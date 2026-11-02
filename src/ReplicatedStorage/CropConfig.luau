-- CropConfig: the crop field's shared numbers and pure helpers (E1a2, docs/EXPANSION.md §5, numbers from docs/ECONOMY.md →
-- "Inputs ready for E1"). Shared: the server prices, grows and pays from this table only, the client renders it. Pure data +
-- helpers, no side effects. Crop ids are stored in profiles (Garden.Field.Squares[n].Crop, Garden.Seeds, Garden.Items):
-- never rename one. tools/economy.py reads this file and `check` pins it.
-- Growth: a planted square earns growth seconds (`Grown`) at OnlineRate while its owner is online and at OfflineRate for
-- at most OfflineCapSeconds of each absence; a crop is ripe at Grown >= growSeconds and waits (never rots).

local CropConfig = {}

-- Crops in catalogue order. letter: one character in the plot message (GardenRemotes.Plot field.crops); renown: Renown level
-- that unlocks the crop; sale / seed in Coins (seed = 25 % of the sale); tier: Renown points per harvest (RenownPoints).
CropConfig.Crops = {
	{ id = "Potato", name = "Potato", icon = "🥔", letter = "a", tier = 1, growSeconds = 5 * 60, sale = 2, seed = 1, renown = 0 }, -- loc: ignore
	{ id = "Corn", name = "Corn", icon = "🌽", letter = "b", tier = 2, growSeconds = 6 * 3600, sale = 108, seed = 27, renown = 8 }, -- loc: ignore
	{ id = "Pumpkin", name = "Pumpkin", icon = "🎃", letter = "c", tier = 2, growSeconds = 8 * 3600, sale = 144, seed = 36, renown = 8 }, -- loc: ignore
	{ id = "GiantMelon", name = "Giant melon", icon = "🍉", letter = "d", tier = 3, growSeconds = 12 * 3600, sale = 432, seed = 108, renown = 25 }, -- loc: ignore
}
CropConfig.ById = {}
CropConfig.ByLetter = {}
for _, crop in CropConfig.Crops do
	CropConfig.ById[crop.id] = crop
	CropConfig.ByLetter[crop.letter] = crop
end

CropConfig.StartSquares = 4 -- a new field (E1a2 decision 3: with StartSeeds, so the first plant needs no shop)
CropConfig.StartSeeds = { Potato = 4 }
CropConfig.MaxSquares = 12
CropConfig.Columns = 4 -- squares per field row (4 x 3 at 12 squares; PlotView draws row by row from the plot outwards)
-- Expansions[n] buys square StartSquares + n: Coins and the Renown level it needs.
CropConfig.Expansions = {
	{ price = 600, renown = 1 },
	{ price = 1500, renown = 2 },
	{ price = 3500, renown = 4 },
	{ price = 7500, renown = 7 },
	{ price = 14000, renown = 10 },
	{ price = 24000, renown = 14 },
	{ price = 40000, renown = 19 },
	{ price = 65000, renown = 25 },
}

CropConfig.RenownPoints = { 1, 3, 6, 12 } -- points per harvest by crop tier (4 = rare crops, E2)
CropConfig.RenownK = 3 -- level L needs RenownK * L ^ RenownP points in total
CropConfig.RenownP = 1.6
CropConfig.BarnCapacity = 40 -- seeds of all crops together, and the crops a Tending pet may store, before the Barn upgrade

-- Field upgrades (E1c1, docs/ECONOMY.md → upgrades): prices[n] = Coins for level n. Growth: each level -step of every grow time
-- (earned growth runs 1 / (1 - step × level) as fast); Barn: each level +step capacity. Ids are stored
-- (Garden.Field.Upgrades[id] = level): never rename one.
CropConfig.Upgrades = {
	{ id = "Growth", icon = "🌱", step = 0.05, prices = { 3000, 8000, 20000, 45000 } },
	{ id = "Barn", icon = "🏠", step = 20, prices = { 1500, 4000, 10000, 25000, 60000 } },
}
CropConfig.UpgradeById = {}
for _, upgrade in CropConfig.Upgrades do
	CropConfig.UpgradeById[upgrade.id] = upgrade
end

-- Field pets (E1b, docs/ECONOMY.md → "Field-pet re-run"): PetSlotPrices[n] = price of the n-th field pet slot (slot 1 is free).
-- A player's pens convert once: PetSlotsFromPens[pens bought] slots, the Coins paid for pens beyond those slots' prices refunded.
-- A Tending pet harvests only while the crops in the barn (Items) are fewer than BarnCapacity.
CropConfig.PetSlotPrices = { 0, 2500, 9000 }
CropConfig.PetSlotsFromPens = { 1, 2, 2, 3, 3, 3 }

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

-- How much faster crops grow at Growth level `level` (earned growth seconds are multiplied by this).
function CropConfig.GrowthSpeed(level: number): number
	return 1 / (1 - CropConfig.UpgradeById.Growth.step * level)
end

-- Seeds the stock holds (and crops a Tending pet may store) at Barn level `level`.
function CropConfig.BarnFor(level: number): number
	return CropConfig.BarnCapacity + CropConfig.UpgradeById.Barn.step * level
end

-- Look stage 1..3 of a planted crop (3 = ripe), from its growth seconds.
function CropConfig.Stage(crop, grown: number): number
	if grown >= crop.growSeconds then
		return 3
	end
	return if grown >= crop.growSeconds / 2 then 2 else 1
end

-- Expansion that buys the next square of a field with `count` squares, or nil at MaxSquares.
function CropConfig.NextExpansion(count: number)
	return CropConfig.Expansions[count - CropConfig.StartSquares + 1]
end

-- Squares (1..count) a pet on `square` reaches with reach `shape` (PetConfig.ReachShape: 0 own, 1 plus the 4 next to it, 2 the
-- 3 x 3 block), on the field grid of Columns squares per row.
function CropConfig.Reach(square: number, shape: number, count: number): { number }
	local col, row = (square - 1) % CropConfig.Columns, (square - 1) // CropConfig.Columns
	local list = {}
	for dy = -1, 1 do
		for dx = -1, 1 do
			local inShape = (dx == 0 and dy == 0) or (shape == 1 and (dx == 0 or dy == 0)) or shape >= 2
			local c, r = col + dx, row + dy
			local n = r * CropConfig.Columns + c + 1
			if inShape and c >= 0 and c < CropConfig.Columns and r >= 0 and n <= count then
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

return CropConfig
