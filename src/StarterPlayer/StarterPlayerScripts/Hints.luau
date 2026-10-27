-- Hints (docs/GDD.md §11, ROADMAP G1): the one place that draws "you can do something here" signals for the local player.
--   Hints.SetDot(target, source, on)        red dot on a button while any source wants it; one pulse when it appears.
--                                           Targets: "SkillsButton", "PetsButton" (top-left icons), "PetsGarden" (the Pets
--                                           panel's "Go to my garden"). The icons' ScreenGui is re-created on every respawn,
--                                           so the dots are re-attached by the loop below.
--   Hints.SetMarker(id, adornee, key, height)  world marker (green disc, chevron, label `Locale.T(key)`) `height` studs above
--                                           `adornee`; nil adornee removes it. A ScreenGui frame: on top of everything at a
--                                           constant size; at the screen edge pointing at the target when it is off screen;
--                                           hidden during a run and within HIDE_DISTANCE studs of its target.
--   Hints.Toast(text)                       one line at the bottom of the screen; waits while a run is active.
--   Hints.Running                           true while a stage run is active (StageTimerUpdate).
-- Display only: nothing here talks to the server. The hints themselves live in HintSources.client.luau.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local HIDE_DISTANCE = 25 -- studs (horizontal) from a marker's target: the player has found it
local MARKER_GREEN = Color3.fromRGB(70, 200, 90)
local MARKER_WIDTH, MARKER_HEIGHT = 140, 84 -- pixels: disc on top, label under it
local DISC_SIZE = 52 -- pixels
local BOB_PIXELS = 5
local EDGE_INSET = 60 -- pixels: an off-screen marker stays this far inside the screen edge
local DOT_RED = Color3.fromRGB(230, 55, 50)
local DOT_SIZE = 16 -- pixels
local TOAST_SECONDS = 4

local Hints = {}
Hints.Running = false

-- Run state ---------------------------------------------------------------------------------------------------------------

local toastQueue = {}
local showNextToast -- defined below

ReplicatedStorage:WaitForChild("StageTimerUpdate").OnClientEvent:Connect(function(elapsed)
	local running = type(elapsed) == "number" and elapsed >= 0
	if running ~= Hints.Running then
		Hints.Running = running
		if not running then
			showNextToast()
		end
	end
end)

-- Dots --------------------------------------------------------------------------------------------------------------------

local function findTarget(target: string): GuiObject?
	if target == "PetsGarden" then
		local petsGui = playerGui:FindFirstChild("PetsGui")
		local button = petsGui and petsGui:FindFirstChild("Garden", true)
		return if button and button:IsA("GuiObject") then button else nil
	end
	local screenGui = playerGui:FindFirstChild("ScreenGui")
	local icons = screenGui and screenGui:FindFirstChild("TopLeftIcons")
	local button = icons and icons:FindFirstChild(target)
	return if button and button:IsA("GuiObject") then button else nil
end

local dotSources = {} -- [target] = { [source] = true }

local function newDot(): Frame
	local dot = Instance.new("Frame")
	dot.Name = "HintDot"
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.new(1, -3, 0, 3)
	dot.Size = UDim2.fromOffset(DOT_SIZE, DOT_SIZE)
	dot.BackgroundColor3 = DOT_RED
	dot.ZIndex = 10
	Instance.new("UICorner", dot).CornerRadius = UDim.new(0.5, 0)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = 2
	stroke.Parent = dot
	local scale = Instance.new("UIScale")
	scale.Scale = 1.8
	scale.Parent = dot
	TweenService:Create(scale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	return dot
end

local function applyDot(target: string)
	local button = findTarget(target)
	if not button then
		return
	end
	local want = next(dotSources[target] or {}) ~= nil
	local dot = button:FindFirstChild("HintDot")
	if want and not dot then
		newDot().Parent = button
	elseif dot and not want then
		dot:Destroy()
	end
end

function Hints.SetDot(target: string, source: string, on: boolean)
	local sources = dotSources[target] or {}
	dotSources[target] = sources
	sources[source] = if on then true else nil
	applyDot(target)
end

-- Markers -----------------------------------------------------------------------------------------------------------------
-- A ScreenGui frame placed every frame at the projected world point (a BillboardGui with AlwaysOnTop did not show in
-- Studio captures, and one without it is hidden by signs). Off screen or behind the camera it sits at the screen edge and
-- its chevron points towards the target.

local markerGui = Instance.new("ScreenGui")
markerGui.Name = "HintMarkers"
markerGui.ResetOnSpawn = false
markerGui.IgnoreGuiInset = true -- frame positions are viewport pixels
markerGui.AutoLocalize = false -- translated by Locale
markerGui.DisplayOrder = 1 -- under the panels and popups
markerGui.Parent = playerGui

local markers = {} -- [id] = { frame, arrow, label, key, adornee, height }

local function newMarker(): (Frame, Frame, TextLabel)
	local frame = Instance.new("Frame")
	frame.Name = "HintMarker"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromOffset(MARKER_WIDTH, MARKER_HEIGHT)
	frame.Visible = false

	local disc = Instance.new("Frame")
	disc.Name = "Disc"
	disc.AnchorPoint = Vector2.new(0.5, 0)
	disc.Position = UDim2.fromScale(0.5, 0)
	disc.Size = UDim2.fromOffset(DISC_SIZE, DISC_SIZE)
	disc.BackgroundColor3 = MARKER_GREEN
	disc.Parent = frame
	Instance.new("UICorner", disc).CornerRadius = UDim.new(0.5, 0)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = 3
	stroke.Parent = disc
	-- a chevron from two bars meeting under the centre; the Arrow frame turns it (0 = pointing down)
	local arrow = Instance.new("Frame")
	arrow.Name = "Arrow"
	arrow.BackgroundTransparency = 1
	arrow.Size = UDim2.fromScale(1, 1)
	arrow.Parent = disc
	for _, side in { -1, 1 } do
		local bar = Instance.new("Frame")
		bar.AnchorPoint = Vector2.new(0.5, 0.5)
		bar.Position = UDim2.new(0.5, side * 7, 0.5, 2)
		bar.Size = UDim2.fromOffset(22, 7)
		bar.Rotation = side * -45
		bar.BackgroundColor3 = Color3.new(1, 1, 1)
		bar.BorderSizePixel = 0
		bar.Parent = arrow
		Instance.new("UICorner", bar).CornerRadius = UDim.new(0.5, 0)
	end

	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.fromScale(0.5, 1)
	label.Size = UDim2.new(1, 0, 0, 26)
	label.BackgroundTransparency = 1
	label.Font = StudStyle.Font
	label.TextSize = 22
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeColor3 = Color3.fromRGB(20, 60, 25)
	label.TextStrokeTransparency = 0
	label.Parent = frame

	frame.Parent = markerGui
	return frame, arrow, label
end

function Hints.SetMarker(id: string, adornee: BasePart?, key: string?, height: number?)
	local marker = markers[id]
	if not adornee then
		if marker then
			marker.frame:Destroy()
			markers[id] = nil
		end
		return
	end
	if not marker then
		local frame, arrow, label = newMarker()
		marker = { frame = frame, arrow = arrow, label = label }
		markers[id] = marker
	end
	marker.adornee = adornee
	marker.height = height or 6
	if marker.key ~= key then
		marker.key = key
		marker.label.Text = if key then Locale.T(key) else ""
	end
end

-- The marker's frame (tests read Visible and Arrow.Rotation); nil when the marker is not set.
function Hints.Marker(id: string): Frame?
	local marker = markers[id]
	return marker and marker.frame
end

Locale.Changed:Connect(function()
	for _, marker in markers do
		marker.label.Text = if marker.key then Locale.T(marker.key) else ""
	end
end)

local function placeMarkers()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera
	local view = camera.ViewportSize
	local bob = math.sin(os.clock() * math.pi / 0.8) * BOB_PIXELS
	for _, marker in markers do
		local show = not Hints.Running and root ~= nil and marker.adornee.Parent ~= nil
		if show then
			local offset = marker.adornee.Position - root.Position
			show = Vector2.new(offset.X, offset.Z).Magnitude > HIDE_DISTANCE
		end
		marker.frame.Visible = show
		if show then
			local target = marker.adornee.Position + Vector3.new(0, marker.height, 0)
			local point = camera:WorldToViewportPoint(target)
			local onScreen = point.Z > 0
				and point.X >= EDGE_INSET and point.X <= view.X - EDGE_INSET
				and point.Y >= EDGE_INSET and point.Y <= view.Y - EDGE_INSET
			if onScreen then
				marker.frame.AnchorPoint = Vector2.new(0.5, 1)
				marker.frame.Position = UDim2.fromOffset(point.X, point.Y + bob)
				marker.arrow.Rotation = 0
			else
				-- from the screen centre towards the target in camera space (screen y points down), clamped to the edge; a
				-- target behind the camera goes to the bottom edge, towards its side ("turn around")
				local centre = view / 2
				local relative = camera.CFrame:PointToObjectSpace(target)
				local direction = Vector2.new(relative.X, -relative.Y)
				if relative.Z > 0 then
					direction = Vector2.new(relative.X, math.max(direction.Y, 0) + relative.Z)
				end
				if direction.Magnitude < 1e-3 then
					direction = Vector2.new(0, 1)
				end
				local scale = math.min(
					(centre.X - EDGE_INSET) / math.max(math.abs(direction.X), 1e-3),
					(centre.Y - EDGE_INSET) / math.max(math.abs(direction.Y), 1e-3)
				)
				local spot = centre + direction * scale
				marker.frame.AnchorPoint = Vector2.new(0.5, 0.5)
				marker.frame.Position = UDim2.fromOffset(spot.X, spot.Y)
				marker.arrow.Rotation = math.deg(math.atan2(direction.Y, direction.X)) - 90
			end
		end
	end
end

RunService.RenderStepped:Connect(placeMarkers)

-- Toast -------------------------------------------------------------------------------------------------------------------

local toastGui = Instance.new("ScreenGui")
toastGui.Name = "HintToast"
toastGui.ResetOnSpawn = false
toastGui.AutoLocalize = false -- translated by Locale
toastGui.DisplayOrder = 6
local toastLabel = Instance.new("TextLabel")
toastLabel.AnchorPoint = Vector2.new(0.5, 1)
toastLabel.Position = UDim2.new(0.5, 0, 1, -170)
toastLabel.Size = UDim2.fromOffset(0, 0)
toastLabel.AutomaticSize = Enum.AutomaticSize.XY -- grows with the text up to the width below, then wraps (Czech is longer)
toastLabel.TextWrapped = true
toastLabel.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
toastLabel.BackgroundTransparency = 0.15
toastLabel.Font = StudStyle.Font
toastLabel.TextSize = 22
toastLabel.TextColor3 = Color3.fromRGB(150, 240, 150)
toastLabel.Visible = false
toastLabel.Parent = toastGui
Instance.new("UICorner", toastLabel).CornerRadius = UDim.new(0, 10)
local toastPadding = Instance.new("UIPadding")
toastPadding.PaddingLeft = UDim.new(0, 16)
toastPadding.PaddingRight = UDim.new(0, 16)
toastPadding.PaddingTop = UDim.new(0, 10)
toastPadding.PaddingBottom = UDim.new(0, 10)
toastPadding.Parent = toastLabel
local toastLimit = Instance.new("UISizeConstraint")
toastLimit.MaxSize = Vector2.new(460, math.huge)
toastLimit.Parent = toastLabel
toastGui.Parent = playerGui

local toastShowing = false
showNextToast = function()
	if toastShowing or Hints.Running or #toastQueue == 0 then
		return
	end
	toastShowing = true
	toastLabel.Text = table.remove(toastQueue, 1)
	toastLabel.Visible = true
	task.delay(TOAST_SECONDS, function()
		toastLabel.Visible = false
		toastShowing = false
		task.wait(0.3)
		showNextToast()
	end)
end

function Hints.Toast(text: string)
	table.insert(toastQueue, text)
	showNextToast()
end

-- Loop: dots re-attached after a respawn re-created the icons.
task.spawn(function()
	while true do
		for target in dotSources do
			applyDot(target)
		end
		task.wait(0.25)
	end
end)

return Hints
