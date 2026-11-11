-- SoundSettings (docs/STAGES.md §7.7): the "Sound: On / Off" row of the Settings panel. It sets the player attribute
-- SoundMuted (the choice lasts for the session) and mutes every sound of the game: each Sound that appears in Workspace,
-- SoundService or the PlayerGui is routed through one master SoundGroup whose Volume drops to 0 while muted, so no sound
-- script has to know about the setting (StageMusic also reads the attribute to skip its beat ticks). The row: SettingsRow.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local SettingsRow = require(script.Parent:WaitForChild("SettingsRow"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local master = Instance.new("SoundGroup")
master.Name = "MasterSoundGroup"
master.Volume = 1
master.Parent = SoundService

local function route(sound: Sound)
	if sound.SoundGroup ~= master then
		sound.SoundGroup = master
	end
end

local function watch(root: Instance)
	root.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("Sound") then
			route(descendant)
		end
	end)
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("Sound") then
			route(descendant)
		end
	end
end

local function applyMute()
	master.Volume = if player:GetAttribute("SoundMuted") == true then 0 else 1
end
player:GetAttributeChangedSignal("SoundMuted"):Connect(applyMute)
applyMute()

watch(workspace)
watch(SoundService)
watch(playerGui)

SettingsRow.Mount("SoundRow", 1, function(button)
	local state = Locale.T(if player:GetAttribute("SoundMuted") == true then "common.off" else "common.on")
	button.Text = Locale.T("settings.sound", { state = state })
end, function()
	player:SetAttribute("SoundMuted", player:GetAttribute("SoundMuted") ~= true)
end)
