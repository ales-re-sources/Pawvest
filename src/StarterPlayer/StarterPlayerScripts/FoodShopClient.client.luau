-- Food shop client (docs/GDD.md §7.6, P2b2): the prompt on the garden plaza's food stand opens the food panel: every owned
-- pet with its level, XP and the XP still needed for level 20, and one feed button per food. Display only: a click just
-- names a pet and a food; GardenFood validates the distance, the price and the level. The GUI is built here (no Studio GUI).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))

local remotes = ReplicatedStorage:WaitForChild("GardenRemotes")
local feedEvent = remotes:WaitForChild("Feed") -- looked up by name, never `remotes.X`
local player = Players.LocalPlayer

local WIDTH = 460
local HEIGHT = 460
local ROW_HEIGHT = 56
local FOOD_BUTTON_WIDTH = 62
local CLOSE_DISTANCE = GardenConfig.FoodStandDistance -- walking further from the stand closes the panel (the server rejects it too)

local COLOR_PANEL = Color3.fromRGB(40, 40, 40)
local COLOR_ROW = Color3.fromRGB(55, 55, 55)
local COLOR_BUY = Color3.fromRGB(60, 170, 70)
local COLOR_LOCKED = Color3.fromRGB(110, 110, 110)
local COLOR_INFO = Color3.fromRGB(190, 190, 190)
local COLOR_ERROR = Color3.fromRGB(240, 100, 90)
local COLOR_OK = Color3.fromRGB(120, 230, 120)

local REJECT_TEXT = {
	coins = "Not enough Coins",
	maxed = "This pet is already level 20",
	far = "Too far from the food stand",
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

-- Panel ------------------------------------------------------------------------------------------------------------------

local menu = {}
for _, food in GardenConfig.Foods do
	table.insert(
		menu,
		string.format("%s %s %s Coins → %s XP", food.icon, food.name, PetClient.Number(food.price), PetClient.Number(food.xp))
	)
end

local titleLabel = label("Title", {
	Position = UDim2.new(0, 12, 0, 8),
	Size = UDim2.new(1, -60, 0, 26),
	TextSize = 20,
	Text = "🍓 Pet food",
})
local closeButton = button("Close", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -8, 0, 8),
	Size = UDim2.fromOffset(30, 26),
	BackgroundColor3 = COLOR_LOCKED,
	TextSize = 16,
	Text = "X",
})
local menuLabel = label("Menu", {
	Position = UDim2.new(0, 12, 0, 38),
	Size = UDim2.new(1, -24, 0, 36),
	Font = Enum.Font.Gotham,
	TextSize = 14,
	TextColor3 = COLOR_INFO,
	TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Top,
	Text = table.concat(menu, "   ") .. "\nOnly the fed pet gets the XP.",
})
local statusLabel = label("Status", {
	Position = UDim2.new(0, 12, 0, 78),
	Size = UDim2.new(1, -24, 0, 22),
	TextSize = 15,
	TextColor3 = COLOR_INFO,
	TextTruncate = Enum.TextTruncate.AtEnd,
	RichText = true,
})
local list = create("ScrollingFrame", {
	Name = "Pets",
	Position = UDim2.new(0, 8, 0, 104),
	Size = UDim2.new(1, -16, 1, -112),
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
	Position = UDim2.new(0, 12, 0, 110),
	Size = UDim2.new(1, -24, 0, 40),
	Font = Enum.Font.Gotham,
	TextSize = 15,
	TextColor3 = COLOR_INFO,
	TextWrapped = true,
	Text = "You have no pets yet. Hatch one at the egg stand.",
	Visible = false,
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
	menuLabel,
	statusLabel,
	list,
	emptyLabel,
})

local screenGui = create("ScreenGui", {
	Name = "FoodShopGui",
	ResetOnSpawn = false,
	DisplayOrder = 5,
}, { panel })

-- State ------------------------------------------------------------------------------------------------------------------

local openStand: BasePart? = nil
local rows = {}
local flashToken = 0

local function flash(text: string, color: Color3)
	flashToken += 1
	local mine = flashToken
	statusLabel.Text = text
	statusLabel.TextColor3 = color
	task.delay(4, function()
		if flashToken == mine then
			statusLabel.Text = ""
		end
	end)
end

local function where(entry): string
	if entry.equipped then
		return "equipped"
	elseif entry.penned then
		return "in pen " .. entry.penned
	end
	return "resting"
end

local function petRow(order: number, entry)
	local pet = PetClient.State.pets[entry.uid]
	local toMax = GardenConfig.XpToMax(pet)
	local maxed = entry.level >= PetConfig.MaxLevel
	local detail = if maxed
		then "Max level · " .. where(entry)
		else string.format(
			"XP %s/%s · %s XP to Lv %d · %s",
			PetClient.Number(entry.xp),
			PetClient.Number(entry.xpNext),
			PetClient.Number(toMax),
			PetConfig.MaxLevel,
			where(entry)
		)
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
		label("Name", {
			Position = UDim2.new(0, 18, 0, 5),
			Size = UDim2.new(1, -(24 + 3 * (FOOD_BUTTON_WIDTH + 4)), 0, 24),
			TextSize = 16,
			TextColor3 = entry.rarity.color,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = string.format("%s  Lv %d", entry.kind, entry.level),
		}),
		label("Detail", {
			Position = UDim2.new(0, 18, 0, 30),
			Size = UDim2.new(1, -(24 + 3 * (FOOD_BUTTON_WIDTH + 4)), 0, 18),
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = COLOR_INFO,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = detail,
		}),
	})
	for index, food in GardenConfig.Foods do
		local feedButton = button("Feed_" .. food.id, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -6 - (#GardenConfig.Foods - index) * (FOOD_BUTTON_WIDTH + 4), 0.5, 0),
			Size = UDim2.fromOffset(FOOD_BUTTON_WIDTH, 40),
			BackgroundColor3 = if not maxed and PetClient.Coins >= food.price then COLOR_BUY else COLOR_LOCKED,
			TextSize = 13,
			Text = food.icon .. "\n" .. PetClient.Number(food.price),
			AutoButtonColor = not maxed,
		})
		feedButton.Parent = row
		feedButton.Activated:Connect(function()
			if maxed then
				return flash(REJECT_TEXT.maxed, COLOR_ERROR)
			end
			if food.xp > toMax then
				-- allowed, but tell the player that the rest is lost
				flash(string.format("Only %s XP needed to Lv %d: the rest is lost", PetClient.Number(toMax), PetConfig.MaxLevel), COLOR_INFO)
			end
			feedEvent:FireServer(entry.uid, food.id)
		end)
	end
	return row
end

local function refresh()
	for _, row in rows do
		row:Destroy()
	end
	table.clear(rows)
	if not (openStand and PetClient.State) then
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
end

local function closePanel()
	openStand = nil
	panel.Visible = false
	refresh()
end

local function openPanel(stand: BasePart)
	openStand = stand
	statusLabel.Text = ""
	panel.Visible = true
	refresh()
end

closeButton.Activated:Connect(closePanel)

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
		return flash(REJECT_TEXT[detail] or "Request failed", COLOR_ERROR)
	end
	local food = GardenConfig.FoodById[detail.food]
	local pet = PetClient.State and PetClient.State.pets[detail.uid]
	local kind = pet and pet.Kind or "Your pet"
	local text = string.format("%s %s +%s XP", food and food.icon or "", kind, PetClient.Number(detail.xp))
	if type(detail.levels) == "number" and detail.levels > 0 then
		text ..= string.format(" · Level up! Lv %d", detail.level)
	end
	flash(text, COLOR_OK)
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
