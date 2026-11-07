-- GardenView (E1a1, docs/EXPANSION.md §16): draws the garden's plots on this client, into the client-local folder
-- Workspace.GardenView (the server keeps only data). Starts when first required (IncubatorClient, FieldClient, HintSources).
--   * owned plots: GardenRemotes.Plot (GardenPlotFeed), one state per player; RequestPlots on start;
--   * free slots 1..GardenConfig.ShownFreeSlots nobody holds: an empty "Free plot";
--   * Studio test hook: Workspace attribute GardenViewFake = N fills slots 1..N nobody holds with synthetic full plots, and
--     GardenViewField = open squares (0 = none, at most CropConfig.MaxSquares) adds a stand-in field to every plot (budget checks,
--     ROADMAP E1a1 check 5).
-- Detail by horizontal distance from the character to the plot centre: full ≤ 60 studs, mid ≤ 120 (pets as blocks), low ≤ 300,
-- nothing beyond (10 studs of hysteresis). Builds run on Heartbeat within BUDGET seconds per frame, the own plot first, then the
-- nearest. The own plot's hatchery carries a prompt that calls the handler registered with OnHatchery (U5b), its barn one OnBarn (U5a;
-- the barn's sacks and crates come from the own field's State, SetBarn); the field has none since
-- U3a: SquareAt / SquareCFrame / ShowSelect / OwnRoot serve FieldHand's tap and FieldRings; U3b: ShowBorders, ShowHover). OwnState / OwnField return the own
-- plot and the owner's field state as last received (GardenSummary, U2).
-- In Studio the folder carries the attributes Instances and Pending (tests).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local PlotView = require(script.Parent:WaitForChild("PlotView"))

local FULL_DISTANCE = 60
local MID_DISTANCE = 120
local LOW_DISTANCE = 300
local HYSTERESIS = 10
local BUDGET = 0.006 -- seconds of build work per frame
local DETAIL_INTERVAL = 0.25
local TICK_INTERVAL = 0.5

local player = Players.LocalPlayer
local studio = RunService:IsStudio()

local folder = Instance.new("Folder")
folder.Name = "GardenView"
folder.Parent = workspace

local views = {} -- [slot] = PlotView
local received = {} -- [userId] = state from the server
local real = {} -- [userId] = that state with `names` = the owner's pet names (P3b, PetConfig.NamesAttribute)
local order = {} -- slots in build order (own first, then by distance)
local handlers = { hatchery = nil, barn = nil }
local ownField = nil -- the owner's field as GardenRemotes.State last sent it (OwnField)

local GardenView = {}

GardenView.Folder = folder

-- fn() when the own hatchery's prompt is triggered (U5b; the three nests share it).
function GardenView.OnHatchery(fn: () -> ())
	handlers.hatchery = fn
end

-- fn() when the own barn's prompt is triggered (U5a).
function GardenView.OnBarn(fn: () -> ())
	handlers.barn = fn
end

-- What the own barn shows (U5a): seed sacks for the share of the barn's capacity the seeds fill (none at 0, at least one above),
-- a crate per crop kind held (crop letters in catalogue order). nil without a field.
local function barnFill(field)
	if type(field) ~= "table" then
		return nil
	end
	local capacity = CropConfig.BarnFor(CropConfig.UpgradeLevel(field.upgrades, "Barn"))
	local seeds = CropConfig.SeedTotal(field.seeds)
	local crates = {}
	for _, crop in CropConfig.Crops do
		if type(field.items) == "table" and (field.items[crop.id] or 0) > 0 then
			table.insert(crates, crop.letter)
		end
	end
	return { sacks = math.min(PlotView.BarnSacks, math.ceil(PlotView.BarnSacks * seeds / math.max(capacity, 1))), crates = crates }
end

local function ownSlot(): number?
	return player:GetAttribute(GardenConfig.PlotAttribute)
end

-- The state of the own plot as last received ({ eggs, incCount, field, ... }), or nil.
function GardenView.OwnState()
	local slot = ownSlot()
	local view = slot and views[slot]
	return if view and view.state and not view.state.free then view.state else nil
end

-- The drawn piece of the own plot: "inc<n>" (a Model with Base, Egg), or nil while not drawn.
function GardenView.OwnPiece(key: string): Model?
	local slot = ownSlot()
	local view = slot and views[slot]
	return view and view:Piece(key)
end

-- Tints the own field's `squares` (the reach of a pet being placed, E1b); nil clears.
function GardenView.ShowReach(squares: { number }?)
	local slot = ownSlot()
	local view = slot and views[slot]
	if view then
		view:ShowReach(squares)
	end
end

local function ownView()
	local slot = ownSlot()
	return slot and views[slot]
end

-- Outlines the own field's square `square` (the selected one, U3a); nil clears.
function GardenView.ShowSelect(square: number?)
	local view = ownView()
	if view then
		view:ShowSelect(square)
	end
end

-- U3b: corner brackets on the own field's square `square` (the one the player stands on, PlotView:ShowHover); nil clears.
function GardenView.ShowHover(square: number?)
	local view = ownView()
	if view then
		view:ShowHover(square)
	end
end

-- U3b: the placed pets' reach regions as borders on the own field (PlotView:ShowBorders); nil clears.
function GardenView.ShowBorders(borders)
	local view = ownView()
	if view then
		view:ShowBorders(borders)
	end
end

-- The own field's square under world point `position` (locked ones included), or nil.
function GardenView.SquareAt(position: Vector3): number?
	local view = ownView()
	return view and view:SquareAt(position)
end

-- World CFrame of the middle of the own field's square `square` at the soil's top, or nil without a plot.
function GardenView.SquareCFrame(square: number): CFrame?
	local view = ownView()
	return view and view:SquareCFrame(square)
end

-- The own plot's drawn model (the tap ray's include list), or nil.
function GardenView.OwnRoot(): Model?
	local view = ownView()
	return view and view.root
end

-- Data ---------------------------------------------------------------------------------------------------------------------

-- deterministic pseudo-random 0..1 from integers (synthetic plots and fields)
local function noise(a: number, b: number): number
	local h = (a * 73856093 + b * 19349663) % 2147483647
	h = (h * 48271) % 2147483647
	return h / 2147483647
end

local KINDS = {}
for kind in PetConfig.Kinds do
	table.insert(KINDS, kind)
end
table.sort(KINDS)

-- a field with its first `squares` squares open (CropConfig's shape; the rest locked)
local function syntheticField(slot: number, squares: number)
	local crops = table.create(CropConfig.MaxSquares)
	for i = 1, CropConfig.MaxSquares do
		if i > squares then
			crops[i] = "#0"
		else
			local r = noise(slot, i)
			crops[i] = string.char(string.byte("a") + math.floor(r * 6)) .. tostring(math.floor(noise(i, slot) * 4))
		end
	end
	local pets = {} -- a field pet on every fourth square (E1b budget checks)
	for i = 2, squares, 4 do
		local kind = KINDS[(slot + i) % #KINDS + 1]
		table.insert(pets, string.format("%s:%d:f%d_s%d:%d:%d", kind, 1 + math.floor(noise(slot, i + 90) * 20), slot, i, i, 1 + math.floor(noise(i, slot + 7) * 9)))
	end
	return { crops = table.concat(crops), squares = squares, pets = pets }
end

local function syntheticPlot(slot: number)
	local eggs = {}
	local now = math.floor(workspace:GetServerTimeNow())
	for n = 1, GardenConfig.MaxIncubators do
		eggs[n] = string.format("%s:%d", if n == 3 then "Golden" else "Basic", now + 60 * slot + 20 * n)
	end
	return { name = "#" .. slot, incCount = 3, eggs = eggs }
end

local FREE = table.freeze({ free = true })
local fakeCache = {} -- [slot] = synthetic state (kept so countdowns do not restart)

-- state of every slot that is drawn now: [slot] = state
local function states()
	local result = {}
	for _, state in real do
		if GardenConfig.PlotRing(state.slot) then
			result[state.slot] = state
		end
	end
	if studio then
		local fake = math.min(tonumber(workspace:GetAttribute("GardenViewFake")) or 0, GardenConfig.PlotSlots)
		for slot = 1, fake do
			if not result[slot] then
				fakeCache[slot] = fakeCache[slot] or syntheticPlot(slot)
				result[slot] = fakeCache[slot]
			end
		end
		local squares = math.clamp(tonumber(workspace:GetAttribute("GardenViewField")) or 0, 0, CropConfig.MaxSquares)
		for slot, state in result do
			if squares > 0 and not (state.field and state.field.squares == squares) then
				state = table.clone(state)
				state.field = syntheticField(slot, squares)
				result[slot] = state
			end
		end
	end
	for slot = 1, math.min(GardenConfig.ShownFreeSlots, GardenConfig.PlotSlots) do
		result[slot] = result[slot] or FREE
	end
	return result
end

local function refresh()
	local current = states()
	local own = ownSlot()
	for slot = 1, GardenConfig.PlotSlots do
		local state = current[slot]
		local view = views[slot]
		if view and (not state or view.own ~= (slot == own)) then
			view:Destroy()
			views[slot] = nil
			view = nil
		end
		if state then
			if not view then
				view = PlotView.new(slot, folder, {
					own = slot == own,
					onHatchery = function()
						if handlers.hatchery then
							handlers.hatchery()
						end
					end,
					onBarn = function()
						if handlers.barn then
							handlers.barn()
						end
					end,
				})
				views[slot] = view
				if slot == own then
					view:SetBarn(barnFill(ownField))
				end
			end
			if view.state ~= state then
				view:SetState(state)
			end
		end
	end
end

-- Detail and scheduling ------------------------------------------------------------------------------------------------------

local function focus(): Vector3?
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		return (root :: BasePart).Position
	end
	return workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position
end

local function wantedDetail(current: string, distance: number): string
	local full = if current == "full" then FULL_DISTANCE + HYSTERESIS else FULL_DISTANCE
	local mid = if current == "full" or current == "mid" then MID_DISTANCE + HYSTERESIS else MID_DISTANCE
	local low = if current == "none" then LOW_DISTANCE else LOW_DISTANCE + HYSTERESIS
	return if distance <= full then "full" elseif distance <= mid then "mid" elseif distance <= low then "low" else "none"
end

local function updateDetail()
	local at = focus()
	if not at then
		return
	end
	local own = ownSlot()
	local distances = {}
	order = {}
	for slot, view in views do
		local centre = view.floor.Position
		local distance = Vector3.new(centre.X - at.X, 0, centre.Z - at.Z).Magnitude
		distances[slot] = if slot == own then -1 else distance
		view:SetDetail(wantedDetail(view.detail, distance))
		table.insert(order, slot)
	end
	table.sort(order, function(a, b)
		return distances[a] < distances[b]
	end)
end

local function pendingCount(): number
	local count = 0
	for _, view in views do
		count += view:Pending()
	end
	return count
end

local function step()
	if pendingCount() == 0 then
		return
	end
	local deadline = os.clock() + BUDGET
	for _, slot in order do
		local view = views[slot]
		if view and view:Pending() > 0 then
			view:Step(deadline)
			if os.clock() >= deadline then
				break
			end
		end
	end
end

local remotes = ReplicatedStorage:WaitForChild("GardenRemotes")
-- the owner's filtered pet names go into a copy of the plot state, so a new name redraws the labels (PlotView signatures)
local function withNames(userId: number)
	local state = received[userId]
	if type(state) ~= "table" or state.free then
		real[userId] = state
		return
	end
	local owner = Players:GetPlayerByUserId(userId)
	local copy = table.clone(state)
	copy.names = PetConfig.DecodeNames(owner and owner:GetAttribute(PetConfig.NamesAttribute))
	real[userId] = copy
end

local function watchNames(owner: Player)
	owner:GetAttributeChangedSignal(PetConfig.NamesAttribute):Connect(function()
		if received[owner.UserId] then
			withNames(owner.UserId)
			refresh()
		end
	end)
end
Players.PlayerAdded:Connect(watchNames)
for _, owner in Players:GetPlayers() do
	watchNames(owner)
end

-- The owner's field as GardenRemotes.State last sent it ({ squares = { [n] = { crop, grown, readyAt } }, ... }; FieldClient
-- asks for it), kept here because this module is required before anyone asks (GardenSummary reads it, U2).
remotes:WaitForChild("State").OnClientEvent:Connect(function(state)
	ownField = if type(state) == "table" then state.field else nil
	local slot = ownSlot()
	local view = slot and views[slot]
	if view and view.own then
		view:SetBarn(barnFill(ownField))
	end
end)
function GardenView.OwnField()
	return ownField
end

remotes:WaitForChild("Plot").OnClientEvent:Connect(function(userId, state)
	received[userId] = state
	withNames(userId)
	refresh()
end)
player:GetAttributeChangedSignal(GardenConfig.PlotAttribute):Connect(refresh)
if studio then
	for _, name in { "GardenViewFake", "GardenViewField" } do
		workspace:GetAttributeChangedSignal(name):Connect(function()
			fakeCache = {}
			refresh()
		end)
	end
end
Locale.Changed:Connect(function()
	for _, view in views do
		view:Relabel()
	end
end)

local detailClock, tickClock = 0, 0
RunService.Heartbeat:Connect(function(dt)
	detailClock += dt
	tickClock += dt
	if detailClock >= DETAIL_INTERVAL then
		detailClock = 0
		updateDetail()
	end
	step()
	if tickClock >= TICK_INTERVAL then
		tickClock = 0
		local now = workspace:GetServerTimeNow()
		for _, view in views do
			view:Tick(now)
		end
		if studio then
			folder:SetAttribute("Instances", #folder:GetDescendants())
			folder:SetAttribute("Pending", pendingCount())
		end
	end
end)

refresh()
updateDetail()
remotes:WaitForChild("RequestPlots"):FireServer()

return GardenView
