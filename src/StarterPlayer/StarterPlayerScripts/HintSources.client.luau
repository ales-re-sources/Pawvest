-- Hint sources, phase 1 (docs/GDD.md §11, ROADMAP G1); Hints.luau draws them.
--   Next stage: the first stage in game order that is open and has no medal. A "Next" marker above its start gate sign while
--     the player is in that stage's courtyard (the Tutorial: near its landing pad), above its hub entrance (world gate /
--     the Tutorial's hub portal) while the player is in the hub.
--   Skills: a dot on the Skills icon when a talent level became affordable that was not affordable while the panel was open.
--   Ready egg: a dot on the Pets icon and "Go to my garden", a "Ready!" marker above the incubator while in the garden, and a
--     toast once per egg.
-- Display only: reads attributes, leaderstats and the own plot's incubator models.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local StageMastery = require(ReplicatedStorage:WaitForChild("StageMastery"))
local TalentConfig = require(ReplicatedStorage:WaitForChild("TalentConfig"))
local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local Hints = require(script.Parent:WaitForChild("Hints"))

local player = Players.LocalPlayer

local GATE_MARKER_HEIGHT = 6 -- studs above a gate sign (where GateMastery's badge would be; a "next" stage is never mastered)
local PORTAL_MARKER_HEIGHT = 9 -- studs above the Tutorial's hub portal
local WORLD_MARKER_HEIGHT = 11 -- studs above a hub world gate's portal
local INCUBATOR_MARKER_GAP = 5 -- studs above the top of an incubator model
local AREA_MARGIN = 15 -- studs around an area's parts that still count as inside
local TUTORIAL_RADIUS = 60 -- studs (horizontal) from the Tutorial's start gate

-- Areas -------------------------------------------------------------------------------------------------------------------

-- XZ rectangle around every part of `container`, grown by AREA_MARGIN.
local function rectOf(container: Instance?)
	if not container then
		return nil
	end
	local minX, minZ, maxX, maxZ = math.huge, math.huge, -math.huge, -math.huge
	for _, part in container:GetDescendants() do
		if part:IsA("BasePart") then
			local p = part.Position
			minX, minZ = math.min(minX, p.X), math.min(minZ, p.Z)
			maxX, maxZ = math.max(maxX, p.X), math.max(maxZ, p.Z)
		end
	end
	if minX > maxX then
		return nil
	end
	return { minX - AREA_MARGIN, minZ - AREA_MARGIN, maxX + AREA_MARGIN, maxZ + AREA_MARGIN }
end

local function inside(rect, position: Vector3): boolean
	return rect ~= nil and position.X >= rect[1] and position.Z >= rect[2] and position.X <= rect[3] and position.Z <= rect[4]
end

local worldRects = {} -- [world index] = courtyard rectangle (its Wall folder)
local hubRect, gardenRect = nil, nil
local tutorialGate: BasePart? = nil

task.spawn(function()
	for index, world in StageConfig.Worlds do
		if not world.soon then
			local folder = workspace:WaitForChild(world.folder, 30)
			worldRects[index] = rectOf(folder and folder:WaitForChild("Wall", 30))
		end
	end
	hubRect = rectOf(workspace:WaitForChild("StartLocation", 30))
	gardenRect = rectOf(workspace:WaitForChild("Garden", 30))
end)

-- "world<n>", "hub", "garden", "tutorial" or nil.
local function areaOf(position: Vector3): string?
	for index, rect in worldRects do
		if inside(rect, position) then
			return "world" .. index
		end
	end
	if inside(hubRect, position) then
		return "hub"
	end
	if inside(gardenRect, position) then
		return "garden"
	end
	if tutorialGate then
		local offset = tutorialGate.Position - position
		if Vector2.new(offset.X, offset.Z).Magnitude <= TUTORIAL_RADIUS then
			return "tutorial"
		end
	end
	return nil
end

-- Next stage --------------------------------------------------------------------------------------------------------------

local gateSigns = {} -- [stage key] = the Sign part of the stage's start gate
local hubEntrances = {} -- [stage key] = { part, height }: the hub world gate's portal, the Tutorial's hub portal

for _, stage in StageConfig.Stages do
	local world = StageConfig.Worlds[stage.world]
	if stage.hubPortal or (world and not world.soon) then
		task.spawn(function()
			local gate = StageMastery.WaitGate(stage)
			local sign = gate and gate:FindFirstChild("Sign")
			if sign and sign:IsA("BasePart") then
				gateSigns[stage.key] = sign
				if not world then
					tutorialGate = sign
				end
			end
			if world then
				hubEntrances[stage.key] = { StageConfig.WorldGatePortal(world), WORLD_MARKER_HEIGHT }
			else
				hubEntrances[stage.key] = { StageConfig.FaceTarget(stage), PORTAL_MARKER_HEIGHT }
			end
		end)
	end
end

local function nextStage()
	if player:GetAttribute(StageConfig.UnlockedAttribute(StageConfig.Stages[1])) == nil then
		return nil -- profile not loaded yet
	end
	for _, stage in StageConfig.Stages do
		local open = player:GetAttribute(StageConfig.UnlockedAttribute(stage)) == true
		if open and (player:GetAttribute(StageConfig.MedalAttribute(stage)) or 0) == 0 then
			return stage
		end
	end
	return nil
end

local function updateNext(area: string?)
	local stage = nextStage()
	local part, height = nil, nil
	if stage and area then
		if area == "hub" then
			local entrance = hubEntrances[stage.key]
			if entrance then
				part, height = entrance[1], entrance[2]
			end
		elseif area == (if StageConfig.Worlds[stage.world] then "world" .. stage.world else "tutorial") then
			part, height = gateSigns[stage.key], GATE_MARKER_HEIGHT
		end
	end
	Hints.SetMarker("next", part, "hints.next", height)
end

-- Skills ------------------------------------------------------------------------------------------------------------------

local seenAffordable = {} -- ["<talent id>:<level>"] = true: affordable while the Skills panel was open (this session)
local coins = 0

local function affordableLevels()
	local keys = {}
	for _, talent in TalentConfig.List do
		local level = TalentConfig.ClampLevel(talent.id, player:GetAttribute(TalentConfig.AttributeName(talent.id)))
		local cost = TalentConfig.NextCost(talent.id, level)
		if cost and coins >= cost then
			table.insert(keys, talent.id .. ":" .. (level + 1))
		end
	end
	return keys
end

local function updateSkills()
	local panelOpen = player:GetAttribute("OpenPanel") == "SkillsPanel" -- ButtonHandler's open panel
	local unseen = false
	for _, key in affordableLevels() do
		if panelOpen then
			seenAffordable[key] = true
		elseif not seenAffordable[key] then
			unseen = true
		end
	end
	Hints.SetDot("SkillsButton", "skills", unseen)
end

player:GetAttributeChangedSignal("OpenPanel"):Connect(updateSkills)
for _, talent in TalentConfig.List do
	player:GetAttributeChangedSignal(TalentConfig.AttributeName(talent.id)):Connect(updateSkills)
end
task.spawn(function()
	local coinValue = player:WaitForChild("leaderstats"):WaitForChild("Coins") :: IntValue
	coins = coinValue.Value
	updateSkills()
	coinValue:GetPropertyChangedSignal("Value"):Connect(function()
		coins = coinValue.Value
		updateSkills()
	end)
end)

-- Ready eggs --------------------------------------------------------------------------------------------------------------

local toastedEggs = {} -- ["<incubator>:<ReadyAt>"] = true: the toast was shown for that egg (this session)

local function ownPlot(): Instance?
	local index = player:GetAttribute(GardenConfig.PlotAttribute)
	local garden = workspace:FindFirstChild("Garden")
	local plots = garden and garden:FindFirstChild("Plots")
	return if index and plots then plots:FindFirstChild(GardenConfig.PlotName(index)) else nil
end

local function updateEggs(area: string?)
	local plot = ownPlot()
	local now = workspace:GetServerTimeNow()
	local first: Model? = nil
	for number = 1, GardenConfig.MaxIncubators do
		local model = plot and plot:FindFirstChild(GardenConfig.IncubatorNamePrefix .. number)
		local readyAt = model and model:GetAttribute("ReadyAt")
		if model and model:GetAttribute("State") == "egg" and type(readyAt) == "number" and readyAt <= now then
			first = first or model
			local key = number .. ":" .. readyAt
			if not toastedEggs[key] then
				toastedEggs[key] = true
				Hints.Toast(Locale.T("hints.eggReady"))
			end
		end
	end
	Hints.SetDot("PetsButton", "egg", first ~= nil)
	Hints.SetDot("PetsGarden", "egg", first ~= nil)

	local base = first and first:FindFirstChild("Base")
	if base and base:IsA("BasePart") and area == "garden" then
		local cframe, size = first:GetBoundingBox()
		local top = cframe.Position.Y + size.Y / 2
		Hints.SetMarker("egg", base, "hints.ready", top - base.Position.Y + INCUBATOR_MARKER_GAP)
	else
		Hints.SetMarker("egg", nil)
	end
end

-- Loop --------------------------------------------------------------------------------------------------------------------

while true do
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local area = if root then areaOf(root.Position) else nil
	updateNext(area)
	updateEggs(area)
	task.wait(0.5)
end
