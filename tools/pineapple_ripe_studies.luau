-- CG21a: disposable static mature pineapple studies, Studio Edit. No scripts, remotes or saved-data edits.
-- A = classic ground rosette (fruit in the heart of the rosette), B = tall stalk (fruit lifted above an upright fountain),
-- C = mother plant with a side sucker and a slip under the fruit.
-- Builds workspace.PineappleRipeStudies in the sky; Destroy it after review and set the Edit camera back to Fixed.
assert(game:GetService("RunService"):IsStudio(), "Studio only")
assert(game.PlaceId == 73033440513091, "Wrong place")
assert(not workspace:FindFirstChild("PineappleRipeStudies"), "Remove previous study first")
local Kit = require(game.ReplicatedStorage.PlantKit)
local V, C = Vector3.new, Color3.fromRGB
local folder = Instance.new("Folder")
folder.Name = "PineappleRipeStudies"
folder:SetAttribute("OriginalCamera", workspace.CurrentCamera.CFrame)
folder:SetAttribute("OriginalFocus", workspace.CurrentCamera.Focus)

local LEAF = {C(34, 102, 58), C(50, 124, 66)} -- glossy dark rosette strap leaves
local CROWN = {C(86, 148, 118), C(110, 168, 124)} -- blue-green crown
local HUB, STALK = C(150, 170, 104), C(112, 138, 66)
local EYE_LOW, EYE_HIGH = C(236, 158, 36), C(226, 196, 70) -- ripe from the base up: orange-gold to yellow
local EYE_ALT = C(250, 194, 64)
local CORE, SPIKE = C(120, 86, 34), C(112, 120, 44)
local SOIL = C(88, 66, 48)

local function block(m, name, size, cf, color, role, slot, class, variant)
	return Kit.proxyPart(m, name, size, cf, color, variant or "StudsSmall", role, slot, class)
end
local function rod(m, b, name, a, z, w, color, role)
	return Kit.proxyRod(m, b, name, a, z, w, color, role or "Structure")
end
-- Flat strap blade between two soil-space points.
local function strap(m, b, name, a, z, w, color, role, roll)
	local d = z - a
	if d.Magnitude < 0.001 then return end
	return block(m, name, V(w, 0.085, d.Magnitude + 0.06), b * CFrame.lookAt((a + z) / 2, z) * CFrame.Angles(0, 0, roll or 0), color, role or "Foliage", nil, nil, "Studs")
end

-- One rosette leaf: three strap segments rising from the hub, arching out and drooping at the tip.
local function rosetteLeaf(m, b, c, phi, L, H, droop, width, tone, i)
	local d = V(math.cos(phi), 0, math.sin(phi))
	local function pt(r, h) return c + d * r + V(0, h, 0) end
	local p = {pt(0.18, 0.12), pt(0.18 + 0.34 * L, 0.12 + 0.50 * H), pt(0.18 + 0.68 * L, 0.12 + H), pt(0.18 + L, 0.12 + H * droop)}
	local w = {width, width * 0.88, width * 0.62}
	local roll = if i % 2 == 0 then 0.5 else -0.5 -- tilt the blade about its axis so it shows its face from the side
	for s = 1, 3 do strap(m, b, "Leaf" .. i .. "_" .. s, p[s], p[s + 1], w[s], tone, nil, roll) end
end
local function rosette(m, b, c, n, L, H, droop, width, yaw0)
	block(m, "Hub", V(0.8, 0.5, 0.8), b * CFrame.new(c + V(0, 0.25, 0)) * CFrame.Angles(0, yaw0, 0), HUB, "Structure")
	for j = 1, n do
		local phi = yaw0 + j * 2.399963229728653
		local k = ((j * 37) % 7) / 6 -- 0..1, unequal lengths
		rosetteLeaf(m, b, c, phi, L * (0.78 + 0.22 * k), H * (0.8 + 0.2 * (1 - k)), droop * (0.7 + 0.5 * k), width, LEAF[j % 2 + 1], j)
	end
end

-- Diamond-eyed barrel fruit standing on its base point `at`: tiers of tilted eye blocks over a core, bracts on a checker.
local PROFILE = {0.70, 0.88, 0.98, 1.0, 0.96, 0.86, 0.68}
local function fruit(m, b, at, H, R, N, yaw)
	local T = #PROFILE
	local th = H / T
	for k = 0, 1 do
		local cy = if k == 0 then H * 0.30 else H * 0.72
		local diam = (if k == 0 then 1.55 else 1.45) * R
		local cyl = block(m, "FruitCore", V(H * 0.46, diam, diam), b * CFrame.new(at + V(0, cy, 0)) * CFrame.Angles(0, 0, math.pi / 2), CORE, "Fruit", 1)
		cyl.Shape = Enum.PartType.Cylinder
	end
	-- Top cap closing the barrel under the crown (green-gold shoulder where the crown starts).
	local cap = block(m, "FruitCap", V(0.30, R * 1.45, R * 1.45), b * CFrame.new(at + V(0, H - 0.08, 0)) * CFrame.Angles(0, 0, math.pi / 2), C(150, 160, 70), "Fruit", 1)
	cap.Shape = Enum.PartType.Cylinder
	for t = 1, T do
		local r = R * PROFILE[t]
		local rUp, rDn = R * (PROFILE[math.min(t + 1, T)]), R * (PROFILE[math.max(t - 1, 1)])
		local slope = (rUp - rDn) / (2 * th)
		local colour = EYE_LOW:Lerp(EYE_HIGH, (t - 1) / (T - 1))
		for i = 0, N - 1 do
			local theta = yaw + (i + (t % 2) * 0.5) * 2 * math.pi / N
			local out = V(math.cos(theta), 0, math.sin(theta))
			local pos = at + V(0, th * (t - 0.5), 0) + out * r
			local n = (out - V(0, slope, 0)).Unit
			local eye = b * CFrame.lookAt(pos, pos + n)
			local w = 2 * math.pi * r / N * 0.98
			block(m, "Eye", V(w, th * 0.98, 0.30), eye, if (i + t) % 2 == 0 then colour else EYE_ALT:Lerp(colour, 0.5), "Fruit", 1)
			if (i + t) % 2 == 0 then
				block(m, "Bract", V(0.11, 0.20, 0.10), eye * CFrame.new(0, th * 0.30, -0.19) * CFrame.Angles(-0.45, 0, 0), SPIKE, "Fruit", 1)
			end
		end
	end
end

-- Crown: three rings of upright blue-green blades (outer, middle, central), each two segments with a bent tip.
local function crown(m, b, at, scale, yaw)
	local rings = {{6, 0.62, 1.05, 0.40}, {5, 0.36, 1.30, 0.36}, {3, 0.12, 1.05, 0.30}}
	local idx = 0
	for ri, g in rings do
		for j = 1, g[1] do
			idx += 1
			local phi = yaw + (j + ri * 0.37) * 2 * math.pi / g[1]
			local d = V(math.cos(phi), 0, math.sin(phi))
			local len = g[3] * 1.15 * scale * (0.88 + 0.12 * ((idx * 5) % 3))
			local lean = g[2]
			local mid = at + d * (math.sin(lean) * len * 0.55) + V(0, math.cos(lean) * len * 0.55, 0)
			local tip = mid + d * (math.sin(lean + 0.30) * len * 0.50) + V(0, math.cos(lean + 0.30) * len * 0.50, 0)
			local tone = CROWN[idx % 2 + 1]
			local roll = if idx % 2 == 0 then 0.45 else -0.45
			strap(m, b, "CrownBlade" .. idx .. "a", at, mid, g[4] * 1.25 * scale, tone, nil, roll)
			strap(m, b, "CrownBlade" .. idx .. "b", mid, tip, g[4] * 1.25 * scale * 0.62, tone, nil, roll)
		end
	end
end

local studies = {
	{ name = "A_ClassicRosette", build = function(m, b)
		local c = V(0, 0, 0)
		rosette(m, b, c, 13, 2.0, 1.9, 0.30, 0.85, 0.4)
		local H, R = 2.30, 0.98
		rod(m, b, "FruitStalk", c + V(0, 0.4, 0), c + V(0, 1.15, 0), 0.34, STALK)
		fruit(m, b, c + V(0, 1.10, 0), H, R, 8, 0.2)
		crown(m, b, c + V(0, 1.10 + H - 0.05, 0), 1.0, 0.5)
	end },
	{ name = "B_TallStalk", build = function(m, b)
		local c = V(0, 0, 0)
		rosette(m, b, c, 12, 1.75, 2.45, 0.55, 0.72, 1.1)
		local base, H, R = 2.55, 2.15, 0.90
		rod(m, b, "FruitStalk1", c + V(0, 0.4, 0), c + V(0.04, 1.5, 0.02), 0.36, STALK)
		rod(m, b, "FruitStalk2", c + V(0.04, 1.5, 0.02), c + V(0.02, base + 0.1, 0.0), 0.32, STALK)
		fruit(m, b, c + V(0.02, base, 0), H, R, 8, 0.1)
		crown(m, b, c + V(0.02, base + H - 0.05, 0), 1.0, 0.2)
	end },
	{ name = "C_MotherAndSucker", build = function(m, b)
		local c = V(-0.55, 0, 0.1)
		rosette(m, b, c, 10, 1.50, 1.6, 0.25, 0.75, 0.7)
		local H, R = 2.0, 0.88
		rod(m, b, "FruitStalk", c + V(0, 0.4, 0), c + V(0, 1.1, 0), 0.32, STALK)
		fruit(m, b, c + V(0, 1.05, 0), H, R, 8, 0.0)
		crown(m, b, c + V(0, 1.05 + H - 0.05, 0), 0.92, 1.0)
		-- Side sucker: a small second rosette that will carry the next crop.
		local s = V(1.15, 0, 0.25)
		rod(m, b, "SuckerShoot", c + V(0.2, 0.3, 0.1), s + V(0, 0.4, 0), 0.22, STALK)
		rosette(m, b, s + V(0, 0.15, 0), 7, 0.85, 1.0, 0.25, 0.5, 2.0)
		-- Slip: a small leafy tuft growing from the stalk below the fruit.
		local sp = c + V(0.52, 1.0, -0.2)
		rod(m, b, "SlipStem", c + V(0.1, 0.9, -0.05), sp, 0.13, STALK)
		for j = 1, 4 do
			local phi = j * 1.6
			local d = V(math.cos(phi) * 0.35, 0.55, math.sin(phi) * 0.35)
			strap(m, b, "SlipLeaf" .. j, sp, sp + d * 1.0, 0.20, CROWN[j % 2 + 1])
		end
	end },
}

local y0 = 1500
block(folder, "GrassContext", V(26, 0.50, 10), CFrame.new(-1, y0 - 0.45, 0), C(103, 149, 75))
local counts = {}
for i, s in studies do
	local base = CFrame.new((i - 2) * 6.5, y0, 0)
	block(folder, "Soil" .. i, V(5.5, 0.30, 5.5), base * CFrame.new(0, -0.15, 0), SOIL, nil, nil, nil, "Studs")
	local m = Instance.new("Model")
	m.Name = s.name
	s.build(m, base)
	local radius, top = 0, 0
	for _, p in m:GetChildren() do
		for x = -1, 1, 2 do for y = -1, 1, 2 do for z = -1, 1, 2 do
			local v = base:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size * V(x, y, z) / 2))
			radius = math.max(radius, V(v.X, 0, v.Z).Magnitude)
			top = math.max(top, v.Y)
		end end end
	end
	counts[s.name] = {parts = #m:GetChildren(), height = math.round(top * 100) / 100, radius = math.round(radius * 100) / 100}
	m.Parent = folder
end
local description = Instance.new("HumanoidDescription")
local ok, avatar = pcall(function() return game.Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15) end)
description:Destroy()
if not ok then folder:Destroy(); error("Avatar reference failed: " .. tostring(avatar)) end
avatar.Name = "ReferenceAvatar"
avatar:PivotTo(CFrame.new(-10.45, y0 + 3, 0.35) * CFrame.Angles(0, math.pi, 0))
local minY = math.huge
for _, p in avatar:GetDescendants() do if p:IsA("BasePart") then
	minY = math.min(minY, p.Position.Y - p.Size.Y / 2)
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
end end
avatar:PivotTo(avatar:GetPivot() + V(0, y0 - minY, 0))
avatar.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
avatar.Parent = folder
counts.avatarHeight = math.round(avatar:GetExtentsSize().Y * 100) / 100
folder.Parent = workspace
return game.HttpService:JSONEncode(counts)
