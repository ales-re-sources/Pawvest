-- Potato art recipe, deliberately unregistered until the motion review passes.
-- Fixed topology: 42 foliage + 6 tuber + 3 stalk + 12 flower + 2 berry = 65 parts.
-- Growth is normalized (the review runner supplies a ten-second timeline).
local PotatoPlant = {}
PotatoPlant.__index = PotatoPlant
local V = Vector3.new
local GREEN = Color3.fromRGB(61, 132, 60)
local LIGHT = Color3.fromRGB(91, 157, 67)
local STEM = Color3.fromRGB(80, 119, 54)
local TAN = Color3.fromRGB(173, 133, 83)
local CREAM = Color3.fromRGB(245, 242, 220)
local YELLOW = Color3.fromRGB(234, 184, 45)
local TOPS = {V(-0.54, 1.98, -0.15), V(0.51, 2.13, -0.20), V(0.05, 1.90, 0.54)}
-- Baseline, squat/wide, tall/slender, left leaning, right leaning, compact.
local VARIATIONS = {
	{1, 1, 0},
	{1.08, 0.92, -0.02},
	{0.94, 1.08, 0.01},
	{1, 0.98, -0.08},
	{1, 1.02, 0.08},
	{0.92, 0.94, -0.03},
}
local META = {}
local function metadata(name, variant)
	table.insert(META, {name, variant or "StudsSmall"})
end
for _ = 1, 3 do
	metadata("Stem")
	metadata("Stem")
	for _ = 1, 2 do
		metadata("CompoundStalk")
		for _ = 1, 2 do
			metadata("LeafFold", "Studs")
			metadata("LeafTip")
		end
	end
	metadata("LeafFold", "Studs")
	metadata("LeafTip")
end
for _ = 1, 2 do
	metadata("TuberBuriedSides")
	metadata("TuberRoundedEnds")
	metadata("TuberCrown")
end
metadata("FlowerStalk")
metadata("FlowerStalk")
for _ = 1, 5 do
	metadata("FlowerPetal")
end
metadata("FlowerYellowCone")
metadata("FlowerStalk")
for _ = 1, 5 do
	metadata("FlowerPetal")
end
metadata("FlowerYellowCone")
metadata("DecorativeGreenBerry")
metadata("DecorativeGreenBerry")
assert(#META == 65, "Potato metadata budget changed")
local function phase(g, a, b)
	local t = math.clamp((g - a) / (b - a), 0, 1)
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

function PotatoPlant.new(parent, soilCFrame, seed)
	local self = setmetatable({}, PotatoPlant)
	self.model = Instance.new("Model")
	self.model.Name = "PotatoPlant"
	self.base = soilCFrame
	self.parts, self.applied = {}, {}
	local variation = VARIATIONS[(math.floor(seed or 1) - 1) % #VARIATIONS + 1]
	local random = Random.new(seed or 1)
	local amount = if (seed or 1) == 1 then 0 else 1
	self.spread = variation[1] + random:NextNumber(-0.012, 0.012) * amount
	self.height = variation[2] + random:NextNumber(-0.012, 0.012) * amount
	self.lean = variation[3] + random:NextNumber(-0.012, 0.012) * amount
	for i, meta in META do
		local part = Instance.new("Part")
		part.Name, part.MaterialVariant = meta[1], meta[2]
		part.Material = Enum.Material.Plastic
		if meta[1] == "DecorativeGreenBerry" then
			part.Shape = Enum.PartType.Ball
		end
		part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
		part.Transparency = 1
		part.Parent = self.model
		self.parts[i] = part
		self.applied[i] = {visible = false}
	end
	self:SetGrowth(0)
	self.model.Parent = parent
	return self
end

function PotatoPlant:SetGrowth(normalized)
	assert(not self.destroyed, "PotatoPlant has been destroyed")
	assert(type(normalized) == "number" and normalized == normalized, "Growth must be a number")
	local g = math.clamp(normalized, 0, 1)
	if self.growth == g then
		return
	end
	self.growth = g
	local cursor = 0
	local function point(p)
		return V(p.X * self.spread + p.Y * self.lean, p.Y * self.height, p.Z * self.spread)
	end
	local function hide(count)
		for _ = 1, count do
			cursor += 1
			local state = self.applied[cursor]
			if state.visible then
				self.parts[cursor].Transparency = 1
				state.visible = false
			end
		end
	end
	local function block(size, cf, color, visible)
		if not visible then
			hide(1)
			return
		end
		cursor += 1
		local part, state = self.parts[cursor], self.applied[cursor]
		local actual = V(math.max(size.X, 0.001), math.max(size.Y, 0.001), math.max(size.Z, 0.001))
		local world = self.base * cf
		if state.size ~= actual then
			part.Size = actual
			state.size = actual
		end
		if state.cf ~= world then
			part.CFrame = world
			state.cf = world
		end
		if state.color ~= color then
			part.Color = color
			state.color = color
		end
		if not state.visible then
			part.Transparency = 0
			state.visible = true
		end
	end
	local function twig(a, b, width, visible)
		if not visible then
			hide(1)
			return
		end
		block(V(width, width, (b - a).Magnitude), axis(a, b), STEM, true)
	end
	local function blade(at, offset, width, color, scale)
		if scale <= 0 then
			hide(2)
			return
		end
		-- Leaves unfold from their own attachment rather than sliding into place.
		local direction = offset.Unit:Lerp(Vector3.yAxis, (1 - scale) * 0.88).Unit * offset.Magnitude * scale
		local crease = at + direction * 0.60 + V(0, 0.12 * scale, 0)
		local tip = at + direction
		-- Both folds retain the mature blade's hinge while unfolding near vertical.
		-- Using axis() here would switch its up vector and abruptly roll the leaf.
		local right = Vector3.yAxis:Cross(offset).Unit
		local function segmentFrame(a, b)
			local back = (b - a).Unit
			return CFrame.fromMatrix((a + b) / 2, right, back:Cross(right), back)
		end
		block(V(width * scale, 0.14 * scale, (crease - at).Magnitude), segmentFrame(at, crease), color, true)
		block(V(width * 0.62 * scale, 0.13 * scale, (tip - crease).Magnitude), segmentFrame(crease, tip), color, true)
	end
	local tops = {}
	for i, finalTop in TOPS do
		local extension = if i == 1 then 0.055 + 0.945 * phase(g, 0, 0.53) else phase(g, 0.17 + (i - 2) * 0.04, 0.57)
		local origin = point(V((i - 2) * 0.08, 0.08, 0)) * extension
		local top = point(finalTop) * extension
		tops[i] = top
		local elbowOffset = V(if i % 2 == 0 then -0.08 else 0.08, 0, 0.07)
		local finalOrigin = V((i - 2) * 0.08, 0.08, 0)
		local elbow = point(finalOrigin:Lerp(finalTop, 0.52) + elbowOffset) * extension
		twig(origin, elbow, 0.12 * (0.35 + 0.65 * extension), extension > 0)
		twig(elbow, top, 0.12 * (0.35 + 0.65 * extension), extension > 0)
		local outward = V(finalTop.X, 0, finalTop.Z).Unit
		for tier, fraction in {0.38, 0.77} do
			local node = if fraction <= 0.52 then origin:Lerp(elbow, fraction / 0.52) else elbow:Lerp(top, (fraction - 0.52) / 0.48)
			local angle = (tier - 1) * 0.72 + (i - 1) * 0.18
			local radial = CFrame.Angles(0, angle, 0):VectorToWorldSpace(outward)
			local side = V(-radial.Z, 0, radial.X)
			local scale
			if i == 1 and tier == 1 then
				scale = phase(g, 0.025, 0.23)
			else
				local start = 0.22 + (i - 1) * 0.025 + (tier - 1) * 0.04
				local finish = 0.61 + (tier - 1) * 0.05
				scale = phase(g, start, finish)
			end
			local branchEnd = node + point(radial * 0.46 + V(0, 0.09, 0)) * scale
			twig(node, branchEnd, 0.12 * scale, scale > 0)
			local leafScale = 1.30 * (if tier == 1 then 1 else 0.91)
			local secondScale = if i == 1 and tier == 1 then phase(g, 0.055, 0.26) else scale
			blade(branchEnd, point((radial * 0.48 + side * 0.70 + V(0, 0.10, 0)) * leafScale), 0.46 * leafScale, GREEN, scale)
			blade(branchEnd, point((radial * 0.48 - side * 0.70 + V(0, 0.04, 0)) * leafScale), 0.43 * leafScale, LIGHT, secondScale)
		end
		blade(top, point(outward * 0.39 + V(0, 0.20, 0)), 0.33, LIGHT, phase(g, 0.31 + (i - 1) * 0.025, 0.65))
	end
	local tuberScale = phase(g, 0.70, 1)
	for i, at in {V(-0.57, 0, 0.46), V(0.55, 0, 0.60)} do
		if tuberScale <= 0 then
			hide(3)
		else
			local cf = CFrame.new(point(at) + V(0, -0.28 * (1 - tuberScale), 0)) * CFrame.Angles(0, i * 0.60, 0)
			local size = 0.55 + 0.45 * tuberScale
			block(V(0.73, 0.34, 0.45) * size, cf * CFrame.new(0, -0.08 * size, 0), TAN, true)
			block(V(0.53, 0.33, 0.62) * size, cf * CFrame.new(0, -0.08 * size, 0), TAN, true)
			block(V(0.44, 0.14, 0.35) * size, cf * CFrame.new(0, 0.13 * size, 0), TAN, true)
		end
	end
	local bloom = phase(g, 0.60, 0.80)
	local late = phase(g, 0.85, 1)
	local fork = tops[2] + point(V(0, 0.20, 0.09)) * bloom
	twig(tops[2], fork, 0.12 * bloom, bloom > 0)
	local function flower(at, turn, scale)
		if scale <= 0 then
			hide(6)
			return
		end
		local face = CFrame.lookAt(at, at + V(0, 0.55, 0.84).Unit) * CFrame.Angles(0, 0, turn)
		for petal = 1, 5 do
			local angle = (petal - 1) * math.pi * 2 / 5
			local cf = face * CFrame.Angles(0, 0, angle) * CFrame.new(0, 0.105 * scale, 0)
			block(V(0.125, 0.17, 0.065) * scale, cf, CREAM, true)
		end
		block(V(0.095, 0.11, 0.105) * scale, face * CFrame.new(0, 0, -0.067 * scale), YELLOW, true)
	end
	local left = fork + point(V(-0.18, 0.13, 0.04)) * bloom
	twig(fork, left, 0.12 * bloom, bloom > 0)
	flower(left, 0.16, bloom)
	local rightOffset = V(0.17, 0.07, -0.02):Lerp(V(-0.70, -0.35, 0.90), late)
	local right = fork + point(rightOffset) * bloom
	twig(fork, right, 0.12 * bloom, bloom > 0)
	flower(right, -0.25, bloom * (1 - late))
	-- These are small, decorative non-edible berries; the underground tubers
	-- remain the harvest crop. Berry tops touch the shared upper side stalk.
	block(V(0.29, 0.30, 0.29) * late, CFrame.new(right + point(V(-0.11, -0.10, 0)) * late), Color3.fromRGB(132, 169, 70), late > 0)
	block(V(0.27, 0.28, 0.27) * late, CFrame.new(right + point(V(0.18, -0.13, 0.04)) * late), Color3.fromRGB(117, 155, 62), late > 0)
	assert(cursor == 65, "Potato part budget changed")
end

function PotatoPlant:Destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true
	self.model:Destroy()
	self.parts, self.applied = {}, {}
end

PotatoPlant.RingHeight = 2.95

return PotatoPlant
