-- Historical CG9 study: option 3 (chestnut pair) was selected and is built as GlowMushroomPlant. For current art use
-- PlantGrowthReview.Open("GlowMushroom", 10); this file preserves the three bolete options only.
-- Glow Mushroom bolete study (display-only), run in the Studio playtest Client context.
-- Three ripe options side by side on adjacent field squares, left to right:
--   1 chestnut trio, 2 indigo trio, 3 chestnut pair + buttons (the porcini photo's composition).
-- Bolete cues: barrel stem wide at the base, thick convex cushion cap with a pale rim line, a pale pore layer (not gills)
-- under the cap that glows teal, no gills or spots. No field requests or saved-state writes.
-- Destroy GlowBoleteStudy to restore camera/HUD.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsClient(), "Studio client only")
local player = game.Players.LocalPlayer
local PlotView = require(player.PlayerScripts:WaitForChild("PlotView"))
local Kit = require(game.ReplicatedStorage.PlantKit)
local GardenConfig = require(game.ReplicatedStorage.GardenConfig)
local CropConfig = require(game.ReplicatedStorage.CropConfig)
local garden = assert(workspace:FindFirstChild("GardenView"), "Wait for GardenView")
assert(not workspace:FindFirstChild("GlowBoleteStudy"), "Destroy previous study first")
local slot = 13
while GardenConfig.PlotCFrame(slot) and garden:FindFirstChild(string.format("Slot_%02d", slot)) do slot += 1 end
assert(GardenConfig.PlotCFrame(slot), "No free study slot")
local V, C = Vector3.new, Color3.fromRGB

local CHESTNUT = { C(98, 54, 32), C(114, 64, 38), C(128, 74, 42), C(142, 84, 48), C(154, 96, 56), C(166, 108, 64) } -- cap layers, bottom to top
local INDIGO = { C(58, 48, 126), C(66, 56, 138), C(74, 62, 150), C(86, 72, 164), C(98, 82, 176), C(108, 92, 186) }
local RIM = C(226, 214, 190)
local STEM, STEM_SHADE = C(208, 202, 186), C(184, 178, 160)
local PORE = C(96, 214, 204)

local root = Instance.new("Folder")
root.Name = "GlowBoleteStudy"
local view = PlotView.new(slot, root)
local cells = table.create(CropConfig.MaxSquares, "#0")
for n = 1, 24 do cells[n] = ".0" end
view:SetState({name = player.DisplayName, incCount = 1, eggs = {}, field = {crops = table.concat(cells), pets = {"Cat:3:review:11:1:1"}}})
view:SetDetail("full")
while view:Step(os.clock() + 0.006) do task.wait() end

local built = {}
local function build(name, base, palette, specs, buttons)
	local model = Instance.new("Model")
	model.Name = name
	model:SetAttribute("StaticRipeStudy", true)
	local function block(n, size, frame, color, glow)
		local p = Kit.proxyPart(model, n, size, base * frame, color, "StudsSmall", "Fruit")
		if glow then p.Material, p.MaterialVariant = Enum.Material.Neon, "" end
		return p
	end
	local function oct(n, at, width, thick, color, glow)
		block(n .. "a", V(width, thick, width), CFrame.new(at), color, glow)
		block(n .. "b", V(width, thick, width), CFrame.new(at) * CFrame.Angles(0, math.pi / 4, 0), color, glow)
	end
	local function mushroom(s)
		-- Barrel stem: widest in the lower third, narrowing towards the cap (octagons below, squares above).
		local profile = { 0.92, 1.10, 1.04, 0.88, 0.70 }
		local h = s.H / 5
		for i, k in profile do
			local w = s.W * k
			local at = s.pos + V(s.lean.X * (i / 5) ^ 2, h * (i - 0.5), s.lean.Z * (i / 5) ^ 2)
			local color = if i % 2 == 0 then STEM_SHADE else STEM
			oct("Stem" .. i, at, w, h + 0.02, color)
		end
		local top = s.pos + s.lean + V(0, s.H, 0)
		-- Pore layer: thick, pale, glowing, just under the cap and wider than the stem.
		local cap = CFrame.new(top + V(0, -0.1, 0)) * CFrame.Angles(s.tilt.X, s.yaw, s.tilt.Z)
		local d = 2 * s.R
		oct("Pores", cap.Position + (cap.Rotation * V(0, -0.1, 0)), d * 0.84, 0.20, PORE, true)
		-- Cap: thin pale rim, then five brown layers (convex cushion), tilted slightly.
		local t = s.T / 6
		local rim = cap * CFrame.new(0, 0.03, 0)
		block("RimA", V(d * 0.90, 0.07, d * 0.90), rim, RIM)
		block("RimB", V(d * 0.90, 0.07, d * 0.90), rim * CFrame.Angles(0, math.pi / 4, 0), RIM)
		local widths = { 0.84, 0.98, 1.00, 0.92, 0.72, 0.42 }
		for i, w in widths do
			local f = cap * CFrame.new(0, 0.07 + t * (i - 0.5) * 1.1, 0)
			block("Cap" .. i .. "a", V(d * w, t * 1.1 + 0.02, d * w), f, palette[i])
			if i <= 5 then block("Cap" .. i .. "b", V(d * w, t * 1.1 + 0.02, d * w), f * CFrame.Angles(0, math.pi / 4, 0), palette[i]) end
		end
	end
	for _, s in specs do mushroom(s) end
	for _, b in buttons do
		-- Button: a squat stem and a small glowing-pored cap.
		block("BStem", V(b.W, b.H, b.W), CFrame.new(b.pos + V(0, b.H / 2, 0)), STEM)
		oct("BPore", b.pos + V(0, b.H - 0.02, 0), b.R * 1.7, 0.1, PORE, true)
		oct("BCap", b.pos + V(0, b.H + b.R * 0.35, 0), b.R * 2.0, b.R * 0.7, palette[4])
	end
	model.Parent = root
	built[name] = { model = model, base = base }
end

local bases = { view:SquareCFrame(8), view:SquareCFrame(9), view:SquareCFrame(10) }
local function trio()
	return {
		{ pos = V(-0.45, 0, 0.10), H = 3.0, W = 0.85, R = 1.10, T = 1.00, lean = V(-0.08, 0, 0.04), tilt = V(0.04, 0, -0.03), yaw = 0.3, flecks = 4 },
		{ pos = V(0.75, 0, -0.55), H = 1.9, W = 0.70, R = 0.90, T = 0.80, lean = V(0.12, 0, 0), tilt = V(-0.03, 0, 0.04), yaw = 1.1, flecks = 3 },
		{ pos = V(0.35, 0, 0.95), H = 1.1, W = 0.60, R = 0.72, T = 0.62, lean = V(0, 0, 0.08), tilt = V(0.03, 0, 0.02), yaw = 2.0, flecks = 2 },
	}
end
local trioButtons = {
	{ pos = V(-1.35, 0, -0.85), H = 0.35, W = 0.26, R = 0.28 },
	{ pos = V(1.55, 0, 0.45), H = 0.3, W = 0.22, R = 0.24 },
}
build("1_ChestnutTrio", bases[1], CHESTNUT, trio(), trioButtons)
build("2_IndigoTrio", bases[2], INDIGO, trio(), trioButtons)
build("3_ChestnutPair", bases[3], CHESTNUT, {
	{ pos = V(-0.35, 0, 0.15), H = 3.0, W = 1.00, R = 1.30, T = 1.20, lean = V(-0.06, 0, 0.04), tilt = V(0.05, 0, -0.04), yaw = 0.3, flecks = 4 },
	{ pos = V(0.95, 0, -0.60), H = 1.9, W = 0.75, R = 0.85, T = 0.75, lean = V(0.1, 0, 0), tilt = V(-0.03, 0, 0.05), yaw = 1.1, flecks = 3 },
}, {
	{ pos = V(-1.1, 0, -1.2), H = 0.35, W = 0.26, R = 0.28 },
	{ pos = V(1.2, 0, 1.05), H = 0.3, W = 0.22, R = 0.24 },
})

for _, n in { 8, 9, 10 } do view:ShowSelect(n) end

local report = {}
for name, b in built do
	local radius, height = 0, 0
	for _, p in b.model:GetChildren() do
		local half = p.Size / 2
		for _, x in {-1,1} do for _, y in {-1,1} do for _, z in {-1,1} do
			local c = b.base:PointToObjectSpace(p.CFrame:PointToWorldSpace(half * V(x, y, z)))
			radius = math.max(radius, V(c.X, 0, c.Z).Magnitude)
			height = math.max(height, c.Y)
		end end end
	end
	report[name] = { parts = #b.model:GetChildren(), radius = math.round(radius * 100) / 100, height = math.round(height * 100) / 100 }
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
	RunService:UnbindFromRenderStep("GlowBoleteStudyCamera")
	camera.CFrame, camera.CameraType, camera.Focus = oldCF, oldType, oldFocus
	for _, gui in hidden do if gui.Parent then gui.Enabled = true end end
	view:Destroy()
end)
root.Parent = workspace
camera.CameraType = Enum.CameraType.Scriptable
local mid = bases[2]
local target = mid:PointToWorldSpace(V(0, 2.2, 0))
local studyCamera = CFrame.lookAt(mid:PointToWorldSpace(V(0, 6.5, 17)), target)
camera.CFrame, camera.Focus = studyCamera, CFrame.new(target)
RunService:BindToRenderStep("GlowBoleteStudyCamera", Enum.RenderPriority.Last.Value + 1, function()
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame, camera.Focus = studyCamera, CFrame.new(target)
end)
return game.HttpService:JSONEncode({ report = report, slot = slot })
