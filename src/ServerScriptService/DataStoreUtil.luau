-- DataStoreUtil: DataStore calls that survive a hiccup. Server-only.
--   DataStoreUtil.WithRetries(fn, attempts?)  pcall(fn) up to `attempts` times (default 3), waiting 1 s, 2 s … between them;
--                                             returns (true, result) or (false, last error)

local DataStoreUtil = {}

function DataStoreUtil.WithRetries(fn: () -> any, attempts: number?): (boolean, any)
	local tries = attempts or 3
	local ok, result
	for attempt = 1, tries do
		ok, result = pcall(fn)
		if ok then
			return true, result
		end
		if attempt < tries then
			task.wait(attempt)
		end
	end
	return false, result
end

return DataStoreUtil
