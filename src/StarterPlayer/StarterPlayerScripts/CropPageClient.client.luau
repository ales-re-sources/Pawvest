-- Crop page (EV3c, docs/GDD.md §7.9 → crop upgrades): one common crop's mastery and its three upgrade lines. Opened from a ★ brick on
-- a seed stall row or a barn row, or from the Goals panel's Upgrades section (GardenUi.OpenCropPage: hook CropPageGui attribute Open =
-- crop id, Back = the ScreenGui to reopen on close).
--   * header: the crop's mastery line with a bar toward the next level, then the points: "1 point to spend", the plants still needed
--     for the next point, or "Fully upgraded!";
--   * three rows (CropConfig.PointLines: Value, Size, Speed), each with its points as dots (●●○, up to Points.PerLine) and its effect as
--     numbers from the real values: the sale of one standard crop (GardenUi.SalePrice), the average harvest weight (Sorter included), the
--     grow time (Growth upgrade included); a line below the maximum shows "now → with one more point" and a + brick (two taps, ConfirmTap;
--     grey without a free point: the server refuses), a full line shows ✓ and its value; once every point is spent at ★3 the other
--     lines show only their value.
--   * PanelFocus "CropPage" (closes the other panels; walking away closes it). The X closes it and reopens the panel it came from.
-- Display only: + names a crop and a line (GardenRemotes.CropPoint); GardenField checks the points and answers on GardenRemotes.Result
-- (FieldClient toasts it). Re-renders on every State, a language change and a resize.
-- Paths (under PlayerGui.CropPageGui.Panel): Content.Head, Content.Lines.<Line>.Add (the + brick) / .Done; Close.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CropConfig = require(ReplicatedStorage:WaitForChild("CropConfig"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local PanelFocus = require(ReplicatedStorage:WaitForChild("PanelFocus"))
local ConfirmTap = require(ReplicatedStorage:WaitForChild("ConfirmTap"))
local UiKit = require(ReplicatedStorage:WaitForChild("UiKit"))
local GardenView = require(script.Parent:WaitForChild("GardenView"))
local GardenUi = require(script.Parent:WaitForChild("GardenUi"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("GardenRemotes")
local cropPointEvent = remotes:WaitForChild("CropPoint")

local WIDTH = 400
local HEIGHT = 430
local ADD_WIDTH = 64

local COLOR = StudStyle.Colors.Wood
local COLOR_ROW = StudStyle.PetRowColor(COLOR)
local COLOR_TRACK = StudStyle.Shade(COLOR, 0.35)
local COLOR_FILL = StudStyle.Colors.Green

-- the texts of each line: name, effect (without → with the point), done (the value with it)
local LINE_KEYS = {
	Value = { name = "field.point.value", effect = "field.point.value.effect", done = "field.point.value.done" },
	Size = { name = "field.point.size", effect = "field.point.size.effect", done = "field.point.size.done" },
	Speed = { name = "field.point.speed", effect = "field.point.speed.effect", done = "field.point.speed.done" },
}

local ui = GardenUi.Panel("CropPageGui", COLOR, WIDTH, HEIGHT)
local headSection = GardenUi.Section("Head", 1)
headSection.Parent = ui.content
local linesSection = GardenUi.Section("Lines", 2)
linesSection.Parent = ui.content

local shown: string? = nil -- the crop id on the page
local back: string? = nil -- the ScreenGui to reopen on close

-- `pts` with one more point in `line`.
local function plusOne(pts, line: string)
	local copy = if type(pts) == "table" then table.clone(pts) else {}
	copy[line] = CropConfig.PointsIn(pts, line) + 1
	return copy
end

-- A line's points as dots: ● per point, ○ per point still open.
local function dots(n: number): string
	return string.rep("●", n) .. string.rep("○", CropConfig.Mastery.Points.PerLine - n)
end

-- The average harvest weight of `crop` with the points `pts`, as a { decimal } placeholder (two decimals: Garlic's 0.10 → 0.11 shows).
local function weight(field, crop, pts)
	local factor = (1 + CropConfig.ToolEffect(field.tools, "Sorter")) * CropConfig.SizeMult(pts)
	return { decimal = string.format("%.2f", crop.kg * factor) }
end

-- { from, to } of `line`'s effect: now and with one more point in it (the crop's other points count in both).
local function effectArgs(field, crop, pts, line: string)
	local without, with = pts, plusOne(pts, line)
	if line == "Value" then
		return { from = GardenUi.SalePrice(field, crop, without), to = GardenUi.SalePrice(field, crop, with) }
	elseif line == "Size" then
		return { from = weight(field, crop, without), to = weight(field, crop, with) }
	end
	return {
		from = GardenUi.Countdown(GardenUi.GrowSecondsOn(field, crop, without)),
		to = GardenUi.Countdown(GardenUi.GrowSecondsOn(field, crop, with)),
	}
end

local function renderHead(field, crop)
	local n = GardenUi.PlantsOf(field, crop)
	local level = CropConfig.MasteryLevel(crop, n, GardenUi.PointsOf(field, crop))
	local levels = CropConfig.LevelsOf(crop)
	local free = GardenUi.FreePoints(field, crop)
	local spent = CropConfig.SpentPoints(GardenUi.PointsOf(field, crop))
	GardenUi.Paragraph("Mastery", {
		LayoutOrder = 1,
		Font = StudStyle.Font,
		TextSize = 17,
		TextColor3 = Color3.new(1, 1, 1),
		Text = GardenUi.MasteryLine(field, crop) or "",
	}).Parent = headSection
	local need = levels[level + 1]
	if need then
		local from = levels[level] or 0
		UiKit.Bar("Bar", {
			order = 2,
			height = 18,
			track = COLOR_TRACK,
			fill = COLOR_FILL,
			share = math.clamp((n - from) / (need - from), 0, 1), -- a level kept by its points may sit below its count (FL)
			parent = headSection,
		})
	end
	local text, color
	if free > 0 then
		text, color = Locale.T("field.cropPage.points", { count = free }), GardenUi.COLOR_OK
	elseif spent >= #levels then
		text, color = Locale.T("field.cropPage.allDone"), GardenUi.COLOR_OK
	else
		text, color = Locale.T("field.cropPage.noPoints", { left = (need or n) - n }), GardenUi.COLOR_INFO
	end
	GardenUi.Paragraph("Points", { LayoutOrder = 3, Font = StudStyle.Font, TextSize = 16, TextColor3 = color, Text = text }).Parent =
		headSection
	GardenUi.Paragraph("Hint", { LayoutOrder = 4, TextSize = 13, TextColor3 = GardenUi.COLOR_DIM, Text = Locale.T("field.cropPage.hint") }).Parent =
		headSection
	GardenUi.Paragraph("GrowthHint", { LayoutOrder = 5, TextSize = 13, TextColor3 = GardenUi.COLOR_DIM, Text = GardenUi.GrowthHint(field) }).Parent = headSection
end

local function renderLines(field, crop)
	local pts = GardenUi.PointsOf(field, crop)
	local free = GardenUi.FreePoints(field, crop)
	local final = CropConfig.SpentPoints(pts) >= #CropConfig.LevelsOf(crop) -- every point of the top level spent: no + any more
	local tap = ui.TapHeight()
	for index, line in CropConfig.PointLines do
		local keys = LINE_KEYS[line]
		local have = CropConfig.PointsIn(pts, line)
		local taken = have >= CropConfig.Mastery.Points.PerLine
		local args = if taken or final then { to = effectArgs(field, crop, pts, line).from } else effectArgs(field, crop, pts, line)
		local row = GardenUi.Row(linesSection, line, index, COLOR_ROW)
		GardenUi.TextColumn(
			row,
			ADD_WIDTH + GardenUi.GAP,
			Locale.T(keys.name) .. "  " .. dots(have),
			Locale.T(if taken or final then keys.done else keys.effect, args)
		)
		if taken then
			GardenUi.Paragraph("Done", {
				LayoutOrder = 2,
				Size = UDim2.new(0, ADD_WIDTH, 0, 0),
				Font = StudStyle.Font,
				TextSize = 22,
				TextColor3 = GardenUi.COLOR_OK,
				TextXAlignment = Enum.TextXAlignment.Center,
				Text = "✓",
			}).Parent = row
		elseif not final then -- after the last point a line keeps what it has: no +
			local add = GardenUi.Button("Add", {
				LayoutOrder = 2,
				Size = UDim2.fromOffset(ADD_WIDTH, tap),
				BackgroundColor3 = if free > 0 then GardenUi.COLOR_BUY else GardenUi.COLOR_LOCKED,
				TextSize = 20,
				Text = "+",
				Parent = row,
			}, 2)
			local cropId = crop.id
			ConfirmTap.Wrap(add, "CropPoint" .. cropId .. line, function()
				return true -- a point is spent for good: always two taps
			end, function()
				cropPointEvent:FireServer(cropId, line)
			end)
		end
	end
end

local function render()
	local crop = shown and CropConfig.ById[shown]
	ui.title.Text = if crop then GardenUi.CropTitle(crop) .. GardenUi.Stars(GardenView.OwnField(), crop) else ""
	if not (crop and ui.panel.Visible) then
		return
	end
	GardenUi.Clear(headSection)
	GardenUi.Clear(linesSection)
	local field = GardenView.OwnField()
	if not field then
		GardenUi.Paragraph("Loading", { Text = Locale.T("common.loading") }).Parent = headSection
		return
	end
	renderHead(field, crop)
	renderLines(field, crop)
end

local function hide()
	PanelFocus.Closed("CropPage")
	ui.panel.Visible = false
end

local function open(cropId: string)
	local crop = CropConfig.ById[cropId]
	if not crop or crop.rare then
		return
	end
	shown = cropId
	PanelFocus.Open("CropPage", hide) -- walking away closes it (without going back)
	ui.Fit()
	ui.panel.Visible = true
	render()
end

ui.close.Activated:Connect(function()
	hide()
	local gui = back and playerGui:FindFirstChild(back)
	back = nil
	if gui then
		gui:SetAttribute("Open", true) -- back to the panel the page came from
	end
end)
ui.gui:GetAttributeChangedSignal("Open"):Connect(function()
	local cropId = ui.gui:GetAttribute("Open")
	if type(cropId) == "string" then
		ui.gui:SetAttribute("Open", nil)
		local from = ui.gui:GetAttribute("Back")
		back = if type(from) == "string" then from else nil
		ui.gui:SetAttribute("Back", nil)
		open(cropId)
	end
end)

remotes:WaitForChild("State").OnClientEvent:Connect(function()
	task.defer(render) -- after GardenView took the new state
end)
Locale.Changed:Connect(render)
ui.OnResize(render)

ui.gui.Parent = playerGui
