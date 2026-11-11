-- Admin panel "Add Coins": credits the admin who clicked it with AdminConfig.AddCoinsAmount (debug tool for testing
-- prices, slots and eggs). The amount is fixed here and never sent by the client; only the caller's own profile is
-- touched and non-admin requests are ignored. It uses PlayerProfile.AddCoins directly, so the pet multiplier does
-- not apply (it is not a gameplay reward). The profile is saved by the usual autosave / leave save.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local AdminConfig = require(ReplicatedStorage.AdminConfig)
local PlayerProfile = require(ServerScriptService.PlayerProfile)
local Remotes = require(ServerScriptService.Remotes)

-- client → server, no arguments; created here (not in Studio); 0.3 s between accepted requests per player
Remotes.Admin(Remotes.Add(ReplicatedStorage, "AdminAddCoins"), 0.3, function(player)
	PlayerProfile.AddCoins(player, AdminConfig.AddCoinsAmount) -- nil while the profile is still loading: nothing happens
end)
