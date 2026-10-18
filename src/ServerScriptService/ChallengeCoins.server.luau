-- Challenge coins (docs/GDD.md §5): each coin pays once per player, is saved in PlayerProfile.CollectedCoins and is
-- hidden only for the player who collected it. The server never hides a coin; it mirrors the collected ids to the
-- player attribute CollectedCoins and ChallengeCoinsClient hides them locally. Coins are Studio-only parts tagged
-- ChallengeCoin with the attribute CoinId (ChallengeCoinConfig); the value comes from the config tier.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ChallengeCoinConfig = require(ReplicatedStorage.ChallengeCoinConfig)
local StageConfig = require(ReplicatedStorage.StageConfig)
local PlayerProfile = require(ServerScriptService.PlayerProfile)
local CoinRewards = require(ServerScriptService.CoinRewards)
local PetService = require(ServerScriptService.PetService)
local PetConfig = require(ReplicatedStorage.PetConfig)

-- Max distance (studs) between the character's root and the coin on the server: a body part touching the coin is
-- within ~5 studs; the rest covers replication lag of a fast-falling character. Rejects coins moved on a client.
local MAX_REACH = 15

local coinParts = {} -- [id] = part, to reject duplicates

local function publish(player: Player)
	local profile = PlayerProfile.Get(player)
	if profile then
		player:SetAttribute(ChallengeCoinConfig.CollectedAttribute, ChallengeCoinConfig.Encode(profile.CollectedCoins))
	end
end

local function tryCollect(coin, part: BasePart, otherPart: BasePart)
	local character = otherPart.Parent
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then
		return
	end
	local profile = PlayerProfile.Get(player)
	if not profile or profile.CollectedCoins[coin.id] then
		return -- still loading (the coin stays), or already collected (repeated / queued touches)
	end
	if (root.Position - part.Position).Magnitude > MAX_REACH then
		return
	end

	profile.CollectedCoins[coin.id] = true -- marked before anything yields: a coin pays once
	CoinRewards.Grant(player, coin.value, "challenge")
	PetService.AddXP(player, PetConfig.CoinXp)
	publish(player)
end

-- Key of the stage whose Workspace folder contains `part`, or nil.
local function stageKeyOf(part: Instance): string?
	local ok, stage = pcall(StageConfig.ForInstance, part)
	return ok and stage.key or nil
end

local function setupCoin(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	local id = part:GetAttribute(ChallengeCoinConfig.IdAttribute)
	local coin = ChallengeCoinConfig.ById[id]
	if not coin then
		warn("ChallengeCoins: unknown CoinId " .. tostring(id) .. " on " .. part:GetFullName())
		return
	end
	if stageKeyOf(part) ~= coin.stage then
		warn("ChallengeCoins: " .. id .. " belongs to " .. coin.stage .. " but is placed at " .. part:GetFullName())
		return
	end
	if coinParts[id] then
		warn("ChallengeCoins: duplicate CoinId " .. id .. " on " .. part:GetFullName() .. ", ignored")
		return
	end
	coinParts[id] = part
	part.Touched:Connect(function(otherPart)
		tryCollect(coin, part, otherPart)
	end)
end

for _, part in CollectionService:GetTagged(ChallengeCoinConfig.Tag) do
	setupCoin(part)
end
CollectionService:GetInstanceAddedSignal(ChallengeCoinConfig.Tag):Connect(setupCoin)

local function setupPlayer(player: Player)
	if PlayerProfile.WaitFor(player) then
		publish(player)
	end
end

PlayerProfile.ProfileReset:Connect(publish)

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do
	task.spawn(setupPlayer, player)
end
