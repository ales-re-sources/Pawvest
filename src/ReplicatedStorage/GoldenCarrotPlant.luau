-- CG10b: tall divided foliage and one pointed golden taproot, two-thirds buried (docs/plants/GOLDEN_CARROT.md).
-- 6 root + 3 crease + 2 seed-leaf + 12 stalk + 42 leaflet + 7 terminal Parts = 72, built once.
local GoldenCarrotPlant = {}
GoldenCarrotPlant.RingHeight = 4.7
GoldenCarrotPlant.ReviewHeight = 4.3

local Kit = require(script.Parent.PlantKit)
local phase, V, C = Kit.phase, Vector3.new, Color3.fromRGB
local ZERO = V(0,0,0)
local GOLD, LIGHT, AMBER = C(239,178,40), C(255,214,88), C(180,113,28)
local PALE = C(207,192,112)
local STALK, GREEN, TIP = C(47,110,44), C(69,151,57), C(110,185,65)
local WIDTHS = {0.06,0.24,0.43,0.64,0.86,0.76}
-- yaw, length, elevation, arch, emergence. Baseline seed 1 keeps the approved crown and root dimensions.
local FRONDS = {
	{-2.65,1.95,0.83,0.34,0.08}, {-1.55,2.15,1.02,0.28,0.14}, {-0.48,2.30,0.99,0.24,0.22},
	{0.42,2.00,0.70,0.34,0.29}, {1.38,2.35,1.18,0.20,0.36}, {2.37,1.85,0.77,0.33,0.42}, {3.08,2.42,1.30,0.17,0.48},
}
local CREASES = {
	{0.16,1.50,0.497,0.28,math.pi/4}, {-0.05,1.67,0.526,0.24,-math.pi/4}, {0.13,1.90,0.466,0.18,math.pi/4},
}
local TENDENCIES = {{1,1,0},{1.12,0.92,0.08},{0.91,1.10,-0.05},{1.05,1.04,-0.10},{0.96,0.94,0.11},{1.08,1.12,0.02}}

local function seededShape(seed, sizeFactor)
	local vary, ds = Kit.seeded(seed), Kit.dimension(sizeFactor)
	local tendency = Kit.tendency(TENDENCIES,seed)
	local shape = {fronds={},dimension=ds,rootLength=2.1*ds,rootWidth=ds,rootLean=V(vary(0.025),0,vary(0.025))}
	-- Root proportions vary together, preserving the full taproot's aspect and two-thirds burial.
	local rootShape = 1+vary(0.075)
	shape.rootLength *= rootShape
	shape.rootWidth *= rootShape
	local vigor = math.clamp(1+(ds-1)*0.2,0.92,1.10)
	local maxRad = 0
	for i,s in FRONDS do
		local f = {yaw=s[1]+vary(0.22),len=s[2]*vigor*tendency[1]*(1+vary(0.10)),
			elev=s[3]+tendency[3]+vary(0.06),arch=s[4]+vary(0.04),first=s[5]+vary(0.012),
			leafScale=vigor*tendency[2]*(1+vary(0.10)),single=i<=2}
		shape.fronds[i]=f
		local bz = math.cos(f.elev)*f.len*0.52
		local cz = bz+math.cos(f.elev-f.arch)*f.len*0.48
		maxRad = math.max(maxRad,cz+0.35)
		for pair,t in {0.38,0.61,0.81} do
			local atZ = if f.single then cz*t elseif t<=0.52 then bz*t/0.52 else bz+(cz-bz)*(t-0.52)/0.48
			local length = (if pair==1 then 0.48 elseif pair==2 then 0.41 else 0.29)*(s[2]/2.2)*f.leafScale
			maxRad = math.max(maxRad,V(length*0.83,0,atZ+length*0.56).Magnitude+0.15)
		end
	end
	shape.horizontal = math.min(1,(2.30-0.05*shape.rootWidth-shape.rootLean.Magnitude)/math.max(0.001,maxRad))
	-- Append effect draws after the structural stream so effects cannot reroll the plant.
	shape.glintRate = 0.2+vary(0.035)
	return shape
end

local function rootState(shape,g)
	local q = phase(g,0.30,1)
	local length = shape.rootLength*q
	local embed = 0.18*(1-q)
	local top = length/3-embed
	local crown = V(0.05*shape.rootWidth*q,math.max(0.025,top-0.02*shape.dimension*q),0)+shape.rootLean*q
	return {q=q,length=length,width=shape.rootWidth*math.sqrt(q),bottom=-length*2/3-embed,
		crown=crown,top=top,sheen=phase(g,0.75,1),color=phase(g,0.50,1)}
end

local function rootGeometry(shape,s,emit,proxy)
	for i,width in WIDTHS do
		if proxy and i<5 then continue end
		local at = V(0.01*(i-1)*shape.rootWidth*s.q,s.bottom+s.length*(i-0.5)/6,0)+shape.rootLean*s.q
		emit("Root_"..i,V(width*s.width,s.length/6,width*s.width),CFrame.new(at)*CFrame.Angles(0,math.pi/4,0),
			PALE:Lerp(if i==6 then LIGHT else GOLD,s.color),phase(s.q,0,0.04),"Root")
	end
	if proxy then return end
	local scale = shape.rootLength/2.1
	for i,spec in CREASES do
		local p = V(spec[1]*shape.rootWidth*s.q,(spec[2]-2.02)*scale*s.q+s.top,spec[3]*s.width)+shape.rootLean*s.q
		emit("RootCrease_"..i,V(spec[4]*s.width,0.026*shape.dimension,0.018*shape.dimension),
			CFrame.new(p)*CFrame.Angles(0,spec[5],0),AMBER,phase(s.q,0.38,0.70),"Root")
	end
end

local function cotyledons(shape,s,g,emit)
	local open = phase(g,0,0.20)
	local size = math.clamp(shape.dimension,0.75,1.10)
	for i,side in {-1,1} do
		local a = s.crown+V(side*0.018,-0.015,0)
		local len = (0.16+0.20*open)*size
		local elev = 1.15-0.94*open
		local b = a+V(side*math.cos(elev)*len,math.sin(elev)*len,0.02)
		emit("SeedLeaf_"..i,V(0.04,0.12*size,(b-a).Magnitude),Kit.axis(a,b)*CFrame.Angles(0,0,side*math.pi/2),
			TIP,1,"Foliage",nil,nil,"WedgePart")
	end
end

local function frondGeometry(shape,s,f,index,g,emit,proxy)
	local q1 = phase(g,f.first,f.first+0.30)
	local q2 = phase(g,f.first+0.12,math.min(1,f.first+0.52))
	local open = phase(g,f.first+0.05,math.min(1,f.first+0.50))
	local e1 = math.pi/2+(f.elev-math.pi/2)*open
	local e2 = math.pi/2+(f.elev-f.arch-math.pi/2)*open
	local a = ZERO
	local b = V(0,math.sin(e1)*1.45,math.cos(e1))*f.len*0.52*q1
	local c = b+V(0,math.sin(e2)*1.45,math.cos(e2))*f.len*0.48*q2
	local horizontal = V(shape.horizontal,1,shape.horizontal)
	local frame = CFrame.new(s.crown)*CFrame.Angles(0,f.yaw,0)
	local function point(p) return frame:PointToWorldSpace(p*horizontal) end
	local function rod(name,p1,p2,width,q)
		local x,y = point(p1),point(p2)
		emit(name,V(width,width,(y-x).Magnitude+0.015),Kit.axis(x,y),STALK,phase(q,0,0.08),"Foliage")
	end
	if f.single then
		rod("Frond_"..index.."_Spine",a,c,0.048,q1)
	else
		rod("Frond_"..index.."_Lower",a,b,0.052,q1)
		rod("Frond_"..index.."_Upper",b,c,0.038,q2)
	end
	for pair,t in {0.38,0.61,0.81} do
		if proxy and pair==2 then continue end
		local at = if f.single then a:Lerp(c,t) elseif t<=0.52 then a:Lerp(b,t/0.52) else b:Lerp(c,(t-0.52)/0.48)
		local q = phase(g,f.first+0.07+(pair-1)*0.045,math.min(1,f.first+0.36+(pair-1)*0.065))
		local len = (if pair==1 then 0.48 elseif pair==2 then 0.41 else 0.29)*(FRONDS[index][2]/2.2)*f.leafScale*(0.15+0.85*q)
		for _,side in {-1,1} do
			local finish = at+V(side*len*0.83*q,len*(1.15-q),len*0.56*q)
			local x,y = point(at),point(finish)
			emit("Frond_"..index.."_Leaf_"..pair.."_"..side,
				V(0.045,0.22*(1.15-pair*0.12)*f.leafScale*(0.2+0.8*q)*shape.horizontal,(y-x).Magnitude),
				Kit.axis(x,y)*CFrame.Angles(0,0,side*math.pi/2),if pair==3 then TIP else GREEN,
				phase(q,0,0.08)*phase(q1,0,0.10),"Foliage",nil,nil,"WedgePart")
		end
	end
	local qTip = phase(g,f.first+0.22,math.min(1,f.first+0.52))
	local delta = c-b
	local tip = c+(if delta.Magnitude>0.00001 then delta.Unit else Vector3.yAxis)*0.20*qTip
	local x,y = point(c-V(0,0.05*qTip,0)),point(tip)
		emit("Frond_"..index.."_Tip",V(0.04,0.14*shape.horizontal,(y-x).Magnitude),
		Kit.axis(x,y)*CFrame.Angles(0,0,math.pi/2),TIP,phase(qTip,0,0.10),"Foliage",nil,nil,"WedgePart")
end

local function geometry(shape,g,emit,proxy)
	local s = rootState(shape,g)
	rootGeometry(shape,s,emit,proxy)
	cotyledons(shape,s,g,emit)
	for i,f in shape.fronds do
		if proxy and i~=1 and i~=4 and i~=7 then continue end
		frondGeometry(shape,s,f,i,g,emit,proxy)
	end
	return s
end

local function addGlint(part,rate)
	local at = Instance.new("Attachment")
	at.Name = "RipeGlint"
	at.Parent = part
	local e = Instance.new("ParticleEmitter")
	e.Name,e.Texture="GoldGlint","rbxasset://textures/particles/sparkles_main.dds"
	e.Color=ColorSequence.new(C(255,230,130),C(255,248,206))
	e.LightEmission,e.LightInfluence=0.8,0
	e.Rate,e.Lifetime,e.Speed=rate,NumberRange.new(0.45,0.65),NumberRange.new(0.03,0.08)
	e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.35,0.24),NumberSequenceKeypoint.new(1,0)})
	e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.2,0.05),NumberSequenceKeypoint.new(1,1)})
	e.Rotation,e.RotSpeed=NumberRange.new(0,90),NumberRange.new(-12,12)
	e.SpreadAngle,e.LockedToPart=Vector2.new(15,15),true
	e.Enabled=false
	e.Parent=at
	return at,e
end

Kit.recipe(GoldenCarrotPlant, {
	name = "GoldenCarrotPlant",
	parts = 72,
	shape = seededShape,
	geometry = geometry,
	proxyMid = 0.70,
	onBuilt = function(self)
		self.glintAnchor, self.glint = addGlint(self.rig.parts[6], self.glintRate)
	end,
	-- the six root slabs shine as the carrot ripens
	onPart = function(part, role, g, index)
		if role == "Root" then
			local reflectance = if index <= 6 then 0.08 * phase(g, 0.75, 1) else 0
			if part.Reflectance ~= reflectance then
				part.Reflectance = reflectance
			end
		end
	end,
	onPose = function(self, g, s)
		self.glintAnchor.Position = V(0, 0.10 * self.dimension * s.q, 0.38 * s.width + 0.006)
		local ripe = g >= 1
		if self.glint.Enabled ~= ripe then
			self.glint.Enabled = ripe
			if not ripe then
				self.glint:Clear()
			end
		end
	end,
	-- Direct mid proxy: shoulders and three divided fronds. Hidden geometry is never constructed.
	onProxyPart = function(part, role, g)
		if role == "Root" then
			part.Reflectance = 0.08 * phase(g, 0.75, 1)
		end
	end,
})

-- A short gold-fleck reward at collection, independent of the plant that the plot feed may already have removed.
function GoldenCarrotPlant.PlayHarvest(parent,soilCFrame,sizeFactor)
	local dimension=Kit.dimension(sizeFactor)
	local anchor=Kit.proxyPart(parent,"GoldenCarrotHarvest",V(0.1,0.1,0.1),
		soilCFrame*CFrame.new(0,0.6*dimension,0),GOLD,nil,"Effect")
	anchor.Transparency=1
	local at,e=addGlint(anchor,0)
	at.Position=ZERO
	e.Speed=NumberRange.new(1.1,2.3)
	e.Acceleration=V(0,-2,0)
	e.SpreadAngle=Vector2.new(65,65)
	e.LockedToPart=false
	e:Emit(9)
	game:GetService("Debris"):AddItem(anchor,0.9)
	return anchor
end

return GoldenCarrotPlant
