-- GardenBubble (U2, docs/GDD.md §7.9): the summary bubble over the local player's own plot sign, so what waits in the garden
-- reads without opening a panel: "🧺 4 ripe · ⏱ 2:14 · 🥚 Ready!" with only the parts that apply (ripe crops, the time to the
-- next ripe crop while something grows, a ready egg; U4: "🐦 0:45" while the next crows are less than CROW_SOON away, "🐦 now!"
-- while they are on, only once crows come to this field: State.field.crows.active, schedule from CropConfig.NextCrows); nothing
-- planted -> "🌱 Plant seeds". Counts from GardenSummary, updated
-- every half second (so no second is skipped) from workspace:GetServerTimeNow(). Only the own plot has one (other plots show their sign and crops).
-- Shown while the character is within SHOW_DISTANCE studs (horizontal) of the sign or anywhere on the garden's central plaza
-- (inside plot ring 1); a constant size on screen (pixels) and AlwaysOnTop: without it the food stand and the follower pets'
-- labels hide it from the plaza (U2 check). Studio captures do not show AlwaysOnTop billboards: check it by its properties
-- (or switch AlwaysOnTop off for a capture). Client-local: an invisible anchor part "GardenBubble" in Workspace.
-- Display only: nothing here talks to the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local TimeFormat = require(ReplicatedStorage:WaitForChild("TimeFormat"))
local GardenSummary = require(script.Parent:WaitForChild("GardenSummary"))
local GardenView = require(script.Parent:WaitForChild("GardenView"))

local player = Players.LocalPlayer

local SHOW_DISTANCE = 120 -- studs (horizontal) from the sign
local PLAZA_RADIUS = GardenConfig.PlotRings[1].radius - GardenConfig.PlotSize / 2 -- the plaza: inside the inner ring's fronts
local SIGN_SPOT = Vector3.new(0, 16, -22) -- plot floor space: above the name sign's top bar (PlotView: z -22, top bar 12.4)
local TEXT_SIZE = 24 -- pixels
local CROW_SOON = 3600 -- seconds: the crow part shows from this long before the crows come
local COLOR_BACK = Color3.fromRGB(70, 46, 28) -- the sign's wood, darker
local COLOR_EDGE = Color3.fromRGB(255, 205, 150) -- the sign's number colour

local anchor = Instance.new("Part")
anchor.Name = "GardenBubble"
anchor.Anchored = true
anchor.CanCollide = false
anchor.CanTouch = false
anchor.CanQuery = false
anchor.CastShadow = false
anchor.Transparency = 1
anchor.Size = Vector3.new(1, 1, 1)

local gui = Instance.new("BillboardGui")
gui.Name = "Bubble"
gui.AutoLocalize = false -- translated by Locale
gui.Size = UDim2.fromOffset(560, 56)
gui.LightInfluence = 0
gui.AlwaysOnTop = true
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = anchor

local pill = Instance.new("Frame")
pill.Name = "Pill"
pill.AnchorPoint = Vector2.new(0.5, 0.5)
pill.Position = UDim2.fromScale(0.5, 0.5)
pill.AutomaticSize = Enum.AutomaticSize.XY
pill.Size = UDim2.new()
pill.BackgroundColor3 = COLOR_BACK
pill.BackgroundTransparency = 0.1
pill.Parent = gui
Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 14)
local stroke = Instance.new("UIStroke")
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Color = COLOR_EDGE
stroke.Thickness = 2
stroke.Parent = pill
local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 14)
padding.PaddingRight = UDim.new(0, 14)
padding.PaddingTop = UDim.new(0, 6)
padding.PaddingBottom = UDim.new(0, 6)
padding.Parent = pill

local label = Instance.new("TextLabel")
label.Name = "Text"
label.AutomaticSize = Enum.AutomaticSize.XY
label.Size = UDim2.new()
label.BackgroundTransparency = 1
label.Font = StudStyle.Font
label.TextSize = TEXT_SIZE
label.TextColor3 = Color3.fromRGB(255, 240, 210)
label.TextStrokeTransparency = 0.6
label.Parent = pill

anchor.Parent = workspace

-- The bubble's text now, or nil when there is nothing to show yet.
local function textOf(now: number): string?
	local summary = GardenSummary.Get(now)
	if not summary.known then
		return nil
	end
	local parts = {}
	if summary.planted == 0 then
		table.insert(parts, Locale.T("garden.bubble.plant"))
	end
	if summary.ripe > 0 then
		table.insert(parts, Locale.T("garden.bubble.ripe", { count = summary.ripe }))
	end
	if summary.nextAt then
		table.insert(parts, Locale.T("garden.bubble.time", { time = TimeFormat.Clock(math.max(summary.nextAt - now, 1)) }))
	end
	if summary.eggs > 0 then
		table.insert(parts, Locale.T("garden.bubble.egg"))
	end
	local field = GardenView.OwnField()
	local crows = field and field.crows
	if type(crows) == "table" and crows.active then
		local from, to = CropConfig.NextCrows(now, CROW_SOON)
		if from and to and from <= now then
			table.insert(parts, Locale.T("garden.bubble.crowsNow"))
		elseif from then
			table.insert(parts, Locale.T("garden.bubble.crows", { time = TimeFormat.Clock(from - now) }))
		end
	end
	return if #parts > 0 then table.concat(parts, "  ·  ") else nil
end

local function update()
	local slot = player:GetAttribute(GardenConfig.PlotAttribute)
	local plot = slot and GardenConfig.PlotCFrame(slot)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local text = plot and textOf(workspace:GetServerTimeNow())
	if not (plot and root and text) then
		gui.Enabled = false
		return
	end
	local spot = (plot :: CFrame) * SIGN_SPOT
	if anchor.Position ~= spot then
		anchor.CFrame = CFrame.new(spot)
	end
	local at = (root :: BasePart).Position
	local fromSign = Vector3.new(at.X - spot.X, 0, at.Z - spot.Z).Magnitude
	local centre = GardenConfig.PlotCentre
	local fromCentre = Vector3.new(at.X - centre.X, 0, at.Z - centre.Z).Magnitude
	gui.Enabled = fromSign <= SHOW_DISTANCE or fromCentre <= PLAZA_RADIUS
	label.Text = text :: string
end

Locale.Changed:Connect(update)
while true do
	update()
	task.wait(0.5)
end
