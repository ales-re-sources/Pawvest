# Incubator redesign

## Warm and cozy hatching (2026-11-17, implemented and desktop Studio-validated)

The user chose to combine three of five options (A rising sparks, C brick hearts, D heat lamp; B steam and E egg wiggle not
built). Full detail, growing state only; scanning / ready / empty unchanged and every new effect off outside growing.
- D: the rear heater strip flickers between WARM and a deeper ember orange (slow noise per pod, desynced by the pod number);
  a SpotLight on its front face (Angle 80, Range 7) lights the egg, brightness following the embers.
- A: a ParticleEmitter on an attachment just above the egg top (built-in sparkles texture, amber → peach, rate 3, 2–3 s life,
  slow rise with 35° spread, size peak 0.4).
- C: two pink Neon hearts (5 × 4 studs of 0.11: "XX XX / XXXXX / XXX / X", 5 touching Parts each) rise 1.6 studs over 4 s,
  half a life apart, with a small sway and roll, fading in / out; start position per cycle from a stable hash, in the front
  half of the pod so they stay clear of the number plate.
Full body Parts 34 → 44; mid / low unchanged. First 3-row heart read as a cup and drifted over the number plate (reworked).
Acceptance: no heart intersection with egg / body at three yaws; hearts above the egg top; coplanar audit clean; effects
only while growing; boot clean; the real growing pod animates.

Validation (desktop Studio, 2026-11-17):
- Counts full / mid / low 44 / 8 / 3. 1 200 poses at yaw 0 / 90 / 180 (Golden egg): no heart intersection; heart bottoms
  ≥ 5.03 (egg top 5.00), z −0.59 … −0.02; spark attachment exactly 0.05 above the egg top at every yaw; heater green
  channel 128–173 (between EMBER 118 and WARM 183).
- States: scanning / ready / empty → no hearts, sparks / lamp off, heater Plastic; growing → 10 heart parts, sparks / lamp on,
  heater Neon; switching back and forth restores both.
- Static coplanar audit (CanQuery on disposable pods, min area 0.002 for the small studs): 12 pods, 708 parts, clean.
- [Capture](art/incubator-review/warm-hearts.jpg) (hearts, ember heater). Edit captures do not render particles (a large red
  probe emitter was invisible too) and Studio screen access was declined, so the sparks' look is not visually checked.
- Playtest: no server / client warnings or errors; the developer's real growing pod (Slot_01 inc1) had sparks and heat lamp
  on, hearts moving; empty pods had all effects off.

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
