# Pumpkin growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../ROADMAP.md)

## Selected design (CG15, 2026-11-11)

Ales chose **B, the arching vine**, with the fruit made **30% bigger** (2.0 → 2.6 studs). The study table and the options below
are kept as the decision record.

References from Ales: a [life-cycle infographic](../art/pumpkin/reference-life-cycle.webp) (seed, germination, cotyledons, true
leaves, a running vine with tendrils, yellow flowers, a small green fruit, an orange ribbed pumpkin, brown dry vine at harvest) and a
[ripe patch photo](../art/pumpkin/reference-ripe-patch.webp) (a squat, ribbed, orange fruit under large scalloped leaves held up on
long petioles, with a yellow flower).

Crop facts: Pumpkin is the 10th ladder crop (3 h, 6 kg, annual: harvest clears the whole plant). It is the first crop where the
**fruit** is the headline, so ripeness must read from the orange ribbed fruit, not from a flower or a fold.

Shared rules for all options: free-standing, **fixed ring height** (the fruit scales, the vine does not), cube-root mass scaling
on the fruit only, a constrained leaf factor, canopy inside the 2.4-stud ground radius at every age and mass, `PlantRole`
`Fruit` on the pumpkin (one fruit slot) and `Foliage` / `Structure` elsewhere. The fruit is eight ribs (two alternating oranges),
each rib a belly, shoulder and foot block so the profile bulges like a squat pumpkin, topped by a curled, thick stem.

[Static ripe studies A / B / C](../art/pumpkin/ripe-studies.jpg) (the blue bar is the 5.46-stud avatar; seed-1 standard mass;
`tools/pumpkin_ripe_studies.luau`):

| | Silhouette | Reads as | Height | Parts |
|---|---|---|---|---|
| **A, patch canopy** | 2.1-stud fruit at the front, vine on the ground, seven big leaves on raised petioles forming a canopy over and behind the fruit, one yellow flower | the photo reference: a pumpkin hiding under its leaves | about 2.4 studs | 85 |
| **B, arching vine** | 2.0-stud fruit at the front, a stout vine arching up and over (about 4 studs) with five broad leaves, two yellow flowers and three tendril curls | the infographic's looping vine; a distinct tall silhouette among the low crops | about 4.2 studs | 93 |
| **C, giant fruit, low runner** | 2.6-stud fruit centred, flat leaves low on a runner, brown dry vine and stem, no flowers | the "giant" crop (6 kg); the dry vine is the harvest cue | about 1.6 studs | 70 |

**Recommendation: B.** The arch keeps the fruit unobscured and gives Pumpkin a readable row silhouette at phone distance, where a
low ground crop (A, C) would blend with Potato and Lettuce; it also maps directly to the infographic's life cycle (curling vine
at 50%, flowers at 75%). A is the most naturalistic; C is the weakest cue at distance. Open points for B: the arch's height versus
the avatar, and whether two flowers are one too many once the fruit is orange.

## Proposed growth (applies to A / B / C; pose details follow the chosen study)

| Growth | Pose |
|---|---|
| 0% | Germination: a pale seed shell on soil with one curved green shoot. An unplanted square stays bare. |
| 20% | Two oval cotyledons, then the first true leaves on a short stem. |
| 50% | The vine runs and curls (arch rising for B), larger leaves, tendrils start to coil. |
| 75% | Yellow flowers open; a small green striped fruit swells at the base of the stem. |
| 100% | The fruit is large, ribbed and orange; leaves are full; the vine nearest the fruit turns brown (the ripeness cue). |

Timing: the vine extends base-first with overlapping timings, the fruit swells 62-100% and turns from green to orange 80-100%.
A 43→44→43% seek must restore the same pose. Seeded variation: fruit yaw and rib tilt, leaf size and yaw, vine bends,
flower count and placement. Production duration stays **three hours** (posed every 22.5 s).

## Recipe and status

[`PumpkinPlant.luau`](../../src/ReplicatedStorage/PumpkinPlant.luau), built on `PlantKit`: **96 Parts** (seed shell 1, seed leaves 2,
vine 7, leaves 6 × 6, flowers 2 × 7, tendrils 3 × 3, fruit 24 ribs + 3 stem rods), so a 36-square field uses 3,456 plant Parts
before soil, pets or UI. Registered in `PlantGrowth`; free-standing but **fixed orientation** (the fruit always faces the player's
side of the arch); fixed ring height 4.9; review framing 4.2. One fruit slot (`fruitSlots[1]`: the 24 ribs and 3 stem rods).

- **Fruit:** eight ribs, each a belly, shoulder and foot block, alternating two oranges (two greens while young). Standard width
  2.6 studs, height 0.66 × width. Cube-root mass scaling: 1.84 studs at the smallest mass, 3.24 at the largest. The fruit centre
  slides toward the middle (and the width is clamped) so fruit, vine and leaves stay inside the 2.4-stud ground radius.
- **Vine and leaves:** seven rods rise in an arch to about 3.4 studs and end at the fruit stem; six five-plate leaves (the centre
  plate's far corner reaches 0.99 × scale from the hinge, so each leaf is clamped by its hinge radius). Two yellow flowers open at
  50-66% and wilt by 90% as the fruit sets. Three tendrils curl.
- **Timing:** vine segments overlap from 0 to 62%; the fruit appears at 62% on a hanging stem and swells to 98%, green to orange
  from 74%; the stem and the upper vine turn brown from 84-86% (the ripeness cue, as in the infographic).
- **Mid proxy:** vine rods, a petiole and one blade per leaf, one disc per flower, a two-box belly and two-box shoulder, one stem
  rod: **5 / 26 / 24 Parts** for young / growing / ripe. Nothing at low detail. No harvest effect (`PlayHarvest` is nil).

Studio validation (2026-11-11): six seeds × three harvested masses (0.357 / 1 / 3.03) × 101 ages: maximum ground radius **2.39
studs**, top **4.47**, exact visible backward seeks (43 → 44 → 43%), all 96 Parts retained. Production `PlotView`
([`pumpkin_integration_checks.luau`](../../tools/pumpkin_integration_checks.luau)) with disposable public-feed fixtures and no
remotes or profile writes: three recipes build 288 Parts; a server-time correction keeps the same plant, soil and pet; the exact
ripe moment is not missed and a backward correction clears the ripe state; the soil selection ray is not blocked; full → mid → low
→ full keeps the seed's identity; harvest clears the square and a replant starts young; the 3 h crop is sampled every 22.5 s.
Playtest boot clean. [Five stills](../art/pumpkin/growth-review.jpg) · [ripe and 75% detail](../art/pumpkin/growth-ripe-detail.jpg)
await Ales's review. Open: performance (full field and the 24-plot route), real phone, second client.
