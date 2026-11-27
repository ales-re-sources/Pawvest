-- TR2: the Golden apple tree (FruitTree, the Apple's shape in gold, the user's choice): golden apples, warmer leaves,
-- 6 fruit slots (CropConfig tree.Cap).
local C = Color3.fromRGB
local Plant = require(script.Parent.FruitTree).make("GoldenApple", {
	bark = C(124, 94, 66), limb = C(140, 106, 72), stalk = C(110, 80, 44), fruitLeaf = C(120, 176, 70),
	leaves = { C(92, 148, 62), C(120, 168, 70), C(78, 132, 66) },
	fruit = C(239, 178, 40), facet = C(255, 214, 88), unripe = C(170, 192, 92), unripeFacet = C(198, 214, 124), d = 0.64,
})

return Plant
