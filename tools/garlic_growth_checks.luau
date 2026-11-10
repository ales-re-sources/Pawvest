-- CG12b: Studio-client geometry checks. Disposable models only; no remotes or profile writes.
assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient(), "Studio client only")
local Recipe = require(game.ReplicatedStorage.GarlicPlant)
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
	for i = 1, 7 do for j = 1, 2 do joined(p.model["Blade_" .. i .. "_" .. j], p.model["Blade_" .. i .. "_" .. (j + 1)]) end end
	for i = 1, 9 do joined(p.model["Scape_" .. i], p.model["Scape_" .. (i + 1)]) end
	local last
	for i = 1, 10 do if p.model["Scape_" .. i].Transparency < 0.5 then last = p.model["Scape_" .. i] end end
	if last then joined(last, p.model.ClosedSpathe, 0.0125, 0.01) end
	joined(p.model.ClosedSpathe, p.model.SpathePoint, 0.01, 0.01)
	local stemStart, stemEnd = ends(p.model.Pseudostem)
	for i = 1, 7 do
		local blade = p.model["Blade_" .. i .. "_1"]
		if blade.Transparency < 0.5 then
			local node = stemStart:Lerp(stemEnd, (0.78 + i * 0.18 - 0.655) / 1.57)
			assert((node - ends(blade)).Magnitude < 0.0005, "Detached blade base")
		end
	end
end
for _, mass in {low, 1, high} do for seed = 1, 6 do
	local p = Recipe.new(parent, base, seed, mass)
	assert(#p.rig.parts == 54 and not p.fruitSlots, "Topology changed")
	local initial = snapshot(p)
	for step = 0, 100 do
		p:SetGrowth(step / 100)
		local r, _, hi = measure(p.model)
		assert(r <= 2.4001, "Footprint exceeded at " .. seed .. "/" .. mass .. "/" .. step .. ": " .. r)
		maxRadius, maxHeight = math.max(maxRadius, r), math.max(maxHeight, hi.Y)
		attached(p)
		if step == 0 then
			assert(p.model.Blade_1_1.Transparency == 0 and p.model.Blade_2_1.Transparency == 1, "Initial sprout missing or doubled")
			assert(hi.Y < 0.5 and p.model.Scape_1.Transparency == 1, "Initial pose is not a small sprout")
		end
		if step <= 20 then
			local _, _, head = measure(p.model, function(part) return part:GetAttribute("PlantRole") == "Bulb" end)
			assert(head.Y < 0.015, "Head exposed before foliage establishment")
		end
		if step % 20 == 0 then task.wait() end
	end
	local _, _, ripe = measure(p.model)
	minRipe, maxRipe = math.min(minRipe, ripe.Y), math.max(maxRipe, ripe.Y)
	local _, blo, bhi = measure(p.model, function(part) return part.Name:match("^Lobe") or part.Name == "WrappedCore" end)
	local exposure = bhi.Y / (bhi.Y - blo.Y)
	assert(exposure > 0.45 and exposure < 0.56, "Ripe head not half buried: " .. exposure)
	assert(p.model.Scape_10.Transparency == 0 and p.model.SpathePoint.Transparency == 0, "Mature scape incomplete")
	if seed == 1 and mass == 1 then baseline = {height = ripe.Y, headWidth = math.max(bhi.X - blo.X, bhi.Z - blo.Z),
		headHeight = bhi.Y - blo.Y, exposed = exposure} end
	for _, g in {0, 0.20, 0.43, 0.75, 0.99} do
		p:SetGrowth(g); local pose = snapshot(p)
		p:SetGrowth(g + 0.01); p:SetGrowth(g); same(p, pose)
	end
	p:SetGrowth(1); p:SetGrowth(0); same(p, initial)
	for stage = 1, 3 do
		local proxy = Instance.new("Model")
		Recipe.BuildProxy(proxy, base, stage, seed, mass)
		local r = measure(proxy)
		assert(#proxy:GetChildren() > 0 and #proxy:GetChildren() <= 26 and r <= 2.4001, "Proxy contract failed")
		if seed == 1 and mass == 1 then proxies[stage] = #proxy:GetChildren() end
		proxy:Destroy()
	end
	for _, part in p.rig.parts do assert(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery, "Art intercepts input/physics") end
	if mass == 1 then p:SetGrowth(1); identities[seed] = tostring(p.model.Blade_4_2.CFrame) .. tostring(p.model.LobeBody_1.Size) .. tostring(p.model.Scape_5.CFrame) end
	p:Destroy()
	task.wait()
end end
for i = 1, 6 do for j = i + 1, 6 do assert(identities[i] ~= identities[j], "Identical seeds") end end
parent:Destroy()
assert(Crops.ById.Garlic.growSeconds == 180 and Growth.UpdateInterval(180) == 0.375, "Production timing changed")
return game.HttpService:JSONEncode({seeds = 6, masses = {low, 1, high}, ages = 101, parts = 54, fieldParts = 1944,
	maxRadius = maxRadius, tallestAnyAge = maxHeight, ripeHeight = {minRipe, maxRipe}, proxies = proxies, baseline = baseline})
