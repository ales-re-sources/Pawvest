-- TR2: the fruit-tree art (docs/plants/APPLE_TREE.md), the approved A round crown. One builder, one palette per tree crop
-- (ApplePlant, GoldenApplePlant). A tree has two growths: its structure (sapling -> mature crown; a pick never resets it) and
-- its fruit slots (CropConfig tree.Cap): `fruit` ripe apples on slots 1..fruit and the next one growing on slot fruit + 1.
-- SetTree(structure, fruit, nextGrowth) poses both; SetGrowth(g) is the reviewer's whole life: the structure matures by
-- STRUCTURE_END, then the slots fill one by one up to the cap at 1.
-- Parts: 8 wood (trunk, 3 root flares, 3 limbs, leader) + 14 leaf clumps + 4 per fruit slot (stalk, apple, facet, leaf).
local PlantKit = require(script.Parent.PlantKit)
local CropConfig = require(script.Parent.CropConfig)
local phase, axis = PlantKit.phase, PlantKit.axis
local V = Vector3.new

local FruitTree = {}

local LIMIT = 2.35 -- ground radius every Part corner keeps (the field's 2.4 less a margin)
local STRUCTURE_END = 0.6
local CROWN_BASE = 3.1 -- where the trunk ends and the crown starts (crown tendencies scale above it)

local function pt(t: number, r: number, y: number): Vector3
	return V(math.sin(t) * r, y, math.cos(t) * r)
end

-- Largest ground radius of a box's corners (soil space).
local function reach(cf: CFrame, size: Vector3): number
	local r = 0
	for x = -1, 1, 2 do
		for y = -1, 1, 2 do
			for z = -1, 1, 2 do
				local a = cf:PointToWorldSpace(size * V(x, y, z) / 2)
				r = math.max(r, V(a.X, 0, a.Z).Magnitude)
			end
		end
	end
	return r
end

-- Seed 1's mature crown: { center, size, yaw, tip, first, last } (first..last = when it opens in structure growth; the core
-- clump is there from the sapling).
local CLUMPS = { { V(0, 5.3, 0), V(2.1, 1.8, 2.1), 0.3, 0, 0, 0.4 } }
for k = 0, 5 do
	table.insert(CLUMPS, { pt(k * math.pi / 3, 1.35, 4.7), V(1.5, 1.2, 1.5), k * 0.7, 0.15, 0.12 + k * 0.04, 0.45 + k * 0.04 })
end
for k = 0, 4 do
	table.insert(CLUMPS, { pt(0.6 + k * 2 * math.pi / 5, 1.1, 5.8), V(1.4, 1.1, 1.4), k * 0.9 + 0.3, -0.12, 0.32 + k * 0.04,
		0.68 + k * 0.04 })
end
table.insert(CLUMPS, { V(0.25, 6.6, 0.1), V(1.3, 1.0, 1.3), 0.5, 0.1, 0.5, 0.85 })
table.insert(CLUMPS, { V(-0.3, 6.5, -0.2), V(1.2, 0.9, 1.2), 1.1, -0.1, 0.55, 0.9 })
local LIMB_YAWS = { 0.4, 2.5, 4.6 }
-- Where the apples of slots 1..6 hang (apple centres of seed 1), under the crown's lower ring.
local SPOTS = { pt(0.25, 1.75, 3.45), pt(1.75, 1.7, 3.55), pt(-0.95, 1.75, 3.5), pt(3.6, 1.7, 3.5), pt(-1.9, 1.8, 4.0),
	pt(2.5, 1.8, 4.05) }
local STALK = 0.28
-- Crown tendencies (height, width) a planting cycles through.
local CROWNS = { { 1, 1 }, { 1.08, 0.94 }, { 0.94, 1.05 } }

-- A planting's mature layout. Keep the draws in this order (PLANT_GROWTH: a new draw goes last).
local function shape(seed: number?, sizeFactor: number?, palette, cap: number)
	local vary = PlantKit.seeded(seed)
	local crown = PlantKit.tendency(CROWNS, seed)
	local lean = V(vary(0.18), 0, vary(0.18))
	local yaw = vary(0.5)
	local rot = CFrame.Angles(0, yaw, 0)
	local function crownPoint(p: Vector3): Vector3
		local r = rot * V(p.X * crown[2], 0, p.Z * crown[2])
		local y = if p.Y > CROWN_BASE then CROWN_BASE + (p.Y - CROWN_BASE) * crown[1] else p.Y
		return V(r.X, y, r.Z) + lean * (y / 5.3)
	end
	local s = { palette = palette, cap = cap, d = palette.d * PlantKit.dimension(sizeFactor), clumps = {}, limbs = {}, nodes = {} }
	s.top = crownPoint(V(0.04, CROWN_BASE, 0))
	s.limbBase = V(0.04, 2.9, 0) + lean * (2.9 / 5.3)
	s.leaderBase = V(0.04, 3.0, 0) + lean * (3.0 / 5.3)
	s.leaderTop = crownPoint(V(0, 5.0, 0))
	for i, c in CLUMPS do
		s.clumps[i] = { center = crownPoint(c[1]) + V(vary(0.12), vary(0.15), vary(0.12)), size = c[2] * (1 + vary(0.1)),
			yaw = c[3] + yaw, tip = c[4], first = c[5], last = c[6] }
	end
	for i, t in LIMB_YAWS do
		local tt = t + vary(0.25)
		s.limbs[i] = { flare = t + 0.2, tip = crownPoint(pt(tt, 1.0, 4.4)) }
	end
	for i, p in SPOTS do
		local at = CFrame.Angles(0, vary(0.15), 0) * crownPoint(p)
		local flat = V(at.X, 0, at.Z)
		local most = LIMIT - s.d * 0.72
		if flat.Magnitude > most then
			at = V(0, at.Y, 0) + flat.Unit * most
		end
		s.nodes[i] = at + V(0, palette.d * 0.45 + STALK, 0) -- the stalk's top: fixed, whatever the apple's size
	end
	return s
end

-- Emits every Part in a fixed order: emit(name, size, cf (soil space), color, opacity, role, slot?, variant?).
-- proxy = true leaves out the root flares, stalks and fruit leaves.
local function geometry(s, structure: number, fruit: number, nextGrowth: number, emit, proxy: boolean)
	local pal = s.palette
	local u = 0.35 + 0.65 * phase(structure, 0, 0.9) -- the whole tree grows from about a third of its size
	local function rod(name: string, a: Vector3, b: Vector3, width: number, color: Color3, opacity: number, role: string?, slot: number?)
		emit(name, V(width, width, (b - a).Magnitude + 0.025), axis(a, b), color, opacity, role or "Structure", slot)
	end
	local top = s.top * u
	rod("Trunk", V(0, 0, 0), top, 0.5 * math.max(u, 0.45), pal.bark, 1)
	if not proxy then
		local q = phase(structure, 0.3, 0.6)
		for _, limb in s.limbs do
			rod("Root", pt(limb.flare, 0.12, 0.28) * u, pt(limb.flare, 0.55, 0) * u, 0.22 * u, pal.bark, phase(q, 0, 0.08))
		end
	end
	for i, limb in s.limbs do
		local q = phase(structure, 0.15 + i * 0.05, 0.55 + i * 0.05)
		local a = s.limbBase * u
		rod("Limb", a, a:Lerp(limb.tip * u, math.max(q, 0.05)), 0.26 * u, pal.limb, phase(q, 0, 0.08))
	end
	local lq = phase(structure, 0.05, 0.5)
	rod("Leader", s.leaderBase * u, (s.leaderBase * u):Lerp(s.leaderTop * u, math.max(lq, 0.05)), 0.28 * u, pal.limb, phase(lq, 0, 0.08))
	local core = s.clumps[1].center * u
	for i, c in s.clumps do
		local q = if i == 1 then 0.35 + 0.65 * phase(structure, 0, 0.4) else phase(structure, c.first, c.last)
		-- the sapling's tuft (the core clump) starts at more than the tree's scale, so a young tree reads at field distance
		local size = c.size * (if i == 1 then math.max(u, 0.55) else u) * (0.35 + 0.65 * q)
		local cf = CFrame.new(core:Lerp(c.center * u, 0.45 + 0.55 * q)) * CFrame.Angles(0, c.yaw, 0)
			* CFrame.Angles(c.tip, 0, c.tip * 0.6)
		local over = reach(cf, size) - LIMIT
		if over > 0 then
			local flat = V(cf.X, 0, cf.Z)
			if flat.Magnitude > 0.01 then
				cf -= flat.Unit * math.min(over + 0.01, flat.Magnitude)
			end
		end
		emit("Leaves", size, cf, pal.leaves[i % 3 + 1], if i == 1 then 1 else phase(q, 0, 0.08), "Foliage")
	end
	for i = 1, s.cap do
		local q = if i <= fruit then 1 elseif i == fruit + 1 then nextGrowth else 0
		local opacity = if q > 0 then 1 else 0
		local ripe = phase(q, 0.45, 1)
		local d = s.d * (0.3 + 0.7 * q)
		local node = s.nodes[i] * u
		local cf = CFrame.new(node - V(0, STALK + d * 0.45, 0)) * CFrame.Angles(0, i * 0.5, 0)
		if not proxy then
			rod("FruitStalk", node - V(0, STALK, 0), node, 0.07, pal.stalk, opacity, "Fruit", i)
		end
		emit("Fruit", V(d, d * 0.9, d), cf, pal.unripe:Lerp(pal.fruit, ripe), opacity, "Fruit", i)
		emit("FruitFacet", V(d * 0.86, d * 0.8, d * 0.86), cf * CFrame.Angles(0, math.pi / 4, 0), pal.unripeFacet:Lerp(pal.facet, ripe),
			opacity, "Fruit", i)
		if not proxy then
			emit("FruitLeaf", V(0.22, 0.05, 0.36), cf * CFrame.new(0.1, d * 0.5 + 0.1, 0.12) * CFrame.Angles(0.5, 0.6, 0), pal.fruitLeaf,
				opacity, "Fruit", i, "Studs")
		end
	end
end

-- The recipe module of tree crop `cropId` drawn with `palette`: { bark, limb, stalk, fruitLeaf, leaves = { 3 }, fruit, facet,
-- unripe, unripeFacet, d (apple size at the standard mass) }.
function FruitTree.make(cropId: string, palette)
	local crop = assert(CropConfig.ById[cropId], "Unknown tree " .. cropId)
	local cap = assert(crop.tree, "Not a tree: " .. cropId).Cap
	assert(cap <= #SPOTS, "More fruit than slots: " .. cropId)
	local parts = 8 + #CLUMPS + 4 * cap

	local Plant = {}
	Plant.__index = Plant
	Plant.RingHeight = 8.0
	Plant.FixedRingHeight = true
	Plant.ReviewHeight = 7.4
	Plant.Tree = true

	function Plant.new(parent: Instance, soilCFrame: CFrame, seed: number, sizeFactor: number?)
		local self = setmetatable(shape(seed, sizeFactor, palette, cap), Plant)
		local rig = PlantKit.newRig(cropId .. "Tree", soilCFrame)
		self.rig, self.model, self.fruitSlots = rig, rig.model, {}
		for i = 1, cap do
			self.fruitSlots[i] = { id = i, attachment = soilCFrame * CFrame.new(self.nodes[i]), parts = {} }
		end
		geometry(self, 1, cap, 0, function(name, _, _, _, _, role, slot, variant)
			local part = rig:add(name, variant, role, slot)
			if slot then
				table.insert(self.fruitSlots[slot].parts, part)
			end
		end, false)
		assert(#rig.parts == parts, cropId .. " tree topology changed")
		self:SetTree(0, 0, 0)
		self.model.Parent = parent
		return self
	end

	-- structure 0..1 (sapling -> mature), fruit = ripe apples (0..cap), nextGrowth 0..1 = the apple growing on slot fruit + 1.
	function Plant:SetTree(structure: number, fruit: number, nextGrowth: number?)
		local rig = self.rig
		assert(not rig.destroyed, "Plant has been destroyed")
		local s = math.clamp(structure, 0, 1)
		local count = math.clamp(math.floor(fruit), 0, cap)
		local grow = if count >= cap then 0 else math.clamp(nextGrowth or 0, 0, 1)
		local pose = self.pose
		if pose and pose[1] == s and pose[2] == count and pose[3] == grow then
			return
		end
		self.pose = { s, count, grow }
		rig.cursor = 0
		geometry(self, s, count, grow, function(_, size, cf, color, opacity)
			rig:block(size, cf, color, opacity)
		end, false)
		rig:finish()
	end

	-- The reviewer's whole life of a tree (0 = sapling, STRUCTURE_END = mature and bare, 1 = every slot ripe).
	function Plant:SetGrowth(normalized: number)
		local g = math.clamp(normalized, 0, 1)
		local t = math.max(0, g - STRUCTURE_END) / (1 - STRUCTURE_END) * cap
		local count = math.min(cap, math.floor(t))
		self:SetTree(math.min(1, g / STRUCTURE_END), count, t - count)
	end

	function Plant:Destroy()
		self.rig:destroy()
	end

	-- Mid detail: stage 1 a young tree, 2 mature and bare, 3 with `fruit` apples (all slots when not given).
	function Plant.BuildProxy(parent: Instance, soilCFrame: CFrame, stage: number, seed: number?, sizeFactor: number?, fruit: number?)
		local s = shape(seed, sizeFactor, palette, cap)
		local count = if stage >= 3 then math.clamp(fruit or cap, 1, cap) else 0
		geometry(s, if stage <= 1 then 0.35 else 1, count, 0, function(name, size, cf, color, opacity, role, slot, variant)
			if opacity <= 0.01 then
				return
			end
			local part = PlantKit.proxyPart(parent, name, size, soilCFrame * cf, color, variant, role, slot)
			part.Transparency = 1 - opacity
		end, true)
	end

	return Plant
end

return FruitTree
