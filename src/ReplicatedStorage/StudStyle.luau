-- StudStyle: the rounded brick look of the screen GUI (top-left icons, panels, coin counter, status card), built in code
-- so no Studio layout edit is needed.
--   Brick(button, options)  a button becomes a brick: dark Lip (the brick's side) under a Top frame with the coloured
--                           Face and a Glyph label. The button's BackgroundColor3 is the brick
--                           colour and its Text the glyph: both stay the source of truth (the button's own text is only
--                           made invisible), so scripts that set them keep working. Hover lifts the Top, a press sinks it.
--                           Calling it again (e.g. on a clone of a styled button) rebuilds the look.
--   Panel(frame, color)     slide-in panel: deep tone of the colour, dark outline, TitleLabel as a flat stud-textured strip
--   Row(frame, panelName)   a row inside a panel: a lighter tone of that panel's colour
--   Plate(frame, color)     a free-standing plate (coin counter, status card): colour, outline, shine
--   Title(label, color)     chunky white text with a dark outline in the colour's shade
--   Coin(holder, color?)    stud coin icon (gold disc, beaded border, one embossed stud) drawn inside an ImageLabel / Frame

local TweenService = game:GetService("TweenService")

local StudStyle = {}

-- Desired on-screen sizes; callers divide by their UIScale before laying out controls.
StudStyle.Sizes = { Header = 40, Tab = 36, HudButton = 40, Action = 40 }

StudStyle.Colors = {
	Red = Color3.fromRGB(229, 83, 61),
	Yellow = Color3.fromRGB(245, 180, 0),
	Green = Color3.fromRGB(58, 165, 92),
	Blue = Color3.fromRGB(47, 127, 214),
	Purple = Color3.fromRGB(125, 91, 208),
	Wood = Color3.fromRGB(165, 108, 62),
	Grey = Color3.fromRGB(128, 128, 134),
}

-- status texts on the dark panels: Info (light parchment), Dim, Ok, Error, Rare (gold), Grey (the pet panels' info line)
StudStyle.Text = {
	Info = Color3.fromRGB(235, 222, 190),
	Dim = Color3.fromRGB(190, 178, 150),
	Ok = Color3.fromRGB(120, 230, 120),
	Error = Color3.fromRGB(240, 100, 90),
	Rare = Color3.fromRGB(255, 205, 90),
	Grey = Color3.fromRGB(190, 190, 190),
}

-- the panel colour is the colour of the icon that opens it
StudStyle.PanelColors = {
	SkillsPanel = StudStyle.Colors.Yellow,
	SettingsPanel = StudStyle.Colors.Blue,
	AdminPanel = StudStyle.Colors.Purple,
	PetsPanel = StudStyle.Colors.Green, -- PetsGui.Panel (PetsPanel.client)
	Field = StudStyle.Colors.Wood, -- the field's wood: FieldHand's card and pickers (the Garden panel is gone, U4)
	Incubator = StudStyle.Colors.Yellow, -- HatcheryGui.Panel (IncubatorClient)
	FoodShop = StudStyle.Colors.Red, -- FoodShopGui.Panel (FoodShopClient)
}

-- dark row behind pet names in rarity colours (green, blue, purple, gold must all read on it)
function StudStyle.PetRowColor(panelColor: Color3): Color3
	return StudStyle.Shade(panelColor, 0.28)
end

-- BuilderSansBold has Latin Extended-A (Czech) and Cyrillic; FredokaOne has neither (docs/LOCALIZATION.md → Font check)
StudStyle.Font = Enum.Font.BuilderSansBold

local LIP = 5 -- pixels of brick side under the face
local LIFT_HOVER = -2
local LIFT_TWEEN = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local EDGE = 0.62 -- shade of outlines, lips and stud rims
local PANEL_BODY = 0.42
local PANEL_ROW = 0.6

-- factor < 1 darkens towards black, > 1 lightens towards white
function StudStyle.Shade(color: Color3, factor: number): Color3
	if factor < 1 then
		return color:Lerp(Color3.new(0, 0, 0), 1 - factor)
	end
	return color:Lerp(Color3.new(1, 1, 1), factor - 1)
end
local shade = StudStyle.Shade

local function corner(parent: Instance, radius: number)
	local c = parent:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function outline(parent: Instance, color: Color3, thickness: number)
	local s = parent:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Color = color
	s.Thickness = thickness
	s.Transparency = 0
	s.Enabled = true
	s.Parent = parent
	return s
end

local function shine(parent: Instance)
	local g = parent:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(215, 215, 215))
	g.Parent = parent
end

function StudStyle.Title(label: TextLabel | TextButton, color: Color3)
	label.Font = StudStyle.Font
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeColor3 = shade(color, 0.35)
	label.TextStrokeTransparency = 0.2
end

-- Reuse StudPack's colour map as a faint, flat pattern. The original label still owns text / sizing;
-- a foreground copy keeps the texture behind the words, including after a language or layout change.
local function textureTitle(title: TextLabel)
	local texture = title:FindFirstChild("HeaderTexture") :: ImageLabel?
	if not texture then
		texture = Instance.new("ImageLabel")
		texture.Name = "HeaderTexture"
		texture.BackgroundTransparency = 1
		texture.Image = "rbxassetid://10509831729" -- MaterialService.StudPack.Studs.ColorMap
		texture.ImageTransparency = 0.65
		texture.ScaleType = Enum.ScaleType.Tile
		texture.TileSize = UDim2.fromScale(0.5, 0.5)
		texture.ZIndex = 0
		corner(texture, 10)
		texture.Parent = title

		local caption = Instance.new("TextLabel")
		caption.Name = "HeaderText"
		caption.BackgroundTransparency = 1
		caption.Size = UDim2.fromScale(1, 1)
		caption.AutoLocalize = false
		caption.TextStrokeTransparency = 0.2
		caption.ZIndex = 2
		caption.Parent = title
		for _, property in {
			"Text", "FontFace", "TextSize", "TextScaled", "TextWrapped", "RichText",
			"TextXAlignment", "TextYAlignment", "TextColor3", "TextStrokeColor3", "TextTruncate", "LineHeight",
		} do
			local function sync()
				(caption :: any)[property] = (title :: any)[property]
			end
			title:GetPropertyChangedSignal(property):Connect(sync)
			sync()
		end

		-- Padding belongs to the title's text and close button. Extend the texture back across the entire strip.
		local function fitTexture()
			local padding = title:FindFirstChildOfClass("UIPadding")
			local left = if padding then padding.PaddingLeft else UDim.new()
			local right = if padding then padding.PaddingRight else UDim.new()
			local top = if padding then padding.PaddingTop else UDim.new()
			local bottom = if padding then padding.PaddingBottom else UDim.new()
			texture.Position = UDim2.new(-left.Scale, -left.Offset, -top.Scale, -top.Offset)
			texture.Size = UDim2.new(1 + left.Scale + right.Scale, left.Offset + right.Offset,
				1 + top.Scale + bottom.Scale, top.Offset + bottom.Offset)
			-- Two complete rows at every header height; the aspect ratio keeps each stud square under UIScale.
			local size = title.AbsoluteSize
			texture.TileSize = UDim2.fromScale(if size.X > 0 then size.Y / (2 * size.X) else 0.5, 0.5)
		end
		local function watchPadding(child: Instance)
			if child:IsA("UIPadding") then
				for _, property in { "PaddingLeft", "PaddingRight", "PaddingTop", "PaddingBottom" } do
					child:GetPropertyChangedSignal(property):Connect(fitTexture)
				end
				fitTexture()
			end
		end
		title.ChildAdded:Connect(watchPadding)
		title.ChildRemoved:Connect(fitTexture)
		title:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitTexture)
		for _, child in title:GetChildren() do
			watchPadding(child)
		end
		fitTexture()
	end
	texture.ImageColor3 = title.BackgroundColor3
	title.TextTransparency = 1
	title.TextStrokeTransparency = 1
end

-- Legacy stud counts remain accepted for existing callers; controls now have smooth top edges.
function StudStyle.Brick(button: GuiButton, options: { studs: number?, socket: boolean?, compact: boolean? }?)
	local opts = options or {}
	local lipHeight = if opts.compact then 3 else LIP
	for _, name in { "Lip", "Top" } do
		local old = button:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	button.Style = Enum.ButtonStyle.Custom -- a legacy style (Reset Score's RobloxRoundButton) draws a grey box and insets children
	button.AutoButtonColor = false
	button.BackgroundTransparency = 1
	button.ClipsDescendants = false
	local ownStroke = button:FindFirstChildOfClass("UIStroke")
	if ownStroke then
		ownStroke.Enabled = false
	end
	local isText = button:IsA("TextButton")
	if isText then
		(button :: TextButton).TextTransparency = 1
		;(button :: TextButton).TextStrokeTransparency = 1
	end

	local lip = Instance.new("Frame")
	lip.Name = "Lip"
	lip.Size = UDim2.fromScale(1, 1)
	lip.BorderSizePixel = 0
	corner(lip, 7)
	lip.Parent = button

	local top = Instance.new("Frame")
	top.Name = "Top"
	top.Size = UDim2.new(1, 0, 1, -lipHeight)
	top.BackgroundTransparency = 1
	top.Parent = button

	local face = Instance.new("Frame")
	face.Name = "Face"
	face.Size = UDim2.fromScale(1, 1)
	face.BorderSizePixel = 0
	corner(face, 7)
	shine(face)
	face.Parent = top
	local faceStroke = outline(face, Color3.new(), 1.5)

	-- dark round socket behind the glyph: emoji stay readable on every brick colour (⚡ on yellow, ⚙ on blue)
	local socket
	if opts.socket then
		socket = Instance.new("Frame")
		socket.Name = "Socket"
		socket.AnchorPoint = Vector2.new(0.5, 0.5)
		socket.Position = UDim2.fromScale(0.5, 0.5)
		socket.Size = UDim2.fromOffset(34, 34)
		socket.BackgroundTransparency = 0.25
		socket.BorderSizePixel = 0
		corner(socket, 17)
		socket.Parent = face
	end

	local glyph
	if isText then
		local tb = button :: TextButton
		glyph = Instance.new("TextLabel")
		glyph.Name = "Glyph"
		glyph.Size = UDim2.fromScale(1, 1)
		glyph.BackgroundTransparency = 1
		glyph.Font = if opts.socket then tb.Font else StudStyle.Font
		glyph.TextSize = tb.TextSize
		glyph.TextScaled = tb.TextScaled
		glyph.TextWrapped = tb.TextWrapped
		glyph.RichText = tb.RichText -- e.g. a smaller second line (<font size>)
		glyph.TextColor3 = Color3.new(1, 1, 1)
		glyph.TextStrokeTransparency = if opts.socket then 1 else 0.3
		glyph.ZIndex = 2
		glyph.Parent = face
		local function syncText()
			glyph.Text = tb.Text
		end
		tb:GetPropertyChangedSignal("Text"):Connect(syncText)
		syncText()
	end

	local function recolor()
		local color = button.BackgroundColor3
		lip.BackgroundColor3 = shade(color, EDGE)
		face.BackgroundColor3 = color
		faceStroke.Color = shade(color, EDGE)
		if socket then
			socket.BackgroundColor3 = shade(color, 0.4)
		end
		if glyph then
			glyph.TextStrokeColor3 = shade(color, 0.35)
		end
	end
	button:GetPropertyChangedSignal("BackgroundColor3"):Connect(recolor)
	recolor()

	local hovering, pressed = false, false
	local function lift()
		local y = pressed and (lipHeight - 2) or (hovering and LIFT_HOVER or 0)
		TweenService:Create(top, LIFT_TWEEN, { Position = UDim2.fromOffset(0, y) }):Play()
	end
	button.MouseEnter:Connect(function()
		hovering = true
		lift()
	end)
	button.MouseLeave:Connect(function()
		hovering, pressed = false, false
		lift()
	end)
	button.MouseButton1Down:Connect(function()
		pressed = true
		lift()
	end)
	button.MouseButton1Up:Connect(function()
		pressed = false
		lift()
	end)
end

function StudStyle.Plate(frame: GuiObject, color: Color3, _studs: number?)
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = 0
	frame.ClipsDescendants = false
	corner(frame, 10)
	outline(frame, shade(color, EDGE), 3)
	shine(frame)
end

-- round disc filling `parent` (scale sizes, so it follows the holder)
local function disc(name: string, parent: Instance, size: number, y: number, color: Color3): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5, y)
	f.Size = UDim2.fromScale(size, size)
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.5, 0)
	c.Parent = f
	f.Parent = parent
	return f
end

-- Stud coin icon drawn inside `holder` (an ImageLabel's image is cleared): a gold disc with a dark edge under it,
-- a diagonal shine, a beaded border of small studs and one flat embossed stud in the middle. Square and round whatever
-- the holder's size; calling it again rebuilds the look.
function StudStyle.Coin(holder: GuiObject, color: Color3?)
	local gold = color or StudStyle.Colors.Yellow
	if holder:IsA("ImageLabel") or holder:IsA("ImageButton") then
		holder.Image = ""
	end
	holder.BackgroundTransparency = 1
	local old = holder:FindFirstChild("Coin")
	if old then
		old:Destroy()
	end
	local ratio = holder:FindFirstChildOfClass("UIAspectRatioConstraint") or Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 1
	ratio.Parent = holder

	local coin = Instance.new("Frame")
	coin.Name = "Coin"
	coin.BackgroundTransparency = 1
	coin.Size = UDim2.fromScale(1, 1)

	-- the coin's edge peeks out under the face like a brick's lip
	local edge = disc("Edge", coin, 0.88, 0.53, shade(gold, EDGE))
	outline(edge, shade(gold, 0.4), 2)
	local face = disc("Face", coin, 0.88, 0.47, shade(gold, 1.12))
	outline(face, shade(gold, 0.4), 2)
	-- metal shine: a light diagonal band across a slightly darker face
	local band = Instance.new("UIGradient")
	band.Rotation = 45
	local dim, lit = Color3.new(0.78, 0.78, 0.78), Color3.new(1, 1, 1)
	band.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, dim),
		ColorSequenceKeypoint.new(0.3, dim),
		ColorSequenceKeypoint.new(0.4, lit),
		ColorSequenceKeypoint.new(0.52, lit),
		ColorSequenceKeypoint.new(0.62, dim),
		ColorSequenceKeypoint.new(1, dim),
	})
	band.Parent = face

	-- beaded border like a minted coin: a ring of small studs
	local beads = 12
	for i = 1, beads do
		local a = (i - 1) / beads * math.pi * 2
		local bead = disc("Bead" .. i, face, 0.09, 0.5, shade(gold, 0.8))
		bead.Position = UDim2.fromScale(0.5 + 0.39 * math.cos(a), 0.5 + 0.39 * math.sin(a))
	end

	-- the stud embossed flat into the face: a thin shadow below, no glint
	disc("StudShadow", face, 0.4, 0.55, shade(gold, EDGE))
	local stud = disc("Stud", face, 0.4, 0.5, shade(gold, 1.12))
	outline(stud, shade(gold, 0.8), 1.5)

	coin.Parent = holder
	return coin
end

function StudStyle.Panel(frame: GuiObject, color: Color3)
	frame.BackgroundColor3 = shade(color, PANEL_BODY)
	frame.BackgroundTransparency = 0
	frame.ClipsDescendants = false
	corner(frame, 10)
	outline(frame, shade(color, 0.25), 3)
	-- the title strip sits on the top edge and the panel fits its rows (the Studio layouts were centred in a fixed
	-- 200 px frame, which left the Settings title floating mid-panel); scripts that set the height still work, as
	-- AutomaticSize only grows a frame to its content
	local layout = frame:FindFirstChildOfClass("UIListLayout")
	if layout then
		layout.VerticalAlignment = Enum.VerticalAlignment.Top
		frame.Size = UDim2.new(frame.Size.X, UDim.new(0, 0))
		frame.AutomaticSize = Enum.AutomaticSize.Y
		local padding = frame:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding")
		padding.PaddingBottom = UDim.new(0, 10)
		padding.Parent = frame
	end
	local title = frame:FindFirstChild("TitleLabel")
	if title and title:IsA("TextLabel") then
		title.BackgroundColor3 = color
		title.BackgroundTransparency = 0
		title.TextSize = math.max(title.TextSize, 18)
		corner(title, 10)
		shine(title)
		StudStyle.Title(title, color)
		textureTitle(title)
	end
end

function StudStyle.RowColor(panelName: string): Color3
	return shade(StudStyle.PanelColors[panelName] or StudStyle.Colors.Grey, PANEL_ROW)
end

function StudStyle.Row(frame: GuiObject, panelName: string)
	frame.BackgroundColor3 = StudStyle.RowColor(panelName)
	frame.BackgroundTransparency = 0
	corner(frame, 8)
end

return StudStyle
