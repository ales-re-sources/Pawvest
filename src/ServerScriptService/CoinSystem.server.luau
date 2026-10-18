local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Coins are stored in the player's profile (loaded / saved by PlayerProfile); pickups live in ChallengeCoins
local PlayerProfile = require(ServerScriptService.PlayerProfile)

-- Create RemoteEvent for coin updates
local coinUpdateEvent = Instance.new("RemoteEvent")
coinUpdateEvent.Name = "CoinUpdateEvent"
coinUpdateEvent.Parent = ReplicatedStorage

function createLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local stage = Instance.new("StringValue")
	stage.Name = "Stage"
	stage.Parent = leaderstats

	-- Add coins to leaderstats
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats
end

-- Mirror profile Coins into leaderstats and the client counter
local function showCoins(player, amount)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if coins then
		coins.Value = amount
	end
	coinUpdateEvent:FireClient(player, amount)
end

-- Show coins once the profile is loaded
local function loadPlayerData(player)
	local profile = PlayerProfile.WaitFor(player)
	if profile then
		showCoins(player, profile.Coins)
	end
end

PlayerProfile.CoinsChanged:Connect(showCoins)

-- Handle existing and new players
Players.PlayerAdded:Connect(function(player)
	createLeaderstats(player)
	loadPlayerData(player)
end)

for _, player in Players:GetPlayers() do
	if not player:FindFirstChild("leaderstats") then
		createLeaderstats(player)
	end
	task.spawn(loadPlayerData, player)
end
