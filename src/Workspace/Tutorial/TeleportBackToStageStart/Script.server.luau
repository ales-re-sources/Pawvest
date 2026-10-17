local TeleportPart1 = script.Parent.Portal
local TeleportPart2 = script.Parent.Parent.LandingPad.TeleportDestination

TeleportPart1.Touched:Connect(function(hit)
	local w = hit.Parent:FindFirstChild("HumanoidRootPart")
	if w then
		w.CFrame = TeleportPart2.CFrame + Vector3.new(0, 5, 0)
		TeleportPart2.CanTouch = false
		wait(1)
		TeleportPart2.CanTouch = true
	end
end)
