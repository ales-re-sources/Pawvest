-- LanguageSettings (L1, docs/LOCALIZATION.md): the "Language" row of the Settings panel, below the Sound row. Each click
-- moves to the next choice, Automatic -> English -> Čeština (-> [Pseudo] in Studio and for admins) -> Automatic, and asks
-- the server (LanguageRemotes.Set); the server stores it in the profile and sets the player attributes LanguageSetting /
-- Language, which every GUI follows. The row: SettingsRow.

local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local SettingsRow = require(script.Parent:WaitForChild("SettingsRow"))
local remotes = ReplicatedStorage:WaitForChild("LanguageRemotes")
local setEvent = remotes:WaitForChild("Set")

-- The server cannot read the device's language: tell it once (it resolves "automatic" from it, Locale.Resolve).
remotes:WaitForChild("SystemLocale"):FireServer(LocalizationService.SystemLocaleId)

local player = Players.LocalPlayer

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

SettingsRow.Mount("LanguageRow", 2, function(button, panel)
	button.Text = rowText()
	-- the panel's title strip is authored in Studio; its text comes from here (L2)
	local titleLabel = panel:FindFirstChild("TitleLabel")
	if titleLabel and titleLabel:IsA("TextLabel") then
		titleLabel.Text = Locale.T("settings.title")
	end
end, function()
	local index = table.find(CHOICES, setting()) or 1
	setEvent:FireServer(CHOICES[index % #CHOICES + 1])
end, { player:GetAttributeChangedSignal(Locale.SettingAttribute) })
