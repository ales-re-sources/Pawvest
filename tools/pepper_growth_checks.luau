-- CG8 Studio-client acceptance checks. Display-only; no remotes or profile writes.
local Recipe = require(game.ReplicatedStorage.PepperPlant)
local Growth = require(game.ReplicatedStorage.PlantGrowth)
local CropConfig = require(game.ReplicatedStorage.CropConfig)
local low,high = CropConfig.SizeBounds()
local V = Vector3.new
local base = CFrame.new(0,20,0)*CFrame.Angles(0,0.73,0)
local parent = Instance.new("Folder")
local maxRadius,minFruitY,minHeight,maxHeight = 0,math.huge,math.huge,0
local proxies,identities = {},{}
local function radiusHeight(model)
	local radius,height,fruitY = 0,0,math.huge
	for _,p in model:GetDescendants() do if p:IsA("BasePart") and p.Transparency<0.99 then
		for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
			local c=base:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size/2*V(x,y,z)))
			radius=math.max(radius,V(c.X,0,c.Z).Magnitude)
			height=math.max(height,c.Y)
			if p.Name:find("Shoulder") or p.Name:find("LowerLobe") then fruitY=math.min(fruitY,c.Y) end
		end end end
	end end
	return radius,height,fruitY
end
local function snapshot(plant)
	local out={}
	for i,p in plant.rig.parts do
		out[i]={part=p,cf=p.CFrame,size=p.Size,color=p.Color,alpha=p.Transparency}
	end
	return out
end
local function same(plant,pose)
	for i,p in plant.rig.parts do
		local old=pose[i]
		assert(p==old.part and p.Transparency==old.alpha,"Instance/visibility changed on backward seek")
		if p.Transparency<1 then
			assert(p.CFrame==old.cf and p.Size==old.size and p.Color==old.color,"Visible backward seek mismatch")
		end
	end
end
assert(Growth.Supports("Pepper"),"Pepper not registered")
for _,size in {low,1,high} do
	for seed=1,6 do
		local plant=Recipe.new(parent,base,seed,size)
		assert(#plant.rig.parts==90 and #plant.fruitSlots==3,"Topology/slots changed")
		for id,slot in plant.fruitSlots do
			assert(slot.id==id and #slot.parts==16,"Fruit group incomplete")
			for _,part in slot.parts do assert(part:GetAttribute("FruitSlot")==id and part:GetAttribute("PlantRole")=="Fruit") end
		end
		local initial=snapshot(plant)
		for step=0,100 do
			plant:SetGrowth(step/100)
			local r,_,fy=radiusHeight(plant.model)
			maxRadius=math.max(maxRadius,r); minFruitY=math.min(minFruitY,fy)
			assert(r<=2.4001,"All-age footprint exceeded: seed "..seed..", mass "..size..", growth "..step..", radius "..r)
			assert(fy>=0.10,"Pepper clips soil")
			local cursor=8
			for i,leaf in plant.leaves do
				local plate=plant.rig.parts[cursor]
				local stem=plant.rig.parts[leaf.parent]
				if plate.Transparency<0.5 and stem.Transparency<0.5 then
					local a=stem.Position+stem.CFrame.LookVector*stem.Size.Z/2
					local b=stem.Position-stem.CFrame.LookVector*stem.Size.Z/2
					local hinge=plate.Position+plate.CFrame.LookVector*plate.Size.Z/2
					assert((hinge-a:Lerp(b,leaf.t)).Magnitude<0.02,"Detached leaf")
				end
				cursor+=leaf.pieces
			end
			-- Visible fruit stalks must meet the extending parent stem and their calyx.
			for id,f in plant.fruits do
				local parts=plant.fruitSlots[id].parts
				if parts[1].Transparency<0.5 then
					local stem=plant.rig.parts[f.parent]
					local tip=stem.Position-stem.CFrame.LookVector*stem.Size.Z/2
					local start=parts[1].Position+parts[1].CFrame.LookVector*parts[1].Size.Z/2
					local finish=parts[2].Position-parts[2].CFrame.LookVector*parts[2].Size.Z/2
					assert((tip-start).Magnitude<0.005,"Detached fruit stalk")
					if parts[3].Transparency<0.5 then assert((finish-parts[3].Position).Magnitude<0.005,"Detached calyx") end
				end
			end
		end
		local _,height=radiusHeight(plant.model)
		minHeight=math.min(minHeight,height); maxHeight=math.max(maxHeight,height)
		for _,g in {0,0.43,0.58,0.75,1} do
			plant:SetGrowth(g); local pose=snapshot(plant)
			plant:SetGrowth(math.min(1,g+0.01)); plant:SetGrowth(g); same(plant,pose)
		end
		plant:SetGrowth(0); same(plant,initial)
		plant:SetGrowth(1); local ripe=snapshot(plant)
		plant:SetGrowth(1); same(plant,ripe)
		for stage=1,3 do
			local proxy=Instance.new("Model")
			Recipe.BuildProxy(proxy,base,stage,seed,size)
			local r=radiusHeight(proxy)
			assert(r<=2.4001,"Proxy footprint exceeded")
			if size==1 and seed==1 then proxies[stage]=#proxy:GetChildren() end
			proxy:Destroy()
		end
		if size==1 then identities[seed]=tostring(plant.rig.parts[4].CFrame)..tostring(plant.rig.parts[8].Size) end
		plant:Destroy()
		task.wait()
	end
end
for i=1,6 do for j=i+1,6 do assert(identities[i]~=identities[j],"Seed silhouettes identical") end end
parent:Destroy()
return game.HttpService:JSONEncode({seeds=6,masses={low,1,high},ages=101,parts=90,fieldParts=3240,
	maxRadius=maxRadius,minFruitClearance=minFruitY,ripeHeight={minHeight,maxHeight},proxies=proxies,
	productionSeconds=CropConfig.ById.Pepper.growSeconds,interval=Growth.UpdateInterval(CropConfig.ById.Pepper.growSeconds)})
