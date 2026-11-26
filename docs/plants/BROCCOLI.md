# Broccoli growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../PLANT_GROWTH.md#crops-and-status)

## Design

References: [life cycle](../art/broccoli/reference-life-cycle.png), [mature crown](../art/broccoli/reference-crown.png), [uncut-leaf
proportions](../art/broccoli/reference-long-leaves.png). They show a leafy seedling, a broad blue-green vegetative plant and a late
dense green crown on a thick pale stalk. Game silhouette: one central domed head of seven tightly joined floret clusters, six **long**
lobed leaves and visible branching beneath the head. The crown nests in foliage rising around it (no tree-like bare trunk); roots stay
underground; matte stud-block Parts.

Leaves were first too short: blades are now **2.9-3.2 studs long** (1.6-2.1× the first recipe) on ~0.61-stud petioles; lower leaves spread,
upper ones rise around and above the head with gaps revealing the florets. Some photo leaves were removed to expose the head; the game
plant keeps its foliage. Keep field-square clearance by making long leaves more upright (gentle joined bend), never by shortening
blades; larger-mass foliage stands more upright. Standard mature height **4.01 studs** (avatar 5.40), radius limit 2.4 at every age
and mass. Cube-root mass scaling for the crown, conservative for foliage. Seeds vary leaf lengths, angles, stalk lean, crown proportions.

| Growth | Pose |
|---|---|
| 0% | Tiny stalk and paired seed leaves; no exposed seed, roots or crown. |
| 20% | Two emerging broad true leaves above the seed leaves. |
| 50% | Established layered foliage; the first tight central green bud. |
| 75% | Thickening stalk, widening branching crown framed by long leaves. |
| 100% | Dense dark-green domed crown with smaller raised bud blocks; long blue-green lobed leaves rise around and partly above it. |

[Five-pose sheet](../art/broccoli/growth-review.png) · [0%](../art/broccoli/growth-0.jpg) · [20%](../art/broccoli/growth-20.jpg) ·
[50%](../art/broccoli/growth-50.jpg) · [75%](../art/broccoli/growth-75.jpg) · [100%](../art/broccoli/growth-100.jpg).

Leaves extend from attached petioles and unfold at connected sections; the late crown expands from the stalk's current tip, each branch
and its floret cluster moving together. Closed green florets are the ripe cue; no yellow flowers or glow. Annual whole-plant art,
whole-square clearing harvest, no fruit slots.

## Recipe

[`BroccoliPlant.luau`](../../src/ReplicatedStorage/BroccoliPlant.luau), `PlantKit` rig: **108 Parts** (one stalk, two seed leaves, six
seven-Part true leaves, seven nine-Part floret groups); 36-square field 3 888. Roles `Structure`, `Foliage`, `Crown`. Mid proxies
**11 / 27 / 27 Parts** (three broad leaves, stalk, seven crown lobes). Ring fixed **5.6 studs**, review framing 5.2. No harvest effect.
Standard crown 2.313 wide × 1.173 high; ripe height 3.563-4.767 over seeds / masses; max radius 2.071; all six mature blades exceed
2.35 studs even at minimum mass. Checks: `broccoli_growth_checks.luau` (six seeds × masses 0.35656 / 1 / 3.02985 × 101 ages),
`broccoli_integration_checks.luau`. Exact ripeness completes the crown and stops sampling; backward corrections restore young art.
Open: performance, real phone, second client.
