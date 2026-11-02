-- GardenField: the crop field behind the player's plot (E1a2, docs/ROADMAP.md → E1a2, docs/EXPANSION.md §5). Server-only.
-- Open only to players with GardenConfig.HasFieldAccess (admins and Studio test users until E1 ships): for anyone else no
-- Field data is written, every remote is rejected ("locked") and the plot messages carry no field (GardenPlotFeed).
-- State lives in PlayerProfile.Garden: Field = { Count, Squares["1".."12"] = { Crop, Grown }, SettledAt }, Seeds[crop],
-- Items[crop], Renown (points; the level is derived, CropConfig.RenownLevel). Grown = growth seconds earned, SettledAt = the
-- server os.time() up to which growth was counted. Growth is settled on join (the time since SettledAt is an absence:
-- CropConfig.OfflineRate, capped), and while online (OnlineRate) every SettleSeconds, before every field action and on leave.
-- Ripe crops wait. The client only names a square, a crop or a count: prices, times and Renown come from here.
-- Field pets (E1b): Garden.FieldPets[uid] = { Square, Job } (Job "Tending"), Garden.FieldPetSlots. A Tending pet works the squares
-- in its reach (PetConfig.ReachShape, CropConfig.Reach; the strongest pet counts): during an absence (the join settle) a ripe crop
-- that was not tried yet is harvested by the pet with the chance PetConfig.Strength(level) (Items, Renown; only while the barn
-- has room) and replanted from Seeds with the leftover growth; a failed roll marks the planting Tried (it waits for the owner).
-- The roll is deterministic per owner and planting number (Squares[n].N from Field.Plantings), so a re-join never rerolls.
-- Placed pets earn aptitude XP in their job by the weighted field time (the same seconds as growth).
-- Pens convert once (Garden.Converted) on the join of a player with field access: penned pets back to the inventory,
-- CropConfig.PetSlotsFromPens slots, the rest of the pen prices refunded; GardenService then rejects the pen remotes.
-- Remotes (in GardenRemotes): Plant(square, crop), Harvest(square), BuySeeds(crop, count), Sell(crop, count),
-- BuySquare(expectedCount), PlacePet(square, uid) (also moves a placed pet), LiftPet(uid), BuyPetSlot(expectedSlots)
-- (client → server); answers on GardenRemotes.Result; GardenRemotes.State.field (the owner's panel).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GardenConfig = require(ReplicatedStorage.GardenConfig)
local CropConfig = require(ReplicatedStorage.CropConfig)
local PetConfig = require(ReplicatedStorage.PetConfig)
local PlayerProfile = require(ServerScriptService.PlayerProfile)
local CoinRewards = require(ServerScriptService.CoinRewards)
local GardenService = require(ServerScriptService.GardenService)

local plantEvent = GardenService.Remote("Plant") -- client → server: (square: number, crop: string)
local harvestEvent = GardenService.Remote("Harvest") -- client → server: (square: number)
local buySeedsEvent = GardenService.Remote("BuySeeds") -- client → server: (crop: string, count: number)
local sellEvent = GardenService.Remote("Sell") -- client → server: (crop: string, count: number)
local buySquareEvent = GardenService.Remote("BuySquare") -- client → server: (expectedCount: number)
local placePetEvent = GardenService.Remote("PlacePet") -- client → server: (square: number, uid: string)
local liftPetEvent = GardenService.Remote("LiftPet") -- client → server: (uid: string)
local buyPetSlotEvent = GardenService.Remote("BuyPetSlot") -- client → server: (expectedSlots: number)

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

-- The profile's field, cleaned (idempotent), or nil without access. A player with access gets a new field the first time:
-- StartSquares empty squares and StartSeeds.
local function fieldOf(player: Player, profile)
	local garden = profile.Garden
	if type(garden) ~= "table" or not GardenConfig.HasFieldAccess(player.UserId) then
		return nil
	end
	local field = garden.Field
	if type(field) ~= "table" then
		field = { Count = CropConfig.StartSquares, Squares = {}, SettledAt = os.time() }
		garden.Field = field
		garden.Seeds = table.clone(CropConfig.StartSeeds)
		garden.Items = {}
		garden.Renown = 0
	end
	field.Count = math.clamp(count(field.Count), CropConfig.StartSquares, CropConfig.MaxSquares)
	if not finite(field.SettledAt) then
		field.SettledAt = os.time()
	end
	local squares = {}
	if type(field.Squares) == "table" then
		for key, square in field.Squares do
			local index = tonumber(key)
			if
				index
				and index == math.floor(index)
				and index >= 1
				and index <= field.Count
				and type(square) == "table"
				and CropConfig.ById[square.Crop]
			then
				squares[tostring(index)] = {
					Crop = square.Crop,
					Grown = if finite(square.Grown) then math.max(0, square.Grown) else 0,
					N = count(square.N),
					Tried = if square.Tried == true then true else nil,
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
	garden.Renown = count(garden.Renown)

	-- field pets: an owned pet with the job's aptitude, not penned, on an owned square of its own, within the slots (in uid order);
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
			if
				type(square) == "number"
				and square == math.floor(square)
				and square >= 1
				and square <= field.Count
				and not taken[square]
				and entry.Job == "Tending"
				and profile.Pets[uid]
				and PetConfig.AptitudeLevel(profile.Pets[uid], entry.Job) > 0
				and not GardenConfig.IsPenned(profile, uid)
				and placed < garden.FieldPetSlots
			then
				pets[uid] = { Square = square, Job = entry.Job }
				taken[square] = true
				placed += 1
			end
		end
	end
	garden.FieldPets = pets
	return field
end
GardenField.FieldOf = fieldOf

-- [square] = Tending strength on that square: the strongest Tending pet that reaches it (the same job does not stack).
local function tendingStrength(profile, field)
	local best = {}
	for uid, entry in profile.Garden.FieldPets do
		local level = PetConfig.AptitudeLevel(profile.Pets[uid], "Tending")
		if entry.Job == "Tending" and level > 0 then
			for _, n in CropConfig.Reach(entry.Square, PetConfig.ReachShape(level), field.Count) do
				best[n] = math.max(best[n] or 0, PetConfig.Strength(level))
			end
		end
	end
	return best
end

-- The Tending roll of `player`'s planting number `n`, uniform in [0, 1): the same planting always rolls the same.
local function tendRoll(player: Player, n: number): number
	return Random.new(player.UserId * 7919 + n * 104729):NextNumber()
end

-- Adds the growth since SettledAt to every planted square and moves SettledAt to now: an absence (the join) at the offline
-- rate, anything else at the online rate. In an absence Tending pets harvest and replant the ripe crops in their reach.
-- Placed pets gain aptitude XP by the same weighted seconds. Returns whether a square's look, a crop or a pet's aptitude
-- level changed, and { [cropId] = harvests by pets } (nil when none).
local function settle(player: Player, profile, field, absence: boolean): (boolean, { [string]: number }?)
	local now = os.time()
	local elapsed = if field.SettledAt <= now then now - field.SettledAt else 0
	local growth = if absence then CropConfig.Growth(0, elapsed) else CropConfig.Growth(elapsed, 0)
	field.SettledAt = now
	if growth <= 0 then
		return false, nil
	end
	local garden = profile.Garden
	local strength = if absence then tendingStrength(profile, field) else {}
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
		square.Grown += growth
		local chance = strength[tonumber(key)]
		local entry = square
		while
			chance
			and entry
			and entry.Grown >= crop.growSeconds
			and not entry.Tried
			and CropConfig.SeedTotal(garden.Items) < CropConfig.BarnCapacity
		do
			if tendRoll(player, entry.N) >= chance then
				entry.Tried = true -- the pet did not get to it: it waits for the owner
				break
			end
			garden.Items[crop.id] = (garden.Items[crop.id] or 0) + 1
			garden.Renown += CropConfig.RenownPoints[crop.tier] or 0
			tended = tended or {}
			tended[crop.id] = (tended[crop.id] or 0) + 1
			local leftover = math.min(entry.Grown - crop.growSeconds, growth) -- growth from before this absence does not carry over
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
	for uid, entry in garden.FieldPets do
		local pet = profile.Pets[uid]
		if pet and PetConfig.GainAptitudeXp(pet, entry.Job, growth) > 0 then
			changed = true
		end
	end
	return changed, tended
end
GardenField.Settle = settle

-- What GardenRemotes.State.field holds for the owner's panel, or nil without a field.
GardenService.AddStateField("field", function(profile)
	local owner = nil
	for _, player in Players:GetPlayers() do
		if PlayerProfile.Get(player) == profile then
			owner = player
		end
	end
	local field = owner and fieldOf(owner, profile)
	if not field then
		return nil
	end
	local now = os.time()
	local squares = {}
	for key, square in field.Squares do
		local crop = CropConfig.ById[square.Crop]
		-- server time when the crop is ripe if the owner stays online (the panel's countdown)
		local left = math.max(0, crop.growSeconds - square.Grown)
		squares[key] = { crop = square.Crop, grown = math.floor(square.Grown), readyAt = now + math.ceil(left / CropConfig.OnlineRate) }
	end
	local garden = profile.Garden
	local pets = {} -- [square] = the pet working there
	for uid, entry in garden.FieldPets do
		local pet = profile.Pets[uid]
		local apt = pet.Apt[entry.Job]
		local need = if apt.L < PetConfig.AptitudeCap(pet.Kind) then PetConfig.AptitudeXpToNext(apt.L) else nil
		pets[tostring(entry.Square)] = {
			uid = uid,
			kind = pet.Kind,
			level = PetConfig.ClampLevel(pet.Level),
			job = entry.Job,
			apt = apt.L,
			xp = math.floor(apt.XP),
			next = need,
			reach = PetConfig.ReachShape(apt.L),
		}
	end
	return {
		count = field.Count,
		squares = squares,
		seeds = garden.Seeds,
		items = garden.Items,
		renown = garden.Renown,
		level = CropConfig.RenownLevel(garden.Renown),
		pets = pets,
		slots = garden.FieldPetSlots,
		slotPrice = CropConfig.PetSlotPrices[garden.FieldPetSlots + 1],
		notice = notices[owner],
	}
end)

-- The field part of `player`'s plot message ({ cols, rows, crops = 2 characters per square: crop letter + stage 1-3,
-- ".0" for an empty owned square, "#0" for a square not bought yet in the last row; pets = { "Kind:Level:uid:square:reach" } },
-- reach = PetConfig.ReachShape), or nil without a field.
function GardenField.PlotField(player: Player)
	local profile = PlayerProfile.Get(player)
	local field = profile and fieldOf(player, profile)
	if not field then
		return nil
	end
	local cols = CropConfig.Columns
	local rows = math.ceil(field.Count / cols)
	local cells = table.create(cols * rows)
	for n = 1, cols * rows do
		local square = field.Squares[tostring(n)]
		local crop = square and CropConfig.ById[square.Crop]
		cells[n] = if n > field.Count then "#0" elseif crop then crop.letter .. CropConfig.Stage(crop, square.Grown) else ".0"
	end
	local pets = {} -- "Kind:Level:uid:square:reach" per field pet, by square
	for uid, entry in profile.Garden.FieldPets do
		local pet = profile.Pets[uid]
		local reach = PetConfig.ReachShape(PetConfig.AptitudeLevel(pet, entry.Job))
		table.insert(pets, string.format("%s:%d:%s:%d:%d", pet.Kind, PetConfig.ClampLevel(pet.Level), uid, entry.Square, reach))
	end
	table.sort(pets, function(a, b)
		return tonumber(string.match(a, ":(%d+):%d+$")) < tonumber(string.match(b, ":(%d+):%d+$"))
	end)
	return { cols = cols, rows = rows, crops = table.concat(cells), pets = pets }
end

-- The caller's profile and field if they may use the field now (access, loaded, at their plot); otherwise rejects. The
-- field is settled (online) first, so every action sees the growth up to now.
local function usableField(player: Player, action: string)
	if not GardenConfig.HasFieldAccess(player.UserId) then
		reject(player, action, "locked")
		return nil, nil
	end
	local profile = GardenService.Usable(player, action)
	local field = profile and fieldOf(player, profile)
	if not field then
		return nil, nil
	end
	local _, tended = settle(player, profile, field, not settledOnline[player])
	if tended then
		notices[player] = notices[player] or {}
		notices[player].tended = tended
	end
	settledOnline[player] = true
	return profile, field
end

local function done(player: Player, action: string, detail: any)
	GardenService.PublishAll(player)
	GardenService.Succeed(player, action, detail)
	task.spawn(PlayerProfile.Save, player)
end

plantEvent.OnServerEvent:Connect(function(player, square, cropId)
	local crop = type(cropId) == "string" and CropConfig.ById[cropId]
	if not (GardenService.WholeNumber(square) and crop) or not GardenService.Allow(player) then
		return
	end
	local profile, field = usableField(player, "Plant")
	if not field then
		return
	end
	local garden = profile.Garden
	if square < 1 or square > field.Count then
		return reject(player, "Plant", "square")
	end
	if field.Squares[tostring(square)] then
		return reject(player, "Plant", "occupied")
	end
	if CropConfig.RenownLevel(garden.Renown) < crop.renown then
		return reject(player, "Plant", "renown")
	end
	if (garden.Seeds[crop.id] or 0) < 1 then
		return reject(player, "Plant", "seeds")
	end

	garden.Seeds[crop.id] -= 1
	if garden.Seeds[crop.id] == 0 then
		garden.Seeds[crop.id] = nil
	end
	field.Plantings += 1
	field.Squares[tostring(square)] = { Crop = crop.id, Grown = 0, N = field.Plantings }
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
	garden.Items[crop.id] = (garden.Items[crop.id] or 0) + 1
	local before = CropConfig.RenownLevel(garden.Renown)
	garden.Renown += CropConfig.RenownPoints[crop.tier] or 0
	local level = CropConfig.RenownLevel(garden.Renown)
	done(player, "Harvest", { square = square, crop = crop.id, level = level, levelUp = level > before })
end)

buySeedsEvent.OnServerEvent:Connect(function(player, cropId, amount)
	local crop = type(cropId) == "string" and CropConfig.ById[cropId]
	if not (crop and GardenService.WholeNumber(amount) and amount >= 1) or not GardenService.Allow(player) then
		return
	end
	local profile, field = usableField(player, "BuySeeds")
	if not field then
		return
	end
	local garden = profile.Garden
	if CropConfig.RenownLevel(garden.Renown) < crop.renown then
		return reject(player, "BuySeeds", "renown")
	end
	if CropConfig.SeedTotal(garden.Seeds) + amount > CropConfig.BarnCapacity then
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
	local profile, field = usableField(player, "Sell")
	if not field then
		return
	end
	local garden = profile.Garden
	if (garden.Items[crop.id] or 0) < amount then
		return reject(player, "Sell", "items")
	end

	garden.Items[crop.id] -= amount
	if garden.Items[crop.id] == 0 then
		garden.Items[crop.id] = nil
	end
	local paid = CoinRewards.Grant(player, crop.sale * amount, "crop") or 0 -- the pet bonus at sale time
	done(player, "Sell", { crop = crop.id, count = amount, paid = paid })
end)

buySquareEvent.OnServerEvent:Connect(function(player, expected)
	if not GardenService.WholeNumber(expected) or not GardenService.Allow(player) then
		return
	end
	local profile, field = usableField(player, "BuySquare")
	if not field then
		return
	end
	local expansion = CropConfig.NextExpansion(field.Count)
	if not expansion then
		return reject(player, "BuySquare", "maxed")
	end
	if expected ~= field.Count then
		return reject(player, "BuySquare", "stale") -- out-of-date panel, double click or forged request
	end
	if CropConfig.RenownLevel(profile.Garden.Renown) < expansion.renown then
		return reject(player, "BuySquare", "renown")
	end
	if profile.Coins < expansion.price then
		return reject(player, "BuySquare", "coins")
	end

	PlayerProfile.AddCoins(player, -expansion.price)
	field.Count += 1
	done(player, "BuySquare", field.Count)
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
	local profile, field = usableField(player, "PlacePet")
	if not field then
		return
	end
	local garden = profile.Garden
	local pet = profile.Pets[uid]
	if not pet then
		return
	end
	if square < 1 or square > field.Count then
		return reject(player, "PlacePet", "square")
	end
	if table.find(profile.EquippedPets, uid) then
		return reject(player, "PlacePet", "equipped")
	end
	if GardenConfig.IsPenned(profile, uid) then
		return reject(player, "PlacePet", "penned")
	end
	if PetConfig.AptitudeLevel(pet, "Tending") < 1 then
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
	garden.FieldPets[uid] = { Square = square, Job = "Tending" }
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
	local profile, field = usableField(player, "BuyPetSlot")
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

-- Pens -> field pet slots, once (E1b; ECONOMY → "Field-pet re-run" proposal 4). Runs after GardenService paid the pens'
-- production up to now (its join settle). Returns { pens, slots, refund, returned } or nil when already converted.
local function convert(player: Player, profile)
	local garden = profile.Garden
	if garden.Converted then
		return nil
	end
	local pens = math.clamp(count(garden.PenCount), 1, GardenConfig.MaxPens)
	local slots = CropConfig.PetSlotsFromPens[pens]
	local paid, value = 0, 0
	for n = 1, pens do
		paid += GardenConfig.PenPrices[n]
	end
	for n = 1, slots do
		value += CropConfig.PetSlotPrices[n]
	end
	local refund = math.max(0, paid - value)
	local returned = 0
	for _ in garden.Pens do
		returned += 1
	end
	garden.Pens = {}
	garden.PenCount = 1
	garden.Carry = 0
	garden.FieldPetSlots = math.max(slots, count(garden.FieldPetSlots))
	garden.Converted = true
	if refund > 0 then
		PlayerProfile.AddCoins(player, refund) -- money back for pens, not a reward: no pet multiplier
	end
	return { pens = pens, slots = slots, refund = refund, returned = returned }
end

-- Join (and admin reset): a new field for a player with access, the pens converted once, then the absence since SettledAt
-- counts as offline time (Tending pets work it).
GardenService.AddSetupHook(function(player)
	local profile = PlayerProfile.Get(player)
	local field = profile and fieldOf(player, profile)
	if not field then
		return
	end
	local converted = convert(player, profile)
	local _, tended = settle(player, profile, field, not settledOnline[player])
	settledOnline[player] = true
	if converted or tended then
		notices[player] = notices[player] or {}
		notices[player].converted = converted or notices[player].converted
		notices[player].tended = tended or notices[player].tended
	end
	GardenService.PublishAll(player)
	if converted then
		task.spawn(PlayerProfile.Save, player)
	end
end)

-- Leave and shutdown: the time since the last settle was online.
PlayerProfile.OnLeaving(function(player, profile)
	local field = profile and settledOnline[player] and fieldOf(player, profile)
	if field then
		settle(player, profile, field, false)
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
			local field = profile and settledOnline[player] and fieldOf(player, profile)
			if field and settle(player, profile, field, false) then
				GardenService.PublishAll(player)
			end
		end
	end
end)

return GardenField
