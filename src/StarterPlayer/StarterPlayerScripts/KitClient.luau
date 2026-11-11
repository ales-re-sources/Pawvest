-- KitClient: what the obstacle-kit client scripts share (ObstacleKit, KitZones, KitMaze, KitGhosts, KitWires, KitTide,
-- KitConveyorsClient). Client only; KitMath stays the pure timing maths.
--   Track(tag, add, remove?)      add(part) for every part with the CollectionService tag, now and later; remove(part) when
--                                 one loses it (or streams out)
--   Attr(part, name, default)     a part's attribute, cached per part (the frame loops read several per part every frame;
--                                 AttributeChanged drops a changed value, so tuning a part in Studio still takes effect)
--   HideZone(part) -> boolean     an invisible trigger volume: transparent, no collision / touch / query (false: not a part)
--   Kill(part, humanoid)          a client kit kill: Health 0, KitKillAt / KitKilledBy on the player, telemetry "kill"
--   RunStart() -> number?         server time the player's current run started (StageTimerUpdate), nil outside a run
--   OnRun(fn(newStart, oldStart)) called on every StageTimerUpdate with the run start before and after it
--   Focus() -> Vector3?           where the kit updates around: the character's root, else the camera

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local KitClient = {}

function KitClient.Track(tag: string, add: (Instance) -> (), remove: ((Instance) -> ())?)
	for _, part in CollectionService:GetTagged(tag) do
		add(part)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(add)
	if remove then
		CollectionService:GetInstanceRemovedSignal(tag):Connect(remove)
	end
end

-- Only kit parts are read, so the AttributeChanged connections stay one per kit part; weak keys let a part that left go.
local NONE = {} -- cached "attribute not set"
local attrCache = setmetatable({}, { __mode = "k" }) -- [Instance] = { [name] = value or NONE }

function KitClient.Attr(part: Instance, name: string, default: any): any
	local cache = attrCache[part]
	if not cache then
		local fresh = {}
		cache = fresh
		attrCache[part] = fresh
		part.AttributeChanged:Connect(function(changed: string)
			fresh[changed] = nil
		end)
	end
	local value = cache[name]
	if value == nil then
		value = part:GetAttribute(name)
		if value == nil then
			value = NONE
		end
		cache[name] = value
	end
	if value == NONE then
		return default
	end
	return value
end

function KitClient.HideZone(part: Instance): boolean
	if not part:IsA("BasePart") then
		return false
	end
	part.Transparency = 1
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	return true
end

function KitClient.Kill(part: Instance, humanoid: Humanoid)
	humanoid.Health = 0
	player:SetAttribute("KitKillAt", workspace:GetServerTimeNow())
	player:SetAttribute("KitKilledBy", (part.Parent :: Instance).Name .. "." .. part.Name)
	-- telemetry (T1a): the server cannot see a client kill's cause
	local remotes = ReplicatedStorage:FindFirstChild("TelemetryRemotes")
	local report = remotes and remotes:FindFirstChild("Report")
	if report then
		(report :: RemoteEvent):FireServer("kill", part)
	end
end

local runStart: number? = nil
local runListeners: { (number?, number?) -> () } = {}

function KitClient.RunStart(): number?
	return runStart
end

function KitClient.OnRun(fn: (number?, number?) -> ())
	table.insert(runListeners, fn)
end

-- the player's run: StageTimerUpdate (elapsed >= 0, stageKey) while it runs, (-1, ...) when it ends
ReplicatedStorage:WaitForChild("StageTimerUpdate").OnClientEvent:Connect(function(elapsed: number)
	local old = runStart
	runStart = if type(elapsed) == "number" and elapsed >= 0 then workspace:GetServerTimeNow() - elapsed else nil
	for _, fn in runListeners do
		fn(runStart, old)
	end
end)

function KitClient.Focus(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end
	local camera = workspace.CurrentCamera
	return if camera then camera.CFrame.Position else nil
end

return KitClient
