-- CG8 display-only PlotView lifecycle checks. Synthetic feed, no remotes/profile writes.
local player=game.Players.LocalPlayer
local View=require(player.PlayerScripts.PlotView)
local Crop=require(game.ReplicatedStorage.CropConfig)
local low,high=Crop.SizeBounds()
local root=Instance.new("Folder")
local view=View.new(14,root)
local cells=table.create(Crop.MaxSquares,"#0")
for i=1,24 do cells[i]=".0" end
cells[7],cells[8],cells[9]="m1","m2","m3"
local now=workspace:GetServerTimeNow()
local plants={
	["7"]={n=1,startAt=now-720,readyAt=now+2880,size=low},
	["8"]={n=2,startAt=now-2520,readyAt=now+1080,size=1},
	["9"]={n=3,startAt=0,readyAt=0,size=high},
}
local function state()
	return {ownerId=player.UserId,name=player.DisplayName,incCount=1,eggs={},
		field={crops=table.concat(cells),plants=plants,pets={"Cat:3:review:7:1:1"}}}
end
local function drain()
	while view:Step(os.clock()+0.006) do task.wait() end
	view:StepPlants(os.clock()+1)
end
local function count()
	local n=0
	for i=7,9 do
		local piece=view.pieces["grow"..i]
		if piece then for _,p in piece:GetDescendants() do if p:IsA("BasePart") then n+=1 end end end
	end
	return n
end
local ok,result=xpcall(function()
	view:SetState(state()); view:SetDetail("full"); drain()
	local full=count()
	assert(full==252,"Field did not build three Pepper rigs")
	local before,soil,pet=view.plants[7].plant,view.pieces.sq7,view.pieces.sq7:FindFirstChild("Pet7")
	assert(pet,"Missing field pet")
	plants["7"].startAt=now-1548; plants["7"].readyAt=now+2052
	view:SetState(state()); drain()
	assert(view.plants[7].plant==before and view.pieces.sq7==soil and soil:FindFirstChild("Pet7")==pet,"Time update replaced plant/soil/pet")
	assert(math.abs(view.plants[7].growth-0.43)<0.01,"Correction failed")
	view:SetDetail("mid"); drain(); local mid=count()
	assert(mid>0 and mid<full and next(view.plants)==nil,"Mid detail built full rigs")
	view:SetDetail("low"); drain(); assert(count()==0,"Low detail retained art")
	view:SetDetail("full"); drain(); assert(count()==full,"Full detail failed to restore")
	cells[7]=".0"; plants["7"]=nil; view:SetState(state()); drain()
	assert(view.plants[7]==nil and view.pieces.grow7==nil,"Clearing feed retained crop")
	return {fullParts=full,midParts=mid,retainedOnTimeUpdate=true,detailRoundTrip=true,cleared=true}
end,debug.traceback)
view:Destroy(); root:Destroy()
assert(ok,result)
return game.HttpService:JSONEncode(result)
