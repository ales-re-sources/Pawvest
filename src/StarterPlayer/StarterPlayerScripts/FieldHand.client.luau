-- FieldHand (U3a, docs/GDD.md §7.9): acting on the own field by tapping a square, no prompts.
--   * tap (TouchTapInWorld) / click (left button pressed and released within TAP_SECONDS and TAP_PIXELS, not over a GUI) while
--     the character is within TAP_DISTANCE (horizontal) of the own plot centre: a ray against the own plot's view (GardenView)
--     or the field's plane picks a square; it gets a white outline and the square card slides up at the bottom. Tapping the
--     selected square again, or off the field, closes the card; so does walking away;
--   * square card: crop icon and name (or empty / overgrown), a progress bar with the time left (ripe: full, "Ripe!"), the
--     growth boosts that apply (Growth upgrade, Cloches), a row per field pet whose reach covers the square (portrait, job icons,
--     what it does there; a tap opens its pet page through PetsGui's OpenPet attribute) and the context buttons: Plant (seed
--     picker), Harvest, Place pet (pet picker), Move pet (the next tap on a free square places it there), Take back, Buy square
--     (price and Renown of the next square; over CONFIRM_PRICE Coins a second tap within CONFIRM_SECONDS confirms);
--   * a placed pet's reach is tinted for REACH_SECONDS (GardenView.ShowReach), as is the reach of a row hovered in the pet picker.
-- Display only: the remotes carry a square number (and a crop id / pet uid); GardenField checks plot, distance, square, seeds,
-- Renown and Coins and answers on GardenRemotes.Result (FieldClient shows the toasts). Times: workspace:GetServerTimeNow().
-- The GUI is built here (ScreenGui FieldHandGui; stud bricks, StudStyle). Card width: at most CARD_WIDTH, and on a touch screen
-- clear of the thumbstick and the jump button (TOUCH_SIDE on each side); it sits above FieldClient's Field button.
-- Test hook (FieldHandGui attribute, cleared after use): Select = square selects it as a tap would (display checks).
-- Buttons by path: FieldHandGui.Card.Body.Buttons.<Plant|Harvest|PlacePet|MovePet|TakeBack|Buy|Cancel>, .Header.Close,
-- .Body.Pets.Pet_<uid>, .Body.List.<CropId> (seed picker) / .Body.List.Pet_<uid> (pet picker), .Body.List.Shop.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))
local GardenView = require(script.Parent:WaitForChild("GardenView"))
local PlotView = require(script.Parent:WaitForChild("PlotView"))
local PetPortrait = require(script.Parent:WaitForChild("PetPortrait"))

local remotes = ReplicatedStorage:WaitForChild("GardenRemotes")
local plantEvent = remotes:WaitForChild("Plant")
local harvestEvent = remotes:WaitForChild("Harvest")
local buySquareEvent = remotes:WaitForChild("BuySquare")
local placePetEvent = remotes:WaitForChild("PlacePet")
local liftPetEvent = remotes:WaitForChild("LiftPet")

local TAP_DISTANCE = 40 -- studs (horizontal) from the own plot centre; the server accepts 45 (3D)
local TAP_SECONDS = 0.3
local TAP_PIXELS = 8
local RAY_LENGTH = 300
local CARD_WIDTH = 400
local TOUCH_SIDE = 110 -- px kept free on each side on a touch screen (thumbstick, jump button)
local CARD_BOTTOM = 76 -- px from the bottom: above the Field button (48 px at 20 px)
local BUTTON_HEIGHT = 48
local ROW_HEIGHT = 54
local GAP = 8
local CONFIRM_PRICE = 1000
local CONFIRM_SECONDS = 3
local REACH_SECONDS = 3
local TICK_SECONDS = 0.25
local LIST_MAX = 300 -- px: the pickers' list scrolls beyond this

local COLOR_PANEL = StudStyle.PanelColors.Field
local COLOR_ROW = StudStyle.PetRowColor(COLOR_PANEL)
local COLOR_GO = StudStyle.Colors.Green
local COLOR_PET = StudStyle.Colors.Blue
local COLOR_OFF = StudStyle.Colors.Grey
local COLOR_CLOSE = StudStyle.Colors.Red
local COLOR_ARMED = Color3.fromRGB(240, 140, 40)
local COLOR_INFO = Color3.fromRGB(235, 222, 190)
local COLOR_DIM = Color3.fromRGB(190, 178, 150)
local COLOR_OK = Color3.fromRGB(120, 230, 120)
local COLOR_BAR = Color3.fromRGB(245, 200, 70)
local COLOR_TRACK = Color3.fromRGB(45, 38, 30)

-- Helpers ---------------------------------------------------------------------------------------------------------------------

local function create(className: string, props, children)
	local instance = Instance.new(className)
	for key, value in props do
		(instance :: any)[key] = value
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

-- a text that wraps and grows downwards
local function paragraph(name: string, order: number, props)
	props.LayoutOrder = order
	props.Size = props.Size or UDim2.new(1, 0, 0, 0)
	props.AutomaticSize = Enum.AutomaticSize.Y
	props.TextWrapped = true
	props.Font = props.Font or Enum.Font.Gotham
	props.TextSize = props.TextSize or 15
	props.TextColor3 = props.TextColor3 or COLOR_INFO
	props.TextYAlignment = Enum.TextYAlignment.Top
	return label(name, props)
end

-- a brick button (StudStyle.Brick: colour and text keep being set on the button itself)
local function brick(name: string, props, studs: number?)
	props.Name = name
	props.TextColor3 = Color3.new(1, 1, 1)
	props.TextWrapped = true
	local instance = create("TextButton", props)
	StudStyle.Brick(instance, { studs = studs })
	return instance
end

local function countdown(seconds: number): string
	seconds = math.max(1, math.ceil(seconds))
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

local function pct(share: number): string
	return Locale.Number(math.round(share * 100))
end

local function rootPosition(): Vector3?
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

local function plotCFrame(): CFrame?
	local slot = player:GetAttribute(GardenConfig.PlotAttribute)
	return if type(slot) == "number" then GardenConfig.PlotCFrame(slot) else nil
end

local function inRange(): boolean
	local root, plot = rootPosition(), plotCFrame()
	if not (root and plot) then
		return false
	end
	local offset = root - plot.Position
	return Vector3.new(offset.X, 0, offset.Z).Magnitude <= TAP_DISTANCE
end

-- State ------------------------------------------------------------------------------------------------------------------------

local fieldState = nil -- GardenRemotes.State.field (FieldClient's comment lists its fields)
local receivedAt = 0
local selected: number? = nil
local page = "card" -- what the card shows: "card", "seeds" (seed picker) or "pets" (pet picker)
local moving: string? = nil -- uid of the pet whose Move pet waits for a free square
local armedUntil = 0 -- Buy square's second tap is open until this os.clock()
local reachToken = 0
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

local function petName(uid: string, kind: string): string
	local name = PetClient.NameOf(uid)
	return if type(name) == "string" and name ~= "" then name else Locale.PetKindName(kind)
end

-- share grown 0..1, ripe, seconds left of a planted square at server time `now` (as FieldRings: towards readyAt)
local function progress(entry, crop, now: number): (number, boolean, number)
	local grown, readyAt = entry.grown or 0, entry.readyAt or 0
	if grown >= crop.growSeconds or readyAt <= now then
		return 1, true, 0
	end
	local rate = (crop.growSeconds - grown) / math.max(readyAt - receivedAt, 1)
	return math.clamp((grown + rate * math.max(now - receivedAt, 0)) / crop.growSeconds, 0, 1), false, readyAt - now
end

local function reachOf(square: number, level: number): { number }
	return CropConfig.Reach(square, PetConfig.ReachShape(level), openSet())
end

local function contains(list: { number }, n: number): boolean
	return table.find(list, n) ~= nil
end

-- GUI --------------------------------------------------------------------------------------------------------------------------

local screenGui = create("ScreenGui", {
	Name = "FieldHandGui",
	ResetOnSpawn = false,
	DisplayOrder = 5, -- under FieldClient's Garden panel (6)
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	AutoLocalize = false, -- translated by Locale
})

local card = create("Frame", {
	Name = "Card",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 400),
	Size = UDim2.fromOffset(CARD_WIDTH, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	Visible = false,
	Parent = screenGui,
})
StudStyle.Panel(card, COLOR_PANEL)
local body = create("Frame", {
	Name = "Body",
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
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

local portraits = PetPortrait.Cache()

local function cardWidth(): number
	local camera = workspace.CurrentCamera
	local viewport = if camera then camera.ViewportSize.X else 800
	local side = if UserInputService.TouchEnabled then TOUCH_SIDE else 12
	return math.floor(math.max(200, math.min(CARD_WIDTH, viewport - 2 * side)))
end

local function clearBody()
	PetPortrait.Release(body)
	for _, child in body:GetChildren() do
		if not (child:IsA("UIListLayout") or child:IsA("UIPadding")) then
			child:Destroy()
		end
	end
	barFill, barText = nil, nil
end

-- the title row: a title that wraps and a close button
local function header(title: string, onClose: () -> ())
	local row = create("Frame", {
		Name = "Header",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 44),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = body,
	})
	local text = label("Title", {
		Size = UDim2.new(1, -54, 0, 44),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 22,
		TextWrapped = true,
		Text = title,
		Parent = row,
	})
	StudStyle.Title(text, COLOR_PANEL)
	local close = brick("Close", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = COLOR_CLOSE,
		TextSize = 18,
		Text = "X",
		Parent = row,
	}, 1)
	close.Activated:Connect(onClose)
end

-- the progress bar with the time left inside
local function bar(order: number)
	local track = create("Frame", {
		Name = "Bar",
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = COLOR_TRACK,
		Parent = body,
	}, { create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	barFill = create("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = COLOR_BAR,
		Parent = track,
	}, { create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	barText = label("Time", {
		Size = UDim2.fromScale(1, 1),
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.3,
		ZIndex = 2,
		Parent = track,
	})
end

local function buttonRow(order: number, specs)
	local row = create("Frame", {
		Name = "Buttons",
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, BUTTON_HEIGHT),
		BackgroundTransparency = 1,
		Parent = body,
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
		button.Activated:Connect(spec.action)
	end
	return row
end

local render -- forward

-- Card pages ---------------------------------------------------------------------------------------------------------------------

local function closeCard()
	selected, moving, page = nil, nil, "card"
	GardenView.ShowSelect(nil)
	GardenView.ShowReach(nil)
	if card.Visible then
		local tween = TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 1, 400) })
		tween.Completed:Connect(function()
			if not selected then
				card.Visible = false
				clearBody()
			end
		end)
		tween:Play()
	end
end

local function openPetPage(uid: string)
	local petsGui = player.PlayerGui:FindFirstChild("PetsGui")
	if petsGui then
		petsGui:SetAttribute("OpenPet", uid)
	end
end

-- one row per field pet whose reach covers `square`: portrait, name and job icons, what it does here; a tap opens its page
local function petRows(square: number, order: number)
	local holder = create("Frame", {
		Name = "Pets",
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = body,
	}, { create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }) })
	local open = openSet()
	local statePets = (fieldState and fieldState.pets) or {}
	local placed = {}
	for at, pet in plotPets() do
		table.insert(placed, { at = at, pet = pet })
	end
	table.sort(placed, function(a, b)
		return a.at < b.at
	end)
	local shown = 0
	for _, item in placed do
		local pet, at = item.pet, item.at
		local lines = {}
		if pet.apt > 0 and contains(CropConfig.Reach(at, PetConfig.ReachShape(pet.apt), open), square) then
			table.insert(lines, Locale.T("field.card.petTend", { pct = pct(PetConfig.Strength(pet.apt)) }))
		end
		local guard = statePets[tostring(at)] and statePets[tostring(at)].guard
		if pet.guard > 0 and type(guard) == "table" and contains(CropConfig.Reach(at, PetConfig.ReachShape(pet.guard), open), square) then
			table.insert(lines, Locale.T("field.card.petGuard", { pct = pct(guard.chance or 0) }))
		end
		if #lines > 0 then
			shown += 1
			local row = create("TextButton", {
				Name = "Pet_" .. pet.uid,
				LayoutOrder = at,
				Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = COLOR_ROW,
				AutoButtonColor = true,
				Text = "",
				Parent = holder,
			}, {
				create("UICorner", { CornerRadius = UDim.new(0, 8) }),
				create("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5) }),
			})
			PetPortrait.Holder({
				Position = UDim2.fromOffset(6, 0),
				Size = UDim2.fromOffset(44, 44),
				BackgroundColor3 = StudStyle.Shade(COLOR_ROW, 0.6),
			}, portraits(pet)).Parent = row
			local column = create("Frame", {
				Name = "Text",
				Position = UDim2.fromOffset(58, 0),
				Size = UDim2.new(1, -64, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Parent = row,
			}, { create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1) }) })
			paragraph("Name", 1, {
				Font = StudStyle.Font,
				TextSize = 17,
				TextColor3 = Color3.new(1, 1, 1),
				Text = petName(pet.uid, pet.kind) .. "  " .. PlotView.JobIcons(pet.apt, pet.guard),
			}).Parent = column
			paragraph("Effect", 2, { TextSize = 14, Text = table.concat(lines, "\n") }).Parent = column
			row.Activated:Connect(function()
				openPetPage(pet.uid)
			end)
		end
	end
	if shown == 0 then
		holder:Destroy()
	end
end

local function boostLine(): string?
	local parts = {}
	local growth = CropConfig.GrowthSpeed(CropConfig.UpgradeLevel(fieldState.upgrades, "Growth")) - 1
	if growth > 1e-6 then
		table.insert(parts, Locale.T("field.card.boost", { icon = "🌱", name = Locale.T("field.upgrade.growth"), pct = pct(growth) }))
	end
	local cloches = CropConfig.ToolEffect(fieldState.tools, "Cloches")
	if cloches > 1e-6 then
		table.insert(parts, Locale.T("field.card.boost", { icon = "🔔", name = Locale.T("field.tool.cloches"), pct = pct(cloches) }))
	end
	return if #parts > 0 then table.concat(parts, " · ") else nil
end

-- the next square's price, Renown and the button (grey with the reason when it cannot be bought)
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
		Text = if expansion.renown > 0
			then Locale.T("field.card.priceRenown", { count = expansion.price, level = expansion.renown })
			else Locale.T("field.card.price", { count = expansion.price }),
	}).Parent = body
	local lines = {}
	local renownShort = (fieldState.level or 0) < expansion.renown
	local coins = PetClient.Coins or 0
	if renownShort then
		table.insert(lines, "<font color='#f06a5a'>" .. Locale.T("field.expand.needRenown", { level = expansion.renown }) .. "</font>")
	end
	if coins < expansion.price then
		table.insert(lines, Locale.T("common.needMoreCoins", { count = expansion.price - coins }))
	end
	if #lines > 0 then
		paragraph("Reason", 3, { RichText = true, Text = table.concat(lines, "\n") }).Parent = body
	end
	local can = #lines == 0
	local armed = os.clock() < armedUntil
	buttonRow(9, {
		{
			name = "Buy",
			color = if not can then COLOR_OFF elseif armed then COLOR_ARMED else COLOR_GO,
			text = if armed then Locale.T("field.card.tapAgain") else Locale.T("field.card.buy"),
			action = function()
				if not can then
					return
				end
				if expansion.price > CONFIRM_PRICE and os.clock() >= armedUntil then
					armedUntil = os.clock() + CONFIRM_SECONDS
					render()
					task.delay(CONFIRM_SECONDS, function()
						if os.clock() >= armedUntil then
							render()
						end
					end)
					return
				end
				armedUntil = 0
				buySquareEvent:FireServer(square, #(fieldState.open or {}))
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
	header(if crop then crop.icon .. " " .. Locale.CropName(crop) else Locale.T("field.card.empty"), closeCard)
	local ripe = false
	if crop then
		bar(2)
		local _, isRipe = progress(entry, crop, workspace:GetServerTimeNow())
		ripe = isRipe
		cardRipe = ripe
		local boosts = boostLine()
		if boosts and not ripe then
			paragraph("Boosts", 3, { TextSize = 14, Text = boosts }).Parent = body
		end
	else
		paragraph("Hint", 3, { TextSize = 15, Text = Locale.T("field.card.emptyHint") }).Parent = body
	end
	petRows(square, 4)
	if moving then
		local uid = moving
		local owned = PetClient.State and PetClient.State.pets[uid]
		paragraph("Moving", 5, {
			Font = StudStyle.Font,
			TextSize = 17,
			TextColor3 = COLOR_OK,
			Text = Locale.T("field.card.moving", { pet = if owned then petName(uid, owned.Kind) else "" }),
		}).Parent = body
		buttonRow(9, {
			{ name = "Cancel", color = COLOR_OFF, text = Locale.T("field.card.cancel"), action = function()
				moving = nil
				GardenView.ShowReach(nil)
				render()
			end },
		})
		return
	end
	local specs = {}
	if not crop then
		table.insert(specs, { name = "Plant", color = COLOR_GO, text = Locale.T("field.card.plant"), action = function()
			page = "seeds"
			render()
		end })
	elseif ripe then
		table.insert(specs, { name = "Harvest", color = COLOR_GO, text = Locale.T("field.card.harvest"), action = function()
			harvestEvent:FireServer(square)
		end })
	end
	if pet then
		table.insert(specs, { name = "MovePet", color = COLOR_PET, text = Locale.T("field.card.movePet"), action = function()
			moving = pet.uid
			local level = math.max(pet.apt or 0, if type(pet.guard) == "table" then pet.guard.level else 0)
			GardenView.ShowReach(reachOf(square, level))
			render()
		end })
		table.insert(specs, { name = "TakeBack", color = COLOR_OFF, text = Locale.T("field.card.takeBack"), action = function()
			liftPetEvent:FireServer(pet.uid)
		end })
	else
		table.insert(specs, { name = "PlacePet", color = COLOR_PET, text = Locale.T("field.card.placePet"), action = function()
			page = "pets"
			render()
		end })
	end
	buttonRow(9, specs)
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
	page = "card"
	GardenView.ShowReach(nil)
	render()
end

-- the seed picker: the seeds held (count, grow time); without seeds a hint and the way to the seed shop
local function renderSeeds()
	local square = selected :: number
	header(Locale.T("field.picker.title", { n = square }), back)
	local list = pickerList(2)
	local rows = 0
	local growth = CropConfig.GrowthSpeed(CropConfig.UpgradeLevel(fieldState.upgrades, "Growth"))
	for _, crop in CropConfig.Crops do
		local stock = (fieldState.seeds or {})[crop.id] or 0
		if stock > 0 then
			rows += 1
			local seconds = math.ceil(crop.growSeconds / growth - 1e-6)
			local row = pickerRow(list, crop.id, rows, crop.icon .. " " .. Locale.CropName(crop), Locale.T("field.picker.info", { stock = stock, time = growTime(seconds) }), true, COLOR_GO)
			row.Activated:Connect(function()
				plantEvent:FireServer(square, crop.id)
				page = "card"
				render()
			end)
		end
	end
	if rows > 0 then
		fitList(list, rows)
		return
	end
	list:Destroy()
	paragraph("None", 2, { Text = Locale.T("field.picker.none") }).Parent = body
	buttonRow(9, {
		{ name = "Shop", color = COLOR_GO, text = Locale.T("field.picker.shop"), action = function()
			closeCard()
			local fieldGui = player.PlayerGui:FindFirstChild("FieldGui")
			if fieldGui then
				fieldGui:SetAttribute("OpenField", "seeds")
			end
		end },
	})
end

-- the pet picker: pets with Tending or Pest control (job levels, squares they would work here); hovering a row tints its reach
local function renderPets()
	local square = selected :: number
	header(Locale.T("field.petPicker.title", { n = square }), back)
	local used = 0
	for _ in (fieldState.pets or {}) do
		used += 1
	end
	local candidates = {}
	for _, pet in PetClient.Inventory() do
		if pet.tending > 0 or pet.guard > 0 then
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
	if #candidates == 0 then
		paragraph("None", 2, { Text = Locale.T("field.petPicker.none") }).Parent = body
		return
	end
	local list = pickerList(2)
	for index, pet in candidates do
		local reach = reachOf(square, math.max(pet.tending, pet.guard))
		local enabled = not pet.equipped and (pet.field ~= nil or used < (fieldState.slots or 1))
		local info
		if pet.equipped then
			info = Locale.T("field.petPicker.equipped")
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
		local title = petName(pet.uid, pet.kind) .. "  " .. PlotView.JobIcons(pet.tending, pet.guard)
		local row = pickerRow(list, "Pet_" .. pet.uid, index, title, info, enabled, COLOR_PET)
		row.MouseEnter:Connect(function()
			GardenView.ShowReach(reach)
		end)
		row.MouseLeave:Connect(function()
			GardenView.ShowReach(nil)
		end)
		if enabled then
			row.Activated:Connect(function()
				placePetEvent:FireServer(square, pet.uid)
				page = "card"
				GardenView.ShowReach(nil)
				render()
			end)
		end
	end
	fitList(list, #candidates)
end

function render()
	if not (selected and fieldState) then
		return
	end
	clearBody()
	card.Size = UDim2.fromOffset(cardWidth(), 0)
	if page == "seeds" then
		renderSeeds()
	elseif page == "pets" then
		renderPets()
	else
		renderCard()
		local entry = fieldState.squares and fieldState.squares[tostring(selected)]
		local crop = entry and CropConfig.ById[entry.crop]
		if crop and barFill and barText then
			local share, ripe, left = progress(entry, crop, workspace:GetServerTimeNow())
			barFill.Size = UDim2.fromScale(share, 1)
			barFill.BackgroundColor3 = if ripe then COLOR_OK else COLOR_BAR
			barText.Text = if ripe then Locale.T("field.card.ripe") else countdown(left)
		end
	end
end

-- Selection and taps -------------------------------------------------------------------------------------------------------------

local function select(square: number)
	selected, page = square, "card"
	armedUntil = 0
	GardenView.ShowSelect(square)
	render()
	if not card.Visible then
		card.Visible = true
		card.Position = UDim2.new(0.5, 0, 1, 400)
	end
	TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 1, -CARD_BOTTOM) }):Play()
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

-- The own square under screen point `point` (InputObject / TouchTapInWorld coordinates), or nil.
local function squareUnder(point: Vector2): number?
	local camera = workspace.CurrentCamera
	local plot = plotCFrame()
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

local function onTap(point: Vector2)
	if not (fieldState and inRange()) then
		return
	end
	local square = squareUnder(point)
	if moving then
		local uid = moving
		moving = nil
		GardenView.ShowReach(nil)
		local open = openSet()
		if square and open[square] and not (fieldState.pets or {})[tostring(square)] then
			placePetEvent:FireServer(square, uid)
			select(square)
			return
		end
	end
	if not square or (square == selected and page == "card") then
		closeCard()
		return
	end
	select(square)
end

UserInputService.TouchTapInWorld:Connect(function(position: Vector2, processedByUI: boolean)
	if not processedByUI then
		onTap(position)
	end
end)

local pressAt: Vector2? = nil
local pressClock = 0
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessed then
		pressAt = Vector2.new(input.Position.X, input.Position.Y)
		pressClock = os.clock()
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 or not pressAt then
		return
	end
	local point = Vector2.new(input.Position.X, input.Position.Y)
	local start = pressAt
	pressAt = nil
	if (point - start).Magnitude <= TAP_PIXELS and os.clock() - pressClock <= TAP_SECONDS then
		onTap(point)
	end
end)

-- Events -------------------------------------------------------------------------------------------------------------------------

remotes:WaitForChild("State").OnClientEvent:Connect(function(state)
	fieldState = if type(state) == "table" then state.field else nil
	receivedAt = workspace:GetServerTimeNow()
	if selected and not fieldState then
		closeCard()
	elseif selected then
		render()
	end
end)

remotes:WaitForChild("Result").OnClientEvent:Connect(function(action, ok, detail)
	if action ~= "PlacePet" or not ok or type(detail) ~= "table" then
		return
	end
	-- the placed pet's reach, for a moment
	local pet = PetClient.State and PetClient.State.pets[detail.uid]
	if pet then
		reachToken += 1
		local mine = reachToken
		GardenView.ShowReach(reachOf(detail.square, math.max(PetConfig.AptitudeLevel(pet, "Tending"), PetConfig.AptitudeLevel(pet, "PestControl"))))
		task.delay(REACH_SECONDS, function()
			if reachToken == mine and not moving and page ~= "pets" then
				GardenView.ShowReach(nil)
			end
		end)
	end
end)

PetClient.Changed:Connect(function()
	if selected then
		render() -- Coins (Buy square), pets equipped / hatched / renamed
	end
end)

Locale.Changed:Connect(function()
	if selected then
		render()
	end
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

local function resize()
	if selected then
		card.Size = UDim2.fromOffset(cardWidth(), 0)
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

-- Every TICK_SECONDS: the card closes out of range; the bar and its time follow the server time
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < TICK_SECONDS then
		return
	end
	elapsed = 0
	if not selected then
		return
	end
	if not inRange() then
		closeCard()
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
		barFill.Size = UDim2.fromScale(share, 1)
		barFill.BackgroundColor3 = if ripe then COLOR_OK else COLOR_BAR
		barText.Text = if ripe then Locale.T("field.card.ripe") else countdown(left)
	end
end)

screenGui.Parent = player:WaitForChild("PlayerGui")
-- the State may have arrived before this script connected (GardenView keeps the last one)
if not fieldState and GardenView.OwnField() then
	fieldState = GardenView.OwnField()
	receivedAt = workspace:GetServerTimeNow()
end
