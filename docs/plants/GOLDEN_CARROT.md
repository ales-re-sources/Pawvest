# Golden Carrot growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../ROADMAP.md)

Mature silhouette approved by Ales, 2026-11-09: one pointed golden root with two-thirds of its length buried, tall divided
foliage, a gentle sheen and sparse ripe glints. The continuous recipe and direct mid proxy are built and Studio-checked (CG10b).
Five growth stills await art review. The recipe is not registered for live fields; integration and harvest effects follow review.

[Mature study with two-thirds of the root buried](../art/golden-carrot/ripe-study-buried-root.jpg) ·
[Reproducible Studio client study](../../tools/golden_carrot_ripe_study.luau)

[Five-pose review sheet](../art/golden-carrot/growth-review.png) ·
[0%](../art/golden-carrot/growth-0.jpg) · [20%](../art/golden-carrot/growth-20.jpg) ·
[50%](../art/golden-carrot/growth-50.jpg) · [75%](../art/golden-carrot/growth-75.jpg) ·
[100%](../art/golden-carrot/growth-100.jpg)

Studio playtest Client command bar: `require(game.Players.LocalPlayer.PlayerScripts.PlantGrowthReview).Open("GoldenCarrot", 10)`.
The ten seconds are review playback only; the production crop remains six hours.

## Mature silhouette

One elongated golden taproot with a feathery green crown, growing directly from the soil. **Two-thirds of the full root length
stays below ground; only its upper third and shoulders show.** Ales liked the long-root shape, requested a finer point, and
corrected its planting depth. Keep the full root **1.5–2 times taller than its widest dimension**, even though only a short gold
shoulder is visible while planted. One visual root represents the planting, without changing harvest quantity.

At standard harvested mass, target a **4.2-stud above-ground height**, approximately **0.7 studs of exposed root** and **3.5 studs
of foliage above its crown**. The full root is approximately **2.1 studs long**, including **1.4 studs below soil**. Keep an
approximately **3.5-stud canopy width**. The taller foliage retains its stalk and leaflet dimensions while its base follows the
root's crown at the corrected planting depth. Judge the silhouette beside
the actual avatar on the same soil plane. Keep every age, rotation
and supported size inside the shared **2.4-stud ground radius** on the existing 5.5-stud square.

The root has broad angular shoulders, a narrowing body and a slight seeded lean. Two or three short, offset amber creases suggest
carrot skin without striping the whole surface. Seven unequal fronds grow from one crown: upright central fronds and arching
outer ones. Each has a narrow central stalk and spaced pairs of pointed leaflets. Keep gaps between fronds so it reads as carrot
foliage rather than a solid bush or a pineapple's strap-leaf crown.

## Color and surface

Use Pawvest's colored stud-block style: faceted Parts, restrained stud texture, warm gold root and ordinary green foliage.
Proposed palette: honey-gold body, pale golden upper facets, amber creases; deep green stalks, fresh green leaflets and a few
lighter tips. Make gold readable through broad color planes under ordinary field lighting. Avoid effects that obscure the root.

Accepted effect direction: the root's sheen strengthens over 75–100% growth; ripe shoulders produce an occasional tiny
star-shaped gold glint, staggered between plants. Leaves remain matte green. A brief gold-fleck harvest burst is intended for
the later field-integration pass. The first mature study previews only the sheen and sparse ripe glints.

The planted crop is intrinsically Golden Carrot. This art does not implement the future earned Golden variant described in
EXPANSION §5.3. Ripeness combines a fuller exposed root, wider shoulders and an opened crown, as well as richer gold color.

## Continuous growth

| Growth | Review pose |
|---|---|
| 0% | Two tiny narrow seed leaves just above the soil. The planted square has a visible sprout; unplanted soil stays bare. |
| 20% | Seed leaves spread; the first divided true leaf rises and begins unfolding. The root is still concealed. |
| 50% | Three or four unequal fronds fan out from the crown. A small pale-gold shoulder becomes visible at soil level. |
| 75% | Most fronds have opened; outer ones arch while central ones remain upright. The root lengthens below ground and its exposed golden shoulder thickens. Amber skin creases develop. |
| 100% | Honey-gold shoulders show above the soil beneath the full feathery crown. Two-thirds of the long pointed root stays buried; the newest leaf finishes opening and the foliage settles outward. |

These are poses of one plant. Fronds extend successively and their leaflets unfold from their bases, with overlapping timings.
Early seed leaves stay small and become tucked beneath the crown. Root swelling follows foliage establishment; the plant does
not uniformly inflate or pop out of the ground. Frond bases follow the root's crown continuously as it develops. Grow the long
taper down into the soil while limiting shoulder exposure to about the upper third, including backward seeks. Omit hidden fine
roots and flowering stalks from the standing crop.

Seeds vary frond length, openness, lean, leaflet spacing, root shoulder proportions and whole-plant rotation. Preserve one root
and the carrot silhouette for every seed. Harvest mass uses cube-root dimensional scaling, emphasizing root size while limiting
canopy spread. Harvest clears the whole plant under the current contract. Production growth remains **six hours**.

## Recipe and review boundaries

Keep about two-thirds of the mature root below soil; improve shoulder color/shape readability within that exposure limit.
The approved silhouette is implemented through `PlantKit` and the shared growth reviewer. Root growth develops beneath the
soil first; its upper shoulder becomes visible around the middle of growth. Seven fronds extend and unfold at overlapping
intervals. Seed leaves remain small beneath the mature crown. To retain the 72-Part budget, the first two fronds each use one
straight spine; the other five use two connected stalk sections. Their heights and mature crown shape remain consistent with
the approved study.

[`GoldenCarrotPlant.luau`](../../src/ReplicatedStorage/GoldenCarrotPlant.luau) creates **72 full-detail Parts**: six root sections,
three creases, two seed leaves, twelve stalk sections, 42 paired leaflets and seven terminal leaflets. A 36-square field would
use **2,592 plant Parts**, excluding soil, pets and UI. Direct-built mid proxies use **5 / 23 / 24 Parts** for young/growing/ripe
plants, retaining divided foliage and the exposed shoulder. This whole-root crop has `PlantRole` `Root` or `Foliage`, no fruit
slots. The nominal ring height is 4.7 studs, scaled with harvested mass. Review framing is 4.3 studs.

The five stills use seed 1, standard mass, the same camera and square, with the real soil and field pet. The review sheet simply
assembles those stills using the same crop rectangle. Field registration and performance checks follow art review; crop timing,
economy, harvest behavior and saved data have not changed.

## Mature dimensions and validation

The seed-1 standard-mass recipe is **4.16 studs above ground**, consistent with the approved 4.17-stud study beside a 5.40-stud
avatar on the same soil plane. The full edible root is **2.10 studs long by 1.22 studs at its widest**, a **1.73:1** ratio.
**1.40 studs (66.7%) are below ground and
0.70 studs (33.3%) show above it.** The lowest section narrows to 0.06 studs, giving the buried root a finer point. A 36-square
field would contain **2,592 plant Parts** before soil, pets, UI and effect instances.

Root reflectance rises to 0.08 over 75–100% growth; leaves retain the ordinary matte surface. One attachment and one native
particle emitter add sparse ripe glints: baseline rate 0.2/s (seeded variation ±0.035), lifetime 0.45–0.65 s. Glints enable only
at 100%; seeking backward disables and clears them. The texture loaded successfully in the Studio client. There is no separate
crop scheduler or per-frame particle loop. The harvest burst remains part of later field integration.

[`golden_carrot_growth_checks.luau`](../../tools/golden_carrot_growth_checks.luau) passed for six seeds, 101 ages and three harvested
mass factors: **0.35656 / 1 / 3.02985** (including the top Sorter). Maximum full-model/proxy radius stayed below 2.4 studs; the full
models reached **2.08 studs**. Mature heights ranged **3.49–5.30 studs**. Checks cover stalk/leaflet attachment, exact visible
backward seeks, initial-pose restoration, seed individuality, physics/query flags, ripe-only glints, and mature burial/aspect.
Real clicks exercised five poses, six seeds, seed and size changes, rings, play/pause, scrubber and Close in the shared reviewer.
The five stills were captured; client and server logs were clean, Close removed the reviewer, and the playtest was stopped.
No direct profile writes or field actions were performed. Art approval, field integration, performance, phone and multi-client
validation remain separate.

## Possible beet reuse

Ales noted that this exposed-root and basal-crown arrangement could also form a beet study, with different leaves. Retain the
[earlier lower-crown image](../art/golden-carrot/ripe-study.jpg) as a shape reference for that future design. Carrot keeps its
divided feathery foliage; beet leaf shape would be authored separately.
