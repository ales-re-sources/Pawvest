-- Quick Respawn, client side (docs/STAGES.md §6.2.1, Talent_QuickRespawn level 2):
--   * fall reset: a falling character that is more than the stage's depth below its checkpoint plate is put back on the
--     plate, facing along the course, without dying (the same placement as a respawn); the stage timer keeps running;
--   * a short fade after an instant respawn or a fall reset.
-- The current checkpoint comes from CheckpointReached / CheckpointsReset (the server decides the respawn point; this only
-- mirrors it). The depth is the stage folder's attribute FallResetDepth (studs, default 30; 0 turns the reset off, e.g. on
-- the dropper stage where falling is the course), but the reset always happens SEA_MARGIN studs above the sea
-- (workspace.DebugBaseplate, the kill floor), so a plate close to the sea still resets before the fall kills. Plates farther than MAX_DISTANCE away (e.g. a player who went Home and
-- fell off the hub island) are ignored. Kit-local obstacles (S3) reset themselves when they listen to Respawned below.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local TalentConfig = require(ReplicatedStorage:WaitForChild("TalentConfig"))
local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local reachedEvent = ReplicatedStorage:WaitForChild("CheckpointReached")
local resetEvent = ReplicatedStorage:WaitForChild("CheckpointsReset")

local TALENT = TalentConfig.AttributeName("QuickRespawn")
local DEFAULT_DEPTH = 30 -- studs below the plate's top
local MAX_DISTANCE = 300 -- studs (horizontal) between the character and its plate
local SEA_MARGIN = 5 -- studs above the kill floor's top
local COOLDOWN = 0.5 -- seconds between resets
local FADE_TIME = 0.3

local player = Players.LocalPlayer

local plate = nil -- BasePart of the current checkpoint, nil after a new run starts until its first plate is reached
local lastReset = 0

-- Fires after every fall reset (kit-local obstacles can reset their per-player state here).
local respawned = Instance.new("BindableEvent")
respawned.Name = "Respawned"
respawned.Parent = script

local function level(): number
	return TalentConfig.ClampLevel("QuickRespawn", player:GetAttribute(TALENT))
end

local fade = Instance.new("Frame")
fade.Name = "Fade"
fade.Size = UDim2.fromScale(1, 1)
fade.BackgroundColor3 = Color3.new(0, 0, 0)
fade.BackgroundTransparency = 1
fade.BorderSizePixel = 0
fade.Active = false
local fadeGui = Instance.new("ScreenGui")
fadeGui.Name = "QuickRespawnFade"
fadeGui.ResetOnSpawn = false
fadeGui.IgnoreGuiInset = true
fadeGui.DisplayOrder = 20
fade.Parent = fadeGui
fadeGui.Parent = player:WaitForChild("PlayerGui")

local function flash()
	fade.BackgroundTransparency = 0.35
	TweenService:Create(fade, TweenInfo.new(FADE_TIME), { BackgroundTransparency = 1 }):Play()
end

local function stageDepth(part: BasePart): number
	-- the stage folder (Workspace.World1.Stage4 …), or for a plate outside every stage the top-level folder it lies in
	local found, _, folder = pcall(StageConfig.ForInstance, part)
	local stage = if found then folder else part
	while not found and stage.Parent and stage.Parent ~= workspace do
		stage = stage.Parent
	end
	local depth = stage:GetAttribute("FallResetDepth")
	return if type(depth) == "number" then depth else DEFAULT_DEPTH
end

local function placeOnPlate(character: Model, target: BasePart)
	local look = target.CFrame.LookVector
	local forward = Vector3.new(look.X, 0, look.Z)
	local top = target.Position.Y + target.Size.Y / 2
	local position = Vector3.new(target.Position.X, top + 4, target.Position.Z)
	if forward.Magnitude < 0.1 then
		character:PivotTo(CFrame.new(position))
	else
		character:PivotTo(CFrame.lookAt(position, position + forward))
	end
end

reachedEvent.OnClientEvent:Connect(function(part)
	plate = part
end)
resetEvent.OnClientEvent:Connect(function()
	plate = nil
end)
-- the run ended (finish, Home, cancel): the finish teleport can land far below the last plate (the Clocktower's roof is
-- 100 studs above the World 2 plaza), which must not count as a fall
ReplicatedStorage:WaitForChild("StageTimerUpdate").OnClientEvent:Connect(function(elapsed)
	if type(elapsed) == "number" and elapsed < 0 then
		plate = nil
	end
end)

-- Fade after an instant respawn (not on the join spawn, nor with the slower respawns that have their own wait).
local firstSpawn = true
player.CharacterAdded:Connect(function()
	if firstSpawn then
		firstSpawn = false
		return
	end
	if level() >= 2 then
		flash()
	end
end)

game:GetService("RunService").Heartbeat:Connect(function()
	if not TalentConfig.HasFallReset(level()) then
		return
	end
	local target = plate
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (target and target.Parent and humanoid and root) or humanoid.Health <= 0 then
		return
	end
	local depth = stageDepth(target)
	if depth <= 0 or root.AssemblyLinearVelocity.Y >= 0 then
		return -- off for this stage, or not falling
	end
	local top = target.Position.Y + target.Size.Y / 2
	local limit = top - depth
	local sea = workspace:FindFirstChild("DebugBaseplate")
	if sea and sea:IsA("BasePart") then
		limit = math.max(limit, sea.Position.Y + sea.Size.Y / 2 + SEA_MARGIN)
	end
	if root.Position.Y > limit then
		return
	end
	local offset = root.Position - target.Position
	if Vector3.new(offset.X, 0, offset.Z).Magnitude > MAX_DISTANCE then
		return
	end
	if os.clock() - lastReset < COOLDOWN then
		return
	end
	lastReset = os.clock()

	placeOnPlate(character, target)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	flash()
	respawned:Fire(target)
end)
