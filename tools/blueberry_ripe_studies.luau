-- CG17a: three disposable static mature blueberry studies, Studio Edit context. No scripts, remotes or profile writes.
-- Run with execute_luau, capture, then destroy workspace.BlueberryRipeStudies and restore the camera.
assert(game:GetService("RunService"):IsStudio(), "Studio only")
assert(not workspace:FindFirstChild("BlueberryRipeStudies"), "Remove previous study first")
local V, C = Vector3.new, Color3.fromRGB
local folder = Instance.new("Folder")
folder.Name = "BlueberryRipeStudies"
local CANE, TWIG = C(116, 86, 64), C(156, 88, 72)
local LEAVES = { C(84, 146, 68), C(110, 166, 78), C(72, 130, 84) }
local BERRY, BLOOM = C(88, 96, 150), C(150, 160, 204)
local UNRIPE, BLUSH = C(188, 208, 146), C(178, 108, 150)
local CROWN = C(40, 38, 70)

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
local function polyline(m, b, pts, w0, w1, color)
	for i = 1, #pts - 1 do
		local f = if #pts > 2 then (i - 1) / (#pts - 2) else 0
		rod(m, b, pts[i], pts[i + 1], w0 + (w1 - w0) * f, color)
	end
end
-- Point and unit direction at fraction t of a polyline's length.
local function along(pts, t)
	local total = 0
	for i = 1, #pts - 1 do total += (pts[i + 1] - pts[i]).Magnitude end
	local want = total * math.clamp(t, 0, 1)
	for i = 1, #pts - 1 do
		local seg = pts[i + 1] - pts[i]
		if want <= seg.Magnitude or i == #pts - 1 then
			return pts[i] + seg.Unit * math.min(want, seg.Magnitude), seg.Unit
		end
		want -= seg.Magnitude
	end
	return pts[#pts], (pts[#pts] - pts[#pts - 1]).Unit
end
-- A small elliptic leaf: one stud plate hinged at `at`, pointing along dir.
local function leaf(m, b, at, dir, len, wid, color, roll)
	-- Shorten a leaf whose tip would leave the field radius (2.3 studs, leaving room for the blade's width).
	local tipAt = at + dir.Unit * len
	local reach = V(tipAt.X, 0, tipAt.Z).Magnitude
	if reach > 2.3 then
		local base = V(at.X, 0, at.Z).Magnitude
		len *= math.clamp((2.3 - base) / math.max(reach - base, 0.01), 0.5, 1)
	end
	local cf = b * CFrame.lookAt(at, at + dir.Unit) * CFrame.Angles(0, 0, roll)
	block(m, "Leaf", V(wid, 0.06, len), cf * CFrame.new(0, 0, -len / 2), color, "Foliage", nil, "Studs")
end
-- n alternate leaves along the outer part of a polyline (from fraction `first`); the last one is a tip leaf.
local leafCount = 0
local function leaves(m, b, pts, n, len, wid, rise, first)
	for i = 1, n do
		leafCount += 1
		local tip = i == n
		local p, along_ = along(pts, if tip then 1 else first + (1 - first) * (i - 1) / math.max(1, n - 1))
		local side = if i % 2 == 0 then 1 else -1
		local perp = along_:Cross(Vector3.yAxis)
		perp = (if perp.Magnitude < 0.01 then Vector3.xAxis else perp.Unit) * side
		local out = V(p.X, 0, p.Z)
		out = if out.Magnitude > 0.05 then out.Unit else perp
		-- Leaves spread nearly level (alternating a little up / down); a tip leaf follows its shoot but never stands up.
		local flat = V(along_.X, 0, along_.Z)
		local h = if tip then flat + out * 0.6 else perp * 0.8 + out * 0.6 + flat * 0.3
		h = if h.Magnitude > 0.01 then h.Unit else out
		local pitch = if tip then rise + 0.25 else rise + (if leafCount % 2 == 0 then 0.28 else -0.16)
		local scale = 0.88 + 0.12 * ((leafCount * 37) % 7) / 6
		leaf(m, b, p, h + V(0, pitch, 0), len * scale, wid * scale, LEAVES[leafCount % 3 + 1], side * 0.22)
	end
end
-- A hanging bunch: stalk from node to `at`, then n two-Part berries (octagonal read), one crown facing outward.
-- unripe[i] = 1 (pale green) or 2 (blush) for the few berries that are not blue yet.
local OFFSETS = { V(0, 0, 0), V(0.34, -0.10, 0.06), V(-0.32, -0.08, 0.10), V(0.06, -0.30, 0.30), V(-0.12, -0.34, -0.18), V(0.28, -0.38, -0.14) }
local function bunch(m, b, node, at, n, d, unripe, slot)
	rod(m, b, node, at, 0.07, TWIG, "Fruit", slot)
	local out = V(at.X, 0, at.Z)
	local yaw = if out.Magnitude > 0.05 then math.atan2(out.X, out.Z) else 0
	local frame = CFrame.new(at) * CFrame.Angles(0, yaw, 0)
	for i = 1, n do
		local p = frame * (OFFSETS[i] * (d / 0.38))
		local kind = unripe[i]
		local body = if kind == 1 then UNRIPE elseif kind == 2 then BLUSH else BERRY
		local facet = if kind then body:Lerp(Color3.new(1, 1, 1), 0.18) else BLOOM
		local cf = b * CFrame.new(p) * CFrame.Angles(0, yaw + i * 0.7, 0)
		block(m, "Berry", V(d, d * 0.9, d), cf, body, "Fruit", slot)
		block(m, "BerryBloom", V(d * 0.84, d * 0.74, d * 0.84), cf * CFrame.Angles(0, math.pi / 4, 0), facet, "Fruit", slot)
	end
	local front = frame * (OFFSETS[math.min(4, n)] * (d / 0.38))
	local outward = frame.LookVector * -1 -- frame's +Z
	local at2 = front + outward * d * 0.55 - V(0, d * 0.10, 0)
	block(m, "Crown", V(d * 0.42, d * 0.42, d * 0.14), b * CFrame.lookAt(at2, at2 + outward), CROWN, "Fruit", slot)
end
local function hang(node, outBy, drop)
	local out = V(node.X, 0, node.Z)
	out = if out.Magnitude > 0.05 then out.Unit else Vector3.zAxis
	return node + out * outBy - V(0, drop, 0)
end

local studies = {
	-- A: the photo's round highbush. Five canes fan into a leafy dome; five bunches hang at its skin, mostly blue.
	{ name = "A_RoundHighbush", build = function(m, b)
		local canes = { { 0.25, 3.95, 1.20 }, { 1.45, 3.55, 1.35 }, { 2.75, 4.15, 1.05 }, { 3.95, 3.65, 1.30 }, { 5.15, 3.85, 1.25 } }
		for _, c in canes do
			local t, h, r = c[1], c[2], c[3]
			c.p = { pt(t, 0.10, 0), pt(t + 0.10, 0.55, h * 0.42), pt(t + 0.18, r, h) }
			c.tw = { c.p[2], pt(t - 0.45, 1.45, h * 0.74) }
			polyline(m, b, c.p, 0.18, 0.12, CANE)
			polyline(m, b, c.tw, 0.09, 0.09, TWIG)
		end
		for _, c in canes do
			leaves(m, b, c.p, 6, 1.06, 0.66, 0.30, 0.35)
			leaves(m, b, c.tw, 3, 1.00, 0.62, 0.20, 0.30)
		end
		local function caneAt(i, t) return (along(canes[i].p, t)) end
		bunch(m, b, canes[1].tw[2], hang(canes[1].tw[2], 0.05, 0.42), 5, 0.38, {}, 1)
		bunch(m, b, caneAt(1, 0.72), hang(caneAt(1, 0.72), 0.32, 0.38), 5, 0.38, { [5] = 1 }, 2)
		bunch(m, b, caneAt(5, 0.72), hang(caneAt(5, 0.72), 0.32, 0.38), 5, 0.38, {}, 3)
		bunch(m, b, canes[2].tw[2], hang(canes[2].tw[2], 0.05, 0.42), 5, 0.38, { [3] = 2, [5] = 1 }, 4)
		bunch(m, b, canes[5].tw[2], hang(canes[5].tw[2], 0.05, 0.42), 5, 0.38, {}, 5)
	end },
	-- B: the life-cycle illustration's tall open vase. Three canes lean outward, reddish twigs end in leaf tufts,
	-- five bigger six-berry bunches hang in the open gaps between them.
	{ name = "B_TallVase", build = function(m, b)
		local canes = { { 5.55, 5.05, 1.35 }, { 0.95, 4.55, 1.30 }, { 3.15, 4.85, 1.20 } }
		for _, c in canes do
			local t, h, r = c[1], c[2], c[3]
			c.p = { pt(t, 0.10, 0), pt(t, 0.35, h * 0.35), pt(t + 0.08, r * 0.62, h * 0.70), pt(t + 0.14, r, h) }
			c.tw = {
				{ c.p[3], pt(t + 0.70, 1.45, h * 0.80) },
				{ c.p[3], pt(t - 0.70, 1.45, h * 0.76) },
			}
			polyline(m, b, c.p, 0.20, 0.12, CANE)
			polyline(m, b, c.tw[1], 0.09, 0.09, TWIG)
			polyline(m, b, c.tw[2], 0.09, 0.09, TWIG)
		end
		for _, c in canes do
			leaves(m, b, c.p, 5, 1.06, 0.66, 0.32, 0.62)
			leaves(m, b, c.tw[1], 4, 1.00, 0.62, 0.28, 0.35)
			leaves(m, b, c.tw[2], 4, 1.00, 0.62, 0.28, 0.35)
		end
		bunch(m, b, canes[1].tw[1][2], hang(canes[1].tw[1][2], -0.10, 0.50), 6, 0.42, {}, 1)
		bunch(m, b, canes[1].tw[2][2], hang(canes[1].tw[2][2], -0.10, 0.50), 6, 0.42, { [6] = 1 }, 2)
		bunch(m, b, canes[2].tw[1][2], hang(canes[2].tw[1][2], -0.10, 0.50), 6, 0.42, { [5] = 2 }, 3)
		bunch(m, b, canes[2].tw[2][2], hang(canes[2].tw[2][2], -0.10, 0.50), 6, 0.42, {}, 4)
		bunch(m, b, canes[3].tw[2][2], hang(canes[3].tw[2][2], -0.10, 0.50), 6, 0.42, { [3] = 1 }, 5)
	end },
	-- C: a compact lowbush mound. Six short canes and spreading twigs under flat leaves; seven bunches of big berries
	-- sit on top, the strongest blue from the field camera.
	{ name = "C_CompactMound", build = function(m, b)
		local canes = {}
		local heights = { 2.10, 1.90, 2.25, 1.80, 2.00, 1.95 }
		for k = 1, 6 do
			local t, h = (k - 1) * math.pi / 3 + 0.30, heights[k]
			local c = { t = t }
			c.p = { pt(t, 0.12, 0), pt(t + 0.12, 1.15, h) }
			c.tw = { (c.p[1] + c.p[2]) / 2, pt(t - 0.45, 1.45, h * 0.62) }
			polyline(m, b, c.p, 0.16, 0.16, CANE)
			polyline(m, b, c.tw, 0.09, 0.09, TWIG)
			canes[k] = c
		end
		for _, c in canes do
			leaves(m, b, c.p, 4, 0.98, 0.62, 0.10, 0.35)
			leaves(m, b, c.tw, 3, 0.94, 0.58, 0.05, 0.30)
		end
		local function sit(i) local top = canes[i].p[2]; return top, hang(top, 0.10, -0.28) end
		local n1, a1 = sit(1); bunch(m, b, n1, a1, 4, 0.46, {}, 1)
		local n2, a2 = sit(2); bunch(m, b, n2, a2, 4, 0.46, { [4] = 1 }, 2)
		local n3, a3 = sit(3); bunch(m, b, n3, a3, 4, 0.46, {}, 3)
		local n5, a5 = sit(5); bunch(m, b, n5, a5, 4, 0.46, { [2] = 2 }, 4)
		local n6, a6 = sit(6); bunch(m, b, n6, a6, 4, 0.46, {}, 5)
		bunch(m, b, canes[1].tw[2], hang(canes[1].tw[2], 0.05, 0.10), 4, 0.46, {}, 6)
		bunch(m, b, canes[6].tw[2], hang(canes[6].tw[2], 0.05, 0.10), 4, 0.46, { [3] = 1 }, 7)
	end },
}
local y0 = 500
block(folder, "GrassContext", V(24, 0.5, 9), CFrame.new(-1, y0 - 0.45, 0), C(103, 149, 75))
local counts = {}
for i, s in studies do
	local base = CFrame.new((i - 2) * 6.5, y0, 0)
	block(folder, "Soil_" .. i, V(5.5, 0.30, 5.5), base * CFrame.new(0, -0.15, 0), C(88, 66, 48), nil, nil, "Studs")
	local m = Instance.new("Model")
	m.Name = s.name
	s.build(m, base)
	local radius, top, bottom, berries = 0, 0, math.huge, 0
	for _, p in m:GetChildren() do
		if p.Name == "Berry" then berries += 1 end
		for x = -1, 1, 2 do for y = -1, 1, 2 do for z = -1, 1, 2 do
			local a = base:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size * V(x, y, z) / 2))
			radius = math.max(radius, V(a.X, 0, a.Z).Magnitude)
			top = math.max(top, a.Y)
			if p:GetAttribute("PlantRole") == "Fruit" and p.Name ~= "Stem" then bottom = math.min(bottom, a.Y) end
		end end end
	end
	counts[s.name] = { parts = #m:GetChildren(), height = math.floor(top * 100) / 100, radius = math.floor(radius * 100) / 100,
		fruitClearance = math.floor(bottom * 100) / 100, berries = berries }
	assert(radius <= 2.4, "Study exceeds field radius: " .. s.name .. " " .. radius)
	assert(#m:GetChildren() <= 130, "Study exceeds budget: " .. s.name .. " " .. #m:GetChildren())
	m.Parent = folder
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
