# Incubator redesign

## Compact actions and odds (2026-11-17, implemented and desktop Studio-validated)

Scope: use the game's ConfirmTap pattern with a tap-sized square trash icon, orange OK? on the first tap, discard only on
a second tap within three seconds. Timeout or panel close disarms; state redraws keep the selected egg's arming only.
Replace the inline odds prose with rows (rarity / right-aligned percentage / time). Retain only the two player-facing
sentences about offline hatching and no-refund discard; do not explain purchase rolls or shared time tiers in the tip.
Acceptance: real UI arming, timeout after redraw, close/reopen, second-tap request, other eggs unaffected; both egg odds
tables and Czech text fit. Boot logs and localization checks; no backend or economy changes.

Validation (desktop Studio, 2026-11-17):
- Real UI: trash is square, 44 px at this viewport; first click shows orange OK? on that egg only and sends no request.
  Redraw via Golden ? preserves OK?; after 3 s it returns to trash. Closing / reopening disarms without a request.
- Second click sent exactly one CancelEgg request. Client-only state fixtures used nonexistent egg ids, so the unchanged server
  rejected with empty and no profile mutation occurred. No live-profile fixture writes, purchases or stage runs were needed.
- Both Basic (5 rarity rows) and Golden (4 rows) fit in Czech; Basic rows were scrolled into view. Percentage right edges align,
  as do time right edges. English rows fit too. Tip contains only the two accepted sentences; no hidden-mechanics explanation.
- Server/client boot and action logs: no warnings or errors. Localization build/check/lint: 0 errors / 0 literals.
- Studio returned to Edit. Physical phone touch and live validation remain open.


2026-11-17: egg kind is fixed at purchase / free placement and hidden server-side until Hatch. New eggs use shared tiers:
Common / Uncommon 5 m, Rare 1 h, Epic / Legendary 4 h. Nest rows show only the egg and countdown. A small square trash button uses ConfirmTap:
orange OK? on first tap, discard on the second tap within 3 s; discarding gives no refund. Odds are separate rarity / percentage / time
rows, with only offline hatching and no-refund text in the tip. Existing deadlines and instant first pet are preserved.
Implemented and desktop Studio-validated; physical touch and live validation remain open. As built: [GDD §7.2](GDD.md#72-eggs).
Scope, acceptance checks, snapshot / restore details and follow-up validation: `git show e7aff11:docs/INCUBATOR_REDESIGN.md`.
Initial egg-timing validation: `git show 79e61e3:docs/INCUBATOR_REDESIGN.md`.

2026-11-17: pods and eggs now face the central path towards the barn (90° turn, plot-local −X), Studio-validated in three
plot orientations and at all detail levels. Centres, footprints and label anchors are preserved.

Implemented and Studio-validated on desktop, 2026-11-16: Cross-lapped oval eggs + Tall pavilion + Quiet rows + Nearby labels + Open hatch pod bodies (selected by the user). As-built behavior is in [GDD §7.6](GDD.md#76-pet-garden-minigame-p2), script APIs in [LAYOUT](LAYOUT.md). Physical phone touch and live validation remain open.

![Path-facing open hatch pod viewed from the central path](art/incubator-review/open-pod-path-facing.jpg)

Earlier design options / acceptance checks: `git show d24f132:docs/INCUBATOR_REDESIGN.md`. The three body concepts and their disposable Studio builder are archived at `git show 44431fe:docs/INCUBATOR_REDESIGN.md` and `git show 44431fe:tools/incubator_body_review.luau`.
