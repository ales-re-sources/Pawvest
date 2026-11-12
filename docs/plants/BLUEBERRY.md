# Blueberry growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../ROADMAP.md)

## Selected design (CG17, 2026-11-12)

**Ales chose A, the round highbush**, with the berries redistributed after a second
[ripe-bush photo](../art/blueberry/reference-ripe-bush-2.webp): many tight round bunches spread over the **whole** bush, from
just above the base to the top, sitting close to the canes, every front berry showing its dark crown and one or two pale green
berries in most bunches. The study's five bunches hanging only at the dome's skin did not read that way. The growth recipe
below implements the revised A; the studies stay as the decision record. **CG17b growth art reviewed in Studio by Ales and
approved (2026-11-12).**

## Mature silhouette studies (CG17a, 2026-11-12)

Ales supplied a [life-cycle illustration](../art/blueberry/reference-life-cycle.webp) (seed, sprout with two round seed leaves,
an upright shoot with paired oval leaves, a branched shrub, pink hanging bell flowers, a bush loaded with blue berries) and a
[ripe highbush photo](../art/blueberry/reference-ripe-bush.webp) (a dense rounded bush of small glossy leaves dotted with
bunches of dusty blue berries, a few still pale green or blush). Keep: woody multi-stem canes with reddish young twigs, small
oval leaves, berries in **bunches** rather than single fruit, a dusty blue-violet skin with a pale bloom and a dark crown at
the blossom end, and a few unripe berries in a ripe bunch. No trellis, exposed roots or single big fruit.

Flower reference ([petal fall](../art/blueberry/reference-flowers-petal-fall.webp), Ales 2026-11-12): **white** urn-shaped
bells (not pink), hanging mouth-down in a raceme, each on a short reddish pedicel with a green star calyx at its top. At petal
fall the bell drops and leaves a small green berry start with a blush-pink rim and the calyx crown at its blossom end: the
crown each ripe berry shows is that same calyx.

Crop facts: Blueberry has stored ID `Blueberry`, a **6 h** grow time and **0.2 kg** nominal harvest mass (one punnet); those
stay unchanged. Harvest clears the whole square, as for every crop. Blueberry is the natural first candidate for future
perennial picking, so every bunch is an explicit fruit slot (`PlantRole` `Fruit` + `FruitSlot`) from the start; the slots
do not change today's harvest contract.

Shared rules for all study options: free-standing (seeded 360° orientation), every Part inside the 2.4-stud ground radius, berries
built from two crossed blocks (a blue body and a paler 45°-turned "bloom" block, so a berry reads octagonal), one dark crown
per bunch on its outward berry, leaves as single broad stud plates spread near level along the outer part of each shoot.

[Static mature studies A / B / C](../art/blueberry/ripe-studies.jpg), reproducible with
[`blueberry_ripe_studies.luau`](../../tools/blueberry_ripe_studies.luau) (Studio Edit; seed-1 standard size on 5.5-stud soil
squares, an R15 avatar of 5.18 studs on the same ground plane). The temporary display was removed after capture.

| Variant | Silhouette | Intended read | Height / radius / Parts / berries |
|---|---|---|---|
| **A, round highbush** | Five woody canes fan into a leafy dome; five bunches of five berries hang at its outer skin, mostly blue with a few pale or blush berries | the ripe photo: a rounded bush dotted with blue bunches | 4.74 / 2.33 / 120 / 25 |
| **B, tall vase** | Three tall canes lean outward in a vase; reddish twigs end in leaf tufts; five bigger six-berry bunches hang in the open gaps | the illustration's branched shrub; tallest silhouette, berries hang clear of the leaves | 5.61 / 2.38 / 124 / 30 |
| **C, compact mound** | Six short canes and spreading twigs under flat leaves; seven bunches of four big berries sit on top | strongest blue from the field camera; lowest crop, reads as a berry patch | 2.73 / 2.27 / 124 / 28 |

Lowest berry above the soil: A 1.69, B 2.34, C 0.53 studs. These are standard-size static studies, not a growth recipe or
mass-extreme validation. Recommended (and chosen): **A**, closest to the ripe photo and a clear "bush" next to the tall Eggplant and
low Lettuce; B if a taller tree-like crop is wanted, C if blue mass at phone distance matters most.

## Continuous growth (CG17b)

| Growth | Pose |
|---|---|
| **0%** | A tiny green sprout with two folded round seed leaves at the soil. |
| **20%** | The first cane is up with its leaves unfolding; the next canes and the first twig follow; seed leaves fading. |
| **50%** | All five canes and four twigs are out and leafy; white urn-shaped bells hang mouth-down in every bunch. |
| **75%** | Petal fall is over: small pale green berry starts with pink-rimmed crowns gather into round bunches and swell; the first turn blush. |
| **100%** | Ten full bunches of dusty blue berries over the whole bush, crowns facing out, a pale green or blush berry in most bunches; the loaded twigs settle slightly. |

Overlapping phases: seed leaves open 0–10%, fade 24–40%. Cane *i* starts at 0 / 6 / 12 / 17 / 22% and extends over 50% of
growth (lower segment first, upper from 35% of its window); it turns from green to brown 25–70% after its start and thickens to
90%. Twigs grow from the cane's middle joint 22–55% after its cane's start. Leaves are born as their parent reaches them and
unfold from upright over 16%. Each bunch blooms at 40–46% (bells open over 6%), drops its petals 12–19% later, gathers from a
hanging raceme into a round bunch and swells to 93%, while the crowns turn from facing down to facing outward; each berry
ripens green → blush → blue over 14% from about 74–88%, staggered by berry and bunch. Growth extends from the current parents
(no whole-model scaling); a 43 → 44 → 43% seek and 1 → 0 restore the exact pose.

Seed 1 is the authored pose; seeds vary cane yaw, height and spread, twig ends, leaf length and pitch, bunch position and
outward yaw, and which berry stays pale. Free-standing 360° orientation. Harvest mass scales the berries by its cube root;
foliage vigor is held to 0.93–1.08. Bunches are pulled inward and leaves shortened where they would leave the 2.28-stud limit.

## Recipe and validation

[`BlueberryPlant.luau`](../../src/ReplicatedStorage/BlueberryPlant.luau) is an emit-style `PlantKit.recipe` of **134 Parts**:
2 seed leaves, 5 two-rod canes, 4 twigs, 28 single-plate leaves and 10 bunches of 6 one-block berries + 3 crowns. Each berry
block is first the white bell, then the berry start, then the berry (one Part through the whole cycle). Each bunch is
`fruitSlots[k]` with stable `id`, its mature world-space `attachment` and its 9 Parts (`PlantRole` `Fruit`, `FruitSlot` = k);
canes and twigs are `Structure`, leaves `Foliage`. A 36-square full-detail field holds **4,824 plant Parts** (a recipe count,
not a performance measurement).

[`blueberry_growth_checks.luau`](../../tools/blueberry_growth_checks.luau), Studio Client (2026-11-12): six seeds × harvested
mass factors min / 1 / max × 101 ages pass: maximum radius **2.396 studs** (mid proxies 2.387), ripe height **4.22–5.17 studs**
(seed-1 standard 4.73; all-age top 5.20), lowest ripe berry **0.39 studs** above the soil, finite poses, physics flags (full and
proxy), ten 9-Part fruit slots, exact backward seeks and 1 → 0 restoration.

## Field integration (CG17c)

Registered: the recipe has no `Draft`, so [`PlantGrowth`](../../src/ReplicatedStorage/PlantGrowth.luau) dispatches it. Mid
proxies come from the same geometry (`PlantKit.recipe`, shown at 20 / 70 / 100%): canes and twigs, every other leaf 15% longer,
and two 1.4× berries per bunch, no crowns: **6 / 48 / 48 Parts**. A growing proxy shows pale green berry bunches, a ripe one
blue. Their bunches are pulled further inward so the larger berries stay inside the radius. Low detail hides crop art. No custom
harvest effect; the ordinary harvest pop and the square-clearing contract stay. The ring is fixed at **5.9 studs**; the 6 h
config and the shared 30 s update interval are unchanged.

Studio Client [`blueberry_integration_checks.luau`](../../tools/blueberry_integration_checks.luau) passes (2026-11-12): three
production `PlotView` crops build 402 full Parts or 6 / 48 / 48 proxy Parts; corrections keep plant, soil and pet; exact
ripeness stops posing; a backward correction clears it; full → mid → low → full keeps seed identity; the selection ray reaches the
soil; harvest clears only its square and a replant starts young. Full and mid art were looked at in a field with the field pet and
selection outline. Playtest boot: no server errors or warnings; the client logged only Studio MCP's camera-reset note from the
look. **CG17c Studio-validated.** Open: CG17d full-field / 24-plot performance, real phone, second client and live validation.
