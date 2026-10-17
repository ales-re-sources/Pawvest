local TimerHandler = require(workspace.Handlers.PlayerTimerHandler)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageTimerStopped = ReplicatedStorage:WaitForChild("StageTimerStopped")

local portal = script.Parent
local touchedConnection = nil

local function onTouched(hit)
    local player = game.Players:GetPlayerFromCharacter(hit.Parent)
    if player then
        -- Only allow teleport once per timer cycle
        if touchedConnection then
            touchedConnection:Disconnect()
            touchedConnection = nil
        end
        local elapsed = TimerHandler.StopTimer(player)
    end
end

local function connectTouched()
    if not touchedConnection then
        touchedConnection = portal.Touched:Connect(onTouched)
    end
end

-- Initial connection
connectTouched()

-- timer stop or timer reset (user left through portal) - make it possible to touch it again
StageTimerStopped.OnServerEvent:Connect(function(player)
    connectTouched()
end)

