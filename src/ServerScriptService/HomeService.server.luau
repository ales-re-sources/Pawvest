-- HomeService: the Home button (top-left) sends the player one step back: from a stage of a world to the plaza in front of
-- that stage's gate, from anywhere else (hub, the world's courtyard, Tutorial, garden) to the hub spawn. A running stage
-- timer is cancelled and the score panel shows the new place. The remote carries no data; the server decides.
-- GoGarden (the Pets panel's "Go to my garden" button) works the same way: it lands the player on the grass in front
-- of their borrowed garden plot (GardenPlots), looking at it. Both remotes share one cooldown.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StageConfig = require(ReplicatedStorage.StageConfig)
local GardenPlots = require(game:GetService("ServerScriptService").GardenPlots)
local TimerHandler = require(workspace.Handlers.PlayerTimerHandler)

local COOLDOWN = 3 -- seconds per player
-- garden arrival, in the plot floor's space: its front (-Z, LookVector) faces the garden plaza, the sign stands 22
-- studs out on that side, so the player lands beside the sign's line and turns to the plot centre
local GARDEN_ARRIVAL = Vector3.new(8, 0, -30)

local goHomeEvent = Instance.new("RemoteEvent")
goHomeEvent.Name = "GoHome"
goHomeEvent.Parent = ReplicatedStorage

local goGardenEvent = Instance.new("RemoteEvent")
goGardenEvent.Name = "GoGarden"
goGardenEvent.Parent = ReplicatedStorage

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

-- The live character's root, or nil when it is dead / missing or the player is still cooling down (counts the use).
local function acceptRequest(player: Player): (Model?, BasePart?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then
		return nil, nil
	end
	local now = os.clock()
	if lastUse[player] and now - lastUse[player] < COOLDOWN then
		return nil, nil
	end
	lastUse[player] = now
	return character, root :: BasePart
end

goHomeEvent.OnServerEvent:Connect(function(player)
	local character, root = acceptRequest(player)
	if not character or not root then
		return
	end

	local stage = StageConfig.ByKey[TimerHandler.GetPanelKey(player)]
	if stage and onPlaza(stage, root.Position) then
		stage = nil -- already on the courtyard (e.g. after a finish): Home goes on to the hub
	end
	local destination = if stage and StageConfig.Worlds[stage.world]
		then StageConfig.ReturnSpawn(stage)
		else workspace.StartLocation.SpawnLocation
	character:PivotTo(destination.CFrame + Vector3.new(0, 5, 0))
	TimerHandler.ResetTimer(player, "home") -- leaving the stage cancels a running timer
	TimerHandler.UpdateScorePanel(player, if stage then StageConfig.LocationKey(stage) else StageConfig.HubName)
end)

goGardenEvent.OnServerEvent:Connect(function(player)
	local index = GardenPlots.PlotOf(player)
	local plot = index and GardenPlots.Model(index)
	local floor = plot and (plot.PrimaryPart or plot:FindFirstChild("Floor"))
	if not floor or not floor:IsA("BasePart") then
		return
	end
	local character = acceptRequest(player)
	if not character then
		return
	end
	local position = floor.CFrame:PointToWorldSpace(GARDEN_ARRIVAL) + Vector3.new(0, 5, 0)
	local centre = floor.Position
	character:PivotTo(CFrame.lookAt(position, Vector3.new(centre.X, position.Y, centre.Z)))
	TimerHandler.ResetTimer(player, "home")
	TimerHandler.UpdateScorePanel(player, StageConfig.HubName)
end)

Players.PlayerRemoving:Connect(function(player)
	lastUse[player] = nil
end)
