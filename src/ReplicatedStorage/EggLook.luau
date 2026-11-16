-- Portal-style cross-lapped egg, shared by plot nests and hatchery card portraits.
-- Make(eggId, baseCFrame, detail?) builds from the bottom of the shell (full 27 / mid 9 / low 5 bricks).
-- Portrait(eggId, size) uses the full recipe in a passive ViewportFrame.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))

local EggLook = {}
EggLook.Height = 3.15

local COURSE = 0.35
local WIDTHS = { 1.25, 1.95, 2.55, 2.85, 2.8, 2.5, 2.05, 1.5, 0.85 }

function EggLook.Make(eggId: string, baseCFrame: CFrame, detail: string?): Model
	local egg = PetConfig.Eggs[eggId]
	local look = egg and egg.look
	local color = if look then look.color else Color3.fromRGB(236, 228, 208)
	local model = Instance.new("Model")
	model.Name = "Egg"
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(0.1, 0.1, 0.1)
	root.CFrame = baseCFrame * CFrame.new(0, EggLook.Height / 2, 0)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.CastShadow = false
	root.Parent = model
	model.PrimaryPart = root

	local function brick(n: number, piece: number, x: number, y: number, z: number, w: number, h: number, d: number)
		local p = Instance.new("Part")
		p.Name = string.format("Course%d_%d", n, piece)
		p.Size = Vector3.new(w, h, d)
		p.CFrame = baseCFrame * CFrame.new(x, y, z)
		p.Color = color
		p.Material = Enum.Material.Plastic
		p.MaterialVariant = "StudsSmall"
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = false
		p.Parent = model
	end

	if detail == "low" then
		local bottom = 0
		for n, w in { 1.25, 2.55, 2.8, 2.05, 1.5 } do
			local h = if n == 1 then COURSE else COURSE * 2
			brick(n, 1, 0, bottom + h / 2, 0, w, h, w * 0.84)
			bottom += h
		end
	else
		for n, w in WIDTHS do
			local y, depth = (n - 0.5) * COURSE, w * 0.84
			local turn = n % 2 == 0
			local function add(piece: number, z: number, sx: number, sz: number)
				brick(n, piece, if turn then z else 0, y, if turn then 0 else z,
					if turn then sz else sx, COURSE, if turn then sx else sz)
			end
			if detail == "mid" then
				add(1, 0, w, depth)
			else
				-- Three touching rectangles clip the corners without overlapping / coplanar outer faces.
				add(1, 0, w, depth * 0.66)
				add(2, -depth * 0.415, w * 0.66, depth * 0.17)
				add(3, depth * 0.415, w * 0.66, depth * 0.17)
			end
		end
	end
	if look and look.glow and (detail == nil or detail == "full") then
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 8
		light.Brightness = 1.5
		light.Parent = root
	end
	return model
end

function EggLook.Portrait(eggId: string, size: UDim2): ViewportFrame
	local frame = Instance.new("ViewportFrame")
	frame.Name = "Picture"
	frame.AutoLocalize = false
	frame.Active = false
	frame.BackgroundTransparency = 1
	frame.Size = size
	frame.Ambient = Color3.fromRGB(180, 180, 180)
	frame.LightColor = Color3.new(1, 1, 1)
	frame.LightDirection = Vector3.new(-1, -1.5, -1)
	local model = EggLook.Make(eggId, CFrame.identity)
	model.Parent = frame
	local camera = Instance.new("Camera")
	camera.FieldOfView = 35
	local target = Vector3.new(0, EggLook.Height / 2, 0)
	camera.CFrame = CFrame.lookAt(target + Vector3.new(4.6, 2.7, 7.2), target)
	camera.Parent = frame
	frame.CurrentCamera = camera
	return frame
end

return EggLook
