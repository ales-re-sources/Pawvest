-- PortalFaceStyle: the text style of every line drawn on a hub portal / gate face (stars, coins found, lock requirement), so the
-- Tutorial portal, the world gates and any portal added later read the same: white text with the dark-navy outline of the
-- portal's name label (Studio, SurfaceGui "Label": white GothamBlack, stroke 20 / 45 / 80). The door faces of the world stages
-- follow their own closed / open rule in HubPortalMedals.

local PortalFaceStyle = {}

PortalFaceStyle.TextColor = Color3.new(1, 1, 1)
PortalFaceStyle.StrokeColor = Color3.fromRGB(20, 45, 80)
PortalFaceStyle.StrokeTransparency = 0.1
PortalFaceStyle.Font = Enum.Font.GothamBold

function PortalFaceStyle.Apply(label: TextLabel)
	label.Font = PortalFaceStyle.Font
	label.TextColor3 = PortalFaceStyle.TextColor
	label.TextStrokeColor3 = PortalFaceStyle.StrokeColor
	label.TextStrokeTransparency = PortalFaceStyle.StrokeTransparency
end

return PortalFaceStyle
