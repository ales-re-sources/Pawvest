-- HomeService: the Home button (top-left) sends the player one step back: from a stage of a world to the plaza in front of
-- that stage's gate, from anywhere else (hub, the world's courtyard, Tutorial, garden) to the hub spawn. A running stage
-- timer is cancelled and the score panel shows the new place. The remote carries no data; the server decides.
-- GoGarden (the 🌱 Garden icon, top left) works the same way: it lands the player on the grass in front
-- of their borrowed garden plot (GardenPlots; its position from GardenConfig.PlotCFrame, no plot model), looking at it.
-- Each remote has its own cooldown (a shared one swallowed Home right after Garden).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StageConfig = require(ReplicatedStorage.StageConfig)
local GardenConfig = require(ReplicatedStorage.GardenConfig)
local GardenPlots = require(game:GetService("ServerScriptService").GardenPlots)
local TimerHandler = require(workspace.Handlers.PlayerTimerHandler)

local COOLDOWN = 0.5 -- seconds per player and button: only stops double-click spam, chained hops (stage gate → hub) must feel instant
-- garden arrival, in the plot floor's space: its front (-Z, LookVector) faces the garden plaza, the sign stands 22
-- studs out on that side, so the player lands beside the sign's line and turns to the plot centre
local GARDEN_ARRIVAL = Vector3.new(8, 0, -30)

local goHomeEvent = Instance.new("RemoteEvent")
goHomeEvent.Name = "GoHome"
goHomeEvent.Parent = ReplicatedStorage

local goGardenEvent = Instance.new("RemoteEvent")
goGardenEvent.Name = "GoGarden"
goGardenEvent.Parent = ReplicatedStorage

-- One cooldown per button: Garden followed by Home (or the reverse) must work at once, only a repeat of the same button waits.
local lastUse = { home = {}, garden = {} } -- [button][Player] = os.clock() of the last accepted request

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
local function acceptRequest(player: Player, button: string): (Model?, BasePart?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then
		return nil, nil
	end
	local now = os.clock()
	local uses = lastUse[button]
	if uses[player] and now - uses[player] < COOLDOWN then
		return nil, nil
	end
	uses[player] = now
	return character, root :: BasePart
end

goHomeEvent.OnServerEvent:Connect(function(player)
	local character, root = acceptRequest(player, "home")
	if not character or not root then
		return
	end

	local stage = StageConfig.ByKey[TimerHandler.GetPanelKey(player)]
	if stage and onPlaza(stage, root.Position) then
		stage = nil -- already on the courtyard (e.g. after a finish): Home goes on to the hub
	end
	local destination = if stage and StageConfig.Worlds[stage.world]
		then StageConfig.ReturnCFrame(stage)
		else workspace.StartLocation.SpawnLocation.CFrame + Vector3.new(0, 5, 0)
	character:PivotTo(destination)
	TimerHandler.ResetTimer(player, "home") -- leaving the stage cancels a running timer
	TimerHandler.UpdateScorePanel(player, if stage then StageConfig.LocationKey(stage) else StageConfig.HubName)
end)

goGardenEvent.OnServerEvent:Connect(function(player)
	local index = GardenPlots.PlotOf(player)
	local floor = index and GardenConfig.PlotCFrame(index) -- from the slot: no plot model needed (E1.0)
	if not floor then
		return
	end
	local character = acceptRequest(player, "garden")
	if not character then
		return
	end
	local position = floor:PointToWorldSpace(GARDEN_ARRIVAL) + Vector3.new(0, 5, 0)
	local centre = floor.Position
	character:PivotTo(CFrame.lookAt(position, Vector3.new(centre.X, position.Y, centre.Z)))
	TimerHandler.ResetTimer(player, "home")
	TimerHandler.UpdateScorePanel(player, StageConfig.HubName)
end)

Players.PlayerRemoving:Connect(function(player)
	lastUse.home[player] = nil
	lastUse.garden[player] = nil
end)
