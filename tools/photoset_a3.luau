-- Photo set A3 (docs/THUMBNAILS.md §4 A): the player landing on a lit stud checkpoint, facing the camera and cheering, the
-- Phoenix beside them, a challenge coin about to be taken; shot in the stage itself (Stage 1's Island Hop, checkpoint 105:
-- the camera stands ahead of the pad and looks back along the pillar chain over the sea, so the run reads as an obby; a
-- low shot between Stage 3's kill corridors read as "anything", the user 2026-11-14). Run through the Studio MCP `execute_luau` in Edit mode. Needs ServerStorage.PhotoSet.Builder_Rig
-- (tools/photoset_rig.luau) and the Lighting preset A3 (tools/photoset_lighting.luau) applied first.
--   "build"  (re)builds Workspace.PhotoSet_A3, sets the camera on it (Scriptable) and returns the camera position / look-at
--   "stash"  moves it to ServerStorage.PhotoSet.A3 and resets the camera
--   "shoot"  moves the stashed set back into Workspace and sets its camera again
-- Real pieces only: the stage as built (nothing in it is moved or changed), the pad's reached look as CheckpointClient draws
-- it (Core 7 x 7 neon green with its PointLight at 2, the Beam column 18 studs at transparency 0.8) on copies laid over the
-- pad, the stage's own challenge coin (or an untagged copy, so no coin script sees it), the Phoenix at Lv 19 (Legendary:
-- Lv 20 is real too, but its tier-4 halo is out on the thumbnails, the user 2026-11-14). Coins have no burst when taken
-- (they vanish with a sound), so the coin waits beside the player. Pose and placement are free.
-- Iterating: store this file in ServerStorage.PhotoSet.Builder_A3 and run
-- `return loadstring(game.ServerStorage.PhotoSet.Builder_A3.Value)({ RIG_YAW = 10, ... })`.
local P = ... or {}
local MODE: string = P.MODE or "build"
local STAGE = P.STAGE or "World1.Stage1"
local CHECKPOINT = P.CHECKPOINT or "105"
local COIN_ID = P.COIN_ID or "Stage1_4" -- on the pillar to the pad's side (pad space about {-14.5, 1.8, 0})
-- pad space: origin on the pad's top centre, -Z along the pad's LookVector (the way the course goes on: the camera side)
local RIG_AT = P.RIG_AT or Vector3.new(2.5, 0, -7) -- camera-left of the light column, at the pillar's front edge
local RIG_YAW = P.RIG_YAW or 12 -- 0 faces the camera side
local POSE = P.POSE or "cheer"
local PET_KIND, PET_UID, PET_LEVEL = P.PET_KIND or "Phoenix", P.PET_UID or "1", P.PET_LEVEL or 19 -- uid 1: FlameTail
-- pad space (+X is camera-left), up and off to the side: its own glow (PointLight 2.5, range 10) bleached the player beside it
local PET_AT = P.PET_AT or Vector3.new(6.2, 5.4, -6.5) -- camera-left, clear of the logo (top right)
local PET_YAW = P.PET_YAW or 28 -- 0 faces the camera side
-- "real": frame the stage's own coin where it stands (no copy); a Vector3 (pad space) places an untagged copy there (at
-- checkpoint 105 a copy beside the player also left the real one in view: two coins)
local COIN_AT: any = P.COIN_AT or "real"
local COIN_YAW = P.COIN_YAW or 20 -- a copy's turn; 0: its face toward the camera side
local LIT = if P.LIT == nil then true else P.LIT
local FOV = P.FOV or 60
local CAMERA = P.CAMERA or Vector3.new(-1.5, 7, -20.5) -- pad space: above the next pillars, looking back (draft J)
local LOOK = P.LOOK or Vector3.new(-0.5, 3.2, 8)

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

if MODE == "stash" then
	local set = assert(workspace:FindFirstChild("PhotoSet_A3"), "nothing to stash")
	local old = photoSet():FindFirstChild("A3")
	if old then
		old:Destroy()
	end
	set.Name = "A3"
	set.Parent = photoSet()
	workspace.CurrentCamera.FieldOfView = 70
	workspace.CurrentCamera.CameraType = Enum.CameraType.Fixed
	game:GetService("StarterGui").ShowDevelopmentGui = true
	return "stashed"
elseif MODE == "shoot" then
	local set = assert(photoSet():FindFirstChild("A3"), "no stashed A3")
	set.Name = "PhotoSet_A3"
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
local padModel = assert(stage:FindFirstChild(CHECKPOINT), "no checkpoint " .. CHECKPOINT)
local pad = padModel.C :: BasePart
local O = pad.CFrame * CFrame.new(0, pad.Size.Y / 2, 0) -- -Z = pad LookVector = the camera side

local old = workspace:FindFirstChild("PhotoSet_A3")
if old then
	old:Destroy()
end
local set = Instance.new("Model")
set.Name = "PhotoSet_A3"

-- the reached pad (CheckpointClient.LOOK), on copies just above the Studio pieces (no shared faces)
if LIT then
	local core = padModel.Core:Clone() :: BasePart
	core:ClearAllChildren()
	core.Name = "LitCore"
	core.Size = V(7, core.Size.Y + 0.04, 7)
	core.CFrame = padModel.Core.CFrame + V(0, 0.02, 0)
	core.Material, core.MaterialVariant, core.Color = Enum.Material.Neon, "", Color3.fromRGB(110, 255, 130)
	local light = padModel.Core:FindFirstChildOfClass("PointLight")
	if light then
		local lit = light:Clone()
		lit.Brightness = 2
		lit.Parent = core
	end
	core.Parent = set
	local beam = padModel.Beam:Clone() :: BasePart
	beam:ClearAllChildren()
	beam.Name = "LitBeam"
	local base = padModel.Beam
	local bottom = base.Position - V(0, base.Size.X / 2, 0)
	local height = padModel:GetAttribute("BeamHeight") or 18
	beam.Size = V(height, base.Size.Y, base.Size.Z)
	beam.CFrame = CFrame.new(bottom + V(0, height / 2, 0)) * (base.CFrame - base.Position)
	beam.Transparency = 0.8
	beam.Parent = set
end

-- the player, feet on the pad
local rig = Rig.build()
Rig.pose(rig, Rig.POSES[POSE], O * CFrame.new(RIG_AT + V(0, 3, 0)) * CFrame.Angles(0, math.rad(RIG_YAW), 0), O.Position.Y)
rig.Parent = set

-- the pet, hovering beside the raised hand
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

-- the coin: the stage's own (COIN_AT "real"), or an untagged copy of it at COIN_AT
local source
for _, c in CollectionService:GetTagged("ChallengeCoin") do
	if c:GetAttribute("CoinId") == COIN_ID then
		source = c
	end
end
assert(source, "no coin " .. COIN_ID)
if COIN_AT ~= "real" then
	local coin = source:Clone() :: BasePart
	for _, tag in CollectionService:GetTags(coin) do
		CollectionService:RemoveTag(coin, tag)
	end
	for name in coin:GetAttributes() do
		coin:SetAttribute(name, nil)
	end
	coin.Name = "Coin"
	coin.Anchored, coin.CanCollide, coin.CanTouch, coin.CanQuery = true, false, false, false
	coin.CFrame = O * CFrame.new(COIN_AT) * CFrame.Angles(0, math.rad(COIN_YAW), 0)
	coin.Parent = set
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
local _, size = rig:GetBoundingBox()
local coinAt = O:PointToObjectSpace(source.Position)
return string.format("%s %s, %s %s Lv %d, coin %s (pad space {%.1f, %.1f, %.1f}); rig height %.1f\ncamera {%.2f, %.2f, %.2f} look {%.2f, %.2f, %.2f}",
	STAGE, CHECKPOINT, PET_KIND, PET_UID, PET_LEVEL, COIN_ID, coinAt.X, coinAt.Y, coinAt.Z, size.Y, camPos.X, camPos.Y, camPos.Z,
	look.X, look.Y, look.Z)
