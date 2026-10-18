-- Pets panel (docs/GDD.md §7.3, §7.5): inventory, equip / unequip, buy slot, sell (two clicks), total Coin bonus.
-- Display only: the list comes from PetClient (PetRemotes.PetsChanged), so a hatch or a sale shows up while the panel
-- is open. A click just names a pet or the next slot; the server validates, prices and pays. The GUI is built here.
-- The 🐶 button (ButtonHandler) opens it through the SetOpen BindableEvent and reads the Open attribute.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))

local remotes = PetClient.Remotes
local player = Players.LocalPlayer

local WIDTH = 340
local HEIGHT = 470
local ROW_HEIGHT = 58
local CONFIRM_SECONDS = 3 -- how long "Sure?" waits for the second click
local POS_OPEN = UDim2.new(0, 10, 0, 80.3)
local POS_CLOSED = UDim2.new(0, -WIDTH - 20, 0, 80.3)

local COLOR_PANEL = Color3.fromRGB(40, 40, 40)
local COLOR_ROW = Color3.fromRGB(55, 55, 55)
local COLOR_BUY = Color3.fromRGB(60, 170, 70)
local COLOR_EQUIP = Color3.fromRGB(60, 120, 200)
local COLOR_LOCKED = Color3.fromRGB(110, 110, 110)
local COLOR_SELL = Color3.fromRGB(190, 80, 70)
local COLOR_INFO = Color3.fromRGB(190, 190, 190)
local COLOR_ERROR = Color3.fromRGB(240, 100, 90)
local COLOR_OK = Color3.fromRGB(120, 230, 120)

local REJECT_TEXT = {
	coins = "Not enough Coins",
	full = "Pet inventory is full",
	slots = "All slots in use: unequip a pet first",
	equipped = "Unequip it before selling",
	stale = "Out of date, try again",
	maxed = "All slots unlocked",
	loading = "Still loading...",
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
	props.Font = props.Font or Enum.Font.GothamBold
	props.TextColor3 = props.TextColor3 or Color3.new(1, 1, 1)
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	return create("TextLabel", props)
end

local function button(name: string, props)
	props.Name = name
	props.Font = Enum.Font.GothamBold
	props.TextColor3 = Color3.new(1, 1, 1)
	return create("TextButton", props, { create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
end

local titleLabel = label("Title", {
	Position = UDim2.new(0, 12, 0, 6),
	Size = UDim2.new(1, -60, 0, 26),
	TextSize = 20,
	Text = "🐶 Pets",
})
local closeButton = button("Close", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -8, 0, 6),
	Size = UDim2.fromOffset(30, 26),
	BackgroundColor3 = COLOR_LOCKED,
	TextSize = 16,
	Text = "X",
})
local summaryLabel = label("Summary", {
	Position = UDim2.new(0, 12, 0, 36),
	Size = UDim2.new(1, -24, 0, 20),
	TextSize = 15,
	RichText = true,
})
local slotButton = button("Slot", {
	Position = UDim2.new(0, 10, 0, 60),
	Size = UDim2.new(1, -20, 0, 32),
	TextSize = 15,
})
local infoLabel = label("Info", {
	Position = UDim2.new(0, 12, 0, 96),
	Size = UDim2.new(1, -24, 0, 20),
	Font = Enum.Font.Gotham,
	TextSize = 13,
	TextColor3 = COLOR_INFO,
	TextTruncate = Enum.TextTruncate.AtEnd,
})
local list = create("ScrollingFrame", {
	Name = "Inventory",
	Position = UDim2.new(0, 8, 0, 120),
	Size = UDim2.new(1, -16, 1, -128),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 5,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, {
	create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }),
	create("UIPadding", { PaddingRight = UDim.new(0, 6) }),
})
local emptyLabel = label("Empty", {
	Position = UDim2.new(0, 12, 0, 130),
	Size = UDim2.new(1, -24, 0, 60),
	Font = Enum.Font.Gotham,
	TextSize = 15,
	TextColor3 = COLOR_INFO,
	TextWrapped = true,
	Text = "No pets yet. Hatch one at the egg stand on the hub island!",
	Visible = false,
})

local panel = create("Frame", {
	Name = "Panel",
	Position = POS_CLOSED,
	Size = UDim2.fromOffset(WIDTH, HEIGHT),
	BackgroundColor3 = COLOR_PANEL,
	Visible = false,
}, {
	create("UICorner", { CornerRadius = UDim.new(0, 8) }),
	create("UIStroke", { Color = Color3.fromRGB(80, 80, 80), Thickness = 1 }),
	titleLabel,
	closeButton,
	summaryLabel,
	slotButton,
	infoLabel,
	list,
	emptyLabel,
})

local setOpenEvent = create("BindableEvent", { Name = "SetOpen" })
local screenGui = create("ScreenGui", {
	Name = "PetsGui",
	ResetOnSpawn = false,
	DisplayOrder = 4,
}, { panel, setOpenEvent })

local pendingSell: string? = nil -- uid waiting for the second click
local pendingToken = 0
local flashToken = 0
local flashing = false -- a message is showing: refresh leaves the info line alone
local rows = {} -- [uid] = row frame (rebuilt on every state change)

local refresh -- defined below; the sell confirmation timeout and the state listener call it

local function showInfo(text: string, color: Color3)
	infoLabel.Text = text
	infoLabel.TextColor3 = color
end

local function defaultInfo()
	local state = PetClient.State
	local waiting = 0
	if state then
		for _, count in state.freeEggs do
			waiting += count
		end
	end
	if waiting > 0 then
		showInfo(string.format("🎁 %d free egg%s waiting at the egg stand", waiting, if waiting == 1 then "" else "s"), COLOR_OK)
	else
		showInfo("Equipped pets raise every Coin reward", COLOR_INFO)
	end
end

local function flash(text: string, color: Color3)
	flashToken += 1
	flashing = true
	local mine = flashToken
	showInfo(text, color)
	task.delay(3, function()
		if flashToken == mine then
			flashing = false
			defaultInfo()
		end
	end)
end

local function clearPendingSell()
	pendingSell = nil
	pendingToken += 1
end

local function buildRow(index: number, pet)
	local rarityColor = pet.rarity.color
	local confirming = pendingSell == pet.uid

	local equipButton = button("Equip", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -6, 0, 5),
		Size = UDim2.fromOffset(84, 22),
		BackgroundColor3 = if pet.equipped then COLOR_LOCKED else COLOR_EQUIP,
		TextSize = 13,
		Text = if pet.equipped then "Unequip" else "Equip",
	})
	local sellButton = button("Sell", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -6, 1, -5),
		Size = UDim2.fromOffset(84, 22),
		BackgroundColor3 = if pet.equipped then COLOR_LOCKED elseif confirming then COLOR_SELL else COLOR_ROW,
		TextSize = 13,
		Text = (if confirming then "Sure? +" else "Sell ") .. PetClient.Number(pet.sellValue),
	})
	if not pet.equipped and not confirming then
		sellButton.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
	end

	local row = create("Frame", {
		Name = "Pet_" .. pet.uid,
		LayoutOrder = index,
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		BackgroundColor3 = COLOR_ROW,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 8) }),
		create("Frame", {
			Name = "RarityBar",
			Size = UDim2.new(0, 5, 1, -12),
			Position = UDim2.new(0, 6, 0, 6),
			BackgroundColor3 = rarityColor,
			BorderSizePixel = 0,
		}, { create("UICorner", { CornerRadius = UDim.new(0, 3) }) }),
		label("Name", {
			Position = UDim2.new(0, 18, 0, 5),
			Size = UDim2.new(1, -118, 0, 24),
			TextSize = 17,
			TextColor3 = rarityColor,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = string.format("%s  Lv %d", pet.kind, pet.level),
		}),
		label("Detail", {
			Position = UDim2.new(0, 18, 0, 30),
			Size = UDim2.new(1, -118, 0, 20),
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = COLOR_INFO,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = string.format(
				"%s · +%s%% · %s",
				pet.rarity.id,
				PetClient.Percent(pet.bonus),
				if pet.xpNext then string.format("%d/%d XP", pet.xp, pet.xpNext) else "max level"
			),
		}),
		equipButton,
		sellButton,
	})

	equipButton.Activated:Connect(function()
		clearPendingSell()
		if pet.equipped then
			remotes.Unequip:FireServer(pet.uid)
		else
			remotes.Equip:FireServer(pet.uid)
		end
	end)
	sellButton.Activated:Connect(function()
		if pet.equipped then
			flash(REJECT_TEXT.equipped, COLOR_ERROR)
			return
		end
		if pendingSell == pet.uid then
			clearPendingSell()
			remotes.SellPet:FireServer(pet.uid)
			return
		end
		pendingSell = pet.uid
		pendingToken += 1
		local mine = pendingToken
		task.delay(CONFIRM_SECONDS, function()
			if pendingToken == mine and pendingSell == pet.uid then
				clearPendingSell()
				refresh()
			end
		end)
		refresh()
	end)

	return row
end

refresh = function()
	local state = PetClient.State
	if not state then
		summaryLabel.Text = "Loading..."
		slotButton.Visible = false
		return
	end

	local inventory = PetClient.Inventory()
	if pendingSell and not state.pets[pendingSell] then
		clearPendingSell()
	end

	local equippedCount = #state.equipped
	summaryLabel.Text = string.format(
		"Coin bonus <font color='#78e678'>+%s%%</font>  ·  Equipped %d/%d  ·  Pets %d/%d",
		PetClient.Percent(math.round((state.multiplier - 1) * 1000)),
		equippedCount,
		state.slots,
		#inventory,
		PetConfig.MaxPets
	)

	slotButton.Visible = true
	local nextSlot = state.slots + 1
	local price = PetConfig.SlotPrices[nextSlot]
	if price then
		slotButton.Text = string.format("Buy slot %d: %s Coins", nextSlot, PetClient.Number(price))
		slotButton.BackgroundColor3 = if PetClient.Coins >= price then COLOR_BUY else COLOR_LOCKED
		slotButton.Active = true
	else
		slotButton.Text = string.format("All %d slots unlocked", state.slots)
		slotButton.BackgroundColor3 = COLOR_ROW
		slotButton.Active = false
	end

	for _, row in rows do
		row:Destroy()
	end
	table.clear(rows)
	for index, pet in inventory do
		local row = buildRow(index, pet)
		row.Parent = list
		rows[pet.uid] = row
	end
	emptyLabel.Visible = #inventory == 0
	if not flashing then
		defaultInfo()
	end
end

slotButton.Activated:Connect(function()
	local state = PetClient.State
	if state and PetConfig.SlotPrices[state.slots + 1] then
		remotes.BuySlot:FireServer(state.slots + 1)
	end
end)

PetClient.Result:Connect(function(action, ok, detail)
	if action == "BuyEgg" then
		return -- the egg stand shows the hatch
	end
	if ok then
		if action == "SellPet" then
			flash(string.format("Sold for %s Coins", PetClient.Number(detail.coins)), COLOR_OK)
		elseif action == "BuySlot" then
			flash(string.format("Slot %d unlocked", detail), COLOR_OK)
		end
	else
		flash(REJECT_TEXT[detail] or "Request failed", COLOR_ERROR)
	end
end)

-- Open / close (driven by the 🐾 button through SetOpen)
local function setOpen(open: boolean)
	if screenGui:GetAttribute("Open") == open then
		return
	end
	screenGui:SetAttribute("Open", open)
	if open then
		panel.Visible = true
		TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = POS_OPEN }):Play()
	else
		clearPendingSell()
		local tween = TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = POS_CLOSED })
		tween.Completed:Connect(function()
			if screenGui:GetAttribute("Open") ~= true then
				panel.Visible = false
			end
		end)
		tween:Play()
		refresh()
	end
end
screenGui:SetAttribute("Open", false)
setOpenEvent.Event:Connect(setOpen)
closeButton.Activated:Connect(function()
	setOpen(false)
end)

PetClient.Changed:Connect(refresh)
refresh()
screenGui.Parent = player:WaitForChild("PlayerGui")
