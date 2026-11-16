-- HX prototype (Studio review only): draws a plant from a PlantGenome instead of a hand-written recipe.
-- GenePlant.recipe(genome) is an ordinary emit-style recipe (PlantKit.recipe): stems extend, branches follow, leaves
-- are born along their stem and unfold, flowers open and drop, fruit swells and ripens. Its Part count is fixed per
-- genome (never per seed) and capped at a budget; every organ is kept inside the radius of the plant's footprint:
-- one field square, or a 2 x 2 block for a big plant (PlantGenome.footprint; recipe.Footprint).
-- GenePlant.cross(a, b) is the review recipe for PlantGrowthReview.OpenCross: seed 1 = parent a, 2-5 = their
-- children, 6 = parent b. The module name matches no crop id, so PlantGrowth and the field never load it.
local GenePlant = {}

local Kit = require(script.Parent.PlantKit)
local Genome = require(script.Parent.PlantGenome)
local phase, V, C = Kit.phase, Vector3.new, Color3.fromRGB
local Y, ZERO = Vector3.yAxis, Vector3.zero

-- By footprint: every Part stays inside the 2.4-stud ground radius of a square, or 5.2 of a 2 x 2 block.
local LIMIT = { 2.28, 5.0 }
local BUDGET = { 140, 400 }
local GOLDEN = 2.39996 -- successive organs turn by the golden angle
local SEED_LEAF, CANE, POST = C(126, 178, 92), C(122, 92, 66), C(150, 116, 82)
local FROST, SPINE = C(225, 240, 250), C(236, 230, 200)

local LEAF_PARTS = { blade = 1, round = 2, lobed = 3, strap = 2, feather = 3, mass = 1 }
local STEM_EXTRA = { smooth = 0, ribbed = 1, spiny = 2, segmented = 1 } -- Parts added to each stem segment
local PATTERNED = { ball = true, tapered = true, cap = true }

local function hsv(h: number, s: number, v: number): Color3
	return Color3.fromHSV(h % 1, math.clamp(s, 0, 1), math.clamp(v, 0, 1))
end

local function flat(p: Vector3): Vector3
	return V(p.X, 0, p.Z)
end

local function compass(yaw: number): Vector3
	return V(math.sin(yaw), 0, math.cos(yaw))
end

-- p pulled towards the plant's axis until it is within `radius` of it.
local function within(p: Vector3, radius: number): Vector3
	local r = flat(p).Magnitude
	if r <= radius or r < 0.0001 then
		return p
	end
	local k = math.max(radius, 0) / r
	return V(p.X * k, p.Y, p.Z * k)
end

-- Point and unit direction at fraction f of a polyline's length.
local function along(pts, f: number)
	local total = 0
	for i = 1, #pts - 1 do
		total += (pts[i + 1] - pts[i]).Magnitude
	end
	local want = total * math.clamp(f, 0, 1)
	for i = 1, #pts - 1 do
		local seg = pts[i + 1] - pts[i]
		local len = seg.Magnitude
		if want <= len or i == #pts - 1 then
			local dir = if len > 0.0001 then seg / len else Y
			return pts[i] + dir * math.min(want, len), dir
		end
		want -= len
	end
	return pts[#pts], Y
end

-- The stem's current polyline: its lower then upper segment extend from the base.
local function stemPoints(c, g: number, first: boolean)
	local q = phase(g, c.start, c.start + 0.50)
	local low = math.max(phase(q, 0, 0.45), if first then 0.07 else 0)
	local p1 = c.base + (c.mid - c.base) * low
	local p2 = p1 + (c.top - c.mid) * phase(q, 0.35, 1)
	return { c.base, p1, p2 }, q
end

-- The fruit's pieces in fruit sizes: { size, offset, tilt = roll about Z, kind }, then its height and width.
-- kind: nil = skin, "cap" (leaf green), "pale", "centre", "pattern", "tuft", "crown", "frost".
local function fruitBody(G, shape: string, pattern: string, extra: string)
	local a, c = G.fruitAspect, G.fruitCurve
	local body, tall, wide
	if shape == "ball" and G.fruitSize >= 0.9 then -- a big ball is ribbed
		body, tall, wide = { { V(0.92, 0.72 * a, 0.92), ZERO }, { V(1.06, 0.62 * a, 0.46), ZERO }, { V(0.46, 0.62 * a, 1.06), ZERO } },
			0.72 * a, 1.06
	elseif shape == "ball" then
		body, tall, wide = { { V(1, 0.94 * a, 1), ZERO } }, 0.94 * a, 1
	elseif shape == "tapered" then
		body, tall, wide = {
			{ V(0.62, 0.8 * a, 0.62), V(0, 0.35 * a, 0) }, { V(0.4, 0.75 * a, 0.4), V(0, -0.4 * a, 0) },
			{ V(0.5, 0.14, 0.5), V(0, 0.75 * a + 0.07, 0), kind = "cap" },
		}, 1.65 * a, 0.62
	elseif shape == "pod" then
		body, tall, wide = {
			{ V(0.36, 0.56 * a, 0.36), ZERO }, { V(0.34, 0.56 * a, 0.34), V(0.2 * c * a, 0.5 * a, 0), tilt = -0.4 * c },
			{ V(0.3, 0.56 * a, 0.3), V(0.2 * c * a, -0.5 * a, 0), tilt = 0.4 * c },
		}, 1.6 * a, 0.36 + 0.5 * c * a
	elseif shape == "cluster" then
		body, tall, wide = {
			{ V(0.5, 0.5, 0.5), V(-0.27, 0.02, 0.2) }, { V(0.5, 0.5, 0.5), V(0.27, -0.04, 0.2) },
			{ V(0.5, 0.5, 0.5), V(0, -0.32, 0.16) }, { V(0.5, 0.5, 0.5), V(0, 0.3, 0.14) },
			{ V(0.5, 0.5, 0.5), V(0, -0.02, -0.2) },
		}, 1.3, 1.1
	elseif shape == "head" then
		body, tall, wide = { { V(1, 0.36, 1), V(0, -0.24, 0) }, { V(0.8, 0.36, 0.8), V(0, 0.08, 0) }, { V(0.5, 0.3, 0.5), V(0, 0.38, 0) } },
			0.9, 1
	elseif shape == "cap" then
		body, tall, wide = {
			{ V(1, 0.34, 1), V(0, 0.1, 0) }, { V(0.68, 0.26, 0.68), V(0, 0.38, 0) },
			{ V(0.78, 0.1, 0.78), V(0, -0.1, 0), kind = "pale" },
		}, 0.7, 1
	else -- bloom: a dark centre and four petals
		body, tall, wide = {
			{ V(0.42, 0.22, 0.42), ZERO, kind = "centre" }, { V(0.5, 0.08, 0.36), V(0.44, 0, 0) },
			{ V(0.5, 0.08, 0.36), V(-0.44, 0, 0) }, { V(0.36, 0.08, 0.5), V(0, 0, 0.44) }, { V(0.36, 0.08, 0.5), V(0, 0, -0.44) },
		}, 0.25, 1.38
	end
	local size, at = body[1][1], body[1][2]
	if PATTERNED[shape] and pattern == "stripes" then
		table.insert(body, { V(size.X * 1.04, size.Y * 0.9, size.X * 0.16), at, kind = "pattern" })
		table.insert(body, { V(size.X * 0.16, size.Y * 0.9, size.X * 1.04), at, kind = "pattern" })
	elseif PATTERNED[shape] and pattern == "spots" then
		local dot = V(1, 1, 1) * size.X * 0.22
		table.insert(body, { dot, at + V(size.X / 2, size.Y * 0.12, size.X * 0.12), kind = "pattern" })
		table.insert(body, { dot, at + V(-size.X * 0.15, size.Y * 0.15, size.X / 2), kind = "pattern" })
		table.insert(body, { dot, at + V(size.X * 0.1, size.Y / 2, -size.X * 0.15), kind = "pattern" })
	end
	if extra == "husk" then
		table.insert(body, { V(wide * 0.75, 0.2, wide * 0.75), V(0, tall / 2 + 0.06, 0), kind = "cap" })
	elseif extra == "tuft" then
		for side = -1, 1 do
			table.insert(body, { V(0.16, 0.6, 0.16), V(side * 0.14, tall / 2 + 0.28, 0), tilt = -side * 0.5, kind = "tuft" })
		end
	elseif extra == "crown" then
		table.insert(body, { V(0.3, 0.1, 0.3), V(0, -tall / 2 - 0.04, 0), kind = "crown" })
	elseif extra == "frost" then
		table.insert(body, { V(wide * 1.05, 0.14, wide * 1.05), V(0, tall / 2, 0), kind = "frost" })
	end
	return body, tall, wide
end

-- How many of each organ the genome gets inside the Part budget (leaves give way first, fruit and stems last).
local function layout(G, footprint: number, fruitParts: number)
	local p = {
		stems = G.stems, branches = G.branches, leafCount = G.leafCount, basal = math.round(G.basal * 10),
		leafShape = Genome.pick(G, "leafShape"), stemStyle = Genome.pick(G, "stemStyle"),
	}
	-- Big fruit come few to a plant.
	p.fruits = math.min(G.fruitCount, math.max(1, math.floor((if footprint == 2 then 24 else 5) / (G.fruitSize * G.fruitSize))))
	p.supports = 0
	if G.height * G.bulk > 1.6 and G.spread < 0.5 then
		local support = Genome.pick(G, "support")
		p.supports = if support == "stake" then 1 elseif support == "trellis" then 3 else 0
	end
	local function parts()
		local leaves = p.stems * (p.leafCount + p.branches) + p.basal
		return 2 + p.stems * (2 * (1 + STEM_EXTRA[p.stemStyle]) + p.branches) + leaves * LEAF_PARTS[p.leafShape]
			+ p.fruits * (1 + fruitParts) + p.supports
	end
	while parts() > BUDGET[footprint] do
		if p.leafCount > 2 then
			p.leafCount -= 1
		elseif p.basal > 4 then
			p.basal -= 1
		elseif p.branches > 0 then
			p.branches -= 1
		elseif p.fruits > 1 then
			p.fruits -= 1
		elseif p.leafCount > 0 then
			p.leafCount -= 1
		elseif p.basal > 0 then
			p.basal -= 1
		elseif p.stems > 1 then
			p.stems -= 1
		else
			break
		end
	end
	p.parts = parts()
	return p
end

function GenePlant.recipe(G)
	local footprint = Genome.footprint(G)
	local R = LIMIT[footprint]
	local scale = R / LIMIT[1] -- lengths that are fitted to the square grow with the footprint
	local fruitShape = Genome.pick(G, "fruitShape")
	local extra = Genome.pick(G, "extra")
	local body, bodyH, bodyW = fruitBody(G, fruitShape, Genome.pick(G, "pattern"), extra)
	local p = layout(G, footprint, #body)
	local bulk = G.bulk
	local stemW = G.stemWidth * bulk
	local stemExtra = STEM_EXTRA[p.stemStyle]
	local stemMargin = stemW * (if p.stemStyle == "spiny" then 1.15 else 0.75)
	local stemReach = math.max(0.877 * R - stemMargin, 0.1)
	local leafW = G.leafWidth
	local leafHalf = if p.leafShape == "lobed" then 0.38 + 0.2 * leafW else leafW * 0.5 -- of its length
	local buried = G.fruitAt < 0
	local terminal = G.fruitAt >= 0.97 and G.fruitHang < 0.35
	local plain = buried or fruitShape == "head" or fruitShape == "cap" or fruitShape == "bloom" -- no flower first
	local hang = G.fruitHang
	local trained = p.supports == 3 and G.climb > 0

	local leafValue = 0.42 + 0.30 * G.leafTone
	local leaves = {
		hsv(G.leafHue, G.leafSat, leafValue),
		hsv(G.leafHue - 0.035 * G.leafVary, G.leafSat * 0.96, leafValue + 0.10 * G.leafVary),
		hsv(G.leafHue + 0.045 * G.leafVary, G.leafSat * 0.92, leafValue - 0.07 * G.leafVary),
	}
	local young = hsv(G.leafHue - 0.02, G.leafSat * 0.88, math.min(leafValue + 0.16, 0.9))
	local shoot = hsv(G.stemHue, G.stemSat, G.stemTone)
	local wood = shoot:Lerp(CANE, G.wood)
	local unripe = hsv(G.unripeHue, 0.34, 0.80)
	local ripeSkin = hsv(G.ripeHue, G.ripeSat, G.ripeVal)
	local flower = hsv(G.flowerHue, 0.22, 0.97)
	local kindColor = {
		cap = leaves[1], tuft = leaves[2], pale = hsv(G.ripeHue, 0.1, 0.95), centre = hsv(G.ripeHue + 0.06, 0.75, 0.35),
		pattern = hsv(G.patternHue, G.patternSat, 0.92), crown = hsv(G.ripeHue, 0.5, 0.28), frost = FROST,
	}

	local function shape(seed, sizeFactor)
		local vary, ds = Kit.seeded(seed), Kit.dimension(sizeFactor)
		local vigor = math.clamp(1 + (ds - 1) * 0.20, 0.93, 1.08)
		local s = { stems = {}, branches = {}, leaves = {}, fruits = {} }
		s.d = math.min(G.fruitSize * ds, 1.36 * R / bodyW)
		local n = p.stems
		local leanTo = compass(0.6)
		for i = 1, n do
			local yaw = (i - 1) * math.pi * 2 / n + 0.25 + vary(0.18)
			local out = compass(yaw)
			local tilt = G.spread * 1.45 * (if n > 1 then 0.75 + 0.25 * (i % 2) else 1) + vary(0.05)
			local length = G.height * bulk * vigor * (1 + vary(0.07)) * (if n > 1 then 1 - 0.06 * (i * 7 % 3) else 1)
			local t1 = math.max(tilt - G.arch * 0.5, 0)
			local t2 = math.min(tilt + G.arch * 0.9, 1.75)
			local reach = length / 2 * (math.sin(t1) + math.sin(t2))
			local most = math.max((if n == 1 then 1.58 else 0.83) * R - stemMargin, 0.1)
			if reach > most then
				length *= most / reach
				reach = most
			end
			-- One sprawling stem crosses the whole footprint; several start together at its middle.
			local base = if n == 1 then -out * reach * 0.5 else out * math.min(0.10 + stemW * 0.3, stemReach)
			local floor = stemW / 2 + 0.03
			local mid = base + (out * math.sin(t1) + Y * math.cos(t1)) * length / 2 + leanTo * G.lean * length * 0.15
			local top = mid + (out * math.sin(t2) + Y * math.cos(t2)) * length / 2 + leanTo * G.lean * length * 0.35
			if trained then -- the shoot is led to its place on the trellis rail
				local rail = V(((i - 0.5) / n - 0.5) * 3.2 * scale, G.height * bulk * 0.88, 0)
				top = top:Lerp(rail, G.climb)
				mid = mid:Lerp(V(rail.X * 0.5, mid.Y, 0), G.climb * 0.6)
			end
			mid = within(V(mid.X, math.max(mid.Y, floor), mid.Z), stemReach)
			top = within(V(top.X, math.max(top.Y, floor), top.Z), stemReach)
			s.stems[i] = {
				start = (i - 1) * math.min(0.05, 0.2 / math.max(n - 1, 1)),
				yaw = yaw, base = base, mid = mid, top = top,
			}
		end
		for i, c in s.stems do
			local pts = { c.base, c.mid, c.top }
			local upper = c.top - c.mid
			upper = if upper.Magnitude > 0.01 then upper.Unit else Y
			for b = 1, p.branches do
				local frac = if p.branches == 1 then G.branchAt else G.branchAt + (0.95 - G.branchAt) * (b - 1) / (p.branches - 1)
				local away = (compass(c.yaw + b * GOLDEN + i) * 0.9 + Y * 0.3).Unit
				local angle = G.branchAngle + vary(0.12)
				local from = along(pts, math.clamp(frac, 0.2, 1))
				local vec = (upper * math.cos(angle) + away * math.sin(angle)) * (c.top - c.base).Magnitude * 0.42 * (1 + vary(0.10))
				for _ = 1, 6 do
					if flat(from + vec).Magnitude <= 0.9 * R then
						break
					end
					vec *= 0.75
				end
				if from.Y + vec.Y < 0.12 then
					vec = V(vec.X, 0.12 - from.Y, vec.Z)
				end
				table.insert(s.branches, { stem = i, frac = math.clamp(frac, 0.2, 1), vec = vec })
			end
		end
		local leafLen = G.leafLen * math.sqrt(bulk) * vigor
		for i, c in s.stems do
			for j = 1, p.leafCount do
				local frac = if p.leafCount == 1 then 1 else G.leafFrom + (1 - G.leafFrom) * (j - 1) / (p.leafCount - 1)
				table.insert(s.leaves, {
					stem = i, frac = frac, yaw = c.yaw + j * GOLDEN + vary(0.3),
					len = leafLen * (1 + vary(0.10)) * (1.1 - 0.25 * frac), rise = 0.9 - G.droop * 1.3 + vary(0.12),
				})
			end
		end
		for k, b in s.branches do
			table.insert(s.leaves, {
				branch = k, yaw = s.stems[b.stem].yaw + k * GOLDEN + vary(0.3),
				len = leafLen * 0.85 * (1 + vary(0.10)), rise = 0.9 - G.droop * 1.3 + vary(0.12),
			})
		end
		for j = 1, p.basal do
			local yaw = j * GOLDEN + vary(0.25)
			local inner = (j - 1) / math.max(p.basal - 1, 1) -- later leaves stand at the heart
			table.insert(s.leaves, {
				basal = true, yaw = yaw, at = compass(yaw) * 0.08 + Y * 0.04, born = 0.02 + 0.30 * inner,
				len = leafLen * (1 - 0.3 * inner) * (1 + vary(0.08)), rise = 0.9 - G.droop * 1.3 + 0.5 * inner + vary(0.10),
			})
		end
		-- Fruit go round the stems, then the branches, and spread along each host around `fruitAt`.
		local hosts = n + #s.branches
		local rounds = math.ceil(p.fruits / hosts)
		for k = 1, p.fruits do
			local host, round = (k - 1) % hosts + 1, (k - 1) // hosts
			local branch = if host > n then host - n else nil
			local stem = if branch then s.branches[branch].stem else host
			local shift = (round - (rounds - 1) / 2) * math.min(0.22, 0.6 / rounds)
			local f = {
				stem = stem, branch = branch, yaw = s.stems[stem].yaw + k * GOLDEN + vary(0.25),
				frac = math.clamp((if branch then 0.4 + 0.6 * G.fruitAt else G.fruitAt) + shift + vary(0.04), 0.15, 1),
				bloom = G.bloomAt + 0.006 * k + vary(0.012),
				ripeAt = 0.70 + G.ripenSpread * (k - 1) / math.max(p.fruits - 1, 1),
			}
			if buried then
				f.depth = -G.fruitAt / 0.3
				f.at = if p.fruits == 1 then ZERO else compass(f.yaw) * math.min(0.9 * scale, s.d * 0.8)
			elseif terminal then
				f.frac = 1 - 0.25 * round
			end
			s.fruits[k] = f
		end
		-- Append future variation draws here to preserve planting identity.
		return s
	end

	local function emitLeaf(emit, name, at, unit, level, len, q, color, opacity, proxy)
		local up = if math.abs(unit.Y) > 0.98 then level else Y
		local cf = CFrame.lookAt(at, at + unit, up)
		local width = len * leafW
		if p.leafShape == "mass" then
			emit(name, V(width, len * 0.45, len * 0.9), cf * CFrame.new(0, 0, -len * 0.45), color, opacity, "Foliage", nil, "Studs")
		elseif proxy or p.leafShape == "blade" then
			emit(name, V(width, 0.09, len), cf * CFrame.new(0, 0, -len / 2), color, opacity, "Foliage", nil, "Studs")
		elseif p.leafShape == "round" then
			emit(name .. "_Stalk", V(0.09, 0.09, len * 0.4), cf * CFrame.new(0, 0, -len * 0.2), young, opacity, "Foliage")
			emit(name, V(width, 0.09, len * 0.65), cf * CFrame.new(0, 0, -len * 0.675), color, opacity, "Foliage", nil, "Studs")
		elseif p.leafShape == "strap" then
			local bend = (0.35 + 0.7 * math.max(G.droop, 0)) * q
			local tip = cf * CFrame.new(0, 0, -len * 0.55) * CFrame.Angles(-bend, 0, 0)
			emit(name, V(width, 0.09, len * 0.55), cf * CFrame.new(0, 0, -len * 0.275), color, opacity, "Foliage", nil, "Studs")
			emit(name .. "_Tip", V(width * 0.7, 0.08, len * 0.45), tip * CFrame.new(0, 0, -len * 0.225), color, opacity, "Foliage", nil, "Studs")
		elseif p.leafShape == "lobed" then
			emit(name, V(width * 0.7, 0.09, len), cf * CFrame.new(0, 0, -len / 2), color, opacity, "Foliage", nil, "Studs")
			for side = -1, 1, 2 do
				local lobe = cf * CFrame.new(0, 0, -len * 0.4) * CFrame.Angles(0, side * 0.75, 0) * CFrame.new(0, 0, -len * 0.27)
				emit(name .. (if side < 0 then "_L" else "_R"), V(width * 0.55, 0.08, len * 0.55), lobe, color, opacity, "Foliage", nil, "Studs")
			end
		else -- feather: a midrib with two pairs of leaflets
			emit(name, V(0.09, 0.09, len), cf * CFrame.new(0, 0, -len / 2), young, opacity, "Foliage")
			emit(name .. "_A", V(width, 0.08, len * 0.26), cf * CFrame.new(0, 0, -len * 0.5), color, opacity, "Foliage", nil, "Studs")
			emit(name .. "_B", V(width * 0.65, 0.08, len * 0.24), cf * CFrame.new(0, 0, -len * 0.84), color, opacity, "Foliage", nil, "Studs")
		end
	end

	-- Returns the highest point drawn (the review framing and ring height use it at full growth).
	local function geometry(s, g, emit, proxy)
		local peak = 0
		local stems, grown = {}, {}
		for i, c in s.stems do
			stems[i], grown[i] = stemPoints(c, g, i == 1)
			peak = math.max(peak, stems[i][3].Y)
		end
		-- Seed leaves on the first shoot, folded at 0 %, open by 10 %, gone by 40 %.
		local sprout = stems[1][2]
		for i = 1, 2 do
			local open = phase(g, 0, 0.10)
			local yaw = 0.25 + (i - 1) * math.pi
			local q = 0.55 + 0.45 * open
			emit("SeedLeaf_" .. i, V(0.24, 0.05, 0.30) * q,
				CFrame.new(sprout + compass(yaw) * 0.13 * q) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(-1.1 + 0.85 * open, 0, 0),
				SEED_LEAF, 1 - phase(g, 0.24, 0.40), "Foliage")
		end
		for i, c in s.stems do
			local pts, q = stems[i], grown[i]
			local bark = shoot:Lerp(wood, phase(g, c.start + 0.25, c.start + 0.70))
			local width = 0.05 + (stemW - 0.05) * phase(g, c.start, 0.90)
			local opacity = if i == 1 then 1 else phase(q, 0, 0.04)
			for j = 1, 2 do
				local a, b = pts[j], pts[j + 1]
				local len = (b - a).Magnitude
				local w = width * (if j == 1 then 1 else 0.68)
				local shown = if len > 0.005 then opacity else 0
				local cf = Kit.axis(a, b)
				emit("Stem_" .. i .. "_" .. j, V(w, w, len + 0.025), cf, bark, shown, "Structure")
				if proxy or stemExtra == 0 then
					continue
				end
				if p.stemStyle == "ribbed" then
					emit("Rib_" .. i .. "_" .. j, V(w * 0.94, w * 0.94, len + 0.02), cf * CFrame.Angles(0, 0, math.pi / 4),
						bark:Lerp(Color3.new(0, 0, 0), 0.08), shown, "Structure")
				elseif p.stemStyle == "segmented" then
					emit("Node_" .. i .. "_" .. j, V(w * 1.3, w * 1.3, 0.12), cf * CFrame.new(0, 0, -len / 2),
						bark:Lerp(Color3.new(0, 0, 0), 0.12), shown, "Structure")
				else -- spiny
					local spine = if len > 0.3 then shown * phase(g, c.start + 0.3, c.start + 0.6) else 0
					emit("Spine_" .. i .. "_" .. j .. "a", V(w * 2.2, 0.06, 0.06), cf * CFrame.new(0, 0, len / 6), SPINE, spine, "Structure")
					emit("Spine_" .. i .. "_" .. j .. "b", V(0.06, w * 2.2, 0.06), cf * CFrame.new(0, 0, -len / 6), SPINE, spine, "Structure")
				end
			end
		end
		local twigs = {}
		for k, b in s.branches do
			local c = s.stems[b.stem]
			local q = phase(g, c.start + 0.22, c.start + 0.55)
			local a = along(stems[b.stem], b.frac)
			local e = a + b.vec * q
			twigs[k] = { a, e }
			peak = math.max(peak, e.Y)
			local w = math.max(stemW * 0.5, 0.07) * (0.4 + 0.6 * phase(g, c.start + 0.22, 0.90))
			emit("Branch_" .. k, V(w, w, (e - a).Magnitude + 0.025), Kit.axis(a, e), shoot:Lerp(wood, phase(g, 0.45, 0.85)),
				phase(q, 0, 0.05), "Structure")
		end
		local thin = proxy and #s.leaves > 10
		for n, l in s.leaves do
			if thin and n % 2 == 0 then
				continue
			end
			local at, born, span
			if l.basal then
				at, born, span = l.at, l.born, 0.40
			elseif l.stem then
				at, born, span = along(stems[l.stem], l.frac), s.stems[l.stem].start + l.frac * 0.42, 0.16
			else
				at, born, span = twigs[l.branch][2], s.stems[s.branches[l.branch].stem].start + 0.52, 0.16
			end
			local q = phase(g, born, born + span)
			local level = compass(l.yaw)
			local radial = flat(at)
			local r0 = radial.Magnitude
			if p.stems > 1 and r0 > 0.05 then -- a bush shows its leaves outward
				level = level + radial.Unit * 0.8
				level = if level.Magnitude > 0.05 then level.Unit else radial.Unit
			end
			if r0 > 0.526 * R then -- near the edge of the footprint a leaf turns back in
				level = level - radial.Unit * math.min((r0 - 0.526 * R) / (0.35 * R), 1) * 1.6
				level = if level.Magnitude > 0.05 then level.Unit else -radial.Unit
			end
			local len = l.len * (0.30 + 0.70 * q) * (if proxy then 1.12 else 1)
			local rise = 1.35 + (l.rise - 1.35) * q -- unfolds from upright
			local lift = math.sin(rise)
			if at.Y + lift * len < 0.07 then -- never through the soil
				lift = (0.07 - at.Y) / len
			end
			local unit = (level * math.cos(rise) + Y * lift).Unit
			local across = unit:Cross(if math.abs(unit.Y) > 0.98 then level else Y).Unit
			for _ = 1, 10 do -- shorten (and so narrow) a leaf whose corners would leave the footprint
				local half, tip = across * len * leafHalf, at + unit * len
				if math.max(flat(at + half).Magnitude, flat(at - half).Magnitude, flat(tip + half).Magnitude,
					flat(tip - half).Magnitude) <= R - 0.08 then
					break
				end
				len *= 0.82
			end
			peak = math.max(peak, at.Y + unit.Y * len)
			emitLeaf(emit, "Leaf_" .. n, at, unit, level, len, q, young:Lerp(leaves[n % 3 + 1], phase(q, 0.3, 1)),
				phase(q, 0, 0.08), proxy)
		end
		local d = s.d
		local bloomSize = 0.26 + 0.08 * math.min(d, 1.5)
		local keep = if fruitShape == "cluster" then 2 elseif fruitShape == "bloom" then 5 else 1 -- the proxy's share of a fruit
		for k, f in s.fruits do
			local open, fall, swell
			if plain then
				open, fall, swell = phase(g, 0.26, 0.32), 1, phase(g, 0.30, 0.93)
			else
				open = phase(g, f.bloom, f.bloom + 0.06) -- the flower opens
				fall = phase(g, f.bloom + 0.12, f.bloom + 0.19) -- petal fall
				swell = phase(g, f.bloom + 0.18, 0.93)
			end
			local ripe = phase(g, f.ripeAt, f.ripeAt + 0.14)
			local dd = d * (0.3 + 0.7 * swell)
			local tall = bodyH * dd
			local attach, centre = ZERO, nil
			if buried then
				-- The shoulder shows at the soil; the rest swells below it.
				centre = V(f.at.X, tall + (0.16 * dd - tall) * f.depth - tall / 2, f.at.Z)
			else
				local dir
				if f.branch then
					local twig = twigs[f.branch]
					local run = twig[2] - twig[1]
					attach, dir = twig[1] + run * f.frac, if run.Magnitude > 0.001 then run.Unit else Y
				else
					attach, dir = along(stems[f.stem], f.frac)
				end
				if terminal then
					centre = attach + dir * tall * 0.5
				else
					centre = attach + compass(f.yaw) * (0.10 + 0.5 * bodyW * dd * (1 - hang) + 0.12 * dd * hang)
						- Y * hang * (tall * 0.5 + 0.12) * fall
				end
				centre = V(centre.X, math.max(centre.Y, tall * 0.5 + 0.02), centre.Z) -- rests on the soil
			end
			centre = within(centre, R - dd * bodyW * 0.71)
			peak = math.max(peak, centre.Y + tall * 0.5)
			local top = centre + Y * tall * 0.5
			local stalk = (top - attach).Magnitude
			emit("Stalk_" .. k, V(0.09, 0.09, stalk + 0.02), Kit.axis(attach, top), shoot,
				if buried or terminal or stalk < 0.06 then 0 else open, "Structure")
			local frame = CFrame.new(centre) * CFrame.Angles(0, f.yaw, 0)
			local skin = unripe:Lerp(ripeSkin, ripe)
			for j, piece in body do
				local kind = piece.kind
				if proxy and (j > keep or (kind ~= nil and kind ~= "centre")) then
					continue
				end
				local size, at = piece[1] * dd, piece[2] * dd
				if proxy and fruitShape == "cluster" then
					size, at = size * 1.4, at * 0.7
				end
				local color = if kind then kindColor[kind] elseif j % 2 == 0 then skin:Lerp(Color3.new(0, 0, 0), 0.06) else skin
				local opacity = if kind == "frost" then 0.8 * ripe elseif plain then open else fall
				if j == 1 and not plain then -- the first piece is the flower until its petals fall
					size = (V(bloomSize, bloomSize, bloomSize) * (0.3 + 0.7 * open)):Lerp(size, fall)
					at *= fall
					color = flower:Lerp(color, fall)
					opacity = phase(open, 0, 0.1)
				end
				local cf = frame * CFrame.new(at)
				if piece.tilt then
					cf *= CFrame.Angles(0, 0, piece.tilt)
				end
				emit("Fruit_" .. k .. "_" .. j, size, cf, color, opacity, "Fruit", k)
			end
		end
		return peak
	end

	-- Rigid supports stand full size from planting, as tall as the mature plant.
	local supports = {}
	local count, peak = 0, 0
	peak = geometry(shape(1, 1), 1, function()
		count += 1
	end, false)
	if p.supports == 1 then
		supports[1] = { name = "Stake", size = V(0.14, peak * 0.92, 0.14), cf = CFrame.new(-0.2 - stemW / 2, peak * 0.46, -0.2), color = POST }
	elseif p.supports == 3 then
		local tall, x = peak * 0.95, 1.9 * scale
		supports[1] = { name = "Post_1", size = V(0.16, tall, 0.16), cf = CFrame.new(-x, tall / 2, 0), color = POST }
		supports[2] = { name = "Post_2", size = V(0.16, tall, 0.16), cf = CFrame.new(x, tall / 2, 0), color = POST }
		supports[3] = { name = "Rail", size = V(x * 2 + 0.16, 0.12, 0.12), cf = CFrame.new(0, tall - 0.06, 0), color = POST }
	end
	assert(count + #supports == p.parts, "GenePlant part count")

	local Plant = { Draft = true, Genome = G, Parts = p.parts, Peak = peak, Footprint = footprint }
	Plant.RingHeight = peak + 0.8
	Plant.FixedRingHeight = true
	if peak > 3.2 then
		Plant.ReviewHeight = peak + 0.4
	end
	return Kit.recipe(Plant, {
		name = "GenePlant",
		parts = p.parts,
		shape = shape,
		geometry = geometry,
		proxyMid = 0.70,
		supports = supports,
		-- A glowing crop lights up as it ripens.
		onPart = if extra == "glow" then function(part, role, g)
			if role == "Fruit" then
				local material = if g >= 0.85 then Enum.Material.Neon else Enum.Material.Plastic
				if part.Material ~= material then
					part.Material = material
				end
			end
		end else nil,
	})
end

local function genomeOf(parent)
	if type(parent) == "string" then
		return assert(Genome.Presets[parent], "No genome preset for " .. parent)
	end
	return parent
end

-- A review recipe over up to six genomes: seed i draws genome i (other seeds wrap). `reference[i]` = show that one
-- in its reference pose (planting seed 1); the others keep their own planting variation.
function GenePlant.row(genomes, reference)
	local recipes = {}
	local Row = { Draft = true, Genomes = genomes, Recipes = recipes, FixedRingHeight = true, RingHeight = 0, ReviewHeight = 0, Footprint = 1 }
	for i, genome in genomes do
		recipes[i] = GenePlant.recipe(genome)
		Row.RingHeight = math.max(Row.RingHeight, recipes[i].RingHeight)
		Row.ReviewHeight = math.max(Row.ReviewHeight, recipes[i].Peak + 0.4)
		Row.Footprint = math.max(Row.Footprint, recipes[i].Footprint) -- one big plant puts the whole row on blocks
	end
	local function pick(seed: number?)
		local index = (math.floor(seed or 1) - 1) % #genomes + 1
		return recipes[index], if reference and reference[index] then 1 else index
	end
	function Row.new(parent: Instance, soilCFrame: CFrame, seed: number, sizeFactor: number?)
		local recipe, planting = pick(seed)
		return recipe.new(parent, soilCFrame, planting, sizeFactor)
	end
	function Row.BuildProxy(parent: Instance, soilCFrame: CFrame, stage: number, seed: number?, sizeFactor: number?)
		local recipe, planting = pick(seed)
		recipe.BuildProxy(parent, soilCFrame, stage, planting, sizeFactor)
	end
	return Row
end

-- The review recipe of one cross: seed 1 = parent a, seeds 2-5 = four children, seed 6 = parent b.
-- Parents are preset ids or genomes; `crossSeed` picks another set of children.
function GenePlant.cross(a, b, mutagens: { string }?, crossSeed: number?)
	local first, last = genomeOf(a), genomeOf(b)
	local genomes = { first }
	for i = 2, 5 do
		genomes[i] = Genome.cross(first, last, Random.new((crossSeed or 1) * 1000 + i), mutagens)
	end
	genomes[6] = last
	return GenePlant.row(genomes, { [1] = true, [6] = true })
end

-- The review recipe of up to six presets side by side, each in its reference pose.
function GenePlant.presets(ids: { string })
	local genomes, reference = {}, {}
	for i, id in ids do
		genomes[i], reference[i] = genomeOf(id), true
	end
	return GenePlant.row(genomes, reference)
end

return GenePlant
