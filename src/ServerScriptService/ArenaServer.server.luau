-- ArenaServer: rules of the key arena (Workspace.KeyArena, ArenaConfig). All parts are Studio-only and found by tag:
--   ArenaSpike       a touch kills the character
--   ArenaCheckpoint  plate C of a numbered checkpoint model: handed to CheckpointTouchHandler (respawn point, pad animation)
--   ArenaKey         pickup: the player holds the key (attribute ArenaKeys) until they leave through the exit
--   ArenaLock        zone: touching it with the matching key opens that gate for the player (attribute ArenaOpened)
--   ArenaExit        zone: with every key the player is sent back to the start and the keys / gates reset (ArenaClears + 1)
-- The server never moves or hides a key or a gate: ArenaClient shows each player their own state from the attributes.
-- Keys and opened gates survive deaths (the checkpoints keep the run short) and are reset by the exit or when the player leaves.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArenaConfig = require(ReplicatedStorage.ArenaConfig)
local CheckpointTouchHandler = require(workspace:WaitForChild("Handlers"):WaitForChild("CheckpointTouchHandler"))

-- Max distance (studs) between the character's root and a key on the server: rejects keys moved on a client.
local MAX_REACH = 15
local START_CHECKPOINT = "301"

local keys = {} -- [Player] = { [keyId] = true }
local opened = {} -- [Player] = { [keyId] = true }

local function publish(player: Player)
	player:SetAttribute(ArenaConfig.KeysAttribute, ArenaConfig.Encode(keys[player] or {}))
	player:SetAttribute(ArenaConfig.OpenedAttribute, ArenaConfig.Encode(opened[player] or {}))
end

-- player, humanoid and root part of a live character touching something, or nil
local function aliveCharacter(hit: BasePart)
	local character = hit.Parent
	local player = character and Players:GetPlayerFromCharacter(character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if player and humanoid and humanoid.Health > 0 and root then
		return player, humanoid, root
	end
	return nil
end

local function setupSpike(part: Instance)
	if part:IsA("BasePart") then
		part.Touched:Connect(function(hit)
			local _, humanoid = aliveCharacter(hit)
			if humanoid then
				humanoid.Health = 0
			end
		end)
	end
end

local function setupCheckpoint(part: Instance)
	if part:IsA("BasePart") then
		part.Touched:Connect(function(hit)
			CheckpointTouchHandler.OnTouched(part, hit)
		end)
	end
end

local function setupKey(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	local id = part:GetAttribute(ArenaConfig.KeyAttribute)
	part.Touched:Connect(function(hit)
		local player, _, root = aliveCharacter(hit)
		if not player or not keys[player] or keys[player][id] then
			return
		end
		if (root.Position - part.Position).Magnitude > MAX_REACH then
			return
		end
		keys[player][id] = true
		if part:GetAttribute(ArenaConfig.OpensGateAttribute) then
			opened[player][id] = true
		end
		publish(player)
	end)
end

local function setupLock(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	local id = part:GetAttribute(ArenaConfig.KeyAttribute)
	part.Touched:Connect(function(hit)
		local player = aliveCharacter(hit)
		if player and keys[player] and keys[player][id] and not opened[player][id] then
			opened[player][id] = true
			publish(player)
		end
	end)
end

local function startPlate(): BasePart?
	local folder = workspace:FindFirstChild(ArenaConfig.Folder)
	local model = folder and folder:FindFirstChild(START_CHECKPOINT)
	local plate = model and model:FindFirstChild("C")
	return plate and plate:IsA("BasePart") and plate or nil
end

local function setupExit(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	part.Touched:Connect(function(hit)
		local player, _, root = aliveCharacter(hit)
		if not player or not keys[player] or not ArenaConfig.HasAllKeys(keys[player]) then
			return
		end
		keys[player] = {}
		opened[player] = {}
		publish(player)
		player:SetAttribute(ArenaConfig.ClearsAttribute, (player:GetAttribute(ArenaConfig.ClearsAttribute) or 0) + 1)
		-- back to the start, which is also the respawn point again
		local plate = startPlate()
		if plate then
			local top = plate.Position.Y + plate.Size.Y / 2
			root.Parent:PivotTo(CFrame.lookAt(Vector3.new(plate.Position.X, top + 4, plate.Position.Z), Vector3.new(plate.Position.X + 1, top + 4, plate.Position.Z)))
			CheckpointTouchHandler.OnTouched(plate, root)
		end
	end)
end

local tagSetups = {
	[ArenaConfig.Tags.Spike] = setupSpike,
	[ArenaConfig.Tags.Checkpoint] = setupCheckpoint,
	[ArenaConfig.Tags.Key] = setupKey,
	[ArenaConfig.Tags.Lock] = setupLock,
	[ArenaConfig.Tags.Exit] = setupExit,
}
for tag, setup in tagSetups do
	for _, part in CollectionService:GetTagged(tag) do
		setup(part)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(setup)
end

local function setupPlayer(player: Player)
	keys[player] = {}
	opened[player] = {}
	player:SetAttribute(ArenaConfig.ClearsAttribute, 0)
	publish(player)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do
	setupPlayer(player)
end
Players.PlayerRemoving:Connect(function(player)
	keys[player] = nil
	opened[player] = nil
end)
