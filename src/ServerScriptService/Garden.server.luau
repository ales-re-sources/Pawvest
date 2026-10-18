-- Garden: boot script of the pet garden (docs/GDD.md §7.6). Starts the plot assignment and the pens / production
-- (GardenService) and wires the two portals:
-- the hub portal Workspace.StartLocation.TeleportToGarden → Workspace.Garden.Arrival, and the garden's
-- Workspace.Garden.ReturnPortal → the hub spawn (a running stage timer is cancelled, like the Home button).
-- The portals are plain Studio-only models (a part named Portal each), so no script lives inside the scene.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local StageConfig = require(ReplicatedStorage.StageConfig)
local TimerHandler = require(workspace.Handlers.PlayerTimerHandler)
require(ServerScriptService.GardenPlots)
require(ServerScriptService.GardenService)

local COOLDOWN = 2 -- seconds per player and portal
local ARRIVAL_SPREAD = 4 -- studs; players arriving together do not stack

-- Calls onEnter(player, character) when a living player's character touches `portal`.
local function connectPortal(portal: BasePart, onEnter: (Player, Model) -> ())
	local lastUse = {} -- [Player] = os.clock() of the last accepted touch
	portal.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not (player and humanoid and humanoid.Health > 0) then
			return
		end
		local now = os.clock()
		if lastUse[player] and now - lastUse[player] < COOLDOWN then
			return
		end
		lastUse[player] = now
		onEnter(player, character)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastUse[player] = nil
	end)
end

local garden = workspace:WaitForChild("Garden", 30)
local hubPortal = workspace:WaitForChild("StartLocation"):WaitForChild("TeleportToGarden", 30)
local arrival = garden and garden:WaitForChild("Arrival", 30)
local returnPortal = garden and garden:WaitForChild("ReturnPortal", 30)
local hubPortalPart = hubPortal and hubPortal:FindFirstChild("Portal")
local returnPortalPart = returnPortal and returnPortal:FindFirstChild("Portal")
if not (arrival and hubPortalPart and returnPortalPart) then
	warn("Garden: scene is incomplete (Garden.Arrival, Garden.ReturnPortal.Portal, StartLocation.TeleportToGarden.Portal)")
	return
end

connectPortal(hubPortalPart, function(_player, character)
	local spread = Vector3.new(math.random(-ARRIVAL_SPREAD, ARRIVAL_SPREAD), 0, math.random(-ARRIVAL_SPREAD, ARRIVAL_SPREAD))
	character:PivotTo(arrival.CFrame + Vector3.new(0, 5, 0) + spread)
end)

connectPortal(returnPortalPart, function(player, character)
	character:PivotTo(workspace.StartLocation.SpawnLocation.CFrame + Vector3.new(0, 5, 0))
	TimerHandler.ResetTimer(player) -- a stage timer cannot run in the garden
	TimerHandler.UpdateScorePanel(player, StageConfig.HubName)
end)
