# Tomato growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../PLANT_GROWTH.md#crops-and-status)

## Selected design

**Classic staked tomato** (a tester asked for a much taller plant grown around a wooden stick; replaces the earlier spreading bush):
one leader winds across a rigid 6-stud wooden stake, tied with twine at three heights; three trusses of two large fruit hang clear of the
leaves. Opaque coloured Plastic with `Studs` and `StudsSmall`. About 5.85 studs beside the 5.46-stud avatar, ground radius at most 2.4;
seed 1 at standard mass is the authored form.
[Three alternatives](../art/tomato/stake-studies.jpg) (A classic, B two floors, C cherry spiral; `tomato_stake_studies.luau`) ·
[Five growth poses](../art/tomato/stake-growth-poses.jpg) · [Close-up](../art/tomato/stake-growth-closeup.jpg)

Not built: B and C. If variants are wanted later, roll a second layout from a final seed draw so existing plantings keep their form
(the floor count is a natural seeded tendency).

## Growth and harvest

| Growth | Pose |
|---|---|
| 0% | The stake stands from planting; a small green tip appears beside it. Unplanted square stays bare. |
| 20% | Leader ~1.3 studs up, first leaf unfolding; first twine tie follows. |
| 50% | Leader ~4.6 studs, three or four unequal leaves, two ties, first trusses forming. |
| 75% | Leader tops out near 5.5 studs; green tomatoes swell on all three trusses. |
| 100% | Full red tomatoes hang below the leaf line; fruit size and truss length also signal ripeness. |

Annual: harvest clears the square. Seeded variation = six tendencies (baseline, fruit-heavy, leafy, compact, lopsided, airy; three
mirrored) over stem height and weave, leaf angles and length, truss sides, length and fruit size; whole-plant rotation over a full
circle. Harvested mass (Sorter included) scales leaf and fruit by its cube root; stake and stem heights do not scale; horizontal canopy
fitting preserves square clearance. Ring fixed at 6.8 studs, above the stake.

## Recipe

[`TomatoPlant.luau`](../../src/ReplicatedStorage/TomatoPlant.luau): **71 Parts**: rigid stake (placed once), six stem rods, three ties,
28 leaf pieces (seven leaves of blade, tip, two leaflets), 33 pieces in three trusses (a rachis plus two fruit of pedicel, sepal,
shoulder, body, base); 36-square field 2 556. Mid detail: the stake, one to three leaf plates and, when ripe, three fruit (2 / 3 / 7
Parts); low detail hides crop art. Seeds 1-7 at masses 0.5 / 1 / 3: radius at most 2.39, leaf / fruit tops 5.1-6.07 studs, fruit bottoms
at most 0.21 below soil (mass 3, compact seed). Five stills (2026-11-28, seed 1, ×1.00): [0%](../art/tomato/growth-0.jpg) · [20%](../art/tomato/growth-20.jpg) · [50%](../art/tomato/growth-50.jpg) · [75%](../art/tomato/growth-75.jpg) · [100%](../art/tomato/growth-100.jpg), approved by Ales (2026-11-28).
Open: real phone, second client, full-field performance.
