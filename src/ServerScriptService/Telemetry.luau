-- Telemetry (T1a / T1b, docs/TELEMETRY.md): the only caller of AnalyticsService. Server-only.
--   * run funnel "StageRun" (one funnel for every stage, CF01 = stage): step 1 start, k + 1 = cp<k>, FINISH_STEP = finish;
--   * stage progression start / complete / fail (path = world name or "Hub", level = position in the world);
--   * custom events Fail (aggregated per player and (stage, segment, cause), flushed every minute and on leave), RunEnd,
--     Quit, Return and Session;
--   * skills (T1b): the loadout (talent levels at the run's start, "RS3 DJ1 JH3 QR2") on the progression events, an economy
--     event + TalentBought per talent purchase (TalentService), ArrivalWithoutTalent (PlayerTimerHandler's arrival check).
-- Hooks: PlayerTimerHandler calls RunStarted / RunEnded, CheckpointTouchHandler calls Checkpoint, the kill scripts call
-- MarkKill; deaths (Humanoid.Died), joins, leaves (PlayerProfile.OnLeaving) and the client reports are watched here.
-- Debug: with the ServerScriptService attribute TelemetryDebug = true every event is printed as "[Telemetry] …".

local AnalyticsService = game:GetService("AnalyticsService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local StageConfig = require(ReplicatedStorage.StageConfig)
local TalentConfig = require(ReplicatedStorage.TalentConfig)
local PlayerProfile = require(ServerScriptService.PlayerProfile)

local FUNNEL = "StageRun"
local MAX_CP = 20 -- funnel steps cp1..cp20 (step k + 1); a later checkpoint counts as cp20
local FINISH_STEP = MAX_CP + 2
local FLUSH_INTERVAL = 60 -- seconds between Fail flushes
local CLASSIFY_DELAY = 1 -- seconds after a death before its cause is decided, so a client report can still arrive
local CLIENT_KILL_WINDOW = 3 -- seconds between a client kill report and the death it explains
local REPORT_COOLDOWN = 1 -- seconds; a second kill / fall report within it is dropped
-- seconds a run's first events are held back: walking out through a gate touches TimerStart again just after GateExit
-- cancelled the run, which starts a ghost run that GateExit ends a moment later; such a run ending by "exit" sends nothing
local GHOST_TIME = 2
local SESSION_WAIT = 15 -- seconds to wait for the client's platform before Session logs "unknown"
local GARDEN_RADIUS = 145 -- studs from the garden island's centre (the island is 290 across)
local RATE_BASE, RATE_PER_PLAYER = 100, 15 -- events per minute and server (the API allows 120 + 20 × CCU per experience)
local PLATFORMS = { touch = true, gamepad = true, keyboard = true }
local DEATH_BUCKETS = { { 0, "0" }, { 2, "1-2" }, { 5, "3-5" }, { 10, "6-10" } } -- above the last: "11+"
local STAR_BUCKETS = { { 0, "0" }, { 5, "1-5" }, { 15, "6-15" }, { 30, "16-30" } } -- above the last: "31+"

local CF = {
	Enum.AnalyticsCustomFieldKeys.CustomField01.Name,
	Enum.AnalyticsCustomFieldKeys.CustomField02.Name,
	Enum.AnalyticsCustomFieldKeys.CustomField03.Name,
}

local Telemetry = {}

-- [Player] = {
--   run = { id, stage, startClock, cp (position of the current checkpoint, 0 before the first), maxStep, deaths, loadout,
--     queue (events held back while the run is younger than GHOST_TIME) } or nil, lastStage (key of the last run's stage),
--   lastActivity (os.clock of the last checkpoint / run start / run end / join), lastReport, clientKill = { part, at },
--   platform, area (score panel key, SetArea), fails = { [key] = { stage, segment, cause, count } }
-- }
local states = {}
local marks = {} -- [character] = { part = the server kill part that killed it (first mark wins), at = os.clock() }
local positions = {} -- [stage key] = { [checkpoint C part] = position in course order }

local function debugOn(): boolean
	return ServerScriptService:GetAttribute("TelemetryDebug") == true
end

local function debugPrint(...)
	if debugOn() then
		print("[Telemetry]", ...)
	end
end

local function fields(...)
	local list = {}
	for i = 1, select("#", ...) do
		local value = select(i, ...)
		if value ~= nil then
			list[CF[i]] = tostring(value)
		end
	end
	return list
end

local function describe(value): string
	if type(value) ~= "table" then
		return tostring(value)
	end
	local parts = {}
	for key, item in value do
		table.insert(parts, (string.gsub(tostring(key), "CustomField", "CF")) .. "=" .. tostring(item))
	end
	table.sort(parts)
	return "{" .. table.concat(parts, " ") .. "}"
end

-- per-server rate guard over a one-minute window
local windowStart, windowCount, windowWarned = os.clock(), 0, false

local function allow(): boolean
	local now = os.clock()
	if now - windowStart >= 60 then
		windowStart, windowCount, windowWarned = now, 0, false
	end
	if windowCount >= RATE_BASE + RATE_PER_PLAYER * #Players:GetPlayers() then
		if not windowWarned then
			windowWarned = true
			warn("Telemetry: rate guard dropped events this minute")
		end
		return false
	end
	windowCount += 1
	return true
end

local function send(method: string, player: Player, ...)
	if not allow() then
		return
	end
	local args = table.pack(...)
	if debugOn() then
		local shown = {}
		for i = 1, args.n do
			shown[i] = describe(args[i])
		end
		print("[Telemetry]", method, player.Name, table.concat(shown, " "))
	end
	local ok, err = pcall(function()
		(AnalyticsService :: any)[method](AnalyticsService, player, table.unpack(args, 1, args.n))
	end)
	if not ok and debugOn() then
		warn("[Telemetry] " .. method .. " failed: " .. tostring(err))
	end
end

local function state(player: Player)
	local s = states[player]
	if not s then
		s = { lastActivity = os.clock(), lastReport = 0, fails = {} }
		states[player] = s
	end
	return s
end

local function round(value: number, step: number): number
	return math.floor(value / step + 0.5) * step
end

local function bucketOf(buckets, value: number, above: string): string
	for _, bucket in buckets do
		if value <= bucket[1] then
			return bucket[2]
		end
	end
	return above
end

local function deathsBucket(deaths: number): string
	return bucketOf(DEATH_BUCKETS, deaths, "11+")
end

-- Talent levels from the Talent_<id> attributes, e.g. "RS3 DJ1 JH3 QR2" (code = the capitals of the talent id)
local function loadout(player: Player): string
	local parts = {}
	for _, talent in TalentConfig.List do
		local level = TalentConfig.ClampLevel(talent.id, player:GetAttribute(TalentConfig.AttributeName(talent.id)))
		table.insert(parts, (string.gsub(talent.id, "%l", "")) .. level)
	end
	return table.concat(parts, " ")
end

local function segment(run): string
	return run.stage.key .. "#" .. run.cp
end

-- progression path (world name, "Hub" for the Tutorial) and level (1-based position in the world)
local function progression(stage)
	local world = StageConfig.Worlds[stage.world]
	local level = table.find(StageConfig.StagesOfWorld(stage.world), stage) or 1
	return if world then world.name else "Hub", level
end

-- Position of checkpoint part `part` in the course order of `stage` (folder `folder`): the checkpoint folders sorted by
-- `stage.checkpointOrder`, else numerically. Rebuilt when an unknown part shows up (parts added later in Studio).
local function positionOf(stage, folder: Instance, part: BasePart): number?
	local map = positions[stage.key]
	if map and map[part] then
		return map[part]
	end
	local list = {}
	for _, d in folder:GetDescendants() do
		if d.Name == "C" and d:IsA("BasePart") and d.Parent and tonumber(d.Parent.Name) then
			table.insert(list, d)
		end
	end
	local rank = {}
	for i, name in stage.checkpointOrder or {} do
		rank[name] = i
	end
	local function key(p)
		return rank[p.Parent.Name] or 1e6 + tonumber(p.Parent.Name)
	end
	table.sort(list, function(a, b)
		return key(a) < key(b)
	end)
	map = {}
	for i, p in list do
		map[p] = i
	end
	positions[stage.key] = map
	return map[part]
end

-- The cause of a death by `part` and the stage it lies in: "fall" for the sea, else "kill:<path>" with the path below the
-- stage folder (or below the top-level Workspace folder, whose name is then the stage) cut to two levels.
local function causeOf(part: Instance): (string?, string)
	if part == workspace:FindFirstChild("DebugBaseplate") then
		return nil, "fall"
	end
	local found, stage, folder = pcall(StageConfig.ForInstance, part)
	local root = if found then folder else part
	while not found and root.Parent and root.Parent ~= workspace do
		root = root.Parent
	end
	if not found and root.Parent ~= workspace then
		return nil, "other"
	end
	local names = {}
	local node = part
	while node and node ~= root do
		table.insert(names, 1, node.Name)
		node = node.Parent
	end
	if #names == 0 then
		names = { root.Name }
	end
	return if found then stage.key else root.Name, "kill:" .. table.concat(names, "/", 1, math.min(2, #names))
end

local function countFail(player: Player, stageName: string, seg: string, cause: string)
	local s = state(player)
	local key = stageName .. "|" .. seg .. "|" .. cause
	local entry = s.fails[key]
	if entry then
		entry.count += 1
	else
		s.fails[key] = { stage = stageName, segment = seg, cause = cause, count = 1 }
	end
	debugPrint("fail counted", player.Name, stageName, seg, cause)
end

local function flush(player: Player)
	local s = states[player]
	if not s or next(s.fails) == nil then
		return
	end
	local fails = s.fails
	s.fails = {}
	for _, entry in fails do
		send("LogCustomEvent", player, "Fail", entry.count, fields(entry.stage, entry.segment, entry.cause))
	end
end

-- PlayerTimerHandler: the score panel now shows `key` (a stage key, a world name or StageConfig.HubName); kept here because
-- the handler forgets it in its own PlayerRemoving, possibly before the leave callback below runs
function Telemetry.SetArea(player: Player, key: string)
	state(player).area = key
end

-- Sends a run event, or queues it while the run is younger than GHOST_TIME
local function runSend(player: Player, run, method: string, ...)
	if run.queue then
		table.insert(run.queue, table.pack(method, ...))
	else
		send(method, player, ...)
	end
end

local function releaseQueue(player: Player, run)
	local queue = run.queue
	run.queue = nil
	for _, item in queue or {} do
		send(item[1], player, table.unpack(item, 2, item.n))
	end
end

-- A run of `stageKey` started (PlayerTimerHandler.StartTimer); a run still going on another stage ends with "switch"
function Telemetry.RunStarted(player: Player, stageKey: string)
	local stage = StageConfig.ByKey[stageKey]
	if not stage then
		return
	end
	local s = state(player)
	if s.run then
		Telemetry.RunEnded(player, "switch")
	end
	local run = {
		id = HttpService:GenerateGUID(false),
		stage = stage,
		startClock = os.clock(),
		cp = 0,
		maxStep = 1,
		deaths = 0,
		loadout = loadout(player),
		queue = {},
	}
	s.run = run
	s.lastStage = stage.key
	s.lastActivity = os.clock()
	runSend(player, run, "LogFunnelStepEvent", FUNNEL, run.id, 1, "start", fields(stage.key))
	local path, level = progression(stage)
	runSend(player, run, "LogProgressionStartEvent", path, level, stage.key, fields(nil, nil, run.loadout))
	task.delay(GHOST_TIME, function()
		if s.run == run then
			releaseQueue(player, run)
		end
	end)
end

-- The run ended: reason "finish" (with StageResults' `result`), "exit", "home", "reset", "quit" or "switch"
function Telemetry.RunEnded(player: Player, reason: string, result: { medal: number }?)
	local s = states[player]
	local run = s and s.run
	if not run then
		return
	end
	s.run = nil
	s.lastActivity = os.clock()
	if run.queue and reason == "exit" then
		debugPrint("ghost run dropped", player.Name, run.stage.key)
		return
	end
	releaseQueue(player, run)
	local stage = run.stage
	local seg = segment(run)
	local bucket = deathsBucket(run.deaths)
	local path, level = progression(stage)
	if reason == "finish" then
		send("LogFunnelStepEvent", player, FUNNEL, run.id, FINISH_STEP, "finish", fields(stage.key))
		local medal = result and StageConfig.Medals[result.medal]
		send("LogProgressionCompleteEvent", player, path, level, stage.key, fields(if medal then medal.name else "none", bucket, run.loadout))
	else
		-- the segment stays in RunEnd: with the loadout it would exceed the custom fields' combination limit
		send("LogProgressionFailEvent", player, path, level, stage.key, fields(reason, bucket, run.loadout))
	end
	send("LogCustomEvent", player, "RunEnd", round(os.clock() - run.startClock, 0.1), fields(stage.key, seg, reason))
end

-- TalentService bought level `level` of talent `talentId` for `cost` Coins, leaving `balance`
function Telemetry.TalentBought(player: Player, talentId: string, level: number, cost: number, balance: number)
	send(
		"LogEconomyEvent",
		player,
		Enum.AnalyticsEconomyFlowType.Sink,
		"Coins",
		cost,
		balance,
		Enum.AnalyticsEconomyTransactionType.Shop.Name,
		talentId .. "_" .. level
	)
	local profile = PlayerProfile.Get(player)
	local stars = if profile then StageConfig.TotalStars(profile.Medals) else 0
	local s = state(player)
	send("LogCustomEvent", player, "TalentBought", level, fields(talentId, bucketOf(STAR_BUCKETS, stars, "31+"), s.lastStage or "none"))
end

-- PlayerTimerHandler: the player arrived on stage `stageKey` without the talents in `missing` ({ { id, level }, … })
function Telemetry.ArrivalWithoutTalent(player: Player, stageKey: string, missing)
	local names = {}
	for _, need in missing do
		table.insert(names, need.id .. need.level)
	end
	local args = fields(stageKey, table.concat(names, "+"))
	local run = states[player] and states[player].run
	if run and run.stage.key == stageKey then
		runSend(player, run, "LogCustomEvent", "ArrivalWithoutTalent", 1, args) -- the gate entry of this run: dropped with a ghost run
	else
		send("LogCustomEvent", player, "ArrivalWithoutTalent", 1, args)
	end
end

-- The player's respawn point moved to checkpoint part `part` (CheckpointTouchHandler); a checkpoint of the running stage
-- further on than any before in this run logs its funnel step
function Telemetry.Checkpoint(player: Player, part: BasePart)
	local s = state(player)
	s.lastActivity = os.clock()
	local run = s.run
	if not run then
		return
	end
	local found, stage, folder = pcall(StageConfig.ForInstance, part)
	if not found or stage ~= run.stage then
		return
	end
	local k = positionOf(stage, folder, part)
	if not k then
		return
	end
	run.cp = k
	local step = math.min(k, MAX_CP) + 1
	if step > run.maxStep then
		run.maxStep = step
		runSend(player, run, "LogFunnelStepEvent", FUNNEL, run.id, step, "cp" .. (step - 1), fields(stage.key))
	end
end

-- A server kill part killed `character` (the kill-script copies, the sea, the arena spikes); the first mark counts
function Telemetry.MarkKill(character: Instance?, part: Instance)
	if character and marks[character] == nil then
		marks[character] = { part = part, at = os.clock() }
	end
end

local function onDied(player: Player, character: Model)
	local s = state(player)
	local run = s.run
	local runStage = run and run.stage.key
	local seg = if run then segment(run) else "#-"
	if run then
		run.deaths += 1
	end
	local diedAt = os.clock()
	task.delay(CLASSIFY_DELAY, function()
		local partStage, cause = nil, "other"
		local mark = marks[character]
		local clientKill = s.clientKill
		if mark then
			partStage, cause = causeOf(mark.part)
		elseif clientKill and math.abs(clientKill.at - diedAt) <= CLIENT_KILL_WINDOW and clientKill.part.Parent then
			partStage, cause = causeOf(clientKill.part)
		end
		s.clientKill = nil
		countFail(player, runStage or partStage or "none", seg, cause)
	end)
end

local function watchCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid then
		humanoid.Died:Once(function()
			onDied(player, character)
		end)
	end
end

-- client -> server reports (telemetry only, never trusted for gameplay):
--   ("platform", "touch" | "gamepad" | "keyboard") once on join (TelemetryClient)
--   ("kill", part) the kit killed the character on the client (ObstacleKit); part must lie in a stage folder
--   ("fall") a Quick Respawn fall reset put the character back on its plate without a death (QuickRespawnClient)
local remotes = Instance.new("Folder")
remotes.Name = "TelemetryRemotes"
local report = Instance.new("RemoteEvent")
report.Name = "Report"
report.Parent = remotes
remotes.Parent = ReplicatedStorage

report.OnServerEvent:Connect(function(player, kind, arg)
	local s = state(player)
	if kind == "platform" then
		if s.platform == nil and type(arg) == "string" and PLATFORMS[arg] then
			s.platform = arg
		end
		return
	end
	if kind ~= "kill" and kind ~= "fall" then
		return
	end
	local now = os.clock()
	if now - s.lastReport < REPORT_COOLDOWN then
		debugPrint("report dropped (cooldown)", player.Name, kind)
		return
	end
	s.lastReport = now
	if kind == "kill" then
		if typeof(arg) ~= "Instance" or not arg:IsA("BasePart") or not pcall(StageConfig.ForInstance, arg) then
			debugPrint("report dropped (not a stage part)", player.Name, describe(arg))
			return
		end
		s.clientKill = { part = arg, at = now }
		return
	end
	local run = s.run
	if run then
		run.deaths += 1
	end
	countFail(player, if run then run.stage.key else "none", if run then segment(run) else "#-", "fall")
end)

-- Where an idle player is: the garden island, else the score panel's place ("hub" or a world name / stage key)
local function idleArea(player: Player): string
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local garden = workspace:FindFirstChild("Garden")
	local island = garden and garden:FindFirstChild("Island")
	if root and island and island:IsA("BasePart") then
		local offset = root.Position - island.Position
		if Vector3.new(offset.X, 0, offset.Z).Magnitude < GARDEN_RADIUS then
			return "garden"
		end
	end
	local key = states[player] and states[player].area
	return if key == nil or key == StageConfig.HubName then "hub" else key
end

local function onJoin(player: Player)
	local s = state(player)
	player.CharacterAdded:Connect(function(character)
		watchCharacter(player, character)
	end)
	if player.Character then
		task.spawn(watchCharacter, player, player.Character)
	end

	local profile = PlayerProfile.WaitFor(player)
	if not profile then
		return
	end
	local lastQuit = profile.LastQuit
	if type(lastQuit) == "table" and lastQuit.Stage then
		local days = math.max(0, os.time() - (tonumber(lastQuit.At) or os.time())) / 86400
		send("LogCustomEvent", player, "Return", round(days, 0.01), fields(lastQuit.Stage, lastQuit.Segment))
		profile.LastQuit = {}
	end
	local isNew = PlayerProfile.IsNew(player)
	local deadline = os.clock() + SESSION_WAIT
	while s.platform == nil and player.Parent and os.clock() < deadline do
		task.wait(0.5)
	end
	if player.Parent then
		send("LogCustomEvent", player, "Session", 1, fields(player.LocaleId, s.platform or "unknown", if isNew then "new" else "returning"))
	end
end

-- Leaving (also a server shutdown): a running run ends with "quit", Quit is logged, fails are flushed and LastQuit is
-- written into the profile before PlayerProfile saves it
PlayerProfile.OnLeaving(function(player: Player, profile)
	local s = states[player]
	if not s then
		return
	end
	local idle = round(os.clock() - s.lastActivity, 0.1)
	local area, seg, kind
	if s.run then
		area, seg, kind = s.run.stage.key, segment(s.run), "run"
		Telemetry.RunEnded(player, "quit")
	else
		area, seg, kind = idleArea(player), "#-", "idle"
	end
	send("LogCustomEvent", player, "Quit", idle, fields(area, seg, kind))
	flush(player)
	if profile then
		profile.LastQuit = { Stage = area, Segment = seg, At = os.time() }
	end
	states[player] = nil
end)

Players.PlayerAdded:Connect(onJoin)
for _, player in Players:GetPlayers() do
	task.spawn(onJoin, player)
end
Players.PlayerRemoving:Connect(function(player)
	task.delay(CLASSIFY_DELAY + 1, function() -- after a death classified during the leave
		states[player] = nil
	end)
end)

task.spawn(function()
	while true do
		task.wait(FLUSH_INTERVAL)
		for player in states do
			flush(player)
		end
		local now = os.clock()
		for character, mark in marks do -- marks are read 1 s after a death; later touches of a dead body only leave stale ones
			if now - mark.at > FLUSH_INTERVAL then
				marks[character] = nil
			end
		end
	end
end)

return Telemetry
