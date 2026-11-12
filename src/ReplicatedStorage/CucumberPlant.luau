-- CG13: trellised cucumber vine (docs/plants/CUCUMBER.md): a rigid wooden ladder trellis, a twining stem, five broad angular
-- leaves, yellow flowers, tendrils and three dark-green ridged cucumbers hanging in front of the leaves.
-- 5 rigid supports + 4 stem + 2 cotyledon + 30 leaf + 24 fruit + 8 male flower + 6 tendril Parts = 79, built once.
local CucumberPlant = {}
CucumberPlant.RingHeight = 5.6
CucumberPlant.FixedOrientation = true -- a trained vine keeps its trellis aligned with the field rows
CucumberPlant.FixedRingHeight = true
CucumberPlant.ReviewHeight = 5.0

local Kit = require(script.Parent.PlantKit)
local phase, V, C = Kit.phase, Vector3.new, Color3.fromRGB

local WOOD = C(176, 132, 78)
local STEM_YOUNG, STEM, TENDRIL = C(150, 200, 110), C(92, 150, 64), C(132, 192, 98)
local LEAF_YOUNG, LEAF_LIGHT, LEAF_DARK = C(146, 206, 108), C(108, 184, 70), C(68, 148, 58)
local COTYLEDON, COTYLEDON_OLD = C(156, 210, 124), C(196, 204, 112)
local FRUIT_YOUNG, FRUIT_RIPE, FRUIT_SHOULDER, FRUIT_STRIPE = C(128, 184, 88), C(24, 76, 42), C(42, 104, 56), C(124, 184, 100)
local FLOWER, FLOWER_DRY = C(252, 214, 62), C(206, 140, 52)

-- Rigid equipment, present from planting and never scaled by mass: name, size, centre (the plane sits just behind the vine).
local function support(name, size, at, proxy)
	return {name = name, size = size, cf = CFrame.new(at), color = WOOD, variant = "Studs", proxy = proxy}
end
-- The proxy shows the posts and two rungs (not the middle one).
local SUPPORTS = {
	support("RigidPost_1", V(0.20, 4.8, 0.20), V(-1.0, 2.4, -0.14)), support("RigidPost_2", V(0.20, 4.8, 0.20), V(1.0, 2.4, -0.14)),
	support("RigidRung_1", V(2.2, 0.12, 0.12), V(0, 1.2, -0.14)), support("RigidRung_2", V(2.2, 0.12, 0.12), V(0, 2.7, -0.14), false),
	support("RigidRung_3", V(2.2, 0.12, 0.12), V(0, 4.2, -0.14)),
}
-- Mature stem points: four segments climbing the trellis. Start and finish growth of each segment.
local PX = {0, -0.14, 0.15, -0.12, 0.08}
local PY = {0.02, 1.0, 2.1, 3.2, 4.4}
local STEM_TIME = {{0, 0.16}, {0.10, 0.34}, {0.26, 0.54}, {0.44, 0.74}}
-- Node height, side (-1 left, +1 right), base elevation of the blade, scale. Leaves alternate; the top one rises out of the tip.
local LEAVES = {
	{0.60, -1, 0.30, 1.15}, {1.75, 1, 0.35, 1.35}, {2.70, -1, 0.35, 1.40}, {3.60, 1, 0.40, 1.35}, {4.40, -1, 0.65, 1.15},
}
-- Node height, side, standard length. Each cucumber hangs just below a leaf node on its own side, in front of the leaves.
local FRUITS = {{3.45, 1, 1.45}, {2.55, -1, 1.55}, {4.25, -1, 1.35}}
local MALES = {{1.2, 1}, {4.05, 1}}
local TENDRILS = {{4.3, 1}, {1.5, -1}}
local CURL = {V(0.30, 0.20, 0.30), V(0.50, 0.48, 0.32), V(0.34, 0.70, 0.30)}
-- Blade pieces: offset from the hinge, size, rotation. Different thicknesses and heights keep overlapping tops off one plane.
local LOBES = {
	{V(0, 0, 0.44), V(0.60, 0.07, 0.86), 0},
	{V(-0.36, 0.012, 0.30), V(0.50, 0.07, 0.62), -0.85}, {V(0.36, 0.024, 0.30), V(0.50, 0.07, 0.62), 0.85},
	{V(-0.30, 0.036, 0.05), V(0.38, 0.07, 0.42), -1.30}, {V(0.30, 0.048, 0.05), V(0.38, 0.07, 0.42), 1.30},
}

local function locate(y)
	for k = 1, 4 do
		if y <= PY[k + 1] + 0.0001 then
			return k, (y - PY[k]) / (PY[k + 1] - PY[k])
		end
	end
	return 4, 1
end

local function nodeTime(k, f)
	return STEM_TIME[k][1] + f * (STEM_TIME[k][2] - STEM_TIME[k][1])
end

-- Blade frame: Z along the blade, Y its normal (turned a little up and toward the viewer).
local function leafFrame(at, d)
	local n0 = V(0, 0.12, 1)
	local n = (n0 - d * d:Dot(n0)).Unit
	return CFrame.fromMatrix(at, n:Cross(d), n, d)
end

local function leafRadius(leaf, scale)
	local at = leaf.node + leaf.stalk
	local frame = leafFrame(at, leaf.d)
	local radius = math.sqrt(at.X * at.X + at.Z * at.Z)
	for _, lobe in LOBES do
		local cf = frame * CFrame.new(lobe[1] * scale) * CFrame.Angles(0, lobe[3], 0)
		local h = lobe[2] * scale / 2
		for _, x in {-1, 1} do for _, y in {-1, 1} do for _, z in {-1, 1} do
			local p = cf:PointToWorldSpace(V(h.X * x, h.Y * y, h.Z * z))
			radius = math.max(radius, math.sqrt(p.X * p.X + p.Z * p.Z))
		end end end
	end
	return radius
end

local function seededShape(seed, sizeFactor)
	local vary, ds = Kit.seeded(seed), Kit.dimension(sizeFactor)
	local vigor = math.clamp(1 + (ds - 1) * 0.25, 0.92, 1.08)
	local mirror = if vary(1) < 0 then -1 else 1 -- seed 1 is the authored layout; other seeds may swap the sides
	local shape = {dimension = ds, mirror = mirror, path = {}, leaves = {}, fruit = {}, males = {}, tendrils = {}}
	for i = 1, 5 do
		local sway, depth = vary(0.16), vary(0.05)
		shape.path[i] = if i == 1 then V(PX[1], PY[1], 0) else V(PX[i] + sway, PY[i], depth)
	end
	local function node(k, f)
		return shape.path[k]:Lerp(shape.path[k + 1], f)
	end
	for i, def in LEAVES do
		local vx, ve, vf, vs, vst = vary(0.10), vary(0.14), vary(0.10), vary(0.12), vary(0.06)
		local side = def[2] * mirror
		local k, f = locate(def[1])
		local leaf = {k = k, f = f, side = side, node = node(k, f), d = V(side * (0.90 + vx), def[3] + ve, 0.12 + vf).Unit,
			stalk = V(side * (0.48 + vst), 0.10, 0.16), scale = def[4] * vigor * (1 + vs), t0 = nodeTime(k, f) + 0.02}
		leaf.t1 = leaf.t0 + 0.15
		for _ = 1, 8 do
			if leafRadius(leaf, leaf.scale) <= 2.30 then break end
			leaf.scale *= 0.94
		end
		shape.leaves[i] = leaf
	end
	shape.fruitSlots = {}
	for i, def in FRUITS do
		local vl, vw, vo, vz, vd = vary(0.12), vary(0.08), vary(0.06), vary(0.05), vary(0.06)
		local side = def[2] * mirror
		local k, f = locate(def[1])
		local at = node(k, f)
		local offset = V(side * 0.34 + vo, -0.10, 0.42)
		local dir = V(side * 0.07 + vd, -1, 0.05 + vz).Unit
		local len = math.min(def[3] * ds * (1 + vl), (at.Y + offset.Y - 0.25) / -dir.Y)
		shape.fruit[i] = {k = k, f = f, side = side, offset = offset, dir = dir, len = len, width = 0.46 * ds * (1 + vw),
			t0 = nodeTime(k, f) + 0.02, turn = vary(0.2), attachment = at + offset}
	end
	for i, def in MALES do
		local k, f = locate(def[1])
		shape.males[i] = {k = k, f = f, side = def[2] * mirror, t0 = math.max(nodeTime(k, f) + 0.02, 0.38), turn = vary(0.2)}
	end
	for i, def in TENDRILS do
		local k, f = locate(def[1])
		shape.tendrils[i] = {k = k, f = f, side = def[2] * mirror, t0 = nodeTime(k, f) + 0.02, size = 1 + vary(0.10)}
	end
	return shape
end

local function rod(emit, name, a, b, width, color, q, role, slot)
	emit(name, V(width, width, (b - a).Magnitude + 0.02), Kit.axis(a, b), color, phase(q, 0, 0.08), role, slot)
end

-- Six-pointed yellow star facing the viewer from three crossed plates.
local function flower(emit, name, center, q, wilt, turn, role, slot, proxy)
	if proxy then
		return
	end
	for k = 1, 3 do
		local s = q * (1 - 0.6 * wilt)
		emit(name .. k, V(0.50 * s, 0.17 * s, 0.05), CFrame.new(center + V(0, 0, k * 0.012)) * CFrame.Angles(0, 0, (k - 1) * math.pi / 3 + turn),
			FLOWER:Lerp(FLOWER_DRY, wilt), phase(q, 0, 0.08), role, slot)
	end
end

-- Emits every non-rigid Part in a fixed order: emit(name, size, cframe-relative-to-soil, color, opacity, role, fruitSlot, variant).
local function geometry(shape, g, emit, proxy)
	local main, mq = {shape.path[1]}, {}
	local stemColor = STEM_YOUNG:Lerp(STEM, phase(g, 0.10, 0.50))
	for i = 1, 4 do
		local q = phase(g, STEM_TIME[i][1], STEM_TIME[i][2])
		if i == 1 then q = 0.30 + 0.70 * q end -- the seedling already has a short stem at planting
		mq[i] = q
		main[i + 1] = main[i]:Lerp(shape.path[i + 1], q)
		rod(emit, "Stem_" .. i, main[i], main[i + 1], 0.15 * (0.55 + 0.45 * q), stemColor, q, "Structure")
	end
	local function nodeAt(k, f)
		return main[k]:Lerp(shape.path[k + 1], f)
	end
	for i, side in {-1, 1} do
		local drop = phase(g, 0.50, 0.72)
		local s = 1 - 0.5 * drop
		emit("Cotyledon_" .. i, V(0.46 * s, 0.05, 0.26 * s), CFrame.new(side * 0.30, 0.12, 0.04) * CFrame.Angles(0, side * 0.20, side * 0.35),
			COTYLEDON:Lerp(COTYLEDON_OLD, phase(g, 0.30, 0.70)), 1 - drop, "Foliage")
	end
	for i, leaf in shape.leaves do
		local q = phase(g, leaf.t0, leaf.t1)
		local at = nodeAt(leaf.k, leaf.f) + leaf.stalk * q
		if not proxy then
			rod(emit, "Leaf_" .. i .. "_Stalk", nodeAt(leaf.k, leaf.f), at, 0.09 * (0.4 + 0.6 * q), stemColor, q, "Structure")
		end
		local d = (V(0, 1, 0) * (1 - q) + leaf.d * q).Unit
		local frame = leafFrame(at, d)
		local scale = leaf.scale * q
		for j, lobe in LOBES do
			if not (proxy and (i % 2 == 0 or j > 3)) then
				local tone = if (i + j) % 2 == 0 then LEAF_LIGHT else LEAF_DARK
				emit("Leaf_" .. i .. "_Lobe_" .. j, lobe[2] * scale, frame * CFrame.new(lobe[1] * scale) * CFrame.Angles(0, lobe[3], 0),
					LEAF_YOUNG:Lerp(tone, q), phase(q, 0, 0.08), "Foliage", nil, "Studs")
			end
		end
	end
	for i, fruit in shape.fruit do
		local top0 = nodeAt(fruit.k, fruit.f)
		local show = phase(g, fruit.t0, fruit.t0 + 0.10)
		local grow = phase(g, fruit.t0 + 0.04, 1)
		local ripe = phase(g, fruit.t0 + 0.14, 0.98)
		local top = top0 + fruit.offset * show
		local len = fruit.len * (0.18 + 0.82 * grow)
		local w = fruit.width * (0.50 + 0.50 * grow)
		local dir = fruit.dir
		if not proxy then
			rod(emit, "Fruit_" .. i .. "_Stalk", top0, top, 0.09 * (0.5 + 0.5 * show), stemColor, show, "Fruit", i)
		end
		local body = FRUIT_YOUNG:Lerp(FRUIT_RIPE, ripe)
		local parts = {
			{"Shoulder", 0, 0.32, 0.80, FRUIT_YOUNG:Lerp(FRUIT_SHOULDER, ripe)},
			{"Body", 0.32, 0.74, 1.0, body},
			{"Lower", 0.74, 1.0, 0.84, body:Lerp(FRUIT_STRIPE, 0.12)},
		}
		for _, p in parts do
			local name = "Fruit_" .. i .. "_" .. p[1]
			if proxy then
				if p[1] == "Body" then
					rod(emit, name, top, top + dir * len, w * 0.95, body, show, "Fruit", i)
				end
			else
				rod(emit, name, top + dir * (len * p[2]), top + dir * (len * p[3]), w * p[4], p[5], show, "Fruit", i)
			end
		end
		if not proxy then
			local lift = V(0, 0, w * 0.5 + 0.004)
			rod(emit, "Fruit_" .. i .. "_Stripe", top + dir * (len * 0.12) + lift, top + dir * (len * 0.80) + lift, 0.06,
				FRUIT_STRIPE, phase(g, fruit.t0 + 0.10, fruit.t0 + 0.25), "Fruit", i)
		end
		-- The female flower sits at the blossom end and dries up as the fruit ripens.
		flower(emit, "Fruit_" .. i .. "_Petal_", top + dir * len + V(0, -0.02, 0.05), show, phase(g, 0.82, 0.99), fruit.turn, "Fruit", i, proxy)
	end
	for i, male in shape.males do
		local q = phase(g, male.t0, male.t0 + 0.10)
		local node = nodeAt(male.k, male.f)
		local center = node + V(male.side * 0.40, 0.06, 0.34) * q
		if not proxy then
			rod(emit, "Male_" .. i .. "_Stalk", node, center, 0.07, stemColor, q, "Structure")
		end
		flower(emit, "Male_" .. i .. "_Petal_", center, q, 0, male.turn, "Flower", nil, proxy)
	end
	for i, tendril in shape.tendrils do
		local q = phase(g, tendril.t0, tendril.t0 + 0.20)
		local start = nodeAt(tendril.k, tendril.f) + V(tendril.side * 0.06, 0, 0.08)
		local points = {start}
		for j, offset in CURL do
			points[j + 1] = start + V(offset.X * tendril.side, offset.Y, offset.Z) * (q * tendril.size)
		end
		if not proxy then
			for j = 1, 3 do
				rod(emit, "Tendril_" .. i .. "_" .. j, points[j], points[j + 1], 0.05, TENDRIL, q, "Structure")
			end
		end
	end
end

Kit.recipe(CucumberPlant, {
	name = "CucumberPlant",
	parts = 79, -- 5 supports + 4 stem + 2 cotyledon + 30 leaf + 24 fruit + 8 male + 6 tendril
	shape = seededShape,
	geometry = geometry,
	proxyMid = 0.60,
	-- Mid proxy: posts and two rungs, the stem, three leaves of three plates and one body piece per ripe fruit.
	supports = SUPPORTS,
	onNew = function(self, _, soilCFrame)
		for i, fruit in self.fruit do
			-- Stable visual slot: mature, seeded stalk origin (docs/PLANT_GROWTH.md, fruit identity).
			self.fruitSlots[i] = {id = i, attachment = soilCFrame * CFrame.new(fruit.attachment), parts = {}}
		end
	end,
})

return CucumberPlant
