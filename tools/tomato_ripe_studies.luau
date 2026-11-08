-- Studio playtest, Client command context. Builds a local review plot with Pawvest's own
-- PlotView. Look from +Z of the plot toward A, B, C (left to right). Destroy the returned
-- preview folder after review. No garden requests or profile changes.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsClient(), "Run in the Studio playtest client")
local player = game:GetService("Players").LocalPlayer
local PlotView = require(player.PlayerScripts:WaitForChild("PlotView"))
local CropConfig = require(game.ReplicatedStorage.CropConfig)

local V = Vector3.new
local stem = Color3.fromRGB(59, 119, 64)
local darkLeaf = Color3.fromRGB(41, 126, 66)
local litLeaf = Color3.fromRGB(83, 161, 74)
local newLeaf = Color3.fromRGB(143, 187, 75)
local red = Color3.fromRGB(219, 52, 43)
local ripeRed = Color3.fromRGB(192, 42, 38)

local function block(model, name, size, cf, color, variant)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Material, p.MaterialVariant = Enum.Material.Plastic, variant
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.Parent = model
end

-- Local +Z follows the length of both a stem and a stepped leaf blade.
local function axis(a, b)
	local direction = (b - a).Unit
	local up = if math.abs(direction.Y) > 0.98 then Vector3.xAxis else Vector3.yAxis
	return CFrame.lookAt((a + b) / 2, a, up)
end

local function twig(model, base, a, b, width)
	block(model, "Stem", V(width, width, (b-a).Magnitude), base * axis(a, b), stem, "StudsSmall")
end

local function leaf(model, base, at, offset, width, color)
	local length = offset.Magnitude
	local cf = base * axis(at, at + offset)
	block(model, "Leaf", V(width, 0.14, length * 0.72), cf * CFrame.new(0, 0, -length * 0.14), color, "Studs")
	block(model, "LeafTip", V(width * 0.56, 0.13, length * 0.28), cf * CFrame.new(0, 0, length * 0.36), color, "StudsSmall")
end

local function fruit(model, base, at, size, color)
	-- The short vertical stalk holds a stepped, slightly flattened tomato. The smaller
	-- shoulder carries two crossed green sepals where the stalk meets the fruit.
	local stalkEnd = at - V(0, 0.22, 0)
	twig(model, base, at, stalkEnd, 0.10)
	local top = base * CFrame.new(stalkEnd)
	block(model, "Sepal", V(size * 0.57, 0.09, 0.14), top, darkLeaf, "StudsSmall")
	block(model, "Sepal", V(0.15, 0.10, size * 0.56), top, darkLeaf, "StudsSmall")
	block(model, "Shoulder", V(size*0.74, size*0.17, size*0.70), top * CFrame.new(0, -size*0.085, 0), color, "StudsSmall")
	block(model, "Tomato", V(size, size*0.55, size*0.66), top * CFrame.new(0, -size*0.445, 0), color, "StudsSmall")
	for _, side in {-1, 1} do
		block(model, "Cheek", V(size*0.74, size*0.47, size*0.14), top * CFrame.new(0, -size*0.44, side*size*0.40), color, "StudsSmall")
	end
	block(model, "Base", V(size*0.72, size*0.16, size*0.64), top * CFrame.new(0, -size*0.80, 0), color, "StudsSmall")
end

-- Hand-placed joints are in studs above the soil. Each arm has an elbow, a fruit
-- attachment, and one leaf growing outward beyond the elbow.
local studies = {
	{
		name = "A - Spreading", joint = V(-0.06, 0.83, 0), crown = V(0.18, 1.68, -0.18),
		arms = {
			{V(-0.75,1.37,0.05), V(-1.18,1.23,0.44), V(-0.98,0.12,-0.36), 0.85},
			{V(0.68,1.40,0.14), V(1.19,1.33,0.34), V(0.94,0.20,-0.35), 0.78},
			{V(-0.20,1.60,-0.50), V(-0.70,1.40,-0.82), V(-0.32,0.32,-0.81), 0.63},
		},
	},
	{
		name = "B - Upright", joint = V(0.04, 1.00, 0), crown = V(-0.12, 2.58, -0.14),
		arms = {
			{V(-0.50,1.58,0.06), V(-0.93,1.47,0.48), V(-0.91,0.33,-0.21), 0.82},
			{V(0.51,2.16,-0.14), V(0.92,1.95,0.21), V(0.80,0.41,-0.36), 0.75},
		},
	},
	{
		name = "C - Fruit laden", joint = V(0.30, 0.98, 0.03), crown = V(0.77, 2.11, -0.10),
		arms = {
			{V(-0.48,1.50,-0.14), V(-0.95,1.38,0.18), V(-0.97,0.27,-0.28), 0.73},
			{V(1.13,1.65,0.08), V(1.44,1.18,0.22), V(0.74,0.25,-0.40), 0.90},
			{V(0.57,1.67,0.57), V(0.37,1.34,0.85), V(-0.38,0.13,0.68), 0.70},
		},
	},
}

local function drawStudy(parent, base, study)
	local model = Instance.new("Model")
	model.Name = study.name
	twig(model, base, V(0,0,0), study.joint, 0.19)
	twig(model, base, study.joint, study.crown, 0.17)
	for i, arm in study.arms do
		local elbow, endPoint, blade, fruitSize = table.unpack(arm)
		local fork = study.joint:Lerp(study.crown, (i-1)*0.27)
		twig(model, base, fork, elbow, 0.14)
		twig(model, base, elbow, endPoint, 0.12)
		local leafColor = if i%2 == 1 then darkLeaf else litLeaf
		leaf(model, base, elbow, blade * 1.18, 0.60, leafColor)
		local side = Vector3.yAxis:Cross(blade).Unit
		local leafJoint = elbow + blade * 0.32
		leaf(model, base, leafJoint, blade*0.46 + side*0.52 + V(0,-0.12,0), 0.37, leafColor)
		leaf(model, base, leafJoint, blade*0.53 - side*0.46 + V(0,0.10,0), 0.37, litLeaf)
		fruit(model, base, endPoint, fruitSize, if i == 2 then ripeRed else red)
	end
	leaf(model, base, study.crown, V(-0.78,0.25,0.35), 0.48, litLeaf)
	leaf(model, base, study.crown, V(0.57,0.34,-0.51), 0.41, newLeaf)
	model.Parent = parent
end

local folder = Instance.new("Folder")
folder.Name = "TomatoRipeStudies"
assert(not workspace:FindFirstChild(folder.Name), "Remove the previous review folder before rerunning")
local view = PlotView.new(13, folder)
-- An unoccupied outer plot, behind the garden, uses real plot and square geometry.
local realPlot = workspace.GardenView:FindFirstChild(view.root.Name)
assert(not realPlot, "Review slot 13 is in use")
local cells = table.create(CropConfig.MaxSquares, "#0")
for i = 1, 12 do cells[i] = ".0" end
cells[7] = "a2"
view:SetState({name = player.DisplayName, incCount = 1, eggs = {},
	field = {crops = table.concat(cells), pets = {"Cat:3:review:11:1:1"}}})
view:SetDetail("full")
while view:Step(os.clock() + 0.006) do task.wait() end
for i, study in studies do
	drawStudy(folder, view:SquareCFrame(7 + i), study)
end

-- Reuse an actual field ring when one is available in the playtest. Keep it over
-- the existing crop so all three studies remain unobstructed during comparison.
local rings = workspace:FindFirstChild("FieldRings")
local template = rings and rings:FindFirstChildWhichIsA("BillboardGui", true)
if template then
	local soil = view.pieces.sq7:FindFirstChild("Soil7")
	local attachment = Instance.new("Attachment")
	attachment.Parent = soil
	attachment.WorldCFrame = view:SquareCFrame(7)
	local ring = template:Clone()
	ring.Adornee, ring.Enabled = attachment, true
	ring.Time.Visible = false
	ring.Disc.Inner.Icon.Text = CropConfig.ById.Potato.icon
	ring.Parent = attachment
end
folder.Parent = workspace
return folder:GetFullName()
