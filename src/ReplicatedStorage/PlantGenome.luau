-- HX prototype (Studio review only, no saved data): the genome of a generated plant and how two genomes cross.
-- A genome is a table gene id -> number; a pick gene stores the index of its option. GenePlant draws a genome.
-- The gene table is free to change until a genome is stored anywhere; from then on it is append-only: a new gene's
-- `default` must leave every older plant unchanged. Read genes by id, never by position.
local CropConfig = require(script.Parent.CropConfig)

local PlantGenome = {}

-- kind: "num" (min..max), "int" (whole, min..max), "hue" (0..1, wraps), "pick" (options). `log` blends in log space.
local GENES = {
	-- Architecture: one continuous space from a rosette to a bush, a creeper, a root crop and a tree.
	{ id = "stems", kind = "int", min = 1, max = 12, default = 1 },
	{ id = "height", kind = "num", min = 0.3, max = 7, default = 2.5 }, -- stem length in studs, before `bulk`
	{ id = "spread", kind = "num", min = 0, max = 1, default = 0.1 }, -- 0 upright ... 1 along the ground
	{ id = "arch", kind = "num", min = 0, max = 1, default = 0.2 }, -- how far the stem bends over
	{ id = "lean", kind = "num", min = 0, max = 0.5, default = 0 },
	{ id = "branches", kind = "int", min = 0, max = 4, default = 0 }, -- per stem
	{ id = "branchAngle", kind = "num", min = 0.3, max = 1.3, default = 0.8 },
	{ id = "branchAt", kind = "num", min = 0.3, max = 1, default = 0.5 }, -- where the first branch leaves the stem
	{ id = "wood", kind = "num", min = 0, max = 1, default = 0.2 }, -- stem colour ... brown bark
	{ id = "stemWidth", kind = "num", min = 0.1, max = 0.9, default = 0.2 },
	{ id = "support", kind = "pick", options = { "none", "stake", "trellis" }, default = 1 },
	{ id = "climb", kind = "num", min = 0, max = 1, default = 0 }, -- how far the stems follow a trellis rail
	-- Overall size of stems and leaves. From WIDE_BULK up the plant takes a 2 x 2 block of squares.
	{ id = "bulk", kind = "num", min = 0.6, max = 2.2, default = 1 },
	{ id = "stemHue", kind = "hue", default = 0.24 },
	{ id = "stemSat", kind = "num", min = 0, max = 1, default = 0.48 },
	{ id = "stemTone", kind = "num", min = 0.2, max = 1, default = 0.62 },
	{ id = "stemStyle", kind = "pick", options = { "smooth", "ribbed", "spiny", "segmented" }, default = 1 },
	-- Leaves
	{ id = "leafShape", kind = "pick", options = { "blade", "round", "lobed", "strap", "feather", "mass" }, default = 1 },
	{ id = "leafLen", kind = "num", min = 0.4, max = 2.2, default = 1 },
	{ id = "leafWidth", kind = "num", min = 0.1, max = 1, default = 0.6 }, -- of the length
	{ id = "leafCount", kind = "int", min = 0, max = 6, default = 4 }, -- per stem
	{ id = "leafFrom", kind = "num", min = 0, max = 0.9, default = 0.32 }, -- how much of the stem stays bare
	{ id = "basal", kind = "num", min = 0, max = 1, default = 0 }, -- size of the ground rosette (x10 leaves)
	{ id = "droop", kind = "num", min = -0.3, max = 1, default = 0.3 }, -- upright ... hanging
	{ id = "leafHue", kind = "hue", default = 0.3 },
	{ id = "leafSat", kind = "num", min = 0, max = 1, default = 0.54 },
	{ id = "leafTone", kind = "num", min = 0, max = 1, default = 0.45 }, -- dark ... light
	{ id = "leafVary", kind = "num", min = 0, max = 1, default = 0.5 },
	-- Fruit (whatever the plant is grown for: a fruit, a root, a head, a cap, a bloom)
	{ id = "fruitShape", kind = "pick", options = { "ball", "tapered", "cluster", "head", "pod", "cap", "bloom" }, default = 1 },
	{ id = "fruitSize", kind = "num", min = 0.25, max = 2.6, default = 0.6 },
	{ id = "fruitAspect", kind = "num", min = 0.5, max = 2.5, log = true, default = 1 }, -- squat ... long
	{ id = "fruitCurve", kind = "num", min = 0, max = 1, default = 0 }, -- a pod's bend
	{ id = "fruitCount", kind = "int", min = 1, max = 12, default = 4 },
	{ id = "fruitAt", kind = "num", min = -0.3, max = 1, default = 0.6 }, -- buried ... stem tip
	{ id = "fruitHang", kind = "num", min = 0, max = 1, default = 0.5 },
	{ id = "unripeHue", kind = "hue", default = 0.25 },
	{ id = "ripeHue", kind = "hue", default = 0 },
	{ id = "ripeSat", kind = "num", min = 0, max = 1, default = 0.8 },
	{ id = "ripeVal", kind = "num", min = 0.25, max = 1, default = 0.85 },
	{ id = "pattern", kind = "pick", options = { "none", "stripes", "spots" }, default = 1 },
	{ id = "patternHue", kind = "hue", default = 0.3 },
	{ id = "patternSat", kind = "num", min = 0, max = 1, default = 0.5 },
	{ id = "extra", kind = "pick", options = { "none", "crown", "glow", "frost", "husk", "tuft" }, default = 1 },
	-- Timing
	{ id = "bloomAt", kind = "num", min = 0.3, max = 0.6, default = 0.42 },
	{ id = "flowerHue", kind = "hue", default = 0.15 },
	{ id = "ripenSpread", kind = "num", min = 0, max = 0.15, default = 0.08 },
	-- Stats: carried and inherited, not used by anything yet.
	{ id = "growHours", kind = "num", min = 0.01, max = 48, log = true, default = 1 },
	{ id = "value", kind = "num", min = 1, max = 1e8, log = true, default = 100 },
	{ id = "kg", kind = "num", min = 0.02, max = 50, log = true, default = 0.5 },
}
PlantGenome.Genes = GENES
PlantGenome.WIDE_BULK = 1.5

local DRIFT = 0.06 -- of a gene's range, each way
local HUE_DRIFT = 0.03

local byId = {}
for _, gene in GENES do
	byId[gene.id] = gene
end

-- A numeric gene's value as 0..1 of its range, and back.
local function toUnit(gene, value: number): number
	if gene.log then
		return math.log(value / gene.min) / math.log(gene.max / gene.min)
	end
	return (value - gene.min) / (gene.max - gene.min)
end

local function fromUnit(gene, unit: number): number
	local u = math.clamp(unit, 0, 1)
	local value = if gene.log then gene.min * (gene.max / gene.min) ^ u else gene.min + (gene.max - gene.min) * u
	return if gene.kind == "int" then math.round(value) else value
end

local function clean(gene, value)
	if gene.kind == "pick" then
		if type(value) == "string" then
			value = assert(table.find(gene.options, value), "Unknown " .. gene.id .. " option " .. value)
		end
		return math.clamp(math.round(value), 1, #gene.options)
	elseif gene.kind == "hue" then
		return value % 1
	end
	return fromUnit(gene, toUnit(gene, value))
end

-- A full genome from partial values (pick genes may be given by option name); the rest are defaults.
function PlantGenome.new(values)
	local genome = {}
	for id in values do
		assert(byId[id], "Unknown gene " .. id)
	end
	for _, gene in GENES do
		local value = values[gene.id]
		genome[gene.id] = clean(gene, if value == nil then gene.default else value)
	end
	return genome
end

-- The option name of a pick gene.
function PlantGenome.pick(genome, id: string): string
	return byId[id].options[genome[id]]
end

-- Squares along one side of the block the plant stands on: 1, or 2 for a big plant.
function PlantGenome.footprint(genome): number
	return if genome.bulk >= PlantGenome.WIDE_BULK then 2 else 1
end

function PlantGenome.random(random: Random)
	local genome = {}
	for _, gene in GENES do
		if gene.kind == "pick" then
			genome[gene.id] = random:NextInteger(1, #gene.options)
		elseif gene.kind == "hue" then
			genome[gene.id] = random:NextNumber()
		else
			genome[gene.id] = fromUnit(gene, random:NextNumber())
		end
	end
	return genome
end

-- What a mutagen does to the child after the cross: set a gene, scale it, or keep it at least `min`.
PlantGenome.Mutagens = {
	Violet = { { gene = "ripeHue", set = 0.78 }, { gene = "ripeSat", min = 0.6 }, { gene = "ripeVal", min = 0.55 } },
	Giant = { { gene = "fruitSize", scale = 1.6 }, { gene = "fruitCount", scale = 0.5 } },
}

-- A child of a and b. Every gene takes two draws whatever its kind, so one gene's change never shifts the others.
-- Numbers: a random blend of the parents plus a drift; picks: one parent's; hues: blended along the shorter arc.
function PlantGenome.cross(a, b, random: Random, mutagens: { string }?)
	local child = {}
	for _, gene in GENES do
		local x, y = a[gene.id], b[gene.id]
		local weight, drift = random:NextNumber(), random:NextNumber(-1, 1)
		if gene.kind == "pick" then
			child[gene.id] = if weight < 0.5 then x else y
		elseif gene.kind == "hue" then
			local arc = (y - x + 0.5) % 1 - 0.5
			child[gene.id] = (x + arc * weight + drift * HUE_DRIFT) % 1
		else
			local ux, uy = toUnit(gene, x), toUnit(gene, y)
			child[gene.id] = fromUnit(gene, ux + (uy - ux) * weight + drift * DRIFT)
		end
	end
	for _, name in mutagens or {} do
		for _, effect in assert(PlantGenome.Mutagens[name], "Unknown mutagen " .. name) do
			local gene = byId[effect.gene]
			local value = child[effect.gene]
			if effect.set then
				value = effect.set
			elseif effect.scale then
				value *= effect.scale
			elseif effect.min then
				value = math.max(value, effect.min)
			end
			child[effect.gene] = clean(gene, math.clamp(value, gene.min or 0, gene.max or 1))
		end
	end
	return child
end

-- One byte per gene: the size a stored or broadcast genome would have.
function PlantGenome.pack(genome): string
	local bytes = table.create(#GENES)
	for i, gene in GENES do
		local value = genome[gene.id]
		if gene.kind == "pick" then
			bytes[i] = value
		elseif gene.kind == "int" then
			bytes[i] = value - gene.min
		elseif gene.kind == "hue" then
			bytes[i] = math.round(value * 255)
		else
			bytes[i] = math.round(toUnit(gene, value) * 255)
		end
	end
	return string.char(table.unpack(bytes))
end

function PlantGenome.unpack(packed: string)
	local genome = {}
	for i, gene in GENES do
		local byte = string.byte(packed, i)
		if byte == nil then
			genome[gene.id] = clean(gene, gene.default)
		elseif gene.kind == "pick" then
			genome[gene.id] = clean(gene, byte)
		elseif gene.kind == "int" then
			genome[gene.id] = clean(gene, byte + gene.min)
		elseif gene.kind == "hue" then
			genome[gene.id] = byte / 255 % 1
		else
			genome[gene.id] = fromUnit(gene, byte / 255)
		end
	end
	return genome
end

-- Hand-fitted genomes: the 19 catalogue crops (their stats come from CropConfig) and plant types the catalogue lacks.
local PRESETS = {
	Potato = {
		stems = 4, height = 1.9, spread = 0.3, arch = 0.2, branches = 1, stemWidth = 0.16, leafShape = "feather",
		leafLen = 1.0, leafWidth = 0.6, leafCount = 4, droop = 0.3, leafHue = 0.31, leafTone = 0.4, fruitShape = "ball",
		fruitSize = 0.55, fruitCount = 4, fruitAt = -0.2, fruitHang = 0, unripeHue = 0.1, ripeHue = 0.09, ripeSat = 0.45,
		ripeVal = 0.72, ripenSpread = 0,
	},
	Lettuce = {
		height = 0.3, spread = 0, arch = 0, leafShape = "round", leafLen = 1.6, leafWidth = 0.9, leafCount = 0, basal = 1,
		droop = 0.3, leafHue = 0.29, leafTone = 0.6, leafVary = 0.8, fruitShape = "head", fruitSize = 1.6, fruitCount = 1,
		fruitAt = 1, fruitHang = 0, unripeHue = 0.27, ripeHue = 0.25, ripeSat = 0.55, ripeVal = 0.8, ripenSpread = 0,
	},
	Onion = {
		height = 0.3, spread = 0, arch = 0, leafShape = "strap", leafLen = 2.0, leafWidth = 0.12, leafCount = 0, basal = 0.5,
		droop = -0.25, leafHue = 0.34, leafTone = 0.45, fruitShape = "ball", fruitSize = 0.85, fruitAspect = 0.9,
		fruitCount = 1, fruitAt = -0.15, fruitHang = 0, unripeHue = 0.1, ripeHue = 0.08, ripeSat = 0.55, ripeVal = 0.72,
		ripenSpread = 0,
	},
	Garlic = {
		height = 0.3, spread = 0, arch = 0, leafShape = "strap", leafLen = 1.7, leafWidth = 0.2, leafCount = 0, basal = 0.4,
		droop = -0.1, leafHue = 0.32, leafTone = 0.5, fruitShape = "ball", fruitSize = 0.8, fruitAspect = 0.85,
		fruitCount = 1, fruitAt = -0.15, fruitHang = 0, unripeHue = 0.15, ripeHue = 0.12, ripeSat = 0.08, ripeVal = 0.95,
		ripenSpread = 0,
	},
	Tomato = {
		height = 4.8, spread = 0.03, arch = 0.1, branches = 2, branchAngle = 0.9, wood = 0.1, stemWidth = 0.26,
		support = "stake", leafShape = "lobed", leafLen = 1.3, leafWidth = 0.7, leafCount = 5, droop = 0.5, leafHue = 0.31,
		leafTone = 0.4, fruitShape = "ball", fruitSize = 0.7, fruitCount = 6, fruitAt = 0.5, fruitHang = 0.7,
		unripeHue = 0.25, ripeHue = 0.01, ripeSat = 0.85, ripeVal = 0.86, ripenSpread = 0.1,
	},
	Cucumber = {
		stems = 2, height = 4.6, spread = 0.05, arch = 0.1, stemWidth = 0.14, support = "trellis", climb = 0.7,
		leafShape = "round", leafLen = 0.95, leafWidth = 0.9, leafCount = 5, droop = 0.3, leafHue = 0.31, leafTone = 0.4,
		fruitShape = "pod", fruitSize = 1.0, fruitAspect = 1.2, fruitCurve = 0.15, fruitCount = 4, fruitAt = 0.6,
		fruitHang = 1, unripeHue = 0.28, ripeHue = 0.34, ripeSat = 0.7, ripeVal = 0.42, flowerHue = 0.15,
	},
	Corn = {
		height = 6.8, spread = 0, arch = 0, wood = 0, stemWidth = 0.3, leafShape = "strap", leafLen = 2.0, leafWidth = 0.2,
		leafCount = 6, droop = 0.55, leafHue = 0.29, leafTone = 0.5, fruitShape = "ball", fruitSize = 0.44,
		fruitAspect = 2.4, fruitCount = 2, fruitAt = 0.6, fruitHang = 0, unripeHue = 0.25, ripeHue = 0.14, ripeSat = 0.7,
		ripeVal = 0.95, extra = "husk", bloomAt = 0.45, flowerHue = 0.14, ripenSpread = 0.04,
	},
	Pepper = {
		height = 3.4, spread = 0.02, arch = 0.05, branches = 2, branchAngle = 1.0, wood = 0.15, stemWidth = 0.22,
		leafShape = "blade", leafLen = 1.15, leafWidth = 0.55, leafCount = 6, droop = 0.35, leafHue = 0.33, leafTone = 0.35,
		fruitShape = "tapered", fruitSize = 0.55, fruitAspect = 1.1, fruitCount = 6, fruitAt = 0.7, fruitHang = 1,
		unripeHue = 0.28, ripeHue = 0, ripeSat = 0.9, ripeVal = 0.8, bloomAt = 0.4, flowerHue = 0.13, ripenSpread = 0.12,
	},
	Broccoli = {
		height = 1.6, spread = 0, arch = 0, stemWidth = 0.4, stemTone = 0.8, stemSat = 0.3, leafShape = "lobed",
		leafLen = 1.7, leafWidth = 0.5, leafCount = 2, basal = 0.6, droop = 0.2, leafHue = 0.38, leafSat = 0.35,
		leafTone = 0.5, fruitShape = "head", fruitSize = 1.5, fruitCount = 1, fruitAt = 1, fruitHang = 0, unripeHue = 0.3,
		ripeHue = 0.33, ripeSat = 0.55, ripeVal = 0.5, ripenSpread = 0,
	},
	Pumpkin = {
		height = 3.8, spread = 0.6, arch = 0.85, branches = 1, branchAngle = 1.1, wood = 0, stemWidth = 0.24,
		leafShape = "round", leafLen = 1.7, leafWidth = 0.9, leafCount = 5, droop = 0.15, leafHue = 0.3, leafTone = 0.35,
		fruitShape = "ball", fruitSize = 2.3, fruitCount = 1, fruitAt = 0.15, fruitHang = 0, unripeHue = 0.27,
		ripeHue = 0.07, ripeSat = 0.9, ripeVal = 0.95, bloomAt = 0.38, flowerHue = 0.13, ripenSpread = 0,
	},
	Eggplant = {
		height = 3.8, spread = 0.03, arch = 0.1, branches = 3, branchAt = 0.45, branchAngle = 1.0, wood = 0.3,
		stemWidth = 0.24, leafShape = "blade", leafLen = 1.5, leafWidth = 0.7, leafCount = 4, droop = 0.4, leafHue = 0.32,
		leafTone = 0.35, fruitShape = "ball", fruitSize = 0.5, fruitAspect = 2.1, fruitCount = 3, fruitAt = 0.6,
		fruitHang = 1, unripeHue = 0.8, ripeHue = 0.78, ripeSat = 0.6, ripeVal = 0.32, extra = "husk", flowerHue = 0.78,
	},
	Blueberry = {
		stems = 5, height = 4.3, spread = 0.26, arch = 0.12, branches = 1, branchAngle = 0.9, wood = 0.85, stemWidth = 0.2,
		leafShape = "blade", leafLen = 1.0, leafWidth = 0.62, leafCount = 4, droop = 0.4, leafHue = 0.31, leafTone = 0.4,
		fruitShape = "cluster", fruitSize = 0.8, fruitCount = 10, fruitAt = 0.8, fruitHang = 0.4, unripeHue = 0.24,
		ripeHue = 0.64, ripeSat = 0.48, ripeVal = 0.68, extra = "crown", bloomAt = 0.4, flowerHue = 0.13,
	},
	SweetPotato = {
		stems = 3, height = 3.4, spread = 0.1, arch = 0.2, stemWidth = 0.14, support = "trellis", climb = 0.5,
		leafShape = "round", leafLen = 1.25, leafWidth = 0.95, leafCount = 5, droop = 0.35, leafHue = 0.3, leafTone = 0.4,
		fruitShape = "tapered", fruitSize = 0.9, fruitAspect = 1.2, fruitCount = 3, fruitAt = -0.25, fruitHang = 0,
		unripeHue = 0.02, ripeHue = 0.98, ripeSat = 0.5, ripeVal = 0.72, ripenSpread = 0,
	},
	GiantMelon = {
		height = 3.8, spread = 0.6, arch = 0.85, branches = 1, branchAngle = 1.1, stemWidth = 0.24, leafShape = "lobed",
		leafLen = 1.6, leafWidth = 0.8, leafCount = 5, droop = 0.15, leafHue = 0.31, leafTone = 0.4, fruitShape = "ball",
		fruitSize = 2.4, fruitAspect = 1.1, fruitCount = 1, fruitAt = 0.15, fruitHang = 0, unripeHue = 0.3, ripeHue = 0.34,
		ripeSat = 0.65, ripeVal = 0.5, pattern = "stripes", patternHue = 0.3, patternSat = 0.45, bloomAt = 0.38,
		flowerHue = 0.14, ripenSpread = 0,
	},
	Sunflower = {
		height = 6.6, spread = 0, arch = 0.05, stemWidth = 0.3, leafShape = "blade", leafLen = 1.5, leafWidth = 0.75,
		leafCount = 6, leafFrom = 0.15, droop = 0.45, leafHue = 0.31, leafTone = 0.4, fruitShape = "bloom", fruitSize = 2.0,
		fruitCount = 1, fruitAt = 1, fruitHang = 0, unripeHue = 0.2, ripeHue = 0.13, ripeSat = 0.9, ripeVal = 1,
		ripenSpread = 0,
	},
	Pineapple = {
		height = 1.6, spread = 0, arch = 0, stemWidth = 0.32, leafShape = "strap", leafLen = 2.0, leafWidth = 0.2,
		leafCount = 0, basal = 0.9, droop = 0.1, leafHue = 0.37, leafSat = 0.4, leafTone = 0.45, fruitShape = "ball",
		fruitSize = 0.88, fruitAspect = 1.5, fruitCount = 1, fruitAt = 1, fruitHang = 0, unripeHue = 0.3, ripeHue = 0.12,
		ripeSat = 0.75, ripeVal = 0.9, pattern = "spots", patternHue = 0.08, patternSat = 0.75, extra = "tuft",
		ripenSpread = 0,
	},
	GoldenCarrot = {
		height = 0.3, spread = 0, arch = 0, stemWidth = 0.14, leafShape = "feather", leafLen = 2.1, leafWidth = 0.42,
		leafCount = 0, basal = 0.7, droop = -0.2, leafHue = 0.3, leafTone = 0.5, fruitShape = "tapered", fruitSize = 0.9,
		fruitCount = 1, fruitAt = -0.3, fruitHang = 0, unripeHue = 0.13, ripeHue = 0.12, ripeSat = 0.85, ripeVal = 1,
		extra = "glow", ripenSpread = 0,
	},
	FrostGrape = {
		stems = 2, height = 5.6, spread = 0.05, arch = 0.1, wood = 0.9, stemWidth = 0.2, support = "trellis", climb = 0.9,
		leafShape = "lobed", leafLen = 1.15, leafWidth = 0.9, leafCount = 4, leafFrom = 0.5, droop = 0.35, leafHue = 0.33,
		leafTone = 0.4, fruitShape = "cluster", fruitSize = 0.95, fruitCount = 3, fruitAt = 0.85, fruitHang = 1,
		unripeHue = 0.3, ripeHue = 0.6, ripeSat = 0.35, ripeVal = 0.92, extra = "frost",
	},
	GlowMushroom = {
		stems = 2, height = 1.7, spread = 0.12, arch = 0, stemWidth = 0.5, stemHue = 0.1, stemSat = 0.15, stemTone = 0.92,
		leafCount = 0, fruitShape = "cap", fruitSize = 1.5, fruitCount = 2, fruitAt = 1, fruitHang = 0, unripeHue = 0.1,
		ripeHue = 0.07, ripeSat = 0.6, ripeVal = 0.5, extra = "glow", ripenSpread = 0.03,
	},
	-- Plant types the catalogue does not have yet.
	Palm = {
		bulk = 2, height = 5, spread = 0.03, arch = 0.25, wood = 0.7, stemWidth = 0.45, stemStyle = "segmented",
		leafShape = "feather", leafLen = 2.2, leafWidth = 0.5, leafCount = 6, leafFrom = 0.9, droop = 0.6, leafHue = 0.31,
		leafTone = 0.45, fruitShape = "ball", fruitSize = 0.85, fruitAspect = 1.1, fruitCount = 4, fruitAt = 0.92,
		fruitHang = 0.8, unripeHue = 0.25, ripeHue = 0.08, ripeSat = 0.6, ripeVal = 0.45,
	},
	AppleTree = {
		bulk = 2, height = 4.2, spread = 0.02, arch = 0.05, branches = 4, branchAt = 0.55, branchAngle = 1.0, wood = 1,
		stemWidth = 0.5, leafShape = "mass", leafLen = 2.2, leafWidth = 0.9, leafCount = 3, leafFrom = 0.8, droop = 0.6,
		leafHue = 0.31, leafTone = 0.4, fruitShape = "ball", fruitSize = 0.6, fruitCount = 10, fruitAt = 0.8,
		fruitHang = 0.8, unripeHue = 0.25, ripeHue = 0, ripeSat = 0.8, ripeVal = 0.85, flowerHue = 0.95,
	},
	Cactus = {
		stems = 3, height = 2.6, spread = 0.12, arch = 0, stemWidth = 0.8, stemHue = 0.36, stemSat = 0.5, stemTone = 0.55,
		wood = 0, stemStyle = "spiny", leafCount = 0, fruitShape = "bloom", fruitSize = 0.7, fruitCount = 3, fruitAt = 1,
		fruitHang = 0, ripeHue = 0.92, ripeSat = 0.6, ripeVal = 1, ripenSpread = 0.05,
	},
	Toadstool = {
		height = 1.8, spread = 0, arch = 0, stemWidth = 0.5, stemSat = 0.08, stemTone = 0.95, leafCount = 0,
		fruitShape = "cap", fruitSize = 2.0, fruitCount = 1, fruitAt = 1, fruitHang = 0, unripeHue = 0.05, ripeHue = 0,
		ripeSat = 0.85, ripeVal = 0.85, pattern = "spots", patternSat = 0.05, ripenSpread = 0,
	},
	Tulip = {
		stems = 3, height = 2.2, spread = 0.08, arch = 0, stemWidth = 0.12, leafShape = "strap", leafLen = 1.5,
		leafWidth = 0.3, leafCount = 0, basal = 0.4, droop = -0.1, leafHue = 0.33, leafTone = 0.5, fruitShape = "ball",
		fruitSize = 0.6, fruitAspect = 1.3, fruitCount = 3, fruitAt = 1, fruitHang = 0, unripeHue = 0.28, ripeHue = 0.93,
		ripeSat = 0.7, ripeVal = 0.95, ripenSpread = 0.05,
	},
	Bean = {
		stems = 2, height = 4.6, spread = 0.05, arch = 0.1, stemWidth = 0.12, support = "trellis", climb = 0.7,
		leafShape = "round", leafLen = 0.9, leafWidth = 0.8, leafCount = 5, droop = 0.3, leafHue = 0.3, leafTone = 0.45,
		fruitShape = "pod", fruitSize = 0.8, fruitAspect = 1.3, fruitCurve = 0.5, fruitCount = 8, fruitAt = 0.55,
		fruitHang = 1, unripeHue = 0.28, ripeHue = 0.3, ripeSat = 0.6, ripeVal = 0.65, flowerHue = 0.9,
	},
	Wheat = {
		stems = 12, height = 3.4, spread = 0.1, arch = 0.15, stemWidth = 0.1, stemHue = 0.14, stemSat = 0.5,
		stemTone = 0.8, leafShape = "strap", leafLen = 1.0, leafWidth = 0.12, leafCount = 2, leafFrom = 0.3, droop = 0.3,
		leafHue = 0.2, leafTone = 0.6, fruitShape = "ball", fruitSize = 0.28, fruitAspect = 2.5, fruitCount = 12,
		fruitAt = 1, fruitHang = 0, unripeHue = 0.22, ripeHue = 0.13, ripeSat = 0.6, ripeVal = 0.9, ripenSpread = 0.03,
	},
	Strawberry = {
		stems = 5, height = 0.9, spread = 0.8, arch = 0.5, stemWidth = 0.1, leafShape = "round", leafLen = 0.8,
		leafWidth = 0.9, leafCount = 0, basal = 0.7, droop = 0.2, leafHue = 0.31, leafTone = 0.4, fruitShape = "tapered",
		fruitSize = 0.45, fruitAspect = 0.7, fruitCount = 5, fruitAt = 0.9, fruitHang = 0.6, unripeHue = 0.22,
		ripeHue = 0.99, ripeSat = 0.85, ripeVal = 0.85, flowerHue = 0.16,
	},
}

PlantGenome.Presets = {}
for id, values in PRESETS do
	local crop = CropConfig.ById[id]
	if crop then
		values.growHours, values.value, values.kg = crop.growSeconds / 3600, crop.sale, crop.kg
	end
	PlantGenome.Presets[id] = PlantGenome.new(values)
end

return PlantGenome
