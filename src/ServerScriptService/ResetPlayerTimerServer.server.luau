-- Admin panel "Reset Score": full progress reset of the admin who clicked it (debug tool).
-- Coins, best times, medals, unlocks, collected coins and talents go back to a fresh profile, and the admin's
-- entries are removed from the Top-10 boards. Other players are never touched; non-admin requests are ignored.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local AdminConfig = require(ReplicatedStorage.AdminConfig)
local PlayerProfile = require(ServerScriptService.PlayerProfile)
local StageResults = require(ServerScriptService.StageResults)
local handler = require(workspace.Handlers.PlayerTimerHandler)

local resetTimerEvent = ReplicatedStorage:WaitForChild("ResetPlayerTimer")

local COOLDOWN = 5 -- seconds; each reset writes several DataStore keys
local lastReset = {} -- [Player] = os.clock() of the last accepted reset

Players.PlayerRemoving:Connect(function(player)
	lastReset[player] = nil
end)

resetTimerEvent.OnServerEvent:Connect(function(player)
	if not AdminConfig.IsAdmin(player.UserId) then
		warn(string.format("ResetPlayerTimer: ignored request from non-admin %s (%d)", player.Name, player.UserId))
		return
	end
	local now = os.clock()
	if lastReset[player] and now - lastReset[player] < COOLDOWN then
		return
	end
	lastReset[player] = now

	handler.ResetTimer(player)
	if not PlayerProfile.Reset(player) then
		return -- profile still loading
	end
	StageResults.PublishMedals(player)
	handler.UpdateScorePanel(player, nil)
	handler.RemoveFromGlobalLeaderboards(player.Name)
end)
