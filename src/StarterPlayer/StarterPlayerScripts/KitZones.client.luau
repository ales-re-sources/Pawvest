-- KitZones (S3.3a, docs/STAGES.md §2.2 "Zones"): regions that act on the local character while it is inside, all client side
-- like the rest of the kit. A zone is a part tagged "KitZone" (an invisible box, hidden for players, visible in Studio)
-- with attribute Kind:
--   Wind        Push Vector3 (studs/s, the speed the wind carries the character along; default (0, 0, 12)); GroundFactor
--               (default 0.6) scales it while the character stands; gusts: set Period (s), Duty (blowing share) and Phase,
--               then the wind rises and falls smoothly inside the blowing window; RunSeeded (see ObstacleKit)
--   LowGravity  GravityScale (default 0.35): the share of normal gravity that acts inside the zone (jumps go farther / higher)
--   Updraft     Lift (studs/s, default 45): the character is accelerated upward (Accel studs/s², default 400: it must beat gravity, 196) up to that speed
-- Nothing here pushes a character at a speed above the attributes' own limits, and everything stops the moment the character
-- dies or leaves the box. Priority is not needed: the effects of overlapping zones simply add.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local KitMath = require(ReplicatedStorage:WaitForChild("KitMath"))

local player = Players.LocalPlayer

local zones = {} -- [part] = true
local runStart: number? = nil

local function addZone(part: Instance)
	if part:IsA("BasePart") then
		zones[part] = true
		part.Transparency = 1
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
	end
end
for _, part in CollectionService:GetTagged("KitZone") do
	addZone(part)
end
CollectionService:GetInstanceAddedSignal("KitZone"):Connect(addZone)
CollectionService:GetInstanceRemovedSignal("KitZone"):Connect(function(part)
	zones[part] = nil
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
				local strength = 1
				local period = zone:GetAttribute("Period")
				if type(period) == "number" then
					strength = KitMath.Gust(
						KitMath.TimeBase(now, runStart, attr(zone, "RunSeeded", false)),
						period,
						attr(zone, "Duty", 0.5),
						attr(zone, "Phase", 0)
					)
				end
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
