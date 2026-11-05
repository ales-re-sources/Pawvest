-- KitConveyorsClient (docs/STAGES.md §2.5 "Conveyors"): the chevrons on a conveyor belt slide along it at the belt's own `Speed`, so the
-- belt shows where it carries a player before they step on. Purely visual and local; the push itself is the server's surface velocity
-- (KitConveyors.server).
-- A belt is a part tagged KitConveyor; its chevrons are its children `Chevron<n>L` / `Chevron<n>R` (two arms each), authored pointing the
-- way the belt pushed when they were placed. Here every chevron is unwelded and anchored locally, then moved along the belt's local Z
-- (the push runs along -Z * Speed) and wrapped over the belt's length, fading out near the rollers. If `Speed` changes sign the chevrons
-- turn around. The phase comes from workspace:GetServerTimeNow(), so every player sees the same belt. Belts farther than ANIMATE_DISTANCE
-- from the camera are not updated.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local TAG = "KitConveyor"
local ANIMATE_DISTANCE = 300
local HALF_EXTENT = 1.3 -- studs from a chevron's centre to its tip or tail along the belt
local FADE = 1.3 -- studs over which a chevron fades in / out at the belt's ends

type Arm = { part: BasePart, offset: CFrame }
type Chevron = { z: number, arms: { Arm } }
type Belt = { chevrons: { Chevron }, authoredSign: number }

local belts: { [BasePart]: Belt } = {}

local function collect(belt: BasePart)
	local groups: { [string]: Chevron } = {}
	local list: { Chevron } = {}
	for _, child in belt:GetChildren() do
		local id = child:IsA("BasePart") and string.match(child.Name, "^Chevron(%d+)[LR]$")
		if id then
			local part = child :: BasePart
			part.Anchored = true
			local weld = part:FindFirstChildOfClass("WeldConstraint")
			if weld then
				weld.Enabled = false
			end
			local offset = belt.CFrame:ToObjectSpace(part.CFrame)
			local group = groups[id]
			if not group then
				group = { z = 0, arms = {} }
				groups[id] = group
				table.insert(list, group)
			end
			table.insert(group.arms, { part = part, offset = offset })
		end
	end
	for _, group in list do
		local sum = 0
		for _, arm in group.arms do
			sum += arm.offset.Position.Z
		end
		group.z = sum / #group.arms
	end
	local speed = belt:GetAttribute("Speed")
	belts[belt] = { chevrons = list, authoredSign = if type(speed) == "number" and speed < 0 then -1 else 1 }
end

local function add(instance: Instance)
	if instance:IsA("BasePart") and instance:IsDescendantOf(workspace) then
		task.defer(collect, instance)
	end
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(add)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(instance)
	belts[instance :: BasePart] = nil
end)
for _, instance in CollectionService:GetTagged(TAG) do
	add(instance)
end

local FLIP = CFrame.Angles(0, math.pi, 0)

RunService.Heartbeat:Connect(function()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local eye = camera.CFrame.Position
	local now = workspace:GetServerTimeNow()
	for belt, data in belts do
		if belt.Parent and (belt.Position - eye).Magnitude <= ANIMATE_DISTANCE and #data.chevrons > 0 then
			local speed = belt:GetAttribute("Speed")
			speed = if type(speed) == "number" then speed else 0
			local length = belt.Size.Z
			local flipped = speed ~= 0 and math.sign(speed) ~= data.authoredSign
			local shift = -speed * now -- the surface moves along -Z * Speed
			local beltCFrame = belt.CFrame
			for _, chevron in data.chevrons do
				local z0 = if flipped then -chevron.z else chevron.z
				local z = (z0 + shift + length / 2) % length - length / 2
				local edge = length / 2 - math.abs(z) -- distance of the centre to the nearer end
				local transparency = math.clamp((HALF_EXTENT + FADE - edge) / FADE, 0, 1)
				local move = CFrame.new(0, 0, z - z0)
				for _, arm in chevron.arms do
					local offset = if flipped then FLIP * arm.offset else arm.offset
					arm.part.CFrame = beltCFrame * move * offset
					arm.part.Transparency = transparency
				end
			end
		end
	end
end)
