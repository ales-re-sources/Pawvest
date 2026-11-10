-- CG11b Studio-client checks for OnionPlant. Disposable models, no remotes or profile writes.
-- Run in a playtest Client context (require the recipe from ReplicatedStorage).
assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient(), "Studio client only")
local Recipe = require(game.ReplicatedStorage.OnionPlant)
local CropConfig = require(game.ReplicatedStorage.CropConfig)
local low, high = CropConfig.SizeBounds()
local V = Vector3.new
local base = CFrame.new(0, 20, 0) * CFrame.Angles(0, 0.73, 0)
local parent = Instance.new("Folder")
local maxRadius, minTall, maxTall, minRipe, maxRipe = 0, math.huge, 0, math.huge, 0
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
		assert(p == old[1] and p.Transparency == old[5], "Instance or visibility changed on seek")
		if p.Transparency < 1 then
			assert(p.CFrame == old[2] and p.Size == old[3] and p.Color == old[4], "Visible backward seek mismatch")
		end
	end
end
-- A rod's two ends: the far end of its Z axis is the joint with the next rod.
local function ends(part)
	local d = part.CFrame.LookVector * (part.Size.Z / 2 - 0.015)
	return part.Position + d, part.Position - d -- lookAt points at the rod's start, so + is the start
end
local function attached(plant)
	for i = 1, 8 do
		for j = 1, 2 do
			local a, b = plant.model["Quill_" .. i .. "_" .. j], plant.model["Quill_" .. i .. "_" .. (j + 1)]
			if a.Transparency < 0.5 and b.Transparency < 0.5 then
				local _, aEnd = ends(a)
				local bStart = ends(b)
				assert((aEnd - bStart).Magnitude < 0.0001, "Detached quill joint " .. i .. "/" .. j)
			end
		end
	end
end

for _, mass in {low, 1, high} do for seed = 1, 6 do
	local p = Recipe.new(parent, base, seed, mass)
	assert(#p.rig.parts == 59 and not p.fruitSlots, "Topology contract changed")
	local initial = snapshot(p)
	for step = 0, 100 do
		p:SetGrowth(step / 100)
		local radius, _, hi, visible = measure(p.model)
		assert(visible >= 2, "Empty growth pose")
		assert(radius <= 2.4001, "Footprint exceeded at seed " .. seed .. ", mass " .. mass .. ", growth " .. step .. ": " .. radius)
		maxRadius = math.max(maxRadius, radius)
		maxTall = math.max(maxTall, hi.Y)
		attached(p)
		if step % 20 == 0 then task.wait() end
	end
	local _, lo, ripe = measure(p.model)
	minRipe, maxRipe = math.min(minRipe, ripe.Y), math.max(maxRipe, ripe.Y)
	local _, blo, bhi = measure(p.model, "^Bulb")
	local exposed = bhi.Y / (bhi.Y - blo.Y)
	assert(exposed > 0.45 and exposed < 0.65, "Bulb exposure out of range: " .. exposed)
	local scape = p.model.Scape_1
	local scapeEnd = select(2, ends(scape))
	local scapeStart = ends(p.model.Scape_2)
	assert((scapeEnd - scapeStart).Magnitude < 0.0001, "Detached scape joint")
	if seed == 1 and mass == 1 then
		baseline = {ripeHeight = ripe.Y, bulbHeight = bhi.Y - blo.Y, bulbWidth = math.max(bhi.X - blo.X, bhi.Z - blo.Z), exposed = exposed}
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
		assert(visible >= 2 and r <= 2.4001, "Empty or oversized proxy")
		if mass == 1 and seed == 1 then proxies[stage] = #proxy:GetChildren() end
		proxy:Destroy()
	end
	for _, part in p.rig.parts do
		assert(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery, "Art intercepts input/physics")
	end
	if mass == 1 then p:SetGrowth(1); identities[seed] = tostring(p.model.Quill_4_2.CFrame) .. tostring(p.model.Bulb_3_0.Size) .. tostring(p.model.Floret_1.CFrame) end
	p:Destroy()
	task.wait()
end end
for i = 1, 6 do for j = i + 1, 6 do assert(identities[i] ~= identities[j], "Seed forms identical") end end
parent:Destroy()
return game.HttpService:JSONEncode({seeds = 6, masses = {low, 1, high}, ages = 101, parts = 59, fieldParts = 2124, maxRadius = maxRadius,
	tallestAnyAge = maxTall, ripeHeight = {minRipe, maxRipe}, proxies = proxies, baseline = baseline,
	productionSeconds = CropConfig.ById.Onion.growSeconds})
