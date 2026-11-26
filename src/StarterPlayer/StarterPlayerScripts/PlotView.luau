-- PlotView (E1a1, docs/EXPANSION.md §16): draws one garden plot on the client from a plain state table (GardenRemotes.Plot,
-- GardenPlotFeed), at its slot's position (GardenConfig.PlotCFrame), in one of four details: "full" (floor, edges, sign,
-- incubators with egg and live countdown, incubator billboards, field pets with models and labels, clickable own incubators and the barn prompt
-- on the own plot), "mid" (the same without billboards and prompts, each pet one block in its rarity colour), "low" (floor, one block per egg,
-- the field as its row plates) or "none". Registered crops use seeded growth art; other crops remain blocks.
-- The front strip (U5a): the path in the middle (base), the hatchery on the plaza's left (hatch: posts and roof over the nests
-- inc1..3; own pods click/tap to call options.onHatchery), the barn on its right (barn: a red stud
-- barn with a stepped gable and its decoration; on the own plot the "Open barn" prompt, which calls options.onBarn).
-- A plot is split into pieces (base, hatch, barn, inc1..3, field = row plates, sq1..36, grow1..36). SetState / SetDetail / Relabel only
-- mark the pieces whose look changed; Step builds marked pieces until a deadline, so a build is spread over frames by the caller.
-- State: { name, incCount, eggs = { [1..3] = "EggId:readyAt:startedAt" or "" },
-- field = { crops = two characters per square 1..CropConfig.MaxSquares: crop letter (CropConfig, a-s; a-f in synthetic plots) +
-- stage 1-3 (3 = ripe), ".0" an empty open square, "#0" a locked one, pets = { "Kind:Level:uid:square:tending:guard" } (E1b field pets,
-- tending / guard = Tending / Pest-control level, 0 without it; E4b; a feed without guard reads as 0),
-- plants? = { [square string] = { n = planting identity, startAt, readyAt } } } } or { free = true } (a slot
-- nobody holds: floor, sign "Free plot", grey incubators, an empty barn). Every plot's floor is the front strip; the field lies behind it
-- (the P2 pens are gone since FA).
-- The field (E1d2) has the shape CropConfig.RowWidths: every row is a plate of overgrown grass, open squares are soil on it (pale dry soil while empty),
-- locked squares carry grass tufts (U3a; full detail). Field pets stand on their squares (full: the PetLook model with a label of
-- its name and job icons, never its level; mid: a block). The field has no prompts (U3a): the own plot's field parts are
-- CanQuery so FieldHand's tap ray hits them, SquareAt maps a world point to a square, ShowSelect outlines the selected square
-- and ShowReach tints the squares a pet would work; ShowHover (U3b) marks the square the player stands on with corner brackets. ShowBorders (U3b) draws the placed pets' reach regions as thin borders in their
-- rarity colours (FieldRings computes the regions).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local PetLook = require(ReplicatedStorage:WaitForChild("PetLook"))
local EggLook = require(ReplicatedStorage:WaitForChild("EggLook"))
local IncubatorLook = require(ReplicatedStorage:WaitForChild("IncubatorLook"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local TimeFormat = require(ReplicatedStorage:WaitForChild("TimeFormat"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local PanelFocus = require(ReplicatedStorage:WaitForChild("PanelFocus"))
local UiKit = require(ReplicatedStorage:WaitForChild("UiKit"))
local PlantGrowth = require(ReplicatedStorage:WaitForChild("PlantGrowth"))

local PetModels = ReplicatedStorage:WaitForChild("PetModels")

-- Floor-space layout (U5a, docs/GDD.md §7.6): −Z is the sign side (towards the plaza), so the plaza's left is +X. The
-- strip holds the hatchery on +X (three nests in a triangle under one roof), the barn on −X and a path between them (x ±PATH_HALF).
-- FX (2026-11-22, the user): the hatchery and barn stand one field square (5.5 studs) further towards the plaza, the sign two
-- (GardenConfig.SignZ); the strip grew by one square at its front, so the path still runs from the front edge to the field.
local INCUBATOR_SPOTS = { Vector3.new(8.5, 0, -20.5), Vector3.new(16.2, 0, -20.5), Vector3.new(12.35, 0, -13.5) }
local PATH_HALF = 4.8 -- the gravel path: half its width (the strip's front and back edges leave a gap of EDGE_GAP each side of x = 0)
local EDGE_GAP = 5
local HATCH_X0, HATCH_X1, HATCH_Z0, HATCH_Z1 = 5.6, 19.3, -24.8, -10.2 -- hatchery: centres of its corner posts
local HATCH_ROOF = 12 -- tall pavilion: roof underside, clear of the eggs and approach camera
local BARN_X0, BARN_X1, BARN_Z0, BARN_Z1 = -19, -6, -20.5, -10.5 -- barn: outer faces of its walls (the door faces −Z, the plaza)
local BARN_WALL, BARN_HEIGHT = 0.6, 8 -- barn: wall thickness, wall height over the floor
local BARN_DOOR_HALF, BARN_DOOR_HEIGHT = 3.5, 7 -- barn: half the door opening's width, its height over the floor (a character fits with room)
local BARN_STEPS = { 10, 6.8, 3.6 } -- barn: widths of the stepped gable's red steps over the walls (the ridge ends ~12.2 over the floor)
local BARN_STEP, BARN_CAP = 0.9, 0.3 -- barn: height of each red step, of the slate cap on the walls and on each step
local STRIP_FRONT, STRIP_BACK = GardenConfig.StripFront, -4 -- a plot's floor (FX: front -25.5, was -20): the strip that holds the sign side, the hatchery and the barn
local FIELD_FRONT = GardenConfig.FieldFront -- the field lies behind the strip (floor +Z), from this far behind the centre
local FIELD_PITCH = GardenConfig.FieldPitch -- studs per square
local INFO_DISTANCE = 60 -- studs: pad / incubator billboards and pet labels
local INCUBATOR_NEAR_IN, INCUBATOR_NEAR_OUT, INCUBATOR_FADE = 28, 30, 24
local SIGN_CLEAR = 8 -- name sign: height of the lower frame bar's centre over the floor centre (a player walks under it)
local SIGN_TOP = 12.4 -- name sign: height of the upper frame bar's centre (1.5x the old 8.25-stud sign)

local COLORS = {
	floor = Color3.fromRGB(126, 186, 96),
	edge = Color3.fromRGB(120, 85, 50),
	-- name sign: the stud palette of Workspace.Garden.HubSign
	sign = Color3.fromRGB(117, 77, 50),
	signPost = Color3.fromRGB(255, 151, 90),
	signFrame = Color3.fromRGB(157, 84, 45),
	signCollar = Color3.fromRGB(100, 133, 147),
	signText = Color3.fromRGB(255, 240, 210),
	signNumber = Color3.fromRGB(255, 205, 150),
	path = Color3.fromRGB(196, 178, 140),
	post = Color3.fromRGB(157, 84, 45),
	roof = Color3.fromRGB(196, 72, 56),
	roofTop = Color3.fromRGB(165, 55, 45),
	barnWall = Color3.fromRGB(176, 60, 50),
	barnTrim = Color3.fromRGB(245, 235, 215),
	barnFloor = Color3.fromRGB(150, 105, 65),
	barnDoor = Color3.fromRGB(150, 45, 38),
	barnRoof = Color3.fromRGB(76, 96, 112), -- slate caps of the barn's stepped gable
	steel = Color3.fromRGB(100, 133, 147), -- hardware (the stud palette's steel collars)
	pane = Color3.fromRGB(74, 51, 34), -- the hayloft window's dark pane
	hay = Color3.fromRGB(232, 194, 74),
	can = Color3.fromRGB(200, 208, 212),
	lantern = Color3.fromRGB(255, 214, 120),
	leaf = Color3.fromRGB(97, 149, 0),
	soil = Color3.fromRGB(105, 70, 45),
	drySoil = Color3.fromRGB(176, 140, 100), -- an open square without a crop: empty squares read apart from planted ones at any angle
	overgrown = Color3.fromRGB(78, 120, 52), -- the field's row plates: locked squares and the paths between squares
}
local SPROUT = Color3.fromRGB(110, 190, 80) -- unripe crops (stage 1-2)
local REACH = Color3.fromRGB(255, 230, 120) -- ShowReach tint
local BORDER_INSET, BORDER_LANE, BORDER_WIDTH = 0.45, 0.35, 0.25 -- ShowBorders: studs inside a region's edge, per lane, strip width
local TUFTS = { -- grass tufts on a locked square (U3a): local x, z (in squares), height, yaw, colour
	{ -0.22, -0.18, 1.3, 20, Color3.fromRGB(96, 150, 62) },
	{ 0.2, 0.05, 1.0, 55, Color3.fromRGB(70, 112, 46) },
	{ -0.05, 0.25, 1.5, -30, Color3.fromRGB(110, 165, 70) },
}
local CROP_COLORS = { -- ripe crops, by letter (CropConfig: a Potato, b Corn, c Pumpkin, d Giant melon, E2a rare: e Golden carrot, f Frost grape, g Glow mushroom)
	a = Color3.fromRGB(196, 150, 90),
	b = Color3.fromRGB(245, 210, 60),
	c = Color3.fromRGB(240, 130, 40),
	d = Color3.fromRGB(80, 170, 70),
	e = Color3.fromRGB(255, 190, 40),
	f = Color3.fromRGB(150, 120, 230),
	g = Color3.fromRGB(110, 230, 220),
	-- EV2a ladder: h Lettuce, i Onion, j Garlic, k Tomato, l Cucumber, m Pepper, n Broccoli, o Eggplant, p Blueberry, q Sweet potato,
	-- r Sunflower, s Pineapple
	h = Color3.fromRGB(150, 220, 90),
	i = Color3.fromRGB(205, 160, 200),
	j = Color3.fromRGB(240, 235, 215),
	k = Color3.fromRGB(225, 55, 45),
	l = Color3.fromRGB(60, 140, 60),
	m = Color3.fromRGB(235, 80, 50),
	n = Color3.fromRGB(45, 120, 55),
	o = Color3.fromRGB(110, 50, 140),
	p = Color3.fromRGB(70, 90, 200),
	q = Color3.fromRGB(200, 100, 70),
	r = Color3.fromRGB(255, 205, 30),
	s = Color3.fromRGB(230, 180, 50),
}

local PlotView = {}
PlotView.__index = PlotView

local function part(props): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(p :: any)[key] = value
	end
	return p
end

local function textLabel(parent: Instance, props): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	for key, value in props do
		(label :: any)[key] = value
	end
	label.Parent = parent
	return label
end

-- "Info" billboard over `adornee`'s part with one line of text (pads and incubators that hold nothing).
local function info(parentPart: BasePart, size: UDim2, offset: number, text: string): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Name = "Info"
	gui.AutoLocalize = false
	gui.Size = size
	gui.StudsOffset = Vector3.new(0, offset, 0)
	gui.MaxDistance = INFO_DISTANCE
	gui.AlwaysOnTop = true -- own pods only and only when near; without it number plates and side walls hid the text
	gui.Enabled = false -- own-nest proximity enables it after construction
	local label = textLabel(gui, { Text = text })
	gui.Parent = parentPart
	return label
end

local function prompt(parentPart: BasePart, action: string, object: string, distance: number, onTriggered: () -> ())
	local p = Instance.new("ProximityPrompt")
	p.Name = "Prompt"
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = 0
	p.MaxActivationDistance = distance
	p.RequiresLineOfSight = false
	p.Triggered:Connect(onTriggered)
	p.Parent = parentPart
	return p
end

-- The filtered name of the owner's pet `uid` (P3b): GardenView puts the owner's PetConfig.NamesAttribute into state.names.
local function nameOf(state, uid: string?): string?
	local names = state and state.names
	return if names and uid then names[uid] else nil
end

-- "EggId:readyAt:startedAt" → egg id, readyAt, startedAt; accept the older two-field payload too.
local function parseEgg(text: string?): (string?, number?, number?)
	if type(text) ~= "string" or text == "" then
		return nil, nil
	end
	local egg, readyAt, startedAt = string.match(text, "^([^:]+):(%d+):(%d+)$")
	if not egg then egg, readyAt = string.match(text, "^([^:]+):(%d+)$") end
	return egg, tonumber(readyAt), tonumber(startedAt)
end
PlotView.ParseEgg = parseEgg

-- field.pets ("Kind:Level:uid:square:tending:guard") → [square] = { kind, level, uid, apt (Tending level), guard, text }
local function fieldPets(field): { [number]: { kind: string, level: number, uid: string, apt: number, guard: number, text: string } }
	local map = {}
	if type(field) == "table" and type(field.pets) == "table" then
		for _, text in field.pets do
			local kind, level, uid, square, apt, guard = string.match(text, "^([^:]+):(%d+):([^:]*):(%d+):(%d+):?(%d*)$")
			if kind then
				map[tonumber(square) :: number] = {
					kind = kind,
					level = tonumber(level) :: number,
					uid = uid,
					apt = tonumber(apt) :: number,
					guard = tonumber(guard) or 0,
					text = text,
				}
			end
		end
	end
	return map
end
PlotView.FieldPets = fieldPets

-- Centre (local x, z) of field square `square` (CropConfig.Cell: rows outwards from FIELD_FRONT, centred on the grid).
local function squareSpot(square: number): (number, number)
	local row, col = CropConfig.Cell(square)
	return ((col :: number) - 0.5 - CropConfig.GridColumns / 2) * FIELD_PITCH, FIELD_FRONT + ((row :: number) - 0.5) * FIELD_PITCH
end

-- New view of plot slot `slot` under `parent`. options: { own = boolean, onHatchery = fn(), onBarn = fn() } (interactions on the own
-- plot only), onLike = fn(slot) (SH: the Like prompt on another player's sign), floor = CFrame for a staged preview.
function PlotView.new(slot: number, parent: Instance, options)
	local self = setmetatable({}, PlotView)
	self.slot = slot
	self.floor = (options and options.floor) or GardenConfig.PlotCFrame(slot) :: CFrame
	self.own = options and options.own or false
	self.onHatchery = options and options.onHatchery
	self.onBarn = options and options.onBarn
	self.onLike = options and options.onLike
	self.detail = "none"
	self.state = nil
	self.lang = Locale.Current()
	self.built = {} -- [key] = signature of the drawn piece
	self.pieces = {} -- [key] = Model
	self.pending = {} -- ordered keys whose signature changed
	self.marked = {} -- [key] = true while pending
	self.squares = 0 -- most field squares ever drawn (squares beyond the current field are cleared)
	self.petMap = {} -- [square] = field pet of the current state (fieldPets)
	self.labels = {} -- [incubator] = { gui, label, egg?, readyAt? }; owned-nest info, including empty
	self.incubatorNear = false
	self.incubatorLights = {} -- occupied full-detail pods; update lights at ReadyAt without rebuilding the body
	self.plants = {} -- full-detail plants, separate from soil and field pets
	self.plantCursor = 0
	self.plantNextAt = math.huge
	self.root = Instance.new("Model")
	self.root.Name = string.format("Slot_%02d", slot)
	self.root.Parent = parent
	return self
end

local function growthCrop(field, square: number)
	local letter = field and string.sub(field.crops, square * 2 - 1, square * 2 - 1)
	local crop = letter and CropConfig.ByLetter[letter]
	return if crop and PlantGrowth.Supports(crop.id) then crop else nil
end

function PlotView:keys(): { string }
	local keys = { "base", "hatch", "barn" }
	for n = 1, GardenConfig.MaxIncubators do
		table.insert(keys, "inc" .. n)
	end
	table.insert(keys, "field")
	local field = self.state and self.state.field
	self.squares = math.max(self.squares, if field then CropConfig.MaxSquares else 0)
	for n = 1, self.squares do
		table.insert(keys, "sq" .. n)
		table.insert(keys, "grow" .. n)
	end
	return keys
end

-- What piece `key` should look like now; equal signatures mean nothing to redraw.
function PlotView:signature(key: string): string
	local state = self.state
	local detail = self.detail
	if detail == "none" or not state then
		return "none"
	end
	if key == "base" then
		if state.free then
			return table.concat({ detail, "", self.lang }, "|")
		end
		-- SH: the sign's likes and ribbons, and whether the viewer liked this plot today (the prompt)
		return table.concat({ detail, tostring(state.name), self.lang, tostring(state.likes or 0), tostring(state.ribbons or 0),
			tostring(state.liked == true) }, "|")
	end
	if key == "field" then
		return if not state.free and state.field then detail else "none"
	end
	if key == "hatch" then
		return table.concat({ detail, tostring(self.own and not state.free), self.lang }, "|")
	end
	if key == "barn" then
		return table.concat({ detail, tostring(self.own and not state.free), self.lang }, "|")
	end
	local kind, number = string.match(key, "^(%a+)(%d+)$")
	local n = tonumber(number) :: number
	if state.free then
		return if kind == "inc" or kind == "sq" or kind == "grow" or detail == "low" then "none" else detail .. "|free"
	end
	if kind == "inc" then
		if n > state.incCount then return "none" end -- unpurchased pods have no model, labels or click target
		return table.concat({ detail, state.eggs[n] or "", tostring(self.own), self.lang }, "|")
	end
	local field = state.field
	if not field or n > CropConfig.MaxSquares or detail == "low" then
		return "none"
	end
	local cell = string.sub(field.crops, (n - 1) * 2 + 1, n * 2)
	local plant = type(field.plants) == "table" and field.plants[tostring(n)]
	local crop = growthCrop(field, n)
	if kind == "grow" then
		if not crop or string.sub(cell, 2, 2) == "0" then return "none" end
		local identity = crop.id .. "|" .. tostring(state.ownerId or self.slot) .. "|" .. tostring(plant and plant.n or n)
			.. "|" .. tostring(plant and plant.size or 1)
		return if detail == "full" then "grow|" .. identity else "proxy|" .. identity .. "|" .. self:plantStage(n)
	end
	if crop then
		-- Both plant details live separately; stage/time changes retain soil and pets.
		cell = crop.letter .. (if string.sub(cell, 2, 2) ~= "0" then "1" else "0")
	end
	if string.sub(cell, 1, 1) == "#" then
		-- a locked square is the row plate with grass tufts (full detail); its price shows only in the square card (U3a)
		return if detail == "full" then "lock|" .. tostring(self.own) else "none"
	end
	local pet = self.petMap[n]
	return string.format(
		"%s|%s|%s|%s|%s|%s",
		if self.own and detail == "full" then "own" else "full",
		detail,
		cell,
		if pet then pet.text else "",
		if pet then nameOf(state, pet.uid) or "" else "",
		self.lang
	)
end

function PlotView:mark()
	for _, key in self:keys() do
		if not self.marked[key] and self:signature(key) ~= (self.built[key] or "none") then
			self.marked[key] = true
			table.insert(self.pending, key)
		end
	end
end

function PlotView:SetState(state)
	self.state = state
	self.petMap = fieldPets(state.field)
	for _, entry in self.plants do entry.dirty = true end
	self.plantNextAt = 0 -- a correction can wake a previously ripe plant
	self:mark()
end

function PlotView:SetDetail(detail: string)
	if detail ~= self.detail then
		self.detail = detail
		self:mark()
	end
end

-- Redraws the texts in the current language (Locale.Changed).
function PlotView:Relabel()
	self.lang = Locale.Current()
	self:mark()
end

function PlotView:Pending(): number
	return #self.pending
end

-- The drawn piece `key` ("base", "inc2", "sq7", ...), or nil.
function PlotView:Piece(key: string): Model?
	return self.pieces[key]
end

-- Piece builders: each returns the filled Model (not parented yet) -------------------------------------------------------

function PlotView:at(offset: Vector3): CFrame
	return self.floor * CFrame.new(offset)
end

function PlotView:buildBase(model: Model)
	-- the floor is only the incubator strip (E1b, E1d2): the field starts right behind it
	local front, back = STRIP_FRONT, STRIP_BACK
	local depth, middle = back - front, (front + back) / 2
	local floor = part({ Name = "Floor", Size = Vector3.new(40, 0.5, depth), CFrame = self:at(Vector3.new(0, 0, middle)), Color = COLORS.floor, Material = Enum.Material.Grass })
	floor.CanQuery = true -- something to stand on and to raycast
	floor.Parent = model
	if self.detail == "low" then
		return
	end
	-- the front and back edges leave a gap for the path (U5a)
	-- each front / back piece runs from the gap to the side edges' inner face (x = ±20); the side edges reach the corners, so no two
	-- edges overlap with a shared top face
	local half = (20 - EDGE_GAP) / 2
	local edges = {
		{ Vector3.new(-20.4, 0.65, middle), Vector3.new(0.8, 1, depth + 1.6) },
		{ Vector3.new(20.4, 0.65, middle), Vector3.new(0.8, 1, depth + 1.6) },
	}
	for _, z in { back + 0.4, front - 0.4 } do
		for _, side in { -1, 1 } do
			table.insert(edges, { Vector3.new(side * (EDGE_GAP + half), 0.65, z), Vector3.new(2 * half, 1, 0.8) })
		end
	end
	for _, edge in edges do
		part({ Name = "Edge", Size = edge[2], CFrame = self:at(edge[1]), Color = COLORS.edge,
			Material = Enum.Material.Plastic, MaterialVariant = "Inlets" }).Parent = model
	end
	part({
		Name = "Path",
		Size = Vector3.new(2 * PATH_HALF, 0.1, depth - 0.2),
		CFrame = self:at(Vector3.new(0, 0.3, middle)),
		Color = COLORS.path,
		Material = Enum.Material.Pebble,
	}).Parent = model
	self:buildSign(model)
end

-- The name sign in front of the plot, in the stud look of the garden's hub sign (Inlets texture): two posts high enough to
-- walk between and under (the board's lowest edge is SIGN_CLEAR above the floor) and a board with tan frame bars and steel
-- collars. No two parts share a face plane (z-fighting).
function PlotView:buildSign(model: Model)
	local z = GardenConfig.SignZ -- FX: -33, was -22
	local function stud(name: string, size: Vector3, offset: Vector3, color: Color3, solid: boolean)
		local p = part({
			Name = name,
			Size = size,
			CFrame = self:at(Vector3.new(offset.X, offset.Y, z + offset.Z)),
			Color = color,
			Material = Enum.Material.Plastic,
			MaterialVariant = "Inlets",
			CanCollide = solid,
		})
		p.Parent = model
		return p
	end
	local boardLow, boardHigh = SIGN_CLEAR + 0.3, SIGN_TOP - 0.3 -- the board between the frame bars
	local boardMid = (boardLow + boardHigh) / 2
	for _, x in { -7.6, 7.6 } do
		stud("Post", Vector3.new(1.1, SIGN_TOP + 0.15, 1.1), Vector3.new(x, (SIGN_TOP + 0.4) / 2, 0), COLORS.signPost, true)
		stud("Cap", Vector3.new(1.4, 0.7, 1.4), Vector3.new(x, SIGN_TOP + 0.6, 0), COLORS.signFrame, false)
		stud("Collar", Vector3.new(1.4, 0.6, 1.4), Vector3.new(x, 0.55, 0), COLORS.signCollar, false)
		stud("Collar", Vector3.new(1.4, 0.9, 1.4), Vector3.new(x, SIGN_CLEAR, 0), COLORS.signCollar, false)
	end
	for _, y in { SIGN_CLEAR, SIGN_TOP } do
		stud("Bar", Vector3.new(15.2, 0.6, 0.8), Vector3.new(0, y, 0), COLORS.signPost, false)
	end
	local sign = stud("Sign", Vector3.new(14, boardHigh - boardLow, 0.5), Vector3.new(0, boardMid, 0), COLORS.sign, false)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Gui"
	gui.Face = Enum.NormalId.Front
	gui.AutoLocalize = false
	gui.PixelsPerStud = 25
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	-- SH: "12❤      🏆 3× crop of the week" centred under the name (only what is above zero; the crop of the week in words:
	-- a bare ribbon symbol was not understood)
	local social = {}
	local likes = if not self.state.free and type(self.state.likes) == "number" then self.state.likes else 0
	local ribbons = if not self.state.free and type(self.state.ribbons) == "number" then self.state.ribbons else 0
	if likes > 0 then
		table.insert(social, Locale.T("garden.sign.likes", { count = likes }))
	end
	if ribbons > 0 then
		table.insert(social, Locale.T("garden.sign.ribbons", { count = ribbons }))
	end
	local name = textLabel(gui, {
		Name = "Name",
		Position = UDim2.new(0, 14, 0, 6),
		Size = UDim2.new(1, -28, 1, if #social > 0 then -40 else -12),
		Font = StudStyle.Font,
		TextColor3 = COLORS.signText,
		TextStrokeColor3 = Color3.new(0, 0, 0),
		TextStrokeTransparency = 0.5,
		-- a player name (no translation)
		Text = if self.state.free then Locale.T("garden.sign.plotFree") else tostring(self.state.name),
	})
	local cap = Instance.new("UITextSizeConstraint") -- a short name on the whole board would read as a shout
	cap.MaxTextSize = 56
	cap.Parent = name
	if #social > 0 then
		local line = textLabel(gui, {
			Name = "Social",
			Position = UDim2.new(0, 14, 1, -32),
			Size = UDim2.new(1, -28, 0, 26),
			Font = StudStyle.Font,
			TextColor3 = COLORS.signNumber,
			TextStrokeColor3 = Color3.new(0, 0, 0),
			TextStrokeTransparency = 0.6,
			Text = table.concat(social, string.rep(" ", 8)), -- a clear gap: two separate counts, not one phrase
		})
		local lineCap = Instance.new("UITextSizeConstraint") -- 22 like before; a longer (Czech) line shrinks to fit
		lineCap.MaxTextSize = 22
		lineCap.Parent = line
	end
	gui.Parent = sign
	-- SH: another player's plot gets a Like prompt at the board's lower edge (once a day per plot; "Liked" after that)
	if not self.own and not self.state.free and self.onLike and self.detail == "full" then
		local spot = Instance.new("Attachment")
		spot.Name = "LikeSpot"
		spot.Position = Vector3.new(0, -(boardHigh - boardLow) / 2, 0)
		spot.Parent = sign
		local liked = self.state.liked == true
		local like = Instance.new("ProximityPrompt")
		like.Name = "LikePrompt"
		like.ActionText = Locale.T(if liked then "garden.like.done" else "garden.like.action")
		like.ObjectText = Locale.T("garden.like.object", { name = tostring(self.state.name) })
		like.HoldDuration = 0
		like.MaxActivationDistance = 12
		like.RequiresLineOfSight = false
		like.Triggered:Connect(function()
			self.onLike(self.slot)
		end)
		like.Parent = spot
	end
end

-- Pet model standing at `at` (its pivot's horizontal position) on a surface whose top is at height `top` (full detail): a PetModels
-- clone dressed by PetLook like the followers, with `text` over it.
-- The hatchery (U5a): an open shelter over the three nests (the nests are the inc1..3 pieces): four corner posts and a stepped
-- roof. Low detail: the roof only. No two parts share a face plane.
function PlotView:buildHatchery(model: Model)
	local x0, x1, z0, z1 = HATCH_X0, HATCH_X1, HATCH_Z0, HATCH_Z1
	local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
	local w, d = x1 - x0, z1 - z0
	local function add(name: string, size: Vector3, at: Vector3, color: Color3)
		local p = part({ Name = name, Size = size, CFrame = self:at(at), Color = color, Material = Enum.Material.Plastic, MaterialVariant = "Inlets" })
		p.Parent = model
		return p
	end
	-- Three thinner courses keep the pavilion light while leaving its footprint unchanged.
	local roof = HATCH_ROOF
	add("Roof", Vector3.new(w + 1.8, 0.4, d + 1.8), Vector3.new(cx, roof + 0.2, cz), COLORS.roof)
	add("Roof", Vector3.new(w - 2.6, 0.4, d - 2.6), Vector3.new(cx, roof + 0.6, cz), COLORS.roofTop)
	add("Roof", Vector3.new(w - 7, 0.4, d - 7), Vector3.new(cx, roof + 1, cz), COLORS.roof)
	if self.detail == "low" then
		return
	end
	local height = roof - 0.25 -- from the floor's top (0.25) to the roof's underside
	for _, x in { x0, x1 } do
		for _, z in { z0, z1 } do
			add("Post", Vector3.new(1, height, 1), Vector3.new(x, 0.25 + height / 2, z), COLORS.post).CanCollide = true
		end
	end
end

-- The barn (U5a; stud look since 2026-11-13, the user's pick "classic red barn"): red Inlets walls with a door opening towards the
-- plaza, a stepped gable (red steps under slate Studs caps), a white door frame, both door leaves swung open flat against the front
-- wall with a white frame and X brace, a hayloft window over the door. Full detail adds the decoration: a flower box, a hay hook and a
-- weathervane with a pet on the ridge; hay bales, milk cans and a pitchfork in front; a lantern, hay and a ladder inside. The barn
-- shows no stock (the barn panel lists it, 2026-11-12). The own plot's barn carries the "Open barn" prompt (full detail). Low detail:
-- one block under the stepped gable. No two parts share a face plane: details on a face stand 0.03 inside it, and crossing or
-- overlapping details stand out by different depths.
function PlotView:buildBarn(model: Model)
	local x0, x1, z0, z1 = BARN_X0, BARN_X1, BARN_Z0, BARN_Z1
	local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
	local w, d, t = x1 - x0, z1 - z0, BARN_WALL
	local base = 0.25 -- the plot floor's top
	local top = base + BARN_HEIGHT -- the walls' top
	-- a part at `cf` in plot-floor space: stud `variant` on Plastic, else SmoothPlastic (small parts: the texture reads as a waffle)
	local function put(name: string, size: Vector3, cf: CFrame, color: Color3, variant: string?, solid: boolean?): Part
		local p = part({
			Name = name,
			Size = size,
			CFrame = self.floor * cf,
			Color = color,
			Material = if variant then Enum.Material.Plastic else Enum.Material.SmoothPlastic,
			MaterialVariant = variant or "",
			CanCollide = solid == true,
		})
		p.Parent = model
		return p
	end
	local function add(name: string, size: Vector3, at: Vector3, color: Color3, variant: string?, solid: boolean?): Part
		return put(name, size, CFrame.new(at), color, variant, solid)
	end
	-- a detail on a face looking towards −Z at z = `face`: `proud` studs in front of it, 0.03 inside it, turned `roll` about Z
	local function onFront(name: string, width: number, height: number, x: number, y: number, face: number, proud: number, color: Color3, roll: number?): Part
		local depth = proud + 0.03
		return put(name, Vector3.new(width, height, depth), CFrame.new(x, y, face + 0.03 - depth / 2) * CFrame.Angles(0, 0, roll or 0), color)
	end
	-- the stepped gable: a slate cap on the walls, then each red step under its own cap (caps overhang the sides and the back by 0.4;
	-- at the front they end flush with the steps, so the window and the hay hook sit on one plane)
	local y = top
	local function cap(width: number)
		add("Roof", Vector3.new(width + 0.8, BARN_CAP, d + 0.4), Vector3.new(cx, y + BARN_CAP / 2, z0 + (d + 0.4) / 2), COLORS.barnRoof, "Studs", true)
		y += BARN_CAP
	end
	cap(w)
	local stepBottom = y -- the lowest step's bottom
	for _, width in BARN_STEPS do
		add("Gable", Vector3.new(width, BARN_STEP, d), Vector3.new(cx, y + BARN_STEP / 2, cz), COLORS.barnWall, "Inlets", true)
		y += BARN_STEP
		cap(width)
	end
	local ridge = y
	if self.detail == "low" then
		add("Barn", Vector3.new(w, BARN_HEIGHT, d), Vector3.new(cx, base + BARN_HEIGHT / 2, cz), COLORS.barnWall, "Inlets", true)
		return
	end

	-- walls: the back one spans the full width, the sides run between it and the front wall: two pieces beside the door and a header
	local doorL, doorR = cx - BARN_DOOR_HALF, cx + BARN_DOOR_HALF
	local doorTop = base + BARN_DOOR_HEIGHT
	add("Wall", Vector3.new(w, BARN_HEIGHT, t), Vector3.new(cx, base + BARN_HEIGHT / 2, z1 - t / 2), COLORS.barnWall, "Inlets", true)
	for _, x in { x0 + t / 2, x1 - t / 2 } do
		add("Wall", Vector3.new(t, BARN_HEIGHT, d - 2 * t), Vector3.new(x, base + BARN_HEIGHT / 2, cz), COLORS.barnWall, "Inlets", true)
	end
	for _, span in { { x0, doorL }, { doorR, x1 } } do
		add("Wall", Vector3.new(span[2] - span[1], BARN_HEIGHT, t), Vector3.new((span[1] + span[2]) / 2, base + BARN_HEIGHT / 2, z0 + t / 2), COLORS.barnWall, "Inlets", true)
	end
	add("Wall", Vector3.new(doorR - doorL, top - doorTop, t), Vector3.new(cx, (doorTop + top) / 2, z0 + t / 2), COLORS.barnWall, "Inlets", true)
	-- the floor inside the walls (its sides meet the walls' inner faces, which face the other way; its front edge is hidden in the front
	-- wall and 0.03 inside the opening)
	local inX0, inX1, inZ1 = x0 + t, x1 - t, z1 - t
	local floorZ0 = z0 + 0.03
	local floor = add("BarnFloor", Vector3.new(inX1 - inX0, 0.2, inZ1 - floorZ0), Vector3.new(cx, base + 0.1, (floorZ0 + inZ1) / 2), COLORS.barnFloor, "Inlets", true)
	-- the white door frame: jambs straddling the opening's edges, a lintel over them
	for _, x in { doorL, doorR } do
		onFront("Trim", 0.4, BARN_DOOR_HEIGHT - 0.2, x, base + (BARN_DOOR_HEIGHT - 0.2) / 2, z0, 0.2, COLORS.barnTrim)
	end
	onFront("Trim", 2 * BARN_DOOR_HALF + 0.8, 0.4, cx, doorTop, z0, 0.2, COLORS.barnTrim)
	-- the door leaves, swung open flat against the front wall pieces (0.2 in front of them), each with a white frame and an X brace
	-- (the brace's bars cross, so they stand out by different depths)
	local leafW, leafH = doorL - 0.25 - (x0 + 0.05), BARN_DOOR_HEIGHT - 0.5
	local leafY, leafFace = base + 0.25 + leafH / 2, z0 - 0.4
	local innerW, innerH = leafW - 0.66, leafH - 0.66 -- inside the frame bars (0.3 wide, 0.03 in from the leaf's edges)
	local braceLength, braceAngle = math.sqrt(innerW * innerW + innerH * innerH) - 0.2, math.atan2(innerH, innerW)
	for _, lx in { x0 + 0.05 + leafW / 2, x1 - 0.05 - leafW / 2 } do
		add("Door", Vector3.new(leafW, leafH, 0.2), Vector3.new(lx, leafY, z0 - 0.3), COLORS.barnDoor, "Inlets", true)
		for _, s in { -1, 1 } do
			onFront("DoorTrim", leafW - 0.06, 0.3, lx, leafY + s * (leafH / 2 - 0.18), leafFace, 0.12, COLORS.barnTrim)
			onFront("DoorTrim", 0.3, innerH, lx + s * (leafW / 2 - 0.18), leafY, leafFace, 0.12, COLORS.barnTrim)
		end
		onFront("DoorBrace", braceLength, 0.3, lx, leafY, leafFace, 0.08, COLORS.barnTrim, braceAngle)
		onFront("DoorBrace", braceLength, 0.3, lx, leafY, leafFace, 0.05, COLORS.barnTrim, -braceAngle)
	end
	-- the hayloft window over the door, on the steps' front faces: a dark pane, a white frame and a mullion
	local paneW, paneH = 2, 1.8
	local paneY = stepBottom + 0.2 + paneH / 2
	onFront("Window", paneW, paneH, cx, paneY, z0, 0.05, COLORS.pane)
	onFront("WindowFrame", 0.15, paneH, cx, paneY, z0, 0.09, COLORS.barnTrim)
	for _, s in { -1, 1 } do
		onFront("WindowFrame", 0.25, paneH, cx + s * (paneW + 0.25) / 2, paneY, z0, 0.12, COLORS.barnTrim)
		onFront("WindowFrame", paneW + 0.5, 0.25, cx, paneY + s * (paneH + 0.25) / 2, z0, 0.12, COLORS.barnTrim)
	end
	if self.own and self.onBarn and self.detail == "full" and not self.state.free then
		prompt(floor, Locale.T("barn.prompt.action"), Locale.T("barn.prompt.object"), 10, function()
			self.onBarn()
		end)
	end
	if self.detail ~= "full" then
		return
	end

	-- decoration (full detail; never solid except the hay bales in front, which a player may climb)
	-- a flower box over the door frame
	local boxY = top - 0.3
	onFront("FlowerBox", 2.6, 0.5, cx, boxY, z0, 0.5, COLORS.signFrame)
	local boxZ = z0 - 0.235 -- the flower box's depth centre
	add("FlowerLeaves", Vector3.new(2.4, 0.15, 0.4), Vector3.new(cx, boxY + 0.325, boxZ), COLORS.leaf)
	for i, color in { Color3.fromRGB(255, 102, 204), Color3.fromRGB(255, 232, 61), Color3.fromRGB(126, 255, 255) } do
		add("Flower", Vector3.new(0.35, 0.35, 0.35), Vector3.new(cx + (i - 2) * 0.8, boxY + 0.425, boxZ), color)
	end
	-- the hay hook: a beam out of the top step, a hook hanging from its end
	local hookY = ridge - BARN_CAP - BARN_STEP / 2
	add("HookBeam", Vector3.new(0.4, 0.4, 1.4), Vector3.new(cx, hookY, z0 + 0.03 - 0.7), COLORS.sign)
	add("Hook", Vector3.new(0.12, 0.5, 0.12), Vector3.new(cx, hookY - 0.45, z0 - 1.2), COLORS.steel)
	-- the weathervane on the ridge: a collar, a pole, an arrow along X (head, tail fin) and a little pet on top
	add("VaneCollar", Vector3.new(0.6, 0.3, 0.6), Vector3.new(cx, ridge + 0.15, cz), COLORS.steel, "Inlets")
	add("VanePole", Vector3.new(0.2, 2.17, 0.2), Vector3.new(cx, ridge + 0.03 + 2.17 / 2, cz), COLORS.steel)
	local arrowY, petY = ridge + 1.6, ridge + 2.2
	add("VaneArrow", Vector3.new(2.6, 0.12, 0.12), Vector3.new(cx, arrowY, cz), COLORS.steel)
	put("VaneHead", Vector3.new(0.45, 0.45, 0.1), CFrame.new(cx + 1.3, arrowY, cz) * CFrame.Angles(0, 0, math.rad(45)), COLORS.steel)
	add("VaneFin", Vector3.new(0.6, 0.7, 0.08), Vector3.new(cx - 1.2, arrowY, cz), COLORS.steel)
	add("VanePet", Vector3.new(1, 0.5, 0.3), Vector3.new(cx, petY + 0.25, cz), COLORS.signPost)
	add("VanePet", Vector3.new(0.55, 0.5, 0.36), Vector3.new(cx + 0.6, petY + 0.5, cz), COLORS.signPost)
	for _, ex in { 0.45, 0.75 } do
		add("VanePet", Vector3.new(0.14, 0.22, 0.2), Vector3.new(cx + ex, petY + 0.86, cz), COLORS.signPost)
	end
	add("VanePet", Vector3.new(0.14, 0.6, 0.14), Vector3.new(cx - 0.55, petY + 0.5, cz), COLORS.signPost)
	-- hay bales in front of the left leaf (two side by side, one on top)
	for _, bale in { { x0 + 1.1, 0.5, z0 - 3.6 }, { x0 + 1.1, 0.5, z0 - 2.3 }, { x0 + 1.2, 1.5, z0 - 2.95 } } do
		add("Hay", Vector3.new(2, 1, 1.2), Vector3.new(bale[1], base + bale[2], bale[3]), COLORS.hay, "Studs", true)
	end
	-- two milk cans in front of the right leaf
	local upright = CFrame.Angles(0, 0, math.rad(90)) -- a cylinder's axis is its X: turn it to stand
	for _, at in { Vector3.new(x1 - 1, 0, z0 - 2.2), Vector3.new(x1 - 2, 0, z0 - 2.8) } do
		put("MilkCan", Vector3.new(1.2, 0.8, 0.8), CFrame.new(at.X, base + 0.6, at.Z) * upright, COLORS.can).Shape = Enum.PartType.Cylinder
		put("MilkCan", Vector3.new(0.2, 0.6, 0.6), CFrame.new(at.X, base + 1.3, at.Z) * upright, COLORS.steel).Shape = Enum.PartType.Cylinder
	end
	-- a pitchfork leaning against the right leaf, tines up
	local fork = CFrame.new(x1 - 0.7, base, z0 - 1.3) * CFrame.Angles(math.atan2(0.7, 3.8), 0, 0)
	put("Pitchfork", Vector3.new(0.15, 3.3, 0.15), fork * CFrame.new(0, 1.65, 0), COLORS.signFrame)
	put("Pitchfork", Vector3.new(0.7, 0.12, 0.12), fork * CFrame.new(0, 3.3, 0), COLORS.steel)
	for _, tx in { -0.3, 0, 0.3 } do
		put("Pitchfork", Vector3.new(0.08, 0.55, 0.08), fork * CFrame.new(tx, 3.575, 0), COLORS.steel)
	end
	-- inside: a lantern hanging from the ceiling, hay in the back left corner, a ladder on the back wall
	add("Lantern", Vector3.new(0.08, 0.9, 0.08), Vector3.new(cx, top - 0.45, cz + 1), COLORS.steel)
	add("Lantern", Vector3.new(0.5, 0.15, 0.5), Vector3.new(cx, top - 0.975, cz + 1), COLORS.steel)
	add("Lantern", Vector3.new(0.4, 0.6, 0.4), Vector3.new(cx, top - 1.35, cz + 1), COLORS.lantern).Material = Enum.Material.Neon
	local inside = base + 0.2 -- the barn floor's top
	for _, bale in { { inX0 + 1.1, 0.5, inZ1 - 0.7 }, { inX0 + 1.1, 0.5, inZ1 - 2 }, { inX0 + 1.2, 1.5, inZ1 - 1.35 } } do
		add("Hay", Vector3.new(2, 1, 1.2), Vector3.new(bale[1], inside + bale[2], bale[3]), COLORS.hay, "Studs")
	end
	local ladderZ, ladderH = inZ1 - 0.2, top - 0.5 - inside
	for _, rx in { inX1 - 1.5, inX1 - 0.5 } do
		add("Ladder", Vector3.new(0.2, ladderH, 0.2), Vector3.new(rx, inside + ladderH / 2, ladderZ), COLORS.signFrame)
	end
	for rung = 1, math.floor(ladderH - 0.5) do
		add("Ladder", Vector3.new(1.1, 0.15, 0.15), Vector3.new(inX1 - 1, inside + rung - 0.2, ladderZ), COLORS.signFrame)
	end
end

local function standingPet(kind: string, level: number, uid: string, at: CFrame, top: number, text: string): Model?
	local template = PetModels:FindFirstChild(kind)
	if not (template and template:IsA("Model") and template.PrimaryPart) then
		return nil
	end
	local model = template:Clone()
	local metrics = PetLook.Apply(model, kind, level, uid, {
		text = text,
		richText = true,
		size = UDim2.new(6, 0, 1.4, 0),
		maxDistance = INFO_DISTANCE + 30,
		gap = 1,
	})
	if not metrics then
		model:Destroy()
		return nil
	end
	model:PivotTo(at + Vector3.new(0, 1, 0))
	-- stand the model on the surface: move it so the lowest point of its bounding box touches the top
	local boxCFrame, boxSize = model:GetBoundingBox()
	local bottom = boxCFrame.Position.Y - boxSize.Y / 2
	model:PivotTo(model:GetPivot() + Vector3.new(0, top - bottom, 0))
	return model
end

-- Job icons of a field pet: "🌱4 🛡2" (Tending, Pest control; U3a: never the level, which may come from Cuteness).
local function jobIcons(apt: number, guard: number): string
	local jobs = {}
	if apt > 0 then
		table.insert(jobs, Locale.T("field.job.tending", { level = apt }))
	end
	if guard > 0 then
		table.insert(jobs, Locale.T("field.job.guard", { level = guard }))
	end
	return table.concat(jobs, " ")
end
PlotView.JobIcons = jobIcons

-- Label over a field pet: its given name (only if it has one) over the job icons.
local function fieldPetLabel(apt: number, guard: number, name: string?): string
	local jobs = jobIcons(apt, guard)
	if type(name) == "string" and name ~= "" then
		return Locale.T("field.pet.label", { name = name, jobs = jobs })
	end
	return jobs
end

function PlotView:buildIncubator(model: Model, n: number)
	local state = self.state
	local spot = INCUBATOR_SPOTS[n]
	local podCFrame = self:at(spot) * CFrame.Angles(0, math.pi / 2, 0) -- front (-Z) faces the central path (-X)
	self.labels[n] = nil
	self.incubatorLights[n] = nil
	local eggId, readyAt, startedAt = parseEgg(state.eggs[n])
	local egg = eggId and PetConfig.Eggs[eggId]
	local status = if not eggId then "empty"
		else GardenConfig.EggPhase(startedAt, readyAt or math.huge, self.tickNow or workspace:GetServerTimeNow())
	local setState, animate = IncubatorLook.Build(model, podCFrame, self.detail, status, n)
	if self.own and self.onHatchery and self.detail == "full" then
		local target = part({
			Name = "ClickTarget", Size = Vector3.new(7, 6.5, 7), CFrame = podCFrame * CFrame.new(0, 3.25, 0),
			Transparency = 1, CanCollide = false, CanQuery = true,
		})
		target.Parent = model
		local hover = Instance.new("Highlight")
		hover.Name = "Hover"
		hover.Adornee = model
		hover.FillTransparency = 1
		hover.OutlineColor = Color3.new(1, 1, 1)
		hover.OutlineTransparency = 0.15
		hover.DepthMode = Enum.HighlightDepthMode.Occluded
		hover.Enabled = false
		hover.Parent = model
		local click = Instance.new("ClickDetector")
		click.Name = "OpenHatchery"
		click.MaxActivationDistance = 60
		click.CursorIcon = "rbxasset://textures/Cursors/DragDetector/HoverCursor.png"
		local function canOpen()
			local player = game:GetService("Players").LocalPlayer
			local root = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not root or PanelFocus.Current() ~= nil or UiKit.BlocksWorld(player.PlayerGui, UiKit.PointerPosition()) then return false end
			local offset = root.Position - self.floor.Position
			return Vector3.new(offset.X, 0, offset.Z).Magnitude <= 45
		end
		click.MouseClick:Connect(function()
			hover.Enabled = false
			if canOpen() then self.onHatchery() end
		end)
		click.Parent = target
	end
	if self.detail == "low" then
		if eggId then
			EggLook.Make(eggId, podCFrame * CFrame.new(0, 1.85, 0), "low").Parent = model
		end
		return
	end
	local base = model:FindFirstChild("Base") :: BasePart
	if not eggId then
		if self.own and self.detail == "full" then
			local label = info(base, UDim2.new(6, 0, 1, 0), 6.9, Locale.T("garden.sign.incubator.empty"))
			self.labels[n] = { gui = label.Parent, label = label }
		end
		return
	end
	local shell = EggLook.Make(eggId, podCFrame * CFrame.new(0, 1.85, 0), self.detail)
	shell.Parent = model
	self.incubatorLights[n] = { setState = setState, animate = animate, startedAt = startedAt, readyAt = readyAt or math.huge }
	animate(self.tickNow or workspace:GetServerTimeNow(), startedAt)
	if self.detail ~= "full" or not self.own then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "Info"
	gui.AutoLocalize = false
	gui.Size = UDim2.new(6, 0, 1.6, 0)
	gui.StudsOffset = Vector3.new(0, 3.9, 0) -- status clears the rear number plate
	gui.MaxDistance = INFO_DISTANCE + 30
	gui.AlwaysOnTop = true -- as in info(): a nearer pod's plate or walls must not hide the status
	gui.Enabled = false
	local label = textLabel(gui, { Font = StudStyle.Font })
	gui.Parent = shell.PrimaryPart
	self.labels[n] = { gui = gui, label = label, egg = egg, readyAt = readyAt, startedAt = startedAt }
end

-- Character proximity is independent of camera zoom. Only the owner's full-detail labels are built.
function PlotView:UpdateIncubatorLabels(position: Vector3?)
	local distance = math.huge
	if self.own and self.detail == "full" and position then
		local at = self.floor:PointToObjectSpace(position)
		for _, spot in INCUBATOR_SPOTS do
			distance = math.min(distance, Vector3.new(at.X - spot.X, 0, at.Z - spot.Z).Magnitude)
		end
	end
	self.incubatorNear = distance <= (if self.incubatorNear then INCUBATOR_NEAR_OUT else INCUBATOR_NEAR_IN)
	local fade = if self.incubatorNear then math.clamp((distance - INCUBATOR_FADE) / (INCUBATOR_NEAR_OUT - INCUBATOR_FADE), 0, 1) else 1
	for _, entry in self.labels do
		entry.gui.Enabled = fade < 1
		entry.label.TextTransparency = fade
		entry.label.TextStrokeTransparency = 0.3 + 0.7 * fade
	end
end

-- The field's row plates (every detail): overgrown grass under the whole shape, below the soil (no shared face).
function PlotView:buildField(model: Model)
	for row, width in CropConfig.RowWidths do
		part({
			CanQuery = self.own, -- the tap ray (U3a)
			Name = "Row" .. row,
			Size = Vector3.new(width * FIELD_PITCH, 0.3, FIELD_PITCH),
			CFrame = self:at(Vector3.new(0, -0.1, FIELD_FRONT + (row - 0.5) * FIELD_PITCH)),
			Color = COLORS.overgrown,
			Material = Enum.Material.Grass,
		}).Parent = model
	end
end

-- Locked square `square` (full detail, U3a): grass tufts on the row plate, so it looks overgrown next to the soil of open squares.
function PlotView:buildOvergrown(model: Model, square: number)
	local x, z = squareSpot(square)
	for i, tuft in TUFTS do
		local height = tuft[3]
		part({
			Name = "Tuft" .. i,
			Size = Vector3.new(0.7, height, 0.7),
			-- the plate's top is at 0.05: the tuft starts inside it (no shared face)
			CFrame = self:at(Vector3.new(x + tuft[1] * FIELD_PITCH, height / 2, z + tuft[2] * FIELD_PITCH)) * CFrame.Angles(0, math.rad(tuft[4]), 0),
			Color = tuft[5],
			Material = Enum.Material.Grass,
			CanCollide = false,
			CanQuery = self.own,
		}).Parent = model
	end
end

function PlotView:buildSquare(model: Model, square: number)
	local field = self.state.field
	local size = FIELD_PITCH - 0.4
	local x, z = squareSpot(square)
	local pets = self.petMap
	local index = (square - 1) * 2 + 1
	local letter = string.sub(field.crops, index, index)
	local stage = tonumber(string.sub(field.crops, index + 1, index + 1)) or 0
	if letter == "#" then
		return self:buildOvergrown(model, square)
	end
	local soil = part({ Name = "Soil" .. square, Size = Vector3.new(size, 0.4, size), CFrame = self:at(Vector3.new(x, 0.05, z)),
		Color = if letter == "." then COLORS.drySoil else COLORS.soil, Material = Enum.Material.Ground, CanQuery = self.own })
	soil.Parent = model
	if CROP_COLORS[letter] and stage > 0 and not growthCrop(field, square) then
		local height = 0.6 + stage * 0.7
		local width = size * (0.3 + stage * 0.15)
		local color = if stage >= 3 then CROP_COLORS[letter] else SPROUT
		part({ Name = "Crop", Size = Vector3.new(width, height, width), CFrame = self:at(Vector3.new(x, 0.25 + height / 2, z)), Color = color, CanQuery = self.own }).Parent = model
	end
	local pet = pets[square]
	local rarity = pet and PetConfig.RarityOf(pet.kind)
	if pet and rarity then
		-- the pet stands on the square's front corner, beside the crop
		local spot = Vector3.new(x + size * 0.28, 0, z - size * 0.28)
		if self.detail == "mid" then
			local cube = 1.4 * PetConfig.ScaleOf(pet.level)
			part({ Name = "Pet" .. square, Size = Vector3.new(cube, cube, cube), CFrame = self:at(spot + Vector3.new(0, 0.25 + cube / 2, 0)), Color = rarity.color }).Parent =
				model
		else
			local petModel = standingPet(pet.kind, pet.level, pet.uid, self:at(spot), soil.Position.Y + soil.Size.Y / 2, fieldPetLabel(pet.apt, pet.guard, nameOf(self.state, pet.uid)))
			if petModel then
				petModel.Name = "Pet" .. square
				petModel.Parent = model
			end
		end
	end
end

-- The public anchors are shared by the owner and visitors. Old/synthetic feeds
-- without anchors keep a static review pose, never a local guessed countdown.
function PlotView:plantGrowth(square: number, now: number): number
	local field = self.state and self.state.field
	local anchor = field and type(field.plants) == "table" and field.plants[tostring(square)]
	if type(anchor) == "table" and type(anchor.startAt) == "number" and type(anchor.readyAt) == "number" then
		if anchor.startAt == 0 and anchor.readyAt == 0 then return 1 end
		local duration = anchor.readyAt - anchor.startAt
		if duration > 0 then return math.clamp((now - anchor.startAt) / duration, 0, 1) end
	end
	local stage = field and tonumber(string.sub(field.crops, square * 2, square * 2)) or 0
	return if stage >= 3 then 1 elseif stage == 2 then 0.5 elseif stage == 1 then 0.2 else 0
end

function PlotView:plantStage(square: number): number
	local field = self.state and self.state.field
	local anchor = field and type(field.plants) == "table" and field.plants[tostring(square)]
	if not self:plantTimed(square) and not (type(anchor) == "table" and anchor.startAt == 0 and anchor.readyAt == 0) then
		return field and tonumber(string.sub(field.crops, square * 2, square * 2)) or 0
	end
	local growth = self:plantGrowth(square, workspace:GetServerTimeNow())
	local crop = growthCrop(field, square)
	if not crop then return 0 end
	return CropConfig.Stage(crop, growth * crop.growSeconds)
end

function PlotView:buildPlant(model: Model, square: number)
	local field = self.state.field
	local crop = growthCrop(field, square)
	if not crop then return end
	local anchor = type(field.plants) == "table" and field.plants[tostring(square)]
	local planting = anchor and anchor.n or square
	local sizeFactor = anchor and anchor.size or 1
	-- Same owner/planting prime mix as the deterministic Tending roll. Consecutive
	-- plantings still cycle all six silhouettes (104729 is coprime with six).
	local seed = (self.state.ownerId or self.slot) * 7919 + planting * 104729
	if self.detail == "mid" then
		PlantGrowth.BuildProxy(model, self:SquareCFrame(square), crop.id, self:plantStage(square), seed, sizeFactor)
		return
	end
	local plant = PlantGrowth.new(model, self:SquareCFrame(square), crop.id, seed, sizeFactor)
	local now = workspace:GetServerTimeNow()
	local growth = self:plantGrowth(square, now)
	plant:SetGrowth(growth)
	local nextAt = self:plantDue(square, growth, now, os.clock())
	self.plants[square] = { plant = plant, growth = growth, dirty = false, nextAt = nextAt, animated = self:plantTimed(square) }
	self.plantNextAt = math.min(self.plantNextAt, nextAt)
end

function PlotView:plantTimed(square: number): boolean
	local field = self.state and self.state.field
	local anchor = field and type(field.plants) == "table" and field.plants[tostring(square)]
	return type(anchor) == "table" and type(anchor.startAt) == "number" and type(anchor.readyAt) == "number" and anchor.readyAt > anchor.startAt
end

-- The registry scales cadence to the crop's duration. Schedule the exact ripe
-- boundary sooner when necessary; a review scrubber bypasses this scheduler.
function PlotView:plantDue(square: number, growth: number, now: number, clock: number): number
	if growth >= 1 or not self:plantTimed(square) then return math.huge end
	local anchor = self.state.field.plants[tostring(square)]
	local interval = PlantGrowth.UpdateInterval(anchor.readyAt - anchor.startAt)
	-- Spread square updates across the interval instead of posing a whole field
	-- in one frame. Ripeness can still arrive before the next regular sample.
	local offset = (square - 1 + (self.slot - 1) / GardenConfig.PlotSlots) / CropConfig.MaxSquares * interval
	local nextSample = (math.floor((now - offset) / interval) + 1) * interval + offset
	return clock + math.min(nextSample - now, math.max(0, anchor.readyAt - now))
end

function PlotView:HasGrowingPlants(): boolean
	return self.detail == "full" and os.clock() >= self.plantNextAt
end

-- Share the build deadline, with a rotating square cursor so a large field can
-- spread posing across frames. Ripe plants do no pose work until a correction.
function PlotView:StepPlants(deadline: number)
	if not self:HasGrowingPlants() then return end
	local now, clock = workspace:GetServerTimeNow(), os.clock()
	for _ = 1, CropConfig.MaxSquares do
		if os.clock() >= deadline then break end
		self.plantCursor = self.plantCursor % CropConfig.MaxSquares + 1
		local entry = self.plants[self.plantCursor]
		if entry and (entry.dirty or (entry.animated and entry.growth < 1)) and (entry.dirty or clock >= entry.nextAt) then
			local growth = self:plantGrowth(self.plantCursor, now)
			if growth ~= entry.growth then
				entry.plant:SetGrowth(growth)
				entry.growth = growth
			end
			entry.dirty = false
			entry.animated = self:plantTimed(self.plantCursor)
			entry.nextAt = self:plantDue(self.plantCursor, growth, now, clock)
		end
	end
	-- Include unvisited entries if the deadline interrupted this pass, so their
	-- overdue work resumes next frame rather than waiting another whole second.
	self.plantNextAt = math.huge
	for _, entry in self.plants do
		self.plantNextAt = math.min(self.plantNextAt, if entry.dirty then 0 else entry.nextAt)
	end
end

function PlotView:build(key: string): Model?
	if self:signature(key) == "none" then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = key
	if key == "base" then
		self:buildBase(model)
	elseif key == "hatch" then
		self:buildHatchery(model)
	elseif key == "barn" then
		self:buildBarn(model)
	elseif key == "field" then
		self:buildField(model)
	else
		local kind, number = string.match(key, "^(%a+)(%d+)$")
		local n = tonumber(number) :: number
		if kind == "inc" then
			self:buildIncubator(model, n)
		elseif kind == "grow" then
			self:buildPlant(model, n)
		else
			self:buildSquare(model, n)
		end
	end
	return model
end

-- Builds pending pieces until os.clock() passes `deadline` (at least one piece per call). True while work is left.
function PlotView:Step(deadline: number): boolean
	local builtAny = false
	while #self.pending > 0 do
		local key = table.remove(self.pending, 1)
		self.marked[key] = nil
		local signature = self:signature(key)
		if signature ~= (self.built[key] or "none") then
			builtAny = true
			if string.sub(key, 1, 4) == "grow" then
				local square = tonumber(string.sub(key, 5)) :: number
				local entry = self.plants[square]
				if entry then entry.plant:Destroy() end
				self.plants[square] = nil
			end
			if string.sub(key, 1, 3) == "inc" then
				local n = tonumber(string.sub(key, 4)) :: number
				self.labels[n] = nil
				self.incubatorLights[n] = nil
			end
			local model = self:build(key)
			if self.pieces[key] then
				self.pieces[key]:Destroy()
			end
			self.pieces[key] = model
			self.built[key] = signature
			if model then
				model.Parent = self.root -- one parent write per piece
			end
		end
		if os.clock() >= deadline then
			break
		end
	end
	self:StepPlants(deadline)
	if builtAny and #self.pending == 0 and self.tickNow then
		self:Tick(self.tickNow)
	end
	return #self.pending > 0
end

-- Tints `squares` of the field (the squares a pet would work, E1b) until called again; nil clears.
function PlotView:ShowReach(squares: { number }?)
	if self.reach then
		self.reach:Destroy()
		self.reach = nil
	end
	local field = self.state and self.state.field
	if not (squares and field and (self.detail == "full" or self.detail == "mid")) then
		return
	end
	local tint = Instance.new("Model")
	tint.Name = "Reach"
	for _, square in squares do
		local x, z = squareSpot(square)
		part({
			Name = "Reach" .. square,
			Size = Vector3.new(FIELD_PITCH - 0.2, 0.1, FIELD_PITCH - 0.2),
			CFrame = self:at(Vector3.new(x, 0.33, z)), -- just above the soil top (0.25): no shared face
			Color = REACH,
			Material = Enum.Material.Neon,
			Transparency = 0.6,
			CanCollide = false,
		}).Parent = tint
	end
	tint.Parent = self.root
	self.reach = tint
end

-- Thin borders around field regions (U3b: the squares each placed pet counts for), until called again; nil or {} clears.
-- `borders` = { { squares = { number }, color = Color3, lane = 0..2 } }: one border per entry along the outer edges of its region
-- (collinear edges of neighbouring squares merged into one strip), BORDER_INSET + lane x BORDER_LANE studs inside the edge, so
-- two regions that share an edge draw side by side; a strip ends where its perpendicular neighbour runs (shorter at an outer
-- corner, longer at an inner one). Not Neon: a light rarity colour must not glow white like the select outline. 0.26-0.32 over the floor centre: above the soil top (0.25), under the reach
-- tint (0.28-0.38) and the select outline (0.30-0.46) without a shared face.
function PlotView:ShowBorders(borders)
	if self.borders then
		self.borders:Destroy()
		self.borders = nil
	end
	if not (borders and #borders > 0 and (self.detail == "full" or self.detail == "mid")) then
		return
	end
	local G = CropConfig.GridColumns
	local model = Instance.new("Model")
	model.Name = "Borders"
	for index, border in borders do
		local inside = {}
		for _, n in border.squares do
			local row, col = CropConfig.Cell(n)
			if row then
				inside[row * 100 + col] = true
			end
		end
		local inset = BORDER_INSET + (border.lane or 0) * BORDER_LANE
		-- runs[key] = sorted positions along the edge line; key = axis .. side .. line
		local runs = {}
		local function add(key: string, at: number)
			runs[key] = runs[key] or {}
			table.insert(runs[key], at)
		end
		for key in inside do
			local row, col = key // 100, key % 100
			if not inside[(row - 1) * 100 + col] then
				add("z-" .. row, col)
			end
			if not inside[(row + 1) * 100 + col] then
				add("z+" .. row, col)
			end
			if not inside[row * 100 + col - 1] then
				add("x-" .. col, row)
			end
			if not inside[row * 100 + col + 1] then
				add("x+" .. col, row)
			end
		end
		local function strip(center: Vector3, size: Vector3)
			part({
				Name = "Border" .. index,
				Size = size,
				CFrame = self:at(center),
				Color = border.color,
				Material = Enum.Material.SmoothPlastic,
				Transparency = 0.1,
				CanCollide = false,
			}).Parent = model
		end
		for key, list in runs do
			table.sort(list)
			local axis, side, line = string.sub(key, 1, 1), string.sub(key, 2, 2), tonumber(string.sub(key, 3)) :: number
			local first = 1
			for i = 1, #list do
				if i == #list or list[i + 1] ~= list[i] + 1 then
					local a, b = list[first], list[i]
					first = i + 1
					-- each end: the next cell along the run inside the region = an inner corner (reach past the cell's edge to
					-- the perpendicular strip), outside = an outer corner (stop short of it)
					if axis == "z" then
						-- an edge along x at the front (-) or back (+) of row `line`, columns a..b
						local z = FIELD_FRONT + (if side == "-" then line - 1 else line) * FIELD_PITCH + (if side == "-" then inset else -inset)
						local x0 = (a - 1 - G / 2) * FIELD_PITCH + (if inside[line * 100 + a - 1] then -inset else inset)
						local x1 = (b - G / 2) * FIELD_PITCH + (if inside[line * 100 + b + 1] then inset else -inset)
						strip(Vector3.new((x0 + x1) / 2, 0.29, z), Vector3.new(math.max(x1 - x0, 0.5), 0.06, BORDER_WIDTH))
					else
						-- an edge along z at the left (-) or right (+) of column `line`, rows a..b
						local x = (if side == "-" then line - 1 else line) * FIELD_PITCH - G / 2 * FIELD_PITCH + (if side == "-" then inset else -inset)
						local z0 = FIELD_FRONT + (a - 1) * FIELD_PITCH + (if inside[(a - 1) * 100 + line] then -inset else inset)
						local z1 = FIELD_FRONT + b * FIELD_PITCH + (if inside[(b + 1) * 100 + line] then inset else -inset)
						strip(Vector3.new(x, 0.29, (z0 + z1) / 2), Vector3.new(BORDER_WIDTH, 0.06, math.max(z1 - z0, 0.5)))
					end
				end
			end
		end
	end
	model.Parent = self.root
	self.borders = model
end

-- The field square under world point `position` (its grid cell, locked squares and the paths between squares included), or nil
-- off the field (U3a: FieldHand's tap).
function PlotView:SquareAt(position: Vector3): number?
	local offset = self.floor:PointToObjectSpace(position)
	local col = math.floor(offset.X / FIELD_PITCH + CropConfig.GridColumns / 2) + 1
	local row = math.floor((offset.Z - FIELD_FRONT) / FIELD_PITCH) + 1
	return CropConfig.SquareAt(row, col)
end

-- World CFrame of the middle of field square `square` at the soil's top (rings, pops).
function PlotView:SquareCFrame(square: number): CFrame
	local x, z = squareSpot(square)
	return self:at(Vector3.new(x, 0.25, z))
end

-- White outline around field square `square` (the selected square, U3a) until called again; nil clears.
function PlotView:ShowSelect(square: number?)
	if self.select then
		self.select:Destroy()
		self.select = nil
	end
	if not square or not CropConfig.Cell(square) then
		return
	end
	local x, z = squareSpot(square)
	local outline = Instance.new("Model")
	outline.Name = "Select"
	local half, thick = (FIELD_PITCH - 0.4) / 2 + 0.05, 0.3
	for _, edge in {
		{ Vector3.new(0, 0, -half), Vector3.new(2 * half + thick, 0.16, thick) },
		{ Vector3.new(0, 0, half), Vector3.new(2 * half + thick, 0.16, thick) },
		{ Vector3.new(-half, 0, 0), Vector3.new(thick, 0.16, 2 * half - thick) },
		{ Vector3.new(half, 0, 0), Vector3.new(thick, 0.16, 2 * half - thick) },
	} do
		part({
			Name = "Edge",
			Size = edge[2],
			-- 0.30-0.46 over the floor centre: above the soil top (0.25) and the reach tint (0.28-0.38), no shared face
			CFrame = self:at(Vector3.new(x, 0.38, z) + edge[1]),
			Color = Color3.new(1, 1, 1),
			Material = Enum.Material.Neon,
			CanCollide = false,
		}).Parent = outline
	end
	outline.Parent = self.root
	self.select = outline
end

-- Four white corner brackets on field square `square` (the square the player stands on, U3b: shows that squares are things to
-- tap) until called again; nil clears. Brackets, not a full outline: a full thin line reads as a pet's reach border (Common grey).
-- 0.33-0.41 over the floor centre: inside the select outline's height (0.30-0.46) and off the reach tint's faces (0.28-0.38), no
-- shared face; outside the borders' strips. The two strips of a corner do not overlap.
function PlotView:ShowHover(square: number?)
	if self.hover then
		self.hover:Destroy()
		self.hover = nil
	end
	if not square or not CropConfig.Cell(square) then
		return
	end
	local x, z = squareSpot(square)
	local marks = Instance.new("Model")
	marks.Name = "Hover"
	local half, thick, arm = (FIELD_PITCH - 0.4) / 2 + 0.05, 0.18, 1.4
	local function strip(center: Vector3, size: Vector3)
		part({
			Name = "Corner",
			Size = size,
			CFrame = self:at(Vector3.new(x, 0.37, z) + center),
			Color = Color3.new(1, 1, 1),
			Material = Enum.Material.SmoothPlastic,
			Transparency = 0.2,
			CanCollide = false,
		}).Parent = marks
	end
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			-- along x: from half - arm to the outer edge of the corner; along z: from half - arm up to the x strip
			strip(Vector3.new(sx * (half - arm / 2 + thick / 4), 0, sz * half), Vector3.new(arm + thick / 2, 0.08, thick))
			strip(Vector3.new(sx * half, 0, sz * (half - arm / 2 - thick / 4)), Vector3.new(thick, 0.08, arm - thick / 2))
		end
	end
	marks.Parent = self.root
	self.hover = marks
end

-- Updates the countdowns of the drawn eggs (server time `now`, workspace:GetServerTimeNow()).
function PlotView:Tick(now: number)
	self.tickNow = now
	-- Only registered plant squares need a stage refresh at mid distance. No scan of
	-- unrelated plot pieces, and no full plant posing here.
	local field = self.state and self.state.field
	if self.detail == "mid" and field and type(field.plants) == "table" then
		for square in field.plants do
			if growthCrop(field, tonumber(square) :: number) then
				local key = "grow" .. square
				if not self.marked[key] and self:signature(key) ~= (self.built[key] or "none") then
					self.marked[key] = true
					table.insert(self.pending, key)
				end
			end
		end
	end
	for _, body in self.incubatorLights do
		body.setState(GardenConfig.EggPhase(body.startedAt, body.readyAt, now))
	end
	for _, entry in self.labels do
		if entry.egg then
			local remaining = (entry.readyAt or 0) - now
			local phase = GardenConfig.EggPhase(entry.startedAt, entry.readyAt or 0, now)
			entry.label.Text = Locale.EggName(entry.egg) .. "\n" .. (if phase == "scanning" then Locale.T("incubator.scanning")
				elseif remaining > 0 then TimeFormat.Clock(remaining) else Locale.T("incubator.label.ready"))
		end
	end
end

function PlotView:AnimateIncubators(now: number)
	for _, body in self.incubatorLights do
		body.animate(now, body.startedAt)
	end
end

function PlotView:Destroy()
	for _, entry in self.plants do entry.plant:Destroy() end
	self.plants = {}
	self.root:Destroy()
	self.pieces = {}
	self.pending = {}
	self.labels = {}
	self.incubatorLights = {}
end

return PlotView
