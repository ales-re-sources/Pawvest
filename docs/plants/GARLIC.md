# Garlic growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../ROADMAP.md)

## Selected mature silhouette

Ales selected **A, hardneck with a curled scape**, on 2026-11-10 (CG12a): one half-buried ivory garlic head, a slim pale neck,
tall flat strap leaves, a side curl and a rising tail with a pointed closed spathe. The continuous recipe is built and
Studio-checked (CG12b); the five growth stills await art review. Field registration is pending.

[Five-pose sheet](../art/garlic/growth-review.png) · [0%](../art/garlic/growth-0.jpg) ·
[20%](../art/garlic/growth-20.jpg) · [50%](../art/garlic/growth-50.jpg) ·
[75%](../art/garlic/growth-75.jpg) · [100%](../art/garlic/growth-100.jpg).

Studio playtest Client command: `require(game.Players.LocalPlayer.PlayerScripts.PlantGrowthReview).Open("Garlic", 10)`.
The ten seconds affect review playback only; production duration remains three minutes.

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
- **Selected A:** one green scape with a clear side curl and a rising tail carrying a tapered pale spathe above the leaves.
  Target total height about 4.8 studs, below the normal avatar. Preserve the loop's negative space at gameplay distance.
- The unselected studies were B (no scape) and C (taller scape with a bent pointed bud).

Use ordinary matte coloured stud-block Parts. No glow or ripe particles are proposed. Ivory bulb, pale straw neck, cool green
leaves and a few straw lower tips separate Garlic from brown Onion and its lilac-white flower globe. Hidden fine roots are omitted.

## Continuous growth

| Growth | Review pose |
|---|---|
| 0% | One short pointed green shoot from a buried clove. No black seed coat or paired seed leaves. Unplanted soil stays bare. |
| 20% | Two or three flat leaves extend from overlapping pale sheaths; the clove and future head stay concealed. |
| 50% | Four or five unequal blades form an upright fan; the head begins swelling and its pale shoulders first show at soil level. |
| 75% | Nearly full leaf height and widening lobed shoulders; clove ribs become distinct beneath the wrapper. The scape rises and begins curling; its spathe stays closed. |
| 100% | Full wrapped ivory head, tall open fan and two lowered, straw-tipped outer leaves. The scape completes its side curl and rising tail with a pointed pale closed spathe. |

Leaves extend successively from their bases; their joints and scape segments remain attached as they grow. Head swelling follows
foliage establishment, growing downward and widening the shoulder. Scape growth extends a connected path base-first; its bud
follows the current endpoint, including during the curl. All poses are reversible, including 43→44→43% and ripe→young.

Seed variation should change alternating leaf lengths, fan openness, lean, bulb-lobe proportions and the scape's orientation
and curl, while preserving an open loop for A. Seed 1 is the authored baseline. Use existing planting identity and cube-root
harvested-mass scaling, with restrained canopy spread and leaf height. Whole-plant yaw may vary. Every age, yaw and supported
mass must stay within the shared 2.4-stud ground radius on the existing 5.5-stud square.

Garlic keeps its current **three-minute** production duration. Harvest clears the entire plant; scapes and cloves are not separate
collectibles. No economy, profile, remote or reward change is part of this art design. No fruit slots are needed;
`PlantRole` groups are `Bulb`, `Foliage` and `Scape`.

## Recipe and Studio validation

[`GarlicPlant.luau`](../../src/ReplicatedStorage/GarlicPlant.luau) builds once through `PlantKit`: **54 Parts** (21 head/neck/stem,
21 blade, 10 scape and 2 spathe). A 36-square field would use **1,944 plant Parts**, excluding soil, pets and UI. Direct-built
mid proxies use **9 / 14 / 26 Parts** for young / growing / ripe, retaining alternating blades and the full mature curl.
Ring height is fixed at **5.5 studs**; review framing is **5.0**. No harvest effect is added.

[`garlic_growth_checks.luau`](../../tools/garlic_growth_checks.luau) passed on 2026-11-10 for **six seeds × three harvested mass
factors (0.35656 / 1 / 3.02985) × 101 ages**. Maximum full-model ground radius was **1.89 studs**; proxies also stayed inside
2.4 studs. Checks cover blade hinges and joints, scape segments and moving bud attachment, exact visible backward seeks,
restored initial pose, seed individuality, a single initial sprout, hidden early head, half-buried ripe head and physics/query flags.
Standard seed 1 is **4.78 studs tall**, with a **1.70-stud-wide, 1.30-stud-high head, 50.1% exposed**. Ripe height across the checked
seeds and masses ranges **4.14–5.61 studs**. The three-minute production interval remains **0.375 seconds** through shared timing.

The shared reviewer exercised five poses, six seeds, seed and size changes, rings, play/pause and Close through real clicks.
The five stills use seed 1, standard mass, the same camera and soil square, with the real comparison plant and field pet. The
sheet crops the same rectangle from each still. Ring and selection composition were checked together before capture.
Close removed the reviewer and the playtest was stopped. No recipe/gameplay errors were logged; Studio Assistant emitted its
plugin-version warning, and one capture command encountered a reviewer that had already been closed. Capture completed after
coordinating Studio use with Ales. No field actions or profile fixture writes were performed.

**Current status:** mature A selected; continuous growth and proxies Studio-checked. Five growth stills await Ales's review.
**Next (CG12c), after art approval:** register in `PlantGrowth` and validate production `PlotView` lifecycle, corrections, exact
ripeness, soil selection and detail transitions. Full-field / 24-plot performance, real phone and second client remain CG12d.

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

The selected recipe retains A's angular wrapped head, alternating blades and pointed closed spathe. Static studies remain
historical comparison evidence; the five continuous-growth stills above are the current review deliverable.
