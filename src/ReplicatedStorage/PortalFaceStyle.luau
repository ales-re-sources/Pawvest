-- PortalFaceStyle: the text style of every status line drawn on a hub portal / gate face (stars, coins found, lock requirement),
-- so the Tutorial portal, the world gates and any portal added later read the same: black text with a white outline. The
-- portal's name ("Tutorial", "World 1"; Studio, SurfaceGui "Label") stays white with a dark outline, the contrast to these lines.
-- The door faces of the world stages follow their own closed / open rule in HubPortalMedals.
-- The outline is a UIStroke, not TextStroke: TextStroke is always 1 px and vanishes into the text from a distance, while a
-- UIStroke of a few pixels keeps its share of the 40-70 px tall face text when the whole face shrinks.

local PortalFaceStyle = {}

PortalFaceStyle.TextColor = Color3.new(0, 0, 0)
PortalFaceStyle.StrokeColor = Color3.new(1, 1, 1)
PortalFaceStyle.StrokeTransparency = 0
PortalFaceStyle.StrokeThickness = 3.5 -- status lines (about 40-60 px tall on the 50 px / stud face SurfaceGuis)
PortalFaceStyle.NameStrokeThickness = 5 -- the portal's name label (about 70 px tall)
PortalFaceStyle.Font = Enum.Font.GothamBold

-- Replaces the label's TextStroke with a UIStroke (reused when there is one; a clone of the label carries it along).
function PortalFaceStyle.Outline(label: TextLabel, color: Color3, transparency: number, thickness: number)
	label.TextStrokeTransparency = 1
	local stroke = label:FindFirstChild("Outline") or Instance.new("UIStroke")
	stroke.Name = "Outline"
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Color = color
	stroke.Transparency = transparency
	stroke.Thickness = thickness
	stroke.Parent = label
end

function PortalFaceStyle.Apply(label: TextLabel)
	label.Font = PortalFaceStyle.Font
	label.TextColor3 = PortalFaceStyle.TextColor
	PortalFaceStyle.Outline(label, PortalFaceStyle.StrokeColor, PortalFaceStyle.StrokeTransparency, PortalFaceStyle.StrokeThickness)
end

-- The Studio-authored name label of a portal (`face` = its SurfaceGui): keeps the colour of its TextStroke, thicker.
function PortalFaceStyle.OutlineName(face: SurfaceGui?)
	if not face then
		return
	end
	for _, label in face:GetDescendants() do
		if label:IsA("TextLabel") and not label:FindFirstChild("Outline") and label.TextStrokeTransparency < 1 then
			PortalFaceStyle.Outline(label, label.TextStrokeColor3, 0, PortalFaceStyle.NameStrokeThickness)
		end
	end
end

return PortalFaceStyle
