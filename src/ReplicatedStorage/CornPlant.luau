-- CG6b/c field recipe: selected B, with a slightly taller jointed stalk.
-- 13 stalk/node + 27 blade + 50 ear + 9 tassel Parts, created once.
local CornPlant = {}
CornPlant.__index = CornPlant
CornPlant.ReviewHeight = 9.5
CornPlant.RingHeight = 10.8
CornPlant.FixedRingHeight = true

local PlantKit = require(script.Parent.PlantKit)
local phase = PlantKit.phase
local V = Vector3.new
local GREEN = Color3.fromRGB(77, 136, 54)
local LIGHT = Color3.fromRGB(107, 159, 60)
local DARK = Color3.fromRGB(51, 111, 47)
local YOUNG = Color3.fromRGB(134, 177, 73)
local HUSK = Color3.fromRGB(124, 160, 66)
local GOLD = Color3.fromRGB(247, 189, 52)
local PALE = Color3.fromRGB(255, 214, 79)
local SILK = Color3.fromRGB(154, 108, 55)
local TASSEL = Color3.fromRGB(188, 163, 79)

-- Corn's approved blocks face the far end of each segment.
local function axis(a, b)
	return PlantKit.axis(b, a)
end

-- Shared seed parameters keep the distance proxy consistent without building
-- the full plant just to discard its Parts.
local function seededShape(soilCFrame, seed, sizeFactor)
	local self = {}
	self.fruitSlots = {}
	local vary = PlantKit.seeded(seed)
	self.dimensionScale = PlantKit.dimension(sizeFactor)
	local vigor = math.clamp(1 + (self.dimensionScale - 1) * 0.20, 0.94, 1.10)
	self.height = 7.80 * (1 + vary(0.075)) * vigor
	self.path = {}
	local lean = V(vary(0.29), 0, vary(0.22))
	for i = 0, 7 do
		local t = i / 7
		self.path[i + 1] = V(0.10 * math.sin(t * 2.5), self.height * t, 0.08 * t * t)
			+ lean * t + V(vary(0.045), vary(0.10), vary(0.045)) * (if i == 0 then 0 else 1)
	end
	self.leaves = {}
	for i = 1, 9 do
		local t = 0.15 + (i - 1) * 0.70 / 8
		local yaw = (if i % 2 == 0 then -math.pi / 2 + 0.16 else math.pi / 2 - 0.22)
			+ (i % 3 - 1) * 0.22 + vary(0.38)
		local width = 0.43 * (1 + vary(0.20)) * vigor
		local reach = 1.55 * (if i == 9 then 0.64 elseif i == 1 then 0.79 else 1) * (1 + vary(0.22)) * vigor
		-- Bound folded and mature blades independently of planting orientation.
		local section = math.min(6, math.floor(t * 7))
		local node = self.path[section + 1]:Lerp(self.path[section + 2], t * 7 - section)
		local rootRadius = V(node.X, 0, node.Z).Magnitude
		reach = math.min(reach, 2.25 - rootRadius - width * 0.55)
		self.leaves[i] = {t = t, yaw = yaw, reach = reach, width = width,
			rise = 0.52 + vary(0.10), droop = 0.78 + vary(0.18), delay = vary(0.018)}
	end
	self.ears = {}
	for i = 1, 2 do
		local t = if i == 1 then 0.54 else 0.37
		local section = math.min(6, math.floor(t * 7))
		local node = self.path[section + 1]:Lerp(self.path[section + 2], t * 7 - section)
		self.ears[i] = {t = t, yaw = (if i == 1 then 0.20 else math.pi + 0.15) + vary(0.28),
			tilt = 0.36 + vary(0.13), scale = 0.85 * (if i == 1 then 1 else 0.84) * self.dimensionScale * (1 + vary(0.14))}
		self.fruitSlots[i] = {id = i, attachment = soilCFrame * CFrame.new(node), parts = {}}
	end
	return self
end

function CornPlant.new(parent, soilCFrame, seed, sizeFactor)
	local self = setmetatable(seededShape(soilCFrame, seed, sizeFactor), CornPlant)
	local rig = PlantKit.newRig("CornPlant", soilCFrame)
	self.rig, self.model = rig, rig.model
	self.leafPoses, self.earPoses = {}, {}
	local function create(name, slot)
		local p = rig:add(name, nil, if slot then "Fruit" else "Structure", slot)
		if slot then table.insert(self.fruitSlots[slot].parts, p) end
	end
	for i = 1, 7 do create("Internode"); if i < 7 then create("Node") end end
	for i = 1, 9 do for j = 1, 3 do create("Leaf" .. i .. "_" .. j) end end
	for slot = 1, 2 do
		create("EarStalk", slot); create("CobCore", slot); create("CobTip", slot)
		for _ = 1, 16 do create("Kernel", slot) end
		for _ = 1, 2 do create("HuskBase", slot); create("HuskTip", slot) end
		for _ = 1, 2 do create("Silk", slot) end
	end
	create("TasselLeader")
	for _ = 1, 4 do create("TasselBranch"); create("TasselTip") end
	assert(#rig.parts == 99, "Corn topology changed")
	self:SetGrowth(0)
	self.model.Parent = parent
	return self
end

function CornPlant:SetGrowth(normalized)
	local rig = self.rig
	local g = rig:beginPose(normalized)
	if not g then return end
	local function rod(a, b, width, color, q)
		rig:rod(b, a, width, color, q)
	end
	local nodes = {self.path[1]}
	for i = 1, 7 do
		local q = phase(g, (i - 1) * 0.075, (i - 1) * 0.075 + 0.23)
		if i == 1 then q = 0.16 + 0.84 * q end
		nodes[i + 1] = nodes[i] + (self.path[i + 1] - self.path[i]) * q
		rod(nodes[i], nodes[i + 1], (0.18 - (i - 1) * 0.012) * (0.55 + 0.45 * q), YOUNG:Lerp(GREEN, q), q)
		if i < 7 then rig:block(V(0.21, 0.08, 0.21) * q, CFrame.new(nodes[i + 1]), LIGHT, phase(q, 0, 0.08)) end
	end
	local function nodeAt(t)
		local section = math.min(6, math.floor(t * 7))
		return nodes[section + 1]:Lerp(nodes[section + 2], t * 7 - section)
	end
	for i, leaf in self.leaves do
		local q = phase(g, 0.03 + (i - 1) * 0.065 + leaf.delay, 0.25 + (i - 1) * 0.065 + leaf.delay)
		if i == 1 then q = 0.10 + 0.90 * q end
		local node = nodeAt(leaf.t)
		local old = self.leafPoses[i]
		if old and old.q == q and old.node == node then rig:skip(3) else
			self.leafPoses[i] = {q = q, node = node}
			local frame = CFrame.new(node) * CFrame.Angles(0, leaf.yaw, 0) * CFrame.Angles(-1.30 * (1 - q), 0, 0)
			local reach, rise, droop = leaf.reach * q, leaf.rise * q, leaf.droop * q * q
			local path = {V(0, 0, 0), V(0, rise, reach * 0.36), V(0, rise * 0.92, reach * 0.72), V(0, rise - droop, reach)}
			local widths = {0.72, 1, 0.43}
			for j = 1, 3 do
				local a, b = path[j], path[j + 1]
				rig:block(V(leaf.width * widths[j] * q, 0.075 * q, (b - a).Magnitude + 0.035 * q),
					frame * axis(a, b), YOUNG:Lerp(if i % 2 == 0 then LIGHT else DARK, q), phase(q, 0, 0.08))
			end
		end
	end
	for i, ear in self.ears do
		local node = nodeAt(ear.t)
		local emergence = phase(g, 0.56 + (i - 1) * 0.035, 0.78 + (i - 1) * 0.025)
		local swell = phase(g, 0.70, 1)
		local ripe = phase(g, 0.80, 1)
		local old = self.earPoses[i]
		if old and old.node == node and old.emergence == emergence and old.swell == swell then rig:skip(25) else
			self.earPoses[i] = {node = node, emergence = emergence, swell = swell}
			local frame = CFrame.new(node) * CFrame.Angles(0, ear.yaw, 0) * CFrame.Angles(0, 0, -ear.tilt * emergence)
			local length = ear.scale * emergence
			local width = ear.scale * emergence * (0.32 + 0.68 * swell)
			local function dims(p) return V(p.X * width, p.Y * length, p.Z * width) end
			local function part(size, at, color, angle)
				rig:block(dims(size), frame * CFrame.new(dims(at)) * (angle or CFrame.identity), color, phase(emergence, 0, 0.08))
			end
			rod(node, frame:PointToWorldSpace(V(0, 0.28 * length, 0)), 0.12 * emergence, GREEN, emergence)
			part(V(0.46, 1.13, 0.40), V(0, 0.94, 0), HUSK:Lerp(GOLD, ripe))
			part(V(0.30, 0.24, 0.31), V(0, 1.60, 0), LIGHT:Lerp(PALE, ripe))
			for _, face in {-1, 1} do for row = 1, 4 do for col = 1, 2 do
				part(V(0.19, 0.21, 0.075), V((col - 1.5) * 0.215, 0.66 + (row - 1) * 0.245, face * 0.224),
					HUSK:Lerp(if (row + col) % 2 == 0 then PALE else GOLD, ripe))
			end end end
			for _, side in {-1, 1} do
				-- Husks open from the ear base; the blade tips stay joined to that base.
				local hinge = frame * CFrame.new(dims(V(side * 0.24, 0.29, 0))) * CFrame.Angles(0, 0, -side * 0.12 * ripe)
				rig:block(dims(V(0.16, 0.74, 0.49)), hinge * CFrame.new(0, 0.37 * length, 0), HUSK, phase(emergence, 0, 0.08))
				local tip = hinge * CFrame.new(0, 0.74 * length, 0) * CFrame.Angles(0, 0, -side * 0.10 * ripe)
				rig:block(dims(V(0.13, 0.62, 0.30)), tip * CFrame.new(0, 0.31 * length, 0), LIGHT, phase(emergence, 0, 0.08))
			end
			for _, side in {-1, 1} do
				rod(frame:PointToWorldSpace(dims(V(side * 0.055, 1.70, 0))), frame:PointToWorldSpace(dims(V(side * 0.14, 1.82, -0.06))),
					0.055 * emergence, PALE:Lerp(SILK, ripe), emergence)
			end
		end
	end
	local q = phase(g, 0.60, 0.85)
	local crown = nodes[8]
	rod(crown, crown + V(0, 0.68, 0) * q, 0.07 * q, YOUNG:Lerp(TASSEL, phase(g, 0.72, 1)), q)
	for i = 1, 4 do
		local spread = phase(g, 0.64 + (i - 1) * 0.015, 0.91)
		local yaw = (i - 1) * math.pi / 2 + 0.35
		local a = crown + V(0, 0.12 + (i % 2) * 0.12, 0) * q
		local b = a + V(math.cos(yaw) * 0.30 * spread, 0.30 * q, math.sin(yaw) * 0.30 * spread)
		local c = b + V(math.cos(yaw) * 0.12 * spread, 0.23 * q, math.sin(yaw) * 0.12 * spread)
		local color = YOUNG:Lerp(TASSEL, phase(g, 0.72, 1))
		rod(a, b, 0.075 * q, color, q); rod(b, c, 0.06 * q, color, q)
	end
	rig:finish()
end

function CornPlant:Destroy()
	self.rig:destroy()
end

-- Mid distance: 5 / 9 / 14 Parts. Keep the jointed upright silhouette,
-- arching leaves, crown tassel and two golden ears; omit kernel/husk detail.
function CornPlant.BuildProxy(parent, soilCFrame, stage, seed, sizeFactor)
	local shape = seededShape(soilCFrame, seed, sizeFactor)
	local growth = if stage <= 1 then 0.20 elseif stage == 2 then 0.90 else 1
	local crown = shape.path[8] * growth
	local function block(name, size, cf, color, slot)
		PlantKit.proxyPart(parent, name, size, soilCFrame * cf, color, nil, if slot then "Fruit" else "Structure", slot)
	end
	local function rod(name, a, b, width, color)
		block(name, V(width, width, (b - a).Magnitude), axis(a, b), color)
	end
	rod("Stem", V(0, 0, 0), crown, if stage <= 1 then 0.09 else 0.16, GREEN)
	local indices = if stage <= 1 then {1, 2} else {2, 3, 6, 7}
	for _, i in indices do
		local leaf = shape.leaves[i]
		local node = crown * leaf.t
		local scale = if stage <= 1 then 0.45 else 1
		local frame = CFrame.new(node) * CFrame.Angles(0, leaf.yaw, 0)
		local path = {V(0, 0, 0), V(0, leaf.rise, leaf.reach * 0.62) * scale,
			V(0, leaf.rise - leaf.droop, leaf.reach) * scale}
		for j = 1, 2 do
			local a, b = path[j], path[j + 1]
			block("Leaf", V(leaf.width * scale * (if j == 1 then 1 else 0.5), 0.075, (b - a).Magnitude + 0.025),
				frame * axis(a, b), if i % 2 == 0 then LIGHT else DARK)
		end
	end
	if stage >= 3 then
		for i, ear in shape.ears do
			local frame = CFrame.new(crown * ear.t) * CFrame.Angles(0, ear.yaw, 0) * CFrame.Angles(0, 0, -ear.tilt)
			block("Ear", V(0.46, 1.45, 0.42) * ear.scale, frame * CFrame.new(0, 1.0 * ear.scale, 0), GOLD, i)
		end
		rod("Tassel", crown, crown + V(0, 0.68, 0), 0.08, TASSEL)
		for _, side in {-1, 1} do
			rod("TasselBranch", crown + V(0, 0.20, 0), crown + V(side * 0.38, 0.65, 0), 0.07, TASSEL)
		end
	end
end

return CornPlant
