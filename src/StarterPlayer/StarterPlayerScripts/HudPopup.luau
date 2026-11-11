-- HudPopup: the small dark HUD popups built in code (StageResultsPopup, StageArrivalWarning, TalentGrantPopup,
-- StageExploreWarning). Client only.
--   HudPopup.new(name, opts) -> popup
--     opts: displayOrder, width (320), position (top centre, 90 px down), anchor (0.5, 0), padding { top, bottom, side? },
--     gap (6, between lines), stroke { color, thickness }?, tapCloses (the whole panel is a button that hides it),
--     pop (scales in), fadeSeconds (fades out before hiding)
--   popup.Line(name, order, textSize, props?) -> TextLabel     a centred bold line that wraps and grows the panel (RichText)
--   popup.Button(name, order, color, height?, textSize?)       a rounded button across the panel
--   popup.Show(render, seconds) -> boolean                     render() fills the lines (false = nothing to show); runs again
--                                                              on a language change; hides itself after `seconds`
--   popup.Hide()
-- The ScreenGui (ResetOnSpawn off, AutoLocalize off: texts come from Locale) is popup.gui, the panel popup.panel.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local UiKit = require(ReplicatedStorage:WaitForChild("UiKit"))

local create = UiKit.Create

local COLOR_PANEL = Color3.fromRGB(32, 32, 32)
local PANEL_TRANSPARENCY = 0.1

local HudPopup = {}

function HudPopup.new(name: string, opts)
	local padding = opts.padding or {}
	local panel = create(if opts.tapCloses then "TextButton" else "Frame", {
		Name = "Panel",
		AnchorPoint = opts.anchor or Vector2.new(0.5, 0),
		Position = opts.position or UDim2.new(0.5, 0, 0, 90),
		Size = UDim2.fromOffset(opts.width or 320, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = COLOR_PANEL,
		BackgroundTransparency = PANEL_TRANSPARENCY,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 12) }),
		create("UIPadding", {
			PaddingTop = UDim.new(0, padding.top or 12),
			PaddingBottom = UDim.new(0, padding.bottom or 12),
			PaddingLeft = UDim.new(0, padding.side or 0),
			PaddingRight = UDim.new(0, padding.side or 0),
		}),
		create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, opts.gap or 6),
		}),
	})
	if opts.tapCloses then
		local button = panel :: TextButton -- a button, so a tap on the text closes it too
		button.AutoButtonColor = false
		button.Text = ""
	end
	local stroke = opts.stroke
		and create("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border, -- on a TextButton panel the default would outline its (empty) text
			Color = opts.stroke.color,
			Thickness = opts.stroke.thickness or 2,
			Parent = panel,
		})
	local scale = opts.pop and create("UIScale", { Scale = 1, Parent = panel })

	local gui = create("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		DisplayOrder = opts.displayOrder or 5,
		Enabled = false,
		AutoLocalize = false, -- translated by Locale (L1)
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, { panel })

	local popup = { gui = gui, panel = panel }
	local timer = UiKit.Latest()
	local current: (() -> boolean?)? = nil -- the render on screen, run again on a language change
	local lines: { TextLabel } = {}
	local fades: { Tween } = {}

	function popup.Line(lineName: string, order: number, textSize: number, props: { [string]: any }?): TextLabel
		local base = {
			Name = lineName,
			LayoutOrder = order,
			Size = UDim2.new(1, -24, 0, textSize + 6),
			AutomaticSize = Enum.AutomaticSize.Y, -- wrapped lines (longer in Czech) grow the panel
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = textSize,
			TextColor3 = Color3.new(1, 1, 1),
			TextWrapped = true,
			RichText = true,
			Text = "",
			Parent = panel,
		}
		for key, value in props or {} do
			base[key] = value
		end
		local label = create("TextLabel", base)
		table.insert(lines, label)
		return label
	end

	function popup.Button(buttonName: string, order: number, color: Color3, height: number?, textSize: number?): TextButton
		return create("TextButton", {
			Name = buttonName,
			LayoutOrder = order,
			Size = UDim2.new(1, -48, 0, height or 36),
			BackgroundColor3 = color,
			Font = Enum.Font.GothamBold,
			TextSize = textSize or 16,
			TextColor3 = Color3.new(1, 1, 1),
			Text = "",
			Parent = panel,
		}, { create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	end

	function popup.Hide()
		timer.Cancel()
		current = nil
		gui.Enabled = false
	end

	local function setFade(alpha: number)
		for _, tween in fades do
			tween:Cancel()
		end
		table.clear(fades)
		panel.BackgroundTransparency = PANEL_TRANSPARENCY + (1 - PANEL_TRANSPARENCY) * alpha
		for _, label in lines do
			label.TextTransparency = alpha
		end
		if stroke then
			stroke.Transparency = alpha
		end
	end

	local function fadeOut()
		local seconds = opts.fadeSeconds
		local info = TweenInfo.new(seconds)
		local function fade(target: Instance, goal)
			local tween = TweenService:Create(target, info, goal)
			table.insert(fades, tween)
			tween:Play()
		end
		fade(panel, { BackgroundTransparency = 1 })
		for _, label in lines do
			fade(label, { TextTransparency = 1 })
		end
		if stroke then
			fade(stroke, { Transparency = 1 })
		end
		timer.After(seconds, popup.Hide)
	end

	function popup.Show(render: () -> boolean?, seconds: number): boolean
		if render() == false then
			return false
		end
		current = render
		if opts.fadeSeconds then
			setFade(0)
		end
		gui.Enabled = true
		if scale then
			scale.Scale = 0.6
			TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		end
		timer.After(seconds, if opts.fadeSeconds then fadeOut else popup.Hide)
		return true
	end

	if opts.tapCloses then
		(panel :: TextButton).Activated:Connect(popup.Hide)
	end
	Locale.Changed:Connect(function()
		if gui.Enabled and current then
			current()
		end
	end)

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return popup
end

return HudPopup
