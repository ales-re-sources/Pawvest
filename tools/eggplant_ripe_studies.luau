-- CG16a: three disposable static mature studies, Studio Edit context. No scripts, remotes or profile writes.
-- Run with execute_luau, capture, then destroy workspace.EggplantRipeStudies and restore the camera.
assert(game:GetService("RunService"):IsStudio(), "Studio only")
assert(not workspace:FindFirstChild("EggplantRipeStudies"), "Remove previous study first")
local V, C = Vector3.new, Color3.fromRGB
local folder = Instance.new("Folder")
folder.Name = "EggplantRipeStudies"
local STEM, PURPLESTEM = C(104, 146, 65), C(100, 73, 100)
local LEAF, LEAF2 = C(77, 132, 62), C(96, 151, 75)
local SKIN, FACET = C(57, 20, 84), C(83, 30, 113)
local CALYX, PETAL = C(106, 153, 58), C(179, 102, 220)
local function block(m, name, size, cf, color, role, slot, variant)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Material, p.MaterialVariant = Enum.Material.Plastic, variant or "StudsSmall"
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	if role then p:SetAttribute("PlantRole", role) end
	if slot then p:SetAttribute("FruitSlot", slot) end
	p.Parent = m
	return p
end
local function rod(m, b, a, z, w, color, role, slot)
	local d = z - a
	local up = if math.abs(d.Unit.Y) > 0.98 then Vector3.xAxis else Vector3.yAxis
	return block(m, role or "Stem", V(w, w, d.Magnitude + 0.025), b * CFrame.lookAt((a + z) / 2, a, up), color, role or "Structure", slot)
end
local function stem(m, b, pts, w)
	for i = 1, #pts - 1 do rod(m, b, pts[i], pts[i+1], w * (1 - (i-1)*0.09), if i == 1 then PURPLESTEM else STEM) end
end
-- Broad pointed oval with two shallow pairs of lobes, six Parts including its petiole.
-- Positive Z is the outward blade direction. Offsetting plates prevents coplanar faces.
local function leaf(m, b, node, hinge, length, width, yaw, rise)
	rod(m, b, node, hinge, 0.10, PURPLESTEM, "Foliage")
	length *= 1.10
	width *= 1.25
	local cf = b * CFrame.new(hinge) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(-rise - 0.20, 0, math.sin(yaw) * 0.65)
	block(m, "LeafCentre", V(width*0.55, 0.07, length*0.76), cf*CFrame.new(0,0,length*0.42), LEAF, "Foliage", nil, "Studs")
	for side = -1, 1, 2 do
		block(m, "LeafLobe", V(width*0.56, 0.065, length*0.45), cf*CFrame.new(side*width*0.24,0.013,length*0.35)*CFrame.Angles(0,side*0.32,0), LEAF2, "Foliage", nil, "Studs")
	end
	block(m, "LeafTip", V(width*0.40, 0.063, length*0.42), cf*CFrame.new(0,0.026,length*0.81)*CFrame.Angles(0,0.72,0), LEAF, "Foliage", nil, "Studs")
	block(m, "LeafVein", V(0.038,0.024,length*0.83), cf*CFrame.new(0,0.05,length*0.47), C(126,153,80), "Foliage")
end
-- Five green sepals drape over a narrow neck; four overlapping octagonal sections fill a blunt pear belly.
local function fruit(m, b, node, at, length, width, bend, slot)
	local crook = at + V(-bend*0.14,0.26,-0.08)
	rod(m,b,node,crook,0.13,STEM,"Fruit",slot)
	rod(m,b,crook,at,0.16,CALYX,"Fruit",slot)
	local cf = b*CFrame.new(at)*CFrame.Angles(0,0.12, bend)
	local levels = {
		{0.16,0.36,0.56}, {0.40,0.42,0.87}, {0.67,0.40,1.00}, {0.88,0.24,0.73},
	}
	for j,l in levels do
		for k=0,1 do
			local w=width*l[3]*(if k==1 then 0.84 else 1)
			block(m,"FruitBody",V(w,length*l[2],w),cf*CFrame.new(0,-length*l[1],0)*CFrame.Angles(0,k*math.pi/4,0),if k==0 then SKIN else FACET,"Fruit",slot)
		end
	end
	block(m,"CalyxCore",V(width*0.57,0.17,width*0.57),cf*CFrame.new(0,-0.015,0),CALYX,"Fruit",slot)
	for j=0,4 do
		block(m,"Sepal",V(width*0.20,0.075,width*0.53),cf*CFrame.Angles(0,j*math.pi*0.4,0)*CFrame.Angles(0.65,0,0)*CFrame.new(0,-0.04,width*0.23),CALYX,"Fruit",slot)
	end
end
local function flower(m,b,node,at)
	rod(m,b,node,at,0.075,STEM,"Foliage")
	local cf=b*CFrame.new(at)*CFrame.Angles(math.rad(60),0,0)
	for i=0,4 do
		block(m,"Petal",V(0.17,0.055,0.31),cf*CFrame.Angles(0,i*math.pi*0.4,0)*CFrame.new(0,0,0.16),PETAL,"Foliage")
	end
	block(m,"FlowerCentre",V(0.12,0.18,0.12),cf*CFrame.new(0,0.10,0),C(242,197,57),"Foliage")
end
local studies = {
	{name="A_NaturalFork", build=function(m,b)
		local fork=V(0.03,2.06,-0.12)
		stem(m,b,{V(0,0,0),V(-0.10,1.10,0),fork,V(-0.52,2.98,-0.10),V(-0.31,3.69,-0.08)},0.19)
		stem(m,b,{fork,V(0.63,2.82,-0.11),V(0.89,3.35,-0.13)},0.15)
		stem(m,b,{V(-0.10,1.10,0),V(-0.58,1.69,0.07),V(-0.88,2.20,0.10)},0.14)
		leaf(m,b,V(-0.12,1.23,0),V(-0.58,1.58,-0.05),1.34,0.95,-1.85,0.10)
		leaf(m,b,fork,V(0.55,2.25,-0.23),1.28,0.98,1.20,0.20)
		leaf(m,b,V(-0.52,2.98,-0.10),V(-0.89,3.19,-0.19),1.25,0.94,-1.25,0.27)
		leaf(m,b,V(-0.31,3.69,-0.08),V(-0.25,3.74,-0.23),0.96,0.77,3.05,0.40)
		leaf(m,b,V(0.63,2.82,-0.11),V(0.68,3.09,-0.51),1.11,0.91,2.72,0.25)
		leaf(m,b,V(-0.10,1.10,0),V(-0.08,1.47,-0.51),1.11,0.91,3.10,0.08)
		fruit(m,b,V(-0.58,1.69,0.07),V(-0.99,1.87,0.56),1.45,0.72,-0.12,1)
		fruit(m,b,V(0.63,2.82,-0.11),V(0.92,2.35,0.49),1.58,0.79,0.14,2)
		fruit(m,b,V(-0.52,2.98,-0.10),V(-0.40,3.18,0.44),0.99,0.56,-0.08,3)
		flower(m,b,V(0.89,3.35,-0.13),V(0.98,3.56,0.26))
	end},
	{name="B_TallOpen", build=function(m,b)
		local fork=V(0,2.55,-0.12)
		stem(m,b,{V(0,0,0),V(0.06,1.35,-0.08),fork,V(-0.20,3.52,-0.16),V(0.02,4.39,-0.10)},0.19)
		stem(m,b,{fork,V(-0.75,3.16,-0.12),V(-1.02,3.72,-0.10)},0.15)
		stem(m,b,{V(-0.20,3.52,-0.16),V(0.70,3.76,-0.12),V(0.94,4.13,-0.20)},0.14)
		leaf(m,b,V(0.06,1.35,-0.08),V(-0.38,1.75,-0.38),1.33,0.94,-1.55,0.16)
		leaf(m,b,fork,V(0.44,2.80,-0.24),1.18,0.90,1.25,0.12)
		leaf(m,b,V(-0.75,3.16,-0.12),V(-1.00,3.42,-0.29),1.05,0.87,-1.36,0.35)
		leaf(m,b,V(0.02,4.39,-0.10),V(0.06,4.44,-0.20),0.87,0.76,3.04,0.44)
		leaf(m,b,V(0.70,3.76,-0.12),V(0.86,4.02,-0.44),1.05,0.84,2.55,0.25)
		fruit(m,b,V(-0.75,3.16,-0.12),V(-0.92,3.00,0.48),1.88,0.69,-0.14,1)
		fruit(m,b,V(0.70,3.76,-0.12),V(0.91,3.47,0.42),1.79,0.73,0.13,2)
		fruit(m,b,fork,V(-0.03,2.68,0.52),1.16,0.53,0.08,3)
		flower(m,b,V(0.94,4.13,-0.20),V(0.98,4.31,0.23))
	end},
	{name="C_CompactHeavy", build=function(m,b)
		local fork=V(0,1.50,-0.18)
		stem(m,b,{V(0,0,0),V(-0.05,0.79,-0.06),fork,V(-0.46,2.19,-0.24),V(-0.26,2.80,-0.22)},0.23)
		stem(m,b,{fork,V(0.56,2.03,-0.15),V(0.85,2.53,-0.18)},0.19)
		stem(m,b,{V(-0.05,0.79,-0.06),V(-0.72,1.48,0.05)},0.16)
		leaf(m,b,V(-0.05,0.79,-0.06),V(-0.53,1.20,-0.14),1.35,1.06,-1.83,0.17)
		leaf(m,b,fork,V(0.67,1.74,-0.14),1.30,1.05,1.47,0.13)
		leaf(m,b,V(-0.46,2.19,-0.24),V(-0.76,2.50,-0.27),1.21,1.05,-1.25,0.21)
		leaf(m,b,V(-0.26,2.80,-0.22),V(-0.24,2.85,-0.26),0.91,0.88,3.04,0.35)
		leaf(m,b,V(0.56,2.03,-0.15),V(0.79,2.48,-0.49),1.18,1.02,2.50,0.18)
		fruit(m,b,V(-0.72,1.48,0.05),V(-0.96,1.55,0.52),1.15,0.91,-0.12,1)
		fruit(m,b,V(0.56,2.03,-0.15),V(0.94,1.91,0.52),1.35,1.00,0.15,2)
		fruit(m,b,V(-0.46,2.19,-0.24),V(-0.16,2.35,0.57),0.91,0.73,-0.06,3)
		flower(m,b,V(0.85,2.53,-0.18),V(0.78,2.75,0.27))
	end},
}
local y0=500
block(folder,"GrassContext",V(24,0.5,9),CFrame.new(-1,y0-0.45,0),C(103,149,75))
local counts={}
for i,s in studies do
	local base=CFrame.new((i-2)*6.5,y0,0)
	block(folder,"Soil_"..i,V(5.5,0.30,5.5),base*CFrame.new(0,-0.15,0),C(88,66,48),nil,nil,"Studs")
	local m=Instance.new("Model")
	m.Name=s.name
	s.build(m,base)
	local radius,top,bottom=0,0,math.huge
	for _,p in m:GetChildren() do
		for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
			local a=base:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size*V(x,y,z)/2))
			radius=math.max(radius,V(a.X,0,a.Z).Magnitude)
			top=math.max(top,a.Y)
			if p:GetAttribute("PlantRole")=="Fruit" then bottom=math.min(bottom,a.Y) end
		end end end
	end
	counts[s.name]={parts=#m:GetChildren(),height=top,radius=radius,fruitClearance=bottom}
	assert(radius<=2.4,"Study exceeds field radius: "..s.name.." "..radius)
	assert(#m:GetChildren()<=130,"Study exceeds budget")
	m.Parent=folder
end
local ok,avatar=pcall(function()
	return game.Players:CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"),Enum.HumanoidRigType.R15)
end)
if ok then
	avatar.Name="ReferenceAvatar"
	avatar.Parent=folder
	avatar:PivotTo(CFrame.new(-10.25,y0+3,0.35)*CFrame.Angles(0,math.pi,0))
	local minY=math.huge
	for _,p in avatar:GetDescendants() do
		if p:IsA("BasePart") then minY=math.min(minY,p.Position.Y-p.Size.Y/2); p.Anchored=true; p.CanCollide=false end
	end
	avatar:PivotTo(avatar:GetPivot()+V(0,y0-minY,0))
	avatar.Humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
	counts.avatarHeight=avatar:GetExtentsSize().Y
else
	folder:Destroy()
	error("Avatar reference failed: "..tostring(avatar))
end
folder.Parent=workspace
return game.HttpService:JSONEncode(counts)
