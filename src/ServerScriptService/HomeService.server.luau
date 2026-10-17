-- HomeService: the Home button (top-left) sends the player back to the hub spawn, like the stage "TeleportToSpawn" portals:
-- a running stage timer is cancelled and the score panel shows the hub. The remote carries no data; the server decides.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StageConfig = require(ReplicatedStorage.StageConfig)
local TimerHandler = require(workspace.Handlers.PlayerTimerHandler)

local COOLDOWN = 3 -- seconds per player

local goHomeEvent = Instance.new("RemoteEvent")
goHomeEvent.Name = "GoHome"
goHomeEvent.Parent = ReplicatedStorage

local lastUse = {} -- [Player] = os.clock() of the last accepted request

goHomeEvent.OnServerEvent:Connect(function(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then
		return
	end
	local now = os.clock()
	if lastUse[player] and now - lastUse[player] < COOLDOWN then
		return
	end
	lastUse[player] = now

	character:PivotTo(workspace.StartLocation.SpawnLocation.CFrame + Vector3.new(0, 5, 0))
	TimerHandler.ResetTimer(player) -- leaving the stage cancels a running timer
	TimerHandler.UpdateScorePanel(player, StageConfig.HubName)
end)

Players.PlayerRemoving:Connect(function(player)
	lastUse[player] = nil
end)
