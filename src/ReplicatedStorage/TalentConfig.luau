-- TalentConfig: talents bought with Coins and a crop bundle from the barn (GDD §6; bundles since EV2b). Shared: the server validates and prices purchases from this
-- table only (clients never send a price), the skills panel renders it. Pure data + helpers, no side effects.
-- Talent ids are stored in PlayerProfile.Talents and as Talent_<id> player attributes: never rename them.

local Num = require(script.Parent:WaitForChild("Num"))

local TalentConfig = {}

export type Talent = {
	id: string,
	name: string,
	costs: { number }, -- costs[n] = price of level n; #costs = max level
	crops: { [number]: { [string]: number } }?, -- crops[n] = { [cropId] = count } taken from the barn with costs[n] (EV2b)
	perLevel: number, -- effect per level as a fraction
	effect: string, -- panel text for one level
	effects: { string }?, -- panel text per level when the levels differ (effects[n] = what buying level n gives)
	names: { string }?, -- name per level when a level reads as a talent of its own (names[n] = name of level n; S7 Triple Jump)
	rewards: { [number]: number }?, -- world rewards (K1): rewards[n] = world whose opening grants level n; such a level is never sold
}

TalentConfig.List = {
	{ id = "RunSpeed", name = "Run Speed", costs = { 800, 1400, 2600, 4500, 8000 }, crops = { [2] = { Garlic = 12 }, [3] = { Cucumber = 12 }, [4] = { Corn = 15 }, [5] = { Pepper = 15 } }, perLevel = 0.06, effect = "+6% run speed" }, -- loc: ignore (English source and fallback; players see Locale)
	{
		id = "DoubleJump",
		name = "Double Jump", -- loc: ignore (English source and fallback; players see Locale)
		costs = { 0, 16000 }, -- level 1 is a world reward (3 000 until 2026-11-01, 1 500 until 2026-10-23; GDD §6); level 2 = Triple Jump (S7; 5 000 until EV2b)
		crops = { [2] = { Cucumber = 20, FrostGrape = 1 } },
		rewards = { [1] = 2 }, -- granted when World 2 opens (K1)
		perLevel = 1,
		effect = "1 extra jump in the air", -- loc: ignore (English source and fallback; players see Locale)
		effects = { "1 extra jump in the air", "A second extra jump in the air" }, -- loc: ignore (English source and fallback; players see Locale)
		names = { "Double Jump", "Triple Jump" }, -- loc: ignore (English source and fallback; players see Locale)
	},
	{ id = "JumpHeight", name = "Jump Height", costs = { 1100, 1900, 6500 }, crops = { [2] = { Cucumber = 12 }, [3] = { Pepper = 15 } }, perLevel = 0.08, effect = "+8% jump height" }, -- loc: ignore (English source and fallback; players see Locale)
	{
		id = "QuickRespawn",
		name = "Quick Respawn", -- loc: ignore (English source and fallback; players see Locale)
		costs = { 1100, 10000 },
		crops = { [1] = { Tomato = 12 }, [2] = { Broccoli = 15 } },
		perLevel = 1,
		effect = "faster respawn", -- loc: ignore (English source and fallback; players see Locale)
		effects = { "Respawn after 1 s", "Instant respawn + fall reset" }, -- loc: ignore (English source and fallback; players see Locale)
	},
	{
		id = "Dash",
		name = "Dash", -- loc: ignore (English source and fallback; players see Locale)
		costs = { 12000, 29000 }, -- S7 (STAGES §6.2 / §7.10); 5 000 / 3 000 until EV2b (8 000 for level 1 until S8.2 added Long Dash, §7.12)
		crops = { [1] = { Corn = 20 }, [2] = { Pepper = 20, GlowMushroom = 1 } },
		perLevel = 1,
		effect = "A burst forward in the air (Q)", -- loc: ignore (English source and fallback; players see Locale)
		effects = { "A burst forward in the air (Q)", "The burst goes farther" }, -- loc: ignore (English source and fallback; players see Locale)
		names = { "Dash", "Long Dash" }, -- loc: ignore (English source and fallback; players see Locale)
	},
} :: { Talent }

TalentConfig.ById = {} :: { [string]: Talent }
for _, talent in TalentConfig.List do
	TalentConfig.ById[talent.id] = talent
end

function TalentConfig.AttributeName(id: string): string
	return "Talent_" .. id
end

function TalentConfig.MaxLevel(id: string): number
	return #TalentConfig.ById[id].costs
end

-- Clamps whatever is stored or replicated to a valid whole level (corrupt data counts as 0).
function TalentConfig.ClampLevel(id: string, level: any): number
	local talent = TalentConfig.ById[id]
	return if talent then Num.Level(level, 0, #talent.costs, 0) else 0
end

-- The player's level of talent `id` in a profile (PlayerProfile.Talents), clamped to a valid level. Server.
function TalentConfig.LevelOf(profile, id: string): number
	return TalentConfig.ClampLevel(id, type(profile.Talents) == "table" and profile.Talents[id] or 0)
end

-- The world whose opening grants `level` of the talent (never sold), or nil when that level is bought.
function TalentConfig.RewardWorld(id: string, level: number): number?
	local rewards = TalentConfig.ById[id].rewards
	return rewards and rewards[level]
end

-- Price of the next level, or nil when the talent is maxed (0 for a world reward: check RewardWorld first).
function TalentConfig.NextCost(id: string, level: number): number?
	return TalentConfig.ById[id].costs[level + 1]
end

-- Crops the next level takes from the barn ({ [cropId] = count }; empty when none or maxed).
function TalentConfig.NextCrops(id: string, level: number): { [string]: number }
	local crops = TalentConfig.ById[id].crops
	return crops and crops[level + 1] or {}
end

-- Multiplier on the base WalkSpeed (16 → 20.8 at level 5).
function TalentConfig.WalkSpeedFactor(level: number): number
	return 1 + TalentConfig.ById.RunSpeed.perLevel * level
end

-- Multiplier on jump height. JumpPower scales with the square root of it.
function TalentConfig.JumpHeightFactor(level: number): number
	return 1 + TalentConfig.ById.JumpHeight.perLevel * level
end

-- Seconds to wait after a death before the character is loaded again (STAGES §6.2.1): `defaultDelay` (the place's
-- Players.RespawnTime) without the talent, 1 s at level 1, none at level 2.
function TalentConfig.RespawnDelay(level: number, defaultDelay: number): number
	if level >= 2 then
		return 0
	elseif level == 1 then
		return math.min(1, defaultDelay)
	end
	return defaultDelay
end

-- True when the talent resets a lost (falling) character to its checkpoint (level 2).
function TalentConfig.HasFallReset(level: number): boolean
	return level >= 2
end

-- Name of `level` of a talent with per-level names (English fallback; players see Locale.TalentName), else its name.
function TalentConfig.LevelName(talent: Talent, level: number): string
	return talent.names and talent.names[math.clamp(level, 1, #talent.names)] or talent.name
end

-- Dash (S7, STAGES §7.10): a flat burst in the air, once per air time. Long Dash (level 2, S8.2, STAGES §7.12) lasts longer
-- at the same speed: a faster burst would move the character more than a stud per frame and could pass a thin kill beam
-- between two of ObstacleKit's touch tests.
TalentConfig.DashSpeed = 50 -- studs per second
TalentConfig.DashTimes = { 0.2, 0.32 } -- seconds per level: about 10 / 16 studs

function TalentConfig.HasDash(level: number): boolean
	return level >= 1
end

-- Seconds a dash lasts at `level` (0 without the talent).
function TalentConfig.DashTime(level: number): number
	return TalentConfig.DashTimes[math.clamp(level, 0, #TalentConfig.DashTimes)] or 0
end

-- Extra jumps allowed in the air.
function TalentConfig.AirJumps(level: number): number
	return TalentConfig.ById.DoubleJump.perLevel * level
end

return TalentConfig
