-- CG9 field recipe: a glowing chestnut bolete pair (docs/plants/GLOW_MUSHROOM.md).
-- Two boletes (barrel stem 10 + pores 2 + rim 2 + cap 11 = 25 each) and two buttons (stem 1 + pores 2 + cap 2 = 5 each) = 60 Parts.
-- Boletes grow as a button: a squat bun on a stub that swells and lengthens while the cap widens, rises and flattens into a
-- cushion. Ripeness = the pore layer under each cap switching from a pale plastic to a bright Neon teal glow.
local GlowMushroomPlant = {}
GlowMushroomPlant.__index = GlowMushroomPlant
GlowMushroomPlant.RingHeight = 5.0
GlowMushroomPlant.ReviewHeight = 4.8 -- keeps the tall cap and the ring in the Studio reviewer's frame

local Kit = require(script.Parent.PlantKit)
local phase = Kit.phase
local V, C = Vector3.new, Color3.fromRGB
local CAP = { C(98, 54, 32), C(114, 64, 38), C(128, 74, 42), C(142, 84, 48), C(154, 96, 56), C(166, 108, 64) } -- bottom to top
local YOUNG_CAP = C(196, 158, 118)
local RIM = C(226, 214, 190)
local STEM, STEM_SHADE, YOUNG_STEM = C(208, 202, 186), C(184, 178, 160), C(224, 218, 200)
local PORE_YOUNG, GLOW = C(214, 218, 200), C(90, 205, 196) -- the glow is the crop's teal (PlotView CROP_COLORS g)
local MAX_RADIUS = 2.4 -- ground radius target of the 5.5-stud square, every age and size
local MAX_HEIGHT = 4.8 -- tallest cap top, well below the 5.46-stud avatar
local OCTAGON = 1.4143 -- corner reach of a slab (two squares, one turned 45 degrees) over its half width

-- Cap layer widths (fraction of the cap diameter), bottom to top: a rounded button when young, a flatter cushion when ripe.
-- Layers 1-5 are octagons, layer 6 a single square.
local YOUNG_W = { 0.72, 0.96, 1.00, 0.86, 0.60, 0.30 }
local RIPE_W = { 0.84, 0.98, 1.00, 0.92, 0.72, 0.42 }
-- Barrel stem: widest in the lower third, narrowing under the cap.
local STEM_PROFILE = { 0.92, 1.10, 1.04, 0.88, 0.70 }

-- pos, stem height, stem width, cap radius, cap height, lean at the stem top, cap tilt, stem / cap growth intervals.
local MUSHROOMS = {
	{ pos = V(-0.35, 0, 0.15), H = 3.0, W = 1.00, R = 1.30, T = 1.20, lean = V(-0.06, 0, 0.04), tilt = V(0.03, 0, -0.03),
		sFirst = 0.08, sLast = 0.70, cFirst = 0.14, cLast = 0.86 },
	{ pos = V(0.95, 0, -0.60), H = 1.60, W = 0.75, R = 0.85, T = 0.75, lean = V(0.10, 0, 0), tilt = V(-0.02, 0, 0.03),
		sFirst = 0.04, sLast = 0.56, cFirst = 0.08, cLast = 0.72 },
}
local BUTTONS = {
	{ pos = V(-1.10, 0, -1.20), H = 0.35, W = 0.26, R = 0.28, first = 0.05, last = 0.45 },
	{ pos = V(1.20, 0, 1.05), H = 0.30, W = 0.22, R = 0.24, first = 0.12, last = 0.52 },
}
-- Height multipliers per seed (big / small); consecutive seeds walk through the list.
local TENDENCIES = { { 1, 1 }, { 0.92, 1.15 }, { 1.08, 0.92 }, { 0.88, 1.0 }, { 1.04, 1.2 }, { 0.96, 0.88 } }

-- Largest ground distance a ripe mushroom's cap reaches (tilt allowance included).
local function reach(m): number
	return V(m.pos.X + m.lean.X, 0, m.pos.Z + m.lean.Z).Magnitude + OCTAGON * m.R + 0.06
end

-- Shared seed parameters keep the distance proxy consistent without building the full plant. The `vary` draw order is part
-- of a planting's identity: add new draws last.
local function seededShape(seed, sizeFactor)
	local self = { mushrooms = {}, buttons = {} }
	local vary = Kit.seeded(seed)
	local ds = Kit.dimension(sizeFactor)
	local tendency = Kit.tendency(TENDENCIES, seed)
	-- Heavy harvests grow taller and thicker (to 1.3 and 1.15), never wider than the square; light ones shrink evenly.
	local sH, sT, sW = math.min(ds, 1.3), math.min(ds, 1.15), math.min(ds, 1)
	self.dimensionScale = ds
	for i, spec in MUSHROOMS do
		self.mushrooms[i] = {
			id = i,
			pos = V(spec.pos.X * sW + vary(0.15), 0, spec.pos.Z * sW + vary(0.15)),
			H = spec.H * tendency[i] * sH * (1 + vary(0.08)),
			W = spec.W * sT,
			R = spec.R * sW * (1 + vary(0.08)),
			T = spec.T * sH,
			lean = V((spec.lean.X + vary(0.08)) * sW, 0, (spec.lean.Z + vary(0.08)) * sW),
			tilt = V(spec.tilt.X + vary(0.03), 0, spec.tilt.Z + vary(0.03)),
			yaw = vary(0.6),
			delay = vary(0.03),
			sFirst = spec.sFirst, sLast = spec.sLast, cFirst = spec.cFirst, cLast = spec.cLast,
		}
	end
	for i, spec in BUTTONS do
		self.buttons[i] = {
			pos = V(spec.pos.X * sW + vary(0.15), 0, spec.pos.Z * sW + vary(0.15)),
			H = spec.H * sH, W = spec.W * sT, R = spec.R * sW, yaw = vary(0.6),
			first = spec.first, last = spec.last,
		}
	end
	-- The small cap stays clear of the big cap's underside.
	local big, small = self.mushrooms[1], self.mushrooms[2]
	local tiltAllowance = 1.5 * (big.R * (math.abs(big.tilt.X) + math.abs(big.tilt.Z)) + small.R * (math.abs(small.tilt.X) + math.abs(small.tilt.Z)))
	small.H = math.max(0.8 * sH, math.min(small.H, big.H - 1.1 * small.T - 0.5 - tiltAllowance))
	-- The tallest cap stays below the avatar even for the largest harvest on a tall seed.
	local tallest = big.H + 1.1 * big.T - 0.03
	if tallest > MAX_HEIGHT then
		local fit = MAX_HEIGHT / tallest
		for _, m in self.mushrooms do
			m.H *= fit
			m.T *= fit
		end
	end
	-- Fit the ripe canopy (the widest pose) to the square, pulling the group together and slimming the caps evenly.
	local ext = 0
	for _, m in self.mushrooms do ext = math.max(ext, reach(m)) end
	for _, b in self.buttons do ext = math.max(ext, b.pos.Magnitude + OCTAGON * b.R * 1.0) end
	if ext > MAX_RADIUS then
		local fit = MAX_RADIUS / ext
		for _, m in self.mushrooms do
			m.pos *= fit
			m.lean *= fit
			m.R *= fit
		end
		for _, b in self.buttons do
			b.pos *= fit
			b.R *= fit
		end
	end
	return self
end

-- Pose of one bolete at growth g: stem top, cap frame and the sizes the geometry writes.
local function mushroomState(m, g)
	local qS = phase(g, m.sFirst + m.delay, m.sLast + m.delay)
	local o = phase(g, m.cFirst + m.delay, m.cLast + m.delay)
	local stemH = m.H * (0.10 + 0.90 * qS)
	local top = m.pos + m.lean * qS + V(0, stemH, 0)
	return {
		qS = qS, o = o, stemH = stemH, top = top, widen = 0.5 + 0.5 * qS,
		rf = 0.32 + 0.68 * o, Tf = m.T * (0.55 + 0.45 * o),
		frame = CFrame.new(top + V(0, -0.1, 0)) * CFrame.Angles(m.tilt.X * o, m.yaw, m.tilt.Z * o),
		glow = phase(g, 0.82 + m.delay, 0.98),
	}
end

-- emit(kind, size, cf, color, opacity): kind is "stem", "pore", "rim" or "cap". Octagons emit two plates.
local function mushroomGeometry(m, s, emit)
	local h = s.stemH / 5
	for i, k in STEM_PROFILE do
		local w = m.W * s.widen * k
		local at = CFrame.new(m.pos + V(m.lean.X * s.qS * (i / 5) ^ 2, h * (i - 0.5), m.lean.Z * s.qS * (i / 5) ^ 2))
		local color = (if i % 2 == 0 then STEM_SHADE else STEM):Lerp(YOUNG_STEM, 1 - s.qS)
		emit("stem", V(w, h + 0.02, w), at, color, 1)
		emit("stem", V(w, h + 0.02, w), at * CFrame.Angles(0, math.pi / 4, 0), color, 1)
	end
	local d = 2 * m.R * s.rf
	local pores = phase(s.o, 0.08, 0.25)
	local poreColor = PORE_YOUNG:Lerp(GLOW, s.glow)
	local poreCF = s.frame * CFrame.new(0, -0.16, 0)
	local poreSize = V(d * 0.88, 0.3 * (0.5 + 0.5 * s.o), d * 0.88)
	emit("pore", poreSize, poreCF, poreColor, pores)
	emit("pore", poreSize, poreCF * CFrame.Angles(0, math.pi / 4, 0), poreColor, pores)
	local rim = s.frame * CFrame.new(0, 0.03, 0)
	emit("rim", V(d * 0.90, 0.07, d * 0.90), rim, RIM, 1)
	emit("rim", V(d * 0.90, 0.07, d * 0.90), rim * CFrame.Angles(0, math.pi / 4, 0), RIM, 1)
	local t = s.Tf / 6
	for i = 1, 6 do
		local w = YOUNG_W[i] + (RIPE_W[i] - YOUNG_W[i]) * s.o
		local size = V(d * w, t * 1.1 + 0.02, d * w)
		local f = s.frame * CFrame.new(0, 0.07 + t * (i - 0.5) * 1.1, 0)
		local color = YOUNG_CAP:Lerp(CAP[i], s.o)
		emit("cap", size, f, color, 1)
		if i <= 5 then emit("cap", size, f * CFrame.Angles(0, math.pi / 4, 0), color, 1) end
	end
end

local function buttonState(b, g)
	local q = phase(g, b.first, b.last)
	local stemH = b.H * (0.30 + 0.70 * q)
	return { q = q, stemH = stemH, rf = 0.4 + 0.6 * q, glow = phase(g, 0.82, 0.98) }
end

local function buttonGeometry(b, s, emit)
	local w = b.W * (0.6 + 0.4 * s.q)
	emit("stem", V(w, s.stemH, w), CFrame.new(b.pos + V(0, s.stemH / 2, 0)), STEM:Lerp(YOUNG_STEM, 1 - s.q), 1)
	local d = 2 * b.R * s.rf
	local poreColor = PORE_YOUNG:Lerp(GLOW, s.glow)
	local pores = phase(s.q, 0.3, 0.5)
	local at = CFrame.new(b.pos + V(0, s.stemH - 0.02, 0))
	emit("pore", V(d * 0.85, 0.1, d * 0.85), at, poreColor, pores)
	emit("pore", V(d * 0.85, 0.1, d * 0.85), at * CFrame.Angles(0, math.pi / 4, 0), poreColor, pores)
	local cap = CFrame.new(b.pos + V(0, s.stemH + b.R * 0.35 * s.rf, 0))
	local color = YOUNG_CAP:Lerp(CAP[4], s.q)
	emit("cap", V(d, b.R * 0.7 * s.rf, d), cap, color, 1)
	emit("cap", V(d, b.R * 0.7 * s.rf, d), cap * CFrame.Angles(0, math.pi / 4, 0), color, 1)
end

-- The pore layer is ordinary stud plastic until it starts to glow, then Neon.
local function setGlowing(part: BasePart, on: boolean)
	local material = if on then Enum.Material.Neon else Enum.Material.Plastic
	if part.Material ~= material then
		part.Material, part.MaterialVariant = material, if on then "" else "StudsSmall"
	end
end

function GlowMushroomPlant.new(parent, soilCFrame, seed, sizeFactor)
	local self = setmetatable(seededShape(seed, sizeFactor), GlowMushroomPlant)
	local rig = Kit.newRig("GlowMushroomPlant", soilCFrame)
	self.rig, self.model, self.fruitSlots = rig, rig.model, {}
	for i, m in self.mushrooms do
		local slot = { id = i, attachment = soilCFrame * CFrame.new(mushroomState(m, 1).top), parts = {} }
		self.fruitSlots[i] = slot
		local function add(name, count)
			for k = 1, count do
				table.insert(slot.parts, rig:add("Mushroom" .. i .. "_" .. name .. k, nil, "Fruit", i))
			end
		end
		add("Stem", 10)
		add("Pore", 2)
		add("Rim", 2)
		add("Cap", 11)
	end
	for i = 1, #self.buttons do
		rig:add("Button" .. i .. "_Stem", nil, "Structure")
		rig:add("Button" .. i .. "_Pore1", nil, "Structure")
		rig:add("Button" .. i .. "_Pore2", nil, "Structure")
		rig:add("Button" .. i .. "_Cap1", nil, "Structure")
		rig:add("Button" .. i .. "_Cap2", nil, "Structure")
	end
	assert(#rig.parts == 60, "Glow mushroom topology changed")
	self:SetGrowth(0)
	self.model.Parent = parent
	return self
end

function GlowMushroomPlant:SetGrowth(normalized)
	local rig = self.rig
	local g = rig:beginPose(normalized)
	if not g then return end
	local function writer(glowing)
		return function(kind, size, cf, color, opacity)
			rig:block(size, cf, color, opacity)
			if kind == "pore" then setGlowing(rig.parts[rig.cursor], glowing) end
		end
	end
	for _, m in self.mushrooms do
		local s = mushroomState(m, g)
		mushroomGeometry(m, s, writer(s.glow > 0.02))
	end
	for _, b in self.buttons do
		local s = buttonState(b, g)
		buttonGeometry(b, s, writer(s.glow > 0.02))
	end
	rig:finish()
end

function GlowMushroomPlant:Destroy()
	self.rig:destroy()
end

-- Mid distance: 4 / 8 / 12 Parts. Keep the bolete silhouette (barrel stem, cushion cap, glowing pores) and the ripe buttons;
-- omit the stem's octagon layers, rim and cap layers.
function GlowMushroomPlant.BuildProxy(parent, soilCFrame, stage, seed, sizeFactor)
	local shape = seededShape(seed, sizeFactor)
	local g = if stage <= 1 then 0.20 elseif stage == 2 then 0.72 else 1
	local function block(kind, size, cf, color, role, id, glowing)
		local part = Kit.proxyPart(parent, kind, size, soilCFrame * cf, color, nil, role, id)
		if glowing then setGlowing(part, true) end
	end
	for id, m in shape.mushrooms do
		local s = mushroomState(m, g)
		local w = m.W * s.widen * 0.95
		block("stem", V(w, s.stemH, w), CFrame.new(m.pos + m.lean * (s.qS * 0.5) + V(0, s.stemH / 2, 0)),
			STEM:Lerp(YOUNG_STEM, 1 - s.qS), "Fruit", id)
		local d = 2 * m.R * s.rf
		local color = YOUNG_CAP:Lerp(CAP[3], s.o)
		local capSize = V(d * 0.94, s.Tf * 0.9, d * 0.94)
		local cap = s.frame * CFrame.new(0, 0.07 + s.Tf * 0.5, 0)
		block("cap", capSize, cap, color, "Fruit", id)
		if stage >= 2 then
			block("cap", capSize, cap * CFrame.Angles(0, math.pi / 4, 0), color, "Fruit", id)
			block("pore", V(d * 0.88, 0.3 * (0.5 + 0.5 * s.o), d * 0.88), s.frame * CFrame.new(0, -0.16, 0),
				PORE_YOUNG:Lerp(GLOW, s.glow), "Fruit", id, s.glow > 0.02)
		end
	end
	if stage >= 3 then
		for _, b in shape.buttons do
			local s = buttonState(b, g)
			local d = 2 * b.R * s.rf
			block("stem", V(b.W, s.stemH, b.W), CFrame.new(b.pos + V(0, s.stemH / 2, 0)), STEM, "Structure")
			block("cap", V(d, b.R * 0.7 * s.rf + 0.08, d), CFrame.new(b.pos + V(0, s.stemH + b.R * 0.35 * s.rf, 0)),
				CAP[4], "Structure", nil, false)
		end
	end
end

return GlowMushroomPlant
