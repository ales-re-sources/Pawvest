-- KitWires (docs/STAGES.md §7.12 "Vault lanes"): the visible link between a colour switch and the plates it changes
-- (ObstacleKit's KitSwitch / KitColorPlate). A wire is a row of thin parts tagged "KitWire" with attributes Group (the
-- switch's group) and Order (1 = the segment at the switch, then on to the plate); put them flat against a back wall,
-- CanCollide / CanTouch / CanQuery off. At rest the wire shows its Studio look. When a switch sets its group's colour
-- (the player attribute KitColors that ObstacleKit publishes), a bead runs along the wire from the switch end, every
-- segment it passes lights up (and stays lit while the group is off Red), and the group's colour plates flash as the
-- bead arrives; ReplicatedStorage.SwitchSound (Studio-only, silent without it) clicks as the switch is pressed. A death or run start resets
-- the group (ObstacleKit) and puts the wire back to rest. Local only, like the colour state itself.
-- A group with several switches (Stage 14's colour shaft: Toggle0 / Toggle1 in Group Lab) gives each wire the attribute Switch (the
-- name of its switch): a press runs the bead along the pressed switch's wire (the group's switch the player stands nearest) and puts
-- the group's other wires back to rest. A Toggle switch's wire stays lit after its press (its plate is the one that just opened).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local BEAD_SPEED = 45 -- studs/s along the wire
local BEAD_SIZE = 1.4
local LIT_COLOR = Color3.fromRGB(80, 255, 120) -- the switch pads' green
local FLASH_TIME = 0.6 -- seconds the plate flash takes to fade
local FLASH_GROW = 2 -- studs the flash box grows by on every axis while it fades

local wires = {} -- [part] = { color, material } (the Studio look = at rest)
local shown = {} -- [group] = colour from the last KitColors
local token = {} -- [group] = number, bumped to stop a running bead

local function addWire(part: Instance)
	if part:IsA("BasePart") and not wires[part] then
		wires[part] = { color = part.Color, material = part.Material }
	end
end

-- the group's wire segments; with `switch`, only that switch's wire (and segments that name no switch)
local function segments(group: string, switch: string?): { BasePart }
	local list = {}
	for part in wires do
		local owner = part:GetAttribute("Switch")
		if part:GetAttribute("Group") == group and part:IsDescendantOf(workspace)
			and (switch == nil or owner == nil or owner == switch) then
			table.insert(list, part)
		end
	end
	table.sort(list, function(a, b)
		return (a:GetAttribute("Order") or 0) < (b:GetAttribute("Order") or 0)
	end)
	return list
end

local function setLit(part: BasePart, lit: boolean)
	local rest = wires[part]
	if rest then
		part.Material = if lit then Enum.Material.Neon else rest.material
		part.Color = if lit then LIT_COLOR else rest.color
	end
end

-- The two ends of a segment along its longest axis.
local function ends(part: BasePart): (Vector3, Vector3)
	local size = part.Size
	local axis, half
	if size.X >= size.Y and size.X >= size.Z then
		axis, half = part.CFrame.RightVector, size.X / 2
	elseif size.Y >= size.Z then
		axis, half = part.CFrame.UpVector, size.Y / 2
	else
		axis, half = part.CFrame.LookVector, size.Z / 2
	end
	return part.Position - axis * half, part.Position + axis * half
end

local function tagged(tag: string, group: string): { BasePart }
	local list = {}
	for _, part in CollectionService:GetTagged(tag) do
		if part:IsA("BasePart") and part:GetAttribute("Group") == group and part:IsDescendantOf(workspace) then
			table.insert(list, part)
		end
	end
	return list
end

-- The group's switch nearest to the player (the one just stepped on), or nil without a character.
local function pressedSwitch(group: string): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return nil
	end
	local best, pressed = math.huge, nil
	for _, switch in tagged("KitSwitch", group) do
		local distance = (switch.Position - root.Position).Magnitude
		if distance < best then
			best, pressed = distance, switch
		end
	end
	return pressed
end

-- The bead's route: from the first segment's end nearest the switch, then to the far end of every next segment.
local function route(group: string, list: { BasePart }, switch: BasePart?): { Vector3 }
	local a, b = ends(list[1])
	local from = a
	if switch then
		from = switch.Position
	else
		local best = math.huge
		for _, candidate in tagged("KitSwitch", group) do
			local distance = (candidate.Position - list[1].Position).Magnitude
			if distance < best then
				best, from = distance, candidate.Position
			end
		end
	end
	local points = if (a - from).Magnitude <= (b - from).Magnitude then { a, b } else { b, a }
	for i = 2, #list do
		local c, d = ends(list[i])
		local last = points[#points]
		table.insert(points, if (c - last).Magnitude <= (d - last).Magnitude then d else c)
	end
	return points
end

local function flash(group: string)
	for _, plate in tagged("KitColorPlate", group) do
		local glow = Instance.new("Part")
		glow.Name = "KitWireFlash"
		glow.Anchored = true
		glow.CanCollide = false
		glow.CanTouch = false
		glow.CanQuery = false
		glow.CastShadow = false
		glow.Material = Enum.Material.Neon
		glow.Color = Color3.new(1, 1, 1)
		glow.Transparency = 0.2
		glow.Size = plate.Size + Vector3.one * 0.3
		glow.CFrame = plate.CFrame
		glow.Parent = workspace
		local tween = TweenService:Create(glow, TweenInfo.new(FLASH_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 1,
			Size = plate.Size + Vector3.one * FLASH_GROW,
		})
		tween.Completed:Connect(function()
			glow:Destroy()
		end)
		tween:Play()
	end
end

local function pulse(group: string, lit: boolean)
	local sound = ReplicatedStorage:FindFirstChild("SwitchSound")
	if sound and sound:IsA("Sound") then
		SoundService:PlayLocalSound(sound)
	end
	token[group] = (token[group] or 0) + 1
	local mine = token[group]
	for _, part in segments(group) do
		setLit(part, false)
	end
	local switch = pressedSwitch(group)
	if switch and switch:GetAttribute("Color") == "Toggle" then
		lit = true
	end
	local list = segments(group, switch and switch.Name)
	if #list == 0 then
		flash(group)
		return
	end
	local points = route(group, list, switch)
	local legs, total = {}, 0
	for i = 2, #points do
		legs[i - 1] = (points[i] - points[i - 1]).Magnitude
		total += legs[i - 1]
	end

	local bead = Instance.new("Part")
	bead.Name = "KitWireBead"
	bead.Shape = Enum.PartType.Ball
	bead.Size = Vector3.one * BEAD_SIZE
	bead.Anchored = true
	bead.CanCollide = false
	bead.CanTouch = false
	bead.CanQuery = false
	bead.CastShadow = false
	bead.Material = Enum.Material.Neon
	bead.Color = LIT_COLOR
	bead.Position = points[1]
	bead.Parent = workspace

	task.spawn(function()
		local started = os.clock()
		while token[group] == mine do
			local travelled = math.min((os.clock() - started) * BEAD_SPEED, total)
			local leg, rest = 1, travelled
			while leg < #legs and rest > legs[leg] do
				rest -= legs[leg]
				leg += 1
			end
			bead.Position = points[leg]:Lerp(points[leg + 1], if legs[leg] > 0 then math.min(rest / legs[leg], 1) else 1)
			if lit then
				for i = 1, leg do
					setLit(list[i], true)
				end
			end
			if travelled >= total then
				bead:Destroy()
				flash(group)
				return
			end
			RunService.RenderStepped:Wait()
		end
		bead:Destroy() -- stopped by a reset or a newer press
	end)
end

local function decode(text: any): { [string]: string }
	local map = {}
	if type(text) == "string" then
		for group, color in string.gmatch(text, "([^=,]+)=([^,]+)") do
			map[group] = color
		end
	end
	return map
end

local function onColors()
	local now = decode(player:GetAttribute("KitColors"))
	for group, color in now do
		if shown[group] ~= color then
			pulse(group, color ~= "Red")
		end
	end
	for group in shown do
		if now[group] == nil then
			-- reset (death / run start): stop the bead, the wire goes back to rest
			token[group] = (token[group] or 0) + 1
			for _, part in segments(group) do
				setLit(part, false)
			end
		end
	end
	shown = now
end

for _, part in CollectionService:GetTagged("KitWire") do
	addWire(part)
end
CollectionService:GetInstanceAddedSignal("KitWire"):Connect(addWire)
CollectionService:GetInstanceRemovedSignal("KitWire"):Connect(function(part)
	wires[part] = nil
end)
player:GetAttributeChangedSignal("KitColors"):Connect(onColors)
onColors()
