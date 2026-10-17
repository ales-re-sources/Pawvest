-- StageResults: what a finished run earns — personal best, medal, one-time Coin payouts and the daily diminishing
-- repeat reward (docs/GDD.md §4–5). Coins are paid through CoinRewards.
-- Server-only. Medals are mirrored to player attributes (StageConfig.MedalAttribute) for client displays.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local StageConfig = require(ReplicatedStorage.StageConfig)
local PlayerProfile = require(ServerScriptService.PlayerProfile)
local CoinRewards = require(ServerScriptService.CoinRewards)

local StageResults = {}

local function publishMedals(player)
	local profile = PlayerProfile.WaitFor(player)
	if not profile then
		return
	end
	for _, stage in StageConfig.Stages do
		player:SetAttribute(StageConfig.MedalAttribute(stage), profile.Medals[stage.key] or 0)
	end
end

local SECONDS_PER_DAY = 86400

-- The profile's finish counts for the current UTC day, started afresh when the day changed.
local function runsToday(profile)
	local today = math.floor(os.time() / SECONDS_PER_DAY)
	if profile.RunsToday.Day ~= today then
		profile.RunsToday = { Day = today }
	end
	return profile.RunsToday
end

-- Records a finished run and returns the result for the results popup, or nil if the profile is not loaded:
-- { stageKey, displayName, time, best, newBest, medal (this run), bestMedal, coins (medal payout),
--   runCoins (repeat reward), runsToday (finishes of this stage today, this one included), nextMedal?, nextThreshold? }
function StageResults.RecordFinish(player: Player, stageKey: string, elapsed: number)
	local profile = PlayerProfile.Get(player)
	local stage = StageConfig.ByKey[stageKey]
	if not (profile and stage) then
		return nil
	end

	local previousBest = profile.BestTimes[stageKey]
	local newBest = previousBest == nil or elapsed < previousBest
	if newBest then
		profile.BestTimes[stageKey] = elapsed
	end

	-- each tier pays once: only tiers above the best medal so far are paid
	local medal = StageConfig.EvaluateMedal(stage, elapsed)
	local previousMedal = profile.Medals[stageKey] or 0
	local coins = 0
	if medal > previousMedal then
		profile.Medals[stageKey] = medal
		player:SetAttribute(StageConfig.MedalAttribute(stage), medal)
		coins = CoinRewards.Grant(player, StageConfig.Payout(stage, previousMedal, medal), "medal") or 0
	end

	-- every finish counts towards the daily decay; only finishes with a medal pay
	local runs = runsToday(profile)
	local earlierFinishes = runs[stageKey] or 0
	runs[stageKey] = earlierFinishes + 1
	local runCoins = CoinRewards.Grant(player, StageConfig.RunReward(stage, medal, earlierFinishes), "run") or 0
	if medal > previousMedal then
		task.spawn(PlayerProfile.Save, player) -- a new medal is saved at once; run counts follow with the autosave
	end

	local bestMedal = math.max(previousMedal, medal)
	local nextMedal = if StageConfig.Medals[bestMedal + 1] then bestMedal + 1 else nil
	return {
		stageKey = stageKey,
		displayName = stage.displayName,
		time = elapsed,
		best = profile.BestTimes[stageKey],
		newBest = newBest,
		medal = medal,
		bestMedal = bestMedal,
		coins = coins,
		runCoins = runCoins,
		runsToday = earlierFinishes + 1,
		nextMedal = nextMedal,
		nextThreshold = nextMedal and StageConfig.Threshold(stage, nextMedal),
	}
end

-- Re-sends the medal attributes, e.g. after the profile was reset
StageResults.PublishMedals = publishMedals

Players.PlayerAdded:Connect(publishMedals)
for _, player in Players:GetPlayers() do
	task.spawn(publishMedals, player)
end

return StageResults
