-- PetLook: how a pet looks, as a pure function of (kind, level, uid) applied to a clone of ReplicatedStorage.PetModels
-- (docs/PET_GROWTH.md). Shared, so the followers (PetFollow, client) and the garden pens (GardenService, server) are drawn by
-- the same code and always match. Nothing is stored or replicated: every viewer derives the look from the same numbers.
-- P1e1: size by level, label, Epic / Legendary glow, formation slots. `uid` is reserved for the individuality seed (P1e4).
-- Every part is forced Anchored / CanCollide / CanTouch / CanQuery off / Massless here, so a replaced model can never
-- push the owner, fire touch parts or block raycasts and the camera.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))

local PetLook = {}

local SLOT_GAP = 0.6 -- studs between neighbouring pets of a formation
local BASE_BACK = 3.5 -- studs behind the owner of the pets' roots (never closer than the pets' reach allows)
local OWNER_CLEARANCE = 1.5 -- owner half depth + a gap, kept between the owner and the front of the nearest pet
local SIDE_MIN = 2 -- lateral offset of a single pet (at least this, wider models move further out)
local OWNER_HALF_WIDTH = 0.9

export type Label = {
	text: string,
	richText: boolean?,
	size: UDim2,
	maxDistance: number,
	gap: number, -- studs between the top of the scaled model and the label
}

-- size / center: the bounding box of the scaled model in the PrimaryPart's space; lift: how far to raise the root so the
-- model's underside stays where it is at Lv 1 (models grow around their root).
export type Metrics = { scale: number, size: Vector3, center: Vector3, lift: number }

-- Size factor of a level: 1.0 at Lv 1 growing linearly to PetConfig.MaxScale at Lv 20.
function PetLook.Scale(level: number): number
	return PetConfig.ScaleOf(level)
end

-- Look tier of a level (0 below Lv 5, then 1 / 2 / 3 / 4 at Lv 5 / 10 / 15 / 20).
function PetLook.Tier(level: number): number
	return PetConfig.TierOf(level)
end

local function addGlow(root: BasePart, rarity: PetConfig.Rarity)
	if rarity.order < PetConfig.RarityById.Epic.order then
		return
	end
	local legendary = rarity.order >= PetConfig.RarityById.Legendary.order
	local light = Instance.new("PointLight")
	light.Color = rarity.color
	light.Brightness = if legendary then 2.5 else 1.5
	light.Range = if legendary then 10 else 8
	light.Parent = root
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Color = ColorSequence.new(rarity.color)
	sparkles.LightEmission = 1
	sparkles.Size = NumberSequence.new(0.25, 0)
	sparkles.Transparency = NumberSequence.new(0.2, 1)
	sparkles.Lifetime = NumberRange.new(0.6, 1)
	sparkles.Rate = if legendary then 10 else 5
	sparkles.Speed = NumberRange.new(0.5, 1.5)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Parent = root
end

local function addLabel(model: Model, root: BasePart, rarity: PetConfig.Rarity, top: number, label: Label)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Adornee = root
	gui.Size = label.size
	gui.StudsOffset = Vector3.new(0, top + label.gap, 0)
	gui.MaxDistance = label.maxDistance
	gui.LightInfluence = 0
	gui.Parent = model
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.RichText = label.richText == true
	text.Text = label.text
	text.TextColor3 = rarity.color
	text.TextStrokeTransparency = 0.3
	text.Parent = gui
end

-- Dresses a fresh, unparented clone of PetModels[kind] for `level`: forces the safety flags, scales it by level around
-- its root, adds the label (if given) above the scaled model and the Epic / Legendary glow. Call once per clone.
-- Returns the metrics the formation needs, or nil if the model has no PrimaryPart.
function PetLook.Apply(model: Model, kind: string, level: number, uid: string?, label: Label?): Metrics?
	local root = model.PrimaryPart
	local rarity = PetConfig.RarityOf(kind)
	if not (root and rarity) then
		return nil
	end
	level = PetConfig.ClampLevel(level)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Massless = true
		end
	end

	local scale = PetLook.Scale(level)
	model:ScaleTo(scale)
	local boxCFrame, boxSize = model:GetBoundingBox()
	local center = root.CFrame:PointToObjectSpace(boxCFrame.Position)
	local underside = boxSize.Y / 2 - center.Y -- reach below the root

	if label then
		addLabel(model, root, rarity, center.Y + boxSize.Y / 2, label)
	end
	addGlow(root, rarity)
	return { scale = scale, size = boxSize, center = center, lift = underside * (1 - 1 / scale) }
end

-- Formation offsets in the owner's anchor space (+Z = behind), one per entry of `metrics` (same order): 1 pet right-behind,
-- 2 side by side, 3 with the centre one further back. The spacing comes from the widest scaled model, so neighbours never
-- overlap; the distance behind grows with the models' length so the pets do not sink into the owner; `lift` keeps their
-- undersides at the Lv 1 height.
function PetLook.Slots(metrics: { Metrics }): { Vector3 }
	local width, back = 0, BASE_BACK
	for _, info in metrics do
		width = math.max(width, info.size.X)
		back = math.max(back, OWNER_CLEARANCE + info.size.Z / 2 - info.center.Z)
	end
	local spacing = width + SLOT_GAP
	local xs, zs
	local count = #metrics
	if count == 1 then
		xs, zs = { math.max(SIDE_MIN, width / 2 + OWNER_HALF_WIDTH) }, { back }
	elseif count == 2 then
		xs, zs = { -spacing / 2, spacing / 2 }, { back, back }
	else
		xs, zs = { -spacing, 0, spacing }, { back, back + 1, back }
	end
	local slots = {}
	for index, info in metrics do
		slots[index] = Vector3.new(xs[index], info.lift, zs[index])
	end
	return slots
end

return PetLook
