-- Photo set A2 (docs/THUMBNAILS.md §4 A): the Laser Lab (Stage 14) seen side-on, as its own 2D camera shows it. Draft L (the
-- user's pick, 2026-11-14): in the Vault, the player jumps up and left off the blue switch she has just pressed, its wire lit
-- green, the floor spikes below, the Dog following (draft H, a leap over a sweeping laser arm: THUMBNAILS §9). Shot at night
-- (Lighting preset A2: by day the lab is a light room). Run through the Studio MCP `execute_luau` in Edit mode. Needs
-- ServerStorage.PhotoSet.Builder_Rig (tools/photoset_rig.luau) and the Lighting preset A2 (tools/photoset_lighting.luau)
-- applied first.
--   "build"  (re)builds Workspace.PhotoSet_A2, draws the stage's hazards at run time T, sets the camera (Scriptable) and
--            returns the camera position / look-at
--   "stash"  moves it to ServerStorage.PhotoSet.A2, shows the stage's hazards as they are in Studio, resets the camera
--   "shoot"  moves the stashed set back into Workspace, draws the hazards at its T and sets its camera again
-- Real pieces only, at one real moment: every hazard is drawn as ObstacleKit draws it T seconds into a run (they are all
-- RunSeeded): each KitBeam at its KitMath.Window state (on 0.15 / warning 0.8 / off invisible), each Spin sweeper turned to
-- (Speed * T + Phase) on a copy over the original. The originals are hidden only through LocalTransparencyModifier (not
-- saved, reset by "stash"); nothing in the stage is moved or changed. The coin is the stage's own. Pose, pet placement,
-- camera and the key light are free.
-- Iterating: store this file in ServerStorage.PhotoSet.Builder_A2 and run
-- `return loadstring(game.ServerStorage.PhotoSet.Builder_A2.Value)({ T = 8.78, ... })`.
local P = ... or {}
local MODE: string = P.MODE or "build"
local STAGE = P.STAGE or "World3.Stage14"
-- lab space: origin on the top of the Vault's Block_Float2 in the lane's middle (Switch_Lane1 lies on it, lab X +2); +X along
-- the course (world -x, screen right in the game's side view), +Y up, +Z toward the camera (world -z, the game's camera side)
local ORIGIN = P.ORIGIN or Vector3.new(-338.4, 86.15, -585)
-- seconds into the run (no timed hazard is in L's frame; for H: Sweeper1's east arm 35° below level under the player, Beam3
-- and Beam4 on)
local T = P.T or 0.78
-- colour-switch groups shown as pressed, { [Group] = "Blue" | "Red" }: ObstacleKit ghosts the plates of the other colour
-- (transparency 0.85), KitWires lights a group's wire while it is off Red (neon green). Groups left out keep their Studio
-- look (every group starts Red). For a one-switch group (Vault1 / Vault2); the shaft's Lab group lights only the pressed
-- switch's wire, which this does not tell apart.
local COLORS: { [string]: string } = P.COLORS or { Vault1 = "Blue" } -- L: Switch_Lane1 just pressed
local MIRROR = if P.MIRROR == nil then true else P.MIRROR -- mirror the pose (Rig.mirror): L jumps against the course
local LOOK_NAME = P.LOOK_NAME -- nil: the rig's default look (Rig.LOOK)
local POSE: any = P.POSE or "leap" -- a Rig.POSES name or a pose table
local RIG_AT = P.RIG_AT or Vector3.new(-8, 0, 0) -- lab space, between the switch and Block_Float1; Y is ignored (GROUND)
local GROUND = P.GROUND or 5.5 -- lab Y of the lower foot: mid-jump
local RIG_YAW = P.RIG_YAW or 112 -- 90 runs against the course, -90 along it, ±180 faces the camera (the pose turns the head)
-- Dog uid 4 at Lv 12 (its cap; Wings, so it can fly behind): warm brown on the dark-blue lab, unused by the other sets.
-- The Dragon (purple) vanished against the panel at night (draft A).
local PET_KIND, PET_UID, PET_LEVEL = P.PET_KIND or "Dog", P.PET_UID or "4", P.PET_LEVEL or 12
local PET_AT = P.PET_AT or Vector3.new(-1.2, 8.8, 1.5) -- lab space: following up from the switch, just left of its wire
local PET_YAW = P.PET_YAW or 130
local KEY_LIGHT = if P.KEY_LIGHT == nil then true else P.KEY_LIGHT
-- a narrow spot from in front and above (a wide one lit a pale disc on the back panel)
local KEY_AT = P.KEY_AT or Vector3.new(-4, 16, 18) -- lab space
local KEY_BRIGHTNESS = P.KEY_BRIGHTNESS or 6
local KEY_ANGLE = P.KEY_ANGLE or 28
local FOV = P.FOV or 50
-- square on to the lane like the game's side camera, 37 studs out (the game's Vault camera: 55): the floor spikes bottom
-- left and the lit wire along the top both inside the 16:9 band (at 33 out the band cut the spikes)
local CAMERA = P.CAMERA or Vector3.new(-16, 6.2, 37) -- lab space
local LOOK = P.LOOK or Vector3.new(-16, 6.2, 0)

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

local stage: Instance = workspace
for name in string.gmatch(STAGE, "[^%.]+") do
	stage = stage:FindFirstChild(name) :: Instance
	assert(stage, "no stage " .. STAGE)
end

local function attr(part: Instance, name: string, default: any): any
	local value = part:GetAttribute(name)
	if value == nil then
		return default
	end
	return value
end

local function tagged(tag: string): { BasePart }
	local list = {}
	for _, part in CollectionService:GetTagged(tag) do
		if part:IsA("BasePart") and part:IsDescendantOf(stage) then
			table.insert(list, part)
		end
	end
	return list
end

local function sweepers(): { BasePart }
	local list = {}
	for _, part in tagged("KitMover") do
		if attr(part, "Kind", "Slide") == "Spin" then
			table.insert(list, part)
		end
	end
	return list
end

local function strip(copy: BasePart, name: string)
	for _, tag in CollectionService:GetTags(copy) do
		CollectionService:RemoveTag(copy, tag)
	end
	for attribute in copy:GetAttributes() do
		copy:SetAttribute(attribute, nil)
	end
	copy.Name = name
	copy.Anchored, copy.CanCollide, copy.CanTouch, copy.CanQuery = true, false, false, false
end

-- ObstacleKit's hazards at run time `t` and the colour groups `colors` (nil: as in Studio). Returns a line per hazard.
local BEAM_TRANSPARENCY = { off = 1, warning = 0.8, on = 0.15 } -- ObstacleKit
local LIT_COLOR = Color3.fromRGB(80, 255, 120) -- KitWires
local function drawHazards(set: Instance?, t: number?, colors: { [string]: string }?): string
	local KitMath = require(RS.KitMath:Clone())
	local lines = {}
	for _, beam in tagged("KitBeam") do
		if t then
			local state = KitMath.Window(t, attr(beam, "Period", 4), attr(beam, "Duty", 0.5), attr(beam, "Phase", 0),
				attr(beam, "Telegraph", 0.4))
			local name = if state == "on" then "OnTransparency" elseif state == "warning" then "WarnTransparency" else "OffTransparency"
			-- the parts are opaque in Studio, so the modifier is the transparency ObstacleKit would set
			beam.LocalTransparencyModifier = attr(beam, name, BEAM_TRANSPARENCY[state])
			table.insert(lines, beam.Name .. " " .. state)
		else
			beam.LocalTransparencyModifier = 0
		end
	end
	for _, sweeper in sweepers() do
		if t and set then
			local degrees = (attr(sweeper, "Speed", 60) * t + attr(sweeper, "Phase", 0)) % 360
			local copy = sweeper:Clone()
			strip(copy, sweeper.Name .. "_At")
			copy.CFrame = sweeper.CFrame * CFrame.Angles(0, math.rad(degrees), 0)
			copy.Parent = set
			sweeper.LocalTransparencyModifier = 1
			table.insert(lines, string.format("%s %.0f°", sweeper.Name, degrees))
		else
			sweeper.LocalTransparencyModifier = 0
		end
	end
	for group, color in colors or {} do
		table.insert(lines, group .. " " .. color)
	end
	for _, plate in tagged("KitColorPlate") do
		local shown = colors and colors[attr(plate, "Group", "A")]
		plate.LocalTransparencyModifier = if shown and shown ~= attr(plate, "Color", "Red") then 0.85 else 0
	end
	for _, wire in tagged("KitWire") do
		local shown = colors and colors[attr(wire, "Group", "A")]
		if set and shown and shown ~= "Red" then
			local copy = wire:Clone()
			strip(copy, wire.Name .. "_At")
			copy.Material, copy.Color = Enum.Material.Neon, LIT_COLOR
			copy.Parent = set
			wire.LocalTransparencyModifier = 1
		else
			wire.LocalTransparencyModifier = 0
		end
	end
	return table.concat(lines, ", ")
end

local function setCamera(set: Instance)
	local camera = workspace.CurrentCamera
	camera.FieldOfView = set:GetAttribute("FieldOfView") or FOV
	local camPos, look = set:GetAttribute("CameraPosition"), set:GetAttribute("CameraLook")
	if camPos and look then
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.lookAt(camPos, look)
	end
	game:GetService("StarterGui").ShowDevelopmentGui = false
end

if MODE == "stash" then
	local set = assert(workspace:FindFirstChild("PhotoSet_A2"), "nothing to stash")
	local old = photoSet():FindFirstChild("A2")
	if old then
		old:Destroy()
	end
	drawHazards(nil, nil, nil)
	set.Name = "A2"
	set.Parent = photoSet()
	workspace.CurrentCamera.FieldOfView = 70
	workspace.CurrentCamera.CameraType = Enum.CameraType.Fixed
	game:GetService("StarterGui").ShowDevelopmentGui = true
	return "stashed; hazards as in Studio"
elseif MODE == "shoot" then
	local set = assert(photoSet():FindFirstChild("A2"), "no stashed A2")
	for _, child in set:GetChildren() do
		if child.Name:match("_At$") then
			child:Destroy()
		end
	end
	local colors = game:GetService("HttpService"):JSONDecode(set:GetAttribute("Colors") or "{}")
	local hazards = drawHazards(set, set:GetAttribute("T"), colors)
	set.Name = "PhotoSet_A2"
	set.Parent = workspace
	setCamera(set)
	return "in Workspace; " .. hazards
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

-- lab space: +X = world -x, +Y up, so +Z = world -z
local O = CFrame.fromMatrix(ORIGIN, V(-1, 0, 0), V(0, 1, 0))

local old = workspace:FindFirstChild("PhotoSet_A2")
if old then
	old:Destroy()
end
local set = Instance.new("Model")
set.Name = "PhotoSet_A2"
set:SetAttribute("T", T)
set:SetAttribute("Colors", game:GetService("HttpService"):JSONEncode(COLORS))
local hazards = drawHazards(set, T, COLORS)

-- the player, mid-leap
local look = if LOOK_NAME then assert(Rig.LOOKS[LOOK_NAME], "no rig look " .. LOOK_NAME) else nil
local rig = Rig.build(look)
local rigAt = O * CFrame.new(RIG_AT.X, GROUND + 3, RIG_AT.Z) * CFrame.Angles(0, math.rad(RIG_YAW), 0)
local pose = if type(POSE) == "table" then POSE else Rig.POSES[POSE]
Rig.pose(rig, if MIRROR then Rig.mirror(pose) else pose, rigAt, (O * V(0, GROUND, 0)).Y)
rig.Parent = set

-- the pet, trailing
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

-- a key light on the player (the lab is dark at night)
if KEY_LIGHT then
	local key = Instance.new("Part")
	key.Name = "KeyLight"
	key.Size = V(0.2, 0.2, 0.2)
	key.Transparency = 1
	key.Anchored, key.CanCollide, key.CanTouch, key.CanQuery, key.CastShadow = true, false, false, false, false
	local target = rig:GetPivot().Position
	key.CFrame = CFrame.lookAt((O * KEY_AT), target)
	local spot = Instance.new("SpotLight")
	spot.Face = Enum.NormalId.Front
	spot.Angle = KEY_ANGLE
	spot.Range = 40
	spot.Brightness = KEY_BRIGHTNESS
	spot.Color = Color3.fromRGB(255, 244, 230)
	spot.Shadows = false
	spot.Parent = key
	key.Parent = set
end

set.Parent = workspace
local camPos, lookAt = O * CAMERA, O * LOOK
set:SetAttribute("CameraPosition", camPos)
set:SetAttribute("CameraLook", lookAt)
set:SetAttribute("FieldOfView", FOV)
setCamera(set)
local _, size = rig:GetBoundingBox()
return string.format("%s T %.2f: %s\n%s %s Lv %d; rig height %.1f\ncamera {%.2f, %.2f, %.2f} look {%.2f, %.2f, %.2f}", STAGE, T,
	hazards, PET_KIND, PET_UID, PET_LEVEL, size.Y, camPos.X, camPos.Y, camPos.Z, lookAt.X, lookAt.Y, lookAt.Z)
