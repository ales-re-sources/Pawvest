-- Egg stand (docs/GDD.md §7.2): the ProximityPrompt on workspace.StartLocation.EggStand.Egg opens a popup with the odds
-- (rendered from PetConfig, never typed here), the price and an "open" button, then a short hatch reveal.
-- The button only names the egg (PetRemotes.BuyEgg(eggId)); the server charges the price from PetConfig (or opens a
-- waiting free egg first, for 0 Coins), rolls the pet and answers with Result. The GUI is built here, not in Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))

local EGG_ID = "Basic" -- the one egg sold at the stand (PetConfig.Eggs[...].stand)
local MIN_HATCH_SECONDS = 0.9 -- the egg wobbles at least this long before the reveal
local REPLY_TIMEOUT = 5 -- seconds to wait for the server before the button unlocks again
local LEAVE_MARGIN = 8 -- studs beyond the prompt's range before the popup closes by itself

local egg = PetConfig.Eggs[EGG_ID]
local player = Players.LocalPlayer

local COLOR_PANEL = Color3.fromRGB(32, 32, 32)
local COLOR_BUY = Color3.fromRGB(60, 170, 70)
local COLOR_LOCKED = Color3.fromRGB(110, 110, 110)
local COLOR_INFO = Color3.fromRGB(190, 190, 190)
local COLOR_ERROR = Color3.fromRGB(240, 100, 90)
local COLOR_OK = Color3.fromRGB(120, 230, 120)

local REJECT_TEXT = {
	full = "Your pet inventory is full (%d/%d). Sell a pet in the Pets panel first.",
	loading = "Still loading, try again in a moment",
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

local function line(name: string, order: number, textSize: number, color: Color3)
	return create("TextLabel", {
		Name = name,
		LayoutOrder = order,
		Size = UDim2.new(1, -24, 0, textSize + 6),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = textSize,
		TextColor3 = color,
		TextWrapped = true,
		RichText = true,
		Text = "",
	})
end

local function button(name: string, order: number, color: Color3)
	return create("TextButton", {
		Name = name,
		LayoutOrder = order,
		Size = UDim2.new(1, -48, 0, 42),
		BackgroundColor3 = color,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = Color3.new(1, 1, 1),
	}, { create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
end

local function rgbHex(color: Color3): string
	return string.format("#%02x%02x%02x", math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255))
end

-- Odds table: one row per rarity the egg can hatch, straight from PetConfig (weight / total).
local totalWeight = 0
for _, rarity in PetConfig.Rarities do
	totalWeight += egg.weights[rarity.id] or 0
end
local oddsRows = {}
for _, rarity in PetConfig.Rarities do
	local weight = egg.weights[rarity.id]
	if weight and weight > 0 then
		local percent = string.format("%g", weight / totalWeight * 100)
		table.insert(oddsRows, create("Frame", {
			Name = "Odds_" .. rarity.id,
			LayoutOrder = 10 + rarity.order,
			Size = UDim2.new(1, -48, 0, 22),
			BackgroundTransparency = 1,
		}, {
			create("TextLabel", {
				Name = "Rarity",
				Size = UDim2.new(1, -70, 1, 0),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				TextSize = 15,
				TextColor3 = rarity.color,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = string.format("%s  (%s)", rarity.id, table.concat(PetConfig.KindsByRarity[rarity.id], ", ")),
			}),
			create("TextLabel", {
				Name = "Percent",
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.new(0, 66, 1, 0),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				TextSize = 15,
				TextColor3 = Color3.new(1, 1, 1),
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = percent .. "%",
			}),
		}))
	end
end

local titleLabel = line("Title", 1, 22, Color3.new(1, 1, 1))
titleLabel.Text = "🥚 " .. egg.name
local oddsHeader = line("OddsHeader", 5, 14, COLOR_INFO)
oddsHeader.Text = "Odds per hatch"

local revealLabel = create("TextLabel", {
	Name = "Reveal",
	Size = UDim2.new(1, 0, 0, 44),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 36,
	TextColor3 = Color3.new(1, 1, 1),
	Text = "🥚",
})
local revealSub = create("TextLabel", {
	Name = "RevealSub",
	Position = UDim2.new(0, 0, 0, 46),
	Size = UDim2.new(1, 0, 0, 20),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextColor3 = COLOR_INFO,
	Text = "",
})
local revealStroke = create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 0, Transparency = 0.2 })
local revealFrame = create("Frame", {
	Name = "RevealFrame",
	LayoutOrder = 20,
	Size = UDim2.new(1, -48, 0, 70),
	BackgroundColor3 = Color3.fromRGB(45, 45, 45),
}, {
	create("UICorner", { CornerRadius = UDim.new(0, 10) }),
	revealStroke,
	revealLabel,
	revealSub,
})

local priceLabel = line("Price", 21, 16, Color3.new(1, 1, 1))
local openButton = button("Open", 22, COLOR_BUY)
local infoLabel = line("Info", 23, 14, COLOR_INFO)
local closeButton = button("Close", 24, COLOR_LOCKED)
closeButton.Size = UDim2.new(1, -48, 0, 34)
closeButton.TextSize = 16
closeButton.Text = "Close"

local panelChildren = {
	create("UICorner", { CornerRadius = UDim.new(0, 12) }),
	create("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14) }),
	create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 6),
	}),
	titleLabel,
	oddsHeader,
	revealFrame,
	priceLabel,
	openButton,
	infoLabel,
	closeButton,
}
for _, row in oddsRows do
	table.insert(panelChildren, row)
end

local panel = create("Frame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(360, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = COLOR_PANEL,
	BackgroundTransparency = 0.05,
}, panelChildren)

local screenGui = create("ScreenGui", {
	Name = "EggStandGui",
	ResetOnSpawn = false,
	DisplayOrder = 7,
	Enabled = false,
}, { panel })

local hatching = false
local hatchStarted = 0 -- os.clock() of the click, so the reveal waits out the wobble
local hatchGeneration = 0 -- invalidates timeouts and wobbles of an earlier click
local wobble = 0 -- counts running wobble loops; the loop stops when it no longer matches

local function setInfo(text: string, color: Color3)
	infoLabel.Text = text
	infoLabel.TextColor3 = color
end

local function freeEggsWaiting(): number
	local state = PetClient.State
	return state and state.freeEggs[EGG_ID] or 0
end

local function refresh()
	local free = freeEggsWaiting()
	if free > 0 then
		priceLabel.Text = string.format("🎁 %d free egg%s waiting: opening costs <font color='#78e678'>0 Coins</font>", free, if free == 1 then "" else "s")
	else
		priceLabel.Text = string.format(
			"Price: <font color='#ffd34d'>%s Coins</font>   (you have %s)",
			PetClient.Number(egg.price),
			PetClient.Number(PetClient.Coins)
		)
	end
	if hatching then
		openButton.Text = "Hatching..."
		openButton.BackgroundColor3 = COLOR_LOCKED
	elseif free > 0 then
		openButton.Text = "Open free egg"
		openButton.BackgroundColor3 = COLOR_BUY
	else
		openButton.Text = string.format("Open egg: %s Coins", PetClient.Number(egg.price))
		openButton.BackgroundColor3 = if PetClient.Coins >= egg.price then COLOR_BUY else COLOR_LOCKED
	end
end

local function resetReveal()
	wobble += 1
	revealLabel.Rotation = 0
	revealLabel.TextSize = 36
	revealLabel.TextColor3 = Color3.new(1, 1, 1)
	revealLabel.Text = "🥚"
	revealSub.Text = ""
	revealStroke.Thickness = 0
end

local function startWobble()
	wobble += 1
	local mine = wobble
	task.spawn(function()
		local direction = 1
		while wobble == mine do
			local tween = TweenService:Create(
				revealLabel,
				TweenInfo.new(0.09, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ Rotation = 14 * direction }
			)
			tween:Play()
			tween.Completed:Wait()
			direction = -direction
		end
		revealLabel.Rotation = 0
	end)
end

local function endHatch()
	hatching = false
	hatchGeneration += 1
	refresh()
end

local function reveal(detail)
	local kind = detail.kind
	local rarity = PetConfig.RarityOf(kind)
	wobble += 1 -- stop wobbling
	revealLabel.Rotation = 0
	revealLabel.Text = kind .. "!"
	revealLabel.TextColor3 = if rarity then rarity.color else Color3.new(1, 1, 1)
	revealLabel.TextSize = 10
	TweenService:Create(
		revealLabel,
		TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ TextSize = 36 }
	):Play()
	if rarity then
		revealSub.Text = string.format(
			"%s  ·  +%s%% Coin bonus  ·  %s",
			rarity.id,
			PetClient.Percent(rarity.bonus),
			if detail.free then "free egg" else "added to your pets"
		)
		revealSub.TextColor3 = rarity.color
		revealStroke.Color = rarity.color
		revealStroke.Thickness = if rarity.order >= 4 then 4 else 2 -- Epic and Legendary glow
	end
	setInfo("Added to your pets: equip it in the Pets panel (🐶 button)", COLOR_OK)
	endHatch()
end

local function hide()
	hatchGeneration += 1
	hatching = false
	wobble += 1
	screenGui.Enabled = false
end

local function show()
	resetReveal()
	hatching = false
	setInfo("Free eggs are won with the first Gold on a stage", COLOR_INFO)
	refresh()
	screenGui.Enabled = true
end

openButton.Activated:Connect(function()
	if hatching then
		return
	end
	hatching = true
	hatchGeneration += 1
	local generation = hatchGeneration
	resetReveal()
	startWobble()
	setInfo("", COLOR_INFO)
	refresh()
	hatchStarted = os.clock()
	PetClient.Remotes.BuyEgg:FireServer(EGG_ID)
	task.delay(REPLY_TIMEOUT, function()
		if hatching and hatchGeneration == generation then
			resetReveal()
			setInfo("No answer from the server, try again", COLOR_ERROR)
			endHatch()
		end
	end)
end)
closeButton.Activated:Connect(hide)

PetClient.Result:Connect(function(action, ok, detail)
	if action ~= "BuyEgg" or not screenGui.Enabled or not hatching then
		return
	end
	local generation = hatchGeneration
	if ok then
		local wait = MIN_HATCH_SECONDS - (os.clock() - hatchStarted)
		task.delay(math.max(0, wait), function()
			if hatching and hatchGeneration == generation then
				reveal(detail)
			end
		end)
	else
		resetReveal()
		if detail == "coins" then
			setInfo(
				string.format(
					"Not enough Coins: you need %s, you have %s",
					PetClient.Number(egg.price),
					PetClient.Number(PetClient.Coins)
				),
				COLOR_ERROR
			)
		elseif detail == "full" then
			setInfo(string.format(REJECT_TEXT.full, PetClient.PetCount(), PetConfig.MaxPets), COLOR_ERROR)
		else
			setInfo(REJECT_TEXT[detail] or "Could not open the egg", COLOR_ERROR)
		end
		endHatch()
	end
end)

PetClient.Changed:Connect(function()
	if screenGui.Enabled then
		refresh()
	end
end)

-- The stand itself lives in Studio: workspace.StartLocation.EggStand.Egg with a ProximityPrompt called Prompt.
task.spawn(function()
	local stand = workspace:WaitForChild("StartLocation"):WaitForChild("EggStand")
	local eggPart = stand:WaitForChild("Egg") :: BasePart
	local prompt = eggPart:WaitForChild("Prompt") :: ProximityPrompt

	prompt.Triggered:Connect(function(who)
		if who == player then
			show()
		end
	end)

	-- Close the popup when the player walks away from the stand.
	while true do
		task.wait(0.5)
		if screenGui.Enabled then
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not root or (root.Position - eggPart.Position).Magnitude > prompt.MaxActivationDistance + LEAVE_MARGIN then
				hide()
			end
		end
	end
end)

screenGui.Parent = player:WaitForChild("PlayerGui")
