-- PlayerTimerHandler: Centralized timer management for players

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageTimerUpdate = ReplicatedStorage:FindFirstChild("StageTimerUpdate")
local DataStoreService = game:GetService("DataStoreService")
local PlayerScoresStore = DataStoreService:GetDataStore("PlayerScoresStore")
local GlobalLeaderboardsStore = DataStoreService:GetDataStore("GlobalLeaderboardsStore")


local PlayerTimers = {}
local TimerLoops = {}

-- Helper to load scores from DataStore
local function loadScores(player)
	local key = "player_" .. player.UserId
	local success, data = pcall(function()
		return PlayerScoresStore:GetAsync(key)
	end)
	if success and data then
		return data
	end
	return {}
end

-- Helper to save scores to DataStore
local function saveScores(player, scores)
	local key = "player_" .. player.UserId
	pcall(function()
		PlayerScoresStore:SetAsync(key, scores)
	end)
end

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
	saveScores(player, {})
end


local function updateScorePanel(player, stageName)
	local gui = player:FindFirstChild("PlayerGui")
	if not gui then return end
	local screenGui = gui:FindFirstChild("ScreenGui")
	if not screenGui then return end
	local scorePanel = screenGui:FindFirstChild("ScorePanel")
	if not scorePanel then return end

	if (stageName) then
		scorePanel.StageName.Text = stageName
	else
		stageName = scorePanel.StageName.Text 
	end

	local scores = loadScores(player)
	local found = false
	for i, entry in scores do
		if entry.StageName == stageName then
			local minutes = math.floor(entry.Elapsed / 60)
			local seconds = entry.Elapsed % 60
			scorePanel.StageRecord.Text = string.format("Your record: " .. "%02d:%02d", minutes, seconds)
			found = true
			break
		end
	end
	if not found then
		if (stageName == "Central Island") then
			scorePanel.StageRecord.Text = "Enter portal!"
		else
			scorePanel.StageRecord.Text = "First try!"
		end
	end
end


local function startTimer(player, name)
    PlayerTimers[player] = os.time()

    -- Stop any existing timer loop for this player
    if TimerLoops[player] then
        TimerLoops[player].Active = false
    end

    local loop = {Active = true, Name = name}
    TimerLoops[player] = loop

    -- Start a loop to send elapsed time every second
    spawn(function()
        while loop.Active and PlayerTimers[player] do
            local elapsed = os.time() - PlayerTimers[player]
            if StageTimerUpdate then
                StageTimerUpdate:FireClient(player, elapsed)
            end
            task.wait(1)
        end
		StageTimerUpdate:FireClient(player, -1)
	end)
end


local function resetTimer(player)
	local startTime = PlayerTimers[player]
	if startTime then
		local elapsed = os.time() - startTime
		PlayerTimers[player] = nil
		if TimerLoops[player] then
			TimerLoops[player].Active = false
			TimerLoops[player] = nil
		end
		return elapsed
	end
	return nil
end


local function stopTimer(player)
	local startTime = PlayerTimers[player]
	local loop = TimerLoops[player]
    if startTime then
		local elapsed = os.time() - startTime
		resetTimer(player)

		-- Permanent storage logic
		if loop and loop.Name then
			local scores = loadScores(player)
			local found = false
			for i, entry in scores do
				if entry.StageName == loop.Name then
					if (entry.Elapsed > elapsed) then
						-- new high score!
						entry.Elapsed = elapsed
						saveScores(player, scores)
						updateScorePanel(player, nil)
						
						-- Update global Top-10 leaderboard
						updateGlobalLeaderboard(loop.Name, player.Name, elapsed)
					end
					
					found = true
					break
				end
			end
			if not found then
				-- First successful attempt
				table.insert(scores, {StageName = loop.Name, Elapsed = elapsed})
				saveScores(player, scores)
				
				-- Update global Top-10 leaderboard
				updateGlobalLeaderboard(loop.Name, player.Name, elapsed)
			end
		end

        return elapsed
    end
    return nil
end

-- returns nil in case timer is not active for given player, otherwise returns the time elapsed since the timer start
local function getTimer(player)
    local startTime = PlayerTimers[player]
    if startTime then
        return os.time() - startTime
    end
    return nil
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
