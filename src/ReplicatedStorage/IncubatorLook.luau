-- Open hatch pod: the selected stud-brick body, built directly into a plot piece so Base remains discoverable.
-- Build(...) -> setState(state), animate(serverNow, startedAt?). Full / mid / low: 25 / 8 / 3 body Parts.
-- States: free / locked / empty (unlit), scanning (cyan rear scanner), growing (warm amber pulse), ready (green).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local IncubatorLook = {}

local BROWN = Color3.fromRGB(150, 100, 60)
local PAD = Color3.fromRGB(225, 195, 110)
local CREAM = Color3.fromRGB(236, 228, 208)
local STEEL = Color3.fromRGB(100, 133, 147)
local DARK = Color3.fromRGB(50, 66, 72)
local LOCKED = Color3.fromRGB(80, 80, 80)
local WARM = Color3.fromRGB(255, 183, 63)
local READY = Color3.fromRGB(108, 209, 110)
local SCAN = Color3.fromRGB(81, 216, 240)
local SCAN_LIGHT = Color3.fromRGB(165, 250, 255)
local SCAN_TOP = Vector3.new(0, 4.2, 1.86) -- the emitter's front face
local SCAN_BACK, SCAN_FRONT, SCAN_PERIOD = 1.5, -1.8, 3 -- scan line z range on the nest; seconds per back-front-back

function IncubatorLook.Build(parent: Model, floorCFrame: CFrame, detail: string, state: string, number: number)
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
			-- Keep the same top edge, embedding the bottom in the base instead of sharing the nest's bottom face.
			add(side .. "Side", Vector3.new(0.7, 2.7, 3), Vector3.new(x, 2.7, 0.75), trim)
		end
	end
	if detail ~= "low" then
		add("RearHeaterCase", Vector3.new(3.5, 1.5, 0.5), Vector3.new(0, 4.45, 2.2), trim)
		-- Embed the plate's foot in the heater case; front and back remain readable from either approach.
		local plate = add("NumberPlate", Vector3.new(1.4, 1.15, 0.3), Vector3.new(0, 5.7, 2.2), DARK)
		for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
			local gui = Instance.new("SurfaceGui")
			gui.Name = "Number" .. face.Name
			gui.Face = face
			gui.AutoLocalize = false
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = 60
			gui.LightInfluence = 0.2
			gui.MaxDistance = 100
			local label = Instance.new("TextLabel")
			label.Name = "Number"
			label.AutoLocalize = false
			label.BackgroundTransparency = 1
			label.Position = UDim2.fromScale(0.1, 0.06)
			label.Size = UDim2.fromScale(0.8, 0.88)
			label.Font = StudStyle.Font
			label.TextScaled = true
			label.TextColor3 = CREAM
			Locale.SetText(label, Locale.Number(number))
			label.Parent = gui
			gui.Parent = plate
		end
		-- Its inner face must stand clear of the cheek's inner face (x = 1.85), or the two stud textures flicker.
		add("ControlPod", Vector3.new(0.68, 1.9, 1.3), Vector3.new(2.25, 2.45, -1.45), trim)
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
	local bands = {}
	local emitter, sheet, scanLine
	if detail == "full" then
		for _, segment in {
			{ "Front", Vector3.new(3.4, 0.06, 0.06), Vector3.new(0, 1.95, -1.48) },
			{ "Back", Vector3.new(3.4, 0.06, 0.06), Vector3.new(0, 1.95, 1.48) },
			{ "Left", Vector3.new(0.06, 0.06, 2.9), Vector3.new(-1.67, 1.95, 0) },
			{ "Right", Vector3.new(0.06, 0.06, 2.9), Vector3.new(1.67, 1.95, 0) },
		} do
			local p = add("PhaseBand" .. segment[1], segment[2], segment[3], SCAN, "")
			p.Material = Enum.Material.Neon
			p.Transparency = 1
			table.insert(bands, p)
		end
		-- Rear scanner: the bar is embedded in the heater case's front face; a see-through sheet runs from it to a bright line
		-- that sweeps the nest (just above its top face) back to front and back again.
		emitter = add("ScanEmitter", Vector3.new(3, 0.14, 0.1), Vector3.new(0, 4.2, 1.91), DARK, "")
		sheet = add("ScanSheet", Vector3.new(3, 0.04, 1), Vector3.new(0, 3, 0), SCAN, "")
		sheet.Material = Enum.Material.Neon
		sheet.Transparency = 1
		scanLine = add("ScanLine", Vector3.new(3.3, 0.08, 0.14), Vector3.new(0, 1.9, SCAN_BACK), SCAN_LIGHT, "")
		scanLine.Material = Enum.Material.Neon
		scanLine.Transparency = 1
	elseif detail == "mid" then
		local p = add("PhaseStrip", Vector3.new(3.4, 0.08, 0.1), Vector3.new(0, 1.95, -1.48), SCAN, "")
		p.Material = Enum.Material.Neon
		p.Transparency = 1
		table.insert(bands, p)
	end
	local glow = nil
	if detail == "full" then
		glow = Instance.new("PointLight")
		glow.Name = "NestGlow"
		glow.Range = 6
		glow.Shadows = false
		glow.Enabled = false
		glow.Parent = parent:FindFirstChild("Nest")
	end
	local function sweep(z: number)
		if not sheet then return end
		local top = floorCFrame * SCAN_TOP
		local bottom = floorCFrame * Vector3.new(0, 1.9, z)
		local back = (top - bottom).Unit -- the sheet's local Z runs from its scan line up to the emitter
		sheet.Size = Vector3.new(3, 0.04, (top - bottom).Magnitude)
		sheet.CFrame = CFrame.fromMatrix((top + bottom) / 2, floorCFrame.RightVector, back:Cross(floorCFrame.RightVector), back)
		scanLine.CFrame = floorCFrame * CFrame.new(0, 1.9, z)
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
		local growing, ready, scanning = nextState == "growing", nextState == "ready", nextState == "scanning"
		local color = if ready then READY elseif scanning then SCAN else WARM
		lamp(heater, WARM, growing)
		lamp(emitter, SCAN_LIGHT, scanning)
		lamp(temperature, color, growing or ready or scanning)
		lamp(podStatus, color, growing or ready or scanning)
		lamp(status, color, growing or ready or scanning)
		for _, band in bands do
			band.Color = color
			-- Full detail scans with the rear scanner; mid keeps its static strip.
			band.Transparency = if scanning and not sheet then 0.25 elseif growing then 0.55 else 1
		end
		if sheet then
			sheet.Transparency = if scanning then 0.72 else 1
			scanLine.Transparency = if scanning then 0 else 1
			sweep(SCAN_BACK)
		end
		if glow then
			glow.Enabled = growing or scanning
			glow.Color = color
			glow.Brightness = if scanning then 0.4 else 0.6
		end
	end
	local function animate(now: number, startedAt: number?)
		if detail ~= "full" then return end
		local age = now - (startedAt or 0)
		if current == "scanning" then
			-- Eased ping-pong: start at the back, reach the front after half a period.
			sweep(SCAN_BACK + (SCAN_FRONT - SCAN_BACK) * (1 - math.cos(age * 2 * math.pi / SCAN_PERIOD)) / 2)
		elseif current == "growing" then
			local pulse = math.sin(age * math.pi / 2)
			for _, band in bands do band.Transparency = 0.55 - 0.15 * pulse end
			if glow then glow.Brightness = 0.6 + 0.15 * pulse end
		end
	end
	setState(state)
	return setState, animate
end

return IncubatorLook
