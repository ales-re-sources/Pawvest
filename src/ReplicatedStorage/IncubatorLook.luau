-- Open hatch pod: the selected stud-brick body, built directly into a plot piece so Base remains discoverable.
-- Build(...) -> setState(state), animate(serverNow, startedAt?). Full / mid / low: 34 / 8 / 3 body Parts.
-- States: free / locked / empty (unlit), scanning (cyan contour ring), growing (warm amber pulse), ready (green).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local EggLook = require(ReplicatedStorage:WaitForChild("EggLook"))
local IncubatorLook = {}

local BROWN = Color3.fromRGB(150, 100, 60)
local PAD = Color3.fromRGB(225, 195, 110)
local CREAM = Color3.fromRGB(236, 228, 208)
local STEEL = Color3.fromRGB(100, 133, 147)
local DARK = Color3.fromRGB(50, 66, 72)
local LOCKED = Color3.fromRGB(80, 80, 80)
local WARM = Color3.fromRGB(255, 183, 63)
local READY = Color3.fromRGB(108, 209, 110)
local SCAN = Color3.fromRGB(81, 216, 240)
local SCAN_LIGHT = Color3.fromRGB(165, 250, 255)
local NEST_TOP = 1.85 -- the egg's base (PlotView places EggLook there)
-- Ring thickness; gap between its inner face and the egg's bricks (the 0.22 head reaches 0.035 nearer); half-height of the
-- head, the tallest ring piece. At the egg's widest course the head's outer face stays 0.03 inside the cheeks (x = 1.85).
local RING_T, RING_CLEAR, RING_HALF = 0.15, 0.07, 0.11
local RING_LOW, RING_HIGH, RING_PERIOD, RING_LAP = 0.15, 3.05, 4, 3 -- ring height range above the nest; seconds per up-down / lap
local TAN8 = math.tan(math.pi / 8)

-- The egg's reach at each course boundary (the larger of the two courses); linear between them it is at least the reach of
-- the course it crosses. A piece spanning h ± RING_HALF meets each course it touches at one of its ends (courses are taller
-- than the piece), so the larger value at the two ends is a smooth bound for every brick it passes.
local ringBounds = {}
for n = 0, EggLook.Courses do
	ringBounds[n] = math.max(EggLook.Reach(math.max(n, 1)), EggLook.Reach(math.min(n + 1, EggLook.Courses)))
end
local function eggReach(h: number): number
	local f = math.clamp(h / EggLook.Course, 0, EggLook.Courses)
	local n = math.min(math.floor(f), EggLook.Courses - 1)
	return ringBounds[n] + (ringBounds[n + 1] - ringBounds[n]) * (f - n)
end
local function ringRadius(h: number): number -- centreline apothem of the ring at height h above the nest
	return math.max(eggReach(h - RING_HALF), eggReach(h + RING_HALF)) + RING_CLEAR + RING_T / 2
end

function IncubatorLook.Build(parent: Model, floorCFrame: CFrame, detail: string, state: string, number: number)
	local muted = state == "locked" or state == "free"
	local trim = if muted then STEEL else CREAM
	local function add(name: string, size: Vector3, at: Vector3, color: Color3, variant: string?, collide: boolean?)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = floorCFrame * CFrame.new(at)
		p.Color = color
		p.Material = Enum.Material.Plastic
		p.MaterialVariant = variant or "StudsSmall"
		p.Anchored = true
		p.CanCollide = collide == true
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = parent
		return p
	end

	add("Base", Vector3.new(6, 1.2, 6), Vector3.new(0, 0.85, 0), if state == "locked" then LOCKED else BROWN, "Studs", true)
	if detail ~= "low" then
		add("Nest", Vector3.new(4.4, 0.4, 4.4), Vector3.new(0, 1.65, 0), PAD, nil, true)
	end
	for side, x in { Left = -2.2, Right = 2.2 } do
		if detail == "full" then
			for tier = 1, 4 do
				add(side .. "Cheek" .. tier, Vector3.new(0.7, 0.55, 4.3 - tier * 0.6),
					Vector3.new(x, 1.7 + tier * 0.55, 0.3 + tier * 0.18), if tier % 2 == 0 then trim else STEEL)
			end
		else
			-- Keep the same top edge, embedding the bottom in the base instead of sharing the nest's bottom face.
			add(side .. "Side", Vector3.new(0.7, 2.7, 3), Vector3.new(x, 2.7, 0.75), trim)
		end
	end
	if detail ~= "low" then
		add("RearHeaterCase", Vector3.new(3.5, 1.5, 0.5), Vector3.new(0, 4.45, 2.2), trim)
		-- Embed the plate's foot in the heater case; front and back remain readable from either approach.
		local plate = add("NumberPlate", Vector3.new(1.4, 1.15, 0.3), Vector3.new(0, 5.7, 2.2), DARK)
		for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
			local gui = Instance.new("SurfaceGui")
			gui.Name = "Number" .. face.Name
			gui.Face = face
			gui.AutoLocalize = false
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = 60
			gui.LightInfluence = 0.2
			gui.MaxDistance = 100
			local label = Instance.new("TextLabel")
			label.Name = "Number"
			label.AutoLocalize = false
			label.BackgroundTransparency = 1
			label.Position = UDim2.fromScale(0.1, 0.06)
			label.Size = UDim2.fromScale(0.8, 0.88)
			label.Font = StudStyle.Font
			label.TextScaled = true
			label.TextColor3 = CREAM
			Locale.SetText(label, Locale.Number(number))
			label.Parent = gui
			gui.Parent = plate
		end
		-- Its inner face must stand clear of the cheek's inner face (x = 1.85), or the two stud textures flicker.
		add("ControlPod", Vector3.new(0.68, 1.9, 1.3), Vector3.new(2.25, 2.45, -1.45), trim)
	end
	local heater, temperature, podStatus, status
	if detail == "full" then
		heater = add("RearHeater", Vector3.new(2.7, 0.25, 0.16), Vector3.new(0, 4.65, 1.87), DARK, "")
		podStatus = add("PodStatus", Vector3.new(0.35, 0.18, 0.08), Vector3.new(2.25, 2.9, -2.15), DARK, "")
		-- Stand the console on the front lip; a panel inside the solid plinth would be hidden.
		add("Thermostat", Vector3.new(1.6, 0.65, 0.12), Vector3.new(-0.2, 1.775, -2.72), DARK)
		temperature = add("Temperature", Vector3.new(0.75, 0.18, 0.04), Vector3.new(-0.4, 1.855, -2.81), DARK, "")
		status = add("Status", Vector3.new(0.18, 0.18, 0.04), Vector3.new(0.3, 1.855, -2.81), DARK, "")
	end
	local bands = {}
	local function glowPart(name: string, size: Vector3, at: Vector3, color: Color3, ball: boolean?)
		local p = add(name, size, at, color, "")
		p.Material = Enum.Material.Neon
		p.Transparency = 1
		if ball then p.Shape = Enum.PartType.Ball end
		return p
	end
	local ring, ringHead, ringTrail = {}, {}, {}
	if detail == "full" then
		for _, segment in {
			{ "Front", Vector3.new(3.4, 0.06, 0.06), Vector3.new(0, 1.95, -1.48) },
			{ "Back", Vector3.new(3.4, 0.06, 0.06), Vector3.new(0, 1.95, 1.48) },
			{ "Left", Vector3.new(0.06, 0.06, 2.9), Vector3.new(-1.67, 1.95, 0) },
			{ "Right", Vector3.new(0.06, 0.06, 2.9), Vector3.new(1.67, 1.95, 0) },
		} do
			table.insert(bands, glowPart("PhaseBand" .. segment[1], segment[2], segment[3], SCAN))
		end
		-- Contour ring: eight segments that touch only along their inner edges (no overlapping coplanar faces), a bright head
		-- clipped at the corners and two fading trail points.
		for k = 1, 8 do
			table.insert(ring, glowPart("ScanRing" .. k, Vector3.one * RING_T, Vector3.new(0, 3, 0), SCAN))
		end
		for n = 1, 2 do
			table.insert(ringHead, glowPart("ScanRingHead" .. n, Vector3.one * 0.22, Vector3.new(0, 3, 0), SCAN_LIGHT))
		end
		for n, size in { 0.2, 0.15 } do
			table.insert(ringTrail, glowPart("ScanRingTrail" .. n, Vector3.one * size, Vector3.new(0, 3, 0), SCAN_LIGHT, true))
		end
	elseif detail == "mid" then
		table.insert(bands, glowPart("PhaseStrip", Vector3.new(3.4, 0.08, 0.1), Vector3.new(0, 1.95, -1.48), SCAN))
	end
	local glow = nil
	if detail == "full" then
		glow = Instance.new("PointLight")
		glow.Name = "NestGlow"
		glow.Range = 6
		glow.Shadows = false
		glow.Enabled = false
		glow.Parent = parent:FindFirstChild("Nest")
	end
	local function poseRing(age: number)
		if #ring == 0 then return end
		local h = RING_LOW + (RING_HIGH - RING_LOW) * (1 - math.cos(age * 2 * math.pi / RING_PERIOD)) / 2
		local r = ringRadius(h)
		local level = floorCFrame * CFrame.new(0, NEST_TOP + h, 0)
		local edge = 2 * r * TAN8 -- centreline edge length; each edge's frame has local X along it, travelled towards -X
		local frames = {}
		for k, p in ring do
			frames[k] = level * CFrame.Angles(0, (k - 1) * math.pi / 4, 0) * CFrame.new(0, 0, -r)
			p.Size = Vector3.new(2 * (r - RING_T / 2) * TAN8, RING_T, RING_T)
			p.CFrame = frames[k]
		end
		local function along(s: number): CFrame -- a point s studs along the centreline from edge 1's start
			local k = math.min(math.floor(s / edge), 7)
			return frames[k + 1] * CFrame.new(edge / 2 - (s - k * edge), 0, 0)
		end
		local perimeter = 8 * edge
		local length = math.min(0.6, edge) -- never spans more than two edges
		local head = (age % RING_LAP) / RING_LAP * perimeter
		local used = 0
		for k = 0, 7 do
			local from = k * edge
			local lo, hi = math.max(from, head - length), math.min(from + edge, head)
			if hi <= lo then -- wrap the tail across the last / first edge
				lo, hi = math.max(from, head + perimeter - length), math.min(from + edge, head + perimeter)
			end
			if hi > lo + 0.001 and used < 2 then
				used += 1
				local p = ringHead[used]
				p.Size = Vector3.new(hi - lo, 0.22, 0.22)
				p.CFrame = frames[k + 1] * CFrame.new(edge / 2 - ((lo + hi) / 2 - from), 0, 0)
				p.Transparency = 0.04
			end
		end
		for n = used + 1, 2 do ringHead[n].Transparency = 1 end
		for n, p in ringTrail do
			p.CFrame = along((head - length - 0.2 * n) % perimeter)
			p.Transparency = if n == 1 then 0.3 else 0.6
		end
	end
	local current = nil
	local function lamp(p: BasePart?, color: Color3, on: boolean)
		if p then
			p.Color = if on then color else DARK
			p.Material = if on then Enum.Material.Neon else Enum.Material.Plastic
		end
	end
	local function setState(nextState: string)
		if nextState == current then return end
		current = nextState
		local growing, ready, scanning = nextState == "growing", nextState == "ready", nextState == "scanning"
		local color = if ready then READY elseif scanning then SCAN else WARM
		lamp(heater, WARM, growing)
		lamp(temperature, color, growing or ready or scanning)
		lamp(podStatus, color, growing or ready or scanning)
		lamp(status, color, growing or ready or scanning)
		for _, band in bands do
			band.Color = color
			-- Full detail scans with the ring; mid keeps its static strip.
			band.Transparency = if scanning and detail ~= "full" then 0.25 elseif growing then 0.55 else 1
		end
		for _, p in ring do p.Transparency = if scanning then 0.15 else 1 end
		if scanning then
			poseRing(0)
		else
			for _, p in ringHead do p.Transparency = 1 end
			for _, p in ringTrail do p.Transparency = 1 end
		end
		if glow then
			glow.Enabled = growing or scanning
			glow.Color = color
			glow.Brightness = if scanning then 0.4 else 0.6
		end
	end
	local function animate(now: number, startedAt: number?)
		if detail ~= "full" then return end
		local age = now - (startedAt or 0)
		if current == "scanning" then
			poseRing(age) -- eased up-down ping-pong, starting at the bottom
		elseif current == "growing" then
			local pulse = math.sin(age * math.pi / 2)
			for _, band in bands do band.Transparency = 0.55 - 0.15 * pulse end
			if glow then glow.Brightness = 0.6 + 0.15 * pulse end
		end
	end
	setState(state)
	return setState, animate
end

return IncubatorLook
