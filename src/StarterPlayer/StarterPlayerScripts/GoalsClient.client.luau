-- Goals (EV3b2, docs/UI_GARDEN_PETS.md §13): the tracker line and the Goals panel.
--   * tracker line: a wooden plate in the score panel's place (top right, under the coin plate) everywhere except on a stage
--     (player attribute HudStage, PlayerTimerHandler; there ScorePanelClient shows the run view): the next crop's goal,
--     "🥔 8 / 12 → 🥬 Lettuce" and a bar (the previous crop's plants toward the unlock, or the milestone quest's least-done piece,
--     GardenUi.NextGoal). When the goal changes (an unlock: FieldClient toasts it) the line pulses briefly. Hidden until the
--     first field state and once every crop is open. A tap opens / closes the panel. Line 2 (the day's requests) comes with E5.
--   * Goals panel (GardenUi.Panel, PanelFocus "Goals"): *Next crop*: the crop, how it opens and the count bar, or the quest's
--     pieces with Bring buttons (GardenRemotes.Quest, accepted anywhere: the server takes from the barn; FieldClient toasts the
--     answer); *Upgrades* (EV3c, only while a crop has a point to spend): a row per such crop with a button to its crop page
--     (GardenUi.OpenCropPage; its close comes back here). Re-renders on every State, a language change and a resize.
-- Display only: the field state comes from GardenRemotes.State (GardenView keeps the last one).
-- Hook (ScreenGui GoalsGui attribute, cleared after use): Open = true opens the panel. Paths: PlayerGui.GoalsLineGui.Line (.Goal its text)
-- (the line's button), PlayerGui.GoalsGui.Panel.Content.Next.Quest<CropId>.Bring, PlayerGui.GoalsGui.Panel.Content.Upgrades.<CropId>.Upgrade.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local PanelFocus = require(ReplicatedStorage:WaitForChild("PanelFocus"))
local UiKit = require(ReplicatedStorage:WaitForChild("UiKit"))
local GardenView = require(script.Parent:WaitForChild("GardenView"))
local GardenUi = require(script.Parent:WaitForChild("GardenUi"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
local remotes = ReplicatedStorage:WaitForChild("GardenRemotes")
local questEvent = remotes:WaitForChild("Quest")

local LINE_WIDTH = 250
local LINE_HEIGHT = 50
local PANEL_WIDTH = 400
local PANEL_HEIGHT = 300
local BRING_WIDTH = 110
local PULSE_SECONDS = 2

local COLOR = StudStyle.Colors.Wood
local COLOR_ROW = StudStyle.PetRowColor(COLOR)
local COLOR_TRACK = StudStyle.Shade(COLOR, 0.35)
local COLOR_FILL = StudStyle.Colors.Green

local create = UiKit.Create

-- Tracker line ------------------------------------------------------------------------------------------------------------

local lineGui = create("ScreenGui", {
	Name = "GoalsLineGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = false, -- the HUD's ScreenGui: the plate sits where its ScorePanel does
	ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	AutoLocalize = false,
})
local lineScale = create("UIScale", {})
local line = create("TextButton", {
	Name = "Line",
	AnchorPoint = Vector2.new(1, 0), -- the scale shrinks it towards the top right corner
	Position = UDim2.new(1, -12, 0, 12),
	Size = UDim2.fromOffset(LINE_WIDTH, LINE_HEIGHT),
	AutoButtonColor = false,
	Text = "",
	Visible = false,
	Parent = lineGui,
}, { lineScale })
StudStyle.Plate(line, COLOR)
local lineText = UiKit.Label("Goal", {
	Position = UDim2.fromOffset(10, 5),
	Size = UDim2.new(1, -20, 0, 24),
	TextScaled = true, -- a long (Czech) crop name shrinks instead of running off the plate
	TextXAlignment = Enum.TextXAlignment.Center,
	Parent = line,
})
create("UITextSizeConstraint", { MaxTextSize = 20, Parent = lineText })
StudStyle.Title(lineText, COLOR)
local lineBar, lineFill = UiKit.Bar("Bar", { height = 10, track = COLOR_TRACK, fill = COLOR_FILL, corner = 5, parent = line })
lineBar.Position = UDim2.fromOffset(12, 33)
lineBar.Size = UDim2.new(1, -24, 0, 10)
local pulse = UiKit.Pulse(lineText, 1.12, 0.5) -- on the text: the plate has its own UIScale
local pulseTimer = UiKit.Latest()

local shownTarget: string? = nil -- the goal's crop now on the line: a change pulses it

local function layoutLine()
	lineScale.Scale = math.clamp(camera.ViewportSize.Y / 600, 0.7, 1)
end

local function renderLine()
	local field = GardenView.OwnField()
	local goal = field and GardenUi.NextGoal(field)
	line.Visible = goal ~= nil and player:GetAttribute("HudStage") == nil
	if not goal then
		shownTarget = nil
		return
	end
	lineText.Text = Locale.T("goals.line", {
		icon = goal.from.icon,
		have = goal.have,
		need = goal.need,
		crop = GardenUi.CropTitle(goal.crop),
	})
	UiKit.SetShare(lineFill, goal.have / goal.need)
	if shownTarget and shownTarget ~= goal.crop.id then -- the line moves on to the next crop
		pulse(true)
		pulseTimer.After(PULSE_SECONDS, function()
			pulse(false)
		end)
	end
	shownTarget = goal.crop.id
end

-- Goals panel -------------------------------------------------------------------------------------------------------------

local ui = GardenUi.Panel("GoalsGui", COLOR, PANEL_WIDTH, PANEL_HEIGHT)
local nextSection = GardenUi.Section("Next", 1)
nextSection.Parent = ui.content
local upgradesSection = GardenUi.Section("Upgrades", 2)
upgradesSection.Parent = ui.content
local isOpen = false

-- EV3c: the crops with a point to spend, a row each with a button to its crop page (shown only while there is one).
local function renderUpgrades(field)
	GardenUi.Clear(upgradesSection)
	local crops = if field then GardenUi.CropsWithPoints(field) else {}
	if #crops == 0 then
		return
	end
	GardenUi.Heading(upgradesSection, 1, Locale.T("goals.upgrades.heading"), COLOR)
	local tap = ui.TapHeight()
	for index, crop in crops do
		local row = GardenUi.Row(upgradesSection, crop.id, index + 1, COLOR_ROW)
		GardenUi.TextColumn(
			row,
			BRING_WIDTH + GardenUi.GAP,
			GardenUi.CropTitle(crop) .. GardenUi.Stars(field, crop),
			Locale.T("field.cropPage.points", { count = GardenUi.FreePoints(field, crop) })
		)
		local button = GardenUi.Button("Upgrade", {
			LayoutOrder = 2,
			Size = UDim2.fromOffset(BRING_WIDTH, tap),
			BackgroundColor3 = GardenUi.COLOR_BUY,
			TextSize = 16,
			Text = Locale.T("goals.upgrades.open"),
			Parent = row,
		}, 2)
		local cropId = crop.id
		button.Activated:Connect(function()
			GardenUi.OpenCropPage(cropId, "GoalsGui")
		end)
	end
end

local function renderPanel()
	ui.title.Text = Locale.T("goals.title")
	if not isOpen then
		return
	end
	renderUpgrades(GardenView.OwnField())
	GardenUi.Clear(nextSection)
	GardenUi.Heading(nextSection, 1, Locale.T("goals.next.heading"), COLOR)
	local field = GardenView.OwnField()
	local goal = field and GardenUi.NextGoal(field)
	if not goal then
		GardenUi.Paragraph("AllOpen", {
			LayoutOrder = 2,
			TextSize = 15,
			TextColor3 = GardenUi.COLOR_INFO,
			Text = Locale.T(if field then "goals.next.allOpen" else "goals.next.loading"),
		}).Parent = nextSection
		return
	end
	local target = goal.crop
	local row = GardenUi.Row(nextSection, "Target", 2, COLOR_ROW)
	local hint = if target.quest
		then Locale.T("field.seed.questHint")
		else Locale.T("goals.next.countHint", { need = goal.need, crop = Locale.CropName(goal.from) })
	local column = GardenUi.TextColumn(row, 0, GardenUi.CropTitle(target), hint)
	if target.quest then
		GardenUi.QuestRows(nextSection, target, field, 2, { width = BRING_WIDTH, tap = ui.TapHeight(), color = StudStyle.Shade(COLOR_ROW, 0.85) }, function(id, amount)
			questEvent:FireServer(id, amount)
		end)
	else
		UiKit.Bar("Bar", {
			order = 3,
			height = 22,
			track = COLOR_TRACK,
			fill = COLOR_FILL,
			share = goal.have / goal.need,
			text = Locale.T("goals.next.bar", { icon = goal.from.icon, have = goal.have, need = goal.need }),
			textSize = 15,
			parent = column,
		})
	end
end

local function closePanel()
	PanelFocus.Closed("Goals")
	isOpen = false
	ui.panel.Visible = false
end

local function openPanel()
	PanelFocus.Open("Goals", closePanel) -- walking away closes it, as the HUD panels do
	isOpen = true
	ui.Fit()
	ui.panel.Visible = true
	renderPanel()
end

ui.close.Activated:Connect(closePanel)
line.Activated:Connect(function()
	if isOpen then
		closePanel()
	else
		openPanel()
	end
end)
ui.gui:GetAttributeChangedSignal("Open"):Connect(function()
	if ui.gui:GetAttribute("Open") == true then
		ui.gui:SetAttribute("Open", nil)
		openPanel()
	end
end)

-- Events ------------------------------------------------------------------------------------------------------------------

local function renderAll()
	renderLine()
	renderPanel()
end

remotes:WaitForChild("State").OnClientEvent:Connect(function()
	task.defer(renderAll) -- after GardenView took the new state
end)
Locale.Changed:Connect(renderAll)
player:GetAttributeChangedSignal("HudStage"):Connect(renderLine)
camera:GetPropertyChangedSignal("ViewportSize"):Connect(layoutLine)
ui.OnResize(renderPanel)

layoutLine()
renderAll()
lineGui.Parent = playerGui
ui.gui.Parent = playerGui
