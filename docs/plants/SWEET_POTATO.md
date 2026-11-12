# Sweet potato growth art

[Shared authoring workflow](../PLANT_GROWTH.md) · [Status](../ROADMAP.md)

## Selected design

Ales selected **C, the trained fan**, and approved its continuous growth with the fuller foliage on 2026-11-12.
Three vines grow up a small rigid fan, inspired by the indoor reference. The supported ornamental interpretation omits the
bottle and giant exposed mother root. Eighteen broad heart leaves face outward, with two smaller staggered leaves between
each vine's original nodes. Pale trumpet flowers have purple funnels and dark throats; three tapered reddish storage-root
shoulders emerge late. These cues distinguish it from Potato's upright compound foliage, small star flowers and round brown
shoulders. Exposed roots are an intentional readability shortcut; flowers are an identity accent rather than a harvest clock.

References: [life cycle](../art/sweet-potato/reference-life-cycle.png), [cultivation timeline](../art/sweet-potato/reference-timeline.png),
[indoor trained vine](../art/sweet-potato/reference-indoor.png), [trumpet flowers](../art/sweet-potato/reference-flowers.png).
[Original mature studies](../art/sweet-potato/ripe-studies.png) preserve the A spreading patch / B lifted cascade / C trained fan choice.

## Continuous growth

| Growth | Pose |
|---|---|
| 0% | The full-sized fan is installed. A tiny green slip breaks the soil between its feet. |
| 20% | Three unequal vines establish their lower stems and first unfolding heart leaves. |
| 50% | Successive nodes climb the fan; original and staggered middle leaves open as lower stems turn reddish. |
| 75% | Upper leaves continue to unfold, both pale trumpets open and small pink root shoulders emerge. |
| 100% | The full leafy fan settles above three larger reddish tapered storage-root shoulders. |

[Five-pose sheet](../art/sweet-potato/growth-review.png) · [0%](../art/sweet-potato/growth-0.png) ·
[20%](../art/sweet-potato/growth-20.png) · [50%](../art/sweet-potato/growth-50.png) ·
[75%](../art/sweet-potato/growth-75.png) · [100%](../art/sweet-potato/growth-100.png).

## Recipe and field behavior

[`SweetPotatoPlant.luau`](../../src/ReplicatedStorage/SweetPotatoPlant.luau) is registered in the shared `PlantGrowth` system
(CG18b/c). `PlantKit.recipe` supplies construction, reversible posing, destruction and direct proxy generation. The full model
reuses **169 Parts**: five fixed supports, 12 stem segments, 108 leaf/stalk/vein pieces, three ties, 15 storage-root pieces and
26 flower pieces. A full-detail 36-square field uses 6,084 plant Parts before soil, pets or UI. Mid-detail proxy stages use
20 / 75 / 97 Parts; low detail hides crop art. Orientation and the 5-stud ring height stay fixed.

Seed variation changes vine heights, lean, leaf angles/sizes and root proportions. Seed 1 is the reproducible authored baseline:
4.929 studs tall and 2.282-stud maximum Part-corner radius. The supported seed/mass checks remain inside the 2.4-stud ground
radius throughout growth. Storage roots scale by the cube root of harvested mass, including Sorter; their centres move inward
at large sizes. Canopy width is constrained and rigid equipment does not scale with mass. The three roots have stable fruit-slot
IDs, mature attachments and explicit five-Part groups; flowers remain separate accents. Added leaf variation draws follow the
original shape draws, preserving the original vines, roots and flowers.

Production growth remains **eight hours**, with the shared scheduler's **30-second** growth cadence and immediate state
corrections/exact ripeness. Harvest clears the whole square and retains the ordinary success pop; there is no custom harvest effect.
No stored fields, rewards or crop IDs changed.

Studio playtest Client command: `require(game.Players.LocalPlayer.PlayerScripts.PlantGrowthReview).Open("SweetPotato", 10)`.
The ten seconds affect review playback only.

## Validation status

Growth geometry and production `PlotView` lifecycle/detail transitions, stable identity, corrections, exact ripeness, soil
selection and harvest/replant feed fixtures are Studio-validated. Checks use disposable client geometry and public-feed fixtures,
with no saved-data edits (`tools/sweet_potato_growth_checks.luau`, `tools/sweet_potato_integration_checks.luau`).
Server/client boot logs were clean. Full-field/24-plot performance, real phone, second client and live validation remain open.
