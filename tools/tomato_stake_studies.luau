-- Studio playtest, Client command context only. Static art studies for the staked tomato (6-stud rigid stake).
-- Builds a review plot (slot 13) with Pawvest's own PlotView; A, B, C stand on squares 9, 10, 11 (left to right
-- seen from local +Z, which is the side away from the barn). No garden requests or profile changes.
-- Put the avatar on the same ground plane for scale (R15 is ~5.46 studs) and bind a Scriptable camera in a
-- RenderStep after Camera priority: the default camera script resets CameraType.
-- Remove workspace.TomatoStakeStudies and unbind the camera ("StakeStudyCam") after review.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsClient(), "Run in the Studio playtest client")
local player = game:GetService("Players").LocalPlayer
local PlotView = require(player.PlayerScripts:WaitForChild("PlotView"))
local CropConfig = require(game.ReplicatedStorage.CropConfig)
assert(not workspace:FindFirstChild("TomatoStakeStudies"), "Remove the previous review folder before rerunning")

local V = Vector3.new
local STEM = Color3.fromRGB(59, 119, 64)
local DARK = Color3.fromRGB(41, 126, 66)
local LIT = Color3.fromRGB(83, 161, 74)
local NEW = Color3.fromRGB(143, 187, 75)
local RED = Color3.fromRGB(219, 52, 43)
local RIPE = Color3.fromRGB(192, 42, 38)
local WOOD = Color3.fromRGB(150, 112, 72)
local TWINE = Color3.fromRGB(214, 190, 140)
local SZ, R = -0.22, 0.26 -- stake axis (local z) and stem radius around it

local function block(model, name, size, cf, color, variant)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Material, p.MaterialVariant = Enum.Material.Plastic, variant or "StudsSmall"
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.Parent = model
end
local function axis(a, b)
	local d = (b - a).Unit
	local up = if math.abs(d.Y) > 0.98 then Vector3.xAxis else Vector3.yAxis
	return CFrame.lookAt((a + b) / 2, a, up)
end
local function twig(model, base, a, b, width, color)
	block(model, "Stem", V(width, width, (b - a).Magnitude), base * axis(a, b), color or STEM, "StudsSmall")
end
local function leaf(model, base, at, offset, width, color)
	local length = offset.Magnitude
	local cf = base * axis(at, at + offset)
	block(model, "Leaf", V(width, 0.14, length * 0.72), cf * CFrame.new(0, 0, -length * 0.14), color, "Studs")
	block(model, "LeafTip", V(width * 0.56, 0.13, length * 0.28), cf * CFrame.new(0, 0, length * 0.36), color, "StudsSmall")
end
-- Compound leaf: blade plus two side leaflets (4 Parts).
local function frond(model, base, at, yawDeg, L, droop, w, color)
	local y = math.rad(yawDeg)
	local d = V(math.sin(y), droop, math.cos(y)).Unit * L
	leaf(model, base, at, d, w, color)
	local side = Vector3.yAxis:Cross(d).Unit
	local j = at + d * 0.38
	for s = -1, 1, 2 do
		local off = d * 0.45 + side * (s * L * 0.42) + V(0, 0.06, 0)
		block(model, "Leaflet", V(w * 0.7, 0.13, off.Magnitude), base * axis(j, j + off), LIT, "StudsSmall")
	end
end
-- Full fruit 4 Parts, `lite` (cherry) 2 Parts; the sepal is one rotated plate.
local function tomato(model, base, at, size, color, lite)
	local top = base * CFrame.new(at)
	block(model, "Sepal", V(size * 0.6, 0.09, size * 0.6), top * CFrame.Angles(0, math.rad(45), 0), DARK, "StudsSmall")
	if lite then
		block(model, "Tomato", V(size, size * 0.9, size * 0.9), top * CFrame.new(0, -size * 0.47, 0), color, "StudsSmall")
		return
	end
	block(model, "Shoulder", V(size * 0.74, size * 0.17, size * 0.70), top * CFrame.new(0, -size * 0.085, 0), color, "StudsSmall")
	block(model, "Tomato", V(size, size * 0.6, size * 0.8), top * CFrame.new(0, -size * 0.47, 0), color, "StudsSmall")
	block(model, "Base", V(size * 0.72, size * 0.16, size * 0.64), top * CFrame.new(0, -size * 0.84, 0), color, "StudsSmall")
end
-- fruits: {t along the rachis, size, drop of the pedicel}
local function truss(model, base, at, yawDeg, out, rise, fruits, lite)
	local y = math.rad(yawDeg)
	local tip = at + V(math.sin(y), 0, math.cos(y)) * out + V(0, rise, 0)
	twig(model, base, at, tip, 0.11)
	for i, f in fruits do
		local p = at:Lerp(tip, f[1])
		local hang = p - V(0, f[3], 0)
		twig(model, base, p, hang, 0.07)
		tomato(model, base, hang, f[2], if i % 2 == 1 then RED else RIPE, lite)
	end
end
-- az(h): azimuth of the stem around the stake axis (0 = toward the camera).
local function pt(h, az)
	local a = az(h)
	return V(R * math.sin(a), h, SZ + R * math.cos(a))
end
local function leader(model, base, heights, az)
	for i = 1, #heights - 1 do
		local w = 0.24 - 0.11 * (i - 1) / (#heights - 2)
		twig(model, base, pt(heights[i], az), pt(heights[i + 1], az), w)
	end
end
local function tie(model, base, h, az)
	local p, s = pt(h, az), V(0, h, SZ)
	block(model, "Tie", V(0.42, 0.10, 0.62), base * CFrame.new((p + s) / 2) * CFrame.Angles(0, az(h), 0), TWINE, "StudsSmall")
end
local function stake(model, base)
	block(model, "Stake", V(0.22, 6, 0.22), base * CFrame.new(0, 3, SZ), WOOD, "Studs")
end

local studies = {}
-- A: classic single leader woven across the stake, three trusses of two big fruit.
studies[1] = {"A_Classic", function(model, base)
	local az = function(h) return math.rad(55) * math.sin(h * 1.1) end
	stake(model, base)
	leader(model, base, {0, 0.9, 1.8, 2.7, 3.6, 4.5, 5.5}, az)
	for _, h in {1.2, 2.9, 4.5} do tie(model, base, h, az) end
	for _, f in {{0.6, 100, 1.3, -0.2, LIT}, {1.75, -110, 1.6, -0.25, DARK}, {2.4, 75, 1.5, -0.25, LIT}, {3.5, -95, 1.5, -0.2, DARK}, {4.0, 120, 1.3, -0.15, LIT}, {5.0, 70, 1.2, 0.0, NEW}, {5.5, -60, 1.0, 0.15, NEW}} do
		frond(model, base, pt(f[1], az), f[2], f[3], f[4], 0.78, f[5])
	end
	truss(model, base, pt(1.15, az), 35, 1.2, 0.15, {{0.5, 0.85, 0.28}, {1.0, 0.9, 0.5}})
	truss(model, base, pt(2.95, az), -40, 1.15, 0.15, {{0.5, 0.8, 0.3}, {1.0, 0.85, 0.55}})
	truss(model, base, pt(4.4, az), 50, 1.0, 0.12, {{0.5, 0.7, 0.25}, {1.0, 0.75, 0.45}})
end}
-- B: two floors - a spreading lower tier on two suckers, a bare tied stem, a leafy upper crown with one truss of three.
studies[2] = {"B_TwoFloors", function(model, base)
	local az = function(h) return math.rad(40) * math.sin(h * 0.9) end
	stake(model, base)
	leader(model, base, {0, 1.0, 2.0, 3.0, 4.0, 5.5}, az)
	for _, h in {0.4, 2.4, 3.3} do tie(model, base, h, az) end
	for _, s in {{0.7, V(-0.8, 0.4, 0.35), V(-0.6, 0.6, 0.2), -75, -40, LIT, {{0.5, 0.85, 0.28}, {1.0, 0.9, 0.5}}},
		{1.1, V(0.85, 0.35, 0.25), V(0.55, 0.65, -0.1), 70, 50, DARK, {{0.5, 0.82, 0.3}, {1.0, 0.86, 0.52}}}} do
		local root = pt(s[1], az)
		local elbow = root + s[2]
		local tip = elbow + s[3]
		twig(model, base, root, elbow, 0.15)
		twig(model, base, elbow, tip, 0.13)
		truss(model, base, elbow, s[4], 0.9, 0.1, s[7])
		frond(model, base, tip, s[5], 1.3, -0.15, 0.78, s[6])
	end
	truss(model, base, pt(3.8, az), 20, 1.1, 0.12, {{0.4, 0.75, 0.25}, {0.7, 0.8, 0.5}, {1.0, 0.75, 0.3}})
	for _, f in {{4.2, -100, 1.5, -0.2, DARK}, {4.7, 110, 1.4, -0.15, LIT}, {5.1, -50, 1.2, 0.0, LIT}, {5.5, 40, 1.0, 0.15, NEW}} do
		frond(model, base, pt(f[1], az), f[2], f[3], f[4], 0.78, f[5])
	end
end}
-- C: tight spiral around the stake, small leaves, four cascades of three cherry fruit.
studies[3] = {"C_CherrySpiral", function(model, base)
	local az = function(h) return h * 0.55 * math.pi * 2 end
	stake(model, base)
	leader(model, base, {0, 0.75, 1.5, 2.25, 3.0, 3.75, 4.5, 5.25, 5.7}, az)
	for _, h in {1.0, 2.6, 4.2} do tie(model, base, h, az) end
	for _, f in {{0.5, 80, 1.1, -0.2, LIT}, {1.7, -100, 1.15, -0.2, DARK}, {2.0, 140, 1.1, -0.15, LIT}, {3.0, -70, 1.15, -0.15, DARK}, {3.9, 100, 1.1, -0.15, LIT}, {4.8, -120, 1.0, 0.0, DARK}, {5.7, 30, 0.9, 0.15, NEW}} do
		frond(model, base, pt(f[1], az), f[2], f[3], f[4], 0.55, f[5])
	end
	for _, f in {{1.2, 20}, {2.4, -60}, {3.5, 60}, {4.55, -25}} do
		truss(model, base, pt(f[1], az), f[2], 0.9, 0.2, {{0.4, 0.55, 0.3}, {0.7, 0.55, 0.55}, {1.0, 0.55, 0.8}}, true)
	end
end}

local folder = Instance.new("Folder")
folder.Name = "TomatoStakeStudies"
local slot = 13
assert(not workspace.GardenView:FindFirstChild(string.format("Slot_%02d", slot)), "Review slot 13 is in use")
local view = PlotView.new(slot, folder)
local cells = table.create(CropConfig.MaxSquares, "#0")
for i = 1, 12 do cells[i] = ".0" end
view:SetState({name = player.DisplayName, incCount = 1, eggs = {}, field = {crops = table.concat(cells), pets = {}}})
view:SetDetail("full")
while view:Step(os.clock() + 0.006) do task.wait() end
local counts = {}
for i, study in studies do
	local model = Instance.new("Model")
	model.Name = study[1]
	study[2](model, view:SquareCFrame(8 + i))
	counts[model.Name] = #model:GetChildren()
	model.Parent = folder
end
folder.Parent = workspace
return game:GetService("HttpService"):JSONEncode(counts)
