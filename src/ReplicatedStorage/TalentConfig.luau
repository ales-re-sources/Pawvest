-- TalentConfig: talents bought with Coins (GDD §6). Shared: the server validates and prices purchases from this
-- table only (clients never send a price), the skills panel renders it. Pure data + helpers, no side effects.
-- Talent ids are stored in PlayerProfile.Talents and as Talent_<id> player attributes: never rename them.

local TalentConfig = {}

export type Talent = {
	id: string,
	name: string,
	costs: { number }, -- costs[n] = price of level n; #costs = max level
	perLevel: number, -- effect per level as a fraction
	effect: string, -- panel text for one level
}

TalentConfig.List = {
	{ id = "RunSpeed", name = "Run Speed", costs = { 200, 400, 600, 900, 1300 }, perLevel = 0.06, effect = "+6% run speed" },
	{ id = "DoubleJump", name = "Double Jump", costs = { 1500 }, perLevel = 1, effect = "1 extra jump in the air" },
	{ id = "JumpHeight", name = "Jump Height", costs = { 300, 600, 1000 }, perLevel = 0.08, effect = "+8% jump height" },
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
	if not talent or type(level) ~= "number" or level ~= level then
		return 0
	end
	return math.clamp(math.floor(level), 0, #talent.costs)
end

-- Price of the next level, or nil when the talent is maxed.
function TalentConfig.NextCost(id: string, level: number): number?
	return TalentConfig.ById[id].costs[level + 1]
end

-- Multiplier on the base WalkSpeed (16 → 20.8 at level 5).
function TalentConfig.WalkSpeedFactor(level: number): number
	return 1 + TalentConfig.ById.RunSpeed.perLevel * level
end

-- Multiplier on jump height. JumpPower scales with the square root of it.
function TalentConfig.JumpHeightFactor(level: number): number
	return 1 + TalentConfig.ById.JumpHeight.perLevel * level
end

-- Extra jumps allowed in the air.
function TalentConfig.AirJumps(level: number): number
	return TalentConfig.ById.DoubleJump.perLevel * level
end

return TalentConfig
