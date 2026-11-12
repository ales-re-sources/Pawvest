-- CG20b Studio Edit check: six seeds x three harvested masses x 101 ages, rotated roots, finite visible Part corners,
-- 2.4-stud footprint, fixed topology/meshes, explicit head slot, backward seeks, deterministic identity and smaller proxies.
-- Disposable geometry only: no remotes, profiles or saved data. A fresh clone avoids Edit require caching after file edits.
assert(game:GetService("RunService"):IsStudio() and game.PlaceId==73033440513091,"Pawvest Studio only")
local source=game.ReplicatedStorage.SunflowerPlant:Clone()
source.Name="SunflowerPlantCheck"
source.Parent=game.ReplicatedStorage
local Plant=require(source)
source:Destroy()
assert(Plant.Draft==true,"Growth review must stay out of the field")
local V=Vector3.new
local minimumMass,maximumMass=require(game.ReplicatedStorage.CropConfig).SizeBounds()
local folder=Instance.new("Folder")
folder.Name="SunflowerChecks"
folder.Parent=workspace
local report={parts=192,meshes=141,runs=0,poses=0,maxRadius=0,maxTop=0,seekChecks=0,proxy={},standardTop=0,attachmentChecks=0}
local function signature(model)
	local out={}
	for _,p in model:GetChildren() do
		if p:IsA("BasePart") and p.Transparency<0.99 then
			local values={p.Transparency,p.Size.X,p.Size.Y,p.Size.Z,p.Color.R,p.Color.G,p.Color.B,p.CFrame:GetComponents()}
			local fields={p.Name}
			for _,v in values do table.insert(fields,string.format("%.5f",v)) end
			table.insert(out,table.concat(fields,","))
		end
	end
	return table.concat(out,"|")
end
local ok,err=xpcall(function()
	for seed=1,6 do for _,mass in {minimumMass,1,maximumMass} do
		local soil=CFrame.new(0,500,0)*CFrame.Angles(0,(seed-1)*0.73,0)
		local plant=Plant.new(folder,soil,seed,mass)
		assert(#plant.model:GetChildren()==192,"Part topology")
		local meshes=0
		for _,v in plant.model:GetDescendants() do
			if v:IsA("SpecialMesh") then meshes+=1 end
			if v:IsA("BasePart") then assert(v.Anchored and not v.CanCollide and not v.CanTouch and not v.CanQuery,"Local art physics") end
		end
		assert(meshes==141,"Mesh topology")
		assert(#plant.fruitSlots==1 and plant.fruitSlots[1].id==1 and #plant.fruitSlots[1].parts==120,"Head slot")
		local instances=#plant.model:GetDescendants()
		for step=0,100 do
			plant:SetGrowth(step/100)
			local model=plant.model
			for j=1,4 do
				local a,b=model["Stem"..j],model["Stem"..j+1]
				if a.Transparency<0.99 and b.Transparency<0.99 then
					assert(((a.Position-a.CFrame.LookVector*a.Size.Z/2)-(b.Position+b.CFrame.LookVector*b.Size.Z/2)).Magnitude<0.001,"Detached stem")
					report.attachmentChecks+=1
				end
			end
			for j=1,9 do
				local blade,petiole=model["LeafShoulders"..j],model["PetioleTip"..j]
				if blade.Transparency<0.99 then
					local hinge=petiole.Position-petiole.CFrame.LookVector*petiole.Size.Z/2
					local edge=blade.CFrame:PointToWorldSpace(V(0,0,-blade.Size.Z/2))
					assert((hinge-edge).Magnitude<0.001,"Leaf did not unfold from petiole")
					report.attachmentChecks+=1
				end
			end
			if step>=69 then
				local back,disk=model.HeadBack,model.DiskCentre
				local backFront=disk.CFrame:PointToObjectSpace(back.Position).Z+back.Size.Z/2
				assert(backFront<disk.Size.Z/2,"Green bud backing protrudes through the disk")
			end
			for _,p in plant.model:GetChildren() do if p.Transparency<0.99 then
				for _,n in {p.CFrame:GetComponents()} do assert(n==n and math.abs(n)<math.huge,"Non-finite pose") end
				for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
					local rel=soil:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size*V(x,y,z)/2))
					local r=V(rel.X,0,rel.Z).Magnitude
					report.maxRadius=math.max(report.maxRadius,r)
					report.maxTop=math.max(report.maxTop,rel.Y)
					assert(r<=2.4,"Footprint: seed "..seed.." mass "..mass.." age "..step.." "..p.Name.." radius "..r)
					if seed==1 and mass==1 and step==100 then report.standardTop=math.max(report.standardTop,rel.Y) end
				end end end
			end end
			report.poses+=1
			if step%20==0 then task.wait() end
		end
		assert(#plant.model:GetDescendants()==instances,"Growth created instances")
		for _,seek in {{0.43,0.44},{0.86,0.12},{1,0}} do
			plant:SetGrowth(seek[1]); local before=signature(plant.model)
			plant:SetGrowth(seek[2]); plant:SetGrowth(seek[1])
			assert(signature(plant.model)==before,"Backward seek changed visible pose")
			report.seekChecks+=1
		end
		local copy=Plant.new(folder,soil,seed,mass)
		copy:SetGrowth(1); plant:SetGrowth(1)
		assert(signature(copy.model)==signature(plant.model),"Identity changed on rebuild")
		copy:Destroy(); plant:Destroy()
		report.runs+=1
	end end
	assert(report.standardTop>5.18 and report.maxTop<Plant.RingHeight,"Height/ring contract")
	for stage=1,3 do
		local proxy=Instance.new("Folder"); proxy.Parent=folder
		Plant.BuildProxy(proxy,CFrame.new(0,500,0),stage,1,1)
		report.proxy[stage]=#proxy:GetChildren()
		assert(report.proxy[stage]>0 and report.proxy[stage]<192,"Proxy must be smaller")
		for _,p in proxy:GetChildren() do assert(p.Transparency<0.99,"Invisible proxy placeholder") end
		proxy:Destroy()
	end
end,debug.traceback)
folder:Destroy()
if not ok then error(err) end
return game.HttpService:JSONEncode(report)
