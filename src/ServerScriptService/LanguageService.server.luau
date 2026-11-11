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
local Remotes = require(ServerScriptService.Remotes)
local RateLimit = require(ServerScriptService.RateLimit)

-- Set: client -> server (code: string), "" = automatic; SystemLocale: client -> server (localeId: string), the device's
-- locale, once per join
local _, remotes = Remotes.Folder("LanguageRemotes", { "Set", "SystemLocale" })
local setEvent, systemEvent = remotes.Set, remotes.SystemLocale
local allow = RateLimit.new(0.3) -- seconds between requests per player

local systemReported = {} -- [Player] = true once the device locale arrived

local function publish(player: Player, setting: string)
	player:SetAttribute(Locale.SettingAttribute, setting)
	player:SetAttribute(
		Locale.LanguageAttribute,
		if setting ~= "" then setting else Locale.Resolve(player.LocaleId, player:GetAttribute(Locale.SystemAttribute))
	)
end


setEvent.OnServerEvent:Connect(function(player, setting)
	if not Locale.IsValidSetting(player, setting) then
		return
	end
	if not allow(player) then
		return
	end
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

-- the locale until the profile has loaded
Players.PlayerAdded:Connect(function(player)
	publish(player, "")
end)
for _, player in Players:GetPlayers() do
	publish(player, "")
end
-- join and admin reset (a reset profile is automatic again)
PlayerProfile.OnReady(function(player, profile)
	publish(player, if Locale.IsValidSetting(player, profile.Language) then profile.Language else "")
end)

Players.PlayerRemoving:Connect(function(player)
	systemReported[player] = nil
end)
