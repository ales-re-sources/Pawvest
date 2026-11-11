# Broccoli growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../ROADMAP.md)

## Design

The two references supplied by Ales (2026-11-11), [life cycle](../art/broccoli/reference-life-cycle.png) and
[mature crown](../art/broccoli/reference-crown.png), establish a leafy seedling, a broad blue-green vegetative plant and a late,
dense green crown on a thick pale stalk. The game silhouette uses one central domed head, with seven tightly joined floret
clusters, six broad lobed leaves and visible branching beneath the head. Keep the crown above the foliage, with no tree-like
bare trunk. Roots remain underground. Ordinary matte stud-block Parts match the existing field art.

Standard mature height is **3.55 studs**, below the measured **5.40-stud avatar** on the same ground plane; the ground-radius limit is 2.4 studs at every growth age
and supported mass. Harvested mass changes crown dimensions by the shared cube-root scale; foliage grows more conservatively.
Seed variation changes leaf lengths, angles, stalk lean and crown proportions; seed 1 is the authored baseline.

| Growth | Review pose |
|---|---|
| 0% | Tiny stalk and paired seed leaves; no exposed seed, roots or crown. |
| 20% | Two emerging broad true leaves above the seed leaves. |
| 50% | Established layered foliage; the first tight central green bud appears. |
| 75% | Thickening stalk and widening, branching crown above the leaves. |
| 100% | Dense dark-green domed crown with smaller raised bud blocks; blue-green lobed leaves and pale ribs remain below it. |

Leaves extend from attached petioles and unfold at connected sections. The late crown expands from the stalk's current tip;
each branch and its floret cluster move together. Closed green florets are the ripe cue; no yellow flowers or glowing effects.
The existing **two-hour** production duration and whole-square clearing harvest remain unchanged. This is annual whole-plant
art, without separate collectible fruit slots, profile fields, remotes or economy changes.

## Recipe and review

[`BroccoliPlant.luau`](../../src/ReplicatedStorage/BroccoliPlant.luau) uses the shared `PlantKit` rig: **108 Parts**
(one stalk, two seed leaves, six seven-Part true leaves and seven nine-Part floret groups). A full 36-square field would use
**3,888 plant Parts**, excluding soil, pets and UI. Direct-built mid proxies use **11 / 27 / 27 Parts** for young/growing/ripe,
keeping three broad leaves, the stalk and seven connected crown lobes. Roles are `Structure`, `Foliage` and `Crown`.
Ring height is fixed at **4.5 studs**; review framing is **4.0**. There is no extra harvest effect.

[Five-pose sheet](../art/broccoli/growth-review.png) · [0%](../art/broccoli/growth-0.jpg) ·
[20%](../art/broccoli/growth-20.jpg) · [50%](../art/broccoli/growth-50.jpg) ·
[75%](../art/broccoli/growth-75.jpg) · [100%](../art/broccoli/growth-100.jpg).

Studio playtest Client command: `require(game.Players.LocalPlayer.PlayerScripts.PlantGrowthReview).Open("Broccoli", 10)`.
The ten seconds affect review playback only. The stills use seed 1, standard mass, the same square and an elevated three-quarter
camera, with the real soil, comparison Potato and field pet. The sheet crops the same rectangle from each still.
Rings and selection were checked together; the five stills hide them for the plant review.

[`broccoli_growth_checks.luau`](../../tools/broccoli_growth_checks.luau) passed on 2026-11-11 for **six seeds × three harvested
mass factors (0.35656 / 1 / 3.02985) × 101 ages**. Maximum checked ground radius was **2.321 studs**. The standard crown is
**2.313 studs wide × 1.173 high**; ripe total height across the checked seeds and masses was **2.976–4.401 studs**. Leaf petioles
and blade joints, stalk/branch/floret/bud attachments, paired initial seed leaves, late crown emergence, distinct seeds, retained
Part identity, exact visible backward seeks and non-colliding/non-touching/non-queryable flags pass. Proxies also fit the radius.

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
