-- HomeService: the Home button (top-left) sends the player one step back: from a stage of a world to the plaza in front of
-- that stage's gate, from anywhere else (hub, the world's courtyard, Tutorial, garden) to the hub spawn. A running stage
-- timer is cancelled and the score panel shows the new place. The remote carries no data; the server decides.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StageConfig = require(ReplicatedStorage.StageConfig)
local TimerHandler = require(workspace.Handlers.PlayerTimerHandler)

local COOLDOWN = 3 -- seconds per player

local goHomeEvent = Instance.new("RemoteEvent")
goHomeEvent.Name = "GoHome"
goHomeEvent.Parent = ReplicatedStorage

local lastUse = {} -- [Player] = os.clock() of the last accepted request

-- True when `position` lies on the plaza of the stage's world (the courtyard: finishing a stage also lands there).
local function onPlaza(stage, position: Vector3): boolean
	local world = StageConfig.Worlds[stage.world]
	local plaza = world and workspace:FindFirstChild(world.folder) and workspace[world.folder]:FindFirstChild("Plaza")
	if not plaza then
		return false
	end
	local local_ = plaza.CFrame:PointToObjectSpace(position)
	local half = plaza.Size / 2
	return math.abs(local_.X) <= half.X and math.abs(local_.Z) <= half.Z and math.abs(local_.Y) <= 30
end

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

	local stage = StageConfig.ByKey[TimerHandler.GetPanelKey(player)]
	if stage and onPlaza(stage, root.Position) then
		stage = nil -- already on the courtyard (e.g. after a finish): Home goes on to the hub
	end
	local destination = if stage and StageConfig.Worlds[stage.world]
		then StageConfig.ReturnSpawn(stage)
		else workspace.StartLocation.SpawnLocation
	character:PivotTo(destination.CFrame + Vector3.new(0, 5, 0))
	TimerHandler.ResetTimer(player) -- leaving the stage cancels a running timer
	TimerHandler.UpdateScorePanel(player, if stage then StageConfig.LocationKey(stage) else StageConfig.HubName)
end)

Players.PlayerRemoving:Connect(function(player)
	lastUse[player] = nil
end)
