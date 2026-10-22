-- Writes the stage name on the start gate sign (Gate.Sign), so the Gate template is a plain copy for every stage (like the
-- Top-10 board title, which its own script sets from the same StageConfig entry).
local StageConfig = require(game:GetService("ReplicatedStorage").StageConfig)

local stage = StageConfig.ForInstance(script)
script.Parent.Sign.Gui.Title.Text = stage.displayName
