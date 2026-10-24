-- GateMastery (docs/GDD.md §3 "Mastered stage"): a gold check badge bobs above the start gate of a stage the local player
-- has mastered (Gold medal and every challenge coin, StageMastery); visible across the courtyard. The same badge floats
-- above a hub world gate once every stage of that world is mastered. The gate itself stays as
-- authored. Local to this player (the ticks on the door face come from HubPortalMedals).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local StageMastery = require(ReplicatedStorage:WaitForChild("StageMastery"))

local LocalPlayer = Players.LocalPlayer

local BADGE_GOLD = StageMastery.Gold
local BADGE_INK = StageMastery.Ink
local BADGE_SIZE = 5 -- studs
local BADGE_HEIGHT = 6.2 -- studs above a gate sign
local PORTAL_BADGE_HEIGHT = 9 -- studs above the Tutorial's hub portal
local WORLD_BADGE_HEIGHT = 11 -- studs above the middle of a hub world gate (its arch is 7.7 studs above it)
local BOB = 0.45 -- studs
local VIEW_DISTANCE = 300

local function makeBadge(adornee: BasePart, height: number)
	local badge = Instance.new("BillboardGui")
	badge.Name = "MasteredBadge"
	badge.Adornee = adornee
	badge.Size = UDim2.fromScale(BADGE_SIZE, BADGE_SIZE)
	badge.StudsOffsetWorldSpace = Vector3.new(0, height, 0)
	badge.LightInfluence = 0
	badge.MaxDistance = VIEW_DISTANCE
	badge.ResetOnSpawn = false
	badge.Enabled = false

	local disc = Instance.new("Frame")
	disc.Size = UDim2.fromScale(1, 1)
	disc.BackgroundColor3 = BADGE_GOLD
	disc.Parent = badge
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = disc
	local stroke = Instance.new("UIStroke")
	stroke.Color = BADGE_INK
	stroke.Thickness = 3
	stroke.Parent = disc
	local check = StageMastery.NewCheck(BADGE_INK)
	check.AnchorPoint = Vector2.new(0.5, 0.5)
	check.Position = UDim2.fromScale(0.5, 0.5)
	check.Size = UDim2.fromScale(0.62, 0.62)
	check.Parent = disc

	TweenService:Create(badge, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		StudsOffsetWorldSpace = Vector3.new(0, height + BOB, 0),
	}):Play()
	badge.Parent = adornee
	return badge
end

local function addMastery(stage)
	local gate = StageMastery.WaitGate(stage)
	local sign = gate and gate:FindFirstChild("Sign")

	local badge = sign and makeBadge(sign, BADGE_HEIGHT)
	-- the Tutorial is also entered through its hub portal: a second badge above it
	local portalBadge = if stage.hubPortal then makeBadge(StageConfig.FaceTarget(stage), PORTAL_BADGE_HEIGHT) else nil

	StageMastery.Watch(stage, LocalPlayer, function()
		local mastered = StageMastery.Goals(stage, LocalPlayer).mastered
		if badge then
			badge.Enabled = mastered
		end
		if portalBadge then
			portalBadge.Enabled = mastered
		end
	end)
end

for _, stage in StageConfig.Stages do
	if stage.hubPortal or StageConfig.Worlds[stage.world] then
		task.spawn(addMastery, stage)
	end
end

-- A hub world gate: the badge shows once every stage of the world is mastered.
local function addWorldMastery(world)
	local badge = makeBadge(StageConfig.WorldGatePortal(world), WORLD_BADGE_HEIGHT)
	StageMastery.WatchWorld(world.index, LocalPlayer, function()
		badge.Enabled = StageMastery.WorldGoals(world.index, LocalPlayer).mastered
	end)
end

for _, world in StageConfig.Worlds do
	if not world.soon then
		task.spawn(addWorldMastery, world)
	end
end
