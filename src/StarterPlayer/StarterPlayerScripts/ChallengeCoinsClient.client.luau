-- Challenge coins on this client (docs/GDD.md §5): hides the coins the local player has collected (the server-owned
-- CollectedCoins attribute) and spins the others. Everything here is local, so other players keep seeing a coin until
-- they collect it themselves. A hidden coin also stops touching locally, so it sends the server no more touches.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ChallengeCoinConfig = require(ReplicatedStorage:WaitForChild("ChallengeCoinConfig"))

local SPIN_SPEED = math.rad(90) -- per second, around the world Y axis

local LocalPlayer = Players.LocalPlayer

local coins = {} -- [part] = { base = CFrame, transparency = number, hidden = boolean }
local collected = nil -- set [id] = true; nil until the server publishes it (all coins hidden until then)

local function setEffects(part: BasePart, enabled: boolean)
	for _, effect in part:GetDescendants() do
		if effect:IsA("Highlight") or effect:IsA("ParticleEmitter") or effect:IsA("Light") or effect:IsA("BillboardGui") then
			effect.Enabled = enabled
		end
	end
end

local function refreshCoin(part: BasePart)
	local state = coins[part]
	local hidden = not collected or collected[part:GetAttribute(ChallengeCoinConfig.IdAttribute)] == true
	if not state or state.hidden == hidden then
		return
	end
	state.hidden = hidden
	part.Transparency = if hidden then 1 else state.transparency
	part.CanTouch = not hidden
	part.CanQuery = not hidden
	setEffects(part, not hidden)
end

local function addCoin(part: Instance)
	if not part:IsA("BasePart") or coins[part] then
		return
	end
	coins[part] = { base = part.CFrame, transparency = part.Transparency, hidden = false }
	refreshCoin(part)
end

local function refreshAll()
	local text = LocalPlayer:GetAttribute(ChallengeCoinConfig.CollectedAttribute)
	collected = if text ~= nil then ChallengeCoinConfig.Decode(text) else nil
	for part in coins do
		refreshCoin(part)
	end
end

for _, part in CollectionService:GetTagged(ChallengeCoinConfig.Tag) do
	addCoin(part)
end
CollectionService:GetInstanceAddedSignal(ChallengeCoinConfig.Tag):Connect(addCoin)
CollectionService:GetInstanceRemovedSignal(ChallengeCoinConfig.Tag):Connect(function(part)
	coins[part] = nil
end)

LocalPlayer:GetAttributeChangedSignal(ChallengeCoinConfig.CollectedAttribute):Connect(refreshAll)
refreshAll()

RunService.RenderStepped:Connect(function()
	local angle = (os.clock() * SPIN_SPEED) % (2 * math.pi)
	local spin = CFrame.Angles(0, angle, 0)
	for part, state in coins do
		if not state.hidden then
			part.CFrame = CFrame.new(state.base.Position) * spin * state.base.Rotation
		end
	end
end)
