local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageTimerUpdate = ReplicatedStorage:WaitForChild("StageTimerUpdate")
local StageTimerStopped = ReplicatedStorage:WaitForChild("StageTimerStopped")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local stageTimerLabel = nil

local function updateStageTimerLabelReference()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if gui then
        local screenGui = gui:FindFirstChild("ScreenGui")
        if screenGui then
            stageTimerLabel = screenGui:FindFirstChild("StageTimer")
        else
            stageTimerLabel = nil
        end
    else
        stageTimerLabel = nil
    end
end

local function fadeOutLabel(label)
	--blinkFadeActive = true

	-- Blink red 3x
	local originalColor = label.TextColor3
	for i = 1, 3 do
		--if not blinkFadeActive then break end
		label.TextColor3 = Color3.new(1, 0, 0) -- Red
		label.Visible = true
		task.wait(0.25)
		--if not blinkFadeActive then break end
		label.TextColor3 = originalColor
		task.wait(0.25)
	end

	-- Fade out over 1.5 seconds
	local fadeTime = 1.5
	local steps = 15
	local startTransparency = label.TextTransparency
	local startStrokeTransparency = label.TextStrokeTransparency
	for i = 1, steps do
		--if not blinkFadeActive then break end
		local alpha = i / steps
		label.TextTransparency = startTransparency + (1 - startTransparency) * alpha
		label.TextStrokeTransparency = startStrokeTransparency + (1 - startStrokeTransparency) * alpha
		task.wait(fadeTime / steps)
	end

	-- Hide label
	label.Visible = false
	label.TextTransparency = 0
	label.TextStrokeTransparency = 0
end

-- Initial reference
updateStageTimerLabelReference()

-- Update reference on respawn
LocalPlayer.CharacterAdded:Connect(function()
    -- Wait a short moment for PlayerGui to be rebuilt
    task.wait(0.5)
    updateStageTimerLabelReference()
end)

StageTimerUpdate.OnClientEvent:Connect(function(elapsed)
    if not stageTimerLabel then
        updateStageTimerLabelReference()
    end
	if stageTimerLabel then
		if (elapsed == -1) then
			-- Fire callback to server to reset lastHitPart of 'timer start' object
			StageTimerStopped:FireServer()
			
			fadeOutLabel(stageTimerLabel)
			stageTimerLabel.Visible = false
			stageTimerLabel.Text = "00:00"
		else
	        local minutes = math.floor(elapsed / 60)
	        local seconds = elapsed % 60
	        stageTimerLabel.Text = string.format("%02d:%02d", minutes, seconds)
			stageTimerLabel.Visible = true
		end
    end
end)
