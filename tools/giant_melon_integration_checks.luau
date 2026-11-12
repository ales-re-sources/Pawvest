-- CG19c Studio client acceptance: production PlotView, disposable public-feed fixtures, no remotes/profile writes.
-- Run in a playtest, Client context (execute_luau).
assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient(), "Studio client only")
local PlotView = require(game.Players.LocalPlayer.PlayerScripts.PlotView)
local Registry = require(game.ReplicatedStorage.PlantGrowth)
local Config = require(game.ReplicatedStorage.CropConfig)
local GardenConfig = require(game.ReplicatedStorage.GardenConfig)
local crop = Config.ById.GiantMelon
assert(Registry.Supports(crop.id) and crop.growSeconds == 43200, "Registry/timing changed")
assert(Registry.RingHeight(crop.id, 1) == 4.9 and Registry.RingHeight(crop.id, 3) == 4.9, "Melon ring must be fixed")
local low, high = Config.SizeBounds()
local garden = assert(workspace:FindFirstChild("GardenView"), "Wait for GardenView")
local slot = 13
while GardenConfig.PlotCFrame(slot) and garden:FindFirstChild(string.format("Slot_%02d", slot)) do slot += 1 end
assert(GardenConfig.PlotCFrame(slot), "No free study slot")
local root = Instance.new("Folder")
root.Name = "GiantMelonIntegration"
root.Parent = workspace
local view = PlotView.new(slot, root)
local G = crop.growSeconds
local function state()
	local cells = table.create(36, "#0")
	for n = 1, 12 do cells[n] = ".0" end
	cells[3], cells[4], cells[9] = crop.letter .. "1", crop.letter .. "2", crop.letter .. "3"
	local now = workspace:GetServerTimeNow()
	return {ownerId = 9892673032, name = "CG19c", incCount = 1, eggs = {}, field = {crops = table.concat(cells), pets = {"Cat:3:pumpkin:4:1:1"}, plants = {
		["3"] = {n = 41, size = low, startAt = now - G / 100, readyAt = now + G * 0.99},
		["4"] = {n = 42, size = 1, startAt = now - G * 0.6, readyAt = now + G * 0.4},
		["9"] = {n = 43, size = high, startAt = 0, readyAt = 0},
	}}}
end
local function flush()
	while view:Step(os.clock() + 0.006) do task.wait() end
end
local function cropParts()
	local count = 0
	for _, entry in view.plants do count += #entry.plant.rig.parts end
	return count
end
local function snapshot(model)
	local out = {}
	for i, p in model:GetChildren() do if p:IsA("BasePart") then out[i] = {cf = p.CFrame, size = p.Size, color = p.Color, alpha = p.Transparency} end end
	return out
end
local function compare(model, saved)
	for i, old in saved do
		local p = model:GetChildren()[i]
		assert(p.CFrame == old.cf and p.Size == old.size and p.Color == old.color and p.Transparency == old.alpha, "Seed identity changed across detail transition")
	end
end
local function ripeNow(plant) return plant.rig.growth >= 0.99 end
local function run()
	view:SetState(state()); view:SetDetail("full"); flush()
	assert(cropParts() == 291, "Full field did not build three recipes: " .. cropParts())
	local first = view.plants[3].plant
	local ripe = view.plants[9].plant
	assert(not ripeNow(first) and ripeNow(ripe), "Ripe cue did not follow feed")
	local soil = view.pieces.sq3
	local pet = view.pieces.sq4
	local look = snapshot(ripe.model)
	local function corrected(ready)
		local copy = state()
		copy.field.plants["3"].readyAt = ready
		copy.field.plants["3"].startAt = ready - G
		view:SetState(copy); flush()
		assert(view.plants[3].plant == first and view.pieces.sq3 == soil and view.pieces.sq4 == pet, "Correction replaced plant/soil/pet")
	end
	corrected(workspace:GetServerTimeNow() + 0.15)
	task.wait(0.30); view:StepPlants(os.clock() + 0.006)
	assert(ripeNow(first) and view.plants[3].growth == 1 and view.plants[3].nextAt == math.huge, "Exact ripe boundary missed")
	corrected(workspace:GetServerTimeNow() + G * 0.99)
	assert(not ripeNow(first) and view.plants[3].growth < 0.2, "Backward correction did not reset the ripe cue")
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {view.root}
	local frame = view:SquareCFrame(9)
	local hit = workspace:Raycast(frame.Position + Vector3.new(0, 12, 0), Vector3.new(0, -20, 0), params)
	assert(hit and hit.Instance.Name == "Soil9", "Crop art blocked soil selection: " .. tostring(hit and hit.Instance.Name))
	view:ShowSelect(3)
	assert(view.root:FindFirstChild("Select"), "Selection outline missing")
	view:SetState(state()); flush()
	view:SetDetail("mid"); flush()
	assert(next(view.plants) == nil and not first.model.Parent, "Full plants survived proxy transition")
	local proxies = {}
	for _, n in {3, 4, 9} do
		local piece = assert(view.pieces["grow" .. n], "Missing crop proxy")
		local count = 0
		for _, p in piece:GetChildren() do if p:IsA("BasePart") then count += 1 end end
		proxies[n] = count
		assert(count >= 5 and count <= 60, "Wrong proxy count: " .. count)
	end
	view:SetDetail("low"); flush()
	assert(next(view.plants) == nil and not view.pieces.grow9, "Low detail retained crop art")
	view:SetDetail("full"); flush()
	assert(cropParts() == 291, "Full detail did not return")
	compare(view.plants[9].plant.model, look)
	assert(not Registry.PlayHarvest(crop.id, root, frame, high), "Giant melon has no harvest effect")
	-- Successful harvest is represented by a cleared public cell; a subsequent planting gets a new identity.
	local oldPlant = view.plants[9].plant
	local neighbour = view.plants[4].plant
	local harvested = state()
	harvested.field.crops = harvested.field.crops:sub(1, 16) .. ".0" .. harvested.field.crops:sub(19)
	harvested.field.plants["9"] = nil
	view:SetState(harvested); flush()
	assert(not view.plants[9] and not view.pieces.grow9 and not oldPlant.model.Parent, "Harvest feed retained crop art")
	assert(view.plants[4].plant == neighbour, "Harvest replaced neighbouring plant")
	local replanted = state()
	local now = workspace:GetServerTimeNow()
	replanted.field.crops = replanted.field.crops:sub(1, 16) .. crop.letter .. "1" .. replanted.field.crops:sub(19)
	replanted.field.plants["9"] = {n = 44, size = high, startAt = now, readyAt = now + G}
	view:SetState(replanted); flush()
	local newPlant = assert(view.plants[9], "Replant feed did not build crop")
	assert(newPlant.plant ~= oldPlant and newPlant.growth < 0.01 and not ripeNow(newPlant.plant), "Replant did not start young")
	assert(Registry.UpdateInterval(G) == 30, "Giant melon cadence changed")
	return {fullParts = 291, proxyParts = proxies, productionSeconds = G, interval = Registry.UpdateInterval(G),
		correctionsRetainInstances = true, exactRipeness = true, detailRoundTrip = true, harvestReplant = true, soilRay = hit.Instance.Name}
end
local ok, result = xpcall(run, debug.traceback)
view:Destroy()
root:Destroy()
assert(ok, result)
return game.HttpService:JSONEncode(result)
