-- FieldHand (U3a + U3b, docs/GDD.md §7.9): acting on the own field by tapping a square, no prompts.
--   * tap (TouchTapInWorld) / click (left button pressed and released within TAP_SECONDS and TAP_PIXELS, not over a GUI) while
--     the character is within TAP_DISTANCE (horizontal) of the own plot centre: a ray against the own plot's view (GardenView)
--     or the field's plane picks a square; it gets a white outline and the square card slides up at the bottom. Tapping the
--     selected square again, or off the field, closes the card; so does walking away;
--   * square card: crop icon and name (or empty / overgrown), a progress bar with the time left (ripe: full, "Ripe!"), the
--     Crop / Pets group boxes, non-clickable strongest-job coverage and a resident section with Move / Take off field;
--     the pet picker shows capacity, origin/consequence and a Place pet button for resting, field and equipped pets;
--   * a placed pet's reach is tinted for REACH_SECONDS (GardenView.ShowReach), as is the reach of a row hovered in the pet picker;
--   * hand bar (U3b, shown while the tap range applies; a 2 x 2 block above the jump button on a touch screen without a keyboard,
--     else a row at the bottom right): Seeds (a seed is selected at once, the last picked while any is left, else the first, and
--     the next as soon as it runs out; the card picks another; every tap on an empty square plants it; the button shows the seed
--     and the count left), Basket (every tap on a ripe square harvests it: one Harvest per tap, never all), Pets
--     (a tap on a placed pet takes it in hand, its reach follows the mouse / the last tapped square, a tap on a free open square
--     puts it there: one click with a mouse, two taps on the same square on touch; a tap on the pet's square or on Pets cancels;
--     a free square with nothing in hand opens the pet picker), Look (default: select + card). The other taps select as in Look.
--     Keys 1-4 do what a click on the bar's brick does, in the bar's order (not while typing or with a panel open).
--     Leaving the range resets to Look. A hint line above the bar says what a tap does (in Look: "Tap a square" until the first
--     tap on a square this session). Seeds pulses while nothing is planted and seeds are held, Basket while something is ripe, each
--     until its mode was used once this session;
--   * while the bar shows, white corner brackets (GardenView.ShowHover; never on the selected or the held pet's square) mark the
--     own square under the mouse (and the cursor becomes a pointing hand), else the square the character stands on: squares are
--     things to tap, on touch screens too (no hover there);
--   * every field remote is fired through one queue at most every FIRE_GAP seconds (the server drops actions under 0.2 s apart);
--     a harvest result pops "+1 <crop>" over its square for POP_SECONDS.
-- Display only: the remotes carry a square number (and a crop id / pet uid); GardenField checks plot, distance, square, seeds,
-- unlocks and Coins and answers on GardenRemotes.Result (FieldClient shows the toasts). Times: workspace:GetServerTimeNow().
-- The GUI is built here (ScreenGui FieldHandGui; stud bricks, StudStyle). Card width: at most CARD_WIDTH, and on a touch screen
-- clear of the thumbstick and the jump button (TOUCH_SIDE on each side); it sits above FieldClient's Field button.
-- FieldHandGui attributes: Select = square selects it as a tap would (test hook, cleared after use); HoldPet = uid takes that
-- pet in hand in Pets mode (the pet page's "Place on field", cleared after use); HandShown (set here) = whether the bar shows.
-- Buttons: Card.Body.CropGroup.Content.Buttons.<Plant|Harvest>, .PetsGroup.Content.Resident.Buttons.<PlacePet|MovePet|TakeBack>;
-- locked square .Body.Buttons.Buy; Card.Close (fixed beside Card.TitleLabel);
-- pet picker .Body.List.Pet_<uid>.PlacePet; HandBar.<Seeds|Basket|Pets|Look>; Placement.<Hint|Cancel>.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local player = Players.LocalPlayer

local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local PlantGrowth = require(ReplicatedStorage:WaitForChild("PlantGrowth"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local UiKit = require(ReplicatedStorage:WaitForChild("UiKit"))
local ConfirmTap = require(ReplicatedStorage:WaitForChild("ConfirmTap"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local TimeFormat = require(ReplicatedStorage:WaitForChild("TimeFormat"))
local UiSounds = require(ReplicatedStorage:WaitForChild("UiSounds"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))
local Onboarding = require(script.Parent:WaitForChild("Onboarding"))
local GardenView = require(script.Parent:WaitForChild("GardenView"))
local PlotView = require(script.Parent:WaitForChild("PlotView"))
local PetPortrait = require(script.Parent:WaitForChild("PetPortrait"))
local GardenUi = require(script.Parent:WaitForChild("GardenUi"))
local PanelFocus = require(ReplicatedStorage:WaitForChild("PanelFocus"))

local remotes = ReplicatedStorage:WaitForChild("GardenRemotes")
local plantEvent = remotes:WaitForChild("Plant")
local harvestEvent = remotes:WaitForChild("Harvest")
local buySquareEvent = remotes:WaitForChild("BuySquare")
local placePetEvent = remotes:WaitForChild("PlacePet")
local liftPetEvent = remotes:WaitForChild("LiftPet")
local uprootEvent = remotes:WaitForChild("Uproot")

local TAP_DISTANCE = 20 -- studs (horizontal) from the own plot and field (GardenConfig.FootprintDistance); the server accepts 25 (3D)
local TAP_SECONDS = 0.3
local TAP_PIXELS = 8
local RAY_LENGTH = 300
local CARD_WIDTH = 400
local PET_PICKER_WIDTH = 600
local PET_PICKER_HEIGHT = 450
local PET_ACTION_WIDTH = 128 -- fits "🔒 Umístit mazlíčka" (a blocked pet) with some room
local BLOCKED_FADE = 0.5 -- pet picker: a pet that cannot be placed (no free field slot)
local PET_ACTION_HEIGHT = 34 -- the pet picker's Place pet bricks (compact rows) and its top line
local HEADER_HEIGHT = StudStyle.Sizes.Header
local TOUCH_SIDE = 110 -- px kept free on each side on a touch screen (thumbstick, jump button)
local CARD_BOTTOM = 76 -- px from the bottom: above the Field button (48 px at 20 px)
local BUTTON_HEIGHT = 48
local ROW_HEIGHT = 54
local GAP = 8
local PET_ROW_HEIGHT = 52 -- px: the square card's resident pet row
local TRASH_SIZE = 44 -- px: the square card's dig-up brick (a tap target)
local REACH_SECONDS = 3
local TICK_SECONDS = 0.25
local FIRE_GAP = 0.25 -- s between two field remotes (the server's limit is 0.2)
local PENDING_SECONDS = 3 -- a planted / harvested square waits this long for the State before it counts as free again
local POP_SECONDS = 1
local HAND_BUTTON = 52
local HAND_GAP = 6
local HAND_RAISE = 6 -- px the active mode's button is raised
local HINT_GAP = 12 -- px between the hint line and the bar's top (the raised button)
-- Roblox's own hover hand (ClickDetector / DragDetector), shipped with every client; "rbxasset://SystemCursors/PointingHand" was
-- set but drawn as the arrow
local POINTER = "rbxasset://textures/Cursors/DragDetector/HoverCursor.png"
local LIST_MAX = 300 -- px: the pickers' list scrolls beyond this

local COLOR_PANEL = StudStyle.PanelColors.Field
local COLOR_ROW = StudStyle.PetRowColor(COLOR_PANEL)
local COLOR_GROUP_BORDER = StudStyle.Shade(COLOR_PANEL, 0.8)
local COLOR_GO = StudStyle.Colors.Green
local COLOR_PET = StudStyle.Colors.Blue
local COLOR_OFF = StudStyle.Colors.Grey
local COLOR_CLOSE = StudStyle.Colors.Red
local COLOR_INFO = StudStyle.Text.Info
local COLOR_DIM = StudStyle.Text.Dim
local COLOR_BAR = Color3.fromRGB(245, 200, 70)
local COLOR_TRACK = Color3.fromRGB(45, 38, 30)

-- Helpers ---------------------------------------------------------------------------------------------------------------------

local create = UiKit.Create

local label = UiKit.Label

-- a text that wraps and grows downwards
local function paragraph(name: string, order: number, props)
	props.LayoutOrder = order
	props.TextSize = props.TextSize or 15
	return UiKit.Paragraph(name, props)
end

-- a brick button (StudStyle.Brick: colour and text keep being set on the button itself)
local function brick(name: string, props, studs: (number | { compact: boolean? })?)
	props.TextWrapped = true
	return UiKit.Button(name, props, studs)
end

local function pct(share: number): string
	return Locale.Number(math.round(share * 100))
end

local function rootPosition(): Vector3?
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

local function inRange(): boolean
	local plot, at = GardenConfig.PlotOf(player), rootPosition()
	return plot ~= nil and at ~= nil and GardenConfig.FootprintDistance(plot, at) <= TAP_DISTANCE
end

-- State ------------------------------------------------------------------------------------------------------------------------

local fieldState = nil -- GardenRemotes.State.field (FieldClient's comment lists its fields)
local receivedAt = 0
local selected: number? = nil
local page = "card" -- what the card shows: "card", "seeds" (seed picker) or "pets" (pet picker)
local cardOpen = false
local mode = "look" -- hand mode (U3b): "look", "seeds", "basket" or "pets"
local handSeed: string? = nil -- the crop id Seeds mode plants
local held: string? = nil -- uid of the pet in hand (Pets mode)
local heldFrom: number? = nil -- its square, nil while not placed
local heldCard: number? = nil -- source card restored by Cancel
local placing = nil -- { uid, square, picker }: submitted placement, awaiting Result
local placementHint: string? = nil -- occupied destination; cleared by the next preview
local preview: number? = nil -- touch: the square a first tap previewed the held pet's reach on
local hoverSquare: number? = nil
local used = {} -- [mode] = true once chosen this session (its pulse stops)
local tappedSquare = false -- a tap hit a square this session (Look's hint stops)
local standing: number? = nil -- the square outlined under the character
local pendingPlant: { [number]: { crop: string, untilClock: number } } = {}
local pendingHarvest: { [number]: number } = {} -- [square] = until os.clock()
local reachTimer = UiKit.Latest()
local barFill: Frame? = nil
local barText: TextLabel? = nil
local cardRipe = false -- whether the card was drawn for a ripe crop (it redraws when the crop ripens)

local function openSet(): { [number]: boolean }
	local set = {}
	for _, n in (fieldState and fieldState.open) or {} do
		set[n] = true
	end
	return set
end

-- [square] = { kind, level, uid, apt (Tending level), guard (Pest-control level) } of the own field pets (the plot feed)
local function plotPets()
	local own = GardenView.OwnState()
	return PlotView.FieldPets(own and own.field)
end

-- `text` safe inside a RichText label (a player-given pet name)
local function richEscape(text: string): string
	return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function petName(uid: string, kind: string): string
	local name = PetClient.NameOf(uid)
	return if type(name) == "string" and name ~= "" then name else Locale.PetKindName(kind)
end

-- Actual share / ripeness and baseline seconds left, shared with rings.
local function progress(entry, crop, now: number): (number, boolean, number)
	return CropConfig.Progress(entry, crop, receivedAt, now, fieldState and fieldState.tools)
end

local function reachOf(square: number, level: number): { number }
	return CropConfig.Reach(square, PetConfig.ReachShape(level), openSet())
end

local function contains(list: { number }, n: number): boolean
	return table.find(list, n) ~= nil
end

local queue = {} -- { remote, args } fired one by one, FIRE_GAP apart
local lastFire = 0
local function fire(remote: RemoteEvent, ...)
	table.insert(queue, { remote, table.pack(...) })
end

local function ripeEntry(entry): boolean
	local crop = entry and CropConfig.ById[entry.crop]
	if not crop then
		return false
	end
	local _, ripe = progress(entry, crop, workspace:GetServerTimeNow())
	return ripe
end

-- seeds of `crop` held minus the plantings still on their way
local function seedsLeft(crop: string): number
	local count = (fieldState and fieldState.seeds or {})[crop] or 0
	local now = os.clock()
	for square, item in pendingPlant do
		if item.untilClock < now then
			pendingPlant[square] = nil
		elseif item.crop == crop then
			count -= 1
		end
	end
	return math.max(count, 0)
end

local function heldLevel(): number
	local owned = held and PetClient.State and PetClient.State.pets[held]
	if not owned then
		return 0
	end
	return math.max(PetConfig.AptitudeLevel(owned, "Tending"), PetConfig.AptitudeLevel(owned, "PestControl"))
end

-- GUI --------------------------------------------------------------------------------------------------------------------------

local screenGui = create("ScreenGui", {
	Name = "FieldHandGui",
	ResetOnSpawn = false,
	DisplayOrder = 5, -- under the garden panels (Barn, Seed stall: 6)
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	AutoLocalize = false, -- translated by Locale
})

local card = create("Frame", {
	Name = "Card",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 400),
	Size = UDim2.fromOffset(CARD_WIDTH, 0),
	AutomaticSize = Enum.AutomaticSize.None,
	-- blank areas must consume world input too; passive (not Active) so the cursor stays an arrow off its buttons
	Active = false,
	InputSink = Enum.InputSink.All,
	Visible = false,
	Parent = screenGui,
})
local cardTitle = label("TitleLabel", {
	Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
	AutomaticSize = Enum.AutomaticSize.Y,
	TextSize = 20,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Center,
	Text = "",
	Parent = card,
})
create("UIPadding", {
	PaddingLeft = UDim.new(0, 54), PaddingRight = UDim.new(0, 54), Parent = cardTitle,
})
StudStyle.Panel(card, COLOR_PANEL)
local closeHeader: (() -> ())? = nil
local cardClose = brick("Close", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -6, 0, 0),
	Size = UDim2.fromOffset(HEADER_HEIGHT, HEADER_HEIGHT),
	ZIndex = 2,
	BackgroundColor3 = COLOR_CLOSE,
	TextSize = 18,
	Text = "X",
	Parent = card,
}, { compact = true })
cardClose.Activated:Connect(function()
	if closeHeader then
		closeHeader()
	end
end)
local body = create("ScrollingFrame", {
	Name = "Body",
	Position = UDim2.fromOffset(0, HEADER_HEIGHT),
	Size = UDim2.new(1, 0, 1, -HEADER_HEIGHT),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.None,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	Active = false, -- passive like the card: an arrow cursor, world input still sunk
	InputSink = Enum.InputSink.All,
	ScrollBarThickness = 4,
	BorderSizePixel = 0,
	BackgroundTransparency = 1,
	Parent = card,
}, {
	create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, GAP) }),
	create("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	}),
})

local function fitCard()
	local camera = workspace.CurrentCamera
	local available = if screenGui.AbsoluteSize.Y > 0 then screenGui.AbsoluteSize.Y else if camera then camera.ViewportSize.Y else 600
	local room = math.min(available - CARD_BOTTOM - 16, if page == "pets" then PET_PICKER_HEIGHT else math.huge)
	-- Text and automatic layouts can measure in fractional pixels. Round up both the canvas and its window
	-- together so a subpixel remainder cannot create a scrollbar on a card whose content fits.
	local height = math.ceil(body.UIListLayout.AbsoluteContentSize.Y + 18)
	local headerHeight = math.ceil(cardTitle.AbsoluteSize.Y)
	body.CanvasSize = UDim2.fromOffset(0, height)
	body.Position = UDim2.fromOffset(0, headerHeight)
	body.Size = UDim2.new(1, 0, 1, -headerHeight)
	card.Size = UDim2.fromOffset(card.Size.X.Offset, math.max(headerHeight + 44, math.min(headerHeight + height, room)))
end
body.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fitCard)
cardTitle:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitCard)

local portraits = PetPortrait.Cache()

local handBar: Frame -- forward (the hand bar, built below)

local function cardWidth(): number
	local camera = workspace.CurrentCamera
	local viewport = if camera then camera.ViewportSize.X else 800
	local side = if UserInputService.TouchEnabled then TOUCH_SIDE else 12
	if UserInputService.TouchEnabled and handBar and handBar.Visible then
		side = math.max(side, viewport - handBar.AbsolutePosition.X + GAP) -- clear of the 2 x 2 bar above the jump button
	end
	if UserInputService.TouchEnabled then
		local hud = player.PlayerGui:FindFirstChild("ScreenGui")
		local goals = player.PlayerGui:FindFirstChild("GoalsLineGui")
		-- keep the close button clear of the stage HUD (the score panel on a stage, the tracker line elsewhere: EV3b2)
		for _, plate in { hud and hud:FindFirstChild("ScorePanel"), goals and goals:FindFirstChild("Line"), goals and goals:FindFirstChild("Request") } do
			if plate and plate:IsA("GuiObject") and plate.Visible and plate.AbsoluteSize.X > 0 then
				side = math.max(side, viewport - plate.AbsolutePosition.X + GAP)
			end
		end
	end
	local width = if page == "pets" then PET_PICKER_WIDTH else CARD_WIDTH
	return math.floor(math.max(200, math.min(width, viewport - 2 * side)))
end

local function clearBody()
	PetPortrait.Release(body)
	for _, child in body:GetChildren() do
		if not (child:IsA("UIListLayout") or child:IsA("UIPadding")) then
			child:Destroy()
		end
	end
	barFill, barText = nil, nil
	body.CanvasPosition = Vector2.zero
end

-- Shared panel chrome stays fixed while long content scrolls beneath it.
local function header(title: string, onClose: () -> ())
	cardTitle.Text = title
	closeHeader = onClose
end

-- the progress bar with the share and the time left inside
local function bar(order: number, parent: Instance?, height: number?)
	local track, fill, text = UiKit.Bar("Bar", {
		order = order,
		height = height or 30,
		corner = 8,
		track = COLOR_TRACK,
		fill = COLOR_BAR,
		text = "",
		textSize = 18,
		textStroke = 0.3,
		parent = parent or body,
	})
	barFill, barText = fill, text
	return track
end

-- "42% · 3 h 40 min": the growing crop's share (never 100 % before it is ripe) and its away-time left in words
local function growingText(share: number, left: number): string
	return Locale.T("field.card.growing", { pct = Locale.Number(math.min(99, math.floor(share * 100))), time = Locale.Duration(left) })
end

local function buttonRow(order: number, specs, parent: Instance?)
	local row = create("Frame", {
		Name = "Buttons",
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, BUTTON_HEIGHT),
		BackgroundTransparency = 1,
		Parent = parent or body,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, GAP),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
	})
	local count = #specs
	for index, spec in specs do
		local button = brick(spec.name, {
			LayoutOrder = index,
			Size = UDim2.new(1 / count, -GAP * (count - 1) / count, 1, 0),
			BackgroundColor3 = spec.color,
			TextSize = 18,
			Text = spec.text,
			Parent = row,
		}, 2)
		if spec.confirmKey then
			ConfirmTap.Wrap(button, spec.confirmKey, spec.needsConfirm, spec.action)
		else
			button.Activated:Connect(spec.action)
		end
	end
	return row
end

local function groupBox(name: string, order: number, key: string): Frame
	local content, legend = GardenUi.GroupBox(body, name, order, COLOR_PANEL)
	legend.Text = Locale.T(key)
	return content
end

local render -- forward
local hold -- forward: (uid, square?) takes a pet in hand (Pets mode)
local renderBar -- forward
local submitPlacement -- forward

-- Card pages ---------------------------------------------------------------------------------------------------------------------

local function closeCard()
	selected, page, cardOpen = nil, "card", false
	renderBar()
	if not held then
		GardenView.ShowSelect(nil)
		GardenView.ShowReach(nil)
	end
	if card.Visible then
		local tween = TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 1, 400) })
		tween.Completed:Connect(function()
			if not cardOpen then
				card.Visible = false
				clearBody()
			end
		end)
		tween:Play()
	end
end

-- The strongest Tending (offline harvest chance) and Pest control (crow protection chance) reaching `square`, from the pet
-- sitting here or one nearby (only the strongest per job applies); 0 when none.
local function helpOf(square: number): (number, number)
	local open = openSet()
	local statePets = (fieldState and fieldState.pets) or {}
	local tend, guardChance = 0, 0
	for at, pet in plotPets() do
		if pet.apt > 0 and contains(CropConfig.Reach(at, PetConfig.ReachShape(pet.apt), open), square) then
			tend = math.max(tend, PetConfig.Strength(pet.apt))
		end
		local guard = statePets[tostring(at)] and statePets[tostring(at)].guard
		if pet.guard > 0 and type(guard) == "table" and contains(CropConfig.Reach(at, PetConfig.ReachShape(pet.guard), open), square) then
			guardChance = math.max(guardChance, guard.chance or 0)
		end
	end
	return tend, guardChance
end

-- Two permanent indicators on every open square's card: "🌱 Tending 68%" and "🛡 Pest control 84%" (the job names) (dim at 0 %).
local function helpIndicators(square: number, order: number, parent: Instance)
	local row = create("Frame", {
		Name = "Help", LayoutOrder = order, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Parent = parent,
	}, {
		create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, GAP) }),
	})
	local tend, guardChance = helpOf(square)
	for index, item in { { "Tend", "field.card.helpTend", tend }, { "Guard", "field.card.helpGuard", guardChance } } do
		local on = item[3] > 1e-6
		local chip = label(item[1], {
			LayoutOrder = index, Size = UDim2.new(0.5, -GAP / 2, 1, 0), BackgroundTransparency = 0, BackgroundColor3 = COLOR_ROW,
			TextSize = 15, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd,
			TextColor3 = if on then Color3.new(1, 1, 1) else COLOR_DIM, TextTransparency = if on then 0 else 0.3,
			Text = Locale.T(item[2], { pct = pct(item[3]) }), Parent = row,
		})
		create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = chip })
	end
end

-- Opens the Pets panel at `uid`'s page (details, feeding: PetsPanel's OpenPet attribute); the card closes.
local function openPetPage(uid: string)
	local petsGui = player.PlayerGui:FindFirstChild("PetsGui")
	if petsGui then
		closeCard()
		petsGui:SetAttribute("OpenPet", uid)
	end
end

-- the next square's price and the button (grey with the reason when it cannot be bought; Coins only since EV3b)
local function renderLocked(square: number)
	header(Locale.T("field.card.locked"), closeCard)
	local expansion = CropConfig.NextExpansion(#(fieldState.open or {}))
	if not expansion then
		return
	end
	paragraph("Price", 2, {
		Font = StudStyle.Font,
		TextSize = 18,
		TextColor3 = Color3.new(1, 1, 1),
		Text = Locale.T("field.card.price", { count = expansion.price }),
	}).Parent = body
	local lines = {}
	local coins = PetClient.Coins or 0
	if coins < expansion.price then
		table.insert(lines, Locale.T("common.needMoreCoins", { count = expansion.price - coins }))
	end
	if #lines > 0 then
		paragraph("Reason", 3, { RichText = true, Text = table.concat(lines, "\n") }).Parent = body
	end
	local can = #lines == 0
	buttonRow(9, {
		{
			name = "Buy",
			color = if can then COLOR_GO else COLOR_OFF,
			text = Locale.T("field.card.buy"),
			confirmKey = "Square" .. square,
			needsConfirm = function()
				return can and ConfirmTap.Over(expansion.price)
			end,
			action = function()
				if can then
					fire(buySquareEvent, square, #(fieldState.open or {}))
				end
			end,
		},
	})
end

local function renderCard()
	local square = selected :: number
	local open = openSet()
	if not open[square] then
		return renderLocked(square)
	end
	local entry = fieldState.squares and fieldState.squares[tostring(square)]
	local crop = entry and CropConfig.ById[entry.crop]
	local pet = (fieldState.pets or {})[tostring(square)]
	header(Locale.T("field.card.title"), closeCard)
	-- Crop group: empty → only Plant; growing → bar (share · time left) + dig-up trash, one hint; ripe → only Harvest.
	local cropGroup = groupBox("CropGroup", 2, "field.card.cropGroup")
	cardRipe = false
	if not crop then
		buttonRow(1, { { name = "Plant", color = COLOR_GO, text = Locale.T("field.card.plant"), action = function()
			page = "seeds"
			render()
		end } }, cropGroup)
	else
		paragraph("Title", 1, {
			Font = StudStyle.Font, TextSize = 18, TextColor3 = Color3.new(1, 1, 1),
			Text = GardenUi.CropTitle(crop) .. GardenUi.Stars(fieldState, crop),
		}).Parent = cropGroup
		local _, ripe = progress(entry, crop, workspace:GetServerTimeNow())
		cardRipe = ripe
		if ripe then
			buttonRow(2, { { name = "Harvest", color = COLOR_GO, text = Locale.T("field.card.harvest"), action = function()
				fire(harvestEvent, square)
			end } }, cropGroup)
		else
			local row = create("Frame", {
				Name = "Growing", LayoutOrder = 2, Size = UDim2.new(1, 0, 0, TRASH_SIZE), BackgroundTransparency = 1, Parent = cropGroup,
			}, {
				create("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, GAP),
				}),
			})
			bar(1, row, 36).Size = UDim2.new(1, -(TRASH_SIZE + GAP), 0, 36)
			-- dig up: a red trash brick, orange "OK?" on the first tap, gone on the second (ConfirmTap, as an egg's discard)
			local key = "Uproot" .. square .. entry.crop
			local armed = ConfirmTap.IsArmed(key)
			local trash = brick("Uproot", {
				LayoutOrder = 2, Size = UDim2.fromOffset(TRASH_SIZE, TRASH_SIZE), TextSize = 15,
				BackgroundColor3 = if armed then ConfirmTap.COLOR else COLOR_CLOSE,
				Text = if armed then Locale.T("field.card.uprootConfirm") else "",
				Parent = row,
			}, { compact = true })
			if not armed then
				GardenUi.TrashIcon(trash)
			end
			trash.Activated:Connect(function()
				if ConfirmTap.Tap(key, function()
					if cardOpen and selected == square and page == "card" then
						render()
					end
				end) then
					fire(uprootEvent, square)
				end
				render()
			end)
			paragraph("GrowthHint", 3, { TextSize = 14, Text = Locale.T("field.card.fasterOnline") }).Parent = cropGroup
		end
	end
	-- Pets group: the pet sitting here as one row (tap → its page) with a grey X brick (take it off the field), or Place pet;
	-- under it the two help indicators of this soil (always shown).
	local petsGroup = groupBox("PetsGroup", 3, "field.card.petsGroup")
	if pet then
		local row = create("Frame", {
			Name = "Resident", LayoutOrder = 1, Size = UDim2.new(1, 0, 0, PET_ROW_HEIGHT), BackgroundTransparency = 1, Parent = petsGroup,
		}, {
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, GAP),
			}),
		})
		local open = create("TextButton", {
			Name = "Open", LayoutOrder = 1, Size = UDim2.new(1, -(TRASH_SIZE + GAP), 1, 0), Text = "", AutoButtonColor = true,
			BackgroundColor3 = COLOR_ROW, BorderSizePixel = 0, Parent = row,
		}, {
			create("UICorner", { CornerRadius = UDim.new(0, 8) }),
		})
		local portrait = PetPortrait.Holder({
			Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(PET_ROW_HEIGHT - 8, PET_ROW_HEIGHT - 8),
			BackgroundColor3 = StudStyle.Shade(COLOR_ROW, 0.6),
		}, portraits(pet))
		portrait.Parent = open
		label("Name", {
			Position = UDim2.fromOffset(PET_ROW_HEIGHT + 4, 0), Size = UDim2.new(1, -(PET_ROW_HEIGHT + 30), 1, 0),
			Font = StudStyle.Font, TextSize = 17, TextTruncate = Enum.TextTruncate.AtEnd,
			Text = petName(pet.uid, pet.kind) .. "  " .. PlotView.JobIcons(pet.apt, pet.guard and pet.guard.level or 0),
			Parent = open,
		})
		label("Chevron", {
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.new(0, 16, 1, 0),
			Font = StudStyle.Font, TextSize = 24, TextColor3 = COLOR_DIM, Text = "›", TextXAlignment = Enum.TextXAlignment.Right,
			Parent = open,
		})
		open.Activated:Connect(function()
			openPetPage(pet.uid)
		end)
		local takeBack = brick("TakeBack", {
			LayoutOrder = 2, Size = UDim2.fromOffset(TRASH_SIZE, TRASH_SIZE), TextSize = 20, BackgroundColor3 = COLOR_OFF, Text = "X", Parent = row,
		}, { compact = true })
		takeBack.Activated:Connect(function()
			fire(liftPetEvent, pet.uid)
		end)
	else
		buttonRow(1, { { name = "PlacePet", color = COLOR_PET, text = Locale.T("field.card.placePet"), action = function()
			page = "pets"
			render()
		end } }, petsGroup)
	end
	helpIndicators(square, 2, petsGroup)
end

-- the scrolling list of a picker (rows of ROW_HEIGHT)
local function pickerList(order: number): ScrollingFrame
	return create("ScrollingFrame", {
		Name = "List",
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = body,
	}, { create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }) })
end

local function fitList(list: ScrollingFrame, rows: number)
	local camera = workspace.CurrentCamera
	local room = if camera then camera.ViewportSize.Y - CARD_BOTTOM - 140 else LIST_MAX
	list.Size = UDim2.new(1, 0, 0, math.max(ROW_HEIGHT, math.min(rows * (ROW_HEIGHT + 6), LIST_MAX, room)))
end

local function pickerRow(list: Instance, name: string, order: number, title: string, info: string, enabled: boolean, color: Color3): TextButton
	return create("TextButton", {
		Name = name,
		LayoutOrder = order,
		Size = UDim2.new(1, -8, 0, ROW_HEIGHT),
		BackgroundColor3 = StudStyle.Shade(if enabled then color else COLOR_OFF, 0.75),
		AutoButtonColor = enabled,
		Text = "",
		Parent = list,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 8) }),
		create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = if enabled then color else COLOR_OFF, Thickness = 2 }),
		label("Name", {
			Position = UDim2.fromOffset(12, 5),
			Size = UDim2.new(1, -24, 0, 24),
			TextSize = 18,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = title,
		}),
		label("Info", {
			Position = UDim2.fromOffset(12, 29),
			Size = UDim2.new(1, -24, 0, 18),
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextColor3 = COLOR_INFO,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = info,
		}),
	})
end

local function back()
	if placing then
		return
	end
	page = "card"
	GardenView.ShowReach(nil)
	render()
end

-- Seeds mode always has a seed selected: the one picked before while any is left, else the picker's first (renderBar)
local function preselectSeed()
	if not fieldState or (handSeed and seedsLeft(handSeed) > 0) then
		return
	end
	for _, crop in CropConfig.Crops do
		if seedsLeft(crop.id) > 0 then
			handSeed = crop.id
			return
		end
	end
end

-- the seed picker: the seeds held (count, grow time); without seeds a hint to the plaza's seed stall. With `square` nil it
-- picks the seed of the hand's Seeds mode and outlines the selected one in white.
local function renderSeeds(square: number?)
	header(if square then Locale.T("field.picker.title") else Locale.T("field.hand.pickSeed"), if square then back else closeCard)
	paragraph("GrowthHint", 2, { TextSize = 13, Text = GardenUi.GrowthHint(fieldState) }).Parent = body
	local list = pickerList(3)
	local rows = 0
	for _, crop in CropConfig.Crops do
		local stock = (fieldState.seeds or {})[crop.id] or 0
		if stock > 0 then
			rows += 1
			local seconds = GardenUi.GrowSecondsOn(fieldState, crop)
			local row = pickerRow(list, crop.id, rows, GardenUi.CropTitle(crop) .. GardenUi.Stars(fieldState, crop), Locale.T("field.picker.info", { stock = stock, time = TimeFormat.GrowTime(seconds) }), true, COLOR_GO)
			if not square and crop.id == handSeed then
				local outline = row:FindFirstChildOfClass("UIStroke") :: UIStroke
				outline.Color, outline.Thickness = Color3.new(1, 1, 1), 3
			end
			row.Activated:Connect(function()
				if square then
					fire(plantEvent, square, crop.id)
					page = "card"
					render()
				else
					handSeed = crop.id
					closeCard()
					renderBar()
				end
			end)
		end
	end
	if rows > 0 then
		fitList(list, rows)
		return
	end
	list:Destroy()
	paragraph("None", 2, { Text = Locale.T("field.picker.none") }).Parent = body -- U4: seeds are sold at the plaza's seed stall
end

-- the pet picker: pets with Tending or Pest control (job levels, squares they would work here); hovering a row tints its reach
local function renderPets()
	local square = selected :: number
	header(Locale.T("field.petPicker.title"), back)
	local used = 0
	for _ in (fieldState.pets or {}) do
		used += 1
	end
	local slotLine = GardenUi.FieldSlots(fieldState, PetClient.Coins or 0, PET_ACTION_HEIGHT, function(slot)
		fire(remotes:WaitForChild("BuyPetSlot") :: RemoteEvent, slot)
	end)
	slotLine.LayoutOrder = 2
	slotLine.Size = UDim2.new(1, -8, 0, PET_ACTION_HEIGHT)
	slotLine.Parent = body
	-- a tap on a blocked pet (no free slot) points at the cure: the slot box and the "+1 slot" brick pulse for a moment
	local pulses = {}
	for _, name in { "Pips", "Buy" } do
		local target = slotLine:FindFirstChild(name, true)
		if target then
			table.insert(pulses, UiKit.Pulse(target :: GuiObject, 1.1, 0.25))
		end
	end
	local pulseToken = 0
	local function pointAtSlots()
		pulseToken += 1
		local token = pulseToken
		for _, pulse in pulses do
			pulse(true)
		end
		task.delay(1, function()
			if token == pulseToken then
				for _, pulse in pulses do
					pulse(false)
				end
			end
		end)
	end
	local candidates = {}
	for _, pet in PetClient.Inventory() do
		if pet.tending > 0 or pet.guard > 0 then
			table.insert(candidates, pet)
		end
	end
	table.sort(candidates, function(a, b)
		local aCan = a.field ~= nil or used < (fieldState.slots or 1)
		local bCan = b.field ~= nil or used < (fieldState.slots or 1)
		if aCan ~= bCan then
			return aCan
		end
		-- rarest first (the Pets list's order): a rare pet that is still low is easy to find
		if a.rarity.order ~= b.rarity.order then
			return a.rarity.order > b.rarity.order
		end
		if a.tending ~= b.tending then
			return a.tending > b.tending
		end
		if a.guard ~= b.guard then
			return a.guard > b.guard
		end
		return (tonumber(a.uid) or 0) < (tonumber(b.uid) or 0)
	end)
	if #candidates == 0 then
		paragraph("None", 4, { Text = Locale.T("field.petPicker.none") }).Parent = body
		return
	end
	-- Let Body scroll the complete picker; nested scrolling would trap the action below the capacity text on phones.
	local list = UiKit.Section("List", 4, 6)
	list.Parent = body
	local wide = card.Size.X.Offset >= 440
	for index, pet in candidates do
		local reach = reachOf(square, math.max(pet.tending, pet.guard))
		local hasSlot = pet.field ~= nil or used < (fieldState.slots or 1)
		local enabled = hasSlot and not placing
		local effects = {}
		if pet.tending > 0 then
			table.insert(effects, Locale.T("field.petPicker.info", { level = pet.tending, count = #reachOf(square, pet.tending) }))
		end
		if pet.guard > 0 then
			table.insert(effects, Locale.T("field.petPicker.guard", { level = pet.guard, count = #reachOf(square, pet.guard) }))
		end
		-- name and job icons in the rarity colour (rarity is told by colour only), then where the pet is now in brackets; a resting
		-- pet (the default) says nothing. The name is the player's: escaped for RichText.
		local title = richEscape(petName(pet.uid, pet.kind)) .. "  " .. PlotView.JobIcons(pet.tending, pet.guard)
		local where = if pet.field then "field.petPicker.fromField" elseif pet.equipped then "field.petPicker.fromEquipped" else nil
		if where then
			title ..= string.format("  <font color='#%s'>%s</font>", COLOR_INFO:ToHex(), Locale.T(where))
		end
		-- One inset contains the entire pet and its action, so the button cannot read as the next pet's heading.
		local row = GardenUi.Row(list, "Pet_" .. pet.uid, index, COLOR_ROW)
		row.Size = UDim2.new(1, -8, 0, 0)
		row.UIListLayout.FillDirection = if wide then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical
		row.UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = COLOR_GROUP_BORDER, Thickness = 1, Parent = row })
		local identity = create("Frame", {
			Name = "Identity", LayoutOrder = 1, Size = UDim2.new(1, if wide then -PET_ACTION_WIDTH - GardenUi.GAP else 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = row,
		}, { create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, GardenUi.GAP), VerticalAlignment = Enum.VerticalAlignment.Top,
		}) })
		local holder = PetPortrait.Holder({ LayoutOrder = 1, Size = UDim2.fromOffset(44, 44), BackgroundColor3 = StudStyle.Shade(COLOR_ROW, 0.6) }, portraits(pet))
		create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = pet.rarity.color, Thickness = 2, Parent = holder })
		holder.Parent = identity
		local description = GardenUi.TextColumn(identity, 44 + GardenUi.GAP, title)
		description.LayoutOrder = 2
		local nameLabel = description:FindFirstChild("Name") :: TextLabel
		nameLabel.TextColor3 = pet.rarity.color
		nameLabel.RichText = true
		local effectsLabel = paragraph("Effects", 2, { TextSize = 13, Text = table.concat(effects, " · ") })
		effectsLabel.Parent = description
		-- no free slot: the row is dimmed and its brick carries the locked slot's 🔒 (no message; a tap pulses the slot box)
		local buttonText = Locale.T(if placing and placing.uid == pet.uid then "field.hand.placing" else "field.card.placePet")
		if not hasSlot then
			local portrait = holder:FindFirstChild("Portrait")
			if portrait then
				(portrait :: ViewportFrame).ImageTransparency = BLOCKED_FADE
			end
			(holder:FindFirstChildOfClass("UIStroke") :: UIStroke).Transparency = BLOCKED_FADE
			nameLabel.TextTransparency = BLOCKED_FADE
			effectsLabel.TextTransparency = BLOCKED_FADE
			buttonText = "🔒 " .. buttonText
		end
		local action = brick("PlacePet", { LayoutOrder = 2, Size = if wide then UDim2.fromOffset(PET_ACTION_WIDTH, PET_ACTION_HEIGHT) else UDim2.new(1, 0, 0, PET_ACTION_HEIGHT), BackgroundColor3 = if enabled then COLOR_PET else COLOR_OFF, TextSize = 15,
			Text = buttonText, Active = enabled or not hasSlot, AutoButtonColor = enabled, Parent = row }, { compact = true })
		row.MouseEnter:Connect(function()
			GardenView.ShowReach(reach)
		end)
		row.MouseLeave:Connect(function()
			GardenView.ShowReach(nil)
		end)
		if enabled then
			action.Activated:Connect(function()
				submitPlacement(square, pet.uid, true)
			end)
		elseif not hasSlot then
			action.Activated:Connect(pointAtSlots)
		end
	end
end

function render()
	if not (cardOpen and fieldState) or (page ~= "handSeeds" and not selected) then
		return
	end
	clearBody()
	card.Size = UDim2.fromOffset(cardWidth(), card.Size.Y.Offset)
	if page == "seeds" or page == "handSeeds" then
		renderSeeds(if page == "seeds" then selected else nil)
	elseif page == "pets" then
		renderPets()
	else
		renderCard()
		local entry = fieldState.squares and fieldState.squares[tostring(selected)]
		local crop = entry and CropConfig.ById[entry.crop]
		if crop and barFill and barText then
			local share, ripe, left = progress(entry, crop, workspace:GetServerTimeNow())
			UiKit.SetShare(barFill, share)
			barText.Text = growingText(share, left)
		end
	end
	fitCard()
end

-- Selection and taps -------------------------------------------------------------------------------------------------------------

local function showCard()
	cardOpen = true
	render()
	renderBar()
	if not card.Visible then
		card.Visible = true
		card.Position = UDim2.new(0.5, 0, 1, 400)
	end
	TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 1, -CARD_BOTTOM) }):Play()
end

local function select(square: number, toPage: string?)
	selected, page = square, toPage or "card"
	GardenView.ShowSelect(square)
	showCard()
end

-- the card as the hand's seed picker (no square selected)
local function openSeedPicker()
	selected, page = nil, "handSeeds"
	if not held then
		GardenView.ShowSelect(nil)
	end
	showCard()
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

-- Active panels in any ScreenGui, including passive labels inside them, block world input.
local function overUi(point: Vector2): boolean
	return UiKit.BlocksWorld(player.PlayerGui, point)
end

-- The own square under screen point `point` (InputObject / TouchTapInWorld coordinates), or nil.
local function squareUnder(point: Vector2): number?
	if overUi(point) then
		return nil
	end
	local camera = workspace.CurrentCamera
	local plot = GardenConfig.PlotOf(player)
	local root = GardenView.OwnRoot()
	if not (camera and plot) then
		return nil
	end
	local ray = camera:ScreenPointToRay(point.X, point.Y)
	if root then
		rayParams.FilterDescendantsInstances = { root }
		local hit = workspace:Raycast(ray.Origin, ray.Direction * RAY_LENGTH, rayParams)
		if hit then
			-- a part of a square's piece (soil, crop, pet, tufts) names its square; anything else maps by position
			local node: Instance? = hit.Instance
			while node and node ~= root do
				local number = string.match(node.Name, "^sq(%d+)$")
				if number and node:IsA("Model") then
					return tonumber(number)
				end
				node = node.Parent
			end
			return GardenView.SquareAt(hit.Position)
		end
	end
	-- nothing drawn under the point: the field's plane (the soil's top)
	local height = plot.Position.Y + 0.25
	if ray.Direction.Y >= -1e-3 then
		return nil
	end
	local t = (height - ray.Origin.Y) / ray.Direction.Y
	if t <= 0 or t > RAY_LENGTH then
		return nil
	end
	return GardenView.SquareAt(ray.Origin + ray.Direction * t)
end

-- Hand bar (U3b) -----------------------------------------------------------------------------------------------------------------

local MODES = { "seeds", "basket", "pets", "look" }
local MODE_KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four } -- in MODES order
local MODE_NAMES = { seeds = "Seeds", basket = "Basket", pets = "Pets", look = "Look" }
local MODE_ICONS = { seeds = "🌱", basket = "🧺", pets = "🐾", look = "✋" }
local MODE_COLORS = { seeds = COLOR_GO, basket = Color3.fromRGB(205, 140, 60), pets = COLOR_PET, look = COLOR_OFF }

handBar = create("Frame", {
	Name = "HandBar",
	Active = true,
	AnchorPoint = Vector2.new(1, 1),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = screenGui,
})
local handHint = label("Hint", {
	-- a fixed two-line box (AutomaticSize did not grow it to the wrapped height), its text at the bottom, over the bar
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, 0, 0, -HINT_GAP),
	Size = UDim2.fromOffset(300, 40),
	TextSize = 16,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Right,
	TextYAlignment = Enum.TextYAlignment.Bottom,
	TextStrokeTransparency = 0.2,
	Text = "",
	Visible = false,
	Parent = handBar,
})
local placementStrip = create("Frame", {
	Name = "Placement",
	Active = true,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, 0, 0, -HINT_GAP),
	Size = UDim2.fromOffset(400, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	Visible = false,
	Parent = screenGui,
})
StudStyle.Panel(placementStrip, COLOR_PANEL)
local placementText = label("Hint", {
	Position = UDim2.fromOffset(10, 8),
	Size = UDim2.new(1, -120, 0, 44),
	Font = Enum.Font.Gotham,
	TextSize = 16,
	TextColor3 = COLOR_INFO,
	TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Top,
	Text = "",
	Parent = placementStrip,
})
local function fitPlacementText()
	local bounds = TextService:GetTextSize(placementText.Text, placementText.TextSize, placementText.Font, Vector2.new(math.max(1, placementText.AbsoluteSize.X), 10000))
	placementText.Size = UDim2.new(1, -120, 0, math.max(44, bounds.Y + 4))
end
placementText:GetPropertyChangedSignal("Text"):Connect(fitPlacementText)
placementText:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitPlacementText)
create("UIPadding", { PaddingBottom = UDim.new(0, 8), Parent = placementStrip })
local cancelPlacement = brick("Cancel", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -8, 0, 8),
	Size = UDim2.fromOffset(96, 44),
	TextSize = 16,
	BackgroundColor3 = COLOR_OFF,
	Text = "",
	Parent = placementStrip,
}, 2)
local handButtons: { [string]: TextButton } = {}
local pulses: { [string]: (boolean) -> () } = {} -- UiKit.Pulse setters of the hand buttons
local seedCount: TextLabel

local function touchLayout(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- the jump button's top right corner on a touch screen (its real place if drawn, else Roblox's layout for this screen size)
local function jumpCorner(viewport: Vector2): Vector2
	local touchGui = player.PlayerGui:FindFirstChild("TouchGui")
	local jump = touchGui and touchGui:FindFirstChild("JumpButton", true)
	if jump and jump:IsA("GuiObject") and jump.AbsoluteSize.X > 0 then
		return Vector2.new(jump.AbsolutePosition.X + jump.AbsoluteSize.X, jump.AbsolutePosition.Y)
	end
	if math.min(viewport.X, viewport.Y) <= 500 then
		return Vector2.new(viewport.X - 25, viewport.Y - 90)
	end
	return Vector2.new(viewport.X - 50, viewport.Y - 210)
end

local function layoutBar()
	local camera = workspace.CurrentCamera
	local viewport = if camera then camera.ViewportSize else Vector2.new(800, 600)
	local step = HAND_BUTTON + HAND_GAP
	local touch = touchLayout()
	placementStrip.Size = UDim2.fromOffset(math.min(400, viewport.X - 24), 0)
	if touch then
		local corner = jumpCorner(viewport)
		handBar.Size = UDim2.fromOffset(2 * HAND_BUTTON + HAND_GAP, 2 * HAND_BUTTON + HAND_GAP + HAND_RAISE)
		handBar.Position = UDim2.fromOffset(corner.X, corner.Y - 10)
	else
		handBar.Size = UDim2.fromOffset(4 * HAND_BUTTON + 3 * HAND_GAP, HAND_BUTTON + HAND_RAISE)
		handBar.Position = UDim2.new(1, -12, 1, -12)
	end
	for index, name in MODES do
		local button = handButtons[name]
		local col, row = if touch then (index - 1) % 2 else index - 1, if touch then (index - 1) // 2 else 0
		button.Position = UDim2.fromOffset(col * step, HAND_RAISE + row * step - (if name == mode then HAND_RAISE else 0))
	end
	if touch then
		-- Above the bottom HUD, beside the hand bar: the top-right stage HUD must not cover Cancel.
		placementStrip.AnchorPoint = Vector2.new(0.5, 1)
		placementStrip.Position = UDim2.new(0.5, 0, 1, -CARD_BOTTOM)
		placementStrip.Size = UDim2.fromOffset(cardWidth(), 0)
	else
		placementStrip.AnchorPoint = Vector2.new(1, 1)
		placementStrip.Position = UDim2.fromOffset(handBar.AbsolutePosition.X + handBar.AbsoluteSize.X, handBar.AbsolutePosition.Y - HINT_GAP)
	end
	if cardOpen then
		card.Size = UDim2.fromOffset(cardWidth(), card.Size.Y.Offset)
		fitCard()
	end
end

for index, name in MODES do
	local button = create("TextButton", {
		Name = MODE_NAMES[name],
		LayoutOrder = index,
		Size = UDim2.fromOffset(HAND_BUTTON, HAND_BUTTON),
		BackgroundColor3 = MODE_COLORS[name],
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 26,
		Font = Enum.Font.GothamBold,
		Text = MODE_ICONS[name],
		Parent = handBar,
	})
	StudStyle.Brick(button, { studs = 1, socket = true })
	button:SetAttribute("UiSound", "Tab") -- switching the hand is a tab switch (UiSoundsClient)
	-- the active mode's frame (a separate frame: the brick's own stroke is its face's)
	create("Frame", {
		Name = "Active",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 6, 1, 6),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 3,
		Parent = button,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 9) }),
		create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 3 }),
	})
	pulses[name] = UiKit.Pulse(button, 1.15, 0.45)
	handButtons[name] = button
end
seedCount = label("Count", {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -2, 1, -3),
	Size = UDim2.fromOffset(40, 16),
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Right,
	TextStrokeTransparency = 0,
	ZIndex = 5,
	Text = "",
	Parent = handButtons.seeds,
})

local function setPulse(name: string, on: boolean)
	pulses[name](on)
end

-- the next step (G1 style): Seeds while nothing is planted and seeds are held, Basket while something is ripe
local function updatePulse()
	local planted, ripe, seeds = false, false, false
	if fieldState and handBar.Visible then
		for _, entry in fieldState.squares or {} do
			planted = true
			ripe = ripe or ripeEntry(entry)
		end
		for _, count in fieldState.seeds or {} do
			seeds = seeds or count > 0
		end
	end
	-- E5c: the onboarding steps planting, harvesting and placing the first pet pulse their button until done
	setPulse("seeds", mode ~= "seeds" and seeds and ((not used.seeds and not planted) or Onboarding.Is("plant")))
	setPulse("basket", mode ~= "basket" and ripe and (not used.basket or Onboarding.Is("harvest")))
	setPulse("pets", mode ~= "pets" and held == nil and handBar.Visible and Onboarding.Is("placePet"))
end
Onboarding.Changed:Connect(updatePulse)

function renderBar()
	for _, name in MODES do
		(handButtons[name]:FindFirstChild("Active") :: Frame).Visible = name == mode
	end
	layoutBar()
	if mode == "seeds" then
		preselectSeed() -- on entering the mode, and as soon as the selected one runs out
	end
	local crop = handSeed and CropConfig.ById[handSeed]
	handButtons.seeds.Text = if crop then crop.icon else MODE_ICONS.seeds
	seedCount.Text = if crop then Locale.Number(seedsLeft(crop.id)) else ""
	local text = ""
	if held then
		local owned = PetClient.State and PetClient.State.pets[held]
		local name = if owned then petName(held, owned.Kind) else ""
		text = if placing then Locale.T("field.hand.placing") elseif placementHint then placementHint elseif preview then Locale.T("field.hand.dropAgain", { pet = name }) else Locale.T(if heldFrom then "field.card.moving" else "field.hand.place", { pet = name })
		if owned and PetClient.State and table.find(PetClient.State.equipped, held) and not placing then
			text ..= "\n" .. Locale.T("field.petPicker.equipped")
		end
	elseif mode == "seeds" and crop then
		text = Locale.T("field.hand.seeds", { crop = GardenUi.CropTitle(crop) })
	elseif mode == "basket" then
		text = Locale.T("field.hand.basket")
	elseif mode == "pets" then
		text = Locale.T("field.hand.pets")
	elseif mode == "look" and not tappedSquare then
		text = Locale.T("field.hand.look")
	end
	handHint.Text = text
	handHint.Visible = text ~= "" and not held and not cardOpen
	placementStrip.Visible = held ~= nil and handBar.Visible
	placementText.Text = text
	cancelPlacement.Visible = placing == nil
	cancelPlacement.Text = Locale.T("field.hand.cancel")
	updatePulse()
end

local function showHeldReach(square: number?)
	if held and square then
		GardenView.ShowReach(reachOf(square, heldLevel()))
	else
		GardenView.ShowReach(nil)
	end
end

local function cancelHold(restore: boolean?)
	if placing then
		return
	end
	local source = heldCard
	held, heldFrom, preview, hoverSquare = nil, nil, nil, nil
	heldCard, placementHint = nil, nil
	mode = "look"
	GardenView.ShowReach(nil)
	if not cardOpen then
		GardenView.ShowSelect(nil)
	end
	renderBar()
	if restore and source and inRange() then
		select(source)
	end
end
cancelPlacement.Activated:Connect(function()
	cancelHold(true)
end)

local function setMode(name: string)
	if placing then
		return
	end
	if held then
		cancelHold()
	end
	mode = name
	if name ~= "look" then
		used[name] = true
	end
	if cardOpen and page == "handSeeds" and name ~= "seeds" then
		closeCard()
	end
	renderBar()
end

function hold(uid: string, square: number?)
	if placing then
		return
	end
	local source = if cardOpen then selected else nil
	if mode ~= "pets" then
		setMode("pets")
	end
	closeCard()
	held, heldFrom, preview, hoverSquare = uid, square, nil, nil
	heldCard, placementHint = source, nil
	GardenView.ShowSelect(square)
	showHeldReach(square)
	renderBar()
end

function submitPlacement(square: number, uid: string, picker: boolean?)
	if placing then
		return
	end
	placing = { uid = uid, square = square, picker = picker == true }
	fire(placePetEvent, square, uid)
	if cardOpen then
		render()
	end
	renderBar()
end

local function drop(square: number)
	submitPlacement(square, held)
end

-- what a hand bar brick does, on a click / tap or on its number key
local handActions: { [string]: () -> () } = {
	seeds = function()
		setMode("seeds")
		openSeedPicker()
	end,
	basket = function()
		setMode(if mode == "basket" then "look" else "basket")
	end,
	pets = function()
		if held then
			cancelHold(true)
		else
			setMode(if mode == "pets" then "look" else "pets")
		end
	end,
	look = function()
		setMode("look")
	end,
}
for name, action in handActions do
	handButtons[name].Activated:Connect(action)
end

-- Taps -------------------------------------------------------------------------------------------------------------------------

-- a tap in a hand mode on an open square; true when the mode handled it (else the tap selects as in Look)
local function handTap(square: number, touch: boolean): boolean
	local key = tostring(square)
	local entry = fieldState.squares and fieldState.squares[key]
	local petAt = (fieldState.pets or {})[key]
	if mode == "seeds" and not entry then
		if pendingPlant[square] and pendingPlant[square].untilClock > os.clock() then
			return true -- already on its way
		end
		if not handSeed or seedsLeft(handSeed) <= 0 then
			openSeedPicker()
			return true
		end
		closeCard()
		pendingPlant[square] = { crop = handSeed :: string, untilClock = os.clock() + PENDING_SECONDS }
		fire(plantEvent, square, handSeed)
		renderBar()
		return true
	elseif mode == "basket" and entry and ripeEntry(entry) then
		if (pendingHarvest[square] or 0) < os.clock() then
			closeCard()
			pendingHarvest[square] = os.clock() + PENDING_SECONDS
			fire(harvestEvent, square)
		end
		return true
	elseif mode == "pets" then
		if held then
			if petAt and petAt.uid == held then
				cancelHold(true)
			elseif petAt then
				placementHint = Locale.T("field.reason.petOccupied")
				renderBar()
			elseif touch and preview ~= square then
				placementHint = nil
				preview = square -- touch: the first tap shows where it would work
				GardenView.ShowSelect(square)
				showHeldReach(square)
				renderBar()
			else
				drop(square)
			end
		elseif petAt then
			hold(petAt.uid, square)
		else
			select(square, "pets")
		end
		return true
	end
	return false
end

local function onTap(point: Vector2, touch: boolean)
	if overUi(point) or placing or not (fieldState and inRange()) then
		return
	end
	local square = squareUnder(point)
	if square and not tappedSquare then
		tappedSquare = true
		renderBar()
	end
	if square and openSet()[square] and handTap(square, touch) then
		return
	end
	if not square or (square == selected and page == "card") then
		closeCard()
		return
	end
	select(square)
end

UserInputService.TouchTapInWorld:Connect(function(position: Vector2, processedByUI: boolean)
	if not processedByUI then
		onTap(position, true)
	end
end)

local pressAt: Vector2? = nil
local pressClock = 0
local mouseAt: Vector2? = nil -- the mouse (InputObject coordinates) for the held pet's reach
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.Escape and held and not UserInputService:GetFocusedTextBox() and not PanelFocus.Current() then
		cancelHold(true)
	end
	local brickName = MODES[table.find(MODE_KEYS, input.KeyCode) or 0]
	if brickName and handBar.Visible and not gameProcessed and not UserInputService:GetFocusedTextBox() and not PanelFocus.Current() then
		UiSounds.Play("Tab") -- as the brick's own click
		handActions[brickName]()
	end
	if input.UserInputType == Enum.UserInputType.Touch then
		mouseAt = nil -- a touch screen: no hover, the brackets follow the character
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		pressAt = nil
		local point = Vector2.new(input.Position.X, input.Position.Y)
		if not gameProcessed and not overUi(point) then
			pressAt = point
			pressClock = os.clock()
		end
	end
end)
UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 or not pressAt then
		return
	end
	local point = Vector2.new(input.Position.X, input.Position.Y)
	local start = pressAt
	pressAt = nil
	if not gameProcessed and (point - start).Magnitude <= TAP_PIXELS and os.clock() - pressClock <= TAP_SECONDS then
		onTap(point, false)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		mouseAt = Vector2.new(input.Position.X, input.Position.Y)
	end
end)

-- Harvest pop ------------------------------------------------------------------------------------------------------------------

local function pop(square: number, crop, size: number?)
	local cframe = GardenView.SquareCFrame(square)
	if not cframe then
		return
	end
	PlantGrowth.PlayHarvest(crop.id, workspace, cframe, size)
	local anchor = create("Part", {
		Name = "HarvestPop",
		Anchored = true,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		Transparency = 1,
		Size = Vector3.new(0.2, 0.2, 0.2),
		CFrame = cframe + Vector3.new(0, 2, 0),
	})
	local text = Locale.T("field.hand.pop", { count = 1, icon = crop.icon })
	local field = GardenView.OwnField()
	local tag = size and CropConfig.SizeLabel(size, field and GardenUi.PointsOf(field, crop))
	if tag then
		text ..= " " .. Locale.T(if tag == "Giant" then "field.size.giant" else "field.size.big")
	end
	local gui = create("BillboardGui", {
		Size = UDim2.fromOffset(220, 40),
		StudsOffset = Vector3.new(0, 0, 3), -- toward the camera, as the rings
		LightInfluence = 0,
		AutoLocalize = false,
		Parent = anchor,
	})
	local textLabel = label("Text", {
		Size = UDim2.fromScale(1, 1),
		TextSize = 28,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.2,
		Text = text,
		Parent = gui,
	})
	anchor.Parent = workspace
	local info = TweenInfo.new(POP_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(anchor, info, { CFrame = anchor.CFrame + Vector3.new(0, 3, 0) }):Play()
	TweenService:Create(textLabel, TweenInfo.new(POP_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(POP_SECONDS + 0.1, function()
		anchor:Destroy()
	end)
end

-- Events -------------------------------------------------------------------------------------------------------------------------

remotes:WaitForChild("State").OnClientEvent:Connect(function(state)
	fieldState = if type(state) == "table" then state.field else nil
	receivedAt = workspace:GetServerTimeNow()
	if fieldState then
		for square in pendingPlant do
			if fieldState.squares and fieldState.squares[tostring(square)] then
				pendingPlant[square] = nil -- planted: the seeds held count it now
			end
		end
	end
	if cardOpen and not fieldState then
		closeCard()
	elseif cardOpen then
		render()
	end
	renderBar()
end)

remotes:WaitForChild("Result").OnClientEvent:Connect(function(action, ok, detail)
	if action == "Plant" and not ok then
		table.clear(pendingPlant) -- a refused planting: count from the State again
		renderBar()
	end
	if action == "Harvest" and ok and type(detail) == "table" and type(detail.square) == "number" then
		local crop = CropConfig.ById[detail.crop]
		if crop then
			pop(detail.square, crop, detail.size)
		end
	end
	if action ~= "PlacePet" then
		return
	end
	local request = placing
	placing = nil
	if request then
		if ok then
			if held then
				cancelHold()
			elseif cardOpen and selected == request.square and page == "pets" then
				page = "card"
			end
		elseif held then
			placementHint = Locale.Reject(detail, {
				occupied = "field.reason.petOccupied", slots = "field.petPicker.noSlot",
				aptitude = "field.reason.aptitude", far = "field.reason.far", square = "field.reason.square",
			})
			if not inRange() then
				cancelHold()
			end
		end
		if cardOpen then
			render()
		end
		renderBar()
	end
	if not ok or type(detail) ~= "table" then
		return
	end
	-- the placed pet's reach, for a moment
	local pet = PetClient.State and PetClient.State.pets[detail.uid]
	if pet then
		GardenView.ShowReach(reachOf(detail.square, math.max(PetConfig.AptitudeLevel(pet, "Tending"), PetConfig.AptitudeLevel(pet, "PestControl"))))
		reachTimer.After(REACH_SECONDS, function()
			if not held and page ~= "pets" then
				GardenView.ShowReach(nil)
			end
		end)
	end
end)

PetClient.Changed:Connect(function()
	if cardOpen then
		render() -- Coins (Buy square), pets equipped / hatched / renamed
	end
	if held and not (PetClient.State and PetClient.State.pets[held]) then
		cancelHold() -- sold
	end
end)

Locale.Changed:Connect(function()
	if cardOpen then
		render()
	end
	renderBar()
end)

screenGui:GetAttributeChangedSignal("Select"):Connect(function()
	local square = screenGui:GetAttribute("Select")
	if type(square) == "number" then
		screenGui:SetAttribute("Select", nil)
		if fieldState then
			select(square)
		end
	end
end)

-- HoldPet = uid (the pet page's "Place on field"): that pet in hand, Pets mode
screenGui:GetAttributeChangedSignal("HoldPet"):Connect(function()
	local uid = screenGui:GetAttribute("HoldPet")
	if type(uid) ~= "string" then
		return
	end
	screenGui:SetAttribute("HoldPet", nil)
	if not (fieldState and handBar.Visible and PetClient.State and PetClient.State.pets[uid]) then
		return
	end
	local from = nil
	for key, entry in fieldState.pets or {} do
		if type(entry) == "table" and entry.uid == uid then
			from = tonumber(key)
		end
	end
	hold(uid, from)
end)

local function resize()
	layoutBar()
	if cardOpen then
		render() -- pet rows reflow between side-by-side and stacked actions with the available width
	end
end
local function watchCamera()
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
	end
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()

-- the corner brackets on the own square under the mouse, else under the character (not the selected one or the held pet's
-- square / preview); a pointing-hand cursor while the mouse is over an own square
local pointing = false
local function updateStanding()
	local want = nil
	local overSquare = false
	local byMouse = false
	if handBar.Visible then
		local square = if mouseAt then squareUnder(mouseAt) else nil
		overSquare = square ~= nil
		byMouse = overSquare
		if not square then
			local at = rootPosition()
			square = at and GardenView.SquareAt(at)
		end
		if square and square ~= selected and square ~= heldFrom and square ~= preview then
			want = square
		end
	end
	if overSquare ~= pointing then
		pointing = overSquare
		UserInputService.MouseIcon = if pointing then POINTER else ""
	end
	if want ~= standing then
		standing = want
		GardenView.ShowHover(want)
		if want and byMouse then
			UiSounds.Play("Hover") -- the mouse moved onto another square; not while walking over squares
		end
	end
end

-- Every frame: the next queued remote (FIRE_GAP apart), the square under the character and, with a pet in hand, its reach
-- under the mouse
local lastMouse: Vector2? = nil
RunService.Heartbeat:Connect(function()
	updateStanding()
	if #queue > 0 and os.clock() - lastFire >= FIRE_GAP then
		lastFire = os.clock()
		local item = table.remove(queue, 1)
		item[1]:FireServer(table.unpack(item[2], 1, item[2].n))
	end
	if held and mouseAt and mouseAt ~= lastMouse and fieldState and not preview then
		lastMouse = mouseAt
		local square = squareUnder(mouseAt)
		if square ~= hoverSquare then
			hoverSquare = square
				placementHint = nil
				renderBar()
			local free = square and openSet()[square] and not (fieldState.pets or {})[tostring(square)]
			showHeldReach(if free then square else heldFrom)
		end
	end
end)

-- Every TICK_SECONDS: the bar shows in range (leaving it resets to Look); the card closes out of range; the bar and its time
-- follow the server time
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < TICK_SECONDS then
		return
	end
	elapsed = 0
	local shown = fieldState ~= nil and inRange()
	if shown ~= handBar.Visible then
		handBar.Visible = shown
		screenGui:SetAttribute("HandShown", shown)
		if not shown then
			if held then
				cancelHold()
			end
			mode = "look"
		end
		renderBar()
	elseif shown then
		updatePulse()
	end
	if shown then
		layoutBar() -- touch controls can finish laying out after the camera / device resize
	end
	if not cardOpen then
		return
	end
	if not inRange() then
		closeCard()
		return
	end
	if not selected then
		return
	end
	local entry = fieldState and fieldState.squares and fieldState.squares[tostring(selected)]
	local crop = entry and CropConfig.ById[entry.crop]
	if crop and barFill and barText then
		local share, ripe, left = progress(entry, crop, workspace:GetServerTimeNow())
		if ripe ~= cardRipe and page == "card" then
			render() -- it ripened while the card was open: the Harvest button appears
			return
		end
		UiKit.SetShare(barFill, share)
		barText.Text = growingText(share, left)
	end
end)

screenGui:SetAttribute("HandShown", false)
screenGui.Parent = player:WaitForChild("PlayerGui")
-- the State may have arrived before this script connected (GardenView keeps the last one)
if not fieldState and GardenView.OwnField() then
	fieldState = GardenView.OwnField()
	receivedAt = workspace:GetServerTimeNow()
end
renderBar()
