-- PetLook: how a pet looks, as a pure function of (kind, level, uid) applied to a clone of ReplicatedStorage.PetModels
-- (docs/PET_GROWTH.md). Shared, so the followers (PetFollow, client) and the garden pens (GardenService, server) are drawn by
-- the same code and always match. Nothing is stored or replicated: every viewer derives the look from the same numbers.
-- P1e1: size by level, label, Epic / Legendary glow, formation slots. `uid` is reserved for the individuality seed (P1e4).
-- P1e2: label text with tier badge (LabelText), level-up moment (LevelUp, client only).
-- Every part is forced Anchored / CanCollide / CanTouch / CanQuery off / Massless here, so a replaced model can never
-- push the owner, fire touch parts or block raycasts and the camera.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))

local PetLook = {}

local SLOT_GAP = 0.6 -- studs between neighbouring pets of a formation
local BASE_BACK = 3.5 -- studs behind the owner of the pets' roots (never closer than the pets' reach allows)
local OWNER_CLEARANCE = 1.5 -- owner half depth + a gap, kept between the owner and the front of the nearest pet
local SIDE_MIN = 2 -- lateral offset of a single pet (at least this, wider models move further out)
local OWNER_HALF_WIDTH = 0.9

export type Label = {
	text: string,
	richText: boolean?,
	size: UDim2,
	maxDistance: number,
	gap: number, -- studs between the top of the scaled model and the label
}

-- size / center: the bounding box of the scaled model in the PrimaryPart's space; lift: how far to raise the root so the
-- model's underside stays where it is at Lv 1 (models grow around their root).
export type Metrics = { scale: number, size: Vector3, center: Vector3, lift: number }

-- Size factor of a level: 1.0 at Lv 1 growing linearly to PetConfig.MaxScale at Lv 20.
function PetLook.Scale(level: number): number
	return PetConfig.ScaleOf(level)
end

-- Look tier of a level (0 below Lv 5, then 1 / 2 / 3 / 4 at Lv 5 / 10 / 15 / 20).
function PetLook.Tier(level: number): number
	return PetConfig.TierOf(level)
end

local function addGlow(root: BasePart, rarity: PetConfig.Rarity)
	if rarity.order < PetConfig.RarityById.Epic.order then
		return
	end
	local legendary = rarity.order >= PetConfig.RarityById.Legendary.order
	local light = Instance.new("PointLight")
	light.Color = rarity.color
	light.Brightness = if legendary then 2.5 else 1.5
	light.Range = if legendary then 10 else 8
	light.Parent = root
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Color = ColorSequence.new(rarity.color)
	sparkles.LightEmission = 1
	sparkles.Size = NumberSequence.new(0.25, 0)
	sparkles.Transparency = NumberSequence.new(0.2, 1)
	sparkles.Lifetime = NumberRange.new(0.6, 1)
	sparkles.Rate = if legendary then 10 else 5
	sparkles.Speed = NumberRange.new(0.5, 1.5)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Parent = root
end

local function addLabel(model: Model, root: BasePart, rarity: PetConfig.Rarity, top: number, label: Label)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Adornee = root
	gui.Size = label.size
	gui.StudsOffset = Vector3.new(0, top + label.gap, 0)
	gui.MaxDistance = label.maxDistance
	gui.LightInfluence = 0
	gui.Parent = model
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.RichText = label.richText == true
	text.Text = label.text
	text.TextColor3 = rarity.color
	text.TextStrokeTransparency = 0.3
	text.Parent = gui
end

-- Label text of a pet: "Cat Lv 12 ★★", one star per look tier (none below Lv 5), so the tier shows on the label too.
function PetLook.LabelText(kind: string, level: number): string
	level = PetConfig.ClampLevel(level)
	local tier = PetLook.Tier(level)
	return kind .. " Lv " .. level .. if tier > 0 then " " .. string.rep("★", tier) else ""
end

-- Dresses a fresh, unparented clone of PetModels[kind] for `level`: forces the safety flags, scales it by level around
-- its root, adds the label (if given) above the scaled model and the Epic / Legendary glow. Call once per clone.
-- Returns the metrics the formation needs, or nil if the model has no PrimaryPart.
function PetLook.Apply(model: Model, kind: string, level: number, uid: string?, label: Label?): Metrics?
	local root = model.PrimaryPart
	local rarity = PetConfig.RarityOf(kind)
	if not (root and rarity) then
		return nil
	end
	level = PetConfig.ClampLevel(level)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Massless = true
		end
	end

	local scale = PetLook.Scale(level)
	model:ScaleTo(scale)
	local boxCFrame, boxSize = model:GetBoundingBox()
	local center = root.CFrame:PointToObjectSpace(boxCFrame.Position)
	local underside = boxSize.Y / 2 - center.Y -- reach below the root

	if label then
		addLabel(model, root, rarity, center.Y + boxSize.Y / 2, label)
	end
	addGlow(root, rarity)
	return { scale = scale, size = boxSize, center = center, lift = underside * (1 - 1 / scale) }
end

-- Level-up moment (P1e2), client only (every viewer plays it for the pet that levelled). A staged ~2 s show, timed in seconds
-- from the start (constants below):
--   0 - 1.4   the old look spins faster and faster (SPIN_TURNS turns, then SETTLE_TURNS more while braking) and rises RISE studs;
--             swirling sparks get denser
--   0.75-1.85 a bright neon ball with a light surrounds the pet (the flash, ~1 s, peak at ~1.3)
--   0.9 - 1.3 under the flash the old look cross-fades into the new one (new model fades in, the old one - the "ghost" - out);
--             the label switches to the new level at LABEL_AT
--   0         optional sound (ReplicatedStorage.PetLevelUpSound, SOUND_AT)
--   1.2       burst of sparks, expanding ring on the ground, floating "Level N!"
--   1.4 - 2.0 the pet drops back to its place
-- The owner of the pet's position (PetFollow every frame, PetPenLevelUp for pens) calls `moment:Pose(base)` with the pose the
-- pet would have anyway and uses the returned CFrame (spin + rise on top) and fade (LocalTransparencyModifier of the new model,
-- 1 -> 0; combine with max). Pose also drives the ghost, flash and sparks, so it must be called every frame until `moment.done`.
-- Everything extra lives in one Folder "LevelUpFx" in the workspace, removed by Debris after FX_LIFETIME, by `Cancel()` or when
-- the model is destroyed. Every part made here obeys the Apply invariants (anchored, no collide / touch / query, massless).
-- The optional Studio-only ReplicatedStorage.PetLevelUpSound is cloned locally onto the root (like ChallengeCoinSound).
local SPIN_TURNS = 4 -- whole turns while accelerating (the yaw ends on a multiple of 2 pi, so the pet lands facing forward)
local SPIN_TIME = 1.1 -- seconds of accelerating spin and rise
local SETTLE_TURNS = 1 -- whole extra turns while braking to a stop
local SETTLE_TIME = SETTLE_TURNS * SPIN_TIME / SPIN_TURNS
local DROP_TIME = 0.6 -- seconds back down after the spin
local POSE_TIME = SPIN_TIME + SETTLE_TIME + DROP_TIME
local RISE = 3 -- studs above its place at the top
local SWAP_FROM, SWAP_TO = 0.9, 1.3 -- cross-fade old look -> new look
local LABEL_AT = 1.1
local FLASH_FROM, FLASH_TO = 0.75, 1.85
local BURST_AT = 1.2 -- burst, ring and text
local SOUND_AT = 0 -- start of the sound (PetLevelUpSound is ~1.5 s, so it ends around the flash and burst; shift it here if it feels off)
local TEXT_TIME = 1.8
local RING_TIME = 0.9
local BURST_COUNT = 40
local FX_LIFETIME = BURST_AT + TEXT_TIME + 0.4

export type Moment = { done: boolean, Pose: (Moment, CFrame) -> (CFrame, number), Cancel: (Moment) -> () }

local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

-- Yaw (radians) and height of the pet `t` seconds into the moment.
local function spinAndRise(t: number): (number, number)
	local full = 2 * math.pi
	if t <= SPIN_TIME then
		return full * SPIN_TURNS * (t / SPIN_TIME) ^ 2, RISE * smooth(t / SPIN_TIME)
	end
	local s = t - SPIN_TIME
	if s <= SETTLE_TIME then
		local omega = 2 * full * SPIN_TURNS / SPIN_TIME -- angular speed at the end of the acceleration
		return full * SPIN_TURNS + omega * (s - s * s / (2 * SETTLE_TIME)), RISE
	end
	return full * (SPIN_TURNS + SETTLE_TURNS), RISE * (1 - smooth((s - SETTLE_TIME) / DROP_TIME))
end

local function fxPart(name: string, shape: Enum.PartType, color: Color3, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Transparency = 1
	part.CastShadow = false
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.Size = Vector3.one * 0.1
	part.Parent = parent
	return part
end

-- Starts the moment for `model` (the dressed, parented model of the new level). `ghost` = the model of the old level (taken
-- over and destroyed by the moment) with its current LocalTransparencyModifier `ghostFade`; nil for pens (no old model).
-- Returns the moment, or nil if the model cannot play it (no PrimaryPart / not in the workspace; the ghost is destroyed then).
function PetLook.LevelUp(model: Model, kind: string, level: number, ghost: Model?, ghostFade: number?): Moment?
	local root = model.PrimaryPart
	local rarity = PetConfig.RarityOf(kind)
	if not (root and rarity and model:IsDescendantOf(workspace)) then
		if ghost then
			ghost:Destroy()
		end
		return nil
	end
	level = PetConfig.ClampLevel(level)
	local boxCFrame, boxSize = model:GetBoundingBox()
	local center = root.CFrame:PointToObjectSpace(boxCFrame.Position)
	local top = center.Y + boxSize.Y / 2
	local color = rarity.color:Lerp(Color3.new(1, 1, 1), 0.35)
	local flashColor = rarity.color:Lerp(Color3.new(1, 1, 1), 0.6)

	local folder = Instance.new("Folder")
	folder.Name = "LevelUpFx"
	folder.Parent = workspace
	Debris:AddItem(folder, FX_LIFETIME)

	-- the label (new level) stays hidden until LABEL_AT, the ghost keeps showing the old one
	local label = model:FindFirstChild("Label")
	if label and not label:IsA("BillboardGui") then
		label = nil
	end
	if label then
		label.Enabled = false
	end
	local ghostParts, ghostLabel = {}, nil
	if ghost then
		ghost.Parent = folder
		ghostLabel = ghost:FindFirstChild("Label")
		for _, part in ghost:GetDescendants() do
			if part:IsA("BasePart") then
				table.insert(ghostParts, part)
			end
		end
	end
	local ghostStart = ghostFade or 0

	-- swirling sparks around the pet while it spins up
	local attachment = Instance.new("Attachment")
	attachment.Name = "LevelUpAttachment"
	attachment.Position = center
	attachment.Parent = root
	Debris:AddItem(attachment, FX_LIFETIME)
	local swirl = Instance.new("ParticleEmitter")
	swirl.Rate = 0
	swirl.Color = ColorSequence.new(color)
	swirl.LightEmission = 1
	swirl.Size = NumberSequence.new(0.35, 0)
	swirl.Transparency = NumberSequence.new(0.1, 1)
	swirl.Lifetime = NumberRange.new(0.4, 0.8)
	swirl.Speed = NumberRange.new(2, 5)
	swirl.SpreadAngle = Vector2.new(180, 180)
	swirl.Parent = attachment
	local burst = Instance.new("ParticleEmitter")
	burst.Rate = 0
	burst.Color = ColorSequence.new(color)
	burst.LightEmission = 1
	burst.Size = NumberSequence.new(0.5, 0)
	burst.Transparency = NumberSequence.new(0, 1)
	burst.Lifetime = NumberRange.new(0.6, 1.1)
	burst.Speed = NumberRange.new(9, 16)
	burst.Drag = 3
	burst.Acceleration = Vector3.new(0, 6, 0)
	burst.SpreadAngle = Vector2.new(180, 180)
	burst.Parent = attachment

	-- the flash: a neon ball with a light around the pet
	local flashSize = boxSize.Magnitude * 1.2 + 1
	local flash = fxPart("LevelUpFlash", Enum.PartType.Ball, flashColor, folder)
	local light = Instance.new("PointLight")
	light.Color = flashColor
	light.Range = 18
	light.Brightness = 0
	light.Parent = flash

	local moment = { done = false } :: any
	local start = os.clock()
	local celebrated, labelShown, sounded = false, false, false

	local function celebrate(base: CFrame)
		celebrated = true
		burst:Emit(BURST_COUNT)
		-- ring on the ground under the pet's place (a flat neon cylinder, axis up)
		local reach = math.max(boxSize.X, boxSize.Z)
		local ring = fxPart("LevelUpRing", Enum.PartType.Cylinder, rarity.color, folder)
		ring.Transparency = 0.2
		ring.Size = Vector3.new(0.15, reach * 0.6, reach * 0.6)
		ring.CFrame = base * CFrame.new(0, center.Y - boxSize.Y / 2 + 0.1, 0) * CFrame.Angles(0, 0, math.pi / 2)
		local ringInfo = TweenInfo.new(RING_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(ring, ringInfo, { Size = Vector3.new(0.15, reach * 2.6 + 2, reach * 2.6 + 2), Transparency = 1 }):Play()

		-- floating "Level N!" above the label
		local gui = Instance.new("BillboardGui")
		gui.Name = "LevelUpText"
		gui.Adornee = root
		gui.Size = UDim2.new(6, 0, 1.2, 0)
		gui.StudsOffset = Vector3.new(0, top + 1.8, 0)
		gui.MaxDistance = 100
		gui.LightInfluence = 0
		gui.AlwaysOnTop = true
		gui.Parent = folder
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.GothamBlack
		text.TextScaled = true
		text.Text = "Level " .. level .. "!"
		text.TextColor3 = color
		text.TextStrokeTransparency = 0.2
		text.Parent = gui
		local riseInfo = TweenInfo.new(TEXT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(gui, riseInfo, { StudsOffset = Vector3.new(0, top + 1.8 + 2.5, 0) }):Play()
		local fadeInfo = TweenInfo.new(TEXT_TIME * 0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, TEXT_TIME * 0.5)
		TweenService:Create(text, fadeInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end

	local function playSound()
		sounded = true
		local template = ReplicatedStorage:FindFirstChild("PetLevelUpSound")
		if template and template:IsA("Sound") then
			local sound = template:Clone()
			sound.Parent = root
			sound:Play()
			Debris:AddItem(sound, 5)
		end
	end

	local function showLabel()
		labelShown = true
		if label then
			label.Enabled = true
		end
		if ghostLabel then
			ghostLabel:Destroy()
			ghostLabel = nil
		end
	end

	local function finish()
		moment.done = true
		swirl.Enabled = false
		if not labelShown then
			showLabel()
		end
		if ghost then
			ghost:Destroy()
			ghost = nil
		end
		flash:Destroy()
	end

	function moment:Pose(base: CFrame): (CFrame, number)
		if moment.done then
			return base, 0
		end
		local t = os.clock() - start
		if t >= POSE_TIME then
			if not celebrated then
				celebrate(base)
			end
			finish()
			return base, 0
		end
		if not sounded and t >= SOUND_AT then
			playSound()
		end
		local yaw, rise = spinAndRise(t)
		local pose = CFrame.new(0, rise, 0) * base * CFrame.Angles(0, yaw, 0)

		-- old look -> new look
		local swap = smooth((t - SWAP_FROM) / (SWAP_TO - SWAP_FROM))
		if ghost then
			if swap >= 1 then
				ghost:Destroy()
				ghost = nil
			else
				ghost:PivotTo(pose)
				for _, part in ghostParts do
					part.LocalTransparencyModifier = ghostStart + (1 - ghostStart) * swap
				end
			end
		end
		if not labelShown and t >= LABEL_AT then
			showLabel()
		end

		-- sparks get denser while spinning up, stop when the spin is over
		swirl.Rate = if t < SPIN_TIME + SETTLE_TIME then 8 + 70 * (t / SPIN_TIME) ^ 2 else 0

		-- the flash: grows and glows to its peak, then fades
		local f = (t - FLASH_FROM) / (FLASH_TO - FLASH_FROM)
		if f > 0 and f < 1 then
			local bell = math.sin(math.pi * f)
			flash.Size = Vector3.one * flashSize * (0.5 + 0.7 * f)
			flash.CFrame = CFrame.new(pose:PointToWorldSpace(center))
			flash.Transparency = 1 - 0.85 * bell
			light.Brightness = 5 * bell
		else
			flash.Transparency = 1
			light.Brightness = 0
		end

		if not celebrated and t >= BURST_AT then
			celebrate(base)
		end
		return pose, 1 - swap
	end

	function moment:Cancel()
		if not moment.done then
			moment.done = true
			if label then
				label.Enabled = true
			end
		end
		folder:Destroy() -- also the ghost, flash, ring and text
	end

	model.Destroying:Connect(function()
		moment:Cancel()
	end)
	return moment :: Moment
end

-- Formation offsets in the owner's anchor space (+Z = behind), one per entry of `metrics` (same order): 1 pet right-behind,
-- 2 side by side, 3 with the centre one further back. The spacing comes from the widest scaled model, so neighbours never
-- overlap; the distance behind grows with the models' length so the pets do not sink into the owner; `lift` keeps their
-- undersides at the Lv 1 height.
function PetLook.Slots(metrics: { Metrics }): { Vector3 }
	local width, back = 0, BASE_BACK
	for _, info in metrics do
		width = math.max(width, info.size.X)
		back = math.max(back, OWNER_CLEARANCE + info.size.Z / 2 - info.center.Z)
	end
	local spacing = width + SLOT_GAP
	local xs, zs
	local count = #metrics
	if count == 1 then
		xs, zs = { math.max(SIDE_MIN, width / 2 + OWNER_HALF_WIDTH) }, { back }
	elseif count == 2 then
		xs, zs = { -spacing / 2, spacing / 2 }, { back, back }
	else
		xs, zs = { -spacing, 0, spacing }, { back, back + 1, back }
	end
	local slots = {}
	for index, info in metrics do
		slots[index] = Vector3.new(xs[index], info.lift, zs[index])
	end
	return slots
end

return PetLook
