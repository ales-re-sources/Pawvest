-- Num: checks for numbers that come from a client or from stored data (never trust either). Shared, pure.
--   Num.Finite(v)                       a real number (not NaN, |v| < 1e12)
--   Num.Whole(v, limit?)                a whole number with |v| < limit (default 1e6): client arguments (counts, squares, levels)
--   Num.Level(v, min, max, default)     whatever is stored or replicated as a whole level in min..max; `default` for a
--                                       non-number or NaN (corrupt data)

local Num = {}

function Num.Finite(value: any): boolean
	return type(value) == "number" and value == value and math.abs(value) < 1e12
end

function Num.Whole(value: any, limit: number?): boolean
	return type(value) == "number" and value == math.floor(value) and math.abs(value) < (limit or 1e6)
end

function Num.Level(value: any, min: number, max: number, default: number): number
	if type(value) ~= "number" or value ~= value then
		return default
	end
	return math.clamp(math.floor(value), min, max)
end

return Num
