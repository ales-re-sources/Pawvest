# Pawvest — Roadmap

Design lives in [GDD.md](GDD.md); this file is the build order and status. "What next?" is answered from here.
Finished milestones are summarised in a few lines each. Their full scopes, acceptance checks and validation logs are in
git history (last full version: `git show 53bd79b:docs/ROADMAP.md`).

## Workflow

1. **Design check** — confirm the milestone still matches the GDD; fix the GDD first if not.
2. **Scope** — before coding, the milestone section states inputs, outputs, boundary and acceptance checks.
3. **Implement** — code in `src/` (synced by Argon); Studio-only changes (parts, GUI, RemoteEvents) via Studio or MCP,
   listed in the milestone so they are not forgotten (they are not in git; the user saves the place with Ctrl+S).
4. **Studio validation** — MCP playtest runs every acceptance check; console has no new errors; live DataStores
   snapshotted before and restored after (AGENTS.md → Testing).
5. **Status update + commit** — update the status table below, commit code + docs together. When a milestone is done,
   shrink its section to a short summary in "Done".

Rules:
- One milestone at a time, in order, unless the order rationale below allows otherwise.
- Acceptance checks are **hard**: phrased so an empty or broken result fails ("second Gold finish pays 0",
  not "pays Coins").
- A design change discovered during implementation: GDD → ROADMAP → code, in that order.
- Validate through the real UI at least once (a click, a prompt key): firing remotes alone once missed a broken button.

### Status levels (tracked separately, never merged)
| Level | Meaning |
|---|---|
| **Implemented** | code in `src/`, synced to Studio, committed |
| **Studio-validated** | every acceptance check passed in an MCP playtest; no new console errors |
| **Live-validated** | published; checked on a real server with real DataStores |

## Status

| # | Milestone | Implemented | Studio-validated | Live-validated |
|---|---|---|---|---|
| M0 | Foundations | ✔ | ✔ | – |
| M1 | Medals & rewards | ✔ | ✔ | – |
| M2 | Talents shop + admin tools | ✔ | ✔ | – |
| R | Economy: shared payout, repeat rewards, Coins ×10 | ✔ | ✔ | – |
| M3 | Stage unlocks | ✔ | ✔ | – |
| M4 | Challenge coins | ✔ | ✔ | – |
| M5 | Leaderboards + hub navigation | ✔ | ✔ | – |
| P1 | Pets: data, panel, followers, XP | ✔ | ✔ | – |
| P1e | Pet growth visuals | ✔ | ✔ | – |
| P2 | Pet garden: plots, pens, incubators, food | ✔ | ✔ | – |
| H1 | Hub island redesign + stud portals + stud landing pads | ✔ | ✔ | – |
| H2 | Stud checkpoints (square plate, growing core + light) | ✔ | ✔ | – |
| S1 | Stage framework (config, gating UI, Stars) — design check done, S1.1 Studio-validated (2026-10-21), S1.2 done (user's visual check of the portal faces 2026-10-21) | ✔ | ✔ | – |
| S2 | Quick Respawn talent (Studio-checked: 3 / 1 / 0 s delays, fall reset, Home, Skills row) | ✔ | ✔ | – |
| S3 | Obstacle kit + jump lab — S3.1 spike (GO decided 2026-10-21) and S3.2a / S3.2b (hazards, StageCamera; user's visual check done) done; S3.3a / b / c done (kit-local plates, zones, ghosts, templates, reach table, Stage 1 spinners on the kit; user's visual check of Stage 1 done 2026-10-21) | ✔ | ✔ | – |
| S4 | World 1 complete (Island Hop, Blink) — done 2026-10-22: S4.0 courtyard + hub gate, S4.1 Island Hop, S4.2 Blink (user's visual checks) | ✔ (S4.0-S4.2) | ✔ (S4.0-S4.2) | – |
| T1a | Telemetry core: run funnels, fails per segment / cause, quits and returns ([TELEMETRY.md](TELEMETRY.md)) — design check + implementation 2026-10-23 | ✔ | ✔ | – |
| T1b | Telemetry: skills (purchases, arrivals without a talent, loadout per run) — done 2026-10-23 | ✔ | ✔ | – |
| L1 | Localization infrastructure + HUD in Czech ([LOCALIZATION.md](LOCALIZATION.md)) — done 2026-10-23 (Czech texts await the user's review) | ✔ | ✔ | – |
| L1.1 | Strings workflow: CSV source (English + translations + context side by side), `tools/loc.py` build / check / lint / review, pseudo-language — done 2026-10-24 | ✔ | ✔ | – |
| L2 | Localization: all client panels + config display names — done 2026-10-24 (Czech texts await the user's review) | ✔ | ✔ | – |
| L3 | Localization: server-written + Studio-authored texts — texts done 2026-10-24 (Czech awaits review); font check and per-panel Czech overflow pass still open | ✔ | ✔ (texts) | – |
| M6a | First live test + World 1 balancing | – | – | – |
| E0 | Economy model for the pet-garden expansion (scope written 2026-10-24; `tools/economy.py` loader, drift check, reproduction, report, day-by-day sim, crop field + guardrails A-C (39 checks green, provisional numbers in [ECONOMY.md](ECONOMY.md)) done; repricing, dead end, rare supply and sensitivity pending; [EXPANSION.md](EXPANSION.md) §11) | partial | – | – |
| E1.0 | Client-drawn plots spike: GO / NO-GO on the plot architecture before E1 (scope written 2026-10-24, no code) | – | – | – |
| S5 | Worlds hub — done 2026-10-22: gates for Worlds 2-4 (coming soon, admins only), World 2 courtyard, signs, per-world stars boards (user's visual check) | ✔ | ✔ | – |
| S6 | World 2 (stages 6–10) — S6.1 Double Up + Seesaw built and Studio-checked 2026-10-22 (awaits the user's visual check), S6.2 / S6.3 not started | ✔ (S6.1) | ✔ (S6.1) | – |
| S7 | Talents: Triple Jump + Dash (+ World 3 courtyard) — done 2026-10-24: talents, Q / gamepad / touch button, reach table, World 3 courtyard east of the hub; closed 2026-10-24 (the visual and real-device touch checks were waived by the user; Live-validated comes with the next publish) | ✔ | ✔ | – |
| S8 | World 3 (stages 11–15) — S8.1 Triple Peaks + Ice Rink built and Studio-checked 2026-10-24 (kit ice, World 3 open; awaits the user's visual check), S8.2 / S8.3 not started | ✔ (S8.1) | ✔ (S8.1) | – |
| S9 | Talents: Wall Jump + Glide | – | – | – |
| S10 | World 4 (stages 16–20) | – | – | – |
| M6b | Final balancing (all stages) | – | – | – |
| S11 | Bonus stages | – | – | – |
| P3 | Trading | – | – | – |
| M7 | Monetization | deferred | | |

Order rationale (2026-10-21): the stage expansion ([STAGES.md](STAGES.md)) comes first. S1–S4 finish World 1, so the
stage re-order and the new unlock chain land **before the first live test** (no grandfather rule needed); M6a then tunes
World 1 from real finish times. S5–S10 follow in order (each world needs its world island and, from World 3, its talents);
S11 (bonus stages) can slot in after any world island exists (S5 or later). P3 (trading) comes after all 20 stages (user
decision); it needs profile session locking (its first step). M7 is scoped after M6b. Nothing is live-validated yet: the
open checks below belong to the first live test.

Order addendum (2026-10-23, user decision): **T1a → T1b → L1 → L2 → L3**, next after the World 2 work in progress. Telemetry
comes first because M6a needs it: data only accumulates once it is live, so T1a must ship with (or before) the first live
test. Localization does not block the live test. L4 (more languages) is chosen later from the telemetry locale data.

## Done

**M0 — Foundations.** `StageConfig` (stage key, folder, hub portal, `T_base`, tiers, unlock rule, reward factor) so stage
scripts are identical copies; timer on `os.clock()` shown as `mm:ss.t`; `PlayerProfiles` DataStore (load / migrate /
save, a failed load never saves) migrating the legacy `PlayerCoins` / `PlayerScoresStore`; per-player debounces.

**M1 — Medals & rewards.** Bronze / Silver / Gold per stage by time, one-time medal payouts, results popup, own stars on
each hub portal; the score panel and the timer show the medal limits and the next reachable medal.

**M2 — Talents shop + admin tools.** Skills panel (⚡) with Run Speed, Double Jump and Jump Height, bought through a
server-priced `Buy(talentId, expectedLevel)` and applied on every spawn. `AdminConfig` is the single admin list; admin
Reset Score (a full self-reset, confirmed by a second click) and +Coins are checked on the server.

**R — Economy.** `CoinRewards.Grant` is the only gameplay payout (pet multiplier, rounding); a daily repeat reward per
stage decays by 0.8 per finish with a floor of 10; every Coin amount was scaled ×10 (profile `Version = 3` migrates
older records once).

**M3 — Stage unlocks.** A hub portal opens by the previous stage's medal (Stage 1: Bronze on Tutorial, Stage 2 / 3:
Silver on the stage before) or by a purchase (500 / 1 500 / 3 000). Locked portals are local walls that open the
unlock popup; the portal face shows the requirement and price.

**M4 — Challenge coins.** 29 coins (Tutorial 2, Stage 1 8, Stage 2 9, Stage 3 10) worth 20 / 50 / 100 (easy / risky /
Double Jump only), collected once per player and hidden only for that player; "found x/y" on each portal face; pickup
sound. Ids live in `ChallengeCoinConfig` and must never be renamed or reused.

**M5 — Leaderboards + hub navigation.** Top-10 board with avatars on every stage pad; hub "most stars" board
(OrderedDataStore `MostStars`); Tutorial course and hub portal; top-left buttons Home (to the hub) / Skills / Pets /
Settings / Admin.

**P1 — Pets.** 8 kinds in 5 rarities with a Coin bonus (total capped at +50 %); up to 3 follower slots, inventory 50,
selling; launch egg and a free Basic egg on each stage's first Gold; a hatched pet is equipped when a slot is free.
Pets panel (🐶), blocky part-built models following every player (client-side, never touching gameplay parts).
XP from the run's medal (5 / 10 / 20), each challenge coin (+1) and server-measured movement during a run (max 30);
levels 1–20.

**P1e — Pet growth visuals** (design: [PET_GROWTH.md](PET_GROWTH.md)). The look is a pure function of (kind, level, uid):
size 1.0 → 1.6, a staged level-up moment, tier effects at Lv 5 / 10 / 15 / 20 with distance LOD, per-pet colour and
texture, accessories at Lv 10 / 20, Bunny coats. Followers and garden pens are drawn by the same code.

**P2 — Pet garden.** A garden island with 12 plots, one borrowed per player (servers of 12 players). Each plot has 6 pens
whose pets produce Coins, also offline (capped at 8 h, server time only), and 3 incubators, the only place eggs hatch:
Basic (500, 5 min) and Golden (4 000, 1 h, no Common); free eggs start in an empty incubator by themselves. A food stand
sells XP (Berry / Cake / Feast) for any pet. A pet is either equipped or penned.

**H1 — Hub island redesign.** The hub is a part-built island in the garden's style, joined to the garden by a wooden
bridge (no portals); one endless sea is the world's floor and kill brick; decor, signs, the stars board and the 4 stage
portals use the stud style (`ServerStorage.DecorKit`).
The 4 stage landing pads (H1.2) match: a cobblestone inlay on the grass pad, hedges on three sides, trees / bushes / flowers
cloned from the kit, a stud-stone start gate with the stage name over `TimerStart`, the return portal as a stud arch (warm
orange face, label "Hub") and the hub board's wooden frame on every Top-10 board. The `TimerStart` trigger spans the whole
pad (48 × 30 × 4), so the timer cannot be skipped by jumping around the gate; the pads and gates are centred on the first
checkpoint platform of their track (the start gate is a `StartGate` Model of 17-stud pillars). `ServerStorage.StageKit.LandingPad` is the
reusable template (AGENTS.md → Adding a stage); `GateSign` writes the stage name on the gate. A client script
(`CameraFacing`) turns the camera the way the character faces after a teleport and on the first spawn: the hub spawn looks at
the Tutorial / Stage 1 portals, each stage's arrival point looks along the course. The user's visual check of the pads passed (2026-10-20).

**H2 — Stud checkpoints.** Every checkpoint is a 16 × 12 cream stud plate (the courses moved 5.84 studs per checkpoint
to make room) with a small green tile; only the player's current checkpoint glows for that player (the tile grows, a light
column rises, 1 s), the first reach in a run plays the sound, and the start gate counts as the stage's first checkpoint.
A respawn faces along the course (the plate's front). `ServerStorage.StageKit.Checkpoint` is the template. The Stage 2 bounce bricks launch at a fixed speed per brick
(client-side), so the chain to checkpoint 13 works at walking speed. The user's check passed (2026-10-20).


**S1 — Stage framework** (2026-10-21; design in STAGES §9, GDD §3–6). `StageConfig` gained `world` and `requires`, the reward factors `0.5 + 0.25 × n`
(Stage 3: 1.75) and the unlock rule `{ world, stars }` (10 of the previous world's 15 stars, or the price) in `StageConfig` + `StageUnlocks`; challenge-coin
values stay flat (20 / 50 / 100). Gating UI: a "Needs: <talent>" line on hub portal faces (green / red), an arrival warning with a button that opens the Skills
panel (entry is never blocked), leaderstats "Stars" instead of "Stage". Stage 3's duplicate checkpoint got a free number.

**S2 — Quick Respawn talent.** `QuickRespawn` level 1 (1 000): respawn after 1 s instead of 3 s; level 2 (3 000): instant respawn and a client-side fall reset to the
current checkpoint. A server script does all respawns (`CharacterAutoLoads` off). Design: STAGES §6.2.1.

**S3 — Obstacle kit + jump lab** (2026-10-21; design STAGES §2.4, §5.1). The client-driven kit passed its spike (carry drift ≤ 0.053 studs after 30 s, a tilt plate that
slides players off, a client kill reaching the server in 0.03 s, 100 movers + 10 beams at 0.34 ms per frame). `ObstacleKit.client` (tags `KitMover`, `KitTilt`,
`KitBeam`, `KitPlate`, `KitCrumble`, `KitSwitch` / `KitColorPlate`; attribute `Kill`, `RunSeeded` = schedule on the player's run time) with the pure `KitMath`;
movers: slide, turntable, lift, spinner, piston, pendulum, disappearing plates; `KitZones.client` (Wind with gusts, LowGravity, Updraft); `KitGhosts.client`
(other players drawn translucent inside a ghost zone); `StageCamera.client` (modes Iso / Side / Down / Front by `CameraZone` parts or a stage `CameraMode`
attribute, reset on death / Home / finish). Studio-only: `Workspace.KitLab` (jump lab with gap and height ladders, at (547, 16, -475)) and 28 templates in
`ServerStorage.StageKit.Obstacles`. The reach table per talent set is measured in STAGES §1.0. Stage 1's eight server spinner scripts became `KitMover` Spin parts.
Lessons: wait for the respawned Humanoid before reading it; reduce spin angles modulo 360 in double precision (float32 froze the part); a floor probe counts only surfaces
2.0–3.8 studs under the root and kill hazards are never floors; the touch test is a box 0.1 stud larger than the part. Other clients see a rider about 0.2 s behind a
platform, so keep movers watched by players at ≤ 10 studs/s. The user's visual checks passed.

**S4 — World 1 complete** (2026-10-21 / 22). S4.0 courtyard (x -430..-320, z 187..357) with a hub gate; the `LandingPad` was split into `Gate` (door gate: `TimerStart`,
`GateExit`, `GateSign`, `Door`), `Top10Leaderboard` and `Arrival` templates in `ServerStorage.StageKit`; the stages lie behind the gates (STAGES §7.1). S4.1 Island Hop
(checkpoints 101–105, 7 coins, `KitConveyors.server` for conveyors, price 200 Coins by user decision). S4.2 Blink, the rhythm special (120 BPM metronome per run,
`StageMusic.client`, a Music row in Settings, checkpoints 201–206, 8 coins, `tBase` 60, factor 1.25); the unlock chain is complete. Tuning: a ProximityPrompt on shut
doors and gates replaced the unlock popup (`GatePrompts.client`), an exploring banner when a checkpoint is reached without a timer, `TimerStart` shrunk to the
doorway (21 × 16 × 4), the World 1 gate shut until one stage is open, shared `PortalFaceStyle`. Restyle: all six original courses now use the Island Hop stud-column look
(Tutorial approved; Stages 2, 4 and 5 await the user's look), end portals are stud-stone arches ("Finish"). Rename (2026-10-22): keys, folders and coin ids equal the
stage position (`Stage1` Island Hop … `Stage5`, `Tutorial`), stages live under `Workspace.World1`; developer DataStore records migrated.
*Open after S4:* (1) Stage 5's 11–12 stud jumps need more than a baseline single jump (talents vs geometry, decide in M6a); (2) a real music track for Blink instead of
the metronome (Sound + BPM); (3) measure the real `T_base` of every stage in M6a; (4) check the three ChoiceStages of Stage 2 (rebuilt after the rename).

**S5 — Worlds hub** (2026-10-22; STAGES §7.8). `StageConfig.Worlds` entries, `StageUnlocks.IsWorldOpen` (a `soon` world is shut for everyone but admins), `HubGateFaces` /
`HubGateLocks`, hub gates `GateWorld1..4`, the World 2 courtyard (cloned from World 1, 263 studs south, rotated 180°), per-world `WorldStars_<n>` boards (`StarBoard`). The user's
visual check passed.

**S6 — World 2** (2026-10-22 / 23; STAGES §7.9). Stage 6 Double Up and Stage 7 Seesaw (checkpoints 401–408 / 501–508, `requires` Double Jump, factors 2.0 / 2.25, World 2 opens
with 10 of 15 World 1 stars or 2 500, both lengthened to ~630 / 760 studs, wind visible through `WindParticles`); Stage 8 Turntable (kit kind `Flip`, `PushTime`, made harder
after the first run) and Stage 9 Labyrinth (`KitMaze.client`, a teaching maze + a 15 × 15 maze with an exit door opened by a latching switch, four patrolling guards, blinking
lava, walls shifting every 5 s; `T_base` 100); Stage 10 Clocktower (tick-driven spinners and `KitButton` / `KitDoor`, a belfry finish behind a ladder, `T_base` 90, checkpoints
801–806). Each stage was crossed by a bot at baseline with one air jump and one timed run finished with a payout.
*Not checked / open:* the look of every course (the Studio viewport rendered white), human difficulty and real `T_base`, the user's own run and look at the Stage 9 maze, a
full timed Stage 9 run, deleting `ServerStorage.Stage9_OldBigMaze` after that check. Argon note: an edit to `ObstacleKit` once did not reach Studio; check the Studio source
before a playtest.

**S7 — Talents: Triple Jump + Dash, World 3 courtyard** (closed 2026-10-24; STAGES §7.10). `DoubleJump` level 2 (Triple Jump, 5 000) with per-level names; `Dash` (8 000,
`TalentDash.client`: Q / gamepad X / touch button; one dash of 10 studs in 0.2 s per air time); Skills rows; telemetry loadout with bucketed Run Speed; reach table with the
real talents; the World 3 courtyard east of the hub (admins only while `soon`). *Not checked:* the touch button on a real phone, the trail's look.

**T1a / T1b — Telemetry** (2026-10-23; [TELEMETRY.md](TELEMETRY.md)). `Telemetry.luau` is the only user of AnalyticsService. One shared `StageRun` funnel (`start`,
`cp1`..`cp20`, `finish`) broken down by stage (the API allows 10 funnels), progression events with medal and deaths buckets, `Fail` aggregated per (stage, segment, cause:
`fall` / `kill:<obstacle>` / `other`), `RunEnd` reasons, `Quit` + `Return` through the profile's `LastQuit`, `Session` (locale, platform), `TelemetryRemotes.Report` (client
kill / fall / platform, rate-limited), debug switch = `ServerScriptService` attribute `TelemetryDebug`. T1b: the loadout code (`RS3 DJ1 JH3 QR2`) in CF03 of the progression events,
an economy event + `TalentBought` on every purchase, `ArrivalWithoutTalent`. *Not checked:* the Home button click, the garden quit area, the rate guard, the loadout on a
progression complete; **Live-validated only when every event type shows in the Creator Dashboard after publishing.**

**L1–L3 — Localization** (2026-10-23 / 24; [LOCALIZATION.md](LOCALIZATION.md)). English default + Czech; language from `player.LocaleId`, override in Settings (profile
`Language`, attribute `Language`); `Locale.T` / `Locale.SetKey`, Studio-authored labels tagged `Loc` + `LocKey`. L1.1: `localization/strings.csv` (English, Czech, context side by side)
compiled by `tools/loc.py` (`build` / `check` / `lint` / `review`) into the generated `Strings/*.luau`, plus a pseudo-language `qps` for Studio / admins. L2: every client panel and
config display name; L3: server-written and Studio-authored texts, lint baseline 0. The Czech texts were reviewed by the user (113 approved, 25 reworded).
*Open:* the FredokaOne caron-glyph font check, Czech overflow screenshots of the panels, the Stage 9 maze exit door label ("Find the switch"). *Not checked:* Player Emulator
with `cs-cz` on first join, the arena HUD on screen. L4 (more languages) is chosen later from the telemetry `Session` locale data.

## Open checks for the first live test
Never covered in Studio, so check them on a real server:
- several real players at once: shared plots, pens, incubators, pet effects and coins seen by others; a full 12-player garden;
  checkpoint pads and their sound only for the player who reached them (H2);
- two servers at once (boards and `MostStars` updating across servers);
- a locked portal's unlock popup on the redesigned hub (only the barrier was tested there);
- a real 1-hour Golden egg and the inventory cap with free eggs waiting;
- touch / mobile layout of every panel and popup (planned as milestone MU below).

Housekeeping (Studio): `ReplicatedStorage.StageTimerStopped` is unused and can be deleted.

## Next milestones

Stage expansion plan and design: [STAGES.md](STAGES.md) (catalogue, curve, worlds, talents, §8 milestone breakdown). Stage
milestones hold 2–3 stages each; every sub-milestone ends with a Studio check, the user's visual check and a commit.
Each milestone gets its scope when it starts (workflow step 2).

Pet-garden simulator (E0–E8, direction decided 2026-10-24, draft, nothing started): [EXPANSION.md](EXPANSION.md) §10–11 (game name **Pawvest**; the MVP
cut is E1 + E2 + hatch-time traits + first landmark and request board + basic ledger, then updates U1–U5). E0 (economy
model) and the plot-architecture spike E1.0 come first (scopes below); E1 (the field and crops) is the first build milestone. They get their scope when they start.

### E0 — Economy model (scope, 2026-10-24; draft until the open decisions below are confirmed)
**Goal.** One reproducible model of the whole Coin economy (faucets, sinks, time) that fixes the numbers E1 needs and proves the
GDD §6 constraints and the EXPANSION §5 guardrails still hold with crops added, **and re-prices every Coin sink** (talents, stage unlocks,
pet slots, eggs, incubators, posts, food, field expansion and upgrades, stations) so each is bought at a deliberate point in the
player's timeline. No game code changes in E0 itself; the output is numbers and docs, and the price changes are applied afterwards (E0b).

**Form.** `tools/economy.py` (Python, stdlib only, like `tools/loc.py`): `python tools/economy.py report` prints the tables,
`check` runs the acceptance checks below and exits non-zero on a failure, `csv` writes the timelines for Excel. Parameters for
things that already exist (medal base, factor formula, repeat reward, talent / pet / egg / pen / incubator / food prices, rarity
bonus, pen rates) are **read from the Luau configs by regex where the table is flat, otherwise copied into one `PARAMS` block with
a drift check** that fails when a config value differs. New numbers (crops, seeds, Renown gates, request rewards, landmark
bundles) live only in the model until E1 copies them into `CropConfig`.

**Inputs (existing, GDD §5-§7).** Medals and first-finish payout per stage (21 stages planned), repeat reward with the daily decay,
challenge coins (~160 planned), talent tree (47 300), stage unlocks (80 700), pets (eggs, slots 7 000, rarity bonus, +50 % cap,
sell values, levels / XP, food prices), pens 32 500, incubators 17 000, pen production (rates by rarity, 8 h offline cap).
**Inputs (new, EXPANSION §5-§9).** The crop ladder (tiers, grow time, sale price, seed cost 20-30 %), the **field** (a grid of squares the
player plants freely, see below), field expansion and upgrade prices, Gardener auto-replant coverage (squares per Gardener pet and the
number of Gardener posts), seed stock, Renown gates, station multiplier (1.5-2×), request board (3 a day), the first landmark (Kitchen) bundle.

**Field model (decided 2026-10-24, replaces "6 beds").** The garden has one **field** made of squares; the player puts any unlocked crop
on any square. Capacity comes from the number of squares (expansion tiers of the field, bought with Coins and Renown), not from a fixed
bed list, and the crop catalogue size becomes a content question rather than a structural one: the model takes any crop list. Parameters:
squares per expansion tier and their prices, the upgrades (for example faster growth, a barn, more Gardener coverage), optional crops
that cover 2 × 2 squares (giant melon, trophy pumpkin). The plot geometry is **not** a constraint of E0 (decided 2026-10-24: the plot area and layout will be reworked, and the architecture may move
to client-drawn plots, see EXPANSION §12 "Plot architecture"): the maximum field is a model parameter with a provisional ceiling
(proposal: 150 squares) that the plot rework must be able to draw. E0 outputs the minimum catalogue that makes the ladder work (at least one crop per tier
plus a rare one per world) and a recommended MVP size; six stays a proposal, not a constraint.

**Player archetypes** (each simulated day by day, 60 days): *Obby main* (2 h obby, 3 garden visits), *Casual* (45 min, 2 visits),
*Garden main* (15 min obby, 5 visits, long offline gaps), *Binge* (one 6 h day, then nothing for a week). Each has a visit
schedule, an obby minutes budget by stage reached, and a purchase policy (talent-first or pets-first; two variants).

**Questions the model must answer (each becomes a number or a rule in EXPANSION / GDD)**
1. **Baseline.** What does today's pen economy pay per archetype and per day? The GDD says 6 mixed pets at Lv 5 ≈ 197 Coins/h and a
   strong set ≈ 5 000 per 8 h offline, which is above the E1 target (a casual 4-bed garden ≈ 1 100 a day). E1 would then be a nerf for live
   players: decide the migration (grandfather the pen income to a cut-off date, convert to a one-time payout, or retune the crops up).
2. **Crop ladder.** Sale price, seed cost, grow time and gate per tier so that net Coins per square-hour land on ≈ 20 / 45 / 90 / 150 (rare)
   and the guardrails hold (the per-bed numbers of EXPANSION §5 are read as per square until the model replaces them).
3. **Field and Gardener capacity.** Squares per expansion tier, their prices, the Gardener coverage and the seed stock needed, so that the
   structural cap (not the 8 h rule) limits output. Reference: a fully replanted square cycles 24 h a day, 6 squares × 90 = ~13 000 a day against
   the 24-hour rule below, so the cap has to come from square count, seed cost and stock, not from grow time alone.
4. **Sink share.** How much of each faucet the sinks absorb (seeds, beds, stations, barn, decor, landmark bundles, talents,
   unlocks) at days 1, 7, 30, 60; the time to buy everything per archetype, so no archetype hits "nothing left to buy" before day 60
   and none is stuck with Coins but no sink.
5. **Obby vs garden balance.** Hourly and daily Coins by source per archetype and per world reached; the share from the garden
   must stay a majority only for *Garden main*, never for *Obby main*.
6. **Pet bonus interaction.** The +50 % multiplier applies to crop sales at sale time: verify it does not push the best archetype
   beyond the guardrail (the bonus multiplies the garden too).
7. **Rare crops and requests.** How many rare crops the obby drip supplies per week (daily first-run seed, world signature crops) against
   what the first landmark and the request board consume; sets the bundle sizes and the request rewards.
8. **Talent / unlock timing under the new faucet.** The §6 "required set share ≤ 65 %" table recomputed with the garden income and
   the new sinks: crops must not let a player buy Dash before World 2, nor starve the no-grind path.
9. **Repricing.** For every sink (talents, stage unlocks, pet slots, Basic / Golden egg, incubators, posts, food, field expansion tiers,
   field upgrades, stations, landmark Coins parts) the day each archetype can first afford it. The model proposes a price per sink that
   lands that day inside a target band (bands: open decision 3), shown as old price, proposed price, change %, and the archetype days.
   Talent prices must keep the §6 required-set table (≤ 65 % share) and the Gold sets of World 1.

**Outputs**
- `tools/economy.py` + `tools/economy_README.md` (how to change a number and re-run) — or a section in this file if it stays short.
- `docs/ECONOMY.md`: the chosen parameters, the tables from `report`, the archetype timelines, the decisions taken and why.
- **A price proposal table** (old price → new price per sink, with the time-to-afford it produces). It is only a proposal until the user
  approves it; applying it is **E0b**: GDD §6 / §7 first, then the config values (`TalentConfig`, `StageConfig.unlockPrice`, `PetConfig`,
  `GardenConfig`), then `loc.py` if a price appears in a text, then a Studio check that the shops show the new prices. Existing buyers are
  not refunded or charged again (a lowered price stays in their favour, a raised one only affects what is not yet bought).
- EXPANSION §5 / §9 and GDD §6-§7.6 updated with the final ladder, prices and guardrail numbers (GDD first, per the workflow rule).
- A list of E1 inputs ready to copy into `CropConfig` (crops, seed prices, bed prices, Renown thresholds, request rewards) and the
  migration decision for pen income.

**Boundary.** In: the numbers, the model, docs, the price proposal. Out of E0 (in E0b once approved): any Luau change and any Studio change. Out entirely: telemetry events (E1 extends TELEMETRY.md), monetization
(M7), trading (P3), critters / raids (the model leaves a placeholder "loss rate" parameter for U1), estate tiers and decor prices (U4; only a
reserved sink share). The model is not a simulator of the game: no stochastic eggs beyond expected values, no player skill model beyond
the archetype's minutes and Gold-run share.

**Acceptance checks (hard; `python tools/economy.py check` prints each and fails on any miss)**
1. Drift: every existing-config parameter equals the model's value; changing `PenPrices[2]` in the config makes the check fail.
2. Reproduction: the model returns the GDD figures it already states — one-time medal total of the six built stages = 9 450, all 21 stages =
   88 200, first-finish total 6 300, planned talent tree 47 300, Gold-run sum of a day on Stage 2 = 668, 6 mixed Lv 5 pens = 197 ± 1 Coins/h.
3. GDD §6 required-set table: every share ≤ 65 % with garden income **off**, and the recomputed table with it **on** is printed beside it.
4. Guardrail A, **the 24-hour rule** (decided 2026-10-24): one active obby hour (mini-games count) ≈ 24 hours of fully automated planting.
   For every archetype at every progress point the model computes the Coins of a fully developed, fully replanted field over 24 h and compares
   it with that player's first obby hour of a fresh day (2 230 at the time of this scope, scales with the stages reached, includes the pet
   bonus on both sides). It must stay ≤ 1.0 ×; the report prints the ratio, the target is 0.8-1.0 × so the garden is a real income, not a decoration.
5. Guardrail B: a field with no Gardener harvests at most once per square per visit (nothing replants itself), so a visit-less day pays
   strictly less than a Gardener-run day.
6. Guardrail C: the sinks absorb at least the fixed share of the faucet decided below, measured over days 1-60 per archetype.
7. No dead end: every archetype can afford the next required talent before the stage that needs it, without a purchase from the garden.
8. Rare crops: the weekly rare-crop supply of the obby drip ≥ the first landmark's need within 14 days for *Casual*, and the supply is
   zero for a player who never runs an obby.
10. Repricing: for every sink the proposed price puts the first affordable day of each archetype inside its band; no price changes by more than
    ×2 or ÷2 from today's without being listed as "large change" for the user to confirm.
11. Sensitivity: a table of ±20 % on each new parameter and which acceptance check flips; any parameter whose ±20 % breaks a guardrail is
   flagged for telemetry in M6a.

**Progress (2026-10-24): baseline step done.** `tools/economy.py` loads every existing number from the Luau configs with a small table reader
(no duplicated constants), pins them in `tools/economy_pins.json` (`drift` / `check` fail when a config changes; `pin` accepts the new state after
review), reproduces the GDD figures (acceptance checks 1-3 run and pass: 21 / 21), and prints the baseline (`report`). The day-by-day simulation
(`sim`) is built, see below. The crop field and guardrails A-C (checks 4-6) are built too (field step below). Not built yet: dead end (7), rare-crop supply (8), repricing (10), sensitivity (11).

**Baseline findings** (`python tools/economy.py report`; run times are model assumptions, hour 1 for World 1 comes out at ~2 700 vs the GDD's ~2 230)
- The first obby hour of a day grows steeply with progress because the repeat-reward decay is per stage: ~2 700 (Tutorial + World 1), ~5 500 (+ World 2),
  ~6 500 (+ World 3 built). The 24-hour rule therefore compares against the hour at the player's own progress, not one fixed number.
- **Today's pens already break the 24-hour rule** for early players: 6 mixed Lv5 pens make ~4 700 per 24 h (1.8x the World 1 first hour), a strong
  Lv10 set ~15 000 (5.6x). Only the 8 h offline cap holds it in check; for a Casual player the pens (~3 400 a day with the mixed set) out-earn the
  obby (~2 300 a day at World 1). The crop field must not inherit this: its ceiling comes from squares, seed cost and stock.
- One-time sinks (talents 47 300, 20 stage unlocks ~78 700 with provisional prices for 13-20, slots 7 000, pens 32 500, incubators 17 000 = 182 500) are
  1.8x the one-time faucet (medals + first finish + challenge coins = 101 640). Repeat rewards and the garden must fill the difference, which is
  the room the repricing has to work with.
- A Basic egg resells for ~48 % of its price and a Golden egg for ~18 %, so selling pets is a weak faucet today.

**Simulation step (2026-10-24, `python tools/economy.py sim`).** Four archetypes x two purchase policies (talent-first, pets-first) x 60 days,
6 egg-roll seeds each: obby (learn a stage, then farm Gold runs with the daily decay), pet XP and levels for the equipped pets, the pet multiplier on
every faucet, pens, eggs, food, and time-to-afford / time-bought per sink. The learning curve (stage n takes 5 + n runs of T_base x 1.4 + 25 s) is the
largest assumption and is provisional until telemetry exists (a dedicated player clears all 21 stages in ~17 days at 2 h a day, Casual in ~30).
Findings of the current game (before crops):
- **Pet leveling saturates within days.** Equipped pets reach about Lv 20 in 7-14 days for every archetype except *Garden main* (~30 days): a Gold run
  gives up to 50 XP to each equipped pet (20 medal + 30 movement), so Lv 1 -> 20 (6 714 XP) is ~134 runs. The multiplier then sits at ~1.47 and only
  rarity / slots can raise it. XP and food are therefore not a lasting sink or progression axis; the egg luck is the only variable left.
- **The existing sinks run out.** An *Obby main* player has bought all talents, pens, slots and incubators by day ~6; *Casual* by day ~14; *Binge* ~22; *Garden
  main* ~29. At day 60 the bank holds 0.2 M (Binge), 0.3-0.5 M (Garden main), 0.8 M (Casual) and 1.8 M Coins (Obby main). At full progress income is ~39 000 a day (Obby main:
  23 700 repeat + 15 400 pens), ~23 000 (Casual), ~18 000 (Garden main, 87-89 % pens). E1's sinks must absorb this, not the 182 500 one-time sinks of today.
- **Pens already dominate for the casual player at full progress:** pens are 51 % of *Casual* income at day 60 (and 87-89 % for *Garden main*); for
  *Obby main* 36-40 %, inside the "never a majority for Obby main" rule. Pens never level here (penned pets get no XP unless fed), and even so a full
  pen set sits at ~1.0-1.1x the first obby hour (24-hour rule) at full progress. The crop field must stay under that line with levels and the multiplier counted.
- Required talents block a player only 0-5 days in total (they save for Double Jump, Triple Jump, Dash...): the no-grind path holds for every archetype.
- **Free eggs:** the code grants a free Basic egg for the first Gold on **every** stage (StageResults `GOLD_EGG`), (up to 21 + the launch egg). GDD §7.2 said 4 and was corrected
  to match the code on 2026-10-24; the simulation follows the code.

**Field step (2026-10-24, `python tools/economy.py check` / `sim` / `field`; numbers in [ECONOMY.md](ECONOMY.md), all provisional).** The model now has the crop field: one grid of squares
(6 free, 9 expansion tiers), visit-based harvest (one per square per visit, ripe crops wait), Green-thumb Gardener pets on Field posts that re-cycle their squares between visits from a seed
stock and barn, seeds as a real cost, sales through the pet multiplier, Renown as a derived level, a rare-seed drip from the obby, upgrades (growth, barn, Gardener coverage) and a placeholder
ladder for the sinks that are not designed yet (landmarks / estate / decor). `--garden pens|field|both` switches between today's pens, pens-become-posts and grandfathered pens. 39 checks pass in
about 2 s, including A (24-hour rule on every day, every archetype x policy), the A target band, B, C and the Obby main garden share. Findings:
- **The EXPANSION §5 ladder (20 / 45 / 90 / 150 per square-hour) only fits 4-7 squares** under the 24-hour rule at the last stage (first obby hour 10 188). Tuned: ladder scale 0.15 (3 / 6.7 / 13.5 / 22.5)
  and a field of 6 -> 24 squares; **the 150-square ceiling is not needed (the plot rework draws 24-30)**; squares x scale is what the rule limits. Binding archetype: Casual (long gaps, a 12 h crop ripens each visit) at
  0.95x; Obby main 0.85x, Garden main 0.86x (0.70x at day 60), Binge 0.55x. About half of the potential is the Gardener part. A is linear in the ladder scale (+20 % -> 1.14x), and also sensitive to
  squares per Gardener and the growth upgrade: flag them for M6a telemetry.
- **Catalogue:** six crops (Potato, Pumpkin, Giant melon + one rare per world) pass every check; the recommended MVP is **seven** (+ Corn, the 6 h slot, +10 % for Obby main). Carrot, Radish and a 2 x 2 crop add under 1 %.
- **B holds:** with / without Gardeners the net per day is 12.6k / 9.5k (Obby main), 14.1k / 12.6k (Casual), 8.5k / 2.2k (Garden main), 4.4k / 0.1k (Binge).
- **C needs content that does not exist yet:** existing sinks plus the field absorb 35 % (Obby main) / 53 % (Casual) of the faucet by day 60; the 80 % proposal needs ~0.97 M / 0.36 M Coins of landmark / estate / decor sinks
  (the placeholder ladder supplies them; the check prints both values). Obby main's garden share is 39 %, but **Casual's is 58 %** (garden majority for a 45-minute player).
- **Pens:** grandfathering them (`--garden both`) breaks A (worst day 2.2-2.7x) and puts Obby main's garden share at 53 %: the model supports replacing the Coins-per-hour production when posts arrive.
- Rare seeds from the obby: 7-9 a week for Obby main / Casual, 2-3 for Garden main / Binge.

**Done when** `check` is green, `docs/ECONOMY.md` and the GDD / EXPANSION edits are committed, and the user has confirmed the ladder, the
price proposal and the pen-income migration. E0b (applying the prices) is a separate small milestone. Status: in progress (baseline, simulation and field steps done; repricing next).

**Decided:** form = script (2026-10-24); the garden is one free-form field of squares (not fixed beds); guardrail = the 24-hour rule (check 4), measured against the **first obby hour of a fresh day** (about 2 230; the later steady hour is only reported).

**Open decisions (confirm before starting)**
1. *Sink share:* the fixed share the sinks must absorb (proposal: 60 % of the faucet by day 30, 80 % of the cumulative faucet by day 60).
2. *Time-to-afford bands* for repricing (proposal for the Casual archetype: first extra pet slot / first field expansion on day 1-2, first
   incubator and Run Speed 3 by day 3-5, Double Jump with the Stage 2 medals, field expansion tiers about one a week, the last talents and
   unlocks after the last stage of their world, last field tier by day 60).
3. *Live players:* how many exist (probably only the developer and test accounts). If nobody has live pen income the migration collapses to
   "replace pens"; otherwise grandfather.
4. *Maximum field:* provisional ceiling of 150 squares for the model; the real limit comes from the plot-architecture decision (EXPANSION §12). The field step shows 24 squares are enough at ladder scale 0.15.
5. *Field size and ladder scale* (new, 2026-10-24): accept 24 squares at scale 0.15 (potato 12 / melon 216 Coins), or fewer squares with larger numbers (12 squares at about scale 0.3)?
6. *Casual as a garden-majority player* (new): 58 % of a 45-minute player's income is the field at the 0.95x A level; ROADMAP Q5 wants a majority only for Garden main. Accept, or lower the field to about 0.75x (below the 0.8-1.0 band).
7. *Placeholder sinks* (new): the sink share of open decision 1 holds only with ~1 M Coins of landmark / estate / decor sinks (E6 / E7); keep the share or lower it.

### E1.0 — Client-drawn plots spike (scope, 2026-10-24; before E1, after or alongside E0)
**Goal.** Decide GO / NO-GO on the plot architecture of EXPANSION §12: the server keeps only garden data, each client draws the plots it needs
(its own, others' within view distance at lower detail). A spike in the style of S3.1: small, measured, and it ends in a decision.

**Inputs.** Today's server drawing (`GardenService` pens and pet models, `GardenIncubators`), `GardenPlots` / `GardenConfig.NewAssigner`
(12 borrowed plots), `GardenClient` prompts, `HomeService` `GoGarden` (plot position), `PetFollow` (already client-rendered from attributes).

**Outputs.** A prototype `PlotView` (client module, behind an admin / Studio flag, the live garden untouched) that draws a plot from a plain
state table; a pure plot-position formula in `GardenConfig` (slot → CFrame, row / column) used by client and server; a test field of up to 150
squares with crop stand-ins; measurements; the decision with the numbers written into EXPANSION §12, plus a migration plan for E1 (what
replaces `Workspace.Garden.Plots`, the pens, the incubators and the sign).

**Boundary.** No crops economy, no DataStore changes, no new profile fields, no art pass (stand-in blocks only), no city: the layout question
(compact neighbourhood plus teleports vs a large walkable city) is decided from the measurements, not built. If NO-GO, the fallback is the
current server plots with more slots and E1 proceeds on them.

**Acceptance checks (hard)**
1. One plot is drawn on a client from a data table only: 6 pens with pet models, 3 incubators with a live countdown, a 150-square field with crop
   stand-ins; no server-built instance exists for it. Placing a pet through the existing remote changes the drawing within 1 s.
2. The plot-position formula gives 30 slots with no overlap and ≥ 8 studs between plots; the server computes the same position as the client
   (compared by a test), and `GoGarden` lands in front of the right plot without a plot model on the server.
3. Scale: with 30 plots' state in range, distance-based detail (full ≤ 120 studs, low detail ≤ 300, nothing beyond) keeps the drawn instances at
   **≤ 5 000** in total and no single build or update frame above 50 ms (builds are spread over frames); instance count, build time and memory are
   recorded for 1, 12 and 30 plots, in Studio and with the mobile emulation.
4. Interaction: a `ProximityPrompt` on a client-built part fires the server remote and the server accepts it only for the caller's own plot by
   position computed from the slot; a request from 100 studs away is rejected. Two clients (Server and Clients): B standing in B's plot is not seen
   inside A's plot, and each sees the other's pets.
5. Server cost: the server's Workspace gains no per-plot instances and the join of a 12-player test does not exceed today's profile load; a visit
   (client B views A's plot, same server) needs only A's data message.
6. Offline visit (design only, not built): the snapshot read is specified (key, compact encoding, size per garden at 150 squares, DataStore
   requests per visit against the budget) and its number is recorded.
7. The decision is written down: GO / NO-GO, the player cap it allows, the layout (neighbourhood + teleports or city) and the E1 migration list.

**Studio-only work.** The test field and stand-ins are built from code (nothing to author); note anything added by hand. Playtests need the
Server and Clients mode for check 4; `screen_capture` one call at a time.

**Status.** Scope only (not started).

### S8 — World 3 (design: STAGES §7.11 for S8.1)
- **S8.1 outputs:** `Workspace.World3.Stage11` (Triple Peaks: Triple ledges, a lift, a crusher ridge) and `Stage12` (Ice Rink: ice, crosswind, a pressure door,
  ledges onto ice), `StageConfig` entries (`requires` Triple Jump; World 3 opens with Stage 11: `Worlds[3].soon` removed), 16 challenge coins, the kit's
  `KitIce` (ObstacleKit), closed `SoonGate13..15` doors, the `World3East` lane divider.
- **Acceptance checks:** a baseline Triple Jump lands every Triple ledge and a maxed Double Jump (Run Speed 5 + Jump Height 3) does not; ice keeps momentum and
  slides you off a plate you stop on; the wind beam needs counter-steering; the door stays open long enough for a run across the ice track; the crushers kill and
  their gaps are safe; a run starts at the gate, every checkpoint fires, the finish ends it; World 3's hub gate follows the world rule (10 of 15 World 2 stars or
  buy Stage 11).
- *Studio check (2026-10-24):* see STAGES §7.11 → Checks. *Not checked:* the look, a human run / `T_base`, coin pickups, a normal player at the World 3 hub gate.

### M6a — First live test + World 1 balancing
The first live test (open checks below) with 6 stages, then M6 for World 1 (scope in "M6 — Balancing pass" below).

### S5–S11 (outline)
S5 worlds hub (gates for Worlds 2–4 in the hub, World 2 island, return / Home to the world) · S6 World 2 (S6.1 Double Up + Seesaw, S6.2
Turntable + Labyrinth, S6.3 Clocktower) · S7 Triple Jump + Dash (+ World 3 island) · S8 World 3 (S8.1 Triple Peaks + Ice Rink,
S8.2 Dash Bridge + Laser Lab, S8.3 Rising Tide) · S9 Wall Jump + Glide (+ World 4 island) · S10 World 4 (S10.1 Wall Climb +
Glide Canyon, S10.2 Moon Base + Clockwork, S10.3 Summit) · M6b final balancing · S11 bonus stages (S11.1 Darkness + Memory
path, S11.2 Stealth + Chase, S11.3 Giant room + Minecart).

**Prototype ahead of S8.2 (2026-10-22, Studio-validated, awaits the user's visual check):** the Laser Lab level the user drew
(keys + gates + spikes in a side-view room) is built as `Workspace.KeyArena` with `ArenaServer` / `ArenaClient` /
`ArenaConfig`; details, deliberate changes and the reach analysis are in STAGES §5.2. Checked in a playtest: spikes kill,
checkpoints respawn on the plates, keys / locks / gates / exit work per player, the `Side` camera zone and the key HUD
switch on inside the room. Not checked: how it looks (screen captures of the 3D view came back blank), a real run with the
Triple Jump talent (not built; the route was checked with a kinematic model). Open: its slot (stage 14 / World 3 needs S5 +
S7 first) and the `StageConfig` entry.

### P3 — Trading
- **Prerequisite:** profile session locking in `PlayerProfile` (`UpdateAsync` with a `{ JobId, Time }` lock instead of
  `SetAsync`; a profile locked by another live server is not loaded until released or stale).
- **Outputs (draft):** trade request → both players add pets / Coins → both confirm the final offer → server swaps
  atomically, saves both profiles immediately, writes a trade log; pets in an open trade are locked; cooldown.
- **Acceptance checks (draft):** changing the offer after a confirmation resets both confirmations; a player leaving
  mid-trade cancels it with no item moved; the same pet cannot end up in both inventories (also across a server
  crash right after the trade); a profile open on server A cannot be loaded for writing on server B.

### M6 — Balancing pass (run as M6a for World 1, M6b for all stages)
- **Outputs:** measured `T_base` per stage (H2 made every course 17–53 studs longer); finish-time telemetry (T1a / T1b); tuned numbers in GDD + `StageConfig` / `PetConfig` /
  `GardenConfig`.
- **Known items:** the repeat-reward floor (Tutorial loop ~1 400 Coins / h), pet bonus values, slot prices, the Basic egg's
  5-minute hatch time, garden production vs stage income.
- **Acceptance checks:** every stage has a measured `T_base`; GDD §6 economy constraint table still all ✔.

### M7 — Monetization
Deferred; scoped after M6 (GDD §8).

### MU — Mobile UX acceptance check (to be planned, noted 2026-10-24)
Decision (2026-10-24): Pawvest stays on Roblox and is treated as a **mobile-first game inside Roblox** (most Roblox playtime is on phones;
a standalone mobile port is revisited only if live retention / spend telemetry justifies it). So a mobile acceptance check must be planned
and scoped before the first public live test and before M7 (monetization UI); it gets its scope when it starts (workflow step 2).
- **To cover (draft):** touch layout of every panel and popup (Pets, Skills, Settings, garden, incubators, food stand, results, unlock
  prompts) at phone sizes, tap targets, safe areas / notch, Czech text length; touch controls for the obstacle kit and talents (the S7 touch
  button was never checked on a real phone); performance on a mid-range phone (many pets, 12-player garden, part counts); short-session
  feel of the first minutes; telemetry platform split (T1a) used to compare phone vs PC.
- **Acceptance (draft):** a checklist run on a real phone and on Studio's device emulator, results recorded here; absorbs the last item of
  "Open checks for the first live test".

## Ideas (unscheduled)
- **UI sounds.** The creator **SodaBreadle** on the Creator Store has many short free UI sounds (the level-up jingle
  `UI - Level Up`, asset `112485797063762`, is already `ReplicatedStorage.PetLevelUpSound`). Use more of them for menu feedback:
  button hover / click / select, panel open / close, buy success / fail (Pets, Skills, Settings, unlock popup, food stand,
  incubators, results popup). Find them through the creator's Creator Store page (a keyword search by creator name does not
  list them); check licence/free status and the length of each sound before using it, and keep volumes consistent. Use a
  shared client module with one Studio-only `Sound` per cue (like `ChallengeCoinSound` / `PetLevelUpSound`) so the code works
  when a sound is missing.
