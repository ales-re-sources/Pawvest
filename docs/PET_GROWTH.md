# Pet looks (PetLook) — reference

How a pet's look is derived and how pet models are authored (the player-facing description is GDD §7.5).

## Principle
A pet's look is a pure function of **(kind, level, uid)** (level = pet level 1-`PetConfig.MaxLevel` (20) = its highest shown trait level, `PetConfig.PetLevel`) applied to the part-built model `ReplicatedStorage.PetModels[kind]`, in layers (size,
tint, tier effects, accessories, life). Nothing about the look is stored or replicated: every client derives it from `EquippedPets`
(`Kind:Level:uid`, `PetFollow`) or the plot feed (`PlotView`). `PetLook.Apply(model, kind, level, uid)` is the one entry point, so followers,
garden pets and the pet page always match. A pet without a uid (old `Kind:Level` form) gets no individuality and no accessories.

## Layers (`PetLook.luau`, numbers in `PetConfig`)
- **Size:** `Scale(level)` = 1 → `MaxScale` 1.6 linearly over levels 1-20 (`model:ScaleTo`; label offset from the bounding box afterwards).
  Eyes grow at half that rate (`EYE_GROWTH = 0.5`): parts with `Eye = true` shrink back after `ScaleTo` as one group around the point between
  the eyes, so their spacing grows like the eyes.
- **Tier:** `Tier(level)` 0-4 at Lv 5 / 10 / 15 / 20 (`PetConfig.Tiers`); the label shows one ★ per tier. Effects in the rarity colour,
  cumulative: T1 sparkle trail, T2 soft aura + underglow, T3 orbiting motes, T4 hexagonal halo + stronger aura. Off beyond ~60 studs.
- **Tint:** parts with `Accent = true` drift toward the rarity colour with the level and turn Neon at Lv 20; body parts only get the seed jitter.
- **Individuality:** `Seed(uid)` gives a deterministic variant (hue / saturation / value jitter of the body, a tint for white / grey parts,
  60 % of Bunnies a grey to near-black coat, about half the pets a material texture spreading with the level up to 45 % of the parts at Lv 20). Accents
  and effects use the pet's own shade of its rarity colour (`FxColor`); the label keeps the exact rarity colour.
- **Accessories:** none below Lv 10 (tier 2), one at Lv 10-19, two at Lv 20 (tier 4), picked from the kind's candidates by the seed (the first piece stays).
  Kit: Crown, Scarf, Wings, Horns, FlameTail, built in code from the model's `Head` / `Body` / `Tail` and the bounding box, in a Folder
  `Accessories`. Skip rules in `ACCESSORIES[id].skip` (Crown: Bunny / Fox / Phoenix; Scarf: Dog; Wings: Dragon / Phoenix / Owl; Horns: Dragon /
  Owl / Phoenix; FlameTail: Owl / Panda); Crown + Horns never together. Every kind needs at least two candidates. Built before the bounding box
  is taken, so spacing, label and halo include them.
- **Level-up moment:** `PetFollow` sees the same uid at a higher level (a rise of its best trait) → `PetLook.LevelUp` (spin, flash, sparks, ring, "Level N!"), for every
  viewer in range; sound from the Studio-only `ReplicatedStorage.PetLevelUpSound` if present.
- **Formation and camera:** slot spacing from the largest scaled width; a pet whose surface the camera comes within 5 studs of fades
  as a whole (`LocalTransparencyModifier` 0.8, back to solid beyond 6 studs, short tween: `FADE_ENTER` / `FADE_EXIT` in PetFollow, never a
  distance gradient, so the bob cannot toggle it and no half of a pet looks faded); during a run the pets drop back and turn ghostly.
- All created parts: Anchored, CanCollide / CanTouch / CanQuery off, Massless.

## Authoring a pet model (Studio-only, `ReplicatedStorage.PetModels`)
- **Names PetLook relies on:** `Root` (invisible PrimaryPart, front = −Z), `Head`, `Body`, `Tail*`; parts flat under the Model, anchored, no
  welds. Eyes sit on the front of the head.
- **Attributes:** `Accent = true` on the level-tinted parts (stripes, ear insides, tips, belly); `Eye = true` on eyes, rims, pupils, shines and
  eye patches. **Never mark eyes Accent:** a Neon iris at the max level looks startled. A shut eye (field pets' blink and nap,
  FieldPetIdle) hides the `Eye` parts named `Eye<n>`, `Pupil*`, `EyeShine*`, `EyeInner*`, `EyeGreen*`, `EyeRim*`, `EyeRing*`; other `Eye`
  parts (brows, patches, lids, lashes, facial discs) stay. `Blink = true / false` on a part overrides the name; a new eye part with
  another name needs one.
- **Stud look:** stud texture (Material `Plastic` + MaterialVariant `StudsSmall` from `MaterialService.StudPack`) only on the big
  main-colour parts; small or white parts stay SmoothPlastic (the texture reads as a waffle there); no cylinder studs. Detail from shaped parts
  (wedge ears, face masks, sloped muzzles, round eyes with catchlights, tapering tail segments), about 40-65 parts per pet. A variant's
  `material` replaces the Material on some big parts and so drops their stud texture (intended).
- **Lessons:** eyes need a big pupil and catchlights (slit pupils and small irises looked threatening or cold); lids drooping
  at the outer ends look sad; a kind's silhouette must not read as another animal (the first Phoenix read as a chicken, thin Owl tufts as cat
  ears).
- After changing a model: check the Lv 20 bounding box against the formation and a field square (the Phoenix is the largest, 4.6 × 4.8 × 6.8
  at the max level).
