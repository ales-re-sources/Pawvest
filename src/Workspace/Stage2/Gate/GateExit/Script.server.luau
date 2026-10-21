-- GateExit (S4.0): a thin trigger just outside the stage's door gate, on the plaza side. Walking back out through the gate
-- before the finish cancels the running stage timer and puts the score panel back on the world (the stage lies physically
-- behind the gate; finishing teleports back in front of it as before). The stage comes from the Workspace folder.

local Players = game:GetService("Players")
local StageConfig = require(game:GetService("ReplicatedStorage").StageConfig)
local TimerHandler = require(workspace.Handlers.PlayerTimerHandler)

local stage = StageConfig.ForInstance(script)

script.Parent.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then
		return
	end
	local _, runningStage = TimerHandler.GetTimer(player)
	if runningStage == stage.key then
		TimerHandler.ResetTimer(player)
		TimerHandler.UpdateScorePanel(player, StageConfig.LocationKey(stage))
	end
end)
