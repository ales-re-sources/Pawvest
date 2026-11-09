-- Plumbing shared by the plant art recipes (docs/PLANT_GROWTH.md): timing, seed and size helpers, and the Rig that
-- builds a plant's fixed set of Parts once and then writes only the properties that changed.
local PlantKit = {}

local V = Vector3.new

-- Smoothstep of g across [first, last]: 0 before, 1 after.
function PlantKit.phase(g: number, first: number, last: number): number
	local t = math.clamp((g - first) / (last - first), 0, 1)
	return t * t * (3 - 2 * t)
end

-- Frame at the middle of a -> b, with its Z axis along the segment. Stays stable near vertical.
function PlantKit.axis(a: Vector3, b: Vector3): CFrame
	local delta = b - a
	if delta.Magnitude < 0.00001 then
		return CFrame.new(a)
	end
	local up = if math.abs(delta.Unit.Y) > 0.98 then Vector3.xAxis else Vector3.yAxis
	return CFrame.lookAt((a + b) / 2, a, up)
end

-- Cube-root length scale of a harvested mass factor (nil = standard size).
function PlantKit.dimension(sizeFactor: number?): number
	local factor = sizeFactor or 1
	assert(type(factor) == "number" and factor > 0 and factor < math.huge, "Invalid plant size factor")
	return factor ^ (1 / 3)
end

-- vary(extent) = the planting's next random offset in [-extent, extent]. Seed 1 is the authored reference: always 0.
-- The draw order is part of a planting's identity: inserting a draw changes every existing plant's shape.
function PlantKit.seeded(seed: number?): (number) -> number
	local random = Random.new(seed or 1)
	local amount = if (seed or 1) == 1 then 0 else 1
	return function(extent: number): number
		return random:NextNumber(-extent, extent) * amount
	end
end

-- The authored silhouette a planting cycles to; consecutive seeds walk through the whole list.
function PlantKit.tendency(list, seed: number?)
	return list[(math.floor(seed or 1) - 1) % #list + 1]
end

local function newPart(name: string, variant: string?, role: string?, slot: number?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Material, part.MaterialVariant = Enum.Material.Plastic, variant or "StudsSmall"
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
	if role then
		part:SetAttribute("PlantRole", role)
	end
	if slot then
		part:SetAttribute("FruitSlot", slot)
	end
	return part
end

-- One piece of a mid-distance proxy: placed once, casts no shadow.
function PlantKit.proxyPart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, variant: string?, role: string?, slot: number?): Part
	local part = newPart(name, variant, role, slot)
	part.Size, part.CFrame, part.Color = size, cframe, color
	part.CastShadow = false
	part.Parent = parent
	return part
end

local Rig = {}
Rig.__index = Rig

-- `base` is the soil CFrame the pose is relative to.
function PlantKit.newRig(modelName: string, base: CFrame)
	local model = Instance.new("Model")
	model.Name = modelName
	return setmetatable({ model = model, base = base, parts = {}, applied = {}, cursor = 0 }, Rig)
end

-- Adds a hidden Part. A pose must write the Parts in the order they were added.
function Rig:add(name: string, variant: string?, role: string?, slot: number?): Part
	local part = newPart(name, variant, role, slot)
	part.Transparency = 1
	part.Parent = self.model
	table.insert(self.parts, part)
	table.insert(self.applied, { transparency = 1 })
	return part
end

-- Starts a pose: returns the clamped growth, or nil when the plant already shows it. `fixedParts` = how many leading
-- Parts (rigid supports) no pose ever writes.
function Rig:beginPose(normalized: number, fixedParts: number?): number?
	assert(not self.destroyed, "Plant has been destroyed")
	assert(type(normalized) == "number" and normalized == normalized, "Growth must be a number")
	local g = math.clamp(normalized, 0, 1)
	if self.growth == g then
		return nil
	end
	self.growth = g
	self.cursor = fixedParts or 0
	return g
end

-- Writes the next Part at a world CFrame; a hidden Part (opacity 0) keeps its last geometry.
function Rig:place(size: Vector3, world: CFrame, color: Color3, opacity: number)
	self.cursor += 1
	local part, old = self.parts[self.cursor], self.applied[self.cursor]
	if opacity > 0 then
		local actual = V(math.max(size.X, 0.001), math.max(size.Y, 0.001), math.max(size.Z, 0.001))
		if old.size ~= actual then
			part.Size, old.size = actual, actual
		end
		if old.cf ~= world then
			part.CFrame, old.cf = world, world
		end
		if old.color ~= color then
			part.Color, old.color = color, color
		end
	end
	local transparency = 1 - opacity
	if old.transparency ~= transparency then
		part.Transparency, old.transparency = transparency, transparency
	end
end

-- Writes the next Part at `cf`, relative to the soil.
function Rig:block(size: Vector3, cf: CFrame, color: Color3, opacity: number)
	self:place(size, self.base * cf, color, opacity)
end

-- A rod from a to b that fades in over the first moments of its own growth q.
function Rig:rod(a: Vector3, b: Vector3, width: number, color: Color3, q: number)
	self:block(V(width, width, (b - a).Magnitude), PlantKit.axis(a, b), color, PlantKit.phase(q, 0, 0.08))
end

function Rig:hide(count: number)
	for _ = 1, count do
		self.cursor += 1
		local old = self.applied[self.cursor]
		if old.transparency ~= 1 then
			self.parts[self.cursor].Transparency, old.transparency = 1, 1
		end
	end
end

-- Passes Parts whose pose has not changed.
function Rig:skip(count: number)
	self.cursor += count
end

function Rig:finish()
	assert(self.cursor == #self.parts, self.model.Name .. " pose topology changed")
end

function Rig:destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true
	self.model:Destroy()
end

return PlantKit
