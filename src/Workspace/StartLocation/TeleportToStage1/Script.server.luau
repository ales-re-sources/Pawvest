local Players = game:GetService("Players")
local StageConfig = require(game:GetService("ReplicatedStorage").StageConfig)
local StageUnlocks = require(game:GetService("ServerScriptService").StageUnlocks)

local stage = StageConfig.ByHubPortal[script.Parent.Name]
local TeleportPart1 = script.Parent.Portal
local TeleportPart2 = workspace[stage.folder].LandingPad.TeleportDestination

local handler = require(workspace.Handlers.PlayerTimerHandler)

-- Table to track cooldowns per player
local playerCooldowns = {}

local COOLDOWN_TIME = 2

local function onTouched(hit)
	local humanoidRootPart = hit.Parent:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			local now = os.clock()
			local lastTouch = playerCooldowns[player]
			if lastTouch and now - lastTouch < COOLDOWN_TIME then
				-- Still in cooldown, ignore
				return
			end
			-- Set cooldown timestamp
			playerCooldowns[player] = now

			-- Locked stage (GDD §3): no teleport, the client shows the requirement and price instead
			local unlocked = StageUnlocks.IsUnlocked(player, stage)
			if not unlocked then
				if unlocked == false then
					StageUnlocks.ShowLocked(player, stage)
				end
				return
			end

			-- Teleport player
			humanoidRootPart.CFrame = TeleportPart2.CFrame + Vector3.new(0, 5, 0)
			handler.UpdateScorePanel(player, stage.key)
		end
	end
end

-- Connect touch event
TeleportPart1.Touched:Connect(onTouched)

Players.PlayerRemoving:Connect(function(player)
	playerCooldowns[player] = nil
end)
