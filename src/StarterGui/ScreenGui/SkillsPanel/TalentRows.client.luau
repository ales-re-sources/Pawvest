-- "Your skills" panel: one row per talent with its level, next effect and a buy button.
-- Display only: levels come from the Talent_<id> attributes the server maintains, Coins from leaderstats, and
-- a click just asks the server (talentId, expected next level). The server decides and prices everything.
-- Rows are built in code; this script is re-created with the ScreenGui on every respawn.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TalentConfig = require(ReplicatedStorage:WaitForChild("TalentConfig"))
local remotes = ReplicatedStorage:WaitForChild("TalentRemotes")
local buyEvent = remotes:WaitForChild("Buy")
local resultEvent = remotes:WaitForChild("Result")

local panel = script.Parent
local player = Players.LocalPlayer

local ROW_HEIGHT = 54
local COLOR_ROW = Color3.fromRGB(45, 45, 45)
local COLOR_BUY = Color3.fromRGB(60, 170, 70)
local COLOR_LOCKED = Color3.fromRGB(110, 110, 110)
local COLOR_INFO = Color3.fromRGB(190, 190, 190)
local COLOR_ERROR = Color3.fromRGB(240, 100, 90)

local REJECT_TEXT = {
	coins = "Not enough Coins",
	maxed = "Already maxed",
	stale = "Out of date, try again",
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

local function levelOf(id: string): number
	return TalentConfig.ClampLevel(id, player:GetAttribute(TalentConfig.AttributeName(id)))
end

local coins = 0
local rows = {}

local function refreshRow(row)
	local talent = row.talent
	local level = levelOf(talent.id)
	local max = #talent.costs
	local cost = TalentConfig.NextCost(talent.id, level)

	row.title.Text = talent.name .. "  " .. level .. "/" .. max
	if row.flash == 0 then
		row.info.TextColor3 = COLOR_INFO
		row.info.Text = cost and talent.effect or "Maxed out"
	end
	if cost then
		row.button.Text = "Buy " .. cost
		row.button.BackgroundColor3 = coins >= cost and COLOR_BUY or COLOR_LOCKED
	else
		row.button.Text = "MAX"
		row.button.BackgroundColor3 = COLOR_LOCKED
	end
end

local function refreshAll()
	for _, row in rows do
		refreshRow(row)
	end
end

local function flash(row, text: string)
	row.flash += 1
	local mine = row.flash
	row.info.TextColor3 = COLOR_ERROR
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

panel.Size = UDim2.new(0, 250, 0, 35 + #TalentConfig.List * (ROW_HEIGHT + 10) + 5)

for index, talent in TalentConfig.List do
	local title = create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 4),
		Size = UDim2.new(1, -90, 0, 24),
		Font = Enum.Font.SourceSansBold,
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
	}, { create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	create("Frame", {
		Name = "Talent_" .. talent.id,
		LayoutOrder = index,
		BackgroundColor3 = COLOR_ROW,
		Size = UDim2.new(0, 240, 0, ROW_HEIGHT),
		Parent = panel,
	}, { create("UICorner", { CornerRadius = UDim.new(0, 8) }), title, info, button })

	local row = { talent = talent, title = title, info = info, button = button, flash = 0 }
	rows[talent.id] = row

	button.Activated:Connect(function()
		local level = levelOf(talent.id)
		if level >= #talent.costs then
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
		flash(row, REJECT_TEXT[detail] or "Purchase failed")
	end
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
