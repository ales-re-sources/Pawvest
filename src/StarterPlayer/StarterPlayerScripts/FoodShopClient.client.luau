-- Food shop client (docs/GDD.md §7.6, P2b2): the prompt on the garden plaza's food stand opens the food panel: every owned
-- pet with its level, XP and the XP still needed for level 20, and one feed button per food. Display only: a click just
-- names a pet and a food; GardenFood validates the distance, the price and the level. The GUI is built here (no Studio GUI).
-- Stud-brick look (StudStyle, red): title strip, pet rows with a PetPortrait, the foods as brick buttons that say what
-- they give and cost ("🍓 +25 XP" over "50 Coins"; a pet at the max level shows a "Max level" tag instead).
-- Tooltip above a food button: food and price, what it does to that pet ("Owl Lv 6 → Lv 8", XP wasted past Lv 20) and
-- the Coins still missing. With a mouse it shows on hover and one click feeds; after a touch the first tap selects the
-- button (white outline + tooltip, "Tap again to feed") and a second tap on it within ARM_SECONDS feeds; a tap anywhere
-- else or the timeout cancels. Touch vs mouse is taken from the last input type, not from the device.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))
local PetPortrait = require(script.Parent:WaitForChild("PetPortrait"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))

local remotes = ReplicatedStorage:WaitForChild("GardenRemotes")
local feedEvent = remotes:WaitForChild("Feed") -- looked up by name, never `remotes.X`
local player = Players.LocalPlayer

local WIDTH = 540
local HEIGHT = 480
local ROW_HEIGHT = 62
local FOOD_BUTTON_WIDTH = 86
local ARM_SECONDS = 3 -- touch: how long a selected food button waits for the second tap
local TOOLTIP_ROOM = 130 -- a button closer than this to the panel's top gets its tooltip below it
local TEXT_LEFT = 74 -- name and detail start right of the portrait
local CLOSE_DISTANCE = GardenConfig.FoodStandDistance -- walking further from the stand closes the panel (the server rejects it too)

local COLOR_PANEL = StudStyle.PanelColors.FoodShop
local COLOR_ROW = StudStyle.PetRowColor(COLOR_PANEL)
local COLOR_BUY = StudStyle.Colors.Green
local COLOR_LOCKED = StudStyle.Colors.Grey
local COLOR_CLOSE = StudStyle.Shade(StudStyle.Colors.Red, 0.75) -- a darker red than the panel's title strip
local COLOR_INFO = Color3.fromRGB(235, 222, 190)
local COLOR_ERROR = Color3.fromRGB(240, 100, 90)
local COLOR_OK = Color3.fromRGB(120, 230, 120)
local REJECT_KEYS = {
	coins = "common.reject.coins",
	maxed = "food.reject.maxed",
	far = "food.reject.far",
	loading = "common.reject.loading",
}

local function rejectText(reason: string?): string
	return Locale.T(reason and REJECT_KEYS[reason] or "common.reject.failed", { max = PetConfig.MaxLevel })
end

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

local rowPortrait = PetPortrait.Cache()

-- Panel ------------------------------------------------------------------------------------------------------------------

-- the brick title strip: StudStyle.Panel styles a child named TitleLabel
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
local statusLabel = label("Status", {
	Position = UDim2.new(0, 12, 0, 42),
	Size = UDim2.new(1, -24, 0, 22),
	TextSize = 15,
	TextColor3 = COLOR_INFO,
	TextTruncate = Enum.TextTruncate.AtEnd,
	RichText = true,
})
local list = create("ScrollingFrame", {
	Name = "Pets",
	Position = UDim2.new(0, 8, 0, 68),
	Size = UDim2.new(1, -16, 1, -76),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 5,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, {
	create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }),
	create("UIPadding", { PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 2) }),
})
local emptyLabel = label("Empty", {
	Position = UDim2.new(0, 12, 0, 74),
	Size = UDim2.new(1, -24, 0, 40),
	Font = Enum.Font.Gotham,
	TextSize = 15,
	TextColor3 = COLOR_INFO,
	TextWrapped = true,
	Visible = false,
})

-- one tooltip for the whole panel, placed above the food button it describes
local tooltip = label("Tooltip", {
	AnchorPoint = Vector2.new(0.5, 1),
	Size = UDim2.fromOffset(220, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	TextSize = 14,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Center,
	RichText = true,
	ZIndex = 10,
	Visible = false,
})
tooltip.BackgroundTransparency = 0 -- label() makes labels transparent
tooltip.BackgroundColor3 = StudStyle.Shade(COLOR_PANEL, 0.2)
create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = tooltip })
create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Color3.fromRGB(255, 205, 60), Thickness = 2, Parent = tooltip })
create("UIPadding", {
	PaddingTop = UDim.new(0, 5),
	PaddingBottom = UDim.new(0, 5),
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
	Parent = tooltip,
})

local panel = create("Frame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(WIDTH, HEIGHT),
	Visible = false,
}, {
	titleLabel,
	closeButton,
	statusLabel,
	list,
	emptyLabel,
	tooltip,
})
StudStyle.Panel(panel, COLOR_PANEL)

local screenGui = create("ScreenGui", {
	Name = "FoodShopGui",
	ResetOnSpawn = false,
	DisplayOrder = 5,
	AutoLocalize = false, -- translated by Locale (L2)
}, { panel })

-- texts that do not depend on the state (set again when the language changes)
local function staticTexts()
	titleLabel.Text = Locale.T("food.title")
	emptyLabel.Text = Locale.T("food.empty")
end
staticTexts()

-- State ------------------------------------------------------------------------------------------------------------------

local openStand: BasePart? = nil
local rows = {}
local buttons = {} -- ["uid:foodId"] = { button, entry, food } of the current rows
local hovered: string? = nil -- key of the food button under the mouse
local armed: string? = nil -- touch: key of the selected food button
local armToken = 0
local flashToken = 0

local function showDefaultStatus()
	statusLabel.Text = Locale.T("food.status")
	statusLabel.TextColor3 = COLOR_INFO
end

local function flash(text: string, color: Color3)
	flashToken += 1
	local mine = flashToken
	statusLabel.Text = text
	statusLabel.TextColor3 = color
	task.delay(4, function()
		if flashToken == mine then
			showDefaultStatus()
		end
	end)
end

local function hex(color: Color3): string
	return "#" .. color:ToHex()
end

-- What `food` does to the pet: "Owl Lv 6 → Lv 8", "Owl Lv 6 · XP 23 → 48/147", "… · 600 XP wasted"
local function outcome(entry, food): string
	local pet = PetClient.State.pets[entry.uid]
	local copy = { Level = entry.level, XP = entry.xp }
	local gained = PetConfig.GainXp(copy, food.xp) or 0
	local kind = string.format("<font color='%s'>%s</font>", hex(entry.rarity.color), Locale.PetKindName(entry.kind))
	local name = Locale.T("pet.nameLevel", { kind = kind, level = entry.level })
	local text
	if gained > 0 then
		text = Locale.T("food.outcome.levelUp", { name = name, level = copy.Level })
	else
		text = Locale.T("food.outcome.xp", { name = name, from = entry.xp, to = copy.XP, next = entry.xpNext })
	end
	local wasted = food.xp - GardenConfig.XpToMax(pet)
	if wasted > 0 then
		text ..= "\n" .. Locale.T("food.wasted", { xp = wasted, max = PetConfig.MaxLevel })
	end
	return text
end

local function setOutline(key: string?, on: boolean)
	local info = key and buttons[key]
	local face = info and info.button:FindFirstChild("Face", true)
	local stroke = face and face:FindFirstChildOfClass("UIStroke")
	if stroke then
		if on then
			stroke:SetAttribute("BaseColor", stroke:GetAttribute("BaseColor") or stroke.Color)
			stroke.Color = Color3.new(1, 1, 1)
			stroke.Thickness = 3
		elseif stroke:GetAttribute("BaseColor") then
			stroke.Color = stroke:GetAttribute("BaseColor")
			stroke.Thickness = 1.5
		end
	end
end

-- Shows the tooltip for the armed button (touch) or the hovered one (mouse); hides it otherwise.
local function updateTooltip()
	local key = armed or hovered
	local info = key and buttons[key]
	if not (info and info.button.Parent and PetClient.State) then
		tooltip.Visible = false
		return
	end
	local food = info.food
	local lines = {
		Locale.T("food.tooltip.head", { icon = food.icon, food = Locale.FoodName(food), count = food.price }),
		outcome(info.entry, food),
	}
	if PetClient.Coins < food.price then
		table.insert(lines, Locale.T("common.needMoreCoins", { count = food.price - PetClient.Coins }))
	elseif armed == key then
		table.insert(lines, Locale.T("food.tapAgain"))
	end
	tooltip.Text = table.concat(lines, "\n")
	-- above the button; below it near the top of the list (it would cover the title and the close button), and kept
	-- inside the panel's width
	local b = info.button
	local top = b.AbsolutePosition.Y - panel.AbsolutePosition.Y
	local half = tooltip.Size.X.Offset / 2
	local x = math.clamp(b.AbsolutePosition.X - panel.AbsolutePosition.X + b.AbsoluteSize.X / 2, half + 4, WIDTH - half - 4)
	if top < TOOLTIP_ROOM then
		tooltip.AnchorPoint = Vector2.new(0.5, 0)
		tooltip.Position = UDim2.fromOffset(x, top + b.AbsoluteSize.Y + 8)
	else
		tooltip.AnchorPoint = Vector2.new(0.5, 1)
		tooltip.Position = UDim2.fromOffset(x, top - 8)
	end
	tooltip.Visible = true
end

local function disarm()
	if armed then
		setOutline(armed, false)
		armed = nil
		armToken += 1
		updateTooltip()
	end
end

local function arm(key: string)
	disarm()
	armed = key
	armToken += 1
	local mine = armToken
	setOutline(key, true)
	updateTooltip()
	task.delay(ARM_SECONDS, function()
		if armToken == mine then
			disarm()
		end
	end)
end

local function lastInputWasTouch(): boolean
	return UserInputService:GetLastInputType() == Enum.UserInputType.Touch
end

local function where(entry): string
	if entry.equipped then
		return Locale.T("food.where.equipped")
	elseif entry.penned then
		return Locale.T("food.where.pen", { pen = entry.penned })
	end
	return Locale.T("food.where.resting")
end

local function petRow(order: number, entry)
	local pet = PetClient.State.pets[entry.uid]
	local toMax = GardenConfig.XpToMax(pet)
	local maxed = entry.level >= PetConfig.MaxLevel
	local detail = if maxed
		then Locale.T("food.detail.max", { where = where(entry) })
		else Locale.T("food.detail", {
			xp = entry.xp,
			next = entry.xpNext,
			where = where(entry),
			toMax = toMax,
			max = PetConfig.MaxLevel,
		})
	local textWidth = -(TEXT_LEFT + 6 + #GardenConfig.Foods * (FOOD_BUTTON_WIDTH + 4))
	local maxTag = maxed
		and label("MaxTag", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(#GardenConfig.Foods * (FOOD_BUTTON_WIDTH + 4) - 4, 30),
			TextSize = 16,
			TextColor3 = Color3.fromRGB(255, 205, 60),
			TextXAlignment = Enum.TextXAlignment.Center,
			Text = Locale.T("food.maxTag"),
		})
	local row = create("Frame", {
		Name = "Pet_" .. entry.uid,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		BackgroundColor3 = COLOR_ROW,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 8) }),
		create("Frame", {
			Name = "RarityBar",
			Size = UDim2.new(0, 5, 1, -12),
			Position = UDim2.new(0, 6, 0, 6),
			BackgroundColor3 = entry.rarity.color,
			BorderSizePixel = 0,
		}, { create("UICorner", { CornerRadius = UDim.new(0, 3) }) }),
		PetPortrait.Holder({
			Position = UDim2.fromOffset(16, 6),
			Size = UDim2.fromOffset(50, 50),
			BackgroundColor3 = StudStyle.Shade(COLOR_PANEL, 0.18),
		}, rowPortrait(entry)),
		label("Name", {
			Position = UDim2.new(0, TEXT_LEFT, 0, 6),
			Size = UDim2.new(1, textWidth, 0, 22),
			TextSize = 16,
			TextColor3 = entry.rarity.color,
			TextStrokeTransparency = 0.4,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = Locale.PetName(entry.kind, entry.level),
		}),
		label("Detail", {
			Position = UDim2.new(0, TEXT_LEFT, 0, 29),
			Size = UDim2.new(1, textWidth, 0, 30),
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = COLOR_INFO,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = detail,
		}),
		maxTag or nil,
	})
	if maxed then
		return row
	end
	for index, food in GardenConfig.Foods do
		local key = entry.uid .. ":" .. food.id
		local feedButton = button("Feed_" .. food.id, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -6 - (#GardenConfig.Foods - index) * (FOOD_BUTTON_WIDTH + 4), 0.5, 2),
			Size = UDim2.fromOffset(FOOD_BUTTON_WIDTH, 46),
			BackgroundColor3 = if PetClient.Coins >= food.price then COLOR_BUY else COLOR_LOCKED,
			TextSize = 14,
			RichText = true,
			Text = Locale.T("food.button", { icon = food.icon, xp = food.xp, count = food.price }),
		}, 2)
		feedButton.Parent = row
		buttons[key] = { button = feedButton, entry = entry, food = food }

		feedButton.MouseEnter:Connect(function()
			if not lastInputWasTouch() then
				hovered = key
				updateTooltip()
			end
		end)
		feedButton.MouseLeave:Connect(function()
			if hovered == key then
				hovered = nil
				updateTooltip()
			end
		end)
		feedButton.Activated:Connect(function()
			if PetClient.Coins < food.price then
				-- nothing to confirm: show why (tooltip) and say so
				if lastInputWasTouch() then
					arm(key)
				end
				return flash(rejectText("coins"), COLOR_ERROR)
			end
			if lastInputWasTouch() and armed ~= key then
				return arm(key) -- first tap: preview
			end
			disarm()
			feedEvent:FireServer(entry.uid, food.id)
		end)
	end
	return row
end

local function refresh()
	for _, row in rows do
		PetPortrait.Release(row) -- the portraits stay cached
		row:Destroy()
	end
	table.clear(rows)
	table.clear(buttons)
	if not (openStand and PetClient.State) then
		armed, hovered = nil, nil
		tooltip.Visible = false
		return
	end
	local count = 0
	for _, entry in PetClient.Inventory() do
		count += 1
		local row = petRow(count, entry)
		row.Parent = list
		table.insert(rows, row)
	end
	emptyLabel.Visible = count == 0
	-- the rows are rebuilt on every state change (Coins too): keep the selection and the tooltip on the new buttons
	if armed and not buttons[armed] then
		armed = nil
	end
	if hovered and not buttons[hovered] then
		hovered = nil
	end
	if armed then
		setOutline(armed, true)
	end
	updateTooltip()
end

local function closePanel()
	openStand = nil
	panel.Visible = false
	refresh()
end

local function openPanel(stand: BasePart)
	openStand = stand
	armed, hovered = nil, nil
	showDefaultStatus()
	panel.Visible = true
	refresh()
end

closeButton.Activated:Connect(closePanel)

-- touch: a tap anywhere but the selected food button cancels the selection (a tap on another food selects that one)
UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.Touch or not armed then
		return
	end
	local info = buttons[armed]
	if not info then
		return disarm()
	end
	local position = Vector2.new(input.Position.X, input.Position.Y)
	local b = info.button
	local inside = position.X >= b.AbsolutePosition.X
		and position.X <= b.AbsolutePosition.X + b.AbsoluteSize.X
		and position.Y >= b.AbsolutePosition.Y
		and position.Y <= b.AbsolutePosition.Y + b.AbsoluteSize.Y
	if not inside then
		disarm()
	end
end)
-- the tooltip sits above a button inside the scrolling list: scrolling would leave it behind
list:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
	hovered = nil
	disarm()
	tooltip.Visible = false
end)

PetClient.Changed:Connect(function()
	if openStand then
		refresh()
	end
end)

remotes:WaitForChild("Result").OnClientEvent:Connect(function(action, ok, detail)
	if action ~= "Feed" then
		return
	end
	if not ok then
		return flash(rejectText(detail), COLOR_ERROR)
	end
	local food = GardenConfig.FoodById[detail.food]
	local pet = PetClient.State and PetClient.State.pets[detail.uid]
	local leveled = type(detail.levels) == "number" and detail.levels > 0
	flash(
		Locale.T(if leveled then "food.fedLevelUp" else "food.fed", {
			icon = food and food.icon or "",
			kind = if pet then Locale.PetKindName(pet.Kind) else Locale.T("food.yourPet"),
			xp = detail.xp,
			level = detail.level,
		}),
		COLOR_OK
	)
end)

Locale.Changed:Connect(function()
	staticTexts()
	if openStand then
		showDefaultStatus()
		refresh()
	end
end)

-- Prompt -----------------------------------------------------------------------------------------------------------------

local function counter(): BasePart?
	local garden = workspace:FindFirstChild("Garden")
	local stand = garden and garden:FindFirstChild(GardenConfig.FoodStandName)
	return stand and stand:IsA("Model") and stand.PrimaryPart or nil
end

task.spawn(function()
	local stand = workspace:WaitForChild("Garden"):WaitForChild(GardenConfig.FoodStandName, 60)
	local part = stand and stand:IsA("Model") and stand.PrimaryPart
	local prompt = part and part:FindFirstChild("Prompt")
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Triggered:Connect(function(who)
			if who == player then
				openPanel(part)
			end
		end)
	end
end)

-- Opens the panel when the ScreenGui attribute Open is set (same effect as the prompt; a test hook).
screenGui:GetAttributeChangedSignal("Open"):Connect(function()
	if screenGui:GetAttribute("Open") then
		local part = counter()
		if part then
			openPanel(part)
		end
		screenGui:SetAttribute("Open", nil)
	end
end)

-- Closes the panel when the player walks away from the stand
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.5 then
		return
	end
	elapsed = 0
	if openStand then
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root or (root.Position - openStand.Position).Magnitude > CLOSE_DISTANCE then
			closePanel()
		end
	end
end)

screenGui.Parent = player:WaitForChild("PlayerGui")
