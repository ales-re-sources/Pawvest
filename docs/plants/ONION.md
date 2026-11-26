# Onion growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../PLANT_GROWTH.md#crops-and-status)

## Selected design

**Brown onion** ([studies A / B / C / D](../art/onion/ripe-studies.jpg), `onion_ripe_studies.luau`) following a life-cycle reference
(germination hook, bulb initiation, bulb enlargement, flowering bolt with umbel, ripe onion):

- **Half-buried brown bulb:** about 58% of the bulb above soil; the widest slab at the soil line. Eight stacked octagonal slabs; with half
  buried, six read as a stepped pagoda (known roughness: slabs still read slightly stepped; the 0% seed coat is small at review distance).
- **Tall slim quills:** about 3.3 studs above soil, roughly four times the exposed bulb.
- **Flower scape and umbel as the ripeness cue** (a mostly buried bulb is a weak cue): the stalk rises through the fan from 45%, shows a
  closed bud at 75%, opens into a white-lilac globe of florets at 100%. Outer leaves only droop slightly and tips turn straw. Seed formation
  not drawn.
- Not B bulb-forward (growth would inflate the bulb), not a red-purple skin.

Annual: harvest clears the plant. No fruit slots; `PlantRole` `Bulb`, `Foliage`, `Seed` or `Flower`.

**Distinct from beet** (a beet study would sit in the same half-buried slot, see [Golden Carrot](GOLDEN_CARROT.md)): onion is brown and
papery with a pale tapered neck, slim cylindrical quills and a flower globe; beet is deep red / purple, smooth, with broad red-veined
leaves. Keep that split.

Colours: skin amber-brown (`150,92,48`), lighter copper shoulder, pale straw neck, two dark paper seams; quills blue-green with a pale
sheath and lighter tip. Roots omitted.

## Growth

[Five-pose sheet](../art/onion/growth-review.png) · [0%](../art/onion/growth-0.jpg) · [20%](../art/onion/growth-20.jpg) ·
[50%](../art/onion/growth-50.jpg) · [75%](../art/onion/growth-75.jpg) · [100%](../art/onion/growth-100.jpg)

| Growth | Pose |
|---|---|
| 0% | Germination: one hooked shoot with the black seed coat on its tip above a tiny pale shank. Unplanted square stays bare. |
| 20% | Shoot straightened, seed coat gone; two or three thin quills rise from a pale shank (bulb initiation). |
| 50% | Fan of slim quills over a swelling, still white bulb sinking into the soil. The scape starts inside the fan. |
| 75% | All eight quills near full height; bulb nearly full and tan-brown; a pale bud on the scape peeks above the leaves. |
| 100% | Brown half-buried bulb with tapered neck, slim leaves with straw tips, open white-lilac umbel on a tall scape. |

Quills emerge in sequence from the centre (later ones taller) and extend base-first through three joined rods. The bulb widens, rises and
sinks at once. Hook straightens 6–30%; scape rises 45–80%; bud grows 58–80% and from 84% shrinks as ten florets move outward into the
umbel. 43→44→43% seek restores the pose. Seeds vary quill yaw, lean, length, emergence, droop, bulb width and depth, scape length, lean and
floret turn; whole-plant rotation seeded. Cube-root mass scaling chiefly on the bulb, constrained length factor for leaves and scape;
a horizontal fit keeps the fan inside the 2.4-stud radius.

## Recipe

[`OnionPlant.luau`](../../src/ReplicatedStorage/OnionPlant.luau), `PlantKit`: **59 Parts** (19 bulb: 16 slab, 2 seam, 1 neck; 1 seed coat;
24 quill rods; 2 scape rods, 2 bud, 1 core, 10 florets); 36-square field 2 124. Mid proxy (upper slabs, neck, every other quill, scape,
half the florets) **13 / 20 / 26 Parts**. Ring fixed 5.0 studs (height barely follows mass), review framing 4.6. No harvest effect.
Seed 1 standard: ripe height 4.36, bulb 1.65 high × 2.07 wide; ripe height 3.6–5.3 over seeds / masses, max radius 1.81, bulb 50–60%
above soil. Checks: `onion_growth_checks.luau`, `onion_integration_checks.luau`. Open: performance, real phone, second client.
