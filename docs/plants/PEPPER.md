# Paprika / Pepper growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../ROADMAP.md)

## Selected design

Reference: Ales's bell-pepper growth illustration, 2026-11-09. Keep the existing stored crop ID `Pepper` (Czech name Paprika).
Ales approved the no-pole bush, elongated/slimmer fruit and red ripe colour on 2026-11-09. The continuous-growth recipe follows
this selected silhouette and is registered for the field. The five growth stills await art review.

[Mature study beside the avatar](../art/pepper/ripe-study.jpg) ·
[Reproducible Studio client study](../../tools/pepper_ripe_study.luau)

A **free-standing upright forked bush without a pole**: one sturdy central stem splits into two unequal upper arms, with a shorter
side shoot. Pointed oval leaves leave clear gaps around three hanging peppers, staggered in height and azimuth. The fruit remains
visible as the seeded plant rotates. The upright habit contrasts with Tomato's low spreading bush.

Target standard-mass height: **3.2–3.6 studs**, below the 5.46-stud reference avatar and taller than Tomato's 2.1-stud bush.
Maintain the shared maximum **2.4-stud ground radius** throughout growth, including supported seeds and size extremes.
Use Pawvest's opaque colored stud-block style. The supplied illustration's exposed roots are explanatory; roots stay below soil.

## Distinct bell-pepper fruit

- Broad square shoulders beneath a small green calyx, a short bent green stalk, and a pendant orientation.
- Four overlapping elongated lobes form one solid fruit with shallow vertical grooves and a subtly tapered body. The four blunt
  lower tips remain discernible; avoid a pointed chilli tip, a round tomato, or a cluster of separate balls.
- **Ales's shape correction (2026-11-09):** lengthen and slim the fruit so it cannot be mistaken for Tomato. The revised study
  stretches the fruit bodies by **27% vertically** and narrows them by **14%**, with matching narrower calyxes. The three
  standard-mass bodies measure **0.83–0.96 studs wide and 1.22–1.40 studs long** (length/width about **1.46**).
  Reserve foliage gaps around the shoulders and lower lobes.
- All three peppers finish red. Green → warm orange → red is a ripening shortcut; widening shoulders and filling lobes must
  also communicate progress. Seeded variation changes relative length/width and hanging angle while preserving the bell shape.

## Growth and harvest

[0%](../art/pepper/growth-0.jpg) · [20%](../art/pepper/growth-20.jpg) · [50%](../art/pepper/growth-50.jpg) ·
[75%](../art/pepper/growth-75.jpg) · [100%](../art/pepper/growth-100.jpg)

| Growth | Review pose |
|---|---|
| 0% | A tiny planted sprout with two folded seed leaves just above the soil. An unplanted square remains bare. |
| 20% | A short upright stem with the first two pointed leaves opening at different heights. |
| 50% | The main fork and unequal upper arms extend; pointed leaves open in tiers. Small white flowers appear at the three future fruit attachments. |
| 75% | Nearly full bush height. Flowers have faded; attached green peppers lengthen into clearly grooved bells beneath their calyxes. |
| 100% | Three plump red bell peppers hang in the foliage gaps; fruit-bearing arms dip slightly under their apparent weight. Leaves stay green. |

Stems extend successively from their current parent tips. Leaves unfold at their bases with overlapping timing. Five-petal white
flowers open briefly; their plates contract and turn green into the calyx as fruit sets at the same attachment. Fruit first
lengthens, then fills across its shoulders and lobes. Fruit-bearing arms settle through a small dip; their attached leaves,
stalks and fruit follow. Growth is continuous and reversible, without model swaps or a wind loop.

Seeds vary height, arm balance, spread, lean, leaf angles, relative fruit sizes and timing. Seed 1 is the authored baseline;
free-standing plants rotate through a full circle. Actual harvest mass, including Sorter, uses cube-root dimensional scaling
chiefly on fruit, with constrained foliage vigor and footprint. The largest fruit can raise the bush to preserve soil clearance.
Production duration remains **one hour** and annual harvest clears the square. No persistence or economy changes.

## Recipe and fruit identity

[`PepperPlant.luau`](../../src/ReplicatedStorage/PepperPlant.luau), built on `PlantKit`, reuses **90 Parts**: seven stems,
35 leaf plates (one small lower leaf has two, the other eleven have three) and three 16-Part fruit/blossom assemblies.
A 36-square field uses **3,240 plant Parts** before soil, pets or UI. Direct-built mid proxies use **5 / 31 / 31 Parts** for
young/growing/ripe plants, retaining the fork and four fruit lobes; low detail hides art. Nominal ring height is **4.4 studs**,
scaled by harvested mass's cube root. The shared scheduler poses the one-hour crop every **7.5 seconds**, skips completed leaf
groups and stops posing ripe plants. Parts do not intercept soil-selection rays.

Each plant exposes `fruitSlots[1..3]` with stable `id`, mature world-space `attachment` CFrame and 16 grouped `parts` (two stalk
pieces, centre/calyx, five petals/sepals, eight lobe pieces). `PlantRole` distinguishes structure, foliage and fruit; `FruitSlot`
identifies every fruit assembly's Parts. These slots do not define reward quantity or enable perennial collection.

Studio checks (2026-11-09): six seeds, harvest factors **0.3566 / 1 / 3.0298** and 101 ages stay within a **2.02-stud** maximum
radius; ripe height ranges **2.91–4.22 studs**, with at least **0.29 studs** fruit clearance. Leaf/stalk/calyx attachments and exact
backward seeks pass. PlotView builds 270 full-detail Parts for three peppers and 67 mid-proxy Parts, retains plant/soil/pet on
time corrections, restores detail and clears harvested art. Review Play/Pause, Rings and Close were exercised through the UI;
ring, selection and field pet were checked together at field distance. Server/client gameplay logs were clear.

The original mature study has 88 Parts and remains a static design reference. Growth art review, full-field/24-plot performance,
real-phone rendering and second-client checks remain open; the geometry checks do not establish runtime performance.
