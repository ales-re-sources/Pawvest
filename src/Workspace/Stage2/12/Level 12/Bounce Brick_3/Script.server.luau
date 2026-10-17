local RunService = game:GetService("RunService")

local part = script.Parent

local function updateVelocity()
	part.Velocity = part.CFrame.LookVector * 1300
end

local heartbeatConnection
heartbeatConnection = RunService.Heartbeat:Connect(function()
	updateVelocity()
end)

-- Optionally, disconnect when the part is destroyed
part.AncestryChanged:Connect(function(_, parent)
	if not parent and heartbeatConnection then
		heartbeatConnection:Disconnect()
	end
end)
