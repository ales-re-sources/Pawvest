-- Barn (U4, docs/UI_GARDEN_PETS.md §6): what the player holds from the field. Two entries: the barn building's "Open barn" prompt on
-- the own plot (U5a, PlotView via GardenView.OnBarn) and the bottom-centre HUD button "🧺 Barn" (shown within 45 studs of the own plot
-- and, while the player holds crops, anywhere outside a stage run; a young field gets a toast at the first harvest of the session and
-- the button pulses until the barn was opened: playtest 2026-11-08).
--   * at the top one line of the crow forecast (E4b, GardenUi.CrowLine; "crows come once you grow Garlic" on a young field);
--   * Seeds (legend "Seeds · 12 / 100": held / the barn's capacity, red when full): one line per seed held (icon, name × count,
--     grow time with the Growth upgrade); nothing → a hint to the plaza's seed stall;
--   * Harvest: every crop held (name × count, record kg) with a ★ brick that opens its crop page (EV3c, CropPageClient; "★+" while a
--     point is free; its close comes back here) on a common crop and the sell bricks 1 / 10 / All with "💰 69" under each (what that
--     sale pays: GardenUi.SellBricks, as on the seed stall's Sell tab; two taps over ConfirmTap's limit). Feeding is on the pet's
--     page (2026-11-23: the barn's Feed chooser is gone);
--   * PanelFocus "Barn": opening it closes the other panels, walking 32 studs away closes it.
-- Display only: Sell names a crop and a count; GardenField checks the count and pays (answer toasted by FieldClient).
-- Hook (ScreenGui BarnGui attribute, cleared after use): Open = true opens the panel. Buttons by path (under PlayerGui.BarnGui):
-- Open (the HUD button), Panel.Content.Crops.Content.<CropId>.Sell1 / .Sell10 / .Sell (all) / .Star; Panel.Close.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local PanelFocus = require(ReplicatedStorage:WaitForChild("PanelFocus"))
local GardenView = require(script.Parent:WaitForChild("GardenView"))
local GardenUi = require(script.Parent:WaitForChild("GardenUi"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))
local Hints = require(script.Parent:WaitForChild("Hints"))
local Onboarding = require(script.Parent:WaitForChild("Onboarding"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("GardenRemotes")
local sellEvent = remotes:WaitForChild("Sell")

local WIDTH = 480 -- room for the name next to the ★ and three sell bricks (1 / 10 / All)
local HEIGHT = 470
local GAP = GardenUi.GAP
local SHOW_DISTANCE = 45 -- studs from the plot centre: the Barn button is visible within this
local STAR_WIDTH = 44 -- EV3c: the ★ brick that opens the crop page
local SELL_HINT_UNTIL = "Corn" -- the sell toast and the pulse are for a young field: until this crop is unlocked (EV3b; was Renown 5)

local COLOR_PANEL = StudStyle.Colors.Wood
local COLOR_ROW = StudStyle.PetRowColor(COLOR_PANEL)

local ui = GardenUi.Panel("BarnGui", COLOR_PANEL, WIDTH, HEIGHT)
-- the crow forecast: one line above the groups (no box)
local headerSection = GardenUi.Create("Frame", {
	Name = "Header", LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1, Parent = ui.content,
}, {
	GardenUi.Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
	GardenUi.Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
})
local seedsSection, seedsLegend = GardenUi.GroupBox(ui.content, "Seeds", 2, COLOR_PANEL)
local cropsSection, harvestLegend = GardenUi.GroupBox(ui.content, "Crops", 3, COLOR_PANEL)

-- HUD button (where the Garden panel's "Field" button was)
local openButton = GardenUi.Button("Open", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -20),
	Size = UDim2.fromOffset(112, StudStyle.Sizes.HudButton),
	BackgroundColor3 = COLOR_PANEL,
	TextSize = 18,
	Visible = false,
}, { compact = true })
openButton.Parent = ui.gui
GardenUi.FarmButton(openButton, 1)
-- the crops held, as a badge on the button's corner (like the hatchery's ready eggs): green, red when the barn is full; it pops when
-- the number rises, so a harvest visibly lands in the barn
local cropBadge = GardenUi.Label("CropBadge", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -2, 0, 0), Size = UDim2.fromOffset(22, 22),
	AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 0, BackgroundColor3 = StudStyle.Colors.Green, TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Center, Text = "", Visible = false, ZIndex = 5, Parent = openButton,
})
GardenUi.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = cropBadge })
GardenUi.Create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = cropBadge })
local cropBadgeScale = GardenUi.Create("UIScale", { Parent = cropBadge })

local closePanel -- defined below
local isOpen = false
local crowLabel: TextLabel? = nil

-- Rendering ---------------------------------------------------------------------------------------------------------------

local function renderHeader(field)
	GardenUi.Clear(headerSection)
	local text, color = GardenUi.CrowLine(field, workspace:GetServerTimeNow())
	local crows = GardenUi.Paragraph("Crows", { LayoutOrder = 1, Font = StudStyle.Font, TextSize = 16, TextColor3 = color, Text = text })
	crows.Parent = headerSection
	crowLabel = crows
end

local function renderSeeds(field)
	GardenUi.Clear(seedsSection)
	local any = false
	for index, crop in CropConfig.Crops do
		local stock = field.seeds[crop.id] or 0
		if stock > 0 then
			any = true
			local row = GardenUi.Row(seedsSection, crop.id, index + 1, COLOR_ROW)
			GardenUi.TextColumn(row, 0, string.format("%s × %s · %s", GardenUi.CropTitle(crop), Locale.Number(stock),
				GardenUi.GrowTime(GardenUi.GrowSecondsOn(field, crop))))
		end
	end
	if not any then
		GardenUi.Paragraph("Empty", { LayoutOrder = 2, Text = Locale.T("barn.seeds.empty") }).Parent = seedsSection
	end
	-- the barn's capacity sits in the legend: "Seeds · 12 / 100", red when full
	local total, capacity = CropConfig.SeedTotal(field.seeds), GardenUi.BarnOf(field)
	seedsLegend.Text = Locale.T("barn.seeds.legend", { total = total, capacity = capacity })
	seedsLegend.TextColor3 = if total >= capacity then GardenUi.COLOR_ERROR else GardenUi.COLOR_INFO
end

-- 1 + the equipped pets' bonus (what CoinRewards.Grant multiplies a sale by); 1 before the first pet state.
local function petMultiplier(): number
	local state = PetClient.State
	return type(state) == "table" and tonumber(state.multiplier) or 1
end

local function renderCrops(field, tap: number)
	GardenUi.Clear(cropsSection)
	local any = false
	for index, crop in CropConfig.Crops do
		local owned = field.items[crop.id] or 0
		if owned > 0 then
			any = true
			local row = GardenUi.Row(cropsSection, crop.id, index + 1, COLOR_ROW)
			local best = field.best and field.best[crop.id]
			if not crop.rare then
				GardenUi.StarButton(row, field, crop, STAR_WIDTH, tap, 0, "BarnGui")
			end
			GardenUi.TextColumn(
				row,
				#GardenUi.SellAmounts(owned) * (GardenUi.SELL_BRICK_WIDTH + GAP) + (if crop.rare then 0 else STAR_WIDTH + GAP),
				string.format("%s%s × %s", GardenUi.CropTitle(crop), GardenUi.Stars(field, crop), Locale.Number(owned)),
				if best then Locale.T("field.crop.best", { kg = GardenUi.KgText(crop, best) }) else nil
			)
			GardenUi.SellBricks(row, crop, field, PetClient.State, tap, 3, function(id, count)
				sellEvent:FireServer(id, count)
			end)
		end
	end
	if not any then
		GardenUi.Paragraph("Empty", { LayoutOrder = 2, Text = Locale.T("barn.crops.empty") }).Parent = cropsSection
	end
end

local function render()
	ui.title.Text = Locale.T("barn.title")
	seedsLegend.Text = Locale.T("field.section.seeds")
	harvestLegend.Text = Locale.T("field.section.crops")
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
end

function closePanel()
	PanelFocus.Closed("Barn")
	isOpen = false
	ui.panel.Visible = false
end

local barnOpened = false -- once this session: the Barn button stops pulsing

local function openPanel()
	PanelFocus.Open("Barn", closePanel) -- walking 32 studs away closes it
	isOpen = true
	barnOpened = true
	ui.Fit()
	ui.panel.Visible = true
	render()
end

ui.close.Activated:Connect(closePanel)
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
	if isOpen and petMultiplier() ~= shownMultiplier then
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

local setPulse = GardenUi.Pulse(openButton)

local shownCrops: number? = nil -- crops held at the last check (nil before the first field state)
local sellHintShown = false
local badgeShown: number? = nil -- crops shown on the button's badge (nil before the first check)

-- Every 0.25 s: the button (near the own plot, or crops to sell outside a run), the sell hint, the crow countdown
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.25 then
		return
	end
	elapsed = 0
	local distance = GardenView.FlatDistanceToPlot()
	local near = distance ~= nil and distance <= SHOW_DISTANCE
	local field = GardenView.OwnField()
	local crops = cropsHeld(field)
	local focus = PanelFocus.Current()
	openButton.Visible = not isOpen and (focus == nil or focus == "Barn") and (near or (crops > 0 and not Hints.Running))
	if field and crops ~= badgeShown then -- no field state yet: no badge, no pop for the crops already held at the join
		cropBadge.Visible = crops > 0
		cropBadge.Text = Locale.Number(crops)
		cropBadge.BackgroundColor3 = if crops >= GardenUi.BarnOf(field) then StudStyle.Colors.Red else StudStyle.Colors.Green
		if badgeShown and crops > badgeShown then
			cropBadgeScale.Scale = 1.6
			TweenService:Create(cropBadgeScale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		end
		badgeShown = crops
	end
	local young = type(field) == "table" and not GardenUi.IsUnlocked(field, CropConfig.ById[SELL_HINT_UNTIL])
	if field then
		if shownCrops and crops > shownCrops and young and not sellHintShown then
			sellHintShown = true
			Hints.Toast(Locale.T("hints.sellCrops"))
		end
		shownCrops = crops
	end
	setPulse(openButton.Visible and ((young and crops > 0 and not barnOpened) or (Onboarding.Is("sell") and crops > 0))) -- E5c step 4
	if isOpen and crowLabel then
		local text, color = GardenUi.CrowLine(GardenView.OwnField(), workspace:GetServerTimeNow())
		crowLabel.Text = text
		crowLabel.TextColor3 = color
	end
end)

ui.OnResize(render)
render()
ui.gui.Parent = player:WaitForChild("PlayerGui")
