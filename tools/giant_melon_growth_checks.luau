-- CG19b: Giant melon geometry checks, Studio Edit context (execute_luau). Display only: no remotes, no saved data.
-- Six seeds x three harvested masses x 101 ages: Part count, ground radius, top, nothing but the fruit inside the melon
-- (flowers, leaves, vine, tendrils stay clear of it), exact visible backward seek (43 -> 44 -> 43%).
-- Edit mode caches require: run a fresh clone so the check sees the module on disk.
local clone = game.ReplicatedStorage.GiantMelonPlant:Clone()
clone.Name = "GiantMelonPlantCheck"
clone.Parent = game.ReplicatedStorage
local Plant = require(clone)
clone:Destroy()
local V = Vector3.new
local function smooth(g, a, b) local t = math.clamp((g - a) / (b - a), 0, 1) return t * t * (3 - 2 * t) end
local folder = Instance.new("Folder")
folder.Name = "MelonChecks"
folder.Parent = workspace
local soil = CFrame.new(0, 500, 0)
local report = {parts = 0, maxRadius = 0, maxTop = 0, overlaps = {}, seekBad = 0, runs = 0}
local function corners(p)
	local h = p.Size / 2
	local list = {p.Position}
	for _, x in {-1, 1} do for _, y in {-1, 1} do for _, z in {-1, 1} do
		table.insert(list, p.CFrame:PointToWorldSpace(V(h.X * x, h.Y * y, h.Z * z)))
	end end end
	return list
end
local function signature(model)
	local out = {}
	for i, p in model:GetChildren() do
		if p.Transparency < 0.99 then
			local c, s = p.Position, p.Size
			out[#out + 1] = string.format("%d:%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.2f", i, c.X, c.Y, c.Z, s.X, s.Y, s.Z, p.Transparency)
		end
	end
	return table.concat(out, "|")
end
for seed = 1, 6 do
	for _, mass in {0.357, 1, 3.03} do
		local plant = Plant.new(folder, soil, seed, mass)
		report.parts = #plant.model:GetChildren()
		report.runs += 1
		for step = 0, 100 do
			local g = step / 100
			plant:SetGrowth(g)
			local sc = 0.10 + 0.90 * smooth(g, 0.60, 0.98)
			local L, R = plant.L * sc, plant.R * sc
			local fr = soil * CFrame.new(plant.pos + V(0, 0.94 * R, 0)) * CFrame.Angles(0, plant.yaw, 0)
			local fruitUp = smooth(g, 0.60, 0.64) > 0.05
			for _, p in plant.model:GetChildren() do
				if p.Transparency < 0.99 then
					for _, w in corners(p) do
						local rel = w - soil.Position
						report.maxRadius = math.max(report.maxRadius, math.sqrt(rel.X ^ 2 + rel.Z ^ 2))
						report.maxTop = math.max(report.maxTop, rel.Y)
					end
					if fruitUp and p:GetAttribute("PlantRole") ~= "Fruit" and step >= 50 then
						for _, w in corners(p) do
							local l = fr:PointToObjectSpace(w)
							if (l.X / (0.46 * L)) ^ 2 + (l.Y / R) ^ 2 + (l.Z / R) ^ 2 < 0.85 then
								report.overlaps[p.Name] = (report.overlaps[p.Name] or 0) + 1
								break
							end
						end
					end
				end
			end
		end
		plant:SetGrowth(0.43)
		local a = signature(plant.model)
		plant:SetGrowth(0.44)
		plant:SetGrowth(0.43)
		if signature(plant.model) ~= a then report.seekBad += 1 end
		plant:Destroy()
	end
end
folder:Destroy()
report.overlapNames = {}
for name, n in report.overlaps do table.insert(report.overlapNames, name .. "=" .. n) end
report.overlaps = nil
return game.HttpService:JSONEncode(report)
