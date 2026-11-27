-- FieldPetIdle (PL1, PL2, PL3a; docs/ROADMAP.md → PL): drives the idle life (PetRoutine: breathe, look, hop, sit, shuffle, nap,
-- blink) and the owner reactions (greet, cheer) of the full-detail field pets PlotView draws. Client only, cosmetic, not in step between clients. A field pet's rest
-- frame is the spot PlotView stood it on; the routine's pose is applied with PivotTo, as PetFollow moves followers.
-- The label moves onto a still anchor part beside the model, so it never bobs (the 💤 hangs on the anchor too). The orbiting
-- motes and the emitters' distance LOD run through PetLook.UpdateFx (as for followers).
-- LOD: only pets within ANIM_DISTANCE of the camera move (beyond it they snap to rest, eyes open); past NEAR_DISTANCE at FAR_RATE
-- Hz. Attach(model, uid, level, centre, ownerId) after the model is parented into its piece; a destroyed piece drops the pet
-- (Parent nil).
-- Greet (PL3a): the plot owner's character within GREET_IN studs (flat) of a moving pet; once per approach (re-armed beyond
-- GREET_OUT) and GREET_GAP apart, remembered per owner + uid so a rebuilt piece does not greet again. Cheer: FieldHand's tap on
-- the own pet (this client only).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetLook = require(ReplicatedStorage:WaitForChild("PetLook"))
local PetRoutine = require(script.Parent:WaitForChild("PetRoutine"))

local FieldPetIdle = {}

local ANIM_DISTANCE = 90 -- studs from the camera within which field pets move
local ANIM_HYSTERESIS = 5
local NEAR_DISTANCE = 50 -- ... every frame within this, FAR_RATE updates per second beyond it
local FAR_RATE = 15
local LOD_HYSTERESIS = 5 -- emitters come back this much inside PetLook.LodDistance (as PetFollow)
local GREET_IN, GREET_OUT = 8, 14 -- studs (flat) from the rest spot: the owner greeted within, re-armed beyond
local GREET_HEIGHT = 12 -- studs: an owner further above or below is not near
local GREET_GAP = 30 -- seconds at least between two greets of one pet
local CHEER_GAP = 2 -- seconds at least between two cheers of one pet

type Pet = {
	model: Model,
	rest: CFrame,
	anchor: BasePart?,
	fx: any,
	routine: any,
	animating: boolean,
	far: boolean,
	frameAt: number,
	hold: boolean?, -- Studio checks (Hold): still at rest, eyes forced
	ownerId: number?,
	memory: Memory,
}
type Memory = { armed: boolean, greetedAt: number, cheeredAt: number }

local pets: { Pet } = {}
local memories: { [string]: Memory } = {} -- [ownerId .. ":" .. uid] (a pet's greets outlive its rebuilt piece)
local connection: RBXScriptConnection? = nil

local function step()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local eye = camera.CFrame.Position
	local now = os.clock()
	local owners: { [number]: Vector3 | false } = {} -- this frame's owner positions
	local function ownerAt(userId: number): Vector3?
		local cached = owners[userId]
		if cached == nil then
			local owner = Players:GetPlayerByUserId(userId)
			local root = owner and owner.Character and owner.Character:FindFirstChild("HumanoidRootPart")
			cached = if root and root:IsA("BasePart") then root.Position else false
			owners[userId] = cached
		end
		return cached or nil
	end
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
		local routine = pet.routine
		if pet.hold ~= nil then
			routine:Stop()
			model:PivotTo(pet.rest)
			routine:SetEyes(pet.hold)
			continue
		end
		local distance = (pet.rest.Position - eye).Magnitude
		local animate = distance < ANIM_DISTANCE + (if pet.animating then ANIM_HYSTERESIS else 0)
		local far = distance > PetLook.LodDistance - (if pet.far then LOD_HYSTERESIS else 0)
		if not animate then
			if pet.animating then
				pet.animating = false
				routine:Stop()
				routine:SetEyes(false)
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
			routine:Start(now)
		end
		local ownerPosition = pet.ownerId and ownerAt(pet.ownerId)
		if ownerPosition then
			local memory = pet.memory
			local offset = ownerPosition - pet.rest.Position
			local flat = Vector3.new(offset.X, 0, offset.Z).Magnitude
			if flat > GREET_OUT or math.abs(offset.Y) > GREET_HEIGHT then
				memory.armed = true
			elseif flat < GREET_IN and memory.armed and now - memory.greetedAt >= GREET_GAP then
				memory.armed = false
				memory.greetedAt = now
				routine:React(now, "greet", pet.rest:PointToObjectSpace(ownerPosition))
			end
		end
		if distance > NEAR_DISTANCE then
			if now < pet.frameAt then
				continue
			end
			pet.frameAt = now + 1 / FAR_RATE
		end
		local pose, shut = routine:Pose(now)
		model:PivotTo(pet.rest * pose)
		routine:SetEyes(routine:EyesShut(now, shut, distance <= PetRoutine.BlinkDistance))
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
-- beside it); `centre` is the world position of its square's middle; `ownerId` the plot owner's UserId (greets; nil: none).
function FieldPetIdle.Attach(model: Model, uid: string, level: number, centre: Vector3, ownerId: number?)
	local root = model.PrimaryPart
	if not root or not model.Parent then
		return
	end
	local rest = model:GetPivot()
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
	local pet: Pet = {
		model = model,
		rest = rest,
		anchor = anchor,
		fx = PetLook.CollectFx(model),
		routine = PetRoutine.new(model, uid, level, { toCentre = rest:PointToObjectSpace(centre), zzz = anchor }),
		animating = false,
		far = false,
		frameAt = 0,
		hold = nil,
		ownerId = ownerId,
		memory = (function()
			local key = tostring(ownerId) .. ":" .. uid
			local memory = memories[key]
			if not memory then
				memory = { armed = true, greetedAt = -math.huge, cheeredAt = -math.huge }
				memories[key] = memory
			end
			return memory
		end)(),
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

-- PL3a: a tap on the own pet `model` (FieldHand): it hops towards the camera under a ❤️. Returns whether it cheered.
function FieldPetIdle.Cheer(model: Model): boolean
	local camera = workspace.CurrentCamera
	local now = os.clock()
	for _, pet in pets do
		if pet.model == model then
			if not camera or not pet.animating or pet.hold ~= nil or now - pet.memory.cheeredAt < CHEER_GAP then
				return false
			end
			pet.memory.cheeredAt = now
			pet.routine:React(now, "cheer", pet.rest:PointToObjectSpace(camera.CFrame.Position))
			return true
		end
	end
	return false
end

-- Studio checks: holds `model` still at rest with its eyes shut (true) or open (false); nil lets it move again
function FieldPetIdle.Hold(model: Model, closed: boolean?)
	for _, pet in pets do
		if pet.model == model then
			pet.hold = closed
			if closed == nil then
				pet.animating = false -- restarts the routine on the next frame
			end
			return true
		end
	end
	return false
end

return FieldPetIdle
