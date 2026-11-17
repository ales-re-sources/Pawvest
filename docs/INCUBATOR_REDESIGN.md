# Incubator redesign

## Scan and warmth (2026-11-17, implemented and desktop Studio-validated)

Scope: first 30 s of the existing hatch duration is scanning (cyan moving band + Scanning… above the egg and in the menu,
no countdown). Then show remaining time with a gentle amber nest glow / pulse. Ready stays green and stops the effects.
Use stored StartedAt / ReadyAt, never restart on reconnect; ready takes priority (instant first pet unchanged). Existing
eggs older than the scan window enter hatching. Public Plot adds StartedAt; no profile, reward or deadline changes.
Full detail animates; mid uses a static phase strip, low stays simple. No particles or extra Highlights.
Acceptance: scan motion / label → warmth / countdown → ready; reconnect / old payload / instant-ready behavior; full / mid / low,
all plot orientations; cancel and new egg reset; no pet-kind leakage, interaction targets unchanged; Czech fit and boot / localization checks.

Validation (desktop Studio, 2026-11-17):
- Public live Plot includes the existing StartedAt anchor as the third field; no kind / rarity added. Config helper boundary checks:
  scanning before 30 s, growing at 30 s, ready overrides scanning for instant eggs, old two-field payload skips scanning.
- Client-only fixtures: cyan band moved over 0.6 s; owner world label and menu both showed Skenování… with no countdown.
  Scan → growing changed color / text on the same model, without rebuilding; old public payload warmed immediately.
  Ready set green, heater Plastic, glow off; badge updated. New egg after removal restarted cyan scanning; empty pod effects cleared.
- Warm ring and light pulse in phase (brightness + transparency = 1.15); final playtest measured 1.14999998 on a real growing egg.
- Edit body checks at yaw 0 / 90 / 180: 21 / 7 / 3 BaseParts at full / mid / low; full scan band local Y=3.575 at age 1,
  ready light off for every detail. Cyan scan, amber warmth and green ready visually reviewed side by side with two captures.
  Disposable preview removed, original Edit camera restored / Fixed; Studio window checked restored before captures.
- No new particles, Highlights, collision or query surfaces. Existing click target and Cancel remain present while scanning.
- Czech scan text fits; final server / client boot logs contain no warnings/errors. Localization build/check/lint: 0 errors / 0 literals.
  New Czech: Skenování…; updated purchase message: Vejce je v inkubátoru!.
- Only client state fixtures and disposable Edit models used: no live-profile fixture writes. Hatch deadlines, stored kinds and
  inventory unchanged by this feature; total hatch durations unchanged. Physical phone / live validation remain open.


2026-11-17 phases: 30 s cyan scanning sweep + Scanning… (inside the existing hatch timer), then a soft pulsing amber nest glow
and countdown; ready stays green with warming off. Stored anchors survive rejoin; instant-ready eggs skip the scan.

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
