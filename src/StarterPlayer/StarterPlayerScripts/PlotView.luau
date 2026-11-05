-- PlotView (E1a1, docs/EXPANSION.md §16): draws one garden plot on the client from a plain state table (GardenRemotes.Plot,
-- GardenPlotFeed), at its slot's position (GardenConfig.PlotCFrame), in one of four details: "full" (floor, edges, sign, pens
-- with pet models and labels, incubators with egg and live countdown, pad / incubator billboards, prompts on the own plot),
-- "mid" (the same without billboards and prompts, each pet one block in its rarity colour), "low" (floor, one block per pet and
-- egg, the field as its row plates) or "none". Stand-in blocks only (no art pass). Used by GardenView, which picks the detail.
-- A plot is split into pieces (base, pen1..6, inc1..3, field = the row plates, sq1..36). SetState / SetDetail / Relabel only
-- mark the pieces whose look changed; Step builds marked pieces until a deadline, so a build is spread over frames by the caller.
-- State: { name, penCount, pens = { [1..6] = "Kind:Level:uid" or "" }, incCount, eggs = { [1..3] = "EggId:readyAt" or "" },
-- field = { crops = two characters per square 1..CropConfig.MaxSquares: crop letter (CropConfig, a-f in synthetic plots) +
-- stage 1-3 (3 = ripe), ".0" an empty open square, "#0" a locked one, pets = { "Kind:Level:uid:square:tending:guard" } (E1b field pets,
-- tending / guard = Tending / Pest-control level, 0 without it; E4b; a feed without guard reads as 0) }, converted (E1b: the pens became field pet slots: no pens, the floor shrinks to the incubator strip and
-- the field starts behind it) } or { free = true } (a slot nobody holds: floor, sign "Free plot", grey pads and incubators).
-- The field (E1d2) has the shape CropConfig.RowWidths: every row is a plate of overgrown grass, open squares are soil on it.
-- Field pets stand on their squares (full: the PetLook model, mid: a block); the own plot's squares also get a pet prompt
-- (onSquare(square, "pet", soil), key F), its locked squares a buy prompt (onSquare(square, "buy", holder)), and ShowReach
-- tints the squares a pet would work.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local PetLook = require(ReplicatedStorage:WaitForChild("PetLook"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))

local PetModels = ReplicatedStorage:WaitForChild("PetModels")

-- floor-space layout, copied from the former Studio plots (Workspace.Garden.Plots.Plot_NN, deleted in E1a1)
local PEN_SPOTS = {
	Vector3.new(-12, 0.4, 4),
	Vector3.new(0, 0.4, 4),
	Vector3.new(12, 0.4, 4),
	Vector3.new(-12, 0.4, 15),
	Vector3.new(0, 0.4, 15),
	Vector3.new(12, 0.4, 15),
}
local INCUBATOR_SPOTS = { Vector3.new(-12, 0, -10), Vector3.new(0, 0, -10), Vector3.new(12, 0, -10) }
local STRIP_FRONT, STRIP_BACK = -20, -4 -- a converted plot's floor: the strip that holds the sign side and the incubators
local FIELD_FRONT = -2 -- the field lies behind the strip (floor +Z), from this far behind the centre
local FIELD_PITCH = 5.5 -- studs per square
local BUY_HOLD = 0.5 -- seconds a buy prompt is held
local INFO_DISTANCE = 60 -- studs: pad / incubator billboards and pet labels
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
	padFree = Color3.fromRGB(150, 150, 150),
	padEmpty = Color3.fromRGB(110, 190, 110),
	padLocked = Color3.fromRGB(80, 80, 80),
	base = Color3.fromRGB(150, 100, 60),
	nest = Color3.fromRGB(225, 195, 110),
	soil = Color3.fromRGB(105, 70, 45),
	overgrown = Color3.fromRGB(78, 120, 52), -- the field's row plates: locked squares and the paths between squares
}
local SPROUT = Color3.fromRGB(110, 190, 80) -- unripe crops (stage 1-2)
local REACH = Color3.fromRGB(255, 230, 120) -- ShowReach tint
local CROP_COLORS = { -- ripe crops, by letter (CropConfig: a Potato, b Corn, c Pumpkin, d Giant melon, E2a rare: e Golden carrot, f Frost grape, g Glow mushroom)
	a = Color3.fromRGB(196, 150, 90),
	b = Color3.fromRGB(245, 210, 60),
	c = Color3.fromRGB(240, 130, 40),
	d = Color3.fromRGB(80, 170, 70),
	e = Color3.fromRGB(255, 190, 40),
	f = Color3.fromRGB(150, 120, 230),
	g = Color3.fromRGB(110, 230, 220),
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

local function countdown(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	if seconds >= 3600 then
		return string.format("%d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
	end
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

-- "Kind:Level:uid" → kind, level, uid (nil for "")
local function parsePet(text: string?): (string?, number?, string?)
	if type(text) ~= "string" or text == "" then
		return nil, nil, nil
	end
	local kind, level, uid = string.match(text, "^([^:]+):(%d+):(.*)$")
	return kind, tonumber(level), uid
end
PlotView.ParsePet = parsePet

-- The filtered name of the owner's pet `uid` (P3b): GardenView puts the owner's PetConfig.NamesAttribute into state.names.
local function nameOf(state, uid: string?): string?
	local names = state and state.names
	return if names and uid then names[uid] else nil
end

-- "EggId:readyAt" → egg id, readyAt (nil for "")
local function parseEgg(text: string?): (string?, number?)
	if type(text) ~= "string" or text == "" then
		return nil, nil
	end
	local egg, readyAt = string.match(text, "^([^:]+):(%d+)$")
	return egg, tonumber(readyAt)
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

-- Number of open squares in a field message ("#0" = locked).
local function openOf(field): number
	local _, locked = string.gsub(field.crops, "#", "")
	return CropConfig.MaxSquares - locked
end

-- New view of plot slot `slot` under `parent`. options: { own = boolean, onPen = fn(pen, pad), onIncubator = fn(n, base),
-- onSquare = fn(square, action "plant" / "harvest", soil), onLevelUp = fn(model, kind, level) } (prompts on the own plot only;
-- onLevelUp for a pet that levelled up in its pen).
function PlotView.new(slot: number, parent: Instance, options)
	local self = setmetatable({}, PlotView)
	self.slot = slot
	self.floor = GardenConfig.PlotCFrame(slot) :: CFrame
	self.own = options and options.own or false
	self.onPen = options and options.onPen
	self.onIncubator = options and options.onIncubator
	self.onSquare = options and options.onSquare
	self.onLevelUp = options and options.onLevelUp
	self.detail = "none"
	self.state = nil
	self.lang = Locale.Current()
	self.built = {} -- [key] = signature of the drawn piece
	self.pieces = {} -- [key] = Model
	self.pending = {} -- ordered keys whose signature changed
	self.marked = {} -- [key] = true while pending
	self.squares = 0 -- most field squares ever drawn (squares beyond the current field are cleared)
	self.petMap = {} -- [square] = field pet of the current state (fieldPets)
	self.labels = {} -- [incubator] = { label, egg, readyAt } of drawn countdowns
	self.levelUps = {} -- [pen] = level the pet in that pen just reached (played when the pen is next drawn in full)
	self.root = Instance.new("Model")
	self.root.Name = string.format("Slot_%02d", slot)
	self.root.Parent = parent
	return self
end

function PlotView:keys(): { string }
	local keys = { "base" }
	for n = 1, GardenConfig.MaxPens do
		table.insert(keys, "pen" .. n)
	end
	for n = 1, GardenConfig.MaxIncubators do
		table.insert(keys, "inc" .. n)
	end
	table.insert(keys, "field")
	local field = self.state and self.state.field
	self.squares = math.max(self.squares, if field then CropConfig.MaxSquares else 0)
	for n = 1, self.squares do
		table.insert(keys, "sq" .. n)
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
		return table.concat({ detail, if state.free then "" else tostring(state.name), tostring(not state.free and state.converted == true), self.lang }, "|")
	end
	if key == "field" then
		return if not state.free and state.field then detail else "none"
	end
	local kind, number = string.match(key, "^(%a+)(%d+)$")
	local n = tonumber(number) :: number
	if state.free then
		return if kind == "sq" or detail == "low" then "none" else detail .. "|free"
	end
	if kind == "pen" then
		if state.converted then
			return "none" -- the pens became field pet slots (E1b)
		end
		local _, _, uid = parsePet(state.pens[n])
		return table.concat({ detail, state.pens[n] or "", nameOf(state, uid) or "", tostring(n <= state.penCount), tostring(self.own), self.lang }, "|")
	elseif kind == "inc" then
		return table.concat({ detail, state.eggs[n] or "", tostring(n <= state.incCount), tostring(self.own), self.lang }, "|")
	end
	local field = state.field
	if not field or n > CropConfig.MaxSquares or detail == "low" then
		return "none"
	end
	local cell = string.sub(field.crops, (n - 1) * 2 + 1, n * 2)
	if string.sub(cell, 1, 1) == "#" then
		-- a locked square is the row plate; only the own plot draws a buy prompt on it, with the price of the next square
		return if self.own and detail == "full" then string.format("lock|%d|%s", openOf(field), self.lang) else "none"
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
	local old = self.state
	if old and not old.free and not state.free then
		-- the same pet in the same pen at a higher level: a level-up (placing, removing and first sight never count)
		for n = 1, GardenConfig.MaxPens do
			local _, oldLevel, oldUid = parsePet(old.pens[n])
			local _, level, uid = parsePet(state.pens[n])
			if uid and uid == oldUid and level and oldLevel and level > oldLevel then
				self.levelUps[n] = level
			end
		end
	end
	self.state = state
	self.petMap = fieldPets(state.field)
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

-- The drawn piece `key` ("pen1", "inc2", ...), or nil.
function PlotView:Piece(key: string): Model?
	return self.pieces[key]
end

-- Piece builders: each returns the filled Model (not parented yet) -------------------------------------------------------

function PlotView:at(offset: Vector3): CFrame
	return self.floor * CFrame.new(offset)
end

function PlotView:buildBase(model: Model)
	-- a converted plot (E1b, E1d2) keeps only the incubator strip: the field starts right behind it
	local front, back = -20, 20
	if not self.state.free and self.state.converted then
		front, back = STRIP_FRONT, STRIP_BACK
	end
	local depth, middle = back - front, (front + back) / 2
	local floor = part({ Name = "Floor", Size = Vector3.new(40, 0.5, depth), CFrame = self:at(Vector3.new(0, 0, middle)), Color = COLORS.floor, Material = Enum.Material.Grass })
	floor.CanQuery = true -- something to stand on and to raycast
	floor.Parent = model
	if self.detail == "low" then
		return
	end
	for _, edge in {
		{ Vector3.new(-20.4, 0.65, middle), Vector3.new(0.8, 1, depth + 0.8) },
		{ Vector3.new(20.4, 0.65, middle), Vector3.new(0.8, 1, depth + 0.8) },
		{ Vector3.new(0, 0.65, back + 0.4), Vector3.new(40.8, 1, 0.8) },
		{ Vector3.new(0, 0.65, front - 0.4), Vector3.new(40.8, 1, 0.8) },
	} do
		part({ Name = "Edge", Size = edge[2], CFrame = self:at(edge[1]), Color = COLORS.edge, Material = Enum.Material.Wood }).Parent = model
	end
	self:buildSign(model)
end

-- The name sign in front of the plot, in the stud look of the garden's hub sign (Inlets texture): two posts high enough to
-- walk between and under (the board's lowest edge is SIGN_CLEAR above the floor) and a board with tan frame bars and steel
-- collars. No two parts share a face plane (z-fighting).
function PlotView:buildSign(model: Model)
	local z = -22
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
	textLabel(gui, {
		Name = "Number",
		Position = UDim2.new(0, 10, 0, 6),
		Size = UDim2.new(1, -20, 0, 30),
		TextScaled = false,
		TextSize = 28,
		Font = StudStyle.Font,
		TextColor3 = COLORS.signNumber,
		TextStrokeColor3 = Color3.new(0, 0, 0),
		TextStrokeTransparency = 0.6,
		Text = Locale.T("sign.plot", { n = self.slot }),
	})
	textLabel(gui, {
		Name = "Name",
		Position = UDim2.new(0, 14, 0, 36),
		Size = UDim2.new(1, -28, 1, -44),
		Font = StudStyle.Font,
		TextColor3 = COLORS.signText,
		TextStrokeColor3 = Color3.new(0, 0, 0),
		TextStrokeTransparency = 0.5,
		-- a player name (no translation)
		Text = if self.state.free then Locale.T("garden.sign.plotFree") else tostring(self.state.name),
	})
	gui.Parent = sign
end

-- Label over a penned pet: name, level, tier stars and its Coins per hour (before the pet bonus).
local function penLabel(kind: string, level: number, name: string?): string
	local rate = GardenConfig.RatePerHour({ Kind = kind, Level = level })
	return Locale.T("garden.penPet.label", {
		pet = Locale.PetName(kind, level, name),
		stars = PetLook.TierStars(level),
		rate = { key = "garden.rate", args = { rate = { decimal = string.format("%g", rate) } } },
	})
end

-- Pet model standing at `at` (its pivot's horizontal position) on a surface whose top is at height `top` (full detail): a PetModels
-- clone dressed by PetLook like the followers, with `text` over it.
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

-- Pet model standing on `pad` (full detail).
local function penPet(kind: string, level: number, uid: string, pad: BasePart, name: string?): Model?
	return standingPet(kind, level, uid, pad.CFrame, pad.Position.Y + pad.Size.Y / 2, penLabel(kind, level, name))
end

-- Label over a field pet: name, level, tier stars and its jobs' levels (Tending, Pest control; E4b).
local function fieldPetLabel(kind: string, level: number, apt: number, guard: number, name: string?): string
	local jobs = {}
	if apt > 0 then
		table.insert(jobs, Locale.T("pets.tending", { level = apt }))
	end
	if guard > 0 then
		table.insert(jobs, Locale.T("pets.guard", { level = guard }))
	end
	return Locale.T("field.pet.label", { pet = Locale.PetName(kind, level, name), stars = PetLook.TierStars(level), jobs = table.concat(jobs, " · ") })
end

function PlotView:buildPen(model: Model, n: number)
	local state = self.state
	local spot = PEN_SPOTS[n]
	local levelUp = self.levelUps[n]
	self.levelUps[n] = nil
	if state.free then
		part({ Name = "Pad", Size = Vector3.new(9, 0.3, 9), CFrame = self:at(spot), Color = COLORS.padFree, Material = Enum.Material.SmoothPlastic }).Parent = model
		return
	end
	local kind, level, uid = parsePet(state.pens[n])
	local rarity = kind and PetConfig.RarityOf(kind)
	if self.detail == "low" then
		if kind and rarity then
			local size = 2 * PetConfig.ScaleOf(level :: number)
			part({ Name = "Pet", Size = Vector3.new(size, size, size), CFrame = self:at(spot + Vector3.new(0, size / 2 + 0.15, 0)), Color = rarity.color }).Parent = model
		end
		return
	end
	local locked = n > state.penCount
	local color = if locked then COLORS.padLocked elseif rarity then COLORS.padEmpty:Lerp(rarity.color, 0.45) else COLORS.padEmpty
	local pad = part({ Name = "Pad", Size = Vector3.new(9, 0.3, 9), CFrame = self:at(spot), Color = color, Material = Enum.Material.SmoothPlastic })
	pad.Parent = model
	if kind and rarity then
		if self.detail == "mid" then
			local size = 2 * PetConfig.ScaleOf(level :: number)
			part({ Name = "Pet", Size = Vector3.new(size, size, size), CFrame = self:at(spot + Vector3.new(0, 0.15 + size / 2, 0)), Color = rarity.color }).Parent = model
		else
			local pet = penPet(kind, level :: number, uid :: string, pad, nameOf(state, uid))
			if pet then
				pet.Name = "Pet"
				pet.Parent = model
				if levelUp == level and self.onLevelUp then
					task.defer(self.onLevelUp, pet, kind, level)
				end
			end
		end
	elseif self.detail == "full" then
		info(pad, UDim2.new(5, 0, 1.6, 0), 2.5, Locale.T(if locked then "garden.sign.pen.locked" else "garden.sign.pen.empty", { n = n }))
	end
	if self.own and self.onPen and self.detail == "full" then
		prompt(pad, Locale.T("garden.prompt.openPen"), Locale.T("garden.prompt.pen", { n = n }), 12, function()
			self.onPen(n, pad)
		end)
	end
end

function PlotView:buildIncubator(model: Model, n: number)
	local state = self.state
	local spot = INCUBATOR_SPOTS[n]
	self.labels[n] = nil
	local baseCFrame = self:at(spot + Vector3.new(0, 0.85, 0))
	local nestCFrame = self:at(spot + Vector3.new(0, 1.65, 0))
	if state.free then
		part({ Name = "Base", Size = Vector3.new(6, 1.2, 6), CFrame = baseCFrame, Color = COLORS.base, Material = Enum.Material.WoodPlanks }).Parent = model
		part({ Name = "Nest", Size = Vector3.new(4.4, 0.4, 4.4), CFrame = nestCFrame, Color = COLORS.nest, Material = Enum.Material.Fabric }).Parent = model
		return
	end
	local eggId, readyAt = parseEgg(state.eggs[n])
	local egg = eggId and PetConfig.Eggs[eggId]
	local look = egg and egg.look
	local eggColor = if look then look.color else Color3.fromRGB(236, 228, 208)
	if self.detail == "low" then
		if eggId then
			part({ Name = "Egg", Shape = Enum.PartType.Ball, Size = Vector3.new(2.8, 2.8, 2.8), CFrame = nestCFrame, Color = eggColor }).Parent = model
		end
		return
	end
	local locked = n > state.incCount
	local base = part({ Name = "Base", Size = Vector3.new(6, 1.2, 6), CFrame = baseCFrame, Color = if locked then COLORS.padLocked else COLORS.base, Material = Enum.Material.WoodPlanks })
	base.Parent = model
	part({ Name = "Nest", Size = Vector3.new(4.4, 0.4, 4.4), CFrame = nestCFrame, Color = COLORS.nest, Material = Enum.Material.Fabric }).Parent = model
	if self.own and self.onIncubator and self.detail == "full" then
		prompt(base, Locale.T("garden.prompt.openIncubator"), Locale.T("garden.prompt.incubator", { n = n }), 10, function()
			self.onIncubator(n, base)
		end)
	end
	if not eggId then
		if self.detail == "full" then
			info(base, UDim2.new(6, 0, 2.2, 0), 3, Locale.T(if locked then "garden.sign.incubator.locked" else "garden.sign.incubator.empty", { n = n }))
		end
		return
	end
	local ball = part({
		Name = "Egg",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.8, 2.8, 2.8),
		CFrame = self:at(spot + Vector3.new(0, 3.25, 0)),
		Color = eggColor,
		Material = if look and look.material then look.material else Enum.Material.SmoothPlastic,
	})
	ball.Parent = model
	if self.detail ~= "full" then
		return
	end
	if look and look.glow then
		local light = Instance.new("PointLight")
		light.Color = look.color
		light.Range = 8
		light.Brightness = 1.5
		light.Parent = ball
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "Info"
	gui.AutoLocalize = false
	gui.Size = UDim2.new(6, 0, 1.6, 0)
	gui.StudsOffset = Vector3.new(0, 2.6, 0)
	gui.MaxDistance = INFO_DISTANCE + 30
	local label = textLabel(gui, { Font = StudStyle.Font })
	gui.Parent = ball
	self.labels[n] = { label = label, egg = egg, readyAt = readyAt }
end

-- The field's row plates (every detail): overgrown grass under the whole shape, below the soil (no shared face).
function PlotView:buildField(model: Model)
	for row, width in CropConfig.RowWidths do
		part({
			Name = "Row" .. row,
			Size = Vector3.new(width * FIELD_PITCH, 0.3, FIELD_PITCH),
			CFrame = self:at(Vector3.new(0, -0.1, FIELD_FRONT + (row - 0.5) * FIELD_PITCH)),
			Color = COLORS.overgrown,
			Material = Enum.Material.Grass,
		}).Parent = model
	end
end

-- The own plot's buy prompt on locked square `square` (full detail): the price and Renown of the next square, whichever is picked.
function PlotView:buildLock(model: Model, square: number)
	local expansion = CropConfig.NextExpansion(openOf(self.state.field))
	if not (expansion and self.onSquare) then
		return
	end
	local x, z = squareSpot(square)
	local holder = part({
		Name = "Lock" .. square,
		Size = Vector3.new(FIELD_PITCH - 0.4, 0.2, FIELD_PITCH - 0.4),
		CFrame = self:at(Vector3.new(x, 0.15, z)),
		Transparency = 1,
		CanCollide = false,
	})
	holder.Parent = model
	local price = if expansion.renown > 0
		then Locale.T("field.prompt.priceRenown", { count = expansion.price, level = expansion.renown })
		else Locale.T("field.prompt.price", { count = expansion.price })
	local buy = prompt(holder, Locale.T("field.prompt.buySquare"), price, 6, function()
		self.onSquare(square, "buy", holder)
	end)
	buy.HoldDuration = BUY_HOLD
end

function PlotView:buildSquare(model: Model, square: number)
	local field = self.state.field
	local size = FIELD_PITCH - 0.4
	local x, z = squareSpot(square)
	local prompts = self.own and self.onSquare and self.detail == "full"
	local pets = self.petMap
	local index = (square - 1) * 2 + 1
	local letter = string.sub(field.crops, index, index)
	local stage = tonumber(string.sub(field.crops, index + 1, index + 1)) or 0
	if letter == "#" then
		return self:buildLock(model, square)
	end
	local soil = part({ Name = "Soil" .. square, Size = Vector3.new(size, 0.4, size), CFrame = self:at(Vector3.new(x, 0.05, z)), Color = COLORS.soil, Material = Enum.Material.Ground })
	soil.Parent = model
	if CROP_COLORS[letter] and stage > 0 then
		local height = 0.6 + stage * 0.7
		local width = size * (0.3 + stage * 0.15)
		local color = if stage >= 3 then CROP_COLORS[letter] else SPROUT
		part({ Name = "Crop", Size = Vector3.new(width, height, width), CFrame = self:at(Vector3.new(x, 0.25 + height / 2, z)), Color = color }).Parent = model
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
			local petModel = standingPet(pet.kind, pet.level, pet.uid, self:at(spot), soil.Position.Y + soil.Size.Y / 2, fieldPetLabel(pet.kind, pet.level, pet.apt, pet.guard, nameOf(self.state, pet.uid)))
			if petModel then
				petModel.Name = "Pet" .. square
				petModel.Parent = model
			end
		end
	end
	if prompts then
		local petPrompt = prompt(
			soil,
			Locale.T(if pet then "field.prompt.movePet" else "field.prompt.placePet"),
			if pet then Locale.PetName(pet.kind, pet.level, nameOf(self.state, pet.uid)) else Locale.T("field.prompt.square", { n = square }),
			6,
			function()
				self.onSquare(square, "pet", soil)
			end
		)
		petPrompt.Name = "PetPrompt"
		petPrompt.KeyboardKeyCode = Enum.KeyCode.F
		petPrompt.GamepadKeyCode = Enum.KeyCode.ButtonY
		petPrompt.UIOffset = Vector2.new(0, 72) -- below the plant / harvest prompt of the same square
	end
	local crop = CropConfig.ByLetter[letter]
	if prompts and (letter == "." or (crop and stage >= 3)) then
		local action = if letter == "." then "plant" else "harvest"
		prompt(
			soil,
			Locale.T(if action == "plant" then "field.prompt.plant" else "field.prompt.harvest"),
			if crop then Locale.CropName(crop) else Locale.T("field.prompt.square", { n = square }),
			6,
			function()
				self.onSquare(square, action, soil)
			end
		)
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
	elseif key == "field" then
		self:buildField(model)
	else
		local kind, number = string.match(key, "^(%a+)(%d+)$")
		local n = tonumber(number) :: number
		if kind == "pen" then
			self:buildPen(model, n)
		elseif kind == "inc" then
			self:buildIncubator(model, n)
		else
			self:buildSquare(model, n)
		end
	end
	return model
end

-- Builds pending pieces until os.clock() passes `deadline` (at least one piece per call). True while work is left.
function PlotView:Step(deadline: number): boolean
	while #self.pending > 0 do
		local key = table.remove(self.pending, 1)
		self.marked[key] = nil
		local signature = self:signature(key)
		if signature ~= (self.built[key] or "none") then
			if string.sub(key, 1, 3) == "inc" then
				self.labels[tonumber(string.sub(key, 4)) :: number] = nil
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
	if #self.pending == 0 and self.tickNow then
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

-- Updates the countdowns of the drawn eggs (server time `now`, workspace:GetServerTimeNow()).
function PlotView:Tick(now: number)
	self.tickNow = now
	for _, entry in self.labels do
		local name = if entry.egg then Locale.EggName(entry.egg) else ""
		local remaining = (entry.readyAt or 0) - now
		entry.label.Text = name .. "\n" .. (if remaining > 0 then countdown(remaining) else Locale.T("incubator.label.ready"))
	end
end

function PlotView:Destroy()
	self.root:Destroy()
	self.pieces = {}
	self.pending = {}
	self.labels = {}
end

return PlotView
