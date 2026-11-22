-- Photo set A1 (docs/THUMBNAILS.md §4 A): one jump over World 3 lava with a Dragon trailing, the garden island behind. Shot
-- in Stage 15 (Rising Tide) itself: the 34-stud Long Dash gap D1 -> D2, the tide risen to just under the pillar tops, the
-- camera on the course's east side looking west-north-west along the line jump -> garden island, so the island stands
-- beyond the lava's far edge (the tide covers only the course's footprint, x -200..-40). From the Shore (z -500) that line
-- runs through Stages 13 / 14; from Dash Run it is clear. Run through the Studio MCP `execute_luau` in Edit mode. Needs
-- ServerStorage.PhotoSet.Builder_Rig (tools/photoset_rig.luau) and the Lighting preset A1 (tools/photoset_lighting.luau).
--   "build"  (re)builds Workspace.PhotoSet_A1, sets the camera on it (Scriptable) and returns the camera position / look-at
--   "stash"  moves it to ServerStorage.PhotoSet.A1 and resets the camera
--   "shoot"  moves the stashed set back into Workspace and sets its camera again
-- Real pieces only: the stage as built (nothing in it is moved or changed); the tide is an untagged copy of Stage15.Tide with
-- its CrackedLava `Crust` at LAVA_Y (a height a run reaches: from 1303 it rises from 116.5 at 1.5 studs/s, so 137.5 is about
-- 14 s behind a clean run); the Dragon at Lv 18, its kind's cap. Pose, pet placement and camera are free; the garden island
-- is a moved copy (GARDEN_COPY, the user's call).
-- Geometry: the garden sits at sea level ~1250 studs away (about 6° below the horizon from the jump) and the lava's far edge
-- ~100-140 studs from the camera hides everything below it, so the island shows only while the camera stands well above the
-- lava ((camera - lava) / edge distance > (camera - sea) / island distance): a camera low over the lava loses the island.
-- Iterating: store this file in ServerStorage.PhotoSet.Builder_A1 and run
-- `return loadstring(game.ServerStorage.PhotoSet.Builder_A1.Value)({ RIG_YAW = 130, ... })`.
local P = ... or {}
local MODE: string = P.MODE or "build"
local STAGE = P.STAGE or "World3.Stage15"
-- view space: origin in the gap's middle at the pillars' top level (D1 142.5, D2 144.5), -Z toward the garden island
-- (horizontal), +X screen right, +Y up; the jump runs world +z = screen left (view {-0.89, 0, 0.46})
local ORIGIN = P.ORIGIN or Vector3.new(-150, 143.5, -269)
local GARDEN = P.GARDEN or Vector3.new(-1223, 16, -834) -- Workspace.Garden.Island
local LAVA_Y = P.LAVA_Y or 137.5 -- world top of the tide copy
local LOOK_NAME = P.LOOK_NAME -- nil: the rig's default look (Rig.LOOK)
local POSE: any = P.POSE or "dash" -- a Rig.POSES name or a pose table
local MIRROR = if P.MIRROR == nil then true else P.MIRROR -- dash / leap mirrored run screen left (as A2's draft L)
-- draft N (the user, 2026-11-15: "show where the player jumps to"): the player near D2, over the lava 2 studs above its
-- top, D2's stud top and Stage 15's coin in the foreground at the left, so the landing reads
local R = Vector3.new(-12.5, 0, 6.5)
local RIG_AT = P.RIG_AT or R -- view space; Y is ignored (GROUND)
local GROUND = P.GROUND or 3 -- view Y of the lower foot: mid-dash, 2 above D2's top
-- 0 faces the island (away from the camera), 180 the camera, 118 runs along the jump
local RIG_YAW = P.RIG_YAW or 122
-- Dragon uid 1 at Lv 18 (Epic cap, tier 3: FlameTail, orbiting motes; uids 2 / 4 / 8 / 10 wear a Scarf instead)
local PET_KIND, PET_UID, PET_LEVEL = P.PET_KIND or "Dragon", P.PET_UID or "1", P.PET_LEVEL or 18
-- view space: trailing, behind (screen right of) and above the player, at draft K's distance (the user's pick), fully in frame
local PET_AT = P.PET_AT or R + Vector3.new(5.6, 6.6, -6)
local PET_YAW = P.PET_YAW or 135 -- as RIG_YAW
local FOV = P.FOV or 42
local CAMERA = P.CAMERA or R + Vector3.new(0, 8.5, 20) -- view space: 8.5 above the pillar-top level, 14.5 above the lava
local LOOK = P.LOOK or R + Vector3.new(-3.5, 5.7, 0) -- left and down: D2's top fills the lower left
local ROLL = P.ROLL or -7 -- degrees, a tilted camera (+ turns the picture clockwise)
-- scene folders hidden while the set is shot (LocalTransparencyModifier: render only, never saved; stash shows them again):
-- Stage 14's Laser Lab panels stood as grey slabs behind the Dragon
local HIDE = P.HIDE or { "World3.Stage14" }
-- The garden island (the user, 2026-11-15: "garden copy, closer"): from Stage 15 the Laser Lab's back wall (BeamHall,
-- z -581) covers half of the real island, and Edit draws no plots (PlotView runs on clients). The set holds a copy of
-- Workspace.Garden with GARDEN_SLOTS plots drawn by PlotView (ripe crops from GARDEN_CROPS), moved toward the camera along
-- its own sight lines and scaled by the same factor: at GARDEN_AT studs from the camera it looks exactly like the real
-- island (GARDEN_SIZE 1) but stands in front of the Laser Lab. GARDEN_SIZE > 1 shows it bigger (about its centre),
-- GARDEN_LIFT raises it (studs at the real island's distance). false: no copy (the real view).
local GARDEN_COPY = if P.GARDEN_COPY == nil then true else P.GARDEN_COPY
local GARDEN_AT = P.GARDEN_AT or 420 -- in front of the BeamHall wall (~600 out), behind the lava's far edge (~140)
local GARDEN_SIZE = P.GARDEN_SIZE or 1.8
local GARDEN_LIFT = P.GARDEN_LIFT or 0
-- degrees the copy is turned about the camera's vertical axis (+ moves it screen left): it keeps its look and moves in
-- the frame, so the camera can turn toward the landing pillar while the island stays behind the player
local GARDEN_TURN = P.GARDEN_TURN or 0
local SEA_Y = 0 -- the sea's top (Workspace.DebugBaseplate)
local GARDEN_SEA = P.GARDEN_SEA or 2000 -- radius of the copy's own sea disc (0: none); its far edge near the horizon
local GARDEN_SLOTS = P.GARDEN_SLOTS or 8 -- a full server (Max Players 8, FX)
local GARDEN_DETAIL = P.GARDEN_DETAIL or "mid"
-- ripe crops, a letter per square cycled over the plots (CropConfig letters; no Sunflower: its art is a draft): corn,
-- pumpkin, pineapple, giant melon, sweet potato, a golden carrot now and then
local GARDEN_CROPS = P.GARDEN_CROPS or "bcsbdcsqbcsdbcse"

local RS = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
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

local function hide(set: Instance, on: boolean)
	for _, path in string.split(set:GetAttribute("Hide") or "", ",") do
		local node: Instance? = workspace
		for _, name in string.split(path, ".") do
			node = node and node:FindFirstChild(name)
		end
		for _, p in if node and node ~= workspace then node:GetDescendants() else {} do
			if p:IsA("BasePart") then
				p.LocalTransparencyModifier = if on then 1 else 0
			end
		end
	end
end

local function setCamera(set: Instance)
	hide(set, true)
	local camera = workspace.CurrentCamera
	camera.FieldOfView = set:GetAttribute("FieldOfView")
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(set:GetAttribute("CameraPosition"), set:GetAttribute("CameraLook"))
		* CFrame.Angles(0, 0, -math.rad(set:GetAttribute("CameraRoll") or 0))
	-- without Focus Studio's edit camera reset itself to Fixed and an old orientation before a grab (stale frames)
	camera.Focus = CFrame.new(set:GetAttribute("CameraLook"))
	game:GetService("StarterGui").ShowDevelopmentGui = false
end

if MODE == "stash" then
	local set = assert(workspace:FindFirstChild("PhotoSet_A1"), "nothing to stash")
	hide(set, false)
	local old = photoSet():FindFirstChild("A1")
	if old then
		old:Destroy()
	end
	set.Name = "A1"
	set.Parent = photoSet()
	workspace.CurrentCamera.FieldOfView = 70
	workspace.CurrentCamera.CameraType = Enum.CameraType.Fixed
	game:GetService("StarterGui").ShowDevelopmentGui = true
	return "stashed"
elseif MODE == "shoot" then
	local set = assert(photoSet():FindFirstChild("A1"), "no stashed A1")
	set.Name = "PhotoSet_A1"
	set.Parent = workspace
	setCamera(set)
	return "in Workspace"
end
assert(MODE == "build", "unknown MODE " .. MODE)

local Rig = loadstring(assert(photoSet():FindFirstChild("Builder_Rig"), "store tools/photoset_rig.luau in Builder_Rig").Value)()

-- fresh module copies (Edit-mode require caches across calls), outside the DataModel
local lib = Instance.new("Folder")
for _, name in { "Num", "PetConfig", "PetLook" } do
	RS[name]:Clone().Parent = lib
end
lib.PetLook.Source = lib.PetLook.Source:gsub('ReplicatedStorage:WaitForChild%("PetConfig"%)', 'script.Parent:WaitForChild("PetConfig")')
local PetLook = require(lib.PetLook)
local PetConfig = require(lib.PetConfig)
assert(PET_LEVEL <= PetConfig.AptitudeCap(PET_KIND), "pet level above its kind's cap")

local stage: Instance = workspace
for name in string.gmatch(STAGE, "[^%.]+") do
	stage = stage:FindFirstChild(name) :: Instance
	assert(stage, "no stage " .. STAGE)
end
local toGarden = ((GARDEN - ORIGIN) * V(1, 0, 1)).Unit
local O = CFrame.lookAt(ORIGIN, ORIGIN + toGarden)

local old = workspace:FindFirstChild("PhotoSet_A1")
if old then
	old:Destroy()
end
local set = Instance.new("Model")
set.Name = "PhotoSet_A1"

-- the tide at LAVA_Y: an untagged copy (KitTide must never pick it up), nothing collides or kills; its look layers (the
-- CrackedLava `Crust`, KitTide's BasePart children) come along at their offset, other children (sounds) are dropped
local tide = (stage :: any).Tide:Clone() :: BasePart
for _, child in tide:GetChildren() do
	if not child:IsA("BasePart") then
		child:Destroy()
	end
end
for _, tag in CollectionService:GetTags(tide) do
	CollectionService:RemoveTag(tide, tag)
end
for name in tide:GetAttributes() do
	tide:SetAttribute(name, nil)
end
tide.Anchored, tide.CanCollide, tide.CanTouch, tide.CanQuery = true, false, false, false
local rise = V(0, LAVA_Y - tide.Size.Y / 2 - tide.Position.Y, 0)
tide.CFrame += rise
for _, layer in tide:GetChildren() do
	(layer :: BasePart).CFrame += rise
end
tide.Parent = set

-- the player, mid-dash over the gap
local rig = Rig.build(if LOOK_NAME then Rig.LOOKS[LOOK_NAME] else nil)
local pose = if type(POSE) == "string" then Rig.POSES[POSE] else POSE
if MIRROR then
	pose = Rig.mirror(pose)
end
Rig.pose(rig, pose, O * CFrame.new(RIG_AT + V(0, 3, 0)) * CFrame.Angles(0, math.rad(RIG_YAW), 0), ORIGIN.Y + GROUND)
rig.Parent = set

-- the Dragon, trailing
local pet = RS.PetModels[PET_KIND]:Clone()
assert(PetLook.Apply(pet, PET_KIND, PET_LEVEL, PET_UID), "Apply failed")
pet:PivotTo(O * CFrame.new(PET_AT) * CFrame.Angles(0, math.rad(PET_YAW), 0))
for _, p in pet:GetDescendants() do
	if p:IsA("BasePart") then
		p.Anchored = true
	end
end
pet.Parent = set
local fx = PetLook.CollectFx(pet)
if fx then
	PetLook.UpdateFx(fx, 0, false, false)
end

-- the garden island copy (see GARDEN_COPY)
if GARDEN_COPY then
	local GardenConfig = require(RS.GardenConfig)
	local CropConfig = require(RS.CropConfig)
	game:GetService("StarterPlayer").StarterPlayerScripts.PlotView:Clone().Parent = lib
	local PlotView = require(lib.PlotView)
	local garden = Instance.new("Model")
	garden.Name = "Garden"
	for _, child in workspace.Garden:GetChildren() do
		child:Clone().Parent = garden
	end
	local views = {}
	local cursor = 0
	for slot = 1, GARDEN_SLOTS do
		local cells = {}
		for n = 1, CropConfig.MaxSquares do
			cursor = cursor % #GARDEN_CROPS + 1
			cells[n] = string.sub(GARDEN_CROPS, cursor, cursor) .. "3"
		end
		local view = PlotView.new(slot, garden)
		view:SetState({ name = "", incCount = 3, eggs = {}, ownerId = slot, field = { crops = table.concat(cells), pets = {} } })
		view:SetDetail(GARDEN_DETAIL)
		table.insert(views, view)
	end
	local started = os.clock()
	for _, view in views do
		while view:Step(os.clock() + 0.01) and os.clock() - started < 120 do
			task.wait()
		end
	end
	-- scene only: no scripts (Argon would sync them), no labels or prompts, nothing to touch
	for _, d in garden:GetDescendants() do
		if d:IsA("LuaSourceContainer") or d:IsA("BillboardGui") or d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored, d.CanCollide, d.CanTouch, d.CanQuery = true, false, false, false
		end
	end
	-- cut at the sea (DebugBaseplate's top, y 0): the real island's rock is under water, the copy stands above it
	for _, d in garden:GetDescendants() do
		if d:IsA("BasePart") then
			local cf, size = d.CFrame, d.Size
			local axes = { { cf.RightVector, "X" }, { cf.UpVector, "Y" }, { cf.LookVector, "Z" } }
			local extent = 0
			for _, a in axes do
				extent += math.abs(a[1].Y) * (size :: any)[a[2]] / 2
			end
			local bottom, top = cf.Position.Y - extent, cf.Position.Y + extent
			if top <= SEA_Y then
				d:Destroy()
			elseif bottom < SEA_Y then
				for _, a in axes do -- trim along the local axis that stands upright (cylinders, slabs)
					if math.abs(a[1].Y) > 0.99 then
						local cut = SEA_Y - bottom
						local s = { X = size.X, Y = size.Y, Z = size.Z }
						s[a[2]] -= cut
						d.Size = V(s.X, s.Y, s.Z)
						d.CFrame = cf + V(0, cut / 2, 0)
						break
					end
				end
			end
		end
	end
	-- scaled about the island's centre at the waterline, so a bigger copy still sits on the sea
	local centre = workspace.Garden.Island.Position * V(1, 0, 1) + V(0, SEA_Y, 0)
	local camPos = O * CAMERA
	local k = GARDEN_AT / (centre - camPos).Magnitude
	garden.WorldPivot = CFrame.new(centre)
	garden:ScaleTo(k * GARDEN_SIZE)
	local turn = CFrame.Angles(0, math.rad(GARDEN_TURN), 0)
	local at = camPos + turn * ((centre - camPos) * k + V(0, GARDEN_LIFT * k, 0))
	garden:PivotTo(CFrame.new(at) * turn)
	-- the copy's own sea: its waterline is a plane far above the real sea, so without water round it the island floats
	-- (the real sea showed under its near rim); a disc in the sea's own material and colour, its near edge behind the lava
	if GARDEN_SEA > 0 then
		local real = workspace.DebugBaseplate :: BasePart
		local sea = Instance.new("Part")
		sea.Name = "Sea"
		sea.Shape = Enum.PartType.Cylinder
		sea.Material, sea.MaterialVariant, sea.Color = real.Material, real.MaterialVariant, real.Color
		sea.Anchored, sea.CanCollide, sea.CanTouch, sea.CanQuery, sea.CastShadow = true, false, false, false, false
		sea.Size = V(1, GARDEN_SEA * 2, GARDEN_SEA * 2)
		sea.CFrame = CFrame.new(at - V(0, 0.55, 0)) * CFrame.Angles(0, 0, math.rad(90))
		sea.Parent = garden
	end
	garden.Parent = set
end

set:SetAttribute("CameraPosition", O * CAMERA)
set:SetAttribute("CameraLook", O * LOOK)
set:SetAttribute("FieldOfView", FOV)
set:SetAttribute("CameraRoll", ROLL)
set:SetAttribute("Hide", table.concat(HIDE, ","))
set.Parent = workspace
setCamera(set)
local camPos, look = O * CAMERA, O * LOOK
local _, size = rig:GetBoundingBox()
return string.format("%s %s Lv %d, lava %.1f; rig height %.1f\ncamera {%.2f, %.2f, %.2f} look {%.2f, %.2f, %.2f} FOV %d roll %d",
	PET_KIND, PET_UID, PET_LEVEL, LAVA_Y, size.Y, camPos.X, camPos.Y, camPos.Z, look.X, look.Y, look.Z, FOV, ROLL)
