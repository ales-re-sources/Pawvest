# Sweet potato growth art

[Shared authoring workflow](../PLANT_GROWTH.md) · [Status](../PLANT_GROWTH.md#crops-and-status)

## Selected design

**Trained fan** (chosen from A spreading patch / B lifted cascade / C trained fan, [studies](../art/sweet-potato/ripe-studies.png)):
three vines grow up a small rigid fan (the supported ornamental interpretation of the indoor reference; no bottle, no giant exposed mother
root). Eighteen broad heart leaves face outward, with two smaller staggered leaves between each vine's original nodes. Pale trumpet flowers
have purple funnels and dark throats; three tapered reddish storage-root shoulders emerge late. These cues separate it from Potato's
upright compound foliage, small star flowers and round brown shoulders. Exposed roots are a readability shortcut; flowers are an identity
accent, not a harvest clock.

References: [life cycle](../art/sweet-potato/reference-life-cycle.png), [cultivation timeline](../art/sweet-potato/reference-timeline.png),
[indoor trained vine](../art/sweet-potato/reference-indoor.png), [trumpet flowers](../art/sweet-potato/reference-flowers.png).

## Growth

[Five-pose sheet](../art/sweet-potato/growth-review.png) · [0%](../art/sweet-potato/growth-0.png) · [20%](../art/sweet-potato/growth-20.png) ·
[50%](../art/sweet-potato/growth-50.png) · [75%](../art/sweet-potato/growth-75.png) · [100%](../art/sweet-potato/growth-100.png).

| Growth | Pose |
|---|---|
| 0% | The full-sized fan is installed. A tiny green slip breaks the soil between its feet. |
| 20% | Three unequal vines establish lower stems and first unfolding heart leaves. |
| 50% | Successive nodes climb the fan; original and staggered middle leaves open as lower stems turn reddish. |
| 75% | Upper leaves keep unfolding, both pale trumpets open, small pink root shoulders emerge. |
| 100% | Full leafy fan above three larger reddish tapered storage-root shoulders. |

## Recipe

[`SweetPotatoPlant.luau`](../../src/ReplicatedStorage/SweetPotatoPlant.luau), `PlantKit.recipe`: **169 Parts** (five fixed supports, 12
stem segments, 108 leaf/stalk/vein pieces, three ties, 15 storage-root pieces, 26 flower pieces); 36-square field 6 084. Mid proxies
**20 / 75 / 97 Parts**; low detail hides crop art. Fixed orientation, fixed ring height 5 studs. No custom harvest effect.

Seeds vary vine heights, lean, leaf angles / sizes, root proportions; seed 1: 4.929 studs tall, max Part-corner radius 2.282, all
supported seeds / masses inside 2.4. Storage roots scale by the cube root of harvested mass (Sorter included) and move inward at large
sizes; canopy width is constrained, rigid equipment does not scale. The three roots have stable fruit-slot ids, mature attachments and
explicit five-Part groups; flowers stay separate accents. Leaf variation draws come after the original shape draws (keeps the original
vines, roots and flowers). Checks: `sweet_potato_growth_checks.luau`, `sweet_potato_integration_checks.luau`. Open: full-field
performance, real phone, second client.
