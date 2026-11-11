-- SettingsRow: one brick row of the Settings panel (SoundSettings, LanguageSettings). The panel is part of the ScreenGui that
-- is re-created on every respawn, so the row is added each time it appears. Client only.
--   SettingsRow.Mount(name, order, refresh, onActivated, signals?)
--     refresh(button, panel) sets the row's text; it runs at once, on Locale.Changed and on each of `signals` (connections end
--     with the button); onActivated() handles a click.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local StudStyle = require(ReplicatedStorage:WaitForChild("StudStyle"))

local SettingsRow = {}

function SettingsRow.Mount(
	name: string,
	order: number,
	refresh: (TextButton, Instance) -> (),
	onActivated: () -> (),
	signals: { RBXScriptSignal }?
)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local function addRow(screenGui: Instance)
		local panel = screenGui:WaitForChild("SettingsPanel", 10)
		if not panel or panel:FindFirstChild(name) then
			return
		end
		local button = Instance.new("TextButton")
		button.Name = name
		button.LayoutOrder = order
		button.Size = UDim2.new(1, -20, 0, 40)
		button.BackgroundColor3 = StudStyle.PanelColors.SettingsPanel
		button.TextSize = 18
		local function update()
			refresh(button, panel)
		end
		button.Activated:Connect(function()
			onActivated()
			update()
		end)
		local connections = { Locale.Changed:Connect(update) }
		for _, signal in signals or {} do
			table.insert(connections, signal:Connect(update))
		end
		button.Destroying:Connect(function()
			for _, connection in connections do
				connection:Disconnect()
			end
		end)
		update()
		StudStyle.Brick(button, { studs = 5 })
		button.Parent = panel
	end

	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "ScreenGui" then
			task.spawn(addRow, child)
		end
	end)
	local existing = playerGui:FindFirstChild("ScreenGui")
	if existing then
		task.spawn(addRow, existing)
	end
end

return SettingsRow
