-- UiKit: the GUI builders every code-built panel shares (client only; GardenUi re-exports them). It lives in
-- ReplicatedStorage so StarterGui scripts can require it too.
--   * Create(className, props, children): an instance with its properties and children set;
--   * Label (a transparent left-aligned TextLabel in StudStyle.Font), Button (a StudStyle brick: colour and text keep being
--     set on the button itself), Paragraph (a label that wraps and grows downwards), Section (a list frame that grows),
--     Clear (removes a list's content, keeping UIComponent layout / chrome);
--   * PointerPosition(): current pointer in GUI-inset coordinates, for native world click events with no position argument;
--   * BlocksWorld(playerGui, point): hit-test Active / InputSink UI and controls (including passive children) before world tap / hover;
--   * Bar(name, opts): a rounded progress bar (track, fill and an optional centred text) → (track, fill, text?);
--     SetShare(fill, share) moves its fill;
--   * Latest(): "only the latest call acts" → { After(seconds, fn), Cancel() }: a new After (or Cancel) drops the pending one
--     (message and status lines that clear themselves);
--   * Toast(label, seconds, fadeSeconds?): a one-message label → show(text, color?, seconds?);
--   * Pulse(target, scale?, seconds?): a UIScale "Pulse" on target that breathes while on → setter(on: boolean);
--   * Shake(target): a short sideways shake (a refused tap on a buy brick);
--   * Notice(parent, props?): a plate over a row's text saying why a tap was refused, without moving the row → show(text?, seconds?).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))

local UiKit = {}

-- Native world click events do not carry a position; retain the current touch for the shared GUI guard.
local touchPoint: Vector2? = nil
local function rememberTouch(input: InputObject)
	if input.UserInputType == Enum.UserInputType.Touch then
		touchPoint = Vector2.new(input.Position.X, input.Position.Y)
	end
end
UserInputService.InputBegan:Connect(rememberTouch)
UserInputService.InputChanged:Connect(rememberTouch)

function UiKit.PointerPosition(): Vector2
	if UserInputService:GetLastInputType() == Enum.UserInputType.Touch and touchPoint then
		return touchPoint
	end
	local inset = GuiService:GetGuiInset()
	return UserInputService:GetMouseLocation() - inset
end

function UiKit.Create(className: string, props, children)
	local instance = Instance.new(className)
	for key, value in props do
		(instance :: any)[key] = value
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	return instance
end
local create = UiKit.Create

function UiKit.BlocksWorld(playerGui: PlayerGui, point: Vector2): boolean
	for _, object in playerGui:GetGuiObjectsAtPosition(point.X, point.Y) do
		local node: Instance? = object
		while node and node ~= playerGui do
			if node:IsA("GuiObject") and (node.Active or node.InputSink ~= Enum.InputSink.None or node:IsA("GuiButton") or node:IsA("TextBox")) then
				return true
			end
			node = node.Parent
		end
	end
	return false
end

function UiKit.Label(name: string, props)
	props.Name = name
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.Font = props.Font or StudStyle.Font
	props.TextColor3 = props.TextColor3 or Color3.new(1, 1, 1)
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	return create("TextLabel", props)
end

-- Legacy stud counts or explicit brick options (e.g. { compact = true }).
function UiKit.Button(name: string, props, studs: (number | { compact: boolean? })?)
	props.Name = name
	props.TextColor3 = Color3.new(1, 1, 1)
	local instance = create("TextButton", props)
	StudStyle.Brick(instance, if type(studs) == "table" then studs else { studs = studs })
	return instance
end

function UiKit.Paragraph(name: string, props)
	props.Size = props.Size or UDim2.new(1, 0, 0, 0)
	props.AutomaticSize = Enum.AutomaticSize.Y
	props.TextWrapped = true
	props.Font = props.Font or Enum.Font.Gotham
	props.TextSize = props.TextSize or 14
	props.TextColor3 = props.TextColor3 or StudStyle.Text.Info
	props.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Top
	return UiKit.Label(name, props)
end

function UiKit.Clear(section: Instance)
	for _, child in section:GetChildren() do
		if not child:IsA("UIComponent") then
			child:Destroy()
		end
	end
end

function UiKit.Section(name: string, order: number, gap: number?)
	return create("Frame", {
		Name = name,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, {
		create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, gap or 6) }),
	})
end

-- opts: order?, height, track (colour), fill (colour), share (0..1), corner? (px, default 6), text?, textSize?,
-- textStroke? (default 0.5), parent?
function UiKit.Bar(name: string, opts)
	local share = math.clamp(opts.share or 0, 0, 1)
	local corner = UDim.new(0, opts.corner or 6)
	local track = create("Frame", {
		Name = name,
		LayoutOrder = opts.order or 0,
		Size = UDim2.new(1, 0, 0, opts.height),
		BackgroundColor3 = opts.track,
		BorderSizePixel = 0,
	}, { create("UICorner", { CornerRadius = corner }) })
	local fill = create("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(share, 1),
		BackgroundColor3 = opts.fill,
		BorderSizePixel = 0,
		Visible = share > 0,
		Parent = track,
	}, { create("UICorner", { CornerRadius = corner }) })
	local text = nil
	if opts.text then
		text = UiKit.Label("Text", {
			Size = UDim2.fromScale(1, 1),
			TextSize = opts.textSize or 12,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextStrokeTransparency = opts.textStroke or 0.5,
			Text = opts.text,
			ZIndex = 2,
			Parent = track,
		})
	end
	track.Parent = opts.parent
	return track, fill, text
end

-- a bar's fill at share (0..1); hidden at 0 (a rounded empty fill would show as a dot)
function UiKit.SetShare(fill: GuiObject, share: number)
	share = math.clamp(share, 0, 1)
	fill.Size = UDim2.fromScale(share, 1)
	fill.Visible = share > 0
end

function UiKit.Latest()
	local token = 0
	local api = {}
	function api.After(seconds: number, fn: () -> ())
		token += 1
		local mine = token
		task.delay(seconds, function()
			if token == mine then
				fn()
			end
		end)
	end
	function api.Cancel()
		token += 1
	end
	return api
end

-- A label that shows one message at a time: show(text, color?, seconds?) puts it up (white by default) for `seconds` (else
-- defaultSeconds); a newer message replaces it. With fadeSeconds it fades out (text and background) before hiding.
function UiKit.Toast(label: TextLabel, defaultSeconds: number, fadeSeconds: number?): (string, Color3?, number?) -> ()
	local timer = UiKit.Latest()
	local background = label.BackgroundTransparency
	local fade: Tween? = nil
	label.Visible = false
	local function hide()
		label.Visible = false
	end
	return function(text: string, color: Color3?, seconds: number?)
		if fade then
			fade:Cancel()
			fade = nil
		end
		label.Text = text
		label.TextColor3 = color or Color3.new(1, 1, 1)
		label.TextTransparency = 0
		label.BackgroundTransparency = background
		label.Visible = true
		timer.After(seconds or defaultSeconds, function()
			if not fadeSeconds then
				return hide()
			end
			fade = TweenService:Create(label, TweenInfo.new(fadeSeconds), { TextTransparency = 1, BackgroundTransparency = 1 })
			;(fade :: Tween):Play()
			timer.After(fadeSeconds, hide)
		end)
	end
end

function UiKit.Pulse(target: GuiObject, scale: number?, seconds: number?): (boolean) -> ()
	local uiScale = create("UIScale", { Name = "Pulse", Parent = target })
	local tween: Tween? = nil
	return function(on: boolean)
		if on == (tween ~= nil) then
			return
		end
		if tween then
			tween:Cancel()
			tween = nil
			uiScale.Scale = 1
			return
		end
		tween = TweenService:Create(
			uiScale,
			TweenInfo.new(seconds or 0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Scale = scale or 1.12 }
		)
		;(tween :: Tween):Play()
	end
end

-- A short sideways shake of `target` (a refused tap on a buy brick); a shake already running is not restarted.
local shaking: { [GuiObject]: boolean } = setmetatable({}, { __mode = "k" }) :: any
function UiKit.Shake(target: GuiObject)
	if shaking[target] then
		return
	end
	shaking[target] = true
	local home = target.Position
	task.spawn(function()
		for _, dx in { -6, 6, -4, 4, -2, 2 } do
			target.Position = home + UDim2.fromOffset(dx, 0)
			task.wait(0.035)
		end
		target.Position = home
		shaking[target] = nil
	end)
end

UiKit.NOTICE_SECONDS = 2.5

-- A red StudStyle plate over a row's text that says why a tap was refused ("Needs: 💰 1,200 more, Cucumber 5/20"). It lies
-- over the title and info lines (`props` place it; default: fills `parent`), so nothing in the row moves or grows. Its 2 px
-- outline is drawn outside the frame: place the frame NOTICE_INSET from the row's edges and the brick for an even 4 px margin.
-- → show(text?, seconds?): nil text hides it; it hides itself after `seconds` (NOTICE_SECONDS); and the label (to resize it).
-- The parent must not have a UIListLayout. In an AutomaticSize parent a Y scale counts against the parent's base Size plus its
-- UIPadding: keep position + offset + padding ≤ 0, or size it in offsets.
UiKit.NOTICE_INSET = 6
function UiKit.Notice(parent: GuiObject, props: { [string]: any }?): ((string?, number?) -> (), TextLabel)
	local color = StudStyle.Colors.Red
	local label = create("TextLabel", {
		Name = "Notice",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = color,
		BackgroundTransparency = 0, -- opaque: the row's name must not show through
		TextSize = 15,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoLocalize = false,
		ZIndex = 6,
		Visible = false,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 6) }),
		create("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = StudStyle.Shade(color, 0.62), -- StudStyle's edge shade
			Thickness = 2,
		}),
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(215, 215, 215)) }),
		create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
		create("UITextSizeConstraint", { MaxTextSize = 15, MinTextSize = 10 }),
	})
	StudStyle.Title(label, color) -- white with an outline in the red's shade
	for key, value in props or {} do
		(label :: any)[key] = value
	end
	label.TextScaled = true -- a long list shrinks inside the plate instead of growing the row
	label.Parent = parent
	local timer = UiKit.Latest()
	local function show(text: string?, seconds: number?)
		if not text then
			timer.Cancel()
			label.Visible = false
			return
		end
		label.Text = text
		label.Visible = true
		timer.After(seconds or UiKit.NOTICE_SECONDS, function()
			label.Visible = false
		end)
	end
	return show, label
end

return UiKit
