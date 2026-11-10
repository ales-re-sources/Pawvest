-- CG13 Studio-client checks for CucumberPlant. Disposable models, no remotes or profile writes.
-- Run in a playtest Client context (require the recipe from ReplicatedStorage).
assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient(), "Studio client only")
local Recipe = require(game.ReplicatedStorage.CucumberPlant)
local CropConfig = require(game.ReplicatedStorage.CropConfig)
local low, high = CropConfig.SizeBounds()
local V = Vector3.new
local base = CFrame.new(0, 20, 0)
local parent = Instance.new("Folder")
local maxRadius, maxTall, minRipe, maxRipe, minFruitBottom = 0, 0, math.huge, 0, math.huge
local proxies, identities, baseline = {}, {}, {}

local function measure(model, filter)
	local lo, hi = V(math.huge, math.huge, math.huge), V(-math.huge, -math.huge, -math.huge)
	local radius, visible = 0, 0
	for _, p in model:GetDescendants() do
		if not p:IsA("BasePart") or p.Transparency >= 0.99 or (filter and not p.Name:match(filter)) then continue end
		visible += 1
		for _, x in {-1, 1} do for _, y in {-1, 1} do for _, z in {-1, 1} do
			local at = base:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size / 2 * V(x, y, z)))
			lo, hi = lo:Min(at), hi:Max(at)
			radius = math.max(radius, V(at.X, 0, at.Z).Magnitude)
		end end end
	end
	return radius, lo, hi, visible
end
local function snapshot(plant)
	local out = {}
	for i, p in plant.rig.parts do out[i] = {p, p.CFrame, p.Size, p.Color, p.Transparency} end
	return out
end
local function same(plant, pose)
	for i, p in plant.rig.parts do
		local old = pose[i]
		assert(p == old[1] and p.Transparency == old[5], "Instance or visibility changed on seek: " .. p.Name)
		if p.Transparency < 1 then
			assert(p.CFrame == old[2] and p.Size == old[3] and p.Color == old[4], "Visible backward seek mismatch: " .. p.Name)
		end
	end
end
-- A rod's two ends: lookAt points at the rod's start, so +LookVector is the start and - is the end.
local function ends(part)
	local d = part.CFrame.LookVector * (part.Size.Z / 2 - 0.01)
	return part.Position + d, part.Position - d
end
local function attached(plant)
	local m = plant.model
	for i = 1, 3 do
		local a, b = m["Stem_" .. i], m["Stem_" .. (i + 1)]
		if a.Transparency < 0.5 and b.Transparency < 0.5 then
			local _, aEnd = ends(a)
			local bStart = ends(b)
			assert((aEnd - bStart).Magnitude < 0.05, "Detached stem joint " .. i)
		end
	end
	for i = 1, 5 do
		local stalk = m["Leaf_" .. i .. "_Stalk"]
		if stalk.Transparency < 0.5 then
			-- The petiole's free end must be where the blade hinge sits: the centre lobe starts there.
			local _, tip = ends(stalk)
			local lobe = m["Leaf_" .. i .. "_Lobe_1"]
			if lobe.Transparency < 0.5 then
				assert((lobe.CFrame:PointToObjectSpace(tip)).Magnitude < lobe.Size.Z + 0.2, "Detached leaf " .. i)
			end
		end
	end
	for i = 1, 3 do
		local stalk, shoulder = m["Fruit_" .. i .. "_Stalk"], m["Fruit_" .. i .. "_Shoulder"]
		if stalk.Transparency < 0.5 and shoulder.Transparency < 0.5 then
			local _, stalkEnd = ends(stalk)
			local shoulderStart = ends(shoulder)
			assert((stalkEnd - shoulderStart).Magnitude < 0.05, "Detached fruit stalk " .. i)
		end
	end
end

for _, mass in {low, 1, high} do for seed = 1, 6 do
	local p = Recipe.new(parent, base, seed, mass)
	assert(#p.rig.parts == 79 and #p.fruitSlots == 3, "Topology contract changed")
	for slot = 1, 3 do assert(#p.fruitSlots[slot].parts == 8, "Fruit slot Part group changed") end
	local initial = snapshot(p)
	for step = 0, 100 do
		p:SetGrowth(step / 100)
		local radius, _, hi, visible = measure(p.model)
		assert(visible >= 5, "Empty growth pose")
		assert(radius <= 2.4001, "Footprint exceeded at seed " .. seed .. ", mass " .. mass .. ", growth " .. step .. ": " .. radius)
		maxRadius = math.max(maxRadius, radius)
		maxTall = math.max(maxTall, hi.Y)
		attached(p)
		if step % 20 == 0 then task.wait() end
	end
	local _, _, ripe = measure(p.model, "^Leaf")
	minRipe, maxRipe = math.min(minRipe, ripe.Y), math.max(maxRipe, ripe.Y)
	local _, flo = measure(p.model, "^Fruit_%d_[SBL]")
	assert(flo.Y > -0.01, "Fruit below soil: " .. flo.Y)
	minFruitBottom = math.min(minFruitBottom, flo.Y)
	for i = 1, 3 do assert(p.model["Fruit_" .. i .. "_Body"].Transparency < 0.01, "Ripe fruit missing " .. i) end
	if seed == 1 and mass == 1 then
		local _, _, hi, _ = measure(p.model)
		baseline = {ripeTop = hi.Y, leafTop = ripe.Y, fruitBottom = flo.Y}
	end
	for _, g in {0, 0.20, 0.43, 0.75, 0.99} do
		p:SetGrowth(g); local pose = snapshot(p)
		p:SetGrowth(g + 0.01); p:SetGrowth(g); same(p, pose)
	end
	p:SetGrowth(1); p:SetGrowth(0); same(p, initial)
	for stage = 1, 3 do
		local proxy = Instance.new("Model")
		Recipe.BuildProxy(proxy, base, stage, seed, mass)
		local r, _, _, visible = measure(proxy)
		assert(visible >= 4 and r <= 2.4001, "Empty or oversized proxy")
		if mass == 1 and seed == 1 then proxies[stage] = #proxy:GetChildren() end
		proxy:Destroy()
	end
	for _, part in p.rig.parts do
		assert(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery, "Art intercepts input/physics")
	end
	if mass == 1 then
		p:SetGrowth(1)
		identities[seed] = tostring(p.model.Leaf_2_Lobe_1.CFrame) .. tostring(p.model.Fruit_1_Body.CFrame) .. tostring(p.model.Stem_4.CFrame)
	end
	p:Destroy()
	task.wait()
end end
for i = 1, 6 do for j = i + 1, 6 do assert(identities[i] ~= identities[j], "Seed forms identical") end end
parent:Destroy()
return game.HttpService:JSONEncode({seeds = 6, masses = {low, 1, high}, ages = 101, parts = 79, fieldParts = 79 * 36, maxRadius = maxRadius,
	tallestAnyAge = maxTall, leafTop = {minRipe, maxRipe}, lowestFruit = minFruitBottom, proxies = proxies, baseline = baseline,
	productionSeconds = CropConfig.ById.Cucumber.growSeconds})
