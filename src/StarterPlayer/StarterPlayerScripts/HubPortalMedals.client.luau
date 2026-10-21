-- Shows the local player's best medal on each hub portal, the challenge coins found on the stage (`x/y`) and, while
-- the stage is locked, its requirement and price (docs/GDD.md §3 "Hub portals"). Medals, coins and lock state come from
-- player attributes set by StageResults, ChallengeCoins and StageUnlocks; every player sees only their own.
-- The stars are a SurfaceGui on the same face as the portal's stage-name label ("Stage N"), so they are part of the gate.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local MedalText = require(ReplicatedStorage:WaitForChild("MedalText"))
local ChallengeCoinConfig = require(ReplicatedStorage:WaitForChild("ChallengeCoinConfig"))
local TalentConfig = require(ReplicatedStorage:WaitForChild("TalentConfig"))

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local UNEARNED = "#D8D8D8" -- light and semi-transparent: readable on the blue portal face
local UNEARNED_TRANSPARENCY = 0.45

-- Layout inside the stud-stone arch (H1.1): the visible opening is narrower than the Portal part (the arch steps in
-- at the feet and around the middle), so the lines stay narrow and above the feet.
local DOOR_SHIFT = -0.34 -- how far up the stack moves on a door face
local LINE_TOP = 0.51 -- first line under the stars
local LINE_STEP = 0.085
local LINE_SIZE = UDim2.fromScale(0.74, 0.08)

local function addPortalMedal(stage)
	local portal = StageConfig.FaceTarget(stage)
	local portalLabel = portal:FindFirstChildOfClass("SurfaceGui")
	-- a door has no stage-name label (the gate's sign carries it), so its lines start higher than on a portal face
	local shift = if portalLabel then 0 else DOOR_SHIFT

	local surface = Instance.new("SurfaceGui")
	surface.Name = "PortalMedal_" .. stage.folder
	surface.ResetOnSpawn = false
	surface.Adornee = portal
	surface.Face = if portalLabel then portalLabel.Face else Enum.NormalId.Back
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 50
	surface.LightInfluence = 0

	-- below the stage-name label in the upper part of the face
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.fromScale(0.5, 0.4 + shift)
	label.Size = UDim2.fromScale(0.7, 0.1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.RichText = true
	label.TextStrokeTransparency = 0.4
	if not portalLabel then
		-- on a dark wooden door the default black text is unreadable: white text with a dark outline
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeColor3 = Color3.new(0, 0, 0)
		label.TextStrokeTransparency = 0.2
	end
	label.Parent = surface

	local attribute = StageConfig.MedalAttribute(stage)
	local function refresh()
		label.Text = MedalText.Stars(LocalPlayer:GetAttribute(attribute) or 0, UNEARNED, UNEARNED_TRANSPARENCY)
	end
	LocalPlayer:GetAttributeChangedSignal(attribute):Connect(refresh)
	refresh()

	-- challenge coins found (M4): under the stars, below the lock lines while locked; none for a stage without coins
	local coinLine = nil
	local _, coinCount = ChallengeCoinConfig.Found(stage.key, {})
	if coinCount > 0 then
		coinLine = label:Clone()
		coinLine.Name = "Coins"
		coinLine.Position = UDim2.fromScale(0.5, LINE_TOP + shift)
		coinLine.Size = LINE_SIZE
		coinLine.Parent = surface
		local collectedAttribute = ChallengeCoinConfig.CollectedAttribute
		local function refreshCoins()
			local collected = ChallengeCoinConfig.Decode(LocalPlayer:GetAttribute(collectedAttribute))
			local found, total = ChallengeCoinConfig.Found(stage.key, collected)
			coinLine.Text = string.format("💰 found %d/%d", found, total)
		end
		LocalPlayer:GetAttributeChangedSignal(collectedAttribute):Connect(refreshCoins)
		refreshCoins()
	end

	-- lock lines below the stars while the stage is locked (M3); hidden until the server publishes the state
	local locks = {}
	local bar = MedalText.UnlockBar(stage)
	if bar then
		local lockLines = {
			"🔒 " .. bar,
			if stage.unlockPrice then "or " .. stage.unlockPrice .. " Coins" else nil,
		}
		for index, text in lockLines do
			local lock = label:Clone()
			lock.Name = "Lock" .. index
			lock.Size = LINE_SIZE
			lock.Text = text
			lock.Visible = false
			lock.Parent = surface
			table.insert(locks, lock)
		end
	end

	-- required talents (S1.2): "Needs: Double Jump", green when owned and red when not; no line without requirements
	local needsLine = nil
	if #stage.requires > 0 then
		needsLine = label:Clone()
		needsLine.Name = "Needs"
		needsLine.Size = LINE_SIZE
		needsLine.Parent = surface
	end

	-- the lines stack under the stars: lock lines (only while locked), coins found, needs
	local unlockedAttribute = StageConfig.UnlockedAttribute(stage)
	local function layout()
		local locked = LocalPlayer:GetAttribute(unlockedAttribute) == false
		local row = 0
		for _, lock in locks do
			lock.Visible = locked
			lock.Position = UDim2.fromScale(0.5, LINE_TOP + shift + row * LINE_STEP)
			row += 1
		end
		for _, line in { coinLine, needsLine } do
			line.Position = UDim2.fromScale(0.5, LINE_TOP + shift + row * LINE_STEP)
			row += 1
		end
	end
	local function refreshNeeds()
		if needsLine then
			needsLine.Text = MedalText.Needs(stage, function(id)
				return LocalPlayer:GetAttribute(TalentConfig.AttributeName(id)) or 0
			end) or ""
		end
	end
	LocalPlayer:GetAttributeChangedSignal(unlockedAttribute):Connect(layout)
	for _, need in stage.requires do
		LocalPlayer:GetAttributeChangedSignal(TalentConfig.AttributeName(need.id)):Connect(refreshNeeds)
	end
	layout()
	refreshNeeds()

	surface.Parent = playerGui
end

for _, stage in StageConfig.Stages do
	if stage.hubPortal or StageConfig.Worlds[stage.world] then
		task.spawn(addPortalMedal, stage)
	end
end
