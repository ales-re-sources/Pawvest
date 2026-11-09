-- Preserve the original CG1b review command.
local Review = require(script.Parent.PlantGrowthReview)

return {
	Open = function()
		return Review.Open("Tomato", 8)
	end,
}
