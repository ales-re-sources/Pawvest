-- PlotView (E1.0 spike, docs/ROADMAP.md → E1.0, docs/EXPANSION.md §16): draws one garden plot on the client from a plain
-- state table, at its slot's position (GardenConfig.PlotCFrame), in one of three details: "full" (floor, edges, sign, pens
-- with pet models, incubators with a live countdown, field squares with crop stand-ins), "low" (floor, one block per pet
-- and egg, the field as one patch) or "none". Stand-in blocks only (no art pass).
-- A plot is split into pieces (base, pen1..6, inc1..3, row1..n of the field). SetState / SetDetail only mark the pieces
-- whose look changed; Step builds marked pieces until a deadline, so a build is spread over frames by the caller.
-- State: { name, penCount, pens = { [1..6] = "Kind:Level:uid" or "" }, incCount, eggs = { [1..3] = "EggId:readyAt" or "" },
-- field = { cols, rows, crops = two characters per square: crop letter a-f (or "." for none) + stage 0-3 } }.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local PetLook = require(ReplicatedStorage:WaitForChild("PetLook"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))

local PetModels = ReplicatedStorage:WaitForChild("PetModels")

-- floor-space layout, copied from the Studio plots (Workspace.Garden.Plots.Plot_NN)
local PEN_SPOTS = {
	Vector3.new(-12, 0.4, 4),
	Vector3.new(0, 0.4, 4),
	Vector3.new(12, 0.4, 4),
	Vector3.new(-12, 0.4, 15),
	Vector3.new(0, 0.4, 15),
	Vector3.new(12, 0.4, 15),
}
local INCUBATOR_SPOTS = { Vector3.new(-12, 0, -10), Vector3.new(0, 0, -10), Vector3.new(12, 0, -10) }
local FIELD_FRONT = 22 -- the field lies behind the plot (floor +Z), from this far behind the centre
local FIELD_WIDTH = 40

local COLORS = {
	floor = Color3.fromRGB(126, 186, 96),
	edge = Color3.fromRGB(120, 85, 50),
	sign = Color3.fromRGB(60, 42, 28),
	padEmpty = Color3.fromRGB(110, 190, 110),
	padLocked = Color3.fromRGB(80, 80, 80),
	base = Color3.fromRGB(150, 100, 60),
	nest = Color3.fromRGB(225, 195, 110),
	soil = Color3.fromRGB(105, 70, 45),
}
local CROP_COLORS = {
	a = Color3.fromRGB(230, 200, 90),
	b = Color3.fromRGB(240, 120, 40),
	c = Color3.fromRGB(220, 60, 60),
	d = Color3.fromRGB(140, 210, 80),
	e = Color3.fromRGB(150, 90, 200),
	f = Color3.fromRGB(90, 200, 140),
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

-- "EggId:readyAt" → egg id, readyAt (nil for "")
local function parseEgg(text: string?): (string?, number?)
	if type(text) ~= "string" or text == "" then
		return nil, nil
	end
	local egg, readyAt = string.match(text, "^([^:]+):(%d+)$")
	return egg, tonumber(readyAt)
end

-- New view of plot slot `slot` under `parent`. options: { own = boolean, onPen = fn(pen) } (prompts on the own plot only).
function PlotView.new(slot: number, parent: Instance, options)
	local self = setmetatable({}, PlotView)
	self.slot = slot
	self.floor = GardenConfig.PlotCFrame(slot) :: CFrame
	self.own = options and options.own or false
	self.onPen = options and options.onPen
	self.detail = "none"
	self.state = nil
	self.built = {} -- [key] = signature of the drawn piece
	self.pieces = {} -- [key] = Model
	self.pending = {} -- ordered keys whose signature changed
	self.marked = {} -- [key] = true while pending
	self.rows = 0 -- most field rows ever drawn (rows beyond the current field are cleared)
	self.labels = {} -- [incubator] = { label, egg, readyAt } of drawn countdowns
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
	local rows = self.state and self.state.field and self.state.field.rows or 0
	self.rows = math.max(self.rows, rows)
	for n = 1, self.rows do
		table.insert(keys, "row" .. n)
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
		return detail .. "|" .. tostring(state.name)
	end
	local kind, number = string.match(key, "^(%a+)(%d+)$")
	local n = tonumber(number) :: number
	if kind == "pen" then
		return table.concat({ detail, state.pens[n] or "", tostring(n <= state.penCount), tostring(self.own) }, "|")
	elseif kind == "inc" then
		return table.concat({ detail, state.eggs[n] or "", tostring(n <= state.incCount) }, "|")
	end
	local field = state.field
	if not field or n > field.rows then
		return "none"
	end
	if detail == "low" then
		return if n == 1 then string.format("low|%dx%d", field.cols, field.rows) else "none"
	end
	return string.format("full|%d|%s", field.cols, string.sub(field.crops, (n - 1) * field.cols * 2 + 1, n * field.cols * 2))
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
	self:mark()
end

function PlotView:SetDetail(detail: string)
	if detail ~= self.detail then
		self.detail = detail
		self:mark()
	end
end

function PlotView:Pending(): number
	return #self.pending
end

-- Piece builders: each returns the filled Model (not parented yet) -------------------------------------------------------

function PlotView:at(offset: Vector3): CFrame
	return self.floor * CFrame.new(offset)
end

function PlotView:buildBase(model: Model)
	local floor = part({ Name = "Floor", Size = Vector3.new(40, 0.5, 40), CFrame = self.floor, Color = COLORS.floor, Material = Enum.Material.Grass })
	floor.CanQuery = true -- something to stand on and to raycast
	floor.Parent = model
	if self.detail ~= "full" then
		return
	end
	for _, edge in {
		{ Vector3.new(-20.4, 0.6, 0), Vector3.new(0.8, 1, 40.8) },
		{ Vector3.new(20.4, 0.6, 0), Vector3.new(0.8, 1, 40.8) },
		{ Vector3.new(0, 0.6, 20.4), Vector3.new(40.8, 1, 0.8) },
		{ Vector3.new(0, 0.6, -20.4), Vector3.new(40.8, 1, 0.8) },
	} do
		part({ Name = "Edge", Size = edge[2], CFrame = self:at(edge[1]), Color = COLORS.edge, Material = Enum.Material.Wood }).Parent = model
	end
	for _, x in { -6, 6 } do
		part({ Name = "Post", Size = Vector3.new(0.8, 5, 0.8), CFrame = self:at(Vector3.new(x, 2.8, -22)), Color = COLORS.edge }).Parent = model
	end
	local sign = part({ Name = "Sign", Size = Vector3.new(14, 4, 0.6), CFrame = self:at(Vector3.new(0, 6.2, -22)), Color = COLORS.sign, Material = Enum.Material.Wood })
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Gui"
	gui.Face = Enum.NormalId.Front
	gui.AutoLocalize = false
	gui.PixelsPerStud = 25
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = tostring(self.state.name) -- a player name (no translation)
	label.Parent = gui
	gui.Parent = sign
	sign.Parent = model
end

-- Pet model standing on `pad` (full detail): a PetModels clone dressed by PetLook like the server's pen pets.
local function penPet(kind: string, level: number, uid: string, pad: BasePart): Model?
	local template = PetModels:FindFirstChild(kind)
	if not (template and template:IsA("Model") and template.PrimaryPart) then
		return nil
	end
	local model = template:Clone()
	local metrics = PetLook.Apply(model, kind, level, uid, {
		text = PetLook.LabelText(kind, level),
		size = UDim2.new(6, 0, 1.4, 0),
		maxDistance = 90,
		gap = 1,
	})
	if not metrics then
		model:Destroy()
		return nil
	end
	model:PivotTo(pad.CFrame * CFrame.new(0, pad.Size.Y / 2 + 1, 0))
	local boxCFrame, boxSize = model:GetBoundingBox()
	local bottom = boxCFrame.Position.Y - boxSize.Y / 2
	model:PivotTo(model:GetPivot() + Vector3.new(0, pad.Position.Y + pad.Size.Y / 2 - bottom, 0))
	return model
end

function PlotView:buildPen(model: Model, n: number)
	local state = self.state
	local kind, level, uid = parsePet(state.pens[n])
	local rarity = kind and PetConfig.RarityOf(kind)
	local spot = PEN_SPOTS[n]
	if self.detail == "low" then
		if kind and rarity then
			local size = 2 * PetConfig.ScaleOf(level :: number)
			part({ Name = "Pet", Size = Vector3.new(size, size, size), CFrame = self:at(spot + Vector3.new(0, size / 2 + 0.15, 0)), Color = rarity.color }).Parent = model
		end
		return
	end
	local color = if n > state.penCount then COLORS.padLocked elseif rarity then COLORS.padEmpty:Lerp(rarity.color, 0.45) else COLORS.padEmpty
	local pad = part({ Name = "Pad", Size = Vector3.new(9, 0.3, 9), CFrame = self:at(spot), Color = color, Material = Enum.Material.SmoothPlastic })
	pad.Parent = model
	if kind and rarity then
		local pet = penPet(kind, level :: number, uid :: string, pad)
		if pet then
			pet.Name = "Pet"
			pet.Parent = model
		end
	end
	if self.own and self.onPen then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "Prompt"
		prompt.ObjectText = Locale.T("garden.title", { pen = n })
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Triggered:Connect(function()
			self.onPen(n)
		end)
		prompt.Parent = pad
	end
end

function PlotView:buildIncubator(model: Model, n: number)
	local state = self.state
	local eggId, readyAt = parseEgg(state.eggs[n])
	local egg = eggId and PetConfig.Eggs[eggId]
	local eggColor = if egg and egg.look then egg.look.color else Color3.fromRGB(236, 228, 208)
	local spot = INCUBATOR_SPOTS[n]
	self.labels[n] = nil
	if self.detail == "low" then
		if eggId then
			part({ Name = "Egg", Shape = Enum.PartType.Ball, Size = Vector3.new(2.8, 2.8, 2.8), CFrame = self:at(spot + Vector3.new(0, 1.65, 0)), Color = eggColor }).Parent = model
		end
		return
	end
	local locked = n > state.incCount
	part({ Name = "Base", Size = Vector3.new(6, 1.2, 6), CFrame = self:at(spot + Vector3.new(0, 0.85, 0)), Color = if locked then COLORS.padLocked else COLORS.base, Material = Enum.Material.WoodPlanks }).Parent = model
	part({ Name = "Nest", Size = Vector3.new(4.4, 0.4, 4.4), CFrame = self:at(spot + Vector3.new(0, 1.65, 0)), Color = COLORS.nest, Material = Enum.Material.Fabric }).Parent = model
	if not eggId then
		return
	end
	local ball = part({ Name = "Egg", Shape = Enum.PartType.Ball, Size = Vector3.new(2.8, 2.8, 2.8), CFrame = self:at(spot + Vector3.new(0, 3.2, 0)), Color = eggColor })
	local info = Instance.new("BillboardGui")
	info.Name = "Info"
	info.AutoLocalize = false
	info.Size = UDim2.new(6, 0, 1.6, 0)
	info.StudsOffset = Vector3.new(0, 2.6, 0)
	info.MaxDistance = 90
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Parent = info
	info.Parent = ball
	ball.Parent = model
	self.labels[n] = { label = label, egg = egg, readyAt = readyAt }
end

function PlotView:buildRow(model: Model, r: number)
	local field = self.state.field
	local pitch = math.min(5.5, FIELD_WIDTH / field.cols)
	local size = pitch - 0.4
	if self.detail == "low" then
		local depth = pitch * field.rows
		part({ Name = "Field", Size = Vector3.new(pitch * field.cols, 0.4, depth), CFrame = self:at(Vector3.new(0, 0.05, FIELD_FRONT + depth / 2)), Color = COLORS.soil }).Parent = model
		return
	end
	local z = FIELD_FRONT + (r - 0.5) * pitch
	for c = 1, field.cols do
		local x = (c - 0.5 - field.cols / 2) * pitch
		part({ Name = "Soil", Size = Vector3.new(size, 0.4, size), CFrame = self:at(Vector3.new(x, 0.05, z)), Color = COLORS.soil, Material = Enum.Material.Ground }).Parent = model
		local index = ((r - 1) * field.cols + c - 1) * 2 + 1
		local crop = string.sub(field.crops, index, index)
		local stage = tonumber(string.sub(field.crops, index + 1, index + 1)) or 0
		if CROP_COLORS[crop] and stage > 0 then
			local height = 0.6 + stage * 0.7
			local width = size * (0.3 + stage * 0.15)
			part({ Name = "Crop", Size = Vector3.new(width, height, width), CFrame = self:at(Vector3.new(x, 0.25 + height / 2, z)), Color = CROP_COLORS[crop] }).Parent = model
		end
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
	else
		local kind, number = string.match(key, "^(%a+)(%d+)$")
		local n = tonumber(number) :: number
		if kind == "pen" then
			self:buildPen(model, n)
		elseif kind == "inc" then
			self:buildIncubator(model, n)
		else
			self:buildRow(model, n)
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
