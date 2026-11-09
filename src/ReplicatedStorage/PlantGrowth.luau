-- Shared plant-art entry point. Register a recipe here to animate another crop.
-- Recipes provide new(parent, soilCFrame, seed), BuildProxy(parent, soilCFrame, stage),
-- and a plant object with model, SetGrowth(0..1) and Destroy().
local recipes = {
	Tomato = require(script.Parent.TomatoPlant),
}

local PlantGrowth = {}

function PlantGrowth.Supports(cropId: string): boolean
	return recipes[cropId] ~= nil
end

function PlantGrowth.new(parent: Instance, soilCFrame: CFrame, cropId: string, seed: number)
	return assert(recipes[cropId], "Missing growth recipe for " .. cropId).new(parent, soilCFrame, seed)
end

function PlantGrowth.BuildProxy(parent: Instance, soilCFrame: CFrame, cropId: string, stage: number)
	assert(recipes[cropId], "Missing growth recipe for " .. cropId).BuildProxy(parent, soilCFrame, stage)
end

function PlantGrowth.RingHeight(cropId: string): number
	local recipe = recipes[cropId]
	return if recipe then recipe.RingHeight or 1.3 else 1.3
end

function PlantGrowth.UpdateInterval(duration: number): number
	-- Keep a similar visible growth step for quick crops and boosted plants.
	return math.clamp(duration / 480, 0.05, 1)
end

return PlantGrowth
