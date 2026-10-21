-- KitGhosts (S3.3b, docs/STAGES.md §5.1 "Ghost others"): where every player sees their own state of the kit (colour plates,
-- crumbling plates, tilt plates, a maze's walls), another player standing in the same spot would seem to float or walk through
-- a wall. Inside a ghost zone the other players are therefore drawn translucent, so nobody is mistaken for solid.
-- A ghost zone is a part tagged "KitGhostZone" (an invisible box, hidden for players, visible in Studio); optional attribute
-- Transparency (default 0.65) sets how faint the others look. Purely cosmetic and local: it changes only the
-- LocalTransparencyModifier of the other players' character parts on this client.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local DEFAULT_TRANSPARENCY = 0.65

local zones = {} -- [part] = true
local ghosted = {} -- [Model] = transparency applied, for characters currently drawn as ghosts

local function addZone(part: Instance)
	if part:IsA("BasePart") then
		zones[part] = true
		part.Transparency = 1
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
	end
end
for _, part in CollectionService:GetTagged("KitGhostZone") do
	addZone(part)
end
CollectionService:GetInstanceAddedSignal("KitGhostZone"):Connect(addZone)
CollectionService:GetInstanceRemovedSignal("KitGhostZone"):Connect(function(part)
	zones[part] = nil
end)

local function setModifier(character: Model, value: number)
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = value
		end
	end
end

-- the faintest-ghost zone value (the highest transparency) of the zones containing `position`, or nil outside all of them
local function zoneTransparency(position: Vector3): number?
	local result: number? = nil
	for zone in zones do
		local local_ = zone.CFrame:PointToObjectSpace(position)
		local half = zone.Size / 2
		if math.abs(local_.X) <= half.X and math.abs(local_.Y) <= half.Y and math.abs(local_.Z) <= half.Z then
			local value = zone:GetAttribute("Transparency")
			value = if type(value) == "number" then value else DEFAULT_TRANSPARENCY
			result = if result then math.max(result, value) else value
		end
	end
	return result
end

RunService.RenderStepped:Connect(function()
	if next(zones) == nil and next(ghosted) == nil then
		return
	end
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local character = other.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local want = if root then zoneTransparency(root.Position) else nil
			local have = if character then ghosted[character] else nil
			if character and want ~= have then
				if want then
					ghosted[character] = want
					setModifier(character, want)
				else
					ghosted[character] = nil
					setModifier(character, 0)
				end
			elseif character and want then
				-- parts added later (accessories, tools) get the same modifier
				for _, descendant in character:GetDescendants() do
					if descendant:IsA("BasePart") and descendant.LocalTransparencyModifier ~= want then
						descendant.LocalTransparencyModifier = want
					end
				end
			end
		end
	end
	for character in ghosted do
		if not character.Parent then
			ghosted[character] = nil
		end
	end
end)
