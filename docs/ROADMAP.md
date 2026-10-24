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
- touch / mobile layout of every panel and popup.

Housekeeping (Studio): `ReplicatedStorage.StageTimerStopped` is unused and can be deleted.

## Next milestones

Stage expansion plan and design: [STAGES.md](STAGES.md) (catalogue, curve, worlds, talents, §8 milestone breakdown). Stage
milestones hold 2–3 stages each; every sub-milestone ends with a Studio check, the user's visual check and a commit.
Each milestone gets its scope when it starts (workflow step 2).

Pet-garden simulator (E0–E8, direction decided 2026-10-24, draft, nothing started): [EXPANSION.md](EXPANSION.md) §10–11 (game name **Pawvest**; the MVP
cut is E1 + E2 + hatch-time traits + first landmark and request board + basic ledger, then updates U1–U5). E0 (economy
model) comes first; E1 (beds and crops) is the first build milestone. They get their scope when they start.

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

## Ideas (unscheduled)
- **UI sounds.** The creator **SodaBreadle** on the Creator Store has many short free UI sounds (the level-up jingle
  `UI - Level Up`, asset `112485797063762`, is already `ReplicatedStorage.PetLevelUpSound`). Use more of them for menu feedback:
  button hover / click / select, panel open / close, buy success / fail (Pets, Skills, Settings, unlock popup, food stand,
  incubators, results popup). Find them through the creator's Creator Store page (a keyword search by creator name does not
  list them); check licence/free status and the length of each sound before using it, and keep volumes consistent. Use a
  shared client module with one Studio-only `Sound` per cue (like `ChallengeCoinSound` / `PetLevelUpSound`) so the code works
  when a sound is missing.
