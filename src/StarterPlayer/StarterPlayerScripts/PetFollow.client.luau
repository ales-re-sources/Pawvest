-- Pet followers (docs/GDD.md §7.5): every player's equipped pets float behind them, for everyone to see.
-- Display only, on each client: the list comes from the EquippedPets player attribute ("Kind:Level:uid,…", PetService),
-- models are clones of ReplicatedStorage.PetModels dressed by PetLook (size by level, label, glow; the garden pens use the
-- same code), moved locally every frame (no server parts, no physics).
-- Every pet part is anchored with CanCollide / CanTouch / CanQuery off (PetLook.Apply), so pets never push the owner, never
-- fire touch parts (kill parts, coins, portals) and are ignored by raycasts and the camera.
-- The pets of one player hang on one smoothed anchor behind the owner, so they keep their formation (never overlap, spacing
-- from the scaled widths: PetLook.Slots) while the anchor lags behind turns and jumps. Pets close to the camera fade out
-- (LocalTransparencyModifier, this client only) so a pet between the camera and its owner never blocks the view.
-- While the local player's stage timer runs (StageTimerUpdate), their pets drop further back and turn ghostly, so the
-- course stays visible.
-- A level-up (same uid, higher level than in the previous list) plays PetLook.LevelUp on that pet, for every viewer: the old
-- model spins up and rises, a flash covers the cross-fade to the new model (this script calls moment:Pose every frame and
-- applies the returned pose and fade); the label shows the tier badge (PetLook.LabelText).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local PetLook = require(ReplicatedStorage:WaitForChild("PetLook"))
local PetModels = ReplicatedStorage:WaitForChild("PetModels")
local StageTimerUpdate = ReplicatedStorage:WaitForChild("StageTimerUpdate")

local FOLLOW_SPEED = 8 -- anchor smoothing rate (1/s); higher follows tighter
local SNAP_DISTANCE = 40 -- studs; farther than this (teleport, respawn) the anchor jumps instead of gliding
local HEIGHT = -0.5 -- pet centre relative to the HumanoidRootPart
local BOB_HEIGHT = 0.2
local BOB_SPEED = 2.5
local LABEL_MAX_DISTANCE = 80
local MAX_PETS = 3
local FADE_FAR = 7 -- studs from the camera to the pet's surface where fading starts
local FADE_NEAR = 2 -- ... and where it is complete
local FADE_MAX = 0.85 -- LocalTransparencyModifier of a fully faded pet
local RUN_BACK = 4 -- extra studs behind the owner while their stage timer runs
local RUN_FADE = 0.6 -- minimum LocalTransparencyModifier of the owner's pets while their stage timer runs
local RUN_BLEND_SPEED = 4 -- how fast the run mode fades in / out (1/s)
local LEVEL_UP_WINDOW = 1 -- seconds a level-up may wait for its model to appear in the world

local running = false -- the local player's stage timer is running
local runBlend = 0 -- 0 = normal formation, 1 = run mode
StageTimerUpdate.OnClientEvent:Connect(function(elapsed)
	running = type(elapsed) == "number" and elapsed >= 0 -- (elapsed, stageKey) = run active; (-1, …) = finished / cancelled
end)

local folder = Instance.new("Folder")
folder.Name = "PetFollowers"
folder.Parent = workspace

local followers = {} -- [Player] = { pets = { { key, model, metrics, parts, fade, offset, phase } }, anchor = CFrame? }
local warned = {}

local function makePet(entry): any?
	local template = PetModels:FindFirstChild(entry.kind)
	if not (template and template:IsA("Model") and template.PrimaryPart) then
		if not warned[entry.kind] then
			warned[entry.kind] = true
			warn("PetFollow: no model with a PrimaryPart for pet kind " .. entry.kind)
		end
		return nil
	end
	local model = template:Clone()
	local metrics = PetLook.Apply(model, entry.kind, entry.level, entry.uid, {
		text = PetLook.LabelText(entry.kind, entry.level),
		size = UDim2.new(6, 0, 0.6, 0),
		maxDistance = LABEL_MAX_DISTANCE,
		gap = 0.5,
	})
	if not metrics then
		model:Destroy()
		return nil
	end
	local parts = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			table.insert(parts, part)
		end
	end
	return {
		key = entry.key,
		kind = entry.kind,
		level = entry.level,
		uid = entry.uid,
		model = model,
		metrics = metrics,
		parts = parts,
		fade = 0,
		phase = math.random() * math.pi * 2,
	}
end

-- Removes a pet for good: a running level-up moment, its old-look ghost (not yet handed to a moment) and the model.
local function discard(pet)
	if pet.moment then
		pet.moment:Cancel()
	end
	if pet.ghost then
		pet.ghost.model:Destroy()
	end
	pet.model:Destroy()
end

-- Rebuilds a player's pet list from the attribute; pets that stay (same kind, level and uid) keep their model.
-- A pet whose uid was already in the list with a lower level has levelled up: its new model plays the level-up moment once
-- (pet.levelUpUntil, started in the Heartbeat as soon as the model is in the world), taking the old model over as the ghost
-- that fades out under the flash (pet.ghost). A uid that is new to the list (join, equip, re-equip) never does.
local function refresh(player: Player)
	local state = followers[player]
	if not state then
		return
	end
	local old = state.pets
	local before = {} -- [uid] = pet record in the previous list
	for _, pet in old do
		if pet.uid then
			before[pet.uid] = pet
		end
	end
	local wanted = PetConfig.DecodeEquipped(player:GetAttribute(PetConfig.AttributeName))
	local pets, metrics = {}, {}
	for index, entry in wanted do
		if index > MAX_PETS then
			break
		end
		local pet
		for i, candidate in old do
			if candidate.key == entry.key then
				pet = table.remove(old, i)
				break
			end
		end
		if not pet then
			pet = makePet(entry)
			local previous = entry.uid and before[entry.uid]
			if pet and previous and entry.level > previous.level then
				pet.levelUpUntil = os.clock() + LEVEL_UP_WINDOW
				local i = table.find(old, previous)
				if i then
					table.remove(old, i) -- its model lives on as the ghost
				end
				if previous.moment then
					previous.moment:Cancel() -- a second level-up during the first moment
					previous.moment = nil
				end
				if previous.ghost then
					previous.ghost.model:Destroy()
					previous.ghost = nil
				end
				pet.ghost = previous
			end
		end
		if pet then
			pet.model.Name = player.Name .. "_" .. entry.kind
			table.insert(pets, pet)
			table.insert(metrics, pet.metrics)
		end
	end
	for _, pet in old do
		discard(pet)
	end
	for index, offset in PetLook.Slots(metrics) do
		pets[index].offset = offset
	end
	state.pets = pets
end

local function track(player: Player)
	if followers[player] then
		return
	end
	followers[player] = { pets = {}, anchor = nil }
	player:GetAttributeChangedSignal(PetConfig.AttributeName):Connect(function()
		refresh(player)
	end)
	refresh(player)
end

local function untrack(player: Player)
	local state = followers[player]
	if state then
		followers[player] = nil
		for _, pet in state.pets do
			discard(pet)
		end
	end
end

Players.PlayerAdded:Connect(track)
Players.PlayerRemoving:Connect(untrack)
for _, player in Players:GetPlayers() do
	track(player)
end

RunService.Heartbeat:Connect(function(dt)
	local now = os.clock()
	local alpha = 1 - math.exp(-FOLLOW_SPEED * dt)
	runBlend += ((if running then 1 else 0) - runBlend) * (1 - math.exp(-RUN_BLEND_SPEED * dt))
	local camera = workspace.CurrentCamera
	local cameraPosition = camera and camera.CFrame.Position
	for player, state in followers do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root or #state.pets == 0 then
			-- no character (dead, respawning, streamed out): hide the pets and jump back on the next spawn
			state.anchor = nil
			for _, pet in state.pets do
				pet.model.Parent = nil
			end
			continue
		end
		local look = root.CFrame.LookVector
		local yaw = math.atan2(-look.X, -look.Z)
		local target = CFrame.new(root.Position + Vector3.new(0, HEIGHT, 0)) * CFrame.Angles(0, yaw, 0)
		local anchor = state.anchor
		if not anchor or (anchor.Position - target.Position).Magnitude > SNAP_DISTANCE then
			anchor = target
		else
			anchor = anchor:Lerp(target, alpha)
		end
		state.anchor = anchor
		local blend = if player == LocalPlayer then runBlend else 0
		for _, pet in state.pets do
			local bob = math.sin(now * BOB_SPEED + pet.phase) * BOB_HEIGHT
			local base = anchor * CFrame.new(pet.offset + Vector3.new(0, bob, RUN_BACK * blend))
			if pet.model.Parent ~= folder then
				pet.model.Parent = folder
			end
			if pet.levelUpUntil then
				-- a pet hidden since its level-up (owner without a character) misses the moment instead of replaying it late
				local ghost = pet.ghost
				pet.ghost = nil
				if os.clock() <= pet.levelUpUntil then
					pet.moment = PetLook.LevelUp(pet.model, pet.kind, pet.level, ghost and ghost.model, ghost and ghost.fade)
				elseif ghost then
					ghost.model:Destroy()
				end
				pet.levelUpUntil = nil
			end
			-- level-up moment: spin and rise on top of the normal pose, the new look fades in under the flash
			local cframe, momentFade = base, 0
			if pet.moment then
				cframe, momentFade = pet.moment:Pose(base)
				if pet.moment.done then
					pet.moment = nil
				end
			end
			pet.model:PivotTo(cframe)

			-- camera fade: the closer the camera is to the pet's surface, the more transparent (client only)
			local fade = 0
			if cameraPosition then
				local distance = (cameraPosition - cframe:PointToWorldSpace(pet.metrics.center)).Magnitude - pet.metrics.size.X / 2
				fade = FADE_MAX * math.clamp((FADE_FAR - distance) / (FADE_FAR - FADE_NEAR), 0, 1)
			end
			fade = math.max(fade, RUN_FADE * blend, momentFade)
			if math.abs(fade - pet.fade) > 0.01 or (fade == 0 and pet.fade ~= 0) then
				pet.fade = fade
				for _, part in pet.parts do
					part.LocalTransparencyModifier = fade
				end
			end
		end
	end
end)
