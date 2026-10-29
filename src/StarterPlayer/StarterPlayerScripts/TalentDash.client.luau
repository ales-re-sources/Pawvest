-- Dash talent (S7, docs/STAGES.md §7.10): in the air, Q / gamepad X / the touch button gives a flat burst forward
-- (TalentConfig.DashSpeed for TalentConfig.DashTime(level): about 10 studs, 16 with Long Dash (level 2); height held), once per air time; landing, climbing
-- or swimming gives it back. Movement is client-driven in Roblox, so this runs here; the level is the server-owned
-- attribute Talent_Dash (purchase). The action (and with it the touch button) is bound only while the player owns it.
-- While a dash runs the character carries the attribute `Dashing` (TalentDoubleJump ignores jumps then).
-- "On the ground" is a probe under the root, not the humanoid state: under a low roof (Stage 14's tower, 7.5 high) the
-- humanoid reports Landed / Running with the feet still 2 studs up, which cut the dash after 2 studs (2026-10-29).
-- A wall ahead ends the burst at the wall: the unlimited force pinned the character there and threw it back on release.
-- A glancing wall is slid along instead (a dash facing a little off a narrow lane kept going before the wall check).

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TalentConfig = require(ReplicatedStorage:WaitForChild("TalentConfig"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))

local ACTION = "TalentDash"
local TRAIL_TIME = 0.35 -- seconds the trail stays after the burst
local GROUND_SLACK = 0.6 -- feet this close above a floor count as standing
local WALL_LOOKAHEAD = 1 / 30 -- seconds of burst checked ahead for a wall each frame
local SLIDE_MIN = 0.5 -- share of the burst along a wall below which the dash stops at it (more than 60 degrees into it)

local player = Players.LocalPlayer
local attribute = TalentConfig.AttributeName("Dash")

local humanoid: Humanoid? = nil
local used = false -- the dash of this air time is spent
local dashing = false

local probe = RaycastParams.new()
probe.FilterType = Enum.RaycastFilterType.Exclude
probe.RespectCanCollide = true

-- the root's footprint swept down to just below the feet
local function grounded(h: Humanoid, root: BasePart): boolean
	probe.CollisionGroup = root.CollisionGroup
	local reach = root.Size.Y / 2 + h.HipHeight + GROUND_SLACK
	return workspace:Blockcast(CFrame.new(root.Position), Vector3.new(root.Size.X, 0.1, root.Size.Z), Vector3.new(0, -reach, 0), probe) ~= nil
end

local function airborne(h: Humanoid, root: BasePart): boolean
	local state = h:GetState()
	if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping then
		return true
	end
	if state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.RunningNoPhysics
		or state == Enum.HumanoidStateType.Landed then
		return not grounded(h, root)
	end
	return false -- climbing, swimming, seated, dead…
end

-- A white trail behind the root part for the burst, local only (others see the movement itself)
local function trail(root: BasePart, duration: number)
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0.8, 0)
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -0.8, 0)
	local t = Instance.new("Trail")
	t.Attachment0 = a0
	t.Attachment1 = a1
	t.Lifetime = 0.25
	t.Color = ColorSequence.new(Color3.new(1, 1, 1))
	t.Transparency = NumberSequence.new(0.3, 1)
	t.LightEmission = 0.5
	t.FaceCamera = true
	a0.Parent = root
	a1.Parent = root
	t.Parent = root
	task.delay(duration + TRAIL_TIME, function()
		t.Enabled = false
		task.wait(t.Lifetime)
		t:Destroy()
		a0:Destroy()
		a1:Destroy()
	end)
end

local function dash()
	local h = humanoid
	local character = h and h.Parent
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (h and root) or h.Health <= 0 or used or dashing or not airborne(h, root) then
		return
	end
	local level = TalentConfig.ClampLevel("Dash", player:GetAttribute(attribute))
	if not TalentConfig.HasDash(level) then
		return
	end
	local duration = TalentConfig.DashTime(level)
	local direction = Vector3.new(h.MoveDirection.X, 0, h.MoveDirection.Z)
	if direction.Magnitude < 0.1 then
		direction = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	end
	if direction.Magnitude < 0.1 then
		return
	end
	direction = direction.Unit
	-- off ice (ObstacleKit's ice-air) the slide is kept after the burst: a dash shifts the player but is no brake or U-turn
	local velocity0 = root.AssemblyLinearVelocity
	local slide = if character:GetAttribute("IceAir") == true then Vector3.new(velocity0.X, 0, velocity0.Z) else nil
	used = true
	dashing = true
	character:SetAttribute("Dashing", true)
	trail(root, duration)

	-- a world-space LinearVelocity without a force limit holds the burst (and the height) against gravity and air control
	local attachment = Instance.new("Attachment")
	attachment.Name = "DashAttachment"
	attachment.Parent = root
	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "DashVelocity"
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	velocity.ForceLimitsEnabled = false
	velocity.VectorVelocity = direction * TalentConfig.DashSpeed
	velocity.Parent = root

	local started = os.clock()
	local walled = false
	local speed = TalentConfig.DashSpeed
	while os.clock() - started < duration and h.Health > 0 and root.Parent and airborne(h, root) do
		probe.CollisionGroup = root.CollisionGroup
		-- 0.2 shorter than the root, so a roof or floor it skims is no wall
		local box = Vector3.new(root.Size.X, root.Size.Y - 0.2, root.Size.Z)
		local facing = CFrame.lookAt(root.Position, root.Position + direction)
		local hit = workspace:Blockcast(facing.Rotation + root.Position, box, direction * (speed * WALL_LOOKAHEAD), probe)
		if hit then
			root.CFrame += direction * math.max(hit.Distance - 0.05, 0)
			-- a glancing hit slides along the wall with what is left of the burst (the narrow 2.5D lanes: a dash
			-- facing a little off the lane must not stop at the lane wall); a near head-on one stops there
			local normal = Vector3.new(hit.Normal.X, 0, hit.Normal.Z)
			local along = if normal.Magnitude > 0.1 then direction - normal.Unit * direction:Dot(normal.Unit) else Vector3.zero
			if along.Magnitude < SLIDE_MIN then
				walled = true
				break
			end
			speed *= along.Magnitude
			direction = along.Unit
			velocity.VectorVelocity = direction * speed
		end
		RunService.Heartbeat:Wait()
	end
	velocity:Destroy()
	attachment:Destroy()
	if root.Parent and h.Health > 0 then
		-- leave the burst at run speed in the dash direction, falling from rest, so the dash adds no extra momentum;
		-- against a wall, at rest
		root.AssemblyLinearVelocity = if walled then Vector3.zero else slide or direction * h.WalkSpeed
	end
	dashing = false
	if character.Parent then
		character:SetAttribute("Dashing", nil)
	end
end

local function onAction(_, inputState: Enum.UserInputState)
	if inputState == Enum.UserInputState.Begin then
		task.spawn(dash)
	end
	return Enum.ContextActionResult.Sink
end

local bound = false
local function refreshBinding()
	local owned = TalentConfig.HasDash(TalentConfig.ClampLevel("Dash", player:GetAttribute(attribute)))
	if owned and not bound then
		ContextActionService:BindAction(ACTION, onAction, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonX)
		bound = true
	elseif not owned and bound then
		ContextActionService:UnbindAction(ACTION)
		bound = false
	end
	if bound then
		ContextActionService:SetTitle(ACTION, Locale.T("talent.dash.button")) -- touch button only
	end
end

local function onCharacterAdded(character: Model)
	local h = character:WaitForChild("Humanoid") :: Humanoid
	humanoid = h
	used = false
	dashing = false
	probe.FilterDescendantsInstances = { character }
	h.StateChanged:Connect(function(_, state)
		if state == Enum.HumanoidStateType.Climbing or state == Enum.HumanoidStateType.Swimming then
			used = false
		end
	end)
end

-- standing again gives the dash back (the probe, not Landed: a low roof makes the humanoid "land" in mid-air)
RunService.Heartbeat:Connect(function()
	local h = humanoid
	if not used or dashing or not h then
		return
	end
	local root = h.Parent and h.Parent:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root and grounded(h, root) then
		used = false
	end
end)

if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)
player:GetAttributeChangedSignal(attribute):Connect(refreshBinding)
Locale.Changed:Connect(refreshBinding)
refreshBinding()
