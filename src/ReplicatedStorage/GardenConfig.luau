-- GardenConfig: the pet garden's shared numbers and pure helpers (docs/GDD.md §7.6). Shared: the server assigns plots,
-- prices and pays from this table only, the client renders it. Pure data + helpers, no side effects.
-- Names stored in the profile or used as attributes are fixed: never rename them.

local GardenConfig = {}

GardenConfig.PlotSize = 40 -- studs, square
GardenConfig.PlotAttribute = "GardenPlot" -- player attribute: slot of the borrowed plot (absent when none)
GardenConfig.ShownFreeSlots = 12 -- slots 1..12 (ring 1, Max Players = 12) are drawn as "Free plot" while nobody holds them

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

local PetConfig = require(script.Parent:WaitForChild("PetConfig"))

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
GardenConfig.SeedStallName = "SeedStall" -- Workspace.Garden.SeedStall (U4: Studio-only model beside the food stand, PrimaryPart "Counter")
GardenConfig.SeedStallDistance = 20 -- studs from the stall's PrimaryPart within which BuySeeds / BuyCart are accepted

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
