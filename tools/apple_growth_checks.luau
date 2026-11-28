-- TR2: Apple / Golden apple tree geometry checks, Studio Edit context (no scripts, remotes or profile writes).
-- Six seeds x three harvested masses x 101 ages of the reviewer's life (SetGrowth), then the field poses (SetTree): every
-- fruit count with its next apple growing, a pick back to zero and regrowth, and backward seeks. Reports Part count, max radius,
-- height, and asserts the 5.2-stud radius (TR4: a tree takes a 2 x 2 block, 5.5 studs to its edge) and that a seek returns the
-- same pose.
-- Note: require caches in Edit; after a disk change check the module's Source or restart Studio's Edit session.
assert(game:GetService("RunService"):IsStudio(), "Studio only")
local RS = game:GetService("ReplicatedStorage")
local CropConfig = require(RS.CropConfig)
local V = Vector3.new
local lo, hi = CropConfig.SizeBounds(true)
local holder = Instance.new("Folder")
holder.Name = "AppleGrowthChecks"
holder.Parent = workspace
local soil = CFrame.new(0, 800, 0)
local report = {}
local function measure(plant)
	local radius, top, shown = 0, 0, 0
	for _, p in plant.model:GetChildren() do
		if p.Transparency < 1 then
			shown += 1
			local l = soil:ToObjectSpace(p.CFrame)
			for x = -1, 1, 2 do for y = -1, 1, 2 do for z = -1, 1, 2 do
				local a = l:PointToWorldSpace(p.Size * V(x, y, z) / 2)
				radius = math.max(radius, V(a.X, 0, a.Z).Magnitude)
				top = math.max(top, a.Y)
			end end end
		end
	end
	return radius, top, shown
end
local function snapshot(plant)
	local t = {}
	for i, p in plant.model:GetChildren() do -- hidden Parts keep their last geometry: only the shown ones count
		t[i] = if p.Transparency >= 1 then "-" else string.format("%.4f %.4f %.4f %.3f %.3f %.3f %.2f", p.Position.X, p.Position.Y, p.Position.Z, p.Size.X, p.Size.Y, p.Size.Z, p.Transparency)
	end
	return table.concat(t, ";")
end
for _, id in { "Apple", "GoldenApple" } do
	local recipe = require(RS[id .. "Plant"])
	local cap = CropConfig.ById[id].tree.Cap
	local worst, tallest, lowest, parts = 0, 0, math.huge, 0
	for seed = 1, 6 do
		for _, mass in { lo, 1, hi } do
			local plant = recipe.new(holder, soil, seed, mass)
			parts = #plant.model:GetChildren()
			for age = 0, 100 do
				plant:SetGrowth(age / 100)
				local r, top = measure(plant)
				worst = math.max(worst, r)
				if age == 100 then tallest = math.max(tallest, top); lowest = math.min(lowest, top) end
			end
			-- field poses: each count with the next apple half grown, a pick to zero, regrowth
			for count = 0, cap do
				plant:SetTree(1, count, 0.5)
				worst = math.max(worst, (measure(plant)))
			end
			plant:SetGrowth(0.43); local a = snapshot(plant)
			plant:SetGrowth(0.44); plant:SetGrowth(0.43)
			assert(snapshot(plant) == a, id .. " backward seek changed the pose (seed " .. seed .. ")")
			plant:SetTree(1, cap, 0); local full = snapshot(plant)
			plant:SetTree(1, 0, 0); plant:SetTree(1, 0, 0.6); plant:SetTree(1, cap, 0)
			assert(snapshot(plant) == full, id .. " pick and regrowth changed the tree (seed " .. seed .. ")")
			plant:Destroy()
		end
	end
	assert(worst <= 5.2, id .. " exceeds its block: " .. worst)
	report[id] = string.format("parts %d, full field (19 trees) = %d, max radius %.2f, ripe height %.2f-%.2f", parts, parts * 19, worst, lowest, tallest)
end
holder:Destroy()
return game.HttpService:JSONEncode(report)
