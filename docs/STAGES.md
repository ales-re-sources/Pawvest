# Pawvest — Stage expansion plan (≈ 20 stages)

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
   limit of a single jump. **Rebuilt 2026-11-01** (K1; the user could no longer clear it without talents): **five gaps of 10.5**
   (20 → `level.1.Part_1..4` → 26; was 12 / 12 / 12 / 12 / 11.02) with the four plates spaced evenly between 20 and 26 (16 × 1 ×
   8.61, z centres 158.19 / 139.08 / 119.97 / 100.86; heights unchanged, each 1 higher; nothing downstream moved), and a
   **1-stud lip**: every landing plate (also 26's) overhangs its column (`Columns.Column_7` / `_8` / `_6` / `_5` / `_4`) by 1 stud
   on the approach side. *The lip is the trick:* a character that arrives just short of the edge while holding forward grabs it and
   climbs up (Humanoid `Climbing` state; the user's "kept pressing up and climbed the edge"); a column flush with its plate is a
   plain wall and the same jump slides down it. Measured (bot, forward held like the stick, playtest): the jump carries about 8.5
   studs without talents (WalkSpeed 16, JumpPower 50); **without talents, jumping at the edge**, 20 → 26 cleared twice in a row with
   5 edge climbs each, **jumping 0.5 stud early fails**; with Run Speed 2 + Jump Height 3 (the kid's) or Run Speed 5 it lands without
   climbing. 11 fails without talents even with the lip, flush 10.5 fails too. Coplanar audit of the plates and columns clean.
   Before: plates 6.98 deep at z 157.51 / 138.53 / 119.55 / 100.57, columns 7.00 deep at the same centres (flush), Column_4 12.00 at
   z 80.06. **Use a lip wherever a jump is meant to be "very hard but doable" at the edge of reach.**
2. **Wrap-around** (`level.2`): three 12-stud-high walls fill the whole 16-stud width of a 40-stud floor; you get past each
   one by jumping out around its side over the void.
3. **Tightrope** (21 → 22): a zig-zag of five beams (right-angle turns) with four red kill nubs to hop over. **Widened 2026-11-01**
   (K1, kid playtest: the 0.1-stud wires were too hard on a touch stick): `Part_12` / `_15` / `_17` / `_04` / `_07` are **2 × 0.4** beams
   (12-42 long, top at y 82.71 as before); the north-south ones cover the corner squares and the east-west ones end against their sides
   (no shared faces); the nubs `Part_08` / `_06` / `_14` / `_09` are 2 wide (the full beam) × 0.2 × 1, so they are hopped, not walked
   around. Before: 0.1 × 0.05 wires (14-40 long) and 0.1 × 0.2 × 1 nubs (old CFrames in the commit message of this change).
   Playtest: a bot walked plate 21 → checkpoint 22 hopping every nub without a fall; a missed hop still kills; tightrope audit clean.

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

**With the real talents (S7, 2026-10-24, World 3 plaza, Jump Height 0, every jump and the dash at the apex):** Triple Jump
(`Talent_DoubleJump` 2) gives 3 jumps (the 4th press is ignored) and rises 21.8. The dash itself measured 10.00 studs in 0.200 s at a constant
height (the real `TalentDash`; one per air time, none on the ground). Bot runs, flat reach / rise:

| Run Speed | Single | + Dash | Double Jump | DJ + Dash | Triple Jump | TJ + Dash |
|---|---|---|---|---|---|---|
| 0 (16.0) | 8.8 / 7.3 | 18.8 | 15.2 / 14.5 | 25.4 | 21.1 / 21.8 | 32.1 |
| 5 (20.8) | 11.4 / 7.3 | 22.3 | 19.8 / 14.5 | 30.1 | 27.4 / 21.8 | 37.7 |

A dash at the apex adds 10-11 studs to any jump. A dash later in the fall adds a little more, because it stops the fall for 0.2 s.
~~A Dash gate is a flat gap above 29.8, or a gap of 12-18 under a low ceiling~~: superseded by the S8.2 measurements below (the open
window was 2 studs, and a ceiling does not stop air jumps).

**Long Dash (Dash level 2, S8.2, 2026-10-26; bot with the real numbers, dash at the apex, 0.32 s at 50 studs/s = 16 studs):**

| Run Speed / Jump Height | Single + Long Dash | DJ + Long Dash | Triple Jump | TJ + Dash | TJ + Long Dash |
|---|---|---|---|---|---|
| 0 / 0 | 25.3 | 31.6 | 20.6 | 31.7 | 37.5 |
| 5 / 3 | 29.0 | 38.3 | 29.8 | 40.8 | 46.5 |

Real gaps (edge to edge, landing plate level with the take-off): baseline TJ + Long Dash crosses 36; baseline TJ + Dash and a maxed Triple
Jump without Dash fail at 32; baseline DJ + Long Dash fails at 33. **A Dash gate is a flat gap of 34**: 2+ studs of margin both ways. A
maxed Triple Jump with the short Dash (40.8) also crosses it: Run Speed + Jump Height stand in for Long Dash, a soft-talent shortcut
(user, 2026-10-26: shortcuts are welcome, they give replay value).

**Low ceilings do not gate air jumps (S8.2 bot tests):** under a solid ceiling 7-9 studs above the floor, a Triple Jump that lets the
character drop 2-3 studs below the take-off height before each air jump hovers on: it crossed 14-18 studs under an 8-stud ceiling, as
far as a single jump + Dash (14-16). A kill ceiling leaks the same way and its margin depends on the avatar's height. Ceilings stay
decoration or soft gaps.

**Avatar size rule (2026-10-29; design for every avatar, players keep their bodies).** An R15 character collides only with its
`HumanoidRootPart` and torso (head, limbs and accessories never collide), so a roof stops it at the root's top = HipHeight + root height.
ObstacleKit's kill test checks every body part's box (accessories too until 2026-10-29, now left out), so a kill part above reaches the head first. Measured on rigs
from `HumanoidDescription`s with the standard body parts (`Players:CreateHumanoidModelFromDescription`):

| Avatar | HipHeight | Collider top | Head top |
|---|---|---|---|
| classic, height 0.9 | 1.80 | **3.6** | 4.9 |
| classic, height 1.0 (Lekzdrh's avatar: 4.1) | 2.00 | 4.0 | 5.2 |
| classic, height 1.05 | 2.10 | 4.2 | 5.3 |
| Rthro body type 1, height 1.05 | 3.10 | **5.2** | 6.3 |
| Rthro body type 1, proportions 1, height 1.05 | 2.77 | 4.9 | 6.0 |

`BodyHeightScale` alone does not even them out (body type moves the collider from 4.2 to 5.2 at one height); only fixed scales plus forced
standard body parts would, and that changes how players look, so the stages are designed for the spread instead. Bundles with their own body
meshes were not measured and may lie outside it. Rules:
- **Collider: plan for 3.6-5.2.** A gap to walk under is **at least 6** (everyone fits) or **at most 3.4** (nobody does), never in between.
- **Jump headroom** under a roof is counted for the 5.2 collider: the feet rise at most roof - 5.2. **In a jump the head counts too**
  (measured 2026-10-29 in the colour shaft: a body-type-1 avatar, head top 6.56, bonked at feet 7.3 under a 14-stud roof, and the roof
  throws the character down, so the arc ends early): an unhindered single jump (rise 7.3) needs about **14** for the tallest avatar
  (7.3 + 6.6), 12.2 for a classic one. A spike to be hopped under a roof gets a lane of at least 14; lower lanes only take spikes meant
  for a jump + dash (rows).
- **Accessories never kill (since 2026-10-29, user decision):** ObstacleKit's hazard test (kill parts, beams, kill movers) checks only
  the character's own body parts (its BasePart children; accessories and held tools are left out, the list follows parts swapped by
  `ApplyDescription`). The head still counts.
- **No kills through solid parts (2026-10-29):** the head and limbs do not collide, so in a jump they pass into a thin slab above and
  reached a spike standing on it (the user died that way under `ShaftSlab1_26` and `ShaftSlab2_27`; the probe: a Triple Jump on slab 1
  put the head inside `ShaftSlab2_27`'s kill box for 5 frames). A touch now counts only when a ray from the root to the nearest point
  of the hazard (stopping 0.15 short of it) meets no CanCollide part, ignoring the character and the hazard's own model (a gargoyle's
  body). Checked: Triple Jumps under both slab spikes survive; walking into `ShaftSlab2_27` and into the `Right2_13` row kills, a jump
  under `Ceiling_21` kills, walking under it does not; no errors. The ray runs only when the overlap test already found a touch.
- **Kill parts above a walkway: at least 7.5** over its floor (head 6.3 plus a margin); ceiling spikes meant to be walked under follow this.
- Decor that can be walked into (tree crowns, sign boards) is either above 6 or reaches the ground; otherwise only part of the players bump it.

*Scan (2026-10-29, Edit mode, every Block part's top in the stage folders, the hub and the Garden; a 1.5 x 1.5 column free up to 3.4, then the
first solid or `KitKill` part above it; movers, doors, tilt plates and gates at their authored positions; MeshParts, wedges and side openings
above a floor not covered; 57 of the 60 `KitKill` parts have `CanQuery` off, so kill parts were measured from their own boxes):*
- *Gameplay:* Stage 14 `Block_Float2` (4.2 over the lane-0 floor; Lekzdrh's avatar walks under it, a taller one cannot); the key notch in
  `E_Bar` (4.5 over `SlotHatch`; the key's `Hit` reaches 0.4 into the slot, so it is still taken from there, unverified for a 5.2 avatar);
  `Ceiling_21` (kill box 6.46 over `E_ArmTop`: a 6.3 head has 0.16, a hat dies); Stage 15 `Chimney.Lintel` (5.0 over `Slab1_N`: the
  door's upper part beside slab 1 lets small avatars out of the shaft, back to where they came from; harmless, but in the band).
  Fixed the same day with the four-lane tower (§7.12 "Vault tower"): `Block_Float2` down to h 3.4, `Ceiling_21` 10 over its floor; the
  notch and the Stage 15 lintel are open.
- *Jump headroom over floor spikes (feet room above the spike's hit for a 4.0 / 5.2 collider):* Stage 14 tower `Right2_13`, `Slab_23`
  0.9 for 5.2 (2.1 for 4.0), `Right1_12` 1.0, `BaseTiny_15` / `Column1_19` 1.4, `ArmTop_24` 1.9; the lane-0 spikes (15.4 roof) and
  `PlatformA`'s (13.5) 6.0 or more. No `KitKill` floor spike in another stage has a roof within 14 studs. The four-lane tower gives
  every row 5.66 for a 5.2 collider (lanes 12.25, hits 1.39).
- *Decor:* tree crowns (`Decor.Tree1` / `Tree2`) 3.5-5.9 over the World plazas and the courtyard wall tops, `WorldSign.Board` 5.0 over the
  plazas, Tutorial landing-pad trees over hedges and rocks, the Tutorial welcome sign 4.5 over the `Inlay`.
- *Legacy scripted kill parts (18):* none hangs 3.3-6.6 over a floor.

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

### 2.3.1 Moving parts vs frame (build rules; user, 2026-10-26: the Ice Rink door flickered "again")
A part that moves (door, lift, piston, flipper) must never lie in the same plane as a face of the static geometry around it
while facing the same way: the renderer cannot decide which one wins and the two textures flicker in a mixed pattern
(z-fighting). It hit the Ice Rink door twice: a 2-stud door in a 2-stud frame (walls, lintel) shares all four side planes with
the lintel the moment it slides up into it.
- **Make the moving part thinner than its frame** (door 1 stud in a 2-stud frame, a lift 0.2 narrower than its shaft) and never
  flush with a neighbour in any direction it travels; never slide a door *into* the lintel, swing it (`OpenTurn` + `OpenHinge`,
  ObstacleKit header) or let it drop into a slot that is wider than itself.
- Faces that touch but point opposite ways (a door resting on its sill, its top under the lintel) are fine.
- Frame walls go down to the sea / the ground, not just under the plates: a player who falls beside the course can jump into any
  gap below a floating wall and reach the part behind it (the Ice Rink's `DoorWallL/R`).
- **Check before you finish a door:** run `tools/kit_coplanar_audit.luau` through the Studio MCP `execute_luau` (Edit). It walks every
  `KitDoor` from closed to open and lists each coplanar, same-facing, overlapping face; the result must be "clean" for the stage
  you touched. (State 2026-10-26: it also lists `Stage9.Maze.Big.ExitDoor` vs the posts / floor and `Stage10.Movers.Door_10` vs
  `Tower.Core`; not looked at yet.)
- **Static parts z-fight too** (S8.2b, user 2026-10-26: Stage 14's back panel flickered seen from behind / from the start island): room
  parts built 10 deep ran through the 2-stud back panel and shared its outer face. Parts that overlap must not share a face plane: end
  floors, ceilings and walls at the panel's inner face, put walls under (not through) a ceiling, start a beam on its emitter. Set
  `STATIC_ROOT` in the audit (e.g. `"World3.Stage14"`) to check a whole stage's static parts; hidden zones are skipped. (State
  2026-10-26: Stage 14 is clean except the gate and finish-arch clones every stage shares: arch stones that overlap each other.)

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
- **Colour language (2026-10-25):** red = kills, yellow / gold = movers and pushers, blue = tilt plates, teal = disappearing / flip
  plates, green = switches and checkpoints, pastel violet = low gravity, **pink (`#FF46B4`) = bounce** (stud trampolines,
  the KeyArena orb). A new component takes a colour not on this list.
- **Visuals are deferred (user decision 2026-10-21):** every kit component is deliberately plain (grey / coloured boxes); wind
  and updraft particles, plate looks, beam glow etc. come in a later visual pass together with the world style decision
  ([STYLE_PREVIEW.md](STYLE_PREVIEW.md)), as presets on the `StageKit.Obstacles` templates. Only the functionality (attributes
  and behaviour in the script headers) is fixed.
- **S3.1 spike result (2026-10-21):** carry by frame delta is exact (no drift) and needs a short air-carry (0.5 s) after
  jumping off; tilt plates need an explicit slide-off (freefall + downhill velocity) because `MaxSlopeAngle` is 89; the client
  kill reaches the server in one message; 100 movers cost 0.34 ms per frame. Other players see riders ~0.2 s behind a moving
  platform (replication delay). Details: `git show 53bd79b:docs/ROADMAP.md` (S3).
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
    height); the teal gate is full height (the 3-unit pillar alone is cleared by a Triple Jump); the orb (pink since 2026-10-25, the bounce colour; drawn yellow) is a bounce
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
  - *Done in S8.2b (2026-10-26):* the prototype became room 1 (the Key Vault) of Stage 14, see §7.12; `Workspace.KeyArena` is gone.

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

### 5.5 Idea: branching appearing steps (user, 2026-10-28)
A stage built on `KitStep` (ObstacleKit: a block is solid only once the player stood on the previous one of its group). Tried in
the vault's green-key half and taken out again (the user: not a fan of it there). The idea for a stage of its own: stepping on one
block makes two appear, and the player has to pick the right one; the other leads to a dead end. `KitStep` would need a block to name
the block(s) it follows (e.g. a `After` attribute instead of the plain `Step` order). Unscheduled.

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
| 6 | Double Jump (world reward) | 0 | 9 450 | 0 % | ✔ |
| 11 | + Triple Jump | 5 000 | 26 950 | 19 % | ✔ |
| 13 | + Dash | 13 000 | 36 400 | 36 % | ✔ |
| 16 | + Wall Jump | 23 000 | 53 200 | 43 % | ✔ |
| 17 | + Glide | 35 000 | 59 500 | 59 % | ✔ |

With Run Speed and Jump Height (5 300) and Quick Respawn (4 000) the whole tree costs **44 300**. Double Jump is a world reward since
2026-11-01 (granted when World 2 opens, GDD §6, ROADMAP K1; it cost 3 000 from 2026-10-23, 1 500 before). Talents stay a real investment that competes with
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
- **Return / Home:** already world-aware (`StageConfig.Worlds`, `ReturnCFrame`, `HomeService`): the return gate of a world lands in front of the world's hub gate, looking out of it
  (`HubExitCFrame`, like stepping out of a door; the Tutorial's return portal does the same at its hub portal), the finish portals and Home from a stage land on that
  stage's `Arrival` facing the island (away from the gate), Home on a courtyard plaza goes to the hub. The score panel shows the world's name and its
  stars out of the planned 15 (`Worlds[n].stageCount`).
- **Not in S5:** the five World 2 stages and their gates (S6), bonus portals (S11), Worlds 3 and 4 islands (S7 / S9), a bridge.

### 7.9 S6 World 2 (design checks 2026-10-22 / 23; all five stages built; compacted 2026-10-24, the full build and tuning log is `git show c8767cd:docs/STAGES.md`)
- **Slots (World 2 is World 1 rotated 180 degrees about its centre, so every gate sits at the mirrored position):** stage 6 = east near (x -318.3, z 505, course east), 7 = east far (x -318.3, z 565, east),
  8 = west near (x -431.7, z 505, west), 9 = west far (x -431.7, z 565, west), 10 = the finale gate at the south end (x -375, z 621.7, the course runs +z). Same gate pose offsets as World 1
  (`TimerStart` 13.3 studs outside the wall line, `Arrival` 13 inside). Folders `Workspace.World2.Stage6..10` (key = folder = position, §7.4), checkpoint blocks `401`- / `501`- / `601`- / `701`- / `801`-
  (the key arena holds 301-303). Each stage was built from clones of the previous gate / board / `Arrival` / finish and checkpoints, script files copied by hand (AGENTS.md "Adding a world stage").
- **StageConfig:** `world = 2`, `requires = { { id = "DoubleJump", level = 1 } }`, factor `0.5 + 0.25 × n`, provisional `tBase` (M6b measures):

  | Stage | Name | tBase | Factor | Unlock | Length | Checkpoints |
  |---|---|---|---|---|---|---|
  | 6 | Double Up | 90 | 2.0 | 10 of 15 World 1 stars or 2 500 | ~630 studs | 401-408 |
  | 7 | Seesaw | 80 (was 100) | 2.25 | Bronze on 6 or 3 000 | ~760 | 501-508 |
  | 8 | Turntable | 75 (was 105) | 2.5 | Bronze on 7 or 3 000 | ~550 | 601-606 |
  | 9 | Labyrinth | 100 (was 105, 140 during the maze rework) | 2.75 | Bronze on 8 or 3 500 | ~360 + maze | 701-705 |
  | 10 | Clocktower | 75 (was 135, 90) | 3.0 | Bronze on 9 or 4 000 | ~700, 120 high | 801-806 |

  (`407` / `408` / `507` / `508` were added when the courses were lengthened, so numbers are not in course order: Stage 7's `506` (6 studs before the finish, after the `Fin` climb) was deleted 2026-10-29 and its plate kept as `Pillars.EndPlate`, so `508` is its last; Stage 6's `406` was deleted 2026-10-26, `408` is its last checkpoint.)
- **World 2 opens with stage 6** (user decision, 2026-10-22): the `soon` flag was removed with Stage 6, so the hub gate follows the normal world rule (10 of 15 World 1 stars, or buy Stage 6); the unbuilt openings
  carried closed "Coming soon" doors (`SoonGate8..10`, replaced by the real gates). **Look:** the Island Hop look (stud columns from the sea) until the style decision (STYLE_PREVIEW.md).
- **Reach rules for Double Jump stages** (measured with a baseline bot, Run Speed 0 / Jump Height 0, one air jump; it jumps 0.6 studs before the edge and double-jumps at 0.24 s): a Double Jump crosses a **12-12.5 stud gap
  with 1.6-2.4 studs to spare** and an **11 stud ledge with 4.6-4.9** (12 has none, so ledges stay at 11); a single jump with **Run Speed 5 + Jump Height 3 still crosses 12 by 0 studs**, so the real gate is the 11 stud ledge
  (single rise with every soft talent is 9.0). Rules used: Double Jump gaps 12-12.5 (never over 13), ledges 11, landings at least 6 × 6, **single-jump gaps at most 6.5** (a baseline single jump reaches 8.3), 4-5 when the next plate
  is 4 higher. The developer account (Run Speed 3 / Jump Height 3) covers about 21 studs with a running Double Jump, so square plates cannot force timing for such a player.
- **Coins:** 8 per stage (5 easy 20, 2 risky 50, 1 talent 100 = 300), ids `Stage6_1..8` … `Stage10_1..8`.
- **Stage 6 Double Up:** pillar warm-up; five 8 × 8 Double Jump pillars (gaps 12.5, lateral stagger ±3); three 6 × 6 ledge towers 11 apart in height; a kit lift (rises 22, period 10, pause 1.5 s); two run-seeded slide movers
  (amplitude 8, period 6 s, opposite phases) and a Double Jump gap of 11; a zigzag of six 6 × 6 pillars (gaps 9 along, 10 sideways, margin 1.6-2.9; a diagonal reach is what counts); five sideways-sliding stones (amplitude 9,
  period 7 s, phases 0 / .2 / .4 / .6 / .8, about 2 s waiting each); descent to the finish island. Lengthened from 440 to 630 studs after the user's "too short" (a perfect run is about 60 s).
- **Stage 7 Seesaw:** tilt plates (teaching plate, a chain of four, a recovery chain with 10-11 stud gaps, a gauntlet of six zigzagging, three rising ones in a gust zone), two 40 × 6 beams in wind (steady crosswind push 10;
  gusts push -14, period 5), a 60 × 6 beam in opposed gusts, crumbling plates (delay 0.8 s). After "still pretty simple" the plates are touchier: `Sens` 3.5 (teaching, slide angle 25), chain 7.5 / 9 / 10.5 / 12, recovery and
  finale 9, gauntlet 12, slide angle 22 (a plate slides you off at about 1.8-2.4 studs from its centre; lower `Sens` / raise `SlideAngle` if it is too hard, M6b).
- **Stage 8 Turntable:** new kit kind `Flip` (rests, tints for `Telegraph` s, turns 180° in `Turn` s, not solid while turning, so the rider drops; a turning flipper carries nobody). Every mover is run-seeded. Final course (after "still too easy"):
  a kicker paddle on `Turn1` (`Push` 40, `PushLift` 25, new `PushTime` 0.4 s: a one-shot push was braked within 2 studs) and spinning planks `Plank1/2` (60 / -60 deg/s, line up every 3 s, only a jump around the line-up reaches the next);
  two sweeper pads (kill bars 75 / -95 deg/s, corners are the safe spots); flipper rows (period 5 / 3.5, telegraph 0.5, each flipping 0.6 / 0.55 s *after* the one behind, so a steady runner follows the wave); two flat windmills
  (30 deg/s, 6-wide arms); two Double Jump ledges and the finale turntable under a -55 deg/s sweeper; crumbling plates; knock-back follows the mover's motion at the character.
- **Stage 9 Labyrinth:** `KitMaze.client` plays tagged `KitMazeWall` parts (`Pattern` per layout step, `Period`, `Phase`, `Telegraph` 1.5 s: a rising wall glows as a floor line, a sinking one flashes; `RunSeeded`; a change takes 0.4 s and a rising wall
  pushes an overlapping character aside). Cells are 10 studs (16-high walls under a 60° iso view hide less than a cell). Layouts are generated and seeded (a random spanning tree, then swaps that cut the current route and reconnect elsewhere, so
  every layout is a connected tree). An invisible ceiling at the wall tops (10 studs thick, underside at 94.5) holds every talent (a baseline single jump does not clear a 9.5 hedge).
  **Roof exploit fixed 2026-10-25:** the ceiling used to be a 1-stud slab flush on the wall tops, so a Double / Triple Jump from the entry pad `703` or exit pad `704` (outside the walls) rose above 95.5 and landed on it, walking over the maze. Each maze now has four invisible
  fence slabs (`Big_Fence_N/S/W/E`, `Small_Fence_*`; y 94.5-160, 3 thick, flush with the outer walls and 2.5 studs outward) so nothing outside can be landed on; ground-level openings are untouched. Studio-only parts. Jump boosts above about 65 studs of rise would need a taller fence. Each maze has a `CameraZone` (Iso, Yaw 90, Pitch 70 since 2026-10-27 (was 60: passages were hard to read between the wall tops; a 16-high wall now hides about 5.8 studs of floor instead of 9.2), Fov 25, Distance 180 / 260) and a `KitGhostZone`.
  *Small maze:* 7 × 7, 2 layouts, period 8 s. *Big maze (reworked 2026-10-23, "bigger and harder"):* 15 × 15 (x -630..-780, z 535..685), entry from `703`, exit door (`KitDoor`, group `LabyrinthExit`) opened by a latching `KitButton`
  (`Latch`: open for the rest of the run, kept through a death) in a 3 × 2-cell switch room with checkpoint `705`, so the maze is crossed twice; 4 layouts, period 5 s, 36 shifting walls; four red kill guards in guard lanes that stay open in every layout
  (max 11-13.5 studs/s, end cells safe, the generator accepts only routes that run ≤ 2 cells along a lane); six blinking lava tiles (period 4, on 40 %; `Lava_n` kill boxes are 7 × 7 inside the 9 × 9 red `LavaMark` tile since 2026-10-27: R15 feet and legs do not collide, so at run speed a foot reached up to 1.2 studs through a 1-stud wall and `Lava_1` killed a player standing behind `Wall_61-76`; the hit test ignores walls, so keep a 1-stud margin where a kill box meets a wall) each under a neon `LavaGlow` column (the iso camera hides about 9 of a cell's 10 studs behind a wall). **Lava flames (2026-10-27):** each `Lava_n` carries two Studio-only `ParticleEmitter`s that `ObstacleKit` switches with the beam state: `Flames` (fire texture, 90/s, rising 10-17 studs/s, only while the tile is on) and `Embers` (`Warn = true`: sparks already in the 0.8 s telegraph, so the tile "heats up" before it turns deadly). They need the emitter children to stay under the `KitBeam` part; the 0.15 s of tail after switching off is the particles' own lifetime.
  A glass lane divider `LaneDividers.World2West` (z 523.5) separates the Stage 8 / 9 lanes. Offline bot: entry → switch → exit in 48.75 s (old maze 18.5-20 s). After the user's first run (1:46 got Gold) `tBase` went to 100 (Gold < 80 s, Silver < 110 s,
  Bronze < 160 s; clean run estimated 70-75 s); the old-maze records were removed from `leaderboard_Stage9` and both profiles (snapshots `leaderboard_Stage9_before_rework_cleanup`, `profile_<id>_s9_cleanup`). The old maze copy is `ServerStorage.Stage9_OldBigMaze` (delete after the user's check).
  **Coin height (2026-10-27):** the seven maze coins (`Stage9_1`-`Stage9_7`, Studio-only parts) sit at y 86.0, 7.5 studs above the floor (78.5; were 81.2): under the old 60° iso view a 16-high wall hid a coin below about 7.3 studs when it stands in a cell centre, so at 2.7 studs they were almost never visible (at the current 70° the limit is about 2.3 studs, so 7.5 has margin). Keep them at 7.5 or higher; a standing character does not reach them, a normal jump does (server reach limit 15 studs), and the invisible ceiling starts at 94.5. `Stage9_8` stands on a pillar outside the maze and was left alone.
- **Stage 10 Clocktower:** a climb round a tower; everything moves on **one 1 s clock tick** (Blink's metronome sound at 60 BPM, every hazard run-seeded). Kit: Spin `Tick` / `TickMove` (`KitMath.Ticked`), `KitButton` / `KitDoor` (Group, `Time`, `Latch`, `OpenAxis` /
  `OpenDistance` / `OpenTime` / `OpenTurn`; kit-local; a countdown of whole seconds floats over button and doorway). Layout: a 40 × 40 `Tower.Core` at (-347, 686) up to h 120 with a `Belfry` (h 120-157.5) carrying four clock faces; the course is three laps on a square of
  half-size 28, 12 sides of 56 studs, rising 10 per side, corner pads every corner, checkpoints `802`-`806` at corners 2 / 4 / 6 / 8 / 11. Sides in final order: lap 1 ticking gears, wall pistons (stroke 10, out 1 s in every 3), tilt plates in outward gusts, tick beams;
  lap 2 tick flippers + crumbling steps + **door 1**, clock platform with a ticking kill hand, ticking planks; lap 3 pendulums (brass, they only knock you off), conveyor (-12) with three hurdle beams, tick flippers + **door 2**, crumbling stairs between two pistons up to the roof.
  Doors cover two sides, stay open **11 s** (bot with Run Speed 3: 8.3-9.9 s for each stretch), sit at s 44.5 behind a `Doorstep` slab so the checkpoint behind cannot be touched past a shut door; buttons are 8 × 5 blue pads on the path. The finish portal stands on the belfry top
  behind a `BelfryLadder` with a kill beam on the tick at h 136 (stop below it and climb when it switches off). A **roof ring of 12 stud gargoyles** (7 larger ones were reworked into the user's layout: kill gaps 1.5-2.5 studs, wings to roof +14, kill boxes exactly their silhouette) blocks Double Jump
  shortcuts onto the roof (bot peaks h 126-132); `Gargoyle_11` is a gate (`KitDoor`, `OpenTurn` 90, `Button_11` on `806`, 3.5 s) that turns aside to let the course onto the roof. Stairs `Crumble11_3..5` are level at h 115 (a double jump from 117-119 clears the wings).
  Falling from a lap lands on the lap below (Quick Respawn's fall reset returns you). Fixes that matter: `QuickRespawnClient` forgets the plate when a run ends and when the character moves more than 40 studs in a frame (finish, Home, gates teleport about 100 studs below the last plate);
  steps must not end under a checkpoint plate (it sticks 8 studs back toward the arriving side); flipper waves must follow a hopping player; doors must be ≥ 20 high. Decor in the stud style from the place's own StudPack variants (27 windows, doors, lintels, pistons as dark-steel rams with an orange push plate).
- **Checks:** a client bot (`Humanoid:Move` on RenderStepped, control module disabled) crossed every leg of all five courses at baseline Run Speed with one air jump, each stage had one timed run from the gate to a payout, and the maze, door, gargoyle and latch behaviours were
  verified in playtests (developer profile, snapshots restored). A bot is not a human: M6b re-checks every margin. *Not checked:* the look (the viewport rendered white in these sessions), human difficulty and real `T_base` of every stage, the tick sound in a run, a full timed Stage 9 run.

### 7.10 S7 Triple Jump + Dash + World 3 courtyard (design check 2026-10-24; decisions with the user)
- **Triple Jump** = `DoubleJump` level 2 (costs 3 000 / 5 000; `TalentConfig.AirJumps` already scales). Decided: **the row renames itself**: per-level names
  (`names = { "Double Jump", "Triple Jump" }`, strings `talent.name.DoubleJump` / `talent.name.DoubleJump.2`); the Skills row shows the name of the level it
  sells ("Double Jump 0/2", then "Triple Jump 1/2", maxed "Triple Jump 2/2"), and a requirement `{ id = "DoubleJump", level = 2 }` reads "Needs: Triple Jump".
- **Dash** (`Dash`, 1 level, 8 000): in the air only, **once per air time** (reset on landing / climbing / swimming like the air jumps), a **flat** burst
  (decided): height is held for 0.2 s at 50 studs/s (about 10 studs), then the normal fall resumes with the run speed in the dash direction. Direction = the
  move direction, else the character's facing. Air jumps stay usable after a dash (combos are in the reach table); a jump pressed during the 0.2 s is ignored.
  Controls (decided): **Q**, gamepad **X**, and an on-screen **Dash** button on touch devices (`ContextActionService` touch button beside Jump), bound only
  while the player owns the talent. Client-driven like Double Jump (`TalentDash.client`); the level is server-owned. A short local trail shows the dash.
- **No world gate on buying**: both talents can be bought any time (talent coins of earlier worlds use them, §7.3); the course geometry is the gate (§6.3).
- **Telemetry** (TELEMETRY.md T1b bound): with DJ 0-2 and Dash 0-1 the loadouts grow from 144 to 432 (fail events 10 800 > 8 000), so Run Speed is
  bucketed in the loadout (level 0 → `RS0`, 1-3 → `RS2`, 4-5 → `RS5`): 3 x 3 x 4 x 3 x 2 = 216 loadouts, fails 5 400, completes 4 320.
- **Reach table** (§1.0): measured again with the real talents in the jump lab: Triple Jump, Dash after a single / double / triple jump.
- **World 3 courtyard** (decided: the free sea **east of the hub**, not south of World 2): a copy of World 2's courtyard (Plaza, Rock, Wall with the gate
  openings, Spawn, ReturnGate, Decor, StarsLeaderboard, WorldSign) moved by (+225, 0, -1150): x -205..-95, z -700..-530, same orientation as World 2
  (entrance, `Spawn` and the return gate on the north side (-z, z ~ -700), the finale gate at the south end (z ~ -530), its course running south (+z) toward
  z ~ -250, clear of the Tutorial (x -473..-425); side lanes east up to x ~ 450 and
  west down to x ~ -800, clear of KitLab (x 447+, z -500..-190), the hub (x -1214..-1038) and the garden). The kill floor already covers it. Scripts:
  `World3/ReturnGate` and `World3/WorldStarsBoard` copied on disk from World 2. `Worlds[3].soon` stays true (S8 flips it with the stages): admins only.

### 7.11 S8.1 Triple Peaks + Ice Rink (design check 2026-10-24; decisions with the user)
- **Slots:** World 3 is World 2 moved by (+225, 0, -1150), so the gates sit at World 2's positions moved the same way: stage 11 = east near gate
  (x -93.3, z -645, course runs east, band z -678..-615), stage 12 = east far gate (x -93.3, z -585, east, band z -609..-546); the sea east of the
  courtyard is empty up to KitLab (x 447+, z -500 and north), so a course may run to x ~ 430. Gate / board / `Arrival` / finish / checkpoints are clones of
  Stage 6's / Stage 7's moved by (+225, 0, -1150). The other three openings get closed `SoonGate13..15` doors like World 2 had.
- **Keys and folders:** `Stage11` / `Stage12` under `Workspace.World3`; checkpoint blocks `901`- and `1001`-.
- **StageConfig:** `world = 3`, `requires = { { id = "DoubleJump", level = 2 } }` (Triple Jump); Stage 11 `tBase` 85 (was 110; Gold < 68 s), factor 3.25, unlock 10 of 15 stars in
  World 2 or 4 000; Stage 12 `tBase` 90 (was 120; Gold < 72 s), factor 3.5, Bronze on Stage 11 or 4 500 (GDD §3 / §5; provisional, M6b measures).
- **World 3 opens with stage 11** (user decision, as World 2 did): `Worlds[3].soon` is removed when Stage 11 enters `StageConfig`.
- **Reach rules for Triple Jump stages** (§1.0, measured again in the bot tests of S8.1): the gate is the **ledge height**, not the gap (a Double Jump with
  Run Speed 5 + Jump Height 3 reaches 21.6 flat, more than a baseline Triple Jump's 21.1, but rises only 18.0 against 21.8). Ledges between the best Double Jump
  and the baseline Triple Jump, gaps a baseline Triple Jump crosses with margin.
- **Stage 11 Triple Peaks** (signature: Triple Jump towers; also elevators and crushers): warm-up on Double Jump ledges, a first Triple ledge over a safe floor,
  peaks climbed by Triple ledges, kit lifts between peaks (jump off at the top onto the next ledge), a ridge under **crushers** (kit `Piston` pointing down with
  `Kill`, telegraphed), the summit and a descent to the finish island. No new kit code.
- **Stage 12 Ice Rink** (signature: ice; also wind and timed doors): a teaching rink with a soft stop, ice plates with gaps (brake before the edge), crosswind
  on ice, a pressure door (`KitButton` / `KitDoor`) with a sprint across ice, Triple ledges taken from ice, a finale.
- **Ice = kit ice** (user decision): new `KitIce` tag in `ObstacleKit`. While the character stands on a `KitIce` part (the kit's floor ray), the client takes over
  its horizontal velocity: it moves toward the input direction x walk speed at `Accel` studs/s² and coasts without input, slowing at `Brake` studs/s²
  (attributes on the part); since 2026-10-29 the slide also carries through the air (**ice-air**, below). Same on every device, tunable per part; it stops at once on death.
- **Ice look (user pick "variant 3", 2026-10-29; Studio-only):** all 17 `KitIce` parts (the 16 of `Stage12.Ice` and `Stage15.CrusherIce.IceRidge`) are smooth `Plastic`
  (no MaterialVariant, `(0.70, 0.87, 0.98)`) and carry decoration children (Anchored, CanCollide / CanTouch / CanQuery / CastShadow off): a `Cap` (`Glass`, `(0.3, 0.65, 0.95)`,
  Transparency 0.3, 0.4 thick, its top 0.05 above the ice), `RimN/S/W/E` white `Studs` bars (0.4 wide, 0.6 high) round the top edge and `CollarN/S/W/E` white `Studs` bands
  (1.6 high, 0.2 proud) on the side faces. **Why:** smooth + glossy = slippery, studs = grip, so the studs only frame the slick surface (the first try, a studded body under a
  translucent cap, still read as grip; the white shine streaks read as painted lanes and were dropped). The floor the kit sees is still the ice part itself (the tag and
  all attributes are on it), the decoration never collides. A side where another collidable part is within 0.5 studs of the face (rails, walls, the next ice part) gets no rim /
  collar there (`I1`, `I2`, `I3`, `Track3`, `WindBeam`, `Rink1`, `IceRidge`); only a neighbour that is flush with the ice top (a joint, a rail) suppresses the **rim**: the tall glass walls beside `IceRidge` and the `IceDoor` beside `Track3` do not, so those got their rims added by hand (`IceRidge` `RimW` / `RimE`, `Track3` `RimE`); `WindBeam`'s `RimN/S` and `CollarN/S` start 0.3 past the pressure `Door.Button` (8.4 wide, wider than the 8-wide beam, which had blocked its whole long sides) and run to the east end. Applied by script, so a part that is resized needs its children redone. The switch to Plastic **broke the slide** (fixed by the kit, see ice-air below).
- **Button / switch look (all stages, user pick "raised plates, no red", 2026-10-29; Studio-only + one kit line):** the pads were Neon (blue / yellow buttons, green switches); red and orange
  mean "kills you" in this game, so no pad is ever red. Every `KitButton` and `KitSwitch` in the stages (15: Stage 9 `Maze.Big.Switch`, Stage 10 `Button_5/10/11`, Stage 12 `Door.Button`,
  Stage 14 `Switch_Lane1/2` and `ColourShaft.Toggle0/1`, Stage 15 `Headwind.Button` and `Chimney.Toggle0-3`; the `ServerStorage.StageKit.Obstacles.Switch_Toggle` template) is the part itself
  as `Plastic` + `Studs`, azure `(0.0, 0.6, 0.86)` (the kit still turns a pressed button green, `BUTTON_ON_COLOR`, and back), grown upward so its top stands 0.6 above the floor it sits in,
  plus a child `Base`: a charcoal `Studs` slab (floor - 0.05 to floor + 0.2) that reaches 0.9 past the plate on every side where the floor continues (0.03 inside the plate edge where it
  does not: a gap bridge like `Button_5` / `Button_10`, an overhanging button like `Door.Button`), CanCollide / CanQuery / CanTouch / CastShadow off. The colour-coded `Switch_Red` / `Switch_Blue`
  of `KitLab` and the templates are untouched. **Click:** `ObstacleKit` now plays `ReplicatedStorage.SwitchSound` once per step-on of a pressure button (`lastButton`, like `lastSwitch`);
  colour switches already click through `KitWires`. Not playtested.
  - *Buttons over a gap (user, 2026-10-29: "the black lining is not done properly"):* the rule above left a button that bridges or overhangs a gap without any border
    on those sides (`Button_5` was a blue block with a black strip beside it on the checkpoint side). Now the 8 such pads (Stage 10 `Button_5/10/11`, Stage 12
    `Door.Button`, Stage 14 `Switch_Lane1/2`, `ColourShaft.Toggle0/1`) are built as **housing + cap**: the kit part itself is the charcoal `Studs` housing, its top
    lowered to floor + 0.25 (0.05 above the `Base` slab's top, so no shared plane), and a child `Cap` (azure `Studs`, 0.35 thick, top at floor + 0.6 as before,
    Anchored, CanCollide / CanQuery on, CanTouch off) covers it, inset 0.9 on every side over a gap and flush on the floor sides (the `Base` gives the border there).
    The pressable footprint is unchanged: `ObstacleKit` treats a hit on a button's / switch's `Cap` as the part itself and tints the `Cap` (not the housing) green.
    `Door.Button`'s `Base` also got its missing 0.9 border toward checkpoint `1005`'s plate. Pads surrounded by floor keep the plain look. Checked in a playtest:
    `Button_5` pressed from the cap and from the black edge (cap green, back to azure after `Time`), `ColourShaft.Toggle0` toggled from its cap; no errors.
- **Coins:** 8 per stage (5 easy 20, 2 risky 50, 1 talent 100), ids `Stage11_1..8`, `Stage12_1..8`; the talent coin needs a talent beyond the requirement (Dash).
- **Measured in the S8.1 bot tests (2026-10-24):** standing rises match §1.0 (Double Jump 14.5, with Jump Height 3 18.0; Triple Jump 22.0, with Jump Height 3 26.9),
  but a **17-stud ledge was landed by a Double Jump with Run Speed 5 + Jump Height 3** (gap 6): a ledge is cleared with a root rise of about its own height, not 2.5
  more as the Stage 6 note suggested. So **Triple ledges are 20** (gap 6): a baseline Triple Jump lands them with three jump timings (apex, every 0.3 s, from 1.2 or
  2.8 studs before the edge; jumping 0.6 before the edge with late air jumps failed), a maxed Double Jump fails with every timing. Flat Triple gaps of 17 (with an 8
  stud side shift) are crossed by a baseline Triple Jump, not by a baseline Double Jump (soft, a fast Double Jump may make them).
- **Stage 11 Triple Peaks as built** (x = -87 + u, z = -645 + l, surface h above y 78.5; checkpoint plates are 12 along the course, 16 wide): `901` (u 0);
  (1) Double Jump warm-up pillars `A1`-`A3` (8 x 8, h 0 / 11 / 22, gaps 6); (2) `Shelf1` (20 x 20, h 22) with tower `T1` (h 42) on its far end: the first Triple
  ledge, a miss lands on the shelf; `902` (u 84, h 42); (3) peaks: `P1` (h 62, Triple ledge), `P2` (6 x 6, h 62, flat gap 17), `P3` (6 x 6, h 82, Triple ledge from a
  6-stud runway), `P4` (h 75), `903` (u 176, h 75); (4) drop 17 onto the kit lift `Lift1` (8 x 8, h 58 -> 92, period 10, pause 1.5), Triple ledge from its top to
  `P5` (h 112), `904` (u 226, h 112); (5) the **crusher ridge** `Ridge` (66 x 6, h 112, flush with `904` / `905`) under `Crusher1..4` (6 x 4 x 8 at u 246 / 258 / 270 /
  282, 9 studs over the ridge, kit `Piston` Axis down, Stroke 9, Period 3, Duty 0.25, Out 0.2, Back 0.6, Telegraph 0.6, `Kill`, run-seeded, Phase 0.75 / 0.5 /
  0.25 / 0: each slams 0.75 s after the one before, so a walker who leaves as crusher 1 lifts follows the wave); the 6-stud gaps between them are safe; `905`
  (u 304, h 112); (6) `Summit` (h 132, Triple ledge), descent `D1`-`D4` (h 115 / 98 / 81 / 64, gaps 12-14), finish island (16 x 16, h 47), portal at u 432. About
  440 studs. Coins: easy on `Shelf1`'s corner, `P4`, the ridge between crushers 2 and 3, `D2`, the finish island; risky on a 4 x 4 side pillar 9 studs beside `P2`
  and under crusher 4; talent on a 3 x 3 pillar 24.5 studs beside the summit (Triple Jump + Run Speed 4-5, or Dash).
- **Stage 12 Ice Rink as built** (z = -585 + l): `1001` (u 0); (1) `Rink1` (44 x 24 ice, low side rails) flush with the plate, rest plate `R1`, ice turns `I1`
  (36 x 8) -> `I2` (sideways, to l 24) -> `I3`, `1002` (u 142, l 20); (2) four 10 x 10 ice plates `J1`-`J4` with gaps 5-7 and side shifts of 8 (hop on at once:
  a stop slides you off), `1003` (u 226); (3) `WindBeam` (66 x 8 ice, flush both ends) in a steady crosswind `Wind1` (Push 6 toward +z; 10 blew even a correcting
  bot off), the rest plate `Plate_1004` (u 304; **no checkpoint since 2026-10-26**: the door segment was too forgiving, now a fall on the track or at the door replays the wind beam from `1003`); (4) **pressure door**: `Button` (Group `IceDoor`, **8.5 s** since 2026-10-26 (9.5 first, then cut by 1 s on request), was 6; moved to the start of `WindBeam` right behind `1003` (5 x 1.1 x 8.4 at u 150, 0.1 above the beam and 0.2 wider each side so no face is coplanar with the beam), so the timer covers the whole beam, the rest plate and the track: about 142 studs. The old spot is the plain `StepTop_1004`. Measured with a bot that steers against the crosswind, from the button's edge to the door: 7.0 s at the default WalkSpeed 20.8 (Run Speed 5), 9.2 s at WalkSpeed 16 (no talent), so at 8.5 s: 1.5 s of margin at the default speed, and a no-talent run (WalkSpeed 16) misses the door by 0.7 s, so Run Speed is effectively needed), ice track `Track1..3` with two 5-stud gaps, `IceDoor`
  (a 1-stud wooden door, 12 wide, 20 high, hinged on its north edge; swings 90° toward the approaching player: `OpenTurn -90`, `OpenHinge (0, 0, -5.5)`, 0.7 s;
  fixed 2026-10-26, see §2.3.1) between walls (down to y -4) and a lintel, `1005` (u 390) behind it; (5) Triple ledges onto ice `K1`-`K3` (10 x 10 ice, h 20 / 40 / 60,
  gaps 6-7), finish island (h 49, drop 11), portal at u 466. About 470 studs. Coins: easy on the rink corner, `I2`'s corner, `J3`, the beam's upwind edge, the
  finish island; risky on the beam's downwind edge and on a 6 x 6 ice plate 10 beside `J2`; talent on a 3 x 3 pillar 21.5 beside `K3`.
- **Fall reset (user, 2026-10-24: with Quick Respawn 2 the descent reset the player to `905` around `D4`):** the descent goes 65 studs below `905`, past the
  default 30-stud `FallResetDepth`; the Stage 11 folder now carries `FallResetDepth = 75` (Studio-only attribute; the reset stays clamped above the sea for the low
  checkpoints). Checked with a bot with Quick Respawn 2: depth 30 resets on the jump to `D4`, depth 75 lands `D4` and the finish island.
- **Door countdown made visible (user, 2026-10-24: on the Ice Rink and the Clocktower's two doors the countdown went unnoticed; you always run past the button):**
  the doorway countdown is now big (0.6 x the door's width, 5-10 studs) at the door's middle instead of over its top, shows the seconds rounded up (6 ... 1) with
  a bar under it that shrinks green -> orange (half time) -> red (last 2 s), and is drawn through walls (AlwaysOnTop) so it shows round the Clocktower's corners;
  the last 3 seconds tick (Studio-only `ReplicatedStorage.DoorTickSound` = the metronome tick, faster each second; silent without it). Checked on the Ice Rink door:
  6 -> 1 with the bar 1.00 -> 0.16, then hidden, ticks at 3 / 2 / 1. *Not checked:* the look (the capture timed out), the Clocktower doors in play.
- **Kit ice tuning** (defaults Accel 14, Brake 5): from rest it reaches 15.5 studs/s in 1 s and coasts 21 studs after letting go.
- **Friction + ice-air (user, 2026-10-29: "after restyling they are not so slippy", and a jump or dash resets the inertia):**
  - *Friction:* the Humanoid's own walking grips by floor friction. On the restyle's `Plastic` (friction 0.3) it overpowered the drive: a slide
    from 20.8 studs/s stopped in 1.1 studs, a reversal took 0.1 s. Now the kit gives every `KitIce` part `CustomPhysicalProperties` with friction 0 /
    weight 100 locally (density and elasticity kept), whatever its material: coast 21.1 studs again, a reversal on the ice 0.9 s.
  - *Ice-air:* the Humanoid's air control turned a jump into a free brake or U-turn (15.7 -> -20.8 studs/s in 0.3 s; landing back on the ice, the drive
    started from that). Now, from leaving a `KitIce` part (a jump or an edge) until the next landing, the kit keeps driving the root: toward the
    input at the left part's `AirAccel` (default 14, as on the ice), never braking without input. Landing on any other floor gives the Humanoid back
    (after 0.1 s on the ground: it reports a floor for a frame or two after take-off); a teleport (> 10 studs in a frame) or death ends it too. You still
    steer mid-jump, but gradually: a plain jump changes the speed by about 7 studs/s, a Triple Jump's air time can turn it round. Measured: 17
    studs/s² (the Humanoid leaks a little past the drive), no input keeps the slide (14.9 for 0.6 s of air).
  - *Dash:* in ice-air the burst is unchanged, but afterwards the slide from before it is restored (character attribute `IceAir`, read by
    `TalentDash`) instead of run speed in the dash direction; measured a backward dash: -50 during the burst, +8.4 after, so no brake.
  - *Course checks (playtest 2026-10-29, client bots at Walk Speed 16 / Jump Power 50, Triple Jump; calibration with `AirAccel` 200 ≈ the old air
    control):* hop chain `J1`-`J4` 5 / 5 strategies (also with 1 air jump 4 / 4, without 3 / 4); Triple ledges `1005`-`K1`-`K2`-`K3`-`Finish`, each leg from
    rest 2 / 4 / 7 studs before the edge: 12 / 12; Stage 15 `IceRidge` -> `T1` from 2-10 studs before the edge 8 / 10 (2 falls with a long run-up: the bot
    reaches `T1`'s face before its third jump's apex), 10 / 10 at `AirAccel` 200. `WindBeam` and the door sprint were not re-run (floor slide only: the
    friction fix restores the validated tuning). Not checked by a human player yet.
- **Checks (Studio playtest 2026-10-24, bots at baseline Walk Speed 16 / Jump Power 50 unless noted; developer profile snapshot `profile_<id>_s81` restored, the
  Stage 11 / 12 boards removed):** every Triple ledge of both stages (also from the lift's top and from ice), the flat 17 gap, the ice hop chain (one timing made all
  four hops, another slid off after the second), the wind beam (correcting runner across, straight runner blown off), the door sprint (button to doorway 4.4 s of 6 s),
  the crusher ridge (walker leaving as crusher 1 lifts crosses, later starts are killed by `Crusher3` / `4`; Run Speed 5 crosses from 0.2-0.5 s; standing under a
  crusher kills in 0.7 s, standing in a gap is safe); a locked stage's door stops a player; an unlocked run: gate starts the timer, `901`-`905` / `1001`-`1005` fire
  in order, the finish portal ends the run with a result (Gold for the teleported test run) and sends the player to the courtyard. No script errors or warnings.
- *Fixed while testing:* 2-4 stud seams between checkpoint plates and the next ice / ridge part (made flush), the button-to-track gap, the crusher wave ran toward
  the player (a higher Phase is earlier in `KitMath.Cycle`), the first crosswind (10).
- *Not checked:* the look (screen captures came back white), a human run and the real `T_base` (110 / 120 provisional), the coins being collected, the talent
  coins' reach with Dash, the door countdown on screen.
- **User's check (2026-10-26):** both stages played and accepted after the tuning above (door swing, button at the start of `WindBeam`, 8.5 s, no `1004`).
- **Crusher press (2026-10-28):** a baseline Triple Jump taken 9-13 studs before `Crusher1` cleared its top and landed in the gap behind it (a first-run
  shortcut, see §7.13 → "Same open sky"), so the ridge now runs through a press like Stage 15's: Studio-only folder `Stage11.Press` with `PressWallN` /
  `PressWallS` (2-stud glass walls, transparency 0.5, x 145-211 = the ridge's length, from the sea y 2 to y 203.5 = the crushers' raised top, flush beside
  the ridge at z -650..-648 / -642..-640) and `PressRoof` (DiamondPlate until 2026-10-28, now charcoal studs, x 145-211, z -650..-640, y 203.5-223: 32.5 above the ridge, out of a maxed Triple
  Jump's reach). `Crusher1..4` are 5.8 across (were 8, overhanging the 6-wide ridge), 0.1 from each wall; their timing attributes are unchanged. The roof
  ends at `905`'s west edge, so the Triple ledge to `Summit` is open. Checks: static coplanar audit of `Stage11` clean apart from the finish-arch stones /
  gate and an older `T1` / `Shelf1` pair (+X and -Y faces shared; not touched), the crushers against walls and roof clean at 0 / 2.25 / 4.5 / 6.75 / 9 of
  the stroke; bots from `904` with the stored maxed profile (WalkSpeed 20.8, JumpPower 55.7, Triple Jump) and at baseline (16 / 50), take-offs at
  u 224-237 (x 137-150) with air jumps at the apex or every 0.3 s: highest root y 217.6 against the roof's west face (roof top 223), none above
  y 202 inside the press, every one either walked through under the wave or died at a crusher; Triple Jumps outside the walls (z -652 / -638) peak at
  220.6 and fall to the sea; baseline walkers leaving the middle of `904` at 8 points of the 3 s cycle: 4 cross (about 5.4 s to `905`), 4 die at
  `Crusher1`, as before; `905` -> `Summit` lands from 3 take-offs x 2 timings at baseline and with the maxed profile. *Not checked:* the look and the
  camera inside the press (no capture), a human run. Developer profile, `MostStars` and the Stage 11 board restored from `profile_<id>_s11press`.
  - *Piston rods (user, 2026-10-28: "like Stage 15"):* `Movers.Rod1..4`, Metal cylinders (square studded columns since 2026-10-28, see "Rod and roof look") standing on each crusher (unanchored, Massless, CanTouch /
    CanQuery off, WeldConstraint to the crusher, as Stage 15's `Rod1..3`). Length 13.5 as on Stage 15 (y 203.4-216.9 at rest, still 4.4 inside the
    roof at the full 9-stud stroke), but **5.6 across instead of 6.2**: the slot between the glass walls is only 6 here, so a 6.2 rod would cut 0.1 into
    each wall when it comes down; 5.6 leaves 0.2. Checked in a playtest: every rod stays on its crusher (offset 0.000 over 3.2 s, Crusher1 y 192.5-201.5)
    and the 8 baseline walkers from `904` give the same result as before (4 cross in 5.4 s, 4 die at `Crusher1`). Profile etc. restored from
    `profile_<id>_s11rods`. *Not checked:* the look.
  - *Crusher look (user pick "B", 2026-10-28):* the lava-red smooth blocks looked like lava, so `Crusher1..4` are now charcoal (`#2D2D34`) Plastic with the
    `Studs` variant, glowing Neon cracks (`Crack_1..24`, 0.1 thick, a mirrored pattern on every second head) on the four sides, a Neon `BottomGlow` plate and a
    `ParticleEmitter` of black smoke cloned from Stage 2's `Lava block` (Rate 10). The cracks / plate are children of the crusher, unanchored, Massless,
    CanCollide / CanTouch / CanQuery off, each with a `WeldConstraint` to it (like the rods), so they travel with the ram. Size, attributes and `Kill` are unchanged;
    ObstacleKit's telegraph tints the body to `WarnColor` (255, 170, 60) and back, the cracks stay lit. Studio-only. Checked in Edit mode by moving a crusher down 8: cracks, `BottomGlow` and rods travel with it (offsets unchanged); *not checked* in a playtest.
  - *Rod and roof look (user pick "option 1", 2026-10-28, Stage 11 and Stage 15):* `Rod1..n` are now square columns (Block, not Cylinder) of the same
    footprint as the old cylinders (5.6 on Stage 11, 6.2 on Stage 15; same 13.5 length, offset, CanCollide, Massless, unanchored, re-welded to their
    crusher, so blocking is unchanged apart from the corners): stone-grey (`#A3A2A5`) Plastic with `Studs`, a yellow `Inlets` `RodBase` band (1 high) on
    the head and two charcoal `Studs` `RodCollar_1/2` (0.9 high, 3 and 6 above the head top, 0.2 wider than the rod: 5.8 fits the 6-stud slot, 0.1 each side);
    the decorations are children of the rod, Massless, CanCollide / CanTouch / CanQuery off, welded to the crusher. `PressRoof` is charcoal Plastic with
    `Studs` (was DiamondPlate) with four anchored yellow `Inlets` `RoofBand_1..4` (1.2 high, 0.2 thick, 0.1 proud) along both long faces, 0.9 from the bottom
    and the top. Studio-only; checked in Edit mode on Stage 15 with the heads lowered 8 (rods, bands and cracks follow); *not checked* in a playtest.
  - *Hazard looks, two languages (user decision, 2026-10-28; Studio-only):* **solid hazards** (crushers, later spikes / blades) use "B": charcoal `Studs`
    body, glowing Neon cracks, black smoke. **Lava-like floors** use "A", lava bricks: the kill part keeps its size, script and `Touched` hook, is restyled
    to dark red Plastic with `Studs` (the cracked-lava `MoltenLavaGlow2` variant and the Neon red are gone) and carries `LavaTile_n` children: anchored
    2 x 4 plates (0.2 high, 0.08 gaps so no face plane is shared with the base), palette dark red / red / orange (`Studs`) with about 1 in 5 tiles Neon orange,
    `CanCollide` / `CanTouch` / `CanQuery` off, `CastShadow` off. Applied to Stage 2 `Lava block` (66 tiles, keeps its own smoke emitter) and
    `LavaFloorStage.Part_3` (72), and to Stage 4's `11."level 11"` kill strips `Part_1..4, 6, 7` (52 in all). The smoke is a `LavaSmoke` emitter cloned from the
    Lava block's (rate area / 30, 3-12 per s, size 1-3.6) on every part of 40 or more square studs except the Lava block. Mobile: the place had 6 606 parts
    (StreamingEnabled off) when this was added, +190 tiles is about 3 %; the cost to watch is the smoke overdraw, hence the low rates and the bigger bricks.
    Not measured on a phone. Other red hazards (Stage 2 `SpinnerStage_1` bars, laser strips) are not restyled yet.
  - *Spike look "GlowRidge" (user pick 2026-10-29 from three previews, see §7.12 "Colour-shaft spikes"):* every spike model (a `Hit` plus two
    `WedgePart`s; all 27 are in Stage 14: 24 in the vault, 3 in the colour shaft) has charcoal (`#2C2C34`) Plastic + `Studs` wedges and two
    Neon `#FF5913` `Tip` wedges along the ridge (the top 0.75 or 40 % of the wedge, same slope, 0.03 proud of it, 0.02 longer at each end;
    CanCollide / CanTouch / CanQuery / CastShadow off; on `EBottom_18` they carry its `ArenaGate` tag and fade with the hatch). Built in each
    wedge's own frame, so hanging (`Ceiling_21`, `Hang_7/8`) and wall spikes (`EBarSide_22`) get the tip at their point too (checked: the two
    tips of every model meet at the ridge). `Hit` boxes unchanged. Stage 10's gargoyles (also a `Hit` plus two wedges) are not spikes and keep
    their look. New spikes: clone a restyled one (e.g. `Vault.Spikes.Right2_13`).
  - *Yellow movers (user pick, 2026-10-28: rimmed plates, spur gear; Studio-only):* all 23 yellow `KitMover` parts (plus `SpinnerStage_2`, below) (Stage 1 `Mover1`; Stage 6 `Lift1`, `Slide1/2`,
    `Stone1-5`; Stage 8 `Mill1A/B`, `Mill2A/B`, `Plank1/2`, `Turn1`, `Turn4`; Stage 10 `Plank_1/2`, `Gear_1-3`; Stage 11 `Lift1`) are `Plastic` + `Studs`, LEGO yellow
    (`#FFD54A`). Plates (20 parts) keep their size and collision and carry four amber `Studs` rim bars `RimN/S/W/E` (`(0.89, 0.58, 0.08)`, 0.4 wide, 0.2 high, 0.03 in from the edge so
    no face plane is shared; they were charcoal until 2026-10-29, when the user dropped the black lining; previews with no lining and a same-yellow `Inlets`
    lining were rejected) and, on the discs `Turn1/4`, a 3 x 3 amber `Hub`; all are children, Massless, CanCollide / CanTouch / CanQuery / CastShadow off,
    `WeldConstraint` to the mover (checked in Edit mode on `Stone2`, `Turn1`, `Gear_2`: offsets hold when the mover is moved or turned). `Gear_1-3` are now one
    `UnionOperation` each (12 teeth, body 8 across, tips 10 across, 1 high, `PreciseConvexDecomposition`) built from a hub block so the union keeps an upright frame;
    name, `KitMover` tag, attributes (`Speed`, `Tick`, `TickMove`, `Phase`, `RunSeeded`), position and the -90 degree yaw are copied from the old block, plus the 3 x 3 amber `Hub`.
    **Why the gear is the mover itself:** ObstacleKit carries a rider only when the exact part under their feet is a `KitMover` (`movers[standing]`), so a round
    gear cannot be decoration on a square block. Its footprint is smaller than the old 10 x 10 square at the corners; the tips still reach 5 studs along the row,
    so the gaps between the gears (13 apart) are unchanged. *Not checked:* in a playtest (rider carry on the gear, the Stage 10 gear row, Stage 8 / 6 timing).
    Added the same day: Stage 2 `SpinnerStage_2` (`Part_1`, `Part_3`, the two spinning 16.3 x 4.3 planks, were green `Studs`) now has the yellow plate + rim (no hub: the
    planks keep their small axle pins `Part_2` / `Part_6`, now amber `Studs`); 4 rim children each, offsets checked by turning `Part_1` in Edit mode. The red
    Neon sweeper bars of `SpinnerStage_1` are unchanged.
  - *Tilt plates (user pick "T1", 2026-10-29; Studio-only):* the light blue plain plates read like the Ice Rink, so all 23 `KitTilt` parts (Stage 7 `Plates`, Stage 10
    `Movers.Tilt_1-3`, `KitLab.Tilt_1`, `StageKit.Obstacles.Plate_Tilt`) are `Plastic` + `Studs`, green `(58, 165, 92)`, with four dark green `Studs` rim bars `RimN/S/W/E`
    (`(30, 110, 60)`, 0.4 wide, 0.2 high, 0.03 in from the edge, like the yellow movers) and a charcoal hinge pin on the tilt axis: `Axle` (Cylinder, 0.8 thick, plate
    width + 1.6, through the plate's centre along its local X, hidden inside it but for 0.8 at each side) and `AxleCapW/E` (Cylinder knobs 1.3 across, 0.4 thick, at
    the pin's ends). The pin sits on the axis so it only turns about itself while the plate tips (the preview had it under the plate, where it would swing). All
    children are unanchored, Massless, CanCollide / CanTouch / CanQuery / CastShadow off, welded to the plate, so they follow ObstacleKit's CFrame tilt (checked in a
    playtest: `Chain1` at 28.9 degrees, offsets unchanged). No pin or knob overlaps another visible or collidable part. Previews rejected: T2 orange with a charcoal
    pivot stripe (orange is close to the movers' amber rims and the crusher warning), T3 two-tone halves.
  - *Disappearing plates (`KitPlate`, user decision 2026-10-29):* the teal plain plates now have the standard look of Stage 4's `Part_10` (`Plastic` + `Studs`,
    `(0.75, 0.67, 0.55)`, opaque, no decoration) on all 19 (Stage 3, `KitLab.Plate_1-4`, `StageKit.Obstacles.Plate_Disappearing`): the flicker and the vanishing
    are the cue. **Why:** a 30 % transparent plate barely registered at a glance (preview N2), the kit already uses translucency for "not solid" (ghost colour plates
    0.85, ghost steps 0.75), and the sea tinted a translucent plate blue. Rejected previews: N1 / N3 cream with grey dashed rims, V1-V3 purple / pink with rims.
    The kit now fades and removes the parts inside a disappearing or crumbling plate with it (`decorOf` / `setPlateLook`: a decoration at base transparency d goes
    the same share of the way to 1 as the plate; the warning flicker goes 60 % of the way from the plate's own transparency to 1, so 0.6 for an opaque plate as before).
  - *Crumbling plates (`KitCrumble`, user pick "C1", 2026-10-29; the plates the user meant first):* were plain tan `SmoothPlastic` `(0.78, 0.67, 0.47)`. All 25
    (Stage 7 `Plates.Crumble1-4` / `CrumbleB1-3`, Stage 8 `Movers.Crumble1-3`, Stage 10 `Movers.Crumble5_1-4` / `Crumble11_1-5`, `KitLab.Crumble_1-5`,
    `StageKit.Obstacles.Plate_Crumble`) are sandstone `Plastic` + `Studs` `(222, 170, 100)` with three dark brown cracks `Crack_1..10` (`(70, 45, 30)`, segments 0.14 wide,
    0.06 high on the top, one crack across the plate with two branches; the pattern turns a quarter per plate in name order and mirrors every other pair, scaled to the
    plate). The cracks are welded, unanchored, Massless, CanCollide / CanTouch / CanQuery / CastShadow off. Checked in a playtest on `Crumble1`: shake 0.17, the cracks
    keep their offset, plate and cracks vanish together (no collision) and come back together. Rejected previews: C2 3 x 3 loose sandstone tiles on a dark bed, C3
    terracotta slabs split 2 x 2 by grooves.
  - *Stage 10 movers (user picks, 2026-10-29; Studio-only; decoration welded, unanchored, Massless, CanCollide / CanTouch / CanQuery / CastShadow off):*
    - **Flips** `Movers.Flip_1-3`, `FlipB_1-3` (pick "F2"): were teal `SmoothPlastic`. LEGO yellow `Plastic` + `Studs` `#FFD54A` like the yellow movers, amber `Studs` rims
      on **both** faces (`RimN/S/W/E` on top, `RimBN/BS/BW/BE` underneath: a flip shows its underside half the time) and the tilt plates' charcoal hinge pin on the flip
      axis (`Axle`, `AxleCapW/E`, local X = `Hinge` "X"). *Known weakness:* the kit's warning tint (255, 170, 60) is close to the yellow, so the 0.6 s telegraph reads
      weaker than on the purple preview "F1" (rejected); a per-part `WarnColor` would fix it. Stage 8's 9 flips are still teal.
    - **Pushing pistons** `Piston_1-3`, `PistonB_1-2`: body and `Rod` stone grey `Studs` `#A3A2A5` (were DiamondPlate / Metal), `PushPlate` orange `Inlets`, a yellow
      `Inlets` `Band` (1 thick, 0.1 proud) 0.6 behind the body's centre across the push axis. At rest only the push plate shows (the body sits in the tower wall).
    - **Pendulums** `Pendulum_1-3` (Swing, no kill): brass `Studs` `(204, 160, 61)` (were gold Metal) with a charcoal `Hub` cylinder on the hinge axis at the `Pivot`
      (it overlaps the `Course.PendulumBar_n` it hangs from). A bob at the bottom was dropped: it would look bigger than the part that pushes.
    - **Clock hand** `Hand_6` (Spin + Kill): charcoal `Studs` (was red `SmoothPlastic`) with glowing red Neon `EdgeL/R` strips along both long sides, the "solid hazard" language.
    - Checked in a playtest: the flip (turned, tinted and back), piston (10 out), pendulum and hand moved with every decoration at zero offset drift; no errors.
      Not restyled: `Conveyor_9` (with Stage 1's two conveyors later), the tower's `SecondHand_1-4` (decoration).

### 7.12 S8.2 Dash Bridge + Laser Lab (design check 2026-10-26; decisions with the user: Long Dash as Dash level 2, a `Roll` kit kind, soft-talent coins, arena + Dash room)
- **Slots** (Studio survey 2026-10-26): the west openings of the World 3 courtyard. Stage 13 = west near gate (`SoonGate13`, x -219..-190, z -659..-630;
  course runs **west**, band z -678..-615), stage 14 = west far gate (`SoonGate14`, z -599..-570; west, band z -609..-546). The sea west of the courtyard is
  empty from x -222 to x -1000 (checked: no parts in x -1000..-222, z -720..-520), the hub starts at x -1038, so a course may run to about x -950 (the S7 note
  said -800 to keep a margin to the hub; ≈ 500 studs either way). `SoonGate15` stays closed until S8.3. Gate / board / `Arrival` / checkpoints from `StageKit`
  as in §7.11. Keys and folders `Stage13` / `Stage14` under `World3`; checkpoint blocks `1101`- and `1201`-.
- **StageConfig (provisional, M6b measures):** both `requires = { { id = "DoubleJump", level = 2 }, { id = "Dash", level = 2 } }` (Triple Jump, Long Dash). Stage 13 `tBase` 90 (was 120; Gold < 72 s), factor
  3.75, Bronze on Stage 12 or 5 000; Stage 14 `tBase` 135, factor 4.0, Bronze on Stage 13 or 5 500 (the World 2 / World 3 steps continued). `tools/economy.py check`
  after the entries.
- **Dash gates = Long Dash** (decided 2026-10-26 after the bot tests in §1.0): open-air gaps had a 2-stud window (baseline TJ + Dash 31.7 vs a
  maxed Triple Jump 29.8) and low ceilings leaked (Triple Jump hover). The user chose a longer dash as a **second Dash level, Long Dash**
  (0.32 s at the same 50 studs/s = 16 studs; a faster burst could pass thin kill beams between two touch tests), so stages 1-12 keep their
  tuning. Prices: Dash 5 000 + Long Dash 3 000 (the 8 000 of the old single level, split: the GDD §6 required set at stage 17 is already at
  64 % of the 65 % cap). Hard Dash gaps are **34 studs flat** (§1.0). Telemetry: Dash 0-2 made the loadouts 324, so Jump Height is bucketed
  too (TELEMETRY.md). *Economy model:* `check` passes the required-set shares (44 % / 64 %) but the Casual 24-hour rule reaches 1.04x on
  day 16 with any split of the two levels (1.00x allowed; the model buys the two levels at different times among the field squares);
  prices not pinned yet, decision with the user.
- **Stage 13 Dash Bridge** (signature: Dash gaps; also pendulums and rolling balls), about 450 studs west, checkpoints every 20-30 s:
  (1) *teach*: a short-Dash gap (20-24) over a safe catch floor 8 below (a miss walks back up a ramp), then a 34 Long Dash gap over the same floor;
  (2) *test*: three 34 gaps over the sea, one of them with a side ledge route of Triple ledges (slower, the Gold route skips it); (3) *pendulums*: a 6-wide bridge under four swinging axes (`KitMover Swing` + `Kill`,
  swinging across the bridge, run-seeded, a wave like the crusher ridge); (4) *rolling balls*: a 10-wide ramp climbing 20 studs, balls roll down it toward the
  player in lanes; jump them or step into the side pockets; (5) *finale*: a Dash gap with a pendulum swinging through it (dash through its window), the finish
  island and the portal. Coins: 5 easy, 2 risky (a ball pocket, beside a pendulum), 1 talent (Run Speed 5 + Jump Height 3, below).
- **Rolling balls need new kit code:** `KitMover Kind = "Roll"`: the ball travels along `Axis` for `Distance` studs at a constant speed within `Period` (Phase,
  RunSeeded as the other movers), turns about the axis across its path so it looks rolling, sinks / fades in `Fade` s at both ends (no pop-in at the top),
  `Kill` by default. No physics (§2.1 T). The alternative without code, a `Slide` ball rolling back and forth, reads as a ping-pong, not a ball coming at you.
- **Stage 14 Laser Lab** (signature: 2D side view; §5.2): the `KeyArena` prototype becomes its **first room**, followed by a **second room** for the Dash:
  sweeping lasers (a `KitMover Spin` + `Kill` bar turning in the lane's plane, part tilted so its Y axis points across the lane), laser grids (`KitBeam` rows,
  run-seeded) and colour switches (`KitSwitch` / `KitColorPlate`), with two 34-stud Long Dash gaps and an exit to the finish portal. The arena alone is about 172 studs
  across and too short for a 120-150 s stage; the two rooms together aim at `T_base` ≈ 135.
  - *Camera:* `Side` with `Yaw 180` (looking south, so screen right = west = along the course), distance 55 as the arena uses. The camera then sits about 55
    studs north of the lab's lane, inside stage 13's band: **stage 13 keeps every part north of z -645 along the lab's length** (the camera looks away from them).
    The arena is turned 180° about Y (a rotation, not a mirror: start bottom left, exit bottom right stay as drawn).
  - *Integration:* the arena's own checkpoints (`ArenaCheckpoint`, start `301`) become stage checkpoints `1201`-; keys and opened gates reset when a new run
    starts (`CheckpointsReset` / timer start) instead of at the exit; the exit zone leads on to room 2 instead of teleporting back; spikes become `KitKill` (client
    kill like every other stage, telemetry by part); `ArenaServer` keeps keys / locks / gates. The prototype at x 800 is removed after the move.
  - *Dash shortcut in room 1:* the low corridor under platform A (§5.2, not checked yet) is measured with the real Dash; if it works it is the Gold route.
- **Talent coins** (decided: maxed soft talents now): §7.3 wants a talent beyond the requirement, but stages 13 / 14 already require every World 3 talent and World 4's are not built. Either
  a "maxed soft talents" coin now (Run Speed 5 + Jump Height 3, e.g. a 33-stud open gap) or the coin waits for S9 (Wall Jump) and the stages ship with 7 coins.
- **Split** (default taken): S8.2a Dash Bridge (with `Roll`) and S8.2b Laser Lab, each with its Studio check, the user's check and a commit, Dash Bridge first (its gates
  are measured in the jump lab and the Laser Lab's room 2 reuses them).
- **Stage 13 Dash Bridge as built (S8.2a, 2026-10-26)** (x = -213 - u, course along z -657, surface h above y 78.5; everything north of z -644 for the Laser Lab
  camera): `1101` (u 0, z -645, Stage 11's gate / board / `Arrival` mirrored across the courtyard about (-150, -645)); (1) runway `R1` (u 6-26), a 22 gap (any Dash)
  to `L1` (u 48-64), a 34 gap to `L2` (u 98-112), both over brown catch floors (`Catch1` / `Catch2`) with a truss back up to the take-off; the floors were 8 lower and ran up to the landing pillar's face, so a short jump climbed onto it (2026-10-28, the user: the section needed no Dash): now **32 lower** (top h -32, trusses 32 tall), a maxed Triple Jump from the floor rises 26.7 (bot: Triple Jump, Jump Height 3, Run Speed 5), a miss climbs back in about 4.5 s, and the folder's `FallResetDepth = 40` keeps Quick Respawn from resetting the fall before the floor (the root lands 29.5 below the plate); `1102` (u 118); (2) 34 gaps over the sea to `P1` (h -2),
  `P2` (h -4), `1103` (u 256, h -6); (3) a 6-wide `Bridge` (u 262-330) under `Axe1..4` (1.5 x 32 x 4 at u 276 / 290 / 304 / 318, hung from an overhead beam whose underside is at h 30 (it was h 12 and a Triple Jump, rising 21.8, 27.0 with Jump Height 3,
  landed on top of it and walked past the axes; now the beam top is 38 above the bridge, the posts 18 taller, the axes longer so the tips stay 4 above the deck),
  `Swing` Hinge X across the bridge, Angle 24 (was 55 on 14-stud axes: a longer arm needs a smaller angle to keep the closed share of the period; 8 bot walkers at 16 studs/s: 3 crossed), Period 3, run-seeded, Phase 0 / 0.708 / 0.417 / 0.125 = a wave a 16 studs/s walker follows); `1104` (u 336);
  (4) `Ramp` (u 342-422, h -6 -> 14, 10 wide) with `Ball1..4` (diameter 5, `Roll` Distance 80, Period 6, Fade 0.4, run-seeded; lanes z -659.5 / -654.5,
  one ball every 1.5 s alternating lanes, a lane every 3 s; 3 balls per lane were too dense: even a jumping bot died) and side `Pocket1..3`; `1105` (u 428, h 14);
  (5) a 34 gap (drop 4) through `AxeFinale` (2 x 34 x 4 from a gantry at h 50, Angle 50, Period 4) to `F1` (u 468-482, h 10), a 22 gap (drop 6) to `Finish`
  (u 504-520, h 4), portal at u 514. About 520 studs. Coins: easy on `R1`'s corner, `L2`, `P1`, the bridge between axes 2 and 3, the finish island; risky in
  `Pocket2` and under `Axe4`; talent on `TalentPillar` (3 x 3, 41 studs north of `F1`).
- **Checks (Studio playtest 2026-10-26, bot with the stored profile at Triple Jump + Long Dash, snapshot `profile_<id>_s82` restored, the Stage 13 board removed):**
  every gap crossed with Triple Jump + Long Dash at the apex (landings at u 63.6 / 100 / 162 / 208 / 254); walkers over the axe bridge: 3 of 6 start times
  crossed (`Axe1` / `Axe3` killed the others), standing under `Axe2` kills; ramp: a bot that jumps the balls of its lane got up every time (5.7 s), a plain
  walker died within 2 s; finale: 4 of 8 start times passed the pendulum; talent pillar: baseline Triple Jump + Long Dash falls short, Run Speed 3 lands it,
  Run Speed 5 + Jump Height 3 overshoots the 3 x 3 top unless steered; coin pickups (`Stage13_4`, `_7`, `_8`); a full run: gate starts the timer, `1101`-`1105`
  in order, the finish portal ends it with a result (Gold). No script errors.
- *Not checked:* the look, a human run. The bot's clean segments took about 30 s: the provisional `tBase` 120 is very likely too generous (Gold came easily);
  set it after the user's run, as for Stage 10. *For S8.2b:* Stage 14's lane (z -609..-546) lies within a Long Dash of Stage 13's south edge (35 studs): put a
  `World3West` lane divider between them (superseded by the S8.2b draft below: the lane sits at z -580, 61 studs off).
- **Stage 14 Laser Lab, S8.2b draft (2026-10-26, Studio survey the same day; awaits the user's design check).** Coordinates as Stage 13: x = -213 - u,
  surface h above the plaza top (y 78). Everything below lies in the band z -609..-546, empty sea west of the courtyard (checked: only `DebugBaseplate`).
  - *Lane and camera:* lane centre **z -580**, 6 deep (z -583..-577), invisible walls on both sides up to the room ceilings / h 45 outdoors (a Triple Jump
    + Long Dash rises 27 and reaches 46: nothing leaves the lane). `Side` zones with `Yaw 180`, Pitch 3: the camera sits at z -635 (room 1, Distance 55) /
    z -625 (outdoors and room 2, Distance 45, rooms 40 high), behind it are Stage 13's southmost parts (`GantryPost2` z -642.5..-639.5, `R1` / `1101`
    z ≤ -639): **Stage 13 keeps every part north of z -638 along the lab** (at lane z -585, the gate's centre, the camera would stand inside `GantryPost2`).
    Stage 13's track is 61 studs from the lab's north wall, beyond a maxed Long Dash (46.5): no `World3West` divider. Whether the camera blends between two
    `Side` zones with different distances: check in the build (else one distance for the whole lab).
  - *Entry (u 0-36):* Stage 14's gate / board / `Arrival` from `StageKit` on the west far opening (`SoonGate14`, centre z -585, removed); `1201` at u 0
    (z -585) like `1101`; a 12-wide entry hall narrows to the lane (z -580) by u 20, the first camera zone starts at u 10 (past `GateExit`). One teaching
    beam at u 28 (`KitBeam`, Period 2, Duty 0.5, floor to the hall ceiling): the first sight of "lit = death" with a safe floor before it.
  - *Room 1, Key Vault (u 36-244):* the `KeyArena` prototype, every part mapped (x, y, z) -> (543 - x, y - 42, 620 - z) (a 180° turn about Y, floor y 120
    -> 78): start bottom right of the lab's map = screen left, exit opening at u ≈ 228-234, the shell's west wall at u 244. Arena checkpoint `301` is
    dropped (`1201` is 40 studs before it), `302` / `303` become `1202` (before the pillar) / `1203` (behind the teal gate). Integration as above
    (keys reset at run start, `KitKill` spikes, exit zone removed: the green gate is the exit door). Before moving: measure floor -> platform A (20.2 of
    21.8 studs with Triple Jump) and the low corridor under A (Dash shortcut, but §1.0: Triple Jump hovers under low ceilings) with the real talents;
    lower A by 1 stud if the bot needs more than one try in three.
  - *Transit, Cooling Deck (u 244-314, outdoors, h 0):* deck u 244-268 with `1204` at u 252, a **34 gap over the sea** (u 268-302, Long Dash gate 1;
    plain, no hazard), landing deck u 302-314 at room 2's door. The sky behind the gap is the stage's one daylight moment between two dark rooms.
  - *Room 2, Beam Hall (inner u 316-530, h 0-40):*
    (a) *laser grid* u 326-366 under a 12-high ceiling: four floor-to-ceiling `KitBeam`s (1 x 12 x 6, at u 334 / 342 / 350 / 358), Period 3, Duty 0.5,
    Telegraph 0.4, run-seeded, Phase steps of 1/6 so the off window travels west at 16 studs/s (a walker who joins the wave walks through; 8-stud safe
    pockets between beams for everyone else); (b) *sweepers* u 374-414: two double-arm laser bars (`KitMover Spin` + `Kill`, 21 x 1.5 x 6, local Y
    tilted onto world Z so they turn in the lane's plane) on hubs at u 382 / 406, h 10, Speed 60 deg/s (an arm sweeps the floor every 3 s), the second
    90° behind the first; the floor at u 394 lies 12 from both hubs and is the safe spot; `1205` at u 424; (c) *colour climb* u 434-470 up to h 28:
    grey stubs with `KitSwitch Color = "Toggle"` pads and red / blue `KitColorPlate` tiers between them, a floor pad `Color = "Red"` that resets the
    puzzle; a wrong toggle ghosts the next tier and drops the player back to the safe shaft floor (no death, lost time); a Triple Jump that skips one
    tier is a welcome shortcut, but the top must need at least one correct toggle; `1206` on the top ledge (u 470-482, h 28); (d) *finale*: a **34
    gap** (u 482-516, Long Dash gate 2) dropping 4 to the exit ledge, over a laser floor (`KitKill`, h -10), with one floor-to-ceiling `KitBeam` at
    u 499 (Period 2.5, Duty 0.4, Telegraph 0.5, run-seeded): take off as it goes dark. Exit door at u 530 to a balcony (u 532-550, h 24) with the finish
    portal at u 544 (`LookVector` -X). About 550 studs, x down to -763.
  - *Ghosts:* `KitGhostZone`s over room 1 (other players' gates / keys) and the colour climb (other players on a plate that is a ghost for you).
  - *Coins (8):* easy on the entry hall, `PlatformB` and beside the orb in room 1, the transit landing, a side tier of the climb; risky between grid
    beams 2 and 3 (above the walking line: a jump inside a dark window) and at h 6 over the sweeper safe spot; talent on a 3 x 3 ledge **25.5 above
    room 2's floor** over the sweeper safe spot (Triple Jump rises 21.8, with Jump Height 3 27.0: the "maxed soft talents" coin), placed so that a
    baseline Triple Jump + Long Dash reaches it from nowhere (bot check).
  - *Time:* entry 3 s, room 1 about 50 s, transit 6 s, room 2 about 35 s: about 95 s for a clean run; `tBase` stays at the provisional 135 until the
    user's run (Stage 13's bot run showed the provisional values are generous).
  - *No new code for room 2 / transit:* everything is existing kit (`KitBeam`, `KitMover Spin`, `KitSwitch` / `KitColorPlate`, `KitKill`, `KitGhostZone`,
    `CameraZone`). Code changes are the arena integration only (`ArenaServer` / `ArenaClient` / `ArenaConfig`) plus config (`StageConfig`,
    `ChallengeCoinConfig`). Check whether a `KitBeam`'s telegraph (Warn transparency 0.8) reads in the side view; `FloorMark` does not (seen edge-on).
- **Stage 14 Laser Lab as built (S8.2b, 2026-10-26)** (x = -213 - u, lane z -583..-577, plaza top y 78 = h 0; **every z in this section is 5 lower since 2026-10-29**, see "Centred on the gate" below: lane z -588..-582, `1201` z -585): `1201` (16 x 12, u 0, z -581); `Entry` hall
  u 8-40 (ceiling h 14, `TeachBeam` at u 28, Period 2, Duty 0.5); `Vault` u 40-240 (the arena turned 180°, entrance door 8 high in its east wall, the alcove end
  removed so the exit opens onto the deck; platform A 1 stud lower; `1202` / `1203` at u 142 / 164, 8 x 6 vault-style plates); `Deck` u 240-268 with `1204`
  (u 252), the 34 gap u 268-302 over the sea (yellow edge strips), landing u 302-314; `BeamHall` u 314-534, h 0-40: `Grid` u 326-366 under a 12-high block
  (`Beam1..4` at u 334 / 342 / 350 / 358, Period 3, Duty 0.5, Telegraph 0.4, Phase 1, 5/6, 4/6, 3/6 → the dark window moves west at 16 studs/s, run-seeded),
  `Sweepers` (hubs u 381 / 407 at **h 12**, bars 21 x 6 x 1.5, **both -45 deg/s**, Phase 0 / 90, run-seeded; `TalentLedge` 3 x 1 x 6, top h 25.5 at u 394),
  `1205` (u 424); **`ColourShaft`** u 432-482 (changed from the draft's open climb: with Triple Jump + Long Dash any stub at h ≥ 6 skips an open climb):
  an enclosed shaft of two full-width slabs, each with one hatch: slab 1 (h 10-11) holds the red `Hatch1` (u 452-458), slab 2 (h 21-22) the blue `Hatch2`
  (u 440-446); `Toggle0` on the floor (u 436-441) and `Toggle1` on slab 1 (u 462-467), Group `Lab`; the hatches are open in opposite colours, so every floor
  needs its own toggle and no jump passes both; a wrong toggle closes the hatch above (no death); `1206` on slab 2 (u 468); `Finale`: take-off u 482 (h 22),
  34 gap over a `LaserFloor` (KitKill, h -10) with `FinaleBeam` at u 499 (Period 2.5, Duty 0.4, Telegraph 0.5, run-seeded), landing u 516-530 (h 18),
  exit door, `Balcony` (u 534-554) and the portal at u 544; **the bay over the finale is 54 high** (ceiling y 132 from u 474: at 40 a Triple Jump from
  slab 2 hit the ceiling and fell short). Coins: easy in the hall, on platform B, by the orb, on the landing deck, on slab 1; risky between grid beams 2 and 3
  (h 8) and over the sweeper safe spot (h 12); talent on `TalentLedge`. 303 parts. `SoonGate14` and the prototype `Workspace.KeyArena` deleted.
- **Checks (Studio playtests 2026-10-26, bot with Triple Jump + Long Dash at Run Speed 0 / Jump Height 0; profile snapshot `profile_<id>_s82b` restored,
  the Stage 14 board entry removed):**
  - *Floor -> platform A:* at the drawn 20.2 studs 4 of 12 take-off / timing variants landed (pushing toward A too early slips under it); 1 stud lower 8 of 12
    in the lab. The low corridor under A is a real Long Dash route: single jump + Long Dash clears its four floor spikes, short Dash and Triple Jump
    hovering do not.
  - *Keys:* the teal key (Triple Jump from platform B) opens the teal gate at once, the green key (Triple Jump from the slab step beside the pillar) and its
    lock open the exit gate; both reset when a new run starts at the gate, not at a death.
  - *Long Dash gates:* deck gap: baseline TJ + Long Dash crosses, TJ + short Dash, DJ + Long Dash and a maxed Triple Jump fall, a maxed TJ + short Dash
    crosses (the known soft shortcut). Finale: TJ + Long Dash taken as the beam goes dark lands at u 518, a take-off 0.5 s later dies in the beam.
  - *Grid:* a walker starting as beam 1 goes dark (or up to 0.5 s later) walks through, later starters die at beam 1; the pockets between beams are safe.
  - *Sweepers:* as drafted (hubs h 10, then h 12; one turning against the walker) almost no start time got through (0 of 6 bot walkers; a kinematic check
    of the bar box vs the body box: 1 of 36 start angles). Both turning with the walker at 45 deg/s: a walker starting at a random moment clears each one
    53-55 % of the time; the safe spot between them held for 6.5 s.
  - *Colour shaft:* without a toggle a Triple Jump bonks on the closed `Hatch1`; `Toggle0` -> Blue, a Double Jump through `Hatch1`; on slab 1 the closed
    `Hatch2` stops a Triple Jump; `Toggle1` -> Red, a Double Jump through `Hatch2`.
  - *Talent coin:* a baseline Triple Jump rises 21.8 and misses the ledge, Jump Height 3 (27.0) lands on it and collects `Stage14_8`; coins `_3` / `_4`
    collected in passing.
  - *Full run:* the gate starts the timer, the side camera switches on (`LabCamera`, `VaultCamera` in room 1), `1201`-`1206` fire in order, the finish
    portal ends the run with a result (Gold for the teleported test run) and returns the player to the courtyard. No script errors or warnings.
  - *Fixed while testing:* a 4-stud hole in the floor under the hall's east wall and a 2-stud one between `1201` and the hall (a lane probe now finds only the
    two gaps), a support pillar sticking 6 studs up into the finale pit (a perch above the lasers), the finale ceiling, the sweepers.
  - *User's first look (2026-10-26):* the back panel flickered when seen from behind / from the start island: the Beam Hall's floor, ceilings,
    walls, blocks, slabs and emitters were 10 deep (z -585..-575) and shared the panel's outer face. All now end at z -577 (the panel's inner face);
    also fixed by the static coplanar audit (§2.3.1): the vault's corner walls vs its ceiling, `Base_L_Post`, the entry's lintel (inside the vault
    wall, deleted) and tiles (were on the panel's back), the beams' ends vs their emitters, the yellow edge strips, the hatch rims inside the
    panel (deleted), the `1204`-`1206` plates (5.8 deep).
  - *Not checked:* the look (screen captures came back white), whether the camera blends between `LabCamera` (45) and `VaultCamera` (55), a human run through
    the vault (the bot teleported between its sections; the route was checked by the kinematic search in §5.2), the real `T_base` (135 provisional).
- **Vault lanes (room 1 redesigned 2026-10-27/28 from the user's sketch; built and bot-checked, awaits the user's check).** The user's route: the dash
  corridor along the floor, a switchback up the right (`Block_Float2` from its right side, `Block_Float1`), left along `PlatformA`, up the wall ledges,
  right along `PlatformB`, up `Block_Top2` -> `Block_Top1` -> the teal key, then a fall back to the entrance floor and the dash corridor again. The
  old room did not force any of it: a Triple Jump rises 21.8 studs (27.0 with Jump Height 3), a third of the room, and the fastest max-talent path
  was floor -> `LedgeL1` -> key. Height alone cannot separate levels that close, so the room became **stacked lanes, each under a solid roof, open
  at alternate ends**, plus one-way teal gates and two colour switches (coordinates u / h as above, lane z -583..-577):
  - *Shell:* the room is **98 high over u 40-100.7** (`CeilingTall` h 98-102, `BackPanelTall` / `LaneWallTall` h 66-98, `WallLeft` to 98) and stays
    64 high to the right; `RightWall` (u 96.82-100.7, h 32.8-98) seals lanes 2 and 3 from the right. `VaultCamera` covers h -8..104.
  - *Lane 0 (floor, roof `PlatformA` + `Hatch_Low`):* `Hatch_Low` (teal `ArenaGate`, u 44-64.4, h 15.4-19.2) closes the gap between the wall and
    `PlatformA`, so nothing above can be reached from the entrance floor; the only exit is past the spikes (single jump + Long Dash under the 15.4 roof).
  - *Switchback:* `Block_Float2` widened to u 121.4-129.3 (h 3.4-8.1 since 2026-10-29, the avatar size rule); `Switch_Lane1` (`KitSwitch` Group `Vault1`, Color Blue) on its right part ghosts
    `Bar_Lane1` (`KitColorPlate` Red, u 90.5-91.5 across lane 1). Without the switch a dash + air jumps onto `PlatformA`'s right end leads nowhere.
  - *Lane 1 (`PlatformA`, roof `PlatformB`), going left:* exit at the left end, up `LedgeL1` / `LedgeL2`. `Switch_Lane2` (Group `Vault2`) on `LedgeL2`
    ghosts `Bar_Lane2` (u 76-77 across lane 2): jumping from lane 1 straight onto `PlatformB` leads nowhere. `Gate_TealBehind` (u 96.82-98.82,
    h 19.2-32.8, `ClosesWhenOpen`) is absent until the teal key, then shuts lane 1's right exit.
  - *Lane 2 (`PlatformB`, roof `Lid` + `Hatch_High` at h 46-48), going right:* `Lid` u 68.5-84 with a deadly top `Spikes.LidKill` (h 48-48.5);
    `Hatch_High` (teal, u 44-68.5) with `Gates.HatchKill` on top (`ArenaGate` + `KitKill` + `KillWhileShut`: deadly until the key, then gone). Exit
    up the chimney between the lid's end and `RightWall`.
  - *Lane 3 (over the deadly lid), going left, 16-stud steps:* `Block_Top2` u 85-91 top 52.6, `Block_Top1` u 71-77 top 68.6 (both 6 wide, spike on the
    left part), key `Hit` u 58-65 h 88-94. A step of 16 is in a baseline Triple Jump (21.8), two steps (32) are out of a maxed one (27 + ~2 ledge snap),
    so each stone is needed.
  - *After the key:* both hatches open, the player falls down the shaft to the entrance floor, `Gate_TealBehind` shuts lane 1, and the only way to the
    teal gate is the dash corridor again. The right half of the vault (green key, exit) is unchanged.
  - *Code:* `ArenaConfig.ClosesAttribute` / `KillAttribute` handled in `ArenaClient.refreshGate` (a kill strip's `KitKill` tag is removed locally;
    `CanTouch` cannot be used, the Stage 10 gargoyles' kill parts have it off); `ObstacleKit` also clears the colour groups at a run start.
  - *Model:* `tools/vault_reach.py` searches every path (optimal timing, jumps at the apex, the dash anywhere) for a profile: `max` (Jump Height 3,
    Run Speed 5, slim body, 2-stud ledge snap) to hunt shortcuts, `base` (Triple Jump + Long Dash only) for feasibility. Checks (as built, all pass):
    with either barrier shut the key is unreachable (and `Switch_Lane2` needs `Bar_Lane1` open); without `Block_Top2` or without `Block_Top1` the key
    is unreachable even at max; `base` reaches the key through every lane; after the key, with the dash corridor plugged, no max path reaches the
    right floor. Re-run it after moving any vault part.
  - *Studio playtest (2026-10-28, bot driving the root velocity, real jumps, the dash rebuilt as in `TalentDash`):* jump rises measured 7.29 / 21.81
    (baseline single / triple) and 9.03 / 26.99 (Jump Height 3), as the model assumes; pads ghost their barriers, a death shuts them again; baseline
    `PlatformB` -> `Top2` -> `Top1` -> key without a dash (`Top2` -> `Top1` carries 15.3 studs, the first layout needed 19 and fell on the lid); the
    key opens both hatches, removes the strip's kill, shuts `Gate_TealBehind`; the fall lands on the floor at u 62; a maxed Triple Jump out of lane 1's
    right end is stopped by the barrier; baseline jump + Long Dash from the floor recrosses the corridor (lands at u 108). No script errors; static
    coplanar audit of the vault clean. The backup of the old room (`ServerStorage.VaultBackup_20261027`) was deleted on 2026-10-28 after the user's check.
  - *Not checked:* a human run of the whole vault, the run-start reset of the switches (needs a real run), the look of the empty upper back panel.
  - *After the user's first playtest (2026-10-28):* the user added `Spikes.Floor_9` (hit u 81.7-83.8 on the floor, the dash felt too easy).
    `VaultCamera` now reaches the gate line (x -457..-205): the entry hall (`TeachBeam`) and checkpoint `1201` used `LabCamera` (Distance 45) or no
    zone at all, so a respawn at `1201` switched cameras twice. `Gate_Teal` sits on top of `Pillar_Lock` (u 154.9-156.9, h 12.14-64); the pillar and
    its `LockTeal_*` decor carry `ArenaGate` + `KeyId = Teal` and fade out with it (`ArenaClient` fades every gate change over 0.8 s and never turns
    on collision of a part authored without it). Checkpoint `1203` (u 164, right behind the old gate, 22 studs after `1202`) removed on disk.
    The `Beam` cylinders of `1202`-`1206` were lying along Z (rotation 0, 90, 0); turned upright like `StageKit.Checkpoint`.
    Re-checked: `base` still reaches the key with Floor_9, and from the landing (u 61.7) after the key recrosses the corridor to the right floor;
    playtest: the start at `1201` is inside `VaultCamera` (camera 55 studs off), the pillar, lock and gate fade out in 0.8 s, the lock decor never
    collides; the coplanar audit of the vault, entry and checkpoints is clean.
  - *Switch wires (user's pick of three: wire + pulse, recoloured pads, matching numbers):* nothing tied a pad to its barrier. `Decor.Wire_Lane1_1/2`
    (up from `Switch_Lane1` at x -340.5, left at y 104 into `Bar_Lane1`) and `Wire_Lane2_1/2` (up from `Switch_Lane2`, along y 119.3 into
    `Bar_Lane2`): 0.5 wide, 0.25 deep at z -577.30..-577.05 (clear of the back panel's face), dim red SmoothPlastic, tag `KitWire` + Group + Order,
    no collision / touch / query. `KitWires.client.luau` runs a green bead along the wire at 45 studs/s when the pad is pressed, lights each segment
    it passes (green Neon, while the group is off Red) and flashes the barrier (a white Neon box fading over 0.6 s); a death or run start puts the
    wire back to rest. Playtest: bead from the pad to the bar in 1.2 s, flash on arrival, wire dim again after a death, no errors; audit clean.
    Sound: Studio-only `ReplicatedStorage.SwitchSound` (rbxassetid://830440268, 0.17 s, volume 0.5, added by the user) clicks as the pad is pressed, when the bead sets off.
  - *Colour-shaft wires (user, 2026-10-29: like `Wire_Lane1`, also for `Toggle0` / `Toggle1`):* `BeamHall.ColourShaft.Wire_Toggle0_1..3`
    (up from `Toggle0` at u 438.5 to h 7.5, right under slab 1 to u 455, up into `Hatch1`'s underside at h 10) and `Wire_Toggle1_1..3`
    (up from `Toggle1` at u 464.5 to h 17, left between the slabs to u 443, up into `Hatch2` at h 21): each wire leads to the hatch its
    toggle opens; the same look and depth as the vault wires (0.5 wide, z -577.30..-577.05, dark red SmoothPlastic, no collision / touch /
    query / shadow), tag `KitWire`, Group `Lab`, Order 1-3 and the new attribute **`Switch`** (`Toggle0` / `Toggle1`). Both toggles share
    the group, so `KitWires` now picks the pressed switch (the group's switch nearest the player when the colour changes), runs the bead
    along that switch's wire only and puts the group's other wires back to rest; a `Toggle` switch's wire stays lit after its press.
    Wires without `Switch` (the vault's) behave as before. Playtest: `Toggle0` -> Blue, bead from the pad, its wire lit, `Hatch1` open;
    `Toggle1` -> Red, bead from its pad, its wire lit, `Toggle0`'s back to rest, `Hatch2` open; a death puts both back to rest;
    `Switch_Lane1` still lights `Wire_Lane1`; no errors. Coplanar audit of the shaft: nothing from the wires (it reports the toggle pads
    sinking into their bases and the floor / slab, like the vault pads, from the button restyle).
  - *Colour-shaft spikes (user, 2026-10-29: "a few spikes" in the shaft):* three single spikes (the `Right2_13` shape, hit 1.56 x 1.39):
    `ColourShaft.ShaftFloor_25` (floor, hit u 445.72-447.28, between `Toggle0` and the `Hatch1` column), `ShaftSlab1_26` (slab 1, u 448.22-449.78,
    between the `Hatch2` column and `Hatch1`), `ShaftSlab2_27` (slab 2, u 454.22-455.78, before `1206`). Playtest (single running jumps at 16):
    on slab 2 (open above) the hop is easy (feet peak 9, lands 6 past the spike); under the 10-high floor and slab-1 lanes the jump bonks
    on the slab above and carries only about 4.5 studs: collider 4.1 cleared the floor spike from u 444.3 and died from 443.5 (a take-off
    window under 1 stud), the 5.3 avatar died from 442.5.
  - *Taller shaft lanes (user, same day: "make ceilings a bit higher"):* slab 2 stays (h 21-22, level with `TakeoffBlock`, the finale is
    unchanged), so the floor went down: the hall `Floor` now ends at u 434, `ColourShaft.ShaftFloor` (a copy of it) is the shaft's floor at
    h -12..-8 (u 434-474), `ShaftRiser` (u 432-434, h -12..-4) closes the step under the hall floor's end; slab 1 (`Slab1East`, `Hatch1`,
    `Hatch1Rim`, `Slab1West`, `Toggle1`) at h 6-7; `ShaftEastWall` down to h 7 (slab 1's top: no way onto slab 1 from the hall; the way in is
    under it, 7 high from the hall floor, then an 8-stud drop); `Coin_5` 4 lower; wires follow (`Wire_Toggle0_1` from the pad at h -7.75,
    along at h 4, into `Hatch1` at h 6; `Wire_Toggle1_1` from h 7.25). **Lanes 14 / 14** (were 10 / 10), hatch climbs 15 (a Triple Jump; the
    Double Jump of the old shaft no longer reaches). Tried 12 and 13 first: the 5.3 avatar still bonked (head counts in a jump, see the avatar
    size rule). Spikes moved: `ShaftFloor_25` 2 right (hit u 447.72-449.28, a run-up from `Toggle0`'s end), `ShaftSlab1_26` to u 459.22-460.78
    (between the closed `Hatch1` and `Toggle1`; at u 449 it stood over the floor spike, and a floor hop with a hat died on it through the
    1-stud slab). Backup: Studio-only `ServerStorage.ShaftBackup_20261029` (the shaft, the hall floor, `Coin_5` before the change).
    *Playtest (running single jumps at 16):* collider 4.1: floor spike cleared from every take-off u 442.5-446.2, slab 1 from 454.5-457.3 (a
    death first, so `Hatch1` is shut), slab 2 from 449.5-452.5; the 5.3 avatar with a hat (and the developer's Jump Height level): floor
    from 444.5-445.5, slab 1 from 455.5 and 457.3 (456.5 died), a 1-2 stud window. The hat death through slab 1 is gone with the
    body-parts-only kill test (avatar size rule). Coplanar audit of the shaft: clean apart from the pads.
  - *Stud spike previews (Studio-only `Workspace.SpikePreview`, removed after the user picked `1_GlowRidge`, see §7.11 "Spike look"):* `0_Current` (light red SmoothPlastic wedges), `1_GlowRidge` (charcoal `#2C2C34` Plastic + `Studs` ridge, Neon
    `#FF5913` tip wedges along the top 0.75, 0.03 proud of the slopes; the crushers' "B" language), `2_SpikePlate` (charcoal `Studs` plate
    2.8 x 0.6 x 6 with two red teeth, same overall height 2.31), `4_RedStuds` (the current shape in red `#C4281C` Plastic + `Studs`). 39 spike
    models would change (Stage 14: 27 with the shaft's three, Stage 10: 12); the `Hit` boxes stay as they are.
  - *Stud blocks (user, 2026-10-29: "HallCeiling and similar white blocks ... Stud version"):* all 49 white (`(240, 240, 245)` / `(239, 239, 245)`)
    SmoothPlastic parts of Stage 14 are `Plastic` + `Studs`, colour, size and collision unchanged: `Entry.HallFloor` / `HallCeiling`,
    `Deck.DeckFloor` / `LandingFloor`, the vault's `Shell` (8) and `Solids` (20, `Pillar_Lock` with its `ArenaGate` fade), `BeamHall`'s floor,
    ceilings and walls (7), `ColourShaft` (8) and `Finale` (2). Not changed: `LabCamera` (camera zone, 0.9 transparent). Revert = SmoothPlastic,
    no variant. Studio-only; checked by a capture of the entry hall.
  - *Centred on the gate (user, 2026-10-29: "the mis-aligned start of the stage"):* the gate opening is centred at z -585 (like Stage 12 / 13, whose
    first plates sit on their gate's centre line), but `1201` was at z -581 and the hall / lane at -580. Every part of Stage 14 except `Gate`,
    `Arrival` and `Top10Leaderboard` moved 5 to -z (`1201` 4), 361 parts in one `BulkMoveTo`: lane now z -588..-582 (centre -585), back panel face
    -582, `1201` / `HallFloor` / `Door` all at z -585. The u / h coordinates (x, y) and `tools/vault_reach.py` are unchanged. Camera: the `Side`
    zones keep their distances, so `VaultCamera` (55) stands at z -640 and `LabCamera` (45) at -630. Near the vault the only Stage 13 part in
    front of -640 is the edge of `1101.C` (to -637, y 78.5, 6 below the camera); `GantryPost2` (z -642.5..-639.5, x -664) lies under
    `LabCamera`, 9.5 behind its camera. The draft's warning above (a lane at -585 puts the camera in `GantryPost2`) held for Distance 55 only.
    Stage 13's track is now 56 from the lab's north wall, still beyond a maxed Long Dash (46.5). Coplanar audit: no new clash (the known button
    pads, plus the template's own finish-arch stones and gate parts). Revert: the same parts +5 z (`1201` +4). Studio-only; checked by a capture
    of the gate; the user playtested it the same day ("looks good").
  - *Back panels sand blue (user pick "C", 2026-10-29):* the near-black panels hid the charcoal spikes and fit no other stage. The 5 panels
    (`Vault.Shell.BackPanel` / `BackPanelRight` / `BackPanelTall`, `Entry.HallBack`, `BeamHall.BackPanel`) are LEGO sand blue `(112, 129, 154)`
    Plastic + `Studs` (were SmoothPlastic `(44, 44, 48)`), the 11 decorative `Tile`s on them (`Vault.Decor`, `Entry`) a darker sand blue
    `(92, 108, 132)` Plastic + `Inlets` (were SmoothPlastic `(58, 58, 63)`). Previews rejected: A no panels (transparent, collision kept: the
    hub and the other stages behind the lane were busy and the back-wall wires floated), B stone grey `#A3A2A5` (the white blocks merged into
    it), D tan `(199, 172, 120)` (in the ceilings' shadow it read as muddy grey). Not changed: the dark emitters, `GridCeiling`, the deck /
    hall pillars and supports. Studio-only; checked by captures of the vault tower and the beam hall.
  - *`Gate_Teal` replaced by a full-height `Pillar_Lock` (user, 2026-10-29):* the user saw the translucent Neon gate as decoration only, but
    `vault_reach.py` (profile `max`, `DROP=Gate_Teal`, target past the pillar) showed that without it a Double Jump clears the 12-high pillar
    before the teal key. `Pillar_Lock` (white `Studs`, `ArenaGate`, `KeyId = Teal`, unchanged otherwise) now runs from the floor to the ceiling
    (h 0-64, y 78-142, u 154.0-157.8, 0.9 wider each side than the gate was) and fades with its `LockTeal_*` decor on the teal key;
    `Gate_Teal` moved to `ServerStorage.VaultBackup_20261029`. Model re-run: `max` reaches neither the pillar's top nor the floor past it before
    the key (it did stand on the old pillar's top); `base` with both switches still reaches `Key_Teal`. Coplanar audit of the pillar clean.
    Studio-only (plus `vault_reach.py`); checked by a capture; *not checked* in a playtest (the fade on the key).
- **Vault tower (the right half, green key; rebuilt 2026-10-28 from the user's second sketch, cut to four taller lanes 2026-10-29 (option A, the avatar size rule); built, model- and bot-checked, awaits the user's check).**
  The user's route: from the teal pillar along the floor, then `Block_Right2`, `Block_Right1`, `Slab_Step`, `Base_L` (hop `BaseTiny_15`),
  `Base_L_Post`, the zig-zag between the E's arms and the columns (`E_ArmBottom`, `Column_2`, `E_ArmMid`, `Column_1`, `E_ArmTop`), over
  `E_Stem` and down the slot between `E_Bar` and the stem past two spikes to the key. As first built the blocks rose 4 studs a step in an open
  chimney: a maxed Triple Jump (27) skipped from the floor to `Base_L` and from `Base_L` to the E's top, and an arm reached the key from the left
  (the pocket under `E_Bar` was open on that side). A first fix, blocks that appear one after another (`KitStep`), was taken out again (the user
  did not like it here; the mechanic stays in ObstacleKit for a stage of its own, §5.5). The bounce orb (`Pickups.Orb` / `OrbRing`) is removed.
  - *Shell:* the right half is **69.25 high over u 157.83-220** (`Shell.CeilingRight` h 69.25-73.25, raised 4.25 on 2026-10-29 so the top lane
    is as tall as the others; `RightMass`, `E_Bar` and `WallRightUpper` reach it; `BackPanelRight` / `LaneWallRight` h 66-73.25 over u 157.83-220
    extend the back panel and the invisible lane wall, which stop at h 66). The left half's `Ceiling` (h 64-68) ends at u 157.83 above the teal
    pillar. It was 103 high for the ten-ledge tower, then 65. `VaultCamera` covers h -8..115, `VaultGhosts` h 0..107.
  - *Tower (switchback lanes, like the first half; ten lanes, then six 15.8 apart, six 9.5 apart (2026-10-28), now four 14.25 apart
    (2026-10-29: six jump-dashes under a 7.5 roof were too hard, see the user's playtest below)):* four ledges, 2 thick, tops 14.25, 28.5,
    42.75, 57, hung alternately from `Solids.RightMass` (u 200.2-216, h 7.5-69.25; ledges u 179.2-200.2, gap 174.2-179.2 at the left) and from
    `E_Stem` (u 172.2-174.2, h 7.5-57, 2 thick; ledges u 174.2-195.2, gap 195.2-200.2 at the right): `Block_Right2` (R-hung), `Block_Right1`
    (stem), `Column_1` (R), `E_ArmTop` (stem, flush with the stem's top, so the climb ends walking left over the stem into the slot; the
    count must stay even). Every ledge roofs the lane below except at its gap, the gaps alternate, so each lane is walked in turn. Lanes are
    **12.25 high**, planned for the tallest avatar (collider 5.2, the avatar size rule): a ledge-up is a **Triple Jump** through the gap (a
    double jump rises 14.5 against a step of 14.25: too tight to count on). On each of the three lower ledges a **row of three spikes**
    (`Right2_13` / `b` / `c`, `Right1_12` / `b` / `c`, `Column1_19` / `b` / `c`: the `Right2_13` shape, hits 1.56 x 1.39, pitch 2.25, row 6.06
    long) ends 0.6 before the gap column the climb leaves by: R-hung ledges u 188.54-194.6, the stem ledge u 179.8-185.86. The row is a
    **jump + dash**; a single jump does not clear three spikes, and an air jump only hits the roof (the second jump of a double jump adds no
    distance under a 12.25 roof). The landing after a ledge-up has 9.3 studs before the row (a player holding the direction key through the
    whole Triple Jump drifts about 7). The top lane has no row, only **`Ceiling_21`** at full scale hanging from the new ceiling (`Hit`
    u 183.36-185.44, h 67.05-69.25: 10 above `E_ArmTop`, so a walking head and hat pass under it, a hop by any avatar dies). Taken out:
    `Slab_Step`, `Base_L` and the spikes `Slab_23`, `BaseTiny_15`, `ArmTop_24` (the old `Right1_12` / `Column1_19` shapes replaced by the
    rows); backup in the Studio-only `ServerStorage.VaultBackup_20261029` until the user's check.
  - *Floor lane:* h 0-7.5 under the stem, `RightMass` and `E_Bar` from the doorway (under `E_Bar`) to the green lock and the exit, 12.25 under
    `Block_Right2`; `Block_Right2`'s gap above it is the way in.
  - *Slot and key (widened 2026-10-28 from 4.2 to 10.2, the user got past `EBarSide_22` once in five tries):* `E_Bar` (u 157.83-162, the right half's left wall, to the ceiling) in three parts (`E_BarLower` h 7.5-41, `E_BarNotchBack`
    u ..159 h 41-45.5, `E_Bar` h 45.5-69.25): a notch at the slot floor holds the key (`Key_Green.Visual` at half size, `Hit` u 159-162.4,
    h 41-45.5: touched only by a player who landed left of the bottom spike). The slot is u 162-172.2; `EBarSide_22` on the bar near its top
    (h 55.6-56.8), `EBottom_18` on the floor (u 166.8-168.13). The slot floor is `Gates.SlotHatch` (green, u 162-172.2, h 39-41, `KeyId`
    Green + `OpensWhenHeld`): it fades out as soon as the key is held, with the bottom spike (its parts are ArenaGates too, the hit `KillWhileShut`),
    and the player drops the shaft below the slot (between `E_BarLower` and the stem) to the floor lane, then walks to the lock.
  - *Why the narrow slot failed:* stepping off the stem always carries walking speed (about 20 studs/s; with no input the character
    still drifts about 4 studs), the fall pose reaches the hands about 2 studs ahead, and ObstacleKit tests the bounding boxes of every
    character part (accessories too). In the 4.2 (and a tried 6.2) slot the hands reached the left wall at feet h 54-55, inside the side
    spike's band, whatever the input: walking off, letting go, even pulling back at once (the pull-back clears the wall only below h 47, too
    late to get back left of the bottom spike). In the 10.2 slot (bot runs, all spikes armed): **walk off holding left** lands at the
    wall on the key (alive); a jump in also passes under the side spike; a **dash in** dies on `EBarSide_22`; **letting go** after the step
    dies on `EBottom_18` (lands u 165.6-168.8); a slow straight drop (thumbstick) lands right of it (u 168.7-171.8) and hops it to the key.
  - *Code:* `ArenaConfig.HeldAttribute` (`OpensWhenHeld`): `ArenaClient` opens such a gate on the key pickup itself (no lock) and refreshes
    gates on key changes. The gate fade of 2026-10-28 (0.8 s, decor never collides) had been lost when Studio restarted and Argon synced
    Studio's older copy over the file; restored.
  - *Model:* `RIGHT=1` in `tools/vault_reach.py` (the tower as built, `PLUG=k` fills the gap of ledge k, `HATCH=open`), `MAX_STATES` env;
    `bash tools/vault_right_checks.sh` (8 checks in parallel, about a minute): a baseline player gets from the doorway to the key and lands
    left of the bottom spike; with any one of the six gaps plugged a maxed player reaches no key (so every lane is on every way to it); with the
    hatch open the slot leads to the lock zone. All pass.
  - *Studio playtest:* drop from the stem: hold u 164.2 past the side spike, steer left below it, land on the hatch at u 163 alive, key
    taken, hatch and bottom spike fade, fall 79 studs to the floor alive, walk right, the lock opens `Gate_Green` (in the 103-high room; the slot is the same 38 lower now);
    jump + Long Dash clears a ledge spike under a 7.5 roof (peak 3.3-3.5 above the ledge), a plain running hop dies on it (peak 3.6, the
    head at the roof); walking under `Ceiling_21` survives, a hop under it dies. Coplanar audit of the vault clean (`E_Bar` snapped to
    `Pillar_Lock`'s face, which it overlapped by 0.05; `CeilingRight` made as deep as `Ceiling`, its 10-stud depth shared the back panel's
    face once lowered). No errors.
  - *Not checked:* a human climb (six lanes, six jump-dashes and the ceiling spike; a death sends the player back to `1202`, there is no checkpoint in the tower),
    the look (old `Decor.Tile` panels still hang on the back wall behind the tower).
  - *User's playtest (2026-10-29): too hard for the target audience.* Three causes measured in Studio:
    - **Dash into a wall threw the player back:** the dash's unlimited-force LinearVelocity pinned the character against `RightMass` and released
      it at about 117 studs/s, 14 studs back onto `Right2_13`. The R-hung ledges end at that wall, so a dash over their spike usually ends in it.
    - **The dash was cut short under the roof:** `TalentDash` ended the burst when the humanoid left Freefall / Jumping, and under the 7.5 roof
      it reports Landed / Running with the feet still about 2 up (the whole jump lasts about 0.17 s before the head hits the roof). Pressed
      0.04-0.06 s after the jump the dash ran about 2 studs, 0.12 s 4.5, later nothing; only 0.08-0.10 s gave the full 16.
    - **Avatars collide at different heights:** the head never collides; the top of the collider is the `HumanoidRootPart` (HipHeight + 2).
      Lekzdrh's avatar: 4.1 (head top 4.9), so it fits under `Block_Float2` (gap 4.2, h 4.2-8.1 over the lane-0 floor) with 0.1 to spare;
      longer-legged avatars do not, and under a 7.5 roof their feet rise less (spike kills test every part, accessories too).
  - *Dash fix (2026-10-29, `TalentDash`):* "on the ground" is a probe under the root (the root's footprint swept to 0.6 below the feet), not the
    humanoid state, for starting, ending and giving back the dash; a box cast ahead each frame ends the burst at a wall (stepped up to it, then
    at rest, falling). Playtest with the real keys (Space, Q) on `Block_Right2`: a dash into `RightMass` stops at x -412.65 (wall -413.2),
    lands, no bounce (largest speed after it 4); jump + dash over `Right2_13` clears its hit by 1.1 (feet 2.5 up) and stops at the wall, alive;
    pressed 0.133 s after the jump (falling after the head hit the roof) the dash still runs 16.2 studs over the spike; pressed 0.02 s after
    the jump it holds the feet 1 stud up and dies on the spike (too early, as expected). Under the 7.5 roof the window is now about
    0.04-0.14 s after the jump instead of 0.08-0.10. Open-air dashes are unchanged (no wall, no false landing). No script errors.
    *Glancing walls (user, same day: "jump + Q no longer gets anywhere unless I hold left or right"):* with no direction key the dash goes
    where the character faces, often a little toward the front or back of the 6-deep lane; the wall check stopped it at the lane wall
    (playtest: 15 degrees off, 6.2 studs, then onto `Right1_12`), the old dash had slid along it. Now a hit whose remaining share along
    the wall is 0.5 or more (less than 60 degrees into it) slides along the wall with that share of the speed; a near head-on hit stops.
    Re-test: 15 degrees off on `Block_Right1`, 16.5 studs along the lane over the row, alive; head-on into `RightMass` stops after 2.8,
    largest speed afterwards 2 (no bounce).
  - *Rebuild to four lanes (2026-10-29, option A; the layout above):* also `Block_Float2` extended down to h 3.4 (top 8.1 unchanged: no avatar
    walks under it now, everyone goes over it as the 5.2-tall model always had to). `tools/vault_reach.py`: tower as built, `max` now models
    the smallest avatar (height 3.6, was 5.0), `base` the tallest (5.2); `vault_right_checks.sh` plugs gaps 1-4. All pass: `base` reaches the
    key and the slot floor, any one plugged gap keeps a maxed player from the key, the open hatch leads to the lock; room 1 (re-run with the
    3.6 `max`): either barrier shut or either top stone dropped keeps the teal key out of reach, `base` reaches it, and after the key no path
    skips the dash corridor. Coplanar audit of the vault: nothing from the rebuild; it reports the switch pads sinking 0.05 into their blocks
    (`Switch_Lane1` / `Block_Float2`, `Switch_Lane2` / `LedgeL2`, from the button restyle), left for the user.
    *Playtest* (bot driving the root velocity, jumps through the humanoid state as `TalentDoubleJump` does, the real dash on the Q key; the
    tall avatar is the player's description with body type 1, height 1.05 = collider **5.3**):
    - first version, rows of four spikes (8.35 long) in the middle of the ledges: a double jump died on the row at every air-jump timing
      (0.15 / 0.25 / 0.35 s; the air jump only hits the roof), jump + dash cleared it (4.1 and 5.3 colliders); a Triple Jump climb holding
      the direction key overshot the 6.8-stud landing onto the next row. Hence three-spike rows against the climb end;
    - as built: the 5.3 avatar's Triple Jump climbs (`Block_Right2` -> `Block_Right1`, `Block_Right1` -> `Column_1`, air jumps at 0.3 / 0.6 and
      0.2 / 0.4 s) peak 19.4-20.3 above the ledge and stand 1-6 studs short of the row, alive; jump + dash over `Right1_12` (Q 0.2 s into the
      jump) clears the hits by about 2.5 and stops at the stem, alive; single jumps over three spikes from u 189 / 188 / 187.2 all die. No errors.
  - *User's first climb (2026-10-29): a Triple Jump crosses the rows, "probably too easy".* Confirmed: air jumps fired as soon as they
    are possible bonk on the roof and die on the row (0.2 / 0.4, 0.3 / 0.6, 0.4 / 0.8 s), but air jumps on the way down (feet back
    below 4 or 2.5 over the ledge) restart the arc each time and carry the player 12-13 studs, over the row to u 175-176. Lower lanes do not
    stop it (the S8.2 note: under an 8-stud roof a hovering Triple Jump crossed 14-18), and the ledge (21) leaves no room for a longer row.
    Open: keep it (rows = Triple Jump rhythm or dash) or block air jumps over the rows only (the climbs need them).
  - *User's height adjustment (2026-10-29, "a bit harder"):* ledge tops 14.25 / 27.81 / 40.75 / 54 (lanes 11.56 / 10.94 / 11.25, top lane
    12.25), `CeilingRight` h 66.25-70.25, `RightMass` / `E_Bar` to 66.25, `BackPanelRight` to 70.25, `Ceiling_21` hit h 64.05-66.25 (10 over
    `E_ArmTop`), `EBarSide_22` 1 lower (h 54.6-55.8); `E_Stem` stayed at 57, 3 above `E_ArmTop`. `WallRightUpper` (still to 69.25) ran into the
    lowered ceiling and z-fought with it: trimmed to 66.25 (audit otherwise as before). `vault_reach.py` follows the new heights; all tower
    checks pass. Slot entry (bot, walking 16 / Run Speed 20.8, playtest): over the 3-stud stem stub a jump at walking speed lands on
    `EBottom_18` (u 168, dead), at 20.8 at u 165. Trial in the playtest only: stem trimmed flush (54) -> walking off at 16 still lands on
    `EBottom_18` (the drop is 3 shorter, so less drift), jumps land at u 161-162.5; with `EBottom_18` also moved 2.2 right (hit u 169-170.33)
    every entry lands on the key, u 160.7-163.0, collider 4.1 and 5.3. `EBarSide_22` was never touched on these paths (they pass it 5+
    studs from the wall); it only catches a dash into the slot. The user kept the layout as adjusted (stem stub, `EBottom_18` and
    `EBarSide_22` where they are).
  - *Not checked:* a human climb of the new tower, the look (the new back-panel band, the full-scale `Ceiling_21`, the old `Decor.Tile`
    panels), a climb from the floor lane into lane 1 in Studio (the model finds it), the Run Speed 5 single-jump shortcut over a row.
- **Key look (user pick "C, mint", 2026-10-29; Studio-only + `ArenaConfig` / `ArenaClient` / two strings):** the Neon keys (flat, edge-on twice a
  turn) are Stud bricks with a charcoal outline. `Shaft` / `Tooth1` / `Tooth2` are `Plastic` + `StudsSmall` in the key colour, each with a charcoal
  `*_Outline` copy grown in the key's plane (0.3 on `Key_Teal`, 0.2 on the half-size `Key_Green`: its ring spins 0.2 from `E_BarNotchBack`) and 0.1
  thinner in depth, so the core's faces stand 0.05 proud (no shared plane). `Ring` / `Ring_Outline` are CSG rings (`GeometryService:SubtractAsync`):
  the hole is empty (user: "not black"; the black `Hole` part is gone), the outline's hole is smaller by the same growth, so a charcoal lip lines it.
  A `PointLight` in `Ring` (key colour, range 8, brightness 1.5; 3 tinted the vault's ceiling 7 studs above) is the glow; `ArenaClient` turns a key's
  lights off with its parts when it is held. **The teal key is mint** `(100, 255, 190)`: cyan sat close to the azure buttons (two of them in the
  vault) and sank into the blue panel. Its id stays `Teal`; `ArenaConfig.KeyColors.Teal` (HUD chip, toast), the teal gates (`Hatch_Low`,
  `Hatch_High`, `Gate_TealBehind`) and `LockTeal_Disc` are mint, the toasts say "Mint key collected" / "Mint gate opened". Spin and bob unchanged.
  The old keys are in `ServerStorage.KeyBackup_20261029`. Checked in a playtest (`ArenaKeys` set on the server): the held key's 8 parts hide and its
  light goes off, both come back on reset; no errors. Not checked: a real pickup run, a phone.
- **Teal gate look (user pick "A", 2026-10-29; Studio-only):** `Hatch_Low`, `Hatch_High` and `Gate_TealBehind` were translucent Neon (0.45), which
  read bright cyan over the blue panel. Now opaque mint `Plastic` + `Studs` (the key's colour: mint brick goes with the mint key), each with a
  charcoal `StudsSmall` frame on its front face (`FrameTop` / `FrameBottom` full width, `FrameLeft` / `FrameRight` between them, 0.3 wide, 0.1 deep,
  standing wholly in front of the face so no plane is shared) and a centred keyhole (`KeyholeTop` cylinder over `KeyholeSlot`, the slot 0.02 less
  proud). The decor parts are children of their gate with `ArenaGate` + `KeyId = Teal` (and `ClosesWhenOpen` on `Gate_TealBehind`'s), CanCollide /
  CanTouch / CanQuery off, so they fade with it and never collide. Collision unchanged. The old parts are in `ServerStorage.HatchBackup_20261029`.
  `HatchKill` (and `LidKill` beside it) keep their red Neon strip. **`Gate_TealBehind` is still needed** (user asked, `Bar_Lane1` seemed to block lane 1):
  the switch is only reset by a death or a run start, so after the key `Bar_Lane1` is normally open; `vault_reach.py` `POST=1 B1=open B2=open` from the
  landing (61.7) without the gate reaches the right floor (floor -> `PlatformA` -> out of lane 1's right end), with it or with the bar shut it does not.
  Coplanar audit of Stage 14: nothing from the gates or keys (the 70 older clashes as before). Playtest (`ArenaKeys` / `ArenaOpened` = Teal set on the
  server): the hatches and their decor fade out and stop colliding, `Gate_TealBehind` and its decor appear (only the gate collides); no errors.
  - *`Gate_TealBehind` removed (user, same day: "it's visible when the player collects the key and blocks an entrance open from the other side").*
    Accepted consequence: after the key, with `Switch_Lane1` still pressed, the way floor -> open `Hatch_Low` gap -> `PlatformA` -> lane 1's right end
    reaches the right floor without the dash corridor (`vault_reach.py` POST no longer adds the gate). `ClosesWhenOpen` stays in the code, unused.
    Both versions of the gate are in `ServerStorage.HatchBackup_20261029`.
  - *Green gates in the same look:* `Gate_Green` (the exit door at `LockZone_Green`; the zone itself stays an invisible trigger) and `SlotHatch` are
    green `(70, 255, 100)` `Plastic` + `Studs` with the same charcoal frame and keyhole (decor with `KeyId = Green`, `SlotHatch`'s also
    `OpensWhenHeld`). The old lock decor `Decor.LockGreen_Disc` / `_Dot` / `_Slot` (Neon disc, untagged, so it stayed in the doorway after the gate
    opened) is deleted, copies in the backup folder. Audit: nothing from the gates. Playtest: holding the green key opens `SlotHatch` with its decor
    while `Gate_Green` stays shut; opening Green fades `Gate_Green` and its decor; no errors.
  - *`Pillar_Lock` under `E_BarLower` (user, same day):* the floor-to-ceiling pillar (u 154-157.8, white `Studs` with the Neon `LockTeal_*` disc)
    is now a low door filling the gap under `E_BarLower` exactly (u 157.83-162, h 0-7.5, its top on `E_BarLower`'s bottom face), mint `Studs`
    with the same frame and keyhole (decor children, `ArenaGate` + `KeyId = Teal`). The E column above it (`E_BarLower` h 7.5-41,
    `E_BarNotchBack` 41-45.5, `E_Bar` 45.5-66.25) reaches the ceiling (`Ceiling` / `CeilingRight` at 66.25), so the halves stay apart; the
    column u 154-157.83 is now open left-half space (a dead end). `Decor.LockTeal_*` deleted; the old pillar and decor are in the backup folder.
    `vault_reach.py` models the new pillar plus an `E_Column` box and has a `PastPillar` target (floor right of the E column): `max` from the
    entrance with both barriers open reaches the key, the coin and both switches but not `PastPillar`. Audit: nothing
    from the pillar. Playtest: opening Teal fades the pillar and its decor and drops its collision; no errors.

### 7.13 S8.3 Rising Tide (design check 2026-10-28; the user took every recommendation the same day: D1 A, D2 sound alone, D3 out-and-back, D4 maxed soft talents, D5 S8.3a / S8.3b)
The World 3 finale (§3 "each world finale mixes every signature of its world"): one new hazard, a **lava tide** rising under the whole
course, over a run that takes each World 3 signature again (Triple ledges and crushers, ice, wind and a timed door, Long Dash gaps
and a pendulum, a colour-hatch shaft, rolling balls and a sweeper). The stages before taught the pieces; here the tide turns every
wait and every mistake into lost height.
- **Slot** (Studio survey 2026-10-28): the **south (finale) opening** of the World 3 courtyard, `SoonGate15` (x -165..-135, z -532..-528); the
  course runs **south (+z)**. South of the wall the sea is empty: x -400..+300, z -528..-60 holds only the Tutorial (x -467..-425, from z -156)
  and Stage 5's end (x -383..-367, z -62..-46); KitLab starts at x 447. The course stays inside **x -200..-40, z -522..-140**. Gate / board /
  `Arrival` from `StageKit` turned 180° (the templates face north) onto the opening; `SoonGate15` removed. Key and folder `Stage15` under
  `World3`, checkpoint block `1301`-, coins `Stage15_1..8`. Coordinates below: **u** = distance south of the gate line (z = -528 + u),
  **v** = east of the gate's centre (x = -150 + v), **h** = height above the plaza top (y 78).
- **StageConfig (provisional, M6b measures):** `requires` Triple Jump + Long Dash (as 13 / 14), factor **4.25** (§6.4), unlock **Bronze on Stage 14
  or 5 500** (§7.2), `tBase` **100** (clean run estimated at about 80 s below; Stage 13's bot run showed provisional values run generous, so set it
  after the user's run). `tools/economy.py check` after the entry. The display name "Stage 15" and its Czech string already exist; the gate sign's
  literal text must be set to "Stage 15" in Studio (AGENTS gotcha).

**The tide (new kit piece, `KitTide`)**
- *What it is:* one Studio part `Stage15.Tide` (tag `KitTide`): a thin Neon slab (4 thick, orange-red, the "kills" colour of §2.4) whose footprint
  covers the whole course (x -200..-40, z -522..-140; it stops at the courtyard wall). `CanCollide` / `CanTouch` / `CanQuery` off. Only its **height**
  is animated, and only on the running player's client (build **L**, §2.1: each player races their own tide; other players see none, and may seem to
  stand in your lava).
- *Kill test:* while a run of this stage is active, any character part whose bottom is below the tide's top, inside the footprint, kills (client kill
  like `ObstacleKit`'s: `Health = 0`, `KitKillAt` / `KitKilledBy` = `Stage15.Tide`, `TelemetryRemotes.Report("kill", tide)`, so telemetry counts tide
  deaths per segment as their own cause). Walls and slabs do not shelter: the test is height only.
- **D1 - how the tide moves (recommended: A).**
  - **A. Each checkpoint resets the tide** (recommended): reaching a checkpoint (the `CheckpointReached` event, so the gate's `TimerStart` counts as the
    first: the server resolves it to the first plate) and every respawn there set the tide to that checkpoint's `TideFloor` (a world y, Studio
    attribute on the checkpoint's `C` plate), shown sinking over about 1 s, and it rises at its `TideSpeed` (studs/s) from there. Every segment is a fixed, learnable budget, a slow segment carries no debt into
    the next, and the sinking lava doubles as the checkpoint's reward. Re-touching the same checkpoint does nothing (no camping: standing on a plate,
    the lava arrives after (plate top - floor) / speed seconds).
  - *B. Rubber band:* the tide rises with the run and a checkpoint only raises it (never more than `Lag` below you); a death lowers it. Constant
    pressure, but a slow segment leaves the player arriving at the next checkpoint with lava at their feet.
  - *C. Pure run timer:* the tide rises with the stage timer, a death lowers it under the checkpoint. A fast player never sees it, a slow one meets
    an impossible tide late in the run.
- *Run state:* the tide exists only during a run of `Stage15` (`StageTimerUpdate`): no run = no tide (exploring without a timer shows the usual banner);
  the finish, Home, `GateExit` and a cancelled run park it out of sight. On death it stops; on the respawn it resets (A).
- *Telegraph (§2.3):* the tide is the slowest and most visible hazard; it also gets a rumble Sound (Studio-only child of `Tide`) whose volume grows as
  the gap to the player's feet drops below 15 studs. **D2:** also a small "heat" vignette under 6 studs (one new client effect, no text), or the
  sound alone for now (recommended: sound alone; add the vignette if the user's run misses the tide coming).
- *Code:* a new `StarterPlayerScripts/KitTide.client.luau` (like `KitMaze` / `KitWires`, `ObstacleKit` is already 50 kB): listens to
  `StageTimerUpdate`, `CheckpointReached` and `CharacterAdded`; attributes `TideFloor` / `TideSpeed` on the checkpoints' `C` plates (a checkpoint
  without them parks the tide: a segment can switch it off), `Footprint` from the part's own size. No server code, no remote, no new strings.
- *Budget rule (replaces "≥ 0.5 s to react" for this hazard):* in segment k the tide reaches height h after (h - floor_k) / speed_k seconds. At every
  point of the course this time must be **≥ 1.6 x a clean run's time** to that point from the checkpoint (a Bronze pace with one hazard cycle lost
  survives) and **≤ 3 x** (the lava must be seen coming; segment 1 teaches and may be looser). The course never drops below its segment's checkpoint by more than a few studs (a descent
  eats the budget twice); the one deliberate low spot is a risky coin. The bot measures the clean times in the build and the floors / speeds are
  set from them; the table gives the starting values.

**Course** (about 650 studs, h 0 -> 152; out south on v 0, across east, up a shaft, back north on v 80 high above the drowned outbound leg)

| Seg | From | Content | Floor (h) / speed | Tide reaches | Clean (est.) |
|---|---|---|---|---|---|
| 1 *Shore* (teach) | `TimerStart` / `1301` (u 7, h 0) | a 16-wide causeway at h 0 with two single-jump gaps (6), Double Jump steps up to h 11 / 22 | -24 / 1.5 | h 0 at 16 s, h 22 at 31 s | 9 s |
| 2 *Crusher ice* | `1302` (u 92, h 22) | a flat 8-wide **kit-ice ridge** (u 98-158) under three crushers (Stage 11's wave, Period 3, run-seeded), then two **Triple ledges** (20 high, gap 6) to h 62 | -8 / 1.5 | h 22 at 20 s, h 62 at 47 s | 13 s |
| 3 *Dash run* | `1303` (u 196, h 62) | three **34-stud Long Dash gaps** to 12 x 12 pillars rising 2 each (h 64 / 66 / 68), a swinging axe through the third gap (Stage 13's finale, Period 3) | 32 / 1.5 | h 62 at 20 s, h 68 at 24 s | 12 s |
| 4 *Headwind door* | `1304` (u 346, h 68) | the course turns east: `Button` (Group `TideDoor`, 9 s) on the plate, a 60-long 8-wide beam (plain floor, not ice) in a **gusting headwind** (Push 10 toward the west, Period 3, Duty 0.5) with one 12-stud Double Jump gap in its middle, a 1-stud swinging `KitDoor` into the shaft | 38 / 1.5 | h 68 at 20 s | 8 s |
| 5 *Chimney* (climax) | `1305` (v 80, u 360, h 68) | a 24 x 24 shaft, walls on three sides, **open to the north** (camera): three slabs at h 83 / 98 / 113, each with a red and a blue hatch (`KitSwitch Toggle` pads, Group `Chimney`, Stage 14's colour shaft), a `KitBeam` row across the shaft between slabs 2 and 3 (Period 3); the lava fills the shaft below you | 52 / 2.5 | h 68 at 6.4 s, h 98 at 18 s, top h 128 at 30 s | 16 s |
| 6 *Summit run* | `1306` (on the shaft's roof, h 128) | back north on v 80: a 10-wide ramp h 128 -> 148 (u 340-260) with **rolling balls** in two lanes and side pockets (Stage 13's ramp), a pad under a **sweeper** (Stage 14's, 45 deg/s, turning with the walker), a last Long Dash gap (34, drop 4) to the summit crag (h 144), the finish portal at u ≈ 140 looking north at the courtyard | 104 / 1.75 | h 128 at 14 s, the crag h 144 at 23 s | 14 s |

- *Headwind (segment 4; user, 2026-10-28: wind that slows you down; "wind seems to ignore jumps and dashes"):* `KitZones` moves the root by
  `Push` studs/s every frame, at full strength in the air and 0.6 on the ground, so it does act on jumps and dashes. Two things hide it: (1) the
  existing zones are 14-16 high from the floor (Stage 7, Stage 12's `Wind1` 14), so the root leaves the box above about 11-13 studs and a Double or
  Triple Jump's apex is out of the wind; (2) the drift is small next to a 50 studs/s dash (Push 6 takes 2 studs off a 0.32 s Long Dash). Segment
  4's zone therefore reaches **30 above the beam** (above a maxed Triple Jump's root) and blows **against** the course: in a gust a walker makes
  about 10 studs/s instead of 16, and a jump over the 12 gap drifts back about 8 studs and falls short, so the gap is crossed in the lull (one
  base period of 3 s) and the gusts cost time while the tide rises. Door time 9 s: about 5 s of walking at the gust-averaged speed + one lull
  of waiting + 1.5 s margin, measured with the bot in the build. No new code; only a taller zone. (Stage 12's wind beam has the same low zone:
  a hopping player may dodge its crosswind, to be checked separately.)
- *Timing:* every timed hazard on a 3 s base period (crushers, axe, beam row, balls 6 s, the headwind's gusts), all **run-seeded** (§2.3: short, learnable waits). Clean
  run about 72 s of segments + run-ups ≈ 80 s.
- *Checkpoint spacing:* 8-16 s of clean play, inside World 3's 20-30 s with deaths. If segment 6 is too long in the user's run, `1307` goes on the
  sweeper pad.
- *Why out-and-back:* the Clocktower (Stage 10) already spirals round a tower; here the high return leg looks down on the outbound course under the
  lava, which shows the player how far the tide has come.
- **D3 - layout (recommended: out-and-back as above).** Alternative: a single volcano cone climbed in a spiral with the lava filling the crater
  (more compact, closer to the Clocktower).
- *Camera:* default everywhere; the shaft is open to the north so the camera has room behind a climber. Check in the build whether a `CameraZone`
  (fixed yaw looking south into the shaft) reads better.
- *Ghosts:* a `KitGhostZone` over the shaft (other players on a hatch that is a ghost for you), as on Stage 14's colour shaft.
- *Fall reset:* the tide kills before Quick Respawn's 30-stud fall reset in every segment; no `FallResetDepth` attribute needed.
- **Coins (8, 20 / 50 / 100 as §7.3):** easy on the causeway's corner, the first Triple ledge, the second dash pillar, a corner of the shaft's
  slab 2, a ball pocket on the ramp; risky on a ledge 8 below the causeway (h -8: the tide reaches it 10.7 s after the start, so it is a grab
  at once or not at all) and inside the shaft in the beam row (a dark-window grab with the lava coming); talent: **D4** below.
- **D4 - talent coin (recommended: maxed soft talents, as Stages 13 / 14):** a 3 x 3 crag 25.5 above `1306` (Jump Height 3 only; a baseline
  Triple Jump rises 21.8), with the tide's 14 s running, or no talent coin until S9 (Wall Jump) and 7 coins.
- **D5 - split (recommended: S8.3a / S8.3b):** **S8.3a** `KitTide` + segments 1-2 greybox, Studio check and the user's look at the tide alone
  (is a rising floor readable and fair?), commit; **S8.3b** segments 3-6, coins, the full check. Alternative: build the stage in one go.
- **Acceptance checks:** the tide rises only during a `Stage15` run and parks on finish / Home / gate exit; reaching a checkpoint and a respawn put
  it at that checkpoint's floor; re-touching a plate does not; standing on a checkpoint dies after (top - floor) / speed s; a death in the lava
  respawns at the checkpoint with the lava down; every point meets the budget rule with a clean bot (≥ 1.6x) and a bot that waits one extra hazard
  cycle per segment still finishes; a baseline Triple Jump + short Dash does not cross the 34 gaps, Triple Jump + Long Dash does; a wrong toggle in
  the shaft costs time, not a death; kill telemetry reports `Stage15.Tide`; a full run fires `1301`-`1306` in order and ends with a result; the
  coplanar audit (§2.3.1) with `STATIC_ROOT = "World3.Stage15"` is clean (the door too).
- **S8.3a as built (2026-10-28)** (x -150 + v, z = -528 + u, heights as world y; plaza top y 78, plate tops y 78.5):
  - *Gate / board / `Arrival` / `1301`* are Stage 10's (the World 2 finale gate, same orientation) moved by (+225, 0, -1150); `SoonGate15` deleted;
    script files copied on disk from Stage 14 (`Gate`, `Top10Leaderboard`, `TeleportBackToStageStart`, `1301`-`1303`), Studio-only children grafted
    in (descendant counts equal the source's). The sign's literal text is "Stage 15". Every plate stands on a `Plate_<n>` column.
  - *`Tide`:* Neon (255, 85, 20) slab 160 x 4 x 388 over x -200..-40, z -528..-140 (from the gate line; it began at z -522 first, see the user's
    look below), parked at y -20, tag `KitTide`, `Speed` 1.5. No `Rumble`
    sound yet (silent until one is added in Studio).
  - *Segment 1 `Shore`:* `1301` (u 0-12, y 78.5, `TideFloor` 54.5); `Causeway1..3` (16 wide, y 78.5: u 12-30, 36-54, 60-72, single-jump gaps 6);
    `Step1` (8 x 8, u 78-86, y 89.5); `1302` (u 92-104, y 100.5): Double Jump ledges of 11 with gaps 6; `LowShelf` (6 x 6, y 70.5, 3 studs west of
    `Causeway2`): the risky coin's spot.
  - *Segment 2 `CrusherIce`:* `1302` (`TideFloor` 70.5); `IceRidge` (KitIce, 8 wide, u 104-164, y 100.5, flush with the plate) under `Crusher1..3`
    (first Stage 11's crusher turned to 10 x 4 x 6, centres u 122 / 134 / 146, 9 over the ice, Stroke 9, Period 3, Phase 0.5 / 0.25 / 0, run-seeded;
    now in a press with a cascade rhythm, see "Crusher rhythm" below); Triple
    ledge `T1` (10 x 8, u 170-178, y 120.5); `1303` (u 184-196, y 140.5, `TideFloor` 110.5), a second Triple ledge.
  - *`FinishTemp` (S8.3a only):* `FinishIsland` (16 x 16, u 196-212, y 140.5) with Stage 14's finish portal turned to face +z (u 206); it moves to
    the summit in S8.3b.
- **S8.3a checks (Studio playtest 2026-10-28; bots at baseline WalkSpeed 16 / JumpPower 50 with Triple Jump + Long Dash; the developer profile
  snapshot `profile_<id>_s83a` restored, `leaderboard_Stage15` removed):**
  - *Tide:* parked and hidden without a run; the gate starts it at 1301's floor; standing on `1301` kills after 15.0 s on the plate (16 s from the
    gate, as (78.5 - 54.5) / 1.5), `KitKilledBy` = `Stage15.Tide`; the respawn puts it back at 54.5; `1302` / `1303` set 70.5 / 110.5; the finish parks
    it. Telemetry classifies the kill as cause `kill:Tide` (read from `Telemetry.causeOf`; the minute's `Fail` flush was not watched).
  - *Shore:* both 6 gaps (single jump), `Causeway3` -> `Step1` -> `1302` (Double Jump, from 0.6 and 1.5 before the edge) all land; `LowShelf` is
    reached by walking off `Causeway2` (a jump overshoots its 6-stud top) and left with a Double Jump.
  - *Crusher ice:* a walker starting from rest on `1302` at 8 points of the 3 s cycle: 4 cross (start 0.75-1.875 s into the cycle), the other 4 die
    at `Crusher1` only (once past it the wave carries an ice runner through, as on Stage 11); plate to ridge end 3.9 s. Triple Jump from the ice to
    `T1`: 3 of 4 take-off points land (on the near edge, as Stage 11's 20-stud ledges); `T1` -> `1303`: 3 of 4 (0.6 before the edge falls short).
  - *Full run:* gate -> `1301` 1.4 s -> `1302` 7.5 s -> (1.0 s waiting for the crusher window) -> `1303` 14.3 s -> finish: the run ends with a
    result and the tide parks. Smallest gap between the feet and the tide: 17.3 studs in segment 1, 22.5 in segment 2.
  - *Budget:* a clean run is far ahead of the tide in both segments (segment 1: the causeway is drowned 16 s after the start, the bot left it after
    about 5 s; segment 2: the ridge drowns 20 s after `1302`, the bot was off it after 5 s). The budget rule's upper bound (≤ 3 x) cannot hold on a
    climb (the ledges outrun the tide); it applies to the flat parts. Whether the lava reads as a threat here (segment 1 teaches) is the user's call.
  - No script errors; static coplanar audit of `Stage15` clean apart from the gate and finish-arch stones every stage shares.
  - *Not checked:* the look (no capture), a human run, the rumble sound (no asset), coins (S8.3b).
- **User's first look (2026-10-28) and fixes:**
  - *Standing at the start of `1301` the lava rose in front of the player:* the footprint began at z -522, the plate reaches back to the gate line
    (z -528), so its first 6 studs were outside the tide. The footprint now starts at the gate line. Check: a bot standing on the plate's rear edge
    (z -526.9) dies 15.4 s after the gate, `KitKilledBy` = `Stage15.Tide`.
  - *The crushers could be jumped over* (they hung in open air 9-13 above the ice; a Double Jump rises 14.5). They now work inside a **press**:
    `PressWallW` / `PressWallE` (2-stud glass walls, transparency 0.5, from the sea to y 113.5, beside the ridge) and `PressRoof` (DiamondPlate until 2026-10-28, now charcoal studs,
    x -156..-144, y 113.5-133, u 113-155): its top is 32.5 above the ice, out of a maxed Triple Jump's reach (27), and the walls stop a detour round
    the sides. The crushers are 7.8 wide, 0.1 from each wall (no shared face plane; the static audit with the crushers at five points of their stroke
    is clean). Checks: the stored maxed profile (Run Speed 5, Jump Height 3, Triple Jump) jumping at 5 points of the lead-in peaks at root y 128.3
    (roof top 133) and never above y 112 inside the press; baseline walkers at 8 points of the cycle: 4 cross in 3.9 s, 4 die at `Crusher1`, as before.
  - *Same open sky on Stage 11's crusher ridge* (nothing above its `Crusher1..4`): not changed yet. Checked 2026-10-28 with a baseline bot (WalkSpeed
    16, JumpPower 50) and only the stage's required talent: a **Triple Jump taken 9-13 studs before `Crusher1` clears its top by 0.5-2.5 studs and
    lands alive in the gap behind it** (3 of 6 take-off points; a Double Jump cleared it once by 0.6 and landed on the edge). So a first-time player
    can go over the crushers; each hop has to land in a 6-stud gap between kill tops, so it is a different skill rather than a faster way. The user's
    rule: a shortcut that needs a later talent is fine, one open on the first run is not. Decision pending.
- **Crusher rhythm (user, 2026-10-28: "first falls down, then second, then last, and they all slowly go up, giving a moment to pass with a dash"):**
  - *Timing:* one cycle of **4.5 s**: `Crusher1` strikes at 2.2 s, `Crusher2` at 2.6 s, `Crusher3` at 3.0 s (Out 0.2 s, Telegraph 0.6 s), each stays
    down until the end of the cycle, then **all three rise together over 2.0 s** (`Back`). The kit's piston already works this way: same `Period`
    and `Phase` (0), `Duty` = 1 - strike / period (0.5111 / 0.4222 / 0.3333), run-seeded. No code change.
  - *Geometry:* the crushers are 10 long (u 116-126 / 128-138 / 140-150) with **2-stud gaps** (a body cannot stand in one, so the crossing cannot be
    split by waiting between crushers), 7.8 wide, 4 high, and rise to **15 above the ice** (`Stroke` 15) so a hop + dash fits under them. The press
    grew with them: walls to y 119.5, roof y 119.5-133 (its top still 32.5 above the ice). Static coplanar audit (crushers at seven points of the
    stroke) clean.
  - *Why the dash matters:* a Long Dash covers 16 studs in 0.32 s (50 studs/s, three times a baseline run of 16 studs/s) and holds the height it was
    pressed at, so a hop + quick dash stays low under the rising crushers. A timing model of the crossing (plate to u 153; R15 head 5.5 above the
    feet, ±1 stud along the course; dash 0.15 s after the hop; scratchpad script, not kept) gave: baseline runner 0 of 50 start times; one hop-dash
    0.7 s of the cycle; two hop-dashes (at u 120 and 136) 0.9 s; a runner with Run Speed 5 0.5 s (a soft talent may pass, as everywhere).
  - *Bots (Studio playtest, baseline WalkSpeed 16 / JumpPower 50, the dash rebuilt as in `TalentDash`; server-time cycle, no run):* leaving the
    middle of `1302` at 15 points of the cycle (0.3 s apart): **runner 0 of 15** (killed by `Crusher1` at 13 start times, by `Crusher2` / `Crusher3`
    when it starts as they rise); **two hop-dashes 2 of 15** (leaving 0.0 and 0.3 s after the rise begins, through in 2.75 s), others die at
    `Crusher1` or `Crusher3`. So the window is about 0.6 s: "go the moment they start lifting". If the user finds it too tight, moving the
    strikes 0.2 s later (2.4 / 2.8 / 3.2) widened the modelled dash window to 1.1 s and let a baseline runner through 0.3 s of the cycle.
- **Piston rods, one way through (user, 2026-10-28: "I can jump above them, between crushers and PressRoof; the player can pass only when the
  crushers are lifted"):** a lowered head (top 4 above the ice) left 15 studs of open space under the roof, so a hop cleared it. Now:
  - *Rods:* `Rod1..3` (steel, 7.6 x 13.5 x 11.8, unanchored, Massless, CanTouch / CanQuery off, `WeldConstraint` to their head, so ObstacleKit's
    CFrame on the anchored head carries them) fill the space from the head (sunk 0.1 into it) to y 132.9: with a head down only 1.6 studs remain
    under the roof; with it up the rod sits inside the roof. The rods do not kill; only the heads do.
  - *No gaps:* the heads are 12 long and contiguous (u 116-128 / 128-140 / 140-152), so nothing is left to stand in between them.
  - *Timing:* strikes 0.1 s later for the 2 studs longer row: **2.3 / 2.7 / 3.1 s** (`Duty` 0.48889 / 0.4 / 0.31111); period 4.5, rise 2.0 s,
    stroke 15 unchanged. Model: baseline runner 0 of 50, two hop-dashes 0.9 s of the cycle, Run Speed 5 runner 0.5 s.
  - *Look (2026-10-28):* `Crusher1..3` have the Stage 11 look (charcoal `Studs` heads, 36 Neon `Crack_n` parts per head, the pattern repeated twice over the 12-long faces, `BottomGlow`, black smoke emitter from Stage 2's `Lava block`, all welded to the head); rods and `PressRoof` as in Stage 11 → "Rod and roof look" (rod 6.2 across). Studio-only, not playtested.
  - *Checks:* coplanar audit clean (heads and rods through the stroke, neighbours at different strokes; the rods' undersides first lay in the
    roof's underside plane when up, hence the 0.1 sink). Playtest: the rods follow their heads; the stored maxed profile (Run Speed 5, Jump Height
    3, Triple Jump) jumping at 4 points in the press from 9 start times: 0 through, never above a head; baseline runner 0 of 15; two hop-dashes
    **2 of 15** (leaving 0.0 / 0.3 s after the rise begins, 2.87 s through). Same window as before the rods: about 0.6 s, "go as they lift".
  - *Slimmer rods (user, same day: "thinner than the crusher, for a better visual"):* the rods are now upright steel **cylinders, 6.2 across**
    (a cylinder part turned 90° about Z; length unchanged, still welded, bottom sunk 0.1 into the head, top at y 132.9). 6.2 is the thinnest that
    still blocks: the slot between the press walls is 8, so 0.9 is left on each side; a character is about 2 across the shoulders but only about 1
    deep, so a player strafing sideways (shift lock) might slip through 1.5. Check (playtest, the stored maxed profile): Triple Jumps at 4 points in
    the press from 9 start times facing forward and 9 strafing sideways (facing the wall, moving along the course), and single hops strafing
    sideways from 4 start times while the heads are down: **0 of 22 through**; every one is stopped by `Rod1` (furthest u 118) and dies on the
    lowered `Crusher1`. The coplanar audit does not cover cylinders; their round sides share no plane with the walls or roof.
- **S8.3b as built (2026-10-28)** (world coordinates; the return leg runs north on x -70, v 80). Checkpoints `1304`-`1306`: script folders copied
  on disk from `1303`, Argon made the bare instances, `C` / `Core` / `Beam` / `Plate_<n>` taken over from `1303` (fronts: `1304` / `1305` east,
  `1306` north). `FinishTemp` deleted; the finish portal model moved to the summit.
  - *Segment 3 `DashRun`:* `1303` (z -344..-332, y 140.5) -> 34 gap -> `D1` (12 x 12, z -298..-286, y 142.5) -> 34 gap -> `D2` (z -252..-240, y
    144.5) -> 34 gap -> `1304` (z -206..-190, y 146.5). `Axe` (4 x 52 x 2, `Swing` Hinge Z across the course, Angle 40, Period 3, Kill, run-seeded)
    hangs from y 200 over the middle of the third gap (z -223), bottom 3.5 above the take-off; frame `AxePostW` / `AxePostE` (x ±40 from the
    course, out of the blade's reach) and `AxeBeam` (y 202-205). The first build hung a 34 blade from y 179.5 (Stage 13's proportions): the triple
    jump's flight peaks 9-15 below that pivot, where the blade hardly moves aside, and every bot died; with the pivot 55 above the take-off the blade
    is in the flight path only near the bottom of its swing.
  - *Segment 4 `Headwind`:* `Button` (KitButton, Group `TideDoor`, Time 9) on `1304`; `WindBeam1` / `WindBeam2` (8 wide, y 146.5, x -144..-120 and
    -108..-84, the 12 gap between); `Wind` (KitZone, 60 x 30 x 12 over the beam, Push (-10, 0, 0), Period 3, Duty 0.5, run-seeded); `TideDoor`
    (1 x 20 x 8 wooden door in the shaft's west wall, Stage 12's look and bands / knobs welded, hinge on its north edge, OpenTurn -90: it swings out
    toward the approaching player, clean through the swing in the door audit).
  - *Segment 5 `Chimney`:* shaft inside x -82..-58, z -210..-186 (walls `WallW_*` / `Lintel` round the door, `WallE`, `WallS` solid, `GlassN`
    glass at transparency 0.5 so the camera can look in from the north, all from the sea to y 205.5). `1305` on the floor (y 146.5) beside the door;
    `Slab1..3` (tops y 161.5 / 176.5 / 191.5) and `Roof` (y 206.5), 15 apart (a baseline Triple Jump rises about 21), each with **one 6 x 6 hatch**
    (KitColorPlate, Group `Chimney`: slab 1 red in the south-east corner, slab 2 blue south-west, slab 3 red south-east, roof blue south-west) and a
    `Toggle0..3` pad on the level below it (floor east, slab 1 / 3 north-west, slab 2 north-east). Groups start red, so each toggle opens the hatch
    above and closes the one underfoot; stepping on it twice closes it again (costs a walk back, not a death). This differs from the table's "a red and
    a blue hatch per slab": one hatch per level is Stage 14's proven pattern and already forces the walk across every slab. `Beam1` / `Beam2`
    (KitBeam, 1 x 13.8 x 23.8 across the shaft at x -74 / -68, between slab 2 and slab 3, Period 3, Duty 0.5, Telegraph 0.4, Phase 0 / 0.867 so
    the second follows the first by 0.4 s, run-seeded, FloorMark) cut slab 2 between its hatch and its toggle; `ChimneyGhosts` (KitGhostZone).
  - *Segment 6 `Summit`:* `1306` on the roof (z -210..-198); `Ramp` (9.9 wide, z -212 -> -292, y 206.5 -> 226.5, Stage 13's slope) on two
    `RampPost`s, `Ball1..4` (Stage 13's: two lanes x -72.5 / -67.5, Roll Distance 78, Period 6, phases 0 / 0.5 and 0.25 / 0.75, run-seeded),
    `Pocket1..3` at its sides; `SweepPad` (10 x 24, y 226.5) between glass `SweepWallW` / `SweepWallE` (to y 256, out of a maxed Triple Jump's
    reach, so nobody goes round the bar), `Sweeper` (21 x 9.8 x 1.5, Spin about the course's cross axis, axle 12 above the pad at z -304, Speed -45:
    the lower arm moves north with the walker, Phase 90, Kill, Carry false, run-seeded) on `AxleW` / `AxleE` stubs; a 34 gap (drop 4) to `Crag`
    (16 x 16, z -366..-350, y 222.5) with the finish portal (z -362, facing north); `TalentPillar` (3 x 3, top y 232.5, 25.5 above the roof, off the
    shaft's south-east corner).
  - *Tide (checkpoint attributes, world y / studs per s):* `1303` 116.5 / 1.5 (was 110.5), `1304` 125.5 / 1.5, `1305` 130 / 2.5, `1306` 182 / 1.75.
  - *Coins* (`ChallengeCoins`, ids in `ChallengeCoinConfig`): `Stage15_1` Causeway1's corner, `_2` LowShelf (risky), `_3` on `T1`, `_4` D2's corner,
    `_5` slab 2's north-west corner, `_6` 6.5 above slab 2 between the two beams (risky), `_7` over `Pocket2`, `_8` on `TalentPillar` (talent).
    `economy.py pin` for the new coin count, check 43 / 43.
- **S8.3b checks (Studio playtest 2026-10-28; bots at baseline WalkSpeed 16 / JumpPower 50, Triple Jump + Long Dash rebuilt as before; developer
  profile snapshot `profile_<id>_s83b` restored, `MostStars` 45, the Stage 15 board left with the user's own 34.8 entry):**
  - *Long Dash gaps:* `1303` -> `D1` (34, rising 2): Triple Jump + Long Dash at the apex lands 2 studs onto `D1`, dashing 0.2 s after the third jump
    0.4; a short dash (0.2 s) and a dash 0.1 s after the third jump fall short. Rising 2 per gap makes these the hardest Long Dash gaps so far
    (Stage 13's are flat or drop). Last gap (34, drop 4): lands 3.5 onto `Crag`.
  - *Headwind:* walkers from `1304` reach the gap in about 2 s; a Double Jump launched in a gust fell 0.5 short, launched in the lull it lands;
    button -> door -> `1305` in 5.4 s (door time 9).
  - *Chimney:* toggle, hatch and Triple Jump up through every level work (each landing beside its hatch); crossing the beams just as `Beam1` goes
    off passes; 0.3 / 0.6 s later died at `Beam2` before its phase fix (with 0.867 the window is about 1.2 s by the timing).
  - *Ramp:* a plain walker or a lane-switching bot dies within 2 s (the two lanes cover the width, as on Stage 13); a bot that jumps the balls of its
    own lane when one is 9-10 studs ahead got up 7 of 8 times in 5.4 s (5-6 studs ahead was too late).
  - *Sweeper:* leaving the ramp top 0.45-2.4 s after an arm is vertical passes (about 2 s of its 4 s cycle); 0-0.3 s after, the walker catches the
    rising arm, 3 s after, the next arm comes down.
  - *Full timed run* (gate -> finish, tide live): `1301` -> `1302` 6.2 s. The crusher press stopped the bot (6 tries, the known 0.6 s window), so it
    was put on `T1` and jumped to `1303` itself; from there without a death: `1303` -> `1304` 7.2 s (with the axe wait), `1304` -> `1305` 5.8 s,
    `1305` -> `1306` 16.6 s (with the beam wait), `1306` -> finish 12.7 s; the run ended with a result and the tide parked. Smallest gap between
    feet and tide: 24.8 / 21.2 / 11.9 / 18.2 studs in segments 3-6 (with the old floors of 3 and 4). Clean run about 55-60 s (`tBase` 100 stays
    provisional until the user's run).
  - *Budget:* the tide reaches the segment's end at 3.3x (segment 3) and 3.4x (segment 4) the bot's time, so both floors were raised 6 / 9 studs:
    now 2.8x / 2.4x. Segment 5: the roof drowns at 30.8 s (1.9x), the floor at 6.6 s (the bot left it after about 3 s); segment 6: the crag at 23 s
    (1.8x). A lost hazard cycle (axe 3 s, gust 3 s, beams 3 s, sweeper 4 s) still fits every segment by these times (not run as a bot).
  - *Talent coin:* a baseline Triple Jump from the roof peaks 21.5 above it (pillar 25.5), Jump Height 3 peaks 26.5 and collected `Stage15_8`.
  - *Tide:* after the finish the portal sent the bot to the gate, which started a new run: the tide rose at `1301` again and killed it there
    (`Stage15.Tide`), respawns reset it.
  - Static coplanar audit of `Stage15` clean apart from the gate and finish-arch stones every stage shares (one clash found and fixed: the ramp's
    sides lay in the sweeper pad's side planes, so the ramp is 9.9 wide); the door audit is clean.
  - *Not checked:* the look (no capture), a human run, the camera inside the shaft (west wall solid; the north side is glass), the rumble sound
    (no asset), maxed-talent shortcuts in segments 3-6 (e.g. over the sweeper's top at 22.5 above the pad: a maxed Triple Jump rises 27).

## 8. Milestones (agreed 2026-10-21; status in [ROADMAP.md](ROADMAP.md), full scopes of finished milestones in `git show 53bd79b:docs/ROADMAP.md`)
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
