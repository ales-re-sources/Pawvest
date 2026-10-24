-- GardenPlots: borrows one of the garden's 12 plots to every player while they are online (docs/GDD.md §7.6). Server-only.
-- A plot is assigned on join (the lowest free index, also while the player is still on the hub) and released on leave.
-- The index is mirrored to the player attribute GardenConfig.PlotAttribute; the plot model carries OwnerUserId /
-- OwnerName attributes and its sign shows the owner's name (a "Free plot" key when nobody owns it). The plots themselves
-- (Workspace.Garden.Plots.Plot_01..12) are Studio-only parts and always exist, so every client sees all of them.
-- PlotChanged(index, player or nil) fires after an assignment or release, for systems that draw into the plots.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GardenConfig = require(ReplicatedStorage.GardenConfig)
local Locale = require(ReplicatedStorage.Locale)

local assigner = GardenConfig.NewAssigner(GardenConfig.PlotCount)
local changed = Instance.new("BindableEvent")
local warned = false

local GardenPlots = {}

GardenPlots.PlotChanged = changed.Event

-- Workspace.Garden.Plots.Plot_NN, or nil if the scene lacks it.
function GardenPlots.Model(index: number): Model?
	local garden = workspace:FindFirstChild("Garden")
	local plots = garden and garden:FindFirstChild("Plots")
	local plot = plots and plots:FindFirstChild(GardenConfig.PlotName(index))
	return if plot and plot:IsA("Model") then plot else nil
end

-- Plot index borrowed by `player`, or nil (none free, or not assigned yet).
function GardenPlots.PlotOf(player: Player): number?
	return assigner.IndexOf(player)
end

-- Player currently borrowing plot `index`, or nil.
function GardenPlots.OwnerOf(index: number): Player?
	return assigner.KeyOf(index)
end

local function drawOwner(index: number, owner: Player?)
	local plot = GardenPlots.Model(index)
	if not plot then
		if not warned then
			warned = true
			warn("GardenPlots: Workspace.Garden.Plots." .. GardenConfig.PlotName(index) .. " is missing")
		end
		return
	end
	plot:SetAttribute(GardenConfig.OwnerIdAttribute, if owner then owner.UserId else nil)
	plot:SetAttribute(GardenConfig.OwnerNameAttribute, if owner then owner.Name else nil)
	local sign = plot:FindFirstChild("Sign")
	local label = sign and sign:FindFirstChild("Gui") and sign.Gui:FindFirstChild("Label")
	if label and label:IsA("TextLabel") then
		if owner then
			Locale.SetText(label, owner.Name)
		else
			Locale.SetKey(label, "garden.sign.plotFree")
		end
	end
end

local function claim(player: Player)
	local index = assigner.Claim(player)
	if not index then
		warn("GardenPlots: no free plot for " .. player.Name .. " (Max Players should be " .. GardenConfig.PlotCount .. ")")
		return
	end
	player:SetAttribute(GardenConfig.PlotAttribute, index)
	drawOwner(index, player)
	changed:Fire(index, player)
end

local function release(player: Player)
	local index = assigner.Release(player)
	if index then
		drawOwner(index, nil)
		changed:Fire(index, nil)
	end
end

Players.PlayerAdded:Connect(claim)
Players.PlayerRemoving:Connect(release)
for _, player in Players:GetPlayers() do
	claim(player)
end

-- every plot starts as free (a plot left with an owner by an earlier session of the place would otherwise stay marked)
for index = 1, GardenConfig.PlotCount do
	if not assigner.KeyOf(index) then
		drawOwner(index, nil)
	end
end

return GardenPlots
