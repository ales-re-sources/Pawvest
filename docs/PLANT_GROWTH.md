# Plant growth art

This document owns the shared authoring workflow and Studio player. [EXPANSION §5.1](EXPANSION.md#51-plant-growth-art) holds
the high-level direction; [ROADMAP](ROADMAP.md) owns status and next steps. Read only the relevant crop page for its anatomy,
selected silhouette, growth poses and geometry budget.

| Crop | Design | Full-detail Parts |
|---|---|---|
| Tomato | [Spreading bush](plants/TOMATO.md) | 54 |
| Potato | [Upright compound foliage](plants/POTATO.md) | 65 |
| Frost Grape | [Tall vineyard trellis](plants/FROST_GRAPE.md) | 115 |
| Corn | [Tall two-ear stalk](plants/CORN.md) | 99 |
| Lettuce | [Crisp head](plants/LETTUCE.md) | 70 |
| Pepper / Paprika | [Upright bell-pepper bush — mature study](plants/PEPPER.md) | 88 (static study) |

## Studio growth player

Start a Studio playtest, then run in the **Client command bar**:

```luau
require(game.Players.LocalPlayer.PlayerScripts.PlantGrowthReview).Open("FrostGrape", 10)
```

Replace `"FrostGrape"` with `"Tomato"`, `"Potato"`, `"Corn"` or `"Lettuce"`. The optional seconds argument controls only review playback;
it does not change real crop timing or saved data. The reviewer can open an unregistered art recipe, so it is not proof of field
integration. Close the current reviewer before opening another crop.

**One plant** offers a growth scrubber; **Five poses** shows 0/20/50/75/100%; **Six seeds** is an internal variation check.
**Seed**, **Size** and **Rings** change the comparison. **Play/Pause** runs the continuous preview. **Close** removes its disposable
plot and restores the camera/HUD. These are Studio-only English controls. User review deliverables remain the five stills below.

## Review deliverable

**Ales's review preference, 2026-11-09: five snapshots only, at 0%, 20%, 50%, 75% and 100%.**
Use the same seed, harvested-size factor, field square and camera for all five. These are review poses of one continuously growing
plant, not five replacement models. Do not generate a 20-frame sequence, GIF or video unless explicitly requested. Older CG entries
and their GIF links are historical evidence, not requirements for another crop. Extra seed rows, size galleries and camera views
are optional deliverables only when requested; seed/size checks still belong in internal Studio validation.

Use the normal gameplay distance and a composition that remains readable at phone size. Show the crop against its real soil and
surroundings. Check the field pet, selection and progress ring together without making a separate gallery by default. A resized
desktop screenshot checks composition, not phone rendering performance. Studio review controls can remain English.

## Decide the plant before animating it

- Use the supplied references to choose the stem habit, leaf shape, fruit position and support needs. Potato needed upright,
  layered foliage; a flat rosette lost its identity. Preserve the cues that distinguish the crop at gameplay distance.
- Agree the mature silhouette first. Static alternatives can resolve an undecided shape before animation work. Define height
  relative to the actual avatar on the same ground plane; a close-up alone hides scale mistakes. Frost Grape's living canopy,
  not just its posts, must exceed the player.
- State what harvest removes: the whole annual plant, or fruit from a persistent plant. Real-world biology does not automatically
  change existing gameplay. The current Frost Grape pilot still uses the existing square-clearing harvest contract.
- Keep the current 5.5-stud square and its clearances. Existing recipes target a maximum 2.4-stud ground radius throughout growth,
  including rotated poses and supported size extremes. Record any deliberate exception before implementation.
- Choose intentional readability shortcuts. Potato's brown tuber shoulders show the harvest underground; its green berries are
  decoration. Grapes hang below the leaves. Shape, size and placement should communicate ripeness alongside color.

## Build one deterministic plant

Use a crop recipe through the shared `PlantGrowth` system, not a crop-specific scheduler or review UI. Build on
[`PlantKit`](../src/ReplicatedStorage/PlantKit.luau): its timing, seed and size helpers and its `Rig` (cached Part writes) belong
there, not copied into a recipe. A pose writes Parts in the order they were added. Keep a recipe's `vary` draws in their order: a new
draw goes last, otherwise every existing planting changes shape. Build a bounded set of Parts once and pose them continuously. Leaves unfold at their bases; children follow the current parent as it extends. Growth should
extend successive stems and organs with overlapping timings rather than uniformly inflate the entire model. A 43→44→43% seek
must restore the same visible pose without floating leaves, detached fruit or a changed random roll.

Derive appearance from the existing owner/planting identity. Seed 1 is the reproducible authored baseline. Variation must be visible
at first glance: use unequal shoots, leaf angles, lean and bunch proportions rather than barely perceptible jitter. Rejoin, time
corrections and detail changes must preserve identity. Free-standing bushes can rotate through a full circle; trained vines retain
row alignment. `FixedOrientation` is a recipe option, not a rule that every crop rotates randomly.

Reflect the server's actual harvested mass factor, including its current Sorter bonus. Cube-root dimensional scaling makes produce
larger without treating tripled mass as tripled height. Constrain canopy width and crop-specific height requirements. Rigid poles
and rails stay full-sized from planting and do not scale with mass. Frost Grape keeps its tall canopy while its grapes change size.
`FixedRingHeight` and `ReviewHeight` handle the corresponding ring and review framing.

## Recipe interface

The shared [PlantGrowth registry](../src/ReplicatedStorage/PlantGrowth.luau) dispatches registered crops. Each art recipe builds
local anchored, non-colliding geometry and exposes:

| Entry | Contract |
|---|---|
| `new(parent, soilCFrame, seed, sizeFactor?)` | Build once; return an instance with `model`. |
| `plant:SetGrowth(0..1)` / `Destroy()` | Pose reversibly / dispose of the instance. |
| `BuildProxy(parent, soilCFrame, stage, seed?, sizeFactor?)` | Production mid-detail silhouette; required before field integration. |
| `RingHeight` | Nominal ring offset; mass-scaled unless `FixedRingHeight` is true. |
| `FixedOrientation`, `FixedRingHeight`, `ReviewHeight` | Optional row-alignment, ring and Studio-framing rules. |
| `plant.fruitSlots` | Explicit fruit IDs, attachments and Part groups where authored; see below. |

The public plot feed supplies planting identity, harvested-size factor and server-time anchors; its schema belongs in
[PROTOCOL](PROTOCOL.md). Ordinary time updates preserve existing plant, soil and pet instances. Mid proxies retain the selected
silhouette and harvest cues; low detail removes crop art. Do not construct a full plant just to derive its cheaper proxy.

## Identify fruit before future perennial gameplay

For new fruit-bearing recipes, assign stable fruit-slot IDs, explicit Part groups and seeded attachment points. Keep support,
structure/foliage and collectible fruit distinguishable in code; do not depend on Part-array offsets or remembered geometry.
Frost Grape is the reference: each instance exposes `fruitSlots[1..3]`, with `id`, mature world-space `attachment` and `parts`.
Its local Parts carry `PlantRole` and, for fruit, `FruitSlot`. The bunch group includes berries, frost facets and its stalk.

Future perennials need separate structure maturity and per-slot fruit growth/readiness. Collecting fruit should retain the seeded
trunk/vine, leaves and support, then regrow fruit at the same slots. Do not reset the whole plant with `SetGrowth(0)` or reroll its
structure at each harvest. Explicit visual slots do not decide reward quantity or whether collection happens per bunch or all at
once. Organ metadata alone does not implement collection, regrowth, persistence or server harvest authority.

## Validate without making review expensive

Check intermediate attachment/hinge poses and backward seeks in Studio without capturing every frame. Check representative seeds,
minimum/standard/maximum mass, mature height, all-age footprint and the selected ripe baseline. Report model Part count and the
36-square plant-only total; include soil, pets and UI when measuring the complete field. Keep art approval distinct from production
integration and performance validation.

Continuous growth does not require production updates every rendered frame. Reuse cached poses/properties, skip invisible work,
freeze completed groups and stop posing ripe plants. Spread square updates within the shared frame budget. Current cadence is 1/480 of the
effective growth duration, clamped to 0.2–30 seconds: ten-second Potato uses 5 Hz, thirty-minute Corn updates every 3.75 s, crops of
4 h or more every 30 s. State corrections and the exact ripe moment do not wait for a sample.
The Studio scrubber can pose immediately. Short preview playback must not change a live crop's growth duration. Measure the full field and the 24-plot scenario on the same route before
claiming an improvement; real-phone performance remains a separate check. Simplify distant foliage while preserving harvest cues.

## Keep saved-data edits separate from art tooling

Before acting on an existing planting, establish whether the request changes its saved state or asks for an art preview. Inspect
the actual saved fields and the code that consumes them. A request for a one-off DataStore change is not permission to add a preview
LocalScript, Workspace overrides or renderer features as a workaround. If the requested change is supported, snapshot the current
live profile immediately before the minimal authorized write, following AGENTS.md. Never rename a stored crop ID to select art.

Currently `Crop`, `Grown` and `N` identify the planted crop and progress; the renderer chooses recipes from code. There is no stored
per-plant art-version selector. Changing age or other unrelated data cannot enable an unregistered recipe. Explain a missing
consumer before proposing code changes; do not invent an ineffective profile field. Keep display-only prototypes, registered art
and future perennial behavior clearly distinguished in status reports.

## Historical evidence

Alternative-study details, acceptance counts and desktop CPU logs from CG1–CG6 are archived in git:
`git show d73a9aa:docs/EXPANSION.md`. Keep durable design decisions in the crop pages and current open checks in ROADMAP;
do not copy those validation narratives back into EXPANSION or this guide.
