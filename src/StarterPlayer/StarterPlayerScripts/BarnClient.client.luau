-- Barn (U4, docs/UI_GARDEN_PETS.md §6): what the player holds from the field. Two entries: the barn building's "Open barn" prompt on
-- the own plot (U5a, PlotView via GardenView.OnBarn) and the bottom-centre HUD button "🧺 Barn" (shown within 45 studs of the own plot
-- and, while the player holds crops, anywhere outside a stage run; a young field gets a toast at the first harvest of the session and
-- the button pulses until the barn was opened: playtest 2026-11-08).
--   * header: the crow forecast (E4b, from CropConfig.NextCrows and the server time; "crows come from Renown n" on a young field) and
--     the barn's seed capacity;
--   * Seeds: every seed held (icon, name × count, grow time with the Growth upgrade); nothing → a hint to the plaza's seed stall;
--   * Harvest: every crop held (name × count, record kg) with Feed (a chooser of the pets that can still eat → that pet's page, which
--     feeds crops: PetsGui attribute OpenPet) and Sell (two taps, ConfirmTap; "Sell 2 · 3 787": the count and what the sale pays with the
--     pet bonus, PetClient.State.multiplier, rounded as CoinRewards.Grant rounds);
--   * PanelFocus "Barn": opening it closes the other panels, walking 32 studs away closes it.
-- Display only: Sell names a crop and a count; GardenField checks the count and pays (answer toasted by FieldClient).
-- Hook (ScreenGui BarnGui attribute, cleared after use): Open = true opens the panel. Buttons by path (under PlayerGui.BarnGui):
-- Open (the HUD button), Panel.Content.Crops.<CropId>.Sell / .Feed, Panel.Chooser.List.<uid>; Panel.Close.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local PanelFocus = require(ReplicatedStorage:WaitForChild("PanelFocus"))
local GardenView = require(script.Parent:WaitForChild("GardenView"))
local GardenUi = require(script.Parent:WaitForChild("GardenUi"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))
local Hints = require(script.Parent:WaitForChild("Hints"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("GardenRemotes")
local sellEvent = remotes:WaitForChild("Sell")

local WIDTH = 420
local HEIGHT = 470
local GAP = GardenUi.GAP
local SHOW_DISTANCE = 45 -- studs from the plot centre: the Barn button is visible within this
local SELL_WIDTH = 116
local FEED_WIDTH = 84
local SELL_HINT_LEVEL = 5 -- the sell toast and the pulse are for a young field: up to this Renown level

local COLOR_PANEL = StudStyle.Colors.Wood
local COLOR_ROW = StudStyle.PetRowColor(COLOR_PANEL)

local ui = GardenUi.Panel("BarnGui", COLOR_PANEL, WIDTH, HEIGHT)
local headerSection = GardenUi.Section("Header", 1)
local seedsSection = GardenUi.Section("Seeds", 2)
local cropsSection = GardenUi.Section("Crops", 3)
headerSection.Parent = ui.content
seedsSection.Parent = ui.content
cropsSection.Parent = ui.content

-- the pet chooser for Feed: a page over the panel's content
local chooser = GardenUi.Create("Frame", {
	Name = "Chooser",
	Position = UDim2.new(0, 8, 0, 46),
	Size = UDim2.new(1, -16, 1, -54),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = ui.panel,
})
local chooserTitle = GardenUi.Paragraph("Title", {
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(1, -110, 0, 0),
	Font = StudStyle.Font,
	TextSize = 17,
	TextColor3 = Color3.new(1, 1, 1),
	Parent = chooser,
})
local chooserBack = GardenUi.Button("Back", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, 0),
	Size = UDim2.fromOffset(100, 44),
	BackgroundColor3 = GardenUi.COLOR_LOCKED,
	TextSize = 16,
	Parent = chooser,
}, 2)
local chooserList = GardenUi.Create("ScrollingFrame", {
	Name = "List",
	Position = UDim2.new(0, 0, 0, 54),
	Size = UDim2.new(1, 0, 1, -54),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 5,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Parent = chooser,
}, {
	GardenUi.Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, GAP) }),
	GardenUi.Create("UIPadding", { PaddingRight = UDim.new(0, 6) }),
})

-- HUD button (where the Garden panel's "Field" button was)
local openButton = GardenUi.Button("Open", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -20),
	Size = UDim2.fromOffset(112, 48),
	BackgroundColor3 = COLOR_PANEL,
	TextSize = 18,
	Visible = false,
}, 2)
openButton.Parent = ui.gui

local renderChooser, closePanel -- defined below (rows and the chooser call them)
local isOpen = false
local feeding: string? = nil -- crop id while the chooser is shown
local crowLabel: TextLabel? = nil

-- Rendering ---------------------------------------------------------------------------------------------------------------

local function renderHeader(field)
	GardenUi.Clear(headerSection)
	local text, color = GardenUi.CrowLine(field, workspace:GetServerTimeNow())
	local crows = GardenUi.Paragraph("Crows", { LayoutOrder = 1, Font = StudStyle.Font, TextSize = 16, TextColor3 = color, Text = text })
	crows.Parent = headerSection
	crowLabel = crows
	if type(field.crows) == "table" and field.crows.active then
		GardenUi.Paragraph("CrowsHint", { LayoutOrder = 2, TextSize = 12, TextColor3 = GardenUi.COLOR_DIM, Text = Locale.T("field.crows.hint") }).Parent =
			headerSection
	end
end

local function renderSeeds(field)
	GardenUi.Clear(seedsSection)
	GardenUi.Heading(seedsSection, 1, Locale.T("field.section.seeds"), COLOR_PANEL)
	local any = false
	for index, crop in CropConfig.Crops do
		local stock = field.seeds[crop.id] or 0
		if stock > 0 then
			any = true
			local row = GardenUi.Row(seedsSection, crop.id, index + 1, COLOR_ROW)
			GardenUi.TextColumn(
				row,
				0,
				string.format("%s × %s", GardenUi.CropTitle(crop), Locale.Number(stock)),
				Locale.T("barn.seed.grow", { time = GardenUi.GrowTime(GardenUi.GrowSecondsOn(field, crop)) })
			)
		end
	end
	if not any then
		GardenUi.Paragraph("Empty", { LayoutOrder = 2, Text = Locale.T("barn.seeds.empty") }).Parent = seedsSection
	end
	local total, capacity = CropConfig.SeedTotal(field.seeds), GardenUi.BarnOf(field)
	GardenUi.Paragraph("Capacity", {
		LayoutOrder = #CropConfig.Crops + 2,
		Font = StudStyle.Font,
		TextSize = 15,
		TextColor3 = if total >= capacity then GardenUi.COLOR_ERROR else Color3.new(1, 1, 1),
		Text = Locale.T("field.barn", { total = total, capacity = capacity }),
	}).Parent = seedsSection
end

-- 1 + the equipped pets' bonus (what CoinRewards.Grant multiplies a sale by); 1 before the first pet state.
local function petMultiplier(): number
	local state = PetClient.State
	return type(state) == "table" and tonumber(state.multiplier) or 1
end

local function renderCrops(field, tap: number)
	GardenUi.Clear(cropsSection)
	GardenUi.Heading(cropsSection, 1, Locale.T("field.section.crops"), COLOR_PANEL)
	local any = false
	for index, crop in CropConfig.Crops do
		local owned = field.items[crop.id] or 0
		if owned > 0 then
			any = true
			local row = GardenUi.Row(cropsSection, crop.id, index + 1, COLOR_ROW)
			local best = field.best and field.best[crop.id]
			GardenUi.TextColumn(
				row,
				SELL_WIDTH + FEED_WIDTH + GAP * 2,
				string.format("%s × %s", GardenUi.CropTitle(crop), Locale.Number(owned)),
				if best then Locale.T("field.crop.best", { kg = GardenUi.KgText(crop, best) }) else nil
			)
			local feed = GardenUi.Button("Feed", {
				LayoutOrder = 2,
				Size = UDim2.fromOffset(FEED_WIDTH, tap),
				BackgroundColor3 = GardenUi.COLOR_BUY,
				TextSize = 15,
				TextWrapped = true,
				Text = Locale.T("barn.feed"),
				Parent = row,
			}, 2)
			local cropId = crop.id
			feed.Activated:Connect(function()
				feeding = cropId
				chooser.Visible = true
				ui.content.Visible = false
				renderChooser()
			end)
			GardenUi.SellButton(row, crop, field, PetClient.State, SELL_WIDTH, tap, 3, function(id, count)
				sellEvent:FireServer(id, count)
			end)
		end
	end
	if not any then
		GardenUi.Paragraph("Empty", { LayoutOrder = 2, Text = Locale.T("barn.crops.empty") }).Parent = cropsSection
	end
end

function renderChooser()
	for _, child in chooserList:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local crop = feeding and CropConfig.ById[feeding]
	if not crop then
		return
	end
	chooserTitle.Text = Locale.T("barn.feed.title", { crop = GardenUi.CropTitle(crop) })
	chooserBack.Text = Locale.T("barn.feed.back")
	local tap = ui.TapHeight()
	local pets = {}
	for _, pet in PetClient.Inventory() do
		if pet.care then -- something left to train (P4: PetConfig.CareTarget)
			table.insert(pets, pet)
		end
	end
	table.sort(pets, function(a, b)
		if a.equipped ~= b.equipped then
			return a.equipped
		end
		if a.level ~= b.level then
			return a.level < b.level
		end
		return a.uid < b.uid
	end)
	for index, pet in pets do
		local row = GardenUi.Button(pet.uid, {
			LayoutOrder = index,
			Size = UDim2.new(1, 0, 0, tap),
			BackgroundColor3 = COLOR_ROW,
			TextSize = 17,
			Text = Locale.PetName(pet.kind, pet.level, pet.name),
			Parent = chooserList,
		}, 3)
		local uid = pet.uid
		row.Activated:Connect(function()
			closePanel()
			local petsGui = player.PlayerGui:FindFirstChild("PetsGui")
			if petsGui then
				petsGui:SetAttribute("OpenPet", uid) -- the pet page feeds crops (PetDetail)
			end
		end)
	end
	if #pets == 0 then
		GardenUi.Paragraph("None", { LayoutOrder = 1, Text = Locale.T("barn.feed.none") }).Parent = chooserList
	end
end

local function render()
	ui.title.Text = Locale.T("barn.title")
	openButton.Text = Locale.T("barn.button")
	if not isOpen then
		return
	end
	local field = GardenView.OwnField()
	if not field then
		GardenUi.Clear(headerSection)
		GardenUi.Clear(seedsSection)
		GardenUi.Clear(cropsSection)
		crowLabel = nil
		GardenUi.Paragraph("Loading", { Text = Locale.T("common.loading") }).Parent = headerSection
		return
	end
	renderHeader(field)
	renderSeeds(field)
	renderCrops(field, ui.TapHeight())
	if chooser.Visible then
		renderChooser()
	end
end

local function showContent()
	feeding = nil
	chooser.Visible = false
	ui.content.Visible = true
end

function closePanel()
	PanelFocus.Closed("Barn")
	isOpen = false
	showContent()
	ui.panel.Visible = false
end

local barnOpened = false -- once this session: the Barn button stops pulsing

local function openPanel()
	PanelFocus.Open("Barn", closePanel) -- walking 32 studs away closes it
	isOpen = true
	barnOpened = true
	showContent()
	ui.Fit()
	ui.panel.Visible = true
	render()
end

ui.close.Activated:Connect(closePanel)
chooserBack.Activated:Connect(function()
	showContent()
end)
openButton.Activated:Connect(function()
	if isOpen then
		closePanel()
	else
		openPanel()
	end
end)

-- Events ------------------------------------------------------------------------------------------------------------------

remotes:WaitForChild("State").OnClientEvent:Connect(function()
	task.defer(render) -- after GardenView took the new state
end)
local shownMultiplier = petMultiplier()
PetClient.Changed:Connect(function()
	if isOpen and chooser.Visible then
		renderChooser()
	elseif isOpen and petMultiplier() ~= shownMultiplier then
		render() -- an equipped pet changed: the sale values on the Sell buttons follow
	end
	shownMultiplier = petMultiplier()
end)
Locale.Changed:Connect(render)

-- the barn building's prompt on the own plot (U5a, PlotView)
GardenView.OnBarn(function()
	if not isOpen then
		openPanel()
	end
end)

ui.gui:GetAttributeChangedSignal("Open"):Connect(function()
	if ui.gui:GetAttribute("Open") then
		ui.gui:SetAttribute("Open", nil)
		openPanel()
	end
end)

local function cropsHeld(field): number
	local total = 0
	for _, count in (type(field) == "table" and type(field.items) == "table" and field.items or {}) do
		total += count
	end
	return total
end

local pulseScale = GardenUi.Create("UIScale", { Name = "Pulse", Parent = openButton })
local pulse: Tween? = nil
local function setPulse(on: boolean)
	if on == (pulse ~= nil) then
		return
	end
	if pulse then
		pulse:Cancel()
		pulse = nil
		pulseScale.Scale = 1
		return
	end
	pulse = TweenService:Create(pulseScale, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.12 })
	;(pulse :: Tween):Play()
end

local shownCrops: number? = nil -- crops held at the last check (nil before the first field state)
local sellHintShown = false

-- Every 0.25 s: the button (near the own plot, or crops to sell outside a run), the sell hint, the crow countdown
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.25 then
		return
	end
	elapsed = 0
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local slot = player:GetAttribute(GardenConfig.PlotAttribute)
	local plot = if type(slot) == "number" then GardenConfig.PlotCFrame(slot) else nil
	local near = false
	if root and plot then
		local offset = root.Position - plot.Position
		near = Vector3.new(offset.X, 0, offset.Z).Magnitude <= SHOW_DISTANCE
	end
	local field = GardenView.OwnField()
	local crops = cropsHeld(field)
	openButton.Visible = near or (crops > 0 and not Hints.Running)
	local young = type(field) == "table" and (tonumber(field.level) or math.huge) <= SELL_HINT_LEVEL
	if field then
		if shownCrops and crops > shownCrops and young and not sellHintShown then
			sellHintShown = true
			Hints.Toast(Locale.T("hints.sellCrops"))
		end
		shownCrops = crops
	end
	setPulse(young and crops > 0 and not barnOpened and openButton.Visible)
	if isOpen and crowLabel then
		local text, color = GardenUi.CrowLine(GardenView.OwnField(), workspace:GetServerTimeNow())
		crowLabel.Text = text
		crowLabel.TextColor3 = color
	end
end)

render()
ui.gui.Parent = player:WaitForChild("PlayerGui")
