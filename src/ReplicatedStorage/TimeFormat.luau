-- TimeFormat: stage times are kept and shown in tenths of a second (GDD §4).

local TimeFormat = {}

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

return TimeFormat
