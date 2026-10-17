-- CoinRewards: the only place where gameplay pays Coins (docs/GDD.md §5): medal payouts, repeat rewards, coin
-- pickups and future sources. Applies the player's pet multiplier (GDD §7.3, capped at +50 %) and rounds half up.
-- Purchases and deductions call PlayerProfile.AddCoins directly, without the multiplier. Server-only.

local ServerScriptService = game:GetService("ServerScriptService")

local PlayerProfile = require(ServerScriptService.PlayerProfile)
local PetService = require(ServerScriptService.PetService)

local CoinRewards = {}

-- Reward multiplier of `player`: 1 + the bonus of the equipped pets.
CoinRewards.Multiplier = PetService.Multiplier

-- Pays `baseCoins` × multiplier (rounded) for `source` (e.g. "medal", "run", "coin").
-- Returns the Coins paid (0 for a non-positive base), or nil if the profile is not loaded (nothing paid).
function CoinRewards.Grant(player: Player, baseCoins: number, _source: string): number?
	if not PlayerProfile.Get(player) then
		return nil
	end
	if baseCoins <= 0 then
		return 0
	end
	-- the guard keeps exact halves from rounding down through float error (30 × 1.15 = 34.4999…)
	local paid = math.floor(baseCoins * CoinRewards.Multiplier(player) + 0.5 + 1e-9)
	PlayerProfile.AddCoins(player, paid)
	return paid
end

return CoinRewards
