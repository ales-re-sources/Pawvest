-- Crop page (EV3c, docs/GDD.md §7.9 → crop upgrades): one common crop's mastery, its three upgrade lines and its stats. Opened from
-- a ★ brick on a seed stall row or a barn row, or from the Goals panel's Upgrades section (GardenUi.OpenCropPage: hook CropPageGui
-- attribute Open = crop id, Back = the ScreenGui to reopen on close).
--   * star track (Content.Head.Track): the crop's icon, then one star per mastery level, evenly spaced on one bar. Each star is one
--     upgrade point (all of them shown, like the field pet slots): gold = earned (a green "+1" badge while its point is unspent;
--     earned stars count as spent first), faint outline = still to grow. The segment toward the next star is the progress bar with
--     "have / need" inside it; the plant count of every star sits under it. Under the track one fixed-height line: "N points: pick
--     an upgrade", "Fully upgraded!" or (no point free) the dim rule "Each ★ gives 1 point. A spent point stays.";
--   * three cards (CropConfig.PointLines: Value, Size, Speed): icon tile, name, the effect from the real values (sale of one
--     standard crop, average harvest weight with the Sorter, away-time grow time with Growth) in a two-line box, "now → with one
--     more point" with the new value in green while the line can still take a point. A column of square pips (points in that line,
--     up to Points.PerLine; the three cards' pips stand under each other), then the action slot: a green "Upgrade" brick (two
--     taps, ConfirmTap) only while a point is free, ✓ on a full line, else empty.
--   Every state has the same parts and sizes: spending a point moves nothing under the pointer and leaves no gap at the bottom;
--   * stats tiles (two per row): plants grown, biggest harvest, Coins earned (sales and request bonuses, Garden.Earned) and weeks
--     won as crop of the week (Garden.Ribbons).
--   * PanelFocus "CropPage" (closes the other panels; walking away closes it). The X closes it and reopens the panel it came from.
-- Display only: Upgrade names a crop and a line (GardenRemotes.CropPoint); GardenField checks the points and answers on
-- GardenRemotes.Result (FieldClient toasts it). Re-renders on every State, a language change and a resize.
-- Paths (under PlayerGui.CropPageGui.Panel): Content.Head.Track, Content.Lines.<Line>.Add (the Upgrade brick) / .Done,
-- Content.Stats.<Stat>; Close.

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
local HEIGHT = 515 -- the first estimate: the panel then fits its content (fitHeight)
local ADD_WIDTH = 88 -- the Upgrade brick
local ICON = 44 -- a card's icon tile
local NODE = 38 -- a star (and the crop icon) on the track
local SEGMENT = 20 -- the track's bar height
local TRACK_INSET = 4 -- room around the track for the nodes' strokes
local STATUS_HEIGHT = 20 -- the line under the track
local INFO_HEIGHT = 34 -- a card's effect: two lines of 14 px
local PIP = 12
local STAT_HEIGHT = 50
local create = GardenUi.Create

local COLOR = StudStyle.Colors.Wood
local COLOR_ROW = StudStyle.PetRowColor(COLOR)
local COLOR_TILE = StudStyle.Shade(COLOR, 0.8)
local COLOR_TRACK = StudStyle.Shade(COLOR, 0.35)
local COLOR_FILL = StudStyle.Colors.Green
local COLOR_GOLD = StudStyle.Colors.Yellow
local COLOR_OPEN = StudStyle.Shade(COLOR, 1.3) -- a star / pip still to fill
local OK_HEX = GardenUi.COLOR_OK:ToHex()

-- the texts of each line: name, effect (now → with the point), done (the value it has)
local LINE_KEYS = {
	Value = { name = "field.point.value", effect = "field.point.value.effect", done = "field.point.value.done" },
	Size = { name = "field.point.size", effect = "field.point.size.effect", done = "field.point.size.done" },
	Speed = { name = "field.point.speed", effect = "field.point.speed.effect", done = "field.point.speed.done" },
}

local ui = GardenUi.Panel("CropPageGui", COLOR, WIDTH, HEIGHT)
local headSection = GardenUi.Section("Head", 1, 8)
headSection.Parent = ui.content
local linesSection = GardenUi.Section("Lines", 2, 8)
linesSection.Parent = ui.content
local statsSection = GardenUi.Section("Stats", 3, 6)
statsSection.Parent = ui.content

local shown: string? = nil -- the crop id on the page
local back: string? = nil -- the ScreenGui to reopen on close

-- `pts` with one more point in `line`.
local function plusOne(pts, line: string)
	local copy = if type(pts) == "table" then table.clone(pts) else {}
	copy[line] = CropConfig.PointsIn(pts, line) + 1
	return copy
end

-- The average harvest weight of `crop` with the points `pts` ("0,31": two decimals, so Garlic's 0.10 → 0.11 shows).
local function weight(field, crop, pts): string
	local factor = (1 + CropConfig.ToolEffect(field.tools, "Sorter")) * CropConfig.SizeMult(pts)
	return Locale.Decimal(string.format("%.2f", crop.kg * factor))
end

-- `line`'s value as text with the points `pts`.
local function valueOf(field, crop, pts, line: string): string
	if line == "Value" then
		return Locale.Number(GardenUi.SalePrice(field, crop, pts))
	elseif line == "Size" then
		return weight(field, crop, pts)
	end
	return GardenUi.Countdown(GardenUi.GrowSecondsOn(field, crop, pts))
end

-- Node `index` (0 = the crop icon, 1..#levels = the stars) of `count` evenly spaced nodes on the track: its position (the first
-- node's left edge at the track's left, the last one's right edge at its right).
local function nodeX(index: number, count: number): UDim
	local share = index / (count - 1)
	return UDim.new(share, -share * NODE)
end

local function circle(name: string, props, stroke: Color3, thickness: number, transparency: number?)
	props.Size = UDim2.fromOffset(NODE, NODE)
	props.TextXAlignment = Enum.TextXAlignment.Center
	local node = UiKit.Label(name, props)
	create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = node })
	create("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = stroke, Thickness = thickness, Transparency = transparency or 0, Parent = node,
	})
	return node
end

-- The star track: the crop icon, the stars, the bars between them (the one toward the next star with "have / need"), each star's
-- plant count under it.
local function renderTrack(field, crop)
	local n = GardenUi.PlantsOf(field, crop)
	local levels = CropConfig.LevelsOf(crop)
	local level = CropConfig.MasteryLevel(crop, n, GardenUi.PointsOf(field, crop))
	local spent = CropConfig.SpentPoints(GardenUi.PointsOf(field, crop))
	local count = #levels + 1
	local track = create("Frame", {
		Name = "Track", LayoutOrder = 1, Size = UDim2.new(1, 0, 0, NODE + 20 + 2 * TRACK_INSET), BackgroundTransparency = 1,
		Parent = headSection,
	}, {
		-- the nodes' strokes draw outside them: keep them off the Content's clipping edge
		create("UIPadding", {
			PaddingLeft = UDim.new(0, TRACK_INSET), PaddingRight = UDim.new(0, TRACK_INSET),
			PaddingTop = UDim.new(0, TRACK_INSET), PaddingBottom = UDim.new(0, TRACK_INSET),
		}),
	})
	for index = 1, #levels do
		local from, need = levels[index - 1] or 0, levels[index]
		local left, right = nodeX(index - 1, count), nodeX(index, count)
		local share = if index <= level then 1 elseif index == level + 1 then math.clamp((n - from) / (need - from), 0, 1) else 0
		-- from the middle of the node before to the middle of this one (the nodes cover its ends)
		local bar = UiKit.Bar("Segment" .. index, {
			height = SEGMENT, track = COLOR_TRACK, fill = COLOR_FILL, share = share, corner = 4, textSize = 13,
			text = if index == level + 1 then string.format("%s / %s", Locale.Number(n), Locale.Number(need)) else nil,
			parent = track,
		})
		bar.Position = UDim2.new(left.Scale, left.Offset + NODE / 2, 0, (NODE - SEGMENT) / 2)
		bar.Size = UDim2.new(right.Scale - left.Scale, right.Offset - left.Offset, 0, SEGMENT)
	end
	local start = circle("Crop", {
		BackgroundColor3 = COLOR_TILE, BackgroundTransparency = 0, TextSize = 22, Text = crop.icon, ZIndex = 2, Parent = track,
	}, COLOR_OPEN, 2)
	start.Position = UDim2.new(nodeX(0, count), UDim.new(0, 0))
	for index, need in levels do
		local earned = index <= level
		local star = circle("Star" .. index, {
			BackgroundColor3 = if earned then COLOR_GOLD else COLOR_TRACK, BackgroundTransparency = 0, TextSize = 22,
			TextColor3 = if earned then Color3.new(1, 1, 1) else COLOR_OPEN, TextStrokeTransparency = if earned then 0.6 else 1,
			Text = "★", ZIndex = 2, Parent = track,
		}, if earned then Color3.new(1, 1, 1) else COLOR_OPEN, 2, if earned then 0.2 else 0.3)
		star.Position = UDim2.new(nodeX(index, count), UDim.new(0, 0))
		if earned and index > spent then -- this star's point is still to spend
			local badge = UiKit.Label("Free", {
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -2, 1, -4), Size = UDim2.fromOffset(26, 16),
				BackgroundColor3 = GardenUi.COLOR_BUY, BackgroundTransparency = 0, TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Center, Text = "+1", ZIndex = 3, Parent = star,
			})
			create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = badge })
		end
		UiKit.Label("Need" .. index, {
			AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(nodeX(index, count).Scale, nodeX(index, count).Offset + NODE / 2, 0, NODE + 3),
			Size = UDim2.fromOffset(NODE + 24, 16), Font = Enum.Font.GothamMedium, TextSize = 12,
			TextColor3 = if earned then COLOR_GOLD else GardenUi.COLOR_DIM, TextXAlignment = Enum.TextXAlignment.Center,
			Text = Locale.Number(need), Parent = track,
		})
	end
	-- one status line of a fixed height in every state, so spending a point moves nothing under the player's pointer
	local free = GardenUi.FreePoints(field, crop)
	local text, color, font, size
	if free > 0 then
		text, color, font, size = Locale.T("field.cropPage.free", { count = free }), GardenUi.COLOR_OK, StudStyle.Font, 16
	elseif spent >= #levels then
		text, color, font, size = Locale.T("field.cropPage.allDone"), GardenUi.COLOR_OK, StudStyle.Font, 16
	else
		text, color, font, size = Locale.T("field.cropPage.rule"), GardenUi.COLOR_DIM, Enum.Font.Gotham, 13
	end
	UiKit.Label("Points", {
		LayoutOrder = 2, Size = UDim2.new(1, 0, 0, STATUS_HEIGHT), Font = font, TextSize = size, TextColor3 = color,
		TextYAlignment = Enum.TextYAlignment.Center, TextWrapped = true, Text = text, Parent = headSection,
	})
end

-- A line's points as square pips (the field pet slots' look): filled = a point in it, outline = room for one more. A fixed-width
-- column, so the three cards' pips stand under each other.
local PIP_GAP = 5
local PIPS_WIDTH = CropConfig.Mastery.Points.PerLine * (PIP + PIP_GAP) + 2 -- the strokes draw outside the pips
local function pips(parent: Instance, have: number)
	local box = create("Frame", {
		Name = "Pips", LayoutOrder = 2, Size = UDim2.fromOffset(PIPS_WIDTH, PIP + 4), BackgroundTransparency = 1, Parent = parent,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, PIP_GAP),
			VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Right,
		}),
		create("UIPadding", { PaddingRight = UDim.new(0, 2) }),
	})
	for index = 1, CropConfig.Mastery.Points.PerLine do
		local filled = index <= have
		local pip = create("Frame", {
			Name = "Pip" .. index, LayoutOrder = index, Size = UDim2.fromOffset(PIP, PIP), BackgroundColor3 = COLOR_GOLD,
			BackgroundTransparency = if filled then 0 else 1, Parent = box,
		})
		create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = pip })
		create("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = if filled then Color3.new(1, 1, 1) else COLOR_OPEN, Thickness = 1.5,
			Parent = pip,
		})
	end
end

local function renderLines(field, crop)
	local pts = GardenUi.PointsOf(field, crop)
	local free = GardenUi.FreePoints(field, crop)
	local final = CropConfig.SpentPoints(pts) >= #CropConfig.LevelsOf(crop) -- every point of the top level spent: no preview any more
	local tap = ui.TapHeight()
	local canAdd = free > 0 and not final
	-- Every card always has the same parts and sizes (an action slot right of the pips: Upgrade brick, ✓ or empty; the effect in a
	-- two-line box), so spending a point changes no card's size and nothing moves under the pointer.
	for index, line in CropConfig.PointLines do
		local keys = LINE_KEYS[line]
		local have = CropConfig.PointsIn(pts, line)
		local taken = have >= CropConfig.Mastery.Points.PerLine
		local row = GardenUi.Row(linesSection, line, index, COLOR_ROW)
		local tile = UiKit.Label("Icon", {
			LayoutOrder = 0, Size = UDim2.fromOffset(ICON, ICON), BackgroundColor3 = COLOR_TILE, BackgroundTransparency = 0, TextSize = 24,
			TextXAlignment = Enum.TextXAlignment.Center, Text = CropConfig.PointIcons[line], Parent = row,
		})
		create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = tile })
		local reserved = ICON + GardenUi.GAP + PIPS_WIDTH + GardenUi.GAP + ADD_WIDTH + GardenUi.GAP
		local column = create("Frame", {
			Name = "Text", LayoutOrder = 1, Size = UDim2.new(1, -reserved, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, Parent = row,
		}, { create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3) }) })
		UiKit.Label("Name", {
			LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 20), TextSize = 17, Text = Locale.T(keys.name), Parent = column,
		})
		pips(row, have)
		local now = valueOf(field, crop, pts, line)
		local text = if taken or final then Locale.T(keys.done, { to = now })
			else Locale.T(keys.effect, {
				from = now,
				to = string.format('<font color="#%s">%s</font>', OK_HEX, valueOf(field, crop, plusOne(pts, line), line)),
			})
		UiKit.Label("Info", {
			LayoutOrder = 2, Size = UDim2.new(1, 0, 0, INFO_HEIGHT), Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = StudStyle.Text.Info,
			TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, RichText = true, Text = text, Parent = column,
		})
		if taken then
			UiKit.Label("Done", {
				LayoutOrder = 3, Size = UDim2.fromOffset(ADD_WIDTH, tap), TextSize = 24, TextColor3 = GardenUi.COLOR_OK,
				TextXAlignment = Enum.TextXAlignment.Center, Text = "✓", Parent = row,
			})
		elseif canAdd then -- without a free point the card shows only its preview: no grey dead brick
			local add = GardenUi.Button("Add", {
				LayoutOrder = 3, Size = UDim2.fromOffset(ADD_WIDTH, tap), BackgroundColor3 = GardenUi.COLOR_BUY, TextSize = 16,
				TextWrapped = true, Text = Locale.T("field.cropPage.upgrade"), Parent = row,
			}, 2)
			local cropId = crop.id
			ConfirmTap.Wrap(add, "CropPoint" .. cropId .. line, function()
				return true -- a point is spent for good: always two taps
			end, function()
				cropPointEvent:FireServer(cropId, line)
			end)
		else -- an empty slot of the brick's size
			create("Frame", { Name = "Slot", LayoutOrder = 3, Size = UDim2.fromOffset(ADD_WIDTH, tap), BackgroundTransparency = 1, Parent = row })
		end
	end
end

-- Stat tiles: value over label, two per row (the crop's history only: what the barn holds belongs to the barn).
local function renderStats(field, crop)
	local best = field.best and field.best[crop.id]
	local earned = type(field.earned) == "table" and tonumber(field.earned[crop.id]) or 0
	local ribbons = type(field.ribbons) == "table" and tonumber(field.ribbons[crop.id]) or 0
	local stats = {
		{ "Grown", "🌱", Locale.Number(GardenUi.PlantsOf(field, crop)), "field.cropPage.stat.grown" },
		{ "Biggest", "⚖️", if best then Locale.T("field.cropPage.stat.kg", { kg = GardenUi.KgText(crop, best) }) else "–", "field.cropPage.stat.biggest" },
		{ "Earned", "💰", Locale.Number(earned), "field.cropPage.stat.earned" },
		{ "Ribbons", "🏆", Locale.Number(ribbons), "field.cropPage.stat.ribbons" },
	}
	local perRow = 2
	local rowFrame
	for index, stat in stats do
		if (index - 1) % perRow == 0 then
			rowFrame = create("Frame", {
				Name = "StatRow" .. math.ceil(index / perRow), LayoutOrder = index, Size = UDim2.new(1, 0, 0, STAT_HEIGHT),
				BackgroundTransparency = 1, Parent = statsSection,
			}, {
				create("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, GardenUi.GAP),
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
				}),
			})
		end
		local tile = create("Frame", {
			Name = stat[1], LayoutOrder = index, Size = UDim2.new(1 / perRow, -GardenUi.GAP * (perRow - 1) / perRow, 1, 0),
			BackgroundColor3 = COLOR_ROW, Parent = rowFrame,
		}, {
			create("UICorner", { CornerRadius = UDim.new(0, 8) }),
			create("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), PaddingTop = UDim.new(0, 5) }),
		})
		UiKit.Label("Value", {
			Size = UDim2.new(1, 0, 0, 22), TextSize = 17, TextXAlignment = Enum.TextXAlignment.Center, TextScaled = false,
			Text = stat[2] .. " " .. stat[3], Parent = tile,
		})
		UiKit.Label("Label", {
			Position = UDim2.fromOffset(0, 23), Size = UDim2.new(1, 0, 0, 16), Font = Enum.Font.Gotham, TextSize = 12,
			TextColor3 = GardenUi.COLOR_DIM, TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true, Text = Locale.T(stat[4]),
			Parent = tile,
		})
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
	GardenUi.Clear(statsSection)
	local field = GardenView.OwnField()
	if not field then
		GardenUi.Paragraph("Loading", { Text = Locale.T("common.loading") }).Parent = headSection
		return
	end
	renderTrack(field, crop)
	renderLines(field, crop)
	renderStats(field, crop)
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

-- The panel is exactly as tall as its content (no scrollbar, no gap): the cards' bricks grow with a small screen's scale
-- (TapHeight), so no fixed height fits every device. Content sits HeaderHeight + 6 below the panel top and ends 8 above its bottom;
-- the list's own padding is 4 + 6. AbsoluteContentSize is scaled by the panel's UIScale.
local contentList = ui.content:FindFirstChildOfClass("UIListLayout") :: UIListLayout
local function fitHeight()
	if not ui.panel.Visible then
		return
	end
	local needed = math.ceil(contentList.AbsoluteContentSize.Y / ui.Scale() + 10 + ui.HeaderHeight() + 14)
	if math.abs(needed - ui.panel.Size.Y.Offset) >= 1 then
		ui.SetHeight(needed)
	end
end
contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fitHeight)
ui.panel:GetPropertyChangedSignal("Visible"):Connect(fitHeight)

ui.gui.Parent = playerGui
