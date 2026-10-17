-- StageConfig: single source of truth for stages (docs/GDD.md §3–5). Shared by server and client.
-- `key` is the DataStore key (best times, leaderboards, medals) and must never change for an existing stage.

local StageConfig = {}

StageConfig.HubName = "Central Island"

-- Medal thresholds as multiples of tBase (GDD §4); a stage may point `tiers` at its own table.
StageConfig.DefaultTiers = { Bronze = 1.6, Silver = 1.1, Gold = 0.8 }

StageConfig.Stages = {
	{
		key = "Stage 4", -- legacy key of the Tutorial, kept so recorded times are not lost
		displayName = "Tutorial",
		folder = "Tutorial", -- stage folder in Workspace
		hubPortal = nil, -- added in M3
		order = 0,
		tBase = nil, -- seconds; measured in M6
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
		tBase = nil,
		tiers = StageConfig.DefaultTiers,
		unlock = nil,
		unlockPrice = nil,
		rewardFactor = 1.0,
	},
	{
		key = "Stage 2",
		displayName = "Stage 2",
		folder = "Stage2",
		hubPortal = "TeleportToStage2",
		order = 2,
		tBase = nil,
		tiers = StageConfig.DefaultTiers,
		unlock = { stage = "Stage 1", medal = "Silver" },
		unlockPrice = 150,
		rewardFactor = 1.5,
	},
	{
		key = "Stage 3",
		displayName = "Stage 3",
		folder = "Stage3",
		hubPortal = "TeleportToStage3",
		order = 3,
		tBase = nil,
		tiers = StageConfig.DefaultTiers,
		unlock = { stage = "Stage 2", medal = "Silver" },
		unlockPrice = 300,
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

return StageConfig
