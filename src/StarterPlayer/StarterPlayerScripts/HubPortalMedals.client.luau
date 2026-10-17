-- Shows the local player's best medal on each hub portal (docs/GDD.md §3 "Hub portals").
-- Medals come from player attributes set by StageResults; every player sees only their own medals.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local GOLD = "#FFD54A"
local UNEARNED = "#D8D8D8" -- light and semi-transparent: readable on the blue portal and against the night sky

local function stars(medal)
	local total = #StageConfig.Medals
	return string.format('<font color="%s">%s</font><font color="%s" transparency="0.45">%s</font>',
		GOLD, string.rep("★", medal), UNEARNED, string.rep("★", total - medal))
end

local function addPortalMedal(stage)
	local portal = workspace:WaitForChild("StartLocation"):WaitForChild(stage.hubPortal):WaitForChild("Portal")

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PortalMedal_" .. stage.folder
	billboard.ResetOnSpawn = false
	billboard.Adornee = portal
	billboard.Size = UDim2.fromScale(5, 1.6) -- studs, so it scales with the portal like its label
	-- on the portal face below the "Stage N access" label; above the frame it hid behind the top-right HUD
	billboard.StudsOffset = Vector3.new(0, -2.2, 0)
	billboard.MaxDistance = 120
	billboard.LightInfluence = 0

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.RichText = true
	label.TextStrokeTransparency = 0.4
	label.Parent = billboard

	local attribute = StageConfig.MedalAttribute(stage)
	local function refresh()
		label.Text = stars(LocalPlayer:GetAttribute(attribute) or 0)
	end
	LocalPlayer:GetAttributeChangedSignal(attribute):Connect(refresh)
	refresh()

	billboard.Parent = playerGui
end

for _, stage in StageConfig.Stages do
	if stage.hubPortal then
		task.spawn(addPortalMedal, stage)
	end
end
