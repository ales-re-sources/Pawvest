-- ObstacleKit (docs/STAGES.md §2.4): client-driven obstacles for the stage kit, configured by attributes on Studio parts
-- and found through CollectionService tags. The server animates nothing; every client derives the same phase from
-- workspace:GetServerTimeNow() (KitMath). Standing on a mover carries the character; kill hazards set the character's own
-- Humanoid.Health = 0 (client kill).
--   KitMover  Kind (default "Slide"), all carry the character standing on them:
--               Slide  sine ping-pong: Axis Vector3, Amplitude studs, Period s, Phase 0..1
--               Lift   elevator: Axis, Distance studs, Period s (full cycle), Pause s at each end, Phase
--               Spin   turntable / sweeper bar around the part's Y axis: Speed deg/s, Phase deg
--               Piston strikes out and pulls back: Axis, Stroke studs, Period, Duty (extended share), Out s (strike time),
--                      Back s (retract time), Telegraph s (the part tints to WarnColor before it strikes), Phase
--               Swing  pendulum: Hinge "Z" (default) or "X", Angle deg, Period, Phase; hangs from the part's top (Pivot
--                      Vector3 offset from the part centre overrides)
--             Optional on any mover: Kill (touching it kills), Push studs/s (touching it knocks the character back along
--             the part's motion, PushLift studs/s upward, default 25), AirCarry s (how long a jump off keeps following it).
--   KitBeam   blinking kill beam: Period s, Duty (on share 0..1), Phase, Telegraph s before "on"; Kill defaults to true.
--   KitPlate  disappearing plate: Period, Duty (solid share), Phase, Telegraph s (flickers before it vanishes).
--   KitCrumble crumbling plate (kit-local): shakes when the player stands on it, vanishes after Delay s (default 0.8), is back
--             after Return s (default 3). Other players see it at rest.
--   KitSwitch / KitColorPlate  colour puzzle (kit-local): stepping on a KitSwitch (attributes Group, Color; Color "Toggle"
--             flips Red / Blue) sets that Group's colour; a KitColorPlate (Group, Color "Red" / "Blue") is solid only while its
--             Group shows its colour, a ghost otherwise. Groups start Red.
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

local KitMath = require(ReplicatedStorage:WaitForChild("KitMath"))

local player = Players.LocalPlayer

local RAY_DEPTH = 5 -- studs below the root part searched for the floor
local FLOOR_RADIUS = 1.5 -- radius of that search (the character's feet reach about this far past the root)
local CARRY_GRACE = 0.2 -- seconds after leaving a mover that its velocity is still handed to the character
local AIR_CARRY = 0.5 -- seconds a jump off a mover keeps following it (attribute AirCarry on the part overrides)
local OVERLAP_MARGIN = 8 -- studs beyond a part's own radius within which the overlap tests run
local WARN_COLOR = Color3.fromRGB(255, 170, 60)
local BEAM_TRANSPARENCY = { off = 1, warning = 0.8, on = 0.15 }

local movers = {} -- [part] = { base, cframe, delta, color, state }
local tilts = {} -- [part] = { base, angle, speed }
local beams = {} -- [part] = { state }
local plates = {} -- [part] = { state, transparency }
local crumbles = {} -- [part] = { state, base, transparency, since }
local switches = {} -- [part] = true
local colorPlates = {} -- [part] = { transparency, solid }
local colorState = {} -- [group] = "Red" / "Blue"
local runStart: number? = nil -- server time the player's current run started (StageTimerUpdate)
local timeBaseChanged = false -- a run started or ended: run-seeded movers jump to their new time, nobody is carried by it

local character, humanoid, root = nil, nil, nil
local floorParams = RaycastParams.new()
floorParams.FilterType = Enum.RaycastFilterType.Exclude
local bodyParams = OverlapParams.new()
bodyParams.FilterType = Enum.RaycastFilterType.Include

local function attr(part: Instance, name: string, default: any): any
	local value = part:GetAttribute(name)
	if value == nil then
		return default
	end
	return value
end

local function addMover(part: Instance)
	if part:IsA("BasePart") then
		movers[part] = {
			base = part.CFrame,
			cframe = part.CFrame,
			delta = CFrame.identity,
			color = part.Color,
			state = "on",
		}
	end
end

local function addTilt(part: Instance)
	if part:IsA("BasePart") then
		tilts[part] = { base = part.CFrame, angle = 0, speed = 0 }
	end
end

local function addBeam(part: Instance)
	if part:IsA("BasePart") then
		beams[part] = { state = "off" }
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

local function track(tag: string, add: (Instance) -> (), registry: { [Instance]: any })
	for _, part in CollectionService:GetTagged(tag) do
		add(part)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(add)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(function(part)
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

-- the player's run: StageTimerUpdate (elapsed >= 0, stageKey) while it runs, (-1, ...) when it ends
ReplicatedStorage:WaitForChild("StageTimerUpdate").OnClientEvent:Connect(function(elapsed: number)
	local newStart = if type(elapsed) == "number" and elapsed >= 0 then workspace:GetServerTimeNow() - elapsed else nil
	if (newStart == nil) ~= (runStart == nil) or (newStart and runStart and math.abs(newStart - runStart) > 0.5) then
		timeBaseChanged = true
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
		local degrees = (attr(part, "Speed", 60) * now + phase) % 360
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
	end
	return data.base + axis.Unit * attr(part, "Amplitude", 10) * KitMath.Sine(now, period, phase), "on"
end

-- carry bookkeeping
local carriedVelocity = Vector3.zero
local carriedUntil = 0
local wasCarried = false
local carriedPart = nil -- the mover the character was last carried by
local airMover = nil -- mover data the character just jumped off, followed in the air until airUntil
local airUntil = 0
local standSample = nil -- { part, local position, since }
local lastSwitch = nil -- the colour switch the character stood on last frame (a switch fires once per step-on)
local pushedUntil = 0 -- os.clock() before which no further knock-back is applied
local PUSH_COOLDOWN = 0.6

local frameMs = 0
local lastPublish = 0

local function publish(name: string, value: any)
	if player:GetAttribute(name) ~= value then
		player:SetAttribute(name, value)
	end
end

-- True when `part` is close enough to the character for an overlap test.
local function near(part: BasePart): boolean
	return (part.Position - root.Position).Magnitude < part.Size.Magnitude / 2 + OVERLAP_MARGIN
end

local function touchesCharacter(part: BasePart): boolean
	return near(part) and #workspace:GetPartsInPart(part, bodyParams) > 0
end

local function kill(part: Instance)
	humanoid.Health = 0
	player:SetAttribute("KitKillAt", workspace:GetServerTimeNow())
	player:SetAttribute("KitKilledBy", part.Name)
end

RunService.PreSimulation:Connect(function(dt: number)
	local started = os.clock()
	local now = workspace:GetServerTimeNow()

	for part, data in movers do
		local frame, state = moverFrame(part, data, KitMath.TimeBase(now, runStart, attr(part, "RunSeeded", false)))
		data.delta = if timeBaseChanged then CFrame.identity else frame * data.cframe:Inverse()
		data.cframe = frame
		part.CFrame = frame
		if state ~= data.state then
			data.state = state
			if attr(part, "Kind", "Slide") == "Piston" then
				part.Color = if state == "warning" then attr(part, "WarnColor", WARN_COLOR) else data.color
			end
		end
	end

	for part, data in beams do
		local state = KitMath.Window(
			KitMath.TimeBase(now, runStart, attr(part, "RunSeeded", false)),
			attr(part, "Period", 4),
			attr(part, "Duty", 0.5),
			attr(part, "Phase", 0),
			attr(part, "Telegraph", 0.4)
		)
		if state ~= data.state then
			data.state = state
			part.Transparency = BEAM_TRANSPARENCY[state]
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
		local instance = hit and hit.Instance
		if instance and (movers[instance] or tilts[instance] or crumbles[instance] or switches[instance]) then
			standing = instance
		end
	end

	-- kit-local state resets when the character dies or respawns (crumbled plates are back, colour groups start Red)
	if not alive then
		if next(colorState) ~= nil then
			table.clear(colorState)
		end
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
	local carriedBy = if standing and grounded then movers[standing] else nil
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
			for part, data in movers do
				if data.state == "on" then
					local push = attr(part, "Push", 0)
					local step = data.delta.Position
					if push > 0 and step.Magnitude > 1e-3 and os.clock() > pushedUntil and touchesCharacter(part) then
						-- knock-back: launch the character along the mover's motion (a standing Humanoid would cancel a
						-- plain velocity, so it goes into freefall); one launch per PUSH_COOLDOWN
						pushedUntil = os.clock() + PUSH_COOLDOWN
						player:SetAttribute("KitPushedBy", part.Name)
						root.AssemblyLinearVelocity = step.Unit * push + Vector3.new(0, attr(part, "PushLift", 25), 0)
						humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
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
