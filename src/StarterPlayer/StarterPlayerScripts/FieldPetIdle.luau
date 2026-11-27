-- FieldPetIdle (PL1, docs/ROADMAP.md → PL): idle motion of the full-detail field pets PlotView draws. Client only, cosmetic,
-- not in step between clients. A field pet is a PetLook model of anchored parts without a rig, so every pose is a CFrame of
-- the whole model in its rest frame (the spot PlotView stood it on; the pet faces −Z), applied with PivotTo as PetFollow does.
-- Per pet a small state machine seeded by its uid: breathe (always), look, hop, sit, shuffle (along its square's edges towards
-- the square's middle and back, a sniff at the far end; never onto another square), nap (lies low under a floating 💤).
-- Higher look tiers wait less and hop more. PL2: the eyes shut in a nap and blink near the camera (see Eyes below). The label moves onto a still anchor part beside the model, so it never bobs.
-- The orbiting motes and the emitters' distance LOD run through PetLook.UpdateFx (as for followers).
-- LOD: only pets within ANIM_DISTANCE of the camera move (beyond it they snap to rest); past NEAR_DISTANCE at FAR_RATE Hz.
-- Attach(model, uid, level, centre) after the model is parented into its piece; a destroyed piece drops the pet (Parent nil).

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetLook = require(ReplicatedStorage:WaitForChild("PetLook"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))

local FieldPetIdle = {}

local ANIM_DISTANCE = 90 -- studs from the camera within which field pets move
local ANIM_HYSTERESIS = 5
local NEAR_DISTANCE = 50 -- ... every frame within this, FAR_RATE updates per second beyond it
local FAR_RATE = 15
local LOD_HYSTERESIS = 5 -- emitters come back this much inside PetLook.LodDistance (as PetFollow)

local WAIT_MIN, WAIT_MAX = 1.5, 5 -- seconds of plain breathing between actions (tier shortens them)
local NAP_GAP = 90 -- seconds at least between two naps of one pet
local WEIGHTS = { look = 30, hop = 16, sit = 14, shuffle = 22, nap = 5 } -- hop gains HOP_PER_TIER per look tier
local HOP_PER_TIER = 4

local BREATH_PERIOD = 2.8 -- seconds per breath (a nap breathes slower and deeper)
local BREATH_PITCH = math.rad(0.8)
local BREATH_RISE = 0.012 -- share of the pet's height
local HOP_TIME, HOP_GAP, HOP_CROUCH = 0.34, 0.14, 0.09 -- seconds: in the air, between hops, the dip before each take-off
local HOP_HEIGHT = 0.22 -- share of the pet's height, capped at HOP_MAX studs
local HOP_MAX = 0.8
local SIT_PITCH = math.rad(14) -- nose up, around the back bottom edge
local WALK_SPEED = 2.2 -- studs per second while shuffling
local TURN_TIME = 0.3
local STEP_BOUNCE = 0.1 -- studs: the hop of each step while shuffling
local STEP_RATE = 9 -- rad/s of the step bounce
local SNIFF_PITCH = math.rad(9) -- nose down, around the front bottom edge
local SHUFFLE_SHARE = { 0.4, 0.75 } -- of the way from the rest spot towards the square's middle line, along one edge
local NAP_SINK = 0.1 -- share of the pet's height it lies lower (into the soil), capped at NAP_SINK_MAX studs
local NAP_SINK_MAX = 0.3
local NAP_PITCH = math.rad(3)

-- Eyes (PL2): a closed eye hides the open-eye parts (LocalTransparencyModifier, this client) and shows a "‿" line of three thin
-- parts in front of it. Which `Eye = true` parts hide: the names below (eye discs Eye<n>, irises, rims, pupils, shines); brows,
-- patches, lids, lashes, the Owl's facial disc and the Phoenix's flicks stay. A `Blink` attribute (true / false) on a part overrides.
local HIDE_PREFIXES = { "Pupil", "EyeShine", "EyeInner", "EyeGreen", "EyeRim", "EyeRing" }
local BLINK_TIME = 0.12 -- seconds an eye stays shut in a blink
local BLINK_EVERY = { 2.5, 6 } -- seconds between blinks
local DOUBLE_BLINK = 0.2 -- chance that a blink is followed by a second one
local BLINK_DISTANCE = 45 -- studs from the camera within which pets blink (the eyes are tiny beyond)
local LINE_DARK = Color3.fromRGB(42, 31, 26)
local LINE_LIGHT = Color3.fromRGB(230, 220, 210)
local DARK_BEHIND = 0.35 -- luminance below which the closed-eye line is light

type Pose = (t: number) -> CFrame
type Action = { name: string, duration: number, pose: Pose, closed: ((t: number) -> boolean)? }
type Eyes = { hide: { BasePart }, lines: { BasePart } }
type Pet = {
	model: Model,
	rest: CFrame,
	anchor: BasePart?,
	fx: any,
	rng: Random,
	tier: number,
	height: number,
	bottom: number, -- rest-frame Y of the model's underside
	front: number, -- rest-frame Z of its front face (−Z side) and back face
	back: number,
	cx: number, -- rest-frame X / Z of the bounding box centre (the yaw axis)
	cz: number,
	toCentre: Vector3, -- rest-frame vector to the square's middle (y = 0)
	action: Action?,
	started: number,
	nextAt: number,
	lastNap: number,
	breathPhase: number,
	zzz: BillboardGui?,
	animating: boolean,
	far: boolean,
	frameAt: number,
	eyes: Eyes?,
	closed: boolean,
	blinkAt: number,
	blinkUntil: number,
	hold: boolean?, -- Studio checks (Hold): still at rest, eyes forced
}

local pets: { Pet } = {}
local connection: RBXScriptConnection? = nil

local function smooth(u: number): number
	u = math.clamp(u, 0, 1)
	return u * u * (3 - 2 * u)
end

local function hash(text: string): number
	local h = 5381
	for i = 1, #text do
		h = (h * 33 + string.byte(text, i)) % 2147483647
	end
	return h
end

-- Rotations in the rest frame: yaw around the box centre's vertical axis, pitch around a bottom edge at depth `z`
local function yaw(pet: Pet, angle: number): CFrame
	return CFrame.new(pet.cx, 0, pet.cz) * CFrame.Angles(0, angle, 0) * CFrame.new(-pet.cx, 0, -pet.cz)
end

local function pitch(pet: Pet, angle: number, z: number): CFrame
	return CFrame.new(0, pet.bottom, z) * CFrame.Angles(angle, 0, 0) * CFrame.new(0, -pet.bottom, -z)
end

-- Facing (yaw angle) towards a rest-frame direction; the pet's front is −Z
local function facing(direction: Vector3): number
	return math.atan2(-direction.X, -direction.Z)
end

local function turnBetween(from: number, to: number, u: number): number
	local delta = (to - from + math.pi) % (2 * math.pi) - math.pi
	return from + delta * smooth(u)
end

-- Actions -----------------------------------------------------------------------------------------------------------------

local function look(pet: Pet): Action
	local rng = pet.rng
	local angle = math.rad(rng:NextNumber(25, 60)) * (if rng:NextNumber() < 0.5 then -1 else 1)
	local ease, hold = 0.5, rng:NextNumber(1, 2.5)
	return { name = "look", duration = ease * 2 + hold, pose = function(t)
		local w = if t < ease then smooth(t / ease) elseif t < ease + hold then 1 else 1 - smooth((t - ease - hold) / ease)
		return yaw(pet, angle * w)
	end }
end

local function hop(pet: Pet): Action
	local count = pet.rng:NextInteger(1, 3)
	local height = math.min(pet.height * HOP_HEIGHT, HOP_MAX)
	local each = HOP_CROUCH + HOP_TIME + HOP_GAP
	local dip = pet.height * 0.04
	return { name = "hop", duration = each * count, pose = function(t)
		local u = t % each
		if u < HOP_CROUCH then
			return CFrame.new(0, -dip * math.sin(math.pi * u / HOP_CROUCH), 0)
		end
		u -= HOP_CROUCH
		if u < HOP_TIME then
			local k = u / HOP_TIME
			-- nose up while rising, down while falling, around the box centre's bottom
			return CFrame.new(0, 4 * height * k * (1 - k), 0) * pitch(pet, math.rad(6) * (1 - 2 * k), pet.cz)
		end
		return CFrame.identity
	end }
end

local function sit(pet: Pet): Action
	local rng = pet.rng
	local ease, hold = 0.4, rng:NextNumber(2.5, 5)
	local sway = math.rad(rng:NextNumber(6, 12))
	return { name = "sit", duration = ease * 2 + hold, pose = function(t)
		local w = if t < ease then smooth(t / ease) elseif t < ease + hold then 1 else 1 - smooth((t - ease - hold) / ease)
		-- a slow look to the side while it sits
		local side = if t > ease and t < ease + hold then math.sin((t - ease) / hold * math.pi) * sway else 0
		return pitch(pet, SIT_PITCH * w, pet.back) * yaw(pet, side)
	end }
end

local function shuffle(pet: Pet): Action
	local rng = pet.rng
	-- along one edge of the square: the X or the Z part of the way to the square's middle
	local share = rng:NextNumber(SHUFFLE_SHARE[1], SHUFFLE_SHARE[2])
	local alongX = rng:NextNumber() < 0.5
	local target = if alongX then Vector3.new(pet.toCentre.X * share, 0, 0) else Vector3.new(0, 0, pet.toCentre.Z * share)
	local distance = target.Magnitude
	if distance < 0.3 then
		return look(pet)
	end
	local out, back = facing(target), facing(-target)
	local walk = distance / WALK_SPEED
	local sniff = rng:NextNumber(0.7, 1.4)
	-- phases: turn out, walk out, sniff, turn round, walk back, turn to the front
	local t1 = TURN_TIME
	local t2 = t1 + walk
	local t3 = t2 + sniff
	local t4 = t3 + TURN_TIME * 1.5
	local t5 = t4 + walk
	local t6 = t5 + TURN_TIME
	local function step(u: number): number
		return math.abs(math.sin(u * STEP_RATE)) * STEP_BOUNCE
	end
	return { name = "shuffle", duration = t6, pose = function(t)
		if t < t1 then
			return yaw(pet, turnBetween(0, out, t / t1))
		elseif t < t2 then
			local k = (t - t1) / walk
			return CFrame.new(target * smooth(k) + Vector3.new(0, step(t - t1), 0)) * yaw(pet, out)
		elseif t < t3 then
			local k = (t - t2) / sniff
			local nose = SNIFF_PITCH * math.sin(k * math.pi) * (0.8 + 0.2 * math.sin(k * 30))
			return CFrame.new(target) * yaw(pet, out) * pitch(pet, -nose, pet.front)
		elseif t < t4 then
			return CFrame.new(target) * yaw(pet, turnBetween(out, back, (t - t3) / (t4 - t3)))
		elseif t < t5 then
			local k = (t - t4) / walk
			return CFrame.new(target * (1 - smooth(k)) + Vector3.new(0, step(t - t4), 0)) * yaw(pet, back)
		end
		return yaw(pet, turnBetween(back, 0, (t - t5) / (t6 - t5)))
	end }
end

local function showZzz(pet: Pet, on: boolean)
	if on and not pet.zzz and pet.anchor then
		local gui = Instance.new("BillboardGui")
		gui.Name = "Zzz"
		gui.Adornee = pet.anchor
		gui.Size = UDim2.new(1.4, 0, 1.4, 0)
		gui.LightInfluence = 0
		gui.MaxDistance = ANIM_DISTANCE
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.TextScaled = true
		text.AutoLocalize = false
		Locale.SetText(text, "💤")
		text.Parent = gui
		gui.Parent = pet.anchor
		pet.zzz = gui
	elseif not on and pet.zzz then
		pet.zzz:Destroy()
		pet.zzz = nil
	end
end

local function nap(pet: Pet): Action
	local ease, hold = 1, pet.rng:NextNumber(12, 25)
	local sink = math.min(pet.height * NAP_SINK, NAP_SINK_MAX)
	return { name = "nap", duration = ease * 2 + hold, closed = function(t)
		-- shut while it lies down, open as it gets up
		return t > ease * 0.6 and t < ease + hold + ease * 0.4
	end, pose = function(t)
		local w = if t < ease then smooth(t / ease) elseif t < ease + hold then 1 else 1 - smooth((t - ease - hold) / ease)
		local gui = pet.zzz
		if gui then
			-- the 💤 drifts up from the head and fades, one rise per 2.4 s
			local k = (t % 2.4) / 2.4
			gui.StudsOffset = Vector3.new(0.5, pet.bottom + pet.height + 0.3 + k * 1.6, 0)
			local label = gui:FindFirstChildOfClass("TextLabel")
			if label then
				label.TextTransparency = if w < 1 then 1 else math.max(0, k * 1.4 - 0.4)
			end
		end
		return CFrame.new(0, -sink * w, 0) * pitch(pet, -NAP_PITCH * w, pet.front)
	end }
end

local BUILDERS = { look = look, hop = hop, sit = sit, shuffle = shuffle, nap = nap }

local function pick(pet: Pet, now: number): Action
	local weights = table.clone(WEIGHTS)
	weights.hop += HOP_PER_TIER * pet.tier
	if now - pet.lastNap < NAP_GAP then
		weights.nap = 0
	end
	local total = 0
	for _, weight in weights do
		total += weight
	end
	local roll = pet.rng:NextNumber() * total
	for name, weight in weights do
		roll -= weight
		if roll <= 0 then
			return BUILDERS[name](pet)
		end
	end
	return look(pet)
end

local function waitTime(pet: Pet): number
	local cut = 1 - 0.1 * pet.tier
	return pet.rng:NextNumber(WAIT_MIN, WAIT_MAX) * cut
end

local function endAction(pet: Pet, now: number)
	if pet.action and pet.action.name == "nap" then
		pet.lastNap = now
	end
	showZzz(pet, false)
	pet.action = nil
	pet.nextAt = now + waitTime(pet)
end

-- Eyes --------------------------------------------------------------------------------------------------------------------

local function hidesWhenClosed(part: BasePart): boolean
	local flag = part:GetAttribute("Blink")
	if flag ~= nil then
		return flag == true
	end
	if not part:GetAttribute("Eye") then
		return false
	end
	local name = part.Name
	if string.match(name, "^Eye%d") then
		return true
	end
	for _, prefix in HIDE_PREFIXES do
		if string.sub(name, 1, #prefix) == prefix then
			return true
		end
	end
	return false
end

local function largest(size: Vector3): number
	return math.max(size.X, size.Y, size.Z)
end

local function luminance(color: Color3): number
	return 0.2126 * color.R + 0.7152 * color.G + 0.0722 * color.B
end

-- Finds both eyes of a dressed model at rest and builds their closed-eye lines (hidden). Sides by the sign of X in the root's
-- frame; an eye's centre and size are its biggest hiding part, the line sits just in front of its frontmost hiding part.
local function buildEyes(model: Model, root: BasePart): Eyes?
	local rootCFrame = root.CFrame
	local sides = {}
	local kept = {}
	local hide = {}
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") or (part:GetAttribute("Eye") == nil and part:GetAttribute("Blink") == nil) then
			continue
		end
		local at = rootCFrame:PointToObjectSpace(part.Position)
		local side = if at.X < 0 then -1 else 1
		local size = largest(part.Size)
		if hidesWhenClosed(part) then
			table.insert(hide, part)
			local eye = sides[side] or { size = 0, centre = at, front = math.huge }
			sides[side] = eye
			if size > eye.size then
				eye.size = size
				eye.centre = at
			end
			local thin = math.min(part.Size.X, part.Size.Y, part.Size.Z)
			eye.front = math.min(eye.front, at.Z - thin / 2)
		else
			table.insert(kept, { part = part, at = at, side = side, size = size })
		end
	end
	if #hide == 0 then
		return nil
	end
	local head = model:FindFirstChild("Head") or model:FindFirstChild("Body")
	local folder = Instance.new("Folder")
	folder.Name = "ClosedEyes"
	local lines = {}
	for side, eye in sides do
		-- what the line is drawn on: the largest patch / disc around the eye (not a lash or lid over it), else the head
		local behind = if head and head:IsA("BasePart") then head.Color else Color3.new(0.8, 0.7, 0.6)
		local behindSize = 0
		for _, other in kept do
			if other.side == side and other.size >= eye.size * 0.9 and other.size > behindSize
				and Vector2.new(other.at.X - eye.centre.X, other.at.Y - eye.centre.Y).Magnitude < eye.size / 2 then
				behind = other.part.Color
				behindSize = other.size
			end
		end
		local color = if luminance(behind) < DARK_BEHIND then LINE_LIGHT else LINE_DARK
		local d = eye.size
		local thick = math.max(0.035, d * 0.1)
		local base = rootCFrame * CFrame.new(eye.centre.X, eye.centre.Y - d * 0.08, eye.front - 0.012)
		local tilt = math.rad(28)
		local pieces = {
			{ Vector3.new(d * 0.42, thick, 0.02), base },
			{ Vector3.new(d * 0.34, thick, 0.02), base * CFrame.new(-d * 0.36, d * 0.08, 0) * CFrame.Angles(0, 0, -tilt) },
			{ Vector3.new(d * 0.34, thick, 0.02), base * CFrame.new(d * 0.36, d * 0.08, 0) * CFrame.Angles(0, 0, tilt) },
		}
		for index, piece in pieces do
			local line = Instance.new("Part")
			line.Name = "Lid" .. (if side < 0 then "L" else "R") .. index
			line.Size = piece[1]
			line.CFrame = piece[2]
			line.Color = color
			line.Material = Enum.Material.SmoothPlastic
			line.Transparency = 1
			line.Anchored = true
			line.CanCollide = false
			line.CanTouch = false
			line.CanQuery = false
			line.CastShadow = false
			line.Parent = folder
			table.insert(lines, line)
		end
	end
	folder.Parent = model
	return { hide = hide, lines = lines }
end

local function setEyes(pet: Pet, closed: boolean)
	local eyes = pet.eyes
	if not eyes or closed == pet.closed then
		return
	end
	pet.closed = closed
	for _, part in eyes.hide do
		part.LocalTransparencyModifier = if closed then 1 else 0
	end
	for _, line in eyes.lines do
		line.Transparency = if closed then 0 else 1
	end
end

-- Frame -------------------------------------------------------------------------------------------------------------------

local function poseOf(pet: Pet, now: number): (CFrame, boolean)
	local action = pet.action
	if not action and now >= pet.nextAt then
		action = pick(pet, now)
		pet.action = action
		pet.started = now
		if action.name == "nap" then
			showZzz(pet, true)
		end
	end
	local pose = CFrame.identity
	local napping, shut = false, false
	if action then
		local t = now - pet.started
		if t >= action.duration then
			endAction(pet, now)
		else
			pose = action.pose(t)
			napping = action.name == "nap"
			shut = action.closed ~= nil and action.closed(t)
		end
	end
	local period = if napping then BREATH_PERIOD * 1.6 else BREATH_PERIOD
	local depth = if napping then 1.8 else 1
	local breath = math.sin(now * 2 * math.pi / period + pet.breathPhase)
	return pose
		* CFrame.new(0, (breath + 1) * 0.5 * BREATH_RISE * pet.height * depth, 0)
		* pitch(pet, breath * BREATH_PITCH * depth, pet.cz), shut
end

-- Eyes shut by the action (nap) or a blink; blinks only near the camera and never while an action keeps them shut
local function eyesClosed(pet: Pet, now: number, shut: boolean, distance: number): boolean
	if shut then
		return true
	end
	if now >= pet.blinkAt then
		if distance <= BLINK_DISTANCE then
			pet.blinkUntil = now + BLINK_TIME
		end
		local double = pet.rng:NextNumber() < DOUBLE_BLINK
		pet.blinkAt = now + (if double then BLINK_TIME + 0.16 else pet.rng:NextNumber(BLINK_EVERY[1], BLINK_EVERY[2]))
	end
	return now < pet.blinkUntil
end

local function step()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local eye = camera.CFrame.Position
	local now = os.clock()
	local index = 1
	while index <= #pets do
		local pet = pets[index]
		local model = pet.model
		if model.Parent == nil then
			-- the piece was destroyed (rebuilt, the pet left its square, the plot went away)
			if pet.anchor then
				pet.anchor:Destroy()
			end
			pets[index] = pets[#pets]
			pets[#pets] = nil
			continue
		end
		index += 1
		if not model:IsDescendantOf(workspace) then
			continue
		end
		if pet.hold ~= nil then
			pet.action = nil
			showZzz(pet, false)
			model:PivotTo(pet.rest)
			setEyes(pet, pet.hold)
			continue
		end
		local distance = (pet.rest.Position - eye).Magnitude
		local animate = distance < ANIM_DISTANCE + (if pet.animating then ANIM_HYSTERESIS else 0)
		local far = distance > PetLook.LodDistance - (if pet.far then LOD_HYSTERESIS else 0)
		if not animate then
			if pet.animating then
				pet.animating = false
				pet.action = nil
				showZzz(pet, false)
				setEyes(pet, false)
				model:PivotTo(pet.rest)
			end
			if far ~= pet.far and pet.fx then
				pet.far = far
				PetLook.UpdateFx(pet.fx, now, far, false)
			end
			continue
		end
		if not pet.animating then
			pet.animating = true
			pet.nextAt = now + waitTime(pet)
		end
		if distance > NEAR_DISTANCE then
			if now < pet.frameAt then
				continue
			end
			pet.frameAt = now + 1 / FAR_RATE
		end
		local pose, shut = poseOf(pet, now)
		model:PivotTo(pet.rest * pose)
		setEyes(pet, eyesClosed(pet, now, shut, distance))
		pet.far = far
		if pet.fx then
			PetLook.UpdateFx(pet.fx, now, far, false)
		end
	end
	if #pets == 0 and connection then
		connection:Disconnect()
		connection = nil
	end
end

-- Hands a dressed, placed field pet to the idle loop. `model` must already be parented into its piece (the label anchor goes
-- beside it); `centre` is the world position of its square's middle.
function FieldPetIdle.Attach(model: Model, uid: string, level: number, centre: Vector3)
	local root = model.PrimaryPart
	if not root or not model.Parent then
		return
	end
	local rest = model:GetPivot()
	local boxCFrame, boxSize = model:GetBoundingBox()
	local box = rest:ToObjectSpace(boxCFrame)
	-- the box is aligned with the model; its rest-frame extents along Y and Z
	local half = boxSize / 2
	local anchor: BasePart? = nil
	local label = model:FindFirstChild("Label")
	if label and label:IsA("BillboardGui") then
		local part = Instance.new("Part")
		part.Name = model.Name .. "Label"
		part.Size = Vector3.new(0.2, 0.2, 0.2)
		part.Transparency = 1
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
		part.CFrame = root.CFrame -- the label's offsets were measured from the root; the 💤 sits on the anchor too
		part.Parent = model.Parent
		label.Adornee = part
		label.Parent = part
		anchor = part
	end
	local toCentre = rest:PointToObjectSpace(centre)
	local seed = hash(uid)
	local pet: Pet = {
		model = model,
		rest = rest,
		anchor = anchor,
		fx = PetLook.CollectFx(model),
		rng = Random.new(seed),
		tier = PetLook.Tier(level),
		height = boxSize.Y,
		bottom = box.Position.Y - half.Y,
		front = box.Position.Z - half.Z,
		back = box.Position.Z + half.Z,
		cx = box.Position.X,
		cz = box.Position.Z,
		toCentre = Vector3.new(toCentre.X, 0, toCentre.Z),
		action = nil,
		started = 0,
		nextAt = 0,
		lastNap = -math.huge,
		breathPhase = (seed % 1000) / 1000 * 2 * math.pi,
		zzz = nil,
		animating = false,
		far = false,
		frameAt = 0,
		eyes = buildEyes(model, root),
		closed = false,
		blinkAt = 0,
		blinkUntil = 0,
		hold = nil,
	}
	table.insert(pets, pet)
	if not connection then
		connection = RunService.Heartbeat:Connect(step)
	end
end

-- Number of pets in the idle loop (Studio checks)
function FieldPetIdle.Count(): number
	return #pets
end

-- Studio checks: holds `model` still at rest with its eyes shut (true) or open (false); nil lets it move again
function FieldPetIdle.Hold(model: Model, closed: boolean?)
	for _, pet in pets do
		if pet.model == model then
			pet.hold = closed
			return true
		end
	end
	return false
end

return FieldPetIdle
