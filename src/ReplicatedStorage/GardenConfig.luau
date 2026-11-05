-- GardenConfig: the pet garden's shared numbers and pure helpers (docs/GDD.md §7.6). Shared: the server assigns plots,
-- prices and pays from this table only, the client renders it. Pure data + helpers, no side effects.
-- Names stored in the profile or used as attributes are fixed: never rename them.

local GardenConfig = {}

GardenConfig.PlotSize = 40 -- studs, square
GardenConfig.PlotAttribute = "GardenPlot" -- player attribute: slot of the borrowed plot (absent when none)
GardenConfig.ShownFreeSlots = 12 -- slots 1..12 (ring 1, Max Players = 12) are drawn as "Free plot" while nobody holds them

-- Crop field access (E1a2, docs/ROADMAP.md): "admins" = admins (AdminConfig) and Studio test users (UserIds < 0) only, "all"
-- once E1 ships. A code constant, switched in git and live by publishing. Without access no Field data is written to the
-- profile, every field remote is rejected and the plot messages carry no field.
GardenConfig.FieldAccess = "admins"

local AdminConfig = require(script.Parent:WaitForChild("AdminConfig"))

function GardenConfig.HasFieldAccess(userId: number): boolean
	if GardenConfig.FieldAccess == "all" then
		return true
	end
	return AdminConfig.IsAdmin(userId) or (game:GetService("RunService"):IsStudio() and userId < 0)
end

-- Plot positions (E1.0, docs/EXPANSION.md §16): a pure formula slot → floor CFrame, shared by server and client, so no
-- system needs a plot model to know where a plot is. Slots fill rings round the garden centre, ring by ring; each plot's
-- front (LookVector, the sign side) faces the centre. Ring 1 has 12 plots at radius 112 (slot 1 on +X, counted towards
-- +Z; 9 studs between neighbours), ring 2 18 plots at radius 185, turned by 5° so the path from the bridge (75°) runs
-- between plots on both rings (E1a1, docs/ROADMAP.md). A plot's field lies behind it (away from the centre).
GardenConfig.PlotCentre = Vector3.new(-1222.517, 16.25, -834.035) -- garden centre at the height of the plot floors' centre
GardenConfig.PlotRings = {
	{ count = 12, radius = 112 },
	{ count = 18, radius = 185, offset = 5 },
}
GardenConfig.PlotSlots = 0 -- every slot the rings hold (30)
for _, ring in GardenConfig.PlotRings do
	GardenConfig.PlotSlots += ring.count
end

export type PlotRing = { count: number, radius: number, offset: number? } -- offset in degrees

-- Ring (1 = inner) and position on it (1..count) of plot slot `slot`, or nil outside the rings. `rings` defaults to
-- PlotRings (tests pass another layout).
function GardenConfig.PlotRing(slot: number, rings: { PlotRing }?): (number?, number?)
	if type(slot) ~= "number" or slot % 1 ~= 0 or slot < 1 then
		return nil, nil
	end
	local first = 1
	for ringIndex, ring in rings or GardenConfig.PlotRings do
		if slot < first + ring.count then
			return ringIndex, slot - first + 1
		end
		first += ring.count
	end
	return nil, nil
end

-- Floor CFrame of plot slot `slot` (centre of the 40 x 40 floor, front towards the garden centre), or nil.
function GardenConfig.PlotCFrame(slot: number, rings: { PlotRing }?): CFrame?
	rings = rings or GardenConfig.PlotRings
	local ringIndex, position = GardenConfig.PlotRing(slot, rings)
	if not ringIndex then
		return nil
	end
	local ring = (rings :: { PlotRing })[ringIndex]
	local angle = math.rad(ring.offset or 0) + (position - 1) * 2 * math.pi / ring.count
	local centre = GardenConfig.PlotCentre
	local at = centre + Vector3.new(math.cos(angle), 0, math.sin(angle)) * ring.radius
	return CFrame.lookAt(at, Vector3.new(centre.X, at.Y, centre.Z))
end

-- Pens and production (docs/GDD.md §7.6). Rates are Coins per hour at level 1 (the pet level, PetConfig.PetLevel); the max level
-- adds MaxLevelRate permille, linear in between. All production maths is integer: a pet's "units" are
-- rate × (1000 + MaxLevelRate × (level − 1) // (MaxLevel − 1)), i.e. thousandths of a
-- Coin per hour, so production over `seconds` is units × seconds / UNITS_PER_COIN_SECOND whole Coins and the remainder
-- (the carry) is kept, which makes the total identical however the time is split into payouts.
GardenConfig.MaxPens = 6
GardenConfig.PenPrices = { 0, 1000, 2500, 5000, 9000, 15000 } -- PenPrices[n] = price of the n-th pen (pen 1 is free)
GardenConfig.BaseRates = { Common = 10, Uncommon = 20, Rare = 40, Epic = 70, Legendary = 120 } -- by rarity id
GardenConfig.MaxLevelRate = 760 -- permille of the base rate added at the max level (Lv 10 = ×1.76, as Lv 20 before P4)
GardenConfig.OfflineCapSeconds = 8 * 3600 -- production counted at most this long since LastSeen
GardenConfig.PayoutSeconds = 300 -- online payout interval
GardenConfig.MinAwaySeconds = 60 -- shorter absences do not show the "welcome back" announcement

local UNITS_PER_COIN_SECOND = 3600 * 1000

local PetConfig = require(script.Parent:WaitForChild("PetConfig"))

-- Units of one pet (0 for an unknown kind or rarity).
function GardenConfig.Units(pet): number
	local rarity = PetConfig.RarityOf(pet.Kind)
	local rate = rarity and GardenConfig.BaseRates[rarity.id] or 0
	return rate * (1000 + GardenConfig.MaxLevelRate * (PetConfig.PetLevel(pet) - 1) // (PetConfig.MaxLevel - 1))
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

-- Square (1..12) of the crop field where pet `uid` works (E1b: Garden.FieldPets[uid] = { Square, Job }), or nil.
function GardenConfig.FieldSquare(profile, uid: string): number?
	local garden = profile.Garden
	local entry = type(garden) == "table" and type(garden.FieldPets) == "table" and garden.FieldPets[uid]
	return if type(entry) == "table" and type(entry.Square) == "number" then entry.Square else nil
end

-- Incubators (P2b1, docs/GDD.md §7.6): garden eggs (PetConfig.Eggs with hatchSeconds) bought at an empty incubator hatch
-- in real server time, also offline. Stored as profile.Garden.Incubators["1".."3"] = { Egg, StartedAt, ReadyAt } (server
-- os.time()) and Garden.IncubatorCount (owned incubators, unlocked in order).
GardenConfig.MaxIncubators = 3
GardenConfig.IncubatorPrices = { 0, 5000, 12000 } -- IncubatorPrices[n] = price of the n-th incubator (incubator 1 is free)

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

-- Care XP (food, crops) a pet can still use before the rest is wasted (0: nothing left to train; PetConfig.CareXpLeft, P4).
function GardenConfig.XpToMax(pet): number
	return PetConfig.CareXpLeft(pet)
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
