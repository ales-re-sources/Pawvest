-- Arrival warning (S1.2, docs/STAGES.md §6.3): arriving on a stage without a talent it requires shows a short popup
-- (StageArrival from PlayerTimerHandler) with a button that opens the Skills panel. Entry is never blocked; the popup
-- closes itself after a while. The GUI is built here, not in Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local MedalText = require(ReplicatedStorage:WaitForChild("MedalText"))
local TalentConfig = require(ReplicatedStorage:WaitForChild("TalentConfig"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local HudPopup = require(script.Parent:WaitForChild("HudPopup"))
local arrivalEvent = ReplicatedStorage:WaitForChild("StageArrival")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CLOSE_AFTER = 12 -- seconds
local COLOR_BUTTON = Color3.fromRGB(60, 120, 200)
local COLOR_CLOSE = Color3.fromRGB(110, 110, 110)

local popup = HudPopup.new("StageArrivalWarning", { displayOrder = 6 })
local titleLabel = popup.Line("Title", 1, 20)
local needsLabel = popup.Line("Needs", 2, 16)
local skillsButton = popup.Button("Skills", 3, COLOR_BUTTON)
local closeButton = popup.Button("Close", 4, COLOR_CLOSE)

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

arrivalEvent.OnClientEvent:Connect(function(stageKey)
	local stage = StageConfig.ByKey[stageKey]
	if stage then
		popup.Show(function()
			return render(stage)
		end, CLOSE_AFTER)
	end
end)

-- ButtonHandler (the top-left icons) opens its panels; the ScreenGui attribute is the request, it resets it itself
skillsButton.Activated:Connect(function()
	local main = playerGui:FindFirstChild("ScreenGui")
	if main then
		main:SetAttribute("OpenSkills", true)
	end
	popup.Hide()
end)
closeButton.Activated:Connect(popup.Hide)
