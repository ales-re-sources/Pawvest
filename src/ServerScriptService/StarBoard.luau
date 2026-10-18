-- StarBoard: global "most stars" ranking for the hub board (GDD §8). Server-only.
-- An OrderedDataStore keyed by UserId holds each player's total stars (StageConfig.TotalStars of their medals).
-- The entry is written only when the total changes: after a new medal (StageResults calls Sync), after an admin
-- reset (removed) and once on join when the stored value differs from the profile. The profile stays the source of
-- truth; the store is only a ranking. Entries with 0 stars do not exist.
-- The board reads the Top-10 through Refresh (rate-limited); writes of this server show at once through overrides.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local StageConfig = require(ReplicatedStorage.StageConfig)
local PlayerProfile = require(ServerScriptService.PlayerProfile)

local ROWS = 10
local MIN_FETCH_GAP = 10 -- seconds between reads of the sorted store (budget: a few requests per minute)
local OVERRIDE_TTL = 120 -- seconds a write of this server is layered over the (possibly stale) read
local MAX_ATTEMPTS = 3

local store = DataStoreService:GetOrderedDataStore("MostStars")

local written = {} -- [UserId] = total stars known to be in the store (0 = no entry)
local busy = {} -- [UserId] = true while a push runs
local dirty = {} -- [UserId] = true when Sync was called during a push
local overrides = {} -- [UserId] = { Stars, At } writes of this server
local names = {} -- [UserId] = resolved name
local cache = nil -- { { UserId, Stars }, … } from the last successful read; nil before the first one
local lastFetch = nil
local fetching = false

local changed = Instance.new("BindableEvent")

local StarBoard = {}

-- Fires (entries) after this server changed an entry or a read finished; entries as returned by Top.
StarBoard.Changed = changed.Event

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

-- The last read with this server's recent writes on top: { { UserId, Name, Stars }, … } best first, at most ROWS;
-- nil before the first successful read.
function StarBoard.Top()
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
		warn("StarBoard: reading the ranking failed: " .. tostring(page))
	end
	fetching = false
	return ok
end

-- Re-reads the ranking (rate-limited) and fires Changed with the current Top-10. Returns that list, or nil if no
-- read has succeeded yet.
function StarBoard.Refresh()
	fetch(false)
	local top = StarBoard.Top()
	if top then
		changed:Fire(top)
	end
	return top
end

-- Brings the player's store entry in line with their profile medals (no-op when it already matches).
-- Safe to call at any time and from several threads; also called on join and after an admin reset.
function StarBoard.Sync(player: Player)
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
		local stars = StageConfig.TotalStars(profile.Medals)
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
				local top = StarBoard.Top()
				if top then
					changed:Fire(top)
				end
			else
				warn("StarBoard: writing stars failed for " .. player.Name .. ": " .. tostring(err))
			end
		end
	until not dirty[userId]
	busy[userId] = nil
end

-- On join: learn what the store holds for this player, then correct it if the profile disagrees.
local function onJoin(player: Player)
	if not PlayerProfile.WaitFor(player) then
		return
	end
	local ok, stored = withRetries(function()
		return store:GetAsync(tostring(player.UserId))
	end)
	if ok then
		written[player.UserId] = if type(stored) == "number" then stored else 0
	end
	-- on a failed read `written` stays unknown, so the push writes the profile's total
	StarBoard.Sync(player)
end

PlayerProfile.ProfileReset:Connect(StarBoard.Sync)

Players.PlayerAdded:Connect(onJoin)
for _, player in Players:GetPlayers() do
	task.spawn(onJoin, player)
end

Players.PlayerRemoving:Connect(function(player)
	written[player.UserId] = nil
	busy[player.UserId] = nil
	dirty[player.UserId] = nil
end)

return StarBoard
