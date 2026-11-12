# Giant melon growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../ROADMAP.md)

## Selected design (CG19a, 2026-11-12)

Ales chose **B, the arching vine**, with one rule: **no flower may grow on or above the melon.** (In the study the flower sat on the
fruit's top.) Both flowers now sit on the left of the arch, behind and beside the blossom end; the geometry check below tests it.

Crop facts: Giant melon is the 14th ladder crop (12 h, 15 kg, sale 450 000; `CropConfig` id `GiantMelon`, letter `d`, annual: harvest
clears the whole plant). Like Pumpkin, the **fruit** is the headline. The three static studies below are the decision record.

**How it gets "giant":** by scale against the player, not by a trick. The fruit is the biggest in the garden: about **4.6 studs long
and 2.8 high** (Pumpkin is 2.6 wide, 1.7 high), roughly twice a pumpkin's volume and half the 5.46-stud avatar's height, lying
on the ground like a real watermelon. Cube-root mass scaling plus the 2.4-stud ground radius clamp the largest harvests.

**Final fruit colour:** striped watermelon green, not orange: alternating dark-green (`26,86,46`) and light-green (`142,202,104`)
lengthwise stripes, a pale-yellow ground spot on the lower flank (`238,208,100`) and a dark blossom-end scar. Cut-open red flesh
stays out of the plant (a split-melon harvest effect is an optional later `PlayHarvest`). Ripeness cues: the stripes darken and
contrast, the ground spot turns creamy, and the stem plus the tendril beside it dry to brown (as in the infographic and as
Pumpkin's stem does).

Shared rules for all three: free-standing, **fixed orientation** (spot and stem face the player), fixed ring height, one fruit
slot (`PlantRole` `Fruit`), deeply lobed leaves (five narrow lobes) so it differs from Pumpkin's broad scalloped leaves, yellow
flowers, curled tendrils, canopy inside the 2.4-stud ground radius at every age. The fruit is eight lengthwise stripe ribs around
its axis, each a long middle block and two narrower end blocks (24 Parts).

[Static ripe studies A / B / C](../art/melon/ripe-studies.jpg) (the blue bar is the 5.46-stud avatar; standard mass;
`tools/melon_ripe_studies.luau`):

| | Silhouette | Reads as | Height | Parts |
|---|---|---|---|---|
| **A, ground giant** | 4.6 × 2.8-stud striped melon lying in front, a low runner with six lobed leaves on short petioles behind and beside it | the real watermelon patch: a boulder of a fruit | about 2.8 studs | 85 |
| **B, arching vine** | 3.3-stud round melon at the front, Pumpkin's arch (about 4.2 studs) with lobed leaves | the pumpkin silhouette with a new fruit | about 4.2 studs | 87 |
| **C, trellis sling** | 3.6-stud melon hanging in a rope sling tied to a ladder trellis (4.8 studs), vine climbing the post | cucumber's ladder carrying a fruit far too heavy for it | about 4.8 studs | 97 |

**Recommendation was A; Ales chose B.** Original reasoning: The fruit is unobscured and reads as the giant it is; the rigid trellis and the arch (B, C) reuse existing
silhouettes and shrink the fruit's share of the picture. A's weakness is its low height (it can blend with Potato and Lettuce rows
at phone distance), which the striped 4.6-stud fruit offsets; if that reads too flat, B is the fallback. Open for the choice: A's
fruit nearly fills the 2.4-stud ground radius, so heavy harvests clamp to about 4.6 studs long and light ones shrink to about 3.

Note: the reference screen of the watermelon life cycle mentioned in the request was not attached to the session, so the stages
below follow the pumpkin infographic's structure and the standard watermelon cycle.

## Proposed growth (applies to A / B / C)

| Growth | Pose |
|---|---|
| 0% | Germination: a pale seed shell on the soil, one curved green shoot. |
| 20% | Two oval cotyledons, then the first lobed true leaf. |
| 50% | The runner extends with tendrils; larger lobed leaves; a first yellow flower. |
| 75% | Flowers open; a small pale-striped melon sets at the stem. |
| 100% | The big striped melon sits on a ground spot; stem and nearest tendril are brown; leaves full. |

Timing: the vine extends base-first with overlapping timings (0-62%); the melon appears at 60%, swells to 98% and its stripes
darken from pale to final contrast 74-100%; the ground spot fades in 66-76% and turns creamy; the stem, the dry tendril and the
upper vine turn brown from 84-86% (the ripeness cue). Flowers open 44-62% and wilt by 90%. A 43→44→43% seek restores the same
pose. Seeded variation: fruit yaw and position, leaf yaw / tilt / size, vine bends, flower offsets. Production duration stays
**twelve hours**.

## Recipe and status

[`GiantMelonPlant.luau`](../../src/ReplicatedStorage/GiantMelonPlant.luau), built on `PlantKit.recipe`: **97 Parts** (seed shell 1,
cotyledons 2, vine 6, leaves 6 × 6, flowers 2 × 7, tendrils 2 × 3, fruit 24 stripe blocks + ground spot + scar + 3 stem rods,
dry tendril 3), so a 36-square field uses 3,492 plant Parts before soil, pets or UI. **Registered in `PlantGrowth`** (art approved by
Ales 2026-11-12; CG19c). Free-standing, **fixed orientation**, fixed ring height 4.9,
review framing 4.2. One fruit slot (`fruitSlots[1]`: stripe blocks, spot, scar, stem rods).

- **Fruit:** eight stripe ribs around a horizontal axis (alternating dark `26,86,46` and light `142,202,104` when ripe), each a long
  middle block and two shorter end blocks. Standard 3.1 long × 2.7 wide (the footprint clamp trims the study's 3.3). Cube-root
  mass scaling, then the clamp: 2.4 long at the smallest mass, 3.3 at the largest, where the radius is capped (1.55) so a heavy
  melon gets longer, not taller, and stays under the arch. The fruit slides toward the centre with mass.
- **Vine and leaves:** six rods in Pumpkin's arch (leaf tops about 4.5 studs); six five-lobe leaves, each clamped to the 2.4 radius
  by its real corners; no leaf lies on the fruit's side. The vine tip sits above the melon's stem end and the stem hangs from it.
- **Mid proxy** (from the same geometry): three lobes per leaf, the middle stripe blocks only, ground spot, stem; no flowers or
  tendrils: **14 / 42 / 42 Parts** for young / growing / ripe. Nothing at low detail. No harvest effect (`PlayHarvest` is nil).

Studio validation (2026-11-12): [`giant_melon_growth_checks.luau`](../../tools/giant_melon_growth_checks.luau), six seeds × three
harvested masses (0.357 / 1 / 3.03) × 101 ages: 97 Parts, maximum ground radius **2.38 studs**, top **4.54**, exact visible
backward seeks (43 → 44 → 43%), and **no non-fruit Part (flower, leaf, vine, tendril) inside the melon from 50% on**. Playtest boot clean.
[Five stills](../art/melon/growth-review.jpg) (0/20/50/75/100%, seed 1, standard mass, Edit-mode side by side, not the reviewer) ·
[75% and ripe detail](../art/melon/growth-75-100-detail.jpg), approved by Ales (2026-11-12).

Field integration (2026-11-12): [`giant_melon_integration_checks.luau`](../../tools/giant_melon_integration_checks.luau) passed through
the production `PlotView` with disposable public-feed fixtures and no remotes or profile writes: three recipes build 291 Parts; a
server-time correction keeps the same plant, soil and pet; the exact ripe moment is not missed and a backward correction clears the
ripe state; the soil selection ray is not blocked; full → mid → low → full keeps the seed's identity; harvest clears the square and a
replant starts young; the 12 h crop is sampled every 30 s (the cap). Playtest boot clean (server and client).
Open: performance (full field and the 24-plot route), real phone, second client.
