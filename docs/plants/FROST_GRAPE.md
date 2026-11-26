# Frost Grape growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../PLANT_GROWTH.md#crops-and-status)

## Selected design

**Vineyard trellis**, with the mature plant required to be taller than the player: two rigid posts and rails support a woody climbing
vine, lobed teal leaves and three tapered blue-violet bunches with pale frost facets. The repeated row silhouette distinguishes this rare
crop from the short food bushes; fruit hangs below the canopy.

Reference: **7.43-stud living canopy** beside a 5.39-stud avatar on the same soil plane; posts **7.4 studs**. Every mature seed and
size extreme keeps a living-canopy top of at least **7.1 studs** and fits the square: raise the cane and support, don't stretch berries or
leaves. The support keeps field-row alignment and does not scale with mass.
[Vine/leaf reference](../art/frost-grape/young-reference.png) · [Bunch detail](../art/frost-grape/detail-reference.png) ·
[Training reference](../art/frost-grape/training-reference.png) · [Selected design with avatar](../art/frost-grape/selected-b.jpg) ·
[Five growth poses](../art/frost-grape/growth-poses.jpg)

| Growth | Pose |
|---|---|
| 0% | Full-sized support installed; a shoot begins emerging at its foot. Unplanted square stays bare. |
| 20% | The shoot climbs the lower pole; small lobed leaves unfold. |
| 50% | Successive cane segments rise; lateral shoots extend along the support. |
| 75% | Upper canopy opens; green-blue bunches develop below it on attached stalks. |
| 100% | Heavy violet bunches hang; berries swell, stalks dip, pale frost facets develop. |

Seeds vary cane bends, leaf angles / size, berry proportions, bunch size and hanging offset; harvested mass changes grapes while
height and support stay tall. Existing square-clearing harvest; fruit-only perennial harvesting is future gameplay, not a side effect of
this recipe.

**Frost particles:** from 90% growth each bunch's middle berry carries a `FrostFlecks` ParticleEmitter (4/s, pale-ice sparkles, 1.8-2.8 s
life, slowly falling, not locked to the Part); off and cleared on a backward seek. `PlayHarvest` emits a 26-fleck falling burst at the
bunches for the owner's successful harvest only. Never in mid / low detail.

**Mid proxy 8 / 34 / 34 Parts** (stage 1 / 2 / 3): posts and rails, cane, arms, a stalk and one blade per leaf, a stalk plus two tapered
blocks per bunch (`Fruit` role with slot id); frost facets omitted.

## Recipe and fruit identity

[`FrostGrapePlant.luau`](../../src/ReplicatedStorage/FrostGrapePlant.luau): **115 Parts** (four support, 48 structure/foliage, 63 fruit);
36-square field 4 140. Supports created once; leaf poses and unchanged properties cached. `FixedOrientation`, `FixedRingHeight` (ring 8.1
studs), `ReviewHeight` 7.6. `fruitSlots[1..3]`: stable `id`, seeded mature world-space stalk `attachment`, 21 `parts` (18 blocks = nine
berries, two frost facets, the bunch stalk); `PlantRole` / `FruitSlot` attributes; ids and attachments survive seeks and mass changes.
Future fruit-only collection must keep structure and reset separate fruit cycles at these slots; the three bunches do not define reward
quantity or collection granularity. Open: performance (particles included), real phone, second client.
