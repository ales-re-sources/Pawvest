-- StudStyle: the stud-brick look of the screen GUI (top-left icons, panels, coin counter, status card), built in code
-- so no Studio layout edit is needed.
--   Brick(button, options)  a button becomes a brick: dark Lip (the brick's side) under a Top frame with the coloured
--                           Face, studs on its upper edge and a Glyph label. The button's BackgroundColor3 is the brick
--                           colour and its Text the glyph: both stay the source of truth (the button's own text is only
--                           made invisible), so scripts that set them keep working. Hover lifts the Top, a press sinks it.
--                           Calling it again (e.g. on a clone of a styled button) rebuilds the look.
--   Panel(frame, color)     slide-in panel: deep tone of the colour, dark outline, TitleLabel as a brick strip with studs
--   Row(frame, panelName)   a row inside a panel: a lighter tone of that panel's colour
--   Plate(frame, color)     a free-standing plate (coin counter, status card): colour, outline, shine, studs on top
--   Title(label, color)     chunky white text with a dark outline in the colour's shade

local TweenService = game:GetService("TweenService")

local StudStyle = {}

StudStyle.Colors = {
	Red = Color3.fromRGB(229, 83, 61),
	Yellow = Color3.fromRGB(245, 180, 0),
	Green = Color3.fromRGB(58, 165, 92),
	Blue = Color3.fromRGB(47, 127, 214),
	Purple = Color3.fromRGB(125, 91, 208),
	Wood = Color3.fromRGB(165, 108, 62),
	Grey = Color3.fromRGB(128, 128, 134),
}

-- the panel colour is the colour of the icon that opens it
StudStyle.PanelColors = {
	SkillsPanel = StudStyle.Colors.Yellow,
	SettingsPanel = StudStyle.Colors.Blue,
	AdminPanel = StudStyle.Colors.Purple,
}

StudStyle.Font = Enum.Font.FredokaOne

local LIP = 5 -- pixels of brick side under the face
local LIFT_HOVER = -2
local LIFT_PRESS = LIP - 2
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

-- `count` studs evenly spread along the top edge of `parent`, sticking out above it
local function addStuds(parent: Instance, color: Color3, count: number, width: number?)
	local old = parent:FindFirstChild("Studs")
	if old then
		old:Destroy()
	end
	local holder = Instance.new("Frame")
	holder.Name = "Studs"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, 0, 0, 0)
	for i = 1, count do
		local stud = Instance.new("Frame")
		stud.Name = "Stud" .. i
		stud.AnchorPoint = Vector2.new(0.5, 1)
		stud.Position = UDim2.new((i - 0.5) / count, 0, 0, 2)
		stud.Size = UDim2.fromOffset(width or 14, 7)
		stud.BackgroundColor3 = shade(color, 1.12)
		stud.BorderSizePixel = 0
		corner(stud, 3)
		outline(stud, shade(color, EDGE), 1.5)
		stud.Parent = holder
	end
	holder.Parent = parent
	return holder
end

function StudStyle.Title(label: TextLabel | TextButton, color: Color3)
	label.Font = StudStyle.Font
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeColor3 = shade(color, 0.35)
	label.TextStrokeTransparency = 0.2
end

function StudStyle.Brick(button: GuiButton, options: { studs: number?, socket: boolean? }?)
	local opts = options or {}
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
	top.Size = UDim2.new(1, 0, 1, -LIP)
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

	local studs
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
		studs = addStuds(top, color, opts.studs or 2)
		studs.ZIndex = 0
	end
	button:GetPropertyChangedSignal("BackgroundColor3"):Connect(recolor)
	recolor()

	local hovering, pressed = false, false
	local function lift()
		local y = pressed and LIFT_PRESS or (hovering and LIFT_HOVER or 0)
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

function StudStyle.Plate(frame: GuiObject, color: Color3, studs: number?)
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = 0
	frame.ClipsDescendants = false
	corner(frame, 10)
	outline(frame, shade(color, EDGE), 3)
	shine(frame)
	addStuds(frame, color, studs or 3, 18)
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
		addStuds(title, color, 6, 18)
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
