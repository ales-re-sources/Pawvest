-- CG6b display recipe: selected B, with a slightly taller jointed stalk.
-- 13 stalk/node + 27 blade + 50 ear + 9 tassel Parts, created once.
local CornPlant = {}
CornPlant.__index = CornPlant
CornPlant.ReviewHeight = 9.5
CornPlant.RingHeight = 10.8
CornPlant.FixedRingHeight = true

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

local function phase(g, first, last)
	local t = math.clamp((g - first) / (last - first), 0, 1)
	return t * t * (3 - 2 * t)
end

local function axis(a, b)
	local delta = b - a
	if delta.Magnitude < 0.000001 then return CFrame.new(a) end
	local up = if math.abs(delta.Unit.Y) > 0.98 then Vector3.xAxis else Vector3.yAxis
	return CFrame.lookAt((a + b) / 2, b, up)
end

function CornPlant.new(parent, soilCFrame, seed, sizeFactor)
	local self = setmetatable({}, CornPlant)
	local mass = sizeFactor or 1
	assert(type(mass) == "number" and mass > 0 and mass < math.huge, "Invalid plant size factor")
	self.model = Instance.new("Model")
	self.model.Name = "CornPlant"
	self.base, self.parts, self.applied = soilCFrame, {}, {}
	self.leafPoses, self.earPoses, self.fruitSlots = {}, {}, {}
	local random = Random.new(seed or 1)
	local amount = if (seed or 1) == 1 then 0 else 1
	local function vary(extent) return random:NextNumber(-extent, extent) * amount end
	self.dimensionScale = mass ^ (1 / 3)
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
	local function create(name, slot)
		local p = Instance.new("Part")
		p.Name, p.Material, p.MaterialVariant = name, Enum.Material.Plastic, "StudsSmall"
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
		p.Transparency = 1
		p:SetAttribute("PlantRole", if slot then "Fruit" else "Structure")
		if slot then p:SetAttribute("FruitSlot", slot); table.insert(self.fruitSlots[slot].parts, p) end
		p.Parent = self.model
		table.insert(self.parts, p)
		table.insert(self.applied, {})
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
	assert(#self.parts == 99, "Corn topology changed")
	self:SetGrowth(0)
	self.model.Parent = parent
	return self
end

function CornPlant:SetGrowth(normalized)
	assert(not self.destroyed, "CornPlant has been destroyed")
	assert(type(normalized) == "number" and normalized == normalized, "Growth must be a number")
	local g = math.clamp(normalized, 0, 1)
	if self.growth == g then return end
	self.growth = g
	local cursor = 0
	local function block(size, cf, color, opacity)
		cursor += 1
		local p, old = self.parts[cursor], self.applied[cursor]
		local transparency = 1 - opacity
		if opacity > 0 then
			local actual = V(math.max(size.X, 0.001), math.max(size.Y, 0.001), math.max(size.Z, 0.001))
			local world = self.base * cf
			if old.size ~= actual then p.Size, old.size = actual, actual end
			if old.cf ~= world then p.CFrame, old.cf = world, world end
			if old.color ~= color then p.Color, old.color = color, color end
		end
		if old.transparency ~= transparency then p.Transparency, old.transparency = transparency, transparency end
	end
	local function rod(a, b, width, color, q)
		block(V(width, width, (b - a).Magnitude), axis(a, b), color, phase(q, 0, 0.08))
	end
	local nodes = {self.path[1]}
	for i = 1, 7 do
		local q = phase(g, (i - 1) * 0.075, (i - 1) * 0.075 + 0.23)
		if i == 1 then q = 0.16 + 0.84 * q end
		nodes[i + 1] = nodes[i] + (self.path[i + 1] - self.path[i]) * q
		rod(nodes[i], nodes[i + 1], (0.18 - (i - 1) * 0.012) * (0.55 + 0.45 * q), YOUNG:Lerp(GREEN, q), q)
		if i < 7 then block(V(0.21, 0.08, 0.21) * q, CFrame.new(nodes[i + 1]), LIGHT, phase(q, 0, 0.08)) end
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
		if old and old.q == q and old.node == node then cursor += 3 else
			self.leafPoses[i] = {q = q, node = node}
			local frame = CFrame.new(node) * CFrame.Angles(0, leaf.yaw, 0) * CFrame.Angles(-1.30 * (1 - q), 0, 0)
			local reach, rise, droop = leaf.reach * q, leaf.rise * q, leaf.droop * q * q
			local path = {V(0, 0, 0), V(0, rise, reach * 0.36), V(0, rise * 0.92, reach * 0.72), V(0, rise - droop, reach)}
			local widths = {0.72, 1, 0.43}
			for j = 1, 3 do
				local a, b = path[j], path[j + 1]
				block(V(leaf.width * widths[j] * q, 0.075 * q, (b - a).Magnitude + 0.035 * q),
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
		if old and old.node == node and old.emergence == emergence and old.swell == swell then cursor += 25 else
			self.earPoses[i] = {node = node, emergence = emergence, swell = swell}
			local frame = CFrame.new(node) * CFrame.Angles(0, ear.yaw, 0) * CFrame.Angles(0, 0, -ear.tilt * emergence)
			local length = ear.scale * emergence
			local width = ear.scale * emergence * (0.32 + 0.68 * swell)
			local function dims(p) return V(p.X * width, p.Y * length, p.Z * width) end
			local function part(size, at, color, angle)
				block(dims(size), frame * CFrame.new(dims(at)) * (angle or CFrame.identity), color, phase(emergence, 0, 0.08))
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
				block(dims(V(0.16, 0.74, 0.49)), hinge * CFrame.new(0, 0.37 * length, 0), HUSK, phase(emergence, 0, 0.08))
				local tip = hinge * CFrame.new(0, 0.74 * length, 0) * CFrame.Angles(0, 0, -side * 0.10 * ripe)
				block(dims(V(0.13, 0.62, 0.30)), tip * CFrame.new(0, 0.31 * length, 0), LIGHT, phase(emergence, 0, 0.08))
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
	assert(cursor == #self.parts, "Corn pose topology changed")
end

function CornPlant:Destroy()
	if self.destroyed then return end
	self.destroyed = true
	self.model:Destroy()
end

return CornPlant
