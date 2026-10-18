-- GardenConfig: the pet garden's shared numbers and pure helpers (docs/GDD.md §7.6). Shared: the server assigns plots,
-- prices and pays from this table only, the client renders it. Pure data + helpers, no side effects.
-- Names stored in the profile or used as attributes are fixed: never rename them.

local GardenConfig = {}

GardenConfig.PlotCount = 12 -- one plot per player slot (Max Players = 12)
GardenConfig.PlotSize = 40 -- studs, square
GardenConfig.PlotAttribute = "GardenPlot" -- player attribute: index of the borrowed plot (absent when none)
GardenConfig.OwnerIdAttribute = "OwnerUserId" -- plot model attribute: UserId of the current owner (absent when free)
GardenConfig.OwnerNameAttribute = "OwnerName" -- plot model attribute: name of the current owner (absent when free)
GardenConfig.FreeSignText = "Free plot"

-- Name of the Workspace.Garden.Plots model of plot `index` ("Plot_01" … "Plot_12").
function GardenConfig.PlotName(index: number): string
	return string.format("Plot_%02d", index)
end

export type Assigner = {
	Claim: (key: any) -> number?,
	Release: (key: any) -> number?,
	IndexOf: (key: any) -> number?,
	KeyOf: (index: number) -> any?,
}

-- Plot assigner: hands out the lowest free index in 1..count to a key (a Player on the server). Claiming again for the
-- same key returns the same index; a full garden returns nil; a released index is free for the next claim.
function GardenConfig.NewAssigner(count: number): Assigner
	local byKey = {}
	local byIndex = {}
	local assigner = {}

	function assigner.Claim(key)
		if byKey[key] then
			return byKey[key]
		end
		for index = 1, count do
			if byIndex[index] == nil then
				byKey[key] = index
				byIndex[index] = key
				return index
			end
		end
		return nil
	end

	-- Returns the index that was freed, or nil if the key held none.
	function assigner.Release(key)
		local index = byKey[key]
		if index then
			byKey[key] = nil
			byIndex[index] = nil
		end
		return index
	end

	function assigner.IndexOf(key)
		return byKey[key]
	end

	function assigner.KeyOf(index)
		return byIndex[index]
	end

	return assigner
end

return GardenConfig
