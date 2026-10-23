-- Strings/Hud (L1, docs/LOCALIZATION.md): score panel, stage timer, results popup, gate prompts and the explore /
-- arrival warnings. Keys never change once shipped.

return {
	-- score panel (written by PlayerTimerHandler through Locale.SetKey)
	["hud.score.record"] = { en = "Your record: {time}", cs = "Tvůj rekord: {time}" },
	["hud.score.firstTry"] = { en = "First try!", cs = "První pokus!" },
	["hud.score.chooseStage"] = { en = "Choose a stage!", cs = "Vyber si úroveň!" },
	["hud.score.enterPortal"] = { en = "Enter portal!", cs = "Vstup do brány!" },
	["hud.score.starsEarned"] = { en = "Stars earned: {n} / {max}", cs = "Získané hvězdy: {n} / {max}" },

	-- stage timer / MedalText
	["hud.timer.noMedal"] = { en = "no medal", cs = "bez medaile" },
	["hud.needs"] = { en = "Needs: {list}", cs = "Potřeba: {list}" },

	-- results popup
	["results.title"] = { en = "{stage} finished", cs = "{stage} dokončena" },
	["results.newRecord"] = { en = "New record!", cs = "Nový rekord!" },
	["results.record"] = { en = "Record: {time}", cs = "Rekord: {time}" },
	["results.noMedal"] = { en = "No medal", cs = "Bez medaile" },
	["results.coins"] = {
		en = { "+{count} Coin", "+{count} Coins" },
		cs = { "+{count} mince", "+{count} mince", "+{count} mincí" },
	},
	["results.firstFinish"] = {
		en = { "First finish +{count} Coin", "First finish +{count} Coins" },
		cs = { "První dokončení +{count} mince", "První dokončení +{count} mince", "První dokončení +{count} mincí" },
	},
	["results.runReward"] = { en = "Run reward +{count} (run {run} today)", cs = "Odměna za běh +{count} ({run}. běh dnes)" },
	["results.petXp"] = { en = "Pets +{xp} XP ({move} from moving)", cs = "Mazlíčci +{xp} XP ({move} za pohyb)" },
	["results.freeEgg"] = { en = "🎁 Free {egg} → your incubator", cs = "🎁 {egg} zdarma → do tvého inkubátoru" },
	["results.next"] = { en = "Next: {medal} under {time}", cs = "Další cíl: {medal} pod {time}" },
	["results.allMedals"] = { en = "All medals earned!", cs = "Všechny medaile získány!" },

	-- gate prompts and toasts
	["gate.prompt.unlock"] = {
		en = { "Unlock · {count} Coin", "Unlock · {count} Coins" },
		cs = { "Odemknout · {count} mince", "Odemknout · {count} mince", "Odemknout · {count} mincí" },
	},
	["gate.prompt.needs"] = {
		en = { "Needs {count} Coin", "Needs {count} Coins" },
		cs = { "Potřebuješ {count} minci", "Potřebuješ {count} mince", "Potřebuješ {count} mincí" },
	},
	["gate.toast.unlocked"] = { en = "{name} unlocked!", cs = "Odemčeno: {name}!" },
	["gate.toast.gate"] = { en = "Gate", cs = "Brána" },
	["gate.reject.coins"] = { en = "Not enough Coins", cs = "Nemáš dost mincí" },
	["gate.reject.owned"] = { en = "Already unlocked", cs = "Už je odemčeno" },
	["gate.reject.loading"] = { en = "Still loading...", cs = "Ještě se načítá…" },
	["gate.reject.failed"] = { en = "Unlock failed", cs = "Odemčení se nepovedlo" },

	-- explore warning (StageExploreWarning)
	["hud.explore"] = {
		en = "<b>Exploring {stage} without a timer</b>\nYou got in around the gate: no time, medal or finish reward counts here, but Coins you pick up do. Go through the gate to run it for real. Carrying on is at your own risk.",
		cs = "<b>{stage} bez časomíry</b>\nDovnitř vedla cesta mimo bránu: čas, medaile ani odměna za dokončení se tu nepočítají, sebrané mince ano. Pro opravdový běh projdi branou. Pokračuješ na vlastní riziko.",
	},

	-- arrival warning (StageArrivalWarning)
	["hud.arrival.title"] = { en = "{stage} needs a talent", cs = "{stage} vyžaduje dovednost" },
	["hud.arrival.body"] = {
		en = "You can still enter, but some jumps are out of reach.",
		cs = "Vstoupit můžeš, ale na některé skoky nedosáhneš.",
	},
	["hud.arrival.openSkills"] = { en = "Open Skills", cs = "Otevřít dovednosti" },
	["hud.arrival.continue"] = { en = "Continue", cs = "Pokračovat" },
}
