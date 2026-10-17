-- StageResults: what a finished run earns — personal best, medal and one-time Coin payouts (docs/GDD.md §4–5).
-- Server-only. Medals are mirrored to player attributes (StageConfig.MedalAttribute) for client displays.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local StageConfig = require(ReplicatedStorage.StageConfig)
local PlayerProfile = require(ServerScriptService.PlayerProfile)

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

-- Records a finished run and returns the result for the results popup, or nil if the profile is not loaded:
-- { stageKey, displayName, time, best, newBest, medal (this run), bestMedal, coins, nextMedal?, nextThreshold? }
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
		coins = StageConfig.Payout(stage, previousMedal, medal)
		profile.Medals[stageKey] = medal
		player:SetAttribute(StageConfig.MedalAttribute(stage), medal)
		PlayerProfile.AddCoins(player, coins)
		task.spawn(PlayerProfile.Save, player)
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
		nextMedal = nextMedal,
		nextThreshold = nextMedal and StageConfig.Threshold(stage, nextMedal),
	}
end

Players.PlayerAdded:Connect(publishMedals)
for _, player in Players:GetPlayers() do
	task.spawn(publishMedals, player)
end

return StageResults
