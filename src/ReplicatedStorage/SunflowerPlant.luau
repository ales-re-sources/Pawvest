-- CG20b: approved A1 spiral foliage + H2 layered golden head, staged for art review only.
-- 192 Parts: 5 stems + 63 foliage + neck + 120 head + seed + 2 cotyledons; 141 built-in sphere meshes.
-- One fixed topology, reversible parent-attached growth; no saved data or crop-specific scheduler.
local SunflowerPlant = {Draft = true, RingHeight = 8.9, FixedRingHeight = true, ReviewHeight = 8.2}
local Kit = require(script.Parent.PlantKit)
local phase, V, C = Kit.phase, Vector3.new, Color3.fromRGB
local STEM, LEAF, LIGHT, YOUNG = C(91,137,57), C(59,121,56), C(89,148,64), C(145,188,88)
local GOLD, PALE, AMBER = C(246,187,28), C(255,211,53), C(227,157,24)
local GOLDEN = 2.399963229728653
local STEM_TIMES = {{0,0.17},{0.07,0.31},{0.18,0.45},{0.30,0.58},{0.42,0.70}}

local function along(path, t)
	local f = math.clamp(t,0,1) * (#path-1)
	local i = math.min(#path-1, math.floor(f)+1)
	return path[i]:Lerp(path[i+1],f-(i-1))
end

local function shape(seed, sizeFactor)
	local vary, ds = Kit.seeded(seed), Kit.dimension(sizeFactor)
	local s = {path={V(0,0,0)}, leaves={}, seeds={}, petals={}, headScale=math.min(ds,1.20)}
	local grow = math.clamp(1+(ds-1)*0.12,0.94,1.06)
	local height = 5.72*grow*(1+vary(0.045))
	local lean = V(0.16+vary(0.14),0,0.10+vary(0.12))
	for j=1,5 do
		local t=j/5
		s.path[j+1]=lean*t*t+V(math.sin(t*5.7)*0.12,height*t,math.sin(t*4.1)*0.08)
	end
	-- These two fixed random streams reproduce the approved study at seed 1; Kit.seeded supplies planting variation.
	local random=Random.new(90)
	for j=1,9 do
		local t=0.11+(j-1)*0.74/8+random:NextNumber(-0.018,0.018)
		local yaw=0.30+(j-1)*2.39+random:NextNumber(-0.16,0.16)
		local size=if j==9 then 0.72 elseif j==1 then 0.83 else random:NextNumber(0.84,1.04)
		local petiole=random:NextNumber(0.32,0.48)
		local rise=if j<=3 then random:NextNumber(-0.28,-0.06) else random:NextNumber(0.05,0.30)
		local roll=random:NextNumber(-0.24,0.24)
		local tone=LEAF:Lerp(LIGHT,random:NextNumber(0.05,0.65))
		local scale=math.clamp(1+(ds-1)*0.15,0.94,1.08)*(1+vary(0.07))
		s.leaves[j]={t=t,yaw=yaw+vary(0.20),petiole=petiole,len=1.31*size*scale,width=0.96*size*scale,
			rise=rise+vary(0.08),roll=roll+vary(0.12),tone=tone,start=0.035+(j-1)*0.046}
	end
	s.yaw, s.pitch, s.roll = -0.10+vary(0.28), 0.13+vary(0.055), -0.07+vary(0.10)
	random=Random.new(701)
	for j=1,42 do
		local a=j*GOLDEN
		local r=1.68*0.425*math.sqrt(j/42)
		local size=1.68*0.060*random:NextNumber(0.85,1.12)
		local z=0.125+0.075*math.sqrt(math.max(0,1-(r/(1.68*0.5))^2))
		local tone=C(105,70,34):Lerp(C(166,117,53),random:NextNumber(0.10,0.65))
		s.seeds[j]={angle=a,r=r,size=size,z=z,tone=tone}
	end
	for layer=1,2 do
		local count=if layer==1 then 20 else 14
		for j=1,count do
			local a=(j-1)*math.pi*2/count+(if layer==2 then math.pi/count else 0)+random:NextNumber(-0.04,0.04)
			local len=0.96*random:NextNumber(0.87,1.11)*(if layer==2 then 0.77 else 1)
			local width=0.43*random:NextNumber(0.86,1.12)
			local bend=0.18+random:NextNumber(-0.09,0.14)
			local tone=GOLD:Lerp(AMBER,random:NextNumber(0,0.27))
			table.insert(s.petals,{layer=layer,index=j,angle=a,len=len,width=width,bend=bend,tone=tone})
		end
	end
	s.headAt=s.path[6]+V(0,0.25,0.16)
	return s
end

local function rod(emit, name, a, b, w, color, opacity, role)
	emit(name,V(w,w,(b-a).Magnitude),Kit.axis(a,b),color,opacity,role or "Structure")
end

local function leaf(emit, node, l, j, g, proxy)
	local q=phase(g,l.start,l.start+0.25)
	local open=phase(q,0.10,1)
	local opacity=phase(q,0,0.08)
	local radial=V(math.sin(l.yaw),0,math.cos(l.yaw))
	local elbow=node+radial*l.petiole*0.58*q+V(0,0.22*q,0)
	local hinge=node+radial*l.petiole*q+V(0,0.25*q,0)
	if proxy then
		rod(emit,"Petiole"..j,node,hinge,0.085,STEM,opacity,"Foliage")
	else
		rod(emit,"PetioleBase"..j,node,elbow,0.09,STEM,opacity,"Foliage")
		rod(emit,"PetioleTip"..j,elbow,hinge,0.075,STEM,opacity,"Foliage")
	end
	local blade=(radial*(0.12+0.88*open)+V(0,1.10*(1-open)+l.rise*open,0)).Unit
	local n=(Vector3.yAxis-blade*blade.Y).Unit
	local cf=CFrame.fromMatrix(hinge,n:Cross(blade),n,blade)*CFrame.Angles(0,0,l.roll*open)
	local len,width=l.len*(0.08+0.92*q),l.width*(0.12+0.88*q)
	local tone=if q>=0.95 then l.tone else YOUNG:Lerp(l.tone,phase(q,0.1,0.95))
	emit("LeafShoulders"..j,V(width*0.83,0.075,len*0.56),cf*CFrame.new(0,0,len*0.28),tone,opacity,"Foliage",nil,"Studs")
	local endFrame=cf*CFrame.new(0,0,len*0.44)*CFrame.Angles(0.24*open,0,0)
	emit("LeafBlade"..j,V(width,0.07,len*0.55),endFrame*CFrame.new(0,0,len*0.17),tone:Lerp(LIGHT,0.12),opacity,"Foliage",nil,"Studs")
	if not proxy then
		local tipFrame=endFrame*CFrame.new(0,0,len*0.25)
		for side=-1,1,2 do
			local apex,corner=V(0,0,len*0.36),V(side*width*0.31,0,0)
			local f=tipFrame*CFrame.fromMatrix((apex+corner)/2,Vector3.yAxis*side,Vector3.zAxis,Vector3.xAxis*side)
			emit("LeafPoint"..j.."_"..side,V(0.052,len*0.36,width*0.31),f,tone,opacity,"Foliage",nil,"Studs","WedgePart")
		end
		local a,b=V(0,0.045,len*0.06),V(0,0.045,len*0.65)
		emit("LeafVein"..j,V(0.026,0.026,(b-a).Magnitude),cf*Kit.axis(a,b),tone:Lerp(C(159,181,87),0.40),opacity,"Foliage")
	end
end

local function geometry(s,g,emit,proxy)
	local path={s.path[1]}
	for j=1,5 do
		local q=phase(g,STEM_TIMES[j][1],STEM_TIMES[j][2])
		path[j+1]=path[j]+(s.path[j+1]-s.path[j])*q
		rod(emit,"Stem"..j,path[j],path[j+1],(0.23-j*0.016)*(0.45+0.55*q),STEM,phase(q,0,0.08))
	end
	for j,l in s.leaves do
		if not (proxy and j%3==0) then leaf(emit,along(path,l.t),l,j,g,proxy) end
	end
	local emerge=phase(g,0.43,0.53)
	local top=path[6]
	rod(emit,"Neck",top,top+V(0,0.17,0.13)*emerge,0.15,STEM,emerge)
	local open=phase(g,0.58,0.85)
	local nod=phase(g,0.84,1)
	local pitch=-1.05*(1-phase(g,0.48,0.76))+s.pitch*nod
	local at=top+V(0,0.25,0.16)*emerge
	local cf=CFrame.new(at)*CFrame.Angles(pitch,s.yaw,s.roll)
	local scale=s.headScale*(0.12+0.88*phase(g,0.44,0.94))
	local d=1.68*scale
	local diskVisible=phase(g,0.59,0.69)
	-- The closed bud is thick; flatten its back before exposing the disk so green geometry cannot poke through its face.
	local budThickness=1-phase(g,0.53,0.69)
	emit("HeadBack",V(d*1.03,d*1.03,(0.29+budThickness*1.20)*scale),cf*CFrame.new(0,0,-0.12*scale),STEM,emerge,"Fruit",1,"")
	local diskColor=if g>=0.98 then C(104,67,33) else YOUNG:Lerp(C(104,67,33),phase(g,0.72,0.98))
	local centreColor=if g>=0.98 then C(75,48,27) else C(175,159,65):Lerp(C(75,48,27),phase(g,0.74,0.98))
	emit("SeedDisk",V(d,d,0.32*scale),cf,diskColor,diskVisible,"Fruit",1,"")
	emit("DiskCentre",V(d*0.91,d*0.91,0.23*scale),cf*CFrame.new(0,0,0.075*scale),centreColor,diskVisible,"Fruit",1,"")
	if not proxy then
		for j,seed in s.seeds do
			local q=phase(g,0.80+0.04*j/42,0.96+0.03*j/42)
			local sc=scale*(0.45+0.55*q)
			emit("SeedTexture"..j,V(seed.size*0.77*sc,seed.size*sc,0.040*sc),
				cf*CFrame.new(math.cos(seed.angle)*seed.r*scale,math.sin(seed.angle)*seed.r*scale,seed.z*scale)*CFrame.Angles(0,0,seed.angle),
				seed.tone,q,"Fruit",1,"")
		end
	end
	for _,p in s.petals do
		if not proxy or (p.layer==1 and p.index%2==0) or (p.layer==2 and p.index%3==0) then
			local start=0.58+0.012*(p.layer-1)+0.035*(0.5+0.5*math.sin(p.angle))
			local q=phase(g,start,start+0.21)
			local petalScale=scale*(0.20+0.80*q)
			local len,width=p.len*petalScale,p.width*petalScale
			local f=cf*CFrame.new(0,0,if p.layer==2 then 0.045*scale else 0)
			local rf=f*CFrame.Angles(0,0,p.angle)*CFrame.new(0,d*0.42,-0.03*scale)*CFrame.Angles(1.35*(1-q)+p.bend*q,0,0)
			local tone=if q==1 then p.tone else PALE:Lerp(p.tone,phase(q,0.2,1))
			local id=p.layer.."_"..p.index
			emit("LayeredPetal"..id,V(width,len,0.075*petalScale),rf*CFrame.new(0,len*0.44,0),tone,phase(q,0,0.1),"Flower",1,"")
			if not proxy then
				emit("PetalFold"..id,V(width*0.69,len*0.54,0.06*petalScale),rf*CFrame.new(0,len*0.71,-len*0.055)*CFrame.Angles(0.22*q,0,0),
					tone:Lerp(PALE,0.19),phase(q,0,0.1),"Flower",1,"")
			end
		end
	end
	for j=1,7 do
		if not proxy or j%2==1 then
			local f=cf*CFrame.Angles(0,0,j*math.pi*2/7)
			emit("GreenBract"..j,V(d*0.16,d*0.35,0.07*scale),f*CFrame.new(0,d*0.37,-0.24*scale)*CFrame.Angles(0.9*(1-open)-0.35*open,0,0),
				LEAF,emerge,"Fruit",1,"")
		end
	end
	if not proxy then
		local sprout=phase(g,0,0.12)
		local seedVisible=1-phase(g,0.08,0.23)
		emit("SeedShell",V(0.13,0.23,0.11),CFrame.new(0,0.045,0)*CFrame.Angles(0,0,0.55),C(69,54,36),seedVisible,"Structure",nil,"")
		for side=-1,1,2 do
			local hinge=V(0,0.18+0.18*sprout,0)
			emit("Cotyledon"..side,V(0.20,0.045,0.44)*(0.2+0.8*sprout),CFrame.new(hinge)*CFrame.Angles(0,side*math.pi/2,0)*CFrame.Angles(-0.6*(1-sprout),0,0)*CFrame.new(0,0,0.17*sprout),
				YOUNG,phase(g,0.015,0.055)*(1-phase(g,0.24,0.39)),"Foliage",nil,"")
		end
	end
end

local function sphere(part)
	local name=part.Name
	if name:match("^Stem") or name:match("^Petiole") or name:match("^LeafPoint") or name:match("^LeafVein") or name=="Neck" then return end
	local mesh=Instance.new("SpecialMesh")
	mesh.MeshType=Enum.MeshType.Sphere
	mesh.Parent=part
end

Kit.recipe(SunflowerPlant,{
	name="SunflowerPlant",parts=192,shape=shape,geometry=geometry,proxyMid=0.72,
	onNew=function(self,_,soil)
		self.fruitSlots={{id=1,attachment=soil*CFrame.new(self.headAt)*CFrame.Angles(self.pitch,self.yaw,self.roll),parts={}}}
	end,
	onBuilt=function(self) for _,part in self.rig.parts do sphere(part) end end,
	onProxyPart=sphere,
})
return SunflowerPlant
