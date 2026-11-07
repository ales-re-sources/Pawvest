-- Hatchery panel (U5b, docs/UI_GARDEN_PETS.md §7; was the per-incubator panel of P2b1 / P2b3): the own plot's hatchery has one
-- "Open hatchery" prompt (PlotView, GardenView.OnHatchery) that opens this panel (ScreenGui HatcheryGui, GardenUi.Panel):
--   * one row per incubator (the hatchery's nests): its egg with a live countdown and Hatch when ready; empty; the next one to buy
--     (Unlock brick with the price, two taps over ConfirmTap.THRESHOLD); later ones "unlock incubator n first";
--   * egg cards (K1) while an owned incubator is empty: the egg drawn in its colour, name, hatch time, a buy brick with the price
--     (two taps over the threshold) that starts it in the first empty incubator, and a "?" brick that shows its odds;
--   * the reveal on a Hatch answer: the pet's portrait, its kind in the rarity colour, where it went, then its traits as chips one
--     by one (P4: a cute pet is a lucky roll);
--   * waiting free eggs (the server starts them on its own); answers and refusals in a status line at the top;
--   * PanelFocus "Hatchery": opening it closes the other panels, walking 32 studs away closes it.
-- GardenView draws the eggs and their countdowns above every plot's nests (E1a1). Display only: a click names an incubator and an
-- egg; GardenIncubators validates ownership, price, the inventory cap and the hatch time against the server's os.time(). Countdowns use
-- workspace:GetServerTimeNow(). Hook (HatcheryGui attribute, cleared after use): Open = true opens the panel. Buttons by path (under
-- PlayerGui.HatcheryGui.Panel): Content.Nests.Nest<n>.Action, Content.Eggs.Cards.<EggId>.Buy / .Odds, Reveal.Ok, Close.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local PanelFocus = require(ReplicatedStorage:WaitForChild("PanelFocus"))
local ConfirmTap = require(ReplicatedStorage:WaitForChild("ConfirmTap"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))
local PetPortrait = require(script.Parent:WaitForChild("PetPortrait"))
local PetRow = require(script.Parent:WaitForChild("PetRow"))
local GardenView = require(script.Parent:WaitForChild("GardenView"))
local GardenUi = require(script.Parent:WaitForChild("GardenUi"))

local remotes = ReplicatedStorage:WaitForChild("GardenRemotes")
-- looked up by name (never `remotes.X`: a name like Remove would resolve to an Instance method)
local startEggEvent = remotes:WaitForChild("StartEgg")
local hatchEvent = remotes:WaitForChild("Hatch")
local buyIncubatorEvent = remotes:WaitForChild("BuyIncubator")

local WIDTH = 420
local HEIGHT = 500
local GAP = GardenUi.GAP
local ACTION_WIDTH = 132 -- the row's brick (Hatch / Unlock)
local EGG_W, EGG_H = 44, 56 -- the drawn egg on a card
local CHIP_DELAY = 0.4 -- seconds between the reveal's trait chips
local PORTRAIT = 132

local COLOR_PANEL = StudStyle.PanelColors.Incubator
local COLOR_ROW = StudStyle.PetRowColor(COLOR_PANEL)
local COLOR_HATCH = StudStyle.Colors.Purple -- stands out on the yellow panel
local COLOR_CHIP = Color3.fromRGB(28, 28, 28)

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

local function hex(color: Color3): string
	return string.format("#%02x%02x%02x", math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255))
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
				string.format("<font color='%s'>%s %s %%</font>", hex(rarity.color), Locale.RarityName(rarity.id), Locale.Decimal(PetClient.Percent(weight)))
			)
		end
	end
	return table.concat(parts, " · ")
end

-- Panel ----------------------------------------------------------------------------------------------------------------------

local ui = GardenUi.Panel("HatcheryGui", COLOR_PANEL, WIDTH, HEIGHT)
local statusSection = GardenUi.Section("Status", 1)
local nestsSection = GardenUi.Section("Nests", 2)
local eggsSection = GardenUi.Section("Eggs", 3)
statusSection.Parent = ui.content
nestsSection.Parent = ui.content
eggsSection.Parent = ui.content

-- the reveal: a page over the panel's content
local reveal = GardenUi.Create("Frame", {
	Name = "Reveal",
	Position = UDim2.new(0, 8, 0, 46),
	Size = UDim2.new(1, -16, 1, -54),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = ui.panel,
}, {
	GardenUi.Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 10),
	}),
	GardenUi.Create("UIPadding", { PaddingTop = UDim.new(0, 6) }),
})
local revealTitle = GardenUi.Label("Title", {
	LayoutOrder = 1,
	Size = UDim2.new(1, 0, 0, 30),
	TextSize = 24,
	TextXAlignment = Enum.TextXAlignment.Center,
	Text = "",
	Parent = reveal,
})
local revealHolder: Frame? = nil -- PetPortrait.Holder, LayoutOrder 2 (rebuilt per hatch)
local revealName = GardenUi.Paragraph("PetName", {
	LayoutOrder = 3,
	Font = StudStyle.Font,
	TextSize = 22,
	TextXAlignment = Enum.TextXAlignment.Center,
	RichText = true,
	Text = "",
	Parent = reveal,
})
local revealLine = GardenUi.Paragraph("Line", { LayoutOrder = 4, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Center, Text = "", Parent = reveal })
local revealChips = GardenUi.Create("Frame", {
	Name = "Chips",
	LayoutOrder = 5,
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Parent = reveal,
}, {
	GardenUi.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Wraps = true,
		Padding = UDim.new(0, GAP),
	}),
})
local revealOk = GardenUi.Button("Ok", {
	LayoutOrder = 6,
	Size = UDim2.fromOffset(160, 48),
	BackgroundColor3 = GardenUi.COLOR_BUY,
	TextSize = 18,
	Parent = reveal,
}, 3)

local isOpen = false
local incubators = nil -- last GardenRemotes.State.incubators: { count, eggs = { ["n"] = { egg, readyAt } } }
local status: { text: string, color: Color3 }? = nil -- the last answer, shown for STATUS_SECONDS
local statusToken = 0
local oddsShown: string? = nil -- egg id whose odds are shown
local countdowns = {} -- { { label, readyAt } } of the drawn rows
local revealToken = 0
local STATUS_SECONDS = 5

local render -- defined below

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

local function firstEmpty(state): number?
	for n = 1, state.count do
		if not state.eggs[tostring(n)] then
			return n
		end
	end
	return nil
end

local function setStatus(text: string, color: Color3)
	statusToken += 1
	local mine = statusToken
	status = { text = text, color = color }
	render()
	task.delay(STATUS_SECONDS, function()
		if statusToken == mine then
			status = nil
			render()
		end
	end)
end

-- Rendering ------------------------------------------------------------------------------------------------------------------

local function renderStatus()
	GardenUi.Clear(statusSection)
	local waiting = waitingFreeEggs()
	if status then
		GardenUi.Paragraph("Message", { LayoutOrder = 1, Font = StudStyle.Font, TextSize = 16, TextColor3 = status.color, RichText = true, Text = status.text }).Parent =
			statusSection
	end
	if waiting > 0 then
		GardenUi.Paragraph("FreeEggs", { LayoutOrder = 2, TextSize = 14, Text = Locale.T("incubator.freeEggs", { count = waiting }) }).Parent = statusSection
	end
end

local function renderNests(state, tap: number)
	GardenUi.Clear(nestsSection)
	table.clear(countdowns)
	local now = workspace:GetServerTimeNow()
	for n = 1, GardenConfig.MaxIncubators do
		local entry = state.eggs[tostring(n)]
		local row = GardenUi.Row(nestsSection, "Nest" .. n, n, COLOR_ROW)
		local function action(text: string, color: Color3): TextButton
			return GardenUi.Button("Action", {
				LayoutOrder = 2,
				Size = UDim2.fromOffset(ACTION_WIDTH, tap),
				BackgroundColor3 = color,
				TextSize = 15,
				TextWrapped = true,
				Text = text,
				Parent = row,
			}, 2)
		end
		if n > state.count then
			local nextIndex = state.count + 1
			if n == nextIndex then
				local price = GardenConfig.IncubatorPrices[n]
				GardenUi.TextColumn(row, ACTION_WIDTH + GAP, "🔒 " .. Locale.T("incubator.title", { n = n }), Locale.T("incubator.body.locked"))
				local unlock = action(Locale.T("hatchery.unlock", { count = price }), if PetClient.Coins >= price then GardenUi.COLOR_BUY else GardenUi.COLOR_LOCKED)
				ConfirmTap.Wrap(unlock, "Unlock" .. n, function()
					return ConfirmTap.Over(price)
				end, function()
					buyIncubatorEvent:FireServer(n)
				end)
			else
				GardenUi.TextColumn(row, 0, "🔒 " .. Locale.T("incubator.title", { n = n }), Locale.T("incubator.unlockFirst", { n = nextIndex }))
			end
		elseif entry then
			local remaining = entry.readyAt - now
			local egg = PetConfig.Eggs[entry.egg]
			local title = string.format("%s · %s", Locale.T("incubator.title", { n = n }), eggName(entry.egg))
			if remaining > 0 then
				local column = GardenUi.TextColumn(row, 0, title, Locale.T("incubator.hatchesIn", { time = GardenUi.Countdown(remaining) }))
				table.insert(countdowns, { label = column:FindFirstChild("Info"), readyAt = entry.readyAt })
			else
				local column = GardenUi.TextColumn(row, ACTION_WIDTH + GAP, title, Locale.T("incubator.ready"))
				local info = column:FindFirstChild("Info") :: TextLabel?
				if info then
					info.TextColor3 = GardenUi.COLOR_OK
				end
				local hatch = action(Locale.T("incubator.hatch"), COLOR_HATCH)
				hatch.Activated:Connect(function()
					hatchEvent:FireServer(n) -- the server checks the time itself
				end)
			end
			if egg and egg.look then
				row.BackgroundColor3 = COLOR_ROW:Lerp(egg.look.color, 0.18)
			end
		else
			GardenUi.TextColumn(row, 0, Locale.T("incubator.title", { n = n }), Locale.T("hatchery.nest.empty"))
		end
	end
end

-- An egg drawn as a rounded oval in the egg's colour.
local function eggPicture(eggId: string): Frame
	local egg = PetConfig.Eggs[eggId]
	local look = egg and egg.look
	local picture = GardenUi.Create("Frame", {
		Name = "Picture",
		LayoutOrder = 1,
		Size = UDim2.fromOffset(EGG_W, EGG_H),
		BackgroundColor3 = if look then look.color else Color3.fromRGB(236, 228, 208),
	}, {
		GardenUi.Create("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
		GardenUi.Create("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = 0.5, Thickness = 2 }),
		-- a highlight on the upper left
		GardenUi.Create("Frame", {
			Name = "Shine",
			Position = UDim2.fromScale(0.22, 0.16),
			Size = UDim2.fromScale(0.22, 0.2),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.45,
		}, { GardenUi.Create("UICorner", { CornerRadius = UDim.new(0.5, 0) }) }),
	})
	if look and look.glow then
		GardenUi.Create("UIStroke", { Color = look.color, Thickness = 3, Transparency = 0.2, Parent = picture })
	end
	return picture
end

local function renderEggs(state, tap: number)
	GardenUi.Clear(eggsSection)
	local target = firstEmpty(state)
	GardenUi.Heading(eggsSection, 1, Locale.T("hatchery.eggs"), COLOR_PANEL)
	if not target then
		GardenUi.Paragraph("Busy", { LayoutOrder = 2, Text = Locale.T("hatchery.busy") }).Parent = eggsSection
		return
	end
	GardenUi.Paragraph("Hint", { LayoutOrder = 2, TextSize = 13, TextColor3 = GardenUi.COLOR_DIM, Text = Locale.T("hatchery.eggs.hint", { n = target }) }).Parent =
		eggsSection
	local cards = GardenUi.Create("Frame", {
		Name = "Cards",
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = eggsSection,
	}, {
		GardenUi.Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, GAP) }),
	})
	local count = #PetConfig.EggOrder
	for order, eggId in PetConfig.EggOrder do
		local egg = PetConfig.Eggs[eggId]
		local card = GardenUi.Create("Frame", {
			Name = eggId,
			LayoutOrder = order,
			Size = UDim2.new(1 / count, -GAP * (count - 1) / count, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = COLOR_ROW,
			Parent = cards,
		}, {
			GardenUi.Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
			GardenUi.Create("UIPadding", {
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
			}),
			GardenUi.Create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 4),
			}),
		})
		eggPicture(eggId).Parent = card
		GardenUi.Paragraph("Name", {
			LayoutOrder = 2,
			Font = StudStyle.Font,
			TextSize = 17,
			TextColor3 = Color3.new(1, 1, 1),
			TextXAlignment = Enum.TextXAlignment.Center,
			Text = eggName(eggId),
		}).Parent = card
		GardenUi.Paragraph("Time", {
			LayoutOrder = 3,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Center,
			Text = Locale.T("hatchery.egg.time", { time = GardenUi.GrowTime(egg.hatchSeconds) }),
		}).Parent = card
		local bricks = GardenUi.Create("Frame", {
			Name = "Bricks",
			LayoutOrder = 4,
			Size = UDim2.new(1, 0, 0, tap),
			BackgroundTransparency = 1,
			Parent = card,
		}, {
			GardenUi.Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, GAP) }),
		})
		local buy = GardenUi.Button("Buy", {
			LayoutOrder = 1,
			Size = UDim2.new(1, -(tap + GAP), 0, tap),
			BackgroundColor3 = if PetClient.Coins >= egg.price then GardenUi.COLOR_BUY else GardenUi.COLOR_LOCKED,
			TextSize = 16,
			TextWrapped = true,
			Text = Locale.T("hatchery.egg.buy", { count = egg.price }),
			Parent = bricks,
		}, 2)
		ConfirmTap.Wrap(buy, "Egg" .. eggId, function()
			return ConfirmTap.Over(egg.price)
		end, function()
			local now = incubators and firstEmpty(incubators)
			if now then
				startEggEvent:FireServer(now, eggId)
			end
		end)
		local oddsButton = GardenUi.Button("Odds", {
			LayoutOrder = 2,
			Size = UDim2.fromOffset(tap, tap),
			BackgroundColor3 = if oddsShown == eggId then StudStyle.Colors.Blue else GardenUi.COLOR_LOCKED,
			TextSize = 18,
			Text = Locale.T("hatchery.odds.button"),
			Parent = bricks,
		}, 1)
		oddsButton.Activated:Connect(function()
			oddsShown = if oddsShown == eggId then nil else eggId
			render()
		end)
	end
	if oddsShown and PetConfig.Eggs[oddsShown] then
		GardenUi.Paragraph("Odds", {
			LayoutOrder = 4,
			TextSize = 14,
			RichText = true,
			Text = Locale.T("hatchery.odds", { egg = eggName(oddsShown), odds = odds(oddsShown) }),
		}).Parent = eggsSection
	end
end

render = function()
	ui.title.Text = Locale.T("hatchery.title")
	revealOk.Text = Locale.T("hatchery.reveal.ok")
	if not isOpen then
		return
	end
	local state = incubators
	renderStatus()
	if not state then
		GardenUi.Clear(nestsSection)
		GardenUi.Clear(eggsSection)
		GardenUi.Paragraph("Loading", { Text = Locale.T("common.loading") }).Parent = nestsSection
		return
	end
	local tap = ui.TapHeight()
	renderNests(state, tap)
	renderEggs(state, tap)
end

-- Reveal ---------------------------------------------------------------------------------------------------------------------

local function chip(trait, level: number, order: number): Frame
	return GardenUi.Create("Frame", {
		Name = "Chip_" .. trait.id,
		LayoutOrder = order,
		Size = UDim2.fromOffset(0, 34),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = COLOR_CHIP,
	}, {
		GardenUi.Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
		GardenUi.Create("UIStroke", { Color = trait.color, Thickness = 2 }),
		GardenUi.Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
		GardenUi.Label("Text", {
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 17,
			TextColor3 = trait.color,
			TextStrokeTransparency = 0.6,
			Text = string.format("%s %s %s", trait.icon, Locale.T("pet.apt." .. trait.id), Locale.Number(level)),
		}),
	})
end

local function showContent()
	revealToken += 1
	reveal.Visible = false
	ui.content.Visible = true
end

local function showReveal(detail)
	revealToken += 1
	local mine = revealToken
	ui.content.Visible = false
	reveal.Visible = true
	local rarity = PetConfig.RarityById[detail.rarity]
	local stored = PetClient.State and PetClient.State.pets[detail.uid]
	revealTitle.Text = Locale.T("hatchery.reveal.title")
	revealName.Text = string.format(
		"<font color='%s'>%s</font>\n<font size='15' color='%s'>%s</font>",
		hex(if rarity then rarity.color else Color3.new(1, 1, 1)),
		Locale.PetKindName(tostring(detail.kind)),
		hex(if rarity then rarity.color else Color3.new(1, 1, 1)),
		Locale.RarityName(tostring(detail.rarity))
	)
	revealLine.Text = Locale.T(if detail.equipped then "hatchery.reveal.follows" else "hatchery.reveal.panel")
	if revealHolder then
		revealHolder:Destroy()
	end
	local level = if stored then PetConfig.PetLevel(stored) else 1
	revealHolder = PetPortrait.Holder({
		LayoutOrder = 2,
		Size = UDim2.fromOffset(PORTRAIT, PORTRAIT),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
	}, PetPortrait.Make(tostring(detail.kind), level, detail.uid))
	local stroke = Instance.new("UIStroke")
	stroke.Color = if rarity then rarity.color else Color3.new(1, 1, 1)
	stroke.Thickness = 3
	stroke.Parent = revealHolder
	revealHolder.Parent = reveal
	for _, child in revealChips:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local traits = if type(detail.traits) == "table" then detail.traits else {}
	task.spawn(function()
		for order, id in traits do
			local trait = PetRow.ByTrait[id]
			if trait then
				task.wait(CHIP_DELAY)
				if revealToken ~= mine then
					return
				end
				local now = PetClient.State and PetClient.State.pets[detail.uid]
				chip(trait, if now then math.max(1, PetConfig.AptitudeLevel(now, id)) else 1, order).Parent = revealChips
			end
		end
	end)
end

-- Open / close ---------------------------------------------------------------------------------------------------------------

local function closePanel()
	PanelFocus.Closed("Hatchery")
	isOpen = false
	showContent()
	ui.panel.Visible = false
	ConfirmTap.Reset()
end

local function openPanel()
	PanelFocus.Open("Hatchery", closePanel) -- walking 32 studs away closes it
	isOpen = true
	showContent()
	ui.Fit()
	ui.panel.Visible = true
	render()
end

ui.close.Activated:Connect(closePanel)
revealOk.Activated:Connect(function()
	showContent()
	render()
end)

-- Events ---------------------------------------------------------------------------------------------------------------------

remotes:WaitForChild("State").OnClientEvent:Connect(function(state)
	if type(state) == "table" and type(state.incubators) == "table" then
		incubators = state.incubators
		render()
	end
end)
PetClient.Changed:Connect(function()
	if isOpen and not reveal.Visible then
		render()
	end
end)
Locale.Changed:Connect(render)

remotes:WaitForChild("Result").OnClientEvent:Connect(function(action, ok, detail)
	if action ~= "StartEgg" and action ~= "Hatch" and action ~= "BuyIncubator" then
		return
	end
	if not ok then
		setStatus(Locale.T(REJECT_KEYS[detail] or "common.reject.failed", { max = PetConfig.MaxPets }), GardenUi.COLOR_ERROR)
	elseif action == "BuyIncubator" then
		setStatus(Locale.T("incubator.unlocked", { n = detail }), GardenUi.COLOR_OK)
	elseif action == "StartEgg" then
		setStatus(Locale.T("incubator.started"), GardenUi.COLOR_OK)
	elseif action == "Hatch" and type(detail) == "table" and isOpen then
		showReveal(detail)
	end
end)

GardenView.OnHatchery(function()
	if not isOpen then
		openPanel()
	end
end)

ui.gui:GetAttributeChangedSignal("Open"):Connect(function()
	if ui.gui:GetAttribute("Open") then
		ui.gui:SetAttribute("Open", nil)
		openPanel()
	end
end)

-- Every 0.5 s while open: the countdowns; a row that reached its time redraws (Hatch appears)
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.5 or not isOpen then
		return
	end
	elapsed = 0
	local now = workspace:GetServerTimeNow()
	for _, entry in countdowns do
		local remaining = entry.readyAt - now
		if remaining <= 0 then
			if not reveal.Visible then
				render()
			end
			return
		end
		if entry.label then
			entry.label.Text = Locale.T("incubator.hatchesIn", { time = GardenUi.Countdown(remaining) })
		end
	end
end)

ui.gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
render()
