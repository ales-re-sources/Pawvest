-- ArenaServer: key and gate rules of the Laser Lab's Key Vault (room 1 of Workspace.World3.Stage14, ArenaConfig; was the
-- KeyArena prototype, docs/STAGES.md §5.2 / §7.12). All parts are Studio-only and found by tag:
--   ArenaKey         pickup: the player holds the key (attribute ArenaKeys) for the rest of the run
--   ArenaLock        zone: touching it with the matching key opens that gate for the player (attribute ArenaOpened)
-- The server never moves or hides a key or a gate: ArenaClient shows each player their own state from the attributes.
-- Keys and opened gates survive deaths (the stage's checkpoints keep the run short) and are reset when a new run starts
-- (CheckpointTouchHandler.RunStarted, the stage's TimerStart) or the player leaves. Spikes are KitKill parts and the
-- checkpoints are ordinary stage checkpoints.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArenaConfig = require(ReplicatedStorage.ArenaConfig)
local CheckpointTouchHandler = require(workspace:WaitForChild("Handlers"):WaitForChild("CheckpointTouchHandler"))

-- Max distance (studs) between the character's root and a key on the server: rejects keys moved on a client.
local MAX_REACH = 15

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

local tagSetups = {
	[ArenaConfig.Tags.Key] = setupKey,
	[ArenaConfig.Tags.Lock] = setupLock,
}
for tag, setup in tagSetups do
	for _, part in CollectionService:GetTagged(tag) do
		setup(part)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(setup)
end

local function resetPlayer(player: Player)
	keys[player] = {}
	opened[player] = {}
	publish(player)
end

Players.PlayerAdded:Connect(resetPlayer)
for _, player in Players:GetPlayers() do
	resetPlayer(player)
end
Players.PlayerRemoving:Connect(function(player)
	keys[player] = nil
	opened[player] = nil
end)
CheckpointTouchHandler.RunStarted:Connect(function(player: Player)
	if keys[player] and (next(keys[player]) or next(opened[player])) then
		resetPlayer(player)
	end
end)
