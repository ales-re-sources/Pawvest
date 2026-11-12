-- CG20a: disposable static mature sunflower studies, Studio Edit. No scripts, remotes or saved-data edits.
assert(game:GetService("RunService"):IsStudio(),"Studio only")
assert(game.PlaceId==73033440513091,"Wrong place")
assert(not workspace:FindFirstChild("SunflowerRipeStudies"),"Remove previous study first")
local Kit=require(game.ReplicatedStorage.PlantKit)
local V,C=Vector3.new,Color3.fromRGB
local folder=Instance.new("Folder")
folder.Name="SunflowerRipeStudies"
folder:SetAttribute("OriginalCamera",workspace.CurrentCamera.CFrame)
folder:SetAttribute("OriginalFocus",workspace.CurrentCamera.Focus)
local STEM,LEAF,LIGHT=C(91,137,57),C(60,121,57),C(88,149,66)
local GOLD,PALE,AMBER=C(248,189,31),C(255,216,59),C(222,148,23)
local DISK,DARK,SEED=C(91,56,30),C(54,39,25),C(149,105,53)
local function block(m,name,size,cf,color,role,slot,class,variant)
	return Kit.proxyPart(m,name,size,cf,color,variant or "StudsSmall",role,slot,class)
end
local function rod(m,b,name,a,z,w,color,role)
	return Kit.proxyRod(m,b,name,a,z,w,color,role or "Structure")
end
local function leaf(m,b,node,hinge,len,width,side,tone,index)
	rod(m,b,"Petiole"..index,node,hinge,0.10,STEM,"Foliage")
	local d=V(side*0.93,0.26+(index%3)*0.10,0.12).Unit
	local n0=V(0,0.42,1)
	local n=(n0-d*n0:Dot(d)).Unit
	local cf=b*CFrame.fromMatrix(hinge,n:Cross(d),n,d)
	block(m,"LeafCentre"..index,V(width*0.62,0.065,len*0.64),cf*CFrame.new(0,0,len*0.37),tone,"Foliage",nil,nil,"Studs")
	for s=-1,1,2 do
		block(m,"LeafShoulder"..index,V(width*0.51,0.060,len*0.46),cf*CFrame.new(s*width*0.22,s*0.008,len*0.26)*CFrame.Angles(0,s*0.35,0),tone,"Foliage",nil,nil,"Studs")
		local apex,corner=V(0,0,len),V(s*width*0.5,0,len*0.4)
		local tip=cf*CFrame.fromMatrix((apex+corner)/2,Vector3.yAxis*s,Vector3.zAxis,Vector3.xAxis*s)
		block(m,"LeafPoint"..index,V(0.06,len*0.60,width*0.5),tip,tone,"Foliage",nil,"WedgePart","Studs")
	end
	block(m,"LeafVein"..index,V(0.035,0.025,len*0.83),cf*CFrame.new(0,0.05,len*0.46),tone:Lerp(C(156,180,86),0.48),"Foliage")
end
local function cylinder(m,name,cf,diameter,depth,color,role,slot)
	local p=block(m,name,V(depth,diameter,diameter),cf*CFrame.Angles(0,math.pi/2,0),color,role,slot)
	p.Shape=Enum.PartType.Cylinder
	return p
end
local function head(m,b,at,diameter,rayLength,rays,seedCount,yaw,pitch,slot)
	-- +Z is the face. A backed disk reads from the side, with small warm seed facets over its dark centre.
	local cf=b*CFrame.new(at)*CFrame.Angles(pitch,yaw,0)
	cylinder(m,"HeadBack",cf*CFrame.new(0,0,-0.09),diameter*1.08,0.20,STEM,"Fruit",slot)
	cylinder(m,"SeedDisk",cf,diameter,0.23,DISK,"Fruit",slot)
	cylinder(m,"DiskCentre",cf*CFrame.new(0,0,0.125),diameter*0.86,0.035,DARK,"Fruit",slot)
	for j=1,seedCount do
		local angle=j*2.399963229728653
		local r=diameter*0.43*math.sqrt(j/seedCount)
		local size=diameter*(if seedCount>12 then 0.055 else 0.07)
		block(m,"SeedFacet",V(size,size*0.75,0.042),cf*CFrame.new(math.cos(angle)*r,math.sin(angle)*r,0.16)*CFrame.Angles(0,0,angle),if j%3==0 then SEED else DISK:Lerp(SEED,0.45),"Fruit",slot)
	end
	for j=1,rays do
		local theta=(j-1)*math.pi*2/rays
		local petal=cf*CFrame.Angles(0,0,theta)*CFrame.new(0,diameter*0.42,-0.055)
		local length=rayLength*(0.94+0.06*(j%3))
		local width=diameter*math.pi/rays*1.25
		block(m,"RayBase",V(width, length*0.48,0.065),petal*CFrame.new(0,length*0.24,0)*CFrame.Angles(-0.10,0,0),if j%2==0 then GOLD else AMBER,"Flower")
		local start=length*0.30
		for side=-1,1,2 do
			local apex,corner=V(0,length,0),V(side*width*0.50,start,0)
			local wedge=petal*CFrame.fromMatrix((apex+corner)/2,Vector3.zAxis*-side,Vector3.yAxis,Vector3.xAxis*side)
			block(m,"RayPoint",V(0.065,length-start,width*0.50),wedge,if j%2==0 then PALE else GOLD,"Flower",nil,"WedgePart")
		end
	end
	local bracts=if slot==1 then 5 else 3
	for j=1,bracts do
		local f=cf*CFrame.Angles(0,0,j*math.pi*2/bracts)
		block(m,"GreenBract",V(diameter*0.16,diameter*0.35,0.08),f*CFrame.new(0,diameter*0.36,-0.22)*CFrame.Angles(-0.25,0,0),LEAF,"Structure")
	end
end
local studies={
	{name="A_TallClassic",height=5.70,lean=0.10,leaves=7,leaf=1.28,width=1.02,
		build=function(m,b,node)
			head(m,b,node(1)+V(0,0.28,0.12),1.90,0.78,20,17,-0.08,0.12,1)
		end},
	{name="B_HeavySeedHead",height=6.35,lean=0.17,leaves=8,leaf=1.38,width=1.10,
		build=function(m,b,node)
			local top=node(1)
			rod(m,b,"NoddingNeck",top,top+V(0.10,0.12,0.30),0.19,STEM)
			head(m,b,top+V(0.10,0.24,0.35),2.45,0.77,24,25,0.08,0.32,1)
		end},
	{name="C_BranchingGarden",height=4.95,lean=-0.08,leaves=6,leaf=1.18,width=0.98,
		build=function(m,b,node)
			local fork=node(0.63)
			rod(m,b,"BranchLeft",fork,V(-0.76,4.15,0.10),0.13,STEM)
			rod(m,b,"BranchLeftTip",V(-0.76,4.15,0.10),V(-1.06,4.65,0.14),0.11,STEM)
			rod(m,b,"BranchRight",node(0.75),V(0.94,4.06,0.22),0.12,STEM)
			head(m,b,node(1)+V(0,0.25,0.10),1.50,0.64,12,9,-0.04,0.10,1)
			head(m,b,V(-1.06,4.65,0.14),1.08,0.46,8,9,-0.18,0.18,2)
			head(m,b,V(0.94,4.06,0.22),1.10,0.48,8,9,0.22,0.24,3)
		end},
}
local y0=1500
block(folder,"GrassContext",V(26,0.50,10),CFrame.new(-1,y0-0.45,0),C(103,149,75))
local counts={}
for i,s in studies do
	local base=CFrame.new((i-2)*6.5,y0,0)
	block(folder,"Soil"..i,V(5.5,0.30,5.5),base*CFrame.new(0,-0.15,0),C(88,66,48),nil,nil,nil,"Studs")
	local m=Instance.new("Model"); m.Name=s.name
	local function node(t) return V(s.lean*t*t,s.height*t,-0.06*t) end
	for j=1,4 do rod(m,base,"Stem"..j,node((j-1)/4),node(j/4),0.24-(j-1)*0.022,STEM) end
	for j=1,s.leaves do
		local t=0.13+(j-1)*0.69/(s.leaves-1)
		local side=if j%2==0 then 1 else -1
		local at=node(t)
		local hinge=at+V(side*0.34,0.21,0.07+(j%3)*0.06)
		local tone=if j%3==0 then LIGHT else LEAF
		if i==2 and j<=2 then tone=C(175,161,66) end
		leaf(m,base,at,hinge,s.leaf*(if j==s.leaves then 0.82 else 1),s.width,side,tone,j)
	end
	s.build(m,base,node)
	local radius,top=0,0
	for _,p in m:GetChildren() do
		for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
			local v=base:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size*V(x,y,z)/2))
			radius=math.max(radius,V(v.X,0,v.Z).Magnitude); top=math.max(top,v.Y)
		end end end
	end
	if radius>2.4 or #m:GetChildren()>180 then
		local message=s.name.." exceeds study bounds/budget: "..radius.." / "..#m:GetChildren()
		m:Destroy(); folder:Destroy(); error(message)
	end
	counts[s.name]={parts=#m:GetChildren(),height=math.round(top*100)/100,radius=math.round(radius*100)/100}
	m.Parent=folder
end
local description=Instance.new("HumanoidDescription")
local ok,avatar=pcall(function() return game.Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R15) end)
description:Destroy()
if not ok then folder:Destroy(); error("Avatar reference failed: "..tostring(avatar)) end
avatar.Name="ReferenceAvatar"
avatar:PivotTo(CFrame.new(-10.45,y0+3,0.35)*CFrame.Angles(0,math.pi,0))
local minY=math.huge
for _,p in avatar:GetDescendants() do if p:IsA("BasePart") then
	minY=math.min(minY,p.Position.Y-p.Size.Y/2)
	p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery,p.CastShadow=true,false,false,false,false
end end
avatar:PivotTo(avatar:GetPivot()+V(0,y0-minY,0))
avatar.Humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
avatar.Parent=folder
counts.avatarHeight=math.round(avatar:GetExtentsSize().Y*100)/100
folder.Parent=workspace
return game.HttpService:JSONEncode(counts)
