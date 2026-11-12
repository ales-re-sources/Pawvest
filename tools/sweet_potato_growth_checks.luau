-- CG18b geometry acceptance, Studio client only. Disposable models; no remotes or saved-data edits.
assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient(),"Studio client only")
local Recipe=require(game.ReplicatedStorage.SweetPotatoPlant)
local Crops=require(game.ReplicatedStorage.CropConfig)
local Growth=require(game.ReplicatedStorage.PlantGrowth)
local low,high=Crops.SizeBounds()
local V=Vector3.new
local base=CFrame.new(0,20,0)*CFrame.Angles(0,0.73,0)
local parent=Instance.new("Folder")
local maxRadius,maxHeight,identities,proxies=0,0,{},{}
local baseline={}
local function measure(model)
	local radius,height,count=0,0,0
	for _,part in model:GetChildren() do
		if not part:IsA("BasePart") or part.Transparency>=0.99 then continue end
		count+=1
		for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
			local p=base:PointToObjectSpace(part.CFrame:PointToWorldSpace(part.Size*V(x,y,z)/2))
			assert(p.X==p.X and p.Y==p.Y and p.Z==p.Z,"Non-finite pose")
			radius=math.max(radius,V(p.X,0,p.Z).Magnitude); height=math.max(height,p.Y)
		end end end
	end
	return radius,height,count
end
local function snapshot(plant)
	local pose={}
	for i,p in plant.rig.parts do pose[i]={p,p.CFrame,p.Size,p.Color,p.Transparency} end
	return pose
end
local function same(plant,pose)
	for i,p in plant.rig.parts do
		local old=pose[i]
		assert(p==old[1] and p.Transparency==old[5],"Instance/visibility changed on seek")
		if p.Transparency<1 then assert(p.CFrame==old[2] and p.Size==old[3] and p.Color==old[4],"Seek mismatch: "..p.Name) end
	end
end
local function ends(p)
	local d=p.CFrame.LookVector*p.Size.Z/2
	return p.Position+d,p.Position-d
end
local function near(a,b,label) assert((a-b).Magnitude<0.001,"Detached "..label..": "..(a-b).Magnitude) end
local function attached(plant)
	for k=1,3 do
		for j=1,4 do
			local stem=plant.model["Vine"..k.."Stem"..j]
			if stem.Transparency<0.5 and j>1 then near(ends(stem),select(2,ends(plant.model["Vine"..k.."Stem"..(j-1)])),stem.Name) end
		end
		for j,leaf in plant.vines[k].leaves do
			local petiole=plant.model["Vine"..k.."Leaf"..j.."Petiole"]
			if petiole.Transparency<0.5 then
				local start=ends(plant.model["Vine"..k.."Stem"..leaf.segment])
				local finish=select(2,ends(plant.model["Vine"..k.."Stem"..leaf.segment]))
				near(ends(petiole),start:Lerp(finish,leaf.fraction),petiole.Name)
			end
		end
	end
	for id,f in plant.flowers do
		local stalk=plant.model["Flower"..id.."Stalk"]
		if stalk.Transparency<0.5 then near(ends(stalk),select(2,ends(plant.model["Vine"..f.vine.."Stem"..(f.node-1)])),stalk.Name) end
	end
end
for _,mass in {low,1,high} do for seed=1,6 do
	local plant=Recipe.new(parent,base,seed,mass)
	assert(#plant.rig.parts==169 and #plant.fruitSlots==3 and #plant.vines[1].leaves==6,"Topology changed")
	local supports={}
	for i=1,5 do local p=plant.model["FanSupport"..i]; supports[i]={p.CFrame,p.Size} end
	for id,slot in plant.fruitSlots do
		assert(id==slot.id and #slot.parts==5,"Root slot changed")
		near(slot.attachment.Position,(base*plant.roots[id].cf).Position,"Root attachment")
		for _,part in slot.parts do assert(part:GetAttribute("PlantRole")=="Fruit" and part:GetAttribute("FruitSlot")==id,"Missing root metadata") end
	end
	for step=0,100 do
		plant:SetGrowth(step/100)
		local radius,height=measure(plant.model)
		assert(radius<=2.4001,"Footprint exceeded "..seed.."/"..mass.."/"..step..": "..radius)
		maxRadius,maxHeight=math.max(maxRadius,radius),math.max(maxHeight,height)
		attached(plant)
		for i=1,5 do local p=plant.model["FanSupport"..i]; assert(p.CFrame==supports[i][1] and p.Size==supports[i][2] and p.Transparency==0,"Support grew/moved") end
		if step<58 then assert(plant.model.Root1Slice3.Transparency==1,"Roots appeared too early") end
		if step==100 and mass==1 and seed==1 then baseline={radius=radius,height=height} end
		if step%20==0 then task.wait() end
	end
	for _,g in {0,0.20,0.43,0.50,0.59,0.75,0.88,0.99} do
		plant:SetGrowth(g); local pose=snapshot(plant); plant:SetGrowth(g+0.01); plant:SetGrowth(g); same(plant,pose)
	end
	plant:SetGrowth(0); local initial=snapshot(plant); plant:SetGrowth(1); plant:SetGrowth(0); same(plant,initial)
	plant:SetGrowth(1)
	if mass==1 then identities[seed]=tostring(plant.model.Vine1Leaf4Tip1.CFrame)..tostring(plant.model.Root2Slice3.Size) end
	for stage=1,3 do
		local proxy=Instance.new("Model")
		Recipe.BuildProxy(proxy,base,stage,seed,mass)
		local radius,_,count=measure(proxy)
		assert(radius<=2.4001 and count>5 and count<100,"Proxy bounds/budget")
		if mass==1 and seed==1 then proxies[stage]=count end
		for _,part in proxy:GetChildren() do assert(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery and not part.CastShadow,"Proxy intercepts input/physics") end
		proxy:Destroy()
	end
	for _,part in plant.rig.parts do assert(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery,"Art intercepts input/physics") end
	plant:Destroy(); task.wait()
end end
for i=1,6 do for j=i+1,6 do assert(identities[i]~=identities[j],"Identical seeds") end end
-- Rigid equipment is identical even when harvest mass changes.
local small,big=Recipe.new(parent,base,1,low),Recipe.new(parent,base,1,high)
for i=1,5 do assert(small.rig.parts[i].Size==big.rig.parts[i].Size and small.rig.parts[i].CFrame==big.rig.parts[i].CFrame,"Mass scaled equipment") end
assert(math.abs(big.roots[1].len/small.roots[1].len-(high/low)^(1/3))<0.0001,"Root mass scale")
small:Destroy(); big:Destroy(); parent:Destroy()
assert(Recipe.Draft and not Growth.Supports("SweetPotato"),"Draft entered the field")
assert(Crops.ById.SweetPotato.growSeconds==28800 and Growth.UpdateInterval(28800)==30,"Production timing changed")
return game.HttpService:JSONEncode({parts=169,fieldParts=6084,seeds=6,masses={low,1,high},ages=101,
	maxRadius=maxRadius,maxHeight=maxHeight,baseline=baseline,proxyParts=proxies,draft=Recipe.Draft})
