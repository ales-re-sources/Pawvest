-- Arch hatch pod: the selected stud-brick body, built directly into a plot piece so Base remains discoverable.
-- Build(...) -> setState(state), animate(serverNow, startedAt?). Full / mid / low: 59 / 13 / 8 body Parts.
-- States: free / locked / empty (unlit), scanning (cyan contour ring), growing (amber pulse, heat lamp / embers, rising sparks and brick hearts), ready (green).
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
local SKIRT = Color3.fromRGB(96, 63, 38)
local NEST_TOP = 1.85 -- the egg's base (PlotView places EggLook there)
-- Arch body (C, 2026-11-17): side walls step up to a headboard; z from, z to, top (studs above the plot floor).
local SIDE_STEPS = {
	full = { { -1.7, -0.7, 2.45 }, { -0.7, 0.3, 3.3 }, { 0.3, 2.35, 4.25 } },
	mid = { { -1.7, 0.3, 2.9 }, { 0.3, 2.35, 4.25 } },
	low = { { -1.7, 2.35, 4.25 } },
}
-- Arch: centre height, centreline radius, thickness, half angle from vertical (its ends meet the 4.25 wall tops at
-- x = ±2.2, its crown is 5.6 high), depth range (the back half: the hearts rise in front of it), segments at full detail.
local ARCH_YC, ARCH_R, ARCH_T, ARCH_HALF = 3.132, 2.468, 0.25, math.rad(63)
local ARCH_Z0, ARCH_Z1, ARCH_SEGMENTS = 0.5, 2.35, 7
-- Ring thickness; gap between its inner face and the egg's bricks (the 0.22 head reaches 0.035 nearer); half-height of the
-- head, the tallest ring piece. At the egg's widest course the head's outer face stays 0.03 inside the walls (x = 1.85).
local RING_T, RING_CLEAR, RING_HALF = 0.15, 0.07, 0.11
local RING_LOW, RING_HIGH, RING_PERIOD, RING_LAP = 0.15, 3.05, 4, 3 -- ring height range above the nest; seconds per up-down / lap
local TAN8 = math.tan(math.pi / 8)
local EMBER = Color3.fromRGB(255, 118, 40) -- the heater strip flickers between WARM and this while growing
local HEART = Color3.fromRGB(255, 85, 125)
local EGG_TOP = NEST_TOP + EggLook.Height
-- Hearts: stud size; rise above the egg top; seconds each; two in flight half a life apart.
local HEART_STUD, HEART_RISE, HEART_LIFE = 0.11, 1.6, 4
local HEART_PIECES = { -- 5 × 4 studs "XX XX / XXXXX / XXX / X": offsets / sizes in studs, rows touch but never overlap
	{ Vector3.new(-1.5, 1.5, 0), Vector3.new(2, 1, 1) },
	{ Vector3.new(1.5, 1.5, 0), Vector3.new(2, 1, 1) },
	{ Vector3.new(0, 0.5, 0), Vector3.new(5, 1, 1) },
	{ Vector3.new(0, -0.5, 0), Vector3.new(3, 1, 1) },
	{ Vector3.new(0, -1.5, 0), Vector3.one },
}
local function hash(a: number, b: number): number -- stable 0..1 for a heart's cycle
	return (math.sin(a * 12.9898 + b * 78.233) * 43758.5453) % 1
end

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
	local function add(name: string, size: Vector3, at: Vector3 | CFrame, color: Color3, variant: string?, collide: boolean?)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = floorCFrame * (if typeof(at) == "CFrame" then at else CFrame.new(at))
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

	-- Every body part rests on, or sinks into, the one below it: no part may hang in the air (the old pod's rear heater
	-- and side tiers floated). Ranges are plot-local studs; front is -Z.
	local function box(name: string, x0: number, x1: number, y0: number, y1: number, z0: number, z1: number,
		color: Color3, variant: string?, collide: boolean?)
		return add(name, Vector3.new(x1 - x0, y1 - y0, z1 - z0), Vector3.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2),
			color, variant, collide)
	end
	local full = detail == "full"
	box("Base", -3, 3, if full then 0.75 else 0.25, 1.45, -3, 3, if state == "locked" then LOCKED else BROWN, "Studs", true)
	if full then
		box("Skirt", -2.7, 2.7, 0.25, 0.85, -2.7, 2.7, SKIRT, "Studs") -- set in under the base: the pod stands on a foot
	end
	-- The nest fits between the side walls (the egg's widest course stays inside x = 1.85); the low egg rests on it too.
	box("Nest", -1.9, 1.9, 1.45, 1.85, -2.2, 2.2, PAD, nil, true)
	for _, s in { -1, 1 } do
		local side = if s < 0 then "Left" else "Right"
		local inner, outer = 1.85 * s, 2.55 * s
		for k, seg in SIDE_STEPS[detail] do
			local z0, z1, top = seg[1], seg[2], seg[3]
			if full then
				box(side .. "Side" .. k, math.min(inner, outer), math.max(inner, outer), 1.35, top - 0.35, z0, z1, STEEL)
				-- The cap overhangs only outwards: its inner face stays flush with the wall, clear of the scan ring.
				box(side .. "Cap" .. k, math.min(inner, 2.6 * s), math.max(inner, 2.6 * s), top - 0.35, top, z0, z1, trim)
			else
				box(side .. "Side" .. k, math.min(inner, outer), math.max(inner, outer), 1.35, top, z0, z1, STEEL)
			end
		end
	end
	box("Headboard", -2.65, 2.65, 1.35, 4.75, 2.3, 2.85, STEEL)
	if full then
		local roll = add("HeadboardRoll", Vector3.new(5.5, 0.7, 0.7), Vector3.new(0, 4.75, 2.575), trim)
		roll.Shape = Enum.PartType.Cylinder
		-- A band round the back and sides, so the field side is not one blank wall.
		box("HeadboardBand", -2.7, 2.7, 2.6, 2.95, 2.25, 2.9, trim)
	end
	-- The arch bridges the side walls over the egg's back half, its ends sunk into their 4.25 tops at x = ±2.2.
	local segments = if full then ARCH_SEGMENTS else 3
	local step = 2 * ARCH_HALF / segments
	for k = 1, segments do
		local phi = -ARCH_HALF + (k - 0.5) * step -- from vertical, positive towards +X
		add("Arch" .. k, Vector3.new(2 * ARCH_R * math.sin(step / 2) + 0.06, ARCH_T, ARCH_Z1 - ARCH_Z0),
			CFrame.new(ARCH_R * math.sin(phi), ARCH_YC + ARCH_R * math.cos(phi), (ARCH_Z0 + ARCH_Z1) / 2) * CFrame.Angles(0, 0, -phi),
			if k % 2 == 1 then trim else STEEL)
	end
	if detail ~= "low" then
		-- The plate's foot sinks into the arch's crown; front and back remain readable from either approach.
		local plate = box("NumberPlate", -0.7, 0.7, 5.55, 6.7, 1.275, 1.575, DARK)
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
		-- The control module stands on the base ledge outside the right wall, its inner face sunk 0.05 into the wall.
		if full then
			box("ControlPod", 2.5, 2.95, 1.3, 2.9, -1.9, -0.6, STEEL)
			box("ControlPodCap", 2.48, 2.97, 2.9, 3.2, -1.92, -0.58, trim)
		else
			box("ControlPod", 2.5, 2.95, 1.3, 3.2, -1.9, -0.6, STEEL)
		end
	end
	local heater, temperature, podStatus, status
	if detail == "full" then
		heater = box("RearHeater", -1.35, 1.35, 3.85, 4.1, 2.14, 2.32, DARK, "") -- on the headboard, facing the egg
		podStatus = box("PodStatus", 2.555, 2.895, 2.45, 2.63, -1.96, -1.88, DARK, "")
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
	local hearts = {} -- [heart] = { { part, at } }
	local sparks: ParticleEmitter?, lamp: SpotLight? = nil, nil
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
		-- Warming: brick hearts float up from the egg; sparks rise from its top; the heater lights it like a lamp.
		for h = 1, 2 do
			local pieces = {}
			for n, piece in HEART_PIECES do
				table.insert(pieces, { part = glowPart(string.format("WarmHeart%d_%d", h, n), piece[2] * HEART_STUD, Vector3.new(0, 3, 0), HEART),
					at = piece[1] * HEART_STUD })
			end
			table.insert(hearts, pieces)
		end
		local nest = parent:FindFirstChild("Nest") :: BasePart
		local top = Instance.new("Attachment")
		top.Name = "WarmSparks"
		top.Position = Vector3.new(0, EGG_TOP + 0.05 - 1.65, 0) -- in the nest's space (its centre is 1.65 above the floor)
		top.Parent = nest
		sparks = Instance.new("ParticleEmitter")
		sparks.Name = "WarmSparks"
		sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparks.Color = ColorSequence.new(Color3.fromRGB(255, 205, 120), Color3.fromRGB(255, 150, 90))
		sparks.LightEmission, sparks.LightInfluence = 0.8, 0
		sparks.Rate, sparks.Lifetime = 3, NumberRange.new(2, 3)
		sparks.Speed, sparks.SpreadAngle = NumberRange.new(0.35, 0.65), Vector2.new(35, 35)
		sparks.Acceleration, sparks.Drag = Vector3.new(0, 0.15, 0), 0.4
		sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.25, 0.4), NumberSequenceKeypoint.new(1, 0) })
		sparks.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.1), NumberSequenceKeypoint.new(1, 1) })
		sparks.Rotation, sparks.RotSpeed = NumberRange.new(0, 90), NumberRange.new(-15, 15)
		sparks.Enabled = false
		sparks.Parent = top
		lamp = Instance.new("SpotLight")
		lamp.Name = "HeatLamp"
		lamp.Face = Enum.NormalId.Front -- the strip's front faces the egg
		lamp.Angle, lamp.Range, lamp.Brightness = 80, 7, 1.5
		lamp.Color = WARM
		lamp.Shadows = false
		lamp.Enabled = false
		lamp.Parent = heater
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
	local function poseHearts(age: number)
		for h, pieces in hearts do
			local t = age / HEART_LIFE + (h - 1) / 2
			local cycle = math.floor(t)
			local f = t - cycle
			local x = (hash(cycle, h) - 0.5) * 1.0 + 0.12 * math.sin(f * 2 * math.pi + h)
			local z = -0.3 + (hash(cycle, h + 7) - 0.5) * 0.6 -- the front half, clear of the number plate behind
			local frame = floorCFrame * CFrame.new(x, EGG_TOP + 0.25 + HEART_RISE * f, z)
				* CFrame.Angles(0, 0, 0.15 * math.sin(f * 3 * math.pi))
			-- fade in over the first 15 %, out over the last 40 %
			local fade = if f < 0.15 then 1 - f / 0.15 * 0.85 elseif f > 0.6 then 0.15 + (f - 0.6) / 0.4 * 0.85 else 0.15
			for _, piece in pieces do
				piece.part.CFrame = frame * CFrame.new(piece.at)
				piece.part.Transparency = fade
			end
		end
	end
	local current = nil
	local function light(p: BasePart?, color: Color3, on: boolean)
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
		light(heater, WARM, growing)
		light(temperature, color, growing or ready or scanning)
		light(podStatus, color, growing or ready or scanning)
		light(status, color, growing or ready or scanning)
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
		if sparks then sparks.Enabled = growing end
		if lamp then lamp.Enabled = growing end
		if not growing then
			for _, pieces in hearts do
				for _, piece in pieces do piece.part.Transparency = 1 end
			end
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
			if heater then
				-- Embers: slow noise per pod (the number desyncs neighbours), lamp brightness follows.
				local ember = math.clamp(0.5 + 0.6 * math.noise(age * 0.7, number * 3.1), 0, 1)
				heater.Color = WARM:Lerp(EMBER, ember)
				if lamp then lamp.Brightness = 1.6 - 0.5 * ember end
			end
			poseHearts(age)
		end
	end
	setState(state)
	return setState, animate
end

return IncubatorLook
