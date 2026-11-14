-- Photo set C3 (docs/THUMBNAILS.md §4 C): the collection. Four pets in a row growing from a small Cat to a hovering Phoenix,
-- one per rarity step (Common, Uncommon, Rare, Legendary), each with a ripe crop beside it whose value and size grow too (pets
-- do not hold crops in the game). Frontal, the Phoenix dominant; bright day. Run through the Studio MCP `execute_luau` in Edit
-- mode with the Lighting preset C2 applied (tools/photoset_lighting.luau; C3 shares it): PLOT_SLOT "sun" picks the plot from
-- the sun direction.
--   "build"  (re)builds Workspace.PhotoSet_C3, sets the camera on it (Scriptable) and returns the camera position / look-at
--   "stash"  moves it to ServerStorage.PhotoSet.C3 (nothing shows in play) and resets the camera
--   "shoot"  moves the stashed set back into Workspace and sets its camera again
-- Real pieces only: the real plot drawn by PlotView, `<CropId>Plant` recipes at growth 1 with size factors inside
-- CropConfig.SizeBounds(), PetLook.Apply on PetModels clones at levels their rarity reaches (PetConfig.AptitudeCap). Poses free.
-- Iterating: store this file in ServerStorage.PhotoSet.Builder_C3 (a StringValue: Argon ignores it), then run
-- `return loadstring(game.ServerStorage.PhotoSet.Builder_C3.Value)({ FOV = 40, ... })`; the table overrides the defaults.
-- While a set is in Workspace the Studio GUI is hidden (StarterGui.ShowDevelopmentGui); "stash" shows it again.
local P = ... or {}
local MODE: string = P.MODE or "build"
local PLOT_SLOT: any = P.PLOT_SLOT or "sun"
-- camera-left to camera-right, each a step nearer the camera (the diagonal makes the ladder read: draft F, 2026-11-14).
-- One pet per rarity step (Dragon, Epic, left out: four read at tile size, five would not); the crop's seed price and size
-- factor grow with it. crop: CropConfig id, seed, size factor; at: the pet's offset from its square's centre (set axes: +X
-- camera-left, -Z toward the camera, Y = hover above the soil); cropAt: the crop's offset (default CROP_SHIFT); yaw: degrees
-- turning the pet (0 faces the camera).
local LINEUP = P.LINEUP or {
	{ kind = "Cat", uid = "2", level = 6, crop = "Tomato", seed = 1, size = 1.0, at = Vector3.new(-1.6, 0, -2.4), yaw = -14, cropAt = Vector3.new(-0.2, 0, 0.6) },
	{ kind = "Fox", uid = "4", level = 12, crop = "Blueberry", seed = 1, size = 1.4, at = Vector3.new(-0.4, 0, -3.6), yaw = -8, cropAt = Vector3.new(-1.6, 0, 0.6) },
	{ kind = "Panda", uid = "2", level = 16, crop = "Pumpkin", seed = 1, size = 2.0, at = Vector3.new(1.3, 0, -5.0), yaw = -2, cropAt = Vector3.new(-1.0, 0, 0.2) },
	-- hovering: its own glow; at the crown of the mushroom it hid the caps
	{ kind = "Phoenix", uid = "1", level = 19, crop = "GlowMushroom", seed = 1, size = 2.6, at = Vector3.new(3.8, 1.7, -7.4), yaw = 4, cropAt = Vector3.new(-0.6, 0, -0.4) },
}
local SQUARES = P.SQUARES or { 31, 32, 33, 34 } -- the middle of the outer row; ordered camera-left to camera-right at build
local CROP_SHIFT = P.CROP_SHIFT or Vector3.new(-1.0, 0, 0.6) -- each crop's offset from its square's centre (set axes)
-- extra yaw per kind on top of `yaw` (the models face their pivot's LookVector at 0)
local FACE = P.FACE or {}
local FOV = P.FOV or 40
-- set space: origin between the middle two squares at the soil top; low and tilted up, so the grass in front drops out
local CAMERA = P.CAMERA or Vector3.new(0.6, 1.2, -24)
local LOOK = P.LOOK or Vector3.new(0.4, 4.4, 0)
-- one CropConfig letter per square 1..36 (rows 6, 6, 8, 8, 8 from the barn outward), "." = empty soil, "#" = locked; all ripe.
-- SQUARES are cleared (their crops are the lineup's). No sunflower (r: draft art).
local CROPS = P.CROPS or "bkkbkb" .. "kbobbk" .. "obkplbpk" .. "ombpkbnm" .. "hn....qa"

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
	local set = assert(workspace:FindFirstChild("PhotoSet_C3"), "nothing to stash")
	local old = photoSet():FindFirstChild("C3")
	if old then
		old:Destroy()
	end
	set.Name = "C3"
	set.Parent = photoSet()
	workspace.CurrentCamera.FieldOfView = 70
	workspace.CurrentCamera.CameraType = Enum.CameraType.Fixed
	game:GetService("StarterGui").ShowDevelopmentGui = true
	return "stashed"
elseif MODE == "shoot" then
	local set = assert(photoSet():FindFirstChild("C3"), "no stashed C3")
	set.Name = "PhotoSet_C3"
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
local names = { "Num", "PetConfig", "PetLook", "PlantKit" }
for _, entry in LINEUP do
	table.insert(names, entry.crop .. "Plant")
end
for _, name in names do
	if not lib:FindFirstChild(name) then
		RS[name]:Clone().Parent = lib
	end
end
game:GetService("StarterPlayer").StarterPlayerScripts.PlotView:Clone().Parent = lib
lib.PetLook.Source = lib.PetLook.Source:gsub('ReplicatedStorage:WaitForChild%("PetConfig"%)', 'script.Parent:WaitForChild("PetConfig")')
local PetLook = require(lib.PetLook)
local PetConfig = require(lib.PetConfig)
local CropConfig = require(RS.CropConfig)
local GardenConfig = require(RS.GardenConfig)
local PlotView = require(lib.PlotView)
local _, upper = CropConfig.SizeBounds()

for _, entry in LINEUP do
	local cap = PetConfig.AptitudeCap(entry.kind)
	assert(entry.level <= cap, string.format("%s reaches Lv %d at most (rarity cap): Lv %d is not real content", entry.kind, cap, entry.level))
	assert(entry.size <= upper + 1e-6, "size factor above CropConfig.SizeBounds()")
	assert(not require(lib[entry.crop .. "Plant"]).Draft, entry.crop .. " art is still a draft")
end

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

local old = workspace:FindFirstChild("PhotoSet_C3")
if old then
	old:Destroy()
end
local set = Instance.new("Model")
set.Name = "PhotoSet_C3"

local cells = {}
for n = 1, CropConfig.MaxSquares do
	local letter = string.sub(CROPS, n, n)
	cells[n] = if letter == "" or letter == "." then ".0" elseif letter == "#" then "#0" else letter .. "3"
end
for _, n in SQUARES do
	cells[n] = ".0"
end
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

-- set frame O: origin between the SQUARES at the soil top, -Z outward (toward the camera), +X camera-left
local back = (GardenConfig.PlotCFrame(slot) :: CFrame).LookVector
local out = -V(back.X, 0, back.Z).Unit
local mid = V(0, 0, 0)
for _, n in SQUARES do
	mid += view:SquareCFrame(n).Position / #SQUARES
end
local O = CFrame.lookAt(mid, mid + out)
local order = table.clone(SQUARES)
table.sort(order, function(a, b)
	return O:PointToObjectSpace(view:SquareCFrame(a).Position).X > O:PointToObjectSpace(view:SquareCFrame(b).Position).X
end)

local report = {}
for i, entry in LINEUP do
	local square = view:SquareCFrame(order[i])
	local S = CFrame.lookAt(square.Position, square.Position + out) -- the square in set axes
	-- the crop, ripe, on its square
	local holder = Instance.new("Model")
	holder.Name = entry.crop
	holder.Parent = set
	local plant = require(lib[entry.crop .. "Plant"]).new(holder, square + S:VectorToWorldSpace(entry.cropAt or CROP_SHIFT), entry.seed, entry.size)
	plant:SetGrowth(1)
	-- the pet in front of it
	local pet = RS.PetModels[entry.kind]:Clone()
	assert(PetLook.Apply(pet, entry.kind, entry.level, entry.uid), "Apply failed for " .. entry.kind)
	for _, p in pet:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
		end
	end
	local at = S * CFrame.new(entry.at.X, 3, entry.at.Z)
	pet:PivotTo(at * CFrame.Angles(0, math.rad((FACE[entry.kind] or 0) + (entry.yaw or 0)), 0))
	local box, size = pet:GetBoundingBox()
	pet:PivotTo(pet:GetPivot() + V(0, square.Position.Y + entry.at.Y - (box.Position.Y - size.Y / 2), 0))
	pet.Parent = set
	local fx = PetLook.CollectFx(pet)
	if fx then
		-- orbiting motes: the moment when every mote stands most to the side as seen from the camera (at 0 one sat on the
		-- Panda's nose)
		local toCam = (O * CAMERA - pet:GetPivot().Position) * V(1, 0, 1)
		toCam = pet:GetPivot():VectorToObjectSpace(toCam.Unit)
		local bestT, bestScore = 0, -1
		for t = 0, 30, 0.05 do
			local score = 1
			for _, mote in fx.motes do
				local angle = mote.phase + t * mote.speed
				local offset = V(math.cos(angle), 0, math.sin(angle))
				score = math.min(score, offset:Cross(toCam).Magnitude)
			end
			if score > bestScore then
				bestT, bestScore = t, score
			end
		end
		PetLook.UpdateFx(fx, bestT, false, false)
	end
	table.insert(report, string.format("%s %s Lv %d (%.1f tall) + %s x%.1f on %d", entry.kind, entry.uid, entry.level, size.Y, entry.crop, entry.size, order[i]))
end

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
return string.format("slot %d; %s\ncamera {%.2f, %.2f, %.2f} look {%.2f, %.2f, %.2f}", slot, table.concat(report, "; "),
	camPos.X, camPos.Y, camPos.Z, look.X, look.Y, look.Z)
