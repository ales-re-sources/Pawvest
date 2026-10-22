-- Return gate of a world island (S4.0): touching its Portal teleports the player back to the hub spawn.

local Players = game:GetService("Players")
local StageConfig = require(game:GetService("ReplicatedStorage").StageConfig)
local TimerHandler = require(workspace.Handlers.PlayerTimerHandler)

local portal = script.Parent:WaitForChild("Portal")

local COOLDOWN = 2 -- seconds per player
local lastTouch = {} -- [Player] = os.clock()

portal.Touched:Connect(function(hit)
	local character = hit.Parent
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local player = character and Players:GetPlayerFromCharacter(character)
	if not (player and root) then
		return
	end
	local now = os.clock()
	if lastTouch[player] and now - lastTouch[player] < COOLDOWN then
		return
	end
	lastTouch[player] = now

	root.CFrame = workspace.StartLocation.SpawnLocation.CFrame + Vector3.new(0, 5, 0)
	TimerHandler.UpdateScorePanel(player, StageConfig.HubName)
end)

Players.PlayerRemoving:Connect(function(player)
	lastTouch[player] = nil
end)
