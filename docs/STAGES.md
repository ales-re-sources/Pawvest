# Oby sandbox — Stage expansion plan (≈ 20 stages)

Status: **agreed plan** (2026-10-21); nothing is built yet. Decided with the user: today's Stage 3 becomes the finale of
World 1 (slot 5); stages are grouped in **worlds of 5**; four **new talents** (Triple Jump, Dash, Glide, Wall Jump) plus the
utility talent Quick Respawn (§6.2.1); a talent requirement is shown as a **hint + warning, entry stays open**; **one special
stage per world** (rhythm, isometric shifting maze, 2D side-scroller, dropper) plus **bonus stages** outside the unlock chain
(§5); milestones S1–S11 (§8) are in the [ROADMAP](ROADMAP.md), trading (P3) after all 20 stages. Numbers (prices, factors,
`T_base`) are provisional, like everything in [GDD.md](GDD.md), until M6. GDD §3–6 is updated from this file in S1 (design
first: GDD → ROADMAP → code); the open questions in §9 are answered then.

## 1. What exists today

| Stage (key) | Course | Checkpoints | `T_base` | Obstacles | Skill |
|---|---|---|---|---|---|
| Tutorial (`Tutorial`, was `"Stage 4"`) | 284 studs, flat | 3 (23–25), 80–100 studs apart | 30 | gaps up to about 6 studs (one 16-stud step at the start), 10 small tops; no kill parts | none |
| Stage 2 (`Stage2`, was `"Stage 1"`) | 605 studs, flat | 9 (1–9), about 57 studs apart | 70 | laser strips + lava floor + lava block (9 kill parts), 2 spinner groups (8 sweepers), 3 choice stages, side jumps (15-stud gaps), jump pads (45-stud launches) | none |
| Stage 4 (`Stage4`, was `"Stage 2"`) | 535 studs, climbs 114 | 5 (10–14), 50–200 studs apart | 100 | kill-part corridors (6 kill parts), gaps of 9.5–11 studs, a bounce-brick chain (3 bricks, 33–54-stud launches) | none (DJ coins) |
| Stage 5 (`Stage5`, was `"Stage 3"`) | **293 studs**, flat | 4 plates (20, 21, **21**, 22), about 100 studs apart | 120 | see below | none, but very hard |

**Why Stage 3 is hard** (Studio survey, 2026-10-21): it is the *shortest* course but the slowest, because every metre is
precision. It has three sections and no timing obstacle at all:
1. **Max-distance jumps** (20 → 21): four 16 × 7 plates with **12-stud gaps**, each plate 1 stud higher than the last, at the
   limit of a single jump.
2. **Wrap-around** (`level.2`): three 12-stud-high walls fill the whole 16-stud width of a 40-stud floor; you get past each
   one by jumping out around its side over the void.
3. **Tightrope** (21 → 22): a zig-zag of **0.1-stud wires** (10 segments, 14–40 studs long, right-angle turns) with ten tiny
   kill nubs (1 × 0.2 studs) on the wire to hop over.

The difficulty is pure precision and nerve, which is why it stays doable without talents (Double Jump would trivialise
sections 1 and 2 and help on the wire). A death costs about 30 s of replay (about 8 s on Stage 1).

Movement reach (place settings: `CharacterUseJumpPower`, JumpPower 50, WalkSpeed 16, gravity 196.2, MaxSlopeAngle 89): a
single jump rises about **6.4 studs** and stays about 0.51 s in the air (about 8 studs of flat air distance at WalkSpeed 16,
10.6 with Run Speed 5; with the character's own length the longest gap is about 11–12 studs, as Stage 3 shows); Jump Height 3
computes to 7.9 studs (a measured jump in M4 reached about 9); Double Jump reaches about **12.7 studs**. Only Double Jump
separates "can" from "cannot" with a clear margin. The other two talents differ by 1–2 studs or 5 % of speed per level, too
little for a fair hard gate (§6.1). The component kit (S3) measures a full reach table in a jump lab.

### 1.0 Measured reach table (S3.3b jump lab, 2026-10-21)
Measured in a Studio playtest on a flat runway (KitLab row 5): the character runs at full speed, jumps once at the same height
and lands level; the extra jumps are Double Jump style `Jumping` state changes, timed by the better of two policies (at the
apex, or as early as the 0.26 s gap allows). Values are root part positions in studs: **flat reach** = distance from take-off
to landing, **rise** = highest point above the take-off. A crossable gap between two platforms is the flat reach minus about
1–2 studs (the root stands slightly inside each edge).

| Run Speed | Jump Height | Single jump: reach / rise | 1 air jump (Double Jump): reach / rise | 2 air jumps (Triple Jump): reach / rise |
|---|---|---|---|---|
| 0 (16.0) | 0 (power 50) | 8.3 / 7.3 | 14.7 / 14.5 | 20.5 / 22.0 |
| 0 (16.0) | 3 (power 55.7) | 9.5 / 9.0 | 16.4 / 18.0 | 22.5 / 27.0 |
| 3 (18.9) | 0 | 9.9 / 7.3 | 17.4 / 14.7 | 24.4 / 22.0 |
| 3 (18.9) | 3 | 11.3 / 9.0 | 19.5 / 18.0 | 26.7 / 27.0 |
| 5 (20.8) | 0 | 11.0 / 7.3 | 19.3 / 14.5 | 27.0 / 22.0 |
| 5 (20.8) | 3 | 12.5 / 9.0 | 21.6 / 18.0 | 29.8 / 27.0 |

Reading it for design: a single jump (rise 7.3–9.0) is cleanly separated from Double Jump (14.5–18.0); every Run Speed / Jump
Height combination of a single jump stays below the Double Jump baseline (14.5 rise, 14.7 reach), so a "needs Double Jump"
ledge of ≥ 10 studs or gap of ≥ 14 studs is a real gate (the figures above supersede the earlier estimates of about 12.7 /
19 studs in §6.1). Triple Jump adds about 6 studs of reach and 7.5 of rise over Double Jump. Run Speed 5 gives +2.7 studs of
single-jump reach, Jump Height 3 +1.7 studs of rise: the soft talents move numbers by 1–3 studs, as §6.1 assumes.

### 1.1 Studio survey findings (2026-10-21, read-only)
- Place settings: `Players.RespawnTime` **3 s**, `CharacterAutoLoads` on, `StreamingEnabled` **off**; 2 441 parts in
  `Workspace` (each stage 250–320 parts including its decorated landing pad). 20 more stages add about
  6 000–8 000 parts: still fine without streaming, but the kit stays streaming-ready (§2.4).
- **Stage 3 has two checkpoints named `21`** (`Stage3.21` and `Stage3.level.2.21`, about 52 studs apart). Both work (they are
  not siblings), but the leaderstats show 21 twice and it breaks the "one number per checkpoint" rule (§7.4). Fix when
  Stage 3 is touched next (rename one; the higher block of numbers for re-ordered stages makes room).
- Stage 1's spinners are 8 server scripts (`while wait()`), 2 of them on parts with a second, kill script; Stage 1 and 2
  kill parts are 1-stud-thin strips, Stage 3's are tiny nubs.
- No solid invisible parts on any course (no hidden helpers or walls).

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

### 2.4 Kit architecture (for S3)
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
- **Visuals are deferred (user decision 2026-10-21):** every kit component is deliberately plain (grey / coloured boxes); wind
  and updraft particles, plate looks, beam glow etc. come in a later visual pass together with the world style decision
  ([STYLE_PREVIEW.md](STYLE_PREVIEW.md)), as presets on the `StageKit.Obstacles` templates. Only the functionality (attributes
  and behaviour in the script headers) is fixed.
- **S3.1 spike result (2026-10-21):** carry by frame delta is exact (no drift) and needs a short air-carry (0.5 s) after
  jumping off; tilt plates need an explicit slide-off (freefall + downhill velocity) because `MaxSlopeAngle` is 89; the client
  kill reaches the server in one message; 100 movers cost 0.34 ms per frame. Other players see riders ~0.2 s behind a moving
  platform (replication delay). Details in [ROADMAP.md](ROADMAP.md) S3.
- For the special stages the kit also holds `StageCamera`, run-seeded schedules and ghost drawing of other players (§5.1).

## 3. Combination patterns
- **One signature per stage.** Each stage introduces or develops **one** headline component (the user's three each get
  their own stage). No component is the signature of two stages.
- **Teach → test → twist → finale.** First a safe version (no kill, or a floor under it), then with a hazard, then
  combined with an earlier component, and the last section before the finish fast and combined.
- **Rest and stress.** A short, safe rest strip after every hard section; a checkpoint every 10–15 s of play in World 1,
  15–20 s in World 2, 20–30 s in Worlds 3–4, never more than 40 s (Stage 3, about 30 s, is close to the upper limit on purpose).
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
| T | – | Tutorial (hub stage, no world) | basics | jumps, first kill part | – | 30 | today's Tutorial (`Tutorial`) |
| 1 | 1 | Island Hop | stud pillars | wide gaps, slow conveyors, first moving platform | – | 45–60 | **new** |
| 2 | 1 | Stage 2 (today) | variety | laser strips, spinners, lava floor, choice stage, jump pads | – | 70 | `Stage2` |
| 3 | 1 | Blink ★ special: rhythm | **blinking beams** pulsing to the music | disappearing plates, beam waves, pistons on the beat | – | 70–90 | **new** |
| 4 | 1 | Stage 4 (today) | bounce corridors | kill-part corridors, bounce bricks | – | 100 | `Stage4` |
| 5 | 1 | Stage 5 (today) | dense precision (World 1 finale) | dense kill parts | – | 120 | `Stage5` |
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

### 5.1 Shared pieces (part of the kit, S3)
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
music. A Studio-only `Sound` with a `BPM` attribute (100–120) drives the schedule. **Decided in the S4.2 design check
(2026-10-21): the beat is per run, not shared:** every hazard is run-seeded and the music starts with the player's timer and
follows run time (`TimePosition` = run time mod the loop length), so every run sees the same sequence; the course still works
if the sound fails to load. Beams telegraph on the off-beat; most hazards switch on bars 2 and 4. A mute option in Settings.

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
- **First level (user's 2D drawing, 2026-10-22): the key arena**, built as the standalone prototype `Workspace.KeyArena`
  (not in `StageConfig` yet, no timer, medals or portal; reached only by teleporting; floats at x 800, y 120, z 1200).
  - *Goal:* an isolated room, start bottom left, exit bottom right; collect the **teal key** (top left) and the **green key**
    (hanging in the E-shaped structure, upper right); picking up the teal key makes the teal force-field gate beside the pillar
    disappear at once (key attribute `OpensGate`, no lock needed; user's change 2026-10-22), the green key opens the exit door
    when the player touches its lock zone. An opened gate is fully invisible and non-solid for that player. Spikes kill. Keys and opened gates are per player, persist through deaths (3 checkpoints: start,
    before the pillar, behind the gate) and reset at the exit.
  - *Scale:* 1 drawing unit = 4 studs (the arena is 172 x 64 studs inside); positions are converted from the drawing's
    pixels (41.5 px per unit), so the layout is the drawing's. Lane 6 studs deep (invisible front wall, dark back panel),
    camera zone `Side`, distance 55 (the whole arena is 64 studs high; the default 40 shows only part of it).
  - *Deliberate changes to the drawing:* the exit opening is 2 units high (the drawing's 1 unit is below a character's
    height); the teal gate is full height (the 3-unit pillar alone is cleared by a Triple Jump); the yellow orb is a bounce
    brick (`LaunchSpeed` 60, launches straight up; the way past the spiked block in the low corridor); spike kill boxes
    are 60 % of the drawn spike (hanging ones 50 %) so the A-B corridor stays passable for a 5-stud character; keys have a
    7 x 6 stud pickup box because the key pocket under the hanging bar is only 4.4 studs high; spikes are light red.
  - *Reachability (kinematic search, calibrated on the real humanoid: 7.27 studs per jump, 16 studs/s):* **Double Jump alone
    cannot even climb onto platform A** (5 units = 20 studs, a Double Jump rises 14.5); **Triple Jump (2 air jumps, 21.8
    studs) completes the level** (start -> A -> left ledge -> platform B and the teal key -> over the spiked blocks -> pillar
    top -> green key -> orb -> exit). So the level belongs to the Triple Jump tier (stage 14, S7). Dash is not needed by
    that route; the low corridor under platform A (4 floor spikes under a 12-stud ceiling) is the Dash shortcut, not checked
    yet. With the Triple Jump the margins are small (floor -> A needs 20.2 of 21.8 studs): playtest with the real talent
    in S7 and lower platform A by a quarter unit if it feels harsh.
  - *Scripts:* `ArenaConfig` (names, tags, attributes), `ArenaServer` (spikes, checkpoints, keys, locks, exit; no per-part
    scripts, everything is found by tag) and `ArenaClient` (local key / gate state, key HUD, toasts).
  - *To do when the stage gets its slot:* `StageConfig` entry (key, world 3, requires), `TimerStart` / finish portal at
    the start / exit (the exit zone currently just teleports back to the start), Top-10 board, challenge coins, hub portal.

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
stage and player). Unscheduled; a good replay hook after S10.

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

### 6.2.1 Quick Respawn (utility talent, user idea)
Not a movement talent and never a requirement: it saves the waiting after a mistake. Today every death waits for the
place's respawn time (`Players.RespawnTime` = 3 s, set in Studio; no script sets it) plus the death animation,
and a missed jump over the sea falls for several seconds before the kill floor is reached.

| Level | Effect | Cost (prov.) |
|---|---|---|
| 1 | after a death, respawn at the checkpoint after **1 s** instead of the default | 1 000 |
| 2 | **instant**: a death respawns at once (short fade, no break-apart animation), and a **fall reset** moves you back to the checkpoint the moment you are clearly lost, without dying | 3 000 |

- Id `QuickRespawn` (attribute `Talent_QuickRespawn`; never renamed). Shown in the skills panel as "Quick Respawn".
- **Death → respawn** (server): on `Humanoid.Died` the server calls `LoadCharacter` after the player's delay. Every kill source
  (26 copied kill scripts, the sea, kit client kills) ends in `Died`, so one place handles them all. Needs
  `Players.CharacterAutoLoads = false` with all respawns done by one server script (calling `LoadCharacter` while auto-load
  is on can respawn twice); the join spawn and the Home button must keep working through it.
- **Fall reset** (client, level 2; built in S2 as `QuickRespawnClient`): the client already knows its current checkpoint (`CheckpointReached`); when the character
  is falling and more than `fallResetDepth` studs (the stage folder's attribute `FallResetDepth`, default 30, 0 = off; never lower than 5 studs above the sea / `DebugBaseplate`, so plates near the sea still reset before the fall kills; plates more than 300 studs away are ignored, e.g. after Home) below that checkpoint plate, it moves itself onto
  the plate facing its front (same placement as a respawn). The stage's kit-local obstacles (crumbling plates, tilt plates,
  colour switches) reset as on a respawn. Off on the dropper (stage 17), where falling is the course; deep sections set
  their own depth.
- The stage timer keeps running in both cases: the talent only removes the waiting.
- **Fair for the boards:** a clean Gold or Top-10 run has no deaths, so the talent barely changes the best times; it mostly
  helps players who still die, on long hard stages like today's Stage 3. Gold is never designed around it.
- Useful from the first stages, so it is cheap and available from the start (no world gate).

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

With Run Speed and Jump Height (5 300) and Quick Respawn (4 000) the whole tree costs **45 800**. Talents stay a real investment that competes with
pets, pens and incubators (≈ 56 500 together), without blocking the no-grind path. Run Speed / Jump Height could get more
levels later if Gold on Worlds 3–4 needs them (M6).

## 7. Practical side

### 7.1 Hub and worlds (decided: worlds of 5)
- **Central Island** keeps the Tutorial portal and gets **one world gate per world** (4 larger stud portals cloned from
  `ServerStorage.DecorKit.StudPortal`). The stage portals no longer stand in the hub (changed 2026-10-21, user idea: every
  world including World 1 is a crossroad island; the hub itself has no stage portals except the Tutorial).
- **Each world (1–4) has a small island of its own** (a "crossroad"): 5 stud portals in an arc, one per stage, 2 bonus-stage
  portals from World 2 on (§5.3), a world sign, the world's stars board and a return gate to the hub. World 1's island is
  built in S4 (today's three stage portals move onto it); Worlds 2–4 follow with their milestones. A bridge like the
  garden's is optional decoration; the gate is the fast way.
- **The world gate shows progress** (face, like the stage portals): the world's **stars x / 15** (medals earned), the
  **challenge coins found x / y** across the world's stages, and its lock (requirement + price, §7.2). **A world's gate is shut until one of its stages is open** for the
  player (decided 2026-10-22, so nobody enters a courtyard of closed gates): World 1 opens with Bronze on the Tutorial or by buying Stage 1; the face shows the
  lock (requirement + price), a local barrier fills the gate, a prompt on it ("Unlock · 200 Coins", hold E) buys Stage 1, which opens the world (the price is low on purpose, decided 2026-10-22; a player without a Tutorial medal cannot earn it anyway); the server refuses the
  teleport. Worlds 2–4 open with their first stage under the world-stars rule of §7.2.
- The stage return portal ("Hub") and the Home button lead to the stage's **world island** (`StageConfig.world` → world
  spawn), the Home button on a world island to the hub. The Tutorial (world 0) returns to the hub.
- **S4.0 design (third version 2026-10-21; replaces the island with arch portals and the long row of pads):** a world is a
  **compact rectangular courtyard whose gates lead directly into the stages**; nobody is teleported into a stage.
  - *The Tutorial* counts in no world (World 1 = 15 stars) and keeps its own old-style pad and hub portal.
  - *Rectangle:* World 1: x -430..-320 (110 wide), z 187..357 (170 long), top y 78, low wall (6 high). The entrance (return
    portal to the hub; the hub gate lands on the `Spawn` pad) is in the south **short** side; the finale gate (Stage 3, its
    course runs north) is in the north short side; two gates on each **long** side, near (z 302) and far (z 242).
  - *Names (user decision 2026-10-21):* the signs read the **position**: "Stage 1" and "Stage 2" on the west side (near, far),
    "Stage 3" and "Stage 4" on the east side, "Stage 5" at the far end; `StageConfig.displayName` is "Stage 2" for key
    `"Stage 1"`, "Stage 4" for key `"Stage 2"`, "Stage 5" for key `"Stage 3"` (keys never change); Island Hop and Blink are
    working titles of the two new stages (positions 1 and 3), which stand closed as "Stage 1" / "Stage 3 - coming soon".
    Until S4 switches the unlock chain, bars still name the old stage's new display name (e.g. "Silver on Stage 2").
  - *Order:* west side near to far = Island Hop (1), Stage 1 (2); east side near to far = Blink (3), Stage 2 (4); far end =
    Stage 3 (5). Side courses run outward (west courses west, east courses east): the existing Stage 1 and Stage 2 were
    rotated 90 degrees about their gates (whole stage folders, every part's CFrame); Stage 3 stayed, the Tutorial pad was
    moved 70 studs north to clear the west lanes. The two future gates stand closed with a "Coming soon" sign.
  - *Door gates:* each gate is a stud gate (two pillars, beams, sign) with a wooden **door** that stays shut for a player while
    the stage is locked (white text with stars / coins / lock lines on it, a prompt on it, "Unlock · 1 000 Coins", buys the stage); once the bar is
    met or the stage bought, the door is a faint ghost with black text and the doorway is free. **Walking through starts the
    stage and the timer at once** (`TimerStart`, the server checks the unlock). Walking back out cancels the run (`GateExit`).
  - *Tuning after the first walk-through (2026-10-22):* the unlock popup was first made to close by itself 20 studs from the gate, then **replaced by gate prompts** (a ProximityPrompt on each shut door and on a shut world gate, plus a toast; `GatePrompts`); **lane dividers**
    (`Workspace.LaneDividers`, glass panes between Island Hop / Stage 2 and Blink / Stage 4) stop players hopping between neighbouring lanes (Island Hop's plate 105 lay
    19 studs from Stage 2's lava section, within Double Jump + Run Speed reach) and walking along the courtyard wall top from one lane to the next;
    **getting around a gate stays possible** (over the wall, or around a locked door): the timer does not start, finish rewards and times do not count, Coins
    do, and the first checkpoint reached without a timer shows the banner "Exploring Stage N without a timer ... at your own risk" (`StageExploreWarning`).
  - *Start trigger (2026-10-22):* `TimerStart` shrank from 48 x 30 x 4 to 21 x 16 x 4 (the doorway), so a timer starts only when walking through the gate, not beside it or on the
    wall top (all six gates incl. the Tutorial; checked in a playtest).
  - *Stage 5 fix (2026-10-22):* the checkpoint between `level.1` and `level.2` of Stage 3 had been lost (see AGENTS gotchas), leaving a 23-stud gap; restored, the
    gap is 11 studs like the three before it. These 11-12 stud jumps are at the limit of a single jump (a baseline run reaches about 8.3 studs root to root,
    the jump lab table in 1.0), so Stage 5 in practice wants Run Speed or Jump Height talents; to be weighed in M6a against the GDD rule that World 1 needs none.
  - *LandingPad broken down:* the old pad object is gone for world stages: each stage folder holds `Gate` (door gate with
    `TimerStart`, `GateExit`, `GateSign`), `Top10Leaderboard` (standing in the courtyard beside the gate) and `Arrival` (where
    finish and Home land, in front of the gate); the plaza replaces the pad floor, decor and rock.
  - *Flows:* hub gate to `Spawn`; finish and Home from a stage land on the stage's `Arrival`; Home on the plaza (also right
    after a finish) and the south return portal go to the hub.
  - *Not in S4.0:* the world stars board (with World 2, S5); a bridge.
  - The hub keeps the Tutorial portal and the World 1 gate (1.25x stud arch on the central slot; two slots free for Worlds 2, 3).
- Islands and courses sit in the same sea; `DebugBaseplate` (the kill floor) must cover every new course, or be extended.

### 7.2 Unlock chain and prices
- **Inside a world:** Bronze on the previous stage, or the price.
- **World openers** (6, 11, 16): **10 of the 15 stars of the previous world**, or the price (decided 2026-10-21, replaces
  "Silver on the finale"; 10 = Silver on every stage, provisional). Needs a new unlock rule type next to
  `unlock = { stage, medal }` (e.g. `unlock = { world, stars }`), built in S1.1.
- **Price** of stage `n` ≈ the previous stage's medal total, rounded to 500:

  | n | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 |
  |---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
  | Price | 200 (Island Hop: low on purpose, see GDD §3) | 1 000 | 1 500 | 2 000 | 2 000 | 2 500 | 3 000 | 3 000 | 3 500 | 4 000 | 4 000 | 4 500 | 5 000 | 5 500 | 5 500 | 6 000 | 6 500 | 6 500 | 7 000 | 7 500 |

  Buying every unlock costs 80 700: skipping stays possible and expensive (GDD §3).
- The re-order changes the bars of today's Stage 1 (now after Island Hop) and Stage 2 (after Blink). Nothing is live yet, so
  this should land **before the first live test**; afterwards it would need a grandfather rule.

### 7.3 Challenge coins, boards, HUD
- **Coins per stage:** about 8 (5 easy, 2 risky, 1–3 talent). From World 1 on, talent coins need a talent the stage does
  **not** require (a later world's), so they pull players back. About 160 coins in total.
- **Coin values stay flat** (decided 2026-10-21): 20 / 50 / 100 on every stage; the scaling proposal (tier × stage
  factor) was rejected. Late-stage coins matter less next to the medals; they remain a revisit hook.
- **Boards:** every stage pad has its Top-10 board (in the `LandingPad` template). The hub "most stars" board grows to
  63 stars (+3 per bonus stage); each world island gets a world board (stars in that world). The GDD §8 question "show talents next to a time"
  becomes moot for gated stages.
- **leaderstats "Stage"** shows the checkpoint number today; with 20 stages show **Stars** instead.

### 7.4 Keys, folders, checkpoints
- `StageConfig` already separates `key` / `folder` (stable) from `order` / `displayName` (shown): the re-order only edits
  `order` and `displayName`.
- **Renamed 2026-10-22: key = folder = position** (`Stage1` … `Stage5`, `Tutorial`; World 2 will be `Stage6` …). The old keys (`IslandHop`, `"Stage 1"`, `Blink`, `"Stage 2"`, `"Stage 3"`, `"Stage 4"`) and the folders at the Workspace root were replaced in one go while nothing was live: the stage folders moved under their world (`Workspace.World1.Stage1` …), the keys, coin ids (`<folder>_<n>`) and the DataStore records of the developers' accounts were migrated (profiles: BestTimes, Medals, UnlockedStages, RunsToday, CollectedCoins; boards `leaderboard_<key>`). Sections 7.6 / 7.7 below keep the names of their time.
- ~~New stages get a semantic key = folder name~~ (superseded by the line above) (`IslandHop`, `Blink`, `DoubleUp`, …), never "Stage N":
  numbers would clash with display numbers after any re-order. Coin ids follow (`Blink_1`), boards follow
  (`leaderboard_Blink`). The display name can change any time.
- Checkpoint names must be numbers (the handler and leaderstats read them). Give each new stage its own block of 100
  (first new stage 100–199, then 200–299, …) so numbers never collide.

### 7.5 Build effort
With the kit and `ServerStorage.StageKit`: about **one session per stage** (greybox from kit templates, playtest, coins,
decor, measured `T_base`), one per world island, about three for the kit, one per new talent. Special stages take about 1.5× a normal stage (the
Labyrinth's layout cycle and the dropper's height the most), bonus stages 1–2× (§5.3). Adding a stage stays as in
AGENTS.md "Adding a stage" plus the `StageConfig` entry (`world`, `requires`, key, prices).

### 7.6 S4.1 Island Hop (design check and as built, 2026-10-21)
- **Place:** the west **near** gate (z 302; the closed `SoonGate1` was deleted) is the gate of the stage folder `IslandHop` (key and
  folder `IslandHop`, shown "Stage 1"). The course leaves west from x -438 inside the band z 272..335 (Stage 2 occupies z 204..266
  to its south); the kill floor already covers it. About 370 studs long, a **gentle S-curve** (decided): headings 0 deg (warm-up),
  12 deg north-west (pillar field, z up to about 322), -22 deg south-west (conveyors), -8 deg (moving platform), +6 deg (climb).
- **Built from** Stage 2's west gate pose: its `Gate`, `Top10Leaderboard`, `Arrival` and finish portal cloned and moved +60 in z (board
  at z 273 beside the gate; the two decor pieces that stood there were removed), `StageKit.Checkpoint` and `Mover_Slide`.
- **Signature: stud pillars over the sea** (stud-textured columns from the sea up; no kill parts, the sea is the only hazard):
  (A) warm-up, six 6 x 6 pillars, gaps 4, plate `102`; (B) pillar field, twelve 4 x 4 / 3 x 3 pillars staggered 3-5 studs sideways,
  gaps 4-6, rises -2..+1, plate `103`; (C) three small pillars, two **conveyors** (8 x 18, speed 6 studs/s, first against and then
  with the run), a rest pillar, plate `104`; (D) pillar, 8 x 8 bank, then **one run-seeded `Mover_Slide`** (10 x 8, amplitude 6,
  period 6 s, 1 stud from each bank at the ends) across a 22-stud gap to plate `105`; (E) six pillars rising 8 studs, a 16 x 16
  finish island with the finish portal, entered along the course.
- **Conveyors are a new tiny component** (`KitConveyors.server.luau`): parts tagged `KitConveyor` with attribute `Speed` (studs/s along the
  part's front; negative = backwards); the server sets the anchored part's `AssemblyLinearVelocity` once.
- **Reach limits (§1.0)** hold for Bronze without talents: every gap on the main line is at most 6.1 studs edge to edge, every rise at most
  +1.5, landings at least 3 x 3. A baseline bot (Run Speed 0, Jump Height 0, no Double Jump) crossed every leg, most on the
  first attempt; the tightest legs (3 x 3 pillars with 5-5.6 stud gaps and a sideways stagger) needed up to three tries, which
  M6a should keep an eye on.
- **Checkpoints:** the start plate `101` (first checkpoint; `TimerStart` counts as it) and `102`..`105`, each facing along its
  section's heading (a respawn faces the course).
- **Coins** `IslandHop_1`..`_7` (4 easy 20, 2 risky 50, 1 talent 100 = 280): side pillars off the course; the talent coin sits
  on a 3 x 3 tower 11.5 studs above the finish island (only Double Jump reaches it); none behind a score board.
- **StageConfig:** key `IslandHop`, displayName "Stage 1", order 1, world 1, `tBase` 52 (provisional, M6a), reward factor 0.75,
  unlock Bronze on the Tutorial or 200 Coins (first 500, then none, then 200, see §7.1); Stage 2 (key `"Stage 1"`) now needs Bronze on Island Hop or 1 000 Coins; Stage 4 and 5 keep
  their bars until S4.2. World 1 has four stages until Blink exists: the hub gate and the world panel read x / 12 stars.

### 7.7 S4.2 Blink (design check and as built, 2026-10-22; decisions: metronome now / track later, per-run beat)
- **Place:** the east **near** gate (z 302, x -320; the closed `SoonGate3` was deleted) is the gate of the stage folder `Blink` (key and folder
  `Blink`, shown "Stage 3"). The course runs **east** along z 272..335, a straight 517-stud lane from x -312 to the finish island at x 185
  (Stage 4's course lies south of it, z 203..266). `Gate`, `Top10Leaderboard`, `Arrival` and the finish portal are clones of the east far gate
  moved +60 in z (the decor at the board's spot was removed); script files were copied by hand (AGENTS "Adding a world stage").
- **Beat:** `BPM` 120 (beat 0.5 s, bar 2 s, two bars 4 s); beams use a 2 s period, plates and pistons 4 s. All timed parts are `RunSeeded`.
- **Course** (checkpoints `201`..`206` at x -312, -236, -168, -48, 47, 106; every plate faces east):
  1. *Count-in* (x -306..-246): five 8 x 8 `Plate_Disappearing` (period 4 s, 75 % solid, telegraph 0.5 s), phases stepped -0.25 so they
     vanish one after the other; the sea is the only hazard.
  2. *Beam rows* (floor 202 -> 203, 16 wide): four `Hazard_BlinkBeam` curtains 8 studs apart (1 x 18 x 18, period 2 s, 50 % on,
     telegraph 0.4 s, phases stepped -0.25 so a full-speed runner meets all four in the same state; the floor between them is safe).
  3. *Piston bridge* (106 x 6, x -162..-54): four `Hazard_PistonPush` blocks (8 x 6 x 2, stroke 8, push 55, every two bars, telegraph 0.5 s)
     from alternating sides at x -140 / -116 / -92 / -68, phases 0 / 0.5 / 0 / 0.5; a push throws you into the sea (a respawn).
  4. *Drop the beat*: (a) six 8 x 8 plates (the third is a static rest pillar) with a beam curtain over every gap (duty 40 %, plates 80 %
     solid); (b) a floor with six beams 6.4 studs apart, phases 0 / 0.5 alternating (dash, wait, dash); (c) five 8 x 8 plates (third a
     static rest pillar) to the 16 x 16 finish island and its portal.
- **Fairness check (offline, KitMath):** a runner at 16 studs/s (also 14 and 19.8) can get through every section by departing from a static
  spot; leg windows of 0.8-2.5 s per 4 s cycle (with 2 studs of body margin on beams and 5.5 on pistons), a perfect run about 40 s; a plan
  that departs 0.2 s after a window opens, run by a bot in a playtest, finished in 51.6 s without a death. A run that departs at the very edge of a
  window dies (the kill box reaches about 1.9 studs from a beam's centre).
- **Music:** `StageMusic.client.luau` (a `Music` Sound in the stage folder: attributes `BPM`, `Metronome`, `BaseVolume`; plays while that stage's run
  is active, ticks on every beat from run time with a higher tick on bar starts; a looped track would use `TimePosition` = run time mod length);
  the placeholder tick is the Creator Store sound `ui_click_2` (asset 110948579458469, by Doimens). `MusicSettings.client.luau` adds a
  "Music: On / Off" row to the Settings panel (player attribute `MusicMuted`, session only).
- **Coins** `Blink_1`..`_8` (5 easy 20, 2 risky 50, 1 talent 100 = 300): side pads off the course, a 2 x 2 pad opposite a piston, a coin hanging in a
  beam curtain's plane over a gap (collect it mid-jump while the beam is off) and a tower 11.5 studs above the last floor (Double Jump).
- **StageConfig:** key `Blink`, displayName "Stage 3", order 3, world 1, `tBase` **60** (provisional; the perfect run takes about 40 s, so 80 was too
  generous; M6a measures), reward factor 1.25, unlock Bronze on Stage 2 (key `"Stage 1"`) or 1 500. Unlock chain completed: Stage 4 (key `"Stage 2"`)
  Bronze on Blink or 2 000, Stage 5 (key `"Stage 3"`) Bronze on Stage 4 or 2 000. The hub gate and the world panel read x / 15 stars.

### 7.8 S5 Worlds hub (design check 2026-10-22; decisions with the user)
- **Hub gates:** the hub gets the gates of Worlds 2, 3 and 4 next to `GateWorld1`: clones of `GateWorld1` (1.25x stud arch, `Portal` with its name
  label, `PointLight`, the gate script) on the same circle round the plaza centre (radius about 44) at 90 / 60 / 30 / 0 degrees for Worlds 1 / 2 / 3 / 4 (positive side, away from the stars board;
  Tutorial at 142 degrees), facing the plaza: reading from the Tutorial gate the worlds run 1, 2, 3, 4 (user decision 2026-10-22). Models `GateWorld2`..`GateWorld4` (script files copied on disk, Argon creates the
  bare models, the Studio-only children are cloned in).
- **"Coming soon" (decided):** `StageConfig.Worlds[n].soon = true` for Worlds 2-4 until their stages exist (S6 flips World 2's flag, S7/S9 Worlds
  3 and 4). A soon world has no stages in `StageConfig`: its gate is shut for normal players (local barrier, the server refuses the teleport) and
  open for admins (`AdminConfig.IsAdmin`) so the island can be built and tested. The face shows "Coming soon" and the future requirement
  (`world.unlock` / `world.unlockPrice`, informational until S6 copies them onto the first stage: World 2 = 10 of 15 stars in World 1 or 2 500,
  World 3 = 10 of 15 in World 2 or 4 000, World 4 = 10 of 15 in World 3 or 6 000, per §7.2). No unlock prompt on a soon gate.
- **World 2 courtyard (decided, as built):** the same compact rectangle as World 1, cloned 263 studs south of it (x -430..-320, z 450..620, y 77) and
  **rotated 180 degrees about its centre**, so the entrance (`ReturnGate`, `Spawn` pad) is on the side facing World 1 and the finale gate will be at the far
  south end, whose course runs south, away from World 1 (a plain copy would have sent the finale lane through World 1's courtyard). `Workspace.World2`: `Plaza`,
  `Rock`, `Wall` with the gate openings, `Spawn`, `ReturnGate`, `Decor`, `StarsLeaderboard`, `WorldSign`, `WorldStarsBoard`. The five stage gates (2 + 2 on the long
  sides, 1 at the far end) come with S6; the plaza reserves the two bonus portal slots beside the return gate (S11), no portals yet. The kill floor already covers the
  area (baseplate to z 923); lanes of the later stages run east / west like World 1's. Both courtyards also get a **world sign** ("World N" on two wooden posts, 27 studs
  in front of the arrival pad) and their stars board.
- **World stars boards (decided):** each world plaza gets a board of the players with the most stars earned in that world (not the total):
  `StarBoard` is generalised to boards (`MostStars` stays the global one; `WorldStars_<n>` one OrderedDataStore per world with stages, written when
  that world's stars change, next to the global write), a board model (clone of `StartLocation.StarsLeaderboard`) and a `WorldStarsBoard`
  script per world folder. World 1's board stands beside the south return gate; World 2's board stays empty until S6.
- **Return / Home:** already world-aware (`StageConfig.Worlds`, `ReturnSpawn`, `HomeService`): the return gate of a world goes to the hub spawn,
  Home from a stage lands on that stage's `Arrival`, Home on a courtyard plaza goes to the hub. The score panel shows the world's name and its
  stars out of the planned 15 (`Worlds[n].stageCount`).
- **Not in S5:** the five World 2 stages and their gates (S6), bonus portals (S11), Worlds 3 and 4 islands (S7 / S9), a bridge.

### 7.9 S6 World 2 (design check 2026-10-22, S6.1 in full; S6.2 / S6.3 are scoped when they start)
- **Slots (World 2 is World 1 rotated 180 degrees about its centre, so every gate sits at the mirrored position):** the five gates in game order are
  stage 6 = east near (x -318.3, z 505, course runs east, band z 472..535), 7 = east far (x -318.3, z 565, east, band z 541..604), 8 = west near
  (x -431.7, z 505, west), 9 = west far (x -431.7, z 565, west), 10 = the finale gate at the south end (x -375, z 621.7, the course runs +z). Same
  gate pose offsets as World 1's (`TimerStart` 13.3 studs outside the wall line, `Arrival` 13 studs inside the courtyard).
- **Keys and folders:** `Stage6` .. `Stage10` (key = folder = position, §7.4), folders under `Workspace.World2`; checkpoint blocks of 100 from the next free
  block (the key arena holds 301-303): Stage 6 = `401`-, Stage 7 = `501`-, Stage 8 `601`-, Stage 9 `701`-, Stage 10 `801`-.
- **StageConfig entries (as GDD §3 / §5):** `world = 2`, `requires = { { id = "DoubleJump", level = 1 } }`, factor `0.5 + 0.25 x n`, `tBase` provisional (middle of
  §4's range, M6b measures): Stage 6 (Double Up) 90 s, factor 2.0, unlock 10 of 15 stars in World 1 or 2 500; Stage 7 (Seesaw) 100 s, 2.25, Bronze on Stage 6 or 3 000;
  Stage 8 (Turntable) 105 s, 2.5, 3 000; Stage 9 (Labyrinth) 105 s, 2.75, 3 500; Stage 10 (Clocktower) 135 s, 3.0, 4 000.
- **World 2 opens with stage 6** (user decision, 2026-10-22; the recommendation was to stay shut until S6.3): when Stage 6 enters `StageConfig` the world's `soon`
  flag is removed, so the hub gate follows the normal world rule (open when one of the world's stages is open: 10 of 15 stars in World 1, or buy Stage 6 for
  2 500 at the gate), the stars board and the gate's x / 15 face go live, and players meet a world with only the stages built so far (the later gates in the
  courtyard stay closed "Coming soon" doors, like World 1's `SoonGate`s were).
- **Look:** the Island Hop look (stud-textured columns from the sea, grass / sand tops, no kill parts except where a stage needs them), so World 2 matches
  World 1 until the style decision (STYLE_PREVIEW.md) is made.
- **Reach rules for Double Jump stages** (§1.0): measured in the S6.1 bot tests (baseline Run Speed 0 / Jump Height 0, one air jump; the bot jumps 0.6 studs
  before the edge and double-jumps at 0.24 s): a Double Jump crosses a **12-12.5 stud gap with 1.6-2.4 studs to spare**, a **11 stud ledge with 4.6-4.9**, a 12 stud ledge
  with none (so ledges stay at 11); a single jump with **Run Speed 5 and Jump Height 3 still crosses a 12 stud gap by 0 studs** (landed on the edge), so a gap of 12-12.5 is only a
  soft gate and the real gate on Double Up is the 11 stud ledges (single rise with every soft talent is 9.0). Rules used: Double Jump gaps 12-12.5 (never more than 13: margin 1.4 at 13),
  ledges 11, landings at least 6 x 6; **single-jump gaps at most 6.5** (a baseline single jump reaches 8.3: gaps of 8 to 10 landed on the edge), 4-5 when the next plate is 4 higher.
- **S6.1 Stage 6 Double Up as built** (key `Stage6`, east near gate (x -318.3, z 505), course east, plate centres at `u` studs from the first plate `401` at x -312; surface y 78.5):
  (1) warm-up: three 8 x 8 pillars, gaps 5; (2) **Double Jump gaps**: five 8 x 8 pillars at `u` 61.5 / 82 / 102.5 / 123 / 143.5 with gaps of 12.5, lateral stagger +3 / -3 / +3, checkpoint `402` plate at 166
  (gap 12.5); (3) **ledges**: three 6 x 6 towers 11 studs apart in height (h 11 / 22 / 33) with gaps of 6, checkpoint `403` plate at 220 (h 33); (4) a kit **lift** (`Lift1`, 8 x 8, rises 22 studs, period 10 s, pause 1.5 s,
  6 stud gaps both ends) to checkpoint `404` (h 55, plate at 252.5); (5) two **run-seeded slide movers** (10 x 8, amplitude 8, period 6 s, opposite phases, 6 stud gap to the plate and to each other at the extremes, standing still
  at their extremes for about a second) and a final **Double Jump gap of 11** from the last mover's right extreme to checkpoint `405` (h 55, plate at 339.5); (6) descent: `406` (h 45, 8 gap), pillars at h 37 / 29 / 21 (6 gaps)
  and a 16 x 16 finish island at h 13 (8 gap) with the finish portal at `u` 421.5. About 440 studs.
- **S6.1 Stage 7 Seesaw as built** (key `Stage7`, east far gate (z 565)): (1) a gentle 14 x 14 `Plate_Tilt` (Sens 2, max 12) and a rest pillar; (2) four 10 x 10 tilt plates 3 apart (Sens 5 / 6 / 7 / 8, slide angle 25) to checkpoint `502`
  (plate at 106, 6 gap); (3) a 40 x 6 **beam in a steady crosswind** (`Wind1`, push 10 studs/s, 6 on the ground) and a rest pillar; (4) four 12 x 12 tilt plates (Sens 6) with **10-11 stud gaps** (Double Jump jumps, the
  recovery after a slide-off), checkpoint `503` (plate at 277); (5) four 6 x 6 **crumbling plates** (delay 0.8 s) after a 10 gap, checkpoint `504` (343, 11 gap), a second 40 x 6 beam in **gusts** (push -14, period 5 s, duty 0.5);
  (6) checkpoint `505` (406.5), three 12 x 12 tilt plates rising 4 each with gaps of 4 inside a gust zone (`Gust3`), checkpoint `506` (h 12, 11 gap), 6 gap to the finish island (h 12) with the portal at `u` 502.5. About 510 studs.
- **Gate / courtyard:** the stage folders are `Workspace.World2.Stage6` / `Stage7`, built from clones of Blink's `Gate`, `Top10Leaderboard`, `Arrival`, finish portal and checkpoints moved +203 / +263 in z (script files copied by hand into
  `src/Workspace/World2/Stage6`, `Stage7`, Argon created the bare instances, the Studio-only parts were merged into them). The three unbuilt gate openings carry closed "Coming soon" door models `SoonGate8`, `SoonGate9`, `SoonGate10`
  (Studio-only clones of the gate without scripts), replaced by the real gates in S6.2 / S6.3.
- **Coins:** 8 per stage like the others (5 easy 20, 2 risky 50, 1 talent 100 = 300), ids `Stage6_1`..`_8`, `Stage7_1`..`_8`, none behind a score board.
- **Checks (done in S6.1):** a client bot (`Humanoid:Move` on RenderStepped with the control module disabled) crossed every leg of both courses at baseline Run Speed with one air jump, including the lift, the sliders (jumping
  when the gap is closing) and the tilt / crumble plates, the wind and the finale; the lift and slider timing is tight for a bot but fair for a player. A bot is not a human: M6b re-checks every margin.
- **Not in S6.1:** Stages 8-10 (S6.2 / S6.3), bonus portals, World 3.

## 8. Milestones (agreed 2026-10-21; status and full scopes in [ROADMAP.md](ROADMAP.md))
Stage milestones hold 2–3 stages each; every sub-milestone ends with a Studio check, the user's visual check and a commit.

| Phase | # | Milestone | Parts |
|---|---|---|---|
| A — World 1 + first live test | S1 | Stage framework | S1.1 GDD + `StageConfig` (order, keys, factors, prices, `world` / `requires`; rename the duplicate `21`) · S1.2 "Needs:" line on portal and popup, arrival warning, leaderstats Stars |
| | S2 | Quick Respawn talent | §6.2.1 |
| | S3 | Obstacle kit | S3.1 spike: tilt plate, carry, client kill (go / no-go) · S3.2 timed components + `StageCamera` · S3.3 kit-local + zones + jump lab (reach table), old spinners to the kit |
| | S4 | World 1 | S4.0 World 1 island + hub gate · S4.1 Island Hop · S4.2 Blink (rhythm) |
| | M6a | first live test + World 1 balancing | real times, `T_base`, prices |
| B — World 2 | S5 | Worlds hub | gates for Worlds 2–4, World 2 island, return / Home to the world |
| | S6 | World 2 | S6.1 Double Up + Seesaw · S6.2 Turntable + Labyrinth · S6.3 Clocktower |
| C — World 3 | S7 | Triple Jump + Dash | talents, mobile button, reach table; World 3 island |
| | S8 | World 3 | S8.1 Triple Peaks + Ice Rink · S8.2 Dash Bridge + Laser Lab · S8.3 Rising Tide |
| D — World 4 | S9 | Wall Jump + Glide | talents, reach table; World 4 island |
| | S10 | World 4 | S10.1 Wall Climb + Glide Canyon · S10.2 Moon Base + Clockwork · S10.3 Summit |
| | M6b | final balancing | all 21 stages |
| Any time after S5 | S11 | Bonus stages | S11.1 Darkness + Memory path · S11.2 Stealth + Chase · S11.3 Giant room + Minecart |

Then P3 (trading), after all 20 stages (user decision).

## 9. Open questions
Answered with the user on 2026-10-21 (S1 design check): the **Decision** column is final (numbers stay provisional until
M6); two answers differ from the recommendation (marked ≠).

| Question | Decision |
|---|---|
| World themes and names (sky, factory, storm, summit…)? | pick with the style decision ([STYLE_PREVIEW.md](STYLE_PREVIEW.md)); stud style for now |
| World gate bar: Silver on the previous finale, or "N stars in the previous world" (needs code)? | **≠ N stars in the previous world: 10 of 15** (Silver everywhere; N provisional); new unlock rule type in S1.1 |
| Scale challenge-coin values with the stage factor? | **≠ no, flat 20 / 50 / 100** |
| Semantic keys for new stages (`Blink`) instead of `"Stage N"`? | was yes; replaced 2026-10-22 by key = folder = position (`Stage3`) |
| Re-tune today's Stage 3 factor from 2.0 to 1.75 (curve) or keep 2.0? | 1.75 (already-paid Coins are unaffected) |
| Move today's spinners to the kit (smoother, no server loop)? | yes, in S3.3, optional |
| Should a world island also have a garden-style bridge? | gate first, bridges later as decor |
| Bonus stages: open with their world, no bar and no price? | yes |
| Bonus stars count toward the hub "most stars" total? | yes (they are real stages with medals) |
| Rhythm stage music: which track (licence, loop length, BPM)? | a free Creator Store track at 100–120 BPM; pick in S4.2 |
| Personal-best ghost (§5.4) as a later milestone? | yes, after S10 |
| Default respawn delay for players without Quick Respawn? | keep today's 3 s (`Players.RespawnTime`); level 1 = 1 s, level 2 = instant |
