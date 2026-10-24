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

-- `stage` is the StageConfig key; ids are `<stage folder>_<n>` (renamed with the stages on 2026-10-22: Island Hop's coins are Stage1_n, the old Stage 1's Stage2_n, Blink's Stage3_n, the old Stage 2's Stage4_n, the old Stage 3's Stage5_n).
ChallengeCoinConfig.Coins = {
	{ id = "Tutorial_1", stage = "Tutorial", tier = "Risky" },
	{ id = "Tutorial_2", stage = "Tutorial", tier = "Risky" },
	{ id = "Tutorial_3", stage = "Tutorial", tier = "Easy" }, -- the only coin behind a score board. Retired ids, never reuse: Stage2_1, Stage4_1, Stage5_1 (the other boards' coins were removed)
	{ id = "Stage1_1", stage = "Stage1", tier = "Easy" },
	{ id = "Stage1_2", stage = "Stage1", tier = "Easy" },
	{ id = "Stage1_3", stage = "Stage1", tier = "Easy" },
	{ id = "Stage1_4", stage = "Stage1", tier = "Easy" },
	{ id = "Stage1_5", stage = "Stage1", tier = "Risky" },
	{ id = "Stage1_6", stage = "Stage1", tier = "Risky" },
	{ id = "Stage1_7", stage = "Stage1", tier = "Talent" },
	{ id = "Stage3_1", stage = "Stage3", tier = "Easy" },
	{ id = "Stage3_2", stage = "Stage3", tier = "Easy" },
	{ id = "Stage3_3", stage = "Stage3", tier = "Easy" },
	{ id = "Stage3_4", stage = "Stage3", tier = "Easy" },
	{ id = "Stage3_5", stage = "Stage3", tier = "Easy" },
	{ id = "Stage3_6", stage = "Stage3", tier = "Risky" },
	{ id = "Stage3_7", stage = "Stage3", tier = "Risky" },
	{ id = "Stage3_8", stage = "Stage3", tier = "Talent" },
	{ id = "Stage2_2", stage = "Stage2", tier = "Easy" },
	{ id = "Stage2_3", stage = "Stage2", tier = "Easy" },
	{ id = "Stage2_4", stage = "Stage2", tier = "Easy" },
	{ id = "Stage2_5", stage = "Stage2", tier = "Easy" },
	{ id = "Stage2_6", stage = "Stage2", tier = "Risky" },
	{ id = "Stage2_7", stage = "Stage2", tier = "Risky" },
	{ id = "Stage2_8", stage = "Stage2", tier = "Talent" },
	{ id = "Stage4_2", stage = "Stage4", tier = "Easy" },
	{ id = "Stage4_3", stage = "Stage4", tier = "Easy" },
	{ id = "Stage4_4", stage = "Stage4", tier = "Easy" },
	{ id = "Stage4_5", stage = "Stage4", tier = "Easy" },
	{ id = "Stage4_6", stage = "Stage4", tier = "Risky" },
	{ id = "Stage4_7", stage = "Stage4", tier = "Risky" },
	{ id = "Stage4_8", stage = "Stage4", tier = "Talent" },
	{ id = "Stage4_9", stage = "Stage4", tier = "Talent" },
	{ id = "Stage5_2", stage = "Stage5", tier = "Easy" },
	{ id = "Stage5_3", stage = "Stage5", tier = "Easy" },
	{ id = "Stage5_4", stage = "Stage5", tier = "Easy" },
	{ id = "Stage5_5", stage = "Stage5", tier = "Easy" },
	{ id = "Stage5_6", stage = "Stage5", tier = "Risky" },
	{ id = "Stage5_7", stage = "Stage5", tier = "Risky" },
	{ id = "Stage5_8", stage = "Stage5", tier = "Talent" },
	{ id = "Stage5_9", stage = "Stage5", tier = "Talent" },
	{ id = "Stage5_10", stage = "Stage5", tier = "Talent" },
	{ id = "Stage6_1", stage = "Stage6", tier = "Easy" },
	{ id = "Stage6_2", stage = "Stage6", tier = "Easy" },
	{ id = "Stage6_3", stage = "Stage6", tier = "Easy" },
	{ id = "Stage6_4", stage = "Stage6", tier = "Easy" },
	{ id = "Stage6_5", stage = "Stage6", tier = "Easy" },
	{ id = "Stage6_6", stage = "Stage6", tier = "Risky" },
	{ id = "Stage6_7", stage = "Stage6", tier = "Risky" },
	{ id = "Stage6_8", stage = "Stage6", tier = "Talent" }, -- needs Double Jump plus Jump Height 2-3 (the stage itself requires Double Jump)
	{ id = "Stage7_1", stage = "Stage7", tier = "Easy" },
	{ id = "Stage7_2", stage = "Stage7", tier = "Easy" },
	{ id = "Stage7_3", stage = "Stage7", tier = "Easy" },
	{ id = "Stage7_4", stage = "Stage7", tier = "Easy" },
	{ id = "Stage7_5", stage = "Stage7", tier = "Easy" },
	{ id = "Stage7_6", stage = "Stage7", tier = "Risky" },
	{ id = "Stage7_7", stage = "Stage7", tier = "Risky" },
	{ id = "Stage7_8", stage = "Stage7", tier = "Talent" },
	{ id = "Stage8_1", stage = "Stage8", tier = "Easy" },
	{ id = "Stage8_2", stage = "Stage8", tier = "Easy" },
	{ id = "Stage8_3", stage = "Stage8", tier = "Easy" },
	{ id = "Stage8_4", stage = "Stage8", tier = "Easy" },
	{ id = "Stage8_5", stage = "Stage8", tier = "Easy" },
	{ id = "Stage8_6", stage = "Stage8", tier = "Risky" },
	{ id = "Stage8_7", stage = "Stage8", tier = "Risky" },
	{ id = "Stage8_8", stage = "Stage8", tier = "Talent" },
	{ id = "Stage9_1", stage = "Stage9", tier = "Easy" },
	{ id = "Stage9_2", stage = "Stage9", tier = "Easy" },
	{ id = "Stage9_3", stage = "Stage9", tier = "Easy" },
	{ id = "Stage9_4", stage = "Stage9", tier = "Easy" },
	{ id = "Stage9_5", stage = "Stage9", tier = "Easy" },
	{ id = "Stage9_6", stage = "Stage9", tier = "Risky" },
	{ id = "Stage9_7", stage = "Stage9", tier = "Risky" },
	{ id = "Stage9_8", stage = "Stage9", tier = "Talent" },
	{ id = "Stage10_1", stage = "Stage10", tier = "Easy" },
	{ id = "Stage10_2", stage = "Stage10", tier = "Easy" },
	{ id = "Stage10_3", stage = "Stage10", tier = "Easy" },
	{ id = "Stage10_4", stage = "Stage10", tier = "Easy" },
	{ id = "Stage10_5", stage = "Stage10", tier = "Easy" },
	{ id = "Stage10_6", stage = "Stage10", tier = "Risky" },
	{ id = "Stage10_7", stage = "Stage10", tier = "Risky" },
	{ id = "Stage10_8", stage = "Stage10", tier = "Talent" },
	{ id = "Stage11_1", stage = "Stage11", tier = "Easy" },
	{ id = "Stage11_2", stage = "Stage11", tier = "Easy" },
	{ id = "Stage11_3", stage = "Stage11", tier = "Easy" },
	{ id = "Stage11_4", stage = "Stage11", tier = "Easy" },
	{ id = "Stage11_5", stage = "Stage11", tier = "Easy" },
	{ id = "Stage11_6", stage = "Stage11", tier = "Risky" },
	{ id = "Stage11_7", stage = "Stage11", tier = "Risky" },
	{ id = "Stage11_8", stage = "Stage11", tier = "Talent" }, -- 24.5 studs out from the summit: Triple Jump plus Run Speed 4-5, or Dash
	{ id = "Stage12_1", stage = "Stage12", tier = "Easy" },
	{ id = "Stage12_2", stage = "Stage12", tier = "Easy" },
	{ id = "Stage12_3", stage = "Stage12", tier = "Easy" },
	{ id = "Stage12_4", stage = "Stage12", tier = "Easy" },
	{ id = "Stage12_5", stage = "Stage12", tier = "Easy" },
	{ id = "Stage12_6", stage = "Stage12", tier = "Risky" },
	{ id = "Stage12_7", stage = "Stage12", tier = "Risky" },
	{ id = "Stage12_8", stage = "Stage12", tier = "Talent" }, -- beside the last ice ledge, like Stage11_8
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
