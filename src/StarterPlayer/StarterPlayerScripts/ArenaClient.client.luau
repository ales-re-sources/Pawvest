-- ArenaClient: what the local player sees of the key arena (Workspace.KeyArena, ArenaConfig / ArenaServer). Everything here
-- is local: a key the player holds disappears for them only, a gate they opened turns into a faint ghost and stops colliding
-- for them only (the client owns its character's physics, like GateDoors). Also the key HUD (shown inside the arena's camera
-- zone) and short toasts, built in code.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ArenaConfig = require(ReplicatedStorage:WaitForChild("ArenaConfig"))

local LocalPlayer = Players.LocalPlayer

local SPIN_SPEED = math.rad(100) -- key spin around the world Y axis, per second
local BOB_HEIGHT = 0.5 -- studs
local OPEN_TRANSPARENCY = 1 -- an opened gate disappears
local TOAST_TIME = 2.5

local keyModels = {} -- [hit part] = { visual = Model, base = CFrame, parts = { [part] = transparency }, hidden = boolean }
local gates = {} -- [part] = { transparency = number }
local held = {} -- keys held (ArenaKeys)
local opened = {} -- gates opened (ArenaOpened)

------------------------------------------------------------------ HUD
local gui = Instance.new("ScreenGui")
gui.Name = "ArenaGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 5
gui.Enabled = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local bar = Instance.new("Frame")
bar.AnchorPoint = Vector2.new(0.5, 0)
bar.Position = UDim2.new(0.5, 0, 0, 12)
bar.Size = UDim2.fromOffset(190, 44)
bar.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
bar.BackgroundTransparency = 0.25
bar.Parent = gui
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(12, 0)
title.Size = UDim2.new(0, 60, 1, 0)
title.Font = Enum.Font.GothamBold
title.Text = "KEYS"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = bar

local slots = {} -- [keyId] = Frame (filled when held)
for index, id in ArenaConfig.Keys do
	local slot = Instance.new("Frame")
	slot.AnchorPoint = Vector2.new(0, 0.5)
	slot.Position = UDim2.new(0, 78 + (index - 1) * 50, 0.5, 0)
	slot.Size = UDim2.fromOffset(40, 28)
	slot.BackgroundColor3 = ArenaConfig.KeyColors[id]
	slot.BackgroundTransparency = 0.85
	slot.Parent = bar
	Instance.new("UICorner", slot).CornerRadius = UDim.new(0, 6)
	local stroke = Instance.new("UIStroke")
	stroke.Color = ArenaConfig.KeyColors[id]
	stroke.Thickness = 2
	stroke.Parent = slot
	slots[id] = slot
end

local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, 64)
toast.Size = UDim2.fromOffset(320, 36)
toast.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
toast.BackgroundTransparency = 0.2
toast.Font = Enum.Font.GothamBold
toast.TextColor3 = Color3.new(1, 1, 1)
toast.TextSize = 18
toast.Visible = false
toast.Parent = gui
Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 10)

local toastId = 0
local function showToast(text: string, color: Color3?)
	toastId += 1
	local id = toastId
	toast.Text = text
	toast.TextColor3 = color or Color3.new(1, 1, 1)
	toast.Visible = true
	task.delay(TOAST_TIME, function()
		if toastId == id then
			toast.Visible = false
		end
	end)
end

local function refreshHud()
	for id, slot in slots do
		slot.BackgroundTransparency = if held[id] then 0.1 else 0.85
	end
end

local function refreshVisibility()
	gui.Enabled = LocalPlayer:GetAttribute("CameraZone") == ArenaConfig.CameraZone
end

------------------------------------------------------------------ keys
local function setKeyHidden(hit: BasePart, state, hidden: boolean)
	if state.hidden == hidden then
		return
	end
	state.hidden = hidden
	for part, transparency in state.parts do
		part.Transparency = if hidden then 1 else transparency
	end
	hit.CanTouch = not hidden
end

local function addKey(hit: Instance)
	if not hit:IsA("BasePart") or keyModels[hit] then
		return
	end
	local visual = hit.Parent and hit.Parent:FindFirstChild("Visual")
	if not (visual and visual:IsA("Model")) then
		return
	end
	local state = { visual = visual, base = visual:GetPivot(), parts = {}, hidden = false }
	for _, part in visual:GetDescendants() do
		if part:IsA("BasePart") then
			state.parts[part] = part.Transparency
		end
	end
	keyModels[hit] = state
	setKeyHidden(hit, state, held[hit:GetAttribute(ArenaConfig.KeyAttribute)] == true)
end

local function refreshKeys()
	for hit, state in keyModels do
		setKeyHidden(hit, state, held[hit:GetAttribute(ArenaConfig.KeyAttribute)] == true)
	end
	refreshHud()
end

------------------------------------------------------------------ gates
local function refreshGate(part: BasePart, state)
	local isOpen = opened[part:GetAttribute(ArenaConfig.KeyAttribute)] == true
	part.CanCollide = not isOpen
	part.CanTouch = not isOpen
	part.Transparency = if isOpen then OPEN_TRANSPARENCY else state.transparency
end

local function addGate(part: Instance)
	if not part:IsA("BasePart") or gates[part] then
		return
	end
	local state = { transparency = part.Transparency }
	gates[part] = state
	refreshGate(part, state)
end

------------------------------------------------------------------ attributes
local function names(set: { [string]: boolean }): { string }
	local list = {}
	for _, id in ArenaConfig.Keys do
		if set[id] then
			table.insert(list, id)
		end
	end
	return list
end

local function onKeysChanged()
	local previous = held
	held = ArenaConfig.Decode(LocalPlayer:GetAttribute(ArenaConfig.KeysAttribute))
	for _, id in names(held) do
		if not previous[id] then
			showToast(id .. " key collected", ArenaConfig.KeyColors[id])
		end
	end
	refreshKeys()
end

local function onOpenedChanged()
	local previous = opened
	opened = ArenaConfig.Decode(LocalPlayer:GetAttribute(ArenaConfig.OpenedAttribute))
	for _, id in names(opened) do
		if not previous[id] then
			showToast(id .. " gate opened", ArenaConfig.KeyColors[id])
		end
	end
	for part, state in gates do
		refreshGate(part, state)
	end
end

for _, hit in CollectionService:GetTagged(ArenaConfig.Tags.Key) do
	addKey(hit)
end
CollectionService:GetInstanceAddedSignal(ArenaConfig.Tags.Key):Connect(addKey)
for _, part in CollectionService:GetTagged(ArenaConfig.Tags.Gate) do
	addGate(part)
end
CollectionService:GetInstanceAddedSignal(ArenaConfig.Tags.Gate):Connect(addGate)

LocalPlayer:GetAttributeChangedSignal(ArenaConfig.KeysAttribute):Connect(onKeysChanged)
LocalPlayer:GetAttributeChangedSignal(ArenaConfig.OpenedAttribute):Connect(onOpenedChanged)
LocalPlayer:GetAttributeChangedSignal("CameraZone"):Connect(refreshVisibility)
LocalPlayer:GetAttributeChangedSignal(ArenaConfig.ClearsAttribute):Connect(function()
	if (LocalPlayer:GetAttribute(ArenaConfig.ClearsAttribute) or 0) > 0 then
		showToast("Arena cleared!", Color3.fromRGB(255, 225, 80))
	end
end)
onKeysChanged()
onOpenedChanged()
refreshVisibility()

RunService.RenderStepped:Connect(function()
	local now = os.clock()
	local spin = CFrame.Angles(0, (now * SPIN_SPEED) % (2 * math.pi), 0)
	local bob = CFrame.new(0, math.sin(now * 2) * BOB_HEIGHT, 0)
	for _, state in keyModels do
		if not state.hidden then
			state.visual:PivotTo(CFrame.new(state.base.Position) * bob * spin)
		end
	end
end)
