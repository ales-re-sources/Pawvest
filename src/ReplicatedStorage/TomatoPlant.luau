-- Tomato art recipe. Shared by PlantGrowth and the Studio review.
-- Every seek poses the same 54 parts from the seed's fixed parameters.
local TomatoPlant = {}
TomatoPlant.__index = TomatoPlant

local V = Vector3.new
local STEM = Color3.fromRGB(59, 119, 64)
local DARK = Color3.fromRGB(41, 126, 66)
local LIT = Color3.fromRGB(83, 161, 74)
local NEW = Color3.fromRGB(143, 187, 75)
local GREEN = Color3.fromRGB(105, 164, 65)
local RED = Color3.fromRGB(219, 52, 43)
local RIPE_RED = Color3.fromRGB(192, 42, 38)
local ARMS = {
	{V(-0.75, 1.37, 0.05), V(-1.18, 1.23, 0.44), V(-0.98, 0.12, -0.36), 0.85},
	{V(0.68, 1.40, 0.14), V(1.19, 1.33, 0.34), V(0.94, 0.20, -0.35), 0.78},
	{V(-0.20, 1.60, -0.50), V(-0.70, 1.40, -0.82), V(-0.32, 0.32, -0.81), 0.63},
}

-- Bounded planting tendencies: baseline, squat/wide, tall, left-heavy,
-- right-heavy, compact. Ordinary consecutive seeds expose all six silhouettes.
local TENDENCIES = {
	{1, 1, 0, {1, 1, 1}, {1, 1, 1}},
	{1.11, 0.86, -0.02, {1.04, 0.98, 0.94}, {1.06, 0.94, 0.93}},
	{0.89, 1.16, 0.02, {0.98, 1.04, 1.08}, {0.94, 1.03, 1.07}},
	{1.02, 0.98, -0.08, {1.14, 0.85, 0.96}, {1.08, 0.88, 1.02}},
	{1.02, 1.04, 0.08, {0.85, 1.14, 1.04}, {0.88, 1.08, 0.95}},
	{0.91, 0.91, -0.04, {1.07, 0.96, 0.84}, {1.03, 0.96, 0.88}},
}

-- Fixed topology: initialize names and stud variants even for hidden pieces.
local PART_METADATA = {}
local function metadata(name, variant)
	table.insert(PART_METADATA, { name, variant or "StudsSmall" })
end
metadata("Stem")
metadata("Stem")
for _ = 1, 3 do
	metadata("Stem")
	metadata("Stem")
	for _ = 1, 3 do
		metadata("Leaf", "Studs")
		metadata("LeafTip")
	end
	for _, name in {"Stem", "Sepal", "Sepal", "Shoulder", "Tomato", "Cheek", "Cheek", "Base"} do
		metadata(name)
	end
end
for _ = 1, 2 do
	metadata("Leaf", "Studs")
	metadata("LeafTip")
end
assert(#PART_METADATA == 54, "Tomato metadata budget changed")

local function phase(g, first, last)
	local t = math.clamp((g - first) / (last - first), 0, 1)
	return t * t * (3 - 2 * t)
end

local function axis(a, b)
	local delta = b - a
	if delta.Magnitude < 0.00001 then
		return CFrame.new(a)
	end
	local up = if math.abs(delta.Unit.Y) > 0.98 then Vector3.xAxis else Vector3.yAxis
	return CFrame.lookAt((a + b) / 2, a, up)
end

local function massScale(sizeFactor)
	local factor = sizeFactor or 1
	assert(type(factor) == "number" and factor > 0 and factor < math.huge, "Invalid plant size factor")
	return factor ^ (1 / 3)
end

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

function TomatoPlant.new(parent, soilCFrame, seed, sizeFactor)
	local self = setmetatable({}, TomatoPlant)
	self.model = Instance.new("Model")
	self.model.Name = "TomatoPlant"
	self.base = soilCFrame
	self.scale = massScale(sizeFactor)
	self.horizontalFit = 1
	self.parts = {}
	self.applied = {}
	local random = Random.new(seed or 1)
	-- Seed one preserves the approved A; the others retain its separated fruit.
	local amount = if (seed or 1) == 1 then 0 else 1
	local tendency = TENDENCIES[(math.floor(seed or 1) - 1) % #TENDENCIES + 1]
	self.spread = tendency[1] + random:NextNumber(-0.012, 0.012) * amount
	self.height = tendency[2] + random:NextNumber(-0.012, 0.012) * amount
	self.lean = tendency[3] + random:NextNumber(-0.012, 0.012) * amount
	self.armLengths, self.fruitSizes, self.armHeights, self.leafTurns = {}, {}, {}, {}
	self.timing = {}
	for i = 1, 3 do
		self.armLengths[i] = tendency[4][i] + random:NextNumber(-0.10, 0.10) * amount
		self.fruitSizes[i] = tendency[5][i] + random:NextNumber(-0.13, 0.13) * amount
		self.armHeights[i] = random:NextNumber(-0.16, 0.16) * amount
		self.leafTurns[i] = CFrame.Angles(0, random:NextNumber(-0.22, 0.22) * amount, 0)
		self.timing[i] = random:NextNumber(-0.018, 0.018) * amount
	end
	for i = 1, 54 do
		local part = Instance.new("Part")
		part.Name, part.MaterialVariant = PART_METADATA[i][1], PART_METADATA[i][2]
		part.Material = Enum.Material.Plastic
		part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
		part.Transparency = 1
		part.Parent = self.model
		self.parts[i] = part
		self.applied[i] = { visible = false }
	end
	-- Fit off the DataModel before revealing the plant. Check the opening poses as
	-- well as ripe leaves; only horizontal spread/foliage is constrained.
	for _ = 1, 16 do
		local radius = 0
		for _, growth in {0.2, 0.5, 0.75, 1} do
			self:SetGrowth(growth)
			radius = math.max(radius, radiusOf(self.parts, soilCFrame))
		end
		if radius <= 2.4 then break end
		self.horizontalFit *= math.min(0.90, 2.35 / radius)
		self.growth = nil
	end
	self:SetGrowth(0)
	self.model.Parent = parent
	return self
end

function TomatoPlant:SetGrowth(normalized)
	assert(not self.destroyed, "TomatoPlant has been destroyed")
	assert(type(normalized) == "number" and normalized == normalized, "Growth must be a number")
	local g = math.clamp(normalized, 0, 1)
	if self.growth == g then return end
	self.growth = g
	local cursor = 0
	local base = self.base
	local function point(p)
		return V((p.X * self.spread + p.Y * self.lean) * self.horizontalFit, p.Y * self.height, p.Z * self.spread * self.horizontalFit)
	end
	local function hide(count)
		for _ = 1, count do
			cursor += 1
			local applied = self.applied[cursor]
			if applied.visible then
				self.parts[cursor].Transparency = 1
				applied.visible = false
			end
		end
	end
	local function block(_name, size, cf, color, _variant, visible)
		if not visible then
			hide(1)
			return
		end
		cursor += 1
		local part = self.parts[cursor]
		local applied = self.applied[cursor]
		local scaled = size * self.scale
		local actualSize = V(math.max(scaled.X, 0.001), math.max(scaled.Y, 0.001), math.max(scaled.Z, 0.001))
		local world = base * CFrame.new(cf.Position * self.scale) * cf.Rotation
		if applied.size ~= actualSize then
			part.Size = actualSize
			applied.size = actualSize
		end
		if applied.cf ~= world then
			part.CFrame = world
			applied.cf = world
		end
		if applied.color ~= color then
			part.Color = color
			applied.color = color
		end
		if not applied.visible then
			part.Transparency = 0
			applied.visible = true
		end
	end
	local function twig(a, b, width, visible)
		if not visible then
			hide(1)
			return
		end
		block("Stem", V(width, width, (b - a).Magnitude), axis(a, b), STEM, "StudsSmall", visible)
	end
	local function opened(offset, opening)
		-- Keep a small horizontal component while tucked; its fixed hinge axis
		-- avoids the lookAt up-vector switch near a vertical leaf.
		return offset.Unit:Lerp(Vector3.yAxis, (1 - opening) * 0.94).Unit * offset.Magnitude
	end
	local function leaf(at, offset, width, color, scale, opening)
		if scale <= 0 then
			hide(2)
			return
		end
		width *= self.horizontalFit
		local direction = opened(offset, opening or scale)
		local blade = direction * scale
		local length = blade.Magnitude
		local right = Vector3.yAxis:Cross(offset).Unit
		local back = direction.Unit
		local cf = CFrame.fromMatrix(at + blade / 2, right, back:Cross(right), back)
		block("Leaf", V(width * scale, 0.14 * scale, length * 0.72), cf * CFrame.new(0, 0, -length * 0.14), color, "Studs", scale > 0)
		block("LeafTip", V(width * scale * 0.56, 0.13 * scale, length * 0.28), cf * CFrame.new(0, 0, length * 0.36), color, "StudsSmall", scale > 0)
	end
	local function fruit(at, size, scale, color)
		if scale <= 0 then
			hide(8)
			return
		end
		local s = size * scale
		local stalkEnd = at - V(0, 0.22 * scale, 0)
		twig(at, stalkEnd, 0.10 * scale, scale > 0)
		local top = CFrame.new(stalkEnd)
		block("Sepal", V(s * 0.57, 0.09 * scale, 0.14 * scale), top, DARK, "StudsSmall", scale > 0)
		block("Sepal", V(0.15 * scale, 0.10 * scale, s * 0.56), top, DARK, "StudsSmall", scale > 0)
		block("Shoulder", V(s * 0.74, s * 0.17, s * 0.70), top * CFrame.new(0, -s * 0.085, 0), color, "StudsSmall", scale > 0)
		block("Tomato", V(s, s * 0.55, s * 0.66), top * CFrame.new(0, -s * 0.445, 0), color, "StudsSmall", scale > 0)
		for _, side in {-1, 1} do
			block("Cheek", V(s * 0.74, s * 0.47, s * 0.14), top * CFrame.new(0, -s * 0.44, side * s * 0.40), color, "StudsSmall", scale > 0)
		end
		block("Base", V(s * 0.72, s * 0.16, s * 0.64), top * CFrame.new(0, -s * 0.80, 0), color, "StudsSmall", scale > 0)
	end

	local stemGrowth = phase(g, 0, 0.58)
	local joint = point(V(-0.06, 0.83, 0)) * (0.10 + 0.90 * stemGrowth)
	local crown = joint + point(V(0.24, 0.85, -0.18)) * phase(g, 0.10, 0.63)
	twig(V(0, 0, 0), joint, 0.07 + 0.12 * stemGrowth, true)
	twig(joint, crown, 0.17 * stemGrowth, g > 0.10)
	for i, arm in ARMS do
		local delay = self.timing[i]
		local extension = phase(g, 0.22 + delay + (i - 1) * 0.035, 0.59 + delay)
		local bend = phase(g, 0.66, 1)
		local fork = joint:Lerp(crown, (i - 1) * 0.27)
		local armLength = self.armLengths[i]
		local finalFork = V(-0.06, 0.83, 0):Lerp(V(0.18, 1.68, -0.18), (i - 1) * 0.27)
		local raisedElbow = finalFork + (arm[1] - finalFork) * armLength + V(0, self.armHeights[i] + 0.16 * (1 - bend), 0)
		local elbow = fork:Lerp(point(raisedElbow), extension)
		local endPoint = elbow + point((arm[2] - arm[1]) * armLength + V(0, 0.26 * (1 - bend), 0)) * extension
		local fruitSize = arm[4] * self.fruitSizes[i]
		local fruitScale = phase(g, 0.60 + delay, 1)
		-- The heaviest fruit stays above soil on a short seeded bush.
		local minimumY = (0.22 + fruitSize * 0.88) * fruitScale + 0.04
		endPoint = V(endPoint.X, math.max(endPoint.Y, minimumY), endPoint.Z)
		twig(fork, elbow, 0.14 * extension, extension > 0)
		twig(elbow, endPoint, 0.12 * extension, extension > 0)
		local blade = point(self.leafTurns[i]:VectorToWorldSpace(arm[3])) * (0.88 + armLength * 0.12)
		local leafScale = phase(g, 0.28 + delay + (i - 1) * 0.035, 0.70 + delay)
		local leafColor = if i % 2 == 1 then DARK else LIT
		leaf(elbow, blade * 1.18, 0.60, leafColor, leafScale)
		local side = Vector3.yAxis:Cross(blade).Unit
		local leafJoint = elbow + opened(blade, leafScale) * 0.32 * leafScale
		local smallScale = leafScale * phase(g, 0.38 + delay, 0.79 + delay)
		leaf(leafJoint, blade * 0.46 + side * 0.52 * self.horizontalFit + V(0, -0.12, 0), 0.37, leafColor, smallScale)
		leaf(leafJoint, blade * 0.53 - side * 0.46 * self.horizontalFit + V(0, 0.10, 0), 0.37, LIT, smallScale)
		local ripeColor = if i == 2 then RIPE_RED else RED
		local color = if g == 1 then ripeColor else GREEN:Lerp(ripeColor, phase(g, 0.79, 1))
		fruit(endPoint, fruitSize, fruitScale, color)
	end
	local leftScale = phase(g, 0.025, 0.23)
	local rightScale = phase(g, 0.055, 0.26)
	leaf(crown, point(V(-0.78, 0.25, 0.35)), 0.48, LIT, leftScale, phase(g, 0.035, 0.29))
	leaf(crown, point(V(0.57, 0.34, -0.51)), 0.41, NEW, rightScale, phase(g, 0.075, 0.34))
	assert(cursor == 54, "Tomato part budget changed")
end

function TomatoPlant:Destroy()
	if self.destroyed then return end
	self.destroyed = true
	self.model:Destroy()
	self.parts = {}
	self.applied = {}
end

TomatoPlant.RingHeight = 2.65

function TomatoPlant.BuildProxy(parent: Instance, soil: CFrame, stage: number, seed: number?, sizeFactor: number?)
	if stage <= 0 then return end
	local scale = massScale(sizeFactor)
	local random = Random.new(seed or 1)
	local amount = if (seed or 1) == 1 then 0 else 1
	local tendency = TENDENCIES[(math.floor(seed or 1) - 1) % #TENDENCIES + 1]
	local width = (if stage == 1 then 1.4 elseif stage == 2 then 2.7 else 3.6) * tendency[1]
	local height = (if stage == 1 then 0.70 elseif stage == 2 then 1.25 else 1.65) * tendency[2]
	local pieces = {
		{"Canopy", V(width, 0.5, width * 0.58), V(tendency[3], height - 0.25, -0.10), LIT, "Studs"},
	}
	if stage >= 3 then
		for i, side in {-1, 1} do
			local fruitScale = tendency[5][i] + random:NextNumber(-0.13, 0.13) * amount
			table.insert(pieces, {"Tomato", V(0.85, 0.7, 0.8) * fruitScale, V(side * 1.12 * tendency[4][i], 0.60 * tendency[2], 0.35), Color3.fromRGB(225, 55, 45), "StudsSmall"})
		end
	end
	local radius = 0
	for _, piece in pieces do
		local size, at = piece[2] * scale, piece[3] * scale
		radius = math.max(radius, V(math.abs(at.X) + size.X / 2, 0, math.abs(at.Z) + size.Z / 2).Magnitude)
	end
	local fit = math.min(1, 2.4 / radius)
	local function block(name, size, offset, color, variant)
		local part = Instance.new("Part")
		local dimensions = V(size.X * fit, size.Y, size.Z * fit) * scale
		local at = V(offset.X * fit, offset.Y, offset.Z * fit) * scale
		part.Name, part.Size, part.CFrame, part.Color = name, dimensions, soil * CFrame.new(at), color
		part.Material, part.MaterialVariant = Enum.Material.Plastic, variant
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery, part.CastShadow = true, false, false, false, false
		part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		part.Parent = parent
	end
	for _, piece in pieces do
		block(table.unpack(piece))
	end
end

return TomatoPlant
