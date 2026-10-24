-- GardenConfig: the pet garden's shared numbers and pure helpers (docs/GDD.md §7.6). Shared: the server assigns plots,
-- prices and pays from this table only, the client renders it. Pure data + helpers, no side effects.
-- Names stored in the profile or used as attributes are fixed: never rename them.

local GardenConfig = {}

GardenConfig.PlotCount = 12 -- one plot per player slot (Max Players = 12)
GardenConfig.PlotSize = 40 -- studs, square
GardenConfig.PlotAttribute = "GardenPlot" -- player attribute: index of the borrowed plot (absent when none)
GardenConfig.OwnerIdAttribute = "OwnerUserId" -- plot model attribute: UserId of the current owner (absent when free)
GardenConfig.OwnerNameAttribute = "OwnerName" -- plot model attribute: name of the current owner (absent when free)

-- Name of the Workspace.Garden.Plots model of plot `index` ("Plot_01" … "Plot_12").
function GardenConfig.PlotName(index: number): string
	return string.format("Plot_%02d", index)
end

-- Pens and production (docs/GDD.md §7.6). Rates are Coins per hour at level 1; each level above 1 adds LevelRate permille.
-- All production maths is integer: a pet's "units" are rate × (1000 + LevelRate × (level − 1)), i.e. thousandths of a
-- Coin per hour, so production over `seconds` is units × seconds / UNITS_PER_COIN_SECOND whole Coins and the remainder
-- (the carry) is kept, which makes the total identical however the time is split into payouts.
GardenConfig.MaxPens = 6
GardenConfig.PenPrices = { 0, 1000, 2500, 5000, 9000, 15000 } -- PenPrices[n] = price of the n-th pen (pen 1 is free)
GardenConfig.BaseRates = { Common = 10, Uncommon = 20, Rare = 40, Epic = 70, Legendary = 120 } -- by rarity id
GardenConfig.LevelRate = 40 -- permille of the base rate per level above 1 (Lv 20 = ×1.76)
GardenConfig.OfflineCapSeconds = 8 * 3600 -- production counted at most this long since LastSeen
GardenConfig.PayoutSeconds = 300 -- online payout interval
GardenConfig.MinAwaySeconds = 60 -- shorter absences do not show the "welcome back" announcement
GardenConfig.PenNamePrefix = "Pen_" -- Workspace.Garden.Plots.Plot_NN.Pen_1..6 (Studio-only models)

local UNITS_PER_COIN_SECOND = 3600 * 1000

local PetConfig = require(script.Parent:WaitForChild("PetConfig"))

-- Units of one pet (0 for an unknown kind or rarity).
function GardenConfig.Units(pet): number
	local rarity = PetConfig.RarityOf(pet.Kind)
	local rate = rarity and GardenConfig.BaseRates[rarity.id] or 0
	return rate * (1000 + GardenConfig.LevelRate * (PetConfig.ClampLevel(pet.Level) - 1))
end

-- Coins per hour of one pet, for display (before the pet bonus).
function GardenConfig.RatePerHour(pet): number
	return GardenConfig.Units(pet) / 1000
end

-- Whole Coins produced by `units` over `seconds` on top of `carry`, and the new carry (units × seconds left over).
function GardenConfig.Settle(units: number, carry: number, seconds: number): (number, number)
	local total = carry + units * seconds
	local coins = total // UNITS_PER_COIN_SECOND
	return coins, total - coins * UNITS_PER_COIN_SECOND
end

-- Pen index (1..MaxPens) that holds pet `uid` in `profile.Garden`, or nil.
function GardenConfig.IsPenned(profile, uid: string): number?
	local garden = profile.Garden
	if type(garden) ~= "table" or type(garden.Pens) ~= "table" then
		return nil
	end
	for key, penned in garden.Pens do
		if penned == uid then
			return tonumber(key)
		end
	end
	return nil
end

-- Incubators (P2b1, docs/GDD.md §7.6): garden eggs (PetConfig.Eggs with hatchSeconds) bought at an empty incubator hatch
-- in real server time, also offline. Stored as profile.Garden.Incubators["1".."3"] = { Egg, StartedAt, ReadyAt } (server
-- os.time()) and Garden.IncubatorCount (owned incubators, unlocked in order).
GardenConfig.MaxIncubators = 3
GardenConfig.IncubatorPrices = { 0, 5000, 12000 } -- IncubatorPrices[n] = price of the n-th incubator (incubator 1 is free)
GardenConfig.IncubatorNamePrefix = "Incubator_" -- Workspace.Garden.Plots.Plot_NN.Incubator_1..3 (Studio-only models)

-- True when the incubator entry's egg may hatch at server time `now`.
function GardenConfig.EggReady(entry, now: number): boolean
	return type(entry) == "table" and type(entry.ReadyAt) == "number" and now >= entry.ReadyAt
end

-- Number of eggs incubating in `garden` (they count towards the inventory cap when a new egg is started).
function GardenConfig.IncubatingCount(garden): number
	local count = 0
	if type(garden) == "table" and type(garden.Incubators) == "table" then
		for _ in garden.Incubators do
			count += 1
		end
	end
	return count
end

-- Feeding (P2b2, docs/GDD.md §7.6): food is bought at the plaza's food stand and fed at once to one pet (no food inventory).
GardenConfig.Foods = {
	{ id = "Berry", name = "Berry", icon = "🍓", price = 50, xp = 25 },
	{ id = "Cake", name = "Cake", icon = "🍰", price = 400, xp = 250 },
	{ id = "Feast", name = "Feast", icon = "🍖", price = 1500, xp = 1000 },
}
GardenConfig.FoodById = {}
for _, food in GardenConfig.Foods do
	GardenConfig.FoodById[food.id] = food
end
GardenConfig.FoodStandName = "FoodStand" -- Workspace.Garden.FoodStand (Studio-only model, PrimaryPart "Counter")
GardenConfig.FoodStandDistance = 20 -- studs from the stand's PrimaryPart within which Feed is accepted

-- XP a pet still needs to reach the max level (0 at the max level).
function GardenConfig.XpToMax(pet): number
	local level = PetConfig.ClampLevel(pet.Level)
	local xp = if type(pet.XP) == "number" and pet.XP == pet.XP then math.max(0, math.floor(pet.XP)) else 0
	local need = 0
	for current = level, PetConfig.MaxLevel - 1 do
		need += PetConfig.XpToNext(current)
	end
	return math.max(0, need - xp)
end

export type Assigner = {
	Claim: (key: any) -> number?,
	Release: (key: any) -> number?,
	IndexOf: (key: any) -> number?,
	KeyOf: (index: number) -> any?,
}

-- Plot assigner: hands out the lowest free index in 1..count to a key (a Player on the server). Claiming again for the
-- same key returns the same index; a full garden returns nil; a released index is free for the next claim.
function GardenConfig.NewAssigner(count: number): Assigner
	local byKey = {}
	local byIndex = {}
	local assigner = {}

	function assigner.Claim(key)
		if byKey[key] then
			return byKey[key]
		end
		for index = 1, count do
			if byIndex[index] == nil then
				byKey[key] = index
				byIndex[index] = key
				return index
			end
		end
		return nil
	end

	-- Returns the index that was freed, or nil if the key held none.
	function assigner.Release(key)
		local index = byKey[key]
		if index then
			byKey[key] = nil
			byIndex[index] = nil
		end
		return index
	end

	function assigner.IndexOf(key)
		return byKey[key]
	end

	function assigner.KeyOf(index)
		return byIndex[index]
	end

	return assigner
end

return GardenConfig
