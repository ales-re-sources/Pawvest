# Lettuce growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../PLANT_GROWTH.md#crops-and-status)

## Selected design

**Crisp head**: open outer wrapper leaves around a firm head, a lighter-green base at each leaf and frilled outer tips. Rejected: B Romaine
(tall, upright) and C loose-leaf (flat frilled rosette, weakest ripeness cue). [Ripe alternatives A / B / C](../art/lettuce/ripe-studies.jpg)
(shot before the colour correction below) · [top view](../art/lettuce/top-view.jpg).

Ripe plant about **1.6 studs** tall, 2.3 wide, within the 2.4-stud radius at every age, seed and size. The closed lighter lime-green head
is the ripeness cue. **Colour rule (user decision):** the heart is a lighter shade of the same leaf green, never white or cream (the first
version read as cauliflower). Reference: a butterhead from above has broad rounded overlapping outer leaves and a tight yellow-green heart.
Annual: harvest clears the plant.

## Growth

[0%](../art/lettuce/growth-0.jpg) · [20%](../art/lettuce/growth-20.jpg) · [50%](../art/lettuce/growth-50.jpg) ·
[75%](../art/lettuce/growth-75.jpg) · [100%](../art/lettuce/growth-100.jpg)

| Growth | Pose |
|---|---|
| 0% | Two small folded leaves above the soil; unplanted square stays bare. |
| 20% | A small cluster; first outer leaves opening, next ones emerge. |
| 50% | Open rosette of outer leaves; middle ring up, a lime heart starts to show. |
| 75% | Frilled outer leaves settle; inner leaves rise and cup around the swelling heart. |
| 100% | Firm closed lime-green head on broad overlapping frilled wrapper leaves. |

Leaves unfold at their bases, outer ring first, then middle, then inner (which cups over the head late), with overlapping seeded timings;
frills appear as each outer leaf finishes; the head's two Parts swell from the centre. Seeds vary leaf yaw, elevation, length, width, ring
spread, timing, head size; whole-plant rotation seeded. Cube-root mass scaling chiefly for the head and inner leaves, constrained foliage
vigor; a canopy fit keeps ripe leaves inside 2.4 studs, so the largest plants get a bigger head rather than wider leaves. Completed leaves
skip their writes; 43→44→43% restores the identical pose.

## Recipe

[`LettucePlant.luau`](../../src/ReplicatedStorage/LettucePlant.luau), `PlantKit`: **70 Parts** (35 outer-leaf [7 leaves × three plates + two
frills], 18 middle and 15 inner leaf plates, two head pieces); 36-square field 2 520. Mid detail **2 / 9 / 14 Parts** (open outer leaves
and the head; no frills); low detail hides crop art. Nominal ring 2.3 studs, mass-scaled. No fruit slots (whole-plant leafy crop): Parts
carry `PlantRole` `Foliage` or `Head`. Max radius 2.40 (ripe always widest), ripe height 1.32-2.27 studs. Open: real phone, second client.
