# Pet growth visuals (P1e1-P1f)

> Design and plan for making pet levels visible (size, effects, level-up moment, individuality, accessories). Milestones and status: [ROADMAP.md](ROADMAP.md) (P1e). Related: [GDD.md](GDD.md) §7.4-7.5. Correct this file when the design changes while a milestone is implemented.

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
- `Seed(uid)` -> deterministic variant record (P1e4, see below: hue +-6 %, saturation +-15 %, value +-10 % on body parts, tint for
  white / grey parts, optional material texture, accessory pick seed) so two Cats differ but keep their rarity identity.
- Tint: parts with attribute `Accent = true` (stripes, ear insides, tail tip, belly...) ramp toward the rarity colour
  with level; at Lv 20 accents become Neon. Body parts only get the seed jitter.
- Tier effects, built in code (no lights below Epic; reuse the existing Epic/Legendary light):
  T1 sparkle trail, T2 soft aura (low-rate emitter + faint neon underglow disc), T3 orbiting motes (a few tiny
  neon parts moved by the existing Heartbeat), T4 halo + stronger aura. Colour = rarity colour (from P1e4: shifted per pet by the seed, `PetLook.FxColor`; the label keeps the exact rarity colour).
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
**Decisions made in P1f:**
- *Halo dropped from the kit.* P1e3 already gives every Lv 20 pet a neon hexagonal halo (tier 4); a second halo piece at Lv 10 would be doubled at Lv 20 and cannot "keep the earlier piece". The tier halo floats above the tallest accessory (it is placed from the bounding box that includes them).
- *Kit = Crown, Scarf, Wings, Horns, FlameTail.* Skip rules (`PetLook` table `ACCESSORIES[id].skip`): Crown skips Bunny / Fox (ears leave no room) and Phoenix (crest); Scarf skips Dog (has a collar); Wings skip Dragon / Phoenix / Owl; Horns skip Dragon / Owl (tufts) / Phoenix; FlameTail skips Owl / Panda (no tail; Phoenix and Dragon keep it). Forbidden pair (both sit on top of the head): Crown + Horns. Every kind has at least two candidates; Owl (Crown, Scarf) and Phoenix (Scarf, FlameTail) have exactly two, so they always wear both at Lv 20 and differ only in which one comes first at Lv 10.
- *Pick rule:* candidates of the kind sorted by `mix(variant.accessory xor hash(id))`, greedy, skipping forbidden pairs; `AccessoryCount` = 0 / 1 / 2 for tier < 2 / 2-3 / 4. The Lv 10 piece is the first pick, so it stays at Lv 20. `uid` nil -> none (old attribute form).
- *Built on the scaled model before the bounding box is taken,* so slot spacing (wings widen the pet), the label height and the tier halo include the pieces. Parts sit in a Folder `Accessories` in the model (model attribute `Accessories` = "Crown,Scarf"), coloured from the pet's `FxColor` (gold crown with a FxColor jewel; scarf, wings, horns and flame in shades of it).
- *Cost:* at most 11 extra instances per pet (avg 8 at Lv 20) and one emitter (flame tail), which the existing `CollectFx` / `UpdateFx` LOD handles; the camera fade covers the parts because `PetFollow` collects its parts after `Apply`.

Because pieces use only part names (`Head`, `Body`, `Tail`, `Root`) and the bounding box, replacing the blocky models with
real art later keeps working; missing parts fall back to bounding-box positions.

### Stud restyle (P1g, started 2026-10-25)
The plain 15-23 block models get a stud-toy look and more detail, one kind at a time, Studio-only (`ReplicatedStorage.PetModels`;
no code change). Fox is done; the user picked it from five previews (texture everywhere, real cylinder studs, brick-built
"BrickHeadz" with seams, and two mixes). The picked recipe, for the other kinds to follow:
- *Stud texture only on the big main-colour parts* (Fox: `Head`, `Body`, `Tail`, `Tail2`): Material `Plastic` + MaterialVariant
  `StudsSmall` (`MaterialService.StudPack`). Everything white or small (face, chest, ear insides, tips, legs, paws) stays
  SmoothPlastic: the texture reads as a waffle on small areas. No cylinder studs (they barely show at pet size).
- *More detail from shaped parts:* triangular ears from two mirrored WedgeParts (outer, inner Accent, dark tip Accent), a face
  mask wrapping the lower head with cheek tufts (Accent), a sloped muzzle (WedgePart on top), round cylinder eyes with a
  shine, a tail of 2-3 tapering segments with a white tip (Accent), paws. About 35-40 parts per pet (was ~20).
- *Keep the names PetLook relies on:* `Root` (invisible PrimaryPart, front −Z), `Head`, `Body`, `Tail*`; mark the
  level-tinted parts `Accent = true`.
- A variant with `variant.material` (PetLook `jitterBody`) replaces the Material on some big parts, so those parts lose the
  stud texture (the MaterialVariant needs base `Plastic`); intended, that is the variant's texture.
- The replaced models were kept in the Studio-only `ServerStorage.PetModelBackup` (deleted on 2026-11-01; `Fox_Old_20261025`, `Cat_Old_20261025`, `Dog_Old_20261025`, `Bunny_Old_20261025`, `Owl_Old_20261025`, `Panda_Old_20261025`, `Dragon_Old_20261025`, `Phoenix_Old_20261025`).
- *Cat* (done 2026-10-25, 54 parts): shorter wider ears with pink insides, tabby stripes (forehead "M", cheeks, three across
  the back, a tail ring), cream muzzle pads / chin / chest / paws, whiskers, a thin upright tail curling forward. Eyes after the
  user's reference photo (the first green iris with a slit pupil looked threatening): dark-brown rim, gold outer and green
  inner iris, a big oval pupil (disc + short block), a large catchlight up-outside and a small one down-inside.
- *Dog* (done 2026-10-25, 42 parts): floppy dark-brown ears (a fold over the head's edge, a flap hanging outward, a rounded
  end), warm brown eyes like the Cat's (big round pupil, two catchlights) with light brow dots and a brown patch round the
  left eye, a cream forehead blaze, a boxy cream snout with a big shiny nose, a mouth line and the tongue out to one side, a
  brown saddle spot, cream bib and front paws, the red collar lowered below the head with a round gold tag on a ring
  (Accent; the Dog still skips the scarf), a short upturned tail with a cream tip.
- *Bunny* (done 2026-10-25, 45 parts): tall ears in two segments bending outward (pink insides, rounded tips), chubby cheek
  puffs, pink blush discs, two small muzzle pads with a pink nose, mouth line and buck teeth, dark ruby eyes with a big pupil
  and slightly larger catchlights (they must read on the near-black coat), round haunches, long back feet with pink toe
  pads, short front legs, a faintly pink chest (Accent), a cotton tail of three balls. Coats: the big white parts take the
  grey / black coat; the muzzle pads are kept under `TEXTURE_MIN_SIZE` on purpose, so a dark Bunny keeps a light muzzle.
- *Owl* (done 2026-10-25, 46 parts): two overlapping tan facial discs behind the eyes (tagged `Eye`, so they grow with
  them), a big yellow iris with a big pupil, an upper lid in the disc colour covering only a sliver of the iris (level,
  outer end 3° up) with a dark lash line, a downward beak triangle, chunky stepped ear tufts on the head's top corners
  leaning outward (block + darker narrower tip, Accent, like the original's blocks), a cream belly (Accent) with chevron
  speckles, folded wings with two light feather bars and back-swept tips, a short tail fan, orange feet with three talons.
  Learned on the way (user feedback): an iris marked Accent turns Neon in the rarity colour at Lv 20 and the pet looks
  startled — keep eyes off the Accent list; lids drooping at the outer ends or covering half the iris look sad / tired;
  thin triangle tufts read like the Cat's ears, the Owl needs the blocky corner plumes.
- *Panda* (done 2026-10-25, 42 parts): round black ears facing front (cylinders, dark grey insides), teardrop eye patches
  (a disc and a smaller one below-outside; tagged `Eye`, no longer Accent, so they stay black at Lv 20), dark brown eyes
  with a grey rim that reads on the patch and two catchlights, an off-white raised muzzle with a wide nose and a small "w"
  mouth, pink blush discs (Accent), the black shoulder band (Accent, as before), black legs and paws, a small white tail
  ball (the Panda still skips FlameTail), a bamboo sprig (two stalks, two nodes, two leaves) leaning by the left front paw.
- *Dragon* (done 2026-10-25, 65 parts; the Epic pet gets the most detail): gold horns in two segments curving back, lilac
  side fins, a narrow snout with a low slope on top (kept clear of the eyes), nostrils and two baby fangs, bat wings
  (membrane wedge, scallop, bone, gold claw), three gold back spikes, a lilac belly with plate lines, a thick three-segment
  tail with a gold spade; gold parts and the belly are Accent as before. Eyes ("wide slit", picked from seven options):
  dark-purple rim, gold outer and fire-orange inner iris, a vertical capsule pupil 0.15 wide (a narrow slit looked cold,
  the first amber ring with a small round pupil and a brow floating above it looked surprised), two catchlights, a brow
  ridge resting on the rim (outer end 4° up).
- *Phoenix* (done 2026-10-25, 65 parts): the first stud version read as a chicken (upright crest fan = a rooster's comb,
  small down-pointing beak, wings folded flat, stubby tail). The firebird: raised wings of four long feathers fanned up,
  out and back from each shoulder (gold Neon on top down to deep red), three thin crest plumes swept back over the head
  with glowing orbs, a long tail of three plumes sweeping back and down and curling up into glowing orbs plus two short red
  ones, a hooked raptor beak sticking forward, a three-point feather breastplate, the Cat's eye layout in fire colours with
  a gold flick up from the outer corners, gold feet with darker talons. Neon / Accent parts as on the original (crest,
  gold wing feather, tail plumes). It is bigger than the others: bounding box 2.9 × 3.0 × 4.2 at Lv 1 (old 2.3 × 2.8 × 3.5),
  4.6 × 4.8 × 6.8 at Lv 20; the formation spaces by the box, the garden pen fit at Lv 20 is not checked yet.
- *Eyes grow slower than the pet* (`PetLook` `EYE_GROWTH = 0.5`, every kind): at Lv 20 the body is ×1.6, the eyes ×1.3
  (fully growing eyes looked intense, fixed-size eyes too small). Parts with the Studio attribute `Eye = true` (eyes, rims,
  pupils, shines, Owl rings, Panda patches) are shrunk back after `ScaleTo` as one group around the point between the eyes on
  the face, so their spacing grows like the eyes (shrinking each eye alone would push the pair apart). New eye parts need
  the attribute; eyes must sit on the front (−Z) of the head.

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

1. **P1e1 - PetLook foundation + size growth (done).** Deviations from this plan: slot gap 0.6 (not 0.5); `PetLook.Slots` also
   scales the distance behind the owner and lifts large pets; a run mode (4 studs back, >= 0.6 transparency while the owner's
   stage timer runs) was added after the first visual check. Details: ROADMAP P1e1 at f27c0b7. New `PetLook` module with `Scale` / `Tier` / `Apply`; `PetFollow` and
   `makePenPet` both use it (removes the duplicated model/label/glow code); size 1.0 -> 1.6 by level; formation spacing from
   the scaled width; camera fade. Attribute becomes `Kind:Level:uid` (parser also accepts the old form) because the next two
   steps need the pet id. Studio: none. User check: pets visibly grow, three Lv 20 pets don't overlap, nothing blocks the view.
2. **P1e2 - Level-up moment (done, details in ROADMAP P1e2 at f27c0b7; pens show it too via `PetPenLevelUp`).** Level-up detection per uid in `PetFollow`; burst, ring, floating "Level N!" (visible to
   all nearby players); label tier badge; optional `PetLevelUpSound`. User check: finish a run with a pet near a threshold.
3. **P1e3 - Tier effects + accent tint (done, details in ROADMAP P1e3 at f27c0b7; deviations: the T2 glow disc under the pet became an updraft of rising sparks after the visual check, effects also switch off while the pet is >= 50 % transparent, pens animate via `PetPenFx`).** Trail / aura / orbiting motes / halo at Lv 5 / 10 / 15 / 20 in the rarity colour,
   accent parts ramp to the rarity colour (Neon at Lv 20), livelier bob, distance LOD, cost check for 12 players.
   Studio: `Accent = true` on accent parts of the 8 models (one script). User check: how each tier looks.
4. **P1e4 - Individuality (done, details in ROADMAP P1e4 at f27c0b7; deviations after the user's visual check: larger jitter than first planned, white / grey parts get a seeded pastel tint, and a material texture that spreads with the level was added).** `Seed(uid)` jitter so same kind and level differ; unit-checked
   determinism. The attribute format and the model reuse key already carried the uid since P1e1.
5. **P1f - Accessory kit (done, details in ROADMAP P1f at f27c0b7; deviations: no halo piece because of the P1e3 tier halo, flame tail also on Phoenix, pieces are included in the bounding box / metrics).** Crown, scarf, small wings, horns, flame tail built in code from `Head` / `Body` / `Tail*`;
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
