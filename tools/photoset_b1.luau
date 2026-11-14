-- Photo set B1 (docs/THUMBNAILS.md §4 B): one guard pet on its field square, its reach tinted over ripe crops, one big Pumpkin
-- beside it; crow-free until drop D1. Run through the Studio MCP `execute_luau` in Edit mode (paste the file as `code`). Apply
-- the Lighting preset first (tools/photoset_lighting.luau, PRESET "B1"): PLOT_SLOT "sun" picks the plot from the sun direction.
--   "build"  (re)builds Workspace.PhotoSet_B1, sets the camera on it (Scriptable) and returns the camera position / look-at
--            (for screen_capture drafts; tools/thumb_art.ps1 grab takes the final from the camera as it is)
--   "stash"  moves it to ServerStorage.PhotoSet.B1 (nothing shows in play) and resets the camera FOV
--   "shoot"  moves the stashed set back into Workspace and sets its camera again
-- Real pieces only: the real plot drawn by PlotView (barn, hatchery, field with ripe crops from CROPS), the reach tint of
-- PlotView:ShowReach over CropConfig.Reach of the pet's level, PetLook.Apply on a PetModels clone at a level its rarity reaches
-- (PetConfig.AptitudeCap), PumpkinPlant at growth 1 with a size factor inside CropConfig.SizeBounds(). The pose is free.
-- Iterating: store this file once in ServerStorage.PhotoSet.Builder_B1 (a StringValue: Argon ignores it), then run
-- `return loadstring(game.ServerStorage.PhotoSet.Builder_B1.Value)({ PET_YAW = 20, ... })`; the table overrides the defaults.
-- While a set is in Workspace the Studio GUI is hidden (StarterGui.ShowDevelopmentGui); "stash" shows it again.
local P = ... or {}
local MODE: string = P.MODE or "build"
-- Owl: Rare, so Lv 16 is its real maximum (look tier 3: no halo); leans to Pest control and is the raccoon guard (KindSpec).
-- Owl uids at Lv 16: 2 / 3 / 4 Scarf, 1 / 5 Crown (no crown on a thumbnail pet).
local KIND, UID = P.KIND or "Owl", P.UID or "2"
local LEVEL = P.LEVEL -- nil: the kind's cap (PetConfig.AptitudeCap)
local PLOT_SLOT: any = P.PLOT_SLOT or "sun" -- a GardenConfig slot, or "sun": the inner-ring slot whose field faces the sun
local SQUARE = P.SQUARE or 32 -- the pet's square (rows 6, 6, 8, 8, 8 from the barn outward: 29..36 is the outer row)
local PUMPKIN_SQUARE = P.PUMPKIN_SQUARE or 31 -- left empty in CROPS; the big Pumpkin is planted there
local PUMPKIN_SEED = P.PUMPKIN_SEED or 1
local PUMPKIN_SIZE: any = P.PUMPKIN_SIZE or "max" -- a size factor, or "max": the upper bound of CropConfig.SizeBounds()
local PUMPKIN_YAW = P.PUMPKIN_YAW or 0 -- degrees about the square's centre
-- where the pet stands on its square (square space, studs; -Z toward the camera) and its pose
local PET_AT = P.PET_AT or Vector3.new(0, 0, -1.4)
local PET_YAW, PET_PITCH = P.PET_YAW or 30, P.PET_PITCH or 0 -- the Owl model faces the camera at 0; 30 turns it toward the Pumpkin
local REACH = if P.REACH == nil then true else P.REACH -- tint the pet's reach (PlotView:ShowReach)
local BORDER = if P.BORDER == nil then true else P.BORDER -- outline it in the pet's rarity colour (PlotView:ShowBorders, U3b)
local FOV = P.FOV or 50
-- draft I (2026-11-14): Pumpkin left, Owl right of centre, sky top-left for the logo in the final 16:9 band (+X is camera-left)
local CAMERA = P.CAMERA or Vector3.new(1.4, 3.2, -13) -- set space (origin: the pet's square at the soil top, -Z outward)
local LOOK = P.LOOK or Vector3.new(2.6, 2.9, 1.5) -- set-space look-at point
-- one CropConfig letter per square 1..36 (rows 6, 6, 8, 8, 8 from the barn outward), "." = empty soil, "#" = locked; all ripe.
-- No pumpkin other than the big one; tall crops (corn b, tomato k) at the back. No sunflower (r): its art is still a draft
-- (`Draft = true`), so the plot draws it as a yellow block.
local CROPS = P.CROPS or "bkkbkb" .. "kbobbk" .. "obkplbpk" .. "ombpkbnm" .. "hnp.ppqa"
-- degrees to turn every plant model of a name about the centre of its visible parts
local TURN: { [string]: number } = P.TURN or {}

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
	local set = assert(workspace:FindFirstChild("PhotoSet_B1"), "nothing to stash")
	local old = photoSet():FindFirstChild("B1")
	if old then
		old:Destroy()
	end
	set.Name = "B1"
	set.Parent = photoSet()
	workspace.CurrentCamera.FieldOfView = 70
	workspace.CurrentCamera.CameraType = Enum.CameraType.Fixed
	game:GetService("StarterGui").ShowDevelopmentGui = true
	return "stashed"
elseif MODE == "shoot" then
	local set = assert(photoSet():FindFirstChild("B1"), "no stashed B1")
	set.Name = "PhotoSet_B1"
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

-- fresh module copies (Edit-mode require caches across calls), held outside the DataModel so Argon never sees them
local lib = Instance.new("Folder")
for _, name in { "Num", "PetConfig", "PetLook", "PlantKit", "PumpkinPlant" } do
	RS[name]:Clone().Parent = lib
end
game:GetService("StarterPlayer").StarterPlayerScripts.PlotView:Clone().Parent = lib
lib.PetLook.Source = lib.PetLook.Source:gsub('ReplicatedStorage:WaitForChild%("PetConfig"%)', 'script.Parent:WaitForChild("PetConfig")')
local PetLook = require(lib.PetLook)
local PetConfig = require(lib.PetConfig)
local CropConfig = require(RS.CropConfig) -- TimeFormat needs Locale: not cloned (SizeBounds / Reach are plain)
local GardenConfig = require(RS.GardenConfig)
local Pumpkin = require(lib.PumpkinPlant)
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

local old = workspace:FindFirstChild("PhotoSet_B1")
if old then
	old:Destroy()
end
local set = Instance.new("Model")
set.Name = "PhotoSet_B1"

local cells = {}
for n = 1, CropConfig.MaxSquares do
	local letter = string.sub(CROPS, n, n)
	cells[n] = if letter == "" or letter == "." then ".0" elseif letter == "#" then "#0" else letter .. "3"
end
cells[PUMPKIN_SQUARE] = ".0"
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

-- the reach: the squares this pet would guard from its square (every square open)
local open = {}
for n = 1, CropConfig.MaxSquares do
	open[n] = string.sub(CROPS, n, n) ~= "#"
end
local reach = CropConfig.Reach(SQUARE, PetConfig.ReachShape(level), open)
if REACH then
	view:ShowReach(reach)
end
if BORDER then
	local rarity = PetConfig.RarityOf(KIND)
	view:ShowBorders({ { squares = reach, color = if rarity then rarity.color else Color3.new(1, 1, 1), lane = 0 } })
end

-- set frame O: origin on the pet's square at the soil top, -Z outward (away from the barn, toward the camera)
local square = view:SquareCFrame(SQUARE)
local back = (GardenConfig.PlotCFrame(slot) :: CFrame).LookVector
local out = -V(back.X, 0, back.Z).Unit
local O = CFrame.lookAt(square.Position, square.Position + out)

-- pet: dressed for its level, turned by PET_YAW (180 faces the camera), standing on the soil
local pet = RS.PetModels[KIND]:Clone()
assert(PetLook.Apply(pet, KIND, level, UID), "Apply failed")
pet.Parent = set
pet:PivotTo(O * CFrame.new(PET_AT + V(0, 3, 0)) * CFrame.Angles(0, math.rad(PET_YAW), 0) * CFrame.Angles(math.rad(PET_PITCH), 0, 0))
local box, size = pet:GetBoundingBox()
pet:PivotTo(pet:GetPivot() + V(0, O.Position.Y - (box.Position.Y - size.Y / 2), 0))
local fx = PetLook.CollectFx(pet)
if fx then
	PetLook.UpdateFx(fx, 0, false, false)
end

-- the big Pumpkin: ripe, at a real size, on its square
local _, upper = CropConfig.SizeBounds()
local factor = if PUMPKIN_SIZE == "max" then upper else PUMPKIN_SIZE :: number
assert(factor <= upper + 1e-6, "size factor above CropConfig.SizeBounds()")
local soilCF = view:SquareCFrame(PUMPKIN_SQUARE) * CFrame.Angles(0, math.rad(PUMPKIN_YAW), 0)
local plant = Pumpkin.new(set, soilCF, PUMPKIN_SEED, factor)
plant:SetGrowth(1)

set.Parent = workspace
local camera = workspace.CurrentCamera
camera.FieldOfView = FOV
game:GetService("StarterGui").ShowDevelopmentGui = false
local camPos, look = O * CAMERA, O * LOOK
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.lookAt(camPos, look)
set:SetAttribute("CameraPosition", camPos)
set:SetAttribute("CameraLook", look)
set:SetAttribute("FieldOfView", FOV)
return string.format("slot %d, %s %s Lv %d (cap %d), reach %d squares {%s}; pumpkin factor %.2f (upper %.2f); pet height %.1f\ncamera {%.2f, %.2f, %.2f} look {%.2f, %.2f, %.2f}",
	slot, KIND, UID, level, cap, #reach, table.concat(reach, ","), factor, upper, size.Y, camPos.X, camPos.Y, camPos.Z, look.X, look.Y, look.Z)
