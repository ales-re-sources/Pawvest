-- Results popup after a finished run (docs/GDD.md §4–5): time, record, medal of the run, medal payout, first-finish
-- payout, repeat reward,
-- pet XP (§7.4), free egg of the first Gold (§7.2), next goal.
-- Driven by the finish message StageTimerUpdate(-1, final, result); the GUI is built here, not in Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageTimerUpdate = ReplicatedStorage:WaitForChild("StageTimerUpdate")
local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local TimeFormat = require(ReplicatedStorage:WaitForChild("TimeFormat"))
local MedalText = require(ReplicatedStorage:WaitForChild("MedalText"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))

local SHOW_SECONDS = 7
local DIM = "#5A5A5A"

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StageResults"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 5
screenGui.Enabled = false
screenGui.AutoLocalize = false -- translated by Locale (L1)

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
	label.AutomaticSize = Enum.AutomaticSize.Y -- a long line (Czech) wraps and grows the panel
	label.TextWrapped = true
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
local finishLabel = addLine("FirstFinish", 7, 18)
local runLabel = addLine("RunReward", 8, 18)
local petLabel = addLine("PetXp", 9, 16)
local eggLabel = addLine("FreeEgg", 10, 16)
local nextLabel = addLine("Next", 11, 16)
coinsLabel.TextColor3 = Color3.fromRGB(120, 230, 120)
finishLabel.TextColor3 = Color3.fromRGB(120, 230, 120)
runLabel.TextColor3 = Color3.fromRGB(120, 230, 120)
petLabel.TextColor3 = Color3.fromRGB(180, 150, 255)
eggLabel.TextColor3 = Color3.fromRGB(255, 215, 90)
nextLabel.TextColor3 = Color3.fromRGB(190, 190, 190)

local showGeneration = 0
local shownResult = nil -- the result on screen, re-rendered when the language changes

local function hide()
	showGeneration += 1
	screenGui.Enabled = false
end

local function render(result)
	local stage = StageConfig.ByKey[result.stageKey]
	titleLabel.Text = Locale.T("results.title", { stage = if stage then Locale.StageName(stage) else result.displayName })
	timeLabel.Text = TimeFormat.Format(result.time)
	recordLabel.Text = if result.newBest
		then string.format('<font color="%s">%s</font>', MedalText.Gold, Locale.T("results.newRecord"))
		else Locale.T("results.record", { time = TimeFormat.Format(result.best) })
	starsLabel.Text = MedalText.Stars(result.medal, DIM)
	medalLabel.Text = if result.medal > 0
		then Locale.T("medal.label." .. StageConfig.Medals[result.medal].name)
		else Locale.T("results.noMedal")
	coinsLabel.Visible = result.coins > 0
	coinsLabel.Text = Locale.T("results.coins", { count = result.coins })
	local finishCoins = result.finishCoins or 0
	finishLabel.Visible = finishCoins > 0
	finishLabel.Text = Locale.T("results.firstFinish", { count = finishCoins })
	local runCoins = result.runCoins or 0
	runLabel.Visible = runCoins > 0
	runLabel.Text = Locale.T("results.runReward", { count = runCoins, run = result.runsToday or 1 })
	local petXp = result.petXp or 0
	petLabel.Visible = petXp > 0 and (result.petsLeveled or 0) > 0
	petLabel.Text = Locale.T("results.petXp", { xp = petXp, move = result.moveXp or 0 })
	local freeEgg = PetConfig.Eggs[result.freeEgg or ""]
	eggLabel.Visible = freeEgg ~= nil
	eggLabel.Text = if freeEgg then Locale.T("results.freeEgg", { egg = Locale.EggName(freeEgg) }) else ""
	if result.nextMedal and result.nextThreshold then
		nextLabel.Text = Locale.T("results.next", {
			medal = Locale.MedalName(StageConfig.Medals[result.nextMedal]),
			time = TimeFormat.Format(result.nextThreshold),
		})
	elseif result.nextMedal then
		nextLabel.Text = ""
	else
		nextLabel.Text = Locale.T("results.allMedals")
	end
end

local function show(result)
	shownResult = result
	render(result)

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

Locale.Changed:Connect(function()
	if screenGui.Enabled and shownResult then
		render(shownResult)
	end
end)

StageTimerUpdate.OnClientEvent:Connect(function(elapsed, _final, result)
	if elapsed >= 0 then
		hide() -- a new run started
	elseif result then
		show(result)
	end
end)

screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
