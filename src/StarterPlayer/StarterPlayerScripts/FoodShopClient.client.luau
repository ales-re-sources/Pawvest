-- Food shop client (docs/GDD.md §7.6, P2b2): the prompt on the garden plaza's food stand opens the food panel: every owned
-- pet as the Pets panel shows it (U1: PetRow: portrait with level badge and status icon, name, trait chips with fills; the chip
-- the food will train, PetConfig.CareTarget, is outlined) and one feed button per food. Order: pets with you, then the others
-- that can still grow, then the ones with nothing left to train (greyed). Display only: a click just names a pet and a food;
-- GardenFood validates the distance, the price and that something can train. The GUI is built here (no Studio GUI).
-- Stud-brick look (StudStyle, red): title strip, pet rows, the foods as brick buttons that say what they give and cost
-- ("🍓 +25 XP" over "50 Coins"; a pet with nothing left to train shows a "Max level" / "Trained" tag instead). On a small
-- screen the panel is scaled down to fit (UIScale) and the food buttons grow so they stay at least 36 px tall on screen.
-- Tooltip above a food button: food and price, what it does to that pet ("Owl Lv 6 · Cuteness → Lv 8", XP wasted) and
-- the Coins still missing. With a mouse it shows on hover and one click feeds; after a touch the first tap selects the
-- button (white outline + tooltip, "Tap again to feed") and a second tap on it within ARM_SECONDS feeds; a tap anywhere
-- else or the timeout cancels. Touch vs mouse is taken from the last input type, not from the device.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local UiKit = require(ReplicatedStorage:WaitForChild("UiKit"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))
local PetPortrait = require(script.Parent:WaitForChild("PetPortrait"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local PanelFocus = require(ReplicatedStorage:WaitForChild("PanelFocus"))
local PetRow = require(script.Parent:WaitForChild("PetRow"))
local PetFilterBar = require(script.Parent:WaitForChild("PetFilterBar"))
local GardenUi = require(script.Parent:WaitForChild("GardenUi"))

local remotes = ReplicatedStorage:WaitForChild("GardenRemotes")
local feedEvent = remotes:WaitForChild("Feed") -- looked up by name, never `remotes.X`
local player = Players.LocalPlayer

local WIDTH = 540
local HEIGHT = 480
local FOOD_BUTTON_WIDTH = 86
local ARM_SECONDS = 3 -- touch: how long a selected food button waits for the second tap
local FILTER_TOP = 74 -- the filter chips (PetFilterBar, as in the Pets panel) sit above the pet list
local CLOSE_DISTANCE = GardenConfig.FoodStandDistance -- walking further from the stand closes the panel (the server rejects it too)

local COLOR_PANEL = StudStyle.PanelColors.FoodShop
local COLOR_ROW = StudStyle.PetRowColor(COLOR_PANEL)
local COLOR_BUY = StudStyle.Colors.Green
local COLOR_LOCKED = StudStyle.Colors.Grey
local COLOR_INFO = StudStyle.Text.Info
local COLOR_ERROR = StudStyle.Text.Error
local COLOR_OK = StudStyle.Text.Ok
local REJECT_KEYS = { -- the rest: Locale.Reject's common.reject.*
	maxed = "food.reject.maxed",
	far = "food.reject.far",
}

local create = UiKit.Create

local label = UiKit.Label

-- a brick button (StudStyle.Brick: colour and text keep being set on the button itself)
local button = UiKit.Button

local rowPortrait = PetPortrait.Cache()

-- Panel ------------------------------------------------------------------------------------------------------------------

-- the shell (GardenUi.Panel: brick title strip, X button, fit to the screen); the filter chips, status line and pet list are
-- laid out here
local shell = GardenUi.Panel("FoodShopGui", COLOR_PANEL, WIDTH, HEIGHT, { content = false })
local panel, titleLabel, closeButton = shell.panel, shell.title, shell.close
local screenGui = shell.gui

local statusLabel = label("Status", {
	Position = UDim2.new(0, 12, 0, 38),
	Size = UDim2.new(1, -24, 0, 34),
	TextSize = 14,
	TextColor3 = COLOR_INFO,
	TextWrapped = true, -- two lines (Czech is longer)
	TextYAlignment = Enum.TextYAlignment.Center,
	RichText = true,
})
local list = create("ScrollingFrame", {
	Name = "Pets",
	Position = UDim2.new(0, 8, 0, 74 + 42), -- set again by layoutList
	Size = UDim2.new(1, -16, 1, -82 - 42),
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
	Position = UDim2.new(0, 12, 0, 80 + 42),
	Size = UDim2.new(1, -24, 0, 40),
	Font = Enum.Font.Gotham,
	TextSize = 15,
	TextColor3 = COLOR_INFO,
	TextWrapped = true,
	Visible = false,
})

statusLabel.Parent = panel
list.Parent = panel
emptyLabel.Parent = panel
local chipTooltip = PetRow.Tooltip(panel, COLOR_PANEL)
-- one for the whole panel, over the food button it describes (under it in the first rows: it would cover the filter chips)
local foodTooltip = PetRow.Tooltip(panel, COLOR_PANEL, { name = "Tooltip", room = 130 })

local refresh -- defined below; a filter pick calls it
local chipHeight = 36
local filterBar = PetFilterBar.Mount(panel, {
	color = COLOR_PANEL,
	width = WIDTH,
	top = FILTER_TOP,
	height = chipHeight,
	onPress = function()
		chipTooltip.Hide()
	end,
	onChange = function()
		list.CanvasPosition = Vector2.zero
		refresh()
	end,
})

-- the chips take a row above the pet list; their height keeps a finger target of at least 36 px on screen
local function layoutList()
	local listTop = FILTER_TOP + chipHeight + 6
	filterBar.SetLayout(FILTER_TOP, chipHeight)
	list.Position = UDim2.new(0, 8, 0, listTop)
	list.Size = UDim2.new(1, -16, 1, -listTop - 8)
	emptyLabel.Position = UDim2.new(0, 12, 0, listTop + 6)
end
layoutList()

-- U1: a phone screen (e.g. 844 x 390) is smaller than the panel: scale it to fit; the food buttons then grow so a finger still hits
-- them (≥ 36 px on screen)
local buttonHeight = 46
local rowHeight = 62
local function fitToScreen()
	shell.Fit()
	local scale = shell.Scale()
	buttonHeight = math.min(60, math.max(46, math.ceil(36 / scale)))
	rowHeight = math.max(62, buttonHeight + 10)
	chipHeight = math.max(36, math.ceil(36 / scale))
	layoutList()
end

-- texts that do not depend on the state (set again when the language changes)
local function staticTexts()
	titleLabel.Text = Locale.T("food.title")
	filterBar.SetTexts()
end
staticTexts()

-- State ------------------------------------------------------------------------------------------------------------------

local openStand: BasePart? = nil
local rows = {}
local buttons = {} -- ["uid:foodId"] = { button, entry, food } of the current rows
local hovered: string? = nil -- key of the food button under the mouse
local armed: string? = nil -- touch: key of the selected food button
local armTimer = UiKit.Latest()
local flashTimer = UiKit.Latest()

local function showDefaultStatus()
	statusLabel.Text = Locale.T("food.status")
	statusLabel.TextColor3 = COLOR_INFO
end

local function flash(text: string, color: Color3)
	statusLabel.Text = text
	statusLabel.TextColor3 = color
	flashTimer.After(4, showDefaultStatus)
end

local function hex(color: Color3): string
	return "#" .. color:ToHex()
end

-- What `food` does to the pet (P4: care XP, PetConfig.GainCareXp): "Owl Lv 6 · Cuteness → Lv 8", "Owl Lv 6 · Cuteness XP 23 → 48/147",
-- "… · 600 XP wasted"
local function outcome(entry, food): string
	local pet = PetClient.State.pets[entry.uid]
	local copy = PetConfig.CopyForCare(pet)
	local trained, wasted = PetConfig.GainCareXp(copy, food.xp)
	local kind = string.format("<font color='%s'>%s</font>", hex(entry.rarity.color), Locale.PetKindName(entry.kind))
	local name = Locale.T("pet.nameLevel", { kind = kind, level = entry.level })
	local leveled = nil -- the last trait that gains a level
	for _, step in trained do
		if step.levels > 0 then
			leveled = step
		end
	end
	local text
	if leveled then
		text = Locale.T("food.outcome.levelUp", { name = name, trait = Locale.T("pet.apt." .. leveled.id), level = leveled.level })
	else
		local _, to = PetConfig.CareProgress(copy)
		text = Locale.T("food.outcome.xp", {
			name = name,
			trait = Locale.T("pet.apt." .. (entry.care or "Cuteness")),
			from = entry.xp,
			to = to,
			next = entry.xpNext,
		})
	end
	if wasted > 0 then
		text ..= "\n" .. Locale.T("food.wasted", { xp = wasted })
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
		foodTooltip.Hide()
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
	foodTooltip.ShowAt(info.button, table.concat(lines, "\n"))
end

local function disarm()
	if armed then
		setOutline(armed, false)
		armed = nil
		armTimer.Cancel()
		updateTooltip()
	end
end

local function arm(key: string)
	disarm()
	armed = key
	setOutline(key, true)
	updateTooltip()
	armTimer.After(ARM_SECONDS, disarm)
end

local function lastInputWasTouch(): boolean
	return UserInputService:GetLastInputType() == Enum.UserInputType.Touch
end

local function petRow(order: number, entry)
	local maxed = entry.care == nil -- P4: nothing left that food can train
	local foodsWidth = #GardenConfig.Foods * (FOOD_BUTTON_WIDTH + 4)
	local row = create("Frame", {
		Name = "Pet_" .. entry.uid,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, rowHeight),
		BackgroundColor3 = COLOR_ROW,
		BackgroundTransparency = if maxed then 0.35 else 0,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 8) }),
	})
	PetRow.Fill(row, entry, {
		portrait = rowPortrait,
		panelColor = COLOR_PANEL,
		right = foodsWidth + 6,
		highlight = entry.care, -- U1: the chip this food trains
		trainedTag = false, -- the tag stands where the food buttons would
		dim = maxed,
		tooltip = chipTooltip,
	})
	if maxed then
		label("MaxTag", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(foodsWidth - 4, 30),
			TextSize = 16,
			TextColor3 = Color3.fromRGB(255, 205, 60),
			TextXAlignment = Enum.TextXAlignment.Center,
			Text = Locale.T(if entry.level >= PetConfig.MaxLevel then "food.maxTag" else "food.doneTag"),
			Parent = row,
		})
		return row
	end
	for index, food in GardenConfig.Foods do
		local key = entry.uid .. ":" .. food.id
		local feedButton = button("Feed_" .. food.id, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -6 - (#GardenConfig.Foods - index) * (FOOD_BUTTON_WIDTH + 4), 0.5, 2),
			Size = UDim2.fromOffset(FOOD_BUTTON_WIDTH, buttonHeight),
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
				return flash(Locale.Reject("coins", REJECT_KEYS), COLOR_ERROR)
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

refresh = function()
	for _, row in rows do
		PetPortrait.Release(row) -- the portraits stay cached
		row:Destroy()
	end
	table.clear(rows)
	table.clear(buttons)
	if not (openStand and PetClient.State) then
		armed, hovered = nil, nil
		foodTooltip.Hide()
		return
	end
	chipTooltip.Hide()
	local inventory = PetClient.Inventory()
	filterBar.Refresh(inventory)
	local shown = filterBar.Filtered(inventory)
	-- U1: pets with you first, then the others that can still grow, then the ones food can't train (each group in inventory order);
	-- "Best for" keeps its own order (the trait's level)
	local grouped = filterBar.Filter() ~= "best"
	local function group(entry): number
		if not grouped then
			return 1
		end
		return if entry.care == nil then 3 elseif entry.equipped then 1 else 2
	end
	local count = 0
	for pass = 1, 3 do
		for _, entry in shown do
			if group(entry) == pass then
				count += 1
				local row = petRow(count, entry)
				row.Parent = list
				table.insert(rows, row)
			end
		end
	end
	emptyLabel.Visible = count == 0
	emptyLabel.Text = Locale.T(if #inventory == 0 then "food.empty" else "pets.filter.none")
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
	PanelFocus.Closed("Food")
	filterBar.HideMenu()
	openStand = nil
	panel.Visible = false
	refresh()
end

local function openPanel(stand: BasePart)
	PanelFocus.Open("Food", closePanel, CLOSE_DISTANCE, stand) -- U4: one panel at a time; walking away from the stand closes it
	openStand = stand
	armed, hovered = nil, nil
	fitToScreen()
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
	chipTooltip.Hide()
	hovered = nil
	disarm()
	foodTooltip.Hide()
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
		return flash(Locale.Reject(detail, REJECT_KEYS), COLOR_ERROR)
	end
	local food = GardenConfig.FoodById[detail.food]
	local pet = PetClient.State and PetClient.State.pets[detail.uid]
	local leveled = PetConfig.LastLevelUp(detail.trained)
	flash(
		Locale.T(if leveled then "food.fedLevelUp" else "food.fed", {
			icon = food and food.icon or "",
			kind = if pet then Locale.PetKindName(pet.Kind) else Locale.T("food.yourPet"),
			xp = detail.xp,
			trait = if leveled then Locale.T("pet.apt." .. leveled.id) else "",
			level = if leveled then leveled.level else detail.level,
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

GardenUi.BindStand(screenGui, GardenConfig.FoodStandName, openPanel)
screenGui.Parent = player:WaitForChild("PlayerGui")
