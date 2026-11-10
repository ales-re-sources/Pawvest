-- CG11a: run in Studio playtest Client context. Display only; no field requests, no saved-state writes.
-- Squares 8/9/10/11 = A quill fan / B bulb-forward / C flowering allium / D (A in copper-yellow). Square 7 is a Potato for scale.
-- Stop Play to remove. Ripe poses only: growth, fold timing and Part budget are decided after a silhouette is chosen.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsClient(), "Studio client only")
local player = game.Players.LocalPlayer
local PlotView = require(player.PlayerScripts:WaitForChild("PlotView"))
local Kit = require(game.ReplicatedStorage.PlantKit)
local GardenConfig = require(game.ReplicatedStorage.GardenConfig)
local CropConfig = require(game.ReplicatedStorage.CropConfig)
local garden = assert(workspace:FindFirstChild("GardenView"), "Wait for GardenView")
assert(not workspace:FindFirstChild("OnionRipeStudies"), "Remove previous studies first")
local slot = 13
while GardenConfig.PlotCFrame(slot) and garden:FindFirstChild(string.format("Slot_%02d", slot)) do slot += 1 end
assert(GardenConfig.PlotCFrame(slot), "No free study slot")
local V, C = Vector3.new, Color3.fromRGB

local sheath = C(214, 226, 170)
local body = C(70, 135, 110)
local bodyLight = C(96, 156, 104)
local tip = C(176, 190, 96)
local straw = C(222, 200, 140)
local skins = {
	red = { skin = C(150, 46, 96), shoulder = C(188, 92, 132), seam = C(222, 168, 182) },
	copper = { skin = C(184, 124, 58), shoulder = C(214, 166, 86), seam = C(236, 206, 140) },
}

local function block(model, name, size, cf, color, role)
	return Kit.proxyPart(model, name, size, cf, color, "StudsSmall", role or "Foliage")
end

-- Faceted bulb: each layer is two boxes 45 degrees apart (an octagon seen from above).
local function bulb(model, base, cy, W, H, c)
	local layers = {
		{ y = -0.30, h = 0.34, w = 0.62, color = c.skin },
		{ y = 0.00, h = 0.42, w = 1.00, color = c.skin },
		{ y = 0.27, h = 0.30, w = 0.80, color = c.shoulder },
	}
	for _, l in layers do
		for k = 0, 1 do
			local w = l.w * W * (if k == 1 then 0.86 else 1) -- a smaller second box keeps the union round, not a star
			block(model, "Bulb", V(w, l.h * H, w), base * CFrame.new(0, cy + l.y * H, 0) * CFrame.Angles(0, k * math.pi / 4, 0), l.color, "Bulb")
		end
	end
	-- Two paper seams where the scales overlap.
	block(model, "Seam", V(W * 1.03, H * 0.05, W * 0.2), base * CFrame.new(0, cy + 0.14 * H, 0), c.seam, "Bulb")
	block(model, "Seam", V(W * 0.2, H * 0.05, W * 1.03), base * CFrame.new(0, cy - 0.12 * H, 0), c.seam, "Bulb")
	local top = cy + 0.27 * H + 0.15 * H
	local neckH = 0.34 * H
	block(model, "Neck", V(0.3 * W, neckH, 0.3 * W), base * CFrame.new(0, top + neckH / 2 - 0.05, 0), straw, "Bulb")
	return top + neckH - 0.08
end

-- A quill is three connected rods (pale sheath, green body, straw tip); `leans` are radians from vertical per rod.
local function quill(model, base, o)
	local pos = o.at
	local out = V(math.sin(o.yaw), 0, math.cos(o.yaw))
	local fracs, widths, colors = { 0.22, 0.5, 0.28 }, { 0.27, 0.23, 0.15 }, { sheath, o.color or body, tip }
	for i = 1, 3 do
		local dir = out * math.sin(o.leans[i]) + V(0, math.cos(o.leans[i]), 0)
		local nxt = pos + dir * (o.len * fracs[i])
		local a, b = base:PointToWorldSpace(pos), base:PointToWorldSpace(nxt)
		local w = widths[i] * (o.width or 1)
		block(model, "Quill", V(w, w, (b - a).Magnitude + 0.04), Kit.axis(a, b), colors[i])
		pos = nxt
	end
end

local function fan(model, base, topY, spec)
	for i = 1, spec.n do
		local j = (i * 37 + (spec.salt or 0)) % 5 - 2
		local k = (i * 53 + (spec.salt or 0)) % 7
		local yaw = (i - 1) * (math.pi * 2 / spec.n) + (spec.turn or 0) + j * 0.07
		local lean = spec.lean * (0.55 + k * 0.1)
		local folded = spec.fold and i % 3 == 1
		local l2 = if folded then lean + 0.45 elseif spec.droop then lean + spec.droop else lean * 1.1
		local l3 = if folded then 1.45 elseif spec.droop then lean + spec.droop * 2.2 else lean * 1.5
		quill(model, base, {
			at = V(math.sin(yaw) * 0.1, topY, math.cos(yaw) * 0.1),
			yaw = yaw,
			leans = { lean * 0.6, l2, l3 },
			len = spec.len * (0.82 + k * 0.05),
			width = spec.width,
			color = if i % 2 == 0 then body else bodyLight,
		})
	end
end

local studies = {
	{ name = "A - Quill fan, red", draw = function(model, base)
		local top = bulb(model, base, 0.3, 1.3, 1.4, skins.red)
		fan(model, base, top, { n = 8, lean = 0.34, len = 2.1, fold = true, turn = 0.2 })
	end },
	{ name = "B - Bulb forward", draw = function(model, base)
		local top = bulb(model, base, 0.5, 1.9, 1.9, skins.red)
		fan(model, base, top, { n = 6, lean = 0.5, len = 1.1, droop = 0.55, width = 1.2, turn = 0.5, salt = 3 })
	end },
	{ name = "C - Flowering allium", draw = function(model, base)
		local top = bulb(model, base, 0.3, 1.2, 1.3, skins.red)
		fan(model, base, top, { n = 6, lean = 0.26, len = 1.7, turn = 0.1, salt = 5 })
		local scapeTop = 3.7
		local a, b = base:PointToWorldSpace(V(0, top, 0)), base:PointToWorldSpace(V(0, scapeTop, 0))
		block(model, "Scape", V(0.2, 0.2, (b - a).Magnitude), Kit.axis(a, b), bodyLight)
		block(model, "ScapeSwell", V(0.3, 0.5, 0.3), base * CFrame.new(0, 1.9, 0), body)
		local lilac, white = C(190, 140, 210), C(236, 220, 242)
		for k = 0, 2 do
			block(model, "Umbel", V(1.0, 1.0, 1.0), base * CFrame.new(0, scapeTop + 0.35, 0) * CFrame.Angles(k * 0.5, k * 0.7 + 0.3, k * 0.4), if k == 1 then white else lilac, "Flower")
		end
	end },
	{ name = "D - A copper-yellow", draw = function(model, base)
		local top = bulb(model, base, 0.3, 1.3, 1.4, skins.copper)
		fan(model, base, top, { n = 8, lean = 0.34, len = 2.1, fold = true, turn = 0.2 })
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
folder.Name = "OnionRipeStudies"
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
