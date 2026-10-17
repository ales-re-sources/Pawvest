local TimerHandler = require(workspace.Handlers.PlayerTimerHandler)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageTimerStopped = ReplicatedStorage:WaitForChild("StageTimerStopped")
local TouchHandler = require(workspace.Handlers.CheckpointTouchHandler)

lastHitPart = nil

script.Parent.Touched:Connect(function(hit)
	local player = game.Players:GetPlayerFromCharacter(hit.Parent)

	if script.Parent ~= lastHitPart and game.Players:FindFirstChild(hit.Parent.Name) then
		lastHitPart = script.Parent
		TimerHandler.StartTimer(player, "Stage 4")
	end
	
	TouchHandler.OnTouched(script.Parent, hit)
end)

-- timer stop or timer reset (user left through portal) - make it possible to touch it again
StageTimerStopped.OnServerEvent:Connect(function(player)
	lastHitPart = nil
end)
