-- StageScripts: the behaviour of the scripts copied into every stage scene (gates, finish portals, Top-10 boards, hub and island
-- portals, kill parts, ChoiceStage steps). Each scene script is a one-line stub that passes itself:
--   require(workspace.Handlers.StageScripts).TimerStart(script)
-- so the stage comes from where the stub lives (StageConfig.ForInstance), and the stubs stay byte-identical (docs/LAYOUT.md →
-- Reusable script variants). Server only.
--
-- Stage gate (Gate / Tutorial LandingPad):
--   TimerStart(script)        the gate's start line: starts the player's run timer (unlocked stages only) and counts as a checkpoint
--   GateExit(script)          walking out through the gate cancels a running timer of this stage
--   GateSign(script)          writes the stage name on the gate sign (Sign, or the Tutorial's StartGate.Sign)
--   Top10(script)             the stage's Top-10 board (Model.ScoreBlock): title, rows, live and per-minute updates
-- Finish (TeleportBackToStageStart):
--   FinishTimer(script)       on the Portal: stops this stage's running timer (the result)
--   TeleportToArrival(script) on the folder: the Portal teleports to the stage's Arrival (the Tutorial: LandingPad's destination)
-- Portals (all with a 2 s per-player cooldown):
--   WorldGate(script)         hub GateWorld<n>: to the island's spawn, while the world is open for the player
--   ReturnGate(script)        an island's ReturnGate: back to the hub, in front of the gate that led there
--   HubPortal(script)         hub stage portal (TeleportToTutorial): to the stage's landing pad, or the locked-stage popup
--   LeaveStage(script)        the Tutorial's TeleportToSpawn: back to the hub, cancelling a running timer
-- Hazards:
--   Kill(script)              the part kills a player's character on touch (Telemetry.MarkKill names it as the cause)
--   Damage(script, hp, gap)   the part takes `hp` health per touch, at most once per `gap` seconds per character (lava)
--   ChoiceStep(script)        makes one random child named `Step` solid (ChoiceStage: one safe step per server)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local AvatarThumbs = require(ServerScriptService.AvatarThumbs)
local Locale = require(ReplicatedStorage.Locale)
local StageConfig = require(ReplicatedStorage.StageConfig)
local StageUnlocks = require(ServerScriptService.StageUnlocks)
local TimeFormat = require(ReplicatedStorage.TimeFormat)
local TimerHandler = require(script.Parent.PlayerTimerHandler)
local TouchHandler = require(script.Parent.CheckpointTouchHandler)

local StageScripts = {}

-- The touching player's character root, or nil for anything else.
local function playerRoot(hit: BasePart): (Player?, BasePart?)
	local character = hit.Parent
	local player = character and Players:GetPlayerFromCharacter(character)
	local root = player and (character :: Instance):FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return player, root
	end
	return nil, nil
end

local PORTAL_COOLDOWN = 2 -- seconds per player
local portalTouches = {} -- [portal] = { [Player] = os.clock() }

Players.PlayerRemoving:Connect(function(player)
	for _, touches in portalTouches do
		touches[player] = nil
	end
end)

-- A teleport portal. allow(player) may refuse (falsy: no teleport); destination(player) is where the root goes (nil: nowhere);
-- onTeleport(player) runs after the teleport.
local function portalTouch(portal: BasePart, opts)
	local touches = {}
	portalTouches[portal] = touches
	portal.Touched:Connect(function(hit)
		local player, root = playerRoot(hit)
		if not (player and root) then
			return
		end
		local now = os.clock()
		if touches[player] and now - touches[player] < PORTAL_COOLDOWN then
			return
		end
		touches[player] = now
		if opts.allow and not opts.allow(player) then
			return
		end
		local destination = opts.destination(player)
		if not destination then
			return
		end
		root.CFrame = destination
		if opts.onTeleport then
			opts.onTeleport(player)
		end
	end)
end

-- Stage gate ------------------------------------------------------------------------------------------------------------------

function StageScripts.TimerStart(script: LuaSourceContainer)
	local stage = StageConfig.ForInstance(script)
	local part = script.Parent :: BasePart
	part.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end
		if StageUnlocks.IsUnlocked(player, stage) ~= true then
			return
		end
		local _, runningStage = TimerHandler.GetTimer(player)
		if runningStage ~= stage.key then
			TimerHandler.StartTimer(player, stage.key)
			TimerHandler.UpdateScorePanel(player, stage.key)
			TouchHandler.NewRun(player)
		end
		TouchHandler.OnTouched(part, hit)
	end)
end

function StageScripts.GateExit(script: LuaSourceContainer)
	local stage = StageConfig.ForInstance(script)
	local part = script.Parent :: BasePart
	part.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end
		local _, runningStage = TimerHandler.GetTimer(player)
		if runningStage == stage.key then
			TimerHandler.ResetTimer(player)
			TimerHandler.UpdateScorePanel(player, StageConfig.LocationKey(stage))
		end
	end)
end

function StageScripts.GateSign(script: LuaSourceContainer)
	local stage = StageConfig.ForInstance(script)
	local gate = script.Parent :: Instance
	local holder = gate:FindFirstChild("StartGate") or gate -- the Tutorial's LandingPad keeps its sign in StartGate
	Locale.SetKey((holder :: any).Sign.Gui.Title, "stage.name." .. stage.key)
end

local LEADERBOARD_UPDATE = 60 -- seconds; picks up records set on other servers

function StageScripts.Top10(script: LuaSourceContainer)
	local stage = StageConfig.ForInstance(script)
	local rows = StageConfig.TopRows
	local surface = (script.Parent :: any).Model.ScoreBlock.SurfaceGui

	-- the title comes from the stage, so a copied board can never show another stage's name
	Locale.SetKey(surface.DataLabel, "board.top10", { stage = { key = "stage.name." .. stage.key }, rows = rows })

	-- draws all rows; rows without an entry are cleared, so a shorter list leaves no stale names
	local function render(leaderboard)
		for i = 1, rows do
			local entry = leaderboard[i]
			surface.Names["Name" .. i].Text = if entry then entry.PlayerName else ""
			surface.Score["Score" .. i].Text = if entry then TimeFormat.Format(entry.Elapsed) else "..."
			-- avatar head shot; entries written before UserIds were stored are resolved by name
			AvatarThumbs.Show(surface.Photos["Photo" .. i], entry and entry.UserId, entry and entry.PlayerName)
		end
	end

	-- a record set on this server shows at once
	TimerHandler.LeaderboardChanged:Connect(function(stageKey, leaderboard)
		if stageKey == stage.key then
			render(leaderboard)
		end
	end)

	task.spawn(function()
		task.wait(5)
		render(TimerHandler.LoadGlobalLeaderboard(stage.key))
		while task.wait(LEADERBOARD_UPDATE) do
			render(TimerHandler.LoadGlobalLeaderboard(stage.key))
		end
	end)
end

-- Finish ----------------------------------------------------------------------------------------------------------------------

-- StopTimer is a no-op without a running timer, so repeated touches need no debounce
function StageScripts.FinishTimer(script: LuaSourceContainer)
	local stage = StageConfig.ForInstance(script)
	local portal = script.Parent :: BasePart
	portal.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end
		local _, runningStage = TimerHandler.GetTimer(player)
		if runningStage == stage.key then
			TimerHandler.StopTimer(player)
		end
	end)
end

function StageScripts.TeleportToArrival(script: LuaSourceContainer)
	local folder = script.Parent :: Instance
	local stageFolder = folder.Parent :: Instance
	local arrival = stageFolder:FindFirstChild("Arrival")
	local destination = if arrival
		then StageConfig.ArrivalCFrame(arrival :: BasePart)
		else (stageFolder :: any).LandingPad.TeleportDestination.CFrame + Vector3.new(0, 5, 0) -- the Tutorial: its start
	portalTouch((folder :: any).Portal, {
		destination = function()
			return destination
		end,
	})
end

-- Portals ---------------------------------------------------------------------------------------------------------------------

-- Hub world gate (S4.0, docs/STAGES.md §7.1): the world is found by the gate model's name. Shut until one of the world's stages
-- is open for the player (or while the profile loads); the client shows why (HubGateLocks, HubGateFaces). An island that is not
-- built yet (an admin at a `soon` gate) is nowhere to go.
function StageScripts.WorldGate(script: LuaSourceContainer)
	local gate = script.Parent :: Instance
	local world = StageConfig.WorldByGate[gate.Name]
	portalTouch(gate:WaitForChild("Portal") :: BasePart, {
		allow = function(player)
			return StageUnlocks.IsWorldOpen(player, world) == true
		end,
		destination = function()
			local island = workspace:FindFirstChild(world.folder)
			local spawn = island and island:FindFirstChild(world.spawn)
			return spawn and (spawn :: BasePart).CFrame + Vector3.new(0, 5, 0)
		end,
		onTeleport = function(player)
			TimerHandler.UpdateScorePanel(player, world.name)
		end,
	})
end

-- An island's return gate (S4.0): back to the hub, in front of the hub gate that led to this world, looking out of it.
function StageScripts.ReturnGate(script: LuaSourceContainer)
	local gate = script.Parent :: Instance
	local world = StageConfig.WorldByFolder[(gate.Parent :: Instance).Name]
	local destination = StageConfig.HubExitCFrame(StageConfig.WorldGatePortal(world))
	portalTouch(gate:WaitForChild("Portal") :: BasePart, {
		destination = function()
			return destination
		end,
		onTeleport = function(player)
			TimerHandler.UpdateScorePanel(player, StageConfig.HubName)
		end,
	})
end

-- A hub stage portal: a locked stage (GDD §3) does not teleport, the client shows the requirement and price instead.
function StageScripts.HubPortal(script: LuaSourceContainer)
	local hubPortal = script.Parent :: Instance
	local stage = StageConfig.ByHubPortal[hubPortal.Name]
	local target = (workspace :: any)[stage.folder].LandingPad.TeleportDestination
	portalTouch((hubPortal :: any).Portal, {
		allow = function(player)
			local unlocked = StageUnlocks.IsUnlocked(player, stage)
			if unlocked == false then
				StageUnlocks.ShowLocked(player, stage)
			end
			return unlocked
		end,
		destination = function()
			return target.CFrame + Vector3.new(0, 5, 0)
		end,
		onTeleport = function(player)
			TimerHandler.UpdateScorePanel(player, stage.key)
		end,
	})
end

-- Back to the hub, in front of the hub portal that led here, looking out of it; leaving the stage cancels a running timer.
function StageScripts.LeaveStage(script: LuaSourceContainer)
	local stage = StageConfig.ForInstance(script)
	local destination = StageConfig.ReturnCFrame(stage)
	portalTouch((script.Parent :: any).Portal, {
		destination = function()
			return destination
		end,
		onTeleport = function(player)
			TimerHandler.ResetTimer(player)
			TimerHandler.UpdateScorePanel(player, StageConfig.LocationKey(stage))
		end,
	})
end

-- Hazards ---------------------------------------------------------------------------------------------------------------------

-- A living character is killed once; touches of a dead one do nothing, so no debounce is needed.
function StageScripts.Kill(script: LuaSourceContainer)
	local part = script.Parent :: BasePart
	part.Touched:Connect(function(hit)
		local character = hit.Parent
		if not (character and Players:GetPlayerFromCharacter(character)) then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = 0
			require(ServerScriptService.Telemetry).MarkKill(character, part) -- cause of death (T1a)
		end
	end)
end

function StageScripts.Damage(script: LuaSourceContainer, hp: number, gap: number)
	local part = script.Parent :: BasePart
	local cooling = {} -- [Humanoid] = true
	part.Touched:Connect(function(hit)
		local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
		if not humanoid or cooling[humanoid] then
			return
		end
		humanoid.Health -= hp
		cooling[humanoid] = true
		task.delay(gap, function()
			cooling[humanoid] = nil
		end)
	end)
end

function StageScripts.ChoiceStep(script: LuaSourceContainer)
	local steps = {}
	for _, child in (script.Parent :: Instance):GetChildren() do
		if child.Name == "Step" and child:IsA("BasePart") then
			table.insert(steps, child)
		end
	end
	if #steps == 0 then
		warn("ChoiceStep: no Step in " .. (script.Parent :: Instance):GetFullName())
		return
	end
	steps[math.random(1, #steps)].CanCollide = true
end

return StageScripts
