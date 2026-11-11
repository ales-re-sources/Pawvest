-- Admin panel "Reset Score": full progress reset of the admin who clicked it (debug tool).
-- Coins, best times, medals, unlocks, collected coins, talents and pets go back to a fresh profile, and the admin's
-- entries are removed from the Top-10 boards and the hub "most stars" ranking (StarBoard reacts to the profile reset).
-- Other players are never touched; non-admin requests are ignored.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerProfile = require(ServerScriptService.PlayerProfile)
local Remotes = require(ServerScriptService.Remotes)
local handler = require(workspace.Handlers.PlayerTimerHandler)

-- 5 s between accepted resets per player: each reset writes several DataStore keys
Remotes.Admin(ReplicatedStorage:WaitForChild("ResetPlayerTimer"), 5, function(player)
	handler.ResetTimer(player, "reset")
	if not PlayerProfile.Reset(player) then
		return -- profile still loading
	end
	-- the services that mirror the profile (medals, unlocks, talents, pets, garden …) refresh through PlayerProfile.OnReady
	handler.UpdateScorePanel(player, nil)
	handler.RemoveFromGlobalLeaderboards(player.Name, player.UserId)
end)
