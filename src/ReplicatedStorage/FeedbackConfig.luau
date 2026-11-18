-- FeedbackConfig (FB, docs/GDD.md → Player feedback): what the stage rating and the feedback box share between the server
-- (FeedbackService) and the clients (StageResultsPopup, FeedbackClient).

local FeedbackConfig = {}

FeedbackConfig.Folder = "FeedbackRemotes" -- ReplicatedStorage folder: Rate, Send, Result
FeedbackConfig.Categories = { "bug", "idea", "other" } -- stored ids, never renamed (shown in this order)
FeedbackConfig.CategoryIcons = { bug = "🐞", idea = "💡", other = "💬" }
FeedbackConfig.MaxLength = 300 -- characters (utf8) of one message
FeedbackConfig.PerDay = 3 -- messages per player and UTC day

-- The DataStores; in Studio their keys get StudioPrefix so tests never touch the live data.
FeedbackConfig.RatingStore = "StageRatings" -- key "counts" = { [stageKey] = { up = n, down = n } }
FeedbackConfig.FeedbackStore = "PlayerFeedback" -- key "<os.time()>_<UserId>" = { u, t, cat, area, text, lang, ver }
FeedbackConfig.CountsKey = "counts"
FeedbackConfig.StudioPrefix = "studio_"

function FeedbackConfig.IsCategory(value: any): boolean
	return type(value) == "string" and table.find(FeedbackConfig.Categories, value) ~= nil
end

-- `text` without leading / trailing whitespace, or nil when it is not a string of valid UTF-8.
function FeedbackConfig.Trim(text: any): string?
	if type(text) ~= "string" or utf8.len(text) == nil then
		return nil
	end
	return (string.match(text, "^%s*(.-)%s*$"))
end

-- `text` cut to at most `limit` characters (valid UTF-8 in, valid UTF-8 out).
function FeedbackConfig.Cut(text: string, limit: number): string
	local length = utf8.len(text)
	if not length or length <= limit then
		return text
	end
	return string.sub(text, 1, (utf8.offset(text, limit + 1) :: number) - 1)
end

return FeedbackConfig
