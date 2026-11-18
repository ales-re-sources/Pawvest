-- FeedbackService (FB, docs/GDD.md → Player feedback): stage ratings and the feedback box, both only for us. Server-only.
-- Remotes (ReplicatedStorage.FeedbackRemotes, FeedbackConfig.Folder):
--   Rate(stageKey, rating)    client → server: 1 = 👍, -1 = 👎 on the stage results popup; only a stage the player has finished
--                             (a stored best time). Kept in profile StageRatings[stageKey]; the per-stage counts (DataStore
--                             StageRatings, key "counts" = { [stageKey] = { up, down } }) take the change as a delta, queued and
--                             written with one UpdateAsync every FLUSH_SECONDS (+ jitter) and in BindToClose. Answer: ("rate", ok, …).
--   Send(category, text)      client → server: a feedback message from the Settings box; a known category, 1..MaxLength characters,
--                             PerDay a UTC day (profile FeedbackToday = { Day, Count }); filtered before it is stored in the
--                             DataStore PlayerFeedback (key "<os.time()>_<UserId>" = { u, t, cat, area, text, lang, ver }).
--                             Answer: ("send", true, left today) or ("send", false, reason).
--   Result                    server → client: (key, ok, detail / reason), Remotes.Results
-- Reasons: loading, stage (not finished / unknown), value, wait (cooldown), category, empty, long, daily, filter, failed.
-- In Studio the keys get FeedbackConfig.StudioPrefix (tests never touch the live data). Studio does not filter text.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local TextService = game:GetService("TextService")

local FeedbackConfig = require(ReplicatedStorage.FeedbackConfig)
local StageConfig = require(ReplicatedStorage.StageConfig)
local TimeFormat = require(ReplicatedStorage.TimeFormat)
local Locale = require(ReplicatedStorage.Locale)
local Num = require(ReplicatedStorage.Num)
local PlayerProfile = require(ServerScriptService.PlayerProfile)
local DataStoreUtil = require(ServerScriptService.DataStoreUtil)
local RateLimit = require(ServerScriptService.RateLimit)
local Remotes = require(ServerScriptService.Remotes)
local Telemetry = require(ServerScriptService.Telemetry)

local FLUSH_SECONDS = 60
local FLUSH_JITTER = 15
local RATE_COOLDOWN = 1
local SEND_COOLDOWN = 5

local prefix = if RunService:IsStudio() then FeedbackConfig.StudioPrefix else ""
local ratingStore = DataStoreService:GetDataStore(FeedbackConfig.RatingStore)
local feedbackStore = DataStoreService:GetDataStore(FeedbackConfig.FeedbackStore)
local countsKey = prefix .. FeedbackConfig.CountsKey
local withRetries = DataStoreUtil.WithRetries

local _, events = Remotes.Folder(FeedbackConfig.Folder, { "Rate", "Send", "Result" })
local reject, succeed = Remotes.Results(events.Result)
local allowRate = RateLimit.new(RATE_COOLDOWN)
local allowSend = RateLimit.new(SEND_COOLDOWN)

local pending = {} -- [stageKey] = { up = delta, down = delta } not written yet

-- The stored counts with `deltas` added (never below 0); an old or hand-edited value keeps only usable entries.
local function merge(old, deltas)
	local counts = {}
	if type(old) == "table" then
		for key, entry in old do
			if StageConfig.ByKey[key] and type(entry) == "table" then
				counts[key] = {
					up = if Num.Finite(entry.up) then math.max(0, math.floor(entry.up)) else 0,
					down = if Num.Finite(entry.down) then math.max(0, math.floor(entry.down)) else 0,
				}
			end
		end
	end
	for key, delta in deltas do
		local entry = counts[key] or { up = 0, down = 0 }
		entry.up = math.max(0, entry.up + delta.up)
		entry.down = math.max(0, entry.down + delta.down)
		counts[key] = entry
	end
	return counts
end

local function flush()
	if next(pending) == nil then
		return
	end
	local deltas = pending
	pending = {}
	local ok, err = withRetries(function()
		return ratingStore:UpdateAsync(countsKey, function(old)
			return merge(old, deltas)
		end)
	end)
	if not ok then
		warn("FeedbackService: writing the rating counts failed: " .. tostring(err))
		for key, delta in deltas do -- back into the queue for the next flush
			local entry = pending[key] or { up = 0, down = 0 }
			entry.up += delta.up
			entry.down += delta.down
			pending[key] = entry
		end
	end
end

local function addDelta(stageKey: string, rating: number, sign: number)
	local entry = pending[stageKey] or { up = 0, down = 0 }
	if rating == 1 then
		entry.up += sign
	else
		entry.down += sign
	end
	pending[stageKey] = entry
end

events.Rate.OnServerEvent:Connect(function(player: Player, stageKey: any, rating: any)
	local profile = PlayerProfile.Get(player)
	if not (profile and PlayerProfile.CanSave(player)) then
		return reject(player, "rate", "loading")
	end
	if type(stageKey) ~= "string" or not StageConfig.ByKey[stageKey] or profile.BestTimes[stageKey] == nil then
		return reject(player, "rate", "stage")
	end
	if rating ~= 1 and rating ~= -1 then
		return reject(player, "rate", "value")
	end
	if not allowRate(player) then
		return reject(player, "rate", "wait")
	end
	if type(profile.StageRatings) ~= "table" then
		profile.StageRatings = {}
	end
	local previous = profile.StageRatings[stageKey]
	if previous == rating then
		return succeed(player, "rate", rating)
	end
	if previous == 1 or previous == -1 then
		addDelta(stageKey, previous, -1)
	end
	addDelta(stageKey, rating, 1)
	profile.StageRatings[stageKey] = rating
	PlayerProfile.Save(player)
	Telemetry.StageRating(player, stageKey, rating, profile.Medals[stageKey] or 0, if previous then "change" else "new")
	succeed(player, "rate", rating)
end)

-- The broadcast-filtered `text`, or nil when the filter call fails.
local function filter(player: Player, text: string): string?
	local ok, result = pcall(function()
		local filterResult = TextService:FilterStringAsync(text, player.UserId, Enum.TextFilterContext.PublicChat)
		return filterResult:GetNonChatStringForBroadcastAsync()
	end)
	if ok and type(result) == "string" then
		return result
	end
	warn("FeedbackService: filter failed: " .. tostring(result))
	return nil
end

-- The profile's messages today (FeedbackToday started afresh on a new UTC day).
local function today(profile)
	local day = TimeFormat.UtcDay(os.time())
	local record = profile.FeedbackToday
	if type(record) ~= "table" or record.Day ~= day or not Num.Finite(record.Count) then
		record = { Day = day, Count = 0 }
		profile.FeedbackToday = record
	end
	return record
end

local sending = {} -- [Player] = true while a message is being filtered / stored

events.Send.OnServerEvent:Connect(function(player: Player, category: any, text: any)
	local profile = PlayerProfile.Get(player)
	if not (profile and PlayerProfile.CanSave(player)) then
		return reject(player, "send", "loading")
	end
	if not FeedbackConfig.IsCategory(category) then
		return reject(player, "send", "category")
	end
	local trimmed = FeedbackConfig.Trim(text)
	if trimmed == nil or trimmed == "" then
		return reject(player, "send", "empty")
	end
	if (utf8.len(trimmed) :: number) > FeedbackConfig.MaxLength then
		return reject(player, "send", "long")
	end
	if today(profile).Count >= FeedbackConfig.PerDay then
		return reject(player, "send", "daily")
	end
	if sending[player] or not allowSend(player) then
		return reject(player, "send", "wait")
	end
	sending[player] = true
	local area = Telemetry.AreaOf(player)
	local filtered = filter(player, trimmed)
	if not filtered then
		sending[player] = nil
		return reject(player, "send", "filter")
	end
	local now = os.time()
	local key = string.format("%s%d_%d", prefix, now, player.UserId)
	local ok, err = withRetries(function()
		feedbackStore:SetAsync(key, {
			u = player.UserId,
			t = now,
			cat = category,
			area = area,
			text = filtered,
			lang = tostring(player:GetAttribute(Locale.LanguageAttribute) or player.LocaleId),
			ver = game.PlaceVersion,
		}, { player.UserId })
	end)
	sending[player] = nil
	if not ok then
		warn("FeedbackService: storing " .. key .. " failed: " .. tostring(err))
		return reject(player, "send", "failed")
	end
	local record = today(PlayerProfile.Get(player) or profile)
	record.Count += 1
	PlayerProfile.Save(player)
	Telemetry.Feedback(player, category, area)
	succeed(player, "send", FeedbackConfig.PerDay - record.Count)
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
	sending[player] = nil
end)

task.spawn(function()
	while true do
		task.wait(FLUSH_SECONDS + math.random() * FLUSH_JITTER)
		flush()
	end
end)

game:BindToClose(flush)
