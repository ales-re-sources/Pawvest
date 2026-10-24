-- PlayerProfile: one DataStore record per player holding all persistent progress. Server-only.
-- Loaded on join, saved on leave, every AUTOSAVE_INTERVAL seconds and on shutdown.
-- A missing record is built from the legacy PlayerCoins / PlayerScoresStore data (left untouched).
-- If loading fails the player plays on a default profile that is never saved, so stored data is never overwritten.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local PROFILE_VERSION = 3 -- 2: pets (P1a); 3: Coin scale ×10 (R2)
local COIN_SCALE = 10 -- R2: Coins stored before version 3 (and legacy PlayerCoins) are multiplied once
local AUTOSAVE_INTERVAL = 60
local MAX_ATTEMPTS = 3
local SHUTDOWN_TIMEOUT = 25

local profileStore = DataStoreService:GetDataStore("PlayerProfiles")
local legacyCoinStore = DataStoreService:GetDataStore("PlayerCoins")
local legacyScoreStore = DataStoreService:GetDataStore("PlayerScoresStore")

local profiles = {} -- [Player] = profile
local saveBlocked = {} -- [Player] = true when the load failed
local fresh = {} -- [Player] = true when neither a stored record nor legacy data existed (a new player)
local left = {} -- [Player] = true once the OnLeaving callbacks ran
local leavingCallbacks = {}
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
		Pets = {}, -- [uid string] = { Kind, Level, XP } (P1a)
		EquippedPets = {}, -- { uid, … } in equip order, at most PetSlots (P1a)
		PetSlots = 1, -- equip slots owned (P1a)
		NextPetUid = 1, -- next uid to hand out, never reused (P1a)
		FreeEggs = {}, -- [eggId] = free eggs waiting to be opened (P1a)
		LaunchEgg = false, -- true once the pets-launch free egg was granted (P1a)
		-- Pet garden (P2a2): Pens["1".."6"] = uid of the penned pet, PenCount = pens owned, LastSeen = server os.time()
		-- up to which production was paid (absent until the first settle), Carry = production left over from the last payout;
		-- P2b1: Incubators["1".."3"] = { Egg, StartedAt, ReadyAt } (server os.time()), IncubatorCount = incubators owned
		Garden = { Pens = {}, PenCount = 1, Carry = 0, Incubators = {}, IncubatorCount = 1 },
		LastQuit = {}, -- { Stage, Segment, At = os.time() } of the last leave, cleared on the next join (Telemetry, T1a)
		Language = "", -- chosen language code ("en", "cs"), "" = automatic from the player's locale (LanguageService, L1)
	}
end

-- Fills fields added after the record was written and upgrades older versions (each step runs once:
-- the record is stamped with PROFILE_VERSION afterwards).
local function reconcile(data)
	local version = type(data.Version) == "number" and data.Version or 1
	if version < 3 and type(data.Coins) == "number" then
		data.Coins *= COIN_SCALE
	end
	for field, default in newProfile() do
		if data[field] == nil then
			data[field] = default
		end
	end
	data.Version = PROFILE_VERSION
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
		profile.Coins = math.max(0, math.floor(coins)) * COIN_SCALE
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
		fresh[player] = ok and profile.Coins == 0 and next(profile.BestTimes) == nil or nil
	elseif ok and type(data) == "table" then
		profile = reconcile(data)
	elseif ok then
		ok, data = false, "record is not a table" -- loc: ignore (log message)
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

-- True for a player who had neither a stored profile nor legacy data when they joined (telemetry Session).
function PlayerProfile.IsNew(player: Player): boolean
	return fresh[player] == true
end

-- Registers fn(player, profile or nil), run once per leaving player right before the leave save, also when the server
-- shuts down (BindToClose), so it may still change the profile (Telemetry writes LastQuit).
function PlayerProfile.OnLeaving(fn)
	table.insert(leavingCallbacks, fn)
end

local function runLeaving(player)
	if left[player] then
		return
	end
	left[player] = true
	for _, fn in leavingCallbacks do
		local ok, err = pcall(fn, player, profiles[player])
		if not ok then
			warn("PlayerProfile: OnLeaving callback failed: " .. tostring(err))
		end
	end
end

-- Returns the loaded profile, or nil while it is still loading.
function PlayerProfile.Get(player: Player)
	return profiles[player]
end

-- True when the profile is loaded from the store and will be saved (false while loading or after a failed load).
-- Systems that mirror profile data into other stores must check it, so a default profile never overwrites real data.
function PlayerProfile.CanSave(player: Player): boolean
	return profiles[player] ~= nil and not saveBlocked[player]
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
	runLeaving(player)
	save(player)
	profiles[player] = nil
	saveBlocked[player] = nil
	fresh[player] = nil
	left[player] = nil
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
		runLeaving(player)
		task.spawn(save, player)
	end
	local deadline = os.clock() + SHUTDOWN_TIMEOUT
	while activeSaves > 0 and os.clock() < deadline do
		task.wait()
	end
end)

return PlayerProfile
