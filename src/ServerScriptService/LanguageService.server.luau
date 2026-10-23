-- LanguageService (L1, docs/LOCALIZATION.md): the player's language. The choice is stored in the profile as Language
-- ("" = automatic, else a code of Locale.Supported) and mirrored as the player attributes LanguageSetting (the choice) and
-- Language (the code the clients render in: the choice, or the player's LocaleId when automatic, English when that is
-- unsupported). The Settings row (LanguageSettings.client) sends LanguageRemotes.Set(code or "").

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

local lastSet = {} -- [Player] = os.clock() of the last request

local function valid(setting: any): boolean
	return setting == "" or (type(setting) == "string" and Locale.Supported[setting] ~= nil)
end

local function publish(player: Player, setting: string)
	player:SetAttribute(Locale.SettingAttribute, setting)
	player:SetAttribute(Locale.LanguageAttribute, if setting ~= "" then setting else Locale.FromLocaleId(player.LocaleId))
end

local function setupPlayer(player: Player)
	publish(player, "") -- the locale until the profile has loaded
	local profile = PlayerProfile.WaitFor(player)
	if profile then
		publish(player, if valid(profile.Language) then profile.Language else "")
	end
end

setEvent.OnServerEvent:Connect(function(player, setting)
	if not valid(setting) then
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

PlayerProfile.ProfileReset:Connect(function(player)
	publish(player, "")
end)

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do
	task.spawn(setupPlayer, player)
end

Players.PlayerRemoving:Connect(function(player)
	lastSet[player] = nil
end)
