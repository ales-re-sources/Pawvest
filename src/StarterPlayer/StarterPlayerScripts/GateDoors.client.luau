-- GateDoors (S4.0, docs/STAGES.md §7.1): the door in each world stage's start gate (Workspace.<Stage>.Gate.Door). While the stage
-- is locked for the local player the door is solid for them and touching it opens the unlock popup; once the bar is met or the
-- stage is bought it becomes a faint ghost and the doorway is free, so walking through starts the stage and its timer (the
-- server's TimerStart checks the unlock again). All of it is local: the door part itself stays as authored for everyone else.
-- The stars / coins / lock lines on the door face come from HubPortalMedals (StageConfig.FaceTarget).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))

local LocalPlayer = Players.LocalPlayer

local OPEN_TRANSPARENCY = 0.75 -- the open door: faint, the face lines stay readable
local POPUP_COOLDOWN = 1.5 -- seconds between popups from one door

local function addDoor(stage)
	local door = StageConfig.FaceTarget(stage)
	local closedTransparency = door.Transparency
	local attribute = StageConfig.UnlockedAttribute(stage)
	local lastPopup = 0

	local function refresh()
		local locked = LocalPlayer:GetAttribute(attribute) ~= true -- locked until the server says otherwise
		door.CanCollide = locked
		door.CanTouch = locked
		door.Transparency = if locked then closedTransparency else OPEN_TRANSPARENCY
	end
	LocalPlayer:GetAttributeChangedSignal(attribute):Connect(refresh)
	refresh()

	door.Touched:Connect(function(hit)
		local character = LocalPlayer.Character
		if not character or not hit:IsDescendantOf(character) then
			return
		end
		if LocalPlayer:GetAttribute(attribute) ~= true and os.clock() - lastPopup > POPUP_COOLDOWN then
			lastPopup = os.clock()
			LocalPlayer:SetAttribute("OpenUnlockPopup", stage.key) -- StageUnlockPopup shows the requirement and price
		end
	end)
end

for _, stage in StageConfig.Stages do
	if StageConfig.Worlds[stage.world] and stage.unlock then
		task.spawn(addDoor, stage)
	end
end
