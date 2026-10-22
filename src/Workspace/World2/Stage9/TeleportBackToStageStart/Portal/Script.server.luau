local Players = game:GetService("Players")
local StageConfig = require(game:GetService("ReplicatedStorage").StageConfig)
local TimerHandler = require(workspace.Handlers.PlayerTimerHandler)

local stage = StageConfig.ForInstance(script)

-- StopTimer is a no-op without a running timer, so repeated touches need no debounce
script.Parent.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end

	local _, runningStage = TimerHandler.GetTimer(player)
	if runningStage == stage.key then
		TimerHandler.StopTimer(player)
	end
end)
