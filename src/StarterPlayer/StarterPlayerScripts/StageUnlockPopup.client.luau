-- Unlock popup (docs/GDD.md §3): opens when the server reports a touch on a locked hub portal (UnlockRemotes.Locked).
-- Shows the bar (required medal) and the Coin price; the button only asks the server to unlock (stageKey), the server
-- prices and decides everything. The GUI is built here, not in Studio. There is no Close button: the popup closes by itself
-- when the player walks away from the gate (CLOSE_DISTANCE studs, measured to the gate's door / portal face).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local MedalText = require(ReplicatedStorage:WaitForChild("MedalText"))
local TalentConfig = require(ReplicatedStorage:WaitForChild("TalentConfig"))
local remotes = ReplicatedStorage:WaitForChild("UnlockRemotes")
local buyEvent = remotes:WaitForChild("Buy")
local resultEvent = remotes:WaitForChild("Result")
local lockedEvent = remotes:WaitForChild("Locked")

local player = Players.LocalPlayer

local CLOSE_AFTER_UNLOCK = 3 -- seconds
local CLOSE_DISTANCE = 20 -- studs (horizontal) from the gate's face before the popup closes
local COLOR_PANEL = Color3.fromRGB(32, 32, 32)
local COLOR_BUY = Color3.fromRGB(60, 170, 70)
local COLOR_LOCKED = Color3.fromRGB(110, 110, 110)
local COLOR_INFO = Color3.fromRGB(190, 190, 190)
local COLOR_ERROR = Color3.fromRGB(240, 100, 90)
local COLOR_OK = Color3.fromRGB(120, 230, 120)

local REJECT_TEXT = {
	coins = "Not enough Coins",
	owned = "Already unlocked",
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
		Size = UDim2.new(1, -48, 0, 40),
		BackgroundColor3 = color,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = Color3.new(1, 1, 1),
	}, { create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
end

local titleLabel = line("Title", 1, 22, Color3.new(1, 1, 1))
local barLabel = line("Bar", 2, 18, Color3.new(1, 1, 1))
local needsLabel = line("Needs", 3, 16, Color3.new(1, 1, 1))
local orLabel = line("Or", 4, 16, COLOR_INFO)
local buyButton = button("Unlock", 5, COLOR_BUY)
local infoLabel = line("Info", 6, 14, COLOR_INFO)

local panel = create("Frame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(340, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = COLOR_PANEL,
	BackgroundTransparency = 0.1,
}, {
	create("UICorner", { CornerRadius = UDim.new(0, 12) }),
	create("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14) }),
	create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 6),
	}),
	titleLabel,
	barLabel,
	needsLabel,
	orLabel,
	buyButton,
	infoLabel,
})

local screenGui = create("ScreenGui", {
	Name = "StageUnlock",
	ResetOnSpawn = false,
	DisplayOrder = 6,
	Enabled = false,
}, { panel })

local current = nil -- stage shown in the popup
local currentWorld = nil -- set when the popup was opened by a shut world gate: `current` is then the world's first stage
local currentFace: BasePart? = nil -- the gate face the player has to stay near
local coins = 0
local showGeneration = 0

local function hide()
	showGeneration += 1
	current = nil
	currentWorld = nil
	currentFace = nil
	screenGui.Enabled = false
end

local function setInfo(text: string, color: Color3)
	infoLabel.Text = text
	infoLabel.TextColor3 = color
end

local function refresh()
	if not current then
		return
	end
	local price = current.unlockPrice
	local unlocked = player:GetAttribute(StageConfig.UnlockedAttribute(current)) == true
	titleLabel.Text = (if currentWorld then currentWorld.name else current.displayName) .. (if unlocked then " unlocked!" else " is locked")
	barLabel.Text = "Earn " .. (MedalText.UnlockBar(current) or "")
	barLabel.Visible = not unlocked
	-- required talents of the stage (S1.2): shown with or without the lock, entry never depends on them
	local needs = MedalText.Needs(current, function(id)
		return player:GetAttribute(TalentConfig.AttributeName(id)) or 0
	end)
	needsLabel.Text = needs or ""
	needsLabel.Visible = needs ~= nil
	orLabel.Visible = not unlocked and price ~= nil
	orLabel.Text = if currentWorld then "or unlock " .. current.displayName .. " now:" else "or unlock it now:"
	buyButton.Visible = not unlocked and price ~= nil
	if price then
		buyButton.Text = string.format("Unlock for %d Coins", price)
		buyButton.BackgroundColor3 = if coins >= price then COLOR_BUY else COLOR_LOCKED
	end
end

local function show(stage, world)
	current = stage
	currentWorld = world
	currentFace = if world then StageConfig.WorldGatePortal(world) else StageConfig.FaceTarget(stage)
	showGeneration += 1
	setInfo(string.format("You have %d Coins", coins), COLOR_INFO)
	refresh()
	screenGui.Enabled = true
end

buyButton.Activated:Connect(function()
	if current then
		buyEvent:FireServer(current.key)
	end
end)

-- walking away from the gate closes the popup
RunService.Heartbeat:Connect(function()
	local face = currentFace
	if not face then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local offset = root.Position - face.Position
	if Vector3.new(offset.X, 0, offset.Z).Magnitude > CLOSE_DISTANCE then
		hide()
	end
end)

-- GateDoors (a locked door gate was touched) asks for the popup through this player attribute (a stage key)
player:GetAttributeChangedSignal("OpenUnlockPopup"):Connect(function()
	local stageKey = player:GetAttribute("OpenUnlockPopup")
	if type(stageKey) == "string" then
		player:SetAttribute("OpenUnlockPopup", nil)
		local stage = StageConfig.ByKey[stageKey]
		if stage and stage.unlock then
			show(stage)
		end
	end
end)

-- HubGateLocks (a shut world gate was touched) asks for the popup through this player attribute (a world index); the popup then
-- shows the world's first stage, whose bar and price are what opens the world
player:GetAttributeChangedSignal("OpenWorldPopup"):Connect(function()
	local index = player:GetAttribute("OpenWorldPopup")
	if type(index) == "number" then
		player:SetAttribute("OpenWorldPopup", nil)
		local world = StageConfig.Worlds[index]
		local entry = StageConfig.StagesOfWorld(index)[1]
		if world and entry and entry.unlock then
			show(entry, world)
		end
	end
end)

lockedEvent.OnClientEvent:Connect(function(stageKey)
	local stage = StageConfig.ByKey[stageKey]
	if stage then
		show(stage)
	end
end)

resultEvent.OnClientEvent:Connect(function(stageKey, ok, reason)
	if not current or current.key ~= stageKey then
		return
	end
	if ok then
		refresh()
		setInfo("Step into the portal to enter", COLOR_OK)
		local generation = showGeneration
		task.delay(CLOSE_AFTER_UNLOCK, function()
			if generation == showGeneration then
				hide()
			end
		end)
	else
		setInfo(REJECT_TEXT[reason] or "Unlock failed", COLOR_ERROR)
	end
end)

for _, stage in StageConfig.Stages do
	player:GetAttributeChangedSignal(StageConfig.UnlockedAttribute(stage)):Connect(function()
		if current == stage then
			refresh()
		end
	end)
end

task.spawn(function()
	local coinValue = player:WaitForChild("leaderstats"):WaitForChild("Coins") :: IntValue
	coins = coinValue.Value
	refresh()
	coinValue:GetPropertyChangedSignal("Value"):Connect(function()
		coins = coinValue.Value
		refresh()
	end)
end)

screenGui.Parent = player:WaitForChild("PlayerGui")
