-- Onboarding (E5c, D5): which onboarding step the local player is on (OnboardConfig; the server keeps the steps in the player
-- attribute Onboard). It teaches by pointing only: the GUI that owns a step's control pulses it while that step is current —
-- IncubatorClient the Hatchery button (hatch), FieldHand Seeds (plant), Basket (harvest) and Pets (placePet), BarnClient the Barn
-- button (sell), GoalsClient the Goals line (quests); this module puts a marker over the seed stall (buySeeds); the stage step uses
-- the next-stage marker (HintSources). Nothing is locked or hidden off the path.
--   Onboarding.Is(id) -> boolean     true while `id` is the current step
--   Onboarding.Changed               fires when the current step changes
--   Onboarding.Seen(id)              tells the server a client-only step happened (OnboardConfig: "quests")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OnboardConfig = require(ReplicatedStorage:WaitForChild("OnboardConfig"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local Hints = require(script.Parent:WaitForChild("Hints"))

local player = Players.LocalPlayer

local STALL_MARKER_HEIGHT = 9 -- studs above the seed stall's PrimaryPart

local changed = Instance.new("BindableEvent")
local current: string? = nil

local Onboarding = {}
Onboarding.Changed = changed.Event

function Onboarding.Is(id: string): boolean
	return current == id
end

function Onboarding.Seen(id: string)
	if current ~= nil and not OnboardConfig.Has(player:GetAttribute(OnboardConfig.Attribute), id) then
		local remotes = ReplicatedStorage:FindFirstChild("OnboardRemotes")
		local seen = remotes and remotes:FindFirstChild("Seen")
		if seen then
			seen:FireServer(id)
		end
	end
end

local function stallAnchor(): BasePart?
	local garden = workspace:FindFirstChild("Garden")
	local stall = garden and garden:FindFirstChild("SeedStall")
	return if stall and stall:IsA("Model") then stall.PrimaryPart else nil
end

local function update()
	local step = OnboardConfig.Current(player:GetAttribute(OnboardConfig.Attribute))
	if step == current then
		return
	end
	current = step
	Hints.SetMarker("onboard.stall", if step == "buySeeds" then stallAnchor() else nil, function()
		return Locale.T("hints.buySeeds")
	end, STALL_MARKER_HEIGHT)
	changed:Fire(step)
end

player:GetAttributeChangedSignal(OnboardConfig.Attribute):Connect(update)
task.defer(update)

return Onboarding
