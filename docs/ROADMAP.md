# Oby sandbox — Roadmap

Design lives in [GDD.md](GDD.md); this file is the build order and status. "What next?" is answered from here.
Finished milestones are summarised in a few lines each. Their full scopes, acceptance checks and validation logs are in
git history (last full version: `git show f27c0b7:docs/ROADMAP.md`).

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
| P3 | Trading | – | – | – |
| M6 | Balancing pass | – | – | – |
| M7 | Monetization | deferred | | |

Order rationale: H2 (checkpoint redesign, user request) comes first. P3 needs profile session locking (its first step). M6 needs the full loop, garden included, and is best
done after a first live test (real finish times). M7 is scoped after M6. Nothing is live-validated yet: the open checks
below belong to the first live test.

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

### H2 — Stud checkpoints (user request 2026-10-20)
- **Inputs:** concept D picked from the Studio mock-ups; the user chose a real, almost-square plate and moving the
  courses to make room. Every stage runs along −Z, 16 studs wide; each checkpoint (`<number>`: `C` + Script, red 16 × 6
  `Part`, `T`, `CC`, `arrow`) sits directly between two obstacles.
- **Outputs (Studio-only):**
  - `C` is the whole plate, 16 × 1 × 12, cream stud plastic (`Studs` variant), top at the old platform top; it keeps the
    upstream edge and grows 5.84 studs downstream. `Part`, `T`, `CC`, `arrow` deleted.
  - `Core` (3 × 3 green stud tile set into the plate; no collide / touch / query) with a `PointLight` (off) and `Beam`
    (Neon cylinder, invisible; no collide / touch / query / shadow).
  - Course move per stage: every part downstream of a checkpoint moves −Z by 5.84 per checkpoint passed (obstacles,
    coins, dividers, finish portal, course models nested in checkpoint models). Stage1 +52.6, Stage2 +29.2,
    Stage3 +23.4, Tutorial +17.5 studs.
  - Template `ServerStorage.StageKit.Checkpoint`; `Workspace._CheckpointConcepts` deleted.
- **Outputs (code):** `CheckpointReached(part, first)` fired whenever the respawn point changes (`first` = first reach in
  the run → sound), the new runtime remote `CheckpointsReset` (fired by `NewRun`, which also forgets the last checkpoint);
  a `TimerStart` touch counts as the stage's lowest-numbered checkpoint (one sound for gate + first plate, respawn on the
  plate). `CheckpointClient` (renamed from `CheckpointSound`): only the current checkpoint glows — in 1 s the core grows
  3 → 7 and turns Neon, the light fades in, the beam rises (~18 studs); the previous one goes back to small in 0.4 s.
- **Boundary:** `StageConfig.tBase` and recorded times stay (the courses are 1–3 s longer; M6 measures `tBase`).
- **Acceptance checks:**
  - 21 checkpoint models, each exactly `C` (16 × 1 × 12, Script) + `Core` + `Beam`; no `Part` / `T` / `CC` / `arrow` left;
  - every plate's gaps to its neighbours equal the old ones; no part overlaps a plate; every coin moved with its obstacle;
  - walking the Tutorial (real `MoveTo`) activates 23, 24, 25 once each with one sound each; a second pass in the same
    run animates nothing; dying respawns on the last plate; a new run turns every pad small again;
  - Stage1 checkpoints 1 → 9 all activate in order and the finish portal still ends the run;
  - another player's reached pads do not change on this client; no new console errors.
- **Validation (2026-10-20):** edit mode — 21 models each `C` 16 × 1 × 12 + Script + `Core` + `Beam`, no old parts left,
  nothing overlaps a plate, every plate's gaps equal the survey (0.5 / 4.0 / 4.5 / 5.0 / 5.5 / 8.5 / 11.0 / 12.0 studs),
  the 8 off-course coins kept their place next to their obstacles; template `ServerStorage.StageKit.Checkpoint`.
  Playtest — Tutorial: walked (`MoveTo`, jumps) onto 23, 24, 25: one event each, core 3 → 7 Neon, light 0 → 2, beam
  0 → 18 in 1 s; a second pass and a death fired nothing; respawn on plate 25. Stage1: the new run reset 23–25 to small,
  1 → 9 activated in order, the finish portal ended the run (results popup). Console: no errors. The test's live writes
  were undone: profile restored identical (deep compare), its Stage 1 Top-10 entry removed, `MostStars` back to 0.
  Not covered: a second client (another player's pads), left for the first multi-client test.
- **User review (2026-10-20):** look approved; three changes asked for and done: only the current checkpoint glows,
  the start gate no longer plays its own sound (it counts as the first checkpoint), and confirmed per-player only.
  Retest — events: gate → 23 one event (first); stepping on 23 nothing; 24 first; back to 23 / 24 silent (`first=false`);
  death nothing, respawn on 24; Stage1 gate: reset + 1 (first); Home from checkpoint 1 and back through the gate: reset +
  1 (first) again. The pad tweens could not be watched in this run (Studio rendered 0 frames in the background, so
  tweens stood still); the tween code is the one validated above, the switch-off of the previous pad is for the user's
  visual check. Profile restored identical; boards untouched.
- **Bounce bricks (Stage2 Level 12, found in the user's test):** the move kept them rigid (same 17.52-stud shift as
  their level, checkpoint 12 and the ramp), but their old server-side conveyor `Velocity` (900 / 600 / 1 300) launched
  anywhere from ~35 to ~1 000 studs depending on the landing. Now each brick's script only declares `LAUNCH_SPEED`
  (Brick_2 360, Brick_1 365, Brick_3 500; ~3.6 s / ~5 s of flight) and `BounceBricks.client` sets the local character's
  velocity on touch. Playtest (client `MoveTo` steering): peaks +334 / +339 / +639 every time; at WalkSpeed 16 plate 12 →
  Brick_2 → Brick_1 → Brick_3 → ramp → plate 13, at 26 straight onto plate 13. Profile restored identical.
- The user's check of the checkpoints and Stage 2 passed; place saved (2026-10-20).
- `src/ServerStorage/StageKit/…`: Argon wrote the template's script copies on the Studio reconnect (identical to the
  stage scripts); committed with H2.

### P3 — Trading
- **Prerequisite:** profile session locking in `PlayerProfile` (`UpdateAsync` with a `{ JobId, Time }` lock instead of
  `SetAsync`; a profile locked by another live server is not loaded until released or stale).
- **Outputs (draft):** trade request → both players add pets / Coins → both confirm the final offer → server swaps
  atomically, saves both profiles immediately, writes a trade log; pets in an open trade are locked; cooldown.
- **Acceptance checks (draft):** changing the offer after a confirmation resets both confirmations; a player leaving
  mid-trade cancels it with no item moved; the same pet cannot end up in both inventories (also across a server
  crash right after the trade); a profile open on server A cannot be loaded for writing on server B.

### M6 — Balancing pass
- **Outputs:** measured `T_base` per stage (H2 made every course 17–53 studs longer); finish-time telemetry; tuned numbers in GDD + `StageConfig` / `PetConfig` /
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
