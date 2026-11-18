-- HallConfig: the Harvest Hall's rules (SH, docs/GDD.md §7.9 → Harvest Hall). Shared, pure.
-- A board is { crops = { [cropId] = { { u = UserId, n = name, f = size factor, t = os.time() of the harvest }, … } } }: per crop at
-- most Rows entries, one per player, the bigger factor first, the earlier harvest on a tie. The week's board and the all-time board
-- are plain DataStore values of the same shape (DataStore `Store`, keys from HallConfig.Key) merged with UpdateAsync.
--   HallConfig.Week(now, shift?)       the week number of `now`: whole weeks since Monday 1970-01-05 00:00 UTC (+ `shift`, Studio tests)
--   HallConfig.WeekEnds(week, shift?)  os.time() when week `week` ends
--   HallConfig.Key(kind, week?, test?) "week_<n>" / "alltime" ("test_" in front for Studio tests)
--   HallConfig.Merge(board, entries)   a new board: `board` (any stored value, sanitized) with `entries` merged in
--   HallConfig.Rank(board, cropId, userId)  the player's place (1..Rows) on that crop's list, or nil

local HallConfig = {}

HallConfig.Store = "HarvestHall" -- DataStore name
HallConfig.Rows = 3 -- entries kept per crop, on the week's and on the all-time board
HallConfig.RefreshSeconds = 120 -- every server re-reads both boards this often
HallConfig.FlushSeconds = 60 -- a server writes its queued entries at most this often (+ up to FlushJitter)
HallConfig.FlushJitter = 30
HallConfig.ToastGap = 60 -- seconds between two Hall toasts on one server
HallConfig.SettleSeconds = 300 -- a finished week's board is read for ribbons only this long after its end (late flushes)
HallConfig.WeekSeconds = 7 * 86400
HallConfig.Epoch = 4 * 86400 -- Monday 1970-01-05 00:00 UTC

HallConfig.Folder = "HarvestHall" -- ReplicatedStorage folder: attribute Board (JSON), remote Toast
HallConfig.SceneFolder = "HarvestHall" -- Workspace.StartLocation.HarvestHall
-- a pedestal Model, attribute Crop, children Top (the plant stands on it) and Plaque; shown only for a crop with plant art that is not
-- a draft (PlantGrowth.Supports)
HallConfig.PedestalTag = "HallPedestal"
HallConfig.WeekBestAttribute = "HallWeekBest" -- player attribute: JSON { [cropId] = factor } of the week's own bests

function HallConfig.Week(now: number, shift: number?): number
	return math.floor((now - HallConfig.Epoch) / HallConfig.WeekSeconds) + (shift or 0)
end

function HallConfig.WeekEnds(week: number, shift: number?): number
	return HallConfig.Epoch + (week - (shift or 0) + 1) * HallConfig.WeekSeconds
end

function HallConfig.Key(kind: string, week: number?, test: boolean?): string
	local key = if kind == "week" then "week_" .. tostring(week) else "alltime"
	return if test then "test_" .. key else key
end

local function finite(x: any): boolean
	return type(x) == "number" and x == x and x > -math.huge and x < math.huge
end

-- A clean entry or nil.
local function cleanEntry(entry: any)
	if type(entry) ~= "table" then
		return nil
	end
	local u, f, t = entry.u, entry.f, entry.t
	if not (finite(u) and u == math.floor(u) and finite(f) and f > 0 and finite(t)) then
		return nil
	end
	return { u = u, n = if type(entry.n) == "string" then string.sub(entry.n, 1, 40) else tostring(u), f = f, t = t }
end

-- a before b: the bigger factor, then the earlier harvest, then the lower UserId (a fixed order)
local function before(a, b): boolean
	if a.f ~= b.f then
		return a.f > b.f
	end
	if a.t ~= b.t then
		return a.t < b.t
	end
	return a.u < b.u
end

-- `entries` = { { crop = cropId, u, n, f, t }, … }
function HallConfig.Merge(board: any, entries: { any }?)
	local lists = {} -- [cropId] = { [UserId] = entry }
	local function add(cropId: any, raw: any)
		local entry = type(cropId) == "string" and cleanEntry(raw)
		if not entry then
			return
		end
		lists[cropId] = lists[cropId] or {}
		local own = lists[cropId][entry.u]
		if not own or before(entry, own) then
			lists[cropId][entry.u] = entry
		elseif own.f == entry.f and own.t == entry.t then
			own.n = entry.n -- the same harvest: keep the newest name
		end
	end
	if type(board) == "table" and type(board.crops) == "table" then
		for cropId, list in board.crops do
			if type(list) == "table" then
				for _, raw in list do
					add(cropId, raw)
				end
			end
		end
	end
	for _, raw in entries or {} do
		if type(raw) == "table" then
			add(raw.crop, raw)
		end
	end
	local crops = {}
	for cropId, byUser in lists do
		local list = {}
		for _, entry in byUser do
			table.insert(list, entry)
		end
		table.sort(list, before)
		for i = #list, HallConfig.Rows + 1, -1 do
			list[i] = nil
		end
		crops[cropId] = list
	end
	return { crops = crops }
end

function HallConfig.Rank(board: any, cropId: string, userId: number): number?
	local list = type(board) == "table" and type(board.crops) == "table" and board.crops[cropId]
	if type(list) ~= "table" then
		return nil
	end
	for i, entry in list do
		if type(entry) == "table" and entry.u == userId then
			return i
		end
	end
	return nil
end

return HallConfig
