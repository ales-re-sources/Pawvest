-- GardenPlots: borrows one of the garden's plot slots to every player while they are online (docs/GDD.md §7.6). Server-only.
-- A slot is assigned on join (the lowest free one, before the garden arrival) and released on leave.
-- The slot is mirrored to the player attribute GardenConfig.PlotAttribute. Nothing is drawn here: the plots exist only as
-- slots of the formula GardenConfig.PlotCFrame, and every client draws them from GardenRemotes.Plot (E1a1, GardenPlotFeed).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GardenConfig = require(ReplicatedStorage.GardenConfig)

local assigner = GardenConfig.NewAssigner(GardenConfig.PlotSlots)

local GardenPlots = {}

-- In front of the plot sign, looking towards the field; shared by join spawns and the Home shortcut.
local ARRIVAL_OFFSET = Vector3.new(8, 0, -35.5) -- FX: 8 studs in front of the sign (PlotView z -27.5; was -30 / -22)

-- Plot slot borrowed by `player`, or nil (none free, or not assigned yet).
function GardenPlots.PlotOf(player: Player): number?
	return assigner.IndexOf(player)
end

-- The floor CFrame of the plot `player` borrows (from its slot: GardenConfig.PlotCFrame, no plot model, E1.0), or nil.
function GardenPlots.FloorCFrame(player: Player): CFrame?
	local slot = assigner.IndexOf(player)
	return if slot then GardenConfig.PlotCFrame(slot) else nil
end

function GardenPlots.ArrivalCFrame(player: Player): CFrame?
	local floor = GardenPlots.FloorCFrame(player)
	if not floor then
		return nil
	end
	local position = floor:PointToWorldSpace(ARRIVAL_OFFSET) + Vector3.new(0, 5, 0)
	local centre = floor.Position
	return CFrame.lookAt(position, Vector3.new(centre.X, position.Y, centre.Z))
end

local function claim(player: Player)
	local slot = assigner.Claim(player)
	if not slot then
		warn("GardenPlots: no free plot for " .. player.Name .. " (Max Players should be at most " .. GardenConfig.PlotSlots .. ")")
		return
	end
	player:SetAttribute(GardenConfig.PlotAttribute, slot)
end

local function release(player: Player)
	assigner.Release(player)
end

Players.PlayerAdded:Connect(claim)
Players.PlayerRemoving:Connect(release)
for _, player in Players:GetPlayers() do
	claim(player)
end

return GardenPlots
