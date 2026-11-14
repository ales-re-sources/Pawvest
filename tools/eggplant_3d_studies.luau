-- CG16e: around-the-stem layout studies for the ripe eggplant, Studio Edit context. No scripts, remotes or profile writes.
-- Each variant swaps only the recipe's LAYOUT block (arms, leaves, fruit, top flower azimuths); every other line is the
-- registered recipe. Builds seed 1 at standard size, seen from 0° / 45° / 90° yaw, with soil squares and an R15 rig.
-- Base source: ReplicatedStorage.EggStudyTmp.EggBase when present (a draft pasted before Argon syncs it), else
-- ReplicatedStorage.EggplantPlant. Capture, then destroy workspace.Eggplant3DStudies and ReplicatedStorage.EggStudyTmp.
assert(game:GetService("RunService"):IsStudio(), "Studio only")
local RS = game:GetService("ReplicatedStorage")
local old = workspace:FindFirstChild("Eggplant3DStudies")
if old then old:Destroy() end
local tmp = RS:FindFirstChild("EggStudyTmp") or Instance.new("Folder")
tmp.Name = "EggStudyTmp"
if not tmp:FindFirstChild("PlantKit") then RS.PlantKit:Clone().Parent = tmp end
tmp.Parent = RS
local baseSource = (tmp:FindFirstChild("EggBase") or RS.EggplantPlant).Source
local head = baseSource:find("-- LAYOUT BEGIN", 1, true)
local tail = select(2, baseSource:find("-- LAYOUT END", 1, true))
assert(head and tail, "Recipe has no LAYOUT block")

local LEADER = [[
seg(0,V(0.06,1.35,-0.08),0,0.24,0.19)
seg(1,V(-0.06,1.20,-0.04),0.12,0.38,0.173)
seg(2,V(-0.20,0.97,-0.04),0.25,0.48,0.156)
seg(3,V(0.22,0.87,0.06),0.35,0.58,0.139)
]]
local VARIANTS = {
	-- A: fruit pair in a front V plus the short fruit behind; leaves fan round the sides and back.
	{ name = "A_ThreeWay", layout = LEADER .. [[
seg(2,P(0.90,-55,0.55),0.28,0.47,0.15)
seg(5,P(0.32,-55,0.50),0.38,0.59,0.1365)
seg(3,P(1.00,65,0.20),0.33,0.53,0.14)
seg(7,P(0.30,65,0.35),0.42,0.63,0.1274)
leaf(1,0.50,125,0.40,1.33,0.94,-0.05,0.10,0.40,0.45)
leaf(2,0.46,-120,0.25,1.18,0.90,-0.08,0.24,0.52,-0.45)
leaf(5,0.30,-125,0.26,1.05,0.87,0.10,0.33,0.61,0.45)
leaf(4,0.11,180,0.05,0.87,0.76,0.0,0.40,0.66,0.3)
leaf(7,0.30,10,0.26,1.05,0.84,0.10,0.38,0.65,-0.45)
fruitAt(5,0.30,-40,-0.20,1.88,0.69,0.14,0)
fruitAt(7,0.30,60,-0.25,1.79,0.73,0.13,0.012)
fruitAt(2,0.70,185,0.13,1.16,0.53,0.08,0.025)
local FLOWER = P(0.43,65,0.18)
]] },
	-- B: leaves climb the leader in a 137.5° spiral; arms 140° apart, fruit about 120° apart.
	{ name = "B_Spiral", layout = LEADER .. [[
seg(2,P(0.90,-100,0.55),0.28,0.47,0.15)
seg(5,P(0.32,-100,0.50),0.38,0.59,0.1365)
seg(3,P(1.00,25,0.20),0.33,0.53,0.14)
seg(7,P(0.30,25,0.35),0.42,0.63,0.1274)
leaf(1,0.50,80,0.40,1.33,0.94,-0.05,0.10,0.40,0.45)
leaf(2,0.46,-160,0.25,1.18,0.90,-0.08,0.24,0.52,-0.45)
leaf(5,0.30,-30,0.26,1.05,0.87,0.10,0.33,0.61,0.45)
leaf(4,0.11,150,0.05,0.87,0.76,0.0,0.40,0.66,0.3)
leaf(7,0.30,100,0.26,1.05,0.84,0.10,0.38,0.65,-0.45)
fruitAt(5,0.30,-110,-0.20,1.88,0.69,0.14,0)
fruitAt(7,0.30,35,-0.25,1.79,0.73,0.13,0.012)
fruitAt(2,0.70,145,0.13,1.16,0.53,0.08,0.025)
local FLOWER = P(0.43,25,0.18)
]] },
	-- C: the selected B's left/right fork kept, with depth fore and aft: one long fruit forward, one back, leaves front/back.
	{ name = "C_CrossFork", layout = LEADER .. [[
seg(2,P(0.90,-90,0.55),0.28,0.47,0.15)
seg(5,P(0.32,-90,0.50),0.38,0.59,0.1365)
seg(3,P(1.00,90,0.20),0.33,0.53,0.14)
seg(7,P(0.30,90,0.35),0.42,0.63,0.1274)
leaf(1,0.50,180,0.40,1.33,0.94,0.12,0.10,0.40,0.45)
leaf(2,0.46,10,0.25,1.18,0.90,-0.08,0.24,0.52,-0.45)
leaf(5,0.30,-160,0.26,1.05,0.87,0.15,0.33,0.61,0.45)
leaf(4,0.11,-40,0.05,0.87,0.76,0.0,0.40,0.66,0.3)
leaf(7,0.30,15,0.26,1.05,0.84,0.25,0.38,0.65,-0.45)
fruitAt(5,0.35,-30,-0.20,1.88,0.69,0.14,0)
fruitAt(7,0.35,150,-0.25,1.79,0.73,0.13,0.012)
fruitAt(2,0.70,-150,0.13,1.16,0.53,0.08,0.025)
local FLOWER = P(0.43,90,0.18)
]] },
}
local ONLY = nil -- e.g. { "A_ThreeWay" }
local YAWS = { 0, 45, 90 }
local V, C = Vector3.new, Color3.fromRGB
local function slab(parent, name, size, cf, color)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Material, p.MaterialVariant = Enum.Material.Plastic, "Studs"
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.Parent = parent
end
local folder = Instance.new("Folder")
folder.Name = "Eggplant3DStudies"
local Y0, Z0 = 500, 200
local report = {}
for v, variant in VARIANTS do
	if ONLY and not table.find(ONLY, variant.name) then continue end
	local module = tmp:FindFirstChild(variant.name)
	if module then module:Destroy() end
	module = Instance.new("ModuleScript")
	module.Name = variant.name
	module.Source = baseSource:sub(1, head - 1) .. "-- LAYOUT BEGIN\n" .. variant.layout .. "-- LAYOUT END" .. baseSource:sub(tail + 1)
	module.Parent = tmp
	local Recipe = require(module)
	local row = Instance.new("Model")
	row.Name = variant.name
	local z = Z0 + (v - 1) * 40
	slab(row, "Grass", V(30, 0.5, 14), CFrame.new(0, Y0 - 0.45, z), C(103, 149, 75))
	local stats = { name = variant.name }
	for i, yaw in YAWS do
		local soil = CFrame.new((i - 2) * 7, Y0, z)
		slab(row, "Soil" .. yaw, V(5.5, 0.30, 5.5), soil * CFrame.new(0, -0.15, 0), C(88, 66, 48))
		-- Turning the plant by -yaw shows it as a camera at +yaw round the plant would see it.
		local plant = Recipe.new(row, soil * CFrame.Angles(0, -math.rad(yaw), 0), 1, 1)
		plant:SetGrowth(1)
		plant.model.Name = "Yaw" .. yaw
		if i == 1 then
			local radius, top, bottom = 0, 0, math.huge
			for _, p in plant.model:GetChildren() do
				if not p:IsA("BasePart") or p.Transparency >= 0.99 then continue end
				for x = -1, 1, 2 do for y = -1, 1, 2 do for zz = -1, 1, 2 do
					local a = soil:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size * V(x, y, zz) / 2))
					radius, top = math.max(radius, V(a.X, 0, a.Z).Magnitude), math.max(top, a.Y)
					if p:GetAttribute("PlantRole") == "Fruit" then bottom = math.min(bottom, a.Y) end
				end end end
			end
			stats.radius, stats.top, stats.fruitClearance = radius, top, bottom
			stats.parts = #plant.model:GetChildren()
		end
	end
	local ok, avatar = pcall(function()
		return game.Players:CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
	end)
	if ok then
		avatar.Name = "ReferenceAvatar"
		for _, p in avatar:GetDescendants() do
			if p:IsA("BasePart") then p.Anchored = true; p.CanCollide = false end
		end
		avatar:PivotTo(CFrame.new(-12, Y0 + 3, z + 0.5))
		local minY = math.huge
		for _, p in avatar:GetDescendants() do
			if p:IsA("BasePart") then minY = math.min(minY, p.Position.Y - p.Size.Y / 2) end
		end
		avatar:PivotTo(avatar:GetPivot() + V(0, Y0 - minY, 0))
		avatar.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		avatar.Parent = row
	end
	row.Parent = folder
	table.insert(report, stats)
end
folder.Parent = workspace
return game:GetService("HttpService"):JSONEncode(report)
