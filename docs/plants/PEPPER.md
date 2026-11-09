# Paprika / Pepper growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../ROADMAP.md)

## Proposed design — mature study awaiting review

Reference: Ales's bell-pepper growth illustration, 2026-11-09. Keep the existing stored crop ID `Pepper` (Czech name Paprika).
The no-pole design direction was accepted on 2026-11-09. A display-only mature study is built and Studio-checked; its actual
silhouette still awaits Ales's review. No growth recipe or field registration exists yet.

[Mature study beside the avatar](../art/pepper/ripe-study.jpg) ·
[Reproducible Studio client study](../../tools/pepper_ripe_study.luau)

Recommend a **free-standing upright forked bush without a pole**. Support is useful for heavy real pepper crops, but is not
essential to the selected compact silhouette. One sturdy central stem splits into two unequal upper arms, with a shorter side
shoot. Use pointed oval leaves and clear gaps around three hanging peppers, at staggered heights and azimuths. Keep the fruit
visible from the normal elevated gameplay camera as the seeded plant rotates. Avoid the low spreading habit of Tomato.

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

## Continuous growth proposal

| Growth | Review pose |
|---|---|
| 0% | A tiny planted sprout with two folded seed leaves just above the soil. An unplanted square remains bare. |
| 20% | A short upright stem; seed leaves spread and the first pointed true leaves unfold. |
| 50% | The main fork and unequal upper arms extend; pointed leaves open in tiers. Small white flowers appear at the three future fruit attachments. |
| 75% | Nearly full bush height. Flowers have faded; attached green peppers lengthen into clearly grooved bells beneath their calyxes. |
| 100% | Three plump red bell peppers hang in the foliage gaps; fruit-bearing arms dip slightly under their apparent weight. Leaves stay green. |

Stems extend successively from their current parent tips. Leaves unfold at their bases with overlapping timing. Flowers open
briefly, then shrink/fade as the fruit grows at the same attachment, without a detached flower or fruit. Fruit first lengthens,
then fills across its shoulders and lobes. Blend the small branch dip with fruit mass; the complete child assembly follows the
branch. Use continuous reversible poses, not five model swaps. No wind loop is needed for the initial growth-art scope.

Seeds vary fork height, arm lengths, lean, leaf angles and fruit proportions/timing. Preserve three recognizable fruit slots and
their foliage gaps. Seed 1 is the authored baseline; variation must remain visible after full-circle plant rotation. Actual
harvest mass, including Sorter, uses cube-root dimensional scaling chiefly on fruit, with constrained foliage vigor and footprint.

## Implementation and review boundary

The static study uses `PlantKit`: **88 Parts** (seven stems, 36 leaf plates, 45 fruit pieces in three 15-Part groups), or
**3,168 plant-only Parts** for 36 squares. Its standard-size height is **3.38 studs** and maximum ground radius **1.71 studs**
(rounded up). Each fruit's four diagonally oriented shoulder columns and narrower lower lobes make actual silhouette grooves.
These baseline measurements do not validate future seed/mass extremes or production performance. The playtest's server
log was clear; client warnings were limited to the Studio MCP camera-reset notices. The revised silhouette was checked in a fresh
playtest, with the same soil square and camera composition. The disposable study was removed, camera/HUD restored and the
agent-started playtest stopped after validation.

Use `PlantKit` and a future `PepperPlant` recipe through the shared `PlantGrowth` system and existing reviewer. Target at most
**90 full-detail Parts** (3,240 plant-only Parts for 36 squares; a budget, not a measured result). Use a cheaper direct-built mid
proxy that preserves the fork and lobed fruit silhouettes. Assign explicit `fruitSlots[1..3]` with stable IDs, attachments and
Part groups, plus `PlantRole` / `FruitSlot` metadata. These visual slots do not define reward quantity.

Keep the current **one-hour** production duration and square-clearing harvest behavior. No persistence or economy changes.

First review the mature silhouette beside an avatar on the same ground plane. After its shape is agreed, build the motion and
deliver five stills at **0/20/50/75/100%** using the same seed, size, square and camera. Internally check attachment continuity,
backward seeking, seed/size extremes, all-age bounds, proxies, real selection/progress rings and the field pet. Field registration
and performance validation follow art review; mark their status only after the corresponding checks.
