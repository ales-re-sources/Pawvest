-- Level-up moment for penned pets (P1e2): a pet that is fed in the garden (GardenFood) gains a level, the server redraws its
-- pen (new model, pen attribute Level changes) and every client in the garden plays PetLook.LevelUp on that model, exactly like
-- the followers do. Display only: it watches the pen attributes State / Uid / Kind / Level that GardenService keeps, never
-- sends anything. Same rule as PetFollow: only the same uid with a higher level counts (placing a pet, taking it out, a
-- different pet in the pen, joining and first sight never do).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local PetLook = require(ReplicatedStorage:WaitForChild("PetLook"))

local MODEL_WAIT = 2 -- seconds the redrawn pen model may take to arrive after the attribute

-- The pen's pet model of `level` (GardenService stamps the level on it), or nil.
local function findModel(plot: Instance, pen: Instance, level: number): Model?
	local pets = plot:FindFirstChild("PenPets")
	if not pets then
		return nil
	end
	local prefix = pen.Name .. "_"
	for _, model in pets:GetChildren() do
		if model:IsA("Model") and string.sub(model.Name, 1, #prefix) == prefix and model:GetAttribute("Level") == level then
			return model
		end
	end
	return nil
end

-- Plays the moment on the redrawn pen model: it spins and rises in its new look (the pen has no ghost of the old look - the server
-- already replaced the model - so there is no cross-fade; the returned fade is ignored) with the flash, burst, ring and text.
local function play(plot: Instance, pen: Instance, kind: string, level: number)
	local waited = 0
	local model = findModel(plot, pen, level)
	while not model and waited < MODEL_WAIT do
		waited += RunService.Heartbeat:Wait()
		model = findModel(plot, pen, level)
	end
	if not (model and pen:GetAttribute("Level") == level) then
		return
	end
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
end

local function watch(plot: Instance, pen: Instance)
	local lastUid = pen:GetAttribute("Uid")
	local lastLevel = pen:GetAttribute("Level")
	local scheduled = false
	local function check()
		scheduled = false
		local uid, level, kind = pen:GetAttribute("Uid"), pen:GetAttribute("Level"), pen:GetAttribute("Kind")
		if uid ~= nil and uid == lastUid and type(level) == "number" and type(lastLevel) == "number" and level > lastLevel and type(kind) == "string" then
			task.spawn(play, plot, pen, kind, level)
		end
		lastUid, lastLevel = uid, level
	end
	local function onChanged()
		if not scheduled then -- one check per batch of attribute changes (Uid, Kind, Level arrive together)
			scheduled = true
			task.defer(check)
		end
	end
	for _, name in { "State", "Uid", "Kind", "Level" } do
		pen:GetAttributeChangedSignal(name):Connect(onChanged)
	end
end

task.spawn(function()
	local plots = workspace:WaitForChild("Garden"):WaitForChild("Plots")
	for _, plot in plots:GetChildren() do
		for number = 1, GardenConfig.MaxPens do
			local pen = plot:WaitForChild(GardenConfig.PenNamePrefix .. number, 10)
			if pen then
				watch(plot, pen)
			end
		end
	end
end)
