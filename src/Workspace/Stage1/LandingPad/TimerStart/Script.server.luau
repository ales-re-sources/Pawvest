local Players = game:GetService("Players")
local StageConfig = require(game:GetService("ReplicatedStorage").StageConfig)
local TimerHandler = require(workspace.Handlers.PlayerTimerHandler)
local TouchHandler = require(workspace.Handlers.CheckpointTouchHandler)

local stage = StageConfig.ForInstance(script)

script.Parent.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end

	-- per-player debounce: a run already going on this stage is not restarted
	-- (this pad is also a checkpoint, so respawning here keeps the run going)
	local _, runningStage = TimerHandler.GetTimer(player)
	if runningStage ~= stage.key then
		TimerHandler.StartTimer(player, stage.key)
	end
	TouchHandler.OnTouched(script.Parent, hit)
end)
