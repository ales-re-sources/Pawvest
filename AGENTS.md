# Pawvest — agent guide

Roblox obby growing into a pet-garden game: a central hub island with portals to 15 timed stages in 3 worlds (checkpoints, medals, Top-10
boards, challenge coins, talents), pets, and a garden island with plots, incubators and, behind admin access, a crop field with field pets.

- Place **"Pawvest"**, placeId `73033440513091` (pinned in `Pawvest.project.json` → `placeIds`; the old place `83181838162651` is dead and its
  DataStores did not move).
- Code is synced to this repo with **Argon** (Rojo-compatible); the **scene lives only in the place file**.
- Luau, legacy run context (`.server.luau` = Script, `.client.luau` = LocalScript, `.luau` = ModuleScript).

## Docs (on demand: grep for the section you need, don't read a doc whole)
| Doc | Holds |
|---|---|
| [docs/ROADMAP.md](docs/ROADMAP.md) | status, what next, open items, done log. Answer "what next?" from here |
| [docs/GDD.md](docs/GDD.md) | the game as built: loop, stages, time tiers, rewards, talents, pets, garden, crop field (§7.9), hints |
| [docs/EXPANSION.md](docs/EXPANSION.md) | the pet-garden direction not yet built: MVP and drop plan (E5–E11, D1–D10), monetization rules |
| [docs/UI_GARDEN_PETS.md](docs/UI_GARDEN_PETS.md) | garden / pet UI redesign U1–U5 (decided, not built): field rings, square card, hand bar, panel split, pets list |
| [docs/ECONOMY.md](docs/ECONOMY.md) | economy parameters and decisions, how to run `tools/economy.py` |
| [docs/STAGES.md](docs/STAGES.md) | stage building: components, build rules, reach table, difficulty curve, per-stage as-built notes |
| [docs/LAYOUT.md](docs/LAYOUT.md) | every script and scene folder, stage anatomy, **adding a world stage**, copied-script table |
| [docs/PROTOCOL.md](docs/PROTOCOL.md) | every RemoteEvent, DataStore key and profile field, mirrored player attributes |
| [docs/LOCALIZATION.md](docs/LOCALIZATION.md) | localization design and the strings workflow |
| [docs/TELEMETRY.md](docs/TELEMETRY.md) | telemetry events and how to read them on the Creator Dashboard |
| [docs/PET_GROWTH.md](docs/PET_GROWTH.md) | how PetLook derives a pet's look, how pet models are authored |

Tools: `tools/economy.py` (economy model: run `check` after changing any price, rate or reward in a config, `pin` to accept reviewed values; `tools/economy_ev.py`: the engagement-first EV proposal, `economy.py proposal`),
`tools/loc.py` (strings, below), `tools/vault_reach.py` + `tools/vault_right_checks.sh` (Stage 14's Key Vault reachability; re-run after moving
a vault part), `tools/kit_coplanar_audit.luau` (z-fighting audit, Gotchas).

**Workflow:** milestone by milestone per ROADMAP (design check → scope with hard acceptance checks → implement → Studio validation → status +
commit). Status levels (Implemented / Studio-validated / Live-validated) change only after validation.

**Keeping docs small** (this file loads into every thread): AGENTS.md holds only rules that apply to most tasks; tables, procedures and
per-stage facts go to `docs/`. A finished milestone shrinks to a short "Done" entry in ROADMAP and its as-built design goes to GDD (or STAGES
for a stage); scopes, acceptance checks and validation logs stay in git only (point to them with `git show <hash>:<path>`). Durable lessons
from a validation go here (Gotchas / Testing) as one-line rules, not as stories.

## How code gets here (read before editing)
Argon runs in **Only Code Mode**: `src/` contains every script **plus the instances that contain scripts** (as folders with `init.meta.json`
holding only `className`; no properties). Parts, GUI layout, RemoteEvents, Sounds, lighting etc. exist **only in Studio**.
- Do not "clean up" folders like `src/Workspace/World1/Stage5/Part_01/` — that folder *is* the kill part that owns the script.
- Size / colour / position of parts, GUI layout and Studio-only RemoteEvents change in Studio (by hand or the Roblox Studio MCP), not in files.
- Never run `argon build` to produce the real place — it would contain only scripts and default parts.
- Safety nets that must stay on: `$keepUnknowns: true` on every service in `Pawvest.project.json` and the plugin's **Keep Unknowns**
  setting. Without them a Server-priority sync deletes the scene.
- Sibling names must be unique (Argon drops duplicates on syncback): new scripted parts need unique names (`Part_11`, `KillPart_3`).
  Exception: ChoiceStage `Step` parts (Gotchas).
- **Argon does not write the script files of instances created through the Studio MCP** (clones, `execute_luau`; a `Source` changed that way
  does not reach the disk either). New scripted instances start as files on disk (LAYOUT.md → Adding a world stage).
- `sourcemap.json` and `*.rbxl` are git-ignored.

Roblox Studio MCP is available for inspecting / editing the live place (`search_game_tree`, `execute_luau`, `script_read`, `screen_capture`,
playtests). Studio must be in **Edit** mode for `datamodel_type: "Edit"`.

## Layout
Per-file and per-scene-folder descriptions live in [docs/LAYOUT.md](docs/LAYOUT.md): grep it (or the file itself) when you need one.
```
src/ReplicatedStorage/        shared modules: configs (Stage / Pet / Garden / Crop / Talent / ChallengeCoin / Arena / Admin),
                              Locale + generated Strings/, KitMath, StudStyle, PetLook, TimeFormat, MedalText
src/ServerScriptService/      services: PlayerProfile (DataStore), CoinRewards, StageResults, StageUnlocks, PetService,
                              Garden* (plots, incubators, food, field, plot feed), RespawnService, TalentService, Telemetry,
                              LanguageService, admin remotes
src/StarterPlayer/StarterPlayerScripts/  client: obstacle kit (ObstacleKit, KitZones, KitMaze, KitGhosts), StageCamera, checkpoints,
                              gates / portals, pets (PetClient, PetFollow, PetsPanel, PetDetail), garden (GardenView, PlotView,
                              FieldClient, panels), settings
src/StarterGui/               CoinGui, ScreenGui (TopLeftIcons/ButtonHandler, SkillsPanel, AdminPanel)
src/Workspace/Handlers/       CheckpointTouchHandler, PlayerTimerHandler (required by every stage script)
src/Workspace/                StartLocation (hub), Tutorial, World1 (Stage1-5), World2 (Stage6-10), World3 (Stage11-15), Garden,
                              DebugBaseplate (the sea kill brick); scene content of these is Studio-only
```

### Stages
- World stages live in `Workspace.World<n>.Stage<k>` (`Gate`, `Top10Leaderboard`, `Arrival`, checkpoints `<number>/C`, finish
  `TeleportBackToStageStart/Portal`, obstacles); a new stage takes the next free block of 100 checkpoint numbers. Anatomy and the procedure
  for a new stage: LAYOUT.md.
- Stage scripts never hard-code a stage: they call `StageConfig.ForInstance(script)` (stage = the Workspace folder they live in) or
  `StageConfig.ByHubPortal[...]`, so most stage scripts are **byte-identical copies**: edit all copies consistently (grep by content or md5),
  including the `ServerStorage.StageKit` template copies (LAYOUT.md → Reusable script variants).
- Stage keys (`"Stage1"`…`"Stage15"`, `"Tutorial"`; equal to the stage's `folder` and position) are DataStore keys and **never change**. Hub
  label: `StageConfig.HubName` (`"Central Island"`).

## Networking & persistence (tables: [docs/PROTOCOL.md](docs/PROTOCOL.md); update it with every remote / profile / attribute change)
- Remotes live in `ReplicatedStorage`, created at runtime by their service (only `StageTimerUpdate`, `StageTimerStopped`, `ResetPlayerTimer`
  exist in Studio). The server never takes a price, time, reward or position from a client: prices come from the configs, times from server
  `os.time()`, plot actions are derived from the caller; answers come back on the service's `Result` remote.
- Every admin remote checks `AdminConfig.IsAdmin` on the server (the client check only hides the panel).
- The profile (`PlayerProfiles`, `user_<UserId>`) is read and written only through `PlayerProfile` (never `SetAsync` on it directly).
- Gameplay Coins go through `CoinRewards.Grant` (pet multiplier); purchases, deductions and sales call `PlayerProfile.AddCoins`. Stored Coins
  were scaled ×10 once by the `Version = 3` migration: never multiply stored Coins by hand.
- Stored ids are never renamed or reused: stage keys, challenge coin ids (`<stage folder>_<n>`), aptitude ids, upgrade / tool ids, crop ids,
  field square numbers.
- Every player has the crop field (FA, 2026-11-06; there is no no-field path). A profile from before it converts once on join
  (`GardenField` `convert`: pens → field pet slots, legacy pen fields cleared).

## Localization rules (docs/LOCALIZATION.md → Strings workflow)
- Never set player-visible text as a literal: use `Locale.T(key)` on the client or `Locale.SetKey(label, key, args)` from the server
  (`Locale.SetText` only for texts without words: times, star lines). Names of stages, worlds, medals, talents, eggs, pets, crops go through
  the `Locale` helpers (`Locale.StageName` etc.), never `displayName` / `name` directly; the configs' English fields carry `-- loc: ignore`.
  A Studio-authored label gets the tag `Loc` + attribute `LocKey` (+ `LocArgs` JSON); its script must not write that label's `Text`.
- Strings live only in `localization/strings.csv` (key, context hint, `en`, `cs`, `cs_status`, `cs_en_hash`): a new or changed string gets its
  row with a useful context (where it shows, each `{placeholder}`, Czech grammar notes), English and Czech, `cs_status` = `new`. Never edit
  `src/ReplicatedStorage/Strings/*.luau` (generated).
- Before every commit that touches text: `python tools/loc.py build`, `python tools/loc.py check` (0 errors) and `python tools/loc.py lint`
  (within `tools/loc_lint_baseline.txt`; after converting a file lower its number with `--update-baseline`, never raise it). List the new /
  changed Czech texts in the summary for the user's review.
- Keys are `area.thing.detail`, never renamed once shipped (a rename = new key, old one removed).
- The CSV opens in Excel: UTF-8 with BOM, no `sep=` line; `build` rewrites whatever Excel saved in the canonical form. A text starting with
  `+`, `-`, `=` or `@` is written `\+…`.
- Numbers in texts go through placeholders (`Locale.Number` formats per language); never build "1,500" in code.
- A GUI that stays on screen re-renders on `Locale.Changed`; GUIs built in code set `AutoLocalize = false`. Pet names are user data, never
  localized.
- Czech texts are longer: let lines wrap and grow (`TextWrapped` + `AutomaticSize`) and check `TextFits` in Czech. Stud-brick buttons
  (`StudStyle.Brick`) show their text in an inner `Glyph` label: measure that one. The pseudo-language (Settings row, Studio / admins) finds
  literals (no `[!!`) and cut-off texts.

## Gotchas
- **Argon / sync**
  - Only **one** Argon plugin may be enabled in Studio (the CLI installs `%LOCALAPPDATA%\Roblox\Plugins\Argon.rbxm`; a Creator Store copy must
    stay disabled). Two plugins each create every new file → duplicate scripts.
  - Two-way sync is on: deleting / renaming a synced script **in Studio deletes / renames the file**. Do such changes on disk. Clean up
    Studio-side duplicates only while Argon is disconnected.
  - Initial sync priority is **Client** (Studio overwrites files on connect): commit before connecting and check `git status` right after;
    files edited while disconnected are overwritten by Studio's copy.
  - If a file edit does not show in Studio although Argon is connected, reconnect the plugin (seen in P3b: Studio's copy missed the last edit).
  - **Moving or renaming a script container on disk recreates its Studio instance**: its Studio-only children are lost, a stashed copy of the
    scripted part is deleted too (Argon tracks the instance, not the path), and a renamed checkpoint folder comes back as a default part at the
    origin. Reparent in Studio instead, or note the scripted parts' properties first and rebuild after the move.
  - Adding a script file under a plain Studio instance does not convert it: Argon creates a second empty one. After adding / renaming script
    containers, check Studio for duplicates and lost children.
- **ChoiceStage:** the scripts pick a random child named exactly `Step`; the three `Step` parts per ChoiceStage keep that duplicate name and
  are not synced. Code that moves scene children by name match overwrites the first one with the second: move them without matching.
- **PlayerProfile:** saved on leave, every 60 s and in `BindToClose`; a failed load blocks saving for that session. Writes to one key are
  spaced `MIN_WRITE_GAP` (7 s): `Save` only marks the profile dirty. Don't `require` it from the MCP command context during a playtest (a
  second copy that also saves).
- Studio playtests with API access read / write the **live** DataStores — snapshot and restore anything a test changes (Testing).
- **Fall reset depth:** a stage whose course has a catch or bounce surface, or continues on a platform, far below its last checkpoint needs
  the Studio attribute `FallResetDepth` on its stage folder (QuickRespawnClient's default is 30; the stages that have one: LAYOUT.md → Stage
  anatomy).
- **Moving kit parts must not share a face plane with their frame** (z-fighting): doors / lifts thinner than their frame, doors swing
  (`OpenTurn` + `OpenHinge`) instead of sliding into a lintel, frame walls reach the ground / sea. After building or changing a `KitDoor` run
  `tools/kit_coplanar_audit.luau` via MCP `execute_luau` (Edit) until "clean"; after building a stage, run it with `STATIC_ROOT` set to its
  folder (rules: STAGES.md §2.3.1).
- A finish portal's label is on its Back face: its `LookVector` must point along the approach (last checkpoint → portal); after cloning or
  rotating a course check `portal.CFrame.LookVector:Dot(approach) > 0`.
- Decorations are clones from the Studio-only `ServerStorage.DecorKit` (stud textures are MaterialVariants in `MaterialService.StudPack`,
  looked up by name: keep that folder); placed decor is Anchored with CanTouch / CanQuery off (flowers / grass also CanCollide off).
- Challenge coins pay once per player and are hidden only on that player's client; a new coin needs a new id in `ChallengeCoinConfig` **and**
  the Studio part (tag + `CoinId`) in its stage folder. No Highlights on coins (Roblox renders at most 31 at once).
- Debounces in timer, portal and checkpoint code are per player; kill scripts key a script-global `h` by the touching part. The timer uses
  `os.clock()`; times are floored to tenths (`TimeFormat.Tenths`) before storing.
- A ScreenGui built in code gets `ZIndexBehavior = Sibling` (with Global its children drew under later pages / pickers).
- Legacy APIs are common (`wait`, `spawn`, `:connect`, `findFirstChild`); prefer `task.*` and `Players:GetPlayerFromCharacter` in new code,
  but don't mass-rewrite without asking.

## Testing
No automated tests. Validate by risk; scope acceptance checks to the tier a change needs, not more:
- **Always:** grep for leftovers of what changed; the tool checks that apply (`economy.py check`, `loc.py check` / `lint`, a smoke run of
  any tool command a change touches); one playtest boot (MCP `start_stop_play`) reading server and client errors / warnings.
- **UI or input changed:** each changed control through the real UI at least once (firing remotes alone once missed a broken button).
  A pure removal only needs a look at the affected screens.
- **Stored data migrated or rewritten:** first read the live profiles (one playtest, read-only). Test the path with a fixture
  (snapshot / restore below) only if a live profile actually needs it; otherwise review the path in code and say so.
- **Never skipped:** a snapshot right before any write to a live profile.

**Keep tool output small** (it all stays in the context):
- Console: not `get_console_output` (it returns the whole log). Use `execute_luau` (`Server` / `Client` during a playtest, `Edit` otherwise):
  `game:GetService("LogService"):GetLogHistory()`, keep entries matching a pattern (`"%[Telemetry%]"`, `"error"`, your own prefix) or after the
  test's start, last ~30, each cut to ~200 chars.
- Big files (PetLook, ObstacleKit, PetsPanel, PetDetail, Telemetry, FoodShopClient, FieldClient, GardenField,
  StageConfig, IncubatorClient: 17-50 kB): Grep for the function / text, then Read with `offset` / `limit`.
- `python tools/loc.py check` prints errors and a summary; `loc.py review` lists the waiting texts.

**Studio MCP habits:**
- A **minimized Studio window renders no 3D**: check `IsIconic` on the `RobloxStudioBeta` window and restore it with `ShowWindow(handle, 4)`
  from PowerShell before capturing.
- `screen_capture` **one call at a time**, ~1.5 s apart (parallel captures time out, then captures come back white until Studio restarts and
  the instance id changes). A capture with a camera position leaves the Edit camera `Scriptable`: set
  `workspace.CurrentCamera.CameraType = Enum.CameraType.Fixed` afterwards. `BillboardGui`s with `AlwaysOnTop` don't show in captures (check
  them by properties).
- Never leave a playtest running (`start_stop_play` false at the end; `Edit` calls fail in Play mode). Check `get_studio_state` for a
  playtest you did not start before stopping anything (ask the user). A character may not be loaded right after start (wait for
  `HumanoidRootPart`).
- Bots: a `MoveTo` bot cannot walk on a kit mover (use `Humanoid:Move`); a jump-reach bot holds forward with `Humanoid:Move` every frame
  through the landing; teleporting into a coin or trigger is flaky (walk onto it). A stage finish can be driven by moving the character
  through the gate's `TimerStart` and then the finish portal. Scroll a list row into view before clicking it (an off-screen row's click
  lands on what lies under it).
- Never `require` a client module that starts itself (GardenView, PetClient …) from the MCP `Client` context: it runs a second copy
  (a second Workspace.GardenView with every plot drawn twice). Read their drawn instances or GUIs instead.
- `require` in the **Edit** context caches a ModuleScript across calls (may return the old version after a disk change): check `.Source`, or
  test in a playtest.

**Live DataStore snapshot / restore:**
- Right before **every** fixture write, copy the profile as it is now (`PlayerProfiles` `user_<id>`, plus its `MostStars` value) into
  `TestSnapshots` under a new key (`profile_<id>_<milestone>_<n>`); never restore an older snapshot (the user plays between tests). Restore
  after the playtest has stopped and remove the test's entries from `GlobalLeaderboardsStore`.
- If Edit-mode DataStore calls fail ("Access forbidden"), write from the playtest `Server` context after PlayerProfile's shutdown save:
  `game:BindToClose(function() task.wait(9); store:SetAsync(key, value) end)` (value built beforehand), stop the playtest, wait ~15 s before
  the next one, and check the write there before the profile is saved again. Don't kick the player (it ends the playtest and its dialog
  blocks the MCP).
- `GetAsync` returns two values: assign to a local before passing to `SetAsync` (else "Unable to cast Instance to Array").
- Accounts: `Lekzdrh` (9892673032, the developer in Studio), `AhojRupert` (769364524, another admin).

**Multi-client:** the user starts Test → **Server and Clients** (F7), then **Add Clients**. `list_roblox_studios` shows one instance per client
plus the server; `get_studio_state` tells them apart. Test users have UserIds −1, −2… and create `PlayerProfiles` records `user_-1`, `user_-2`:
remove them afterwards. Studio does not filter text (`TextService`): filter results need a live test.
