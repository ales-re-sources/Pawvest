# Broccoli growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../ROADMAP.md)

## Design

The two references supplied by Ales (2026-11-11), [life cycle](../art/broccoli/reference-life-cycle.png) and
[mature crown](../art/broccoli/reference-crown.png), establish a leafy seedling, a broad blue-green vegetative plant and a late,
dense green crown on a thick pale stalk. The game silhouette uses one central domed head, with seven tightly joined floret
clusters, six long lobed leaves and visible branching beneath the head. Nest the crown within foliage that rises around it, with no tree-like
bare trunk. Roots remain underground. Ordinary matte stud-block Parts match the existing field art.

Ales's [uncut-leaf proportion reference](../art/broccoli/reference-long-leaves.png) (2026-11-11) corrects the first recipe's
short foliage: use much longer blades, with lower leaves spreading and upper leaves rising around and above the head.
Some leaves in the photo were removed to expose the head; the game plant keeps its foliage. Maintain the field-square
clearance by making the long leaves more upright, with a gentle joined bend, rather than shortening the blades.

Blades are **2.9–3.2 studs long** at standard seed/mass, **1.6–2.1×** their first-recipe lengths, with approximately **0.61-stud**
petioles extending outward from lower attachment points. Upper leaves reach above the head while gaps reveal its green florets.
Standard mature height is **4.01 studs**, below the measured **5.40-stud avatar**; the ground-radius limit is 2.4 studs at every growth age
and supported mass. Harvested mass changes crown dimensions by the shared cube-root scale; foliage grows more conservatively.
Seed variation changes leaf lengths, angles, stalk lean and crown proportions; seed 1 is the authored baseline.

| Growth | Review pose |
|---|---|
| 0% | Tiny stalk and paired seed leaves; no exposed seed, roots or crown. |
| 20% | Two emerging broad true leaves above the seed leaves. |
| 50% | Established layered foliage; the first tight central green bud appears. |
| 75% | Thickening stalk and widening, branching crown framed by long leaves. |
| 100% | Dense dark-green domed crown with smaller raised bud blocks; long blue-green lobed leaves rise around and partly above it. |

Leaves extend from attached petioles and unfold at connected sections. The late crown expands from the stalk's current tip;
each branch and its floret cluster move together. Closed green florets are the ripe cue; no yellow flowers or glowing effects.
The existing **two-hour** production duration and whole-square clearing harvest remain unchanged. This is annual whole-plant
art, without separate collectible fruit slots, profile fields, remotes or economy changes.

## Recipe and review

[`BroccoliPlant.luau`](../../src/ReplicatedStorage/BroccoliPlant.luau) uses the shared `PlantKit` rig: **108 Parts**
(one stalk, two seed leaves, six seven-Part true leaves and seven nine-Part floret groups). A full 36-square field would use
**3,888 plant Parts**, excluding soil, pets and UI. Direct-built mid proxies use **11 / 27 / 27 Parts** for young/growing/ripe,
keeping three broad leaves, the stalk and seven connected crown lobes. Roles are `Structure`, `Foliage` and `Crown`.
Ring height is fixed at **5.6 studs**; review framing is **5.2**. There is no extra harvest effect.

[Five-pose sheet](../art/broccoli/growth-review.png) · [0%](../art/broccoli/growth-0.jpg) ·
[20%](../art/broccoli/growth-20.jpg) · [50%](../art/broccoli/growth-50.jpg) ·
[75%](../art/broccoli/growth-75.jpg) · [100%](../art/broccoli/growth-100.jpg).

Studio playtest Client command: `require(game.Players.LocalPlayer.PlayerScripts.PlantGrowthReview).Open("Broccoli", 10)`.
The ten seconds affect review playback only. The stills use seed 1, standard mass, the same square and an elevated three-quarter
camera, with the real soil, comparison Potato and field pet. The sheet crops the same rectangle from each still.
Rings and selection were checked together; the five stills hide them for the plant review.

[`broccoli_growth_checks.luau`](../../tools/broccoli_growth_checks.luau) passed on 2026-11-11 for **six seeds × three harvested
mass factors (0.35656 / 1 / 3.02985) × 101 ages**, rerun after the long-leaf revision. Maximum checked ground radius was **2.071 studs**. The standard crown is
**2.313 studs wide × 1.173 high**; ripe total height across the checked seeds and masses was **3.563–4.767 studs**. Leaf petioles
and blade joints, stalk/branch/floret/bud attachments, paired initial seed leaves, late crown emergence, distinct seeds, retained
Part identity, exact visible backward seeks and non-colliding/non-touching/non-queryable flags pass. All six mature blades exceed
2.35 studs even at the checked minimum mass. Proxies also fit the radius. Larger-mass foliage stands more upright to retain clearance.

The recipe is registered in `PlantGrowth`. [`broccoli_integration_checks.luau`](../../tools/broccoli_integration_checks.luau)
passed through production `PlotView` using disposable public-feed fixtures: three age/mass samples contain **324 full-detail
Parts**, and mid proxies contain **11 / 27 / 27**. Corrections retain plant, soil and pet instances; exact ripeness completes the
crown and stops sampling. Backward corrections restore young art. Full→mid→low→full preserves identity, crop art leaves soil
selection rays clear, and clearing/replanting a square replaces only that plant. Production duration remains **7,200 seconds**,
with a shared **15-second** update interval and immediate corrections/ripe boundary.

The existing reviewer exercised five poses, six seeds, seed/size changes, rings, playback and Close through real UI clicks.
Client/server logs contained no errors or warnings; disposable fixtures were removed and the playtest stopped. No field action,
remote or profile fixture write was used. Art approval, full-field/24-plot performance, real phone, second client and live
validation remain open; see ROADMAP.
