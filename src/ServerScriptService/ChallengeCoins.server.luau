-- Challenge coins (docs/GDD.md §5): each coin pays once per player, is saved in PlayerProfile.CollectedCoins and is
-- hidden only for the player who collected it. The server never hides a coin; it mirrors the collected ids to the
-- player attribute CollectedCoins and ChallengeCoinsClient hides them locally. Coins are Studio-only parts tagged
-- ChallengeCoin with the attribute CoinId (ChallengeCoinConfig); the value comes from the config tier.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ChallengeCoinConfig = require(ReplicatedStorage.ChallengeCoinConfig)
local StageConfig = require(ReplicatedStorage.StageConfig)
local PlayerProfile = require(ServerScriptService.PlayerProfile)
local CoinRewards = require(ServerScriptService.CoinRewards)
local PetService = require(ServerScriptService.PetService)
local PetConfig = require(ReplicatedStorage.PetConfig)
local CharacterUtil = require(ServerScriptService.CharacterUtil)

local coinParts = {} -- [id] = part, to reject duplicates

local function publish(player: Player)
	local profile = PlayerProfile.Get(player)
	if profile then
		player:SetAttribute(ChallengeCoinConfig.CollectedAttribute, ChallengeCoinConfig.Encode(profile.CollectedCoins))
	end
end

local function tryCollect(coin, part: BasePart, otherPart: BasePart)
	local player, _, root = CharacterUtil.FromHit(otherPart)
	if not player or not root then
		return
	end
	local profile = PlayerProfile.Get(player)
	if not profile or profile.CollectedCoins[coin.id] then
		return -- still loading (the coin stays), or already collected (repeated / queued touches)
	end
	if not CharacterUtil.Reaches(root, part) then
		return
	end

	profile.CollectedCoins[coin.id] = true -- marked before anything yields: a coin pays once
	CoinRewards.Grant(player, coin.value, "challenge")
	PetService.AddXP(player, PetConfig.CoinXp)
	publish(player)
end

-- Key of the stage whose Workspace folder contains `part`, or nil.
local function stageKeyOf(part: Instance): string?
	local stage = StageConfig.TryForInstance(part)
	return stage and stage.key
end

local function setupCoin(part: Instance)
	if not part:IsA("BasePart") or not part:IsDescendantOf(workspace) then
		return -- tagged parts in ServerStorage (backups, kits) are not live coins
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

PlayerProfile.OnReady(publish) -- join and admin reset
