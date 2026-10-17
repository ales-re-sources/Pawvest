local TimerHandler = require(workspace.Handlers.PlayerTimerHandler)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageTimerStopped = ReplicatedStorage:WaitForChild("StageTimerStopped")

lastHitPart = nil

script.Parent.Touched:Connect(function(hit)
	if script.Parent ~= lastHitPart and game.Players:FindFirstChild(hit.Parent.Name) then
		lastHitPart = script.Parent
		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
		local elapsed = TimerHandler.StopTimer(player)
	end
end)

-- timer stop or timer reset (user left through portal) - make it possible to touch it again
StageTimerStopped.OnServerEvent:Connect(function(player)
	lastHitPart = nil
end)
