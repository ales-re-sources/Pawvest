-- Pets panel (docs/GDD.md §7.3, §7.5): inventory, equip / unequip, buy slot, sell (two clicks), total Coin bonus.
-- Display only: the list comes from PetClient (PetRemotes.PetsChanged), so a hatch or a sale shows up while the panel
-- is open. A click just names a pet or the next slot; the server validates, prices and pays. The GUI is built here.
-- The 🐶 button (ButtonHandler) opens it through the SetOpen BindableEvent and reads the Open attribute.
-- Stud-brick look (StudStyle, green like its icon); "Go to my garden" asks the server (GoGarden, HomeService) to put
-- the player in front of their garden plot.
-- Layout: pet list on top (click a row = equip it, click an equipped one = unequip it), the equip slots as three square
-- bricks at the bottom (#PetConfig.SlotPrices): a slot shows its equipped pet (click = unequip), "Empty", or a lock;
-- the next slot to buy takes two clicks ("Sure?"), and hovering any slot shows a tooltip (price, whether it is
-- affordable). Equipped pets fill the slots in PetsChanged.equipped order. Pet portraits come from PetPortrait (one
-- cache for the rows, one for the slots).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))
local PetPortrait = require(script.Parent:WaitForChild("PetPortrait"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))

local remotes = PetClient.Remotes
local player = Players.LocalPlayer

local WIDTH = 340
local HEIGHT = 560
local ROW_HEIGHT = 66
local SLOT_SIZE = 96
local SLOT_GAP = 16
local CONFIRM_SECONDS = 3 -- how long "Sure?" waits for the second click
local POS_OPEN = UDim2.new(0, 10, 0, 80.3)
local POS_CLOSED = UDim2.new(0, -WIDTH - 20, 0, 80.3)

local COLOR_PANEL = StudStyle.PanelColors.PetsPanel
-- pet rows stay very dark so the rarity colours (green, blue, purple, gold names) read on the green panel
local COLOR_ROW = StudStyle.Shade(COLOR_PANEL, 0.28)
local COLOR_ROW_HOVER = StudStyle.Shade(COLOR_PANEL, 0.38)
local COLOR_EQUIPPED = Color3.fromRGB(255, 205, 60) -- outline of an equipped row and its tag
local COLOR_BUY = StudStyle.Colors.Yellow
local COLOR_LOCKED = StudStyle.Colors.Grey
local COLOR_LOCKED_LATER = StudStyle.Shade(StudStyle.Colors.Grey, 0.7)
local COLOR_SLOT = Color3.fromRGB(214, 196, 158) -- owned slot: a sand plate, neutral behind any pet
local COLOR_SELL = StudStyle.Colors.Red
local COLOR_SELL_IDLE = StudStyle.Colors.Wood
local COLOR_GARDEN = StudStyle.Colors.Wood
local COLOR_INFO = Color3.fromRGB(190, 190, 190)
local COLOR_ERROR = Color3.fromRGB(240, 100, 90)
local COLOR_OK = Color3.fromRGB(120, 230, 120)

local REJECT_KEYS = {
	coins = "common.reject.coins",
	full = "pets.reject.full",
	slots = "pets.reject.slots",
	equipped = "pets.reject.equipped",
	penned = "pets.reject.penned",
	stale = "common.reject.stale",
	maxed = "pets.reject.maxed",
	loading = "common.reject.loading",
}

local function rejectText(reason: string?): string
	return Locale.T(reason and REJECT_KEYS[reason] or "common.reject.failed")
end

-- "+4.5%" in the player's language
local function bonusText(permille: number): string
	return Locale.T("common.percentBonus", { pct = Locale.Decimal(PetClient.Percent(permille)) })
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

-- Pet portraits -------------------------------------------------------------------------------------------------------
local listPortrait = PetPortrait.Cache()
local slotPortrait = PetPortrait.Cache()

-- Panel ---------------------------------------------------------------------------------------------------------------
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
	BackgroundColor3 = COLOR_SELL,
	TextSize = 16,
	Text = "X",
}, 1)
local summaryLabel = label("Summary", {
	Position = UDim2.new(0, 12, 0, 42),
	Size = UDim2.new(1, -24, 0, 20),
	TextSize = 15,
	RichText = true,
})
local gardenButton = button("Garden", {
	Position = UDim2.new(0, 10, 0, 70),
	Size = UDim2.new(1, -20, 0, 34),
	BackgroundColor3 = COLOR_GARDEN,
	TextSize = 16,
}, 6)
local infoLabel = label("Info", {
	Position = UDim2.new(0, 12, 0, 110),
	Size = UDim2.new(1, -24, 0, 20),
	Font = Enum.Font.Gotham,
	TextSize = 13,
	TextColor3 = COLOR_INFO,
	TextTruncate = Enum.TextTruncate.AtEnd,
})
local SLOTS_TOP = HEIGHT - 10 - SLOT_SIZE -- top of the slot bricks
local LIST_TOP = 134
local list = create("ScrollingFrame", {
	Name = "Inventory",
	Position = UDim2.new(0, 8, 0, LIST_TOP),
	Size = UDim2.new(1, -16, 0, SLOTS_TOP - 30 - LIST_TOP),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 5,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, {
	create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }),
	create("UIPadding", { PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2) }),
})
local emptyLabel = label("Empty", {
	Position = UDim2.new(0, 12, 0, LIST_TOP + 10),
	Size = UDim2.new(1, -24, 0, 60),
	Font = Enum.Font.Gotham,
	TextSize = 15,
	TextColor3 = COLOR_INFO,
	TextWrapped = true,
	Visible = false,
})
local slotsLabel = label("SlotsTitle", {
	Position = UDim2.new(0, 12, 0, SLOTS_TOP - 28),
	Size = UDim2.new(1, -24, 0, 18),
	TextSize = 15,
})

-- texts that do not depend on the pet state (set again when the language changes)
local function staticTexts()
	titleLabel.Text = Locale.T("pets.title")
	gardenButton.Text = Locale.T("pets.garden")
	emptyLabel.Text = Locale.T("pets.empty")
	slotsLabel.Text = Locale.T("pets.slotsTitle")
end
staticTexts()
local tooltip = label("Tooltip", {
	AnchorPoint = Vector2.new(0.5, 1),
	Size = UDim2.fromOffset(190, 44),
	BackgroundTransparency = 0,
	BackgroundColor3 = StudStyle.Shade(COLOR_PANEL, 0.2),
	TextSize = 14,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Center,
	RichText = true,
	ZIndex = 10,
	Visible = false,
})
tooltip.BackgroundTransparency = 0 -- label() makes labels transparent
create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = tooltip })
create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = COLOR_EQUIPPED, Thickness = 2, Parent = tooltip })

local panel = create("Frame", {
	Name = "Panel",
	Position = POS_CLOSED,
	Size = UDim2.fromOffset(WIDTH, HEIGHT),
	Visible = false,
}, {
	titleLabel,
	closeButton,
	summaryLabel,
	gardenButton,
	infoLabel,
	list,
	emptyLabel,
	slotsLabel,
	tooltip,
})
StudStyle.Panel(panel, COLOR_PANEL)

local setOpenEvent = create("BindableEvent", { Name = "SetOpen" })
local screenGui = create("ScreenGui", {
	Name = "PetsGui",
	ResetOnSpawn = false,
	DisplayOrder = 4,
	AutoLocalize = false, -- translated by Locale (L2)
}, { panel, setOpenEvent })

local pendingSell: string? = nil -- uid waiting for the second click
local pendingSlot: number? = nil -- slot waiting for the second click
local pendingToken = 0
local flashToken = 0
local flashing = false -- a message is showing: refresh leaves the info line alone
local rows = {} -- [uid] = row frame (rebuilt on every state change)

local refresh -- defined below; the confirmation timeouts and the state listener call it

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
		showInfo(Locale.T("pets.freeEggs", { count = waiting }), COLOR_OK)
	else
		showInfo(Locale.T("pets.hint"), COLOR_INFO)
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

local function clearPending()
	pendingSell = nil
	pendingSlot = nil
	pendingToken += 1
end

-- arms a two-click confirmation; it lapses after CONFIRM_SECONDS
local function armPending()
	pendingToken += 1
	local mine = pendingToken
	task.delay(CONFIRM_SECONDS, function()
		if pendingToken == mine then
			clearPending()
			refresh()
		end
	end)
end

local function equippedCount(): number
	return if PetClient.State then #PetClient.State.equipped else 0
end

-- Equip slots ---------------------------------------------------------------------------------------------------------
local slotCount = #PetConfig.SlotPrices
local slots = {} -- [index] = { button, face, caption, kind = "pet" | "empty" | "buy" | "locked", pet? }
local hoveredSlot: number? = nil

local function slotTooltip(index: number): string?
	local slot = slots[index]
	local state = PetClient.State
	if not state then
		return nil
	end
	if slot.kind == "pet" then
		local pet = slot.pet
		return Locale.T("pets.slot.pet", {
			name = string.format("<font color='#%s'>%s</font>", pet.rarity.color:ToHex(), Locale.PetName(pet.kind, pet.level)),
			bonus = bonusText(pet.bonus),
		})
	elseif slot.kind == "empty" then
		return Locale.T("pets.slot.free")
	end
	local price = PetConfig.SlotPrices[index]
	local head = Locale.T("pets.slot.price", { slot = index, count = price })
	if slot.kind == "locked" then
		return head .. "\n" .. Locale.T("pets.slot.buyFirst", { slot = state.slots + 1 })
	elseif PetClient.Coins >= price then
		return head .. "\n" .. Locale.T("pets.slot.canBuy")
	end
	return head .. "\n" .. Locale.T("common.needMoreCoins", { count = price - PetClient.Coins })
end

local function updateTooltip()
	local text = hoveredSlot and slotTooltip(hoveredSlot)
	tooltip.Visible = text ~= nil
	if text then
		tooltip.Text = text
		local slotButton = slots[hoveredSlot].button
		tooltip.Position = UDim2.fromOffset(slotButton.Position.X.Offset + SLOT_SIZE / 2, SLOTS_TOP - 10)
	end
end

for index = 1, slotCount do
	local slotButton = button("Slot" .. index, {
		Position = UDim2.fromOffset(10 + (index - 1) * (SLOT_SIZE + SLOT_GAP), SLOTS_TOP),
		Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE),
		BackgroundColor3 = COLOR_LOCKED,
		TextSize = 20,
	}, 3)
	local face = slotButton:FindFirstChild("Face", true) :: Frame
	local caption = label("Caption", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -3),
		Size = UDim2.new(1, -8, 0, 16),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.3,
		ZIndex = 3,
	})
	caption.Parent = face
	slots[index] = { button = slotButton, face = face, caption = caption, kind = "locked" }
	slotButton.Parent = panel

	slotButton.MouseEnter:Connect(function()
		hoveredSlot = index
		updateTooltip()
	end)
	slotButton.MouseLeave:Connect(function()
		if hoveredSlot == index then
			hoveredSlot = nil
			updateTooltip()
		end
	end)
	slotButton.Activated:Connect(function()
		local slot = slots[index]
		local state = PetClient.State
		if not state then
			return
		end
		if slot.kind == "pet" then
			clearPending()
			remotes.Unequip:FireServer(slot.pet.uid)
		elseif slot.kind == "empty" then
			flash(Locale.T("pets.slot.equipHint"), COLOR_INFO)
		elseif slot.kind == "locked" then
			flash(Locale.T("pets.slot.buyFirst", { slot = state.slots + 1 }), COLOR_ERROR)
		elseif PetClient.Coins < PetConfig.SlotPrices[index] then
			flash(rejectText("coins"), COLOR_ERROR)
		elseif pendingSlot == index then
			clearPending()
			remotes.BuySlot:FireServer(index)
		else
			clearPending()
			pendingSlot = index
			armPending()
		end
		refresh()
		hoveredSlot = index -- a tap on a touch screen shows the tooltip too
		updateTooltip()
	end)
end

local function refreshSlots(inventory)
	local state = PetClient.State
	local byUid = {}
	for _, pet in inventory do
		byUid[pet.uid] = pet
	end
	for index, slot in slots do
		local pet = state and index <= state.slots and byUid[state.equipped[index]]
		local old = slot.face:FindFirstChild("Portrait")
		if old then
			old.Parent = nil -- kept in the cache
		end
		slot.pet = pet or nil
		if not state then
			slot.kind = "locked"
		elseif pet then
			slot.kind = "pet"
		elseif index <= state.slots then
			slot.kind = "empty"
		elseif index == state.slots + 1 then
			slot.kind = "buy"
		else
			slot.kind = "locked"
		end

		local b = slot.button
		if slot.kind == "pet" then
			b.BackgroundColor3 = COLOR_SLOT
			b.Text = ""
			slot.caption.Text = Locale.PetName(pet.kind, pet.level)
			slot.caption.TextColor3 = Color3.new(1, 1, 1) -- rarity colours (Common grey) are too faint on the sand plate
			local portrait = slotPortrait(pet)
			if portrait then
				portrait.Size = UDim2.new(1, 0, 1, -14) -- leaves the caption line free
				portrait.Parent = slot.face
			end
		elseif slot.kind == "empty" then
			b.BackgroundColor3 = COLOR_SLOT
			b.Text = Locale.T("pets.slot.empty")
			slot.caption.Text = ""
		elseif slot.kind == "buy" then
			local price = PetConfig.SlotPrices[index]
			b.BackgroundColor3 = if PetClient.Coins >= price then COLOR_BUY else COLOR_LOCKED
			b.Text = Locale.T(if pendingSlot == index then "pets.slot.sure" else "pets.slot.buy")
			slot.caption.Text = if pendingSlot == index then Locale.Number(price) else ""
			slot.caption.TextColor3 = Color3.new(1, 1, 1)
		else
			b.BackgroundColor3 = COLOR_LOCKED_LATER
			b.Text = "🔒"
			slot.caption.Text = ""
		end
	end
	updateTooltip()
end

-- Pet list ------------------------------------------------------------------------------------------------------------
local function onRowClicked(pet)
	clearPending()
	if pet.penned then
		flash(rejectText("penned"), COLOR_ERROR)
	elseif pet.equipped then
		remotes.Unequip:FireServer(pet.uid)
	elseif PetClient.State and equippedCount() >= PetClient.State.slots then
		flash(rejectText("slots"), COLOR_ERROR)
	else
		remotes.Equip:FireServer(pet.uid)
	end
	refresh()
end

local function buildRow(index: number, pet)
	local rarityColor = pet.rarity.color
	local confirming = pendingSell == pet.uid

	local sellButton = button("Sell", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -6, 1, -6),
		Size = UDim2.fromOffset(84, 24),
		BackgroundColor3 = if pet.equipped or pet.penned then COLOR_LOCKED elseif confirming then COLOR_SELL else COLOR_SELL_IDLE,
		TextSize = 13,
		Text = Locale.T(if confirming then "pets.sellSure" else "pets.sell", { price = pet.sellValue }),
	})
	local tagText = if pet.penned
		then Locale.T("pets.tag.pen", { pen = pet.penned })
		elseif pet.equipped then Locale.T("pets.tag.equipped")
		else ""
	local portraitHolder = create("Frame", {
		Name = "PortraitHolder",
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.fromOffset(54, 54),
		BackgroundColor3 = StudStyle.Shade(COLOR_PANEL, 0.18),
	}, { create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	local portrait = listPortrait(pet)
	if portrait then
		portrait.Parent = portraitHolder
	end

	local row = create("TextButton", {
		Name = "Pet_" .. pet.uid,
		LayoutOrder = index,
		Size = UDim2.new(1, -2, 0, ROW_HEIGHT),
		BackgroundColor3 = COLOR_ROW,
		AutoButtonColor = false,
		Text = "",
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 8) }),
		create("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = COLOR_EQUIPPED,
			Thickness = 2,
			Enabled = pet.equipped,
		}),
		create("Frame", {
			Name = "RarityBar",
			Size = UDim2.new(0, 4, 1, -12),
			Position = UDim2.new(0, 4, 0, 6),
			BackgroundColor3 = rarityColor,
			BorderSizePixel = 0,
		}, { create("UICorner", { CornerRadius = UDim.new(0, 2) }) }),
		portraitHolder,
		label("Name", {
			Position = UDim2.new(0, 74, 0, 7),
			Size = UDim2.new(1, -170, 0, 22),
			TextSize = 17,
			TextColor3 = rarityColor,
			TextStrokeTransparency = 0.4,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = Locale.PetName(pet.kind, pet.level),
		}),
		label("Detail", {
			Position = UDim2.new(0, 74, 0, 30),
			Size = UDim2.new(1, -170, 0, 30),
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = COLOR_INFO,
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			Text = Locale.T("pets.detail", { rarity = Locale.RarityName(pet.rarity.id), bonus = bonusText(pet.bonus) })
				.. "\n"
				.. if pet.xpNext then Locale.T("pet.xp", { xp = pet.xp, next = pet.xpNext }) else Locale.T("pet.maxLevel"),
		}),
		label("Tag", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -8, 0, 8),
			Size = UDim2.fromOffset(84, 20),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextColor3 = if pet.equipped then COLOR_EQUIPPED else COLOR_INFO,
			Text = tagText,
		}),
		sellButton,
	})

	row.MouseEnter:Connect(function()
		row.BackgroundColor3 = COLOR_ROW_HOVER
	end)
	row.MouseLeave:Connect(function()
		row.BackgroundColor3 = COLOR_ROW
	end)
	row.Activated:Connect(function()
		onRowClicked(pet)
	end)
	sellButton.Activated:Connect(function()
		if pet.penned then
			flash(rejectText("penned"), COLOR_ERROR)
			return
		end
		if pet.equipped then
			flash(rejectText("equipped"), COLOR_ERROR)
			return
		end
		if pendingSell == pet.uid then
			clearPending()
			remotes.SellPet:FireServer(pet.uid)
			return
		end
		clearPending()
		pendingSell = pet.uid
		armPending()
		refresh()
	end)

	return row
end

refresh = function()
	local state = PetClient.State
	if not state then
		summaryLabel.Text = Locale.T("common.loading")
		refreshSlots({})
		return
	end

	local inventory = PetClient.Inventory()
	if pendingSell and not state.pets[pendingSell] then
		clearPending()
	end
	if pendingSlot and pendingSlot ~= state.slots + 1 then
		clearPending()
	end

	summaryLabel.Text = Locale.T("pets.summary", {
		bonus = bonusText(math.round((state.multiplier - 1) * 1000)),
		equipped = #state.equipped,
		slots = state.slots,
		pets = #inventory,
		max = PetConfig.MaxPets,
	})

	for _, row in rows do
		local portrait = row:FindFirstChild("Portrait", true)
		if portrait then
			portrait.Parent = nil -- kept in the cache
		end
		row:Destroy()
	end
	table.clear(rows)
	for index, pet in inventory do
		local row = buildRow(index, pet)
		row.Parent = list
		rows[pet.uid] = row
	end
	emptyLabel.Visible = #inventory == 0
	refreshSlots(inventory)
	if not flashing then
		defaultInfo()
	end
end

PetClient.Result:Connect(function(action, ok, detail)
	if ok then
		if action == "SellPet" then
			flash(Locale.T("pets.sold", { count = detail.coins }), COLOR_OK)
		elseif action == "BuySlot" then
			flash(Locale.T("pets.slotUnlocked", { slot = detail }), COLOR_OK)
		end
	else
		flash(rejectText(detail), COLOR_ERROR)
	end
end)

Locale.Changed:Connect(function()
	staticTexts()
	refresh()
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
		clearPending()
		hoveredSlot = nil
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

gardenButton.Activated:Connect(function()
	if player:GetAttribute("GardenPlot") == nil then
		flash(Locale.T("pets.gardenNotReady"), COLOR_ERROR)
		return
	end
	local goGarden = ReplicatedStorage:FindFirstChild("GoGarden")
	if goGarden then
		goGarden:FireServer()
		setOpen(false)
	end
end)

PetClient.Changed:Connect(refresh)
refresh()
screenGui.Parent = player:WaitForChild("PlayerGui")
