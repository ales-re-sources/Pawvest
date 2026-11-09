# Lettuce growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../ROADMAP.md)

## Selected design

Ales selected **A, the crisp head** (CG7a, 2026-11-09): open outer wrapper leaves around a firm head, a lighter-green base at each
leaf and frilled outer tips. Rejected: B Romaine (tall, upright; would have suited a taller plant) and C loose-leaf (a flat frilled
rosette, the weakest ripeness cue). [Ripe alternatives, left to right A / B / C](../art/lettuce/ripe-studies.jpg) (shot before the colour correction below)

The ripe plant is about **1.6 studs** tall and 2.3 wide, well below the 5.46-stud avatar; it stays within the 2.4-stud ground
radius at every age, seed and size. The closed, lighter lime-green head is the ripeness cue. **Colour rule (Ales, 2026-11-09):** the heart is a lighter shade of the same
leaf green, never white or cream (the first version read as cauliflower). Reference: a butterhead from above has broad, rounded,
overlapping outer leaves and a tight yellow-green heart; [top view of the build](../art/lettuce/top-view.jpg). Lettuce is an annual: harvest clears the whole plant.

## Growth and harvest

[0%](../art/lettuce/growth-0.jpg) · [20%](../art/lettuce/growth-20.jpg) · [50%](../art/lettuce/growth-50.jpg) ·
[75%](../art/lettuce/growth-75.jpg) · [100%](../art/lettuce/growth-100.jpg)

| Growth | Pose |
|---|---|
| 0% | Two small folded leaves above the soil; an unplanted square stays bare. |
| 20% | A small cluster; the first outer leaves are opening and the next ones emerge. |
| 50% | An open rosette of outer leaves; the middle ring is up and a lime heart starts to show. |
| 75% | Frilled outer leaves settle; inner leaves rise and begin to cup around the swelling heart. |
| 100% | A firm closed lime-green head on broad, overlapping frilled wrapper leaves. |

Leaves unfold at their bases, outer ring first, then the middle ring, then the inner ring, which cups over the head late
(overlapping seeded timings). Frills appear as each outer leaf finishes. The head's two Parts swell from the centre. Seeds vary
leaf yaw, elevation, length and width, ring spread, timing and head size. Whole-plant rotation is seeded. Harvest mass uses
cube-root scaling chiefly for the head and inner leaves, with constrained foliage vigor; a canopy fit keeps the ripe leaves
inside 2.4 studs, so the largest plants get a bigger head rather than wider leaves.

Production duration stays **thirty seconds**; the shared scheduler poses it at its 5 Hz floor (the same as Potato), and completed
leaves skip their writes. A 43→44→43% seek restores the identical pose.

## Recipe

[`LettucePlant.luau`](../../src/ReplicatedStorage/LettucePlant.luau), built on `PlantKit`, is registered in `PlantGrowth`
(CG7). It reuses **70 Parts**: 35 outer-leaf (7 leaves × three plates + two frills), 18 middle and 15 inner leaf plates, and
two head pieces. A 36-square field uses 2,520 plant Parts before soil, pets or UI. Mid detail uses **2 / 9 / 14 Parts** for
young/growing/ripe plants (open outer leaves and the head; no frills); low detail hides crop art. Nominal ring height is 2.3
studs, scaled with mass. No fruit slots: Lettuce is a whole-plant leafy crop, so Parts carry `PlantRole` `Foliage` or `Head` only.

Studio validation (2026-11-09): at harvest sizes 0.36 / 1 / 3.03 and six seeds, the maximum ground radius over every growth
step is 2.40 and the ripe pose is always the widest; ripe height is 1.32–2.27 studs. Through the real `PlotView` path three
plants build 210 Parts at full detail and 25 Parts as mid proxies. Playtest boot had no errors. Real-phone and second-client
validation are open.
