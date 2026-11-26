# Pineapple growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../PLANT_GROWTH.md#crops-and-status)

## Selected design

**Tall stalk**: the fruit stands on a thick stalk well above an upright leaf fountain, as in the cultivation infographic.

Stored id `Pineapple`, plot letter `s`; annual in the game (harvest clears the whole square) although the real plant is a perennial
bromeliad that ratoons from suckers. References: Ales's photo of a green fruit in a rosette of long glossy strap leaves with a blue-green
crown, and the "duration of pineapple cultivation" infographic (planting, seedling, ratoon, fruit development).

Shared rules: free-standing (rosette rotates by seed), one fruit slot (`PlantRole` `Fruit`), 8 columns × 7 tiers of tilted diamond "eye"
blocks (orange-gold at the base, yellow at the top: ripe from the bottom up, like the real fruit) over two cylinder cores and a green-gold
cap, small green-brown bracts on a checker, a blue-green crown of 14 blades in three rings with bent tips, and a rosette of long strap
leaves in glossy dark green, each three segments rolled alternately so the blades show their faces.

Rejected ([studies](../art/pineapple/ripe-studies.jpg), `pineapple_ripe_studies.luau`): **A classic rosette** (fruit nested in a 13-leaf
arching rosette, 4.96 studs; matches the photo but low and hard to read at phone distance) and **C mother and sucker** (side sucker
rosette and slip, 175 Parts, crowds the fruit at phone size). Chosen B: 2.15-stud fruit lifted above a 12-leaf fountain, 6.26 studs,
the only study clearly taller than the avatar (5.18).

## Growth

[Five stills](../art/pineapple/growth-review.jpg) · [75% and ripe detail](../art/pineapple/growth-75-100-detail.jpg)

| Growth | Pose |
|---|---|
| 0% | Planting: a leafy crown top (slip) pressed into the soil, three short upright blades. |
| 20% | Young rosette: eight narrow strap leaves fanning out, still upright. |
| 50% | Full rosette; leaves long and arching; the central heart rises. |
| 75% | A short stalk lifts a small green fruit with a tiny crown; pale eye pattern. |
| 100% | Fruit swells to full size, eyes turn orange-gold from the base up, crown fully fanned. |

Leaves 1-4 exist from 0% as a small upright slip; the other eight sprout every 3% and each opens from a bud into its arch over 32% (all
open by 65%); the stalk rises 45-72%; the fruit appears 56-62%, swells to 98% and rides up with the stalk; the eight columns ripen tier by
tier from the base (tier 1 at 74-86%, tier 7 at 88-100%, green to orange-gold / yellow); the crown unfolds from an upright tuft 58-98% and
turns blue-green. Pure function of growth (43 → 44 → 43% restores the pose). Seeds vary leaf yaw / length / height / droop, stalk lean,
fruit column yaw, crown yaw.

## Recipe

[`PineapplePlant.luau`](../../src/ReplicatedStorage/PineapplePlant.luau), `PlantKit.recipe`: **155 Parts** (hub 1, leaves 12 × 3, stalk 2,
fruit core 2, cap 2, eyes 56, bracts 28, crown 14 blades × 2); 36-square field 5 580, the heaviest crop (Sweet potato 169 Parts is next;
the mid proxy is the lever). Rotates with the planting, **fixed ring 7.2**, review framing 6.4. One fruit slot `fruitSlots[1]` (core, cap,
eyes, bracts, crown). Fruit scale follows cube-root mass up to 1.2; leaf reach clamped to 2.36. **Mid proxy:** 8 of 12 leaves in two
segments, stalk, core, cap, eyes on tiers 2 / 4 / 6, the two inner crown rings as one blade each, no bracts: **11 / 55 / 55 Parts**.
No harvest effect. Max radius 2.31, top 7.00, no leaf inside the fruit from 78%. Checks: `pineapple_growth_checks.luau`,
`pineapple_integration_checks.luau`; long crop sampled at the 30 s cap. Open: performance, real phone, second client.
