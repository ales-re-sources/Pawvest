-- The status card (ScreenGui.ScorePanel: stage name, record, medal limits) made collapsible and screen-aware. Collapsed
-- it shows only the name row; tapping the name row toggles it. On a phone-sized screen it starts collapsed, is scaled
-- down; everywhere it sits right under the coin plate, aligned with its right edge. The card is re-created with its
-- ScreenGui on every respawn, so it is set up again each time and the chosen state is kept here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local PanelFit = require(ReplicatedStorage:WaitForChild("PanelFit"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local EXPANDED_HEIGHT = 150
local COLLAPSED_HEIGHT = 50 -- the name row (10 + 40) and a little air
local SMALL_SCREEN_HEIGHT = 500 -- viewport height below which the screen counts as a phone
local TOGGLE_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local collapsed = nil -- nil until the first card: then the default for this screen, afterwards the player's choice
local current = nil -- { panel, scale, glyph, details } of the card now on screen

local function layout(card)
	card.scale.Scale = math.clamp(camera.ViewportSize.Y / 600, 0.7, 1)
	card.panel.AnchorPoint = Vector2.new(1, 0) -- the scale shrinks it towards the top right corner
	card.panel.Position = UDim2.new(1, -12, 0, 12) -- right edge in line with the coin plate (CoinGui), just below it
end

local function apply(card, animate)
	card.glyph.Text = if collapsed then "+" else "-"
	for _, row in card.details do
		row.Visible = not collapsed
	end
	local size = UDim2.fromOffset(250, if collapsed then COLLAPSED_HEIGHT else EXPANDED_HEIGHT)
	if animate then
		TweenService:Create(card.panel, TOGGLE_TWEEN, { Size = size }):Play()
	else
		card.panel.Size = size
	end
end

local function setup(screenGui)
	local panel = screenGui:WaitForChild("ScorePanel", 10)
	if not panel then
		return
	end
	local nameLabel = panel:WaitForChild("StageName")
	local details = { panel:WaitForChild("StageRecord"), panel:FindFirstChild("StageMedals") }

	if collapsed == nil then
		collapsed = PanelFit.ViewportHeight() < SMALL_SCREEN_HEIGHT -- not the camera's first placeholder size
	end

	-- a long (Czech) name shrinks instead of running under the toggle
	nameLabel.Size = UDim2.new(1, -56, 0, 40)
	nameLabel.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 22
	limit.Parent = nameLabel

	local scale = Instance.new("UIScale")
	scale.Parent = panel

	-- the whole name row is the button; a dark round socket with +/- at its right end says so
	local hit = Instance.new("TextButton")
	hit.Name = "Toggle"
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.Size = UDim2.new(1, 0, 0, COLLAPSED_HEIGHT)
	hit.ZIndex = 10
	hit.Parent = panel

	local socket = Instance.new("Frame")
	socket.AnchorPoint = Vector2.new(1, 0.5)
	socket.Position = UDim2.new(1, -12, 0, 30)
	socket.Size = UDim2.fromOffset(30, 30)
	socket.BackgroundColor3 = StudStyle.Shade(StudStyle.Colors.Wood, 0.4)
	socket.BackgroundTransparency = 0.25
	socket.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = socket
	socket.Parent = hit

	local glyph = Instance.new("TextLabel")
	glyph.BackgroundTransparency = 1
	glyph.Size = UDim2.fromScale(1, 1)
	glyph.AutoLocalize = false
	glyph.TextSize = 26
	StudStyle.Title(glyph, StudStyle.Colors.Wood)
	glyph.Parent = socket

	local card = { panel = panel, scale = scale, glyph = glyph, details = details }
	current = card
	layout(card)
	apply(card, false)

	hit.MouseButton1Click:Connect(function()
		collapsed = not collapsed
		apply(card, true)
	end)
end

playerGui.ChildAdded:Connect(function(child)
	if child.Name == "ScreenGui" then
		setup(child)
	end
end)
local existing = playerGui:FindFirstChild("ScreenGui")
if existing then
	task.spawn(setup, existing)
end

camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	if current and current.panel.Parent then
		layout(current)
	end
end)
