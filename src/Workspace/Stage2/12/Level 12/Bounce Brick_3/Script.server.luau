-- Bounce brick: marks this part as a bounce brick with a fixed launch speed. The launch itself is done by the
-- BounceBricks client script on the player's own character (the client owns its character's physics), so every
-- bounce reaches the same height. Tuned so the flight lasts long enough to steer onto the ramp up to checkpoint 13.
local CollectionService = game:GetService("CollectionService")

local LAUNCH_SPEED = 500 -- studs/s along the brick's LookVector (up)

script.Parent:SetAttribute("LaunchSpeed", LAUNCH_SPEED)
CollectionService:AddTag(script.Parent, "BounceBrick")
