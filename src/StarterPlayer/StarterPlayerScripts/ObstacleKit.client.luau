-- ObstacleKit (S3.1 spike, docs/STAGES.md §2.4): client-driven obstacles for the stage kit, configured by attributes on
-- Studio parts and found through CollectionService tags. The server animates nothing; every client derives the same
-- phase from workspace:GetServerTimeNow().
--   KitMover  Kind = "Slide" (Axis Vector3, Amplitude studs, Period s, Phase 0..1) or "Spin" (Speed deg/s, Phase deg):
--             moves its part locally; the character standing on it is carried with the part's per-frame delta.
--   KitTilt   hinge plate (local X axis): the plate tips toward the side the player stands on, a spring pulls it back;
--             Sens deg per stud of offset, Spring, Damping, MaxAngle deg, SlideAngle deg (the tilt past which the character
--             is pushed off), SlideSpeed studs/s. Kit-local: other players see the plate at rest.
--   KitBeam   blinking kill beam: Period s, Duty (on share 0..1), Phase 0..1, Telegraph s before "on"; while on, touching
--             the local character sets its own Humanoid.Health = 0 (client kill).
-- Spike diagnostics are mirrored to attributes on the local player: KitStandingOn, KitDrift, KitStandTime, KitFrameMs,
-- KitTiltAngle, KitKillAt (server time of the last client kill).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local RAY_DEPTH = 5 -- studs below the root part searched for the floor
local CARRY_GRACE = 0.2 -- seconds after leaving a mover that its velocity is still handed to the character
local AIR_CARRY = 0.5 -- seconds a jump off a mover keeps following it (attribute AirCarry on the part overrides)

local movers = {} -- [part] = { base, cframe, delta }
local tilts = {} -- [part] = { base, angle, speed }
local beams = {} -- [part] = { state }

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
		movers[part] = { base = part.CFrame, cframe = part.CFrame, delta = CFrame.identity }
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

local function setCharacter(newCharacter: Model?)
	character = newCharacter
	humanoid = newCharacter and newCharacter:FindFirstChildOfClass("Humanoid")
	root = newCharacter and newCharacter:FindFirstChild("HumanoidRootPart")
	if newCharacter then
		floorParams.FilterDescendantsInstances = { newCharacter }
		bodyParams.FilterDescendantsInstances = { newCharacter }
	end
end
player.CharacterAdded:Connect(function(newCharacter)
	task.defer(setCharacter, newCharacter)
end)
setCharacter(player.Character)

-- Position of a mover part at server time `now`.
local function moverFrame(part: BasePart, data, now: number): CFrame
	local period = attr(part, "Period", 6)
	if attr(part, "Kind", "Slide") == "Spin" then
		local degrees = attr(part, "Speed", 60) * now + attr(part, "Phase", 0)
		return data.base * CFrame.Angles(0, math.rad(degrees), 0)
	end
	local axis: Vector3 = attr(part, "Axis", Vector3.new(0, 0, 1))
	local swing = math.sin(2 * math.pi * (now / period + attr(part, "Phase", 0)))
	return data.base + axis.Unit * attr(part, "Amplitude", 10) * swing
end

-- "off" / "warning" (telegraph before on) / "on" for a beam at server time `now`.
local function beamState(part: BasePart, now: number): string
	local period = attr(part, "Period", 4)
	local duty = attr(part, "Duty", 0.5)
	local cycle = (now / period + attr(part, "Phase", 0)) % 1
	local onStart = 1 - duty -- the on window is the end of the cycle
	if cycle >= onStart then
		return "on"
	end
	if (onStart - cycle) * period <= attr(part, "Telegraph", 0.4) then
		return "warning"
	end
	return "off"
end

local STATE_TRANSPARENCY = { off = 1, warning = 0.8, on = 0.15 }

-- carry bookkeeping
local carriedVelocity = Vector3.zero
local carriedUntil = 0
local wasCarried = false
local carriedPart = nil -- the mover the character was last carried by
local airMover = nil -- mover data the character just jumped off, followed in the air until airUntil
local airUntil = 0
local standSample = nil -- { part, local position, since }

local frameMs = 0
local lastPublish = 0

local function publish(name: string, value: any)
	if player:GetAttribute(name) ~= value then
		player:SetAttribute(name, value)
	end
end

RunService.PreSimulation:Connect(function(dt: number)
	local started = os.clock()
	local now = workspace:GetServerTimeNow()

	for part, data in movers do
		local frame = moverFrame(part, data, now)
		data.delta = frame * data.cframe:Inverse()
		data.cframe = frame
		part.CFrame = frame
	end

	for part, data in beams do
		local state = beamState(part, now)
		if state ~= data.state then
			data.state = state
			part.Transparency = STATE_TRANSPARENCY[state]
		end
	end

	local alive = character ~= nil and root ~= nil and humanoid ~= nil and humanoid.Health > 0 and root.Parent ~= nil
	local standing: BasePart? = nil
	local grounded = false
	if alive then
		grounded = humanoid.FloorMaterial ~= Enum.Material.Air
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -RAY_DEPTH, 0), floorParams)
		if hit and (movers[hit.Instance] or tilts[hit.Instance]) then
			standing = hit.Instance
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
		if slope >= attr(standing, "SlideAngle", 25) then
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

	-- client kill: an "on" beam overlapping the character sets its own Health to 0
	if alive then
		for part, data in beams do
			if data.state == "on" then
				if #workspace:GetPartsInPart(part, bodyParams) > 0 then
					humanoid.Health = 0
					player:SetAttribute("KitKillAt", workspace:GetServerTimeNow())
					break
				end
			end
		end
	end

	frameMs = frameMs * 0.9 + (os.clock() - started) * 1000 * 0.1
	if started - lastPublish > 0.5 then
		lastPublish = started
		publish("KitFrameMs", math.floor(frameMs * 1000) / 1000)
	end
end)
