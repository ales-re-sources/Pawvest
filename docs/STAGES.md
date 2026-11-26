# Pawvest — Stage building reference

The 15 stages of Worlds 1–3 and the Tutorial are built. World 4 (stages 16–20) and the bonus stages are ideas (§5.3–5.5, §8). This doc holds
what stage design rests on: measured movement reach (§1), the obstacle component catalogue, build rules, kit architecture and look (§2),
design patterns (§3), the stage list and difficulty curve (§4), special stages (§5), skill requirements (§6), hub / world layout facts and
per-stage as-built notes (§7), and the build gotchas (end). Names, times, prices and unlock bars live in `StageConfig` (the source of truth);
the game design is GDD §3–5; scene anatomy and the procedure for a new stage are in [LAYOUT.md](LAYOUT.md) ("Adding a world stage").

## 1. Movement and reach
Place settings: `CharacterUseJumpPower`, JumpPower 50, WalkSpeed 16, gravity 196.2, MaxSlopeAngle 89, `StreamingEnabled` off (the kit stays
streaming-ready, §2.4).

**In short:** a single jump rises about 6.4-7.3 studs and carries about 8 studs flat at WalkSpeed 16 (10.6 with Run Speed 5; with the
character's own length the longest gap is 11-12); Double Jump rises about 14.5. Only the air-jump and dash talents separate "can" from
"cannot" with a clear margin; Run Speed and Jump Height differ by 1-2 studs or 5 % per level, too little for a fair hard gate (§6.1).

**Lip rule (Stage 5):** a landing plate that overhangs its column by 1 stud on the approach side lets a character who arrives just short of the
edge, holding forward, grab it and climb (Humanoid `Climbing`); a column flush with its plate is a wall and the same jump slides down. **Use a
lip wherever a jump is meant to be "very hard but doable" at the edge of reach.**

### 1.0 Measured reach table
Measured in a Studio playtest on a flat runway: the character runs at full speed, jumps once at the same height and lands level; extra
jumps are timed at the apex. Values are root-part positions in studs: **flat reach** = take-off to landing, **rise** = highest point above the
take-off. A crossable gap between two platforms is the flat reach minus about 1-2 studs (the root stands slightly inside each edge).

| Run Speed | Jump Height | Single jump: reach / rise | Double Jump (1 air jump): reach / rise | Triple Jump (2 air jumps): reach / rise |
|---|---|---|---|---|
| 0 (16.0) | 0 (power 50) | 8.3 / 7.3 | 14.7 / 14.5 | 20.5 / 22.0 |
| 0 (16.0) | 3 (power 55.7) | 9.5 / 9.0 | 16.4 / 18.0 | 22.5 / 27.0 |
| 3 (18.9) | 0 | 9.9 / 7.3 | 17.4 / 14.7 | 24.4 / 22.0 |
| 3 (18.9) | 3 | 11.3 / 9.0 | 19.5 / 18.0 | 26.7 / 27.0 |
| 5 (20.8) | 0 | 11.0 / 7.3 | 19.3 / 14.5 | 27.0 / 22.0 |
| 5 (20.8) | 3 | 12.5 / 9.0 | 21.6 / 18.0 | 29.8 / 27.0 |

A single jump (rise 7.3-9.0) is cleanly separated from Double Jump (14.5-18.0): a "needs Double Jump" ledge of 10+ studs or gap of 14+ is a
real gate. Triple Jump adds about 6 studs of reach and 7.5 of rise. Run Speed 5 gives +2.7 studs of single-jump reach, Jump Height 3 +1.7 of rise.

**With the real talents** (bot runs, every jump and the dash at the apex). The dash measured 10.00 studs in 0.200 s at constant height (once
per air time, none on the ground); a dash at the apex adds 10-11 studs to any jump, a later one slightly more (it stops the fall for 0.2 s).

| Run Speed | Single | + Dash | Double Jump | DJ + Dash | Triple Jump | TJ + Dash |
|---|---|---|---|---|---|---|
| 0 (16.0) | 8.8 / 7.3 | 18.8 | 15.2 / 14.5 | 25.4 | 21.1 / 21.8 | 32.1 |
| 5 (20.8) | 11.4 / 7.3 | 22.3 | 19.8 / 14.5 | 30.1 | 27.4 / 21.8 | 37.7 |

**Long Dash** (Dash level 2, 0.32 s at 50 studs/s = 16 studs), dash at the apex:

| Run Speed / Jump Height | Single + Long Dash | DJ + Long Dash | Triple Jump | TJ + Dash | TJ + Long Dash |
|---|---|---|---|---|---|
| 0 / 0 | 25.3 | 31.6 | 20.6 | 31.7 | 37.5 |
| 5 / 3 | 29.0 | 38.3 | 29.8 | 40.8 | 46.5 |

Real gaps (edge to edge, level landing): baseline TJ + Long Dash crosses 36; baseline TJ + Dash and a maxed Triple Jump without Dash fail
at 32; baseline DJ + Long Dash fails at 33. **A Dash gate is a flat gap of 34** (2+ studs of margin both ways). A maxed Triple Jump with the
short Dash (40.8) also crosses it: Run Speed + Jump Height stand in for Long Dash, a soft-talent shortcut that is welcome (user decision:
shortcuts give replay value).

**Low ceilings do not gate air jumps:** under a solid ceiling 7-9 studs above the floor, a Triple Jump that lets the character drop 2-3 studs
below the take-off height before each air jump hovers on: it crossed 14-18 studs under an 8-stud ceiling. A kill ceiling leaks the same way
and its margin depends on the avatar's height. Ceilings stay decoration or soft gaps.

**Avatar size rule (design for every avatar, players keep their bodies).** An R15 character collides only with its `HumanoidRootPart` and
torso (head, limbs and accessories never collide), so a roof stops it at the root's top = HipHeight + root height. Measured on rigs from
`HumanoidDescription`s with the standard body parts:

| Avatar | HipHeight | Collider top | Head top |
|---|---|---|---|
| classic, height 0.9 | 1.80 | **3.6** | 4.9 |
| classic, height 1.0 | 2.00 | 4.0 | 5.2 |
| classic, height 1.05 | 2.10 | 4.2 | 5.3 |
| Rthro body type 1, height 1.05 | 3.10 | **5.2** | 6.3 |
| Rthro body type 1, proportions 1, height 1.05 | 2.77 | 4.9 | 6.0 |

Body scale does not even them out; only forcing standard parts would, and that changes how players look, so stages are designed for the spread.
Bundles with their own body meshes were not measured. Rules:
- **Collider: plan for 3.6-5.2.** A gap to walk under is **at least 6** (everyone fits) or **at most 3.4** (nobody does), never in between.
- **Jump headroom** under a roof is counted for the 5.2 collider. **In a jump the head counts too**: an unhindered single jump (rise 7.3) needs
  about **14** of roof height for the tallest avatar (7.3 + 6.6), 12.2 for a classic one (a roof throws the character down). A spike to be
  hopped under a roof gets a lane of at least 14; lower lanes only take spikes meant for a jump + dash.
- **Accessories never kill (user decision):** the kit's hazard test (kill parts, beams, kill movers) checks only the character's own body
  parts (BasePart children; accessories and held tools are left out). The head still counts.
- **No kills through solid parts:** head and limbs do not collide, so in a jump they pass into a thin slab and could reach a spike standing on
  it. A touch counts only when a ray from the root to the nearest point of the hazard (stopping 0.15 short) meets no CanCollide part, ignoring
  the character and the hazard's own model. The ray runs only when the overlap test already found a touch.
- **Kill parts above a walkway: at least 7.5** over its floor (head 6.3 plus a margin).
- Decor that can be walked into (tree crowns, sign boards) is either above 6 or reaches the ground.
- Known spots left in the band: the key notch in Stage 14's `E_Bar` (4.5 over `SlotHatch`; the key's `Hit` reaches 0.4 into the slot, unverified
  for a 5.2 avatar); Stage 15's `Chimney.Lintel` (5.0 over `Slab1_N`: small avatars slip out of the shaft back to where they came from, harmless).

## 2. Component catalogue

### 2.1 Build techniques
| Code | Technique | Use for | Risks |
|---|---|---|---|
| **S** | **Static**: anchored parts + an existing script or tag (kill, bounce) | gaps, pillars, beams, walls, kill parts | none; cheapest |
| **F** | **Surface**: anchored part with `AssemblyLinearVelocity` / `AssemblyAngularVelocity` (conveyor, rolling log) or `CustomPhysicalProperties` | conveyors, ice, slow floors | replicates natively; tune friction on mobile |
| **T** | **Kit-timed**: tagged parts animated on **every client** from `workspace:GetServerTimeNow()` and attributes (`Period`, `Phase`, `Duty`, `Amplitude`, `Axis`…). Every player sees the same phase; the server never moves them | blinking beams, movers, rotators, pistons, pendulums, sweepers | the client must carry the character on moving parts (§2.4); kills from these are detected on the client |
| **L** | **Kit-local**: state per player, simulated only on that player's client | tilt plates, crumbling plates, colour switches, pressure doors | other players see the part at rest (they seem to float); accepted, nobody can grief your plate |
| **Z** | **Zone**: the client applies a force or velocity while its character is inside a region | wind, fans, low gravity, updrafts | keep forces moderate (no flings); stop the force at once on death / respawn |
| **P** | **Physics**: unanchored parts with constraints | cosmetic motion, knock-back balls | **avoid for anything a player stands on** (network ownership jumps between nearby players) |

New movers use **T**; do not move parts from a server `while wait()` loop (the CFrame replicates every frame to every client).

### 2.2 Components
Skill tested: **Tim** timing, **Pre** precision, **Rou** routing, **Ner** nerve, **Spd** speed. Gate: which talent the component can *require*
(hard) or only *reward* (soft: faster medal, shortcut).

**Static and surface**
| Component | How it works | Tests | Gate | Build |
|---|---|---|---|---|
| Gap jumps | plain, diagonal, up / down jumps between platforms | Pre | hard: DJ / Triple / Dash by gap width | S |
| Stud pillars | small tops (3×3 → 1×1), often staggered | Pre, Ner | soft | S |
| Tightrope / thin beam | 1-stud beam walk, straight or zig-zag | Pre, Ner | – | S |
| Wrap-around | ledges around a wall corner | Pre | – | S |
| Low ceiling | ceiling over a gap allows only a flat jump | Pre | does not stop air jumps (§1.0) | S |
| Kill parts / lava floor | touch = death | Pre | – | S |
| Truss / ladder | climbing sections, also with hazards beside | Tim | – | S |
| Choice stage | several identical steps, one random one is solid | Ner, luck | – | S |
| Maze | walls hide the route; dead ends | Rou | DJ to see over walls (soft) | S |
| Invisible / ghost path | path faint or visible only nearby | Rou, Ner | – | S + client fade |
| Ice | very low friction, momentum carries you | Pre, Spd | soft (Run Speed) | F |
| Conveyor | floor pushes along / against / across the route | Tim, Pre | soft | F |
| Rolling log | cylinder spins under your feet | Pre, Tim | – | F |
| Mud / slow floor | WalkSpeed lowered while on it | Spd | soft (Run Speed) | F / Z |
| Bounce bricks / jump pads | fixed launch along the brick's front | Tim, Pre | – | S (client script) |
| Speed strip | short boost along the route | Spd | – | Z |

**Timed and moving** (kit-timed unless noted)
| Component | How it works | Tests | Gate | Build |
|---|---|---|---|---|
| **Blinking beams** | laser bars switch on and off; on = death. A thin translucent beam and a hum **telegraph** 0.4 s before "on"; rows with phase offsets make waves | Tim | – | T |
| Sweeping laser | a beam rotates or slides across a platform | Tim | – | T |
| Spinners / sweepers | rotating kill bars at foot or head height | Tim | – | T |
| Moving platforms | ping-pong or loop paths | Tim, Pre | – | T + carry |
| Elevators | platforms that rise and fall | Tim | – | T + carry |
| **Rotating plates** | (a) turntable around Y you ride; (b) flipper: flips 180° on a timer, you must leave before; (c) windmill blades you jump between | Tim, Pre | DJ to skip blades (soft) | T + carry |
| Disappearing plates | plates fade out and back on a fixed cycle (same for everyone) | Tim | DJ to save a late jump | T |
| Pistons / pushers | blocks punch out of walls or floors and push you off | Tim | – | T |
| Crushers | ceiling blocks slam down; under them = death | Tim, Ner | – | T |
| Pendulums / swinging axes | swing across the path | Tim | – | T |
| Rolling balls | balls roll down a ramp toward you (`KitMover Kind = "Roll"`, no physics) | Tim | – | T |
| Rising lava / tide | kill plane rises from the run's start; you race it | Spd, Ner | soft (Run Speed) | L |

**Per-player state** (kit-local)
| Component | How it works | Tests | Gate | Build |
|---|---|---|---|---|
| **Tilt plates** | plate on a fixed hinge axis; it tilts toward where you stand, a spring pulls it back; past the slope limit you slide off | Pre, Ner | DJ to recover from a slide | L |
| Balance board | two-axis tilt plate (idea) | Pre, Ner | – | L |
| Crumbling plates | start shaking when you land, fall after N s, return after M s (only for you) | Spd, Ner | – | L |
| Colour switches | step on a button: red plates turn solid, blue ones ghost (only for you) | Rou, Tim | – | L |
| Pressure door / timed door | a button opens a door for N s; sprint through | Spd | soft (Run Speed; not a hard gate, §6.1) | L |

**Zones**
| Component | How it works | Tests | Gate | Build |
|---|---|---|---|---|
| Wind / fans | constant push across the path, steady or gusting | Pre | – | Z |
| Updraft | vertical push up a shaft | Tim | Glide rides it (World 4 idea) | Z |
| Low gravity | lower gravity inside the zone | Pre | – | Z |

**Talent-gated geometry**
| Component | How it works | Gate | Build |
|---|---|---|---|
| DJ gaps / ledges | gaps and ledges beyond a single jump | hard: Double Jump | S |
| Triple towers | ledges beyond a Double Jump | hard: Triple Jump | S |
| Dash gaps | flat gaps beyond run + jumps | hard: Long Dash (34 studs, §1.0) | S |
| Wall-jump shafts, Glide canyons | World 4 ideas (§8) | hard: Wall Jump / Glide | S (+ Z) |
| Talent shortcuts | an optional faster route needing a talent the stage doesn't require | soft (Gold route) | S |

### 2.3 Fairness rules for every component
- **What you see is what kills you**: timed hazards are drawn and checked on the same client from server time.
- Every timed hazard has a **telegraph** (colour, sound or motion) and a **safe spot** in front of it.
- **No blind jumps**: the landing is visible from the take-off point.
- Moving parts never push a player into a kill part without a chance to react (≥ 0.5 s).
- Timers on one stage share a **base period** (multiples of 1 s), so waits are short and learnable.

### 2.3.1 Moving parts vs frame (build rules)
A part that moves (door, lift, piston, flipper) must never lie in the same plane as a face of the static geometry around it while facing the
same way: the two textures flicker (z-fighting). A 2-stud door in a 2-stud frame shares all four side planes with the lintel the moment it slides up.
- **Make the moving part thinner than its frame** (door 1 stud in a 2-stud frame, a lift 0.2 narrower than its shaft), never flush with a
  neighbour in any direction it travels; never slide a door *into* the lintel, swing it (`OpenTurn` + `OpenHinge`, ObstacleKit header) or let it
  drop into a slot that is wider than itself.
- Faces that touch but point opposite ways (a door resting on its sill) are fine.
- Frame walls go down to the sea / the ground, not just under the plates: a player who falls beside the course can jump into any gap below a
  floating wall and reach the part behind it.
- **Check before you finish a door:** run `tools/kit_coplanar_audit.luau` through the Studio MCP `execute_luau` (Edit). It walks every `KitDoor`
  from closed to open and lists each coplanar, same-facing, overlapping face; it must say "clean" for the stage you touched. Known unreviewed
  hits: `Stage9.Maze.Big.ExitDoor` vs the posts / floor, `Stage10.Movers.Door_10` vs `Tower.Core`.
- **Static parts z-fight too:** parts that overlap must not share a face plane (end floors, ceilings and walls at a back panel's inner face;
  walls under, not through, a ceiling; a beam starts on its emitter). Set `STATIC_ROOT` in the audit (e.g. `"World3.Stage14"`) to check a
  whole stage's static parts; hidden zones are skipped. Known: the gate and finish-arch clones every stage shares have overlapping arch stones.

### 2.4 Kit architecture
- One client module (`ObstacleKit`) drives every tagged part through `CollectionService` (`BlinkBeam`, `Mover`, `Rotator`, `TiltPlate`,
  `Crumble`, `ColourSwitch`, `Piston`, `Pendulum`, `WindZone`, …), configured by attributes on the Studio parts. No script copies per part.
- **Carry**: when the character stands on a kit mover (downward raycast from the root), the client applies the mover's frame delta (move +
  rotation around the axis); a short air-carry (0.5 s) after jumping off. Other players see riders about 0.2 s behind a moving platform.
  Tilt plates need an explicit slide-off (freefall + downhill velocity) because `MaxSlopeAngle` is 89.
- **Client kill** for kit hazards: the client sets its own `Humanoid.Health = 0`. It cannot be used to cheat (skipping a death is possible with
  exploits anyway, and times stay server-measured).
- **Streaming-ready**: tags are handled through added / removed signals. **Cost**: animate only parts within about 300 studs of the camera;
  the server animates nothing (100 movers cost 0.34 ms per frame).
- Templates live in `ServerStorage.StageKit.Obstacles` (Studio-only), next to `LandingPad` and `Checkpoint`.
- **Colour language:** red = kills, yellow / gold = movers and pushers, blue = tilt plates, teal = disappearing / flip plates, green = switches and
  checkpoints, pastel violet = low gravity, **pink (`#FF46B4`) = bounce** (stud trampolines, the key-arena orb). A new component takes a
  colour not on this list.

### 2.5 Look language of kit parts (Studio-only)
Every stage uses the stud look (`Plastic` + a `MaterialService.StudPack` variant). Decoration is always a child of the kit part, unanchored, Massless, CanCollide / CanTouch / CanQuery / CastShadow off,
`WeldConstraint` to the part (so it follows the kit's CFrame), and never shares a face plane with it (rims 0.03 in from the edge, frames wholly in front of the face). **Build a new piece by cloning a
restyled one** (`ServerStorage.StageKit.Obstacles` templates, or e.g. `Stage14.Vault.Spikes.Right2_13` for a spike); a resized part needs its decoration redone.
- **Colours mean things:** red / orange = kills you, so no pad or safe part is ever red. Translucency means "not solid" (ghost plates 0.85, ghost steps 0.75), so solid parts are opaque.
- **Solid hazards** (crushers, spikes, blades): charcoal `Studs` body with glowing Neon cracks / ridge (`#FF5913` spike tips), a Neon `BottomGlow`, black smoke on crushers. The telegraph tints the body to
  `WarnColor` (255, 170, 60). **Lava floors:** the kill part in dark red `Studs` covered by `LavaTile_n` children (2 x 4, dark red / red / orange, ~1 in 5 Neon) and a `LavaSmoke` emitter on large parts
  (low rates for phones). **Hot coals** (Stage 2's `Lava block`: 20 damage every 0.5 s, not a kill) look different on purpose: charcoal `Studs` tiles with dim burnt-orange ones, no Neon.
- **Moving plates** (`KitMover`): LEGO yellow `#FFD54A` `Studs` with amber rim bars `RimN/S/W/E`, an amber `Hub` on discs. A gear is one union that *is* the mover (the kit carries a rider only on the
  exact `KitMover` part). Flips: `Axle` bar with `AxleCapE/W` through the hinge, rims on both faces; clone `Stage10.Movers.Flip_1`.
- **Conveyors** (`KitConveyor`): a charcoal `(44, 44, 52)` `Studs` belt slab (1-1.2 thick), stone grey `Roller1/2` cylinders across both ends (none where another part touches within 0.5) and amber
  `#E29314` chevrons (`Chevron<n>L/R`) pointing the way the belt pushes; over the sea the belt stands on its own stud pillar (`ConveyorBase<n>`). `KitConveyorsClient` slides the chevrons at `Speed`;
  space them evenly. Template `StageKit.Obstacles.Conveyor_Belt`.
- **Tilt plates** (`KitTilt`): green `(58, 165, 92)` `Studs`, dark green rims, a charcoal hinge pin on the tilt axis. **Disappearing plates** (`KitPlate`): opaque `(0.75, 0.67, 0.55)` `Studs`, no
  decoration (the flicker is the cue). **Crumbling plates** (`KitCrumble`): sandstone `(222, 170, 100)` `Studs` with dark brown `Crack_n` lines; the kit fades a plate's decoration with it.
- **Ice** (`KitIce`): smooth `Plastic` `(0.70, 0.87, 0.98)` with a glass `Cap`, white `Studs` rims and collars (smooth = slippery, studs = grip); no rim where another part touches within 0.5.
- **Buttons and switches** (`KitButton` / `KitSwitch`): azure `(0.0, 0.6, 0.86)` `Studs` plates 0.6 above the floor on a charcoal `Base` slab; a pad over a gap is a charcoal housing with an azure `Cap`
  (a hit on the `Cap` counts as the part; tinted green when pressed). `ReplicatedStorage.SwitchSound` clicks.
- **Pistons / rods / roofs:** stone grey `#A3A2A5` `Studs` with yellow `Inlets` bands and charcoal collars; press roofs charcoal with yellow bands. Pendulums brass with a charcoal hub; clock hands charcoal
  with red Neon edges. **Keys and key gates** (Stage 14): stud bricks in the key colour with a charcoal outline and a `PointLight`; teal is **mint** `(100, 255, 190)` (cyan sat too close to the azure
  buttons); key gates opaque mint / green `Studs` with a charcoal frame and keyhole. **Lab back panels:** LEGO sand blue `(112, 129, 154)` `Studs` with darker `Inlets` tiles.

## 3. Combination patterns
- **One signature per stage.** Each stage introduces or develops **one** headline component; no component is the signature of two stages.
- **Teach → test → twist → finale.** First a safe version (no kill, or a floor under it), then with a hazard, then combined with an earlier
  component, and the last section before the finish fast and combined.
- **Rest and stress.** A short, safe rest strip after every hard section; a checkpoint every 10–15 s of play in World 1, 15–20 s in World 2,
  20–30 s in World 3, never more than 40 s (Stage 5, about 30 s, is close to the limit on purpose).
- **Sawtooth curve.** Each world's first stage is easier in precision than the previous finale but teaches the world's new talent; each world
  finale mixes every signature of its world.
- **Gold route.** Stages have 1–2 optional risky shortcuts worth 3–8 s, so Gold is about route and nerve, not only speed.
- **Good pairings:** blinking beams + moving platforms (two clocks with one base period); tilt plates + wind; turntable + sweepers; conveyors +
  gaps; ice + timed doors; crumbling + disappearing plates; colour switches + maze; low gravity + beams; rising tide + anything.
- **Avoid:** two timers with unrelated periods (random waits); invisible path + kill floor without hints; tilt plate + a kill part right at its
  edge; knock-back into a kill part with no recovery.
- **Revisit hook.** Talent-tier challenge coins need a talent from a *later* world, so finished stages are worth replaying after each new talent.

## 4. Stage list and difficulty curve
Display number = position in the game (`order`, `displayName` in `StageConfig`); the **key and folder** never change (§7.4). `tBase` = a clean
run with exactly the required talents (set from the developers' runs: Gold ≈ 0.8 × tBase; medal multiples and rewards in `StageConfig`, GDD §4).
Reward factor = `0.5 + 0.25 × order` (Tutorial 0.5).

| # | World | Name | Signature | Other components | Requires | `tBase` (s) |
|---|---|---|---|---|---|---|
| T | – | Tutorial (hub stage) | basics | jumps, first kill part | – | 30 |
| 1 | 1 | Island Hop | stud pillars over the sea | conveyors, one slide mover | – | 52 |
| 2 | 1 | the variety stage | variety | laser strips, spinners, lava floor, choice stage, jump pads | – | 70 |
| 3 | 1 | bounce corridors | bounce corridors | kill-part corridors, bounce bricks | – | 100 |
| 4 | 1 | Blink ★ | **blinking beams** to a metronome | disappearing plates, beam waves, pistons | – | 60 |
| 5 | 1 | the precision finale | max-distance jumps | wrap-around, tightrope | – | 120 |
| 6 | 2 | Double Up | Double Jump gaps and ledges | lifts, slide movers | Double Jump | 90 |
| 7 | 2 | Seesaw | **tilt plates** | wind, crumbling plates | Double Jump | 80 |
| 8 | 2 | Turntable | **rotating plates** | sweepers, flippers, windmills | Double Jump | 75 |
| 9 | 2 | Labyrinth ★ | **shifting iso maze** | guards, lava tiles, switch + door | Double Jump | 100 |
| 10 | 2 | Clocktower (finale) | one 1 s clock tick | tower climb, doors, pistons, gargoyles | Double Jump | 75 |
| 11 | 3 | Triple Peaks | Triple Jump ledges | lift, crusher ridge | Triple Jump | 55 |
| 12 | 3 | Ice Rink | ice | crosswind, timed door | Triple Jump | 50 |
| 13 | 3 | Dash Bridge | Long Dash gaps | axes, rolling balls | Triple Jump, Long Dash | 45 |
| 14 | 3 | Laser Lab ★ | **side-view platformer**, Key Vault | laser grid, sweepers, colour shaft | Triple Jump, Long Dash | 95 |
| 15 | 3 | Rising Tide (finale) | lava tide | everything from World 3 | Triple Jump, Long Dash | 55 |

★ = the world's special stage (§5). Every run stays within GDD pillar 1 (1–3 minutes). Run Speed and Jump Height never become requirements; they
stay the way to faster medals and shortcuts. Bronze means "finishable by any player who owns the required talents". Stages 16–20: §8.

## 5. Special and bonus stages
**One special stage per world** (★ in §4) plays differently from a normal obby. Bonus stages (§5.3) are unbuilt.

### 5.1 Shared pieces (part of the kit)
- **`StageCamera`** (client): camera modes `Default`, `Iso`, `Side`, `Down`, `Front`, switched by a zone or a stage attribute `CameraMode`; back to
  `Default` on death, Home, the return portal and the finish. Roblox has no orthographic camera: a far camera (about 150 studs) with a narrow
  field of view (about 20°) looks almost isometric. A fixed camera yaw keeps the controls natural ("W = up the screen"), also on mobile. Zoom and
  shift-lock are off in these modes.
- **Run-seeded schedules**: a per-player obstacle cycle that starts when that player's timer starts, so every run sees exactly the same
  sequence (fair Top-10, learnable Gold). The kit-local (L) components use it.
- **Ghost others** (`KitGhosts`): where every player sees their own state (maze walls, colour switches), other players are drawn translucent.

### 5.2 World specials
**World 1 — Blink (Stage 4): rhythm stage.** Blinking beams, disappearing plates and pistons switch on the beat of the stage music (as built: §7.7).
**The beat is per run, not shared:** every hazard is run-seeded and the music starts with the player's timer and follows run time, so every run
sees the same sequence; the course still works if the sound fails to load. Beams telegraph on the off-beat; most hazards switch on bars 2 and 4.

**World 2 — Labyrinth (Stage 9): isometric shifting maze** (as built: §7.9).
- Seen from above with the `Iso` camera; walls on the cell edges; **no way on top:** an invisible ceiling at the walls' top height (plus fence
  slabs outside) covers the maze and holds against every talent; the camera looks through it.
- **The view shows everything** (no fog): the challenge is reacting to the change. A rising wall shows a glowing line on the floor before it
  rises, a sinking one flashes; a wall rising where a player stands pushes them aside.
- **Always solvable:** a fixed cycle of generated layouts, each a connected tree.
- **Run-seeded** (§5.1); other players are ghosts. A torchlight variant (only nearby cells lit) stays an idea for a bonus stage.

**World 3 — Laser Lab (Stage 14): 2D side-scroller** (as built: §7.12).
- `Side` camera zones perpendicular to the course, following along it; the character runs in a lane between invisible walls. Triple Jump and Dash
  read perfectly in 2D.
- The Key Vault (room 1) began as the standalone prototype `Workspace.KeyArena` from the user's 2D drawing (1 drawing unit = 4 studs): an isolated
  room with a teal and a green key, force-field gates, spikes and an exit door. Its scripts live on: `ArenaConfig` (names, tags, attributes),
  `ArenaServer` (spikes, checkpoints, keys, locks, exit; everything found by tag, no per-part scripts) and `ArenaClient` (local key / gate
  state, key HUD, toasts). Keys and opened gates are per player, persist through deaths and reset at a new run; an opened gate is fully
  invisible and non-solid for that player. Picking up a key can open a gate at once (key attribute `OpensGate`).

**World 4 — Glide Canyon (Stage 17): dropper** (idea, §8).

### 5.3 Bonus stages (ideas)
| Bonus stage | What it is | New piece | Effort |
|---|---|---|---|
| Stealth | guards with sweeping spotlight cones; seen = back to the checkpoint | guard component (cone check on the client) | 1.5× |
| Darkness | lights off, only a small light around you and beacons on the route | lighting for that player only | 1× |
| Memory path | a glowing path flashes for 2 s, then you walk it from memory | run-seeded random path per run (a fixed one would be memorised for the Top-10) | 1× |
| Chase | a boulder or wave rolls after you; the `Front` camera faces you | `Front` camera, kill wall started by the run | 1.5× |
| Giant room | you are tiny in a huge kitchen or desk: cups, pencils, a fan | props only | 1× |
| Minecart | ride a cart on rails, jump gaps, duck under beams | client-driven cart | 2× |

Rules (proposal): **outside the unlock chain** (no medal bar, no price; opens when its world opens; never needed for a world gate); reward factor
1.0, medals, a Top-10 board and challenge coins like any stage, stars counted in the total (+3 each); 2 bonus portals per world island from
World 2 on, beside the 5 stage portals (the World 2 plaza reserves the slots). Cheapest first: Darkness and Memory path; Minecart last. The farm
stages (EXPANSION §8.2) may use this slot.

### 5.4 Idea: personal-best ghost
A translucent replay of your own best run on any stage. The client records the character's position about 10 times a second; the best run's
track is stored in its own DataStore (about 10–30 KB per stage and player). Unscheduled.

### 5.5 Idea: branching appearing steps
A stage built on `KitStep` (a block is solid only once the player stood on the previous one of its group): stepping on one block makes two
appear, the player picks the right one, the other is a dead end. Tried in the vault's green-key half and taken out (the user did not like it
there). `KitStep` would need an `After` attribute naming the block(s) it follows instead of the plain `Step` order. Unscheduled.

## 6. Skill requirements

### 6.1 What can be a hard gate
| Talent | Hard gate? | Why |
|---|---|---|
| Double Jump | **yes** | rise 14.5 vs 7.3-9.0 for any single jump (§1.0) |
| Triple Jump | **yes** | rise 21.8 vs at most 18.0 for a maxed Double Jump |
| Dash / Long Dash | **yes** (Long Dash) | a flat gap of 34 (§1.0) |
| Glide, Wall Jump | would be (World 4 ideas, §8) | a descent / shaft nothing else crosses |
| Run Speed | no, soft | 5 % per level: a door that "needs Run Speed 3" would come down to tenths of a second |
| Jump Height | no, soft | 1–2 studs between levels; the humanoid's ledge catch blurs it further |

### 6.2 Talents
Built (`TalentConfig`; prices and crop bundles there and in GDD §6; ids never renamed; all movement talents are client-driven, the level is
server-owned as `Talent_<id>`; level changes in GDD §6):
| Talent | Id | Effect | First required |
|---|---|---|---|
| Double Jump | `DoubleJump` 1 | 1 air jump; a world reward (granted when World 2 opens, never sold) | Stage 6 |
| Triple Jump | `DoubleJump` 2 | 2 air jumps (`TalentConfig.AirJumps` scales with the level); the row renames itself (`names`) | Stage 11 |
| Dash | `Dash` 1 | in the air, a flat burst, once per air time (§7.10) | – (Long Dash is the gate) |
| Long Dash | `Dash` 2 | the burst lasts 0.32 s (about 16 studs) | Stage 13 |
| Quick Respawn | `QuickRespawn` | faster respawn, fall reset (§6.2.1); a utility, never required | – |
| Run Speed (5 levels), Jump Height (3 levels) | `RunSpeed`, `JumpHeight` | soft | – |

Ideas (not built; World 4):
| Talent | Id | Effect | Controls |
|---|---|---|---|
| Wall Jump | `WallJump` | in the air against a wall: jump kicks up and away from it; does not refill air jumps | jump near a wall |
| Glide | `Glide` | hold jump while falling: fall speed capped at about 8 studs/s, run speed kept | hold jump |

Wall Jump needs the most tuning (wall detection, camera, mobile), which is why it comes last. A talent requirement is shown as hint +
warning, never enforced (§6.3).

### 6.2.1 Quick Respawn
Not a movement talent and never a requirement: it saves the waiting after a mistake. Level 1: respawn at the checkpoint after **1 s** instead of
the place's `Players.RespawnTime` (3 s, set in Studio); level 2: **instant** respawn plus a **fall reset**.
- **Death → respawn** (server, `RespawnService`): on `Humanoid.Died` the server calls `LoadCharacter` after the player's delay. Every kill source
  (kill scripts, the sea, kit client kills) ends in `Died`, so one place handles them all. `Players.CharacterAutoLoads = false`; calling
  `LoadCharacter` with auto-load on can respawn twice. The service places the character on its stored checkpoint only after `LoadCharacter`
  returns (`CharacterAdded` fires too early and Roblox can overwrite the placement with the default spawn). The join spawn and the Home button
  must keep working through it.
- **Fall reset** (client, level 2, `QuickRespawnClient`): the client knows its current checkpoint (`CheckpointReached`); when the character is
  falling and more than `fallResetDepth` studs (the stage folder's attribute `FallResetDepth`, default 30, 0 = off; never lower than 5 studs
  above the sea / `DebugBaseplate`; plates more than 300 studs away are ignored, e.g. after Home) below that plate, it moves itself onto the
  plate facing its front (same placement as a respawn). The stage's kit-local obstacles reset as on a respawn. It forgets the plate when a run
  ends or the character moves more than 40 studs in a frame (finish, Home, gates). Off on the dropper idea (falling is the course).
- The stage timer keeps running in both cases. **Fair for the boards:** a clean Gold run has no deaths; Gold is never designed around the talent.

### 6.3 How a requirement is shown (hint + warning, entry open)
`StageConfig.requires = { { id = "DoubleJump", level = 1 }, … }`. The **portal / gate face** shows a line "Needs: Double Jump" (green when owned,
red when not); a player **arriving** without a required talent sees a short popup with a button that opens the Skills panel and can still play.
Course geometry is the real gate (no server check).

## 7. Practical side

### 7.1 Hub and worlds
- **Central Island** keeps the Tutorial portal and has **one world gate per world** (larger stud portals cloned from `ServerStorage.DecorKit.StudPortal`, `GateWorld1..4`, on a circle of radius about 44
  round the plaza centre at 90 / 60 / 30 / 0 degrees for Worlds 1 / 2 / 3 / 4, facing the plaza; the Tutorial at 142 degrees). The hub has no stage portals except the Tutorial.
- **A world is a compact rectangular courtyard whose gates lead directly into the stages**; nobody is teleported into a stage. World 1: x -430..-320 (110 wide), z 187..357, top y 78, low wall (6 high).
  The entrance (`ReturnGate` to the hub; the hub gate lands on the `Spawn` pad) is in the south short side; the finale gate in the north short side; two gates on each long side, near (z 302) and far
  (z 242). Slots: Stage 1 = west near, Stage 2 = west far, Stage 3 = east far, Stage 4 (Blink) = east near, Stage 5 = far end. Side courses run outward. World 2 §7.8, World 3 §7.10. The Tutorial
  counts in no world (World 1 = 15 stars) and keeps its own old-style pad and hub portal. Courtyards also hold a `WorldSign` and `LaneDividers` (glass panes that stop players hopping between
  neighbouring lanes or walking along the wall tops).
- **The world gate shows progress** (face): stars x / 15, challenge coins found x / y, and its lock (requirement + price, §7.2). **A world's gate is shut until one of its stages is open** for the
  player (local barrier; the server refuses the teleport; `HubGateLocks`): World 1 opens with Bronze on the Tutorial or by buying Stage 1 (200, low on purpose); Worlds 2–4 open with their first stage (§7.2).
- **Stage gates:** a stud gate (two pillars, beams, sign) with a wooden **door** that stays shut for a player while the stage is locked (stars / coins / lock lines on it; a prompt "Unlock · N Coins" buys
  the stage: `GateDoors`, `GatePrompts`); once unlocked the door is a faint ghost. **Walking through starts the stage and the timer at once** (`TimerStart`, a 21 x 16 x 4 box at the doorway; the server checks
  the unlock); walking back out cancels the run (`GateExit`). **Getting around a gate stays possible** (over the wall, around a locked door): the timer does not start, finish rewards and times do not
  count, Coins do, and the first checkpoint reached without a timer shows the banner "Exploring Stage N without a timer" (`StageExploreWarning`).
- Each stage folder holds `Gate` (`TimerStart`, `GateExit`, `GateSign`), `Top10Leaderboard` (beside the gate) and `Arrival` (where finish and Home land, in front of the gate, facing the island).
- **Flows:** the hub gate lands on the world's `Spawn`; finish and Home from a stage land on the stage's `Arrival`; Home on a plaza (also right after a finish) and the south return portal go to the hub, landing in
  front of the world's hub gate looking out (`HubExitCFrame`). World-aware through `StageConfig.Worlds`, `ReturnCFrame`, `HomeService`.
- Islands and courses sit in the same sea; `DebugBaseplate` (the kill floor) must cover every new course, or be extended.

### 7.2 Unlock chain and prices
- **Inside a world:** Bronze on the previous stage, or the price (`StageConfig.unlock`, `unlockPrice`).
- **World openers** (stages 6, 11, 16): **10 of the 15 stars of the previous world** (`unlock = { world, stars }`; 10 = Silver on every stage),
  or the price.
- Price of stage `n` ≈ the previous stage's medal total, rounded to 500 (stage 1 is 200); buying every unlock is expensive on purpose: skipping
  stays possible (GDD §3, ECONOMY.md).

### 7.3 Challenge coins, boards
- About 8 coins per stage (5 easy, 2 risky, 1 talent). Talent coins need a talent the stage does **not** require (a later world's), so they pull
  players back. **Values are flat:** 20 / 50 / 100 (`ChallengeCoinConfig`); the stage-factor scaling was rejected.
- Every stage has its Top-10 board (`leaderboard_<stage key>`); the hub "most stars" board is the only stars board (the per-world `WorldStars_<n>`
  boards were removed, their stores emptied).

### 7.4 Keys, folders, checkpoints
- **Key = folder = position** (`Stage1` … `Stage15`, `Tutorial`), never changed again; only `order`, `displayName`, bar and price may change. Stage
  folders live under their world (`Workspace.World1.Stage1` …); coin ids `<folder>_<n>`; boards `leaderboard_<key>`. Coin ids and boards swapped
  with the Stage 3 / 4 swap (Blink is Stage 4, the bounce corridors Stage 3).
- Checkpoint names must be numbers (the handler and leaderstats read them); each new stage takes the next free block of 100. Blocks: Stage 1
  `101`-`105`, Stage 2 `1`-`9`, Stage 3 `10`-`14`, Stage 4 `201`-`206`, Stage 5 `20`-`22` (+ `level.2/26`), Stage 6 `401`-, 7 `501`-, 8 `601`-,
  9 `701`-, 10 `801`-, 11 `901`-, 12 `1001`-, 13 `1101`-, 14 `1201`-, 15 `1301`-; `301`-`303` were the key arena's. Numbers are not always in course
  order (extra plates were added later; deleted ones are not reused).
- Adding a stage: LAYOUT.md "Adding a world stage" plus the `StageConfig` entry (`world`, `requires`, key, prices); about one session per
  stage (greybox from kit templates, playtest, coins, decor, measured `tBase`); special stages about 1.5×.

### 7.6 World 1 stages
- **Stage 1 Island Hop** (west near gate, z 302): the course leaves west from x -438 inside z 272..335, about 370 studs, a gentle S-curve.
  *Signature: stud pillars over the sea* (no kill parts, the sea is the only hazard): (A) warm-up, six 6 x 6 pillars, gaps 4, plate `102`; (B) pillar
  field, twelve 4 x 4 / 3 x 3 pillars staggered 3-5 studs sideways, gaps 4-6, `103`; (C) three small pillars, two **conveyors** (8 x 18, 6 studs/s, first
  against then with the run), a rest pillar, `104`; (D) pillar, 8 x 8 bank, then one run-seeded `Mover_Slide` (10 x 8, amplitude 6, period 6 s) across
  a 22-stud gap, `105`; (E) six pillars rising 8 studs, a 16 x 16 finish island. Reach limits hold for Bronze without talents: every main-line gap at
  most 6.1 edge to edge, rises at most +1.5, landings at least 3 x 3 (the 3 x 3 pillars with a sideways stagger are the tightest). Coins
  `Stage1_1..7` (the talent coin sits on a 3 x 3 tower 11.5 above the finish island, Double Jump only). **Conveyors** (`KitConveyors.server.luau`): parts
  tagged `KitConveyor` with attribute `Speed` (studs/s along the part's front, negative = backwards); the server sets the anchored part's
  `AssemblyLinearVelocity` once; each is a stud belt (§2.5) on its own pillar `ConveyorBase1/2` (top y 79.5).
- **Stage 2** (west far gate, checkpoints `1`-`9`) and **Stage 3** (bounce corridors, east far gate, `10`-`14`): the older hand-built stages; their
  facts are in GDD §3 and LAYOUT. Stage 2's `Lava block` is hot coals (§2.5); its spinners are kit parts. Stage 3 needs `FallResetDepth = 70` (the
  bounce bricks lie 46-61 studs below the plates). Stage 3 and 4 swapped places so the easier course comes first.
- **Stage 5 precision finale** (north gate; shortest course, slowest: pure precision, no timing obstacle, doable without talents; a death costs
  about 30 s of replay): (1) **max-distance jumps** (20 → 26): five gaps of 10.5 over four plates evenly spaced between the checkpoints, each 1
  higher, every landing plate with the 1-stud **lip** (§1; without talents, jumping at the edge clears it, jumping 0.5 early fails; 11-stud gaps
  fail even with the lip); (2) **wrap-around** (`level.2`, a Model literally named `level.2`): three walls fill the width of a 40-stud floor, you
  jump out around each one's side over the void; (3) **tightrope** (21 → 22): a zig-zag of five 2 x 0.4 beams with four 2-wide red kill nubs to hop
  (not 0.1-stud wires: too hard on a touch stick). Checkpoints `20`-`22` (+ `level.2/26`; losing it once left a 23-stud gap).

### 7.7 Stage 4 Blink (the rhythm special)
- **Place:** east near gate (z 302, x -320; the folder was `Stage3` until the 3 / 4 swap); the course runs **east** along z 272..335, a straight 517-stud
  lane to a finish island at x 185. Checkpoints `201`..`206` at x -312, -236, -168, -48, 47, 106, every plate facing east.
- **Beat:** `BPM` 120 (beat 0.5 s, bar 2 s, two bars 4 s); beams use a 2 s period, plates and pistons 4 s. All timed parts are `RunSeeded`.
- **Course:** (1) *count-in*, five 8 x 8 `Plate_Disappearing` (period 4 s, 75 % solid, telegraph 0.5 s, phases stepped -0.25 so they vanish one after the
  other); (2) *beam rows*, floor 202 → 203, four `Hazard_BlinkBeam` curtains 8 apart (1 x 18 x 18, period 2 s, 50 % on, telegraph 0.4 s, phases stepped
  -0.25 so a full-speed runner meets all four in the same state); (3) *piston bridge* (106 x 6), four `Hazard_PistonPush` blocks (8 x 6 x 2, stroke 8, push 55,
  every two bars, telegraph 0.5 s) from alternating sides, phases 0 / 0.5 / 0 / 0.5; a push throws you into the sea; (4) *drop the beat*: six 8 x 8
  plates (third static) with a beam curtain over every gap (duty 40 %, plates 80 % solid), a floor with six beams 6.4 apart (phases 0 / 0.5: dash,
  wait, dash), five plates (third static) to the finish island.
- **Fairness (offline, KitMath):** a runner at 14-19.8 studs/s gets through every section from a static spot; windows of 0.8-2.5 s per 4 s cycle (2 studs
  of body margin on beams, 5.5 on pistons); a perfect run takes about 40 s (`tBase` 60). A beam's kill box reaches about 1.9 studs from its centre.
- **Music:** `StageMusic.client.luau` (a `Music` Sound in the stage folder: attributes `BPM`, `Metronome`, `BaseVolume`) plays while that stage's run is
  active and ticks on every beat from run time (a higher tick on bar starts); a looped track would use `TimePosition` = run time mod length. The
  placeholder is the Creator Store sound `ui_click_2` (asset 110948579458469). `SoundSettings.client.luau` adds a "Sound: On / Off" row to Settings
  (player attribute `SoundMuted`, session only; it mutes all game sounds through a master SoundGroup). Coins `Stage4_1..8`.

### 7.8 Worlds hub: courtyards of Worlds 2–4
- **World 2 courtyard:** World 1's rectangle cloned 263 studs south (x -430..-320, z 450..620, y 77) and **rotated 180° about its centre**, so the entrance
  (`ReturnGate`, `Spawn`) faces World 1 and the finale gate is at the far south end with its course running south (a plain copy would have sent the
  finale lane through World 1). `Workspace.World2`: `Plaza`, `Rock`, `Wall` with the gate openings, `Spawn`, `ReturnGate`, `Decor`,
  `StarsLeaderboard`, `WorldSign`; the plaza reserves two bonus-portal slots beside the return gate. The kill floor already covers the area.
- **World 4:** `StageConfig.Worlds[4].soon = true` (`unlock = { world = 3, stars = 10 }`, 6 000): its gate is shut for normal players (local
  barrier, the server refuses the teleport) and open for admins so the island can be built; the face shows "Coming soon" and the future
  requirement. No island exists yet. The score panel shows the world's name and stars out of `Worlds[n].stageCount`.
- A hub gate model's script files are copied on disk; Argon creates the bare models, the Studio-only children are cloned in.

### 7.9 World 2 (Stages 6–10)
- **Slots** (World 2 is World 1 rotated 180°): stage 6 = east near (x -318.3, z 505, course east), 7 = east far (z 565, east), 8 = west near
  (x -431.7, z 505, west), 9 = west far (z 565, west), 10 = finale gate at the south end (x -375, z 621.7, course +z). `TimerStart` 13.3 studs outside the
  wall line, `Arrival` 13 inside. Folders `Workspace.World2.Stage6..10`, checkpoint blocks `401`- … `801`-. `requires` Double Jump; World 2 opens with stage 6.
  Coins `Stage6_1..8` … `Stage10_1..8` (5 easy, 2 risky, 1 talent). Look: the Island Hop stud look.
- **Reach rules for Double Jump stages** (baseline bot, jumps 0.6 studs before the edge, double-jumps at 0.24 s): a Double Jump crosses a **12-12.5 gap with
  1.6-2.4 to spare** and an **11-stud ledge with 4.6-4.9** (12 has none, so ledges stay 11); a single jump with Run Speed 5 + Jump Height 3 still crosses 12 by 0, so
  the real gate is the 11 ledge (single rise with every soft talent is 9.0). Rules: Double Jump gaps 12-12.5 (never over 13), ledges 11, landings at least
  6 x 6, **single-jump gaps at most 6.5**, 4-5 when the next plate is 4 higher. A player with Run Speed 3 / Jump Height 3 covers about 21 studs with a running
  Double Jump, so square plates cannot force timing for them.
- **Stage 6 Double Up** (~630 studs; `FallResetDepth = 55`: the pillar descent after `408` ends 42 below the plate): pillar warm-up; five 8 x 8 Double Jump
  pillars (gaps 12.5, stagger ±3); three 6 x 6 ledge towers; a kit lift (rises 22, period 10, pause 1.5 s); two run-seeded slide movers (amplitude 8, period 6 s,
  opposite phases); a zigzag of six 6 x 6 pillars (gaps 9 along, 10 sideways); five sideways-sliding stones (amplitude 9, period 7 s, phases 0 / .2 / .4 / .6 /
  .8); descent to the finish island. Checkpoints `401`-`405`, `407`, `408`.
- **Stage 7 Seesaw** (~760; `501`-`508`): tilt plates (teaching plate, chains of four, a recovery chain with 10-11 gaps, a gauntlet of six, three rising ones in a
  gust zone), 40 x 6 beams in wind (steady crosswind push 10; gusts push -14, period 5), crumbling plates (delay 0.8 s). Plates are touchy: `Sens` 3.5
  (teaching, slide angle 25), chain 7.5 / 9 / 10.5 / 12, recovery and finale 9, gauntlet 12, slide angle 22 (a plate slides you off at about 1.8-2.4 studs from
  its centre; lower `Sens` / raise `SlideAngle` if too hard).
- **Stage 8 Turntable** (~550; `601`-`606`): new kit kind `Flip` (rests, tints for `Telegraph` s, turns 180° in `Turn` s, not solid while turning; a turning flipper carries nobody). Every mover
  run-seeded. A kicker paddle (`Push` 40, `PushLift` 25, `PushTime` 0.4 s: a one-shot push was braked within 2 studs), spinning planks (60 / -60 deg/s), two sweeper pads (bars 75 / -95 deg/s, corners
  are the safe spots), flipper rows (period 5 / 3.5, telegraph 0.5, each flipping 0.55-0.6 s *after* the one behind so a steady runner follows the wave), two flat windmills (30 deg/s), two Double Jump
  ledges, the finale turntable under a -55 deg/s sweeper. Knock-back follows the mover's motion at the character.
- **Stage 9 Labyrinth** (~360 + maze; `701`-`705`): `KitMaze.client` plays tagged `KitMazeWall` parts (`Pattern` per layout step, `Period`, `Phase`, `Telegraph` 1.5 s; `RunSeeded`; a change takes 0.4 s
  and a rising wall pushes an overlapping character aside). Cells are 10 studs. Layouts are generated and seeded (a random spanning tree, then swaps that cut the current route and reconnect elsewhere,
  so every layout is a connected tree). Each maze has a `CameraZone` (Iso, Yaw 90, Pitch 70, Fov 25, Distance 180 / 260) and a `KitGhostZone`; a glass divider `LaneDividers.World2West` (z 523.5)
  separates the Stage 8 / 9 lanes.
  - *Roof:* an invisible ceiling at the wall tops (10 thick, underside at 94.5) holds every talent, plus four invisible fence slabs per maze (`*_Fence_N/S/W/E`; y 94.5-160, flush with the outer walls
    and 2.5 outward) so nothing outside can be landed on (without them a Double / Triple Jump from the entry / exit pad landed on the ceiling and walked over the maze). Jump boosts above about 65 studs
    of rise would need a taller fence.
  - *Small maze:* 7 x 7, 2 layouts, period 8 s. *Big maze:* 15 x 15 (x -630..-780, z 535..685), entry from `703`, exit door (`KitDoor`, group `LabyrinthExit`) opened by a latching `KitButton` (`Latch`:
    open for the rest of the run, kept through a death) in a 3 x 2-cell switch room with checkpoint `705`, so the maze is crossed twice; 4 layouts, period 5 s, 36 shifting walls; four red kill guards
    in guard lanes that stay open in every layout (11-13.5 studs/s, end cells safe); six blinking lava tiles (period 4, on 40 %) with Studio-only `Flames` / `Embers` `ParticleEmitter`s that
    `ObstacleKit` switches with the beam state (they must stay under the `KitBeam` part). `Lava_n` kill boxes are 7 x 7 inside the 9 x 9 `LavaMark` tile: R15 feet and legs do not collide, so
    **keep a 1-stud margin where a kill box meets a wall** (the hit test ignores walls).
  - *Coins:* the seven maze coins (`Stage9_1`-`_7`) sit at y 86.0, 7.5 above the floor: a 16-high wall hides a coin below about 2.3 studs under the iso view; keep them at 7.5 or higher (the ceiling
    starts at 94.5). `Stage9_8` stands on a pillar outside the maze.
- **Stage 10 Clocktower** (~700, 120 high; `801`-`806`): a climb round a tower; everything moves on **one 1 s clock tick** (Blink's metronome sound at 60 BPM, run-seeded). Kit: Spin `Tick` /
  `TickMove` (`KitMath.Ticked`), `KitButton` / `KitDoor` (Group, `Time`, `Latch`, `OpenAxis` / `OpenDistance` / `OpenTime` / `OpenTurn`; kit-local; a countdown of whole seconds floats over button and
  doorway). A 40 x 40 `Tower.Core` at (-347, 686) up to h 120 with a `Belfry` (h 120-157.5); three laps on a square of half-size 28, 12 sides of 56 studs, rising 10 per side: gears, wall pistons,
  tilt plates in gusts, tick beams (lap 1); tick flippers + crumbling steps + **door 1**, a ticking kill hand, planks (lap 2); pendulums, a conveyor (-12) with hurdle beams, flippers + **door 2**,
  crumbling stairs (lap 3). Doors stay open **11 s** and sit behind a `Doorstep` slab so the checkpoint behind cannot be touched past a shut door. The finish portal is on the belfry top behind a
  `BelfryLadder` with a tick kill beam. A **roof ring of 12 stud gargoyles** (kill boxes exactly their silhouette) blocks Double Jump shortcuts onto the roof; `Gargoyle_11` is a gate (`KitDoor`,
  `OpenTurn` 90, `Button_11` on `806`). Falling from a lap lands on the lap below (Quick Respawn's fall reset returns you). Build rules: steps must not end under a checkpoint plate (it sticks 8 studs
  back toward the arriving side); flipper waves must follow a hopping player; doors at least 20 high.
- Open: human difficulty and real `tBase` of every World 2 stage (checked only with a baseline bot).

### 7.10 Triple Jump, Dash and the World 3 courtyard
- **Triple Jump** = `DoubleJump` level 2. The Skills row renames itself per level (`names`; strings `talent.name.DoubleJump` / `.2`); a requirement
  `{ id = "DoubleJump", level = 2 }` reads "Needs: Triple Jump".
- **Dash** (`Dash`, levels Dash / Long Dash): in the air only, **once per air time** (reset on landing / climbing / swimming like the air jumps), a **flat** burst:
  height is held for 0.2 s (Long Dash 0.32 s) at 50 studs/s, then the normal fall resumes with the run speed in the dash direction (move direction,
  else facing). Air jumps stay usable after a dash; a jump pressed during the burst is ignored. Controls: **Q**, gamepad **X**, an on-screen button on
  touch devices (`ContextActionService`, bound only while the talent is owned). Client-driven (`TalentDash.client`) with a short local trail. A faster
  burst than 50 studs/s could pass a thin kill beam between two kit touch tests. Fixes found in the vault: "on the ground" is a probe under the root
  (under a low roof the humanoid state reports Landed with the feet 2 up); a box cast ahead ends the burst at a wall, and a hit less than 60° into a wall
  slides along it with that share of the speed.
- **No world gate on buying**: both talents can be bought any time (talent coins of earlier worlds use them); the course geometry is the gate.
- **Telemetry:** Run Speed is bucketed in the loadout (level 0 → `RS0`, 1-3 → `RS2`, 4-5 → `RS5`) to stay under the event budget (TELEMETRY.md).
- **World 3 courtyard:** the free sea east of the hub: World 2's courtyard moved by (+225, 0, -1150): x -205..-95, z -700..-530, same orientation (entrance,
  `Spawn`, `ReturnGate` on the north side z ~ -700, the finale gate at the south end z ~ -530, its course running +z toward z ~ -250). Side lanes reach east to
  x ~ 450 (clear of KitLab at x 447+) and west to x ~ -800 (the hub starts at x -1038). `World3/ReturnGate` and `WorldStarsBoard` scripts are copies of World 2's.

### 7.11 Stages 11 and 12 (Triple Peaks, Ice Rink)
- **Slots:** stage 11 = east near gate (x -93.3, z -645, course east, band z -678..-615), stage 12 = east far gate (z -585, east, band z -609..-546).
  Checkpoint blocks `901`- / `1001`-, coins `Stage11_1..8` / `Stage12_1..8` (the talent coin needs Dash). `requires` Triple Jump; World 3 opens with stage 11.
- **Reach rules for Triple Jump stages:** the gate is the **ledge height**, not the gap. A ledge is cleared with a root rise of about its own height, so
  **Triple ledges are 20** (gap 6): a baseline Triple Jump lands them with several timings, a maxed Double Jump (rise 18.0) fails every one. Flat Triple
  gaps of 17 (8-stud side shift) are soft (a fast Double Jump may make them).
- **Stage 11 Triple Peaks** (x = -87 + u, z = -645 + l, h above y 78.5; plates 12 along, 16 wide; `FallResetDepth = 75`, the descent ends 65 below `905`): Double Jump pillars `A1`-`A3`; `Shelf1` under the
  first Triple ledge `T1`; peaks `P1`-`P4` (Triple ledges, a flat 17 gap); kit lift `Lift1` (h 58 → 92, period 10) with a Triple ledge to `P5`; the **crusher ridge** `Ridge` (66 x 6, h 112) under
  `Crusher1..4` (kit `Piston` down, Stroke 9, Period 3, Duty 0.25, Telegraph 0.6, `Kill`, run-seeded, each slamming 0.75 s after the one before, so a walker who leaves as crusher 1 lifts follows the
  wave) inside a **press** (`Stage11.Press`: glass walls, `PressRoof` 32.5 above the ridge, out of a maxed Triple Jump's reach; a baseline Triple Jump otherwise hopped over the crushers) with
  `Movers.Rod1..4` (5.6 across: the slot is 6) welded on the heads; `Summit`, descent `D1`-`D4`, finish island.
- **Stage 12 Ice Rink** (z = -585 + l): `Rink1` (44 x 24 ice) and ice turns `I1`-`I3`; four 10 x 10 ice plates `J1`-`J4` (gaps 5-7, side shifts 8: hop on at once, a stop slides you off); the pressure
  `Button` (Group `IceDoor`, 8.5 s) at the start of `WindBeam` (66 x 8 ice in the steady crosswind `Wind1`, Push 6), a rest plate (no checkpoint: a fall replays the wind beam), ice track `Track1..3`
  with two 5-stud gaps, `IceDoor` (1-stud wooden door hinged on its north edge, `OpenTurn -90`, swings toward the player, §2.3.1); Triple ledges onto ice `K1`-`K3`. At 8.5 s the door leaves 1.5 s at
  WalkSpeed 20.8 and is missed at 16 (Run Speed is effectively needed).
- **Kit ice (`KitIce`, `ObstacleKit`):** on a `KitIce` floor the client drives the horizontal velocity toward the input at `Accel` (14) and coasts without
  input at `Brake` (5): 15.5 studs/s after 1 s, a 21-stud coast. The kit sets friction 0 / weight 100 on every ice part locally (the Humanoid's own grip
  otherwise stops a slide on Plastic). **Ice-air:** from leaving a `KitIce` part until the next landing the kit keeps driving the root at `AirAccel` (14),
  never braking without input; a dash in ice-air restores the slide afterwards (character attribute `IceAir`, read by `TalentDash`). A teleport or death ends it.
- **Door countdown** (every `KitDoor`: Ice Rink, Clocktower): a big number at the door's middle (seconds rounded up, a bar green → orange → red, drawn
  through walls) and ticks in the last 3 s (Studio-only `ReplicatedStorage.DoorTickSound`).
- **Open:** Stage 12's `Wind1` zone is only 14 high, so a hopping player may dodge the crosswind; a human run's `tBase`.

### 7.12 Stages 13 and 14 (Dash Bridge, Laser Lab)
- **Slots:** the west openings of the World 3 courtyard: stage 13 = west near gate (band z -678..-615, course **west**), stage 14 = west far gate (centre z -585,
  band z -609..-546); the sea west is free to about x -950. Blocks `1101`- / `1201`-. Both require Triple Jump + Long Dash (open-air Dash gaps had a 2-stud
  window between a baseline Triple Jump + Dash and a maxed Triple Jump, hence Long Dash, §1.0). Talent coins of stages 13-15 need **maxed soft talents**.
- **Rolling balls (`KitMover Kind = "Roll"`):** the ball travels along `Axis` for `Distance` studs in `Period` (Phase, RunSeeded), turns about the cross axis, fades in
  `Fade` s at both ends, `Kill` by default. No physics.
- **Stage 13 Dash Bridge** (x = -213 - u, along z -657, h above y 78.5; **every part stays north of z -644**, behind the Laser Lab's camera; `FallResetDepth = 40`): runway `R1`, a 22 gap to `L1`,
  34 gaps to `L2` and over the sea to `P1`, `P2`; the first two over catch floors `Catch1/2` **32 below** with a truss back up (8 below let a short jump climb out without a Dash); a 6-wide `Bridge`
  under `Axe1..4` (hung 38 above the deck so no Triple Jump lands on it; `Swing` Hinge X, Angle 24, Period 3, phases 0 / 0.708 / 0.417 / 0.125 = a wave a 16 studs/s walker follows); a `Ramp`
  (10 wide) with `Ball1..4` (Ø 5, `Roll` Distance 80, Period 6, two lanes, a ball every 1.5 s alternating; 3 per lane killed even a jumping bot) and side `Pocket1..3`; a 34 gap through
  `AxeFinale` (Angle 50, Period 4) to `F1`, a 22 gap to `Finish`. Checkpoints `1101`-`1105`. Talent coin on `TalentPillar` 41 north of `F1`.
- **Stage 14 Laser Lab** (x = -213 - u; **lane z -588..-582**, centred on the gate; `Side` camera zones with `Yaw 180`: `VaultCamera` Distance 55 over the vault and entry, `LabCamera` 45 elsewhere;
  Stage 13's track lies 56 north of the lab's wall): `Entry` hall with `TeachBeam`; the **Vault** (room 1, below); `Deck` with a plain 34 gap; the `BeamHall` (h 0-40): `Grid` (four floor-to-ceiling
  `KitBeam`s, Period 3, Duty 0.5, the dark window moving west at 16 studs/s) and `Sweepers` (two double-arm laser bars, hubs at h 12, **both turning with the walker** at -45 deg/s, Phase 0 / 90; the
  floor between them is safe); the **`ColourShaft`** (slab 1 at h 6-7 with the red `Hatch1`, slab 2 at h 21-22 with the blue `Hatch2`, lanes 14 high; `Toggle0` on the floor, `Toggle1` on slab 1, Group
  `Lab`; the hatches are open in opposite colours, so a wrong toggle costs time, not a life; wires from each toggle to its hatch); the `Finale` (a 34 gap over a `LaserFloor` with `FinaleBeam`,
  Period 2.5; the bay is 54 high so a Triple Jump from slab 2 does not hit the ceiling). Checkpoints `1201`-`1206`, portal at u 544. Every part ends at the back panel's inner face (z -582 side): a
  part through the panel z-fights (§2.3.1).
- **Vault lanes** (room 1, left half; part geometry is encoded in `tools/vault_reach.py`). A Triple Jump rises 21.8 (27.0 with Jump Height 3), a third of the room, so height alone cannot force a route:
  the room is **stacked lanes, each under a solid roof, open at alternate ends**, plus one-way teal gates and two colour switches. Route: the dash corridor along the floor (lane 0, roof `PlatformA` +
  `Hatch_Low`; the only exit is past the floor spikes `Spikes.Floor_9`: single jump + Long Dash under the 15.4 roof), a switchback up the right (`Block_Float2`, top h 8.1, down to h 3.4 so no avatar
  walks under it, carries `Switch_Lane1` which ghosts `Bar_Lane1`), left along `PlatformA` (lane 1; `Switch_Lane2` on `LedgeL2` ghosts `Bar_Lane2`), right along `PlatformB` (lane 2, roof `Lid` with
  the deadly `Spikes.LidKill`, `Hatch_High` with `Gates.HatchKill`, `KillWhileShut`; exit up the chimney beside `RightWall`), then lane 3 over the lid: `Block_Top2` (top 52.6) and `Block_Top1`
  (top 68.6), **16-stud steps** (one is inside a baseline Triple Jump, two (32) are out of a maxed one, so each stone is needed) to the teal (mint) key (`Hit` at u 58-65, h 88-94). After the key both
  hatches open and the player falls to the entrance floor, back to the dash corridor and the teal lock (a low mint door under `E_BarLower`, `ArenaGate`, `KeyId = Teal`). With `Switch_Lane1` still
  pressed, `PlatformA` → lane 1's right end reaches the right floor without the dash corridor (accepted; `ClosesWhenOpen` stays in the code, unused).
  - *Wires:* `Decor.Wire_*` (attribute `Switch`) run from each pad to the barrier it opens; `KitWires.client` runs a green bead along the pressed pad's wire. *Code:* `ArenaConfig.ClosesAttribute` /
    `KillAttribute` / `HeldAttribute` in `ArenaClient.refreshGate` (gate changes fade over 0.8 s and never turn on the collision of a part authored without it); keys and switches reset at a run start,
    not at a death.
  - *Model:* `tools/vault_reach.py` searches every path: `max` (Jump Height 3, Run Speed 5, the smallest avatar, 2-stud ledge snap) hunts shortcuts, `base` (Triple Jump + Long Dash, the tallest
    avatar) checks feasibility. Must hold: with either barrier shut or either top stone missing `max` does not reach the key; `base` reaches it; `max` does not get past the teal lock (`PastPillar`)
    before the key. **Re-run it after moving any vault part.**
- **Vault tower** (right half, green key; four lanes for the avatar size rule §1.0). From the teal lock along the floor, a switchback up four ledges (tops **14.25 / 27.81 / 40.75 / 54**, hung alternately
  from `Solids.RightMass` with the gap at the left and from `E_Stem` with the gap at the right; the count must stay even so the climb ends walking left into the slot), over `E_Stem`, down the slot to
  the key, a drop to the floor lane and the green lock. Every ledge roofs the lane below except at its gap; a ledge-up is a **Triple Jump** through the gap. The three lower ledges carry a **row of
  three spikes** ending 0.6 before the gap the climb leaves by: a **jump + dash** (a single jump does not clear three spikes; air jumps on the way down also carry a player over: accepted); every row
  has 5.66 of feet room for a 5.2 collider. The top lane has only `Ceiling_21`. The slot between `E_Bar` and the stem is **10.2 wide** (4.2 and 6.2 failed: stepping off the stem carries walking speed
  and the fall pose puts the hands 2 studs ahead into the side spike); the key sits on `Gates.SlotHatch` (`OpensWhenHeld`: fades with the bottom spike once the key is held); a dash in dies on `EBarSide_22`.
  Model: `RIGHT=1` in `tools/vault_reach.py` (`PLUG=k` fills the gap of ledge k, `HATCH=open`); `bash tools/vault_right_checks.sh` (8 checks, about a minute): `base` gets from the doorway to the
  key and lands left of the bottom spike; any one plugged gap keeps `max` from the key; the open hatch leads to the lock zone.
- **Open:** a human climb of the whole vault; the look of the empty upper back panel and the old `Decor.Tile` panels behind the tower; a human `tBase`.

### 7.13 Stage 15 Rising Tide
The World 3 finale: a **lava tide** rising under the whole course, over a run that replays every World 3 piece. Out and back: the high return leg looks down on the
drowned outbound course.
- **Slot:** the south (finale) opening of the World 3 courtyard (x -165..-135, z -532..-528); the course runs south (+z) inside x -200..-40, z -528..-140. u = south of the gate
  line (z = -528 + u), v = east of the gate's centre (x = -150 + v), heights as world y (plaza top 78, plate tops 78.5). Folder `Stage15`, checkpoints `1301`-`1306`, coins
  `Stage15_1..8`. Requires Triple Jump + Long Dash.
- **The tide (`KitTide.client.luau`, Studio part `Stage15.Tide`, tag `KitTide`):** a Neon slab (255, 85, 20) over the whole footprint, no collision, under a `Crust` child (a 0.2-thick
  `CrackedLava` sheet (255, 120, 0), transparency 0.15, its top 0.05 above the slab's, so the glow shows through its cracks; the kill test uses the slab only). Only its height moves,
  only on the running player's client (each player races their own tide). **Each checkpoint resets it:** reaching a checkpoint (the gate's `TimerStart` counts as the first) and every
  respawn there set it to that plate's `TideFloor` (world y, attribute on the `C` plate), and it rises at the plate's `TideSpeed`; re-touching a plate does nothing; a plate without
  the attributes parks it. No run = no tide; finish, Home, `GateExit` and a cancelled run park it. **Kill test:** any character part below the tide's top inside the footprint dies
  (`KitKilledBy` = `Stage15.Tide`, telemetry cause `kill:Tide`); walls do not shelter. A `Rumble` sound child is supported, none authored yet.
- **Budget rule:** at every point the tide arrives after ≥ 1.6 × a clean run's time from the checkpoint and, on flat parts, ≤ 3 × (the lava must be seen coming). Values (world y / studs
  per s): `1301` 54.5 / 1.5, `1302` 70.5 / 1.5, `1303` 116.5 / 1.5, `1304` 125.5 / 1.5, `1305` 130 / 2.5, `1306` 182 / 1.75. Climbs outrun the tide.
- **Course:** (1) *Shore* (teach): `Causeway1..3` (16 wide, single-jump gaps 6), Double Jump ledges of 11; `LowShelf` holds the risky coin. (2) *Crusher ice:* `IceRidge` (kit ice, 8 wide) under
  `Crusher1..3` in a **press** (glass walls, `PressRoof` 32.5 above). Heads 12 long and contiguous, Stroke 15, **cascade rhythm** (the user's): cycle 4.5 s, strikes at 2.3 / 2.7 / 3.1 s (`Duty`
  0.48889 / 0.4 / 0.31111, same Period and Phase 0), all rise together over 2.0 s; `Rod1..3` (square columns 6.2 across, welded on the heads) fill the space up to the roof, so the only way through is
  **"go as they lift"** with two hop + Long Dashes (a window of about 0.6 s). (3) *Dash run:* three 34 Long Dash gaps rising 2 each, an `Axe` (`Swing` Hinge Z, Angle 40, Period 3) over the third,
  pivoted 55 above the take-off (a lower pivot put the blade in every flight path). (4) *Headwind door:* `Button` (Group `TideDoor`, 9 s) on `1304`, two beams with a 12 gap in a gusting headwind
  `Wind` (Push -10, Period 3, Duty 0.5, **30 high**: a low zone lets a jump's apex escape it), `TideDoor` into the shaft (Stage 12's door; 14 high, under `Slab1`). (5) *Chimney:* a 24 x 24 shaft (glass
  `GlassN` to the north for the camera), `Slab1..3` and `Roof` 15 apart, **one 6 x 6 hatch per level** (`KitColorPlate`, Group `Chimney`, groups start red) with a `Toggle0..3` pad on the level below;
  `Beam1` / `Beam2` across slab 2; `ChimneyGhosts`; a ceiling stamper between the hatch and `Toggle3`, crossed twice (safe window about 2 s): `StampHead1..3` (clones of `Crusher1`, Period 5, Duty 0.34,
  Stroke 9.8) each hung on a **telescope** (`StampPost` / `StampMid` / `StampInner` pistons moving with the head, overlapping at least 1.0: nothing shows below the raised head and no gap opens under the
  lowered one). `1305`'s model carries `BeamHeight` 10 (`CheckpointClient`); `GlassN` is `SmoothPlastic` 0.5 (**Glass material does not draw transparent parts behind it**). (6) *Summit:* `1306` on
  the roof, `Ramp` with `Ball1..4`, `SweepPad` under `Sweeper` (Speed -45, the lower arm moving with the walker), a 34 gap (drop 4) to `Crag`; `TalentPillar` 25.5 above the roof. Gold is 46 s
  (`Gold = 46 / 55` of tBase; the stamper costs 2 s).
- **Open:** a human run and the real `tBase`; maxed-talent shortcuts in segments 3-6 (a maxed Triple Jump rises 27, the sweeper's top is 22.5 above its pad); the rumble sound asset; the camera
  inside the shaft.

## 8. World 4 and later (ideas, not built)
`StageConfig.Worlds[4]` is `soon`; the stages below carry no keys yet (next keys `Stage16`…`Stage20`, checkpoint blocks from `1401`). ROADMAP lists the
milestones (S9 Wall Jump + Glide talents, S10 the stages, S11 bonus stages).

| # | Name | Signature | Other components | Requires | `tBase` guess (s) |
|---|---|---|---|---|---|
| 16 | Wall Climb | wall-jump shafts | pistons, disappearing plates | + Wall Jump | 110–130 |
| 17 | Glide Canyon ★ | dropper: a long fall down a shaft, steer through rings | glide sections, updrafts, blinking beams in the air | + Glide | 90–130 |
| 18 | Moon Base | low gravity | blinking beams, Dash gaps | all so far | 120–150 |
| 19 | Clockwork | synchronised timers | rotating plates, crushers, wall jumps | all so far | 130–170 |
| 20 | Summit (finale) | everything | every talent in one run | all talents | 160–200 |

- **Glide Canyon dropper:** starts at the top of a tall shaft (400–600 studs); the player falls through rings, past blinking beams and rotating bars with the
  `Down` camera. A zone caps the fall speed (about 80 studs/s), because Roblox characters keep accelerating. Glide sections between shafts (wide horizontal
  gaps) and updrafts lift to the next shaft; checkpoints on platforms in the shafts; no fall damage, so landings are safe. Quick Respawn's fall reset stays off
  there (falling is the course).
- **Talents:** Wall Jump and Glide (§6.2); their reach numbers must be measured in the jump lab like the others (§1.0). World 4's star bar (10 of 15 in
  World 3) should be re-checked against World 3's tighter medals.

## 9. Open questions
- World themes and names (sky, factory, storm, summit …)? Open; the style is stud (voxel / pixel-art previews were dropped).

## Build gotchas
- **ChoiceStage:** the scripts pick a random child named exactly `Step`; the three `Step` parts per ChoiceStage keep that duplicate name and are not
  synced. Code that moves scene children by name match overwrites the first one with the second: move them without matching.
- **Fall reset depth:** a stage whose course has a catch or bounce surface, or continues on a platform, far below its last checkpoint needs the Studio
  attribute `FallResetDepth` on its stage folder (QuickRespawnClient's default is 30; the stages that have one: LAYOUT.md → Stage anatomy; today
  `World1.Stage3` 70, `World2.Stage6` 55, `World3.Stage11` 75, `World3.Stage13` 40).
- **Moving kit parts must not share a face plane with their frame** (z-fighting): doors / lifts thinner than their frame, doors swing (`OpenTurn` +
  `OpenHinge`) instead of sliding into a lintel, frame walls reach the ground / sea. After building or changing a `KitDoor` run
  `tools/kit_coplanar_audit.luau` via MCP `execute_luau` (Edit) until "clean"; after building a stage, run it with `STATIC_ROOT` set to its folder
  (rules: §2.3.1).
- A finish portal's label is on its Back face: its `LookVector` must point along the approach (last checkpoint → portal); after cloning or rotating a
  course check `portal.CFrame.LookVector:Dot(approach) > 0`.
- Decorations are clones from the Studio-only `ServerStorage.DecorKit` (stud textures are MaterialVariants in `MaterialService.StudPack`, looked up by
  name: keep that folder); placed decor is Anchored with CanTouch / CanQuery off (flowers / grass also CanCollide off).
- Challenge coins pay once per player and are hidden only on that player's client; a new coin needs a new id in `ChallengeCoinConfig` **and** the Studio
  part (tag + `CoinId`) in its stage folder. No Highlights on coins (Roblox renders at most 31 at once).
