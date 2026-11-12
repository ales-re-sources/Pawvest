-- CG21b: Pineapple geometry checks, Studio Edit context (execute_luau). Display only: no remotes, no saved data.
-- Six seeds x three harvested masses x 101 ages: Part count, ground radius, top, NaN poses, leaves clear of the fruit from 78%,
-- exact visible backward seek (43 -> 44 -> 43%). Also builds the mid proxy at stages 1-3.
-- Edit mode caches require: run a fresh clone so the check sees the module on disk.
local clone = game.ReplicatedStorage.PineapplePlant:Clone()
clone.Name = "PineapplePlantCheck"
clone.Parent = game.ReplicatedStorage
local Plant = require(clone)
clone:Destroy()
local V = Vector3.new
local function smooth(g, a, b) local t = math.clamp((g - a) / (b - a), 0, 1) return t * t * (3 - 2 * t) end
local folder = Instance.new("Folder")
folder.Name = "PineappleChecks"
folder.Parent = workspace
local soil = CFrame.new(0, 500, 0)
local report = {parts = 0, maxRadius = 0, maxTop = 0, nan = 0, overlaps = {}, seekBad = 0, runs = 0, proxy = {}}
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
			local sc = 0.16 + 0.84 * smooth(g, 0.56, 0.98)
			local R, H = plant.R * sc, plant.H * sc
			local fp = soil.Position + V(plant.lean.X, 2.55, plant.lean.Z)
			for _, p in plant.model:GetChildren() do
				if p.Transparency < 0.99 then
					local pos = p.Position
					if pos.X ~= pos.X or pos.Y ~= pos.Y or pos.Z ~= pos.Z then report.nan += 1 end
					for _, w in corners(p) do
						local rel = w - soil.Position
						report.maxRadius = math.max(report.maxRadius, math.sqrt(rel.X ^ 2 + rel.Z ^ 2))
						report.maxTop = math.max(report.maxTop, rel.Y)
					end
					local role = p:GetAttribute("PlantRole")
					if role == "Foliage" and step >= 78 then
						for _, w in corners(p) do
							local rel = w - fp
							if rel.Y > 0.1 and rel.Y < H and math.sqrt(rel.X ^ 2 + rel.Z ^ 2) < 0.7 * R then
								report.overlaps[p.Name:match("^%a+_%d+") or p.Name] = (report.overlaps[p.Name:match("^%a+_%d+") or p.Name] or 0) + 1
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
for stage = 1, 3 do
	local pf = Instance.new("Folder")
	pf.Parent = folder
	Plant.BuildProxy(pf, soil, stage, 3, 1)
	report.proxy[stage] = #pf:GetChildren()
	pf:Destroy()
end
folder:Destroy()
report.overlapNames = {}
for name, n in report.overlaps do table.insert(report.overlapNames, name .. "=" .. n) end
report.overlaps = nil
return game.HttpService:JSONEncode(report)
