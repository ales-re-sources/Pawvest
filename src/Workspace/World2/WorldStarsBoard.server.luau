-- World stars board (S5, docs/STAGES.md §7.8): draws StarBoard.World(n)'s Top-10 (the players with the most stars earned in this
-- world) on the board model beside it, `StarsLeaderboard` (a Studio-only clone of the hub's board; same ScoreBlock.SurfaceGui
-- layout). The world is the one whose Workspace folder this script lives in; identical copies sit in every world folder.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local StageConfig = require(ReplicatedStorage.StageConfig)
local StarBoard = require(ServerScriptService.StarBoard)
local AvatarThumbs = require(ServerScriptService.AvatarThumbs)

local world
for _, candidate in StageConfig.Worlds do
	if candidate.folder == script.Parent.Name then
		world = candidate
	end
end
if not world then
	error("WorldStarsBoard: no world for folder " .. script.Parent.Name)
end

local REFRESH = 1 -- minutes; picks up stars earned on other servers
local ROWS = 10
local board = StarBoard.World(world.index)
local scoreBlock = script.Parent:WaitForChild("StarsLeaderboard"):WaitForChild("Model"):WaitForChild("ScoreBlock")
local maxStars = StageConfig.MaxWorldStars(world.index)

scoreBlock.SurfaceGui.DataLabel.Text = string.format("%s stars - top %d!", world.name, ROWS)

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
board.Changed:Connect(render)

task.spawn(function()
	task.wait(5)
	while true do
		board.Refresh()
		task.wait(REFRESH * 60)
	end
end)
