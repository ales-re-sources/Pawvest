# Oby sandbox — agent guide

Roblox obby (obstacle course): a central hub island with portals to timed stages, checkpoints,
per-stage Top-10 leaderboards, collectible coins and a small admin panel.

- Place: **"Oby sandbox"**, placeId `83181838162651` (pinned in `Oby.project.json` → `placeIds`).
- Code is synced to this repo with **Argon** (Rojo-compatible); the **scene lives only in the place file**.
- Language: Luau, legacy run context (`.server.luau` = Script, `.client.luau` = LocalScript, `.luau` = ModuleScript).

## Project docs & workflow
- [docs/GDD.md](docs/GDD.md) — game design: loop, stages, time tiers, rewards, talents, economy numbers.
- [docs/ROADMAP.md](docs/ROADMAP.md) — milestones, acceptance checks, status. Answer "what next?" from here.

Work milestone by milestone per ROADMAP (design check → implement → Studio validation → status update → commit);
update the status levels (Implemented / Studio-validated / Live-validated) only after validation.

## How code gets here (read before editing)

Argon runs in **Only Code Mode**: `src/` contains every script **plus the instances that contain scripts**
(as folders with `init.meta.json` holding only `className`; no properties). Parts, GUI layout,
RemoteEvents, Sounds, lighting etc. exist **only in Studio**.

Consequences:
- Do not "clean up" folders like `src/Workspace/Stage3/Part_01/` — that folder *is* the kill part that owns the script.
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

```
src/
  ReplicatedStorage/
    StageConfig.luau                  stage list (key, display name, folder, hub portal, T_base, tiers, unlock, reward factor)
    TimeFormat.luau                   tenths rounding + "mm:ss.t" formatting
  ServerScriptService/
    PlayerProfile.luau                per-player profile DataStore (load/migrate/save), AddCoins, CoinsChanged
    CoinSystem.server.luau            leaderstats (Stage, Coins) mirrored from profile, coin pickup, CoinUpdateEvent
    ResetPlayerTimerServer.server.luau  handles ResetPlayerTimer remote → wipe player's best times
  StarterPlayer/StarterPlayerScripts/
    StageTimerClientUpdater.client.luau  StageTimer label: counts locally between start/stop from StageTimerUpdate
  StarterGui/
    CoinGui/CoinDisplayScript.client.luau        top-right coin counter
    ScreenGui/TopLeftIcons/ButtonHandler.client.luau  Home/Settings/Admin buttons, slide-in panels, ADMIN_USERS
    ScreenGui/AdminPanel/...                      RunSpeed (16↔64), DoubleJump (up to 5 air jumps), ScoreReset
  Workspace/
    Handlers/                         ModuleScripts shared by all stage scripts (required via workspace.Handlers.*)
      CheckpointTouchHandler.luau     checkpoint touch → leaderstats.Stage, respawn point, sound
      PlayerTimerHandler.luau         stage timers (os.clock), personal bests (profile), global Top-10, score panel
    StartLocation/                    hub: SpawnLocation + TeleportToStage1..3 portals
    Stage1/ Stage2/ Stage3/ Tutorial/ stages (see below)
    DebugBaseplate/                   kill brick under the map
```

### Stage anatomy
Every stage folder follows the same pattern:

| Child | Script behaviour |
|---|---|
| `LandingPad/TeleportDestination` | arrival point from the hub portal |
| `LandingPad/TimerStart` | starts the timer unless one already runs on this stage + acts as checkpoint |
| `LandingPad/TeleportToSpawn/Portal` | back to hub; cancels timer, score panel → hub |
| `LandingPad/Top10Leaderboard` | SurfaceGui board from `LoadGlobalLeaderboard(stage.key)` (Stage1, Stage2 only) |
| `<number>/C` | checkpoint part (`1`–`9` Stage1, `10`–`14` Stage2, `20`–`22` Stage3, `23`–`24` Tutorial) |
| `TeleportBackToStageStart/Portal` | finish line: `StopTimer` → save best time; sibling script teleports to stage start |
| obstacle models | kill parts, spinners, lava, bounce bricks, choice stage |

Stage scripts never hard-code a stage: they call `StageConfig.ForInstance(script)` (stage = the Workspace folder they
live in) or `StageConfig.ByHubPortal[...]`, so all copies of TimerStart, finish portal, TeleportToSpawn, hub portal and
Top10Leaderboard are byte-identical. Stage keys (`"Stage 1"`…`"Stage 3"`, Tutorial `"Stage 4"`) are DataStore keys
and must never change. Hub label is `StageConfig.HubName` (`"Central Island"`).

## Reusable script variants (copy-pasted, not modules)

Most of the 98 scripts are identical copies. Edit them consistently (grep by content or md5):

| Count | Variant | Example |
|---|---|---|
| 20 | checkpoint → `CheckpointTouchHandler.OnTouched` | `Workspace/Stage1/1/C/Script.server.luau` |
| 16 | kill on touch (`Humanoid.Health = 0`) | `Workspace/Stage3/Part_01/Script.server.luau` |
| 10 | kill player on touch (debounced by `hit`) | `Workspace/Stage1/LaserStripStage/Part_01/…` |
| 8 | spinner (`CFrame * Angles` in `while wait()`) | `Workspace/Stage1/SpinnerStage_1/Part_2/Script_1…` |
| 4 | `TimerStart` | `Workspace/Stage*/LandingPad/TimerStart/…` |
| 4 | `TeleportToSpawn` | `Workspace/Stage*/LandingPad/TeleportToSpawn/…` |
| 4+4 | finish portal / teleport back to stage start (Stage1 teleport copy differs slightly) | `Workspace/Stage*/TeleportBackToStageStart/…` |
| 3 | hub portal `TeleportToStageN` | `Workspace/StartLocation/TeleportToStage*/…` |
| 2 | Top10Leaderboard | `Workspace/Stage1/LandingPad/Top10Leaderboard/Script…` |
| 3 | ChoiceStage random safe `Step` | `Workspace/Stage1/ChoiceStage_*/Script…` |
| 3 | bounce brick (Heartbeat velocity) | `Workspace/Stage2/12/Level 12/Bounce Brick_*` |

## Networking & persistence

RemoteEvents (in `ReplicatedStorage`; first three exist only in Studio, not in files):

| Remote | Direction | Purpose |
|---|---|---|
| `StageTimerUpdate` | server → client | `(elapsed ≥ 0)` run active; `(-1, final)` finished; `(-1)` cancelled |
| `StageTimerStopped` | — | unused since M0 (was the stop ack); can be deleted in Studio |
| `ResetPlayerTimer` | client → server | admin panel "reset score" (no server-side admin check) |
| `CoinUpdateEvent` | server → client | created at runtime by `CoinSystem` |

DataStores:

| Store | Key | Value |
|---|---|---|
| `PlayerProfiles` | `user_<UserId>` | `{ Version, Coins, BestTimes[stageKey], Medals, UnlockedStages, CollectedCoins, Talents }` |
| `PlayerCoins` | `UserId` | legacy integer coins — read once for migration |
| `PlayerScoresStore` | `player_<UserId>` | legacy `{ {StageName, Elapsed}, … }` — read once for migration |
| `GlobalLeaderboardsStore` | `leaderboard_<StageName>` | Top-10 `{ {PlayerName, Elapsed}, … }` |
| ordered `"a"` | — | legacy time-played board; `TopTimeScript` is **Disabled** |

Checkpoint respawn state is kept in `ServerStorage.CheckpointData.<UserId>` (ObjectValue, runtime only).

## Gotchas
- **ChoiceStage** scripts pick a random child and require `p.Name == "Step"`; the three `Step` parts
  per ChoiceStage must keep that exact (duplicate) name. They are not synced (no code inside).
- `PlayerProfile` is saved on leave, every 60 s and in `BindToClose`; a failed load blocks saving for that session.
  Don't `require` it from the MCP command context during a playtest: that creates a second copy that also saves.
- Studio playtests with API access read/write the **live** DataStores — snapshot and restore anything a test changes.
- `CheckpointTouchHandler` plays `script.Sound` — the `Sound`/`Orig` children exist only in Studio.
- `Workspace/Stage3/level.2` is a Model literally named `level.2` (dot in the name).
- Debounces in timer, portal and checkpoint code are per player. Kill scripts keep a script-global `h` keyed by the
  touching part (effectively per player).
- Timer uses `os.clock()`; times are floored to tenths (`TimeFormat.Tenths`) before storing.
- Collected coins are hidden server-wide and never respawn.
- Admin check (`ADMIN_USERS` in `ButtonHandler`) is client-only UI gating.
- Tutorial has no hub portal and no leaderboard; Stage3 has no leaderboard.
- Legacy APIs are common (`wait`, `spawn`, `:connect`, `findFirstChild`); prefer `task.*` and
  `Players:GetPlayerFromCharacter` in new code, but don't mass-rewrite without asking.

## Testing
No automated tests. Verify in Studio: playtest (MCP `start_stop_play`), read `get_console_output`,
and check DataStore behaviour only with Studio API access enabled.

Multi-client: the user starts Test → Start Test Session → **Server and Clients** (F7), then Test → **Add Clients**.
`list_roblox_studios` then shows one extra instance per client and one for the server (unnamed);
`get_studio_state` tells them apart by the focused DataModel. Test users have UserIds −1, −2… and create
`PlayerProfiles` records `user_-1`, `user_-2` — remove them afterwards.
