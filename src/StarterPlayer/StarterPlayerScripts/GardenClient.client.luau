-- Garden client (docs/GDD.md §7.6): pen prompts on the player's own plot, the pen panel (unlock a pen, place a pet, remove it),
-- the "welcome back" announcement after the join payout (top centre, fades out after 5 s, nothing to close) and a small
-- toast for online payouts.
-- Display only: a click just names a pen and a pet; GardenService validates ownership, price and time. The prompts of other
-- players' plots are switched off locally (the server rejects them anyway). The GUI is built here (no Studio GUI).
-- Stud-brick look (StudStyle, wood): brick buttons, pet rows with a PetPortrait, the penned pet as a large portrait;
-- the toast and the "welcome back" card are wooden plates too.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))
local PetPortrait = require(script.Parent:WaitForChild("PetPortrait"))

local remotes = ReplicatedStorage:WaitForChild("GardenRemotes")
-- looked up by name: `remotes.Remove` would be the built-in Instance:Remove() method, not the RemoteEvent
local placeEvent = remotes:WaitForChild("Place")
local removeEvent = remotes:WaitForChild("Remove")
local buyPenEvent = remotes:WaitForChild("BuyPen")
local requestStateEvent = remotes:WaitForChild("RequestState")
local player = Players.LocalPlayer

local WIDTH = 360
local HEIGHT = 440
local ROW_HEIGHT = 58
local CARD_SIZE = 140 -- portrait of the penned pet
local CLOSE_DISTANCE = 32 -- studs from the pen pad; walking further away closes the panel

local COLOR_PANEL = StudStyle.PanelColors.GardenPen
local COLOR_ROW = StudStyle.PetRowColor(COLOR_PANEL)
local COLOR_BUY = StudStyle.Colors.Green
local COLOR_EQUIP = StudStyle.Colors.Blue
local COLOR_LOCKED = StudStyle.Colors.Grey
local COLOR_SELL = StudStyle.Colors.Red
local COLOR_INFO = Color3.fromRGB(235, 222, 190)
local COLOR_ERROR = Color3.fromRGB(240, 100, 90)
local COLOR_OK = Color3.fromRGB(120, 230, 120)

local REJECT_TEXT = {
	coins = "Not enough Coins",
	stale = "Out of date, try again",
	maxed = "All pens unlocked",
	locked = "Unlock this pen first",
	occupied = "This pen already holds a pet",
	equipped = "Unequip the pet first (Pets panel)",
	penned = "That pet is already in a pen",
	far = "Too far from your plot",
	noplot = "You have no plot on this server",
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
local cardPortrait = PetPortrait.Cache()

local function rate(n: number): string
	return string.format("%g", n)
end

-- "7 h 59 min", "12 min", "45 s"
local function duration(seconds: number): string
	if seconds >= 3600 then
		return string.format("%d h %d min", seconds // 3600, (seconds % 3600) // 60)
	elseif seconds >= 60 then
		return string.format("%d min", seconds // 60)
	end
	return string.format("%d s", seconds)
end

-- Pen panel ---------------------------------------------------------------------------------------------------------------

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
local infoLabel = label("Info", {
	Position = UDim2.new(0, 12, 0, 42),
	Size = UDim2.new(1, -24, 0, 36),
	Font = Enum.Font.Gotham,
	TextSize = 14,
	TextColor3 = COLOR_INFO,
	TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Top,
	RichText = true,
})
local actionButton = button("Action", {
	Position = UDim2.new(0, 10, 0, 88),
	Size = UDim2.new(1, -20, 0, 38),
	TextSize = 17,
}, 6)
-- the penned pet, large, under the "take it out" button
local penCard = PetPortrait.Holder({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 140),
	Size = UDim2.fromOffset(CARD_SIZE, CARD_SIZE),
	BackgroundColor3 = COLOR_ROW,
	Visible = false,
})
create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 3, Parent = penCard })
local list = create("ScrollingFrame", {
	Name = "Pets",
	Position = UDim2.new(0, 8, 0, 86),
	Size = UDim2.new(1, -16, 1, -136),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 5,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, {
	create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }),
	create("UIPadding", { PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 6) }), -- room for the first row's studs
})
local emptyLabel = label("Empty", {
	Position = UDim2.new(0, 12, 0, 96),
	Size = UDim2.new(1, -24, 0, 60),
	Font = Enum.Font.Gotham,
	TextSize = 15,
	TextColor3 = COLOR_INFO,
	TextWrapped = true,
	Text = "No free pets. Hatch one in an incubator, or unequip one in the Pets panel.",
	Visible = false,
})
local footerLabel = label("Footer", {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 12, 1, -8),
	Size = UDim2.new(1, -24, 0, 36),
	Font = Enum.Font.Gotham,
	TextSize = 14,
	TextColor3 = COLOR_INFO,
	TextWrapped = true,
	RichText = true,
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
	infoLabel,
	actionButton,
	penCard,
	list,
	emptyLabel,
	footerLabel,
})
StudStyle.Panel(panel, COLOR_PANEL)

-- Toast and "welcome back" announcement
local toast = label("Toast", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 70),
	Size = UDim2.fromOffset(300, 34),
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Center,
	Visible = false,
})
StudStyle.Plate(toast, COLOR_PANEL, 4)
StudStyle.Title(toast, COLOR_PANEL)

-- "Welcome back" announcement: top centre, nothing to click, fades out by itself (CanvasGroup fades text and background;
-- it clips its children, so this wooden card has an outline but no studs)
local awayTitle = label("Title", {
	Size = UDim2.new(1, 0, 0, 24),
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Center,
	Text = "🌱 Welcome back!",
	LayoutOrder = 1,
})
StudStyle.Title(awayTitle, COLOR_PANEL)
local awayText = label("Text", {
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	Font = Enum.Font.Gotham,
	TextSize = 16,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Center,
	RichText = true,
	LayoutOrder = 2,
})
local awayPanel = create("CanvasGroup", {
	Name = "Away",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 12),
	Size = UDim2.fromOffset(420, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = COLOR_PANEL,
	BackgroundTransparency = 0,
	GroupTransparency = 1,
	Visible = false,
}, {
	create("UICorner", { CornerRadius = UDim.new(0, 10) }),
	create("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = StudStyle.Shade(COLOR_PANEL, 0.62),
		Thickness = 3,
	}),
	create("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	}),
	create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }),
	awayTitle,
	awayText,
})

local screenGui = create("ScreenGui", {
	Name = "GardenGui",
	ResetOnSpawn = false,
	DisplayOrder = 5,
}, { panel, toast, awayPanel })

-- State -------------------------------------------------------------------------------------------------------------------

local gardenState = nil -- last GardenRemotes.State: { pens = { ["1"] = uid }, penCount, rate }
local openPen: number? = nil
local openPad: BasePart? = nil
local rows = {}
local flashToken = 0
local flashing = false

local function showInfo(text: string, color: Color3)
	infoLabel.Text = text
	infoLabel.TextColor3 = color
end

local refresh -- defined below

local function flash(text: string, color: Color3)
	flashToken += 1
	flashing = true
	local mine = flashToken
	showInfo(text, color)
	task.delay(3, function()
		if flashToken == mine then
			flashing = false
			refresh()
		end
	end)
end

local function petRow(index: number, pet)
	local placeButton = button("Place", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 2),
		Size = UDim2.fromOffset(72, 32),
		BackgroundColor3 = COLOR_EQUIP,
		TextSize = 15,
		Text = "Place",
	})
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
			BackgroundColor3 = pet.rarity.color,
			BorderSizePixel = 0,
		}, { create("UICorner", { CornerRadius = UDim.new(0, 3) }) }),
		PetPortrait.Holder({
			Position = UDim2.fromOffset(16, 6),
			Size = UDim2.fromOffset(46, 46),
			BackgroundColor3 = StudStyle.Shade(COLOR_PANEL, 0.18),
		}, rowPortrait(pet)),
		label("Name", {
			Position = UDim2.new(0, 70, 0, 6),
			Size = UDim2.new(1, -160, 0, 24),
			TextSize = 16,
			TextColor3 = pet.rarity.color,
			TextStrokeTransparency = 0.4,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = string.format("%s  Lv %d", pet.kind, pet.level),
		}),
		label("Detail", {
			Position = UDim2.new(0, 70, 0, 31),
			Size = UDim2.new(1, -160, 0, 18),
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextColor3 = COLOR_OK,
			Text = rate(GardenConfig.RatePerHour({ Kind = pet.kind, Level = pet.level })) .. " Coins/h",
		}),
		placeButton,
	})
	placeButton.Activated:Connect(function()
		if openPen then
			placeEvent:FireServer(openPen, pet.uid)
		end
	end)
	return row
end

refresh = function()
	for _, row in rows do
		PetPortrait.Release(row) -- the portraits stay cached
		row:Destroy()
	end
	table.clear(rows)
	PetPortrait.Release(penCard)
	actionButton.Visible = false
	list.Visible = false
	emptyLabel.Visible = false
	penCard.Visible = false

	local state = gardenState
	local pen = openPen
	if not (state and pen) then
		return
	end
	titleLabel.Text = "🌱 Pen " .. pen
	footerLabel.Text = string.format(
		"Garden income: <font color='#a8e6a0'>%s Coins/h</font> (before the pet bonus) · paid every %d min",
		rate(state.rate),
		GardenConfig.PayoutSeconds // 60
	)

	local uid = state.pens[tostring(pen)]
	if pen > state.penCount then
		local nextPen = state.penCount + 1
		actionButton.Visible = true
		if pen == nextPen then
			local price = GardenConfig.PenPrices[nextPen]
			actionButton.Text = string.format("Unlock pen %d: %s Coins", nextPen, PetClient.Number(price))
			actionButton.BackgroundColor3 = if PetClient.Coins >= price then COLOR_BUY else COLOR_LOCKED
			if not flashing then
				showInfo("Pets in pens produce Coins, even while you are away.", COLOR_INFO)
			end
		else
			actionButton.Text = "Unlock pen " .. nextPen .. " first"
			actionButton.BackgroundColor3 = COLOR_LOCKED
			if not flashing then
				showInfo("Pens are unlocked in order.", COLOR_INFO)
			end
		end
	elseif uid and PetClient.State and PetClient.State.pets[uid] then
		local data = PetClient.State.pets[uid]
		local rarity = PetConfig.RarityOf(data.Kind)
		local level = PetConfig.ClampLevel(data.Level)
		actionButton.Visible = true
		actionButton.Text = "Take " .. data.Kind .. " out of the pen"
		actionButton.BackgroundColor3 = COLOR_SELL
		local portrait = cardPortrait({ uid = uid, kind = data.Kind, level = level })
		if portrait then
			portrait.Parent = penCard
		end
		penCard.UIStroke.Color = rarity.color
		penCard.Visible = true
		if not flashing then
			showInfo(
				string.format(
					"%s Lv %d · <font color='#a8e6a0'>%s Coins/h</font>. A penned pet gains no XP and gives no pet bonus.",
					data.Kind,
					level,
					rate(GardenConfig.RatePerHour(data))
				),
				rarity.color
			)
		end
	else
		local count = 0
		for index, entry in PetClient.Inventory() do
			if not entry.equipped and not entry.penned then
				count += 1
				local row = petRow(count, entry)
				row.Parent = list
				rows[entry.uid] = row
			end
		end
		list.Visible = count > 0
		emptyLabel.Visible = count == 0
		if not flashing then
			showInfo("Choose a pet for this pen. It produces Coins while it stays here.", COLOR_INFO)
		end
	end
end

local function closePanel()
	openPen, openPad = nil, nil
	panel.Visible = false
end

local function openPanel(pen: number, pad: BasePart)
	openPen, openPad = pen, pad
	flashing = false
	panel.Visible = true
	refresh()
end

closeButton.Activated:Connect(closePanel)

actionButton.Activated:Connect(function()
	local state = gardenState
	local pen = openPen
	if not (state and pen) then
		return
	end
	if pen > state.penCount then
		if pen == state.penCount + 1 then
			buyPenEvent:FireServer(pen)
		end
	elseif state.pens[tostring(pen)] then
		removeEvent:FireServer(pen)
	end
end)

remotes:WaitForChild("State").OnClientEvent:Connect(function(state)
	gardenState = state
	refresh()
end)
PetClient.Changed:Connect(function()
	if openPen then
		refresh()
	end
end)

remotes:WaitForChild("Result").OnClientEvent:Connect(function(action, ok, detail)
	if action ~= "Place" and action ~= "Remove" and action ~= "BuyPen" then
		return -- incubators and the food stand answer on the same remote (IncubatorClient, FoodShopClient)
	end
	if ok then
		if action == "BuyPen" then
			flash(string.format("Pen %d unlocked", detail), COLOR_OK)
		elseif action == "Place" then
			flash("Placed. It produces Coins from now on.", COLOR_OK)
		elseif action == "Remove" then
			flash("Back in your inventory.", COLOR_OK)
		end
	else
		flash(REJECT_TEXT[detail] or "Request failed", COLOR_ERROR)
	end
end)

-- Payouts -----------------------------------------------------------------------------------------------------------------

local shownAway = {} -- [payout id] = true: the server may send the join payout again on RequestState
local toastToken = 0
local AWAY_SHOW_SECONDS = 5 -- the announcement stays this long, then fades out
local AWAY_FADE_IN = TweenInfo.new(0.3)
local AWAY_FADE_OUT = TweenInfo.new(1)

local awayToken = 0 -- a newer announcement restarts the 5 s; the older one's fade-out is skipped

local function showAway(text: string)
	awayToken += 1
	local mine = awayToken
	awayText.Text = text
	awayPanel.GroupTransparency = 1
	awayPanel.Visible = true
	TweenService:Create(awayPanel, AWAY_FADE_IN, { GroupTransparency = 0 }):Play()
	task.delay(AWAY_SHOW_SECONDS, function()
		if awayToken ~= mine then
			return
		end
		local fade = TweenService:Create(awayPanel, AWAY_FADE_OUT, { GroupTransparency = 1 })
		fade.Completed:Connect(function(state)
			if state == Enum.PlaybackState.Completed and awayToken == mine then
				awayPanel.Visible = false
			end
		end)
		fade:Play()
	end)
end

local function showToast(text: string)
	toastToken += 1
	local mine = toastToken
	toast.Text = text
	toast.Visible = true
	task.delay(3, function()
		if toastToken == mine then
			toast.Visible = false
		end
	end)
end

remotes:WaitForChild("Payout").OnClientEvent:Connect(function(info)
	if type(info) ~= "table" then
		return
	end
	if info.away then
		if shownAway[info.id] then
			return
		end
		shownAway[info.id] = true
		local text = string.format(
			"Your pens produced <font color='#78e678'>%s Coins</font> in %s.",
			PetClient.Number(info.paid),
			duration(info.seconds)
		)
		if info.paid ~= info.base then
			text ..= string.format("\n(%s base + your pet bonus)", PetClient.Number(info.base))
		end
		if info.capped then
			text ..= string.format("\nProduction while away is capped at %d hours.", GardenConfig.OfflineCapSeconds // 3600)
		end
		showAway(text)
	else
		showToast(string.format("🌱 Garden +%s Coins", PetClient.Number(info.paid)))
	end
end)

-- Pen prompts ---------------------------------------------------------------------------------------------------------------

local wired = {} -- [Pad] = true
local function wirePrompts()
	local garden = workspace:WaitForChild("Garden")
	local plots = garden:WaitForChild("Plots")
	local own = player:GetAttribute(GardenConfig.PlotAttribute)
	for _, plot in plots:GetChildren() do
		local mine = own ~= nil and plot:GetAttribute("PlotIndex") == own
		for number = 1, GardenConfig.MaxPens do
			local pen = plot:FindFirstChild(GardenConfig.PenNamePrefix .. number)
			local pad = pen and pen:FindFirstChild("Pad")
			local prompt = pad and pad:FindFirstChild("Prompt")
			if prompt and prompt:IsA("ProximityPrompt") then
				prompt.Enabled = mine
				if not wired[pad] then
					wired[pad] = true
					prompt.Triggered:Connect(function(who)
						if who == player then
							openPanel(number, pad)
						end
					end)
				end
			end
		end
	end
end

player:GetAttributeChangedSignal(GardenConfig.PlotAttribute):Connect(wirePrompts)
task.spawn(wirePrompts)

-- Opens the panel for pen N of the player's own plot when the ScreenGui attribute OpenPen is set (same effect as the
-- prompt; lets tests and other UI open a pen). Display only: the server validates every action anyway.
screenGui:GetAttributeChangedSignal("OpenPen"):Connect(function()
	local number = screenGui:GetAttribute("OpenPen")
	local own = player:GetAttribute(GardenConfig.PlotAttribute)
	if type(number) ~= "number" or not own then
		return
	end
	local plot = workspace:FindFirstChild("Garden") and workspace.Garden.Plots:FindFirstChild(GardenConfig.PlotName(own))
	local pen = plot and plot:FindFirstChild(GardenConfig.PenNamePrefix .. number)
	local pad = pen and pen:FindFirstChild("Pad")
	if pad then
		openPanel(number, pad)
	end
	screenGui:SetAttribute("OpenPen", nil)
end)

-- Closes the panel when the player walks away from the pen
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.5 then
		return
	end
	elapsed = 0
	if openPad then
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root or (root.Position - openPad.Position).Magnitude > CLOSE_DISTANCE then
			closePanel()
		end
	end
end)

requestStateEvent:FireServer()
screenGui.Parent = player:WaitForChild("PlayerGui")
