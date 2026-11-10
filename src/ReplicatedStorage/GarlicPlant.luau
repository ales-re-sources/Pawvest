-- CG12b: selected A, wrapped ivory head, alternating flat leaves and one curled hardneck scape.
-- 21 head/neck/stem + 21 blade + 10 scape + 2 spathe Parts = 54, built once (docs/plants/GARLIC.md).
local GarlicPlant = {}
GarlicPlant.__index = GarlicPlant
GarlicPlant.RingHeight = 5.5
GarlicPlant.FixedRingHeight = true
GarlicPlant.ReviewHeight = 5.0

local Kit = require(script.Parent.PlantKit)
local phase, V, C = Kit.phase, Vector3.new, Color3.fromRGB
local IVORY, CREAM, SHADE = C(237, 230, 208), C(248, 242, 218), C(193, 180, 192)
local SHEATH, GREEN, GREEN_B, STRAW = C(198, 214, 165), C(68, 127, 103), C(90, 151, 114), C(202, 185, 116)
local YOUNG = C(142, 184, 115)
local LENGTHS = {1.85, 2.05, 2.30, 2.40, 2.30, 2.20, 2.15}
local STARTS = {0, 0.05, 0.13, 0.25, 0.35, 0.43, 0.51}
local FRACS, WIDTHS = {0.38, 0.38, 0.24}, {0.28, 0.40, 0.14}
-- A connected side curl and rising tail; coordinates relative to the scape's mature base at 0.9 studs.
local PATH = {
	V(-0.10, 1.60, 0.02), V(-0.30, 2.50, 0.04), V(-0.78, 2.62, 0.04),
	V(-1.12, 2.34, 0.04), V(-1.12, 1.95, 0.04), V(-0.80, 1.72, 0.04),
	V(-0.42, 1.83, 0.04), V(-0.24, 2.19, 0.04), V(0.02, 2.87, 0.04), V(0.28, 3.34, 0.04),
}

local function shape(seed, sizeFactor)
	local vary, ds = Kit.seeded(seed), Kit.dimension(sizeFactor)
	local s = {dimension = ds, leaves = {}}
	s.vigor = math.clamp(1 + (ds - 1) * 0.25, 0.90, 1.12)
	s.bulbWidth = ds * (1 + vary(0.06))
	s.bulbHeight = ds * (1 + vary(0.06))
	for i, length in LENGTHS do
		s.leaves[i] = {
			length = length * s.vigor * (1 + vary(0.12)),
			yaw = (if i % 2 == 0 then math.pi else 0) + 0.45 + ((i % 3) - 1) * 0.35 + vary(0.22),
			lean = 0.25 + (7 - i) * 0.08 + vary(0.07),
			start = math.max(0, STARTS[i] + vary(0.018)),
			width = 1 + vary(0.10),
		}
	end
	-- Append new variation draws here so existing plantings keep their structural identity.
	s.curlWidth = 1 + vary(0.14)
	s.scapeHeight = s.vigor * (1 + vary(0.06))
	s.scapeYaw = vary(0.40)
	s.stemLean = vary(0.10)
	return s
end

local function state(s, g)
	local swell = phase(g, 0.30, 0.94)
	local scale = 0.18 + 0.82 * swell
	local offset = -0.20 * (1 - swell) * s.bulbHeight
	local bottom = math.max(0.015, 0.65 * scale * s.bulbHeight + offset)
	return {swell = swell, scale = scale, offset = offset, bottom = bottom,
		stemHeight = (0.07 + 1.50 * phase(g, 0.04, 0.72)) * s.vigor}
end

local function geometry(s, g, emit, proxy)
	local st = state(s, g)
	local wx, hy = st.scale * s.bulbWidth, st.scale * s.bulbHeight
	local function bulb(name, size, cf, color)
		local p = cf.Position
		local scaled = V(p.X * wx, p.Y * hy + st.offset, p.Z * wx)
		emit(name, size * V(wx, hy, wx), CFrame.new(scaled) * cf.Rotation,
			SHEATH:Lerp(color, phase(g, 0.35, 0.85)), 1, "Bulb")
	end
	bulb("WrappedCore", V(0.95, 1.0, 0.95), CFrame.new(0, -0.15, 0), IVORY)
	for i = 1, 6 do
		local lobe = CFrame.Angles(0, (i - 1) * math.pi / 3 + 0.15, 0)
		-- Early lobes overlap beneath one wrapper; their vertical ribs separate as the head fills out.
		local spread = 0.6 + 0.4 * phase(g, 0.45, 0.88)
		if not proxy then
			bulb("LobeBase_" .. i, V(0.52, 0.48, 0.55), lobe * CFrame.new(0, -0.37, 0.44 * spread), IVORY)
			bulb("LobeBody_" .. i, V(0.58, 0.58, 0.60), lobe * CFrame.new(0, -0.01, 0.50 * spread),
				if i % 3 == 0 then SHADE:Lerp(IVORY, 0.60) else IVORY)
		end
		if not proxy or i % 2 == 1 then
			bulb("LobeShoulder_" .. i, V(0.44, 0.55, 0.44), lobe * CFrame.new(0, 0.32, 0.35 * spread) * CFrame.Angles(-0.35, 0, 0),
				if i % 2 == 0 then CREAM else IVORY)
		end
	end
	bulb("GatheredNeck", V(0.34, 0.50, 0.34), CFrame.new(0, 0.62, 0), CREAM)
	local stemBase = V(0, st.bottom, 0)
	local stemTop = stemBase + V(s.stemLean * st.stemHeight, st.stemHeight, 0)
	local stemWidth = 0.10 + 0.11 * phase(g, 0, 0.65)
	emit("Pseudostem", V(stemWidth, stemWidth, (stemTop - stemBase).Magnitude + 0.025), Kit.axis(stemBase, stemTop),
		SHEATH:Lerp(GREEN_B, 0.35 * phase(g, 0.15, 0.80)), 1, "Foliage")
	for i, f in s.leaves do
		if proxy and i % 2 == 0 then continue end
		local q = if i == 1 then 0.12 + 0.88 * phase(g, 0, 0.28) else phase(g, f.start, f.start + 0.32)
		local dry = if i <= 2 then phase(g, 0.78, 1) else 0
		local lean = f.lean * (0.35 + 0.65 * phase(q, 0.1, 1))
		local out = V(math.sin(f.yaw), 0, math.cos(f.yaw))
		local node = (0.78 + i * 0.18 - 0.655) / 1.57
		local pos = stemBase:Lerp(stemTop, node)
		local points = {pos}
		local reach, used = f.length * q, 0
		for j = 1, 3 do
			local angle = lean + (j - 1) * (0.15 + 0.18 * dry)
			local len = math.clamp(reach - used, 0, f.length * FRACS[j])
			used += f.length * FRACS[j]
			pos += (out * math.sin(angle) + V(0, math.cos(angle), 0)) * len
			points[j + 1] = pos
		end
		for j = 1, (if proxy then 2 else 3) do
			local a, b = points[j], points[if proxy and j == 2 then 4 else j + 1]
			local delta = b - a
			local dir = if delta.Magnitude > 0.00001 then delta.Unit else V(0, 1, 0)
			local normal = out:Cross(Vector3.yAxis):Cross(dir).Unit
			local cf = CFrame.lookAt((a + b) / 2, (a + b) / 2 - dir, normal)
			local color = YOUNG:Lerp(if i % 2 == 0 then GREEN else GREEN_B, phase(g, 0.10, 0.60))
			if j == 3 or (proxy and j == 2) then color = color:Lerp(STRAW, dry) end
			local width = WIDTHS[j] * f.width * (0.45 + 0.55 * q)
			emit("Blade_" .. i .. "_" .. j, V(width, 0.065, delta.Magnitude + 0.025), cf, color,
				if delta.Magnitude > 0.004 then 1 else 0, "Foliage")
		end
	end
	-- Extend one connected path base-first. The bud always rides its actual current endpoint.
	local scapeBase = stemBase:Lerp(stemTop, 0.25 / 1.57)
	local turn = CFrame.Angles(0, s.scapeYaw, 0)
	local path, total, prev = {scapeBase}, 0, scapeBase
	for _, p in PATH do
		local nextPos = scapeBase + turn:VectorToWorldSpace(p * V(s.curlWidth, s.scapeHeight, s.curlWidth))
		total += (nextPos - prev).Magnitude
		table.insert(path, nextPos)
		prev = nextPos
	end
	local grow = phase(g, 0.52, 0.98)
	local remaining, tip, direction = total * grow, scapeBase, V(0, 1, 0)
	for j = 1, #PATH do
		local a = tip
		local length = (path[j + 1] - path[j]).Magnitude
		local len = math.clamp(remaining, 0, length)
		local dir = (path[j + 1] - path[j]).Unit
		local b = a + dir * len
		emit("Scape_" .. j, V(0.13, 0.13, len + 0.025), Kit.axis(a, b), GREEN_B, if len > 0.00001 then 1 else 0, "Scape")
		if len > 0 then direction = dir end
		tip, remaining = b, remaining - len
	end
	local bud = phase(g, 0.58, 0.94)
	local matureDir = turn:VectorToWorldSpace(V(0.42, 0.9, 0).Unit)
	local budDir = direction:Lerp(matureDir, phase(g, 0.93, 1)).Unit
	local b, c = tip + budDir * 0.32 * bud, tip + budDir * 0.57 * bud
	emit("ClosedSpathe", V(0.22 * bud + 0.001, 0.18 * bud + 0.001, (b - tip).Magnitude + 0.02), Kit.axis(tip, b),
		SHEATH:Lerp(CREAM, 0.55), if bud > 0.01 then 1 else 0, "Scape")
	emit("SpathePoint", V(0.09 * bud + 0.001, 0.08 * bud + 0.001, (c - b).Magnitude + 0.02), Kit.axis(b, c),
		CREAM, if bud > 0.01 then 1 else 0, "Scape")
end

function GarlicPlant.new(parent, soilCFrame, seed, sizeFactor)
	local self = setmetatable(shape(seed, sizeFactor), GarlicPlant)
	self.rig = Kit.newRig("GarlicPlant", soilCFrame)
	self.model = self.rig.model
	geometry(self, 1, function(name, _, _, _, _, role) self.rig:add(name, nil, role) end)
	assert(#self.rig.parts == 54, "Garlic topology changed")
	self:SetGrowth(0)
	self.model.Parent = parent
	return self
end

function GarlicPlant:SetGrowth(normalized)
	local g = self.rig:beginPose(normalized)
	if not g then return end
	geometry(self, g, function(_, size, cf, color, opacity) self.rig:block(size, cf, color, opacity) end)
	self.rig:finish()
end

function GarlicPlant:Destroy()
	self.rig:destroy()
end

-- Direct-built mid silhouette: three shoulders, neck/core/stem, four two-piece blades and the complete scape curl.
function GarlicPlant.BuildProxy(parent, soilCFrame, stage, seed, sizeFactor)
	local s = shape(seed, sizeFactor)
	local g = if stage <= 1 then 0.20 elseif stage == 2 then 0.60 else 1
	geometry(s, g, function(name, size, cf, color, opacity, role)
		if opacity <= 0.01 then return end
		local part = Kit.proxyPart(parent, name, size, soilCFrame * cf, color, nil, role)
		part.Transparency = 1 - opacity
	end, true)
end

return GarlicPlant
