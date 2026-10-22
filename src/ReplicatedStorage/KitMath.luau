-- KitMath: pure timing maths of the obstacle kit (docs/STAGES.md §2.4). Every function maps server time `now` (seconds,
-- workspace:GetServerTimeNow()) and part attributes to a state, with no side effects, so each client derives the same
-- phase. `phase` is a share of the period (0..1) that shifts a part against its neighbours; `period` is in seconds.

local KitMath = {}

local TAU = 2 * math.pi

-- Position in the cycle, 0 ≤ c < 1.
function KitMath.Cycle(now: number, period: number, phase: number): number
	return (now / period + phase) % 1
end

-- "on" / "warning" / "off" for a blinking hazard: the on window is the last `duty` share of the cycle, the warning is the
-- `telegraph` seconds before it.
function KitMath.Window(now: number, period: number, duty: number, phase: number, telegraph: number): string
	local cycle = KitMath.Cycle(now, period, phase)
	local onStart = 1 - duty
	if cycle >= onStart then
		return "on"
	end
	if (onStart - cycle) * period <= telegraph then
		return "warning"
	end
	return "off"
end

-- Disappearing plate: "solid" for the first `duty` share of the cycle (the last `telegraph` seconds of it are "warning",
-- the plate flickers), "gone" for the rest.
function KitMath.Plate(now: number, period: number, duty: number, phase: number, telegraph: number): string
	local cycle = KitMath.Cycle(now, period, phase)
	if cycle >= duty then
		return "gone"
	end
	if (duty - cycle) * period <= telegraph then
		return "warning"
	end
	return "solid"
end

-- The time a part runs on: server time, or, for a run-seeded part while that player's timer runs, the seconds since the
-- run started (`runStart` = server time of the start), so every run sees the same sequence.
function KitMath.TimeBase(now: number, runStart: number?, seeded: boolean): number
	if seeded and runStart then
		return now - runStart
	end
	return now
end

-- Gust strength 0..1 for a wind that blows in the last `duty` share of each cycle, rising and falling smoothly.
function KitMath.Gust(now: number, period: number, duty: number, phase: number): number
	local cycle = KitMath.Cycle(now, period, phase)
	local onStart = 1 - duty
	if cycle < onStart then
		return 0
	end
	return math.sin(math.pi * (cycle - onStart) / duty)
end

-- Smooth sine swing −1..1 (sliding platforms, pendulums).
function KitMath.Sine(now: number, period: number, phase: number): number
	return math.sin(TAU * KitMath.Cycle(now, period, phase))
end

local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end
KitMath.Smooth = smooth

-- Elevator position 0..1: rests `pause` seconds at each end, eased between them; one full cycle = `period`.
function KitMath.Lift(now: number, period: number, pause: number, phase: number): number
	local t = KitMath.Cycle(now, period, phase) * period
	local half = period / 2
	local travel = math.max(half - pause, 1e-3)
	if t < half then
		return smooth((t - pause) / travel)
	end
	return 1 - smooth((t - half - pause) / travel)
end

-- Piston extension 0..1: retracted until the on window, strikes out in `out` seconds when it starts (the warning is the
-- `telegraph` seconds before), holds until the end of the cycle, then pulls back over `back` seconds.
-- Returns extension and the same on / warning / off state as Window.
function KitMath.Piston(now: number, period: number, duty: number, phase: number, telegraph: number, out: number, back: number)
	local cycle = KitMath.Cycle(now, period, phase)
	local t = cycle * period
	local onStart = (1 - duty) * period
	local extension
	if t < back then
		extension = 1 - smooth(t / back)
	elseif t >= onStart then
		extension = smooth((t - onStart) / out)
	else
		extension = 0
	end
	return extension, KitMath.Window(now, period, duty, phase, telegraph)
end

-- Flipper: rests flat, then turns 180 degrees in the last `turn` seconds of each half cycle (so it flips over and back once
-- per `period`). Returns the angle in degrees (0..360) and "on" while it turns, "warning" for the `telegraph` seconds
-- before, "off" while it rests.
function KitMath.Flip(now: number, period: number, phase: number, turn: number, telegraph: number): (number, string)
	local half = period / 2
	local t = KitMath.Cycle(now, period, phase) * period
	local flips = if t >= half then 1 else 0
	local into = t - flips * half
	local restEnd = half - turn
	if into >= restEnd then
		return 180 * (flips + smooth((into - restEnd) / turn)), "on"
	end
	return 180 * flips, if restEnd - into <= telegraph then "warning" else "off"
end

-- Pendulum angle in degrees.
function KitMath.Swing(now: number, period: number, phase: number, amplitude: number): number
	return amplitude * KitMath.Sine(now, period, phase)
end

return KitMath
