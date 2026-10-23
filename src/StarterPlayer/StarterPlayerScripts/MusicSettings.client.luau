-- MusicSettings (docs/STAGES.md §7.7): the "Music: On / Off" row of the Settings panel. It only sets the player attribute
-- MusicMuted, which StageMusic reads; the choice lasts for the session. The panel is part of the ScreenGui that is re-created on
-- every respawn, so the row is added each time it appears.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function addRow(screenGui: Instance)
	local panel = screenGui:WaitForChild("SettingsPanel", 10)
	if not panel or panel:FindFirstChild("MusicRow") then
		return
	end

	local button = Instance.new("TextButton")
	button.Name = "MusicRow"
	button.LayoutOrder = 1
	button.Size = UDim2.new(1, -20, 0, 40)
	button.BackgroundColor3 = StudStyle.PanelColors.SettingsPanel
	button.TextSize = 18

	local function refresh()
		button.Text = "Music: " .. (if player:GetAttribute("MusicMuted") == true then "Off" else "On")
	end
	button.Activated:Connect(function()
		player:SetAttribute("MusicMuted", player:GetAttribute("MusicMuted") ~= true)
		refresh()
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
