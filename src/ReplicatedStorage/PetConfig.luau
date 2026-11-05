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
-- P4: a pet has no level of its own any more. Its level (PetLevel) is the highest level of its working traits (aptitudes in Shown),
-- 1..MaxLevel; it drives the label, size, look tiers and pen output. The stored Pets[uid].Level / XP (1..LegacyMaxLevel, before P4) are
-- frozen and read only by the profile migration (MigrateLegacyPet).
PetConfig.MaxLevel = 10
PetConfig.LegacyMaxLevel = 20
PetConfig.CuteStep = 19 -- Cuteness: permille per level above 1, on top of the rarity's base bonus (P4)
PetConfig.MaxBonus = 500 -- cap on the summed bonus of equipped pets (+50 %)
PetConfig.AttributeName = "EquippedPets" -- player attribute "Kind:Level:uid,…" of the equipped pets (P1c, uid since P1e1; level = PetLevel)
PetConfig.MaxScale = 1.6 -- model size at MaxLevel relative to Lv 1 (PetLook.Scale, P1e1)
PetConfig.Tiers = { 3, 5, 8, 10 } -- first level of look tiers 1..4 (PetLook.Tier); P4: the 5 / 10 / 15 / 20 of the 20-level look, scaled

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

-- Coin bonus of one pet in permille (P4: only a pet with Cuteness has one): rarity base + CuteStep per Cuteness level above 1; 0 for
-- a pet without Cuteness or of an unknown kind.
function PetConfig.PetBonus(pet): number
	local rarity = PetConfig.RarityOf(pet.Kind)
	local level = PetConfig.AptitudeLevel(pet, "Cuteness")
	if not rarity or level < 1 then
		return 0
	end
	return rarity.bonus + PetConfig.CuteStep * (level - 1)
end

-- Coin multiplier of a list of equipped pets: 1 + min(+50 %, sum of their bonuses).
function PetConfig.Multiplier(pets: { any }): number
	local sum = 0
	for _, pet in pets do
		sum += PetConfig.PetBonus(pet)
	end
	return 1 + math.min(PetConfig.MaxBonus, sum) / 1000
end

-- Cuteness XP needed to go from `level` to level + 1: round(CuteXpFactor × L^1.5); nil at the max level (the rarity cap may stop it
-- earlier: AptitudeCap).
PetConfig.CuteXpFactor = 100
function PetConfig.CuteXpToNext(level: number): number?
	if level >= PetConfig.MaxLevel then
		return nil
	end
	return math.floor(PetConfig.CuteXpFactor * level ^ 1.5 + 0.5)
end

-- Care XP sources (GDD §7.4): every equipped pet receives the full amount of each event, trained by GainCareXp
PetConfig.MedalXp = { 5, 10, 20 } -- MedalXp[medal] for the run's medal (Bronze / Silver / Gold); no medal: FinishXp
PetConfig.FinishXp = 2 -- a finish without a medal
PetConfig.CoinXp = 1 -- per collected coin
PetConfig.StudsPerXp = 20 -- movement while a stage timer runs (horizontal studs, measured on the server)
PetConfig.MaxMoveXp = 30 -- per run

-- Movement XP of a run that covered `studs` horizontal studs.
function PetConfig.MoveXp(studs: number): number
	return math.min(PetConfig.MaxMoveXp, math.floor(studs / PetConfig.StudsPerXp))
end

-- Sell value of a pet of `kind` (0 for an unknown kind).
function PetConfig.SellValue(kind: string): number
	local rarity = PetConfig.RarityOf(kind)
	return rarity and rarity.sellValue or 0
end

-- Aptitudes (E1b, docs/EXPANSION.md §4, numbers from docs/ECONOMY.md → "Field-pet re-run"): the jobs a pet is born with, each with
-- its own level 1..cap raised by doing the job. Stored as Pets[uid].Apt = { [id] = { L, XP } } (XP = weighted field seconds
-- towards the next level) and Pets[uid].Spec (Pest-control speciality). Ids are stored: never rename one. Rolled once (at hatch,
-- or on load for pets from before E1b) and never rerolled. Only the ids in Shown do something yet (E1b: Tending, E2c: Scouting,
-- E4-thin: Pest control, P4: Cuteness, the Coin bonus; P4 calls them "traits" in the UI). The list order is the display order.
PetConfig.Aptitudes = { "Cuteness", "Tending", "Fertilising", "PestControl", "Weeding", "Scouting", "Crafting" }
PetConfig.Shown = { Cuteness = true, Tending = true, Scouting = true, PestControl = true }
-- P4: hatches roll only working traits; Fertilising / Weeding / Crafting join when they are built (pets that have them keep them)
PetConfig.HatchPool = { "Cuteness", "Tending", "PestControl", "Scouting" }
-- P4: chance of Cuteness by rarity when a trait slot is left after Tending (so the field model's Tending rates hold)
PetConfig.CuteChance = { Common = 0.35, Uncommon = 0.4, Rare = 0.5, Epic = 0.6, Legendary = 0.7 }
-- P4 care XP (obby XP, food, crops): goes to Cuteness while it is below its cap, otherwise to the lowest working trait below
-- CareLevelCap, as CareSecondsPerXp weighted field seconds per XP (so Coins cannot buy the top work levels)
PetConfig.CareLevelCap = 5
PetConfig.CareSecondsPerXp = 36
-- Scouting (E2c, a with-you aptitude): every medal finish on a world stage gives each equipped pet with Scouting XpPerFinish seconds of
-- aptitude XP (same curve as Tending); the equipped scouts together add min(Cap, sum of PerStrength x Strength) to the stage's rare-seed
-- meter points, and at PouchExtraAt or more the seed pouch drops 1 seed more
PetConfig.Scouting = { XpPerFinish = 15 * 60, PerStrength = 0.5, Cap = 0.5, PouchExtraAt = 0.5 }
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
-- speciality (or nil). `withTending` makes Tending one of them (decision 3: a hatch while an owner with field access has no Tending pet).
-- P4: from HatchPool only; Tending first (forced or by TendingChance), then Cuteness by CuteChance while a slot is left, the rest from
-- the other pool traits with the kind's lean; slots the pool cannot fill take Cuteness, then Tending.
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
	local cuteRoll = rng:NextNumber()
	if total > 0 and cuteRoll < PetConfig.CuteChance[rarityId] then
		apt.Cuteness = { L = start, XP = 0 }
		total -= 1
	end
	local pool = {}
	for _, id in PetConfig.HatchPool do
		if id ~= "Tending" and id ~= "Cuteness" then
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
	for _, id in { "Cuteness", "Tending" } do
		if total > 0 and not apt[id] then
			apt[id] = { L = start, XP = 0 }
			total -= 1
		end
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

-- Pest control (E4-thin): a guard on the field chases the critters off the squares in its reach with Base + PerStrength x Strength(level),
-- x SpecMult against the critter of its speciality (Spec), at most 1. Crows are the only critter yet ("Crows").
PetConfig.Guard = { Base = 0.5, PerStrength = 0.5, SpecMult = 2 }

-- Chance that a guard with Pest-control `level` and speciality `spec` chases `critter` off (0 without the aptitude).
function PetConfig.GuardChance(level: number, spec: string?, critter: string): number
	if level < 1 then
		return 0
	end
	local rules = PetConfig.Guard
	local chance = rules.Base + rules.PerStrength * PetConfig.Strength(level)
	if spec == critter then
		chance *= rules.SpecMult
	end
	return math.min(1, chance)
end

-- Scouting bonus of the pets in `pets` (the equipped ones): min(Cap, sum of PerStrength x Strength(Scouting level)), 0 without scouts.
function PetConfig.ScoutBonus(pets: { any }): number
	local rules = PetConfig.Scouting
	local sum = 0
	for _, pet in pets do
		sum += rules.PerStrength * PetConfig.Strength(PetConfig.AptitudeLevel(pet, "Scouting"))
	end
	return math.min(rules.Cap, sum)
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

-- P4: the pet's level, the highest level of its working traits (Shown), 1..MaxLevel (1 without one).
function PetConfig.PetLevel(pet): number
	local best = 1
	for id in PetConfig.Shown do
		best = math.max(best, PetConfig.AptitudeLevel(pet, id))
	end
	return math.clamp(math.floor(best), 1, PetConfig.MaxLevel)
end

-- Level up to which care XP raises trait `id` of a pet of `kind`: the rarity cap for Cuteness, CareLevelCap (at most the cap) otherwise.
function PetConfig.CareLimit(kind: string, id: string): number
	local cap = PetConfig.AptitudeCap(kind)
	return if id == "Cuteness" then cap else math.min(cap, PetConfig.CareLevelCap)
end

-- The trait care XP trains now: Cuteness while below its cap, otherwise the lowest working trait below its care limit (ties in list
-- order); nil when nothing can train.
function PetConfig.CareTarget(pet): string?
	local cute = PetConfig.AptitudeLevel(pet, "Cuteness")
	if cute >= 1 and cute < PetConfig.CareLimit(pet.Kind, "Cuteness") then
		return "Cuteness"
	end
	local best, bestLevel = nil, math.huge
	for _, id in PetConfig.Aptitudes do
		if PetConfig.Shown[id] and id ~= "Cuteness" then
			local level = PetConfig.AptitudeLevel(pet, id)
			if level >= 1 and level < PetConfig.CareLimit(pet.Kind, id) and level < bestLevel then
				best, bestLevel = id, level
			end
		end
	end
	return best
end

-- Care XP trait `id` still takes to reach its care limit (Cuteness XP points; a work trait's field seconds / CareSecondsPerXp, rounded up).
function PetConfig.CareNeed(pet, id: string): number
	local level = PetConfig.AptitudeLevel(pet, id)
	if level < 1 then
		return 0
	end
	local entry = pet.Apt[id]
	local limit = PetConfig.CareLimit(pet.Kind, id)
	local need = 0
	for current = level, limit - 1 do
		need += if id == "Cuteness" then PetConfig.CuteXpToNext(current) or 0 else PetConfig.AptitudeXpToNext(current)
	end
	need = math.max(0, need - entry.XP)
	return if id == "Cuteness" then need else math.ceil(need / PetConfig.CareSecondsPerXp)
end

-- The trait care XP trains now and its progress in care XP (Cuteness XP points; a work trait's field seconds / CareSecondsPerXp):
-- id, xp, next; nil, 0, 0 when nothing can train (the UI's XP bars and the food stand).
function PetConfig.CareProgress(pet): (string?, number, number)
	local id = PetConfig.CareTarget(pet)
	if not id then
		return nil, 0, 0
	end
	local entry = pet.Apt[id]
	if id == "Cuteness" then
		return id, math.floor(entry.XP), PetConfig.CuteXpToNext(entry.L) or 0
	end
	local rate = PetConfig.CareSecondsPerXp
	return id, math.floor(entry.XP / rate), math.ceil(PetConfig.AptitudeXpToNext(entry.L) / rate)
end

-- Copy of `pet` with its own Apt table (to preview GainCareXp without changing the state).
function PetConfig.CopyForCare(pet)
	local copy = table.clone(pet)
	copy.Apt = {}
	if type(pet.Apt) == "table" then
		for id, entry in pet.Apt do
			copy.Apt[id] = table.clone(entry)
		end
	end
	return copy
end

-- Care XP the pet can still take in total (what GainCareXp would use before wasting the rest).
function PetConfig.CareXpLeft(pet): number
	local total = 0
	for id in PetConfig.Shown do
		total += PetConfig.CareNeed(pet, id)
	end
	return total
end

-- Adds `amount` care XP (obby XP, food, crops) to the pet (mutates its Apt): CareTarget gets it up to its care limit, the rest goes on
-- to the next target. Returns the traits trained in order { { id, levels, level } } (empty when nothing could train) and the XP wasted.
function PetConfig.GainCareXp(pet, amount: number): ({ { id: string, levels: number, level: number } }, number)
	local trained = {}
	local left = math.max(0, math.floor(amount))
	while left > 0 do
		local id = PetConfig.CareTarget(pet)
		if not id then
			break
		end
		local entry = pet.Apt[id]
		local before = entry.L
		local need = PetConfig.CareNeed(pet, id)
		if left >= need then
			entry.L, entry.XP = PetConfig.CareLimit(pet.Kind, id), 0
			left -= need
		else
			if id == "Cuteness" then
				entry.XP += left
				while entry.XP >= (PetConfig.CuteXpToNext(entry.L) or math.huge) do
					entry.XP -= PetConfig.CuteXpToNext(entry.L) :: number
					entry.L += 1
				end
			else
				entry.XP += left * PetConfig.CareSecondsPerXp
				while entry.XP >= PetConfig.AptitudeXpToNext(entry.L) do
					entry.XP -= PetConfig.AptitudeXpToNext(entry.L)
					entry.L += 1
				end
			end
			left = 0
		end
		table.insert(trained, { id = id, levels = entry.L - before, level = entry.L })
	end
	return trained, left
end

-- P4 profile migration (PlayerProfile Version 4): a pet from before P4 gets Cuteness once, at its old level (1..LegacyMaxLevel) scaled
-- to 1..MaxLevel and rounded up (so its Coin bonus never drops), clamped to its cap, on top of its traits. A pet from before E1b (no
-- aptitudes) first gets them rolled (starting at ceil(old level / LiveLevelStep)). Level / XP stay as stored. False for a bad record.
function PetConfig.MigrateLegacyPet(pet, seed: string): boolean
	if type(pet) ~= "table" or not PetConfig.Kinds[pet.Kind] then
		return false
	end
	local old = if type(pet.Level) == "number" and pet.Level == pet.Level
		then math.clamp(math.floor(pet.Level), 1, PetConfig.LegacyMaxLevel)
		else 1
	if not PetConfig.CleanAptitudes(pet) then
		pet.Apt, pet.Spec = PetConfig.RollAptitudes(seed, pet.Kind, false, math.ceil(old / PetConfig.LiveLevelStep))
	end
	local cap = PetConfig.AptitudeCap(pet.Kind)
	local level = math.min(cap, 1 + math.ceil((old - 1) * (PetConfig.MaxLevel - 1) / (PetConfig.LegacyMaxLevel - 1)))
	local entry = pet.Apt.Cuteness
	if entry and entry.L >= level then
		return true
	end
	pet.Apt.Cuteness = { L = level, XP = 0 }
	return true
end

-- Pet names (P3b, docs/ROADMAP.md → P3): stored raw as Pets[uid].Name, filtered by the server (TextService, broadcast) on every join and
-- rename; clients only ever get the filtered text (PetsChanged pets[uid].Name, the NamesAttribute of the owner). The first name is free,
-- every later one costs RenamePrice (Pets[uid].Renamed = true after the first); clearing a name is free.
PetConfig.RenamePrice = 250
PetConfig.NameMaxLength = 20 -- characters (UTF-8 code points)
PetConfig.RenameCooldown = 10 -- seconds between renames per player
PetConfig.NamesAttribute = "PetNames" -- player attribute: JSON { [uid] = filtered name } of the pets others can see

-- allowed characters: ASCII letters and digits, the space, and the Latin-1 / Latin Extended-A and -B letters (Czech and other Latin
-- scripts; × and ÷ excluded)
local function nameCharacter(code: number): boolean
	return (code >= 48 and code <= 57)
		or (code >= 65 and code <= 90)
		or (code >= 97 and code <= 122)
		or code == 32
		or (code >= 0xC0 and code <= 0x24F and code ~= 0xD7 and code ~= 0xF7)
end

-- The name a player typed, cleaned: spaces trimmed and collapsed. "" = no name; nil when the text is not allowed (bad characters,
-- invalid UTF-8, longer than NameMaxLength).
function PetConfig.CleanName(text: any): string?
	if type(text) ~= "string" or #text > PetConfig.NameMaxLength * 4 then
		return nil
	end
	if not utf8.len(text) then
		return nil
	end
	for _, code in utf8.codes(text) do
		if not nameCharacter(code) then
			return nil
		end
	end
	local clean = string.gsub(string.gsub(text, "^ +", ""), " +$", "")
	clean = string.gsub(clean, "  +", " ")
	if (utf8.len(clean) :: number) > PetConfig.NameMaxLength then
		return nil
	end
	return clean
end

-- The NamesAttribute value → { [uid] = name } (empty for a missing or malformed value).
function PetConfig.DecodeNames(value: any): { [string]: string }
	local names = {}
	if type(value) ~= "string" or value == "" then
		return names
	end
	local ok, decoded = pcall(function()
		return game:GetService("HttpService"):JSONDecode(value)
	end)
	if ok and type(decoded) == "table" then
		for uid, name in decoded do
			if type(uid) == "string" and type(name) == "string" and name ~= "" then
				names[uid] = name
			end
		end
	end
	return names
end

-- Reach shape of aptitude `level` (docs/EXPANSION.md §3): 0 = the pet's own square (levels 1-3), 1 = plus the 4 next to it (4-6),
-- 2 = the 3 x 3 block (7-10).
function PetConfig.ReachShape(level: number): number
	return if level >= 7 then 2 elseif level >= 4 then 1 else 0
end

return PetConfig
