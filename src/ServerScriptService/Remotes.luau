-- Remotes: how a server service creates and answers its remotes (docs/PROTOCOL.md lists them). Server-only.
--   Remotes.Folder(name, events)   a Folder `name` in ReplicatedStorage holding a RemoteEvent per name in `events`, parented once
--                                  they all exist; returns (folder, { [eventName] = RemoteEvent }). Remotes a sibling module
--                                  adds later go through Remotes.Add(folder, name).
--   Remotes.Add(parent, name)      a RemoteEvent `name` under `parent` (a lone remote: parent = ReplicatedStorage)
--   Remotes.Results(event)         the two answers on a service's Result remote, both (player, key, …) on the wire:
--                                  reject(player, key, reason) → (key, false, reason); succeed(player, key, detail?) → (key, true, detail)
--   Remotes.Admin(event, cooldown, fn)  connects an admin-only remote: AdminConfig.IsAdmin (else a warning), then a per-player
--                                  cooldown (RateLimit), then fn(player, ...)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminConfig = require(ReplicatedStorage.AdminConfig)
local RateLimit = require(script.Parent.RateLimit)

local Remotes = {}

function Remotes.Add(parent: Instance, name: string): RemoteEvent
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = parent
	return event
end

function Remotes.Folder(name: string, events: { string }): (Folder, { [string]: RemoteEvent })
	local folder = Instance.new("Folder")
	folder.Name = name
	local created = {}
	for _, eventName in events do
		created[eventName] = Remotes.Add(folder, eventName)
	end
	folder.Parent = ReplicatedStorage
	return folder, created
end

function Remotes.Results(event: RemoteEvent)
	local function reject(player: Player, key: string, reason: string)
		event:FireClient(player, key, false, reason)
	end
	local function succeed(player: Player, key: string, detail: any)
		event:FireClient(player, key, true, detail)
	end
	return reject, succeed
end

function Remotes.Admin(event: RemoteEvent, cooldown: number, fn: (Player, ...any) -> ())
	local allow = RateLimit.new(cooldown)
	event.OnServerEvent:Connect(function(player, ...)
		if not AdminConfig.IsAdmin(player.UserId) then
			warn(string.format("%s: rejected request from non-admin %s (%d)", event.Name, player.Name, player.UserId))
			return
		end
		if not allow(player) then
			return
		end
		fn(player, ...)
	end)
end

return Remotes
