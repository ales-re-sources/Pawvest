# Tomato growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../ROADMAP.md)

## Selected design

Ales selected **A, the spreading bush**, on 2026-11-08 (CG1). A low, open canopy and separated hanging fruit read clearly from
the gameplay camera. Preserve the gaps below the leaves as seeds vary; the upright and fruit-laden alternatives obscured fruit
more easily. Use opaque colored Plastic with `Studs` and `StudsSmall`.

The reference bush is about 2.1 studs tall on a 5.5-stud square. Seed 1 at standard mass reproduces the authored form.
[Ripe alternatives](../art/tomato/ripe-studies.jpg) · [Five growth poses](../art/tomato/growth-poses.jpg)

## Growth and harvest

| Growth | Pose |
|---|---|
| 0% | A small green tip appears after planting. An unplanted square stays bare. |
| 20% | A short leaning stem carries two broad leaves unfolding at different angles. |
| 50% | Two or three unequal arms open, with gaps between them and smaller leaves near their tips. |
| 75% | Green tomatoes swell below the outer branches, which begin to dip. |
| 100% | Full red tomatoes hang visibly below the leaf line; fruit size and branch angle also communicate ripeness. |

Tomato is an annual: harvest clears the square. Its production duration remains eight minutes. Stable seeded variation changes
lean, spread, arm height/length, leaf angles and fruit proportions; the whole bush can rotate through a full circle. Actual harvest
mass, including Sorter, scales linear dimensions by its cube root. Horizontal canopy fitting preserves square clearance while
fruit retain their mass scale. The ring follows plant size.

## Recipe

[`TomatoPlant.luau`](../../src/ReplicatedStorage/TomatoPlant.luau) is registered in `PlantGrowth` (CG1c / CG2 / CG4).
The full model reuses **54 Parts**: eight stem/branch pieces, 22 leaf pieces and 24 pieces in three fruit assemblies.
A 36-square field uses 1,944 plant Parts before soil, pets or UI. Mid detail uses one canopy and, when ripe, two fruit (1–3 Parts);
low detail hides crop art. The nominal ring height is 2.65 studs, scaled with mass. Posing uses the shared scheduler and stops when ripe.

Desktop CPU tuning is implemented; real-phone and second-client validation remain open. Historical measurements and validation
logs are referenced from the shared guide rather than repeated here.
