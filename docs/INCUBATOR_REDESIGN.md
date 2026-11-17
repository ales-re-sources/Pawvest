# Incubator redesign

## Hatchery access (2026-11-17, implemented and desktop Studio-validated)

Scope: replace the hatchery E prompt with a Hatchery HUD button beside Barn while within 45 studs of the own plot,
plus click/tap on any own incubator (occupied, empty or locked). Both open the existing panel; neither hatches an egg.
The HUD counts ready eggs. World pods have generous non-colliding click targets and a whole-pod hover outline.
Keep the barn's existing availability (including crops held away from the plot); center the visible farm buttons together.
Acceptance: HUD from field and plaza; all three pods from both sides; empty/locked pods; hover; no hatchery prompt;
HUD layout / ready badge / Czech fit; GUI blocks world activation; no clicks on other plots or opening outside own-plot range.
Check boot logs, localization, and leave Studio in Edit. Physical touch validation remains separate.

Validation (desktop Studio, 2026-11-17):
- Real HUD clicks from the field opened Hatchery and Barn; both hide while a panel is open. Czech and English labels fit.
  The row is 256 px wide; with only Barn visible its center offset is zero. Existing away-from-plot Barn policy is unchanged.
- Real world clicks opened all three own pods from both field and plaza approaches. Public-state-only fixtures confirmed
  empty and locked pods remain clickable; a synthetic other plot had zero ClickDetectors. No hatchery ProximityPrompt remains.
- Whole-pod hover enabled on the generous target and cleared under UI / on opening. Native ClickDetector hover was replaced
  with a ray over the same target. Camera control was held only for reproducible clicks and restored before stopping.
- Passive Active=false / InputSink.All overlay blocked pod opening; after removing it the same click opened the menu.
  PointerPosition reconciles mouse GUI inset and retains inset-adjusted touch InputObject.Position for the common guard.
- Outside the own plot's 45-stud range, HUD is hidden and native clicks do not open. Ready badge showed 2 for two ready eggs,
  hid at 0, and changed to 1 as a future timer expired without another state message.
- Server/client final boot and action logs: no warnings/errors. Localization build/check/lint: 0 errors / 0 literals.
  New Czech: 🥚 Líheň (hatchery.button). No economy, profile or remote changes; client-only state / GUI fixtures, no live fixture writes.
- Studio left in Edit. Physical phone touch and live validation remain open.


2026-11-17 access: Hatchery HUD beside Barn (ready-egg badge) near the own plot, or click/tap any own incubator from either side.
Whole-pod hover; no hatchery E prompt. Barn keeps its existing availability; visible farm buttons center together.

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
