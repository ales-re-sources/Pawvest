-- Level-up moment for penned pets (P1e2): a pet that is fed in the garden (GardenFood) gains a level, the server publishes its
-- plot, GardenView redraws the pen with the new model and every client in the garden plays PetLook.LevelUp on that model,
-- exactly like the followers do. Display only, never sends anything. PlotView decides what counts (the same uid in the same pen
-- at a higher level; placing a pet, taking it out, a different pet in the pen, joining and first sight never do) and calls this
-- only when the pen is drawn in full detail.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PetLook = require(ReplicatedStorage:WaitForChild("PetLook"))
local GardenView = require(script.Parent:WaitForChild("GardenView"))

-- Plays the moment on the redrawn pen model: it spins and rises in its new look (the pen has no ghost of the old look - the old
-- model is already gone - so there is no cross-fade; the returned fade is ignored) with the flash, burst, ring and text.
GardenView.OnPenLevelUp(function(model: Model, kind: string, level: number)
	local base = model:GetPivot()
	local moment = PetLook.LevelUp(model, kind, level)
	if not moment then
		return
	end
	while not moment.done and model.Parent do
		model:PivotTo((moment:Pose(base)))
		RunService.Heartbeat:Wait()
	end
	if model.Parent then
		model:PivotTo(base)
	end
end)
