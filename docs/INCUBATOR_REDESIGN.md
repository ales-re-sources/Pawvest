# Incubator redesign

## Rear scanner B (2026-11-17, implemented and desktop Studio-validated)

Selected B from three disposable Studio mockups (A egg-hugging contour ring, B rear scanner, D rising square ripples).
Full detail only: replaces the vertical scan square, travelling highlight and trail. A bright emitter bar is embedded in the
rear heater case's front face (lit only while scanning); a see-through cyan Neon sheet (transparency 0.72) runs from it to a
bright scan line just above the nest, which sweeps z 1.5 → −1.8 → 1.5 with a cosine ease every 3 s, starting at the back.
The four thin bands stay for the amber growing pulse only. Mid keeps its static strip; low unchanged. Timing, labels,
states and the PlotView API unchanged. Full / mid / low body Parts 28 → 25 / 8 / 3.
Acceptance: sheet ends stay on the emitter and the scan line, line stays on the nest plane and in range, sheet keeps the pod's
right axis at yaw 0 / 90 / 180; scanner hidden and emitter dark in empty / growing / ready, restored on a new scan; coplanar
audit clean; boot logs clean.

Validation (desktop Studio, 2026-11-17):
- Counts full / mid / low 25 / 8 / 3. 300 poses per yaw 0 / 90 / 180: sheet top end ≤ 0.00003 from the emitter face, bottom end
  ≤ 0.00003 from the line; line Y error ≤ 0.00001, z range −1.800 … 1.500 (1.5 at age 0, −1.8 at 1.5 s); sheet length 2.33–4.32.
- States on one model: empty → scanning (emitter Neon, sheet 0.72, line 0, bands hidden, cyan glow) → growing (scanner hidden,
  emitter dark, heater on, amber bands) → ready (all off) → scanning (restored) → empty. Mid strip 0.25 scanning / 0.55 growing.
- Static coplanar audit (tools/kit_coplanar_audit.luau static rule, CanQuery enabled on the disposable pods): 9 full pods at
  three yaws × back / mid / front poses, 189 visible parts, clean.
- Visual capture: [rear scanner, growing pod for contrast](art/incubator-review/rear-scanner.jpg).
- Playtest boot: no server / client warnings or errors; 6 full-detail pods built the new parts, no old tracer parts; growing pod
  showed heater on / scanner off. A live scanning egg was not placed (no profile writes); the scanning path was checked on Edit fixtures.

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
