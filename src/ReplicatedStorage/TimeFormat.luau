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

return TimeFormat
