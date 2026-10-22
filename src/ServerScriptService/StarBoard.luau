-- StarBoard: "most stars" rankings (GDD §8). Server-only. The global board (hub; StarBoard.Top / Refresh / Changed) and one board
-- per built world (StarBoard.World(n), S5: the stars earned in that world, on the world's plaza) work the same way:
-- An OrderedDataStore keyed by UserId holds each player's stars (global: StageConfig.TotalStars of their medals; a world:
-- StageConfig.WorldStars).
-- The entry is written only when the total changes: after a new medal (StageResults calls Sync), after an admin
-- reset (removed) and once on join when the stored value differs from the profile. The profile stays the source of
-- truth; the store is only a ranking. Entries with 0 stars do not exist.
-- A board reads the Top-10 through Refresh (rate-limited); writes of this server show at once through overrides.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local StageConfig = require(ReplicatedStorage.StageConfig)
local PlayerProfile = require(ServerScriptService.PlayerProfile)

local ROWS = 10
local MIN_FETCH_GAP = 10 -- seconds between reads of one sorted store (budget: a few requests per minute)
local OVERRIDE_TTL = 120 -- seconds a write of this server is layered over the (possibly stale) read
local MAX_ATTEMPTS = 3

local names = {} -- [UserId] = resolved name (shared by all boards)

local StarBoard = {}

local function withRetries(fn)
	local ok, result
	for attempt = 1, MAX_ATTEMPTS do
		ok, result = pcall(fn)
		if ok then
			return true, result
		end
		if attempt < MAX_ATTEMPTS then
			task.wait(attempt)
		end
	end
	return false, result
end

local function resolveName(userId: number): string
	local player = Players:GetPlayerByUserId(userId)
	if player then
		names[userId] = player.Name
	end
	if not names[userId] then
		local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
		if ok and type(name) == "string" then
			names[userId] = name
		end
	end
	return names[userId] or ("Player " .. userId) -- not cached, so a failed lookup is retried on the next read
end

-- One ranking: an OrderedDataStore `storeName` keyed by UserId whose value is `starsOf(profile)`. Every board has its own
-- cache and write state.
local function newBoard(storeName: string, starsOf)
	local store = DataStoreService:GetOrderedDataStore(storeName)

	local written = {} -- [UserId] = stars known to be in the store (0 = no entry)
	local busy = {} -- [UserId] = true while a push runs
	local dirty = {} -- [UserId] = true when Sync was called during a push
	local overrides = {} -- [UserId] = { Stars, At } writes of this server
	local cache = nil -- { { UserId, Stars }, … } from the last successful read; nil before the first one
	local lastFetch = nil
	local fetching = false

	local changed = Instance.new("BindableEvent")
	local board = {}

	-- Fires (entries) after this server changed an entry or a read finished; entries as returned by Top.
	board.Changed = changed.Event

	-- The last read with this server's recent writes on top: { { UserId, Name, Stars }, … } best first, at most ROWS;
	-- nil before the first successful read.
	function board.Top()
		if not cache then
			return nil
		end
		local stars = {}
		for _, entry in cache do
			stars[entry.UserId] = entry.Stars
		end
		local now = os.clock()
		for userId, override in overrides do
			if now - override.At > OVERRIDE_TTL then
				overrides[userId] = nil
			else
				stars[userId] = override.Stars
			end
		end
		local list = {}
		for userId, count in stars do
			if count > 0 then
				table.insert(list, { UserId = userId, Name = names[userId] or ("Player " .. userId), Stars = count })
			end
		end
		table.sort(list, function(a, b)
			if a.Stars ~= b.Stars then
				return a.Stars > b.Stars
			end
			return a.Name < b.Name
		end)
		for i = #list, ROWS + 1, -1 do
			list[i] = nil
		end
		return list
	end

	-- Reads the Top-10 from the store (skipped within MIN_FETCH_GAP unless `force`). Returns true when the cache is fresh.
	local function fetch(force: boolean?): boolean
		if fetching then
			return false
		end
		if not force and lastFetch and os.clock() - lastFetch < MIN_FETCH_GAP then
			return true
		end
		fetching = true
		local ok, page = pcall(function()
			return store:GetSortedAsync(false, ROWS):GetCurrentPage()
		end)
		if ok then
			local list = {}
			for _, item in page do
				local userId = tonumber(item.key)
				if userId and type(item.value) == "number" and item.value > 0 then
					table.insert(list, { UserId = userId, Stars = item.value })
					resolveName(userId)
				end
			end
			cache = list
			lastFetch = os.clock()
		else
			warn("StarBoard " .. storeName .. ": reading the ranking failed: " .. tostring(page))
		end
		fetching = false
		return ok
	end

	-- Re-reads the ranking (rate-limited) and fires Changed with the current Top-10. Returns that list, or nil if no
	-- read has succeeded yet.
	function board.Refresh()
		fetch(false)
		local top = board.Top()
		if top then
			changed:Fire(top)
		end
		return top
	end

	-- Brings the player's store entry in line with their profile medals (no-op when it already matches).
	function board.Sync(player: Player)
		local userId = player.UserId
		if busy[userId] then
			dirty[userId] = true
			return
		end
		busy[userId] = true
		repeat
			dirty[userId] = nil
			local profile = PlayerProfile.Get(player)
			if not (profile and PlayerProfile.CanSave(player)) then
				break -- a failed load plays on a default profile: never let it overwrite the real entry
			end
			local stars = starsOf(profile)
			if written[userId] ~= stars then
				local ok, err = withRetries(function()
					if stars > 0 then
						store:SetAsync(tostring(userId), stars)
					else
						store:RemoveAsync(tostring(userId))
					end
				end)
				if ok then
					local dropped = written[userId] ~= nil and stars < written[userId]
					written[userId] = stars
					names[userId] = player.Name
					overrides[userId] = { Stars = stars, At = os.clock() }
					if dropped then
						fetch(true) -- the cached Top-10 holds no 11th entry to fill the gap, so read it again
					end
					local top = board.Top()
					if top then
						changed:Fire(top)
					end
				else
					warn("StarBoard " .. storeName .. ": writing stars failed for " .. player.Name .. ": " .. tostring(err))
				end
			end
		until not dirty[userId]
		busy[userId] = nil
	end

	-- On join: learn what the store holds for this player (the Sync that follows corrects it if the profile disagrees).
	function board.Learn(player: Player)
		local ok, stored = withRetries(function()
			return store:GetAsync(tostring(player.UserId))
		end)
		if ok then
			written[player.UserId] = if type(stored) == "number" then stored else 0
		end
		-- on a failed read `written` stays unknown, so the push writes the profile's total
	end

	function board.Forget(player: Player)
		written[player.UserId] = nil
		busy[player.UserId] = nil
		dirty[player.UserId] = nil
	end

	return board
end

local globalBoard = newBoard("MostStars", function(profile)
	return StageConfig.TotalStars(profile.Medals)
end)
local worldBoards = {} -- [world index] = board; only worlds whose stages are built (a `soon` world has no stars to rank)
for index, world in StageConfig.Worlds do
	if not world.soon then
		worldBoards[index] = newBoard("WorldStars_" .. index, function(profile)
			return StageConfig.WorldStars(profile.Medals, index)
		end)
	end
end

-- Global board (the hub's "most stars"): same API as before the world boards existed.
StarBoard.Changed = globalBoard.Changed
StarBoard.Top = globalBoard.Top
StarBoard.Refresh = globalBoard.Refresh

-- The board of the stars earned in world `index`. A world that is not built yet (`soon`) gets an always-empty stand-in, so its
-- plaza board can already be drawn.
local empty = {}
function StarBoard.World(index: number)
	local board = worldBoards[index]
	if board then
		return board
	end
	if not empty[index] then
		local never = Instance.new("BindableEvent")
		empty[index] = {
			Changed = never.Event,
			Top = function()
				return {}
			end,
			Refresh = function()
				return {}
			end,
		}
	end
	return empty[index]
end

local function eachBoard(fn)
	fn(globalBoard)
	for _, board in worldBoards do
		fn(board)
	end
end

-- Brings the player's entries on every board in line with their profile medals (no-op where it already matches).
-- Safe to call at any time and from several threads; also called on join, after a new medal and after an admin reset.
function StarBoard.Sync(player: Player)
	eachBoard(function(board)
		task.spawn(board.Sync, player)
	end)
end

local function onJoin(player: Player)
	if not PlayerProfile.WaitFor(player) then
		return
	end
	eachBoard(function(board)
		task.spawn(function()
			board.Learn(player)
			board.Sync(player)
		end)
	end)
end

PlayerProfile.ProfileReset:Connect(StarBoard.Sync)

Players.PlayerAdded:Connect(onJoin)
for _, player in Players:GetPlayers() do
	task.spawn(onJoin, player)
end

Players.PlayerRemoving:Connect(function(player)
	eachBoard(function(board)
		board.Forget(player)
	end)
end)

return StarBoard
