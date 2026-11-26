# Corn growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../PLANT_GROWTH.md#crops-and-status)

## Selected design

**Tall narrow two-ear stalk**: jointed green stalk, long arching ribbon leaves, two upward ears in green husks, branching crown tassel.
Each internode has an attached leaf base and three shorter, narrower blade segments; ears attach at stable upper leaf axils. Stalk
7.8 studs before the tassel, about **8.6 studs overall**, above the 5.46-stud avatar; keep the upright silhouette and 2.4-stud radius
across seeds and sizes. A golden kernel window in each ripe husk is a readability shortcut; husks do not open like flowers.
[Ripe alternatives](../art/corn/ripe-studies.jpg) · [Five growth poses](../art/corn/growth-poses.jpg)

| Growth | Pose |
|---|---|
| 0% | A small green spear above the soil; unplanted square stays bare. |
| 20% | Short stalk, two lower blades unfolding, upright central spear. |
| 50% | Successive joints lift the crown; alternating long blades form open arches. |
| 75% | Nearly full height, branching tassel, two slim green husked ears with silk. |
| 100% | Filled upward ears, visible golden kernels, dry tan silk; leaves stay mostly green. |

Internodes extend from the current previous node; leaves open from their bases, lower blades first, with overlapping seeded timing; ears
swell inside attached husks that unfold at connected hinges. Seeds vary spacing, lean, leaf yaw / arch, ear tilt, relative size; seeded
whole-plant rotation. Cube-root mass scaling chiefly for the ears, constrained foliage vigor. Annual: harvest clears the plant.

## Recipe and fruit identity

[`CornPlant.luau`](../../src/ReplicatedStorage/CornPlant.luau): **99 Parts** (13 stalk/node, 27 leaf, 50 ear, nine tassel); 36-square
field 3 564. Mid detail **5 / 9 / 14 Parts** (young / growing / ripe) keeps the arching leaves and ripe ears; full and proxy share seeded
dimensions and orientation; low detail hides crop art. Ring fixed **10.8 studs** independent of mass. Crop art does not intercept
soil-selection rays. `fruitSlots[1..2]`: `id`, mature world-space `attachment`, 25 `parts` per ear; `PlantRole` / `FruitSlot`
attributes identify ear pieces. These visual ids do not define harvest quantity or change annual clearing.
