-- PetService: pet inventory, eggs, equip slots and the pet Coin multiplier (docs/GDD.md §7.1–7.3). Server-only.
-- The client only names what it wants (egg id, pet uid, expected slot); prices, rolls and sell values come from
-- PetConfig, so a forged request can never change what is charged, hatched or paid. State lives in PlayerProfile
-- (Pets, EquippedPets, PetSlots, NextPetUid, FreeEggs, LaunchEgg).
-- Remotes are created here in ReplicatedStorage.PetRemotes: BuyEgg(eggId), Equip(uid), Unequip(uid),
-- BuySlot(expectedSlot), SellPet(uid), RequestState() (client → server); PetsChanged(state) and
-- Result(action, ok, detailOrReason) (server → client). The equipped pets are mirrored to the EquippedPets player
-- attribute ("Kind:Level,…"). AddXP levels the equipped pets (stage finishes, coins, movement during a run). AddPet is the
-- shared "new pet" step of every egg (stand eggs here, garden incubators in GardenIncubators).
-- A pet is either equipped or in a garden pen (P2a2), never both: Equip and SellPet reject a penned pet, and the garden
-- (GardenService) rejects an equipped one; PetsChanged.penned maps each penned uid to its pen index.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PetConfig = require(ReplicatedStorage.PetConfig)
local GardenConfig = require(ReplicatedStorage.GardenConfig)
local PlayerProfile = require(ServerScriptService.PlayerProfile)

local COOLDOWN = 0.2 -- seconds between pet requests per player
local LAUNCH_EGG = "Basic" -- free egg every player gets once when pets launch (GDD §7.2)

local remotes = Instance.new("Folder")
remotes.Name = "PetRemotes"
local function remote(name: string): RemoteEvent
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = remotes
	return event
end
local buyEggEvent = remote("BuyEgg") -- client → server: (eggId: string)
local equipEvent = remote("Equip") -- client → server: (uid: string)
local unequipEvent = remote("Unequip") -- client → server: (uid: string)
local buySlotEvent = remote("BuySlot") -- client → server: (expectedSlot: number)
local sellEvent = remote("SellPet") -- client → server: (uid: string)
local requestStateEvent = remote("RequestState") -- client → server, no arguments: resend the state (join publish may be missed)
local changedEvent = remote("PetsChanged") -- server → client: (state)
local resultEvent = remote("Result") -- server → client: (action, ok: boolean, detailOrReason)
remotes.Parent = ReplicatedStorage

local rng = Random.new()
local lastRequest = {} -- [Player] = os.clock() of the last accepted request

local PetService = {}

local function equippedPets(profile)
	local pets = {}
	for _, uid in profile.EquippedPets do
		table.insert(pets, profile.Pets[uid])
	end
	return pets
end

local function isEquipped(profile, uid: string): boolean
	return table.find(profile.EquippedPets, uid) ~= nil
end

local function petCount(profile): number
	local count = 0
	for _ in profile.Pets do
		count += 1
	end
	return count
end
PetService.PetCount = petCount

-- Coin multiplier from the player's equipped pets (1 while the profile is not loaded).
function PetService.Multiplier(player: Player): number
	local profile = PlayerProfile.Get(player)
	if not profile then
		return 1
	end
	return PetConfig.Multiplier(equippedPets(profile))
end

-- Sends the pet state to the client and refreshes the EquippedPets attribute.
local function publish(player: Player)
	local profile = PlayerProfile.Get(player)
	if not profile then
		return
	end
	local penned = {} -- [uid] = pen index
	local pens = profile.Garden and profile.Garden.Pens
	if type(pens) == "table" then
		for key, uid in pens do
			if type(uid) == "string" and tonumber(key) then
				penned[uid] = tonumber(key)
			end
		end
	end
	local parts = {}
	for _, pet in equippedPets(profile) do
		table.insert(parts, pet.Kind .. ":" .. PetConfig.ClampLevel(pet.Level))
	end
	player:SetAttribute(PetConfig.AttributeName, table.concat(parts, ","))
	changedEvent:FireClient(player, {
		pets = profile.Pets,
		equipped = profile.EquippedPets,
		slots = profile.PetSlots,
		freeEggs = profile.FreeEggs,
		multiplier = PetConfig.Multiplier(equippedPets(profile)),
		penned = penned,
	})
end

-- Re-sends the state after another system (the garden) changed which pets are penned.
PetService.Publish = publish

-- Adds a free egg waiting to be opened at the egg stand (first Gold, launch egg). False if the profile is not loaded.
function PetService.GrantFreeEgg(player: Player, eggId: string): boolean
	local profile = PlayerProfile.Get(player)
	if not (profile and PetConfig.Eggs[eggId]) then
		return false
	end
	profile.FreeEggs[eggId] = (profile.FreeEggs[eggId] or 0) + 1
	publish(player)
	return true
end

-- Adds a new level-1 pet of `kind` to the inventory and equips it when a slot is free (GDD §7.3). The caller checks the
-- inventory cap first, publishes and saves. Returns uid, equipped; nil while the profile is not loaded or for a bad kind.
function PetService.AddPet(player: Player, kind: string): (string?, boolean?)
	local profile = PlayerProfile.Get(player)
	if not (profile and PetConfig.Kinds[kind]) then
		return nil, nil
	end
	local uid = tostring(profile.NextPetUid)
	profile.NextPetUid += 1
	profile.Pets[uid] = { Kind = kind, Level = 1, XP = 0 }
	local equipped = #profile.EquippedPets < profile.PetSlots
	if equipped then
		table.insert(profile.EquippedPets, uid)
	end
	return uid, equipped
end

-- Gives `amount` XP to every equipped pet (GDD §7.4: each gets the full amount; level-ups keep the remainder, a
-- level-20 pet gains nothing). Saved by the autosave and on leave. Returns how many pets gained XP (0 while the
-- profile is not loaded or nothing is equipped).
function PetService.AddXP(player: Player, amount: number): number
	local profile = PlayerProfile.Get(player)
	if not profile or type(amount) ~= "number" or amount < 1 then
		return 0
	end
	amount = math.floor(amount)
	local gaining = 0
	for _, pet in equippedPets(profile) do
		if PetConfig.GainXp(pet, amount) then
			gaining += 1
		end
	end
	if gaining > 0 then
		publish(player) -- levels feed the Coin bonus, the EquippedPets labels and the Pets panel
	end
	return gaining
end

-- Drops equipped uids that no longer exist or exceed the slots (corrupt or hand-edited records).
local function sanitize(profile)
	local kept = {}
	for _, uid in profile.EquippedPets do
		if
			type(uid) == "string"
			and profile.Pets[uid]
			and not table.find(kept, uid)
			and not GardenConfig.IsPenned(profile, uid) -- equipped and penned never both (hand-edited records)
			and #kept < profile.PetSlots
		then
			table.insert(kept, uid)
		end
	end
	profile.EquippedPets = kept
end

-- Join and admin reset: grants the launch egg once and publishes the state.
local function setup(player: Player)
	local profile = PlayerProfile.WaitFor(player)
	if not profile then
		return
	end
	sanitize(profile)
	if not profile.LaunchEgg then
		profile.LaunchEgg = true
		profile.FreeEggs[LAUNCH_EGG] = (profile.FreeEggs[LAUNCH_EGG] or 0) + 1
		task.spawn(PlayerProfile.Save, player)
	end
	publish(player)
end

-- Per-player rate limit shared by all pet remotes; true if the request may proceed.
local function allow(player: Player): boolean
	local now = os.clock()
	if lastRequest[player] and now - lastRequest[player] < COOLDOWN then
		return false
	end
	lastRequest[player] = now
	return true
end

local function reject(player: Player, action: string, reason: string)
	resultEvent:FireClient(player, action, false, reason)
end

local function succeed(player: Player, action: string, detail: any)
	publish(player)
	resultEvent:FireClient(player, action, true, detail)
end

buyEggEvent.OnServerEvent:Connect(function(player, eggId)
	if type(eggId) ~= "string" then
		return
	end
	local egg = PetConfig.Eggs[eggId]
	if not (egg and egg.stand) or not allow(player) then
		return
	end
	local profile = PlayerProfile.Get(player)
	if not profile then
		return reject(player, "BuyEgg", "loading")
	end
	if petCount(profile) >= PetConfig.MaxPets then
		return reject(player, "BuyEgg", "full")
	end
	local free = (profile.FreeEggs[eggId] or 0) > 0
	if not free and profile.Coins < egg.price then
		return reject(player, "BuyEgg", "coins")
	end

	local kind = PetConfig.Roll(eggId, rng)
	if free then
		profile.FreeEggs[eggId] -= 1
		if profile.FreeEggs[eggId] == 0 then
			profile.FreeEggs[eggId] = nil
		end
	else
		PlayerProfile.AddCoins(player, -egg.price)
	end
	local uid, equipped = PetService.AddPet(player, kind) -- a new pet takes a free slot at once (GDD §7.3)
	succeed(player, "BuyEgg", { uid = uid, kind = kind, free = free, equipped = equipped })
	task.spawn(PlayerProfile.Save, player) -- spent Coins (or the free egg) and the pet are saved together
end)

requestStateEvent.OnServerEvent:Connect(function(player)
	if allow(player) then
		publish(player) -- does nothing while the profile is loading: setup publishes once it is
	end
end)

equipEvent.OnServerEvent:Connect(function(player, uid)
	if type(uid) ~= "string" or not allow(player) then
		return
	end
	local profile = PlayerProfile.Get(player)
	if not (profile and profile.Pets[uid]) then
		return
	end
	if isEquipped(profile, uid) then
		return reject(player, "Equip", "equipped")
	end
	if GardenConfig.IsPenned(profile, uid) then
		return reject(player, "Equip", "penned")
	end
	if #profile.EquippedPets >= profile.PetSlots then
		return reject(player, "Equip", "slots")
	end
	table.insert(profile.EquippedPets, uid)
	succeed(player, "Equip", uid)
end)

unequipEvent.OnServerEvent:Connect(function(player, uid)
	if type(uid) ~= "string" or not allow(player) then
		return
	end
	local profile = PlayerProfile.Get(player)
	local index = profile and table.find(profile.EquippedPets, uid)
	if not index then
		return
	end
	table.remove(profile.EquippedPets, index)
	succeed(player, "Unequip", uid)
end)

buySlotEvent.OnServerEvent:Connect(function(player, expectedSlot)
	if type(expectedSlot) ~= "number" or not allow(player) then
		return
	end
	local profile = PlayerProfile.Get(player)
	if not profile then
		return reject(player, "BuySlot", "loading")
	end
	if profile.PetSlots >= #PetConfig.SlotPrices then
		return reject(player, "BuySlot", "maxed")
	end
	if expectedSlot ~= profile.PetSlots + 1 then
		return reject(player, "BuySlot", "stale") -- out-of-date panel, double click or forged request
	end
	local price = PetConfig.SlotPrices[expectedSlot]
	if profile.Coins < price then
		return reject(player, "BuySlot", "coins")
	end

	PlayerProfile.AddCoins(player, -price)
	profile.PetSlots = expectedSlot
	succeed(player, "BuySlot", expectedSlot)
	task.spawn(PlayerProfile.Save, player)
end)

sellEvent.OnServerEvent:Connect(function(player, uid)
	if type(uid) ~= "string" or not allow(player) then
		return
	end
	local profile = PlayerProfile.Get(player)
	local pet = profile and profile.Pets[uid]
	if not pet then
		return
	end
	if isEquipped(profile, uid) then
		return reject(player, "SellPet", "equipped")
	end
	if GardenConfig.IsPenned(profile, uid) then
		return reject(player, "SellPet", "penned")
	end

	local value = PetConfig.SellValue(pet.Kind)
	profile.Pets[uid] = nil
	PlayerProfile.AddCoins(player, value) -- a sale is not a gameplay reward: no pet multiplier
	succeed(player, "SellPet", { uid = uid, coins = value })
	task.spawn(PlayerProfile.Save, player)
end)

PlayerProfile.ProfileReset:Connect(setup)

Players.PlayerAdded:Connect(setup)
for _, player in Players:GetPlayers() do
	task.spawn(setup, player)
end

Players.PlayerRemoving:Connect(function(player)
	lastRequest[player] = nil
end)

return PetService
