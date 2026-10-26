local Players = game:GetService("Players")
local StageConfig = require(game:GetService("ReplicatedStorage").StageConfig)
local TimerHandler = require(workspace.Handlers.PlayerTimerHandler)

local TeleportPart1 = script.Parent.Portal
local stage = StageConfig.ForInstance(script)
local destination = StageConfig.ReturnCFrame(stage) -- in front of the hub portal that led here, looking out of it

TeleportPart1.Touched:Connect(function(hit)
	local w = hit.Parent:FindFirstChild("HumanoidRootPart")
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if w and player then
		w.CFrame = destination

		-- leaving the stage cancels a running timer
		TimerHandler.ResetTimer(player)
		TimerHandler.UpdateScorePanel(player, StageConfig.LocationKey(stage))
	end
end)
