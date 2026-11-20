-- OnboardConfig (E5c, D5): the first-ten-minutes path of a new player and the GardenStart funnel (docs/GDD.md §11 → Onboarding).
-- The profile field Onboard (mirrored as the player attribute Onboard) is a bit mask: bit k - 1 set = step k of Funnel done.
-- Steps 1-8 are the path the hints walk (the current step = the lowest unfinished one; all 8 = the path is done); 9 and 10 only
-- feed the funnel. Step ids and their order are stored (bits, funnel step numbers): never renamed, reordered or reused.

local OnboardConfig = {}

OnboardConfig.Attribute = "Onboard"
OnboardConfig.FunnelName = "GardenStart"

-- the path (D5: no text boxes, no locked controls; every step is pointed at by a pulse or a marker)
OnboardConfig.Path = {
	"hatch", -- the starter egg (ready on arrival)
	"plant", -- the 4 start Potatoes (CropConfig.StartSeeds; done at 4 plantings)
	"harvest",
	"sell",
	"buySeeds", -- at the seed stall (catalogue or market cart)
	"placePet", -- the first pet on the field
	"quests", -- the Goals panel opened (the client tells the server)
	"stage", -- a stage finished
}
OnboardConfig.Funnel = table.clone(OnboardConfig.Path)
table.insert(OnboardConfig.Funnel, "request") -- the first finished request (E5a)
table.insert(OnboardConfig.Funnel, "return") -- the first join on a later UTC day than the first one

OnboardConfig.Index = {} -- [id] = step number
for step, id in OnboardConfig.Funnel do
	OnboardConfig.Index[id] = step
end
OnboardConfig.AllMask = bit32.lshift(1, #OnboardConfig.Funnel) - 1 -- a profile that starts as done

function OnboardConfig.Bit(id: string): number
	return bit32.lshift(1, OnboardConfig.Index[id] - 1)
end

-- Whether step `id` is done in `mask` (a missing mask: nothing is done).
function OnboardConfig.Has(mask: any, id: string): boolean
	return type(mask) == "number" and bit32.band(mask, OnboardConfig.Bit(id)) ~= 0
end

-- The current path step of `mask` (the lowest unfinished one), or nil when the path is done or the mask is unknown.
function OnboardConfig.Current(mask: any): string?
	if type(mask) ~= "number" then
		return nil
	end
	for _, id in OnboardConfig.Path do
		if not OnboardConfig.Has(mask, id) then
			return id
		end
	end
	return nil
end

return OnboardConfig
