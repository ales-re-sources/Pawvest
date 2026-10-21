-- MedalText: rich-text snippets for medal stars and medal limits (docs/GDD.md §4).
-- Shared by the server (score panel) and client GUIs (popup, portal stars, stage timer).

local StageConfig = require(script.Parent.StageConfig)
local TimeFormat = require(script.Parent.TimeFormat)
local TalentConfig = require(script.Parent.TalentConfig)

local MedalText = {}

MedalText.Gold = "#FFD54A"

local function font(color, text, transparency)
	if transparency then
		return string.format('<font color="%s" transparency="%s">%s</font>', color, tostring(transparency), text)
	end
	return string.format('<font color="%s">%s</font>', color, text)
end

-- `medal` gold stars followed by the stars not earned in `unearnedColor` (optionally transparent).
function MedalText.Stars(medal: number, unearnedColor: string, unearnedTransparency: number?): string
	local unearned = #StageConfig.Medals - medal
	local text = ""
	if medal > 0 then
		text ..= font(MedalText.Gold, string.rep("★", medal))
	end
	if unearned > 0 then
		text ..= font(unearnedColor, string.rep("★", unearned), unearnedTransparency)
	end
	return text
end

-- "★ 1:52   ★★ 1:17   ★★★ 0:56"; entries for medals already earned (≤ bestMedal) are gold.
function MedalText.Limits(stage, bestMedal: number): string
	local parts = {}
	for medal in StageConfig.Medals do
		local limit = StageConfig.Threshold(stage, medal)
		if limit then
			local entry = string.rep("★", medal) .. " " .. TimeFormat.Short(limit)
			table.insert(parts, if medal <= bestMedal then font(MedalText.Gold, entry) else entry)
		end
	end
	return table.concat(parts, "   ")
end

-- Unlock bar of a stage (GDD §3): "★★ Silver on Stage 1" with gold stars; nil for a stage without an unlock rule.
function MedalText.UnlockBar(stage): string?
	local rule = stage.unlock
	if not rule then
		return nil
	end
	if rule.world then
		return font(MedalText.Gold, "★") .. " " .. rule.stars .. " of " .. StageConfig.MaxWorldStars(rule.world)
			.. " in World " .. rule.world
	end
	local previous = StageConfig.ByKey[rule.stage]
	local stars = string.rep("★", StageConfig.MedalIndex[rule.medal])
	return font(MedalText.Gold, stars) .. " " .. rule.medal .. " on " .. previous.displayName
end

-- Display name of a required talent ("Double Jump", or "Double Jump 2" above level 1 on a multi-level talent).
function MedalText.TalentName(need): string
	local talent = TalentConfig.ById[need.id]
	local name = if talent then talent.name else need.id
	if talent and #talent.costs > 1 and need.level > 1 then
		return name .. " " .. need.level
	end
	return name
end

-- "Needs: Double Jump, Dash" with every talent green when `levelOf(talentId)` meets it and red when not; nil for a
-- stage without requirements (S1.2).
function MedalText.Needs(stage, levelOf: (string) -> number): string?
	if #stage.requires == 0 then
		return nil
	end
	local parts = {}
	for _, need in stage.requires do
		table.insert(parts, font(if levelOf(need.id) >= need.level then "#7CE07C" else "#F06A5E", MedalText.TalentName(need)))
	end
	return "Needs: " .. table.concat(parts, ", ")
end

-- Best medal still reachable after `elapsed` seconds, with its limit: "★★★ 0:56", or "no medal".
function MedalText.Target(stage, elapsed: number): string
	local medal = StageConfig.EvaluateMedal(stage, elapsed)
	if medal == 0 then
		return "no medal"
	end
	return font(MedalText.Gold, string.rep("★", medal)) .. " " .. TimeFormat.Short(StageConfig.Threshold(stage, medal))
end

return MedalText
