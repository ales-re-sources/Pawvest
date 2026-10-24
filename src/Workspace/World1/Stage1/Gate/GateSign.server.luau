-- Writes the stage name on the start gate sign (Gate.Sign), so the Gate template is a plain copy for every stage (like the
-- Top-10 board title, which its own script sets from the same StageConfig entry).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageConfig = require(ReplicatedStorage.StageConfig)
local Locale = require(ReplicatedStorage.Locale)

local stage = StageConfig.ForInstance(script)
Locale.SetKey(script.Parent.Sign.Gui.Title, "stage.name." .. stage.key)
