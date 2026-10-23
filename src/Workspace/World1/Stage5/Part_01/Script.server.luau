function onTouch(part)
local humanoid = part.Parent:findFirstChild("Humanoid")
if (humanoid ~=nil) then
humanoid.Health = 0
require(game:GetService("ServerScriptService").Telemetry).MarkKill(humanoid.Parent, script.Parent) -- cause of death (T1a)
end
end

script.Parent.Touched:connect(onTouch)
