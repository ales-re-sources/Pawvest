-- KitZones (S3.3a, docs/STAGES.md §2.2 "Zones"): regions that act on the local character while it is inside, all client side
-- like the rest of the kit. A zone is a part tagged "KitZone" (an invisible box, hidden for players, visible in Studio)
-- with attribute Kind:
--   Wind        Push Vector3 (studs/s, the speed the wind carries the character along; default (0, 0, 12)); GroundFactor
--               (default 0.6) scales it while the character stands; gusts: set Period (s), Duty (blowing share) and Phase,
--               then the wind rises and falls smoothly inside the blowing window; RunSeeded (see ObstacleKit)
--   LowGravity  GravityScale (default 0.35): the share of normal gravity that acts inside the zone (jumps go farther / higher)
--   Updraft     Lift (studs/s, default 45): the character is accelerated upward (Accel studs/s², default 400: it must beat gravity, 196) up to that speed
-- Wind zones also draw themselves for the local player (S6.1, user request): a ParticleEmitter of drifting streaks inside the zone, flowing
-- along Push (the dominant axis of it) at about the wind's speed, its rate following the gust (none while a gust is off), so a crosswind or a
-- gust is visible before it moves the character. Local only; attribute Particles = false switches it off for a zone.
-- Nothing here pushes a character at a speed above the attributes' own limits, and everything stops the moment the character
-- dies or leaves the box. Priority is not needed: the effects of overlapping zones simply add.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local KitMath = require(ReplicatedStorage:WaitForChild("KitMath"))

local player = Players.LocalPlayer

local zones = {} -- [part] = true
local windEmitters = {} -- [part] = ParticleEmitter (wind zones only)
local runStart: number? = nil

local EMIT_DISTANCE = 260 -- studs from the character within which a wind zone emits

-- Normal of the zone's local axis closest to the world vector `direction` (zones are axis aligned boxes in practice).
local function dominantNormal(part: BasePart, direction: Vector3): Enum.NormalId
	local localDirection = part.CFrame:VectorToObjectSpace(direction)
	local ax, ay, az = math.abs(localDirection.X), math.abs(localDirection.Y), math.abs(localDirection.Z)
	if ax >= ay and ax >= az then
		return if localDirection.X >= 0 then Enum.NormalId.Right else Enum.NormalId.Left
	elseif ay >= az then
		return if localDirection.Y >= 0 then Enum.NormalId.Top else Enum.NormalId.Bottom
	end
	return if localDirection.Z >= 0 then Enum.NormalId.Back else Enum.NormalId.Front
end

local function addWindEmitter(part: BasePart)
	if part:GetAttribute("Particles") == false then
		return
	end
	local push = part:GetAttribute("Push")
	local direction: Vector3 = if typeof(push) == "Vector3" and push.Magnitude > 0 then push else Vector3.new(0, 0, 12)
	local speed = math.max(direction.Magnitude * 1.4, 6)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "WindParticles"
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(235, 245, 255))
	emitter.LightEmission = 0.25
	emitter.LightInfluence = 0
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.15, 0.55),
		NumberSequenceKeypoint.new(0.8, 0.6),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Size = NumberSequence.new(0.9, 0.5)
	emitter.Orientation = Enum.ParticleOrientation.VelocityParallel
	emitter.Squash = NumberSequence.new(-2)
	emitter.Speed = NumberRange.new(speed * 0.9, speed * 1.1)
	emitter.SpreadAngle = Vector2.new(4, 4)
	emitter.EmissionDirection = dominantNormal(part, direction)
	emitter.Lifetime = NumberRange.new(1.0, 1.6)
	emitter.Rate = 0
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward -- InAndOut sent half of the streaks against the wind
	emitter.Enabled = true
	emitter.Parent = part
	windEmitters[part] = emitter
end

local function addZone(part: Instance)
	if part:IsA("BasePart") then
		zones[part] = true
		part.Transparency = 1
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		local kind = part:GetAttribute("Kind")
		if kind == nil or kind == "Wind" then
			addWindEmitter(part)
		end
	end
end
for _, part in CollectionService:GetTagged("KitZone") do
	addZone(part)
end
CollectionService:GetInstanceAddedSignal("KitZone"):Connect(addZone)
CollectionService:GetInstanceRemovedSignal("KitZone"):Connect(function(part)
	zones[part] = nil
	local emitter = windEmitters[part]
	if emitter then
		emitter:Destroy()
		windEmitters[part] = nil
	end
end)

ReplicatedStorage:WaitForChild("StageTimerUpdate").OnClientEvent:Connect(function(elapsed: number)
	runStart = if type(elapsed) == "number" and elapsed >= 0 then workspace:GetServerTimeNow() - elapsed else nil
end)

local function attr(part: Instance, name: string, default: any): any
	local value = part:GetAttribute(name)
	if value == nil then
		return default
	end
	return value
end

local function inside(zone: BasePart, position: Vector3): boolean
	local local_ = zone.CFrame:PointToObjectSpace(position)
	local half = zone.Size / 2
	return math.abs(local_.X) <= half.X and math.abs(local_.Y) <= half.Y and math.abs(local_.Z) <= half.Z
end

-- Current strength of a wind zone, 0..1 (1 for a steady wind, KitMath.Gust for a gusting one).
local function windStrength(zone: BasePart, now: number): number
	local period = zone:GetAttribute("Period")
	if type(period) ~= "number" then
		return 1
	end
	return KitMath.Gust(KitMath.TimeBase(now, runStart, attr(zone, "RunSeeded", false)), period, attr(zone, "Duty", 0.5), attr(zone, "Phase", 0))
end

-- The wind particles follow the zone's strength: a rate in proportion to its volume, none while a gust is off or the zone is far from the character.
RunService.Heartbeat:Connect(function()
	-- distance from the character (the camera follows it; a cut-scene or test camera far away must not switch the wind off)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local camera = workspace.CurrentCamera
	local origin = if root then root.Position elseif camera then camera.CFrame.Position else nil
	if not origin then
		return
	end
	local now = workspace:GetServerTimeNow()
	for zone, emitter in windEmitters do
		local strength = 0
		if (zone.Position - origin).Magnitude <= EMIT_DISTANCE + zone.Size.Magnitude / 2 then
			strength = windStrength(zone, now)
		end
		local volume = zone.Size.X * zone.Size.Y * zone.Size.Z
		emitter.Rate = if strength > 0.05 then math.clamp(volume / 120, 10, 60) * strength else 0
	end
end)

RunService.PreSimulation:Connect(function(dt: number)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end
	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
	local now = workspace:GetServerTimeNow()
	local names = {}

	for zone in zones do
		if inside(zone, root.Position) then
			local kind = attr(zone, "Kind", "Wind")
			table.insert(names, zone.Name)
			if kind == "Wind" then
				local strength = windStrength(zone, now)
				if strength > 0 then
					local push: Vector3 = attr(zone, "Push", Vector3.new(0, 0, 12))
					local factor = if grounded then attr(zone, "GroundFactor", 0.6) else 1
					root.CFrame += push * (strength * factor * dt)
				end
			elseif kind == "LowGravity" then
				local scale = attr(zone, "GravityScale", 0.35)
				if not grounded then
					root.AssemblyLinearVelocity += Vector3.new(0, workspace.Gravity * (1 - scale) * dt, 0)
				end
			elseif kind == "Updraft" then
				local velocity = root.AssemblyLinearVelocity
				local lift = attr(zone, "Lift", 45)
				if grounded then
					-- a standing Humanoid cancels small upward velocities every frame: launch it like a jump first
					root.AssemblyLinearVelocity = Vector3.new(velocity.X, lift * 0.5, velocity.Z)
					humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
				elseif velocity.Y < lift then
					root.AssemblyLinearVelocity = Vector3.new(velocity.X, math.min(velocity.Y + attr(zone, "Accel", 400) * dt, lift), velocity.Z)
				end
			end
		end
	end

	table.sort(names)
	local label = table.concat(names, ",")
	if player:GetAttribute("KitZones") ~= label then
		player:SetAttribute("KitZones", label) -- diagnostics: the zones the character is inside
	end
end)
