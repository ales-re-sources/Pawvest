-- FieldRings (U3a, docs/GDD.md §7.9): the Near tier of the own field. A ring over every planted square of the own field while
-- the character is within SHOW_DISTANCE (horizontal) of the nearest square: a dark disc whose pie fills as the crop grows, the
-- crop icon in the middle. Ripe = full green pie, a ✓ badge and a small bounce. The NEAREST growing squares closest to the
-- character also print the time left under their ring. Own plot only, at most CropConfig.MaxSquares billboards.
-- Data: GardenRemotes.State field.squares ({ crop, grown, readyAt }; readyAt = server time when ripe if the owner stays online)
-- and the server time (workspace:GetServerTimeNow()). The pie moves from `grown` at the State's arrival towards readyAt.
-- A ring is built once per planted crop and only re-filled each second (no new instances while nothing is planted / harvested).
-- Positions: GardenView.SquareCFrame. The billboards sit on Attachments of one invisible client part (Workspace.FieldRings),
-- not AlwaysOnTop (screen captures show them); drawn TOWARD the camera from the square so its crop does not hide it. In Studio the part carries the attributes
-- Rings (rings drawn) and UpdateMs (the last update's cost).
-- U3b: in the same tier, every placed field pet's reach region as a thin border in its rarity colour (GardenView.ShowBorders). The
-- region = the squares this pet counts for under GardenField's rules: per square the strongest Tending pet that reaches it and the
-- strongest guard (the guard chance from the State); ties go to the lower uid (the effect is the same). Redrawn only when a region
-- changes (State, PetsChanged) or the tier shows / hides. Studio attribute Borders = the regions drawn.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local GardenView = require(script.Parent:WaitForChild("GardenView"))
local PetClient = require(script.Parent:WaitForChild("PetClient"))

local player = Players.LocalPlayer
local studio = RunService:IsStudio()

local SHOW_DISTANCE = 30 -- studs (horizontal) from the character to the nearest field square
local NEAREST = 4 -- growing squares that print their time
local HEIGHT = 1.3 -- studs over the soil (billboard centre: the disc's centre is 0.6 higher, at a crop's middle). Higher rings
-- looked a row further back from the default camera's angle
local TOWARD = 3 -- studs toward the camera (StudsOffset Z): in front of the crop block (half width up to 1.9), so it does not hide the ring
local WIDTH, TALL = 4.2, 3.5 -- billboard size in studs: the DISC-stud disc over a 1.05-stud time line
local DISC = 2.3
local TICK_SECONDS = 1

local COLOR_TRACK = Color3.fromRGB(35, 35, 40)
local COLOR_GROWING = Color3.fromRGB(245, 200, 70)
local COLOR_RIPE = Color3.fromRGB(90, 225, 90)
local COLOR_CHECK = Color3.fromRGB(40, 160, 60)

local anchor = Instance.new("Part")
anchor.Name = "FieldRings"
anchor.Anchored = true
anchor.CanCollide = false
anchor.CanQuery = false
anchor.CanTouch = false
anchor.Transparency = 1
anchor.Size = Vector3.new(1, 1, 1)
anchor.Parent = workspace

local field = nil -- GardenRemotes.State.field as last received
local receivedAt = 0 -- server time of its arrival
local rings = {} -- [square] = ring entry (newRing)
local builtSlot = nil

local function circle(name: string, props): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BorderSizePixel = 0
	for key, value in props do
		(frame :: any)[key] = value
	end
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = frame
	return frame
end

-- One half of the pie: a clip frame over the left or right half of the disc holding the full fill circle, whose gradient hides
-- one side. Rotating the gradient clockwise sweeps the fill from 12 o'clock (right half: 0-180°, left half: 180-360°).
local function half(parent: Instance, right: boolean): UIGradient
	local clip = Instance.new("Frame")
	clip.Name = if right then "Right" else "Left"
	clip.BackgroundTransparency = 1
	clip.ClipsDescendants = true
	clip.Size = UDim2.fromScale(0.5, 1)
	clip.Position = UDim2.fromScale(if right then 0.5 else 0, 0)
	clip.Parent = parent
	local fill = circle("Fill", {
		Size = UDim2.fromScale(2, 1),
		Position = UDim2.fromScale(if right then -1 else 0, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
	})
	fill.Parent = clip
	local gradient = Instance.new("UIGradient")
	-- right half: the left side of the circle is opaque (none of it shows at 0°); left half: the right side
	gradient.Transparency = if right
		then NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(0.501, 1), NumberSequenceKeypoint.new(1, 1) })
		else NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(0.501, 0), NumberSequenceKeypoint.new(1, 0) })
	gradient.Parent = fill
	return gradient
end

local function newRing(square: number, crop)
	local cframe = GardenView.SquareCFrame(square)
	if not cframe then
		return nil
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = "Square" .. square
	attachment.WorldCFrame = cframe
	local gui = Instance.new("BillboardGui")
	gui.Name = "Ring"
	gui.AutoLocalize = false
	gui.LightInfluence = 0
	gui.Size = UDim2.new(WIDTH, 0, TALL, 0) -- scale = studs
	gui.StudsOffset = Vector3.new(0, HEIGHT, TOWARD)
	gui.MaxDistance = 90
	gui.Enabled = false
	local disc = circle("Disc", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromScale(DISC / WIDTH, DISC / TALL),
		BackgroundColor3 = COLOR_TRACK,
		BackgroundTransparency = 0.25,
	})
	disc.Parent = gui
	local pie = Instance.new("Frame")
	pie.Name = "Pie"
	pie.BackgroundTransparency = 1
	pie.Size = UDim2.fromScale(1, 1)
	pie.Parent = disc
	local right = half(pie, true)
	local left = half(pie, false)
	local inner = circle("Inner", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.7, 0.7),
		BackgroundColor3 = COLOR_TRACK,
		BackgroundTransparency = 0.05,
	})
	inner.Parent = disc
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.Size = UDim2.fromScale(0.72, 0.72)
	icon.TextScaled = true
	icon.Font = Enum.Font.GothamBold
	icon.Text = crop.icon
	icon.Parent = inner
	local check = circle("Check", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.86, 0.14),
		Size = UDim2.fromScale(0.4, 0.4),
		BackgroundColor3 = COLOR_CHECK,
		Visible = false,
	})
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = 1.5
	stroke.Parent = check
	local mark = Instance.new("TextLabel")
	mark.Name = "Mark"
	mark.BackgroundTransparency = 1
	mark.Size = UDim2.fromScale(1, 1)
	mark.TextScaled = true
	mark.Font = Enum.Font.GothamBold
	mark.TextColor3 = Color3.new(1, 1, 1)
	mark.Text = "✓"
	mark.Parent = check
	check.Parent = disc
	local time = Instance.new("TextLabel")
	time.Name = "Time"
	time.BackgroundTransparency = 1
	time.AnchorPoint = Vector2.new(0.5, 1)
	time.Position = UDim2.fromScale(0.5, 1)
	time.Size = UDim2.fromScale(1, 1.05 / TALL)
	time.TextScaled = true
	time.Font = Enum.Font.GothamBold
	time.TextColor3 = Color3.new(1, 1, 1)
	time.TextStrokeTransparency = 0.2
	time.Visible = false
	time.Parent = gui
	gui.Parent = attachment
	attachment.Parent = anchor
	return {
		crop = crop,
		attachment = attachment,
		gui = gui,
		disc = disc,
		fills = { right.Parent :: Frame, left.Parent :: Frame }, -- the two fill circles (the gradients' parents)
		right = right,
		left = left,
		check = check,
		time = time,
		position = cframe.Position,
		ripe = nil, -- unknown until the first fill
		bounce = nil,
	}
end

local function dropRing(square: number)
	local ring = rings[square]
	if ring then
		if ring.bounce then
			ring.bounce:Cancel()
		end
		ring.attachment:Destroy()
		rings[square] = nil
	end
end

local function countdown(seconds: number): string
	seconds = math.max(1, math.ceil(seconds))
	if seconds >= 3600 then
		return string.format("%d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
	end
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

-- Builds / drops rings to match the planted squares of the current field (only where the crop changed).
local function sync()
	local slot = player:GetAttribute(GardenConfig.PlotAttribute)
	if slot ~= builtSlot then
		for square in rings do
			dropRing(square)
		end
		builtSlot = slot
	end
	local squares = if type(field) == "table" and type(field.squares) == "table" then field.squares else {}
	for square, ring in rings do
		local entry = squares[tostring(square)]
		if not entry or CropConfig.ById[entry.crop] ~= ring.crop then
			dropRing(square)
		end
	end
	if not slot then
		return
	end
	for key, entry in squares do
		local square = tonumber(key)
		local crop = CropConfig.ById[entry.crop]
		if square and crop and not rings[square] then
			rings[square] = newRing(square, crop)
		end
	end
end

local function setRipe(ring, ripe: boolean)
	if ring.ripe == ripe then
		return
	end
	ring.ripe = ripe
	ring.check.Visible = ripe
	for _, fill in ring.fills do
		fill.BackgroundColor3 = if ripe then COLOR_RIPE else COLOR_GROWING
	end
	if ring.bounce then
		ring.bounce:Cancel()
		ring.bounce = nil
		ring.disc.Position = UDim2.fromScale(0.5, 0)
	end
	if ripe then
		ring.bounce = TweenService:Create(
			ring.disc,
			TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1, true),
			{ Position = UDim2.fromScale(0.5, -0.07) }
		)
		ring.bounce:Play()
	end
end

-- Re-fills every ring for server time `now` and shows them while the character is near the field.
-- Reach borders -----------------------------------------------------------------------------------------------------------------

local borders = {} -- { { squares, color, lane } } for GardenView.ShowBorders
local bordersKey = "" -- signature of `borders`
local bordersDrawn: string? = nil -- signature drawn now (nil = none shown)

local function uidBefore(a: string, b: string): boolean
	local x, y = tonumber(a), tonumber(b)
	if x and y and x ~= y then
		return x < y
	end
	return a < b
end

local function computeBorders()
	local pets = type(field) == "table" and field.pets
	local state = PetClient.State
	borders, bordersKey = {}, ""
	if type(pets) ~= "table" or not state then
		return
	end
	local open = {}
	for _, n in field.open or {} do
		open[n] = true
	end
	local placed = {}
	for key, entry in pets do
		local square = tonumber(key)
		local owned = type(entry) == "table" and state.pets[entry.uid]
		if square and owned then
			table.insert(placed, {
				uid = entry.uid,
				square = square,
				kind = owned.Kind,
				tending = PetConfig.AptitudeLevel(owned, "Tending"),
				guard = PetConfig.AptitudeLevel(owned, "PestControl"),
				chance = if type(entry.guard) == "table" then entry.guard.chance or 0 else 0,
			})
		end
	end
	table.sort(placed, function(a, b)
		return uidBefore(a.uid, b.uid)
	end)
	-- per square the winner of each job; the list is in uid order, so a strict > keeps the lower uid on a tie
	local tend, guard = {}, {}
	for _, pet in placed do
		if pet.tending > 0 then
			local value = PetConfig.Strength(pet.tending)
			for _, n in CropConfig.Reach(pet.square, PetConfig.ReachShape(pet.tending), open) do
				if not tend[n] or value > tend[n].value then
					tend[n] = { value = value, pet = pet }
				end
			end
		end
		if pet.guard > 0 then
			for _, n in CropConfig.Reach(pet.square, PetConfig.ReachShape(pet.guard), open) do
				if not guard[n] or pet.chance > guard[n].value then
					guard[n] = { value = pet.chance, pet = pet }
				end
			end
		end
	end
	local keys = {}
	for index, pet in placed do
		local mine = {}
		for n = 1, CropConfig.MaxSquares do
			if (tend[n] and tend[n].pet == pet) or (guard[n] and guard[n].pet == pet) then
				table.insert(mine, n)
			end
		end
		if #mine > 0 then
			local rarity = PetConfig.RarityOf(pet.kind)
			local color = if rarity then rarity.color else Color3.new(1, 1, 1)
			local lane = (index - 1) % 3
			table.insert(borders, { squares = mine, color = color, lane = lane })
			table.insert(keys, pet.uid .. "@" .. lane .. ":" .. table.concat(mine, ",") .. ":" .. color:ToHex())
		end
	end
	bordersKey = table.concat(keys, "|")
end

local function showBorders(near: boolean)
	local want = if near and #borders > 0 then bordersKey else nil
	if want == bordersDrawn then
		return
	end
	bordersDrawn = want
	GardenView.ShowBorders(if want then borders else nil)
	if studio then
		anchor:SetAttribute("Borders", if want then #borders else 0)
	end
end

local function update(now: number)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local at = if root and root:IsA("BasePart") then root.Position else nil
	local near = false
	if at then
		for n = 1, CropConfig.MaxSquares do
			local cframe = builtSlot and GardenView.SquareCFrame(n)
			if not cframe then
				break
			end
			local offset = cframe.Position - at
			if Vector3.new(offset.X, 0, offset.Z).Magnitude <= SHOW_DISTANCE then
				near = true
				break
			end
		end
	end
	local squares = if type(field) == "table" and type(field.squares) == "table" then field.squares else {}
	local growing = {}
	for square, ring in rings do
		ring.gui.Enabled = near
		local entry = squares[tostring(square)]
		if entry then
			local crop = ring.crop
			local grown = entry.grown or 0
			local readyAt = entry.readyAt or 0
			local ripe = grown >= crop.growSeconds or readyAt <= now
			setRipe(ring, ripe)
			local share = 1
			if not ripe then
				-- growth since the State arrived, at the rate that reaches growSeconds at readyAt
				local rate = (crop.growSeconds - grown) / math.max(readyAt - receivedAt, 1)
				share = math.clamp((grown + rate * math.max(now - receivedAt, 0)) / crop.growSeconds, 0, 1)
				if at then
					table.insert(growing, { ring = ring, distance = (ring.position - at).Magnitude, left = readyAt - now })
				end
			end
			ring.right.Rotation = math.clamp(share, 0, 0.5) * 360
			ring.left.Rotation = math.clamp(share - 0.5, 0, 0.5) * 360
			ring.time.Visible = false
		end
	end
	table.sort(growing, function(a, b)
		return a.distance < b.distance
	end)
	for i = 1, math.min(NEAREST, #growing) do
		local item = growing[i]
		item.ring.time.Text = countdown(item.left)
		item.ring.time.Visible = true
	end
	showBorders(near)
end

ReplicatedStorage:WaitForChild("GardenRemotes"):WaitForChild("State").OnClientEvent:Connect(function(state)
	field = if type(state) == "table" then state.field else nil
	receivedAt = workspace:GetServerTimeNow()
	sync()
	computeBorders()
	update(receivedAt)
end)
PetClient.Changed:Connect(function()
	computeBorders() -- a job level or a pet changed
end)
player:GetAttributeChangedSignal(GardenConfig.PlotAttribute):Connect(function()
	-- the plot's view is built a moment later: SquareCFrame needs it
	task.delay(1, function()
		sync()
		bordersDrawn = nil -- the new plot's view has none drawn
		GardenView.ShowBorders(nil)
	end)
end)

-- the State may have arrived before this script connected (GardenView keeps the last one)
if not field and GardenView.OwnField() then
	field = GardenView.OwnField()
	receivedAt = workspace:GetServerTimeNow()
	computeBorders()
end

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < TICK_SECONDS then
		return
	end
	elapsed = 0
	if builtSlot == nil or next(rings) == nil then
		sync() -- the own plot may have been drawn since
	end
	local started = os.clock()
	update(workspace:GetServerTimeNow())
	if studio then
		local count = 0
		for _ in rings do
			count += 1
		end
		anchor:SetAttribute("Rings", count)
		anchor:SetAttribute("UpdateMs", math.floor((os.clock() - started) * 100000) / 100)
	end
end)
