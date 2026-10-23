-- Strings/Common (L1, docs/LOCALIZATION.md): texts shared by several areas. Keys never change once shipped.
-- Plural forms: en = { one, other }, cs = { one, few (2-4), other }, chosen by the `count` argument.

return {
	["common.coins"] = {
		en = { "{count} Coin", "{count} Coins" },
		cs = { "{count} mince", "{count} mince", "{count} mincí" },
	},
	["common.on"] = { en = "On", cs = "Zapnuto" },
	["common.off"] = { en = "Off", cs = "Vypnuto" },
	["settings.music"] = { en = "Music: {state}", cs = "Hudba: {state}" },
	["settings.language"] = { en = "Language: {name}", cs = "Jazyk: {name}" },
	["settings.language.auto"] = { en = "Automatic ({name})", cs = "Automaticky ({name})" },
}
