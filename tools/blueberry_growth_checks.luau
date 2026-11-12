-- CG17b: Studio (Edit or Client). Disposable geometry; no remotes or profile writes. Returns a JSON summary.
-- In Edit, `require` caches across calls: run it once after a change, or in a playtest Client.
assert(game:GetService("RunService"):IsStudio(), "Studio only")
local Recipe = require(game.ReplicatedStorage.BlueberryPlant)
local Crops = require(game.ReplicatedStorage.CropConfig)
local low, high = Crops.SizeBounds()
local V = Vector3.new
local base = CFrame.new(0, 300, 0) * CFrame.Angles(0, 0.73, 0)
local parent = Instance.new("Folder")
local function measure(model)
	local r, top, berryLow, n = 0, 0, math.huge, 0
	for _, p in model:GetChildren() do
		if not p:IsA("BasePart") or p.Transparency >= 0.99 then continue end
		n += 1
		for x = -1, 1, 2 do for y = -1, 1, 2 do for z = -1, 1, 2 do
			local at = base:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size * V(x, y, z) / 2))
			assert(at.X == at.X and at.Y == at.Y and at.Z == at.Z, "Non-finite pose " .. p.Name)
			r = math.max(r, V(at.X, 0, at.Z).Magnitude)
			top = math.max(top, at.Y)
			if p:GetAttribute("PlantRole") == "Fruit" then berryLow = math.min(berryLow, at.Y) end
		end end end
	end
	return r, top, berryLow, n
end
local function snapshot(p)
	local pose = {}
	for i, part in p.rig.parts do pose[i] = { part.CFrame, part.Size, part.Color, part.Transparency } end
	return pose
end
local function same(p, pose)
	for i, part in p.rig.parts do
		local old = pose[i]
		assert(part.Transparency == old[4], "Visibility changed on seek: " .. part.Name)
		if part.Transparency < 1 then
			assert(part.CFrame == old[1] and part.Size == old[2] and part.Color == old[3], "Backward seek mismatch: " .. part.Name)
		end
	end
end
local out = { radius = 0, proxyRadius = 0, ripeTop = { math.huge, 0 }, allTop = 0, ripeClearance = math.huge, seeds = {}, proxies = {} }
for _, size in { low, 1, high } do
	for seed = 1, 6 do
		local plant = Recipe.new(parent, base, seed, size)
		assert(#plant.rig.parts == 134, "Part count")
		for _, part in plant.rig.parts do
			assert(part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch, "Physics flags")
		end
		local slots = 0
		for id, slot in plant.fruitSlots do
			assert(slot.id == id and #slot.parts == 9 and typeof(slot.attachment) == "CFrame", "Fruit slot " .. id)
			for _, part in slot.parts do assert(part:GetAttribute("FruitSlot") == id, "Slot attribute") end
			slots += 1
		end
		assert(slots == 10, "Ten fruit slots")
		for step = 0, 100 do
			plant:SetGrowth(step / 100)
			local r, top = measure(plant.model)
			out.radius = math.max(out.radius, r)
			out.allTop = math.max(out.allTop, top)
		end
		local r, top, berryLow = measure(plant.model)
		out.ripeTop = { math.min(out.ripeTop[1], top), math.max(out.ripeTop[2], top) }
		out.ripeClearance = math.min(out.ripeClearance, berryLow)
		if size == 1 then out.seeds[seed] = math.floor(top * 100) / 100 end
		plant:SetGrowth(0.43)
		local pose = snapshot(plant)
		plant:SetGrowth(0.44)
		plant:SetGrowth(0.43)
		same(plant, pose)
		plant:SetGrowth(0)
		local zero = snapshot(plant)
		plant:SetGrowth(1)
		plant:SetGrowth(0)
		same(plant, zero)
		plant:Destroy()
		for stage = 1, 3 do
			local folder = Instance.new("Folder")
			Recipe.BuildProxy(folder, base, stage, seed, size)
			for _, p in folder:GetChildren() do
				assert(p.Anchored and not p.CanCollide and not p.CanQuery and not p.CanTouch, "Proxy physics flags")
			end
			local pr = measure(folder)
			out.proxyRadius = math.max(out.proxyRadius, pr)
			if seed == 1 and size == 1 then out.proxies[stage] = #folder:GetChildren() end
			folder:Destroy()
		end
	end
end
assert(out.radius <= 2.4 and out.proxyRadius <= 2.4, "Footprint " .. out.radius .. " / proxy " .. out.proxyRadius)
out.radius = math.floor(out.radius * 1000) / 1000
out.proxyRadius = math.floor(out.proxyRadius * 1000) / 1000
out.allTop = math.floor(out.allTop * 100) / 100
out.ripeClearance = math.floor(out.ripeClearance * 100) / 100
out.ripeTop = { math.floor(out.ripeTop[1] * 100) / 100, math.floor(out.ripeTop[2] * 100) / 100 }
parent:Destroy()
return game:GetService("HttpService"):JSONEncode(out)
