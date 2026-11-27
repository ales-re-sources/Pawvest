-- TR2: three disposable static mature apple-tree studies, Studio Edit context. No scripts, remotes or profile writes.
-- Front row: Apple (red); back row (z = -40): the same shapes in the Golden apple palette with its two extra fruit slots.
-- Run with execute_luau, capture, then destroy workspace.AppleRipeStudies and restore the camera.
assert(game:GetService("RunService"):IsStudio(), "Studio only")
assert(not workspace:FindFirstChild("AppleRipeStudies"), "Remove previous study first")
local V, C = Vector3.new, Color3.fromRGB
local folder = Instance.new("Folder")
folder.Name = "AppleRipeStudies"
local LIMIT = 2.35 -- ground radius every corner keeps (the field's 2.4 minus a margin)

local PALETTES = {
	Apple = {
		bark = C(112, 78, 54), limb = C(128, 92, 62), stalk = C(92, 66, 42), fruitLeaf = C(98, 168, 72),
		leaves = { C(70, 140, 62), C(92, 160, 70), C(58, 122, 64) },
		fruit = C(206, 48, 44), facet = C(232, 96, 72), slots = 4, d = 0.62,
	},
	GoldenApple = {
		bark = C(124, 94, 66), limb = C(140, 106, 72), stalk = C(110, 80, 44), fruitLeaf = C(120, 176, 70),
		leaves = { C(92, 148, 62), C(120, 168, 70), C(78, 132, 66) },
		fruit = C(239, 178, 40), facet = C(255, 214, 88), slots = 6, d = 0.64,
	},
}

local function block(m, name, size, cf, color, role, slot, variant)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Material, p.MaterialVariant = Enum.Material.Plastic, variant or "StudsSmall"
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	if role then p:SetAttribute("PlantRole", role) end
	if slot then p:SetAttribute("FruitSlot", slot) end
	p.Parent = m
	return p
end
local function rod(m, b, a, z, w, color, role, slot)
	local d = z - a
	local up = if math.abs(d.Unit.Y) > 0.98 then Vector3.xAxis else Vector3.yAxis
	return block(m, "Stem", V(w, w, d.Magnitude + 0.025), b * CFrame.lookAt((a + z) / 2, a, up), color, role or "Structure", slot)
end
-- Soil-space point at yaw t (0 = towards the camera, +Z), radius r, height y.
local function pt(t, r, y)
	return V(math.sin(t) * r, y, math.cos(t) * r)
end
-- Largest ground radius of a box's corners in soil space.
local function reach(cf: CFrame, size: Vector3): number
	local r = 0
	for x = -1, 1, 2 do for y = -1, 1, 2 do for z = -1, 1, 2 do
		local a = cf:PointToWorldSpace(size * V(x, y, z) / 2)
		r = math.max(r, V(a.X, 0, a.Z).Magnitude)
	end end end
	return r
end
-- A leaf clump: one stud box, yawed and tipped a little, pulled towards the trunk until it fits the field radius.
local clumps = 0
local function clump(m, b, pal, center, size, yaw, tip)
	clumps += 1
	local cf = CFrame.new(center) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(tip or 0, 0, (tip or 0) * 0.6)
	local over = reach(cf, size) - LIMIT
	if over > 0 then
		local flat = V(center.X, 0, center.Z)
		if flat.Magnitude > 0.01 then
			cf = cf - flat.Unit * math.min(over + 0.01, flat.Magnitude)
		end
	end
	block(m, "Leaves", size, b * cf, pal.leaves[clumps % 3 + 1], "Foliage")
end
-- An apple hanging under `at`: stalk, an octagonal two-block body, a small leaf. Fruit slot `slot`.
local function apple(m, b, pal, at, slot)
	local d = pal.d
	local top = at + V(0, d * 0.45, 0)
	rod(m, b, top, top + V(0, 0.28, 0), 0.07, pal.stalk, "Fruit", slot)
	local cf = b * CFrame.new(at) * CFrame.Angles(0, slot * 0.5, 0)
	block(m, "Fruit", V(d, d * 0.9, d), cf, pal.fruit, "Fruit", slot)
	block(m, "FruitFacet", V(d * 0.86, d * 0.8, d * 0.86), cf * CFrame.Angles(0, math.pi / 4, 0), pal.facet, "Fruit", slot)
	block(m, "FruitLeaf", V(0.22, 0.05, 0.36), cf * CFrame.new(0.1, d * 0.5 + 0.1, 0.12) * CFrame.Angles(0.5, 0.6, 0),
		pal.fruitLeaf, "Fruit", slot, "Studs")
end

local studies = {
	-- A: classic round crown. Straight trunk, three short limbs and a leader under a ball of leaf clumps; apples hang
	-- from the crown's lower skin.
	{ name = "A_RoundCrown", build = function(m, b, pal)
		rod(m, b, V(0, 0, 0), V(0.04, 3.1, 0), 0.5, pal.bark)
		for k = 0, 2 do
			local t = 0.4 + k * 2.1
			rod(m, b, pt(t, 0.12, 0.28), pt(t, 0.55, 0), 0.22, pal.bark) -- root flare
			rod(m, b, V(0.04, 2.9, 0), pt(t, 1.0, 4.4), 0.26, pal.limb)
		end
		rod(m, b, V(0.04, 3.0, 0), V(0, 5.0, 0), 0.28, pal.limb)
		clump(m, b, pal, V(0, 5.3, 0), V(2.1, 1.8, 2.1), 0.3)
		for k = 0, 5 do clump(m, b, pal, pt(k * math.pi / 3, 1.35, 4.7), V(1.5, 1.2, 1.5), k * 0.7, 0.15) end
		for k = 0, 4 do clump(m, b, pal, pt(0.6 + k * 2 * math.pi / 5, 1.1, 5.8), V(1.4, 1.1, 1.4), k * 0.9 + 0.3, -0.12) end
		clump(m, b, pal, V(0.25, 6.6, 0.1), V(1.3, 1.0, 1.3), 0.5, 0.1)
		clump(m, b, pal, V(-0.3, 6.5, -0.2), V(1.2, 0.9, 1.2), 1.1, -0.1)
		local spots = { pt(0.25, 1.75, 3.45), pt(1.75, 1.7, 3.55), pt(-0.95, 1.75, 3.5), pt(3.6, 1.7, 3.5), pt(-1.9, 1.8, 4.0),
			pt(2.5, 1.8, 4.05) }
		for slot = 1, pal.slots do apple(m, b, pal, spots[slot], slot) end
	end },
	-- B: open orchard vase. Short trunk, four scaffold limbs flaring out, leaf clumps at their ends; apples hang from the
	-- limbs in the open middle, easy to see and count.
	{ name = "B_OpenVase", build = function(m, b, pal)
		rod(m, b, V(0, 0, 0), V(0, 1.8, 0), 0.52, pal.bark)
		local limbs = {}
		for k = 0, 3 do
			local t = 0.35 + k * math.pi / 2
			local a, mid, z = V(0, 1.65, 0), pt(t, 0.85, 3.1), pt(t, 1.35, 4.6)
			rod(m, b, a, mid, 0.3, pal.bark)
			rod(m, b, mid, z, 0.22, pal.limb)
			limbs[k + 1] = { t = t, mid = mid, z = z }
			rod(m, b, pt(t + 0.4, 0.12, 0.25), pt(t + 0.4, 0.55, 0), 0.22, pal.bark) -- root flare
		end
		for _, l in limbs do
			clump(m, b, pal, pt(l.t, 1.3, 5.25), V(1.6, 1.25, 1.6), l.t, 0.12)
			clump(m, b, pal, pt(l.t + 0.45, 1.25, 4.55), V(1.2, 0.9, 1.2), l.t + 0.6, -0.15)
			clump(m, b, pal, pt(l.t - 0.3, 0.95, 6.1), V(1.2, 0.95, 1.2), l.t + 0.2, 0.1)
		end
		clump(m, b, pal, V(0, 6.55, 0), V(1.3, 0.95, 1.3), 0.4)
		local function under(l, f, outBy, drop)
			local p = l.mid:Lerp(l.z, f)
			local out = V(p.X, 0, p.Z).Unit
			return p + out * outBy - V(0, drop, 0)
		end
		local spots = { under(limbs[1], 0.35, 0.15, 0.75), under(limbs[2], 0.45, 0.15, 0.75), under(limbs[3], 0.3, 0.15, 0.75),
			under(limbs[4], 0.45, 0.15, 0.75), under(limbs[1], 0.95, 0.0, 0.7), under(limbs[3], 0.95, 0.0, 0.7) }
		for slot = 1, pal.slots do apple(m, b, pal, spots[slot], slot) end
	end },
	-- C: tiered storybook tree. Straight trunk through three stacked rings of flat clumps, narrowing upward; apples hang
	-- under the rims of the two lower tiers.
	{ name = "C_Tiered", build = function(m, b, pal)
		rod(m, b, V(0, 0, 0), V(0, 3.6, 0), 0.5, pal.bark)
		rod(m, b, V(0, 3.5, 0), V(0, 6.3, 0), 0.34, pal.limb)
		for k = 0, 2 do
			local t = 0.2 + k * 2.1
			rod(m, b, pt(t, 0.12, 0.28), pt(t, 0.55, 0), 0.22, pal.bark) -- root flare
			rod(m, b, V(0, 3.0, 0), pt(t, 1.2, 3.45), 0.2, pal.limb)
		end
		for k = 0, 5 do clump(m, b, pal, pt(k * math.pi / 3, 1.45, 3.6), V(1.5, 0.75, 1.2), k * math.pi / 3, 0.08) end
		for k = 0, 4 do clump(m, b, pal, pt(0.3 + k * 2 * math.pi / 5, 1.0, 4.9), V(1.3, 0.7, 1.1), 0.3 + k * 2 * math.pi / 5, 0.08) end
		for k = 0, 2 do clump(m, b, pal, pt(0.9 + k * 2 * math.pi / 3, 0.5, 6.0), V(1.1, 0.65, 0.95), 0.9 + k * 2 * math.pi / 3, 0.08) end
		clump(m, b, pal, V(0, 6.75, 0), V(0.9, 0.75, 0.9), 0.4)
		local spots = { pt(0.0, 1.8, 2.75), pt(1.57, 1.8, 2.75), pt(-1.57, 1.8, 2.75), pt(3.14, 1.8, 2.75), pt(0.8, 1.45, 4.15),
			pt(-0.8, 1.45, 4.15) }
		for slot = 1, pal.slots do apple(m, b, pal, spots[slot], slot) end
	end },
}

local y0 = 500
local counts = {}
for row, palName in { "Apple", "GoldenApple" } do
	local z = if row == 1 then 0 else -40
	block(folder, "GrassContext_" .. palName, V(26, 0.5, 9), CFrame.new(-1, y0 - 0.45, z), C(103, 149, 75))
	for i, s in studies do
		local base = CFrame.new((i - 2) * 6.5, y0, z)
		block(folder, "Soil_" .. palName .. i, V(5.5, 0.30, 5.5), base * CFrame.new(0, -0.15, 0), C(88, 66, 48), nil, nil, "Studs")
		local m = Instance.new("Model")
		m.Name = palName .. "_" .. s.name
		clumps = 0
		s.build(m, base, PALETTES[palName])
		local radius, top, bottom = 0, 0, math.huge
		for _, p in m:GetChildren() do
			local local_ = base:ToObjectSpace(p.CFrame)
			radius = math.max(radius, reach(local_, p.Size))
			for x = -1, 1, 2 do for y = -1, 1, 2 do for zz = -1, 1, 2 do
				local a = local_:PointToWorldSpace(p.Size * V(x, y, zz) / 2)
				top = math.max(top, a.Y)
				if p.Name == "Fruit" then bottom = math.min(bottom, a.Y) end
			end end end
		end
		counts[m.Name] = { parts = #m:GetChildren(), height = math.floor(top * 100) / 100, radius = math.floor(radius * 100) / 100,
			fruitClearance = math.floor(bottom * 100) / 100 }
		assert(radius <= 2.4, "Study exceeds field radius: " .. m.Name .. " " .. radius)
		assert(#m:GetChildren() <= 130, "Study exceeds budget: " .. m.Name .. " " .. #m:GetChildren())
		m.Parent = folder
	end
end
local ok, avatar = pcall(function()
	return game.Players:CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
end)
if ok then
	avatar.Name = "ReferenceAvatar"
	avatar.Parent = folder
	avatar:PivotTo(CFrame.new(-10.25, y0 + 3, 0.35) * CFrame.Angles(0, math.pi, 0))
	local minY = math.huge
	for _, p in avatar:GetDescendants() do
		if p:IsA("BasePart") then minY = math.min(minY, p.Position.Y - p.Size.Y / 2); p.Anchored = true; p.CanCollide = false end
	end
	avatar:PivotTo(avatar:GetPivot() + V(0, y0 - minY, 0))
	avatar.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	counts.avatarHeight = avatar:GetExtentsSize().Y
else
	folder:Destroy()
	error("Avatar reference failed: " .. tostring(avatar))
end
folder.Parent = workspace
return game.HttpService:JSONEncode(counts)
