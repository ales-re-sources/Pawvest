-- CG17b: round highbush blueberry (docs/plants/BLUEBERRY.md, study A with the berries spread over the whole bush).
-- 2 seed leaves + 5 two-rod canes + 4 twigs + 28 leaves + 10 bunches (6 berries, 3 crowns) = 134 Parts, built once.
-- Each bunch is a fruit slot: white bells hang where its berries will be, drop at petal fall, and the green berry starts
-- swell, turn their crowns outward and ripen green -> blush -> dusty blue one by one.
-- Mid proxy: the same canes and twigs, every other leaf (a little larger) and two enlarged berries per bunch, no crowns.
local BlueberryPlant = {}
BlueberryPlant.RingHeight = 5.9
BlueberryPlant.FixedRingHeight = true
BlueberryPlant.ReviewHeight = 4.6

local Kit = require(script.Parent.PlantKit)
local phase, V, C = Kit.phase, Vector3.new, Color3.fromRGB
local YOUNG, CANE = C(128, 158, 82), C(122, 92, 66)
local SEED_LEAF = C(126, 178, 92)
local LEAVES = { C(84, 146, 68), C(108, 164, 78), C(72, 130, 84) }
local BELL, START, CALYX = C(246, 244, 236), C(176, 204, 140), C(196, 126, 140)
local GREEN, BLUSH, CROWN = C(178, 204, 146), C(178, 112, 150), C(44, 44, 74)
local BLUES = { C(96, 110, 170), C(84, 98, 160), C(110, 124, 184) }
local CANE_SPEC = { -- yaw (0 = review camera), height, top radius, start
	{ 0.25, 3.95, 1.20, 0.00 }, { 1.45, 3.55, 1.35, 0.06 }, { 2.75, 4.15, 1.05, 0.12 },
	{ 3.95, 3.65, 1.30, 0.17 }, { 5.15, 3.85, 1.25, 0.22 },
}
local TWIG_CANES = { 1, 2, 4, 5 }
-- Bunches spread over the whole bush, low to high: cane, fraction along it, yaw offset of its outward side.
local BUNCH_SPEC = {
	{ 1, 0.30, 0.55 }, { 1, 0.62, -0.45 }, { 1, 0.90, 0.30 }, { 2, 0.42, -0.35 }, { 2, 0.82, 0.40 },
	{ 3, 0.58, 0.00 }, { 4, 0.32, 0.30 }, { 4, 0.78, -0.30 }, { 5, 0.46, 0.35 }, { 5, 0.86, -0.35 },
}
-- Berry centres in the bunch frame (+Z outward, +Y up), in berry sizes; the first three show their crowns.
local BERRY_AT = { V(-0.52, 0.02, 0.36), V(0.50, -0.06, 0.38), V(0.02, -0.56, 0.32), V(0.02, 0.54, 0.30), V(-0.28, 0.20, -0.36), V(0.30, -0.34, -0.30) }
local FLOWER_AT = { V(-0.42, -0.58, 0.12), V(0.44, -0.62, 0.16), V(0.02, -1.00, 0.24), V(0, -0.30, 0.14), V(-0.24, -0.80, -0.28), V(0.30, -1.06, -0.16) }
local CROWNED = 3
local LEAF_AT = { 0.40, 0.58, 0.76, 1.0 }
local TWIG_LEAF_AT = { 0.55, 1.0 }
local LIMIT = 2.28 -- every Part stays inside the 2.4-stud ground radius

local function pt(t, r, y)
	return V(math.sin(t) * r, y, math.cos(t) * r)
end

-- Point and unit direction at fraction f of a polyline's length.
local function along(pts, f)
	local total = 0
	for i = 1, #pts - 1 do total += (pts[i + 1] - pts[i]).Magnitude end
	local want = total * math.clamp(f, 0, 1)
	for i = 1, #pts - 1 do
		local seg = pts[i + 1] - pts[i]
		local len = seg.Magnitude
		if want <= len or i == #pts - 1 then
			local dir = if len > 0.0001 then seg / len else Vector3.yAxis
			return pts[i] + dir * math.min(want, len), dir
		end
		want -= len
	end
	return pts[#pts], Vector3.yAxis
end

local function shape(seed, sizeFactor)
	local vary, ds = Kit.seeded(seed), Kit.dimension(sizeFactor)
	local s = { canes = {}, twigs = {}, leaves = {}, bunches = {} }
	s.vigor = math.clamp(1 + (ds - 1) * 0.20, 0.93, 1.08)
	s.berry = 0.40 * ds
	for i, c in CANE_SPEC do
		local t, h, r = c[1] + vary(0.18), c[2] * s.vigor * (1 + vary(0.07)), c[3] * (1 + vary(0.10))
		s.canes[i] = {
			start = c[4],
			base = pt(t, 0.10, 0), mid = pt(t + 0.10, 0.55, h * 0.42), top = pt(t + 0.18, r, h),
			twigEnd = pt(t - 0.45 + vary(0.15), 1.45, h * (0.74 + vary(0.05))),
		}
	end
	for k, i in TWIG_CANES do
		s.twigs[k] = { cane = i }
	end
	for i = 1, #CANE_SPEC do
		for j, f in LEAF_AT do
			table.insert(s.leaves, { cane = i, frac = f, tip = j == #LEAF_AT, len = 1.04 * s.vigor * (1 + vary(0.10)), rise = 0.30 + vary(0.12) })
		end
	end
	for k = 1, #TWIG_CANES do
		for j, f in TWIG_LEAF_AT do
			table.insert(s.leaves, { twig = k, frac = f, tip = j == #TWIG_LEAF_AT, len = 0.98 * s.vigor * (1 + vary(0.10)), rise = 0.20 + vary(0.12) })
		end
	end
	for k, b in BUNCH_SPEC do
		s.bunches[k] = {
			cane = b[1], frac = b[2] + vary(0.05), yaw = b[3] + vary(0.25),
			bloom = 0.40 + 0.006 * k + vary(0.012),
			unripe = (k * 3 + 1) % 6 + 1, -- the berry that is still pale at harvest
			unripeKind = if k % 3 == 0 then 0 elseif k % 5 == 0 then 2 else 1, -- 0 = all blue
		}
	end
	-- Append future variation draws here to preserve planting identity.
	return s
end

-- The cane's current polyline: its lower then upper segment extend from the base.
local function canePoints(c, g, first)
	local q = phase(g, c.start, c.start + 0.50)
	local low = math.max(phase(q, 0, 0.45), if first then 0.07 else 0)
	local p1 = c.base + (c.mid - c.base) * low
	local p2 = p1 + (c.top - c.mid) * phase(q, 0.35, 1)
	return { c.base, p1, p2 }, q
end

-- The bunch centre on its cane's current polyline, pushed outward and kept inside the field radius.
-- `margin` = how far (in berry sizes) the bunch's outer berry reaches past its centre.
local function bunchFrame(b, pts, g, d, margin)
	local at = along(pts, b.frac)
	local outward = at - V(0, at.Y, 0)
	local yaw = (if outward.Magnitude > 0.05 then math.atan2(outward.X, outward.Z) else 0) + b.yaw
	local dir = V(math.sin(yaw), 0, math.cos(yaw))
	local centre = at + dir * (0.18 + 0.62 * d)
	local reach = V(centre.X, 0, centre.Z).Magnitude + margin * d
	if reach > LIMIT then
		centre -= V(centre.X, 0, centre.Z).Unit * (reach - LIMIT)
	end
	centre -= V(0, 0.10 * phase(g, 0.80, 1), 0) -- the loaded twig settles
	return CFrame.new(centre) * CFrame.Angles(0, yaw, 0)
end

local function geometry(s, g, emit, proxy)
	local canes, caneGrowth = {}, {}
	for i, c in s.canes do
		canes[i], caneGrowth[i] = canePoints(c, g, i == 1)
	end
	-- Seed leaves on the first shoot, folded at 0 %, open by 10 %, gone by 40 %.
	local sprout = canes[1][2]
	for i = 1, 2 do
		local open = phase(g, 0, 0.10)
		local yaw = 0.25 + (i - 1) * math.pi
		local dir = V(math.sin(yaw), 0, math.cos(yaw))
		local q = 0.55 + 0.45 * open
		emit("SeedLeaf_" .. i, V(0.24, 0.05, 0.30) * q,
			CFrame.new(sprout + dir * 0.13 * q) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(-1.1 + 0.85 * open, 0, 0),
			SEED_LEAF, 1 - phase(g, 0.24, 0.40), "Foliage")
	end
	for i, c in s.canes do
		local pts, q = canes[i], caneGrowth[i]
		local wood = YOUNG:Lerp(CANE, phase(g, c.start + 0.25, c.start + 0.70))
		local width = 0.05 + 0.13 * phase(g, c.start, 0.90)
		local opacity = if i == 1 then 1 else phase(q, 0, 0.04)
		for j = 1, 2 do
			local a, b = pts[j], pts[j + 1]
			local w = width * (if j == 1 then 1 else 0.68)
			emit("Cane_" .. i .. "_" .. j, V(w, w, (b - a).Magnitude + 0.025), Kit.axis(a, b), wood,
				if (b - a).Magnitude > 0.005 then opacity else 0, "Structure")
		end
	end
	local twigs = {}
	for k, t in s.twigs do
		local c = s.canes[t.cane]
		local q = phase(g, c.start + 0.22, c.start + 0.55)
		local a = canes[t.cane][2]
		local b = a + (c.twigEnd - c.mid) * q
		twigs[k] = { a, b }
		emit("Twig_" .. k, V(0.085, 0.085, (b - a).Magnitude + 0.025), Kit.axis(a, b), YOUNG:Lerp(CANE, phase(g, 0.45, 0.85)),
			phase(q, 0, 0.05), "Structure")
	end
	for n, l in s.leaves do
		local pts, born
		if l.cane then
			pts, born = canes[l.cane], s.canes[l.cane].start + l.frac * 0.42
		else
			pts, born = twigs[l.twig], s.canes[s.twigs[l.twig].cane].start + 0.24 + l.frac * 0.28
		end
		if proxy and n % 2 == 0 then continue end
		local q = phase(g, born, born + 0.16)
		local p, dir = along(pts, l.frac)
		local side = if n % 2 == 0 then 1 else -1
		local perp = dir:Cross(Vector3.yAxis)
		perp = (if perp.Magnitude < 0.01 then Vector3.xAxis else perp.Unit) * side
		local out = V(p.X, 0, p.Z)
		out = if out.Magnitude > 0.05 then out.Unit else perp
		-- Leaves spread nearly level (alternately a little up and down); a tip leaf follows its shoot but never stands up.
		local flat = V(dir.X, 0, dir.Z)
		local h = if l.tip then flat + out * 0.6 else perp * 0.8 + out * 0.6 + flat * 0.3
		h = if h.Magnitude > 0.01 then h.Unit else out
		local rise = if l.tip then l.rise + 0.25 else l.rise + (if n % 2 == 0 then 0.28 else -0.16)
		local unit = (h + V(0, 1.6 + (rise - 1.6) * q, 0)).Unit -- unfolds from upright
		local len = l.len * (0.30 + 0.70 * q) * (if proxy then 1.15 else 1)
		local reach = V(p.X + unit.X * len, 0, p.Z + unit.Z * len).Magnitude
		if reach > LIMIT then
			local base = V(p.X, 0, p.Z).Magnitude
			len *= math.clamp((LIMIT - base) / math.max(reach - base, 0.01), 0.4, 1)
		end
		local cf = CFrame.lookAt(p, p + unit) * CFrame.Angles(0, 0, side * 0.22)
		emit("Leaf_" .. n, V(len * 0.62, 0.06, len), cf * CFrame.new(0, 0, -len / 2),
			YOUNG:Lerp(LEAVES[n % 3 + 1], phase(q, 0.3, 1)), phase(q, 0, 0.08), "Foliage", nil, "Studs")
	end
	local d = s.berry
	for k, b in s.bunches do
		local frame = bunchFrame(b, canes[b.cane], g, d, if proxy then 1.40 else 0.95)
		local open = phase(g, b.bloom, b.bloom + 0.06) -- bells open
		local fall = phase(g, b.bloom + 0.12, b.bloom + 0.19) -- petal fall
		local swell = phase(g, b.bloom + 0.18, 0.93)
		local gather = phase(g, b.bloom + 0.16, b.bloom + 0.40) -- hanging raceme -> round bunch
		local turn = phase(g, b.bloom + 0.18, b.bloom + 0.45) -- crowns turn from down to outward
		for j, at in BERRY_AT do
			if proxy and j > 2 then break end
			local ripe = phase(g, 0.72 + 0.022 * j + 0.004 * k, 0.86 + 0.022 * j + 0.004 * k)
			local skin
			if j == b.unripe and b.unripeKind == 1 then
				skin = START:Lerp(GREEN, ripe)
			elseif j == b.unripe and b.unripeKind == 2 then
				skin = START:Lerp(BLUSH, ripe)
			else
				local blue = BLUES[(j + k) % 3 + 1]
				skin = if ripe < 0.5 then START:Lerp(BLUSH, ripe * 2) else BLUSH:Lerp(blue, ripe * 2 - 1)
			end
			local size = V(0.48, 0.48, 0.70):Lerp(V(0.34, 0.34, 0.34), fall):Lerp(V(1, 0.94, 1), swell) * d * open
			local pos = (FLOWER_AT[j]:Lerp(at, gather)) * d
			if proxy then -- two berries stand for the bunch
				size *= 1.4
				pos *= 0.7
			end
			local cf = frame * CFrame.new(pos) * CFrame.Angles(0, (j - 3.5) * 0.10, 0)
				* CFrame.Angles(math.pi / 2 * (1 - turn) + (j % 2 - 0.5) * 0.12, 0, 0)
			emit("Berry_" .. k .. "_" .. j, size, cf, BELL:Lerp(skin, fall), phase(open, 0, 0.1), "Fruit", k)
			if j <= CROWNED and not proxy then
				local cs = size.X * 0.52
				emit("Crown_" .. k .. "_" .. j, V(cs, cs, 0.12 * d * open),
					cf * CFrame.new(0, 0, size.Z / 2 + 0.02 * d) * CFrame.Angles(0, 0, math.pi / 4),
					CALYX:Lerp(CROWN, ripe), fall, "Fruit", k)
			end
		end
	end
end

Kit.recipe(BlueberryPlant, {
	name = "BlueberryPlant",
	parts = 134,
	shape = shape,
	geometry = geometry,
	proxyMid = 0.70,
	onNew = function(self, _, soilCFrame)
		self.fruitSlots = {}
		local canes = {}
		for i, c in self.canes do
			canes[i] = canePoints(c, 1, i == 1)
		end
		for k, b in self.bunches do
			self.fruitSlots[k] = { id = k, attachment = soilCFrame * bunchFrame(b, canes[b.cane], 1, self.berry, 0.95), parts = {} }
		end
	end,
})

return BlueberryPlant
