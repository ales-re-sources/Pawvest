-- PetService: pet inventory, free eggs, equip slots and the pet Coin multiplier (docs/GDD.md §7.1–7.3). Server-only.
-- Eggs are hatched only in the garden incubators (GardenIncubators). The client only names what it wants (pet uid,
-- expected slot); prices and sell values come from PetConfig, so a forged request can never change what is charged or
-- paid. State lives in PlayerProfile
-- (Pets, EquippedPets, PetSlots, NextPetUid, FreeEggs, LaunchEgg).
-- Remotes are created here in ReplicatedStorage.PetRemotes: Equip(uid), Unequip(uid),
-- BuySlot(expectedSlot), SellPet(uid), RequestState() (client → server); PetsChanged(state) and
-- Result(action, ok, detailOrReason) (server → client). The equipped pets are mirrored to the EquippedPets player
-- attribute ("Kind:Level:uid,…", level = PetConfig.PetLevel). AddXP gives care XP to the equipped pets (stage finishes, coins,
-- movement during a run; P4: PetConfig.GainCareXp, Cuteness first, else the lowest working trait). AddPet is the
-- "new pet" step of every hatched egg; free eggs wait in FreeEggs until GardenIncubators places them (FreeEggsChanged).
-- A pet is either equipped, in a garden pen (P2a2) or on a field square (E1b), never two of them: Equip and SellPet reject a
-- penned or field pet, and the garden (GardenService / GardenField) rejects an equipped one; PetsChanged.penned maps each penned
-- uid to its pen index, PetsChanged.field each field pet's uid to its square. Every pet has aptitudes (Apt, Spec; PetConfig):
-- rolled at hatch (AddPet); pets from before P4 got Cuteness once in the profile migration (PlayerProfile, Version 4).
-- Names (P3b): Rename(uid, text) stores the cleaned raw text as Pets[uid].Name; the server filters it (TextService, broadcast) at the
-- rename and again on every join and keeps only the filtered text for display: PetsChanged carries the filtered name, never the raw
-- one, and the player attribute PetConfig.NamesAttribute holds { [uid] = filtered } of the equipped, penned and field pets (PetFollow,
-- GardenView). A failed filter call shows no name. The first name is free, later ones cost PetConfig.RenamePrice.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

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
local equipEvent = remote("Equip") -- client → server: (uid: string)
local unequipEvent = remote("Unequip") -- client → server: (uid: string)
local buySlotEvent = remote("BuySlot") -- client → server: (expectedSlot: number)
local sellEvent = remote("SellPet") -- client → server: (uid: string)
local renameEvent = remote("Rename") -- client → server: (uid: string, text: string); "" clears the name
local requestStateEvent = remote("RequestState") -- client → server, no arguments: resend the state (join publish may be missed)
local changedEvent = remote("PetsChanged") -- server → client: (state)
local resultEvent = remote("Result") -- server → client: (action, ok: boolean, detailOrReason)
remotes.Parent = ReplicatedStorage

local lastRequest = {} -- [Player] = os.clock() of the last accepted request
local lastRename = {} -- [Player] = os.clock() of the last rename that reached the filter
local filtered = {} -- [Player] = { [uid] = filtered name } (P3b; never the raw text)

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
	local field = {} -- [uid] = square (E1b)
	local fieldPets = profile.Garden and profile.Garden.FieldPets
	if type(fieldPets) == "table" then
		for uid, entry in fieldPets do
			if type(entry) == "table" and type(entry.Square) == "number" then
				field[uid] = entry.Square
			end
		end
	end
	local equipped = {}
	for _, uid in profile.EquippedPets do
		local pet = profile.Pets[uid]
		table.insert(equipped, { Kind = pet.Kind, Level = PetConfig.PetLevel(pet), uid = uid })
	end
	player:SetAttribute(PetConfig.AttributeName, PetConfig.EncodeEquipped(equipped))
	-- names (P3b): the client gets the filtered name in place of the stored one; others see those of the pets they can see
	local names = filtered[player] or {}
	local pets, shown, anyShown = {}, {}, false
	for uid, pet in profile.Pets do
		local copy = table.clone(pet)
		copy.Name = names[uid]
		pets[uid] = copy
		if names[uid] and (isEquipped(profile, uid) or penned[uid] or field[uid]) then
			shown[uid] = names[uid]
			anyShown = true
		end
	end
	player:SetAttribute(PetConfig.NamesAttribute, if anyShown then HttpService:JSONEncode(shown) else "")
	changedEvent:FireClient(player, {
		pets = pets,
		equipped = profile.EquippedPets,
		slots = profile.PetSlots,
		freeEggs = profile.FreeEggs,
		multiplier = PetConfig.Multiplier(equippedPets(profile)),
		penned = penned,
		field = field,
	})
end

-- Re-sends the state after another system (the garden) changed which pets are penned.
PetService.Publish = publish

-- Fires (player) when a free egg was added to FreeEggs; GardenIncubators moves waiting free eggs into empty incubators.
local freeEggsChanged = Instance.new("BindableEvent")
PetService.FreeEggsChanged = freeEggsChanged.Event

-- Adds a free egg (first Gold, launch egg); it waits in FreeEggs until an incubator is empty (GardenIncubators places
-- it). False if the profile is not loaded.
function PetService.GrantFreeEgg(player: Player, eggId: string): boolean
	local profile = PlayerProfile.Get(player)
	if not (profile and PetConfig.Eggs[eggId]) then
		return false
	end
	profile.FreeEggs[eggId] = (profile.FreeEggs[eggId] or 0) + 1
	publish(player)
	freeEggsChanged:Fire(player)
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
	-- E1b decision 3: a hatch while the owner has no Tending pet always gets Tending (P4: only with field access, where it works)
	local hasTender = not GardenConfig.HasFieldAccess(player.UserId)
	for _, pet in profile.Pets do
		hasTender = hasTender or PetConfig.AptitudeLevel(pet, "Tending") > 0
	end
	local apt, spec = PetConfig.RollAptitudes(player.UserId .. "/" .. uid, kind, not hasTender)
	profile.Pets[uid] = { Kind = kind, Apt = apt, Spec = spec }
	local equipped = #profile.EquippedPets < profile.PetSlots
	if equipped then
		table.insert(profile.EquippedPets, uid)
	end
	return uid, equipped
end

-- Gives `amount` care XP to every equipped pet (GDD §7.4: each gets the full amount, PetConfig.GainCareXp; a pet with nothing left
-- to train gains nothing). Saved by the autosave and on leave. Returns how many pets gained XP (0 while the profile is not loaded or
-- nothing is equipped).
function PetService.AddXP(player: Player, amount: number): number
	local profile = PlayerProfile.Get(player)
	if not profile or type(amount) ~= "number" or amount < 1 then
		return 0
	end
	amount = math.floor(amount)
	local gaining = 0
	for _, pet in equippedPets(profile) do
		if #PetConfig.GainCareXp(pet, amount) > 0 then
			gaining += 1
		end
	end
	if gaining > 0 then
		publish(player) -- levels feed the Coin bonus, the EquippedPets labels and the Pets panel
	end
	return gaining
end

-- Drops equipped uids that no longer exist or exceed the slots (corrupt or hand-edited records). A pet whose aptitudes are missing or
-- corrupt (the profile migration rolls them for pets from before E1b) gets a fresh set rolled from the owner and uid.
-- Returns true when aptitudes were rolled (the profile should be saved).
local function sanitize(profile, player: Player): boolean
	local rolled = false
	for uid, pet in profile.Pets do
		if not PetConfig.CleanAptitudes(pet) then
			pet.Apt, pet.Spec = PetConfig.RollAptitudes(player.UserId .. "/" .. uid, pet.Kind, false, 1)
			rolled = true
		end
	end
	for _, pet in profile.Pets do
		local name = PetConfig.CleanName(pet.Name)
		pet.Name = if name and name ~= "" then name else nil -- hand-edited or corrupt names are dropped
	end
	local kept = {}
	for _, uid in profile.EquippedPets do
		if
			type(uid) == "string"
			and profile.Pets[uid]
			and not table.find(kept, uid)
			and not GardenConfig.IsPenned(profile, uid) -- equipped and penned never both (hand-edited records)
			and not GardenConfig.FieldSquare(profile, uid) -- nor equipped and on the field
			and #kept < profile.PetSlots
		then
			table.insert(kept, uid)
		end
	end
	profile.EquippedPets = kept
	return rolled
end

-- The broadcast-filtered form of `text` written by `player`, or nil when the filter call fails (then no name is shown).
local function filterName(player: Player, text: string): string?
	local ok, result = pcall(function()
		local filterResult = TextService:FilterStringAsync(text, player.UserId, Enum.TextFilterContext.PublicChat)
		return filterResult:GetNonChatStringForBroadcastAsync()
	end)
	if ok and type(result) == "string" then
		return result
	end
	warn("[PetService] name filter failed: " .. tostring(result))
	return nil
end

-- Filters every stored name again (filters change over time) and publishes; runs after the join publish.
local function refilter(player: Player)
	local profile = PlayerProfile.Get(player)
	if not profile then
		return
	end
	local results = {} -- { uid, raw, shown }
	for uid, pet in profile.Pets do
		if type(pet.Name) == "string" then
			table.insert(results, { uid, pet.Name, filterName(player, pet.Name) })
		end
	end
	local names = filtered[player]
	if #results == 0 or not names or PlayerProfile.Get(player) ~= profile then
		return
	end
	for _, result in results do
		local pet = profile.Pets[result[1]]
		if pet and pet.Name == result[2] then -- a rename during the calls keeps its own result
			names[result[1]] = result[3]
		end
	end
	publish(player)
end

-- Join and admin reset: grants the launch egg once and publishes the state.
local function setup(player: Player)
	local profile = PlayerProfile.WaitFor(player)
	if not profile then
		return
	end
	if sanitize(profile, player) then
		task.spawn(PlayerProfile.Save, player)
	end
	if not profile.LaunchEgg then
		profile.LaunchEgg = true
		profile.FreeEggs[LAUNCH_EGG] = (profile.FreeEggs[LAUNCH_EGG] or 0) + 1
		task.spawn(PlayerProfile.Save, player)
	end
	filtered[player] = {}
	publish(player)
	freeEggsChanged:Fire(player)
	task.spawn(refilter, player)
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
	if GardenConfig.FieldSquare(profile, uid) then
		return reject(player, "Equip", "field")
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
	if GardenConfig.FieldSquare(profile, uid) then
		return reject(player, "SellPet", "field")
	end

	local value = PetConfig.SellValue(pet.Kind)
	profile.Pets[uid] = nil
	PlayerProfile.AddCoins(player, value) -- a sale is not a gameplay reward: no pet multiplier
	succeed(player, "SellPet", { uid = uid, coins = value })
	task.spawn(PlayerProfile.Save, player)
end)

renameEvent.OnServerEvent:Connect(function(player, uid, text)
	if type(uid) ~= "string" or type(text) ~= "string" or not allow(player) then
		return
	end
	local profile = PlayerProfile.Get(player)
	local pet = profile and profile.Pets[uid]
	if not pet then
		return
	end
	local name = PetConfig.CleanName(text)
	if not name then
		return reject(player, "Rename", "name")
	end
	if name == (pet.Name or "") then
		return reject(player, "Rename", "same")
	end
	local names = filtered[player] or {}
	filtered[player] = names
	if name == "" then
		pet.Name = nil -- clearing is free and needs no filter
		names[uid] = nil
		succeed(player, "Rename", { uid = uid, price = 0 })
		task.spawn(PlayerProfile.Save, player)
		return
	end
	local now = os.clock()
	if lastRename[player] and now - lastRename[player] < PetConfig.RenameCooldown then
		return reject(player, "Rename", "cooldown")
	end
	local price = if pet.Renamed then PetConfig.RenamePrice else 0
	if profile.Coins < price then
		return reject(player, "Rename", "coins")
	end
	lastRename[player] = now
	local shown = filterName(player, name) -- yields
	if not shown then
		return reject(player, "Rename", "filter")
	end
	-- the profile may have changed during the filter call (sale, purchase, leave)
	if PlayerProfile.Get(player) ~= profile or profile.Pets[uid] ~= pet then
		return
	end
	if profile.Coins < price then
		return reject(player, "Rename", "coins")
	end
	if price > 0 then
		PlayerProfile.AddCoins(player, -price)
	end
	pet.Name = name
	pet.Renamed = true
	names[uid] = shown
	succeed(player, "Rename", { uid = uid, name = shown, price = price })
	task.spawn(PlayerProfile.Save, player)
end)

PlayerProfile.ProfileReset:Connect(setup)

Players.PlayerAdded:Connect(setup)
for _, player in Players:GetPlayers() do
	task.spawn(setup, player)
end

Players.PlayerRemoving:Connect(function(player)
	lastRequest[player] = nil
	lastRename[player] = nil
	filtered[player] = nil
end)

return PetService
