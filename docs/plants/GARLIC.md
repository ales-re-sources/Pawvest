# Garlic growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../PLANT_GROWTH.md#crops-and-status)

## Design

**Hardneck with a curled scape** (chosen from three studies; B no scape and C taller scape with a bent bud were rejected): one
half-buried ivory head, slim pale neck, tall flat strap leaves, a side curl and a rising tail with a pointed closed spathe. The
half-exposed bulb is a deliberate readability shortcut (approved).

[Five-pose sheet](../art/garlic/growth-review.png) · [0%](../art/garlic/growth-0.jpg) · [20%](../art/garlic/growth-20.jpg) ·
[50%](../art/garlic/growth-50.jpg) · [75%](../art/garlic/growth-75.jpg) · [100%](../art/garlic/growth-100.jpg).
References: [bulb and clove development](../art/garlic/reference-growth-stages.png), [leaf arrangement, curled scape and pointed
spathe](../art/garlic/reference-life-cycle.png) (they expose roots to show anatomy; the in-field plant hides roots and keeps the head
mostly buried). Keeping the curled scape through game ripeness is a readability shortcut, not a literal life-cycle stage.

- **Bulb:** single wrapped ivory head, ~1.7 studs wide, 1.3 high at standard mass; the lower half stays underground. Broad vertical
  lobes suggest cloves under a shared wrapper, crown gathered into one neck (no pile of peeled cloves). Lavender-grey recesses and
  cream shoulders give depth.
- **Foliage:** seven unequal blue-green flat strap leaves, alternating at separated heights up a slender pseudostem; blades bend outward
  at joined sections and taper; the centre stays taller. ~4 studs above soil. Flat leaves distinguish it from Onion's round quills.
- **Scape:** one green scape with a clear side curl (keep the loop's negative space) and a rising tail with a tapered pale spathe;
  total height ~4.8 studs, below the avatar.
- Matte stud-block Parts; no glow or particles. Ivory bulb, pale straw neck, cool green leaves and a few straw lower tips separate it
  from brown Onion and its lilac-white flower globe. Roots omitted.

## Growth

| Growth | Pose |
|---|---|
| 0% | One short pointed green shoot from a buried clove. No seed coat or paired seed leaves. Unplanted soil stays bare. |
| 20% | Two or three flat leaves from overlapping pale sheaths; head concealed. |
| 50% | Four or five unequal blades form an upright fan; head begins swelling, pale shoulders first show at soil level. |
| 75% | Nearly full leaf height, widening lobed shoulders, clove ribs distinct under the wrapper. Scape rises and begins curling; spathe closed. |
| 100% | Full wrapped ivory head, tall open fan, two lowered straw-tipped outer leaves. Scape completes its curl and rising tail with a pointed closed spathe. |

Leaves extend from their bases; joints and scape segments stay attached. Head swelling follows foliage establishment, growing downward
and widening. The scape extends base-first and its bud follows the current endpoint, also during the curl. All poses reversible.
Seeds vary alternating leaf lengths, fan openness, lean, lobe proportions, scape orientation and curl (keeping an open loop); whole-plant
yaw may vary. Cube-root harvested-mass scaling; every age, yaw and supported mass stays inside the 2.4-stud ground radius.

Grow time: `CropConfig` (updates every 1/480 of it, shared cadence). Harvest clears the whole plant; scapes and cloves are not collectibles. No fruit
slots; `PlantRole` groups are `Bulb`, `Foliage`, `Scape`.

## Recipe and field integration

[`GarlicPlant.luau`](../../src/ReplicatedStorage/GarlicPlant.luau), `PlantKit`: **54 Parts** (21 head/neck/stem, 21 blade, 10 scape,
2 spathe); 36-square field 1 944. Mid proxies **9 / 14 / 26 Parts** (young / growing / ripe) keep alternating blades and the full
mature curl. Ring height fixed **5.5 studs**, review framing 5.0. No harvest effect. Seed 1: 4.78 studs tall, head 1.70 × 1.30,
50.1% exposed; ripe height 4.14–5.61 across seeds / masses; max full-model radius 1.89. Checks: `garlic_growth_checks.luau` (six seeds
× masses 0.35656 / 1 / 3.02985 × 101 ages), `garlic_integration_checks.luau`. Exact ripe boundary completes the scape and stops
sampling; a backward correction hides it again. Open: real phone, second client (status table).
