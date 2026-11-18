-- FeedbackConfig (FB / FB2, docs/GDD.md §10 → Player feedback): what the stage rating and the feedback box share between the server
-- (FeedbackService) and the clients (RatingSigns, FeedbackClient).

local FeedbackConfig = {}

FeedbackConfig.Folder = "FeedbackRemotes" -- ReplicatedStorage folder: Rate, Send, Result

-- FB2 rating signs: one Studio-only model per world stage, tagged SignTag (template ServerStorage.StageKit.RatingSign)
FeedbackConfig.SignTag = "RatingSign"
FeedbackConfig.PromptDistance = 10 -- studs: the thumb prompts' MaxActivationDistance
FeedbackConfig.RateDistance = 20 -- studs from the sign's pivot within which the server accepts a rating
FeedbackConfig.RatingsAttribute = "StageRatings" -- player attribute: JSON { [stageKey] = 1 | -1 } of the own ratings
FeedbackConfig.Categories = { "bug", "idea", "other" } -- stored ids, never renamed (shown in this order)
FeedbackConfig.CategoryIcons = { bug = "🐞", idea = "💡", other = "💬" }
FeedbackConfig.MaxLength = 300 -- characters (utf8) of one message
FeedbackConfig.PerDay = 3 -- messages per player and UTC day

-- The DataStores; in Studio their keys get StudioPrefix so tests never touch the live data.
FeedbackConfig.RatingStore = "StageRatings" -- key "counts" = { [stageKey] = { up, down, upUnfinished, downUnfinished } }
FeedbackConfig.FeedbackStore = "PlayerFeedback" -- key "<os.time()>_<UserId>" = { u, t, cat, area, text, lang, ver }
FeedbackConfig.CountsKey = "counts"
FeedbackConfig.StudioPrefix = "studio_"

-- Whether `stage` (a StageConfig entry) has a rating sign: the world stages, not the Tutorial.
function FeedbackConfig.Rated(stage): boolean
	return stage ~= nil and (stage.world or 0) > 0
end

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
