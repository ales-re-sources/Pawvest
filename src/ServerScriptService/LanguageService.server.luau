-- LanguageService (L1, docs/LOCALIZATION.md): the player's language. The choice is stored in the profile as Language
-- ("" = automatic, else a code of Locale.Supported) and mirrored as the player attributes LanguageSetting (the choice) and
-- Language (the code the clients render in: the choice; when automatic, Locale.Resolve: the account's LocaleId if it is a
-- supported language other than English, else the device locale the client reports once on join (LanguageRemotes.SystemLocale,
-- attribute SystemLocale), English when neither is supported). The Settings row (LanguageSettings.client) sends LanguageRemotes.Set(code or ""); the pseudo-language
-- (Locale.Pseudo) is accepted in Studio and from admins only.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Locale = require(ReplicatedStorage.Locale)
local PlayerProfile = require(ServerScriptService.PlayerProfile)

local COOLDOWN = 0.3 -- seconds between requests per player

local remotes = Instance.new("Folder")
remotes.Name = "LanguageRemotes"
local setEvent = Instance.new("RemoteEvent") -- client -> server: (code: string), "" = automatic
setEvent.Name = "Set"
setEvent.Parent = remotes
remotes.Parent = ReplicatedStorage

local systemEvent = Instance.new("RemoteEvent") -- client -> server: (localeId: string), the device's locale, once per join
systemEvent.Name = "SystemLocale"
systemEvent.Parent = remotes

local lastSet = {} -- [Player] = os.clock() of the last request
local systemReported = {} -- [Player] = true once the device locale arrived

local function publish(player: Player, setting: string)
	player:SetAttribute(Locale.SettingAttribute, setting)
	player:SetAttribute(
		Locale.LanguageAttribute,
		if setting ~= "" then setting else Locale.Resolve(player.LocaleId, player:GetAttribute(Locale.SystemAttribute))
	)
end

local function setupPlayer(player: Player)
	publish(player, "") -- the locale until the profile has loaded
	local profile = PlayerProfile.WaitFor(player)
	if profile then
		publish(player, if Locale.IsValidSetting(player, profile.Language) then profile.Language else "")
	end
end

setEvent.OnServerEvent:Connect(function(player, setting)
	if not Locale.IsValidSetting(player, setting) then
		return
	end
	local now = os.clock()
	if lastSet[player] and now - lastSet[player] < COOLDOWN then
		return
	end
	lastSet[player] = now
	local profile = PlayerProfile.Get(player)
	if profile then
		profile.Language = setting
	end
	publish(player, setting)
end)

-- Only the language part of the id is used, but the whole id is kept for telemetry; anything that is not a locale id is dropped.
systemEvent.OnServerEvent:Connect(function(player, localeId)
	if systemReported[player] or type(localeId) ~= "string" or not string.match(localeId, "^%a%a%a?[%w%-_]*$") or #localeId > 20 then
		return
	end
	systemReported[player] = true
	player:SetAttribute(Locale.SystemAttribute, string.lower(localeId))
	if player:GetAttribute(Locale.SettingAttribute) == "" then
		publish(player, "") -- automatic: the device may change the language
	end
end)

PlayerProfile.ProfileReset:Connect(function(player)
	publish(player, "")
end)

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do
	task.spawn(setupPlayer, player)
end

Players.PlayerRemoving:Connect(function(player)
	lastSet[player] = nil
	systemReported[player] = nil
end)
