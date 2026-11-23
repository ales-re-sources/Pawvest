-- GardenUi (U4): what the garden's panels share (Seed stall: SeedStallClient, Barn: BarnClient). Client only.
--   * builders: Create, Label, Button, Paragraph, Section, Clear, Latest, Pulse (re-exported from UiKit), Heading, GroupBox (content + legend), Row + TextColumn (a text column
--     that wraps, then the buttons), SellButton (a crop row's Sell);
--   * Panel(name, color, width, height): a ScreenGui (Sibling ZIndex, AutoLocalize off) with a centred stud panel (title strip,
--     X button, a scrolling Content list unless opts.content is false) that Fit() scales down to the screen (UIScale, Scale();
--     never below 0.5); TapHeight() = a brick
--     height that stays at least 44 px on screen;
--   * FarmButton(button, order): center the visible farm HUD buttons together, preserving their ScreenGui parents;
--   * texts: Countdown ("1:00:00"), GrowTime ("3 hours"), CropTitle (icon + name), GrowSecondsOn (with the Growth upgrade),
--     KgText, BarnOf (seeds the barn holds), CrowLine (the crow forecast's text and colour, E4b);
--   * mastery (EV3b): Mastery, PlantsOf, IsUnlocked, Stars, MasteryLine, NextGoal (the tracker line's goal), QuestGot, QuestRows
--     (the quest's pieces with Bring buttons: seed stall and Goals panel);
--   * crop upgrades (EV3c): PointsOf, FreePoints, CropsWithPoints, SalePrice, OpenCropPage (CropPageClient's hook), StarButton (a row's
--     ★ brick that opens the crop page, "★+" while a point is free);
--   * BindStand(gui, standName, open, opts?): a garden stand's prompt and the gui's Open attribute (a test hook) call
--     open(counter part); opts.prompt = { action, object } Locale keys of the prompt, opts.onStand(stand model) once found.
-- Display only: nothing here talks to the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local ConfirmTap = require(ReplicatedStorage:WaitForChild("ConfirmTap"))
local TimeFormat = require(ReplicatedStorage:WaitForChild("TimeFormat"))
local UiKit = require(ReplicatedStorage:WaitForChild("UiKit"))

local GardenUi = {}

GardenUi.GAP = 6
GardenUi.COLOR_INFO = StudStyle.Text.Info
GardenUi.COLOR_DIM = StudStyle.Text.Dim
GardenUi.COLOR_ERROR = StudStyle.Text.Error
GardenUi.COLOR_OK = StudStyle.Text.Ok
GardenUi.COLOR_RARE = StudStyle.Text.Rare
GardenUi.COLOR_BUY = StudStyle.Colors.Green
GardenUi.COLOR_SELL = StudStyle.Colors.Blue
GardenUi.COLOR_LOCKED = StudStyle.Colors.Grey

local MARGIN = 16

GardenUi.Create = UiKit.Create
GardenUi.Label = UiKit.Label
GardenUi.Button = UiKit.Button
GardenUi.Paragraph = UiKit.Paragraph
GardenUi.Clear = UiKit.Clear
GardenUi.Section = UiKit.Section
GardenUi.Latest = UiKit.Latest
GardenUi.Pulse = UiKit.Pulse
local create = UiKit.Create

-- Farm HUD buttons keep their own ScreenGui / Open paths, but share one centered row.
local farmButtons = {} -- [GuiButton] = order
local function layoutFarmButtons()
	local shown, width = {}, 0
	for button, order in farmButtons do
		if button.Parent and button.Visible then
			table.insert(shown, { button = button, order = order })
			width += button.Size.X.Offset
		end
	end
	table.sort(shown, function(a, b) return a.order < b.order end)
	local gap = 12
	width += math.max(0, #shown - 1) * gap
	local x = -width / 2
	for _, entry in shown do
		local button = entry.button
		button.AnchorPoint = Vector2.new(0.5, 1)
		button.Position = UDim2.new(0.5, x + button.Size.X.Offset / 2, 1, -20)
		x += button.Size.X.Offset + gap
	end
end

function GardenUi.FarmButton(button: GuiButton, order: number)
	farmButtons[button] = order
	button:GetPropertyChangedSignal("Visible"):Connect(layoutFarmButtons)
	button:GetPropertyChangedSignal("Size"):Connect(layoutFarmButtons)
	button.Destroying:Connect(function()
		farmButtons[button] = nil
		layoutFarmButtons()
	end)
	layoutFarmButtons()
end

function GardenUi.Heading(parent: Instance, order: number, text: string, color: Color3)
	local title = GardenUi.Label("Heading", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 24),
		TextSize = 19,
		Text = text,
	})
	StudStyle.Title(title, color)
	title.Parent = parent
	return title
end

-- A labelled inset enclosing both information and controls. Clear the returned content; the legend stays outside it.
function GardenUi.GroupBox(parent: Instance, name: string, order: number, color: Color3): (Frame, TextLabel)
	local group = create("Frame", {
		Name = name, LayoutOrder = order, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = parent,
	})
	local content = UiKit.Section("Content", 1, GardenUi.GAP)
	content.Position = UDim2.fromOffset(0, 12)
	content.BackgroundTransparency = 0
	content.BackgroundColor3 = StudStyle.Shade(color, 0.35)
	content.BorderSizePixel = 0
	content.Parent = group
	create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = content })
	create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = StudStyle.Shade(color, 0.8), Thickness = 1, Parent = content })
	create("UIPadding", {
		PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = content,
	})
	local legend = UiKit.Label("Legend", {
		Position = UDim2.fromOffset(12, 0), Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 0, BackgroundColor3 = StudStyle.Shade(color, 0.42), BorderSizePixel = 0,
		TextColor3 = GardenUi.COLOR_INFO, TextSize = 18, Text = "", ZIndex = 2, Parent = group,
	})
	create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = legend })
	return content, legend
end

-- A row: a text column that wraps and grows, then the buttons (TextColumn's `reserved` = their widths plus gaps).
function GardenUi.Row(parent: Instance, name: string, order: number, color: Color3)
	return create("Frame", {
		Name = name,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = color,
		Parent = parent,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 8) }),
		create("UIPadding", {
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 8),
		}),
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, GardenUi.GAP),
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
	})
end

function GardenUi.TextColumn(row: Instance, reserved: number, title: string, info: string?)
	local column = create("Frame", {
		Name = "Text",
		LayoutOrder = 1,
		Size = UDim2.new(1, -reserved, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = row,
	}, {
		create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }),
	})
	GardenUi.Paragraph("Name", { LayoutOrder = 1, Font = StudStyle.Font, TextSize = 17, TextColor3 = Color3.new(1, 1, 1), Text = title }).Parent =
		column
	if info then
		GardenUi.Paragraph("Info", { LayoutOrder = 2, TextSize = 13, Text = info }).Parent = column
	end
	return column
end

-- Field pet slots, the same line in the field's pet picker and the Pets panel: "Field pets", one rounded box with a pip per field
-- pet slot there is (CropConfig.PetSlotPrices) and the next slot's "+1 slot" brick (two taps over ConfirmTap's limit; none at the
-- last slot). A taken pip is the Pets list's "on the field" badge (🌾 on wood), an owned free one its outline, one still to buy
-- faint grey. `field` = GardenRemotes.State.field; `onBuy(slot)` asks the server (it checks the price, answers on Result).
GardenUi.SLOT_PIP = 20
GardenUi.SLOT_BUY_WIDTH = 150
function GardenUi.FieldSlots(field, coins: number, height: number, onBuy: (number) -> ()): Frame
	local used = 0
	for _ in field.pets or {} do
		used += 1
	end
	local slots = field.slots or 1
	local price = field.slotPrice
	local line = create("Frame", { Name = "FieldSlots", Size = UDim2.new(1, 0, 0, height), BackgroundTransparency = 1 })
	local left = create("Frame", {
		Name = "Count", Size = UDim2.new(1, if price then -(GardenUi.SLOT_BUY_WIDTH + GardenUi.GAP) else 0, 1, 0),
		BackgroundTransparency = 1, Parent = line,
	}, { create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, GardenUi.GAP), VerticalAlignment = Enum.VerticalAlignment.Center,
	}) })
	UiKit.Label("Text", {
		LayoutOrder = 1, Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, Font = Enum.Font.Gotham, TextSize = 15,
		TextColor3 = GardenUi.COLOR_INFO, Text = Locale.T("field.petPicker.slots"), Parent = left,
	})
	local box = create("Frame", {
		Name = "Pips", LayoutOrder = 2, AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = StudStyle.Shade(StudStyle.Colors.Wood, 0.2),
		BackgroundTransparency = 0.2, Parent = left,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 6) }),
		create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = StudStyle.Colors.Wood, Thickness = 1 }),
		create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
		create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }), -- strokes draw outside the pips
	})
	for index = 1, #CropConfig.PetSlotPrices do
		local owned = index <= slots
		local taken = index <= used
		local pip = UiKit.Label("Pip" .. index, {
			LayoutOrder = index, Size = UDim2.fromOffset(GardenUi.SLOT_PIP, GardenUi.SLOT_PIP),
			BackgroundColor3 = StudStyle.Colors.Wood, BackgroundTransparency = if taken then 0 else 1,
			TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center, Text = if taken then "🌾" else "", Parent = box,
		})
		create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = pip })
		create("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = if owned then StudStyle.Shade(StudStyle.Colors.Wood, 1.3) else StudStyle.Colors.Grey,
			Transparency = if owned then 0 else 0.45, Thickness = if owned then 2 else 1.5, Parent = pip,
		})
	end
	if price then
		local buy = UiKit.Button("Buy", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(GardenUi.SLOT_BUY_WIDTH, height),
			BackgroundColor3 = if coins >= price then StudStyle.Colors.Yellow else StudStyle.Colors.Grey, TextSize = 15, TextWrapped = true,
			Text = Locale.T("pets.fieldSlot.buy", { count = price }), Parent = line,
		}, { compact = true })
		ConfirmTap.Wrap(buy, "FieldSlot", function()
			return coins >= price and ConfirmTap.Over(price)
		end, function()
			onBuy(slots + 1)
		end)
	end
	return line
end

-- The Sell brick of a crop row (Barn, the seed stall's Sell tab): sells everything held of `crop` in two taps (ConfirmTap, §10), the text
-- says what the sale pays: SaleValue (sale × summed sizes), then × the pet multiplier (`petState` = PetClient.State), rounded as
-- CoinRewards.Grant does. `fire(cropId, count)` asks the server.
function GardenUi.SellButton(row: Instance, crop, field, petState, width: number, height: number, order: number, fire: (string, number) -> ())
	local owned = field.items[crop.id] or 0
	local base = CropConfig.SaleValue(crop, field.sizes and field.sizes[crop.id] or owned, GardenUi.PointsOf(field, crop)) -- EV3c Value
	local multiplier = type(petState) == "table" and tonumber(petState.multiplier) or 1
	local sell = GardenUi.Button("Sell", {
		LayoutOrder = order,
		Size = UDim2.fromOffset(width, height),
		BackgroundColor3 = GardenUi.COLOR_SELL,
		TextSize = 14,
		TextWrapped = true,
		Text = Locale.T("field.crop.sellCount", { count = owned, coins = math.floor(base * multiplier + 0.5 + 1e-9) }),
		Parent = row,
	}, 2)
	local cropId = crop.id
	ConfirmTap.Wrap(sell, "Sell" .. cropId .. owned, function()
		return true -- Sell always takes two taps
	end, function()
		fire(cropId, owned)
	end)
	return sell
end

-- A centred panel in its own ScreenGui. Returns a table: gui, panel, content (ScrollingFrame with a list), title, close,
-- Fit() (live safe area), TapHeight(), HeaderHeight(), TabHeight(), OnResize(callback) (reflow after a safe-area change).
-- opts.content = false: no Content list (the caller lays out its own children; FoodShop)
-- The panel and its Content are passive (not Active, InputSink = All): they sink world input but keep the arrow cursor off the
-- buttons (Active showed the hand over the whole panel). opts.passiveCursor = false: the old Active containers.
function GardenUi.Panel(name: string, color: Color3, width: number, height: number, opts: { content: boolean?, passiveCursor: boolean? }?)
	local passiveCursor = not (opts and opts.passiveCursor == false)
	local title = GardenUi.Label("TitleLabel", {
		Size = UDim2.new(1, 0, 0, 34),
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	local close = GardenUi.Button("Close", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -6, 0, 3),
		Size = UDim2.fromOffset(40, 36),
		ZIndex = 2,
		BackgroundColor3 = StudStyle.Shade(StudStyle.Colors.Red, 0.75),
		TextSize = 18,
		Text = "X",
	}, { compact = true })
	local content = if opts and opts.content == false then nil else create("ScrollingFrame", {
		Name = "Content",
		Active = not passiveCursor,
		InputSink = if passiveCursor then Enum.InputSink.All else Enum.InputSink.None,
		Position = UDim2.new(0, 8, 0, 46),
		Size = UDim2.new(1, -16, 1, -54),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, {
		create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 14) }),
		create("UIPadding", { PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 6) }),
	})
	local fit = create("UIScale", { Scale = 1 })
	local panel = create("Frame", {
		Name = "Panel",
		Active = not passiveCursor,
		InputSink = if passiveCursor then Enum.InputSink.All else Enum.InputSink.None,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, height),
		Visible = false,
	}, { fit, title, close, content })
	StudStyle.Panel(panel, color)
	local titlePadding = create("UIPadding", { Parent = title })
	panel.AutomaticSize = Enum.AutomaticSize.None -- StudStyle.Panel fits a listed panel; this one has a fixed size
	panel.Size = UDim2.fromOffset(width, height)
	local gui = create("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		DisplayOrder = 6,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		AutoLocalize = false, -- translated by Locale (L2)
	}, { panel })
	local self = { gui = gui, panel = panel, content = content, title = title, close = close }
	local resizeCallbacks = {}
	function self.Fit()
		local size = gui.AbsoluteSize
		if size.X <= 100 or size.Y <= 100 then
			return -- wait for the real safe area after parenting / device changes
		end
		local scale = math.min(1, (size.Y - 2 * MARGIN) / height, (size.X - 2 * MARGIN) / width)
		fit.Scale = math.max(scale, 0.5)
		local header = self.HeaderHeight()
		close.Size = UDim2.fromOffset(header, header)
		close.Position = UDim2.new(1, -6, 0, 0)
		if content then
			content.Position = UDim2.fromOffset(8, header + 6)
			content.Size = UDim2.new(1, -16, 1, -(header + 14))
		end
		title.Size = UDim2.new(1, 0, 0, header)
		title.Position = UDim2.fromOffset(0, 0)
		titlePadding.PaddingLeft = UDim.new(0, header + 8)
		titlePadding.PaddingRight = UDim.new(0, header + 8)
	end
	function self.OnResize(callback: () -> ())
		table.insert(resizeCallbacks, callback)
	end
	local resizeQueued = false
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if resizeQueued then return end
		resizeQueued = true
		task.defer(function()
			resizeQueued = false
			self.Fit()
			for _, callback in resizeCallbacks do callback() end
		end)
	end)
	function self.Scale(): number
		return fit.Scale
	end
	function self.TapHeight(): number
		return math.max(44, math.ceil(44 / fit.Scale))
	end
	function self.HeaderHeight(): number
		return math.ceil(StudStyle.Sizes.Header / fit.Scale)
	end
	function self.TabHeight(): number
		return math.ceil(StudStyle.Sizes.Tab / fit.Scale)
	end
	return self
end

-- Texts ---------------------------------------------------------------------------------------------------------------------

-- "1:00:00", "42:07", "0:05" / "3 hours", "30 min" (TimeFormat)
GardenUi.Countdown = TimeFormat.Clock
GardenUi.GrowTime = TimeFormat.GrowTime

-- A solid white trash-can silhouette on a brick's face (independent of emoji / font rendering; follows the brick's moving
-- face): the incubator's egg discard and the square card's dig-up.
function GardenUi.TrashIcon(button: TextButton)
	local icon = GardenUi.Create("Frame", {
		Name = "TrashIcon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.44, 0.54), BackgroundTransparency = 1, ZIndex = 3,
		Parent = (button :: any).Top.Face,
	})
	for _, rect in {
		{ "Body", 0.24, 0.36, 0.52, 0.58 },
		{ "Lid", 0.12, 0.2, 0.76, 0.08 },
		{ "Handle", 0.38, 0.08, 0.24, 0.1 },
	} do
		local part = GardenUi.Create("Frame", {
			Name = rect[1], Position = UDim2.fromScale(rect[2], rect[3]), Size = UDim2.fromScale(rect[4], rect[5]),
			BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0, BorderSizePixel = 0, ZIndex = 3, Parent = icon,
		})
		if rect[1] == "Body" then
			GardenUi.Create("UICorner", { CornerRadius = UDim.new(0.12, 0), Parent = part })
			for _, x in { 0.3, 0.62 } do
				GardenUi.Create("Frame", {
					Name = "Slot", Position = UDim2.fromScale(x, 0.18), Size = UDim2.fromScale(0.08, 0.64),
					BackgroundColor3 = button.BackgroundColor3, BorderSizePixel = 0, ZIndex = 4, Parent = part,
				})
			end
		end
	end
end

function GardenUi.CropTitle(crop): string
	return crop.icon .. " " .. Locale.CropName(crop)
end

-- The crop's away-time duration on `field` (Growth and crop Speed included), whole seconds. `pts` replaces the
-- crop's points (the crop page's preview).
function GardenUi.GrowSecondsOn(field, crop, pts: any?): number
	local speed = CropConfig.GrowthRates(field and field.upgrades, nil, if pts ~= nil then pts else GardenUi.PointsOf(field, crop))
	return math.ceil(crop.growSeconds / speed - 1e-6)
end

function GardenUi.GrowthHint(field): string
	local rate = string.format("%.2f", CropConfig.CountdownRate(field and field.tools)):gsub("0+$", ""):gsub("%.$", "")
	return Locale.T("field.growth.hint", { rate = Locale.Decimal(rate), cap = Locale.Number(CropConfig.OfflineCapSeconds / 3600) })
end

-- "7.4" (Czech "7,4"): the weight of a crop of size `factor`, to 0.1 kg (E1c2).
function GardenUi.KgText(crop, factor: number): string
	return Locale.Decimal(string.format("%.1f", crop.kg * factor))
end

-- Seeds the barn of `field` holds (the Barn upgrade).
function GardenUi.BarnOf(field): number
	return CropConfig.BarnFor(CropConfig.UpgradeLevel(field and field.upgrades, "Barn"))
end

-- EV3b crop mastery from the field state (GardenRemotes.State.field.mastery = { crops = { [id] = plants grown }, unlocked, quest? }).
function GardenUi.Mastery(field)
	local mastery = field and field.mastery
	return if type(mastery) == "table" then mastery else { crops = {}, unlocked = {} }
end

-- Plants of `crop` grown (its mastery count).
function GardenUi.PlantsOf(field, crop): number
	local n = GardenUi.Mastery(field).crops[crop.id]
	return if type(n) == "number" then n else 0
end

-- Whether `crop` is open on `field` (Potato and rare crops always are).
function GardenUi.IsUnlocked(field, crop): boolean
	return CropConfig.IsUnlocked(GardenUi.Mastery(field).unlocked, crop.id)
end

-- " ★2" to put after a common crop's title; empty below level 1 and for rare crops (no words, no Locale key).
function GardenUi.Stars(field, crop): string
	if crop.rare then
		return ""
	end
	local level = CropConfig.MasteryLevel(crop, GardenUi.PlantsOf(field, crop), GardenUi.PointsOf(field, crop))
	return if level > 0 then " ★" .. level else ""
end

-- The crop's mastery line ("Mastery ★1: 32 / 75", "Mastery ★3: complete"), nil for a rare crop.
function GardenUi.MasteryLine(field, crop): string?
	if crop.rare then
		return nil
	end
	local n = GardenUi.PlantsOf(field, crop)
	local level = CropConfig.MasteryLevel(crop, n, GardenUi.PointsOf(field, crop))
	local need = CropConfig.LevelsOf(crop)[level + 1]
	if not need then
		return Locale.T("field.mastery.max", { level = level })
	end
	return Locale.T("field.mastery.line", { level = level, have = n, need = need })
end

-- EV3c: the crop's points from the state ({ Value = 2, … }; nil = none).
function GardenUi.PointsOf(field, crop)
	local points = GardenUi.Mastery(field).points
	local pts = type(points) == "table" and points[crop.id]
	return if type(pts) == "table" then pts else nil
end

-- Points of `crop` still to spend (0 for a rare crop).
function GardenUi.FreePoints(field, crop): number
	return if crop.rare then 0 else CropConfig.FreePoints(crop, GardenUi.PlantsOf(field, crop), GardenUi.PointsOf(field, crop))
end

-- The common crops with a point to spend, in list order.
function GardenUi.CropsWithPoints(field): { any }
	local list = {}
	for _, crop in CropConfig.Ladder do
		if GardenUi.FreePoints(field, crop) > 0 then
			table.insert(list, crop)
		end
	end
	return list
end

-- The sale of one standard-size crop with the crop's points (`pts` replaces them: the crop page's preview).
function GardenUi.SalePrice(field, crop, pts: any?): number
	return CropConfig.SalePrice(crop, if pts ~= nil then pts else GardenUi.PointsOf(field, crop))
end

-- Opens the crop page of `cropId` (CropPageClient, hook CropPageGui attribute Open); its close reopens the ScreenGui named `back`
-- (BarnGui, SeedStallGui, GoalsGui) through that gui's Open attribute.
function GardenUi.OpenCropPage(cropId: string, back: string?)
	local gui = Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("CropPageGui")
	if gui then
		gui:SetAttribute("Back", back)
		gui:SetAttribute("Open", cropId)
	end
end

-- A row's ★ brick (named "Star", LayoutOrder `order`) that opens the crop page of `crop`: "★+" on green while a point is free.
function GardenUi.StarButton(row: Instance, field, crop, width: number, height: number, order: number, back: string)
	local free = GardenUi.FreePoints(field, crop) > 0
	local star = GardenUi.Button("Star", {
		LayoutOrder = order,
		Size = UDim2.fromOffset(width, height),
		BackgroundColor3 = if free then GardenUi.COLOR_BUY else StudStyle.Colors.Wood,
		TextSize = 18,
		Text = if free then "★+" else "★",
		Parent = row,
	}, { compact = true })
	local cropId = crop.id
	star.Activated:Connect(function()
		GardenUi.OpenCropPage(cropId, back)
	end)
	return star
end

-- The next goal of the mastery ladder (EV3b2, the tracker line): nil when every common crop is open, else
-- { crop = the next locked crop, from = the crop being counted, have, need } — for a count unlock the previous crop's plants
-- (have capped at need), for a quest crop its least-done piece (brought / needed; ties: unlock order).
function GardenUi.NextGoal(field)
	local mastery = GardenUi.Mastery(field)
	local target = CropConfig.NextLocked(mastery.unlocked)
	if not target then
		return nil
	end
	if not target.quest then
		local previous, need = CropConfig.UnlockNeed(target)
		if not previous or not need then
			return nil
		end
		return { crop = target, from = previous, have = math.min(GardenUi.PlantsOf(field, previous), need), need = need }
	end
	local got = GardenUi.QuestGot(field, target)
	local best = nil
	for id, need in target.quest do
		local crop = CropConfig.ById[id]
		local have = math.min(got[id] or 0, need)
		local share = have / need
		if crop and have < need and (not best or share < best.share or (share == best.share and crop.order < best.from.order)) then
			best = { crop = target, from = crop, have = have, need = need, share = share }
		end
	end
	return best
end

-- The open quest's handed-in counts toward `target` ({ [cropId] = n }; empty when the quest is another crop's or not open yet).
function GardenUi.QuestGot(field, target): { [string]: number }
	local quest = GardenUi.Mastery(field).quest
	local got = if type(quest) == "table" and quest.crop == target.id and type(quest.got) == "table" then quest.got else {}
	local clean = {}
	for id, n in got do
		if type(n) == "number" then
			clean[id] = n
		end
	end
	return clean
end

-- The quest's pieces as rows under `parent` (EV3b; the seed stall and the Goals panel, EV3b2): each crop with brought / needed /
-- held and a Bring button (named "Bring") that hands in what the barn holds, up to what is still needed, through fire(crop, n).
-- Row names "Quest<CropId>", LayoutOrder order + k. opts: width (the Bring column), tap (its height), color (the rows).
function GardenUi.QuestRows(parent: Instance, target, field, order: number, opts: { width: number, tap: number, color: Color3 }, fire: (string, number) -> ())
	local got = GardenUi.QuestGot(field, target)
	local pieces = {}
	for id, need in target.quest do
		table.insert(pieces, { crop = CropConfig.ById[id], need = need })
	end
	table.sort(pieces, function(x, y)
		return (x.crop.order or 0) < (y.crop.order or 0)
	end)
	for k, piece in pieces do
		local crop = piece.crop
		local brought = math.min(got[crop.id] or 0, piece.need)
		local have = (field and field.items and field.items[crop.id]) or 0
		local missing = piece.need - brought
		local row = GardenUi.Row(parent, "Quest" .. crop.id, order + k, opts.color)
		GardenUi.TextColumn(
			row,
			opts.width + GardenUi.GAP,
			GardenUi.CropTitle(crop),
			Locale.T("field.quest.piece", { got = brought, need = piece.need, have = have })
		)
		if missing <= 0 then
			GardenUi.Paragraph("Done", {
				LayoutOrder = 2,
				Size = UDim2.new(0, opts.width, 0, 0),
				Font = StudStyle.Font,
				TextSize = 15,
				TextColor3 = GardenUi.COLOR_OK,
				TextXAlignment = Enum.TextXAlignment.Center,
				Text = Locale.T("field.quest.done"),
			}).Parent = row
		else
			local bring = GardenUi.Button("Bring", {
				LayoutOrder = 2,
				Size = UDim2.fromOffset(opts.width, opts.tap),
				BackgroundColor3 = if have > 0 then GardenUi.COLOR_BUY else GardenUi.COLOR_LOCKED,
				TextSize = 16,
				Text = Locale.T("field.quest.bring"),
				Parent = row,
			}, 2)
			if have > 0 then
				local id, amount = crop.id, math.min(have, missing)
				bring.Activated:Connect(function()
					fire(id, amount)
				end)
			end
		end
	end
end

-- The crow forecast (E4b) for the server time `now`: text and colour; from the fixed schedule (CropConfig.NextCrows).
-- `field.crows.active` false (a young field) → the "crows come once you grow Garlic" line (EV3b: CropConfig.Crows.FromCrop).
function GardenUi.CrowLine(field, now: number): (string, Color3)
	local crows = field and field.crows
	if type(crows) ~= "table" or not crows.active then
		return Locale.T("field.crows.later", { crop = Locale.CropName(CropConfig.ById[CropConfig.Crows.FromCrop]) }), GardenUi.COLOR_DIM
	end
	local from, to = CropConfig.NextCrows(now, 24 * 3600)
	if not from then
		return Locale.T("field.crows.calm"), GardenUi.COLOR_OK
	elseif from <= now then
		return Locale.T("field.crows.now", { time = GardenUi.Countdown(to - now) }), GardenUi.COLOR_ERROR
	end
	return Locale.T("field.crows.next", { time = GardenUi.Countdown(from - now) }), GardenUi.COLOR_INFO
end

function GardenUi.BindStand(gui: ScreenGui, standName: string, open: (BasePart) -> (), opts: { prompt: { action: string, object: string }?, onStand: ((Model) -> ())? }?)
	local function counter(): BasePart?
		local garden = workspace:FindFirstChild("Garden")
		local stand = garden and garden:FindFirstChild(standName)
		return if stand and stand:IsA("Model") then stand.PrimaryPart else nil
	end
	gui:GetAttributeChangedSignal("Open"):Connect(function()
		if gui:GetAttribute("Open") then
			gui:SetAttribute("Open", nil)
			local part = counter()
			if part then
				open(part)
			end
		end
	end)
	task.spawn(function()
		local stand = workspace:WaitForChild("Garden"):WaitForChild(standName, 60)
		local part = stand and stand:IsA("Model") and stand.PrimaryPart
		if not part then
			return
		end
		local prompt = part:FindFirstChild("Prompt")
		if prompt and prompt:IsA("ProximityPrompt") then
			local keys = opts and opts.prompt
			if keys then
				local function texts()
					prompt.ActionText = Locale.T(keys.action)
					prompt.ObjectText = Locale.T(keys.object)
				end
				texts()
				Locale.Changed:Connect(texts)
			end
			prompt.Triggered:Connect(function(who)
				if who == Players.LocalPlayer then
					open(part)
				end
			end)
		end
		if opts and opts.onStand then
			opts.onStand(stand)
		end
	end)
end

return GardenUi
