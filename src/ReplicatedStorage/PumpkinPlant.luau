-- CG15 recipe: the approved arching pumpkin vine (docs/plants/PUMPKIN.md) with a 2.6-stud ribbed fruit.
-- 96 Parts: seed shell 1, cotyledons 2, vine 7, leaves 6 x 6, flowers 2 x 7, tendrils 3 x 3, fruit 24 ribs + 3 stem rods.
local PumpkinPlant = {}
PumpkinPlant.__index = PumpkinPlant
PumpkinPlant.RingHeight = 4.9
PumpkinPlant.FixedOrientation = true
PumpkinPlant.FixedRingHeight = true
PumpkinPlant.ReviewHeight = 4.2

local Kit = require(script.Parent.PlantKit)
local phase, axis = Kit.phase, Kit.axis
local V, C = Vector3.new, Color3.fromRGB
local SKIN = {C(240, 134, 38), C(214, 104, 28)}
local GREEN = {C(104, 156, 72), C(78, 128, 60)}
local STEM, DRY = C(104, 126, 62), C(122, 94, 58)
local VINE, SHOOT = C(86, 140, 72), C(150, 196, 110)
local LEAF = {C(48, 118, 62), C(76, 148, 78)}
local YOUNG_LEAF = C(120, 186, 104)
local YELLOW, CORE = C(250, 204, 58), C(214, 140, 30)
local SEED = C(240, 226, 190)

local D0, TALL = 2.6, 0.66 -- standard fruit width (30% over the first study's 2.0) and its height / width
local POS0 = V(0.45, 0, 0.55)
local MAX_RADIUS = 2.40
local ARCH = {V(-1.4, 0.1, -1.1), V(-1.55, 1.2, -0.9), V(-1.2, 2.4, -0.6), V(-0.5, 3.2, -0.3), V(0.4, 3.4, -0.2), V(1.1, 2.9, 0.0), V(1.15, 2.5, 0.3)}
-- Start / end of each vine segment; the last one ends where the fruit stem hangs.
local SEG = {{0.00, 0.16}, {0.07, 0.24}, {0.14, 0.32}, {0.22, 0.40}, {0.30, 0.48}, {0.38, 0.56}, {0.46, 0.62}}
-- Arch node, mature hinge, size, yaw, tilt, start, end.
local LEAVES = {
	{3, V(-1.25, 2.95, -0.35), 1.10, 0.3, -0.35, 0.26, 0.50},
	{4, V(-0.7, 3.95, -0.10), 1.15, -0.4, -0.25, 0.34, 0.56},
	{5, V(0.7, 4.0, 0.0), 1.05, 0.6, -0.30, 0.42, 0.62},
	{6, V(1.3, 3.05, 0.10), 1.00, 1.3, -0.30, 0.50, 0.70},
	{2, V(-1.15, 0.95, 0.2), 0.95, 2.4, -0.25, 0.18, 0.42},
	{1, V(-0.3, 0.8, -1.2), 1.00, 3.0, -0.30, 0.12, 0.38},
}
local PLATES = {
	{V(0, 0, 0.42), V(0.90, 0.09, 0.92), 0},
	{V(-0.46, 0.012, 0.06), V(0.62, 0.09, 0.78), -0.55},
	{V(0.46, 0.024, 0.06), V(0.62, 0.09, 0.78), 0.55},
	{V(-0.34, 0.036, -0.30), V(0.50, 0.09, 0.50), -0.95},
	{V(0.34, 0.048, -0.30), V(0.50, 0.09, 0.50), 0.95},
}
-- Arch node, mature offset, open start / end, wilt start / end.
local FLOWERS = {
	{6, V(-0.20, -0.15, 0.55), 0.56, 0.66, 0.82, 0.90},
	{2, V(0.20, 0.45, 0.50), 0.48, 0.58, 0.78, 0.86},
}
-- Arch node, start, end.
local TENDRILS = {{4, 0.38, 0.56}, {6, 0.50, 0.66}, {2, 0.30, 0.46}}
local CURL = {V(0, 0, 0), V(0.20, 0.30, -0.10), V(0.46, 0.34, -0.22), V(0.52, 0.14, -0.30)}

-- Seeded shape shared by the full plant and the mid proxy; the draw order is part of a planting's identity.
local function seededShape(seed, sizeFactor)
	local self = {dimensionScale = Kit.dimension(sizeFactor)}
	local vary = Kit.seeded(seed)
	local arch = {ARCH[1]}
	for i = 2, #ARCH do arch[i] = ARCH[i] + V(vary(0.10), vary(0.12), vary(0.08)) end
	self.leaves = {}
	for i, spec in LEAVES do
		local node = arch[spec[1]]
		local hinge = spec[2] + V(vary(0.06), vary(0.05), vary(0.06))
		local scale = spec[3] * (1 + vary(0.12)) * (1 + 0.15 * (self.dimensionScale - 1))
		-- The centre plate's far corner reaches 0.99 x scale from the hinge, at any fold.
		local radius = V(hinge.X, 0, hinge.Z).Magnitude
		scale = math.min(scale, (MAX_RADIUS - radius) / 1.0)
		self.leaves[i] = {node = spec[1], offset = hinge - node, scale = scale, yaw = spec[4] + vary(0.30), tilt = spec[5] + vary(0.10)}
	end
	self.flowers = {}
	for i, spec in FLOWERS do
		self.flowers[i] = {node = spec[1], offset = spec[2] + V(vary(0.10), vary(0.08), vary(0.10))}
	end
	self.yaw = 0.5 + vary(0.6)
	local dim = self.dimensionScale
	-- A heavy fruit slides toward the middle so the fruit and its vine stay on the square.
	local shift = math.min(1, 1.1 / dim)
	local pos = V((POS0.X + vary(0.15)) * shift, 0, (POS0.Z + vary(0.12)) * shift)
	self.pos = pos
	self.D = math.min(D0 * dim, (MAX_RADIUS - 0.10 - pos.Magnitude) / 0.51)
	local crown = pos + V(0, self.D * TALL * 0.68, 0)
	self.crown = crown
	arch[#arch + 1] = crown + V(0.45, 0.80, 0.06)
	self.arch = arch
	return self
end

local function vineState(shape, g)
	local pts, q = {shape.arch[1]}, {}
	for k = 1, 7 do
		local raw = phase(g, SEG[k][1], SEG[k][2])
		q[k] = if k == 1 then 0.12 + 0.88 * raw else raw
		pts[k + 1] = pts[k]:Lerp(shape.arch[k + 1], q[k])
	end
	return pts, q
end

local function fruitState(shape, g)
	local grow = phase(g, 0.62, 0.98)
	local s = 0.10 + 0.90 * grow
	local D = shape.D * s
	return {s = s, D = D, H = D * TALL, vis = phase(g, 0.62, 0.66), ripe = phase(g, 0.74, 1), dry = phase(g, 0.84, 1)}
end

local function ribs(emit, shape, f)
	for i = 0, 7 do
		local frame = CFrame.new(shape.pos) * CFrame.Angles(0, shape.yaw + i * math.pi / 4, 0)
		local color = GREEN[i % 2 + 1]:Lerp(SKIN[i % 2 + 1], f.ripe)
		local D, H = f.D, f.H
		emit("Rib", V(D * 0.64, H * 0.60, D * 0.40), frame * CFrame.new(D * 0.15, H * 0.50, 0), color)
		emit("RibShoulder", V(D * 0.46, H * 0.22, D * 0.34), frame * CFrame.new(D * 0.07, H * 0.89, 0), color)
		emit("RibFoot", V(D * 0.48, H * 0.18, D * 0.33), frame * CFrame.new(D * 0.10, H * 0.09, 0), color)
	end
end

local function stemPoints(shape, pts, f)
	local top = shape.pos + V(0, f.H * 0.68, 0)
	local A = shape.arch[8]
	return {A, top:Lerp(A, 0.7) + V(0.10, 0, 0.04), top:Lerp(A, 0.35) + V(0.14, 0, 0.02), top}
end

local function leafPose(shape, leaf, pts, spec, g)
	local q = phase(g, spec[6], spec[7])
	local node = pts[leaf.node]
	local at = node + leaf.offset * q
	local face = CFrame.new(at) * CFrame.Angles(leaf.tilt + 1.10 * (1 - q), leaf.yaw, 0)
	return q, node, at, face, leaf.scale * q
end

function PumpkinPlant.new(parent, soilCFrame, seed, sizeFactor)
	local self = setmetatable(seededShape(seed, sizeFactor), PumpkinPlant)
	local rig = Kit.newRig("PumpkinPlant", soilCFrame)
	self.rig, self.model = rig, rig.model
	local slot = {id = 1, attachment = soilCFrame * CFrame.new(self.crown), parts = {}}
	self.fruitSlots = {slot}
	rig:add("SeedShell", nil, "Structure")
	for _ = 1, 2 do rig:add("Cotyledon", nil, "Foliage") end
	for _ = 1, 7 do rig:add("Vine", nil, "Structure") end
	for _ = 1, 6 do
		rig:add("Petiole", nil, "Structure")
		for _ = 1, 5 do rig:add("LeafPlate", "Studs", "Foliage") end
	end
	for _ = 1, 2 do
		rig:add("FlowerStalk", nil, "Structure")
		for _ = 1, 5 do rig:add("Petal", nil, "Flower") end
		rig:add("FlowerCore", nil, "Flower")
	end
	for _ = 1, 9 do rig:add("Tendril", nil, "Structure") end
	for _ = 1, 24 do table.insert(slot.parts, rig:add("Rib", nil, "Fruit", 1)) end
	for _ = 1, 3 do table.insert(slot.parts, rig:add("PumpkinStem", nil, "Fruit", 1)) end
	assert(#rig.parts == 96, "Pumpkin topology changed")
	-- Rib parts were added in a fixed order of rib / shoulder / foot per rib; name them for the debugger.
	for i = 1, 24 do slot.parts[i].Name = ({"Rib", "RibShoulder", "RibFoot"})[(i - 1) % 3 + 1] end
	self:SetGrowth(0)
	self.model.Parent = parent
	return self
end

function PumpkinPlant:SetGrowth(normalized)
	local rig = self.rig
	local g = rig:beginPose(normalized)
	if not g then return end
	local pts, vq = vineState(self, g)
	local f = fruitState(self, g)
	-- Seed shell and the two seed leaves at the first node.
	rig:block(V(0.55, 0.10, 0.34), CFrame.new(self.arch[1] + V(-0.30, 0.05, 0.25)) * CFrame.Angles(0, 0.5, 0.1), SEED, 1 - phase(g, 0.18, 0.30))
	local cot = phase(g, 0.03, 0.18) * (1 - phase(g, 0.38, 0.52))
	local node = self.arch[1]:Lerp(pts[2], 0.55)
	for side = -1, 1, 2 do
		rig:block(V(0.62, 0.05, 0.34) * (0.4 + 0.6 * cot), CFrame.new(node + V(0.26 * side * cot, 0.05, 0)) * CFrame.Angles(0, 0, -0.45 * side), YOUNG_LEAF, cot)
	end
	for k = 1, 7 do
		local brown = if k >= 6 then phase(g, 0.86, 1) else 0
		local color = SHOOT:Lerp(VINE, phase(g, 0.05, 0.30)):Lerp(DRY, brown)
		rig:rod(pts[k], pts[k + 1], 0.22 * (0.55 + 0.45 * vq[k]), color, vq[k])
	end
	for i, spec in LEAVES do
		local leaf = self.leaves[i]
		local q, from, at, face, scale = leafPose(self, leaf, pts, spec, g)
		rig:rod(from, at, 0.14 * (0.4 + 0.6 * q), VINE, q)
		for j, p in PLATES do
			rig:block(p[2] * scale, face * CFrame.new(p[1] * scale) * CFrame.Angles(0, p[3], 0), YOUNG_LEAF:Lerp(LEAF[j % 2 + 1], phase(q, 0.2, 1)), phase(q, 0, 0.08))
		end
	end
	for i, spec in FLOWERS do
		local flower = self.flowers[i]
		local open = phase(g, spec[3], spec[4])
		local fade = open * (1 - phase(g, spec[5], spec[6]))
		local from = pts[flower.node]
		local at = from + flower.offset * open
		rig:rod(from, at, 0.12 * (0.4 + 0.6 * open), STEM, open)
		for p = 0, 4 do
			rig:block(V(0.34, 0.06, 0.62) * fade, CFrame.new(at) * CFrame.Angles(0, p * math.pi * 0.4, 0) * CFrame.Angles(-0.35, 0, 0) * CFrame.new(0, 0, 0.30 * fade), YELLOW, fade)
		end
		rig:block(V(0.22, 0.22, 0.22) * fade, CFrame.new(at + V(0, 0.08, 0)), CORE, fade)
	end
	for _, spec in TENDRILS do
		local q = phase(g, spec[2], spec[3])
		local base = pts[spec[1]]
		local color = VINE:Lerp(DRY, phase(g, 0.86, 1))
		for i = 1, 3 do
			rig:rod(base + CURL[i] * q, base + CURL[i + 1] * q, 0.06 * (0.4 + 0.6 * q), color, q)
		end
	end
	ribs(function(_, size, cf, color)
		rig:block(size, cf, color, f.vis)
	end, self, f)
	local sp = stemPoints(self, pts, f)
	local stemColor = STEM:Lerp(DRY, f.dry)
	for i = 1, 3 do
		rig:rod(sp[i], sp[i + 1], 0.26 + 0.05 * (i - 1), stemColor, f.vis)
	end
	rig:finish()
end

function PumpkinPlant:Destroy()
	self.rig:destroy()
end

-- Direct mid proxy: vine, two parts per leaf, flowers as one disc, a two-box fruit with a two-box shoulder and the stem.
function PumpkinPlant.BuildProxy(parent, soilCFrame, stage, seed, sizeFactor)
	local shape = seededShape(seed, sizeFactor)
	local g = Kit.proxyGrowth(stage, 0.70)
	local pts, vq = vineState(shape, g)
	local function rod(name, a, b, width, color, role, slot)
		return Kit.proxyRod(parent, soilCFrame, name, a, b, width, color, role, slot)
	end
	for k = 1, 7 do
		if vq[k] > 0.05 then
			local brown = if k >= 6 then phase(g, 0.86, 1) else 0
			rod("Vine", pts[k], pts[k + 1], 0.22, VINE:Lerp(DRY, brown), "Structure")
		end
	end
	for i, spec in LEAVES do
		local leaf = shape.leaves[i]
		local q, from, at, face, scale = leafPose(shape, leaf, pts, spec, g)
		if q > 0.05 then
			rod("Petiole", from, at, 0.14, VINE, "Structure")
			Kit.proxyPart(parent, "LeafBlade", V(1.5, 0.10, 1.35) * scale, soilCFrame * face * CFrame.new(0, 0, 0.12 * scale),
				LEAF[i % 2 + 1], "Studs", "Foliage")
		end
	end
	for i, spec in FLOWERS do
		local open = phase(g, spec[3], spec[4]) * (1 - phase(g, spec[5], spec[6]))
		if open > 0.05 then
			local at = pts[shape.flowers[i].node] + shape.flowers[i].offset * open
			Kit.proxyPart(parent, "Flower", V(0.9, 0.08, 0.9) * open, soilCFrame * CFrame.new(at) * CFrame.Angles(-0.35, 0, 0), YELLOW, nil, "Flower")
		end
	end
	local f = fruitState(shape, g)
	if f.vis > 0.05 then
		local D, H = f.D, f.H
		local color1, color2 = GREEN[1]:Lerp(SKIN[1], f.ripe), GREEN[2]:Lerp(SKIN[2], f.ripe)
		for k = 0, 1 do
			local frame = soilCFrame * CFrame.new(shape.pos) * CFrame.Angles(0, shape.yaw + k * math.pi / 4, 0)
			Kit.proxyPart(parent, "Belly", V(D * 0.78, H * (0.70 - 0.02 * k), D * 0.78), frame * CFrame.new(0, H * 0.35, 0), if k == 0 then color1 else color2, nil, "Fruit", 1)
			Kit.proxyPart(parent, "Shoulder", V(D * 0.56, H * (0.26 - 0.02 * k), D * 0.56), frame * CFrame.new(0, H * 0.87, 0), if k == 0 then color1 else color2, nil, "Fruit", 1)
		end
		local sp = stemPoints(shape, pts, f)
		rod("PumpkinStem", sp[1], sp[4], 0.30, STEM:Lerp(DRY, f.dry), "Fruit", 1)
	end
end

return PumpkinPlant
