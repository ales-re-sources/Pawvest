-- RateLimit: a per-player cooldown for a remote (double clicks, spam). Server-only.
--   local allow = RateLimit.new(seconds)   allow(player) → true and starts the cooldown when the last accepted call is at
--                                          least `seconds` ago, else false; forgets a player when they leave

local Players = game:GetService("Players")

local RateLimit = {}

function RateLimit.new(seconds: number): (Player) -> boolean
	local last = {} -- [Player] = os.clock() of the last accepted call
	Players.PlayerRemoving:Connect(function(player)
		last[player] = nil
	end)
	return function(player: Player): boolean
		local now = os.clock()
		if last[player] and now - last[player] < seconds then
			return false
		end
		last[player] = now
		return true
	end
end

return RateLimit
