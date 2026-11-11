-- StageExploreWarning: the server (CheckpointTouchHandler, ExploreWarning remote) reports that the player reached a checkpoint
-- of a stage without a running timer for it, i.e. they got in around the gate (over the courtyard wall, a locked gate).
-- That is allowed, but it is an exploring run: no time, medal or finish reward counts, collected Coins do. A banner says so
-- for a few seconds; it goes away at once when a timed run starts. GUI built in code.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local HudPopup = require(script.Parent:WaitForChild("HudPopup"))
local exploreEvent = ReplicatedStorage:WaitForChild("ExploreWarning")
local StageTimerUpdate = ReplicatedStorage:WaitForChild("StageTimerUpdate")

local SHOW_SECONDS = 9

local popup = HudPopup.new("StageExploreWarning", {
	displayOrder = 5,
	width = 440,
	anchor = Vector2.new(0.5, 1),
	position = UDim2.new(0.5, 0, 1, -110),
	padding = { top = 10, bottom = 10, side = 12 },
	stroke = { color = Color3.fromRGB(255, 190, 60), thickness = 2 },
	fadeSeconds = 0.4,
})
local label = popup.Line("Text", 1, 16, { Font = Enum.Font.GothamMedium, Size = UDim2.new(1, 0, 0, 0) })

exploreEvent.OnClientEvent:Connect(function(stageKey)
	local stage = StageConfig.ByKey[stageKey]
	if stage then
		popup.Show(function()
			label.Text = Locale.T("hud.explore", { stage = Locale.StageName(stage) })
			return true
		end, SHOW_SECONDS)
	end
end)

-- a timed run started: the warning no longer applies
StageTimerUpdate.OnClientEvent:Connect(function(elapsed)
	if type(elapsed) == "number" and elapsed >= 0 then
		popup.Hide()
	end
end)
