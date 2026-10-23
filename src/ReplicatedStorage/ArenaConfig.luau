-- ArenaConfig: shared names of the key arena (Workspace.KeyArena, the side-view platformer special stage of docs/STAGES.md §5.2).
-- Pure data + helpers, no side effects. The arena is a locked 2D-style room: collect the keys, open the gates with them, leave
-- through the exit. Key ids and tags are used by ArenaServer (validation) and ArenaClient (what the local player sees).

local ArenaConfig = {}

ArenaConfig.Folder = "KeyArena" -- Workspace folder
ArenaConfig.CameraZone = "ArenaCamera" -- the CameraZone part (StageCamera publishes its name as the player attribute CameraZone)
ArenaConfig.Keys = { "Teal", "Green" } -- every key the exit needs, in HUD order
ArenaConfig.KeyColors = {
	Teal = Color3.fromRGB(0, 220, 220),
	Green = Color3.fromRGB(70, 255, 100),
}

ArenaConfig.Tags = {
	Key = "ArenaKey", -- pickup trigger (attribute KeyId), the key model's spinning `Visual` model is its sibling
	Lock = "ArenaLock", -- zone that opens the gate of KeyId for a player who holds that key
	Gate = "ArenaGate", -- barrier (attribute KeyId): solid until the local player has opened it
	Exit = "ArenaExit", -- finish zone, needs every key
	Spike = "ArenaSpike", -- kill box (touching it kills)
	Checkpoint = "ArenaCheckpoint", -- plate `C` of a numbered checkpoint model (respawn point)
}
ArenaConfig.KeyAttribute = "KeyId"
ArenaConfig.OpensGateAttribute = "OpensGate" -- on a key pickup: picking it up opens the gate of the same KeyId at once (no lock zone needed)

-- player attributes (server-owned): comma-separated sorted key ids, "" when none
ArenaConfig.KeysAttribute = "ArenaKeys" -- keys the player holds
ArenaConfig.OpenedAttribute = "ArenaOpened" -- gates the player has opened
ArenaConfig.ClearsAttribute = "ArenaClears" -- number of times the player left through the exit this session

function ArenaConfig.Encode(set: { [string]: boolean }): string
	local ids = {}
	for id, on in set do
		if on then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	return table.concat(ids, ",")
end

function ArenaConfig.Decode(text: any): { [string]: boolean }
	local set = {}
	if type(text) == "string" then
		for id in string.gmatch(text, "[^,]+") do
			set[id] = true
		end
	end
	return set
end

-- True when `set` holds every key the exit needs.
function ArenaConfig.HasAllKeys(set: { [string]: boolean }): boolean
	for _, id in ArenaConfig.Keys do
		if not set[id] then
			return false
		end
	end
	return true
end

return ArenaConfig
