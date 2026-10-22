-- HubGateLocks (docs/STAGES.md §7.1): a world's hub gate is shut for the local player until one of the world's stages is open
-- (Unlocked_<folder> attributes from StageUnlocks: World 1 opens with Bronze on the Tutorial or by buying its first stage), so a
-- player is never sent into a courtyard whose gates are all closed. While shut, a local invisible barrier fills the gate's
-- opening, like PortalBarriers does for stage portals, and touching the portal opens the unlock popup (StageUnlockPopup, through
-- the player attribute OpenWorldPopup). Movement feedback only: the server refuses the teleport itself (GateWorld1 script).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))

local LocalPlayer = Players.LocalPlayer

local BARRIER_DEPTH = 0.5 -- studs; the portal is deeper, so a player pressed against the barrier still touches it
local POPUP_COOLDOWN = 1.5 -- seconds between popups from one gate

local function addGate(world)
	local portal = StageConfig.WorldGatePortal(world)
	local stages = StageConfig.StagesOfWorld(world.index)

	local barrier = Instance.new("Part")
	barrier.Name = "GateBarrier_" .. world.folder
	barrier.Anchored = true
	barrier.CanTouch = false
	barrier.Transparency = 1
	barrier.Size = Vector3.new(portal.Size.X, portal.Size.Y, BARRIER_DEPTH)
	barrier.CFrame = portal.CFrame

	local function isOpen(): boolean
		for _, stage in stages do
			if LocalPlayer:GetAttribute(StageConfig.UnlockedAttribute(stage)) == true then
				return true
			end
		end
		return false
	end
	local function refresh()
		local open = isOpen() -- shut until the server says otherwise
		barrier.CanCollide = not open
		barrier.Parent = if open then nil else workspace
	end
	for _, stage in stages do
		LocalPlayer:GetAttributeChangedSignal(StageConfig.UnlockedAttribute(stage)):Connect(refresh)
	end
	refresh()

	local lastPopup = 0
	portal.Touched:Connect(function(hit)
		local character = LocalPlayer.Character
		if not character or not hit:IsDescendantOf(character) then
			return
		end
		if not isOpen() and os.clock() - lastPopup > POPUP_COOLDOWN then
			lastPopup = os.clock()
			LocalPlayer:SetAttribute("OpenWorldPopup", world.index)
		end
	end)
end

for _, world in StageConfig.Worlds do
	task.spawn(addGate, world)
end
