# Eggplant growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../ROADMAP.md)

## Mature study (CG16a, 2026-11-11)

Ales supplied a [life-cycle illustration](../art/eggplant/reference-life-cycle.png) and a
[fruiting-plant photo](../art/eggplant/reference-ripe-plant.png). Preserve the upright branching habit, broad shallow-lobed
leaves, green star-shaped calyxes, purple flowers with yellow centres and heavy hanging aubergines. No trellis, exposed roots,
ground rosette or chilli-shaped pointed fruit. Use Pawvest's coloured stud-block geometry: faceted, rounded fruit with a
narrow neck and full blunt lower belly, sparse violet facets rather than painted white shine stripes.

Eggplant already has stored ID `Eggplant`, a **4 h** grow time and **0.4 kg** nominal harvest mass. Those values stay unchanged.
Harvest clears the whole square; explicit fruit slots are preparation for future art/gameplay, not perennial harvesting.

Three static mature studies precede the growth recipe. Each has three fruit slots (two prominent lower fruit and a smaller
upper one), purple-green stems and an open front so the produce remains legible from normal field distance. The alternatives
change the silhouette and leaf/fruit proportions, not the crop's identity or reward quantity.

| Variant | Silhouette | Intended read | Height / Parts |
|---|---|---|---|
| **A — Natural fork** (recommended) | Unequal forked bush, broad lobed leaves in alternating tiers, three plump hanging purple fruit | Closest to both references; fruit is clearly separate from the foliage | 4.44 studs / 99 |
| **B — Tall open plant** | Taller leader and higher unequal arms, fewer leaves, longer pear-shaped fruit hanging in open gaps | Strongest upright silhouette; easiest fruit read among neighbouring crops | 5.11 studs / 93 |
| **C — Compact heavy crop** | Short broad crown, low branches and three short, fat dark-purple ovals | Photo's heavy fruit; strongest purple mass at phone distance, least height | 3.48 studs / 92 |

[Static mature studies A / B / C](../art/eggplant/ripe-studies.jpg), reproducible with
[`eggplant_ripe_studies.luau`](../../tools/eggplant_ripe_studies.luau). The study includes 5.5-stud soil squares and an actual
R15 rig (5.18 studs tall) on the same ground plane. Studio Edit checks: maximum radii **2.16 / 2.06 / 2.22 studs**;
lowest fruit clearance **0.39 / 1.10 / 0.36 studs**. Each is below the 130-Part static budget. These are standard-size static
studies, not validation of a growth recipe or its future mass extremes. The temporary display was removed after capture.

## Proposed continuous growth and animation

These timings are design, pending the mature choice. They do not yet describe a shipped recipe.

| Growth | Pose |
|---|---|
| **0%** | Tiny emerging hooked shoot and two folded cotyledons at the soil. An unplanted square stays bare. |
| **20%** | A short green stem, two opened cotyledons and the first broad true leaves; purple tint begins at the lower stem. |
| **50%** | The main fork and unequal side shoots extend; true leaves unfold in alternating tiers. Violet five-petal flowers with yellow centres open at future fruit attachments. |
| **75%** | The bush is almost full. Petals curl inward and fade; calyxes remain green as small dusky-purple fruit lengthen beneath them. The lower fruit leads the upper fruit slightly. |
| **100%** | Three full deep-purple fruit hang from bent pedicels under green star calyxes. Leaves frame the fruit; loaded arms settle slightly. No brown, dried or yellow overripe fruit. |

Suggested overlapping phases: stem/branches 0–58%; true leaves 12–66%; flowers 43–67%; fruit set 59–74%; neck and length
62–88%; belly filling 74–100%; richer purple 70–96%; load settling 80–100%. Flowers and fruit share their attachment point.
The small violet fruit starts purple, rather than borrowing Pepper's green → orange → red ripening sequence. Ripeness reads
from the full lower belly, length and dark skin together. Keep the calyx and stalk attached throughout the bend.

Growth extends from current parents, not by scaling the whole mature model. Leaves hinge open from petioles; fruit lengthens
from its neck before the belly fills. A small deterministic downward branch bend follows fruit weight. No perpetual ripe sway
or new particle effect is proposed. A 43 → 44 → 43% seek must reproduce the exact original pose.

Seed 1 is the authored baseline; seed variation changes fork balance, stem lean, leaf yaw/fold, fruit bend and relative lengths.
Free-standing orientation can vary over 360°. Actual harvested mass (including Sorter) scales produce dimensions by its cube
root; foliage vigor stays constrained. Raise or tuck fruit inward if needed to retain soil clearance and the 2.4-stud radius
at the supported mass extremes. Final ring height is chosen against the selected mature model.

## Scope and acceptance

**CG16a:** disposable static Studio studies and this design; choose A/B/C before building growth.
**CG16b:** one selected `EggplantPlant` recipe through `PlantKit`, stable fruit IDs and grouped Parts, reversible attachment-aware
growth, six-seed/three-mass bounds checks and exactly five review stills at 0/20/50/75/100%, using the same seed, size and camera.
**CG16c:** after art approval, direct-built mid proxies and `PlantGrowth` registration, production lifecycle/detail/selection
checks. **CG16d:** full-field/24-plot performance, real phone and second client. No economy, persistence or remote changes.

Status: three static studies built and geometry-checked in Studio; awaiting Ales's mature choice. Growth and field integration
are not implemented. Playtest boot: no server/client warnings or errors; stopped afterwards. Localization build/check/lint
pass (0 errors, 0 literals); no new player-facing or Czech strings.
