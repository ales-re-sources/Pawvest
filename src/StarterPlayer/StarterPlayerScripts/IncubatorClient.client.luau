-- Incubator client (docs/GDD.md §7.2, §7.6, P2b1, P2b3): incubator prompts on the player's own plot, the incubator panel
-- (unlock an incubator, start a Basic or Golden egg, countdown, Hatch with the pet reveal) and the countdown text above
-- every plot's eggs. Free eggs are started by the server on their own; the panel only says how many still wait.
-- Display only: a click just names an incubator; GardenIncubators validates ownership, price, the inventory cap and the
-- hatch time against the server's os.time(). The countdown uses workspace:GetServerTimeNow() (synced to the server, not
-- the device clock), so a wrong device clock only changes what is shown. The GUI is built here (no Studio GUI).
-- Stud-brick look (StudStyle, yellow): title strip, brick buttons (unlock / eggs green, Hatch purple).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))

local remotes = ReplicatedStorage:WaitForChild("GardenRemotes")
-- looked up by name (never `remotes.X`: a name like Remove would resolve to an Instance method)
local startEggEvent = remotes:WaitForChild("StartEgg")
local hatchEvent = remotes:WaitForChild("Hatch")
local buyIncubatorEvent = remotes:WaitForChild("BuyIncubator")
local player = Players.LocalPlayer

local WIDTH = 380
local HEIGHT = 330
local CLOSE_DISTANCE = 32 -- studs from the incubator; walking further away closes the panel

local COLOR_PANEL = StudStyle.PanelColors.Incubator
local COLOR_BUY = StudStyle.Colors.Green
local COLOR_HATCH = StudStyle.Colors.Purple -- stands out on the yellow panel
local COLOR_LOCKED = StudStyle.Colors.Grey
local COLOR_CLOSE = StudStyle.Colors.Red
local COLOR_INFO = Color3.fromRGB(235, 222, 190)
local COLOR_ERROR = Color3.fromRGB(240, 100, 90)
local COLOR_OK = Color3.fromRGB(120, 230, 120)

local REJECT_KEYS = {
	coins = "common.reject.coins",
	stale = "common.reject.stale",
	maxed = "incubator.reject.maxed",
	locked = "incubator.reject.locked",
	occupied = "incubator.reject.occupied",
	full = "incubator.reject.full",
	empty = "incubator.reject.empty",
	notready = "incubator.reject.notready",
	far = "common.reject.far",
	noplot = "common.reject.noplot",
	loading = "common.reject.loading",
}

local function create(className: string, props, children)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	return instance
end

local function label(name: string, props)
	props.Name = name
	props.BackgroundTransparency = 1
	props.Font = props.Font or StudStyle.Font
	props.TextColor3 = props.TextColor3 or Color3.new(1, 1, 1)
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	return create("TextLabel", props)
end

-- a brick button (StudStyle.Brick: colour and text keep being set on the button itself)
local function button(name: string, props, studs: number?)
	props.Name = name
	props.TextColor3 = Color3.new(1, 1, 1)
	local instance = create("TextButton", props)
	StudStyle.Brick(instance, { studs = studs })
	return instance
end

local function hex(color: Color3): string
	return string.format("#%02x%02x%02x", math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255))
end

-- "1:00:00", "42:07", "0:05"
local function countdown(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	if seconds >= 3600 then
		return string.format("%d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
	end
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

-- "1 hour", "30 min"
local function hatchTime(seconds: number): string
	if seconds % 3600 == 0 then
		return Locale.T("common.hours", { count = seconds // 3600 })
	end
	return Locale.T("common.duration.m", { m = seconds // 60 })
end

local function eggName(eggId: string): string
	local egg = PetConfig.Eggs[eggId]
	return if egg then Locale.EggName(egg) else eggId
end

-- Odds of an egg as rich text: "<Uncommon 45 %> · <Rare 35 %> · …" in rarity colours.
local function odds(eggId: string): string
	local egg = PetConfig.Eggs[eggId]
	local parts = {}
	for _, rarity in PetConfig.Rarities do
		local weight = egg.weights[rarity.id]
		if weight and weight > 0 then
			table.insert(
				parts,
				string.format(
					"<font color='%s'>%s %s %%</font>",
					hex(rarity.color),
					Locale.RarityName(rarity.id),
					Locale.Decimal(PetClient.Percent(weight))
				)
			)
		end
	end
	return table.concat(parts, " · ")
end

-- Panel ------------------------------------------------------------------------------------------------------------------

-- the brick title strip: StudStyle.Panel styles a child named TitleLabel
local titleLabel = label("TitleLabel", {
	Size = UDim2.new(1, 0, 0, 34),
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Center,
})
local closeButton = button("Close", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -6, 0, 4),
	Size = UDim2.fromOffset(30, 28),
	ZIndex = 2,
	BackgroundColor3 = COLOR_CLOSE,
	TextSize = 16,
	Text = "X",
}, 1)
local bodyLabel = label("Body", {
	Position = UDim2.new(0, 12, 0, 44),
	Size = UDim2.new(1, -24, 0, 150),
	Font = Enum.Font.Gotham,
	TextSize = 15,
	TextColor3 = COLOR_INFO,
	TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Top,
	RichText = true,
})
local statusLabel = label("Status", {
	Position = UDim2.new(0, 12, 0, 196),
	Size = UDim2.new(1, -24, 0, 50),
	TextSize = 16,
	TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Top,
	RichText = true,
})
local actionButton = button("Action", {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 10, 1, -12),
	Size = UDim2.new(1, -20, 0, 42),
	TextSize = 18,
}, 6)
-- empty incubator: one button per egg (PetConfig.EggOrder), side by side in place of the action button
local eggButtons = {} -- { { id, button } }
for position, eggId in PetConfig.EggOrder do
	local count = #PetConfig.EggOrder
	table.insert(eggButtons, {
		id = eggId,
		button = button("Egg_" .. eggId, {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new((position - 1) / count, if position == 1 then 10 else 5, 1, -12),
			Size = UDim2.new(1 / count, -15, 0, 42),
			TextSize = 16,
			Visible = false,
		}, 3),
	})
end

local panel = create("Frame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(WIDTH, HEIGHT),
	Visible = false,
}, {
	titleLabel,
	closeButton,
	bodyLabel,
	statusLabel,
	actionButton,
})
for _, entry in eggButtons do
	entry.button.Parent = panel
end
StudStyle.Panel(panel, COLOR_PANEL)

local screenGui = create("ScreenGui", {
	Name = "IncubatorGui",
	ResetOnSpawn = false,
	DisplayOrder = 5,
	AutoLocalize = false, -- translated by Locale (L2)
}, { panel })

-- State ------------------------------------------------------------------------------------------------------------------

local incubators = nil -- last GardenRemotes.State.incubators: { count, eggs = { ["n"] = { egg, readyAt } } }
local openIndex: number? = nil
local openBase: BasePart? = nil
local flashToken = 0
local flashing = false

local refresh -- defined below

local function flash(text: string, color: Color3)
	flashToken += 1
	flashing = true
	local mine = flashToken
	statusLabel.Text = text
	statusLabel.TextColor3 = color
	task.delay(4, function()
		if flashToken == mine then
			flashing = false
			refresh()
		end
	end)
end

local function setAction(text: string, color: Color3, visible: boolean?)
	actionButton.Text = text
	actionButton.BackgroundColor3 = color
	actionButton.Visible = visible ~= false
	for _, entry in eggButtons do
		entry.button.Visible = false
	end
end

-- Free eggs still waiting for an empty incubator (the server starts them on its own).
local function waitingFreeEggs(): number
	local waiting = 0
	if PetClient.State and type(PetClient.State.freeEggs) == "table" then
		for _, count in PetClient.State.freeEggs do
			waiting += count
		end
	end
	return waiting
end

-- Redraws the open panel (also every second while it is open, for the countdown).
refresh = function()
	local state = incubators
	local index = openIndex
	if not (state and index) then
		return
	end
	titleLabel.Text = Locale.T("incubator.title", { n = index })
	local entry = state.eggs[tostring(index)]
	local status, statusColor = "", COLOR_INFO

	if index > state.count then
		local nextIndex = state.count + 1
		bodyLabel.Text = Locale.T("incubator.body.locked")
		if index == nextIndex then
			local price = GardenConfig.IncubatorPrices[nextIndex]
			setAction(
				Locale.T("incubator.unlock", { n = nextIndex, count = price }),
				if PetClient.Coins >= price then COLOR_BUY else COLOR_LOCKED
			)
		else
			setAction(Locale.T("incubator.unlockFirst", { n = nextIndex }), COLOR_LOCKED)
			status = Locale.T("incubator.order")
		end
	elseif entry then
		local remaining = entry.readyAt - workspace:GetServerTimeNow()
		bodyLabel.Text = string.format("%s\n%s", eggName(entry.egg), odds(entry.egg))
		if remaining > 0 then
			status = Locale.T("incubator.hatchesIn", { time = countdown(remaining) })
			setAction(Locale.T("incubator.hatching"), COLOR_LOCKED)
		else
			status, statusColor = Locale.T("incubator.ready"), COLOR_OK
			setAction(Locale.T("incubator.hatch"), COLOR_HATCH)
		end
	else
		local lines = { Locale.T("incubator.body.empty") }
		for _, eggId in PetConfig.EggOrder do
			local egg = PetConfig.Eggs[eggId]
			table.insert(lines, string.format("<b>%s</b> · %s\n%s", eggName(eggId), hatchTime(egg.hatchSeconds), odds(eggId)))
		end
		bodyLabel.Text = table.concat(lines, "\n")
		setAction("", COLOR_LOCKED, false)
		for _, button in eggButtons do
			local egg = PetConfig.Eggs[button.id]
			button.button.Text = eggName(button.id) .. ": " .. Locale.Number(egg.price)
			button.button.BackgroundColor3 = if PetClient.Coins >= egg.price then COLOR_BUY else COLOR_LOCKED
			button.button.Visible = true
		end
	end
	local waiting = waitingFreeEggs()
	if waiting > 0 and status == "" then
		status = Locale.T("incubator.freeEggs", { count = waiting })
	end
	if not flashing then
		statusLabel.Text = status
		statusLabel.TextColor3 = statusColor
	end
end

local function closePanel()
	openIndex, openBase = nil, nil
	panel.Visible = false
end

local function openPanel(index: number, base: BasePart)
	openIndex, openBase = index, base
	flashing = false
	panel.Visible = true
	refresh()
end

closeButton.Activated:Connect(closePanel)

actionButton.Activated:Connect(function()
	local state = incubators
	local index = openIndex
	if not (state and index) then
		return
	end
	local entry = state.eggs[tostring(index)]
	if index > state.count then
		if index == state.count + 1 then
			buyIncubatorEvent:FireServer(index)
		end
	elseif entry then
		if entry.readyAt - workspace:GetServerTimeNow() <= 0 then
			hatchEvent:FireServer(index) -- the server checks the time itself
		end
	end
end)
for _, button in eggButtons do
	button.button.Activated:Connect(function()
		local state = incubators
		local index = openIndex
		if state and index and index <= state.count and not state.eggs[tostring(index)] then
			startEggEvent:FireServer(index, button.id)
		end
	end)
end

remotes:WaitForChild("State").OnClientEvent:Connect(function(state)
	if type(state) == "table" and type(state.incubators) == "table" then
		incubators = state.incubators
		refresh()
	end
end)
PetClient.Changed:Connect(function()
	if openIndex then
		refresh()
	end
end)

remotes:WaitForChild("Result").OnClientEvent:Connect(function(action, ok, detail)
	if action ~= "StartEgg" and action ~= "Hatch" and action ~= "BuyIncubator" then
		return
	end
	if not ok then
		flash(Locale.T(REJECT_KEYS[detail] or "common.reject.failed", { max = PetConfig.MaxPets }), COLOR_ERROR)
	elseif action == "BuyIncubator" then
		flash(Locale.T("incubator.unlocked", { n = detail }), COLOR_OK)
	elseif action == "StartEgg" then
		flash(Locale.T("incubator.started"), COLOR_OK)
	elseif action == "Hatch" then
		local rarity = PetConfig.RarityById[detail.rarity]
		local pet = string.format(
			"<font color='%s'>%s (%s)</font>",
			hex(rarity and rarity.color or Color3.new(1, 1, 1)),
			Locale.PetKindName(tostring(detail.kind)),
			Locale.RarityName(tostring(detail.rarity))
		)
		flash(Locale.T(if detail.equipped then "incubator.hatched.follows" else "incubator.hatched.panel", { pet = pet }), COLOR_OK)
	end
end)

Locale.Changed:Connect(function()
	if openIndex then
		refresh()
	end
end)

-- Prompts and countdowns -------------------------------------------------------------------------------------------------

local wired = {} -- [Base] = true
local function wirePrompts()
	local plots = workspace:WaitForChild("Garden"):WaitForChild("Plots")
	local own = player:GetAttribute(GardenConfig.PlotAttribute)
	for _, plot in plots:GetChildren() do
		local mine = own ~= nil and plot:GetAttribute("PlotIndex") == own
		for number = 1, GardenConfig.MaxIncubators do
			local model = plot:FindFirstChild(GardenConfig.IncubatorNamePrefix .. number)
			local base = model and model:FindFirstChild("Base")
			local prompt = base and base:FindFirstChild("Prompt")
			if prompt and prompt:IsA("ProximityPrompt") then
				prompt.Enabled = mine
				if not wired[base] then
					wired[base] = true
					prompt.Triggered:Connect(function(who)
						if who == player then
							openPanel(number, base)
						end
					end)
				end
			end
		end
	end
end

player:GetAttributeChangedSignal(GardenConfig.PlotAttribute):Connect(wirePrompts)
task.spawn(wirePrompts)

-- Opens incubator N of the player's own plot when the ScreenGui attribute OpenIncubator is set (same effect as the prompt;
-- a test hook). Display only: the server validates every action anyway.
screenGui:GetAttributeChangedSignal("OpenIncubator"):Connect(function()
	local number = screenGui:GetAttribute("OpenIncubator")
	local own = player:GetAttribute(GardenConfig.PlotAttribute)
	if type(number) ~= "number" or not own then
		return
	end
	local plot = workspace:FindFirstChild("Garden") and workspace.Garden.Plots:FindFirstChild(GardenConfig.PlotName(own))
	local model = plot and plot:FindFirstChild(GardenConfig.IncubatorNamePrefix .. number)
	local base = model and model:FindFirstChild("Base")
	if base then
		openPanel(number, base)
	end
	screenGui:SetAttribute("OpenIncubator", nil)
end)

-- Every plot's incubating eggs: "Golden egg" + countdown, "Ready!" once due (local text; the server draws the rest).
local function drawCountdowns()
	local garden = workspace:FindFirstChild("Garden")
	local plots = garden and garden:FindFirstChild("Plots")
	if not plots then
		return
	end
	local now = workspace:GetServerTimeNow()
	for _, plot in plots:GetChildren() do
		for number = 1, GardenConfig.MaxIncubators do
			local model = plot:FindFirstChild(GardenConfig.IncubatorNamePrefix .. number)
			local readyAt = model and model:GetAttribute("ReadyAt")
			local eggId = model and model:GetAttribute("Egg")
			local base = model and model:FindFirstChild("Base")
			local info = base and base:FindFirstChild("Info")
			local text = info and info:FindFirstChildOfClass("TextLabel")
			if text and model:GetAttribute("State") == "egg" and type(readyAt) == "number" then
				local remaining = readyAt - now
				text.Text = eggName(tostring(eggId)) .. "\n" .. (if remaining > 0 then countdown(remaining) else Locale.T("incubator.label.ready"))
			end
		end
	end
end

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.5 then
		return
	end
	elapsed = 0
	drawCountdowns()
	if openBase then
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root or (root.Position - openBase.Position).Magnitude > CLOSE_DISTANCE then
			closePanel()
		else
			refresh()
		end
	end
end)

-- The server publishes the garden state on join (which a loading client may miss) and answers RequestState, but shares one
-- rate limit with GardenClient's request: ask again until the incubator state has arrived.
task.spawn(function()
	local requestStateEvent = remotes:WaitForChild("RequestState")
	for _ = 1, 10 do
		if incubators then
			return
		end
		requestStateEvent:FireServer()
		task.wait(2)
	end
end)
screenGui.Parent = player:WaitForChild("PlayerGui")
