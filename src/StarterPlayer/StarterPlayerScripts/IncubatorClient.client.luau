-- Hatchery panel: the farm HUD button beside Barn (ready-egg badge) or a click/tap on any own pod opens this panel.
-- World entry: PlotView → GardenView.OnHatchery; no hatchery E prompt. ScreenGui HatcheryGui, GardenUi.Panel:
--   * one row per incubator: egg + countdown, small trash brick → orange OK? → discard (ConfirmTap), Hatch when ready;
--     empty; the next one to buy
--     (Unlock brick with the price, two taps over ConfirmTap.THRESHOLD); later ones "unlock incubator n first";
--   * egg cards (K1), two a row, while an owned incubator is empty: the egg drawn in its colour, name, hatch time, a buy brick with
--     the price (two taps over the threshold) that starts it in the first empty incubator, and "?" for odds (with the kinds under
--     each rarity, a silhouette until owned, EG), rarity times and rules; an egg whose crop is not open shows 🔒 + the crop's icon;
--   * on a Hatch answer, HatchReveal over the content: the egg wobbles and bursts, the pet pops in, then a summary (rarity and the
--     egg's chance of it, where it went, every trait it was born with and what it does) with View pet / Great!;
--   * waiting free eggs (the server starts them on its own); answers and refusals in a status line at the top;
--   * PanelFocus "Hatchery": opening it closes the other panels, walking 32 studs away closes it.
-- GardenView draws the eggs and their countdowns above every plot's nests (E1a1). Display only: a click names an incubator and an
-- egg; GardenIncubators validates ownership, price, the inventory cap and the hatch time against the server's os.time(). Countdowns use
-- workspace:GetServerTimeNow(). Hook (HatcheryGui attribute, cleared after use): Open = true opens the panel. Buttons by path (under
-- PlayerGui.HatcheryGui.Panel): Content.Nests.Content.Nest<n>.Action, Content.Eggs.Content.Cards.<EggId>.Buy / .Odds,
-- Reveal.Buttons.Ok / .View, Reveal.Skip, Close.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local EggLook = require(ReplicatedStorage:WaitForChild("EggLook"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local PanelFocus = require(ReplicatedStorage:WaitForChild("PanelFocus"))
local ConfirmTap = require(ReplicatedStorage:WaitForChild("ConfirmTap"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))
local PetPortrait = require(script.Parent:WaitForChild("PetPortrait"))
local HatchReveal = require(script.Parent:WaitForChild("HatchReveal"))
local GardenView = require(script.Parent:WaitForChild("GardenView"))
local GardenUi = require(script.Parent:WaitForChild("GardenUi"))
local UiKit = require(ReplicatedStorage:WaitForChild("UiKit"))
local Onboarding = require(script.Parent:WaitForChild("Onboarding"))

local remotes = ReplicatedStorage:WaitForChild("GardenRemotes")
-- looked up by name (never `remotes.X`: a name like Remove would resolve to an Instance method)
local startEggEvent = remotes:WaitForChild("StartEgg")
local hatchEvent = remotes:WaitForChild("Hatch")
local cancelEggEvent = remotes:WaitForChild("CancelEgg")
local buyIncubatorEvent = remotes:WaitForChild("BuyIncubator")

local WIDTH = 420
local HEIGHT = 500
local GAP = GardenUi.GAP
local ACTION_WIDTH = 132 -- the row's brick (Hatch / Unlock)
local EGG_W, EGG_H = 64, 76 -- the shared 3D egg on a card

local COLOR_PANEL = StudStyle.PanelColors.Incubator
local COLOR_ROW = StudStyle.PetRowColor(COLOR_PANEL)
local COLOR_HATCH = StudStyle.Colors.Purple -- stands out on the yellow panel

local REJECT_KEYS = { -- the rest: Locale.Reject's common.reject.*
	maxed = "incubator.reject.maxed",
	locked = "incubator.reject.locked",
	occupied = "incubator.reject.occupied",
	full = "incubator.reject.full",
	empty = "incubator.reject.empty",
	notready = "incubator.reject.notready",
	eggLocked = "incubator.reject.eggLocked",
}
local KIND_SIZE = 44 -- the odds panel's pet portraits (EG)
local COLOR_UNSEEN = Color3.fromRGB(25, 22, 30) -- a kind never owned: a dark silhouette

local function eggName(eggId: string): string
	local egg = PetConfig.Eggs[eggId]
	return if egg then Locale.EggName(egg) else eggId
end

-- One portrait per pet kind, built once and reparented on every render (PetPortrait.Release before the section is cleared).
local kindPortraits = {} -- [kind] = ViewportFrame | false (no model)
local function kindPortrait(kind: string): ViewportFrame?
	if kindPortraits[kind] == nil then
		kindPortraits[kind] = PetPortrait.Make(kind, 1) or false
	end
	return kindPortraits[kind] or nil
end

-- EG: the kinds an egg can hatch under each rarity row, in colour once owned (PetsChanged seenKinds), else a dark silhouette.
local function renderKinds(rarityId: string, order: number, parent: Instance)
	local seen = PetClient.State and type(PetClient.State.seenKinds) == "table" and PetClient.State.seenKinds or {}
	local row = GardenUi.Create("Frame", {
		Name = rarityId .. "Kinds", LayoutOrder = order, Size = UDim2.new(1, 0, 0, KIND_SIZE), BackgroundTransparency = 1, Parent = parent,
	}, {
		GardenUi.Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, GAP),
		}),
	})
	for index, kind in PetConfig.KindsByRarity[rarityId] do
		local portrait = kindPortrait(kind)
		local known = seen[kind] == true
		if portrait then
			portrait.ImageColor3 = if known then Color3.new(1, 1, 1) else COLOR_UNSEEN
		end
		local holder = PetPortrait.Holder({
			Name = kind, LayoutOrder = index, Size = UDim2.fromOffset(KIND_SIZE, KIND_SIZE),
			BackgroundColor3 = StudStyle.Shade(COLOR_ROW, if known then 0.8 else 0.6), Parent = row,
		}, portrait)
		holder:SetAttribute("Seen", known) -- tests read it
	end
end

-- Odds as separate rows: rarity and aligned chance, then the kinds of that rarity. Hatch duration stays out of this table.
local function renderOdds(eggId: string, parent: Instance)
	local section = GardenUi.Section("Odds", 4)
	section.Parent = parent
	GardenUi.Paragraph("Title", { LayoutOrder = 0, Font = StudStyle.Font, TextSize = 16, Text = eggName(eggId), Parent = section })
	for _, rarity in PetConfig.Rarities do
		local weight = PetConfig.Eggs[eggId].weights[rarity.id]
		if weight and weight > 0 then
			renderKinds(rarity.id, rarity.order * 2 + 1, section)
			local row = GardenUi.Create("Frame", {
				Name = rarity.id, LayoutOrder = rarity.order * 2, Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = section,
			}, {
				GardenUi.Create("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, GAP),
				}),
			})
			GardenUi.Paragraph("Rarity", {
				LayoutOrder = 1, Size = UDim2.new(0.7, -GAP, 0, 0), TextSize = 14,
				TextColor3 = rarity.color, Text = Locale.RarityName(rarity.id), Parent = row,
			})
			GardenUi.Paragraph("Chance", {
				LayoutOrder = 2, Size = UDim2.new(0.3, 0, 0, 0), TextSize = 14, Font = StudStyle.Font,
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = Locale.T("hatchery.odds.chance", { chance = Locale.Decimal(PetClient.Percent(weight)) }), Parent = row,
			})
		end
	end
end

-- Panel ----------------------------------------------------------------------------------------------------------------------

local ui = GardenUi.Panel("HatcheryGui", COLOR_PANEL, WIDTH, HEIGHT)
local openButton = GardenUi.Button("Open", {
	Size = UDim2.fromOffset(132, StudStyle.Sizes.HudButton), BackgroundColor3 = COLOR_PANEL,
	TextSize = 18, Visible = false, Parent = ui.gui,
}, { compact = true })
GardenUi.FarmButton(openButton, 2)
local readyBadge = GardenUi.Label("ReadyBadge", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -2, 0, 0), Size = UDim2.fromOffset(22, 22),
	BackgroundTransparency = 0, BackgroundColor3 = StudStyle.Colors.Red, TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Center, Text = "", Visible = false, ZIndex = 5, Parent = openButton,
})
GardenUi.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = readyBadge })
local statusSection = GardenUi.Section("Status", 1)
local nestsSection, nestsLegend = GardenUi.GroupBox(ui.content, "Nests", 2, COLOR_PANEL)
local eggsSection, eggsLegend = GardenUi.GroupBox(ui.content, "Eggs", 3, COLOR_PANEL)
statusSection.Parent = ui.content

-- the reveal: a page over the panel's content (HatchReveal); callbacks below
local render, showContent, viewPet -- defined below
local hatchReveal = HatchReveal.new(ui.panel, {
	onDone = function()
		showContent()
		render()
	end,
	onViewPet = function(uid: string)
		viewPet(uid)
	end,
})
local reveal = hatchReveal.frame

local isOpen = false
local incubators = nil -- private State: { count, eggs = { ["n"] = { id, egg, startedAt, readyAt } } }; kind stays server-only
local status: { text: string, color: Color3 }? = nil -- the last answer, shown for STATUS_SECONDS
local statusTimer = GardenUi.Latest()
local oddsShown: string? = nil -- egg id whose odds are shown
local countdowns = {} -- { { label, readyAt } } of the drawn rows
local STATUS_SECONDS = 5


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
	status = { text = text, color = color }
	render()
	statusTimer.After(STATUS_SECONDS, function()
		status = nil
		render()
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
				local scanning = GardenConfig.EggPhase(entry.startedAt, entry.readyAt, now) == "scanning"
				local column = GardenUi.TextColumn(row, tap + GAP, title, if scanning then Locale.T("incubator.scanning")
					else Locale.T("incubator.hatchesIn", { time = GardenUi.Countdown(remaining) }))
				table.insert(countdowns, { label = column:FindFirstChild("Info"), readyAt = entry.readyAt, startedAt = entry.startedAt })
				local key = "CancelEgg" .. entry.id
				local armed = ConfirmTap.IsArmed(key)
				local cancel = action(if armed then Locale.T("incubator.cancel.tapAgain") else "",
					if armed then ConfirmTap.COLOR else StudStyle.Colors.Red)
				cancel.Size = UDim2.fromOffset(tap, tap)
				if not armed then
					GardenUi.TrashIcon(cancel)
				end
				cancel.Activated:Connect(function()
					local current = incubators and incubators.eggs[tostring(n)]
					if current and current.id == entry.id and current.readyAt > workspace:GetServerTimeNow() then
						if ConfirmTap.Tap(key, function()
							if isOpen and not reveal.Visible then render() end
						end) then
							cancelEggEvent:FireServer(n, entry.id)
						end
					else
						ConfirmTap.Disarm(key)
					end
					render()
				end)
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

-- The same cross-lapped brick recipe as the world nests.
local function eggPicture(eggId: string): ViewportFrame
	local picture = EggLook.Portrait(eggId, UDim2.fromOffset(EGG_W, EGG_H))
	picture.LayoutOrder = 1
	return picture
end

local function renderEggs(state, tap: number)
	PetPortrait.Release(eggsSection) -- the cached kind portraits survive the clear
	GardenUi.Clear(eggsSection)
	local target = firstEmpty(state)
	if not target then
		GardenUi.Paragraph("Busy", { LayoutOrder = 2, Text = Locale.T("hatchery.busy") }).Parent = eggsSection
		return
	end
	local cards = GardenUi.Create("Frame", {
		Name = "Cards",
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = eggsSection,
	}, {
		-- EG: two cards a row (four eggs did not fit one row with a buy brick and "?")
		GardenUi.Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, GAP), Wraps = true,
		}),
	})
	local unlocked = GardenUi.Mastery(GardenView.OwnField()).unlocked
	for order, eggId in PetConfig.EggOrder do
		local egg = PetConfig.Eggs[eggId]
		local open = PetConfig.EggOpen(egg, unlocked)
		local opener = egg.opensWith and CropConfig.ById[egg.opensWith]
		local shortest, longest = math.huge, 0
		for rarity, weight in egg.weights do
			if weight > 0 then
				shortest = math.min(shortest, PetConfig.HatchSeconds[rarity])
				longest = math.max(longest, PetConfig.HatchSeconds[rarity])
			end
		end
		local card = GardenUi.Create("Frame", {
			Name = eggId,
			LayoutOrder = order,
			Size = UDim2.new(0.5, -GAP / 2, 0, 0),
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
			Text = Locale.T("hatchery.egg.time", { time = GardenUi.GrowTime(shortest), max = GardenUi.GrowTime(longest) }),
		}).Parent = card
		if not open and opener then
			GardenUi.Paragraph("OpensWith", {
				LayoutOrder = 3,
				TextSize = 13,
				TextColor3 = GardenUi.COLOR_INFO,
				TextXAlignment = Enum.TextXAlignment.Center,
				Text = Locale.T("hatchery.egg.opensWith", { crop = Locale.CropName(opener) }),
			}).Parent = card
		end
		local bricks = GardenUi.Create("Frame", {
			Name = "Bricks",
			LayoutOrder = 4,
			Size = UDim2.new(1, 0, 0, tap),
			BackgroundTransparency = 1,
			Parent = card,
		}, {
			GardenUi.Create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, GAP),
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
		})
		if open then
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
		else -- EG: the crop that opens it, as the seed stall's lock bar
			GardenUi.Paragraph("Locked", {
				LayoutOrder = 1,
				Size = UDim2.new(1, -(tap + GAP), 0, 0),
				Font = StudStyle.Font,
				TextSize = 18,
				TextColor3 = GardenUi.COLOR_DIM,
				TextXAlignment = Enum.TextXAlignment.Center,
				Text = Locale.T("hatchery.egg.lockIcon", { icon = opener and opener.icon or "" }),
			}).Parent = bricks
		end
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
		renderOdds(oddsShown, eggsSection)
		GardenUi.Paragraph("Rules", { LayoutOrder = 5, TextSize = 14, Text = Locale.T("hatchery.odds.rules") }).Parent = eggsSection
	end
end

render = function()
	openButton.Text = Locale.T("hatchery.button")
	ui.title.Text = Locale.T("hatchery.title")
	nestsLegend.Text = Locale.T("hatchery.group.nests")
	eggsLegend.Text = Locale.T("hatchery.eggs")
	hatchReveal.Layout(math.max(48, ui.TapHeight()))
	reveal.Position = UDim2.fromOffset(8, ui.HeaderHeight() + 6)
	reveal.Size = UDim2.new(1, -16, 1, -(ui.HeaderHeight() + 14))
	if not isOpen then
		return
	end
	local state = incubators
	renderStatus()
	if not state then
		GardenUi.Clear(nestsSection)
		PetPortrait.Release(eggsSection)
		GardenUi.Clear(eggsSection)
		GardenUi.Paragraph("Loading", { Text = Locale.T("common.loading") }).Parent = nestsSection
		return
	end
	local tap = ui.TapHeight()
	renderNests(state, tap)
	renderEggs(state, tap)
end

-- Reveal ---------------------------------------------------------------------------------------------------------------------

showContent = function()
	hatchReveal.Hide()
	ui.content.Visible = true
end

local function showReveal(detail)
	ui.content.Visible = false
	hatchReveal.Show(detail)
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

openButton.Activated:Connect(openPanel)

ui.close.Activated:Connect(closePanel)
-- View pet: the Pets panel opens at the pet's page (PanelFocus closes this panel)
viewPet = function(uid: string)
	local petsGui = Players.LocalPlayer.PlayerGui:FindFirstChild("PetsGui")
	if petsGui then
		petsGui:SetAttribute("OpenPet", uid)
	end
end

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
	if action ~= "StartEgg" and action ~= "Hatch" and action ~= "BuyIncubator" and action ~= "CancelEgg" then
		return
	end
	if not ok then
		setStatus(Locale.Reject(detail, REJECT_KEYS, { max = PetConfig.MaxPets }), GardenUi.COLOR_ERROR)
	elseif action == "BuyIncubator" then
		setStatus(Locale.T("incubator.unlocked", { n = detail }), GardenUi.COLOR_OK)
	elseif action == "StartEgg" then
		setStatus(Locale.T("incubator.started"), GardenUi.COLOR_OK)
	elseif action == "CancelEgg" then
		setStatus(Locale.T("incubator.cancelled"), GardenUi.COLOR_OK)
	elseif action == "Hatch" and type(detail) == "table" and isOpen then
		showReveal(detail)
	end
end)

GardenView.OnHatchery(function()
	local distance = GardenView.FlatDistanceToPlot()
	if not isOpen and distance and distance <= 45 then
		openPanel()
	end
end)

ui.gui:GetAttributeChangedSignal("Open"):Connect(function()
	if ui.gui:GetAttribute("Open") then
		ui.gui:SetAttribute("Open", nil)
		openPanel()
	end
end)

-- Own-pod hover each frame; HUD / ready badge and open-panel countdowns every 0.25 s.
local POD_CLICK_DISTANCE = 60 -- PlotView's OpenHatchery ClickDetector range while the world takes clicks
local hoverParams = RaycastParams.new()
hoverParams.FilterType = Enum.RaycastFilterType.Include
local function updatePodHover()
	local root = GardenView.OwnRoot()
	if not root then return end
	local hit = nil
	local camera = workspace.CurrentCamera
	local distance = GardenView.FlatDistanceToPlot()
	local point = UserInputService:GetMouseLocation()
	-- a panel is open or a GUI covers the pointer: the pods take no click, so their ClickDetector must not show its hand either
	-- (a passive panel's InputSink does not hide a ClickDetector's cursor)
	local worldFree = PanelFocus.Current() == nil and not UiKit.BlocksWorld(Players.LocalPlayer.PlayerGui, UiKit.PointerPosition())
	if camera and distance and distance <= 45 and worldFree and UserInputService.MouseEnabled
		and UserInputService:GetLastInputType() ~= Enum.UserInputType.Touch then
		hoverParams.FilterDescendantsInstances = { root }
		local ray = camera:ViewportPointToRay(point.X, point.Y)
		hit = workspace:Raycast(ray.Origin, ray.Direction * 300, hoverParams)
	end
	for n = 1, GardenConfig.MaxIncubators do
		local piece = GardenView.OwnPiece("inc" .. n)
		local hover = piece and piece:FindFirstChild("Hover")
		if hover then hover.Enabled = hit ~= nil and hit.Instance:IsDescendantOf(piece) end
		local click = piece and piece:FindFirstChild("OpenHatchery", true) :: ClickDetector?
		if click then click.MaxActivationDistance = if worldFree then POD_CLICK_DISTANCE else 0 end
	end
end
local setOpenPulse = GardenUi.Pulse(openButton)
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	updatePodHover()
	elapsed += dt
	if elapsed < 0.25 then
		return
	end
	elapsed = 0
	local now = workspace:GetServerTimeNow()
	local distance = GardenView.FlatDistanceToPlot()
	openButton.Visible = not isOpen and PanelFocus.Current() == nil and distance ~= nil and distance <= 45
	local ready = 0
	if incubators then
		for _, egg in incubators.eggs do
			if egg.readyAt <= now then ready += 1 end
		end
	end
	readyBadge.Text = Locale.Number(ready)
	readyBadge.Visible = ready > 0
	setOpenPulse(Onboarding.Is("hatch") and openButton.Visible) -- E5c step 1: the starter egg
	if not isOpen then return end
	for _, entry in countdowns do
		local remaining = entry.readyAt - now
		if remaining <= 0 then
			if not reveal.Visible then
				render()
			end
			return
		end
		if entry.label then
			entry.label.Text = if GardenConfig.EggPhase(entry.startedAt, entry.readyAt, now) == "scanning" then Locale.T("incubator.scanning")
				else Locale.T("incubator.hatchesIn", { time = GardenUi.Countdown(remaining) })
		end
	end
end)

ui.OnResize(render)
ui.gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
render()
