# Oby sandbox — Roadmap

Design lives in [GDD.md](GDD.md); this file is the build order and status. "What next?" is answered from here.
Finished milestones are summarised in a few lines each. Their full scopes, acceptance checks and validation logs are in
git history (last full version: `git show daba6d7:docs/ROADMAP.md`).

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
| M6a | First live test + World 1 balancing | – | – | – |
| S5 | Worlds hub (world gates, World 2 island) | – | – | – |
| S6 | World 2 (stages 6–10) | – | – | – |
| S7 | Talents: Triple Jump + Dash | – | – | – |
| S8 | World 3 (stages 11–15) | – | – | – |
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
Only S1 is scoped in full; the others get their scope when they start (workflow step 2).

### S1 — Stage framework
- **Design check (first) — DONE 2026-10-21** (docs only; answers recorded in STAGES §9, GDD §3–6 updated). Decided with
  the user: Stage 3 factor **1.75**; challenge-coin values **stay flat** (no scaling, the S1.1 bullet below is void);
  world openers (6, 11, 16) need **10 of the 15 stars of the previous world** or the price, which needs a **new unlock rule
  type** (`unlock = { world, stars }`) in S1.1 / `StageUnlocks`; all other §9 recommendations adopted. Scope as written:
  GDD §3–6 updated from STAGES.md: the 21-stage table with worlds, keys and unlock rules (planned
  stages marked as planned); §4 `T_base` and Bronze intent with required talents (STAGES §4.1); §5 reward factors
  (`0.5 + 0.25 × n`) and the medal table; §6 the new talents (planned) and Quick Respawn, the economy constraint table
  (STAGES §6.4). The STAGES §9 open questions are answered with the user at this point.
- **S1.1 — Config and data.**
  - `StageConfig`: new fields `world` (1–4) and `requires` (`{ { id, level } }`, empty on World 1), and the reward factors
    of the curve (today's Stage 3: 2.0 → 1.75 if confirmed). Today's four stages keep their keys and folders; their `order`
    gets room for the new World 1 stages (Tutorial 0, Stage 1 → 2, Stage 2 → 4, Stage 3 → 5). Display names and unlock bars
    that depend on stages not built yet (Island Hop, Blink) switch in S4, so players never see a gap in the numbering.
  - Unlock prices of today's stages from the STAGES §7.2 table (Stage 1 → 1 000, Stage 2 → 2 000, Stage 3 → 2 000) with
    their new positions, applied in S4 together with the bars.
  - ~~Challenge-coin value scaling~~ — rejected in the design check; coin values stay 20 / 50 / 100.
  - New unlock rule `{ world, stars }` (stars summed over a world's stages, from medals) in `StageConfig` + `StageUnlocks`
    (bar check, Unlocked_<folder> attributes, popup/portal text "10 of 15 ★ in World 1"). No world-2+ stage exists yet, so
    it is exercised with a temporary Studio-only test entry.
  - Stage 3's duplicate checkpoint: `Stage3.21` gets a free number (20 stays the lowest); rename in Studio while Argon is
    connected (two-way sync renames the folder), then check `git status` and Studio for duplicates.
- **S1.2 — Gating UI and HUD.**
  - Hub portal face (`HubPortalMedals`): a "Needs: <talent>" line for stages with `requires`, green when every required
    level is owned, red when not; no line on stages without requirements. Must fit beside the lock lines.
  - Unlock popup (`StageUnlockPopup`): lists the requirement under the medal bar and price.
  - Arrival warning (new client script): arriving on a stage without a required talent shows a short popup with a button
    that opens the Skills panel; entry is never blocked.
  - leaderstats: "Stage" (checkpoint number) is replaced by "Stars" (`StageConfig.TotalStars`), updated on every new medal.
- **Acceptance checks:**
  - A profile with medals and best times on all four stages loads after S1.1 with the same medals, best times, Top-10
    entries and stars (keys unchanged); `StageConfig.Stages` is sorted by `order` and every stage has `world` and `requires`.
  - Stage 3 has no two checkpoints with the same number, and its respawns still land on the right plate.
  - With a temporary Studio-only test requirement (`requires` Double Jump on one stage, not committed): its portal shows
    "Needs: Double Jump" in red without the talent and green after buying it; the unlock popup lists it; arriving without
    the talent shows the warning and its button opens the Skills panel; arriving with it shows no warning. Portals of
    stages without requirements show no "Needs:" line.
  - leaderstats show "Stars" equal to `StageConfig.TotalStars` of the profile, and it rises by the right amount right after
    a new medal; no "Stage" column remains.
  - A test entry with `unlock = { world = 1, stars = 10 }` stays locked below 10 stars in World 1 and opens at 10 (and by price).
  - Stage 3's reward factor is 1.75 (a first-run Gold pays 1 400 + repeat 175 base Coins).

### S2 — Quick Respawn talent
Talent `QuickRespawn`, level 1 (1 000): respawn after 1 s instead of 3 s; level 2 (3 000): instant respawn and a client-side
fall reset to the current checkpoint. A server script does all respawns (`CharacterAutoLoads` off). Design: STAGES §6.2.1.

### S3 — Obstacle kit + jump lab
**S3.1 scope (agreed 2026-10-21):** a throw-away-or-keep spike that decides GO / NO-GO for the client-driven kit (STAGES §2.4).
- **Lab:** Studio-only `Workspace.KitLab` at (-700, 16, 450) (free area, sea below as kill floor; no hub portal, reached by
  teleport in tests; grows into the S3.3 jump lab). Three stations on one grass slab with a spawn pad.
- **Code:** one client script `ObstacleKit.client.luau` (tags `KitMover`, `KitTilt`, `KitBeam`; behaviour from attributes), no
  server scripts besides what `RespawnService` already does.
- **Station A, carry:** a ping-pong platform and a Y turntable driven by `workspace:GetServerTimeNow()`; the client applies the
  platform's frame delta to the character standing on it.
- **Station B, tilt plate:** hinge plate, torque from the player's offset, spring back, max angle; per-player (kit-local); the
  slide-off mechanism is part of the spike (place setting `MaxSlopeAngle` is 89, so a steep plate alone does not slide you).
- **Station C, client kill:** a blinking beam (server-time phase, 0.4 s telegraph) that kills by the client setting its own
  `Humanoid.Health = 0`.
- **GO needs all four:** (1) carry: after 30 s on a mover the character's offset from its spot on the platform drifts < 0.5
  studs and shows no visible jitter; jumping on / off keeps plausible momentum; (2) tilt: responds < 0.1 s, can slide the
  player off, and a second client sees the plate at rest; (3) client kill: reaches the server (`Died` fires, `RespawnService`
  respawns, timer rules unchanged) within 0.2 s of the overlap; (4) cost: 100 animated parts cost < 1 ms of script time per
  frame. The multi-client check (F7 Server and Clients) is run by the user when asked.
- **Ends with** a written recommendation and a wait for the user's decision; S3.2 does not start before it.

**S3.1 result (2026-10-21, Studio, single client + F7 with 2 clients): all four GO tests passed; recommendation GO.**
Code: `ObstacleKit.client.luau` (the spike is already the kit core); lab: `Workspace.KitLab` (Studio-only, stays for S3.3).
- *Carry:* standing on the sliding platform (15.7 studs/s peak) for 30 s: 0.000 studs drift; on the turntable (45°/s, 5.4
  studs from the centre): 0.053 studs. Jumping off keeps the player above the platform for the jump (max 0.8 studs) with
  `AirCarry` 0.5 s; without it the Humanoid's air friction stops the handed velocity in 0.2 s and the platform swings 7 studs away.
- *Tilt plate:* first visible tilt after 0.05 s, 12° at 0.26 s, settles at about 23° for an offset of 3 studs (Sens 8°/stud);
  holds the player below `SlideAngle` 25° (balancing feel) and pushes off past it (left the plate 0.45 s after standing at the
  edge). A steep plate alone does not slide a character (`MaxSlopeAngle` 89, a standing Humanoid holds any slope): the kit
  puts the Humanoid into freefall with a downhill velocity (`SlideSpeed` 14).
- *Client kill:* the client's `Humanoid.Health = 0` reached the server 0.03 s later (Studio, no network), `Died` fired,
  `RespawnService` respawned; a second client saw the death 0.06 s after the overlap and the respawn after 3.4 s.
- *Cost:* 100 movers + 10 beams: 0.34 ms of script time per frame (limit 1 ms). The two-client run measured the same
  mover and beam phase on both clients within the 10 ms sampling error.
- *Findings for S3.2 (not blockers):* (1) other players see a rider about 0.2 s behind the platform (normal character
  replication delay; 3 studs at the fastest mover, more on a real network), so riders look slightly off a fast platform: keep
  movers at ≤ 10 studs/s where players are watched, or accept it; (2) another player's tilt plate is at rest, so a player
  tilting on it appears to sink about 1 stud into it, as designed in STAGES §2.2; (3) the kit's slide-off and carry only run
  on the local character, so a player who leaves the game mid-slide needs no cleanup; (4) falling or dying with the plate
  tilted just lets it spring back (it resets with no player on it).

**S3.2 scope (agreed 2026-10-21, after GO on S3.1; cut in two, each ends with a Studio check, the user's visual check and a commit):**
- **S3.2a, timed hazards and movers** in `ObstacleKit.client.luau` + a pure `KitMath` module: blinking beams (promoted from the
  spike, `Kill` attribute), elevator (`Lift`: pause at the ends, eased), spinner / sweeper bar (`Spin` + `Kill`), piston
  (`Piston`: telegraph tint, fast strike, slow retract; `Kill` or `Push`), pendulum (`Swing`), disappearing plates (`KitPlate`:
  flicker before they vanish). One unified kill rule: any kit part with `Kill` (beams default on) kills the local character
  while it is dangerous. Test stations in `Workspace.KitLab` (a second slab row). Fairness rules of STAGES §2.3 checked per
  component (telegraph, safe spot, ≥ 0.5 s reaction).
- **S3.2b, `StageCamera`** (client): modes `Default`, `Iso`, `Side`, `Down`, `Front` (all four non-default modes), switched by
  camera zones (parts tagged `CameraZone`, attribute `Mode` + `Distance` / `Fov` / `Yaw` / `Pitch` / `Lead`) or a stage folder
  attribute `CameraMode`; back to `Default` on death, Home, the return portal and the finish; zoom and shift-lock off in the
  modes. Tested in the KitLab.
**S3.2a result (2026-10-21, Studio single client, awaits the user's visual check):** `KitLab` row 2 has one station per component.
- *Lift:* rests 1.5 s at each end, eased, rider carried with 0.000 studs drift over two cycles. *Spinner bar* (70°/s, `Kill`):
  kills on touch, 8 studs from the hub it passes every 2.6 s. *Turntable:* 101° turned in 10.2 s (45°/s), rider drift 0.001
  studs. *Piston* (`Push` 55, `PushLift` 28): tints orange 0.5 s before it strikes (0.3 s strike, 0.8 s retract), knocked the
  player back 18.7 studs without a kill; the crusher variant (`Kill`) killed after 0.7–1.5 s. *Pendulum* (±55°, 3 s): killed
  after 0.8–1.1 s. *Disappearing plates:* 1.8 s solid, 0.6 s flicker, 1.6 s gone per 4 s cycle, four plates staggered.
- `KitMath` unit checks (cycle wrap, lift rest/continuity, window shares, plate shares, piston continuity, precision at
  server-time magnitudes) all pass; 22 kit parts cost 0.12 ms per frame.
- Two bugs found and fixed on the way: (1) a respawned character was read before its Humanoid / root part had replicated, so
  hazards stopped working after the first death (`WaitForChild` now); (2) `CFrame.Angles` keeps float32, so a spin angle of
  `Speed × server time` (~1.2e11°) froze the part: the angle is reduced modulo 360 in double precision first. The S3.1
  turntable numbers above were measured while that part was not turning; re-measured now (0.001 studs while turning).
**S3.2b result (2026-10-21, Studio single client, awaits the user's visual check):** `StageCamera.client.luau` + KitLab row 3
(four camera zones, `Zone_Iso` / `Side` / `Down` / `Front`, each with pillars and a floor stripe).
- Modes measured in a playtest: Iso fov 20, distance 151, pitch 35°, heading (-0.58, -0.58); Side fov 55, 41, 3°, looking
  -Z; Down fov 60, 35, 80°; Front fov 65, 23, 12°, looking -X. Leaving a zone blends back to the normal camera (distance
  13, fov 70, CameraType Custom). A stage folder attribute `CameraMode` (+ attribute overrides such as `Distance`) works while
  that stage's timer runs and ends with the run (cancel / Home / finish).
- Resets: dying inside a mode, and Home from a mode, hand the camera back behind the character at once (no glide across a
  teleport); `CameraFacing` skips its own teleport turn while a mode owns the camera.
- Zoom and shift lock: the camera is Scriptable in a mode, so wheel zoom and the shift-lock camera do nothing (a script cannot
  switch the shift-lock option off: `DevEnableMouseLock` is Studio-only). Movement keys stay relative to the camera, so
  "W = up the screen"; checked by design, not with a keyboard in this run.
- Not in S3.2: crushers / rolling balls / sweeping laser variants beyond the above (they are `Piston` / `Spin` / `Swing`
  presets), kit-local crumbling plates, colour switches, zones and the jump lab (S3.3), moving the old spinners (S3.3).

**S3.3 scope (agreed 2026-10-21; three steps, each ends with a Studio check, the user's visual check and a commit):**
- **S3.3a, kit-local components, zones, run-seeded schedules** (KitLab row 4): crumbling plates (`KitCrumble`: shake on landing,
  fall after `Delay`, back after `Return`; only for the local player), colour switches (`KitSwitch` pads that set a `Group`'s
  colour, `KitColorPlate` plates solid only while their colour is set; per player), zones in a new `KitZones.client.luau`
  (`Wind` with optional gusts, `LowGravity`, `Updraft`; forces are capped, they stop at death and on leaving the box). All
  kit-local state resets on death / respawn. **Run-seeded:** a kit part with attribute `RunSeeded` runs on time since that
  player's timer started (`StageTimerUpdate`), so every run sees the same sequence; outside a run it follows server time.
- **S3.3b, ghosts, templates, jump lab:** other players drawn translucent where each player sees their own state (a kit part
  attribute `GhostOthers`), the Studio-only templates in `ServerStorage.StageKit.Obstacles` (one per component, attributes
  preset), and the jump lab: a script run in a playtest measures jump height and flat reach for each talent set (Run Speed 0-5,
  Jump Height 0-3, Double Jump) into a reach table in STAGES.md, plus labelled gap and height ladders in KitLab.
- **S3.3c, old spinners to the kit:** the 8 server `while wait()` spinner scripts on Stage 1 become `KitMover` Spin parts
  with the same speed and kill behaviour, verified before / after; their server scripts are removed on disk.

**S3.3a result (2026-10-21, Studio single client, awaits the user's visual check):** `ObstacleKit` gained `KitCrumble`,
`KitSwitch` / `KitColorPlate` and `RunSeeded`; new `KitZones.client.luau`; `KitMath` gained `TimeBase` and `Gust`; KitLab row 4
(z≈630) has a station for each.
- *Crumble:* shakes on landing (0.17 studs), gone after 0.82 s (Delay 0.8), back 3.0 s later (Return 3); neighbours unaffected.
- *Colour switches:* Red / Blue / Toggle pads set the group's colour, plates flip solid / ghost (0.85 transparency, no
  collision); standing on a Toggle flips once per step-on; death resets the group to Red and crumbled plates to solid.
- *Zones:* steady wind carries a standing character 8.4 studs/s (Push 14 × GroundFactor 0.6), gust wind swings 0 to 12 studs/s
  with the cycle; low gravity (scale 0.3) raises a jump from 9.0 to 26.2 studs; the updraft carries a character to the top of
  its box at 42-43 studs/s and a character leaving sideways falls normally (the lift needs `Accel` > gravity, default 400).
- *Run-seeded:* with a run active a `RunSeeded` mover is exactly on its run-time phase (offset 9.19 at t = 0.83 s as
  computed), beams follow run time (warning 1.6 s, on 2.0-4.0 s); when the run ends they are back on server time. Carry
  skips the one-frame jump when the time base changes.
- Not yet checked: the user's visual feel of each station; multi-client behaviour of kit-local state (by design other players
  see crumbles and colour plates at rest).

**S3.3b result (2026-10-21, awaits the user's visual check):** `KitGhosts.client.luau` (ghost zones),
`ServerStorage.StageKit.Obstacles` (28 templates: movers, hazards, plates, switches, zones, camera zones, ghost zone,
run-seeded samples, pendulum rig), and the jump lab: KitLab row 5 (z≈690) has a gap ladder (gaps 6-24 studs, labelled) and a
height ladder (+1 to +16 studs); the reach table is measured and recorded in STAGES §1.0 (single jump 8.3-12.5 reach /
7.3-9.0 rise, Double Jump 14.7-21.6 / 14.5-18.0, Triple Jump 20.5-29.8 / 22.0-27.0). Ghost drawing, checked with the F7 two-client
run (2026-10-21): a player inside the ghost zone is seen at transparency 0.65 by the other client (0.00 for the player
themselves and for anyone outside), in both directions; leaving the zone and respawning both reset it to 0.00.

**S3.3c result (2026-10-21, Studio single client, awaits the user's visual check of Stage 1):** the 8 spinner rotation scripts and
the 2 kill-on-touch scripts of `Stage1/SpinnerStage_1` / `_2` are gone; the parts are `KitMover` Spin parts (Speed 60,
measured before: 59.5-62 deg/s, after: 59.9-60.0). The two sweeper bars (`SpinnerStage_1.Part_2` / `Part_6`) have `Kill`; the
two spinning plates (`SpinnerStage_2.Part_1` / `Part_3`) have `Carry = false`, so a rider is still not carried (before and
after the rider falls off within 3 s); the four hub pillars no longer rotate (invisible before). Before / after: each bar
kills a character standing 6 studs from its hub (8 of 8 tries), and a jump timed 10-22 deg (0.17-0.37 s) before the bar
arrives clears it (6 deg is too late), as the bar's contact window is about +-10 deg.
- Three kit bugs found by this check and fixed in `ObstacleKit`: (1) the sphere floor probe counted a low bar beside the
  character as floor and carried it around with the bar (now only surfaces 2.0-3.8 studs under the root count as floor);
  (2) the Humanoid still reports a floor for 1-2 frames after take-off, so a jump from beside a bar counted as standing on it:
  covered by the same depth band, and kill hazards are never floors; (3) the touch test is a box 0.1 studs larger than the
  part (`GetPartBoundsInBox`), like a physical contact, instead of an exact overlap. `KitKilledBy` now records `Model.Part`.
- Regression after the fixes: slide mover carry 0.000 studs drift, jump-off 0.9 studs, tilt plate lip slides off after 0.4 s,
  turntable carry 0.002 studs.

S3.1 spike: tilt plate, carrying the player on moving parts, client-side kill (go / no-go for the approach); S3.2 timed
components (blinking beams, movers, rotators, pistons, pendulums, disappearing plates) and `StageCamera`; S3.3 kit-local
components (crumbling plates, colour switches, tilt plates) and zones (wind, low gravity), run-seeded schedules, ghost drawing,
templates in `ServerStorage.StageKit.Obstacles`, a Studio-only jump lab that measures the reach table per talent set, today's
spinners moved to the kit. Design: STAGES §2.4, §5.1.

### S4 — World 1 complete
S4.0 World 1 courtyard and the World 1 gate in the hub (stars x / 15 and coins found x / y on its face). **Third design
(2026-10-21), done: built, Studio-checked and visually approved by the user (score boards placed by the user, stage names shown by position: Stage 2 / 4 / 5 for today's three stages):** a compact rectangle (x -430..-320, z 187..357) with the
entrance in the south short side, the finale gate (Stage 3) in the north short side and two door gates on each long side
(west: Island Hop [closed], Stage 1; east: Blink [closed], Stage 2); the stages lie physically behind the gates (STAGES 7.1).
The `LandingPad` object is broken down for world stages into `Gate` (door gate: TimerStart, GateExit, GateSign, Door),
`Top10Leaderboard` and `Arrival`; `ServerStorage.StageKit` now holds `Gate`, `Top10Leaderboard` and `Arrival` templates instead
of `LandingPad`; the Tutorial keeps its old pad (moved 70 studs north to clear the west lanes).
- *Scene work:* Stage 1 rotated 90 degrees about its gate to the west far gate, Stage 2 rotated -90 degrees to the east far gate
  (all part CFrames; checkpoints, kit parts and challenge coins moved with them), new plaza / rock / wall / spawn / return
  portal / decor, two closed "Coming soon" gates cloned from the template gate.
- *Checked in a playtest:* hub gate lands on the spawn pad facing the north gate; locked Stage 3 door is solid and opens the
  popup; walking west through Stage 1's gate and east through Stage 2's starts the timer and shows the stage, walking back out
  cancels it; Home from a stage lands on its `Arrival`, Home on the plaza and the south return portal go to the hub; walking
  into Stage 1's rotated finish teleports to its `Arrival`; death at checkpoint 1 respawns facing along the course (west);
  Tutorial portal arrives on its moved pad; no script errors.
- *Lesson:* moving script containers on disk deletes the Studio parts inside them, including scripted parts stashed elsewhere
  (the `TimerStart` / `GateExit` stashes were deleted and rebuilt from known numbers; AGENTS.md gotcha).
S4.1 Island Hop (stage 1, shown "Stage 1"): **built, Studio-checked and visually approved by the user (2026-10-21).** Design and as-built values in
STAGES 7.6: west near gate, a gentle S-curve of stud pillars over the sea (warm-up, staggered field, two conveyors, one run-seeded
slide mover, a rising climb to the finish island), checkpoints 101-105, 7 coins (280), key `IslandHop`, Bronze on Tutorial / 500; Stage 2's
bar switched to Bronze on Island Hop / 1 000. New: `KitConveyors.server.luau` (tag KitConveyor + `Speed`).
- *Checked in a playtest:* unlock flow (Tutorial Bronze opens Island Hop, a Bronze on it opens Stage 2), gate starts the run and the panel
  shows "Stage 1", walking out cancels it, Home lands on `Arrival`, the finish portal ends the run (a 10.7 s test run gave Gold and paid
  the medals) and lands on `Arrival`, a death at plate 103 respawns facing along the course, all 7 coins pay once (walked onto), conveyor
  velocities set, no script errors. A baseline bot (no talents) crossed every leg; the mover crossing was checked by walking (a
  `MoveTo` bot cannot walk on a kit mover, input `Move` can). The profile, leaderboard and MostStars entries the test changed were restored.
- *Not checked:* real `T_base` (52 s provisional) and the difficulty of the 3 x 3 pillar legs (M6a).
- *Follow-up from the user's check:* Stage 2 folder (`Stage2`, key `"Stage 2"`, shown Stage 4): the Quick Respawn fall reset (30 studs below the plate) sent players back before they reached the bounce bricks of Level 12 (tops 46-61, the plates 107 high); the folder attribute `FallResetDepth = 70` (Studio-only) puts the reset below the lowest brick (limit 37).
- *Lesson:* Argon does not sync instances / scripts created through the MCP to disk (AGENTS.md "Adding a world stage").
S4 tuning (2026-10-22, user's walk-through): unlock popup closes itself when the player walks away from the gate (no Close button); glass lane dividers between Island Hop / Stage 2 and
Blink / Stage 4 (also over the courtyard wall top); an exploring-run banner when a checkpoint is reached without a timer (getting around a gate stays allowed: no timer, no
medal or finish reward, Coins count). Studio-checked (popup closes at 20 studs, the panes stop walking and 5-air-jump attempts on the wall top, the banner appears for a locked
stage and for a bypassed unlocked one and disappears when a timed run starts).
S4 tuning, second round: the exploring banner now also shows when the respawn point is already that checkpoint (it only fired when the respawn point changed); Stage 3 (shown Stage 5)
had lost its checkpoint between `level.1` and `level.2` (a default part at the origin since the S1.1 rename), a 23-stud gap, now rebuilt (11-stud gap like the other jumps). Open for M6a: the
11-12 stud jumps of Stage 5 need more than a baseline single jump.
S4 tuning, third round: `TimerStart` of all six gates shrunk from 48 x 30 x 4 to the 21 x 16 x 4 doorway (a run started when walking beside the gate or on the wall top); checked beside
the doors, on the wall top and through the doorway at four world gates and the Tutorial.
S4 tuning, fourth round: the World 1 hub gate is shut until one of its stages is open (Bronze on the Tutorial or buying Stage 1): face shows the lock, local barrier + unlock popup, server refusal
(`StageUnlocks.IsWorldOpen`, `HubGateLocks.client`); checked closed (blocked, popup, face) and open (walks through) in a playtest.
S4 tuning, fifth round: the unlock popup is retired; a shut stage door and a shut world gate carry a ProximityPrompt ("Unlock · price", hold E; "Needs N Coins" when short) and a toast reports
the result (`GatePrompts.client`, `StageUnlockPopup` deleted). Checked: world gate bought with 600 Coins ("World 1 unlocked!", barrier and prompt gone), a stage door without enough Coins ("Not enough Coins"),
no popup when walking into a shut door.
S4 tuning, sixth round: Island Hop (Stage 1) is no longer for sale (`unlockPrice = nil`): a player without a Tutorial medal can earn at most 120 Coins, so the 500-Coin option was dead. The world gate and
Island Hop's door show only the Bronze requirement and carry no prompt.
S4.2 Blink, the rhythm special (stage 3, shown "Stage 3"): **done: built, Studio-checked and visually approved by the user (2026-10-22).** Design and as-built values
in STAGES 7.7 (metronome placeholder now and a Creator Store track later; the beat is per run, music follows the player's run time): a straight
east lane at 120 BPM (count-in plates, beam rows, piston bridge, "drop the beat" finale), every timed part run-seeded, checkpoints 201-206, 8 coins (300),
key `Blink`, `tBase` 60, factor 1.25, Bronze on Stage 2 / 1 500; the unlock chain is complete (Stage 4: Bronze on Blink / 2 000, Stage 5: Bronze on
Stage 4 / 2 000). New: `StageMusic.client.luau`, a "Music" row in Settings (`MusicSettings.client.luau`).
- *Checked in a playtest:* unlock flow (Bronze on Stage 2 opens Blink; a medal on Blink opens Stage 4, Stage 5 stays locked), the gate starts the run and the
  panel shows "Stage 3", the finish portal lands on `Arrival` (Gold on a 3 s test run), metronome ticks every 0.50 s from run start, mute silences it, Home
  stops it, the Settings row toggles; an offline KitMath planner proves every section passable at 14 / 16 / 19.8 studs/s, and a bot following that plan
  crossed the whole course at baseline in 51.6 s (the first try died at the window edge, which fixed the margin used); all 8 coins pay once. The profile,
  leaderboard and MostStars entries the test changed were restored.
- *Not checked:* real `T_base` (60 s provisional) and the real music track (M6a / later).
A measured `T_base` for both new stages comes in M6a.

### M6a — First live test + World 1 balancing
The first live test (open checks below) with 6 stages, then M6 for World 1 (scope in "M6 — Balancing pass" below).

### S5–S11 (outline)
S5 worlds hub (gates for Worlds 2–4 in the hub, World 2 island, return / Home to the world) · S6 World 2 (S6.1 Double Up + Seesaw, S6.2
Turntable + Labyrinth, S6.3 Clocktower) · S7 Triple Jump + Dash (+ World 3 island) · S8 World 3 (S8.1 Triple Peaks + Ice Rink,
S8.2 Dash Bridge + Laser Lab, S8.3 Rising Tide) · S9 Wall Jump + Glide (+ World 4 island) · S10 World 4 (S10.1 Wall Climb +
Glide Canyon, S10.2 Moon Base + Clockwork, S10.3 Summit) · M6b final balancing · S11 bonus stages (S11.1 Darkness + Memory
path, S11.2 Stealth + Chase, S11.3 Giant room + Minecart).

### P3 — Trading
- **Prerequisite:** profile session locking in `PlayerProfile` (`UpdateAsync` with a `{ JobId, Time }` lock instead of
  `SetAsync`; a profile locked by another live server is not loaded until released or stale).
- **Outputs (draft):** trade request → both players add pets / Coins → both confirm the final offer → server swaps
  atomically, saves both profiles immediately, writes a trade log; pets in an open trade are locked; cooldown.
- **Acceptance checks (draft):** changing the offer after a confirmation resets both confirmations; a player leaving
  mid-trade cancels it with no item moved; the same pet cannot end up in both inventories (also across a server
  crash right after the trade); a profile open on server A cannot be loaded for writing on server B.

### M6 — Balancing pass (run as M6a for World 1, M6b for all stages)
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
