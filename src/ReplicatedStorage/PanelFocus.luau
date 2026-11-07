--!strict
-- PanelFocus (U4, docs/UI_GARDEN_PETS.md §10): one panel open at a time, and panels close when the player walks away. Client only.
--
--   PanelFocus.Open(name, close, maxDistance?)  a panel opened: the one open before closes (its `close` is called), and this one
--                                               closes (its `close`) once the character is more than `maxDistance` studs
--                                               (default WALK_AWAY) from where it was opened; math.huge = never (the stalls close
--                                               themselves at their stand distance, the server checks it too)
--   PanelFocus.Closed(name)                     the panel closed itself (its close button, its own toggle): forget it
--   PanelFocus.Current() -> string?             the open panel's name
--
-- Names: "Pets", "Skills", "Settings", "Admin", "Barn", "SeedStall", "Food", "Hatchery". The square card and the hand bar are not panels.
-- A respawn re-anchors the point to the new character (ButtonHandler restores an open panel through a death).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PanelFocus = {}

PanelFocus.WALK_AWAY = 32

local player = Players.LocalPlayer
local current: string? = nil
local closeCurrent: (() -> ())? = nil
local limit = PanelFocus.WALK_AWAY
local point: Vector3? = nil
local anchoredTo: Model? = nil -- the character the point belongs to
local connection: RBXScriptConnection? = nil

local function root(): BasePart?
	local character = player and player.Character
	local part = character and character:FindFirstChild("HumanoidRootPart")
	return if part and part:IsA("BasePart") then part else nil
end

local function forget()
	current, closeCurrent, point, anchoredTo = nil, nil, nil, nil
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

local function watch()
	if connection then
		return
	end
	local elapsed = 0
	connection = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.25 then
			return
		end
		elapsed = 0
		if not current or limit == math.huge then
			return
		end
		local part = root()
		if not part then
			return
		end
		if not point or anchoredTo ~= player.Character then
			point, anchoredTo = part.Position, player.Character
			return
		end
		if (part.Position - point).Magnitude > limit then
			local close = closeCurrent
			forget()
			if close then
				close()
			end
		end
	end)
end

function PanelFocus.Open(name: string, close: () -> (), maxDistance: number?)
	if current and current ~= name then
		local previous = closeCurrent
		forget()
		if previous then
			previous() -- may call Closed(previous name): ignored, it is no longer current
		end
	end
	current, closeCurrent, limit = name, close, maxDistance or PanelFocus.WALK_AWAY
	local part = root()
	point, anchoredTo = if part then part.Position else nil, player.Character
	watch()
end

function PanelFocus.Closed(name: string)
	if current == name then
		forget()
	end
end

function PanelFocus.Current(): string?
	return current
end

return PanelFocus
