-- RespawnService: the only place that loads characters (docs/STAGES.md §6.2.1). Players.CharacterAutoLoads is turned off
-- here: the join spawn and every respawn after a death go through LoadCharacter, which makes the Quick Respawn talent
-- possible. Delay after a death: the place's Players.RespawnTime without the talent, 1 s at level 1, none at level 2
-- (TalentConfig.RespawnDelay). The stage timer is not touched: the talent only removes the waiting. The Home button
-- moves the live character (HomeService) and needs nothing from here; the respawn point itself is placed by
-- CheckpointTouchHandler on CharacterAdded.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TalentConfig = require(ReplicatedStorage.TalentConfig)

local TALENT = "QuickRespawn"

local defaultDelay = Players.RespawnTime -- read before anything can change it; 3 s in this place
Players.CharacterAutoLoads = false

local waiting = {} -- [Player] = true while a respawn is scheduled (a character that dies twice is loaded once)

local function load(player: Player)
	waiting[player] = nil
	if player.Parent == Players then
		player:LoadCharacter()
	end
end

local function scheduleRespawn(player: Player)
	if waiting[player] then
		return
	end
	waiting[player] = true
	local level = TalentConfig.ClampLevel(TALENT, player:GetAttribute(TalentConfig.AttributeName(TALENT)))
	task.delay(TalentConfig.RespawnDelay(level, defaultDelay), load, player)
end

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end
	humanoid.Died:Once(function()
		if player.Character == character then
			scheduleRespawn(player)
		end
	end)
end

local function setupPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	else
		load(player) -- the join spawn
	end
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do
	task.spawn(setupPlayer, player)
end

Players.PlayerRemoving:Connect(function(player)
	waiting[player] = nil
end)
