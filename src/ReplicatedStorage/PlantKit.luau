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

-- Pointed organs can opt into WedgePart; existing recipes keep their ordinary Part geometry.
local function newPart(name: string, variant: string?, role: string?, slot: number?, className: string?): BasePart
	assert(className == nil or className == "Part" or className == "WedgePart", "Unsupported plant Part class")
	local part = Instance.new(className or "Part")
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
function PlantKit.proxyPart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, variant: string?, role: string?, slot: number?, className: string?): BasePart
	local part = newPart(name, variant, role, slot, className)
	part.Size, part.CFrame, part.Color = size, cframe, color
	part.CastShadow = false
	part.Parent = parent
	return part
end

-- Growth a mid-distance proxy shows at visual stage 1 / 2 / 3: a seedling, the recipe's own `mid`, ripe.
function PlantKit.proxyGrowth(stage: number, mid: number): number
	return if stage <= 1 then 0.20 elseif stage == 2 then mid else 1
end

-- A proxy rod from a to b (soil space), its Z axis along the segment.
function PlantKit.proxyRod(parent: Instance, soilCFrame: CFrame, name: string, a: Vector3, b: Vector3, width: number, color: Color3, role: string?, slot: number?): BasePart
	return PlantKit.proxyPart(parent, name, V(width, width, (b - a).Magnitude), soilCFrame * PlantKit.axis(a, b), color, nil, role, slot)
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
function Rig:add(name: string, variant: string?, role: string?, slot: number?, className: string?): BasePart
	local part = newPart(name, variant, role, slot, className)
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

-- An emit-style recipe: one geometry(s, g, emit, proxy) describes the plant, and emit is called once per Part, in the same
-- order at every growth: emit(name, size, cf, color, opacity, role?, slot?, variant?, className?) with cf relative to the
-- soil. recipe() fills Plant.new / SetGrowth / Destroy / BuildProxy from it:
--   new        builds the Rig once (emit = add; asserts spec.parts), then poses growth 0
--   SetGrowth  poses the Rig (emit = block)
--   BuildProxy builds only the visible Parts (opacity > 0.01) at PlantKit.proxyGrowth(stage, spec.proxyMid), proxy = true
-- spec: name (model name), parts (Part count), shape(seed, sizeFactor) -> s (the plant object's fields), geometry, proxyMid,
-- and the optional hooks:
--   fixedParts                 leading Parts that onNew places once and no pose writes (rigid supports)
--   onNew(self, rig, soilCFrame)   before the Parts are added (supports, fruit slots: a slotted Part joins
--                              self.fruitSlots[slot].parts)
--   onBuilt(self)              after the Parts are added
--   onPart(part, role, g, index)   after each posed Part; onPose(self, g, result) after a pose (result = geometry's return)
--   onProxy(parent, soilCFrame, s) before the proxy's Parts; onProxyPart(part, role, g) after each proxy Part
function PlantKit.recipe(Plant, spec)
	Plant.__index = Plant

	function Plant.new(parent: Instance, soilCFrame: CFrame, seed: number, sizeFactor: number?)
		local self = setmetatable(spec.shape(seed, sizeFactor), Plant)
		local rig = PlantKit.newRig(spec.name, soilCFrame)
		self.rig, self.model = rig, rig.model
		if spec.onNew then
			spec.onNew(self, rig, soilCFrame)
		end
		spec.geometry(self, 1, function(name, _, _, _, _, role, slot, variant, className)
			local part = rig:add(name, variant, role, slot, className)
			if slot and self.fruitSlots then
				table.insert(self.fruitSlots[slot].parts, part)
			end
		end, false)
		assert(#rig.parts == spec.parts, spec.name .. " topology changed")
		if spec.onBuilt then
			spec.onBuilt(self)
		end
		self:SetGrowth(0)
		self.model.Parent = parent
		return self
	end

	function Plant:SetGrowth(normalized: number)
		local rig = self.rig
		local g = rig:beginPose(normalized, spec.fixedParts)
		if not g then
			return
		end
		local onPart = spec.onPart
		local result = spec.geometry(self, g, function(_, size, cf, color, opacity, role)
			rig:block(size, cf, color, opacity)
			if onPart then
				onPart(rig.parts[rig.cursor], role, g, rig.cursor)
			end
		end, false)
		rig:finish()
		if spec.onPose then
			spec.onPose(self, g, result)
		end
	end

	function Plant:Destroy()
		self.rig:destroy()
	end

	function Plant.BuildProxy(parent: Instance, soilCFrame: CFrame, stage: number, seed: number?, sizeFactor: number?)
		local s = spec.shape(seed, sizeFactor)
		if spec.onProxy then
			spec.onProxy(parent, soilCFrame, s)
		end
		local g = PlantKit.proxyGrowth(stage, spec.proxyMid)
		local onProxyPart = spec.onProxyPart
		spec.geometry(s, g, function(name, size, cf, color, opacity, role, slot, variant, className)
			if opacity <= 0.01 then
				return
			end
			local part = PlantKit.proxyPart(parent, name, size, soilCFrame * cf, color, variant, role, slot, className)
			part.Transparency = 1 - opacity
			if onProxyPart then
				onProxyPart(part, role, g)
			end
		end, true)
	end

	return Plant
end

return PlantKit
