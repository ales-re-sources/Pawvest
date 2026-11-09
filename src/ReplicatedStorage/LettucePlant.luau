-- CG7 field recipe: selected A, the crisp head (docs/plants/LETTUCE.md).
-- 35 outer + 18 middle + 15 inner leaf plates and 2 head Parts = 70, created once.
-- Leaves unfold at their bases (outer ring first, the inner ring last, cupping into the head); the head swells from the centre.
local LettucePlant = {}
LettucePlant.__index = LettucePlant
LettucePlant.RingHeight = 2.3

local PlantKit = require(script.Parent.PlantKit)
local phase = PlantKit.phase
local V = Vector3.new
local C = Color3.fromRGB
local DARK = C(58, 126, 52)
local MID = C(92, 158, 60)
local LIGHT = C(140, 190, 78)
local PALE = C(158, 202, 90) -- leaf bases and inner leaves: a lighter green, never white
local HEART = C(188, 216, 112) -- the lightest: the heart of the head
local YOUNG = C(160, 205, 95)

-- A leaf is three connected plates in the local YZ plane of its frame (it runs along +Z): the pale rib base, the blade
-- and the tip, with the outline widest in the blade. Elevation falls by `bend` per plate (negative curls the tip in).
local FRACS = { 0.34, 0.40, 0.26 }
local WIDTH = { 0.60, 1.00, 0.85 }
local FOLD = 1.45 -- elevation of a newly emerging, still folded leaf
local MAX_RADIUS = 2.4 -- ground radius target of the 5.5-stud square, every age and size

-- first/step/span: when ring leaf i starts unfolding and how long it takes (growth 0..1).
local RINGS = {
	{ n = 7, elev = 0.6, bend = 0.42, len = 1.8, width = 1.4, radius = 0.2, rise = 0.1, roll = 0.14, frill = true, turn = 0.2, salt = 0,
		first = 0.0, step = 0.04, span = 0.34, colors = { { PALE, DARK, DARK }, { PALE, MID, DARK } } },
	{ n = 6, elev = 0.95, bend = 0.12, len = 1.5, width = 1.25, radius = 0.14, rise = 0.2, roll = 0, frill = false, turn = 0.5, salt = 3,
		first = 0.15, step = 0.045, span = 0.40, colors = { { PALE, MID, MID }, { PALE, LIGHT, MID } } },
	{ n = 5, elev = 1.15, bend = -0.35, len = 1.25, width = 1.05, radius = 0.2, rise = 0.3, roll = 0, frill = false, turn = 0.1, salt = 5,
		first = 0.30, step = 0.05, span = 0.40, colors = { { PALE, LIGHT, HEART } } },
}

-- Frame at the middle of a -> b, in the leaf's YZ plane (X stays sideways), then rolled about its length.
local function plateCF(a: Vector3, b: Vector3, roll: number): CFrame
	local u = (b - a).Unit
	return CFrame.fromMatrix((a + b) / 2, V(-1, 0, 0), V(0, u.Z, -u.Y), V(0, -u.Y, -u.Z)) * CFrame.Angles(0, 0, roll)
end

-- Points of the leaf's centre line (soil-local offsets inside the leaf frame), its width and roll at unfold q / head cup.
local function leafShape(leaf, q: number, cup: number)
	local elev = FOLD + (leaf.elev - FOLD) * q
	local bend = leaf.bend * (if leaf.ring == 3 then cup else q)
	local len = leaf.len * (0.18 + 0.82 * q)
	local points = { V(0, 0, 0) }
	for i = 1, 3 do
		local e = elev - bend * (i - 1)
		points[i + 1] = points[i] + V(0, math.sin(e), math.cos(e)) * (len * FRACS[i])
	end
	return points, leaf.width * (0.30 + 0.70 * q), leaf.roll * q
end

-- emit(slot, size, cf) for plates 1-3 and, when the leaf has them, the two frill plates 4-5 (soil-local).
local function leafGeometry(leaf, q: number, cup: number, emit)
	local points, width, roll = leafShape(leaf, q, cup)
	local lastCF, lastLen
	for i = 1, 3 do
		local a, b = points[i], points[i + 1]
		local length = (b - a).Magnitude
		local cf = leaf.frame * plateCF(a, b, roll)
		emit(i, V(width * WIDTH[i], 0.09, length + 0.03), cf)
		lastCF, lastLen = cf, length
	end
	if leaf.frill then
		local fq = phase(q, 0.6, 1)
		for s, side in { -1, 1 } do
			emit(3 + s, V(width * 0.42, 0.08, lastLen * 0.8) * fq,
				lastCF * CFrame.new(side * width * 0.42, 0.02, -lastLen * 0.42) * CFrame.Angles(0, 0, side * 0.6))
		end
	end
end

local function leafQ(g: number, leaf): number
	local ring = RINGS[leaf.ring]
	local first = ring.first + (leaf.i - 1) * ring.step + leaf.delay
	local q = phase(g, first, first + ring.span)
	-- Two first leaves already show at planting; the others unfold in turn.
	if leaf.ring == 1 and (leaf.i == 1 or leaf.i == 4) then q = 0.18 + 0.82 * q end
	return q
end

local function ripeRadius(leaves): number
	local radius = 0
	for _, leaf in leaves do
		leafGeometry(leaf, 1, 1, function(_, size, cf)
			local h = size / 2
			for sx = -1, 1, 2 do for sy = -1, 1, 2 do for sz = -1, 1, 2 do
				local p = (cf * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position
				radius = math.max(radius, math.sqrt(p.X * p.X + p.Z * p.Z))
			end end end
		end)
	end
	return radius
end

-- Shared seed parameters keep the distance proxy consistent without building the full plant. The `vary` draw order is part
-- of a planting's identity: add new draws last.
local function seededShape(seed, sizeFactor)
	local self = {}
	local vary = PlantKit.seeded(seed)
	local ds = PlantKit.dimension(sizeFactor)
	self.dimensionScale = ds
	local vigor = math.clamp(1 + (ds - 1) * 0.20, 0.94, 1.10)
	self.headScale = ds * (1 + vary(0.12))
	self.leaves, self.byRing = {}, { {}, {}, {} }
	for r, ring in RINGS do
		local spread = 1 + vary(0.08)
		for i = 1, ring.n do
			local j = (i * 37 + ring.salt) % 5 - 2
			local k = (i * 53 + ring.salt) % 7
			local yaw = (i - 1) * (math.pi * 2 / ring.n) + ring.turn + j * 0.06 + vary(0.22)
			local elev = ring.elev + j * 0.05 + vary(0.10)
			local grow = if r == 3 then math.min(ds, 1.25) else vigor
			local len = ring.len * (0.92 + k * 0.025) * (1 + vary(0.12)) * spread * grow
			local width = ring.width * (1 + vary(0.10)) * spread * grow
			local delay = vary(0.02)
			local leaf = {
				ring = r, i = i, yaw = yaw, elev = elev, bend = ring.bend, len = len, width = width, delay = delay,
				roll = ring.roll * (if i % 2 == 0 then 1 else -1), frill = ring.frill,
				colors = ring.colors[(i - 1) % #ring.colors + 1],
				frame = CFrame.new(math.sin(yaw) * ring.radius, ring.rise, math.cos(yaw) * ring.radius) * CFrame.Angles(0, yaw, 0),
			}
			table.insert(self.leaves, leaf)
			self.byRing[r][i] = leaf
		end
	end
	-- Fit the ripe canopy (the widest pose) to the square; leaves grow monotonically outward from the fold.
	for _ = 1, 4 do
		local radius = ripeRadius(self.leaves)
		if radius <= MAX_RADIUS then break end
		local fit = math.max(0.5, (MAX_RADIUS - 0.25) / (radius - 0.25))
		for _, leaf in self.leaves do
			leaf.len *= fit
			leaf.width *= fit
		end
	end
	return self
end

function LettucePlant.new(parent, soilCFrame, seed, sizeFactor)
	local self = setmetatable(seededShape(seed, sizeFactor), LettucePlant)
	local rig = PlantKit.newRig("LettucePlant", soilCFrame)
	self.rig, self.model = rig, rig.model
	self.poses = {}
	for _, leaf in self.leaves do
		for _ = 1, 3 do rig:add("Leaf", nil, "Foliage") end
		if leaf.frill then
			for _ = 1, 2 do rig:add("Frill", nil, "Foliage") end
		end
	end
	rig:add("HeadCore", nil, "Head")
	rig:add("HeadCore", nil, "Head")
	assert(#rig.parts == 70, "Lettuce topology changed")
	self:SetGrowth(0)
	self.model.Parent = parent
	return self
end

function LettucePlant:SetGrowth(normalized)
	local rig = self.rig
	local g = rig:beginPose(normalized)
	if not g then return end
	local cup = phase(g, 0.55, 1)
	for index, leaf in self.leaves do
		local q = leafQ(g, leaf)
		local cupKey = if leaf.ring == 3 then cup else 0
		local old = self.poses[index]
		if old and old.q == q and old.cup == cupKey then
			rig:skip(if leaf.frill then 5 else 3)
		else
			self.poses[index] = { q = q, cup = cupKey }
			local fq = phase(q, 0.6, 1)
			leafGeometry(leaf, q, cup, function(slot, size, cf)
				if slot <= 3 then
					rig:block(size, cf, YOUNG:Lerp(leaf.colors[slot], q), phase(q, 0, 0.08))
				else
					rig:block(size, cf, YOUNG:Lerp(leaf.colors[3], q), phase(fq, 0, 0.08))
				end
			end)
		end
	end
	local h = phase(g, 0.45, 1)
	if self.headPose == h then
		rig:skip(2)
	else
		self.headPose = h
		local scale = self.headScale * (0.25 + 0.75 * h)
		local at = CFrame.new(0, (0.35 + 0.60 * h) * self.headScale, 0)
		rig:block(V(0.75, 1.0, 0.75) * scale, at, YOUNG:Lerp(HEART, h), phase(h, 0, 0.08))
		rig:block(V(0.75, 0.9, 0.75) * scale, at * CFrame.Angles(0, math.pi / 4, 0), YOUNG:Lerp(PALE, h), phase(h, 0, 0.08))
	end
	rig:finish()
end

function LettucePlant:Destroy()
	self.rig:destroy()
end

-- Mid distance: 2 / 9 / 14 Parts. Keep the open outer leaves and the closed head; omit frills and inner detail.
function LettucePlant.BuildProxy(parent, soilCFrame, stage, seed, sizeFactor)
	local shape = seededShape(seed, sizeFactor)
	local g = if stage <= 1 then 0.20 elseif stage == 2 then 0.70 else 1
	local cup = phase(g, 0.55, 1)
	local function leaf(ring, i, pieces)
		local lf = shape.byRing[ring][i]
		local q = leafQ(g, lf)
		local points, width, roll = leafShape(lf, q, cup)
		local function plate(a, b, w, color)
			PlantKit.proxyPart(parent, "Leaf", V(w, 0.09, (b - a).Magnitude + 0.03), soilCFrame * lf.frame * plateCF(a, b, roll),
				color, nil, "Foliage")
		end
		if pieces == 1 then
			plate(points[1], points[4], width * 0.8, YOUNG:Lerp(lf.colors[2], q))
		else
			plate(points[1], points[3], width * 0.85, YOUNG:Lerp(lf.colors[2], q))
			plate(points[3], points[4], width * 0.6, YOUNG:Lerp(lf.colors[3], q))
		end
	end
	local function head(both)
		local h = phase(g, 0.45, 1)
		local scale = shape.headScale * (0.25 + 0.75 * h)
		local at = soilCFrame * CFrame.new(0, (0.35 + 0.60 * h) * shape.headScale, 0)
		PlantKit.proxyPart(parent, "HeadCore", V(0.75, 1.0, 0.75) * scale, at, YOUNG:Lerp(HEART, h), nil, "Head")
		if both then
			PlantKit.proxyPart(parent, "HeadCore", V(0.75, 0.9, 0.75) * scale, at * CFrame.Angles(0, math.pi / 4, 0),
				YOUNG:Lerp(PALE, h), nil, "Head")
		end
	end
	if stage <= 1 then
		leaf(1, 1, 1)
		leaf(1, 4, 1)
	elseif stage == 2 then
		for _, i in { 1, 3, 5, 7 } do leaf(1, i, 2) end
		head(false)
	else
		for _, i in { 1, 2, 4, 5, 7 } do leaf(1, i, 2) end
		for _, i in { 1, 3 } do leaf(3, i, 1) end
		head(true)
	end
end

return LettucePlant
