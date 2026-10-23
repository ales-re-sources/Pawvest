-- LocalizedText (L1, docs/LOCALIZATION.md): renders every label tagged Loc (Locale.SetKey, mostly written by the server,
-- e.g. the ScorePanel) in this player's language: LocKey + LocArgs (JSON) -> Locale.T. Re-applied when the language, the
-- attributes or the label's Text change (the server's English fallback may replicate after the attributes).

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Locale = require(ReplicatedStorage:WaitForChild("Locale"))

local watched = {} -- [label] = { connections }

local function apply(label: any)
	local key = label:GetAttribute(Locale.KeyAttribute)
	if type(key) ~= "string" then
		return
	end
	local args = nil
	local raw = label:GetAttribute(Locale.ArgsAttribute)
	if type(raw) == "string" and raw ~= "" then
		local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
		if ok then
			args = decoded
		end
	end
	local text = Locale.T(key, args)
	if label.Text ~= text then
		label.Text = text
	end
end

local function watch(label: Instance)
	if watched[label] or not (label:IsA("TextLabel") or label:IsA("TextButton") or label:IsA("TextBox")) then
		return
	end
	watched[label] = {
		label.AttributeChanged:Connect(function(name)
			if name == Locale.KeyAttribute or name == Locale.ArgsAttribute then
				apply(label)
			end
		end),
		label:GetPropertyChangedSignal("Text"):Connect(function()
			apply(label)
		end),
	}
	apply(label)
end

local function unwatch(label: Instance)
	for _, connection in watched[label] or {} do
		connection:Disconnect()
	end
	watched[label] = nil
end

CollectionService:GetInstanceAddedSignal(Locale.Tag):Connect(watch)
CollectionService:GetInstanceRemovedSignal(Locale.Tag):Connect(unwatch)
for _, label in CollectionService:GetTagged(Locale.Tag) do
	watch(label)
end

Locale.Changed:Connect(function()
	for label in watched do
		apply(label)
	end
end)
