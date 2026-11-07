--!strict
-- Click sounds for every button (UiSounds). Each GuiButton that appears in PlayerGui, now or later, plays its cue when activated
-- (mouse click, tap, gamepad): "Click" by default, or the cue named by its `UiSound` attribute ("Tab", ...); "None" = silent.
-- Tab-like controls (pets filter chips, the field hand bar) carry UiSound = "Tab", set by their own scripts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiSounds = require(ReplicatedStorage:WaitForChild("UiSounds"))

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local bound: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function bind(instance: Instance)
	if not instance:IsA("GuiButton") or bound[instance] then
		return
	end
	bound[instance] = true
	instance.Activated:Connect(function()
		local cue = instance:GetAttribute("UiSound")
		if cue == "None" then
			return
		end
		UiSounds.Play(if type(cue) == "string" then cue else "Click")
	end)
end

UiSounds.Preload()
playerGui.DescendantAdded:Connect(bind)
for _, instance in playerGui:GetDescendants() do
	bind(instance)
end
