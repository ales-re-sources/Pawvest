# Potato growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../PLANT_GROWTH.md#crops-and-status)

## Selected design

**Fuller upright foliage with later decorative berries.** Flat studies were rejected: the plant needs several unequal upright shoots and
broad paired leaflets at different heights (real height 30-50 cm; game proportions judged on the field).

[Plant reference](../art/potato/reference.png) · [Anatomy](../art/potato/anatomy-reference.png) ·
[Flower reference](../art/potato/flower-reference.png) · [Selected studies](../art/potato/ripe-studies.jpg) ·
[Five growth poses](../art/potato/growth-poses.jpg) · [Harvest-size comparison](../art/potato/harvest-size.jpg)

| Growth | Pose |
|---|---|
| 0% | A small shoot breaks the soil. Unplanted square stays bare. |
| 20% | Two leaves begin to open from the shoot at different times. |
| 50% | Unequal stems rise; lateral stalks develop compound leaf pairs at successive nodes. |
| 75% | Canopy fills, upper white/yellow flowers open, brown tuber shoulders emerge at soil level. |
| 100% | One flower gives way to small green berries; leaves settle; brown tuber shoulders signal harvest. |

The exposed brown tuber tops are a readability shortcut; green berries are decorative and non-edible. Roots and stolons omitted. Annual:
harvest clears the plant. Seeds vary shoot heights, yaw, lean, leaflet sizes, whole-plant rotation. Harvested mass scales height and
tuber dimensions by its cube root; canopy width constrained to the square, tubers keep full mass scale and separation.

## Recipe

[`PotatoPlant.luau`](../../src/ReplicatedStorage/PotatoPlant.luau): **65 Parts** (42 foliage, six tuber, three flower stalk, 12 flower,
two berry); 36-square field 2 340. Mid detail: three green pieces and two ripe tuber tops (3-5 Parts); low detail hides crop art.
Nominal ring 2.95 studs, mass-scaled. Completed foliage freezes after 66% growth and the flower / stalk after 80% (backward seeks
invalidate the caches). Open: real phone, second client.
