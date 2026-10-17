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

local StageTimerUpdate = ReplicatedStorage:WaitForChild("StageTimerUpdate")
local GlobalLeaderboardsStore = DataStoreService:GetDataStore("GlobalLeaderboardsStore")


local timers = {} -- [Player] = { StageKey = string, StartClock = number }
local panelStages = {} -- [Player] = stage key shown on the score panel, or StageConfig.HubName

Players.PlayerRemoving:Connect(function(player)
	timers[player] = nil
	panelStages[player] = nil
end)

-- Helper to load global leaderboard for a stage
local function loadGlobalLeaderboard(stageName)
	local key = "leaderboard_" .. stageName
	local success, data = pcall(function()
		return GlobalLeaderboardsStore:GetAsync(key)
	end)
	if success and data then
		return data
	end
	return {}
end

-- Helper to save global leaderboard for a stage
local function saveGlobalLeaderboard(stageName, leaderboard)
	local key = "leaderboard_" .. stageName
	pcall(function()
		GlobalLeaderboardsStore:SetAsync(key, leaderboard)
	end)
end

-- Helper to update global Top-10 leaderboard
local function updateGlobalLeaderboard(stageName, playerName, elapsed)
	local leaderboard = loadGlobalLeaderboard(stageName)

	-- Check if player already has a time on this leaderboard
	local existingEntry = nil
	for i, entry in leaderboard do
		if entry.PlayerName == playerName then
			existingEntry = entry
			break
		end
	end

	-- Update existing entry or add new one
	if existingEntry then
		if elapsed < existingEntry.Elapsed then
			existingEntry.Elapsed = elapsed
		end
	else
		table.insert(leaderboard, {PlayerName = playerName, Elapsed = elapsed})
	end

	-- Sort by elapsed time (ascending)
	table.sort(leaderboard, function(a, b)
		return a.Elapsed < b.Elapsed
	end)

	-- Keep only Top-10
	if #leaderboard > 10 then
		for i = 11, #leaderboard do
			leaderboard[i] = nil
		end
	end

	-- Save the updated leaderboard
	saveGlobalLeaderboard(stageName, leaderboard)

	return leaderboard
end


local function resetHighScore(player)
	local profile = PlayerProfile.Get(player)
	if profile then
		profile.BestTimes = {}
	end
end


-- stageKey: a StageConfig key, StageConfig.HubName, or nil to refresh the stage currently shown
local function updateScorePanel(player, stageKey)
	if stageKey then
		panelStages[player] = stageKey
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

	local stage = StageConfig.ByKey[stageKey]
	if not stage then
		scorePanel.StageName.Text = StageConfig.HubName
		scorePanel.StageRecord.Text = "Enter portal!"
		if medalsLabel then
			local stars = 0
			for _, medal in medals do
				stars += medal
			end
			medalsLabel.Text = string.format("Stars earned: %d / %d", stars, #StageConfig.Stages * #StageConfig.Medals)
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
	local result = StageResults.RecordFinish(player, timer.StageKey, elapsed)
	StageTimerUpdate:FireClient(player, -1, elapsed, result)

	updateScorePanel(player, nil) -- record and earned medals may have changed
	if result and result.newBest then
		updateGlobalLeaderboard(timer.StageKey, player.Name, elapsed)
	end
	return elapsed
end


return {
	StartTimer = startTimer,
	StopTimer = stopTimer,
	GetTimer = getTimer,
	ResetTimer = resetTimer,
	ResetHighScore = resetHighScore,
	UpdateScorePanel = updateScorePanel,
	LoadGlobalLeaderboard = loadGlobalLeaderboard,
	UpdateGlobalLeaderboard = updateGlobalLeaderboard,
}
