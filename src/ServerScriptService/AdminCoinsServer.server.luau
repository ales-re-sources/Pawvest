-- Admin panel "Add Coins": credits the admin who clicked it with AdminConfig.AddCoinsAmount (debug tool for testing
-- prices, slots and eggs). The amount is fixed here and never sent by the client; only the caller's own profile is
-- touched and non-admin requests are ignored. It uses PlayerProfile.AddCoins directly, so the pet multiplier does
-- not apply (it is not a gameplay reward). The profile is saved by the usual autosave / leave save.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local AdminConfig = require(ReplicatedStorage.AdminConfig)
local PlayerProfile = require(ServerScriptService.PlayerProfile)

local COOLDOWN = 0.3 -- seconds between accepted requests per player
local lastAdd = {} -- [Player] = os.clock() of the last accepted request

-- client → server, no arguments; created here (not in Studio)
local addCoinsEvent = Instance.new("RemoteEvent")
addCoinsEvent.Name = "AdminAddCoins"
addCoinsEvent.Parent = ReplicatedStorage

Players.PlayerRemoving:Connect(function(player)
	lastAdd[player] = nil
end)

addCoinsEvent.OnServerEvent:Connect(function(player)
	if not AdminConfig.IsAdmin(player.UserId) then
		warn(string.format("AdminAddCoins: ignored request from non-admin %s (%d)", player.Name, player.UserId))
		return
	end
	local now = os.clock()
	if lastAdd[player] and now - lastAdd[player] < COOLDOWN then
		return
	end
	lastAdd[player] = now
	PlayerProfile.AddCoins(player, AdminConfig.AddCoinsAmount) -- nil while the profile is still loading: nothing happens
end)
