-- KitTide (docs/STAGES.md §7.13, S8.3 Rising Tide): a lava tide that rises under a stage while the local player runs it.
-- A tide is a flat part tagged "KitTide" inside a stage folder (CanCollide / CanTouch / CanQuery off); its X / Z extent is the
-- footprint, its Studio position is where it parks (hidden) when no run of its stage is active. Only its height moves, and only
-- on the running player's client: every player races their own tide, other players see none.
-- Each checkpoint plate (`C`) of the stage carries TideFloor (world y of the tide's top) and TideSpeed (studs/s, default the
-- tide's own Speed attribute, else 1.5). Reaching a checkpoint (CheckpointReached: the gate counts as the first plate) and
-- every respawn there put the tide's top at that plate's floor; it rises from there at that speed. A plate without TideFloor
-- parks the tide (a segment without lava). The tide stops while the character is dead.
-- Any character whose feet are below the top inside the footprint dies (client kill, reported to telemetry like ObstacleKit's
-- kills). A Studio-only Sound child "Rumble" plays (2D) louder as the gap between the feet and the top drops below
-- RUMBLE_RANGE studs; silent without it.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))

local player = Players.LocalPlayer

local DEFAULT_SPEED = 1.5 -- studs/s
local SINK_SPEED = 40 -- studs/s: how fast the shown tide sinks to a checkpoint's floor (the real top drops at once)
local RUMBLE_RANGE = 15 -- studs between the feet and the top below which the rumble grows

local tides = {} -- [part] = { cframe, transparency, folder, rumble = Sound?, volume }
local runKey: string? = nil -- stage key of the player's running timer
local plate: BasePart? = nil -- the current checkpoint plate (respawn point)

local active = nil -- the tide part that is up, or nil
local top = 0 -- world y of the tide's top (kills)
local shown = 0 -- world y the part shows (sinks smoothly after a checkpoint)
local speed = DEFAULT_SPEED

local function folderOf(part: Instance): (Instance?, string?)
	local stage, folder = StageConfig.TryForInstance(part)
	if stage then
		return folder, stage.key
	end
	return nil, nil
end

local function park(part: BasePart)
	local data = tides[part]
	part.CFrame = data.cframe
	part.Transparency = 1
	if data.rumble then
		data.rumble:Stop()
	end
end

local function addTide(part: Instance)
	if not part:IsA("BasePart") or tides[part] then
		return
	end
	local folder = folderOf(part)
	local data = { cframe = part.CFrame, transparency = part.Transparency, folder = folder, rumble = nil, volume = 0 }
	local sound = part:FindFirstChild("Rumble")
	if sound and sound:IsA("Sound") then
		local rumble = sound:Clone()
		rumble.Looped = true
		rumble.Parent = script -- outside Workspace a Sound plays 2D, not from the middle of a huge slab
		data.rumble = rumble
		data.volume = sound.Volume
	end
	tides[part] = data
	park(part)
end

local function removeTide(part: Instance)
	local data = tides[part]
	if data then
		if data.rumble then
			data.rumble:Destroy()
		end
		tides[part] = nil
		if active == part then
			active = nil
		end
	end
end

-- Put the tide at the current plate's floor, or park it when this run, plate or stage has none.
local function reset()
	local wanted = nil
	local floor = plate and plate.Parent and plate:GetAttribute("TideFloor")
	if runKey and type(floor) == "number" then
		local folder, key = folderOf(plate)
		if key == runKey then
			for part, data in tides do
				if data.folder == folder then
					wanted = part
					break
				end
			end
		end
	end
	if active and active ~= wanted then
		park(active)
	end
	if not wanted then
		active = nil
		return
	end
	local data = tides[wanted]
	speed = plate:GetAttribute("TideSpeed") or wanted:GetAttribute("Speed") or DEFAULT_SPEED
	top = floor
	if active ~= wanted then
		shown = floor
		wanted.Transparency = data.transparency
		if data.rumble then
			data.rumble.Volume = 0
			data.rumble:Play()
		end
	end
	active = wanted
end

local function kill(part: BasePart, humanoid: Humanoid)
	humanoid.Health = 0
	player:SetAttribute("KitKillAt", workspace:GetServerTimeNow())
	player:SetAttribute("KitKilledBy", part.Parent.Name .. "." .. part.Name)
	-- telemetry (T1a): the server cannot see a client kill's cause
	local remotes = ReplicatedStorage:FindFirstChild("TelemetryRemotes")
	local report = remotes and remotes:FindFirstChild("Report")
	if report then
		report:FireServer("kill", part)
	end
end

for _, part in CollectionService:GetTagged("KitTide") do
	addTide(part)
end
CollectionService:GetInstanceAddedSignal("KitTide"):Connect(addTide)
CollectionService:GetInstanceRemovedSignal("KitTide"):Connect(removeTide)

ReplicatedStorage:WaitForChild("StageTimerUpdate").OnClientEvent:Connect(function(elapsed: number, stageKey: string?)
	local key = if type(elapsed) == "number" and elapsed >= 0 then stageKey else nil
	if key ~= runKey then
		runKey = key
		reset()
	end
end)
ReplicatedStorage:WaitForChild("CheckpointReached").OnClientEvent:Connect(function(part: BasePart)
	plate = part
	reset()
end)
ReplicatedStorage:WaitForChild("CheckpointsReset").OnClientEvent:Connect(function()
	plate = nil
	reset()
end)
-- a respawn (and Quick Respawn's fall reset, which keeps the character) starts the segment's tide over
player.CharacterAdded:Connect(reset)
task.spawn(function()
	local quickRespawn = script.Parent:WaitForChild("QuickRespawnClient", 10)
	local respawned = quickRespawn and quickRespawn:WaitForChild("Respawned", 10)
	if respawned then
		respawned.Event:Connect(reset)
	end
end)

RunService.PreSimulation:Connect(function(dt: number)
	local part = active
	if not part then
		return
	end
	local data = tides[part]
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local alive = humanoid and root and humanoid.Health > 0

	if alive then
		top += speed * dt
	end
	shown = if shown > top then math.max(top, shown - SINK_SPEED * dt) else top
	local position = data.cframe.Position
	part.CFrame = data.cframe.Rotation + Vector3.new(position.X, shown - part.Size.Y / 2, position.Z)

	if not alive then
		if data.rumble then
			data.rumble.Volume = 0
		end
		return
	end
	local feet = root.Position.Y - root.Size.Y / 2 - humanoid.HipHeight
	local offset = data.cframe:PointToObjectSpace(root.Position)
	local inside = math.abs(offset.X) <= part.Size.X / 2 and math.abs(offset.Z) <= part.Size.Z / 2
	if data.rumble then
		local gap = feet - top
		data.rumble.Volume = if inside then data.volume * math.clamp(1 - gap / RUMBLE_RANGE, 0, 1) else 0
	end
	if inside and feet < top then
		kill(part, humanoid)
	end
end)
