-- StageExploreWarning: the server (CheckpointTouchHandler, ExploreWarning remote) reports that the player reached a checkpoint
-- of a stage without a running timer for it, i.e. they got in around the gate (over the courtyard wall, a locked gate).
-- That is allowed, but it is an exploring run: no time, medal or finish reward counts, collected Coins do. A banner says so
-- for a few seconds; it goes away at once when a timed run starts. GUI built in code.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local exploreEvent = ReplicatedStorage:WaitForChild("ExploreWarning")
local StageTimerUpdate = ReplicatedStorage:WaitForChild("StageTimerUpdate")

local player = Players.LocalPlayer

local SHOW_SECONDS = 9
local FADE_SECONDS = 0.4

local label = Instance.new("TextLabel")
label.Name = "Text"
label.Size = UDim2.new(1, -24, 0, 0)
label.AutomaticSize = Enum.AutomaticSize.Y
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamMedium
label.TextSize = 16
label.TextColor3 = Color3.new(1, 1, 1)
label.TextWrapped = true
label.RichText = true
label.Text = ""

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.new(0.5, 0, 1, -110)
panel.Size = UDim2.fromOffset(440, 0)
panel.AutomaticSize = Enum.AutomaticSize.Y
panel.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
panel.BackgroundTransparency = 0.1
label.Parent = panel
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel
local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 12)
padding.PaddingRight = UDim.new(0, 12)
padding.Parent = panel
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 190, 60)
stroke.Thickness = 2
stroke.Parent = panel

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StageExploreWarning"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 5
screenGui.Enabled = false
panel.Parent = screenGui
screenGui.Parent = player:WaitForChild("PlayerGui")

local generation = 0

local function hide()
	generation += 1
	screenGui.Enabled = false
end

local function show(stageKey: string)
	local stage = StageConfig.ByKey[stageKey]
	if not stage then
		return
	end
	generation += 1
	local mine = generation
	label.Text = string.format(
		"<b>Exploring %s without a timer</b>\nYou got in around the gate: no time, medal or finish reward counts here, but Coins you pick up do. Go through the gate to run it for real. Carrying on is at your own risk.",
		stage.displayName
	)
	panel.BackgroundTransparency = 0.1
	label.TextTransparency = 0
	stroke.Transparency = 0
	screenGui.Enabled = true
	task.delay(SHOW_SECONDS, function()
		if mine ~= generation then
			return
		end
		local info = TweenInfo.new(FADE_SECONDS)
		TweenService:Create(panel, info, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(label, info, { TextTransparency = 1 }):Play()
		TweenService:Create(stroke, info, { Transparency = 1 }):Play()
		task.delay(FADE_SECONDS, function()
			if mine == generation then
				hide()
			end
		end)
	end)
end

exploreEvent.OnClientEvent:Connect(show)

-- a timed run started: the warning no longer applies
StageTimerUpdate.OnClientEvent:Connect(function(elapsed)
	if type(elapsed) == "number" and elapsed >= 0 then
		hide()
	end
end)
