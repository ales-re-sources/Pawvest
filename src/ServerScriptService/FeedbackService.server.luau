-- FeedbackService (FB / FB2, docs/GDD.md §10 → Player feedback): stage ratings and the feedback box, both only for us. Server-only.
-- Remotes (ReplicatedStorage.FeedbackRemotes, FeedbackConfig.Folder):
--   Rate(stageKey, rating)    client → server: 1 = 👍, -1 = 👎 at a world stage's rating sign (FB2, RatingSigns; the character within
--                             RateDistance of that sign; finished or not) or on the results popup (StageResultsPopup; within
--                             PopupSeconds of finishing that stage, anywhere). Kept in profile StageRatings[stageKey] = { R = ±1, F = finished
--                             when rated }, mirrored to the player attribute StageRatings (JSON { [stageKey] = ±1 }); the per-stage counts
--                             (DataStore StageRatings, key "counts" = { [stageKey] = { up, down, upUnfinished, downUnfinished } }) take
--                             the change as a delta in the pair F picks, queued and written with one UpdateAsync every FLUSH_SECONDS
--                             (+ jitter) and in BindToClose. Telemetry StageRating carries Telemetry.StageProgress. Answer: ("rate", ok, …).
--   Send(category, text)      client → server: a feedback message from the Settings box; a known category, 1..MaxLength characters,
--                             PerDay a UTC day (profile FeedbackToday = { Day, Count }); filtered before it is stored in the
--                             DataStore PlayerFeedback (key "<os.time()>_<UserId>" = { u, t, cat, area, text, lang, ver }).
--                             Answer: ("send", true, left today) or ("send", false, reason).
--   Result                    server → client: (key, ok, detail / reason), Remotes.Results
-- Reasons: loading, stage (unknown / the Tutorial), far, value, wait (cooldown), category, empty, long, daily, filter, failed.
-- In Studio the keys get FeedbackConfig.StudioPrefix (tests never touch the live data). Studio does not filter text.

local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
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
local StageResults = require(ServerScriptService.StageResults)

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

local FIELDS = { "up", "down", "upUnfinished", "downUnfinished" }

local pending = {} -- [stageKey] = { [field] = delta } not written yet

-- The stored counts with `deltas` added (never below 0); an old or hand-edited value keeps only usable entries.
local function merge(old, deltas)
	local counts = {}
	if type(old) == "table" then
		for key, entry in old do
			if StageConfig.ByKey[key] and type(entry) == "table" then
				local clean = {}
				for _, field in FIELDS do
					clean[field] = if Num.Finite(entry[field]) then math.max(0, math.floor(entry[field])) else 0
				end
				counts[key] = clean
			end
		end
	end
	for key, delta in deltas do
		local entry = counts[key]
		if not entry then
			entry = {}
			for _, field in FIELDS do
				entry[field] = 0
			end
			counts[key] = entry
		end
		for field, change in delta do
			entry[field] = math.max(0, entry[field] + change)
		end
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
			local entry = pending[key] or {}
			for field, change in delta do
				entry[field] = (entry[field] or 0) + change
			end
			pending[key] = entry
		end
	end
end

-- Queues `sign` (+1 / -1) for the vote `vote` ({ R = ±1, F = finished when rated }) of `stageKey`.
local function addDelta(stageKey: string, vote, sign: number)
	local field = (if vote.R == 1 then "up" else "down") .. (if vote.F then "" else "Unfinished")
	local entry = pending[stageKey] or {}
	entry[field] = (entry[field] or 0) + sign
	pending[stageKey] = entry
end

-- The profile's ratings made usable (an old or hand-edited record keeps only { R = ±1, F = bool } of world stages).
local function ratingsOf(profile)
	if type(profile.StageRatings) ~= "table" then
		profile.StageRatings = {}
	end
	for key, vote in profile.StageRatings do
		if not (FeedbackConfig.Rated(StageConfig.ByKey[key]) and type(vote) == "table" and (vote.R == 1 or vote.R == -1)) then
			profile.StageRatings[key] = nil
		else
			vote.F = vote.F == true
		end
	end
	return profile.StageRatings
end

local function mirror(player: Player, ratings)
	local shown = {}
	for key, vote in ratings do
		shown[key] = vote.R
	end
	player:SetAttribute(FeedbackConfig.RatingsAttribute, HttpService:JSONEncode(shown))
end

-- Whether the character of `player` stands within RateDistance of `stage`'s rating sign.
local function nearSign(player: Player, stage): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return false
	end
	for _, sign in CollectionService:GetTagged(FeedbackConfig.SignTag) do
		if StageConfig.TryForInstance(sign) == stage then
			local pivot = if sign:IsA("Model") then sign:GetPivot() else (sign :: BasePart).CFrame
			if (pivot.Position - root.Position).Magnitude <= FeedbackConfig.RateDistance then
				return true
			end
		end
	end
	return false
end

events.Rate.OnServerEvent:Connect(function(player: Player, stageKey: any, rating: any)
	local profile = PlayerProfile.Get(player)
	if not (profile and PlayerProfile.CanSave(player)) then
		return reject(player, "rate", "loading")
	end
	local stage = type(stageKey) == "string" and StageConfig.ByKey[stageKey]
	if not FeedbackConfig.Rated(stage) then
		return reject(player, "rate", "stage")
	end
	if rating ~= 1 and rating ~= -1 then
		return reject(player, "rate", "value")
	end
	if not (nearSign(player, stage) or StageResults.FinishedWithin(player, stageKey, FeedbackConfig.PopupSeconds)) then
		return reject(player, "rate", "far")
	end
	if not allowRate(player) then
		return reject(player, "rate", "wait")
	end
	local ratings = ratingsOf(profile)
	local previous = ratings[stageKey]
	if previous and previous.R == rating then
		return succeed(player, "rate", rating)
	end
	if previous then
		addDelta(stageKey, previous, -1)
	end
	local vote = { R = rating, F = profile.BestTimes[stageKey] ~= nil }
	addDelta(stageKey, vote, 1)
	ratings[stageKey] = vote
	mirror(player, ratings)
	PlayerProfile.Save(player)
	Telemetry.StageRating(player, stageKey, rating, Telemetry.StageProgress(player, stageKey), if previous then "change" else "new")
	succeed(player, "rate", rating)
end)

PlayerProfile.OnReady(function(player, profile)
	mirror(player, ratingsOf(profile))
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
