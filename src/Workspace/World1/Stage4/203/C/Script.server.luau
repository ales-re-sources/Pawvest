local TouchHandler = require(workspace.Handlers.CheckpointTouchHandler)
script.Parent.Touched:Connect(function(hit)
	TouchHandler.OnTouched(script.Parent, hit)
end)