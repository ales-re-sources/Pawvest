-- AdminConfig: who may use the admin panel. Shared: the client uses it to show the panel,
-- the server to accept admin remotes (the client check alone is only UI gating).

local AdminConfig = {}

-- Lekzdrh and SVAL
AdminConfig.Users = { 9892673032, 769364524 }

function AdminConfig.IsAdmin(userId: number): boolean
	return table.find(AdminConfig.Users, userId) ~= nil
end

return AdminConfig
