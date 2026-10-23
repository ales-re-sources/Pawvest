# Oby sandbox — Telemetry (design)

Status: design agreed 2026-10-23, not implemented. Milestones **T1a** (core) and **T1b** (skills) in [ROADMAP.md](ROADMAP.md).

## Goal
Data for rebalancing (M6a / M6b), answering a few questions only:
1. **Where do players struggle?** Deaths and falls per stage, per segment (the stretch after a checkpoint), per cause —
   including "which obstacle kills most", kept coarse enough not to flood the data.
2. **Where do they give up?** Runs abandoned per segment, and players who quit there and never came back.
3. **How hard is a stage overall?** Completion rate, deaths per run, medals.
4. **Are the skills (talents) balanced?** What is bought when, who arrives at a stage without the skill it needs, and how
   a stage plays with and without a skill (T1b).
5. **Which languages to add next?** The player's locale (feeds localization L4, [LOCALIZATION.md](LOCALIZATION.md)).

Not a goal: per-player tracking, positions / heatmaps, per-frame data, our own backend.

## Backend
Roblox **AnalyticsService**, read in the Creator Dashboard (Analytics → Funnels, Progression, Economy, Custom events).
No servers, no DataStore cost. Studio sessions are not recorded by the dashboard, so the module has a debug switch that
prints every event instead. Re-check the current API and limits (custom-field cardinality, events per minute per
server) on create.roblox.com when implementing; the design keeps every field low-cardinality and aggregates the
frequent events.

## Terms
- **Run**: from `TimerStart` to finish, cancel (gate exit, Home, Tutorial return, admin reset) or quit. Every run gets a
  `runId` (GUID) for the funnel session.
- **Segment** `<stageKey>#<k>`: `k` = position (1-based, in course order) of the last checkpoint reached in this run;
  `#0` before the first one (the start gate counts as the first checkpoint, so `#0` is rare). Course order = numeric sort
  of the stage's checkpoint folders, with an optional `checkpointOrder` list in the `StageConfig` entry for exceptions
  (Stage 5's `level.2/26` — verify its place in Studio).
- **Cause** of a fail:
  - `fall` — falling off, **whatever the player's talents**: without Quick Respawn level 2 the player dies on the sea
    (`DebugBaseplate`); with it they never reach the sea, `QuickRespawnClient` puts them back on the plate once they
    drop `FallResetDepth` below it and no death happens, so the client reports the reset and the server counts it
    exactly like a sea death. Stage numbers therefore do not depend on who owns the talent. (Quick Respawn level 1
    only shortens the wait after a real death.)
  - `kill:<obstacle>` — a kill part: its path inside the stage folder, **truncated to 2 levels** (`Beams/Beam_4`,
    `LaserStripStage/Part_04`, `Movers/Mover_Slide`). Arena spikes the same.
  - `other` — anything unexplained (reset by the player, unknown kill).
- **Loadout** (T1b): compact talent levels, e.g. `R1 D2 J0 Q2` (Run Speed, Double Jump, Jump Height, Quick Respawn) from
  the `Talent_<id>` attributes.

## Events

### T1a — core
| Event | API | Fields | When |
|---|---|---|---|
| Run funnel | `LogFunnelStepEvent(player, "Run_<stageKey>", runId, step, stepName)` | step 1 `start`, 2..n `cp<k>`, last `finish` | each step once per run, in order (going back to an earlier checkpoint logs nothing) |
| Stage progression | `LogProgressionStartEvent` / `CompleteEvent` / `FailEvent` (path = world, level = stage index) | complete: medal, time, deaths in run; fail = run cancelled or quit: segment, deaths in run | run start / finish / cancel |
| `Fail` | `LogCustomEvent`, value = count | CF01 stage · CF02 segment · CF03 cause | aggregated per player per (stage, segment, cause), flushed every 60 s and on leave |
| `RunEnd` | `LogCustomEvent`, value = run seconds | CF01 stage · CF02 segment · CF03 reason (`finish` / `exit` / `home` / `quit` / `reset`) | every run end |
| `Quit` | `LogCustomEvent`, value = seconds since the last checkpoint | CF01 stage (or `hub` / `garden` / world name) · CF02 segment · CF03 `run` / `idle` | player leaves |
| `Return` | `LogCustomEvent`, value = days away | CF01 / CF02 = the stored quit | next join of a player whose profile has a `LastQuit` |
| `Session` | `LogCustomEvent` | CF01 locale (`player.LocaleId`) · CF02 platform (touch / gamepad / keyboard, reported by the client) · CF03 `new` / `returning` | join |

Deaths outside a run (hub, garden, exploring a stage without timer) are counted with stage `none` / the stage folder and
segment `#-`, so they do not mix with run data.

### T1b — skills
| Event | API | Fields |
|---|---|---|
| Talent purchase | `LogEconomyEvent` (sink, currency `Coins`, amount = price, balance after, transaction type `Shop`, item SKU `<talentId>_<level>`) | — |
| `TalentBought` | `LogCustomEvent`, value = new level | CF01 talent · CF02 progress bucket of total stars (`0`, `1-5`, `6-15`, `16-30`, `31+`) · CF03 last stage played |
| `ArrivalWithoutTalent` | `LogCustomEvent` | CF01 stage · CF02 missing talent(s) — from the existing `StageArrival` check in `PlayerTimerHandler` |
| loadout on runs | the progression `Complete` / `Fail` events of T1b carry the loadout as a custom field | `Fail` keeps its 3 fields; the per-loadout view comes from progression |

## Reading the questions on the dashboard
| Question | Where |
|---|---|
| Where are runs abandoned? | Funnels → `Run_<stage>`: drop-off between steps |
| Hardest segment of a stage | Custom events → `Fail`, filter CF01 = stage, break down by CF02 |
| Deadliest obstacle | `Fail`, filter CF01 / CF02, break down by CF03 |
| Gave up for good | `Quit` minus `Return` per CF01 / CF02, read **after a 7-day window** (a quit younger than 7 days may still return); overall D1 / D7 retention from the dashboard's built-in retention |
| Stage difficulty | Progression: completion rate, deaths in run; `RunEnd` by reason |
| Skill value (T1b) | Progression by loadout; `TalentBought` by progress bucket / last stage; `ArrivalWithoutTalent` per stage |
| Next languages | `Session` by CF01 |

## Implementation outline
- **`ServerScriptService/Telemetry.luau`** (ModuleScript): the only caller of AnalyticsService. API: `RunStarted(player,
  stageKey)`, `Checkpoint(player, part)`, `RunEnded(player, reason, result?)`, `Fail(player)`, `TalentBought(…)` (T1b);
  per-player run state (runId, stage, segment, deaths, last checkpoint time); the `Fail` aggregation + 60 s flush;
  `Session` / `Return` on join, `Quit` on leave. Attribute `TelemetryDebug` on the module → print instead of / as well
  as logging.
- **Hooks** (call sites only, no gameplay change):
  - `Workspace/Handlers/PlayerTimerHandler.luau` — start / stop / reset / `PlayerRemoving` (the one choke point for
    run start, finish, cancel and quit); `ResetTimer` gains a `reason` argument (GateExit copies, `HomeService`, Tutorial
    `TeleportToSpawn`, admin reset).
  - `Workspace/Handlers/CheckpointTouchHandler.luau` — respawn point changed → `Checkpoint`.
  - `ServerScriptService/RespawnService.server.luau` — `Humanoid.Died` → `Fail`. The cause is classified about 1 s later,
    so a client report can arrive: a server kill mark on the character (attribute `KilledBy`, set by the kill-script
    variants, `DebugBaseplate` → `fall`, `ArenaServer` spikes), else the client's report, else `other`.
  - **`TelemetryRemotes.Report`** (client → server, created at runtime): `("kill", partPath)` from `ObstacleKit`'s
    `kill()`, `("fall")` from `QuickRespawnClient` after a fall reset, `("platform", kind)` once on join. Rate-limited
    (about 1 / s per player), the path must resolve to a part inside a stage folder; anything else is dropped. Telemetry
    only — never trusted for gameplay.
  - `ServerScriptService/TalentService.server.luau` — after a purchase → `TalentBought` (T1b).
- **Profile:** `LastQuit = {}` (`{ Stage, Segment, At }`) in `PlayerProfile.newProfile()` (no version bump). The profile
  saves in its own `PlayerRemoving`, so `PlayerProfile` gets a `BeforeSave` callback list run in its leave handler before
  the save; Telemetry writes `LastQuit` there.
- The kill-script variants (16 + 8 copies + `DebugBaseplate`) get one line each that marks the character; edit them as
  content changes on disk (never move or rename the folders), with the usual copy discipline (AGENTS.md → Reusable
  script variants) and the `ServerStorage.StageKit` copies if any.

## Acceptance checks (Studio, debug switch on)
- T1a: a run start → checkpoints → finish logs funnel steps 1..n in order exactly once, also when a checkpoint is touched
  twice or an earlier one again.
- A death on a server kill part, on a kit beam (client kill), in the sea without Quick Respawn and a fall reset with Quick
  Respawn 2 give `kill:<path>`, `kill:<path>`, `fall`, `fall` on the right segment; 5 deaths within a minute on one
  segment give **one** `Fail` event with value 5.
- Runs ended by gate exit, Home and stopping the playtest give `RunEnd` reasons `exit`, `home`, `quit`; the quit writes
  `LastQuit`, the next join logs `Return` with the same stage / segment and clears it.
- The report remote ignores a second report within 1 s and a path outside every stage folder.
- T1b: a talent purchase logs the economy event and `TalentBought`; the next run's progression events carry the new
  loadout; arriving at a stage without its talent logs `ArrivalWithoutTalent`.
- Live: after publishing, every event type appears in the dashboard (with the dashboard's delay) — only then
  Live-validated.
