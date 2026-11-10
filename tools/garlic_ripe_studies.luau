-- CG12a: run in a Studio playtest's Client context. Disposable art only; no requests or profile writes.
-- A curled scape / B leaf fan / C pointed spathe. Real PlotView soil, pet and selection; Onion is a neighbour.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsClient(), "Studio client only")
local player = game.Players.LocalPlayer
local PlotView = require(player.PlayerScripts:WaitForChild("PlotView"))
local Kit = require(game.ReplicatedStorage.PlantKit)
local GardenConfig = require(game.ReplicatedStorage.GardenConfig)
local CropConfig = require(game.ReplicatedStorage.CropConfig)
local garden = assert(workspace:FindFirstChild("GardenView"), "Wait for GardenView")
assert(not workspace:FindFirstChild("GarlicRipeStudies"), "Remove previous studies first")
local slot = 13
while GardenConfig.PlotCFrame(slot) and garden:FindFirstChild(string.format("Slot_%02d", slot)) do slot += 1 end
assert(GardenConfig.PlotCFrame(slot), "No free study slot")
local V, C = Vector3.new, Color3.fromRGB
local IVORY, CREAM, SHADE = C(237, 230, 208), C(248, 242, 218), C(193, 180, 192)
local SHEATH, GREEN, GREEN_B, STRAW = C(198, 214, 165), C(68, 127, 103), C(90, 151, 114), C(202, 185, 116)

local function block(model, name, size, cf, color, role)
	return Kit.proxyPart(model, name, size, cf, color, "StudsSmall", role)
end

-- Vertical lobes merge into a wrapped head and gathered neck, rather than horizontal onion slabs.
local function head(model, base)
	block(model, "WrappedCore", V(0.95, 1.0, 0.95), base * CFrame.new(0, -0.15, 0), IVORY, "Bulb")
	for i = 1, 6 do
		local yaw = (i - 1) * math.pi / 3 + 0.15
		local lobe = base * CFrame.Angles(0, yaw, 0)
		block(model, "LobeBase_" .. i, V(0.52, 0.48, 0.55), lobe * CFrame.new(0, -0.37, 0.44), IVORY, "Bulb")
		block(model, "LobeBody_" .. i, V(0.58, 0.58, 0.60), lobe * CFrame.new(0, -0.01, 0.50), if i % 3 == 0 then SHADE:Lerp(IVORY, 0.60) else IVORY, "Bulb")
		block(model, "LobeShoulder_" .. i, V(0.44, 0.55, 0.44), lobe * CFrame.new(0, 0.32, 0.35) * CFrame.Angles(-0.35, 0, 0), if i % 2 == 0 then CREAM else IVORY, "Bulb")
	end
	block(model, "GatheredNeck", V(0.34, 0.50, 0.34), base * CFrame.new(0, 0.62, 0), CREAM, "Bulb")
	block(model, "Pseudostem", V(0.21, 1.57, 0.21), base * CFrame.new(0, 1.44, 0), SHEATH:Lerp(GREEN_B, 0.35), "Foliage")
end

local function ribbon(model, base, i, yaw, length, lean, dry)
	local pos = V(0, 0.78 + i * 0.18, 0)
	local outward = V(math.sin(yaw), 0, math.cos(yaw))
	local fractions, widths = {0.38, 0.38, 0.24}, {0.28, 0.40, 0.14}
	for segment = 1, 3 do
		local angle = lean + (segment - 1) * (if dry then 0.33 else 0.15)
		local nextPos = pos + (outward * math.sin(angle) + V(0, math.cos(angle), 0)) * length * fractions[segment]
		-- Explicit blade normal keeps every leaf visibly flat, with width across its fan direction.
		local a, b = base:PointToWorldSpace(pos), base:PointToWorldSpace(nextPos)
		local normal = base:VectorToWorldSpace(outward:Cross(Vector3.yAxis):Cross((nextPos - pos).Unit)).Unit
		local cf = CFrame.lookAt((a + b) / 2, a, normal)
		local color = if dry and segment == 3 then STRAW elseif i % 2 == 0 then GREEN else GREEN_B
		block(model, "Blade_" .. i .. "_" .. segment, V(widths[segment], 0.065, (b - a).Magnitude + 0.025), cf, color, "Foliage")
		pos = nextPos
	end
end

local function foliage(model, base, variant)
	local lengths = {1.85, 2.05, 2.30, 2.40, 2.30, 2.20, 2.15}
	for i, len in lengths do
		-- Alternating blades up the pseudostem, with enough twist to read from multiple sides.
		local yaw = (if i % 2 == 0 then math.pi else 0) + 0.45 + ((i % 3) - 1) * 0.35
		local lean = 0.25 + (7 - i) * 0.080
		ribbon(model, base, i, yaw, len, lean, i <= 2)
	end
end

local function rod(model, base, name, a, b)
	block(model, name, V(0.13, 0.13, (b - a).Magnitude + 0.025), base * Kit.axis(a, b), GREEN_B, "Scape")
end

local function spathe(model, base, at, direction)
	local a = at
	local b = a + direction.Unit * 0.32
	block(model, "ClosedSpathe", V(0.22, 0.18, 0.34), base * Kit.axis(a, b), SHEATH:Lerp(CREAM, 0.55), "Scape")
	local c = b + direction.Unit * 0.25
	block(model, "SpathePoint", V(0.09, 0.08, 0.28), base * Kit.axis(b, c), CREAM, "Scape")
end

local function scape(model, base, variant)
	if variant == "B" then return end
	local start = V(0.02, 0.90, 0.02)
	local mid = V(-0.10, 2.50, 0.02)
	rod(model, base, "ScapeLower", start, mid)
	if variant == "C" then
		local tip = V(-0.18, 4.30, 0.02)
		local bend = V(0.14, 4.58, 0.02)
		rod(model, base, "ScapeUpper", mid, tip)
		rod(model, base, "ScapeBend", tip, bend)
		spathe(model, base, bend, V(0.8, -0.3, 0))
		return
	end
	-- User life-cycle reference: a side curl, then a rising tail carrying a pointed spathe.
	local path = {
		V(-0.30, 3.40, 0.04), V(-0.78, 3.52, 0.04), V(-1.12, 3.24, 0.04),
		V(-1.12, 2.85, 0.04), V(-0.80, 2.62, 0.04), V(-0.42, 2.73, 0.04),
		V(-0.24, 3.09, 0.04), V(0.02, 3.77, 0.04), V(0.28, 4.24, 0.04),
	}
	local prev = mid
	for j, nextPos in path do
		rod(model, base, "Curl_" .. j, prev, nextPos)
		prev = nextPos
	end
	spathe(model, base, prev, V(0.42, 0.9, 0))
end

local function bounds(model, base)
	local radius, height, low = 0, 0, 0
	for _, p in model:GetChildren() do
		assert(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery, "Art intercepts input/physics")
		local h = p.Size / 2
		for sx = -1, 1, 2 do for sy = -1, 1, 2 do for sz = -1, 1, 2 do
			local l = base:PointToObjectSpace((p.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position)
			radius = math.max(radius, Vector2.new(l.X, l.Z).Magnitude)
			height, low = math.max(height, l.Y), math.min(low, l.Y)
		end end end
	end
	return math.round(radius * 100) / 100, math.round(height * 100) / 100, math.round(low * 100) / 100
end

local folder = Instance.new("Folder")
folder.Name = "GarlicRipeStudies"
local view = PlotView.new(slot, folder)
local cells = table.create(CropConfig.MaxSquares, "#0")
for n = 1, 24 do cells[n] = ".0" end
cells[7] = "i3" -- Registered Onion neighbour for silhouette comparison.
view:SetState({ ownerId = player.UserId, name = player.DisplayName, incCount = 1, eggs = {}, field = { crops = table.concat(cells),
	plants = { ["7"] = { n = 1, startAt = 0, readyAt = 0, size = 1 } }, pets = { "Cat:3:review:11:1:1" } } })
view:SetDetail("full")
while view:Step(os.clock() + 0.006) do task.wait() end
local report = {}
for i, variant in {"A", "B", "C"} do
	local base = view:SquareCFrame(7 + i)
	local model = Instance.new("Model")
	model.Name = variant
	model:SetAttribute("StaticRipeStudy", true)
	head(model, base)
	foliage(model, base, variant)
	scape(model, base, variant)
	local r, h, low = bounds(model, base)
	assert(r <= 2.4, "Study exceeds square clearance")
	assert(#model:GetChildren() <= 64, "Study exceeds proposed Part budget")
	report[variant] = {parts = #model:GetChildren(), radius = r, height = h, belowSoil = -low,
		soil = {base.X, base.Y, base.Z}}
	model.Parent = folder
end
folder:SetAttribute("ReviewSlot", slot)
folder.Parent = workspace
view:ShowSelect(8)
local character = player.Character
local hrp = character and character:FindFirstChild("HumanoidRootPart")
if hrp then
	local base = view:SquareCFrame(11)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local stand = (if humanoid then humanoid.HipHeight else 2) + hrp.Size.Y / 2
	character:PivotTo(base * CFrame.new(0, stand, 0))
end
local target = view:SquareCFrame(9).Position + V(0, 1.9, 0)
local offset = view:SquareCFrame(9):VectorToWorldSpace(V(3, 11, 25))
local camera = workspace.CurrentCamera
RunService:BindToRenderStep("GarlicRipeStudyCamera", Enum.RenderPriority.Last.Value + 2, function()
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(target + offset, target)
	camera.FieldOfView = 48
end)
return game.HttpService:JSONEncode({folder = folder:GetFullName(), slot = slot, studies = report})
