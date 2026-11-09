-- Shared plant-art entry point. Register a recipe here to animate another crop.
-- Recipes provide new(parent, soilCFrame, seed), BuildProxy(parent, soilCFrame, stage),
-- and a plant object with model, SetGrowth(0..1) and Destroy().
local recipes = {
	Tomato = require(script.Parent.TomatoPlant),
	Potato = require(script.Parent.PotatoPlant),
}

local PlantGrowth = {}

function PlantGrowth.Supports(cropId: string): boolean
	return recipes[cropId] ~= nil
end

function PlantGrowth.PlantCFrame(soilCFrame: CFrame, seed: number): CFrame
	-- Seed one remains the authored reference pose in the art reviewer.
	local angle = if seed == 1 then 0 else Random.new(seed + 3931):NextNumber(0, math.pi * 2)
	return soilCFrame * CFrame.Angles(0, angle, 0)
end

function PlantGrowth.new(parent: Instance, soilCFrame: CFrame, cropId: string, seed: number, sizeFactor: number?)
	local frame = PlantGrowth.PlantCFrame(soilCFrame, seed)
	return assert(recipes[cropId], "Missing growth recipe for " .. cropId).new(parent, frame, seed, sizeFactor)
end

function PlantGrowth.BuildProxy(parent: Instance, soilCFrame: CFrame, cropId: string, stage: number, seed: number?, sizeFactor: number?)
	local frame = PlantGrowth.PlantCFrame(soilCFrame, seed or 1)
	assert(recipes[cropId], "Missing growth recipe for " .. cropId).BuildProxy(parent, frame, stage, seed, sizeFactor)
end

function PlantGrowth.RingHeight(cropId: string, sizeFactor: number?): number
	local recipe = recipes[cropId]
	if not recipe then return 1.3 end
	return (recipe.RingHeight or 1.3) * (sizeFactor or 1) ^ (1/3)
end

function PlantGrowth.UpdateInterval(duration: number): number
	-- Keep a similar visible growth step for quick crops and boosted plants.
	return math.clamp(duration / 480, 0.2, 1)
end

return PlantGrowth
