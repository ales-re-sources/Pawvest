-- StageConfig: single source of truth for stages (docs/GDD.md §3–5). Shared by server and client.
-- `key` is the DataStore key (best times, leaderboards, medals) and must never change for an existing stage.

local TimeFormat = require(script.Parent.TimeFormat)

local StageConfig = {}

StageConfig.HubName = "Central Island"

-- Medal tiers in ascending order (GDD §4–5). A medal is stored as its index here; 0 = no medal.
-- runMultiplier scales the repeat reward of a run with that medal.
StageConfig.Medals = {
	{ name = "Bronze", basePayout = 200, runMultiplier = 1 },
	{ name = "Silver", basePayout = 400, runMultiplier = 1.5 },
	{ name = "Gold", basePayout = 800, runMultiplier = 2 },
}

-- Medal index by tier name ("Silver" → 2).
StageConfig.MedalIndex = {}
for index, medal in StageConfig.Medals do
	StageConfig.MedalIndex[medal.name] = index
end

-- Repeat reward (GDD §5): max(RunRewardFloor, round(RunRewardBase × factor × medal multiplier × RunRewardDecay^n))
StageConfig.RunRewardBase = 50
StageConfig.RunRewardDecay = 0.8
StageConfig.RunRewardFloor = 10

-- Medal thresholds as multiples of tBase (GDD §4); a stage may point `tiers` at its own table.
StageConfig.DefaultTiers = { Bronze = 1.6, Silver = 1.1, Gold = 0.8 }

StageConfig.Stages = {
	{
		key = "Stage 4", -- legacy key of the Tutorial, kept so recorded times are not lost
		displayName = "Tutorial",
		folder = "Tutorial", -- stage folder in Workspace
		hubPortal = "TeleportToTutorial",
		order = 0,
		tBase = 30, -- seconds; provisional until measured in M6
		tiers = StageConfig.DefaultTiers,
		unlock = nil, -- nil = always open; otherwise { stage = <key>, medal = <tier> }
		unlockPrice = nil,
		rewardFactor = 0.5,
	},
	{
		key = "Stage 1",
		displayName = "Stage 1",
		folder = "Stage1",
		hubPortal = "TeleportToStage1",
		order = 1,
		tBase = 70,
		tiers = StageConfig.DefaultTiers,
		unlock = { stage = "Stage 4", medal = "Bronze" }, -- Tutorial
		unlockPrice = 500,
		rewardFactor = 1.0,
	},
	{
		key = "Stage 2",
		displayName = "Stage 2",
		folder = "Stage2",
		hubPortal = "TeleportToStage2",
		order = 2,
		tBase = 100,
		tiers = StageConfig.DefaultTiers,
		unlock = { stage = "Stage 1", medal = "Silver" },
		unlockPrice = 1500,
		rewardFactor = 1.5,
	},
	{
		key = "Stage 3",
		displayName = "Stage 3",
		folder = "Stage3",
		hubPortal = "TeleportToStage3",
		order = 3,
		tBase = 120,
		tiers = StageConfig.DefaultTiers,
		unlock = { stage = "Stage 2", medal = "Silver" },
		unlockPrice = 3000,
		rewardFactor = 2.0,
	},
}

table.sort(StageConfig.Stages, function(a, b)
	return a.order < b.order
end)

StageConfig.ByKey = {}
StageConfig.ByFolder = {}
StageConfig.ByHubPortal = {}
for _, stage in StageConfig.Stages do
	StageConfig.ByKey[stage.key] = stage
	StageConfig.ByFolder[stage.folder] = stage
	if stage.hubPortal then
		StageConfig.ByHubPortal[stage.hubPortal] = stage
	end
end

-- Returns the stage whose Workspace folder contains `instance` (e.g. a script inside Workspace.Stage2).
function StageConfig.ForInstance(instance: Instance)
	local node = instance
	while node and node.Parent ~= workspace do
		node = node.Parent
	end
	local stage = node and StageConfig.ByFolder[node.Name]
	if not stage then
		error("StageConfig: no stage folder above " .. instance:GetFullName())
	end
	return stage
end

-- Time limit (seconds, tenths) for medal index `medal` on `stage`, or nil while the stage has no tBase.
function StageConfig.Threshold(stage, medal: number): number?
	if not stage.tBase then
		return nil
	end
	return TimeFormat.Tenths(stage.tBase * stage.tiers[StageConfig.Medals[medal].name])
end

-- Highest medal index whose threshold `elapsed` meets; 0 = none.
function StageConfig.EvaluateMedal(stage, elapsed: number): number
	local earned = 0
	for medal in StageConfig.Medals do
		local limit = StageConfig.Threshold(stage, medal)
		if limit and elapsed <= limit then
			earned = medal
		end
	end
	return earned
end

-- Coins for reaching `toMedal` when `fromMedal` is already earned; skipped lower tiers are paid too.
function StageConfig.Payout(stage, fromMedal: number, toMedal: number): number
	local coins = 0
	for medal = fromMedal + 1, toMedal do
		coins += StageConfig.Medals[medal].basePayout * stage.rewardFactor
	end
	return math.floor(coins + 0.5)
end

-- Repeat reward for a run with medal index `medal` after `finishesToday` earlier finishes of `stage` today; 0 without a medal.
function StageConfig.RunReward(stage, medal: number, finishesToday: number): number
	if medal <= 0 then
		return 0
	end
	local raw = StageConfig.RunRewardBase * stage.rewardFactor * StageConfig.Medals[medal].runMultiplier
		* StageConfig.RunRewardDecay ^ finishesToday
	-- the epsilon keeps exact halves (37.5, 112.5) rounding up despite float error in 0.8^n
	return math.max(StageConfig.RunRewardFloor, math.floor(raw + 0.5 + 1e-9))
end

-- Player attribute that replicates the player's medal on `stage` to clients.
function StageConfig.MedalAttribute(stage): string
	return "Medal_" .. stage.folder
end

-- True when `medals` ([stageKey] = medal index) meet the stage's unlock bar, or the stage has no unlock rule (GDD §3).
function StageConfig.MeetsUnlockBar(stage, medals): boolean
	local rule = stage.unlock
	if not rule then
		return true
	end
	return (medals[rule.stage] or 0) >= StageConfig.MedalIndex[rule.medal]
end

-- Player attribute that replicates whether the player may enter `stage` (bar met or bought).
function StageConfig.UnlockedAttribute(stage): string
	return "Unlocked_" .. stage.folder
end

return StageConfig
