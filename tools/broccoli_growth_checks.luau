-- CG14b: Studio-client geometry checks. Disposable models only; no remotes or profile writes.
assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient(), "Studio client only")
local Recipe = require(game.ReplicatedStorage.BroccoliPlant)
local Crops = require(game.ReplicatedStorage.CropConfig)
local Growth = require(game.ReplicatedStorage.PlantGrowth)
local low, high = Crops.SizeBounds()
local V = Vector3.new
local base = CFrame.new(0, 20, 0) * CFrame.Angles(0, 0.73, 0)
local parent = Instance.new("Folder")
local maxRadius, maxHeight, minRipe, maxRipe = 0, 0, math.huge, 0
local proxies, identities, baseline = {}, {}, {}
local function measure(model, filter)
	local lo, hi = V(math.huge, math.huge, math.huge), V(-math.huge, -math.huge, -math.huge)
	local radius, visible = 0, 0
	for _, p in model:GetDescendants() do
		if not p:IsA("BasePart") or p.Transparency >= 0.99 or (filter and not filter(p)) then continue end
		visible += 1
		for _, x in {-1, 1} do for _, y in {-1, 1} do for _, z in {-1, 1} do
			local at = base:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size / 2 * V(x, y, z)))
			assert(at.X == at.X and at.Y == at.Y and at.Z == at.Z, "Non-finite pose")
			lo, hi = lo:Min(at), hi:Max(at)
			radius = math.max(radius, V(at.X, 0, at.Z).Magnitude)
		end end end
	end
	return radius, lo, hi, visible
end
local function snapshot(p)
	local result = {}
	for i, part in p.rig.parts do result[i] = {part, part.CFrame, part.Size, part.Color, part.Transparency} end
	return result
end
local function same(p, pose)
	for i, part in p.rig.parts do
		local old = pose[i]
		assert(part == old[1] and part.Transparency == old[5], "Instances or visibility changed on seek")
		if part.Transparency < 1 then assert(part.CFrame == old[2] and part.Size == old[3] and part.Color == old[4], "Backward seek mismatch") end
	end
end
local function ends(part, overlap)
	local d = part.CFrame.LookVector * (part.Size.Z / 2 - (overlap or 0.0125))
	return part.Position + d, part.Position - d
end
local function joined(a, b, overlapA, overlapB)
	if a.Transparency >= 0.5 or b.Transparency >= 0.5 then return end
	local endpoint = select(2, ends(a, overlapA))
	local startpoint = ends(b, overlapB)
	assert((endpoint - startpoint).Magnitude < 0.0005, "Detached joint: " .. a.Name .. " -> " .. b.Name)
end
local function attached(p)
	local stemStart, stemEnd = ends(p.model.Stalk)
	for i = 1, 6 do
		joined(p.model["Petiole_" .. i], p.model["Blade_" .. i .. "_1"])
		for j = 1, 2 do joined(p.model["Blade_" .. i .. "_" .. j], p.model["Blade_" .. i .. "_" .. (j + 1)]) end
		local petiole = p.model["Petiole_" .. i]
		if petiole.Transparency < 0.5 then
			local node = stemStart:Lerp(stemEnd, 0.18 + (i - 1) * 0.10)
			assert((node - ends(petiole)).Magnitude < 0.0007, "Detached petiole")
		end
	end
	for i = 1, 7 do
		local branch, floret = p.model["Branch_" .. i], p.model["Floret_" .. i]
		if branch.Transparency >= 0.5 then continue end
		local startpoint, endpoint = ends(branch)
		assert((startpoint - stemEnd).Magnitude < p.model.Stalk.Size.X + 0.001, "Branch detached from stalk")
		assert((endpoint - floret.Position).Magnitude < floret.Size.Y / 2, "Floret detached from branch")
		for j = 1, 7 do
			local bud = p.model["Bud_" .. i .. "_" .. j]
			local point = floret.CFrame:PointToObjectSpace(bud.Position)
			assert(math.abs(point.X) < floret.Size.X / 2 and math.abs(point.Z) < floret.Size.Z / 2,
				"Bud floating beyond floret")
			assert(point.Y - bud.Size.Y / 2 <= floret.Size.Y / 2 + 0.001, "Bud floating above floret")
		end
	end
end
for _, mass in {low, 1, high} do for seed = 1, 6 do
	local p = Recipe.new(parent, base, seed, mass)
	assert(#p.rig.parts == 108 and not p.fruitSlots, "Topology changed")
	local initial = snapshot(p)
	for step = 0, 100 do
		p:SetGrowth(step / 100)
		local r, _, hi = measure(p.model)
		assert(r <= 2.4001, "Footprint exceeded at " .. seed .. "/" .. mass .. "/" .. step .. ": " .. r)
		maxRadius, maxHeight = math.max(maxRadius, r), math.max(maxHeight, hi.Y)
		attached(p)
		if step == 0 then
			assert(p.model.Cotyledon_1.Transparency == 0 and p.model.Cotyledon_2.Transparency == 0, "Seed leaves missing")
			assert(hi.Y < 0.3 and p.model.Blade_1_1.Transparency == 1, "Initial pose is not a small seedling")
		end
		if step <= 47 then
			local _, _, _, count = measure(p.model, function(part) return part:GetAttribute("PlantRole") == "Crown" end)
			assert(count == 0, "Crown emerged before foliage establishment")
		end
		if step % 20 == 0 then task.wait() end
	end
	local _, _, ripe = measure(p.model)
	minRipe, maxRipe = math.min(minRipe, ripe.Y), math.max(maxRipe, ripe.Y)
	local _, blo, bhi = measure(p.model, function(part) return part:GetAttribute("PlantRole") == "Crown" end)
	assert(p.model.Floret_1.Position.Y > p.model.Floret_2.Position.Y, "Crown has no central dome")
	assert(p.model.Cotyledon_1.Transparency == 1 and p.model.Cotyledon_2.Transparency == 1, "Seed leaves retained at maturity")
	if seed == 1 and mass == 1 then baseline = {height = ripe.Y, headWidth = math.max(bhi.X - blo.X, bhi.Z - blo.Z),
		headHeight = bhi.Y - blo.Y} end
	for _, g in {0, 0.20, 0.43, 0.75, 0.99} do
		p:SetGrowth(g); local pose = snapshot(p)
		p:SetGrowth(g + 0.01); p:SetGrowth(g); same(p, pose)
	end
	p:SetGrowth(1); p:SetGrowth(0); same(p, initial)
	for stage = 1, 3 do
		local proxy = Instance.new("Model")
		Recipe.BuildProxy(proxy, base, stage, seed, mass)
		local r = measure(proxy)
		assert(#proxy:GetChildren() > 0 and #proxy:GetChildren() <= 29 and r <= 2.4001, "Proxy contract failed")
		if seed == 1 and mass == 1 then proxies[stage] = #proxy:GetChildren() end
		proxy:Destroy()
	end
	for _, part in p.rig.parts do assert(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery, "Art intercepts input/physics") end
	if mass == 1 then p:SetGrowth(1); identities[seed] = tostring(p.model.Blade_4_2.CFrame) .. tostring(p.model.Floret_1.Size) .. tostring(p.model.Stalk.CFrame) end
	p:Destroy()
	task.wait()
end end
for i = 1, 6 do for j = i + 1, 6 do assert(identities[i] ~= identities[j], "Identical seeds") end end
parent:Destroy()
assert(Crops.ById.Broccoli.growSeconds == 7200 and Growth.UpdateInterval(7200) == 15, "Production timing changed")
return game.HttpService:JSONEncode({seeds = 6, masses = {low, 1, high}, ages = 101, parts = 108, fieldParts = 3888,
	maxRadius = maxRadius, tallestAnyAge = maxHeight, ripeHeight = {minRipe, maxRipe}, proxies = proxies, baseline = baseline})
