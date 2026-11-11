# Frost Grape growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../ROADMAP.md)

## Selected design

Ales selected **B, the vineyard trellis**, then required the mature plant to be taller than the player (CG5, 2026-11-09).
Two rigid posts and rails support a woody climbing vine, lobed teal leaves and three tapered blue-violet bunches with pale frost
facets. The repeated row silhouette distinguishes this rare crop from the short food bushes. Keep fruit separated below the canopy.

The approved reference has a **7.43-stud living canopy** beside a 5.39-stud R15 avatar on the same soil plane. Posts stay **7.4 studs**
tall. Every mature seed and harvest-size extreme must retain a living-canopy top of at least **7.1 studs** and fit the square.
Raise the cane and support rather than stretching berries or leaves. The support keeps field-row alignment and does not scale with mass.

[Vine/leaf reference](../art/frost-grape/young-reference.png) · [Bunch detail](../art/frost-grape/detail-reference.png) ·
[Training reference](../art/frost-grape/training-reference.png) · [Selected B with avatar](../art/frost-grape/selected-b.jpg) ·
[Five growth poses](../art/frost-grape/growth-poses.jpg)

## Growth and harvest

| Growth | Pose |
|---|---|
| 0% | Full-sized support is installed; a shoot begins emerging at its foot. An unplanted square stays bare. |
| 20% | The shoot climbs the lower pole and small lobed leaves unfold. |
| 50% | Successive cane segments rise; lateral shoots extend along the support. |
| 75% | The upper canopy opens and green-blue bunches develop below it at attached stalks. |
| 100% | Heavy violet bunches hang visibly; berries swell, stalks dip and pale frost facets develop. |

Seed 1 at standard mass reproduces the selected ripe B. Other seeds vary cane bends, leaf angles/size, berry proportions, bunch size
and hanging offset. Harvested mass changes grapes while mature height and rigid support remain tall.

**Current status:** Ales approved the motion and the design; the recipe is registered in `PlantGrowth` (CG5c, 2026-11-11). The
eight-hour crop duration and existing square-clearing harvest contract are unchanged. CG5d performance, real phone and second
client remain open. Fruit-only perennial harvesting remains future gameplay, not a side effect of this art recipe.

**Frost particles (Ales, 2026-11-11).** From 90% growth each bunch's middle berry carries a `FrostFlecks` ParticleEmitter (4/s,
pale-ice sparkles, 1.8-2.8 s life, slowly falling, not locked to the Part). It switches off and clears on a backward seek.
`PlayHarvest` emits a 26-fleck falling burst at the bunches for the owner's successful harvest only. Particles never run in
mid/low detail.

**Mid proxy (8 / 34 / 34 Parts for stage 1 / 2 / 3):** posts and rails, cane, arms, a stalk and one blade per leaf, and a stalk
plus two tapered blocks per bunch (`Fruit` role with slot id). The frost facets are omitted at mid distance.

## Recipe and fruit identity

[`FrostGrapePlant.luau`](../../src/ReplicatedStorage/FrostGrapePlant.luau) reuses **115 Parts**: four support, 48 structure/foliage
and 63 fruit pieces. A 36-square field at full detail would use 4,140 plant Parts before soil, pets or UI; this is not a phone budget
approval. Supports are created once; leaf poses and unchanged properties are cached. `FixedOrientation` and `FixedRingHeight` are
enabled. Ring height is 8.1 studs and `ReviewHeight` is 7.6.

Each instance exposes `fruitSlots[1..3]`. Each slot has a stable `id`, seeded mature world-space stalk `attachment` and 21 `parts`:
18 blocks forming nine berries, two frost facets and the bunch stalk. Local `PlantRole` and `FruitSlot` attributes identify them.
Attachments and IDs survive seeks and mass changes. Future fruit-only collection must retain structure and reset separate fruit
cycles at these slots. The three visual bunches do not define reward quantity or collection granularity.
