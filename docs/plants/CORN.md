# Corn growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../ROADMAP.md)

## Selected design

Ales selected **B, the tall narrow two-ear stalk**, with room to grow taller (CG6, 2026-11-09). Preserve the jointed green stalk,
long arching ribbon leaves, two upward ears in green husks and branching crown tassel. Each internode has an attached leaf base and
three shorter, narrower blade segments. Ears attach at stable upper leaf axils.

The selected growth baseline raises the stalk to 7.8 studs before the tassel, about **8.6 studs overall**, above the 5.46-stud
reference avatar. Keep the upright silhouette and 2.4-stud radius target across seeds and size extremes. A golden kernel window
in each ripe husk is a deliberate readability shortcut; husks should not open like flowers.
[Ripe alternatives](../art/corn/ripe-studies.jpg) · [Five growth poses](../art/corn/growth-poses.jpg)

## Growth and harvest

| Growth | Pose |
|---|---|
| 0% | A small green spear above the soil; an unplanted square stays bare. |
| 20% | Short stalk, two lower blades unfolding and an upright central spear. |
| 50% | Successive joints lift the crown; alternating long blades form open arches. |
| 75% | Nearly full height, branching tassel and two slim green husked ears with silk. |
| 100% | Filled upward ears, visible golden kernels and dry tan silk; leaves stay mostly green. |

Internodes extend from the current previous node. Leaves open from their bases, lower blades first, with overlapping seeded timing.
Ears swell inside attached husks; the husks unfold at connected hinges. Cached properties and completed leaf/ear poses avoid
repeated writes. Seeds vary spacing, lean, leaf yaw/arch, ear tilt and relative size. Harvest mass uses cube-root scaling chiefly
for the ears, with constrained foliage vigor. Whole-plant rotation is seeded.

Corn remains an annual: harvest clears the plant. Its production duration stays **thirty minutes**. Motion is approved and the
recipe is registered in `PlantGrowth` (CG6c). Desktop scripting samples pass. Ales confirmed real-phone and second-client validation
on **2026-11-09**, completing CG6d and the Corn growth-art milestone.

## Recipe and fruit identity

[`CornPlant.luau`](../../src/ReplicatedStorage/CornPlant.luau) reuses **99 Parts**: 13 stalk/node, 27 leaf, 50 ear and nine tassel
pieces. A 36-square field uses 3,564 plant Parts before soil, pets or UI. Mid detail uses **5 / 9 / 14 Parts** for young/growing/ripe
plants, retaining the arching leaves and ripe ears. Full and proxy forms share seeded dimensions and orientation; low detail hides
crop art. The ring is fixed at **10.8 studs** independently of mass. Crop art does not intercept soil-selection rays.

Each instance exposes `fruitSlots[1..2]`, with `id`, mature world-space `attachment` and 25 `parts` per ear. Local `PlantRole` and
`FruitSlot` attributes identify ear pieces. These visual IDs do not define harvest quantity or change annual clearing behavior.
