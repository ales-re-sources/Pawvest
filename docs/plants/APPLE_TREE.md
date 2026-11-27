# Apple tree growth art (Apple, Golden apple)

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../PLANT_GROWTH.md#crops-and-status) · gameplay: [EXPANSION §5.4](../EXPANSION.md)

## Selected design

**A round crown** (chosen by Ales from three static studies, [Apple](../art/apple/ripe-studies.jpg) /
[Golden](../art/apple/ripe-studies-golden.jpg), `apple_ripe_studies.luau`): a straight trunk with three root flares, three short limbs
and a leader under a ball of 14 stud leaf clumps (a core, a lower ring of six, an upper ring of five, two on top); the apples hang on
short stalks under the crown's lower ring. About 7 studs tall beside a 5.2-stud avatar, every Part inside the 2.4-stud radius.
Rejected: **B open vase** (apples in the open middle, easiest to count) and **C tiered** (storybook stacked tiers).

The **Golden apple** is the same tree in another palette (Ales's choice): gold apples, warmer leaves and bark, six fruit slots instead
of four. One recipe, [`FruitTree`](../../src/ReplicatedStorage/FruitTree.luau); `ApplePlant` / `GoldenApplePlant` only pass the palette.
1×1 trees stay their own small tier when big 2×2 trees come (Orchard, HYBRIDS): only the crown layout would be redrawn for a block.

## Two growths

A tree is perennial: a pick takes the fruit and leaves the tree as it was.
- **Structure** 0..1: the whole tree grows from about a third of its size (`u`), the sapling's leaf tuft starts larger so a young
  tree reads; limbs and leader extend, the leaf rings open in turn (lower ring 12–65%, upper 32–88%, top 50–90%).
- **Fruit slots** 1..`tree.Cap` (Apple 4, Golden apple 6), one apple each: slots 1..`fruit` ripe, slot `fruit + 1` growing (small
  and green, swelling and turning red / gold over its second half), the rest empty. Every slot has a stable id, a seeded mature
  stalk `attachment` and its `parts` (`plant.fruitSlots`); Parts carry `PlantRole` and `FruitSlot`.

`SetTree(structure, fruit, nextGrowth)` poses both. `SetGrowth(g)` is the reviewer's whole life: mature and bare at 60%, then the slots
fill one by one to the cap at 100% ([five stills](../art/apple/growth-stills.jpg): sapling / young tree / mature / one ripe and one
growing / full; [pick and regrowth](../art/apple/pick-regrow.jpg)).

**In the field** (`PlotView:treePose`, from the plot feed's `plants[sq]` = window + `fruit` / `young`): young → the window runs from
planting to the first fruit (structure to `tree.First`, then the first apple); bare → the window is the next apple; with fruit hanging
the window is closed, so the next apple shows only once the tree is bare. A synthetic feed without `fruit` reads the stage digit
(1 young, 2 bare, 3 all slots ripe). Mid-detail proxy: stage 1 young tree, 2 bare, 3 with the ripe apples (no root flares, stalks or
fruit leaves).

## Geometry

Parts: 8 wood + 14 clumps + 4 per slot (stalk, apple, 45°-turned facet, leaf) = **Apple 38**, **Golden apple 46**; a full field of 78
squares 2 964 / 3 588. Seeds vary lean, crown yaw, clump offsets and sizes, limb and apple yaws, and cycle three crown tendencies
(round, taller, wider). The harvested mass scales the apples (cube root), not the tree. Max radius 2.36 over six seeds × three masses
× 101 ages and every fruit pose; ripe height 6.9–7.4 studs. Fixed ring height 8.0, review framing 7.4, free-standing (seeded rotation).
Checks: `apple_growth_checks.luau` (Edit; radius, seeks, pick and regrowth restore the same tree).
[In the field](../art/apple/in-field.jpg): young, bare, picked and full Apples and a full Golden apple on one plot.
