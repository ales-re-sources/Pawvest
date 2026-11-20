-- GardenRequests (E5a): the daily tracked requests, "grow 6 Tomatoes" (docs/GDD.md §7.9 → Requests; rules CropConfig.Requests).
-- Server-only; GardenField calls it (the field owns the barn and the harvests).
-- Profile: Garden.Requests = { Day = the UTC day the board was last filled, Slots = { { Crop, Need, Have, At, Done? } } } (At =
-- os.time() the slot was filled, for telemetry); Garden.Income = { Day, Today, Prev } (Coins from crop sales and request bonuses
-- on UTC day Day and the day before it, the size of new requests).
--   * Clean(garden)            load: drops a slot whose crop is gone or locked, clamps Have to 0..Need, rolls Income to today.
--   * Fill(player, garden)     on every field read: a new UTC day (or a board never filled) keeps the unfinished slots and fills
--                              the rest, once 2 crops are eligible (CropConfig.RequestCrops); the same day and board give the
--                              same crops (seeded by user, day and slot). Returns true when it changed the board.
--   * Track(player, garden, crop, n)  n crops of `crop` went into the barn (any harvest): the first open slot of that crop counts
--                              them; a finished one pays its bonus (CoinRewards.Grant), rolls the drop and answers on
--                              GardenRemotes.Result ("Request", true, { crop, need, coins, drop? = { seed = crop id } | { egg = id } }).
--   * Earned(garden, coins)    a sale or a bonus paid `coins` (today's income).
-- Studio test hook (never outside Studio): ServerStorage.RequestsTest, a BindableFunction made at runtime, works on the first player:
-- Invoke("get") -> { requests, income, unlocked, coins, mult }; Invoke("set", patch) puts patch.Requests / Income / Unlocked into the
-- garden (a field left out stays), then Clean + Fill and publishes; Invoke("track", cropId, n) counts n harvests of the crop.
--   * State(player, garden)    GardenRemotes.State field.requests = { open, endsAt, slots = { { crop, need, have, done, bonus } } }
--                              (bonus = the Coins it pays now, pet multiplier included).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CropConfig = require(ReplicatedStorage.CropConfig)
local StageConfig = require(ReplicatedStorage.StageConfig)
local Num = require(ReplicatedStorage.Num)
local PlayerProfile = require(ServerScriptService.PlayerProfile)
local CoinRewards = require(ServerScriptService.CoinRewards)
local PetService = require(ServerScriptService.PetService)
local GardenService = require(ServerScriptService.GardenService)
local Telemetry = require(ServerScriptService.Telemetry)

local rules = CropConfig.Requests

local GardenRequests = {}

local function today(): number
	return CropConfig.CartDay(os.time())
end

local function whole(value: any): number
	return if Num.Finite(value) and value > 0 then math.floor(value) else 0
end

-- The barn's capacity (seeds; the crops a Tending pet may store) of `garden`.
local function barnOf(garden): number
	local field = type(garden.Field) == "table" and garden.Field
	return CropConfig.BarnFor(CropConfig.UpgradeLevel(field and field.Upgrades, "Barn"))
end

local function pointsOf(garden, crop)
	local entry = type(garden.Crops) == "table" and garden.Crops[crop.id]
	return entry and entry.Pts
end

-- Income rolled to today: Prev = the day before's, Today = so far today.
local function incomeOf(garden)
	local income = garden.Income
	local day = today()
	if type(income) ~= "table" or not Num.Finite(income.Day) then
		income = { Day = day, Today = 0, Prev = 0 }
	elseif income.Day ~= day then
		income = { Day = day, Today = 0, Prev = if income.Day == day - 1 then whole(income.Today) else 0 }
	else
		income = { Day = day, Today = whole(income.Today), Prev = whole(income.Prev) }
	end
	garden.Income = income
	return income
end

function GardenRequests.Clean(garden)
	incomeOf(garden)
	local stored = type(garden.Requests) == "table" and garden.Requests
	local slots = {}
	if stored and type(stored.Slots) == "table" then
		for _, slot in stored.Slots do
			local crop = type(slot) == "table" and type(slot.Crop) == "string" and CropConfig.ById[slot.Crop]
			local need = crop and whole(slot.Need)
			if
				crop
				and not crop.rare
				and CropConfig.IsUnlocked(garden.Unlocked, crop.id)
				and need >= 1
				and #slots < rules.Slots
			then
				local done = slot.Done == true
				table.insert(slots, {
					Crop = crop.id,
					Need = need,
					Have = if done then need else math.min(whole(slot.Have), need),
					At = whole(slot.At),
					Done = if done then true else nil,
				})
			end
		end
	end
	garden.Requests = { Day = if stored and Num.Finite(stored.Day) then stored.Day else nil, Slots = slots }
end

-- How many `crop` a new request asks for (D3): Share of a day's income in that crop's sales (with the pet multiplier).
local function needOf(player: Player, garden, crop): number
	local income = incomeOf(garden)
	local daily = math.max(income.Prev, income.Today, rules.MinIncome)
	local sale = math.max(1, CropConfig.SaleValue(crop, 1, pointsOf(garden, crop)) * CoinRewards.Multiplier(player))
	local cap = math.max(rules.MinNeed, math.floor(barnOf(garden) / 2))
	return math.clamp(math.floor(rules.Share * daily / sale + 0.5), rules.MinNeed, cap)
end

function GardenRequests.Fill(player: Player, garden): boolean
	local board = garden.Requests
	local day = today()
	if board.Day == day and #board.Slots >= rules.Slots then
		return false
	end
	local eligible = CropConfig.RequestCrops(garden.Unlocked)
	if #eligible < 2 then
		return false
	end
	local newDay = board.Day ~= day
	local slots = {}
	for _, slot in board.Slots do
		if not (newDay and slot.Done) then -- an unfinished request stays; a finished one waits for the next day
			table.insert(slots, slot)
		end
	end
	local changed = newDay or #slots ~= #board.Slots
	local now = os.time()
	for index = #slots + 1, rules.Slots do
		local taken = {}
		for _, slot in slots do
			taken[slot.Crop] = true
		end
		local choices = {}
		for _, crop in eligible do
			if not taken[crop.id] then
				table.insert(choices, crop)
			end
		end
		if #choices == 0 then
			choices = eligible
		end
		local rng = Random.new(player.UserId * 7919 + day * 104729 + index * 15485863)
		local crop = choices[rng:NextInteger(1, #choices)]
		table.insert(slots, { Crop = crop.id, Need = needOf(player, garden, crop), Have = 0, At = now })
		changed = true
	end
	board.Slots = slots
	board.Day = day
	return changed
end

function GardenRequests.Earned(garden, coins: number)
	if Num.Finite(coins) and coins > 0 then
		local income = incomeOf(garden)
		income.Today += math.floor(coins)
	end
end

-- The highest world in which the player finished a stage (at least 1): the world of a dropped rare seed.
local function dropWorld(profile): number
	local world = 1
	if type(profile.BestTimes) == "table" then
		for key in profile.BestTimes do
			local stage = StageConfig.ByKey[key]
			if stage and stage.world > world and CropConfig.RareOfWorld(stage.world) then
				world = stage.world
			end
		end
	end
	return world
end

local function finish(player: Player, garden, slot, index: number)
	slot.Done = true
	local crop = CropConfig.ById[slot.Crop]
	local base = rules.Bonus * slot.Need * CropConfig.SaleValue(crop, 1, pointsOf(garden, crop))
	local coins = CoinRewards.Grant(player, base, "request") or 0
	GardenRequests.Earned(garden, coins)
	local profile = PlayerProfile.Get(player)
	local rng = Random.new(player.UserId * 31 + garden.Requests.Day * 977 + index * 7 + slot.At)
	local drop = nil
	if profile and rng:NextNumber() < rules.DropChance then
		if rng:NextNumber() < 0.5 then
			local seed = CropConfig.RareOfWorld(dropWorld(profile))
			if seed then
				garden.Seeds[seed.id] = (garden.Seeds[seed.id] or 0) + 1 -- an earned seed goes past the barn's limit
				drop = { seed = seed.id }
			end
		elseif PetService.GrantFreeEgg(player, rules.DropEgg) then
			drop = { egg = rules.DropEgg }
		end
	end
	Telemetry.RequestDone(player, crop.id, index, (os.time() - slot.At) / 60, coins, if profile then profile.Coins else 0)
	GardenService.Succeed(player, "Request", { crop = crop.id, need = slot.Need, coins = coins, drop = drop }) -- GardenRemotes.Result
	task.spawn(PlayerProfile.Save, player)
end

function GardenRequests.Track(player: Player, garden, crop, n: number)
	local board = garden.Requests
	if crop.rare or type(board) ~= "table" or n <= 0 then
		return
	end
	for index, slot in board.Slots do
		if n <= 0 then
			break
		end
		if slot.Crop == crop.id and not slot.Done then
			local use = math.min(n, slot.Need - slot.Have)
			slot.Have += use
			n -= use
			if slot.Have >= slot.Need then
				finish(player, garden, slot, index)
			end
		end
	end
end

function GardenRequests.State(player: Player, garden)
	local mult = CoinRewards.Multiplier(player)
	local board = garden.Requests
	local slots = {}
	for _, slot in board.Slots do
		local crop = CropConfig.ById[slot.Crop]
		table.insert(slots, {
			crop = slot.Crop,
			need = slot.Need,
			have = slot.Have,
			done = slot.Done == true,
			bonus = math.floor(rules.Bonus * slot.Need * CropConfig.SaleValue(crop, 1, pointsOf(garden, crop)) * mult + 0.5 + 1e-9),
		})
	end
	return {
		open = #slots > 0,
		endsAt = (today() + 1) * CropConfig.DaySeconds,
		slots = slots,
	}
end

if game:GetService("RunService"):IsStudio() then
	local ServerStorage = game:GetService("ServerStorage")
	local hook = Instance.new("BindableFunction")
	hook.Name = "RequestsTest"
	hook.OnInvoke = function(command: string, a: any, b: any)
		local player = game:GetService("Players"):GetPlayers()[1]
		local profile = player and PlayerProfile.Get(player)
		local garden = profile and profile.Garden
		if type(garden) ~= "table" then
			return nil
		end
		if command == "set" then
			for _, name in { "Requests", "Income", "Unlocked" } do
				if a[name] ~= nil then
					garden[name] = a[name]
				end
			end
			GardenRequests.Clean(garden)
			GardenRequests.Fill(player, garden)
			GardenService.PublishAll(player)
		elseif command == "track" then
			GardenRequests.Track(player, garden, CropConfig.ById[a], b)
			GardenService.PublishAll(player)
		end
		return {
			requests = garden.Requests,
			income = garden.Income,
			unlocked = garden.Unlocked,
			coins = profile.Coins,
			mult = CoinRewards.Multiplier(player),
			barn = barnOf(garden),
			seeds = garden.Seeds,
			freeEggs = profile.FreeEggs,
		}
	end
	hook.Parent = ServerStorage
end

return GardenRequests
