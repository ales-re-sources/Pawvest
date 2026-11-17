# Incubator redesign

## Egg timing and cancellation (2026-11-17, implemented and desktop Studio-validated)

Scope: choose and store the pet kind when a paid egg is bought, or when a waiting free egg enters a nest. Show the pet,
rarity and remaining time in the hatchery. Use EV2e's Common 2 m / Uncommon 10 m / Rare 1 h / Epic 4 h / Legendary 12 h.
The first free pet stays instant; traits still roll at hatch. Existing eggs get a fixed kind once and keep their deadlines.
Cancel discards the egg without a refund, confirmed with two taps; a waiting free egg may fill the freed nest immediately.
Tips explain the roll, rarity times and cancellation before purchase.

Acceptance: purchase stores one kind and its rarity timer; publish / rejoin never rerolls it; hatch grants that kind;
old eggs retain their times; free eggs and instant onboarding work; cancel spends/refunds nothing and stale requests cannot
discard a replacement egg. Exercise Buy, ?, Cancel, confirmation and Hatch through the real UI, including Czech text fit.
Run localization and economy checks, then boot with no new server/client errors. Snapshot/restore any live-profile fixture.

Validation (desktop Studio, 2026-11-17):
- Read both live profiles first: both held legacy eggs. Developer fixture snapshotted before each write. Original test baseline:
  `TestSnapshots/profile_9892673032_EV2e_1794930000_2`; `_3` is a nested free-egg fixture baseline (test state only).
- Legacy Basic / Golden deadlines preserved; kinds and GUIDs remained unchanged through publish and a playtest restart.
- Real UI: Basic Buy → Dragon / Epic / 14 400 s; Golden two-tap Buy → Bunny / Uncommon / 600 s; both ? controls show rarity
  times and rules; growing Cancel first tap asks to discard, second discards. Balance stayed 24 880 after cancelling a 120-Coin egg.
- Hatch granted the exact stored Owl, with the existing trait reveal. Fresh free-egg fixture: first Owl ready instantly, later
  Common eggs 120 s; one queued free egg replaced a cancelled egg immediately; replay of old GUID rejected as stale.
- English and Czech nest/action labels fit; Czech odds, rule tip and time ranges fit (`TextFits`, including inner Glyphs).
- Server/client boot and action logs: no errors or warnings. Localization build/check/lint: 0 errors / 0 literals.
  Economy values reviewed and pinned: 15/15 checks, EV 18/18; proposal command prints matching rarity timers.
- Original profile / MostStars restored and verified by exact readback after shutdown (`[EV2e] RESTORE VERIFIED profile=true MostStars=true`). No stage runs, so no test entries were created in Top-10 boards.
- Physical phone touch and live validation remain open.


2026-11-17: pods and eggs now face the central path towards the barn (90° turn, plot-local −X), Studio-validated in three
plot orientations and at all detail levels. Centres, footprints and label anchors are preserved.

Implemented and Studio-validated on desktop, 2026-11-16: Cross-lapped oval eggs + Tall pavilion + Quiet rows + Nearby labels + Open hatch pod bodies (selected by the user). As-built behavior is in [GDD §7.6](GDD.md#76-pet-garden-minigame-p2), script APIs in [LAYOUT](LAYOUT.md). Physical phone touch and live validation remain open.

![Path-facing open hatch pod viewed from the central path](art/incubator-review/open-pod-path-facing.jpg)

Earlier design options / acceptance checks: `git show d24f132:docs/INCUBATOR_REDESIGN.md`. The three body concepts and their disposable Studio builder are archived at `git show 44431fe:docs/INCUBATOR_REDESIGN.md` and `git show 44431fe:tools/incubator_body_review.luau`.
