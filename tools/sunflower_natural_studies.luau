-- CG20a revision: three natural refinements of the tall single-headed A. Static Studio Edit study only.
assert(game:GetService("RunService"):IsStudio() and game.PlaceId==73033440513091,"Pawvest Studio only")
assert(not workspace:FindFirstChild("SunflowerNaturalStudies"),"Remove previous study first")
local Kit=require(game.ReplicatedStorage.PlantKit)
local V,C=Vector3.new,Color3.fromRGB
local folder=Instance.new("Folder")
folder.Name="SunflowerNaturalStudies"
folder:SetAttribute("OriginalCamera",workspace.CurrentCamera.CFrame)
folder:SetAttribute("OriginalFocus",workspace.CurrentCamera.Focus)
local STEM,LEAF,LIGHT=C(91,137,57),C(59,121,56),C(89,148,64)
local GOLD,PALE,AMBER=C(246,187,28),C(255,211,53),C(227,157,24)
local DISK,DARK,SEED=C(88,55,31),C(59,40,25),C(125,88,43)
local function part(m,name,size,cf,color,role,shape)
	local p=Kit.proxyPart(m,name,size,cf,color,if role=="Foliage" then "Studs" else "StudsSmall",role)
	if shape==Enum.PartType.Ball then
		-- Built-in sphere mesh preserves the deliberately flattened ellipsoid on every axis.
		local mesh=Instance.new("SpecialMesh")
		mesh.MeshType=Enum.MeshType.Sphere
		mesh.Parent=p
	elseif shape then p.Shape=shape end
	return p
end
local function rod(m,b,name,a,z,w,color,role)
	return Kit.proxyRod(m,b,name,a,z,w,color,role or "Structure")
end
local function along(path,t)
	local f=math.clamp(t,0,1)*(#path-1)
	local i=math.min(#path-1,math.floor(f)+1)
	return path[i]:Lerp(path[i+1],f-(i-1))
end
-- A curved, broad ovate blade: rounded shoulders, a narrower folded end and a real pointed tip.
-- Leaf normals follow their radial direction and roll; they are never forced into a front-facing fan.
local function leaf(m,b,node,yaw,petiole,len,width,rise,roll,tone,id)
	local radial=V(math.sin(yaw),0,math.cos(yaw))
	local elbow=node+radial*petiole*0.58+V(0,0.22,0)
	local hinge=node+radial*petiole+V(0,0.25,0)
	rod(m,b,"PetioleBase"..id,node,elbow,0.09,STEM,"Foliage")
	rod(m,b,"PetioleTip"..id,elbow,hinge,0.075,STEM,"Foliage")
	local blade=(radial+V(0,rise,0)).Unit
	local n=(Vector3.yAxis-blade*blade.Y).Unit
	local cf=b*CFrame.fromMatrix(hinge,n:Cross(blade),n,blade)*CFrame.Angles(0,0,roll)
	part(m,"LeafShoulders"..id,V(width*0.83,0.075,len*0.56),cf*CFrame.new(0,0,len*0.28),tone,"Foliage",Enum.PartType.Ball)
	local endFrame=cf*CFrame.new(0,0,len*0.44)*CFrame.Angles(0.24,0,0)
	part(m,"LeafBlade"..id,V(width,0.07,len*0.55),endFrame*CFrame.new(0,0,len*0.17),tone:Lerp(LIGHT,0.12),"Foliage",Enum.PartType.Ball)
	local tipFrame=endFrame*CFrame.new(0,0,len*0.25)
	for side=-1,1,2 do
		local apex,corner=V(0,0,len*0.36),V(side*width*0.31,0,0)
		local frame=tipFrame*CFrame.fromMatrix((apex+corner)/2,Vector3.yAxis*side,Vector3.zAxis,Vector3.xAxis*side)
		Kit.proxyPart(m,"LeafPoint"..id,V(0.052,len*0.36,width*0.31),frame,tone,"Studs","Foliage",nil,"WedgePart")
	end
	rod(m,cf,"LeafVein"..id,V(0,0.045,len*0.06),V(0,0.045,len*0.65),0.026,tone:Lerp(C(159,181,87),0.40),"Foliage")
end
local function head(m,b,at,diameter,length,rays,seedCount,yaw,pitch,roll,seed)
	local random=Random.new(seed)
	local cf=b*CFrame.new(at)*CFrame.Angles(pitch,yaw,roll)
	-- Soft convex seed disk and a tucked-away green back, rather than an exposed green wheel rim.
	part(m,"HeadBack",V(diameter*1.02,diameter*1.02,0.23),cf*CFrame.new(0,0,-0.08),STEM,"Fruit",Enum.PartType.Ball)
	part(m,"SeedDisk",V(diameter,diameter,0.28),cf,DISK,"Fruit",Enum.PartType.Ball)
	part(m,"DiskCentre",V(diameter*0.92,diameter*0.92,0.13),cf*CFrame.new(0,0,0.075),DARK,"Fruit",Enum.PartType.Ball)
	for j=1,seedCount do
		local angle=j*2.399963229728653
		local r=diameter*0.43*math.sqrt(j/seedCount)
		local size=diameter*0.047*random:NextNumber(0.8,1.15)
		local z=0.10+0.045*math.sqrt(math.max(0,1-(r/(diameter*0.5))^2))
		part(m,"SeedTexture",V(size,size*0.77,0.028),cf*CFrame.new(math.cos(angle)*r,math.sin(angle)*r,z+0.018)*CFrame.Angles(0,0,angle),DISK:Lerp(SEED,random:NextNumber(0.20,0.60)),"Fruit",Enum.PartType.Ball)
	end
	for j=1,rays do
		local angle=(j-1)*math.pi*2/rays+random:NextNumber(-0.035,0.035)
		local len=length*random:NextNumber(0.80,1.15)
		local width=diameter*math.pi/rays*random:NextNumber(1.28,1.62)
		local bend=random:NextNumber(-0.12,0.35)
		local ray=cf*CFrame.Angles(0,0,angle)*CFrame.new(0,diameter*0.43,-0.015)*CFrame.Angles(bend,0,random:NextNumber(-0.13,0.13))
		local tone=GOLD:Lerp(AMBER,random:NextNumber(0,0.35))
		part(m,"RayBase",V(width,len*0.70,0.065),ray*CFrame.new(0,len*0.28,0),tone,"Flower",Enum.PartType.Ball)
		part(m,"RayTip",V(width*0.72,len*0.57,0.054),ray*CFrame.new(0,len*0.70,-len*0.055)*CFrame.Angles(0.22,0,random:NextNumber(-0.12,0.12)),tone:Lerp(PALE,0.30),"Flower",Enum.PartType.Ball)
	end
	for j=1,5 do
		local f=cf*CFrame.Angles(0,0,j*math.pi*0.4)
		part(m,"GreenBract",V(diameter*0.15,diameter*0.31,0.07),f*CFrame.new(0,diameter*0.35,-0.23)*CFrame.Angles(-0.35,0,0),LEAF,"Structure",Enum.PartType.Ball)
	end
end
local studies={
	{name="A1_SpiralClassic",height=5.72,leaves=9,phase=0.30,advance=2.39,leaf=1.31,width=0.96,
		diameter=1.89,ray=0.89,rays=24,seeds=21,lean=V(0.16,0,0.10),yaw=-0.10,pitch=0.13,roll=-0.07},
	{name="A2_OpenField",height=5.93,leaves=7,phase=1.12,advance=2.27,leaf=1.20,width=0.84,
		diameter=1.80,ray=0.96,rays=22,seeds=17,lean=V(-0.25,0,0.20),yaw=0.14,pitch=0.19,roll=0.10},
	{name="A3_LushCrown",height=5.63,leaves=10,phase=-0.40,advance=2.43,leaf=1.39,width=1.04,
		diameter=1.97,ray=0.88,rays=26,seeds=21,lean=V(0.24,0,0.19),yaw=-0.18,pitch=0.26,roll=-0.10},
}
local y0=1500
part(folder,"GrassContext",V(26,0.50,10),CFrame.new(-1,y0-0.45,0),C(103,149,75))
local counts={}
for i,s in studies do
	local base=CFrame.new((i-2)*6.5,y0,0)
	part(folder,"Soil"..i,V(5.5,0.30,5.5),base*CFrame.new(0,-0.15,0),C(88,66,48))
	local m=Instance.new("Model"); m.Name=s.name
	local path={V(0,0,0)}
	for j=1,5 do
		local t=j/5
		local p=s.lean*t*t+V(math.sin(t*5.7)*0.12,s.height*t,math.sin(t*4.1)*0.08)
		path[j+1]=p
		rod(m,base,"Stem"..j,path[j],p,0.23-j*0.016,STEM)
	end
	local random=Random.new(71+i*19)
	local quadrants={false,false,false,false}
	for j=1,s.leaves do
		local t=0.11+(j-1)*0.74/(s.leaves-1)+random:NextNumber(-0.018,0.018)
		local yaw=s.phase+(j-1)*s.advance+random:NextNumber(-0.16,0.16)
		local quadrant=math.floor((yaw%(math.pi*2))/(math.pi/2))+1; quadrants[quadrant]=true
		local size=if j==s.leaves then 0.72 elseif j==1 then 0.83 else random:NextNumber(0.84,1.04)
		leaf(m,base,along(path,t),yaw,random:NextNumber(0.32,0.48),s.leaf*size,s.width*size,
			if j<=3 then random:NextNumber(-0.28,-0.06) else random:NextNumber(0.05,0.30),random:NextNumber(-0.24,0.24),
			LEAF:Lerp(LIGHT,random:NextNumber(0.05,0.65)),j)
	end
	for _,occupied in quadrants do assert(occupied,"Leaves must occupy every quadrant") end
	local top=path[#path]
	rod(m,base,"Neck",top,top+V(0,0.17,0.13),0.15,STEM)
	head(m,base,top+V(0,0.25,0.16),s.diameter,s.ray,s.rays,s.seeds,s.yaw,s.pitch,s.roll,700+i)
	local radius,height=0,0
	for _,p in m:GetChildren() do
		for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
			local v=base:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size*V(x,y,z)/2))
			radius=math.max(radius,V(v.X,0,v.Z).Magnitude); height=math.max(height,v.Y)
		end end end
	end
	if radius>2.4 or #m:GetChildren()>180 then
		local message=s.name.." exceeds study bounds/budget: "..radius.." / "..#m:GetChildren()
		m:Destroy(); folder:Destroy(); error(message)
	end
	local meshes=0
	for _,p in m:GetDescendants() do if p:IsA("SpecialMesh") then meshes+=1 end end
	counts[s.name]={parts=#m:GetChildren(),meshes=meshes,height=math.round(height*100)/100,radius=math.round(radius*100)/100,leaves=s.leaves,allQuadrants=true}
	m.Parent=folder
end
local description=Instance.new("HumanoidDescription")
local ok,avatar=pcall(function() return game.Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R15) end)
description:Destroy()
if not ok then folder:Destroy(); error("Avatar failed: "..tostring(avatar)) end
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
