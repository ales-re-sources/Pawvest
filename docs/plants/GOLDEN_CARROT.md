# Golden Carrot growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../PLANT_GROWTH.md#crops-and-status)

Approved: one pointed golden root with two-thirds of its length buried, tall divided foliage, a gentle sheen and sparse ripe glints.

[Mature study](../art/golden-carrot/ripe-study-buried-root.jpg) · [`golden_carrot_ripe_study.luau`](../../tools/golden_carrot_ripe_study.luau) ·
[Five-pose sheet](../art/golden-carrot/growth-review.png) · [0%](../art/golden-carrot/growth-0.jpg) ·
[20%](../art/golden-carrot/growth-20.jpg) · [50%](../art/golden-carrot/growth-50.jpg) · [75%](../art/golden-carrot/growth-75.jpg) ·
[100%](../art/golden-carrot/growth-100.jpg)

## Mature silhouette

One elongated golden taproot with a feathery green crown. **Two-thirds of the root stays below ground**; only the upper third and
shoulders show. Keep the full root 1.5–2× taller than wide (fine point requested). One visual root represents the planting; harvest
quantity is unchanged.

Standard mass: **4.2 studs above ground** (about 0.7 exposed root + 3.5 foliage above the crown); full root ~2.1 studs long (1.4 below
soil); canopy ~3.5 studs wide. Judge against the avatar on the same soil plane; every age, rotation and size stays inside the 2.4-stud
radius.

The root has broad angular shoulders, a narrowing body, a slight seeded lean and two or three short offset amber creases. Seven unequal
fronds from one crown (upright central, arching outer), each with a narrow stalk and spaced pairs of pointed leaflets; keep gaps so it
reads as carrot foliage, not a solid bush or pineapple strap leaves.

Colour: honey-gold body, pale golden upper facets, amber creases; deep green stalks, fresh green leaflets, lighter tips. Root reflectance
rises to 0.08 over 75–100%; ripe shoulders emit an occasional tiny gold star glint (one emitter, 0.2/s ±0.035, lifetime 0.45–0.65 s,
only at 100%, cleared on backward seeks). Leaves stay matte. A successful owner harvest plays one brief gold-fleck burst (nine flecks,
0.9 s Debris, separate non-queryable local anchor) through `PlantGrowth.PlayHarvest` from `FieldHand`'s Harvest-result pop; failed
harvests and distance / detail changes do not play it.

The planted crop is intrinsically Golden Carrot; this art is not the future earned Golden variant (EXPANSION §5.3). Ripeness = fuller
exposed root, wider shoulders, opened crown and richer gold.

## Growth

| Growth | Pose |
|---|---|
| 0% | Two tiny narrow seed leaves just above the soil. Unplanted soil stays bare. |
| 20% | Seed leaves spread; first divided true leaf rises. Root concealed. |
| 50% | Three or four unequal fronds fan out; a small pale-gold shoulder shows at soil level. |
| 75% | Most fronds open (outer arch, central upright); root lengthens below ground, shoulder thickens, amber creases develop. |
| 100% | Honey-gold shoulders beneath the full crown; newest leaf finishes opening, foliage settles outward. |

Poses of one plant: fronds extend successively, leaflets unfold from their bases with overlapping timings; seed leaves stay small, tucked
under the crown. Root swelling follows foliage establishment (no uniform inflate, no popping out of the ground); frond bases follow the
root crown. Shoulder exposure is limited to the upper third, also on backward seeks. No hidden fine roots or flowering stalks.
Seeds vary frond length, openness, lean, leaflet spacing, shoulder proportions and rotation, always one root. Cube-root mass scaling
(root size emphasised, canopy limited). Grow time: `CropConfig`; harvest clears the plant.

## Recipe

[`GoldenCarrotPlant.luau`](../../src/ReplicatedStorage/GoldenCarrotPlant.luau), `PlantKit`: **72 Parts** (six root sections, three
creases, two seed leaves, twelve stalk sections, 42 paired leaflets, seven terminal leaflets); the first two fronds use one straight
spine, the other five two stalk sections (keeps the budget). 36-square field 2 592. `PlantRole` `Root` / `Foliage`, no fruit slots.
Ring 4.7 studs (mass-scaled), review framing 4.3. Seed 1: 4.16 studs, root 2.10 × 1.22 (1.73:1), 66.7% buried, lowest section 0.06 wide;
heights 3.49–5.30 and full-model radius max 2.08 over seeds / masses (0.35656 / 1 / 3.02985). Checks:
`golden_carrot_growth_checks.luau`, `golden_carrot_integration_checks.luau`.

## Field integration and desktop samples

Mid proxies **5 / 23 / 24 Parts** (young / growing / ripe) keep divided foliage and the exposed shoulder; low detail removes crop art.
Exact ripeness enables glints and stops posing; backward corrections clear them. Pose interval is the shared cadence (capped 30 s) with the ripe boundary scheduled
sooner. Desktop CPU samples done (24 plots: 3 full / 4 mid / 17 low; frame p95 ~18 ms, similar to the Onion baseline); phone and
second client open.

## Possible beet reuse

The exposed-root and basal-crown arrangement could serve a beet with different leaves; [earlier lower-crown image](../art/golden-carrot/ripe-study.jpg)
is the shape reference.
