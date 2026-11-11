-- ArenaConfig: shared names of the Laser Lab's Key Vault (room 1 of Workspace.World3.Stage14, the side-view special stage of
-- docs/STAGES.md §5.2 / §7.12; was the KeyArena prototype). Pure data + helpers, no side effects. The vault is a locked 2D-style
-- room: collect the keys, open the gates with them, leave through the green gate. Key ids and tags are used by ArenaServer
-- (validation) and ArenaClient (what the local player sees).

local IdSet = require(script.Parent:WaitForChild("IdSet"))

local ArenaConfig = {}

ArenaConfig.CameraZone = "VaultCamera" -- the vault's CameraZone part (StageCamera publishes its name as the player attribute CameraZone)
ArenaConfig.Keys = { "Teal", "Green" } -- every key the exit needs, in HUD order
ArenaConfig.KeyColors = {
	Teal = Color3.fromRGB(100, 255, 190), -- mint since the Stud restyle; the id stays "Teal" (KeyId attributes, string keys)
	Green = Color3.fromRGB(70, 255, 100),
}

ArenaConfig.Tags = {
	Key = "ArenaKey", -- pickup trigger (attribute KeyId), the key model's spinning `Visual` model is its sibling
	Lock = "ArenaLock", -- zone that opens the gate of KeyId for a player who holds that key
	Gate = "ArenaGate", -- barrier (attribute KeyId): solid until the local player has opened it
}
ArenaConfig.KeyAttribute = "KeyId"
ArenaConfig.OpensGateAttribute = "OpensGate" -- on a key pickup: picking it up opens the gate of the same KeyId at once (no lock zone needed)
-- on a gate: the other way round, absent until its KeyId gate opens, then a barrier (unused since Gate_TealBehind was removed, 2026-10-29)
ArenaConfig.ClosesAttribute = "ClosesWhenOpen"
-- on a gate: a kill strip (keeps the KitKill tag and CanCollide off) that is deadly while the gate is shut and harmless once open
ArenaConfig.KillAttribute = "KillWhileShut"
-- on a gate: opens as soon as the player holds its KeyId key, before any lock (the hatch under the green key: the way back down)
ArenaConfig.HeldAttribute = "OpensWhenHeld"

-- player attributes (server-owned): comma-separated sorted key ids, "" when none
ArenaConfig.KeysAttribute = "ArenaKeys" -- keys the player holds
ArenaConfig.OpenedAttribute = "ArenaOpened" -- gates the player has opened

ArenaConfig.Encode = IdSet.Encode
ArenaConfig.Decode = IdSet.Decode

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
