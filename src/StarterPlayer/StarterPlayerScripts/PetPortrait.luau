-- PetPortrait: small 3D pictures of pets for the GUI (Pets panel, garden pen panel, food stand). A portrait is a
-- ViewportFrame named "Portrait" with a clone of ReplicatedStorage.PetModels[kind] dressed by PetLook.Apply, seen from the
-- front (the model's front is -Z, its LookVector), slightly from the side and above.
--   Make(kind, level, uid)   a new portrait, or nil when the model is missing
--   Cache()                  a function (pet) -> portrait that keeps one portrait per uid and rebuilds it only when the
--                            kind or level changes; use one cache per place a pet can be shown at the same time
--   Holder(props, portrait)  a dark rounded frame holding a portrait (props: Position, Size, BackgroundColor3, ...)
--   Release(container)       unparents the cached portraits inside `container`, call it before destroying the container
-- Particle effects of the higher tiers do not render in a ViewportFrame; the glow parts and accessories do.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetLook = require(ReplicatedStorage:WaitForChild("PetLook"))

local petModels = ReplicatedStorage:WaitForChild("PetModels", 10)

local FOV = 40

local PetPortrait = {}

function PetPortrait.Make(kind: string, level: number, uid: string?): ViewportFrame?
	local template = petModels and petModels:FindFirstChild(kind)
	if not template then
		return nil
	end
	local model = template:Clone()
	if not PetLook.Apply(model, kind, level, uid) then
		model:Destroy()
		return nil
	end
	local frame = Instance.new("ViewportFrame")
	frame.Name = "Portrait"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, 1)
	frame.Ambient = Color3.fromRGB(170, 170, 170)
	frame.LightColor = Color3.new(1, 1, 1)
	frame.LightDirection = Vector3.new(-1, -1.5, -1)
	model.Parent = frame
	local box, size = model:GetBoundingBox()
	local root = model.PrimaryPart :: BasePart
	local view = (root.CFrame.LookVector + root.CFrame.RightVector * 0.45 + Vector3.new(0, 0.35, 0)).Unit
	local distance = (size.Magnitude / 2) / math.tan(math.rad(FOV / 2)) * 1.05
	local camera = Instance.new("Camera")
	camera.FieldOfView = FOV
	camera.CFrame = CFrame.lookAt(box.Position + view * distance, box.Position)
	camera.Parent = frame
	frame.CurrentCamera = camera
	return frame
end

function PetPortrait.Cache(): (pet: { uid: string, kind: string, level: number }) -> ViewportFrame?
	local cache = {} -- [uid] = { key = "kind:level", frame = ViewportFrame? }
	return function(pet)
		local key = pet.kind .. ":" .. pet.level
		local entry = cache[pet.uid]
		if not entry or entry.key ~= key then
			if entry and entry.frame then
				entry.frame:Destroy()
			end
			entry = { key = key, frame = PetPortrait.Make(pet.kind, pet.level, pet.uid) }
			cache[pet.uid] = entry
		end
		return entry.frame
	end
end

function PetPortrait.Holder(props, portrait: ViewportFrame?): Frame
	local holder = Instance.new("Frame")
	holder.Name = "PortraitHolder"
	holder.BorderSizePixel = 0
	for key, value in props do
		(holder :: any)[key] = value
	end
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = holder
	if portrait then
		portrait.Size = UDim2.fromScale(1, 1)
		portrait.Parent = holder
	end
	return holder
end

function PetPortrait.Release(container: Instance)
	for _, descendant in container:GetDescendants() do
		if descendant.Name == "Portrait" and descendant:IsA("ViewportFrame") then
			descendant.Parent = nil
		end
	end
end

return PetPortrait
