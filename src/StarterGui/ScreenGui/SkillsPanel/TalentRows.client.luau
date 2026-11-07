-- "Your skills" panel: one row per talent with its level, next effect and a buy button.
-- Display only: levels come from the Talent_<id> attributes the server maintains, Coins from leaderstats, and
-- a click just asks the server (talentId, expected next level). The server decides and prices everything.
-- Rows are built in code; this script is re-created with the ScreenGui on every respawn.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TalentConfig = require(ReplicatedStorage:WaitForChild("TalentConfig"))
local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local PanelFit = require(ReplicatedStorage:WaitForChild("PanelFit"))
local remotes = ReplicatedStorage:WaitForChild("TalentRemotes")
local buyEvent = remotes:WaitForChild("Buy")
local resultEvent = remotes:WaitForChild("Result")

local panel = script.Parent
local player = Players.LocalPlayer

local ROW_HEIGHT = 54
local COLOR_BUY = StudStyle.Colors.Green
local COLOR_LOCKED = StudStyle.Colors.Grey
local COLOR_INFO = Color3.fromRGB(235, 222, 190)
local COLOR_ERROR = Color3.fromRGB(240, 100, 90)
local COLOR_REWARD = Color3.fromRGB(255, 214, 102)
local REWARD_GLYPH = "🔒" -- button of a level that comes with a world (no words: not localized)

local REJECT_KEYS = {
	coins = "common.reject.coins",
	maxed = "skills.reject.maxed",
	stale = "common.reject.stale",
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

local function levelOf(id: string): number
	return TalentConfig.ClampLevel(id, player:GetAttribute(TalentConfig.AttributeName(id)))
end

local coins = 0
local rows = {}

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
		row.button.Text = Locale.T("skills.buy", { price = cost })
		row.button.BackgroundColor3 = coins >= cost and COLOR_BUY or COLOR_LOCKED
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
		Size = UDim2.new(1, -90, 0, 24),
		Font = StudStyle.Font,
		TextSize = 17,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local info = create("TextLabel", {
		Name = "Info",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 28),
		Size = UDim2.new(1, -90, 0, 20),
		Font = Enum.Font.SourceSans,
		TextSize = 14,
		TextColor3 = COLOR_INFO,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local button = create("TextButton", {
		Name = "Buy",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0, 70, 0, 38),
		Font = Enum.Font.SourceSansBold,
		TextSize = 16,
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = COLOR_LOCKED,
	})
	StudStyle.Brick(button) -- refreshRow recolours it through BackgroundColor3 / Text
	local rowFrame = create("Frame", {
		Name = "Talent_" .. talent.id,
		LayoutOrder = index,
		Size = UDim2.new(1, -10, 0, ROW_HEIGHT), -- the panel's width (GardenSkills widens it for the Garden tab)
	}, { title, info, button })
	StudStyle.Row(rowFrame, panel.Name)
	rowFrame.Parent = rowList

	local row = { talent = talent, title = title, info = info, button = button, flash = 0 }
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
		else
			flash(row, Locale.T(REJECT_KEYS[detail] or "skills.reject.failed"))
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
