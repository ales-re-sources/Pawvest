# Sweet potato growth art

[Shared authoring workflow](../PLANT_GROWTH.md) · [Status](../ROADMAP.md)

## Mature study — awaiting selection

Three static mature studies precede the continuous recipe, following the shared art review gates.
The supplied references guide organ shapes and growth; their captions are reference material, not game requirements.

![Mature studies](../art/sweet-potato/ripe-studies.png)

- **A — spreading patch (recommended):** low unequal runners, broad heart-shaped leaves, two pale trumpet flowers and
  three reddish tapered root shoulders. The strongest silhouette difference from upright Potato.
- **B — lifted cascade:** a higher central crown with leafy arching runners descending toward the soil; larger exposed
  root shoulders remain visible below it. More upright readability without a rigid support.
- **C — trained fan:** three leafy vines tied to a small rigid fan support, inspired by the indoor reference. This is a
  supported ornamental interpretation, rather than the indoor bottle or a giant exposed mother root.

All studies use a 5.5-stud soil square, standard harvested mass and the same field-style materials, with an avatar for scale.
Leaves have a basal notch and a pointed tip; flowers have a flared pale rim, purple funnel and dark throat.
Ordinary Potato instead has upright unequal shoots, paired compound leaflets, small white/yellow star flowers and round brown tuber tops.
Sweet potato's exposed reddish root shoulders are an intentional harvest-readability shortcut; fine underground roots are omitted.
Flowers are an identity accent, not a claim that flowering determines the real crop's harvest readiness.

Reference images: [life cycle](../art/sweet-potato/reference-life-cycle.png),
[cultivation timeline](../art/sweet-potato/reference-timeline.png),
[indoor trained vine](../art/sweet-potato/reference-indoor.png),
[trumpet flowers](../art/sweet-potato/reference-flowers.png).

## Scope and acceptance

This milestone produces only the three mature studies and a comparison image. No `SweetPotatoPlant` module is registered,
no field art changes, and no saved data changes. Existing eight-hour timing and whole-square harvest stay as built.
The study runner is `tools/sweet_potato_ripe_studies.luau`; its disposable Studio folder must be removed after capture.

- Each study fits a 2.4-stud ground radius, including every Part corner, and stays within 180 plant Parts.
- Compare all three from one camera, against identical soil and an avatar on the same ground plane.
- Inspect heart-leaf silhouette, flower throat and exposed root cues in Studio, then run one boot and check both logs.
- After Ales chooses a mature variant: use `PlantKit.recipe` for one deterministic bounded geometry function, shared
  phase/seed/size/Rig helpers and reversible attached growth. Present five stills at 0/20/50/75/100% before field integration.
- Continuous growth should establish a small slip, extend successive runner nodes, unfold attached leaves, then develop
  flower accents and reddish root shoulders. Keep the supported option's frame rigid from planting if selected.

Growth, seed/mass extremes, backward seeks, proxies, production lifecycle and performance remain later acceptance checks.

## Static study validation

Studio Edit checks (2026-11-12): A / B / C use 125 / 125 / 133 plant Parts, measure 1.37 / 2.65 / 4.61 studs above soil and
have maximum corner radii 2.28 / 2.26 / 2.04 studs. The reference avatar is 5.18 studs tall. Rendered study checked after
correcting the pointed leaf wedges and separating the exposed roots. These are study counts, not a production recipe budget.
One Studio boot produced zero server/client warnings or errors; the playtest was stopped. The disposable study was removed,
the camera restored and both existing StarterGui screens left enabled. Localization build/check/lint pass with no changed strings.
