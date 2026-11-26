# Giant melon growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../PLANT_GROWTH.md#crops-and-status)

## Selected design

**Arching vine** (chosen from three studies) with one rule: **no flower may grow on or above the melon** (both flowers sit left of the
arch, behind and beside the blossom end; the growth check tests it).

Stored id `GiantMelon`, plot letter `d`, 15 kg nominal; annual, harvest clears the whole plant. Like
Pumpkin the **fruit** is the headline: biggest in the garden, "giant" by scale against the avatar (5.46 studs), lying on the ground like
a real watermelon. Cube-root mass scaling plus the 2.4-stud radius clamp the largest harvests.

**Fruit colour:** striped watermelon green: alternating dark-green (`26,86,46`) and light-green (`142,202,104`) lengthwise stripes, a
pale-yellow ground spot on the lower flank (`238,208,100`), dark blossom-end scar. No cut-open red flesh in the plant (a split-melon
`PlayHarvest` is an optional later effect). Ripeness cues: stripes darken and contrast, the spot turns creamy, the stem and nearest
tendril dry to brown (as Pumpkin's stem does).

Shared rules: free-standing, **fixed orientation** (spot and stem face the player), fixed ring height, one fruit slot (`PlantRole`
`Fruit`), deeply lobed leaves (five narrow lobes; differs from Pumpkin's broad scalloped ones), yellow flowers, curled tendrils, canopy
inside the 2.4-stud radius at every age.

Rejected ([studies](../art/melon/ripe-studies.jpg), `melon_ripe_studies.luau`): **A ground giant** (4.6 × 2.8-stud melon in front of a
low runner; the best giant read, but only ~2.8 studs tall, may blend with Potato / Lettuce rows at phone distance; fallback if B reads
poorly) and **C trellis sling** (melon in a rope sling on a ladder trellis, 4.8 studs). Chosen B: round melon in front, Pumpkin's arch
(~4.2 studs) with lobed leaves.

## Growth

| Growth | Pose |
|---|---|
| 0% | Pale seed shell on the soil, one curved green shoot. |
| 20% | Two oval cotyledons, then the first lobed true leaf. |
| 50% | Runner extends with tendrils; larger lobed leaves; first yellow flower. |
| 75% | Flowers open; a small pale-striped melon sets at the stem. |
| 100% | Big striped melon on a ground spot; stem and nearest tendril brown; leaves full. |

Vine extends base-first, overlapping (0–62%); melon appears at 60%, swells to 98%, stripes darken from pale 74–100%; spot fades in 66–76%
and turns creamy; stem, dry tendril and upper vine turn brown from 84–86% (the ripeness cue). Flowers open 44–62%, wilt by 90%. Seeded
variation: fruit yaw and position, leaf yaw / tilt / size, vine bends, flower offsets. 43→44→43% seek restores the pose.

## Recipe

[`GiantMelonPlant.luau`](../../src/ReplicatedStorage/GiantMelonPlant.luau), `PlantKit.recipe`: **97 Parts** (seed shell 1, cotyledons 2,
vine 6, leaves 6 × 6, flowers 2 × 7, tendrils 2 × 3, fruit 24 stripe blocks + ground spot + scar + 3 stem rods, dry tendril 3); 36-square
field 3 492. Ring fixed 4.9, review framing 4.2. One fruit slot `fruitSlots[1]`.

- **Fruit:** eight stripe ribs around a horizontal axis, each a long middle block and two shorter end blocks. Standard 3.1 long × 2.7
  wide (footprint clamp; the study was 3.3). Cube-root mass scaling, then the clamp: 2.4 long at the smallest mass, 3.3 at the largest,
  radius capped at 1.55 so a heavy melon gets longer, not taller, and stays under the arch; it slides toward the centre with mass.
- **Vine and leaves:** six rods in Pumpkin's arch (leaf tops ~4.5 studs); six five-lobe leaves clamped to the radius by their real
  corners; no leaf lies on the fruit's side; the vine tip sits above the melon's stem end and the stem hangs from it.
- **Mid proxy:** three lobes per leaf, middle stripe blocks only, ground spot, stem; no flowers or tendrils: **14 / 42 / 42 Parts**.
  Nothing at low detail. No harvest effect (`PlayHarvest` nil).

Checks: `giant_melon_growth_checks.luau` (six seeds × masses 0.357 / 1 / 3.03 × 101 ages): max radius 2.38, top 4.54, and no non-fruit
Part inside the melon from 50% on; `giant_melon_integration_checks.luau`. Long crop sampled at the 30 s cap. Stills:
[five poses](../art/melon/growth-review.jpg), [75% and ripe detail](../art/melon/growth-75-100-detail.jpg). Open: performance (full
field, 24-plot route), real phone, second client.
