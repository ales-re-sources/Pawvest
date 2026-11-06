-- Pets panel (docs/GDD.md §7.3, §7.5; U1: docs/UI_GARDEN_PETS.md §9): inventory, equip / unequip, buy slot, total Coin bonus.
-- Display only: the list comes from PetClient (PetRemotes.PetsChanged), so a hatch or a sale shows up while the panel
-- is open. A click just names a pet or the next slot; the server validates, prices and pays. The GUI is built here.
-- The 🐶 button (ButtonHandler) opens it through the SetOpen BindableEvent and reads the Open attribute.
-- Stud-brick look (StudStyle, green like its icon). The way to the garden is the 🌱 HUD icon (U2, ButtonHandler).
-- Layout (U1): summary line ("Coin bonus +12 % · 2 cute pets with you"), filter chips (All n/50 · With me · On the field ·
-- Best for ▼ → a trait: pets with it, highest first; the choice holds for the session), the pet list, the equip slots as three
-- square bricks at the bottom (#PetConfig.SlotPrices): a slot shows its equipped pet (click = unequip), "Empty", or a lock; the
-- next slot to buy takes two clicks ("Sure?"), and hovering any slot shows a tooltip (price, whether it is affordable).
-- A row is PetRow's (portrait with level badge and status icon, name, trait chips with fills and ▲; hover / hold a chip for its
-- numbers) plus an Equip / Unequip brick and a Details › brick that opens the pet page (PetDetail, drawn over this panel). The rest
-- of the row does nothing (kids toggled pets while scrolling); selling is only on the pet page.
-- Width 460, capped to the viewport (16 px margins), scaled by PanelFit on short screens; compact layout there (messages
-- replace the summary line for a moment).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))
local PetPortrait = require(script.Parent:WaitForChild("PetPortrait"))
local PetDetail = require(script.Parent:WaitForChild("PetDetail"))
local PetRow = require(script.Parent:WaitForChild("PetRow"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local PanelFit = require(ReplicatedStorage:WaitForChild("PanelFit"))

local remotes = PetClient.Remotes
local player = Players.LocalPlayer

-- Short screens (a phone in landscape): the panel is scaled down (PanelFit) and shortened to what fits; the slot bricks
-- shrink and the list takes the rest (it scrolls). Tap targets stay at least 36 px on screen (44 at scale 1).
local FIT_SCALE = PanelFit.Scale()
local HEIGHT = math.clamp(PanelFit.MaxHeight(FIT_SCALE), 300, 560)
local COMPACT = HEIGHT < 480
local LEFT = 10 -- the panel's left edge, on the icons' line
local MARGIN = 16
local WIDTH = math.floor(math.min(460, (workspace.CurrentCamera.ViewportSize.X - LEFT - MARGIN) / FIT_SCALE))
local BRICK = math.max(44, math.ceil(36 / FIT_SCALE)) -- height of a tap target in panel pixels
local ROW_HEIGHT = math.max(64, BRICK + 12)
local EQUIP_WIDTH = 84
local DETAILS_WIDTH = 84
local SLOT_SIZE = if COMPACT then BRICK else 96
local SLOT_GAP = if COMPACT then 12 else 16
local SUMMARY_TOP = if COMPACT then 38 else 42
local FILTER_TOP = if COMPACT then 60 else 68
local INFO_TOP = FILTER_TOP + BRICK + 6 -- not compact
local LIST_TOP = if COMPACT then FILTER_TOP + BRICK + 6 else INFO_TOP + 24
local CONFIRM_SECONDS = 3 -- how long "Sure?" waits for the second click
local POS_OPEN = UDim2.new(0, LEFT, 0, 80.3)
local POS_CLOSED = UDim2.new(0, -WIDTH * FIT_SCALE - 20, 0, 80.3)

local COLOR_PANEL = StudStyle.PanelColors.PetsPanel
-- pet rows stay very dark so the rarity colours (green, blue, purple, gold names) read on the green panel
local COLOR_ROW = StudStyle.Shade(COLOR_PANEL, 0.28)
local COLOR_EQUIPPED = Color3.fromRGB(255, 205, 60) -- outline of an equipped row
local COLOR_BUY = StudStyle.Colors.Yellow
local COLOR_LOCKED = StudStyle.Colors.Grey
local COLOR_LOCKED_LATER = StudStyle.Shade(StudStyle.Colors.Grey, 0.7)
local COLOR_SLOT = Color3.fromRGB(214, 196, 158) -- owned slot: a sand plate, neutral behind any pet
local COLOR_CLOSE = StudStyle.Colors.Red
local COLOR_EQUIP = StudStyle.Colors.Yellow
local COLOR_UNEQUIP = StudStyle.Colors.Wood
local COLOR_DETAILS = StudStyle.Colors.Blue
local COLOR_FILTER = StudStyle.Shade(COLOR_PANEL, 0.7)
local COLOR_FILTER_ON = StudStyle.Colors.Yellow
local COLOR_INFO = Color3.fromRGB(190, 190, 190)
local COLOR_ERROR = Color3.fromRGB(240, 100, 90)
local COLOR_OK = Color3.fromRGB(120, 230, 120)

local REJECT_KEYS = {
	coins = "common.reject.coins",
	full = "pets.reject.full",
	slots = "pets.reject.slots",
	equipped = "pets.reject.equipped",
	field = "pets.reject.field",
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
	BackgroundColor3 = COLOR_CLOSE,
	TextSize = 16,
	Text = "X",
}, 1)
local summaryLabel = label("Summary", {
	Position = UDim2.new(0, 12, 0, SUMMARY_TOP),
	Size = UDim2.new(1, -24, 0, 20),
	TextSize = 15,
	RichText = true,
	TextTruncate = Enum.TextTruncate.AtEnd,
})
local infoLabel = label("Info", {
	Position = UDim2.new(0, 12, 0, INFO_TOP),
	Size = UDim2.new(1, -24, 0, 20),
	Font = Enum.Font.Gotham,
	TextSize = 13,
	TextColor3 = COLOR_INFO,
	TextTruncate = Enum.TextTruncate.AtEnd,
	Visible = not COMPACT, -- compact: messages show on the summary line
})
local SLOTS_TOP = HEIGHT - 10 - SLOT_SIZE -- top of the slot bricks
local list = create("ScrollingFrame", {
	Name = "Inventory",
	Position = UDim2.new(0, 8, 0, LIST_TOP),
	Size = UDim2.new(1, -16, 0, SLOTS_TOP - (if COMPACT then 6 else 30) - LIST_TOP), -- compact: no "Equipped pets" title
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 5,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, {
	create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }),
	create("UIPadding", { PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 4) }),
})
local emptyLabel = label("Empty", {
	Position = UDim2.new(0, 12, 0, LIST_TOP + 10),
	Size = UDim2.new(1, -24, 0, 60),
	Font = Enum.Font.Gotham,
	TextSize = 15,
	TextColor3 = COLOR_INFO,
	TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Top,
	Visible = false,
})
local slotsLabel = label("SlotsTitle", {
	Position = UDim2.new(0, 12, 0, SLOTS_TOP - 28),
	Size = UDim2.new(1, -24, 0, 18),
	TextSize = 15,
	Visible = not COMPACT,
})
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
	infoLabel,
	list,
	emptyLabel,
	slotsLabel,
	tooltip,
})
StudStyle.Panel(panel, COLOR_PANEL)
if FIT_SCALE < 1 then
	create("UIScale", { Scale = FIT_SCALE, Parent = panel })
end
local chipTooltip = PetRow.Tooltip(panel, COLOR_PANEL)
local setOpen -- defined below; the detail page's X closes the whole panel
local detail = PetDetail.Mount(panel, COLOR_PANEL, function()
	setOpen(false)
end)

local setOpenEvent = create("BindableEvent", { Name = "SetOpen" })
local screenGui = create("ScreenGui", {
	Name = "PetsGui",
	ResetOnSpawn = false,
	DisplayOrder = 4,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	AutoLocalize = false, -- translated by Locale (L2)
}, { panel, setOpenEvent })

local pendingSlot: number? = nil -- slot waiting for the second click
local pendingToken = 0
local flashToken = 0
local flashing = false -- a message is showing: refresh leaves the info line alone
local rows = {} -- [uid] = row frame (rebuilt on every state change)
local filter = "all" -- "all" | "with" | "field" | "best" (kept for the session)
local bestTrait = "Cuteness" -- the trait of "Best for"

local refresh -- defined below; the confirmation timeouts and the state listener call it
local summaryText = "" -- compact: the summary comes back after a message

local function showInfo(text: string, color: Color3)
	if COMPACT then
		summaryLabel.Text = text
		summaryLabel.TextColor3 = color
	else
		infoLabel.Text = text
		infoLabel.TextColor3 = color
	end
end

local function defaultInfo()
	if COMPACT then
		summaryLabel.Text = summaryText
		summaryLabel.TextColor3 = Color3.new(1, 1, 1)
		return
	end
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

-- Filter chips --------------------------------------------------------------------------------------------------------
local FILTERS = { "all", "with", "field", "best" }
local filterRight = 10
local filterWidth = math.floor((WIDTH - 10 - filterRight - 6 * (#FILTERS - 1)) / #FILTERS)
local filterButtons = {}
for index, id in FILTERS do
	local chip = button("Filter_" .. id, {
		Position = UDim2.fromOffset(10 + (index - 1) * (filterWidth + 6), FILTER_TOP),
		Size = UDim2.fromOffset(filterWidth, BRICK),
		BackgroundColor3 = COLOR_FILTER,
		TextSize = 14,
		TextWrapped = true,
	}, 2)
	chip.Parent = panel
	filterButtons[id] = chip
end

-- "Best for ▼" opens a list of the traits under its chip
local bestMenu = create("Frame", {
	Name = "BestMenu",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.fromOffset(WIDTH - filterRight, FILTER_TOP + BRICK + 4),
	Size = UDim2.fromOffset(180, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = StudStyle.Shade(COLOR_PANEL, 0.2),
	ZIndex = 12,
	Visible = false,
	Parent = panel,
}, {
	create("UICorner", { CornerRadius = UDim.new(0, 8) }),
	create("UIStroke", { Color = COLOR_EQUIPPED, Thickness = 2 }),
	create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }),
	create("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
	}),
})
local bestOptions = {}
for order, trait in PetRow.Traits do
	local option = button("Best_" .. trait.id, {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, BRICK),
		BackgroundColor3 = COLOR_FILTER,
		TextSize = 15,
		ZIndex = 13,
	}, 3)
	option.Parent = bestMenu
	bestOptions[trait.id] = option
end

local function traitWord(id: string): string
	return if id == "Cuteness" then Locale.T("pets.filter.coins") else Locale.T("pet.apt." .. id)
end

-- texts that do not depend on the pet state (set again when the language changes)
local function staticTexts()
	titleLabel.Text = Locale.T("pets.title")
	slotsLabel.Text = Locale.T("pets.slotsTitle")
	filterButtons.with.Text = Locale.T("pets.filter.withMe")
	filterButtons.field.Text = Locale.T("pets.filter.field")
	for id, option in bestOptions do
		option.Text = PetRow.ByTrait[id].icon .. " " .. traitWord(id)
	end
end
staticTexts()

local function setFilter(id: string)
	filter = id
	list.CanvasPosition = Vector2.zero
	refresh()
end

for id, chip in filterButtons do
	chip.Activated:Connect(function()
		chipTooltip.Hide()
		if id == "best" then
			bestMenu.Visible = not bestMenu.Visible
			return
		end
		bestMenu.Visible = false
		setFilter(id)
	end)
end
for id, option in bestOptions do
	option.Activated:Connect(function()
		bestMenu.Visible = false
		bestTrait = id
		setFilter("best")
	end)
end

-- the pets the filter shows, in its order: inventory order, or (Best for) the trait's level, highest first
local function filtered(inventory)
	local state = PetClient.State
	local shown = {}
	for index, pet in inventory do
		local keep = filter == "all"
			or (filter == "with" and pet.equipped)
			or (filter == "field" and pet.field ~= nil)
			or (filter == "best" and PetConfig.AptitudeLevel(state.pets[pet.uid], bestTrait) > 0)
		if keep then
			table.insert(shown, { pet = pet, index = index })
		end
	end
	if filter == "best" then
		table.sort(shown, function(a, b)
			local la = PetConfig.AptitudeLevel(state.pets[a.pet.uid], bestTrait)
			local lb = PetConfig.AptitudeLevel(state.pets[b.pet.uid], bestTrait)
			if la ~= lb then
				return la > lb
			end
			return a.index < b.index
		end)
	end
	local pets = {}
	for _, item in shown do
		table.insert(pets, item.pet)
	end
	return pets
end

local function refreshFilters(inventory)
	filterButtons.all.Text = Locale.T("pets.filter.all", { count = #inventory, max = PetConfig.MaxPets })
	local picked = filter == "best"
	filterButtons.best.Text = if picked
		then Locale.T("pets.filter.bestTrait", { icon = PetRow.ByTrait[bestTrait].icon, trait = traitWord(bestTrait) })
		else Locale.T("pets.filter.best")
	for id, chip in filterButtons do
		chip.BackgroundColor3 = if filter == id then COLOR_FILTER_ON else COLOR_FILTER
	end
	for id, option in bestOptions do
		option.BackgroundColor3 = if filter == "best" and bestTrait == id then COLOR_FILTER_ON else COLOR_FILTER
	end
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
		local name = string.format("<font color='#%s'>%s</font>", pet.rarity.color:ToHex(), Locale.PetName(pet.kind, pet.level, pet.name))
		if pet.cute == 0 then -- P4: only a pet with Cuteness raises the Coins
			return Locale.T("pets.slot.petNoBonus", { name = name })
		end
		return Locale.T("pets.slot.pet", { name = name, bonus = bonusText(pet.bonus) })
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
		bestMenu.Visible = false
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
			slot.caption.Text = Locale.PetName(pet.kind, pet.level, pet.name)
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
local function onEquipClicked(pet)
	clearPending()
	bestMenu.Visible = false
	if pet.field then
		flash(rejectText("field"), COLOR_ERROR)
	elseif pet.equipped then
		remotes.Unequip:FireServer(pet.uid)
	elseif PetClient.State and equippedCount() >= PetClient.State.slots then
		flash(rejectText("slots"), COLOR_ERROR)
	else
		remotes.Equip:FireServer(pet.uid)
	end
end

local function buildRow(index: number, pet)
	local busy = pet.field ~= nil
	local row = create("Frame", {
		Name = "Pet_" .. pet.uid,
		LayoutOrder = index,
		Size = UDim2.new(1, -2, 0, ROW_HEIGHT),
		BackgroundColor3 = COLOR_ROW,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 8) }),
		create("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = COLOR_EQUIPPED,
			Thickness = 2,
			Enabled = pet.equipped,
		}),
	})
	PetRow.Fill(row, pet, {
		portrait = listPortrait,
		panelColor = COLOR_PANEL,
		right = EQUIP_WIDTH + DETAILS_WIDTH + 18,
		tooltip = chipTooltip,
	})
	local equipButton = button("Equip", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -(DETAILS_WIDTH + 12), 0.5, 0),
		Size = UDim2.fromOffset(EQUIP_WIDTH, BRICK),
		BackgroundColor3 = if busy then COLOR_LOCKED elseif pet.equipped then COLOR_UNEQUIP else COLOR_EQUIP,
		TextSize = 15,
		TextWrapped = true,
		Text = Locale.T(if pet.equipped then "petDetail.unequip" else "petDetail.equip"),
	}, 2)
	equipButton.Parent = row
	local detailsButton = button("Details", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.fromOffset(DETAILS_WIDTH, BRICK),
		BackgroundColor3 = COLOR_DETAILS,
		TextSize = 15,
		TextWrapped = true,
		Text = Locale.T("pets.details"),
	}, 2)
	detailsButton.Parent = row
	equipButton.Activated:Connect(function()
		onEquipClicked(pet)
	end)
	detailsButton.Activated:Connect(function()
		clearPending()
		bestMenu.Visible = false
		chipTooltip.Hide()
		detail.Open(pet.uid)
	end)
	return row
end

refresh = function()
	local state = PetClient.State
	if not state then
		summaryText = Locale.T("common.loading")
		summaryLabel.Text = summaryText
		refreshSlots({})
		return
	end

	local inventory = PetClient.Inventory()
	if pendingSlot and pendingSlot ~= state.slots + 1 then
		clearPending()
	end

	-- P4: only cute pets raise the Coins: name how many of the pets with you do
	local cute = 0
	for _, uid in state.equipped do
		local stored = state.pets[uid]
		if stored and PetConfig.AptitudeLevel(stored, "Cuteness") > 0 then
			cute += 1
		end
	end
	summaryText = Locale.T("pets.summaryCute", { bonus = bonusText(math.round((state.multiplier - 1) * 1000)), count = cute })
	if not (COMPACT and flashing) then
		summaryLabel.Text = summaryText
		summaryLabel.TextColor3 = Color3.new(1, 1, 1)
	end
	refreshFilters(inventory)

	chipTooltip.Hide()
	for _, row in rows do
		PetPortrait.Release(row) -- the portraits stay cached
		row:Destroy()
	end
	table.clear(rows)
	local shown = filtered(inventory)
	for index, pet in shown do
		local row = buildRow(index, pet)
		row.Parent = list
		rows[pet.uid] = row
	end
	emptyLabel.Visible = #shown == 0
	emptyLabel.Text = Locale.T(if #inventory == 0 then "pets.empty" else "pets.filter.none")
	refreshSlots(inventory)
	if not flashing then
		defaultInfo()
	end
end

-- the chip tooltip sits over a row inside the scrolling list: scrolling would leave it behind
list:GetPropertyChangedSignal("CanvasPosition"):Connect(chipTooltip.Hide)

PetClient.Result:Connect(function(action, ok, detailOrReason)
	if ok then
		if action == "SellPet" then
			flash(Locale.T("pets.sold", { count = detailOrReason.coins }), COLOR_OK)
		elseif action == "BuySlot" then
			flash(Locale.T("pets.slotUnlocked", { slot = detailOrReason }), COLOR_OK)
		end
	else
		flash(rejectText(detailOrReason), COLOR_ERROR)
	end
end)

Locale.Changed:Connect(function()
	staticTexts()
	refresh()
end)

-- Open / close (driven by the 🐾 button through SetOpen)
function setOpen(open: boolean)
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
		bestMenu.Visible = false
		chipTooltip.Hide()
		detail.Close()
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
