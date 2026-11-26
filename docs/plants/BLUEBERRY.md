# Blueberry growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../PLANT_GROWTH.md#crops-and-status)

## Selected design

**Round highbush** (chosen from three studies), with many tight round bunches spread over the **whole** bush from just above the base
to the top, sitting close to the canes; every front berry shows its dark crown and most bunches have one or two pale green berries.
(Five bunches hanging only at the dome's skin did not read as a ripe bush.)

References: [life-cycle illustration](../art/blueberry/reference-life-cycle.webp), [ripe highbush photos](../art/blueberry/reference-ripe-bush.webp),
[second photo](../art/blueberry/reference-ripe-bush-2.webp), [flowers at petal fall](../art/blueberry/reference-flowers-petal-fall.webp).
Keep: woody multi-stem canes with reddish young twigs, small oval leaves, berries in **bunches** (not single fruit), dusty blue-violet
skin with a pale bloom and a dark crown at the blossom end, a few unripe berries in a ripe bunch. Flowers are **white** urn-shaped bells
(not pink) hanging mouth-down on short reddish pedicels with a green star calyx; at petal fall the bell drops and leaves a small green
berry start with a blush-pink rim, and the calyx becomes the crown each ripe berry shows. No trellis, exposed roots or single big fruit.

Stored id `Blueberry` (nominal harvest mass 0.2 kg, one punnet); harvest clears the whole square. Blueberry is the natural
first candidate for future perennial picking, so every bunch is an explicit fruit slot (`PlantRole` `Fruit` + `FruitSlot`) already.

Rules for the studies / recipe: free-standing (seeded 360° orientation), every Part inside the radius, berries from two crossed blocks
(a blue body and a paler 45°-turned "bloom" block so a berry reads octagonal), one dark crown per bunch on its outward berry, leaves
as single broad stud plates spread near level along the outer part of each shoot.

Rejected variants ([studies](../art/blueberry/ripe-studies.jpg), `blueberry_ripe_studies.luau`): **B tall vase** (5.61 studs, three
leaning canes; the pick if a taller tree-like crop is wanted) and **C compact mound** (2.73 studs, strongest blue mass at phone
distance, reads as a berry patch).

## Growth

| Growth | Pose |
|---|---|
| **0%** | Tiny green sprout with two folded round seed leaves at the soil. |
| **20%** | First cane up with leaves unfolding; next canes and first twig follow; seed leaves fading. |
| **50%** | All five canes and four twigs out and leafy; white bells hang mouth-down in every bunch. |
| **75%** | Petal fall over: pale green berry starts with pink-rimmed crowns gather into round bunches and swell; first turn blush. |
| **100%** | Ten full bunches of dusty blue berries over the whole bush, crowns facing out, a pale green or blush berry in most bunches; loaded twigs settle slightly. |

Phases: seed leaves open 0–10%, fade 24–40%. Cane *i* starts at 0 / 6 / 12 / 17 / 22% and extends over 50% of growth (lower segment
first, upper from 35% of its window); green → brown 25–70% after its start, thickens to 90%. Twigs grow from the cane's middle joint
22–55% after the cane's start. Leaves are born as their parent reaches them and unfold over 16%. Each bunch blooms 40–46% (bells open
over 6%), drops petals 12–19% later, gathers from a hanging raceme into a round bunch and swells to 93% while crowns turn from facing
down to outward; each berry ripens green → blush → blue over 14% from ~74–88%, staggered by berry and bunch. Growth extends from current
parents; 43 → 44 → 43% seeks and 1 → 0 restore the exact pose.

Seeds vary cane yaw, height, spread, twig ends, leaf length and pitch, bunch position and yaw, and which berry stays pale. Harvested mass
scales berries by its cube root; foliage vigor held to 0.93–1.08; bunches are pulled inward and leaves shortened where they would leave
the 2.28-stud limit.

## Recipe and field integration

[`BlueberryPlant.luau`](../../src/ReplicatedStorage/BlueberryPlant.luau), emit-style `PlantKit.recipe`, **134 Parts**: 2 seed leaves,
5 two-rod canes, 4 twigs, 28 single-plate leaves, 10 bunches of 6 one-block berries + 3 crowns (each berry block is first the bell, then
the berry start, then the berry: one Part through the cycle). Each bunch is `fruitSlots[k]` with stable `id`, mature world-space
`attachment` and its 9 Parts (`PlantRole` `Fruit`, `FruitSlot` = k); canes / twigs `Structure`, leaves `Foliage`. 36-square field 4 824.
Seed 1 top 4.73 studs; ripe height 4.22–5.17, max radius 2.396 (mid proxies 2.387), lowest ripe berry 0.39 above soil. Ring fixed
**5.9 studs**. Checks: `blueberry_growth_checks.luau`, `blueberry_integration_checks.luau`.

Mid proxies (same geometry at 20 / 70 / 100%) **6 / 48 / 48 Parts**: canes, twigs, every other leaf 15% longer, two 1.4× berries per
bunch, no crowns, bunches pulled further inward; growing = pale green, ripe = blue. Low detail hides crop art. No custom harvest effect.
Open: full-field performance, real phone, second client.
