-- Checkpoint sound for the local player only: the server's CheckpointTouchHandler fires ReplicatedStorage.CheckpointReached
-- (once per checkpoint per run) and this plays workspace.Handlers.CheckpointTouchHandler.Sound (Studio-only Sound),
-- so other players no longer hear it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local sound: Sound? = nil -- local copy under SoundService (plays non-positionally)

local function play()
	if not sound then
		local handlers = workspace:FindFirstChild("Handlers")
		local handler = handlers and handlers:FindFirstChild("CheckpointTouchHandler")
		local template = handler and handler:FindFirstChild("Sound")
		if not (template and template:IsA("Sound")) then
			return
		end
		sound = template:Clone()
		sound.Parent = SoundService
	end
	sound.TimePosition = 0
	sound:Play()
end

ReplicatedStorage:WaitForChild("CheckpointReached").OnClientEvent:Connect(play)
