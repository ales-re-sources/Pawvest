-- GardenService: the shared plumbing of the pet garden (docs/GDD.md §7.6). Server-only. The P2 pens and their Coin
-- production are gone (FA): a profile from before the field converts once in GardenField. The client only names what it
-- wants; prices, ownership and time come from the sibling modules.
-- Remotes (ReplicatedStorage.GardenRemotes): RequestState() (client → server); State(state), Result(action, ok, detailOrReason)
-- (server → client). Nothing is drawn here: every client draws the plots from GardenRemotes.Plot (GardenPlotFeed, E1a1),
-- which follows every publish.
-- Sibling modules (GardenIncubators, GardenFood, GardenPlotFeed, GardenField) add remotes, State fields and publish hooks
-- through the hooks below.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GardenConfig = require(ReplicatedStorage.GardenConfig)
local PlayerProfile = require(ServerScriptService.PlayerProfile)
local PetService = require(ServerScriptService.PetService)
local GardenPlots = require(ServerScriptService.GardenPlots)

local COOLDOWN = 0.2 -- seconds between garden requests per player
local MAX_DISTANCE = 45 -- studs from the middle of the caller's own plot

local remotes = Instance.new("Folder")
remotes.Name = "GardenRemotes"
local function remote(name: string): RemoteEvent
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = remotes
	return event
end
local requestStateEvent = remote("RequestState") -- client → server, no arguments
local stateEvent = remote("State") -- server → client: (state)
local resultEvent = remote("Result") -- server → client: (action, ok: boolean, detailOrReason)
remotes.Parent = ReplicatedStorage

local lastRequest = {} -- [Player] = os.clock() of the last accepted request
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

-- A garden table to work with (an old or hand-edited record may lack one).
local function sanitize(profile)
	if type(profile.Garden) ~= "table" then
		profile.Garden = {}
	end
end

local function publishState(player: Player)
	local profile = PlayerProfile.Get(player)
	if not profile then
		return
	end
	local state = {}
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
	PetService.Publish(player) -- the Pets panel marks field pets
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

local function succeed(player: Player, action: string, detail: any)
	resultEvent:FireClient(player, action, true, detail)
end

GardenService.Allow = allow
GardenService.Reject = reject
GardenService.Succeed = succeed
GardenService.Usable = usable
GardenService.WholeNumber = wholeNumber
GardenService.PublishAll = publishAll

requestStateEvent.OnServerEvent:Connect(function(player)
	if not allow(player) then
		return
	end
	publishState(player)
end)

-- Join: publishes the garden, then runs the sibling modules' setup (GardenField converts an old profile and settles the field).
local function setup(player: Player)
	local profile = PlayerProfile.WaitFor(player)
	if not profile then
		return
	end
	sanitize(profile)
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
end)

return GardenService
