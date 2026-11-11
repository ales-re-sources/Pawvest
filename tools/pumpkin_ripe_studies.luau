-- CG15a: static ripe-pumpkin studies, Studio Edit context (execute_luau). Display only: no remotes, no saved data.
-- A = patch canopy (big leaves on raised petioles), B = arching vine, C = giant fruit on a low runner.
-- Builds workspace.PumpkinRipeStudies in the sky; Destroy it after review and set the Edit camera back to Fixed.
assert(not workspace:FindFirstChild("PumpkinRipeStudies"), "Remove previous studies first")
local V, C = Vector3.new, Color3.fromRGB
local SKIN = {C(236, 132, 40), C(218, 110, 30)}
local STEM, DRY = C(104, 126, 62), C(122, 94, 58)
local VINE = C(86, 140, 72)
local LEAF = {C(48, 118, 62), C(76, 148, 78)}
local YELLOW = C(250, 204, 58)
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

-- Ribbed pumpkin: eight rib blocks 45 degrees apart (alternating two oranges), each with a narrower shoulder block.
local function pumpkin(model, base, pos, D, tall, yaw, dry)
	local H = D * tall
	for i = 0, 7 do
		local frame = base * CFrame.new(pos + V(0, H / 2, 0)) * CFrame.Angles(0, yaw + i * math.pi / 4, 0)
		local color = SKIN[i % 2 + 1]
		block(model, "Rib", V(D * 0.62, H, D * 0.40), frame * CFrame.new(D * 0.15, 0, 0), color)
		block(model, "RibShoulder", V(D * 0.44, H * 0.26, D * 0.34), frame * CFrame.new(D * 0.07, H * 0.5 + H * 0.05, 0), color)
	end
	local top = pos + V(0, H * 0.68, 0)
	local stemColor = if dry then DRY else STEM
	return top, {top + V(0, 0.55, 0), top + V(0.18, 0.78, 0.04), top + V(0.46, 0.80, 0.08)}, stemColor
end
local function stem(model, base, top, tip, color)
	rod(model, base, top, tip[1], 0.36, color, "PumpkinStem")
	rod(model, base, tip[1], tip[2], 0.30, color, "PumpkinStem")
	rod(model, base, tip[2], tip[3], 0.24, color, "PumpkinStem")
end

-- Broad five-plate leaf on a petiole. Plates differ by a hair in height so none shares a face plane.
local PLATES = {
	{V(0, 0, 0.42), V(0.90, 0.09, 0.92), 0},
	{V(-0.46, 0.012, 0.06), V(0.62, 0.09, 0.78), -0.55},
	{V(0.46, 0.024, 0.06), V(0.62, 0.09, 0.78), 0.55},
	{V(-0.34, 0.036, -0.30), V(0.50, 0.09, 0.50), -0.95},
	{V(0.34, 0.048, -0.30), V(0.50, 0.09, 0.50), 0.95},
}
local function leaf(model, base, node, at, scale, yaw, tilt)
	rod(model, base, node, at, 0.14, VINE, "Petiole")
	local face = base * CFrame.new(at) * CFrame.Angles(tilt, yaw, 0)
	for i, p in PLATES do
		block(model, "LeafPlate", p[2] * scale, face * CFrame.new(p[1] * scale) * CFrame.Angles(0, p[3], 0), LEAF[i % 2 + 1], "Studs")
	end
end
local function flower(model, base, at, up)
	rod(model, base, at - up, at, 0.12, STEM, "FlowerStalk")
	for i = 0, 4 do
		block(model, "Petal", V(0.34, 0.06, 0.62), base * CFrame.new(at) * CFrame.Angles(0, i * math.pi * 0.4, 0) * CFrame.Angles(-0.35, 0, 0) * CFrame.new(0, 0, 0.30), YELLOW)
	end
	block(model, "FlowerCore", V(0.22, 0.22, 0.22), base * CFrame.new(at + V(0, 0.08, 0)), C(214, 140, 30))
end
local function tendril(model, base, a)
	run(model, base, {a, a + V(0.20, 0.30, -0.10), a + V(0.46, 0.34, -0.22), a + V(0.52, 0.14, -0.30)}, 0.06, VINE, "Tendril")
end

local studies = {
	{ name = "A - Patch canopy", build = function(m, b)
		local top, tip, sc = pumpkin(m, b, V(0.25, 0, 0.45), 2.1, 0.72, 0.2, false)
		stem(m, b, top, tip, sc)
		run(m, b, {V(-1.9, 0.12, -1.3), V(-1.2, 0.7, -0.7), V(-0.55, 1.35, -0.2), tip[3]}, 0.20, VINE)
		run(m, b, {V(-1.9, 0.12, -1.3), V(-0.4, 0.10, -1.7), V(1.0, 0.12, -1.6), V(1.6, 0.10, -0.9)}, 0.18, VINE)
		leaf(m, b, V(-1.2, 0.7, -0.7), V(-1.5, 1.9, -0.5), 1.15, 0.4, -0.3)
		leaf(m, b, V(-0.55, 1.35, -0.2), V(-0.75, 2.35, 0.15), 1.05, -0.5, -0.25)
		leaf(m, b, V(-0.4, 0.10, -1.7), V(-0.3, 1.55, -1.8), 1.2, 3.0, -0.3)
		leaf(m, b, V(1.0, 0.12, -1.6), V(1.1, 1.75, -1.3), 1.15, 2.6, -0.3)
		leaf(m, b, V(1.6, 0.10, -0.9), V(1.5, 1.2, -0.5), 0.95, 1.9, -0.25)
		leaf(m, b, V(-1.9, 0.12, -1.3), V(-1.8, 1.0, -0.95), 0.95, 0.9, -0.2)
		leaf(m, b, V(-0.2, 0.12, -1.65), V(0.5, 0.85, -0.4), 0.8, 2.2, -0.35)
		flower(m, b, V(1.2, 1.15, 0.55), V(0.05, 0.9, -0.1))
		tendril(m, b, V(-0.55, 1.35, -0.2))
	end },
	{ name = "B - Arching vine", build = function(m, b)
		local top, tip, sc = pumpkin(m, b, V(0.55, 0, 0.7), 2.0, 0.72, 0.5, false)
		stem(m, b, top, tip, sc)
		local arch = {V(-1.5, 0.1, -1.2), V(-1.75, 1.2, -1.0), V(-1.35, 2.4, -0.6), V(-0.5, 3.2, -0.3), V(0.4, 3.4, -0.2), V(1.2, 2.9, 0.0), V(1.05, 2.0, 0.4), tip[3]}
		run(m, b, arch, 0.22, VINE)
		leaf(m, b, arch[3], V(-1.9, 2.95, -0.4), 1.1, 0.3, -0.35)
		leaf(m, b, arch[4], V(-0.7, 3.95, -0.1), 1.15, -0.4, -0.25)
		leaf(m, b, arch[5], V(0.7, 4.0, 0.0), 1.05, 0.6, -0.3)
		leaf(m, b, arch[6], V(1.9, 3.05, 0.1), 1.0, 1.3, -0.3)
		leaf(m, b, arch[2], V(-1.35, 0.95, 0.2), 0.95, 2.4, -0.25)
		leaf(m, b, V(-1.5, 0.1, -1.2), V(-0.5, 0.8, -1.5), 1.0, 3.0, -0.3)
		flower(m, b, V(0.2, 2.9, 0.4), V(0.0, 0.6, -0.2))
		flower(m, b, V(-1.55, 1.75, 0.0), V(0.1, 0.5, -0.1))
		tendril(m, b, arch[4]); tendril(m, b, arch[6]); tendril(m, b, arch[2])
	end },
	{ name = "C - Giant fruit, low runner", build = function(m, b)
		local top, tip, sc = pumpkin(m, b, V(0.05, 0, 0.35), 2.6, 0.70, 0.35, true)
		stem(m, b, top, tip, sc)
		run(m, b, {V(-2.0, 0.10, -1.6), V(-1.0, 0.12, -1.9), V(0.1, 0.12, -1.7), V(1.3, 0.10, -1.8), V(2.0, 0.10, -1.0)}, 0.22, DRY)
		run(m, b, {V(-0.6, 0.12, -1.8), V(-0.2, 0.6, -1.0), V(0.1, 1.2, -0.3), tip[3]}, 0.20, DRY)
		leaf(m, b, V(-2.0, 0.10, -1.6), V(-1.7, 0.75, -1.1), 1.35, 0.8, -0.12)
		leaf(m, b, V(-1.0, 0.12, -1.9), V(-0.9, 0.95, -1.9), 1.3, 3.1, -0.15)
		leaf(m, b, V(1.3, 0.10, -1.8), V(1.2, 1.0, -1.5), 1.35, 2.8, -0.15)
		leaf(m, b, V(2.0, 0.10, -1.0), V(1.6, 0.7, -0.6), 1.2, 1.7, -0.12)
		leaf(m, b, V(0.1, 0.12, -1.7), V(-0.2, 1.7, -1.3), 1.1, -0.2, -0.3)
		tendril(m, b, V(-1.0, 0.12, -1.9)); tendril(m, b, V(1.3, 0.10, -1.8))
	end },
}

local folder = Instance.new("Folder")
folder.Name = "PumpkinRipeStudies"
local y0 = 500
local slab = Instance.new("Part")
slab.Anchored, slab.Size, slab.Color, slab.Position, slab.Parent = true, V(5.5 * 3 + 4, 1, 8), SOIL, V(0, y0 - 0.5, 0), folder
slab.Name = "SoilSlab"
local counts = {}
for i, study in studies do
	local model = Instance.new("Model")
	model.Name = study.name
	study.build(model, CFrame.new((i - 2) * 6.5, y0, 0))
	counts[study.name] = #model:GetChildren()
	assert(#model:GetChildren() <= 130, "Study part budget exceeded")
	model.Parent = folder
end
-- Avatar-height marker (R15, 5.46 studs) so the height can be judged against the player.
local marker = Instance.new("Part")
marker.Name, marker.Anchored, marker.CanCollide, marker.Size, marker.Color = "AvatarHeight", true, false, V(0.5, 5.46, 0.5), C(120, 160, 220)
marker.Position = V(-11, y0 + 2.73, 0)
marker.Parent = folder
folder.Parent = workspace
return game.HttpService:JSONEncode(counts)
