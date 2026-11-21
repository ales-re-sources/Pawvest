-- GardenFood: the food stand on the garden plaza (docs/GDD.md §7.4, §7.6; P2b2). Server-only.
-- Food is bought and fed at once to one owned pet (equipped, resting or on the field; no food inventory). The client only names
-- the pet uid and the food id; XP comes from GardenConfig.Foods, the price from GardenConfig.FoodPrice (FD: by the level of the trait
-- the food trains and the pet's rarity). Only the fed pet gains the XP, as care XP (PetConfig.GainCareXp "food": Cuteness first, else
-- the lowest working trait, each up to its food limit); a pet at its food limit is rejected ("maxed": it grows with you now) before
-- any Coins are taken.
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
	local price = GardenConfig.FoodPrice(food, pet)
	if not price then
		return reject(player, "Feed", "maxed")
	end
	if not PlayerProfile.TrySpend(player, price) then
		return reject(player, "Feed", "coins")
	end
	local trained, wasted = PetConfig.GainCareXp(pet, food.xp, "food")
	-- re-publishes the Pets panel, Coin bonus, EquippedPets labels, field pet labels
	GardenService.Done(player, "Feed", {
		uid = uid,
		food = food.id,
		price = price,
		xp = food.xp - wasted,
		level = PetConfig.PetLevel(pet),
		trained = trained, -- { { id, levels, level } } in order (P4)
	})
end)

return {}
