local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageConfig = require(ReplicatedStorage.StageConfig)
local TimeFormat = require(ReplicatedStorage.TimeFormat)
local handler = require(workspace.Handlers.PlayerTimerHandler)

local LEADERBOARD_UPDATE= 1 -- minutes; picks up records set on other servers
local ROWS = 10
local stage = StageConfig.ForInstance(script)
local scoreBlock = script.Parent.Model.ScoreBlock


-- Draws all rows; rows without an entry are cleared, so a shorter list leaves no stale names
local function render(leaderboard)
	local sufgui = scoreBlock.SurfaceGui
	for i = 1, ROWS do
		local entry = leaderboard[i]
		sufgui.Names["Name"..i].Text = if entry then entry.PlayerName else ""
		sufgui.Score["Score"..i].Text = if entry then TimeFormat.Format(entry.Elapsed) else "..."
	end
end

local function UpdateBoard()
	render(handler.LoadGlobalLeaderboard(stage.key))
end

-- a record set on this server shows at once
handler.LeaderboardChanged:Connect(function(stageKey, leaderboard)
	if stageKey == stage.key then
		render(leaderboard)
	end
end)

-- update leaderboard
task.spawn(function ()
	task.wait(5)
	UpdateBoard()
	while task.wait(LEADERBOARD_UPDATE*60) do
		UpdateBoard()
	end
end)
