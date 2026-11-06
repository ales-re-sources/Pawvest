-- GardenPlotFeed (E1a1, docs/EXPANSION.md §16): sends every online player's plot as a plain data table to every client, which
-- draws it (GardenView / PlotView); the server adds no instance to Workspace. Server-only.
-- GardenRemotes.Plot (server → client): (userId, state) after every publish of that player's garden (only when the state
-- changed) and (userId, nil) when the player leaves. GardenRemotes.RequestPlots (client → server, no arguments) re-sends every
-- plot to the caller (a client that was still loading missed the broadcasts); 1 s cooldown.
-- State: { slot, name, incCount, eggs = { [1..3] = "EggId:readyAt" or "" }, field = GardenField.PlotField or nil } (readyAt in
-- server os.time(), for the countdowns only).

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GardenConfig = require(ReplicatedStorage.GardenConfig)
local PlayerProfile = require(ServerScriptService.PlayerProfile)
local GardenPlots = require(ServerScriptService.GardenPlots)
local GardenService = require(ServerScriptService.GardenService)
local GardenField = require(ServerScriptService.GardenField)

local REQUEST_COOLDOWN = 1 -- seconds per player

local plotEvent = GardenService.Remote("Plot") -- server → client: (userId, state or nil)
local requestEvent = GardenService.Remote("RequestPlots") -- client → server, no arguments

local sent = {} -- [Player] = JSON of the last state sent to everyone
local lastRequest = {} -- [Player] = os.clock()

local GardenPlotFeed = {}

-- The data a client needs to draw `player`'s plot, or nil (no profile, garden or slot yet).
local function plotState(player: Player)
	local profile = PlayerProfile.Get(player)
	local slot = GardenPlots.PlotOf(player)
	local garden = profile and profile.Garden
	if not (slot and type(garden) == "table") then
		return nil
	end
	local eggs = {}
	for n = 1, GardenConfig.MaxIncubators do
		local entry = type(garden.Incubators) == "table" and garden.Incubators[tostring(n)]
		eggs[n] = if type(entry) == "table" then string.format("%s:%d", tostring(entry.Egg), entry.ReadyAt or 0) else ""
	end
	return {
		slot = slot,
		name = player.Name,
		incCount = garden.IncubatorCount or 1,
		eggs = eggs,
		field = GardenField.PlotField(player),
	}
end
GardenPlotFeed.PlotState = plotState

-- Sends `state` of `owner` to `viewer`.
local function send(viewer: Player, owner: Player, state)
	plotEvent:FireClient(viewer, owner.UserId, state)
end

-- Sends `player`'s state to every client if it changed since the last broadcast.
local function broadcast(player: Player)
	if player.Parent ~= Players then
		return
	end
	local state = plotState(player)
	if not state then
		return
	end
	local json = HttpService:JSONEncode(state)
	if json == sent[player] then
		return
	end
	sent[player] = json
	for _, viewer in Players:GetPlayers() do
		send(viewer, player, state)
	end
end

GardenService.AddPublishHook(function(player)
	task.defer(broadcast, player) -- after the publishing handler finished its changes
end)

Players.PlayerRemoving:Connect(function(player)
	sent[player] = nil
	lastRequest[player] = nil
	plotEvent:FireAllClients(player.UserId, nil)
end)

requestEvent.OnServerEvent:Connect(function(caller)
	local now = os.clock()
	if lastRequest[caller] and now - lastRequest[caller] < REQUEST_COOLDOWN then
		return
	end
	lastRequest[caller] = now
	for _, player in Players:GetPlayers() do
		local state = plotState(player)
		if state then
			send(caller, player, state)
		end
	end
end)

return GardenPlotFeed
