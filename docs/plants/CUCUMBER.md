# Cucumber growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../ROADMAP.md)

## Selected design

Ales supplied two references (2026-11-10): a **life-cycle sheet** (germination, seedling with two cotyledons, young vine with angular
toothed leaves and tendrils, male and female yellow flowers, baby fruit with the flower still on its tip, ripe dark ridged cucumber)
and a **homegrown timeline** (a climbing vine on a two-post wooden ladder trellis, big angular leaves, yellow flowers, dark-green
cucumbers hanging in front of the foliage). The design follows the timeline directly; no static alternatives were built.

- **Wooden ladder trellis, rigid and full-sized from planting**: two 4.8-stud posts and three rungs in light wood, row-aligned
  (`FixedOrientation`). It does not scale with mass. Distinct from the Frost Grape trellis by height (grape is 7.4 studs and rails),
  warm pale wood and a vine with broad bright leaves rather than teal lobes; distinct from the tomato's single stake by the ladder.
- **Twining stem** in four joined segments, **five broad angular leaves** of five plates each, alternating sides.
- **Ripeness cue: three long, dark-green ridged cucumbers** with a pale stripe, hanging in front of the leaves, each just below a leaf
  node on its own side. A young fruit is small and pale; it darkens and lengthens toward ripe. The yellow **female flower** sits on
  the blossom end and dries to a small orange-brown star; two **male flowers** open on the stem; two **tendrils** curl at the nodes.
- The ripe plant is about **5.4 studs** (leaf tops; 5.6 at the tallest seed and mass), beside the 5.46-stud avatar.

Cucumber is an annual here: harvest clears the whole plant. Parts carry `PlantRole` `Support`, `Structure`, `Foliage`, `Flower` or
`Fruit`; the three fruit groups are explicit visual slots (`fruitSlots[1..3]`), without any perennial behaviour.

Colours: leaves lime to mid green (`108,184,70` / `68,148,58`, young `146,206,108`); ripe fruit `24,76,42` with shoulders `42,104,56`;
stripe `124,184,100`; flowers `252,214,62` drying to `206,140,52`; wood `176,132,78`. Leaf pieces use `Studs`, the rest `StudsSmall`.

## Growth and harvest

[0%](../art/cucumber/growth-0.jpg) · [20%](../art/cucumber/growth-20.jpg) · [50%](../art/cucumber/growth-50.jpg) ·
[75%](../art/cucumber/growth-75.jpg) · [100%](../art/cucumber/growth-100.jpg)
(seed 1, standard mass, the reviewer's own camera).

| Growth | Pose (maps to the life cycle) |
|---|---|
| 0% | Seedling: two pale cotyledons and a short stem beside the empty ladder. An unplanted square stays bare. |
| 20% | The stem has climbed about a stud; the first true leaf is unfolding. Cotyledons are still there. |
| 50% | Leaves on both sides of a stem reaching the second rung; tendrils curl; male flowers open. Cotyledons have dropped. |
| 75% | The vine tops out; three young pale cucumbers hang with yellow flowers on their tips. |
| 100% | Dark, long, ridged cucumbers (lengthened and darkened), dried tip flowers, full foliage. |

Four stem segments extend with overlapping timings (the first already has a 0.3-stud stem at planting); each leaf unfolds at its
node when the stem reaches it, pivoting from pointing up to its seeded outward direction; a fruit starts at its node, lengthens
and darkens, and its tip flower opens, then dries from 82%. A 43→44→43% seek restores the same pose.

Seeds vary stem sway, leaf direction, elevation and size, fruit length, width, lean and hang offset, and may **mirror** the whole
layout (left and right swapped). Mass scales fruit and leaf size by cube root (constrained leaf vigour 0.92–1.08); fruit length is
capped so bottoms stay above the soil; a horizontal fit keeps leaves inside the 2.4-stud ground radius. Production duration stays
**fifteen minutes** (`CropConfig`), posed at ~1.9 s steps.

## Recipe

[`CucumberPlant.luau`](../../src/ReplicatedStorage/CucumberPlant.luau), built on `PlantKit`: **79 Parts** (5 rigid supports, 4 stem,
2 cotyledon, 30 leaf [5 × petiole + 5 plates], 24 fruit [3 × stalk, 3 body pieces, stripe, 3 flower plates], 8 male flower, 6
tendril), so a 36-square field uses 2,844 plant Parts before soil, pets or UI. The direct mid proxy builds the posts and two rungs,
the stem, three leaves of three plates and one body piece per visible fruit: **11 / 18 / 20 Parts** for young / growing / ripe.
Ring height is a fixed 5.6 studs; review framing 5.0. Registered in `PlantGrowth` (CG13c). No `PlayHarvest` (`PlayHarvest` is nil), so harvest keeps the ordinary pop.

Studio validation (2026-11-10): [`cucumber_growth_checks.luau`](../../tools/cucumber_growth_checks.luau) passed for six seeds × three
harvested masses (0.357 / 1 / 3.03) × 101 ages: maximum ground radius **2.03 studs**, stem and fruit stalks attached, ripe fruit
visible for every seed, lowest fruit 0.18 above soil, exact visible backward seeks and restored initial pose, distinct seeds, no
input/physics interception. Seed-1 standard mass: leaf top 5.42; across seeds and masses 5.35–5.62. Playtest boot clean.

**Status:** art approved by Ales (2026-11-10); registered in `PlantGrowth` (CG13c). Known roughness: leaf plates read as tilted
cards rather than toothed leaves, and the trellis is mostly hidden behind the foliage from the front camera at 75-100%.

Field integration (2026-11-10): [`cucumber_integration_checks.luau`](../../tools/cucumber_integration_checks.luau) passed through the
production `PlotView` with disposable public-feed fixtures and no remotes or profile writes: three recipes build 237 full Parts;
the first cucumber follows the feed; a server-time correction keeps the same plant, soil and pet instances; the exact ripe moment
(growth 1, no further sampling) is not missed and a backward correction hides the fruit; crop art does not block the soil
selection ray; full -> mid -> low -> full keeps the seed's identity, with mid proxies of **11 / 18 / 20 Parts** for young / growing /
ripe and nothing at low detail. The 900 s crop is sampled every 1.875 s. Playtest boot clean (server and client).
Open: performance (full field and the 24-plot route), real phone, second client.
