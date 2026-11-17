# Incubator redesign

2026-11-17 warm hatching (user combined sparks A, brick hearts C and heat lamp D of five options): while growing, at full
detail, the heater flickers like embers and lights the egg (SpotLight), amber sparkles rise from the egg top and two pink
5 × 4-stud hearts float up in turn. Full body Parts 44. Desktop Studio-validated (no heart intersections at three yaws,
states, coplanar audit, boot, the real growing pod animates); the sparks' look is not visually checked (Edit captures show no
particles). [Capture](art/incubator-review/warm-hearts.jpg). Scope and validation: `git show 08d3c94:docs/INCUBATOR_REDESIGN.md`.

2026-11-17 contour ring A (chosen after trying rear scanner B in game): at full detail an eight-sided cyan ring rises and
falls on the egg (4 s, eased), sized from `EggLook.Reach` to clear every brick, with a corner-clipped head and two trail
points (3 s lap); the scanner is removed and bands stay for the amber pulse. Full body Parts 34. Desktop Studio-validated
(3 600 poses without intersections at three yaws, states, coplanar audit, boot); a live scanning egg was not placed.
[Capture](art/incubator-review/contour-ring.jpg). Scope and validation: `git show 4ca8901:docs/INCUBATOR_REDESIGN.md`.

2026-11-17 rear scanner B (chosen over contour ring A and rising ripples D; replaced by A above the same day): at full detail a heater emitter bar projects a
see-through cyan sheet to a scan line sweeping the nest back / front (eased, 3 s), replacing the scan square, travelling light
and trail; bands stay for the amber pulse. Full body Parts 25. Desktop Studio-validated (geometry at three yaws, states, coplanar
audit, boot); a live scanning egg was not placed. [Capture](art/incubator-review/rear-scanner.jpg). Scope and validation:
`git show 73ae4d7:docs/INCUBATOR_REDESIGN.md`.

2026-11-17 number plates: two-sided plates above the rear heaters at full / mid detail; floating labels show only status.
The plot strip's six edge beams now match the pavilion's Plastic / Inlets. Desktop Studio-validated, including plate clicks.
Scope and validation: `git show a535c0e:docs/INCUBATOR_REDESIGN.md`.

2026-11-17 surface fix: control housing width 0.68 leaves its inner face 0.06 studs clear of the lower cheek; simplified side
bottoms embed in the base instead of sharing the nest's bottom plane. Coplanar audit clean for full / mid / low at 0° / 90° / 180°;
Studio boot checked. The visible top edges, footprint and part counts are unchanged.

2026-11-17 phases: 30 s cyan scanning sweep + travelling edge light / fading trail (replaced by the rear scanner above) + Scanning… (inside the existing hatch timer), then a soft pulsing amber nest glow
and countdown; ready stays green with warming off. Stored anchors survive rejoin; instant-ready eggs skip the scan.
Desktop Studio-validated. Phase scope, visual review and validation: `git show f636dd0:docs/INCUBATOR_REDESIGN.md`.
Travelling-light C scope and validation: `git show 0a76951:docs/INCUBATOR_REDESIGN.md`.

2026-11-17 access: Hatchery HUD beside Barn (ready-egg badge) near the own plot, or click/tap any own incubator from either side.
Whole-pod hover; no hatchery E prompt. Barn keeps its existing availability; visible farm buttons center together.
Desktop Studio-validated; physical touch and live checks remain open. Access scope and validation: `git show 285eb18:docs/INCUBATOR_REDESIGN.md`.

2026-11-17: egg kind is fixed at purchase / free placement and hidden server-side until Hatch. New eggs use shared tiers:
Common / Uncommon 5 m, Rare 1 h, Epic / Legendary 4 h. Nest rows show only the egg and countdown. A small square trash button uses ConfirmTap:
orange OK? on first tap, discard on the second tap within 3 s; discarding gives no refund. Odds are separate rarity / percentage
rows, with only offline hatching and no-refund text in the tip. Existing deadlines and instant first pet are preserved.
Implemented and desktop Studio-validated; physical touch and live validation remain open. As built: [GDD §7.2](GDD.md#72-eggs).
Compact-action / odds scope and Studio validation: `git show b2748e8:docs/INCUBATOR_REDESIGN.md`.
Earlier hidden-pet / shared-timer validation and snapshot details: `git show e7aff11:docs/INCUBATOR_REDESIGN.md`.
Initial egg-timing validation: `git show 79e61e3:docs/INCUBATOR_REDESIGN.md`.

2026-11-17: pods and eggs now face the central path towards the barn (90° turn, plot-local −X), Studio-validated in three
plot orientations and at all detail levels. Centres, footprints and label anchors are preserved.

Implemented and Studio-validated on desktop, 2026-11-16: Cross-lapped oval eggs + Tall pavilion + Quiet rows + Nearby labels + Open hatch pod bodies (selected by the user). As-built behavior is in [GDD §7.6](GDD.md#76-pet-garden-minigame-p2), script APIs in [LAYOUT](LAYOUT.md). Physical phone touch and live validation remain open.

![Path-facing open hatch pod viewed from the central path](art/incubator-review/open-pod-path-facing.jpg)

Earlier design options / acceptance checks: `git show d24f132:docs/INCUBATOR_REDESIGN.md`. The three body concepts and their disposable Studio builder are archived at `git show 44431fe:docs/INCUBATOR_REDESIGN.md` and `git show 44431fe:tools/incubator_body_review.luau`.
