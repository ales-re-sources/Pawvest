-- CG14: leafy brassica with one late, tightly budded crown (docs/plants/BROCCOLI.md).
-- 1 stalk + 2 cotyledons + 6 seven-Part leaves + 7 nine-Part floret groups = 108 Parts, built once.
local BroccoliPlant = {}
BroccoliPlant.__index = BroccoliPlant
BroccoliPlant.RingHeight = 5.6
BroccoliPlant.FixedRingHeight = true
BroccoliPlant.ReviewHeight = 5.2

local Kit = require(script.Parent.PlantKit)
local phase, V, C = Kit.phase, Vector3.new, Color3.fromRGB
local STALK, RIB, YOUNG = C(132, 177, 93), C(163, 194, 131), C(136, 184, 100)
local LEAF, LEAF_B = C(56, 119, 96), C(72, 136, 105)
local CROWN, BUD, LIGHT = C(42, 100, 57), C(60, 131, 66), C(83, 149, 73)
local STARTS = {0.025, 0.07, 0.16, 0.23, 0.30, 0.36}
local YAWS = {0.30, 2.40, 4.20, 1.40, 3.50, 5.30}
local FRACS, WIDTHS = {0.28, 0.43, 0.29}, {0.55, 1, 0.58}
local BUDS = {V(0, 0.39, 0)}
for i = 1, 6 do
	local angle = (i - 1) * math.pi / 3
	table.insert(BUDS, V(math.sin(angle) * 0.29, 0.23 + (i % 3) * 0.035, math.cos(angle) * 0.29))
end

local function shape(seed, sizeFactor)
	local vary, ds = Kit.seeded(seed), Kit.dimension(sizeFactor)
	local s = {leaves = {}, florets = {}}
	s.vigor = math.clamp(1 + (ds - 1) * 0.22, 0.92, 1.10)
	s.headScale = ds * (1 + vary(0.06))
	s.lean = V(vary(0.08), 0, vary(0.08))
	for i = 1, 6 do
		s.leaves[i] = {
			yaw = YAWS[i] + vary(0.28),
			length = (3.20 - (i - 1) * 0.060) * s.vigor * (1 + vary(0.10)),
			width = (1.48 - (i - 1) * 0.025) * s.vigor * (1 + vary(0.10)),
			elev = 1.27 + i * 0.012 + vary(0.04) + math.max(0, s.vigor - 1) * 1.2,
			start = STARTS[i] + vary(0.012),
		}
	end
	for i = 1, 7 do
		s.florets[i] = {
			yaw = (i - 2) * math.pi / 3 + vary(0.12),
			width = 1 + vary(0.11), height = 1 + vary(0.10),
		}
	end
	-- Append future variation draws here to preserve planting identity.
	return s
end

local function geometry(s, g, emit, proxy)
	local extension = phase(g, 0, 0.78)
	local height = (0.13 + 2.22 * extension) * s.vigor
	local tip = V(s.lean.X * height, height, s.lean.Z * height)
	local width = 0.055 + 0.42 * phase(g, 0.12, 0.95)
	emit("Stalk", V(width, width, tip.Magnitude + 0.025), Kit.axis(V(0, 0, 0), tip), STALK, 1, "Structure")
	for i = 1, 2 do
		local yaw = (i - 1) * math.pi + 0.35
		local q = 0.6 + 0.4 * phase(g, 0, 0.10)
		local at = tip * 0.80 + V(math.sin(yaw), 0, math.cos(yaw)) * 0.16 * q
		emit("Cotyledon_" .. i, V(0.16, 0.045, 0.29) * q,
			CFrame.new(at) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(-0.25, 0, 0), YOUNG,
			1 - phase(g, 0.22, 0.45), "Foliage")
	end
	for i, f in s.leaves do
		if proxy and i % 2 == 0 then continue end
		local q = phase(g, f.start, f.start + 0.31)
		local opacity = phase(q, 0, 0.06)
		local out = V(math.sin(f.yaw), 0, math.cos(f.yaw))
		local side = V(math.cos(f.yaw), 0, -math.sin(f.yaw))
		local node = tip * (0.14 + (i - 1) * 0.065)
		local elev = 1.40 + (f.elev - 1.40) * q
		local petioleEnd = node + (out * 0.58 + Vector3.yAxis * 0.18) * s.vigor * q
		emit("Petiole_" .. i, V(0.075, 0.075, (petioleEnd - node).Magnitude + 0.025),
			Kit.axis(node, petioleEnd), STALK, opacity, "Foliage")
		local pos, frames, lengths = petioleEnd, {}, {}
		for j = 1, 3 do
			local a = pos
			-- Long brassica blades rise beside the crown; a shallow bend keeps their tips inside the square.
			local angle = elev - (j - 1) * 0.12 * q
			local dir = out * math.cos(angle) + Vector3.yAxis * math.sin(angle)
			local len = f.length * FRACS[j] * q
			pos += dir * len
			local cf = CFrame.fromMatrix((a + pos) / 2, side, dir:Cross(side), dir)
			frames[j], lengths[j] = cf, len
			emit("Blade_" .. i .. "_" .. j, V(f.width * WIDTHS[j] * q, 0.065, len + 0.025), cf,
				YOUNG:Lerp(if i % 2 == 0 then LEAF else LEAF_B, phase(g, 0.08, 0.54)), opacity, "Foliage")
		end
		if not proxy then
			for j, sign in {-1, 1} do
				emit("Lobe_" .. i .. "_" .. j, V(f.width * 0.35 * q, 0.06, lengths[2] * 0.73 + 0.015),
					frames[2] * CFrame.new(sign * f.width * 0.45 * q, 0.015, lengths[2] * 0.13)
						* CFrame.Angles(0, sign * 0.25, sign * 0.18), LEAF_B, opacity, "Foliage")
			end
			emit("Rib_" .. i, V(0.035, 0.018, lengths[2] + 0.015), frames[2] * CFrame.new(0, 0.040, 0),
				RIB, opacity, "Foliage")
		end
	end
	local h = phase(g, 0.47, 1)
	local hs = s.headScale * h
	for i, f in s.florets do
		local ring = if i == 1 then 0 else 0.66
		local center = tip + V(math.sin(f.yaw) * ring, if i == 1 then 0.64 else 0.27, math.cos(f.yaw) * ring) * hs
		local branchBase = tip - V(0, 0.24 * h, 0)
		local branchEnd = center - V(0, 0.11 * hs, 0)
		local opacity = phase(h, 0, 0.06)
		emit("Branch_" .. i, V(0.19 * hs, 0.19 * hs, (branchEnd - branchBase).Magnitude + 0.025),
			Kit.axis(branchBase, branchEnd), STALK, opacity, "Structure")
		local cf = CFrame.new(center) * CFrame.Angles(0, f.yaw, 0)
		emit("Floret_" .. i, V(0.86 * f.width, 0.48 * f.height, 0.84) * hs, cf,
			CROWN, opacity, "Crown")
		if not proxy then
			for j, offset in BUDS do
				local budScale = (if j == 1 then 1.05 else 1) * hs
				emit("Bud_" .. i .. "_" .. j, V(0.36 * f.width, 0.33 * f.height, 0.36) * budScale,
					cf * CFrame.new(offset * V(f.width, f.height, 1) * hs) * CFrame.Angles(0, (j % 3 - 1) * 0.16, 0),
					if (i + j) % 3 == 0 then LIGHT else BUD, opacity, "Crown")
			end
		end
	end
end

function BroccoliPlant.new(parent, soilCFrame, seed, sizeFactor)
	local self = setmetatable(shape(seed, sizeFactor), BroccoliPlant)
	self.rig = Kit.newRig("BroccoliPlant", soilCFrame)
	self.model = self.rig.model
	geometry(self, 1, function(name, _, _, _, _, role) self.rig:add(name, nil, role) end)
	assert(#self.rig.parts == 108, "Broccoli topology changed")
	self:SetGrowth(0)
	self.model.Parent = parent
	return self
end

function BroccoliPlant:SetGrowth(normalized)
	local g = self.rig:beginPose(normalized)
	if not g then return end
	geometry(self, g, function(_, size, cf, color, opacity) self.rig:block(size, cf, color, opacity) end)
	self.rig:finish()
end

function BroccoliPlant:Destroy()
	self.rig:destroy()
end

-- Direct-built silhouette: three broad three-plate leaves and seven joined crown lobes; no tiny bud blocks.
function BroccoliPlant.BuildProxy(parent, soilCFrame, stage, seed, sizeFactor)
	local s = shape(seed, sizeFactor)
	local g = if stage <= 1 then 0.20 elseif stage == 2 then 0.60 else 1
	geometry(s, g, function(name, size, cf, color, opacity, role)
		if opacity <= 0.01 then return end
		local part = Kit.proxyPart(parent, name, size, soilCFrame * cf, color, nil, role)
		part.Transparency = 1 - opacity
	end, true)
end

return BroccoliPlant
