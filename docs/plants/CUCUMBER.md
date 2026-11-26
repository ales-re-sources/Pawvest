# Cucumber growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../PLANT_GROWTH.md#crops-and-status)

## Selected design

Two references: a **life-cycle sheet** (germination, seedling with two cotyledons, young vine with angular toothed leaves and tendrils,
male and female yellow flowers, baby fruit with the flower on its tip, ripe dark ridged cucumber) and a **homegrown timeline** (a vine on
a two-post wooden ladder trellis, big angular leaves, yellow flowers, dark-green cucumbers hanging in front of the foliage). The design
follows the timeline; no static alternatives were built.

- **Wooden ladder trellis, rigid and full-sized from planting**: two 4.8-stud posts and three rungs in light wood, row-aligned
  (`FixedOrientation`), not mass-scaled. Distinct from the Frost Grape trellis (7.4 studs, rails, teal lobes) by height, warm pale wood
  and broad bright leaves; distinct from Tomato's single stake by the ladder.
- **Twining stem** in four joined segments, **five broad angular leaves** of five plates each, alternating sides.
- **Ripeness cue: three long dark-green ridged cucumbers** with a pale stripe, hanging in front of the leaves, each just below a leaf node
  on its own side. Young fruit is small and pale, darkens and lengthens toward ripe. The yellow **female flower** sits on the blossom end
  and dries to a small orange-brown star; two **male flowers** open on the stem; two **tendrils** curl at the nodes.
- Ripe plant about **5.4 studs** (leaf tops; 5.6 at the tallest seed / mass), beside the 5.46-stud avatar.

Annual: harvest clears the plant. `PlantRole` `Support`, `Structure`, `Foliage`, `Flower`, `Fruit`; the three fruit groups are explicit
visual slots (`fruitSlots[1..3]`) without perennial behaviour.

Colours: leaves lime to mid green (`108,184,70` / `68,148,58`, young `146,206,108`); ripe fruit `24,76,42`, shoulders `42,104,56`; stripe
`124,184,100`; flowers `252,214,62` drying to `206,140,52`; wood `176,132,78`. Leaf pieces `Studs`, the rest `StudsSmall`.

## Growth

[0%](../art/cucumber/growth-0.jpg) · [20%](../art/cucumber/growth-20.jpg) · [50%](../art/cucumber/growth-50.jpg) ·
[75%](../art/cucumber/growth-75.jpg) · [100%](../art/cucumber/growth-100.jpg)

| Growth | Pose |
|---|---|
| 0% | Seedling: two pale cotyledons and a short stem beside the empty ladder. Unplanted square stays bare. |
| 20% | Stem climbed about a stud; first true leaf unfolding; cotyledons still there. |
| 50% | Leaves on both sides of a stem reaching the second rung; tendrils curl; male flowers open; cotyledons dropped. |
| 75% | Vine tops out; three young pale cucumbers hang with yellow flowers on their tips. |
| 100% | Dark, long, ridged cucumbers, dried tip flowers, full foliage. |

Four stem segments extend with overlapping timings (the first already has a 0.3-stud stem at planting); each leaf unfolds at its node when
the stem reaches it, pivoting from pointing up to its seeded outward direction; a fruit starts at its node, lengthens and darkens, its tip
flower opens, then dries from 82%. 43→44→43% seek restores the pose. Seeds vary stem sway, leaf direction / elevation / size, fruit length,
width, lean and hang offset, and may **mirror** the whole layout. Mass scales fruit and leaves by cube root (leaf vigour 0.92-1.08); fruit
length capped so bottoms stay above soil; horizontal fit keeps leaves inside the 2.4-stud radius.

## Recipe

[`CucumberPlant.luau`](../../src/ReplicatedStorage/CucumberPlant.luau), `PlantKit`: **79 Parts** (5 rigid supports, 4 stem, 2 cotyledon,
30 leaf [5 × petiole + 5 plates], 24 fruit [3 × stalk, 3 body pieces, stripe, 3 flower plates], 8 male flower, 6 tendril); 36-square
field 2 844. Mid proxy (posts and two rungs, stem, three leaves of three plates, one body piece per visible fruit) **11 / 18 / 20 Parts**;
nothing at low detail. Ring fixed 5.6 studs, review framing 5.0. No `PlayHarvest`. Max radius 2.03, lowest fruit 0.18 above soil, seed-1
leaf top 5.42 (5.35-5.62 over seeds / masses). Known roughness: leaf plates read as tilted cards rather than toothed leaves; the trellis is
mostly hidden behind foliage from the front camera at 75-100%. Checks: `cucumber_growth_checks.luau`, `cucumber_integration_checks.luau`.
Open: performance, real phone, second client.
