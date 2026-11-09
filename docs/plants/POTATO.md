# Potato growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../ROADMAP.md)

## Selected design

Ales selected **A's fuller upright foliage with later decorative berries** (CG3, 2026-11-09). The first flat studies were rejected:
the plant needs several unequal upright shoots and broad paired leaflets at different heights. The supplied references establish
the branching habit and organ placement. Real-world height was described as 30–50 cm; game proportions are judged on the field.

[Plant reference](../art/potato/reference.png) · [Anatomy](../art/potato/anatomy-reference.png) ·
[Flower reference](../art/potato/flower-reference.png) · [Selected studies](../art/potato/ripe-studies.jpg) ·
[Five growth poses](../art/potato/growth-poses.jpg)

## Growth and harvest

| Growth | Pose |
|---|---|
| 0% | A small shoot breaks the soil. An unplanted square stays bare. |
| 20% | Two leaves begin to open from the shoot at different times. |
| 50% | Unequal stems rise; lateral stalks develop compound leaf pairs at successive nodes. |
| 75% | The canopy fills, upper white/yellow flowers open and brown tuber shoulders emerge at soil level. |
| 100% | One flower gives way to small green berries; leaves settle and the brown tuber shoulders signal harvest. |

The exposed brown tuber tops are an intentional readability shortcut. Green berries are decorative and non-edible; they are not
the harvest crop. Roots and stolons are omitted from the standing plant. Potato is an annual: harvest clears the whole plant.
Its production duration stays **ten seconds**, with posing at **5 Hz** through the shared scheduler.

Stable seeds vary shoot heights, yaw, lean, leaflet sizes and whole-plant rotation. Harvested mass scales height and tuber dimensions
by its cube root. Canopy width is constrained to the square; the brown tubers retain their full mass scale and separation.
[Harvest-size comparison](../art/potato/harvest-size.jpg)

## Recipe

[`PotatoPlant.luau`](../../src/ReplicatedStorage/PotatoPlant.luau) is registered in `PlantGrowth` (CG3c / CG4).
The full model reuses **65 Parts**: 42 foliage, six tuber, three flower stalk, 12 flower and two berry pieces.
A 36-square field uses 2,340 plant Parts before soil, pets or UI. Mid detail uses three green pieces and two ripe tuber tops
(3–5 Parts); low detail hides crop art. Nominal ring height is 2.95 studs, scaled with mass.

Completed foliage freezes after 66% growth and the retained flower/stalk after 80%; backward seeking invalidates the caches.
Desktop CPU tuning is implemented; real-phone and second-client validation remain open.
