-- Tomato art recipe: a staked, single-leader tomato (CG1 / CG2 / CG4; the selected "A, classic" stake study, 2026-11-09).
-- Shared by PlantGrowth and the Studio review. One rigid 6-stud stake is placed once; every seek then poses the same
-- 70 parts from the seed's fixed parameters: 6 stem rods, 3 twine ties, 7 compound leaves (4 parts) and 3 trusses of two fruit.
local TomatoPlant = {}
TomatoPlant.__index = TomatoPlant

local PlantKit = require(script.Parent.PlantKit)
local phase, axis = PlantKit.phase, PlantKit.axis
local V = Vector3.new
local STEM = Color3.fromRGB(59, 119, 64)
local DARK = Color3.fromRGB(41, 126, 66)
local LIT = Color3.fromRGB(83, 161, 74)
local NEW = Color3.fromRGB(143, 187, 75)
local GREEN = Color3.fromRGB(105, 164, 65)
local RED = Color3.fromRGB(219, 52, 43)
local RIPE_RED = Color3.fromRGB(192, 42, 38)
local WOOD = Color3.fromRGB(150, 112, 72)
local TWINE = Color3.fromRGB(214, 190, 140)

-- The ring sits above the stake and ignores mass, like the other tall crops.
TomatoPlant.RingHeight = 6.8
TomatoPlant.FixedRingHeight = true
TomatoPlant.ReviewHeight = 6.2

local STAKE_HEIGHT = 6
local STEM_RADIUS = 0.26 -- the stem winds around the stake axis at this distance
local TOP = 5.5 -- nominal height of the leader tip (scaled by the seed's height)
local STEM_END = 0.68 -- growth at which the leader reaches its top
local LEADER = {0, 0.9, 1.8, 2.7, 3.6, 4.5, 5.5}
local TIES = {1.2, 2.9, 4.5}
-- Node height, yaw in degrees, blade length, droop, colour.
local FRONDS = {
	{0.6, 100, 1.3, -0.20, LIT}, {1.75, -110, 1.6, -0.25, DARK}, {2.4, 75, 1.5, -0.25, LIT}, {3.5, -95, 1.5, -0.20, DARK},
	{4.0, 120, 1.3, -0.15, LIT}, {5.0, 70, 1.2, 0, NEW}, {5.5, -60, 1.0, 0.15, NEW},
}
-- Node height, yaw, rachis length, rise, growth at which the fruit start to swell, fruit {t along the rachis, size, pedicel drop}.
local TRUSSES = {
	{1.15, 35, 1.20, 0.15, 0.38, {{0.5, 0.85, 0.28}, {1.0, 0.90, 0.50}}},
	{2.95, -40, 1.15, 0.15, 0.46, {{0.5, 0.80, 0.30}, {1.0, 0.85, 0.55}}},
	{4.40, 50, 1.00, 0.12, 0.54, {{0.5, 0.70, 0.25}, {1.0, 0.75, 0.45}}},
}

-- Bounded planting tendencies: height, stem weave (degrees), mirror, leaf length, fruit sizes, truss lengths.
-- Baseline, fruit-heavy, leafy and tall, compact, lopsided, airy. Ordinary consecutive seeds expose all six.
local TENDENCIES = {
	{1.00, 55, 1, 1.00, {1.00, 1.00, 1.00}, {1.00, 1.00, 1.00}},
	{0.97, 45, -1, 0.90, {1.12, 1.10, 1.05}, {1.05, 1.00, 0.95}},
	{1.03, 62, 1, 1.12, {0.90, 0.92, 0.95}, {0.95, 1.00, 1.05}},
	{0.90, 40, -1, 0.95, {1.00, 0.95, 0.90}, {0.90, 0.92, 0.90}},
	{1.00, 68, 1, 1.05, {1.08, 0.90, 1.00}, {1.15, 0.85, 1.10}},
	{0.95, 50, -1, 1.05, {0.92, 1.05, 1.10}, {1.00, 1.12, 0.90}},
}

-- Fixed topology after the stake: initialize names and stud variants even for hidden pieces.
local PART_METADATA = {}
local function metadata(name, variant)
	table.insert(PART_METADATA, { name, variant or "StudsSmall" })
end
for _ = 1, #LEADER - 1 do metadata("Stem") end
for _ = 1, #TIES do metadata("Tie") end
for _ = 1, #FRONDS do
	metadata("Leaf", "Studs")
	metadata("LeafTip")
	metadata("Leaflet")
	metadata("Leaflet")
end
for _ = 1, #TRUSSES do
	metadata("Stem")
	for _ = 1, 2 do
		for _, name in {"Stem", "Sepal", "Shoulder", "Tomato", "Base"} do
			metadata(name)
		end
	end
end
assert(#PART_METADATA == 70, "Tomato metadata budget changed")

local function radiusOf(parts, soil)
	local radius = 0
	for _, part in parts do
		if part.Transparency < 1 then
			local relative = soil:ToObjectSpace(part.CFrame)
			local half = part.Size / 2
			for _, x in {-1, 1} do
				for _, y in {-1, 1} do
					for _, z in {-1, 1} do
						local corner = relative:PointToWorldSpace(half * V(x, y, z))
						radius = math.max(radius, V(corner.X, 0, corner.Z).Magnitude)
					end
				end
			end
		end
	end
	return radius
end

-- Draw order is part of a planting's identity: a new draw goes last.
function TomatoPlant.new(parent, soilCFrame, seed, sizeFactor)
	local self = setmetatable({}, TomatoPlant)
	self.rig = PlantKit.newRig("TomatoPlant", soilCFrame)
	self.model = self.rig.model
	self.scale = PlantKit.dimension(sizeFactor)
	self.horizontalFit = 1
	-- Seed one is the approved A; other seeds vary tendency, leaf angles, truss sides and fruit size.
	local vary = PlantKit.seeded(seed)
	local tendency = PlantKit.tendency(TENDENCIES, seed)
	self.height = tendency[1] + vary(0.02)
	self.weave = math.rad(tendency[2] + vary(10))
	self.phase = vary(0.5)
	self.mirror = tendency[3]
	self.fronds, self.trusses = {}, {}
	for i = 1, #FRONDS do
		self.fronds[i] = {yaw = vary(14), length = tendency[4] * (1 + vary(0.10)), droop = vary(0.05)}
	end
	for k = 1, #TRUSSES do
		local first, second = vary(0.08), vary(0.08)
		self.trusses[k] = {
			yaw = vary(12), out = tendency[6][k] * (1 + vary(0.08)),
			fruit = {tendency[5][k] * (1 + first), tendency[5][k] * (1 + second)}, timing = vary(0.02),
		}
	end
	-- Equipment is present from planting and never follows seed, mass or growth.
	local stake = self.rig:add("Stake", "Studs", "Support")
	stake.Size, stake.CFrame, stake.Color, stake.Transparency =
		V(0.22, STAKE_HEIGHT, 0.22), soilCFrame * CFrame.new(0, STAKE_HEIGHT / 2, 0), WOOD, 0
	for _, meta in PART_METADATA do
		self.rig:add(meta[1], meta[2])
	end
	-- Fit off the DataModel before revealing the plant. Check the opening poses as
	-- well as ripe leaves; only horizontal spread/foliage is constrained.
	for _ = 1, 16 do
		local radius = 0
		for _, growth in {0.2, 0.5, 0.75, 1} do
			self:SetGrowth(growth)
			radius = math.max(radius, radiusOf(self.rig.parts, soilCFrame))
		end
		if radius <= 2.4 then break end
		self.horizontalFit *= math.min(0.90, 2.35 / radius)
		self.rig.growth = nil
	end
	self:SetGrowth(0)
	self.model.Parent = parent
	return self
end

function TomatoPlant:SetGrowth(normalized)
	local rig = self.rig
	local g = rig:beginPose(normalized, 1) -- the rigid stake is placed once in new()
	if not g then return end
	local scale, fit, height, mirror = self.scale, self.horizontalFit, self.height, self.mirror
	local top = TOP * height
	local tip = 0.15 + (top - 0.15) * phase(g, 0, STEM_END)

	local function stemPoint(h)
		local a = mirror * self.weave * math.sin(h * 1.1 + self.phase)
		return V(STEM_RADIUS * math.sin(a), h, STEM_RADIUS * math.cos(a)), a
	end
	-- Growth at which the stem tip reaches height h (inverse of the smoothstep).
	local function reach(h)
		local n = math.clamp((h - 0.15) / (top - 0.15), 0, 1)
		return STEM_END * (0.5 - math.sin(math.asin(1 - 2 * n) / 3))
	end
	local function opened(offset, opening)
		-- Keep a small horizontal component while tucked; its fixed hinge axis
		-- avoids the lookAt up-vector switch near a vertical leaf.
		return offset.Unit:Lerp(Vector3.yAxis, (1 - opening) * 0.94).Unit * offset.Magnitude
	end
	local function leaf(at, offset, width, color, q)
		if q <= 0 then
			rig:hide(2)
			return
		end
		local direction = opened(offset, q)
		local blade = direction * q
		local length = blade.Magnitude
		local right = Vector3.yAxis:Cross(offset).Unit
		local back = direction.Unit
		local cf = CFrame.fromMatrix(at + blade / 2, right, back:Cross(right), back)
		rig:block(V(width * q, 0.14 * q, length * 0.72), cf * CFrame.new(0, 0, -length * 0.14), color, 1)
		rig:block(V(width * q * 0.56, 0.13 * q, length * 0.28), cf * CFrame.new(0, 0, length * 0.36), color, 1)
	end

	-- The leader grows up the stake; each rod extends to the tip while the tip is inside it.
	local thickness = 0.55 + 0.45 * phase(g, 0, 0.5)
	for i = 1, #LEADER - 1 do
		local from, to = LEADER[i] * height, LEADER[i + 1] * height
		if i > 1 and tip <= from + 0.01 then
			rig:hide(1)
		else
			local a, b = stemPoint(from), stemPoint(math.min(tip, to))
			local width = (0.24 - 0.11 * (i - 1) / (#LEADER - 2)) * thickness
			rig:block(V(width, width, (b - a).Magnitude), axis(a, b), STEM, 1)
		end
	end
	for _, h in TIES do
		local nodeHeight = h * height
		local q = phase(tip, nodeHeight + 0.1, nodeHeight + 0.5)
		if q <= 0 then
			rig:hide(1)
		else
			local point, a = stemPoint(nodeHeight)
			rig:block(V(0.42 * q, 0.10 * q, 0.62 * q), CFrame.new((point + V(0, nodeHeight, 0)) / 2) * CFrame.Angles(0, a, 0), TWINE, 1)
		end
	end
	-- Compound leaves: blade tucked up along the stem, then unfolding; side leaflets follow.
	for i, node in FRONDS do
		local seeded = self.fronds[i]
		local nodeHeight = node[1] * height
		local first = reach(nodeHeight)
		local q = phase(g, first, first + 0.16)
		if q <= 0 then
			rig:hide(4)
		else
			local at = stemPoint(nodeHeight)
			local yaw = math.rad(node[2] + seeded.yaw) * mirror
			local length = node[3] * seeded.length * scale
			local direction = V(math.sin(yaw), node[4] + seeded.droop, math.cos(yaw)).Unit * length
			direction = V(direction.X * fit, direction.Y, direction.Z * fit)
			local width = 0.78 * scale * fit
			leaf(at, direction, width, node[5], q)
			local small = q * phase(g, first + 0.06, first + 0.22)
			local open = opened(direction, q)
			local joint = at + open * 0.38 * q
			local side = Vector3.yAxis:Cross(direction).Unit
			for sign = -1, 1, 2 do
				if small <= 0 then
					rig:hide(1)
				else
					local offset = (open * 0.45 + side * (sign * length * 0.42) + V(0, 0.06, 0)) * small
					rig:block(V(width * 0.7 * small, 0.13 * small, offset.Magnitude), axis(joint, joint + offset), LIT, 1)
				end
			end
		end
	end
	-- Trusses: a short rachis, then green fruit that swell and redden together toward 100%.
	local ripening = phase(g, 0.74, 1)
	for k, node in TRUSSES do
		local seeded = self.trusses[k]
		local nodeHeight = node[1] * height
		local first = reach(nodeHeight)
		local extension = phase(g, first + 0.02, first + 0.20)
		if extension <= 0 then
			rig:hide(11)
		else
			local at = stemPoint(nodeHeight)
			local yaw = math.rad(node[2] + seeded.yaw) * mirror
			local out = node[3] * seeded.out * scale * fit * extension
			local rachisEnd = at + V(math.sin(yaw) * out, node[4] * extension, math.cos(yaw) * out)
			rig:block(V(0.11 * extension, 0.11 * extension, (rachisEnd - at).Magnitude), axis(at, rachisEnd), STEM, 1)
			for j, fruit in node[6] do
				local swell = phase(g, node[5] + seeded.timing, 1)
				if swell <= 0 then
					rig:hide(5)
				else
					local size = fruit[2] * seeded.fruit[j] * scale * swell
					local from = at:Lerp(rachisEnd, fruit[1])
					-- The heaviest fruit stays above soil on a compact seeded plant.
					local hangY = math.min(math.max(from.Y - fruit[3] * scale * swell, size * 0.84 + 0.04), from.Y - 0.1)
					local hang = V(from.X, hangY, from.Z)
					rig:block(V(0.07 * swell, 0.07 * swell, (from - hang).Magnitude), axis(from, hang), STEM, 1)
					local ripe = if j == 1 then RED else RIPE_RED
					local color = if g == 1 then ripe else GREEN:Lerp(ripe, ripening)
					local topCF = CFrame.new(hang)
					rig:block(V(size * 0.6, 0.09 * swell, size * 0.6), topCF * CFrame.Angles(0, math.rad(45), 0), DARK, 1)
					rig:block(V(size * 0.74, size * 0.17, size * 0.70), topCF * CFrame.new(0, -size * 0.085, 0), color, 1)
					rig:block(V(size, size * 0.6, size * 0.8), topCF * CFrame.new(0, -size * 0.47, 0), color, 1)
					rig:block(V(size * 0.72, size * 0.16, size * 0.64), topCF * CFrame.new(0, -size * 0.84, 0), color, 1)
				end
			end
		end
	end
	rig:finish()
end

function TomatoPlant:Destroy()
	self.rig:destroy()
end

-- Mid-distance silhouette: the rigid stake from planting, leaf plates up the stake and, when ripe, three fruit.
function TomatoPlant.BuildProxy(parent: Instance, soil: CFrame, stage: number, seed: number?, sizeFactor: number?)
	if stage <= 0 then return end
	local scale = PlantKit.dimension(sizeFactor)
	local tendency = PlantKit.tendency(TENDENCIES, seed)
	local leaf, mirror = tendency[4], tendency[3]
	local pieces = {}
	if stage == 1 then
		table.insert(pieces, {"Canopy", V(1.0, 0.5, 0.8) * leaf, V(0, 0.55, 0), LIT, "Studs"})
	elseif stage == 2 then
		table.insert(pieces, {"Canopy", V(2.5, 0.45, 1.5) * leaf, V(0.1 * mirror, 1.7, 0), LIT, "Studs"})
		table.insert(pieces, {"Canopy", V(2.0, 0.45, 1.2) * leaf, V(-0.1 * mirror, 3.4, 0), DARK, "Studs"})
	else
		table.insert(pieces, {"Canopy", V(2.8, 0.5, 1.6) * leaf, V(0.1 * mirror, 1.9, 0), LIT, "Studs"})
		table.insert(pieces, {"Canopy", V(2.4, 0.45, 1.4) * leaf, V(-0.1 * mirror, 3.5, 0), DARK, "Studs"})
		table.insert(pieces, {"Canopy", V(1.8, 0.45, 1.2) * leaf, V(0.05 * mirror, 5.0, 0), NEW, "Studs"})
		for i, at in {V(1.0, 0.85, 0.4), V(-0.95, 2.5, 0.3), V(0.95, 4.0, 0.3)} do
			local size = tendency[5][i]
			table.insert(pieces, {"Tomato", V(0.9, 0.75, 0.8) * size, V(at.X * mirror, at.Y * tendency[1], at.Z), RED, "StudsSmall"})
		end
	end
	local radius = 0
	for _, piece in pieces do
		local size, at = piece[2] * scale, piece[3]
		radius = math.max(radius, V(math.abs(at.X) + size.X / 2, 0, math.abs(at.Z) + size.Z / 2).Magnitude)
	end
	local fit = math.min(1, 2.4 / radius)
	-- Rigid equipment: full-sized from planting, independent of mass.
	PlantKit.proxyPart(parent, "Stake", V(0.22, STAKE_HEIGHT, 0.22), soil * CFrame.new(0, STAKE_HEIGHT / 2, 0), WOOD, "Studs", "Support")
	for _, piece in pieces do
		local size = piece[2]
		local dimensions = V(size.X * fit, size.Y, size.Z * fit) * scale
		local at = V(piece[3].X * fit, piece[3].Y, piece[3].Z * fit)
		PlantKit.proxyPart(parent, piece[1], dimensions, soil * CFrame.new(at), piece[4], piece[5])
	end
end

return TomatoPlant
