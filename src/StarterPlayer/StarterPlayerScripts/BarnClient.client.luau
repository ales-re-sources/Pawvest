-- Barn (U4, docs/UI_GARDEN_PETS.md §6): what the player holds from the field. Until U5 builds the barn on the plot, the entry is the
-- bottom-centre HUD button "🧺 Barn" (shown within 45 studs of the own plot, where the Garden panel's "Field" button was).
--   * header: the crow forecast (E4b, from CropConfig.NextCrows and the server time; "crows come from Renown n" on a young field) and
--     the barn's seed capacity;
--   * Seeds: every seed held (icon, name × count, grow time with the Growth upgrade); nothing → a hint to the plaza's seed stall;
--   * Harvest: every crop held (name × count, record kg) with Feed (a chooser of the pets that can still eat → that pet's page, which
--     feeds crops: PetsGui attribute OpenPet) and Sell all (two taps, ConfirmTap; the value before the pet bonus);
--   * PanelFocus "Barn": opening it closes the other panels, walking 32 studs away closes it (Sell needs the own plot on the server).
-- Display only: Sell names a crop and a count; GardenField checks the plot, the count and pays (answer toasted by FieldClient).
-- Hook (ScreenGui BarnGui attribute, cleared after use): Open = true opens the panel. Buttons by path (under PlayerGui.BarnGui):
-- Open (the HUD button), Panel.Content.Crops.<CropId>.Sell / .Feed, Panel.Chooser.List.<uid>; Panel.Close.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local PanelFocus = require(ReplicatedStorage:WaitForChild("PanelFocus"))
local ConfirmTap = require(ReplicatedStorage:WaitForChild("ConfirmTap"))
local GardenView = require(script.Parent:WaitForChild("GardenView"))
local GardenUi = require(script.Parent:WaitForChild("GardenUi"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("GardenRemotes")
local sellEvent = remotes:WaitForChild("Sell")

local WIDTH = 420
local HEIGHT = 470
local GAP = GardenUi.GAP
local SHOW_DISTANCE = 45 -- studs from the plot centre: the Barn button is visible within this
local SELL_WIDTH = 116
local FEED_WIDTH = 84

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
			local value = CropConfig.SaleValue(crop, field.sizes and field.sizes[crop.id] or owned)
			local sell = GardenUi.Button("Sell", {
				LayoutOrder = 3,
				Size = UDim2.fromOffset(SELL_WIDTH, tap),
				BackgroundColor3 = GardenUi.COLOR_SELL,
				TextSize = 14,
				TextWrapped = true,
				Text = Locale.T("field.crop.sell", { coins = value }),
				Parent = row,
			}, 2)
			ConfirmTap.Wrap(sell, "Sell" .. cropId .. owned, function()
				return true -- Sell always takes two taps (§10)
			end, function()
				sellEvent:FireServer(cropId, owned)
			end)
		end
	end
	if any then
		GardenUi.Paragraph("Note", { LayoutOrder = #CropConfig.Crops + 2, TextSize = 12, TextColor3 = GardenUi.COLOR_DIM, Text = Locale.T("field.crops.note") }).Parent =
			cropsSection
	else
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

local function openPanel()
	PanelFocus.Open("Barn", closePanel) -- walking 32 studs away closes it
	isOpen = true
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
PetClient.Changed:Connect(function()
	if isOpen and chooser.Visible then
		renderChooser()
	end
end)
Locale.Changed:Connect(render)

ui.gui:GetAttributeChangedSignal("Open"):Connect(function()
	if ui.gui:GetAttribute("Open") then
		ui.gui:SetAttribute("Open", nil)
		openPanel()
	end
end)

-- Every 0.25 s: the button near the own plot, the crow countdown
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
	openButton.Visible = near
	if isOpen and crowLabel then
		local text, color = GardenUi.CrowLine(GardenView.OwnField(), workspace:GetServerTimeNow())
		crowLabel.Text = text
		crowLabel.TextColor3 = color
	end
end)

render()
ui.gui.Parent = player:WaitForChild("PlayerGui")
