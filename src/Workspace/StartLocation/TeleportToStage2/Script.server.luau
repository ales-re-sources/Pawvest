local TeleportPart1 = script.Parent.Portal
local TeleportPart2 = script.Parent.Parent.Parent.Stage2.LandingPad.TeleportDestination

local handler = require(workspace.Handlers.PlayerTimerHandler)

-- Table to track cooldowns per player
local playerCooldowns = {}

local COOLDOWN_TIME = 2

local function onTouched(hit)
	local humanoidRootPart = hit.Parent:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			local now = os.clock()
			local lastTouch = playerCooldowns[player]
			if lastTouch and now - lastTouch < COOLDOWN_TIME then
				-- Still in cooldown, ignore
				return
			end
			-- Set cooldown timestamp
			playerCooldowns[player] = now

			-- Teleport player
			humanoidRootPart.CFrame = TeleportPart2.CFrame + Vector3.new(0, 5, 0)
			handler.UpdateScorePanel(player, "Stage 2")
		end
	end
end

-- Connect touch event
TeleportPart1.Touched:Connect(onTouched)
