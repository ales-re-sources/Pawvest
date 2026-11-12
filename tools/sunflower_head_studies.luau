-- CG20a head revision: selected A1 stem/foliage, three alternative crowns. Static Studio Edit study only.
assert(game:GetService("RunService"):IsStudio() and game.PlaceId==73033440513091,"Pawvest Studio only")
assert(not workspace:FindFirstChild("SunflowerHeadStudies"),"Remove previous study first")
local Kit=require(game.ReplicatedStorage.PlantKit)
local V,C=Vector3.new,Color3.fromRGB
local folder=Instance.new("Folder")
folder.Name="SunflowerHeadStudies"
folder:SetAttribute("OriginalCamera",workspace.CurrentCamera.CFrame)
folder:SetAttribute("OriginalFocus",workspace.CurrentCamera.Focus)
folder:SetAttribute("OriginalFov",workspace.CurrentCamera.FieldOfView)
folder:SetAttribute("OriginalCameraType",workspace.CurrentCamera.CameraType.Name)
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
-- Broad ray with an ellipsoid shoulder and two wedges forming a tapered tip.
local function ray(m,cf,angle,radius,len,width,bend,tone,id)
    local f=cf*CFrame.Angles(0,0,angle)*CFrame.new(0,radius,-0.02)*CFrame.Angles(bend,0,0)
    local p=part(m,"PetalShoulder"..id,V(width,len*0.66,0.075),f*CFrame.new(0,len*0.27,0),tone,"Flower",Enum.PartType.Ball)
    p.MaterialVariant=""
    local tip=f*CFrame.new(0,len*0.49,-0.01)*CFrame.Angles(0.18,0,0)
    for side=-1,1,2 do
        local a=V(0,len*0.51,0)
        local c=V(side*width*0.40,0,0)
        local frame=tip*CFrame.fromMatrix((a+c)/2,Vector3.zAxis*side,Vector3.yAxis,-Vector3.xAxis*side)
        local q=Kit.proxyPart(m,"PetalPoint"..id,V(0.055,len*0.51,width*0.40),frame,tone:Lerp(PALE,0.10),"","Flower",1,"WedgePart")
    end
end
local function head(m,b,at,s)
    local random=Random.new(701) -- same crown irregularity sequence for comparison
    local diameter=s.diameter
    local cf=b*CFrame.new(at)*CFrame.Angles(s.pitch,-0.10,-0.07)
    local function soft(name,size,frame,tone,role)
        local p=part(m,name,size,frame,tone,role,Enum.PartType.Ball)
        p.MaterialVariant=""
        if role=="Fruit" or role=="Flower" then p:SetAttribute("FruitSlot",1) end
        return p
    end
    soft("HeadBack",V(diameter*1.03,diameter*1.03,0.29),cf*CFrame.new(0,0,-0.12),STEM,"Fruit")
    soft("SeedDisk",V(diameter,diameter,0.32),cf,C(104,67,33),"Fruit")
    soft("DiskCentre",V(diameter*0.91,diameter*0.91,0.23),cf*CFrame.new(0,0,0.075),C(75,48,27),"Fruit")
    for j=1,s.seeds do
        local a=j*2.399963229728653
        local r=diameter*0.425*math.sqrt(j/s.seeds)
        local size=diameter*0.060*random:NextNumber(0.85,1.12)
        local z=0.125+0.075*math.sqrt(math.max(0,1-(r/(diameter*0.5))^2))
        soft("SeedTexture"..j,V(size*0.77,size,0.040),cf*CFrame.new(math.cos(a)*r,math.sin(a)*r,z)*CFrame.Angles(0,0,a),C(105,70,34):Lerp(C(166,117,53),random:NextNumber(0.10,0.65)),"Fruit")
    end
    for layer=1,s.layers do
        local count=if layer==1 then s.rays else s.inner
        for j=1,count do
            local a=(j-1)*math.pi*2/count+(if layer==2 then math.pi/count else 0)+random:NextNumber(-0.04,0.04)
            local len=s.ray*random:NextNumber(0.87,1.11)*(if layer==2 then 0.77 else 1)
            local width=s.width*random:NextNumber(0.86,1.12)
            local bend=s.bend+random:NextNumber(-0.09,0.14)
            local f=if layer==2 then cf*CFrame.new(0,0,0.045) else cf
            ray(m,f,a,diameter*0.43,len,width,bend,GOLD:Lerp(AMBER,random:NextNumber(0,0.27)),layer.."_"..j)
        end
    end
    for j=1,7 do
        local f=cf*CFrame.Angles(0,0,j*math.pi*2/7)
        soft("GreenBract"..j,V(diameter*0.16,diameter*0.35,0.07),f*CFrame.new(0,diameter*0.37,-0.24)*CFrame.Angles(-0.35,0,0),LEAF,"Structure")
    end
end
local studies={
    {name="H1_BroadPointed",diameter=1.78,ray=0.99,rays=18,layers=1,width=0.39,bend=0.09,pitch=0.13,seeds=42},
    {name="H2_LayeredGolden",diameter=1.68,ray=1.00,rays=17,inner=12,layers=2,width=0.43,bend=0.18,pitch=0.13,seeds=42},
    {name="H3_NoddingSeedHead",diameter=2.18,ray=0.66,rays=19,layers=1,width=0.34,bend=-0.25,pitch=0.43,seeds=57},
}
for _,s in studies do
    -- Identical A1 structure, size and leaf seed in every cell.
    s.height,s.leaves,s.phase,s.advance,s.leaf,s.widthLeaf=5.72,9,0.30,2.39,1.31,0.96
    s.lean=V(0.16,0,0.10)
end
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
	local random=Random.new(90)
	local quadrants={false,false,false,false}
	for j=1,s.leaves do
		local t=0.11+(j-1)*0.74/(s.leaves-1)+random:NextNumber(-0.018,0.018)
		local yaw=s.phase+(j-1)*s.advance+random:NextNumber(-0.16,0.16)
		local quadrant=math.floor((yaw%(math.pi*2))/(math.pi/2))+1; quadrants[quadrant]=true
		local size=if j==s.leaves then 0.72 elseif j==1 then 0.83 else random:NextNumber(0.84,1.04)
		leaf(m,base,along(path,t),yaw,random:NextNumber(0.32,0.48),s.leaf*size,s.widthLeaf*size,
			if j<=3 then random:NextNumber(-0.28,-0.06) else random:NextNumber(0.05,0.30),random:NextNumber(-0.24,0.24),
			LEAF:Lerp(LIGHT,random:NextNumber(0.05,0.65)),j)
	end
	for _,occupied in quadrants do assert(occupied,"Leaves must occupy every quadrant") end
	local top=path[#path]
	rod(m,base,"Neck",top,top+V(0,0.17,0.13),0.15,STEM)
	head(m,base,top+V(0,0.25,0.16),s)
	local radius,height=0,0
	for _,p in m:GetChildren() do
		for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
			local v=base:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size*V(x,y,z)/2))
			radius=math.max(radius,V(v.X,0,v.Z).Magnitude); height=math.max(height,v.Y)
		end end end
	end
	if radius>2.4 or #m:GetChildren()>240 then
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
