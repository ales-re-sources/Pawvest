-- CG10b Studio-client checks. Disposable models, no remotes or direct profile writes.
assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient(),"Studio client only")
local Recipe=require(game.ReplicatedStorage.GoldenCarrotPlant)
local CropConfig=require(game.ReplicatedStorage.CropConfig)
local low,high=CropConfig.SizeBounds()
local V=Vector3.new
local base=CFrame.new(0,20,0)*CFrame.Angles(0,0.73,0)
local parent=Instance.new("Folder")
local maxRadius,minHeight,maxHeight=0,math.huge,0
local proxies,identities,baseline={}, {}, {}
local function measure(model,rootsOnly)
	local lo,hi=V(math.huge,math.huge,math.huge),V(-math.huge,-math.huge,-math.huge)
	local radius,visible=0,0
	for _,p in model:GetDescendants() do
		if not p:IsA("BasePart") or p.Transparency>=0.99 or (rootsOnly and not p.Name:match("^Root_%d")) then continue end
		visible+=1
		for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
			local at=base:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size/2*V(x,y,z)))
			lo,hi=lo:Min(at),hi:Max(at)
			radius=math.max(radius,V(at.X,0,at.Z).Magnitude)
		end end end
	end
	return radius,lo,hi,visible
end
local function snapshot(plant)
	local out={}
	for i,p in plant.rig.parts do out[i]={p,p.CFrame,p.Size,p.Color,p.Transparency,p.Reflectance} end
	return out
end
local function same(plant,pose)
	for i,p in plant.rig.parts do
		local old=pose[i]
		assert(p==old[1] and p.Transparency==old[5],"Instance or visibility changed on seek")
		if p.Transparency<1 then
			assert(p.CFrame==old[2] and p.Size==old[3] and p.Color==old[4] and p.Reflectance==old[6],"Visible backward seek mismatch")
		end
	end
end
local function segment(part)
	local delta=part.CFrame.LookVector*(part.Size.Z/2-0.0075)
	return part.Position+delta,part.Position-delta
end
local function attached(plant)
	for n=1,7 do
		local name="Frond_"..n.."_"
		local spine=plant.model:FindFirstChild(name.."Spine")
		local lower=spine or plant.model[name.."Lower"]
		local upper=spine or plant.model[name.."Upper"]
		if lower.Transparency<0.5 and upper.Transparency<0.5 and not spine then
			local _,b=segment(lower);local c=segment(upper)
			assert((b-c).Magnitude<0.0001,"Detached successive stalk")
		end
		for pair,t in {0.38,0.61,0.81} do
			local stem=if spine or t<=0.52 then lower else upper
			local st=if spine then t elseif t<=0.52 then t/0.52 else (t-0.52)/0.48
			for _,side in {-1,1} do
				local leaf=plant.model[name.."Leaf_"..pair.."_"..side]
				if leaf.Transparency<0.5 and stem.Transparency<0.5 then
					local a,b=segment(stem)
					local hinge=leaf.Position+leaf.CFrame.LookVector*leaf.Size.Z/2
					assert((hinge-a:Lerp(b,st)).Magnitude<0.002,"Detached leaflet")
				end
			end
		end
	end
end
for _,mass in {low,1,high} do for seed=1,6 do
	local p=Recipe.new(parent,base,seed,mass)
	assert(#p.rig.parts==72 and not p.fruitSlots,"Topology/whole-root contract changed")
	local initial=snapshot(p)
	for step=0,100 do
		p:SetGrowth(step/100)
		local radius,_,_,visible=measure(p.model)
		assert(visible>=2,"Empty growth pose")
		assert(radius<=2.4001,"Footprint exceeded at seed "..seed..", mass "..mass..", growth "..step..": "..radius)
		maxRadius=math.max(maxRadius,radius)
		assert(p.glint.Enabled==(step==100),"Glints enabled before ripe")
		attached(p)
		if step%20==0 then task.wait() end
	end
	local _,lo,hi=measure(p.model,true)
	local full=hi.Y-lo.Y
	assert(math.abs(-lo.Y/full-2/3)<0.0001,"Mature root burial changed")
	assert(full/math.max(hi.X-lo.X,hi.Z-lo.Z)>=1.5,"Root became squat")
	local _,_,top=measure(p.model)
	minHeight,maxHeight=math.min(minHeight,top.Y),math.max(maxHeight,top.Y)
	if seed==1 and mass==1 then
		baseline={height=top.Y,rootLength=full,rootVisible=hi.Y,rootWidth=math.max(hi.X-lo.X,hi.Z-lo.Z)}
		assert(math.abs(top.Y-4.1722)<0.08 and math.abs(hi.Y-0.7)<0.001,"Approved baseline changed")
	end
	for _,g in {0,0.20,0.43,0.75,0.99} do
		p:SetGrowth(g);local pose=snapshot(p)
		p:SetGrowth(g+0.01);p:SetGrowth(g);same(p,pose)
	end
	p:SetGrowth(1);p:SetGrowth(0);same(p,initial)
	assert(not p.glint.Enabled,"Backward seek retained glints")
	for stage=1,3 do
		local proxy=Instance.new("Model")
		Recipe.BuildProxy(proxy,base,stage,seed,mass)
		local r,_,_,visible=measure(proxy)
		assert(visible>=2 and r<=2.4001,"Empty or oversized proxy")
		if mass==1 and seed==1 then proxies[stage]=#proxy:GetChildren() end
		proxy:Destroy()
	end
	for _,part in p.rig.parts do
		assert(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery,"Art intercepts input/physics")
	end
	if mass==1 then p:SetGrowth(1);identities[seed]=tostring(p.model.Frond_4_Lower.CFrame)..tostring(p.model.Frond_4_Leaf_1_1.Size) end
	p:Destroy()
	task.wait()
end end
for i=1,6 do for j=i+1,6 do assert(identities[i]~=identities[j],"Seed forms identical") end end
parent:Destroy()
return game.HttpService:JSONEncode({seeds=6,masses={low,1,high},ages=101,parts=72,fieldParts=2592,maxRadius=maxRadius,
	ripeHeight={minHeight,maxHeight},proxies=proxies,baseline=baseline,productionSeconds=CropConfig.ById.GoldenCarrot.growSeconds})
