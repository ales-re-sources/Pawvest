-- RunDistance: horizontal distance a player's character covers during a stage run, measured on the server for
-- movement pet XP (docs/GDD.md §7.4). Server-only. PlayerTimerHandler calls Start when a run starts and Stop when it
-- finishes or is cancelled; nothing is measured outside a run, so walking in the hub earns nothing.
-- The root part is sampled every SAMPLE_SECONDS; a step longer than the character could walk in that time
-- (teleports, respawns, flings) is dropped entirely, not capped.

local Players = game:GetService("Players")

local SAMPLE_SECONDS = 0.25
local SPEED_TOLERANCE = 1.5 -- × Humanoid.WalkSpeed: replication jitter delivers positions unevenly
local STEP_SLACK = 1 -- studs added to the allowed step

local runs = {} -- [Player] = { studs = number, last = Vector3?, lastClock = number }

local RunDistance = {}

-- Starts (or restarts) measuring from zero.
function RunDistance.Start(player: Player)
	runs[player] = { studs = 0, last = nil, lastClock = 0 }
end

-- Stops measuring and returns the studs covered since Start (0 without a run).
function RunDistance.Stop(player: Player): number
	local run = runs[player]
	runs[player] = nil
	return if run then run.studs else 0
end

local function sample(player: Player, run)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = humanoid and humanoid.RootPart
	if not (root and humanoid.Health > 0) then
		run.last = nil -- dead or respawning: the next position starts a new segment
		return
	end
	local now = os.clock()
	local position = root.Position
	if run.last then
		local step = Vector3.new(position.X - run.last.X, 0, position.Z - run.last.Z).Magnitude
		local allowed = humanoid.WalkSpeed * (now - run.lastClock) * SPEED_TOLERANCE + STEP_SLACK
		if step <= allowed then
			run.studs += step
		end
	end
	run.last, run.lastClock = position, now
end

task.spawn(function()
	while true do
		task.wait(SAMPLE_SECONDS)
		for player, run in runs do
			sample(player, run)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	runs[player] = nil
end)

return RunDistance
