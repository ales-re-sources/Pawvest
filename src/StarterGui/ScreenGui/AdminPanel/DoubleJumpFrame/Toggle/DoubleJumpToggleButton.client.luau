local toggle = script.Parent
local frame = toggle.Parent
local button = toggle -- Keep reference for compatibility
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local doubleJumpEnabled = false
local jumpCount = 0
local maxJumpCount = 5
local jumpTick = tick()

local function updateToggleVisual()
    if doubleJumpEnabled then
        toggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        toggle.Knob.Position = UDim2.new(0, 27, 0.5, -10.5)
    else
        toggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        toggle.Knob.Position = UDim2.new(0, 2, 0.5, -10.5)
    end
end

local function onToggleClick()
    doubleJumpEnabled = not doubleJumpEnabled
    updateToggleVisual()
end

toggle.MouseButton1Click:Connect(onToggleClick)

-- Initialize toggle visual
updateToggleVisual()

local function onCharacterAdded(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    jumpCount = 0

    humanoid.StateChanged:Connect(function(_, state)
        if state == Enum.HumanoidStateType.Landed then
            jumpCount = 0
        end
    end)

    UserInputService.JumpRequest:Connect(function()
		if not doubleJumpEnabled then return end
		if jumpCount < maxJumpCount and tick() - jumpTick > 0.2 then
			jumpTick = tick()
			jumpCount = jumpCount + 1
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
    end)
end

local player = Players.LocalPlayer
if player.Character then
    onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)
