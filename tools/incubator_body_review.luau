-- Client-only Studio concept study; execute with the MCP Client context.
-- No profiles, remotes, scripts or live plot instances are changed. Remove IncubatorBodyReview afterwards.
assert(game:GetService("RunService"):IsStudio(), "Studio review only")
assert(game:GetService("RunService"):IsClient(), "Run in Client")
local EggLook = require(game.ReplicatedStorage:WaitForChild("EggLook"))
local previous = workspace:FindFirstChild("IncubatorBodyReview")
if previous then previous:Destroy() end
local folder = Instance.new("Folder")
folder.Name = "IncubatorBodyReview"
folder.Parent = workspace

local brown = Color3.fromRGB(155, 105, 60)
local pad = Color3.fromRGB(218, 184, 111)
local cream = Color3.fromRGB(236, 228, 208)
local steel = Color3.fromRGB(100, 133, 147)
local dark = Color3.fromRGB(50, 66, 72)
local warm = Color3.fromRGB(255, 183, 63)
local green = Color3.fromRGB(108, 209, 110)

local function build(name: string, x: number, body)
	local model = Instance.new("Model")
	model.Name = name
	local origin = CFrame.new(x, 1000, 0)
	local function add(label: string, size: Vector3, at: Vector3, color: Color3, variant: string?)
		local p = Instance.new("Part")
		p.Name = label
		p.Size = size
		p.CFrame = origin * CFrame.new(at)
		p.Color = color
		p.Material = Enum.Material.Plastic
		p.MaterialVariant = variant or "StudsSmall"
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end
	local function light(label: string, size: Vector3, at: Vector3, color: Color3)
		local p = add(label, size, at, color, "")
		p.Material = Enum.Material.Neon
		return p
	end
	local function controls(at: Vector3)
		add("Thermostat", Vector3.new(1.6, 0.65, 0.12), at, dark)
		light("Temperature", Vector3.new(0.75, 0.18, 0.04), at + Vector3.new(-0.2, 0.08, -0.09), warm)
		light("Status", Vector3.new(0.18, 0.18, 0.04), at + Vector3.new(0.5, 0.08, -0.09), green)
	end
	add("Base", Vector3.new(6, 1.2, 6), Vector3.new(0, 0.85, 0), brown, "Studs")
	add("Pad", Vector3.new(4.4, 0.4, 4.4), Vector3.new(0, 1.65, 0), pad)
	body(add, light, controls)
	EggLook.Make("Basic", origin * CFrame.new(0, 1.85, 0)).Parent = model
	model.Parent = folder
	return model
end

build("HeatedCradle", -8, function(add, light, controls)
	for _, x in { -2.55, 2.55 } do
		add("CradleRim", Vector3.new(0.4, 0.55, 5.2), Vector3.new(x, 1.7, 0), cream)
	end
	for _, z in { -2.55, 2.55 } do
		add("CradleRim", Vector3.new(4.7, 0.55, 0.4), Vector3.new(0, 1.7, z), cream)
	end
	add("HeaterPost", Vector3.new(0.6, 5.1, 0.6), Vector3.new(0, 4, 2.3), steel)
	add("HeaterArm", Vector3.new(0.65, 0.4, 2.1), Vector3.new(0, 6.5, 1.5), steel)
	add("HeaterCap", Vector3.new(3.1, 0.5, 1.6), Vector3.new(0, 6.45, 0.6), cream)
	light("HeatElement", Vector3.new(2.4, 0.12, 1.1), Vector3.new(0, 6.14, 0.6), warm)
	controls(Vector3.new(0, 0.9, -2.85))
end)

build("GlassCabinet", 0, function(add, light, controls)
	for _, x in { -2.5, 2.5 } do
		for _, z in { -2.5, 2.5 } do
			add("CornerPost", Vector3.new(0.4, 4.7, 0.4), Vector3.new(x, 3.8, z), cream)
		end
	end
	for _, x in { -2.5, 2.5 } do
		add("TopRail", Vector3.new(0.4, 0.4, 4.6), Vector3.new(x, 6.15, 0), steel)
	end
	for _, z in { -2.5, 2.5 } do
		add("TopRail", Vector3.new(5.4, 0.4, 0.4), Vector3.new(0, 6.15, z), steel)
	end
	local function glass(label, size, at)
		local pane = add(label, size, at, Color3.fromRGB(198, 228, 231), "")
		pane.Material = Enum.Material.Glass
		pane.Transparency = 0.82
		pane.Reflectance = 0
	end
	for _, x in { -2.5, 2.5 } do
		glass("SideGlass", Vector3.new(0.1, 4.25, 4.6), Vector3.new(x, 3.8, 0))
	end
	for _, z in { -2.5, 2.5 } do
		glass("DoorGlass", Vector3.new(4.6, 4.25, 0.1), Vector3.new(0, 3.8, z))
	end
	add("DoorHandle", Vector3.new(0.22, 1.1, 0.22), Vector3.new(1.8, 3.4, -2.7), steel)
	light("RearHeater", Vector3.new(3.7, 0.22, 0.2), Vector3.new(0, 5.6, 2.25), warm)
	controls(Vector3.new(0, 0.9, -2.85))
end)

build("OpenHatchPod", 8, function(add, light, controls)
	for _, x in { -2.2, 2.2 } do
		for tier = 1, 4 do
			add("SteppedCheek", Vector3.new(0.7, 0.55, 4.3 - tier * 0.6),
				Vector3.new(x, 1.7 + tier * 0.55, 0.3 + tier * 0.18), if tier % 2 == 0 then cream else steel)
		end
	end
	add("RearHeaterCase", Vector3.new(3.5, 1.5, 0.5), Vector3.new(0, 4.45, 2.2), cream)
	light("RearHeater", Vector3.new(2.7, 0.25, 0.16), Vector3.new(0, 4.65, 1.87), warm)
	add("ControlPod", Vector3.new(0.8, 1.9, 1.3), Vector3.new(2.25, 2.45, -1.45), cream)
	light("PodStatus", Vector3.new(0.35, 0.18, 0.08), Vector3.new(2.25, 2.9, -2.15), green)
	controls(Vector3.new(-0.2, 0.9, -2.85))
end)

local counts = {}
for _, model in folder:GetChildren() do
	local count = 0
	for _, p in model:GetDescendants() do if p:IsA("BasePart") then count += 1 end end
	counts[model.Name] = count
end
return counts
