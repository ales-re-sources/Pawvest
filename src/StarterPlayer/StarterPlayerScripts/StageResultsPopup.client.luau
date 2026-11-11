-- Results popup after a finished run (docs/GDD.md §4–5): time, record, medal of the run, medal payout, first-finish
-- payout, repeat reward,
-- pet XP (§7.4), free egg of the first Gold (§7.2), rare seeds and the stage's rare-seed meter (E2a, players with the field), next goal.
-- Driven by the finish message StageTimerUpdate(-1, final, result); the GUI is built here, not in Studio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageTimerUpdate = ReplicatedStorage:WaitForChild("StageTimerUpdate")
local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local TimeFormat = require(ReplicatedStorage:WaitForChild("TimeFormat"))
local MedalText = require(ReplicatedStorage:WaitForChild("MedalText"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local HudPopup = require(script.Parent:WaitForChild("HudPopup"))

local SHOW_SECONDS = 7
local DIM = "#5A5A5A"

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
	for _, gain in (if type(obby) == "table" and type(obby.seeds) == "table" then obby.seeds else {}) do
		local crop = CropConfig.ById[gain.crop]
		if crop then
			table.insert(lines, Locale.T("results.rareSeed", {
				icon = crop.icon,
				crop = Locale.CropName(crop),
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
end

StageTimerUpdate.OnClientEvent:Connect(function(elapsed, _final, result)
	if elapsed >= 0 then
		popup.Hide() -- a new run started
	elseif result then
		popup.Show(function()
			render(result)
			return true
		end, SHOW_SECONDS)
	end
end)
