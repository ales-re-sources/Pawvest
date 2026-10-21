-- KitConveyors (docs/STAGES.md §2.1 "F"): anchored parts tagged KitConveyor move whatever stands on them along the part's
-- front (LookVector) at the attribute `Speed` studs/s (negative = backwards). The surface velocity of an anchored part moves
-- characters by friction and replicates on its own; the server only sets it, once per part and when `Speed` changes.

local CollectionService = game:GetService("CollectionService")

local TAG = "KitConveyor"

local function apply(part: Instance)
	if part:IsA("BasePart") then
		part.AssemblyLinearVelocity = part.CFrame.LookVector * (part:GetAttribute("Speed") or 0)
	end
end

local function add(part: Instance)
	apply(part)
	part:GetAttributeChangedSignal("Speed"):Connect(function()
		apply(part)
	end)
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(add)
for _, part in CollectionService:GetTagged(TAG) do
	add(part)
end
