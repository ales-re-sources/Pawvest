-- TR2: the Apple tree (FruitTree, the approved A round crown): red apples, 4 fruit slots (CropConfig tree.Cap).
local C = Color3.fromRGB
local Plant = require(script.Parent.FruitTree).make("Apple", {
	bark = C(112, 78, 54), limb = C(128, 92, 62), stalk = C(92, 66, 42), fruitLeaf = C(98, 168, 72),
	leaves = { C(70, 140, 62), C(92, 160, 70), C(58, 122, 64) },
	fruit = C(206, 48, 44), facet = C(232, 96, 72), unripe = C(146, 184, 76), unripeFacet = C(176, 204, 108), d = 0.62,
})

return Plant
