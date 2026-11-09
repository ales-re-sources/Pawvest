-- Historical CG8a bell-fruit study, superseded by PepperPlant's corrected chilli fruit.
-- For current art use PlantGrowthReview.Open("Pepper", 10); this file preserves the original comparison only.
-- CG8a: display-only mature silhouette, run in Studio playtest Client context.
-- No field requests or saved-state writes. Destroy PepperRipeStudy to restore camera/HUD.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsClient(), "Studio client only")
local player = game.Players.LocalPlayer
local PlotView = require(player.PlayerScripts:WaitForChild("PlotView"))
local Kit = require(game.ReplicatedStorage.PlantKit)
local GardenConfig = require(game.ReplicatedStorage.GardenConfig)
local CropConfig = require(game.ReplicatedStorage.CropConfig)
local garden = assert(workspace:FindFirstChild("GardenView"), "Wait for GardenView")
assert(not workspace:FindFirstChild("PepperRipeStudy"), "Destroy previous study first")
local slot = 13
while GardenConfig.PlotCFrame(slot) and garden:FindFirstChild(string.format("Slot_%02d", slot)) do slot += 1 end
assert(GardenConfig.PlotCFrame(slot), "No free study slot")
local V, C = Vector3.new, Color3.fromRGB
local stem, dark, leafGreen = C(63, 121, 53), C(48, 121, 49), C(86, 151, 59)
local red, redShade = C(222, 45, 32), C(205, 35, 28)
local root = Instance.new("Folder")
root.Name = "PepperRipeStudy"
local view = PlotView.new(slot, root)
local cells = table.create(CropConfig.MaxSquares, "#0")
for n = 1, 24 do cells[n] = ".0" end
view:SetState({name = player.DisplayName, incCount = 1, eggs = {},
	field = {crops = table.concat(cells), pets = {"Cat:3:review:11:1:1"}}})
view:SetDetail("full")
while view:Step(os.clock() + 0.006) do task.wait() end
local base = view:SquareCFrame(9)
local plant = Instance.new("Model")
plant.Name = "PepperMature"
plant:SetAttribute("StaticRipeStudy", true)
local slots = {}
local function block(name, size, frame, color, role, id)
	local p = Kit.proxyPart(plant, name, size, base * frame, color, "StudsSmall", role, id)
	if id then table.insert(slots[id].parts, p) end
	return p
end
local function rod(name, a, b, width, role, id)
	return block(name, V(width, width, (b-a).Magnitude), Kit.axis(a,b), stem, role or "Structure", id)
end
local trunk = {V(0,0,0), V(-0.04,0.65,0), V(0.04,1.35,0.02), V(0,2.02,0)}
for i = 1, 3 do rod("Stem"..i, trunk[i], trunk[i+1], 0.14-(i-1)*0.018) end
local left, right, crown = V(-0.87,2.78,0.04), V(0.83,3.18,-0.16), V(-0.12,3.32,-0.38)
rod("LeftFork", trunk[4], left, 0.105)
rod("RightFork", trunk[4], right, 0.105)
rod("CrownFork", V(0.4,2.6,-0.09), crown, 0.08)
rod("LowerArm", trunk[3], V(0.85,1.98,0.50), 0.085)

-- Attached three-plate pointed leaves, no broad rosette or compound foliage.
local leaves = {
	{trunk[2], -1.7, 0.65, 0.34, 0.18}, {trunk[3], 1.8, 0.80, 0.40, 0.25},
	{V(-0.34,2.30,0.02), -2.2, 0.92, 0.48, 0.32},
	{V(-0.56,2.50,0.03), -0.85, 0.86, 0.46, 0.35},
	{left, -1.45, 0.70, 0.40, 0.36}, {left, 0.20, 0.68, 0.38, 0.40},
	{V(0.40,2.60,-0.09), 2.1, 0.82, 0.44, 0.33},
	{right, 1.0, 0.77, 0.42, 0.23}, {right, -2.0, 0.72, 0.40, 0.27},
	{crown, -0.3, 0.62, 0.37, 0.12}, {crown, 2.5, 0.55, 0.34, 0.16},
	{V(0.62,1.82,0.36), 1.2, 0.70, 0.41, 0.38},
}
for n, spec in leaves do
	local frame = CFrame.new(spec[1]) * CFrame.Angles(0, spec[2], 0)
	local last = V(0,0,0)
	local fractions, widths = {0.28,0.42,0.30}, {0.60,1,0.30}
	for i = 1, 3 do
		local angle = spec[5] - (i-1)*0.20
		local nextPoint = last + V(0,math.sin(angle),math.cos(angle))*spec[3]*1.18*fractions[i]
		block("Leaf"..n.."_"..i, V(spec[4]*1.35*widths[i],0.055,(nextPoint-last).Magnitude+0.015),
			frame * Kit.axis(last,nextPoint), if n%3==0 then leafGreen else dark, "Foliage")
		last = nextPoint
	end
end

-- Three 15-Part bells: four connected lobes with broad shoulders and blunt tapered lower tips.
-- Longer, slimmer bells distinguish ripe red Pepper from Tomato at gameplay distance.
local bodyProportions = V(0.86, 1.27, 0.86)
local fruit = {
	{left, V(-1.06,2.53,0.30), 1.0, -0.13, 0.18},
	{right, V(1.02,2.94,0.12), 0.94, 0.11, -0.20},
	{V(0.85,1.98,0.50), V(0.98,1.78,0.78), 0.87, -0.08, 0.32},
}
for id, spec in fruit do
	slots[id] = {id=id, attachment=base:PointToWorldSpace(spec[1]), parts={}}
	local at, scale = spec[2], spec[3]
	local joint = spec[1]:Lerp(at,0.56) + V(0,0.06,0)
	rod("Fruit"..id.."_StalkA", spec[1], joint, 0.085, "Fruit", id)
	rod("Fruit"..id.."_StalkB", joint, at, 0.085, "Fruit", id)
	local frame = CFrame.new(at) * CFrame.Angles(0,spec[5],spec[4])
	block("Fruit"..id.."_Calyx", V(0.30,0.12,0.30)*V(bodyProportions.X,1,bodyProportions.Z)*scale, frame, dark, "Fruit", id)
	for i=1,4 do
		local turn = CFrame.Angles(0,(i-1)*math.pi/2,0)
		block("Fruit"..id.."_Sepal"..i, V(0.13*bodyProportions.X,0.065,0.33*bodyProportions.Z)*scale,
			frame*turn*CFrame.new(0,-0.025*scale,0.15*bodyProportions.Z*scale)*CFrame.Angles(0.25,0,0), dark, "Fruit", id)
	end
	for i, p in {V(-1,0,-1), V(1,0,-1), V(-1,0,1), V(1,0,1)} do
		local tint = if i==1 or i==4 then redShade else red
		local tilt = CFrame.Angles(p.Z*0.055,0,-p.X*0.055)*CFrame.Angles(0,math.pi/4,0)
		block("Fruit"..id.."_Shoulder"..i, V(0.44,0.72,0.44)*bodyProportions*scale,
			frame*CFrame.new((p*0.218+V(0,-0.40,0))*bodyProportions*scale)*tilt,tint,"Fruit",id)
		block("Fruit"..id.."_LowerLobe"..i, V(0.38,0.43,0.38)*bodyProportions*scale,
			frame*CFrame.new((p*0.195+V(0,-0.91+(i%2)*0.025,0))*bodyProportions*scale)*tilt,tint,"Fruit",id)
	end
end
plant.Parent = root
view:ShowSelect(9)
root:SetAttribute("SoilCFrame",base)
root:SetAttribute("ReviewSlot",slot)
local radius, height, lowest = 0, 0, math.huge
for _, p in plant:GetChildren() do
	local half = p.Size/2
	for _, x in {-1,1} do for _, y in {-1,1} do for _, z in {-1,1} do
		local corner = base:PointToObjectSpace(p.CFrame:PointToWorldSpace(half*V(x,y,z)))
		radius = math.max(radius,V(corner.X,0,corner.Z).Magnitude)
		height = math.max(height,corner.Y)
		lowest = math.min(lowest,corner.Y)
	end end end
end
assert(#plant:GetChildren()<=90 and radius<=2.4, "Study exceeds art budget/footprint")

-- Same-ground-plane avatar, cloned locally with scripts removed before parenting.
local character = player.Character
if character then
	local old = character.Archivable
	character.Archivable = true
	local avatar = character:Clone()
	character.Archivable = old
	avatar.Name = "ScaleReference"
	for _, child in avatar:GetDescendants() do
		if child:IsA("LuaSourceContainer") then child:Destroy()
		elseif child:IsA("BasePart") then child.Anchored=true; child.CanCollide=false; child.CanTouch=false; child.CanQuery=false end
	end
	avatar:PivotTo(base*CFrame.new(-3.65,3,0)*CFrame.Angles(0,math.pi,0))
	local cf, size = avatar:GetBoundingBox()
	local bottom = cf.Position.Y-size.Y/2
	avatar:PivotTo(avatar:GetPivot()+V(0,base.Position.Y-bottom,0))
	avatar.Parent=root
end
local camera = workspace.CurrentCamera
local oldCF, oldType, oldFocus = camera.CFrame, camera.CameraType, camera.Focus
local hidden = {}
for _, gui in player.PlayerGui:GetChildren() do
	if gui:IsA("ScreenGui") and gui.Enabled then hidden[#hidden+1]=gui; gui.Enabled=false end
end
root.Destroying:Connect(function()
	RunService:UnbindFromRenderStep("PepperRipeStudyCamera")
	camera.CFrame, camera.CameraType, camera.Focus = oldCF, oldType, oldFocus
	for _, gui in hidden do if gui.Parent then gui.Enabled=true end end
	view:Destroy()
end)
root.Parent=workspace
camera.CameraType=Enum.CameraType.Scriptable
local target = base:PointToWorldSpace(V(-0.75,2,0))
camera.CFrame=CFrame.lookAt(base:PointToWorldSpace(V(2,6.5,10.5)),target)
camera.Focus=CFrame.new(target)
local studyCamera = camera.CFrame
RunService:BindToRenderStep("PepperRipeStudyCamera", Enum.RenderPriority.Last.Value+1, function()
	camera.CameraType=Enum.CameraType.Scriptable
	camera.CFrame=studyCamera
	camera.Focus=CFrame.new(target)
end)
return game.HttpService:JSONEncode({parts=#plant:GetChildren(),radius=radius,height=height,lowest=lowest,
	fruitSlots={#slots[1].parts,#slots[2].parts,#slots[3].parts},soil={base:GetComponents()},slot=slot})
