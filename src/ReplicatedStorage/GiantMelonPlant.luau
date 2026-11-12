-- CG19 recipe: the chosen "B, arching vine" giant melon (docs/plants/GIANT_MELON.md): Pumpkin's arch, deeply lobed leaves, one big
-- striped melon lying in front of the arch, two flowers kept well away from the fruit, a dry tendril beside the stem as the ripeness cue.
-- 97 Parts: seed shell 1, cotyledons 2, vine 6, leaves 6 x 6, flowers 2 x 7, tendrils 2 x 3, fruit 24 stripe blocks + ground spot +
-- scar + 3 stem rods, dry tendril 3. Growth art approved by Ales 2026-11-12; registered in PlantGrowth (no Draft flag).
local GiantMelonPlant = {}
GiantMelonPlant.RingHeight = 4.9
GiantMelonPlant.FixedOrientation = true -- the ground spot and the stem face the player's side of the arch
GiantMelonPlant.FixedRingHeight = true
GiantMelonPlant.ReviewHeight = 4.2

local Kit = require(script.Parent.PlantKit)
local phase, V, C = Kit.phase, Vector3.new, Color3.fromRGB

local RIPE_DARK, RIPE_LIGHT = C(26, 86, 46), C(142, 202, 104)
local YOUNG_DARK, YOUNG_LIGHT = C(112, 164, 86), C(172, 212, 128)
local SPOT, SCAR = C(238, 208, 100), C(70, 62, 40)
local STEM, DRY = C(104, 126, 62), C(130, 100, 60)
local VINE, SHOOT = C(86, 140, 72), C(150, 196, 110)
local LEAF = {C(48, 128, 66), C(78, 156, 84)}
local YOUNG_LEAF = C(120, 186, 104)
local YELLOW, CORE = C(250, 204, 58), C(214, 140, 30)
local SEED = C(240, 226, 190)

local L0, ROUND = 3.4, 0.44 -- standard fruit length and its radius / length
local MAX_R = 1.55 -- a heavy melon gets longer, not taller (it stays under the arch)
local POS0 = V(0.30, 0, 0.40)
local MAX_RADIUS = 2.40
local MAX_LEAF = 2.30
-- The last node is the vine tip above the melon's stem end; the stem hangs from it. Nodes 4-6 clear the fruit's top (2.9 at most).
local ARCH = {V(-1.4, 0.1, -1.1), V(-1.55, 1.2, -0.9), V(-1.2, 2.4, -0.6), V(-0.5, 3.3, -0.3), V(0.4, 3.5, -0.2), V(1.1, 3.05, 0.0), V(1.7, 2.95, 0.5)}
-- Start / end of each vine segment.
local SEG = {{0.00, 0.16}, {0.08, 0.26}, {0.16, 0.36}, {0.26, 0.46}, {0.36, 0.56}, {0.44, 0.62}}
-- Arch node, mature hinge, size, yaw, tilt, start, end. No leaf lies on the fruit's side of the arch.
local LEAVES = {
	{3, V(-1.25, 2.95, -0.35), 1.15, 0.3, -0.35, 0.26, 0.50},
	{4, V(-0.7, 3.95, -0.10), 1.20, -0.4, -0.25, 0.34, 0.56},
	{5, V(0.7, 4.0, 0.0), 1.10, 0.6, -0.30, 0.42, 0.62},
	{6, V(1.3, 3.05, 0.10), 1.00, 1.3, -0.30, 0.50, 0.70},
	{2, V(-1.3, 1.0, -1.1), 0.95, 2.8, -0.25, 0.18, 0.42},
	{1, V(-0.1, 0.8, -1.55), 1.00, 3.0, -0.30, 0.12, 0.38},
}
-- Five narrow lobes fanned from the hinge: angle, length, width.
local LOBES = {{0, 1.15, 0.50}, {0.62, 0.95, 0.40}, {-0.62, 0.95, 0.40}, {1.22, 0.68, 0.34}, {-1.22, 0.68, 0.34}}
-- Both flowers sit on the left of the arch, behind and beside the fruit's blossom end, never on or above the melon.
-- Arch node, mature offset, open start / end, wilt start / end.
local FLOWERS = {
	{2, V(0.40, 0.70, -0.05), 0.44, 0.54, 0.78, 0.86},
	{3, V(0.00, 0.60, -0.55), 0.52, 0.62, 0.82, 0.90},
}
-- Arch node, start, end.
local TENDRILS = {{4, 0.38, 0.56}, {6, 0.50, 0.66}}
local CURL = {V(0, 0, 0), V(0.20, 0.30, -0.10), V(0.46, 0.34, -0.22), V(0.52, 0.14, -0.30)}

-- Furthest horizontal reach of a mature leaf (all lobe corners), from the soil centre.
local function leafReach(hinge, tilt, yaw, scale)
	local face = CFrame.new(hinge) * CFrame.Angles(tilt, yaw, 0)
	local reach = 0
	for i, l in LOBES do
		local cf = face * CFrame.Angles(0, l[1], 0) * CFrame.new(0, 0.012 * i, l[2] * scale / 2)
		local h = V(l[3], 0.09, l[2]) * scale / 2
		for _, x in {-1, 1} do for _, z in {-1, 1} do
			local p = cf:PointToWorldSpace(V(h.X * x, 0, h.Z * z))
			reach = math.max(reach, math.sqrt(p.X * p.X + p.Z * p.Z))
		end end
	end
	return reach
end

-- Furthest horizontal reach of the ripe melon's stripe blocks (end blocks included) from the soil centre.
local function fruitReach(pos, yaw, L, R)
	local reach = 0
	for _, seg in {{0, 0.52 * L, R}, {0.37 * L, 0.28 * L, 0.80 * R}, {-0.37 * L, 0.28 * L, 0.80 * R}} do
		for _, x in {-1, 1} do for _, z in {-1, 1} do
			local p = pos + CFrame.Angles(0, yaw, 0):VectorToWorldSpace(V(seg[1] + x * seg[2] / 2, 0, z * seg[3])) -- the rib at 90 degrees reaches the full radius sideways
			reach = math.max(reach, math.sqrt(p.X * p.X + p.Z * p.Z))
		end end
	end
	return reach
end

-- Seeded shape shared by the full plant and the mid proxy; the draw order is part of a planting's identity.
local function seededShape(seed, sizeFactor)
	local dim = Kit.dimension(sizeFactor)
	local self = {dimensionScale = dim}
	local vary = Kit.seeded(seed)
	local arch = {ARCH[1]}
	for i = 2, #ARCH do arch[i] = ARCH[i] + V(vary(0.10), vary(0.12), vary(0.08)) end
	self.leaves = {}
	for i, spec in LEAVES do
		local node = arch[spec[1]]
		local hinge = spec[2] + V(vary(0.06), vary(0.05), vary(0.06))
		local scale = spec[3] * (1 + vary(0.12)) * (1 + 0.15 * (dim - 1))
		local yaw, tilt = spec[4] + vary(0.30), spec[5] + vary(0.10)
		for _ = 1, 14 do
			if leafReach(hinge, tilt, yaw, scale) <= MAX_LEAF then break end
			scale *= 0.94
		end
		self.leaves[i] = {node = spec[1], offset = hinge - node, scale = scale, yaw = yaw, tilt = tilt}
	end
	self.flowers = {}
	for i, spec in FLOWERS do
		self.flowers[i] = {node = spec[1], offset = spec[2] + V(vary(0.10), vary(0.08), vary(0.10))}
	end
	self.yaw = 0.45 + vary(0.35)
	-- A heavy fruit slides toward the middle and gets longer, so fruit and arch stay on the square.
	local shift = math.min(1, 1.1 / dim)
	local pos = V((POS0.X + vary(0.12)) * shift, 0, (POS0.Z + vary(0.10)) * shift)
	self.pos = pos
	local L = L0 * dim
	for _ = 1, 30 do
		if fruitReach(pos, self.yaw, L, math.min(ROUND * L, MAX_R)) <= MAX_RADIUS - 0.04 then break end
		L *= 0.97
	end
	self.L = L
	self.R = math.min(ROUND * L, MAX_R)
	self.crown = pos + V(0, self.R * 0.94, 0)
	self.arch = arch
	return self
end

local function vineState(s, g)
	local pts, q = {s.arch[1]}, {}
	for k = 1, 6 do
		local raw = phase(g, SEG[k][1], SEG[k][2])
		q[k] = if k == 1 then 0.12 + 0.88 * raw else raw
		pts[k + 1] = pts[k]:Lerp(s.arch[k + 1], q[k])
	end
	return pts, q
end

local function rod(emit, name, a, b, width, color, q, role, slot)
	emit(name, V(width, width, (b - a).Magnitude + 0.02), Kit.axis(a, b), color, phase(q, 0, 0.08), role, slot)
end

-- Emits every Part in a fixed order: emit(name, size, cframe-relative-to-soil, color, opacity, role, fruitSlot, variant).
local function geometry(s, g, emit, proxy)
	local pts, vq = vineState(s, g)
	emit("SeedShell", V(0.55, 0.10, 0.34), CFrame.new(s.arch[1] + V(-0.30, 0.05, 0.25)) * CFrame.Angles(0, 0.5, 0.1), SEED, 1 - phase(g, 0.18, 0.30), "Structure")
	local cot = phase(g, 0.03, 0.18) * (1 - phase(g, 0.38, 0.52))
	local cotAt = s.arch[1]:Lerp(pts[2], 0.55)
	for i, side in {-1, 1} do
		emit("Cotyledon_" .. i, V(0.62, 0.05, 0.34) * (0.4 + 0.6 * cot), CFrame.new(cotAt + V(0.26 * side * cot, 0.05, 0)) * CFrame.Angles(0, 0, -0.45 * side), YOUNG_LEAF, cot, "Foliage")
	end
	for k = 1, 6 do
		local brown = if k >= 5 then phase(g, 0.86, 1) else 0
		rod(emit, "Vine_" .. k, pts[k], pts[k + 1], 0.22 * (0.55 + 0.45 * vq[k]), SHOOT:Lerp(VINE, phase(g, 0.05, 0.30)):Lerp(DRY, brown), vq[k], "Structure")
	end
	for i, spec in LEAVES do
		local leaf = s.leaves[i]
		local q = phase(g, spec[6], spec[7])
		local from = pts[leaf.node]
		local at = from + leaf.offset * q
		local face = CFrame.new(at) * CFrame.Angles(leaf.tilt + 1.10 * (1 - q), leaf.yaw, 0)
		local scale = leaf.scale * q
		rod(emit, "Petiole_" .. i, from, at, 0.14 * (0.4 + 0.6 * q), VINE, q, "Structure")
		for j, l in LOBES do
			if not (proxy and j > 3) then
				emit("LeafLobe_" .. i .. "_" .. j, V(l[3] * scale, 0.09, l[2] * scale),
					face * CFrame.Angles(0, l[1], 0) * CFrame.new(0, 0.012 * j, l[2] * scale / 2),
					YOUNG_LEAF:Lerp(LEAF[j % 2 + 1], phase(q, 0.2, 1)), phase(q, 0, 0.08), "Foliage", nil, "Studs")
			end
		end
	end
	for i, spec in FLOWERS do
		if not proxy then
			local flower = s.flowers[i]
			local open = phase(g, spec[3], spec[4])
			local fade = open * (1 - phase(g, spec[5], spec[6]))
			local from = pts[flower.node]
			local at = from + flower.offset * open
			rod(emit, "FlowerStalk_" .. i, from, at, 0.12 * (0.4 + 0.6 * open), STEM, open, "Structure")
			for p = 0, 4 do
				emit("Petal_" .. i .. "_" .. p, V(0.24, 0.05, 0.42) * fade, CFrame.new(at) * CFrame.Angles(0, p * math.pi * 0.4, 0) * CFrame.Angles(-0.35, 0, 0) * CFrame.new(0, 0, 0.20 * fade), YELLOW, fade, "Flower")
			end
			emit("FlowerCore_" .. i, V(0.18, 0.18, 0.18) * fade, CFrame.new(at + V(0, 0.07, 0)), CORE, fade, "Flower")
		end
	end
	for i, spec in TENDRILS do
		if not proxy then
			local q = phase(g, spec[2], spec[3])
			local base = pts[spec[1]]
			local color = VINE:Lerp(DRY, phase(g, 0.86, 1))
			for j = 1, 3 do
				rod(emit, "Tendril_" .. i .. "_" .. j, base + CURL[j] * q, base + CURL[j + 1] * q, 0.06 * (0.4 + 0.6 * q), color, q, "Structure")
			end
		end
	end
	-- Fruit: eight stripe ribs around its axis, each a long middle block and two shorter, narrower end blocks.
	local grow = phase(g, 0.60, 0.98)
	local sc = 0.10 + 0.90 * grow
	local L, R = s.L * sc, s.R * sc
	local vis, ripe, dry = phase(g, 0.60, 0.64), phase(g, 0.74, 1), phase(g, 0.84, 1)
	local centre = s.pos + V(0, 0.94 * R, 0)
	local fr = CFrame.new(centre) * CFrame.Angles(0, s.yaw, 0)
	local segs = {{0, 0.52 * L, R}, {0.37 * L, 0.28 * L, 0.80 * R}, {-0.37 * L, 0.28 * L, 0.80 * R}}
	for i = 0, 7 do
		local rib = fr * CFrame.Angles(i * math.pi / 4, 0, 0)
		local color = (if i % 2 == 0 then YOUNG_DARK else YOUNG_LIGHT):Lerp(if i % 2 == 0 then RIPE_DARK else RIPE_LIGHT, ripe)
		for n, seg in segs do
			if not (proxy and n > 1) then
				emit("Rind", V(seg[2], seg[3] * 0.55, seg[3] * 0.86), rib * CFrame.new(seg[1], seg[3] * 0.725, 0), color, vis, "Fruit", 1)
			end
		end
	end
	-- Ground spot on the lower front flank (creamy when ripe), dark blossom scar.
	emit("GroundSpot", V(0.30 * L, 0.07, 0.50 * R), fr * CFrame.Angles(math.rad(135), 0, 0) * CFrame.new(0.05 * L, R, 0), YOUNG_LIGHT:Lerp(SPOT, ripe), phase(g, 0.66, 0.76), "Fruit", 1)
	if not proxy then
		emit("BlossomScar", V(0.12, 0.30, 0.30) * sc, fr * CFrame.new(-0.515 * L, 0, 0), SCAR, vis, "Fruit", 1)
	end
	-- Stem from the stem end of the melon up to the vine tip, with a dry tendril beside it (the ripeness cue).
	local e = fr:PointToWorldSpace(V(0.5 * L, 0.25 * R, 0))
	local tip = s.arch[7]
	local m1 = e:Lerp(tip, 0.35) + V(0.05, 0.25, 0.05)
	local m2 = e:Lerp(tip, 0.70) + V(0, 0.10, 0)
	local stemColor = STEM:Lerp(DRY, dry)
	rod(emit, "MelonStem_1", e, m1, 0.26, stemColor, vis, "Fruit", 1)
	rod(emit, "MelonStem_2", m1, m2, 0.24, stemColor, vis, "Fruit", 1)
	rod(emit, "MelonStem_3", m2, tip, 0.22, stemColor, vis, "Fruit", 1)
	local curl = {m1, m1 + V(0.22, 0.22, 0.12), m1 + V(0.38, 0.06, 0.28), m1 + V(0.18, -0.10, 0.34)}
	for j = 1, 3 do
		if not proxy then
			rod(emit, "DryTendril_" .. j, curl[j], curl[j + 1], 0.07, VINE:Lerp(DRY, dry), vis, "Structure")
		end
	end
end

Kit.recipe(GiantMelonPlant, {
	name = "GiantMelonPlant",
	parts = 97, -- 1 seed shell + 2 cotyledon + 6 vine + 36 leaf + 14 flower + 6 tendril + 32 fruit (24 stripe blocks, spot, scar, 3 stem rods, 3 dry tendril)
	shape = seededShape,
	geometry = geometry,
	proxyMid = 0.70,
	onNew = function(self, _, soilCFrame)
		self.fruitSlots = {{id = 1, attachment = soilCFrame * CFrame.new(self.crown), parts = {}}}
	end,
})

return GiantMelonPlant
