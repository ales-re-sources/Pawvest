-- CG11b: brown onion, a half-buried globe bulb, tall slim quills and a flower scape with an umbel at harvest (docs/plants/ONION.md).
-- 19 bulb + 1 seed coat + 24 quill (8 x 3 rods) + 2 scape + 2 bud + 1 core + 10 floret Parts = 59, built once.
local OnionPlant = {}
OnionPlant.RingHeight = 5.0
OnionPlant.FixedRingHeight = true -- height barely follows mass, so the ring does not scale with it
OnionPlant.ReviewHeight = 4.6

local Kit = require(script.Parent.PlantKit)
local phase, V, C = Kit.phase, Vector3.new, Color3.fromRGB

local N, FLORETS = 8, 10
local FRACS, WIDTHS = {0.14, 0.56, 0.30}, {0.15, 0.13, 0.085}
local SKIN_YOUNG, SKIN = C(232, 226, 190), C(150, 92, 48)
local SHOULDER_YOUNG, SHOULDER = C(238, 230, 196), C(178, 118, 62)
local NECK_YOUNG, NECK = C(226, 226, 182), C(204, 172, 112)
local SEAM = C(120, 74, 38)
local SHEATH, BODY, BODY_B, TIP = C(214, 226, 170), C(76, 140, 72), C(96, 156, 76), C(130, 172, 70)
local DRY, DRY_TIP = C(172, 168, 76), C(214, 192, 112)
local SEED = C(36, 32, 38)
local STALK, BUD, BUD_TIP, CORE = C(112, 168, 84), C(150, 190, 112), C(238, 232, 244), C(168, 196, 128)
local FLOWER_WHITE, FLOWER_LILAC = C(240, 234, 246), C(214, 186, 230)
-- Bulb slabs: bottom and top as fractions of the bulb height, width fraction, tone (0 skin, 1 shoulder, 2 taper).
-- Eight slabs give a round profile; with half the bulb buried, fewer read as a stepped pagoda. The widest slab sits at the soil.
local LAYERS = {
	{0, 0.14, 0.45, 0}, {0.14, 0.28, 0.75, 0}, {0.28, 0.42, 0.94, 0}, {0.42, 0.55, 1.0, 0},
	{0.55, 0.67, 0.96, 1}, {0.67, 0.78, 0.86, 1}, {0.78, 0.88, 0.70, 1}, {0.88, 1.0, 0.46, 2},
}
-- yaw, lean, length, emergence start, droop weight. Seed 1 is the authored reference; leaves emerge from the centre, so later quills are taller.
local QUILLS = {
	{0.30, 0.20, 1.75, 0.00, 0.5}, {2.70, 0.12, 1.90, 0.05, 0.2}, {5.10, 0.26, 2.00, 0.09, 0.2}, {1.22, 0.16, 2.10, 0.14, 0.5},
	{3.62, 0.22, 2.20, 0.19, 0.2}, {6.02, 0.10, 2.30, 0.25, 0.2}, {1.84, 0.24, 2.40, 0.31, 0.5}, {4.25, 0.14, 2.45, 0.38, 0.2},
}
-- Unit directions of the umbel's florets (a 10-point spread over the sphere).
local FLORET_DIRS = {}
for k = 1, FLORETS do
	local y = 1 - (k - 0.5) / FLORETS * 2
	local r = math.sqrt(1 - y * y)
	local a = k * 2.399963
	FLORET_DIRS[k] = V(math.cos(a) * r, y, math.sin(a) * r)
end

local function seededShape(seed, sizeFactor)
	local vary, ds = Kit.seeded(seed), Kit.dimension(sizeFactor)
	local vigor = math.clamp(1 + (ds - 1) * 0.30, 0.90, 1.10)
	local shape = {dimension = ds, quills = {}, horizontal = 1, neckHeight = 0.18 * ds}
	shape.bulbWidth = 1.7 * ds * (1 + vary(0.06))
	shape.bulbDepth = 0.65 * ds * (1 + vary(0.12))
	for i, q in QUILLS do
		shape.quills[i] = {
			yaw = q[1] + vary(0.14), lean = q[2] + vary(0.06), len = q[3] * vigor * (1 + vary(0.10)),
			start = q[4] + vary(0.02), droop = math.clamp(q[5] + vary(0.15), 0.1, 0.6),
		}
	end
	-- Appended after the structural draws so the scape cannot reroll the leaves.
	shape.scapeLength = 2.5 * vigor * (1 + vary(0.08))
	shape.scapeLean = 0.04 + vary(0.05)
	shape.scapeYaw = 1.1 + vary(0.7)
	shape.floretTurn = vary(0.5)
	return shape
end

local function bulbState(shape, g)
	local grow = phase(g, 0.12, 0.85)
	local ds = shape.dimension
	local s = {W = shape.bulbWidth * (0.22 + 0.78 * grow), top = (0.10 + 0.85 * grow) * ds, b0 = -(0.05 * ds + shape.bulbDepth * grow),
		color = phase(g, 0.40, 0.85)}
	s.H = s.top - s.b0
	s.neck = shape.neckHeight * (0.5 + 0.5 * grow)
	s.baseY = s.top + s.neck - 0.05
	return s
end

local function bulbGeometry(s, emit, proxy)
	local skin, shoulder = SKIN_YOUNG:Lerp(SKIN, s.color), SHOULDER_YOUNG:Lerp(SHOULDER, s.color)
	local taper = shoulder:Lerp(NECK_YOUNG:Lerp(NECK, s.color), 0.5)
	for i, l in LAYERS do
		for k = 0, 1 do
			if proxy and (k == 1 or i <= 3) then continue end
			local w = l[3] * s.W * (if k == 1 then 0.86 else 1)
			local h = (l[2] - l[1]) * s.H * (if k == 1 then 0.98 else 1)
			emit("Bulb_" .. i .. "_" .. k, V(w, h, w), CFrame.new(0, s.b0 + (l[1] + l[2]) / 2 * s.H, 0) * CFrame.Angles(0, k * math.pi / 4, 0),
				if l[4] == 0 then skin elseif l[4] == 1 then shoulder else taper, 1, "Bulb")
		end
	end
	if not proxy then
		local seam = phase(s.color, 0.3, 0.7)
		emit("Seam_1", V(s.W * 1.03, 0.04 * s.H + 0.01, s.W * 0.2), CFrame.new(0, s.b0 + 0.47 * s.H, 0), SEAM, seam, "Bulb")
		emit("Seam_2", V(s.W * 0.2, 0.04 * s.H + 0.01, s.W * 0.95), CFrame.new(0, s.b0 + 0.67 * s.H, 0), SEAM, seam, "Bulb")
	end
	emit("Neck", V(0.26 * s.W, s.neck, 0.26 * s.W), CFrame.new(0, s.top + s.neck / 2 - 0.03, 0),
		NECK_YOUNG:Lerp(NECK, s.color), 1, "Bulb")
end

-- Points of quill i at growth g: base, three joints; per-segment length and the crook/droop state.
local function quillState(shape, s, g, i)
	local f = shape.quills[i]
	local q = if i == 1 then 0.30 + 0.70 * phase(g, 0, 0.30) else phase(g, f.start, f.start + 0.30)
	local crook = if i == 1 then 1 - phase(g, 0.06, 0.30) else 0
	local droop = f.droop * phase(g, 0.80 + 0.015 * i, 0.96 + 0.005 * i)
	local shorten = 1 - 0.08 * droop
	local l1 = f.lean * 0.6 * (1 - crook) + 0.15 * crook
	local l2 = (f.lean * 1.1 + 0.25 * droop) * (1 - crook) + 1.40 * crook
	local l3 = (f.lean * 1.5 + (0.95 - f.lean * 1.5) * droop) * (1 - crook) + 2.5 * crook
	local out = V(math.sin(f.yaw), 0, math.cos(f.yaw)) * shape.horizontal
	local pos = V(out.X * 0.06, s.baseY, out.Z * 0.06)
	local pts, lens, reach = {pos}, {}, f.len * q
	local cum = 0
	for j, lean in {l1, l2, l3} do
		local seg = math.clamp(reach - cum, 0, f.len * FRACS[j]) * shorten
		cum += f.len * FRACS[j]
		local dir = out * math.sin(lean) + V(0, math.cos(lean), 0)
		pos += dir * seg
		pts[j + 1], lens[j] = pos, seg
	end
	return {pts = pts, lens = lens, q = q, droop = droop, yellow = phase(g, 0.78, 1), weight = f.droop}
end

-- The flower scape rises through the fan from 45%, carries a closed bud, and opens into a globe of florets at harvest.
local function scapeGeometry(shape, s, g, emit, proxy)
	local rise = phase(g, 0.45, 0.80)
	local grow = shape.scapeLength * rise
	local out = V(math.sin(shape.scapeYaw), 0, math.cos(shape.scapeYaw))
	local a = V(0, s.baseY - 0.10, 0)
	local mid = a + (V(0, 1, 0) + out * shape.scapeLean * 0.5).Unit * (grow * 0.5)
	local top = mid + (V(0, 1, 0) + out * shape.scapeLean).Unit * (grow * 0.5)
	emit("Scape_1", V(0.11, 0.11, (mid - a).Magnitude + 0.03), Kit.axis(a, mid), STALK, if rise > 0.005 then 1 else 0, "Flower")
	emit("Scape_2", V(0.085, 0.085, (top - mid).Magnitude + 0.03), Kit.axis(mid, top), STALK, if rise > 0.005 then 1 else 0, "Flower")
	local bud = phase(g, 0.58, 0.80) * (1 - phase(g, 0.84, 0.95))
	if proxy then
		emit("Bud_1", V(0.01, 0.01, 0.01), CFrame.new(top), BUD, 0, "Flower")
		emit("Bud_2", V(0.01, 0.01, 0.01), CFrame.new(top), BUD, 0, "Flower")
	else
		emit("Bud_1", V(0.20 * bud + 0.001, 0.34 * bud + 0.001, 0.20 * bud + 0.001), CFrame.new(top + V(0, 0.15 * bud, 0)), BUD, if bud > 0.02 then 1 else 0, "Flower")
		emit("Bud_2", V(0.11 * bud + 0.001, 0.24 * bud + 0.001, 0.11 * bud + 0.001), CFrame.new(top + V(0, 0.40 * bud, 0)), BUD_TIP, if bud > 0.02 then 1 else 0, "Flower")
	end
	local open = phase(g, 0.84, 1)
	local center = top + V(0, 0.28 * open, 0)
	emit("UmbelCore", V(0.40 * open + 0.001, 0.40 * open + 0.001, 0.40 * open + 0.001), CFrame.new(center), CORE, if open > 0.02 then 1 else 0, "Flower")
	for k = 1, FLORETS do
		local size = (0.14 + 0.24 * open) * math.clamp(shape.dimension, 0.85, 1.15)
		if proxy and k % 2 == 0 then
			emit("Floret_" .. k, V(0.01, 0.01, 0.01), CFrame.new(center), FLOWER_WHITE, 0, "Flower")
		else
			emit("Floret_" .. k, V(size, size, size), CFrame.new(center + FLORET_DIRS[k] * (0.34 * open)) * CFrame.Angles(k * 0.7 + shape.floretTurn, k * 1.1, k * 0.5),
				if k % 2 == 0 then FLOWER_LILAC else FLOWER_WHITE, if open > 0.02 then 1 else 0, "Flower")
		end
	end
end

local function geometry(shape, g, emit, proxy)
	local s = bulbState(shape, g)
	bulbGeometry(s, emit, proxy)
	local quills = {}
	for i = 1, N do quills[i] = quillState(shape, s, g, i) end
	-- The germination seed coat rides the tip of the first shoot until it straightens.
	local first = quills[1].pts
	local tip = first[4]
	local dir = (first[4] - first[3])
	dir = if dir.Magnitude > 0.0001 then dir.Unit else V(0, -1, 0)
	emit("SeedCoat", V(0.20, 0.14, 0.36), Kit.axis(tip, tip + dir * 0.36), SEED, 1 - phase(g, 0.10, 0.22), "Seed")
	for i = 1, N do
		local st = quills[i]
		for j = 1, 3 do
			local a, b = st.pts[j], st.pts[j + 1]
			local len = st.lens[j]
			if not (proxy and i % 2 == 0) then
				local body = (if i % 2 == 0 then BODY else BODY_B):Lerp(DRY, st.yellow * 0.5 * (0.5 + 0.5 * st.weight))
				local color = if j == 1 then SHEATH elseif j == 2 then body else TIP:Lerp(DRY_TIP, st.yellow)
				local w = WIDTHS[j] * (0.6 + 0.4 * st.q)
				emit("Quill_" .. i .. "_" .. j, V(w, w, len + 0.03), Kit.axis(a, b), color, if len > 0.004 then 1 else 0, "Foliage")
			else
				emit("Quill_" .. i .. "_" .. j, V(0.01, 0.01, 0.01), CFrame.new(a), BODY, 0, "Foliage")
			end
		end
	end
	scapeGeometry(shape, s, g, emit, proxy)
	return s
end

-- Keep the drooping fan inside the shared 2.4-stud ground radius by narrowing only the quills' sideways reach.
local function fitHorizontal(shape)
	local radius = 0
	for _, g in {0.70, 0.85, 1} do
		geometry(shape, g, function(name, size, cf, _, opacity)
			if opacity <= 0 or not name:match("^Quill") then return end
			for _, x in {-1, 1} do for _, y in {-1, 1} do for _, z in {-1, 1} do
				local p = cf:PointToWorldSpace(size / 2 * V(x, y, z))
				radius = math.max(radius, V(p.X, 0, p.Z).Magnitude)
			end end end
		end)
	end
	shape.horizontal = math.min(1, 2.30 / math.max(0.001, radius))
end

local function newShape(seed, sizeFactor)
	local shape = seededShape(seed, sizeFactor)
	fitHorizontal(shape)
	return shape
end

-- Direct mid proxy: the bulb's upper slabs, neck, every other quill, the scape and half the florets. Hidden geometry is never constructed.
Kit.recipe(OnionPlant, {
	name = "OnionPlant",
	parts = 59,
	shape = newShape,
	geometry = geometry,
	proxyMid = 0.60,
})

return OnionPlant
