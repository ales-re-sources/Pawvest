function onTouch(part)
local humanoid = part.Parent:findFirstChild("Humanoid")
if (humanoid ~=nil) then
humanoid.Health = 0
end
end

script.Parent.Touched:connect(onTouch)
