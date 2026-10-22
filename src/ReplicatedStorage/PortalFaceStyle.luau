-- PortalFaceStyle: the text style of every status line drawn on a hub portal / gate face (stars, coins found, lock requirement),
-- so the Tutorial portal, the world gates and any portal added later read the same: black text with a white outline. The
-- portal's name ("Tutorial", "World 1"; Studio, SurfaceGui "Label") stays white with a dark outline, the contrast to these lines.
-- The door faces of the world stages follow their own closed / open rule in HubPortalMedals.

local PortalFaceStyle = {}

PortalFaceStyle.TextColor = Color3.new(0, 0, 0)
PortalFaceStyle.StrokeColor = Color3.new(1, 1, 1)
PortalFaceStyle.StrokeTransparency = 0.15
PortalFaceStyle.Font = Enum.Font.GothamBold

function PortalFaceStyle.Apply(label: TextLabel)
	label.Font = PortalFaceStyle.Font
	label.TextColor3 = PortalFaceStyle.TextColor
	label.TextStrokeColor3 = PortalFaceStyle.StrokeColor
	label.TextStrokeTransparency = PortalFaceStyle.StrokeTransparency
end

return PortalFaceStyle
