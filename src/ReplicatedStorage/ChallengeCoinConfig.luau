-- ChallengeCoinConfig: challenge coins placed off the main path (docs/GDD.md §5). Shared by server and client.
-- Each coin is a Studio-only part tagged `Tag` with the attribute `IdAttribute` = its id; its value comes from the tier
-- here, never from the part. Ids are stored in PlayerProfile.CollectedCoins: never rename or reuse one.
-- Collected ids replicate to clients as the player attribute `CollectedAttribute` (Encode / Decode).

local ChallengeCoinConfig = {}

ChallengeCoinConfig.Tag = "ChallengeCoin"
ChallengeCoinConfig.IdAttribute = "CoinId"
ChallengeCoinConfig.CollectedAttribute = "CollectedCoins"

-- Base Coins per tier (paid through CoinRewards, so the pet multiplier applies)
ChallengeCoinConfig.Tiers = {
	Easy = 20, -- off the main path
	Risky = 50, -- behind a risky jump
	Talent = 100, -- reachable only with a talent (Double Jump)
}

-- `stage` is the StageConfig key.
ChallengeCoinConfig.Coins = {
	{ id = "Tutorial_1", stage = "Stage 4", tier = "Risky" },
	{ id = "Tutorial_2", stage = "Stage 4", tier = "Risky" },
	{ id = "Stage1_1", stage = "Stage 1", tier = "Easy" },
	{ id = "Stage1_2", stage = "Stage 1", tier = "Easy" },
	{ id = "Stage1_3", stage = "Stage 1", tier = "Easy" },
	{ id = "Stage1_4", stage = "Stage 1", tier = "Easy" },
	{ id = "Stage1_5", stage = "Stage 1", tier = "Easy" },
	{ id = "Stage1_6", stage = "Stage 1", tier = "Risky" },
	{ id = "Stage1_7", stage = "Stage 1", tier = "Risky" },
	{ id = "Stage1_8", stage = "Stage 1", tier = "Talent" },
	{ id = "Stage2_1", stage = "Stage 2", tier = "Easy" },
	{ id = "Stage2_2", stage = "Stage 2", tier = "Easy" },
	{ id = "Stage2_3", stage = "Stage 2", tier = "Easy" },
	{ id = "Stage2_4", stage = "Stage 2", tier = "Easy" },
	{ id = "Stage2_5", stage = "Stage 2", tier = "Easy" },
	{ id = "Stage2_6", stage = "Stage 2", tier = "Risky" },
	{ id = "Stage2_7", stage = "Stage 2", tier = "Risky" },
	{ id = "Stage2_8", stage = "Stage 2", tier = "Talent" },
	{ id = "Stage2_9", stage = "Stage 2", tier = "Talent" },
	{ id = "Stage3_1", stage = "Stage 3", tier = "Easy" },
	{ id = "Stage3_2", stage = "Stage 3", tier = "Easy" },
	{ id = "Stage3_3", stage = "Stage 3", tier = "Easy" },
	{ id = "Stage3_4", stage = "Stage 3", tier = "Easy" },
	{ id = "Stage3_5", stage = "Stage 3", tier = "Easy" },
	{ id = "Stage3_6", stage = "Stage 3", tier = "Risky" },
	{ id = "Stage3_7", stage = "Stage 3", tier = "Risky" },
	{ id = "Stage3_8", stage = "Stage 3", tier = "Talent" },
	{ id = "Stage3_9", stage = "Stage 3", tier = "Talent" },
	{ id = "Stage3_10", stage = "Stage 3", tier = "Talent" },
}

ChallengeCoinConfig.ById = {}
ChallengeCoinConfig.ByStage = {} -- [stageKey] = { coin, … }
for _, coin in ChallengeCoinConfig.Coins do
	coin.value = ChallengeCoinConfig.Tiers[coin.tier]
	ChallengeCoinConfig.ById[coin.id] = coin
	ChallengeCoinConfig.ByStage[coin.stage] = ChallengeCoinConfig.ByStage[coin.stage] or {}
	table.insert(ChallengeCoinConfig.ByStage[coin.stage], coin)
end

-- Coins found on `stageKey` (x) and the stage's coin count (y); `collected` is a set [id] = true.
function ChallengeCoinConfig.Found(stageKey: string, collected): (number, number)
	local coins = ChallengeCoinConfig.ByStage[stageKey] or {}
	local found = 0
	for _, coin in coins do
		if collected[coin.id] then
			found += 1
		end
	end
	return found, #coins
end

-- Attribute string of a collected set: known ids only, sorted, comma-separated ("" when none).
function ChallengeCoinConfig.Encode(collected): string
	local ids = {}
	for id, value in collected do
		if value == true and ChallengeCoinConfig.ById[id] then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	return table.concat(ids, ",")
end

-- Set [id] = true from an attribute string (nil or "" → empty set).
function ChallengeCoinConfig.Decode(text: string?)
	local collected = {}
	if type(text) == "string" then
		for id in string.gmatch(text, "[^,]+") do
			collected[id] = true
		end
	end
	return collected
end

return ChallengeCoinConfig
