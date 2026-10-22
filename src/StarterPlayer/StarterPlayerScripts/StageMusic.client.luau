-- StageMusic (docs/STAGES.md §5.2, §7.7): the music of a rhythm stage follows the player's run time, so it matches the
-- run-seeded hazards of the kit exactly. A stage opts in with a Studio-only Sound named `Music` in its Workspace folder;
-- attributes on that Sound: BPM (beats per minute), Metronome (true = play it as a short tick on every beat, a quicker
-- one on the first beat of each bar, instead of looping it), BaseVolume (optional, default the Sound's Volume).
-- While the player's timer runs on that stage (StageTimerUpdate) the sound plays; it stops when the run ends or is
-- cancelled. A looped track is kept at TimePosition = run time mod TimeLength (re-synced when it drifts). The player
-- attribute MusicMuted (set by MusicSettings) silences it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local StageTimerUpdate = ReplicatedStorage:WaitForChild("StageTimerUpdate")

local player = Players.LocalPlayer

local DRIFT = 0.15 -- seconds a looped track may stray from the run time before it is re-synced
local BEATS_PER_BAR = 4
local MAX_LATE = 0.12 -- a beat tick later than this after its time is skipped, not played in a burst

local runStart: number? = nil -- server time the current run started
local music: Sound? = nil
local baseVolume = 1
local lastBeat = -1

local function muted(): boolean
	return player:GetAttribute("MusicMuted") == true
end

local function stopMusic()
	if music then
		music:Stop()
		music.Volume = baseVolume
		music = nil
	end
	runStart = nil
	lastBeat = -1
end

local function startMusic(stageKey: string, start: number)
	local stage = StageConfig.ByKey[stageKey]
	local folder = stage and StageConfig.FindStageFolder(stage)
	local sound = folder and folder:FindFirstChild("Music")
	if not (sound and sound:IsA("Sound")) then
		stopMusic()
		return
	end
	if music ~= sound then
		stopMusic()
		music = sound
		baseVolume = sound:GetAttribute("BaseVolume") or sound.Volume
	end
	runStart = start
	lastBeat = -1
end

StageTimerUpdate.OnClientEvent:Connect(function(elapsed: number, stageKey: string?)
	if type(elapsed) == "number" and elapsed >= 0 and stageKey then
		startMusic(stageKey, workspace:GetServerTimeNow() - elapsed)
	else
		stopMusic()
	end
end)

RunService.Heartbeat:Connect(function()
	local sound, start = music, runStart
	if not (sound and start) then
		return
	end
	local runTime = workspace:GetServerTimeNow() - start
	if runTime < 0 then
		return
	end
	local silent = muted()
	if sound:GetAttribute("Metronome") == true then
		local beat = 60 / (sound:GetAttribute("BPM") or 120)
		local index = math.floor(runTime / beat)
		if index ~= lastBeat then
			lastBeat = index
			if not silent and runTime - index * beat <= MAX_LATE then
				local accent = index % BEATS_PER_BAR == 0
				sound.Volume = if accent then baseVolume else baseVolume * 0.6
				sound.PlaybackSpeed = if accent then 1.5 else 1
				sound.TimePosition = 0
				sound:Play()
			end
		end
		return
	end
	sound.Looped = true
	sound.Volume = if silent then 0 else baseVolume
	if not sound.IsPlaying then
		if sound.IsLoaded and sound.TimeLength > 0 then
			sound.TimePosition = runTime % sound.TimeLength
			sound:Play()
		end
		return
	end
	local length = sound.TimeLength
	if length > 0 then
		local expected = runTime % length
		local diff = math.abs(sound.TimePosition - expected)
		diff = math.min(diff, length - diff)
		if diff > DRIFT then
			sound.TimePosition = expected
		end
	end
end)
