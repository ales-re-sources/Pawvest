# Oby sandbox — Localization (design)

Status: design agreed 2026-10-23; L1 implemented and Studio-validated 2026-10-23 (see "Design check (L1)" below); the
Czech texts await the user's review. L2 / L3 not started. Milestones **L1–L3** (L4 later) in [ROADMAP.md](ROADMAP.md),
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
- **`ReplicatedStorage/Strings/<Area>.luau`** — one module per area (`Common`, `Hud`, `Stages`, `Talents`, `Pets`,
  `Garden`, …): `["area.thing.detail"] = { en = "…", cs = "…" }`. A new language = one more field per key and a
  `Supported` entry. A check (Studio command bar / MCP) lists keys missing a supported language.
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

## Rollout
| Milestone | Scope |
|---|---|
| **L1** — infrastructure | `Locale`, `Strings/Common` + `Hud`, profile field, `SetLanguage` remote, Settings row, `LocalizedText` client; HUD essentials converted: ScorePanel, timer, results popup, gate prompts, explore / arrival warnings. Czech complete for these |
| **L2** — client panels | Pets, Skills (`TalentRows`), Garden, Incubator, Food shop, Arena HUD, hub portal / gate faces, `MedalText`, config display names |
| **L3** — server + Studio texts | gate signs, Top-10 / stars boards, garden plot signs / pens / incubators; MCP pass over Studio-authored `TextLabel` / `TextButton` literals in StarterGui and Workspace (tag + key); overflow check of every panel in Czech |
| **L4** — more languages (later) | chosen from the telemetry locale data; only new string fields + `Supported` entries |

## Rules (copied to AGENTS.md with L1)
- Never set player-visible text as a literal: use `Locale.T(key)` on the client or `LocKey` / `LocArgs` from the server.
- Keys are `area.thing.detail`, never renamed once shipped (a rename = new key, old one removed).
- A new string needs every supported language before commit (the missing-key check reports 0).

## Acceptance checks
- Player Emulator locale `cs-cz` → Czech on first join; `en-us` and an unsupported locale (`ja-jp`) → English.
- Switching in Settings re-renders open panels, the ScorePanel, gate signs and boards at once; a rejoin keeps the choice;
  "automatic" follows the locale again.
- The missing-key check reports 0 for `cs`; no label in the converted scope still shows an English literal in Czech mode.
- Screen captures (one at a time) of each converted panel in Czech show no overflow or missing glyphs.
