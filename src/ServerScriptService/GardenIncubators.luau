-- GardenIncubators: every egg (Basic, Golden) hatches in an incubator of the player's plot (docs/GDD.md §7.2, §7.6;
-- P2b1, P2b3). Server-only.
-- State lives in PlayerProfile.Garden: Incubators["1".."3"] = { Egg, StartedAt, ReadyAt } and IncubatorCount (owned
-- incubators, unlocked in order). StartedAt / ReadyAt are the server's os.time() when the egg was started / is due. The
-- client only names an incubator (or the next one to buy), so no request carries a time or a price. Nothing runs while an
-- egg incubates: Hatch compares ReadyAt with os.time(), so the egg also hatches while the owner is offline. The pet is
-- rolled at Hatch and joins the inventory through PetService.AddPet (auto-equip into a free slot).
-- Free eggs (launch egg, first Gold) wait in profile.FreeEggs and are started for free in the lowest empty incubator as
-- soon as one is empty: on join / admin reset (garden setup hook), when one is granted, after a hatch and after an
-- incubator is bought. They respect the inventory cap like bought eggs.
-- Remotes (in GardenRemotes): StartEgg(incubator, eggId), Hatch(incubator), BuyIncubator(expectedIncubator) (client → server);
-- answers through GardenRemotes.Result; GardenRemotes.State.incubators = { count, eggs = { ["n"] = { egg, readyAt } } }.
-- Drawing: Workspace.Garden.Plots.Plot_NN.Incubator_n (Studio-only: Base with Prompt + Info, Egg) gets attributes State
-- ("free" / "locked" / "empty" / "egg"), Egg and ReadyAt; every client draws the countdown from ReadyAt.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GardenConfig = require(ReplicatedStorage.GardenConfig)
local PetConfig = require(ReplicatedStorage.PetConfig)
local PlayerProfile = require(ServerScriptService.PlayerProfile)
local PetService = require(ServerScriptService.PetService)
local GardenService = require(ServerScriptService.GardenService)

local startEggEvent = GardenService.Remote("StartEgg") -- client → server: (incubator: number)
local hatchEvent = GardenService.Remote("Hatch") -- client → server: (incubator: number)
local buyIncubatorEvent = GardenService.Remote("BuyIncubator") -- client → server: (expectedIncubator: number)

local rng = Random.new()
local reject = GardenService.Reject

local GardenIncubators = {}

local function finite(value: any): boolean
	return type(value) == "number" and value == value and math.abs(value) < 1e12
end

-- The profile's garden with its incubators cleaned (idempotent): the count clamped to 1..MaxIncubators; entries beyond it,
-- with an unknown egg or with a non-number time dropped. Nil if the garden is not a table (not set up yet).
local function gardenOf(profile)
	local garden = profile.Garden
	if type(garden) ~= "table" then
		return nil
	end
	local count = if finite(garden.IncubatorCount) then garden.IncubatorCount else 1
	garden.IncubatorCount = math.clamp(math.floor(count), 1, GardenConfig.MaxIncubators)
	local kept = {}
	if type(garden.Incubators) == "table" then
		for key, entry in garden.Incubators do
			local index = tonumber(key)
			local egg = type(entry) == "table" and type(entry.Egg) == "string" and PetConfig.Eggs[entry.Egg]
			if
				index
				and index == math.floor(index)
				and index >= 1
				and index <= garden.IncubatorCount
				and egg
				and egg.hatchSeconds
				and finite(entry.StartedAt)
				and finite(entry.ReadyAt)
			then
				kept[tostring(index)] = entry
			end
		end
	end
	garden.Incubators = kept
	return garden
end
GardenIncubators.GardenOf = gardenOf

GardenService.AddStateField("incubators", function(profile)
	local garden = gardenOf(profile)
	local eggs = {}
	if garden then
		for key, entry in garden.Incubators do
			eggs[key] = { egg = entry.Egg, readyAt = entry.ReadyAt } -- server time, for the client's countdown only
		end
	end
	return { count = garden and garden.IncubatorCount or 1, eggs = eggs }
end)

GardenService.AddRenderer(function(_index, plot, profile)
	local garden = profile and gardenOf(profile)
	for number = 1, GardenConfig.MaxIncubators do
		local model = plot:FindFirstChild(GardenConfig.IncubatorNamePrefix .. number)
		if not model then
			continue
		end
		local entry = garden and garden.Incubators[tostring(number)]
		local state = "free"
		if garden then
			state = if entry then "egg" elseif number > garden.IncubatorCount then "locked" else "empty"
		end
		model:SetAttribute("State", state)
		model:SetAttribute("Egg", if entry then entry.Egg else nil)
		model:SetAttribute("ReadyAt", if entry then entry.ReadyAt else nil)

		local egg = model:FindFirstChild("Egg")
		if egg and egg:IsA("BasePart") then
			egg.Transparency = if entry then 0 else 1
			local light = egg:FindFirstChildOfClass("PointLight")
			if light then
				light.Enabled = entry ~= nil
			end
		end
		local base = model:FindFirstChild("Base")
		local info = base and base:FindFirstChild("Info")
		local text = info and info:FindFirstChildOfClass("TextLabel")
		if info and info:IsA("BillboardGui") then
			info.Enabled = state ~= "free"
		end
		if text then
			text.Text = if state == "locked"
				then "🔒 Incubator " .. number
				elseif state == "empty" then "Incubator " .. number .. "\nempty"
				elseif entry then PetConfig.Eggs[entry.Egg].name -- clients add the countdown
				else ""
		end
	end
end)

-- Starts waiting free eggs (PetConfig.EggOrder) in the lowest empty incubators while the inventory cap allows; the caller
-- publishes and saves. Returns how many were started.
local function startFreeEggs(profile, garden): number
	local started = 0
	local now = os.time()
	for _, eggId in PetConfig.EggOrder do
		local egg = PetConfig.Eggs[eggId]
		while (profile.FreeEggs[eggId] or 0) > 0 do
			local free = nil
			for index = 1, garden.IncubatorCount do
				if not garden.Incubators[tostring(index)] then
					free = index
					break
				end
			end
			if not free or PetService.PetCount(profile) + GardenConfig.IncubatingCount(garden) >= PetConfig.MaxPets then
				return started
			end
			garden.Incubators[tostring(free)] = { Egg = eggId, StartedAt = now, ReadyAt = now + egg.hatchSeconds }
			profile.FreeEggs[eggId] -= 1
			if profile.FreeEggs[eggId] == 0 then
				profile.FreeEggs[eggId] = nil
			end
			started += 1
		end
	end
	return started
end

-- Starts the player's waiting free eggs (if any fit), publishes and saves.
local function placeFreeEggs(player: Player)
	local profile = PlayerProfile.Get(player)
	local garden = profile and gardenOf(profile)
	if garden and startFreeEggs(profile, garden) > 0 then
		GardenService.PublishAll(player)
		task.spawn(PlayerProfile.Save, player)
	end
end

PetService.FreeEggsChanged:Connect(placeFreeEggs) -- before the garden is set up on join this finds no garden: the hook does it
GardenService.AddSetupHook(placeFreeEggs)

-- The caller's profile and garden if they may use their plot now; otherwise rejects and returns nil.
local function usableGarden(player: Player, action: string)
	local profile = GardenService.Usable(player, action)
	local garden = profile and gardenOf(profile)
	if profile and not garden then
		reject(player, action, "loading")
	end
	return profile, garden
end

startEggEvent.OnServerEvent:Connect(function(player, index, eggId)
	local egg = type(eggId) == "string" and PetConfig.Eggs[eggId]
	if not (GardenService.WholeNumber(index) and egg) or not GardenService.Allow(player) then
		return
	end
	local profile, garden = usableGarden(player, "StartEgg")
	if not garden then
		return
	end
	if index < 1 or index > garden.IncubatorCount then
		return reject(player, "StartEgg", "locked")
	end
	if garden.Incubators[tostring(index)] then
		return reject(player, "StartEgg", "occupied")
	end
	if PetService.PetCount(profile) + GardenConfig.IncubatingCount(garden) >= PetConfig.MaxPets then
		return reject(player, "StartEgg", "full") -- every egg needs a free inventory place when it hatches
	end
	if profile.Coins < egg.price then
		return reject(player, "StartEgg", "coins")
	end

	PlayerProfile.AddCoins(player, -egg.price)
	local now = os.time()
	garden.Incubators[tostring(index)] = { Egg = eggId, StartedAt = now, ReadyAt = now + egg.hatchSeconds }
	GardenService.PublishAll(player)
	GardenService.Succeed(player, "StartEgg", { incubator = index, egg = eggId })
	task.spawn(PlayerProfile.Save, player) -- spent Coins and the egg are saved together
end)

hatchEvent.OnServerEvent:Connect(function(player, index)
	if not GardenService.WholeNumber(index) or not GardenService.Allow(player) then
		return
	end
	local profile, garden = usableGarden(player, "Hatch")
	if not garden then
		return
	end
	local key = tostring(index)
	local entry = garden.Incubators[key]
	if not entry then
		return reject(player, "Hatch", "empty")
	end
	if not GardenConfig.EggReady(entry, os.time()) then
		return reject(player, "Hatch", "notready")
	end
	if PetService.PetCount(profile) >= PetConfig.MaxPets then
		return reject(player, "Hatch", "full") -- the egg waits in the incubator
	end

	local kind, rarityId = PetConfig.Roll(entry.Egg, rng)
	garden.Incubators[key] = nil
	local uid, equipped = PetService.AddPet(player, kind)
	startFreeEggs(profile, garden) -- a waiting free egg takes the incubator at once
	GardenService.PublishAll(player)
	GardenService.Succeed(player, "Hatch", { incubator = index, uid = uid, kind = kind, rarity = rarityId, equipped = equipped })
	task.spawn(PlayerProfile.Save, player)
end)

buyIncubatorEvent.OnServerEvent:Connect(function(player, expected)
	if not GardenService.WholeNumber(expected) or not GardenService.Allow(player) then
		return
	end
	local profile, garden = usableGarden(player, "BuyIncubator")
	if not garden then
		return
	end
	if garden.IncubatorCount >= GardenConfig.MaxIncubators then
		return reject(player, "BuyIncubator", "maxed")
	end
	if expected ~= garden.IncubatorCount + 1 then
		return reject(player, "BuyIncubator", "stale") -- out-of-date panel, double click or forged request
	end
	local price = GardenConfig.IncubatorPrices[expected]
	if profile.Coins < price then
		return reject(player, "BuyIncubator", "coins")
	end

	PlayerProfile.AddCoins(player, -price)
	garden.IncubatorCount = expected
	startFreeEggs(profile, garden)
	GardenService.PublishAll(player)
	GardenService.Succeed(player, "BuyIncubator", expected)
	task.spawn(PlayerProfile.Save, player)
end)

return GardenIncubators
