# Oby sandbox — agent guide

Roblox obby (obstacle course): a central hub island with portals to timed stages, checkpoints,
per-stage Top-10 leaderboards, collectible coins and a small admin panel.

- Place: **"Oby sandbox"**, placeId `83181838162651` (pinned in `Oby.project.json` → `placeIds`).
- Code is synced to this repo with **Argon** (Rojo-compatible); the **scene lives only in the place file**.
- Language: Luau, legacy run context (`.server.luau` = Script, `.client.luau` = LocalScript, `.luau` = ModuleScript).

## Project docs & workflow
- [docs/LAYOUT.md](docs/LAYOUT.md) — what every script and scene folder holds, stage anatomy, copied-script table. Grep it on demand; update it when a script is added or changes its job.
- [docs/GDD.md](docs/GDD.md) — game design: loop, stages, time tiers, rewards, talents, economy numbers.
- [docs/ROADMAP.md](docs/ROADMAP.md) — milestones, acceptance checks, status. Answer "what next?" from here.
- [docs/PET_GROWTH.md](docs/PET_GROWTH.md) — design and plan for the pet growth visuals (P1e1–P1f).
- [docs/STYLE_PREVIEW.md](docs/STYLE_PREVIEW.md) — parked voxel / pixel-art style previews (Studio-only `ServerStorage.StylePreview`), decision pending.
- [docs/TELEMETRY.md](docs/TELEMETRY.md) — telemetry design (T1a / T1b): AnalyticsService events for run funnels, fails per segment / cause, quits and returns, skills; how to read them on the Creator Dashboard. T1a (core) and T1b (skills) implemented.
- [docs/LOCALIZATION.md](docs/LOCALIZATION.md) — localization design (L1–L4): English + Czech, `Locale.T`, string tables, `LocKey` for server texts, language row in Settings. L1 (infrastructure + HUD) implemented; L2 (client panels) and L3 (server + Studio texts) implemented.
- [docs/STAGES.md](docs/STAGES.md) — stage expansion to ≈ 20 stages: obstacle component catalogue, combination patterns, difficulty curve, special / bonus stages, talent gating, worlds / hub layout, proposed S milestones.

Work milestone by milestone per ROADMAP (design check → implement → Studio validation → status update → commit);
update the status levels (Implemented / Studio-validated / Live-validated) only after validation.

## How code gets here (read before editing)

Argon runs in **Only Code Mode**: `src/` contains every script **plus the instances that contain scripts**
(as folders with `init.meta.json` holding only `className`; no properties). Parts, GUI layout,
RemoteEvents, Sounds, lighting etc. exist **only in Studio**.

Consequences:
- Do not "clean up" folders like `src/Workspace/World1/Stage5/Part_01/` — that folder *is* the kill part that owns the script.
- Changing a part's size/color/position, GUI layout, or adding a RemoteEvent must be done in Studio
  (manually or via the Roblox Studio MCP), not in files.
- Never run `argon build` to produce the real place — it would contain only scripts and default parts.
- Safety nets that must stay on: `$keepUnknowns: true` on every service in `Oby.project.json` and
  the plugin's **Keep Unknowns** setting. Without them a Server-priority sync deletes the scene.
- Sibling names must be unique (Argon drops duplicates on syncback). New parts that get a script
  need unique names (`Part_11`, `KillPart_3`, …). Exception: ChoiceStage `Step` parts — see Gotchas.
- `sourcemap.json` and `*.rbxl` are git-ignored.

Roblox Studio MCP is available for inspecting/editing the live place (`search_game_tree`,
`execute_luau`, `script_read`, `screen_capture`, playtests). Studio must be in **Edit** mode for
`datamodel_type: "Edit"`.

## Layout

Per-file and per-scene-folder descriptions, the stage anatomy table and the copied-script table live in
[docs/LAYOUT.md](docs/LAYOUT.md): grep it (or the file itself) when you need one; don't read it whole.

```
src/ReplicatedStorage/        shared modules: configs (Stage / Pet / Garden / Talent / ChallengeCoin / Arena / Admin),
                              Locale + generated Strings/, KitMath, StudStyle, PetLook, TimeFormat, MedalText
src/ServerScriptService/      services: PlayerProfile (DataStore), CoinRewards, StageResults, StageUnlocks, PetService,
                              Garden*, RespawnService, TalentService, Telemetry, LanguageService, admin remotes
src/StarterPlayer/StarterPlayerScripts/  client: obstacle kit (ObstacleKit, KitZones, KitMaze, KitGhosts), StageCamera,
                              checkpoints, gates / portals, pets (PetClient, PetFollow, PetsPanel), garden panels, settings
src/StarterGui/               CoinGui, ScreenGui (TopLeftIcons/ButtonHandler, SkillsPanel, AdminPanel)
src/Workspace/Handlers/       CheckpointTouchHandler, PlayerTimerHandler (required by every stage script)
src/Workspace/                StartLocation (hub), Tutorial, World1 (Stage1-5), World2 (Stage6-10), World3 (Stage11-12), KeyArena, Garden,
                              DebugBaseplate (the sea kill brick); scene content of these is Studio-only
```

### Stages
- World stages live in `Workspace.World<n>.Stage<k>`: `Gate` (TimerStart, Door, GateExit, GateSign), `Top10Leaderboard`,
  `Arrival`, checkpoints `<number>/C`, finish `TeleportBackToStageStart/Portal`, obstacles. A new stage takes the next
  free block of 100 checkpoint numbers. Table with every child's behaviour: docs/LAYOUT.md → Stage anatomy.
- Most scripts are byte-identical copies (checkpoints, kill parts, TimerStart, GateExit, finish portals, boards…):
  edit all copies consistently (grep by content or md5) and the `ServerStorage.StageKit` template copies too.
  Counts and examples: docs/LAYOUT.md → Reusable script variants.

**Adding a world stage:** clone the Studio-only templates `ServerStorage.StageKit.Gate` (door gate with its scripts), `StageKit.Top10Leaderboard` and `StageKit.Arrival` into the new stage folder, `PivotTo` / rotate them as a group onto a free gate position of the courtyard wall (the templates are laid out for a course running north from the gate line at z 187; the first checkpoint plate sits 7 studs behind the gate line), then add the `StageConfig` entry. Checkpoints: clone `ServerStorage.StageKit.Checkpoint` (plate + `Core` + `Beam` + the C Script; pivot = centre of the plate's top), rename it to the next free number and put its upstream edge against the previous obstacle, its front (LookVector, -Z) pointing along the course (the respawn faces that way). Scripts resolve the stage from the folder, so nothing else needs editing;
**Argon does not write the script files of instances created through the Studio MCP** (clones, `execute_luau`; changes to a synced script's `Source` made that way do not reach the disk either). For a new stage, copy the script directories from an existing stage on disk (`Gate`, `Top10Leaderboard`, `TeleportBackToStageStart`, one `<number>` per checkpoint; a plain directory is a Folder, the `init.meta.json` files hold the class), keep the old Studio folder, let Argon create the bare scripted instances from the copied files, then move the Studio-only children and the scripted parts' properties from the old folder into them (match by name; **children with duplicate names, like the three `Step` parts of a ChoiceStage, must be moved without matching** — a name match overwrites the first one), check that the descendant counts agree, and only then delete the old directories on disk (S4.1, S4.2 and the 2026-10-22 renaming did this). The templates' scripts are copies: when a stage script changes, change the template's copy too.

Stage scripts never hard-code a stage: they call `StageConfig.ForInstance(script)` (stage = the Workspace folder they
live in) or `StageConfig.ByHubPortal[...]`, so all copies of TimerStart, finish portal, TeleportToSpawn, hub portal and
Top10Leaderboard are byte-identical. Stage keys (`"Stage1"`…`"Stage5"`, `"Tutorial"`; equal to the stage's `folder` and position) are DataStore keys
and must never change. Hub label is `StageConfig.HubName` (`"Central Island"`).

## Networking & persistence

RemoteEvents (in `ReplicatedStorage`; first three exist only in Studio, not in files):

| Remote | Direction | Purpose |
|---|---|---|
| `StageTimerUpdate` | server → client | `(elapsed ≥ 0, stageKey)` run active; `(-1, final, result)` finished; `(-1)` cancelled |
| `StageTimerStopped` | — | unused since M0 (was the stop ack); can be deleted in Studio |
| `ResetPlayerTimer` | client → server | admin panel "Reset Score": full reset of the caller's own progress; server checks `AdminConfig` |
| `AdminAddCoins` | client → server, no arguments | admin panel "+Coins": server checks `AdminConfig`, credits `AdminConfig.AddCoinsAmount` to the caller; created at runtime by `AdminCoinsServer` |
| `CoinUpdateEvent` | server → client | created at runtime by `CoinSystem` |
| `CheckpointReached` | server → client `(part, first)` | created at runtime by `CheckpointTouchHandler`; the player's respawn point moved to that checkpoint (the stage's `TimerStart` counts as its first checkpoint) → `CheckpointClient` lights that pad and turns the previous one back, for that player only; `first` (first reach in the run) also plays the sound |
| `CheckpointsReset` | server → client, no arguments | created at runtime by `CheckpointTouchHandler`; a new run started (`NewRun`) → `CheckpointClient` turns every pad back |
| `GoHome` | client → server, no arguments | Home button; created at runtime by `HomeService`, 3 s cooldown, server teleports + cancels the timer |
| `GoGarden` | client → server, no arguments | Pets panel "Go to my garden"; created at runtime by `HomeService` (shares GoHome's cooldown), server teleports in front of the caller's plot (`GardenPlots.PlotOf`) facing it + cancels the timer |
| `LanguageRemotes.Set` | client → server `(code)`: `""` = automatic, else a `Locale.Supported` code | created at runtime by `LanguageService`; stored in the profile, mirrored to the attributes `LanguageSetting` / `Language` |
| `TelemetryRemotes.Report` | client → server `("platform", kind)` / `("kill", part)` / `("fall")` | created at runtime by `Telemetry`; telemetry only, never trusted for gameplay; kill / fall rate-limited to 1 per s, the part must lie in a stage folder |
| `TalentRemotes.Buy` / `.Result` | client → server `(talentId, expectedLevel)` / server → client `(talentId, ok, level or reason)` | created at runtime by `TalentService`; the price is never sent |
| `UnlockRemotes.Buy` / `.Result` / `.Locked` | client → server `(stageKey)` / server → client `(stageKey, ok, reason?)` / server → client `(stageKey)` | created at runtime by `StageUnlocks`; price from `StageConfig.unlockPrice`; `Locked` is unused since the unlock popup was replaced by gate prompts (S4 tuning) |
| `PetRemotes.Equip` / `.Unequip` / `.BuySlot` / `.SellPet` / `.RequestState` | client → server `(uid)` / `(uid)` / `(expectedSlot)` / `(uid)` / no arguments | created at runtime by `PetService`; `RequestState` only re-sends `PetsChanged` (a client that was still loading misses the join publish); uids are strings; prices and sell values are server-side. No egg remote here: eggs hatch only in the garden (`GardenRemotes.StartEgg`) |
| `PetRemotes.PetsChanged` / `.Result` | server → client `({ pets, equipped, slots, freeEggs, multiplier })` / `(action, ok, detail or reason)` | state after load and every change; per-request answer (hatch result, sale value, reject reason) |
| `GardenRemotes.Place` / `.Remove` / `.BuyPen` / `.RequestState` | client → server `(penIndex, uid)` / `(penIndex)` / `(expectedPen)` / no arguments | created at runtime by `GardenService`; the plot is derived from the caller (must stand within 45 studs of it); prices from `GardenConfig.PenPrices`; no remote carries a time |
| `GardenRemotes.StartEgg` / `.Hatch` / `.BuyIncubator` / `.Feed` | client → server `(incubator, eggId)` / `(incubator)` / `(expectedIncubator)` / `(uid, foodId)` | created at runtime by `GardenIncubators` / `GardenFood`; prices from `PetConfig.Eggs` / `GardenConfig.IncubatorPrices` / `GardenConfig.Foods`; hatch time checked against server `os.time()`; answers on `GardenRemotes.Result` |
| `GardenRemotes.State` / `.Result` / `.Payout` | server → client `({ pens, penCount, rate, incubators = { count, eggs = { ["n"] = { egg, readyAt } } } })` / `(action, ok, detail or reason)` / `({ id, seconds, base, paid, capped, away })` | `away = true` is the join payout (popup, re-sent on `RequestState`, shown once per `id`), otherwise a toast |

DataStores:

| Store | Key | Value |
|---|---|---|
| `PlayerProfiles` | `user_<UserId>` | `{ Version = 3, Coins, BestTimes[stageKey], Medals, UnlockedStages, CollectedCoins, Talents, RunsToday, Pets[uid] = { Kind, Level, XP }, EquippedPets, PetSlots, NextPetUid, FreeEggs[eggId], LaunchEgg, Garden = { Pens["1".."6"] = uid, PenCount, LastSeen = server os.time, Carry, Incubators["1".."3"] = { Egg, StartedAt, ReadyAt }, IncubatorCount }, LastQuit = { Stage, Segment, At } (telemetry, cleared on join), Language ("" = automatic, "en", "cs") }` |
| `PlayerCoins` | `UserId` | legacy integer coins — read once for migration |
| `PlayerScoresStore` | `player_<UserId>` | legacy `{ {StageName, Elapsed}, … }` — read once for migration |
| `GlobalLeaderboardsStore` | `leaderboard_<StageName>` | Top-10 `{ {PlayerName, Elapsed, UserId?}, … }` (UserId missing on entries from before the avatar boards) |
| ordered `MostStars` | `<UserId>` | total stars (sum of the profile's medals, `StageConfig.TotalStars`); no entry = 0; hub board |
| ordered `"a"` | — | legacy time-played board; `TopTimeScript` is **Disabled** |

Gameplay Coins (medals, repeat rewards, pickups, future sources) go through `CoinRewards.Grant`; purchases and
deductions (and pet sales) call `PlayerProfile.AddCoins` directly. The multiplier is `PetService.Multiplier`
(1 + equipped pets' bonus, capped at +50 %). All Coin amounts were scaled ×10 in R2: records below `Version = 3` (and legacy
`PlayerCoins`) get `Coins × 10` once on load — never multiply stored Coins by hand. `RunsToday = { Day = <UTC day>, [stageKey] = medal finishes }` drives
the diminishing repeat reward (`StageConfig.RunReward`).

Player attributes `Medal_<stage folder>` (0–3) mirror `PlayerProfile.Medals` for client displays; `Unlocked_<stage folder>`
(bool) mirror `StageUnlocks` (bar met or `UnlockedStages[key]` bought; the bar is derived from medals, never stored).
`EquippedPets` (`"Kind:Level:uid,…"`, empty when none; `PetConfig.DecodeEquipped` also reads the old `Kind:Level` form) mirrors the equipped pets; `PetFollow` renders them on every client.
`Garden.LastSeen` is the server time up to which pen production was paid (never from a client); production since then is capped at 8 h.
A pet is either equipped or penned: `PetService` rejects Equip / SellPet of a penned pet, `GardenService` rejects Place of an equipped one.
Player attribute `GardenPlot` = index of the borrowed plot; pen models carry attributes `State` / `Uid` / `Kind` / `Level` (tests, client);
incubator models carry `State` (`free` / `locked` / `empty` / `egg`) / `Egg` / `ReadyAt` (server time; clients only display the countdown).
Incubator eggs are stored with server `os.time()` only and checked at `Hatch`; to test hatching without waiting, move `StartedAt` / `ReadyAt`
back in the stored profile between playtests (snapshot and restore it).
`CollectedCoins` (sorted ids, comma-separated, `""` when none) mirrors `PlayerProfile.CollectedCoins[id] = true`;
`ChallengeCoinsClient` hides those coins for that player only (the server never hides a coin).

Checkpoint respawn state is kept in `ServerStorage.CheckpointData.<UserId>` (ObjectValue, runtime only).

## Localization rules (L1 / L1.1, docs/LOCALIZATION.md → Strings workflow)
- Never set player-visible text as a literal: use `Locale.T(key)` on the client or `Locale.SetKey(label, key, args)` from
  the server (`Locale.SetText` only for texts without words: times, star lines). Names of stages, worlds, medals, talents
  and eggs go through `Locale.StageName` etc., never `displayName` / `name` directly. A Studio-authored label gets the tag `Loc` + attribute `LocKey` (+ `LocArgs` JSON) in the place file;
  its script must not write the same label's `Text` afterwards.
- Strings live only in `localization/strings.csv` (key, context hint, `en`, `cs`, `cs_status`, `cs_en_hash`): a new or
  changed string gets its row with a useful context (where it shows, what each `{placeholder}` holds, Czech grammar
  notes), English and Czech, `cs_status` = `new`. Never edit `src/ReplicatedStorage/Strings/*.luau` (generated).
- Before every commit that touches text: `python tools/loc.py build`, `python tools/loc.py check` (0 errors) and
  `python tools/loc.py lint` (within `tools/loc_lint_baseline.txt`; after converting a file lower its number with
  `--update-baseline`, never raise it). List the new / changed Czech texts in the summary for the user's review.
- Keys are `area.thing.detail`, never renamed once shipped (a rename = new key, old one removed).
- The CSV opens in Excel: keep it UTF-8 with BOM and without a `sep=` line (Excel would garble the Czech letters);
  `build` rewrites whatever Excel saved (also semicolons) in the canonical form.
- Test in the pseudo-language (Settings row, Studio / admins): unbracketed text is a literal, cut-off text is too long.
  A script can do the search: every visible TextLabel / TextButton whose text has letters but no `[!!`. Stud-brick
  buttons (StudStyle.Brick) show their text in an inner `Glyph` label: measure that one (`TextFits`), not the button.
- Numbers in texts go through placeholders (formatted per language by `Locale.Number`); never build "1,500" in code.
  A text starting with `+`, `-`, `=` or `@` is written `\+…` in the CSV (Excel would read a formula; `check` reports it).
- Names held as data (pet kinds, rarities, foods, talent effects, stages, worlds, medals, eggs) are shown through the
  `Locale` helpers; the configs' English fields are the fallback and carry `-- loc: ignore`.
- A GUI that stays on screen re-renders on `Locale.Changed`; GUIs built in code set `AutoLocalize = false`.
- Czech texts are longer: let lines wrap and grow (`TextWrapped` + `AutomaticSize`) and check `TextFits` in Czech.

## Gotchas
- **ChoiceStage** scripts pick a random child and require `p.Name == "Step"`; the three `Step` parts
  per ChoiceStage must keep that exact (duplicate) name. They are not synced (no code inside).
- `PlayerProfile` is saved on leave, every 60 s and in `BindToClose`; a failed load blocks saving for that session.
  Don't `require` it from the MCP command context during a playtest: that creates a second copy that also saves.
- Only **one** Argon plugin may be enabled in Studio (the CLI installs `%LOCALAPPDATA%\Roblox\Plugins\Argon.rbxm`;
  a Creator Store copy must stay disabled). Two plugins each create every new file → duplicate scripts.
- Two-way sync is on: deleting/renaming a synced script **in Studio deletes/renames the file**. Do such changes on disk.
  Clean up Studio-side duplicates only while Argon is disconnected.
- Initial sync priority is **Client** (Studio overwrites files on connect): commit before connecting and check
  `git status` right after; files edited while disconnected are overwritten by Studio's copy.
- `Workspace.World1.Stage4` carries the Studio-only attribute `FallResetDepth = 70` (QuickRespawnClient's default is 30): the bounce bricks of Level 12 lie 46-61 studs below the plates, a smaller depth resets the player before they reach them. `Workspace.World3.Stage11` carries `FallResetDepth = 75` (S8.1: its descent ends 65 studs below checkpoint `905`; at 30 the jump to `D4` was reset). Set the attribute on a stage folder whenever a course has a catch or bounce surface, or a platform it continues on, far below its last checkpoint.
- Studio playtests with API access read/write the **live** DataStores — snapshot and restore anything a test changes.
- `CheckpointTouchHandler`'s `Sound`/`Orig` children exist only in Studio (`CheckpointClient` clones `Sound` on the client).
- Checkpoint `Core` / `Beam` are authored in the "not reached" look; `CheckpointClient` reads that look once per pad and tweens to and
  from it, so restyle them in Studio in that state.
- Argon does not turn an existing plain Studio instance into a synced folder when a script file is added under it
  (it made a second empty `HomePanel`). Renaming such a folder on disk replaces the Studio instance with a bare Frame (styled
  children lost, rebuilt by hand). After adding/renaming script containers, check Studio for duplicates / lost children.
- **Moving a script container on disk recreates its Studio instance, drops its Studio-only children and also deletes a copy of the scripted part that was stashed elsewhere in Studio** (Argon tracks the instance, not the path): stash only Studio-only parts (they survive) and note the scripted parts' properties first.
- **Moving a script container on disk recreates its Studio instance and drops its Studio-only children** (S4.0: `git mv` of
  `TeleportToStage1..3` into `World1/` deleted their `Arch` / `Portal`; rebuilt from the Tutorial portal). Reparent in Studio,
  keep a copy of the Studio-only children, and rebuild after the disk move.
- `Workspace/World1/Stage5/level.2` is a Model literally named `level.2` (dot in the name). Its checkpoint `level.2/26` (the plate between the four jump plates of `level.1` and the wrap-around floor, 11 studs from the last plate) was renamed from `21` on disk in S1.1; Argon recreated it as a default part at the origin and the 23-stud gap made Stage 5 impossible until it was rebuilt on 2026-10-22 (plate 16 x 1 x 12 at z 80.1, the Core / Beam copied from `Stage5/21`). Never rename a checkpoint folder on disk without redoing its Studio parts.
- Decorations (H1) are clones from the Studio-only library `ServerStorage.DecorKit` (the "Stud pack V1" models: Tree1,
  Tree2, Flowers, Grass1/2, Rock, Bush, Wall, Shop, Leaderboard frame used for signs, StudPortal = template of the hub portal arches). Their stud textures are
  MaterialVariants in `MaterialService.StudPack` (`Studs`, `Inlets`, `Universal`…), looked up by name: keep that folder.
  Placed decor is Anchored with CanTouch / CanQuery off (flowers / grass also CanCollide off).
- Debounces in timer, portal and checkpoint code are per player. Kill scripts keep a script-global `h` keyed by the
  touching part (effectively per player).
- Timer uses `os.clock()`; times are floored to tenths (`TimeFormat.Tenths`) before storing.
- Challenge coins pay once per player and are hidden only on that player's client. Coin ids (`<stage folder>_<n>`) are
  stored in profiles: never rename or reuse one; a new coin needs a new id in `ChallengeCoinConfig` **and** the Studio
  part (tag + `CoinId`) inside its stage folder. Coins have no Highlight (removed in M4.1: Roblox renders at most 31 at once and 29 coins would use nearly all).
- Admins are listed once in `ReplicatedStorage.AdminConfig`; every admin remote must check `AdminConfig.IsAdmin`
  on the server (the client check only hides the panel). The RunSpeed/DoubleJump toggles are client-side debug tools.
- A finish portal's label is on its Back face: its `LookVector` must point along the approach (last checkpoint -> portal).
  After cloning or rotating a course check `portal.CFrame.LookVector:Dot(approach) > 0`.
- The Tutorial keeps its old-style `LandingPad` (floor, `StartGate`, `TimerStart`, return portal); the world stages have no landing pad since S4.0.
- **ChoiceStage duplicates when moving scene parts:** the three `Step` parts of a ChoiceStage share one name; code that matches children by name (the "graft" of Studio-only parts into freshly synced script containers) overwrites the first one with the second. Move such children without matching.
- Legacy APIs are common (`wait`, `spawn`, `:connect`, `findFirstChild`); prefer `task.*` and
  `Players:GetPlayerFromCharacter` in new code, but don't mass-rewrite without asking.

## Testing
No automated tests. Verify in Studio: playtest (MCP `start_stop_play`), read the console (below),
and check DataStore behaviour only with Studio API access enabled.

Keep tool output small (it all stays in the context):
- **Console:** `get_console_output` returns the whole log on every call. Read only what you need through `execute_luau`
  (`Server` / `Client` during a playtest, `Edit` otherwise) and return the filtered tail:
  `local h = game:GetService("LogService"):GetLogHistory()` then keep entries whose `message` matches a pattern
  (`"%[Telemetry%]"`, `"error"`, your own `print` prefix) or whose `timestamp` is after the test started, last ~30,
  each cut to ~200 chars. Use `get_console_output` only when you don't know what to look for.
- **Big files** (PetLook, ObstacleKit, PetsPanel, Telemetry, FoodShopClient, GardenClient, GardenService, StageConfig,
  IncubatorClient: 17-50 kB): Grep for the function / text first, then Read with `offset` / `limit` around it.
  Read a file whole only when changing most of it.
- `python tools/loc.py check` prints errors, a per-language count of texts waiting for review and a summary line;
  `loc.py review` lists the waiting texts when you actually review them.
Studio MCP habits that cost time: `screen_capture` must run **one call at a time** (never two in one message) with a short pause between (about 1.5 s): parallel captures time out, after which captures come back white (3D not rendered) until Studio is restarted, and the MCP can lose the Studio instance (diagnosed 2026-10-23; sequential captures worked every time; after a restart the instance id changes); do not leave a playtest running (`start_stop_play` false at the end of every test, `Edit` calls fail in Play mode); a `MoveTo` bot cannot walk on a kit mover (use `Humanoid:Move`); teleporting a character into a coin or trigger is flaky (walk onto it); a character may not be loaded right after `start_stop_play` (wait for `HumanoidRootPart`). Snapshot and restore recipe for the live DataStores: copy `PlayerProfiles` `user_<id>` into `TestSnapshots` (`profile_<id>`, plus the `MostStars` value) before a test, write it back after the playtest has stopped (the profile is saved again on shutdown), and remove the test's entries from `GlobalLeaderboardsStore`. Accounts: `Lekzdrh` (9892673032, the developer in Studio) and `AhojRupert` (769364524, another admin account).
`require` in the MCP `execute_luau` **Edit** context caches a ModuleScript across calls: after the module changed on disk
(Argon) it may still return the old version (2026-10-24: `Locale` after L1.1). Check `.Source` in Studio, or test in a
playtest (modules load fresh there).
MCP `screen_capture` with a camera position leaves the Edit camera on `Scriptable`: when done, set it back with
`workspace.CurrentCamera.CameraType = Enum.CameraType.Fixed` (Edit) so the user can move the viewport again.

Multi-client: the user starts Test → Start Test Session → **Server and Clients** (F7), then Test → **Add Clients**.
`list_roblox_studios` then shows one extra instance per client and one for the server (unnamed);
`get_studio_state` tells them apart by the focused DataModel. Test users have UserIds −1, −2… and create
`PlayerProfiles` records `user_-1`, `user_-2` — remove them afterwards.
