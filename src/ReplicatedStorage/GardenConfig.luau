-- GardenConfig: the pet garden's shared numbers and pure helpers (docs/GDD.md §7.6). Shared: the server assigns plots,
-- prices and pays from this table only, the client renders it. Pure data + helpers, no side effects.
-- Names stored in the profile or used as attributes are fixed: never rename them.

local GardenConfig = {}

GardenConfig.PlotSize = 40 -- studs, square
GardenConfig.PlotAttribute = "GardenPlot" -- player attribute: slot of the borrowed plot (absent when none)
GardenConfig.ShownFreeSlots = 8 -- every slot (Max Players = 8, FX) is drawn as "Free plot" while nobody holds it

-- Plot positions (E1.0, docs/EXPANSION.md §16): a pure formula slot → floor CFrame, shared by server and client, so no
-- system needs a plot model to know where a plot is. Slots fill rings round the garden centre, ring by ring; each plot's
-- front (LookVector, the sign side) faces the centre. FX (2026-11-22, the user: 8 players, a field twice as deep): one ring of
-- 8 plots at radius 112 (slot 1 at 7.5° from +X, counted towards +Z), so the path from the bridge (75°) runs through the middle
-- of the gap between slots 2 and 3. (E1a1 had 12 plots on ring 1 and 18 on a ring 2 at radius 185.) A plot's field lies behind it
-- (away from the centre).
GardenConfig.PlotCentre = Vector3.new(-1222.517, 16.25, -834.035) -- garden centre at the height of the plot floors' centre
GardenConfig.PlotRings = {
	{ count = 8, radius = 112, offset = 7.5 },
}
GardenConfig.PlotSlots = 0 -- every slot the rings hold (8)
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

-- Floor CFrame of the plot `player` borrows (its PlotAttribute), or nil without one. Works for any player, on both sides.
function GardenConfig.PlotOf(player: Player): CFrame?
	local slot = player:GetAttribute(GardenConfig.PlotAttribute)
	return if type(slot) == "number" then GardenConfig.PlotCFrame(slot) else nil
end

-- The field's place in plot space (floor centre; +Z = from the plaza towards the field; PlotView draws it): the first row
-- starts FieldFront behind the floor centre, squares are FieldPitch studs, CropConfig.RowWidths rows of GridColumns columns.
local CropConfig = require(script.Parent:WaitForChild("CropConfig"))
GardenConfig.FieldFront = -2
GardenConfig.FieldPitch = 5.5
GardenConfig.FieldBack = GardenConfig.FieldFront + #CropConfig.RowWidths * GardenConfig.FieldPitch -- 58.5 since FX

-- FX: horizontal distance (studs) from `position` to the footprint of the plot with floor `floor`: the floor plus its field
-- (0 inside). Range checks measure from here, since the field reaches ~60 studs behind the floor centre.
function GardenConfig.FootprintDistance(floor: CFrame, position: Vector3): number
	local p = floor:PointToObjectSpace(position)
	local halfX = math.max(GardenConfig.PlotSize, CropConfig.GridColumns * GardenConfig.FieldPitch) / 2
	local dx = math.max(math.abs(p.X) - halfX, 0)
	local dz = math.max(-GardenConfig.PlotSize / 2 - p.Z, p.Z - GardenConfig.FieldBack, 0)
	return math.sqrt(dx * dx + dz * dz)
end

local PetConfig = require(script.Parent:WaitForChild("PetConfig"))

-- Square (1..MaxSquares) of the crop field where pet `uid` works (E1b: Garden.FieldPets[uid] = { Square, Job }), or nil.
function GardenConfig.FieldSquare(profile, uid: string): number?
	local garden = profile.Garden
	local entry = type(garden) == "table" and type(garden.FieldPets) == "table" and garden.FieldPets[uid]
	return if type(entry) == "table" and type(entry.Square) == "number" then entry.Square else nil
end

-- Incubators (P2b1 / EV2e, docs/GDD.md §7.6): eggs bought at an empty incubator roll their kind at purchase;
-- rarity sets real hatch time, also offline. Stored as Incubators["1".."3"] = { Id, Egg, Kind, StartedAt, ReadyAt } (server
-- os.time()) and Garden.IncubatorCount (owned incubators, unlocked in order).
GardenConfig.MaxIncubators = 3
GardenConfig.ScanSeconds = 30 -- visual phase within the existing hatch duration; never adds time
GardenConfig.IncubatorPrices = { 0, 500, 2800 } -- EV2a (was 5000 / 12000); IncubatorPrices[n] = price of the n-th incubator (incubator 1 is free)

-- True when the incubator entry's egg may hatch at server time `now`.
function GardenConfig.EggReady(entry, now: number): boolean
	return type(entry) == "table" and type(entry.ReadyAt) == "number" and now >= entry.ReadyAt
end

-- Shared display phase. Ready wins for instant / accelerated eggs; old plot payloads omit StartedAt and skip scanning.
function GardenConfig.EggPhase(startedAt: number?, readyAt: number, now: number): string
	if now >= readyAt then return "ready" end
	if startedAt and now < startedAt + GardenConfig.ScanSeconds then return "scanning" end
	return "growing"
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

-- FD "bigger pets eat more" (docs/GDD.md §7.6): a food's price for a pet is its `price` × FoodRarity[the pet's rarity] ×
-- FoodGrowth^(b − 1), b = the base level (PetConfig.BaseLevel) of the trait the food trains, nice-rounded; read at feeding.
GardenConfig.FoodGrowth = 2.65
GardenConfig.FoodRarity = { Common = 1, Uncommon = 1, Rare = 1, Epic = 1, Legendary = 10 }

-- Half to even (tools/economy_ev.py rounds with Python's round(): the prices must match it).
local function roundEven(x: number): number
	local whole = math.floor(x)
	local rest = x - whole
	return if rest > 0.5 or (rest == 0.5 and whole % 2 == 1) then whole + 1 else whole
end

-- "Nice" price (tools/economy_ev.py nice()): below 10 exact; then two digits, 10-30 every integer, 30-100 in steps of 5.
function GardenConfig.Nice(x: number): number
	if x < 10 then
		return math.max(1, roundEven(x))
	end
	local m = 10 ^ (math.floor(math.log10(x)) - 1)
	local a = x / m
	a = if a < 30 then roundEven(a) else 5 * roundEven(a / 5)
	return math.floor(a * m + 0.5)
end

-- FD: the price of `food` for `pet` (nil when food cannot train it any more: every trait at its food limit).
function GardenConfig.FoodPrice(food, pet): number?
	local id = PetConfig.CareTarget(pet, "food")
	if not id then
		return nil
	end
	local factor = GardenConfig.FoodRarity[PetConfig.Kinds[pet.Kind] or "Common"] or 1
	local b = PetConfig.BaseLevel(PetConfig.AptitudeLevel(pet, id))
	return GardenConfig.Nice(food.price * factor * GardenConfig.FoodGrowth ^ (b - 1))
end

-- FD: care XP one `crop` gives `pet` when fed: its level-1 XP scaled by the weakest food's (the Berry's) XP per Coin for that pet
-- against a level-1 Common, so feeding never beats selling the crop and buying food (E1a3 at every level and rarity). Whole XP;
-- 0 = refused (worth < 1 XP, or nothing left to train).
function GardenConfig.CropFeedXp(crop, pet): number
	local base, now = math.huge, math.huge
	for _, food in GardenConfig.Foods do
		local price = GardenConfig.FoodPrice(food, pet)
		if not price then
			return 0
		end
		base = math.min(base, food.xp / food.price)
		now = math.min(now, food.xp / price)
	end
	return math.floor(crop.xp * now / base + 1e-9)
end

-- Care XP food and fed crops can still give the pet before the rest is wasted (0: every trait at its food limit; FD).
function GardenConfig.XpToMax(pet): number
	return PetConfig.CareXpLeft(pet, "food")
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
