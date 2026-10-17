local TeleportPart1 = script.Parent.Portal
local TeleportPart2 = workspace.StartLocation.SpawnLocation

local TimerHandler = require(workspace.Handlers.PlayerTimerHandler)

TeleportPart1.Touched:Connect(function(hit)
	local w = hit.Parent:FindFirstChild("HumanoidRootPart")
	if w then
		w.CFrame = TeleportPart2.CFrame + Vector3.new(0, 5, 0)
		TeleportPart2.CanTouch = false
		wait(1)
		TeleportPart2.CanTouch = true

		-- also reset timer if it's running
		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
		TimerHandler.ResetTimer(player)

		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
		TimerHandler.UpdateScorePanel(player, "Central Island")
	end
end)
