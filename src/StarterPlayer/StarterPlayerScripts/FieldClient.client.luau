-- Field client (E1a2, docs/ROADMAP.md -> E1a2): the crop field's HUD button, the Garden panel and the seed picker.
--   * "Field" button (own ScreenGui FieldGui): visible only while the character is near the own plot; opens / closes the panel;
--   * Garden panel: Renown level, one row per owned square (crop and time left or "Ripe!"), the seed catalogue (buy 1 / 10, Renown
--     locks, barn), harvested crops (Sell all), the next square (price + Renown) -- closes when the player walks away;
--   * seed picker: GardenView.OnSquare(square, "plant") lists the crops in stock; "harvest" fires Harvest straight away;
--   * pet picker (E1b): GardenView.OnSquare(square, "pet") lists the pets with Tending or Pest control (E4b; place / move here,
--     lift the one on the square; hovering a pet tints the squares it would work); the panel's Pets section lists the field pets
--     (square, Tending and Pest-control levels, reach, XP), lifts them and buys the next field pet slot;
--   * crow forecast (E4b): a line under the Renown level, "Crows in 3:20:00" / "Crows now, 1:05:00 left", computed on the client
--     from CropConfig.NextCrows and the server time (the schedule is fixed); State.field.crows.active says whether crows come yet;
--   * toasts for the answers of the field actions on GardenRemotes.Result (pens and eggs share that remote: ignored here), and
--     once per session the notices of State.field.notice (the pens' conversion, what the pets harvested while away, what the
--     crows ate and which guards chased them off).
-- Only for a player with GardenConfig.HasFieldAccess (admins and Studio test users until E1 ships): anyone else gets no GUI.
-- Display only: a click just names a square, a crop or a count; GardenField validates access, place, prices, times and Renown.
-- The countdowns use workspace:GetServerTimeNow() against `readyAt` ("ripe at, if you stay online"), never the device clock.
-- The GUI is built here (no Studio GUI), stud-brick wood look like the pen panel (StudStyle).
-- Test hooks (ScreenGui FieldGui attributes, cleared after use): OpenField = true opens the panel, OpenPicker = square opens the picker,
-- OpenPetPicker = square opens the pet picker.
-- Buttons by path (all under PlayerGui.FieldGui): Panel.Content.Seeds.<CropId>.Buy1 / .Buy10, Panel.Content.Crops.<CropId>.Sell,
-- Panel.Content.Expand.Buy, Panel.Content.Upgrades.<UpgradeId>.Buy, Panel.Content.Pets.Pet<square>.Lift, Panel.Content.Pets.Slot.BuySlot, Picker.<CropId>,
-- Picker.Pet_<uid> / Picker.Lift (pet picker), Open (the HUD button).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local player = Players.LocalPlayer
if not GardenConfig.HasFieldAccess(player.UserId) then
	return
end

local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))
local GardenView = require(script.Parent:WaitForChild("GardenView"))

local remotes = ReplicatedStorage:WaitForChild("GardenRemotes")
local plantEvent = remotes:WaitForChild("Plant")
local harvestEvent = remotes:WaitForChild("Harvest")
local buySeedsEvent = remotes:WaitForChild("BuySeeds")
local sellEvent = remotes:WaitForChild("Sell")
local buySquareEvent = remotes:WaitForChild("BuySquare")
local placePetEvent = remotes:WaitForChild("PlacePet")
local liftPetEvent = remotes:WaitForChild("LiftPet")
local buyPetSlotEvent = remotes:WaitForChild("BuyPetSlot")
local buyUpgradeEvent = remotes:WaitForChild("BuyUpgrade")
local buyToolEvent = remotes:WaitForChild("BuyTool")
local buyCartEvent = remotes:WaitForChild("BuyCart")
local requestStateEvent = remotes:WaitForChild("RequestState")

local SHOW_DISTANCE = 45 -- studs from the plot centre: the Field button is visible within this
local CLOSE_DISTANCE = 32 -- studs from where a panel was opened; walking further away closes it
local TICK_SECONDS = 0.25
local GAP = 6 -- between the items of a row
local SQUARE_ROW = 30
local PICKER_ROW = 54
local BUY1_WIDTH = 50
local BUY10_WIDTH = 56
local SELL_WIDTH = 116
local LOCK_WIDTH = 112
local LIFT_WIDTH = 76
local SLOT_WIDTH = 96
local UPGRADE_WIDTH = 104
local REACH_SECONDS = 3 -- the reach of a pet just placed stays tinted this long
local NOTICE_SECONDS = 8

local COLOR_PANEL = StudStyle.PanelColors.GardenPen
local COLOR_ROW = StudStyle.PetRowColor(COLOR_PANEL)
local COLOR_BUY = StudStyle.Colors.Green
local COLOR_SELL = StudStyle.Colors.Blue
local COLOR_LOCKED = StudStyle.Colors.Grey
local COLOR_CLOSE = StudStyle.Colors.Red
local COLOR_INFO = Color3.fromRGB(235, 222, 190)
local COLOR_DIM = Color3.fromRGB(190, 178, 150)
local COLOR_ERROR = Color3.fromRGB(240, 100, 90)
local COLOR_OK = Color3.fromRGB(120, 230, 120)
local COLOR_RARE = Color3.fromRGB(255, 205, 90) -- rare crops' "from World n" (E2a)

-- the reasons GardenField answers with (texts: field.reason.<reason>)
local REJECT_KEYS = {
	obby = "field.reason.obby",
	locked = "field.reason.locked",
	far = "field.reason.far",
	loading = "field.reason.loading",
	noplot = "field.reason.noplot",
	square = "field.reason.square",
	occupied = "field.reason.occupied",
	renown = "field.reason.renown",
	seeds = "field.reason.seeds",
	empty = "field.reason.empty",
	notripe = "field.reason.notripe",
	barn = "field.reason.barn",
	coins = "field.reason.coins",
	items = "field.reason.items",
	maxed = "field.reason.maxed",
	stale = "field.reason.stale",
	open = "field.reason.open",
	soldout = "field.reason.soldOut",
}
-- the field pet actions' own texts for some reasons (E1b)
local PET_REJECT_KEYS = {
	occupied = "field.reason.petOccupied",
	equipped = "field.reason.equipped",
	penned = "field.reason.penned",
	aptitude = "field.reason.aptitude",
	slots = "field.reason.slots",
	maxed = "field.reason.slotsMaxed",
}
local PET_ACTIONS = { PlacePet = true, LiftPet = true, BuyPetSlot = true }
-- the field upgrades' texts (E1c1): name, effect now → next level, effect at the top level
local UPGRADE_KEYS = {
	Growth = { name = "field.upgrade.growth", effect = "field.upgrade.growth.effect", max = "field.upgrade.growth.max" },
	Barn = { name = "field.upgrade.barn", effect = "field.upgrade.barn.effect", max = "field.upgrade.barn.max" },
}
-- the garden tools' texts (E1c3), the same shape; every effect is shown in %
local TOOL_KEYS = {
	Sorter = { name = "field.tool.sorter", effect = "field.tool.sorter.effect", max = "field.tool.sorter.max" },
	Cloches = { name = "field.tool.cloches", effect = "field.tool.cloches.effect", max = "field.tool.cloches.max" },
	Shears = { name = "field.tool.shears", effect = "field.tool.shears.effect", max = "field.tool.shears.max" },
}

local function create(className: string, props, children)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	return instance
end

local function label(name: string, props)
	props.Name = name
	props.BackgroundTransparency = 1
	props.Font = props.Font or StudStyle.Font
	props.TextColor3 = props.TextColor3 or Color3.new(1, 1, 1)
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	return create("TextLabel", props)
end

-- a brick button (StudStyle.Brick: colour and text keep being set on the button itself)
local function button(name: string, props, studs: number?)
	props.Name = name
	props.TextColor3 = Color3.new(1, 1, 1)
	local instance = create("TextButton", props)
	StudStyle.Brick(instance, { studs = studs })
	return instance
end

-- a text that wraps and grows downwards
local function paragraph(name: string, props)
	props.Size = props.Size or UDim2.new(1, 0, 0, 0)
	props.AutomaticSize = Enum.AutomaticSize.Y
	props.TextWrapped = true
	props.Font = props.Font or Enum.Font.Gotham
	props.TextSize = props.TextSize or 14
	props.TextColor3 = props.TextColor3 or COLOR_INFO
	props.TextYAlignment = Enum.TextYAlignment.Top
	return label(name, props)
end

local function cropOf(id: string)
	return CropConfig.ById[id]
end

-- "1:00:00", "42:07", "0:05"
local function countdown(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	if seconds >= 3600 then
		return string.format("%d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
	end
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

-- "3 hours", "30 min"
local function growTime(seconds: number): string
	if seconds % 3600 == 0 then
		return Locale.T("common.hours", { count = seconds // 3600 })
	end
	return Locale.Duration(seconds)
end

local function cropTitle(crop): string
	return crop.icon .. " " .. Locale.CropName(crop)
end

-- The crop's grow time on `field` (shortened by the Growth upgrade), whole seconds.
local function growSecondsOn(field, crop): number
	local level = CropConfig.UpgradeLevel(field and field.upgrades, "Growth")
	return math.ceil(crop.growSeconds / CropConfig.GrowthSpeed(level) - 1e-6)
end

-- "7.4" (Czech "7,4"): the weight of a crop of size `factor`, to 0.1 kg (E1c2).
local function kgText(crop, factor: number): string
	return Locale.Decimal(string.format("%.1f", crop.kg * factor))
end

-- Seeds the barn of `field` holds (the Barn upgrade).
local function barnOf(field): number
	return CropConfig.BarnFor(CropConfig.UpgradeLevel(field and field.upgrades, "Barn"))
end

-- State -------------------------------------------------------------------------------------------------------------------

local fieldState = nil -- GardenRemotes.State.field: { open (sorted square numbers), squares, seeds, items, sizes, best, renown, level, pets, slots, slotPrice, upgrades, barn, notice }
local panelPoint: Vector3? = nil -- where the Garden panel was opened (nil = closed)
local pickerPoint: Vector3? = nil
local pickerSquare: number? = nil
local pickerMode = "seed" -- "seed" (plant) or "pet" (place / move a field pet)
local reachToken = 0
local noticesShown = {} -- [kind] = true once this session's notice was shown
local timers = {} -- ticking square rows: { label, readyAt, ripe }
local cartTimer = nil -- the market cart's "new offers in" line: { label, at, asked }
local crowLabel = nil -- the crow forecast line (E4b), re-texted every frame while the panel is open
local toastToken = 0

local function rootPosition(): Vector3?
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

-- Garden panel ------------------------------------------------------------------------------------------------------------

local titleLabel = label("TitleLabel", {
	Size = UDim2.new(1, 0, 0, 34),
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Center,
})
local closeButton = button("Close", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -6, 0, 4),
	Size = UDim2.fromOffset(30, 28),
	ZIndex = 2,
	BackgroundColor3 = COLOR_CLOSE,
	TextSize = 16,
	Text = "X",
}, 1)

local function newSection(name: string, order: number)
	return create("Frame", {
		Name = name,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, {
		create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, GAP) }),
	})
end

local headerSection = newSection("Header", 1)
local squaresSection = newSection("Field", 2)
local petsSection = newSection("Pets", 3)
local seedsSection = newSection("Seeds", 4)
local cartSection = newSection("Cart", 5)
local cropsSection = newSection("Crops", 6)
local expandSection = newSection("Expand", 7)
local upgradesSection = newSection("Upgrades", 8)
local toolsSection = newSection("Tools", 9)

local content = create("ScrollingFrame", {
	Name = "Content",
	Position = UDim2.new(0, 8, 0, 44),
	Size = UDim2.new(1, -16, 1, -52),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 5,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, {
	create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 14) }),
	create("UIPadding", { PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 6) }),
	headerSection,
	squaresSection,
	petsSection,
	seedsSection,
	cartSection,
	cropsSection,
	expandSection,
	upgradesSection,
	toolsSection,
})

local panel = create("Frame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(1, -16, 0.85, 0),
	Visible = false,
}, {
	create("UISizeConstraint", { MinSize = Vector2.new(200, 180), MaxSize = Vector2.new(400, 560) }),
	titleLabel,
	closeButton,
	content,
})
StudStyle.Panel(panel, COLOR_PANEL)

-- Seed picker -------------------------------------------------------------------------------------------------------------

local pickerTitle = label("TitleLabel", {
	Size = UDim2.new(1, 0, 0, 34),
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Center,
})
local pickerClose = button("Close", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -6, 0, 4),
	Size = UDim2.fromOffset(30, 28),
	ZIndex = 2,
	BackgroundColor3 = COLOR_CLOSE,
	TextSize = 16,
	Text = "X",
}, 1)
local picker = create("Frame", {
	Name = "Picker",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(1, -16, 0, 160),
	Visible = false,
}, {
	create("UISizeConstraint", { MaxSize = Vector2.new(340, 600) }),
	pickerTitle,
	pickerClose,
})
StudStyle.Panel(picker, COLOR_PANEL)

-- HUD button and toast
local openButton = button("Open", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -20),
	Size = UDim2.fromOffset(112, 48),
	BackgroundColor3 = COLOR_BUY,
	TextSize = 18,
	Visible = false,
}, 2)

local toast = label("Toast", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 108),
	Size = UDim2.new(1, -16, 0, 34),
	AutomaticSize = Enum.AutomaticSize.Y,
	TextSize = 18,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Center,
	Visible = false,
})
create("UISizeConstraint", { MaxSize = Vector2.new(360, 200), Parent = toast })
StudStyle.Plate(toast, COLOR_PANEL, 4)
StudStyle.Title(toast, COLOR_PANEL)

local screenGui = create("ScreenGui", {
	Name = "FieldGui",
	ResetOnSpawn = false,
	DisplayOrder = 6,
	-- Sibling: the picker (a later sibling) draws above the whole panel. Global let the panel's stud-button glyphs (ZIndex 2) show through
	-- the picker's rows when both were open (found in E1c4)
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	AutoLocalize = false, -- translated by Locale (L2)
}, { openButton, panel, picker, toast })

-- Rows --------------------------------------------------------------------------------------------------------------------

local function clearSection(section: Instance)
	for _, child in section:GetChildren() do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

local function heading(parent: Instance, order: number, text: string)
	local title = label("Heading", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 24),
		TextSize = 19,
		Text = text,
	})
	StudStyle.Title(title, COLOR_PANEL)
	title.Parent = parent
end

-- A row: a text column that wraps and grows, then the buttons (`reserved` = their widths plus gaps).
local function newRow(parent: Instance, name: string, order: number)
	return create("Frame", {
		Name = name,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = COLOR_ROW,
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
			Padding = UDim.new(0, GAP),
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
	})
end

local function textColumn(row: Instance, reserved: number, title: string, info: string?)
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
	paragraph("Name", { LayoutOrder = 1, Font = StudStyle.Font, TextSize = 17, TextColor3 = Color3.new(1, 1, 1), Text = title }).Parent = column
	if info then
		paragraph("Info", { LayoutOrder = 2, TextSize = 13, Text = info }).Parent = column
	end
	return column
end

-- { [square] = true } of the open squares of `field` (State.field.open), for CropConfig.Reach.
local function openSet(field): { [number]: boolean }
	local set = {}
	for _, n in field.open or {} do
		set[n] = true
	end
	return set
end

local function coinsNow(): number
	return PetClient.Coins
end

-- Sections ----------------------------------------------------------------------------------------------------------------

-- The crow forecast line's text and colour for the server time now (E4b).
local function crowForecast()
	local label = crowLabel
	if not label then
		return
	end
	local now = workspace:GetServerTimeNow()
	local from, to = CropConfig.NextCrows(now, 24 * 3600)
	if not from then
		label.Text = Locale.T("field.crows.calm")
		label.TextColor3 = COLOR_OK
	elseif from <= now then
		label.Text = Locale.T("field.crows.now", { time = countdown(to - now) })
		label.TextColor3 = COLOR_ERROR
	else
		label.Text = Locale.T("field.crows.next", { time = countdown(from - now) })
		label.TextColor3 = COLOR_INFO
	end
end

local function renderHeader(field)
	clearSection(headerSection)
	paragraph("Level", {
		LayoutOrder = 1,
		Font = StudStyle.Font,
		TextSize = 24,
		TextColor3 = COLOR_OK,
		Text = Locale.T("field.renown.level", { level = field.level }),
	}).Parent = headerSection
	paragraph("Next", {
		LayoutOrder = 2,
		TextSize = 15,
		Text = Locale.T("field.renown.next", { count = math.max(0, CropConfig.PointsFor(field.level + 1) - field.renown), level = field.level + 1 }),
	}).Parent = headerSection
	paragraph("Hint", { LayoutOrder = 3, TextSize = 13, TextColor3 = COLOR_DIM, Text = Locale.T("field.renown.hint") }).Parent = headerSection
	-- E4b crow forecast: from the fixed schedule (CropConfig.NextCrows) and the server time
	crowLabel = nil
	local crows = field.crows
	if type(crows) == "table" then
		if crows.active then
			crowLabel = paragraph("Crows", { LayoutOrder = 4, Font = StudStyle.Font, TextSize = 16, Text = "" })
			crowLabel.Parent = headerSection
			crowForecast()
			paragraph("CrowsHint", { LayoutOrder = 5, TextSize = 12, TextColor3 = COLOR_DIM, Text = Locale.T("field.crows.hint") }).Parent = headerSection
		else
			paragraph("Crows", {
				LayoutOrder = 4,
				TextSize = 13,
				TextColor3 = COLOR_DIM,
				Text = Locale.T("field.crows.later", { level = CropConfig.Crows.FromLevel }),
			}).Parent = headerSection
		end
	end
end

local function renderSquares(field)
	clearSection(squaresSection)
	table.clear(timers)
	heading(squaresSection, 1, Locale.T("field.section.squares"))
	local now = workspace:GetServerTimeNow()
	local open = field.open or {}
	for index, n in open do
		local square = field.squares[tostring(n)]
		local crop = square and cropOf(square.crop)
		local row = create("Frame", {
			Name = "Square" .. n,
			LayoutOrder = index + 1,
			Size = UDim2.new(1, 0, 0, SQUARE_ROW),
			BackgroundColor3 = COLOR_ROW,
			Parent = squaresSection,
		}, { create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
		label("Name", {
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -100, 1, 0),
			TextSize = 16,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextColor3 = if crop then Color3.new(1, 1, 1) else COLOR_DIM,
			Text = if crop then string.format("%d  %s", n, cropTitle(crop)) else tostring(n),
		}).Parent = row
		local time = label("Time", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 0),
			Size = UDim2.fromOffset(86, SQUARE_ROW),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = COLOR_DIM,
			Text = Locale.T("field.square.empty"),
		})
		time.Parent = row
		if crop then
			local ripe = square.grown >= crop.growSeconds
			time.Text = if ripe then Locale.T("field.square.ripe") else countdown(math.max(square.readyAt - now, 1))
			time.TextColor3 = if ripe then COLOR_OK else Color3.new(1, 1, 1)
			table.insert(timers, { label = time, readyAt = square.readyAt, ripe = ripe })
		end
	end
	paragraph("Note", { LayoutOrder = #open + 2, TextSize = 12, TextColor3 = COLOR_DIM, Text = Locale.T("field.square.note") }).Parent =
		squaresSection
end

-- weighted field seconds as hours with one decimal, in the viewer's decimal mark
local function hours(seconds: number)
	return { decimal = string.format("%.1f", seconds / 3600) }
end

-- A field pet's lines for the panel row (E1b; E4b: each job it does, Tending and / or Pest control, with its reach and XP).
local function fieldPetLines(field, square: number, pet): string
	local lines = {}
	local open = openSet(field)
	if pet.job == "Tending" then
		table.insert(lines, Locale.T("field.pet.info", { n = square, level = pet.apt, count = #CropConfig.Reach(square, pet.reach, open) }))
		table.insert(lines, if pet.next
			then Locale.T("field.pet.xp", { xp = hours(pet.xp), next = hours(pet.next) })
			else Locale.T("field.pet.capped"))
	end
	local guard = pet.guard
	if type(guard) == "table" then
		local info = {
			level = guard.level,
			pct = math.round(guard.chance * 100),
			count = #CropConfig.Reach(square, guard.reach, open),
			n = square,
		}
		table.insert(lines, Locale.T(if pet.job == "Tending" then "field.pet.guard" else "field.pet.guardInfo", info))
		table.insert(lines, if guard.next
			then Locale.T("field.pet.guardXp", { xp = hours(guard.xp), next = hours(guard.next) })
			else Locale.T("field.pet.guardCapped"))
	end
	return table.concat(lines, "\n")
end

-- The field pets (E1b): one row per pet (square, job levels, reach, XP; Lift), then the next slot.
local function renderPets(field)
	clearSection(petsSection)
	local placed = {}
	for key, pet in field.pets or {} do
		table.insert(placed, { square = tonumber(key) :: number, pet = pet })
	end
	table.sort(placed, function(a, b)
		return a.square < b.square
	end)
	heading(petsSection, 1, Locale.T("field.section.pets", { used = #placed, slots = field.slots or 1 }))
	for index, entry in placed do
		local pet = entry.pet
		local row = newRow(petsSection, "Pet" .. entry.square, index + 1)
		textColumn(row, LIFT_WIDTH + GAP, Locale.PetName(pet.kind, pet.level, PetClient.NameOf(pet.uid)), fieldPetLines(field, entry.square, pet))
		local lift = button("Lift", {
			LayoutOrder = 2,
			Size = UDim2.fromOffset(LIFT_WIDTH, 34),
			BackgroundColor3 = COLOR_SELL,
			TextSize = 15,
			Text = Locale.T("field.pet.lift"),
			Parent = row,
		}, 2)
		lift.Activated:Connect(function()
			liftPetEvent:FireServer(pet.uid)
		end)
	end
	if #placed == 0 then
		paragraph("Empty", { LayoutOrder = 2, Text = Locale.T("field.pets.empty") }).Parent = petsSection
	end
	if field.slotPrice then
		local enough = coinsNow() >= field.slotPrice
		local row = newRow(petsSection, "Slot", 50)
		textColumn(row, SLOT_WIDTH + GAP, Locale.T("field.slot.title", { n = field.slots + 1 }), Locale.T("field.slot.info", { count = field.slotPrice }))
		local buy = button("BuySlot", {
			LayoutOrder = 2,
			Size = UDim2.fromOffset(SLOT_WIDTH, 34),
			BackgroundColor3 = if enough then COLOR_BUY else COLOR_LOCKED,
			TextSize = 15,
			Text = Locale.T("field.slot.buy"),
			Parent = row,
		}, 2)
		buy.Activated:Connect(function()
			local state = fieldState
			if state then
				buyPetSlotEvent:FireServer(state.slots + 1)
			end
		end)
	else
		paragraph("Slots", { LayoutOrder = 50, TextSize = 14, TextColor3 = COLOR_OK, Text = Locale.T("field.slot.done") }).Parent = petsSection
	end
	paragraph("Note", { LayoutOrder = 51, TextSize = 12, TextColor3 = COLOR_DIM, Text = Locale.T("field.pets.note") }).Parent = petsSection
	paragraph("GuardNote", { LayoutOrder = 52, TextSize = 12, TextColor3 = COLOR_DIM, Text = Locale.T("field.pets.guardNote") }).Parent = petsSection
end

local function renderSeeds(field)
	clearSection(seedsSection)
	heading(seedsSection, 1, Locale.T("field.section.seeds"))
	local total = CropConfig.SeedTotal(field.seeds)
	local capacity = barnOf(field)
	for index, crop in CropConfig.Crops do
		local locked = field.level < crop.renown
		local stock = field.seeds[crop.id] or 0
		local reserved = if locked or crop.rare then LOCK_WIDTH + GAP else BUY1_WIDTH + BUY10_WIDTH + GAP * 2
		local row = newRow(seedsSection, crop.id, index + 1)
		textColumn(
			row,
			reserved,
			cropTitle(crop),
			if crop.rare
				then Locale.T("field.seed.rareInfo", { time = growTime(growSecondsOn(field, crop)), sale = crop.sale, stock = stock })
				else Locale.T("field.seed.info", { time = growTime(growSecondsOn(field, crop)), sale = crop.sale, seed = crop.seed, stock = stock })
		)
		if locked or crop.rare then -- rare seeds come only from the obby (E2a): the row says from which world
			local lock = paragraph("Locked", {
				LayoutOrder = 2,
				Size = UDim2.new(0, LOCK_WIDTH, 0, 0),
				Font = StudStyle.Font,
				TextSize = 15,
				TextColor3 = if crop.rare then COLOR_RARE else COLOR_DIM,
				TextXAlignment = Enum.TextXAlignment.Center,
				Text = if crop.rare
					then Locale.T("field.seed.fromWorld", { world = Locale.WorldName(StageConfig.Worlds[crop.world]) })
					else Locale.T("field.seed.locked", { level = crop.renown }),
			})
			lock.Parent = row
		else
			for slot, option in { { name = "Buy1", amount = 1, width = BUY1_WIDTH }, { name = "Buy10", amount = 10, width = BUY10_WIDTH } } do
				local affordable = coinsNow() >= crop.seed * option.amount and total + option.amount <= capacity
				local buy = button(option.name, {
					LayoutOrder = slot + 1,
					Size = UDim2.fromOffset(option.width, 36),
					BackgroundColor3 = if affordable then COLOR_BUY else COLOR_LOCKED,
					TextSize = 16,
					Text = "+" .. option.amount,
					Parent = row,
				}, 2)
				buy.Activated:Connect(function()
					buySeedsEvent:FireServer(crop.id, option.amount)
				end)
			end
		end
	end
	paragraph("Barn", {
		LayoutOrder = #CropConfig.Crops + 2,
		Font = StudStyle.Font,
		TextSize = 15,
		TextColor3 = if total >= capacity then COLOR_ERROR else Color3.new(1, 1, 1),
		Text = Locale.T("field.barn", { total = total, capacity = capacity }),
	}).Parent = seedsSection
	paragraph("Note", { LayoutOrder = #CropConfig.Crops + 3, TextSize = 12, TextColor3 = COLOR_DIM, Text = Locale.T("field.seed.note") }).Parent =
		seedsSection
end

-- The market cart (E1c4): today's offers (bargains on unlocked crops, a taste of the next locked one); the button buys what is left.
local function renderCart(field)
	clearSection(cartSection)
	cartTimer = nil
	heading(cartSection, 1, Locale.T("field.section.cart"))
	local cart = field.cart
	if not cart then
		return
	end
	local next = paragraph("Next", { LayoutOrder = 2, TextSize = 13, TextColor3 = COLOR_DIM, Text = "" })
	next.Parent = cartSection
	cartTimer = { label = next, at = cart.nextAt, asked = false }
	cartTimer.label.Text = Locale.T("field.cart.next", { time = countdown(math.max(cart.nextAt - workspace:GetServerTimeNow(), 0)) })
	local total, capacity = CropConfig.SeedTotal(field.seeds), barnOf(field)
	for _, offer in cart.offers do
		local crop = cropOf(offer.crop)
		if crop then
			local row = newRow(cartSection, "Offer" .. offer.slot, offer.slot + 2)
			local info = if offer.taste
				then Locale.T("field.cart.taste", { level = crop.renown, price = offer.price })
				else Locale.T("field.cart.bargain", {
					percent = math.floor((offer.discount or 0) * 100 + 0.5),
					price = offer.price,
					base = offer.base,
				})
			textColumn(row, UPGRADE_WIDTH + GAP, Locale.T("field.cart.row", { crop = cropTitle(crop), left = offer.left, count = offer.count }), info)
			local cost = offer.price * offer.left
			local affordable = offer.left > 0 and coinsNow() >= cost and total + offer.left <= capacity
			local buy = button("Buy", {
				LayoutOrder = 2,
				Size = UDim2.fromOffset(UPGRADE_WIDTH, 40),
				BackgroundColor3 = if affordable then COLOR_BUY else COLOR_LOCKED,
				TextSize = 15,
				TextWrapped = true,
				Text = if offer.left > 0 then Locale.T("field.upgrade.price", { count = cost }) else Locale.T("field.cart.soldOut"),
				Parent = row,
			}, 2)
			if offer.left > 0 then
				buy.Activated:Connect(function()
					buyCartEvent:FireServer(offer.slot, offer.crop, offer.left)
				end)
			end
		end
	end
	paragraph("Note", { LayoutOrder = 50, TextSize = 12, TextColor3 = COLOR_DIM, Text = Locale.T("field.cart.note") }).Parent = cartSection
end

local function renderCrops(field)
	clearSection(cropsSection)
	heading(cropsSection, 1, Locale.T("field.section.crops"))
	local any = false
	for index, crop in CropConfig.Crops do
		local owned = field.items[crop.id] or 0
		if owned > 0 then
			any = true
			local row = newRow(cropsSection, crop.id, index + 1)
			local best = field.best and field.best[crop.id]
			textColumn(
				row,
				SELL_WIDTH + GAP,
				string.format("%s × %s", cropTitle(crop), Locale.Number(owned)),
				if best then Locale.T("field.crop.best", { kg = kgText(crop, best) }) else nil
			)
			local value = CropConfig.SaleValue(crop, field.sizes and field.sizes[crop.id] or owned)
			local sell = button("Sell", {
				LayoutOrder = 2,
				Size = UDim2.fromOffset(SELL_WIDTH, 40),
				BackgroundColor3 = COLOR_SELL,
				TextSize = 14,
				TextWrapped = true,
				Text = Locale.T("field.crop.sell", { coins = value }),
				Parent = row,
			}, 2)
			sell.Activated:Connect(function()
				sellEvent:FireServer(crop.id, owned)
			end)
		end
	end
	if any then
		paragraph("Note", { LayoutOrder = #CropConfig.Crops + 2, TextSize = 12, TextColor3 = COLOR_DIM, Text = Locale.T("field.crops.note") }).Parent =
			cropsSection
	else
		paragraph("Empty", { LayoutOrder = 2, Text = Locale.T("field.crops.empty") }).Parent = cropsSection
	end
end

-- The next square's price (E1d2: the player buys any locked square through its prompt on the field; the price depends only on
-- how many are open).
local function renderExpand(field)
	clearSection(expandSection)
	heading(expandSection, 1, Locale.T("field.section.expand"))
	local expansion = CropConfig.NextExpansion(#(field.open or {}))
	if not expansion then
		paragraph("Info", { LayoutOrder = 2, Font = StudStyle.Font, TextSize = 16, TextColor3 = COLOR_OK, Text = Locale.T("field.expand.done") }).Parent =
			expandSection
		return
	end
	local lines = { Locale.T("field.expand.next", { count = expansion.price }) }
	if field.level < expansion.renown then
		table.insert(lines, "<font color='#f06a5a'>" .. Locale.T("field.expand.needRenown", { level = expansion.renown }) .. "</font>")
	end
	if coinsNow() < expansion.price then
		table.insert(lines, Locale.T("common.needMoreCoins", { count = expansion.price - coinsNow() }))
	end
	paragraph("Info", { LayoutOrder = 2, TextSize = 15, TextColor3 = Color3.new(1, 1, 1), RichText = true, Text = table.concat(lines, "\n") }).Parent =
		expandSection
	paragraph("Hint", { LayoutOrder = 3, TextSize = 13, TextColor3 = COLOR_DIM, Text = Locale.T("field.expand.hint") }).Parent = expandSection
end

-- The field upgrades (E1c1): level, what it does now and at the next level, and the price.
local function renderUpgrades(field)
	clearSection(upgradesSection)
	heading(upgradesSection, 1, Locale.T("field.section.upgrades"))
	for index, upgrade in CropConfig.Upgrades do
		local keys = UPGRADE_KEYS[upgrade.id]
		local level = CropConfig.UpgradeLevel(field.upgrades, upgrade.id)
		local top = #upgrade.prices
		local price = upgrade.prices[level + 1]
		local function effect(at: number): number
			return if upgrade.id == "Growth" then math.floor(upgrade.step * at * 100 + 0.5) else CropConfig.BarnFor(at)
		end
		local info = if price
			then Locale.T(keys.effect, { now = effect(level), next = effect(level + 1) })
			else Locale.T(keys.max, { now = effect(level) })
		local row = newRow(upgradesSection, upgrade.id, index + 1)
		textColumn(
			row,
			UPGRADE_WIDTH + GAP,
			Locale.T("field.upgrade.level", { name = upgrade.icon .. " " .. Locale.T(keys.name), level = level, max = top }),
			info
		)
		local affordable = price ~= nil and coinsNow() >= price
		local buy = button("Buy", {
			LayoutOrder = 2,
			Size = UDim2.fromOffset(UPGRADE_WIDTH, 40),
			BackgroundColor3 = if affordable then COLOR_BUY else COLOR_LOCKED,
			TextSize = 15,
			TextWrapped = true,
			Text = if price then Locale.T("field.upgrade.price", { count = price }) else Locale.T("field.upgrade.maxed"),
			Parent = row,
		}, 2)
		if price then
			buy.Activated:Connect(function()
				buyUpgradeEvent:FireServer(upgrade.id, level)
			end)
		end
	end
end

-- The garden tools (E1c3): like the upgrades, and each level needs a Renown level (a red line while it is too low).
local function renderTools(field)
	clearSection(toolsSection)
	heading(toolsSection, 1, Locale.T("field.section.tools"))
	for index, tool in CropConfig.Tools do
		local keys = TOOL_KEYS[tool.id]
		local level = CropConfig.ToolLevel(field.tools, tool.id)
		local price = tool.prices[level + 1]
		local function percent(at: number): number
			return if at > 0 then math.floor(tool.effect[at] * 100 + 0.5) else 0
		end
		local info = if price
			then Locale.T(keys.effect, { now = percent(level), next = percent(level + 1) })
			else Locale.T(keys.max, { now = percent(level) })
		local row = newRow(toolsSection, tool.id, index + 1)
		local column = textColumn(
			row,
			UPGRADE_WIDTH + GAP,
			Locale.T("field.upgrade.level", { name = tool.icon .. " " .. Locale.T(keys.name), level = level, max = #tool.prices }),
			info
		)
		local renownOk = not price or field.level >= tool.renown[level + 1]
		if not renownOk then
			paragraph("Renown", {
				LayoutOrder = 3,
				TextSize = 13,
				TextColor3 = COLOR_ERROR,
				Text = Locale.T("field.expand.needRenown", { level = tool.renown[level + 1] }),
			}).Parent =
				column
		end
		local affordable = price ~= nil and renownOk and coinsNow() >= price
		local buy = button("Buy", {
			LayoutOrder = 2,
			Size = UDim2.fromOffset(UPGRADE_WIDTH, 40),
			BackgroundColor3 = if affordable then COLOR_BUY else COLOR_LOCKED,
			TextSize = 15,
			TextWrapped = true,
			Text = if price then Locale.T("field.upgrade.price", { count = price }) else Locale.T("field.upgrade.maxed"),
			Parent = row,
		}, 2)
		if price then
			buy.Activated:Connect(function()
				buyToolEvent:FireServer(tool.id, level)
			end)
		end
	end
end

local function renderPanel()
	titleLabel.Text = Locale.T("field.title")
	if not panelPoint then
		return
	end
	local field = fieldState
	if not field then
		clearSection(headerSection)
		paragraph("Level", { Text = Locale.T("common.loading") }).Parent = headerSection
		clearSection(squaresSection)
		clearSection(petsSection)
		clearSection(seedsSection)
		clearSection(cartSection)
		cartTimer = nil
		crowLabel = nil
		clearSection(cropsSection)
		clearSection(expandSection)
		clearSection(upgradesSection)
		clearSection(toolsSection)
		return
	end
	renderHeader(field)
	renderSquares(field)
	renderPets(field)
	renderSeeds(field)
	renderCart(field)
	renderCrops(field)
	renderExpand(field)
	renderUpgrades(field)
	renderTools(field)
end

-- Picker rendering ----------------------------------------------------------------------------------------------------------

local pickerItems = {}

local function closePicker()
	pickerPoint, pickerSquare = nil, nil
	picker.Visible = false
	if pickerMode == "pet" then
		GardenView.ShowReach(nil)
	end
end

local function openPanel(scrollToSeeds: boolean?)
	panelPoint = rootPosition() or Vector3.zero
	panel.Visible = true
	renderPanel()
	if scrollToSeeds then
		task.spawn(function()
			task.wait() -- the automatic sizes settle on the next frame
			content.CanvasPosition = Vector2.new(0, math.max(0, seedsSection.AbsolutePosition.Y - content.AbsolutePosition.Y + content.CanvasPosition.Y - 4))
		end)
	end
end

local function closePanel()
	panelPoint = nil
	panel.Visible = false
end

-- Squares a pet with Tending level `level` works from `square` on the current field.
local function reachOf(square: number, level: number): { number }
	return CropConfig.Reach(square, PetConfig.ReachShape(level), if fieldState then openSet(fieldState) else nil)
end

-- The highest job level of a field pet in the State (Tending `apt` for a tender, and its Pest control): the widest reach (E4b).
local function widestOf(pet): number
	local guard = if type(pet.guard) == "table" then pet.guard.level else 0
	return math.max(if pet.job == "Tending" then pet.apt else 0, guard)
end

-- One row of the pet picker at height `y`: a title, an info line; enabled rows are green and clickable.
local function pickerRow(name: string, y: number, title: string, info: string, enabled: boolean)
	local color = if enabled then COLOR_BUY else COLOR_LOCKED
	local row = create("TextButton", {
		Name = name,
		Position = UDim2.new(0, 8, 0, y),
		Size = UDim2.new(1, -16, 0, PICKER_ROW),
		BackgroundColor3 = StudStyle.Shade(color, 0.75),
		AutoButtonColor = enabled,
		Text = "",
		Parent = picker,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 8) }),
		create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = color, Thickness = 2 }),
		label("Name", {
			Position = UDim2.fromOffset(12, 6),
			Size = UDim2.new(1, -24, 0, 24),
			TextSize = 18,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = title,
		}),
		label("Info", {
			Position = UDim2.fromOffset(12, 30),
			Size = UDim2.new(1, -24, 0, 18),
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextColor3 = COLOR_INFO,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = info,
		}),
	})
	table.insert(pickerItems, row)
	return row
end

-- The pet picker (E1b): lift the pet on `square`, or place / move a pet with Tending there. Hovering a row tints its reach.
local function renderPetPicker(square: number)
	pickerTitle.Text = Locale.T("field.petPicker.title", { n = square })
	local field = fieldState
	local here = field and field.pets and field.pets[tostring(square)]
	local used = 0
	for _ in (field and field.pets) or {} do
		used += 1
	end
	local y = 42
	if here then
		local row = pickerRow("Lift", y, Locale.T("field.petPicker.lift", { pet = Locale.PetName(here.kind, here.level, PetClient.NameOf(here.uid)) }), Locale.T("field.petPicker.liftInfo"), true)
		row.Activated:Connect(function()
			liftPetEvent:FireServer(here.uid)
			closePicker()
		end)
		y += PICKER_ROW + GAP
		GardenView.ShowReach(reachOf(square, widestOf(here)))
	end
	local candidates = {}
	for _, pet in PetClient.Inventory() do
		if (pet.tending > 0 or pet.guard > 0) and not (here and pet.uid == here.uid) then
			table.insert(candidates, pet)
		end
	end
	table.sort(candidates, function(a, b)
		if a.tending ~= b.tending then
			return a.tending > b.tending
		end
		if a.guard ~= b.guard then
			return a.guard > b.guard
		end
		return (tonumber(a.uid) or 0) < (tonumber(b.uid) or 0)
	end)
	for _, pet in candidates do
		local reach = reachOf(square, math.max(pet.tending, pet.guard))
		local enabled = not pet.equipped and not pet.penned and (pet.field ~= nil or used < (field and field.slots or 1))
		local info
		if pet.equipped then
			info = Locale.T("field.petPicker.equipped")
		elseif pet.penned then
			info = Locale.T("field.petPicker.penned")
		elseif not enabled then
			info = Locale.T("field.petPicker.noSlot")
		elseif pet.tending > 0 then
			local count = #reachOf(square, pet.tending)
			info = if pet.field
				then Locale.T("field.petPicker.move", { level = pet.tending, count = count, n = pet.field })
				else Locale.T("field.petPicker.info", { level = pet.tending, count = count })
			if pet.guard > 0 then
				info ..= " · " .. Locale.T("pets.guard", { level = pet.guard })
			end
		else
			info = Locale.T("field.petPicker.guard", { level = pet.guard, count = #reach })
			if pet.field then
				info ..= " · " .. Locale.T("field.petPicker.now", { n = pet.field })
			end
		end
		local row = pickerRow("Pet_" .. pet.uid, y, Locale.PetName(pet.kind, pet.level, pet.name), info, enabled)
		y += PICKER_ROW + GAP
		row.MouseEnter:Connect(function()
			GardenView.ShowReach(reach)
		end)
		row.MouseLeave:Connect(function()
			GardenView.ShowReach(if here then reachOf(square, widestOf(here)) else nil)
		end)
		if enabled then
			row.Activated:Connect(function()
				placePetEvent:FireServer(square, pet.uid)
				closePicker()
			end)
		end
	end
	if #candidates == 0 and not here then
		local hint = paragraph("None", {
			Position = UDim2.fromOffset(12, 44),
			Size = UDim2.new(1, -24, 0, 0),
			TextSize = 15,
			Text = Locale.T("field.petPicker.none"),
		})
		hint.Parent = picker
		table.insert(pickerItems, hint)
		y = 150
	end
	picker.Size = UDim2.new(1, -16, 0, y + 6)
end

local function renderPicker()
	for _, item in pickerItems do
		item:Destroy()
	end
	table.clear(pickerItems)
	local square = pickerSquare
	if not square then
		return
	end
	if pickerMode == "pet" then
		renderPetPicker(square)
		return
	end
	pickerTitle.Text = Locale.T("field.picker.title", { n = square })
	local field = fieldState
	local rows = 0
	if field then
		for _, crop in CropConfig.Crops do
			local stock = field.seeds[crop.id] or 0
			if stock > 0 then -- seeds held can be planted before the Renown gate (the market cart's taste, E1c4)
				local y = 42 + rows * (PICKER_ROW + GAP)
				rows += 1
				local row = create("TextButton", {
					Name = crop.id,
					Position = UDim2.new(0, 8, 0, y),
					Size = UDim2.new(1, -16, 0, PICKER_ROW),
					BackgroundColor3 = StudStyle.Shade(COLOR_BUY, 0.75),
					AutoButtonColor = true,
					Text = "",
					Parent = picker,
				}, {
					create("UICorner", { CornerRadius = UDim.new(0, 8) }),
					create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = COLOR_BUY, Thickness = 2 }),
					label("Name", {
						Position = UDim2.fromOffset(12, 6),
						Size = UDim2.new(1, -24, 0, 24),
						TextSize = 18,
						TextTruncate = Enum.TextTruncate.AtEnd,
						Text = cropTitle(crop),
					}),
					label("Info", {
						Position = UDim2.fromOffset(12, 30),
						Size = UDim2.new(1, -24, 0, 18),
						Font = Enum.Font.Gotham,
						TextSize = 13,
						TextColor3 = COLOR_INFO,
						TextTruncate = Enum.TextTruncate.AtEnd,
						Text = Locale.T("field.picker.info", { stock = stock, time = growTime(growSecondsOn(fieldState, crop)) }),
					}),
				})
				table.insert(pickerItems, row)
				row.Activated:Connect(function()
					local target = pickerSquare
					if target then
						plantEvent:FireServer(target, crop.id)
					end
					closePicker()
				end)
			end
		end
	end
	if rows > 0 then
		picker.Size = UDim2.new(1, -16, 0, 42 + rows * (PICKER_ROW + GAP) + 6)
		return
	end
	-- no seeds in stock: a hint and a way to the seed shop (the Garden panel)
	local hint = paragraph("None", {
		Position = UDim2.fromOffset(12, 44),
		Size = UDim2.new(1, -24, 0, 0),
		TextSize = 15,
		Text = Locale.T("field.picker.none"),
	})
	hint.Parent = picker
	table.insert(pickerItems, hint)
	local shop = button("Shop", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.new(1, -24, 0, 40),
		BackgroundColor3 = COLOR_BUY,
		TextSize = 18,
		Text = Locale.T("field.picker.shop"),
		Parent = picker,
	}, 6)
	table.insert(pickerItems, shop)
	shop.Activated:Connect(function()
		closePicker()
		openPanel(true)
	end)
	picker.Size = UDim2.new(1, -16, 0, 170)
end

local function openPicker(square: number, at: Vector3?, mode: string?)
	if pickerMode == "pet" then
		GardenView.ShowReach(nil)
	end
	pickerMode = mode or "seed"
	pickerSquare = square
	pickerPoint = at or rootPosition() or Vector3.zero
	picker.Visible = true
	renderPicker()
end

local function staticTexts()
	openButton.Text = Locale.T("field.button")
	titleLabel.Text = Locale.T("field.title")
end
staticTexts()

local function renderAll()
	if panelPoint then
		renderPanel()
	end
	if pickerSquare then
		renderPicker()
	end
end

-- Toast -------------------------------------------------------------------------------------------------------------------

local function showToast(text: string, color: Color3?, seconds: number?)
	toastToken += 1
	local mine = toastToken
	toast.Text = text
	toast.TextColor3 = color or Color3.new(1, 1, 1)
	toast.Visible = true
	task.delay(seconds or 3, function()
		if toastToken == mine then
			toast.Visible = false
		end
	end)
end

-- Events ------------------------------------------------------------------------------------------------------------------

closeButton.Activated:Connect(closePanel)
pickerClose.Activated:Connect(closePicker)
openButton.Activated:Connect(function()
	if panelPoint then
		closePanel()
	else
		openPanel()
	end
end)

-- "Cat Lv 4" for a uid in the pet state ("" when unknown)
local function petNameOf(uid: string?): string
	local pet = uid and PetClient.State and PetClient.State.pets[uid]
	return if pet then Locale.PetName(pet.Kind, PetConfig.ClampLevel(pet.Level), PetClient.NameOf(uid)) else ""
end

-- Once per session: the pens' conversion, what the pets harvested while the player was away (State.field.notice, E1b) and the
-- crows' raid (E4b: what they ate, which guards chased them off).
local function showNotices(field)
	local notice = field and field.notice
	if type(notice) ~= "table" then
		return
	end
	local lines = {}
	if notice.converted and not noticesShown.converted then
		noticesShown.converted = true
		local c = notice.converted
		table.insert(lines, Locale.T("field.notice.converted", { count = c.slots }))
		if c.refund > 0 then
			table.insert(lines, Locale.T("field.notice.refund", { count = c.refund }))
		end
		if c.returned > 0 then
			table.insert(lines, Locale.T("field.notice.returned", { count = c.returned }))
		end
	end
	if notice.tended and not noticesShown.tended then
		noticesShown.tended = true
		local items = {}
		for _, crop in CropConfig.Crops do
			local n = notice.tended[crop.id]
			if n then
				table.insert(items, Locale.T("field.notice.item", { count = n, crop = Locale.CropName(crop) }))
			end
		end
		table.insert(lines, Locale.T("field.notice.tended", { items = table.concat(items, ", ") }))
	end
	local crows = notice.crows -- E4b: { ate = { [crop] = n }, chased = { [uid] = n } }
	local chased = type(crows) == "table" and type(crows.chased) == "table" and crows.chased or {}
	-- the guards' names need the pet state: wait for it (PetClient.Changed calls this again)
	if type(crows) == "table" and not noticesShown.crows and (next(chased) == nil or PetClient.State ~= nil) then
		noticesShown.crows = true
		local items = {}
		for _, crop in CropConfig.Crops do
			local n = type(crows.ate) == "table" and crows.ate[crop.id]
			if n then
				table.insert(items, Locale.T("field.notice.item", { count = n, crop = Locale.CropName(crop) }))
			end
		end
		if #items > 0 then
			table.insert(lines, Locale.T("field.notice.crowsAte", { items = table.concat(items, ", ") }))
		end
		for uid, n in chased do
			table.insert(lines, Locale.T("field.notice.chased", { pet = petNameOf(tostring(uid)), count = n }))
		end
	end
	if #lines > 0 then
		showToast(table.concat(lines, "\n"), COLOR_OK, NOTICE_SECONDS)
	end
end

remotes:WaitForChild("State").OnClientEvent:Connect(function(state)
	fieldState = if type(state) == "table" then state.field else nil
	renderAll()
	showNotices(fieldState)
end)

PetClient.Changed:Connect(function()
	if panelPoint then
		renderPanel() -- the Coins changed: affordability colours
	end
	if pickerSquare and pickerMode == "pet" then
		renderPicker() -- a pet was equipped, hatched or levelled
	end
	showNotices(fieldState) -- a crow notice waits for the guards' names (E4b)
end)

-- Answers of the field pet actions (E1b): toasts; a placed pet's reach stays tinted for REACH_SECONDS.
local function petResult(action: string, ok: boolean, detail)
	if not ok then
		showToast(Locale.T(PET_REJECT_KEYS[detail] or REJECT_KEYS[detail] or "common.reject.failed"), COLOR_ERROR)
		return
	end
	if action == "PlacePet" then
		local name = petNameOf(detail.uid)
		showToast(Locale.T(if detail.moved then "field.toast.petMoved" else "field.toast.petPlaced", { pet = name, n = detail.square }), COLOR_OK)
		local pet = PetClient.State and PetClient.State.pets[detail.uid]
		if pet then
			reachToken += 1
			local mine = reachToken
			GardenView.ShowReach(reachOf(detail.square, math.max(PetConfig.AptitudeLevel(pet, "Tending"), PetConfig.AptitudeLevel(pet, "PestControl"))))
			task.delay(REACH_SECONDS, function()
				if reachToken == mine and not (pickerSquare and pickerMode == "pet") then
					GardenView.ShowReach(nil)
				end
			end)
		end
	elseif action == "LiftPet" then
		showToast(Locale.T("field.toast.petLifted", { pet = petNameOf(detail.uid) }), COLOR_OK)
	else
		showToast(Locale.T("field.toast.slot", { n = detail }), COLOR_OK)
	end
end

remotes:WaitForChild("Result").OnClientEvent:Connect(function(action, ok, detail)
	if PET_ACTIONS[action] then
		return petResult(action, ok, detail)
	end
	if action == "BuyUpgrade" or action == "BuyTool" then
		local names = if action == "BuyTool" then TOOL_KEYS else UPGRADE_KEYS
		if not ok then
			local key = if detail == "maxed" then "field.reason.upgradeMaxed" else REJECT_KEYS[detail]
			showToast(Locale.T(key or "common.reject.failed"), COLOR_ERROR)
		elseif type(detail) == "table" and names[detail.id] then
			showToast(Locale.T("field.toast.upgrade", { name = Locale.T(names[detail.id].name), level = detail.level }), COLOR_OK)
		end
		return
	end
	if
		action ~= "Plant"
		and action ~= "Harvest"
		and action ~= "BuySeeds"
		and action ~= "BuyCart"
		and action ~= "Sell"
		and action ~= "BuySquare"
	then
		return -- pens, incubators and the food stand answer on the same remote
	end
	if not ok then
		showToast(Locale.T(REJECT_KEYS[detail] or "common.reject.failed"), COLOR_ERROR)
		return
	end
	local crop = type(detail) == "table" and detail.crop and cropOf(detail.crop)
	local name = if crop then Locale.CropName(crop) else ""
	if action == "Harvest" then
		local size = if type(detail.size) == "number" then detail.size else 1
		local lines = { Locale.T("field.toast.harvestSize", { crop = name, kg = kgText(crop, size) }) }
		if detail.extra then
			table.insert(lines, Locale.T("field.toast.shears"))
		end
		local tag = CropConfig.SizeLabel(size)
		local extra = {}
		if tag then
			table.insert(extra, Locale.T(if tag == "Giant" then "field.size.giant" else "field.size.big"))
		end
		if detail.best then
			table.insert(extra, Locale.T("field.size.record"))
		end
		if #extra > 0 then
			table.insert(lines, table.concat(extra, " "))
		end
		if detail.levelUp then
			table.insert(lines, Locale.T("field.toast.renownUp", { level = detail.level }))
		end
		showToast(table.concat(lines, "\n"), COLOR_OK)
	elseif action == "Sell" then
		showToast(Locale.T("field.toast.sell", { count = detail.paid }), COLOR_OK)
	elseif action == "BuySeeds" or action == "BuyCart" then
		showToast(Locale.T("field.toast.seeds", { crop = name, count = detail.count }), COLOR_OK)
	elseif action == "BuySquare" then
		showToast(Locale.T("field.toast.square", { n = detail.square }), COLOR_OK)
	else
		showToast(Locale.T("field.toast.plant", { crop = name }), COLOR_OK)
	end
end)

Locale.Changed:Connect(function()
	staticTexts()
	renderAll()
end)

-- The prompts on the own plot's squares (GardenView): plant opens the picker, harvest and buy fire at once
GardenView.OnSquare(function(square, action, soil)
	if action == "harvest" then
		harvestEvent:FireServer(square)
	elseif action == "buy" then
		if fieldState then
			buySquareEvent:FireServer(square, #(fieldState.open or {}))
		end
	elseif action == "plant" then
		openPicker(square, soil and soil.Position)
	elseif action == "pet" then
		openPicker(square, soil and soil.Position, "pet")
	end
end)

-- Test hooks: OpenField = true opens the Garden panel, OpenPicker = square opens the seed picker (display only)
screenGui:GetAttributeChangedSignal("OpenField"):Connect(function()
	if screenGui:GetAttribute("OpenField") then
		openPanel()
		screenGui:SetAttribute("OpenField", nil)
	end
end)
screenGui:GetAttributeChangedSignal("OpenPetPicker"):Connect(function()
	local square = screenGui:GetAttribute("OpenPetPicker")
	if type(square) == "number" then
		openPicker(square, nil, "pet")
		screenGui:SetAttribute("OpenPetPicker", nil)
	end
end)
screenGui:GetAttributeChangedSignal("OpenPicker"):Connect(function()
	local square = screenGui:GetAttribute("OpenPicker")
	if type(square) == "number" then
		openPicker(square)
		screenGui:SetAttribute("OpenPicker", nil)
	end
end)

-- Every TICK_SECONDS: the button near the own plot, panels closing when the player walks away, the countdowns
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < TICK_SECONDS then
		return
	end
	elapsed = 0
	local root = rootPosition()

	local slot = player:GetAttribute(GardenConfig.PlotAttribute)
	local plot = if type(slot) == "number" then GardenConfig.PlotCFrame(slot) else nil
	local near = false
	if root and plot then
		local offset = root - plot.Position
		near = Vector3.new(offset.X, 0, offset.Z).Magnitude <= SHOW_DISTANCE
	end
	openButton.Visible = near

	if root then
		if panelPoint and (root - panelPoint).Magnitude > CLOSE_DISTANCE then
			closePanel()
		end
		if pickerPoint and (root - pickerPoint).Magnitude > CLOSE_DISTANCE then
			closePicker()
		end
	end

	if panelPoint then
		local now = workspace:GetServerTimeNow()
		for _, timer in timers do
			if not timer.ripe then
				timer.label.Text = countdown(math.max(timer.readyAt - now, 1)) -- ripe only when the server says so (State)
			end
		end
		crowForecast()
		if cartTimer then
			cartTimer.label.Text = Locale.T("field.cart.next", { time = countdown(math.max(cartTimer.at - now, 0)) })
			if now >= cartTimer.at and not cartTimer.asked then
				cartTimer.asked = true -- the new day's offers come with the next State
				requestStateEvent:FireServer()
			end
		end
	end
end)

requestStateEvent:FireServer()
screenGui.Parent = player:WaitForChild("PlayerGui")
