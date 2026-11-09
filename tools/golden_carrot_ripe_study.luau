-- Golden Carrot mature art study. Run in a Studio playtest Client context.
-- Disposable plot, one root, feathery crown, sparse ripe glints and same-plane avatar. No field/profile requests.
-- Destroy Workspace.GoldenCarrotStudy to restore the camera and HUD.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsClient(), "Studio client only")
local player = game.Players.LocalPlayer
local PlotView = require(player.PlayerScripts:WaitForChild("PlotView"))
local Kit = require(game.ReplicatedStorage.PlantKit)
local GardenConfig = require(game.ReplicatedStorage.GardenConfig)
local CropConfig = require(game.ReplicatedStorage.CropConfig)
local garden = assert(workspace:FindFirstChild("GardenView"), "Wait for GardenView")
assert(not workspace:FindFirstChild("GoldenCarrotStudy"), "Destroy previous study first")
local slot
for n = 13, GardenConfig.PlotSlots do
	if not garden:FindFirstChild(string.format("Slot_%02d", n)) then slot = n; break end
end
assert(slot, "No free study plot")
local V, C = Vector3.new, Color3.fromRGB
local GOLD, LIGHT, AMBER = C(239, 178, 40), C(255, 214, 88), C(180, 113, 28)
local STALK, GREEN, TIP = C(47, 110, 44), C(69, 151, 57), C(110, 185, 65)
local root = Instance.new("Folder")
root.Name = "GoldenCarrotStudy"
local view = PlotView.new(slot, root)
local cells = table.create(CropConfig.MaxSquares, "#0")
for n = 1, 12 do cells[n] = ".0" end
view:SetState({name = player.DisplayName, incCount = 1, eggs = {},
	field = {crops = table.concat(cells), pets = {"Cat:3:review:4:1:1"}}})
view:SetDetail("full")
while view:Step(os.clock() + 0.006) do task.wait() end
local base = view:SquareCFrame(9)
local plant = Instance.new("Model")
plant.Name = "GoldenCarrotMature"
plant:SetAttribute("StaticRipeStudy", true)

local function block(name, size, cf, color, role, wedge)
	return Kit.proxyPart(plant, name, size, base * cf, color, "StudsSmall", role, nil,
		if wedge then "WedgePart" else nil)
end
local function rod(name, a, b, width)
	return block(name, V(width, width, (b-a).Magnitude + 0.015), Kit.axis(a,b), STALK, "Foliage")
end

-- Full elongated root, with two-thirds of its length below the soil. A finer lower section sharpens the buried tip.
local rootLength = 2.1
local buriedFraction = 2/3
local rootShift = 0.08-rootLength*buriedFraction
local shoulder
for i, width in {0.06,0.24,0.43,0.64,0.86,0.76} do
	local p = block("Root_"..i, V(width,0.35,width),
		CFrame.new(0.01*(i-1),0.095+(i-1)*0.35+rootShift,0)*CFrame.Angles(0,math.pi/4,0),
		if i==6 then LIGHT else GOLD, "Root")
	p.Reflectance = 0.08
	if i==6 then shoulder=p end
end
-- Short creases on the exposed shoulder. The long lower taper stays concealed by the ground.
for i,s in {{0.16,1.50,0.497,0.28,math.pi/4}, {-0.05,1.67,0.526,0.24,-math.pi/4}, {0.13,1.90,0.466,0.18,math.pi/4}} do
	block("RootCrease_"..i,V(s[4],0.026,0.018),CFrame.new(s[1],s[2]+rootShift,s[3])*CFrame.Angles(0,s[5],0),AMBER,"Root")
end

-- Seven unequal divided fronds. Two stalk segments and three leaflet pairs plus a terminal leaflet = 9 Parts each.
-- Fronds are authored in local YZ planes; yaw fans them around their common crown.
-- Preserve the taller green crown; its base follows the elongated root's top.
local foliageRise = V(1,1.45,1)
local fronds = {
	{-2.65,1.95,0.83,0.34}, {-1.55,2.15,1.02,0.28}, {-0.48,2.30,0.99,0.24},
	{0.42,2.00,0.70,0.34}, {1.38,2.35,1.18,0.20}, {2.37,1.85,0.77,0.33}, {3.08,2.42,1.30,0.17},
}
for n,s in fronds do
	local frame = CFrame.new(0.05,2.00+rootShift,0)*CFrame.Angles(0,s[1],0)
	local a = V(0,0,0)
	local b = V(0,math.sin(s[3]),math.cos(s[3]))*s[2]*0.52*foliageRise
	local c = b + V(0,math.sin(s[3]-s[4]),math.cos(s[3]-s[4]))*s[2]*0.48*foliageRise
	rod("Frond_"..n.."_Lower",frame:PointToWorldSpace(a),frame:PointToWorldSpace(b),0.052)
	rod("Frond_"..n.."_Upper",frame:PointToWorldSpace(b),frame:PointToWorldSpace(c),0.038)
	for pair,t in {0.38,0.61,0.81} do
		local at = if t<=0.52 then a:Lerp(b,t/0.52) else b:Lerp(c,(t-0.52)/0.48)
		local length = (if pair==1 then 0.48 elseif pair==2 then 0.41 else 0.29)*(s[2]/2.2)
		for _,side in {-1,1} do
			local endPoint = at + V(side*length*0.83,length*0.15,length*0.56)
			-- A wedge laid on its side gives each narrow leaflet a pointed outline in its own leaf plane.
			block("Frond_"..n.."_Leaf_"..pair.."_"..side,V(0.045,0.22*(1.15-pair*0.12),(endPoint-at).Magnitude),
				frame*Kit.axis(at,endPoint)*CFrame.Angles(0,0,side*math.pi/2),if pair==3 then TIP else GREEN,"Foliage",true)
		end
	end
	local tip = c + (c-b).Unit*0.20
	block("Frond_"..n.."_Tip",V(0.04,0.14,0.28),frame*Kit.axis(c-V(0,0.05,0),tip)*CFrame.Angles(0,0,math.pi/2),TIP,"Foliage",true)
end

-- Native sparse particles need no per-frame crop loop. One brief glint roughly every five seconds.
local glintAnchor = Instance.new("Attachment")
glintAnchor.Name = "RipeGlint"
glintAnchor.Position = V(0,0.10,0.386)
glintAnchor.Parent = shoulder
local glint = Instance.new("ParticleEmitter")
glint.Name = "GoldGlint"
glint.Texture = "rbxasset://textures/particles/sparkles_main.dds"
glint.Color = ColorSequence.new(C(255,230,130),C(255,248,206))
glint.LightEmission, glint.LightInfluence = 0.8, 0
glint.Rate, glint.Lifetime, glint.Speed = 0.2, NumberRange.new(0.45,0.65), NumberRange.new(0.03,0.08)
glint.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.35,0.24),NumberSequenceKeypoint.new(1,0)})
glint.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.2,0.05),NumberSequenceKeypoint.new(1,1)})
glint.Rotation, glint.RotSpeed = NumberRange.new(0,90), NumberRange.new(-12,12)
glint.SpreadAngle, glint.LockedToPart = Vector2.new(15,15), true
glint.Parent = glintAnchor
plant.Parent = root
view:ShowSelect(9)
root:SetAttribute("SoilCFrame",base)
root:SetAttribute("ReviewSlot",slot)

local radius, height, lowest, count = 0,0,math.huge,0
local rootLow,rootHigh = V(math.huge,math.huge,math.huge),V(-math.huge,-math.huge,-math.huge)
for _,p in plant:GetChildren() do
	if not p:IsA("BasePart") then continue end
	count += 1
	local half = p.Size/2
	for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
		local corner = base:PointToObjectSpace(p.CFrame:PointToWorldSpace(half*V(x,y,z)))
		radius = math.max(radius,V(corner.X,0,corner.Z).Magnitude)
		height,lowest = math.max(height,corner.Y),math.min(lowest,corner.Y)
		if p:GetAttribute("PlantRole")=="Root" then rootLow,rootHigh=rootLow:Min(corner),rootHigh:Max(corner) end
	end end end
end
assert(count==72 and radius<=2.4,"Study exceeds Part budget/footprint")
local rootWidth = math.max(rootHigh.X-rootLow.X,rootHigh.Z-rootLow.Z)
local rootVisibleHeight = rootHigh.Y-math.max(0,rootLow.Y)
local rootFullHeight = rootHigh.Y-rootLow.Y
local rootAspect = rootFullHeight/rootWidth
local rootBuriedFraction = -rootLow.Y/rootFullHeight
assert(rootAspect>=1.5 and rootAspect<=2,"Edible root lost its elongated carrot proportions")
assert(math.abs(rootBuriedFraction-buriedFraction)<0.005,"Root must be two-thirds below the soil")

-- Same-ground-plane avatar. Remove scripts before parenting the local clone.
local avatarHeight
local character = player.Character
if character then
	local old = character.Archivable
	character.Archivable = true
	local avatar = character:Clone()
	character.Archivable = old
	avatar.Name = "ScaleReference"
	for _,child in avatar:GetDescendants() do
		if child:IsA("LuaSourceContainer") or child:IsA("ForceField") then child:Destroy()
		elseif child:IsA("BasePart") then
			child.Anchored,child.CanCollide,child.CanTouch,child.CanQuery=true,false,false,false
		end
	end
	avatar:PivotTo(base*CFrame.new(-3.5,3,0)*CFrame.Angles(0,math.pi,0))
	local cf,size = avatar:GetBoundingBox()
	avatarHeight = size.Y
	avatar:PivotTo(avatar:GetPivot()+V(0,base.Position.Y-(cf.Position.Y-size.Y/2),0))
	avatar.Parent=root
end
local camera = workspace.CurrentCamera
local oldCF,oldType,oldFocus = camera.CFrame,camera.CameraType,camera.Focus
local hidden = {}
for _,gui in player.PlayerGui:GetChildren() do
	if gui:IsA("ScreenGui") and gui.Enabled then hidden[#hidden+1]=gui; gui.Enabled=false end
end
root.Destroying:Connect(function()
	RunService:UnbindFromRenderStep("GoldenCarrotStudyCamera")
	camera.CFrame,camera.CameraType,camera.Focus=oldCF,oldType,oldFocus
	for _,gui in hidden do if gui.Parent then gui.Enabled=true end end
	view:Destroy()
end)
root.Parent=workspace
camera.CameraType=Enum.CameraType.Scriptable
local target = base:PointToWorldSpace(V(-0.75,1.95,0))
local eye = base:PointToWorldSpace(V(2,6.4,10.8))
local studyCamera = CFrame.lookAt(eye,target)
RunService:BindToRenderStep("GoldenCarrotStudyCamera",Enum.RenderPriority.Last.Value+1,function()
	camera.CameraType,camera.CFrame,camera.Focus=Enum.CameraType.Scriptable,studyCamera,CFrame.new(target)
end)
return game.HttpService:JSONEncode({parts=count,radius=radius,height=height,lowest=lowest,avatarHeight=avatarHeight,slot=slot,
	rootWidth=rootWidth,rootVisibleHeight=rootVisibleHeight,rootFullHeight=rootFullHeight,rootAspect=rootAspect,
	rootBuriedFraction=rootBuriedFraction})
