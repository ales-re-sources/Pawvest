-- Display-only CG5b recipe: the approved tall B trellis, with reversible growth.
-- 4 rigid supports + 9 vine segments + 36 leaf pieces + 63 fruit pieces + 3 tendrils.
local FrostGrapePlant = {}
FrostGrapePlant.__index = FrostGrapePlant
FrostGrapePlant.RingHeight = 8.1
FrostGrapePlant.FixedOrientation = true
FrostGrapePlant.FixedRingHeight = true
FrostGrapePlant.ReviewHeight = 7.6

local V = Vector3.new
local WOOD = Color3.fromRGB(123, 105, 85)
local CANE = Color3.fromRGB(87, 82, 104)
local STEM = Color3.fromRGB(68, 118, 111)
local DARK = Color3.fromRGB(46, 115, 111)
local LIGHT = Color3.fromRGB(77, 145, 131)
local YOUNG = Color3.fromRGB(113, 166, 128)
local GREEN_BLUE = Color3.fromRGB(77, 143, 140)
local ICE = Color3.fromRGB(195, 234, 241)
local BERRIES = {Color3.fromRGB(103, 111, 196), Color3.fromRGB(126, 151, 221), Color3.fromRGB(81, 95, 167)}
local PATH = {V(0, 0.02, 0), V(-0.12, 1.35, 0.12), V(0.12, 3.55, 0.08), V(0.03, 5.30, 0)}
-- Parent segment index, mature endpoint, opening and completion times.
local ARMS = {
	{0, V(-0.85, 5.36, 0), 0.42, 0.54}, {1, V(-1.67, 5.48, 0), 0.49, 0.61},
	{0, V(0.84, 5.38, 0), 0.42, 0.54}, {3, V(1.66, 5.47, 0), 0.49, 0.61},
	{1, V(-0.87, 7.04, -0.06), 0.52, 0.69}, {3, V(0.73, 7.12, -0.04), 0.52, 0.69},
}
-- Parent arm (zero = main tip, -1 = lower cane), node, hinge, size, yaw, tilt, timing.
local LEAVES = {
	{2, V(-1.67, 5.48, 0), V(-1.56, 6.12, 0.10), 0.94, -0.35, 0.20, 0.55, 0.76},
	{5, V(-0.87, 7.04, -0.06), V(-0.93, 7.23, -0.16), 1.0, 2.4, -0.25, 0.59, 0.72},
	{0, V(0.03, 5.30, 0), V(0.03, 6.45, -0.12), 0.89, 0.2, 0.18, 0.12, 0.72},
	{6, V(0.73, 7.12, -0.04), V(0.78, 7.26, -0.15), 1.0, 2.5, -0.24, 0.59, 0.72},
	{4, V(1.66, 5.47, 0), V(1.54, 6.15, 0.10), 0.91, 0.35, 0.20, 0.55, 0.76},
	{-1, V(0.02, 2.55, 0.10), V(0.50, 2.98, 0.22), 0.78, 0.60, 0.20, 0.10, 0.35},
}
local LOBES = {
	{V(0, 0, 0.20), V(0.44, 0.10, 0.79), 0},
	{V(-0.27, 0, 0.05), V(0.35, 0.10, 0.60), -0.75},
	{V(0.27, 0, 0.05), V(0.35, 0.10, 0.60), 0.75},
	{V(-0.26, 0, -0.23), V(0.30, 0.10, 0.37), -1.05},
	{V(0.26, 0, -0.23), V(0.30, 0.10, 0.37), 1.05},
}
local FRUIT = {
	{V(-1.29, 5.42, 0), V(-1.28, 5.19, 0.48), 0.95, -0.1},
	{V(0.02, 5.30, 0), V(0.06, 5.05, 0.48), 0.86, 0.2},
	{V(1.28, 5.42, 0), V(1.27, 5.20, 0.48), 1.0, 0.05},
}
local BERRY_POSITIONS = {
	V(-0.23, -0.13, 0), V(0.23, -0.13, 0), V(0, -0.10, -0.26),
	V(-0.23, -0.47, 0.08), V(0.23, -0.47, 0.08), V(0, -0.42, -0.22),
	V(-0.14, -0.78, 0.05), V(0.14, -0.78, -0.10), V(0, -1.06, 0),
}

local function phase(g, first, last)
	local t = math.clamp((g - first) / (last - first), 0, 1)
	return t * t * (3 - 2 * t)
end

local function axis(a, b)
	local d = b - a
	if d.Magnitude < 0.000001 then return CFrame.new(a) end
	local up = if math.abs(d.Unit.Y) > 0.98 then Vector3.xAxis else Vector3.yAxis
	return CFrame.lookAt((a + b) / 2, a, up)
end

function FrostGrapePlant.new(parent, soilCFrame, seed, sizeFactor)
	local self = setmetatable({}, FrostGrapePlant)
	self.model = Instance.new("Model")
	self.model.Name = "FrostGrapePlant"
	self.base, self.parts, self.applied, self.leafPoses = soilCFrame, {}, {}, {}
	local mass = sizeFactor or 1
	assert(type(mass) == "number" and mass > 0 and mass < math.huge, "Invalid plant size factor")
	self.dimensionScale = mass ^ (1 / 3)
	local random = Random.new(seed or 1)
	local amount = if (seed or 1) == 1 then 0 else 1
	local function vary(extent) return random:NextNumber(-extent, extent) * amount end
	local function bend(p, extent, height)
		return p + V(vary(extent), vary(height or 0.035), vary(extent * 0.7))
	end
	self.path = {PATH[1], bend(PATH[2], 0.12, 0.10), bend(PATH[3], 0.12, 0.10), bend(PATH[4], 0.055, 0.10)}
	self.arms, self.leaves, self.fruit, self.fruitSlots = {}, {}, {}, {}
	for i, arm in ARMS do
		self.arms[i] = bend(arm[2], if i <= 4 then 0.09 else 0.075, 0.11)
	end
	for i, leaf in LEAVES do
		local parentNode
		if leaf[1] > 0 then
			parentNode = self.arms[leaf[1]]
		elseif leaf[1] == 0 then
			parentNode = self.path[4]
		else
			local fraction = (leaf[2].Y - PATH[2].Y) / (PATH[3].Y - PATH[2].Y)
			parentNode = self.path[2]:Lerp(self.path[3], fraction) + (leaf[2] - PATH[2]:Lerp(PATH[3], fraction))
		end
		local hinge = parentNode + (leaf[3] - leaf[2]) + V(vary(0.045), vary(0.025), vary(0.045))
		local scale = leaf[4] * (1 + vary(0.13))
		-- A rotation-independent blade bound also covers the folded intermediate poses.
		-- Both stalk offset and blade length grow with q; their bound interpolates
		-- from the bare parent node to this mature hinge-plus-blade bound.
		local radius = V(hinge.X, 0, hinge.Z).Magnitude
		scale = math.min(scale, (2.35 - radius) / 0.75)
		self.leaves[i] = {node = parentNode, offset = hinge - parentNode, scale = scale,
			yaw = leaf[5] + vary(0.28), tilt = leaf[6] + vary(0.10)}
	end
	for i, fruit in FRUIT do
		local first, last = if i == 1 then 1 else 3, if i == 1 then 2 else 4
		local fraction = (fruit[1].X - ARMS[first][2].X) / (ARMS[last][2].X - ARMS[first][2].X)
		local reference = ARMS[first][2]:Lerp(ARMS[last][2], fraction)
		local attachment = (if i == 2 then fruit[1] - PATH[4] else fruit[1] - reference) + V(vary(0.015), vary(0.015), vary(0.015))
		local berries = {}
		for j, at in BERRY_POSITIONS do
			berries[j] = {at = at + V(vary(0.025), vary(0.025), vary(0.025)), size = 1 + vary(0.09)}
		end
		self.fruit[i] = {first = first, last = last, fraction = fraction, attachment = attachment,
			offset = fruit[2] - fruit[1] + V(vary(0.04), vary(0.14), vary(0.04)),
			scale = fruit[3] * self.dimensionScale * (1 + vary(0.12)), turn = fruit[4] + vary(0.16), berries = berries}
		local node = if i == 2 then self.path[4] + attachment
			else self.arms[first]:Lerp(self.arms[last], fraction) + attachment
		-- Stable visual slots, independent of Part order and future fruit-cycle state.
		-- Attachment is the mature, seeded stalk origin, not the moving berry center.
		self.fruitSlots[i] = {id = i, attachment = soilCFrame * CFrame.new(node), parts = {}}
	end
	local function create(name, variant, fruitSlot)
		local p = Instance.new("Part")
		p.Name, p.Material, p.MaterialVariant = name, Enum.Material.Plastic, variant or "StudsSmall"
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
		p.Transparency = 1
		p:SetAttribute("PlantRole", if fruitSlot then "Fruit"
			elseif name == "RigidPost" or name == "RigidRail" then "Support" else "Structure")
		if fruitSlot then
			p:SetAttribute("FruitSlot", fruitSlot)
			table.insert(self.fruitSlots[fruitSlot].parts, p)
		end
		p.Parent = self.model
		table.insert(self.parts, p)
		table.insert(self.applied, {})
		return p
	end
	-- Equipment is present before planting and never follows seed, mass or growth.
	for _, x in {-1.88, 1.88} do
		local p = create("RigidPost", "Studs")
		p.Size, p.CFrame, p.Color, p.Transparency = V(0.19, 7.40, 0.19), soilCFrame * CFrame.new(x, 3.70, -0.14), WOOD, 0
	end
	for _, y in {5.30, 7.10} do
		local p = create("RigidRail")
		p.Size, p.CFrame, p.Color, p.Transparency = V(3.95, 0.095, 0.095), soilCFrame * CFrame.new(0, y, -0.14), WOOD, 0
	end
	for _ = 1, 9 do create("Cane") end
	for _ = 1, 6 do
		create("LeafStalk")
		for _ = 1, 5 do create("LeafLobe", "Studs") end
	end
	for slot = 1, 3 do
		create("BunchStalk", nil, slot)
		for _ = 1, 9 do create("Grape", nil, slot); create("GrapeCrown", nil, slot) end
		create("FrostFacet", nil, slot); create("FrostFacet", nil, slot)
	end
	for _ = 1, 3 do create("Tendril") end
	assert(#self.parts == 115, "Frost grape topology changed")
	self:SetGrowth(0)
	self.model.Parent = parent
	return self
end

function FrostGrapePlant:SetGrowth(normalized)
	assert(not self.destroyed, "FrostGrapePlant has been destroyed")
	assert(type(normalized) == "number" and normalized == normalized, "Growth must be a number")
	local g = math.clamp(normalized, 0, 1)
	if self.growth == g then return end
	self.growth = g
	local cursor = 4
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
	local main, mainQ = {self.path[1]}, {}
	local starts, finishes = {0.01, 0.18, 0.35}, {0.20, 0.36, 0.49}
	for i = 1, 3 do
		local q = phase(g, starts[i], finishes[i])
		mainQ[i] = q
		main[i + 1] = main[i]:Lerp(self.path[i + 1], q)
		rod(main[i], main[i + 1], 0.15 * (0.55 + 0.45 * q), YOUNG:Lerp(CANE, phase(g, 0.15, 0.75)), q)
	end
	local arms = {}
	for i, spec in ARMS do
		local a = if spec[1] == 0 then main[4] else arms[spec[1]]
		local q = phase(g, spec[3], spec[4])
		arms[i] = a:Lerp(self.arms[i], q)
		rod(a, arms[i], 0.115 * (0.5 + 0.5 * q), STEM, q)
	end
	for i, spec in LEAVES do
		local leaf = self.leaves[i]
		local q = phase(g, spec[7], spec[8])
		local node
		if spec[1] > 0 then
			node = arms[spec[1]]
		elseif spec[1] == 0 then
			node = main[4]
		else
			-- This node stops travelling as soon as its section of cane has grown.
			local fraction = (leaf.node.Y - self.path[2].Y) / (self.path[3].Y - self.path[2].Y)
			local reached = math.min(fraction, mainQ[2])
			local onCane = self.path[2]:Lerp(self.path[3], fraction)
			node = main[2]:Lerp(self.path[3], reached) + (leaf.node - onCane) * math.min(1, mainQ[2] / fraction)
		end
		local old = self.leafPoses[i]
		if old and old.q == q and old.node == node then
			cursor += 6
		else
			self.leafPoses[i] = {q = q, node = node}
			local at = node + leaf.offset * q
			rod(node, at, 0.09 * (0.35 + 0.65 * q), STEM, q)
			-- Blade pieces share the same hinge and unfold together around its X axis.
			local face = CFrame.new(at) * CFrame.Angles(leaf.tilt + 1.20 * (1 - q), leaf.yaw, 0)
			local scale = leaf.scale * q
			for j, lobe in LOBES do
				local color = if j % 2 == 0 then DARK else LIGHT
				block(lobe[2] * scale, face * CFrame.new(lobe[1] * scale) * CFrame.Angles(0, lobe[3], 0),
					YOUNG:Lerp(color, q), phase(q, 0, 0.08))
			end
		end
	end
	for i, fruit in self.fruit do
		local parent
		if i == 2 then
			parent = main[4] + fruit.attachment * mainQ[3]
		else
			parent = arms[fruit.first]:Lerp(arms[fruit.last], fruit.fraction) + fruit.attachment * phase(g, 0.49, 0.61)
		end
		local stalk = phase(g, 0.55, 0.65)
		local swell = phase(g, 0.60, 1)
		local at = parent + fruit.offset * stalk + V(0, 0.10 * stalk * (1 - swell), 0)
		rod(parent, at, 0.10 * (0.4 + 0.6 * stalk), STEM, stalk)
		local frame = CFrame.new(at) * CFrame.Angles(0, fruit.turn, 0)
		for j, berry in fruit.berries do
			local q = phase(g, 0.60 + ((j - 1) % 3) * 0.012, 0.96 + ((j - 1) % 3) * 0.02)
			local size = (if j == 9 then 0.35 else 0.43) * berry.size * fruit.scale * q
			local cf = frame * CFrame.new(berry.at * fruit.scale * (0.35 + 0.65 * q)) * CFrame.Angles(0, (j % 3) * 0.20, 0)
			local color = GREEN_BLUE:Lerp(BERRIES[(j - 1) % 3 + 1], phase(g, 0.73, 1))
			block(V(size, size * 0.73, size * 0.85), cf, color, phase(q, 0, 0.08))
			block(V(size * 0.76, size * 0.95, size * 0.72), cf, color, phase(q, 0, 0.08))
		end
		for j = 1, 2 do
			local frost = phase(g, 0.84, 1)
			local berry = fruit.berries[j]
			local q = phase(g, 0.60 + (j - 1) * 0.012, 0.96 + (j - 1) * 0.02)
			local position = berry.at * (0.35 + 0.65 * q)
			local y = position.Y + (0.43 * berry.size * 0.475 + 0.00075) * q
			local cf = frame * CFrame.new(V(position.X, y, position.Z) * fruit.scale) * CFrame.Angles(0, 0.20, 0)
			block(V(0.28 * frost, 0.055 * frost, 0.30 * frost) * fruit.scale * q, cf, ICE, frost)
		end
	end
	local q = phase(g, 0.61, 0.78)
	local tip = arms[4]
	local curl = {tip, tip + V(0.14, 0.28, -0.13) * q, tip + V(0.35, 0.30, -0.20) * q, tip + V(0.30, 0.13, -0.17) * q}
	for i = 1, 3 do rod(curl[i], curl[i + 1], 0.055 * (0.4 + 0.6 * q), STEM, q) end
	assert(cursor == #self.parts, "Frost grape pose topology changed")
end

function FrostGrapePlant:Destroy()
	if self.destroyed then return end
	self.destroyed = true
	self.model:Destroy()
end

return FrostGrapePlant
