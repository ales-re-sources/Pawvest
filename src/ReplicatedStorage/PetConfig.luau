-- PetConfig: pets, rarities, eggs, slots, the level curve and XP sources (docs/GDD.md §7.1–7.4). Shared: the server prices,
-- rolls and validates from this table only (clients never send a price or a result), the pet UI renders it.
-- Pure data + helpers, no side effects. Kind, rarity and egg ids are stored in PlayerProfile: never rename them.
-- Bonuses are in permille (1 ‰ = 0.1 %) so sums stay exact.

local PetConfig = {}

export type Rarity = {
	id: string,
	order: number,
	bonus: number, -- base Coin bonus in permille
	sellValue: number,
	color: Color3, -- label colour (P1c)
}

export type Egg = {
	id: string,
	name: string,
	price: number,
	stand: boolean, -- sold at the hub egg stand (BuyEgg); otherwise hatched elsewhere (Golden: garden incubator, P2b)
	weights: { [string]: number }, -- rarity id → weight per 1000
}

PetConfig.Rarities = {
	{ id = "Common", order = 1, bonus = 20, sellValue = 100, color = Color3.fromRGB(200, 200, 200) },
	{ id = "Uncommon", order = 2, bonus = 40, sellValue = 200, color = Color3.fromRGB(90, 200, 90) },
	{ id = "Rare", order = 3, bonus = 70, sellValue = 500, color = Color3.fromRGB(70, 140, 255) },
	{ id = "Epic", order = 4, bonus = 100, sellValue = 1500, color = Color3.fromRGB(180, 80, 255) },
	{ id = "Legendary", order = 5, bonus = 150, sellValue = 5000, color = Color3.fromRGB(255, 170, 0) },
} :: { Rarity }

PetConfig.RarityById = {} :: { [string]: Rarity }
for _, rarity in PetConfig.Rarities do
	PetConfig.RarityById[rarity.id] = rarity
end

-- Kind id → rarity id (provisional kinds, GDD §7.1)
PetConfig.Kinds = {
	Cat = "Common",
	Dog = "Common",
	Bunny = "Uncommon",
	Fox = "Uncommon",
	Owl = "Rare",
	Panda = "Rare",
	Dragon = "Epic",
	Phoenix = "Legendary",
}

-- Rarity id → kinds of that rarity, sorted (Roll picks one uniformly)
PetConfig.KindsByRarity = {} :: { [string]: { string } }
for _, rarity in PetConfig.Rarities do
	PetConfig.KindsByRarity[rarity.id] = {}
end
for kind, rarityId in PetConfig.Kinds do
	table.insert(PetConfig.KindsByRarity[rarityId], kind)
end
for _, kinds in PetConfig.KindsByRarity do
	table.sort(kinds)
end

PetConfig.Eggs = {
	Basic = {
		id = "Basic",
		name = "Basic egg",
		price = 500,
		stand = true,
		weights = { Common = 600, Uncommon = 250, Rare = 110, Epic = 35, Legendary = 5 },
	},
	Golden = {
		id = "Golden",
		name = "Golden egg",
		price = 4000,
		stand = false,
		weights = { Uncommon = 450, Rare = 350, Epic = 150, Legendary = 50 },
	},
} :: { [string]: Egg }

PetConfig.SlotPrices = { 0, 2000, 5000 } -- SlotPrices[n] = price of the n-th equip slot; #SlotPrices = max slots
PetConfig.MaxPets = 50 -- inventory cap
PetConfig.MaxLevel = 20
PetConfig.LevelBonus = 5 -- permille per level above 1
PetConfig.MaxBonus = 500 -- cap on the summed bonus of equipped pets (+50 %)
PetConfig.AttributeName = "EquippedPets" -- player attribute "Kind:Level,…" of the equipped pets (P1c)

function PetConfig.RarityOf(kind: string): Rarity?
	local rarityId = PetConfig.Kinds[kind]
	return rarityId and PetConfig.RarityById[rarityId]
end

-- Clamps whatever is stored to a valid whole level (corrupt data counts as 1).
function PetConfig.ClampLevel(level: any): number
	if type(level) ~= "number" or level ~= level then
		return 1
	end
	return math.clamp(math.floor(level), 1, PetConfig.MaxLevel)
end

-- Picks a pet from `eggId` using `rng` (a Random): rarity by weight, then a kind of that rarity uniformly.
-- Returns kind, rarity id; nil for an unknown egg.
function PetConfig.Roll(eggId: string, rng: Random): (string?, string?)
	local egg = PetConfig.Eggs[eggId]
	if not egg then
		return nil, nil
	end
	local total = 0
	for _, rarity in PetConfig.Rarities do
		total += egg.weights[rarity.id] or 0
	end
	local pick = rng:NextInteger(1, total)
	for _, rarity in PetConfig.Rarities do
		pick -= egg.weights[rarity.id] or 0
		if pick <= 0 then
			local kinds = PetConfig.KindsByRarity[rarity.id]
			return kinds[rng:NextInteger(1, #kinds)], rarity.id
		end
	end
	return nil, nil -- unreachable while the weights are positive
end

-- Coin bonus of one pet in permille: rarity base + LevelBonus per level above 1 (0 for an unknown kind).
function PetConfig.PetBonus(pet): number
	local rarity = PetConfig.RarityOf(pet.Kind)
	if not rarity then
		return 0
	end
	return rarity.bonus + PetConfig.LevelBonus * (PetConfig.ClampLevel(pet.Level) - 1)
end

-- Coin multiplier of a list of equipped pets: 1 + min(+50 %, sum of their bonuses).
function PetConfig.Multiplier(pets: { any }): number
	local sum = 0
	for _, pet in pets do
		sum += PetConfig.PetBonus(pet)
	end
	return 1 + math.min(PetConfig.MaxBonus, sum) / 1000
end

-- XP needed to go from `level` to level + 1: round(10 × L^1.5); nil at the max level.
function PetConfig.XpToNext(level: number): number?
	if level >= PetConfig.MaxLevel then
		return nil
	end
	return math.floor(10 * level ^ 1.5 + 0.5)
end

-- XP sources (GDD §7.4); every equipped pet receives the full amount of each event
PetConfig.MedalXp = { 5, 10, 20 } -- MedalXp[medal] for the run's medal (Bronze / Silver / Gold); no medal: 0
PetConfig.CoinXp = 1 -- per collected coin
PetConfig.StudsPerXp = 20 -- movement while a stage timer runs (horizontal studs, measured on the server)
PetConfig.MaxMoveXp = 30 -- per run

-- Movement XP of a run that covered `studs` horizontal studs.
function PetConfig.MoveXp(studs: number): number
	return math.min(PetConfig.MaxMoveXp, math.floor(studs / PetConfig.StudsPerXp))
end

-- Adds `amount` XP to `pet` (mutates it): levels up while the XP reaches XpToNext, keeping the remainder; a pet at
-- the max level gains nothing (its XP stays 0). Returns the levels gained, or nil if the pet was already maxed.
function PetConfig.GainXp(pet, amount: number): number?
	local level = PetConfig.ClampLevel(pet.Level)
	if level >= PetConfig.MaxLevel then
		pet.Level, pet.XP = PetConfig.MaxLevel, 0
		return nil
	end
	local xp = (if type(pet.XP) == "number" and pet.XP == pet.XP then math.max(0, math.floor(pet.XP)) else 0) + amount
	local gained = 0
	local need = PetConfig.XpToNext(level)
	while need and xp >= need do
		xp -= need
		level += 1
		gained += 1
		need = PetConfig.XpToNext(level)
	end
	pet.Level, pet.XP = level, if need then xp else 0
	return gained
end

-- Sell value of a pet of `kind` (0 for an unknown kind).
function PetConfig.SellValue(kind: string): number
	local rarity = PetConfig.RarityOf(kind)
	return rarity and rarity.sellValue or 0
end

return PetConfig
