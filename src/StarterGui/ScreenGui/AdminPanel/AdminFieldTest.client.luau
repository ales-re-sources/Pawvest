-- Admin field test (CG perf / phone checks): a button that fills every plot of ring 1 (the plots a full server can hold) with a
-- full field of one crop, ripe, with growth art, through GardenView's test hook (Workspace attributes GardenViewFake /
-- GardenViewField / GardenViewCrop), and shows a frame-rate readout. Works in a live game, so it runs on a real phone.
-- Drawing on this client only: no remotes, no saved data; the real field stays as it is (tapping it still acts on it).
-- Each tap moves to the next mode: off → Sunflower (heaviest art) → Garlic (lightest, for comparison) → off.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local AdminConfig = require(ReplicatedStorage:WaitForChild("AdminConfig"))
if not AdminConfig.IsAdmin(player.UserId) then return end

local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))

local MODES = { false, "Sunflower", "Garlic" }
local PLOTS = math.min(GardenConfig.ShownFreeSlots, GardenConfig.PlotSlots)
local WORST_WINDOW = 5 -- seconds of frames the slowest-frame figure looks back over
local mode = 1

local panel = script.Parent
local resetButton = panel:WaitForChild("ScoreResetButton")
local button = resetButton:Clone()
for _, child in button:GetDescendants() do
	if child:IsA("LuaSourceContainer") then child:Destroy() end
end
button.Name = "FieldTestButton"
button.LayoutOrder = resetButton.LayoutOrder + 3
button.Size = UDim2.new(resetButton.Size.X.Scale, resetButton.Size.X.Offset, 0, 48)
button.AutoLocalize = false
button.TextSize, button.TextScaled, button.TextWrapped = 18, false, true
button.BackgroundColor3 = StudStyle.Colors.Green

-- the panel's ScreenGui may be rebuilt on respawn: keep the mode the attributes hold, replace the old readout
for i, cropId in MODES do
	if cropId and workspace:GetAttribute("GardenViewCrop") == cropId then mode = i end
end
local playerGui = player:WaitForChild("PlayerGui")
local old = playerGui:FindFirstChild("FieldTestHud")
if old then old:Destroy() end

-- Readout ------------------------------------------------------------------------------------------------------------------
local hud = Instance.new("ScreenGui")
hud.Name = "FieldTestHud"
hud.ResetOnSpawn = false
hud.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
hud.AutoLocalize = false
hud.DisplayOrder = 50
hud.Enabled = MODES[mode] ~= false
local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0, 4)
label.AutomaticSize = Enum.AutomaticSize.XY
label.Size = UDim2.fromOffset(0, 0)
label.BackgroundColor3 = Color3.new(0, 0, 0)
label.BackgroundTransparency = 0.35
label.TextColor3 = Color3.new(1, 1, 1)
label.Font = Enum.Font.GothamBold
label.TextSize = 16
local padding = Instance.new("UIPadding")
padding.PaddingLeft, padding.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
padding.PaddingTop, padding.PaddingBottom = UDim.new(0, 3), UDim.new(0, 3)
padding.Parent = label
label.Parent = hud
hud.Parent = playerGui

-- instances drawn by GardenView, counted by signals (a GetDescendants walk would itself show as a slow frame)
local drawn = 0
task.spawn(function()
	local garden = workspace:WaitForChild("GardenView")
	drawn = #garden:GetDescendants()
	garden.DescendantAdded:Connect(function() drawn += 1 end)
	garden.DescendantRemoving:Connect(function() drawn -= 1 end)
end)

local frames = {} -- { at, dt } of recent frames
local shownAt = 0
local function readout()
	local now = os.clock()
	local count, worst = 0, 0
	local keep = {}
	for _, frame in frames do
		if now - frame.at <= WORST_WINDOW then
			table.insert(keep, frame)
			worst = math.max(worst, frame.dt)
			if now - frame.at <= 1 then count += 1 end
		end
	end
	frames = keep
	label.Text = Locale.T("admin.fieldtest.stats", { fps = count, ms = math.round(worst * 1000), objects = drawn })
end
RunService.Heartbeat:Connect(function(dt)
	if not hud.Enabled then return end
	table.insert(frames, { at = os.clock(), dt = dt })
	if os.clock() - shownAt >= 0.5 then
		shownAt = os.clock()
		readout()
	end
end)

-- Modes --------------------------------------------------------------------------------------------------------------------
local function render()
	local cropId = MODES[mode]
	if cropId then
		button.Text = Locale.T("admin.fieldtest.on", { crop = Locale.CropName(CropConfig.ById[cropId]), plots = PLOTS })
	else
		button.Text = Locale.T("admin.fieldtest.off")
	end
	if hud.Enabled then readout() end
end

local function apply()
	local cropId = MODES[mode]
	workspace:SetAttribute("GardenViewCrop", cropId or nil)
	workspace:SetAttribute("GardenViewField", if cropId then CropConfig.MaxSquares else nil)
	workspace:SetAttribute("GardenViewFake", if cropId then PLOTS else nil)
	frames = {}
	hud.Enabled = cropId ~= false
	render()
end

render()
StudStyle.Brick(button, { studs = 4 })
button.Parent = panel
panel.Size += UDim2.fromOffset(0, button.Size.Y.Offset + 10)

button.Activated:Connect(function()
	mode = mode % #MODES + 1
	apply()
end)
Locale.Changed:Connect(render)
