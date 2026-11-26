# Eggplant growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../PLANT_GROWTH.md#crops-and-status)

## Selected design

**Tall open plant** (chosen by Ales from three static studies): tall leader, unequal upper arms, five broad lobed leaves (blades 1.85×
longer and wider than the first study, held upright on short petioles) and three long hanging aubergines. The young stem stays green
and turns purple midway through growth.

References: [life-cycle illustration](../art/eggplant/reference-life-cycle.png), [fruiting-plant photo](../art/eggplant/reference-ripe-plant.png).
Keep the upright branching habit, broad shallow-lobed leaves, green star-shaped calyxes, purple flowers with yellow centres and heavy
hanging aubergines. No trellis, exposed roots, ground rosette or chilli-shaped pointed fruit. Stud-block geometry: faceted, rounded
fruit with a narrow neck and full blunt lower belly, sparse violet facets rather than painted white shine stripes.

Stored id `Eggplant`; grow time and mass: `CropConfig`. Harvest clears the whole square; the explicit
fruit slots prepare future art / gameplay, they are not perennial harvesting.

Rejected variants: A "natural fork" (closest to the references, 4.44 studs, less upright) and C "compact heavy crop" (3.48 studs, least
height); see [static studies](../art/eggplant/ripe-studies.jpg), `eggplant_ripe_studies.luau`.

## Layout round the stem

The ripe plant was too flat (arms, leaves and fruit in one plane, thin fan from the side). Selected layout **cross fork**
([3D studies](../art/eggplant/3d-studies.jpg), `eggplant_3d_studies.luau`): left/right arms; one long fruit hangs forward, the other
back, the short one back-left; leaves fore and aft. Not a three-way V or a 137.5° spiral (less readable). Three leaves stand slightly
more upright and the right arm's leaf turns further to the front to keep the largest harvest inside the field radius. The recipe's
layout is one `LAYOUT` block: `P(r, azimuth°, rise)` offsets from the parent tip (azimuth 0 = +Z). Side arms bend about their own
horizontal axis under the fruit load, fruit hang outward with the pedicel crooking back toward the node, the top flower faces along its
arm; leaf roll is an explicit per-leaf value.

## Growth poses

[Five stills](../art/eggplant/growth-review-c.jpg).

| Growth | Pose |
|---|---|
| **0%** | Tiny shoot and two folded cotyledons at the soil. An unplanted square stays bare. |
| **20%** | Short green stem, two opened cotyledons, first broad true leaf. |
| **50%** | Main fork and unequal side shoots extend; large leaves unfold in alternating tiers. Stem / petioles midway green → purple. Violet five-petal flowers with yellow centres open at the future fruit attachments. |
| **75%** | Bush almost full. Petals curl and fade; calyxes stay green as small dusky-purple fruit lengthen beneath them (lower fruit leads). |
| **100%** | Three full deep-purple fruit hang from bent pedicels under green star calyxes. Leaves frame the fruit; loaded arms settle slightly. No brown / yellow overripe look. |

Overlapping phases: stem/branches 0–63%; true leaves 10–66%; flowers open 43–52%, contract 59–74%; fruit neck and length 62–88%; belly
74–100%; richer purple 70–96%; load settling 80–100%. The shorter central fruit starts 2.5 points later. The decorative top flower opens
46–57% and stays. Cotyledons fade 26–43%. Stems and petioles stay green through 35%, then go purple 35–65% (by plant age, not segment
extension). The violet fruit starts purple (no Pepper-style green → red sequence); ripeness reads from the full belly, length and dark
skin together. Calyx and stalk stay attached through the bend.

Growth extends from current parents; leaves hinge open from petioles; fruit lengthens from its neck before the belly fills. No perpetual
ripe sway or particle effect. Seed 1 is the authored baseline; seeds vary fork balance, stem lean, leaf yaw / fold, fruit bend, relative
lengths. Free-standing orientation over 360°. Harvested mass scales produce by its cube root; foliage vigor stays constrained; the
leader lifts for a larger harvest to keep long fruit off the soil.

## Recipe

[`EggplantPlant.luau`](../../src/ReplicatedStorage/EggplantPlant.luau), shared `PlantKit` rig, **113 Parts**: eight stem segments, two
cotyledons, five six-Part leaves, three 22-Part flower/fruit groups, a seven-Part top flower; 36-square field 4 068 Parts. Each
`fruitSlots[1..3]` holds a stable id, mature world-space attachment CFrame and its 22 grouped Parts; `PlantRole` separates structure,
foliage and fruit, `FruitSlot` identifies each fruit group (incl. spent blossom Parts). Seed 1: top 6.07 studs, ground radius 2.15;
first blade 2.71 × 2.17. Max radius over seeds / masses 2.37, ripe height 5.45–6.73 studs, min fruit clearance 0.39. Nominal ring fixed
at **7.2 studs**, review framing 6.5. Checks: `eggplant_growth_checks.luau` (six seeds × masses 0.3566 / 1 / 3.0298 × 101 ages).

Field integration: mid proxies **7 / 37 / 37 Parts** (young / growing / ripe) share the recipe's seeded structure and fruit-size math
without a full rig; mature proxies keep the tall leader, upright blades, purple lower stem, three hanging fruit with calyxes and the top
flower. Low detail hides crop art. No custom harvest effect. `eggplant_integration_checks.luau` (Client). Open: full-field performance,
real phone, second client (status table).
