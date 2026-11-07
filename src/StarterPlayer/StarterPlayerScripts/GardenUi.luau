-- GardenUi (U4): what the garden's panels share (Seed stall: SeedStallClient, Barn: BarnClient). Client only.
--   * builders: Create, Label, Button (StudStyle brick), Paragraph (wraps and grows), Heading, Row + TextColumn (a text column
--     that wraps, then the buttons), Clear;
--   * Panel(name, color, width, height): a ScreenGui (Sibling ZIndex, AutoLocalize off) with a centred stud panel (title strip,
--     X button, a scrolling Content list) that Fit() scales down to the screen (UIScale; never below 0.5); TapHeight() = a brick
--     height that stays at least 44 px on screen;
--   * texts: Countdown ("1:00:00"), GrowTime ("3 hours"), CropTitle (icon + name), GrowSecondsOn (with the Growth upgrade),
--     KgText, BarnOf (seeds the barn holds), CrowLine (the crow forecast's text and colour, E4b).
-- Display only: nothing here talks to the server.

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local PanelFit = require(ReplicatedStorage:WaitForChild("PanelFit"))

local GardenUi = {}

GardenUi.GAP = 6
GardenUi.COLOR_INFO = Color3.fromRGB(235, 222, 190)
GardenUi.COLOR_DIM = Color3.fromRGB(190, 178, 150)
GardenUi.COLOR_ERROR = Color3.fromRGB(240, 100, 90)
GardenUi.COLOR_OK = Color3.fromRGB(120, 230, 120)
GardenUi.COLOR_RARE = Color3.fromRGB(255, 205, 90)
GardenUi.COLOR_BUY = StudStyle.Colors.Green
GardenUi.COLOR_SELL = StudStyle.Colors.Blue
GardenUi.COLOR_LOCKED = StudStyle.Colors.Grey

local MARGIN = 16

function GardenUi.Create(className: string, props, children)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	return instance
end
local create = GardenUi.Create

function GardenUi.Label(name: string, props)
	props.Name = name
	props.BackgroundTransparency = 1
	props.Font = props.Font or StudStyle.Font
	props.TextColor3 = props.TextColor3 or Color3.new(1, 1, 1)
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	return create("TextLabel", props)
end

-- a brick button (StudStyle.Brick: colour and text keep being set on the button itself)
function GardenUi.Button(name: string, props, studs: number?)
	props.Name = name
	props.TextColor3 = Color3.new(1, 1, 1)
	local instance = create("TextButton", props)
	StudStyle.Brick(instance, { studs = studs })
	return instance
end

-- a text that wraps and grows downwards
function GardenUi.Paragraph(name: string, props)
	props.Size = props.Size or UDim2.new(1, 0, 0, 0)
	props.AutomaticSize = Enum.AutomaticSize.Y
	props.TextWrapped = true
	props.Font = props.Font or Enum.Font.Gotham
	props.TextSize = props.TextSize or 14
	props.TextColor3 = props.TextColor3 or GardenUi.COLOR_INFO
	props.TextYAlignment = Enum.TextYAlignment.Top
	return GardenUi.Label(name, props)
end

function GardenUi.Clear(section: Instance)
	for _, child in section:GetChildren() do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

function GardenUi.Section(name: string, order: number)
	return create("Frame", {
		Name = name,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, {
		create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, GardenUi.GAP) }),
	})
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

-- A centred panel in its own ScreenGui. Returns a table: gui, panel, content (ScrollingFrame with a list), title, close,
-- Fit() (scale to the screen; call on open), TapHeight().
function GardenUi.Panel(name: string, color: Color3, width: number, height: number)
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
	local content = create("ScrollingFrame", {
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
	function self.TapHeight(): number
		return math.max(44, math.ceil(44 / fit.Scale))
	end
	return self
end

-- Texts ---------------------------------------------------------------------------------------------------------------------

-- "1:00:00", "42:07", "0:05"
function GardenUi.Countdown(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	if seconds >= 3600 then
		return string.format("%d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
	end
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

-- "3 hours", "30 min"
function GardenUi.GrowTime(seconds: number): string
	if seconds % 3600 == 0 then
		return Locale.T("common.hours", { count = seconds // 3600 })
	end
	return Locale.Duration(seconds)
end

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

return GardenUi
