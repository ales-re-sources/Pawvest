-- FieldPetIdle (PL1, PL2; docs/ROADMAP.md → PL): drives the idle life (PetRoutine: breathe, look, hop, sit, shuffle, nap,
-- blink) of the full-detail field pets PlotView draws. Client only, cosmetic, not in step between clients. A field pet's rest
-- frame is the spot PlotView stood it on; the routine's pose is applied with PivotTo, as PetFollow moves followers.
-- The label moves onto a still anchor part beside the model, so it never bobs (the 💤 hangs on the anchor too). The orbiting
-- motes and the emitters' distance LOD run through PetLook.UpdateFx (as for followers).
-- LOD: only pets within ANIM_DISTANCE of the camera move (beyond it they snap to rest, eyes open); past NEAR_DISTANCE at FAR_RATE
-- Hz. Attach(model, uid, level, centre) after the model is parented into its piece; a destroyed piece drops the pet (Parent nil).

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
}

local pets: { Pet } = {}
local connection: RBXScriptConnection? = nil

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
-- beside it); `centre` is the world position of its square's middle.
function FieldPetIdle.Attach(model: Model, uid: string, level: number, centre: Vector3)
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
			if closed == nil then
				pet.animating = false -- restarts the routine on the next frame
			end
			return true
		end
	end
	return false
end

return FieldPetIdle
