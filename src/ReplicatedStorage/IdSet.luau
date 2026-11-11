-- IdSet: a set of string ids as a player-attribute string: sorted, comma-separated, "" when empty. Shared, pure.
--   IdSet.Encode(set, isKnown?)  ids whose value is true (and, with `isKnown`, that it accepts)
--   IdSet.Decode(text)           [id] = true from such a string (nil or "" → empty set)

local IdSet = {}

function IdSet.Encode(set: { [string]: any }, isKnown: ((string) -> boolean)?): string
	local ids = {}
	for id, value in set do
		if value == true and (not isKnown or isKnown(id)) then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	return table.concat(ids, ",")
end

function IdSet.Decode(text: any): { [string]: boolean }
	local set = {}
	if type(text) == "string" then
		for id in string.gmatch(text, "[^,]+") do
			set[id] = true
		end
	end
	return set
end

return IdSet
