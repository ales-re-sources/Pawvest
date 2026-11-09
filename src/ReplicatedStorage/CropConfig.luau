-- CropConfig: the crop field's shared numbers and pure helpers (E1a2, docs/EXPANSION.md §5; numbers since E1d1 from docs/ECONOMY.md →
-- "EV", the engagement-first economy, since EV2a). Shared: the server prices, grows and pays from this table only, the client renders it. Pure data +
-- helpers, no side effects. Crop ids are stored in profiles (Garden.Field.Squares[n].Crop, Garden.Seeds, Garden.Items):
-- never rename one. tools/economy.py reads this file and `check` pins it.
-- Growth: a planted square earns growth seconds (`Grown`) at OnlineRate while its owner is online and at OfflineRate for
-- at most OfflineCapSeconds of each absence; a crop is ripe at Grown >= growSeconds and waits (never rots).

local CropConfig = {}

-- Crops in catalogue order (EV2a, docs/ECONOMY.md → "EV": one ladder of grow times from 10 s to 24 h, net Coins per square-hour x 1.2
-- per step). letter: one character in the plot message (GardenRemotes.Plot field.crops); renown: Renown level that unlocks the crop;
-- sale / seed in Coins (seed = 25 % of the sale); points: Renown points per harvest (4 x grow minutes ^ 0.5);
-- kg: the weight shown at size factor 1 (E1c2); xp: pet XP of one crop fed to a pet (E1a3, half the sale, at least 1: no more than
-- its Coins would buy as Berries; economy.py checks it).
-- Rare crops (E2, `rare = true`, sale and points set by hand for the days a world is reached, economy_ev.py check R): one per obby world (`world`), seeds only from the obby (CropConfig.ObbySeeds), never sold as seeds
-- (seed = 0: BuySeeds and the market cart skip them), no Renown gate.
CropConfig.Crops = {
	{ id = "Potato", name = "Potato", icon = "🥔", letter = "a", growSeconds = 10, sale = 9, seed = 2, renown = 0, points = 2, kg = 0.25, xp = 4 }, -- loc: ignore
	{ id = "Lettuce", name = "Lettuce", icon = "🥬", letter = "h", growSeconds = 30, sale = 35, seed = 9, renown = 1, points = 3, kg = 0.4, xp = 17 }, -- loc: ignore
	{ id = "Onion", name = "Onion", icon = "🧅", letter = "i", growSeconds = 1 * 60, sale = 80, seed = 20, renown = 2, points = 4, kg = 0.2, xp = 40 }, -- loc: ignore
	{ id = "Garlic", name = "Garlic", icon = "🧄", letter = "j", growSeconds = 3 * 60, sale = 290, seed = 70, renown = 3, points = 7, kg = 0.1, xp = 145 }, -- loc: ignore
	{ id = "Tomato", name = "Tomato", icon = "🍅", letter = "k", growSeconds = 8 * 60, sale = 900, seed = 220, renown = 4, points = 11, kg = 0.2, xp = 450 }, -- loc: ignore
	{ id = "Cucumber", name = "Cucumber", icon = "🥒", letter = "l", growSeconds = 15 * 60, sale = 2100, seed = 500, renown = 5, points = 15, kg = 0.3, xp = 1050 }, -- loc: ignore
	{ id = "Corn", name = "Corn", icon = "🌽", letter = "b", growSeconds = 30 * 60, sale = 5000, seed = 1200, renown = 6, points = 22, kg = 0.5, xp = 2500 }, -- loc: ignore
	{ id = "Pepper", name = "Pepper", icon = "🌶️", letter = "m", growSeconds = 1 * 3600, sale = 12000, seed = 3000, renown = 8, points = 31, kg = 0.2, xp = 6000 }, -- loc: ignore
	{ id = "Broccoli", name = "Broccoli", icon = "🥦", letter = "n", growSeconds = 2 * 3600, sale = 29000, seed = 7000, renown = 11, points = 44, kg = 0.5, xp = 14500 }, -- loc: ignore
	{ id = "Pumpkin", name = "Pumpkin", icon = "🎃", letter = "c", growSeconds = 3 * 3600, sale = 50000, seed = 12000, renown = 15, points = 54, kg = 6, xp = 25000 }, -- loc: ignore
	{ id = "Eggplant", name = "Eggplant", icon = "🍆", letter = "o", growSeconds = 4 * 3600, sale = 85000, seed = 21000, renown = 20, points = 62, kg = 0.4, xp = 42500 }, -- loc: ignore
	{ id = "Blueberry", name = "Blueberry", icon = "🫐", letter = "p", growSeconds = 6 * 3600, sale = 150000, seed = 40000, renown = 26, points = 76, kg = 0.2, xp = 75000 }, -- loc: ignore
	{ id = "SweetPotato", name = "Sweet potato", icon = "🍠", letter = "q", growSeconds = 8 * 3600, sale = 240000, seed = 60000, renown = 33, points = 88, kg = 0.4, xp = 120000 }, -- loc: ignore
	{ id = "GiantMelon", name = "Giant melon", icon = "🍉", letter = "d", growSeconds = 12 * 3600, sale = 450000, seed = 110000, renown = 42, points = 107, kg = 15, xp = 225000 }, -- loc: ignore
	{ id = "Sunflower", name = "Sunflower", icon = "🌻", letter = "r", growSeconds = 18 * 3600, sale = 750000, seed = 190000, renown = 54, points = 131, kg = 1.5, xp = 375000 }, -- loc: ignore
	{ id = "Pineapple", name = "Pineapple", icon = "🍍", letter = "s", growSeconds = 24 * 3600, sale = 1200000, seed = 300000, renown = 68, points = 152, kg = 1.5, xp = 600000 }, -- loc: ignore
	{ id = "GoldenCarrot", name = "Golden carrot", icon = "🥕", letter = "e", growSeconds = 6 * 3600, sale = 50000, seed = 0, renown = 0, points = 22, kg = 0.3, xp = 25000, rare = true, world = 1 }, -- loc: ignore
	{ id = "FrostGrape", name = "Frost grape", icon = "🍇", letter = "f", growSeconds = 8 * 3600, sale = 150000, seed = 0, renown = 0, points = 44, kg = 0.5, xp = 75000, rare = true, world = 2 }, -- loc: ignore
	{ id = "GlowMushroom", name = "Glow mushroom", icon = "🍄", letter = "g", growSeconds = 10 * 3600, sale = 300000, seed = 0, renown = 0, points = 76, kg = 0.2, xp = 150000, rare = true, world = 3 }, -- loc: ignore
}
CropConfig.ById = {}
CropConfig.ByLetter = {}
for _, crop in CropConfig.Crops do
	CropConfig.ById[crop.id] = crop
	CropConfig.ByLetter[crop.letter] = crop
end

-- The field's shape (E1d2): rows of RowWidths squares from the plot outwards, each row centred on a grid of GridColumns
-- columns (the widest row). Squares are numbered row by row from the plot, left to right as seen from the plot (1..MaxSquares);
-- the numbers are stored (Field.Open, Field.Squares, FieldPets[uid].Square): never reorder the rows.
CropConfig.RowWidths = { 6, 6, 8, 8, 8 }
CropConfig.GridColumns = 8
CropConfig.MaxSquares = 36
CropConfig.StartSquares = 4 -- a new field (E1a2 decision 3: with StartSeeds, so the first plant needs no shop)
CropConfig.StartOpen = { 3, 4, 9, 10 } -- the 2 x 2 block at the front centre
CropConfig.StartSeeds = { Potato = 4 }
-- Expansions[n] = the square bought when StartSquares + n - 1 are open (any locked square the player picks): Coins and the
-- Renown level it needs (EV2a: x 1.33 per square up to the 16th, then x 1.93; 1.6 B in all; every field sink is priced on this ladder).
CropConfig.Expansions = {
	{ price = 290, renown = 1 },
	{ price = 400, renown = 2 },
	{ price = 500, renown = 3 },
	{ price = 700, renown = 4 },
	{ price = 900, renown = 5 },
	{ price = 1200, renown = 6 },
	{ price = 1600, renown = 7 },
	{ price = 2100, renown = 8 },
	{ price = 2800, renown = 9 },
	{ price = 4000, renown = 10 },
	{ price = 5000, renown = 11 },
	{ price = 6500, renown = 12 },
	{ price = 9000, renown = 13 },
	{ price = 12000, renown = 14 },
	{ price = 16000, renown = 15 },
	{ price = 21000, renown = 16 },
	{ price = 40000, renown = 17 },
	{ price = 80000, renown = 18 },
	{ price = 150000, renown = 19 },
	{ price = 290000, renown = 20 },
	{ price = 550000, renown = 21 },
	{ price = 1100000, renown = 23 },
	{ price = 2100000, renown = 24 },
	{ price = 4000000, renown = 25 },
	{ price = 7500000, renown = 26 },
	{ price = 15000000, renown = 27 },
	{ price = 29000000, renown = 28 },
	{ price = 55000000, renown = 29 },
	{ price = 110000000, renown = 30 },
	{ price = 210000000, renown = 32 },
	{ price = 400000000, renown = 33 },
	{ price = 750000000, renown = 34 },
}

-- Rare seeds from the obby (E2a, docs/ROADMAP.md → E2; numbers from docs/ECONOMY.md → "Obby seeds run"), for players with the field:
-- * the first Gold on a stage of world FirstGoldWorld or later: FirstGold seeds of that world's rare crop (World 1's would put the field
--   above the obby on days 1-3);
-- * the day's first medal finish (UTC day, any stage of a world): Daily seeds of that stage's world;
-- * every stage's meter: a medal finish adds Points[medal] (x FirstMult for the day's first medal finish on that stage); MeterSize points
--   give one seed of the stage's world and the meter keeps the rest (Garden.Meters[stageKey]).
-- Rare seeds join Garden.Seeds even past the seed stock's limit (an earned seed is never lost).
CropConfig.ObbySeeds = {
	FirstGoldWorld = 2,
	FirstGold = 1,
	Daily = 1,
	MeterSize = 300,
	Points = { 1, 2, 3 }, -- Bronze, Silver, Gold
	FirstMult = 2,
	-- E2b seed pouch: the day's first medal finish on a stage gives these seeds (Bronze, Silver, Gold) of the common crop the player
	-- planted last (Garden.LastCrop; Potato before any), only up to the barn's limit
	Pouch = { 1, 2, 3 },
	PouchDefault = "Potato",
}

-- The rare crop of obby world `world` (nil for the Tutorial or a world without one).
function CropConfig.RareOfWorld(world: number?)
	for _, crop in CropConfig.Crops do
		if crop.rare and crop.world == world then
			return crop
		end
	end
	return nil
end
CropConfig.RenownK = 0.4 -- level L needs RenownK * L ^ RenownP points in total (EV2a; was 3 x L ^ 1.6)
CropConfig.RenownP = 3
CropConfig.BarnCapacity = 40 -- seeds of all crops together, and the crops a Tending pet may store, before the Barn upgrade

-- Field upgrades (E1c1, docs/ECONOMY.md → upgrades): prices[n] = Coins for level n, renown[n] = the Renown level it needs (EV2a). Growth: each level -step of every grow time
-- (earned growth runs 1 / (1 - step × level) as fast); Barn: each level +step capacity. Ids are stored
-- (Garden.Field.Upgrades[id] = level): never rename one.
CropConfig.Upgrades = {
	{ id = "Growth", icon = "🌱", step = 0.05, prices = { 3000, 18000, 450000, 22000000 }, renown = { 8, 14, 20, 27 } },
	{ id = "Barn", icon = "🏠", step = 20, prices = { 1200, 5000, 21000, 550000, 15000000 }, renown = { 6, 11, 16, 21, 27 } },
}
CropConfig.UpgradeById = {}
for _, upgrade in CropConfig.Upgrades do
	CropConfig.UpgradeById[upgrade.id] = upgrade
end

-- Market cart (E1c4, docs/EXPANSION.md §5.2; approved 2026-11-03): daily offers from the UTC day. Each bargain sells `count` seeds of a
-- different unlocked crop at (1 - discount) of the catalogue price; the taste sells `count` seeds of the next locked crop at the catalogue
-- price × `price`, offered from Renown level `fromLevel` (earlier tastes broke the day 1-3 parity in economy.py). Quantities are per player
-- and day (Garden.Cart). Seeds the player holds can be planted before their Renown gate; the catalogue keeps it.
CropConfig.Cart = {
	bargains = { { count = 10, discount = 0.3 }, { count = 5, discount = 0.5 } },
	taste = { count = 2, price = 1, fromLevel = 3 },
}
CropConfig.DaySeconds = 86400

-- Garden tools (E1c3, docs/EXPANSION.md §6; numbers approved 2026-11-03, docs/ECONOMY.md → "Garden tools at F2"): levels bought with
-- Coins, each level gated by a Renown level; Garden.Tools[id] = level. effect[n] at level n: Sorter = a harvest's size factor x (1 + effect)
-- (owner and Tending pets alike); Cloches = growth while the owner is online x (1 + effect), nothing offline; Shears = the chance of a second
-- crop of the same size per harvest (no extra Renown, no seed). Ids are stored: never rename one.
CropConfig.Tools = {
	{ id = "Sorter", icon = "🔍", effect = { 0.05, 0.10, 0.15 }, prices = { 10000, 220000, 45000000 }, renown = { 12, 19, 28 } },
	{ id = "Cloches", icon = "🔔", effect = { 0.07, 0.14, 0.20 }, prices = { 4000, 30000, 6000000 }, renown = { 9, 16, 25 } },
	{ id = "Shears", icon = "✂️", effect = { 0.05, 0.10, 0.15 }, prices = { 18000, 800000, 160000000 }, renown = { 14, 21, 30 } },
}
CropConfig.ToolById = {}
for _, tool in CropConfig.Tools do
	CropConfig.ToolById[tool.id] = tool
end

-- Field pets (E1b, docs/ECONOMY.md → "Field-pet re-run"; five slots since E1d1): PetSlotPrices[n] = price of the n-th field pet slot (slot 1 is free).
-- A profile from before the field (the P2 pens, removed in FA) converts once on join: PetSlotsFromPens[pens bought] slots, the
-- Coins paid for pens (LegacyPenPrices[n] = what the n-th pen cost) beyond those slots' prices refunded (GardenField).
-- A Tending pet harvests only while the crops in the barn (Items) are fewer than BarnCapacity.
CropConfig.PetSlotPrices = { 0, 2400, 14000, 220000, 11000000 }
CropConfig.PetSlotsFromPens = { 1, 2, 2, 3, 3, 3 }
CropConfig.LegacyPenPrices = { 0, 1000, 2500, 5000, 9000, 15000 }

-- Size roll (E1c2, docs/EXPANSION.md §5.3): every harvest's size factor = exp(SizeSigma × z - SizeSigma² / 2), mean exactly 1
-- (the ladder holds), z standard normal from the planting's own seed, capped at ±SizeZCap. Big from z >= SizeBigZ (top 20 %),
-- Giant from z >= SizeGiantZ (top 3 %). A sale pays sale × factor. tools/economy.py pins these and checks the mean.
CropConfig.SizeSigma = 0.25
CropConfig.SizeZCap = 4
CropConfig.SizeBigZ = 0.8416
CropConfig.SizeGiantZ = 1.8808

-- Passive rates (ECONOMY open decision 5: placeholders).
CropConfig.OnlineRate = 1.0
CropConfig.OfflineRate = 0.5 -- 2026-11-04: was 0.33 (a day away was worth only ~4 h of growth)
CropConfig.OfflineCapSeconds = 24 * 3600 -- was 12 h
CropConfig.SettleSeconds = 60 -- online growth is settled at least this often (and before every field action, on join and leave)

-- Points needed in total for Renown level `level` (0 for level 0).
function CropConfig.PointsFor(level: number): number
	if level <= 0 then
		return 0
	end
	return math.ceil(CropConfig.RenownK * level ^ CropConfig.RenownP - 1e-9)
end

-- The Renown curve before EV2a (3 x L ^ 1.6): only PlayerProfile's Version 5 step uses it, to keep every player's level.
CropConfig.LegacyRenown = { K = 3, P = 1.6 }
function CropConfig.LegacyRenownLevel(points: number): number
	local k, p = CropConfig.LegacyRenown.K, CropConfig.LegacyRenown.P
	local function need(level: number): number
		return if level <= 0 then 0 else math.ceil(k * level ^ p - 1e-9)
	end
	if type(points) ~= "number" or points ~= points or points < need(1) then
		return 0
	end
	local level = math.floor((points / k) ^ (1 / p))
	while need(level + 1) <= points do
		level += 1
	end
	while level > 0 and need(level) > points do
		level -= 1
	end
	return level
end

-- Renown level reached with `points` (the highest L with PointsFor(L) <= points).
function CropConfig.RenownLevel(points: number): number
	if type(points) ~= "number" or points ~= points or points < CropConfig.PointsFor(1) then
		return 0
	end
	local level = math.floor((points / CropConfig.RenownK) ^ (1 / CropConfig.RenownP))
	while CropConfig.PointsFor(level + 1) <= points do
		level += 1
	end
	while level > 0 and CropConfig.PointsFor(level) > points do
		level -= 1
	end
	return level
end

-- E4-thin crows (docs/ROADMAP.md → E4-thin, numbers approved 2026-11-04): the UTC day has blocks of BlockSeconds; block k (counted from
-- the Unix epoch) is a crow block when its seeded roll is below Share, the same schedule on every server. An absence that overlaps a crow
-- block while a common crop is ripe brings a raid: each such crop is rolled once per planting (Chance), at most Cap eaten per absence,
-- only from Renown level FromLevel. Rare crops are never eaten. Guards: PetConfig.GuardChance.
CropConfig.Crows = { BlockSeconds = 6 * 3600, Share = 0.25, Chance = 0.3, Cap = 1, FromLevel = 3 }

-- Whether block k is a crow block.
function CropConfig.IsCrowBlock(k: number): boolean
	return Random.new(7000003 + k):NextNumber() < CropConfig.Crows.Share
end

-- Whether a crow block overlaps the server times [a, b).
function CropConfig.CrowsBetween(a: number, b: number): boolean
	local size = CropConfig.Crows.BlockSeconds
	local k = math.floor(a / size)
	while k * size < b do
		if CropConfig.IsCrowBlock(k) then
			return true
		end
		k += 1
	end
	return false
end

-- The first crow block that has not ended at server time `now` and starts within `horizon` seconds: its start and end (nil when none;
-- neighbouring crow blocks join into one).
function CropConfig.NextCrows(now: number, horizon: number): (number?, number?)
	local size = CropConfig.Crows.BlockSeconds
	local k = math.floor(now / size)
	while k * size < now + horizon do
		if CropConfig.IsCrowBlock(k) then
			local last = k
			while CropConfig.IsCrowBlock(last + 1) do
				last += 1
			end
			return k * size, (last + 1) * size
		end
		k += 1
	end
	return nil, nil
end

-- Growth seconds earned over `online` seconds with the owner present and an absence of `offline` seconds (capped).
function CropConfig.Growth(online: number, offline: number): number
	return math.max(0, online) * CropConfig.OnlineRate + math.min(math.max(0, offline), CropConfig.OfflineCapSeconds) * CropConfig.OfflineRate
end

-- Level 0..max of upgrade `id` in `upgrades` (Garden.Field.Upgrades or the panel state's field.upgrades).
function CropConfig.UpgradeLevel(upgrades, id: string): number
	local upgrade = CropConfig.UpgradeById[id]
	local level = type(upgrades) == "table" and upgrades[id]
	if not upgrade or type(level) ~= "number" or level ~= level then
		return 0
	end
	return math.clamp(math.floor(level), 0, #upgrade.prices)
end

-- Level 0..max of tool `id` in `tools` (Garden.Tools or the panel state's field.tools).
function CropConfig.ToolLevel(tools, id: string): number
	local tool = CropConfig.ToolById[id]
	local level = type(tools) == "table" and tools[id]
	if not tool or type(level) ~= "number" or level ~= level then
		return 0
	end
	return math.clamp(math.floor(level), 0, #tool.prices)
end

-- The effect of tool `id` at its level in `tools` (0 without the tool).
function CropConfig.ToolEffect(tools, id: string): number
	local level = CropConfig.ToolLevel(tools, id)
	return if level > 0 then CropConfig.ToolById[id].effect[level] else 0
end

-- How much faster crops grow at Growth level `level` (earned growth seconds are multiplied by this).
function CropConfig.GrowthSpeed(level: number): number
	return 1 / (1 - CropConfig.UpgradeById.Growth.step * level)
end

-- Seeds the stock holds (and crops a Tending pet may store) at Barn level `level`.
function CropConfig.BarnFor(level: number): number
	return CropConfig.BarnCapacity + CropConfig.UpgradeById.Barn.step * level
end

local function sizeOf(z: number): number
	local sigma = CropConfig.SizeSigma
	return math.exp(sigma * z - sigma * sigma / 2)
end

-- The size factor of `userId`'s planting number `planting` (Field.Squares[n].N): the same planting always rolls the same,
-- whether the owner or a Tending pet harvests it.
function CropConfig.SizeFactor(userId: number, planting: number): number
	local random = Random.new(userId * 6007 + planting * 1000003 + 17) -- not the Tending roll's seed
	local u1 = 1 - random:NextNumber() -- (0, 1]
	local u2 = random:NextNumber()
	local z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
	return sizeOf(math.clamp(z, -CropConfig.SizeZCap, CropConfig.SizeZCap))
end

-- The smallest and the largest size factor a harvest can give (the largest with the top Seed sorter level).
function CropConfig.SizeBounds(): (number, number)
	local sorter = CropConfig.ToolById.Sorter
	return sizeOf(-CropConfig.SizeZCap), sizeOf(CropConfig.SizeZCap) * (1 + sorter.effect[#sorter.effect])
end

-- "Giant", "Big" or nil for a size factor.
function CropConfig.SizeLabel(factor: number): string?
	if factor >= sizeOf(CropConfig.SizeGiantZ) then
		return "Giant"
	end
	return if factor >= sizeOf(CropConfig.SizeBigZ) then "Big" else nil
end

-- Coins (before the pet bonus) for crops of `crop` whose size factors add up to `sizeSum`: the one rounding rule.
function CropConfig.SaleValue(crop, sizeSum: number): number
	return math.floor(crop.sale * sizeSum + 0.5)
end

-- Look stage 1..3 of a planted crop (3 = ripe), from its growth seconds.
function CropConfig.Stage(crop, grown: number): number
	if grown >= crop.growSeconds then
		return 3
	end
	return if grown >= crop.growSeconds / 2 then 2 else 1
end

-- Expansion that buys the next square of a field with `open` squares open, or nil at MaxSquares.
function CropConfig.NextExpansion(open: number)
	return CropConfig.Expansions[open - CropConfig.StartSquares + 1]
end

-- Field grid (E1d2): cells[n] = { row, col } of square n (col 1..GridColumns), at[row][col] = square.
local cells, at = {}, {}
do
	local n = 0
	for row, width in CropConfig.RowWidths do
		at[row] = {}
		local offset = (CropConfig.GridColumns - width) // 2
		for c = 1, width do
			n += 1
			cells[n] = { row = row, col = offset + c }
			at[row][offset + c] = n
		end
	end
	assert(n == CropConfig.MaxSquares, "CropConfig: RowWidths must add up to MaxSquares")
	assert(#CropConfig.StartOpen == CropConfig.StartSquares, "CropConfig: StartOpen must hold StartSquares squares")
end

-- Row (1 = next to the plot) and grid column (1..GridColumns) of square `square`, or nil outside the field.
function CropConfig.Cell(square: number): (number?, number?)
	local cell = cells[square]
	if not cell then
		return nil, nil
	end
	return cell.row, cell.col
end

-- The square at `row` / grid column `col`, or nil.
function CropConfig.SquareAt(row: number, col: number): number?
	return at[row] and at[row][col]
end

-- The square that old square `old` of the 4 x 3 field (before E1d2: 4 per row, row by row) becomes: rows 1-3, grid
-- columns 3-6 (the middle of every row).
function CropConfig.FromOldSquare(old: number): number?
	if old < 1 or old > 12 or old % 1 ~= 0 then
		return nil
	end
	return CropConfig.SquareAt((old - 1) // 4 + 1, (old - 1) % 4 + 3)
end

-- Squares a pet on `square` reaches with reach `shape` (PetConfig.ReachShape: 0 own, 1 plus the 4 next to it, 2 the
-- 3 x 3 block) on the field grid, only those in the set `open` ({ [square] = true }; nil = every square).
function CropConfig.Reach(square: number, shape: number, open: { [number]: boolean }?): { number }
	local row, col = CropConfig.Cell(square)
	local list = {}
	if not row then
		return list
	end
	for dy = -1, 1 do
		for dx = -1, 1 do
			local inShape = (dx == 0 and dy == 0) or (shape == 1 and (dx == 0 or dy == 0)) or shape >= 2
			local n = CropConfig.SquareAt(row + dy, col + dx)
			if inShape and n and (open == nil or open[n]) then
				table.insert(list, n)
			end
		end
	end
	return list
end

-- Seeds of every crop in `seeds` together (the barn holds BarnCapacity).
function CropConfig.SeedTotal(seeds): number
	local total = 0
	if type(seeds) == "table" then
		for _, count in seeds do
			if type(count) == "number" then
				total += count
			end
		end
	end
	return total
end

-- The market cart's day number for server time `now` (UTC days since the epoch).
function CropConfig.CartDay(now: number): number
	return math.floor(now / CropConfig.DaySeconds)
end

-- The market cart's offers on day `day` for a player at Renown level `level`, in slot order: { slot, crop, count, price (Coins per seed),
-- discount?, taste? }. The same for every player with the same unlocked crops (the pick is seeded by the day only).
function CropConfig.CartOffers(day: number, level: number)
	local cart = CropConfig.Cart
	local unlocked, locked = {}, nil
	for _, crop in CropConfig.Crops do
		if crop.rare then
			continue -- rare seeds come only from the obby
		elseif crop.renown <= level then
			table.insert(unlocked, crop)
		elseif not locked or crop.renown < locked.renown or (crop.renown == locked.renown and crop.seed < locked.seed) then
			locked = crop
		end
	end
	local rng = Random.new(day * 7919 + 17)
	for i = #unlocked, 2, -1 do -- shuffle (Fisher-Yates), then the bargains take the first crops
		local j = rng:NextInteger(1, i)
		unlocked[i], unlocked[j] = unlocked[j], unlocked[i]
	end
	local offers = {}
	for i, bargain in cart.bargains do
		local crop = unlocked[i]
		if crop then
			table.insert(offers, {
				slot = #offers + 1,
				crop = crop,
				count = bargain.count,
				price = math.max(1, math.floor(crop.seed * (1 - bargain.discount) + 0.5)),
				discount = bargain.discount,
			})
		end
	end
	if locked and level >= cart.taste.fromLevel then
		table.insert(offers, {
			slot = #offers + 1,
			crop = locked,
			count = cart.taste.count,
			price = math.max(1, math.floor(locked.seed * cart.taste.price + 0.5)),
			taste = true,
		})
	end
	return offers
end

return CropConfig
