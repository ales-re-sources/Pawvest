-- "New skill" popup (K1, GDD §6): a world reward was granted (TalentRemotes.Granted from TalentService), e.g. Double Jump
-- when World 2 opens. Big title, one line on how to use it, one button; a tap anywhere on it closes it (young players on a
-- phone tap the text, not the button), else it closes itself after a while. Built here, not in Studio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TalentConfig = require(ReplicatedStorage:WaitForChild("TalentConfig"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local HudPopup = require(script.Parent:WaitForChild("HudPopup"))
local grantedEvent = ReplicatedStorage:WaitForChild("TalentRemotes"):WaitForChild("Granted")

local CLOSE_AFTER = 12 -- seconds
local COLOR_TITLE = Color3.fromRGB(255, 214, 102)
local COLOR_BUTTON = Color3.fromRGB(70, 170, 80)
-- how to use a granted talent, in a child's words; other talents fall back to their effect line
local HOW_KEYS = { DoubleJump = "talent.granted.how.DoubleJump" }

local popup = HudPopup.new("TalentGrantPopup", {
	displayOrder = 7, -- above the arrival warning
	padding = { top = 14, bottom = 14 },
	gap = 8,
	stroke = { color = COLOR_TITLE, thickness = 3 },
	tapCloses = true, -- young players on a phone tap the text, not the button
	pop = true,
})
local titleLabel = popup.Line("Title", 1, 24, { TextColor3 = COLOR_TITLE, RichText = false })
local howLabel = popup.Line("How", 2, 18, { RichText = false })
local okButton = popup.Button("Ok", 3, COLOR_BUTTON, 40, 18)

grantedEvent.OnClientEvent:Connect(function(talentId, level)
	local talent = TalentConfig.ById[talentId]
	if not talent or type(level) ~= "number" then
		return
	end
	popup.Show(function()
		titleLabel.Text = Locale.T("talent.granted.title", { talent = Locale.TalentName(talent, level) })
		local how = HOW_KEYS[talent.id]
		howLabel.Text = if how then Locale.T(how) else Locale.TalentEffect(talent, level)
		okButton.Text = Locale.T("talent.granted.ok")
		return true
	end, CLOSE_AFTER)
end)

okButton.Activated:Connect(popup.Hide)
