-- Studio admin shortcut to the disposable plant-art reviewer; no remotes or profile writes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local AdminConfig = require(ReplicatedStorage:WaitForChild("AdminConfig"))
if not RunService:IsStudio() or not AdminConfig.IsAdmin(player.UserId) then return end

local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local panel = script.Parent
local resetButton = panel:WaitForChild("ScoreResetButton")
local button = resetButton:Clone()
for _, child in button:GetDescendants() do
	if child:IsA("LuaSourceContainer") then child:Destroy() end
end
button.Name = "PlantReviewButton"
button.LayoutOrder = resetButton.LayoutOrder + 2
button.Size = UDim2.new(resetButton.Size.X.Scale,resetButton.Size.X.Offset,0,48)
button.AutoLocalize = false
button.TextSize, button.TextScaled, button.TextWrapped = 18, false, true
button.BackgroundColor3 = StudStyle.Colors.Green
Locale.SetKey(button,"admin.plants.open")
StudStyle.Brick(button,{studs=4})
button.Parent = panel
panel.Size += UDim2.fromOffset(0,button.Size.Y.Offset+10)

local opening = false
button.Activated:Connect(function()
	if opening or workspace:FindFirstChild("PlantGrowthReview") then return end
	opening = true
	local ok,err = pcall(function()
		local scripts = player:WaitForChild("PlayerScripts")
		require(scripts:WaitForChild("PlantGrowthReview")).Open()
	end)
	opening = false
	if not ok then warn("[PlantGrowthReview] " .. tostring(err)) end
end)
