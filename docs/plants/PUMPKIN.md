# Pumpkin growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../PLANT_GROWTH.md#crops-and-status)

## Selected design

**Arching vine** (chosen from three studies) with the fruit made 30% bigger (2.0 → 2.6 studs). References: [life-cycle infographic](../art/pumpkin/reference-life-cycle.webp),
[ripe patch photo](../art/pumpkin/reference-ripe-patch.webp) (squat ribbed orange fruit under large scalloped leaves on long petioles).

Stored id `Pumpkin` (6 kg nominal; annual: harvest clears the whole plant). First crop where the **fruit** is the headline:
ripeness reads from the orange ribbed fruit, not a flower or fold.

Rules: free-standing, **fixed ring height** (the fruit scales, the vine does not), cube-root mass scaling on the fruit only, constrained
leaf factor, canopy inside the 2.4-stud radius at every age and mass, `PlantRole` `Fruit` on the pumpkin (one fruit slot), `Foliage` /
`Structure` elsewhere. The fruit is eight ribs (two alternating oranges), each a belly, shoulder and foot block (squat profile), topped
by a curled thick stem.

Why B: the arch (~4 studs) keeps the fruit unobscured and gives a readable row silhouette at phone distance, where the low options
(A patch canopy ~2.4 studs, C giant fruit on a low runner ~1.6 studs) blend with Potato and Lettuce rows ([studies](../art/pumpkin/ripe-studies.jpg),
`pumpkin_ripe_studies.luau`). Open: the arch height against the avatar, and whether two flowers are one too many once the fruit is orange.

## Growth

| Growth | Pose |
|---|---|
| 0% | Pale seed shell on soil with one curved green shoot. Unplanted square stays bare. |
| 20% | Two oval cotyledons, then first true leaves on a short stem. |
| 50% | Vine runs and curls (arch rising), larger leaves, tendrils start to coil. |
| 75% | Yellow flowers open; a small green striped fruit swells at the base of the stem. |
| 100% | Large ribbed orange fruit; leaves full; the vine nearest the fruit turns brown (the ripeness cue). |

Vine segments overlap from 0 to 62%; fruit appears at 62% on a hanging stem, swells to 98%, green → orange from 74%; stem and upper vine
turn brown 84–86%. Two flowers open 50–66%, wilt by 90%. Seeded variation: fruit yaw and rib tilt, leaf size and yaw, vine bends,
flower count and placement. 43→44→43% seek restores the pose. Grow time: `CropConfig`.

## Recipe

[`PumpkinPlant.luau`](../../src/ReplicatedStorage/PumpkinPlant.luau), `PlantKit`: **96 Parts** (seed shell 1, seed leaves 2, vine 7,
leaves 6 × 6, flowers 2 × 7, tendrils 3 × 3, fruit 24 ribs + 3 stem rods); 36-square field 3 456. Registered; **fixed orientation** (the
fruit faces the player's side of the arch); ring fixed 4.9, review framing 4.2. One fruit slot `fruitSlots[1]` (24 ribs + 3 stem rods).

- **Fruit:** standard width 2.6 studs, height 0.66 × width; cube-root mass scaling 1.84 (smallest) to 3.24 (largest); the fruit centre
  slides toward the middle and the width is clamped to keep fruit, vine and leaves inside the radius (max 2.39).
- **Vine and leaves:** seven rods arch to ~3.4 studs and end at the fruit stem; six five-plate leaves, each clamped by its hinge radius
  (centre plate far corner 0.99 × scale from the hinge); three tendrils curl.
- **Mid proxy:** vine rods, petiole and one blade per leaf, one disc per flower, two-box belly and shoulder, one stem rod: **5 / 26 / 24
  Parts**. Nothing at low detail. No harvest effect (`PlayHarvest` nil).

Top 4.47 studs max. Checks: `pumpkin_integration_checks.luau` and the growth checks (six seeds × masses 0.357 / 1 / 3.03 × 101 ages).
Five stills (2026-11-28, seed 1, ×1.00): [0%](../art/pumpkin/growth-0.jpg) · [20%](../art/pumpkin/growth-20.jpg) · [50%](../art/pumpkin/growth-50.jpg) · [75%](../art/pumpkin/growth-75.jpg) · [100%](../art/pumpkin/growth-100.jpg), approved by Ales (2026-11-28).
Open: performance (full field, 24-plot route), real phone, second client.
