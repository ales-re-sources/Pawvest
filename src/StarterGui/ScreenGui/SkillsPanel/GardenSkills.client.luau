-- Skills panel, tabs "Obby" / "Garden" (U4, docs/UI_GARDEN_PETS.md §6): the Obby tab is TalentRows' list ("Rows"); the Garden
-- tab is built here: the Renown header (level, a bar to the next level, the points still missing) and one row per field upgrade
-- (Growth, Barn) and garden tool (Seed sorter, Cloches, Pruning shears): icon, name, level / max, effect now → next, the Renown a
-- tool's next level needs (red while too low) and a Buy brick with the price. Buyable anywhere (the server dropped the plot check in
-- U4); every buy is over ConfirmTap.THRESHOLD, so it takes two taps. Display only: a tap names the id and the level it expects;
-- GardenField checks price, level and Renown and answers on GardenRemotes.Result (FieldClient toasts it).
-- The field state comes from GardenRemotes.State (GardenView keeps the last one: this script is re-created on every respawn).
-- The chosen tab lives in the player attribute SkillsTab ("Obby" / "Garden") so it survives a respawn.
-- Buttons by path (under PlayerGui.ScreenGui.SkillsPanel): Tabs.Obby / Tabs.Garden, GardenRows.<UpgradeId|ToolId>.Buy.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local UiKit = require(ReplicatedStorage:WaitForChild("UiKit"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local PanelFit = require(ReplicatedStorage:WaitForChild("PanelFit"))
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

local COLOR_BUY = StudStyle.Colors.Green
local COLOR_LOCKED = StudStyle.Colors.Grey
local COLOR_TAB = StudStyle.Shade(StudStyle.PanelColors.SkillsPanel, 0.6)
local COLOR_INFO = StudStyle.Text.Info
local COLOR_ERROR = StudStyle.Text.Error
local COLOR_OK = StudStyle.Text.Ok

local UPGRADE_KEYS = {
	Growth = { name = "field.upgrade.growth", effect = "field.upgrade.growth.effect", max = "field.upgrade.growth.max" },
	Barn = { name = "field.upgrade.barn", effect = "field.upgrade.barn.effect", max = "field.upgrade.barn.max" },
}
local TOOL_KEYS = {
	Sorter = { name = "field.tool.sorter", effect = "field.tool.sorter.effect", max = "field.tool.sorter.max" },
	Cloches = { name = "field.tool.cloches", effect = "field.tool.cloches.effect", max = "field.tool.cloches.max" },
	Shears = { name = "field.tool.shears", effect = "field.tool.shears.effect", max = "field.tool.shears.max" },
}

local create = UiKit.Create

local function text(name: string, props)
	props.Font = props.Font or Enum.Font.SourceSans
	return UiKit.Paragraph(name, props)
end

-- Layout -------------------------------------------------------------------------------------------------------------------

local fitScale = PanelFit.Scale()
local tapHeight = math.ceil(44 / fitScale) -- tabs and Buy bricks stay at least 44 px tall on screen
panel.Size = UDim2.new(0, PANEL_WIDTH, panel.Size.Y.Scale, panel.Size.Y.Offset)

local rows = panel:WaitForChild("Rows", 10) -- TalentRows' list (the Obby tab)
local listCap = PanelFit.MaxHeight(fitScale) - 55 - (tapHeight + 10)
if rows then
	rows.LayoutOrder = 2
	rows.Size = UDim2.new(1, 0, 0, math.min(rows.Size.Y.Offset, listCap))
end

local function tabButton(name: string, order: number)
	local button = create("TextButton", {
		Name = name,
		LayoutOrder = order,
		Size = UDim2.new(0.5, -4, 0, tapHeight),
		Font = Enum.Font.SourceSansBold,
		TextSize = 17,
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = COLOR_TAB,
		AutoButtonColor = false,
	})
	button:SetAttribute("UiSound", "Tab")
	StudStyle.Brick(button)
	return button
end
local obbyTab = tabButton("Obby", 1)
local gardenTab = tabButton("Garden", 2)
create("Frame", {
	Name = "Tabs",
	LayoutOrder = 1,
	Size = UDim2.new(1, -10, 0, tapHeight),
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

local function clear()
	for _, child in gardenList:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function renderHeader(field, order: number)
	local header = create("Frame", {
		Name = "Renown",
		LayoutOrder = order,
		Size = UDim2.new(1, -10, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, {
		create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }),
	})
	text("Level", {
		LayoutOrder = 1,
		Font = StudStyle.Font,
		TextSize = 22,
		TextColor3 = COLOR_OK,
		Text = Locale.T("field.renown.level", { level = field.level }),
	}).Parent = header
	local low, high = CropConfig.PointsFor(field.level), CropConfig.PointsFor(field.level + 1)
	local fraction = if high > low then math.clamp((field.renown - low) / (high - low), 0, 1) else 1
	UiKit.Bar("Bar", { order = 2, height = 12, track = Color3.fromRGB(60, 45, 20), fill = COLOR_OK, share = fraction, parent = header })
	text("Next", {
		LayoutOrder = 3,
		Text = Locale.T("field.renown.next", { count = math.max(0, high - field.renown), level = field.level + 1 }),
	}).Parent = header
	header.Parent = gardenList
end

-- One upgrade / tool row: title, effect line, an optional red Renown line, the Buy brick.
local function renderRow(order: number, id: string, title: string, info: string, renownLine: string?, price: number?, canBuy: boolean, buy: () -> ())
	local row = create("Frame", {
		Name = id,
		LayoutOrder = order,
		Size = UDim2.new(1, -10, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, {
		create("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
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
	if renownLine then
		text("Renown", { LayoutOrder = 3, TextSize = 13, TextColor3 = COLOR_ERROR, Text = renownLine }).Parent = column
	end
	column.Parent = row
	local button = create("TextButton", {
		Name = "Buy",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(BUY_WIDTH, tapHeight),
		Font = Enum.Font.SourceSansBold,
		TextSize = 15,
		TextWrapped = true,
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = if price and canBuy then COLOR_BUY else COLOR_LOCKED,
		Text = if price then Locale.T("field.upgrade.price", { count = price }) else Locale.T("field.upgrade.maxed"),
	})
	StudStyle.Brick(button)
	button.Parent = row
	if price then
		ConfirmTap.Wrap(button, "Skill" .. id, function()
			return ConfirmTap.Over(price)
		end, buy)
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
	renderHeader(field, 1)
	for index, upgrade in CropConfig.Upgrades do
		local keys = UPGRADE_KEYS[upgrade.id]
		local level = CropConfig.UpgradeLevel(field.upgrades, upgrade.id)
		local price = upgrade.prices[level + 1]
		local function effect(at: number): number
			return if upgrade.id == "Growth" then math.floor(upgrade.step * at * 100 + 0.5) else CropConfig.BarnFor(at)
		end
		local renownOk = not price or field.level >= (upgrade.renown[level + 1] or 0)
		renderRow(
			1 + index,
			upgrade.id,
			Locale.T("field.upgrade.level", { name = upgrade.icon .. " " .. Locale.T(keys.name), level = level, max = #upgrade.prices }),
			if price
				then Locale.T(keys.effect, { now = effect(level), next = effect(level + 1) })
				else Locale.T(keys.max, { now = effect(level) }),
			if renownOk then nil else Locale.T("field.expand.needRenown", { level = upgrade.renown[level + 1] }),
			price,
			price ~= nil and renownOk and coins >= price,
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
		local renownOk = not price or field.level >= tool.renown[level + 1]
		renderRow(
			10 + index,
			tool.id,
			Locale.T("field.upgrade.level", { name = tool.icon .. " " .. Locale.T(keys.name), level = level, max = #tool.prices }),
			if price
				then Locale.T(keys.effect, { now = percent(level), next = percent(level + 1) })
				else Locale.T(keys.max, { now = percent(level) }),
			if renownOk then nil else Locale.T("field.expand.needRenown", { level = tool.renown[level + 1] }),
			price,
			price ~= nil and renownOk and coins >= price,
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
	renderIfShown()
	coinValue:GetPropertyChangedSignal("Value"):Connect(function()
		coins = coinValue.Value
		renderIfShown()
	end)
end)

staticTexts()
showTab()
