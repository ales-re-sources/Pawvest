# Eggplant growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../ROADMAP.md)

## Selected design (CG16a, 2026-11-11)

**Ales chose B — Tall open plant.** Keep the tall leader, unequal upper arms, five broad lobed leaves and three long hanging
aubergines from that study. A and C below are the decision record. Ales's growth review correction: leaf blades **1.85× longer
and wider**, held more upright on shorter petioles; the young stem stays green and develops its purple tint midway through growth.

Ales supplied a [life-cycle illustration](../art/eggplant/reference-life-cycle.png) and a
[fruiting-plant photo](../art/eggplant/reference-ripe-plant.png). Preserve the upright branching habit, broad shallow-lobed
leaves, green star-shaped calyxes, purple flowers with yellow centres and heavy hanging aubergines. No trellis, exposed roots,
ground rosette or chilli-shaped pointed fruit. Use Pawvest's coloured stud-block geometry: faceted, rounded fruit with a
narrow neck and full blunt lower belly, sparse violet facets rather than painted white shine stripes.

Eggplant already has stored ID `Eggplant`, a **4 h** grow time and **0.4 kg** nominal harvest mass. Those values stay unchanged.
Harvest clears the whole square; explicit fruit slots are preparation for future art/gameplay, not perennial harvesting.

Three static mature studies precede the growth recipe. Each has three fruit slots, purple-green stems and an open front so
the produce remains legible from normal field distance. B has two long fruit on its side arms and a shorter central fruit. The alternatives
change the silhouette and leaf/fruit proportions, not the crop's identity or reward quantity.

| Variant | Silhouette | Intended read | Height / Parts |
|---|---|---|---|
| **A — Natural fork** | Unequal forked bush, broad lobed leaves in alternating tiers, three plump hanging purple fruit | Closest to both references; fruit is clearly separate from the foliage | 4.44 studs / 99 |
| **B — Tall open plant (selected)** | Taller leader and higher unequal arms, fewer leaves, longer pear-shaped fruit hanging in open gaps | Strongest upright silhouette; easiest fruit read among neighbouring crops | 5.11 studs / 93 |
| **C — Compact heavy crop** | Short broad crown, low branches and three short, fat dark-purple ovals | Photo's heavy fruit; strongest purple mass at phone distance, least height | 3.48 studs / 92 |

[Static mature studies A / B / C](../art/eggplant/ripe-studies.jpg), reproducible with
[`eggplant_ripe_studies.luau`](../../tools/eggplant_ripe_studies.luau). The study includes 5.5-stud soil squares and an actual
R15 rig (5.18 studs tall) on the same ground plane. Studio Edit checks: maximum radii **2.16 / 2.06 / 2.22 studs**;
lowest fruit clearance **0.39 / 1.10 / 0.36 studs**. Each is below the 130-Part static budget. These are standard-size static
studies, not validation of a growth recipe or its future mass extremes. The temporary display was removed after capture.

## Continuous growth and animation

The B recipe implements the following poses. Art review precedes field registration.

| Growth | Pose |
|---|---|
| **0%** | Tiny emerging shoot and two folded cotyledons at the soil. An unplanted square stays bare. |
| **20%** | A short green stem, two opened cotyledons and the first broad true leaf. The stem and petiole remain green. |
| **50%** | The main fork and unequal side shoots extend; large true leaves unfold in alternating tiers. The lower stem and petioles are midway through their green-to-purple transition. Violet five-petal flowers with yellow centres open at future fruit attachments. |
| **75%** | The bush is almost full. Petals curl inward and fade; calyxes remain green as small dusky-purple fruit lengthen beneath them. The lower fruit leads the upper fruit slightly. |
| **100%** | Three full deep-purple fruit hang from bent pedicels under green star calyxes. Leaves frame the fruit; loaded arms settle slightly. No brown, dried or yellow overripe fruit. |

Overlapping phases: stem/branches 0–63%; true leaves 10–66%; fruit-slot flowers open at 43–52% and contract during fruit set
at 59–74%; neck and length 62–88%; belly filling 74–100%; richer purple 70–96%; load settling 80–100%. The shorter central
fruit starts 2.5 percentage points later. Flowers and fruit share their attachment point. The decorative top flower opens at
46–57% and remains on the mature plant, as in the selected study. Cotyledons fade at 26–43%. Lower stems and leaf petioles
stay green through 35%, then continuously develop purple at 35–65%; this depends on plant age rather than segment extension.
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

## Recipe and validation

[`EggplantPlant.luau`](../../src/ReplicatedStorage/EggplantPlant.luau) uses the shared `PlantKit` rig and builds **113 Parts**:
eight stem segments, two cotyledons, five six-Part leaves, three 22-Part flower/fruit groups and a seven-Part decorative top
flower. A hypothetical 36-square full-detail field would contain **4,068 plant Parts**, before soil, pets or UI. This is a
recipe count, not a production performance measurement. Each `fruitSlots[1..3]` entry holds a stable ID, mature world-space
attachment CFrame and its 22 grouped Parts. `PlantRole` separates structure, foliage and fruit; `FruitSlot` identifies each
fruit group, including its spent blossom Parts.

Seed 1 at standard harvest size retains B's tall leader and fruit positions; the enlarged foliage raises the top to **6.12
studs** with **2.16-stud** ground radius. Its first blade is **2.71 studs long × 2.17 wide**, 1.85× its previous length and
width. Blade dimensions retain seeded vigor; upright leaf pitch and horizontally shorter petioles keep them inside the
field footprint. The recipe uses free-standing seeded orientation, constrained foliage vigor and cube-root fruit dimensions.
A larger harvest can lift the leader to keep the long fruit clear of soil. The nominal ring is fixed at **7.2 studs**
(foliage does not shrink with small fruit); review framing is **6.5 studs**. Completed leaf groups skip unchanged poses,
including the petiole colour transition; the shared rig caches Part writes.

[`eggplant_growth_checks.luau`](../../tools/eggplant_growth_checks.luau), Studio Client (2026-11-11): six seeds × three harvested
mass factors **0.3566 / 1 / 3.0298** × 101 ages pass after the leaf/stem correction. Maximum radius **2.37 studs**, ripe height
**5.49–6.67 studs** (maximum all-age top **6.75 studs**), minimum ripe fruit clearance **0.39 studs**. Stem, petiole and fruit-stalk
attachments, stable fruit groups, green young stems, intermediate petiole tint, enlarged blades, finite geometry, distinct seeds,
flower/fruit order, exact backward seeks and 1 → 0 restoration pass. All 113 Parts remain anchored, non-colliding and
non-queryable. The 4 h config and the shared 30 s production update interval are unchanged.

[Five review stills](../art/eggplant/growth-review.jpg) show 0/20/50/75/100% on the same soil square, seed 1, standard harvest
size and camera. The shared reviewer's Play/Pause path and ring/selection/pet context were checked. No new crop-specific UI,
schedule, remotes or profile writes. **CG16b built and geometry-validated; awaiting Ales's growth-art approval.**
CG16c field registration, direct-built mid proxies and production lifecycle checks remain separate; CG16d performance, real
phone and second-client checks remain open.

Playtest boot/reviewer session: no server or client warnings/errors; review disposed and Play stopped. Localization
build/check/lint pass (0 errors, 0 literals); no new or changed Czech strings.
