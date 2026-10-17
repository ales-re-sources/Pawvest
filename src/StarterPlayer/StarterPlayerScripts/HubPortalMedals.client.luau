-- Shows the local player's best medal on each hub portal and, while the stage is locked, its requirement and price
-- (docs/GDD.md §3 "Hub portals"). Medals and lock state come from player attributes set by StageResults and StageUnlocks;
-- every player sees only their own.
-- The stars are a SurfaceGui on the same face as the portal's "Stage N access" label, so they are part of the gate.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local MedalText = require(ReplicatedStorage:WaitForChild("MedalText"))

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local UNEARNED = "#D8D8D8" -- light and semi-transparent: readable on the blue portal face
local UNEARNED_TRANSPARENCY = 0.45

local function addPortalMedal(stage)
	local portal = workspace:WaitForChild("StartLocation"):WaitForChild(stage.hubPortal):WaitForChild("Portal")
	local portalLabel = portal:FindFirstChildOfClass("SurfaceGui")

	local surface = Instance.new("SurfaceGui")
	surface.Name = "PortalMedal_" .. stage.folder
	surface.ResetOnSpawn = false
	surface.Adornee = portal
	surface.Face = if portalLabel then portalLabel.Face else Enum.NormalId.Back
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 50
	surface.LightInfluence = 0

	-- below the "Stage N access" label, which sits a bit above the middle of the face
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.fromScale(0.5, 0.56)
	label.Size = UDim2.fromScale(0.8, 0.13)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.RichText = true
	label.TextStrokeTransparency = 0.4
	label.Parent = surface

	local attribute = StageConfig.MedalAttribute(stage)
	local function refresh()
		label.Text = MedalText.Stars(LocalPlayer:GetAttribute(attribute) or 0, UNEARNED, UNEARNED_TRANSPARENCY)
	end
	LocalPlayer:GetAttributeChangedSignal(attribute):Connect(refresh)
	refresh()

	-- lock lines below the stars while the stage is locked (M3); hidden until the server publishes the state
	local bar = MedalText.UnlockBar(stage)
	if bar then
		local lockLines = {
			"🔒 " .. bar,
			if stage.unlockPrice then "or " .. stage.unlockPrice .. " Coins" else nil,
		}
		local locks = {}
		for index, text in lockLines do
			local lock = label:Clone()
			lock.Name = "Lock" .. index
			lock.Position = UDim2.fromScale(0.5, 0.72 + (index - 1) * 0.1)
			lock.Size = UDim2.fromScale(0.9, 0.09)
			lock.Text = text
			lock.Visible = false
			lock.Parent = surface
			table.insert(locks, lock)
		end
		local unlockedAttribute = StageConfig.UnlockedAttribute(stage)
		local function refreshLock()
			local locked = LocalPlayer:GetAttribute(unlockedAttribute) == false
			for _, lock in locks do
				lock.Visible = locked
			end
		end
		LocalPlayer:GetAttributeChangedSignal(unlockedAttribute):Connect(refreshLock)
		refreshLock()
	end

	surface.Parent = playerGui
end

for _, stage in StageConfig.Stages do
	if stage.hubPortal then
		task.spawn(addPortalMedal, stage)
	end
end
