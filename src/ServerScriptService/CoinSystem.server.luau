local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create DataStore for coins
local coinDataStore = DataStoreService:GetDataStore("PlayerCoins")

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

-- Load player's coin data
function loadPlayerData(player)
	local success, data = pcall(function()
		return coinDataStore:GetAsync(player.UserId)
	end)
	
	if success and data then
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local coins = leaderstats:FindFirstChild("Coins")
			if coins then
				coins.Value = data
				-- Notify client of loaded coins
				coinUpdateEvent:FireClient(player, data)
			end
		end
	else
		-- If no data exists, start with 0 coins
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local coins = leaderstats:FindFirstChild("Coins")
			if coins then
				coinUpdateEvent:FireClient(player, 0)
			end
		end
	end
end

-- Save player's coin data
function savePlayerData(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then
			local success, errorMessage = pcall(function()
				coinDataStore:SetAsync(player.UserId, coins.Value)
			end)
			
			if not success then
				warn("Failed to save coin data for " .. player.Name .. ": " .. errorMessage)
			end
		end
	end
end

-- Handle coin collection
local function makeTouchHandler(coinPart)
	local lastHitPart = nil

	return function (otherPart)
		if otherPart == lastHitPart then
			return
		end
		lastHitPart = otherPart
		
		local character = otherPart.Parent
		if not character then return end
		
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end
		
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end
		
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then return end
		
		local coins = leaderstats:FindFirstChild("Coins")
		if not coins then return end

		coinPart.Transparency = 1
		coinPart.CanTouch = false

		-- Add 1 coin
		coins.Value = coins.Value + 1
		
		-- Notify client of coin update
		coinUpdateEvent:FireClient(player, coins.Value)
		
		-- Save data immediately
		savePlayerData(player)
	end
end


-- Setup coin touch event for all coins in a folder
local coinFolder = workspace:FindFirstChild("CoinsFolder")
if coinFolder then
	for _, coin in ipairs(coinFolder:GetChildren()) do
		if coin:IsA("BasePart") then
			coin.Touched:Connect(makeTouchHandler(coin))
		end
	end
end

-- Handle existing and new players
Players.PlayerAdded:Connect(function(player)
	createLeaderstats(player)
	loadPlayerData(player)
end)

for _, player in Players:GetPlayers() do
	if not player:FindFirstChild("leaderstats") then
		createLeaderstats(player)
	end
	loadPlayerData(player)
end

-- Save data when player leaves
Players.PlayerRemoving:Connect(savePlayerData)

-- Auto-save every 60 seconds
coroutine.wrap(function()
	while true do
		task.wait(60)
		for _, player in Players:GetPlayers() do
			savePlayerData(player)
		end
	end
end)()