-- Arrival warning (S1.2, docs/STAGES.md §6.3): arriving on a stage without a talent it requires shows a short popup
-- (StageArrival from PlayerTimerHandler) with a button that opens the Skills panel. Entry is never blocked; the popup
-- closes itself after a while. The GUI is built here, not in Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local MedalText = require(ReplicatedStorage:WaitForChild("MedalText"))
local TalentConfig = require(ReplicatedStorage:WaitForChild("TalentConfig"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local arrivalEvent = ReplicatedStorage:WaitForChild("StageArrival")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CLOSE_AFTER = 12 -- seconds
local COLOR_PANEL = Color3.fromRGB(32, 32, 32)
local COLOR_BUTTON = Color3.fromRGB(60, 120, 200)
local COLOR_CLOSE = Color3.fromRGB(110, 110, 110)

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

local function line(name: string, order: number, textSize: number)
	return create("TextLabel", {
		Name = name,
		LayoutOrder = order,
		Size = UDim2.new(1, -24, 0, textSize + 6),
		AutomaticSize = Enum.AutomaticSize.Y, -- wrapped lines (longer in Czech) grow the panel
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = textSize,
		TextColor3 = Color3.new(1, 1, 1),
		TextWrapped = true,
		RichText = true,
		Text = "",
	})
end

local function button(name: string, order: number, color: Color3, text: string)
	return create("TextButton", {
		Name = name,
		LayoutOrder = order,
		Size = UDim2.new(1, -48, 0, 36),
		BackgroundColor3 = color,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = Color3.new(1, 1, 1),
		Text = text,
	}, { create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
end

local titleLabel = line("Title", 1, 20)
local needsLabel = line("Needs", 2, 16)
local skillsButton = button("Skills", 3, COLOR_BUTTON, "")
local closeButton = button("Close", 4, COLOR_CLOSE, "")

local panel = create("Frame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 90),
	Size = UDim2.fromOffset(320, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = COLOR_PANEL,
	BackgroundTransparency = 0.1,
}, {
	create("UICorner", { CornerRadius = UDim.new(0, 12) }),
	create("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12) }),
	create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 6),
	}),
	titleLabel,
	needsLabel,
	skillsButton,
	closeButton,
})

local screenGui = create("ScreenGui", {
	Name = "StageArrivalWarning",
	ResetOnSpawn = false,
	DisplayOrder = 6,
	Enabled = false,
	AutoLocalize = false, -- translated by Locale (L1)
}, { panel })

local generation = 0
local shownStage = nil -- re-rendered when the language changes

-- fills the popup for `stage`; false when the player has every talent it needs
local function render(stage): boolean
	local needs = MedalText.Needs(stage, function(id)
		return player:GetAttribute(TalentConfig.AttributeName(id)) or 0
	end)
	if not needs then
		return false
	end
	titleLabel.Text = Locale.T("hud.arrival.title", { stage = Locale.StageName(stage) })
	needsLabel.Text = needs .. "\n" .. Locale.T("hud.arrival.body")
	skillsButton.Text = Locale.T("hud.arrival.openSkills")
	closeButton.Text = Locale.T("hud.arrival.continue")
	return true
end

local function hide()
	generation += 1
	screenGui.Enabled = false
end

arrivalEvent.OnClientEvent:Connect(function(stageKey)
	local stage = StageConfig.ByKey[stageKey]
	if not stage then
		return
	end
	if not render(stage) then
		return
	end
	shownStage = stage
	generation += 1
	local shown = generation
	screenGui.Enabled = true
	task.delay(CLOSE_AFTER, function()
		if shown == generation then
			hide()
		end
	end)
end)

-- ButtonHandler (the top-left icons) opens its panels; the ScreenGui attribute is the request, it resets it itself
skillsButton.Activated:Connect(function()
	local main = playerGui:FindFirstChild("ScreenGui")
	if main then
		main:SetAttribute("OpenSkills", true)
	end
	hide()
end)
closeButton.Activated:Connect(hide)

Locale.Changed:Connect(function()
	if screenGui.Enabled and shownStage then
		render(shownStage)
	end
end)

screenGui.Parent = playerGui
