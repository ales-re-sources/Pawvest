-- Results popup after a finished run (docs/GDD.md §4): time, record, medal of the run, Coins paid, next goal.
-- Driven by the finish message StageTimerUpdate(-1, final, result); the GUI is built here, not in Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageTimerUpdate = ReplicatedStorage:WaitForChild("StageTimerUpdate")
local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local TimeFormat = require(ReplicatedStorage:WaitForChild("TimeFormat"))

local SHOW_SECONDS = 7
local GOLD = "#FFD54A"
local DIM = "#5A5A5A"

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StageResults"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 5
screenGui.Enabled = false

local panel = Instance.new("TextButton") -- a button so a click closes it
panel.Name = "Panel"
panel.AutoButtonColor = false
panel.Text = ""
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 80)
panel.Size = UDim2.fromOffset(320, 0)
panel.AutomaticSize = Enum.AutomaticSize.Y
panel.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
panel.BackgroundTransparency = 0.1
panel.Parent = screenGui

Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 12)
padding.PaddingBottom = UDim.new(0, 14)
padding.Parent = panel

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Padding = UDim.new(0, 2)
layout.Parent = panel

local function addLine(name, order, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.LayoutOrder = order
	label.Size = UDim2.new(1, -24, 0, textSize + 6)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = textSize
	label.TextColor3 = Color3.new(1, 1, 1)
	label.RichText = true
	label.Text = ""
	label.Parent = panel
	return label
end

local titleLabel = addLine("Title", 1, 20)
local timeLabel = addLine("Time", 2, 40)
local recordLabel = addLine("Record", 3, 18)
local starsLabel = addLine("Stars", 4, 36)
local medalLabel = addLine("Medal", 5, 18)
local coinsLabel = addLine("Coins", 6, 22)
local nextLabel = addLine("Next", 7, 16)
coinsLabel.TextColor3 = Color3.fromRGB(120, 230, 120)
nextLabel.TextColor3 = Color3.fromRGB(190, 190, 190)

local function stars(medal)
	local total = #StageConfig.Medals
	return string.format('<font color="%s">%s</font><font color="%s">%s</font>',
		GOLD, string.rep("★", medal), DIM, string.rep("★", total - medal))
end

local showGeneration = 0

local function hide()
	showGeneration += 1
	screenGui.Enabled = false
end

local function show(result)
	titleLabel.Text = result.displayName .. " finished"
	timeLabel.Text = TimeFormat.Format(result.time)
	recordLabel.Text = if result.newBest
		then string.format('<font color="%s">New record!</font>', GOLD)
		else "Record: " .. TimeFormat.Format(result.best)
	starsLabel.Text = stars(result.medal)
	medalLabel.Text = if result.medal > 0 then StageConfig.Medals[result.medal].name .. " medal" else "No medal"
	coinsLabel.Visible = result.coins > 0
	coinsLabel.Text = string.format("+%d Coins", result.coins)
	if result.nextMedal and result.nextThreshold then
		nextLabel.Text = string.format("Next: %s under %s",
			StageConfig.Medals[result.nextMedal].name, TimeFormat.Format(result.nextThreshold))
	elseif result.nextMedal then
		nextLabel.Text = ""
	else
		nextLabel.Text = "All medals earned!"
	end

	showGeneration += 1
	local generation = showGeneration
	screenGui.Enabled = true
	task.delay(SHOW_SECONDS, function()
		if generation == showGeneration then
			hide()
		end
	end)
end

panel.Activated:Connect(hide)

StageTimerUpdate.OnClientEvent:Connect(function(elapsed, _final, result)
	if elapsed >= 0 then
		hide() -- a new run started
	elseif result then
		show(result)
	end
end)

screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
