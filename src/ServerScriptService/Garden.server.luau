-- Garden: boot script of the pet garden (docs/GDD.md §7.6). Starts the plot assignment, the pens / production
-- (GardenService), the incubators (GardenIncubators) and the food stand (GardenFood).
-- The garden island is reached on foot over Workspace.GardenBridge from the central island (H1); no portals.

local ServerScriptService = game:GetService("ServerScriptService")

require(ServerScriptService.GardenPlots)
require(ServerScriptService.GardenService)
require(ServerScriptService.GardenIncubators)
require(ServerScriptService.GardenFood)
