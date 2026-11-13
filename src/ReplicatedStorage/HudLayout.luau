-- Shared layout for the navigation and its panels. Coordinates are relative to ScreenGui's safe area.
-- Get(gui) -> compact, overlay, left, top, width, height, scale; Watch(gui, update) also runs update immediately.
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local HudLayout = {}

function HudLayout.Get(gui: ScreenGui?)
	local camera = workspace.CurrentCamera
	local viewport = if camera then camera.ViewportSize else Vector2.new(800, 600)
	local inset, bottom = GuiService:GetGuiInset()
	local size = if gui and gui.AbsoluteSize.X > 100 and gui.AbsoluteSize.Y > 100
		then gui.AbsoluteSize else viewport - inset - bottom
	local compact = UserInputService.TouchEnabled and math.min(size.X, size.Y) <= 600
	local overlay = compact and (size.X < 600 or size.Y > size.X)
	local left = if compact and not overlay then 130 else 10
	local top = if compact then 20 else 80.3
	return {
		compact = compact,
		overlay = overlay,
		left = left,
		top = top,
		width = math.max(1, size.X - left - 10),
		height = math.max(1, size.Y - top - 10),
		scale = math.clamp(viewport.Y / 600, 0.7, 1),
	}
end

function HudLayout.Watch(gui: ScreenGui, update)
	local queued = false
	local alive = true
	local function changed()
		if queued or not alive then return end
		queued = true
		task.defer(function()
			queued = false
			if alive then update(HudLayout.Get(gui)) end
		end)
	end
	local connections = {
		gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(changed),
		UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(changed),
		GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(changed),
	}
	-- The safe area can stay the same while the camera is replaced (respawn / device emulation).
	local cameraConnection
	local function watchCamera()
		if cameraConnection then cameraConnection:Disconnect() end
		local camera = workspace.CurrentCamera
		cameraConnection = camera and camera:GetPropertyChangedSignal("ViewportSize"):Connect(changed)
		changed()
	end
	table.insert(connections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera))
	watchCamera()
	gui.Destroying:Connect(function()
		alive = false
		for _, connection in connections do connection:Disconnect() end
		if cameraConnection then cameraConnection:Disconnect() end
	end)
	update(HudLayout.Get(gui))
end

return HudLayout
