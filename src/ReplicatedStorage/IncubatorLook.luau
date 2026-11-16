-- Open hatch pod: the selected stud-brick body, built directly into a plot piece so Base remains discoverable.
-- Build(parent, floorCFrame, detail, state) -> setState(state). Full / mid / low: 17 / 6 / 3 body Parts.
-- States: free / locked / empty (unlit), growing (amber), ready (green). Display only; no remotes or persistence.
local IncubatorLook = {}

local BROWN = Color3.fromRGB(150, 100, 60)
local PAD = Color3.fromRGB(225, 195, 110)
local CREAM = Color3.fromRGB(236, 228, 208)
local STEEL = Color3.fromRGB(100, 133, 147)
local DARK = Color3.fromRGB(50, 66, 72)
local LOCKED = Color3.fromRGB(80, 80, 80)
local WARM = Color3.fromRGB(255, 183, 63)
local READY = Color3.fromRGB(108, 209, 110)

function IncubatorLook.Build(parent: Model, floorCFrame: CFrame, detail: string, state: string): (string) -> ()
	local muted = state == "locked" or state == "free"
	local trim = if muted then STEEL else CREAM
	local function add(name: string, size: Vector3, at: Vector3, color: Color3, variant: string?, collide: boolean?)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = floorCFrame * CFrame.new(at)
		p.Color = color
		p.Material = Enum.Material.Plastic
		p.MaterialVariant = variant or "StudsSmall"
		p.Anchored = true
		p.CanCollide = collide == true
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = parent
		return p
	end

	add("Base", Vector3.new(6, 1.2, 6), Vector3.new(0, 0.85, 0), if state == "locked" then LOCKED else BROWN, "Studs", true)
	if detail ~= "low" then
		add("Nest", Vector3.new(4.4, 0.4, 4.4), Vector3.new(0, 1.65, 0), PAD, nil, true)
	end
	for side, x in { Left = -2.2, Right = 2.2 } do
		if detail == "full" then
			for tier = 1, 4 do
				add(side .. "Cheek" .. tier, Vector3.new(0.7, 0.55, 4.3 - tier * 0.6),
					Vector3.new(x, 1.7 + tier * 0.55, 0.3 + tier * 0.18), if tier % 2 == 0 then trim else STEEL)
			end
		else
			add(side .. "Side", Vector3.new(0.7, 2.6, 3), Vector3.new(x, 2.75, 0.75), trim)
		end
	end
	if detail ~= "low" then
		add("RearHeaterCase", Vector3.new(3.5, 1.5, 0.5), Vector3.new(0, 4.45, 2.2), trim)
		add("ControlPod", Vector3.new(0.8, 1.9, 1.3), Vector3.new(2.25, 2.45, -1.45), trim)
	end
	local heater, temperature, podStatus, status
	if detail == "full" then
		heater = add("RearHeater", Vector3.new(2.7, 0.25, 0.16), Vector3.new(0, 4.65, 1.87), DARK, "")
		podStatus = add("PodStatus", Vector3.new(0.35, 0.18, 0.08), Vector3.new(2.25, 2.9, -2.15), DARK, "")
		-- Stand the console on the front lip; a panel inside the solid plinth would be hidden.
		add("Thermostat", Vector3.new(1.6, 0.65, 0.12), Vector3.new(-0.2, 1.775, -2.72), DARK)
		temperature = add("Temperature", Vector3.new(0.75, 0.18, 0.04), Vector3.new(-0.4, 1.855, -2.81), DARK, "")
		status = add("Status", Vector3.new(0.18, 0.18, 0.04), Vector3.new(0.3, 1.855, -2.81), DARK, "")
	end
	local current = nil
	local function lamp(p: BasePart?, color: Color3, on: boolean)
		if p then
			p.Color = if on then color else DARK
			p.Material = if on then Enum.Material.Neon else Enum.Material.Plastic
		end
	end
	local function setState(nextState: string)
		if nextState == current then return end
		current = nextState
		local growing, ready = nextState == "growing", nextState == "ready"
		local color = if ready then READY else WARM
		lamp(heater, WARM, growing)
		lamp(temperature, color, growing or ready)
		lamp(podStatus, color, growing or ready)
		lamp(status, color, growing or ready)
	end
	setState(state)
	return setState
end

return IncubatorLook
