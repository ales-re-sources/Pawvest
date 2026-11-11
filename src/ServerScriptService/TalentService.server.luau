-- TalentService: permanent talents bought with Coins and a crop bundle from the barn (GDD §6; bundles since EV2b). Server-owned.
-- The client only sends (talentId, expectedLevel); the price and bundle come from TalentConfig and the new level is always
-- current + 1, so a forged cost or level can never change what is charged or granted. Levels live in
-- PlayerProfile.Talents, are mirrored to Talent_<id> player attributes (UI, double jump) and applied to the
-- Humanoid (WalkSpeed, jump) on every spawn and right after a purchase.
-- World rewards (K1, GDD §6): a level in `talent.rewards` is never sold; it is granted here once the world it names opens
-- for the player (StageUnlocks.Changed, also right after the profile loads) and announced on TalentRemotes.Granted.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GardenField = require(ServerScriptService.GardenField)
local PlayerProfile = require(ServerScriptService.PlayerProfile)
local StageUnlocks = require(ServerScriptService.StageUnlocks)
local Telemetry = require(ServerScriptService.Telemetry)
local StageConfig = require(ReplicatedStorage.StageConfig)
local TalentConfig = require(ReplicatedStorage.TalentConfig)
local Num = require(ReplicatedStorage.Num)
local Remotes = require(ServerScriptService.Remotes)
local RateLimit = require(ServerScriptService.RateLimit)

-- Buy: client → server (talentId: string, expectedLevel: number); Result: server → client (talentId, ok, levelOrReason);
-- Granted: server → client (talentId, level) a world reward was granted
local _, remotes = Remotes.Folder("TalentRemotes", { "Buy", "Result", "Granted" })
local buyEvent, grantedEvent = remotes.Buy, remotes.Granted
local reject, succeed = Remotes.Results(remotes.Result)
local allow = RateLimit.new(0.25) -- seconds between requests per player

local bases = setmetatable({}, { __mode = "k" }) -- [Humanoid] = values before talents

local levelOf = TalentConfig.LevelOf

local function publish(player: Player, profile)
	for _, talent in TalentConfig.List do
		player:SetAttribute(TalentConfig.AttributeName(talent.id), levelOf(profile, talent.id))
	end
end

-- Idempotent: always computed from the humanoid's values at spawn, never from its current ones.
local function apply(player: Player, profile)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local base = bases[humanoid]
	if not base then
		base = { walkSpeed = humanoid.WalkSpeed, jumpPower = humanoid.JumpPower, jumpHeight = humanoid.JumpHeight }
		bases[humanoid] = base
	end

	humanoid.WalkSpeed = base.walkSpeed * TalentConfig.WalkSpeedFactor(levelOf(profile, "RunSpeed"))
	local jumpFactor = TalentConfig.JumpHeightFactor(levelOf(profile, "JumpHeight"))
	if humanoid.UseJumpPower then
		humanoid.JumpPower = base.jumpPower * math.sqrt(jumpFactor) -- height grows with the square of the power
	else
		humanoid.JumpHeight = base.jumpHeight * jumpFactor
	end
end

local function onCharacterAdded(player: Player, character: Model)
	if not character:WaitForChild("Humanoid", 10) then
		return
	end
	local profile = PlayerProfile.WaitFor(player)
	if profile and player.Character == character then
		apply(player, profile)
	end
end

-- Grants every world-reward level whose world is open for the player (idempotent; a reset profile has no open world).
local function grantRewards(player: Player)
	local profile = PlayerProfile.Get(player)
	if not profile then
		return
	end
	local granted = {}
	for _, talent in TalentConfig.List do
		for level, worldIndex in talent.rewards or {} do
			local world = StageConfig.Worlds[worldIndex]
			if levelOf(profile, talent.id) < level and world and StageUnlocks.IsWorldOpen(player, world) then
				profile.Talents[talent.id] = level
				table.insert(granted, { id = talent.id, level = level })
			end
		end
	end
	if #granted == 0 then
		return
	end
	publish(player, profile)
	apply(player, profile)
	for _, grant in granted do
		grantedEvent:FireClient(player, grant.id, grant.level)
		Telemetry.TalentGranted(player, grant.id, grant.level)
	end
	task.spawn(PlayerProfile.Save, player)
end

local function watchCharacter(player: Player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
end

buyEvent.OnServerEvent:Connect(function(player, id, expectedLevel)
	if type(id) ~= "string" or not Num.Whole(expectedLevel) then
		return
	end
	local talent = TalentConfig.ById[id]
	if not talent then
		return
	end
	if not allow(player) then
		return
	end

	local profile = PlayerProfile.Get(player)
	if not profile then
		return reject(player, id, "loading")
	end
	local current = levelOf(profile, id)
	if current >= #talent.costs then
		return reject(player, id, "maxed")
	end
	if expectedLevel ~= current + 1 then
		return reject(player, id, "stale") -- the panel was out of date (double click, lag) or the request forged
	end
	if TalentConfig.RewardWorld(id, current + 1) then
		return reject(player, id, "reward") -- comes with a world, never sold
	end
	local cost = talent.costs[current + 1]
	if profile.Coins < cost then
		return reject(player, id, "coins")
	end
	local bundle = TalentConfig.NextCrops(id, current)
	if not GardenField.HasCrops(player, bundle) then
		return reject(player, id, "crops")
	end

	-- no yield since the checks: the Coins and the crops go together, or neither
	PlayerProfile.AddCoins(player, -cost)
	GardenField.TakeCrops(player, bundle)
	profile.Talents[id] = current + 1
	publish(player, profile)
	apply(player, profile)
	succeed(player, id, current + 1)
	Telemetry.TalentBought(player, id, current + 1, cost, profile.Coins) -- the bundle follows from id + level
	task.spawn(PlayerProfile.Save, player) -- spent Coins, crops and the level are saved together
end)

StageUnlocks.Changed:Connect(grantRewards)

Players.PlayerAdded:Connect(watchCharacter)
for _, player in Players:GetPlayers() do
	watchCharacter(player)
end
-- join and admin reset (a reset profile has no open world, so grantRewards grants nothing then)
PlayerProfile.OnReady(function(player, profile)
	publish(player, profile)
	apply(player, profile)
	grantRewards(player)
end)
