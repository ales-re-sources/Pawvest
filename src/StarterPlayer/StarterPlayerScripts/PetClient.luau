-- PetClient: shared client-side pet state for the Pets panel and the garden panels (P1b).
-- Display only: it mirrors PetRemotes.PetsChanged and the leaderstats Coins; every action is a request the server
-- validates and prices (PetService). The server publishes the state once on join, which a client that is still
-- loading would miss, so this module asks for it with PetRemotes.RequestState as soon as it is listening.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))

local remotes = ReplicatedStorage:WaitForChild("PetRemotes")
local player = Players.LocalPlayer

local changedEvent = Instance.new("BindableEvent")
local resultEvent = Instance.new("BindableEvent")

local PetClient = {
	Remotes = remotes,
	State = nil, -- last PetsChanged payload: { pets, equipped, slots, freeEggs, multiplier, penned, field }
	Coins = 0,
	Changed = changedEvent.Event, -- fires (state?) after the pet state or the Coins changed
	Result = resultEvent.Event, -- fires (action, ok, detailOrReason) for each answer from the server
}

export type OwnedPet = {
	uid: string,
	kind: string,
	level: number, -- P4: PetConfig.PetLevel, the highest working trait
	care: string?, -- P4: the trait food and obby XP train now (PetConfig.CareTarget), nil when nothing trains
	xp: number, -- that trait's progress in care XP (0 when nothing trains)
	xpNext: number?, -- care XP for that trait's next level; nil when nothing trains
	cute: number, -- Cuteness level (P4), 0 without it
	rarity: PetConfig.Rarity,
	equipped: boolean,
	penned: number?, -- garden pen index (P2a2), nil when not in a pen
	field: number?, -- field square the pet works (E1b), nil when not on the field
	tending: number, -- Tending aptitude level (E1b), 0 without it
	guard: number, -- Pest-control aptitude level (E4b), 0 without it
	spec: string?, -- Pest-control speciality (PetConfig.Specs), nil without Pest control
	name: string?, -- the filtered name (P3b), nil when the pet has none
	renamed: boolean, -- the pet has been named before: the next name costs PetConfig.RenamePrice
	bonus: number, -- permille
	sellValue: number,
}

-- Inventory as a list in a fixed order: rarest, then highest level, then by kind name, then oldest. Equipping, unequipping
-- or penning a pet never moves it (its row just changes its marks); only a hatch, a sale or a level-up reorders.
function PetClient.Inventory(): { OwnedPet }
	local state = PetClient.State
	local list = {}
	if not state then
		return list
	end
	for uid, pet in state.pets do
		local rarity = PetConfig.RarityOf(pet.Kind)
		if rarity then
			local care, careXp, careNext = PetConfig.CareProgress(pet)
			table.insert(list, {
				uid = uid,
				kind = pet.Kind,
				level = PetConfig.PetLevel(pet),
				care = care,
				xp = careXp,
				xpNext = if care then careNext else nil,
				cute = PetConfig.AptitudeLevel(pet, "Cuteness"),
				rarity = rarity,
				equipped = table.find(state.equipped, uid) ~= nil,
				penned = state.penned and state.penned[uid] or nil,
				field = state.field and state.field[uid] or nil,
				tending = PetConfig.AptitudeLevel(pet, "Tending"),
				guard = PetConfig.AptitudeLevel(pet, "PestControl"),
				spec = if type(pet.Spec) == "string" then pet.Spec else nil,
				name = if type(pet.Name) == "string" and pet.Name ~= "" then pet.Name else nil,
				renamed = pet.Renamed == true,
				bonus = PetConfig.PetBonus(pet),
				sellValue = PetConfig.SellValue(pet.Kind),
			})
		end
	end
	table.sort(list, function(a, b)
		if a.rarity.order ~= b.rarity.order then
			return a.rarity.order > b.rarity.order
		end
		if a.level ~= b.level then
			return a.level > b.level
		end
		if a.kind ~= b.kind then
			return a.kind < b.kind
		end
		return (tonumber(a.uid) or 0) < (tonumber(b.uid) or 0)
	end)
	return list
end

-- The filtered name of the player's pet `uid` (P3b), or nil.
function PetClient.NameOf(uid: string?): string?
	local pet = uid and PetClient.State and PetClient.State.pets[uid]
	local name = pet and pet.Name
	return if type(name) == "string" and name ~= "" then name else nil
end

function PetClient.PetCount(): number
	local count = 0
	if PetClient.State then
		for _ in PetClient.State.pets do
			count += 1
		end
	end
	return count
end

-- "2", "3.5", "0.5": a number with at most one decimal and no trailing zero.
function PetClient.Percent(permille: number): string
	return string.format("%g", math.round(permille) / 10)
end

-- Thousands separators for Coin amounts: 1500 → "1,500".
function PetClient.Number(n: number): string
	local text = tostring(math.floor(n))
	while true do
		local replaced, count = string.gsub(text, "^(-?%d+)(%d%d%d)", "%1,%2")
		text = replaced
		if count == 0 then
			return text
		end
	end
end

remotes:WaitForChild("PetsChanged").OnClientEvent:Connect(function(state)
	PetClient.State = state
	changedEvent:Fire(state)
end)

remotes:WaitForChild("Result").OnClientEvent:Connect(function(action, ok, detail)
	resultEvent:Fire(action, ok, detail)
end)

task.spawn(function()
	local coinValue = player:WaitForChild("leaderstats"):WaitForChild("Coins") :: IntValue
	PetClient.Coins = coinValue.Value
	changedEvent:Fire(PetClient.State)
	coinValue:GetPropertyChangedSignal("Value"):Connect(function()
		PetClient.Coins = coinValue.Value
		changedEvent:Fire(PetClient.State)
	end)
end)

remotes:WaitForChild("RequestState"):FireServer()

return PetClient
