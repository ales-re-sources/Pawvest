-- Strings/Names (L1, docs/LOCALIZATION.md): display names of config entries (ids stay the DataStore keys). Read through
-- Locale.StageName / WorldName / HubName / MedalName / TalentName / EggName, which fall back to the config's English name.

local names = {
	["hub.name"] = { en = "Central Island", cs = "Centrální ostrov" },
	["stage.name.Tutorial"] = { en = "Tutorial", cs = "Výuka" },

	["medal.name.Bronze"] = { en = "Bronze", cs = "Bronz" },
	["medal.name.Silver"] = { en = "Silver", cs = "Stříbro" },
	["medal.name.Gold"] = { en = "Gold", cs = "Zlato" },
	["medal.label.Bronze"] = { en = "Bronze medal", cs = "Bronzová medaile" },
	["medal.label.Silver"] = { en = "Silver medal", cs = "Stříbrná medaile" },
	["medal.label.Gold"] = { en = "Gold medal", cs = "Zlatá medaile" },

	["talent.name.RunSpeed"] = { en = "Run Speed", cs = "Rychlost běhu" },
	["talent.name.DoubleJump"] = { en = "Double Jump", cs = "Dvojitý skok" },
	["talent.name.JumpHeight"] = { en = "Jump Height", cs = "Výška skoku" },
	["talent.name.QuickRespawn"] = { en = "Quick Respawn", cs = "Rychlé oživení" },

	["pet.egg.Basic"] = { en = "Basic egg", cs = "Obyčejné vejce" },
	["pet.egg.Golden"] = { en = "Golden egg", cs = "Zlaté vejce" },
}

-- worlds 1-4 and the numbered stages 1-20 (StageConfig keys "Stage1" … "Stage20")
for n = 1, 4 do
	names["world.name." .. n] = { en = "World " .. n, cs = "Svět " .. n }
end
for n = 1, 20 do
	names["stage.name.Stage" .. n] = { en = "Stage " .. n, cs = "Úroveň " .. n }
end

return names
