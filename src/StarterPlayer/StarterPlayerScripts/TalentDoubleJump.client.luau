-- Double Jump talent: lets the player jump again in the air as many times as the server-owned attribute
-- Talent_DoubleJump allows (TalentConfig.AirJumps). Jumping is client-driven in Roblox, so this part must run
-- here; the level itself can only be changed by the server (purchase). Independent of the admin debug toggle.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local TalentConfig = require(ReplicatedStorage:WaitForChild("TalentConfig"))

local MIN_AIR_JUMP_GAP = 0.12 -- seconds; ignores held-key repeats and the ground jump itself

local player = Players.LocalPlayer
local attribute = TalentConfig.AttributeName("DoubleJump")

local humanoid: Humanoid? = nil
local airJumpsUsed = 0
local lastJump = 0

local function onCharacterAdded(character: Model)
	local h = character:WaitForChild("Humanoid") :: Humanoid
	humanoid = h
	airJumpsUsed = 0
	lastJump = os.clock()

	h.StateChanged:Connect(function(_, state)
		if state == Enum.HumanoidStateType.Landed or state == Enum.HumanoidStateType.Running
			or state == Enum.HumanoidStateType.Climbing or state == Enum.HumanoidStateType.Swimming then
			airJumpsUsed = 0
		elseif state == Enum.HumanoidStateType.Jumping then
			lastJump = os.clock() -- the ground jump (and every air jump) restarts the gap
		end
	end)
end

UserInputService.JumpRequest:Connect(function()
	local h = humanoid
	if not h or h.Health <= 0 or (h.Parent and h.Parent:GetAttribute("Dashing")) then
		return -- a jump during a dash (TalentDash, 0.2 s) would only be eaten by its flat burst
	end
	local state = h:GetState()
	if state ~= Enum.HumanoidStateType.Freefall and state ~= Enum.HumanoidStateType.Jumping then
		return -- on the ground the normal jump handles it
	end
	local allowed = TalentConfig.AirJumps(TalentConfig.ClampLevel("DoubleJump", player:GetAttribute(attribute)))
	if airJumpsUsed >= allowed or os.clock() - lastJump < MIN_AIR_JUMP_GAP then
		return
	end
	airJumpsUsed += 1
	lastJump = os.clock()
	h:ChangeState(Enum.HumanoidStateType.Jumping)
end)

if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)
