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
local settingsButton = screenGui:WaitForChild("SettingsButton")
local adminButton = screenGui:WaitForChild("AdminButton")
local adminPanel = screenGui.Parent:WaitForChild("AdminPanel")
local homePanel = screenGui.Parent:WaitForChild("HomePanel")
local settingsPanel = screenGui.Parent:WaitForChild("SettingsPanel")

local function isAdminUser(userId)
	return AdminConfig.IsAdmin(userId)
end

-- Hover effect function
local function createHoverEffect(button)
	local hoverStroke = button:FindFirstChildOfClass("UIStroke")
	if not hoverStroke then return end
	
	local hoverIn = TweenService:Create(hoverStroke, TweenInfo.new(0.2), {Transparency = 0})
	local hoverOut = TweenService:Create(hoverStroke, TweenInfo.new(0.2), {Transparency = 1})
	
	button.MouseEnter:Connect(function()
		hoverIn:Play()
	end)
	
	button.MouseLeave:Connect(function()
		hoverOut:Play()
	end)
end

-- Check if player is admin and show/hide admin button accordingly
if isAdminUser(player.UserId) then
	-- Apply hover effects only if admin
	adminButton.Visible = true
	createHoverEffect(adminButton)
end

-- Apply hover effects to other buttons
createHoverEffect(homeButton)
createHoverEffect(settingsButton)


-- Panel state tracking
local isPanelOpen = false
local lastOpenPanel = nil

local function closePanel(panel)
	if not lastOpenPanel then return end

	local slideOut = TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0, -250, 0, 80.3)
	})
	slideOut:Play()
	slideOut.Completed:Connect(function()
		panel.Visible = false
	end)
	lastOpenPanel = nil
end

-- Panel animation functions
local function openPanel(panel)
	if lastOpenPanel then
		if (lastOpenPanel == panel) then return end
		closePanel(lastOpenPanel)
	end
	
	lastOpenPanel = panel

	panel.Visible = true
	isPanelOpen = true

	local slideIn = TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 10, 0, 80.3)
	})
	slideIn:Play()
end


-- Button click handlers
homeButton.MouseButton1Click:Connect(function()
	if (lastOpenPanel == homePanel) then
		closePanel(homePanel)
	else
		openPanel(homePanel)
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
