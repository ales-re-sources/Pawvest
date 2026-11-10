-- CG10c Studio client acceptance: production PlotView, disposable public-feed fixtures, no remotes/profile writes.
assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient(),"Studio client only")
local PlotView=require(game.Players.LocalPlayer.PlayerScripts.PlotView)
local Registry=require(game.ReplicatedStorage.PlantGrowth)
local Config=require(game.ReplicatedStorage.CropConfig)
local crop=Config.ById.GoldenCarrot
assert(Registry.Supports(crop.id) and crop.growSeconds==21600,"Registry/timing changed")
local low,high=Config.SizeBounds()
local root=Instance.new("Folder")
root.Name="GoldenCarrotIntegration"
root.Parent=workspace
local view=PlotView.new(13,root)
local function state()
	local cells=table.create(36,"#0")
	for n=1,12 do cells[n]=".0" end
	cells[3],cells[4],cells[9]="e1","e2","e3"
	local now=workspace:GetServerTimeNow()
	return {ownerId=9892673032,name="CG10c",incCount=1,eggs={},field={crops=table.concat(cells),pets={"Cat:3:carrot:4:1:1"},plants={
		["3"]={n=31,size=low,startAt=now-2160,readyAt=now+19440},
		["4"]={n=32,size=1,startAt=now-12960,readyAt=now+8640},
		["9"]={n=33,size=high,startAt=0,readyAt=0},
	}}}
end
local function flush()
	while view:Step(os.clock()+0.006) do task.wait() end
end
local function cropParts()
	local count=0
	for _,entry in view.plants do count+=#entry.plant.rig.parts end
	return count
end
local function snapshot(model)
	local out={}
	for _,p in model:GetChildren() do if p:IsA("BasePart") then out[p.Name]={cf=p.CFrame,size=p.Size,color=p.Color,alpha=p.Transparency} end end
	return out
end
local function compare(model,saved)
	for name,old in saved do
		local p=model[name]
		assert(p.CFrame==old.cf and p.Size==old.size and p.Color==old.color and p.Transparency==old.alpha,"Seed identity changed across detail transition")
	end
end
local function run()
	view:SetState(state());view:SetDetail("full");flush()
	assert(cropParts()==216,"Full field did not build three recipes")
	local first=view.plants[3].plant
	local ripe=view.plants[9].plant
	assert(not first.glint.Enabled and ripe.glint.Enabled,"Ripe cue did not follow feed")
	local selected=3
	local soil=view.pieces.sq3
	local pet=view.pieces.sq4
	local look=snapshot(ripe.model)
	local function corrected(ready)
		local copy=state()
		copy.field.plants["3"].readyAt=ready
		copy.field.plants["3"].startAt=ready-crop.growSeconds
		view:SetState(copy);flush()
		assert(view.plants[3].plant==first and view.pieces.sq3==soil and view.pieces.sq4==pet,"Correction replaced plant/soil/pet")
	end
	corrected(workspace:GetServerTimeNow()+0.15)
	task.wait(0.20);view:StepPlants(os.clock()+0.006)
	assert(first.glint.Enabled and view.plants[3].growth==1 and view.plants[3].nextAt==math.huge,"Exact ripe boundary missed")
	corrected(workspace:GetServerTimeNow()+19440)
	assert(not first.glint.Enabled and view.plants[3].growth<0.2,"Backward correction did not reset ripe cues")
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances={view.root}
	local frame=view:SquareCFrame(9)
	local hit=workspace:Raycast(frame.Position+Vector3.new(0,12,0),Vector3.new(0,-20,0),params)
	assert(hit and hit.Instance.Name=="Soil9","Crop art blocked soil selection")
	view:ShowSelect(selected)
	assert(view.root:FindFirstChild("Select"),"Selection outline missing")
	view:SetState(state());flush()
	view:SetDetail("mid");flush()
	assert(next(view.plants)==nil and not first.model.Parent,"Full plants/glints survived proxy transition")
	local proxies=0
	for _,n in {3,4,9} do
		local piece=assert(view.pieces["grow"..n],"Missing crop proxy")
		for _,p in piece:GetChildren() do if p:IsA("BasePart") then proxies+=1 end end
		assert(not piece:FindFirstChildWhichIsA("ParticleEmitter",true),"Mid proxy created particles")
	end
	assert(proxies==52,"Unexpected young/growing/ripe proxy topology")
	view:SetDetail("low");flush()
	assert(next(view.plants)==nil and not view.pieces.grow9,"Low detail retained crop art")
	view:SetDetail("full");flush()
	assert(cropParts()==216,"Full detail did not return")
	compare(view.plants[9].plant.model,look)
	local effect=Registry.PlayHarvest(crop.id,root,frame,high)
	assert(effect and effect.Name=="GoldenCarrotHarvest" and not effect.CanQuery and effect.Transparency==1,"Harvest effect anchor invalid")
	local emitter=effect:FindFirstChildWhichIsA("ParticleEmitter",true)
	assert(emitter and emitter.Rate==0 and not emitter.Enabled,"Harvest burst became continuous")
	assert(not Registry.PlayHarvest("Potato",root,frame,1),"Other crop gained gold effect")
	task.wait(1.1)
	assert(not effect.Parent,"Harvest effect leaked")
	return {fullParts=216,midParts=proxies,productionSeconds=crop.growSeconds,interval=Registry.UpdateInterval(crop.growSeconds),
		correctionsRetainInstances=true,exactRipeness=true,detailRoundTrip=true,soilRay=hit.Instance.Name,burstCleanup=true}
end
local ok,result=xpcall(run,debug.traceback)
view:Destroy()
root:Destroy()
assert(ok,result)
return game.HttpService:JSONEncode(result)
