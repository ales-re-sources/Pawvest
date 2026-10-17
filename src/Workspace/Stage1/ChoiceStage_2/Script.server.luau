done = false

while not done do
	wait()
	if not done then
		p = script.Parent:GetChildren()[math.random(1,#script.Parent:GetChildren())]
		if p.Name == "Step" then
			p.CanCollide = true
			done = true
		end
	end
	
end