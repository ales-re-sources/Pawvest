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

-- Per stage: `world` (1–4, GDD §3) and `requires` = { { id = <talent id>, level = <n> }, … } (talents the course needs;
-- shown as a hint and warning, never enforced). `order` is the position in the game. Since 2026-10-22 the key and the folder of
-- a world stage are its position ("Stage1" … "Stage5", docs/STAGES.md §7.4); the stage folders live in the world's folder
-- (Workspace.World1.Stage1 …), the Tutorial's in Workspace. `unlock` is { stage = <key>, medal = <tier> } or
-- { world = <n>, stars = <n> } (stars summed over that world's stages, GDD §3).
StageConfig.Stages = {
	{
		key = "Tutorial", -- DataStore key of times, medals and the board: never changes again without migrating the stored profiles
		displayName = "Tutorial",
		folder = "Tutorial", -- stage folder in Workspace
		hubPortal = "TeleportToTutorial",
		order = 0,
		world = 0, -- a hub stage: the Tutorial belongs to no world
		requires = {},
		tBase = 30, -- seconds; provisional until measured in M6
		tiers = StageConfig.DefaultTiers,
		unlock = nil, -- nil = always open; otherwise { stage = <key>, medal = <tier> }
		unlockPrice = nil,
		rewardFactor = 0.5,
	},
	{
		key = "Stage1", -- Island Hop
		displayName = "Stage 1",
		folder = "Stage1",
		order = 1,
		world = 1,
		requires = {},
		tBase = 52, -- seconds; provisional until measured in M6a
		tiers = StageConfig.DefaultTiers,
		unlock = { stage = "Tutorial", medal = "Bronze" },
		unlockPrice = 200, -- a small price on purpose: Coins cannot be earned without a medal (a finish without one pays nothing), so this is a shortcut for later purchases (e.g. Coin packs), not a path for new players
		rewardFactor = 0.75, -- curve 0.5 + 0.25 × order (GDD §5)
	},
	{
		key = "Stage2", -- the variety stage (lasers, spinners, lava, choice steps)
		displayName = "Stage 2",
		folder = "Stage2",
		order = 2,
		world = 1,
		requires = {},
		tBase = 70,
		tiers = StageConfig.DefaultTiers,
		unlock = { stage = "Stage1", medal = "Bronze" },
		unlockPrice = 1000,
		rewardFactor = 1.0,
	},
	{
		key = "Stage3", -- Blink, the rhythm special (docs/STAGES.md §5.2, §7.7)
		displayName = "Stage 3",
		folder = "Stage3",
		order = 3,
		world = 1,
		requires = {},
		tBase = 60, -- seconds; provisional until measured in M6a (a perfect run takes about 40 s)
		tiers = StageConfig.DefaultTiers,
		unlock = { stage = "Stage2", medal = "Bronze" },
		unlockPrice = 1500,
		rewardFactor = 1.25, -- curve 0.5 + 0.25 × order (GDD §5)
	},
	{
		key = "Stage4", -- bounce corridors
		displayName = "Stage 4",
		folder = "Stage4",
		order = 4,
		world = 1,
		requires = {},
		tBase = 100,
		tiers = StageConfig.DefaultTiers,
		unlock = { stage = "Stage3", medal = "Bronze" },
		unlockPrice = 2000,
		rewardFactor = 1.5,
	},
	{
		key = "Stage5", -- the precision finale
		displayName = "Stage 5",
		folder = "Stage5",
		order = 5,
		world = 1,
		requires = {},
		tBase = 120,
		tiers = StageConfig.DefaultTiers,
		unlock = { stage = "Stage4", medal = "Bronze" },
		unlockPrice = 2000,
		rewardFactor = 1.75, -- curve 0.5 + 0.25 × order (GDD §5)
	},
	{
		key = "Stage6", -- Double Up (World 2, docs/STAGES.md §7.9): Double Jump gaps and ledges, lifts, slide movers
		displayName = "Stage 6",
		folder = "Stage6",
		order = 6,
		world = 2,
		requires = { { id = "DoubleJump", level = 1 } },
		tBase = 90, -- seconds; provisional until measured in M6b
		tiers = StageConfig.DefaultTiers,
		unlock = { world = 1, stars = 10 }, -- the world opener: 10 of the 15 stars of World 1
		unlockPrice = 2500,
		rewardFactor = 2.0, -- curve 0.5 + 0.25 × order (GDD §5)
	},
	{
		key = "Stage7", -- Seesaw: kit-local tilt plates, crosswind, crumbling rests
		displayName = "Stage 7",
		folder = "Stage7",
		order = 7,
		world = 2,
		requires = { { id = "DoubleJump", level = 1 } },
		tBase = 100,
		tiers = StageConfig.DefaultTiers,
		unlock = { stage = "Stage6", medal = "Bronze" },
		unlockPrice = 3000,
		rewardFactor = 2.25,
	},
	{
		key = "Stage8", -- Turntable: turntables, sweeper bars, flippers, flat windmills
		displayName = "Stage 8",
		folder = "Stage8",
		order = 8,
		world = 2,
		requires = { { id = "DoubleJump", level = 1 } },
		tBase = 105,
		tiers = StageConfig.DefaultTiers,
		unlock = { stage = "Stage7", medal = "Bronze" },
		unlockPrice = 3000,
		rewardFactor = 2.5,
	},
	{
		key = "Stage9", -- Labyrinth (special): two shifting mazes under an iso camera, Double Jump hedge shortcuts
		displayName = "Stage 9",
		folder = "Stage9",
		order = 9,
		world = 2,
		requires = { { id = "DoubleJump", level = 1 } },
		tBase = 105,
		tiers = StageConfig.DefaultTiers,
		unlock = { stage = "Stage8", medal = "Bronze" },
		unlockPrice = 3500,
		rewardFactor = 2.75,
	},
	{
		key = "Stage10", -- Clocktower (World 2 finale): a three-lap climb round a tower, everything on a 1 s clock tick
		displayName = "Stage 10",
		folder = "Stage10",
		order = 10,
		world = 2,
		requires = { { id = "DoubleJump", level = 1 } },
		tBase = 90, -- 135 in S6.3: a first run with several deaths still got Silver, and AhojRupert's best is 65.9 s (Gold now < 72 s)
		tiers = StageConfig.DefaultTiers,
		unlock = { stage = "Stage9", medal = "Bronze" },
		unlockPrice = 4000,
		rewardFactor = 3.0,
	},
}

-- Worlds (docs/STAGES.md §7.1): `stage.world` 1..n; a world is a courtyard in Workspace.<folder> (plaza, wall, return portal)
-- with a `spawn` part, the stage pads stand on it, and a gate model <gate> in Workspace.StartLocation (the hub) leads there.
-- The Tutorial is world 0 (the hub).
-- `soon = true` (S5): the world's stages are not built yet (not in StageConfig.Stages): its gate stays shut for everyone but admins,
-- the face reads "Coming soon" and the future requirement (`unlock` / `unlockPrice`, informational until S6 copies them onto the world's
-- first stage), `stageCount` = planned stages (5 per world, so the score panel and the gate show x / 15).
StageConfig.Worlds = {
	[1] = { name = "World 1", gate = "GateWorld1", folder = "World1", spawn = "Spawn" },
	[2] = { name = "World 2", gate = "GateWorld2", folder = "World2", spawn = "Spawn", stageCount = 5 },
	[3] = { name = "World 3", gate = "GateWorld3", folder = "World3", spawn = "Spawn", soon = true, stageCount = 5,
		unlock = { world = 2, stars = 10 }, unlockPrice = 4000 },
	[4] = { name = "World 4", gate = "GateWorld4", folder = "World4", spawn = "Spawn", soon = true, stageCount = 5,
		unlock = { world = 3, stars = 10 }, unlockPrice = 6000 },
}
StageConfig.WorldByGate = {}
StageConfig.WorldByName = {}
StageConfig.WorldByFolder = {}
for index, world in StageConfig.Worlds do
	world.index = index
	StageConfig.WorldByGate[world.gate] = world
	StageConfig.WorldByName[world.name] = world
	StageConfig.WorldByFolder[world.folder] = world
end

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

-- Returns the stage whose folder contains `instance` (e.g. a script inside Workspace.World1.Stage2), and that folder. A stage
-- folder is the nearest ancestor named like a stage's `folder` whose parent is Workspace (hub stage) or a world folder.
function StageConfig.ForInstance(instance: Instance)
	local node = instance
	while node and node ~= workspace do
		local stage = StageConfig.ByFolder[node.Name]
		local parent = node.Parent
		if stage and parent and (parent == workspace or StageConfig.WorldByFolder[parent.Name]) then
			return stage, node
		end
		node = parent
	end
	error("StageConfig: no stage folder above " .. instance:GetFullName())
end

-- The folder of `stage` in the scene: Workspace.<world folder>.<stage folder> for a world stage, Workspace.<folder> for the hub
-- stage. StageFolder waits for the scene to load; FindStageFolder returns nil when it is not there (yet).
function StageConfig.StageFolder(stage): Instance
	local world = StageConfig.Worlds[stage.world]
	if world then
		return workspace:WaitForChild(world.folder):WaitForChild(stage.folder)
	end
	return workspace:WaitForChild(stage.folder)
end

function StageConfig.FindStageFolder(stage): Instance?
	local world = StageConfig.Worlds[stage.world]
	local parent = if world then workspace:FindFirstChild(world.folder) else workspace
	return parent and parent:FindFirstChild(stage.folder)
end

-- The part whose face shows a stage's stars, coins and lock lines: the Door of its start gate for a world stage (S4.0: the
-- stage lies physically behind the gate), the hub portal for a hub stage (the Tutorial). Waits for the scene to load.
function StageConfig.FaceTarget(stage): BasePart
	if StageConfig.Worlds[stage.world] then
		return StageConfig.StageFolder(stage):WaitForChild("Gate"):WaitForChild("Door")
	end
	return workspace:WaitForChild("StartLocation"):WaitForChild(stage.hubPortal):WaitForChild("Portal")
end

-- The stages of world `index`, in game order. A world's hub gate is open for a player when any of them is open (the first one
-- opens with the Tutorial medal or its price), so a player is never sent to a courtyard whose gates are all shut.
function StageConfig.StagesOfWorld(index: number)
	local list = {}
	for _, stage in StageConfig.Stages do
		if stage.world == index then
			table.insert(list, stage)
		end
	end
	return list
end

-- The gate part (the Portal of the world's hub gate model) a player touches to travel to the world.
function StageConfig.WorldGatePortal(world): BasePart
	return workspace:WaitForChild("StartLocation"):WaitForChild(world.gate):WaitForChild("Portal")
end

-- Score-panel key of the place a stage returns to: its world's name, or StageConfig.HubName for a hub stage.
function StageConfig.LocationKey(stage): string
	local world = StageConfig.Worlds[stage.world]
	return if world then world.name else StageConfig.HubName
end

-- The part a player is teleported to when leaving `stage` (finish, Home button): the plaza in front of the stage's own gate
-- (its Arrival marker) for a world stage, the hub's SpawnLocation for a hub stage. Waits for the scene.
function StageConfig.ReturnSpawn(stage): BasePart
	if StageConfig.Worlds[stage.world] then
		return StageConfig.StageFolder(stage):WaitForChild("Arrival")
	end
	return workspace:WaitForChild("StartLocation"):WaitForChild("SpawnLocation")
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
	if rule.world then
		return StageConfig.WorldStars(medals, rule.world) >= rule.stars
	end
	return (medals[rule.stage] or 0) >= StageConfig.MedalIndex[rule.medal]
end

-- The `requires` entries of `stage` that the player does not meet; `levelOf(talentId)` is the player's talent level.
function StageConfig.MissingTalents(stage, levelOf: (string) -> number)
	local missing = {}
	for _, need in stage.requires do
		if levelOf(need.id) < need.level then
			table.insert(missing, need)
		end
	end
	return missing
end

-- Stars (medal indices) summed over the stages of `world` for `medals` ([stageKey] = medal index).
function StageConfig.WorldStars(medals, world: number): number
	local stars = 0
	for _, stage in StageConfig.Stages do
		if stage.world == world then
			stars += math.clamp(medals[stage.key] or 0, 0, #StageConfig.Medals)
		end
	end
	return stars
end

-- Most stars a world can give (3 per stage; a world whose stages are not built yet counts its planned stages).
function StageConfig.MaxWorldStars(world: number): number
	local count = 0
	for _, stage in StageConfig.Stages do
		if stage.world == world then
			count += 1
		end
	end
	local planned = StageConfig.Worlds[world] and StageConfig.Worlds[world].stageCount or 0
	return math.max(count, planned) * #StageConfig.Medals
end

-- Stars (medal indices) summed over all stages for `medals` ([stageKey] = medal index); the hub score panel and the
-- hub "most stars" board both use it.
function StageConfig.TotalStars(medals): number
	local stars = 0
	for _, stage in StageConfig.Stages do
		stars += math.clamp(medals[stage.key] or 0, 0, #StageConfig.Medals)
	end
	return stars
end

-- Most stars a player can have (3 per stage).
function StageConfig.MaxStars(): number
	return #StageConfig.Stages * #StageConfig.Medals
end

-- Player attribute that replicates whether the player may enter `stage` (bar met or bought).
function StageConfig.UnlockedAttribute(stage): string
	return "Unlocked_" .. stage.folder
end

return StageConfig
