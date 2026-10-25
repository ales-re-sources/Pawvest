-- PanelFit: fits the slide-in panels (Skills, Pets) to short screens, i.e. a phone held in landscape (about 375-430 px
-- high), where the panels designed for a desktop window ran off the bottom. On a short screen a panel is scaled down a
-- little (UIScale, never below MIN_SCALE) and the rest is solved by the panel itself: it caps its height at `MaxHeight`
-- and scrolls or compacts what does not fit. Tall screens get scale 1 and a huge maximum, so nothing changes there.
--   Scale()            UIScale value for a panel
--   MaxHeight(scale)   the tallest the panel may be, in its own (scaled) pixels, to stay on screen when it opens at
--                      PANEL_TOP below the top bar

local GuiService = game:GetService("GuiService")

local PanelFit = {}

local MIN_SCALE = 0.7
local PANEL_TOP = 80.3 -- where ButtonHandler and PetsPanel open the panels
local MARGIN = 8 -- air below the panel
local TOPBAR = 58 -- the tallest Roblox top bar (desktop); phones have a slightly lower one

-- the camera's viewport is a placeholder (1 x 1 or a half-sized window) for the first frames of a session: wait until
-- it has held one real value for a moment, then keep that (the panels are laid out once)
local settledHeight = nil
local function viewportHeight(): number
	if settledHeight then
		return settledHeight
	end
	local camera = workspace.CurrentCamera
	local deadline = os.clock() + 3
	local last, since = 0, os.clock()
	while os.clock() < deadline do
		local y = camera.ViewportSize.Y
		if y ~= last then
			last, since = y, os.clock()
		end
		if y > 100 and os.clock() - since >= 0.4 then
			break
		end
		task.wait()
	end
	settledHeight = if last > 100 then last else 600
	return settledHeight
end

PanelFit.ViewportHeight = viewportHeight -- yields until the viewport has settled (once per session)

function PanelFit.Scale(): number
	return math.clamp(viewportHeight() / 600, MIN_SCALE, 1)
end

function PanelFit.MaxHeight(scale: number): number
	local topbar = math.max(GuiService.TopbarInset.Height, TOPBAR) -- the inset may not be known yet when a panel script starts
	return (viewportHeight() - topbar - PANEL_TOP - MARGIN) / scale
end

return PanelFit
