-- Bounce bricks (Stage2 Level 12): parts tagged "BounceBrick" with the attribute LaunchSpeed (set by each brick's
-- script) launch the local player's character along the brick's LookVector at exactly that speed on touch, keeping the
-- horizontal speed. The client owns its character's physics, so the launch is immediate and the same every time
-- (the old server-side conveyor Velocity gave anything from ~35 to ~1 000 studs depending on the landing).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local DEBOUNCE = 0.4 -- seconds between two launches from the same brick (a landing touches with several parts)

local LocalPlayer = Players.LocalPlayer
local lastLaunch = {} -- [brick] = os.clock() of the last launch

local function onTouched(brick: BasePart, hit: BasePart)
	local character = LocalPlayer.Character
	if not character or not hit:IsDescendantOf(character) then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and root and humanoid.Health > 0) then
		return
	end
	local now = os.clock()
	if lastLaunch[brick] and now - lastLaunch[brick] < DEBOUNCE then
		return
	end
	local speed = brick:GetAttribute("LaunchSpeed")
	if typeof(speed) ~= "number" then
		return
	end
	lastLaunch[brick] = now
	local velocity = root.AssemblyLinearVelocity
	local up = brick.CFrame.LookVector
	-- replace the velocity along the launch direction, keep the rest (the player's own steering)
	root.AssemblyLinearVelocity = velocity - up * velocity:Dot(up) + up * speed
	humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
end

local function watch(brick: Instance)
	if brick:IsA("BasePart") then
		brick.Touched:Connect(function(hit)
			onTouched(brick, hit)
		end)
	end
end

for _, brick in CollectionService:GetTagged("BounceBrick") do
	watch(brick)
end
CollectionService:GetInstanceAddedSignal("BounceBrick"):Connect(watch)
