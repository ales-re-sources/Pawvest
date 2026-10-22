-- Hub world gates (S4.0): draws the local player's progress in a world on its gate's face, like HubPortalMedals does for
-- stage portals: the stars earned in the world out of the stars its stages can give, and the challenge coins found. Medals
-- and coins come from the player attributes StageResults and ChallengeCoins keep; every player sees only their own.
-- While the gate is shut (none of the world's stages is open for the player) the face shows what opens it instead.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local ChallengeCoinConfig = require(ReplicatedStorage:WaitForChild("ChallengeCoinConfig"))
local MedalText = require(ReplicatedStorage:WaitForChild("MedalText"))

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local GOLD = "#FFD54A"
local STARS_Y, COINS_Y = 0.46, 0.60 -- under the world name label on the gate face
local LINE_SIZE = UDim2.fromScale(0.7, 0.11)

local function addGate(world)
	local portal = StageConfig.WorldGatePortal(world)
	local nameLabel = portal:FindFirstChildOfClass("SurfaceGui")

	local surface = Instance.new("SurfaceGui")
	surface.Name = "GateFace_" .. world.folder
	surface.ResetOnSpawn = false
	surface.Adornee = portal
	surface.Face = if nameLabel then nameLabel.Face else Enum.NormalId.Back
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 50
	surface.LightInfluence = 0

	local function line(name: string, y: number)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.AnchorPoint = Vector2.new(0.5, 0)
		label.Position = UDim2.fromScale(0.5, y)
		label.Size = LINE_SIZE
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.RichText = true
		label.TextStrokeTransparency = 0.4
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Parent = surface
		return label
	end
	local starsLabel = line("Stars", STARS_Y)
	local coinsLabel = line("Coins", COINS_Y)

	local stages = {}
	for _, stage in StageConfig.Stages do
		if stage.world == world.index then
			table.insert(stages, stage)
		end
	end

	local function refresh()
		local open = false
		for _, stage in stages do
			if LocalPlayer:GetAttribute(StageConfig.UnlockedAttribute(stage)) == true then
				open = true
			end
		end
		local entry = stages[1]
		if not open and entry and entry.unlock then
			starsLabel.Text = "🔒 " .. (MedalText.UnlockBar(entry) or "")
			coinsLabel.Text = if entry.unlockPrice then string.format("or %d Coins", entry.unlockPrice) else ""
			return
		end
		local medals = {}
		for _, stage in stages do
			medals[stage.key] = LocalPlayer:GetAttribute(StageConfig.MedalAttribute(stage)) or 0
		end
		starsLabel.Text = string.format('<font color="%s">★</font> %d / %d', GOLD, StageConfig.WorldStars(medals, world.index), StageConfig.MaxWorldStars(world.index))

		local collected = ChallengeCoinConfig.Decode(LocalPlayer:GetAttribute(ChallengeCoinConfig.CollectedAttribute))
		local found, total = 0, 0
		for _, stage in stages do
			local f, t = ChallengeCoinConfig.Found(stage.key, collected)
			found += f
			total += t
		end
		coinsLabel.Text = string.format("💰 found %d/%d", found, total)
	end

	for _, stage in stages do
		LocalPlayer:GetAttributeChangedSignal(StageConfig.MedalAttribute(stage)):Connect(refresh)
		LocalPlayer:GetAttributeChangedSignal(StageConfig.UnlockedAttribute(stage)):Connect(refresh)
	end
	LocalPlayer:GetAttributeChangedSignal(ChallengeCoinConfig.CollectedAttribute):Connect(refresh)
	refresh()
	surface.Parent = playerGui
end

for _, world in StageConfig.Worlds do
	task.spawn(addGate, world)
end
