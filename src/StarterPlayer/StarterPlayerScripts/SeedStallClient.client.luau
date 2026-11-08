-- Seed stall (U4, docs/UI_GARDEN_PETS.md §6, §9.1): the plaza's seed shop beside the food stand, one shop for everyone.
--   * the prompt on Workspace.Garden.SeedStall's Counter opens the panel (texts set here through Locale);
--   * panel: the market cart's offers on top (E1c4: a row per offer, "New offers in 3:20:00", buys what is left of it), then the
--     seed catalogue (+1 / +10 per unlocked crop, the Renown lock or "from World n" for rare crops: E2a), the barn capacity line;
--     spends over ConfirmTap.THRESHOLD take two taps; walking SeedStallDistance away from the counter closes it (the server checks the
--     same distance), PanelFocus "SeedStall" closes the other panels;
--   * two tabs under the title (playtest 2026-11-08): Buy (the above) and Sell (every harvested crop with the Barn's Sell brick);
--   * board: a SurfaceGui (in PlayerGui, Adornee = the stall's Board, both faces) with the local player's cart offers and the time to
--     the next ones, redrawn on every State and language change.
-- Display only: a tap names a crop and a count (BuySeeds) or an offer (BuyCart); GardenField checks the stall distance, prices, Renown
-- and the barn and answers on GardenRemotes.Result (FieldClient toasts it). The field state comes from GardenRemotes.State
-- (GardenView keeps the last one).
-- Hook (ScreenGui SeedStallGui attribute, cleared after use): Open = true opens the panel (as the prompt does).
-- Buttons by path (under PlayerGui.SeedStallGui.Panel): Tabs.Buy / .Sell, Content.Cart.Offer<slot>.Buy, Content.Seeds.<CropId>.Buy1 / .Buy10,
-- Content.SellCrops.<CropId>.Sell; Close.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local PanelFocus = require(ReplicatedStorage:WaitForChild("PanelFocus"))
local ConfirmTap = require(ReplicatedStorage:WaitForChild("ConfirmTap"))
local GardenView = require(script.Parent:WaitForChild("GardenView"))
local GardenUi = require(script.Parent:WaitForChild("GardenUi"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("GardenRemotes")
local buySeedsEvent = remotes:WaitForChild("BuySeeds")
local buyCartEvent = remotes:WaitForChild("BuyCart")
local sellEvent = remotes:WaitForChild("Sell")
local requestStateEvent = remotes:WaitForChild("RequestState")

local WIDTH = 420
local HEIGHT = 470
local GAP = GardenUi.GAP
local BUY1_WIDTH = 56
local BUY10_WIDTH = 64
local LOCK_WIDTH = 120
local CART_WIDTH = 110
local SELL_WIDTH = 150
local BOARD_PPS = 40 -- board pixels per stud (10 x 3.6 studs → 400 x 144)

local COLOR_PANEL = StudStyle.Colors.Green
local COLOR_ROW = StudStyle.PetRowColor(COLOR_PANEL)

local ui = GardenUi.Panel("SeedStallGui", COLOR_PANEL, WIDTH, HEIGHT)
local cartSection = GardenUi.Section("Cart", 1)
local seedsSection = GardenUi.Section("Seeds", 2)
local sellSection = GardenUi.Section("SellCrops", 3)
cartSection.Parent = ui.content
seedsSection.Parent = ui.content
sellSection.Parent = ui.content

local TABS_TOP = 44 -- under the title strip
local CONTENT_TOP = 46 -- GardenUi.Panel's Content
local CONTENT_BOTTOM = 54
local tabs = GardenUi.Create("Frame", {
	Name = "Tabs",
	Position = UDim2.new(0, 8, 0, TABS_TOP),
	Size = UDim2.new(1, -16, 0, 44),
	BackgroundTransparency = 1,
	Parent = ui.panel,
})
local function tabButton(name: string, x: number)
	return GardenUi.Button(name, {
		Position = UDim2.new(x, if x > 0 then 3 else 0, 0, 0),
		Size = UDim2.new(0.5, -3, 1, 0),
		TextSize = 17,
		BackgroundColor3 = GardenUi.COLOR_LOCKED,
		Parent = tabs,
	}, 2)
end
local buyTab, sellTab = tabButton("Buy", 0), tabButton("Sell", 0.5)
local activeTab = "buy"

local openCounter: BasePart? = nil
local cartTimer = nil -- { label, at }
local askedAt = nil -- the cart's nextAt for which a new State was asked once

local function coinsNow(): number
	return PetClient.Coins or 0
end

local function cropOf(id: string)
	return CropConfig.ById[id]
end

-- Panel -------------------------------------------------------------------------------------------------------------------

local function renderCart(field, tap: number)
	GardenUi.Clear(cartSection)
	cartTimer = nil
	GardenUi.Heading(cartSection, 1, Locale.T("field.section.cart"), COLOR_PANEL)
	local cart = field.cart
	if not cart then
		return
	end
	local nextLine = GardenUi.Paragraph("Next", { LayoutOrder = 2, TextSize = 13, TextColor3 = GardenUi.COLOR_DIM, Text = "" })
	nextLine.Parent = cartSection
	cartTimer = { label = nextLine, at = cart.nextAt }
	nextLine.Text = Locale.T("field.cart.next", { time = GardenUi.Countdown(cart.nextAt - workspace:GetServerTimeNow()) })
	local total, capacity = CropConfig.SeedTotal(field.seeds), GardenUi.BarnOf(field)
	for _, offer in cart.offers do
		local crop = cropOf(offer.crop)
		if crop then
			local row = GardenUi.Row(cartSection, "Offer" .. offer.slot, offer.slot + 2, COLOR_ROW)
			local info = if offer.taste
				then Locale.T("field.cart.taste", { level = crop.renown, price = offer.price })
				else Locale.T("field.cart.bargain", {
					percent = math.floor((offer.discount or 0) * 100 + 0.5),
					price = offer.price,
					base = offer.base,
				})
			GardenUi.TextColumn(row, CART_WIDTH + GAP, Locale.T("field.cart.row", { crop = GardenUi.CropTitle(crop), left = offer.left, count = offer.count }), info)
			local cost = offer.price * offer.left
			local affordable = offer.left > 0 and coinsNow() >= cost and total + offer.left <= capacity
			local buy = GardenUi.Button("Buy", {
				LayoutOrder = 2,
				Size = UDim2.fromOffset(CART_WIDTH, tap),
				BackgroundColor3 = if affordable then GardenUi.COLOR_BUY else GardenUi.COLOR_LOCKED,
				TextSize = 15,
				TextWrapped = true,
				Text = if offer.left > 0 then Locale.T("field.upgrade.price", { count = cost }) else Locale.T("field.cart.soldOut"),
				Parent = row,
			}, 2)
			if offer.left > 0 then
				local slot, cropId, left = offer.slot, offer.crop, offer.left
				ConfirmTap.Wrap(buy, "Cart" .. slot, function()
					return ConfirmTap.Over(cost)
				end, function()
					buyCartEvent:FireServer(slot, cropId, left)
				end)
			end
		end
	end
	GardenUi.Paragraph("Note", { LayoutOrder = 50, TextSize = 12, TextColor3 = GardenUi.COLOR_DIM, Text = Locale.T("field.cart.note") }).Parent =
		cartSection
end

local function renderSeeds(field, tap: number)
	GardenUi.Clear(seedsSection)
	GardenUi.Heading(seedsSection, 1, Locale.T("field.section.seeds"), COLOR_PANEL)
	local total = CropConfig.SeedTotal(field.seeds)
	local capacity = GardenUi.BarnOf(field)
	for index, crop in CropConfig.Crops do
		local locked = field.level < crop.renown
		local stock = field.seeds[crop.id] or 0
		local reserved = if locked or crop.rare then LOCK_WIDTH + GAP else BUY1_WIDTH + BUY10_WIDTH + GAP * 2
		local row = GardenUi.Row(seedsSection, crop.id, index + 1, COLOR_ROW)
		local grow = GardenUi.GrowTime(GardenUi.GrowSecondsOn(field, crop))
		GardenUi.TextColumn(
			row,
			reserved,
			GardenUi.CropTitle(crop),
			if crop.rare
				then Locale.T("field.seed.rareInfo", { time = grow, sale = crop.sale, stock = stock })
				else Locale.T("field.seed.info", { time = grow, sale = crop.sale, seed = crop.seed, stock = stock })
		)
		if locked or crop.rare then -- rare seeds come only from the obby (E2a): the row says from which world
			GardenUi.Paragraph("Locked", {
				LayoutOrder = 2,
				Size = UDim2.new(0, LOCK_WIDTH, 0, 0),
				Font = StudStyle.Font,
				TextSize = 15,
				TextColor3 = if crop.rare then GardenUi.COLOR_RARE else GardenUi.COLOR_DIM,
				TextXAlignment = Enum.TextXAlignment.Center,
				Text = if crop.rare
					then Locale.T("field.seed.fromWorld", { world = Locale.WorldName(StageConfig.Worlds[crop.world]) })
					else Locale.T("field.seed.locked", { level = crop.renown }),
			}).Parent = row
		else
			for slot, option in { { name = "Buy1", amount = 1, width = BUY1_WIDTH }, { name = "Buy10", amount = 10, width = BUY10_WIDTH } } do
				local price = crop.seed * option.amount
				local affordable = coinsNow() >= price and total + option.amount <= capacity
				local buy = GardenUi.Button(option.name, {
					LayoutOrder = slot + 1,
					Size = UDim2.fromOffset(option.width, tap),
					BackgroundColor3 = if affordable then GardenUi.COLOR_BUY else GardenUi.COLOR_LOCKED,
					TextSize = 16,
					Text = "+" .. option.amount,
					Parent = row,
				}, 2)
				ConfirmTap.Wrap(buy, "Seed" .. crop.id .. option.amount, function()
					return ConfirmTap.Over(price)
				end, function()
					buySeedsEvent:FireServer(crop.id, option.amount)
				end)
			end
		end
	end
	GardenUi.Paragraph("Barn", {
		LayoutOrder = #CropConfig.Crops + 2,
		Font = StudStyle.Font,
		TextSize = 15,
		TextColor3 = if total >= capacity then GardenUi.COLOR_ERROR else Color3.new(1, 1, 1),
		Text = Locale.T("field.barn", { total = total, capacity = capacity }),
	}).Parent = seedsSection
	GardenUi.Paragraph("Note", { LayoutOrder = #CropConfig.Crops + 3, TextSize = 12, TextColor3 = GardenUi.COLOR_DIM, Text = Locale.T("field.seed.note") }).Parent =
		seedsSection
end

local function renderSell(field, tap: number)
	GardenUi.Clear(sellSection)
	GardenUi.Heading(sellSection, 1, Locale.T("field.section.crops"), COLOR_PANEL)
	local any = false
	for index, crop in CropConfig.Crops do
		local owned = field.items[crop.id] or 0
		if owned > 0 then
			any = true
			local row = GardenUi.Row(sellSection, crop.id, index + 1, COLOR_ROW)
			local best = field.best and field.best[crop.id]
			GardenUi.TextColumn(
				row,
				SELL_WIDTH + GAP,
				string.format("%s × %s", GardenUi.CropTitle(crop), Locale.Number(owned)),
				if best then Locale.T("field.crop.best", { kg = GardenUi.KgText(crop, best) }) else nil
			)
			GardenUi.SellButton(row, crop, field, PetClient.State, SELL_WIDTH, tap, 2, function(id, count)
				sellEvent:FireServer(id, count)
			end)
		end
	end
	if not any then
		GardenUi.Paragraph("Empty", { LayoutOrder = 2, Text = Locale.T("barn.crops.empty") }).Parent = sellSection
	end
end

local function render()
	ui.title.Text = Locale.T("seedStall.title")
	buyTab.Text = Locale.T("seedStall.tab.buy")
	sellTab.Text = Locale.T("seedStall.tab.sell")
	if not openCounter then
		return
	end
	local tap = ui.TapHeight()
	tabs.Size = UDim2.new(1, -16, 0, tap)
	ui.content.Position = UDim2.new(0, 8, 0, CONTENT_TOP + tap + GAP)
	ui.content.Size = UDim2.new(1, -16, 1, -(CONTENT_BOTTOM + tap + GAP))
	buyTab.BackgroundColor3 = if activeTab == "buy" then GardenUi.COLOR_BUY else GardenUi.COLOR_LOCKED
	sellTab.BackgroundColor3 = if activeTab == "sell" then GardenUi.COLOR_SELL else GardenUi.COLOR_LOCKED
	cartSection.Visible = activeTab == "buy"
	seedsSection.Visible = activeTab == "buy"
	sellSection.Visible = activeTab == "sell"
	local field = GardenView.OwnField()
	if not field then
		GardenUi.Clear(cartSection)
		GardenUi.Clear(seedsSection)
		GardenUi.Clear(sellSection)
		cartTimer = nil
		GardenUi.Paragraph("Loading", { Text = Locale.T("common.loading") }).Parent = if activeTab == "buy" then cartSection else sellSection
		return
	end
	renderCart(field, tap)
	renderSeeds(field, tap)
	renderSell(field, tap)
end

buyTab.Activated:Connect(function()
	activeTab = "buy"
	render()
end)
sellTab.Activated:Connect(function()
	activeTab = "sell"
	render()
end)

local function closePanel()
	PanelFocus.Closed("SeedStall")
	openCounter = nil
	ui.panel.Visible = false
end

local function openPanel(counter: BasePart)
	PanelFocus.Open("SeedStall", closePanel, math.huge) -- the stall distance below closes it
	openCounter = counter
	activeTab = "buy"
	ui.Fit()
	ui.panel.Visible = true
	render()
end

ui.close.Activated:Connect(closePanel)

-- Board -------------------------------------------------------------------------------------------------------------------

local boardGuis = {} -- SurfaceGuis on the Board (Front, Back)
local boardTimers = {} -- labels with the "new offers in" line

local function renderBoard()
	table.clear(boardTimers)
	local field = GardenView.OwnField()
	for _, gui in boardGuis do
		for _, child in gui:GetChildren() do
			child:Destroy()
		end
		local frame = GardenUi.Create("Frame", {
			Name = "Offers",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			GardenUi.Create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			GardenUi.Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
		})
		frame.Parent = gui
		local function line(order: number, text: string, size: number, color: Color3?)
			local l = GardenUi.Label("Line" .. order, {
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, size + 4),
				TextSize = size,
				TextScaled = true, -- a long line (Czech, pseudo) shrinks instead of being cut; never above `size`
				TextXAlignment = Enum.TextXAlignment.Center,
				TextColor3 = color or Color3.fromRGB(255, 240, 210),
				TextStrokeTransparency = 0.5,
				Text = text,
			})
			GardenUi.Create("UITextSizeConstraint", { MaxTextSize = size, MinTextSize = 10, Parent = l })
			l.Parent = frame
			return l
		end
		line(1, Locale.T("field.section.cart"), 24, GardenUi.COLOR_RARE)
		local cart = field and field.cart
		if cart then
			for _, offer in cart.offers do
				local crop = cropOf(offer.crop)
				if crop then
					local text = if offer.left <= 0
						then Locale.T("seedStall.board.soldOut", { crop = GardenUi.CropTitle(crop) })
						elseif offer.taste then Locale.T("seedStall.board.taste", { crop = GardenUi.CropTitle(crop), price = offer.price })
						else Locale.T("seedStall.board.bargain", {
							crop = GardenUi.CropTitle(crop),
							percent = math.floor((offer.discount or 0) * 100 + 0.5),
							price = offer.price,
						})
					line(1 + offer.slot, text, 22, if offer.left <= 0 then GardenUi.COLOR_DIM else nil)
				end
			end
			local timer = line(10, "", 18, GardenUi.COLOR_DIM)
			table.insert(boardTimers, { label = timer, at = cart.nextAt })
		end
	end
end

task.spawn(function()
	local stall = workspace:WaitForChild("Garden"):WaitForChild(GardenConfig.SeedStallName, 60)
	if not (stall and stall:IsA("Model") and stall.PrimaryPart) then
		return
	end
	local counter = stall.PrimaryPart :: BasePart
	local prompt = counter:FindFirstChild("Prompt")
	if prompt and prompt:IsA("ProximityPrompt") then
		local function promptTexts()
			prompt.ActionText = Locale.T("seedStall.prompt.action")
			prompt.ObjectText = Locale.T("seedStall.prompt.object")
		end
		promptTexts()
		Locale.Changed:Connect(promptTexts)
		prompt.Triggered:Connect(function(who)
			if who == player then
				openPanel(counter)
			end
		end)
	end
	local board = stall:FindFirstChild("Board")
	if board and board:IsA("BasePart") then
		for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
			table.insert(boardGuis, GardenUi.Create("SurfaceGui", {
				Name = "SeedBoard" .. face.Name,
				Adornee = board,
				Face = face,
				SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
				PixelsPerStud = BOARD_PPS,
				LightInfluence = 0,
				AutoLocalize = false,
				ResetOnSpawn = false,
				Parent = player:WaitForChild("PlayerGui"),
			}))
		end
		renderBoard()
	end
end)

-- Events ------------------------------------------------------------------------------------------------------------------

remotes:WaitForChild("State").OnClientEvent:Connect(function()
	task.defer(function() -- after GardenView took the new state
		render()
		renderBoard()
	end)
end)
PetClient.Changed:Connect(function()
	if openCounter then
		render() -- the Coins changed: affordability colours
	end
end)
Locale.Changed:Connect(function()
	render()
	renderBoard()
end)

ui.gui:GetAttributeChangedSignal("Open"):Connect(function()
	if ui.gui:GetAttribute("Open") then
		ui.gui:SetAttribute("Open", nil)
		local stall = workspace:FindFirstChild("Garden") and workspace.Garden:FindFirstChild(GardenConfig.SeedStallName)
		if stall and stall:IsA("Model") and stall.PrimaryPart then
			openPanel(stall.PrimaryPart)
		end
	end
end)

-- Every 0.25 s: the stall distance, the cart countdowns (panel and board), a new State once the offers change
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.25 then
		return
	end
	elapsed = 0
	local now = workspace:GetServerTimeNow()
	if openCounter then
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - openCounter.Position).Magnitude > GardenConfig.SeedStallDistance then
			closePanel()
		end
	end
	local nextAt = nil
	if cartTimer then
		cartTimer.label.Text = Locale.T("field.cart.next", { time = GardenUi.Countdown(cartTimer.at - now) })
		nextAt = cartTimer.at
	end
	for _, timer in boardTimers do
		timer.label.Text = Locale.T("field.cart.next", { time = GardenUi.Countdown(timer.at - now) })
		nextAt = timer.at
	end
	if nextAt and now >= nextAt and askedAt ~= nextAt then
		askedAt = nextAt -- the new day's offers come with the next State
		requestStateEvent:FireServer()
	end
end)

render()
ui.gui.Parent = player:WaitForChild("PlayerGui")
