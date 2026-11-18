-- GardenLikes (SH): likes on other players' plots (docs/GDD.md §7.9 → Plot likes). Server-only.
-- GardenRemotes.Like(slot) (client → server; the owner is whoever borrows that plot slot now): refuses `self`, `free` (nobody
-- there), `liked` (once per owner per UTC day per liker), `far` (more than LIKE_DISTANCE from that plot), `loading`; answers on
-- GardenRemotes.Result ("Like", true, { name }). The owner is always on this server (plots exist only for present players): their
-- Garden.Likes goes up by one, their plot sign shows the count (GardenPlotFeed `likes`) and GardenRemotes.Liked(name) tells them.
-- The liker's Garden.Liked = { Day, [ownerUserId] = true } is mirrored as the player attributes LikedToday (IdSet of UserIds) and
-- LikedDay (the UTC day it belongs to; another day = nothing liked yet).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local IdSet = require(ReplicatedStorage.IdSet)
local Num = require(ReplicatedStorage.Num)
local TimeFormat = require(ReplicatedStorage.TimeFormat)
local PlayerProfile = require(ServerScriptService.PlayerProfile)
local GardenService = require(ServerScriptService.GardenService)
local GardenPlots = require(ServerScriptService.GardenPlots)
local RateLimit = require(ServerScriptService.RateLimit)
local Telemetry = require(ServerScriptService.Telemetry)

local LIKE_DISTANCE = 60 -- studs from the middle of the liked plot
local LIKED_ATTRIBUTE = "LikedToday"
local LIKED_DAY_ATTRIBUTE = "LikedDay"

local likeEvent = GardenService.Remote("Like") -- client → server: (slot: number)
local likedEvent = GardenService.Remote("Liked") -- server → client (the owner): (likerName: string)
local allow = RateLimit.new(2)
local reject, succeed = GardenService.Reject, GardenService.Succeed

local GardenLikes = {}

-- The liker's set of today, reset when the day changed.
local function likedToday(garden)
	local today = TimeFormat.UtcDay(os.time())
	if type(garden.Liked) ~= "table" or garden.Liked.Day ~= today then
		garden.Liked = { Day = today }
	end
	return garden.Liked
end

local function mirror(player: Player, garden)
	local liked = likedToday(garden)
	local set = {}
	for id, value in liked do
		if id ~= "Day" and value == true then
			set[id] = true
		end
	end
	player:SetAttribute(LIKED_ATTRIBUTE, IdSet.Encode(set))
	player:SetAttribute(LIKED_DAY_ATTRIBUTE, liked.Day)
end

-- The player's likes in all (the plot sign).
function GardenLikes.Count(garden): number
	local n = type(garden) == "table" and garden.Likes
	return if Num.Finite(n) and n > 0 then math.floor(n) else 0
end

local function ownerOf(slot: number): Player?
	for _, other in Players:GetPlayers() do
		if GardenPlots.PlotOf(other) == slot then
			return other
		end
	end
	return nil
end

likeEvent.OnServerEvent:Connect(function(player, slot)
	if not Num.Whole(slot) or not allow(player) then
		return
	end
	local profile = PlayerProfile.Get(player)
	if not profile or type(profile.Garden) ~= "table" then
		return reject(player, "Like", "loading")
	end
	local owner = ownerOf(slot)
	local ownerProfile = owner and PlayerProfile.Get(owner)
	if not (owner and ownerProfile and type(ownerProfile.Garden) == "table") then
		return reject(player, "Like", "free")
	end
	if owner == player then
		return reject(player, "Like", "self")
	end
	local floor = GardenPlots.FloorCFrame(owner)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not (floor and root and root:IsA("BasePart") and (root.Position - floor.Position).Magnitude <= LIKE_DISTANCE) then
		return reject(player, "Like", "far")
	end
	local liked = likedToday(profile.Garden)
	local key = tostring(owner.UserId)
	if liked[key] then
		mirror(player, profile.Garden)
		return reject(player, "Like", "liked")
	end
	liked[key] = true
	ownerProfile.Garden.Likes = GardenLikes.Count(ownerProfile.Garden) + 1
	mirror(player, profile.Garden)
	PlayerProfile.Save(player)
	PlayerProfile.Save(owner)
	GardenService.PublishAll(owner) -- the plot sign's count (GardenPlotFeed)
	likedEvent:FireClient(owner, player.Name)
	Telemetry.PlotLike(player, ownerProfile.Garden.Likes)
	succeed(player, "Like", { name = owner.Name })
end)

PlayerProfile.OnReady(function(player, profile)
	if type(profile.Garden) == "table" then
		mirror(player, profile.Garden)
	end
end)

return GardenLikes
