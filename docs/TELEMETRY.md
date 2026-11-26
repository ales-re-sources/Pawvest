# Pawvest — Telemetry

All events go through `ServerScriptService/Telemetry.luau`, the only caller of AnalyticsService. Live-validated only once every event type
shows on the Creator Dashboard (ROADMAP M6a).

## Goal
Data for rebalancing, answering a few questions only:
1. **Where do players struggle?** Deaths and falls per stage, segment (the stretch after a checkpoint) and cause, coarse enough not to flood the data.
2. **Where do they give up?** Runs abandoned per segment; players who quit there and never came back.
3. **How hard is a stage overall?** Completion rate, deaths per run, medals.
4. **Are the talents balanced?** What is bought when, who arrives at a stage without the talent it needs, how a stage plays with and without it.
5. **Which languages next?** The player's locale (LOCALIZATION.md, L4).

Not a goal: per-player tracking, positions / heatmaps, per-frame data, our own backend.

**Engagement targets** the economy model assumes (ECONOMY.md → EV checks; re-run `economy.py proposal` with measured values): sessions
per day 2–4, session length 30 min – 2.5 h, online minutes between collects ≤ 4 on day 1 / ≤ 8 later, first Legendary pet ≥ 14 days for a casual player; also D1 / D7 retention, minutes to the first talent purchase.

## Backend
Roblox **AnalyticsService**, read in the Creator Dashboard (Analytics → Funnels, Progression, Economy, Custom events). No servers, no
DataStore cost. Studio sessions are not recorded by the dashboard, so the attribute `TelemetryDebug = true` on `ServerScriptService` (read on every event, can be toggled during a playtest) prints every event as `[Telemetry] …`; without it the module is silent. Limits (reset daily):

| Limit | Value |
|---|---|
| requests per minute (whole experience) | 120 + 20 × CCU |
| custom fields per event | 3; after 8 000 combined values per event the rest is grouped as "Other" |
| custom event names | 100 |
| funnels | **10**; 100 steps each; only the 10 most recent `funnelSessionId`s per user and funnel are tracked; a step logged after skipped ones completes the skipped ones |
| economy | 20 transaction types, 100 item SKUs |

## Terms
- **Run**: from `TimerStart` to finish, cancel (gate exit, Home, Tutorial return, admin reset) or quit. Every run has a `runId` (GUID).
- **Segment** `<stageKey>#<k>`: `k` = 1-based position, in course order, of the last checkpoint reached in this run; `#0` before the first
  (the start gate counts as the first checkpoint, so `#0` is rare). Course order = numeric sort of the stage's checkpoint folders, or the
  `checkpointOrder` list in the `StageConfig` entry (Stage5, Stage6, Stage7, Stage9).
- **Cause** of a fail:
  - `fall`: falling off, **whatever the player's talents**. Without Quick Respawn level 2 the player dies on the sea (`DebugBaseplate`); with
    it `QuickRespawnClient` puts them back on the plate once they drop `FallResetDepth` below it, no death happens, and the client reports
    the reset; the server counts it exactly like a sea death. (Quick Respawn level 1 only shortens the wait after a real death.)
  - `kill:<obstacle>`: a kill part, its path inside the stage folder **truncated to 2 levels** (`Beams/Beam_4`, `Part_01`, `11/level 11`).
    Arena spikes the same (they lie in `Stage14`). A part outside every stage: path relative to the top-level Workspace folder, whose name is then the stage field.
  - `other`: anything unexplained (reset by the player, unknown kill).
- **Loadout**: compact talent levels at the run's start, e.g. `RS3 DJ1 JH3 QR2 D0` (code = capitals of the talent id; Run Speed, Double Jump,
  Jump Height, Quick Respawn, Dash), from the `Talent_<id>` attributes in `TalentConfig.List` order, Run Speed and Jump Height bucketed.

## Events

### Runs and sessions
| Event | API | Fields | When |
|---|---|---|---|
| Run funnel | `LogFunnelStepEvent(player, "StageRun", runId, step, stepName, { CF01 = stage })`: **one** funnel for every stage (10-funnel cap), broken down by CF01 | step 1 `start`, `k + 1` = `cp<k>` (k = 1..20; a later checkpoint counts as `cp20`), 22 = `finish` | each step once per run, only forward; a stage with fewer checkpoints jumps to 22 at the finish and the dashboard completes the skipped steps (flat curve after its last checkpoint) |
| Stage progression | `LogProgressionStartEvent` / `CompleteEvent` / `FailEvent` (path = world name, `Hub` for the Tutorial; level = 1-based position in the world; levelName = stage key) | start: CF03 loadout; complete: CF01 medal (`none` / `Bronze` / `Silver` / `Gold`) · CF02 deaths bucket · CF03 loadout; fail (run cancelled or quit): CF01 end reason (as `RunEnd`) · CF02 deaths bucket · CF03 loadout | run start / finish / cancel |
| `Fail` | `LogCustomEvent`, value = count | CF01 stage · CF02 segment · CF03 cause | aggregated per player per (stage, segment, cause), flushed every 60 s and on leave |
| `RunEnd` | `LogCustomEvent`, value = run seconds | CF01 stage · CF02 segment · CF03 reason (`finish` / `exit` / `home` / `quit` / `reset` / `switch`) | every run end |
| `Quit` | `LogCustomEvent`, value = seconds since the last checkpoint / run start / run end / join | CF01 stage (or `hub` / `garden` / world name) · CF02 segment · CF03 `run` / `idle` | player leaves |
| `Return` | `LogCustomEvent`, value = days away | CF01 / CF02 = the stored quit | next join of a player whose profile has a `LastQuit` |
| `Session` | `LogCustomEvent` | CF01 locales `<account LocaleId>/<device SystemLocaleId>` (`en-us/cs-cz`; `?` when the device locale had not arrived) · CF02 platform (`touch` / `gamepad` / `keyboard`, client-reported; `unknown` after 15 s) · CF03 `new` / `returning` | join |

Deaths outside a run (hub, garden, exploring a stage without the timer) count with stage `none` / the stage folder and segment `#-`, so they
do not mix with run data. Deaths bucket: `0`, `1-2`, `3-5`, `6-10`, `11+` (deaths + fall resets in the run). Times and counts never go into
custom fields (cardinality); they are event values.

### Talents
| Event | API | Fields |
|---|---|---|
| Talent purchase | `LogEconomyEvent` (sink, currency `Coins`, amount = price, balance after, transaction type `Shop`, SKU `<talentId>_<level>`; 13 SKUs of the 100 allowed) | — |
| `TalentBought` | `LogCustomEvent`, value = new level | CF01 talent · CF02 bucket of total stars (`0`, `1-5`, `6-15`, `16-30`, `31+`) · CF03 last stage played (the stage of the player's last run this session, `none` before one) |
| `TalentGranted` | `LogCustomEvent`, value = granted level | as `TalentBought`; a world reward (Double Jump when World 2 opens); no economy event |
| `ArrivalWithoutTalent` | `LogCustomEvent` | CF01 stage · CF02 missing talent(s) as `<id><level>` joined by `+` (`DoubleJump1`); from the `StageArrival` check in `PlayerTimerHandler`, on every gate entry without the talent; held back with the run's first events, so a ghost run's entry is dropped |

The progression start / complete / fail events carry the loadout in CF03; `Fail` keeps its 3 fields, the per-loadout view comes from progression.

### Garden
| Event | API | Fields |
|---|---|---|
| `CropUnlock` | `LogCustomEvent`, value = the crop's place on the ladder (`CropConfig` `order`, 2-16) | CF01 crop id · CF02 how (`count`: the previous crop's plants reached its `step`; `quest`: the last milestone piece); not sent by the `Version` 7 migration |
| `CropLevel` | `LogCustomEvent`, value = the new mastery level (1-3) | CF01 crop id |
| `CropPoint` | `LogCustomEvent`, value = the line's points after this one (1-3; 3 = a full line) | CF01 crop id · CF02 line (`Value`, `Size`, `Speed`) |
| `HallEntry` | `LogCustomEvent`, value = the place on the week's Harvest Hall board (1-3) | CF01 crop id; sent when a harvest gets onto the board as this server knows it (before the write) |
| `PlotLike` | `LogCustomEvent`, value = the liked owner's likes after it | — (sent for the liker) |
| `StageRating` | `LogCustomEvent`, value = 1 (thumb up) or -1 | CF01 stage key · CF02 progress (`Telemetry.StageProgress`): `gold` / `silver` / `bronze` (best medal), `finished` (a best time, no medal), `cp<k>` (furthest checkpoint this session; `cp0` = a run started, none reached), `none` (no finish, no run this session; filter it out to drop players who never tried) · CF03 `new` / `change` (a rating-sign prompt that changed the stored rating; the same value again sends nothing). Running totals per stage: the `StageRatings` DataStore (PROTOCOL) |
| `RequestDone` | `LogCustomEvent`, value = minutes from the slot's fill to done (capped 1 440), plus a `LogEconomyEvent` source (Coins, transaction type `Gameplay`, SKU `request`, amount = the bonus paid) | CF01 crop id · CF02 slot (`1`-`3`) |
| `GardenStart` funnel | `LogFunnelStepEvent(player, "GardenStart", "u" .. UserId, step, stepName)`: the 2nd of the 10 funnels; one funnel session per player, spanning sessions | steps 1-8 the onboarding path (`hatch`, `plant`, `harvest`, `sell`, `buySeeds`, `placePet`, `quests`, `stage`), 9 `request` (first finished request), 10 `return` (first join on a later UTC day); each once, in step order (a step done early is logged when the ones before it are, `OnboardService`); profiles that started as done log nothing |
| `Feedback` | `LogCustomEvent`, value = 1 | CF01 category (bug / idea / other) · CF02 area (`Telemetry.AreaOf`); a message stored in `PlayerFeedback`; the text never goes to telemetry |

Read: time to each unlock = `CropUnlock` per CF01 against `Session` `new`; where the first hour stalls = the share of players reaching
order n; which lines players pick = `CropPoint` by CF02. Only talent purchases and requests are economy events; other Coin sources and sinks
(medals, unlocks, eggs, food, the field) are not logged.

## Reading the questions on the dashboard
| Question | Where |
|---|---|
| Where does a new player's first garden hour stop? | Funnels → `GardenStart`: drop-off between steps |
| Where are runs abandoned? | Funnels → `StageRun`, broken down by CF01 (stage): drop-off between steps |
| Hardest segment of a stage | Custom events → `Fail`, filter CF01 = stage, break down by CF02 |
| Deadliest obstacle | `Fail`, filter CF01 / CF02, break down by CF03 |
| Gave up for good | `Quit` minus `Return` per CF01 / CF02, read **after a 7-day window** (a quit younger than 7 days may still return); overall D1 / D7 retention from the dashboard's built-in retention |
| Stage difficulty | Progression: completion rate, deaths in run; `RunEnd` by reason |
| Talent value | Progression by loadout; `TalentBought` by progress bucket / last stage; `ArrivalWithoutTalent` per stage |
| Next languages | `Session` by CF01 |

## Implementation outline
- **API** (`Telemetry.luau`): `RunStarted`, `Checkpoint`, `RunEnded`, `MarkKill`, `SetArea`, `AreaOf`, `StageProgress`, one function per
  talent / garden event. Per-player run state (runId, stage, segment, deaths), the `Fail` aggregation + 60 s flush, `Session` / `Return` on join, `Quit` on leave.
- **Ghost runs:** walking out through a door gate touches `TimerStart` again right after `GateExit` cancelled the run, which starts a run
  that `GateExit` ends a moment later. A run's first events (start, progression start, checkpoints) are held back for 2 s (`GHOST_TIME`); a
  run ending by `exit` within that time sends nothing.
- **Rate guard:** expected load is about 12-15 requests per minute per running player, under the 20 per CCU the limit grants. The module
  drops events above 100 + 15 × players in the current minute and warns once per minute when it does.
- **Hooks** (call sites only, no gameplay change):
  - `Workspace/Handlers/PlayerTimerHandler.luau`: start / stop / reset / `PlayerRemoving`, the one choke point for run start, finish, cancel and
    quit. `ResetTimer` takes a `reason`, default `exit` (the GateExit copies and the Tutorial's `TeleportToSpawn` pass none); `HomeService`
    passes `home`, the admin reset `reset`; a start while another stage's run is going ends that run with `switch`.
  - `Workspace/Handlers/CheckpointTouchHandler.luau`: respawn point changed → `Checkpoint`.
  - `Humanoid.Died` → `Fail`: the module connects it itself. The cause is classified about 1 s later so a client report can arrive: a server
    kill mark (`Telemetry.MarkKill(character, part)`, called by the kill-script variants, `DebugBaseplate` → `fall`, `ArenaServer` spikes;
    the first mark per character wins; a function call, not a string attribute, because full names are ambiguous) wins, else the client's
    report, else `other`.
  - **`TelemetryRemotes.Report`** (client → server): `("kill", part)` from `ObstacleKit`'s `kill()` (the part instance, not a path),
    `("fall")` from `QuickRespawnClient` after a fall reset, `("platform", kind)` once on join (`TelemetryClient.client`). A second kill / fall
    report within 1 s is dropped, the part must lie inside a stage folder. Telemetry only, never trusted for gameplay.
  - `TalentService.server.luau`: after a purchase → `TalentBought`; after a world reward → `TalentGranted`.
- **Profile:** `LastQuit = { Stage, Segment, At }` in `PlayerProfile.newProfile()`. `PlayerProfile.OnLeaving(fn)` callbacks run once per player before the leave save
  (also from `BindToClose`, so stopping a server or a playtest counts as a quit); Telemetry writes `LastQuit` there.
  `PlayerProfile.IsNew(player)` (no stored record and no legacy data) gives `Session`'s `new` / `returning`.
- **Quit area:** the running stage, else `garden` on the garden island, else the score panel's place (`hub` or the world name;
  `PlayerTimerHandler` pushes it with `Telemetry.SetArea`, because it forgets the panel in its own `PlayerRemoving`).
- The kill-script variants (16 + 8 copies + `DebugBaseplate`) carry one line each that marks the character; edit them as content changes on
  disk (never move or rename the folders), with the usual copy discipline (LAYOUT.md → Reusable script variants) and the `ServerStorage.StageKit` copies.

## Combination limits (keep under 8 000 values per event)
- One `StageRun` funnel for every stage (10 funnels allowed). Progression custom fields are bucketed (exact times and death counts are event
  values); CF03 of the progression events carries the loadout; the progression fail event carries the end reason instead of the segment
  (the segment stays in `RunEnd` and `Quit`).
- Loadout buckets: Run Speed `RS0` / `RS2` (1-3) / `RS5` (4-5), Jump Height `JH0` / `JH2` (1-2) / `JH3`, Double Jump 0-2, Quick Respawn 0-2,
  Dash 0-2: 243 loadouts, fails 5 × 5 × 243 = 6 075, completes 4 × 5 × 243 = 4 860. **Wall Jump and Glide (S9) multiply this by 4: another
  bucket cut is needed then.**

## Regression checks after a telemetry change (Studio, `TelemetryDebug` on)
- Run start → checkpoints → finish logs funnel steps 1..n in order exactly once (also on a repeated or earlier checkpoint).
- Deaths on a server kill part, a kit beam (client kill), the sea without Quick Respawn, and a fall reset with Quick Respawn 2 give
  `kill:<path>`, `kill:<path>`, `fall`, `fall`; 5 deaths within a minute on one segment give **one** `Fail` with value 5.
- Gate exit, Home and stopping the playtest give `RunEnd` reasons `exit`, `home`, `quit`; the quit writes `LastQuit`, the next join logs `Return` and clears it.
- The report remote ignores a second report within 1 s and a path outside every stage folder.
- A talent purchase logs the economy event + `TalentBought` and changes the next run's loadout; arriving without a needed talent logs `ArrivalWithoutTalent`.
