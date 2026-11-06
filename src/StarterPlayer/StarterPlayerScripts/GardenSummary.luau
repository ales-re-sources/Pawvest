-- GardenSummary (U2, docs/GDD.md §7.9): what waits in the local player's own garden, for the Garden button's badge
-- (HintSources) and the summary bubble over the own plot's sign (GardenBubble). Display only: it reads GardenView's copies of
-- the server's messages, the own plot (GardenRemotes.Plot: eggs "EggId:readyAt") and the owner's field (GardenRemotes.State
-- field.squares: crop, grown, readyAt), and compares their times with workspace:GetServerTimeNow().
--   GardenSummary.Get(now?) -> { known, ripe, eggs, planted, nextAt }
--     known   = false until the own plot or field has arrived (nothing to show yet)
--     ripe    = ripe crops: grown to the crop's growSeconds, or past readyAt (the server settles the field before a harvest)
--     eggs    = incubators whose egg is ready to hatch
--     planted = squares with a crop (ripe or growing)
--     nextAt  = server time when the next growing crop is ripe (nil when nothing grows)
-- Before the owner's field state arrives, the plot message stands in (crop stage 3 = ripe; no times).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local GardenView = require(script.Parent:WaitForChild("GardenView"))
local PlotView = require(script.Parent:WaitForChild("PlotView"))

local GardenSummary = {}

export type Summary = { known: boolean, ripe: number, eggs: number, planted: number, nextAt: number? }

function GardenSummary.Get(now: number?): Summary
	now = now or workspace:GetServerTimeNow()
	local result: Summary = { known = false, ripe = 0, eggs = 0, planted = 0, nextAt = nil }
	local plot = GardenView.OwnState()
	local field = GardenView.OwnField()

	if plot then
		result.known = true
		for number = 1, GardenConfig.MaxIncubators do
			local eggId, readyAt = PlotView.ParseEgg(plot.eggs and plot.eggs[number])
			if eggId and readyAt and readyAt <= (now :: number) then
				result.eggs += 1
			end
		end
	end

	if type(field) == "table" and type(field.squares) == "table" then
		result.known = true
		for _, square in field.squares do
			local crop = CropConfig.ById[square.crop]
			if crop then
				result.planted += 1
				if (square.grown or 0) >= crop.growSeconds or (square.readyAt or 0) <= (now :: number) then
					result.ripe += 1
				elseif not result.nextAt or square.readyAt < result.nextAt then
					result.nextAt = square.readyAt
				end
			end
		end
	elseif plot and type(plot.field) == "table" and type(plot.field.crops) == "string" then
		local crops = plot.field.crops
		for n = 1, #crops // 2 do
			local letter, stage = string.sub(crops, n * 2 - 1, n * 2 - 1), string.sub(crops, n * 2, n * 2)
			if letter ~= "." and letter ~= "#" then
				result.planted += 1
				if stage == "3" then
					result.ripe += 1
				end
			end
		end
	end
	return result
end

return GardenSummary
