# Pet growth visuals (P1e1-P1f)

> Design and plan for making pet levels visible (size, effects, level-up moment, individuality, accessories). Milestones and status: [ROADMAP.md](ROADMAP.md) (P1e1-P1f). Related: [GDD.md](GDD.md) §7.4-7.5. Correct this file when the design changes while a milestone is implemented.

## Context
Pet XP and levels exist since P1d, but a level-up is invisible: a Lv 20 Cat looks like a Lv 1 Cat. We want pets to
look like they gained experience without storing model variants. Decisions (user, 2026-10-18): first slice includes the
accessory kit; two pets of the same kind and level look slightly different; a Lv 20 pet is 1.6x the size of a Lv 1 pet.
Evolution forms (basic / evolved / true) stay a later, lower-priority step (real per-kind art).

Key idea: appearance is a pure function of (kind, level, uid) applied to the existing blocky models, in **layers**
(size, tint, tier effects, accessories, life). Few steps per layer multiply into many looks. Nothing is replicated:
every client derives it from the `EquippedPets` attribute, as `PetFollow` already does.

## Findings (existing code)
- `PetFollow.client.luau`: `parse()` reads `"Kind:Level,..."`; `makePet(kind, level)` clones `ReplicatedStorage.PetModels[kind]`,
  adds label + Epic/Legendary light and sparkles; models are reused while `key = kind:level` is unchanged; slots `SLOTS`
  are fixed offsets for a widest model of 2.4 studs.
- `GardenService.makePenPet` (server) duplicates the same model/label/glow code for garden pens.
- `PetService.publish` writes the attribute `Kind:Level` (only consumer: `PetFollow`).
- Models are flat (all parts direct children of the Model, anchored, no welds). Every model has `Root`, `Body`, `Head`;
  most have `Tail`. Dragon / Phoenix already have horns / wings, so accessories must be kind-aware.
- Studio MCP screenshots of the 3D view come out blank: looks can only be verified structurally by us; the user checks
  them visually.

## Design

### New shared module `ReplicatedStorage/PetLook.luau`
Pure helpers + one `Apply(model, kind, level, uid)` used by both `PetFollow` (client) and `makePenPet` (server), so
followers and pens always match.
- `Scale(level)` = `1 + (MaxScale - 1) * (level - 1) / 19`, `MaxScale = 1.6` (config in `PetConfig`), applied with
  `model:ScaleTo` (label offset recomputed from the bounding box afterwards).
- `Tier(level)`: 0 for Lv 1-4, 1 for 5-9, 2 for 10-14, 3 for 15-19, 4 at Lv 20 (`PetConfig.Tiers = {5, 10, 15, 20}`).
- `Seed(uid)` -> small deterministic variant record (e.g. hue shift +-4 %, value +-6 % on body parts, accessory pick order)
  so two Cats differ slightly but keep their rarity identity.
- Tint: parts with attribute `Accent = true` (stripes, ear insides, tail tip, belly...) ramp toward the rarity colour
  with level; at Lv 20 accents become Neon. Body parts only get the seed jitter.
- Tier effects, built in code (no lights below Epic; reuse the existing Epic/Legendary light):
  T1 sparkle trail, T2 soft aura (low-rate emitter + faint neon underglow disc), T3 orbiting motes (a few tiny
  neon parts moved by the existing Heartbeat), T4 halo + stronger aura. Colour = rarity colour.
- Life: bob amplitude/speed grow slightly with tier; label gets a tier badge ("Lv 12 *" -> stars per tier) in rarity colour.
- Distance LOD: emitters/orbiters disabled beyond ~60 studs from the camera (checked in the existing refresh loop).
- All created parts: Anchored, CanCollide/CanTouch/CanQuery off, Massless (same invariants as today; re-enforced in Apply).

### Level-up moment (P1e)
`PetFollow` compares the new attribute with the previous list per uid: same uid, higher level -> `PetLook.LevelUp(model)`
(burst of particles, expanding ring, floating "Level N!" billboard, optional sound). It plays for every viewer in range,
including other players. Sound = optional Studio-only `ReplicatedStorage.PetLevelUpSound` (cloned if present, like
`ChallengeCoinSound`); no asset id is invented in code.

### Individuality needs the pet id (P1e)
Attribute format becomes `Kind:Level:uid,...` (`PetService.publish`); `PetFollow.parse` accepts the old 2-part form too
(uid = nil -> no jitter). Model reuse key includes the uid; a level change with the same uid keeps the model identity for
the level-up detection but rebuilds the look. `makePenPet` passes `pet`'s uid.

### Formation and camera (P1e)
- Slot spacing derives from the largest scaled width (2.4 * 1.6 = 3.84 + 0.5 gap) instead of the fixed 3.2; the rear
  centre pet moves back proportionally. Anchor smoothing unchanged.
- Pets behind the player are between player and camera: each frame, parts of pets closer than ~7 studs to the camera
  get `LocalTransparencyModifier` fading to 0.85 (client-only property, no replication, cheap).

### Accessory kit (P1f)
Code-built from a few parts each, positioned from the model's own `Head` / `Body` / `Tail` parts (no Studio attachments
needed): Halo (neon ring), Crown (block + wedge points), Scarf (neck band + tail piece), Small wings (2 wedges),
Horns, Flame tail (neon wedge + emitter). `Accessories[...].skip = { kinds }` avoids duplicates (no wings on
Dragon/Phoenix/Owl, no horns on Dragon). Rule: T2 (Lv 10-14) gets 1 accessory, T4 (Lv 20) 2; which ones comes from
`Seed(uid)` among the allowed candidates, so higher tiers keep earlier pieces (growth, not reshuffle).
Because pieces use only part names (`Head`, `Body`, `Tail`, `Root`) and the bounding box, replacing the blocky models with
real art later keeps working; missing parts fall back to bounding-box positions.

## Critical files
- new `src/ReplicatedStorage/PetLook.luau`
- `src/ReplicatedStorage/PetConfig.luau` (`MaxScale`, `Tiers`, helper `TierOf`)
- `src/StarterPlayer/StarterPlayerScripts/PetFollow.client.luau` (uses PetLook, level-up detection, spacing, camera fade, LOD)
- `src/ServerScriptService/GardenService.luau` (`makePenPet` -> `PetLook.Apply`, drops its duplicated glow code)
- `src/ServerScriptService/PetService.luau` (`publish` attribute format with uid)
- Studio-only: set attribute `Accent = true` on accent parts of the 8 models in `ReplicatedStorage.PetModels` (one
  `execute_luau` script, names such as Stripe*, TailTip, EarInner*, Belly, Muzzle); optional `PetLevelUpSound`.
  **Save the place (Ctrl+S).**
- docs: GDD 7.5 (growth, tiers, accessories, individuality), ROADMAP (P1e, P1f + status rows), AGENTS (layout,
  attribute format).

## Milestones
Two steps is doable but not advisable: we cannot see the 3D result (screenshots are blank), so the user is the only visual
check. Five small milestones let the user look in Studio after each one and steer the next (sizes, colours, which effects),
and each is one commit that can be reverted alone. Order = dependency and value; each needs only the ones before it.

1. **P1e1 - PetLook foundation + size growth.** New `PetLook` module with `Scale` / `Tier` / `Apply`; `PetFollow` and
   `makePenPet` both use it (removes the duplicated model/label/glow code); size 1.0 -> 1.6 by level; formation spacing from
   the scaled width; camera fade. Attribute becomes `Kind:Level:uid` (parser also accepts the old form) because the next two
   steps need the pet id. Studio: none. User check: pets visibly grow, three Lv 20 pets don't overlap, nothing blocks the view.
2. **P1e2 - Level-up moment.** Level-up detection per uid in `PetFollow`; burst, ring, floating "Level N!" (visible to
   all nearby players); label tier badge; optional `PetLevelUpSound`. User check: finish a run with a pet near a threshold.
3. **P1e3 - Tier effects + accent tint.** Trail / aura / orbiting motes / halo at Lv 5 / 10 / 15 / 20 in the rarity colour,
   accent parts ramp to the rarity colour (Neon at Lv 20), livelier bob, distance LOD, cost check for 12 players.
   Studio: `Accent = true` on accent parts of the 8 models (one script). User check: how each tier looks.
4. **P1e4 - Individuality.** `Seed(uid)` jitter (small hue / value shifts) so same kind and level differ; unit-checked
   determinism. Small step; may be merged into P1f if P1e3 review shows nothing to adjust.
5. **P1f - Accessory kit.** Halo, crown, scarf, small wings, horns, flame tail built in code from `Head` / `Body` / `Tail`;
   skip rules per kind; 1 piece at Lv 10, 2 at Lv 20, picked by seed. User check: variety and no ugly combinations
   (a short list of forbidden pairs can be added after review).

Each: design check -> implement -> Studio validation (snapshot + restore the live profile) -> ROADMAP status + validation
log -> commit. Evolution forms (named, per-kind art) stay a possible later milestone after P1f.

## Verification (per milestone)
- Edit mode: `PetLook.Scale/Tier/Seed` values (Lv 1 = 1.0, Lv 20 = 1.6, tiers at 5/10/15/20, same seed -> same result,
  different uids differ), `parse` of old and new attribute formats.
- Playtest (snapshot + restore live profile first; local attribute overrides like in P1c): all 8 kinds at Lv 1/5/10/15/20
  render: scale, part counts, emitter counts, no part with `CanCollide/CanTouch/CanQuery` on, no `Anchored = false`;
  accessory skip rules (no duplicates); three Lv 20 pets side by side: smallest gap between pets > 0 (bounding-sphere
  test as in P1c); label offset above the scaled model.
- Real level-up: finish the Tutorial with an equipped pet at XP just below the threshold -> burst + floating text created
  once, nothing on other pets; pens show the same look as followers.
- Gameplay safety: WalkSpeed/Jump unchanged, pets still trigger no coin/kill/portal touch (reuse P1c positive/negative
  control).
- Cost check: count ParticleEmitters / lights / parts for 12 players x 3 Lv 20 pets (simulated with attribute overrides);
  LOD turns far emitters off.
- Camera fade: place the camera near a pet, `LocalTransparencyModifier` rises, returns when far.
- Multi-client (user starts Server + Clients): the second client sees the first player's tier effects and a level-up burst.
- Consoles clean; live profile restored exactly. Not verifiable by us: how it looks -> the user reviews in Studio.
