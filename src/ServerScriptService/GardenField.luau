-- GardenField: the crop field behind the player's plot (E1a2, docs/ROADMAP.md → E1a2, docs/EXPANSION.md §5). Server-only.
-- Every player has a field (FA, 2026-11-06: the field access gate and the P2 pens are gone).
-- State lives in PlayerProfile.Garden: Field = { Open = { ["n"] = true }, Squares["n"] = { Crop, Grown }, SettledAt }, Seeds[crop],
-- Items[crop], Renown (points; the level is derived, CropConfig.RenownLevel). Grown = growth seconds earned, SettledAt = the
-- server os.time() up to which growth was counted. Growth is settled on join (the time since SettledAt is an absence:
-- CropConfig.OfflineRate, capped), and while online (OnlineRate) every SettleSeconds, before every field action and on leave.
-- Ripe crops wait. The client only names a square, a crop or a count: prices, times and Renown come from here.
-- Field pets (E1b): Garden.FieldPets[uid] = { Square, Job } (Job = "Tending", or "PestControl" for a pet without Tending: the stored
-- primary job), Garden.FieldPetSlots. E4-thin: a pet does every field job it has (Tending and Pest control), each with the reach of its
-- own level, and gains XP in both. A Tending pet works the squares
-- in its reach (PetConfig.ReachShape, CropConfig.Reach; the strongest pet counts): during an absence (the join settle) a ripe crop
-- that was not tried yet is harvested by the pet with the chance PetConfig.Strength(level) (Items, Renown; only while the barn
-- has room) and replanted from Seeds with the leftover growth; a failed roll marks the planting Tried (it waits for the owner).
-- The roll is deterministic per owner and planting number (Squares[n].N from Field.Plantings), so a re-join never rerolls.
-- Placed pets earn aptitude XP in their job by the weighted field time (the same seconds as growth).
-- Crows (E4-thin, CropConfig.Crows): after Tending in the join settle, every common crop that was ripe during the absence while a crow
-- block overlapped it is rolled once per planting (Squares[n].Crow); one that loses the roll is eaten (the square is emptied) unless a
-- guard reaching the square wins its own roll (PetConfig.GuardChance; the strongest guard counts). At most Cap eaten per absence, only
-- from Renown level FromLevel; rare crops are never eaten. State.field.notice.crows = { ate = { [crop] = n }, chased = { [uid] = n } },
-- State.field.crows = { from, to, active } is the forecast (the next crow block within a day, server times).
-- A profile from before the field converts once on join (Garden.Converted; E1b, kept by FA as the migration): the pets it had in
-- the P2 pens back to the inventory, CropConfig.PetSlotsFromPens slots, the rest of the pen prices (LegacyPenPrices) refunded; the
-- legacy pen fields (Pens, PenCount, Carry, LastSeen) are cleared on every join.
-- Size roll (E1c2): every harvest (the owner's or a Tending pet's) rolls CropConfig.SizeFactor from the planting number; the
-- barn keeps per crop the count (Items) and the summed factors (ItemSize; crops from before E1c2 count as 1 each), BestSize[crop]
-- = the best factor harvested. A sale of k of n pays CropConfig.SaleValue for k × ItemSize / n.
-- Field upgrades (E1c1): Field.Upgrades = { Growth, Barn } levels (CropConfig.Upgrades): Growth multiplies the growth crops
-- earn (CropConfig.GrowthSpeed; pets' aptitude XP keeps the plain seconds), Barn raises the seed stock and the crops a Tending
-- pet may store (CropConfig.BarnFor).
-- Garden tools (E1c3): Garden.Tools = { Sorter, Cloches, Shears } levels (CropConfig.Tools), each level gated by a Renown level.
-- Sorter multiplies every harvest's size factor; Cloches multiply the growth earned while the owner is online (not the absence,
-- not the pets' aptitude XP); Shears give a second crop of the same size with their chance, rolled per planting number like
-- Tending (no Renown or seed for it; a Tending pet's second crop needs room in the barn).
-- Market cart (E1c4): CropConfig.CartOffers(today's UTC day, Renown level) are today's offers; Garden.Cart = { Day, Bought = { [key] = n } }
-- counts what the player bought of each (key = crop id, + "*" for the taste), reset when the day changes. BuyCart(slot, crop, count) sells
-- at the offer's price; the seeds join Seeds (within the barn). Plant needs only the seeds: a taste crop can be planted before its Renown
-- gate (BuySeeds keeps the gate).
-- Crops as pet food (E1a3): FeedCrop(uid, crop, count) feeds held crops to any owned pet for CropConfig xp each (half the sale), anywhere
-- (no plot distance: the Pets panel's detail page); at most as many as the pet needs for the max level (the last one may go past it),
-- the average size leaves the barn as in a sale. Renown stays (it is earned at harvest).
-- Rare seeds from the obby (E2a): StageResults calls GardenField.ObbyFinish for every finish; CropConfig.ObbySeeds gives the rare crop of
-- the stage's world for a new Gold (World 2 on), the day's first medal finish (Garden.RareDay = that UTC day) and a full stage meter
-- (Garden.Meters[stageKey] = points). Rare crops are never sold as seeds (BuySeeds: "obby").
-- E2b seed pouch: the day's first medal finish on a stage also gives CropConfig.ObbySeeds.Pouch[medal] seeds of the common crop planted
-- last (Garden.LastCrop, set by Plant), only up to the barn's limit.
-- E2c Scouting: the equipped scouts' bonus (PetConfig.ScoutBonus) multiplies the meter points and adds a pouch seed at PouchExtraAt; each
-- medal finish gives every equipped pet with Scouting PetConfig.Scouting.XpPerFinish of aptitude XP (after the bonus is taken).
-- The field's shape is CropConfig.RowWidths (E1d2: 36 squares on a grid); the player opens any locked square (BuySquare), the price
-- and Renown gate come from the number already open (CropConfig.NextExpansion). Fields from before E1d2 (Count = the first squares
-- of a 4 x 3 field) move onto rows 1-3 (CropConfig.FromOldSquare), with their crops and field pets.
-- Remotes (in GardenRemotes): Plant(square, crop), Harvest(square), BuySeeds(crop, count), Sell(crop, count),
-- BuySquare(square, expectedOpen), PlacePet(square, uid) (also moves a placed pet), LiftPet(uid), BuyPetSlot(expectedSlots),
-- BuyUpgrade(id, expectedLevel), BuyTool(id, expectedLevel), BuyCart(slot, crop, count), FeedCrop(uid, crop, count) (client → server); answers on GardenRemotes.Result; GardenRemotes.State.field (the owner's panel).
-- Where they are accepted: at the own plot (GardenService.Usable, 45 studs) for the field actions and Sell (the barn is on the plot);
-- within GardenConfig.SeedStallDistance of the plaza's seed stall for BuySeeds and BuyCart (U4); anywhere for BuyUpgrade, BuyTool,
-- BuyPetSlot (U4: pure Coin + Renown buys from the Skills / Pets panels) and FeedCrop.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GardenConfig = require(ReplicatedStorage.GardenConfig)
local CropConfig = require(ReplicatedStorage.CropConfig)
local PetConfig = require(ReplicatedStorage.PetConfig)
local PlayerProfile = require(ServerScriptService.PlayerProfile)
local CoinRewards = require(ServerScriptService.CoinRewards)
local GardenService = require(ServerScriptService.GardenService)
local StageConfig = require(ReplicatedStorage.StageConfig)
local PetService = require(ServerScriptService.PetService)

local plantEvent = GardenService.Remote("Plant") -- client → server: (square: number, crop: string)
local harvestEvent = GardenService.Remote("Harvest") -- client → server: (square: number)
local buySeedsEvent = GardenService.Remote("BuySeeds") -- client → server: (crop: string, count: number)
local sellEvent = GardenService.Remote("Sell") -- client → server: (crop: string, count: number)
local buySquareEvent = GardenService.Remote("BuySquare") -- client → server: (square: number, expectedOpen: number)
local placePetEvent = GardenService.Remote("PlacePet") -- client → server: (square: number, uid: string)
local liftPetEvent = GardenService.Remote("LiftPet") -- client → server: (uid: string)
local buyPetSlotEvent = GardenService.Remote("BuyPetSlot") -- client → server: (expectedSlots: number)
local buyUpgradeEvent = GardenService.Remote("BuyUpgrade") -- client → server: (id: string, expectedLevel: number)
local buyToolEvent = GardenService.Remote("BuyTool") -- client → server: (id: string, expectedLevel: number)
local buyCartEvent = GardenService.Remote("BuyCart") -- client → server: (slot: number, crop: string, count: number)
local feedCropEvent = GardenService.Remote("FeedCrop") -- client → server: (uid: string, crop: string, count: number)

local reject = GardenService.Reject

local settledOnline = {} -- [Player] = true once the join settle ran (later settles count as online time)
local notices = {} -- [Player] = { converted?, tended? } for this session's panel (the conversion and what the pets did while away)

local GardenField = {}

local function finite(value: any): boolean
	return type(value) == "number" and value == value and math.abs(value) < 1e12
end

local function count(value: any): number
	return if finite(value) then math.max(0, math.floor(value)) else 0
end

-- { [cropId] = whole number > 0 } from whatever is stored (unknown crops and zeros dropped).
local function cleanStock(stock)
	local clean = {}
	if type(stock) == "table" then
		for id, n in stock do
			if CropConfig.ById[id] and count(n) > 0 then
				clean[id] = count(n)
			end
		end
	end
	return clean
end

-- Number of squares in the set `open`.
local function openCount(open): number
	local n = 0
	for _ in open do
		n += 1
	end
	return n
end

-- { [square] = true } of the stored open set ({ ["n"] = true }) or, for a field from before E1d2, of its Count first squares
-- moved onto the new grid; at least StartOpen. Returns the set and the old-to-new square map of a migrated field (nil otherwise).
local function openSet(field): ({ [number]: boolean }, { [number]: number }?)
	local open, moved = {}, nil
	if type(field.Open) == "table" then
		for key, value in field.Open do
			local n = tonumber(key)
			if value == true and n and CropConfig.Cell(n) then
				open[n] = true
			end
		end
	elseif field.Count ~= nil then
		moved = {}
		for old = 1, math.clamp(count(field.Count), CropConfig.StartSquares, 12) do
			local n = CropConfig.FromOldSquare(old) :: number
			open[n] = true
			moved[old] = n
		end
	end
	if openCount(open) < CropConfig.StartSquares then
		for _, n in CropConfig.StartOpen do
			open[n] = true
		end
	end
	return open, moved
end

-- The profile's field, cleaned (idempotent), and its open set { [square] = true }, or nil without a garden table. A player gets
-- a new field the first time: the StartOpen squares, empty, and StartSeeds.
local function fieldOf(player: Player, profile)
	local garden = profile.Garden
	if type(garden) ~= "table" then
		return nil
	end
	local field = garden.Field
	if type(field) ~= "table" then
		field = { Squares = {}, SettledAt = os.time() }
		garden.Field = field
		garden.Seeds = table.clone(CropConfig.StartSeeds)
		garden.Items = {}
		garden.ItemSize = {}
		garden.Renown = 0
	end
	local open, moved = openSet(field)
	field.Open = {}
	for n in open do
		field.Open[tostring(n)] = true
	end
	field.Count = nil
	if not finite(field.SettledAt) then
		field.SettledAt = os.time()
	end
	local squares = {}
	if type(field.Squares) == "table" then
		for key, square in field.Squares do
			local index = tonumber(key)
			if moved and index then
				index = moved[index]
			end
			if
				index
				and open[index]
				and type(square) == "table"
				and CropConfig.ById[square.Crop]
			then
				squares[tostring(index)] = {
					Crop = square.Crop,
					Grown = if finite(square.Grown) then math.max(0, square.Grown) else 0,
					N = count(square.N),
					Tried = if square.Tried == true then true else nil,
					Crow = if square.Crow == true then true else nil,
				}
			end
		end
	end
	field.Squares = squares
	field.Plantings = count(field.Plantings)
	for _, square in squares do
		if square.N == 0 then -- planted before E1b: give it its own planting number
			field.Plantings += 1
			square.N = field.Plantings
		end
	end
	garden.Seeds = cleanStock(garden.Seeds)
	garden.Items = cleanStock(garden.Items)
	-- sizes: one summed factor per stored crop, within what its count can hold (missing = factor 1 each, from before E1c2)
	local low, high = CropConfig.SizeBounds()
	local sizes, best = {}, {}
	for id, n in garden.Items do
		local stored = type(garden.ItemSize) == "table" and garden.ItemSize[id]
		sizes[id] = if finite(stored) and stored > 0 then math.clamp(stored, n * low, n * high) else n
	end
	if type(garden.BestSize) == "table" then
		for id, factor in garden.BestSize do
			if CropConfig.ById[id] and finite(factor) and factor > 0 then
				best[id] = math.clamp(factor, low, high)
			end
		end
	end
	garden.ItemSize = sizes
	garden.BestSize = best
	garden.Renown = count(garden.Renown)
	local upgrades = {}
	for _, upgrade in CropConfig.Upgrades do
		local level = CropConfig.UpgradeLevel(field.Upgrades, upgrade.id)
		upgrades[upgrade.id] = if level > 0 then level else nil
	end
	field.Upgrades = upgrades
	local tools = {}
	for _, tool in CropConfig.Tools do
		local level = CropConfig.ToolLevel(garden.Tools, tool.id)
		tools[tool.id] = if level > 0 then level else nil
	end
	garden.Tools = tools
	local cart = type(garden.Cart) == "table" and garden.Cart
	local bought = {}
	if cart and type(cart.Day) == "number" and type(cart.Bought) == "table" then
		for key, n in cart.Bought do
			if type(key) == "string" and CropConfig.ById[(string.gsub(key, "%*$", ""))] and count(n) > 0 then
				bought[key] = count(n)
			end
		end
	end
	garden.Cart = { Day = if cart and type(cart.Day) == "number" then cart.Day else 0, Bought = bought }
	local meters = {}
	if type(garden.Meters) == "table" then
		for key, points in garden.Meters do
			if StageConfig.ByKey[key] and finite(points) and points > 0 then
				meters[key] = math.min(points, CropConfig.ObbySeeds.MeterSize)
			end
		end
	end
	garden.Meters = meters
	garden.RareDay = if finite(garden.RareDay) then garden.RareDay else nil
	local last = type(garden.LastCrop) == "string" and CropConfig.ById[garden.LastCrop]
	garden.LastCrop = if last and not last.rare then last.id else nil

	-- field pets: an owned pet with the job's aptitude, on an owned square of its own, within the slots (in uid order);
	-- PetService unequips a field pet (equipped and on the field never both)
	garden.FieldPetSlots = math.clamp(count(garden.FieldPetSlots), 1, #CropConfig.PetSlotPrices)
	local pets, taken, placed = {}, {}, 0
	if type(garden.FieldPets) == "table" then
		local uids = {}
		for uid in garden.FieldPets do
			if type(uid) == "string" then
				table.insert(uids, uid)
			end
		end
		table.sort(uids)
		for _, uid in uids do
			local entry = garden.FieldPets[uid]
			local square = type(entry) == "table" and entry.Square
			if moved and type(square) == "number" then
				square = moved[square]
			end
			if
				type(square) == "number"
				and open[square]
				and not taken[square]
				and (entry.Job == "Tending" or entry.Job == "PestControl")
				and profile.Pets[uid]
				and PetConfig.AptitudeLevel(profile.Pets[uid], entry.Job) > 0
				and placed < garden.FieldPetSlots
			then
				pets[uid] = { Square = square, Job = entry.Job }
				taken[square] = true
				placed += 1
			end
		end
	end
	garden.FieldPets = pets
	return field, open
end
GardenField.FieldOf = fieldOf

-- Garden.Cart for today (a new day starts with nothing bought), and the key under which offer `offer` counts.
local function cartToday(garden)
	local today = CropConfig.CartDay(os.time())
	if garden.Cart.Day ~= today then
		garden.Cart = { Day = today, Bought = {} }
	end
	return garden.Cart, today
end
local function cartKey(offer): string
	return offer.crop.id .. (if offer.taste then "*" else "")
end

-- Whether the Shears give planting number `n` of `player` a second crop: the same planting always rolls the same.
local function shearsExtra(player: Player, garden, n: number): boolean
	local chance = CropConfig.ToolEffect(garden.Tools, "Shears")
	return chance > 0 and Random.new(player.UserId * 6271 + n * 15485863):NextNumber() < chance
end

-- Puts one harvested crop of planting `planting` into the barn with its rolled size (× the Seed sorter), and a second one of the
-- same size when `extra`. Returns the factor and whether it is the player's best of that crop so far.
local function store(player: Player, garden, crop, planting: number, extra: boolean?): (number, boolean)
	local factor = CropConfig.SizeFactor(player.UserId, planting) * (1 + CropConfig.ToolEffect(garden.Tools, "Sorter"))
	local n = if extra then 2 else 1
	garden.Items[crop.id] = (garden.Items[crop.id] or 0) + n
	garden.ItemSize[crop.id] = (garden.ItemSize[crop.id] or 0) + factor * n
	local record = factor > (garden.BestSize[crop.id] or 0)
	if record then
		garden.BestSize[crop.id] = factor
	end
	return factor, record
end

-- [square] = Tending strength on that square: the strongest Tending pet that reaches it (the same job does not stack).
local function tendingStrength(profile, open)
	local best = {}
	for uid, entry in profile.Garden.FieldPets do
		local level = PetConfig.AptitudeLevel(profile.Pets[uid], "Tending") -- every placed pet with Tending tends (E4-thin)
		if level > 0 then
			for _, n in CropConfig.Reach(entry.Square, PetConfig.ReachShape(level), open) do
				best[n] = math.max(best[n] or 0, PetConfig.Strength(level))
			end
		end
	end
	return best
end

-- [square] = { chance, uid } of the strongest guard against crows that reaches it (E4-thin).
local function guardStrength(profile, open)
	local best = {}
	for uid, entry in profile.Garden.FieldPets do
		local pet = profile.Pets[uid]
		local level = PetConfig.AptitudeLevel(pet, "PestControl")
		if level > 0 then
			local chance = PetConfig.GuardChance(level, pet.Spec, "Crows")
			for _, n in CropConfig.Reach(entry.Square, PetConfig.ReachShape(level), open) do
				if not best[n] or chance > best[n].chance then
					best[n] = { chance = chance, uid = uid }
				end
			end
		end
	end
	return best
end

-- The crow roll and the guard roll of `player`'s planting number `n` (E4-thin), uniform in [0, 1), deterministic like tendRoll.
local function crowRoll(player: Player, n: number): number
	return Random.new(player.UserId * 6997 + n * 130003 + 17):NextNumber()
end
local function guardRoll(player: Player, n: number): number
	return Random.new(player.UserId * 5003 + n * 150001 + 29):NextNumber()
end

-- The Tending roll of `player`'s planting number `n`, uniform in [0, 1): the same planting always rolls the same.
local function tendRoll(player: Player, n: number): number
	return Random.new(player.UserId * 7919 + n * 104729):NextNumber()
end

-- Adds the growth since SettledAt to every planted square and moves SettledAt to now: an absence (the join) at the offline
-- rate, anything else at the online rate. In an absence Tending pets harvest and replant the ripe crops in their reach.
-- Placed pets gain aptitude XP by the same weighted seconds. In an absence crows raid afterwards (E4-thin). Returns whether a
-- square's look, a crop or a pet's aptitude level changed, { [cropId] = harvests by pets } (nil when none) and the raid
-- ({ ate = { [cropId] = n }, chased = { [uid] = n } }, nil when nothing happened).
local RIPEN_EPSILON = 1e-7 -- fractional speed boosts can leave a mathematically ripe crop just below its boundary
local function settle(player: Player, profile, field, open, absence: boolean): (boolean, { [string]: number }?, any)
	local now = os.time()
	local start = field.SettledAt
	local elapsed = if field.SettledAt <= now then now - field.SettledAt else 0
	local growth = if absence then CropConfig.Growth(0, elapsed) else CropConfig.Growth(elapsed, 0)
	field.SettledAt = now
	if growth <= 0 then
		return false, nil
	end
	local garden = profile.Garden
	local cloches = if absence then 1 else 1 + CropConfig.ToolEffect(garden.Tools, "Cloches") -- online growth only
	local cropGrowth = growth * cloches * CropConfig.GrowthSpeed(CropConfig.UpgradeLevel(field.Upgrades, "Growth"))
	local barn = CropConfig.BarnFor(CropConfig.UpgradeLevel(field.Upgrades, "Barn"))
	local strength = if absence then tendingStrength(profile, open) else {}
	local changed, tended = false, nil
	local keys = {}
	for key in field.Squares do
		table.insert(keys, key)
	end
	table.sort(keys, function(a, b) -- square order: replants take planting numbers in a fixed order
		return tonumber(a) < tonumber(b)
	end)
	for _, key in keys do
		local square = field.Squares[key]
		local crop = CropConfig.ById[square.Crop]
		local before = CropConfig.Stage(crop, square.Grown)
		square.Grown += cropGrowth
		if square.Grown < crop.growSeconds and crop.growSeconds - square.Grown <= RIPEN_EPSILON then
			square.Grown = crop.growSeconds
		end
		local chance = strength[tonumber(key)]
		local entry = square
		while
			chance
			and entry
			and entry.Grown >= crop.growSeconds
			and not entry.Tried
			and CropConfig.SeedTotal(garden.Items) < barn
		do
			if tendRoll(player, entry.N) >= chance then
				entry.Tried = true -- the pet did not get to it: it waits for the owner
				break
			end
			local extra = shearsExtra(player, garden, entry.N) and CropConfig.SeedTotal(garden.Items) + 1 < barn
			store(player, garden, crop, entry.N, extra)
			garden.Renown += crop.points or 0
			tended = tended or {}
			tended[crop.id] = (tended[crop.id] or 0) + (if extra then 2 else 1)
			local leftover = math.min(entry.Grown - crop.growSeconds, cropGrowth) -- growth from before this absence does not carry over
			if (garden.Seeds[crop.id] or 0) > 0 then
				garden.Seeds[crop.id] -= 1
				if garden.Seeds[crop.id] == 0 then
					garden.Seeds[crop.id] = nil
				end
				field.Plantings += 1
				entry = { Crop = crop.id, Grown = leftover, N = field.Plantings }
			else
				entry = nil
			end
			field.Squares[key] = entry
		end
		changed = changed or entry ~= square or CropConfig.Stage(crop, square.Grown) ~= before
	end
	for uid in garden.FieldPets do
		local pet = profile.Pets[uid]
		if pet then -- both field jobs learn (E4-thin); GainAptitudeXp ignores an aptitude the pet lacks
			local levels = PetConfig.GainAptitudeXp(pet, "Tending", growth) + PetConfig.GainAptitudeXp(pet, "PestControl", growth)
			changed = changed or levels > 0
		end
	end

	-- E4-thin crows: the crops that were ripe while a crow block overlapped the absence, in square order
	local raid = nil
	local rules = CropConfig.Crows
	if absence and CropConfig.RenownLevel(garden.Renown) >= rules.FromLevel then
		local rate = CropConfig.OfflineRate * CropConfig.GrowthSpeed(CropConfig.UpgradeLevel(field.Upgrades, "Growth"))
		local grownUntil = start + math.min(elapsed, CropConfig.OfflineCapSeconds) -- offline growth stops at the cap
		local guards = guardStrength(profile, open)
		local eaten = 0
		for _, key in keys do
			local entry = field.Squares[key]
			local crop = entry and CropConfig.ById[entry.Crop]
			if crop and not crop.rare and not entry.Crow and entry.Grown >= crop.growSeconds then
				local ripeAt = math.max(start, grownUntil - (entry.Grown - crop.growSeconds) / rate)
				if ripeAt < now and CropConfig.CrowsBetween(ripeAt, now) then
					entry.Crow = true -- rolled: this planting faces crows only once
					if crowRoll(player, entry.N) < rules.Chance then
						raid = raid or { ate = {}, chased = {} }
						local guard = guards[tonumber(key)]
						if guard and guardRoll(player, entry.N) < guard.chance then
							raid.chased[guard.uid] = (raid.chased[guard.uid] or 0) + 1
						else
							field.Squares[key] = nil
							raid.ate[crop.id] = (raid.ate[crop.id] or 0) + 1
							changed = true
							eaten += 1
							if eaten >= rules.Cap then
								break
							end
						end
					end
				end
			end
		end
	end
	return changed, tended, raid
end
GardenField.Settle = settle

-- Today's market cart for the panel: { nextAt = server time of the next offers, offers = { { slot, crop, count, left, price, base,
-- discount?, taste? } } }.
local function cartState(garden)
	local cart, today = cartToday(garden)
	local offers = {}
	for _, offer in CropConfig.CartOffers(today, CropConfig.RenownLevel(garden.Renown)) do
		table.insert(offers, {
			slot = offer.slot,
			crop = offer.crop.id,
			count = offer.count,
			left = math.max(0, offer.count - (cart.Bought[cartKey(offer)] or 0)),
			price = offer.price,
			base = offer.crop.seed,
			discount = offer.discount,
			taste = offer.taste,
		})
	end
	return { nextAt = (today + 1) * CropConfig.DaySeconds, offers = offers }
end

local function onlineSpeed(garden, field): number
	return CropConfig.OnlineRate * (1 + CropConfig.ToolEffect(garden.Tools, "Cloches"))
		* CropConfig.GrowthSpeed(CropConfig.UpgradeLevel(field.Upgrades, "Growth"))
end

-- Grown was earned through SettledAt, even if a visitor requests this plot much later.
-- The first whole server second that accepts Harvest is the visual ripe boundary.
local function growthWindow(field, square, duration: number, speed: number): (number, number)
	if square.Grown >= duration then
		return 0, 0
	end
	local startAt = field.SettledAt - square.Grown / speed
	return startAt, field.SettledAt + math.ceil((duration - square.Grown - RIPEN_EPSILON) / speed)
end

-- What GardenRemotes.State.field holds for the owner's panel, or nil without a field.
GardenService.AddStateField("field", function(profile)
	local owner = nil
	for _, player in Players:GetPlayers() do
		if PlayerProfile.Get(player) == profile then
			owner = player
		end
	end
	local field, open
	if owner then
		field, open = fieldOf(owner, profile)
	end
	if not field then
		return nil
	end
	local list = {} -- the open squares in order
	for n in open do
		table.insert(list, n)
	end
	table.sort(list)
	local now = os.time()
	local speed = onlineSpeed(profile.Garden, field)
	local squares = {}
	for key, square in field.Squares do
		local crop = CropConfig.ById[square.Crop]
		-- server time when the crop is ripe if the owner stays online (the panel's countdown)
		local startAt, finish = growthWindow(field, square, crop.growSeconds, speed)
		local readyAt = if finish == 0 then now else finish
		local grown = if finish == 0 then crop.growSeconds
			else crop.growSeconds * math.clamp((now - startAt) / (finish - startAt), 0, 1)
		squares[key] = { crop = square.Crop, grown = math.floor(grown), readyAt = readyAt }
	end
	local garden = profile.Garden
	local pets = {} -- [square] = the pet working there
	for uid, entry in garden.FieldPets do
		local pet = profile.Pets[uid]
		local apt = pet.Apt[entry.Job]
		local cap = PetConfig.AptitudeCap(pet.Kind)
		local need = if apt.L < cap then PetConfig.AptitudeXpToNext(apt.L) else nil
		local guard = pet.Apt.PestControl -- E4-thin: the guard job, also for a pet whose primary job is Tending
		pets[tostring(entry.Square)] = {
			uid = uid,
			kind = pet.Kind,
			level = PetConfig.PetLevel(pet),
			job = entry.Job,
			apt = apt.L,
			xp = math.floor(apt.XP),
			next = need,
			reach = PetConfig.ReachShape(apt.L),
			guard = if guard
				then {
					level = guard.L,
					xp = math.floor(guard.XP),
					next = if guard.L < cap then PetConfig.AptitudeXpToNext(guard.L) else nil,
					reach = PetConfig.ReachShape(guard.L),
					chance = PetConfig.GuardChance(guard.L, pet.Spec, "Crows"),
					spec = pet.Spec,
				}
				else nil,
		}
	end
	local crowsFrom, crowsTo = CropConfig.NextCrows(now, 24 * 3600)
	return {
		open = list,
		squares = squares,
		seeds = garden.Seeds,
		items = garden.Items,
		sizes = garden.ItemSize,
		best = garden.BestSize,
		renown = garden.Renown,
		level = CropConfig.RenownLevel(garden.Renown),
		pets = pets,
		slots = garden.FieldPetSlots,
		slotPrice = CropConfig.PetSlotPrices[garden.FieldPetSlots + 1],
		upgrades = table.clone(field.Upgrades),
		barn = CropConfig.BarnFor(CropConfig.UpgradeLevel(field.Upgrades, "Barn")),
		tools = table.clone(garden.Tools),
		cart = cartState(garden),
		notice = notices[owner],
		crows = {
			from = crowsFrom,
			to = crowsTo,
			active = CropConfig.RenownLevel(garden.Renown) >= CropConfig.Crows.FromLevel,
		},
	}
end)

-- The field part of `player`'s plot message ({ crops = 2 characters per square 1..MaxSquares: crop letter + stage 1-3, ".0" for
-- an empty open square, "#0" for a locked one; pets = { "Kind:Level:uid:square:tending:guard" } }; the shape is CropConfig.RowWidths),
-- tending / guard = the pet's Tending / Pest-control level (0 without it, E4b), each job's reach PetConfig.ReachShape(level)), or nil
-- without a field.
function GardenField.PlotField(player: Player)
	local profile = PlayerProfile.Get(player)
	local field, open
	if profile then
		field, open = fieldOf(player, profile)
	end
	if not field then
		return nil
	end
	local cells = table.create(CropConfig.MaxSquares)
	local plants
	local speed = onlineSpeed(profile.Garden, field)
	for n = 1, CropConfig.MaxSquares do
		local key = tostring(n)
		local square = field.Squares[key]
		local crop = square and CropConfig.ById[square.Crop]
		cells[n] = if not open[n] then "#0" elseif crop then crop.letter .. CropConfig.Stage(crop, square.Grown) else ".0"
		if open[n] and crop then
			local startAt, readyAt = growthWindow(field, square, crop.growSeconds, speed)
			plants = plants or {}
			plants[key] = { n = square.N, startAt = startAt, readyAt = readyAt }
		end
	end
	local pets = {} -- "Kind:Level:uid:square:tending:guard" per field pet, by square
	for uid, entry in profile.Garden.FieldPets do
		local pet = profile.Pets[uid]
		local tending = PetConfig.AptitudeLevel(pet, "Tending")
		local guard = PetConfig.AptitudeLevel(pet, "PestControl")
		table.insert(pets, string.format("%s:%d:%s:%d:%d:%d", pet.Kind, PetConfig.PetLevel(pet), uid, entry.Square, tending, guard))
	end
	table.sort(pets, function(a, b)
		return tonumber(string.match(a, ":(%d+):%d+$")) < tonumber(string.match(b, ":(%d+):%d+$"))
	end)
	return { crops = table.concat(cells), pets = pets, plants = plants }
end

-- The caller's profile, field and open set if they may use the field now (loaded, at their plot unless `anywhere`);
-- otherwise rejects. The field is settled (online) first, so every action sees the growth up to now.
local function usableField(player: Player, action: string, anywhere: boolean?)
	local profile
	if anywhere then
		profile = PlayerProfile.Get(player)
		if not profile then
			reject(player, action, "loading")
		end
	else
		profile = GardenService.Usable(player, action)
	end
	local field, open
	if profile then
		field, open = fieldOf(player, profile)
	end
	if not field then
		return nil, nil, nil
	end
	local _, tended, raid = settle(player, profile, field, open, not settledOnline[player])
	if tended or raid then
		notices[player] = notices[player] or {}
		notices[player].tended = tended or notices[player].tended
		notices[player].crows = raid or notices[player].crows
	end
	settledOnline[player] = true
	return profile, field, open
end

-- True when the character stands within SeedStallDistance of Workspace.Garden.SeedStall (U4: BuySeeds / BuyCart).
local function nearStall(player: Player): boolean
	local garden = workspace:FindFirstChild("Garden")
	local stall = garden and garden:FindFirstChild(GardenConfig.SeedStallName)
	local anchor = stall and stall:IsA("Model") and stall.PrimaryPart
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return anchor ~= nil
		and root ~= nil
		and root:IsA("BasePart")
		and (root.Position - anchor.Position).Magnitude <= GardenConfig.SeedStallDistance
end

local function done(player: Player, action: string, detail: any)
	GardenService.PublishAll(player)
	GardenService.Succeed(player, action, detail)
	task.spawn(PlayerProfile.Save, player)
end

-- Removes `amount` held crops of `cropId` from the barn (the caller checked they are there); returns the summed size factor
-- that leaves with them (their average size: a sale, a pet's meal and a talent bundle all take the average).
local function removeItems(garden, cropId: string, amount: number): number
	local held = garden.Items[cropId]
	local part = (garden.ItemSize[cropId] or held) * amount / held
	garden.Items[cropId] = held - amount
	garden.ItemSize[cropId] = (garden.ItemSize[cropId] or held) - part
	if garden.Items[cropId] == 0 then
		garden.Items[cropId] = nil
		garden.ItemSize[cropId] = nil
	end
	return part
end

plantEvent.OnServerEvent:Connect(function(player, square, cropId)
	local crop = type(cropId) == "string" and CropConfig.ById[cropId]
	if not (GardenService.WholeNumber(square) and crop) or not GardenService.Allow(player) then
		return
	end
	local profile, field, open = usableField(player, "Plant")
	if not field then
		return
	end
	local garden = profile.Garden
	if not open[square] then
		return reject(player, "Plant", "square")
	end
	if field.Squares[tostring(square)] then
		return reject(player, "Plant", "occupied")
	end
	if (garden.Seeds[crop.id] or 0) < 1 then -- no Renown gate: seeds held (the market cart's taste) can always be planted
		return reject(player, "Plant", "seeds")
	end

	garden.Seeds[crop.id] -= 1
	if garden.Seeds[crop.id] == 0 then
		garden.Seeds[crop.id] = nil
	end
	field.Plantings += 1
	field.Squares[tostring(square)] = { Crop = crop.id, Grown = 0, N = field.Plantings }
	if not crop.rare then
		garden.LastCrop = crop.id -- E2b: the seed pouch drops this crop
	end
	done(player, "Plant", { square = square, crop = crop.id })
end)

harvestEvent.OnServerEvent:Connect(function(player, square)
	if not GardenService.WholeNumber(square) or not GardenService.Allow(player) then
		return
	end
	local profile, field = usableField(player, "Harvest")
	if not field then
		return
	end
	local entry = field.Squares[tostring(square)]
	if not entry then
		return reject(player, "Harvest", "empty")
	end
	local crop = CropConfig.ById[entry.Crop]
	if entry.Grown < crop.growSeconds then
		return reject(player, "Harvest", "notripe")
	end

	local garden = profile.Garden
	field.Squares[tostring(square)] = nil
	local extra = shearsExtra(player, garden, entry.N)
	local size, record = store(player, garden, crop, entry.N, extra)
	local before = CropConfig.RenownLevel(garden.Renown)
	garden.Renown += crop.points or 0
	local level = CropConfig.RenownLevel(garden.Renown)
	done(player, "Harvest", {
		square = square,
		crop = crop.id,
		level = level,
		levelUp = level > before,
		size = size,
		best = record or nil,
		extra = extra or nil,
	})
end)

buySeedsEvent.OnServerEvent:Connect(function(player, cropId, amount)
	local crop = type(cropId) == "string" and CropConfig.ById[cropId]
	if not (crop and GardenService.WholeNumber(amount) and amount >= 1) or not GardenService.Allow(player) then
		return
	end
	if not nearStall(player) then
		return reject(player, "BuySeeds", "far") -- U4: seeds are sold at the plaza's seed stall, not at the plot
	end
	local profile, field = usableField(player, "BuySeeds", true)
	if not field then
		return
	end
	local garden = profile.Garden
	if crop.rare then
		return reject(player, "BuySeeds", "obby") -- rare seeds come only from the obby (E2)
	end
	if CropConfig.RenownLevel(garden.Renown) < crop.renown then
		return reject(player, "BuySeeds", "renown")
	end
	if CropConfig.SeedTotal(garden.Seeds) + amount > CropConfig.BarnFor(CropConfig.UpgradeLevel(field.Upgrades, "Barn")) then
		return reject(player, "BuySeeds", "barn")
	end
	local price = crop.seed * amount
	if profile.Coins < price then
		return reject(player, "BuySeeds", "coins")
	end

	PlayerProfile.AddCoins(player, -price)
	garden.Seeds[crop.id] = (garden.Seeds[crop.id] or 0) + amount
	done(player, "BuySeeds", { crop = crop.id, count = amount, price = price })
end)

sellEvent.OnServerEvent:Connect(function(player, cropId, amount)
	local crop = type(cropId) == "string" and CropConfig.ById[cropId]
	if not (crop and GardenService.WholeNumber(amount) and amount >= 1) or not GardenService.Allow(player) then
		return
	end
	local profile, field = usableField(player, "Sell", true) -- from anywhere (playtest 2026-11-08): the Barn button and the stall's Sell tab
	if not field then
		return
	end
	local garden = profile.Garden
	if (garden.Items[crop.id] or 0) < amount then
		return reject(player, "Sell", "items")
	end

	local part = removeItems(garden, crop.id, amount) -- the average size of what is stored
	local paid = CoinRewards.Grant(player, CropConfig.SaleValue(crop, part), "crop") or 0 -- the pet bonus at sale time
	done(player, "Sell", { crop = crop.id, count = amount, paid = paid })
end)

-- E1a3: feeds `amount` held crops to one owned pet (equipped, resting or on the field), clamped to the care XP it can still use
-- (P4: PetConfig.GainCareXp, Cuteness first, else the lowest working trait below the care cap).
feedCropEvent.OnServerEvent:Connect(function(player, uid, cropId, amount)
	local crop = type(cropId) == "string" and CropConfig.ById[cropId]
	if not (type(uid) == "string" and crop and GardenService.WholeNumber(amount) and amount >= 1) or not GardenService.Allow(player) then
		return
	end
	local profile, field = usableField(player, "FeedCrop", true)
	if not field then
		return
	end
	local pet = profile.Pets[uid]
	if not pet then
		return
	end
	local garden = profile.Garden
	local held = garden.Items[crop.id] or 0
	if held < amount then
		return reject(player, "FeedCrop", "items")
	end
	local toMax = GardenConfig.XpToMax(pet)
	if toMax <= 0 then
		return reject(player, "FeedCrop", "maxed")
	end

	local used = math.min(amount, math.ceil(toMax / crop.xp)) -- the last crop may go past what the pet can use (that XP is lost)
	removeItems(garden, crop.id, used) -- the average size leaves, as in a sale
	local trained, wasted = PetConfig.GainCareXp(pet, crop.xp * used)
	done(player, "FeedCrop", {
		uid = uid,
		crop = crop.id,
		used = used,
		xp = crop.xp * used - wasted,
		level = PetConfig.PetLevel(pet),
		trained = trained, -- { { id, levels, level } } in order (P4)
	})
end)

buySquareEvent.OnServerEvent:Connect(function(player, square, expected)
	if not (GardenService.WholeNumber(square) and GardenService.WholeNumber(expected)) or not GardenService.Allow(player) then
		return
	end
	local profile, field, open = usableField(player, "BuySquare")
	if not field then
		return
	end
	if not CropConfig.Cell(square) then
		return reject(player, "BuySquare", "square")
	end
	if open[square] then
		return reject(player, "BuySquare", "open")
	end
	local opened = openCount(open)
	local expansion = CropConfig.NextExpansion(opened)
	if not expansion then
		return reject(player, "BuySquare", "maxed")
	end
	if expected ~= opened then
		return reject(player, "BuySquare", "stale") -- out-of-date prompt, double click or forged request
	end
	if CropConfig.RenownLevel(profile.Garden.Renown) < expansion.renown then
		return reject(player, "BuySquare", "renown")
	end
	if profile.Coins < expansion.price then
		return reject(player, "BuySquare", "coins")
	end

	PlayerProfile.AddCoins(player, -expansion.price)
	field.Open[tostring(square)] = true
	done(player, "BuySquare", { square = square, open = opened + 1, price = expansion.price })
end)

buyUpgradeEvent.OnServerEvent:Connect(function(player, id, expected)
	local upgrade = type(id) == "string" and CropConfig.UpgradeById[id]
	if not (upgrade and GardenService.WholeNumber(expected)) or not GardenService.Allow(player) then
		return
	end
	local profile, field = usableField(player, "BuyUpgrade", true)
	if not field then
		return
	end
	local level = CropConfig.UpgradeLevel(field.Upgrades, upgrade.id)
	local price = upgrade.prices[level + 1]
	if not price then
		return reject(player, "BuyUpgrade", "maxed")
	end
	if expected ~= level then
		return reject(player, "BuyUpgrade", "stale") -- out-of-date panel, double click or forged request
	end
	if CropConfig.RenownLevel(profile.Garden.Renown) < (upgrade.renown[level + 1] or 0) then
		return reject(player, "BuyUpgrade", "renown")
	end
	if profile.Coins < price then
		return reject(player, "BuyUpgrade", "coins")
	end

	PlayerProfile.AddCoins(player, -price) -- the field was settled at the old rate just now (usableField)
	field.Upgrades[upgrade.id] = level + 1
	done(player, "BuyUpgrade", { id = upgrade.id, level = level + 1, price = price })
end)

buyCartEvent.OnServerEvent:Connect(function(player, slot, cropId, amount)
	if
		not (GardenService.WholeNumber(slot) and type(cropId) == "string" and GardenService.WholeNumber(amount) and amount >= 1)
		or not GardenService.Allow(player)
	then
		return
	end
	if not nearStall(player) then
		return reject(player, "BuyCart", "far")
	end
	local profile, field = usableField(player, "BuyCart", true)
	if not field then
		return
	end
	local garden = profile.Garden
	local cart, today = cartToday(garden)
	local offer = CropConfig.CartOffers(today, CropConfig.RenownLevel(garden.Renown))[slot]
	if not offer or offer.crop.id ~= cropId then
		return reject(player, "BuyCart", "stale") -- a new day, a Renown level-up or an old panel
	end
	local key = cartKey(offer)
	local left = offer.count - (cart.Bought[key] or 0)
	if left < 1 then
		return reject(player, "BuyCart", "soldout")
	end
	if amount > left then
		return reject(player, "BuyCart", "stale")
	end
	if CropConfig.SeedTotal(garden.Seeds) + amount > CropConfig.BarnFor(CropConfig.UpgradeLevel(field.Upgrades, "Barn")) then
		return reject(player, "BuyCart", "barn")
	end
	local price = offer.price * amount
	if profile.Coins < price then
		return reject(player, "BuyCart", "coins")
	end

	PlayerProfile.AddCoins(player, -price)
	garden.Seeds[offer.crop.id] = (garden.Seeds[offer.crop.id] or 0) + amount
	cart.Bought[key] = (cart.Bought[key] or 0) + amount
	done(player, "BuyCart", { crop = offer.crop.id, count = amount, price = price, taste = offer.taste })
end)

buyToolEvent.OnServerEvent:Connect(function(player, id, expected)
	local tool = type(id) == "string" and CropConfig.ToolById[id]
	if not (tool and GardenService.WholeNumber(expected)) or not GardenService.Allow(player) then
		return
	end
	local profile, field = usableField(player, "BuyTool", true)
	if not field then
		return
	end
	local garden = profile.Garden
	local level = CropConfig.ToolLevel(garden.Tools, tool.id)
	local price = tool.prices[level + 1]
	if not price then
		return reject(player, "BuyTool", "maxed")
	end
	if expected ~= level then
		return reject(player, "BuyTool", "stale") -- out-of-date panel, double click or forged request
	end
	if CropConfig.RenownLevel(garden.Renown) < tool.renown[level + 1] then
		return reject(player, "BuyTool", "renown")
	end
	if profile.Coins < price then
		return reject(player, "BuyTool", "coins")
	end

	PlayerProfile.AddCoins(player, -price) -- the field was settled at the old rate just now (usableField)
	garden.Tools[tool.id] = level + 1
	done(player, "BuyTool", { id = tool.id, level = level + 1, price = price })
end)

local function placedCount(garden): number
	local n = 0
	for _ in garden.FieldPets do
		n += 1
	end
	return n
end

placePetEvent.OnServerEvent:Connect(function(player, square, uid)
	if not (GardenService.WholeNumber(square) and type(uid) == "string") or not GardenService.Allow(player) then
		return
	end
	local profile, field, open = usableField(player, "PlacePet")
	if not field then
		return
	end
	local garden = profile.Garden
	local pet = profile.Pets[uid]
	if not pet then
		return
	end
	if not open[square] then
		return reject(player, "PlacePet", "square")
	end
	if table.find(profile.EquippedPets, uid) then
		return reject(player, "PlacePet", "equipped")
	end
	local tending = PetConfig.AptitudeLevel(pet, "Tending") > 0
	if not tending and PetConfig.AptitudeLevel(pet, "PestControl") < 1 then -- a field job: Tending or Pest control (E4-thin)
		return reject(player, "PlacePet", "aptitude")
	end
	for other, entry in garden.FieldPets do
		if entry.Square == square and other ~= uid then
			return reject(player, "PlacePet", "occupied")
		end
	end
	if not garden.FieldPets[uid] and placedCount(garden) >= garden.FieldPetSlots then
		return reject(player, "PlacePet", "slots")
	end

	local moved = garden.FieldPets[uid] ~= nil
	garden.FieldPets[uid] = { Square = square, Job = if tending then "Tending" else "PestControl" }
	done(player, "PlacePet", { square = square, uid = uid, moved = moved })
end)

liftPetEvent.OnServerEvent:Connect(function(player, uid)
	if type(uid) ~= "string" or not GardenService.Allow(player) then
		return
	end
	local profile, field = usableField(player, "LiftPet")
	if not field then
		return
	end
	local entry = profile.Garden.FieldPets[uid]
	if not entry then
		return
	end

	profile.Garden.FieldPets[uid] = nil
	done(player, "LiftPet", { square = entry.Square, uid = uid })
end)

buyPetSlotEvent.OnServerEvent:Connect(function(player, expected)
	if not GardenService.WholeNumber(expected) or not GardenService.Allow(player) then
		return
	end
	local profile, field = usableField(player, "BuyPetSlot", true)
	if not field then
		return
	end
	local garden = profile.Garden
	local price = CropConfig.PetSlotPrices[garden.FieldPetSlots + 1]
	if not price then
		return reject(player, "BuyPetSlot", "maxed")
	end
	if expected ~= garden.FieldPetSlots + 1 then
		return reject(player, "BuyPetSlot", "stale") -- out-of-date panel, double click or forged request
	end
	if profile.Coins < price then
		return reject(player, "BuyPetSlot", "coins")
	end

	PlayerProfile.AddCoins(player, -price)
	garden.FieldPetSlots = expected
	done(player, "BuyPetSlot", expected)
end)

-- The P2 pens -> field pet slots, once (E1b; ECONOMY → "Field-pet re-run" proposal 4; FA keeps it as the migration of a profile
-- from before the field). Pen production since the last payout is not paid (FA). Clears the legacy pen fields on every call.
-- Returns { pens, slots, refund, returned } or nil when already converted.
local function convert(player: Player, profile)
	local garden = profile.Garden
	local result = nil
	if not garden.Converted then
		local pens = math.clamp(count(garden.PenCount), 1, #CropConfig.LegacyPenPrices)
		local slots = CropConfig.PetSlotsFromPens[pens]
		local paid, value = 0, 0
		for n = 1, pens do
			paid += CropConfig.LegacyPenPrices[n]
		end
		for n = 1, slots do
			value += CropConfig.PetSlotPrices[n]
		end
		local refund = math.max(0, paid - value)
		local returned = 0
		if type(garden.Pens) == "table" then
			for _ in garden.Pens do
				returned += 1
			end
		end
		garden.FieldPetSlots = math.max(slots, count(garden.FieldPetSlots))
		garden.Converted = true
		if refund > 0 then
			PlayerProfile.AddCoins(player, refund) -- money back for pens, not a reward: no pet multiplier
		end
		result = { pens = pens, slots = slots, refund = refund, returned = returned }
	end
	garden.Pens, garden.PenCount, garden.Carry, garden.LastSeen = nil, nil, nil, nil -- the penned pets rest in the inventory
	return result
end

-- Join (and admin reset): a new field the first time, an old profile converted once, then the absence since SettledAt
-- counts as offline time (Tending pets work it).
GardenService.AddSetupHook(function(player)
	local profile = PlayerProfile.Get(player)
	local field, open
	if profile then
		field, open = fieldOf(player, profile)
	end
	if not field then
		return
	end
	local converted = convert(player, profile)
	local _, tended, raid = settle(player, profile, field, open, not settledOnline[player])
	settledOnline[player] = true
	if converted or tended or raid then
		notices[player] = notices[player] or {}
		notices[player].converted = converted or notices[player].converted
		notices[player].tended = tended or notices[player].tended
		notices[player].crows = raid or notices[player].crows
	end
	GardenService.PublishAll(player)
	if converted then
		task.spawn(PlayerProfile.Save, player)
	end
end)

-- Leave and shutdown: the time since the last settle was online.
PlayerProfile.OnLeaving(function(player, profile)
	if profile and settledOnline[player] then
		local field, open = fieldOf(player, profile)
		if field then
			settle(player, profile, field, open, false)
		end
	end
	settledOnline[player] = nil
	notices[player] = nil
end)

-- Online growth: every SettleSeconds; a changed look stage is published (the plot message and the owner's panel).
task.spawn(function()
	while true do
		task.wait(CropConfig.SettleSeconds)
		for _, player in Players:GetPlayers() do
			local profile = PlayerProfile.Get(player)
			if profile and settledOnline[player] then
				local field, open = fieldOf(player, profile)
				if field and settle(player, profile, field, open, false) then
					GardenService.PublishAll(player)
				end
			end
		end
	end
end)

-- E2a: the rare seeds a finished run on `stage` earns. `medal` = the run's medal (0 = none), `previousMedal` = the best before it,
-- `firstOnStage` = the day's first medal finish on this stage. Adds the seeds to Garden.Seeds (past the stock's limit: an earned seed is
-- never lost) and publishes the garden. Returns, for the results popup, { seeds = { { crop, count, why = "gold" | "daily" | "meter" } },
-- meter = { crop, points, size } } or nil (no medal, a stage without a rare crop).
function GardenField.ObbyFinish(player: Player, stage, medal: number, previousMedal: number, firstOnStage: boolean)
	local rules = CropConfig.ObbySeeds
	local crop = CropConfig.RareOfWorld(stage.world)
	if medal < 1 or not crop then
		return nil
	end
	local profile = PlayerProfile.Get(player)
	local field = profile and fieldOf(player, profile)
	if not field then
		return nil
	end
	local garden = profile.Garden
	local scouts = {}
	for _, uid in profile.EquippedPets do
		local pet = profile.Pets[uid]
		if pet and PetConfig.AptitudeLevel(pet, "Scouting") > 0 then
			table.insert(scouts, pet)
		end
	end
	local bonus = PetConfig.ScoutBonus(scouts)
	-- E2b seed pouch, before the rare seeds (they may go past the barn and would take its room)
	local pouch
	if firstOnStage then
		local pouchCrop = CropConfig.ById[garden.LastCrop or ""] or CropConfig.ById[rules.PouchDefault]
		local room = CropConfig.BarnFor(CropConfig.UpgradeLevel(field.Upgrades, "Barn")) - CropConfig.SeedTotal(garden.Seeds)
		local drop = rules.Pouch[medal] + (if bonus >= PetConfig.Scouting.PouchExtraAt - 1e-9 then 1 else 0)
		local count = math.clamp(room, 0, drop)
		pouch = { crop = pouchCrop.id, count = count, full = count < drop }
		if count > 0 then
			garden.Seeds[pouchCrop.id] = (garden.Seeds[pouchCrop.id] or 0) + count
		end
	end
	local seeds = {}
	local gold = StageConfig.MedalIndex.Gold
	if medal == gold and previousMedal < gold and stage.world >= rules.FirstGoldWorld then
		table.insert(seeds, { crop = crop.id, count = rules.FirstGold, why = "gold" })
	end
	local today = CropConfig.CartDay(os.time())
	if garden.RareDay ~= today then
		garden.RareDay = today
		table.insert(seeds, { crop = crop.id, count = rules.Daily, why = "daily" })
	end
	local points = (garden.Meters[stage.key] or 0) + rules.Points[medal] * (if firstOnStage then rules.FirstMult else 1) * (1 + bonus)
	local full = math.floor(points / rules.MeterSize)
	points -= full * rules.MeterSize
	garden.Meters[stage.key] = if points > 0 then points else nil
	if full > 0 then
		table.insert(seeds, { crop = crop.id, count = full, why = "meter" })
	end
	for _, gain in seeds do
		garden.Seeds[gain.crop] = (garden.Seeds[gain.crop] or 0) + gain.count
	end
	GardenService.PublishAll(player)
	local scoutLevels = 0
	for _, pet in scouts do
		scoutLevels += PetConfig.GainAptitudeXp(pet, "Scouting", PetConfig.Scouting.XpPerFinish)
	end
	if #scouts > 0 then
		PetService.Publish(player) -- the pet detail page shows the Scouting XP
	end
	if #seeds > 0 or (pouch and pouch.count > 0) or scoutLevels > 0 then
		task.spawn(PlayerProfile.Save, player)
	end
	return {
		seeds = seeds,
		pouch = pouch,
		meter = { crop = crop.id, points = points, size = rules.MeterSize },
		scout = if bonus > 0 then bonus else nil,
	}
end

-- EV2b talent bundles ({ [cropId] = count }, TalentConfig.crops) from the barn. TalentService calls HasCrops and, with no yield in
-- between, TakeCrops together with the Coins. The field is settled first (once the join settle ran: a Tending pet may have stored
-- crops since), so the check sees what the panel shows.
function GardenField.HasCrops(player: Player, bundle: { [string]: number }): boolean
	if next(bundle) == nil then
		return true
	end
	local profile = PlayerProfile.Get(player)
	local field, open
	if profile then
		field, open = fieldOf(player, profile)
	end
	if not field then
		return false
	end
	if settledOnline[player] then
		settle(player, profile, field, open, false)
	end
	for cropId, count in bundle do
		if (profile.Garden.Items[cropId] or 0) < count then
			return false
		end
	end
	return true
end

-- Takes a bundle HasCrops just accepted and publishes the garden (the barn count changed).
function GardenField.TakeCrops(player: Player, bundle: { [string]: number })
	if next(bundle) == nil then
		return
	end
	local garden = PlayerProfile.Get(player).Garden
	for cropId, count in bundle do
		removeItems(garden, cropId, count)
	end
	GardenService.PublishAll(player)
end

return GardenField
