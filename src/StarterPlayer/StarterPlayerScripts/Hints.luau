-- Hints (docs/GDD.md §11, ROADMAP G1): the one place that draws "you can do something here" signals for the local player.
--   Hints.SetDot(target, source, on)        red dot on a button while any source wants it; one pulse when it appears.
--                                           Targets: "SkillsButton", "PetsButton" (top-left icons), "PetsGarden" (the Pets
--                                           panel's "Go to my garden"). The icons' ScreenGui is re-created on every respawn,
--                                           so the dots are re-attached by the loop below.
--   Hints.SetMarker(id, adornee, label, height)  world marker: an orange arrow with the text `label()` (re-read when the
--                                           language changes), `height` studs above `adornee`; nil adornee removes it. Drawn
--                                           in a ScreenGui (on top of everything, constant size). In view it bobs above the
--                                           target pointing down; off screen (also a far target above the top of the screen,
--                                           as seen from a steep top-down camera) it sits on the screen edge pointing at it (a
--                                           target behind the camera: the left / right edge of the shorter turn), the label
--                                           on the side towards the screen centre. Hidden during a run and within
--                                           HIDE_DISTANCE studs of its target.
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
local ARROW_ORANGE = Color3.fromRGB(255, 154, 31) -- no status uses orange: it only means "go here"
local ARROW_INK = Color3.fromRGB(122, 58, 0) -- label outline
local ARROW_WIDTH, ARROW_HEIGHT = 54, 68 -- pixels, the white outline included
local BOB_PIXELS = 5
local TURN_SPEED = 12 -- the arrow's rotation eases towards its target angle (about 0.15 s)
local EDGE_INSET = 60 -- pixels: an off-screen marker stays this far inside the left / right screen edge
local EDGE_TOP = 150 -- pixels: and below the top-left icons and the score panel
local EDGE_BOTTOM = 0.3 -- share of the screen height kept free at the bottom (touch joystick and jump button)
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
-- ScreenGui frames placed every frame at the projected world point (a BillboardGui with AlwaysOnTop did not show in Studio
-- captures, and one without it is hidden by signs).

local markerGui = Instance.new("ScreenGui")
markerGui.Name = "HintMarkers"
markerGui.ResetOnSpawn = false
markerGui.IgnoreGuiInset = true -- frame positions are viewport pixels
markerGui.AutoLocalize = false -- translated by Locale
markerGui.DisplayOrder = 1 -- under the panels and popups
markerGui.Parent = playerGui

local markers = {} -- [id] = { holder, arrow, label, text, adornee, height, angle }

local CUT_LEFT = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.5, 1),
	NumberSequenceKeypoint.new(0.501, 0),
	NumberSequenceKeypoint.new(1, 0),
})
local CUT_RIGHT = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(0.501, 1),
	NumberSequenceKeypoint.new(1, 1),
})

-- One half of a downward triangle: a frame cut along its diagonal by a hard UIGradient edge. The left half keeps the part
-- above the diagonal top-left -> bottom-right, the right half the part above the other diagonal.
local function halfHead(parent: Instance, color: Color3, x: number, y: number, width: number, height: number, left: boolean)
	local half = Instance.new("Frame")
	half.BorderSizePixel = 0
	half.BackgroundColor3 = color
	half.Position = UDim2.fromOffset(x, y)
	half.Size = UDim2.fromOffset(width, height)
	local cut = Instance.new("UIGradient")
	cut.Rotation = math.deg(math.atan2(height, width)) * (if left then -1 else 1)
	cut.Transparency = if left then CUT_LEFT else CUT_RIGHT
	cut.Parent = half
	half.Parent = parent
end

-- A down arrow (shaft + head) in the box at (x, y) of the given size.
local function arrowShape(parent: Instance, color: Color3, x: number, y: number, width: number, height: number, head: number, shaft: number)
	local body = Instance.new("Frame")
	body.BorderSizePixel = 0
	body.BackgroundColor3 = color
	body.Position = UDim2.fromOffset(x + (width - shaft) / 2, y)
	body.Size = UDim2.fromOffset(shaft, height - head + 1)
	body.Parent = parent
	halfHead(parent, color, x, y + height - head, width / 2, head, true)
	halfHead(parent, color, x + width / 2, y + height - head, width / 2, head, false)
end

local function newMarker(): (Frame, Frame, TextLabel)
	local holder = Instance.new("Frame") -- full screen, so its children are placed in viewport pixels
	holder.Name = "HintMarker"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.Visible = false

	local arrow = Instance.new("Frame") -- turned as a whole; Rotation 0 = pointing down
	arrow.Name = "Arrow"
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.BackgroundTransparency = 1
	arrow.Size = UDim2.fromOffset(ARROW_WIDTH, ARROW_HEIGHT)
	arrow.Parent = holder
	arrowShape(arrow, Color3.new(1, 1, 1), 0, 0, ARROW_WIDTH, ARROW_HEIGHT, 29, 28) -- outline
	arrowShape(arrow, ARROW_ORANGE, 6, 4, ARROW_WIDTH - 12, ARROW_HEIGHT - 11, 22, 16)

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.fromOffset(0, 26)
	label.BackgroundTransparency = 1
	label.Font = StudStyle.Font
	label.TextSize = 22
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeColor3 = ARROW_INK
	label.TextStrokeTransparency = 0
	label.Parent = holder

	holder.Parent = markerGui
	return holder, arrow, label
end

function Hints.SetMarker(id: string, adornee: BasePart?, label: (() -> string)?, height: number?)
	local marker = markers[id]
	if not adornee then
		if marker then
			marker.holder:Destroy()
			markers[id] = nil
		end
		return
	end
	if not marker then
		local holder, arrow, labelObject = newMarker()
		marker = { holder = holder, arrow = arrow, label = labelObject, angle = 0 }
		markers[id] = marker
	end
	if marker.adornee ~= adornee then
		marker.holder:SetAttribute("Target", adornee:GetFullName()) -- for tests
	end
	marker.adornee = adornee
	marker.height = height or 6
	marker.text = label
	marker.label.Text = if label then label() else ""
end

-- The marker's holder frame (tests read Visible, Arrow.Rotation, Arrow / Label positions); nil when the marker is not set.
function Hints.Marker(id: string): Frame?
	local marker = markers[id]
	return marker and marker.holder
end

Locale.Changed:Connect(function()
	for _, marker in markers do
		marker.label.Text = if marker.text then marker.text() else ""
	end
end)

-- Shortest turn from `from` to `to` (degrees).
local function turn(from: number, to: number): number
	return (to - from + 180) % 360 - 180
end

local function placeMarkers(dt: number)
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
		marker.holder.Visible = show
		if not show then
			continue
		end
		-- `hover`: where the arrow floats; `aim`: the target at the player's height (a gate's doorway), which the arrow points
		-- at, so a player close to a gate looking up is never sent to the point above its sign
		local hover = marker.adornee.Position + Vector3.new(0, marker.height, 0)
		local aim = Vector3.new(hover.X, root.Position.Y, hover.Z)
		local point = camera:WorldToViewportPoint(hover)
		local aimPoint = camera:WorldToViewportPoint(aim)
		local left, right = EDGE_INSET, view.X - EDGE_INSET
		local top, bottom = EDGE_TOP, view.Y * (1 - EDGE_BOTTOM)
		-- the target at the player's height must lie below the free area's top: a far target seen from a steep top-down
		-- camera projects above the screen, and an arrow pinned under the top pointing down would point at unrelated
		-- ground; it goes to the edge pointing towards the target instead
		local ahead = aimPoint.Z > 0 and aimPoint.X >= left and aimPoint.X <= right and aimPoint.Y >= top
		local labelSize = marker.label.AbsoluteSize
		local angle, arrowAt, labelAt
		if ahead then
			-- above the target pointing down at it, the label above the arrow; kept inside the free area (when only the
			-- hover point is above the screen, a gate close by seen from below, the arrow stays pinned under its top,
			-- still pointing down at the target)
			local x = if point.Z > 0 then math.clamp(point.X, left, right) else aimPoint.X
			local y = if point.Z > 0 then point.Y else top
			y = math.clamp(y, top + ARROW_HEIGHT, math.max(top + ARROW_HEIGHT, bottom))
			angle = 0
			arrowAt = Vector2.new(x, y - ARROW_HEIGHT / 2 + bob)
			labelAt = arrowAt - Vector2.new(0, ARROW_HEIGHT / 2 + labelSize.Y / 2)
		else
			-- on the edge of the free area, from its centre towards the target (camera space, screen y down); a target
			-- behind the camera goes to the side of the shorter turn, at mid-height
			local relative = camera.CFrame:PointToObjectSpace(aim)
			local direction = Vector2.new(relative.X, -relative.Y)
			if relative.Z > 0 then
				direction = Vector2.new(if relative.X < 0 then -1 else 1, 0)
			end
			if direction.Magnitude < 1e-3 then
				direction = Vector2.new(1, 0)
			end
			local unit = direction.Unit
			local centre = Vector2.new((left + right) / 2, (top + bottom) / 2)
			local scale = math.min(
				(right - centre.X) / math.max(math.abs(unit.X), 1e-3),
				(bottom - centre.Y) / math.max(math.abs(unit.Y), 1e-3)
			)
			local spot = centre + unit * scale
			angle = math.deg(math.atan2(unit.Y, unit.X)) - 90
			arrowAt = spot + unit * bob -- nudges towards the target
			-- the label on the inner side of the arrow, clear of it
			local clearance = ARROW_HEIGHT / 2 + math.abs(unit.X) * labelSize.X / 2 + math.abs(unit.Y) * labelSize.Y / 2 + 4
			labelAt = spot - unit * clearance
		end
		marker.angle += turn(marker.angle, angle) * math.min(1, dt * TURN_SPEED)
		marker.arrow.Rotation = marker.angle
		marker.arrow.Position = UDim2.fromOffset(arrowAt.X, arrowAt.Y)
		marker.label.Position = UDim2.fromOffset(labelAt.X, labelAt.Y)
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
