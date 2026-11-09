-- CG6a: run in Studio playtest Client context. Display only; no field requests.
-- Squares 8/9/10 = A/B/C. Stop Play to remove.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsClient(), "Studio client only")
local player = game.Players.LocalPlayer
local PlotView = require(player.PlayerScripts:WaitForChild("PlotView"))
local GardenConfig = require(game.ReplicatedStorage.GardenConfig)
local CropConfig = require(game.ReplicatedStorage.CropConfig)
local garden = assert(workspace:FindFirstChild("GardenView"), "Wait for GardenView")
assert(not workspace:FindFirstChild("CornRipeStudies"), "Remove previous studies first")
local slot = 13
while GardenConfig.PlotCFrame(slot) and garden:FindFirstChild(string.format("Slot_%02d", slot)) do slot += 1 end
assert(GardenConfig.PlotCFrame(slot), "No free study slot")
local V = Vector3.new
local green = Color3.fromRGB(77, 136, 54)
local light = Color3.fromRGB(107, 159, 60)
local dark = Color3.fromRGB(51, 111, 47)
local husk = Color3.fromRGB(124, 160, 66)
local gold = Color3.fromRGB(247, 189, 52)
local pale = Color3.fromRGB(255, 214, 79)
local silk = Color3.fromRGB(154, 108, 55)
local tassel = Color3.fromRGB(188, 163, 79)
local function block(model, name, size, cf, color, role, fruitSlot)
 local p = Instance.new("Part")
 p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
 p.Material, p.MaterialVariant = Enum.Material.Plastic, "StudsSmall"
 p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
 p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
 p:SetAttribute("PlantRole", role or "Structure")
 if fruitSlot then p:SetAttribute("FruitSlot", fruitSlot) end
 p.Parent = model
 return p
end
local function rod(model, base, a, b, width, color, name, role, fruitSlot)
 local direction = (b-a).Unit
 local up = if math.abs(direction.Y)>0.98 then Vector3.xAxis else Vector3.yAxis
 return block(model, name, V(width,width,(b-a).Magnitude), base*CFrame.lookAt((a+b)/2,b,up), color, role, fruitSlot)
end
local function blade(model, base, node, yaw, reach, rise, droop, width, index)
 -- Three connected plates share endpoints and taper toward the hanging tip.
 local frame = base*CFrame.new(node)*CFrame.Angles(0,yaw,0)
 local path = {V(0,0,0),V(0,rise,reach*0.36),V(0,rise*0.92,reach*0.72),V(0,rise-droop,reach)}
 local widths = {width*0.72,width,width*0.43}
 for i=1,3 do
  local a,b = path[i],path[i+1]
  local cf = frame*CFrame.lookAt((a+b)/2,b,Vector3.yAxis)
  block(model,"Leaf"..index.."_"..i,V(widths[i],0.075,(b-a).Magnitude+0.035),cf,if index%2==0 then light else dark)
 end
end
local function ear(model, base, node, yaw, size, fruitSlot)
 local frame = base*CFrame.new(node)*CFrame.Angles(0,yaw,0)*CFrame.Angles(0,0,-0.36)
 local function part(name, dims, at, color, angle)
  return block(model,name,dims*size,frame*CFrame.new(at*size)*(angle or CFrame.identity),color,"Fruit",fruitSlot)
 end
 rod(model,frame,V(0,0,0),V(0,0.28*size,0),0.12,green,"EarStalk","Fruit",fruitSlot)
 part("CobCore",V(0.46,1.13,0.40),V(0,0.94,0),gold)
 part("CobTip",V(0.30,0.24,0.31),V(0,1.60,0),pale)
 -- Chunky kernel rows on both sides remain legible as the camera moves.
 for _,face in {-1,1} do for row=1,4 do for col=1,2 do
  part("Kernel",V(0.19,0.21,0.075),V((col-1.5)*0.215,0.66+(row-1)*0.245,face*0.224),if (row+col)%2==0 then pale else gold)
 end end end
 for _,side in {-1,1} do
  part("HuskBase",V(0.16,0.74,0.49),V(side*0.24,0.66,0),husk,CFrame.Angles(0,0,-side*0.12))
  part("HuskTip",V(0.13,0.62,0.30),V(side*0.34,1.22,0.03),light,CFrame.Angles(0,0,-side*0.22))
 end
 for _,side in {-1,1} do
  rod(model,frame,V(side*0.055,1.70,0)*size,V(side*0.14,1.82,-0.06)*size,0.055,silk,"Silk","Fruit",fruitSlot)
 end
end
local studies = {
 {name="A - Classic two-ear",height=5.95,reach=1.95,width=0.56,leaves=8,ears=2,earSize=0.88},
 {name="B - Tall narrow",height=7.15,reach=1.55,width=0.43,leaves=9,ears=2,earSize=0.85},
 {name="C - Compact broad-leaf",height=4.75,reach=2.08,width=0.72,leaves=7,ears=1,earSize=1.06},
}
local function draw(parent,base,study,square,turn)
 base *= CFrame.Angles(0,turn or 0,0)
 local model = Instance.new("Model")
 model.Name=study.name
 model:SetAttribute("StaticRipeStudy",true)
 model:SetAttribute("Square",square)
 model:SetAttribute("SoilCFrame",base)
 local function node(t) return V(0.10*math.sin(t*2.5),study.height*t,0.08*t*t) end
 for i=1,7 do
  rod(model,base,node((i-1)/7),node(i/7),0.18-(i-1)*0.012,green,"Internode")
  if i<7 then block(model,"Node",V(0.21,0.08,0.21),base*CFrame.new(node(i/7)),light) end
 end
 for i=1,study.leaves do
  local t=0.15+(i-1)*0.70/(study.leaves-1)
  local yaw=if i%2==0 then -math.pi/2+0.16 else math.pi/2-0.22
  yaw += (i%3-1)*0.22
  local reach=study.reach*(if i==study.leaves then 0.64 elseif i==1 then 0.79 else 1)
  blade(model,base,node(t),yaw,reach,0.52,0.78,study.width,i)
 end
 for i=1,study.ears do
  local t=if i==1 then 0.54 else 0.37
  local yaw=if i==1 then 0.20 else math.pi+0.15
  ear(model,base,node(t),yaw,study.earSize*(if i==1 then 1 else 0.84),i)
 end
 local crown=node(1)
 rod(model,base,crown,crown+V(0,0.68,0),0.07,tassel,"TasselLeader")
 for i=1,4 do
  local yaw=(i-1)*math.pi/2+0.35
  local a=crown+V(0,0.12+(i%2)*0.12,0)
  local b=a+V(math.cos(yaw)*0.30,0.30,math.sin(yaw)*0.30)
  local c=b+V(math.cos(yaw)*0.12,0.23,math.sin(yaw)*0.12)
  rod(model,base,a,b,0.075,tassel,"TasselBranch")
  rod(model,base,b,c,0.06,tassel,"TasselTip")
 end
 model:SetAttribute("PartCount",#model:GetChildren())
 assert(#model:GetChildren()<=110,"Art study part budget exceeded")
 model.Parent=parent
 return model
end
local folder=Instance.new("Folder")
folder.Name="CornRipeStudies"
local view=PlotView.new(slot,folder)
local cells=table.create(CropConfig.MaxSquares,"#0")
for n=1,24 do cells[n]=".0" end
cells[7]="a3"
view:SetState({ownerId=player.UserId,name=player.DisplayName,incCount=1,eggs={},field={crops=table.concat(cells),plants={["7"]={n=1,startAt=0,readyAt=0,size=1}},pets={"Cat:3:review:11:1:1"}}})
view:SetDetail("full")
while view:Step(os.clock()+0.006) do task.wait() end
local counts={}
for i,study in studies do
 local model=draw(folder,view:SquareCFrame(7+i),study,7+i)
 counts[study.name]=model:GetAttribute("PartCount")
end
folder:SetAttribute("ReviewSlot",slot)
folder:SetAttribute("SelectedStudy","B")
folder.Parent=workspace
view:ShowSelect(8)
return game.HttpService:JSONEncode({folder=folder:GetFullName(),slot=slot,parts=counts})
