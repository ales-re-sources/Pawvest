-- ArenaClient: what the local player sees of the Laser Lab's Key Vault (Stage 14 room 1, ArenaConfig / ArenaServer). Everything
-- here is local: a key the player holds disappears for them only, a gate they opened fades out and stops colliding for them
-- only (the client owns its character's physics, like GateDoors); a ClosesWhenOpen gate fades in instead, a KillWhileShut
-- strip stops killing, an OpensWhenHeld gate opens on the key pickup itself (no lock). Every part tagged with a gate's KeyId
-- goes with it (the full-height Pillar_Lock and its lock decor). Also the key chips (shown inside the vault's camera zone) and
-- short toasts, built in code.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ArenaConfig = require(ReplicatedStorage:WaitForChild("ArenaConfig"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))

local LocalPlayer = Players.LocalPlayer

local SPIN_SPEED = math.rad(100) -- key spin around the world Y axis, per second
local BOB_HEIGHT = 0.5 -- studs
local OPEN_TRANSPARENCY = 1 -- an opened gate disappears
local FADE_TIME = 0.8 -- seconds a gate takes to fade out (or in) when a key changes it
local KILL_TAG = "KitKill" -- ObstacleKit's static kill part
local TOAST_TIME = 2.5
-- The key chips ride on the stage timer's row (StarterGui.ScreenGui.StageTimer, Studio-authored, centred at 5 % of the
-- screen height, 50 px tall), right of its text, so they cost no screen height (a bar under the timer covered too much
-- of a phone's view); the toast shows under the timer for a moment.
local TIMER_Y = 0.05
local TIMER_HALF = 25
local CHIP_GAP = 12 -- px between the timer text and the chips

local keyModels = {} -- [hit part] = { visual = Model, base = CFrame, parts = { [part] = transparency }, lights = { Light }, hidden = boolean }
local gates = {} -- [part] = { transparency = number, collide = boolean, touch = boolean, tween = Tween? }
local held = {} -- keys held (ArenaKeys)
local opened = {} -- gates opened (ArenaOpened)

------------------------------------------------------------------ HUD
local gui = Instance.new("ScreenGui")
gui.Name = "ArenaGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 5
gui.Enabled = false
gui.AutoLocalize = false -- translated by Locale (L2)
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local bar = Instance.new("Frame")
bar.AnchorPoint = Vector2.new(0, 0.5)
bar.Position = UDim2.new(0.5, CHIP_GAP, TIMER_Y, 0)
bar.AutomaticSize = Enum.AutomaticSize.XY
bar.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
bar.BackgroundTransparency = 0.35
bar.Parent = gui
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 8)
local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 6)
padding.PaddingRight = UDim.new(0, 6)
padding.PaddingTop = UDim.new(0, 5)
padding.PaddingBottom = UDim.new(0, 5)
padding.Parent = bar
local list = Instance.new("UIListLayout")
list.FillDirection = Enum.FillDirection.Horizontal
list.Padding = UDim.new(0, 6)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = bar

local slots = {} -- [keyId] = Frame (filled when held)
for index, id in ArenaConfig.Keys do
	local slot = Instance.new("Frame")
	slot.LayoutOrder = index
	slot.Size = UDim2.fromOffset(28, 18)
	slot.BackgroundColor3 = ArenaConfig.KeyColors[id]
	slot.BackgroundTransparency = 0.85
	slot.Parent = bar
	Instance.new("UICorner", slot).CornerRadius = UDim.new(0, 5)
	local stroke = Instance.new("UIStroke")
	stroke.Color = ArenaConfig.KeyColors[id]
	stroke.Thickness = 2
	stroke.Parent = slot
	slots[id] = slot
end

-- right of the timer's text while a run shows it, else centred where the timer would be
local timerLabel: TextLabel? = nil
local function placeChips()
	if not (timerLabel and timerLabel.Parent) then
		local screen = LocalPlayer.PlayerGui:FindFirstChild("ScreenGui")
		local found = screen and screen:FindFirstChild("StageTimer")
		timerLabel = if found and found:IsA("TextLabel") then found else nil
	end
	if timerLabel and timerLabel.Visible and timerLabel.Text ~= "" then
		bar.AnchorPoint = Vector2.new(0, 0.5)
		bar.Position = UDim2.new(0.5, math.ceil(timerLabel.TextBounds.X / 2) + CHIP_GAP, TIMER_Y, 0)
	else
		bar.AnchorPoint = Vector2.new(0.5, 0.5)
		bar.Position = UDim2.new(0.5, 0, TIMER_Y, 0)
	end
end

local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, TIMER_Y, TIMER_HALF + 8) -- under the timer
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
	for _, light in state.lights do
		light.Enabled = not hidden -- the key's glow goes with it
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
	local state = { visual = visual, base = visual:GetPivot(), parts = {}, lights = {}, hidden = false }
	for _, part in visual:GetDescendants() do
		if part:IsA("BasePart") then
			state.parts[part] = part.Transparency
		elseif part:IsA("Light") then
			table.insert(state.lights, part)
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
local function refreshGate(part: BasePart, state, fade: boolean?)
	local id = part:GetAttribute(ArenaConfig.KeyAttribute)
	local isOpen = (if part:GetAttribute(ArenaConfig.HeldAttribute) == true then held[id] else opened[id]) == true
	local shut = isOpen == (part:GetAttribute(ArenaConfig.ClosesAttribute) == true)
	if part:GetAttribute(ArenaConfig.KillAttribute) == true then
		-- a local tag change: ObstacleKit stops (or starts) testing the strip for this player only
		if shut then
			CollectionService:AddTag(part, KILL_TAG)
		else
			CollectionService:RemoveTag(part, KILL_TAG)
		end
	else
		-- decor tagged with its gate (the lock on Pillar_Lock) only fades: it never starts colliding
		part.CanCollide = shut and state.collide
		part.CanTouch = shut and state.touch
	end
	local transparency = if shut then state.transparency else OPEN_TRANSPARENCY
	if state.tween then
		state.tween:Cancel()
		state.tween = nil
	end
	if fade and part.Transparency ~= transparency then
		state.tween = TweenService:Create(part, TweenInfo.new(FADE_TIME), { Transparency = transparency })
		state.tween:Play()
	else
		part.Transparency = transparency
	end
end

local function addGate(part: Instance)
	if not part:IsA("BasePart") or gates[part] then
		return
	end
	local state = { transparency = part.Transparency, collide = part.CanCollide, touch = part.CanTouch }
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
			showToast(Locale.T("arena.keyCollected." .. id), ArenaConfig.KeyColors[id])
		end
	end
	refreshKeys()
	for part, state in gates do
		refreshGate(part, state, true) -- an OpensWhenHeld gate follows the held keys
	end
end

local function onOpenedChanged()
	local previous = opened
	opened = ArenaConfig.Decode(LocalPlayer:GetAttribute(ArenaConfig.OpenedAttribute))
	for _, id in names(opened) do
		if not previous[id] then
			showToast(Locale.T("arena.gateOpened." .. id), ArenaConfig.KeyColors[id])
		end
	end
	for part, state in gates do
		refreshGate(part, state, true)
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
onKeysChanged()
onOpenedChanged()
refreshVisibility()

RunService.RenderStepped:Connect(function()
	if gui.Enabled then
		placeChips()
	end
	local now = os.clock()
	local spin = CFrame.Angles(0, (now * SPIN_SPEED) % (2 * math.pi), 0)
	local bob = CFrame.new(0, math.sin(now * 2) * BOB_HEIGHT, 0)
	for _, state in keyModels do
		if not state.hidden then
			state.visual:PivotTo(CFrame.new(state.base.Position) * bob * spin)
		end
	end
end)
