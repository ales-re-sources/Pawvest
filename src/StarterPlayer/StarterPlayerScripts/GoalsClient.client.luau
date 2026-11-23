-- Goals (EV3b2, docs/UI_GARDEN_PETS.md §13): the tracker line and the Goals panel.
--   * tracker line: a wooden plate in the score panel's place (top right, under the coin plate) everywhere except on a stage
--     (player attribute HudStage, PlayerTimerHandler; there ScorePanelClient shows the run view): the next crop's goal,
--     "🥔 8 / 12 → 🥬 Lettuce" and a bar (the previous crop's plants toward the unlock, or the milestone quest's least-done piece,
--     GardenUi.NextGoal). When the goal changes (an unlock: FieldClient toasts it) the line pulses briefly. Hidden until the
--     first field state and once every crop is open. A tap opens / closes the panel. Line 2 (E5a, plate "Request", under line 1 or
--     in its place): the open request the player ticked in the panel, else the one nearest to done, "🍅 4 / 6 → 💰" and a bar; it
--     pulses when it moves on to another request.
--   * Goals panel (GardenUi.Panel, PanelFocus "Goals"): *Next crop*: the crop, how it opens and the count bar, or the quest's
--     pieces with Bring buttons (GardenRemotes.Quest, accepted anywhere: the server takes from the barn; FieldClient toasts the
--     answer); *Upgrades* (EV3c, only while a crop has a point to spend): a row per such crop with a button to its crop page
--     (GardenUi.OpenCropPage; its close comes back here); *Today's requests* (E5a, State.field.requests): a row per request (the
--     crop and count, the reward in Coins or, once done, the time to the next UTC day; a bar; an eye toggle "Focus" on open rows while
--     2+ are open picks the request line 2 shows), or before the board opens the crop that
--     opens it. Re-renders on every State, a language change and a resize.
-- Display only: the field state comes from GardenRemotes.State (GardenView keeps the last one).
-- Hook (ScreenGui GoalsGui attribute, cleared after use): Open = true opens the panel. Paths: PlayerGui.GoalsLineGui.Line (.Goal its text)
-- (the line's button), PlayerGui.GoalsLineGui.Request (line 2), PlayerGui.GoalsGui.Panel.Content.Requests.Slot<n>,
-- PlayerGui.GoalsGui.Panel.Content.Next.Quest<CropId>.Bring, PlayerGui.GoalsGui.Panel.Content.Upgrades.<CropId>.Upgrade.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local TimeFormat = require(ReplicatedStorage:WaitForChild("TimeFormat"))
local PanelFocus = require(ReplicatedStorage:WaitForChild("PanelFocus"))
local UiKit = require(ReplicatedStorage:WaitForChild("UiKit"))
local Onboarding = require(script.Parent:WaitForChild("Onboarding"))
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
local TICK_SIZE = 34 -- the request rows' "show on screen" checkbox
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
-- A wooden plate with one line of text and a bar (line 1: the next crop, line 2: the day's request nearest to done).
local function newPlate(name: string)
	local scale = create("UIScale", {})
	local plate = create("TextButton", {
		Name = name,
		AnchorPoint = Vector2.new(1, 0), -- the scale shrinks it towards the top right corner
		Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.fromOffset(LINE_WIDTH, LINE_HEIGHT),
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		Parent = lineGui,
	}, { scale })
	StudStyle.Plate(plate, COLOR)
	local text = UiKit.Label("Goal", {
		Position = UDim2.fromOffset(10, 5),
		Size = UDim2.new(1, -20, 0, 24),
		TextScaled = true, -- a long (Czech) crop name shrinks instead of running off the plate
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = plate,
	})
	create("UITextSizeConstraint", { MaxTextSize = 20, Parent = text })
	StudStyle.Title(text, COLOR)
	local bar, fill = UiKit.Bar("Bar", { height = 10, track = COLOR_TRACK, fill = COLOR_FILL, corner = 5, parent = plate })
	bar.Position = UDim2.fromOffset(12, 33)
	bar.Size = UDim2.new(1, -24, 0, 10)
	local pulse = UiKit.Pulse(text, 1.12, 0.5) -- on the text: the plate has its own UIScale
	local timer = UiKit.Latest()
	local holding = false
	return {
		plate = plate,
		scale = scale,
		text = text,
		fill = fill,
		shown = nil :: string?, -- what the plate shows now: a change pulses it
		pulse = function()
			pulse(true)
			timer.After(PULSE_SECONDS, function()
				pulse(holding)
			end)
		end,
		hold = function(on: boolean) -- E5c: a pulse that stays on while `on`
			if on ~= holding then
				holding = on
				timer.Cancel()
				pulse(on)
			end
		end,
	}
end

local goalPlate = newPlate("Line")
local requestPlate = newPlate("Request") -- E5a
local line = goalPlate.plate

local function layoutLine()
	local scale = math.clamp(camera.ViewportSize.Y / 600, 0.7, 1)
	goalPlate.scale.Scale = scale
	requestPlate.scale.Scale = scale
	local below = if line.Visible then (LINE_HEIGHT + 6) * scale else 0 -- line 2 moves up when line 1 is hidden
	requestPlate.plate.Position = UDim2.new(1, -12, 0, 12 + below)
end

-- The request the player ticked in the panel for line 2 (a slot index; nil = automatic: the one nearest to done). Kept for the
-- session and dropped when the day's board changes (`focusDay` = the board's endsAt it was ticked on).
local focusSlot: number? = nil
local focusDay: number? = nil

-- E5a: the request line 2 shows: the ticked open request, else the open one nearest to done (the highest share; ties: the first
-- slot), or nil. Second result: its slot index.
local function nearestRequest(field)
	local board = field and field.requests
	local slots = if type(board) == "table" and type(board.slots) == "table" then board.slots else {}
	if type(board) == "table" and board.endsAt ~= focusDay then
		focusSlot, focusDay = nil, board.endsAt
	end
	local picked = focusSlot and slots[focusSlot]
	if picked and not picked.done and CropConfig.ById[picked.crop] then
		return picked, focusSlot
	end
	local best, bestIndex, bestShare = nil, nil, -1
	for index, slot in slots do
		local share = slot.have / math.max(1, slot.need)
		if not slot.done and CropConfig.ById[slot.crop] and share > bestShare then
			best, bestIndex, bestShare = slot, index, share
		end
	end
	return best, bestIndex
end

local isOpen = false -- the Goals panel (below)

local function renderLine()
	local field = GardenView.OwnField()
	local onStage = player:GetAttribute("HudStage") ~= nil
	local goal = field and GardenUi.NextGoal(field)
	line.Visible = goal ~= nil and not onStage
	if goal then
		goalPlate.text.Text = Locale.T("goals.line", {
			icon = goal.from.icon,
			have = goal.have,
			need = goal.need,
			crop = GardenUi.CropTitle(goal.crop),
		})
		UiKit.SetShare(goalPlate.fill, goal.have / goal.need)
		if goalPlate.shown and goalPlate.shown ~= goal.crop.id then -- the line moves on to the next crop
			goalPlate.pulse()
		end
	end
	goalPlate.shown = if goal then goal.crop.id else nil
	goalPlate.hold(line.Visible and not isOpen and Onboarding.Is("quests")) -- E5c step 7: open the Goals panel
	local request = nearestRequest(field)
	requestPlate.plate.Visible = request ~= nil and not onStage
	if request then
		local crop = CropConfig.ById[request.crop]
		requestPlate.text.Text = Locale.T("goals.requests.line", { icon = crop.icon, have = request.have, need = request.need })
		UiKit.SetShare(requestPlate.fill, request.have / request.need)
		local key = request.crop .. ":" .. request.need
		if requestPlate.shown and requestPlate.shown ~= key then -- a request was done: the line moves on
			requestPlate.pulse()
		end
		requestPlate.shown = key -- kept while no request is open: the next day's first one pulses
	end
	layoutLine()
end

-- Goals panel -------------------------------------------------------------------------------------------------------------

local ui = GardenUi.Panel("GoalsGui", COLOR, PANEL_WIDTH, PANEL_HEIGHT)
local nextSection = GardenUi.Section("Next", 1)
nextSection.Parent = ui.content
local requestsSection = GardenUi.Section("Requests", 2) -- E5a
requestsSection.Parent = ui.content
local upgradesSection = GardenUi.Section("Upgrades", 3)
upgradesSection.Parent = ui.content
local renderPanel -- below (the request rows' checkboxes re-render it)
local countdowns = {} -- [TextLabel] = true: done rows' "New request in 5:12:00" (ticked while the panel is open)
local requestsEndAt = 0

-- The crop whose unlock opens the requests (the second crop they may ask for), for the row shown before they open.
local function requestsOpenWith()
	local found = 0
	for _, crop in CropConfig.Ladder do
		if crop.order >= CropConfig.Requests.MinOrder and crop.growSeconds <= CropConfig.Requests.MaxGrow then
			found += 1
			if found == 2 then
				return crop
			end
		end
	end
	return nil
end

local function countdownText(): string
	local left = math.max(0, requestsEndAt - workspace:GetServerTimeNow())
	return Locale.T("goals.requests.next", { time = TimeFormat.Clock(left) })
end

-- E5a: today's three requests, a row each (crop, reward or "done" with the time to the next day, bar).
local function renderRequests(field)
	GardenUi.Clear(requestsSection)
	table.clear(countdowns)
	GardenUi.Heading(requestsSection, 1, Locale.T("goals.requests.heading"), COLOR)
	local board = field and field.requests
	local slots = if type(board) == "table" and type(board.slots) == "table" then board.slots else {}
	requestsEndAt = if type(board) == "table" and type(board.endsAt) == "number" then board.endsAt else 0
	if #slots == 0 then
		local opener = requestsOpenWith()
		GardenUi.Paragraph("Locked", {
			LayoutOrder = 2,
			TextSize = 15,
			TextColor3 = GardenUi.COLOR_INFO,
			Text = if field and opener
				then Locale.T("goals.requests.locked", { crop = GardenUi.CropTitle(opener) })
				else Locale.T("goals.next.loading"),
		}).Parent = requestsSection
		return
	end
	local _, shownIndex = nearestRequest(field)
	local open = 0
	for _, slot in slots do
		if not slot.done then
			open += 1
		end
	end
	for index, slot in slots do
		local crop = CropConfig.ById[slot.crop]
		if crop then
			local row = GardenUi.Row(requestsSection, "Slot" .. index, index + 2, COLOR_ROW)
			local info = if slot.done then countdownText() else Locale.T("goals.requests.reward", { count = slot.bonus })
			local tickable = not slot.done and open > 1
			local column = GardenUi.TextColumn(
				row,
				if tickable then TICK_SIZE + GardenUi.GAP else 0,
				Locale.T("goals.requests.grow", { need = slot.need, crop = GardenUi.CropTitle(crop) }),
				info
			)
			if tickable then -- the checkbox: this request is the one shown at the top of the screen
				local ticked = index == shownIndex
				local box = GardenUi.Button("Focus", {
					LayoutOrder = 2,
					Size = UDim2.fromOffset(TICK_SIZE, TICK_SIZE),
					BackgroundColor3 = if ticked then GardenUi.COLOR_BUY else COLOR_TRACK,
					TextSize = 20,
					Text = "👁",
					TextTransparency = if ticked then 0 else 0.65,
					Parent = row,
				}, { compact = true })
				box.Activated:Connect(function()
					focusSlot, focusDay = index, board.endsAt -- one request at a time: ticking another moves the tick
					renderLine()
					renderPanel()
				end)
			end
			if slot.done then
				local label = column:FindFirstChild("Info", true)
				if label and label:IsA("TextLabel") then
					countdowns[label] = true
				end
			end
			UiKit.Bar("Bar", {
				order = 3,
				height = 22,
				track = COLOR_TRACK,
				fill = COLOR_FILL,
				share = slot.have / math.max(1, slot.need),
				text = if slot.done
					then Locale.T("goals.requests.done")
					else Locale.T("goals.next.bar", { icon = crop.icon, have = slot.have, need = slot.need }),
				textSize = 15,
				parent = column,
			})
		end
	end
end

-- EV3c: the crops with a point to spend, a row each with a button to its crop page (shown only while there is one).
local function renderUpgrades(field)
	GardenUi.Clear(upgradesSection)
	local crops = if field then GardenUi.CropsWithPoints(field) else {}
	upgradesSection.Visible = #crops > 0
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

function renderPanel()
	ui.title.Text = Locale.T("goals.title")
	if not isOpen then
		return
	end
	renderRequests(GardenView.OwnField())
	renderUpgrades(GardenView.OwnField())
	GardenUi.Clear(nextSection)
	local field = GardenView.OwnField()
	local goal = field and GardenUi.NextGoal(field)
	nextSection.Visible = not (field and not goal) -- every crop is unlocked: no "Next crop" section (an empty one would still leave a gap)
	if not nextSection.Visible then
		return
	end
	GardenUi.Heading(nextSection, 1, Locale.T("goals.next.heading"), COLOR)
	if not goal then
		GardenUi.Paragraph("AllOpen", {
			LayoutOrder = 2,
			TextSize = 15,
			TextColor3 = GardenUi.COLOR_INFO,
			Text = Locale.T("goals.next.loading"),
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
	renderLine()
end

local function openPanel()
	PanelFocus.Open("Goals", closePanel) -- walking away closes it, as the HUD panels do
	isOpen = true
	Onboarding.Seen("quests") -- E5c step 7
	renderLine()
	ui.Fit()
	ui.panel.Visible = true
	renderPanel()
end

ui.close.Activated:Connect(closePanel)
local function togglePanel()
	if isOpen then
		closePanel()
	else
		openPanel()
	end
end
line.Activated:Connect(togglePanel)
requestPlate.plate.Activated:Connect(togglePanel)
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
Onboarding.Changed:Connect(renderLine) -- E5c
camera:GetPropertyChangedSignal("ViewportSize"):Connect(layoutLine)
ui.OnResize(renderPanel)

-- the done rows' countdowns tick while the panel is open (a new UTC day brings the State with the refilled board)
task.spawn(function()
	while true do
		task.wait(1)
		if isOpen and next(countdowns) then
			local text = countdownText()
			for label in countdowns do
				label.Text = text
			end
		end
	end
end)

layoutLine()
renderAll()
lineGui.Parent = playerGui
ui.gui.Parent = playerGui
