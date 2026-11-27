-- Results popup after a finished run (docs/GDD.md §4–5): time, record, medal of the run, medal payout, first-finish
-- payout, repeat reward,
-- pet XP (§7.4), free egg of the first Gold (§7.2), rare seeds and the stage's rare-seed meter (E2a, players with the field), next goal,
-- and, on world stages, the rating row 👍 / 👎 (FB2: the same vote as the stage's rating sign, FeedbackRemotes.Rate; shown from the
-- player attribute StageRatings; a tap restarts the popup's timer, the panel's tap-to-close skips it).
-- Driven by the finish message StageTimerUpdate(-1, final, result); the GUI is built here, not in Studio.
-- Paths: PlayerGui.StageResults.Panel.Rate.Up / .Down (the thumbs), .Rate.Prompt.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageTimerUpdate = ReplicatedStorage:WaitForChild("StageTimerUpdate")
local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local TimeFormat = require(ReplicatedStorage:WaitForChild("TimeFormat"))
local MedalText = require(ReplicatedStorage:WaitForChild("MedalText"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local UiKit = require(ReplicatedStorage:WaitForChild("UiKit"))
local FeedbackConfig = require(ReplicatedStorage:WaitForChild("FeedbackConfig"))
local HudPopup = require(script.Parent:WaitForChild("HudPopup"))

local SHOW_SECONDS = 7
local DIM = "#5A5A5A"
local COLOR_THUMB = Color3.fromRGB(70, 70, 70)
local COLOR_UP = StudStyle.Colors.Green
local COLOR_DOWN = StudStyle.Colors.Red

local popup = HudPopup.new("StageResults", {
	displayOrder = 5,
	position = UDim2.new(0.5, 0, 0, 80),
	padding = { top = 12, bottom = 14 },
	gap = 2,
	tapCloses = true,
})
local addLine = popup.Line

local titleLabel = addLine("Title", 1, 20)
local timeLabel = addLine("Time", 2, 40)
local recordLabel = addLine("Record", 3, 18)
local starsLabel = addLine("Stars", 4, 36)
local medalLabel = addLine("Medal", 5, 18)
local coinsLabel = addLine("Coins", 6, 22)
local finishLabel = addLine("FirstFinish", 7, 18)
local runLabel = addLine("RunReward", 8, 18)
local petLabel = addLine("PetXp", 9, 16)
local eggLabel = addLine("FreeEgg", 10, 16)
local seedsLabel = addLine("RareSeeds", 11, 16)
local meterLabel = addLine("Meter", 12, 14)
local nextLabel = addLine("Next", 13, 16)

-- FB2: "Did you like it?" 👍 / 👎 (FeedbackRemotes.Rate); buttons on the panel take the tap, so it does not close the popup
local rateRow = UiKit.Create("Frame", {
	Name = "Rate",
	LayoutOrder = 14,
	Size = UDim2.new(1, -24, 0, 40),
	BackgroundTransparency = 1,
	Parent = popup.panel,
}, {
	UiKit.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	}),
})
local rateLabel = UiKit.Create("TextLabel", {
	Name = "Prompt",
	LayoutOrder = 1,
	Size = UDim2.fromOffset(0, 36),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextColor3 = StudStyle.Text.Grey,
	Text = "",
	Parent = rateRow,
})
local function thumb(name: string, order: number, icon: string): TextButton
	return UiKit.Create("TextButton", {
		Name = name,
		LayoutOrder = order,
		Size = UDim2.fromOffset(56, 36),
		AutoButtonColor = true,
		BackgroundColor3 = COLOR_THUMB,
		Font = Enum.Font.GothamBold,
		TextSize = 22,
		Text = icon,
		Parent = rateRow,
	}, { UiKit.Create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
end
local upButton = thumb("Up", 2, "👍")
local downButton = thumb("Down", 3, "👎")

local player = Players.LocalPlayer
local shown = nil -- the result on screen
local thanked = false -- a tap on this popup: the prompt says thanks
local tapped = {} -- [stageKey] = the value of a tap the server has not answered yet (shown before the attribute follows)

-- The player's vote on `stageKey`: a tap waiting for its answer, else the attribute FeedbackService mirrors (the sign shows the same).
local function ratingOf(stageKey: string): number?
	if tapped[stageKey] then
		return tapped[stageKey]
	end
	local ok, ratings = pcall(function()
		return HttpService:JSONDecode(player:GetAttribute(FeedbackConfig.RatingsAttribute))
	end)
	return if ok and type(ratings) == "table" then ratings[stageKey] else nil
end
coinsLabel.TextColor3 = StudStyle.Text.Ok
finishLabel.TextColor3 = StudStyle.Text.Ok
runLabel.TextColor3 = StudStyle.Text.Ok
petLabel.TextColor3 = Color3.fromRGB(180, 150, 255)
eggLabel.TextColor3 = Color3.fromRGB(255, 215, 90)
seedsLabel.TextColor3 = StudStyle.Text.Rare
meterLabel.TextColor3 = Color3.fromRGB(230, 200, 140)
nextLabel.TextColor3 = StudStyle.Text.Grey

local function render(result)
	local stage = StageConfig.ByKey[result.stageKey]
	titleLabel.Text = Locale.T("results.title", { stage = if stage then Locale.StageName(stage) else result.displayName })
	timeLabel.Text = TimeFormat.Format(result.time)
	recordLabel.Text = if result.newBest
		then string.format('<font color="%s">%s</font>', MedalText.Gold, Locale.T("results.newRecord"))
		else Locale.T("results.record", { time = TimeFormat.Format(result.best) })
	starsLabel.Text = MedalText.Stars(result.medal, DIM)
	medalLabel.Text = if result.medal > 0
		then Locale.T("medal.label." .. StageConfig.Medals[result.medal].name)
		else Locale.T("results.noMedal")
	coinsLabel.Visible = result.coins > 0
	coinsLabel.Text = Locale.T("results.coins", { count = result.coins })
	local finishCoins = result.finishCoins or 0
	finishLabel.Visible = finishCoins > 0
	finishLabel.Text = Locale.T("results.firstFinish", { count = finishCoins })
	local runCoins = result.runCoins or 0
	runLabel.Visible = runCoins > 0
	runLabel.Text = Locale.T("results.runReward", { count = runCoins, run = result.runsToday or 1 })
	local petXp = result.petXp or 0
	petLabel.Visible = petXp > 0 and (result.petsLeveled or 0) > 0
	petLabel.Text = Locale.T("results.petXp", { xp = petXp, move = result.moveXp or 0 })
	local freeEgg = PetConfig.Eggs[result.freeEgg or ""]
	eggLabel.Visible = freeEgg ~= nil
	eggLabel.Text = if freeEgg then Locale.T("results.freeEgg", { egg = Locale.EggName(freeEgg) }) else ""
	local obby = result.obbySeeds
	local lines = {}
	local first = type(result.firstSeeds) == "table" and result.firstSeeds -- EV3b: the first clear's seed pack
	local firstCrop = first and CropConfig.ById[first.crop]
	if firstCrop and (tonumber(first.count) or 0) > 0 then
		table.insert(lines, Locale.T("results.firstSeeds", { icon = firstCrop.icon, crop = Locale.CropName(firstCrop), count = first.count }))
	end
	for _, gain in (if type(obby) == "table" and type(obby.seeds) == "table" then obby.seeds else {}) do
		local crop = CropConfig.ById[gain.crop]
		if crop then -- a fruit tree (TR) comes as a sapling under the tree's name
			table.insert(lines, Locale.T(if crop.tree then "results.sapling" else "results.rareSeed", {
				icon = crop.icon,
				crop = if crop.tree then Locale.TreeName(crop) else Locale.CropName(crop),
				count = gain.count,
				why = Locale.T("results.rareWhy." .. tostring(gain.why)),
			}))
		end
	end
	local pouch = type(obby) == "table" and obby.pouch
	local pouchCrop = type(pouch) == "table" and CropConfig.ById[pouch.crop]
	if pouchCrop and pouch.count > 0 then
		table.insert(lines, Locale.T("results.pouch", { icon = pouchCrop.icon, crop = Locale.CropName(pouchCrop), count = pouch.count }))
	end
	if pouchCrop and pouch.full then
		table.insert(lines, Locale.T("results.pouchFull"))
	end
	seedsLabel.Visible = #lines > 0
	seedsLabel.Text = table.concat(lines, "\n")
	local meter = type(obby) == "table" and obby.meter
	local meterCrop = meter and CropConfig.ById[meter.crop]
	meterLabel.Visible = meterCrop ~= nil
	local scout = type(obby) == "table" and type(obby.scout) == "number" and obby.scout or 0
	meterLabel.Text = if meterCrop
		then Locale.T(if scout > 0 then "results.meterScout" else "results.meter", {
			icon = meterCrop.icon,
			pct = math.floor(meter.points / meter.size * 100),
			bonus = math.round(scout * 100),
		})
		else ""
	if result.nextMedal and result.nextThreshold then
		nextLabel.Text = Locale.T("results.next", {
			medal = Locale.MedalName(StageConfig.Medals[result.nextMedal]),
			time = TimeFormat.Format(result.nextThreshold),
		})
	elseif result.nextMedal then
		nextLabel.Text = ""
	else
		nextLabel.Text = Locale.T("results.allMedals")
	end
	rateRow.Visible = FeedbackConfig.Rated(stage) -- world stages only, like the signs
	local rating = ratingOf(result.stageKey)
	rateLabel.Text = Locale.T(if thanked then "results.rate.thanks" else "results.rate.prompt")
	upButton.BackgroundColor3 = if rating == 1 then COLOR_UP else COLOR_THUMB
	downButton.BackgroundColor3 = if rating == -1 then COLOR_DOWN else COLOR_THUMB
end

local function show(result)
	shown = result
	popup.Show(function()
		render(result)
		return true
	end, SHOW_SECONDS)
end

StageTimerUpdate.OnClientEvent:Connect(function(elapsed, _final, result)
	if elapsed >= 0 then
		popup.Hide() -- a new run started
		shown = nil
	elseif result then
		thanked = false
		show(result)
	end
end)

-- A tap marks the choice at once (the server's answer drops the mark: the attribute shows the stored vote) and keeps the popup up for
-- another SHOW_SECONDS. The server takes a popup vote for a while after the finish, also away from the sign.
local remotes = ReplicatedStorage:WaitForChild(FeedbackConfig.Folder)
local rateEvent = remotes:WaitForChild("Rate")
local waiting = nil -- stage key of the tap the server has not answered yet
local RATE_GAP = 1.1 -- seconds between two changes (the server's cooldown is 1 s)
local lastRate = -math.huge

local function rate(value: number)
	local result = shown
	if not result or not FeedbackConfig.Rated(StageConfig.ByKey[result.stageKey]) then
		return
	end
	thanked = true
	if ratingOf(result.stageKey) ~= value and os.clock() - lastRate >= RATE_GAP then
		lastRate = os.clock()
		waiting = result.stageKey
		tapped[result.stageKey] = value
		rateEvent:FireServer(result.stageKey, value)
	end
	show(result)
end
upButton.Activated:Connect(function()
	rate(1)
end)
downButton.Activated:Connect(function()
	rate(-1)
end)
remotes:WaitForChild("Result").OnClientEvent:Connect(function(key, ok, detail)
	if key ~= "rate" then
		return
	end
	local stageKey = waiting
	if not stageKey then
		return -- a vote on a sign
	end
	waiting = nil
	tapped[stageKey] = nil
	if not ok then
		warn("[StageResults] rating refused: " .. tostring(detail))
		thanked = false
	end
	if shown and shown.stageKey == stageKey then
		render(shown)
	end
end)

-- A vote on the sign (or a later answer) shows on an open popup too.
player:GetAttributeChangedSignal(FeedbackConfig.RatingsAttribute):Connect(function()
	if shown then
		render(shown)
	end
end)
