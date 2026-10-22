-- StageCamera (S3.2b, docs/STAGES.md §5.1): camera modes for special stages, all client side. A mode is a fixed-heading
-- camera that follows the character: the default controls stay natural ("W = up the screen") because the movement keys
-- are read against the camera's CFrame, also on mobile. Roblox has no orthographic camera, so Iso uses a far camera with a
-- narrow field of view. The camera is Scriptable while a mode is active, so mouse-wheel zoom and the shift-lock camera
-- (both parts of the default camera scripts) do nothing then; a script cannot switch the shift-lock option off (Studio-only
-- property).
--
-- Modes (defaults; every number can be overridden by an attribute on the zone / stage folder):
--   Iso    Yaw 45  Pitch 35 Distance 150 Fov 20    isometric view from above (the maze)
--   Side   Yaw 0   Pitch 3  Distance 40  Fov 55  Lead 6    side view of a 2D course (look along -Z, course along X)
--   Down   Yaw 0   Pitch 80 Distance 35  Fov 60    looking down a shaft (the dropper)
--   Front  Yaw 90  Pitch 12 Distance 22  Fov 65    the camera ahead of the character, facing it (chase stage)
-- Yaw is the heading the camera looks along (0 = toward -Z, 90 = toward -X), Pitch the downward angle in degrees, Lead
-- shifts the view that many studs to the screen's right (negative = left), Height lifts the focus above the root part.
--
-- Where a mode applies (the first that matches wins):
--   1. CameraZone: a part tagged "CameraZone" with attribute Mode ("Iso" / "Side" / "Down" / "Front"); active while the
--      character's root part is inside the part's box (its own box orientation counts). Priority (default 0) picks between
--      overlapping zones, then the smaller volume. The part is hidden for players (it stays visible in Studio).
--   2. Stage attribute: a stage folder in Workspace with attribute CameraMode applies while that stage's timer runs
--      (StageTimerUpdate carries the stage key); it ends with the run: finish, cancel, Home and the return portal.
-- Leaving a mode (or a respawn / teleport) blends back to the normal behind-the-character camera. Diagnostics: the player
-- attributes CameraMode ("Default" or the mode) and CameraZone (name of the zone, "" if none).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))

local player = Players.LocalPlayer

local MODES = {
	Iso = { Yaw = 45, Pitch = 35, Distance = 150, Fov = 20, Lead = 0, Height = 2 },
	Side = { Yaw = 0, Pitch = 3, Distance = 40, Fov = 55, Lead = 6, Height = 2 },
	Down = { Yaw = 0, Pitch = 80, Distance = 35, Fov = 60, Lead = 0, Height = 0 },
	Front = { Yaw = 90, Pitch = 12, Distance = 22, Fov = 65, Lead = 0, Height = 2 },
}
local BLEND_TIME = 0.5 -- seconds to blend into and out of a mode
local FOLLOW_RATE = 10 -- 1 / s: how fast the focus follows the character
local TELEPORT_DISTANCE = 30 -- studs in one frame: the camera snaps instead of gliding after a teleport
local EXIT_DISTANCE = 12 -- studs behind the character when a mode ends
local EXIT_HEIGHT = 5

local zones = {} -- [part] = true
local runStageKey: string? = nil -- stage whose timer runs (StageTimerUpdate), for stage-attribute modes

local function addZone(part: Instance)
	if part:IsA("BasePart") then
		zones[part] = true
		part.Transparency = 1 -- Studio keeps its authored look; players never see the boxes
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
	end
end
local function removeZone(part: Instance)
	zones[part] = nil
end
for _, part in CollectionService:GetTagged("CameraZone") do
	addZone(part)
end
CollectionService:GetInstanceAddedSignal("CameraZone"):Connect(addZone)
CollectionService:GetInstanceRemovedSignal("CameraZone"):Connect(removeZone)

local timerUpdate = ReplicatedStorage:WaitForChild("StageTimerUpdate")
timerUpdate.OnClientEvent:Connect(function(elapsed: number, stageKey: any)
	if elapsed >= 0 and type(stageKey) == "string" then
		runStageKey = stageKey
	else
		runStageKey = nil
	end
end)

-- the mode table (merged with attribute overrides) of the first source that applies, plus its name and source name
local function currentMode(root: BasePart)
	local best, bestPriority, bestVolume = nil, -math.huge, math.huge
	for zone in zones do
		local mode = zone:GetAttribute("Mode")
		if MODES[mode] then
			local local_ = zone.CFrame:PointToObjectSpace(root.Position)
			local half = zone.Size / 2
			if math.abs(local_.X) <= half.X and math.abs(local_.Y) <= half.Y and math.abs(local_.Z) <= half.Z then
				local priority = zone:GetAttribute("Priority") or 0
				local volume = zone.Size.X * zone.Size.Y * zone.Size.Z
				if priority > bestPriority or (priority == bestPriority and volume < bestVolume) then
					best, bestPriority, bestVolume = zone, priority, volume
				end
			end
		end
	end
	local source = best
	if not source and runStageKey then
		local stage = StageConfig.ByKey[runStageKey]
		local folder = stage and StageConfig.FindStageFolder(stage)
		if folder and MODES[folder:GetAttribute("CameraMode")] then
			source = folder
		end
	end
	if not source then
		return nil
	end
	local name = source:GetAttribute("Mode") or source:GetAttribute("CameraMode")
	local params = {}
	for key, value in MODES[name] do
		local override = source:GetAttribute(key)
		params[key] = if type(override) == "number" then override else value
	end
	return name, params, source
end

-- camera CFrame for a mode looking at `root`
local function modeFrame(params, focusPosition: Vector3): CFrame
	local yaw, pitch = math.rad(params.Yaw), math.rad(params.Pitch)
	local heading = Vector3.new(-math.sin(yaw), 0, -math.cos(yaw))
	local look = heading * math.cos(pitch) + Vector3.new(0, -math.sin(pitch), 0)
	local right = heading:Cross(Vector3.yAxis)
	local focus = focusPosition + Vector3.new(0, params.Height, 0) + right * params.Lead
	return CFrame.lookAt(focus - look * params.Distance, focus)
end

local camera = workspace.CurrentCamera
local active: string? = nil -- the mode in force
local params = nil
local focusPosition: Vector3? = nil -- smoothed
local blendFrom: CFrame? = nil -- the camera when the blend began
local blendFromFov = 70
local blendT = 1
local savedFov = 70
local exiting = false -- blending back to the normal camera
local lastRoot: Vector3? = nil

local function publish(mode: string, zoneName: string)
	if player:GetAttribute("CameraMode") ~= mode then
		player:SetAttribute("CameraMode", mode)
	end
	if player:GetAttribute("CameraZone") ~= zoneName then
		player:SetAttribute("CameraZone", zoneName)
	end
end

local function behindFrame(root: BasePart): CFrame
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	flat = if flat.Magnitude > 0.1 then flat.Unit else Vector3.new(0, 0, -1)
	local focus = root.Position + Vector3.new(0, 1.5, 0)
	return CFrame.lookAt(focus - flat * EXIT_DISTANCE + Vector3.new(0, EXIT_HEIGHT, 0), focus)
end

local function startMode(name: string, modeParams, root: BasePart)
	if not active and not exiting then
		savedFov = camera.FieldOfView
	end
	active = name
	params = modeParams
	exiting = false
	blendFrom = camera.CFrame
	blendFromFov = camera.FieldOfView
	blendT = 0
	camera.CameraType = Enum.CameraType.Scriptable
	if not focusPosition then
		focusPosition = root.Position
	end
end

-- Hands the camera back to the default scripts, placed behind `root` (also sets Focus, which the default camera and
-- CameraFacing read to find the player's zoom distance).
local function snapBehind(root: BasePart?)
	if root then
		camera.CFrame = behindFrame(root)
		camera.Focus = CFrame.new(root.Position + Vector3.new(0, 1.5, 0))
	end
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = savedFov
	exiting = false
end

-- Ends the mode: blends back when `root` is given and `snap` is false, otherwise snaps behind `root` at once.
local function stopMode(root: BasePart?, snap: boolean)
	if not active then
		return
	end
	active = nil
	params = nil
	focusPosition = nil
	if root and not snap then
		exiting = true
		blendFrom = camera.CFrame
		blendFromFov = camera.FieldOfView
		blendT = 0
	else
		snapBehind(root)
	end
end

RunService:BindToRenderStep("StageCamera", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
	camera = workspace.CurrentCamera
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		-- dead: the default camera shows the death; a mode ends with it (the respawn arrives as a new character)
		if active then
			stopMode(root, true)
		elseif exiting then
			snapBehind(root)
		end
		lastRoot = nil
		publish("Default", "")
		return
	end

	local name, newParams, source = currentMode(root)
	local teleported = lastRoot ~= nil and (root.Position - lastRoot).Magnitude > TELEPORT_DISTANCE
	lastRoot = root.Position

	if name then
		if name ~= active then
			startMode(name, newParams, root)
		else
			params = newParams
		end
		if teleported or not focusPosition then
			focusPosition = root.Position
			blendT = 1 -- no glide across a teleport
		end
	elseif active then
		stopMode(root, teleported) -- no glide across a teleport (Home, return portal)
	end

	if active and params then
		focusPosition = (focusPosition :: Vector3):Lerp(root.Position, 1 - math.exp(-dt * FOLLOW_RATE))
		local target = modeFrame(params, focusPosition)
		blendT = math.min(blendT + dt / BLEND_TIME, 1)
		local k = blendT * blendT * (3 - 2 * blendT)
		camera.CFrame = (blendFrom :: CFrame):Lerp(target, k)
		camera.FieldOfView = blendFromFov + (params.Fov - blendFromFov) * k
		publish(active, if source and source:IsA("BasePart") then source.Name else "")
	elseif exiting then
		blendT = math.min(blendT + dt / BLEND_TIME, 1)
		local k = blendT * blendT * (3 - 2 * blendT)
		camera.CFrame = (blendFrom :: CFrame):Lerp(behindFrame(root), k)
		camera.FieldOfView = blendFromFov + (savedFov - blendFromFov) * k
		if blendT >= 1 then
			exiting = false
			camera.CameraType = Enum.CameraType.Custom
			camera.FieldOfView = savedFov
		end
		publish("Default", "")
	else
		publish("Default", "")
	end
end)
