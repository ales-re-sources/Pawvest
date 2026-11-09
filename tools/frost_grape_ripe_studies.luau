-- CG5a: static art studies, Studio playtest Client command context only.
-- No crop requests, profile writes or production recipe registration.
-- Square 8/9/10 = A/B/C; 16/17/18 = repeated B vineyard row.
-- Selected B is revised to ~7.43 studs; living foliage must exceed avatar height.
-- Destroy workspace.FrostGrapeRipeStudies after review; restore camera/HUD separately.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsClient(), "Studio client only")
local player = game.Players.LocalPlayer
local PlotView = require(player.PlayerScripts:WaitForChild("PlotView"))
local GardenConfig = require(game.ReplicatedStorage.GardenConfig)
local CropConfig = require(game.ReplicatedStorage.CropConfig)
local garden = assert(workspace:FindFirstChild("GardenView"), "Wait for GardenView")
assert(not workspace:FindFirstChild("FrostGrapeRipeStudies"), "Remove previous studies first")
local slot = 13
while GardenConfig.PlotCFrame(slot) and garden:FindFirstChild(string.format("Slot_%02d", slot)) do slot += 1 end
assert(GardenConfig.PlotCFrame(slot), "No free study slot")
local V = Vector3.new
local wood = Color3.fromRGB(123, 105, 85)
local cane = Color3.fromRGB(87, 82, 104)
local stem = Color3.fromRGB(68, 118, 111)
local leafDark = Color3.fromRGB(46, 115, 111)
local leafLight = Color3.fromRGB(77, 145, 131)
local ice = Color3.fromRGB(195, 234, 241)
local berries = {Color3.fromRGB(103, 111, 196), Color3.fromRGB(126, 151, 221), Color3.fromRGB(81, 95, 167)}
local function block(model, name, size, cf, color, variant)
 local p = Instance.new("Part")
 p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
 p.Material, p.MaterialVariant = Enum.Material.Plastic, variant or "StudsSmall"
 p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
 p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
 p.Parent = model
 return p
end
local function rod(model, base, a, b, width, color, name)
 local d = (b-a).Unit
 local up = if math.abs(d.Y)>0.98 then Vector3.xAxis else Vector3.yAxis
 block(model, name or "Cane", V(width,width,(b-a).Magnitude), base*CFrame.lookAt((a+b)/2,a,up), color)
end
local function leaf(model, base, node, at, scale, yaw, tilt)
 rod(model,base,node,at,0.09,stem,"LeafStalk")
 -- Five connected block lobes with a shallow basal notch. The broad blade is
 -- distinct from Potato's paired leaflets; no vein geometry is needed at phone size.
 local face = base*CFrame.new(at)*CFrame.Angles(tilt,yaw,0)
 local lobes = {
  {V(0,0,0.20),V(0.44,0.10,0.79),0},
  {V(-0.27,0,0.05),V(0.35,0.10,0.60),-0.75},
  {V(0.27,0,0.05),V(0.35,0.10,0.60),0.75},
  {V(-0.26,0,-0.23),V(0.30,0.10,0.37),-1.05},
  {V(0.26,0,-0.23),V(0.30,0.10,0.37),1.05},
 }
 for i,lobe in lobes do
  block(model,"LeafLobe",lobe[2]*scale,face*CFrame.new(lobe[1]*scale)*CFrame.Angles(0,lobe[3],0),if i%2==0 then leafDark else leafLight,"Studs")
 end
end
local function bunch(model,base,node,at,scale,turn)
 rod(model,base,node,at,0.10,stem,"BunchStalk")
 local frame = base*CFrame.new(at)*CFrame.Angles(0,turn,0)
 -- Two overlapping blocks bevel each berry without a mesh or transparent shell.
 -- Overlapping chunky berries form a tapered, three-dimensional bunch.
 -- Frost caps sit on two exposed shoulders, not as floating sparkle geometry.
 local positions = {
  V(-0.23,-0.13,0),V(0.23,-0.13,0),V(0,-0.10,-0.26),
  V(-0.23,-0.47,0.08),V(0.23,-0.47,0.08),V(0,-0.42,-0.22),
  V(-0.14,-0.78,0.05),V(0.14,-0.78,-0.10),V(0,-1.06,0),
 }
 for i,p in positions do
  local size = if i==9 then 0.35 else 0.43
  local cf=frame*CFrame.new(p*scale)*CFrame.Angles(0,(i%3)*0.20,0)
  local color=berries[(i-1)%3+1]
  block(model,"Grape",V(size,size*0.73,size*0.85)*scale,cf,color)
  block(model,"GrapeCrown",V(size*0.76,size*0.95,size*0.72)*scale,cf,color)
 end
 for _,x in {-0.23,0.23} do
  block(model,"FrostFacet",V(0.28,0.055,0.30)*scale,frame*CFrame.new(V(x,0.075,0)*scale)*CFrame.Angles(0,0.20,0),ice)
 end
end
local studies = {
 {name="A - Single-post fan",support="fan",
  path={V(0,0.02,0),V(-0.12,1.05,0.13),V(0.09,2.03,0.05),V(0,2.80,0)},
  arms={{V(0.09,2.03,0.05),V(-0.87,2.73,0.03),V(-1.55,2.82,-0.05)},{V(0,2.80,0),V(0.86,2.93,0),V(1.53,2.77,0.01)}},
  leaves={{V(-1.50,2.82,0),V(-1.55,2.88,0.22),1.04,-0.35,0.23},{V(-0.86,2.73,0),V(-0.75,2.90,-0.34),0.88,2.2,-0.16},{V(0.86,2.93,0),V(0.75,3.09,-0.28),1.0,2.6,-0.24},{V(1.53,2.77,0),V(1.54,2.91,0.29),0.96,0.30,0.28},{V(-0.12,1.05,0.13),V(-0.36,1.39,-0.23),0.69,2.5,-0.20}},
  fruit={{V(-1.20,2.78,0),V(-1.19,2.43,0.47),1.0,-0.20},{V(1.21,2.85,0),V(1.20,2.53,0.48),1.05,0.20},{V(0.05,2.50,0),V(0.23,2.18,0.44),0.78,0.10}}},
 -- B selected by Ales: mature foliage itself must stand above the player.
 -- Taller cane/support, not a uniformly stretched bunch or leaf.
 {name="B - Tall vineyard trellis",support="row",
  path={V(0,0.02,0),V(-0.12,1.35,0.12),V(0.12,3.55,0.08),V(0.03,5.30,0)},
  arms={{V(0.03,5.30,0),V(-0.85,5.36,0),V(-1.67,5.48,0)},{V(0.03,5.30,0),V(0.84,5.38,0),V(1.66,5.47,0)},{V(-0.85,5.36,0),V(-0.87,7.04,-0.06)},{V(0.84,5.38,0),V(0.73,7.12,-0.04)}},
  leaves={{V(-1.67,5.48,0),V(-1.56,6.12,0.10),0.94,-0.35,0.20},{V(-0.87,7.04,-0.06),V(-0.93,7.23,-0.16),1.0,2.4,-0.25},{V(0.03,5.30,0),V(0.03,6.45,-0.12),0.89,0.2,0.18},{V(0.73,7.12,-0.04),V(0.78,7.26,-0.15),1.0,2.5,-0.24},{V(1.66,5.47,0),V(1.54,6.15,0.10),0.91,0.35,0.20},{V(0.02,2.55,0.10),V(0.50,2.98,0.22),0.78,0.60,0.20}},
  fruit={{V(-1.29,5.42,0),V(-1.28,5.19,0.48),0.95,-0.1},{V(0.02,5.30,0),V(0.06,5.05,0.48),0.86,0.2},{V(1.28,5.42,0),V(1.27,5.20,0.48),1.0,0.05}}},
 {name="C - Wrapped pole",support="pole",
  path={V(0,0.02,0),V(-0.23,0.80,0.12),V(0.16,1.50,0.24),V(0.24,2.22,-0.06),V(-0.18,2.90,-0.10),V(0.02,3.38,0.10)},
  arms={{V(0.24,2.22,-0.06),V(-0.69,2.46,0.06)},{V(-0.18,2.90,-0.10),V(0.80,2.98,0.13)},{V(-0.23,0.80,0.12),V(-0.67,1.59,0.18)}},
  leaves={{V(-0.69,2.46,0.06),V(-1.0,2.69,-0.10),1.02,-0.5,0.28},{V(0.80,2.98,0.13),V(1.02,3.18,-0.08),1.07,0.5,0.25},{V(0.02,3.38,0.10),V(-0.11,3.54,0.05),0.90,2.7,-0.18},{V(0.16,1.50,0.24),V(0.71,1.92,-0.22),0.86,2.4,-0.2},{V(-0.67,1.59,0.18),V(-0.88,1.76,-0.20),0.74,2.5,-0.15}},
  fruit={{V(-0.69,2.46,0.06),V(-0.88,2.22,0.55),1.0,-0.2},{V(0.80,2.98,0.13),V(1.0,2.75,0.54),1.02,0.20},{V(0.16,1.50,0.24),V(0.46,1.47,0.62),0.70,0.15}}},
}
local function draw(parent,base,study,square)
 local model = Instance.new("Model")
 model.Name = study.name
 model:SetAttribute("StaticRipeStudy",true)
 model:SetAttribute("Square",square)
 if study.support=="row" then
  for _,x in {-1.88,1.88} do block(model,"RigidPost",V(0.19,7.40,0.19),base*CFrame.new(x,3.70,-0.14),wood,"Studs") end
  for _,y in {5.30,7.10} do block(model,"RigidRail",V(3.95,0.095,0.095),base*CFrame.new(0,y,-0.14),wood) end
 else
  local height = if study.support=="pole" then 3.48 else 3.18
  block(model,"RigidPost",V(0.21,height,0.21),base*CFrame.new(0,height/2,-0.14),wood,"Studs")
  block(model,"PostCap",V(0.29,0.12,0.29),base*CFrame.new(0,height,-0.14),ice)
  if study.support=="fan" then block(model,"RigidCrossbar",V(3.45,0.13,0.13),base*CFrame.new(0,2.82,-0.14),wood) end
 end
 for i=1,#study.path-1 do rod(model,base,study.path[i],study.path[i+1],0.15,cane) end
 for _,arm in study.arms do for i=1,#arm-1 do rod(model,base,arm[i],arm[i+1],0.115,stem) end end
 for _,l in study.leaves do leaf(model,base,table.unpack(l)) end
 for _,f in study.fruit do bunch(model,base,table.unpack(f)) end
 -- One angular tendril; modest geometry suggests the climbing habit.
 local tip = study.arms[2][#study.arms[2]]
 local curl = {tip,tip+V(0.14,0.28,-0.13),tip+V(0.35,0.30,-0.20),tip+V(0.30,0.13,-0.17)}
 for i=1,#curl-1 do rod(model,base,curl[i],curl[i+1],0.055,stem,"Tendril") end
 model:SetAttribute("PartCount",#model:GetChildren())
 assert(#model:GetChildren()<=120,"Study part budget exceeded")
 model.Parent=parent
 return model
end
local folder=Instance.new("Folder")
folder.Name="FrostGrapeRipeStudies"
local view=PlotView.new(slot,folder)
local cells=table.create(CropConfig.MaxSquares,"#0")
for n=1,24 do cells[n]=".0" end
cells[7]="k3"
view:SetState({ownerId=player.UserId,name=player.DisplayName,incCount=1,eggs={},field={crops=table.concat(cells),plants={["7"]={n=1,startAt=0,readyAt=0,size=1}},pets={"Cat:3:review:11:1:1"}}})
view:SetDetail("full")
while view:Step(os.clock()+0.006) do task.wait() end
local counts={}
for i,study in studies do
 local model=draw(folder,view:SquareCFrame(7+i),study,7+i)
 counts[study.name]=model:GetAttribute("PartCount")
end
for i=1,3 do local model=draw(folder,view:SquareCFrame(15+i),studies[2],15+i);model.Name="VineyardRow"..i end
folder:SetAttribute("ReviewSlot",slot)
folder:SetAttribute("SelectedStudy","B")
folder:SetAttribute("MatureCanopyMinimum",7.1)
folder:SetAttribute("RigidSupportHeight",7.4)
folder.Parent=workspace
view:ShowSelect(9)
return game.HttpService:JSONEncode({folder=folder:GetFullName(),slot=slot,parts=counts})
