-- CG1d client-only CPU probe. Run in a Studio playtest Client command context.
-- Uses the production scheduler budget and distance tiers, in a disposable plot folder.
-- Frame timings belong to this desktop/session/camera, not to a phone.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsClient())
local player = game.Players.LocalPlayer
local PlotView = require(player.PlayerScripts.PlotView)
local Growth = require(game.ReplicatedStorage.TomatoPlant)
local GardenConfig = require(game.ReplicatedStorage.GardenConfig)
local root = Instance.new("Folder")
root.Name = "TomatoPerfProbe"
root.Parent = workspace
local poseCalls, poseSeconds = 0, 0
local original = Growth.SetGrowth
Growth.SetGrowth = function(self, g)
	if not self.model:IsDescendantOf(root) then return original(self, g) end
	local start = os.clock()
	original(self, g)
	poseSeconds += os.clock()-start
	poseCalls += 1
end
local function percentile(values, p)
	table.sort(values)
	return values[math.max(1,math.ceil(#values*p))]
end
local function measure(count, tomatoes)
	local views, tiers = {}, {full=0, mid=0, low=0, none=0}
	local focus = GardenConfig.PlotCFrame(1).Position
	local now = workspace:GetServerTimeNow()
	for slot = 1, count do
		local view = PlotView.new(slot, root, {own=slot==1})
		local anchors = {}
		for n=1,36 do anchors[tostring(n)]={n=n,startAt=now-210,readyAt=now+270} end
		local pets={}
		for n=2,36,4 do table.insert(pets,string.format("Cat:10:perf%d:%d:4:4",n,n)) end
		view:SetState({ownerId=slot,name="CG1d",incCount=3,eggs={},
			field={crops=string.rep(if tomatoes then "k1" else "b1",36),pets=pets,plants=if tomatoes then anchors else nil}})
		local delta=view.floor.Position-focus
		local distance=Vector3.new(delta.X,0,delta.Z).Magnitude
		local detail=if distance<=60 then "full" elseif distance<=120 then "mid" elseif distance<=300 then "low" else "none"
		tiers[detail]+=1
		view:SetDetail(detail)
		while view:Step(os.clock()+.006) do RunService.Heartbeat:Wait() end
		table.insert(views,view)
	end
	poseCalls,poseSeconds=0,0
	local frameMs,workMs={},{}
	local start=os.clock()
	repeat
		local dt=RunService.Heartbeat:Wait()
		local frameStart=os.clock()
		local deadline=frameStart+.006
		for _,view in views do
			if view:Pending()>0 or view:HasGrowingPlants() then view:Step(deadline) end
			if os.clock()>=deadline then break end
		end
		table.insert(workMs,(os.clock()-frameStart)*1000)
		table.insert(frameMs,dt*1000)
	until os.clock()-start>=4
	local elapsed=os.clock()-start
	local instances=#root:GetDescendants()
	local result={plots=count,tomatoes=tomatoes,tiers=tiers,instances=instances,
		poseCalls=poseCalls,poseMsPerSecond=poseSeconds*1000/elapsed,
		workP95=percentile(workMs,.95),workMax=workMs[#workMs],
		frameP95=percentile(frameMs,.95)}
	for _,view in views do view:Destroy() end
	return result
end
local ok,results=xpcall(function()
	local out={}
	for _,count in {1,24} do
		table.insert(out,measure(count,false))
		table.insert(out,measure(count,true))
	end
	return out
end,debug.traceback)
Growth.SetGrowth=original
root:Destroy()
assert(ok,results)
return game.HttpService:JSONEncode(results)
