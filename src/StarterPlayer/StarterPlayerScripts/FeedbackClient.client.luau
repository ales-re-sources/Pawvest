-- FeedbackClient (FB, docs/GDD.md → Player feedback): the "Send feedback" row of the Settings panel (SettingsRow, LayoutOrder 3) and
-- the Feedback panel it opens (GardenUi.Panel, PanelFocus "Feedback"): a category (bug / idea / other, one must be picked), a box cut
-- at FeedbackConfig.MaxLength characters with a counter, the "don't write your name or contacts" line, Send and a status line.
-- Send fires FeedbackRemotes.Send(category, text); the answer comes on FeedbackRemotes.Result ("send", ok, left today / reason).
-- Hook (ScreenGui FeedbackGui attribute, cleared after use): Open = true opens the panel. Paths: PlayerGui.FeedbackGui.Panel.Content
-- .Category.<bug|idea|other>, .Box.Input (the TextBox), .Counter, .Send, .Status; the Settings row: ScreenGui.SettingsPanel.FeedbackRow.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FeedbackConfig = require(ReplicatedStorage:WaitForChild("FeedbackConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local PanelFocus = require(ReplicatedStorage:WaitForChild("PanelFocus"))
local UiKit = require(ReplicatedStorage:WaitForChild("UiKit"))
local GardenUi = require(script.Parent:WaitForChild("GardenUi"))
local SettingsRow = require(script.Parent:WaitForChild("SettingsRow"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild(FeedbackConfig.Folder)
local sendEvent = remotes:WaitForChild("Send")

local PANEL_WIDTH = 420
local PANEL_HEIGHT = 470
local BOX_HEIGHT = 130
local ANSWER_TIMEOUT = 20 -- seconds before a Send without an answer frees the button again

local COLOR = StudStyle.PanelColors.SettingsPanel
local COLOR_PICK = StudStyle.Shade(COLOR, 0.6)
local COLOR_PICKED = StudStyle.Colors.Green
local COLOR_BOX = StudStyle.Shade(COLOR, 0.3)
local REJECT_KEYS = {
	category = "feedback.reject.category",
	empty = "feedback.reject.empty",
	long = "feedback.reject.long",
	daily = "feedback.reject.daily",
	filter = "feedback.reject.filter",
	wait = "feedback.reject.wait",
}

local create = UiKit.Create
local max = FeedbackConfig.MaxLength

local ui = GardenUi.Panel("FeedbackGui", COLOR, PANEL_WIDTH, PANEL_HEIGHT)
local content = ui.content :: ScrollingFrame

local intro = GardenUi.Paragraph("Intro", { LayoutOrder = 1, TextSize = 15, Text = "" })
intro.Parent = content

local categoryRow = create("Frame", {
	Name = "Category",
	LayoutOrder = 2,
	Size = UDim2.new(1, 0, 0, 44),
	BackgroundTransparency = 1,
	Parent = content,
}, {
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, GardenUi.GAP),
	}),
})
local categoryButtons = {} -- [category] = TextButton
for index, category in FeedbackConfig.Categories do
	categoryButtons[category] = GardenUi.Button(category, {
		LayoutOrder = index,
		Size = UDim2.new(1 / #FeedbackConfig.Categories, -GardenUi.GAP, 1, 0),
		BackgroundColor3 = COLOR_PICK,
		TextSize = 16,
		TextWrapped = true,
		Text = "",
		Parent = categoryRow,
	}, 2)
end

local boxFrame = create("Frame", {
	Name = "Box",
	LayoutOrder = 3,
	Size = UDim2.new(1, 0, 0, BOX_HEIGHT),
	BackgroundColor3 = COLOR_BOX,
	Parent = content,
}, {
	create("UICorner", { CornerRadius = UDim.new(0, 8) }),
	create("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	}),
})
local box = create("TextBox", {
	Name = "Input",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ClearTextOnFocus = false,
	MultiLine = true,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Font = Enum.Font.Gotham,
	TextSize = 16,
	TextColor3 = Color3.new(1, 1, 1),
	PlaceholderColor3 = StudStyle.Text.Dim,
	Text = "",
	Parent = boxFrame,
}) :: TextBox

local counter = UiKit.Label("Counter", {
	LayoutOrder = 4,
	Size = UDim2.new(1, -8, 0, 18),
	Font = Enum.Font.Gotham,
	TextSize = 14,
	TextColor3 = StudStyle.Text.Dim,
	TextXAlignment = Enum.TextXAlignment.Right,
	Text = "",
	Parent = content,
})
local warning = GardenUi.Paragraph("Warning", { LayoutOrder = 5, TextSize = 14, TextColor3 = StudStyle.Text.Rare, Text = "" })
warning.Parent = content

local sendButton = GardenUi.Button("Send", {
	LayoutOrder = 6,
	Size = UDim2.new(1, 0, 0, 44),
	BackgroundColor3 = GardenUi.COLOR_BUY,
	TextSize = 18,
	Text = "",
	Parent = content,
}, 4)
local status = GardenUi.Paragraph("Status", { LayoutOrder = 7, TextSize = 15, Text = "" })
status.Parent = content

local picked: string? = nil
local sending = false
local statusKey: string? = nil -- the status line's text as (key, args, color), kept for a language change
local statusArgs: { [string]: any }? = nil
local statusColor = StudStyle.Text.Info
local answerTimer = UiKit.Latest()

local function setStatus(key: string?, args: { [string]: any }?, color: Color3?)
	statusKey, statusArgs, statusColor = key, args, color or StudStyle.Text.Info
	status.Text = if key then Locale.T(key, args) else ""
	status.TextColor3 = statusColor
end

local function length(): number
	return utf8.len(box.Text) or #box.Text
end

local function render()
	ui.title.Text = Locale.T("feedback.title")
	intro.Text = Locale.T("feedback.intro")
	for category, button in categoryButtons do
		button.Text = Locale.T("feedback.category." .. category, { icon = FeedbackConfig.CategoryIcons[category] })
		button.BackgroundColor3 = if picked == category then COLOR_PICKED else COLOR_PICK
	end
	box.PlaceholderText = Locale.T("feedback.placeholder")
	counter.Text = Locale.T("feedback.counter", { count = length(), max = max })
	warning.Text = Locale.T("feedback.warning")
	sendButton.Text = Locale.T(if sending then "feedback.sending" else "feedback.send")
	sendButton.BackgroundColor3 = if sending then GardenUi.COLOR_LOCKED else GardenUi.COLOR_BUY
	if statusKey then
		status.Text = Locale.T(statusKey, statusArgs)
		status.TextColor3 = statusColor
	end
end

box:GetPropertyChangedSignal("Text"):Connect(function()
	local cut = FeedbackConfig.Cut(box.Text, max)
	if cut ~= box.Text then
		box.Text = cut -- fires again with the cut text
		return
	end
	counter.Text = Locale.T("feedback.counter", { count = length(), max = max })
end)

for category, button in categoryButtons do
	button.Activated:Connect(function()
		picked = category
		render()
	end)
end

local function finishSending()
	sending = false
	answerTimer.Cancel()
	render()
end

sendButton.Activated:Connect(function()
	if sending then
		return
	end
	if not picked then
		return setStatus("feedback.reject.category", nil, StudStyle.Text.Error)
	end
	local text = FeedbackConfig.Trim(box.Text) or ""
	if text == "" then
		return setStatus("feedback.reject.empty", nil, StudStyle.Text.Error)
	end
	sending = true
	setStatus(nil)
	render()
	answerTimer.After(ANSWER_TIMEOUT, function()
		sending = false
		setStatus("common.reject.failed", nil, StudStyle.Text.Error)
		render()
	end)
	sendEvent:FireServer(picked, text)
end)

remotes:WaitForChild("Result").OnClientEvent:Connect(function(key, ok, detail)
	if key ~= "send" then
		return
	end
	if ok then
		box.Text = ""
		picked = nil
		setStatus("feedback.thanks", nil, StudStyle.Text.Ok)
	else
		local reason = if type(detail) == "string" then detail else "failed"
		local shared = "common.reject." .. reason -- Locale.Reject's order, as a key kept for a language change
		setStatus(REJECT_KEYS[reason] or (if Locale.Has(shared) then shared else "common.reject.failed"), nil, StudStyle.Text.Error)
	end
	finishSending()
end)

local isOpen = false

local function closePanel()
	PanelFocus.Closed("Feedback")
	isOpen = false
	ui.panel.Visible = false
	box:ReleaseFocus()
end

local function openPanel()
	PanelFocus.Open("Feedback", closePanel) -- closes the Settings panel; walking away closes this one
	isOpen = true
	if not sending and statusColor ~= StudStyle.Text.Error then
		setStatus(nil) -- an old "thanks" goes; a refusal stays until the next try
	end
	ui.Fit()
	ui.panel.Visible = true
	render()
end

ui.close.Activated:Connect(closePanel)
ui.gui:GetAttributeChangedSignal("Open"):Connect(function()
	if ui.gui:GetAttribute("Open") == true then
		ui.gui:SetAttribute("Open", nil)
		openPanel()
	end
end)
Locale.Changed:Connect(render)
ui.OnResize(render)

SettingsRow.Mount("FeedbackRow", 3, function(button)
	button.Text = Locale.T("settings.feedback")
end, function()
	if isOpen then
		closePanel()
	else
		openPanel()
	end
end)

render()
ui.gui.Parent = playerGui
