-- GardenField: the crop field behind the player's plot (E1a2, docs/ROADMAP.md → E1a2, docs/EXPANSION.md §5). Server-only.
-- Open only to players with GardenConfig.HasFieldAccess (admins and Studio test users until E1 ships): for anyone else no
-- Field data is written, every remote is rejected ("locked") and the plot messages carry no field (GardenPlotFeed).
-- State lives in PlayerProfile.Garden: Field = { Count, Squares["1".."12"] = { Crop, Grown }, SettledAt }, Seeds[crop],
-- Items[crop], Renown (points; the level is derived, CropConfig.RenownLevel). Grown = growth seconds earned, SettledAt = the
-- server os.time() up to which growth was counted. Growth is settled on join (the time since SettledAt is an absence:
-- CropConfig.OfflineRate, capped), and while online (OnlineRate) every SettleSeconds, before every field action and on leave.
-- Ripe crops wait. The client only names a square, a crop or a count: prices, times and Renown come from here.
-- Remotes (in GardenRemotes): Plant(square, crop), Harvest(square), BuySeeds(crop, count), Sell(crop, count),
-- BuySquare(expectedCount) (client → server); answers on GardenRemotes.Result; GardenRemotes.State.field (the owner's panel).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GardenConfig = require(ReplicatedStorage.GardenConfig)
local CropConfig = require(ReplicatedStorage.CropConfig)
local PlayerProfile = require(ServerScriptService.PlayerProfile)
local CoinRewards = require(ServerScriptService.CoinRewards)
local GardenService = require(ServerScriptService.GardenService)

local plantEvent = GardenService.Remote("Plant") -- client → server: (square: number, crop: string)
local harvestEvent = GardenService.Remote("Harvest") -- client → server: (square: number)
local buySeedsEvent = GardenService.Remote("BuySeeds") -- client → server: (crop: string, count: number)
local sellEvent = GardenService.Remote("Sell") -- client → server: (crop: string, count: number)
local buySquareEvent = GardenService.Remote("BuySquare") -- client → server: (expectedCount: number)

local reject = GardenService.Reject

local settledOnline = {} -- [Player] = true once the join settle ran (later settles count as online time)

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
				squares[tostring(index)] = { Crop = square.Crop, Grown = if finite(square.Grown) then math.max(0, square.Grown) else 0 }
			end
		end
	end
	field.Squares = squares
	garden.Seeds = cleanStock(garden.Seeds)
	garden.Items = cleanStock(garden.Items)
	garden.Renown = count(garden.Renown)
	return field
end
GardenField.FieldOf = fieldOf

-- Adds the growth since SettledAt to every planted square and moves SettledAt to now: an absence (the join) at the offline
-- rate, anything else at the online rate. Returns true when a square's look stage changed.
local function settle(player: Player, profile, field, absence: boolean): boolean
	local now = os.time()
	local elapsed = if field.SettledAt <= now then now - field.SettledAt else 0
	local growth = if absence then CropConfig.Growth(0, elapsed) else CropConfig.Growth(elapsed, 0)
	field.SettledAt = now
	local changed = false
	if growth > 0 then
		for _, square in field.Squares do
			local crop = CropConfig.ById[square.Crop]
			local before = CropConfig.Stage(crop, square.Grown)
			square.Grown += growth
			changed = changed or CropConfig.Stage(crop, square.Grown) ~= before
		end
	end
	return changed
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
	return {
		count = field.Count,
		squares = squares,
		seeds = garden.Seeds,
		items = garden.Items,
		renown = garden.Renown,
		level = CropConfig.RenownLevel(garden.Renown),
	}
end)

-- The field part of `player`'s plot message ({ cols, rows, crops = 2 characters per square: crop letter + stage 1-3,
-- ".0" for an empty owned square, "#0" for a square not bought yet in the last row }), or nil without a field.
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
	return { cols = cols, rows = rows, crops = table.concat(cells) }
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
	settle(player, profile, field, not settledOnline[player])
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
	field.Squares[tostring(square)] = { Crop = crop.id, Grown = 0 }
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

-- Join (and admin reset): a new field for a player with access, then the absence since SettledAt counts as offline time.
GardenService.AddSetupHook(function(player)
	local profile = PlayerProfile.Get(player)
	local field = profile and fieldOf(player, profile)
	if not field then
		return
	end
	settle(player, profile, field, true)
	settledOnline[player] = true
	GardenService.PublishAll(player)
end)

-- Leave and shutdown: the time since the last settle was online.
PlayerProfile.OnLeaving(function(player, profile)
	local field = profile and settledOnline[player] and fieldOf(player, profile)
	if field then
		settle(player, profile, field, false)
	end
	settledOnline[player] = nil
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
