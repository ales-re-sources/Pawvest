-- Admin "Add Coins": a button at the end of the admin panel that asks the server for AdminConfig.AddCoinsAmount Coins
-- (see AdminCoinsServer; the server checks the admin list and fixes the amount). Built in code as a copy of the
-- Reset Score button, so the panel needs no Studio edit; the panel is made taller to fit it.
-- This script also gives the admin panel's contents the stud-brick look (StudStyle; the panel itself is styled by
-- ButtonHandler): Reset Score a red brick, +Coins a yellow one, the toggle rows in the panel's row tone.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminConfig = require(ReplicatedStorage:WaitForChild("AdminConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local addCoinsEvent = ReplicatedStorage:WaitForChild("AdminAddCoins")

local panel = script.Parent
local resetButton = panel:WaitForChild("ScoreResetButton")

local button = resetButton:Clone() -- cloned before the reset button is styled below (Brick rebuilds a copied look anyway)
for _, descendant in button:GetDescendants() do
	if descendant:IsA("LuaSourceContainer") then
		descendant:Destroy() -- the copy must not carry the reset script
	end
end
button.Name = "AddCoinsButton"
button.LayoutOrder = resetButton.LayoutOrder + 1
button.Text = string.format("+%d Coins", AdminConfig.AddCoinsAmount)
button.BackgroundColor3 = StudStyle.Colors.Yellow
StudStyle.Brick(button, { studs = 4 })
button.Parent = panel
panel.Size += UDim2.fromOffset(0, resetButton.Size.Y.Offset + 10)

button.Activated:Connect(function()
	addCoinsEvent:FireServer()
end)

resetButton.BackgroundColor3 = StudStyle.Colors.Red
StudStyle.Brick(resetButton, { studs = 4 })
for _, name in { "DoubleJumpFrame", "RunSpeedFrame" } do
	local row = panel:FindFirstChild(name)
	if row then
		StudStyle.Row(row, panel.Name)
		local label = row:FindFirstChild("Label")
		if label and label:IsA("TextLabel") then
			label.Font = StudStyle.Font
			label.TextColor3 = Color3.new(1, 1, 1)
		end
	end
end
