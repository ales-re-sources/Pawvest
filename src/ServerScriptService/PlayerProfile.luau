-- PlayerProfile: one DataStore record per player holding all persistent progress. Server-only.
-- Loaded on join, saved on leave, every AUTOSAVE_INTERVAL seconds and on shutdown.
-- A missing record is built from the legacy PlayerCoins / PlayerScoresStore data (left untouched).
-- If loading fails the player plays on a default profile that is never saved, so stored data is never overwritten.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local PROFILE_VERSION = 1
local AUTOSAVE_INTERVAL = 60
local MAX_ATTEMPTS = 3
local SHUTDOWN_TIMEOUT = 25

local profileStore = DataStoreService:GetDataStore("PlayerProfiles")
local legacyCoinStore = DataStoreService:GetDataStore("PlayerCoins")
local legacyScoreStore = DataStoreService:GetDataStore("PlayerScoresStore")

local profiles = {} -- [Player] = profile
local saveBlocked = {} -- [Player] = true when the load failed
local activeSaves = 0

local coinsChanged = Instance.new("BindableEvent")
local profileReset = Instance.new("BindableEvent")

local PlayerProfile = {}

-- Fires (player, coins) whenever Coins change through AddCoins.
PlayerProfile.CoinsChanged = coinsChanged.Event

-- Fires (player) after Reset replaced the profile, so systems mirroring it (talents) can refresh.
PlayerProfile.ProfileReset = profileReset.Event

local function newProfile()
	return {
		Version = PROFILE_VERSION,
		Coins = 0,
		BestTimes = {}, -- [stageKey] = seconds (tenths)
		Medals = {}, -- [stageKey] = highest medal earned (M1)
		UnlockedStages = {}, -- [stageKey] = true (M3)
		CollectedCoins = {}, -- [coinId] = true (M4)
		Talents = {}, -- [talentId] = level (M2)
		RunsToday = {}, -- { Day = UTC day number, [stageKey] = finishes that day } (R1)
	}
end

-- Fills fields added after the record was written.
local function reconcile(data)
	for field, default in newProfile() do
		if data[field] == nil then
			data[field] = default
		end
	end
	return data
end

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

local function profileKey(userId)
	return "user_" .. userId
end

-- Returns a profile built from the pre-M0 stores, or nil + error if either read fails.
local function migrateLegacy(userId)
	local okCoins, coins = withRetries(function()
		return legacyCoinStore:GetAsync(userId) -- legacy key is the numeric UserId
	end)
	if not okCoins then
		return nil, coins
	end
	local okScores, scores = withRetries(function()
		return legacyScoreStore:GetAsync("player_" .. userId)
	end)
	if not okScores then
		return nil, scores
	end

	local profile = newProfile()
	if type(coins) == "number" then
		profile.Coins = math.max(0, math.floor(coins))
	end
	if type(scores) == "table" then
		for _, entry in scores do
			if type(entry) == "table" and type(entry.StageName) == "string" and type(entry.Elapsed) == "number" then
				local best = profile.BestTimes[entry.StageName]
				if not best or entry.Elapsed < best then
					profile.BestTimes[entry.StageName] = entry.Elapsed
				end
			end
		end
	end
	return profile
end

local function save(player)
	local profile = profiles[player]
	if not profile or saveBlocked[player] then
		return false
	end
	activeSaves += 1
	local ok, err = withRetries(function()
		profileStore:SetAsync(profileKey(player.UserId), profile, { player.UserId })
	end)
	activeSaves -= 1
	if not ok then
		warn("PlayerProfile: save failed for " .. player.Name .. ": " .. tostring(err))
	end
	return ok
end

local function load(player)
	local ok, data = withRetries(function()
		return profileStore:GetAsync(profileKey(player.UserId))
	end)

	local profile, migrated = nil, false
	if ok and data == nil then
		profile, data = migrateLegacy(player.UserId)
		ok = profile ~= nil
		migrated = ok
	elseif ok and type(data) == "table" then
		profile = reconcile(data)
	elseif ok then
		ok, data = false, "record is not a table"
	end

	if not player.Parent then
		return -- left while loading
	end
	if not ok then
		warn("PlayerProfile: load failed for " .. player.Name .. ", progress will not be saved: " .. tostring(data))
		saveBlocked[player] = true
		profile = newProfile()
	end
	profiles[player] = profile
	if migrated then
		save(player)
	end
end

-- Returns the loaded profile, or nil while it is still loading.
function PlayerProfile.Get(player: Player)
	return profiles[player]
end

-- Yields until the profile is loaded; returns nil if the player left first.
function PlayerProfile.WaitFor(player: Player)
	while not profiles[player] and player.Parent do
		task.wait()
	end
	return profiles[player]
end

-- Returns the new Coins total, or nil if the profile is not loaded.
function PlayerProfile.AddCoins(player: Player, amount: number)
	local profile = profiles[player]
	if not profile then
		return nil
	end
	profile.Coins += amount
	coinsChanged:Fire(player, profile.Coins)
	return profile.Coins
end

-- Replaces the player's progress with a fresh profile and saves it (admin self-reset). False if not loaded.
function PlayerProfile.Reset(player: Player): boolean
	if not profiles[player] then
		return false
	end
	profiles[player] = newProfile()
	coinsChanged:Fire(player, 0)
	profileReset:Fire(player)
	task.spawn(save, player)
	return true
end

PlayerProfile.Save = save

Players.PlayerAdded:Connect(load)
for _, player in Players:GetPlayers() do
	task.spawn(load, player)
end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	profiles[player] = nil
	saveBlocked[player] = nil
end)

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for _, player in Players:GetPlayers() do
			task.spawn(save, player)
		end
	end
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		task.spawn(save, player)
	end
	local deadline = os.clock() + SHUTDOWN_TIMEOUT
	while activeSaves > 0 and os.clock() < deadline do
		task.wait()
	end
end)

return PlayerProfile
