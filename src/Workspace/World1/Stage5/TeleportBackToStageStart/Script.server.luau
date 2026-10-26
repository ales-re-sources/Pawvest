local StageConfig = require(game:GetService("ReplicatedStorage").StageConfig)
local TeleportPart1 = script.Parent.Portal
local TeleportPart2 = script.Parent.Parent.Arrival

TeleportPart1.Touched:Connect(function(hit)
	local w = hit.Parent:FindFirstChild("HumanoidRootPart")
	if w then
		w.CFrame = StageConfig.ArrivalCFrame(TeleportPart2)
		TeleportPart2.CanTouch = false
		wait(1)
		TeleportPart2.CanTouch = true
	end
end)
