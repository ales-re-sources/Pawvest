local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local AdminConfig = require(ReplicatedStorage:WaitForChild("AdminConfig"))
local PanelFocus = require(ReplicatedStorage:WaitForChild("PanelFocus"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local HudLayout = require(ReplicatedStorage:WaitForChild("HudLayout"))
local UiKit = require(ReplicatedStorage:WaitForChild("UiKit"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- This script lives in ScreenGui.TopLeftIcons (the icons' frame; re-created with the ScreenGui on every respawn)
local screenGui = script.Parent
screenGui.Parent.DisplayOrder = 6 -- panels above world hints and the field hand bar

local homeButton = screenGui:WaitForChild("HomeButton")
local skillsButton = screenGui:WaitForChild("SkillsButton")
local settingsButton = screenGui:WaitForChild("SettingsButton")
local adminButton = screenGui:WaitForChild("AdminButton")
local adminPanel = screenGui.Parent:WaitForChild("AdminPanel")
local skillsPanel = screenGui.Parent:WaitForChild("SkillsPanel")
local settingsPanel = screenGui.Parent:WaitForChild("SettingsPanel")

-- Start closed on a fresh join; restore the player's choice when this GUI is re-created on respawn.
-- Apply before waiting for other GUIs so an authored-visible panel cannot linger during startup.
local OPEN_PANEL_ATTRIBUTE = "OpenPanel"
local lastOpenPanel = nil
local remembered = player:GetAttribute(OPEN_PANEL_ATTRIBUTE)
for _, panel in { skillsPanel, settingsPanel, adminPanel } do
	local open = panel.Name == remembered and (panel ~= adminPanel or AdminConfig.IsAdmin(player.UserId))
	panel.Visible = open
	if open then
		lastOpenPanel = panel
	end
end
player:SetAttribute(OPEN_PANEL_ATTRIBUTE, if lastOpenPanel then lastOpenPanel.Name else "")

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
-- Home now means the own farm. The adjacent Gateway button keeps GoHome's stage plaza / central island return.
-- Both use the existing server destinations; HintSources puts the farm's readiness badge on Home.
local gatewayButton = screenGui:FindFirstChild("GatewayButton")
if not gatewayButton then
	gatewayButton = skillsButton:Clone()
	gatewayButton.Name = "GatewayButton"
	for _, child in gatewayButton:GetChildren() do
		if child.Name == "HintDot" or child.Name == "HintBadge" then
			child:Destroy()
		end
	end
	gatewayButton.Text = "🌀"
	gatewayButton.AutoLocalize = false
	gatewayButton.Parent = screenGui
end
local petsGui = playerGui:WaitForChild("PetsGui", 10)
local petsSetOpen = petsGui and petsGui:WaitForChild("SetOpen", 10)

local icons = { homeButton, gatewayButton, skillsButton, petsButton, settingsButton, adminButton }

-- Stud-brick look (ReplicatedStorage.StudStyle): icons as bricks in the colour of the panel they open, the panels in
-- deep tones of that colour, the status card (ScorePanel) as a wooden plate. All of it lives in this ScreenGui,
-- which is re-created on every respawn, so it is styled here each time.
local ICON_COLORS = {
	HomeButton = StudStyle.Colors.Red,
	GatewayButton = StudStyle.Colors.Blue,
	SkillsButton = StudStyle.PanelColors.SkillsPanel,
	PetsButton = StudStyle.Colors.Green,
	SettingsButton = StudStyle.PanelColors.SettingsPanel,
	AdminButton = StudStyle.PanelColors.AdminPanel,
}
for _, icon in icons do
	icon.BackgroundColor3 = ICON_COLORS[icon.Name]
	StudStyle.Brick(icon, { socket = true })
end

for _, panel in { skillsPanel, settingsPanel, adminPanel } do
	StudStyle.Panel(panel, StudStyle.PanelColors[panel.Name])
	panel.Active = true
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
local isAdmin = AdminConfig.IsAdmin(player.UserId)
adminButton.Visible = isAdmin


local function petsOpen()
	return petsGui ~= nil and petsGui:GetAttribute("Open") == true
end

local function closePets()
	if petsSetOpen and petsOpen() then
		petsSetOpen:Fire(false)
	end
end

-- PanelFocus names (U4: one panel at a time across the HUD panels, Pets and the garden's stalls; Skills closes when walking away)
local layout = HudLayout.Get(screenGui.Parent)
local tweens = {}
local function panelPosition(panel, open)
	local scale = panel:FindFirstChild("HudScale")
	return UDim2.fromOffset(if open then layout.left else -(panel.Size.X.Offset * (scale and scale.Scale or 1) + 20), layout.top)
end

local function placePanel(panel, open, animate)
	if tweens[panel] then tweens[panel]:Cancel() end
	if not animate then
		panel.Position = panelPosition(panel, open)
		return
	end
	local tween = TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Quad,
		if open then Enum.EasingDirection.Out else Enum.EasingDirection.In), { Position = panelPosition(panel, open) })
	tweens[panel] = tween
	tween.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed and not open and lastOpenPanel ~= panel then
			panel.Visible = false
		end
	end)
	tween:Play()
end

local function updateNavigation()
	local hidden = layout.overlay and (lastOpenPanel ~= nil or petsOpen())
	for index, icon in icons do
		local col = if layout.compact then (index - 1) % 2 else index - 1
		local row = if layout.compact then (index - 1) // 2 else 0
		icon.Position = UDim2.fromOffset(10 + col * 60, 20 + row * 60)
		icon.Visible = not hidden and (icon ~= adminButton or isAdmin)
	end
end

if petsGui then petsGui:GetAttributeChangedSignal("Open"):Connect(updateNavigation) end

local FOCUS = {
	SkillsPanel = { name = "Skills", distance = nil },
	SettingsPanel = { name = "Settings", distance = math.huge },
	AdminPanel = { name = "Admin", distance = math.huge },
}

local function closePanel(panel)
	if lastOpenPanel ~= panel then return end
	PanelFocus.Closed(FOCUS[panel.Name].name)
	lastOpenPanel = nil
	placePanel(panel, false, true)
	player:SetAttribute(OPEN_PANEL_ATTRIBUTE, "")
	updateNavigation()
end

local function openPanel(panel)
	if lastOpenPanel then
		if lastOpenPanel == panel then return end
		closePanel(lastOpenPanel)
	end
	lastOpenPanel = panel
	player:SetAttribute(OPEN_PANEL_ATTRIBUTE, panel.Name)
	PanelFocus.Open(FOCUS[panel.Name].name, function()
		closePanel(panel)
	end, FOCUS[panel.Name].distance)
	panel.Visible = true
	placePanel(panel, true, true)
	updateNavigation()
end

-- Close stays reachable when portrait panels replace navigation, outside the panel's UIListLayout.
for _, panel in { skillsPanel, settingsPanel, adminPanel } do
	local close = UiKit.Button("Close", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -4, 0, 4),
		Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = StudStyle.Colors.Red,
		Text = "×", -- loc: ignore (close symbol)
		TextSize = 24,
		ZIndex = 10,
		AutoLocalize = false,
	}, 1)
	close.Parent = panel:WaitForChild("TitleLabel")
	close.Activated:Connect(function() closePanel(panel) end)
end

HudLayout.Watch(screenGui.Parent, function(nextLayout)
	layout = nextLayout
	for _, panel in { skillsPanel, settingsPanel, adminPanel } do
		local scale = panel:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
		scale.Name = "HudScale"
		scale.Scale = layout.scale
		scale.Parent = panel
		local width = if panel == skillsPanel then 300 else 250
		panel.Size = UDim2.new(0, math.min(width, layout.width / layout.scale), panel.Size.Y.Scale, panel.Size.Y.Offset)
		local title = panel.TitleLabel
		local closeSize = math.ceil(44 / layout.scale)
		title.Size = UDim2.new(1, 0, 0, closeSize + 8)
		title.Close.Size = UDim2.fromOffset(closeSize, closeSize)
		title.Close.Position = UDim2.new(1, closeSize + 6, 0, 4) -- compensate the title's text padding
		local padding = title:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding")
		padding.PaddingRight = UDim.new(0, closeSize + 10)
		padding.PaddingLeft = UDim.new(0, 6)
		padding.Parent = title
		title.TextWrapped = true
		placePanel(panel, lastOpenPanel == panel, false)
	end
	updateNavigation()
end)

-- A panel restored through a death takes the focus.
if lastOpenPanel then
	local panel = lastOpenPanel
	PanelFocus.Open(FOCUS[panel.Name].name, function()
		closePanel(panel)
	end, FOCUS[panel.Name].distance)
end

-- Button click handlers
-- Gateway: back to the stage's plaza, then Central Island (server validates and cancels a running timer).
local goHomeEvent = ReplicatedStorage:WaitForChild("GoHome")
gatewayButton.Activated:Connect(function()
	goHomeEvent:FireServer()
end)

petsButton.Activated:Connect(function()
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

-- Home: to the own farm (the server checks the plot and the cooldown, cancels a running timer and teleports).
local Hints = require(player:WaitForChild("PlayerScripts"):WaitForChild("Hints"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local goGardenEvent = ReplicatedStorage:WaitForChild("GoGarden")
homeButton.Activated:Connect(function()
	if player:GetAttribute(GardenConfig.PlotAttribute) == nil then
		Hints.Toast(Locale.T("garden.go.notReady"))
		return
	end
	closePets()
	goGardenEvent:FireServer()
end)

local function togglePanel(panel)
	if lastOpenPanel == panel then
		closePanel(panel)
	else
		openPanel(panel)
	end
end

skillsButton.Activated:Connect(function()
	togglePanel(skillsPanel)
end)

-- Open request from another script (StageArrivalWarning's "Open Skills"): a ScreenGui attribute, reset right away
screenGui.Parent:GetAttributeChangedSignal("OpenSkills"):Connect(function()
	if screenGui.Parent:GetAttribute("OpenSkills") then
		screenGui.Parent:SetAttribute("OpenSkills", nil)
		openPanel(skillsPanel)
	end
end)

settingsButton.Activated:Connect(function()
	togglePanel(settingsPanel)
end)

adminButton.Activated:Connect(function()
	if AdminConfig.IsAdmin(player.UserId) then
		togglePanel(adminPanel)
	end
end)

-- Close panel when clicking outside
local userInputService = game:GetService("UserInputService")
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not screenGui.Parent.Enabled then return end -- a reviewer may temporarily hide this HUD
	
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
