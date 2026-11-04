-- CropConfig: the crop field's shared numbers and pure helpers (E1a2, docs/EXPANSION.md §5; numbers since E1d1 from docs/ECONOMY.md →
-- "Direction change", candidate F2: farming is the main game). Shared: the server prices, grows and pays from this table only, the client renders it. Pure data +
-- helpers, no side effects. Crop ids are stored in profiles (Garden.Field.Squares[n].Crop, Garden.Seeds, Garden.Items):
-- never rename one. tools/economy.py reads this file and `check` pins it.
-- Growth: a planted square earns growth seconds (`Grown`) at OnlineRate while its owner is online and at OfflineRate for
-- at most OfflineCapSeconds of each absence; a crop is ripe at Grown >= growSeconds and waits (never rots).

local CropConfig = {}

-- Crops in catalogue order. letter: one character in the plot message (GardenRemotes.Plot field.crops); renown: Renown level
-- that unlocks the crop; sale / seed in Coins (seed = 25 % of the sale); tier: Renown points per harvest (RenownPoints);
-- kg: the weight shown at size factor 1 (E1c2); xp: pet XP of one crop fed to a pet (E1a3, half the sale, at least 1: no more than
-- its Coins would buy as Berries; economy.py checks it).
CropConfig.Crops = {
	{ id = "Potato", name = "Potato", icon = "🥔", letter = "a", tier = 1, growSeconds = 5 * 60, sale = 6, seed = 2, renown = 0, kg = 0.25, xp = 3 }, -- loc: ignore
	{ id = "Corn", name = "Corn", icon = "🌽", letter = "b", tier = 2, growSeconds = 6 * 3600, sale = 1008, seed = 252, renown = 1, kg = 0.5, xp = 504 }, -- loc: ignore
	{ id = "Pumpkin", name = "Pumpkin", icon = "🎃", letter = "c", tier = 2, growSeconds = 8 * 3600, sale = 1344, seed = 336, renown = 1, kg = 6, xp = 672 }, -- loc: ignore
	{ id = "GiantMelon", name = "Giant melon", icon = "🍉", letter = "d", tier = 3, growSeconds = 12 * 3600, sale = 4032, seed = 1008, renown = 5, kg = 15, xp = 2016 }, -- loc: ignore
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
-- Renown level it needs (F2: about x 1.23 per square, 4.8 M in all).
CropConfig.Expansions = {
	{ price = 1400, renown = 0 },
	{ price = 1700, renown = 0 },
	{ price = 2100, renown = 4 }, -- squares 7-11 one Renown level below F2 (E1c3, user 2026-11-03: Casual's day-7 lead)
	{ price = 2600, renown = 5 },
	{ price = 3200, renown = 6 },
	{ price = 4000, renown = 7 },
	{ price = 4900, renown = 9 },
	{ price = 6000, renown = 11 },
	{ price = 7400, renown = 12 },
	{ price = 9200, renown = 13 },
	{ price = 11300, renown = 14 },
	{ price = 13900, renown = 15 },
	{ price = 17200, renown = 16 },
	{ price = 21100, renown = 17 },
	{ price = 26100, renown = 18 },
	{ price = 32100, renown = 19 },
	{ price = 39600, renown = 20 },
	{ price = 48800, renown = 21 },
	{ price = 60100, renown = 22 },
	{ price = 74000, renown = 23 },
	{ price = 91200, renown = 24 },
	{ price = 112400, renown = 25 },
	{ price = 138500, renown = 26 },
	{ price = 170700, renown = 27 },
	{ price = 210300, renown = 28 },
	{ price = 259200, renown = 29 },
	{ price = 319400, renown = 30 },
	{ price = 393600, renown = 31 },
	{ price = 485000, renown = 32 },
	{ price = 597600, renown = 33 },
	{ price = 736400, renown = 34 },
	{ price = 907400, renown = 35 },
}

CropConfig.RenownPoints = { 1, 3, 6, 12 } -- points per harvest by crop tier (4 = rare crops, E2)
CropConfig.RenownK = 3 -- level L needs RenownK * L ^ RenownP points in total
CropConfig.RenownP = 1.6
CropConfig.BarnCapacity = 40 -- seeds of all crops together, and the crops a Tending pet may store, before the Barn upgrade

-- Field upgrades (E1c1, docs/ECONOMY.md → upgrades): prices[n] = Coins for level n. Growth: each level -step of every grow time
-- (earned growth runs 1 / (1 - step × level) as fast); Barn: each level +step capacity. Ids are stored
-- (Garden.Field.Upgrades[id] = level): never rename one.
CropConfig.Upgrades = {
	{ id = "Growth", icon = "🌱", step = 0.05, prices = { 28000, 74700, 186700, 420000 } },
	{ id = "Barn", icon = "🏠", step = 20, prices = { 14000, 37300, 93300, 233300, 560000 } },
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
	{ id = "Sorter", icon = "🔍", effect = { 0.05, 0.10, 0.15 }, prices = { 46700, 140000, 373300 }, renown = { 10, 18, 28 } },
	{ id = "Cloches", icon = "🔔", effect = { 0.07, 0.14, 0.20 }, prices = { 37300, 112000, 280000 }, renown = { 6, 14, 24 } },
	{ id = "Shears", icon = "✂️", effect = { 0.05, 0.10, 0.15 }, prices = { 56000, 168000, 420000 }, renown = { 12, 20, 30 } },
}
CropConfig.ToolById = {}
for _, tool in CropConfig.Tools do
	CropConfig.ToolById[tool.id] = tool
end

-- Field pets (E1b, docs/ECONOMY.md → "Field-pet re-run"; five slots since E1d1): PetSlotPrices[n] = price of the n-th field pet slot (slot 1 is free).
-- A player's pens convert once: PetSlotsFromPens[pens bought] slots, the Coins paid for pens beyond those slots' prices refunded.
-- A Tending pet harvests only while the crops in the barn (Items) are fewer than BarnCapacity.
CropConfig.PetSlotPrices = { 0, 23300, 84000, 280000, 746700 }
CropConfig.PetSlotsFromPens = { 1, 2, 2, 3, 3, 3 }

-- Size roll (E1c2, docs/EXPANSION.md §5.3): every harvest's size factor = exp(SizeSigma × z - SizeSigma² / 2), mean exactly 1
-- (the ladder holds), z standard normal from the planting's own seed, capped at ±SizeZCap. Big from z >= SizeBigZ (top 20 %),
-- Giant from z >= SizeGiantZ (top 3 %). A sale pays sale × factor. tools/economy.py pins these and checks the mean.
CropConfig.SizeSigma = 0.25
CropConfig.SizeZCap = 4
CropConfig.SizeBigZ = 0.8416
CropConfig.SizeGiantZ = 1.8808

-- Passive rates (ECONOMY open decision 5: placeholders).
CropConfig.OnlineRate = 1.0
CropConfig.OfflineRate = 0.33
CropConfig.OfflineCapSeconds = 12 * 3600
CropConfig.SettleSeconds = 60 -- online growth is settled at least this often (and before every field action, on join and leave)

-- Points needed in total for Renown level `level` (0 for level 0).
function CropConfig.PointsFor(level: number): number
	if level <= 0 then
		return 0
	end
	return math.ceil(CropConfig.RenownK * level ^ CropConfig.RenownP - 1e-9)
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
		if crop.renown <= level then
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
