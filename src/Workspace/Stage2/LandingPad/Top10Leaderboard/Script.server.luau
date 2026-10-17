local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageConfig = require(ReplicatedStorage.StageConfig)
local TimeFormat = require(ReplicatedStorage.TimeFormat)
local handler = require(workspace.Handlers.PlayerTimerHandler)

local LEADERBOARD_UPDATE= 1
local stage = StageConfig.ForInstance(script)
local scoreBlock = script.Parent.Model.ScoreBlock


local function UpdateBoard()
	local leaderboard = handler.LoadGlobalLeaderboard(stage.key)
	for v in leaderboard do
		local name = leaderboard[v].PlayerName
		local score = TimeFormat.Format(leaderboard[v].Elapsed)
		local sufgui = scoreBlock.SurfaceGui
		sufgui.Names["Name"..v].Text = name
		sufgui.Score["Score"..v].Text = score
	end
end

-- update leaderboard
task.spawn(function ()
	task.wait(5)
	UpdateBoard()
	while task.wait(LEADERBOARD_UPDATE*60) do
		UpdateBoard()
	end
end)
