-- CharacterUtil: who touched something, and is that character alive and near it. Server-only.
--   CharacterUtil.FromHit(hit)            player, humanoid and root part of a live character a touching part belongs to, or nil
--   CharacterUtil.Live(player)            the player's live character and its root part, or nil (dead / missing)
--   CharacterUtil.Reaches(root, part)     the root is within MAX_REACH studs of `part` (rejects pickups moved on a client: a
--                                         body part touching it is within ~5 studs, the rest covers a fast fall's lag)

local Players = game:GetService("Players")

local CharacterUtil = {}

CharacterUtil.MAX_REACH = 15

local function alive(character: Instance?): (Humanoid?, BasePart?)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
		return humanoid, root
	end
	return nil, nil
end

function CharacterUtil.FromHit(hit: BasePart): (Player?, Humanoid?, BasePart?)
	local character = hit.Parent
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player then
		return nil, nil, nil
	end
	local humanoid, root = alive(character)
	if not humanoid then
		return nil, nil, nil
	end
	return player, humanoid, root
end

function CharacterUtil.Live(player: Player): (Model?, BasePart?)
	local character = player.Character
	local _, root = alive(character)
	if not root then
		return nil, nil
	end
	return character, root
end

function CharacterUtil.Reaches(root: BasePart, part: BasePart): boolean
	return (root.Position - part.Position).Magnitude <= CharacterUtil.MAX_REACH
end

return CharacterUtil
