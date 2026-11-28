-- CropConfig: the crop field's shared numbers and pure helpers (E1a2, docs/EXPANSION.md §5; numbers since E1d1 from docs/ECONOMY.md →
-- "EV", the engagement-first economy, since EV2a). Shared: the server prices, grows and pays from this table only, the client renders it. Pure data +
-- helpers, no side effects. Crop ids are stored in profiles (Garden.Field.Squares[n].Crop, Garden.Seeds, Garden.Items):
-- never rename one. tools/economy.py reads this file and `check` pins it.
-- Growth: a planted square earns growth seconds (`Grown`) at OnlineRate while its owner is online and at OfflineRate for
-- at most OfflineCapSeconds of each absence; a crop is ripe at Grown >= growSeconds and waits (never rots).

local TimeFormat = require(script.Parent:WaitForChild("TimeFormat"))
local Num = require(script.Parent:WaitForChild("Num"))

local CropConfig = {}

-- Crops in catalogue order (EV2a, docs/ECONOMY.md → "EV"; since EV3b six price tiers of 2-3 crops; since FL, 2026-11-21, ECONOMY.md →
-- Findings (FL): a tier sets net Coins per square-hour (tiers 0-2 x1.727 a tier, then x1.5) and grow time is a choice inside it, short /
-- medium / long, away-time 20 s … 14 h; until FL the times rose with every crop, 20 s … 48 h). letter: one character in the plot message (GardenRemotes.Plot field.crops);
-- sale / seed in Coins (seed = 25 % of the sale); step (EV3b, crop mastery): plants of this crop grown that open the next common crop in
-- list order (also the unit of rested mastery); quest: a milestone crop opens by handing in these crops instead (CropConfig.Mastery);
-- kg: the weight shown at size factor 1 (E1c2); xp: pet XP of one crop fed to a pet (E1a3, half the sale, at least 1: no more than
-- its Coins would buy as Berries; economy.py checks it).
-- Rare crops (E2, `rare = true`, sale and points set by hand for the days a world is reached, economy_ev.py check R; FL halved the sales): one per obby world (`world`), seeds only from the obby (CropConfig.ObbySeeds), never sold as seeds
-- (seed = 0: BuySeeds and the market cart skip them), never locked, no mastery.
CropConfig.Crops = {
	{ id = "Potato", name = "Potato", icon = "🥔", letter = "a", growSeconds = 20, sale = 9, seed = 2, step = 12, kg = 0.25, xp = 4 }, -- loc: ignore
	{ id = "Lettuce", name = "Lettuce", icon = "🥬", letter = "h", growSeconds = 60, sale = 28, seed = 7, step = 13, kg = 0.4, xp = 14 }, -- loc: ignore
	{ id = "Onion", name = "Onion", icon = "🧅", letter = "i", growSeconds = 120, sale = 55, seed = 14, step = 13, kg = 0.2, xp = 27 }, -- loc: ignore
	{ id = "Garlic", name = "Garlic", icon = "🧄", letter = "j", growSeconds = 360, sale = 290, seed = 70, step = 14, kg = 0.1, xp = 145 }, -- loc: ignore
	{ id = "Tomato", name = "Tomato", icon = "🍅", letter = "k", growSeconds = 960, sale = 750, seed = 190, step = 15, kg = 0.2, xp = 375 }, -- loc: ignore
	{ id = "Cucumber", name = "Cucumber", icon = "🥒", letter = "l", growSeconds = 1800, sale = 1400, seed = 350, step = 15, kg = 0.3, xp = 700 }, -- loc: ignore
	{ id = "Corn", name = "Corn", icon = "🌽", letter = "b", growSeconds = 900, sale = 1200, seed = 300, step = 16, quest = { Cucumber = 6, Garlic = 10 }, kg = 0.5, xp = 600 }, -- loc: ignore
	{ id = "Pepper", name = "Pepper", icon = "🌶️", letter = "m", growSeconds = 7200, sale = 10000, seed = 2500, step = 17, kg = 0.2, xp = 5000 }, -- loc: ignore
	{ id = "Broccoli", name = "Broccoli", icon = "🥦", letter = "n", growSeconds = 28800, sale = 40000, seed = 10000, step = 18, kg = 0.5, xp = 20000 }, -- loc: ignore
	{ id = "Pumpkin", name = "Pumpkin", icon = "🎃", letter = "c", growSeconds = 43200, sale = 90000, seed = 22000, step = 19, quest = { Pepper = 5, Corn = 8 }, kg = 6, xp = 45000 }, -- loc: ignore
	{ id = "Eggplant", name = "Eggplant", icon = "🍆", letter = "o", growSeconds = 18000, sale = 35000, seed = 9000, step = 20, kg = 0.4, xp = 17500 }, -- loc: ignore
	{ id = "Blueberry", name = "Blueberry", icon = "🫐", letter = "p", growSeconds = 1200, sale = 2500, seed = 600, step = 21, kg = 0.2, xp = 1250 }, -- loc: ignore
	{ id = "SweetPotato", name = "Sweet potato", icon = "🍠", letter = "q", growSeconds = 21600, sale = 65000, seed = 16000, step = 22, quest = { Blueberry = 5, Eggplant = 4 }, kg = 0.4, xp = 32500 }, -- loc: ignore
	{ id = "GiantMelon", name = "Giant melon", icon = "🍉", letter = "d", growSeconds = 50400, sale = 160000, seed = 40000, step = 23, kg = 15, xp = 80000 }, -- loc: ignore
	{ id = "Sunflower", name = "Sunflower", icon = "🌻", letter = "r", growSeconds = 36000, sale = 170000, seed = 40000, step = 24, kg = 1.5, xp = 85000 }, -- loc: ignore
	{ id = "Pineapple", name = "Pineapple", icon = "🍍", letter = "s", growSeconds = 1800, sale = 8500, seed = 2100, step = 25, kg = 1.5, xp = 4250 }, -- loc: ignore
	{ id = "GoldenCarrot", name = "Golden carrot", icon = "🥕", letter = "e", growSeconds = 43200, sale = 25000, seed = 0, kg = 0.3, xp = 12500, rare = true, world = 1 }, -- loc: ignore
	{ id = "FrostGrape", name = "Frost grape", icon = "🍇", letter = "f", growSeconds = 57600, sale = 75000, seed = 0, kg = 0.5, xp = 37500, rare = true, world = 2 }, -- loc: ignore
	{ id = "GlowMushroom", name = "Glow mushroom", icon = "🍄", letter = "g", growSeconds = 72000, sale = 150000, seed = 0, kg = 0.2, xp = 75000, rare = true, world = 3 }, -- loc: ignore
}
-- Fruit trees (TR, docs/EXPANSION.md §5.4; numbers ECONOMY.md → TR0, model economy_ev `trees` / `obby_trees`): perennials that join
-- Crops / ById (a sapling is a seed of the tree, its fruit the crop in the barn) but not the Ladder (no unlock chain, cart, staples or
-- requests). growSeconds = the time per fruit and sale = one fruit; tree.First = growth seconds before the first fruit, tree.Cap = fruit
-- held (at the cap the tree stops bearing). Stall trees (`stallOrder`): saplings at `seed` each, sold from the `unlockWith` crop's unlock
-- in the stall rotation (Stall.Tree*), as many as the player wants (TR5: no cap). Rare trees: tree.MeterEvery = every n-th rare seed of
-- the world's stage meters is a sapling instead while the player has fewer than tree.Max. Trees have no rested mastery (no `step`).
-- TR4: a tree takes a 2 x 2 block of squares (CropConfig.TreeBlock) and earns what 4 squares of its tier earn.
CropConfig.Trees = {
	{ id = "Apple", name = "Apple", treeName = "Apple tree", icon = "🍎", letter = "t", growSeconds = 300, sale = 720, seed = 9000, kg = 0.2, xp = 360, -- loc: ignore
		unlockWith = "Cucumber", stallOrder = 101, tree = { First = 7200, Cap = 8 } },
	{ id = "GoldenApple", name = "Golden apple", treeName = "Golden apple tree", icon = "🍏", letter = "u", growSeconds = 2700, sale = 16777, seed = 0, kg = 0.25, xp = 8388, -- loc: ignore
		rare = true, world = 1, tree = { First = 28800, Cap = 8, Max = 3, MeterEvery = 3 } },
}
for _, tree in CropConfig.Trees do
	table.insert(CropConfig.Crops, tree)
end
CropConfig.ById = {}
CropConfig.ByLetter = {}
for _, crop in CropConfig.Crops do
	CropConfig.ById[crop.id] = crop
	CropConfig.ByLetter[crop.letter] = crop
end

-- The field's shape (E1d2): rows of RowWidths squares from the plot outwards, each row centred on a grid of GridColumns
-- columns (the widest row). Squares are numbered row by row from the plot, left to right as seen from the plot (1..MaxSquares);
-- the numbers are stored (Field.Open, Field.Squares, FieldPets[uid].Square): never reorder the rows.
-- FX (2026-11-22, the user): rows 6-11 (3 x 8, then 3 x 6) doubled the field from 36 to 78 squares.
CropConfig.RowWidths = { 6, 6, 8, 8, 8, 8, 8, 8, 6, 6, 6 }
CropConfig.GridColumns = 8
CropConfig.MaxSquares = 78
CropConfig.StartSquares = 4 -- a new field (E1a2 decision 3: with StartSeeds, so the first plant needs no shop)
CropConfig.StartOpen = { 3, 4, 9, 10 } -- the 2 x 2 block at the front centre
CropConfig.StartSeeds = { Potato = 4 }
-- Expansions[n] = the square bought when StartSquares + n - 1 are open (any locked square the player picks): Coins and the
-- (EV2a: x 1.33 per square up to the 16th, then x 1.93; since FXP x 1.93 only for the 17th-24th, then x 1.33 again; the other field
-- sinks stay priced on the EV2a ladder (economy_ev anchor); Coins only since EV3b).
CropConfig.Expansions = {
	{ price = 290 },
	{ price = 400 },
	{ price = 500 },
	{ price = 700 },
	{ price = 900 },
	{ price = 1200 },
	{ price = 1600 },
	{ price = 2100 },
	{ price = 2800 },
	{ price = 4000 },
	{ price = 5000 },
	{ price = 6500 },
	{ price = 9000 },
	{ price = 12000 },
	{ price = 16000 },
	{ price = 21000 },
	{ price = 40000 },
	{ price = 80000 },
	{ price = 150000 },
	{ price = 290000 },
	{ price = 550000 },
	{ price = 1100000 },
	{ price = 2100000 },
	{ price = 4000000 },
	-- FXP (2026-11-22, the user: re-priced on the flatter post-FL income; docs/ECONOMY.md → Decisions (FXP)): x 1.33 again from the
	-- 29th square (was x 1.93 up to 750 M)
	{ price = 5500000 },
	{ price = 7000000 },
	{ price = 9500000 },
	{ price = 13000000 },
	{ price = 17000000 },
	{ price = 22000000 },
	{ price = 29000000 },
	{ price = 40000000 },
}
-- FX: every square bought past the ladder (the 37th open square on) costs this flat price, the ladder's last one (any locked
-- square the player picks, as above).
CropConfig.LateSquarePrice = 40000000

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
		if crop.rare and not crop.tree and crop.world == world then
			return crop
		end
	end
	return nil
end
-- TR: the rare tree of obby world `world` (its saplings come from the world's stage meters), or nil.
function CropConfig.RareTreeOf(world: number?)
	for _, tree in CropConfig.Trees do
		if tree.rare and tree.world == world then
			return tree
		end
	end
	return nil
end
CropConfig.BarnCapacity = 40 -- seeds of all crops together, and the crops a Tending pet may store, before the Barn upgrade

-- Field upgrades (E1c1, docs/ECONOMY.md → upgrades): prices[n] = Coins for level n (Coins only since EV3b). Growth: each level -step of every grow time
-- (earned growth runs 1 / (1 - step × level) as fast); Barn: each level +step capacity. Ids are stored
-- (Garden.Field.Upgrades[id] = level): never rename one.
CropConfig.Upgrades = {
	{ id = "Growth", icon = "🌱", step = 0.05, prices = { 3000, 18000, 450000, 22000000 } },
	{ id = "Barn", icon = "🏠", step = 20, prices = { 1200, 5000, 21000, 550000, 15000000 } },
}
CropConfig.UpgradeById = {}
for _, upgrade in CropConfig.Upgrades do
	CropConfig.UpgradeById[upgrade.id] = upgrade
end

-- Market cart (E1c4, docs/EXPANSION.md §5.2; approved 2026-11-03): daily offers from the UTC day. Each bargain sells `count` seeds of a
-- different unlocked crop at (1 - discount) of the catalogue price; the taste sells `count` seeds of the next locked crop at the catalogue
-- price × `price`, offered once crop `fromCrop` is unlocked (EV3b; earlier tastes broke the day 1-3 parity in economy.py). Quantities
-- are per player and day (Garden.Cart). Seeds the player holds can be planted while their crop is locked; the catalogue keeps the lock.
CropConfig.Cart = {
	bargains = { { count = 10, discount = 0.3 }, { count = 5, discount = 0.5 } },
	taste = { count = 2, price = 1, fromCrop = "Garlic" },
}
CropConfig.DaySeconds = TimeFormat.DAY

-- Daily requests (E5a, docs/GDD.md §7.9 → Requests; model economy_ev `req_*`, ECONOMY.md → EV "Requests"): `Slots` tracked requests
-- "grow `need` of crop X" per player; harvests of the crop count (nothing handed in). Eligible crops: unlocked common crops with
-- `order` ≥ MinOrder and growSeconds ≤ MaxGrow; the board opens with 2 of them. need = Share × a day's income ÷ (the crop's sale ×
-- pet multiplier), at least MinNeed, at most half the barn; a day's income = crop sales + request bonuses of the previous UTC day or
-- so far today, whichever is more, at least MinIncome. A finished request pays Bonus × need × the crop's sale (+ pet multiplier) and
-- with DropChance a drop: a rare seed of the highest world with a finished stage or a free egg (`DropEggFor`), half and half. An unfinished
-- request stays; finished slots refill on the next UTC day. No timed run and no Sunshine until EV2c (the user, 2026-11-19).
CropConfig.Requests = {
	Slots = 3,
	MinOrder = 3,
	MaxGrow = 8 * 3600, -- OG2b: same eligible crops / 4 h online at the base ×2 rate
	Share = 0.3,
	MinNeed = 3,
	MinIncome = 2000,
	Bonus = 0.6,
	DropChance = 1 / 3,
	DropEgg = "Basic",
	-- EG (the user, 2026-11-20): from LateDropAfter's crop on (Pumpkin) the drop is a Topaz egg; a Pearl egg is worth nothing by then
	LateDropEgg = "Golden",
	LateDropAfter = "Pumpkin",
}

-- The free egg (PetConfig.Eggs id) a request drop gives a player with the open-crop set `unlocked`.
function CropConfig.DropEggFor(unlocked): string
	local rules = CropConfig.Requests
	return if type(unlocked) == "table" and unlocked[rules.LateDropAfter] == true then rules.LateDropEgg else rules.DropEgg
end

-- The crops that requests may ask for with the unlocked set `unlocked`, in ladder order.
function CropConfig.RequestCrops(unlocked)
	local rules = CropConfig.Requests
	local list = {}
	for _, crop in CropConfig.Ladder do
		if crop.order >= rules.MinOrder and crop.growSeconds <= rules.MaxGrow and CropConfig.IsUnlocked(unlocked, crop.id) then
			table.insert(list, crop)
		end
	end
	return list
end

-- The rotating seed stall (ST, docs/GDD.md §7.9; model economy_ev `st_*`, ECONOMY.md → Decisions "ST"). A restock block is
-- floor(os.time() / Seconds) (UTC hours). Always in stock, without a count: the first `Staples` crops of the ladder, the newest unlocked
-- crop, the newest unlocked crop of at least `LongSeconds` (FL: an overnight staple, so every night has a long crop) and the crops a next
-- talent level or the open quest asks for (CropConfig.StallAlways). Every other unlocked common crop is in stock in a block when its
-- draw (StallStock) says so: chance `Chance`, and at least every `Pity` blocks; then `Count` seeds per player per block (Garden.Stall).
-- TR5: a stall tree's saplings rotate rarer and fewer: `TreeChance`, at least every `TreePity` blocks, `TreeCount` per player per block.
CropConfig.Stall = {
	Seconds = 3600,
	Staples = 3,
	Chance = 0.5,
	Pity = 3,
	Count = 12,
	LongSeconds = 21600,
	TreeChance = 0.1,
	TreePity = 24,
	TreeCount = 1,
}

-- Garden tools (E1c3, docs/EXPANSION.md §6; numbers approved 2026-11-03, docs/ECONOMY.md → "Garden tools at F2"): levels bought with
-- Coins; Garden.Tools[id] = level. effect[n] at level n: Sorter = a harvest's size factor x (1 + effect)
-- (owner and Tending pets alike); Cloches = growth while the owner is online x (1 + effect), nothing offline; Shears = the chance of a second
-- crop of the same size per harvest (no extra mastery, no seed). Ids are stored: never rename one.
CropConfig.Tools = {
	{ id = "Sorter", icon = "🔍", effect = { 0.05, 0.10, 0.15 }, prices = { 10000, 220000, 45000000 } },
	{ id = "Cloches", icon = "🔔", effect = { 0.07, 0.14, 0.20 }, prices = { 4000, 30000, 6000000 } },
	{ id = "Shears", icon = "✂️", effect = { 0.05, 0.10, 0.15 }, prices = { 18000, 800000, 160000000 } },
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

-- Catalogue / displayed time is the away-time baseline; playing counts it down faster (OG2, 2026-11-20).
CropConfig.OnlineRate = 2.0
CropConfig.OfflineRate = 1.0
CropConfig.OfflineCapSeconds = 24 * 3600 -- was 12 h
-- Field-job training has its own clock, preserving the pace from before OG2.
CropConfig.WorkOnlineRate = 1.0
CropConfig.WorkOfflineRate = 0.5
CropConfig.SettleSeconds = 60 -- online growth is settled at least this often (and before every field action, on join and leave)

-- Crop mastery (EV3b, docs/GDD.md §7.9; numbers signed off 2026-11-17, docs/ECONOMY.md → EV3): a crop's level (★) comes from the plants
-- of it grown (Garden.Crops[id].N): Levels[L] plants for level L; FL: a quick crop takes the first `LevelsBy` band whose UpTo ≥ its base
-- growSeconds (it stays worth planting on the flatter ladder). A level never drops: it is at least the points spent on the crop (counts
-- raised by FL keep earned upgrades). A harvest of a common crop (by hand or a Tending
-- pet; not the Shears' extra crop) adds one plant. The next common crop in list order opens when the previous one reaches its `step`
-- plants, a crop with `quest` when the quest's crops are handed in (piece by piece, no expiry); the quest gives QuestSeeds seeds of the new
-- crop. Rested mastery (silent: never shown): each day away past the first adds RestPerDay to Garden.Rested (cap RestCap); while it lasts
-- a plant counts double and uses 1 / step of it.
-- Crop upgrades (EV3c): every level gives one point, spent on any of the crop's lines, up to Points.PerLine in one (Garden.Crops[id].Pts =
-- { [line] = points }; no reset). n points in a line: Value sale × (1 + n · Points.Value), Size size factor × (1 + n · Points.Size), Speed
-- grow time × (1 - n · Points.Speed): the crop's growth rate × 1 / (1 - n · Points.Speed).
CropConfig.Mastery = {
	Levels = { 25, 75, 200 },
	LevelsBy = { -- FL (2026-11-21): Potato, Lettuce, Onion, Garlic / Tomato, Cucumber, Corn, Blueberry, Pineapple
		{ UpTo = 600, Levels = { 25, 225, 600 } },
		{ UpTo = 3600, Levels = { 25, 110, 300 } },
	},
	RestPerDay = 0.5,
	RestCap = 3,
	QuestSeeds = 4,
	Points = { Value = 0.11, Size = 0.11, Speed = 0.11, PerLine = 3 },
}
CropConfig.PointLines = { "Value", "Size", "Speed" } -- the crop page's order
CropConfig.PointIcons = { Value = "💰", Size = "📏", Speed = "⚡" } -- the crop page's icon tiles and the upgrade toast

-- The common crops in unlock order (Potato first, always open); trees are not on it.
CropConfig.Ladder = {}
for _, crop in CropConfig.Crops do
	if not crop.rare and not crop.tree then
		table.insert(CropConfig.Ladder, crop)
	end
end
for index, crop in CropConfig.Ladder do
	crop.order = index
end

-- The plant counts of `crop`'s mastery levels (FL: its grow-time band, else Mastery.Levels).
function CropConfig.LevelsOf(crop): { number }
	local seconds = crop and crop.growSeconds or math.huge
	for _, band in CropConfig.Mastery.LevelsBy do
		if seconds <= band.UpTo then
			return band.Levels
		end
	end
	return CropConfig.Mastery.Levels
end

-- Mastery level (0..#Levels) of `crop` with `n` plants grown and the points `pts` spent on it: the count's level, never below the
-- points spent (FL raised the counts of quick crops; an earned level stays).
function CropConfig.MasteryLevel(crop, n: number?, pts): number
	local level = 0
	for L, need in CropConfig.LevelsOf(crop) do
		if (n or 0) >= need then
			level = L
		end
	end
	return math.max(level, CropConfig.SpentPoints(pts))
end

-- EV3c: the points in line `line` of the points table `pts` ({ Value = 2, … }, nil = none): a whole number 0..Points.PerLine (anything
-- else counts as 0).
function CropConfig.PointsIn(pts, line: string): number
	local n = type(pts) == "table" and pts[line]
	if type(n) ~= "number" or n ~= n then
		return 0
	end
	return math.clamp(math.floor(n), 0, CropConfig.Mastery.Points.PerLine)
end

-- Points spent in `pts`, and the free points of a crop with `n` plants grown and those points (never below 0).
function CropConfig.SpentPoints(pts): number
	local spent = 0
	for _, line in CropConfig.PointLines do
		spent += CropConfig.PointsIn(pts, line)
	end
	return spent
end
function CropConfig.FreePoints(crop, n: number?, pts): number
	return math.max(0, CropConfig.MasteryLevel(crop, n, pts) - CropConfig.SpentPoints(pts))
end

-- The sale multiplier (Value), the size factor multiplier (Size) and the growth rate multiplier (Speed) of the points `pts`.
function CropConfig.SaleMult(pts): number
	return 1 + CropConfig.PointsIn(pts, "Value") * CropConfig.Mastery.Points.Value
end
function CropConfig.SizeMult(pts): number
	return 1 + CropConfig.PointsIn(pts, "Size") * CropConfig.Mastery.Points.Size
end
function CropConfig.SpeedMult(pts): number
	return 1 / (1 - CropConfig.PointsIn(pts, "Speed") * CropConfig.Mastery.Points.Speed)
end

-- Whether crop id `id` is open for a player with the unlocked set `unlocked` ({ [id] = true }): rare crops and Potato always are; a
-- stall tree with its `unlockWith` crop (TR).
function CropConfig.IsUnlocked(unlocked, id: string): boolean
	local crop = CropConfig.ById[id]
	if crop and crop.tree and not crop.rare then
		return crop.unlockWith ~= nil and CropConfig.IsUnlocked(unlocked, crop.unlockWith)
	end
	return crop ~= nil and (crop.rare == true or crop.order == 1 or (unlocked ~= nil and unlocked[id] == true))
end

-- The first locked common crop in unlock order, or nil when all are open.
function CropConfig.NextLocked(unlocked)
	for _, crop in CropConfig.Ladder do
		if not CropConfig.IsUnlocked(unlocked, crop.id) then
			return crop
		end
	end
	return nil
end

-- What opens `crop`: (the previous crop, plants of it needed) for a count unlock, or (nil, nil) for a quest crop / the first crop.
function CropConfig.UnlockNeed(crop): (any, number?)
	if crop.quest or not crop.order or crop.order <= 1 then
		return nil, nil
	end
	local previous = CropConfig.Ladder[crop.order - 1]
	return previous, previous.step
end

-- Before EV3b (migration only, PlayerProfile Version 5 and 7): the Renown level a crop needed (EV2a gates) and the two Renown curves:
-- EV2a's level L at K x L ^ P points, and the one before it (3 x L ^ 1.6).
CropConfig.Legacy = {
	Renown = { K = 0.4, P = 3 },
	RenownV4 = { K = 3, P = 1.6 },
	Gates = {
		Potato = 0, Lettuce = 1, Onion = 2, Garlic = 3, Tomato = 4, Cucumber = 5, Corn = 6, Pepper = 8, Broccoli = 11, Pumpkin = 15,
		Eggplant = 20, Blueberry = 26, SweetPotato = 33, GiantMelon = 42, Sunflower = 54, Pineapple = 68,
	},
}
local function renownPoints(curve, level: number): number
	return if level <= 0 then 0 else math.ceil(curve.K * level ^ curve.P - 1e-9)
end
local function renownLevel(curve, points: number): number
	if type(points) ~= "number" or points ~= points or points < renownPoints(curve, 1) then
		return 0
	end
	local level = math.floor((points / curve.K) ^ (1 / curve.P))
	while renownPoints(curve, level + 1) <= points do
		level += 1
	end
	while level > 0 and renownPoints(curve, level) > points do
		level -= 1
	end
	return level
end
-- Renown level (EV2a curve) of `points`, and the points of a level on that curve.
function CropConfig.Legacy.RenownLevel(points: number): number
	return renownLevel(CropConfig.Legacy.Renown, points)
end
function CropConfig.Legacy.PointsFor(level: number): number
	return renownPoints(CropConfig.Legacy.Renown, level)
end
-- Renown level on the curve before EV2a (PlayerProfile's Version 5 step).
function CropConfig.Legacy.RenownLevelV4(points: number): number
	return renownLevel(CropConfig.Legacy.RenownV4, points)
end

-- E4-thin crows (docs/ROADMAP.md → E4-thin, numbers approved 2026-11-04): the UTC day has blocks of BlockSeconds; block k (counted from
-- the Unix epoch) is a crow block when its seeded roll is below Share, the same schedule on every server. An absence that overlaps a crow
-- block while a common crop is ripe brings a raid: each such crop is rolled once per planting (Chance), at most Cap eaten per absence,
-- only once crop FromCrop is unlocked (EV3b; was Renown 3). Rare crops are never eaten. Guards: PetConfig.GuardChance.
CropConfig.Crows = { BlockSeconds = 6 * 3600, Share = 0.25, Chance = 0.3, Cap = 1, FromCrop = "Garlic" }

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

function CropConfig.WorkSeconds(online: number, offline: number): number
	return math.max(0, online) * CropConfig.WorkOnlineRate
		+ math.min(math.max(0, offline), CropConfig.OfflineCapSeconds) * CropConfig.WorkOfflineRate
end

-- Level 0..max of upgrade `id` in `upgrades` (Garden.Field.Upgrades or the panel state's field.upgrades).
function CropConfig.UpgradeLevel(upgrades, id: string): number
	local upgrade = CropConfig.UpgradeById[id]
	return if upgrade and type(upgrades) == "table" then Num.Level(upgrades[id], 0, #upgrade.prices, 0) else 0
end

-- Level 0..max of tool `id` in `tools` (Garden.Tools or the panel state's field.tools).
function CropConfig.ToolLevel(tools, id: string): number
	local tool = CropConfig.ToolById[id]
	return if tool and type(tools) == "table" then Num.Level(tools[id], 0, #tool.prices, 0) else 0
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

-- Growth seconds per real second, away / online. Upgrade and point tables accept stored or client-state values.
function CropConfig.GrowthRates(upgrades, tools, points): (number, number)
	local speed = CropConfig.GrowthSpeed(CropConfig.UpgradeLevel(upgrades, "Growth")) * CropConfig.SpeedMult(points)
	return CropConfig.OfflineRate * speed, CropConfig.OnlineRate * (1 + CropConfig.ToolEffect(tools, "Cloches")) * speed
end

-- Baseline seconds removed from a visible crop timer per real second online; upgrades affect both clocks equally.
function CropConfig.CountdownRate(tools): number
	return CropConfig.OnlineRate * (1 + CropConfig.ToolEffect(tools, "Cloches")) / CropConfig.OfflineRate
end

-- readyAt remains the actual online harvest boundary for art, badges and server authority.
function CropConfig.TimeLeft(readyAt: number, now: number, tools): number
	return math.max(0, readyAt - now) * CropConfig.CountdownRate(tools)
end

-- Shared card / ring interpolation: actual progress and ripeness, plus away-time seconds left to display.
function CropConfig.Progress(entry, crop, receivedAt: number, now: number, tools): (number, boolean, number)
	local grown, readyAt = entry.grown or 0, entry.readyAt or 0
	if grown >= crop.growSeconds or readyAt <= now then
		return 1, true, 0
	end
	local rate = (crop.growSeconds - grown) / math.max(readyAt - receivedAt, 1)
	return math.clamp((grown + rate * math.max(now - receivedAt, 0)) / crop.growSeconds, 0, 1), false,
		CropConfig.TimeLeft(readyAt, now, tools)
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

-- The smallest and the largest size factor a harvest can give (the largest with the top Seed sorter level and every point in Size,
-- EV3c). look = true: the largest the plant art is built for (without Size points; PlantGrowth clamps a bigger factor's look to it).
function CropConfig.SizeBounds(look: boolean?): (number, number)
	local sorter = CropConfig.ToolById.Sorter
	local points = CropConfig.Mastery.Points
	local high = sizeOf(CropConfig.SizeZCap) * (1 + sorter.effect[#sorter.effect])
	return sizeOf(-CropConfig.SizeZCap), if look then high else high * (1 + points.PerLine * points.Size)
end

-- "Giant", "Big" or nil for a size factor of a crop with the points `pts`: the label comes from the roll (the Seed sorter included),
-- not from the Size points (EV3c: with them every harvest would be Big).
function CropConfig.SizeLabel(factor: number, pts): string?
	factor /= CropConfig.SizeMult(pts)
	if factor >= sizeOf(CropConfig.SizeGiantZ) then
		return "Giant"
	end
	return if factor >= sizeOf(CropConfig.SizeBigZ) then "Big" else nil
end

-- Coins (before the pet bonus) for crops of `crop` whose size factors add up to `sizeSum`, with the crop's points `pts` (EV3c Value):
-- the one rounding rule.
function CropConfig.SaleValue(crop, sizeSum: number, pts): number
	return math.floor(crop.sale * CropConfig.SaleMult(pts) * sizeSum + 0.5)
end

-- The sale of one crop of standard size with the points `pts` (the price shown on rows and the crop page).
function CropConfig.SalePrice(crop, pts): number
	return CropConfig.SaleValue(crop, 1, pts)
end

-- Look stage 1..3 of a planted crop (3 = ripe), from its growth seconds. A tree (TR): 1 / 2 while it grows to tree.First, then 2 while
-- bare and 3 while fruit hangs on it (`fruit`).
function CropConfig.Stage(crop, grown: number, fruit: number?): number
	if crop.tree then
		if grown >= crop.tree.First then
			return if (fruit or 0) > 0 then 3 else 2
		end
		return if grown >= crop.tree.First / 2 then 2 else 1
	end
	if grown >= crop.growSeconds then
		return 3
	end
	return if grown >= crop.growSeconds / 2 then 2 else 1
end

-- TR: adds `growth` growth seconds to the tree square `entry` ({ Grown, Fruit, Next }) of tree `crop`: first growth up to tree.First,
-- then one fruit per crop.growSeconds up to tree.Cap; at the cap the tree stops bearing (Next = 0) and further growth is lost. A remainder
-- within `epsilon` of a boundary counts as reached. Returns the fruit gained.
function CropConfig.GrowTree(crop, entry, growth: number, epsilon: number?): number
	local tree, eps = crop.tree, epsilon or 0
	local grown = entry.Grown or 0
	if grown < tree.First then
		local use = math.min(growth, tree.First - grown)
		grown += use
		growth -= use
		if tree.First - grown <= eps then
			grown = tree.First
		end
		entry.Grown = grown
	end
	local fruit = entry.Fruit or 0
	if grown < tree.First or fruit >= tree.Cap then
		entry.Next = 0
		return 0
	end
	local next = (entry.Next or 0) + math.max(0, growth)
	local gained = math.min(tree.Cap - fruit, math.floor((next + eps) / crop.growSeconds))
	entry.Fruit = fruit + gained
	entry.Next = if entry.Fruit >= tree.Cap then 0 else math.max(0, next - gained * crop.growSeconds)
	return gained
end

-- TR: growth seconds tree square `entry` still needs for its next fruit (the first fruit comes a fruit time after tree.First), or nil
-- at the cap (it does not grow).
function CropConfig.TreeNeed(crop, entry): number?
	local tree = crop.tree
	local grown, fruit = entry.Grown or 0, entry.Fruit or 0
	if fruit >= tree.Cap then
		return nil
	end
	if grown < tree.First then
		return tree.First - grown + crop.growSeconds
	end
	return math.max(0, crop.growSeconds - (entry.Next or 0))
end

-- Expansion that buys the next square of a field with `open` squares open, or nil at MaxSquares.
local lateExpansion = table.freeze({ price = CropConfig.LateSquarePrice })
function CropConfig.NextExpansion(open: number)
	if open < CropConfig.StartSquares or open >= CropConfig.MaxSquares then
		return CropConfig.Expansions[open - CropConfig.StartSquares + 1]
	end
	return CropConfig.Expansions[open - CropConfig.StartSquares + 1] or lateExpansion
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

-- TR4: the 2 x 2 block of a tree whose anchor is `anchor` (its front-left square, the lowest number; the tree is stored there):
-- { anchor, right, behind, behind right }, or nil where the block leaves the field.
function CropConfig.TreeBlock(anchor: number): { number }?
	local row, col = CropConfig.Cell(anchor)
	if not row then
		return nil
	end
	local right, behind, corner = CropConfig.SquareAt(row, col + 1), CropConfig.SquareAt(row + 1, col), CropConfig.SquareAt(row + 1, col + 1)
	return if right and behind and corner then { anchor, right, behind, corner } else nil
end

-- TR4: the anchors of the tree blocks that hold square `square` (up to 4).
function CropConfig.TreeAnchors(square: number): { number }
	local row, col = CropConfig.Cell(square)
	local anchors = {}
	if row then
		for _, d in { { 0, 0 }, { 0, -1 }, { -1, 0 }, { -1, -1 } } do
			local anchor = CropConfig.SquareAt(row + d[1], col + d[2])
			if anchor and CropConfig.TreeBlock(anchor) then
				table.insert(anchors, anchor)
			end
		end
	end
	return anchors
end

-- TR4: { [square] = anchor } for every square a tree takes (its anchor included); `cropOf(square)` = the crop planted there or nil.
function CropConfig.TreeCover(cropOf: (number) -> any): { [number]: number }
	local cover = {}
	for square = 1, CropConfig.MaxSquares do
		local crop = cropOf(square)
		local block = crop and crop.tree and CropConfig.TreeBlock(square)
		if block then
			for _, n in block do
				cover[n] = square
			end
		end
	end
	return cover
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
	return TimeFormat.UtcDay(now)
end

-- The market cart's offers on day `day` for a player with the unlocked set `unlocked` (Garden.Unlocked), in slot order: { slot, crop, count, price (Coins per seed),
-- discount?, taste? }. The same for every player with the same unlocked crops (the pick is seeded by the day only).
function CropConfig.CartOffers(day: number, unlockedSet)
	local cart = CropConfig.Cart
	local unlocked = {}
	for _, crop in CropConfig.Ladder do -- rare seeds come only from the obby
		if CropConfig.IsUnlocked(unlockedSet, crop.id) then
			table.insert(unlocked, crop)
		end
	end
	local locked = CropConfig.NextLocked(unlockedSet)
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
	if locked and CropConfig.IsUnlocked(unlockedSet, cart.taste.fromCrop) then
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

-- The seed stall's restock block for server time `now`, and the server time at which block `block` ends.
function CropConfig.StallBlock(now: number): number
	return math.floor(now / CropConfig.Stall.Seconds)
end
function CropConfig.StallEnds(block: number): number
	return (block + 1) * CropConfig.Stall.Seconds
end

-- Whether a rotating crop is in stock in block `block`: a draw seeded by the block and the crop's ladder position only (the same on every
-- server and for every player who has it), or the pity turn (block + position) % Pity == 0 (never out more than Pity - 1 blocks in a row).
-- A stall tree draws with TreeChance / TreePity (TR5).
function CropConfig.StallStock(block: number, crop): boolean
	local stall = CropConfig.Stall
	local order = crop.order or crop.stallOrder or 0
	local chance, pity = stall.Chance, stall.Pity
	if crop.tree then
		chance, pity = stall.TreeChance, stall.TreePity
	end
	return Random.new(block * 7919 + order * 104729):NextNumber() < chance or (block + order) % pity == 0
end

-- How many of rotating crop `crop` one player may buy in a block it is in stock (TR5: a stall tree's saplings are fewer).
function CropConfig.StallCount(crop): number
	return if crop.tree then CropConfig.Stall.TreeCount else CropConfig.Stall.Count
end

-- The crops always in stock for a player with the unlocked set `unlocked`: the staples, the newest unlocked crop (the last one in ladder
-- order), the newest unlocked crop of at least Stall.LongSeconds (FL) and the ids in `extra` (the next talent levels' and the open
-- quest's crops) -> { [cropId] = true }.
function CropConfig.StallAlways(unlocked, extra: { string }?)
	local always = {}
	local newest, newestLong = nil, nil
	for _, crop in CropConfig.Ladder do
		if crop.order <= CropConfig.Stall.Staples then
			always[crop.id] = true
		end
		if CropConfig.IsUnlocked(unlocked, crop.id) then
			newest = crop
			if crop.growSeconds >= CropConfig.Stall.LongSeconds then
				newestLong = crop
			end
		end
	end
	if newest then
		always[newest.id] = true
	end
	if newestLong then
		always[newestLong.id] = true
	end
	for _, id in extra or {} do
		always[id] = true
	end
	return always
end

-- The rotating crops of a player in block `block`: { [cropId] = in stock } for every unlocked common crop not in `always` and every
-- unlocked stall tree (TR: its saplings rotate like a crop).
function CropConfig.StallRotating(block: number, unlocked, always): { [string]: boolean }
	local rotating = {}
	for _, crop in CropConfig.Ladder do
		if CropConfig.IsUnlocked(unlocked, crop.id) and not always[crop.id] then
			rotating[crop.id] = CropConfig.StallStock(block, crop)
		end
	end
	for _, tree in CropConfig.Trees do
		if tree.stallOrder and CropConfig.IsUnlocked(unlocked, tree.id) then
			rotating[tree.id] = CropConfig.StallStock(block, tree)
		end
	end
	return rotating
end

return CropConfig
