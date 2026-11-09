-- CG8: free-standing red chilli peppers, following the corrected pointed-fruit reference.
-- 7 stems + 35 leaf plates + 3 x 14 fruit/blossom pieces = 84 Parts, built once.
local PepperPlant = {}
PepperPlant.__index = PepperPlant
PepperPlant.RingHeight = 4.4

local Kit = require(script.Parent.PlantKit)
local phase, axis = Kit.phase, Kit.axis
local V, C = Vector3.new, Color3.fromRGB
local STEM, DARK, LIGHT = C(63,121,53), C(48,121,49), C(86,151,59)
local YOUNG, GREEN, ORANGE = C(140,181,76), C(78,145,48), C(245,140,31)
local RED, SHADE, WHITE, POLLEN = C(222,45,32), C(205,35,28), C(244,242,225), C(218,185,69)
local ZERO = V(0,0,0)
-- Curved centre line, shoulder to tip. The final wedge makes a real pointed silhouette.
local PROFILE = {
	{V(0,-0.04,0),0.34}, {V(0,-0.30,0),0.31}, {V(0.02,-0.68,0.01),0.25},
	{V(0.09,-1.02,0.02),0.18}, {V(0.22,-1.28,0.02),0.10},
	{V(0.37,-1.46,0.02),0.07}, {V(0.49,-1.55,0.02),0},
}
-- parent segment, fraction along parent, mature endpoint, emergence interval, stem width.
local SEGMENTS = {
	{0,0,V(-0.04,0.65,0),0,0.18,0.14},
	{1,1,V(0.04,1.35,0.02),0.08,0.32,0.122},
	{2,1,V(0,2.02,0),0.19,0.47,0.104},
	{3,1,V(-0.87,2.78,0.04),0.31,0.60,0.105},
	{3,1,V(0.83,3.18,-0.16),0.33,0.64,0.105},
	{5,0.5,V(-0.12,3.32,-0.38),0.40,0.69,0.08},
	{2,1,V(0.85,1.98,0.50),0.29,0.56,0.085},
}
-- parent, fraction, yaw, length, width, elevation, opening interval.
local LEAVES = {
	{1,1,-1.7,0.65,0.34,0.18,0,0.25}, {2,1,1.8,0.80,0.40,0.25,0,0.28},
	{4,0.39,-2.2,0.92,0.48,0.32,0.28,0.56}, {4,0.64,-0.85,0.86,0.46,0.35,0.31,0.60},
	{4,1,-1.45,0.70,0.40,0.36,0.37,0.67}, {4,1,0.20,0.68,0.38,0.40,0.39,0.68},
	{5,0.5,2.1,0.82,0.44,0.33,0.31,0.62}, {5,1,1.0,0.77,0.42,0.23,0.42,0.71},
	{5,1,-2.0,0.72,0.40,0.27,0.43,0.72}, {6,1,-0.3,0.62,0.37,0.12,0.45,0.75},
	{6,1,2.5,0.55,0.34,0.16,0.46,0.76}, {7,0.73,1.2,0.70,0.41,0.38,0.30,0.58},
}
-- parent segment, offset from its tip to the calyx, relative size, tilt, yaw.
local FRUIT = {
	{4,V(-0.19,-0.25,0.26),1,-0.13,0.18},
	{5,V(0.19,-0.24,0.28),0.94,0.11,-0.20},
	{7,V(0.13,-0.20,0.28),0.87,-0.08,0.32},
}
local TENDENCIES = {
	{1,1,1,1}, {0.92,1.12,1.04,0.94}, {1.12,0.91,0.96,1.04},
	{1.02,1.02,1.17,0.86}, {0.98,1.02,0.86,1.17}, {0.94,0.89,1.02,0.96},
}

local function at(starts, tips, parent, t)
	return if parent == 0 then ZERO else starts[parent]:Lerp(tips[parent],t)
end

-- Coordinate intervals bound every intermediate extension, including an arm growing back across its parent.
local function bounds(shape)
	local lows, highs = {}, {}
	for i, s in shape.segments do
		local lo = ZERO
		local hi = lo
		if s.parent > 0 then
			local p = shape.segments[s.parent]
			lo = p.lowStart:Lerp(lows[s.parent],s.t)
			hi = p.highStart:Lerp(highs[s.parent],s.t)
		end
		s.lowStart, s.highStart = lo, hi
		lows[i], highs[i] = lo + s.delta:Min(ZERO), hi + s.delta:Max(ZERO)
	end
	return lows, highs
end

local function radial(lo, hi)
	return V(math.max(math.abs(lo.X),math.abs(hi.X)),0,math.max(math.abs(lo.Z),math.abs(hi.Z))).Magnitude
end

local function seededShape(seed, sizeFactor)
	local shape = {segments={},leaves={},fruits={}}
	local vary = Kit.seeded(seed)
	local ds = Kit.dimension(sizeFactor)
	local tendency = Kit.tendency(TENDENCIES,seed)
	local vigor = math.clamp(1+(ds-1)*0.20,0.94,1.10)
	local height, spread = tendency[1]+vary(0.035), tendency[2]+vary(0.035)
	local lean = V(vary(0.055),0,vary(0.045))
	for i, f in FRUIT do
		local scale = f[3]*ds*(1+vary(0.10))
		shape.fruits[i] = {parent=f[1],offset=f[2]*vigor,scale=scale,tilt=f[4]+vary(0.035),yaw=f[5]+vary(0.18),delay=vary(0.012)}
		-- Keep the lowest ripe tips clear of soil even for the largest Sorter harvest on a short seed.
		local nominalY = SEGMENTS[f[1]][3].Y + f[2].Y
		height = math.max(height,(1.78*scale+0.18)/(nominalY*vigor))
	end
	local function point(p)
		return V(p.X*spread,p.Y*height,p.Z*spread)*vigor + lean*p.Y
	end
	local ripeStarts, ripeTips = {}, {}
	for i, spec in SEGMENTS do
		local tip = point(spec[3])
		if i==4 then tip += V(spec[3].X*(tendency[3]-1)*vigor,0,0)
		elseif i==5 then tip += V(spec[3].X*(tendency[4]-1)*vigor,0,0) end
		local start = at(ripeStarts,ripeTips,spec[1],spec[2])
		ripeStarts[i],ripeTips[i] = start,tip
		shape.segments[i] = {parent=spec[1],t=spec[2],delta=tip-start,first=spec[4],last=spec[5],width=spec[6]*vigor}
	end
	-- A conservative all-age bound fits structure only; fruit keeps its real harvested-mass scale.
	local lows,highs = bounds(shape)
	local fit = 1
	for _, f in shape.fruits do
		local r = radial(lows[f.parent],highs[f.parent]) + V(f.offset.X,0,f.offset.Z).Magnitude
		fit = math.min(fit,math.max(0.25,(2.35-0.95*f.scale)/math.max(r,0.001)))
	end
	local horizontal = V(fit,1,fit)
	for _, s in shape.segments do s.delta *= horizontal end
	for _, f in shape.fruits do f.offset *= horizontal end
	lows,highs = bounds(shape)
	for i, spec in LEAVES do
		local parent = shape.segments[spec[1]]
		local rootLo = parent.lowStart:Lerp(lows[spec[1]],spec[2])
		local rootHi = parent.highStart:Lerp(highs[spec[1]],spec[2])
		local len = spec[4]*1.18*vigor*(1+vary(0.16))
		local width = spec[5]*1.35*vigor*(1+vary(0.13))
		local leafFit = math.min(1,math.max(0.10,(2.32-radial(rootLo,rootHi))/(len+width/2)))
		shape.leaves[i] = {parent=spec[1],t=spec[2],yaw=spec[3]+vary(0.32),len=len*leafFit,width=width*leafFit,
			elev=spec[6]+vary(0.12),first=spec[7],last=spec[8],delay=vary(0.012),pieces=if i==1 then 2 else 3}
	end
	-- Append new draws after the existing seed stream, preserving the bush's identity.
	for i,f in shape.fruits do
		f.bend = (if i==2 then 1 else -1)*(1+vary(0.15))
		f.slender = 1+vary(0.10)
		f.length = 1+vary(0.08)
	end
	return shape
end

local function structure(shape,g)
	local starts,tips,rotations,qs = {},{},{},{}
	local weight = phase(g,0.68,1)
	for i,s in shape.segments do
		local q = phase(g,s.first,s.last)
		if i==1 then q=0.18+0.82*q end
		local start = at(starts,tips,s.parent,s.t)
		local delta = s.delta + V(0,if i==4 or i==5 or i==7 then 0.07*(1-weight) else 0,0)
		starts[i],tips[i],qs[i] = start,start+delta*q,q
		rotations[i] = axis(ZERO,delta).Rotation * axis(ZERO,s.delta).Rotation:Inverse()
	end
	return starts,tips,rotations,qs
end

local function leafPose(leaf,index,g,starts,tips,rotations)
	local q = phase(g,leaf.first+leaf.delay,leaf.last+leaf.delay)
	if index<=2 then q=0.14+0.86*q end
	local frame = CFrame.new(at(starts,tips,leaf.parent,leaf.t))*rotations[leaf.parent]*CFrame.Angles(0,leaf.yaw,0)
	return q,frame
end

local function leafGeometry(leaf,q,frame,emit,proxy)
	local points = {ZERO}
	local fractions = if leaf.pieces==2 then {0.45,0.55} else {0.28,0.42,0.30}
	local widths = if leaf.pieces==2 then {0.75,0.30} else {0.60,1,0.30}
	local len = leaf.len*(0.12+0.88*q)
	for i, fraction in fractions do
		local angle = 1.42+(leaf.elev-1.42)*q-(i-1)*0.20*q
		points[i+1] = points[i]+V(0,math.sin(angle),math.cos(angle))*len*fraction
	end
	local width = leaf.width*(0.18+0.82*q)
	local opacity = phase(q,0,0.08)
	if proxy then
		emit(V(width*0.72,0.055,(points[#points]-points[1]).Magnitude+0.015),frame*axis(points[1],points[#points]),opacity)
	else
		for i=1,leaf.pieces do
			emit(V(width*widths[i],0.055,(points[i+1]-points[i]).Magnitude+0.015),frame*axis(points[i],points[i+1]),opacity)
		end
	end
end

local function fruitPose(f,g,starts,tips,rotations)
	local pedicel = phase(g,0.39+f.delay,0.52+f.delay)
	local node = tips[f.parent]
	local offset = rotations[f.parent]:VectorToWorldSpace(f.offset)*pedicel
	local cap = node+offset
	local frame = CFrame.new(cap)*rotations[f.parent]*CFrame.Angles(0,f.yaw,f.tilt)
	local joint = node:Lerp(cap,0.56)+V(0,0.06*pedicel,0)
	local length = phase(g,0.56+f.delay,0.88+f.delay)
	local swell = phase(g,0.64+f.delay,0.98+f.delay)
	local set = phase(g,0.55+f.delay,0.66+f.delay)
	local flower = phase(g,0.42+f.delay,0.52+f.delay)
	local color = GREEN:Lerp(ORANGE,phase(g,0.79+f.delay,0.90+f.delay)):Lerp(RED,phase(g,0.89,1))
	local dims = V((0.28+0.72*swell)*f.scale*f.slender,(0.08+0.92*length)*f.scale*f.length,(0.28+0.72*swell)*f.scale*f.slender)
	return {node=node,cap=cap,joint=joint,frame=frame,pedicel=pedicel,flower=flower,set=set,dims=dims,color=color,
		curve=(0.12+0.88*length)*f.scale*f.bend}
end

local function fruitGeometry(f,p,emit,proxy)
	local function part(size,cf,color,opacity,className) emit(size,cf,color,opacity,className) end
	local function rod(a,b)
		part(V(0.085,0.085,(b-a).Magnitude),axis(a,b),STEM,phase(p.pedicel,0,0.08))
	end
	rod(p.node,if proxy then p.cap else p.joint)
	if not proxy then rod(p.joint,p.cap) end
	local capSize = (0.30+0.70*p.set)*f.scale
	part(V(0.23,0.10,0.23)*capSize,p.frame,POLLEN:Lerp(DARK,p.set),phase(p.flower,0,0.08))
	if not proxy then
		for i=1,5 do
			local turn = CFrame.Angles(0,(i-1)*math.pi*2/5,0)
			local petalScale = f.scale*p.flower
			local width = 0.15+(0.07-0.15)*p.set
			local reach = 0.30+(0.17-0.30)*p.set
			local hinge = p.frame*turn*CFrame.Angles(0.95*(1-p.flower)+0.25*p.set,0,0)
			part(V(width,0.065,reach)*petalScale,hinge*CFrame.new(0,-0.025*petalScale,(0.15-0.07*p.set)*petalScale),
				WHITE:Lerp(DARK,p.set),phase(p.flower,0,0.08))
		end
	end
	local indices = if proxy then {1,3,5,6,7} else {1,2,3,4,5,6,7}
	local function point(v) return V(v.X*p.curve,v.Y*p.dims.Y,v.Z*p.dims.Z) end
	for i=1,#indices-1 do
		local j,k = indices[i],indices[i+1]
		local a,b = point(PROFILE[j][1]),point(PROFILE[k][1])
		local width = PROFILE[j][2]
		local tip = k==#PROFILE
		local tint = p.color:Lerp(SHADE,if i%2==0 then 0.08*p.set else 0)
		part(V(width*p.dims.Z,width*p.dims.X,(b-a).Magnitude+(if tip then 0 else 0.025*p.dims.Y)),
			p.frame*axis(a,b)*(if tip then CFrame.Angles(0,math.pi,0) else CFrame.identity),tint,phase(p.set,0,0.10),
			if tip then "WedgePart" else nil)
	end
end

function PepperPlant.new(parent,soilCFrame,seed,sizeFactor)
	local self = setmetatable(seededShape(seed,sizeFactor),PepperPlant)
	local rig = Kit.newRig("PepperPlant",soilCFrame)
	self.rig,self.model,self.fruitSlots,self.leafPoses = rig,rig.model,{},{}
	for i=1,7 do rig:add("Stem"..i,nil,"Structure") end
	for i,leaf in self.leaves do for j=1,leaf.pieces do rig:add("Leaf"..i.."_"..j,nil,"Foliage") end end
	local _,tips = structure(self,1)
	for id,f in self.fruits do
		local slot = {id=id,attachment=soilCFrame*CFrame.new(tips[f.parent]),parts={}}
		self.fruitSlots[id]=slot
		for _,name in {"StalkA","StalkB","Calyx","Sepal1","Sepal2","Sepal3","Sepal4","Sepal5",
			"Body1","Body2","Body3","Body4","Body5","Point"} do
			table.insert(slot.parts,rig:add("Fruit"..id.."_"..name,nil,"Fruit",id,if name=="Point" then "WedgePart" else nil))
		end
	end
	assert(#rig.parts==84,"Pepper topology changed")
	self:SetGrowth(0)
	self.model.Parent=parent
	return self
end

function PepperPlant:SetGrowth(normalized)
	local rig = self.rig
	local g = rig:beginPose(normalized)
	if not g then return end
	local starts,tips,rotations,qs = structure(self,g)
	for i,s in self.segments do rig:rod(starts[i],tips[i],s.width*(0.55+0.45*qs[i]),YOUNG:Lerp(STEM,qs[i]),qs[i]) end
	for i,leaf in self.leaves do
		local q,frame = leafPose(leaf,i,g,starts,tips,rotations)
		local old = self.leafPoses[i]
		if old and old.q==q and old.frame==frame then rig:skip(leaf.pieces) else
			self.leafPoses[i]={q=q,frame=frame}
			leafGeometry(leaf,q,frame,function(size,cf,opacity)
				rig:block(size,cf,YOUNG:Lerp(if i%3==0 then LIGHT else DARK,q),opacity)
			end,false)
		end
	end
	for _,f in self.fruits do
		fruitGeometry(f,fruitPose(f,g,starts,tips,rotations),function(size,cf,color,opacity) rig:block(size,cf,color,opacity) end,false)
	end
	rig:finish()
end

function PepperPlant:Destroy() self.rig:destroy() end

-- Direct-built mid silhouette: same seed/size/attachment math, without allocating a full rig.
function PepperPlant.BuildProxy(parent,soilCFrame,stage,seed,sizeFactor)
	local shape = seededShape(seed,sizeFactor)
	local g = if stage<=1 then 0.20 elseif stage==2 then 0.72 else 1
	local starts,tips,rotations,qs = structure(shape,g)
	local function block(name,size,cf,color,opacity,role,id,className)
		if opacity>0 then Kit.proxyPart(parent,name,size,soilCFrame*cf,color,nil,role,id,className) end
	end
	for i,s in shape.segments do
		block("Stem"..i,V(s.width,s.width,(tips[i]-starts[i]).Magnitude),axis(starts[i],tips[i]),STEM,qs[i],"Structure")
	end
	for _,i in (if stage<=1 then {1,2} else {3,5,7,8,10,12}) do
		local leaf = shape.leaves[i]
		local q,frame = leafPose(leaf,i,g,starts,tips,rotations)
		leafGeometry(leaf,q,frame,function(size,cf,opacity)
			block("Leaf"..i,size,cf,if i%3==0 then LIGHT else DARK,opacity,"Foliage")
		end,true)
	end
	if stage>=2 then
		for id,f in shape.fruits do
			fruitGeometry(f,fruitPose(f,g,starts,tips,rotations),function(size,cf,color,opacity,className)
				block("Fruit"..id,size,cf,color,opacity,"Fruit",id,className)
			end,true)
		end
	end
end

return PepperPlant
