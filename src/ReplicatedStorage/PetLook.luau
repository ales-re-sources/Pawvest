-- PetLook: how a pet looks, as a pure function of (kind, level, uid) applied to a clone of ReplicatedStorage.PetModels
-- (docs/PET_GROWTH.md). Shared, so the followers (PetFollow, client) and the garden pens (GardenService, server) are drawn by
-- the same code and always match. Nothing is stored or replicated: every viewer derives the look from the same numbers.
-- P1e1: size by level, label, Epic / Legendary glow, formation slots.
-- P1e4: individuality - Seed(uid) variant (hue / value shift of the body parts, accessory pick seed).
-- P1f: accessory kit (crown, scarf, wings, horns, flame tail) picked by the seed: AccessoryCount, AccessoriesOf, built by Apply.
-- P1e2: label text with tier badge (LabelText), level-up moment (LevelUp, client only).
-- P1e3: accent tint (AccentBlend), tier effects trail / aura / motes / halo built by Apply, livelier bob (Bob), effect gathering
-- and per-frame update with the distance LOD (CollectFx, UpdateFx).
-- Every part is forced Anchored / CanCollide / CanTouch / CanQuery off / Massless here, so a replaced model can never
-- push the owner, fire touch parts or block raycasts and the camera.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

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

-- A part for effects made in code: neon, no shadow, tiny and invisible until its owner sizes it. Obeys the Apply invariants.
local function fxPart(name: string, shape: Enum.PartType, color: Color3, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Transparency = 1
	part.CastShadow = false
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.Size = Vector3.one * 0.1
	part.Parent = parent
	return part
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

-- Label text of a pet: "Cat Lv 12 ★★", one star per look tier (none below Lv 5), so the tier shows on the label too.
function PetLook.LabelText(kind: string, level: number): string
	level = PetConfig.ClampLevel(level)
	local tier = PetLook.Tier(level)
	return kind .. " Lv " .. level .. if tier > 0 then " " .. string.rep("★", tier) else ""
end

-- Accent tint (P1e3): parts of the model with the Studio attribute Accent = true (stripes, ear insides, tail tip, belly...)
-- ramp from their own colour toward the rarity colour with the level (0 at Lv 1 up to ACCENT_LAST below the max level) and
-- turn Neon at the max level. Returns the blend and whether the accents are Neon.
local ACCENT_LAST = 0.85 -- blend at MaxLevel - 1; MaxLevel itself is the full rarity colour
function PetLook.AccentBlend(level: number): (number, boolean)
	level = PetConfig.ClampLevel(level)
	if level >= PetConfig.MaxLevel then
		return 1, true
	end
	return ACCENT_LAST * (level - 1) / (PetConfig.MaxLevel - 2), false
end

local function tintAccents(model: Model, rarity: PetConfig.Rarity, level: number)
	local blend, neon = PetLook.AccentBlend(level)
	if blend <= 0 then
		return
	end
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute("Accent") == true then
			part.Color = part.Color:Lerp(rarity.color, blend)
			if neon then
				part.Material = Enum.Material.Neon
			end
		end
	end
end

-- Individuality (P1e4): a deterministic variant record per pet id, so two pets of the same kind and level differ but keep their
-- rarity identity. Pure: the uid string is hashed (FNV-1a, then an avalanche mix so neighbouring ids "7" / "8" do not look alike),
-- no math.random state, so the server (pens) and every client (followers) derive the same record.
--   hue / saturation / value   colour shifts of the body parts: hue as a fraction of the circle in +-HUE_JITTER, saturation and
--                              value as factors (1 + shift) with shifts in +-SAT_JITTER / +-VALUE_JITTER
--   tintHue / tintAmount       near-white and grey parts have no hue to shift, so they are tinted toward this hue instead
--   material / order           optional "texture" (a Roblox Material, no asset ids): nil for TEXTURE_NONE of the pets; otherwise
--                              it appears on more body parts as the level rises (see Textured); `order` fixes which parts first
--   accessory                  unsigned 32-bit integer: the order accessories are picked in (AccessoriesOf, P1f)
--   coat                       brightness (COAT_DARK .. COAT_LIGHT) the big white parts of COAT_KINDS take instead of the pastel tint, nil = stay white
--                              (drawn after the fx fields, so older fields are unchanged)
--   fxHue / fxSaturation / fxValue  shift of the effect colour (accents, glow, tier effects, level-up) around the rarity colour,
--                              see FxColor; drawn last, so adding it did not change the fields above
-- uid nil or "" -> nil (old attribute form: no jitter). The record never depends on the level, so a level-up keeps the colours.
local HUE_JITTER = 0.06
local SAT_JITTER = 0.15
local VALUE_JITTER = 0.10
local FX_HUE_JITTER = 0.07 -- effect colour: hue shift (fraction of the circle) around the rarity colour, so green stays green-ish
local FX_SAT_JITTER = 0.15
local FX_VALUE_JITTER = 0.10
local FX_GREY_SATURATION = 0.25 -- grey rarity colour (Common): pale tint in the pet's own tint hue instead of a hue shift
local TINT_MIN, TINT_MAX = 0.10, 0.22 -- how far a near-white / grey part is lerped toward the tint colour
local COAT_WHITE = 0.4 -- share of pets of a coat kind that stay white (the rest are grey ... near-black)
local COAT_LIGHT, COAT_DARK = 0.78, 0.22 -- brightness of the lightest grey and of the darkest coat
local COAT_SATURATION = 0.08 -- a trace of the pet's tint hue so the greys are not dead neutral
local COAT_KINDS = { Bunny = true } -- kinds whose big white parts can take a grey / black coat (user request: Bunny)
local TEXTURE_NONE = 0.5 -- share of pets without any texture
local TEXTURE_MAX_SHARE = 0.45 -- share of the body parts that carry the texture at the max level (< 50 %)
local TEXTURE_MIN_SIZE = 0.38 -- parts whose longest side is shorter (eyes, nose, eye shine) never get it; legs and ears do
local TEXTURE_MATERIALS = {
	Enum.Material.Fabric,
	Enum.Material.Marble,
	Enum.Material.Granite,
	Enum.Material.Slate,
	Enum.Material.Pebble,
	Enum.Material.Ice,
}
PetLook.HueJitter = HUE_JITTER
PetLook.SatJitter = SAT_JITTER
PetLook.ValueJitter = VALUE_JITTER

export type Variant = {
	hue: number,
	saturation: number,
	value: number,
	tintHue: number,
	tintAmount: number,
	material: Enum.Material?,
	order: number,
	accessory: number,
	fxHue: number,
	fxSaturation: number,
	fxValue: number,
	coat: number?,
}

-- a * b modulo 2^32 without leaving the 53 bits a double holds exactly (a, b < 2^32)
local function mul32(a: number, b: number): number
	local high = math.floor(a / 65536)
	local low = a % 65536
	return ((high * b % 65536) * 65536 + low * b) % 4294967296
end

local function mix(h: number): number
	h = mul32(bit32.bxor(h, bit32.rshift(h, 16)), 2246822507)
	h = mul32(bit32.bxor(h, bit32.rshift(h, 13)), 3266489909)
	return bit32.bxor(h, bit32.rshift(h, 16))
end

local function hashString(text: string): number
	local h = 2166136261
	for index = 1, #text do
		h = mul32(bit32.bxor(h, string.byte(text, index)), 16777619)
	end
	return h
end

function PetLook.Seed(uid: string?): Variant?
	if type(uid) ~= "string" or uid == "" then
		return nil
	end
	local state = mix(hashString(uid))
	local function nextUnit(): number -- uniform in [0, 1], one avalanche step per call
		state = mix(bit32.bxor(state, 0x9E3779B9))
		return state / 4294967295
	end
	local hue = (nextUnit() * 2 - 1) * HUE_JITTER
	local saturation = (nextUnit() * 2 - 1) * SAT_JITTER
	local value = (nextUnit() * 2 - 1) * VALUE_JITTER
	local tintHue = nextUnit()
	local tintAmount = TINT_MIN + nextUnit() * (TINT_MAX - TINT_MIN)
	local textured = nextUnit() >= TEXTURE_NONE
	local pick = nextUnit()
	local order = mix(bit32.bxor(state, 0x85EBCA6B))
	local accessory = mix(bit32.bxor(order, 0xC2B2AE35))
	local fxHue = (nextUnit() * 2 - 1) * FX_HUE_JITTER
	local fxSaturation = (nextUnit() * 2 - 1) * FX_SAT_JITTER
	local fxValue = (nextUnit() * 2 - 1) * FX_VALUE_JITTER
	local coatRoll = nextUnit()
	local coatTone = nextUnit()
	return {
		hue = hue,
		saturation = saturation,
		value = value,
		tintHue = tintHue,
		tintAmount = tintAmount,
		material = if textured then TEXTURE_MATERIALS[math.min(#TEXTURE_MATERIALS, math.floor(pick * #TEXTURE_MATERIALS) + 1)] else nil,
		order = order,
		accessory = accessory,
		fxHue = fxHue,
		fxSaturation = fxSaturation,
		fxValue = fxValue,
		coat = if coatRoll >= COAT_WHITE then COAT_LIGHT - coatTone * (COAT_LIGHT - COAT_DARK) else nil,
	}
end

-- Effect colour of a pet: its rarity colour shifted by the variant (hue +-FX_HUE_JITTER, saturation +-15 %, value +-10 %), so
-- two Uncommon pets glow in different greens but still read as "green". A grey rarity colour (Common) has no hue to shift and
-- becomes a pale tint in the pet's tint hue. variant nil -> the rarity colour itself. The label keeps the exact rarity colour.
function PetLook.FxColor(base: Color3, variant: Variant?): Color3
	if not variant then
		return base
	end
	local h, s, v = base:ToHSV()
	if s < 0.15 then
		h = variant.tintHue
		s = FX_GREY_SATURATION + variant.fxSaturation
	else
		h = (h + variant.fxHue) % 1
		s = s * (1 + variant.fxSaturation)
	end
	return Color3.fromHSV(h, math.clamp(s, 0, 1), math.clamp(v * (1 + variant.fxValue), 0, 1))
end

-- Number of body parts that carry the texture at `level` (0 below Lv 2, growing to TEXTURE_MAX_SHARE of the parts at the max
-- level). Never decreases with the level, so a pet that has a texture keeps it and gets it on more parts.
function PetLook.TexturedCount(partCount: number, level: number): number
	level = PetConfig.ClampLevel(level)
	return math.floor(partCount * TEXTURE_MAX_SHARE * (level - 1) / (PetConfig.MaxLevel - 1) + 0.5)
end

-- Body parts (not the invisible Root, not the accents, which follow the tint ramp) get the variant's colour shift; a textured
-- pet also gets its material on the first TexturedCount parts in the variant's part order (Neon parts and tiny ones are left).
local function jitterBody(model: Model, variant: Variant, level: number, kind: string)
	local eligible = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part ~= model.PrimaryPart and part:GetAttribute("Accent") ~= true then
			local h, s, v = part.Color:ToHSV()
			if s < 0.2 and v > 0.4 then
				-- white / grey: no hue to shift, so tint it; the big ones of a coat kind take the grey / black coat instead
				if variant.coat and COAT_KINDS[kind] and math.max(part.Size.X, part.Size.Y, part.Size.Z) >= TEXTURE_MIN_SIZE then
					part.Color = Color3.fromHSV(variant.tintHue, COAT_SATURATION, variant.coat)
				else
					part.Color = part.Color:Lerp(Color3.fromHSV(variant.tintHue, 0.85, 1), variant.tintAmount)
				end
				h, s, v = part.Color:ToHSV()
			else
				h = (h + variant.hue) % 1
			end
			part.Color = Color3.fromHSV(h, math.clamp(s * (1 + variant.saturation), 0, 1), math.clamp(v * (1 + variant.value), 0, 1))
			if
				variant.material
				and part.Material ~= Enum.Material.Neon
				and math.max(part.Size.X, part.Size.Y, part.Size.Z) >= TEXTURE_MIN_SIZE
			then
				table.insert(eligible, { part = part, rank = mix(bit32.bxor(hashString(part.Name), variant.order)) })
			end
		end
	end
	if variant.material then
		table.sort(eligible, function(a, b)
			if a.rank ~= b.rank then
				return a.rank < b.rank
			end
			return a.part.Name < b.part.Name
		end)
		for index = 1, math.min(#eligible, PetLook.TexturedCount(#eligible, level)) do
			eligible[index].part.Material = variant.material
		end
	end
end

local function addEmitter(attachment: Attachment, name: string, color: Color3): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = name
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 1
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-60, 60)
	emitter.Parent = attachment
	return emitter
end

-- Accessory kit (P1f): small pieces built in code from the model's own Head / Body / Tail* parts (positions and sizes are read from
-- them, scaled with the pet; a missing part falls back to the bounding box), so no Studio assets are needed and real art with the
-- same part names keeps working. Which pieces a pet wears is a pure function of (kind, level, uid):
--   how many   0 below Lv 10 (tier 2), 1 at Lv 10-19, 2 at Lv 20 (tier 4)           AccessoryCount
--   which      the allowed pieces of the kind (skip rules) in the order of the variant's accessory seed, greedy, never two forbidden
--              pieces together: the first pick of Lv 10 stays at Lv 20 and the second is added (growth, not reshuffle)   AccessoriesOf
-- No uid (old attribute form) -> no accessories. The tier halo of P1e3 (Lv 20) is the only halo: the kit has no halo piece of its own.
-- Pieces are plain Parts / WedgeParts in a Folder "Accessories" of the model (Apply invariants: anchored, no collide / touch /
-- query, massless), coloured from the pet's FxColor, scaled by `u`; the flame tail adds one emitter, which CollectFx / UpdateFx
-- treat like the tier effects (distance LOD, off while the pet is faded).
local ACCESSORY_COUNT_TIER2, ACCESSORY_COUNT_TIER4 = 1, 2

type Box = { position: Vector3, size: Vector3 } -- a model part in the root's space
type Dress = { model: Model, root: BasePart, folder: Folder, u: number, color: Color3, head: Box, body: Box, rear: { x: number, z: number, top: number } }

local function accessoryPart(dress: Dress, class: string, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material): BasePart
	local part = Instance.new(class) :: BasePart
	part.Name = name
	part.Material = material
	part.Color = color
	part.CastShadow = false
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.Size = size
	part.CFrame = dress.root.CFrame * cframe
	part.Parent = dress.folder
	return part
end

-- Crown: gold band with four points and a neon jewel in front, on top of the head between the ears.
local function buildCrown(dress: Dress)
	local u, head = dress.u, dress.head
	local gold = Color3.fromRGB(255, 205, 70):Lerp(dress.color, 0.15)
	local top = head.position.Y + head.size.Y / 2
	local width, baseHeight, pointHeight, point = 0.46 * u, 0.14 * u, 0.2 * u, 0.12 * u
	local x, z = head.position.X, head.position.Z
	accessoryPart(dress, "Part", "Crown_Base", Vector3.new(width, baseHeight, width), CFrame.new(x, top + baseHeight / 2 - 0.01 * u, z), gold, Enum.Material.SmoothPlastic)
	local corner = width / 2 - point / 2
	local index = 0
	for _, dx in { -corner, corner } do
		for _, dz in { -corner, corner } do
			index += 1
			accessoryPart(dress, "Part", "Crown_Point" .. index, Vector3.new(point, pointHeight, point), CFrame.new(x + dx, top + baseHeight + pointHeight / 2 - 0.02 * u, z + dz), gold, Enum.Material.SmoothPlastic)
		end
	end
	local jewel = accessoryPart(dress, "Part", "Crown_Jewel", Vector3.one * 0.1 * u, CFrame.new(x, top + baseHeight / 2, z - width / 2), dress.color, Enum.Material.Neon)
	;(jewel :: Part).Shape = Enum.PartType.Ball
end

-- Horns: two curved horns (two segments each) on the forehead, in front of the ears, in a dark shade of the pet's colour.
local function buildHorns(dress: Dress)
	local u, head = dress.u, dress.head
	local colour = dress.color:Lerp(Color3.new(0, 0, 0), 0.5)
	local top = head.position.Y + head.size.Y / 2
	for _, side in { -1, 1 } do
		local base = CFrame.new(head.position.X + side * 0.3 * u, top - 0.02 * u, head.position.Z - 0.4 * u) * CFrame.Angles(-0.25, 0, -side * 0.2)
		accessoryPart(dress, "Part", "Horns_Low" .. side, Vector3.new(0.17 * u, 0.26 * u, 0.17 * u), base * CFrame.new(0, 0.13 * u, 0), colour, Enum.Material.SmoothPlastic)
		local upper = base * CFrame.new(0, 0.24 * u, 0) * CFrame.Angles(-0.3, 0, -side * 0.35)
		accessoryPart(dress, "Part", "Horns_High" .. side, Vector3.new(0.11 * u, 0.24 * u, 0.11 * u), upper * CFrame.new(0, 0.12 * u, 0), colour:Lerp(dress.color, 0.3), Enum.Material.SmoothPlastic)
	end
end

-- Scarf: a band under the head around the neck and a short end hanging over the chest.
local function buildScarf(dress: Dress)
	local u, head, body = dress.u, dress.head, dress.body
	local colour = dress.color
	local depth = 0.77 * u
	local frontZ = body.position.Z - body.size.Z / 2 - 0.07 * u
	local neckY = head.position.Y - head.size.Y / 2 - 0.12 * u
	accessoryPart(dress, "Part", "Scarf_Band", Vector3.new(body.size.X + 0.14 * u, 0.26 * u, depth), CFrame.new(body.position.X, neckY, frontZ + depth / 2), colour, Enum.Material.Fabric)
	local hang = 0.6 * u
	accessoryPart(dress, "Part", "Scarf_Tail", Vector3.new(0.26 * u, hang, 0.1 * u), CFrame.new(body.position.X + 0.3 * u, neckY - 0.13 * u - hang / 2, body.position.Z - body.size.Z / 2 - 0.04 * u), colour:Lerp(Color3.new(0, 0, 0), 0.15), Enum.Material.Fabric)
end

-- Small wings: a swept-back wedge and a smaller one behind it on each side of the upper back, tilted outward, light shade of the colour.
local function buildWings(dress: Dress)
	local u, body = dress.u, dress.body
	local colour = dress.color:Lerp(Color3.new(1, 1, 1), 0.55)
	local topY = body.position.Y + body.size.Y / 2
	local function wing(side: number, name: string, thick: number, height: number, length: number, x: number, y: number, z: number, tilt: number)
		local pivot = CFrame.new(body.position.X + side * x, y, z) * CFrame.Angles(0, 0, -side * tilt)
		accessoryPart(dress, "WedgePart", name .. side, Vector3.new(thick, height, length), pivot * CFrame.new(side * thick / 2, height / 2, 0), colour, Enum.Material.SmoothPlastic)
	end
	for _, side in { -1, 1 } do
		wing(side, "Wings_Main", 0.1 * u, 0.7 * u, 0.9 * u, body.size.X / 2 - 0.03 * u, topY - 0.05 * u, body.position.Z + 0.15 * u, 0.45)
		wing(side, "Wings_Small", 0.08 * u, 0.45 * u, 0.6 * u, body.size.X / 2 - 0.01 * u, topY - 0.3 * u, body.position.Z + 0.5 * u, 0.7)
	end
end

-- Flame tail: three neon wedges standing on the end of the tail and a rising emitter above them.
local function buildFlameTail(dress: Dress)
	local u, rear = dress.u, dress.rear
	local z = rear.z - 0.15 * u
	local core = accessoryPart(dress, "WedgePart", "FlameTail_Core", Vector3.new(0.2 * u, 0.55 * u, 0.3 * u), CFrame.new(rear.x, rear.top + 0.275 * u - 0.02 * u, z), dress.color:Lerp(Color3.new(1, 1, 1), 0.25), Enum.Material.Neon)
	for _, side in { -1, 1 } do
		accessoryPart(dress, "WedgePart", "FlameTail_Side" .. side, Vector3.new(0.14 * u, 0.34 * u, 0.22 * u), CFrame.new(rear.x + side * 0.13 * u, rear.top + 0.17 * u - 0.02 * u, z - 0.02 * u), dress.color, Enum.Material.Neon)
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = "FlameAttachment"
	attachment.Position = Vector3.new(0, 0.275 * u, 0.05 * u)
	attachment.Parent = core
	local flames = addEmitter(attachment, "Flame", dress.color:Lerp(Color3.new(1, 1, 1), 0.2))
	flames.Rate = 9
	flames.Lifetime = NumberRange.new(0.4, 0.7)
	flames.Speed = NumberRange.new(1.5 * u, 2.5 * u)
	flames.SpreadAngle = Vector2.new(15, 15)
	flames.Acceleration = Vector3.new(0, 2 * u, 0)
	flames.Size = NumberSequence.new(0.32 * u, 0)
	flames.Transparency = NumberSequence.new(0.15, 1)
end

-- skip: kinds that must not wear the piece (they have it already, or a part is in the way). Kit order = tie-break of equal ranks.
-- Crown skips Bunny / Fox (tall / close ears leave no room between them) and Phoenix (crest); Horns skip Dragon (has horns),
-- Owl (tufts) and Phoenix (crest); Wings skip Dragon / Phoenix / Owl (have wings); Scarf skips Dog (has a collar); FlameTail skips
-- Owl / Panda (no tail).
local ACCESSORIES: { [string]: { skip: { [string]: boolean }, build: (Dress) -> () } } = {
	Crown = { skip = { Bunny = true, Fox = true, Phoenix = true }, build = buildCrown },
	Scarf = { skip = { Dog = true }, build = buildScarf },
	Wings = { skip = { Dragon = true, Phoenix = true, Owl = true }, build = buildWings },
	Horns = { skip = { Dragon = true, Owl = true, Phoenix = true }, build = buildHorns },
	FlameTail = { skip = { Owl = true, Panda = true }, build = buildFlameTail },
}
local ACCESSORY_ORDER = { "Crown", "Scarf", "Wings", "Horns", "FlameTail" }
local ACCESSORY_FORBIDDEN = { { "Crown", "Horns" } } -- both sit on top of the head
PetLook.AccessoryIds = ACCESSORY_ORDER

function PetLook.AccessoryAllowed(kind: string, id: string): boolean
	local def = ACCESSORIES[id]
	return def ~= nil and not def.skip[kind]
end

-- Number of accessories at `level`: 0 below tier 2, 1 at tier 2-3, 2 at tier 4.
function PetLook.AccessoryCount(level: number): number
	local tier = PetLook.Tier(level)
	return if tier >= 4 then ACCESSORY_COUNT_TIER4 elseif tier >= 2 then ACCESSORY_COUNT_TIER2 else 0
end

local function accessoryForbidden(a: string, b: string): boolean
	for _, pair in ACCESSORY_FORBIDDEN do
		if (pair[1] == a and pair[2] == b) or (pair[1] == b and pair[2] == a) then
			return true
		end
	end
	return false
end

-- Accessory ids a pet wears, in pick order (the first one is worn from Lv 10, the second added at Lv 20). nil variant -> none.
function PetLook.AccessoriesOf(kind: string, level: number, variant: Variant?): { string }
	local picked = {}
	local count = PetLook.AccessoryCount(level)
	if count == 0 or not variant then
		return picked
	end
	local ranked = {}
	for index, id in ACCESSORY_ORDER do
		if PetLook.AccessoryAllowed(kind, id) then
			table.insert(ranked, { id = id, index = index, rank = mix(bit32.bxor(variant.accessory, hashString(id))) })
		end
	end
	table.sort(ranked, function(a, b)
		if a.rank ~= b.rank then
			return a.rank < b.rank
		end
		return a.index < b.index
	end)
	for _, candidate in ranked do
		if #picked >= count then
			break
		end
		local fits = true
		for _, id in picked do
			if accessoryForbidden(candidate.id, id) then
				fits = false
				break
			end
		end
		if fits then
			table.insert(picked, candidate.id)
		end
	end
	return picked
end

local function partBox(model: Model, root: BasePart, name: string): Box?
	local part = model:FindFirstChild(name)
	if part and part:IsA("BasePart") then
		return { position = root.CFrame:PointToObjectSpace(part.Position), size = part.Size }
	end
	return nil
end

-- Builds `ids` on the scaled model (so before the bounding box is taken: the metrics, label and halo include the pieces).
local function buildAccessories(model: Model, root: BasePart, ids: { string }, u: number, color: Color3)
	local boxCFrame, boxSize = model:GetBoundingBox()
	local center = root.CFrame:PointToObjectSpace(boxCFrame.Position)
	-- missing Head / Body / Tail parts fall back to the usual proportions inside the bounding box
	local head = partBox(model, root, "Head")
		or { position = Vector3.new(center.X, center.Y + boxSize.Y / 2 - 0.65 * u, center.Z - boxSize.Z / 2 + 0.65 * u), size = Vector3.new(1.5, 1.3, 1.3) * u }
	local body = partBox(model, root, "Body")
		or { position = Vector3.new(center.X, head.position.Y - 0.95 * u, head.position.Z + 0.75 * u), size = Vector3.new(1.3, 1, 1.5) * u }
	-- tail: the parts named Tail* (Tail, TailTip, Tail1-3...); the flame stands on the highest of those that reach the rearmost point
	local rearZ = -math.huge
	local tails = {}
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") and string.sub(child.Name, 1, 4) == "Tail" then
			local box = partBox(model, root, child.Name) :: Box
			table.insert(tails, box)
			rearZ = math.max(rearZ, box.position.Z + box.size.Z / 2)
		end
	end
	local rear = { x = center.X, z = center.Z + boxSize.Z / 2, top = body.position.Y }
	if #tails > 0 then
		rear = { x = tails[1].position.X, z = rearZ, top = -math.huge }
		for _, box in tails do
			if box.position.Z + box.size.Z / 2 >= rearZ - 0.4 * u and box.position.Y + box.size.Y / 2 > rear.top then
				rear.top = box.position.Y + box.size.Y / 2
				rear.x = box.position.X
			end
		end
	end
	local folder = Instance.new("Folder")
	folder.Name = "Accessories"
	folder.Parent = model
	local dress: Dress = { model = model, root = root, folder = folder, u = u, color = color, head = head, body = body, rear = rear }
	for _, id in ids do
		ACCESSORIES[id].build(dress)
	end
end

-- Livelier bob with the tier: height (studs) and speed (rad/s) of the float animation PetFollow plays.
function PetLook.Bob(level: number): (number, number)
	local tier = PetLook.Tier(level)
	return 0.2 + 0.04 * tier, 2.5 + 0.35 * tier
end

-- Tier effects (P1e3), cumulative, all in the pet's effect colour (FxColor: rarity colour shifted by the seed), built in code (no lights besides the Epic / Legendary one):
--   T1 (Lv 5)  sparkle trail behind the pet (world-space particles)
--   T2 (Lv 10) soft aura (low-rate puffs around the body) + an updraft of small sparks rising from under the pet
--   T3 (Lv 15) three tiny neon motes orbiting the body (moved by UpdateFx)
--   T4 (Lv 20) hexagonal neon halo above the head, stronger aura (label moves up by HALO_LIFT to clear it)
-- Everything lives in a Folder "Fx" in the model (parts) or on Root attachments (emitters), so it is cloned, moved and destroyed
-- with the model. The server builds it for the garden pens too; only the orbit animation and the distance LOD need a client
-- (PetFollow for followers, PetPenFx for pens).
local HALO_LIFT = 0.7 -- studs the label rises at tier 4
local MOTE_COUNT = 3
local MOTE_SPEED = 1.8 -- rad/s
local LOD_DISTANCE = 60 -- studs from the camera beyond which emitters, lights and orbiters are off
PetLook.LodDistance = LOD_DISTANCE

local function addTierFx(model: Model, root: BasePart, rarity: PetConfig.Rarity, tier: number, scale: number, center: Vector3, size: Vector3)
	local color = rarity.color
	local fx = Instance.new("Folder")
	fx.Name = "Fx"
	fx.Parent = model
	local bottom, top = center.Y - size.Y / 2, center.Y + size.Y / 2

	-- T1: trail, spawned at the back of the body and left behind in world space
	local back = Instance.new("Attachment")
	back.Name = "FxTrail"
	back.Position = Vector3.new(center.X, center.Y - size.Y * 0.15, center.Z + size.Z / 2)
	back.Parent = root
	local trail = addEmitter(back, "Trail", color)
	trail.Rate = 6
	trail.Lifetime = NumberRange.new(0.6, 0.9)
	trail.Speed = NumberRange.new(0, 0.5)
	trail.SpreadAngle = Vector2.new(180, 180)
	trail.Size = NumberSequence.new(0.35 * scale, 0)
	trail.Transparency = NumberSequence.new(0.15, 1)

	if tier >= 2 then
		local body = Instance.new("Attachment")
		body.Name = "FxAura"
		body.Position = center
		body.Parent = root
		local aura = addEmitter(body, "Aura", color)
		aura.Rate = if tier >= 4 then 7 else 3
		aura.Lifetime = NumberRange.new(1.2, 1.8)
		aura.Speed = NumberRange.new(0.3, 0.8)
		aura.SpreadAngle = Vector2.new(180, 180)
		aura.Size = NumberSequence.new((if tier >= 4 then 2.4 else 1.8) * scale)
		aura.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.25, 0.65),
			NumberSequenceKeypoint.new(1, 1),
		})

		-- updraft: small sparks rise from under the pet along its body (no part, no platform under the pet)
		local under = Instance.new("Attachment")
		under.Name = "FxUpdraft"
		under.Position = Vector3.new(center.X, bottom + 0.1, center.Z)
		under.Parent = root
		local updraft = addEmitter(under, "Updraft", color)
		updraft.Rate = if tier >= 4 then 8 else 4
		updraft.Lifetime = NumberRange.new(0.7, 1.1)
		updraft.Speed = NumberRange.new(1.5, 2.5)
		updraft.SpreadAngle = Vector2.new(20, 20)
		updraft.Size = NumberSequence.new(0.22 * scale, 0)
		updraft.Transparency = NumberSequence.new(0.1, 1)
	end

	if tier >= 3 then
		fx:SetAttribute("Center", center)
		for index = 1, MOTE_COUNT do
			local mote = fxPart("Mote" .. index, Enum.PartType.Ball, color, fx)
			mote.Transparency = 0.1
			mote.Size = Vector3.one * 0.24 * scale
			mote:SetAttribute("Radius", math.max(size.X, size.Z) / 2 + 0.45 * scale)
			mote:SetAttribute("Height", bottom + size.Y * (0.15 + 0.35 * (index - 1))) -- 15 %, 50 %, 85 % of the body height
			mote:SetAttribute("Phase", (index - 1) * 2 * math.pi / MOTE_COUNT)
			mote:SetAttribute("Speed", MOTE_SPEED)
			local angle = mote:GetAttribute("Phase")
			mote.CFrame = root.CFrame * CFrame.new(center.X + math.cos(angle) * mote:GetAttribute("Radius"), mote:GetAttribute("Height"), center.Z + math.sin(angle) * mote:GetAttribute("Radius"))
		end
	end

	if tier >= 4 then
		-- hexagon of six neon bars floating above the top of the model, centred over the head
		local head = model:FindFirstChild("Head")
		local headPosition = if head and head:IsA("BasePart") then root.CFrame:PointToObjectSpace(head.Position) else center
		local radius = (if head and head:IsA("BasePart") then head.Size.X / 2 else size.X / 2) + 0.1 * scale
		local y = top + 0.3 * scale
		for index = 1, 6 do
			local angle = (index - 1) * math.pi / 3
			local bar = fxPart("Halo" .. index, Enum.PartType.Block, color, fx)
			bar.Transparency = 0.05
			bar.Size = Vector3.new(radius * 1.05, 0.1 * scale, 0.14 * scale)
			bar.CFrame = root.CFrame
				* CFrame.new(headPosition.X + math.cos(angle) * radius * 0.866, y, headPosition.Z + math.sin(angle) * radius * 0.866)
				* CFrame.Angles(0, -(angle + math.pi / 2), 0)
		end
	end
end

-- Number of effect instances of a model (emitters, lights, parts of the Fx folder): Apply stamps it as the model attribute
-- FxCount so a client that sees a model before all its children arrived knows to collect again.
local function countFx(model: Model): number
	local count = 0
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("ParticleEmitter") or descendant:IsA("Light") then
			count += 1
		end
	end
	local fx = model:FindFirstChild("Fx")
	return count + if fx then #fx:GetChildren() else 0
end

export type Mote = { part: BasePart, radius: number, height: number, phase: number, speed: number }
export type Fx = {
	root: BasePart,
	emitters: { ParticleEmitter },
	lights: { Light },
	motes: { Mote },
	center: Vector3,
	count: number,
	on: boolean, -- emitters and lights are currently enabled
}

-- Gathers the effects of a dressed model (follower or pen, any side) for UpdateFx. Call once per model, again if
-- `fx.count ~= model:GetAttribute("FxCount")` (children still arriving).
function PetLook.CollectFx(model: Model): Fx?
	local root = model.PrimaryPart
	if not root then
		return nil
	end
	local fx: Fx = { root = root, emitters = {}, lights = {}, motes = {}, center = Vector3.zero, count = countFx(model), on = true }
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			table.insert(fx.emitters, descendant)
		elseif descendant:IsA("Light") then
			table.insert(fx.lights, descendant)
		end
	end
	local folder = model:FindFirstChild("Fx")
	if folder then
		fx.center = folder:GetAttribute("Center") or Vector3.zero
		for _, part in folder:GetChildren() do
			local radius = part:GetAttribute("Radius")
			if part:IsA("BasePart") and radius then
				table.insert(fx.motes, {
					part = part,
					radius = radius,
					height = part:GetAttribute("Height") or 0,
					phase = part:GetAttribute("Phase") or 0,
					speed = part:GetAttribute("Speed") or MOTE_SPEED,
				})
			end
		end
	end
	return fx
end

-- Per-frame effect update after the model was pivoted: `far` (beyond LOD_DISTANCE from the camera) and `faded` (the pet is
-- transparent because the camera is close or run mode / a level-up moment hides it) switch emitters and lights off - particles
-- would otherwise float visibly around an almost invisible pet, or right in front of the camera; far pets also stop moving
-- their orbiting motes. Particles already in the air finish their lifetime.
function PetLook.UpdateFx(fx: Fx, now: number, far: boolean, faded: boolean)
	local on = not (far or faded)
	if on ~= fx.on then
		fx.on = on
		for _, emitter in fx.emitters do
			emitter.Enabled = on
		end
		for _, light in fx.lights do
			light.Enabled = on
		end
	end
	if far then
		return
	end
	local rootCFrame = fx.root.CFrame
	local center = fx.center
	for _, mote in fx.motes do
		local angle = mote.phase + now * mote.speed
		mote.part.CFrame = rootCFrame * CFrame.new(center.X + math.cos(angle) * mote.radius, mote.height, center.Z + math.sin(angle) * mote.radius)
	end
end

-- Dresses a fresh, unparented clone of PetModels[kind] for `level`: forces the safety flags, shifts the body colours by the
-- uid's Seed (nil uid: none), tints the accent parts, scales
-- it by level around its root, adds the label (if given) above the scaled model, the Epic / Legendary glow and the tier
-- effects. Call once per clone. Returns the metrics the formation needs (of the model without effects), or nil if the model
-- has no PrimaryPart.
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
	local variant = PetLook.Seed(uid)
	if variant then
		jitterBody(model, variant, level, kind)
	end
	-- accents, glow, tier effects and level-up use the pet's own effect colour; the label keeps the rarity colour
	local look = table.clone(rarity)
	look.color = PetLook.FxColor(rarity.color, variant)
	model:SetAttribute("FxColor", look.color)
	tintAccents(model, look, level)

	local scale = PetLook.Scale(level)
	model:ScaleTo(scale)
	-- accessories are built on the scaled model and before the bounding box, so metrics, label and halo include them
	local accessories = PetLook.AccessoriesOf(kind, level, variant)
	if #accessories > 0 then
		buildAccessories(model, root, accessories, scale, look.color)
	end
	model:SetAttribute("Accessories", table.concat(accessories, ","))
	local boxCFrame, boxSize = model:GetBoundingBox()
	local center = root.CFrame:PointToObjectSpace(boxCFrame.Position)
	local underside = boxSize.Y / 2 - center.Y -- reach below the root
	local tier = PetLook.Tier(level)

	if label then
		addLabel(model, root, rarity, center.Y + boxSize.Y / 2 + if tier >= 4 then HALO_LIFT else 0, label)
	end
	addGlow(root, look)
	if tier > 0 then
		addTierFx(model, root, look, tier, scale, center, boxSize)
	end
	model:SetAttribute("FxCount", countFx(model))
	return { scale = scale, size = boxSize, center = center, lift = underside * (1 - 1 / scale) }
end

-- Level-up moment (P1e2), client only (every viewer plays it for the pet that levelled). A staged ~2 s show, timed in seconds
-- from the start (constants below):
--   0 - 1.4   the old look spins faster and faster (SPIN_TURNS turns, then SETTLE_TURNS more while braking) and rises RISE studs;
--             swirling sparks get denser
--   0.75-1.85 a bright neon ball with a light surrounds the pet (the flash, ~1 s, peak at ~1.3)
--   0.9 - 1.3 under the flash the old look cross-fades into the new one (new model fades in, the old one - the "ghost" - out);
--             the label switches to the new level at LABEL_AT
--   0         optional sound (ReplicatedStorage.PetLevelUpSound, SOUND_AT)
--   1.2       burst of sparks, expanding ring on the ground, floating "Level N!"
--   1.4 - 2.0 the pet drops back to its place
-- The owner of the pet's position (PetFollow every frame, PetPenLevelUp for pens) calls `moment:Pose(base)` with the pose the
-- pet would have anyway and uses the returned CFrame (spin + rise on top) and fade (LocalTransparencyModifier of the new model,
-- 1 -> 0; combine with max). Pose also drives the ghost, flash and sparks, so it must be called every frame until `moment.done`.
-- Everything extra lives in one Folder "LevelUpFx" in the workspace, removed by Debris after FX_LIFETIME, by `Cancel()` or when
-- the model is destroyed. Every part made here obeys the Apply invariants (anchored, no collide / touch / query, massless).
-- The optional Studio-only ReplicatedStorage.PetLevelUpSound is cloned locally onto the root (like ChallengeCoinSound).
local SPIN_TURNS = 4 -- whole turns while accelerating (the yaw ends on a multiple of 2 pi, so the pet lands facing forward)
local SPIN_TIME = 1.1 -- seconds of accelerating spin and rise
local SETTLE_TURNS = 1 -- whole extra turns while braking to a stop
local SETTLE_TIME = SETTLE_TURNS * SPIN_TIME / SPIN_TURNS
local DROP_TIME = 0.6 -- seconds back down after the spin
local POSE_TIME = SPIN_TIME + SETTLE_TIME + DROP_TIME
local RISE = 3 -- studs above its place at the top
local SWAP_FROM, SWAP_TO = 0.9, 1.3 -- cross-fade old look -> new look
local LABEL_AT = 1.1
local FLASH_FROM, FLASH_TO = 0.75, 1.85
local BURST_AT = 1.2 -- burst, ring and text
local SOUND_AT = 0 -- start of the sound (PetLevelUpSound is ~1.5 s, so it ends around the flash and burst; shift it here if it feels off)
local TEXT_TIME = 1.8
local RING_TIME = 0.9
local BURST_COUNT = 40
local FX_LIFETIME = BURST_AT + TEXT_TIME + 0.4

export type Moment = { done: boolean, Pose: (Moment, CFrame) -> (CFrame, number), Cancel: (Moment) -> () }

local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

-- Yaw (radians) and height of the pet `t` seconds into the moment.
local function spinAndRise(t: number): (number, number)
	local full = 2 * math.pi
	if t <= SPIN_TIME then
		return full * SPIN_TURNS * (t / SPIN_TIME) ^ 2, RISE * smooth(t / SPIN_TIME)
	end
	local s = t - SPIN_TIME
	if s <= SETTLE_TIME then
		local omega = 2 * full * SPIN_TURNS / SPIN_TIME -- angular speed at the end of the acceleration
		return full * SPIN_TURNS + omega * (s - s * s / (2 * SETTLE_TIME)), RISE
	end
	return full * (SPIN_TURNS + SETTLE_TURNS), RISE * (1 - smooth((s - SETTLE_TIME) / DROP_TIME))
end

-- Starts the moment for `model` (the dressed, parented model of the new level). `ghost` = the model of the old level (taken
-- over and destroyed by the moment) with its current LocalTransparencyModifier `ghostFade`; nil for pens (no old model).
-- Returns the moment, or nil if the model cannot play it (no PrimaryPart / not in the workspace; the ghost is destroyed then).
function PetLook.LevelUp(model: Model, kind: string, level: number, ghost: Model?, ghostFade: number?): Moment?
	local root = model.PrimaryPart
	local rarity = PetConfig.RarityOf(kind)
	if not (root and rarity and model:IsDescendantOf(workspace)) then
		if ghost then
			ghost:Destroy()
		end
		return nil
	end
	level = PetConfig.ClampLevel(level)
	local boxCFrame, boxSize = model:GetBoundingBox()
	local center = root.CFrame:PointToObjectSpace(boxCFrame.Position)
	local top = center.Y + boxSize.Y / 2
	local fxColor = model:GetAttribute("FxColor") -- the pet's effect colour, stamped by Apply
	if typeof(fxColor) ~= "Color3" then
		fxColor = rarity.color
	end
	local color = fxColor:Lerp(Color3.new(1, 1, 1), 0.35)
	local flashColor = fxColor:Lerp(Color3.new(1, 1, 1), 0.6)

	local folder = Instance.new("Folder")
	folder.Name = "LevelUpFx"
	folder.Parent = workspace
	Debris:AddItem(folder, FX_LIFETIME)

	-- the label (new level) stays hidden until LABEL_AT, the ghost keeps showing the old one
	local label = model:FindFirstChild("Label")
	if label and not label:IsA("BillboardGui") then
		label = nil
	end
	if label then
		label.Enabled = false
	end
	local ghostParts, ghostLabel = {}, nil
	if ghost then
		ghost.Parent = folder
		ghostLabel = ghost:FindFirstChild("Label")
		for _, part in ghost:GetDescendants() do
			if part:IsA("BasePart") then
				table.insert(ghostParts, part)
			elseif part:IsA("ParticleEmitter") then
				part.Enabled = false -- the old tier effects stop; the new model brings its own
			end
		end
	end
	local ghostStart = ghostFade or 0

	-- swirling sparks around the pet while it spins up
	local attachment = Instance.new("Attachment")
	attachment.Name = "LevelUpAttachment"
	attachment.Position = center
	attachment.Parent = root
	Debris:AddItem(attachment, FX_LIFETIME)
	local swirl = Instance.new("ParticleEmitter")
	swirl.Rate = 0
	swirl.Color = ColorSequence.new(color)
	swirl.LightEmission = 1
	swirl.Size = NumberSequence.new(0.35, 0)
	swirl.Transparency = NumberSequence.new(0.1, 1)
	swirl.Lifetime = NumberRange.new(0.4, 0.8)
	swirl.Speed = NumberRange.new(2, 5)
	swirl.SpreadAngle = Vector2.new(180, 180)
	swirl.Parent = attachment
	local burst = Instance.new("ParticleEmitter")
	burst.Rate = 0
	burst.Color = ColorSequence.new(color)
	burst.LightEmission = 1
	burst.Size = NumberSequence.new(0.5, 0)
	burst.Transparency = NumberSequence.new(0, 1)
	burst.Lifetime = NumberRange.new(0.6, 1.1)
	burst.Speed = NumberRange.new(9, 16)
	burst.Drag = 3
	burst.Acceleration = Vector3.new(0, 6, 0)
	burst.SpreadAngle = Vector2.new(180, 180)
	burst.Parent = attachment

	-- the flash: a neon ball with a light around the pet
	local flashSize = boxSize.Magnitude * 1.2 + 1
	local flash = fxPart("LevelUpFlash", Enum.PartType.Ball, flashColor, folder)
	local light = Instance.new("PointLight")
	light.Color = flashColor
	light.Range = 18
	light.Brightness = 0
	light.Parent = flash

	local moment = { done = false } :: any
	local start = os.clock()
	local celebrated, labelShown, sounded = false, false, false

	local function celebrate(base: CFrame)
		celebrated = true
		burst:Emit(BURST_COUNT)
		-- ring on the ground under the pet's place (a flat neon cylinder, axis up)
		local reach = math.max(boxSize.X, boxSize.Z)
		local ring = fxPart("LevelUpRing", Enum.PartType.Cylinder, fxColor, folder)
		ring.Transparency = 0.2
		ring.Size = Vector3.new(0.15, reach * 0.6, reach * 0.6)
		ring.CFrame = base * CFrame.new(0, center.Y - boxSize.Y / 2 + 0.1, 0) * CFrame.Angles(0, 0, math.pi / 2)
		local ringInfo = TweenInfo.new(RING_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(ring, ringInfo, { Size = Vector3.new(0.15, reach * 2.6 + 2, reach * 2.6 + 2), Transparency = 1 }):Play()

		-- floating "Level N!" above the label
		local gui = Instance.new("BillboardGui")
		gui.Name = "LevelUpText"
		gui.Adornee = root
		gui.Size = UDim2.new(6, 0, 1.2, 0)
		gui.StudsOffset = Vector3.new(0, top + 1.8, 0)
		gui.MaxDistance = 100
		gui.LightInfluence = 0
		gui.AlwaysOnTop = true
		gui.Parent = folder
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.GothamBlack
		text.TextScaled = true
		text.Text = "Level " .. level .. "!"
		text.TextColor3 = color
		text.TextStrokeTransparency = 0.2
		text.Parent = gui
		local riseInfo = TweenInfo.new(TEXT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(gui, riseInfo, { StudsOffset = Vector3.new(0, top + 1.8 + 2.5, 0) }):Play()
		local fadeInfo = TweenInfo.new(TEXT_TIME * 0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, TEXT_TIME * 0.5)
		TweenService:Create(text, fadeInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end

	local function playSound()
		sounded = true
		local template = ReplicatedStorage:FindFirstChild("PetLevelUpSound")
		if template and template:IsA("Sound") then
			local sound = template:Clone()
			sound.Parent = root
			sound:Play()
			Debris:AddItem(sound, 5)
		end
	end

	local function showLabel()
		labelShown = true
		if label then
			label.Enabled = true
		end
		if ghostLabel then
			ghostLabel:Destroy()
			ghostLabel = nil
		end
	end

	local function finish()
		moment.done = true
		swirl.Enabled = false
		if not labelShown then
			showLabel()
		end
		if ghost then
			ghost:Destroy()
			ghost = nil
		end
		flash:Destroy()
	end

	function moment:Pose(base: CFrame): (CFrame, number)
		if moment.done then
			return base, 0
		end
		local t = os.clock() - start
		if t >= POSE_TIME then
			if not celebrated then
				celebrate(base)
			end
			finish()
			return base, 0
		end
		if not sounded and t >= SOUND_AT then
			playSound()
		end
		local yaw, rise = spinAndRise(t)
		local pose = CFrame.new(0, rise, 0) * base * CFrame.Angles(0, yaw, 0)

		-- old look -> new look
		local swap = smooth((t - SWAP_FROM) / (SWAP_TO - SWAP_FROM))
		if ghost then
			if swap >= 1 then
				ghost:Destroy()
				ghost = nil
			else
				ghost:PivotTo(pose)
				for _, part in ghostParts do
					part.LocalTransparencyModifier = ghostStart + (1 - ghostStart) * swap
				end
			end
		end
		if not labelShown and t >= LABEL_AT then
			showLabel()
		end

		-- sparks get denser while spinning up, stop when the spin is over
		swirl.Rate = if t < SPIN_TIME + SETTLE_TIME then 8 + 70 * (t / SPIN_TIME) ^ 2 else 0

		-- the flash: grows and glows to its peak, then fades
		local f = (t - FLASH_FROM) / (FLASH_TO - FLASH_FROM)
		if f > 0 and f < 1 then
			local bell = math.sin(math.pi * f)
			flash.Size = Vector3.one * flashSize * (0.5 + 0.7 * f)
			flash.CFrame = CFrame.new(pose:PointToWorldSpace(center))
			flash.Transparency = 1 - 0.85 * bell
			light.Brightness = 5 * bell
		else
			flash.Transparency = 1
			light.Brightness = 0
		end

		if not celebrated and t >= BURST_AT then
			celebrate(base)
		end
		return pose, 1 - swap
	end

	function moment:Cancel()
		if not moment.done then
			moment.done = true
			if label then
				label.Enabled = true
			end
		end
		folder:Destroy() -- also the ghost, flash, ring and text
	end

	model.Destroying:Connect(function()
		moment:Cancel()
	end)
	return moment :: Moment
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
