-- Admin "Reset Score": wipes ALL of the admin's own progress (see ResetPlayerTimerServer), so it needs a second click
-- (ConfirmTap).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConfirmTap = require(ReplicatedStorage:WaitForChild("ConfirmTap"))
local resetTimerEvent = ReplicatedStorage:WaitForChild("ResetPlayerTimer")

local KEY = "AdminResetScore"

local button = script.Parent
local idleText = button.Text

script.Parent.Activated:Connect(function()
	if ConfirmTap.Tap(KEY, function()
		button.Text = idleText
	end) then
		button.Text = idleText
		resetTimerEvent:FireServer()
		return
	end
	button.Text = "Click again to confirm"
end)
