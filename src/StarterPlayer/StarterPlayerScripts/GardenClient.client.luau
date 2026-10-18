-- Garden client (docs/GDD.md §7.6): pen prompts on the player's own plot, the pen panel (unlock a pen, place a pet, remove it),
-- the "while you were away" popup after the join payout and a small toast for online payouts.
-- Display only: a click just names a pen and a pet; GardenService validates ownership, price and time. The prompts of other
-- players' plots are switched off locally (the server rejects them anyway). The GUI is built here (no Studio GUI).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))

local remotes = ReplicatedStorage:WaitForChild("GardenRemotes")
-- looked up by name: `remotes.Remove` would be the built-in Instance:Remove() method, not the RemoteEvent
local placeEvent = remotes:WaitForChild("Place")
local removeEvent = remotes:WaitForChild("Remove")
local buyPenEvent = remotes:WaitForChild("BuyPen")
local requestStateEvent = remotes:WaitForChild("RequestState")
local player = Players.LocalPlayer

local WIDTH = 360
local HEIGHT = 440
local ROW_HEIGHT = 52
local CLOSE_DISTANCE = 32 -- studs from the pen pad; walking further away closes the panel

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

local titleLabel = label("Title", {
	Position = UDim2.new(0, 12, 0, 8),
	Size = UDim2.new(1, -60, 0, 26),
	TextSize = 20,
})
local closeButton = button("Close", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -8, 0, 8),
	Size = UDim2.fromOffset(30, 26),
	BackgroundColor3 = COLOR_LOCKED,
	TextSize = 16,
	Text = "X",
})
local infoLabel = label("Info", {
	Position = UDim2.new(0, 12, 0, 38),
	Size = UDim2.new(1, -24, 0, 36),
	Font = Enum.Font.Gotham,
	TextSize = 14,
	TextColor3 = COLOR_INFO,
	TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Top,
	RichText = true,
})
local actionButton = button("Action", {
	Position = UDim2.new(0, 10, 0, 80),
	Size = UDim2.new(1, -20, 0, 36),
	TextSize = 16,
})
local list = create("ScrollingFrame", {
	Name = "Pets",
	Position = UDim2.new(0, 8, 0, 80),
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
	Position = UDim2.new(0, 12, 0, 90),
	Size = UDim2.new(1, -24, 0, 60),
	Font = Enum.Font.Gotham,
	TextSize = 15,
	TextColor3 = COLOR_INFO,
	TextWrapped = true,
	Text = "No free pets. Hatch one at the egg stand, or unequip one in the Pets panel.",
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
	BackgroundColor3 = COLOR_PANEL,
	Visible = false,
}, {
	create("UICorner", { CornerRadius = UDim.new(0, 8) }),
	create("UIStroke", { Color = Color3.fromRGB(80, 80, 80), Thickness = 1 }),
	titleLabel,
	closeButton,
	infoLabel,
	actionButton,
	list,
	emptyLabel,
	footerLabel,
})

-- Toast and "while you were away" popup
local toast = label("Toast", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 70),
	Size = UDim2.fromOffset(300, 30),
	BackgroundTransparency = 0.3,
	BackgroundColor3 = COLOR_PANEL,
	TextSize = 18,
	TextColor3 = COLOR_OK,
	TextXAlignment = Enum.TextXAlignment.Center,
	Visible = false,
})
create("UICorner", { CornerRadius = UDim.new(0, 8) }).Parent = toast

local awayTitle = label("Title", {
	Position = UDim2.new(0, 12, 0, 10),
	Size = UDim2.new(1, -24, 0, 28),
	TextSize = 22,
	Text = "Welcome back!",
})
local awayText = label("Text", {
	Position = UDim2.new(0, 12, 0, 46),
	Size = UDim2.new(1, -24, 0, 80),
	Font = Enum.Font.Gotham,
	TextSize = 16,
	TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Top,
	RichText = true,
})
local awayButton = button("Ok", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -12),
	Size = UDim2.fromOffset(120, 34),
	BackgroundColor3 = COLOR_BUY,
	TextSize = 16,
	Text = "Collect",
})
local awayPanel = create("Frame", {
	Name = "Away",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.45),
	Size = UDim2.fromOffset(380, 210),
	BackgroundColor3 = COLOR_PANEL,
	Visible = false,
}, {
	create("UICorner", { CornerRadius = UDim.new(0, 8) }),
	create("UIStroke", { Color = Color3.fromRGB(80, 80, 80), Thickness = 1 }),
	awayTitle,
	awayText,
	awayButton,
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
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.fromOffset(70, 28),
		BackgroundColor3 = COLOR_EQUIP,
		TextSize = 14,
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
		label("Name", {
			Position = UDim2.new(0, 18, 0, 4),
			Size = UDim2.new(1, -100, 0, 24),
			TextSize = 16,
			TextColor3 = pet.rarity.color,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = string.format("%s  Lv %d", pet.kind, pet.level),
		}),
		label("Detail", {
			Position = UDim2.new(0, 18, 0, 28),
			Size = UDim2.new(1, -100, 0, 18),
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
		row:Destroy()
	end
	table.clear(rows)
	actionButton.Visible = false
	list.Visible = false
	emptyLabel.Visible = false

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
		awayText.Text = text
		awayPanel.Visible = true
	else
		showToast(string.format("🌱 Garden +%s Coins", PetClient.Number(info.paid)))
	end
end)
awayButton.Activated:Connect(function()
	awayPanel.Visible = false
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
