# Incubator redesign

## Follow-up scope (2026-11-17, implemented and desktop Studio-validated)

Keep the purchase-time pet roll server-side until Hatch: nest rows and private State must expose no kind or rarity.
Use shared timers for new eggs: Common / Uncommon 5 m, Rare 1 h, Epic / Legendary 4 h. Keep existing deadlines.
Replace the timed two-tap Cancel with a selected-egg confirmation page: warning about no refund, Keep hatching, Discard egg.
Closing the panel, keeping the egg, or the egg becoming ready / being replaced dismisses the confirmation without a discard.
Acceptance: exercise both confirmation choices, closing/reopening, readiness and stale-egg invalidation through the real UI;
verify only timing is exposed before hatch, the reveal still works, Czech labels fit, and run economy/localization checks.
Record forecast target regressions without changing the accepted timers or weakening checks.

Validation (desktop Studio, 2026-11-17):
- Real UI: Cancel opens one selected-egg warning; no remote sent. Keep hatching and close/reopen keep the egg and clear the warning.
  Explicit Discard removed only the selected egg; Coins stayed 25 000. No standing No refund text on nest buttons.
- State has id / egg / startedAt / readyAt only; no pet kind / rarity or rarity-colored nest text. Backend keeps the chosen Kind.
  Real Buy produced a 3 600 s egg; stored kind matches its configured tier. All five configured durations match the chosen shared tiers.
- Hatch granted the fixed Dragon and showed its kind, rarity and traits in the existing reveal.
- Client-only State fixtures (no profile writes) exercised countdown expiry while confirming and replacement by another egg id;
  both dismiss the warning without a cancel request. Real clicks opened the warnings.
- English and Czech confirmation text / button Glyphs fit. Czech odds show the shared durations; no content labels were cut off.
- Server and client boot/action logs: no errors or warnings. Localization build/check/lint: 0 errors / 0 literals.
- Economy: approved timer values pinned; config checks 15/15. EV forecast 16/18: G7 longest first-hour news gap 15.9 m (target <= 10),
  G9 Casual talent-first top crop day 13.3 (target >= 14); Legendary expected-count timing remains in band. These are forecast results,
  not failed game actions. No other economy values or check thresholds changed. The forecast starter still uses a timed common/uncommon
  egg, whereas the game gives an instant first pet; this model approximation was left outside the UI/timing fix.
- Fresh original baseline: TestSnapshots/profile_9892673032_incubator_followup_20261117_1 (taken just before fixture write).
  Exact profile / MostStars restoration verified after shutdown (`[IncubatorFollowup] RESTORE VERIFIED profile=true MostStars=true`);
  no stage runs or test Top-10 entries created.
- Physical phone touch and live validation remain open.

2026-11-17: egg kind is fixed at purchase / free placement and hidden server-side until Hatch. New eggs use shared tiers:
Common / Uncommon 5 m, Rare 1 h, Epic / Legendary 4 h. Nest rows show only the egg and countdown. Cancel hatch opens a
selected-egg Keep hatching / Discard egg warning; discarding gives no refund. Existing deadlines and instant first pet are preserved.
Implemented and desktop Studio-validated; physical touch and live validation remain open. As built: [GDD §7.2](GDD.md#72-eggs).
Scope, acceptance checks, snapshot / restore details and validation log: `git show 79e61e3:docs/INCUBATOR_REDESIGN.md`.

2026-11-17: pods and eggs now face the central path towards the barn (90° turn, plot-local −X), Studio-validated in three
plot orientations and at all detail levels. Centres, footprints and label anchors are preserved.

Implemented and Studio-validated on desktop, 2026-11-16: Cross-lapped oval eggs + Tall pavilion + Quiet rows + Nearby labels + Open hatch pod bodies (selected by the user). As-built behavior is in [GDD §7.6](GDD.md#76-pet-garden-minigame-p2), script APIs in [LAYOUT](LAYOUT.md). Physical phone touch and live validation remain open.

![Path-facing open hatch pod viewed from the central path](art/incubator-review/open-pod-path-facing.jpg)

Earlier design options / acceptance checks: `git show d24f132:docs/INCUBATOR_REDESIGN.md`. The three body concepts and their disposable Studio builder are archived at `git show 44431fe:docs/INCUBATOR_REDESIGN.md` and `git show 44431fe:tools/incubator_body_review.luau`.
