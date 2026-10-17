-- CoinRewards: the only place where gameplay pays Coins (docs/GDD.md §5): medal payouts, repeat rewards, coin
-- pickups and future sources. Applies the player's multiplier (pet bonus from P1, a constant 1 until then) and rounds.
-- Purchases and deductions call PlayerProfile.AddCoins directly, without the multiplier. Server-only.

local ServerScriptService = game:GetService("ServerScriptService")

local PlayerProfile = require(ServerScriptService.PlayerProfile)

local CoinRewards = {}

-- Reward multiplier of `player`; P1 replaces this with the pet bonus.
function CoinRewards.Multiplier(_player: Player): number
	return 1
end

-- Pays `baseCoins` × multiplier (rounded) for `source` (e.g. "medal", "run", "coin").
-- Returns the Coins paid (0 for a non-positive base), or nil if the profile is not loaded (nothing paid).
function CoinRewards.Grant(player: Player, baseCoins: number, _source: string): number?
	if not PlayerProfile.Get(player) then
		return nil
	end
	if baseCoins <= 0 then
		return 0
	end
	local paid = math.floor(baseCoins * CoinRewards.Multiplier(player) + 0.5)
	PlayerProfile.AddCoins(player, paid)
	return paid
end

return CoinRewards
