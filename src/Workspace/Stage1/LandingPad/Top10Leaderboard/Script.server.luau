local handler = require(workspace.Handlers.PlayerTimerHandler)

local LEADERBOARD_UPDATE= 1
local scoreBlock = script.Parent.Model.ScoreBlock


local function disp__time(_time)
	local minutes = math.floor(_time / 60)
	local seconds = _time % 60
	return string.format("%02dm : %02ds", minutes, seconds)
end


local function UpdateBoard()
	local leaderboard = handler.LoadGlobalLeaderboard("Stage 1")
	local index = 1
	for v in leaderboard do
		--local userid = tonumber(string.split(v.key, NAME_OF_STAT)[2])
		local name = leaderboard[v].PlayerName
		local score = disp__time(leaderboard[v].Elapsed)
		local sufgui = scoreBlock.SurfaceGui
		sufgui.Names["Name"..v].Text = name
		sufgui.Score["Score"..v].Text = score
		--sufgui.Photos["Photo"..k].Image = game:GetService("Players"):GetUserThumbnailAsync(userid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	end
	
--	print("Board updated sucessfully")
end

-- update leaderboard
spawn(function ()
	wait(5)
	UpdateBoard()
	while wait(LEADERBOARD_UPDATE*60) do
		UpdateBoard()
	end
end)
