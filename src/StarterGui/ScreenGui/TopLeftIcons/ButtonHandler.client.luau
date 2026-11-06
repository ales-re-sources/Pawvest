local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local AdminConfig = require(ReplicatedStorage:WaitForChild("AdminConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for the ScreenGui to be available
local screenGui = nil
for _, gui in ipairs(playerGui:GetChildren()) do
	if gui:IsA("ScreenGui") and gui.Name == "ScreenGui" then
		screenGui = gui
		break
	end
end
screenGui = screenGui.TopLeftIcons

if not screenGui then
	return
end

local homeButton = screenGui:WaitForChild("HomeButton")
local skillsButton = screenGui:WaitForChild("SkillsButton")
local settingsButton = screenGui:WaitForChild("SettingsButton")
local adminButton = screenGui:WaitForChild("AdminButton")
local adminPanel = screenGui.Parent:WaitForChild("AdminPanel")
local skillsPanel = screenGui.Parent:WaitForChild("SkillsPanel")
local settingsPanel = screenGui.Parent:WaitForChild("SettingsPanel")

-- 🐶 Pets button: a Studio placeholder like the other icons (mixed mode: Studio holds the buttons, this script styles
-- them); a copy of the Skills button stands in if the placeholder is missing. The panel itself is built by
-- PetsPanel.client.luau in its own ScreenGui "PetsGui" and opened through its SetOpen event / Open attribute.
local petsButton = screenGui:FindFirstChild("PetsButton")
if not petsButton then
	petsButton = skillsButton:Clone()
	petsButton.Name = "PetsButton"
	petsButton.Text = "🐶"
	petsButton.Parent = screenGui
end
-- 🌱 Garden button (U2): made here from the Skills button (no Studio placeholder); teleports to the own plot (GoGarden,
-- HomeService). Its badge (ripe crops + ready eggs) is drawn by Hints / HintSources.
local gardenIcon = screenGui:FindFirstChild("GardenButton")
if not gardenIcon then
	gardenIcon = skillsButton:Clone()
	gardenIcon.Name = "GardenButton"
	for _, child in gardenIcon:GetChildren() do
		if child.Name == "HintDot" or child.Name == "HintBadge" then
			child:Destroy()
		end
	end
	gardenIcon.Text = "🌱"
	gardenIcon.Parent = screenGui
end
local petsGui = playerGui:WaitForChild("PetsGui", 10)
local petsSetOpen = petsGui and petsGui:WaitForChild("SetOpen", 10)

-- Icon order, left to right: Home, Skills, Pets, Garden, Settings, Admin (last, only visible to admins).
-- Positions are set here, so adding an icon never needs Studio edits.
for index, icon in { homeButton, skillsButton, petsButton, gardenIcon, settingsButton, adminButton } do
	icon.Position = UDim2.new(0, 10 + (index - 1) * 60, 0, 20)
end

local function isAdminUser(userId)
	return AdminConfig.IsAdmin(userId)
end

-- Stud-brick look (ReplicatedStorage.StudStyle): icons as bricks in the colour of the panel they open, the panels in
-- deep tones of that colour, the status card (ScorePanel) as a wooden plate. All of it lives in this ScreenGui,
-- which is re-created on every respawn, so it is styled here each time.
local ICON_COLORS = {
	HomeButton = StudStyle.Colors.Red,
	SkillsButton = StudStyle.PanelColors.SkillsPanel,
	PetsButton = StudStyle.Colors.Green,
	GardenButton = StudStyle.Colors.Wood, -- the garden's wood (the Garden panel, the plot signs)
	SettingsButton = StudStyle.PanelColors.SettingsPanel,
	AdminButton = StudStyle.PanelColors.AdminPanel,
}
for _, icon in { homeButton, skillsButton, petsButton, gardenIcon, settingsButton, adminButton } do
	icon.BackgroundColor3 = ICON_COLORS[icon.Name]
	StudStyle.Brick(icon, { socket = true })
end
for _, panel in { skillsPanel, settingsPanel, adminPanel } do
	StudStyle.Panel(panel, StudStyle.PanelColors[panel.Name])
end

local scorePanel = screenGui.Parent:FindFirstChild("ScorePanel")
if scorePanel then
	StudStyle.Plate(scorePanel, StudStyle.Colors.Wood)
	for _, label in scorePanel:GetChildren() do
		if label:IsA("TextLabel") then
			StudStyle.Title(label, StudStyle.Colors.Wood)
		end
	end
end

-- Check if player is admin and show/hide admin button accordingly
if isAdminUser(player.UserId) then
	adminButton.Visible = true
end


-- Panel state tracking
local isPanelOpen = false
-- This ScreenGui is re-created on every respawn, with the Skills panel visible as authored. The first spawn keeps that
-- (it counts as the open panel: opening another one closes it); after that the player's own choice is restored, so a
-- panel they closed stays closed through a death. The choice lives in a player attribute ("" = none open).
local OPEN_PANEL_ATTRIBUTE = "OpenPanel"
local lastOpenPanel = skillsPanel.Visible and skillsPanel or nil
local remembered = player:GetAttribute(OPEN_PANEL_ATTRIBUTE)
if remembered ~= nil then
	lastOpenPanel = nil
	for _, panel in { skillsPanel, settingsPanel, adminPanel } do
		local open = panel.Name == remembered and (panel ~= adminPanel or isAdminUser(player.UserId))
		panel.Visible = open
		panel.Position = UDim2.new(0, if open then 10 else -250, 0, 80.3)
		if open then
			lastOpenPanel = panel
		end
	end
end
player:SetAttribute(OPEN_PANEL_ATTRIBUTE, if lastOpenPanel then lastOpenPanel.Name else "")

local function petsOpen()
	return petsGui ~= nil and petsGui:GetAttribute("Open") == true
end

local function closePets()
	if petsSetOpen and petsOpen() then
		petsSetOpen:Fire(false)
	end
end

local function closePanel(panel)
	if not lastOpenPanel then return end

	local slideOut = TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0, -250, 0, 80.3)
	})
	slideOut:Play()
	slideOut.Completed:Connect(function()
		if lastOpenPanel ~= panel then -- not reopened in the meantime
			panel.Visible = false
		end
	end)
	lastOpenPanel = nil
	player:SetAttribute(OPEN_PANEL_ATTRIBUTE, "")
end

-- Panel animation functions
local function openPanel(panel)
	if lastOpenPanel then
		if (lastOpenPanel == panel) then return end
		closePanel(lastOpenPanel)
	end
	
	closePets()
	lastOpenPanel = panel
	player:SetAttribute(OPEN_PANEL_ATTRIBUTE, panel.Name)

	panel.Visible = true
	isPanelOpen = true

	local slideIn = TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 10, 0, 80.3)
	})
	slideIn:Play()
end


-- Button click handlers
-- Home: back to the hub (the server validates, cancels a running timer and teleports)
local goHomeEvent = ReplicatedStorage:WaitForChild("GoHome")
homeButton.MouseButton1Click:Connect(function()
	goHomeEvent:FireServer()
end)

petsButton.MouseButton1Click:Connect(function()
	if not petsSetOpen then
		return
	end
	if petsOpen() then
		petsSetOpen:Fire(false)
	else
		if lastOpenPanel then
			closePanel(lastOpenPanel)
		end
		petsSetOpen:Fire(true)
	end
end)

-- Garden: to the own plot (the server checks the plot and the cooldown, cancels a running timer and teleports)
local Hints = require(player:WaitForChild("PlayerScripts"):WaitForChild("Hints"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local goGardenEvent = ReplicatedStorage:WaitForChild("GoGarden")
gardenIcon.MouseButton1Click:Connect(function()
	if player:GetAttribute("GardenPlot") == nil then
		Hints.Toast(Locale.T("garden.go.notReady"))
		return
	end
	closePets()
	goGardenEvent:FireServer()
end)

skillsButton.MouseButton1Click:Connect(function()
	if (lastOpenPanel == skillsPanel) then
		closePanel(skillsPanel)
	else
		openPanel(skillsPanel)
	end
end)

-- Open request from another script (StageArrivalWarning's "Open Skills"): a ScreenGui attribute, reset right away
screenGui.Parent:GetAttributeChangedSignal("OpenSkills"):Connect(function()
	if screenGui.Parent:GetAttribute("OpenSkills") then
		screenGui.Parent:SetAttribute("OpenSkills", nil)
		openPanel(skillsPanel)
	end
end)

settingsButton.MouseButton1Click:Connect(function()
	if (lastOpenPanel == settingsPanel) then
		closePanel(settingsPanel)
	else
		openPanel(settingsPanel)
	end
end)

adminButton.MouseButton1Click:Connect(function()
	if isAdminUser(player.UserId) then
		if (lastOpenPanel == adminPanel) then
			closePanel(adminPanel)
		else
			openPanel(adminPanel)
		end
	end
end)

-- Close panel when clicking outside
local userInputService = game:GetService("UserInputService")
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.UserInputType == Enum.UserInputType.MouseButton1 and lastOpenPanel then
		local mousePos = userInputService:GetMouseLocation() - game:GetService("GuiService"):GetGuiInset()
		local panelPos = lastOpenPanel.AbsolutePosition
		local panelSize = lastOpenPanel.AbsoluteSize
		
		-- Check if click is outside the panel
		if mousePos.X < panelPos.X or mousePos.X > panelPos.X + panelSize.X or
		   mousePos.Y < panelPos.Y or mousePos.Y > panelPos.Y + panelSize.Y then
			closePanel(lastOpenPanel)
		end
	end
end)
