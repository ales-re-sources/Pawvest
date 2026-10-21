-- StageUnlocks: which stages a player may enter through the hub portals (docs/GDD.md §3). Server-only.
-- A stage with an unlock rule is open when the player has the required medal on the previous stage (the bar, derived
-- from PlayerProfile.Medals every time, never stored) or bought it once for Coins (PlayerProfile.UnlockedStages).
-- Times or medals recorded on the locked stage itself do not open it (no grandfathering); admins follow the same rules.
-- The state is mirrored to Unlocked_<folder> player attributes for the portal faces and the unlock popup.
-- Remotes are created here in ReplicatedStorage.UnlockRemotes: Buy (client → server: stageKey; the price is never sent),
-- Result (server → client: stageKey, ok, reason?) and Locked (server → client: stageKey; a locked portal was touched).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local StageConfig = require(ReplicatedStorage.StageConfig)
local PlayerProfile = require(ServerScriptService.PlayerProfile)

local BUY_COOLDOWN = 0.25 -- seconds between requests per player

local remotes = Instance.new("Folder")
remotes.Name = "UnlockRemotes"
local buyEvent = Instance.new("RemoteEvent")
buyEvent.Name = "Buy"
buyEvent.Parent = remotes
local resultEvent = Instance.new("RemoteEvent")
resultEvent.Name = "Result"
resultEvent.Parent = remotes
local lockedEvent = Instance.new("RemoteEvent")
lockedEvent.Name = "Locked"
lockedEvent.Parent = remotes
remotes.Parent = ReplicatedStorage

local lastBuy = {} -- [Player] = os.clock() of the last request

local StageUnlocks = {}

local function isOpen(profile, stage): boolean
	return StageConfig.MeetsUnlockBar(stage, profile.Medals) or profile.UnlockedStages[stage.key] == true
end

-- True if the player may enter `stage`, false if it is locked, nil while the profile is still loading.
function StageUnlocks.IsUnlocked(player: Player, stage): boolean?
	if not stage.unlock then
		return true
	end
	local profile = PlayerProfile.Get(player)
	if not profile then
		return nil
	end
	return isOpen(profile, stage)
end

-- Opens the unlock popup on the player's client.
function StageUnlocks.ShowLocked(player: Player, stage)
	lockedEvent:FireClient(player, stage.key)
end

local function publish(player: Player)
	local profile = PlayerProfile.Get(player)
	if not profile then
		return
	end
	for _, stage in StageConfig.Stages do
		player:SetAttribute(StageConfig.UnlockedAttribute(stage), isOpen(profile, stage))
	end
end

local function setupPlayer(player: Player)
	-- the bar depends on the previous stage's medal: re-check whenever StageResults publishes a new one
	for _, stage in StageConfig.Stages do
		local rule = stage.unlock
		if rule then
			for _, watched in StageConfig.Stages do
				if watched.key == rule.stage or watched.world == rule.world then
					player:GetAttributeChangedSignal(StageConfig.MedalAttribute(watched)):Connect(function()
						publish(player)
					end)
				end
			end
		end
	end
	if PlayerProfile.WaitFor(player) then
		publish(player)
	end
end

local function reject(player: Player, stageKey: string, reason: string)
	resultEvent:FireClient(player, stageKey, false, reason)
end

buyEvent.OnServerEvent:Connect(function(player, stageKey)
	if type(stageKey) ~= "string" then
		return
	end
	local stage = StageConfig.ByKey[stageKey]
	if not (stage and stage.unlock and stage.unlockPrice) then
		return
	end

	local now = os.clock()
	if lastBuy[player] and now - lastBuy[player] < BUY_COOLDOWN then
		return
	end
	lastBuy[player] = now

	local profile = PlayerProfile.Get(player)
	if not profile then
		return reject(player, stageKey, "loading")
	end
	if isOpen(profile, stage) then
		return reject(player, stageKey, "owned") -- bought before or the bar is met: never charged twice
	end
	local price = stage.unlockPrice
	if profile.Coins < price then
		return reject(player, stageKey, "coins")
	end

	PlayerProfile.AddCoins(player, -price)
	profile.UnlockedStages[stageKey] = true
	publish(player)
	resultEvent:FireClient(player, stageKey, true)
	task.spawn(PlayerProfile.Save, player) -- spent Coins and the unlock are saved together
end)

PlayerProfile.ProfileReset:Connect(publish)

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do
	task.spawn(setupPlayer, player)
end

Players.PlayerRemoving:Connect(function(player)
	lastBuy[player] = nil
end)

return StageUnlocks
