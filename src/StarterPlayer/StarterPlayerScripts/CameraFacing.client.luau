-- Turns the camera the way the character faces after a teleport and on the first spawn. The default camera keeps its
-- heading when the server moves the character, so a player would arrive looking at the wrong thing. The facing itself is
-- set by the teleport targets: the hub SpawnLocation looks at the Tutorial / Stage 1 portals (spawn, Home button and the
-- stage "TeleportToSpawn" portals use its CFrame), each stage's TeleportDestination looks along the course.
-- A respawn on a checkpoint counts as a teleport too: the server moves the new character from the hub spawn onto the
-- plate, facing along the course (CheckpointTouchHandler).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local TELEPORT_DISTANCE = 30 -- studs in one frame ...
local TELEPORT_SPEED = 500 -- ... and studs per second: a falling or lagging character is slower than any teleport
local FOCUS_HEIGHT = 1.5 -- the default camera looks at the head
local MIN_PITCH, MAX_PITCH = -0.5, 0.15 -- look vector Y: the player's own tilt is kept within this range
local SPAWN_DELAY = 0.3 -- seconds for the default camera to settle behind a new character

local function faceForward(root)
	-- a StageCamera mode owns the camera (and puts it behind the character itself when the mode ends)
	local mode = LocalPlayer:GetAttribute("CameraMode")
	if mode ~= nil and mode ~= "Default" then
		return
	end
	local camera = workspace.CurrentCamera
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.1 then
		return
	end
	local focus = root.Position + Vector3.new(0, FOCUS_HEIGHT, 0)
	-- camera and Focus are both still at the old place, so their distance is the player's zoom
	local distance = math.max((camera.CFrame.Position - camera.Focus.Position).Magnitude, 1)
	local pitch = math.clamp(camera.CFrame.LookVector.Y, MIN_PITCH, MAX_PITCH)
	local direction = flat.Unit * math.sqrt(1 - pitch * pitch) + Vector3.new(0, pitch, 0)
	camera.CFrame = CFrame.lookAt(focus - direction * distance, focus)
end

local first = true

local function onCharacter(character)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root then
		return
	end

	if first then
		first = false
		task.wait(SPAWN_DELAY)
		if root.Parent then
			faceForward(root)
		end
	end

	local last = root.Position
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not root.Parent then
			connection:Disconnect()
			return
		end
		local position = root.Position
		local moved = (position - last).Magnitude
		last = position
		if moved > TELEPORT_DISTANCE and moved / math.max(dt, 1 / 240) > TELEPORT_SPEED then
			faceForward(root)
		end
	end)
end

LocalPlayer.CharacterAdded:Connect(onCharacter)
if LocalPlayer.Character then
	task.spawn(onCharacter, LocalPlayer.Character)
end
