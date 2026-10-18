-- Pet followers (docs/GDD.md §7.5): every player's equipped pets float behind them, for everyone to see.
-- Display only, on each client: the list comes from the EquippedPets player attribute ("Kind:Level,…", PetService),
-- models are clones of ReplicatedStorage.PetModels, moved locally every frame (no server parts, no physics).
-- Every pet part is anchored with CanCollide / CanTouch / CanQuery off, so pets never push the owner, never fire
-- touch parts (kill parts, coins, portals) and are ignored by raycasts and the camera.
-- The pets of one player hang on one smoothed anchor behind the owner, so they keep their formation (never overlap)
-- while the anchor lags behind turns and jumps.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local PetModels = ReplicatedStorage:WaitForChild("PetModels")

local FOLLOW_SPEED = 8 -- anchor smoothing rate (1/s); higher follows tighter
local SNAP_DISTANCE = 40 -- studs; farther than this (teleport, respawn) the anchor jumps instead of gliding
local HEIGHT = -0.5 -- pet centre relative to the HumanoidRootPart
local BOB_HEIGHT = 0.2
local BOB_SPEED = 2.5
local LABEL_MAX_DISTANCE = 80

-- Formation offsets in the owner's space (+Z = behind) per number of pets; the widest model is 2.4 studs.
local SLOTS = {
	{ Vector3.new(2, 0, 3.5) },
	{ Vector3.new(-1.8, 0, 3.5), Vector3.new(1.8, 0, 3.5) },
	{ Vector3.new(-3.2, 0, 3.5), Vector3.new(0, 0, 4.5), Vector3.new(3.2, 0, 3.5) },
}

local folder = Instance.new("Folder")
folder.Name = "PetFollowers"
folder.Parent = workspace

local followers = {} -- [Player] = { pets = { { key, model, offset, phase } }, anchor = CFrame? }
local warned = {}

-- "Cat:1,Dog:3" → { { kind = "Cat", level = 1, key = "Cat:1" }, … }; unknown kinds are skipped.
local function parse(value): { any }
	local list = {}
	if type(value) ~= "string" then
		return list
	end
	for entry in string.gmatch(value, "[^,]+") do
		local kind, level = string.match(entry, "^(%w+):(%d+)$")
		if kind and PetConfig.RarityOf(kind) then
			level = PetConfig.ClampLevel(tonumber(level))
			table.insert(list, { kind = kind, level = level, key = kind .. ":" .. level })
		end
	end
	return list
end

local function makePet(kind: string, level: number): Model?
	local template = PetModels:FindFirstChild(kind)
	if not (template and template:IsA("Model") and template.PrimaryPart) then
		if not warned[kind] then
			warned[kind] = true
			warn("PetFollow: no model with a PrimaryPart for pet kind " .. kind)
		end
		return nil
	end
	local model = template:Clone()
	local root = model.PrimaryPart
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then -- enforced here too, so a replaced model cannot affect gameplay
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	end

	local rarity = PetConfig.RarityOf(kind)
	local boxCFrame, boxSize = model:GetBoundingBox()
	local top = root.CFrame:PointToObjectSpace(boxCFrame.Position).Y + boxSize.Y / 2

	local label = Instance.new("BillboardGui")
	label.Name = "Label"
	label.Adornee = root
	label.Size = UDim2.new(4, 0, 0.6, 0)
	label.StudsOffset = Vector3.new(0, top + 0.5, 0)
	label.MaxDistance = LABEL_MAX_DISTANCE
	label.LightInfluence = 0
	label.Parent = model
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.Text = kind .. " Lv " .. level
	text.TextColor3 = rarity.color
	text.TextStrokeTransparency = 0.3
	text.Parent = label

	if rarity.order >= PetConfig.RarityById.Epic.order then -- Epic and Legendary glow
		local legendary = rarity.order >= PetConfig.RarityById.Legendary.order
		local light = Instance.new("PointLight")
		light.Color = rarity.color
		light.Brightness = if legendary then 2.5 else 1.5
		light.Range = if legendary then 10 else 8
		light.Parent = root
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Color = ColorSequence.new(rarity.color)
		sparkles.LightEmission = 1
		sparkles.Size = NumberSequence.new(0.25, 0)
		sparkles.Transparency = NumberSequence.new(0.2, 1)
		sparkles.Lifetime = NumberRange.new(0.6, 1)
		sparkles.Rate = if legendary then 10 else 5
		sparkles.Speed = NumberRange.new(0.5, 1.5)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.Parent = root
	end
	return model
end

-- Rebuilds a player's pet list from the attribute; pets that stay (same kind and level) keep their model.
local function refresh(player: Player)
	local state = followers[player]
	if not state then
		return
	end
	local old = state.pets
	local wanted = parse(player:GetAttribute(PetConfig.AttributeName))
	local slots = SLOTS[math.min(#wanted, #SLOTS)]
	local pets = {}
	for index, entry in wanted do
		if index > #SLOTS then
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
			local model = makePet(entry.kind, entry.level)
			pet = model and { key = entry.key, model = model, phase = math.random() * math.pi * 2 }
		end
		if pet then
			pet.offset = slots[index]
			pet.model.Name = player.Name .. "_" .. entry.kind
			table.insert(pets, pet)
		end
	end
	for _, pet in old do
		pet.model:Destroy()
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
			pet.model:Destroy()
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
		for _, pet in state.pets do
			local bob = math.sin(now * BOB_SPEED + pet.phase) * BOB_HEIGHT
			pet.model:PivotTo(anchor * CFrame.new(pet.offset + Vector3.new(0, bob, 0)))
			if pet.model.Parent ~= folder then
				pet.model.Parent = folder
			end
		end
	end
end)
