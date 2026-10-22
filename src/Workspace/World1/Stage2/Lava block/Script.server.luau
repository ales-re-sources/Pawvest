local cooldowns = {}

function onTouched(part)
	local h = part.Parent:FindFirstChild("Humanoid")
	if h ~= nil then
		if not cooldowns[h] then
			h.Health = h.Health - 20
			cooldowns[h] = true
			task.spawn(function()
				task.wait(0.5)
				cooldowns[h] = nil
			end)
		end
	end
end

script.Parent.Touched:Connect(onTouched)