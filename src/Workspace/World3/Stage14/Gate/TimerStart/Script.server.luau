local Players = game:GetService("Players")
local StageConfig = require(game:GetService("ReplicatedStorage").StageConfig)
local StageUnlocks = require(game:GetService("ServerScriptService").StageUnlocks)
local TimerHandler = require(workspace.Handlers.PlayerTimerHandler)
local TouchHandler = require(workspace.Handlers.CheckpointTouchHandler)

local stage = StageConfig.ForInstance(script)

script.Parent.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end
	-- the door gate keeps a locked stage shut on the client; the server does not trust that (also nil while loading)
	if StageUnlocks.IsUnlocked(player, stage) ~= true then return end

	-- per-player debounce: a run already going on this stage is not restarted
	-- (this pad is also a checkpoint, so respawning here keeps the run going)
	local _, runningStage = TimerHandler.GetTimer(player)
	if runningStage ~= stage.key then
		TimerHandler.StartTimer(player, stage.key)
		TimerHandler.UpdateScorePanel(player, stage.key) -- the gate is the entrance: panel and talent warning start here
		TouchHandler.NewRun(player) -- checkpoint sounds play again in the new run
	end
	TouchHandler.OnTouched(script.Parent, hit)
end)
