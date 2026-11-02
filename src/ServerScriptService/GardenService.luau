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
-- A player whose pens were converted into field pet slots (Garden.Converted, E1b, GardenField) has no pens: Place and BuyPen
-- reject them ("field"). Nothing is drawn here: every client draws the plots from GardenRemotes.Plot (GardenPlotFeed, E1a1), which follows every publish.
-- Sibling modules (GardenIncubators, GardenFood, GardenPlotFeed) add remotes, State fields and publish hooks through the hooks below.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GardenConfig = require(ReplicatedStorage.GardenConfig)
local PlayerProfile = require(ServerScriptService.PlayerProfile)
local CoinRewards = require(ServerScriptService.CoinRewards)
local PetService = require(ServerScriptService.PetService)
local GardenPlots = require(ServerScriptService.GardenPlots)

local COOLDOWN = 0.2 -- seconds between garden requests per player
local MAX_DISTANCE = 45 -- studs from the middle of the caller's own plot
local TICK_SECONDS = 30 -- how often online players are checked for a due payout

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
local publishHooks = {} -- { fn(player) }: called after every publish (sibling modules)

local GardenService = {}

-- Hooks for the sibling garden modules (GardenIncubators, GardenFood, GardenPlotFeed): they add their remotes to GardenRemotes,
-- share the request rate limit and the plot checks, extend the State payload and follow every publish.
GardenService.Remote = remote

-- Adds field `name` = fn(profile) to every GardenRemotes.State payload.
function GardenService.AddStateField(name: string, fn: (any) -> any)
	table.insert(stateFields, { name = name, fn = fn })
end

-- Calls fn(player) after every publish of the player's garden (join, admin reset and every change).
function GardenService.AddPublishHook(fn: (Player) -> ())
	table.insert(publishHooks, fn)
end

-- Calls fn(player) once the garden of a joining player (or a reset profile) is cleaned and published.
local setupHooks = {}
function GardenService.AddSetupHook(fn: (Player) -> ())
	table.insert(setupHooks, fn)
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

local function runPublishHooks(player: Player)
	for _, fn in publishHooks do
		fn(player)
	end
end

local function publishAll(player: Player)
	publishState(player)
	PetService.Publish(player) -- the Pets panel marks penned pets
	runPublishHooks(player)
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
	-- the plot's position comes from its slot (GardenConfig.PlotCFrame, E1.0), not from the plot model
	local floor = GardenPlots.PlotOf(player) and GardenConfig.PlotCFrame(GardenPlots.PlotOf(player))
	if not floor then
		reject(player, action, "noplot")
		return nil
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not (root and (root.Position - floor.Position).Magnitude <= MAX_DISTANCE) then
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
	if garden.Converted then
		return reject(player, "Place", "field") -- pens became field pet slots (E1b, GardenField)
	end
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
	if garden.Converted then
		return reject(player, "BuyPen", "field")
	end
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

-- Join: pays the production since the last visit and, for a real absence, queues the "welcome back" announcement.
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
	runPublishHooks(player)
	for _, fn in setupHooks do
		fn(player)
	end
end

-- Admin reset replaced the profile: start the garden over from now.
PlayerProfile.ProfileReset:Connect(function(player)
	local profile = PlayerProfile.Get(player)
	if profile then
		sanitize(profile)
		profile.Garden.LastSeen = os.time()
		pendingPayout[player] = nil
		publishAll(player)
		for _, fn in setupHooks do
			fn(player)
		end
	end
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
