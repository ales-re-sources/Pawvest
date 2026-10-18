-- Admin "Add Coins": a button at the end of the admin panel that asks the server for AdminConfig.AddCoinsAmount Coins
-- (see AdminCoinsServer; the server checks the admin list and fixes the amount). Built in code as a copy of the
-- Reset Score button's look, so the panel needs no Studio edit; the panel is made taller to fit it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminConfig = require(ReplicatedStorage:WaitForChild("AdminConfig"))
local addCoinsEvent = ReplicatedStorage:WaitForChild("AdminAddCoins")

local panel = script.Parent
local resetButton = panel:WaitForChild("ScoreResetButton")

local button = resetButton:Clone()
for _, descendant in button:GetDescendants() do
	if descendant:IsA("LuaSourceContainer") then
		descendant:Destroy() -- the copy must not carry the reset script
	end
end
button.Name = "AddCoinsButton"
button.LayoutOrder = resetButton.LayoutOrder + 1
button.Text = string.format("+%d Coins", AdminConfig.AddCoinsAmount)
button.Parent = panel
panel.Size += UDim2.fromOffset(0, resetButton.Size.Y.Offset + 10)

button.Activated:Connect(function()
	addCoinsEvent:FireServer()
end)
