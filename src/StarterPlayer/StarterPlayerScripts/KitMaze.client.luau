-- KitMaze (S6.2, docs/STAGES.md §7.9): shifting maze walls of the Labyrinth, client-driven like the rest of the kit. Every
-- client derives the same layout from time (KitMath.TimeBase: server time, or the run time for a run-seeded wall), so a
-- wall is where the local player sees it; other players are drawn as ghosts inside a KitGhostZone.
--   KitMazeWall  an upright wall part, authored in its raised pose (thin along its local Z):
--                  Pattern   string of "1" / "0", one per layout step: the wall stands ("1") or is sunk ("0") in that step
--                  Period    seconds per step (default 6); Phase steps the cycle is shifted by (default 0)
--                  Telegraph seconds before a change (default 1.5): a wall about to rise glows as a line on the floor, a
--                            wall about to sink flashes
--                  RunSeeded the cycle starts with the player's run (step 0 at the start)
--                A sunk wall is hidden and not solid; a change takes MOVE_TIME seconds. A rising wall that overlaps the
--                character pushes it out to the nearer side.
-- The layouts are generated and checked for solvability when the maze is built (every layout keeps every cell connected to
-- the exit); this script only plays the pattern.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local KitMath = require(ReplicatedStorage:WaitForChild("KitMath"))

local player = Players.LocalPlayer

local MOVE_TIME = 0.4 -- seconds a wall takes to rise or sink
local GLOW_COLOR = Color3.fromRGB(255, 200, 80)
local GLOW_TOP = 0.15 -- studs the glowing line shows above the floor
local PUSH_CLEARANCE = 1.8 -- studs from the wall face a pushed-out character ends up at
local ACTIVE_DISTANCE = 300 -- studs: walls farther from the character (the camera without one) keep their last pose

local walls = {} -- [part] = { base, color, material, transparency, pattern, pose }
local runStart: number? = nil

local function attr(part: Instance, name: string, default: any): any
	local value = part:GetAttribute(name)
	if value == nil then
		return default
	end
	return value
end

local function addWall(part: Instance)
	if part:IsA("BasePart") then
		local pattern = {}
		for digit in string.gmatch(tostring(attr(part, "Pattern", "1")), "[01]") do
			table.insert(pattern, digit == "1")
		end
		if #pattern == 0 then
			pattern = { true }
		end
		walls[part] = {
			base = part.CFrame,
			color = part.Color,
			material = part.Material,
			transparency = part.Transparency,
			pattern = pattern,
			pose = nil,
		}
	end
end
for _, part in CollectionService:GetTagged("KitMazeWall") do
	addWall(part)
end
CollectionService:GetInstanceAddedSignal("KitMazeWall"):Connect(addWall)
CollectionService:GetInstanceRemovedSignal("KitMazeWall"):Connect(function(part)
	walls[part] = nil
end)

ReplicatedStorage:WaitForChild("StageTimerUpdate").OnClientEvent:Connect(function(elapsed: number)
	runStart = if type(elapsed) == "number" and elapsed >= 0 then workspace:GetServerTimeNow() - elapsed else nil
end)

-- Height share 0..1 and look ("solid" / "flash" / "glow" / "hidden") of a wall at time t.
local function wallState(part: BasePart, data, t: number): (number, string)
	local period = attr(part, "Period", 6)
	local pattern = data.pattern
	local n = #pattern
	local x = t / period + attr(part, "Phase", 0)
	local step = math.floor(x)
	local elapsed = (x - step) * period
	local remaining = period - elapsed
	local up = pattern[step % n + 1]
	local before = pattern[(step - 1) % n + 1]
	local after = pattern[(step + 1) % n + 1]
	local telegraph = attr(part, "Telegraph", 1.5)
	if up then
		local height = if not before and elapsed < MOVE_TIME then KitMath.Smooth(elapsed / MOVE_TIME) else 1
		return height, if not after and remaining <= telegraph then "flash" else "solid"
	end
	if before and elapsed < MOVE_TIME then
		return 1 - KitMath.Smooth(elapsed / MOVE_TIME), "solid"
	end
	return 0, if after and remaining <= telegraph then "glow" else "hidden"
end

RunService.PreSimulation:Connect(function()
	local now = workspace:GetServerTimeNow()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	-- distance from the character: the iso camera hangs about 230 studs away from it
	local camera = workspace.CurrentCamera
	local focus = if root then root.Position elseif camera then camera.CFrame.Position else Vector3.zero
	local flashOn = math.floor(now * 8) % 2 == 0

	for part, data in walls do
		if (data.base.Position - focus).Magnitude > ACTIVE_DISTANCE then
			continue
		end
		local height, look = wallState(part, data, KitMath.TimeBase(now, runStart, attr(part, "RunSeeded", false)))
		local wallHeight = part.Size.Y
		local pose = string.format("%.3f %s %s", height, look, if look == "flash" then tostring(flashOn) else "")
		if pose ~= data.pose then
			data.pose = pose
			if look == "glow" then
				part.CFrame = data.base - Vector3.new(0, wallHeight - GLOW_TOP, 0)
				part.Material = Enum.Material.Neon
				part.Color = GLOW_COLOR
				part.Transparency = 0.25
			else
				part.CFrame = data.base - Vector3.new(0, (1 - height) * (wallHeight + 0.2), 0)
				part.Material = data.material
				part.Color = data.color
				part.Transparency = if look == "hidden" then 1 elseif look == "flash" and flashOn then 0.6 else data.transparency
			end
			part.CanCollide = height > 0 and look ~= "glow"
		end

		-- a wall rising through the character pushes it out to the nearer side
		if root and height > 0 and height < 1 and look == "solid" then
			local offset = data.base:PointToObjectSpace(root.Position)
			local halfLength, halfThick = part.Size.X / 2, part.Size.Z / 2
			if math.abs(offset.X) < halfLength + 1 and math.abs(offset.Z) < halfThick + PUSH_CLEARANCE and math.abs(offset.Y) < wallHeight then
				local side = if offset.Z >= 0 then 1 else -1
				local shift = side * (halfThick + PUSH_CLEARANCE) - offset.Z
				root.CFrame = root.CFrame + data.base:VectorToWorldSpace(Vector3.new(0, 0, shift))
			end
		end
	end
end)
