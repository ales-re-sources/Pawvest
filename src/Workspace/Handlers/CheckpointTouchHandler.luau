local module = {}

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local lastCheckpoints = {} -- [Player] = last checkpoint part touched (respawn point; skips the work on repeated touches)
local reached = {} -- [Player] = { [checkpoint part] = true } reached in the current run: the sound plays once per run

Players.PlayerRemoving:Connect(function(player)
	lastCheckpoints[player] = nil
	reached[player] = nil
end)

-- A new run starts (TimerStart): every checkpoint plays its sound again when reached
function module.NewRun(player)
	reached[player] = nil
end

function module.OnTouched(part, hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end

	-- limbs of a dead character falling onto a nearby checkpoint (or the start gate) must not move the respawn point
	local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	if lastCheckpoints[player] ~= part then
		lastCheckpoints[player] = part

		-- the start gate (TimerStart) stands next to the first checkpoint: walking between them only plays the sound
		-- the first time each one is reached in this run
		local seen = reached[player]
		if not seen then
			seen = {}
			reached[player] = seen
		end
		if not seen[part] then
			seen[part] = true
			script.Sound:Play()
		end

		-- numbered checkpoints only (the TimerStart's parent is "LandingPad")
		if tonumber(part.Parent.Name) and player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Stage") then
			player.leaderstats.Stage.Value = part.Parent.Name
		end

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

			player.CharacterAdded:connect(function(character)
				wait()
				local storedCheckpoint = ServerStorage.CheckpointData[userIdString].Value
				character:MoveTo(storedCheckpoint.Position + Vector3.new(math.random(-2, 2), 2, math.random(-2, 2)))
			end)
		end

		checkpointValue.Value = part
	end
end

return module
