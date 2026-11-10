# Onion growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../ROADMAP.md)

## Selected design

Ales chose a **brown onion** (2026-11-10) after seeing the static studies ([A / B / C / D](../art/onion/ripe-studies.jpg)) and a
life-cycle reference (germination hook, bulb initiation, bulb enlargement, flowering bolt with umbel, ripe onion). Review notes
the same day: the bulb should be **more burrowed**, the leaves **much taller in proportion**, and the flowering stage kept. The
design follows them:

- **Half-buried brown bulb**: about 58% of the bulb shows above soil; the widest slab sits at the soil line.
- **Tall slim quills**: leaves about 3.3 studs above the soil, roughly four times the exposed bulb.
- **Flower scape and umbel as the ripeness cue.** With the bulb mostly underground it is a weak cue, so a flower stalk rises
  through the fan from 45%, shows a closed bud at 75% and opens into a white-lilac globe of florets at 100%. This replaces the
  earlier folding-tops cue; the outer leaves only droop slightly and their tips turn straw. Seed formation is not drawn.
- Not chosen: B bulb-forward (growth would inflate the bulb) and the red-purple skin.

Onion is an annual here: harvest clears the whole plant. No fruit slots; Parts carry `PlantRole` `Bulb`, `Foliage`, `Seed` or
`Flower`.

**Distinct from beet** (the beet study noted in [Golden Carrot](GOLDEN_CARROT.md) would sit in the same half-buried slot): an
onion is brown and papery with a pale tapered neck, slim cylindrical quills and a flower globe; a beet is deep red or purple, smooth,
with broad red-veined leaves. Keep that leaf and colour split when a beet is designed.

Skin: amber-brown (`150,92,48`), lighter copper shoulder, pale straw neck, two dark paper seams. Quills: blue-green with a
pale sheath and a lighter tip. Roots are omitted. The bulb is eight stacked octagonal slabs; with half of it buried, six read
as a stepped pagoda.

## Growth and harvest

[Five-pose sheet](../art/onion/growth-review.png) · [0%](../art/onion/growth-0.jpg) · [20%](../art/onion/growth-20.jpg) ·
[50%](../art/onion/growth-50.jpg) · [75%](../art/onion/growth-75.jpg) · [100%](../art/onion/growth-100.jpg)
(seed 1, standard mass, the reviewer's own camera; the sheet crops the same rectangle from each).

| Growth | Pose (maps to the life cycle) |
|---|---|
| 0% | Germination: one hooked shoot with the black seed coat on its tip, above a tiny pale shank. An unplanted square stays bare. |
| 20% | The shoot has straightened and lost the seed coat; two or three thin quills rise from a pale shank (bulb initiation). |
| 50% | A fan of slim quills over a swelling, still white bulb that is sinking into the soil (bulb enlargement). The scape starts inside the fan. |
| 75% | All eight quills near full height; the bulb is nearly full and tan-brown. A pale bud on the scape peeks above the leaves (flowering bolt). |
| 100% | Ripe: brown half-buried bulb with a tapered neck, slim leaves with straw tips, and an open white-lilac umbel on a tall scape. |

Quills emerge in sequence from the centre (later ones are taller) and extend base-first through three joined rods, with
overlapping timings. The bulb widens, rises and sinks at once, so it appears rather than pops. The hook straightens between 6%
and 30%. The scape rises 45–80%, the bud grows 58–80% and, from 84%, shrinks as ten florets move outward into the umbel. A
43→44→43% seek restores the same pose.

Seeds vary quill yaw, lean, length, emergence time and droop, bulb width and depth, scape length, lean and floret turn. Whole-plant
rotation is seeded. Harvest mass uses cube-root scaling chiefly for the bulb, with a constrained length factor for leaves and
scape; a horizontal fit keeps the fan inside the 2.4-stud ground radius. Production duration stays **one minute**, posed at the
5 Hz floor.

## Recipe

[`OnionPlant.luau`](../../src/ReplicatedStorage/OnionPlant.luau), built on `PlantKit`: **59 Parts** (19 bulb: 16 slab, 2 seam, 1
neck; 1 seed coat; 24 quill rods; 2 scape rods, 2 bud, 1 core, 10 florets), so a 36-square field uses 2,124 plant Parts before soil,
pets or UI. The direct mid proxy builds the upper bulb slabs, neck, every other quill, the scape and half the florets:
**13 / 20 / 26 Parts** for young / growing / ripe. Ring height is a fixed 5.0 studs (the plant's height barely follows mass);
review framing 4.6.

Studio validation (2026-11-10): [`onion_growth_checks.luau`](../../tools/onion_growth_checks.luau) passed for six seeds × three
harvested masses (0.357 / 1 / 3.03) × 101 ages: maximum ground radius **1.81 studs**, every quill and scape joint attached, bulb
50–60% above soil, exact visible backward seeks and restored initial pose, distinct seeds, no input/physics interception.
Seed-1 standard mass: ripe height 4.36 studs, bulb 1.65 high and 2.07 wide across its octagon corners. Ripe height across seeds
and masses ranges 3.6–5.3 studs (the avatar is 5.46); the tallest pose at any age is 5.3. Playtest boot clean.

**Status:** art approved by Ales (2026-11-10); registered in `PlantGrowth` (CG11c). Known roughness: the bulb's slabs still read
slightly stepped, and the 0% seed coat is small at the reviewer's camera distance. The first static studies are historical:
[`onion_ripe_studies.luau`](../../tools/onion_ripe_studies.luau).

Field integration (2026-11-10): [`onion_integration_checks.luau`](../../tools/onion_integration_checks.luau) passed through the
production `PlotView` with disposable public-feed fixtures and no remotes or profile writes: three recipes build 177 full Parts;
the ripe umbel follows the feed; a server-time correction keeps the same plant, soil and pet instances; the exact ripe moment
(growth 1, no further sampling) is not missed and a backward correction clears the umbel; crop art does not block the soil
selection ray; full → mid → low → full keeps the seed's identity, with mid proxies of **13 / 20 / 26 Parts** for young / growing /
ripe and nothing at low detail. The 60 s crop is sampled at the 0.2 s floor (5 Hz). No harvest effect (`PlayHarvest` is nil).
Playtest boot clean. Open: performance (full field and the 24-plot route), real phone, second client.
