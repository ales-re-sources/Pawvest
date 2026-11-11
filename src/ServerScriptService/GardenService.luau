-- GardenService: the shared plumbing of the pet garden (docs/GDD.md §7.6). Server-only. The P2 pens and their Coin
-- production are gone (FA): a profile from before the field converts once in GardenField. The client only names what it
-- wants; prices, ownership and time come from the sibling modules.
-- Remotes (ReplicatedStorage.GardenRemotes): RequestState() (client → server); State(state), Result(action, ok, detailOrReason)
-- (server → client). Nothing is drawn here: every client draws the plots from GardenRemotes.Plot (GardenPlotFeed, E1a1),
-- which follows every publish.
-- Sibling modules (GardenIncubators, GardenFood, GardenPlotFeed, GardenField) add remotes, State fields and publish hooks
-- through the hooks below.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GardenConfig = require(ReplicatedStorage.GardenConfig)
local Num = require(ReplicatedStorage.Num)
local PlayerProfile = require(ServerScriptService.PlayerProfile)
local PetService = require(ServerScriptService.PetService)
local GardenPlots = require(ServerScriptService.GardenPlots)
local Remotes = require(ServerScriptService.Remotes)
local RateLimit = require(ServerScriptService.RateLimit)

local MAX_DISTANCE = 45 -- studs from the middle of the caller's own plot

-- RequestState: client → server, no arguments; State: server → client (state); Result: server → client (action, ok, detailOrReason)
local remoteFolder, remotes = Remotes.Folder("GardenRemotes", { "RequestState", "State", "Result" })
local stateEvent = remotes.State
local reject, succeed = Remotes.Results(remotes.Result)
local allow = RateLimit.new(0.2) -- seconds between garden requests per player, shared by every garden remote
local stateFields = {} -- { { name, fn(profile) } }: extra fields of the State payload (sibling modules)
local publishHooks = {} -- { fn(player) }: called after every publish (sibling modules)

local GardenService = {}

-- Hooks for the sibling garden modules (GardenIncubators, GardenFood, GardenPlotFeed): they add their remotes to GardenRemotes,
-- share the request rate limit and the plot checks, extend the State payload and follow every publish.
function GardenService.Remote(name: string): RemoteEvent
	return Remotes.Add(remoteFolder, name)
end

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

-- The caller's profile if they may use their plot now: loaded, borrowing a plot and standing near it. Otherwise rejects.
local function usable(player: Player, action: string)
	local profile = PlayerProfile.Get(player)
	if not profile then
		reject(player, action, "loading")
		return nil
	end
	local floor = GardenPlots.FloorCFrame(player) -- from the slot (E1.0), not from the plot model
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

GardenService.Allow = allow
GardenService.Reject = reject
GardenService.Succeed = succeed
GardenService.Usable = usable
GardenService.WholeNumber = Num.Whole -- kept for the garden modules
GardenService.PublishAll = publishAll

-- A garden action went through: everything it touched is re-published, the caller gets the success answer and the profile
-- is saved (the Coins spent and what they bought go together).
function GardenService.Done(player: Player, action: string, detail: any)
	publishAll(player)
	succeed(player, action, detail)
	task.spawn(PlayerProfile.Save, player)
end

-- True when the player's character stands within `distance` studs of the PrimaryPart of the Workspace.Garden model `name`
-- (the seed stall, the food stand); false while it is missing.
function GardenService.NearModel(player: Player, name: string, distance: number): boolean
	local garden = workspace:FindFirstChild("Garden")
	local model = garden and garden:FindFirstChild(name)
	local anchor = model and model:IsA("Model") and model.PrimaryPart
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return anchor ~= nil and root ~= nil and root:IsA("BasePart") and (root.Position - anchor.Position).Magnitude <= distance
end

remotes.RequestState.OnServerEvent:Connect(function(player)
	if not allow(player) then
		return
	end
	publishState(player)
end)

-- Join and admin reset (a reset starts the garden over from now): publishes the garden, then runs the sibling modules'
-- setup (GardenField converts an old profile and settles the field).
PlayerProfile.OnReady(function(player, profile)
	sanitize(profile)
	publishAll(player)
	for _, fn in setupHooks do
		fn(player)
	end
end)

return GardenService
