-- TimeFormat: stage times are kept and shown in tenths of a second (GDD §4); the shared clock texts of the garden
-- (Clock, GrowTime) and the UTC day number.

local Locale = require(script.Parent:WaitForChild("Locale"))

local TimeFormat = {}

TimeFormat.DAY = 86400

-- Floors to tenths; the epsilon keeps already-rounded values (e.g. 42.3 stored as 42.29999…) from dropping a tenth.
function TimeFormat.Tenths(seconds: number): number
	return math.floor(seconds * 10 + 1e-6) / 10
end

-- "mm:ss.t"
function TimeFormat.Format(seconds: number): string
	local t = TimeFormat.Tenths(math.max(seconds, 0))
	local minutes = math.floor(t / 60)
	return string.format("%02d:%04.1f", minutes, t - minutes * 60)
end

-- "m:ss", or "m:ss.t" when not whole seconds (medal limits)
function TimeFormat.Short(seconds: number): string
	local t = TimeFormat.Tenths(math.max(seconds, 0))
	local minutes = math.floor(t / 60)
	local rest = t - minutes * 60
	local whole = math.floor(rest + 0.5)
	if math.abs(rest - whole) < 1e-6 then
		return string.format("%d:%02d", minutes, whole)
	end
	return string.format("%d:%04.1f", minutes, rest)
end

-- A running countdown: "1:00:00", "42:07", "0:05". Whole seconds rounded up and never below 0:01 (a timer that still
-- runs never reads 0:00; callers show their own "ready" text once it is over).
function TimeFormat.Clock(seconds: number): string
	seconds = math.max(1, math.ceil(seconds))
	if seconds >= 3600 then
		return string.format("%d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
	end
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

-- A duration in words: "3 hours", "30 min" (Locale.Duration unless it is whole hours).
function TimeFormat.GrowTime(seconds: number): string
	if seconds % 3600 == 0 then
		return Locale.T("common.hours", { count = seconds // 3600 })
	end
	return Locale.Duration(seconds)
end

-- The UTC day number of server time `now` (days since the epoch): daily resets (market cart, runs today).
function TimeFormat.UtcDay(now: number): number
	return math.floor(now / TimeFormat.DAY)
end

return TimeFormat
