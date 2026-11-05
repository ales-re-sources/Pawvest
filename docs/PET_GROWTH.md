# Pet looks (PetLook) — reference

How a pet's look is derived and how pet models are authored. Built in P1e1-P1g (done; the player-facing description is GDD §7.5). The original
plan, findings and per-kind modelling notes: `git show 87b1d3c:docs/PET_GROWTH.md`.

## Principle
A pet's look is a pure function of **(kind, level, uid)** (level = pet level 1-10 = its highest shown trait level, `PetConfig.PetLevel`, P4) applied to the part-built model `ReplicatedStorage.PetModels[kind]`, in layers (size,
tint, tier effects, accessories, life). Nothing about the look is stored or replicated: every client derives it from `EquippedPets`
(`Kind:Level:uid`, `PetFollow`) or the plot feed (`PlotView`). `PetLook.Apply(model, kind, level, uid)` is the one entry point, so followers,
garden pets and the pet page always match. A pet without a uid (old `Kind:Level` form) gets no individuality and no accessories.

## Layers (`PetLook.luau`, numbers in `PetConfig`)
- **Size:** `Scale(level)` = 1 → `MaxScale` 1.6 linearly over levels 1-10 (P4; were 1-20, the look was downscaled proportionally) (`model:ScaleTo`; label offset from the bounding box afterwards).
  Eyes grow at half that rate (`EYE_GROWTH = 0.5`): parts with `Eye = true` shrink back after `ScaleTo` as one group around the point between
  the eyes, so their spacing grows like the eyes.
- **Tier:** `Tier(level)` 0-4 at Lv 3 / 5 / 8 / 10 (`PetConfig.Tiers`, P4); the label shows one ★ per tier. Effects in the rarity colour,
  cumulative: T1 sparkle trail, T2 soft aura + underglow, T3 orbiting motes, T4 hexagonal halo + stronger aura. Off beyond ~60 studs.
- **Tint:** parts with `Accent = true` drift toward the rarity colour with the level and turn Neon at Lv 10; body parts only get the seed jitter.
- **Individuality:** `Seed(uid)` gives a deterministic variant (hue / saturation / value jitter of the body, a tint for white / grey parts,
  60 % of Bunnies a grey to near-black coat, about half the pets a material texture spreading with the level up to 45 % of the parts). Accents
  and effects use the pet's own shade of its rarity colour (`FxColor`); the label keeps the exact rarity colour.
- **Accessories:** none below Lv 5 (tier 2), one at Lv 5-9, two at Lv 10, picked from the kind's candidates by the seed (the Lv 5 piece stays).
  Kit: Crown, Scarf, Wings, Horns, FlameTail, built in code from the model's `Head` / `Body` / `Tail` and the bounding box, in a Folder
  `Accessories`. Skip rules in `ACCESSORIES[id].skip` (Crown: Bunny / Fox / Phoenix; Scarf: Dog; Wings: Dragon / Phoenix / Owl; Horns: Dragon /
  Owl / Phoenix; FlameTail: Owl / Panda); Crown + Horns never together. Every kind needs at least two candidates. Built before the bounding box
  is taken, so spacing, label and halo include them.
- **Level-up moment:** `PetFollow` sees the same uid at a higher level (a rise of its best trait) → `PetLook.LevelUp` (spin, flash, sparks, ring, "Level N!"), for every
  viewer in range; sound from the Studio-only `ReplicatedStorage.PetLevelUpSound` if present.
- **Formation and camera:** slot spacing from the largest scaled width; pet parts closer than ~7 studs to the camera fade
  (`LocalTransparencyModifier`); during a run the pets drop back and turn ghostly.
- All created parts: Anchored, CanCollide / CanTouch / CanQuery off, Massless.

## Authoring a pet model (Studio-only, `ReplicatedStorage.PetModels`)
- **Names PetLook relies on:** `Root` (invisible PrimaryPart, front = −Z), `Head`, `Body`, `Tail*`; parts flat under the Model, anchored, no
  welds. Eyes sit on the front of the head.
- **Attributes:** `Accent = true` on the level-tinted parts (stripes, ear insides, tips, belly); `Eye = true` on eyes, rims, pupils, shines and
  eye patches. **Never mark eyes Accent:** a Neon iris at Lv 10 looks startled.
- **Stud look (P1g recipe):** stud texture (Material `Plastic` + MaterialVariant `StudsSmall` from `MaterialService.StudPack`) only on the big
  main-colour parts; small or white parts stay SmoothPlastic (the texture reads as a waffle there); no cylinder studs. Detail from shaped parts
  (wedge ears, face masks, sloped muzzles, round eyes with catchlights, tapering tail segments), about 40-65 parts per pet. A variant's
  `material` replaces the Material on some big parts and so drops their stud texture (intended).
- **Lessons (user feedback):** eyes need a big pupil and catchlights (slit pupils and small irises looked threatening or cold); lids drooping
  at the outer ends look sad; a kind's silhouette must not read as another animal (the first Phoenix read as a chicken, thin Owl tufts as cat
  ears). The user checks looks visually; MCP checks are structural.
- After changing a model: check the Lv 10 bounding box against the formation and a field square (the Phoenix is the largest, 4.6 × 4.8 × 6.8
  at Lv 10).
