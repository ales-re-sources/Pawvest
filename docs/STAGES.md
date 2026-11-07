# Pawvest — Stage expansion plan (≈ 20 stages)

Status: **agreed plan** (2026-10-21); nothing is built yet. Decided with the user: today's Stage 3 becomes the finale of
World 1 (slot 5); stages are grouped in **worlds of 5**; four **new talents** (Triple Jump, Dash, Glide, Wall Jump) plus the
utility talent Quick Respawn (§6.2.1); a talent requirement is shown as a **hint + warning, entry stays open**; **one special
stage per world** (rhythm, isometric shifting maze, 2D side-scroller, dropper) plus **bonus stages** outside the unlock chain
(§5); milestones S1–S11 (§8) are in the [ROADMAP](ROADMAP.md), trading (P3) after all 20 stages. Numbers (prices, factors,
`T_base`) are provisional, like everything in [GDD.md](GDD.md), until M6. GDD §3–6 is updated from this file in S1 (design
first: GDD → ROADMAP → code); the open questions in §9 are answered then.

## 1. Today's stages and movement
The 15 world stages and the Tutorial are listed in GDD §3 (names, signatures, medal times) and `StageConfig`; their as-built notes are §7.6-7.13
below (World 1's older stages: GDD §3). Place settings: `CharacterUseJumpPower`, JumpPower 50, WalkSpeed 16, gravity 196.2, MaxSlopeAngle 89,
`StreamingEnabled` off (the kit stays streaming-ready, §2.4).

**Stage 5 (the World 1 finale, was "Stage 3")** is the shortest course but the slowest: pure precision, no timing obstacle, doable without talents.
1. **Max-distance jumps** (20 → 26): five gaps of 10.5 over four plates spaced evenly between the checkpoints, each 1 higher, rebuilt 2026-11-01
   (K1) with a **1-stud lip**: every landing plate overhangs its column by 1 stud on the approach side. A character arriving just short of the edge
   while holding forward grabs the lip and climbs up (Humanoid `Climbing`); a column flush with its plate is a wall and the same jump slides down.
   Without talents, jumping at the edge clears it (jumping 0.5 early fails); 11-stud gaps fail even with the lip. **Use a lip wherever a jump is
   meant to be "very hard but doable" at the edge of reach.**
2. **Wrap-around** (`level.2`): three walls fill the width of a 40-stud floor; you jump out around each one's side over the void.
3. **Tightrope** (21 → 22): a zig-zag of five 2 × 0.4 beams with four 2-wide red kill nubs to hop (widened 2026-11-01 from 0.1-stud wires, too
   hard on a touch stick).

A death there costs about 30 s of replay (about 8 s on Stage 1).

**Movement reach in short:** a single jump rises about 6.4 studs and carries about 8 studs flat at WalkSpeed 16 (10.6 with Run Speed 5; with the
character's own length the longest gap is about 11-12); Double Jump rises about 12.7-14.5. Only the air-jump and dash talents separate "can" from
"cannot" with a clear margin; Run Speed and Jump Height differ by 1-2 studs or 5 % per level, too little for a fair hard gate (§6.1). The measured
numbers per talent set are in §1.0.

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
  and updraft particles, plate looks, beam glow etc. come in a later visual pass in the stud style (decided 2026-11-05;
  look rules §2.5), as presets on the `StageKit.Obstacles` templates. Only the functionality (attributes
  and behaviour in the script headers) is fixed.
- **S3.1 spike result (2026-10-21):** carry by frame delta is exact (no drift) and needs a short air-carry (0.5 s) after
  jumping off; tilt plates need an explicit slide-off (freefall + downhill velocity) because `MaxSlopeAngle` is 89; the client
  kill reaches the server in one message; 100 movers cost 0.34 ms per frame. Other players see riders ~0.2 s behind a moving
  platform (replication delay). Details: `git show 53bd79b:docs/ROADMAP.md` (S3).
- For the special stages the kit also holds `StageCamera`, run-seeded schedules and ghost drawing of other players (§5.1).

### 2.5 Look language of kit parts (user picks 2026-10-28 / 29; Studio-only)
Every stage uses the stud look (`Plastic` + a `MaterialService.StudPack` variant). Decoration is always a child of the kit part, unanchored,
Massless, CanCollide / CanTouch / CanQuery / CastShadow off, `WeldConstraint` to the part (so it follows the kit's CFrame), and never shares a face
plane with it (rims 0.03 in from the edge, frames standing wholly in front of the face). **Build a new piece by cloning a restyled one**
(`ServerStorage.StageKit.Obstacles` templates, or e.g. `Stage14.Vault.Spikes.Right2_13` for a spike); a resized part needs its decoration redone.
- **Colours mean things:** red / orange = kills you, so no pad or safe part is ever red. Translucency means "not solid" (ghost plates 0.85,
  ghost steps 0.75), so solid parts are opaque.
- **Solid hazards** (crushers, spikes, blades): charcoal `Studs` body with glowing Neon cracks / ridge (`#FF5913` spike tips), a Neon
  `BottomGlow` and black smoke on crushers. The kit's telegraph tints the body to `WarnColor` (255, 170, 60).
- **Lava-like floors:** the kill part in dark red `Studs` covered by `LavaTile_n` children (2 x 4, palette dark red / red / orange, ~1 in 5 Neon
  orange) and a `LavaSmoke` emitter on large parts (low rates for phones).
- **Moving plates** (`KitMover`): LEGO yellow `#FFD54A` `Studs` with amber rim bars `RimN/S/W/E`, an amber `Hub` on discs. A gear is one union that
  *is* the mover (the kit carries a rider only on the exact `KitMover` part). Flips (Stage 10, and Stage 8's `Flip1-5` / `FlipB1-4` since 2026-11-05) the same: `Axle` bar with `AxleCapE/W` through the hinge, rims on both
  faces (the warning tint is close to the yellow). Cloned from `Stage10.Movers.Flip_1`; the Stage 8 flips keep their own `FlipN_Axle` pillars below.
- **Conveyors** (`KitConveyor`, 2026-11-05): a charcoal `(44, 44, 52)` `Studs` belt slab (1-1.2 thick) with stone grey `Roller1/2`
  cylinders across both ends (none at an end another part touches within 0.5 studs) and amber `#E29314` `Studs` chevrons (`Chevron<n>L/R`,
  arms 0.6 x 0.1 x 3.2 at 40 deg, 0.06 proud) pointing the way the belt pushes (`-Speed` points them backwards). A conveyor over the sea stands
  on its own stud pillar (`ConveyorBase<n>`, 0.1 inset), so only the top pushes. In play `KitConveyorsClient` slides the chevrons along the
  belt at `Speed` and turns them if the sign changes; space them evenly (belt length / count) so the wrap looks even. Template
  `StageKit.Obstacles.Conveyor_Belt`.
- **Tilt plates** (`KitTilt`): green `(58, 165, 92)` `Studs`, dark green rims, a charcoal hinge pin (`Axle`, `AxleCapW/E`) on the tilt axis.
- **Disappearing plates** (`KitPlate`): opaque `(0.75, 0.67, 0.55)` `Studs`, no decoration (the flicker is the cue). **Crumbling plates**
  (`KitCrumble`): sandstone `(222, 170, 100)` `Studs` with dark brown `Crack_n` lines. The kit fades a plate's decoration with it.
- **Ice** (`KitIce`): smooth `Plastic` `(0.70, 0.87, 0.98)` with a glass `Cap`, white `Studs` rims and collars framing it (smooth = slippery,
  studs = grip, so studs only frame the slick surface); no rim where another part touches within 0.5 studs.
- **Buttons and switches** (`KitButton` / `KitSwitch`): azure `(0.0, 0.6, 0.86)` `Studs` plates standing 0.6 above the floor on a charcoal
  `Base` slab; a pad over a gap is a charcoal housing with an azure `Cap` (the kit treats a hit on the `Cap` as the part and tints it green when
  pressed). `ReplicatedStorage.SwitchSound` clicks.
- **Pushing pistons / rods / roofs:** stone grey `#A3A2A5` `Studs` with yellow `Inlets` bands and charcoal collars; press roofs charcoal `Studs`
  with yellow bands. Pendulums brass `Studs` with a charcoal hub; clock hands charcoal with red Neon edges.
- **Keys and key gates** (Stage 14): keys are stud bricks in the key colour with a charcoal outline and a `PointLight`; the teal key is **mint**
  `(100, 255, 190)` (cyan sat too close to the azure buttons); key gates are opaque mint / green `Studs` with a charcoal frame and keyhole (decor
  tagged like the gate, so it fades with it).
- **Lab panels:** back panels LEGO sand blue `(112, 129, 154)` `Studs` with darker `Inlets` tiles; former white SmoothPlastic blocks are `Studs`.

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
pets, incubators and the field, without blocking the no-grind path. Run Speed / Jump Height could get more
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
  - *Stage 5 fix (2026-10-22):* the checkpoint between `level.1` and `level.2` of Stage 3 had been lost (LAYOUT.md → Stage anatomy), leaving a 23-stud gap; restored, the
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
LAYOUT.md "Adding a world stage" plus the `StageConfig` entry (`world`, `requires`, key, prices).

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
  part's front; negative = backwards); the server sets the anchored part's `AssemblyLinearVelocity` once. Since 2026-11-05 each is a stud
  belt (§2.5) 1.2 thick on its own pillar `ConveyorBase1/2` (top still at y 79.5, 8 x 18).
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
  moved +60 in z (the decor at the board's spot was removed); script files were copied by hand (LAYOUT.md "Adding a world stage").
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
- **World stars boards (decided, REMOVED 2026-11-02: not useful; only the hub's `MostStars` board remains, the `WorldStars_<n>` stores were emptied the same day):** each world plaza gets a board of the players with the most stars earned in that world (not the total):
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
  (the key arena holds 301-303). Each stage was built from clones of the previous gate / board / `Arrival` / finish and checkpoints, script files copied by hand (LAYOUT.md "Adding a world stage").
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
  carried closed "Coming soon" doors (`SoonGate8..10`, replaced by the real gates). **Look:** the Island Hop look (stud columns from the sea) (the world style stays stud, decided 2026-11-05).
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

### 7.11 S8.1 Triple Peaks + Ice Rink (built 2026-10-24, accepted by the user 2026-10-26; compacted 2026-11-05, the full design, build and tuning log is `git show 87b1d3c:docs/STAGES.md`)
- **Slots:** World 3 is World 2 moved by (+225, 0, -1150): stage 11 = east near gate (x -93.3, z -645, course east, band z -678..-615), stage 12 =
  east far gate (x -93.3, z -585, east, band z -609..-546); the sea east of the courtyard is free up to KitLab (x 447+). Folders `Stage11` /
  `Stage12` under `Workspace.World3`, checkpoint blocks `901`- / `1001`-, coins `Stage11_1..8` / `Stage12_1..8` (the talent coin needs Dash).
  World 3 opens with stage 11 (as World 2 did). `requires` Triple Jump; prices and provisional `tBase` in `StageConfig`.
- **Reach rules for Triple Jump stages** (§1.0): the gate is the **ledge height**, not the gap. A ledge is cleared with a root rise of about its own
  height, so **Triple ledges are 20** (gap 6): a baseline Triple Jump lands them with several timings, a maxed Double Jump (Run Speed 5 + Jump Height
  3, rise 18.0) fails every one. Flat Triple gaps of 17 (8-stud side shift) are soft (a fast Double Jump may make them).
- **Stage 11 Triple Peaks as built** (x = -87 + u, z = -645 + l, h above y 78.5; plates 12 along, 16 wide): `901`; Double Jump pillars `A1`-`A3`
  (h 0 / 11 / 22); `Shelf1` with tower `T1` (the first Triple ledge over a safe shelf); `902`; peaks `P1`-`P4` (Triple ledges, a flat 17 gap);
  `903`; the kit lift `Lift1` (h 58 → 92, period 10) with a Triple ledge from its top to `P5`; `904`; the **crusher ridge** `Ridge` (66 x 6, h
  112) under `Crusher1..4` (kit `Piston` down, Stroke 9, Period 3, Duty 0.25, Telegraph 0.6, `Kill`, run-seeded, each slamming 0.75 s after the one
  before, so a walker who leaves as crusher 1 lifts follows the wave) inside a **press** (`Stage11.Press`: glass `PressWallN` / `S` from the sea
  to the crushers' raised top, `PressRoof` 32.5 above the ridge, out of a maxed Triple Jump's reach; added 2026-10-28 because a baseline Triple
  Jump hopped over the crushers on a first run) with `Movers.Rod1..4` (5.6 across: the slot is 6) welded on the heads; `905`; `Summit` (Triple
  ledge), descent `D1`-`D4`, finish island, portal at u 432. `FallResetDepth = 75` (the descent ends 65 below `905`).
- **Stage 12 Ice Rink as built** (z = -585 + l): `1001`; `Rink1` (44 x 24 ice) and the ice turns `I1`-`I3`; `1002`; four 10 x 10 ice plates
  `J1`-`J4` (gaps 5-7, side shifts 8: hop on at once, a stop slides you off); `1003`; the pressure `Button` (Group `IceDoor`, 8.5 s) right behind
  `1003` at the start of `WindBeam` (66 x 8 ice in the steady crosswind `Wind1`, Push 6), the rest plate `Plate_1004` (no checkpoint since
  2026-10-26: a fall replays the wind beam), ice track `Track1..3` with two 5-stud gaps, `IceDoor` (1-stud wooden door hinged on its north edge,
  `OpenTurn -90`, swings toward the player, §2.3.1); `1005`; Triple ledges onto ice `K1`-`K3`, finish island, portal at u 466. At 8.5 s the door
  leaves 1.5 s at the default WalkSpeed 20.8 and is missed at 16 (Run Speed is effectively needed).
- **Kit ice (`KitIce`, `ObstacleKit`):** on a `KitIce` floor the client drives the horizontal velocity toward the input at `Accel` (14) and coasts
  without input at `Brake` (5): 15.5 studs/s after 1 s, a 21-stud coast. The kit sets friction 0 / weight 100 on every ice part locally (the
  Humanoid's own grip otherwise stops a slide on Plastic). **Ice-air:** from leaving a `KitIce` part until the next landing the kit keeps driving
  the root at `AirAccel` (14), never braking without input; a dash in ice-air restores the slide afterwards (character attribute `IceAir`, read by
  `TalentDash`). A teleport or death ends it.
- **Door countdown:** a big number at the door's middle (seconds rounded up, a bar green → orange → red, drawn through walls) and ticks in the
  last 3 s (Studio-only `ReplicatedStorage.DoorTickSound`), for every `KitDoor` (Ice Rink, Clocktower).
- **Open:** Stage 12's `Wind1` zone is only 14 high, so a hopping player may dodge the crosswind (not checked); a human run's `tBase`.

### 7.12 S8.2 Dash Bridge + Laser Lab (built 2026-10-26 – 29; compacted 2026-11-05, full log `git show 87b1d3c:docs/STAGES.md`)
- **Slots:** the west openings of the World 3 courtyard: stage 13 = west near gate (z -659..-630, course **west**, band z -678..-615), stage 14 =
  west far gate (centre z -585, band z -609..-546); the sea west is free to about x -950 (the hub starts at x -1038). Folders `Stage13` /
  `Stage14`, checkpoint blocks `1101`- / `1201`-. Both require Triple Jump + Long Dash.
- **Dash gates = Long Dash** (decided 2026-10-26): open-air gaps had a 2-stud window between a baseline Triple Jump + Dash and a maxed Triple Jump,
  so Dash got a **second level, Long Dash** (0.32 s at 50 studs/s = 16 studs; a faster burst could pass thin kill beams between two touch tests)
  and stages 1-12 keep their tuning. Hard Dash gaps are **34 studs flat** (§1.0). Talent coins of stages 13-15 need **maxed soft talents** (Jump
  Height 3 or Run Speed 5: every World 3 talent is already required).
- **Rolling balls (`KitMover Kind = "Roll"`):** the ball travels along `Axis` for `Distance` studs in `Period` (Phase, RunSeeded), turns about the
  cross axis so it looks rolling, sinks / fades in `Fade` s at both ends, `Kill` by default. No physics.
- **Stage 13 Dash Bridge as built** (x = -213 - u, course along z -657, h above y 78.5; **every part stays north of z -644**, behind the Laser Lab's
  camera): `1101`; runway `R1`, a 22 gap (any Dash) to `L1`, a 34 gap to `L2`, both over catch floors `Catch1` / `Catch2` **32 below** with a truss
  back up (8 below let a short jump climb out without a Dash; `FallResetDepth = 40`); `1102`; 34 gaps over the sea to `P1`, `P2`; `1103`; a 6-wide
  `Bridge` under `Axe1..4` (hung from a beam 38 above the deck so no Triple Jump lands on it; `Swing` Hinge X, Angle 24, Period 3, phases 0 /
  0.708 / 0.417 / 0.125 = a wave a 16 studs/s walker follows); `1104`; `Ramp` (h -6 → 14, 10 wide) with `Ball1..4` (Ø 5, `Roll` Distance 80,
  Period 6, two lanes, one ball every 1.5 s alternating; 3 per lane killed even a jumping bot) and side `Pocket1..3`; `1105`; a 34 gap through
  `AxeFinale` (Angle 50, Period 4) to `F1`, a 22 gap to `Finish`, portal at u 514. Talent coin on `TalentPillar` 41 north of `F1`.
- **Stage 14 Laser Lab as built** (x = -213 - u; **lane z -588..-582**, centred on the gate at z -585 since 2026-10-29; h above the plaza top y 78;
  2D side view, `Side` camera zones with `Yaw 180`: `VaultCamera` Distance 55 over the vault and the entry, `LabCamera` 45 elsewhere; Stage 13's
  track is 56 north of the lab's wall, beyond a maxed Long Dash): `1201`; `Entry` hall with `TeachBeam` (the first "lit = death" over a safe floor);
  the **Vault** (room 1, below); `Deck` with `1204` and a plain 34 gap over the sea; the `BeamHall` (h 0-40): `Grid` (four floor-to-ceiling
  `KitBeam`s, Period 3, Duty 0.5, the dark window moving west at 16 studs/s), `Sweepers` (two double-arm laser bars, hubs at h 12, **both turning
  with the walker** at -45 deg/s, Phase 0 / 90; a walker clears each about 54 % of start times, the floor between them is safe; `TalentLedge` 25.5
  above the floor), `1205`, the **`ColourShaft`** (an enclosed shaft: `ShaftFloor` at h -12, slab 1 at h 6-7 with the red `Hatch1`, slab 2 at h
  21-22 with the blue `Hatch2`, lanes 14 high; `Toggle0` on the floor and `Toggle1` on slab 1, Group `Lab`; the hatches are open in opposite
  colours, so each level needs its own toggle and a wrong one costs time, not a life; three single spikes; wires from each toggle to its hatch),
  `1206` on slab 2, the `Finale` (a 34 gap over a `LaserFloor` with `FinaleBeam`, Period 2.5: take off as it goes dark; the bay is 54 high so a
  Triple Jump from slab 2 does not hit the ceiling), balcony and portal at u 544. Back panels sand blue (§2.5). Every part ends at the back panel's
  inner face (z -582 side): a part through the panel z-fights (§2.3.1).
- **Vault lanes** (room 1, the left half; from the user's sketch, 2026-10-27/28). A Triple Jump rises 21.8 (27.0 with Jump Height 3), a third of the
  room, so height alone cannot force a route: the room is **stacked lanes, each under a solid roof, open at alternate ends**, plus one-way teal
  gates and two colour switches. Route: the dash corridor along the floor, a switchback up the right, left along `PlatformA`, up the wall ledges,
  right along `PlatformB`, up `Block_Top2` → `Block_Top1` → the teal (mint) key, a fall back to the entrance floor and the dash corridor again.
  - *Shell:* 98 high over u 40-100.7 (`CeilingTall`), 64 to the right; `RightWall` seals lanes 2-3 from the right.
  - *Lane 0* (floor, roof `PlatformA` + `Hatch_Low`, a teal `ArenaGate`): the only exit is past the floor spikes (single jump + Long Dash under the
    15.4 roof; `Spikes.Floor_9` added by the user).
  - *Switchback:* `Block_Float2` (top h 8.1, down to h 3.4 so no avatar walks under it) with `Switch_Lane1` (Group `Vault1`), which ghosts
    `Bar_Lane1` across lane 1.
  - *Lane 1* (`PlatformA`, going left): exit at the left end up `LedgeL1` / `LedgeL2`; `Switch_Lane2` (Group `Vault2`) on `LedgeL2` ghosts
    `Bar_Lane2` across lane 2.
  - *Lane 2* (`PlatformB`, roof `Lid` with the deadly `Spikes.LidKill` + `Hatch_High` with `Gates.HatchKill`, `KillWhileShut`): exit up the chimney
    between the lid's end and `RightWall`.
  - *Lane 3* (over the lid, going left): `Block_Top2` (top 52.6) and `Block_Top1` (top 68.6), **16-stud steps**: one is inside a baseline Triple
    Jump, two (32) are out of a maxed one, so each stone is needed; key `Hit` at u 58-65, h 88-94.
  - *After the key* both hatches open and the player falls to the entrance floor. `Gate_TealBehind` (shutting lane 1's right exit) was removed on
    the user's request (it showed and blocked an entrance): with `Switch_Lane1` still pressed, floor → `PlatformA` → lane 1's right end now
    reaches the right floor without the dash corridor (accepted). `ClosesWhenOpen` stays in the code, unused.
  - *Teal lock:* a low mint door filling the gap under `E_BarLower` (u 157.83-162, h 0-7.5; `ArenaGate`, `KeyId = Teal`); the E column above it
    reaches the ceiling, so the halves stay apart.
  - *Wires:* `Decor.Wire_Lane1_*` / `Wire_Lane2_*` (and the colour shaft's `Wire_Toggle*_*`, attribute `Switch`) run from each pad to the barrier
    it opens; `KitWires.client` runs a green bead along the pressed pad's wire and flashes the barrier; `SwitchSound` clicks.
  - *Code:* `ArenaConfig.ClosesAttribute` / `KillAttribute` / `HeldAttribute` in `ArenaClient.refreshGate` (a kill strip's `KitKill` tag is removed
    locally; gate changes fade over 0.8 s and never turn on the collision of a part authored without it); keys and switches reset at a run start,
    not at a death.
  - *Model:* `tools/vault_reach.py` searches every path (optimal timing, apex jumps, the dash anywhere): `max` (Jump Height 3, Run Speed 5, the
    smallest avatar, 2-stud ledge snap) hunts shortcuts, `base` (Triple Jump + Long Dash, the tallest avatar) checks feasibility. Must hold:
    with either barrier shut or either top stone missing `max` does not reach the key; `base` reaches it; `max` does not get past the teal lock
    (`PastPillar`) before the key. **Re-run it after moving any vault part.**
- **Vault tower** (the right half, green key; rebuilt 2026-10-28 / 29 from the user's second sketch, cut to four lanes for the avatar size rule
  §2.3 and adjusted "a bit harder" by the user). Route: from the teal lock along the floor, a switchback up four ledges, over `E_Stem`, down the
  slot to the key, a drop to the floor lane and the green lock.
  - *Shell:* `CeilingRight` h 66.25-70.25 over u 157.83-220; `RightMass`, `E_Bar` and `WallRightUpper` reach it.
  - *Tower:* four 2-thick ledges, tops **14.25 / 27.81 / 40.75 / 54**, hung alternately from `Solids.RightMass` (u 200.2-216; ledges u
    179.2-200.2, gap at the left) and from `E_Stem` (u 172.2-174.2; ledges u 174.2-195.2, gap at the right): `Block_Right2`, `Block_Right1`,
    `Column_1`, `E_ArmTop` (flush with the stem's top, so the climb ends walking left into the slot; the count must stay even). Every ledge roofs
    the lane below except at its gap. A ledge-up is a **Triple Jump** through the gap. The three lower ledges carry a **row of three spikes**
    (`Right2_13` / `Right1_12` / `Column1_19` + `b` / `c`) ending 0.6 before the gap the climb leaves by: a **jump + dash** (a single jump does not
    clear three spikes; an air jump only hits the roof). Air jumps on the way down restart the arc and also carry a player over a row (accepted:
    "Triple Jump rhythm or dash"). The top lane has only `Ceiling_21` (a hop under it dies, walking passes).
  - *Slot and key:* the slot between `E_Bar` and the stem is **10.2 wide** (4.2 and 6.2 failed: stepping off the stem carries walking speed and the
    fall pose puts the hands 2 studs ahead into the side spike); `EBarSide_22` near its top, `EBottom_18` on the slot floor `Gates.SlotHatch`
    (green, `OpensWhenHeld`: it fades with the bottom spike as soon as the key is held). Walking off holding left lands on the key; a dash in dies
    on `EBarSide_22`.
  - *Model:* `RIGHT=1` in `tools/vault_reach.py` (`PLUG=k` fills the gap of ledge k, `HATCH=open`); `bash tools/vault_right_checks.sh` (8 checks,
    about a minute): `base` gets from the doorway to the key and lands left of the bottom spike; any one plugged gap keeps `max` from the key; the
    open hatch leads to the lock zone.
- **Dash fixes found in the vault (`TalentDash`, 2026-10-29):** "on the ground" is a probe under the root, not the humanoid state (under a low roof
  the state reports Landed with the feet 2 up and cut the dash short); a box cast ahead ends the burst at a wall (the unlimited-force velocity had
  thrown the player back 14 studs), and a hit less than 60° into a wall slides along it with that share of the speed.
- **Open:** a human climb of the whole vault; the look of the empty upper back panel and the old `Decor.Tile` panels behind the tower.

### 7.13 S8.3 Rising Tide (built 2026-10-28; compacted 2026-11-05, full design check, D1-D5 options and logs `git show 87b1d3c:docs/STAGES.md`)
The World 3 finale (§3: each finale mixes its world's signatures): a **lava tide** rising under the whole course, over a run that replays every
World 3 piece (Triple ledges and crushers, ice, wind and a timed door, Long Dash gaps and an axe, a colour-hatch shaft, rolling balls and a sweeper).
Out and back: the high return leg looks down on the drowned outbound course.
- **Slot:** the south (finale) opening of the World 3 courtyard (x -165..-135, z -532..-528); the course runs south (+z) inside x -200..-40,
  z -528..-140. Coordinates: u = south of the gate line (z = -528 + u), v = east of the gate's centre (x = -150 + v), heights as world y (plaza top
  78, plate tops 78.5). Folder `Stage15`, checkpoints `1301`-`1306`, coins `Stage15_1..8`. Requires Triple Jump + Long Dash; numbers in `StageConfig`.
- **The tide (`KitTide.client.luau`, Studio part `Stage15.Tide`, tag `KitTide`):** a Neon slab (255, 85, 20) over the whole footprint, no collision;
  only its height moves, only on the running player's client (each player races their own tide). **Each checkpoint resets it** (D1 A): reaching a
  checkpoint (the gate's `TimerStart` counts as the first) and every respawn there set it to that plate's `TideFloor` (world y, attribute on the `C`
  plate), and it rises at the plate's `TideSpeed`; re-touching a plate does nothing; a plate without the attributes parks it. No run = no tide;
  finish, Home, `GateExit` and a cancelled run park it. **Kill test:** any character part below the tide's top inside the footprint dies
  (`KitKilledBy` = `Stage15.Tide`, telemetry cause `kill:Tide`); walls do not shelter. A `Rumble` sound child is supported, none is authored yet.
- **Budget rule:** at every point the tide arrives after ≥ 1.6 × a clean run's time from the checkpoint (a Bronze pace with one lost hazard cycle
  survives) and, on flat parts, ≤ 3 × (the lava must be seen coming). Values (world y / studs per s): `1301` 54.5 / 1.5, `1302` 70.5 / 1.5, `1303`
  116.5 / 1.5, `1304` 125.5 / 1.5, `1305` 130 / 2.5, `1306` 182 / 1.75. Climbs outrun the tide (the upper bound cannot hold there).
- **Course as built:**
  1. *Shore* (teach): `1301`, `Causeway1..3` (16 wide, single-jump gaps 6), `Step1`, `1302` (Double Jump ledges of 11); `LowShelf` 8 below
     `Causeway2` holds the risky coin.
  2. *Crusher ice:* `IceRidge` (kit ice, 8 wide) under `Crusher1..3` in a **press** (glass `PressWallW` / `E`, `PressRoof` 32.5 above the ice).
     Heads 12 long and contiguous (u 116-152, nothing to stand in between), Stroke 15, **cascade rhythm** (the user's): cycle 4.5 s, strikes at 2.3 /
     2.7 / 3.1 s (`Duty` 0.48889 / 0.4 / 0.31111, same Period and Phase 0), all rise together over 2.0 s; `Rod1..3` (square columns 6.2 across,
     welded on the heads, bottom sunk 0.1) fill the space up to the roof, so the only way through is **"go as they lift"** with two hop + Long
     Dashes (a window of about 0.6 s; a plain runner never makes it; moving the strikes 0.2 s later would widen it). Then Triple ledge `T1` and `1303`.
  3. *Dash run:* three 34 Long Dash gaps rising 2 each (`D1`, `D2`, `1304`; the hardest Long Dash gaps so far), `Axe` (`Swing` Hinge Z, Angle
     40, Period 3) over the third gap, pivoted 55 above the take-off (a lower pivot put the blade in every flight path).
  4. *Headwind door:* `Button` (Group `TideDoor`, 9 s) on `1304`, `WindBeam1` / `2` with a 12 gap in a gusting headwind `Wind` (Push -10, Period 3,
     Duty 0.5, **30 high**, above a maxed Triple Jump's root: the wind acts in the air, but a low zone lets a jump's apex escape it), `TideDoor` into
     the shaft (Stage 12's door, swinging toward the player).
  5. *Chimney:* a 24 x 24 shaft (glass `GlassN` to the north for the camera), `1305` on its floor, `Slab1..3` and `Roof` 15 apart, **one 6 x 6
     hatch per level** (`KitColorPlate`, Group `Chimney`, groups start red) with a `Toggle0..3` pad on the level below; `Beam1` / `Beam2` (`KitBeam`,
     Phase 0 / 0.867) across slab 2; `ChimneyGhosts`. Sign-off fixes (2026-11-07): `TideDoor` 14 high (146.5-160.5, under `Slab1`; the old 20 stuck into level 2) with `Lintel` from 160.5; `1305`'s model carries `BeamHeight` 10 (`CheckpointClient`; the 18 column pierced `Slab1_N`); `GlassN` is `SmoothPlastic` 0.5 (**Glass material does not draw transparent parts behind it**: the beams vanished seen from outside); `StampHead1..3` on `Slab3_N` (clones of `Crusher1`, 4 thick, x -77.8 / -70 / -62.2, z -198.5, Period 5, Duty 0.34, Back 1, Stroke 9.8; rest bottom 201.4, down 191.6) with a **telescope** each (a single fixed post leaves a gap: the head is 4 thick, the stroke 9.8; a thicker head filled the small room; a sleeve hanging below the raised head read as a bug): `StampPost` (fixed sleeve 3.6 wide, y 201.6-206, wholly inside the raised head; ring `StampRing`), `StampMid` (2.8, Stroke 3.8) and `StampInner` (2.0, Stroke 7.0), each y 201.6-206.4 at rest, own `KitMover` Pistons (same Period / Duty / Back / Out / Phase as the head, Telegraph 0, Kill false) with welded rings; the inner section reaches 1.0 into the lowered head. Nothing shows below the raised head; in a playtest the overlaps stay >= 1.0 (middle in sleeve), 1.6 (inner in middle), 1.0 (inner in head) through the whole cycle; `StampCollar` under the ceiling; the posts leave 4.4 wide lanes) a full-width ceiling stamper between the hatch and `Toggle3`, crossed twice (safe window about 2 s, a crossing takes 0.75 s). Pillars, walls and slabs are all `Plastic` + `Studs`.
  6. *Summit:* `1306` on the roof, `Ramp` (9.9 wide, Stage 13's slope) with `Ball1..4` and `Pocket1..3`, `SweepPad` between glass walls under
     `Sweeper` (Speed -45, the lower arm moving with the walker; since 2026-11-07 a charcoal `Studs` paddle with Neon orange stripes, steel rails and hub, tip glows), a 34 gap (drop 4) to `Crag` with the portal facing north; `TalentPillar` 25.5
     above the roof.
- **Open:** a human run and the real `tBase`; maxed-talent shortcuts in segments 3-6 (a maxed Triple Jump rises 27, the sweeper's top is 22.5
  above its pad); the rumble sound asset; the camera inside the shaft.

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
| World themes and names (sky, factory, storm, summit…)? | open; the style is stud (decided 2026-11-05: voxel / pixel-art previews dropped) |
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
