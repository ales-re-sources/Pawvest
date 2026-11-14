-- The thumbnails' player rig (docs/THUMBNAILS.md §7, TH0): one avatar for every set, built from free Roblox catalog items
-- and posed by forward kinematics. A library, not a command: store this file in the StringValue
-- ServerStorage.PhotoSet.Builder_Rig and load it from a set builder with `loadstring(...Builder_Rig.Value)()`.
--   Rig.build(look?)          an anchored R15 Model (Players:CreateHumanoidModelFromDescription), accessories seated on
--                             their attachments, the dynamic head's FaceControls set to look.expression; not parented
--   Rig.pose(rig, pose, at, ground?)  places HumanoidRootPart at CFrame `at` and every other part down the joint chain, each joint
--                             turned by pose[jointName] = Vector3 degrees (X, Y, Z in the joint's frame; the rig faces -Z:
--                             +X lifts a limb forward, +Z swings it to the rig's right, -Z to its left), then reseats the
--                             accessories and, given `ground` (a world Y), moves the rig so its lowest foot stands on it
-- Edit-mode facts (2026-11-14): the default head is a dynamic head (classic face decals are ignored; expressions come from
-- FaceControls), the joints are AnimationConstraints, and some accessories are not welded (a Lavender Updo handle sat
-- 29 studs away), so the parts are anchored and placed by hand.
local Players = game:GetService("Players")

local Rig = {}

local C = Color3.fromRGB
-- the user's pick (2026-11-14): look C of three, "the woman's avatar"
Rig.LOOK = {
	hair = "451220849", -- Lavender Updo (Roblox, free)
	skin = C(204, 142, 105),
	torso = C(255, 120, 40),
	legs = C(40, 50, 120),
	-- an open-mouthed grin (FaceControls properties, 0..1)
	expression = {
		LeftLipCornerPuller = 1, RightLipCornerPuller = 1, JawDrop = 0.45, LeftCheekRaiser = 0.6, RightCheekRaiser = 0.6,
		LeftInnerBrowRaiser = 0.5, RightInnerBrowRaiser = 0.5, LeftOuterBrowRaiser = 0.5, RightOuterBrowRaiser = 0.5,
		LeftUpperLipRaiser = 0.3, RightUpperLipRaiser = 0.3,
	},
}

-- named poses (degrees per joint); joints left out stay straight
Rig.POSES = {
	stand = {},
	-- A3: landing on the checkpoint and cheering, arms in a V, one knee up from the landing step
	cheer = {
		Waist = Vector3.new(-6, 8, 0),
		Neck = Vector3.new(8, -6, 4),
		RightShoulder = Vector3.new(15, 0, 145),
		RightElbow = Vector3.new(20, 0, 0),
		LeftShoulder = Vector3.new(15, 0, -145),
		LeftElbow = Vector3.new(20, 0, 0),
		RightHip = Vector3.new(55, 0, 6),
		RightKnee = Vector3.new(-75, 0, 0),
		RightAnkle = Vector3.new(20, 0, 0),
		LeftHip = Vector3.new(12, 0, -6),
		LeftKnee = Vector3.new(-22, 0, 0),
		LeftAnkle = Vector3.new(10, 0, 0),
	},
}

local function seat(rig: Model)
	local attachments = {}
	for _, a in rig:GetDescendants() do
		if a:IsA("Attachment") and not a:FindFirstAncestorOfClass("Accessory") then
			attachments[a.Name] = a
		end
	end
	for _, accessory in rig:GetChildren() do
		local handle = accessory:IsA("Accessory") and accessory:FindFirstChild("Handle")
		if handle then
			for _, own in handle:GetChildren() do
				local body = own:IsA("Attachment") and attachments[own.Name]
				if body then
					handle.CFrame = body.WorldCFrame * own.CFrame:Inverse()
					break
				end
			end
		end
	end
end

function Rig.build(look): Model
	look = look or Rig.LOOK
	local d = Instance.new("HumanoidDescription")
	d.HairAccessory = look.hair
	if look.shirt then
		d.Shirt = look.shirt
	end
	if look.pants then
		d.Pants = look.pants
	end
	d.HeadColor = look.skin
	d.LeftArmColor, d.RightArmColor = look.arms or look.skin, look.arms or look.skin
	d.TorsoColor = look.torso or look.skin
	d.LeftLegColor, d.RightLegColor = look.legs or look.skin, look.legs or look.skin
	local rig = Players:CreateHumanoidModelFromDescription(d, Enum.HumanoidRigType.R15)
	rig.Name = "Player"
	for _, p in rig:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
		end
	end
	local face = rig.Head:FindFirstChildOfClass("FaceControls")
	if face then
		for name, value in look.expression or {} do
			(face :: any)[name] = value
		end
	end
	seat(rig)
	return rig
end

function Rig.pose(rig: Model, pose: { [string]: Vector3 }, at: CFrame, ground: number?)
	-- joints by the part they move: Part1 = Attachment1's parent
	local joints = {}
	for _, j in rig:GetDescendants() do
		if (j:IsA("AnimationConstraint") or j:IsA("Motor6D")) and j.Attachment0 and j.Attachment1 then
			local list = joints[j.Attachment0.Parent] or {}
			joints[j.Attachment0.Parent] = list
			table.insert(list, j)
		end
	end
	local root = rig:FindFirstChild("HumanoidRootPart") :: BasePart
	root.CFrame = at
	local function walk(part: BasePart)
		for _, j in joints[part] or {} do
			local a0, a1 = j.Attachment0 :: Attachment, j.Attachment1 :: Attachment
			local deg = pose[j.Name] or Vector3.zero
			local turn = CFrame.Angles(math.rad(deg.X), math.rad(deg.Y), math.rad(deg.Z))
			local child = a1.Parent :: BasePart
			child.CFrame = part.CFrame * a0.CFrame * turn * a1.CFrame:Inverse()
			walk(child)
		end
	end
	walk(root)
	seat(rig)
	if ground then
		local lowest = math.huge
		for _, name in { "LeftFoot", "RightFoot" } do
			local foot = rig:FindFirstChild(name) :: BasePart
			for _, x in { -0.5, 0.5 } do
				for _, y in { -0.5, 0.5 } do
					for _, z in { -0.5, 0.5 } do
						lowest = math.min(lowest, (foot.CFrame * (foot.Size * Vector3.new(x, y, z))).Y)
					end
				end
			end
		end
		local drop = Vector3.new(0, ground - lowest, 0)
		for _, p in rig:GetDescendants() do
			if p:IsA("BasePart") then
				p.CFrame += drop
			end
		end
	end
end

return Rig
