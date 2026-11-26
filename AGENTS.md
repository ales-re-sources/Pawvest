# Pawvest — agent guide

Roblox obby + pet-garden game: a central hub island with portals to 15 timed stages in 3 worlds (checkpoints, medals, Top-10 boards,
challenge coins, talents), pets, and a garden island of 8 plots (incubators, every player's crop field with field pets, barn, seed stall).

- Place **"Pawvest"**, placeId `73033440513091` (pinned in `Pawvest.project.json` → `placeIds`; the old place `83181838162651` is dead and its
  DataStores did not move).
- Code is synced to this repo with **Argon** (Rojo-compatible); the **scene lives only in the place file**.
- Luau, legacy run context (`.server.luau` = Script, `.client.luau` = LocalScript, `.luau` = ModuleScript).

## Docs (on demand: grep for the section you need, don't read a doc whole)
| Doc | Holds |
|---|---|
| [docs/ROADMAP.md](docs/ROADMAP.md) | status, what next, open items, done log. Answer "what next?" from here |
| [docs/GDD.md](docs/GDD.md) | the game as built: loop, stages, time tiers, rewards, talents, pets, garden, crop field (§7.9), UI rules, hints |
| [docs/EXPANSION.md](docs/EXPANSION.md) | pet-garden direction: not-built drops, monetization rules |
| [docs/ECONOMY.md](docs/ECONOMY.md) | economy targets, parameters and decisions, how to run `tools/economy.py` |
| [docs/STAGES.md](docs/STAGES.md) | stage building: components, build rules and gotchas, reach table, difficulty curve, per-stage notes |
| [docs/LAYOUT.md](docs/LAYOUT.md) | every script and scene folder, stage anatomy, **adding a world stage**, script stubs |
| [docs/PROTOCOL.md](docs/PROTOCOL.md) | every RemoteEvent, DataStore key and profile field, mirrored player attributes |
| [docs/TESTING.md](docs/TESTING.md) | Studio MCP habits, bots, live DataStore snapshot / restore, fresh-profile and multi-client tests |
| [docs/LOCALIZATION.md](docs/LOCALIZATION.md) | localization design, full rules and the strings workflow |
| [docs/TELEMETRY.md](docs/TELEMETRY.md) | telemetry events and how to read them on the Creator Dashboard |
| [docs/PET_GROWTH.md](docs/PET_GROWTH.md) | how PetLook derives a pet's look, how pet models are authored |
| [docs/PLANT_GROWTH.md](docs/PLANT_GROWTH.md) | plant art authoring, Studio commands, recipe contracts, per-crop status; crop designs in `docs/plants/` |
| [docs/HYBRIDS.md](docs/HYBRIDS.md) | hybrid plants / breeding design (after 1.0); prototype: `docs/HYBRID_PROTOTYPE.md` |
| [docs/THUMBNAILS.md](docs/THUMBNAILS.md) | store thumbnails: themes, variants, test plan, how they are built |

**Before designing a crop:** read `docs/PLANT_GROWTH.md`. The standard art review is five snapshots (0/20/50/75/100%).

Tools: `tools/economy.py` (run `check` after changing any price, rate or reward in a config, `pin` to accept reviewed values),
`tools/loc.py` (strings), `tools/vault_reach.py` + `tools/vault_right_checks.sh` (Stage 14's Key Vault reachability; re-run after moving
a vault part), `tools/kit_coplanar_audit.luau` (z-fighting audit, STAGES.md → Build gotchas).

**Workflow:** milestone by milestone per ROADMAP (design check → scope with hard acceptance checks → implement → Studio validation → status +
commit). Status levels (Implemented / Studio-validated / Live-validated) change only after validation.

**Keeping docs small** (this file loads into every session): AGENTS.md holds only rules that apply to most tasks. Docs hold the design as
built and the *why* of decisions, not history: no dated change logs, validation logs or iteration stories (git keeps those). A finished
milestone becomes one line in ROADMAP → Done and its as-built design goes to GDD (or STAGES for a stage). Durable lessons from a validation
become one-line rules here or in TESTING / STAGES.

## How code gets here (read before editing)
Argon runs in **Only Code Mode**: `src/` contains every script **plus the instances that contain scripts** (as folders with `init.meta.json`
holding only `className`; no properties). Parts, GUI layout, RemoteEvents, Sounds, lighting etc. exist **only in Studio**.
- Do not "clean up" folders like `src/Workspace/World1/Stage5/Part_01/` — that folder *is* the kill part that owns the script.
- Size / colour / position of parts, GUI layout and Studio-only RemoteEvents change in Studio (by hand or the Roblox Studio MCP), not in files.
- Never run `argon build` to produce the real place — it would contain only scripts and default parts.
- Safety nets that must stay on: `$keepUnknowns: true` on every service in `Pawvest.project.json` and the plugin's **Keep Unknowns**
  setting. Without them a Server-priority sync deletes the scene.
- Sibling names must be unique (Argon drops duplicates on syncback): new scripted parts need unique names (`Part_11`, `KillPart_3`).
  Exception: ChoiceStage `Step` parts (STAGES.md → Build gotchas).
- **Argon does not write the script files of instances created through the Studio MCP** (clones, `execute_luau`; a `Source` changed that way
  does not reach the disk either). New scripted instances start as files on disk (LAYOUT.md → Adding a world stage).
- `sourcemap.json` and `*.rbxl` are git-ignored.

Roblox Studio MCP is available for inspecting / editing the live place (`search_game_tree`, `execute_luau`, `script_read`, `screen_capture`,
playtests). Studio must be in **Edit** mode for `datamodel_type: "Edit"`.

## Layout
Per-file and per-scene-folder descriptions live in [docs/LAYOUT.md](docs/LAYOUT.md): grep it (or the file itself) when you need one.
```
src/ReplicatedStorage/        shared modules: configs (Stage / Pet / Garden / Crop / Talent / ChallengeCoin / Arena / Admin),
                              Locale + generated Strings/, KitMath, StudStyle, PetLook, TimeFormat, MedalText, plant recipes
src/ServerScriptService/      services: PlayerProfile (DataStore), CoinRewards, StageResults, StageUnlocks, PetService,
                              Garden* (plots, incubators, food, field, plot feed), RespawnService, TalentService, Telemetry,
                              LanguageService, admin remotes
src/StarterPlayer/StarterPlayerScripts/  client: obstacle kit (ObstacleKit, KitZones, KitMaze, KitGhosts), StageCamera, checkpoints,
                              gates / portals, pets (PetClient, PetFollow, PetsPanel, PetDetail), garden (GardenView, PlotView,
                              FieldClient, panels), settings
src/StarterGui/               CoinGui, ScreenGui (TopLeftIcons/ButtonHandler, SkillsPanel, AdminPanel)
src/Workspace/Handlers/       CheckpointTouchHandler, PlayerTimerHandler, StageScripts (the logic behind every stage script stub)
src/Workspace/                StartLocation (hub), Tutorial, World1 (Stage1-5), World2 (Stage6-10), World3 (Stage11-15), Garden,
                              DebugBaseplate (the sea kill brick); scene content of these is Studio-only
```

### Stages
- World stages live in `Workspace.World<n>.Stage<k>`; a new stage takes the next free block of 100 checkpoint numbers. Anatomy and the
  procedure for a new stage: LAYOUT.md; build rules and gotchas: STAGES.md.
- Stage scene scripts are byte-identical one-line stubs `require(workspace.Handlers.StageScripts).<Fn>(script)`: change behaviour in
  `StageScripts`, never in a copy. It never hard-codes a stage: `StageConfig.ForInstance(script)` (stage = the Workspace folder the stub
  lives in) or `StageConfig.ByHubPortal[...]`.
- Stage keys (`"Stage1"`…`"Stage15"`, `"Tutorial"`; equal to the stage's `folder` and position) are DataStore keys and **never change**. Hub
  label: `StageConfig.HubName` (`"Central Island"`).

## Networking & persistence (tables: [docs/PROTOCOL.md](docs/PROTOCOL.md); update it with every remote / profile / attribute change)
- Remotes live in `ReplicatedStorage`, created at runtime by their service (only `StageTimerUpdate`, `StageTimerStopped`, `ResetPlayerTimer`
  exist in Studio). The server never takes a price, time, reward or position from a client: prices come from the configs, times from server
  `os.time()`, plot actions are derived from the caller; answers come back on the service's `Result` remote.
- Every admin remote checks `AdminConfig.IsAdmin` on the server (the client check only hides the panel).
- The profile (`PlayerProfiles`, `user_<UserId>`) is read and written only through `PlayerProfile` (never `SetAsync` on it directly). It is
  saved on leave, every 60 s and in `BindToClose`; a failed load blocks saving for that session; writes to one key are spaced
  `MIN_WRITE_GAP` (7 s): `Save` only marks the profile dirty.
- Gameplay Coins go through `CoinRewards.Grant` (pet multiplier); purchases, deductions and sales call `PlayerProfile.AddCoins`. Stored Coins
  were scaled ×10 once by the `Version = 3` migration: never multiply stored Coins by hand.
- Stored ids are never renamed or reused: stage keys, challenge coin ids (`<stage folder>_<n>`), aptitude ids, upgrade / tool ids, crop ids,
  field square numbers.
- Every player has the crop field (there is no no-field path). A profile from before it converts once on join (`GardenField` `convert`).
- Studio playtests with API access read / write the **live** DataStores: snapshot before any write (docs/TESTING.md).

## Localization (full rules: [docs/LOCALIZATION.md](docs/LOCALIZATION.md) → Strings workflow)
- Never set player-visible text as a literal: `Locale.T(key)` on the client, `Locale.SetKey(label, key, args)` from the server
  (`Locale.SetText` only for texts without words). Names of stages, worlds, medals, talents, eggs, pets, crops go through the `Locale`
  helpers (`Locale.StageName` etc.). Numbers go through placeholders. Pet names are user data, never localized.
- Strings live only in `localization/strings.csv` (new / changed row: context hint, `en`, `cs`, `cs_status` = `new`); never edit the generated
  `src/ReplicatedStorage/Strings/*.luau`. Keys are `area.thing.detail`, never renamed once shipped.
- Before every commit that touches text: `python tools/loc.py build`, `check` (0 errors) and `lint` (within the baseline; never raise it).
  List the new / changed Czech texts in the summary for the user's review.
- Czech is longer: let text wrap and grow (`TextWrapped` + `AutomaticSize`); GUIs built in code set `AutoLocalize = false` and re-render on
  `Locale.Changed`.

## Gotchas
- **Argon / sync**
  - Only **one** Argon plugin may be enabled in Studio (the CLI installs `%LOCALAPPDATA%\Roblox\Plugins\Argon.rbxm`; a Creator Store copy must
    stay disabled). Two plugins each create every new file → duplicate scripts.
  - Two-way sync is on: deleting / renaming a synced script **in Studio deletes / renames the file**. Do such changes on disk. Clean up
    Studio-side duplicates only while Argon is disconnected.
  - Initial sync priority is **Client** (Studio overwrites files on connect): commit before connecting and check `git status` right after;
    files edited while disconnected are overwritten by Studio's copy.
  - If a file edit does not show in Studio although Argon is connected, reconnect the plugin.
  - **Disconnect Argon before any git command that changes the working tree** (switch, checkout, merge, pull, reset, stash): Argon applies the
    change to Studio and deletes the Studio-only children of every script container that disappears, even for a moment.
  - **Moving or renaming a script container on disk recreates its Studio instance**: its Studio-only children are lost, a stashed copy of the
    scripted part is deleted too (Argon tracks the instance, not the path), and a renamed checkpoint folder comes back as a default part at the
    origin. Reparent in Studio instead, or note the scripted parts' properties first and rebuild after the move.
  - Adding a script file under a plain Studio instance does not convert it: Argon creates a second empty one. After adding / renaming script
    containers, check Studio for duplicates and lost children.
- Stage building (ChoiceStage `Step` parts, `FallResetDepth`, kit z-fighting audit, finish portal orientation, decorations, challenge coins):
  STAGES.md → Build gotchas.
- Debounces in timer, portal and checkpoint code are per player; a kill part kills a living character once (no debounce). The timer uses
  `os.clock()`; times are floored to tenths (`TimeFormat.Tenths`) before storing.
- **GUI:** a ScreenGui built in code gets `ZIndexBehavior = Sibling`. A BillboardGui with buttons lives in PlayerGui (`Adornee` = the part)
  with `Active = true` and `ResetOnSpawn = false` (without `Active` its buttons get no clicks / taps). Passive panels can use
  `Active = false` + `InputSink = All` to block world input with an arrow cursor; custom world tap / hover handlers use `UiKit.BlocksWorld`;
  native world clicks use `UiKit.PointerPosition()` (raw `GetMouseLocation()` does not match GUI hit-testing). A click never makes panel
  content jump: same parts and sizes in every state.
- **Shared helpers before local copies:** countdowns `TimeFormat.Clock`, client / stored number checks `Num`, id-set
  attributes `IdSet`, status colours `StudStyle.Text`, refusal texts `Locale.Reject(reason, specific)` (falls back to
  `common.reject.*`), stage lookups `StageConfig.TryForInstance` / `AreaOf` / `MedalsFromAttributes` / `AnyUnlocked`.
  Server: remotes through `Remotes` (Folder / Add / Results / Admin), cooldowns `RateLimit.new`, profile mirrors through
  `PlayerProfile.OnReady` (join + reset), purchases `PlayerProfile.TrySpend`, garden successes `GardenService.Done`.
  Client GUI: builders, bars, self-clearing messages, toasts, pulses, refused-buy shake / notice `UiKit`; HUD popups `HudPopup`; two-tap confirms
  `ConfirmTap`; stand prompts `GardenUi.BindStand` + `PanelFocus.Open(..., anchor)`; a player's plot `GardenConfig.PlotOf`.
  Obstacle kit client: tags, cached attributes, kills, run start `KitClient`. Plant recipes: `PlantKit.recipe`, `proxyGrowth`,
  `proxyRod`; a `<CropId>Plant` module is in the field unless `Draft = true`.
- Legacy APIs are common (`wait`, `spawn`, `:connect`, `findFirstChild`); prefer `task.*` and `Players:GetPlayerFromCharacter` in new code,
  but don't mass-rewrite without asking.

## Testing
No automated tests. Validate by risk; scope acceptance checks to the tier a change needs, not more. Playtests, bots and DataStore
fixtures: **read [docs/TESTING.md](docs/TESTING.md) first**.
- **Always:** grep for leftovers of what changed; the tool checks that apply (`economy.py check`, `loc.py check` / `lint`, a smoke run of
  any tool command a change touches); one playtest boot (MCP `start_stop_play`) reading server and client errors / warnings.
- **UI or input changed:** each changed control through the real UI at least once (firing remotes alone once missed a broken button).
  A pure removal only needs a look at the affected screens.
- **Stored data migrated or rewritten:** first read the live profiles (one playtest, read-only). Test the path with a fixture only if a
  live profile actually needs it; otherwise review the path in code and say so.
- **Never skipped:** a snapshot right before any write to a live profile (TESTING.md → Live DataStore snapshot / restore).

**Keep tool output small** (it all stays in the context): read the console through `LogService:GetLogHistory()` filtered and cut
(TESTING.md), never `get_console_output`. Big files (PetLook, ObstacleKit, PetsPanel, PetDetail, Telemetry, FoodShopClient, FieldClient,
GardenField, StageConfig, IncubatorClient: 17-50 kB): Grep for the function / text, then Read with `offset` / `limit`.
