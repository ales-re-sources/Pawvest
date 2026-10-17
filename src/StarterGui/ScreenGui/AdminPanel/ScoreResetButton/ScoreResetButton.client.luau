local ReplicatedStorage = game:GetService("ReplicatedStorage")
local resetTimerEvent = ReplicatedStorage:WaitForChild("ResetPlayerTimer")

script.Parent.Activated:Connect(function()
    resetTimerEvent:FireServer()
end)

