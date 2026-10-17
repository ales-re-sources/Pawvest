-- Shows the stage timer label. The server sends start / finish / cancel on StageTimerUpdate
-- (see PlayerTimerHandler); while a run is active the label counts locally every frame and shows the best medal
-- still reachable with its limit (docs/GDD.md §4).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StageTimerUpdate = ReplicatedStorage:WaitForChild("StageTimerUpdate")
local TimeFormat = require(ReplicatedStorage:WaitForChild("TimeFormat"))
local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local MedalText = require(ReplicatedStorage:WaitForChild("MedalText"))
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local stageTimerLabel = nil
local labelDefaults = nil -- look of a fresh label, restored after a fade

local TARGET_TEXT_SIZE = 22

local runStartClock = nil -- os.clock() at which the active run started; nil when no run is active
local runStage = nil -- StageConfig entry of the active run
local fadeGeneration = 0 -- bumped by every server message so a running fade knows it is stale

-- The label lives in a ResetOnSpawn ScreenGui, so it is replaced on every respawn
local function updateStageTimerLabelReference()
	local gui = LocalPlayer:FindFirstChild("PlayerGui")
	local screenGui = gui and gui:FindFirstChild("ScreenGui")
	stageTimerLabel = screenGui and screenGui:FindFirstChild("StageTimer")
	if stageTimerLabel then
		stageTimerLabel.RichText = true
		labelDefaults = {
			TextColor3 = stageTimerLabel.TextColor3,
			TextTransparency = stageTimerLabel.TextTransparency,
			TextStrokeTransparency = stageTimerLabel.TextStrokeTransparency,
		}
	end
end

local function restoreLabel(label)
	for property, value in labelDefaults do
		label[property] = value
	end
end

local function fadeOutLabel(label, generation)
	local function stale()
		return generation ~= fadeGeneration or label ~= stageTimerLabel
	end

	-- Blink red 3x
	for i = 1, 3 do
		label.TextColor3 = Color3.new(1, 0, 0) -- Red
		label.Visible = true
		task.wait(0.25)
		label.TextColor3 = labelDefaults.TextColor3
		task.wait(0.25)
		if stale() then
			restoreLabel(label)
			return
		end
	end

	-- Fade out over 1.5 seconds
	local fadeTime = 1.5
	local steps = 15
	for i = 1, steps do
		local alpha = i / steps
		label.TextTransparency = labelDefaults.TextTransparency + (1 - labelDefaults.TextTransparency) * alpha
		label.TextStrokeTransparency = labelDefaults.TextStrokeTransparency
			+ (1 - labelDefaults.TextStrokeTransparency) * alpha
		task.wait(fadeTime / steps)
		if stale() then
			restoreLabel(label)
			return
		end
	end

	-- Hide label
	label.Visible = false
	restoreLabel(label)
end

RunService.RenderStepped:Connect(function()
	if not runStartClock then
		return
	end
	if not (stageTimerLabel and stageTimerLabel.Parent) then
		updateStageTimerLabelReference()
	end
	if stageTimerLabel then
		local elapsed = os.clock() - runStartClock
		local text = TimeFormat.Format(elapsed)
		if runStage then
			text ..= string.format('  <font size="%d">%s</font>', TARGET_TEXT_SIZE, MedalText.Target(runStage, elapsed))
		end
		stageTimerLabel.Text = text
		stageTimerLabel.Visible = true
	end
end)

StageTimerUpdate.OnClientEvent:Connect(function(elapsed, extra)
	fadeGeneration += 1
	if not (stageTimerLabel and stageTimerLabel.Parent) then
		updateStageTimerLabelReference()
	end

	if elapsed >= 0 then
		runStartClock = os.clock() - elapsed
		runStage = StageConfig.ByKey[extra] -- start message carries the stage key
		if stageTimerLabel then
			restoreLabel(stageTimerLabel)
		end
		return
	end

	local finalElapsed = extra -- finish message carries the final time; cancel carries nothing
	runStartClock = nil
	runStage = nil
	if not stageTimerLabel then
		return
	end
	if finalElapsed then
		-- finished: show the official server time, then blink and fade
		stageTimerLabel.Text = TimeFormat.Format(finalElapsed)
		task.spawn(fadeOutLabel, stageTimerLabel, fadeGeneration)
	else
		-- cancelled
		stageTimerLabel.Visible = false
	end
end)
