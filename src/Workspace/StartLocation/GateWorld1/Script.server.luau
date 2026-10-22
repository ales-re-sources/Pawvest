-- Hub world gate (S4.0, docs/STAGES.md §7.1): touching the gate's Portal teleports the player to the island of its world
-- (StageConfig.Worlds, found by the gate model's name), arriving on the island's spawn pad. The gate is shut until one of the
-- world's stages is open for the player (World 1: Bronze on the Tutorial or buying Stage 1), so nobody walks into a courtyard
-- of closed gates; the client mirrors that (HubGateLocks: a barrier + the unlock popup, HubGateFaces: the lock text).

local Players = game:GetService("Players")
local StageConfig = require(game:GetService("ReplicatedStorage").StageConfig)
local StageUnlocks = require(game:GetService("ServerScriptService").StageUnlocks)
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
	if StageUnlocks.IsWorldOpen(player, world) ~= true then
		return -- shut (or the profile is still loading); the client shows why
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
