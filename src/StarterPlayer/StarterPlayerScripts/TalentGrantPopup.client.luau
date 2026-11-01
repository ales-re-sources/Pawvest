-- "New skill" popup (K1, GDD §6): a world reward was granted (TalentRemotes.Granted from TalentService), e.g. Double Jump
-- when World 2 opens. Big title, one line on how to use it, one button; a tap anywhere on it closes it (young players on a
-- phone tap the text, not the button), else it closes itself after a while. Built here, not in Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local TalentConfig = require(ReplicatedStorage:WaitForChild("TalentConfig"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local grantedEvent = ReplicatedStorage:WaitForChild("TalentRemotes"):WaitForChild("Granted")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CLOSE_AFTER = 12 -- seconds
local COLOR_PANEL = Color3.fromRGB(32, 32, 32)
local COLOR_TITLE = Color3.fromRGB(255, 214, 102)
local COLOR_BUTTON = Color3.fromRGB(70, 170, 80)
-- how to use a granted talent, in a child's words; other talents fall back to their effect line
local HOW_KEYS = { DoubleJump = "talent.granted.how.DoubleJump" }

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

local function line(name: string, order: number, textSize: number, color: Color3)
	return create("TextLabel", {
		Name = name,
		LayoutOrder = order,
		Size = UDim2.new(1, -24, 0, textSize + 6),
		AutomaticSize = Enum.AutomaticSize.Y, -- wrapped lines (longer in Czech) grow the panel
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = textSize,
		TextColor3 = color,
		TextWrapped = true,
		Text = "",
	})
end

local titleLabel = line("Title", 1, 24, COLOR_TITLE)
local howLabel = line("How", 2, 18, Color3.new(1, 1, 1))
local okButton = create("TextButton", {
	Name = "Ok",
	LayoutOrder = 3,
	Size = UDim2.new(1, -48, 0, 40),
	BackgroundColor3 = COLOR_BUTTON,
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	TextColor3 = Color3.new(1, 1, 1),
	Text = "",
}, { create("UICorner", { CornerRadius = UDim.new(0, 8) }) })

local scale = create("UIScale", { Scale = 1 })
local panel = create("TextButton", { -- a button, so a tap on the text closes it too
	Name = "Panel",
	AutoButtonColor = false,
	Text = "",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 90),
	Size = UDim2.fromOffset(320, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = COLOR_PANEL,
	BackgroundTransparency = 0.1,
}, {
	scale,
	create("UICorner", { CornerRadius = UDim.new(0, 12) }),
	create("UIStroke", { Color = COLOR_TITLE, Thickness = 3 }),
	create("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14) }),
	create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 8),
	}),
	titleLabel,
	howLabel,
	okButton,
})

local screenGui = create("ScreenGui", {
	Name = "TalentGrantPopup",
	ResetOnSpawn = false,
	DisplayOrder = 7, -- above the arrival warning
	Enabled = false,
	AutoLocalize = false, -- translated by Locale (L1)
}, { panel })

local generation = 0
local shown = nil -- { talent, level }: re-rendered when the language changes

local function render()
	local talent, level = shown.talent, shown.level
	titleLabel.Text = Locale.T("talent.granted.title", { talent = Locale.TalentName(talent, level) })
	local how = HOW_KEYS[talent.id]
	howLabel.Text = if how then Locale.T(how) else Locale.TalentEffect(talent, level)
	okButton.Text = Locale.T("talent.granted.ok")
end

local function hide()
	generation += 1
	screenGui.Enabled = false
end

grantedEvent.OnClientEvent:Connect(function(talentId, level)
	local talent = TalentConfig.ById[talentId]
	if not talent or type(level) ~= "number" then
		return
	end
	shown = { talent = talent, level = level }
	render()
	generation += 1
	local mine = generation
	screenGui.Enabled = true
	scale.Scale = 0.6
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(CLOSE_AFTER, function()
		if mine == generation then
			hide()
		end
	end)
end)

okButton.Activated:Connect(hide)
panel.Activated:Connect(hide)

Locale.Changed:Connect(function()
	if screenGui.Enabled and shown then
		render()
	end
end)

screenGui.Parent = playerGui
