-- CG16b: selected B, the tall open eggplant (docs/plants/EGGPLANT.md). Review recipe; field registration follows art approval.
-- Eight stems, two cotyledons, five six-Part leaves, three 22-Part flower/fruit slots and a seven-Part top flower = 113 Parts.
local EggplantPlant = {}
EggplantPlant.__index = EggplantPlant
EggplantPlant.RingHeight = 7.2
EggplantPlant.FixedRingHeight = true
EggplantPlant.ReviewHeight = 6.5

local Kit = require(script.Parent.PlantKit)
local phase, axis = Kit.phase, Kit.axis
local V, C = Vector3.new, Color3.fromRGB
local ZERO = V(0, 0, 0)
local STEM, PURPLESTEM = C(104,146,65), C(100,73,100)
local LEAF, LEAF2, YOUNG = C(77,132,62), C(96,151,75), C(142,181,83)
local SKIN, FACET, UNRIPE = C(57,20,84), C(83,30,113), C(116,74,149)
local CALYX, PETAL, POLLEN = C(106,153,58), C(179,102,220), C(242,197,57)
-- Parent, mature tip, growth interval, width. Parent tips are the attachment bases.
local SEGMENTS = {
	{0,V(0.06,1.35,-0.08),0,0.24,0.19},
	{1,V(0,2.55,-0.12),0.12,0.38,0.173},
	{2,V(-0.20,3.52,-0.16),0.25,0.48,0.156},
	{3,V(0.02,4.39,-0.10),0.35,0.58,0.139},
	{2,V(-0.75,3.16,-0.12),0.28,0.47,0.15},
	{5,V(-1.02,3.72,-0.10),0.38,0.59,0.1365},
	{3,V(0.70,3.76,-0.12),0.33,0.53,0.14},
	{7,V(0.94,4.13,-0.20),0.42,0.63,0.1274},
}
-- Parent, mature hinge, length, width, yaw, rise, unfolding interval.
local LEAVES = {
	{1,V(-0.38,1.75,-0.38),1.33,0.94,-1.55,0.16,0.10,0.40},
	{2,V(0.44,2.80,-0.24),1.18,0.90,1.25,0.12,0.24,0.52},
	{5,V(-1.00,3.42,-0.29),1.05,0.87,-1.36,0.35,0.33,0.61},
	{4,V(0.06,4.44,-0.20),0.87,0.76,3.04,0.44,0.40,0.66},
	{7,V(0.86,4.02,-0.44),1.05,0.84,2.55,0.25,0.38,0.65},
}
local FRUITS = {
	{5,V(-0.92,3.00,0.48),1.88,0.69,-0.14,0},
	{7,V(0.91,3.47,0.42),1.79,0.73,0.13,0.012},
	{2,V(-0.03,2.68,0.52),1.16,0.53,0.08,0.025},
}
local LEVELS = {{0.16,0.36,0.56},{0.40,0.42,0.87},{0.67,0.40,1.00},{0.88,0.24,0.73}}
local TENDENCIES = {{1,1,1,1},{0.96,0.94,1.08,0.92},{1.06,0.98,0.94,1.09},
	{0.94,1.02,1.06,0.95},{1.04,0.95,0.93,1.08},{0.98,1.01,1.10,0.91}}

local function seededShape(seed, sizeFactor)
	local shape = {segments={}, leaves={}, fruits={}}
	local vary, ds = Kit.seeded(seed), Kit.dimension(sizeFactor)
	local tendency = Kit.tendency(TENDENCIES, seed)
	local vigor = math.clamp(1+(ds-1)*0.12,0.96,1.06)
	local height, spread = tendency[1]+vary(0.02), tendency[2]+vary(0.015)
	local lean = V(vary(0.035),0,vary(0.025))
	for i,spec in FRUITS do
		local length, width = spec[3]*ds*(1+vary(0.09)), spec[4]*ds*(1+vary(0.07))
		shape.fruits[i] = {parent=spec[1],len=length,width=width,tilt=spec[5]+vary(0.025),
			yaw=0.12+vary(0.20),delay=spec[6]+vary(0.006)}
		-- A larger harvest grows longer fruit, with the leader lifted only when needed for clearance.
		height = math.max(height,(length*1.01+width*0.18+0.22)/(spec[2].Y*vigor))
	end
	local function point(p)
		local arm = if p.X<0 then tendency[3] else tendency[4]
		return V(p.X*spread*arm,p.Y*height,p.Z*spread)*vigor + lean*p.Y
	end
	for i,s in SEGMENTS do
		local parentTip = if s[1]==0 then ZERO else point(SEGMENTS[s[1]][2])
		shape.segments[i] = {parent=s[1],delta=point(s[2])-parentTip,first=s[3],last=s[4],width=s[5]*vigor}
	end
	for i,s in LEAVES do
		-- Larger blades stand more upright and sit closer to their branch, preserving the field clearance.
		shape.leaves[i] = {parent=s[1],offset=(point(s[2])-point(SEGMENTS[s[1]][2]))*V(0.50,1,0.50),
			len=s[3]*1.10*1.85*vigor*(1+vary(0.09)),width=s[4]*1.25*1.85*vigor*(1+vary(0.08)),
			yaw=s[5]+vary(0.19),rise=s[6]+(if i==4 then 0.35 else 0.85)+vary(0.09),first=s[7],last=s[8],delay=vary(0.008)}
	end
	for i,f in shape.fruits do f.offset=point(FRUITS[i][2])-point(SEGMENTS[f.parent][2]) end
	shape.flowerOffset=point(V(0.98,4.31,0.23))-point(SEGMENTS[8][2])
	return shape
end

local function structure(shape,g)
	local starts,tips,rotations,qs = {},{},{},{}
	local unloaded = 1-phase(g,0.80,1)
	for i,s in shape.segments do
		local parentRotation = if s.parent==0 then CFrame.identity else rotations[s.parent]
		local start = if s.parent==0 then ZERO else tips[s.parent]
		local q = phase(g,s.first,s.last)
		if i==1 then q=0.06+0.94*q end
		local bend = if i==5 then -0.055*unloaded elseif i==7 then 0.055*unloaded else 0
		local rotation = parentRotation*CFrame.Angles(0,0,bend)
		starts[i],tips[i],rotations[i],qs[i] = start,start+rotation:VectorToWorldSpace(s.delta)*q,rotation,q
	end
	return starts,tips,rotations,qs
end

local function leafPose(leaf,g,tips,rotations)
	local q=phase(g,leaf.first+leaf.delay,leaf.last+leaf.delay)
	local node=tips[leaf.parent]
	local hinge=node+rotations[leaf.parent]:VectorToWorldSpace(leaf.offset)*q
	local frame=CFrame.new(hinge)*rotations[leaf.parent]*CFrame.Angles(0,leaf.yaw,0)
		*CFrame.Angles(-1.40+(1.40-leaf.rise)*q,0,math.sin(leaf.yaw)*0.65*q)
	return q,node,hinge,frame
end

local function leaves(rig,leaf,g,tips,rotations)
	local q,node,hinge,cf=leafPose(leaf,g,tips,rotations)
	local len,width=leaf.len*(0.10+0.90*q),leaf.width*(0.09+0.91*q)
	local opacity=phase(q,0,0.09)
	local function plate(size,frame,color) rig:block(size,frame,YOUNG:Lerp(color,q),opacity) end
	rig:rod(node,hinge,0.10*(0.4+0.6*q),STEM:Lerp(PURPLESTEM,phase(g,0.35,0.65)),q)
	plate(V(width*0.55,0.07,len*0.76),cf*CFrame.new(0,0,len*0.42),LEAF)
	for side=-1,1,2 do
		plate(V(width*0.56,0.065,len*0.45),cf*CFrame.new(side*width*0.24,0.013,len*0.35)*CFrame.Angles(0,side*0.32*q,0),LEAF2)
	end
	plate(V(width*0.40,0.063,len*0.42),cf*CFrame.new(0,0.026,len*0.81)*CFrame.Angles(0,0.72*q,0),LEAF)
	plate(V(0.038,0.024,len*0.83),cf*CFrame.new(0,0.05,len*0.47),C(126,153,80))
end

local function fruitPose(f,g,tips,rotations)
	local q=phase(g,0.37+f.delay,0.48+f.delay)
	local node=tips[f.parent]
	local cap=node+rotations[f.parent]:VectorToWorldSpace(f.offset)*q
	local rotation=rotations[f.parent]*CFrame.Angles(0,f.yaw,f.tilt)
	return {node=node,cap=cap,crook=cap+rotation:VectorToWorldSpace(V(-f.tilt*0.14,0.26,-0.08))*q,
		frame=CFrame.new(cap)*rotation,pedicel=q,
		flower=phase(g,0.43+f.delay,0.52+f.delay),set=phase(g,0.59+f.delay,0.74+f.delay),
		length=phase(g,0.62+f.delay,0.88+f.delay),swell=phase(g,0.74+f.delay,1),ripe=phase(g,0.70+f.delay,0.96)}
end

local function fruit(rig,f,p)
	rig:rod(p.node,p.crook,0.13,STEM,p.pedicel)
	rig:rod(p.crook,p.cap,0.16,CALYX,p.pedicel)
	local length=f.len*(0.15+0.85*p.length)
	local width=f.width*(0.35+0.65*p.swell)
	local bodyOpacity=phase(p.set,0,0.14)
	for _,l in LEVELS do for k=0,1 do
		local w=width*l[3]*(if k==1 then 0.84 else 1)
		rig:block(V(w,length*l[2],w),p.frame*CFrame.new(0,-length*l[1],0)*CFrame.Angles(0,k*math.pi/4,0),
			UNRIPE:Lerp(if k==0 then SKIN else FACET,p.ripe),bodyOpacity)
	end end
	local calyxWidth=f.width*(0.45+0.55*p.set)
	local visible=phase(p.flower,0,0.08)
	rig:block(V(calyxWidth*0.57,0.17,calyxWidth*0.57),p.frame*CFrame.new(0,-0.015,0),CALYX,visible)
	for j=0,4 do
		rig:block(V(calyxWidth*0.20,0.075,calyxWidth*0.53),p.frame*CFrame.Angles(0,j*math.pi*0.4,0)
			*CFrame.Angles(0.65,0,0)*CFrame.new(0,-0.04,calyxWidth*0.23),CALYX,visible)
	end
	local bloom=p.flower*(1-p.set)
	local flowerFrame=p.frame*CFrame.Angles(math.rad(60)+p.set*0.75,0,0)
	for j=0,4 do
		rig:block(V(0.17,0.055,0.31)*math.max(0.001,bloom),flowerFrame*CFrame.Angles(0,j*math.pi*0.4,0)
			*CFrame.new(0,0,0.16*bloom),PETAL,visible*(1-p.set))
	end
	rig:block(V(0.12,0.18,0.12)*math.max(0.001,bloom),flowerFrame*CFrame.new(0,0.10*bloom,0),POLLEN,visible*(1-p.set))
end

function EggplantPlant.new(parent,soilCFrame,seed,sizeFactor)
	local self=setmetatable(seededShape(seed,sizeFactor),EggplantPlant)
	local rig=Kit.newRig("EggplantPlant",soilCFrame)
	self.rig,self.model,self.fruitSlots,self.leafPoses=rig,rig.model,{},{}
	for i=1,8 do rig:add("Stem"..i,nil,"Structure") end
	for i=1,2 do rig:add("Cotyledon"..i,nil,"Foliage") end
	for i=1,5 do
		for _,name in {"Petiole","Centre","LobeL","LobeR","Tip","Vein"} do rig:add("Leaf"..i..name,if name=="Vein" or name=="Petiole" then nil else "Studs","Foliage") end
	end
	local _,tips,rotations=structure(self,1)
	for id,f in self.fruits do
		local slot={id=id,attachment=soilCFrame*fruitPose(f,1,tips,rotations).frame,parts={}}
		self.fruitSlots[id]=slot
		for _,name in {"StalkA","StalkB","Body1a","Body1b","Body2a","Body2b","Body3a","Body3b","Body4a","Body4b",
			"Calyx","Sepal1","Sepal2","Sepal3","Sepal4","Sepal5","Petal1","Petal2","Petal3","Petal4","Petal5","Pollen"} do
			table.insert(slot.parts,rig:add("Fruit"..id..name,nil,"Fruit",id))
		end
	end
	for _,name in {"Stalk","Petal1","Petal2","Petal3","Petal4","Petal5","Pollen"} do rig:add("Flower"..name,nil,"Foliage") end
	assert(#rig.parts==113,"Eggplant topology changed")
	self:SetGrowth(0)
	self.model.Parent=parent
	return self
end

function EggplantPlant:SetGrowth(normalized)
	local rig=self.rig
	local g=rig:beginPose(normalized)
	if not g then return end
	local starts,tips,rotations,qs=structure(self,g)
	local tint=phase(g,0.35,0.65)
	for i,s in self.segments do
		local color=if i<=2 then STEM:Lerp(PURPLESTEM,tint) else STEM
		rig:rod(starts[i],tips[i],s.width*(0.40+0.60*qs[i]),YOUNG:Lerp(color,qs[i]),qs[i])
	end
	local cotyledon=1-phase(g,0.26,0.43)
	local open=phase(g,0,0.16)
	for side=-1,1,2 do
		local cf=CFrame.new(tips[1])*CFrame.Angles(0,side*math.pi/2,0)*CFrame.Angles(-1.18+1.02*open,0,0)
		rig:block(V(0.13+0.09*open,0.035,0.15+0.30*open),cf*CFrame.new(0,0,0.075+0.15*open),YOUNG,cotyledon)
	end
	for i,leaf in self.leaves do
		local q,node,hinge,frame=leafPose(leaf,g,tips,rotations)
		local old=self.leafPoses[i]
		if old and old.q==q and old.frame==frame and old.node==node and old.tint==tint then rig:skip(6) else
			leaves(rig,leaf,g,tips,rotations)
			self.leafPoses[i]={q=q,frame=frame,node=node,tint=tint}
		end
	end
	for _,f in self.fruits do fruit(rig,f,fruitPose(f,g,tips,rotations)) end
	local q=phase(g,0.46,0.57)
	local node=tips[8]
	local at=node+rotations[8]:VectorToWorldSpace(self.flowerOffset)*q
	rig:rod(node,at,0.075,STEM,q)
	local cf=CFrame.new(at)*rotations[8]*CFrame.Angles(math.rad(60),0,0)
	for i=0,4 do rig:block(V(0.17,0.055,0.31)*math.max(q,0.001),cf*CFrame.Angles(0,i*math.pi*0.4,0)*CFrame.new(0,0,0.16*q),PETAL,q) end
	rig:block(V(0.12,0.18,0.12)*math.max(q,0.001),cf*CFrame.new(0,0.10*q,0),POLLEN,q)
	rig:finish()
end

function EggplantPlant:Destroy() self.rig:destroy() end

return EggplantPlant
