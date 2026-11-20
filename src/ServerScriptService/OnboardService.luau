-- OnboardService (E5c): keeps every player's onboarding steps (OnboardConfig) and logs the GardenStart funnel. Server-only.
-- Profile: Onboard (bit mask, mirrored as the player attribute Onboard), OnboardLog (funnel steps logged so far, in order: a step
-- done early is logged once the ones before it are), OnboardDay (UTC day of the first join with onboarding, for "return").
-- A profile without Onboard starts as done (every bit, nothing to log) when it has harvested a crop (a Garden.Crops or a
-- Garden.BestSize entry: profiles from before EV3b have size records but no Crops), else at 0.
-- Steps come from GardenService.Done (Action: Hatch, Plant at CropConfig.StartSquares plantings, Harvest, Sell, BuySeeds / BuyCart,
-- PlacePet), OnboardRemotes.Seen ("quests": the client opened the Goals panel), PlayerTimerHandler (a finished stage),
-- GardenRequests (the first finished request) and the join (a later UTC day than OnboardDay).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local OnboardConfig = require(ReplicatedStorage.OnboardConfig)
local CropConfig = require(ReplicatedStorage.CropConfig)
local TimeFormat = require(ReplicatedStorage.TimeFormat)
local Num = require(ReplicatedStorage.Num)
local PlayerProfile = require(ServerScriptService.PlayerProfile)
local Remotes = require(ServerScriptService.Remotes)
local Telemetry = require(ServerScriptService.Telemetry)

local CLIENT_STEPS = { quests = true } -- steps only the client sees (OnboardRemotes.Seen)
local ACTION_STEPS = { -- GardenService.Done actions → step (Plant: below)
	Hatch = "hatch",
	Harvest = "harvest",
	Sell = "sell",
	BuySeeds = "buySeeds",
	BuyCart = "buySeeds",
	PlacePet = "placePet",
}

local _, remotes = Remotes.Folder("OnboardRemotes", { "Seen" }) -- client → server: (stepId) a client-only step happened

local OnboardService = {}

-- Logs every funnel step whose turn has come (OnboardLog + 1 done, then the next …).
local function logFunnel(player: Player, profile)
	local funnel = OnboardConfig.Funnel
	while profile.OnboardLog < #funnel and OnboardConfig.Has(profile.Onboard, funnel[profile.OnboardLog + 1]) do
		profile.OnboardLog += 1
		Telemetry.GardenStep(player, profile.OnboardLog, funnel[profile.OnboardLog])
	end
end

-- Marks step `id` done for `player` (no-op when it is already done or the profile is not loaded).
function OnboardService.Done(player: Player, id: string)
	local profile = PlayerProfile.Get(player)
	if not (profile and OnboardConfig.Index[id] and Num.Finite(profile.Onboard)) or OnboardConfig.Has(profile.Onboard, id) then
		return
	end
	profile.Onboard = bit32.bor(profile.Onboard, OnboardConfig.Bit(id))
	player:SetAttribute(OnboardConfig.Attribute, profile.Onboard)
	logFunnel(player, profile)
	PlayerProfile.Save(player)
end

-- GardenService.Done: a garden action succeeded.
function OnboardService.Action(player: Player, action: string)
	if action == "Plant" then
		local profile = PlayerProfile.Get(player)
		local garden = profile and type(profile.Garden) == "table" and profile.Garden
		local field = garden and type(garden.Field) == "table" and garden.Field
		if field and Num.Finite(field.Plantings) and field.Plantings >= CropConfig.StartSquares then
			OnboardService.Done(player, "plant")
		end
	elseif ACTION_STEPS[action] then
		OnboardService.Done(player, ACTION_STEPS[action])
	end
end

PlayerProfile.OnReady(function(player, profile)
	local today = TimeFormat.UtcDay(os.time())
	if not Num.Finite(profile.Onboard) then
		local garden = type(profile.Garden) == "table" and profile.Garden
		local grown = garden
			and ((type(garden.Crops) == "table" and next(garden.Crops) ~= nil) or (type(garden.BestSize) == "table" and next(garden.BestSize) ~= nil))
		profile.Onboard = if grown then OnboardConfig.AllMask else 0
		profile.OnboardLog = if grown then #OnboardConfig.Funnel else 0
		profile.OnboardDay = today
	end
	if not Num.Finite(profile.OnboardLog) then
		profile.OnboardLog = 0
	end
	if not Num.Finite(profile.OnboardDay) then
		profile.OnboardDay = today
	end
	player:SetAttribute(OnboardConfig.Attribute, profile.Onboard)
	if today > profile.OnboardDay then
		OnboardService.Done(player, "return")
	end
end)

remotes.Seen.OnServerEvent:Connect(function(player, id)
	if type(id) == "string" and CLIENT_STEPS[id] then
		OnboardService.Done(player, id)
	end
end)

return OnboardService
