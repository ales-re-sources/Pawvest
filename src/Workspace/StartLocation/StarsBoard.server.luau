-- Hub "most stars" board (GDD §8): draws StarBoard's global Top-10 on StartLocation.StarsLeaderboard
-- (a Studio-only board model, wooden stud style since H1; this script lives beside it so the model needs no script).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local StageConfig = require(ReplicatedStorage.StageConfig)
local StarBoard = require(ServerScriptService.StarBoard)
local AvatarThumbs = require(ServerScriptService.AvatarThumbs)

local REFRESH = 1 -- minutes; picks up stars earned on other servers
local ROWS = 10
local scoreBlock = script.Parent.StarsLeaderboard.Model.ScoreBlock
local maxStars = StageConfig.MaxStars()

scoreBlock.SurfaceGui.DataLabel.Text = string.format("Most stars - top %d!", ROWS)

-- Draws all rows; rows without an entry are cleared, so a shorter list leaves no stale names
local function render(top)
	local gui = scoreBlock.SurfaceGui
	for i = 1, ROWS do
		local entry = top[i]
		gui.Names["Name" .. i].Text = if entry then entry.Name else ""
		gui.Score["Score" .. i].Text = if entry then string.format("%d / %d", entry.Stars, maxStars) else "..."
		AvatarThumbs.Show(gui.Photos["Photo" .. i], entry and entry.UserId, nil)
	end
end

render({})

-- a star earned (or reset) on this server shows at once
StarBoard.Changed:Connect(render)

task.spawn(function()
	task.wait(5)
	while true do
		StarBoard.Refresh()
		task.wait(REFRESH * 60)
	end
end)
