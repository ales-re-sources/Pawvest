-- PetClient: shared client-side pet state for the egg stand popup and the Pets panel (P1b).
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
	State = nil, -- last PetsChanged payload: { pets, equipped, slots, freeEggs, multiplier }
	Coins = 0,
	Changed = changedEvent.Event, -- fires (state?) after the pet state or the Coins changed
	Result = resultEvent.Event, -- fires (action, ok, detailOrReason) for each answer from the server
}

export type OwnedPet = {
	uid: string,
	kind: string,
	level: number,
	rarity: PetConfig.Rarity,
	equipped: boolean,
	bonus: number, -- permille
	sellValue: number,
}

-- Inventory as a list: equipped first, then rarest, then highest level, then oldest.
function PetClient.Inventory(): { OwnedPet }
	local state = PetClient.State
	local list = {}
	if not state then
		return list
	end
	for uid, pet in state.pets do
		local rarity = PetConfig.RarityOf(pet.Kind)
		if rarity then
			table.insert(list, {
				uid = uid,
				kind = pet.Kind,
				level = PetConfig.ClampLevel(pet.Level),
				rarity = rarity,
				equipped = table.find(state.equipped, uid) ~= nil,
				bonus = PetConfig.PetBonus(pet),
				sellValue = PetConfig.SellValue(pet.Kind),
			})
		end
	end
	table.sort(list, function(a, b)
		if a.equipped ~= b.equipped then
			return a.equipped
		end
		if a.rarity.order ~= b.rarity.order then
			return a.rarity.order > b.rarity.order
		end
		if a.level ~= b.level then
			return a.level > b.level
		end
		return (tonumber(a.uid) or 0) < (tonumber(b.uid) or 0)
	end)
	return list
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
