-- LanguageSettings (L1, docs/LOCALIZATION.md): the "Language" row of the Settings panel, below the Music row. Each click
-- moves to the next choice, Automatic -> English -> Čeština (-> [Pseudo] in Studio and for admins) -> Automatic, and asks
-- the server (LanguageRemotes.Set); the server stores it in the profile and sets the player attributes LanguageSetting /
-- Language, which every GUI follows. The panel is part of the ScreenGui that is re-created on every respawn, so the row is
-- added each time it appears.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local setEvent = ReplicatedStorage:WaitForChild("LanguageRemotes"):WaitForChild("Set")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CHOICES = Locale.Choices(player) -- "" (automatic), the languages, the pseudo-language in Studio / for admins

local function setting(): string
	local value = player:GetAttribute(Locale.SettingAttribute)
	return if type(value) == "string" and table.find(CHOICES, value) then value else ""
end

local function rowText(): string
	local current = setting()
	local name = if current == ""
		then Locale.T("settings.language.auto", { name = Locale.Names[Locale.Current()] })
		else Locale.Names[current]
	return Locale.T("settings.language", { name = name })
end

local function addRow(screenGui: Instance)
	local panel = screenGui:WaitForChild("SettingsPanel", 10)
	if not panel or panel:FindFirstChild("LanguageRow") then
		return
	end

	local button = Instance.new("TextButton")
	button.Name = "LanguageRow"
	button.LayoutOrder = 2
	button.Size = UDim2.new(1, -20, 0, 40)
	button.BackgroundColor3 = StudStyle.PanelColors.SettingsPanel
	button.TextSize = 18

	-- the panel's title strip is authored in Studio; its text comes from here (L2)
	local titleLabel = panel:FindFirstChild("TitleLabel")
	local function refresh()
		button.Text = rowText()
		if titleLabel and titleLabel:IsA("TextLabel") then
			titleLabel.Text = Locale.T("settings.title")
		end
	end
	button.Activated:Connect(function()
		local index = table.find(CHOICES, setting()) or 1
		setEvent:FireServer(CHOICES[index % #CHOICES + 1])
	end)
	local connections = {
		player:GetAttributeChangedSignal(Locale.SettingAttribute):Connect(refresh),
		Locale.Changed:Connect(refresh),
	}
	button.Destroying:Connect(function()
		for _, connection in connections do
			connection:Disconnect()
		end
	end)
	refresh()
	StudStyle.Brick(button, { studs = 5 })
	button.Parent = panel
end

playerGui.ChildAdded:Connect(function(child)
	if child.Name == "ScreenGui" then
		task.spawn(addRow, child)
	end
end)
local existing = playerGui:FindFirstChild("ScreenGui")
if existing then
	task.spawn(addRow, existing)
end
