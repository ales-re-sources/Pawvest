-- CG18b: selected C, three vines on a fixed fan with heart leaves, pale purple-throated trumpets and red storage roots.
-- Review-only until growth art approval. 133 Parts: 5 supports + 12 stems + 72 foliage + 3 ties + 15 root + 26 flower.
local SweetPotatoPlant = {
	Draft = true,
	RingHeight = 5.0,
	FixedOrientation = true,
	FixedRingHeight = true,
	ReviewHeight = 4.8,
}
local Kit = require(script.Parent.PlantKit)
local phase, V, C = Kit.phase, Vector3.new, Color3.fromRGB
local GREEN, LIGHT, YOUNG = C(67,139,69), C(103,169,80), C(145,195,100)
local STEM, REDSTEM = C(105,146,65), C(145,78,91)
local WOOD, TIE = C(173,143,94), C(198,175,125)
local SKIN, FACET = C(166,76,91), C(194,100,108)
local CREAM, PINK, PURPLE, DARK = C(253,237,246), C(214,156,203), C(155,63,150), C(79,27,88)
local TIMES = {{0,0.23},{0.12,0.40},{0.32,0.62},{0.50,0.79}}
local LEAF_TIME = {{0.02,0.25},{0.25,0.48},{0.46,0.69},{0.65,0.88}}
local ROOTS = {
	{V(-0.48,0.14,0.46),-2.50,1.06,0.51},
	{V(0.29,0.16,0.71),-1.50,1.24,0.58},
	{V(0.81,0.11,0.19),-0.10,0.92,0.45},
}
local SLICES = {{-0.16,0.32,0.54},{0.08,0.34,0.88},{0.34,0.36,1},{0.60,0.30,0.70},{0.81,0.18,0.32}}
local SUPPORTS = {}
for i=-1,1 do table.insert(SUPPORTS,{V(i*0.20,0,-0.40),V(i*1.05,4.18,-0.40),0.10}) end
for j=1,2 do table.insert(SUPPORTS,{V(-j*0.43,j*1.42,-0.40),V(j*0.43,j*1.42,-0.40),0.075}) end

local function shape(seed, sizeFactor)
	local vary, ds = Kit.seeded(seed), Kit.dimension(sizeFactor)
	local tendency = Kit.tendency({{1,1,1},{0.87,1.03,0.95},{1.02,0.91,0.84}},seed)
	local s = {vines={},roots={},flowers={},dimension=ds,fruitSlots={}}
	for k=1,3 do
		local i=k-2
		local height=tendency[k]*(1+vary(0.04))
		local sway, depth, delay = vary(0.15),vary(0.11),(k-1)*0.018
		local path={V(i*0.15,0.10,-0.24)}
		local mature={V(i*0.34,1.05,-0.20),V(i*0.57+0.10,2.05,-0.24),V(i*0.78-0.10,3.04,-0.20),V(i*0.96,3.83,-0.20)}
		local vine={path=path,leaves={},delay=delay}
		for j,p in mature do
			path[j+1]=V(p.X+sway*j/4,p.Y*height,p.Z+depth*j/4)
			local yaw=(if (i+j+1)%2==0 then -1.1 else 1.1)+vary(0.33)
			local len=math.min(1.15,1.02*math.clamp(1+(ds-1)*0.20,0.92,1.08)*(1+vary(0.14)))
			vine.leaves[j]={yaw=yaw,tilt=0.65+vary(0.18),len=len,width=len*(0.90/1.02),
				offset=V(math.sin(yaw)*0.15,0.14,0.15),tone=(i+j+1)%3==0}
		end
		s.vines[k]=vine
	end
	for id,def in ROOTS do
		local offset=V(vary(0.06),0,vary(0.06))
		local fit=math.min(1,1/ds)
		local at=V((def[1].X+offset.X)*fit,def[1].Y*ds,(def[1].Z+offset.Z)*fit)
		s.roots[id]={cf=CFrame.new(at)*CFrame.Angles(0,def[2]+vary(0.16),0)*CFrame.Angles(0,0,1.15),
			len=def[3]*ds*(1+vary(0.10)),width=def[4]*ds*(1+vary(0.08))}
	end
	for id,def in {{1,3,V(-0.23,0.38,0.53),-0.25,0.69,0.48},{3,4,V(0.11,0.21,0.50),0.40,0.62,0.64}} do
		s.flowers[id]={vine=def[1],node=def[2],offset=def[3]+V(vary(0.08),vary(0.06),0),
			yaw=def[4]+vary(0.22),size=def[5]*(1+vary(0.12)),start=def[6]}
	end
	return s
end

local function rod(emit,name,a,b,width,color,q,role)
	emit(name,V(width,width,(b-a).Magnitude),Kit.axis(a,b),color,phase(q,0,0.08),role)
end
local function hidden(emit,name,role,slot)
	emit(name,V(0.01,0.01,0.01),CFrame.new(),GREEN,0,role,slot)
end

local function geometry(s,g,emit,proxy)
	local current={}
	for k,vine in s.vines do
		local pts={vine.path[1]}
		current[k]=pts
		for j=1,4 do
			local q=phase(g,TIMES[j][1]+vine.delay,TIMES[j][2]+vine.delay)
			if j==1 then q=0.12+0.88*q end
			-- A child's base is the current parent tip, never a mature fixed point.
			pts[j+1]=pts[j]:Lerp(vine.path[j+1],q)
			rod(emit,"Vine"..k.."Stem"..j,pts[j],pts[j+1],0.09, YOUNG:Lerp(if j==1 then REDSTEM else STEM,phase(g,0.08,0.42)),q,"Structure")
		end
		for j,leaf in vine.leaves do
			local t=LEAF_TIME[j]
			local q=phase(g,t[1]+vine.delay,t[2]+vine.delay)
			if k==2 and j==1 then q=0.16+0.84*q end
			local at=pts[j+1]
			local hinge=at+leaf.offset*q
			local name="Vine"..k.."Leaf"..j
			rod(emit,name.."Petiole",at,hinge,0.065,YOUNG:Lerp(REDSTEM,phase(g,0.10,0.50)),q,"Foliage")
			local cf=CFrame.new(hinge)*CFrame.Angles(0,leaf.yaw,0)*CFrame.Angles(-(1.48+(leaf.tilt-1.48)*q),0,0)
			local len,width=leaf.len*q,leaf.width*q
			local col=YOUNG:Lerp(if leaf.tone then LIGHT else GREEN,q)
			for side=-1,1,2 do
				if proxy then
					hidden(emit,name.."Lobe"..side,"Foliage")
				else
					emit(name.."Lobe"..side,V(width*0.54,0.055,len*0.47),cf*CFrame.new(side*width*0.20,0.004*side,len*0.28)*CFrame.Angles(0,side*0.23,0),col,phase(q,0,0.08),"Foliage",nil,"Studs")
				end
				local apex,corner=V(0,0,len),V(side*width*0.5,0,len*0.4)
				local wedge=cf*CFrame.fromMatrix((apex+corner)/2,Vector3.yAxis*-side,Vector3.zAxis,Vector3.xAxis*-side)
				emit(name.."Tip"..side,V(0.055,len*0.60,width*0.50),wedge,col,phase(q,0,0.08),"Foliage",nil,"Studs","WedgePart")
			end
			if proxy then hidden(emit,name.."Vein","Foliage") else
				emit(name.."Vein",V(0.025,0.025,len*0.76),cf*CFrame.new(0,0.044,len*0.51),C(138,177,97),phase(q,0,0.08),"Foliage")
			end
		end
		emit("Tie"..k,V(0.18,0.035,0.17),CFrame.new(pts[3]),TIE,phase(g,0.40+vine.delay,0.44+vine.delay),"Support")
	end
	for id,root in s.roots do
		local q=phase(g,0.58+(id-1)*0.025,1)
		local scale=0.08+0.92*q
		local show=phase(g,0.58+(id-1)*0.025,0.64+(id-1)*0.025)
		for j,slice in SLICES do
			if proxy and (j==1 or j==4) then hidden(emit,"Root"..id.."Slice"..j,"Fruit",id) else
				emit("Root"..id.."Slice"..j,V(root.width*slice[3],root.len*slice[2],root.width*slice[3]*0.74)*scale,
					root.cf*CFrame.new(0,-root.len*slice[1]*scale,0)*CFrame.Angles(0,0.18,0),
					PINK:Lerp(if j%2==0 then FACET else SKIN,phase(g,0.62,0.96)),show,"Fruit",id)
			end
		end
	end
	for id,flower in s.flowers do
		local q=phase(g,flower.start,flower.start+0.14)
		local at=current[flower.vine][flower.node]
		local center=at+flower.offset*q
		rod(emit,"Flower"..id.."Stalk",at,center,0.065,STEM,q,"Flower")
		local cf=CFrame.new(center)*CFrame.Angles(0,flower.yaw,0)*CFrame.Angles(math.rad(33),0,0)
		local size=flower.size*q
		for i=0,4 do
			local f=cf*CFrame.Angles(0,0,i*math.pi*0.4)
			if proxy then hidden(emit,"Flower"..id.."Funnel"..i,"Flower") else
				emit("Flower"..id.."Funnel"..i,V(size*0.37,size*0.42,size*0.45),f*CFrame.new(0,size*0.15,size*0.10)*CFrame.Angles(-0.58,0,0),PURPLE,phase(q,0,0.08),"Flower")
			end
			emit("Flower"..id.."Rim"..i,V(size*0.59,size*0.34,0.065),f*CFrame.new(0,size*0.35,size*0.36)*CFrame.Angles(-0.10,0,0),CREAM,phase(q,0,0.08),"Flower")
		end
		emit("Flower"..id.."Throat",V(size*0.29,size*0.29,0.055),cf*CFrame.new(0,0,size*0.28),DARK,phase(q,0,0.08),"Flower")
		if proxy then hidden(emit,"Flower"..id.."Pollen","Flower") else
			emit("Flower"..id.."Pollen",V(size*0.065,size*0.12,0.06),cf*CFrame.new(0,-size*0.025,size*0.32),PINK,phase(q,0,0.08),"Flower")
		end
	end
end

Kit.recipe(SweetPotatoPlant,{
	name="SweetPotatoPlant",parts=133,shape=shape,geometry=geometry,proxyMid=0.60,fixedParts=#SUPPORTS,
	onNew=function(self,rig,base)
		for id,root in self.roots do self.fruitSlots[id]={id=id,attachment=base*root.cf,parts={}} end
		for i,support in SUPPORTS do
			local p=rig:add("FanSupport"..i,"StudsSmall","Support")
			p.Size,p.CFrame,p.Color,p.Transparency=V(support[3],support[3],(support[2]-support[1]).Magnitude),base*Kit.axis(support[1],support[2]),WOOD,0
		end
	end,
	onProxy=function(parent,base)
		for i,support in SUPPORTS do Kit.proxyRod(parent,base,"FanSupport"..i,support[1],support[2],support[3],WOOD,"Support") end
	end,
})
return SweetPotatoPlant
