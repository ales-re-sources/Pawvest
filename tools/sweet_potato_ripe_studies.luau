-- Three static sweet-potato studies. Execute in Studio Edit; no scripts, remotes or profile writes.
-- Dispose workspace.SweetPotatoRipeStudies after review. Plant art is not registered by this tool.
assert(game:GetService("RunService"):IsStudio(), "Studio only")
assert(game.PlaceId == 73033440513091, "Wrong place")
assert(not workspace:FindFirstChild("SweetPotatoRipeStudies"), "Remove previous study first")
local Kit = require(game.ReplicatedStorage.PlantKit)
local V, C = Vector3.new, Color3.fromRGB
local folder = Instance.new("Folder")
folder.Name = "SweetPotatoRipeStudies"
folder:SetAttribute("OriginalCamera", workspace.CurrentCamera.CFrame)
folder:SetAttribute("OriginalFocus", workspace.CurrentCamera.Focus)
local GREEN, LIGHT = C(67, 139, 69), C(103, 169, 80)
local STEM, REDSTEM = C(105, 146, 65), C(145, 78, 91)
local SKIN, FACET = C(166, 76, 91), C(194, 100, 108)
local CREAM, PINK, PURPLE, DARK = C(253, 237, 246), C(214, 156, 203), C(155, 63, 150), C(79, 27, 88)
local function block(m, name, size, cf, color, role, slot, class)
 return Kit.proxyPart(m, name, size, cf, color, if role == "Foliage" then "Studs" else "StudsSmall", role, slot, class)
end
local function rod(m, b, a, z, w, color, role, slot)
 return Kit.proxyRod(m, b, "Stem", a, z, w, color, role or "Structure", slot)
end
local function path(m, b, pts, width, role)
 for i = 1, #pts - 1 do rod(m, b, pts[i], pts[i+1], width, if i == 1 then REDSTEM else STEM, role) end
end
-- Single heart-shaped blade: two basal lobes leave a notch; paired thin wedges taper to one point.
-- The local +Z axis runs from the petiole into the blade. No compound leaf pairs like Potato.
local function leaf(m, b, node, hinge, length, width, yaw, tilt, index)
 rod(m, b, node, hinge, 0.065, REDSTEM, "Foliage")
 local cf = b * CFrame.new(hinge) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(-tilt, 0, 0)
 local col = if index % 3 == 0 then LIGHT else GREEN
 for side = -1, 1, 2 do
  block(m,"HeartLobe",V(width*0.54,0.055,length*0.47),cf*CFrame.new(side*width*0.20,0.004*side,length*0.28)*CFrame.Angles(0,side*0.23,0),col,"Foliage")
  -- Triangle apex and the corresponding half of its base, converted to a thin wedge frame.
  local apex,corner=V(0,0,length),V(side*width*0.5,0,length*0.4)
  local wedge=cf*CFrame.fromMatrix((apex+corner)/2,Vector3.yAxis*-side,Vector3.zAxis,Vector3.xAxis*-side)
  block(m,"HeartTip",V(0.055,length*0.60,width*0.50),wedge,col,"Foliage",nil,"WedgePart")
 end
 block(m,"LeafVein",V(0.025,0.025,length*0.76),cf*CFrame.new(0,0.044,length*0.51),C(138,177,97),"Foliage")
end
-- Polygonal trumpet, widening from the stalk to a pale rim. Two nested rings communicate depth.
local function flower(m,b,node,at,yaw,size)
 rod(m,b,node,at,0.065,STEM,"Flower")
 local cf = b*CFrame.new(at)*CFrame.Angles(0,yaw,0)*CFrame.Angles(math.rad(33),0,0)
 for i=0,4 do
  local f=cf*CFrame.Angles(0,0,i*math.pi*0.4)
  block(m,"FlowerFunnel",V(size*0.37,size*0.42,size*0.45),f*CFrame.new(0,size*0.15,size*0.10)*CFrame.Angles(-0.58,0,0),PURPLE,"Flower")
  block(m,"PaleRim",V(size*0.59,size*0.34,0.065),f*CFrame.new(0,size*0.35,size*0.36)*CFrame.Angles(-0.10,0,0),CREAM,"Flower")
 end
 block(m,"Throat",V(size*0.29,size*0.29,0.055),cf*CFrame.new(0,0,size*0.28),DARK,"Flower")
 block(m,"Pollen",V(size*0.065,size*0.12,0.06),cf*CFrame.new(0,-size*0.025,size*0.32),PINK,"Flower")
end
-- Tapered storage root, largely below soil; several decreasing sections read as long red shoulders.
local function root(m,b,at,yaw,length,width,slot)
 local cf=b*CFrame.new(at)*CFrame.Angles(0,yaw,0)*CFrame.Angles(0,0,1.15)
 local slices={{-0.16,0.32,0.54},{0.08,0.34,0.88},{0.34,0.36,1},{0.60,0.30,0.70},{0.81,0.18,0.32}}
 for j,s in slices do
  block(m,"StorageRoot",V(width*s[3],length*s[2],width*s[3]*0.74),cf*CFrame.new(0,-length*s[1],0)*CFrame.Angles(0,0.18,0),if j%2==0 then FACET else SKIN,"Fruit",slot)
 end
end
local function foliage(m,b,pts,leafSize,idx)
 path(m,b,pts,0.095)
 for j=2,#pts do
  local p=pts[j]
  local yaw=math.atan2(p.X,p.Z)+(if j%2==0 then -0.72 else 0.60)
  local direction=V(math.sin(yaw),0,math.cos(yaw))
  local hinge=p+direction*0.16+V(0,0.16,0)
  leaf(m,b,p,hinge,leafSize*(if j==#pts then 0.85 else 1),leafSize*0.82,yaw,0.25+(j%2)*0.18,idx+j)
 end
end
local studies={
 {name="A_SpreadingPatch",build=function(m,b)
  for i=1,4 do
   local t=(i-1)*math.pi/2+0.40
   local function p(r,y,twist) return V(math.sin(t+(twist or 0))*r,y,math.cos(t+(twist or 0))*r) end
   foliage(m,b,{V(0,0.09,0),p(0.40,0.65),p(0.90,0.76,0.20),p(1.22,0.36,0.45)},1.02,i)
  end
  root(m,b,V(-0.54,0.12,0.79),-2.50,1.04,0.50,1)
  root(m,b,V(0.32,0.12,0.79),-1.50,1.22,0.56,2)
  root(m,b,V(0.86,0.10,0.31),-0.10,0.90,0.45,3)
  flower(m,b,V(-0.40,0.65,0.36),V(-0.60,1.04,0.66),-0.35,0.68)
  flower(m,b,V(0.39,0.76,-0.82),V(0.70,1.12,-0.55),0.50,0.59)
 end},
 {name="B_LiftedCascade",build=function(m,b)
  local specs={{-1.0,1.75},{0.70,2.05},{2.50,1.68},{4.10,1.45}}
  for i,s in specs do
   local t,h=s[1],s[2]
   local function p(r,y,twist) return V(math.sin(t+(twist or 0))*r,y,math.cos(t+(twist or 0))*r) end
   foliage(m,b,{V(0,0.10,0),p(0.25,h*0.50),p(0.73,h),p(1.22,h*0.56,0.22)},1.00,i)
  end
  root(m,b,V(-0.52,0.21,0.69),-2.50,1.20,0.55,1)
  root(m,b,V(0.29,0.18,0.74),-1.50,1.40,0.61,2)
  root(m,b,V(0.76,0.13,0.35),-0.10,0.96,0.48,3)
  flower(m,b,V(0.47,1.45,0.56),V(0.88,1.81,0.86),0.40,0.72)
  flower(m,b,V(-0.61,1.50,0.34),V(-0.94,1.85,0.56),-0.50,0.63)
 end},
 {name="C_TrainedFan",build=function(m,b)
  for i=-1,1 do
   rod(m,b,V(i*0.20,0,-0.40),V(i*1.05,4.18,-0.40),0.10,C(173,143,94),"Support")
  end
  for j=1,2 do rod(m,b,V(-j*0.43,j*1.42,-0.40),V(j*0.43,j*1.42,-0.40),0.075,C(173,143,94),"Support") end
  for i=-1,1 do
   local pts={V(i*0.15,0.10,-0.24),V(i*0.34,1.05,-0.20),V(i*0.57+0.10,2.05,-0.24),V(i*0.78-0.10,3.04,-0.20),V(i*0.96,3.83,-0.20)}
   path(m,b,pts,0.09)
   for j=2,5 do
    local yaw=(if (i+j)%2==0 then -1.1 else 1.1)
    leaf(m,b,pts[j],pts[j]+V(math.sin(yaw)*0.15,0.14,0.15),1.02,0.90,yaw,0.65,i+j)
   end
   block(m,"VineTie",V(0.18,0.035,0.17),b*CFrame.new(pts[3]),C(198,175,125),"Support")
  end
  root(m,b,V(-0.48,0.14,0.46),-2.50,1.06,0.51,1)
  root(m,b,V(0.29,0.16,0.71),-1.50,1.24,0.58,2)
  root(m,b,V(0.81,0.11,0.19),-0.10,0.92,0.45,3)
  flower(m,b,V(-0.57,2.05,-0.24),V(-0.80,2.43,0.29),-0.25,0.69)
  flower(m,b,V(0.68,3.04,-0.20),V(0.79,3.25,0.30),0.40,0.62)
 end},
}
local y0=1000
block(folder,"GrassContext",V(26,0.5,9),CFrame.new(-1,y0-0.45,0),C(103,149,75))
local counts={}
for i,s in studies do
 local base=CFrame.new((i-2)*6.3,y0,0)
 block(folder,"Soil_"..i,V(5.5,0.30,5.5),base*CFrame.new(0,-0.15,0),C(88,66,48))
 local m=Instance.new("Model")
 m.Name=s.name
 s.build(m,base)
 local radius,top=0,0
 for _,p in m:GetChildren() do
  for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
   local v=base:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size*V(x,y,z)/2))
   radius=math.max(radius,V(v.X,0,v.Z).Magnitude)
   top=math.max(top,v.Y)
  end end end
 end
 assert(radius<=2.4,s.name.." exceeds radius: "..radius)
 assert(#m:GetChildren()<=180,s.name.." exceeds study budget")
 counts[s.name]={parts=#m:GetChildren(),height=math.round(top*100)/100,radius=math.round(radius*100)/100}
 m.Parent=folder
end
local description=Instance.new("HumanoidDescription")
local ok,avatar=pcall(function() return game.Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R15) end)
description:Destroy()
if not ok then folder:Destroy(); error("Avatar reference failed: "..tostring(avatar)) end
avatar.Name="ReferenceAvatar"
avatar:PivotTo(CFrame.new(-10.25,y0+3,0.35)*CFrame.Angles(0,math.pi,0))
local minY=math.huge
for _,p in avatar:GetDescendants() do
 if p:IsA("BasePart") then
  minY=math.min(minY,p.Position.Y-p.Size.Y/2)
  p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery,p.CastShadow=true,false,false,false,false
 end
end
avatar:PivotTo(avatar:GetPivot()+V(0,y0-minY,0))
avatar.Humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
avatar.Parent=folder
counts.avatarHeight=math.round(avatar:GetExtentsSize().Y*100)/100
folder.Parent=workspace
return game.HttpService:JSONEncode(counts)
