-- CG19a: static ripe giant-melon studies, Studio Edit context (execute_luau). Display only: no remotes, no saved data.
-- A = ground giant (long striped melon on a low runner), B = arching vine (round melon, pumpkin-style arch),
-- C = trellis sling (ladder trellis, melon resting in a rope sling).
-- Builds workspace.MelonRipeStudies in the sky; Destroy it after review and set the Edit camera back to Fixed.
assert(not workspace:FindFirstChild("MelonRipeStudies"), "Remove previous studies first")
local V, C = Vector3.new, Color3.fromRGB
local RIND = {C(26, 86, 46), C(142, 202, 104)} -- dark stripe, light stripe
local SPOT, SCAR = C(238, 208, 100), C(70, 62, 40)
local STEM, DRY = C(104, 126, 62), C(130, 100, 60)
local VINE = C(86, 140, 72)
local LEAF = {C(48, 128, 66), C(78, 156, 84)}
local YELLOW = C(250, 204, 58)
local WOOD, ROPE = C(176, 132, 78), C(196, 170, 120)
local SOIL = C(88, 66, 48)

local function block(model, name, size, cf, color, variant)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Material, p.MaterialVariant = Enum.Material.Plastic, variant or "StudsSmall"
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.Parent = model
	return p
end
local function rod(model, base, a, b, width, color, name)
	local d = b - a
	if d.Magnitude < 0.001 then return end
	local up = if math.abs(d.Unit.Y) > 0.98 then Vector3.xAxis else Vector3.yAxis
	block(model, name or "Vine", V(width, width, d.Magnitude), base * CFrame.lookAt((a + b) / 2, a, up), color)
end
local function run(model, base, points, width, color, name)
	for i = 1, #points - 1 do rod(model, base, points[i], points[i + 1], width, color, name) end
end

-- Striped melon lying along its local X axis: eight stripe ribs (alternating dark / light green) around the axis, each a
-- long middle block and two shorter, narrower end blocks. `pos` is the centre in soil space; returns the stem-end point.
local function melon(model, base, pos, L, R, yaw)
	local fr = base * CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
	local segs = {{0, 0.52 * L, R}, {0.37 * L, 0.28 * L, 0.80 * R}, {-0.37 * L, 0.28 * L, 0.80 * R}}
	for i = 0, 7 do
		local rib = fr * CFrame.Angles(i * math.pi / 4, 0, 0)
		for _, s in segs do
			local rad = s[3]
			block(model, "Rind", V(s[2], rad * 0.55, rad * 0.86), rib * CFrame.new(s[1], rad * 0.725, 0), RIND[i % 2 + 1])
		end
	end
	-- Pale ground spot on the lower front flank, dark scar at the blossom end.
	block(model, "GroundSpot", V(0.30 * L, 0.07, 0.50 * R), fr * CFrame.Angles(math.rad(128), 0, 0) * CFrame.new(0.05 * L, R * 1.0, 0), SPOT)
	block(model, "BlossomScar", V(0.12, 0.30, 0.30), fr * CFrame.new(-0.515 * L, 0, 0), SCAR)
	return (CFrame.new(pos) * CFrame.Angles(0, yaw, 0)):PointToWorldSpace(V(0.5 * L, 0.25 * R, 0)) -- soil space
end
-- Curled stem from the fruit's stem end up to the vine, with one dry brown tendril beside it (the ripeness cue).
local function stem(model, base, a, vinePoint)
	local m1, m2 = a:Lerp(vinePoint, 0.35) + V(0.05, 0.25, 0.05), a:Lerp(vinePoint, 0.7) + V(0.0, 0.1, 0.0)
	run(model, base, {a, m1, m2, vinePoint}, 0.24, STEM, "MelonStem")
	run(model, base, {m1, m1 + V(0.22, 0.22, 0.12), m1 + V(0.38, 0.06, 0.28), m1 + V(0.18, -0.1, 0.34)}, 0.07, DRY, "DryTendril")
end

-- Deeply lobed leaf: five narrow lobes fanned from the hinge, on a petiole. Lobes differ by a hair in height.
local LOBES = {{0, 1.15, 0.50}, {0.62, 0.95, 0.40}, {-0.62, 0.95, 0.40}, {1.22, 0.68, 0.34}, {-1.22, 0.68, 0.34}}
local function leaf(model, base, node, at, scale, yaw, tilt)
	rod(model, base, node, at, 0.13, VINE, "Petiole")
	local face = base * CFrame.new(at) * CFrame.Angles(tilt, yaw, 0)
	for i, l in LOBES do
		block(model, "LeafLobe", V(l[3] * scale, 0.09, l[2] * scale), face * CFrame.Angles(0, l[1], 0) * CFrame.new(0, 0.012 * i, l[2] * scale / 2), LEAF[i % 2 + 1], "Studs")
	end
end
local function flower(model, base, at, up)
	rod(model, base, at - up, at, 0.10, STEM, "FlowerStalk")
	for i = 0, 4 do
		block(model, "Petal", V(0.28, 0.05, 0.50), base * CFrame.new(at) * CFrame.Angles(0, i * math.pi * 0.4, 0) * CFrame.Angles(-0.35, 0, 0) * CFrame.new(0, 0, 0.24), YELLOW)
	end
	block(model, "FlowerCore", V(0.18, 0.18, 0.18), base * CFrame.new(at + V(0, 0.07, 0)), C(214, 140, 30))
end
local function tendril(model, base, a)
	run(model, base, {a, a + V(0.20, 0.30, -0.10), a + V(0.46, 0.34, -0.22), a + V(0.52, 0.14, -0.30)}, 0.06, VINE, "Tendril")
end

local studies = {
	{ name = "A - Ground giant", build = function(m, b)
		local L, R = 4.6, 1.4
		local e = melon(m, b, V(-0.1, R * 0.96, 0.35), L, R, 0.30)
		local v = {V(-1.9, 0.12, -1.0), V(-1.1, 0.16, -1.8), V(0.1, 0.16, -1.6), V(1.0, 0.16, -1.9), V(1.9, 0.16, -1.0)}
		run(m, b, v, 0.20, VINE)
		stem(m, b, e, V(1.9, 0.16, -1.0))
		leaf(m, b, v[1], V(-1.9, 1.05, -0.9), 1.15, 0.9, -0.22)
		leaf(m, b, v[2], V(-1.1, 1.75, -1.7), 1.25, 3.1, -0.25)
		leaf(m, b, v[3], V(0.2, 1.35, -1.4), 1.10, 2.4, -0.30)
		leaf(m, b, v[4], V(1.0, 1.95, -1.8), 1.25, 3.0, -0.25)
		leaf(m, b, v[5], V(1.55, 1.15, -0.5), 1.00, 1.6, -0.22)
		leaf(m, b, v[3], V(-0.7, 2.35, -0.9), 0.95, 0.2, -0.35)
		flower(m, b, V(-1.5, 0.95, -0.2), V(0.0, 0.8, -0.1))
		tendril(m, b, v[2]); tendril(m, b, v[4])
	end },
	{ name = "B - Arching vine", build = function(m, b)
		local L, R = 3.3, 1.5
		local e = melon(m, b, V(0.45, R * 0.94, 0.65), L, R, 0.45)
		local arch = {V(-1.5, 0.1, -1.2), V(-1.75, 1.2, -1.0), V(-1.35, 2.4, -0.6), V(-0.5, 3.2, -0.3), V(0.4, 3.4, -0.2), V(1.2, 2.9, 0.0), V(1.3, 2.3, 0.3)}
		run(m, b, arch, 0.22, VINE)
		stem(m, b, e, arch[7])
		leaf(m, b, arch[3], V(-1.9, 2.95, -0.4), 1.15, 0.3, -0.35)
		leaf(m, b, arch[4], V(-0.7, 3.95, -0.1), 1.2, -0.4, -0.25)
		leaf(m, b, arch[5], V(0.7, 4.0, 0.0), 1.1, 0.6, -0.30)
		leaf(m, b, arch[6], V(1.9, 3.05, 0.1), 1.0, 1.3, -0.30)
		leaf(m, b, arch[2], V(-1.35, 0.95, 0.2), 0.95, 2.4, -0.25)
		leaf(m, b, arch[1], V(-0.5, 0.8, -1.5), 1.0, 3.0, -0.30)
		flower(m, b, V(0.2, 2.9, 0.4), V(0.0, 0.6, -0.2))
		tendril(m, b, arch[4]); tendril(m, b, arch[6])
	end },
	{ name = "C - Trellis sling", build = function(m, b)
		local L, R = 3.6, 1.15
		-- Rigid ladder trellis behind the fruit: two posts and three rungs.
		for _, x in {-2.0, 2.0} do block(m, "Post", V(0.30, 4.8, 0.30), b * CFrame.new(x, 2.4, -1.6), WOOD) end
		for _, y in {1.4, 2.9, 4.4} do block(m, "Rung", V(4.3, 0.24, 0.24), b * CFrame.new(0, y, -1.6), WOOD) end
		-- Fruit hangs a little above the soil in a rope sling tied to the middle rung.
		local cy = 1.75
		local e = melon(m, b, V(0, cy, 0.0), L, R, 0.0)
		block(m, "Sling", V(L * 0.62, 0.10, R * 1.5), b * CFrame.new(0, cy - R - 0.04, 0), ROPE)
		for _, x in {-1.0, 1.0} do
			rod(m, b, V(x, cy - R, 0.55), V(x * 1.1, 2.9, -1.6), 0.06, ROPE, "SlingCord")
			rod(m, b, V(x, cy - R, -0.55), V(x * 1.1, 2.9, -1.6), 0.06, ROPE, "SlingCord")
		end
		local v = {V(-1.9, 0.12, -1.3), V(-1.8, 1.4, -1.5), V(-1.4, 2.6, -1.5), V(-0.5, 3.6, -1.5), V(0.6, 4.3, -1.5), V(1.6, 3.7, -1.4), V(1.9, 2.6, -1.0)}
		run(m, b, v, 0.20, VINE)
		stem(m, b, e, v[7])
		leaf(m, b, v[2], V(-2.0, 1.9, -1.0), 1.0, 0.5, -0.3)
		leaf(m, b, v[3], V(-1.2, 3.1, -1.2), 1.15, 3.2, -0.3)
		leaf(m, b, v[4], V(-0.6, 4.2, -1.1), 1.15, 0.2, -0.3)
		leaf(m, b, v[5], V(0.9, 4.7, -1.2), 1.0, -0.3, -0.3)
		leaf(m, b, v[6], V(1.8, 4.1, -1.0), 1.05, 1.0, -0.3)
		leaf(m, b, v[1], V(-0.6, 0.9, -1.3), 0.9, 3.0, -0.25)
		flower(m, b, V(-0.2, 3.4, -0.8), V(0.0, 0.5, -0.4))
		tendril(m, b, v[4]); tendril(m, b, v[6])
	end },
}

local folder = Instance.new("Folder")
folder.Name = "MelonRipeStudies"
local y0 = 500
local slab = Instance.new("Part")
slab.Anchored, slab.Size, slab.Color, slab.Position, slab.Parent = true, V(7 * 3 + 6, 1, 9), SOIL, V(0, y0 - 0.5, 0), folder
slab.Name = "SoilSlab"
local counts = {}
for i, study in studies do
	local model = Instance.new("Model")
	model.Name = study.name
	study.build(model, CFrame.new((i - 2) * 7.5, y0, 0))
	counts[study.name] = #model:GetChildren()
	model.Parent = folder
end
-- Avatar-height marker (R15, 5.46 studs) so the height can be judged against the player.
local marker = Instance.new("Part")
marker.Name, marker.Anchored, marker.CanCollide, marker.Size, marker.Color = "AvatarHeight", true, false, V(0.5, 5.46, 0.5), C(120, 160, 220)
marker.Position = V(-12.5, y0 + 2.73, 0)
marker.Parent = folder
folder.Parent = workspace
return game.HttpService:JSONEncode(counts)
