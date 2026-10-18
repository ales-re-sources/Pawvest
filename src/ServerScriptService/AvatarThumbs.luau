-- AvatarThumbs: avatar head shots for the leaderboard rows (Photos.Photo1..10 on every board). Server-only.
-- The thumbnail is fetched from Roblox on the server (Players:GetUserThumbnailAsync) and cached in memory for
-- CACHE_TTL seconds; it is not stored in any DataStore, because the image id changes whenever the avatar does.
-- Boards that only know a player's name (Top-10 entries written before UserIds were stored) resolve the UserId by name.

local Players = game:GetService("Players")

local CACHE_TTL = 30 * 60
local THUMB_TYPE = Enum.ThumbnailType.HeadShot
local THUMB_SIZE = Enum.ThumbnailSize.Size100x100

local thumbs = {} -- [UserId] = { Image = content string, At = os.clock() }
local userIds = {} -- [name] = UserId
local pending = setmetatable({}, { __mode = "k" }) -- [ImageLabel] = what it is waiting to show

local AvatarThumbs = {}

-- UserId of a player name (cached; nil when the lookup fails, e.g. a renamed or deleted account).
function AvatarThumbs.UserIdForName(name: string): number?
	if userIds[name] then
		return userIds[name]
	end
	local online = Players:FindFirstChild(name)
	if online and online:IsA("Player") then
		userIds[name] = online.UserId
		return online.UserId
	end
	local ok, userId = pcall(Players.GetUserIdFromNameAsync, Players, name)
	if ok and type(userId) == "number" then
		userIds[name] = userId
		return userId
	end
	return nil
end

-- Content string of the user's head shot, or nil when it is unavailable or Roblox has not generated it yet
-- (a not-ready image is a blank placeholder and is not cached, so the next call asks again).
function AvatarThumbs.Get(userId: number): string?
	local cached = thumbs[userId]
	if cached and os.clock() - cached.At < CACHE_TTL then
		return cached.Image
	end
	local ok, image, ready = pcall(Players.GetUserThumbnailAsync, Players, userId, THUMB_TYPE, THUMB_SIZE)
	if ok and ready and type(image) == "string" then
		thumbs[userId] = { Image = image, At = os.clock() }
		return image
	end
	return cached and cached.Image or nil
end

-- Shows the avatar of `userId` (or of the player called `name` when no UserId is known) on a board's PhotoN
-- ImageLabel; both nil hides the label (empty row). The label keeps its placeholder image until the thumbnail
-- arrives, and stays on it when the lookup fails. Returns at once; the fetch runs in its own thread.
function AvatarThumbs.Show(label: ImageLabel, userId: number?, name: string?)
	local wanted = userId or name
	pending[label] = wanted
	label.Visible = wanted ~= nil
	if wanted == nil then
		return
	end
	task.spawn(function()
		local id = userId or AvatarThumbs.UserIdForName(name :: string)
		local image = id and AvatarThumbs.Get(id)
		if image and pending[label] == wanted then -- the row may have shown someone else meanwhile
			label.Image = image
		end
	end)
end

return AvatarThumbs
