-- CG16b: Studio client only. Disposable geometry; no remotes or profile writes.
assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient(), "Studio client only")
local Recipe=require(game.ReplicatedStorage.EggplantPlant)
local Crops=require(game.ReplicatedStorage.CropConfig)
local Growth=require(game.ReplicatedStorage.PlantGrowth)
local low,high=Crops.SizeBounds()
local V=Vector3.new
local base=CFrame.new(0,20,0)*CFrame.Angles(0,0.73,0)
local parent=Instance.new("Folder")
local radius,height,minRipe,maxRipe,minClear=0,0,math.huge,0,math.huge
local identities,baseline,proxies={},{},{}
local function measure(model,filter)
	local r,lo,hi,n=0,V(math.huge,math.huge,math.huge),V(-math.huge,-math.huge,-math.huge),0
	for _,p in model:GetChildren() do
		if not p:IsA("BasePart") or p.Transparency>=0.99 or (filter and not filter(p)) then continue end
		n+=1
		for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
			local at=base:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size*V(x,y,z)/2))
			assert(at.X==at.X and at.Y==at.Y and at.Z==at.Z,"Non-finite pose")
			r=math.max(r,V(at.X,0,at.Z).Magnitude);lo=lo:Min(at);hi=hi:Max(at)
		end end end
	end
	return r,lo,hi,n
end
local function snapshot(p)
	local pose={}
	for i,part in p.rig.parts do pose[i]={part,part.CFrame,part.Size,part.Color,part.Transparency} end
	return pose
end
local function same(p,pose)
	for i,part in p.rig.parts do
		local old=pose[i]
		assert(part==old[1] and part.Transparency==old[5],"Changed instance or visibility on seek")
		if part.Transparency<1 then assert(part.CFrame==old[2] and part.Size==old[3] and part.Color==old[4],"Backward seek mismatch: "..part.Name) end
	end
end
local function ends(part)
	local d=part.CFrame.LookVector*part.Size.Z/2
	return part.Position+d,part.Position-d
end
local function near(a,b,name) assert((a-b).Magnitude<0.001,"Detached "..name..": "..(a-b).Magnitude) end
local function attached(p)
	for i,s in p.segments do
		local part=p.model["Stem"..i]
		if part.Transparency>=0.5 or s.parent==0 then continue end
		near(ends(part),select(2,ends(p.model["Stem"..s.parent])),part.Name)
	end
	for i,leaf in p.leaves do
		local petiole=p.model["Leaf"..i.."Petiole"]
		if petiole.Transparency<0.5 then
			near(ends(petiole),select(2,ends(p.model["Stem"..leaf.parent])),petiole.Name)
			-- The centre plate overlaps its hinge by 4% of blade length; the vein runs into the petiole.
			local tip=select(2,ends(petiole))
			local centre=p.model["Leaf"..i.."Centre"]
			assert((tip-centre.Position).Magnitude<centre.Size.Z*0.57,"Detached blade")
		end
	end
	for id,f in p.fruits do
		local a,b=p.model["Fruit"..id.."StalkA"],p.model["Fruit"..id.."StalkB"]
		if a.Transparency<0.5 then
			near(ends(a),select(2,ends(p.model["Stem"..f.parent])),a.Name)
			near(select(2,ends(a)),ends(b),b.Name)
			if p.model["Fruit"..id.."Calyx"].Transparency<0.5 then
				assert((select(2,ends(b))-p.model["Fruit"..id.."Calyx"].Position).Magnitude<0.016,"Detached calyx")
			end
		end
	end
end
for _,mass in {low,1,high} do for seed=1,6 do
	local p=Recipe.new(parent,base,seed,mass)
	assert(#p.rig.parts==113 and #p.fruitSlots==3,"Topology changed")
	local initial=snapshot(p)
	for id,slot in p.fruitSlots do
		assert(slot.id==id and #slot.parts==22,"Fruit group changed")
		for _,part in slot.parts do assert(part:GetAttribute("PlantRole")=="Fruit" and part:GetAttribute("FruitSlot")==id,"Missing organ metadata") end
	end
	for step=0,100 do
		p:SetGrowth(step/100)
		local r,_,hi=measure(p.model)
		assert(r<=2.4001,"Footprint exceeded "..seed.."/"..mass.."/"..step..": "..r)
		radius,height=math.max(radius,r),math.max(height,hi.Y)
		attached(p)
		if step==0 then assert(hi.Y<0.3 and p.model.Cotyledon1.Transparency==0 and p.model.Fruit1Body1a.Transparency==1,"Bad seedling") end
		if step<=35 then
			assert(p.model.Stem1.Color.G>p.model.Stem1.Color.R and p.model.Stem1.Color.G>p.model.Stem1.Color.B,"Young stem is not green")
		end
		if step==50 then
			local tint=p.model.Leaf1Petiole.Color
			assert(tint~=Color3.fromRGB(104,146,65) and tint~=Color3.fromRGB(100,73,100),"Petiole tint skipped its halfway transition")
		end
		if step<=58 then assert(p.model.Fruit1Body1a.Transparency==1,"Fruit before flowering") end
		if step==50 then assert(p.model.Fruit1Petal1.Transparency<0.1,"Flower not open at 50%") end
		if step==100 then
			assert(p.model.Stem1.Color==Color3.fromRGB(100,73,100) and p.model.Leaf1Petiole.Color==Color3.fromRGB(100,73,100),"Mature purple tint missing")
			local _,lo=measure(p.model,function(part) return string.find(part.Name,"Body",1,true)~=nil end)
			assert(lo.Y>=0.18,"Fruit touches soil: "..lo.Y)
			minClear=math.min(minClear,lo.Y)
			assert(p.model.Fruit1Petal1.Transparency==1 and p.model.Fruit1Pollen.Transparency==1,"Spent flower retained")
			for _,slot in p.fruitSlots do near(slot.attachment.Position,p.model["Fruit"..slot.id.."Calyx"].Position+slot.attachment.UpVector*0.015,"Stable fruit attachment") end
		end
		if step%20==0 then task.wait() end
	end
	local _,_,hi=measure(p.model)
	minRipe,maxRipe=math.min(minRipe,hi.Y),math.max(maxRipe,hi.Y)
	if seed==1 and mass==1 then
		assert(math.abs(p.leaves[1].len/(1.33*1.10)-1.85)<0.001 and math.abs(p.leaves[1].width/(0.94*1.25)-1.85)<0.001,"Leaf enlargement lost")
		baseline={height=hi.Y,radius=measure(p.model),clearance=minClear,leafLength=p.leaves[1].len,leafWidth=p.leaves[1].width}
	end
	assert(p.model.Cotyledon1.Transparency==1 and p.model.Cotyledon2.Transparency==1,"Mature seed leaves")
	for _,g in {0,0.20,0.43,0.50,0.59,0.75,0.88,0.99} do
		p:SetGrowth(g);local pose=snapshot(p);p:SetGrowth(g+0.01);p:SetGrowth(g);same(p,pose)
	end
	p:SetGrowth(1);p:SetGrowth(0);same(p,initial)
	for stage=1,3 do
		local proxy=Instance.new("Model")
		Recipe.BuildProxy(proxy,base,stage,seed,mass)
		local r,lo,_,count=measure(proxy)
		assert(count>=5 and count<=40 and r<=2.4001,"Proxy bounds/budget failed: "..stage.."/"..seed.."/"..mass..": "..r)
		for _,part in proxy:GetChildren() do
			assert(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery and not part.CastShadow,"Proxy intercepts input/physics")
		end
		if stage>=2 then
			for id=1,3 do
				local calyx=proxy:FindFirstChild("Fruit"..id.."Calyx")
				assert(calyx and calyx:GetAttribute("FruitSlot")==id,"Proxy lost a fruit slot")
			end
			assert(lo.Y>=-0.11,"Proxy extends below soil")
		end
		if seed==1 and mass==1 then proxies[stage]=count end
		proxy:Destroy()
	end
	for _,part in p.rig.parts do assert(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery,"Art intercepts input/physics") end
	if mass==1 then p:SetGrowth(1);identities[seed]=tostring(p.model.Stem4.CFrame)..tostring(p.model.Leaf1Centre.CFrame)..tostring(p.model.Fruit1Body3a.Size) end
	p:Destroy();task.wait()
end end
for i=1,6 do for j=i+1,6 do assert(identities[i]~=identities[j],"Identical seeds") end end
parent:Destroy()
assert(Growth.Supports("Eggplant") and Crops.ById.Eggplant.growSeconds==14400 and Growth.UpdateInterval(14400)==30,"Registry/production timing changed")
return game.HttpService:JSONEncode({seeds=6,masses={low,1,high},ages=101,parts=113,fieldParts=4068,
	maxRadius=radius,tallestAnyAge=height,ripeHeight={minRipe,maxRipe},fruitClearance=minClear,baseline=baseline,proxies=proxies})
