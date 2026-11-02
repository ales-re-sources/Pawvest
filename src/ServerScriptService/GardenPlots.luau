-- GardenPlots: borrows one of the garden's plot slots to every player while they are online (docs/GDD.md §7.6). Server-only.
-- A slot is assigned on join (the lowest free one, also while the player is still on the hub) and released on leave.
-- The slot is mirrored to the player attribute GardenConfig.PlotAttribute. Nothing is drawn here: the plots exist only as
-- slots of the formula GardenConfig.PlotCFrame, and every client draws them from GardenRemotes.Plot (E1a1, GardenPlotFeed).
-- PlotChanged(slot, player or nil) fires after an assignment or release.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GardenConfig = require(ReplicatedStorage.GardenConfig)

local assigner = GardenConfig.NewAssigner(GardenConfig.PlotSlots)
local changed = Instance.new("BindableEvent")

local GardenPlots = {}

GardenPlots.PlotChanged = changed.Event

-- Plot slot borrowed by `player`, or nil (none free, or not assigned yet).
function GardenPlots.PlotOf(player: Player): number?
	return assigner.IndexOf(player)
end

-- Player currently borrowing plot slot `slot`, or nil.
function GardenPlots.OwnerOf(slot: number): Player?
	return assigner.KeyOf(slot)
end

local function claim(player: Player)
	local slot = assigner.Claim(player)
	if not slot then
		warn("GardenPlots: no free plot for " .. player.Name .. " (Max Players should be at most " .. GardenConfig.PlotSlots .. ")")
		return
	end
	player:SetAttribute(GardenConfig.PlotAttribute, slot)
	changed:Fire(slot, player)
end

local function release(player: Player)
	local slot = assigner.Release(player)
	if slot then
		changed:Fire(slot, nil)
	end
end

Players.PlayerAdded:Connect(claim)
Players.PlayerRemoving:Connect(release)
for _, player in Players:GetPlayers() do
	claim(player)
end

return GardenPlots
