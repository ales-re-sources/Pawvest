-- Checkpoints on this client (H2), for the local player only:
-- - ReplicatedStorage.CheckpointReached(part, first) (the player's respawn point moved to that checkpoint, from
--   CheckpointTouchHandler) lights that checkpoint's pad and turns the previously lit one back, so only the current
--   checkpoint glows: the Core grows from a small green stud tile to a larger glowing square, its PointLight fades in and
--   the Beam (a light column) rises. `first` (first reach in this run) also plays
--   workspace.Handlers.CheckpointTouchHandler.Sound (Studio-only Sound); walking back to an earlier checkpoint is silent.
-- - ReplicatedStorage.CheckpointsReset (a new run) turns the lit pad back to "not reached".
-- The pads are server-owned anchored parts; the changes here are local, so every player sees their own progress.
-- The Studio state of Core / Beam is the "not reached" look; this script reads it once per pad and tweens to and from it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local LOOK = {
	activateTime = 1, -- seconds; the sound is ~2.4 s, so the pad settles while it still plays
	resetTime = 0.4,
	coreSize = 7, -- studs, side of the reached core (the Studio core is the small one)
	coreColor = Color3.fromRGB(110, 255, 130),
	lightBrightness = 2,
	beamHeight = 18, -- studs above the plate
	beamTransparency = 0.8,
}

local sound: Sound? = nil -- local copy under SoundService (plays non-positionally)

local function playSound()
	if not sound then
		local handlers = workspace:FindFirstChild("Handlers")
		local handler = handlers and handlers:FindFirstChild("CheckpointTouchHandler")
		local template = handler and handler:FindFirstChild("Sound")
		if not (template and template:IsA("Sound")) then
			return
		end
		sound = template:Clone()
		sound.Parent = SoundService
	end
	sound.TimePosition = 0
	sound:Play()
end

-- [core] = { core, beam, light, base = the Studio ("not reached") values, tweens = running tweens }
local pads = {}

local function padOf(part: BasePart)
	local model = part.Parent
	local core = model and model:FindFirstChild("Core")
	local beam = model and model:FindFirstChild("Beam")
	if not (core and core:IsA("BasePart") and beam and beam:IsA("BasePart")) then
		return nil
	end
	local pad = pads[core]
	if not pad then
		local light = core:FindFirstChildOfClass("PointLight")
		pad = {
			core = core,
			beam = beam,
			light = light,
			base = {
				coreSize = core.Size,
				coreColor = core.Color,
				coreMaterial = core.Material,
				coreVariant = core.MaterialVariant,
				beamCFrame = beam.CFrame, -- the beam's axis is its X (cylinder), standing upright on the plate
				beamSize = beam.Size,
				beamTransparency = beam.Transparency,
				lightBrightness = light and light.Brightness or 0,
			},
			tweens = {},
			active = false,
		}
		pads[core] = pad
	end
	return pad
end

local function play(pad, instance, info, goal)
	local tween = TweenService:Create(instance, info, goal)
	table.insert(pad.tweens, tween)
	tween:Play()
end

local function stop(pad)
	for _, tween in pad.tweens do
		tween:Cancel()
	end
	table.clear(pad.tweens)
end

-- the beam grows upwards from the plate: a cylinder of length h stands with its bottom where the Studio beam's bottom is
local function beamGoal(pad, height: number)
	local base = pad.base
	local bottom = base.beamCFrame.Position - Vector3.new(0, base.beamSize.X / 2, 0)
	return {
		Size = Vector3.new(height, base.beamSize.Y, base.beamSize.Z),
		CFrame = CFrame.new(bottom + Vector3.new(0, height / 2, 0)) * (base.beamCFrame - base.beamCFrame.Position),
	}
end

local function activate(pad)
	stop(pad)
	pad.active = true
	local base = pad.base
	local info = TweenInfo.new(LOOK.activateTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local soft = TweenInfo.new(LOOK.activateTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	pad.core.Material = Enum.Material.Neon
	pad.core.MaterialVariant = ""
	play(pad, pad.core, info, { Size = Vector3.new(LOOK.coreSize, base.coreSize.Y, LOOK.coreSize) })
	play(pad, pad.core, soft, { Color = LOOK.coreColor })
	if pad.light then
		play(pad, pad.light, soft, { Brightness = LOOK.lightBrightness })
	end
	-- start the column flat on the plate, then let it rise and fade in
	local flat = beamGoal(pad, 0.2)
	pad.beam.Size = flat.Size
	pad.beam.CFrame = flat.CFrame
	local goal = beamGoal(pad, LOOK.beamHeight)
	goal.Transparency = LOOK.beamTransparency
	play(pad, pad.beam, soft, goal)
end

local function deactivate(pad)
	stop(pad)
	pad.active = false
	local base = pad.base
	local info = TweenInfo.new(LOOK.resetTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	play(pad, pad.core, info, { Size = base.coreSize, Color = base.coreColor })
	if pad.light then
		play(pad, pad.light, info, { Brightness = base.lightBrightness })
	end
	local goal = beamGoal(pad, 0.2)
	goal.Transparency = 1
	local tween = TweenService:Create(pad.beam, info, goal)
	table.insert(pad.tweens, tween)
	tween.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed and not pad.active then
			pad.core.Material = base.coreMaterial
			pad.core.MaterialVariant = base.coreVariant
			pad.beam.Size = base.beamSize
			pad.beam.CFrame = base.beamCFrame
			pad.beam.Transparency = base.beamTransparency
		end
	end)
	tween:Play()
end

ReplicatedStorage:WaitForChild("CheckpointReached").OnClientEvent:Connect(function(part, first)
	if first ~= false then
		playSound()
	end
	local pad = typeof(part) == "Instance" and part:IsA("BasePart") and padOf(part) or nil
	for _, other in pads do
		if other.active and other ~= pad then
			deactivate(other)
		end
	end
	if pad and not pad.active then
		activate(pad)
	end
end)

ReplicatedStorage:WaitForChild("CheckpointsReset").OnClientEvent:Connect(function()
	for _, pad in pads do
		if pad.active then
			deactivate(pad)
		end
	end
end)
