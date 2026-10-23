# Oby sandbox — Telemetry (design)

Status: design agreed 2026-10-23; design check against the API limits done 2026-10-23 (see "Design check" below), T1a and T1b implemented and Studio-validated (2026-10-23). Milestones **T1a** (core) and **T1b** (skills) in [ROADMAP.md](ROADMAP.md).

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
prints every event. The limits that shape this design (create.roblox.com, checked 2026-10-23; they reset daily):

| Limit | Value |
|---|---|
| requests per minute (whole experience) | 120 + 20 × CCU |
| custom fields per event | 3; after 8 000 combined values per event the rest is grouped as "Other" |
| custom event names | 100 |
| funnels | **10**; 100 steps each; only the 10 most recent `funnelSessionId`s per user and funnel are tracked; a step logged after skipped ones completes the skipped ones |
| economy | 20 transaction types, 100 item SKUs |

## Terms
- **Run**: from `TimerStart` to finish, cancel (gate exit, Home, Tutorial return, admin reset) or quit. Every run gets a
  `runId` (GUID) for the funnel session.
- **Segment** `<stageKey>#<k>`: `k` = position (1-based, in course order) of the last checkpoint reached in this run;
  `#0` before the first one (the start gate counts as the first checkpoint, so `#0` is rare). Course order = numeric sort
  of the stage's checkpoint folders, with a `checkpointOrder` list in the `StageConfig` entry for exceptions (checked in
  Studio 2026-10-23: Stage5 `20 26 21 22`, Stage6 `401-405 407 408 406`, Stage7 `501-505 507 508 506`, Stage9
  `701 702 703 705 704`).
- **Cause** of a fail:
  - `fall` — falling off, **whatever the player's talents**: without Quick Respawn level 2 the player dies on the sea
    (`DebugBaseplate`); with it they never reach the sea, `QuickRespawnClient` puts them back on the plate once they
    drop `FallResetDepth` below it and no death happens, so the client reports the reset and the server counts it
    exactly like a sea death. Stage numbers therefore do not depend on who owns the talent. (Quick Respawn level 1
    only shortens the wait after a real death.)
  - `kill:<obstacle>` — a kill part: its path inside the stage folder, **truncated to 2 levels** (`Beams/Beam_4`,
    `LaserStripStage/Part_04`, `Movers/Mover_Slide`). Arena spikes the same.
  - `other` — anything unexplained (reset by the player, unknown kill).
- **Loadout** (T1b): compact talent levels at the run's start, e.g. `RS3 DJ1 JH3 QR2` (Run Speed, Double Jump, Jump
  Height, Quick Respawn; the code is the capitals of the talent id, so later talents get their own: `TJ`, `D`, `WJ`, `G`)
  from the `Talent_<id>` attributes, in `TalentConfig.List` order. Today 6 × 2 × 4 × 3 = 144 loadouts at most.

## Events

### T1a — core
| Event | API | Fields | When |
|---|---|---|---|
| Run funnel | `LogFunnelStepEvent(player, "StageRun", runId, step, stepName, { CF01 = stage })` — **one** funnel for every stage (10-funnel cap), broken down by CF01 | step 1 `start`, `k + 1` = `cp<k>` (k = 1..20), 22 = `finish` | each step once per run, only forward (going back to an earlier checkpoint logs nothing); a stage with fewer checkpoints jumps to 22 at the finish and the dashboard completes the skipped steps, so its curve is flat after its last checkpoint |
| Stage progression | `LogProgressionStartEvent` / `CompleteEvent` / `FailEvent` (path = world name, `Hub` for the Tutorial; level = position in the world, 1-based; levelName = stage key) | start: CF03 loadout (T1b); complete: CF01 medal (`none` / `Bronze` / `Silver` / `Gold`) · CF02 deaths bucket · CF03 loadout; fail = run cancelled or quit: CF01 end reason (as `RunEnd`) · CF02 deaths bucket · CF03 loadout (T1b; T1a had the segment in CF01, see Design check T1b) | run start / finish / cancel |
| `Fail` | `LogCustomEvent`, value = count | CF01 stage · CF02 segment · CF03 cause | aggregated per player per (stage, segment, cause), flushed every 60 s and on leave |
| `RunEnd` | `LogCustomEvent`, value = run seconds | CF01 stage · CF02 segment · CF03 reason (`finish` / `exit` / `home` / `quit` / `reset` / `switch`) | every run end |
| `Quit` | `LogCustomEvent`, value = seconds since the last checkpoint | CF01 stage (or `hub` / `garden` / world name) · CF02 segment · CF03 `run` / `idle` | player leaves |
| `Return` | `LogCustomEvent`, value = days away | CF01 / CF02 = the stored quit | next join of a player whose profile has a `LastQuit` |
| `Session` | `LogCustomEvent` | CF01 locale (`player.LocaleId`) · CF02 platform (touch / gamepad / keyboard, reported by the client) · CF03 `new` / `returning` | join |

Deaths outside a run (hub, garden, exploring a stage without timer) are counted with stage `none` / the stage folder and
segment `#-`, so they do not mix with run data. Deaths bucket: `0`, `1-2`, `3-5`, `6-10`, `11+` (deaths + fall resets in the
run). Times and counts never go into custom fields (cardinality); they are event values.

### T1b — skills
| Event | API | Fields |
|---|---|---|
| Talent purchase | `LogEconomyEvent` (sink, currency `Coins`, amount = price, balance after, transaction type `Shop`, item SKU `<talentId>_<level>`, 15 SKUs today of the 100 allowed) | — |
| `TalentBought` | `LogCustomEvent`, value = new level | CF01 talent · CF02 progress bucket of total stars (`0`, `1-5`, `6-15`, `16-30`, `31+`) · CF03 last stage played (the stage of the player's last run in this session, `none` before one) |
| `ArrivalWithoutTalent` | `LogCustomEvent` | CF01 stage · CF02 missing talent(s) as `<id><level>` joined by `+` (`DoubleJump1`) — from the existing `StageArrival` check in `PlayerTimerHandler`, i.e. on every gate entry without the talent; held back with the run's first events, so a ghost run's entry is dropped |
| loadout on runs | the progression start / complete / fail events carry the loadout in CF03 | `Fail` keeps its 3 fields; the per-loadout view comes from progression |

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
- **Ghost runs:** walking out through a door gate touches `TimerStart` again right after `GateExit` cancelled the run,
  which starts a run that `GateExit` ends a moment later. A run's first events (start, progression start, checkpoints)
  are held back for 2 s; a run ending by `exit` within that time sends nothing.
- **Rate guard:** expected load is about 12-15 requests per minute for a player who is running stages (funnel steps,
  progression, `RunEnd`, a few `Fail`), under the 20 per CCU the limit grants. The module still drops events above
  100 + 15 × players in the current minute and warns once per minute when it does.
- **Hooks** (call sites only, no gameplay change):
  - `Workspace/Handlers/PlayerTimerHandler.luau` — start / stop / reset / `PlayerRemoving` (the one choke point for
    run start, finish, cancel and quit); `ResetTimer` gains a `reason` argument, default `exit` (so the GateExit copies and
    the Tutorial's `TeleportToSpawn` stay unchanged); `HomeService` passes `home`, the admin reset `reset`; a start while
    another stage's run is going ends that run with `switch`.
  - `Workspace/Handlers/CheckpointTouchHandler.luau` — respawn point changed → `Checkpoint`.
  - `Humanoid.Died` → `Fail`: the module connects it itself (`RespawnService` stays unchanged). The cause is classified
    about 1 s later, so a client report can arrive: a server kill mark (`Telemetry.MarkKill(character, part)`, called by
    the kill-script variants, `DebugBaseplate` → `fall`, `ArenaServer` spikes; the first mark per character wins; a
    function call, not a string attribute, because full names are ambiguous with names like `level.2`), else the
    client's report, else `other`.
  - **`TelemetryRemotes.Report`** (client → server, created at runtime): `("kill", part)` from `ObstacleKit`'s
    `kill()` (the part instance, not a path), `("fall")` from `QuickRespawnClient` after a fall reset, `("platform",
    kind)` once on join (`TelemetryClient.client`). Kill / fall reports are rate-limited (a second one within 1 s is
    dropped), the part must lie inside a stage folder; anything else is dropped. Telemetry only — never trusted for
    gameplay.
  - `ServerScriptService/TalentService.server.luau` — after a purchase → `TalentBought` (T1b).
- **Profile:** `LastQuit = {}` (`{ Stage, Segment, At }`) in `PlayerProfile.newProfile()` (no version bump). The profile
  saves in its own `PlayerRemoving`, so `PlayerProfile` gets an `OnLeaving(fn)` callback list, run once per player before
  the leave save (also from `BindToClose`, so stopping a server or a playtest counts as a quit); Telemetry writes
  `LastQuit` there. `PlayerProfile.IsNew(player)` (no stored record and no legacy data) gives `Session`'s `new` /
  `returning`.
- **Quit area:** the running stage, else `garden` on the garden island, else the score panel's place (`hub` or the
  world name; `PlayerTimerHandler` pushes it with `Telemetry.SetArea`, because it forgets the panel in its own
  `PlayerRemoving`); value = seconds since the last checkpoint / run start / run end / join.
- **Kill path:** relative to the stage folder, 2 levels (`Beams/Beam_4`, `Part_01`, `11/level 11`); outside every stage,
  relative to the top-level Workspace folder, whose name is then the stage field (`KeyArena`).
- The kill-script variants (16 + 8 copies + `DebugBaseplate`) get one line each that marks the character; edit them as
  content changes on disk (never move or rename the folders), with the usual copy discipline (AGENTS.md → Reusable
  script variants) and the `ServerStorage.StageKit` copies if any.

## Design check (2026-10-23)
Changes against the first draft, from the API limits above: one `StageRun` funnel instead of one per stage (11 stages
today, about 21 planned, 10 funnels allowed); progression custom fields bucketed (exact time and death counts would
exhaust the 8 000 combinations; the time is `RunEnd`'s value); CF03 of the progression events kept free for T1b's
loadout; a rate guard; `checkpointOrder` exceptions checked in Studio; `ResetTimer`'s default reason; kill marks as a
function call; `Died` hooked in the module; `PlayerProfile.OnLeaving` also on shutdown. The debug switch is the
`ServerScriptService` attribute `TelemetryDebug = true` (read on every event, so it can be toggled during a playtest):
every event is printed as `[Telemetry] …`; without it the module is silent.

**T1b (2026-10-23):** with the loadout in CF03, a progression fail of segment × deaths bucket × loadout could reach about
200 × 5 × 144 combinations, far over 8 000. The fail event therefore drops the segment (it stays in `RunEnd` and `Quit`)
and carries the end reason instead: 5 reasons × 5 buckets × 144 loadouts = 3 600; complete: 4 medals × 5 × 144 = 2 880.
New talents (S7, S9) multiply the loadouts: review the bound then (e.g. bucket Run Speed). Only talent purchases are
logged as economy events; the other Coin sources and sinks (medals, unlocks, eggs, pens, food) are left for M6.

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
