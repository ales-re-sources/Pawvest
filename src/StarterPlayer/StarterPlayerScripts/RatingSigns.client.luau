-- RatingSigns (FB2, docs/GDD.md §10 → Player feedback): the stage rating signs in the world stages' courtyards. Client only.
-- Every model tagged FeedbackConfig.SignTag (Studio-only clones of ServerStorage.StageKit.RatingSign; the stage = the stage folder it
-- stands in) gets its texts and two ProximityPrompts here: Board.Gui.Title "Did you like Stage 3?", Board.Gui.Sub (a hint, or thanks
-- once rated), the thumb parts Up / Down (a prompt "RatePrompt" each → FeedbackRemotes.Rate(stageKey, ±1)). The own choice is lit
-- (the chosen thumb takes its colour, the other its own) from the player attribute StageRatings (FeedbackService). No score is shown.

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FeedbackConfig = require(ReplicatedStorage:WaitForChild("FeedbackConfig"))
local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))

local player = Players.LocalPlayer
local rateEvent = ReplicatedStorage:WaitForChild(FeedbackConfig.Folder):WaitForChild("Rate")

local CHILD_WAIT = 10 -- seconds for a streamed-in sign's parts
local COLOR_CHOSEN = { Up = StudStyle.Colors.Green, Down = StudStyle.Colors.Red }
local THUMBS = {
	-- gamepad: the d-pad side of the plate (ButtonX is the Dash talent's)
	Up = { value = 1, key = "rating.prompt.up", keyboard = Enum.KeyCode.E, gamepad = Enum.KeyCode.DPadLeft },
	Down = { value = -1, key = "rating.prompt.down", keyboard = Enum.KeyCode.R, gamepad = Enum.KeyCode.DPadRight },
}

local signs = {} -- [sign model] = { stage, title, sub, thumbs = { [name] = { part, prompt, color } } }

local function ownRatings(): { [string]: number }
	local raw = player:GetAttribute(FeedbackConfig.RatingsAttribute)
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	return if ok and type(decoded) == "table" then decoded else {}
end

local function render(entry, ratings)
	local rating = ratings[entry.stage.key]
	local stageName = Locale.StageName(entry.stage)
	if entry.title then
		entry.title.Text = Locale.T("rating.sign.title", { stage = stageName })
	end
	if entry.sub then
		entry.sub.Text = Locale.T(if rating then "rating.sign.thanks" else "rating.sign.hint")
	end
	for name, thumb in entry.thumbs do
		local chosen = rating == THUMBS[name].value
		thumb.part.Color = if chosen then COLOR_CHOSEN[name] else thumb.color
		thumb.prompt.ActionText = Locale.T(THUMBS[name].key)
		thumb.prompt.ObjectText = stageName
		thumb.prompt.Enabled = not chosen -- the chosen thumb has nothing left to do
	end
end

local function renderAll()
	local ratings = ownRatings()
	for _, entry in signs do
		render(entry, ratings)
	end
end

local function add(sign: Instance)
	if signs[sign] or not sign:IsDescendantOf(workspace) then
		return
	end
	local stage = StageConfig.TryForInstance(sign)
	if not FeedbackConfig.Rated(stage) then
		warn("[RatingSigns] a sign outside a world stage: " .. sign:GetFullName())
		return
	end
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
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = FeedbackConfig.PromptDistance
			prompt.RequiresLineOfSight = false
			prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow -- both thumbs show at once
			prompt.KeyboardKeyCode = spec.keyboard
			prompt.GamepadKeyCode = spec.gamepad
			prompt.Triggered:Connect(function()
				rateEvent:FireServer(stage.key, spec.value)
			end)
			prompt.Parent = part
			entry.thumbs[name] = { part = part, prompt = prompt, color = part.Color }
		end
	end
	if signs[sign] or not sign.Parent then
		return
	end
	signs[sign] = entry
	render(entry, ownRatings())
end

CollectionService:GetInstanceAddedSignal(FeedbackConfig.SignTag):Connect(function(sign)
	task.spawn(add, sign)
end)
CollectionService:GetInstanceRemovedSignal(FeedbackConfig.SignTag):Connect(function(sign)
	signs[sign] = nil -- streamed out: its parts (and prompts) went with it
end)
for _, sign in CollectionService:GetTagged(FeedbackConfig.SignTag) do
	task.spawn(add, sign)
end

player:GetAttributeChangedSignal(FeedbackConfig.RatingsAttribute):Connect(renderAll)
Locale.Changed:Connect(renderAll)
