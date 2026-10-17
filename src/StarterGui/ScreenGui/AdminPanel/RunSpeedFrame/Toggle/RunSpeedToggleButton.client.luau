local toggle = script.Parent
local frame = toggle.Parent
local button = toggle -- Keep reference for compatibility
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local DEFAULT_SPEED = 16
local FAST_SPEED = 64

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
        setRunSpeed(DEFAULT_SPEED)
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
            humanoid.WalkSpeed = DEFAULT_SPEED
        end
    end
end)

