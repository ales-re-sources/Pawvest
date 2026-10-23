-- TelemetryClient (T1a, docs/TELEMETRY.md): tells the server once which input the player uses (touch / gamepad / keyboard),
-- for the Session event. The kit kill and fall reset reports come from ObstacleKit / QuickRespawnClient.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local report = ReplicatedStorage:WaitForChild("TelemetryRemotes"):WaitForChild("Report")

local platform = "keyboard"
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
	platform = "touch"
elseif UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then
	platform = "gamepad"
end
report:FireServer("platform", platform)
