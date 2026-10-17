h = nil
script.Parent.Touched:connect(function(hit)
	if hit ~= h and game.Players:FindFirstChild(hit.Parent.Name) then
		h = hit
		hit.Parent.Humanoid.Health = 0
	end
	
	
end)