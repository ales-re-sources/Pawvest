local module = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local TimerHandler = require(script.Parent.PlayerTimerHandler)

-- server -> client (part, first): the player's checkpoint (respawn point) is now that part; CheckpointClient lights its pad
-- (and turns the previous one off) for that player only and plays script.Sound when `first` (first time in the run)
local reachedEvent = Instance.new("RemoteEvent")
reachedEvent.Name = "CheckpointReached"
reachedEvent.Parent = ReplicatedStorage

-- server -> client, no arguments: a new run started; CheckpointClient turns every pad back to "not reached"
local resetEvent = Instance.new("RemoteEvent")
resetEvent.Name = "CheckpointsReset"
resetEvent.Parent = ReplicatedStorage

-- server -> client (stageKey): the player reached a checkpoint of a stage while no timer runs for it (they got in around the
-- gate, e.g. over the courtyard wall): StageExploreWarning tells them this run is not timed
local exploreEvent = Instance.new("RemoteEvent")
exploreEvent.Name = "ExploreWarning"
exploreEvent.Parent = ReplicatedStorage

local EXPLORE_REWARN = 120 -- seconds before the same stage warns the same player again
local explored = {} -- [Player] = { key = stage key, at = os.clock() } of the last warning (cleared when a run starts)
local lastCheckpoints = {} -- [Player] = last checkpoint part touched (respawn point; skips the work on repeated touches)
local reached = {} -- [Player] = { [checkpoint part] = true } reached in the current run: the sound plays once per run
local firstOfStage = {} -- [stage folder] = C part of its lowest-numbered checkpoint (cache)

Players.PlayerRemoving:Connect(function(player)
	lastCheckpoints[player] = nil
	reached[player] = nil
	explored[player] = nil
end)

-- A new run starts (TimerStart): every checkpoint plays its sound and its pad animation again when reached
function module.NewRun(player)
	reached[player] = nil
	explored[player] = nil
	lastCheckpoints[player] = nil -- so the first checkpoint lights again even if it was the last one before
	resetEvent:FireClient(player)
end

-- The stage's start gate (TimerStart) stands just before the first checkpoint: touching it counts as reaching that
-- checkpoint, so walking gate -> plate plays one sound and the respawn point is the plate, not the gate
local function resolve(part)
	if tonumber(part.Parent.Name) then
		return part
	end
	local found, _, folder = pcall(StageConfig.ForInstance, part)
	local stage = if found then folder else part
	while not found and stage.Parent and stage.Parent ~= workspace do
		stage = stage.Parent
	end
	local first = firstOfStage[stage]
	if not (first and first.Parent) then
		first = nil
		local best = math.huge
		for _, d in stage:GetDescendants() do
			local number = d.Name == "C" and d:IsA("BasePart") and tonumber(d.Parent.Name)
			if number and number < best then
				best, first = number, d
			end
		end
		firstOfStage[stage] = first
	end
	return first or part
end

function module.OnTouched(part, hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end

	-- limbs of a dead character falling onto a nearby checkpoint (or the start gate) must not move the respawn point
	local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	part = resolve(part)

	-- a stage's checkpoint without a running timer for that stage: an exploring run. Warn once per stage (again after
	-- EXPLORE_REWARN seconds, e.g. a second visit); this runs on every touch, not only when the respawn point changes, because
	-- the respawn point may already be that plate from an earlier visit
	local found, stage = pcall(StageConfig.ForInstance, part)
	if found then
		local _, runningKey = TimerHandler.GetTimer(player)
		if runningKey ~= stage.key then
			local last = explored[player]
			if not last or last.key ~= stage.key or os.clock() - last.at > EXPLORE_REWARN then
				explored[player] = { key = stage.key, at = os.clock() }
				exploreEvent:FireClient(player, stage.key)
			end
		end
	end
	if lastCheckpoints[player] ~= part then
		lastCheckpoints[player] = part

		-- the pad follows the respawn point (also back to an earlier checkpoint); the sound only on the first reach in this run
		local seen = reached[player]
		if not seen then
			seen = {}
			reached[player] = seen
		end
		local first = not seen[part]
		seen[part] = true
		reachedEvent:FireClient(player, part, first)

		-- checkpoint...
		local checkpointData = ServerStorage:FindFirstChild("CheckpointData")
		if not checkpointData then
			checkpointData = Instance.new("Folder")
			checkpointData.Name = "CheckpointData"
			checkpointData.Parent = ServerStorage
		end

		local userIdString = tostring(player.UserId)
		local checkpointValue = checkpointData:FindFirstChild(userIdString)
		if not checkpointValue then
			checkpointValue = Instance.new("ObjectValue")
			checkpointValue.Name = userIdString
			checkpointValue.Parent = checkpointData

			-- respawn on the stored plate, facing along the course: a plate's front (LookVector, -Z) points downstream
			-- (CameraFacing then turns the camera the same way, the move from the hub spawn counts as a teleport)
			player.CharacterAdded:Connect(function(character)
				task.wait()
				local storedCheckpoint = ServerStorage.CheckpointData[userIdString].Value
				local look = storedCheckpoint.CFrame.LookVector
				local forward = Vector3.new(look.X, 0, look.Z)
				local top = storedCheckpoint.Position.Y + storedCheckpoint.Size.Y / 2
				local position = Vector3.new(storedCheckpoint.Position.X + math.random(-2, 2), top + 4, storedCheckpoint.Position.Z + math.random(-2, 2))
				if forward.Magnitude < 0.1 then
					character:MoveTo(position)
				else
					character:PivotTo(CFrame.lookAt(position, position + forward))
				end
			end)
		end

		checkpointValue.Value = part
	end
end

return module
