-- PlotViewSpike (E1.0 spike, docs/ROADMAP.md → E1.0): runs the client-drawn plot prototype (PlotView). Only in Studio,
-- for admins and Studio test users, while the Workspace attribute PlotViewSpike is true; otherwise it does nothing and the live garden is
-- untouched. While on, it hides the Studio plots (Workspace.Garden.Plots) on this client only and draws every plot from
-- data instead, into the client-local folder Workspace.PlotViewSpike:
--   * real plots: the states of PlotViewRemotes.Plot (one message per player, PlotViewSpike.server.luau);
--   * synthetic plots for the scale test: Workspace attribute PlotViewFake = N fills slots 1..N that no player holds;
--   * a stand-in field on every plot (no crop data exists yet): Workspace attribute PlotViewField = squares (default 12).
-- Detail by horizontal distance from the character to the plot centre: full ≤ 120 studs, low ≤ 300, nothing beyond
-- (10 studs of hysteresis). Builds run on Heartbeat within BUDGET seconds per frame, the own plot first, then the nearest.
-- The own plot's pen pads carry prompts that open the pen panel of GardenClient (its OpenPen hook), which fires the
-- existing GardenRemotes. Measurements are attributes of the folder: Instances, Pending, Full / Low, MaxStepMs (longest
-- build work in one frame), MaxFrameMs (longest frame while building), LastBuildMs (first marked piece → queue empty),
-- MemMb (Stats total), InstancesMb; setting its attribute Reset clears the maxima.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local AdminConfig = require(ReplicatedStorage:WaitForChild("AdminConfig"))
local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local PlotView = require(script.Parent:WaitForChild("PlotView"))

local FLAG = "PlotViewSpike"
local FULL_DISTANCE = 120
local LOW_DISTANCE = 300
local HYSTERESIS = 10
local BUDGET = 0.006 -- seconds of build work per frame
local DETAIL_INTERVAL = 0.25
local STATS_INTERVAL = 0.5

local player = Players.LocalPlayer
-- Studio only; admins, and Studio's test users (UserIds -1, -2… of a Server and Clients test)
if not (RunService:IsStudio() and (AdminConfig.IsAdmin(player.UserId) or player.UserId < 0)) then
	return
end

local active = false
local folder: Folder? = nil
local views = {} -- [slot] = PlotView
local real = {} -- [userId] = state from the server
local order = {} -- slots in build order (own first, then by distance)
local connections = {}
local hidden = {} -- [Instance] = { wanted = Enabled value to restore, conn }
local stats = { maxStep = 0, maxFrame = 0, buildStart = nil, lastBuild = 0 }

-- Studio plots hidden on this client --------------------------------------------------------------------------------------

local TOGGLED = { "LayerCollector", "ProximityPrompt", "Light", "ParticleEmitter", "Trail", "Beam", "Highlight" }

local function hide(inst: Instance)
	if hidden[inst] then
		return
	end
	if inst:IsA("BasePart") or inst:IsA("Decal") then
		(inst :: any).LocalTransparencyModifier = 1
		hidden[inst] = {}
		return
	end
	for _, class in TOGGLED do
		if inst:IsA(class) then
			local entry = { wanted = (inst :: any).Enabled, writing = true }
			hidden[inst] = entry;
			(inst :: any).Enabled = false
			entry.writing = false
			entry.conn = inst:GetPropertyChangedSignal("Enabled"):Connect(function()
				if entry.writing then
					return
				end
				entry.wanted = (inst :: any).Enabled -- another script (or the server) changed it: remember, keep it off
				entry.writing = true;
				(inst :: any).Enabled = false
				entry.writing = false
			end)
			return
		end
	end
end

local function unhideAll()
	for inst, entry in hidden do
		if entry.conn then
			entry.conn:Disconnect()
		end
		if inst:IsA("BasePart") or inst:IsA("Decal") then
			(inst :: any).LocalTransparencyModifier = 0
		elseif entry.wanted ~= nil then
			(inst :: any).Enabled = entry.wanted
		end
	end
	hidden = {}
end

-- Data -------------------------------------------------------------------------------------------------------------------

local function ownSlot(): number?
	return player:GetAttribute(GardenConfig.PlotAttribute)
end

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
	return { cols = cols, rows = rows, crops = table.concat(crops) }
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

-- state of every slot that has one now: [slot] = state
local fakeCache = {} -- [slot] = synthetic state (kept so countdowns do not restart)
local function states()
	local result = {}
	for _, state in real do
		if GardenConfig.PlotRing(state.slot) then
			result[state.slot] = state
		end
	end
	local fake = math.min(tonumber(workspace:GetAttribute("PlotViewFake")) or 0, GardenConfig.PlotSlots)
	for slot = 1, fake do
		if not result[slot] then
			fakeCache[slot] = fakeCache[slot] or syntheticPlot(slot)
			result[slot] = fakeCache[slot]
		end
	end
	local squares = math.clamp(tonumber(workspace:GetAttribute("PlotViewField")) or 12, 0, 400)
	for slot, state in result do
		if squares > 0 and not (state.field and state.field.squares == squares) then
			local field = syntheticField(slot, squares)
			field.squares = squares
			state.field = field
		elseif squares == 0 then
			state.field = nil
		end
	end
	return result
end

local function openPen(pen: number)
	local gui = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("GardenGui")
	if gui then
		gui:SetAttribute("OpenPen", pen) -- GardenClient opens its pen panel (Place / Remove / BuyPen remotes)
	end
end

local function refresh()
	if not (active and folder) then
		return
	end
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
				view = PlotView.new(slot, folder, { own = slot == own, onPen = openPen })
				views[slot] = view
			end
			-- a copy: PlotView compares signatures, the table itself may be reused by the caller
			view:SetState(table.clone(state))
		end
	end
end

-- Detail, scheduling, stats ------------------------------------------------------------------------------------------

local function focus(): Vector3?
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		return (root :: BasePart).Position
	end
	return workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position
end

local function wantedDetail(current: string, distance: number): string
	local full = if current == "full" then FULL_DISTANCE + HYSTERESIS else FULL_DISTANCE
	local low = if current == "none" then LOW_DISTANCE else LOW_DISTANCE + HYSTERESIS
	return if distance <= full then "full" elseif distance <= low then "low" else "none"
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

local function step(dt: number)
	local pending = pendingCount()
	if pending == 0 then
		return
	end
	stats.buildStart = stats.buildStart or os.clock()
	stats.maxFrame = math.max(stats.maxFrame, dt * 1000)
	local start = os.clock()
	local deadline = start + BUDGET
	for _, slot in order do
		local view = views[slot]
		if view and view:Pending() > 0 then
			view:Step(deadline)
			if os.clock() >= deadline then
				break
			end
		end
	end
	stats.maxStep = math.max(stats.maxStep, (os.clock() - start) * 1000)
	if pendingCount() == 0 then
		stats.lastBuild = (os.clock() - stats.buildStart) * 1000
		stats.buildStart = nil
	end
end

local function writeStats()
	if not folder then
		return
	end
	local full, low = 0, 0
	for _, view in views do
		if view.detail == "full" then
			full += 1
		elseif view.detail == "low" then
			low += 1
		end
	end
	folder:SetAttribute("Instances", #folder:GetDescendants())
	folder:SetAttribute("Pending", pendingCount())
	folder:SetAttribute("Full", full)
	folder:SetAttribute("Low", low)
	folder:SetAttribute("MaxStepMs", math.round(stats.maxStep * 100) / 100)
	folder:SetAttribute("MaxFrameMs", math.round(stats.maxFrame * 100) / 100)
	folder:SetAttribute("LastBuildMs", math.round(stats.lastBuild))
	folder:SetAttribute("MemMb", math.round(Stats:GetTotalMemoryUsageMb()))
	folder:SetAttribute("InstancesMb", math.round(Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.Instances) * 10) / 10)
end

local function start()
	if active then
		return
	end
	active = true
	local made = Instance.new("Folder")
	made.Name = "PlotViewSpike"
	made.Parent = workspace
	folder = made
	stats = { maxStep = 0, maxFrame = 0, buildStart = nil, lastBuild = 0 }

	local garden = workspace:FindFirstChild("Garden")
	local plots = garden and garden:FindFirstChild("Plots")
	if plots then
		for _, inst in plots:GetDescendants() do
			hide(inst)
		end
		table.insert(connections, plots.DescendantAdded:Connect(hide))
	end

	local remotes = ReplicatedStorage:WaitForChild("PlotViewRemotes")
	table.insert(connections, remotes.Plot.OnClientEvent:Connect(function(userId, state)
		real[userId] = state
		refresh()
	end))
	table.insert(connections, player:GetAttributeChangedSignal(GardenConfig.PlotAttribute):Connect(refresh))
	for _, name in { "PlotViewFake", "PlotViewField" } do
		table.insert(connections, workspace:GetAttributeChangedSignal(name):Connect(function()
			fakeCache = {}
			refresh()
		end))
	end
	table.insert(connections, made:GetAttributeChangedSignal("Reset"):Connect(function()
		stats.maxStep, stats.maxFrame, stats.lastBuild = 0, 0, 0
	end))

	local detailClock, statsClock, tickClock = 0, 0, 0
	table.insert(connections, RunService.Heartbeat:Connect(function(dt)
		detailClock += dt
		statsClock += dt
		tickClock += dt
		if detailClock >= DETAIL_INTERVAL then
			detailClock = 0
			updateDetail()
		end
		step(dt)
		if tickClock >= 0.5 then
			tickClock = 0
			local now = workspace:GetServerTimeNow()
			for _, view in views do
				view:Tick(now)
			end
		end
		if statsClock >= STATS_INTERVAL then
			statsClock = 0
			writeStats()
		end
	end))

	refresh()
	updateDetail()
	remotes.Request:FireServer()
end

local function stop()
	if not active then
		return
	end
	active = false
	for _, conn in connections do
		conn:Disconnect()
	end
	connections = {}
	for _, view in views do
		view:Destroy()
	end
	views = {}
	real = {}
	fakeCache = {}
	order = {}
	unhideAll()
	if folder then
		folder:Destroy()
		folder = nil
	end
end

local function apply()
	if workspace:GetAttribute(FLAG) == true then
		start()
	else
		stop()
	end
end

workspace:GetAttributeChangedSignal(FLAG):Connect(apply)
apply()
