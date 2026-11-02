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
	hatchSeconds: number, -- real (server) time from start to ready in a garden incubator (every egg hatches there)
	look: { color: Color3, material: Enum.Material, glow: boolean }, -- the egg ball in an incubator (GardenIncubators)
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
		name = "Basic egg", -- loc: ignore (English source and fallback; players see Locale)
		price = 500,
		hatchSeconds = 300,
		look = { color = Color3.fromRGB(236, 228, 208), material = Enum.Material.SmoothPlastic, glow = false }, -- plain cream
		weights = { Common = 600, Uncommon = 250, Rare = 110, Epic = 35, Legendary = 5 },
	},
	Golden = {
		id = "Golden",
		name = "Golden egg", -- loc: ignore (English source and fallback; players see Locale)
		price = 4000,
		hatchSeconds = 3600,
		look = { color = Color3.fromRGB(255, 200, 40), material = Enum.Material.SmoothPlastic, glow = true }, -- shiny gold
		weights = { Uncommon = 450, Rare = 350, Epic = 150, Legendary = 50 },
	},
} :: { [string]: Egg }
PetConfig.EggOrder = { "Basic", "Golden" } -- incubator panel order (cheapest first)

PetConfig.SlotPrices = { 0, 2000, 5000 } -- SlotPrices[n] = price of the n-th equip slot; #SlotPrices = max slots
PetConfig.MaxPets = 50 -- inventory cap
PetConfig.MaxLevel = 20
PetConfig.LevelBonus = 5 -- permille per level above 1
PetConfig.MaxBonus = 500 -- cap on the summed bonus of equipped pets (+50 %)
PetConfig.AttributeName = "EquippedPets" -- player attribute "Kind:Level:uid,…" of the equipped pets (P1c, uid since P1e1)
PetConfig.MaxScale = 1.6 -- model size at MaxLevel relative to Lv 1 (PetLook.Scale, P1e1)
PetConfig.Tiers = { 5, 10, 15, 20 } -- first level of look tiers 1..4 (PetLook.Tier)

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

-- Look tier of a level: 0 below Tiers[1], then one more per reached threshold (Lv 5 / 10 / 15 / 20 → 1 / 2 / 3 / 4).
function PetConfig.TierOf(level: number): number
	local tier = 0
	for _, first in PetConfig.Tiers do
		if PetConfig.ClampLevel(level) >= first then
			tier += 1
		end
	end
	return tier
end

-- Size factor of a level: 1 at Lv 1, MaxScale at MaxLevel, linear in between.
function PetConfig.ScaleOf(level: number): number
	return 1 + (PetConfig.MaxScale - 1) * (PetConfig.ClampLevel(level) - 1) / (PetConfig.MaxLevel - 1)
end

export type EquippedEntry = { kind: string, level: number, uid: string?, key: string }

-- Text of the EquippedPets attribute for a list of { Kind, Level, uid } records: "Cat:1:3,Dog:20:7".
function PetConfig.EncodeEquipped(pets: { { Kind: string, Level: number, uid: string } }): string
	local parts = {}
	for _, pet in pets do
		table.insert(parts, pet.Kind .. ":" .. PetConfig.ClampLevel(pet.Level) .. ":" .. pet.uid)
	end
	return table.concat(parts, ",")
end

-- Parses the EquippedPets attribute: "Kind:Level:uid" and the pre-P1e1 form "Kind:Level" (uid = nil). Unknown kinds and
-- malformed entries are skipped, levels are clamped. `key` identifies an entry (same key = same look).
function PetConfig.DecodeEquipped(value: any): { EquippedEntry }
	local list = {}
	if type(value) ~= "string" then
		return list
	end
	for entry in string.gmatch(value, "[^,]+") do
		local kind, level, uid = string.match(entry, "^(%w+):(%d+):([%w_%-]+)$")
		if not kind then
			kind, level = string.match(entry, "^(%w+):(%d+)$")
		end
		if kind and PetConfig.RarityOf(kind) then
			local clamped = PetConfig.ClampLevel(tonumber(level))
			table.insert(list, { kind = kind, level = clamped, uid = uid, key = kind .. ":" .. clamped .. ":" .. (uid or "") })
		end
	end
	return list
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
PetConfig.MedalXp = { 5, 10, 20 } -- MedalXp[medal] for the run's medal (Bronze / Silver / Gold); no medal: FinishXp
PetConfig.FinishXp = 2 -- a finish without a medal
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

-- Aptitudes (E1b, docs/EXPANSION.md §4, numbers from docs/ECONOMY.md → "Field-pet re-run"): the jobs a pet is born with, each with
-- its own level 1..cap raised by doing the job. Stored as Pets[uid].Apt = { [id] = { L, XP } } (XP = weighted field seconds
-- towards the next level) and Pets[uid].Spec (Pest-control speciality). Ids are stored: never rename one. Rolled once (at hatch,
-- or on load for pets from before E1b) and never rerolled. Only the ids in Shown do something yet (E1b: Tending).
PetConfig.Aptitudes = { "Tending", "Fertilising", "PestControl", "Weeding", "Scouting", "Crafting" }
PetConfig.Shown = { Tending = true }
PetConfig.Specs = { "Crows", "Moles", "Slugs", "Raccoons" }
-- chance of Tending by rarity (the model's: aptitudes at birth / 5), independent of the kind so the economy model holds
PetConfig.TendingChance = { Common = 0.2, Uncommon = 0.22, Rare = 0.4, Epic = 0.5, Legendary = 0.6 }
-- aptitudes at birth by rarity: { count, chance of one more }
PetConfig.AptitudeCount = { Common = { 1, 0 }, Uncommon = { 1, 0.1 }, Rare = { 2, 0 }, Epic = { 2, 0.5 }, Legendary = { 3, 0 } }
PetConfig.AptitudeCaps = { Common = 6, Uncommon = 7, Rare = 8, Epic = 9, Legendary = 10 }
-- the kind leans the draw of the other aptitudes (weight LeanWeight against 1); Owl's Pest control is always against raccoons
PetConfig.KindLean = { Cat = "PestControl", Dog = "PestControl", Bunny = "Fertilising", Fox = "Scouting", Owl = "PestControl",
	Panda = "Weeding", Dragon = "Fertilising", Phoenix = "Scouting" }
PetConfig.LeanWeight = 3
PetConfig.KindSpec = { Owl = "Raccoons" }
-- effect of an aptitude level in share of the maximum (Tending: the chance a ripe crop is harvested and replanted at once)
PetConfig.AptitudeStrength = { 0.20, 0.35, 0.48, 0.59, 0.68, 0.76, 0.83, 0.89, 0.95, 1.00 }
PetConfig.AptitudeXpFirst = 10 * 3600 -- weighted field seconds from level 1 to 2
PetConfig.AptitudeXpRatio = 1.56 -- each next level takes this much longer
PetConfig.LiveLevelStep = 4 -- a pet from before E1b starts its aptitudes at ceil(pet level / LiveLevelStep)

-- pseudo-random generator seeded from `text` (deterministic: the same text always gives the same sequence)
local function seeded(text: string): Random
	local h = 0
	for index = 1, #text do
		h = (h * 31 + string.byte(text, index)) % 2147483647
	end
	return Random.new(h)
end

-- Rolls the aptitudes of a pet of `kind` from `seed` (owner and uid, "userId/uid"): a table { [id] = { L = level, XP = 0 } } and the
-- speciality (or nil). `withTending` makes Tending one of them (decision 3: a hatch while the owner has no Tending pet).
function PetConfig.RollAptitudes(seed: string, kind: string, withTending: boolean?, level: number?): ({ [string]: any }, string?)
	local rarityId = PetConfig.Kinds[kind] or "Common"
	local rng = seeded("apt:" .. seed .. ":" .. kind)
	local count = PetConfig.AptitudeCount[rarityId]
	local total = count[1] + (if rng:NextNumber() < count[2] then 1 else 0)
	local start = math.clamp(level or 1, 1, PetConfig.AptitudeCaps[rarityId])
	local apt = {}
	local tendingRoll = rng:NextNumber()
	if withTending or tendingRoll < PetConfig.TendingChance[rarityId] then
		apt.Tending = { L = start, XP = 0 }
		total -= 1
	end
	local pool = {}
	for _, id in PetConfig.Aptitudes do
		if id ~= "Tending" then
			table.insert(pool, id)
		end
	end
	while total > 0 and #pool > 0 do
		local weights, sum = {}, 0
		for index, id in pool do
			weights[index] = if PetConfig.KindLean[kind] == id then PetConfig.LeanWeight else 1
			sum += weights[index]
		end
		local pick = rng:NextNumber() * sum
		local chosen = #pool
		for index, weight in weights do
			pick -= weight
			if pick < 0 then
				chosen = index
				break
			end
		end
		apt[pool[chosen]] = { L = start, XP = 0 }
		table.remove(pool, chosen)
		total -= 1
	end
	local spec = nil
	if apt.PestControl then
		spec = PetConfig.KindSpec[kind] or PetConfig.Specs[rng:NextInteger(1, #PetConfig.Specs)]
	end
	return apt, spec
end

-- Aptitude level cap of a pet of `kind`.
function PetConfig.AptitudeCap(kind: string): number
	return PetConfig.AptitudeCaps[PetConfig.Kinds[kind] or "Common"]
end

-- The pet's level in aptitude `id` (0 when it does not have it).
function PetConfig.AptitudeLevel(pet, id: string): number
	local entry = type(pet) == "table" and type(pet.Apt) == "table" and pet.Apt[id]
	return if type(entry) == "table" and type(entry.L) == "number" then entry.L else 0
end

-- Effect share of aptitude `level` (0 for level 0).
function PetConfig.Strength(level: number): number
	return PetConfig.AptitudeStrength[math.clamp(math.floor(level), 0, #PetConfig.AptitudeStrength)] or 0
end

-- Weighted field seconds from aptitude `level` to level + 1.
function PetConfig.AptitudeXpToNext(level: number): number
	return math.floor(PetConfig.AptitudeXpFirst * PetConfig.AptitudeXpRatio ^ (level - 1) + 0.5)
end

-- Adds `seconds` of weighted field time to the pet's aptitude `id` (mutates it): levels up while the XP reaches the next step, up to
-- the rarity cap (at the cap XP stays 0). Returns the levels gained (0 without that aptitude).
function PetConfig.GainAptitudeXp(pet, id: string, seconds: number): number
	local entry = type(pet.Apt) == "table" and pet.Apt[id]
	if type(entry) ~= "table" then
		return 0
	end
	local cap = PetConfig.AptitudeCap(pet.Kind)
	local xp = entry.XP + math.max(0, seconds)
	local gained = 0
	while entry.L < cap and xp >= PetConfig.AptitudeXpToNext(entry.L) do
		xp -= PetConfig.AptitudeXpToNext(entry.L)
		entry.L += 1
		gained += 1
	end
	entry.XP = if entry.L >= cap then 0 else xp
	return gained
end

-- Cleans a stored Apt table in place for a pet of `kind` (unknown ids dropped, levels clamped to 1..cap, XP finite); true when it
-- holds at least one aptitude.
function PetConfig.CleanAptitudes(pet): boolean
	if type(pet.Apt) ~= "table" then
		return false
	end
	local cap = PetConfig.AptitudeCap(pet.Kind)
	local clean, any = {}, false
	for _, id in PetConfig.Aptitudes do
		local entry = pet.Apt[id]
		if type(entry) == "table" then
			local level = if type(entry.L) == "number" and entry.L == entry.L then math.clamp(math.floor(entry.L), 1, cap) else 1
			local xp = if type(entry.XP) == "number" and entry.XP == entry.XP and entry.XP < 1e12 then math.max(0, entry.XP) else 0
			clean[id] = { L = level, XP = if level >= cap then 0 else xp }
			any = true
		end
	end
	pet.Apt = clean
	if pet.Spec ~= nil and not (clean.PestControl and table.find(PetConfig.Specs, pet.Spec)) then
		pet.Spec = nil
	end
	return any
end

-- Reach shape of aptitude `level` (docs/EXPANSION.md §3): 0 = the pet's own square (levels 1-3), 1 = plus the 4 next to it (4-6),
-- 2 = the 3 x 3 block (7-10).
function PetConfig.ReachShape(level: number): number
	return if level >= 7 then 2 elseif level >= 4 then 1 else 0
end

return PetConfig
