local Players = game:GetService("Players")
local StageConfig = require(game:GetService("ReplicatedStorage").StageConfig)
local TimerHandler = require(workspace.Handlers.PlayerTimerHandler)

local TeleportPart1 = script.Parent.Portal
local stage = StageConfig.ForInstance(script)
local TeleportPart2 = StageConfig.ReturnSpawn(stage)

TeleportPart1.Touched:Connect(function(hit)
	local w = hit.Parent:FindFirstChild("HumanoidRootPart")
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if w and player then
		w.CFrame = TeleportPart2.CFrame + Vector3.new(0, 5, 0)

		-- leaving the stage cancels a running timer
		TimerHandler.ResetTimer(player)
		TimerHandler.UpdateScorePanel(player, StageConfig.LocationKey(stage))

		TeleportPart2.CanTouch = false
		task.wait(1)
		TeleportPart2.CanTouch = true
	end
end)
