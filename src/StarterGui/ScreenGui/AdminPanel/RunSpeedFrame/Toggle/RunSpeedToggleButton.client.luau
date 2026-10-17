local toggle = script.Parent
local frame = toggle.Parent
local button = toggle -- Keep reference for compatibility
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local TalentConfig = require(ReplicatedStorage:WaitForChild("TalentConfig"))

local DEFAULT_SPEED = 16
local FAST_SPEED = 64

-- "Off" means the player's normal speed, including the Run Speed talent (server-owned attribute)
local function normalSpeed()
    local level = TalentConfig.ClampLevel("RunSpeed", LocalPlayer:GetAttribute(TalentConfig.AttributeName("RunSpeed")))
    return DEFAULT_SPEED * TalentConfig.WalkSpeedFactor(level)
end

local isFast = false

local function setRunSpeed(speed)
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
        humanoid.WalkSpeed = speed
    end
end

local function updateToggleVisual()
    if isFast then
        toggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        toggle.Knob.Position = UDim2.new(0, 27, 0.5, -10.5)
    else
        toggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        toggle.Knob.Position = UDim2.new(0, 2, 0.5, -10.5)
    end
end

toggle.Activated:Connect(function()
    isFast = not isFast
    if isFast then
        setRunSpeed(FAST_SPEED)
    else
        setRunSpeed(normalSpeed())
    end
    updateToggleVisual()
end)

-- Initialize toggle visual
updateToggleVisual()

-- Ensure speed resets when character respawns
LocalPlayer.CharacterAdded:Connect(function(character)

    if isFast then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
            humanoid.WalkSpeed = FAST_SPEED
        end
    else
        local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
            humanoid.WalkSpeed = normalSpeed()
        end
    end
end)

-- A talent purchase makes the server set WalkSpeed; keep the debug boost while it is on
LocalPlayer:GetAttributeChangedSignal(TalentConfig.AttributeName("RunSpeed")):Connect(function()
    if isFast then
        task.defer(setRunSpeed, FAST_SPEED)
    end
end)

