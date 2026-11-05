# Pawvest — Localization

Status: English + Czech, L1-L3 implemented and Studio-validated (2026-10-23 / 24); font BuilderSansBold (2026-11-02). Open: the Czech overflow
pass of the panels (ROADMAP → open items), L4 (more languages, chosen from telemetry). The always-needed rules are in AGENTS.md → Localization
rules; this file says how it works. Design checks and notes of L1-L3: `git show 87b1d3c:docs/LOCALIZATION.md`.

## Goal
- The game shows the player's language when it is supported, English otherwise; the player can switch in Settings.
- Supported now: **English** (default, fallback) and **Czech**. More languages are added later from data (L4): the
  telemetry `Session` event's locale breakdown plus the Creator Dashboard's audience by language.
- Translations are written by Claude into Luau string tables in git (Czech reviewed by the user). **No Roblox automatic
  translation** (uneven quality, no guaranteed Czech, managed outside git).

## How it works
- **`ReplicatedStorage/Locale.luau`:** `Locale.T(key, args?)` with `{name}` placeholders; `Locale.Current()`; `Locale.Changed`;
  `Locale.Supported = { en = "English", cs = "Čeština" }`. Fallback chain: current language → `en` → the key itself (a missing string is
  visible, never an error). On the server `Locale.T` answers in English: the server never builds translated text, it sends keys.
- **Language choice (three states):** the Settings row cycles **Automatic → English → Čeština** ("Language: Automatic (English)"). Profile
  `Language` (`""` = automatic), player attributes `LanguageSetting` (the choice) and `Language` (the resolved code clients render in);
  clients re-render on change, no rejoin. Automatic (`Locale.Resolve`): the account `LocaleId` when it is a supported language other than
  English, else the device's `LocalizationService.SystemLocaleId` (only a client can read it: sent once to `LanguageRemotes.SystemLocale`), else
  `en`. Why: Czech is not a Roblox account language, a Czech player's account says `en-us`. Until the attribute arrives a client resolves its own.
- **Server-written and Studio-authored labels:** `Locale.SetKey(label, key, args)` sets the tag `Loc`, `LocKey` / `LocArgs` (JSON) and the
  English text as a fallback; `Locale.SetText(label, text)` writes a literal (times, star lines) and clears the key. `LocalizedText.client`
  translates every tagged label locally and again when the language, the attributes or the label's `Text` change (the server's English must
  not win). Argument values may be keys (`{ key = "stage.name.Stage6" }`) or decimals (`{ decimal = "4.5" }`, shown with the viewer's mark).
  Studio-authored signs carry the tag and `LocKey` set through the MCP (so `loc.py check` notes `sign.*` as unused). The Stage 9 maze exit door,
  `KitLab` and the Admin panel stay English; panel titles authored in Studio (Skills, Settings) are set from their scripts.
- **Names held as data** go through `Locale` helpers that fall back to the config's English (`-- loc: ignore` on those lines): `StageName`,
  `PetKindName` (`pet.kind.<Kind>`), `RarityName`, `FoodName`, `TalentEffect` (`talent.effect.<id>[.<level>]`), `PetName` ("Cat Lv 12",
  `pet.nameLevel`), `CropName`, `WorldName`, `MedalName`, `TalentName`, `EggName`. Ids are DataStore keys and never change. `MedalText` builds its rich text from keys. Pet names
  (P3b) are user data, never localized.
- **Plural:** a string may hold forms, `en = { one, other }`, `cs = { one, few, other }` (1 / 2-4 / else), chosen by the `count` argument.
- **Numbers:** whole numbers through `Locale.Number` (English "12,500"; Czech groups from five digits, "1500" / "12 500" with a no-break space),
  decimals `Locale.Decimal` ("4,5"), percentages `common.percentBonus` ("+4.5%" / "+4,5 %"), time spans `Locale.Duration`. Times keep `mm:ss.t`.
- **Czech style decisions:** pet levels keep "Lv" ("úroveň" already means a stage); where Czech agreement differs by noun, one key per case
  instead of a fragment (`arena.keyCollected.<key>`); a sentence with a pet name puts the name after a colon ("Máš nového mazlíčka: {pet}!") so no
  case ending is needed; shared refusals are `common.reject.*`, "N more Coins needed" `common.needMoreCoins`.
- **No double translation:** `AutoLocalize = false` on every GUI built in code and on the Studio `ScreenGui`; the Creator Dashboard's automatic
  translation is off (the user, before publishing).
- **Font:** `StudStyle.Font` = **BuilderSansBold** (render test 2026-11-02 of nine fonts: FredokaOne and Bangers draw Czech carons / rings and
  Cyrillic in a thin fallback font; BuilderSansBold, GothamBold, SourceSansBold, Nunito and Arimo have Latin Extended-A and Cyrillic). New Studio
  labels use BuilderSansBold, never FredokaOne. Not checked: Greek, Turkish, Arabic, CJK.
- Player names, the admin panel and debug texts stay untranslated.

## Strings workflow
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
  file against `tools/loc_lint_baseline.txt`; a file above
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

## Checks after a localization change
- Player Emulator locale `cs-cz` → Czech on first join; `en-us` and an unsupported locale (`ja-jp`) → English.
- Switching in Settings re-renders open panels, the ScorePanel, gate signs and boards at once; a rejoin keeps the choice;
  "automatic" follows the locale again.
- `tools/loc.py check` reports 0 errors and `lint` stays within the baseline; in the pseudo-language no label in the
  converted scope shows unbracketed text.
- Screen captures (one at a time) of each converted panel in Czech show no overflow or missing glyphs.
