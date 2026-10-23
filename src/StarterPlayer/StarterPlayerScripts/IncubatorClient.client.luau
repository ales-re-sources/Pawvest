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

local REJECT_TEXT = {
	coins = "Not enough Coins",
	stale = "Out of date, try again",
	maxed = "All incubators unlocked",
	locked = "Unlock this incubator first",
	occupied = "This incubator already holds an egg",
	full = "Your inventory is full (50 pets). Sell a pet first.",
	empty = "There is no egg in this incubator",
	notready = "Not ready yet",
	far = "Too far from your plot",
	noplot = "You have no plot on this server",
	loading = "Still loading...",
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
		local hours = seconds // 3600
		return hours .. (if hours == 1 then " hour" else " hours")
	end
	return seconds // 60 .. " min"
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
				string.format("<font color='%s'>%s %s %%</font>", hex(rarity.color), rarity.id, PetClient.Percent(weight))
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
	titleLabel.Text = "🥚 Incubator " .. index
	local entry = state.eggs[tostring(index)]
	local status, statusColor = "", COLOR_INFO

	if index > state.count then
		local nextIndex = state.count + 1
		bodyLabel.Text = "Incubators hatch eggs in real time, even while you are away."
		if index == nextIndex then
			local price = GardenConfig.IncubatorPrices[nextIndex]
			setAction(
				string.format("Unlock incubator %d: %s Coins", nextIndex, PetClient.Number(price)),
				if PetClient.Coins >= price then COLOR_BUY else COLOR_LOCKED
			)
		else
			setAction("Unlock incubator " .. nextIndex .. " first", COLOR_LOCKED)
			status = "Incubators are unlocked in order."
		end
	elseif entry then
		local name = PetConfig.Eggs[entry.egg] and PetConfig.Eggs[entry.egg].name or entry.egg
		local remaining = entry.readyAt - workspace:GetServerTimeNow()
		bodyLabel.Text = string.format("%s\n%s", name, odds(entry.egg))
		if remaining > 0 then
			status = "Hatches in " .. countdown(remaining)
			setAction("Hatching...", COLOR_LOCKED)
		else
			status, statusColor = "Ready to hatch!", COLOR_OK
			setAction("Hatch", COLOR_HATCH)
		end
	else
		local lines = { "Hatches in real time, also while you are away." }
		for _, eggId in PetConfig.EggOrder do
			local egg = PetConfig.Eggs[eggId]
			table.insert(lines, string.format("<b>%s</b> · %s\n%s", egg.name, hatchTime(egg.hatchSeconds), odds(eggId)))
		end
		bodyLabel.Text = table.concat(lines, "\n")
		setAction("", COLOR_LOCKED, false)
		for _, button in eggButtons do
			local egg = PetConfig.Eggs[button.id]
			button.button.Text = string.format("%s: %s", egg.name, PetClient.Number(egg.price))
			button.button.BackgroundColor3 = if PetClient.Coins >= egg.price then COLOR_BUY else COLOR_LOCKED
			button.button.Visible = true
		end
	end
	local waiting = waitingFreeEggs()
	if waiting > 0 and status == "" then
		status = string.format("🎁 %d free egg%s will start in the next empty incubator", waiting, if waiting == 1 then "" else "s")
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
		flash(REJECT_TEXT[detail] or "Request failed", COLOR_ERROR)
	elseif action == "BuyIncubator" then
		flash(string.format("Incubator %d unlocked", detail), COLOR_OK)
	elseif action == "StartEgg" then
		flash("The egg is warming up. Come back when it is ready!", COLOR_OK)
	elseif action == "Hatch" then
		local rarity = PetConfig.RarityById[detail.rarity]
		flash(
			string.format(
				"You got a <font color='%s'>%s (%s)</font>!%s",
				hex(rarity and rarity.color or Color3.new(1, 1, 1)),
				tostring(detail.kind),
				tostring(detail.rarity),
				if detail.equipped then " It follows you now." else " It is in your Pets panel."
			),
			COLOR_OK
		)
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
				local name = PetConfig.Eggs[eggId] and PetConfig.Eggs[eggId].name or "Egg"
				local remaining = readyAt - now
				text.Text = name .. "\n" .. (if remaining > 0 then countdown(remaining) else "✨ Ready!")
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
