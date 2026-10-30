-- PlotViewSpike (E1.0 spike, docs/ROADMAP.md → E1.0): Studio-only data feed of the client-drawn plot prototype (PlotView).
-- Active only in Studio while the Workspace attribute PlotViewSpike is true. Sends every online player's garden as a plain
-- data table to the clients (ReplicatedStorage.PlotViewRemotes.Plot: (userId, state) or (userId, nil) when the player
-- leaves) whenever GardenService publishes that player's state; draws nothing and adds no instance to Workspace.
-- PlotViewRemotes.Request (client → server, no arguments) re-sends every garden to the caller.
-- Message size (JSON bytes of the state) is kept for the measurements in the attributes LastBytes / MaxBytes / Messages
-- of PlotViewRemotes.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local GardenConfig = require(ReplicatedStorage.GardenConfig)
local PetConfig = require(ReplicatedStorage.PetConfig)
local PlayerProfile = require(ServerScriptService.PlayerProfile)
local GardenPlots = require(ServerScriptService.GardenPlots)
local GardenService = require(ServerScriptService.GardenService)

local FLAG = "PlotViewSpike"
local REQUEST_COOLDOWN = 1 -- seconds per player

local remotes = Instance.new("Folder")
remotes.Name = "PlotViewRemotes"
local plotEvent = Instance.new("RemoteEvent")
plotEvent.Name = "Plot"
plotEvent.Parent = remotes
local requestEvent = Instance.new("RemoteEvent")
requestEvent.Name = "Request"
requestEvent.Parent = remotes
remotes.Parent = ReplicatedStorage

local sent = {} -- [Player] = JSON of the last state sent to everyone
local lastRequest = {} -- [Player] = os.clock()

local function active(): boolean
	return RunService:IsStudio() and workspace:GetAttribute(FLAG) == true
end

-- The data a client needs to draw `player`'s plot, or nil (no profile or plot yet).
local function plotState(player: Player)
	local profile = PlayerProfile.Get(player)
	local slot = GardenPlots.PlotOf(player)
	local garden = profile and profile.Garden
	if not (slot and type(garden) == "table") then
		return nil
	end
	local pens = {}
	for n = 1, GardenConfig.MaxPens do
		local uid = type(garden.Pens) == "table" and garden.Pens[tostring(n)]
		local pet = uid and profile.Pets[uid]
		pens[n] = if pet then string.format("%s:%d:%s", pet.Kind, PetConfig.ClampLevel(pet.Level), uid) else ""
	end
	local eggs = {}
	for n = 1, GardenConfig.MaxIncubators do
		local entry = type(garden.Incubators) == "table" and garden.Incubators[tostring(n)]
		eggs[n] = if type(entry) == "table" then string.format("%s:%d", tostring(entry.Egg), entry.ReadyAt or 0) else ""
	end
	return {
		slot = slot,
		name = player.Name,
		penCount = garden.PenCount or 1,
		pens = pens,
		incCount = garden.IncubatorCount or 1,
		eggs = eggs,
	}
end

local function measure(json: string)
	remotes:SetAttribute("LastBytes", #json)
	remotes:SetAttribute("MaxBytes", math.max(remotes:GetAttribute("MaxBytes") or 0, #json))
	remotes:SetAttribute("Messages", (remotes:GetAttribute("Messages") or 0) + 1)
end

-- Sends `player`'s state to every client if it changed (`force`: also when unchanged).
local function broadcast(player: Player, force: boolean?)
	if not active() or player.Parent ~= Players then
		return
	end
	local state = plotState(player)
	if not state then
		return
	end
	local json = HttpService:JSONEncode(state)
	if json == sent[player] and not force then
		return
	end
	sent[player] = json
	measure(json)
	plotEvent:FireAllClients(player.UserId, state)
end

-- GardenService publishes after every garden change: use that as the change signal (adds nothing to the payload)
GardenService.AddStateField("plotView", function(profile)
	if active() then
		for _, player in Players:GetPlayers() do
			if PlayerProfile.Get(player) == profile then
				task.defer(broadcast, player)
			end
		end
	end
	return nil
end)

GardenPlots.PlotChanged:Connect(function(_index, owner)
	if owner then
		task.defer(broadcast, owner, true)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	sent[player] = nil
	lastRequest[player] = nil
	if active() then
		plotEvent:FireAllClients(player.UserId, nil)
	end
end)

requestEvent.OnServerEvent:Connect(function(caller)
	local now = os.clock()
	if not active() or (lastRequest[caller] and now - lastRequest[caller] < REQUEST_COOLDOWN) then
		return
	end
	lastRequest[caller] = now
	for _, player in Players:GetPlayers() do
		local state = plotState(player)
		if state then
			local json = HttpService:JSONEncode(state)
			measure(json)
			plotEvent:FireClient(caller, player.UserId, state)
		end
	end
end)

workspace:GetAttributeChangedSignal(FLAG):Connect(function()
	for _, player in Players:GetPlayers() do
		broadcast(player, true)
	end
end)
