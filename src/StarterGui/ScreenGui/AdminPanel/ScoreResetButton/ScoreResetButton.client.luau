-- Admin "Reset Score": wipes ALL of the admin's own progress (see ResetPlayerTimerServer), so it needs a second click.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local resetTimerEvent = ReplicatedStorage:WaitForChild("ResetPlayerTimer")

local CONFIRM_SECONDS = 3

local button = script.Parent
local idleText = button.Text
local armedUntil = 0

script.Parent.Activated:Connect(function()
	if os.clock() < armedUntil then
		armedUntil = 0
		button.Text = idleText
		resetTimerEvent:FireServer()
		return
	end
	armedUntil = os.clock() + CONFIRM_SECONDS
	button.Text = "Click again to confirm"
	task.delay(CONFIRM_SECONDS, function()
		if os.clock() >= armedUntil then
			button.Text = idleText
		end
	end)
end)
