-- CG21b recipe: the chosen "B, tall stalk" pineapple (docs/plants/PINEAPPLE.md): a rosette of long strap leaves, a thick stalk that
-- lifts one diamond-eyed fruit (eight columns x seven tiers) above the leaves, and a blue-green crown. Ripens from the base up.
-- 155 Parts: hub 1, leaves 12 x 3, stalk 2, fruit core 2, cap 2, eyes 56, bracts 28, crown 14 blades x 2.
-- Growth art approved by Ales 2026-11-12; registered in PlantGrowth (no Draft flag).
local PineapplePlant = {}
PineapplePlant.RingHeight = 7.2
PineapplePlant.FixedRingHeight = true -- the fruit grows with mass but the ring stays above the tallest crown
PineapplePlant.ReviewHeight = 6.4

local Kit = require(script.Parent.PlantKit)
local phase, V, C = Kit.phase, Vector3.new, Color3.fromRGB

local LEAF = {C(34, 102, 58), C(50, 124, 66)} -- glossy dark rosette strap leaves
local YOUNG_LEAF = C(142, 196, 104)
local CROWN_RIPE = {C(86, 148, 118), C(110, 168, 124)} -- blue-green crown
local CROWN_YOUNG = C(104, 168, 84)
local HUB, STALK = C(150, 170, 104), C(112, 138, 66)
local EYE_LOW, EYE_HIGH, EYE_ALT = C(236, 158, 36), C(226, 196, 70), C(250, 194, 64) -- ripe: orange-gold at the base to yellow
local EYE_GREEN = {C(88, 142, 58), C(112, 164, 74)}
local CORE = C(120, 86, 34)
local BRACT_GREEN, BRACT_RIPE = C(80, 130, 56), C(126, 118, 44)
local CAP_GREEN, CAP_RIPE = C(110, 150, 60), C(150, 160, 70)

local LEAVES = 12
local L0, H0, DROOP0, WIDTH0 = 1.75, 2.45, 0.55, 0.72 -- rosette leaf reach, height, tip droop (of the height), width
local BASE0 = 2.55 -- height of the fruit's base on the stalk
local FRUIT_H, FRUIT_R = 2.15, 0.90
local MAX_FRUIT = 1.20 -- heavy harvests grow the fruit up to this scale
local MAX_REACH = 2.36
local PROFILE = {0.70, 0.88, 0.98, 1.0, 0.96, 0.86, 0.68}
-- Crown rings: blade count, lean from vertical, length, width.
local RINGS = {{6, 0.62, 1.05, 0.40}, {5, 0.36, 1.30, 0.36}, {3, 0.12, 1.05, 0.30}}
local GOLDEN = 2.399963229728653

-- Rosette leaf path: four points (radius fractions, height fractions) in the leaf's radial plane, final arch and upright bud.
local FIN_R, FIN_H = {0, 0.34, 0.68, 1}, {0, 0.5, 1}
local UP_R, UP_H = {0, 0.04, 0.07, 0.10}, {0, 0.55, 1.10, 1.65}
local WIDTHS = {1, 0.88, 0.62}

-- Furthest horizontal reach of a mature leaf's blade corners.
local function leafReach(L, width)
	local reach = 0
	for k = 1, 3 do
		reach = math.max(reach, math.sqrt((0.18 + L * FIN_R[k + 1]) ^ 2 + (width * WIDTHS[k] / 2) ^ 2))
	end
	return reach
end

-- Seeded shape shared by the full plant and the mid proxy; the draw order is part of a planting's identity.
local function seededShape(seed, sizeFactor)
	local dim = Kit.dimension(sizeFactor)
	local self = {dimensionScale = dim}
	local vary = Kit.seeded(seed)
	local grow = 1 + 0.15 * (dim - 1)
	self.leaves = {}
	for j = 1, LEAVES do
		local k = ((j * 37) % 7) / 6 -- 0..1: unequal lengths
		local l = {
			phi = 1.1 + j * GOLDEN + vary(0.22),
			L = L0 * grow * (0.78 + 0.22 * k) * (1 + vary(0.08)),
			H = H0 * grow * (0.8 + 0.2 * (1 - k)) * (1 + vary(0.08)),
			droop = DROOP0 * (0.7 + 0.5 * k) * (1 + vary(0.06)),
			start = (j - 1) * 0.03,
		}
		l.stop = l.start + 0.32
		for _ = 1, 20 do
			if leafReach(l.L, WIDTH0) <= MAX_REACH then break end
			l.L *= 0.96
		end
		self.leaves[j] = l
	end
	self.lean = V(0.04 + vary(0.10), 0, 0.02 + vary(0.10))
	self.fruitYaw = 0.1 + vary(0.4)
	self.crownYaw = 0.2 + vary(0.6)
	self.fs = math.min(dim, MAX_FRUIT)
	self.R, self.H = FRUIT_R * self.fs, FRUIT_H * self.fs
	self.centre = V(self.lean.X, BASE0 + self.H / 2, self.lean.Z)
	return self
end

-- Frame at the middle of a -> b with Z along the segment and X horizontal across the leaf (t = tangent), stable at any slope.
local function frame(a, b, t)
	local d = b - a
	local m = d.Magnitude
	local z = if m < 0.0001 then V(0, 1, 0) else d / m
	local x = t - z * t:Dot(z)
	x = if x.Magnitude < 0.001 then V(1, 0, 0) else x.Unit
	return CFrame.fromMatrix((a + b) / 2, x, z:Cross(x), z), m
end

local function strap(emit, name, a, b, w, color, opacity, t, roll, role, slot)
	local cf, len = frame(a, b, t)
	emit(name, V(w, 0.085, len + 0.06), cf * CFrame.Angles(0, 0, roll), color, opacity, role, slot, "Studs")
end

local function rod(emit, name, a, b, width, color, q, role)
	emit(name, V(width, width, (b - a).Magnitude + 0.02), Kit.axis(a, b), color, phase(q, 0, 0.08), role)
end

-- Emits every Part in a fixed order: emit(name, size, cframe-relative-to-soil, color, opacity, role, fruitSlot, variant).
local function geometry(s, g, emit, proxy)
	local hubS = 0.55 + 0.45 * phase(g, 0, 0.3)
	emit("Hub", V(0.8, 0.5, 0.8) * hubS, CFrame.new(0, 0.25 * hubS, 0) * CFrame.Angles(0, 0.3, 0), HUB, 1, "Structure")
	-- Rosette: leaves 1-4 start as a small upright slip, the rest sprout in turn; each opens from a bud into its arch.
	for j, l in s.leaves do
		if not (proxy and j % 3 == 0) then
			local raw = phase(g, l.start, l.stop)
			local q = if j <= 4 then 0.22 + 0.78 * raw else raw
			local o = phase(q, 0.25, 1)
			local d, t = V(math.cos(l.phi), 0, math.sin(l.phi)), V(-math.sin(l.phi), 0, math.cos(l.phi))
			local pts = {}
			for k = 1, 4 do
				local ru, rf = UP_R[k] * l.L, FIN_R[k] * l.L
				local hu, hf = UP_H[k] * l.H, (if k == 4 then l.droop else FIN_H[k]) * l.H
				pts[k] = d * (0.18 + q * (ru + (rf - ru) * o)) + V(0, 0.12 + q * (hu + (hf - hu) * o), 0)
			end
			local color = YOUNG_LEAF:Lerp(LEAF[j % 2 + 1], phase(q, 0.15, 0.9))
			local opacity = if j <= 4 then 1 else phase(raw, 0, 0.06)
			local roll = (if j % 2 == 0 then 0.5 else -0.5) * (0.3 + 0.7 * o)
			local w = WIDTH0 * (0.4 + 0.6 * q)
			if proxy then
				strap(emit, "Leaf_" .. j .. "_1", pts[1], pts[3], w, color, opacity, t, roll, "Foliage")
				strap(emit, "Leaf_" .. j .. "_2", pts[3], pts[4], w * WIDTHS[3], color, opacity, t, roll, "Foliage")
			else
				for k = 1, 3 do
					strap(emit, "Leaf_" .. j .. "_" .. k, pts[k], pts[k + 1], w * WIDTHS[k], color, opacity, t, roll, "Foliage")
				end
			end
		end
	end
	-- Stalk rises from the heart of the rosette and lifts the fruit.
	local qs = phase(g, 0.45, 0.72)
	local p0 = V(0, 0.4, 0)
	local top = p0:Lerp(V(s.lean.X, BASE0 + 0.1, s.lean.Z), qs)
	local pm = p0:Lerp(top, 0.55) + s.lean * 0.4 * qs
	rod(emit, "Stalk_1", p0, pm, 0.36, STALK, qs, "Structure")
	rod(emit, "Stalk_2", pm, top, 0.32, STALK, qs, "Structure")
	-- Fruit: swells from 58%, green, then ripens from the base up (the base tier first).
	local fp = top - V(0, 0.1, 0)
	local sc = 0.16 + 0.84 * phase(g, 0.56, 0.98)
	local R, H = s.R * sc, s.H * sc
	local th = H / #PROFILE
	local vis = phase(g, 0.56, 0.62)
	local thick = 0.4 + 0.6 * sc
	local ripeAll = phase(g, 0.74, 1)
	local core = 1.05 * R
	for k = 0, 1 do
		emit("FruitCore_" .. (k + 1), V(core, H * 0.9, core), CFrame.new(fp + V(0, H * 0.5, 0)) * CFrame.Angles(0, s.fruitYaw + k * math.pi / 4, 0), CORE, vis, "Fruit", 1)
	end
	for k = 0, 1 do
		emit("FruitCap_" .. (k + 1), V(R * 1.0, 0.3 * thick, R * 1.0), CFrame.new(fp + V(0, H - 0.08 * thick, 0)) * CFrame.Angles(0, s.fruitYaw + k * math.pi / 4, 0), CAP_GREEN:Lerp(CAP_RIPE, ripeAll), vis, "Fruit", 1)
	end
	for t = 1, #PROFILE do
		if not (proxy and t % 2 == 1) then
			local r = R * PROFILE[t]
			local slope = (R * PROFILE[math.min(t + 1, #PROFILE)] - R * PROFILE[math.max(t - 1, 1)]) / (2 * th)
			local ripe = phase(g, 0.74 + 0.02 * (t - 1), 0.86 + 0.02 * (t - 1))
			local gold = EYE_LOW:Lerp(EYE_HIGH, (t - 1) / (#PROFILE - 1))
			for i = 0, 7 do
				local theta = s.fruitYaw + (i + (t % 2) * 0.5) * math.pi / 4
				local out = V(math.cos(theta), 0, math.sin(theta))
				local pos = fp + V(0, th * (t - 0.5), 0) + out * r
				local eye = CFrame.lookAt(pos, pos + (out - V(0, slope, 0)).Unit)
				local even = (i + t) % 2 == 0
				local ripeColor = if even then gold else EYE_ALT:Lerp(gold, 0.5)
				emit("Eye", V(math.pi / 4 * r * 0.98, th * (if proxy then 2.1 else 0.98), 0.30 * thick), eye, EYE_GREEN[if even then 1 else 2]:Lerp(ripeColor, ripe), vis, "Fruit", 1)
				if even and not proxy then
					emit("Bract", V(0.11, 0.20, 0.10) * thick, eye * CFrame.new(0, th * 0.30, -0.19 * thick) * CFrame.Angles(-0.45, 0, 0), BRACT_GREEN:Lerp(BRACT_RIPE, ripe), vis, "Fruit", 1)
				end
			end
		end
	end
	-- Crown: three rings of blades, unfolding from an upright tuft as the fruit swells.
	local at = fp + V(0, H - 0.05 * thick, 0)
	local csc = (0.2 + 0.8 * phase(g, 0.58, 0.98)) * s.fs
	local open = 0.35 + 0.65 * phase(g, 0.70, 0.98)
	local idx = 0
	for ri, ring in RINGS do
		for j = 1, ring[1] do
			idx += 1
			if not (proxy and ri == 1) then
				local phi = s.crownYaw + (j + ri * 0.37) * 2 * math.pi / ring[1]
				local d, t = V(math.cos(phi), 0, math.sin(phi)), V(-math.sin(phi), 0, math.cos(phi))
				local len = ring[3] * 1.15 * csc * (0.88 + 0.12 * ((idx * 5) % 3))
				local lean = ring[2] * open
				local mid = at + d * (math.sin(lean) * len * 0.55) + V(0, math.cos(lean) * len * 0.55, 0)
				local tip = mid + d * (math.sin(lean + 0.30 * open) * len * 0.50) + V(0, math.cos(lean + 0.30 * open) * len * 0.50, 0)
				local color = CROWN_YOUNG:Lerp(CROWN_RIPE[idx % 2 + 1], phase(g, 0.62, 0.98))
				local roll = if idx % 2 == 0 then 0.45 else -0.45
				local w = ring[4] * 1.25 * csc
				if proxy then
					strap(emit, "CrownBlade_" .. idx, at, tip, w, color, vis, t, roll, "Fruit", 1)
				else
					strap(emit, "CrownBlade_" .. idx .. "a", at, mid, w, color, vis, t, roll, "Fruit", 1)
					strap(emit, "CrownBlade_" .. idx .. "b", mid, tip, w * 0.62, color, vis, t, roll, "Fruit", 1)
				end
			end
		end
	end
end

Kit.recipe(PineapplePlant, {
	name = "PineapplePlant",
	parts = 155, -- 1 hub + 36 leaf + 2 stalk + 4 core / cap + 56 eyes + 28 bracts + 28 crown
	shape = seededShape,
	geometry = geometry,
	proxyMid = 0.70,
	onNew = function(self, _, soilCFrame)
		self.fruitSlots = {{id = 1, attachment = soilCFrame * CFrame.new(self.centre), parts = {}}}
	end,
})

return PineapplePlant
