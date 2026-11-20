-- HarvestHall (SH): the week's biggest crop of every kind and the all-time records, shared by every server (docs/GDD.md §7.9 →
-- Harvest Hall). Server-only. Rules and the board shape: HallConfig.
-- GardenField calls HarvestHall.Harvested for every crop that goes into a barn (by hand, a Tending pet, the Shears' extra). A size
-- better than the player's own of the week goes into profile Garden.WeekBest = { Week, [cropId] = factor } (mirrored as the player
-- attribute HallConfig.WeekBestAttribute); one that would enter the week's or the all-time board (as this server knows them) is
-- queued and written with one UpdateAsync per key at most every FlushSeconds (+ jitter). Every server reads both keys every
-- RefreshSeconds and puts the boards, its queue on top, into ReplicatedStorage.HarvestHall's attribute Board (JSON:
-- { week, endsAt, crops = { [cropId] = { { u, n, f, t }, … } }, best = { [cropId] = { u, n, f, t } } }); HallClient draws the Hall.
-- A harvest that takes a week's #1 and is Big or Giant fires HarvestHall.Toast(name, cropId, factor) to every client of this
-- server (at most one per ToastGap).
-- Ribbons: a week in which the player harvested (WeekBest.Week) goes into Garden.RibbonPending when the week changes; once that week
-- is over (+ SettleSeconds) its board is read and every crop the player leads adds Garden.Ribbons[cropId] += 1 (each week once).
-- The session's first check is kept for the "While you were away" ledger (JoinRibbons, E5b; GardenField's notice).
-- Studio tests (ServerStorage attributes, ignored outside Studio): HallTest = true uses the keys "test_…" (never the live Hall),
-- HallWeekShift = n moves the week number; HallWrites counts the UpdateAsync calls of this server.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local HallConfig = require(ReplicatedStorage.HallConfig)
local CropConfig = require(ReplicatedStorage.CropConfig)
local Num = require(ReplicatedStorage.Num)
local PlayerProfile = require(ServerScriptService.PlayerProfile)
local DataStoreUtil = require(ServerScriptService.DataStoreUtil)
local Remotes = require(ServerScriptService.Remotes)
local Telemetry = require(ServerScriptService.Telemetry)
local GardenService = require(ServerScriptService.GardenService)

local TICK = 5 -- seconds between checks of the week, the refresh and the flush timers
local MAX_PENDING_WEEKS = 8

local store = DataStoreService:GetDataStore(HallConfig.Store)
local studio = RunService:IsStudio()
local withRetries = DataStoreUtil.WithRetries

local folder = Instance.new("Folder")
folder.Name = HallConfig.Folder
local toastEvent = Remotes.Add(folder, "Toast") -- server → client: (name, cropId, factor)
folder.Parent = ReplicatedStorage

local boards = {} -- [key] = board as last read or written (HallConfig.Merge shape)
local pending = {} -- [key] = { entry, … } queued, not written yet
local oldWeeks = {} -- [key] = board of a finished week (ribbons), read once per server
local lastToast = -math.huge
local published = nil -- the Board JSON last set

local HarvestHall = {}

local function testMode(): boolean
	return studio and ServerStorage:GetAttribute("HallTest") == true
end

local function shift(): number
	local value = if studio then ServerStorage:GetAttribute("HallWeekShift") else nil
	return if Num.Finite(value) then math.floor(value) else 0
end

local function currentWeek(): number
	return HallConfig.Week(os.time(), shift())
end

local function weekKey(week: number?): string
	return HallConfig.Key("week", week or currentWeek(), testMode())
end

local function allKey(): string
	return HallConfig.Key("alltime", nil, testMode())
end

-- The board of `key` as this server shows it: the last read with its queue on top.
local function shown(key: string)
	return HallConfig.Merge(boards[key], pending[key])
end

local function publish()
	local week = currentWeek()
	local weekBoard, allBoard = shown(weekKey(week)), shown(allKey())
	local best = {}
	for cropId, list in allBoard.crops do
		best[cropId] = list[1]
	end
	local json = HttpService:JSONEncode({
		week = week,
		endsAt = HallConfig.WeekEnds(week, shift()),
		crops = weekBoard.crops,
		best = best,
	})
	if json ~= published then
		published = json
		folder:SetAttribute("Board", json)
	end
end

local function countWrite()
	if studio then
		ServerStorage:SetAttribute("HallWrites", (ServerStorage:GetAttribute("HallWrites") or 0) + 1)
	end
end

-- Writes every queued entry: one UpdateAsync per key (the merge keeps what other servers wrote). A failed key keeps its queue.
local function flush()
	local queued = pending
	pending = {}
	for key, entries in queued do
		countWrite()
		local ok, result = withRetries(function()
			return store:UpdateAsync(key, function(old)
				return HallConfig.Merge(old, entries)
			end)
		end)
		if ok then
			boards[key] = HallConfig.Merge(result, nil)
		else
			warn("HarvestHall: writing " .. key .. " failed: " .. tostring(result))
			pending[key] = pending[key] or {}
			for _, entry in entries do
				table.insert(pending[key], entry)
			end
		end
	end
	publish()
end

-- Reads the week's and the all-time board.
local function refresh()
	local keys = { weekKey(), allKey() }
	for _, key in keys do
		local ok, value = withRetries(function()
			return store:GetAsync(key)
		end)
		if ok then
			boards[key] = HallConfig.Merge(value, nil)
		else
			warn("HarvestHall: reading " .. key .. " failed: " .. tostring(value))
		end
	end
	for key in boards do -- forget last week's (and test / live) boards no longer shown
		if key ~= keys[1] and key ~= keys[2] and not pending[key] then
			boards[key] = nil
		end
	end
	publish()
end

-- Profile fields of the Hall, made usable (an old or hand-edited record may lack them).
local function sanitize(garden)
	if type(garden.WeekBest) ~= "table" or not Num.Finite(garden.WeekBest.Week) then
		garden.WeekBest = { Week = currentWeek() }
	end
	if type(garden.Ribbons) ~= "table" then
		garden.Ribbons = {}
	end
	for id, n in garden.Ribbons do
		if not (CropConfig.ById[id] and Num.Finite(n) and n >= 1) then
			garden.Ribbons[id] = nil
		end
	end
	if type(garden.RibbonPending) ~= "table" then
		garden.RibbonPending = {}
	end
end

local function mirror(player: Player, garden)
	local best = {}
	for id, f in garden.WeekBest do
		if id ~= "Week" and CropConfig.ById[id] and Num.Finite(f) then
			best[id] = f
		end
	end
	player:SetAttribute(HallConfig.WeekBestAttribute, HttpService:JSONEncode(best))
end

-- The board of the finished week `week` (cached per server), or nil when the read failed.
local function oldWeek(week: number)
	local key = weekKey(week)
	if oldWeeks[key] then
		return oldWeeks[key]
	end
	local ok, value = withRetries(function()
		return store:GetAsync(key)
	end)
	if not ok then
		warn("HarvestHall: reading " .. key .. " failed: " .. tostring(value))
		return nil
	end
	oldWeeks[key] = HallConfig.Merge(value, nil)
	return oldWeeks[key]
end

local checking = {} -- [Player] = true while checkRibbons runs
local joinRibbons = {} -- [Player] = { [cropId] = n } the ribbons the session's first finished check found (E5b ledger)

-- Ribbons of the finished weeks in Garden.RibbonPending (each read once it is settled).
local function checkRibbons(player: Player)
	if checking[player] then
		return
	end
	checking[player] = true
	local profile = PlayerProfile.Get(player)
	local garden = profile and profile.Garden
	local gained = 0
	local won = {}
	if type(garden) == "table" and type(garden.RibbonPending) == "table" then
		local now = os.time()
		for i = #garden.RibbonPending, 1, -1 do
			local week = garden.RibbonPending[i]
			if not Num.Finite(week) then
				table.remove(garden.RibbonPending, i)
			elseif now >= HallConfig.WeekEnds(week, shift()) + HallConfig.SettleSeconds then
				local board = oldWeek(week)
				local at = board and table.find(garden.RibbonPending, week) -- the list may have moved while reading
				if at then
					table.remove(garden.RibbonPending, at)
					for cropId, list in board.crops do
						if list[1] and list[1].u == player.UserId and CropConfig.ById[cropId] then
							garden.Ribbons[cropId] = (garden.Ribbons[cropId] or 0) + 1
							won[cropId] = (won[cropId] or 0) + 1
							gained += 1
						end
					end
				end
			end
		end
	end
	checking[player] = nil
	local first = joinRibbons[player] == nil and player.Parent ~= nil
	if first then
		joinRibbons[player] = won
	end
	if gained > 0 and player.Parent then
		PlayerProfile.Save(player)
	end
	if (gained > 0 or first) and player.Parent then
		GardenService.PublishAll(player) -- the plot sign shows the ribbons (GardenPlotFeed); a waiting ledger gets them
	end
end

-- Starts a new week on the profile when WeekBest belongs to an older one (that week waits in RibbonPending if it holds any size).
local function rollOver(player: Player, garden)
	sanitize(garden)
	local week = currentWeek()
	local best = garden.WeekBest
	if best.Week == week then
		return
	end
	if best.Week < week then
		local any = false
		for id in best do
			if id ~= "Week" then
				any = true
			end
		end
		if any and not table.find(garden.RibbonPending, best.Week) then
			table.insert(garden.RibbonPending, best.Week)
			while #garden.RibbonPending > MAX_PENDING_WEEKS do
				table.remove(garden.RibbonPending, 1)
			end
		end
	end
	garden.WeekBest = { Week = week }
	mirror(player, garden)
	task.spawn(checkRibbons, player)
end

-- Queues `entry` for `key` when it would change that board; returns its rank there (nil = it does not get on it).
local function offer(key: string, entry): number?
	local before = shown(key)
	local own = HallConfig.Rank(before, entry.crop, entry.u)
	if own and before.crops[entry.crop][own].f >= entry.f then
		return nil
	end
	local rank = HallConfig.Rank(HallConfig.Merge(before, { entry }), entry.crop, entry.u)
	if not rank then
		return nil
	end
	pending[key] = pending[key] or {}
	table.insert(pending[key], entry)
	return rank
end

-- GardenField: `crop` of size `factor` went into `player`'s barn (with the Garden's points `pts` of that crop, for the Big / Giant label).
function HarvestHall.Harvested(player: Player, crop, factor: number, pts: any?)
	local profile = PlayerProfile.Get(player)
	if not (profile and PlayerProfile.CanSave(player) and Num.Finite(factor) and factor > 0) then
		return
	end
	local garden = profile.Garden
	rollOver(player, garden)
	local f = math.floor(factor * 10000 + 0.5) / 10000
	if f > (garden.WeekBest[crop.id] or 0) then
		garden.WeekBest[crop.id] = f
		mirror(player, garden)
	end
	local entry = { crop = crop.id, u = player.UserId, n = player.Name, f = f, t = os.time() }
	local rank = offer(weekKey(), table.clone(entry))
	local allRank = offer(allKey(), table.clone(entry))
	if not (rank or allRank) then
		return
	end
	if rank then
		Telemetry.HallEntry(player, crop.id, rank)
	end
	if rank == 1 and CropConfig.SizeLabel(f, pts) and os.clock() - lastToast >= HallConfig.ToastGap then
		lastToast = os.clock()
		toastEvent:FireAllClients(player.Name, crop.id, f)
	end
	publish()
end

-- The ribbons ({ [cropId] = n }) the session's first ribbon check found (the E5b ledger), or nil while it runs.
function HarvestHall.JoinRibbons(player: Player)
	return joinRibbons[player]
end

-- The player's ribbons in all (the plot sign).
function HarvestHall.RibbonCount(garden): number
	local total = 0
	if type(garden) == "table" and type(garden.Ribbons) == "table" then
		for _, n in garden.Ribbons do
			if Num.Finite(n) then
				total += math.floor(n)
			end
		end
	end
	return total
end

PlayerProfile.OnReady(function(player, profile)
	if type(profile.Garden) ~= "table" then
		return
	end
	rollOver(player, profile.Garden)
	mirror(player, profile.Garden)
	task.spawn(checkRibbons, player)
end)

Players.PlayerRemoving:Connect(function(player)
	checking[player] = nil
	joinRibbons[player] = nil
end)

-- The week, the reads and the writes.
task.spawn(function()
	local lastWeek = nil
	local nextRefresh, nextFlush = 0, os.clock() + HallConfig.FlushSeconds + math.random() * HallConfig.FlushJitter
	while true do
		local key = weekKey()
		if key ~= lastWeek then
			lastWeek = key
			nextRefresh = 0
			for _, player in Players:GetPlayers() do
				local profile = PlayerProfile.Get(player)
				if profile and type(profile.Garden) == "table" then
					rollOver(player, profile.Garden)
				end
			end
		end
		if os.clock() >= nextFlush then
			if next(pending) ~= nil then
				flush()
			end
			nextFlush = os.clock() + HallConfig.FlushSeconds + math.random() * HallConfig.FlushJitter
		end
		if os.clock() >= nextRefresh then
			refresh()
			nextRefresh = os.clock() + HallConfig.RefreshSeconds
		end
		task.wait(TICK)
	end
end)

game:BindToClose(function()
	if next(pending) ~= nil then
		flush()
	end
end)

return HarvestHall
