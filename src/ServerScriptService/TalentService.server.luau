-- TalentService: Coin-priced permanent talents (GDD §6). Server-owned.
-- The client only sends (talentId, expectedLevel); the price comes from TalentConfig and the new level is always
-- current + 1, so a forged cost or level can never change what is charged or granted. Levels live in
-- PlayerProfile.Talents, are mirrored to Talent_<id> player attributes (UI, double jump) and applied to the
-- Humanoid (WalkSpeed, jump) on every spawn and right after a purchase.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerProfile = require(ServerScriptService.PlayerProfile)
local TalentConfig = require(ReplicatedStorage.TalentConfig)

local BUY_COOLDOWN = 0.25 -- seconds between requests per player

local remotes = Instance.new("Folder")
remotes.Name = "TalentRemotes"
local buyEvent = Instance.new("RemoteEvent") -- client → server: (talentId: string, expectedLevel: number)
buyEvent.Name = "Buy"
buyEvent.Parent = remotes
local resultEvent = Instance.new("RemoteEvent") -- server → client: (talentId, ok: boolean, levelOrReason)
resultEvent.Name = "Result"
resultEvent.Parent = remotes
remotes.Parent = ReplicatedStorage

local lastBuy = {} -- [Player] = os.clock() of the last request
local bases = setmetatable({}, { __mode = "k" }) -- [Humanoid] = values before talents

local function levelOf(profile, id: string): number
	return TalentConfig.ClampLevel(id, profile.Talents[id])
end

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

local function setupPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
	local profile = PlayerProfile.WaitFor(player)
	if profile then
		publish(player, profile)
		apply(player, profile)
	end
end

local function reject(player: Player, id: string, reason: string)
	resultEvent:FireClient(player, id, false, reason)
end

buyEvent.OnServerEvent:Connect(function(player, id, expectedLevel)
	if type(id) ~= "string" or type(expectedLevel) ~= "number" then
		return
	end
	local talent = TalentConfig.ById[id]
	if not talent then
		return
	end

	local now = os.clock()
	if lastBuy[player] and now - lastBuy[player] < BUY_COOLDOWN then
		return
	end
	lastBuy[player] = now

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
	local cost = talent.costs[current + 1]
	if profile.Coins < cost then
		return reject(player, id, "coins")
	end

	PlayerProfile.AddCoins(player, -cost)
	profile.Talents[id] = current + 1
	publish(player, profile)
	apply(player, profile)
	resultEvent:FireClient(player, id, true, current + 1)
	task.spawn(PlayerProfile.Save, player) -- spent Coins and the level are saved together
end)

PlayerProfile.ProfileReset:Connect(function(player)
	local profile = PlayerProfile.Get(player)
	if profile then
		publish(player, profile)
		apply(player, profile)
	end
end)

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do
	task.spawn(setupPlayer, player)
end

Players.PlayerRemoving:Connect(function(player)
	lastBuy[player] = nil
end)
