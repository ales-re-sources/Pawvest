# Oby sandbox — Localization (design)

Status: design agreed 2026-10-23; L1 implemented and Studio-validated 2026-10-23 (see "Design check (L1)" below); L1.1
(strings workflow: CSV source, `tools/loc.py`, pseudo-language) 2026-10-24, see "Strings workflow". The Czech texts await
the user's review. L2 (client panels) implemented and Studio-validated 2026-10-24, see "Design check (L2)". L3 (server + Studio
texts) implemented 2026-10-24, see "L3 notes"; font check and Czech overflow pass still open. Milestones **L1–L3** (L4 later) in [ROADMAP.md](ROADMAP.md),
after telemetry (T1a / T1b, [TELEMETRY.md](TELEMETRY.md)).

## Goal
- The game shows the player's language when it is supported, English otherwise; the player can switch in Settings.
- Supported now: **English** (default, fallback) and **Czech**. More languages are added later from data (L4): the
  telemetry `Session` event's locale breakdown plus the Creator Dashboard's audience by language.
- Translations are written by Claude into Luau string tables in git (Czech reviewed by the user). **No Roblox automatic
  translation** (uneven quality, no guaranteed Czech, managed outside git).

## Current state
No localization exists: about 450 player-visible strings are hard-coded English. Most are in client scripts that build
GUI in code (largest: `GardenClient`, `IncubatorClient`, `PetsPanel`, `FoodShopClient`, `StageResultsPopup`); some are
written by **server** scripts and replicate in one language (the ScorePanel in `PlayerTimerHandler`, `GateSign`,
Top-10 / stars board titles, garden plot signs, pen labels, incubator lock text); display names live in configs
(`StageConfig`, `TalentConfig`, `PetConfig`, `GardenConfig`); some labels are authored in Studio only.

## Design
- **`ReplicatedStorage/Locale.luau`** — `Locale.T(key, args?)` with `{name}` placeholders and a plural helper for counts;
  `Locale.Current()`; `Locale.Changed` signal; `Locale.Supported = { en = "English", cs = "Čeština" }` (native names).
  Fallback chain: current language → `en` → the key itself (a missing string is visible, never an error).
- **Strings** — since L1.1 one table, `localization/strings.csv` (key, context, English and the translations side by
  side), compiled into `ReplicatedStorage/Strings/<lang>.luau`; see "Strings workflow" below. (L1 had hand-written
  modules per area with `{ en = …, cs = … }` entries.)
- **Language choice:**
  - first join: `player.LocaleId` (`cs-cz` → `cs`), unsupported → `en`;
  - override: a **"Language: English / Čeština"** row in the Settings panel (same pattern as `MusicSettings.client.luau`,
    next LayoutOrder), sent with a `SetLanguage` remote; the server validates it against `Locale.Supported`;
  - stored in the profile as `Language` (`""` = automatic), mirrored as the player attribute `Language`; clients follow
    the attribute and re-render on change (no rejoin).
- **Client texts:** every literal goes through `Locale.T`. Panels that build once also re-render on `Locale.Changed`.
- **Server-written texts:** the server no longer writes English. It sets attributes `LocKey` + `LocArgs` (JSON) on the
  label (and the tag `Loc`); a generic **`LocalizedText.client.luau`** translates every tagged label locally and again
  when the language or the attributes change. The same mechanism covers Studio-authored labels (tagged via the MCP;
  layout stays Studio-only).
- **Config display names** (stages, worlds, medals, talents + effect texts, pet kinds / rarities / eggs, foods):
  ids never change (they are DataStore keys); display goes through keys such as `pet.kind.Cat`. `MedalText` builds its
  rich text from keys. Times keep the `mm:ss.t` format in every language.
- **No double translation:** `AutoLocalize = false` on the GUIs we build, and the Creator Dashboard's automatic
  translation turned off (user action).
- Player names, admin panel and debug texts stay untranslated.
- Fonts: check that the fonts in use render Czech diacritics (ě š č ř ž ý á í é ů ú); longer strings must fit
  (`TextScaled` or size changes in Studio).

## Design check (L1, 2026-10-23)
Against the code, the design holds with these decisions:
- **Display names move partly into L1.** The L1 HUD shows stage, world and hub names (ScorePanel, results popup, explore /
  arrival warnings, gate prompts and toasts), medal names, talent names (arrival warning) and egg names (results popup).
  Their keys come in L1 (`Strings/Names`: `stage.name.<key>`, `world.name.<n>`, `hub.name`, `medal.name.<Bronze…>`,
  `talent.name.<id>`, `pet.egg.<id>`); L2 adds the rest (pet kinds, rarities, foods, talent effect texts) and switches
  the remaining panels over. Ids stay the DataStore keys; `displayName` / `name` in the configs remain the English
  source and the fallback.
- **`MedalText`** in L1: `Target` ("no medal"), `Needs` and `TalentName` go through `Locale.T` (used by the timer and the
  arrival warning); `UnlockBar` (portal and gate faces) stays for L2 with its panels. On the server `Locale.T` answers in
  English; the server never builds translated text, it sends keys.
- **Language setting = three states:** the Settings row cycles **Automatic → English → Čeština → Automatic** and reads
  "Language: Automatic (English)" / "Jazyk: Čeština" in the current language. Profile `Language` (`""` = automatic),
  player attributes `LanguageSetting` (the stored choice) and `Language` (the resolved code the clients render in).
  Until the attribute arrives a client uses its own `LocaleId`.
- **Server labels:** `Locale.SetKey(label, key, args)` sets `LocKey` / `LocArgs` (JSON) / tag `Loc` and the English text
  as a fallback; `Locale.SetText(label, text)` writes a literal (times, star lines) and clears the key. `LocalizedText`
  re-applies the translation when the language, the attributes or the label's `Text` change (the server's English
  fallback replicating after the attributes must not win). Argument values may themselves be keys
  (`{ key = "stage.name.Stage6" }`), so a ScorePanel line never needs a server-side translation.
- **Plural:** a string may hold forms instead of one text; `en = { one, other }`, `cs = { one, few, other }` (1 / 2-4 /
  else), chosen by the `count` argument.
- **The Music row** of the Settings panel is converted with the new Language row (same panel).
- **AutoLocalize = false** on the ScreenGuis built in L1 code; the Studio-authored `ScreenGui` gets it in L3. The user
  turns off automatic translation on the Creator Dashboard before publishing (Localization → Settings).

## Design check (L2, 2026-10-24)
- **Names held as data** go through `Locale` helpers that fall back to the config's English: `PetKindName`
  (`pet.kind.<Kind>`), `RarityName` (`pet.rarity.<id>`), `FoodName` (`food.name.<id>`), `TalentEffect`
  (`talent.effect.<id>` or per level `talent.effect.<id>.<level>`), `PetName` ("Cat Lv 12", `pet.nameLevel`). The configs
  keep their English `name` / `effect` fields as source and fallback; those lines carry `-- loc: ignore`.
- **Numbers:** every whole-number placeholder is formatted by `Locale.Number` (English "12,500"; Czech groups from five
  digits, "1500" / "12 500" with a no-break space); decimals through `Locale.Decimal` ("4,5" in Czech); percentages as
  `common.percentBonus` ("+4.5%" / "+4,5 %"). Time spans through `Locale.Duration` (`common.duration.*`).
- **Pet levels keep "Lv" in Czech:** "úroveň" is already the stage name (`stage.name.*`), so "Kočka Lv 12" avoids two
  meanings of one word. Open point for the user's review.
- **Shared texts:** refusals that several panels share are `common.reject.*` (coins, stale, loading, failed, far,
  noplot), the "N more Coins needed" line `common.needMoreCoins`; each panel keeps its own keys for the rest.
- **Grammar:** where Czech agreement differs by noun, one key per case instead of a fragment: the arena toasts are
  `arena.keyCollected.<key>` ("Tyrkysový klíč") and `arena.gateOpened.<key>` ("Tyrkysová brána"); sentences with a pet
  name put the name after a colon ("Máš nového mazlíčka: {pet}!") so no case ending is needed.
- **Panel titles authored in Studio** (Skills, Settings) are set from the panels' scripts; the Admin panel stays English.
- **Server-written texts** in the garden (pen / incubator billboards, plot signs) and the boards stay for L3; the garden
  pen pet label built on the server by `PetLook.LabelText` is English there until L3.

## Strings workflow (L1.1, 2026-10-24)
**Source:** `localization/strings.csv`, the one table people edit: `key`, `context` (where the text appears, what goes
into each `{placeholder}`, grammar notes such as "feminine in Czech"), `en`, and per translation `<lang>` /
`<lang>_status` (`new` = written or changed, waiting for review; `ok` = reviewed) / `<lang>_en_hash` (the English the
translation was written for: when the English changes, `build` puts the translation back to `new`).
- Opens in Excel by double-click: UTF-8 with BOM, comma separated. **No `sep=,` first line:** with it Excel ignores the
  BOM and garbles č / ř / ě (checked 2026-10-24, Microsoft 365, en-US). `loc.py` still reads a file with a `sep=` line or
  semicolons (what a Czech-locale Excel saves) and rewrites it in the canonical form on `build`
  (`EXCEL_SEP_LINE` in `tools/loc.py` switches the line on).
- A key starting with `#` is a section heading. Plural keys have one row per form: `key[one]`, `key[few]`, `key[other]`
  (English one + other, Czech one + few (2-4) + other; English leaves `few` empty).
- Inside a cell, `\n` is a line break and `\\` a backslash; a leading `\` is dropped, so `\=` or `\+` keeps Excel from
  reading the cell as a formula (`check` reports such cells). The hashes start with `h` so Excel keeps them as text.

**Generated:** `python tools/loc.py build` writes `src/ReplicatedStorage/Strings/en.luau`, `cs.luau` and `qps.luau` (flat
`["key"] = "text"` / `{ plural forms }` tables, header "GENERATED", never edited by hand; committed, because Argon syncs
them into Studio). `Locale.luau` reads only these.

**Pseudo-language `qps`:** generated from English: Czech-style accents (tests the glyphs), about 40 % longer (tests the
space), wrapped in `[!! … !!]`; placeholders and rich-text tags stay intact. Selectable in the Settings row in Studio and
by admins (`Locale.PseudoAllowed`). On screen, text **without** the brackets is still a literal in the code; cut-off text
is too long; letters drawn in another font are missing from the label's font.

**Checks** (offline, no Studio):
- `python tools/loc.py check`: missing translations and plural forms; `{placeholders}` and rich-text tags differing from
  English; formula-looking cells; generated files out of date; keys the code uses that do not exist; keys no code uses
  (a key built at runtime counts as used through its prefix literal, e.g. `"stage.name."`). Exit code 1 on an error;
  the translations waiting for review are notes.
- `python tools/loc.py lint`: player-visible text written as a literal in `src/` (property assignments such as
  `.Text = "…"`, and any string that reads like prose outside logs, instance names and service lookups). Counted per
  file against `tools/loc_lint_baseline.txt` (the L2 / L3 backlog: 159 literals in 32 files on 2026-10-24); a file above
  its baseline fails. Lower the baseline with `--update-baseline` after converting a file, never raise it. A line that
  is not player text can carry `-- loc: ignore`; admin and debug scripts are in `LINT_IGNORE`.
- `python tools/loc.py review`: the rows waiting for review, as key / context / English / translation.

**Process for a new or changed string:**
1. Code: `Locale.T("area.thing", args)` on the client, `Locale.SetKey(label, key, args)` from the server; never a literal.
2. CSV: the row with key, context, `en` and the translations (Claude writes the Czech; `cs_status` = `new`).
3. `python tools/loc.py build`, then `check` and `lint` must pass before the commit.
4. Look: a pass in the pseudo-language (no unbracketed text, nothing cut off), then Czech (`TextFits`).
5. Review: the user goes through `review` (or filters `cs_status` = `new` in Excel), corrects the `cs` cell where needed
   and sets it to `ok`; Claude runs `build` and commits. A correction changes the cell, never the key.

A new language later (L4): add the code to `TRANSLATIONS` and `PLURAL_FORMS` in `tools/loc.py` and to
`Locale.Supported` / `Order` / `Names` and the module list in `Locale.luau`; `build` adds its columns to the CSV.

## Rollout
| Milestone | Scope |
|---|---|
| **L1** — infrastructure | `Locale`, `Strings/Common` + `Hud`, profile field, `SetLanguage` remote, Settings row, `LocalizedText` client; HUD essentials converted: ScorePanel, timer, results popup, gate prompts, explore / arrival warnings. Czech complete for these |
| **L1.1** — strings workflow | `localization/strings.csv` as the source, `tools/loc.py` build / check / lint / review, generated `Strings/<lang>.luau`, pseudo-language `qps`, lint baseline |
| **L2** — client panels | Pets, Skills (`TalentRows`), Garden, Incubator, Food shop, Arena HUD, hub portal / gate faces, `MedalText`, config display names |
| **L3** — server + Studio texts | gate signs, Top-10 / stars boards, garden plot signs / pens / incubators; MCP pass over Studio-authored `TextLabel` / `TextButton` literals in StarterGui and Workspace (tag + key); overflow check of every panel in Czech; **font check**: FredokaOne (the stud style's font) has no č ě ň ř š ť ď ž ů, Roblox draws them in a thinner fallback font (seen in the pseudo-language, 2026-10-24): pick a font that covers Latin Extended-A or accept the mix |
| **L4** — more languages (later) | chosen from the telemetry locale data; only new string fields + `Supported` entries |

## Rules (copied to AGENTS.md with L1, updated with L1.1)
- Never set player-visible text as a literal: use `Locale.T(key)` on the client or `LocKey` / `LocArgs` from the server.
- Keys are `area.thing.detail`, never renamed once shipped (a rename = new key, old one removed).
- Strings are edited only in `localization/strings.csv`; `python tools/loc.py build`, `check` and `lint` pass before every
  commit that touches text.

## Acceptance checks
- Player Emulator locale `cs-cz` → Czech on first join; `en-us` and an unsupported locale (`ja-jp`) → English.
- Switching in Settings re-renders open panels, the ScorePanel, gate signs and boards at once; a rejoin keeps the choice;
  "automatic" follows the locale again.
- `tools/loc.py check` reports 0 errors and `lint` stays within the baseline; in the pseudo-language no label in the
  converted scope shows unbracketed text.
- Screen captures (one at a time) of each converted panel in Czech show no overflow or missing glyphs.
