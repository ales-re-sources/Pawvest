local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local AdminConfig = require(ReplicatedStorage:WaitForChild("AdminConfig"))

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

-- 🐶 Pets button: created here (a copy of the Skills button, so no Studio edit). The panel itself is built by
-- PetsPanel.client.luau in its own ScreenGui "PetsGui" and opened through its SetOpen event / Open attribute.
local petsButton = skillsButton:Clone()
petsButton.Name = "PetsButton"
petsButton.Text = "🐶"
petsButton.Parent = screenGui
local petsGui = playerGui:WaitForChild("PetsGui", 10)
local petsSetOpen = petsGui and petsGui:WaitForChild("SetOpen", 10)

-- Icon order, left to right: Home, Skills, Pets, Settings, Admin (last, only visible to admins).
-- Positions are set here, so adding an icon never needs Studio edits.
for index, icon in { homeButton, skillsButton, petsButton, settingsButton, adminButton } do
	icon.Position = UDim2.new(0, 10 + (index - 1) * 60, 0, 20)
end

local function isAdminUser(userId)
	return AdminConfig.IsAdmin(userId)
end

-- Brick tile look (stud style): the Studio button becomes a transparent click area holding a dark Lip (the brick's
-- side, visible under the face), and a Top frame with the coloured face, two studs on its upper edge and the glyph
-- (the button's old Text). Hover lifts the Top, a press pushes it down onto the lip.
local BRICK_COLORS = {
	HomeButton = Color3.fromRGB(229, 83, 61),
	SkillsButton = Color3.fromRGB(245, 180, 0),
	PetsButton = Color3.fromRGB(58, 165, 92),
	SettingsButton = Color3.fromRGB(47, 127, 214),
	AdminButton = Color3.fromRGB(125, 91, 208),
}
local LIP = 5 -- studs of brick side under the face
local LIFT_HOVER = -2
local LIFT_PRESS = LIP - 2
local LIFT_TWEEN = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function shade(color, factor)
	if factor < 1 then
		return color:Lerp(Color3.new(0, 0, 0), 1 - factor)
	end
	return color:Lerp(Color3.new(1, 1, 1), factor - 1)
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function styleBrick(button)
	local color = BRICK_COLORS[button.Name] or Color3.fromRGB(160, 160, 160)
	local glyphText = button.Text
	button.Text = ""
	button.AutoButtonColor = false
	button.BackgroundTransparency = 1
	button.ClipsDescendants = false
	local stroke = button:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Enabled = false
	end

	local lip = Instance.new("Frame")
	lip.Name = "Lip"
	lip.Size = UDim2.fromScale(1, 1)
	lip.BackgroundColor3 = shade(color, 0.62)
	lip.BorderSizePixel = 0
	corner(lip, 7)
	lip.Parent = button

	local top = Instance.new("Frame")
	top.Name = "Top"
	top.Size = UDim2.new(1, 0, 1, -LIP)
	top.BackgroundTransparency = 1
	top.Parent = button

	for i = 1, 2 do
		local stud = Instance.new("Frame")
		stud.Name = "Stud" .. i
		stud.AnchorPoint = Vector2.new(0.5, 1)
		stud.Position = UDim2.new(i == 1 and 0.3 or 0.7, 0, 0, 2)
		stud.Size = UDim2.fromOffset(14, 7)
		stud.BackgroundColor3 = shade(color, 1.12)
		stud.BorderSizePixel = 0
		corner(stud, 3)
		local studStroke = Instance.new("UIStroke")
		studStroke.Color = shade(color, 0.62)
		studStroke.Thickness = 1.5
		studStroke.Parent = stud
		stud.Parent = top
	end

	local face = Instance.new("Frame")
	face.Name = "Face"
	face.Size = UDim2.fromScale(1, 1)
	face.BackgroundColor3 = color
	face.BorderSizePixel = 0
	corner(face, 7)
	local faceStroke = Instance.new("UIStroke")
	faceStroke.Color = shade(color, 0.62)
	faceStroke.Thickness = 1.5
	faceStroke.Parent = face
	local shine = Instance.new("UIGradient")
	shine.Rotation = 90
	shine.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(215, 215, 215))
	shine.Parent = face
	face.Parent = top

	-- dark round socket behind the glyph: the emoji stay readable on every brick colour (⚡ on yellow, ⚙ on blue)
	local socket = Instance.new("Frame")
	socket.Name = "Socket"
	socket.AnchorPoint = Vector2.new(0.5, 0.5)
	socket.Position = UDim2.fromScale(0.5, 0.5)
	socket.Size = UDim2.fromOffset(34, 34)
	socket.BackgroundColor3 = shade(color, 0.4)
	socket.BackgroundTransparency = 0.25
	socket.BorderSizePixel = 0
	corner(socket, 17)
	socket.Parent = face

	local glyph = Instance.new("TextLabel")
	glyph.Name = "Glyph"
	glyph.Size = UDim2.fromScale(1, 1)
	glyph.BackgroundTransparency = 1
	glyph.Text = glyphText
	glyph.Font = button.Font
	glyph.TextSize = button.TextSize
	glyph.TextColor3 = Color3.new(1, 1, 1)
	glyph.ZIndex = socket.ZIndex + 1
	glyph.Parent = face

	local hovering, pressed = false, false
	local function lift()
		local y = pressed and LIFT_PRESS or (hovering and LIFT_HOVER or 0)
		TweenService:Create(top, LIFT_TWEEN, { Position = UDim2.fromOffset(0, y) }):Play()
	end
	button.MouseEnter:Connect(function()
		hovering = true
		lift()
	end)
	button.MouseLeave:Connect(function()
		hovering, pressed = false, false
		lift()
	end)
	button.MouseButton1Down:Connect(function()
		pressed = true
		lift()
	end)
	button.MouseButton1Up:Connect(function()
		pressed = false
		lift()
	end)
end

for _, icon in { homeButton, skillsButton, petsButton, settingsButton, adminButton } do
	styleBrick(icon)
end

-- Check if player is admin and show/hide admin button accordingly
if isAdminUser(player.UserId) then
	adminButton.Visible = true
end


-- Panel state tracking
local isPanelOpen = false
-- The skills panel is visible from the start, so it counts as the open panel (opening another one closes it)
local lastOpenPanel = skillsPanel.Visible and skillsPanel or nil

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
end

-- Panel animation functions
local function openPanel(panel)
	if lastOpenPanel then
		if (lastOpenPanel == panel) then return end
		closePanel(lastOpenPanel)
	end
	
	closePets()
	lastOpenPanel = panel

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
