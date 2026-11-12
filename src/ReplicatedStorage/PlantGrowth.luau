-- Shared plant-art entry point. A crop animates when ReplicatedStorage holds a recipe module named `<crop id>Plant`
-- (the same convention as PlantGrowthReview) that is not marked `Draft = true` (a draft shows only in the reviewer).
-- Recipes provide new(parent, soilCFrame, seed, sizeFactor?), BuildProxy, RingHeight, and a plant object with model,
-- SetGrowth(0..1) and Destroy() (emit-style recipes: PlantKit.recipe).
local CropConfig = require(script.Parent.CropConfig)

local recipes = {}
for _, crop in CropConfig.Crops do
	local module = script.Parent:FindFirstChild(crop.id .. "Plant")
	if module and module:IsA("ModuleScript") then
		local recipe = require(module)
		if not recipe.Draft then
			recipes[crop.id] = recipe
		end
	end
end

local PlantGrowth = {}

function PlantGrowth.Supports(cropId: string): boolean
	return recipes[cropId] ~= nil
end

function PlantGrowth.PlantCFrame(soilCFrame: CFrame, seed: number, recipe): CFrame
	-- Trained vines keep rigid supports aligned with the field rows.
	if recipe and recipe.FixedOrientation then return soilCFrame end
	-- Seed one remains the authored reference pose in the art reviewer.
	local angle = if seed == 1 then 0 else Random.new(seed + 3931):NextNumber(0, math.pi * 2)
	return soilCFrame * CFrame.Angles(0, angle, 0)
end

function PlantGrowth.new(parent: Instance, soilCFrame: CFrame, cropId: string, seed: number, sizeFactor: number?)
	local recipe = assert(recipes[cropId], "Missing growth recipe for " .. cropId)
	local frame = PlantGrowth.PlantCFrame(soilCFrame, seed, recipe)
	return recipe.new(parent, frame, seed, sizeFactor)
end

function PlantGrowth.BuildProxy(parent: Instance, soilCFrame: CFrame, cropId: string, stage: number, seed: number?, sizeFactor: number?)
	local recipe = assert(recipes[cropId], "Missing growth recipe for " .. cropId)
	local frame = PlantGrowth.PlantCFrame(soilCFrame, seed or 1, recipe)
	recipe.BuildProxy(parent, frame, stage, seed, sizeFactor)
end

-- Also accepts an unregistered recipe in the Studio reviewer.
function PlantGrowth.RecipeRingHeight(recipe, sizeFactor: number?): number
	if not recipe then return 1.3 end
	local height = recipe.RingHeight or 1.3
	return if recipe.FixedRingHeight then height else height * (sizeFactor or 1) ^ (1/3)
end

function PlantGrowth.RingHeight(cropId: string, sizeFactor: number?): number
	return PlantGrowth.RecipeRingHeight(recipes[cropId], sizeFactor)
end

-- Cosmetic feedback only after the caller receives a successful harvest acknowledgment.
-- This is independent of plant teardown: distance changes and time corrections must not celebrate a harvest.
function PlantGrowth.PlayHarvest(cropId: string, parent: Instance, soilCFrame: CFrame, sizeFactor: number?)
	local recipe = recipes[cropId]
	if recipe and recipe.PlayHarvest then
		return recipe.PlayHarvest(parent, soilCFrame, sizeFactor)
	end
	return nil
end

function PlantGrowth.UpdateInterval(duration: number): number
	-- The same small visible step (1/480 of the growth) for every crop, at most 5 Hz for quick crops.
	-- Corrections and the exact ripe moment do not wait for a sample (PlotView:plantDue).
	return math.clamp(duration / 480, 0.2, 30)
end

return PlantGrowth
