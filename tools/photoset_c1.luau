-- Photo set C1 (docs/THUMBNAILS.md §4 C): a max-level pet pulling a ripe Golden Carrot out of a field square.
-- Run through the Studio MCP `execute_luau` in Edit mode (paste the file as `code`). Apply the Lighting preset first
-- (tools/photoset_lighting.luau, PRESET "C1"): the set reads the sun direction from it.
--   "build"  (re)builds Workspace.PhotoSet_C1, sets the camera on it (Scriptable) and returns the camera position / look-at
--            (for screen_capture drafts; tools/thumb_art.ps1 grab takes the final from the camera as it is)
--   "stash"  moves it to ServerStorage.PhotoSet.C1 (nothing shows in play) and resets the camera FOV
--   "shoot"  moves the stashed set back into Workspace and sets its camera again
-- Real pieces only: PetLook.Apply on a PetModels clone (no extra scaling), GoldenCarrotPlant at growth 1 with a size factor
-- inside CropConfig.SizeBounds(), and the real plot drawn by PlotView (barn, hatchery, field with ripe crops from CROPS). The
-- pose is free (composition). PLOT_SLOT = 0 builds the bare island-edge field of draft D instead (docs/THUMBNAILS.md §9).
-- Iterating: store this file once in ServerStorage.PhotoSet.Builder_C1 (a StringValue: Argon ignores it), then run
-- `return loadstring(game.ServerStorage.PhotoSet.Builder_C1.Value)({ PET_YAW = 60, ... })`; the table overrides the defaults.
-- While a set is in Workspace the Studio GUI is hidden (StarterGui.ShowDevelopmentGui); "stash" shows it again.
local P = ... or {}
local MODE: string = P.MODE or "build"
-- Bunny 4 (Wings at Lv 19; no crown: the user, 2026-11-13). Earlier: Cat 33 (Crown + Scarf), Dog 32 (Crown + Wings).
-- Crown-free Lv 20 uids: Bunny / Cat / Fox 4 Scarf + Wings, Panda 2 Scarf + Wings, Dog 2 FlameTail + Wings.
local KIND, UID = P.KIND or "Bunny", P.UID or "4"
-- Lv 19: the last level before look tier 4 (PetConfig.Tiers), whose halo the user did not want on the thumbnail (2026-11-14);
-- one accessory instead of two, scale 1.57 instead of 1.6. Panda 2 (Scarf at Lv 19) works with PET_YAW 20, DOLLY 1.15,
-- CARROT_TILT -55, GRIP 2.6 (its square head needs the stalks gripped higher, or they cross its face).
local LEVEL = P.LEVEL or 19
local CARROT_SEED = P.CARROT_SEED or 1
local CARROT_SIZE: number? = P.CARROT_SIZE or 1.6 -- a size factor; "max" = the upper bound of CropConfig.SizeBounds()
local PET_X, PET_Z = P.PET_X or 1.8, P.PET_Z or 0.6 -- set space (camera at -Z); the carrot lands at about -1.5
local PET_YAW, PET_PITCH = P.PET_YAW or 70, P.PET_PITCH or 14 -- yaw turns the face toward the carrot, pitch leans back
local CARROT_TILT = P.CARROT_TILT or -50 -- degrees the carrot leans (negative: its top toward the pet, its root out ahead)
local CARROT_SPIN = P.CARROT_SPIN or 250 -- degrees the carrot turns about its own axis (fans the fronds below the eyes)
local GLINT = P.GLINT or 14 -- particles per second of the carrot's own ripe glint (the game's 0.2 is too sparse for one frame)
local GRIP = P.GRIP or 1.8 -- studs above the root's shoulder (times the carrot's dimension) where the mouth holds the stalks
local FOV = P.FOV or 48
local CAMERA = P.CAMERA or Vector3.new(-7, 2.9, -8) -- set space
local LOOK = P.LOOK or Vector3.new(-0.6, 0.1, 0) -- set-space offset added to the look-at point (between mouth and shoulder)
-- The final is the viewport's middle 16:9 band (tools/thumb_art.ps1 grab), narrower than the viewport: the camera backs away
-- from the look-at point by DOLLY, looks LIFT studs higher (the halo fits) and SHIFT studs to the pet's left (the pet moves
-- right, clear of the logo). Build sets the camera (Scriptable) and stores it on the set; "shoot" sets it again.
local DOLLY = P.DOLLY or 1.4
local LIFT = P.LIFT or 0.7
local SHIFT = P.SHIFT or 1.2
-- degrees to turn every plant model of a name about the centre of its visible parts (some keep hidden parts far away):
-- the eggplant is flat and showed its edge from this camera (the user, 2026-11-13); at 90° its leaves face the camera.
local TURN: { [string]: number } = P.TURN or { EggplantPlant = 90 }
local RADIUS = P.RADIUS or 195 -- studs from the island's centre
local OUTWARD: any = P.OUTWARD or Vector3.new(1, 0, -0.3) -- direction from the island's centre to the set, the camera looks along it ("sun": the sun behind the camera)
-- RADIUS / OUTWARD place the bare field (PLOT_SLOT = 0); with a plot the frame sits on SQUARE, the camera outside the field
local PLOT_SLOT = P.PLOT_SLOT or 1 -- GardenConfig slot PlotView draws (1: the island's east side)
local SQUARE = P.SQUARE or 32 -- field square the carrot comes out of (left empty in CROPS: the hole); the pet stands in it too
-- one CropConfig letter per square 1..36 (rows 6, 6, 8, 8, 8 from the barn outward), "." = empty soil, "#" = locked; all ripe.
-- Tall crops (corn b, tomato k, cucumber l) at the back, round low ones beside the hole; no pineapple (its gold competes
-- with the carrot) and no giant melon in the front row (a green block that filled a corner).
local CROPS = P.CROPS or "bkblkb" .. "kbclbk" .. "obkcdbpk" .. "ocmopdnm" .. "hnc.hpaq"

local RS = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Lighting = game:GetService("Lighting")
local V = Vector3.new

local function photoSet(): Folder
	local folder = ServerStorage:FindFirstChild("PhotoSet")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "PhotoSet"
		folder.Parent = ServerStorage
	end
	return folder
end

if MODE == "stash" then
	local set = assert(workspace:FindFirstChild("PhotoSet_C1"), "nothing to stash")
	local old = photoSet():FindFirstChild("C1")
	if old then
		old:Destroy()
	end
	set.Name = "C1"
	set.Parent = photoSet()
	workspace.CurrentCamera.FieldOfView = 70
	workspace.CurrentCamera.CameraType = Enum.CameraType.Fixed
	game:GetService("StarterGui").ShowDevelopmentGui = true
	return "stashed"
elseif MODE == "shoot" then
	local set = assert(photoSet():FindFirstChild("C1"), "no stashed C1")
	set.Name = "PhotoSet_C1"
	set.Parent = workspace
	local camera = workspace.CurrentCamera
	camera.FieldOfView = FOV
	local camPos, look = set:GetAttribute("CameraPosition"), set:GetAttribute("CameraLook")
	if camPos and look then
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.lookAt(camPos, look)
	end
	game:GetService("StarterGui").ShowDevelopmentGui = false
	return "in Workspace"
end
assert(MODE == "build", "unknown MODE " .. MODE)

-- fresh module copies (Edit-mode require caches across calls), held outside the DataModel so Argon never sees them
local lib = Instance.new("Folder")
for _, name in { "Num", "PetConfig", "PetLook", "PlantKit", "GoldenCarrotPlant" } do
	RS[name]:Clone().Parent = lib
end
game:GetService("StarterPlayer").StarterPlayerScripts.PlotView:Clone().Parent = lib
lib.PetLook.Source = lib.PetLook.Source:gsub('ReplicatedStorage:WaitForChild%("PetConfig"%)', 'script.Parent:WaitForChild("PetConfig")')
local PetLook = require(lib.PetLook)
local CropConfig = require(RS.CropConfig) -- TimeFormat needs Locale: not cloned (SizeBounds is plain constants)
local Carrot = require(lib.GoldenCarrotPlant)
local Kit = require(lib.PlantKit)

local old = workspace:FindFirstChild("PhotoSet_C1")
if old then
	old:Destroy()
end
local set = Instance.new("Model")
set.Name = "PhotoSet_C1"

-- set frame O: origin on the soil top, -Z toward the camera
local O: CFrame
if PLOT_SLOT > 0 then
	-- the real plot: PlotView draws base, barn, hatchery and the field; the camera stands outside the field, looking back at
	-- the barn (the plot faces the island's centre, its field lies behind it)
	local PlotView = require(lib.PlotView)
	local GardenConfig = require(RS.GardenConfig)
	local cells = {}
	for n = 1, CropConfig.MaxSquares do
		local letter = string.sub(CROPS, n, n)
		cells[n] = if letter == "" or letter == "." then ".0" elseif letter == "#" then "#0" else letter .. "3"
	end
	cells[SQUARE] = ".0"
	local view = PlotView.new(PLOT_SLOT, set)
	view:SetState({ name = "", incCount = 3, eggs = {}, ownerId = 1, field = { crops = table.concat(cells), pets = {} } })
	view:SetDetail("full")
	local started = os.clock()
	while view:Step(os.clock() + 0.01) and os.clock() - started < 60 do
		task.wait()
	end
	for _, gui in set:GetDescendants() do
		if gui:IsA("BillboardGui") then -- floating labels (incubators, timers) are HUD, not scene
			gui:Destroy()
		end
	end
	for _, model in set:GetDescendants() do
		local degrees = model:IsA("Model") and TURN[model.Name]
		if degrees then
			local lo, hi = V(math.huge, math.huge, math.huge), V(-math.huge, -math.huge, -math.huge)
			for _, p in model:GetDescendants() do
				if p:IsA("BasePart") and p.Transparency < 1 then
					lo, hi = lo:Min(p.Position), hi:Max(p.Position)
				end
			end
			local axis = CFrame.new((lo.X + hi.X) / 2, lo.Y, (lo.Z + hi.Z) / 2)
			local turn = axis * CFrame.Angles(0, math.rad(degrees), 0) * axis:Inverse()
			for _, p in model:GetDescendants() do
				if p:IsA("BasePart") then
					p.CFrame = turn * p.CFrame
				end
			end
		end
	end
	local square = view:SquareCFrame(SQUARE)
	local back = GardenConfig.PlotCFrame(PLOT_SLOT).LookVector
	local out = -V(back.X, 0, back.Z).Unit
	O = CFrame.lookAt(square.Position, square.Position + out)
else
	local island = workspace.Garden.Island
	local top = island.Position.Y + island.Size.X / 2
	local sun = Lighting:GetSunDirection()
	local inward = if OUTWARD == "sun" then V(sun.X, 0, sun.Z).Unit else -V(OUTWARD.X, 0, OUTWARD.Z).Unit
	local origin = V(island.Position.X, top + 0.4, island.Position.Z) - inward * RADIUS
	O = CFrame.lookAt(origin, origin + inward) -- LookVector (-Z) toward the island's centre = toward the camera
end

local function part(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color, p.Material = name, size, cf, color, material
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = set
	return p
end

-- bare field (no plot): a row plate of overgrown grass, three soil squares (PlotView: pitch 5.5, soil 5.1 x 0.4)
if PLOT_SLOT <= 0 then
	local PITCH = 5.5
	part("Row", V(PITCH * 5, 0.3, PITCH * 2), O * CFrame.new(0, -0.35, PITCH / 2), Color3.fromRGB(78, 120, 52), Enum.Material.Grass)
	for i = -1, 1 do
		part("Soil" .. i, V(PITCH - 0.4, 0.4, PITCH - 0.4), O * CFrame.new(i * PITCH, -0.2, 0), Color3.fromRGB(105, 70, 45), Enum.Material.Ground)
	end
end

-- pet: dressed for its level, turned toward the carrot, leaning back, standing on the soil
local pet = RS.PetModels[KIND]:Clone()
assert(PetLook.Apply(pet, KIND, LEVEL, UID), "Apply failed")
pet.Parent = set
pet:PivotTo(O * CFrame.new(PET_X, 3, PET_Z) * CFrame.Angles(0, math.rad(PET_YAW), 0) * CFrame.Angles(math.rad(PET_PITCH), 0, 0))
local box, size = pet:GetBoundingBox()
pet:PivotTo(pet:GetPivot() + V(0, (O.Position.Y) - (box.Position.Y - size.Y / 2), 0))
local fx = PetLook.CollectFx(pet)
if fx then
	PetLook.UpdateFx(fx, 0, false, false)
end
local mouthPart = pet:FindFirstChild("Mouth", true) or pet:FindFirstChild("Chin", true) or pet:FindFirstChild("Snout", true)
local mouth = assert(mouthPart, "no mouth part").Position

-- carrot: ripe, at a real size (CARROT_SIZE), lifted and leaned so the mouth holds its stalks
local _, upper = CropConfig.SizeBounds()
local factor = if CARROT_SIZE == "max" then upper else CARROT_SIZE :: number
assert(factor <= upper + 1e-6, "size factor above CropConfig.SizeBounds()")
local soilCF = O * CFrame.new(0, 0, 0)
local plant = Carrot.new(set, soilCF, CARROT_SEED, factor)
plant:SetGrowth(1)
local ds = Kit.dimension(factor)
local shoulder = plant.rig.parts[6]
local grip = soilCF:PointToObjectSpace(shoulder.Position + V(0, shoulder.Size.Y / 2 + GRIP * ds, 0))
local toPet = (V(mouth.X, 0, mouth.Z) - V(soilCF.Position.X, 0, soilCF.Position.Z)).Unit
local axis = V(0, 1, 0):Cross(toPet).Unit
local lean = CFrame.fromAxisAngle(axis, math.rad(-CARROT_TILT))
local final = CFrame.new(mouth) * lean * (soilCF - soilCF.Position) * CFrame.Angles(0, math.rad(CARROT_SPIN), 0) * CFrame.new(-grip)
plant.model:PivotTo(final * soilCF:Inverse() * plant.model:GetPivot())
if GLINT then
	for _, emitter in plant.model:GetDescendants() do
		if emitter:IsA("ParticleEmitter") then
			emitter.Rate = GLINT
		end
	end
end
local tip = plant.rig.parts[1].Position
local buried = O.Position.Y - tip.Y

set.Parent = workspace
local camera = workspace.CurrentCamera
camera.FieldOfView = FOV
game:GetService("StarterGui").ShowDevelopmentGui = false
local look = (mouth + shoulder.Position) / 2 + O:VectorToWorldSpace(LOOK)
local offset = O * CAMERA - look
local right = (-offset.Unit):Cross(V(0, 1, 0)).Unit
look -= right * SHIFT
local camPos = look + offset * DOLLY
look += V(0, LIFT, 0)
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.lookAt(camPos, look)
set:SetAttribute("CameraPosition", camPos)
set:SetAttribute("CameraLook", look)
return string.format("size factor %.2f (bounds upper %.2f), dimension %.2f; tip %.2f below soil; pet height %.1f\ncamera {%.2f, %.2f, %.2f} look {%.2f, %.2f, %.2f}",
	factor, upper, ds, buried, size.Y, camPos.X, camPos.Y, camPos.Z, look.X, look.Y, look.Z)
