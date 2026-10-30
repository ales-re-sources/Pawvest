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
| P1g | Pet stud restyle (Studio-only models) — all 8 kinds done 2026-10-25 (user picked the looks in Studio previews), eyes grow at half the body's rate; open: in-game check of followers, pens and portraits (Phoenix at Lv 20 in a pen) | ✔ | – | – |
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
| G1 | Player guidance hints (GDD §11): next-stage marker, Skills dot, ready-egg dot / marker / toast — built and Studio-checked 2026-10-27 (marker: orange arrow + stage name, drawn as a ScreenGui, on the screen edge when off screen); awaits the user's visual check in play | ✔ | ✔ | – |
| M6a | First live test + World 1 balancing | – | – | – |
| E0 | Economy model for the pet-garden expansion (scope written 2026-10-24; `tools/economy.py` loader, drift check, reproduction, report, day-by-day sim, crop field + guardrails A-C (43 checks green, provisional numbers in [ECONOMY.md](ECONOMY.md)) done; repricing, dead end, rare supply and sensitivity pending; [EXPANSION.md](EXPANSION.md) §15) | partial | – | – |
| E1.0 | Client-drawn plots spike — **GO** decided 2026-10-30 (EXPANSION §16 → Plot architecture): `PlotView` prototype behind a Studio flag, slot formula in `GardenConfig` (server `Usable` and `GoGarden` use it), checks 1-7 passed or measured (30 plots 4 802 instances worst case, frames ≤ 24 ms); open: mobile emulation / real phone, the 12-player join | ✔ | ✔ | – |
| S5 | Worlds hub — done 2026-10-22: gates for Worlds 2-4 (coming soon, admins only), World 2 courtyard, signs, per-world stars boards (user's visual check) | ✔ | ✔ | – |
| S6 | World 2 (stages 6–10) — S6.1 Double Up + Seesaw, S6.2 Turntable + Labyrinth, S6.3 Clocktower all built 2026-10-22 / 23, each crossed by a bot and one timed run paid out; Studio validation pending the open checks (course look, human difficulty / `T_base`, the user's Stage 9 run, door coplanar audit hits on `Stage9.Maze.Big.ExitDoor` and `Stage10.Movers.Door_10`, tick sound), see the S6 notes below; **the user declared World 2 done 2026-10-30** (open note: on Stage 10 both admin accounts hold only Bronze, 107 / 115 s against Gold < 60 s, so its tBase 75 needs one more look) | ✔ | ✔ | – |
| S7 | Talents: Triple Jump + Dash (+ World 3 courtyard) — done 2026-10-24: talents, Q / gamepad / touch button, reach table, World 3 courtyard east of the hub; closed 2026-10-24 (the visual and real-device touch checks were waived by the user; Live-validated comes with the next publish) | ✔ | ✔ | – |
| S8 | World 3 (stages 11–15) — S8.1 Triple Peaks + Ice Rink built and Studio-checked 2026-10-24 (kit ice, World 3 open), checked and tuned by the user 2026-10-26; S8.2 designed (STAGES §7.12: Long Dash = Dash level 2, kit `Roll` balls); S8.2a Stage 13 Dash Bridge built and bot-checked 2026-10-26 (awaits the user's check), S8.2b Stage 14 Laser Lab built and bot-checked 2026-10-26 (awaits the user's check; its Key Vault rebuilt as lanes 2026-10-28), S8.3 Rising Tide designed 2026-10-28 (STAGES §7.13), S8.3a (`KitTide` + segments 1-2) built and bot-checked the same day, S8.3b (segments 3-6, coins, finish on the summit) built and bot-checked the same day; the user ran all five stages (Gold on each) and medal times were set from those runs 2026-10-30 (tBase 55 / 50 / 45 / 95 / 55; Bronze 2.5 × tBase for every stage since the same day, GDD §4); awaits the user's sign-off of World 3 | ✔ | ✔ (S8.1) | – |
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

**P1g — Pet stud restyle** (recipe: [PET_GROWTH.md](PET_GROWTH.md) → Stud restyle). Studio-only model work, one kind at a
time: stud texture on the big main-colour parts, shaped ears / face / tail for detail. All 8 kinds done 2026-10-25; eyes
(attribute `Eye`) grow at half the body's rate for every kind (Lv 20: ×1.3 on a ×1.6 pet). Check per kind:
the follower at Lv 1 / 10 / 20 with each allowed accessory, the garden pen and the panel portrait look right.

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

Pet-garden simulator (E0–E11, direction decided 2026-10-24, draft, nothing started): [EXPANSION.md](EXPANSION.md) §14–15 (game name **Pawvest**; MVP
and drops D1–D10). E0 (economy model) and the plot-architecture spike E1.0 come first (scopes below); E1 is the first build milestone. They get their scope when they start.

**Order from 2026-10-30 (user review: Worlds 1–2 done, mobile reasonably playable with somewhat slower times than PC, E0's open
decisions can wait):**
1. **Close World 3:** the user's sign-off of Stages 11–15 with the new medal times; one more look at Stage 10's times.
2. **M6a as a soft launch** (friends, then unlisted) with the 15 stages, today's pets and garden: real finish times, the T1a / T1b
   telemetry, and a **retention baseline of the obby alone** to measure what the garden adds later. S9 / S10 (World 4) wait until after
   the garden MVP (drop D8). When S10 starts, re-check World 4's star bar: World 3's tighter Silver / Gold make 10 of 15 stars harder.
3. **In parallel:** E0 continues (repricing, dead end, rare supply, sensitivity, then the EXPANSION pieces: harvest rolls, fertilisers,
   tools, the Spender archetype); its open decisions are settled later and do not block E1.0 or E1a. The E1.0 spike.
4. **MU** as a short checklist before anything goes public (the user's phone runs are fine so far).
5. **The MVP** in milestones of about 1–2 weeks: **E1a** field, crops, catalogue, selling · **E1b** pens → posts, Gardener auto-replant,
   live-player migration · **E1c** size roll, tools tier 1, Renown, daily market cart · **E4-thin** crows + one Perimeter post · **E2** rare
   seeds from Worlds 1–3 · **E3 / E5** traits at hatch, request board · **ledger, onboarding, garden telemetry**.
6. **Drops D1–D10** (EXPANSION §14): Critters, Comfort shop (M7), Weekly, Variants, Kitchen, …
- Pending idea (2026-10-30, not decided): key talents as **world rewards** (Double Jump for finishing World 1, Dash for World 2), Coins buy
  the levels and the other talents; it removes two Coin sinks, so talent prices rise in the balancing pass (STAGES §6, GDD §6).

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
**Inputs (new, EXPANSION §5-§12).** The crop ladder (tiers, grow time, sale price, seed cost 20-30 %), the **field** (a grid of squares the
player plants freely, see below), field expansion and upgrade prices, Gardener auto-replant coverage (squares per Gardener pet and the
number of Gardener posts), seed stock, Renown gates, station multiplier (1.5-2×), request board (3 a day), the first landmark (Kitchen) bundle.

**Field model (decided 2026-10-24, replaces "6 beds").** The garden has one **field** made of squares; the player puts any unlocked crop
on any square. Capacity comes from the number of squares (expansion tiers of the field, bought with Coins and Renown), not from a fixed
bed list, and the crop catalogue size becomes a content question rather than a structural one: the model takes any crop list. Parameters:
squares per expansion tier and their prices, the upgrades (for example faster growth, a barn, more Gardener coverage), optional crops
that cover 2 × 2 squares (giant melon, trophy pumpkin). The plot geometry is **not** a constraint of E0 (decided 2026-10-24: the plot area and layout will be reworked, and the architecture may move
to client-drawn plots, see EXPANSION §16 "Plot architecture"): the maximum field is a model parameter with a provisional ceiling
(proposal: 150 squares; **decided 2026-10-25: 12 squares at ladder scale ~0.3**) that the plot rework must be able to draw. E0 outputs the minimum catalogue that makes the ladder work (at least one crop per tier
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
- EXPANSION §5 / §12 and GDD §6-§7.6 updated with the final ladder, prices and guardrail numbers (GDD first, per the workflow rule).
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
(4 free, 8 expansion tiers up to 12 squares), visit-based harvest (one per square per visit, ripe crops wait), Green-thumb Gardener pets on Field posts that re-cycle their squares between visits from a seed
stock and barn, seeds as a real cost, sales through the pet multiplier, Renown as a derived level, a rare-seed drip from the obby, upgrades (growth, barn; a Gardener coverage level was dropped because one more square per Gardener would cover the whole 12-square field) and a placeholder
ladder for the sinks that are not designed yet (landmarks / estate / decor). `--garden pens|field|both` switches between today's pens, pens-become-posts and grandfathered pens. 43 checks pass in
about 3 s, including A (24-hour rule on every day, every archetype x policy), the A target band, B, C, the Obby main garden share and the online / offline rule (below). Findings:
- **The EXPANSION §5 ladder (20 / 45 / 90 / 150 per square-hour) only fits 4-7 squares** under the 24-hour rule at the last stage (first obby hour 10 188). Squares x scale is what the rule limits (150 squares would need scale 0.04, 24 squares 0.24).
  **Decided 2026-10-25 (open decision 4): 12 squares at ladder scale 0.3 (6 / 13.5 / 27 / 45 per square-hour), 4 free squares + 8 expansion tiers; the plot rework needs to draw only 12 squares.** The online ceiling reaches
  0.95x for Obby main and Casual, 0.87x worst for Garden main (0.76x at day 60), 0.27x for Binge (its Renown stays below the tier-3 gate). About half of it is the Gardener part. A is linear in the ladder scale (+20 % -> 1.14x), and also
  sensitive to squares per Gardener (2 -> 1.06x), the growth upgrade and the tier-3 gate (25; 12-15 gives 1.28x early): flag them for M6a telemetry.
- **Catalogue:** six crops (Potato, Pumpkin, Giant melon + one rare per world) pass every check; the recommended MVP is **seven** (+ Corn, the 6 h slot, +10 % for Obby main). Carrot, Radish and a 2 x 2 crop add under 1 %.
- **B holds, with a thin margin under the online / offline rule:** with / without Gardeners the net per day is 6.6k / 6.2k (Obby main, +7 %), 4.7k / 4.1k (Casual, +15 %), 4.3k / 3.9k (Garden main, +10 %), 0.32k / 0.27k (Binge, +21 %); B flips with two parameters in the sensitivity run, so the Gardener needs a bigger edge by design (not by more coverage, which breaks A).
- **C needs content that does not exist yet:** existing sinks plus the field absorb 36 % (Obby main) / 68 % (Casual) of the faucet by day 60; the 80 % proposal needs ~0.76 M / 0.10 M Coins of landmark / estate / decor sinks
  (the placeholder ladder supplies them; the check prints both values). Garden share of income: Obby main 25 %, Casual 32 %, Garden main 73 % (the only majority, as Q5 wants), Binge 7 %.
- **Pens:** grandfathering them (`--garden both`) breaks A (worst day 2.2-2.7x) and puts Obby main's garden share at 53 %: the model supports replacing the Coins-per-hour production when posts arrive.
- Rare seeds from the obby: 7-9 a week for Obby main / Casual, 2-3 for Garden main / Binge.

**Online vs offline rule (user, 2026-10-24; EXPANSION §2).** Offline income must exist, but online income, even passive, is much higher so players keep Roblox open. The model has the parameter pair
`online_rate` 1.0 / `offline_rate` 0.33 (online ~3x; **the number is an open decision**) and a field offline cap (`offline_cap_h` 12 h, provisional; pens keep 8 h). It scales all passive income: crop growth (a long crop may
span several visits), Gardener replanting, and the pen production kept for comparison. Roblox no longer pays for uptime (Engagement-Based Payouts ended 2025-07-24), so nothing is modelled as a payout and nothing is paid for pure AFK.
Guardrail A is checked for the online case (the ceiling does not depend on the rates); the new check `O` requires garden income per online hour >= 1 / `offline_rate` x per offline hour and some offline income:
Obby main 3.3x, Casual 3.5x, Garden main 3.2x, Binge 59x. Consequences: the field's realised net per day falls to 6.6k / 4.7k / 4.3k / 0.3k (about half to two thirds of the unweighted 13.9k / 13.9k / 12.7k / 0.4k for the active
archetypes), only 13-36 % of garden income is earned online (online hours are 1-3.5 of 24), **Binge is almost cut off** (one session a week, a 12 h cap: field 0.3k a day, garden 7 % of income) and Garden main stays at 0.30x of the
first obby hour. Levers: the cap (24 h lifts only Binge, to 0.4k) and the rate (0.1 makes online the majority for Obby main, 67 %, but halves the field income again; 0.5 puts A at 1.00x). Pens would drop from 21.5 to 9.4 paid hours a day (Obby main).
**Done when** `check` is green, `docs/ECONOMY.md` and the GDD / EXPANSION edits are committed, and the user has confirmed the ladder, the
price proposal and the pen-income migration. E0b (applying the prices) is a separate small milestone. Status: in progress (baseline, simulation and field steps done; field retuned to 12 squares on 2026-10-25; repricing next).

**Decided:** form = script (2026-10-24); the garden is one free-form field of squares (not fixed beds); guardrail = the 24-hour rule (check 4), measured against the **first obby hour of a fresh day** (about 2 230; the later steady hour is only reported).

**Open decisions (confirm before starting)**
1. *Sink share:* the fixed share the sinks must absorb (proposal: 60 % of the faucet by day 30, 80 % of the cumulative faucet by day 60).
2. *Time-to-afford bands* for repricing (proposal for the Casual archetype: first extra pet slot / first field expansion on day 1-2, first
   incubator and Run Speed 3 by day 3-5, Double Jump with the Stage 2 medals, field expansion tiers about one a week, the last talents and
   unlocks after the last stage of their world, last field tier by day 60).
3. *Live players:* how many exist (probably only the developer and test accounts). If nobody has live pen income the migration collapses to
   "replace pens"; otherwise grandfather.
4. ~~*Maximum field*~~ **Decided 2026-10-25:** 12 squares at ladder scale about 0.3 (potato 24 / melon 432 Coins), so the plot rework draws 12 squares (EXPANSION §16; the E1.0 spike below may keep its 150-square stress test as headroom).
6. *Placeholder sinks* (new): the sink share of open decision 1 holds only with ~0.8 M Coins of landmark / estate / decor sinks (E6 / E7) for an Obby-main player; keep the share or lower it.
7. *Online / offline numbers* (new, 2026-10-24): `offline_rate` 0.33 and the field offline cap 12 h are placeholders (the user gave no number). Choose the rate (0.2 stronger, 0.5 gentler) and the cap (24-48 h helps only Binge).

### E1.0 — Client-drawn plots spike (scope, 2026-10-24; before E1, after or alongside E0)
**Goal.** Decide GO / NO-GO on the plot architecture of EXPANSION §16: the server keeps only garden data, each client draws the plots it needs
(its own, others' within view distance at lower detail). A spike in the style of S3.1: small, measured, and it ends in a decision.

**Inputs.** Today's server drawing (`GardenService` pens and pet models, `GardenIncubators`), `GardenPlots` / `GardenConfig.NewAssigner`
(12 borrowed plots), `GardenClient` prompts, `HomeService` `GoGarden` (plot position), `PetFollow` (already client-rendered from attributes).

**Outputs.** A prototype `PlotView` (client module, behind an admin / Studio flag, the live garden untouched) that draws a plot from a plain
state table; a pure plot-position formula in `GardenConfig` (slot → CFrame, row / column) used by client and server; a test field of up to 150
squares with crop stand-ins; measurements; the decision with the numbers written into EXPANSION §16, plus a migration plan for E1 (what
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

**Status.** Done 2026-10-30, **GO** (decision, cap, layout and E1 migration list: EXPANSION §16 → Plot architecture). Built: `PlotView.luau` +
`PlotViewSpike.client.luau` (client), `PlotViewSpike.server.luau` (data feed), `GardenConfig.PlotRing` / `PlotCFrame`, `tools/plot_formula_test.luau`;
`GardenService.Usable` and `HomeService` `GoGarden` now take the plot position from the slot (no plot model). The spike runs only in Studio while the
Workspace attribute `PlotViewSpike` is true (admins and Studio test users); the live garden is unchanged with it off. Results (Studio, 2026-10-30):
1. **Pass.** The own plot drawn from data only (5 pets, ready egg, locked pen 6 / incubator 3, 12-square field): 305 instances, built in 6 ms; the
   Studio plots are hidden on that client only. Remove / Place through the existing remotes redrew the pen in 97-107 ms (also under the 30-plot load).
2. **Pass with a layout finding.** `PlotCFrame(1..12)` = the Studio plots (0.0000 studs, rotation exact); server and client hash of all 30 slots equal
   (769875742); `GoGarden` lands at floor space (8, 0, -30) facing the plot without a plot model. Gaps (`tools/plot_formula_test.luau`): **today's ring 1 has
   only 2.77 studs** between neighbouring plots' inner corners (fails the 8-stud rule; ring 1 ↔ ring 2 28.4, ring 2 12.7, with the field behind ring 1:
   10.1); the E1 proposal (ring 1 at radius 112, ring 2 at 185) passes: 8.99 / 31.5 / 17.9 (13.3 with the field).
3. **Pass at 12 squares, fails at the 150-square stress field.** Instances (full / low plots), build work per frame, longest frame, build time:

   | Standing at | Plots | Field | Instances | Full / low | Max step | Max frame | Build |
   |---|---|---|---|---|---|---|---|
   | own plot | 1 | 12 | 305 | 1 / 0 | – | – | 6 ms |
   | own plot | 12 | 12 | 1 709 | 5 / 7 | 6.9 ms | 17 ms | 55 ms |
   | own plot | 30 | 12 | 4 373 | 10 / 20 | 7.6 ms | 18 ms | 217 ms |
   | own plot | 30 | 150 | 6 863 | 10 / 20 | 7.2 ms | 18 ms | 249 ms |
   | garden centre | 12 | 12 | 4 400 | 12 / 0 | 7.3 ms | 18 ms | 188 ms |
   | garden centre | 30 | 12 | **4 802** | 12 / 18 | 7.2 ms | 18 ms | 218 ms |
   | garden centre | 30 | 150 | 7 779 | 12 / 18 | 7.3 ms | 18 ms | 269 ms |

   Walking half a ring and out to 420 studs (detail changes): max step 7.5 ms, max frame 18 ms, peak 4 479 instances; a Place / Remove under the
   30-plot load 1.3 ms of build work, worst frame 24 ms (Studio runs server and client in one process). Memory 0 → 30 plots: about +6 MB total
   (PhysicsParts +3.7, GraphicsParts +2.0, Instances +1.0 MB). Where the instances go (12 full plots): pens with pet models 3 734 of 4 802 (78 %), field rows
   285, incubators 210, base 132; 18 low plots 402 together (22 each). **Mobile emulation: not measured** (neither client window had the device emulator on;
   it changes only screen size and input, not CPU / GPU, so the phone number comes from a real-device run in E1a / MU).
4. **Pass.** A client-built pen prompt (real E key; `ProximityPrompt:InputHoldBegin()` from a script does not trigger it) opened GardenClient's pen panel,
   which fires the existing remotes; the server accepted the own plot and answered "far" from 100 studs and from inside neighbour plots 2 and 12
   (52 studs). Server and Clients (Player1 slot 1, Player2 slot 2, each with a hatched pet placed in pen 1): each client drew the other's plot with that
   pet (Cat / Bunny), each character stood inside its own plot and not the other's, prompts only on the own plot.
5. **Pass (12-player join not run).** Server Workspace 13 462 instances with the flag on and 30 plots on the client: no plot instance on the server.
   The feed makes no DataStore request; one message per garden change, 114-153 B (254 B for a full 6-pen / 3-egg garden); a visit on the same server
   needs only that message. A 12-client join was not run: by the code a join costs N such messages (about 3 KB at 12 players) and no extra profile read.
6. **Designed** (EXPANSION §16): snapshot key `GardenSnapshots` / `garden_<UserId>`, about 0.3 KB at 12 squares and 0.9 KB at 150; 1 read per visit,
   ≤ 1 write per 5 min per player.
7. **Written** (EXPANSION §16 → Plot architecture).
Open: a real-phone measurement, a 12-client join, the "mid" pet detail (needed before larger fields).

### S8 — World 3 (design: STAGES §7.11 for S8.1)
- **S8.1 outputs:** `Workspace.World3.Stage11` (Triple Peaks: Triple ledges, a lift, a crusher ridge) and `Stage12` (Ice Rink: ice, crosswind, a pressure door,
  ledges onto ice), `StageConfig` entries (`requires` Triple Jump; World 3 opens with Stage 11: `Worlds[3].soon` removed), 16 challenge coins, the kit's
  `KitIce` (ObstacleKit), closed `SoonGate13..15` doors, the `World3East` lane divider.
- **Acceptance checks:** a baseline Triple Jump lands every Triple ledge and a maxed Double Jump (Run Speed 5 + Jump Height 3) does not; ice keeps momentum and
  slides you off a plate you stop on; the wind beam needs counter-steering; the door stays open long enough for a run across the ice track; the crushers kill and
  their gaps are safe; a run starts at the gate, every checkpoint fires, the finish ends it; World 3's hub gate follows the world rule (10 of 15 World 2 stars or
  buy Stage 11).
- *Studio check (2026-10-24):* see STAGES §7.11 → Checks. *User's check (2026-10-26):* both stages played, look and difficulty accepted after the tuning
  (Ice Rink door swing, button moved, door time 8.5 s, checkpoint `1004` removed). *Still open:* the real `T_base` (M6b), a normal player at the World 3 hub gate.
- **S8.2 (design check: STAGES §7.12):** `Stage13` Dash Bridge and `Stage14` Laser Lab (the `KeyArena` prototype moved into World 3 as its first room).
- **S8.2b Laser Lab (design accepted 2026-10-26; built and bot-checked the same day, STAGES §7.12 → "as built" / "Checks"; awaits the user's check;
  the colour climb became an enclosed hatch shaft, sweepers turn with the walker, the finale bay is 54 high):** outputs: `Workspace.World3.Stage14`
  (gate / board / `Arrival`, entry hall, room 1 Key Vault = the arena turned 180°, the Cooling Deck with Long Dash gap 1, room 2 Beam Hall: laser grid,
  sweepers, colour climb, Long Dash gap 2 through a beam, balcony + finish portal), `StageConfig` entry (`requires` Triple Jump + Long Dash, `tBase` 135,
  factor 4.0, Bronze on Stage 13 or 5 500; `economy.py check`), 8 coins `Stage14_1..8`, `ArenaServer` / `ArenaClient` integration (keys reset at run
  start, stage checkpoints `1201`-`1206`, `KitKill` spikes), `SoonGate14` and `Workspace.KeyArena` removed.
  Acceptance checks: Triple Jump + Long Dash completes the stage and baseline Triple Jump + short Dash does not cross either 34 gap; floor -> platform A
  works for the bot at least two tries in three; the grid wave can be walked and every pocket between beams is safe; the sweepers' safe spot is safe;
  a wrong toggle drops the player to the shaft floor and the floor pad resets the colours; keys and gates reset at a new run, not at a death; the side
  camera never shows Stage 13 parts in front of the lane; a baseline Triple Jump + Long Dash cannot reach the talent coin, Jump Height 3 can; a full run
  fires `1201`-`1206` in order and ends with a result.
  - **Vault lanes (2026-10-27/28, the user's sketch; built and bot-checked, awaits the user's check; STAGES §7.12 → "Vault lanes"):** room 1 rebuilt
    as stacked lanes (98 high on the left), teal hatches that open with the key, a barrier that shuts behind it, two colour switches and 16-stud
    stepping stones, so the only route is the user's (the "floor -> platform A" route above no longer exists). Acceptance: `tools/vault_reach.py`
    finds no shortcut at max talents and a route at baseline; a human run follows the sketch and must cross the dash corridor twice.
  - **Vault tower (2026-10-28, the user's second sketch; built, model- and bot-checked, awaits the user's check; STAGES §7.12 → "Vault tower"):**
    the green-key half rebuilt as a switchback of six ledges 9.5 apart (first ten, then six 15.8 apart: too long, then too easy; room
    back to 65 high), a ceiling spike in the top lane, the key in a notch at the
    slot floor, a green hatch that opens with the key held as the way back down; the bounce orb is gone (appearing steps were tried and taken out).
    Acceptance: `bash tools/vault_right_checks.sh` passes; a human climb follows the sketch and can jump-dash every ledge spike.
- **S8.3 Rising Tide (design check: STAGES §7.13, drafted and accepted 2026-10-28 with every recommendation; S8.3a and S8.3b built and
  bot-checked 2026-10-28, await the user's run; STAGES §7.13 → "S8.3a / S8.3b as built" / "checks"):** the World 3 finale on the courtyard's
  south opening (`SoonGate15`), course running south and back north high: a lava tide (new client script `KitTide`, kit-local, reset to each
  checkpoint's `TideFloor` and rising at its `TideSpeed`) under six segments that replay World 3's signatures (crusher ice ridge + Triple ledges,
  Long Dash gaps + axe, gusting headwind + timed door, a colour-hatch shaft the lava fills, a rolling-ball ramp + sweeper + last Long Dash gap).
  Outputs: `Workspace.World3.Stage15` (gate / board / `Arrival` from `StageKit`, checkpoints `1301`-`1306`, `Tide`), `StageConfig` entry
  (Triple Jump + Long Dash, `tBase` 100 provisional, factor 4.25, Bronze on Stage 14 or 5 500; `economy.py check`), 8 coins `Stage15_1..8`,
  `KitTide.client.luau`, `SoonGate15` removed. Proposed split: S8.3a `KitTide` + segments 1-2 (the user looks at the tide alone), S8.3b the rest.
  Acceptance checks: STAGES §7.13 → "Acceptance checks" (tide only during a run, checkpoint / respawn reset, the budget rule with a clean bot and
  one with a lost hazard cycle per segment, Long Dash gates, telemetry `Stage15.Tide`, full run `1301`-`1306`, coplanar audit clean).

### G1 — Player guidance hints (design: GDD §11; scope 2026-10-27, user request)
A player who finished a stage did not know where to go next (in World 1 the big wooden world sign hides the gates across the
courtyard); affordable skills and ready eggs were not signalled either. Phase 1 of one hint system.
- **Inputs:** player attributes `Medal_<folder>`, `Unlocked_<folder>`, `Talent_<id>`, `GardenPlot`, `OpenPanel`; leaderstats
  `Coins`; the incubator models' `State` / `ReadyAt` on the own plot; `StageTimerUpdate` (run active / ended); `PetsGui.Open`.
  Area rectangles from the scene: each world courtyard's `Wall` folder, the hub (`StartLocation`), the garden (`Garden`), the
  Tutorial's landing pad.
- **Outputs:** `StarterPlayerScripts/Hints.luau` (module: HUD dots, world markers, toast, run state; re-attaches dots to the
  icons after a respawn re-creates the ScreenGui), `StarterPlayerScripts/HintSources.client.luau` (the three phase-1 hints);
  strings `hints.ready`, `hints.eggReady` (the next-stage marker shows the stage's name). No server change, no remote, no Studio-only change.
- **Boundary:** display only (nothing is sent to the server); no in-panel highlight beyond the existing green Buy brick; the
  later hints of GDD §11 are not part of G1.
- *Studio check (2026-10-27, one playtest, live profile snapshotted and restored):* checks 1-8 passed. Next = Stage 2 (the profile's
  state): marker above Stage 2's sign from across the courtyard (capture: clear of the World 1 sign), on the bottom edge pointing
  down with the gate behind, hidden at Stage 2's `Arrival` (12 studs), hidden while a `StageTimerUpdate` run was active and back
  after the cancel; in the hub it stood on the World 1 gate, with `Medal_Tutorial` 0 (local) on the Tutorial's hub portal, with
  every open stage medalled (local) nowhere. Skills dot: off with the seen levels, on at 3 500 Coins (local) for Double Jump,
  cleared by `OpenPanel` = SkillsPanel, off again at 3 600, on at 5 500 (Dash), kept through a respawn. Egg: a real egg became
  ready during the test (Pets + "Go to my garden" dots, toast once, "Ready!" marker in the garden replacing "Next"); a hatched
  (local `State`) or incubating egg cleared everything. Czech and pseudo texts fit (marker label, two-line toast); 0 console
  errors or warnings. The first build drew the marker as an `AlwaysOnTop` BillboardGui, which did not show in the captures (one
  without `AlwaysOnTop` did, but the sign covered its label): the marker became a ScreenGui frame placed at the projected point.
  *Not checked:* the Skills panel opened by a click (the attribute was set directly), a real hatch through the panel.
  *Marker redesign (2026-10-27, user review):* the green disc with a chevron read as a tick ("done"), so the marker became an
  orange arrow labelled with the stage's name (`hints.next` removed), and a target behind the camera moved from the bottom edge
  (under the touch controls, "down" says no direction) to the side edge of the shorter turn. Re-checked in a playtest (profile
  snapshotted and restored): with Stage 3 next, captures show the arrow on the left edge with the gate behind, on the right edge
  pointing right with the gate ahead-right, above the gate pointing down when facing it; hidden 12 studs from the gate and during a
  run; the egg marker reads "Ready!" / "Hotovo!"; 0 console errors.
  *Aim fix (2026-10-27, user's playtest):* close to a gate, looking up, the point above the sign left the screen and the edge
  arrow pointed up at the top of the gate. The arrow now aims at the target at the player's height; while that spot is in view
  left to right it stays above it pointing down, pinned under the top of the free area. Checked with a scripted camera 14 studs
  from Stage 3's gate (the point above the sign at y -24 on screen): arrow at y 188 pointing down at the doorway (capture);
  turned away it pointed sideways (left edge 87°, right edge 270° with the gate behind); 0 errors; profile restored.
  *Latest open stage (2026-10-27, user decision):* the next stage changed from the first open stage without a medal to the
  latest one, and courtyards of other worlds / the Tutorial point at their portal back to the hub (the garden at the hub
  entrance). Checked in a playtest via the marker's `Target` attribute (profile snapshotted and restored): the profile as is
  (Stage 7 latest) gave World 1 / World 3 / Tutorial -> their return portals, World 2 -> Stage 7's gate, hub -> the World 2
  gate, garden -> the ready egg (without it: the hub gate); local attributes for check 9 gave "Stage 6" on World 1's return
  portal and Stage 6's gate, then "Stage 5" on its gate; 0 errors.
  *Star-bar fallback (2026-10-27, user decision after an edge-case review):* with Bronze on every stage of a world the player
  has 5 of the 10 stars the next world needs, every open stage has a medal and the marker used to disappear right where the
  player is stuck. It now points at the stage to raise (check 10, string `hints.raiseMedal`). Checked in a playtest with local
  attributes (profile snapshotted and restored): every case of check 10 as written, World 1 all Gold but Stage 4 Silver ->
  "Stage 4: Gold", everything open and medalled -> no marker; the profile as is still gives "Stage 7"; 0 errors.
- **Acceptance checks:**
  1. Finishing Stage 2 with a medal (Stage 3 open, no medal) shows the marker labelled "Stage 3" above Stage 3's gate sign,
     drawn over the World 1 sign when the sign is between the camera and the gate (screen capture from Stage 2's `Arrival`);
     with the gate off to one side it sits on that screen edge pointing at it, with the gate behind the camera on the left /
     right edge of the shorter turn, the label level and towards the screen centre.
  2. Walking to within 25 studs of the marked gate hides the marker; walking back out shows it again.
  3. While a run is active no world marker is shown (checked on the marker frame's `Visible`); after the finish or Home it returns.
  4. A player with every open stage medalled and no world shut by its star bar has no next-stage marker anywhere; a player with no Tutorial medal sees it above the
     Tutorial's hub portal while in the hub.
  5. In the hub the marker stands above the hub gate of the next stage's world and no stage-gate marker is enabled; in another
     world's courtyard it stands above that courtyard's return portal.
  9. The next stage is the latest open one without a medal: with Stages 5 and 6 open and neither medalled the marker reads
     "Stage 6" (World 1: on its return portal; World 2: on Stage 6's gate); with Stage 6 medalled and Stage 7 shut it reads
     "Stage 5".
  10. Every open stage medalled and the next world shut by its star bar: the marker goes to the stage of the counted world with
     the lowest medal (ties: the earliest) and names the medal to reach. World 2 shut, World 1 at Gold / Gold / Bronze / Gold /
     Bronze reads "Stage 3: Silver" (on Stage 3's gate in World 1, World 1's hub gate in the hub, World 2's return portal);
     Stage 3 at Silver moves it to "Stage 5: Silver"; World 3 shut with World 2 all Bronze reads "Stage 6: Silver"
     ("Úroveň 6: Stříbro" in Czech).
  6. Coins rising past a talent's next price lights the Skills dot; opening the Skills panel clears it; it stays off while
     the Coins stay the same and lights again only when another level becomes affordable; a respawn keeps it (re-attached).
  7. An egg on the own plot whose `ReadyAt` has passed shows the dot on the Pets icon and on "Go to my garden", the "Ready!"
     marker above that incubator in the garden, and the toast once (not again a second later); hatching it clears dot and
     marker. An egg still incubating shows none of them.
  8. Every new text in Czech and in the pseudo-language: no literal, no cut-off text; `loc.py check` 0 errors, lint within the
     baseline; no new console errors.

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
Comfort only, decided 2026-10-25 (GDD §9, EXPANSION §13: no paid random items, luck never sold); ships as drop D2 after the MVP.

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
