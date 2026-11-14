-- Photo set C2 (docs/THUMBNAILS.md §4 C): giant harvest. A ripe Giant Melon at the upper size bound, a pet sitting on top,
-- the player beside it cheering; a very low, close camera makes the melon tower. Run through the Studio MCP `execute_luau` in
-- Edit mode. Needs ServerStorage.PhotoSet.Builder_Rig (tools/photoset_rig.luau) and the Lighting preset C2
-- (tools/photoset_lighting.luau) applied first: PLOT_SLOT "sun" picks the plot from the sun direction.
--   "build"  (re)builds Workspace.PhotoSet_C2, sets the camera on it (Scriptable) and returns the camera position / look-at
--   "stash"  moves it to ServerStorage.PhotoSet.C2 (nothing shows in play) and resets the camera
--   "shoot"  moves the stashed set back into Workspace and sets its camera again
-- Real pieces only: the real plot drawn by PlotView (barn, hatchery, field with ripe crops from CROPS), GiantMelonPlant at
-- growth 1 with a size factor inside CropConfig.SizeBounds() (never past it: §4 C2), PetLook.Apply on a PetModels clone at a
-- level its rarity reaches (PetConfig.AptitudeCap), the shared player rig. Pets do not sit on crops in the game; the pose is free
-- (as C1's pull).
-- Iterating: store this file in ServerStorage.PhotoSet.Builder_C2 (a StringValue: Argon ignores it), then run
-- `return loadstring(game.ServerStorage.PhotoSet.Builder_C2.Value)({ PET_YAW = 20, ... })`; the table overrides the defaults.
-- While a set is in Workspace the Studio GUI is hidden (StarterGui.ShowDevelopmentGui); "stash" shows it again.
local P = ... or {}
local MODE: string = P.MODE or "build"
-- Cat 2 (Common: Lv 12 at most). Orange parts from the green melon; the Panda (Lv 16, uid 2) was draft A. Lv 6 (the user,
-- 2026-11-14): 3.4 studs tall instead of 4.0 at Lv 12, look tier 1, so no accessory (the Scarf comes at Lv 10). Cat uids at Lv 12: 2 / 8 Scarf, 4 / 7 Wings, 1 / 3 FlameTail, 6 Horns, 5 Crown.
local KIND, UID = P.KIND or "Cat", P.UID or "2"
local LEVEL = P.LEVEL or 6
local PLOT_SLOT: any = P.PLOT_SLOT or "sun"
local MELON_SQUARE = P.MELON_SQUARE or 32 -- outer row (29..36), left empty in CROPS
local RIG_SQUARE = P.RIG_SQUARE or 31 -- the player stands here (left empty in CROPS)
local MELON_SEED = P.MELON_SEED or 1
local MELON_SIZE: any = P.MELON_SIZE or "max" -- a size factor, or "max": the upper bound of CropConfig.SizeBounds()
local MELON_YAW = P.MELON_YAW or -47 -- seed 1: turns the fruit's long axis across the camera (its striped side, stem right)
-- set space: origin on the melon's square at the soil top, -Z outward (toward the camera), +X camera-left
local PET_SHIFT = P.PET_SHIFT or Vector3.new(0, 0, -0.5) -- from the top of the fruit; at 0 a leaf lobe crossed the Lv 6 Cat's mouth
local PET_YAW, PET_PITCH, PET_ROLL = P.PET_YAW or 0, P.PET_PITCH or 0, P.PET_ROLL or 0 -- 0: as the model faces after O
local PET_SINK = P.PET_SINK or 0.25 -- studs the pet's bottom sits into the rind's curve
local RIG_AT = P.RIG_AT or Vector3.new(0.6, 0, 5.0) -- from RIG_SQUARE's centre (set axes): a row back, so the melon looms
local RIG_YAW = P.RIG_YAW or 0 -- 0 faces the camera side
local POSE = P.POSE or "cheer"
local LOOK_NAME = P.LOOK_NAME or "classic" -- Rig.LOOKS: "classic" (Roblox's default avatar, the user's pick 2026-11-14) or "updo"
local FOV = P.FOV or 62
-- draft H (2026-11-14): half a stud above the soil, ~9 studs out; forced perspective makes the melon as tall as the player
local CAMERA = P.CAMERA or Vector3.new(-0.4, 0.55, -8.8) -- set space: low and close
local LOOK = P.LOOK or Vector3.new(0.4, 3.45, 0)
-- one CropConfig letter per square 1..36 (rows 6, 6, 8, 8, 8 from the barn outward), "." = empty soil, "#" = locked; all ripe.
-- No other giant melon (d) and no sunflower (r: draft art, drawn as a yellow block).
-- 23 (behind the player) stays empty.
local CROPS = P.CROPS or "bkkbkb" .. "kbobbk" .. "obkplbpk" .. "om.pkbnm" .. "hn..ppqa"

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
	local set = assert(workspace:FindFirstChild("PhotoSet_C2"), "nothing to stash")
	local old = photoSet():FindFirstChild("C2")
	if old then
		old:Destroy()
	end
	set.Name = "C2"
	set.Parent = photoSet()
	workspace.CurrentCamera.FieldOfView = 70
	workspace.CurrentCamera.CameraType = Enum.CameraType.Fixed
	game:GetService("StarterGui").ShowDevelopmentGui = true
	return "stashed"
elseif MODE == "shoot" then
	local set = assert(photoSet():FindFirstChild("C2"), "no stashed C2")
	set.Name = "PhotoSet_C2"
	set.Parent = workspace
	local camera = workspace.CurrentCamera
	camera.FieldOfView = set:GetAttribute("FieldOfView") or FOV
	local camPos, look = set:GetAttribute("CameraPosition"), set:GetAttribute("CameraLook")
	if camPos and look then
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.lookAt(camPos, look)
	end
	game:GetService("StarterGui").ShowDevelopmentGui = false
	return "in Workspace"
end
assert(MODE == "build", "unknown MODE " .. MODE)

local Rig = loadstring(assert(photoSet():FindFirstChild("Builder_Rig"), "store tools/photoset_rig.luau in Builder_Rig").Value)()

-- fresh module copies (Edit-mode require caches across calls), held outside the DataModel so Argon never sees them
local lib = Instance.new("Folder")
for _, name in { "Num", "PetConfig", "PetLook", "PlantKit", "GiantMelonPlant" } do
	RS[name]:Clone().Parent = lib
end
game:GetService("StarterPlayer").StarterPlayerScripts.PlotView:Clone().Parent = lib
lib.PetLook.Source = lib.PetLook.Source:gsub('ReplicatedStorage:WaitForChild%("PetConfig"%)', 'script.Parent:WaitForChild("PetConfig")')
local PetLook = require(lib.PetLook)
local PetConfig = require(lib.PetConfig)
local CropConfig = require(RS.CropConfig)
local GardenConfig = require(RS.GardenConfig)
local Melon = require(lib.GiantMelonPlant)
local PlotView = require(lib.PlotView)

local cap = PetConfig.AptitudeCap(KIND)
local level = LEVEL or cap
assert(level <= cap, string.format("%s reaches Lv %d at most (rarity cap): Lv %d is not real content", KIND, cap, level))

-- the plot: "sun" = the inner-ring slot whose outward direction (field side, where the camera stands) is closest to the sun's
local slot = PLOT_SLOT
if slot == "sun" then
	local sun = Lighting:GetSunDirection()
	sun = V(sun.X, 0, sun.Z).Unit
	local best = -math.huge
	for n = 1, GardenConfig.PlotRings[1].count do
		local look = (GardenConfig.PlotCFrame(n) :: CFrame).LookVector
		local score = (-V(look.X, 0, look.Z).Unit):Dot(sun)
		if score > best then
			best, slot = score, n
		end
	end
end

local old = workspace:FindFirstChild("PhotoSet_C2")
if old then
	old:Destroy()
end
local set = Instance.new("Model")
set.Name = "PhotoSet_C2"

local cells = {}
for n = 1, CropConfig.MaxSquares do
	local letter = string.sub(CROPS, n, n)
	cells[n] = if letter == "" or letter == "." then ".0" elseif letter == "#" then "#0" else letter .. "3"
end
cells[MELON_SQUARE], cells[RIG_SQUARE] = ".0", ".0"
local view = PlotView.new(slot, set)
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

-- set frame O: origin on the melon's square at the soil top, -Z outward (away from the barn, toward the camera)
local square = view:SquareCFrame(MELON_SQUARE)
local back = (GardenConfig.PlotCFrame(slot) :: CFrame).LookVector
local out = -V(back.X, 0, back.Z).Unit
local O = CFrame.lookAt(square.Position, square.Position + out)

-- the Giant Melon: ripe, at a real size
local _, upper = CropConfig.SizeBounds()
local factor = if MELON_SIZE == "max" then upper else MELON_SIZE :: number
assert(factor <= upper + 1e-6, "size factor above CropConfig.SizeBounds()")
local melonModel = Instance.new("Model")
melonModel.Name = "GiantMelon"
melonModel.Parent = set
local plant = Melon.new(melonModel, square * CFrame.Angles(0, math.rad(MELON_YAW), 0), MELON_SEED, factor)
plant:SetGrowth(1)
local lo, hi = V(math.huge, math.huge, math.huge), V(-math.huge, -math.huge, -math.huge)
for _, p in melonModel:GetDescendants() do
	if p:IsA("BasePart") and p.Name == "Rind" and p.Transparency < 1 then
		lo, hi = lo:Min(p.Position + p.Size / 2), hi:Max(p.Position + p.Size / 2) -- rough: the blocks are small
		lo, hi = lo:Min(p.Position - p.Size / 2), hi:Max(p.Position - p.Size / 2)
	end
end
assert(lo.X < math.huge, "no Rind parts")
local fruitTop = V((lo.X + hi.X) / 2, hi.Y, (lo.Z + hi.Z) / 2)
-- the precise top: a ray straight down onto the fruit
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { melonModel }
set.Parent = workspace
local hit = workspace:Raycast(fruitTop + V(0, 5, 0), V(0, -10, 0), params)
if hit then
	fruitTop = hit.Position
end

-- the pet: dressed for its level, sitting on the fruit's crown
local pet = RS.PetModels[KIND]:Clone()
assert(PetLook.Apply(pet, KIND, level, UID), "Apply failed")
for _, p in pet:GetDescendants() do
	if p:IsA("BasePart") then
		p.Anchored = true
	end
end
local Oflat = CFrame.lookAt(fruitTop, fruitTop + out) -- O's axes, at the fruit's top
pet:PivotTo(Oflat * CFrame.new(PET_SHIFT + V(0, 3, 0)) * CFrame.Angles(0, math.rad(PET_YAW), 0)
	* CFrame.Angles(math.rad(PET_PITCH), 0, math.rad(PET_ROLL)))
local box, size = pet:GetBoundingBox()
pet:PivotTo(pet:GetPivot() + V(0, fruitTop.Y + PET_SHIFT.Y - PET_SINK - (box.Position.Y - size.Y / 2), 0))
pet.Parent = set
local fx = PetLook.CollectFx(pet)
if fx then
	PetLook.UpdateFx(fx, 0, false, false)
end

-- the player, feet on the soil of RIG_SQUARE
local rigSquare = view:SquareCFrame(RIG_SQUARE)
local rigAt = CFrame.lookAt(rigSquare.Position, rigSquare.Position + out) * CFrame.new(RIG_AT + V(0, 3, 0))
local rig = Rig.build(assert(Rig.LOOKS[LOOK_NAME], "unknown look " .. LOOK_NAME))
Rig.pose(rig, Rig.POSES[POSE], rigAt * CFrame.Angles(0, math.rad(RIG_YAW), 0), rigSquare.Position.Y)
rig.Parent = set

local camera = workspace.CurrentCamera
camera.FieldOfView = FOV
game:GetService("StarterGui").ShowDevelopmentGui = false
local camPos, look = O * CAMERA, O * LOOK
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.lookAt(camPos, look)
set:SetAttribute("CameraPosition", camPos)
set:SetAttribute("CameraLook", look)
set:SetAttribute("FieldOfView", FOV)
local _, rigSize = rig:GetBoundingBox()
local fruitSize = hi - lo
return string.format("slot %d, %s %s Lv %d (cap %d); melon factor %.2f (upper %.2f), fruit %.1f x %.1f x %.1f, top %.1f above soil; pet %.1f tall; rig %.1f tall\ncamera {%.2f, %.2f, %.2f} look {%.2f, %.2f, %.2f}",
	slot, KIND, UID, level, cap, factor, upper, fruitSize.X, fruitSize.Y, fruitSize.Z, fruitTop.Y - O.Position.Y, size.Y,
	rigSize.Y, camPos.X, camPos.Y, camPos.Z, look.X, look.Y, look.Z)
