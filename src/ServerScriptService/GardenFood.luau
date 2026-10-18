-- GardenFood: the food stand on the garden plaza (docs/GDD.md §7.4, §7.6; P2b2). Server-only.
-- Food is bought and fed at once to one owned pet (equipped, penned or resting; no food inventory). The client only names
-- the pet uid and the food id; price and XP come from GardenConfig.Foods. Only the fed pet gains the XP (PetConfig.GainXp,
-- level-ups keep the remainder); a level-20 pet is rejected before any Coins are taken. A penned pet's production is
-- settled first, so the new level only counts from the feeding on.
-- Remote (in GardenRemotes): Feed(uid, foodId) (client → server); answers through GardenRemotes.Result ("Feed").

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GardenConfig = require(ReplicatedStorage.GardenConfig)
local PetConfig = require(ReplicatedStorage.PetConfig)
local PlayerProfile = require(ServerScriptService.PlayerProfile)
local GardenService = require(ServerScriptService.GardenService)

local feedEvent = GardenService.Remote("Feed") -- client → server: (uid: string, foodId: string)

local reject = GardenService.Reject

-- True when the player's character stands within FoodStandDistance of Workspace.Garden.FoodStand.
local function nearStand(player: Player): boolean
	local garden = workspace:FindFirstChild("Garden")
	local stand = garden and garden:FindFirstChild(GardenConfig.FoodStandName)
	local anchor = stand and stand:IsA("Model") and stand.PrimaryPart
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return anchor ~= nil
		and root ~= nil
		and (root.Position - anchor.Position).Magnitude <= GardenConfig.FoodStandDistance
end

feedEvent.OnServerEvent:Connect(function(player, uid, foodId)
	if type(uid) ~= "string" or type(foodId) ~= "string" or not GardenService.Allow(player) then
		return
	end
	local food = GardenConfig.FoodById[foodId]
	if not food then
		return
	end
	local profile = PlayerProfile.Get(player)
	if not profile then
		return reject(player, "Feed", "loading")
	end
	local pet = profile.Pets[uid]
	if not pet then
		return
	end
	if not nearStand(player) then
		return reject(player, "Feed", "far")
	end
	if PetConfig.ClampLevel(pet.Level) >= PetConfig.MaxLevel then
		return reject(player, "Feed", "maxed")
	end
	if profile.Coins < food.price then
		return reject(player, "Feed", "coins")
	end

	if GardenConfig.IsPenned(profile, uid) then
		GardenService.SettleAndNotify(player) -- production up to now is paid at the old level
	end
	PlayerProfile.AddCoins(player, -food.price)
	local levels = PetConfig.GainXp(pet, food.xp)
	GardenService.PublishAll(player) -- Pets panel, Coin bonus, EquippedPets labels, pen label and garden rate
	GardenService.Succeed(player, "Feed", {
		uid = uid,
		food = food.id,
		xp = food.xp,
		level = pet.Level,
		levels = levels,
	})
	task.spawn(PlayerProfile.Save, player)
end)

return {}
