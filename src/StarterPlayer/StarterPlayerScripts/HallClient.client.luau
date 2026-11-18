-- HallClient (SH): draws the Harvest Hall at the hub from ReplicatedStorage.HarvestHall's attribute Board (HarvestHall, server;
-- shape in HallConfig) and shows its toast. Nothing here is sent to the server.
-- Scene (Studio): Workspace.StartLocation.HarvestHall holds a pedestal Model per crop (tag HallConfig.PedestalTag, attribute Crop,
-- parts Base / Top / Plaque) and RecordBoard (part Screen). Per pedestal: the plaque names the crop; the week's #1 stands on Top in its
-- grown art (PlantGrowth at 100 % with the entry's size; a crop without art shows its icon) while the player is within DRAW_DISTANCE;
-- a label over it shows the #1's avatar, name and weight, #2 and #3 and the player's own best of the week when it is not on the
-- list (player attribute HallConfig.WeekBestAttribute); an empty pedestal has no label, its plaque says "Grow the biggest!". The record board shows the title, the
-- week's countdown and per crop the all-time record. Texts follow Locale.Changed.

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HallConfig = require(ReplicatedStorage:WaitForChild("HallConfig"))
local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local PlantGrowth = require(ReplicatedStorage:WaitForChild("PlantGrowth"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local HudPopup = require(script.Parent:WaitForChild("HudPopup"))

local player = Players.LocalPlayer
local folder = ReplicatedStorage:WaitForChild(HallConfig.Folder)
local scene = workspace:WaitForChild("StartLocation"):WaitForChild(HallConfig.SceneFolder)

local DRAW_DISTANCE = 140 -- studs from the record board: plants are built inside, removed beyond DRAW_DISTANCE + 20
local LABEL_DISTANCE = 55 -- studs: the labels over the pedestals
local LABEL_WIDTH, LABEL_TOP, LABEL_LINE = 6, 1.6, 0.55 -- studs: the label's width, its top block, each small line
local TOAST_SECONDS = 6
local COLOR_TEXT = Color3.fromRGB(255, 240, 210)
local COLOR_GOLD = Color3.fromRGB(255, 214, 102)
local COLOR_DIM = Color3.fromRGB(220, 205, 180)
local COLOR_PANEL = Color3.fromRGB(32, 32, 32)

local board = nil -- the decoded Board attribute
local near = false
local views = {} -- [pedestal Model] = { crop, plaque, label, plant?, plantKey? }
local thumbs = {} -- [UserId] = image content

local function decode()
	local ok, data = pcall(HttpService.JSONDecode, HttpService, folder:GetAttribute("Board") or "")
	board = if ok and type(data) == "table" then data else nil
end

local function ownBest(): { [string]: number }
	local ok, data = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute(HallConfig.WeekBestAttribute) or "")
	return if ok and type(data) == "table" then data else {}
end

-- "0.31", "7.4", "38" (Czech "0,31"): the weight of `crop` at size `f`, two decimals below 1 kg
local function kg(crop, f: number): string
	local weight = crop.kg * f
	local text = if weight < 1 then string.format("%.2f", weight) elseif weight < 100 then string.format("%.1f", weight)
		else string.format("%d", math.floor(weight + 0.5))
	return Locale.Decimal(text)
end

local function thumbnail(userId: number, label: ImageLabel)
	if thumbs[userId] then
		label.Image = thumbs[userId]
		return
	end
	task.spawn(function()
		local ok, image, ready = pcall(Players.GetUserThumbnailAsync, Players, userId, Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size100x100)
		if ok and ready and type(image) == "string" then
			thumbs[userId] = image
		end
		if ok and type(image) == "string" and label:GetAttribute("UserId") == userId then
			label.Image = image
		end
	end)
end

local function text(parent: Instance, props): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = StudStyle.Font
	label.TextColor3 = COLOR_TEXT
	label.TextStrokeTransparency = 0.6
	label.TextScaled = true
	label.TextWrapped = true
	for key, value in props do
		(label :: any)[key] = value
	end
	label.Parent = parent
	return label
end

-- Pedestals ----------------------------------------------------------------------------------------------------------------

local function newView(model: Model)
	local crop = CropConfig.ById[model:GetAttribute("Crop")]
	local plaquePart = model:FindFirstChild("Plaque")
	local top = model:FindFirstChild("Top")
	if not (crop and plaquePart and plaquePart:IsA("BasePart") and top and top:IsA("BasePart")) then
		return nil
	end
	local plaque = Instance.new("SurfaceGui")
	plaque.Name = "HallPlaque"
	plaque.Face = Enum.NormalId.Front
	plaque.AutoLocalize = false
	plaque.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	plaque.PixelsPerStud = 50
	plaque.LightInfluence = 0
	local name = text(plaque, { Name = "Crop", Size = UDim2.new(1, -16, 0.6, -6), Position = UDim2.fromOffset(8, 6) })
	local status = text(plaque, { Name = "Status", Size = UDim2.new(1, -16, 0.4, -6), Position = UDim2.new(0, 8, 0.6, 0),
		TextColor3 = COLOR_DIM })
	plaque.Parent = plaquePart

	local label = Instance.new("BillboardGui")
	label.Name = "HallLabel"
	label.AutoLocalize = false
	label.Adornee = top
	label.Size = UDim2.fromScale(LABEL_WIDTH, LABEL_TOP)
	label.LightInfluence = 0
	label.MaxDistance = LABEL_DISTANCE
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundColor3 = COLOR_PANEL
	panel.BackgroundTransparency = 0.25
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.12, 0)
	corner.Parent = panel
	panel.Parent = label
	local avatar = Instance.new("ImageLabel")
	avatar.Name = "Avatar"
	avatar.BackgroundTransparency = 1
	avatar.Parent = panel
	local first = text(panel, { Name = "First", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = COLOR_GOLD })
	local weight = text(panel, { Name = "Weight", TextXAlignment = Enum.TextXAlignment.Left })
	local rows = {}
	for i = 1, 3 do
		rows[i] = text(panel, { Name = "Row" .. i, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = COLOR_DIM })
	end
	label.Parent = top
	return {
		crop = crop,
		model = model,
		top = top,
		name = name,
		status = status,
		label = label,
		avatar = avatar,
		first = first,
		weight = weight,
		rows = rows,
	}
end

-- The week's list of `cropId` from the board ({ { u, n, f, t }, … }, best first).
local function listOf(cropId: string)
	local crops = board and board.crops
	local list = type(crops) == "table" and crops[cropId]
	return if type(list) == "table" then list else {}
end

local function drawPlant(view, entry)
	local key = if entry and near then string.format("%d|%s|%s", entry.u, tostring(entry.f), tostring(entry.t)) else nil
	if key == view.plantKey then
		return
	end
	view.plantKey = key
	if view.plant then
		view.plant:Destroy()
		view.plant = nil
	end
	if not key then
		return
	end
	local holder = Instance.new("Model")
	holder.Name = "HallPlant"
	local soil = view.top.CFrame * CFrame.new(0, view.top.Size.Y / 2, 0)
	if PlantGrowth.Supports(view.crop.id) then
		local seed = (entry.u % 100000) * 7919 + (math.floor(entry.t) % 100000) * 104729
		local ok, plant = pcall(PlantGrowth.new, holder, soil, view.crop.id, seed, entry.f)
		if ok and plant then
			pcall(plant.SetGrowth, plant, 1)
		else
			warn("HallClient: plant art of " .. view.crop.id .. " failed: " .. tostring(plant))
		end
	else -- no art yet (a draft): the crop's icon stands in
		local stand = Instance.new("Part")
		stand.Name = "Icon"
		stand.Anchored = true
		stand.CanCollide = false
		stand.CanQuery = false
		stand.CanTouch = false
		stand.Transparency = 1
		stand.Size = Vector3.new(2, 2, 2)
		stand.CFrame = soil * CFrame.new(0, 1.5, 0)
		local gui = Instance.new("BillboardGui")
		gui.AutoLocalize = false
		gui.Size = UDim2.fromScale(2.5, 2.5)
		gui.LightInfluence = 0
		text(gui, { Size = UDim2.fromScale(1, 1), Text = view.crop.icon, TextStrokeTransparency = 1 })
		gui.Parent = stand
		stand.Parent = holder
	end
	for _, part in holder:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
		end
	end
	holder.Parent = view.model
	view.plant = holder
end

-- Sizes the label to its top block (avatar, name, weight) and `lines` small lines below it (all in studs, so TextScaled
-- keeps one text size).
local function layout(view, lines: number)
	local height = LABEL_TOP + lines * LABEL_LINE
	view.label.Size = UDim2.fromScale(LABEL_WIDTH, height)
	local function place(child: GuiObject, x: number, y: number, w: number, h: number)
		child.Position = UDim2.fromScale(x / LABEL_WIDTH, y / height)
		child.Size = UDim2.fromScale(w / LABEL_WIDTH, h / height)
	end
	local pad = 0.12
	place(view.avatar, pad, pad, LABEL_TOP - 2 * pad, LABEL_TOP - 2 * pad)
	place(view.first, LABEL_TOP, pad, LABEL_WIDTH - LABEL_TOP - pad, (LABEL_TOP - 2 * pad) * 0.55)
	place(view.weight, LABEL_TOP, pad + (LABEL_TOP - 2 * pad) * 0.55, LABEL_WIDTH - LABEL_TOP - pad, (LABEL_TOP - 2 * pad) * 0.45)
	for i, row in view.rows do
		place(row, 0.25, LABEL_TOP + (i - 1) * LABEL_LINE - 0.05, LABEL_WIDTH - 0.5, LABEL_LINE - 0.08)
	end
end

local function drawView(view, best)
	local crop = view.crop
	view.name.Text = Locale.T("hall.crop", { icon = crop.icon, crop = Locale.CropName(crop) })
	local list = listOf(crop.id)
	local entry = list[1]
	drawPlant(view, entry)
	local height = 1
	if entry and PlantGrowth.Supports(crop.id) then
		local ok, ring = pcall(PlantGrowth.RingHeight, crop.id, entry.f)
		height = if ok and type(ring) == "number" then ring else 3
	elseif entry then
		height = 3
	end
	view.label.StudsOffset = Vector3.new(0, view.top.Size.Y / 2 + height + 2, 0)
	local mine = best[crop.id]
	-- an empty pedestal has no label (19 of them crowded the plaza): its plaque says "Grow the biggest!"
	view.status.Text = if entry then "" else Locale.T("hall.empty")
	view.label.Enabled = entry ~= nil
	if not entry then
		return
	end
	view.avatar:SetAttribute("UserId", entry.u)
	view.avatar.Image = ""
	thumbnail(entry.u, view.avatar)
	view.first.Text = Locale.T("hall.first", { name = entry.n })
	view.weight.Text = Locale.T("hall.kg", { kg = kg(crop, entry.f) })
	for i = 2, 3 do
		local other = list[i]
		view.rows[i - 1].Visible = other ~= nil
		if other then
			view.rows[i - 1].Text = Locale.T("hall.rank", { rank = i, name = other.n, kg = kg(crop, other.f) })
		end
	end
	view.rows[3].Visible = mine ~= nil and HallConfig.Rank(board, crop.id, player.UserId) == nil
	if view.rows[3].Visible then
		view.rows[3].Text = Locale.T("hall.you", { kg = kg(crop, mine) })
	end
	-- the visible small lines move up under the top block
	local lines = 0
	for _, row in view.rows do
		if row.Visible then
			lines += 1
		end
	end
	layout(view, lines)
	local slot = 0
	for _, row in view.rows do
		if row.Visible then
			slot += 1
			row.Position = UDim2.fromScale(row.Position.X.Scale, (LABEL_TOP + (slot - 1) * LABEL_LINE - 0.05) / (LABEL_TOP + lines * LABEL_LINE))
		end
	end
end

-- Record board -------------------------------------------------------------------------------------------------------------

local record = nil -- { title, week, sub, rows = { [cropId] = { crop, holder, weight } } }

local function buildRecord()
	local boardModel = scene:FindFirstChild("RecordBoard")
	local screen = boardModel and boardModel:FindFirstChild("Screen")
	if not (screen and screen:IsA("BasePart")) then
		return
	end
	local gui = Instance.new("SurfaceGui")
	gui.Name = "HallRecords"
	gui.Face = Enum.NormalId.Front
	gui.AutoLocalize = false
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	local list = Instance.new("Frame")
	list.BackgroundTransparency = 1
	list.Size = UDim2.new(1, -40, 1, -24)
	list.Position = UDim2.fromOffset(20, 12)
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 2)
	layout.Parent = list
	list.Parent = gui
	local function line(order: number, height: number, props)
		local label = text(list, props)
		label.LayoutOrder = order
		label.Size = UDim2.new(1, 0, 0, height)
		label.TextScaled = false
		label.TextSize = height - 6
		return label
	end
	record = {
		title = line(1, 50, { TextColor3 = COLOR_GOLD }),
		week = line(2, 32, {}),
		sub = line(3, 40, { TextColor3 = COLOR_GOLD }),
		rows = {},
	}
	for i, crop in CropConfig.Crops do
		local row = Instance.new("Frame")
		row.BackgroundTransparency = if i % 2 == 0 then 1 else 0.85
		row.BackgroundColor3 = Color3.new(0, 0, 0)
		row.BorderSizePixel = 0
		row.LayoutOrder = 10 + i
		row.Size = UDim2.new(1, 0, 0, 27)
		local function cell(x: number, w: number, align: Enum.TextXAlignment): TextLabel
			local label = text(row, { Position = UDim2.new(x, 4, 0, 0), Size = UDim2.new(w, -8, 1, 0), TextXAlignment = align })
			label.TextScaled = false
			label.TextSize = 21
			label.TextWrapped = false
			label.TextTruncate = Enum.TextTruncate.AtEnd
			return label
		end
		record.rows[crop.id] = {
			crop = cell(0, 0.42, Enum.TextXAlignment.Left),
			holder = cell(0.42, 0.36, Enum.TextXAlignment.Left),
			weight = cell(0.78, 0.22, Enum.TextXAlignment.Right),
		}
		row.Parent = list
	end
	gui.Parent = screen
end

-- "3 d 4 h" / "7 h 59 min" until the week's end
local function untilEnd(): string?
	local endsAt = board and board.endsAt
	if type(endsAt) ~= "number" then
		return nil
	end
	local left = math.max(0, endsAt - workspace:GetServerTimeNow())
	if left >= 86400 then
		return Locale.T("hall.duration.dh", { d = math.floor(left / 86400), h = math.floor(left % 86400 / 3600) })
	end
	return Locale.Duration(left)
end

local function drawRecord()
	if not record then
		return
	end
	record.title.Text = Locale.T("hall.title")
	local left = untilEnd()
	record.week.Text = if left then Locale.T("hall.weekEnds", { time = left }) else ""
	record.sub.Text = Locale.T("hall.allTime")
	local best = board and board.best
	for _, crop in CropConfig.Crops do
		local row = record.rows[crop.id]
		local entry = type(best) == "table" and best[crop.id]
		row.crop.Text = Locale.T("hall.crop", { icon = crop.icon, crop = Locale.CropName(crop) })
		row.holder.Text = if type(entry) == "table" then tostring(entry.n) else Locale.T("hall.none")
		row.weight.Text = if type(entry) == "table" then Locale.T("hall.kg", { kg = kg(crop, entry.f) }) else ""
	end
end

-- Drawing ------------------------------------------------------------------------------------------------------------------

local function drawAll()
	local best = ownBest()
	for _, view in views do
		drawView(view, best)
	end
	drawRecord()
end

local function addPedestal(model: Instance)
	if model:IsA("Model") and model:IsDescendantOf(scene) and not views[model] then
		local view = newView(model)
		if view then
			views[model] = view
			drawView(view, ownBest())
		end
	end
end

decode()
buildRecord()
for _, model in CollectionService:GetTagged(HallConfig.PedestalTag) do
	addPedestal(model)
end
CollectionService:GetInstanceAddedSignal(HallConfig.PedestalTag):Connect(addPedestal)

folder:GetAttributeChangedSignal("Board"):Connect(function()
	decode()
	drawAll()
end)
player:GetAttributeChangedSignal(HallConfig.WeekBestAttribute):Connect(drawAll)
Locale.Changed:Connect(drawAll)

-- the draw distance and the countdown
task.spawn(function()
	local anchor = scene:FindFirstChild("RecordBoard")
	while true do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local centre = anchor and anchor:IsA("Model") and anchor:GetPivot().Position
		local distance = if root and root:IsA("BasePart") and centre then (root.Position - centre).Magnitude else math.huge
		local wanted = if near then distance <= DRAW_DISTANCE + 20 else distance <= DRAW_DISTANCE
		if wanted ~= near then
			near = wanted
			drawAll()
		else
			drawRecord()
		end
		task.wait(if near then 5 else 2)
	end
end)

-- Toast --------------------------------------------------------------------------------------------------------------------

local popup = HudPopup.new("HallToast", {
	displayOrder = 6,
	position = UDim2.new(0.5, 0, 0, 150),
	width = 340,
	stroke = { color = COLOR_GOLD, thickness = 2 },
	tapCloses = true,
	pop = true,
})
local toastLine = popup.Line("Text", 1, 18, { RichText = false })

folder:WaitForChild("Toast").OnClientEvent:Connect(function(name, cropId, f)
	local crop = type(cropId) == "string" and CropConfig.ById[cropId]
	if not (crop and type(name) == "string" and type(f) == "number") then
		return
	end
	popup.Show(function()
		toastLine.Text = Locale.T("hall.toast", { name = name, crop = Locale.CropName(crop), kg = kg(crop, f) })
		return true
	end, TOAST_SECONDS)
end)
