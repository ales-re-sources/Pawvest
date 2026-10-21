-- Locked hub portals are walls (docs/GDD.md §3): while the local player has not unlocked a stage, an invisible
-- barrier fills the portal opening, so they cannot walk through it. The barriers are local parts: each player only
-- collides with their own, and they vanish when the Unlocked_<folder> attribute turns true.
-- The barrier is thinner than the portal, so a player pressed against it still touches the portal and gets the unlock
-- popup. This is movement feedback only; the server still refuses the teleport of a locked stage (StageUnlocks).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))

local LocalPlayer = Players.LocalPlayer

local BARRIER_DEPTH = 0.5 -- studs; the portal is 1.5 deep, so ~0.5 of it stays reachable from each side

local function addBarrier(stage)
	local portal = workspace:WaitForChild(StageConfig.PortalFolder(stage)):WaitForChild(stage.hubPortal):WaitForChild("Portal")

	local barrier = Instance.new("Part")
	barrier.Name = "PortalBarrier_" .. stage.folder
	barrier.Anchored = true
	barrier.CanTouch = false
	barrier.Transparency = 1
	barrier.Size = Vector3.new(portal.Size.X, portal.Size.Y, BARRIER_DEPTH)
	barrier.CFrame = portal.CFrame

	local attribute = StageConfig.UnlockedAttribute(stage)
	local function refresh()
		local locked = LocalPlayer:GetAttribute(attribute) ~= true -- locked until the server says otherwise
		barrier.CanCollide = locked
		barrier.Parent = if locked then workspace else nil
	end
	LocalPlayer:GetAttributeChangedSignal(attribute):Connect(refresh)
	refresh()
end

for _, stage in StageConfig.Stages do
	if stage.unlock and stage.hubPortal then
		task.spawn(addBarrier, stage)
	end
end
