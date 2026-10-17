local ReplicatedStorage = game:GetService("ReplicatedStorage")
local resetTimerEvent = ReplicatedStorage:WaitForChild("ResetPlayerTimer")
local handler = require(workspace.Handlers.PlayerTimerHandler)

resetTimerEvent.OnServerEvent:Connect(function(player)
	handler.ResetHighScore(player)
	handler.UpdateScorePanel(player, nil)
end)

