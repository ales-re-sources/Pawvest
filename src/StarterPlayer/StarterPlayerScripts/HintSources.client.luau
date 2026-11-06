-- Hint sources, phase 1 (docs/GDD.md §11, ROADMAP G1); Hints.luau draws them.
--   Next stage: the latest open stage (highest game order) without a medal. A marker with its name above its start gate sign
--     while the player is in that stage's courtyard (the Tutorial: near its landing pad), above its hub entrance (world gate /
--     the Tutorial's hub portal) in the hub or the garden (unless a ready egg's marker is shown there), above the portal
--     back to the hub in any other courtyard or the Tutorial. When every open stage has a medal and a world's star bar shuts
--     the next stage: the same marker on the stage of that world with the lowest medal, labelled with the medal to reach.
--     Stuck (K1): after STUCK_RUNS failed runs or STUCK_DEATHS deaths (Quick Respawn fall resets included) on the next stage
--     in this session, the marker moves to the stage of the same world with the lowest medal instead (the stars that can
--     still open the next world); never to another world, so a player with World 2 open is still sent there.
--   Skills: a dot on the Skills icon when a talent level became affordable that was not affordable while the panel was open.
--   Ready egg: a "Ready!" marker above the incubator while in the garden, and a toast once per egg.
--   Garden waiting (U2): the badge on the Garden icon counts ripe crops + ready eggs (GardenSummary).
-- Display only: reads attributes, leaderstats and the own plot's incubator models.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local StageMastery = require(ReplicatedStorage:WaitForChild("StageMastery"))
local TalentConfig = require(ReplicatedStorage:WaitForChild("TalentConfig"))
local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local Hints = require(script.Parent:WaitForChild("Hints"))
local GardenView = require(script.Parent:WaitForChild("GardenView"))
local PlotView = require(script.Parent:WaitForChild("PlotView"))
local GardenSummary = require(script.Parent:WaitForChild("GardenSummary"))

local player = Players.LocalPlayer

local GATE_MARKER_HEIGHT = 6 -- studs above a gate sign (where GateMastery's badge would be; a "next" stage is never mastered)
local PORTAL_MARKER_HEIGHT = 9 -- studs above the Tutorial's hub portal
local WORLD_MARKER_HEIGHT = 11 -- studs above a hub world gate's portal
local INCUBATOR_MARKER_GAP = 5 -- studs above the top of an incubator model
local AREA_MARGIN = 15 -- studs around an area's parts that still count as inside
local TUTORIAL_RADIUS = 60 -- studs (horizontal) from the Tutorial's start gate
local STUCK_RUNS = 3 -- runs of a stage ended without a medal (given up or too slow) ...
local STUCK_DEATHS = 12 -- ... or deaths (and Quick Respawn fall resets) during its runs, after which the next-stage marker
-- suggests another stage
local MIN_ATTEMPT = 10 -- seconds a run must last to count (walking out through a gate starts and ends a ghost run)

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

-- The open stage of `world` with the lowest medal below Gold (ties: the earliest), skipping `except`; returns the stage and
-- the medal index to reach.
local function lowestMedalStage(world: number, except)
	local best, bestMedal = nil, #StageConfig.Medals
	for _, stage in StageConfig.Stages do
		if stage.world == world and stage ~= except and isOpen(stage) and medalOf(stage) < bestMedal then
			best, bestMedal = stage, medalOf(stage)
		end
	end
	return best, if best then bestMedal + 1 else nil
end

-- The stage to raise a medal on when a world opener's star bar is all that blocks progress: the first shut opener in game
-- order, then the lowest-medal stage of the world it counts stars in.
local function starBarStage()
	for _, opener in StageConfig.Stages do
		local rule = opener.unlock
		if rule and rule.world and not isOpen(opener) then
			return lowestMedalStage(rule.world)
		end
	end
	return nil, nil
end

-- Failed attempts per stage key this session (K1): runs that ended without a medal, deaths and fall resets during runs.
local failedRuns, runDeaths = {}, {}
local runStage, runStartedAt = nil, 0 -- key of the stage whose run is active, os.clock() at its start

local function endRun(medal: number)
	local stage = runStage and StageConfig.ByKey[runStage]
	local lasted = os.clock() - runStartedAt
	runStage = nil
	if stage and lasted >= MIN_ATTEMPT and medal == 0 then
		failedRuns[stage.key] = (failedRuns[stage.key] or 0) + 1
	end
end

-- the server sends (elapsed >= 0, stageKey) when a run starts (the client counts on), (-1, final, result) when it finishes
-- (result.medal: this run's medal), (-1) when it is cancelled; a run started while another is going ends the other one
ReplicatedStorage:WaitForChild("StageTimerUpdate").OnClientEvent:Connect(function(elapsed, stageKeyOrFinal, result)
	if elapsed >= 0 then
		if runStage and runStage ~= stageKeyOrFinal then
			endRun(0)
		end
		runStage, runStartedAt = stageKeyOrFinal, os.clock() - elapsed
		return
	end
	endRun(if type(result) == "table" then result.medal or 0 else 0)
end)

local function countDeath()
	if runStage then
		runDeaths[runStage] = (runDeaths[runStage] or 0) + 1
	end
end

local function watchDeaths(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid then
		humanoid.Died:Connect(countDeath)
	end
end
player.CharacterAdded:Connect(watchDeaths)
if player.Character then
	task.spawn(watchDeaths, player.Character)
end
-- a Quick Respawn fall reset puts the character back without dying: it counts as a death here
task.spawn(function()
	local quickRespawn = script.Parent:WaitForChild("QuickRespawnClient", 10)
	local respawned = quickRespawn and quickRespawn:WaitForChild("Respawned", 10)
	if respawned then
		respawned.Event:Connect(countDeath)
	end
end)

local function stuckOn(stage): boolean
	return (failedRuns[stage.key] or 0) >= STUCK_RUNS or (runDeaths[stage.key] or 0) >= STUCK_DEATHS
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
		if stuckOn(latest) then
			local other, goal = lowestMedalStage(latest.world, latest)
			if other then
				return other, goal
			end
		end
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

-- Ready eggs of the own plot as GardenView last received it (the server's GardenRemotes.Plot, readyAt in server time).
local function updateEggs(area: string?)
	local state = GardenView.OwnState()
	local now = workspace:GetServerTimeNow()
	local first: number? = nil
	for number = 1, GardenConfig.MaxIncubators do
		local eggId, readyAt = PlotView.ParseEgg(state and state.eggs[number])
		if eggId and readyAt and readyAt <= now then
			first = first or number
			local key = number .. ":" .. readyAt
			if not toastedEggs[key] then
				toastedEggs[key] = true
				Hints.Toast(Locale.T("hints.eggReady"))
			end
		end
	end
	local summary = GardenSummary.Get(now)
	Hints.SetBadge("GardenButton", summary.ripe + summary.eggs)

	local piece = first and GardenView.OwnPiece("inc" .. first) -- the drawn incubator (nil while not drawn)
	local base = piece and piece:FindFirstChild("Base")
	if piece and base and base:IsA("BasePart") and area == "garden" then
		local cframe, size = piece:GetBoundingBox()
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
