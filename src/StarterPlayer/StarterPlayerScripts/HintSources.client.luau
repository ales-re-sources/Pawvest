-- Hint sources, phase 1 (docs/GDD.md §11, ROADMAP G1); Hints.luau draws them.
--   Next stage: the latest open stage (highest game order) without a medal. A marker with its name above its start gate sign
--     while the player is in that stage's courtyard (the Tutorial: near its landing pad), above its hub entrance (world gate /
--     the Tutorial's hub portal) in the hub or the garden (unless a ready egg's marker is shown there), above the portal
--     back to the hub in any other courtyard or the Tutorial. When every open stage has a medal and a world's star bar shuts
--     the next stage: the same marker on the stage of that world with the lowest medal, labelled with the medal to reach.
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

-- The portals back to the hub: ["world<n>"] = the courtyard's ReturnGate portal, ["tutorial"] = the Tutorial's TeleportToSpawn.
local exitPortals = {}
for index, world in StageConfig.Worlds do
	if not world.soon then
		task.spawn(function()
			local folder = workspace:WaitForChild(world.folder, 30)
			local gate = folder and folder:WaitForChild("ReturnGate", 30)
			exitPortals["world" .. index] = gate and gate:WaitForChild("Portal", 30)
		end)
	end
end
task.spawn(function()
	local tutorial = workspace:WaitForChild("Tutorial", 30)
	local pad = tutorial and tutorial:WaitForChild("LandingPad", 30)
	local exit = pad and pad:WaitForChild("TeleportToSpawn", 30)
	exitPortals.tutorial = exit and exit:WaitForChild("Portal", 30)
end)

local function isOpen(stage): boolean
	return player:GetAttribute(StageConfig.UnlockedAttribute(stage)) == true
end

local function medalOf(stage): number
	return player:GetAttribute(StageConfig.MedalAttribute(stage)) or 0
end

-- The stage to raise a medal on when a world opener's star bar is all that blocks progress: the first shut opener in game
-- order, then the open stage of the world it counts stars in with the lowest medal (ties: the earliest). Returns the stage
-- and the medal index to reach.
local function starBarStage()
	for _, opener in StageConfig.Stages do
		local rule = opener.unlock
		if rule and rule.world and not isOpen(opener) then
			local best, bestMedal = nil, #StageConfig.Medals
			for _, stage in StageConfig.Stages do
				if stage.world == rule.world and isOpen(stage) and medalOf(stage) < bestMedal then
					best, bestMedal = stage, medalOf(stage)
				end
			end
			return best, if best then bestMedal + 1 else nil
		end
	end
	return nil, nil
end

-- The latest open stage (highest game order) without a medal: players are pushed forwards, not back to an older stage they
-- skipped (a medalled frontier falls back to the latest open stage still without one). When every open stage has a medal
-- and a world's star bar shuts the next stage, the stage to raise a medal on (starBarStage) with the medal to reach.
local function nextStage()
	if player:GetAttribute(StageConfig.UnlockedAttribute(StageConfig.Stages[1])) == nil then
		return nil, nil -- profile not loaded yet
	end
	local latest = nil
	for _, stage in StageConfig.Stages do
		if isOpen(stage) and medalOf(stage) == 0 then
			latest = stage
		end
	end
	if latest then
		return latest, nil
	end
	return starBarStage()
end

local function stageLabel(stage, goal: number?): () -> string
	return function()
		if goal then
			return Locale.T("hints.raiseMedal", {
				stage = Locale.StageName(stage),
				medal = Locale.MedalName(StageConfig.Medals[goal]),
			})
		end
		return Locale.StageName(stage)
	end
end

local function updateNext(area: string?, eggShown: boolean)
	local stage, goal = nextStage()
	local part, height = nil, nil
	if stage and area and not (area == "garden" and eggShown) then
		local home = if StageConfig.Worlds[stage.world] then "world" .. stage.world else "tutorial"
		if area == home then
			part, height = gateSigns[stage.key], GATE_MARKER_HEIGHT
		elseif area == "hub" or area == "garden" then
			local entrance = hubEntrances[stage.key]
			if entrance then
				part, height = entrance[1], entrance[2]
			end
		else
			-- another courtyard or the Tutorial: the way back to the hub
			part, height = exitPortals[area], PORTAL_MARKER_HEIGHT
		end
	end
	Hints.SetMarker("next", part, if stage then stageLabel(stage, goal) else nil, height)
end

-- Skills ------------------------------------------------------------------------------------------------------------------

local seenAffordable = {} -- ["<talent id>:<level>"] = true: affordable while the Skills panel was open (this session)
local coins = 0

local function affordableLevels()
	local keys = {}
	for _, talent in TalentConfig.List do
		local level = TalentConfig.ClampLevel(talent.id, player:GetAttribute(TalentConfig.AttributeName(talent.id)))
		local cost = TalentConfig.NextCost(talent.id, level)
		if cost and coins >= cost and not TalentConfig.RewardWorld(talent.id, level + 1) then -- a world reward is not for sale
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

local function readyLabel(): string
	return Locale.T("hints.ready")
end

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
		Hints.SetMarker("egg", base, readyLabel, top - base.Position.Y + INCUBATOR_MARKER_GAP)
		return true
	end
	Hints.SetMarker("egg", nil)
	return false
end

-- Loop --------------------------------------------------------------------------------------------------------------------

while true do
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local area = if root then areaOf(root.Position) else nil
	updateNext(area, updateEggs(area)) -- one marker per area: in the garden a ready egg wins
	task.wait(0.5)
end
