# Tomato growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../ROADMAP.md)

## Selected design

Ales selected **A, the classic staked tomato**, on 2026-11-09 (CG1e), after a tester asked for a much taller plant grown around a
wooden stick. It replaces the spreading bush selected on 2026-11-08, which is kept in git history (`git show 0cae122:docs/plants/TOMATO.md`).
One leader winds across a rigid 6-stud wooden stake, tied with twine at three heights; three trusses of two large fruit hang
clear of the leaves. Opaque colored Plastic with `Studs` and `StudsSmall`.

The reference plant reaches about 5.85 studs beside the 5.46-stud R15 avatar, on the same 5.5-stud square with a ground radius of
at most 2.4. Seed 1 at standard mass reproduces the authored form.
[Three alternatives](../art/tomato/stake-studies.jpg) (A classic, B two floors, C cherry spiral; script
[`tomato_stake_studies.luau`](../../tools/tomato_stake_studies.luau)) · [Five growth poses](../art/tomato/stake-growth-poses.jpg) ·
[Close-up](../art/tomato/stake-growth-closeup.jpg)

Not built: B (two floors) and C (cherry spiral). If variants are wanted later, roll a second layout from a final seed draw so
existing plantings keep their form; the floor count is a natural seeded tendency.

## Growth and harvest

| Growth | Pose |
|---|---|
| 0% | The stake stands from planting; a small green tip appears beside it. An unplanted square stays bare. |
| 20% | The leader is about 1.3 studs up with its first leaf unfolding; the first twine tie follows. |
| 50% | The leader is about 4.6 studs up with three or four unequal leaves open, two ties and the first trusses forming. |
| 75% | The leader tops out near 5.5 studs; green tomatoes swell on all three trusses. |
| 100% | Full red tomatoes hang below the leaf line; fruit size and truss length also communicate ripeness. |

Tomato is an annual: harvest clears the square. Its production duration remains eight minutes. Stable seeded variation changes
stem height and weave, leaf angles and length, truss sides, length and fruit size across six tendencies (baseline, fruit-heavy,
leafy, compact, lopsided, airy; three of them mirrored); the whole plant can rotate through a full circle. Actual harvest mass,
including Sorter, scales leaf and fruit dimensions by its cube root; the stake and the stem heights do not scale. Horizontal
canopy fitting preserves square clearance while fruit retain their mass scale. The ring is fixed at 6.8 studs, above the stake.

## Recipe

[`TomatoPlant.luau`](../../src/ReplicatedStorage/TomatoPlant.luau) is registered in `PlantGrowth` (CG1c / CG2 / CG4 / CG1e).
The full model reuses **71 Parts**: the rigid stake (placed once), six stem rods, three ties, 28 leaf pieces (seven leaves of a
blade, tip and two leaflets) and 33 pieces in three trusses (a rachis plus two fruit of pedicel, sepal, shoulder, body and base).
A 36-square field uses 2,556 plant Parts before soil, pets or UI. Mid detail uses the stake, one to three leaf plates and, when ripe,
three fruit (2 / 3 / 7 Parts); low detail hides crop art. Posing uses the shared scheduler and stops when ripe.

Studio-checked 2026-11-09 across seeds 1-7 at mass factors 0.5 / 1 / 3: ground radius at most 2.39, leaf and fruit tops
5.1-6.07 studs, fruit bottoms at most 0.21 below soil (mass 3 on a compact seed), and a 43→44→43% seek restores the identical
pose. The playtest boot had no errors. Real-phone, second-client and full-field performance validation remain open (the field
grows from 1,944 to 2,556 Parts).
