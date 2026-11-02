-- Tier effects of penned pets (P1e3): GardenView / PlotView dress the pen models drawn on this client with PetLook.Apply (accent
-- tint, trail, aura, glow disc, halo and motes); this script runs the orbit animation of the motes and the distance LOD, exactly
-- as PetFollow does it for followers: PetLook.UpdateFx every frame, emitters and lights off for pens farther than
-- PetLook.LodDistance from the camera. Display only, never sends anything.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PetLook = require(ReplicatedStorage:WaitForChild("PetLook"))
local GardenView = require(script.Parent:WaitForChild("GardenView"))

local LOD_HYSTERESIS = 5 -- studs: a far pen's effects come back this much inside PetLook.LodDistance

local entries = setmetatable({}, { __mode = "k" }) :: { [Model]: { fx: PetLook.Fx, far: boolean } } -- pen model -> collected effects

local function entryOf(model: Model)
	local entry = entries[model]
	local expected = model:GetAttribute("FxCount")
	if entry and (entry.fx.count == expected or expected == nil) then
		return entry
	end
	-- first sight, or children of the model were still arriving: collect (again)
	local fx = PetLook.CollectFx(model)
	if not fx then
		return nil
	end
	entry = { fx = fx, far = if entry then entry.far else false }
	entries[model] = entry
	return entry
end

RunService.Heartbeat:Connect(function()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local cameraPosition = camera.CFrame.Position
	local now = os.clock()
	for _, model in GardenView.PenPets() do
		if model:GetAttribute("FxCount") == 0 then
			continue
		end
		local entry = entryOf(model)
		if entry then
			local distance = (cameraPosition - entry.fx.root.Position).Magnitude
			local far = distance > PetLook.LodDistance - (if entry.far then LOD_HYSTERESIS else 0)
			entry.far = far
			PetLook.UpdateFx(entry.fx, now, far, false)
		end
	end
end)
