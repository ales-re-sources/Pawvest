-- GardenUi (U4): what the garden's panels share (Seed stall: SeedStallClient, Barn: BarnClient). Client only.
--   * builders: Create, Label, Button, Paragraph, Section, Clear, Latest, Pulse (re-exported from UiKit), Heading, Row + TextColumn (a text column
--     that wraps, then the buttons), SellButton (a crop row's Sell);
--   * Panel(name, color, width, height): a ScreenGui (Sibling ZIndex, AutoLocalize off) with a centred stud panel (title strip,
--     X button, a scrolling Content list unless opts.content is false) that Fit() scales down to the screen (UIScale, Scale();
--     never below 0.5); TapHeight() = a brick
--     height that stays at least 44 px on screen;
--   * texts: Countdown ("1:00:00"), GrowTime ("3 hours"), CropTitle (icon + name), GrowSecondsOn (with the Growth upgrade),
--     KgText, BarnOf (seeds the barn holds), CrowLine (the crow forecast's text and colour, E4b);
--   * BindStand(gui, standName, open, opts?): a garden stand's prompt and the gui's Open attribute (a test hook) call
--     open(counter part); opts.prompt = { action, object } Locale keys of the prompt, opts.onStand(stand model) once found.
-- Display only: nothing here talks to the server.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local PanelFit = require(ReplicatedStorage:WaitForChild("PanelFit"))
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

-- The Sell brick of a crop row (Barn, the seed stall's Sell tab): sells everything held of `crop` in two taps (ConfirmTap, §10), the text
-- says what the sale pays: SaleValue (sale × summed sizes), then × the pet multiplier (`petState` = PetClient.State), rounded as
-- CoinRewards.Grant does. `fire(cropId, count)` asks the server.
function GardenUi.SellButton(row: Instance, crop, field, petState, width: number, height: number, order: number, fire: (string, number) -> ())
	local owned = field.items[crop.id] or 0
	local base = CropConfig.SaleValue(crop, field.sizes and field.sizes[crop.id] or owned)
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
-- Fit() (scale to the screen; call on open), TapHeight().
-- opts.content = false: no Content list (the caller lays out its own children; FoodShop)
function GardenUi.Panel(name: string, color: Color3, width: number, height: number, opts: { content: boolean? }?)
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
	}, 1)
	local content = if opts and opts.content == false then nil else create("ScrollingFrame", {
		Name = "Content",
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
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 18),
		Size = UDim2.fromOffset(width, height),
		Visible = false,
	}, { fit, title, close, content })
	StudStyle.Panel(panel, color)
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
	function self.Fit()
		local viewport = workspace.CurrentCamera.ViewportSize
		local inset = math.max(GuiService.TopbarInset.Height, 58)
		local scale = math.min(1, (PanelFit.ViewportHeight() - inset - MARGIN) / height, (viewport.X - 2 * MARGIN) / width)
		fit.Scale = math.max(scale, 0.5)
	end
	function self.Scale(): number
		return fit.Scale
	end
	function self.TapHeight(): number
		return math.max(44, math.ceil(44 / fit.Scale))
	end
	return self
end

-- Texts ---------------------------------------------------------------------------------------------------------------------

-- "1:00:00", "42:07", "0:05" / "3 hours", "30 min" (TimeFormat)
GardenUi.Countdown = TimeFormat.Clock
GardenUi.GrowTime = TimeFormat.GrowTime

function GardenUi.CropTitle(crop): string
	return crop.icon .. " " .. Locale.CropName(crop)
end

-- The crop's grow time on `field` (shortened by the Growth upgrade), whole seconds.
function GardenUi.GrowSecondsOn(field, crop): number
	local level = CropConfig.UpgradeLevel(field and field.upgrades, "Growth")
	return math.ceil(crop.growSeconds / CropConfig.GrowthSpeed(level) - 1e-6)
end

-- "7.4" (Czech "7,4"): the weight of a crop of size `factor`, to 0.1 kg (E1c2).
function GardenUi.KgText(crop, factor: number): string
	return Locale.Decimal(string.format("%.1f", crop.kg * factor))
end

-- Seeds the barn of `field` holds (the Barn upgrade).
function GardenUi.BarnOf(field): number
	return CropConfig.BarnFor(CropConfig.UpgradeLevel(field and field.upgrades, "Barn"))
end

-- The crow forecast (E4b) for the server time `now`: text and colour; from the fixed schedule (CropConfig.NextCrows).
-- `field.crows.active` false (a young field) → the "crows come from Renown n" line.
function GardenUi.CrowLine(field, now: number): (string, Color3)
	local crows = field and field.crows
	if type(crows) ~= "table" or not crows.active then
		return Locale.T("field.crows.later", { level = CropConfig.Crows.FromLevel }), GardenUi.COLOR_DIM
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
