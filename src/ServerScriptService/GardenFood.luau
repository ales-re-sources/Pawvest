-- GardenFood: the food stand on the garden plaza (docs/GDD.md §7.4, §7.6; P2b2). Server-only.
-- Food is bought and fed at once to one owned pet (equipped, resting or on the field; no food inventory). The client only names
-- the pet uid and the food id; price and XP come from GardenConfig.Foods. Only the fed pet gains the XP, as care XP
-- (PetConfig.GainCareXp, P4: Cuteness first, else the lowest working trait below the care cap); a pet with nothing left to train
-- is rejected ("maxed") before any Coins are taken.
-- Remote (in GardenRemotes): Feed(uid, foodId) (client → server); answers through GardenRemotes.Result ("Feed").

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GardenConfig = require(ReplicatedStorage.GardenConfig)
local PetConfig = require(ReplicatedStorage.PetConfig)
local PlayerProfile = require(ServerScriptService.PlayerProfile)
local GardenService = require(ServerScriptService.GardenService)

local feedEvent = GardenService.Remote("Feed") -- client → server: (uid: string, foodId: string)

local reject = GardenService.Reject

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
	if not GardenService.NearModel(player, GardenConfig.FoodStandName, GardenConfig.FoodStandDistance) then
		return reject(player, "Feed", "far")
	end
	if not PetConfig.CareTarget(pet) then
		return reject(player, "Feed", "maxed")
	end
	if not PlayerProfile.TrySpend(player, food.price) then
		return reject(player, "Feed", "coins")
	end
	local trained, wasted = PetConfig.GainCareXp(pet, food.xp)
	-- re-publishes the Pets panel, Coin bonus, EquippedPets labels, field pet labels
	GardenService.Done(player, "Feed", {
		uid = uid,
		food = food.id,
		xp = food.xp - wasted,
		level = PetConfig.PetLevel(pet),
		trained = trained, -- { { id, levels, level } } in order (P4)
	})
end)

return {}
