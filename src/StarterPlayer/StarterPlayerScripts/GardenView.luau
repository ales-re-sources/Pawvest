-- GardenView (E1a1, docs/EXPANSION.md §16): draws the garden's plots on this client, into the client-local folder
-- Workspace.GardenView (the server keeps only data). Starts when first required (GardenClient, IncubatorClient, HintSources,
-- PetPenFx, PetPenLevelUp all do).
--   * owned plots: GardenRemotes.Plot (GardenPlotFeed), one state per player; RequestPlots on start;
--   * free slots 1..GardenConfig.ShownFreeSlots nobody holds: an empty "Free plot";
--   * Studio test hook: Workspace attribute GardenViewFake = N fills slots 1..N nobody holds with synthetic full plots, and
--     GardenViewField = squares (0 = none) adds a stand-in field to every plot (budget checks, ROADMAP E1a1 check 5).
-- Detail by horizontal distance from the character to the plot centre: full ≤ 60 studs, mid ≤ 120 (pets as blocks), low ≤ 300,
-- nothing beyond (10 studs of hysteresis). Builds run on Heartbeat within BUDGET seconds per frame, the own plot first, then the
-- nearest. The own plot's pads, incubators and field squares carry prompts that call the handlers registered with OnPen /
-- OnIncubator / OnSquare.
-- In Studio the folder carries the attributes Instances and Pending (tests).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
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
local real = {} -- [userId] = state from the server
local order = {} -- slots in build order (own first, then by distance)
local handlers = { pen = nil, incubator = nil, square = nil, levelUp = nil }

local GardenView = {}

GardenView.Folder = folder

-- fn(pen, pad) when a pen prompt of the own plot is triggered.
function GardenView.OnPen(fn: (number, BasePart) -> ())
	handlers.pen = fn
end

-- fn(incubator, base) when an incubator prompt of the own plot is triggered.
function GardenView.OnIncubator(fn: (number, BasePart) -> ())
	handlers.incubator = fn
end

-- fn(square, action, soil) when a field square prompt of the own plot is triggered: action "plant" (empty) / "harvest" (ripe).
function GardenView.OnSquare(fn: (number, string, BasePart) -> ())
	handlers.square = fn
end

-- fn(model, kind, level) when a penned pet levelled up and its new model is drawn (any plot in full detail).
function GardenView.OnPenLevelUp(fn: (Model, string, number) -> ())
	handlers.levelUp = fn
end

local function ownSlot(): number?
	return player:GetAttribute(GardenConfig.PlotAttribute)
end

-- The state of the own plot as last received ({ pens, eggs, penCount, incCount, ... }), or nil.
function GardenView.OwnState()
	local slot = ownSlot()
	local view = slot and views[slot]
	return if view and view.state and not view.state.free then view.state else nil
end

-- The drawn piece of the own plot: "pen<n>" / "inc<n>" (a Model with Pad / Base, Pet / Egg), or nil while not drawn.
function GardenView.OwnPiece(key: string): Model?
	local slot = ownSlot()
	local view = slot and views[slot]
	return view and view:Piece(key)
end

-- Every drawn pen pet model (full detail) of every plot.
function GardenView.PenPets(): { Model }
	local list = {}
	for _, view in views do
		for n = 1, GardenConfig.MaxPens do
			local piece = view:Piece("pen" .. n)
			local pet = piece and piece:FindFirstChild("Pet")
			if pet and pet:IsA("Model") then
				table.insert(list, pet)
			end
		end
	end
	return list
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

local function syntheticField(slot: number, squares: number)
	local cols = if squares <= 12 then 4 else math.ceil(math.sqrt(squares * 1.5))
	local rows = math.ceil(squares / cols)
	local crops = table.create(cols * rows)
	for i = 1, cols * rows do
		if i > squares then
			crops[i] = ".0"
		else
			local r = noise(slot, i)
			crops[i] = string.char(string.byte("a") + math.floor(r * 6)) .. tostring(math.floor(noise(i, slot) * 4))
		end
	end
	return { cols = cols, rows = rows, crops = table.concat(crops), squares = squares }
end

local function syntheticPlot(slot: number)
	local pens = {}
	for n = 1, GardenConfig.MaxPens do
		local kind = KINDS[(slot + n) % #KINDS + 1]
		local level = 1 + math.floor(noise(slot, n + 50) * 20)
		pens[n] = if noise(slot, n + 20) < 0.85 then string.format("%s:%d:f%d_%d", kind, level, slot, n) else ""
	end
	local eggs = {}
	local now = math.floor(workspace:GetServerTimeNow())
	for n = 1, GardenConfig.MaxIncubators do
		eggs[n] = string.format("%s:%d", if n == 3 then "Golden" else "Basic", now + 60 * slot + 20 * n)
	end
	return { name = "#" .. slot, penCount = 6, pens = pens, incCount = 3, eggs = eggs }
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
		local squares = math.clamp(tonumber(workspace:GetAttribute("GardenViewField")) or 0, 0, 400)
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
					onPen = function(pen, pad)
						if handlers.pen then
							handlers.pen(pen, pad)
						end
					end,
					onIncubator = function(n, base)
						if handlers.incubator then
							handlers.incubator(n, base)
						end
					end,
					onSquare = function(square, action, soil)
						if handlers.square then
							handlers.square(square, action, soil)
						end
					end,
					onLevelUp = function(model, kind, level)
						if handlers.levelUp then
							handlers.levelUp(model, kind, level)
						end
					end,
				})
				views[slot] = view
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
remotes:WaitForChild("Plot").OnClientEvent:Connect(function(userId, state)
	real[userId] = state
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
