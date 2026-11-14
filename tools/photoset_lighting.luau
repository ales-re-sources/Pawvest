-- Photo-set Lighting helper for the store thumbnails (docs/THUMBNAILS.md §7). Run through the Studio MCP `execute_luau`
-- in Edit mode: paste the file as `code` with MODE (and PRESET) set, or store it in the StringValue
-- ServerStorage.PhotoSet.Builder_Lighting and run it through loadstring with { MODE = ..., PRESET = ... }.
--   "snapshot"  saves Lighting's properties and clones of its children to ServerStorage.PhotoSet.LightingSnapshot.
--               Refuses if a snapshot already exists (restore first), so a second shoot never overwrites the real look.
--   "apply"     applies PRESETS[PRESET] (C1, A3, B1) on top of the current look (needs a snapshot).
--   "restore"   puts the saved properties and children back and removes the snapshot.
--   "status"    says whether a snapshot is waiting and lists Lighting's children.
-- No game code references Lighting or its children (grep src), so restoring by clones is safe.
local P = ... or {} -- from loadstring(ServerStorage.PhotoSet.Builder_Lighting.Value)({ MODE = ..., PRESET = ... })
local MODE: string = P.MODE or "status"
local PRESET: string = P.PRESET or "C1"

local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")

local PROPS = {
	"Ambient", "Brightness", "ColorShift_Bottom", "ColorShift_Top", "EnvironmentDiffuseScale", "EnvironmentSpecularScale",
	"GlobalShadows", "OutdoorAmbient", "ShadowSoftness", "ClockTime", "GeographicLatitude", "ExposureCompensation",
	"FogColor", "FogEnd", "FogStart",
}

-- A preset: Lighting properties, plus per-child-class property tables (the child is created if missing and marked so
-- restore removes it anyway). `disable` turns off the named effects.
local PRESETS = {
	-- C1 / Icon: bright morning, the sun in the east behind a camera that looks west across slot 1's field at the barn;
	-- saturated, soft warm key; a light depth of field keeps the ripe field behind the pet from competing with it.
	C1 = {
		lighting = { ClockTime = 9.2, Brightness = 3, ExposureCompensation = 0.15, ShadowSoftness = 0.35,
			OutdoorAmbient = Color3.fromRGB(150, 150, 160), Ambient = Color3.fromRGB(90, 90, 100) },
		children = {
			ColorCorrectionEffect = { Saturation = 0.22, Contrast = 0.08, Brightness = 0.02, TintColor = Color3.fromRGB(255, 248, 235) },
			BloomEffect = { Intensity = 0.6, Size = 28, Threshold = 1.6 },
			Atmosphere = { Density = 0.22, Haze = 0.4, Glare = 0, Offset = 0.1 },
			DepthOfFieldEffect = { FarIntensity = 0.3, FocusDistance = 11, InFocusRadius = 6, NearIntensity = 0 },
		},
		disable = { "SunRaysEffect" },
	},
	-- A3: bright late morning in World 1 (Stage 1's Island Hop, the camera looks back along the pillar chain), saturated,
	-- extra contrast so the white stud pillars part at tile size; no depth of field (it does not render in Edit grabs).
	A3 = {
		lighting = { ClockTime = 10.2, Brightness = 2.2, ExposureCompensation = -0.15, ShadowSoftness = 0.3, -- brighter washed the rig
			OutdoorAmbient = Color3.fromRGB(150, 150, 160), Ambient = Color3.fromRGB(90, 90, 100) },
		children = {
			ColorCorrectionEffect = { Saturation = 0.32, Contrast = 0.18, Brightness = 0.02, TintColor = Color3.fromRGB(255, 250, 240) },
			BloomEffect = { Intensity = 0.6, Size = 28, Threshold = 1.6 },
			Atmosphere = { Density = 0.2, Haze = 0.3, Glare = 0, Offset = 0.1 },
		},
		disable = { "SunRaysEffect", "DepthOfFieldEffect" },
	},
	-- B1: late afternoon, a low warm sun behind the camera (photoset_b1 picks the plot on the sun's side), long shadows across
	-- the field; warmer tint than C1, the reach tint's neon still reads.
	B1 = {
		lighting = { ClockTime = 17.4, Brightness = 3, ExposureCompensation = 0.2, ShadowSoftness = 0.3,
			ColorShift_Top = Color3.fromRGB(255, 214, 165), -- warmer made the brown Owl as orange as the Pumpkin
			OutdoorAmbient = Color3.fromRGB(150, 135, 130), Ambient = Color3.fromRGB(95, 85, 85) },
		children = {
			ColorCorrectionEffect = { Saturation = 0.25, Contrast = 0.08, Brightness = 0.02, TintColor = Color3.fromRGB(255, 236, 215) },
			BloomEffect = { Intensity = 0.6, Size = 28, Threshold = 1.5 },
			Atmosphere = { Density = 0.3, Haze = 1.2, Glare = 0.2, Offset = 0.1, Color = Color3.fromRGB(255, 205, 160),
				Decay = Color3.fromRGB(150, 110, 90) },
			DepthOfFieldEffect = { FarIntensity = 0.25, FocusDistance = 12, InFocusRadius = 7, NearIntensity = 0 },
		},
		disable = { "SunRaysEffect" },
	},
}

local function photoSet(): Folder
	local folder = ServerStorage:FindFirstChild("PhotoSet")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "PhotoSet"
		folder.Parent = ServerStorage
	end
	return folder
end

local function children(): string
	local list = {}
	for _, child in Lighting:GetChildren() do
		table.insert(list, child.ClassName .. ":" .. child.Name .. (if child:IsA("PostEffect") and not child.Enabled then "(off)" else ""))
	end
	return table.concat(list, ", ")
end

local snapshot = photoSet():FindFirstChild("LightingSnapshot")

if MODE == "status" then
	return (if snapshot then "SNAPSHOT WAITING (restore after the shoot). " else "no snapshot. ")
		.. "ClockTime=" .. Lighting.ClockTime .. "; children: " .. children()
elseif MODE == "snapshot" then
	assert(not snapshot, "a snapshot already exists: restore it first")
	snapshot = Instance.new("Folder")
	snapshot.Name = "LightingSnapshot"
	for _, name in PROPS do
		snapshot:SetAttribute(name, (Lighting :: any)[name])
	end
	for _, child in Lighting:GetChildren() do
		local copy = child:Clone()
		if copy then
			copy.Parent = snapshot
		end
	end
	snapshot.Parent = photoSet()
	return "saved " .. #PROPS .. " properties and " .. #snapshot:GetChildren() .. " children: " .. children()
elseif MODE == "apply" then
	assert(snapshot, "take a snapshot first")
	local preset = assert(PRESETS[PRESET], "unknown preset " .. PRESET)
	for name, value in preset.lighting do
		(Lighting :: any)[name] = value
	end
	for class, props in preset.children do
		local child = Lighting:FindFirstChildOfClass(class)
		if not child then
			child = Instance.new(class)
			child.Name = "PhotoSet_" .. class
			child.Parent = Lighting
		end
		for name, value in props do
			(child :: any)[name] = value
		end
		if child:IsA("PostEffect") then
			child.Enabled = true
		end
	end
	for _, class in preset.disable or {} do
		for _, child in Lighting:GetChildren() do
			if child.ClassName == class and child:IsA("PostEffect") then
				child.Enabled = false
			end
		end
	end
	return "applied " .. PRESET .. "; children: " .. children()
elseif MODE == "restore" then
	assert(snapshot, "no snapshot to restore")
	for _, name in PROPS do
		(Lighting :: any)[name] = snapshot:GetAttribute(name)
	end
	for _, child in Lighting:GetChildren() do
		child:Destroy()
	end
	for _, saved in snapshot:GetChildren() do
		saved:Clone().Parent = Lighting
	end
	snapshot:Destroy()
	return "restored; ClockTime=" .. Lighting.ClockTime .. "; children: " .. children()
end
error("unknown MODE " .. MODE)
