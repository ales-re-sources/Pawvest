-- PetRoutine (PL1, PL2, PL4; docs/ROADMAP.md → PL): the idle life of one pet model, shared by the field pets (FieldPetIdle)
-- and the followers (PetFollow). Client only, cosmetic, not in step between clients. A pet is a PetLook model of anchored parts
-- without a rig, so every pose is a CFrame in the pet's own rest frame (its pivot; the pet faces −Z) that the caller multiplies
-- onto the spot it stands on and applies with PivotTo.
-- A small state machine seeded by the uid: breathe (always), look, hop, sit, shuffle (field pets only: along its square's edges
-- towards the square's middle and back, a sniff at the far end), nap (lies low under a floating 💤, eyes shut). Higher look tiers
-- wait less and hop more. Reactions (PL3a, React): greet / cheer turn to a target and hop under a rising ❤️.
-- Eyes (PL2): a shut eye hides the open-eye parts (LocalTransparencyModifier, this client) and shows a "‿" line of three thin
-- parts in front of it, light on a dark patch or coat, dark otherwise. Which `Eye = true` parts hide: the names in HIDE_PREFIXES
-- plus Eye<n> (eye discs, irises, rims, pupils, shines); brows, patches, lids, lashes, the Owl's facial disc and the Phoenix's
-- flicks stay. A `Blink` attribute (true / false) on a part overrides (docs/PET_GROWTH.md → Attributes). Callers that fade the
-- whole pet through LocalTransparencyModifier (PetFollow) pass their fade to SetEyes, so a shut eye stays hidden at any fade.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetLook = require(ReplicatedStorage:WaitForChild("PetLook"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))

local PetRoutine = {}
PetRoutine.__index = PetRoutine

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
local ZZZ_DISTANCE = 90 -- studs: the 💤's MaxDistance (and the ❤️'s)
local REACT_HOLD = 0.6 -- seconds a reaction (PL3a) keeps facing its target after the hops
local REACT_BLEND = 0.25 -- seconds a reaction blends from the pose it interrupted
local GREET_HOPS, CHEER_HOPS = 2, 3
local CHEER_LIFT = 1.3 -- a cheer's hops are this much higher (still capped at HOP_MAX)
local HEART_TIME = 1.6 -- seconds the ❤️ takes to rise and fade

local HIDE_PREFIXES = { "Pupil", "EyeShine", "EyeInner", "EyeGreen", "EyeRim", "EyeRing" }
local BLINK_TIME = 0.12 -- seconds an eye stays shut in a blink
local BLINK_EVERY = { 2.5, 6 } -- seconds between blinks
local DOUBLE_BLINK = 0.2 -- chance that a blink is followed by a second one
PetRoutine.BlinkDistance = 45 -- studs from the camera within which pets blink (the eyes are tiny beyond)
local LINE_DARK = Color3.fromRGB(42, 31, 26)
local LINE_LIGHT = Color3.fromRGB(230, 220, 210)
local DARK_BEHIND = 0.35 -- luminance below which the closed-eye line is light

export type Action = {
	name: string,
	duration: number,
	pose: (t: number) -> CFrame,
	closed: ((t: number) -> boolean)?,
	heart: boolean?, -- a ❤️ floats up at its start (reactions)
	from: CFrame?, -- the interrupted pose it blends from over REACT_BLEND
}
type Eyes = { hide: { BasePart }, lines: { BasePart } }

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
local function yaw(pet, angle: number): CFrame
	return CFrame.new(pet.cx, 0, pet.cz) * CFrame.Angles(0, angle, 0) * CFrame.new(-pet.cx, 0, -pet.cz)
end

local function pitch(pet, angle: number, z: number): CFrame
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

local function look(pet): Action
	local rng = pet.rng
	local angle = math.rad(rng:NextNumber(25, 60)) * (if rng:NextNumber() < 0.5 then -1 else 1)
	local ease, hold = 0.5, rng:NextNumber(1, 2.5)
	return { name = "look", duration = ease * 2 + hold, pose = function(t)
		local w = if t < ease then smooth(t / ease) elseif t < ease + hold then 1 else 1 - smooth((t - ease - hold) / ease)
		return yaw(pet, angle * w)
	end }
end

local HOP_EACH = HOP_CROUCH + HOP_TIME + HOP_GAP

-- The pose `u` seconds into one hop (crouch, flight, gap) of `height` studs
local function hopPose(pet, u: number, height: number): CFrame
	if u < HOP_CROUCH then
		return CFrame.new(0, -pet.height * 0.04 * math.sin(math.pi * u / HOP_CROUCH), 0)
	end
	u -= HOP_CROUCH
	if u < HOP_TIME then
		local k = u / HOP_TIME
		-- nose up while rising, down while falling, around the box centre's bottom
		return CFrame.new(0, 4 * height * k * (1 - k), 0) * pitch(pet, math.rad(6) * (1 - 2 * k), pet.cz)
	end
	return CFrame.identity
end

local function hop(pet): Action
	local count = pet.rng:NextInteger(1, 3)
	local height = math.min(pet.height * HOP_HEIGHT, HOP_MAX)
	return { name = "hop", duration = HOP_EACH * count, pose = function(t)
		return hopPose(pet, t % HOP_EACH, height)
	end }
end

-- PL3a: a turn to `angle` (towards the owner or the camera), `count` hops of `height` studs, a short hold, a turn back
local function react(pet, name: string, angle: number, count: number, height: number): Action
	local turn = TURN_TIME * (0.6 + math.abs(angle) / math.pi)
	local t1 = turn
	local t2 = t1 + HOP_EACH * count
	local t3 = t2 + REACT_HOLD
	local t4 = t3 + turn
	return { name = name, duration = t4, heart = true, pose = function(t)
		if t < t1 then
			return yaw(pet, turnBetween(0, angle, t / t1))
		elseif t < t2 then
			return yaw(pet, angle) * hopPose(pet, (t - t1) % HOP_EACH, height)
		elseif t < t3 then
			return yaw(pet, angle)
		end
		return yaw(pet, turnBetween(angle, 0, (t - t3) / (t4 - t3)))
	end }
end

local function sit(pet): Action
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

local function shuffle(pet): Action
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

local function nap(pet): Action
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

-- Finds both eyes of a dressed model and builds their closed-eye lines (hidden) in a Folder "ClosedEyes". Sides by the sign of
-- X in the root's frame; an eye's centre and size are its biggest hiding part, the line sits just in front of its frontmost
-- hiding part.
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
			line.Massless = true
			line.CastShadow = false
			line.Parent = folder
			table.insert(lines, line)
		end
	end
	folder.Parent = model
	return { hide = hide, lines = lines }
end

-- Routine -----------------------------------------------------------------------------------------------------------------

-- A routine for a dressed model (PetLook.Apply done). Its rest frame is the model's pivot; the geometry comes from the bounding
-- box now (any pose of the whole model gives the same numbers). options: toCentre = rest-frame vector to the square's middle
-- (enables the shuffle; field pets), zzz = the instance the 💤 hangs on (default: the model's PrimaryPart).
function PetRoutine.new(model: Model, uid: string?, level: number, options: { toCentre: Vector3?, zzz: Instance? }?)
	local root = model.PrimaryPart :: BasePart
	local pivot = model:GetPivot()
	local boxCFrame, boxSize = model:GetBoundingBox()
	local box = pivot:ToObjectSpace(boxCFrame)
	local half = boxSize / 2
	local seed = hash(uid or model.Name)
	local toCentre = options and options.toCentre
	local self = setmetatable({
		model = model,
		rng = Random.new(seed),
		tier = PetLook.Tier(level),
		height = boxSize.Y,
		bottom = box.Position.Y - half.Y, -- rest-frame Y of the model's underside
		front = box.Position.Z - half.Z, -- rest-frame Z of its front face (−Z side) and back face
		back = box.Position.Z + half.Z,
		cx = box.Position.X, -- rest-frame X / Z of the bounding box centre (the yaw axis)
		cz = box.Position.Z,
		toCentre = if toCentre then Vector3.new(toCentre.X, 0, toCentre.Z) else nil,
		zzzAt = (options and options.zzz) or root,
		action = nil :: Action?,
		started = 0,
		nextAt = 0,
		lastNap = -math.huge,
		breathPhase = (seed % 1000) / 1000 * 2 * math.pi,
		zzz = nil :: BillboardGui?,
		heart = nil :: BillboardGui?,
		last = CFrame.identity, -- the last action pose (without the breath): where a reaction blends from
		queued = nil :: { name: string, target: Vector3 }?, -- a reaction waiting for a shuffle to walk back
		eyes = if root then buildEyes(model, root) else nil,
		closed = false,
		fade = 0,
		blinkAt = 0,
		blinkUntil = 0,
	}, PetRoutine)
	return self
end

function PetRoutine:waitTime(): number
	return self.rng:NextNumber(WAIT_MIN, WAIT_MAX) * (1 - 0.1 * self.tier)
end

function PetRoutine:showZzz(on: boolean)
	if on and not self.zzz and self.zzzAt then
		local gui = Instance.new("BillboardGui")
		gui.Name = "Zzz"
		gui.Adornee = self.zzzAt
		gui.Size = UDim2.new(1.4, 0, 1.4, 0)
		gui.LightInfluence = 0
		gui.MaxDistance = ZZZ_DISTANCE
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.TextScaled = true
		text.TextTransparency = 1
		text.AutoLocalize = false
		Locale.SetText(text, "💤")
		text.Parent = gui
		gui.Parent = self.zzzAt
		self.zzz = gui
	elseif not on and self.zzz then
		self.zzz:Destroy()
		self.zzz = nil
	end
end

-- The ❤️ of a reaction (PL3a): `k` = 0..1 of its rise; nil removes it
function PetRoutine:showHeart(k: number?)
	if k and k < 1 and not self.heart and self.zzzAt then
		local gui = Instance.new("BillboardGui")
		gui.Name = "Heart"
		gui.Adornee = self.zzzAt
		gui.Size = UDim2.new(1.2, 0, 1.2, 0)
		gui.LightInfluence = 0
		gui.MaxDistance = ZZZ_DISTANCE
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.TextScaled = true
		text.AutoLocalize = false
		Locale.SetText(text, "❤️")
		text.Parent = gui
		gui.Parent = self.zzzAt
		self.heart = gui
	end
	local gui = self.heart
	if not gui then
		return
	end
	if not k or k >= 1 then
		gui:Destroy()
		self.heart = nil
		return
	end
	gui.StudsOffset = Vector3.new(0, self.bottom + self.height + 0.2 + smooth(k) * 1.8, 0)
	local label = gui:FindFirstChildOfClass("TextLabel")
	if label then
		label.TextTransparency = math.max(0, k * 2 - 1)
	end
end

-- Starts the routine (the pet just came to rest): a first quiet wait before its first action.
function PetRoutine:Start(now: number)
	self.action = nil
	self.queued = nil
	self.last = CFrame.identity
	self.nextAt = now + self:waitTime()
end

-- Ends the current action at once (the pet leaves its rest: out of range, its owner moves); the 💤 and the ❤️ go. The eyes stay
-- as they are until the caller's next SetEyes.
function PetRoutine:Stop()
	self.action = nil
	self.queued = nil
	self.last = CFrame.identity
	self:showZzz(false)
	self:showHeart(nil)
end

function PetRoutine:startReaction(now: number, name: string, target: Vector3)
	local flat = Vector3.new(target.X - self.cx, 0, target.Z - self.cz)
	local angle = if flat.Magnitude > 0.1 then facing(flat) else 0
	local height = math.min(self.height * HOP_HEIGHT, HOP_MAX)
	local action = if name == "cheer"
		then react(self, name, angle, CHEER_HOPS, math.min(height * CHEER_LIFT, HOP_MAX))
		else react(self, name, angle, GREET_HOPS, height)
	if self.action and self.action.name == "nap" then
		self.lastNap = now -- woken: the next nap waits its full gap
	end
	action.from = self.last
	self:showZzz(false)
	self:showHeart(nil)
	self.action = action
	self.started = now
	self.queued = nil
end

-- PL3a: a reaction, "greet" (the owner came near) or "cheer" (a tap on the pet), towards `target` (a rest-frame point: the owner,
-- the camera). It interrupts the current action (a nap wakes), except a shuffle, which first walks back.
function PetRoutine:React(now: number, name: string, target: Vector3)
	if self.action and self.action.name == "shuffle" then
		self.queued = { name = name, target = target }
		return
	end
	self:startReaction(now, name, target)
end

function PetRoutine:pick(now: number, allowNap: boolean): Action
	local weights = table.clone(WEIGHTS)
	weights.hop += HOP_PER_TIER * self.tier
	if not self.toCentre then
		weights.shuffle = 0
	end
	if not allowNap or now - self.lastNap < NAP_GAP then
		weights.nap = 0
	end
	local total = 0
	for _, weight in weights do
		total += weight
	end
	local roll = self.rng:NextNumber() * total
	for name, weight in weights do
		if weight > 0 then
			roll -= weight
			if roll <= 0 then
				return BUILDERS[name](self)
			end
		end
	end
	return look(self)
end

-- The pose at `now` in the rest frame (multiply it onto the rest spot), and whether the action keeps the eyes shut.
-- `allowNap` false keeps the next action from being a nap (a running nap goes on).
function PetRoutine:Pose(now: number, allowNap: boolean?): (CFrame, boolean)
	local action = self.action
	if not action and now >= self.nextAt then
		action = self:pick(now, allowNap ~= false)
		self.action = action
		self.started = now
		if action.name == "nap" then
			self:showZzz(true)
		end
	end
	local pose = CFrame.identity
	local napping, shut = false, false
	if action then
		local t = now - self.started
		if t >= action.duration then
			if action.name == "nap" then
				self.lastNap = now
			end
			self:showZzz(false)
			self:showHeart(nil)
			self.action = nil
			self.last = CFrame.identity
			self.nextAt = now + self:waitTime()
			local queued = self.queued
			if queued then
				-- a reaction that waited for the shuffle to walk back starts now
				self:startReaction(now, queued.name, queued.target)
				action, t = self.action, 0
			end
		end
		if self.action then
			pose = action.pose(t)
			if action.from and t < REACT_BLEND then
				pose = action.from:Lerp(pose, smooth(t / REACT_BLEND))
			end
			self.last = pose
			napping = action.name == "nap"
			shut = action.closed ~= nil and action.closed(t)
			if action.heart then
				self:showHeart(t / HEART_TIME)
			end
		end
	end
	local period = if napping then BREATH_PERIOD * 1.6 else BREATH_PERIOD
	local depth = if napping then 1.8 else 1
	local breath = math.sin(now * 2 * math.pi / period + self.breathPhase)
	return pose
		* CFrame.new(0, (breath + 1) * 0.5 * BREATH_RISE * self.height * depth, 0)
		* pitch(self, breath * BREATH_PITCH * depth, self.cz), shut
end

-- Whether the eyes are shut at `now`: by the action (`shut`, a nap) or a blink; `near` = within PetRoutine.BlinkDistance of
-- the camera (blinks are only started there).
function PetRoutine:EyesShut(now: number, shut: boolean, near: boolean): boolean
	if shut then
		return true
	end
	if now >= self.blinkAt then
		if near then
			self.blinkUntil = now + BLINK_TIME
		end
		local double = self.rng:NextNumber() < DOUBLE_BLINK
		self.blinkAt = now + (if double then BLINK_TIME + 0.16 else self.rng:NextNumber(BLINK_EVERY[1], BLINK_EVERY[2]))
	end
	return now < self.blinkUntil
end

-- Shows the eyes shut or open. `fade` is the LocalTransparencyModifier the caller gives the whole pet (0 for field pets): an
-- open eye's parts get it back, a shut eye's stay hidden; the lines fade with the pet through the caller's own part list.
function PetRoutine:SetEyes(closed: boolean, fade: number?)
	local eyes = self.eyes
	fade = fade or 0
	if not eyes or (closed == self.closed and fade == self.fade) then
		return
	end
	local linesChanged = closed ~= self.closed
	self.closed = closed
	self.fade = fade
	for _, part in eyes.hide do
		part.LocalTransparencyModifier = if closed then 1 else fade
	end
	if linesChanged then
		for _, line in eyes.lines do
			line.Transparency = if closed then 0 else 1
		end
	end
end

return PetRoutine
