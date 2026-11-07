--!strict
-- Short UI cues (Creator Store, creator AmbientSorcery, the "ui-simple-*" set; free to use). Client only.
--
--   UiSounds.Play(cue)   cue = "Click" | "Tab" | "Hover" | "Notify"; plays locally (not positional), overlapping itself if needed
--
-- Buttons are wired by UiSoundsClient.client.luau (every GuiButton in PlayerGui plays "Click" when activated); a button picks another
-- cue, or none, with the attribute `UiSound` ("Tab", "Hover", "Notify", or "None" for a button that has its own sound).
-- A cue that fails to load is silent: nothing here can break a UI.

local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")

local UiSounds = {}

-- id: Creator Store asset; volume: UI cues stay under the game sounds; gap: least seconds between two plays of the cue
-- (a quick sweep over many squares must not machine-gun the hover tick)
local CUES = {
	Click = { id = 88442833509532, volume = 0.5, gap = 0.04 }, -- ui-simple-button-click
	Tab = { id = 76353543802706, volume = 0.5, gap = 0.04 }, -- ui-simple-tab-switch
	Hover = { id = 139800881181209, volume = 0.3, gap = 0.08 }, -- ui-simple-button-hover
	Notify = { id = 105983221709653, volume = 0.5, gap = 0.5 }, -- ui-simple-notification
}

local folder: Folder? = nil
local sounds: { [string]: Sound } = {}
local lastPlayed: { [string]: number } = {}

local function soundFor(cue: string): Sound?
	local existing = sounds[cue]
	if existing then
		return existing
	end
	local def = CUES[cue]
	if not def then
		return nil
	end
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "UiSounds"
		folder.Parent = SoundService
	end
	local sound = Instance.new("Sound")
	sound.Name = cue
	sound.SoundId = "rbxassetid://" .. def.id
	sound.Volume = def.volume
	sound.Parent = folder
	sounds[cue] = sound
	return sound
end

function UiSounds.Play(cue: string)
	local def = CUES[cue]
	if not def then
		return
	end
	local now = os.clock()
	if now - (lastPlayed[cue] or -1) < def.gap then
		return
	end
	local sound = soundFor(cue)
	if sound then
		lastPlayed[cue] = now
		sound:SetAttribute("Plays", (sound:GetAttribute("Plays") or 0) + 1) -- PlayLocalSound shows nothing on the Sound: lets a playtest count plays
		SoundService:PlayLocalSound(sound)
	end
end

-- Loads every cue once at start so the first click is not silent
function UiSounds.Preload()
	local list = {}
	for cue in CUES do
		local sound = soundFor(cue)
		if sound then
			table.insert(list, sound)
		end
	end
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync(list)
		end)
	end)
end

return UiSounds
