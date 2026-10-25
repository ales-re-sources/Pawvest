local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Wait for the RemoteEvent
local coinUpdateEvent = ReplicatedStorage:WaitForChild("CoinUpdateEvent")

-- Get the TextLabel
local coinFrame = script.Parent:WaitForChild("Frame")
local coinTextLabel = coinFrame:WaitForChild("TextLabel")

-- Stud-brick look (StudStyle): a wooden plate with studs, the count in white chunky text
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
StudStyle.Plate(coinFrame, StudStyle.Colors.Wood, 4)
StudStyle.Title(coinTextLabel, StudStyle.Colors.Wood)
StudStyle.Coin(coinFrame:WaitForChild("ImageLabel"))
-- the count centred in the plate's space right of the coin
coinTextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
coinTextLabel.Position = UDim2.fromScale(0.62, 0.5)
coinTextLabel.Size = UDim2.fromScale(0.6, 0.64)
coinTextLabel.TextXAlignment = Enum.TextXAlignment.Center
coinTextLabel.TextYAlignment = Enum.TextYAlignment.Center

-- Function to update the coin display
local function updateCoinDisplay(coinAmount)
	if coinTextLabel then
		coinTextLabel.Text = tostring(coinAmount)
	end
end

-- Listen for coin updates from server
coinUpdateEvent.OnClientEvent:Connect(updateCoinDisplay)

-- Also update when character loads (in case data loads before GUI)
player.CharacterAdded:Connect(function()
	task.wait(1) -- Give time for data to load
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then
			updateCoinDisplay(coins.Value)
		end
	end
end)

-- Initial update in case player is already loaded
local leaderstats = player:FindFirstChild("leaderstats")
if leaderstats then
	local coins = leaderstats:FindFirstChild("Coins")
	if coins then
		updateCoinDisplay(coins.Value)
	end
end