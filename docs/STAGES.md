# Oby sandbox — Stage expansion plan (≈ 20 stages)

Status: **draft for review** (2026-10-21). Nothing here is built yet. Decided with the user so far: today's Stage 3 becomes
the finale of World 1 (slot 5); stages are grouped in **worlds of 5**; four **new talents** (Triple Jump, Dash, Glide,
Wall Jump); a talent requirement is shown as a **hint + warning, entry stays open**; **one special stage per world**
(rhythm, isometric shifting maze, 2D side-scroller, dropper) plus **bonus stages** outside the unlock chain (§5). Numbers (prices, factors, `T_base`) are
provisional, like everything in [GDD.md](GDD.md), until M6. Once approved, GDD §3–6 and the ROADMAP are updated from this file
(design first: GDD → ROADMAP → code).

## 1. What exists today

| Stage (key) | Checkpoints | `T_base` | Obstacles | Skill |
|---|---|---|---|---|
| Tutorial (`"Stage 4"`) | 3 (23–25) | 30 | basic jumps, first kill part | none |
| Stage 1 (`"Stage 1"`) | 9 (1–9) | 70 | laser strips (7 kill parts), 2 spinner groups (8 sweepers), lava floor, lava block, 3 choice stages (random safe `Step`), jump pads | none |
| Stage 2 (`"Stage 2"`) | 5 (10–14) | 100 | kill-part corridors (`level 11`: 6 kill parts), bounce-brick chain (`Level 12`: 3 bricks, 360 / 365 / 500 studs/s) | none (DJ coins) |
| Stage 3 (`"Stage 3"`) | 3 (20–22) | 120 | dense kill-part layouts (10 scripted kill parts, `level.2`) | none, but very hard |

**Why Stage 3 is hard** (from the files; to be confirmed by the Studio survey, §1.1): it has the longest course with the
fewest checkpoints (3 for a 120 s `T_base`, about 40 s of replay per death, against about 8 s on Stage 1), and its kill parts
are packed tightly along the route, so every jump is a precision jump with no rest strip. It has no timing obstacle at all:
the difficulty is pure precision and nerve, which is why it stays doable without talents.

Movement reach (default humanoid, from M4): a single jump rises about **6.4 studs** (JumpPower 50) and stays about 0.51 s in
the air (about 8 studs of flat distance at WalkSpeed 16, 10.6 with Run Speed 5); Jump Height 3 computes to 7.9 studs (a
measured jump in M4 reached about 9); Double Jump reaches about **12.7 studs**. Only Double Jump separates "can" from
"cannot" with a clear margin. The other two talents differ by 1–2 studs or 5 % of speed per level, too little for a fair hard
gate (§6.1). The component kit (S2) measures a full reach table in a jump lab.

### 1.1 Studio survey (pending)
The place was not open in Studio during planning, so the read-only scene survey (obstacle part counts per stage, gap widths
and heights on Stage 3, part totals for performance) is still to do. It only refines §1; no decision below depends on it.

## 2. Component catalogue

### 2.1 Build techniques
| Code | Technique | Use for | Risks |
|---|---|---|---|
| **S** | **Static**: anchored parts + an existing script or tag (kill, bounce) | gaps, pillars, beams, walls, kill parts | none; cheapest |
| **F** | **Surface**: anchored part with `AssemblyLinearVelocity` / `AssemblyAngularVelocity` (conveyor, rolling log) or `CustomPhysicalProperties` (ice, mud) | conveyors, ice, slow floors | replicates natively, robust; tune friction on mobile |
| **T** | **Kit-timed**: tagged parts animated on **every client** from `workspace:GetServerTimeNow()` and attributes (`Period`, `Phase`, `Duty`, `Amplitude`, `Axis`…). Every player sees the same phase; the server never moves them | blinking beams, movers, rotators, pistons, pendulums, sweepers | the client must carry the character on moving parts (§2.4); kills from these hazards are detected on the client |
| **L** | **Kit-local**: state per player, simulated only on that player's client | tilt plates, crumbling plates, colour switches, pressure doors | other players see the part at rest (they seem to float); acceptable and common in obbies, and nobody can grief your plate |
| **Z** | **Zone**: the client applies a force or velocity while its character is inside a region | wind, fans, low gravity, updrafts | keep forces moderate (no flings); stop the force at once on death / respawn |
| **P** | **Physics**: unanchored parts with constraints | cosmetic motion, knock-back balls | **avoid for anything a player stands on**: network ownership jumps between nearby players (jitter, unfair falls) |

Today's 8 spinners move on the server in `while wait()` loops: their CFrame replicates every frame to every client (jitter,
bandwidth with 12 players). New movers use **T**; the old spinners can move to the kit later (optional).

### 2.2 Components
Skill tested: **Tim** timing, **Pre** precision, **Rou** routing, **Ner** nerve, **Spd** speed. Gate: which talent the
component can *require* (hard) or only *reward* (soft: faster medal, shortcut).

**Static and surface**
| Component | How it works | Tests | Difficulty knobs | Gate | Build |
|---|---|---|---|---|---|
| Gap jumps | plain, diagonal, up / down jumps between platforms | Pre | gap, height difference, landing size | hard: DJ / Triple / Dash by gap width | S |
| Stud pillars | small tops (3×3 → 1×1), often staggered | Pre, Ner | top size, spacing, height | soft | S |
| Tightrope / thin beam | 1-stud beam walk, straight or zig-zag | Pre, Ner | width, length, turns | – | S |
| Wrap-around | ledges around a wall corner (classic obby jump) | Pre | ledge width, overhang | – | S |
| Low ceiling | ceiling over a gap allows only a flat jump | Pre | ceiling height | blocks DJ shortcuts on purpose | S |
| Kill parts / lava floor | touch = death (exists) | Pre | density, size | – | S |
| Truss / ladder | climbing sections, also with hazards beside them | Tim | length, side hazards | – | S |
| Choice stage | several identical steps, one random one is solid (exists) | Ner, luck | number of steps | – | S |
| Maze | walls hide the route; dead ends | Rou | size, height of walls | DJ to see over walls (soft) | S |
| Invisible / ghost path | path faint or visible only nearby | Rou, Ner | visibility distance, hints | – | S + client fade |
| Ice | very low friction, momentum carries you | Pre, Spd | friction, platform size | soft (Run Speed) | F |
| Conveyor | floor pushes along / against / across the route | Tim, Pre | speed, direction changes | soft | F |
| Rolling log | cylinder spins under your feet | Pre, Tim | spin speed, diameter | – | F |
| Mud / slow floor | WalkSpeed lowered while on it | Spd | slowdown | soft (Run Speed) | F / Z |
| Bounce bricks / jump pads | fixed launch along the brick's front (exists) | Tim, Pre | launch speed, angle, chain length | – | S (existing client script) |
| Speed strip | short boost along the route | Spd | boost, length | – | Z |

**Timed and moving** (kit-timed unless noted)
| Component | How it works | Tests | Difficulty knobs | Gate | Build |
|---|---|---|---|---|---|
| **Blinking beams** (user) | laser bars switch on and off; on = death. A thin translucent beam and a hum **telegraph** 0.4 s before "on"; rows with phase offsets make waves | Tim | period, on-share (duty), telegraph time, number of rows, wave speed | – (Dash to cross two rows in one window, soft) | T |
| Sweeping laser | a beam rotates or slides across a platform | Tim | speed, number of beams | – | T |
| Spinners / sweepers | rotating kill bars at foot or head height (exist) | Tim | speed, length, height (jump over / duck under) | – | T (migrate) |
| Moving platforms | ping-pong or loop paths | Tim, Pre | speed, path length, size, pause at the ends | – | T + carry |
| Elevators | platforms that rise and fall | Tim | speed, wait at the top | – | T + carry |
| **Rotating plates** (user) | (a) turntable around Y you ride; (b) flipper: flips 180° on a timer, you must leave before; (c) windmill blades you jump between | Tim, Pre | speed, size, flip period | DJ to skip blades (soft) | T + carry |
| Disappearing plates | plates fade out and back on a fixed cycle (same for everyone) | Tim | period, on-share, fade warning | DJ to save a late jump | T |
| Pistons / pushers | blocks punch out of walls or floors and push you off | Tim | stroke, speed, period | – | T |
| Crushers | ceiling blocks slam down; under them = death | Tim, Ner | period, gap height | – | T |
| Pendulums / swinging axes | swing across the path | Tim | swing angle, period, count | – | T |
| Rolling balls | balls roll down a ramp toward you on a track | Tim | speed, spacing | – | T (along a path, no physics) |
| Rising lava / tide | kill plane rises from the run's start; you race it | Spd, Ner | rise speed, head start | soft (Run Speed) | L (starts with your timer) |

**Per-player state** (kit-local)
| Component | How it works | Tests | Difficulty knobs | Gate | Build |
|---|---|---|---|---|---|
| **Tilt plates ("gravity plates")** (user) | plate on a fixed hinge axis; it tilts toward where you stand (torque from your offset to the axis), a spring pulls it back; past the stage's slope limit you slide off | Pre, Ner | sensitivity, spring-back speed, max angle, plate length, gap to the next plate | DJ to recover from a slide (World 2) | L |
| Balance board | two-axis tilt plate (later variant) | Pre, Ner | as above | – | L |
| Crumbling plates | start shaking when you land, fall after N s, return after M s (only for you) | Spd, Ner | delay, return time | – | L |
| Colour switches | step on a red button: red plates turn solid, blue ones ghost (only for you) | Rou, Tim | number of colours, switch distance | – | L |
| Pressure door / timed door | a button opens a door for N s; sprint through | Spd | door time, distance | soft (Run Speed; not a hard gate, §6.1) | L |

**Zones**
| Component | How it works | Tests | Difficulty knobs | Gate | Build |
|---|---|---|---|---|---|
| Wind / fans | constant push across the path, steady or gusting on a cycle | Pre | force, gust period | – | Z |
| Updraft | vertical push up a shaft | Tim | force, height | Glide rides it (World 4) | Z |
| Low gravity | lower gravity inside the zone (long, floaty jumps) | Pre | gravity, zone size | – | Z |

**Talent-gated geometry** (needs the talents of §6)
| Component | How it works | Gate | Build |
|---|---|---|---|
| DJ gaps / ledges | gaps and ledges beyond a single jump (> 9 studs high, > 11 studs flat) | hard: Double Jump | S |
| Triple towers | ledges beyond a Double Jump (> 13 studs) | hard: Triple Jump | S |
| Dash gaps | flat gaps beyond a run + double jump | hard: Dash | S |
| Wall-jump shafts | two walls close together; climb by jumping between them | hard: Wall Jump | S |
| Glide canyons | long downward gaps, or an updraft carrying you over | hard: Glide | S + Z |
| Talent shortcuts | an optional faster route needing a talent the stage doesn't require | soft (Gold route) | S |

### 2.3 Fairness rules for every component
- **What you see is what kills you**: timed hazards are drawn and checked on the same client from server time, so a laser
  that looked off never kills you through lag.
- Every timed hazard has a **telegraph** (colour, sound or motion) and a **safe spot** in front of it.
- **No blind jumps**: the landing is visible from the take-off point.
- Moving parts never push a player into a kill part without a chance to react (≥ 0.5 s).
- Timers on one stage share a **base period** (multiples of 1 s), so waits are short and learnable.

### 2.4 Kit architecture (for S2)
- One client module (`ObstacleKit`) drives every tagged part through `CollectionService` (`BlinkBeam`, `Mover`, `Rotator`,
  `TiltPlate`, `Crumble`, `ColourSwitch`, `Piston`, `Pendulum`, `WindZone`, …), configured by attributes on the Studio
  parts, like `BounceBricks.client` today. No script copies per part.
- **Carry**: when the character stands on a kit mover (downward raycast from the root), the client applies the mover's frame
  delta (move + rotation around the axis) to the character.
- **Client kill** for kit hazards: the client sets its own `Humanoid.Health = 0` (it owns its character). It cannot be used to
  cheat; skipping a death is possible with exploits anyway, and times stay server-measured.
- **Streaming-ready**: tags are handled through added / removed signals, so the kit works if `StreamingEnabled` is turned
  on later (20 stages are many parts).
- **Cost**: animate only parts within about 300 studs of the camera; the server animates nothing.
- Templates live in `ServerStorage.StageKit.Obstacles` (Studio-only), next to `LandingPad` and `Checkpoint`.
- For the special stages the kit also holds `StageCamera`, run-seeded schedules and ghost drawing of other players (§5.1).

## 3. Combination patterns
- **One signature per stage.** Each stage introduces or develops **one** headline component (the user's three each get
  their own stage). No component is the signature of two stages.
- **Teach → test → twist → finale.** First a safe version (no kill, or a floor under it), then with a hazard, then
  combined with an earlier component, and the last section before the finish fast and combined.
- **Rest and stress.** A short, safe rest strip after every hard section; a checkpoint every 10–15 s of play in World 1,
  15–20 s in World 2, 20–30 s in Worlds 3–4, never more than 40 s (Stage 3 is the upper limit on purpose).
- **Sawtooth curve.** Each world's first stage is easier in precision than the previous finale, but teaches the world's new
  talent; each world finale mixes every signature of its world.
- **Gold route.** Every stage from World 1 on has 1–2 optional risky shortcuts worth 3–8 s, so Gold is about route and
  nerve, not only speed.
- **Good pairings:** blinking beams + moving platforms (two clocks with one base period); tilt plates + wind; turntable +
  sweepers; conveyors + gaps (jump against the belt); ice + timed doors; crumbling plates + disappearing plates (no time to
  hesitate); colour switches + maze (routing); low gravity + blinking beams; rising tide + anything (pressure).
- **Pairings to avoid:** two timers with unrelated periods (random waits); invisible path + kill floor without hints; tilt
  plate + a kill part right at its edge; knock-back into a kill part with no recovery.
- **Revisit hook.** Talent-tier challenge coins need a talent from a *later* world, so finished stages are worth replaying
  after each new talent.

## 4. The 20-stage curve

Display number = position in the game (`order`, `displayName` in `StageConfig`); the **key** and **folder** never change
(§7.4). `T_base` = a clean run with exactly the required talents (§4.1).

| # | World | Name / theme (prov.) | Signature | Other components | Requires | `T_base` (s) | Source |
|---|---|---|---|---|---|---|---|
| T | 1 | Tutorial | basics | jumps, first kill part | – | 30 | today's Tutorial (`"Stage 4"`) |
| 1 | 1 | Island Hop | stud pillars | wide gaps, slow conveyors, first moving platform | – | 45–60 | **new** |
| 2 | 1 | Stage 1 (today) | variety | laser strips, spinners, lava floor, choice stage, jump pads | – | 70 | `"Stage 1"` |
| 3 | 1 | Blink ★ special: rhythm | **blinking beams** pulsing to the music | disappearing plates, beam waves, pistons on the beat | – | 70–90 | **new** |
| 4 | 1 | Stage 2 (today) | bounce corridors | kill-part corridors, bounce bricks | – | 100 | `"Stage 2"` |
| 5 | 1 | Stage 3 (today) | dense precision (World 1 finale) | dense kill parts | – | 120 | `"Stage 3"` |
| 6 | 2 | Double Up | Double Jump gaps and ledges | moving platforms, elevators | Double Jump | 80–100 | new |
| 7 | 2 | Seesaw | **tilt plates** | wind, DJ recovery jumps | Double Jump | 90–110 | new |
| 8 | 2 | Turntable | **rotating plates** | sweepers, flippers, crumbling plates | Double Jump | 90–120 | new |
| 9 | 2 | Labyrinth ★ special: isometric maze | **shifting maze** seen from above | patrolling guards, Double Jump hedge shortcuts | Double Jump | 90–120 | new |
| 10 | 2 | Clocktower (finale) | tilt + rotate + crumble | conveyors, pressure doors, pistons, beams | Double Jump | 120–150 | new |
| 11 | 3 | Triple Peaks | Triple Jump towers | elevators, crushers | Triple Jump | 100–120 | new |
| 12 | 3 | Ice Rink | ice | wind, timed doors | Triple Jump | 110–130 | new |
| 13 | 3 | Dash Bridge | Dash gaps | pendulums, rolling balls | Triple Jump, Dash | 110–130 | new |
| 14 | 3 | Laser Lab ★ special: 2D side-scroller | **side view platformer** | sweeping lasers, laser grids, colour switches | Triple Jump, Dash | 120–150 | new |
| 15 | 3 | Rising Tide (finale) | rising lava chase | everything from World 3 | Triple Jump, Dash | 130–160 | new |
| 16 | 4 | Wall Climb | wall-jump shafts | pistons, disappearing plates | + Wall Jump | 110–130 | new |
| 17 | 4 | Glide Canyon ★ special: dropper | **long fall down a shaft**, steer through rings | glide sections, updrafts, blinking beams in the air | + Glide | 90–130 | new |
| 18 | 4 | Moon Base | low gravity | blinking beams, Dash gaps | all so far | 120–150 | new |
| 19 | 4 | Clockwork | synchronised timers | rotating plates, crushers, wall jumps | all so far | 130–170 | new |
| 20 | 4 | Summit (finale) | everything | every talent in one run | all talents | 160–200 | new |

16 new stages (2 in World 1, 5 in each later world); ★ marks each world's special stage (§5). Every run stays within GDD
pillar 1 (1–3 minutes). Bonus stages (§5.3) come on top and are not numbered.

### 4.1 Changes to the medal rules (GDD §4)
- `T_base` = a clean run by the developer **with exactly the stage's required talents** (none on stages 1–5).
- Bronze intent: "finishable by any player who owns the required talents"; Silver and Gold as today. Run Speed and Jump
  Height never become requirements; they stay the way to faster medals and shortcuts.

## 5. Special and bonus stages
Decided: **one special stage per world** (marked ★ in §4), a stage that plays differently from a normal obby, plus
**bonus stages** outside the unlock chain, just for fun.

### 5.1 Shared pieces (part of the kit, S2)
- **`StageCamera`** (client): camera modes `Default`, `Iso`, `Side`, `Down`, `Front`, switched by a zone or a stage
  attribute `CameraMode`; back to `Default` on death, Home, the return portal and the finish. Roblox has no orthographic
  camera: a far camera (about 150 studs) with a narrow field of view (about 20°) looks almost isometric. A fixed camera yaw
  keeps the default controls natural ("W = up the screen"), also on mobile. Zoom and shift-lock are off in these modes.
- **Run-seeded schedules**: a per-player obstacle cycle that starts when that player's timer starts, so every run sees
  exactly the same sequence (fair Top-10, learnable Gold). The kit-local (L) components use it.
- **Ghost others**: where every player sees their own state (maze walls, colour switches), other players are drawn
  translucent, so nobody seems to walk through a wall.

### 5.2 World specials
**World 1 — Blink (stage 3): rhythm stage.** Blinking beams, disappearing plates and pistons switch on the beat of the stage
music. A Studio-only `Sound` with a `BPM` attribute (100–120) drives the schedule; the beat comes from server time
(shared, like every kit timer) and the music's `TimePosition` follows it, so the course still works if the sound fails to
load. Beams telegraph on the off-beat; most hazards switch on bars 2 and 4. A mute option in Settings.

**World 2 — Labyrinth (stage 9): isometric shifting maze.**
- Seen from above with the `Iso` camera; about 15 × 15 cells of 8 studs (about 120 × 120 studs), walls on the cell edges.
- **No way on top:** an invisible ceiling at the walls' top height covers the whole maze (holds against every talent,
  also Triple Jump / Wall Jump between close walls); the camera looks through it.
- **The view shows everything** (no fog): the challenge is reacting to the change, not finding the way. Every 6–8 s
  some walls sink and others rise. A rising wall shows a glowing line on the floor 1.5 s before; a sinking wall flashes.
  A wall rising where a player stands pushes them to the nearer side.
- **Always solvable:** a fixed cycle of precomputed layouts (data in a `MazeConfig` module), each checked offline for a
  path from every cell to the exit.
- **Run-seeded** (§5.1): the cycle starts with the run; other players are ghosts.
- Extras: patrolling guards (kill blocks on rails, run-seeded too), challenge coins in dead ends, low hedges only a Double
  Jump crosses as shortcuts (still under the ceiling).
- A torchlight variant (only nearby cells lit) stays an idea for a bonus stage.

**World 3 — Laser Lab (stage 14): 2D side-scroller.**
- `Side` camera at a fixed distance (about 40 studs) perpendicular to the course, following along it with a small lead.
- The character runs in a 4-stud lane between invisible walls (simpler and sturdier than a constraint on the depth axis).
- Triple Jump and Dash read perfectly in 2D; laser grids, sweeping lasers and colour switches fill the lane; background
  layers (decor) give depth.

**World 4 — Glide Canyon (stage 17): dropper.**
- Starts at the top of a tall shaft (400–600 studs); the player falls through rings, past blinking beams and rotating bars,
  with the `Down` camera.
- A zone caps the fall speed (about 80 studs/s), because Roblox characters keep accelerating, so the fall stays readable.
- Glide sections between shafts (wide horizontal gaps) and updrafts that lift to the next shaft; checkpoints on
  platforms in the shafts. Roblox has no fall damage by default, so landings are safe.

### 5.3 Bonus stages
| Bonus stage | What it is | New piece | Effort |
|---|---|---|---|
| Stealth | guards with sweeping spotlight cones; seen = back to the checkpoint | guard component (cone check on the client) | 1.5× |
| Darkness | lights off, only a small light around you and beacons on the route | lighting for that player only | 1× |
| Memory path | a glowing path flashes for 2 s, then you walk it from memory (a fair glass bridge) | run-seeded random path per run (a fixed one would be memorised for the Top-10) | 1× |
| Chase | a boulder or wave rolls after you; the `Front` camera faces you (Crash Bandicoot style) | `Front` camera, kill wall started by the run | 1.5× |
| Giant room | you are tiny in a huge kitchen or desk: cups, pencils, a fan | props only | 1× |
| Minecart | ride a cart on rails, jump gaps, duck under beams | client-driven cart | 2× |

Rules (proposal):
- **Outside the unlock chain:** no medal bar and no price; a bonus stage opens when its world opens. Not needed for any
  world gate.
- Reward factor 1.0 (small, so they are fun rather than the best income), medals, a Top-10 board and challenge coins like
  any stage; their stars count toward the total (the maximum grows by 3 each).
- **Where:** 2 bonus portals on each world island (Worlds 2–4), beside the 5 stage portals.
- Order of building: Darkness and Memory path first (cheap), Minecart last.

### 5.4 Idea: personal-best ghost
Not a stage: a translucent replay of your own best run on any stage, to race against. The client records the character's
position about 10 times a second during a run; the best run's track is stored in its own DataStore (about 10–30 KB per
stage and player). Unscheduled; a good replay hook after S9.

## 6. Skill requirements

### 6.1 What can be a hard gate
| Talent | Hard gate? | Why |
|---|---|---|
| Double Jump (exists) | **yes** | about 12.7 vs about 9 studs: a clear margin |
| Triple Jump (new) | **yes** | one more air jump: about 19 studs |
| Dash (new) | **yes** | a flat gap no run + jumps can cross |
| Glide (new) | **yes** | a gap or descent only a slow fall crosses |
| Wall Jump (new) | **yes** | shafts with no other way up |
| Run Speed (exists) | no, soft | 5 % per level: a timed door that "needs Run Speed 3" would come down to tenths of a second |
| Jump Height (exists) | no, soft | 1–2 studs between levels; the humanoid's ledge catch blurs it further |

### 6.2 New talents (proposed specs)
| Talent | Id (never renamed) | Effect | Controls | Levels | Cost (prov.) | First required |
|---|---|---|---|---|---|---|
| Triple Jump | `DoubleJump` level 2 | 2 air jumps (`TalentConfig.AirJumps` already scales with the level) | jump | +1 level on the existing talent | 5 000 | 11 |
| Dash | `Dash` | in the air, a short horizontal burst (about 10 studs in 0.2 s) in the facing / move direction; once per air time | key (Shift / Q) + mobile button | 1 (a level 2 with a longer dash later) | 8 000 | 13 |
| Wall Jump | `WallJump` | in the air against a wall: jump kicks up and away from the wall; does not refill air jumps | jump near a wall | 1 | 10 000 | 16 |
| Glide | `Glide` | hold jump while falling: fall speed capped at about 8 studs/s, run speed kept | hold jump | 1 (a slower fall at level 2 later) | 12 000 | 17 |

All movement talents are client-driven (like `TalentDoubleJump.client` today); the level is server-owned (`Talent_<id>`
attributes). The skills panel gets 3 new rows. Dash needs an on-screen mobile button; Wall Jump needs the most tuning (wall
detection, camera, mobile), which is why it comes last.

### 6.3 How a requirement is shown (decided: hint + warning, entry open)
- `StageConfig` gets `requires = { { id = "DoubleJump", level = 1 }, … }`.
- **Portal face** (`HubPortalMedals`): a line "Needs: Double Jump", green when owned, red when not.
- **Unlock popup**: lists the requirement next to the medal bar and the price.
- **Arrival warning**: a player arriving without a required talent sees a short popup ("This stage needs Double Jump") with
  a button that opens the Skills panel. The player can still play and look around.
- Course geometry is the real gate (no server check).

### 6.4 Economy impact (GDD §6)
Reward factor per display number `n`: `factor = 0.5 + 0.25 × n` (stage 1: 0.75, stage 2 = today's Stage 1: 1.0, stage 4 =
today's Stage 2: 1.5, stage 5 = today's Stage 3: 1.75 instead of 2.0, stage 10: 3.0, stage 20: 5.5). The Tutorial stays at 0.5.
Medal total per stage = 1 400 × factor (1 050 … 7 700); all 21 stages: **88 200** one-time medal Coins (today 7 000).

The no-grind constraint (GDD §6) for required talents, against all medals on the stages before:
| First required at | Required set | Cost | One-time medals before | Share | OK |
|---|---|---|---|---|---|
| 6 | Double Jump | 1 500 | 9 450 | 16 % | ✔ |
| 11 | + Triple Jump | 6 500 | 26 950 | 24 % | ✔ |
| 13 | + Dash | 14 500 | 36 400 | 40 % | ✔ |
| 16 | + Wall Jump | 24 500 | 53 200 | 46 % | ✔ |
| 17 | + Glide | 36 500 | 59 500 | 61 % | ✔ |

With Run Speed and Jump Height (5 300) the whole tree costs **41 800**. Talents stay a real investment that competes with
pets, pens and incubators (≈ 56 500 together), without blocking the no-grind path. Run Speed / Jump Height could get more
levels later if Gold on Worlds 3–4 needs them (M6).

## 7. Practical side

### 7.1 Hub and worlds (decided: worlds of 5)
- **Central Island** keeps the Tutorial and **World 1** (stages 1–5): today's arc of 4 stud portals grows to 6 (two more
  arches cloned from `ServerStorage.DecorKit.StudPortal`).
- **Worlds 2–4** each get a small island of their own with 5 stud portals in an arc, 2 bonus-stage portals (§5.3), a
  world sign, the world's stars board and a return gate. The hub gets **one world gate per world** (a larger stud portal showing the world's stars x / 15 and
  its lock). A bridge like the garden's is optional decoration; the gate is the fast way.
- The stage return portal ("Hub") and the Home button lead to the stage's **world island** (`StageConfig.world` → world
  spawn), the Home button on a world island to the hub.
- Islands and courses sit in the same sea; `DebugBaseplate` (the kill floor) must cover every new course, or be extended.

### 7.2 Unlock chain and prices
- **Inside a world:** Bronze on the previous stage, or the price.
- **World openers** (6, 11, 16): Silver on the previous world's finale, or the price. Both use the existing
  `unlock = { stage, medal }` rule, no new code.
- **Price** of stage `n` ≈ the previous stage's medal total, rounded to 500:

  | n | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 |
  |---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
  | Price | 500 | 1 000 | 1 500 | 2 000 | 2 000 | 2 500 | 3 000 | 3 000 | 3 500 | 4 000 | 4 000 | 4 500 | 5 000 | 5 500 | 5 500 | 6 000 | 6 500 | 6 500 | 7 000 | 7 500 |

  Buying every unlock costs 81 000: skipping stays possible and expensive (GDD §3).
- The re-order changes the bars of today's Stage 1 (now after Island Hop) and Stage 2 (after Blink). Nothing is live yet, so
  this should land **before the first live test**; afterwards it would need a grandfather rule.

### 7.3 Challenge coins, boards, HUD
- **Coins per stage:** about 8 (5 easy, 2 risky, 1–3 talent). From World 1 on, talent coins need a talent the stage does
  **not** require (a later world's), so they pull players back. About 160 coins in total.
- **Coin value scales with the stage** (proposal): value = tier (20 / 50 / 100) × the stage's reward factor, rounded to 5,
  so late-stage coins still matter (a World 4 coin set would otherwise be 400 Coins next to 7 000 in medals).
- **Boards:** every stage pad has its Top-10 board (in the `LandingPad` template). The hub "most stars" board grows to
  63 stars (+3 per bonus stage); each world island gets a world board (stars in that world). The GDD §8 question "show talents next to a time"
  becomes moot for gated stages.
- **leaderstats "Stage"** shows the checkpoint number today; with 20 stages show **Stars** instead.

### 7.4 Keys, folders, checkpoints
- `StageConfig` already separates `key` / `folder` (stable) from `order` / `displayName` (shown): the re-order only edits
  `order` and `displayName`.
- **New stages get a semantic key = folder name** fixed at creation (`IslandHop`, `Blink`, `DoubleUp`, …), never "Stage N":
  numbers would clash with display numbers after any re-order. Coin ids follow (`Blink_1`), boards follow
  (`leaderboard_Blink`). The display name can change any time.
- Checkpoint names must be numbers (the handler and leaderstats read them). Give each new stage its own block of 100
  (first new stage 100–199, then 200–299, …) so numbers never collide.

### 7.5 Build effort
With the kit and `ServerStorage.StageKit`: about **one session per stage** (greybox from kit templates, playtest, coins,
decor, measured `T_base`), one per world island, about three for the kit, one per new talent. Special stages take about 1.5× a normal stage (the
Labyrinth's layout cycle and the dropper's height the most), bonus stages 1–2× (§5.3). Adding a stage stays as in
AGENTS.md "Adding a stage" plus the `StageConfig` entry (`world`, `requires`, key, prices).

## 8. Proposed milestones (for the ROADMAP, pending approval)
| # | Milestone | Scope |
|---|---|---|
| S1 | Stage framework | GDD §3–6 updated from this file; `StageConfig` gets `world` and `requires`, new display order and names, unlock bars and prices from §7.2; reward factors from §6.4; portal "Needs:" line, unlock popup line, arrival warning; leaderstats Stars |
| S2 | Obstacle kit + jump lab | `ObstacleKit` client module (timed, local, zone components, carry, client kill), `StageCamera` modes, run-seeded schedules, ghost drawing (§5.1), templates in `ServerStorage.StageKit.Obstacles`, a Studio-only jump lab that measures the reach table per talent set. First a spike on tilt plates and carry, the riskiest parts |
| S3 | World 1 complete | new stages Island Hop and Blink (rhythm special, with its music), two more hub arches, coins, measured `T_base` |
| S4 | Worlds hub | world gates on the hub, the World 2 island (5 portals, board, return), return / Home to the world |
| S5 | World 2 (stages 6–10) | five stages incl. the Labyrinth, Double Jump gated |
| S6 | Talents: Triple Jump + Dash | panel rows, mobile button, reach-table update; World 3 island |
| S7 | World 3 (stages 11–15) | five stages incl. the side-scroller |
| S8 | Talents: Wall Jump + Glide | as S6; World 4 island |
| S9 | World 4 (stages 16–20) | five stages incl. the dropper, finale |
| S10 | Bonus stages | the six of §5.3 in batches (Darkness + Memory path first), 2 portals per world island |

Order: S1 → S2 → S3 first (World 1 done, the re-order landed before the first live test); S4–S9 in order; bonus stages (S10) can slot in
after any world island exists. P3 (trading) is independent. M6 (balancing) is best after S3 for World 1 and again after S9.

## 9. Open questions
| Question | Recommendation |
|---|---|
| World themes and names (sky, factory, storm, summit…)? | pick with the style decision ([STYLE_PREVIEW.md](STYLE_PREVIEW.md)); stud style for now |
| World gate bar: Silver on the previous finale, or "N stars in the previous world" (needs code)? | Silver on the finale (no code) |
| Scale challenge-coin values with the stage factor? | yes |
| Semantic keys for new stages (`Blink`) instead of `"Stage N"`? | yes |
| Re-tune today's Stage 3 factor from 2.0 to 1.75 (curve) or keep 2.0? | 1.75 (already-paid Coins are unaffected) |
| Move today's spinners to the kit (smoother, no server loop)? | yes, in S2, optional |
| Should a world island also have a garden-style bridge? | gate first, bridges later as decor |
| Bonus stages: open with their world, no bar and no price? | yes |
| Bonus stars count toward the hub "most stars" total? | yes (they are real stages with medals) |
| Rhythm stage music: which track (licence, loop length, BPM)? | a free Creator Store track at 100–120 BPM; pick in S3 |
| Personal-best ghost (§5.4) as a later milestone? | yes, after S9 |
