-- RatingSigns (FB2, docs/GDD.md §10 → Player feedback): the stage rating signs in the world stages' courtyards. Client only.
-- Every model tagged FeedbackConfig.SignTag (Studio-only clones of ServerStorage.StageKit.RatingSign; the stage = the stage folder it
-- stands in) gets its texts and two ProximityPrompts here: Board.Gui.Title "Did you like Stage 3?", Board.Gui.Sub (a hint, or thanks
-- once rated), the thumb parts Up / Down (a prompt "RatePrompt" each → FeedbackRemotes.Rate(stageKey, ±1)). The own choice is lit
-- (the chosen thumb takes its colour, the other its own) from the player attribute StageRatings (FeedbackService). No score is shown.
-- The prompts are Custom style: the thumbs sit ~3 studs apart, too close for two default prompt cards. Each shows a small key badge
-- (BillboardGui "RateBadge" in PlayerGui, adorned to its thumb) while the prompt is shown: the keyboard key, the gamepad button's
-- picture, or a larger thumb to tap on touch. A tap or click on the badge drives the prompt (InputHoldBegin / End).

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local FeedbackConfig = require(ReplicatedStorage:WaitForChild("FeedbackConfig"))
local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local rateEvent = ReplicatedStorage:WaitForChild(FeedbackConfig.Folder):WaitForChild("Rate")

local CHILD_WAIT = 10 -- seconds for a streamed-in sign's parts
local BADGE_SIZE = 44 -- pixels: keyboard / gamepad badge
local BADGE_SIZE_TOUCH = 56 -- pixels: a finger-sized tap target
local BADGE_DROP = 0.3 -- studs below the thumb's lower edge
local COLOR_CHOSEN = { Up = StudStyle.Colors.Green, Down = StudStyle.Colors.Red }
local THUMBS = {
	-- gamepad: the d-pad side of the plate (ButtonX is the Dash talent's); padGlyph when the platform has no button picture
	Up = { value = 1, keyboard = Enum.KeyCode.E, gamepad = Enum.KeyCode.DPadLeft, padGlyph = "◀", touchGlyph = "👍" },
	Down = { value = -1, keyboard = Enum.KeyCode.R, gamepad = Enum.KeyCode.DPadRight, padGlyph = "▶", touchGlyph = "👎" },
}

-- [sign model] = false while its parts stream in, then { stage, title, sub, thumbs = { [name] = { part, prompt, color, badge } } }
local signs = {}

local function ownRatings(): { [string]: number }
	local raw = player:GetAttribute(FeedbackConfig.RatingsAttribute)
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	return if ok and type(decoded) == "table" then decoded else {}
end

local function render(entry, ratings)
	local rating = ratings[entry.stage.key]
	if entry.title then
		entry.title.Text = Locale.T("rating.sign.title", { stage = Locale.StageName(entry.stage) })
	end
	if entry.sub then
		entry.sub.Text = Locale.T(if rating then "rating.sign.thanks" else "rating.sign.hint")
	end
	for name, thumb in entry.thumbs do
		local chosen = rating == THUMBS[name].value
		thumb.part.Color = if chosen then COLOR_CHOSEN[name] else thumb.color
		thumb.prompt.Enabled = not chosen -- the chosen thumb has nothing left to do (PromptHidden hides its badge)
	end
end

local function renderAll()
	local ratings = ownRatings()
	for _, entry in signs do
		if entry then
			render(entry, ratings)
		end
	end
end

-- the key badge under one thumb; hidden until the prompt is shown
local function makeBadge(part: BasePart, prompt: ProximityPrompt, name: string, spec)
	local gui = Instance.new("BillboardGui")
	gui.Name = "RateBadge"
	gui.Adornee = part
	gui.AlwaysOnTop = true
	gui.Active = true -- without it the Key button gets no clicks / taps
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false -- an obby player dies often; the badge belongs to the sign, not the character
	gui.AutoLocalize = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ExtentsOffsetWorldSpace = Vector3.new(0, -1, 0) -- the thumb's lower edge
	gui.StudsOffsetWorldSpace = Vector3.new(0, -BADGE_DROP, 0)
	gui.Size = UDim2.fromOffset(BADGE_SIZE, BADGE_SIZE)
	gui.Enabled = false

	local key = Instance.new("TextButton")
	key.Name = "Key"
	key.Size = UDim2.fromScale(1, 1)
	key.BackgroundColor3 = COLOR_CHOSEN[name]
	key.Font = StudStyle.Font
	key.TextSize = 24
	key.Text = ""
	key.AutoLocalize = false
	key.Parent = gui
	StudStyle.Brick(key, { compact = true })

	local pad = Instance.new("ImageLabel") -- the gamepad button's picture (the brick's Glyph shows the other inputs)
	pad.Name = "Pad"
	pad.AnchorPoint = Vector2.new(0.5, 0.5)
	pad.Position = UDim2.fromScale(0.5, 0.5)
	pad.Size = UDim2.fromScale(0.72, 0.72)
	pad.BackgroundTransparency = 1
	pad.ZIndex = 3
	pad.Visible = false
	pad.Parent = key:FindFirstChild("Top"):FindFirstChild("Face")

	-- a tap (touch) or click (mouse) on the badge presses the prompt
	local holding = false
	key.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if (t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1) and not holding then
			holding = true
			prompt:InputHoldBegin()
		end
	end)
	key.InputEnded:Connect(function(input)
		local t = input.UserInputType
		if (t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1) and holding then
			holding = false
			prompt:InputHoldEnd()
		end
	end)

	prompt.PromptShown:Connect(function(inputType: Enum.ProximityPromptInputType)
		local size = if inputType == Enum.ProximityPromptInputType.Touch then BADGE_SIZE_TOUCH else BADGE_SIZE
		gui.Size = UDim2.fromOffset(size, size)
		local image = if inputType == Enum.ProximityPromptInputType.Gamepad
			then UserInputService:GetImageForKeyCode(spec.gamepad)
			else ""
		pad.Image = image
		pad.Visible = image ~= ""
		if image ~= "" then
			key.Text = ""
		elseif inputType == Enum.ProximityPromptInputType.Gamepad then
			key.Text = spec.padGlyph
		elseif inputType == Enum.ProximityPromptInputType.Touch then
			key.Text = spec.touchGlyph
		else
			local label = UserInputService:GetStringForKeyCode(spec.keyboard) -- the key's letter on the player's layout
			key.Text = if label ~= "" then label else spec.keyboard.Name
		end
		gui.Enabled = true
	end)
	prompt.PromptHidden:Connect(function()
		gui.Enabled = false
		if holding then
			holding = false
			prompt:InputHoldEnd()
		end
	end)

	gui.Parent = playerGui -- a BillboardGui's buttons take input only from PlayerGui
	return gui
end

local function dropEntry(entry)
	for _, thumb in entry.thumbs do
		thumb.badge:Destroy()
	end
end

local function add(sign: Instance)
	if signs[sign] ~= nil or not sign:IsDescendantOf(workspace) then
		return
	end
	local stage = StageConfig.TryForInstance(sign)
	if not FeedbackConfig.Rated(stage) then
		warn("[RatingSigns] a sign outside a world stage: " .. sign:GetFullName())
		return
	end
	signs[sign] = false -- pending: a second add for the same sign stops at the check above
	local board = sign:WaitForChild("Board", CHILD_WAIT)
	local gui = board and board:WaitForChild("Gui", CHILD_WAIT)
	local entry = {
		stage = stage,
		title = gui and gui:FindFirstChild("Title"),
		sub = gui and gui:FindFirstChild("Sub"),
		thumbs = {},
	}
	for name, spec in THUMBS do
		local part = sign:WaitForChild(name, CHILD_WAIT)
		if part and part:IsA("BasePart") then
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "RatePrompt"
			prompt.Style = Enum.ProximityPromptStyle.Custom -- drawn by makeBadge
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = FeedbackConfig.PromptDistance
			prompt.RequiresLineOfSight = false
			prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow -- both thumbs show at once
			prompt.KeyboardKeyCode = spec.keyboard
			prompt.GamepadKeyCode = spec.gamepad
			prompt.Triggered:Connect(function()
				rateEvent:FireServer(stage.key, spec.value)
			end)
			local badge = makeBadge(part, prompt, name, spec)
			prompt.Parent = part
			entry.thumbs[name] = { part = part, prompt = prompt, color = part.Color, badge = badge }
		end
	end
	if signs[sign] ~= false or not sign.Parent then -- streamed out while its parts were loading
		dropEntry(entry)
		return
	end
	signs[sign] = entry
	render(entry, ownRatings())
end

CollectionService:GetInstanceAddedSignal(FeedbackConfig.SignTag):Connect(function(sign)
	task.spawn(add, sign)
end)
CollectionService:GetInstanceRemovedSignal(FeedbackConfig.SignTag):Connect(function(sign)
	local entry = signs[sign]
	signs[sign] = nil -- streamed out: its parts (and prompts) went with it; the badges live in PlayerGui
	if entry then
		dropEntry(entry)
	end
end)
for _, sign in CollectionService:GetTagged(FeedbackConfig.SignTag) do
	task.spawn(add, sign)
end

player:GetAttributeChangedSignal(FeedbackConfig.RatingsAttribute):Connect(renderAll)
Locale.Changed:Connect(renderAll)
