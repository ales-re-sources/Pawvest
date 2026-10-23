-- GatePrompts (docs/STAGES.md §7.1): the way a shut gate is opened. A shut stage door (Workspace.<Stage>.Gate.Door) and a shut
-- world gate in the hub carry a ProximityPrompt ("Unlock · 500 Coins", hold E / tap the button) that appears when the player
-- walks up to it; the requirement itself is already written on the gate face (HubPortalMedals / HubGateFaces). Triggering only
-- asks the server (UnlockRemotes.Buy: stageKey); the server prices and decides, and a short toast reports the answer. Once the
-- stage (or, for a world gate, any stage of the world) is open the prompt is gone. Prompts are local to the player's client.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local remotes = ReplicatedStorage:WaitForChild("UnlockRemotes")
local buyEvent = remotes:WaitForChild("Buy")
local resultEvent = remotes:WaitForChild("Result")

local player = Players.LocalPlayer

local COLOR_OK = Color3.fromRGB(120, 230, 120)
local COLOR_ERROR = Color3.fromRGB(240, 100, 90)
local TOAST_SECONDS = 2.5

local REJECT_KEYS = {
	coins = "gate.reject.coins",
	owned = "gate.reject.owned",
	loading = "gate.reject.loading",
}

-- ---- toast: one short line at the bottom of the screen ----
local toastLabel = Instance.new("TextLabel")
toastLabel.AnchorPoint = Vector2.new(0.5, 1)
toastLabel.Position = UDim2.new(0.5, 0, 1, -120)
toastLabel.Size = UDim2.fromOffset(360, 40)
toastLabel.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
toastLabel.BackgroundTransparency = 0.15
toastLabel.Font = Enum.Font.GothamBold
toastLabel.TextSize = 18
toastLabel.TextColor3 = Color3.new(1, 1, 1)
toastLabel.Visible = false
Instance.new("UICorner", toastLabel).CornerRadius = UDim.new(0, 10)
local toastGui = Instance.new("ScreenGui")
toastGui.Name = "GateToast"
toastGui.ResetOnSpawn = false
toastGui.AutoLocalize = false -- translated by Locale (L1)
toastGui.DisplayOrder = 6
toastLabel.Parent = toastGui
toastGui.Parent = player:WaitForChild("PlayerGui")

local toastGeneration = 0
local function toast(text: string, color: Color3)
	toastGeneration += 1
	local mine = toastGeneration
	toastLabel.Text = text
	toastLabel.TextColor3 = color
	toastLabel.TextTransparency = 0
	toastLabel.BackgroundTransparency = 0.15
	toastLabel.Visible = true
	task.delay(TOAST_SECONDS, function()
		if mine ~= toastGeneration then
			return
		end
		local info = TweenInfo.new(0.3)
		TweenService:Create(toastLabel, info, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		task.delay(0.3, function()
			if mine == toastGeneration then
				toastLabel.Visible = false
			end
		end)
	end)
end

-- ---- prompts ----
local coins = 0
local refreshers = {}

-- `stage` is the stage the prompt buys; `watched` the stages whose Unlocked_ attributes decide whether the gate is open;
-- `objectText` returns the gate's name in the current language
local function addPrompt(adornee: BasePart, stage, objectText: () -> string, watched)
	local price = stage.unlockPrice
	if not price then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "UnlockPrompt"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.UIOffset = Vector2.new(0, 60)
	prompt.Parent = adornee

	local function refresh()
		local open = false
		for _, other in watched do
			if player:GetAttribute(StageConfig.UnlockedAttribute(other)) == true then
				open = true
			end
		end
		prompt.Enabled = not open
		prompt.ObjectText = objectText()
		prompt.ActionText = Locale.T(if coins >= price then "gate.prompt.unlock" else "gate.prompt.needs", { count = price })
	end
	for _, other in watched do
		player:GetAttributeChangedSignal(StageConfig.UnlockedAttribute(other)):Connect(refresh)
	end
	table.insert(refreshers, refresh)
	refresh()

	prompt.Triggered:Connect(function(who)
		if who == player then
			buyEvent:FireServer(stage.key)
		end
	end)
end

for _, stage in StageConfig.Stages do
	if StageConfig.Worlds[stage.world] and stage.unlock then
		task.spawn(function()
			addPrompt(StageConfig.FaceTarget(stage), stage, function()
				return Locale.StageName(stage)
			end, { stage })
		end)
	end
end
for _, world in StageConfig.Worlds do
	local stages = StageConfig.StagesOfWorld(world.index)
	local entry = stages[1]
	if entry and entry.unlock then
		task.spawn(function()
			addPrompt(StageConfig.WorldGatePortal(world), entry, function()
				return Locale.WorldName(world)
			end, stages)
		end)
	end
end

resultEvent.OnClientEvent:Connect(function(stageKey, ok, reason)
	local stage = StageConfig.ByKey[stageKey]
	if ok then
		local first = stage and StageConfig.StagesOfWorld(stage.world)[1] == stage
		local world = stage and StageConfig.Worlds[stage.world]
		local name = if first and world
			then Locale.WorldName(world)
			elseif stage then Locale.StageName(stage)
			else Locale.T("gate.toast.gate")
		toast(Locale.T("gate.toast.unlocked", { name = name }), COLOR_OK)
	else
		toast(Locale.T(REJECT_KEYS[reason] or "gate.reject.failed"), COLOR_ERROR)
	end
end)

Locale.Changed:Connect(function()
	for _, refresh in refreshers do
		refresh()
	end
end)

task.spawn(function()
	local coinValue = player:WaitForChild("leaderstats"):WaitForChild("Coins") :: IntValue
	coins = coinValue.Value
	for _, refresh in refreshers do
		refresh()
	end
	coinValue:GetPropertyChangedSignal("Value"):Connect(function()
		coins = coinValue.Value
		for _, refresh in refreshers do
			refresh()
		end
	end)
end)
