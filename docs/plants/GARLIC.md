# Garlic growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../ROADMAP.md)

## Proposed mature silhouette — awaiting selection

CG12a, 2026-11-10. Start with one mostly buried ivory garlic head, a slim pale neck and tall, flat strap leaves.
The recommended study is **A, hardneck with a curled scape**. Compare **B, leaf fan without a scape**, and
**C, tall scape with a pointed closed spathe** before implementing a continuous recipe. These are display-only studies,
not registered field art or an approved design.

Ales supplied two life-cycle references on 2026-11-10: [bulb and clove development](../art/garlic/reference-growth-stages.png)
and [leaf arrangement, curled scape and pointed spathe](../art/garlic/reference-life-cycle.png). Use the first for sprout →
leaf establishment → bulb swelling → clove definition → drying outer leaves, and the second for a longer pseudostem with
alternating leaves at separated heights and a scape curl below its pointed terminal sheath. The diagrams expose roots and
bulbs to explain anatomy; the in-field plant keeps its roots hidden and its head mostly buried.

Garlic grows from a planted clove. Its flat leaves distinguish it from Onion's round hollow quills; hardneck garlic produces
a scape that curls before straightening. Real bulb-harvest readiness includes yellowing lower leaves, and growers often
remove scapes to favour the bulb. References: [Iowa State Extension](https://yardandgarden.extension.iastate.edu/how-to/growing-garlic-home-garden),
[University of New Hampshire Extension](https://extension.unh.edu/resource/growing-garlic-new-hampshire-fact-sheet).
Keeping a curled scape through game ripeness would be an intentional readability shortcut, not a literal simultaneous life-cycle stage.

- **Bulb:** a single wrapped ivory head, roughly 1.7 studs wide and 1.3 studs high at standard mass; about the lower half stays
  underground. Broad vertical lobes suggest cloves under a shared paper wrapper. Keep the crown gathered into one neck;
  do not draw a pile of peeled cloves. Small lavender-grey recesses and cream shoulders give depth under field lighting.
- **Foliage:** seven unequal blue-green strap leaves, emerging alternately at separated heights up a slender pseudostem. Flat, narrow blades bend
  outward at joined sections and taper at their tips; the centre remains taller. Target about 4 studs above soil.
- **A, recommended:** one green scape with a clear side curl and a rising tail carrying a tapered pale spathe above the leaves.
  Target total height about 4.8 studs, below the normal avatar. Preserve the loop's negative space at gameplay distance.
- **B:** no scape; fuller alternating leaf fan and two yellowing lower tips. Readiness depends more on bulb shoulders and
  leaf posture, making this closer to an ordinary bulb-harvest crop but less distinctive at a distance.
- **C:** taller scape with a bent, pointed ivory bud. Simpler silhouette and geometry than A, but less recognisably garlic.

Use ordinary matte coloured stud-block Parts. No glow or ripe particles are proposed. Ivory bulb, pale straw neck, cool green
leaves and a few straw lower tips separate Garlic from brown Onion and its lilac-white flower globe. Hidden fine roots are omitted.

## Proposed continuous growth

| Growth | Review pose |
|---|---|
| 0% | One short pointed green shoot from a buried clove. No black seed coat or paired seed leaves. Unplanted soil stays bare. |
| 20% | Two or three flat leaves extend from overlapping pale sheaths; the clove and future head stay concealed. |
| 50% | Four or five unequal blades form an upright fan; the head begins swelling and its pale shoulders first show at soil level. |
| 75% | Nearly full leaf height and widening lobed shoulders; clove ribs become distinct beneath the wrapper. In A, a scape rises and begins curling; its spathe stays closed. |
| 100% | Full wrapped ivory head, tall open fan and two lowered, straw-tipped outer leaves. In A, the scape completes its side curl and rising tail with a pointed pale spathe. A small opening with visible bulbils can be considered after silhouette selection. |

This sequence is provisional until the mature study is selected. Extend leaves successively from their bases; their joints and
scape segments must remain attached as they grow. Head swelling follows foliage establishment; preserve burial while growing
downward and widening the shoulder. Scape growth must extend a connected path, not reveal detached pieces along a mature loop.
All poses must be reversible, including 43→44→43% and ripe→young.

Seed variation should change alternating leaf lengths, fan openness, lean, bulb-lobe proportions and the scape's orientation
and curl, while preserving an open loop for A. Seed 1 is the authored baseline. Use existing planting identity and cube-root
harvested-mass scaling, with restrained canopy spread and leaf height. Whole-plant yaw may vary. Every age, yaw and supported
mass must stay within the shared 2.4-stud ground radius on the existing 5.5-stud square.

Garlic keeps its current **three-minute** production duration. Harvest clears the entire plant; scapes and cloves are not separate
collectibles. No economy, profile, remote or reward change is part of this art design. No fruit slots are needed; proposed
`PlantRole` groups are `Bulb`, `Foliage` and `Scape`.

## Scope and acceptance

1. **CG12a:** select the mature silhouette from real-soil static studies, with field pet, selection outline and avatar scale.
   Save the reproducible study tool and a review image. Record measured height, radius and Part count; keep these distinct from
   the eventual production budget.
2. **CG12b, after selection:** build one deterministic `GarlicPlant` recipe through `PlantKit` and the shared growth reviewer.
   Target at most 64 full-detail Parts (2,304 plant Parts per 36-square field), and a direct-built mid proxy at most 26 Parts.
   Validate six seeds, supported mass extremes, 101 ages, attached blades/scape, bounds, backward seeks and physics/query flags.
   Deliver only the five standard stills: 0/20/50/75/100%, same seed, mass, camera and soil square.
3. **CG12c, after art approval:** register in `PlantGrowth`; validate real `PlotView` lifecycle, corrections, exact ripeness,
   soil selection and detail transitions. Three-minute growth uses the shared 0.375-second pose interval.
4. **CG12d:** full-field and 24-plot performance route; phone and second-client checks remain separate validations.

## Static study evidence

[Mature comparison](../art/garlic/ripe-studies.jpg) · [Studio client study](../../tools/garlic_ripe_studies.luau).
Left to right: existing brown Onion, A curled scape (white selection outline), B leaf fan, C pointed spathe, then the avatar.
The real field pet occupies a neighbouring square; the avatar's following pets also appear at the right.

Studio playtest, 2026-11-10: A / B / C use **54 / 42 / 47 Parts**; measured heights are **4.79 / 4.05 / 4.67 studs**.
All have a **1.62-stud ground radius**, below the 2.4-stud limit. Their head's lower surface is 0.65 studs below soil;
its upper shoulder reaches roughly 0.65 above it. All art is anchored, non-colliding, non-touching and non-queryable.
One full 36-square field at these static budgets would use **1,944 / 1,512 / 1,692 plant Parts**, excluding soil, pets and UI.
Those are static study counts, not a measured production field or performance approval.

The study ran through real `PlotView` soil, neighbouring Onion and a field pet, with an actual selection outline and avatar
comparison. The playtest was stopped afterward. Server/client logs had no gameplay errors or warnings; Studio Assistant
reported its own plugin-version-change warning. No field action, remote or profile fixture write was used.

Current status: proposed design and Studio-checked static studies; mature selection awaits Ales. No continuous growth recipe
or production integration yet. The head still has an intentionally angular block silhouette; refine the wrapper and blade
taper in the selected design before the five growth stills.
