-- Skills panel, tabs "Obby" / "Garden" (U4, docs/GDD.md §7.9): the Obby tab is TalentRows' list ("Rows"); the Garden
-- tab is built here: one row per field upgrade (Growth, Barn) and garden tool (Seed sorter, Cloches, Pruning shears): icon, name,
-- level / max, effect now → next and a Buy brick with the price (Coins only since EV3b: the Renown header and gates are gone). Buyable
-- anywhere (the server dropped the plot check in U4); every buy is over ConfirmTap.THRESHOLD, so it takes two taps. Display only: a
-- tap names the id and the level it expects; GardenField checks price and level and answers on GardenRemotes.Result (FieldClient
-- toasts a success; a refusal shows here). A price the player cannot pay is refused here at once: the brick shakes and
-- UiKit.Notice says "Needs: 💰 1,200 more" over the row's text, as on the Obby tab.
-- The field state comes from GardenRemotes.State (GardenView keeps the last one: this script is re-created on every respawn).
-- The chosen tab lives in the player attribute SkillsTab ("Obby" / "Garden") so it survives a respawn.
-- Buttons by path (under PlayerGui.ScreenGui.SkillsPanel): Tabs.Obby / Tabs.Garden, GardenRows.<UpgradeId|ToolId>.Buy.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local UiKit = require(ReplicatedStorage:WaitForChild("UiKit"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local HudLayout = require(ReplicatedStorage:WaitForChild("HudLayout"))
local ConfirmTap = require(ReplicatedStorage:WaitForChild("ConfirmTap"))

local player = Players.LocalPlayer
local panel = script.Parent
local GardenView = require(player:WaitForChild("PlayerScripts"):WaitForChild("GardenView"))
local remotes = ReplicatedStorage:WaitForChild("GardenRemotes")
local buyUpgradeEvent = remotes:WaitForChild("BuyUpgrade")
local buyToolEvent = remotes:WaitForChild("BuyTool")

local PANEL_WIDTH = 300 -- the Studio frame is 250 wide; the Garden rows need the room (TalentRows' rows fill the width)
local TAB_ATTRIBUTE = "SkillsTab"
local GAP = 8
local BUY_WIDTH = 92
local PAD_LEFT, PAD_RIGHT, PAD_Y = 10, 8, 6 -- a row's UIPadding

local COLOR_BUY = StudStyle.Colors.Green
local COLOR_LOCKED = StudStyle.Colors.Grey
local COLOR_TAB = StudStyle.Shade(StudStyle.PanelColors.SkillsPanel, 0.6)
local COLOR_INFO = StudStyle.Text.Info

local UPGRADE_KEYS = {
	Growth = { name = "field.upgrade.growth", effect = "field.upgrade.growth.effect", max = "field.upgrade.growth.max" },
	Barn = { name = "field.upgrade.barn", effect = "field.upgrade.barn.effect", max = "field.upgrade.barn.max" },
}
local TOOL_KEYS = {
	Sorter = { name = "field.tool.sorter", effect = "field.tool.sorter.effect", max = "field.tool.sorter.max" },
	Cloches = { name = "field.tool.cloches", effect = "field.tool.cloches.effect", max = "field.tool.cloches.max" },
	Shears = { name = "field.tool.shears", effect = "field.tool.shears.effect", max = "field.tool.shears.max" },
}

local REJECT_KEYS = { maxed = "field.reason.upgradeMaxed" } -- the rest: Locale.Reject's common.reject.*

local create = UiKit.Create

local function text(name: string, props)
	props.Font = props.Font or Enum.Font.SourceSans
	return UiKit.Paragraph(name, props)
end

-- Layout -------------------------------------------------------------------------------------------------------------------

local fitScale = HudLayout.Get(panel.Parent).scale
local tapHeight = math.ceil(StudStyle.Sizes.Action / fitScale)
local tabHeight = math.ceil(StudStyle.Sizes.Tab / fitScale)
panel.Size = UDim2.new(0, PANEL_WIDTH, panel.Size.Y.Scale, panel.Size.Y.Offset)

local rows = panel:WaitForChild("Rows", 10) -- TalentRows' list (the Obby tab)
local obbyHeight = rows and rows.Size.Y.Offset or 430
local listCap = HudLayout.Get(panel.Parent).height / fitScale - math.ceil(StudStyle.Sizes.Header / fitScale) - tabHeight - 40
if rows then
	rows.LayoutOrder = 2
	rows.Size = UDim2.new(1, 0, 0, math.min(rows.Size.Y.Offset, listCap))
end

local function tabButton(name: string, order: number)
	local button = create("TextButton", {
		Name = name,
		LayoutOrder = order,
		Size = UDim2.new(0.5, -4, 0, tabHeight),
		Font = Enum.Font.SourceSansBold,
		TextSize = 17,
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = COLOR_TAB,
		AutoButtonColor = false,
	})
	button:SetAttribute("UiSound", "Tab")
	StudStyle.Brick(button, { compact = true })
	return button
end
local obbyTab = tabButton("Obby", 1)
local gardenTab = tabButton("Garden", 2)
create("Frame", {
	Name = "Tabs",
	LayoutOrder = 1,
	Size = UDim2.new(1, -10, 0, tabHeight),
	BackgroundTransparency = 1,
	Parent = panel,
}, {
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
	obbyTab,
	gardenTab,
})

local gardenList = create("ScrollingFrame", {
	Name = "GardenRows",
	LayoutOrder = 3,
	Visible = false,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 0, math.max(math.min(430, listCap), 160)),
	ScrollBarThickness = 5,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, {
	create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, GAP),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}),
	create("UIPadding", { PaddingBottom = UDim.new(0, 4) }),
})
gardenList.Parent = panel

-- Rendering -----------------------------------------------------------------------------------------------------------------

local coins = 0
local coinsKnown = false -- leaderstats seen: until then a tap goes to the server unchecked
local COLOR_SHORT_HEX = "#FFD640" -- TalentRows' COLOR_SHORT: a price the player cannot pay

-- The refusal notice outlives a re-render (Coins or the field state changing while it shows).
local notices: { [string]: (string?, number?) -> () } = {} -- [row id] = the shown row's UiKit.Notice
local shown = { id = "", text = "", untilTime = 0 }
local pending = { id = "", price = 0 } -- the last buy sent: the server's refusal names no row

-- A refused purchase: the brick shakes, the notice over the row's text says why (the same as the Obby tab's rows).
local function refuse(id: string, text: string)
	shown.id, shown.text, shown.untilTime = id, text, os.clock() + UiKit.NOTICE_SECONDS
	local show = notices[id]
	if show then
		show(text)
	end
	local row = gardenList:FindFirstChild(id)
	local button = row and row:FindFirstChild("Buy")
	if button then
		UiKit.Shake(button)
	end
end

local function coinsShort(price: number): string
	return Locale.T("skills.needs", { list = Locale.T("skills.needs.coins", { count = price - coins }) })
end

local function clear()
	table.clear(notices)
	for _, child in gardenList:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- One upgrade / tool row: title, effect line, the Buy brick.
local function renderRow(order: number, id: string, title: string, info: string, price: number?, canBuy: boolean, buy: () -> ())
	local row = create("Frame", {
		Name = id,
		LayoutOrder = order,
		Size = UDim2.new(1, -10, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, {
		create("UIPadding", {
			PaddingLeft = UDim.new(0, PAD_LEFT),
			PaddingRight = UDim.new(0, PAD_RIGHT),
			PaddingTop = UDim.new(0, PAD_Y),
			PaddingBottom = UDim.new(0, PAD_Y),
		}),
	})
	StudStyle.Row(row, panel.Name)
	local column = create("Frame", {
		Name = "Text",
		Size = UDim2.new(1, -(BUY_WIDTH + GAP), 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, {
		create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }),
		create("UISizeConstraint", { MinSize = Vector2.new(0, tapHeight) }),
	})
	text("Title", { LayoutOrder = 1, Font = StudStyle.Font, TextSize = 16, TextColor3 = Color3.new(1, 1, 1), Text = title }).Parent = column
	text("Info", { LayoutOrder = 2, Text = info }).Parent = column
	column.Parent = row
	-- over the text column, NOTICE_INSET from the row's edges and the brick (the row's base height is 0, so the Y scale never
	-- grows it)
	local inset = UiKit.NOTICE_INSET
	local notice = UiKit.Notice(row, {
		Position = UDim2.fromOffset(inset - PAD_LEFT, inset - PAD_Y),
		Size = UDim2.new(1, PAD_LEFT - BUY_WIDTH - 2 * inset, 1, 2 * (PAD_Y - inset)), -- the brick sits in the right padding
	})
	notices[id] = notice
	local left = shown.untilTime - os.clock()
	if shown.id == id and left > 0 then
		notice(shown.text, left)
	end
	local priceText = if price then Locale.T("field.upgrade.price", { count = price }) else Locale.T("field.upgrade.maxed")
	local button = create("TextButton", {
		Name = "Buy",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(BUY_WIDTH, tapHeight),
		Font = Enum.Font.SourceSansBold,
		TextSize = 15,
		TextWrapped = true,
		RichText = true, -- a price the player cannot pay is in the short colour, as on the Obby tab
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = if price and canBuy then COLOR_BUY else COLOR_LOCKED,
		Text = if price and not canBuy
			then '<font color="' .. COLOR_SHORT_HEX .. '">' .. priceText .. "</font>" -- loc: ignore (rich-text markup, no words)
			else priceText,
	})
	StudStyle.Brick(button, { compact = true })
	button.Parent = row
	if price then
		ConfirmTap.Wrap(button, "Skill" .. id, function()
			return ConfirmTap.Over(price)
		end, function()
			if coinsKnown and coins < price then -- a grey brick answers at once, no request
				return refuse(id, coinsShort(price))
			end
			pending.id, pending.price = id, price
			buy()
		end)
	end
	row.Parent = gardenList
end

local function render()
	clear()
	local field = GardenView.OwnField()
	if not field then
		text("Loading", { LayoutOrder = 1, Size = UDim2.new(1, -10, 0, 0), Text = Locale.T("common.loading") }).Parent = gardenList
		return
	end
	for index, upgrade in CropConfig.Upgrades do
		local keys = UPGRADE_KEYS[upgrade.id]
		local level = CropConfig.UpgradeLevel(field.upgrades, upgrade.id)
		local price = upgrade.prices[level + 1]
		local function effect(at: number): number
			return if upgrade.id == "Growth" then math.floor(upgrade.step * at * 100 + 0.5) else CropConfig.BarnFor(at)
		end
		renderRow(
			1 + index,
			upgrade.id,
			Locale.T("field.upgrade.level", { name = upgrade.icon .. " " .. Locale.T(keys.name), level = level, max = #upgrade.prices }),
			if price
				then Locale.T(keys.effect, { now = effect(level), next = effect(level + 1) })
				else Locale.T(keys.max, { now = effect(level) }),
			price,
			price ~= nil and coins >= price,
			function()
				buyUpgradeEvent:FireServer(upgrade.id, level)
			end
		)
	end
	for index, tool in CropConfig.Tools do
		local keys = TOOL_KEYS[tool.id]
		local level = CropConfig.ToolLevel(field.tools, tool.id)
		local price = tool.prices[level + 1]
		local function percent(at: number): number
			return if at > 0 then math.floor(tool.effect[at] * 100 + 0.5) else 0
		end
		renderRow(
			10 + index,
			tool.id,
			Locale.T("field.upgrade.level", { name = tool.icon .. " " .. Locale.T(keys.name), level = level, max = #tool.prices }),
			if price
				then Locale.T(keys.effect, { now = percent(level), next = percent(level + 1) })
				else Locale.T(keys.max, { now = percent(level) }),
			price,
			price ~= nil and coins >= price,
			function()
				buyToolEvent:FireServer(tool.id, level)
			end
		)
	end
end

-- Tabs ----------------------------------------------------------------------------------------------------------------------

local function currentTab(): string
	return if player:GetAttribute(TAB_ATTRIBUTE) == "Garden" then "Garden" else "Obby"
end

local function showTab()
	local garden = currentTab() == "Garden"
	if rows then
		rows.Visible = not garden
	end
	gardenList.Visible = garden
	for _, pair in { { obbyTab, not garden }, { gardenTab, garden } } do
		local button, active = pair[1], pair[2]
		button.BackgroundColor3 = if active then StudStyle.PanelColors.SkillsPanel else COLOR_TAB
		local lip = button:FindFirstChild("Lip") -- StudStyle.Brick's base frame: the white outline of the active tab goes there
		if lip then
			local stroke = lip:FindFirstChild("ActiveStroke") or create("UIStroke", {
				Name = "ActiveStroke",
				Thickness = 2,
				Color = Color3.new(1, 1, 1),
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Parent = lip,
			})
			stroke.Enabled = active
		end
	end
	if garden then
		render()
	end
end

local function staticTexts()
	obbyTab.Text = Locale.T("skills.tab.obby")
	gardenTab.Text = Locale.T("skills.tab.garden")
end

obbyTab.Activated:Connect(function()
	player:SetAttribute(TAB_ATTRIBUTE, "Obby")
	showTab()
end)
gardenTab.Activated:Connect(function()
	player:SetAttribute(TAB_ATTRIBUTE, "Garden")
	showTab()
end)

local function renderIfShown()
	if gardenList.Visible then
		render()
	end
end

-- The server's refusal of a buy (FieldClient toasts only the successes): on the row that sent it.
remotes:WaitForChild("Result").OnClientEvent:Connect(function(action, ok, detail)
	if ok or (action ~= "BuyUpgrade" and action ~= "BuyTool") or pending.id == "" then
		return
	end
	if detail == "coins" and coinsKnown and coins < pending.price then
		refuse(pending.id, coinsShort(pending.price))
	else
		refuse(pending.id, Locale.Reject(detail, REJECT_KEYS))
	end
end)

remotes:WaitForChild("State").OnClientEvent:Connect(function()
	task.defer(renderIfShown) -- after GardenView took the new state
end)
Locale.Changed:Connect(function()
	staticTexts()
	renderIfShown()
end)
task.spawn(function()
	local coinValue = player:WaitForChild("leaderstats"):WaitForChild("Coins") :: IntValue
	coins = coinValue.Value
	coinsKnown = true
	renderIfShown()
	coinValue:GetPropertyChangedSignal("Value"):Connect(function()
		coins = coinValue.Value
		renderIfShown()
	end)
end)

staticTexts()
showTab()

HudLayout.Watch(panel.Parent, function(layout)
	fitScale = layout.scale
	tapHeight = math.ceil(StudStyle.Sizes.Action / fitScale)
	tabHeight = math.ceil(StudStyle.Sizes.Tab / fitScale)
	local titleHeight = math.ceil(StudStyle.Sizes.Header / fitScale)
	listCap = math.max(1, layout.height / fitScale - titleHeight - tabHeight - 40)
	panel.Tabs.Size = UDim2.new(1, -10, 0, tabHeight)
	obbyTab.Size = UDim2.new(0.5, -4, 0, tabHeight)
	gardenTab.Size = UDim2.new(0.5, -4, 0, tabHeight)
	if rows then rows.Size = UDim2.new(1, 0, 0, math.min(obbyHeight, listCap)) end
	gardenList.Size = UDim2.new(1, 0, 0, math.min(430, listCap))
	renderIfShown()
end)
