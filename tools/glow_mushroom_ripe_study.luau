-- Historical CG9 study: B was selected and is built as GlowMushroomPlant. For current art use
-- PlantGrowthReview.Open("GlowMushroom", 10); this file preserves the A/B/C comparison only.
-- Glow Mushroom ripe-silhouette study (display-only), run in the Studio playtest Client context.
-- Three alternatives side by side on adjacent field squares, left to right: A giant cap, B trio, C lantern spires.
-- No field requests or saved-state writes. Destroy GlowMushroomStudy to restore camera/HUD.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsClient(), "Studio client only")
local player = game.Players.LocalPlayer
local PlotView = require(player.PlayerScripts:WaitForChild("PlotView"))
local Kit = require(game.ReplicatedStorage.PlantKit)
local GardenConfig = require(game.ReplicatedStorage.GardenConfig)
local CropConfig = require(game.ReplicatedStorage.CropConfig)
local garden = assert(workspace:FindFirstChild("GardenView"), "Wait for GardenView")
assert(not workspace:FindFirstChild("GlowMushroomStudy"), "Destroy previous study first")
local slot = 13
while GardenConfig.PlotCFrame(slot) and garden:FindFirstChild(string.format("Slot_%02d", slot)) do slot += 1 end
assert(GardenConfig.PlotCFrame(slot), "No free study slot")
local V, C = Vector3.new, Color3.fromRGB

local CAP, CAP_TOP, CAP_SHADE = C(74, 62, 150), C(98, 82, 176), C(58, 48, 126)
local STEM, STEM_SHADE = C(176, 208, 206), C(150, 184, 186)
local GLOW = C(110, 230, 220) -- the crop's teal (PlotView CROP_COLORS g)

local root = Instance.new("Folder")
root.Name = "GlowMushroomStudy"
local view = PlotView.new(slot, root)
local cells = table.create(CropConfig.MaxSquares, "#0")
for n = 1, 24 do cells[n] = ".0" end
view:SetState({name = player.DisplayName, incCount = 1, eggs = {},
	field = {crops = table.concat(cells), pets = {"Cat:3:review:11:1:1"}}})
view:SetDetail("full")
while view:Step(os.clock() + 0.006) do task.wait() end

local function build(name, base, fn)
	local model = Instance.new("Model")
	model.Name = name
	model:SetAttribute("StaticRipeStudy", true)
	local function block(n, size, frame, color, role, glow)
		local p = Kit.proxyPart(model, n, size, base * frame, color, "StudsSmall", role)
		if glow then p.Material, p.MaterialVariant = Enum.Material.Neon, "" end
		return p
	end
	-- An octagonal slab: two squares, one turned 45 degrees.
	local function slab(n, at, width, thick, color, role, glow, tilt)
		local f = CFrame.new(at) * (tilt or CFrame.identity)
		block(n .. "a", V(width, thick, width), f, color, role, glow)
		block(n .. "b", V(width, thick, width), f * CFrame.Angles(0, math.pi / 4, 0), color, role, glow)
	end
	-- Stem: three stacked, slightly leaning, tapering blocks from the soil up to `top`.
	local function stem(at, top, width, lean)
		local h = top / 3
		for i = 1, 3 do
			local t = (i - 0.5) / 3
			local w = width * (1.18 - 0.36 * t)
			block("Stem", V(w, h + 0.02, w), CFrame.new(at + V(lean.X * t * t, h * (i - 0.5), lean.Z * t * t)),
				if i == 2 then STEM_SHADE else STEM, "Structure")
		end
		return at + V(lean.X, top, lean.Z)
	end
	-- Domed cap on a stem top: six octagon slabs; glowing gills underneath, glowing spots on the dome.
	local function cap(at, radius, height, spots, bell)
		local widths = if bell then { 0.80, 0.90, 0.88, 0.76, 0.56, 0.30 } else { 0.62, 0.90, 1.00, 0.90, 0.68, 0.38 }
		local t = height / 6
		for i, w in widths do
			slab("Cap" .. i, at + V(0, t * (i - 0.5), 0), radius * 2 * w, t + 0.02, if i >= 5 then CAP_TOP elseif i == 1 then CAP_SHADE else CAP, "Head")
		end
		slab("Gills", at + V(0, -0.04, 0), radius * 2 * 0.62, 0.12, GLOW, "Fruit", true)
		for i = 1, spots do
			local a = i * 2.4 + radius
			local ring = radius * (0.46 + 0.2 * ((i % 2)))
			local y = t * (if ring > radius * 0.6 then 3.9 else 5.1) + 0.04
			block("Spot", V(0.26, 0.12, 0.26) * math.clamp(radius, 0.6, 1.4), CFrame.new(at + V(math.sin(a) * ring, y, math.cos(a) * ring)) * CFrame.Angles(0, a, 0), GLOW, "Fruit", true)
		end
	end
	fn(stem, cap, block, slab)
	model.Parent = root
	return model
end

local bases = { view:SquareCFrame(8), view:SquareCFrame(9), view:SquareCFrame(10) }

-- A: one giant dome cap on a stout stem, ring of four small buttons.
build("A_GiantCap", bases[1], function(stem, cap, block)
	local top = stem(V(0, 0, 0), 2.3, 0.62, V(0.12, 0, -0.06))
	cap(top + V(-0.06, -0.14, 0), 1.65, 1.35, 8, false)
	for i, b in { {1.45, -0.6, 0.62}, {-1.3, 0.9, 0.5}, {0.5, 1.55, 0.42}, {-1.0, -1.35, 0.36} } do
		local at = V(b[1], 0, b[2])
		local t = stem(at, b[3] * 1.2, 0.2, V(0, 0, 0))
		cap(t + V(0, -0.04, 0), b[3] * 0.62, b[3] * 0.5, 2, false)
	end
end)

-- B: three caps at different heights, staggered, like a cluster.
build("B_Trio", bases[2], function(stem, cap)
	local specs = { { V(-0.45, 0, 0.1), 3.0, 0.5, 1.15, 1.0, 6, V(-0.1, 0, 0.05) },
		{ V(0.75, 0, -0.55), 2.0, 0.42, 0.9, 0.8, 5, V(0.18, 0, 0.0) },
		{ V(0.35, 0, 0.95), 1.3, 0.36, 0.72, 0.62, 4, V(0.0, 0, 0.14) } }
	for _, s in specs do
		local top = stem(s[1], s[2], s[3], s[7])
		cap(top + V(0, -0.1, 0), s[4], s[5], s[6], false)
	end
	for _, b in { V(-1.4, 0, -0.9), V(1.55, 0, 0.5) } do
		local t = stem(b, 0.45, 0.14, V(0, 0, 0))
		cap(t + V(0, -0.03, 0), 0.26, 0.24, 1, false)
	end
end)

-- C: three tall slim lanterns, bell caps; the tallest rises above the avatar.
build("C_Lanterns", bases[3], function(stem, cap)
	local specs = { { V(-0.25, 0, 0.1), 5.9, 0.42, 0.82, 1.2, 5, V(0.1, 0, 0.0) },
		{ V(0.8, 0, -0.45), 4.1, 0.36, 0.66, 1.0, 4, V(-0.12, 0, 0.1) },
		{ V(-0.75, 0, -0.95), 3.0, 0.32, 0.56, 0.86, 3, V(0.12, 0, -0.1) } }
	for _, s in specs do
		local top = stem(s[1], s[2], s[3], s[7])
		cap(top + V(0, -0.1, 0), s[4], s[5], s[6], true)
	end
end)

for _, n in { 8, 9, 10 } do view:ShowSelect(n) end

local report = {}
for i, model in root:GetChildren() do
	if model:IsA("Model") then
		local base = bases[i]
		local radius, height = 0, 0
		for _, p in model:GetChildren() do
			local half = p.Size / 2
			for _, x in {-1,1} do for _, y in {-1,1} do for _, z in {-1,1} do
				local c = base:PointToObjectSpace(p.CFrame:PointToWorldSpace(half * V(x, y, z)))
				radius = math.max(radius, V(c.X, 0, c.Z).Magnitude)
				height = math.max(height, c.Y)
			end end end
		end
		report[model.Name] = { parts = #model:GetChildren(), radius = math.round(radius * 100) / 100, height = math.round(height * 100) / 100 }
	end
end

local character = player.Character
if character then
	local old = character.Archivable
	character.Archivable = true
	local avatar = character:Clone()
	character.Archivable = old
	avatar.Name = "ScaleReference"
	for _, child in avatar:GetDescendants() do
		if child:IsA("LuaSourceContainer") then child:Destroy()
		elseif child:IsA("BasePart") then child.Anchored = true; child.CanCollide = false; child.CanTouch = false; child.CanQuery = false end
	end
	avatar:PivotTo(bases[1] * CFrame.new(-3.9, 3, 0.8) * CFrame.Angles(0, math.pi, 0))
	local cf, size = avatar:GetBoundingBox()
	avatar:PivotTo(avatar:GetPivot() + V(0, bases[1].Position.Y - (cf.Position.Y - size.Y / 2), 0))
	avatar.Parent = root
end

local camera = workspace.CurrentCamera
local oldCF, oldType, oldFocus = camera.CFrame, camera.CameraType, camera.Focus
local hidden = {}
for _, gui in player.PlayerGui:GetChildren() do
	if gui:IsA("ScreenGui") and gui.Enabled then hidden[#hidden + 1] = gui; gui.Enabled = false end
end
root.Destroying:Connect(function()
	RunService:UnbindFromRenderStep("GlowMushroomStudyCamera")
	camera.CFrame, camera.CameraType, camera.Focus = oldCF, oldType, oldFocus
	for _, gui in hidden do if gui.Parent then gui.Enabled = true end end
	view:Destroy()
end)
root.Parent = workspace
camera.CameraType = Enum.CameraType.Scriptable
local mid = bases[2]
local target = mid:PointToWorldSpace(V(0, 2.4, 0))
local studyCamera = CFrame.lookAt(mid:PointToWorldSpace(V(0, 7, 17)), target)
camera.CFrame, camera.Focus = studyCamera, CFrame.new(target)
RunService:BindToRenderStep("GlowMushroomStudyCamera", Enum.RenderPriority.Last.Value + 1, function()
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame, camera.Focus = studyCamera, CFrame.new(target)
end)
return game.HttpService:JSONEncode({ report = report, slot = slot, p8 = tostring(bases[1].Position), p9 = tostring(bases[2].Position), p10 = tostring(bases[3].Position) })
