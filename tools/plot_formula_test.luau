-- Plot-position formula test (E1.0, docs/ROADMAP.md → E1.0 check 2). Run through the Studio MCP `execute_luau`:
--   * Edit: compares GardenConfig.PlotCFrame(1..12) with the Studio plots (Workspace.Garden.Plots.Plot_NN.Floor) and
--     checks today's rings and the E1 proposal for overlap and the gap between plots (floor alone, and floor + the 12-square field
--     PlotView draws behind it);
--   * Server and Client of one playtest: run it in both and compare the `hash` lines (same formula on both sides).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MIN_GAP = 8
local FIELD_DEPTH = 3 * 5.5 -- PlotView: 12 squares = 4 x 3 at pitch 5.5, starting 22 behind the floor centre
local FIELD_FRONT = 22

-- Edit: clones in a folder outside the DataModel (GardenConfig finds PetConfig beside it), so the run sees the current Source
local function fresh()
	local folder = Instance.new("Folder")
	ReplicatedStorage.PetConfig:Clone().Parent = folder
	local copy = ReplicatedStorage.GardenConfig:Clone()
	copy.Parent = folder
	return require(copy)
end
local GardenConfig = if RunService:IsRunning() then require(ReplicatedStorage.GardenConfig) else fresh()

local out = {}
local function line(text: string)
	table.insert(out, text)
end

-- corners (XZ) of a rectangle in floor space: x from -w/2 to w/2, z from z0 to z1
local function corners(cf: CFrame, w: number, z0: number, z1: number): { Vector2 }
	local result = {}
	for _, p in { Vector3.new(-w / 2, 0, z0), Vector3.new(w / 2, 0, z0), Vector3.new(w / 2, 0, z1), Vector3.new(-w / 2, 0, z1) } do
		local world = cf:PointToWorldSpace(p)
		table.insert(result, Vector2.new(world.X, world.Z))
	end
	return result
end

local function pointSegment(p: Vector2, a: Vector2, b: Vector2): number
	local ab = b - a
	local t = math.clamp((p - a):Dot(ab) / ab:Dot(ab), 0, 1)
	return (p - (a + ab * t)).Magnitude
end

local function inside(p: Vector2, poly: { Vector2 }): boolean
	local sign = 0
	for i = 1, #poly do
		local a, b = poly[i], poly[i % #poly + 1]
		local cross = (b.X - a.X) * (p.Y - a.Y) - (b.Y - a.Y) * (p.X - a.X)
		local s = if cross > 0 then 1 elseif cross < 0 then -1 else 0
		if s ~= 0 then
			if sign ~= 0 and s ~= sign then
				return false
			end
			sign = s
		end
	end
	return true
end

-- distance between two convex quads (0 when they overlap)
local function distance(a: { Vector2 }, b: { Vector2 }): number
	for _, p in a do
		if inside(p, b) then
			return 0
		end
	end
	for _, p in b do
		if inside(p, a) then
			return 0
		end
	end
	local best = math.huge
	for _, pair in { { a, b }, { b, a } } do
		local from, to = pair[1], pair[2]
		for _, p in from do
			for i = 1, #to do
				best = math.min(best, pointSegment(p, to[i], to[i % #to + 1]))
			end
		end
	end
	return best
end

-- 1. formula = Studio plots
local plots = workspace:FindFirstChild("Garden") and workspace.Garden:FindFirstChild("Plots")
if plots and not RunService:IsRunning() then
	local worstPos, worstRot = 0, 0
	for slot = 1, 12 do
		local floor = plots[GardenConfig.PlotName(slot)].Floor
		local cf = GardenConfig.PlotCFrame(slot) :: CFrame
		worstPos = math.max(worstPos, (cf.Position - floor.Position).Magnitude)
		local rot = math.min(cf.LookVector:Dot(floor.CFrame.LookVector), cf.UpVector:Dot(floor.CFrame.UpVector))
		worstRot = math.max(worstRot, 1 - rot)
	end
	line(string.format("studio match: worst position error %.4f studs, worst rotation 1-dot %.6f -> %s", worstPos, worstRot,
		if worstPos < 0.01 and worstRot < 1e-5 then "PASS" else "FAIL"))
end

-- 2. no overlap, gap >= MIN_GAP: today's rings (GardenConfig.PlotRings) and the E1 proposal (ring 1 moved out to 112)
local LAYOUTS = {
	{ "today", GardenConfig.PlotRings },
	{ "E1 proposal", { { count = 12, radius = 112 }, { count = 18, radius = 185 } } },
}
for _, layout in LAYOUTS do
	local rings = layout[2]
	local slots = 0
	for _, ring in rings do
		slots += ring.count
	end
	for _, case in { { "floor", -20, 20 }, { "floor+field", -20, FIELD_FRONT + FIELD_DEPTH } } do
		local quads = {}
		for slot = 1, slots do
			quads[slot] = corners(GardenConfig.PlotCFrame(slot, rings) :: CFrame, 40, case[2], case[3])
		end
		local worst, pair = {}, {} -- [ring pair "1-1" / "1-2" / "2-2"] = smallest gap, slots
		for i = 1, slots do
			for j = i + 1, slots do
				local key = GardenConfig.PlotRing(i, rings) .. "-" .. GardenConfig.PlotRing(j, rings)
				local d = distance(quads[i], quads[j])
				if d < (worst[key] or math.huge) then
					worst[key], pair[key] = d, i .. "/" .. j
				end
			end
		end
		local parts = {}
		local all = math.huge
		for _, key in { "1-1", "1-2", "2-2" } do
			if worst[key] then
				all = math.min(all, worst[key])
				table.insert(parts, string.format("%s %.2f (%s)", key, worst[key], pair[key]))
			end
		end
		line(string.format("%s, %s: %d slots, smallest gap by ring pair %s -> %s", layout[1], case[1], slots,
			table.concat(parts, ", "), if all >= MIN_GAP then "PASS" else "FAIL"))
	end
end

-- 3. hash of every slot's CFrame, to compare Server and Client
local parts = {}
for slot = 1, GardenConfig.PlotSlots do
	local cf = GardenConfig.PlotCFrame(slot) :: CFrame
	local ring, position = GardenConfig.PlotRing(slot)
	table.insert(parts, string.format("%d:%d:%d:%.3f,%.3f,%.3f,%.4f,%.4f", slot, ring, position, cf.X, cf.Y, cf.Z, cf.LookVector.X, cf.LookVector.Z))
end
local text = table.concat(parts, ";")
local hash = 0
for i = 1, #text do
	hash = (hash * 31 + string.byte(text, i)) % 4294967291
end
line(string.format("hash (%s): %d over %d slots, outside: %s / %s", if RunService:IsServer() then "server" else "client", hash,
	GardenConfig.PlotSlots, tostring(GardenConfig.PlotCFrame(0)), tostring(GardenConfig.PlotCFrame(GardenConfig.PlotSlots + 1))))

return table.concat(out, "\n")
