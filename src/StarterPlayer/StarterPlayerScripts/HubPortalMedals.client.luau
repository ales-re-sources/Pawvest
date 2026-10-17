-- Shows the local player's best medal above each hub portal (docs/GDD.md §3 "Hub portals").
-- Medals come from player attributes set by StageResults; every player sees only their own medals.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local GOLD = "#FFD54A"
local DIM = "#5A5A5A"

local function stars(medal)
	local total = #StageConfig.Medals
	return string.format('<font color="%s">%s</font><font color="%s">%s</font>',
		GOLD, string.rep("★", medal), DIM, string.rep("★", total - medal))
end

local function addPortalMedal(stage)
	local portal = workspace:WaitForChild("StartLocation"):WaitForChild(stage.hubPortal):WaitForChild("Portal")

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PortalMedal_" .. stage.folder
	billboard.ResetOnSpawn = false
	billboard.Adornee = portal
	billboard.Size = UDim2.fromOffset(150, 40)
	billboard.StudsOffset = Vector3.new(0, 8.5, 0) -- above the portal frame
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
