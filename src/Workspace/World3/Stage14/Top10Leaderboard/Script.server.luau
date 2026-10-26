local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageConfig = require(ReplicatedStorage.StageConfig)
local Locale = require(ReplicatedStorage.Locale)
local TimeFormat = require(ReplicatedStorage.TimeFormat)
local AvatarThumbs = require(game:GetService("ServerScriptService").AvatarThumbs)
local handler = require(workspace.Handlers.PlayerTimerHandler)

local LEADERBOARD_UPDATE= 1 -- minutes; picks up records set on other servers
local ROWS = 10
local stage = StageConfig.ForInstance(script)
local scoreBlock = script.Parent.Model.ScoreBlock

-- the title comes from the stage, so a copied board can never show another stage's name
Locale.SetKey(scoreBlock.SurfaceGui.DataLabel, "board.top10", { stage = { key = "stage.name." .. stage.key }, rows = ROWS })


-- Draws all rows; rows without an entry are cleared, so a shorter list leaves no stale names
local function render(leaderboard)
	local sufgui = scoreBlock.SurfaceGui
	for i = 1, ROWS do
		local entry = leaderboard[i]
		sufgui.Names["Name"..i].Text = if entry then entry.PlayerName else ""
		sufgui.Score["Score"..i].Text = if entry then TimeFormat.Format(entry.Elapsed) else "..."
		-- avatar head shot; entries written before UserIds were stored are resolved by name
		AvatarThumbs.Show(sufgui.Photos["Photo"..i], entry and entry.UserId, entry and entry.PlayerName)
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
