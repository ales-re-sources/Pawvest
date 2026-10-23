-- Locale (L1, docs/LOCALIZATION.md): player-visible text by key. Shared.
--   Locale.T(key, args?, lang?)  the text of `key` in `lang` (default: Current()), "{name}" placeholders filled from
--                                `args`; an argument may itself be a key ({ key = "stage.name.Stage6", args = … }); a
--                                string with plural forms picks one by args.count. Fallback: lang -> English -> the key.
--   Locale.Current()             the player's language on a client (player attribute Language, else the client's
--                                LocaleId); "en" on the server, which never builds translated text but sends keys
--   Locale.Changed               client: fires when the language changes
--   Locale.SetKey(label, key, args?) / Locale.SetText(label, text)
--                                a label shows a key (attributes LocKey / LocArgs + tag Loc, rendered per player by
--                                LocalizedText.client) or a literal (times, star lines; the key is cleared)
-- Strings live in ReplicatedStorage.Strings.<Area>: ["area.thing.detail"] = { en = "…", cs = "…" }. Keys are never
-- renamed once shipped; every key needs every supported language (Locale.Missing(lang) lists the gaps).

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Locale = {}

Locale.Default = "en"
Locale.Supported = { en = "English", cs = "Čeština" } -- native names (the language row shows them untranslated)
Locale.Order = { "en", "cs" } -- order of the Settings row
Locale.Tag = "Loc"
Locale.KeyAttribute = "LocKey"
Locale.ArgsAttribute = "LocArgs"
Locale.LanguageAttribute = "Language" -- player attribute: the resolved language code (LanguageService)
Locale.SettingAttribute = "LanguageSetting" -- player attribute: the stored choice, "" = automatic

local AREAS = { "Common", "Names", "Hud" } -- modules in ReplicatedStorage.Strings

local strings = {}
local folder = script.Parent:WaitForChild("Strings")
for _, area in AREAS do
	for key, entry in require(folder:WaitForChild(area)) :: any do
		if strings[key] then
			warn("Locale: duplicate key " .. key .. " in Strings." .. area)
		end
		strings[key] = entry
	end
end

-- "cs-cz" -> "cs"; an unsupported locale -> English
function Locale.FromLocaleId(localeId: string?): string
	local code = string.lower(string.match(localeId or "", "^(%a+)") or "")
	return if Locale.Supported[code] then code else Locale.Default
end

local isClient = RunService:IsClient()
local localPlayer = if isClient then Players.LocalPlayer else nil

function Locale.Current(): string
	if not localPlayer then
		return Locale.Default
	end
	local code = localPlayer:GetAttribute(Locale.LanguageAttribute)
	if type(code) == "string" and Locale.Supported[code] then
		return code
	end
	return Locale.FromLocaleId(localPlayer.LocaleId)
end

local changed = Instance.new("BindableEvent")
Locale.Changed = changed.Event
if localPlayer then
	local last = Locale.Current()
	localPlayer:GetAttributeChangedSignal(Locale.LanguageAttribute):Connect(function()
		local now = Locale.Current()
		if now ~= last then
			last = now
			changed:Fire(now)
		end
	end)
end

-- index of the plural form for `count`: English { one, other }, Czech { one, few (2-4), other }
local function pluralIndex(lang: string, count: number?): number
	if type(count) ~= "number" then
		return 2
	end
	if lang == "cs" then
		if count == 1 then
			return 1
		elseif count >= 2 and count <= 4 and count == math.floor(count) then
			return 2
		end
		return 3
	end
	return if count == 1 then 1 else 2
end

local function format(value: any, lang: string): string
	if type(value) == "table" and type(value.key) == "string" then
		return Locale.T(value.key, value.args, lang)
	elseif type(value) == "number" and value == math.floor(value) and math.abs(value) < 1e15 then
		return string.format("%d", value)
	end
	return tostring(value)
end

function Locale.T(key: string, args: { [string]: any }?, lang: string?): string
	lang = lang or Locale.Current()
	local entry = strings[key]
	local text = entry and (entry[lang] or entry[Locale.Default])
	if text == nil then
		return key
	end
	if type(text) == "table" then
		local forms = text :: { string }
		text = forms[math.min(pluralIndex(lang :: string, args and args.count), #forms)]
	end
	if args then
		text = string.gsub(text, "{(%w+)}", function(name)
			local value = args[name]
			if value == nil then
				return nil -- an unknown placeholder stays visible
			end
			return format(value, lang :: string)
		end)
	end
	return text
end

function Locale.Has(key: string): boolean
	return strings[key] ~= nil
end

-- Display names: the key when it exists, else the config's English name
local function named(key: string, fallback: string): string
	return if strings[key] then Locale.T(key) else fallback
end

function Locale.StageName(stage): string
	return named("stage.name." .. stage.key, stage.displayName)
end

function Locale.WorldName(world): string
	return named("world.name." .. world.index, world.name)
end

function Locale.HubName(): string
	return named("hub.name", "Central Island")
end

function Locale.MedalName(medal): string -- an entry of StageConfig.Medals
	return named("medal.name." .. medal.name, medal.name)
end

function Locale.TalentName(talent): string -- an entry of TalentConfig.List
	return named("talent.name." .. talent.id, talent.name)
end

function Locale.EggName(egg): string -- an entry of PetConfig.Eggs
	return named("pet.egg." .. egg.id, egg.name)
end

-- The label shows `key` (with `args`) in each viewer's language; the English text is written as the fallback
function Locale.SetKey(label: any, key: string, args: { [string]: any }?)
	label:SetAttribute(Locale.KeyAttribute, key)
	label:SetAttribute(Locale.ArgsAttribute, if args then HttpService:JSONEncode(args) else nil)
	CollectionService:AddTag(label, Locale.Tag)
	label.Text = Locale.T(key, args)
end

-- The label shows a literal (no translation): clears a key set before
function Locale.SetText(label: any, text: string)
	if label:GetAttribute(Locale.KeyAttribute) ~= nil then
		label:SetAttribute(Locale.KeyAttribute, nil)
		label:SetAttribute(Locale.ArgsAttribute, nil)
		CollectionService:RemoveTag(label, Locale.Tag)
	end
	label.Text = text
end

-- Keys that have no text in `lang` (the missing-key check; run it from the command bar or the MCP)
function Locale.Missing(lang: string): { string }
	local list = {}
	for key, entry in strings do
		if entry[lang] == nil then
			table.insert(list, key)
		elseif type(entry[lang]) == "table" and #entry[lang] ~= (if lang == "cs" then 3 else 2) then
			table.insert(list, key .. " (plural forms)")
		end
	end
	table.sort(list)
	return list
end

return Locale
