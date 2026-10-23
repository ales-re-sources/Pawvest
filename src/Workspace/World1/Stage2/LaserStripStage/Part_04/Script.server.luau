h = nil
script.Parent.Touched:connect(function(hit)
	if hit ~= h and game.Players:FindFirstChild(hit.Parent.Name) then
		h = hit
		hit.Parent.Humanoid.Health = 0
		require(game:GetService("ServerScriptService").Telemetry).MarkKill(hit.Parent, script.Parent) -- cause of death (T1a)
	end
	
	
end)