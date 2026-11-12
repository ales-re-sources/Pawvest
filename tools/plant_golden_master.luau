-- Plant recipe golden master (docs/PLANT_GROWTH.md → Validate): run via MCP execute_luau in the Edit context before and after a
-- code change that must not change how plants look (PlantKit, a shared helper, a recipe refactor). Equal lines = identical
-- geometry. Builds every registered crop (or ONLY) from fresh module clones (Edit `require` caches modules) at four seed / size
-- cases and six growths (including a step back), then its proxies at stages 1-3 and its ring height, and hashes every Part's
-- name, class, size, CFrame, colour, transparency, reflectance, variant, shadow and PlantRole / FruitSlot, plus fruit slots and
-- particle emitters. Leaves nothing behind. Draft recipes are skipped (not registered); a crop without a recipe prints "none".
local ONLY = nil -- e.g. { "Cucumber", "SweetPotato" } to hash only these crops

local RS = game:GetService("ReplicatedStorage")
local old = RS:FindFirstChild("GoldenTmp")
if old then
	old:Destroy()
end
local folder = Instance.new("Folder")
folder.Name = "GoldenTmp"
for _, m in RS:GetChildren() do
	if m:IsA("ModuleScript") and (m.Name:match("Plant$") or m.Name == "PlantKit" or m.Name == "PlantGrowth") then
		m:Clone().Parent = folder
	end
end
-- PlantGrowth requires script.Parent.CropConfig; a fresh CropConfig clone would wait on Locale, so point at the real one.
local shim = Instance.new("ModuleScript")
shim.Name = "CropConfig"
shim.Source = "return require(game:GetService('ReplicatedStorage').CropConfig)"
shim.Parent = folder
folder.Parent = RS

local M = 4294967296
local function mixn(h, x)
	return (h * 31 + math.floor(x * 10000 + 0.5) % M) % M
end
local function mixs(h, s)
	for i = 1, #s do
		h = (h * 31 + string.byte(s, i)) % M
	end
	return h
end
local function dump(container, h)
	local count = 0
	for _, p in container:GetDescendants() do
		if p:IsA("BasePart") then
			count += 1
			h = mixs(h, p.Name .. p.ClassName .. p.MaterialVariant .. tostring(p.CastShadow) .. p.Color:ToHex())
			for _, v in { p.CFrame:GetComponents() } do
				h = mixn(h, v)
			end
			h = mixn(mixn(mixn(h, p.Size.X), p.Size.Y), p.Size.Z)
			h = mixn(mixn(h, p.Transparency), p.Reflectance)
			h = mixs(h, tostring(p:GetAttribute("PlantRole")) .. tostring(p:GetAttribute("FruitSlot")))
		elseif p:IsA("ParticleEmitter") then
			h = mixs(h, "PE" .. tostring(p.Enabled))
		end
	end
	return h, count
end

local ok, result = pcall(function()
	local Growth = require(folder.PlantGrowth)
	local crops = ONLY
	if not crops then
		crops = {}
		for _, crop in require(RS.CropConfig).Crops do
			table.insert(crops, crop.id)
		end
	end
	local stage = Instance.new("Folder")
	stage.Name = "GoldenStage"
	stage.Parent = workspace
	local base = CFrame.new(0, 10, 0)
	local out = {}
	for _, id in crops do
		if not Growth.Supports(id) then
			table.insert(out, id .. " none")
			continue
		end
		local h, parts = 7, 0
		for _, case in { { 1, nil }, { 2, nil }, { 3, 1.6 }, { 4, 0.6 } } do
			local seed, size = case[1], case[2]
			local plant = Growth.new(stage, base, id, seed, size)
			for _, g in { 0, 0.2, 0.5, 0.75, 1, 0.3 } do
				plant:SetGrowth(g)
				local c
				h, c = dump(plant.model, h)
				parts += c
			end
			if plant.fruitSlots then
				for i, slot in plant.fruitSlots do
					h = mixs(h, i .. ":" .. #slot.parts)
					for _, v in { slot.attachment:GetComponents() } do
						h = mixn(h, v)
					end
				end
			end
			plant:Destroy()
			for st = 1, 3 do
				local proxy = Instance.new("Model")
				Growth.BuildProxy(proxy, base, id, st, seed, size)
				h = dump(proxy, h)
				proxy:Destroy()
			end
			h = mixn(h, Growth.RingHeight(id, size))
		end
		table.insert(out, string.format("%s %08x %d", id, h, parts))
		task.wait()
	end
	stage:Destroy()
	return table.concat(out, "\n")
end)
folder:Destroy()
local leftover = workspace:FindFirstChild("GoldenStage")
if leftover then
	leftover:Destroy()
end
assert(ok, result)
return result
