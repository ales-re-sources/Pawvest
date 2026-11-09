-- CG7a: run in Studio playtest Client context. Display only; no field requests.
-- Squares 8/9/10 = A/B/C. Stop Play to remove.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsClient(), "Studio client only")
local player = game.Players.LocalPlayer
local PlotView = require(player.PlayerScripts:WaitForChild("PlotView"))
local GardenConfig = require(game.ReplicatedStorage.GardenConfig)
local CropConfig = require(game.ReplicatedStorage.CropConfig)
local garden = assert(workspace:FindFirstChild("GardenView"), "Wait for GardenView")
assert(not workspace:FindFirstChild("LettuceRipeStudies"), "Remove previous studies first")
local slot = 13
while GardenConfig.PlotCFrame(slot) and garden:FindFirstChild(string.format("Slot_%02d", slot)) do slot += 1 end
assert(GardenConfig.PlotCFrame(slot), "No free study slot")
local V = Vector3.new
local C = Color3.fromRGB
local dark = C(58, 126, 52)
local mid = C(92, 158, 60)
local light = C(140, 190, 78)
local pale = C(196, 222, 128)
local cream = C(232, 238, 190)
local rose = C(168, 78, 84)
local rosy = C(116, 138, 62)

local function block(model, name, size, cf, color, role)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Material, p.MaterialVariant = Enum.Material.Plastic, "StudsSmall"
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p:SetAttribute("PlantRole", role or "Foliage")
	p.Parent = model
	return p
end

-- A leaf is three connected plates in the local YZ plane of its frame (it runs along +Z):
-- elevation starts at `elev` and falls by `bend` per plate (negative bend curls the tip inward and up).
-- `fracs`/`widths` give a spatulate outline; `colors[i]` tints plate i; `frill` adds two ruffle plates at the tip.
local FRACS = { 0.34, 0.40, 0.26 }
local WIDTH = { 0.55, 1.00, 0.72 }
local function leaf(model, base, s)
	local frame = base * CFrame.new(s.at) * CFrame.Angles(0, s.yaw, 0)
	local pos = V(0, 0, 0)
	local lastCF, lastLen, lastDir
	for i = 1, 3 do
		local e = s.elev - s.bend * (i - 1)
		local sn, cs = math.sin(e), math.cos(e)
		local dir = V(0, sn, cs)
		local len = s.len * FRACS[i]
		local nxt = pos + dir * len
		local cf = frame * CFrame.fromMatrix((pos + nxt) / 2, V(-1, 0, 0), V(0, cs, -sn), V(0, -sn, -cs))
			* CFrame.Angles(0, 0, s.roll or 0)
		block(model, "Leaf", V(s.width * WIDTH[i], 0.09, len + 0.03), cf, s.colors[i])
		lastCF, lastLen, lastDir = cf, len, dir
		pos = nxt
	end
	if s.frill then
		for _, side in { -1, 1 } do
			local w = s.width * 0.42
			local cf = lastCF * CFrame.new(side * s.width * 0.42, 0.02, -lastLen * 0.42) * CFrame.Angles(0, 0, side * 0.6)
			block(model, "Frill", V(w, 0.08, lastLen * 0.8), cf, s.colors[3])
		end
	end
end

-- Deterministic small differences so a ring of leaves does not read as a copy.
local function ring(model, base, n, spec)
	for i = 1, n do
		local j = (i * 37 + (spec.salt or 0)) % 5 - 2
		local k = (i * 53 + (spec.salt or 0)) % 7
		local yaw = (i - 1) * (math.pi * 2 / n) + (spec.turn or 0) + j * 0.06
		local r = spec.radius or 0.15
		leaf(model, base, {
			at = V(math.sin(yaw) * r, spec.rise or 0.08, math.cos(yaw) * r),
			yaw = yaw,
			elev = spec.elev + j * 0.05,
			bend = spec.bend,
			len = spec.len * (0.92 + k * 0.025),
			width = spec.width,
			roll = (spec.roll or 0) * (if i % 2 == 0 then 1 else -1),
			frill = spec.frill,
			colors = if type(spec.colors[1]) == "table" then spec.colors[(i - 1) % #spec.colors + 1] else spec.colors,
		})
	end
end

local studies = {
	{ name = "A - Crisp head", draw = function(model, base)
		-- Wrapper leaves open outward; inner leaves cup into a firm pale head.
		ring(model, base, 7, { elev = 0.6, bend = 0.42, len = 1.8, width = 1.05, radius = 0.2, rise = 0.1, roll = 0.14, frill = true, turn = 0.2,
			colors = { { cream, dark, dark }, { cream, mid, dark } } })
		ring(model, base, 6, { elev = 0.95, bend = 0.12, len = 1.5, width = 0.95, radius = 0.14, rise = 0.2, turn = 0.5, salt = 3,
			colors = { { pale, mid, mid }, { pale, light, mid } } })
		ring(model, base, 5, { elev = 1.15, bend = -0.35, len = 1.25, width = 0.9, radius = 0.2, rise = 0.3, turn = 0.1, salt = 5,
			colors = { pale, light, pale } })
		block(model, "HeadCore", V(0.75, 1.0, 0.75), base * CFrame.new(0, 0.95, 0), cream)
		block(model, "HeadCore", V(0.75, 0.9, 0.75), base * CFrame.new(0, 0.95, 0) * CFrame.Angles(0, math.pi / 4, 0), pale)
	end },
	{ name = "B - Romaine", draw = function(model, base)
		-- Upright spoon leaves with white ribs around a tight pale heart.
		ring(model, base, 6, { elev = 1.1, bend = 0.4, len = 2.4, width = 1.1, radius = 0.12, rise = 0.06, roll = 0.12, frill = true, turn = 0.3,
			colors = { { cream, mid, dark }, { cream, dark, dark } } })
		ring(model, base, 5, { elev = 1.28, bend = 0.3, len = 2.8, width = 1.0, radius = 0.1, rise = 0.12, turn = 0.9, salt = 2,
			colors = { { cream, light, mid }, { cream, mid, mid } } })
		ring(model, base, 4, { elev = 1.4, bend = 0.12, len = 3.0, width = 0.85, radius = 0.08, rise = 0.2, turn = 0.2, salt = 4,
			colors = { { cream, pale, light } } })
		block(model, "Heart", V(0.7, 1.5, 0.7), base * CFrame.new(0, 0.9, 0), cream)
	end },
	{ name = "C - Loose-leaf frill", draw = function(model, base)
		-- A wide frilled rosette with rose-tinted tips; no head.
		ring(model, base, 9, { elev = 0.4, bend = 0.25, len = 1.8, width = 1.15, radius = 0.15, rise = 0.08, roll = 0.2, frill = true, turn = 0.1,
			colors = { { light, mid, rose }, { light, rosy, rose } } })
		ring(model, base, 7, { elev = 0.95, bend = 0.15, len = 1.25, width = 0.9, radius = 0.1, rise = 0.15, roll = 0.15, turn = 0.4, salt = 3,
			colors = { { pale, light, pale }, { pale, mid, light } } })
		block(model, "Tuft", V(0.45, 0.7, 0.45), base * CFrame.new(0, 0.5, 0), pale)
	end },
}

local function bounds(model, base)
	local radius, height = 0, 0
	for _, p in model:GetChildren() do
		local h = p.Size / 2
		for sx = -1, 1, 2 do for sy = -1, 1, 2 do for sz = -1, 1, 2 do
			local l = base:PointToObjectSpace((p.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position)
			radius = math.max(radius, math.sqrt(l.X * l.X + l.Z * l.Z))
			height = math.max(height, l.Y)
		end end end
	end
	return math.round(radius * 100) / 100, math.round(height * 100) / 100
end

local folder = Instance.new("Folder")
folder.Name = "LettuceRipeStudies"
local view = PlotView.new(slot, folder)
local cells = table.create(CropConfig.MaxSquares, "#0")
for n = 1, 24 do cells[n] = ".0" end
cells[7] = "a3"
view:SetState({ ownerId = player.UserId, name = player.DisplayName, incCount = 1, eggs = {}, field = { crops = table.concat(cells),
	plants = { ["7"] = { n = 1, startAt = 0, readyAt = 0, size = 1 } }, pets = { "Cat:3:review:11:1:1" } } })
view:SetDetail("full")
while view:Step(os.clock() + 0.006) do task.wait() end
local report = {}
for i, study in studies do
	local base = view:SquareCFrame(7 + i)
	local model = Instance.new("Model")
	model.Name = study.name
	model:SetAttribute("StaticRipeStudy", true)
	study.draw(model, base)
	local r, h = bounds(model, base)
	report[study.name] = { parts = #model:GetChildren(), radius = r, height = h }
	assert(#model:GetChildren() <= 100, "Art study part budget exceeded")
	model.Parent = folder
end
folder:SetAttribute("ReviewSlot", slot)
folder.Parent = workspace
view:ShowSelect(9)
return game.HttpService:JSONEncode({ folder = folder:GetFullName(), slot = slot, studies = report })
