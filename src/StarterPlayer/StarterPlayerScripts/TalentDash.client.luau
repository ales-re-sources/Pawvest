-- Dash talent (S7, docs/STAGES.md §7.10): in the air, Q / gamepad X / the touch button gives a flat burst forward
-- (TalentConfig.DashSpeed for TalentConfig.DashTime, about 10 studs, height held), once per air time; landing, climbing
-- or swimming gives it back. Movement is client-driven in Roblox, so this runs here; the level is the server-owned
-- attribute Talent_Dash (purchase). The action (and with it the touch button) is bound only while the player owns it.
-- While a dash runs the character carries the attribute `Dashing` (TalentDoubleJump ignores jumps then).

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TalentConfig = require(ReplicatedStorage:WaitForChild("TalentConfig"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))

local ACTION = "TalentDash"
local TRAIL_TIME = 0.35 -- seconds the trail stays after the burst

local player = Players.LocalPlayer
local attribute = TalentConfig.AttributeName("Dash")

local humanoid: Humanoid? = nil
local used = false -- the dash of this air time is spent
local dashing = false

local function inAir(h: Humanoid): boolean
	local state = h:GetState()
	return state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping
end

-- A white trail behind the root part for the burst, local only (others see the movement itself)
local function trail(root: BasePart)
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
	task.delay(TalentConfig.DashTime + TRAIL_TIME, function()
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
	if not (h and root) or h.Health <= 0 or used or dashing or not inAir(h) then
		return
	end
	if not TalentConfig.HasDash(TalentConfig.ClampLevel("Dash", player:GetAttribute(attribute))) then
		return
	end
	local direction = Vector3.new(h.MoveDirection.X, 0, h.MoveDirection.Z)
	if direction.Magnitude < 0.1 then
		direction = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	end
	if direction.Magnitude < 0.1 then
		return
	end
	direction = direction.Unit
	used = true
	dashing = true
	character:SetAttribute("Dashing", true)
	trail(root)

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
	while os.clock() - started < TalentConfig.DashTime and h.Health > 0 and root.Parent and inAir(h) do
		RunService.Heartbeat:Wait()
	end
	velocity:Destroy()
	attachment:Destroy()
	if root.Parent and h.Health > 0 then
		-- leave the burst at run speed in the dash direction, falling from rest, so the dash adds no extra momentum
		root.AssemblyLinearVelocity = direction * h.WalkSpeed
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
	h.StateChanged:Connect(function(_, state)
		if state == Enum.HumanoidStateType.Landed or state == Enum.HumanoidStateType.Running
			or state == Enum.HumanoidStateType.Climbing or state == Enum.HumanoidStateType.Swimming then
			used = false
		end
	end)
end

if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)
player:GetAttributeChangedSignal(attribute):Connect(refreshBinding)
Locale.Changed:Connect(refreshBinding)
refreshBinding()
