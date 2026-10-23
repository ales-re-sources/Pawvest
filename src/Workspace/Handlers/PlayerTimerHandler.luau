-- PlayerTimerHandler: per-player stage timers, personal bests (PlayerProfile) and global Top-10 (DataStore).
-- StageTimerUpdate protocol (server → client):
--   (elapsed >= 0, stageKey)  run is active, `elapsed` seconds as of now; the client counts on locally
--   (-1, final, result)  run finished in `final` seconds; `result` from StageResults.RecordFinish (nil if no profile)
--   (-1)                 run cancelled

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreService = game:GetService("DataStoreService")

local StageConfig = require(ReplicatedStorage.StageConfig)
local TimeFormat = require(ReplicatedStorage.TimeFormat)
local MedalText = require(ReplicatedStorage.MedalText)
local PlayerProfile = require(ServerScriptService.PlayerProfile)
local StageResults = require(ServerScriptService.StageResults)
local RunDistance = require(ServerScriptService.RunDistance)

local StageTimerUpdate = ReplicatedStorage:WaitForChild("StageTimerUpdate")
local TalentConfig = require(ReplicatedStorage.TalentConfig)

-- server → client (stageKey): the player arrived on a stage without a talent it requires (StageArrivalWarning.client)
local stageArrival = Instance.new("RemoteEvent")
stageArrival.Name = "StageArrival"
stageArrival.Parent = ReplicatedStorage
local GlobalLeaderboardsStore = DataStoreService:GetDataStore("GlobalLeaderboardsStore")

-- fires (stageKey, leaderboard) after this server wrote a stage's Top-10, so boards redraw at once
local leaderboardChanged = Instance.new("BindableEvent")


local timers = {} -- [Player] = { StageKey = string, StartClock = number }
local panelStages = {} -- [Player] = stage key shown on the score panel, or StageConfig.HubName

Players.PlayerRemoving:Connect(function(player)
	timers[player] = nil
	panelStages[player] = nil
end)

local TOP_ROWS = 10

-- last Top-10 of each stage this server read or wrote, [stageKey] = list; lets a finish that cannot make the board skip
-- the DataStore. Boards only get faster, so a stale copy errs towards writing (except right after an admin removal
-- elsewhere, which the next board refresh, at most a minute later, picks up)
local cachedBoards = {}

-- Loads a stage's global Top-10 ({} when there is none or the read fails)
local function loadGlobalLeaderboard(stageName)
	local key = "leaderboard_" .. stageName
	local success, data = pcall(function()
		return GlobalLeaderboardsStore:GetAsync(key)
	end)
	if success and type(data) == "table" then
		cachedBoards[stageName] = data
		return data
	end
	return {}
end

-- The entry of a player: by UserId, or by name for entries written before UserIds were stored
local function findEntry(leaderboard, playerName, userId)
	for _, entry in leaderboard do
		if (userId and entry.UserId == userId) or entry.PlayerName == playerName then
			return entry
		end
	end
	return nil
end

-- True when `elapsed` would change the Top-10: better than the player's own entry, or (without one) a free row or
-- faster than the last row
local function wouldChange(leaderboard, playerName, elapsed, userId)
	local entry = findEntry(leaderboard, playerName, userId)
	if entry then
		return elapsed < entry.Elapsed or entry.UserId == nil or entry.PlayerName ~= playerName
	end
	local last = leaderboard[TOP_ROWS]
	return #leaderboard < TOP_ROWS or (last ~= nil and elapsed < last.Elapsed)
end

-- Records a time on a stage's global Top-10, nil when it did not change.
-- UpdateAsync, not GetAsync + SetAsync: two servers posting at the same moment would otherwise overwrite each other's
-- record. The transform may run more than once and returns nil (no write) when the time does not make the board.
-- userId is stored with the entry so boards can show the avatar (older entries get it on their next record)
local function updateGlobalLeaderboard(stageName, playerName, elapsed, userId)
	local cached = cachedBoards[stageName]
	if cached and not wouldChange(cached, playerName, elapsed, userId) then
		return nil
	end
	local written = nil
	local ok, err = pcall(function()
		GlobalLeaderboardsStore:UpdateAsync("leaderboard_" .. stageName, function(old)
			local leaderboard = if type(old) == "table" then old else {}
			cachedBoards[stageName] = leaderboard
			written = nil
			if not wouldChange(leaderboard, playerName, elapsed, userId) then
				return nil
			end
			local entry = findEntry(leaderboard, playerName, userId)
			if entry then
				entry.Elapsed = math.min(entry.Elapsed, elapsed)
				entry.PlayerName = playerName
				entry.UserId = userId or entry.UserId
			else
				table.insert(leaderboard, { PlayerName = playerName, Elapsed = elapsed, UserId = userId })
			end
			table.sort(leaderboard, function(a, b)
				return a.Elapsed < b.Elapsed
			end)
			for i = #leaderboard, TOP_ROWS + 1, -1 do
				leaderboard[i] = nil
			end
			written = leaderboard
			return leaderboard
		end)
	end)
	if not ok then
		warn("PlayerTimerHandler: Top-10 update failed for " .. stageName .. ": " .. tostring(err))
		cachedBoards[stageName] = nil -- the transform may have changed the cached list before the write failed
		return nil
	end
	if written then
		cachedBoards[stageName] = written
		leaderboardChanged:Fire(stageName, written)
	end
	return written
end


-- Removes a player's entries from every stage's Top-10 (admin self-reset); boards redraw via LeaderboardChanged
local function removeFromGlobalLeaderboards(playerName)
	for _, stage in StageConfig.Stages do
		local kept = nil
		local ok, err = pcall(function()
			GlobalLeaderboardsStore:UpdateAsync("leaderboard_" .. stage.key, function(old)
				kept = nil
				if type(old) ~= "table" then
					return nil
				end
				local list = {}
				for _, entry in old do
					if entry.PlayerName ~= playerName then
						table.insert(list, entry)
					end
				end
				if #list == #old then
					return nil
				end
				kept = list
				return list
			end)
		end)
		if not ok then
			warn("PlayerTimerHandler: Top-10 removal failed for " .. stage.key .. ": " .. tostring(err))
		elseif kept then
			cachedBoards[stage.key] = kept
			leaderboardChanged:Fire(stage.key, kept)
		end
	end
end


-- stageKey: a StageConfig key, StageConfig.HubName, or nil to refresh the stage currently shown
local function updateScorePanel(player, stageKey)
	if stageKey then
		panelStages[player] = stageKey
		-- arriving on a stage (the hub portals pass its key): warn about required talents the player lacks (S1.2);
		-- entry is never blocked
		local arrived = StageConfig.ByKey[stageKey]
		if arrived and #arrived.requires > 0 then
			local missing = StageConfig.MissingTalents(arrived, function(id)
				return player:GetAttribute(TalentConfig.AttributeName(id)) or 0
			end)
			if #missing > 0 then
				stageArrival:FireClient(player, stageKey)
			end
		end
	else
		stageKey = panelStages[player] or StageConfig.HubName
	end

	local gui = player:FindFirstChild("PlayerGui")
	if not gui then return end
	local screenGui = gui:FindFirstChild("ScreenGui")
	if not screenGui then return end
	local scorePanel = screenGui:FindFirstChild("ScorePanel")
	if not scorePanel then return end

	-- third row with medal limits (Studio-only label, M1.1); the panel still works without it
	local medalsLabel = scorePanel:FindFirstChild("StageMedals")
	local profile = PlayerProfile.Get(player)
	local medals = if profile then profile.Medals else {}

	-- a world island: the world's name and the stars earned in it
	local world = StageConfig.WorldByName[stageKey]
	if world then
		scorePanel.StageName.Text = world.name
		scorePanel.StageRecord.Text = "Choose a stage!"
		if medalsLabel then
			medalsLabel.Text = string.format("Stars earned: %d / %d", StageConfig.WorldStars(medals, world.index), StageConfig.MaxWorldStars(world.index))
		end
		return
	end

	local stage = StageConfig.ByKey[stageKey]
	if not stage then
		scorePanel.StageName.Text = StageConfig.HubName
		scorePanel.StageRecord.Text = "Enter portal!"
		if medalsLabel then
			medalsLabel.Text = string.format("Stars earned: %d / %d", StageConfig.TotalStars(medals), StageConfig.MaxStars())
		end
		return
	end

	scorePanel.StageName.Text = stage.displayName
	local best = profile and profile.BestTimes[stage.key]
	if best then
		scorePanel.StageRecord.Text = "Your record: " .. TimeFormat.Format(best)
	else
		scorePanel.StageRecord.Text = "First try!"
	end
	if medalsLabel then
		medalsLabel.Text = MedalText.Limits(stage, medals[stage.key] or 0)
	end
end

-- The ScreenGui is re-created on every respawn (ResetOnSpawn); redraw the panel each time it appears,
-- and once more when the profile has loaded.
local function watchScorePanel(player)
	local playerGui = player:WaitForChild("PlayerGui")
	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "ScreenGui" then
			updateScorePanel(player, nil)
		end
	end)
	if PlayerProfile.WaitFor(player) then
		updateScorePanel(player, nil)
	end
end

Players.PlayerAdded:Connect(watchScorePanel)
for _, player in Players:GetPlayers() do
	task.spawn(watchScorePanel, player)
end


local function startTimer(player, stageKey)
	timers[player] = { StageKey = stageKey, StartClock = os.clock() }
	RunDistance.Start(player) -- movement pet XP counts only during a run
	StageTimerUpdate:FireClient(player, 0, stageKey)
end

-- returns nil in case timer is not active for given player, otherwise the elapsed time and the stage key
local function getTimer(player)
	local timer = timers[player]
	if timer then
		return os.clock() - timer.StartClock, timer.StageKey
	end
	return nil
end

-- cancels the run (player left the stage); returns the elapsed time or nil
local function resetTimer(player)
	local timer = timers[player]
	if not timer then
		return nil
	end
	timers[player] = nil
	RunDistance.Stop(player) -- a cancelled run earns no movement XP
	StageTimerUpdate:FireClient(player, -1)
	return TimeFormat.Tenths(os.clock() - timer.StartClock)
end

-- finishes the run and records a personal best; returns the elapsed time (tenths) or nil without a running timer
local function stopTimer(player)
	local timer = timers[player]
	if not timer then
		return nil
	end
	-- cleared before any yield, so repeated finish-portal touches are no-ops
	timers[player] = nil

	local elapsed = TimeFormat.Tenths(os.clock() - timer.StartClock)
	local result = StageResults.RecordFinish(player, timer.StageKey, elapsed, RunDistance.Stop(player))
	StageTimerUpdate:FireClient(player, -1, elapsed, result)

	updateScorePanel(player, nil) -- record and earned medals may have changed
	if result and result.newBest then
		updateGlobalLeaderboard(timer.StageKey, player.Name, elapsed, player.UserId)
	end
	return elapsed
end


return {
	StartTimer = startTimer,
	StopTimer = stopTimer,
	GetTimer = getTimer,
	ResetTimer = resetTimer,
	UpdateScorePanel = updateScorePanel,
	GetPanelKey = function(player) -- the place the score panel shows: a stage key, a world name or StageConfig.HubName
		return panelStages[player] or StageConfig.HubName
	end,
	LoadGlobalLeaderboard = loadGlobalLeaderboard,
	UpdateGlobalLeaderboard = updateGlobalLeaderboard,
	LeaderboardChanged = leaderboardChanged.Event,
	RemoveFromGlobalLeaderboards = removeFromGlobalLeaderboards,
}
