# Incubator redesign

## Contour ring A (2026-11-17, implemented and desktop Studio-validated)

After trying B in game, the user chose A instead (A, B and both were built behind a temporary style switch; only A is kept).
Full detail only: replaces the rear scanner. Eight Neon segments (0.15 thick, transparency 0.15) form an octagon that rises
from 0.15 to 3.05 studs above the nest and back every 4 s (cosine ease, starting at the bottom). Its size follows the egg:
`EggLook.Reach(n)` gives each full-detail course's reach along the axes / diagonals; the ring uses the larger reach at the two
ends of the head's height (±0.11) so it changes size smoothly and clears every brick it passes, plus a 0.07 gap.
Segments touch only along their inner edges (no overlapping coplanar faces). A bright 0.22 head (≤ 0.6 long, never more
than two edges) is clipped at the corners and laps in 3 s; two trail balls follow. Bands remain for the amber growing pulse.
Mid strip / low unchanged. Full body Parts 25 → 34. B's scan line fix (raised to clear the egg's bottom face) left with B.
Acceptance: no ring / head / trail intersection with egg or body at three yaws; head never outside the cheeks; head length
constant; ring hidden outside scanning and restored on a new scan; coplanar audit clean; boot clean.

Validation (desktop Studio, 2026-11-17):
- Counts full / mid / low 34 / 8 / 3. 2 400 poses (ring and both, yaw 0 / 90 / 180, Golden egg) and 1 200 more after B was
  removed (Basic egg): GetPartsInPart found no intersection of any ring segment, head or trail with egg bricks or body parts.
  Head in 1–2 pieces, total length error ≤ 0.00007; ring Y 2.000–4.900; widest ring outer apothem 1.786 (cheeks at 1.85).
- First try (0.12 gap, plain interpolation) put the head into the cheeks and once into course 8; fixed by the gap 0.07 and the
  two-ends reach bound before the counts above.
- States: empty → scanning (12 ring parts visible, bands hidden, cyan glow) → growing (ring hidden, heater on, amber bands)
  → ready (all off) → scanning (restored) → empty.
- Static coplanar audit (CanQuery on disposable pods): 12 pods, three yaws × four poses, 660 visible parts, clean.
- [Capture](art/incubator-review/contour-ring.jpg): ring low and high; the right pod shows the rejected ring + scanner mix.
- Playtest boot: no server / client warnings or errors; 48 ring segments on six full-detail pods, no scanner parts.
  A live scanning egg was not placed (no profile writes).

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
