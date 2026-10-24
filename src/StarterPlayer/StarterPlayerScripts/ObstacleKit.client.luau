-- ObstacleKit (docs/STAGES.md §2.4): client-driven obstacles for the stage kit, configured by attributes on Studio parts
-- and found through CollectionService tags. The server animates nothing; every client derives the same phase from
-- workspace:GetServerTimeNow() (KitMath). Standing on a mover carries the character; kill hazards set the character's own
-- Humanoid.Health = 0 (client kill).
--   KitMover  Kind (default "Slide"), all carry the character standing on them:
--               Slide  sine ping-pong: Axis Vector3, Amplitude studs, Period s, Phase 0..1
--               Lift   elevator: Axis, Distance studs, Period s (full cycle), Pause s at each end, Phase
--               Spin   turntable / sweeper bar around the part's Y axis: Speed deg/s, Phase deg; Tick s (S6.3) makes it a
--                      clockwork step: Speed x Tick degrees per tick, moved in the first TickMove s (default 0.25) of it
--               Piston strikes out and pulls back: Axis, Stroke studs, Period, Duty (extended share), Out s (strike time),
--                      Back s (retract time), Telegraph s (the part tints to WarnColor before it strikes), Phase
--               Swing  pendulum: Hinge "Z" (default) or "X", Angle deg, Period, Phase; hangs from the part's top (Pivot
--                      Vector3 offset from the part centre overrides)
--               Flip   flipper plate: rests, then turns 180 degrees about its centre (Hinge "X" (default) or "Z") in Turn s
--                      (default 0.5) at the end of every half Period, so it flips over and back once per Period; tints to
--                      WarnColor for Telegraph s (default 0.8) before, and is not solid while it turns (the rider drops), Phase
--             Optional on any mover: Kill (touching it kills), Push studs/s (touching it knocks the character back along
--             the part's motion, PushLift studs/s upward, default 25; PushTime s keeps that shove going for a while,
--             default 0 = one kick, which the Humanoid's air braking stops within about 2 studs), AirCarry s (how long a jump off keeps following it), Carry = false (the
--             character standing on it is not carried, e.g. a spinning plate you have to stay on by running against it).
--   KitBeam   blinking kill beam: Period s, Duty (on share 0..1), Phase, Telegraph s before "on"; Kill defaults to true.
--             OffTransparency / WarnTransparency / OnTransparency (defaults 1 / 0.8 / 0.15) change its look per state;
--             with Kill = false it is a marker only (the Labyrinth's glow columns over its lava cells).
--             FloorMark = true lays a local strip along the beam's foot (a little wider than the beam): green right after
--             the beam goes off, shading to orange as it comes back (flashing in the Telegraph), red while it is on.
--   KitKill   static kill part (S6.3, the Clocktower's gargoyles): touching it kills; its look is left alone (often an
--             invisible hit box round a decoration).
--   KitPlate  disappearing plate: Period, Duty (solid share), Phase, Telegraph s (flickers before it vanishes).
--   KitCrumble crumbling plate (kit-local): shakes when the player stands on it, vanishes after Delay s (default 0.8), is back
--             after Return s (default 3). Other players see it at rest.
--   KitSwitch / KitColorPlate  colour puzzle (kit-local): stepping on a KitSwitch (attributes Group, Color; Color "Toggle"
--             flips Red / Blue) sets that Group's colour; a KitColorPlate (Group, Color "Red" / "Blue") is solid only while its
--             Group shows its colour, a ghost otherwise. Groups start Red.
--   KitButton / KitDoor  pressure door (kit-local, S6.3, the Clocktower): standing on a KitButton (attributes Group, Time s, default 4)
--             opens every KitDoor of that Group for Time s for the local player; stepping on the button again restarts the time.
--             The door slides OpenDistance studs (default its height) along OpenAxis (world Vector3, default up) in OpenTime s
--             (default 0.4) and back when the time is up; OpenTurn (degrees, default 0) also turns it about the vertical
--             axis through its centre (OpenDistance then defaults to 0): the Clocktower's turning gargoyle, its other parts
--             welded to the tagged hit box; the button glows while it is open and a countdown of the seconds
--             left floats over the button and, big with a shrinking bar and visible through walls, in the doorway at the
--             door's middle (S8.1 tuning: the one over the door's top went unnoticed); the last 3 seconds tick. Latch = true on a button (the Labyrinth's
--             exit switch) keeps its group open for the rest of the run instead, with no countdown and also after a death;
--             the start or end of a run closes it again.
--   KitIce    ice floor (S8.1, the Ice Rink): while the character stands on it, the kit drives its horizontal velocity: toward
--             the input direction x WalkSpeed at Accel studs/s² (default 14), coasting without input and slowing at Brake
--             studs/s² (default 5). It starts from the character's real velocity every frame, so a wall, wind or a push
--             still count. In the air the Humanoid steers again as usual.
--   RunSeeded  attribute on any timed part (mover, beam, plate): it runs on time since that player's stage timer started
--             (StageTimerUpdate) instead of server time, so every run sees the same sequence; set Phase so that t = 0 is safe.
--   KitTilt   hinge plate (local X axis): the plate tips toward the side the player stands on, a spring pulls it back;
--             Sens deg per stud of offset, Spring, Damping, MaxAngle deg, SlideAngle deg (the tilt past which the character
--             is pushed off), SlideSpeed studs/s. Kit-local: other players see the plate at rest.
-- Diagnostics are mirrored to attributes on the local player: KitStandingOn, KitDrift, KitStandTime, KitFrameMs,
-- KitTiltAngle, KitKillAt (server time of the last client kill), KitKilledBy (name of the part that killed), KitColors
-- (e.g. "A=Blue,B=Red") and KitRunStart (server time the current run started, 0 when none).
-- All kit-local state (crumbled plates, colour groups) resets when the character dies or respawns.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local KitMath = require(ReplicatedStorage:WaitForChild("KitMath"))

local player = Players.LocalPlayer

local RAY_DEPTH = 5 -- studs below the root part searched for the floor
local MIN_FLOOR_DEPTH = 2.0 -- a surface must be this far below the root part to count as floor (the feet are about 3 below) ...
local MAX_FLOOR_DEPTH = 3.8 -- ... and no farther than this
local FLOOR_RADIUS = 1.5 -- radius of that search (the character's feet reach about this far past the root)
local CARRY_GRACE = 0.2 -- seconds after leaving a mover that its velocity is still handed to the character
local AIR_CARRY = 0.5 -- seconds a jump off a mover keeps following it (attribute AirCarry on the part overrides)
local OVERLAP_MARGIN = 8 -- studs beyond a part's own radius within which the overlap tests run
local TOUCH_PAD = 0.1 -- studs added to a hazard's size for the touch test (about what a physical contact adds; all kit hazards are tested as boxes)
local WARN_COLOR = Color3.fromRGB(255, 170, 60)
local TICK_SECONDS = 3 -- an open door ticks in its last seconds (Studio-only ReplicatedStorage.DoorTickSound; silent without it)
local BEAM_TRANSPARENCY = { off = 1, warning = 0.8, on = 0.15 }
local NEAR_DISTANCE = 200 -- studs (beyond a mover's own radius) from the character within which movers update every frame
local FAR_EVERY = 4 -- farther movers (other stages) update every FAR_EVERY-th frame, still moving but carrying nobody

local movers = {} -- [part] = { base, cframe, delta, color, state }
local tilts = {} -- [part] = { base, angle, speed }
local beams = {} -- [part] = { state }
local killParts = {} -- [part] = true
local plates = {} -- [part] = { state, transparency }
local crumbles = {} -- [part] = { state, base, transparency, since }
local switches = {} -- [part] = true
local colorPlates = {} -- [part] = { transparency, solid }
local colorState = {} -- [group] = "Red" / "Blue"
local buttons = {} -- [part] = { color }
local doors = {} -- [part] = { transparency, look }
local doorOpenUntil = {} -- [group] = os.clock() when that group's doors close again
local doorOpenTime = {} -- [group] = the Time its button gave (the doorway bar's full length)
local lastTick = 0 -- whole seconds left on the last frame (door ticks)
local latched = {} -- [group] = true: a Latch button of that group was pressed in this run
local ices = {} -- [part] = true
local BUTTON_ON_COLOR = Color3.fromRGB(90, 230, 120)
local runStart: number? = nil -- server time the player's current run started (StageTimerUpdate)
local timeBaseChanged = false -- a run started or ended: run-seeded movers jump to their new time, nobody is carried by it

local character, humanoid, root = nil, nil, nil
local floorParams = RaycastParams.new()
floorParams.FilterType = Enum.RaycastFilterType.Exclude
local bodyParams = OverlapParams.new()
bodyParams.FilterType = Enum.RaycastFilterType.Include

-- Attribute reads are cached per part (the frame loop reads several per kit part every frame, and GetAttribute is far
-- slower than a table lookup); AttributeChanged drops a changed value, so tuning a part in Studio still takes effect.
-- Only kit parts are read (each registry check comes before the attribute), so the AttributeChanged connections stay
-- one per kit part; weak keys let a part that left the kit go.
local NONE = {} -- cached "attribute not set"
local attrCache = setmetatable({}, { __mode = "k" }) -- [Instance] = { [name] = value or NONE }

local function attr(part: Instance, name: string, default: any): any
	local cache = attrCache[part]
	if not cache then
		local fresh = {}
		cache = fresh
		attrCache[part] = fresh
		part.AttributeChanged:Connect(function(changed: string)
			fresh[changed] = nil
		end)
	end
	local value = cache[name]
	if value == nil then
		value = part:GetAttribute(name)
		if value == nil then
			value = NONE
		end
		cache[name] = value
	end
	if value == NONE then
		return default
	end
	return value
end

local moverCount = 0
local function addMover(part: Instance)
	if part:IsA("BasePart") then
		moverCount += 1
		movers[part] = {
			base = part.CFrame,
			cframe = part.CFrame,
			delta = CFrame.identity,
			color = part.Color,
			state = "on",
			radius = part.Size.Magnitude / 2,
			slot = moverCount % FAR_EVERY, -- far movers take turns, a quarter of them per frame
			near = false,
		}
	end
end

local function addTilt(part: Instance)
	if part:IsA("BasePart") then
		tilts[part] = { base = part.CFrame, angle = 0, speed = 0 }
	end
end

-- The floor strip of a FloorMark beam (local only): along its foot, MARK_MARGIN wider on each side than the beam.
local MARK_MARGIN = 1
local MARK_SAFE = Color3.fromRGB(80, 220, 110)
local MARK_ON = Color3.fromRGB(255, 50, 50)
local function floorMark(part: BasePart): BasePart
	local mark = Instance.new("Part")
	mark.Name = "KitBeamMark"
	mark.Anchored = true
	mark.CanCollide = false
	mark.CanQuery = false
	mark.CanTouch = false
	mark.CastShadow = false
	mark.Material = Enum.Material.Neon
	mark.Size = Vector3.new(part.Size.X + 2 * MARK_MARGIN, 0.2, part.Size.Z)
	mark.CFrame = part.CFrame * CFrame.new(0, -part.Size.Y / 2 + 0.1, 0)
	mark.Parent = workspace.CurrentCamera
	return mark
end

local function addBeam(part: Instance)
	if part:IsA("BasePart") and not beams[part] then
		beams[part] = { state = "off", mark = if part:GetAttribute("FloorMark") then floorMark(part) else nil, look = nil }
	end
end

local function addPlate(part: Instance)
	if part:IsA("BasePart") then
		plates[part] = { state = "solid", transparency = part.Transparency }
	end
end

local function addCrumble(part: Instance)
	if part:IsA("BasePart") then
		crumbles[part] = { state = "solid", base = part.CFrame, transparency = part.Transparency, since = 0 }
	end
end

local function addSwitch(part: Instance)
	if part:IsA("BasePart") then
		switches[part] = true
	end
end

local function addColorPlate(part: Instance)
	if part:IsA("BasePart") then
		colorPlates[part] = { transparency = part.Transparency, solid = true }
	end
end

-- A floating countdown (local only) over `adornee`, hidden until a door group is open. `width` studs wide (default 4);
-- `big` (the doorway's) adds a bar that shrinks with the time left and stays visible through walls, so a player who ran
-- past the button and round a corner still sees how long the door stays open.
local function countdownLabel(adornee: BasePart, offset: number, width: number?, big: boolean?): TextLabel
	local w = width or 4
	local gui = Instance.new("BillboardGui")
	gui.Name = "KitCountdown"
	gui.Adornee = adornee
	gui.Size = UDim2.fromScale(w, w * 0.75)
	gui.StudsOffsetWorldSpace = Vector3.new(0, offset, 0)
	gui.LightInfluence = 0
	gui.AlwaysOnTop = big == true
	gui.Enabled = false
	gui.ResetOnSpawn = false -- PlayerGui drops resetting guis on every respawn; the kit keeps its labels for good
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, if big then 0.8 else 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Parent = gui
	if big then
		local track = Instance.new("Frame")
		track.Name = "Track"
		track.AnchorPoint = Vector2.new(0.5, 1)
		track.Position = UDim2.fromScale(0.5, 1)
		track.Size = UDim2.fromScale(0.9, 0.12)
		track.BackgroundColor3 = Color3.new(0, 0, 0)
		track.BackgroundTransparency = 0.4
		track.BorderSizePixel = 0
		track.Parent = gui
		local bar = Instance.new("Frame")
		bar.Name = "Bar"
		bar.Size = UDim2.fromScale(1, 1)
		bar.BorderSizePixel = 0
		bar.Parent = track
	end
	gui.Parent = player:WaitForChild("PlayerGui")
	return label
end

local function addButton(part: Instance)
	if part:IsA("BasePart") then
		buttons[part] = { color = part.Color, label = countdownLabel(part, 3) }
	end
end

local function addDoor(part: Instance)
	if part:IsA("BasePart") then
		-- the countdown hangs over the doorway (the door itself slides away), on a local invisible anchor
		local anchor = Instance.new("Part")
		anchor.Name = "KitDoorAnchor"
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.Transparency = 1
		anchor.Size = Vector3.one
		anchor.CFrame = part.CFrame
		anchor.Parent = workspace.CurrentCamera
		-- in the doorway at the door's middle, about as wide as the doorway (its widest horizontal side)
		local width = math.clamp(math.max(part.Size.X, part.Size.Z) * 0.6, 5, 10)
		doors[part] = { base = part.CFrame, shown = 0, label = countdownLabel(anchor, 0, width, true) }
	end
end

local function track(tag: string, add: (Instance) -> (), registry: { [Instance]: any })
	for _, part in CollectionService:GetTagged(tag) do
		add(part)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(add)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(function(part)
		local data = registry[part]
		-- local helper parts (a beam's floor strip) go with their part, also when it streams out
		if type(data) == "table" and typeof(data.mark) == "Instance" then
			data.mark:Destroy()
		end
		registry[part] = nil
	end)
end

track("KitMover", addMover, movers)
track("KitTilt", addTilt, tilts)
track("KitBeam", addBeam, beams)
track("KitPlate", addPlate, plates)
track("KitCrumble", addCrumble, crumbles)
track("KitSwitch", addSwitch, switches)
track("KitColorPlate", addColorPlate, colorPlates)
track("KitButton", addButton, buttons)
track("KitDoor", addDoor, doors)
track("KitKill", function(part)
	if part:IsA("BasePart") then
		killParts[part] = true
	end
end, killParts)
track("KitIce", function(part)
	if part:IsA("BasePart") then
		ices[part] = true
	end
end, ices)

-- the player's run: StageTimerUpdate (elapsed >= 0, stageKey) while it runs, (-1, ...) when it ends
ReplicatedStorage:WaitForChild("StageTimerUpdate").OnClientEvent:Connect(function(elapsed: number)
	local newStart = if type(elapsed) == "number" and elapsed >= 0 then workspace:GetServerTimeNow() - elapsed else nil
	if (newStart == nil) ~= (runStart == nil) or (newStart and runStart and math.abs(newStart - runStart) > 0.5) then
		timeBaseChanged = true
		table.clear(latched)
	end
	runStart = newStart
	player:SetAttribute("KitRunStart", runStart or 0)
end)

local function setCharacter(newCharacter: Model?)
	character = newCharacter
	humanoid = newCharacter and newCharacter:FindFirstChildOfClass("Humanoid")
	root = newCharacter and newCharacter:FindFirstChild("HumanoidRootPart")
	if newCharacter then
		floorParams.FilterDescendantsInstances = { newCharacter }
		bodyParams.FilterDescendantsInstances = { newCharacter }
	end
end
-- a respawned character arrives part by part: wait for the Humanoid and the root part before using it
local function onCharacter(newCharacter: Model)
	newCharacter:WaitForChild("Humanoid")
	newCharacter:WaitForChild("HumanoidRootPart")
	setCharacter(newCharacter)
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then
	task.spawn(onCharacter, player.Character)
end

-- Frame of a mover part at server time `now`, and its hazard state: "on" while it moves / is dangerous, "warning" while a
-- piston telegraphs, "off" while a piston rests.
local function moverFrame(part: BasePart, data, now: number): (CFrame, string)
	local kind = attr(part, "Kind", "Slide")
	local period = attr(part, "Period", 6)
	local phase = attr(part, "Phase", 0)
	if kind == "Spin" then
		-- reduce the angle in double precision first: server time is ~1.8e9 s, and CFrame.Angles keeps only float32
		local tick = attr(part, "Tick", 0)
		local turns = if tick > 0 then KitMath.Ticked(now, tick, attr(part, "TickMove", 0.25)) * tick else now
		local degrees = (attr(part, "Speed", 60) * turns + phase) % 360
		return data.base * CFrame.Angles(0, math.rad(degrees), 0), "on"
	end
	local axis: Vector3 = attr(part, "Axis", Vector3.new(0, 0, 1))
	if kind == "Lift" then
		local position = KitMath.Lift(now, period, attr(part, "Pause", 1), phase)
		return data.base + axis.Unit * attr(part, "Distance", 10) * position, "on"
	elseif kind == "Piston" then
		local extension, state = KitMath.Piston(
			now,
			period,
			attr(part, "Duty", 0.5),
			phase,
			attr(part, "Telegraph", 0.4),
			attr(part, "Out", 0.15),
			attr(part, "Back", 0.5)
		)
		return data.base + axis.Unit * attr(part, "Stroke", 10) * extension, if extension > 0.05 then "on" else state
	elseif kind == "Swing" then
		local pivot: Vector3 = attr(part, "Pivot", Vector3.new(0, part.Size.Y / 2, 0))
		local angle = math.rad(KitMath.Swing(now, period, phase, attr(part, "Angle", 45)))
		local rotation = if attr(part, "Hinge", "Z") == "X" then CFrame.Angles(angle, 0, 0) else CFrame.Angles(0, 0, angle)
		return data.base * CFrame.new(pivot) * rotation * CFrame.new(-pivot), "on"
	elseif kind == "Flip" then
		local degrees, state = KitMath.Flip(now, period, phase, attr(part, "Turn", 0.5), attr(part, "Telegraph", 0.8))
		local angle = math.rad(degrees)
		return data.base * (if attr(part, "Hinge", "X") == "Z" then CFrame.Angles(0, 0, angle) else CFrame.Angles(angle, 0, 0)), state
	end
	return data.base + axis.Unit * attr(part, "Amplitude", 10) * KitMath.Sine(now, period, phase), "on"
end

-- carry bookkeeping
local carriedVelocity = Vector3.zero
local carriedUntil = 0
local wasCarried = false
local carriedPart = nil -- the mover the character was last carried by
local airMover = nil -- mover data the character just jumped off, followed in the air until airUntil
local iceDrive: LinearVelocity? = nil -- the root's ice drive (KitIce), created on the first ice floor of a character
local airUntil = 0
local standSample = nil -- { part, local position, since }
local lastSwitch = nil -- the colour switch the character stood on last frame (a switch fires once per step-on)
local pushedUntil = 0 -- os.clock() before which no further knock-back is applied
local PUSH_COOLDOWN = 0.6
local shove = Vector3.zero -- horizontal velocity a PushTime mover keeps applying until shoveUntil
local shoveUntil = 0

local frameMs = 0
local lastPublish = 0
local frameIndex = 0

local function publish(name: string, value: any)
	if player:GetAttribute(name) ~= value then
		player:SetAttribute(name, value)
	end
end

-- True when `part` is close enough to the character for an overlap test.
local function near(part: BasePart): boolean
	return (part.Position - root.Position).Magnitude < part.Size.Magnitude / 2 + OVERLAP_MARGIN
end

-- Touch, like the Touched event it replaces: a box slightly larger than the part, because a solid hazard pushes the
-- character out of any real overlap within one physics step and a bar only grazing a leg would never test positive.
local function touchesCharacter(part: BasePart): boolean
	return near(part) and #workspace:GetPartBoundsInBox(part.CFrame, part.Size + Vector3.one * TOUCH_PAD, bodyParams) > 0
end

local function kill(part: Instance)
	humanoid.Health = 0
	player:SetAttribute("KitKillAt", workspace:GetServerTimeNow())
	player:SetAttribute("KitKilledBy", part.Parent.Name .. "." .. part.Name)
	-- telemetry (T1a): the server cannot see a client kill's cause
	local remotes = ReplicatedStorage:FindFirstChild("TelemetryRemotes")
	local report = remotes and remotes:FindFirstChild("Report")
	if report then
		report:FireServer("kill", part)
	end
end

RunService.PreSimulation:Connect(function(dt: number)
	local started = os.clock()
	local now = workspace:GetServerTimeNow()
	frameIndex += 1

	-- movers far from the character (or the camera, without one) run at a lower rate; a mover's delta is only trusted
	-- while it is near in two frames in a row, so a mover coming back from the low rate never jerks a character
	local camera = workspace.CurrentCamera
	local focus = if root and root.Parent then root.Position elseif camera then camera.CFrame.Position else nil
	for part, data in movers do
		local near = focus == nil or (part.Position - focus).Magnitude < NEAR_DISTANCE + data.radius
		if not near and (frameIndex + data.slot) % FAR_EVERY ~= 0 then
			data.delta = CFrame.identity
			data.near = false
			continue
		end
		local frame, state = moverFrame(part, data, KitMath.TimeBase(now, runStart, attr(part, "RunSeeded", false)))
		data.delta = if timeBaseChanged or not (near and data.near) then CFrame.identity else frame * data.cframe:Inverse()
		data.near = near
		data.cframe = frame
		part.CFrame = frame
		if state ~= data.state then
			data.state = state
			local kind = attr(part, "Kind", "Slide")
			if kind == "Piston" or kind == "Flip" then
				part.Color = if state == "warning" then attr(part, "WarnColor", WARN_COLOR) else data.color
			end
			if kind == "Flip" then
				part.CanCollide = state ~= "on"
			end
		end
	end

	for part, data in beams do
		local time = KitMath.TimeBase(now, runStart, attr(part, "RunSeeded", false))
		local period = attr(part, "Period", 4)
		local duty = attr(part, "Duty", 0.5)
		local phase = attr(part, "Phase", 0)
		local state = KitMath.Window(time, period, duty, phase, attr(part, "Telegraph", 0.4))
		if data.mark then
			-- the strip shades from green to orange over the off window (in 10 steps), flashes in the warning, red while on
			local look
			if state == "on" then
				look = "on"
			elseif state == "warning" then
				look = if math.floor(now * 10) % 2 == 0 then "w1" else "w0"
			else
				look = math.floor(KitMath.Cycle(time, period, phase) / math.max(1 - duty, 1e-3) * 10)
			end
			if look ~= data.look then
				data.look = look
				local mark = data.mark
				if look == "on" then
					mark.Color, mark.Transparency = MARK_ON, 0.1
				elseif look == "w1" or look == "w0" then
					mark.Color, mark.Transparency = WARN_COLOR, if look == "w1" then 0.1 else 0.6
				else
					mark.Color, mark.Transparency = MARK_SAFE:Lerp(WARN_COLOR, KitMath.Smooth(look / 10)), 0.35
				end
			end
		end
		if state ~= data.state then
			data.state = state
			-- OffTransparency / WarnTransparency / OnTransparency override the default look per part
			local name = if state == "on" then "OnTransparency" elseif state == "warning" then "WarnTransparency" else "OffTransparency"
			part.Transparency = attr(part, name, BEAM_TRANSPARENCY[state])
		end
	end

	-- disappearing plates: solid, flickering before they vanish, gone (no collision) otherwise
	for part, data in plates do
		local state = KitMath.Plate(
			KitMath.TimeBase(now, runStart, attr(part, "RunSeeded", false)),
			attr(part, "Period", 4),
			attr(part, "Duty", 0.6),
			attr(part, "Phase", 0),
			attr(part, "Telegraph", 0.6)
		)
		if state == "warning" then
			part.Transparency = if math.floor(now * 8) % 2 == 0 then data.transparency else 0.6
		elseif state ~= data.state then
			part.Transparency = if state == "solid" then data.transparency else 1
		end
		if state ~= data.state then
			part.CanCollide = state ~= "gone"
			data.state = state
		end
	end

	local alive = character ~= nil and root ~= nil and humanoid ~= nil and humanoid.Health > 0 and root.Parent ~= nil
	local standing: BasePart? = nil
	local grounded = false
	if alive then
		grounded = humanoid.FloorMaterial ~= Enum.Material.Air
		-- a sphere, not a ray: a Humanoid can stand on a ledge with its root part past the edge, and a thin ray would
		-- lose the plate there (the tilt would spring back and the player could balance on the lip forever)
		local hit = workspace:Spherecast(root.Position, FLOOR_RADIUS, Vector3.new(0, -RAY_DEPTH, 0), floorParams)
		-- only a surface under the feet counts as floor: a low bar beside the character (the sphere reaches 1.5 studs
		-- sideways) is no floor, and neither is a surface far below a character that has just left the ground (the
		-- Humanoid still reports a floor for a frame or two after take-off); both must neither carry nor tilt it
		local depth = if hit then root.Position.Y - hit.Position.Y else 0
		local instance = hit and depth >= MIN_FLOOR_DEPTH and depth <= MAX_FLOOR_DEPTH and hit.Instance
		-- a kill hazard is never a floor (a sweeper bar at shin height would otherwise carry the character along with it)
		if instance and (movers[instance] or tilts[instance] or crumbles[instance] or switches[instance] or buttons[instance] or ices[instance]) and not attr(instance, "Kill", false) then
			standing = instance
		end
	end

	-- kit-local state resets when the character dies or respawns (crumbled plates are back, colour groups start Red)
	if not alive then
		if next(colorState) ~= nil then
			table.clear(colorState)
		end
		table.clear(doorOpenUntil)
		for part, data in crumbles do
			if data.state ~= "solid" then
				data.state = "solid"
				part.CFrame = data.base
				part.Transparency = data.transparency
				part.CanCollide = true
			end
		end
	end

	-- crumbling plates: shake while the player stands on one, vanish after Delay, come back after Return
	for part, data in crumbles do
		local clock = os.clock()
		if data.state == "solid" then
			if standing == part and grounded then
				data.state = "shaking"
				data.since = clock
			end
		elseif data.state == "shaking" then
			local fell = clock - data.since
			local shake = attr(part, "Shake", 0.12)
			part.CFrame = data.base + Vector3.new(math.sin(fell * 90) * shake, math.sin(fell * 70 + 1) * shake * 0.5, math.cos(fell * 80) * shake)
			if fell >= attr(part, "Delay", 0.8) then
				data.state = "gone"
				data.since = clock
				part.CFrame = data.base
				part.Transparency = 1
				part.CanCollide = false
			end
		elseif clock - data.since >= attr(part, "Return", 3) then
			data.state = "solid"
			part.Transparency = data.transparency
			part.CanCollide = true
		end
	end

	-- colour switches: stepping onto a pad sets (or toggles) its group's colour
	if standing and switches[standing] and standing ~= lastSwitch then
		local group = attr(standing, "Group", "A")
		local color = attr(standing, "Color", "Toggle")
		if color == "Toggle" then
			color = if (colorState[group] or "Red") == "Red" then "Blue" else "Red"
		end
		colorState[group] = color
	end
	lastSwitch = if standing and switches[standing] then standing else nil

	-- pressure buttons: standing on one (re)opens its group's doors for Time seconds (a Latch button for the run)
	if standing and buttons[standing] then
		if attr(standing, "Latch", false) then
			latched[attr(standing, "Group", "A")] = true
		else
			local group = attr(standing, "Group", "A")
			doorOpenUntil[group] = os.clock() + attr(standing, "Time", 4)
			doorOpenTime[group] = attr(standing, "Time", 4)
		end
	end
	local clockNow = os.clock()
	-- the last TICK_SECONDS whole seconds of an open group tick (higher toward the end), once per second for all groups
	local tickNow = 0
	for group, untilTime in doorOpenUntil do
		local left = untilTime - clockNow
		if left > 0 then
			tickNow = math.max(tickNow, math.ceil(left))
		end
	end
	if tickNow ~= lastTick then
		if tickNow > 0 and tickNow <= TICK_SECONDS and lastTick ~= 0 then
			local sound = ReplicatedStorage:FindFirstChild("DoorTickSound")
			if sound and sound:IsA("Sound") then
				sound.PlaybackSpeed = 1 + (TICK_SECONDS - tickNow) * 0.25
				SoundService:PlayLocalSound(sound)
			end
		end
		lastTick = tickNow
	end
	-- the countdown shows the seconds left rounded up (6, 5, … 1), red in the last two; the doorway's bar shrinks with it
	local function showCountdown(label: TextLabel, left: number, total: number?)
		local gui = label.Parent :: BillboardGui?
		if not gui then
			return
		end
		gui.Enabled = left > 0
		if left > 0 then
			local text = tostring(math.ceil(left))
			local urgent = left <= 2
			if label.Text ~= text then
				label.Text = text
				label.TextColor3 = if urgent then Color3.fromRGB(255, 90, 70) else Color3.new(1, 1, 1)
			end
			local track = gui:FindFirstChild("Track")
			local bar = track and track:FindFirstChild("Bar") :: Frame?
			if bar then
				bar.Size = UDim2.fromScale(math.clamp(left / math.max(total or left, 1e-3), 0, 1), 1)
				bar.BackgroundColor3 = if urgent then Color3.fromRGB(255, 90, 70)
					elseif left <= (total or left) / 2 then WARN_COLOR
					else Color3.fromRGB(110, 220, 120)
			end
		end
	end
	for part, data in buttons do
		local group = attr(part, "Group", "A")
		local left = (doorOpenUntil[group] or 0) - clockNow
		local color = if left > 0 or latched[group] then BUTTON_ON_COLOR else data.color
		if part.Color ~= color then
			part.Color = color
		end
		showCountdown(data.label, if latched[group] then 0 else left)
	end
	-- doors: slide open along OpenAxis (and turn by OpenTurn) while their group is open, back when the time is up (solid
	-- all the time: an open door is out of the way, a closing one pushes the character out of the doorway)
	for part, data in doors do
		local group = attr(part, "Group", "A")
		local left = (doorOpenUntil[group] or 0) - clockNow
		local step = dt / math.max(attr(part, "OpenTime", 0.4), 1e-3)
		local shown = math.clamp(data.shown + (if left > 0 or latched[group] then step else -step), 0, 1)
		if shown ~= data.shown then
			data.shown = shown
			local axis: Vector3 = attr(part, "OpenAxis", Vector3.new(0, 1, 0))
			local turn = attr(part, "OpenTurn", 0)
			local distance = attr(part, "OpenDistance", if turn ~= 0 then 0 else part.Size.Y)
			local eased = KitMath.Smooth(shown)
			part.CFrame = CFrame.Angles(0, math.rad(turn * eased), 0) * data.base.Rotation
				+ data.base.Position
				+ axis.Unit * distance * eased
		end
		showCountdown(data.label, if latched[group] then 0 else left, doorOpenTime[group])
	end

	-- colour plates: solid while their group shows their colour, a ghost otherwise
	for part, data in colorPlates do
		local solid = (colorState[attr(part, "Group", "A")] or "Red") == attr(part, "Color", "Red")
		if solid ~= data.solid then
			data.solid = solid
			part.Transparency = if solid then data.transparency else 0.85
			part.CanCollide = solid
		end
	end

	-- tilt plates: only the plate the character stands on reacts to it, the others spring back to rest
	for part, data in tilts do
		local target = 0
		if alive and standing == part then
			local offset = data.base:PointToObjectSpace(root.Position).Z
			target = attr(part, "Sens", 8) * offset
		end
		if target == 0 and math.abs(data.angle) < 1e-3 and math.abs(data.speed) < 1e-3 then
			-- at rest: put it back exactly once instead of rewriting its CFrame every frame
			if data.angle ~= 0 or data.speed ~= 0 then
				data.angle, data.speed = 0, 0
				part.CFrame = data.base
			end
			continue
		end
		local spring = attr(part, "Spring", 40)
		local damping = attr(part, "Damping", 12)
		local limit = attr(part, "MaxAngle", 40)
		data.speed += (spring * (target - data.angle) - damping * data.speed) * dt
		data.angle = math.clamp(data.angle + data.speed * dt, -limit, limit)
		if math.abs(data.angle) == limit and data.speed * data.angle > 0 then
			data.speed = 0
		end
		part.CFrame = data.base * CFrame.Angles(math.rad(data.angle), 0, 0)
		if standing == part then
			publish("KitTiltAngle", math.floor(data.angle * 10) / 10)
		end
	end

	-- a steep tilt plate lets the character slide off. The place's MaxSlopeAngle is 89 and a standing Humanoid holds its
	-- ground on any slope anyway, so past SlideAngle the kit takes the floor away: the Humanoid is put into freefall and
	-- given a downhill velocity every frame (it can still jump away or steer in the air).
	if alive and standing and tilts[standing] then
		local normal = standing.CFrame.UpVector
		local slope = math.deg(math.acos(math.clamp(normal.Y, -1, 1)))
		-- a character whose root hangs past the plate's edge (it stands on the lip) slides off too, on any noticeable tilt
		local local_ = standing.CFrame:PointToObjectSpace(root.Position)
		local onLip = slope > 5 and (math.abs(local_.X) > standing.Size.X / 2 or math.abs(local_.Z) > standing.Size.Z / 2)
		if slope >= attr(standing, "SlideAngle", 25) or onLip then
			local downhill = Vector3.new(normal.X, 0, normal.Z) -- the normal leans toward the lowered edge
			if downhill.Magnitude > 1e-3 then
				local velocity = root.AssemblyLinearVelocity
				root.AssemblyLinearVelocity = downhill.Unit * attr(standing, "SlideSpeed", 14) + Vector3.new(0, velocity.Y, 0)
				humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
			end
		end
	end

	-- carry: grounded on a mover → apply its frame delta; remember the point velocity for the jump off
	-- a mover that is not solid (a turning flipper) carries nobody
	local carriedBy = if standing and grounded and standing.CanCollide and attr(standing, "Carry", true) then movers[standing] else nil
	if carriedBy then
		local before = root.Position
		root.CFrame = carriedBy.delta * root.CFrame
		carriedVelocity = (root.Position - before) / math.max(dt, 1e-3)
		carriedUntil = os.clock() + CARRY_GRACE
		wasCarried = true
		carriedPart = standing
		airMover = nil
	elseif wasCarried and alive then
		wasCarried = false
		if os.clock() <= carriedUntil then
			root.AssemblyLinearVelocity += carriedVelocity
			airMover = movers[carriedPart]
			airUntil = os.clock() + attr(carriedPart, "AirCarry", AIR_CARRY)
		end
	end
	-- jump off: keep following the mover for a short while (the Humanoid's air friction would stop the carried velocity
	-- within 0.2 s and the platform would swing away under the jump)
	if airMover then
		if alive and not grounded and os.clock() < airUntil then
			root.CFrame = airMover.delta * root.CFrame
		else
			airMover = nil
		end
	end

	-- ice: the Humanoid walks at full speed on any floor whatever its friction, so on a KitIce part a plane LinearVelocity
	-- on the root takes over the horizontal motion (vertical stays free for jumps and falls)
	local onIce = alive and grounded and standing ~= nil and ices[standing] ~= nil
	if onIce then
		local drive = iceDrive
		if not drive or drive.Parent ~= root then
			local attachment = Instance.new("Attachment")
			attachment.Name = "KitIceAttachment"
			attachment.Parent = root
			drive = Instance.new("LinearVelocity")
			drive.Name = "KitIceDrive"
			drive.Attachment0 = attachment
			drive.RelativeTo = Enum.ActuatorRelativeTo.World
			drive.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
			drive.PrimaryTangentAxis = Vector3.xAxis
			drive.SecondaryTangentAxis = Vector3.zAxis
			drive.Parent = root
			iceDrive = drive
		end
		local velocity = root.AssemblyLinearVelocity
		local flat = Vector3.new(velocity.X, 0, velocity.Z)
		local wanted = humanoid.MoveDirection * humanoid.WalkSpeed
		if wanted.Magnitude > 0.01 then
			local change = wanted - flat
			local step = attr(standing, "Accel", 14) * dt
			flat = if change.Magnitude <= step then wanted else flat + change.Unit * step
		else
			local speed = flat.Magnitude
			flat = if speed > 0.01 then flat * (math.max(speed - attr(standing, "Brake", 5) * dt, 0) / speed) else Vector3.zero
		end
		-- enough force for the drive, not so much that it shoves through walls or other characters
		drive.MaxForce = root.AssemblyMass * 300
		drive.PlaneVelocity = Vector2.new(flat.X, flat.Z)
		drive.Enabled = true
	elseif iceDrive and iceDrive.Enabled then
		iceDrive.Enabled = false
	end

	-- diagnostics: how far the character drifts from its spot on the mover while standing still
	if carriedBy and humanoid.MoveDirection.Magnitude == 0 then
		local localPosition = (standing :: BasePart).CFrame:PointToObjectSpace(root.Position)
		if not standSample or standSample.part ~= standing then
			standSample = { part = standing, position = localPosition, since = os.clock(), drift = 0 }
		elseif os.clock() - standSample.since < 1 then
			standSample.position = localPosition -- landing settles first: measure from 1 s after touching down
		else
			standSample.drift = math.max(standSample.drift, (localPosition - standSample.position).Magnitude)
		end
		publish("KitDrift", math.floor(standSample.drift * 1000) / 1000)
		publish("KitStandTime", math.floor((os.clock() - standSample.since) * 10) / 10)
	else
		standSample = nil
	end
	publish("KitStandingOn", if standing then standing.Name else "")

	-- hazards: an "on" beam, or a mover with Kill that is moving / extended, overlapping the character kills it;
	-- Push shoves it along the mover's motion
	if alive then
		local killer: Instance? = nil
		for part, data in beams do
			if data.state == "on" and attr(part, "Kill", true) and touchesCharacter(part) then
				killer = part
				break
			end
		end
		if not killer then
			for part in killParts do
				if touchesCharacter(part) then
					killer = part
					break
				end
			end
		end
		if not killer then
			for part, data in movers do
				if data.state == "on" then
					local push = attr(part, "Push", 0)
					-- the mover's motion at the character (a spinning paddle shoves along its turn, not toward its centre)
					local step = if push > 0 then data.delta * root.Position - root.Position else Vector3.zero
					if push > 0 and step.Magnitude > 1e-3 and os.clock() > pushedUntil and touchesCharacter(part) then
						-- knock-back: launch the character along the mover's motion (a standing Humanoid would cancel a
						-- plain velocity, so it goes into freefall); one launch per PUSH_COOLDOWN
						pushedUntil = os.clock() + PUSH_COOLDOWN
						player:SetAttribute("KitPushedBy", part.Name)
						root.AssemblyLinearVelocity = step.Unit * push + Vector3.new(0, attr(part, "PushLift", 25), 0)
						humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
						local flat = Vector3.new(step.X, 0, step.Z)
						shove = if flat.Magnitude > 1e-3 then flat.Unit * push else Vector3.zero
						shoveUntil = os.clock() + attr(part, "PushTime", 0)
					end
					if attr(part, "Kill", false) and touchesCharacter(part) then
						killer = part
						break
					end
				end
			end
		end
		if killer then
			kill(killer)
		end
		-- a long shove: keep the horizontal push against the Humanoid's air braking
		if os.clock() < shoveUntil then
			root.AssemblyLinearVelocity = shove + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
		end
	end

	timeBaseChanged = false
	local parts = {}
	for group, color in colorState do
		table.insert(parts, group .. "=" .. color)
	end
	table.sort(parts)
	publish("KitColors", table.concat(parts, ","))

	frameMs = frameMs * 0.9 + (os.clock() - started) * 1000 * 0.1
	if started - lastPublish > 0.5 then
		lastPublish = started
		publish("KitFrameMs", math.floor(frameMs * 1000) / 1000)
	end
end)
