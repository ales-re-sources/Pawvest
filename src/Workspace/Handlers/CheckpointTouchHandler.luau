local module = {}

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local lastCheckpoints = {} -- [Player] = last checkpoint part touched (per-player debounce)

Players.PlayerRemoving:Connect(function(player)
	lastCheckpoints[player] = nil
end)


function module.OnTouched(part, hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)

	if player and lastCheckpoints[player] ~= part then
		lastCheckpoints[player] = part
		script.Sound:Play()

        if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Stage") then
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
