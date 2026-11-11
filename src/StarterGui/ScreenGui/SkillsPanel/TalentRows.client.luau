-- "Your skills" panel: one row per talent with its level, next effect and a buy button that shows the price of the next level
-- (line 1: 💰 Coins, line 2: the crops it takes, EV2b, have/need; what is short is highlighted; playtest 2026-11-08).
-- Display only: levels come from the Talent_<id> attributes the server maintains, Coins from leaderstats, the barn's crops from
-- the own field state (GardenView.OwnField, refreshed on GardenRemotes.State), and a click just asks the server (talentId,
-- expected next level). The server decides and prices everything.
-- Rows are built in code; this script is re-created with the ScreenGui on every respawn.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TalentConfig = require(ReplicatedStorage:WaitForChild("TalentConfig"))
local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local PanelFit = require(ReplicatedStorage:WaitForChild("PanelFit"))
local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local remotes = ReplicatedStorage:WaitForChild("TalentRemotes")
local buyEvent = remotes:WaitForChild("Buy")
local resultEvent = remotes:WaitForChild("Result")

local panel = script.Parent
local player = Players.LocalPlayer
local GardenView = require(player:WaitForChild("PlayerScripts"):WaitForChild("GardenView"))

local ROW_HEIGHT = 58
local BUTTON_WIDTH = 92 -- fits 💰 16,000 over 🥒20/20  🍇2/2 (GardenSkills' buy bricks have the same width)
local BUTTON_HEIGHT = 48
local TEXT_INSET = BUTTON_WIDTH + 16
local COLOR_BUY = StudStyle.Colors.Green
local COLOR_LOCKED = StudStyle.Colors.Grey
local COLOR_INFO = StudStyle.Text.Info
local COLOR_ERROR = StudStyle.Text.Error
local COLOR_REWARD = Color3.fromRGB(255, 214, 102)
local COLOR_SHORT = Color3.fromRGB(255, 214, 64) -- on the button: what the player has too little of (readable on green and grey)
local HEX_SHORT = "#FFD640" -- COLOR_SHORT in the crops line's rich text
local REWARD_GLYPH = "🔒" -- button of a level that comes with a world (no words: not localized)

local REJECT_KEYS = { -- the rest: Locale.Reject's common.reject.*
	crops = "skills.reject.crops",
	maxed = "skills.reject.maxed",
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

local function levelOf(id: string): number
	return TalentConfig.ClampLevel(id, player:GetAttribute(TalentConfig.AttributeName(id)))
end

local coins = 0
local rows = {}

-- How many of a crop the own barn holds (0 before the first field state).
local function held(cropId: string): number
	local field = GardenView.OwnField()
	local items = type(field) == "table" and field.items
	return type(items) == "table" and tonumber(items[cropId]) or 0
end

-- The crops the next level takes: the button's line ("🥒5/20  🍇0/2", a short crop highlighted), whether every crop is held, and the
-- same with names ("Needs: Cucumber 5/20, Frost grape 0/2", shown when a purchase is refused for crops). Nil texts when it takes none.
-- Crops in catalogue order.
local function cropCost(bundle): (string?, boolean, string?)
	local chips, names, enough = {}, {}, true
	for _, crop in CropConfig.Crops do
		local need = bundle[crop.id]
		if need then
			local have = math.min(held(crop.id), need)
			local chip = crop.icon .. Locale.Number(have) .. "/" .. Locale.Number(need) -- loc: ignore (an icon and numbers, no words)
			if have < need then
				enough = false
				chip = '<font color="' .. HEX_SHORT .. '">' .. chip .. "</font>" -- loc: ignore (rich-text markup, no words)
			end
			table.insert(chips, chip)
			table.insert(names, Locale.T("skills.needs.item", { crop = Locale.CropName(crop), have = have, need = need }))
		end
	end
	if #chips == 0 then
		return nil, true, nil
	end
	return table.concat(chips, "  "), enough, Locale.T("skills.needs", { list = table.concat(names, ", ") })
end

-- "Free when World 2 opens" for a level that is a world reward (K1), else nil
local function rewardText(talent, level: number): string?
	local world = StageConfig.Worlds[TalentConfig.RewardWorld(talent.id, level) or 0]
	return world and Locale.T("skills.reward", { world = Locale.WorldName(world) })
end

local function refreshRow(row)
	local talent = row.talent
	local level = levelOf(talent.id)
	local max = #talent.costs
	local cost = TalentConfig.NextCost(talent.id, level)
	local reward = rewardText(talent, level + 1)
	local cropsLine, enough, needsText = cropCost(if cost then TalentConfig.NextCrops(talent.id, level) else {})
	row.needsText = needsText
	row.cost.Visible = cost ~= nil and not reward

	-- a talent with per-level names shows the level it sells ("Triple Jump 1/2"), maxed the level it has
	row.title.Text = Locale.TalentName(talent, math.min(level + 1, max)) .. "  " .. level .. "/" .. max
	if row.flash == 0 then
		row.info.TextColor3 = if reward then COLOR_REWARD else COLOR_INFO
		row.info.Text = reward or (if cost then Locale.TalentEffect(talent, level + 1) else Locale.T("skills.maxedOut"))
	end
	if reward then
		row.button.Text = REWARD_GLYPH
		row.button.BackgroundColor3 = COLOR_LOCKED
	elseif cost then
		row.button.Text = "" -- the Cost overlay shows the price
		row.costCoins.Text = "💰 " .. Locale.Number(cost) -- loc: ignore (an icon and a number, no words)
		row.costCoins.TextColor3 = if coins >= cost then Color3.new(1, 1, 1) else COLOR_SHORT
		row.costCrops.Text = cropsLine or ""
		row.costCrops.Visible = cropsLine ~= nil
		row.button.BackgroundColor3 = coins >= cost and enough and COLOR_BUY or COLOR_LOCKED
	else
		row.button.Text = Locale.T("skills.max")
		row.button.BackgroundColor3 = COLOR_LOCKED
	end
end

local function refreshAll()
	for _, row in rows do
		refreshRow(row)
	end
end

local function flash(row, text: string, color: Color3?)
	row.flash += 1
	local mine = row.flash
	row.info.TextColor3 = color or COLOR_ERROR
	row.info.Text = text
	task.delay(2, function()
		if row.flash == mine then
			row.flash = 0
			refreshRow(row)
		end
	end)
end

-- The old mock-up row is replaced by the generated ones.
local placeholder = panel:FindFirstChild("RunSpeed")
if placeholder then
	placeholder:Destroy()
end

-- Short screens (a phone in landscape): the panel is scaled down and the rows scroll in a list capped to what fits.
-- The panel itself fits its content (StudStyle.Panel: AutomaticSize.Y): title 35 + gap 10 + list + bottom padding 10.
local fitScale = PanelFit.Scale()
if fitScale < 1 then
	create("UIScale", { Scale = fitScale, Parent = panel })
end
local listHeight = math.min(#TalentConfig.List * (ROW_HEIGHT + 10) - 10, PanelFit.MaxHeight(fitScale) - 55)
local rowList = create("ScrollingFrame", {
	Name = "Rows",
	LayoutOrder = 1,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 0, math.max(listHeight, ROW_HEIGHT)),
	ScrollBarThickness = 5,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, {
	create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}),
})
rowList.Parent = panel

for index, talent in TalentConfig.List do
	local title = create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 4),
		Size = UDim2.new(1, -TEXT_INSET, 0, 24),
		Font = StudStyle.Font,
		TextSize = 17,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local info = create("TextLabel", {
		Name = "Info",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 28),
		Size = UDim2.new(1, -TEXT_INSET, 0, 20),
		AutomaticSize = Enum.AutomaticSize.Y, -- a refused purchase's "Needs: ..." and Czech texts wrap
		Font = Enum.Font.SourceSans,
		TextSize = 14,
		TextColor3 = COLOR_INFO,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
	})
	local button = create("TextButton", {
		Name = "Buy",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0, BUTTON_WIDTH, 0, BUTTON_HEIGHT),
		Font = Enum.Font.SourceSansBold,
		TextSize = 16,
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = COLOR_LOCKED,
	})
	StudStyle.Brick(button) -- refreshRow recolours it through BackgroundColor3 / Text
	local function costLine(name: string, order: number, size: number)
		return create("TextLabel", {
			Name = name,
			LayoutOrder = order,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, size + 3),
			Font = StudStyle.Font,
			TextSize = size,
			TextColor3 = Color3.new(1, 1, 1),
			TextStrokeTransparency = 0.3,
			RichText = true,
			AutoLocalize = false,
			ZIndex = 3,
		})
	end
	local costCoins, costCrops = costLine("Coins", 1, 15), costLine("Crops", 2, 14)
	-- in the brick's face, so it goes down with the press like the Glyph
	local cost = create("Frame", {
		Name = "Cost",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 3,
		Visible = false,
		Parent = button:WaitForChild("Top"):WaitForChild("Face"),
	}, {
		create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		costCoins,
		costCrops,
	})
	local rowFrame = create("Frame", {
		Name = "Talent_" .. talent.id,
		LayoutOrder = index,
		Size = UDim2.new(1, -10, 0, ROW_HEIGHT), -- the panel's width (GardenSkills widens it for the Garden tab)
		AutomaticSize = Enum.AutomaticSize.Y, -- grows when the info line wraps
	}, { title, info, button, create("UIPadding", { PaddingBottom = UDim.new(0, 6) }) })
	StudStyle.Row(rowFrame, panel.Name)
	rowFrame.Parent = rowList

	local row = { talent = talent, title = title, info = info, button = button, cost = cost, costCoins = costCoins, costCrops = costCrops, flash = 0 }
	rows[talent.id] = row

	button.Activated:Connect(function()
		local level = levelOf(talent.id)
		if level >= #talent.costs then
			return
		end
		local reward = rewardText(talent, level + 1)
		if reward then
			flash(row, reward, COLOR_REWARD) -- never sold: the server would refuse it
			return
		end
		buyEvent:FireServer(talent.id, level + 1)
	end)
	player:GetAttributeChangedSignal(TalentConfig.AttributeName(talent.id)):Connect(function()
		refreshRow(row)
	end)
end

resultEvent.OnClientEvent:Connect(function(id, ok, detail)
	local row = rows[id]
	if row and not ok then
		local level = TalentConfig.ClampLevel(id, player:GetAttribute(TalentConfig.AttributeName(id)))
		local reward = if detail == "reward" then rewardText(row.talent, level + 1) else nil
		if reward then
			flash(row, reward, COLOR_REWARD)
		elseif detail == "crops" and row.needsText then
			flash(row, row.needsText, COLOR_REWARD) -- the crops by name (the button only has their icons)
		else
			flash(row, Locale.Reject(detail, REJECT_KEYS, nil, "skills.reject.failed"))
		end
	end
end)

-- the panel's title strip is authored in Studio; its text comes from here
local function title()
	local titleLabel = panel:FindFirstChild("TitleLabel")
	if titleLabel and titleLabel:IsA("TextLabel") then
		titleLabel.Text = Locale.T("skills.title")
	end
end
title()

Locale.Changed:Connect(function()
	title()
	refreshAll()
end)

-- the barn's crops changed (a harvest, a sale, a bought level): after GardenView took the new state
ReplicatedStorage:WaitForChild("GardenRemotes"):WaitForChild("State").OnClientEvent:Connect(function()
	task.defer(refreshAll)
end)

task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats")
	local coinValue = leaderstats:WaitForChild("Coins") :: IntValue
	coins = coinValue.Value
	refreshAll()
	coinValue:GetPropertyChangedSignal("Value"):Connect(function()
		coins = coinValue.Value
		refreshAll()
	end)
end)

refreshAll()
