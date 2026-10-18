-- GardenService: pens, production and offline income of the pet garden (docs/GDD.md §7.6). Server-only.
-- State lives in PlayerProfile.Garden = { Pens = { ["1".."6"] = uid }, PenCount, LastSeen, Carry }. The client only names
-- what it wants (pen index, pet uid, expected pen number); prices, ownership and time come from here: production is
-- computed from the server's os.time() and LastSeen only, and no remote carries a time.
-- Production is "settled" (paid through CoinRewards.Grant, so the pet bonus applies) on join, every PayoutSeconds while
-- online, and before every change to the pens, so a pen never earns for time it was empty. LastSeen is the moment up to
-- which production was paid; time since LastSeen is capped at OfflineCapSeconds. Leaving does not settle: LastSeen stays at
-- the last settle and the next join pays the rest (capped).
-- Remotes (ReplicatedStorage.GardenRemotes): Place(penIndex, uid), Remove(penIndex), BuyPen(expectedPen), RequestState()
-- (client → server); State(state), Result(action, ok, detailOrReason), Payout(info) (server → client).
-- The plots are drawn here from the profile: pad colour, "Info" text and the pet models of Workspace.Garden.Plots.Plot_NN.Pen_n.
-- Sibling modules (GardenIncubators, GardenFood) add remotes, State fields and plot drawing through the hooks below.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GardenConfig = require(ReplicatedStorage.GardenConfig)
local PetConfig = require(ReplicatedStorage.PetConfig)
local PlayerProfile = require(ServerScriptService.PlayerProfile)
local CoinRewards = require(ServerScriptService.CoinRewards)
local PetService = require(ServerScriptService.PetService)
local GardenPlots = require(ServerScriptService.GardenPlots)

local COOLDOWN = 0.2 -- seconds between garden requests per player
local MAX_DISTANCE = 45 -- studs from the middle of the caller's own plot
local TICK_SECONDS = 30 -- how often online players are checked for a due payout

local PAD_COLORS = {
	free = Color3.fromRGB(150, 150, 150),
	locked = Color3.fromRGB(80, 80, 80),
	empty = Color3.fromRGB(110, 190, 110),
}

local remotes = Instance.new("Folder")
remotes.Name = "GardenRemotes"
local function remote(name: string): RemoteEvent
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = remotes
	return event
end
local placeEvent = remote("Place") -- client → server: (penIndex: number, uid: string)
local removeEvent = remote("Remove") -- client → server: (penIndex: number)
local buyPenEvent = remote("BuyPen") -- client → server: (expectedPen: number)
local requestStateEvent = remote("RequestState") -- client → server, no arguments
local stateEvent = remote("State") -- server → client: (state)
local resultEvent = remote("Result") -- server → client: (action, ok: boolean, detailOrReason)
local payoutEvent = remote("Payout") -- server → client: (info)
remotes.Parent = ReplicatedStorage

local lastRequest = {} -- [Player] = os.clock() of the last accepted request
local pendingPayout = {} -- [Player] = join payout waiting for the client popup
local payoutId = 0
local stateFields = {} -- { { name, fn(profile) } }: extra fields of the State payload (sibling modules)
local renderers = {} -- { fn(index, plot, profile?) }: extra drawing of a plot (sibling modules)

local GardenService = {}

-- Hooks for the sibling garden modules (GardenIncubators, GardenFood): they add their remotes to GardenRemotes, share the
-- request rate limit and the plot checks, and extend the State payload and the plot drawing.
GardenService.Remote = remote

-- Adds field `name` = fn(profile) to every GardenRemotes.State payload.
function GardenService.AddStateField(name: string, fn: (any) -> any)
	table.insert(stateFields, { name = name, fn = fn })
end

-- Calls fn(index, plot, profile or nil) whenever plot `index` is drawn.
function GardenService.AddRenderer(fn: (number, Model, any) -> ())
	table.insert(renderers, fn)
end

-- Cleans whatever is stored: pen count, carry, LastSeen, and pens that name a missing, duplicate or out-of-range pet.
local function sanitize(profile)
	local garden = profile.Garden
	if type(garden) ~= "table" then
		garden = {}
		profile.Garden = garden
	end
	local penCount = if type(garden.PenCount) == "number" and garden.PenCount == garden.PenCount then garden.PenCount else 1
	garden.PenCount = math.clamp(math.floor(penCount), 1, GardenConfig.MaxPens)
	local carry = if type(garden.Carry) == "number" and garden.Carry == garden.Carry then garden.Carry else 0
	garden.Carry = math.max(0, math.floor(carry))
	if type(garden.LastSeen) ~= "number" or garden.LastSeen ~= garden.LastSeen then
		garden.LastSeen = nil
	end
	local pens, used = {}, {}
	if type(garden.Pens) == "table" then
		for key, uid in garden.Pens do
			local index = tonumber(key)
			if
				index
				and index == math.floor(index)
				and index >= 1
				and index <= garden.PenCount
				and type(uid) == "string"
				and profile.Pets[uid]
				and not used[uid]
			then
				pens[tostring(index)] = uid
				used[uid] = true
			end
		end
	end
	garden.Pens = pens
end

-- Units (GardenConfig.Units) of all penned pets.
local function totalUnits(profile): number
	local units = 0
	for _, uid in profile.Garden.Pens do
		local pet = profile.Pets[uid]
		if pet then
			units += GardenConfig.Units(pet)
		end
	end
	return units
end

-- Pays the production since LastSeen (at most the offline cap) and moves LastSeen to now. A missing or future LastSeen
-- pays nothing. Returns { seconds, base, paid, capped } or nil if the profile is not loaded.
local function settle(player: Player)
	local profile = PlayerProfile.Get(player)
	if not profile then
		return nil
	end
	local garden = profile.Garden
	local now = os.time()
	local last = garden.LastSeen
	local gap = if type(last) == "number" and last <= now then now - last else 0
	local seconds = math.min(gap, GardenConfig.OfflineCapSeconds)
	local base, carry = GardenConfig.Settle(totalUnits(profile), garden.Carry, seconds)
	garden.Carry = carry
	garden.LastSeen = now
	local paid = if base > 0 then (CoinRewards.Grant(player, base, "garden") or 0) else 0
	return { seconds = seconds, base = base, paid = paid, capped = gap > GardenConfig.OfflineCapSeconds }
end
GardenService.Settle = settle

local function sendPayout(player: Player, info, away: boolean)
	payoutId += 1
	info.id = payoutId
	info.away = away
	if away then
		pendingPayout[player] = info
	end
	payoutEvent:FireClient(player, info)
end

local function publishState(player: Player)
	local profile = PlayerProfile.Get(player)
	if not profile then
		return
	end
	local state = {
		pens = profile.Garden.Pens,
		penCount = profile.Garden.PenCount,
		rate = totalUnits(profile) / 1000,
	}
	for _, field in stateFields do
		state[field.name] = field.fn(profile)
	end
	stateEvent:FireClient(player, state)
end
GardenService.PublishState = publishState

-- Pet model for a pen: a clone of ReplicatedStorage.PetModels (anchored, no collision / touch / query), a two-line label
-- in the rarity colour and the Epic / Legendary glow, as PetFollow draws it.
local function makePenPet(pet, pad: BasePart): Model?
	local template = ReplicatedStorage:FindFirstChild("PetModels") and ReplicatedStorage.PetModels:FindFirstChild(pet.Kind)
	if not (template and template:IsA("Model") and template.PrimaryPart) then
		return nil
	end
	local model = template:Clone()
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	end
	local rarity = PetConfig.RarityOf(pet.Kind)
	local root = model.PrimaryPart
	model:PivotTo(pad.CFrame * CFrame.new(0, pad.Size.Y / 2 + 1, 0))
	-- stand the model on the pad: move it so the lowest point of its bounding box touches the pad top
	local boxCFrame, boxSize = model:GetBoundingBox()
	local bottom = boxCFrame.Position.Y - boxSize.Y / 2
	model:PivotTo(model:GetPivot() + Vector3.new(0, pad.Position.Y + pad.Size.Y / 2 - bottom, 0))
	boxCFrame, boxSize = model:GetBoundingBox()

	local label = Instance.new("BillboardGui")
	label.Name = "Label"
	label.Adornee = root
	label.Size = UDim2.new(6, 0, 1.4, 0)
	label.StudsOffset = Vector3.new(0, boxCFrame.Position.Y + boxSize.Y / 2 - root.Position.Y + 1, 0)
	label.MaxDistance = 90
	label.LightInfluence = 0
	label.Parent = model
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.RichText = true
	text.Text = string.format(
		"%s Lv %d\n<font color='#a8e6a0'>%s Coins/h</font>",
		pet.Kind,
		PetConfig.ClampLevel(pet.Level),
		string.format("%g", GardenConfig.RatePerHour(pet))
	)
	text.TextColor3 = rarity.color
	text.TextStrokeTransparency = 0.3
	text.Parent = label

	if rarity.order >= PetConfig.RarityById.Epic.order then
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

-- Draws plot `index` from its owner's profile (a free plot, or an owner whose profile is still loading, shows neutral pens).
-- Each pen model gets attributes State ("free" / "locked" / "empty" / "pet"), Uid, Kind, Level for the client and for tests.
local function renderPlot(index: number)
	local plot = GardenPlots.Model(index)
	if not plot then
		return
	end
	local owner = GardenPlots.OwnerOf(index)
	local profile = owner and PlayerProfile.Get(owner)
	local pets = plot:FindFirstChild("PenPets")
	if not pets then
		pets = Instance.new("Folder")
		pets.Name = "PenPets"
		pets.Parent = plot
	end
	pets:ClearAllChildren()

	for number = 1, GardenConfig.MaxPens do
		local pen = plot:FindFirstChild(GardenConfig.PenNamePrefix .. number)
		local pad = pen and pen:FindFirstChild("Pad")
		if not (pad and pad:IsA("BasePart")) then
			continue
		end
		local info = pad:FindFirstChild("Info")
		local text = info and info:FindFirstChildOfClass("TextLabel")
		local uid = profile and profile.Garden.Pens[tostring(number)]
		local pet = uid and profile.Pets[uid]

		local state = "free"
		if profile then
			state = if pet then "pet" elseif number > profile.Garden.PenCount then "locked" else "empty"
		end
		pen:SetAttribute("State", state)
		pen:SetAttribute("Uid", if pet then uid else nil)
		pen:SetAttribute("Kind", if pet then pet.Kind else nil)
		pen:SetAttribute("Level", if pet then PetConfig.ClampLevel(pet.Level) else nil)

		local color = PAD_COLORS[state]
		local model = nil
		if pet then
			local rarity = PetConfig.RarityOf(pet.Kind)
			color = PAD_COLORS.empty:Lerp(rarity.color, 0.45)
			model = makePenPet(pet, pad)
			if model then
				model.Name = GardenConfig.PenNamePrefix .. number .. "_" .. pet.Kind
				model.Parent = pets
			end
		end
		pad.Color = color
		if info and info:IsA("BillboardGui") then
			info.Enabled = state == "locked" or state == "empty"
		end
		if text then
			text.Text = if state == "locked" then "🔒 Pen " .. number elseif state == "empty" then "Pen " .. number .. "\nempty" else ""
		end
	end

	for _, render in renderers do
		render(index, plot, profile)
	end
end
GardenService.RenderPlot = renderPlot

local function renderPlayer(player: Player)
	local index = GardenPlots.PlotOf(player)
	if index then
		renderPlot(index)
	end
end

local function publishAll(player: Player)
	publishState(player)
	PetService.Publish(player) -- the Pets panel marks penned pets
	renderPlayer(player)
end

-- Per-player rate limit shared by the garden remotes; true if the request may proceed.
local function allow(player: Player): boolean
	local now = os.clock()
	if lastRequest[player] and now - lastRequest[player] < COOLDOWN then
		return false
	end
	lastRequest[player] = now
	return true
end

local function reject(player: Player, action: string, reason: string)
	resultEvent:FireClient(player, action, false, reason)
end

-- The caller's profile if they may use their plot now: loaded, borrowing a plot and standing near it. Otherwise rejects.
local function usable(player: Player, action: string)
	local profile = PlayerProfile.Get(player)
	if not profile then
		reject(player, action, "loading")
		return nil
	end
	local plot = GardenPlots.PlotOf(player) and GardenPlots.Model(GardenPlots.PlotOf(player))
	if not plot then
		reject(player, action, "noplot")
		return nil
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not (root and plot.PrimaryPart and (root.Position - plot.PrimaryPart.Position).Magnitude <= MAX_DISTANCE) then
		reject(player, action, "far")
		return nil
	end
	return profile
end

local function wholeNumber(value: any): boolean
	return type(value) == "number" and value == math.floor(value) and math.abs(value) < 1e6
end

-- Settles and tells the client about a payout that came out of it (a small toast).
local function settleAndNotify(player: Player)
	local info = settle(player)
	if info and info.paid > 0 then
		sendPayout(player, info, false)
	end
end

local function succeed(player: Player, action: string, detail: any)
	resultEvent:FireClient(player, action, true, detail)
end

GardenService.Allow = allow
GardenService.Reject = reject
GardenService.Succeed = succeed
GardenService.Usable = usable
GardenService.WholeNumber = wholeNumber
GardenService.SettleAndNotify = settleAndNotify
GardenService.PublishAll = publishAll

placeEvent.OnServerEvent:Connect(function(player, penIndex, uid)
	if not wholeNumber(penIndex) or type(uid) ~= "string" or not allow(player) then
		return
	end
	local profile = usable(player, "Place")
	if not profile then
		return
	end
	local garden = profile.Garden
	if penIndex < 1 or penIndex > garden.PenCount then
		return reject(player, "Place", "locked")
	end
	if garden.Pens[tostring(penIndex)] then
		return reject(player, "Place", "occupied")
	end
	if not profile.Pets[uid] then
		return
	end
	if table.find(profile.EquippedPets, uid) then
		return reject(player, "Place", "equipped")
	end
	if GardenConfig.IsPenned(profile, uid) then
		return reject(player, "Place", "penned")
	end

	settleAndNotify(player) -- the pen was empty until now: no production for the past
	garden.Pens[tostring(penIndex)] = uid
	publishAll(player)
	resultEvent:FireClient(player, "Place", true, { pen = penIndex, uid = uid })
	task.spawn(PlayerProfile.Save, player)
end)

removeEvent.OnServerEvent:Connect(function(player, penIndex)
	if not wholeNumber(penIndex) or not allow(player) then
		return
	end
	local profile = usable(player, "Remove")
	if not profile then
		return
	end
	local uid = profile.Garden.Pens[tostring(penIndex)]
	if not uid then
		return
	end

	settleAndNotify(player) -- pays what the pet produced up to now
	profile.Garden.Pens[tostring(penIndex)] = nil
	publishAll(player)
	resultEvent:FireClient(player, "Remove", true, { pen = penIndex, uid = uid })
	task.spawn(PlayerProfile.Save, player)
end)

buyPenEvent.OnServerEvent:Connect(function(player, expectedPen)
	if not wholeNumber(expectedPen) or not allow(player) then
		return
	end
	local profile = usable(player, "BuyPen")
	if not profile then
		return
	end
	local garden = profile.Garden
	if garden.PenCount >= GardenConfig.MaxPens then
		return reject(player, "BuyPen", "maxed")
	end
	if expectedPen ~= garden.PenCount + 1 then
		return reject(player, "BuyPen", "stale") -- out-of-date panel, double click or forged request
	end
	local price = GardenConfig.PenPrices[expectedPen]
	if profile.Coins < price then
		return reject(player, "BuyPen", "coins")
	end

	settleAndNotify(player) -- the new pen starts empty; nothing is owed for the past
	PlayerProfile.AddCoins(player, -price)
	garden.PenCount = expectedPen
	publishAll(player)
	resultEvent:FireClient(player, "BuyPen", true, expectedPen)
	task.spawn(PlayerProfile.Save, player)
end)

requestStateEvent.OnServerEvent:Connect(function(player)
	if not allow(player) then
		return
	end
	publishState(player)
	if pendingPayout[player] then
		payoutEvent:FireClient(player, pendingPayout[player]) -- same id: the client shows each join payout once
	end
end)

-- Join: pays the production since the last visit and, for a real absence, queues the "while you were away" popup.
local function setup(player: Player)
	local profile = PlayerProfile.WaitFor(player)
	if not profile then
		return
	end
	sanitize(profile)
	local info = settle(player)
	if info and info.seconds >= GardenConfig.MinAwaySeconds and info.base > 0 then
		sendPayout(player, info, true)
	end
	publishState(player)
	renderPlayer(player)
end

-- Admin reset replaced the profile: start the garden over from now.
PlayerProfile.ProfileReset:Connect(function(player)
	local profile = PlayerProfile.Get(player)
	if profile then
		sanitize(profile)
		profile.Garden.LastSeen = os.time()
		pendingPayout[player] = nil
		publishAll(player)
	end
end)

GardenPlots.PlotChanged:Connect(function(index)
	renderPlot(index)
end)

Players.PlayerAdded:Connect(setup)
for _, player in Players:GetPlayers() do
	task.spawn(setup, player)
end

Players.PlayerRemoving:Connect(function(player)
	lastRequest[player] = nil
	pendingPayout[player] = nil
end)

-- Online payouts: everyone whose production is due (LastSeen is at least PayoutSeconds old).
task.spawn(function()
	while true do
		task.wait(TICK_SECONDS)
		local now = os.time()
		for _, player in Players:GetPlayers() do
			local profile = PlayerProfile.Get(player)
			local last = profile and profile.Garden and profile.Garden.LastSeen
			if type(last) == "number" and now - last >= GardenConfig.PayoutSeconds then
				settleAndNotify(player)
			end
		end
	end
end)

return GardenService
