-- Hub world gate (S4.0, docs/STAGES.md §7.1): touching the gate's Portal teleports the player to the island of its world
-- (StageConfig.Worlds, found by the gate model's name), arriving on the island's spawn pad. World 1's gate is always open;
-- later worlds get their lock check here (S5). The gate face with stars and coins comes from HubGateFaces.client.

local Players = game:GetService("Players")
local StageConfig = require(game:GetService("ReplicatedStorage").StageConfig)
local TimerHandler = require(workspace.Handlers.PlayerTimerHandler)

local world = StageConfig.WorldByGate[script.Parent.Name]
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

	local spawn = workspace:WaitForChild(world.folder):WaitForChild(world.spawn)
	root.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
	TimerHandler.UpdateScorePanel(player, world.name)
end)

Players.PlayerRemoving:Connect(function(player)
	lastTouch[player] = nil
end)
