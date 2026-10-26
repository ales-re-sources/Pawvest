local DATA_STORE 		= "a" --< Name of the Data store values will be saved in
local SCORE_UPDATE 		= 1 --< How often you want the score to be sent to datastore in minutes (no less than 1)
local LEADERBOARD_UPDATE= 1 --< How often you want the leaderboard to update in minutes (no less than 1) 
local NAME_OF_STAT 		= "The Most Time Played" --< Stat name to save in the database
local DO_DEBUG			= true --< Should it debug (print) messages to the console?

local scoreBlock = script.Parent.Model.ScoreBlock

-- gets the datastore, fails if could not find
local Database = nil
local suc, err = pcall(function ()
	Database = game:GetService("DataStoreService"):GetOrderedDataStore(DATA_STORE)
end)
if not suc or Database == nil then warn(err) script.Parent:Destroy() end

local function disp__time(_time)
	_time = _time * 60
	local days = math.floor(_time/86400)
	local hours = math.floor(math.fmod(_time, 86400)/3600)
	local minutes = math.floor(math.fmod(_time,3600)/60)
	return string.format("%02dd : %02dh : %02dm",days,hours,minutes)
end

local UpdateBoard = function ()
	if DO_DEBUG then print("Updating board") end
	local results = Database:GetSortedAsync(false, 10, 1):GetCurrentPage()
	for k, v in pairs(results) do
		local userid = tonumber(string.split(v.key, NAME_OF_STAT)[2])
		local name = game:GetService("Players"):GetNameFromUserIdAsync(userid)
		local score = disp__time(v.value)
		local sufgui = scoreBlock.SurfaceGui
		sufgui.Names["Name"..k].Text = name
		sufgui.Score["Score"..k].Text = score
		sufgui.Photos["Photo"..k].Image = game:GetService("Players"):GetUserThumbnailAsync(userid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	end
	if DO_DEBUG then print("Board updated sucessfully") end
end

local suc, err = pcall(UpdateBoard) -- update once
if not suc then warn(err) end

-- increments players time in the datastore
spawn(function ()
	while wait(SCORE_UPDATE*60) do
		local suc, err = coroutine.resume(coroutine.create(function ()
			local players = game:GetService("Players"):GetPlayers()
			for _, player in pairs(players) do
				local stat = NAME_OF_STAT .. player.UserId
				local newval = Database:IncrementAsync(stat, SCORE_UPDATE)
				if DO_DEBUG then print("Incremented time played stat of", player, stat, "to", newval) end
			end
		end))
		if not suc then warn(err) end
	end
end)

-- update leaderboard
spawn(function ()
	while wait(LEADERBOARD_UPDATE*60) do
		UpdateBoard()
	end
end)
