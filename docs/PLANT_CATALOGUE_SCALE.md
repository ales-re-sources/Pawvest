# Crop catalogue scaling (100-500 crops)

Analysis of what blocks growing the catalogue from 19 crops to 100-500 types. Proposals, not an approved milestone. Assumes the field
stays bounded (`CropConfig.MaxSquares`, 78 squares per player); catalogue size, planted instances, plant complexity and player count are
separate scaling dimensions, and nothing here certifies 100 or 500 types on a phone.

## What already scales
- **Server simulation follows planted squares, not types.** `GardenField` resolves crops through `CropConfig.ById`, settles growth at
  actions / join / leave and on a 60 s interval, and derives readiness from time: no timer per type.
- **Persistence is compact and keyed by stable ids**: a planting stores crop id, accumulated growth and planting identity (not geometry);
  seeds, harvested counts, summed sizes and records are maps. But `fieldOf` / `cleanStock` **discard unknown ids**, plantings and records
  included: a retired crop must keep a definition or get an explicit conversion, never be deleted.
- **Rendering** (`GardenView` full / mid / low / none at 60 / 120 / 300 studs, hysteresis, shared 6 ms build / pose budget, own plot
  first; `PlotView` keeps plant identity and stops posing ripe plants) and **recipes** (`PlantKit`, `PlantGrowth` discovering recipes by
  crop id, localization resolving crop-name keys by id) are the right base.

## Constraints and recommended changes
| Area | Constraint | Recommendation |
|---|---|---|
| **Public plot format** | `GardenField.PlotField` sends **two bytes per square: one crop letter + one stage** (`#0` locked, `.0` empty); `GardenView` / `PlotView` slice fixed byte offsets (`CropConfig.ByLetter`). A two-byte id breaks parsing (`aa1a2` decodes as cells `aa`, `1a`). | Hard limit far below 500 codes. Replace with an explicit schema (crop ids, or permanently assigned numeric codes, never inferred from catalogue order); a per-square table is fine for 78 squares, measure before going binary. Runtime message change only, no profile migration; update all consumers, reviewer / fixture builders and PROTOCOL together. Stored crop ids stay. |
| **Catalogue UI** | SeedStall clears and recreates every crop row on each render (locked crops too; buy and sell sections both render even when one is hidden): 500 crops = 1 000+ buttons. Barn and seed picker filter to owned stock but have no navigation at scale. | Search, grouping, sorting; paginate / recycle visible rows; update stock and prices in place. |
| **Recipe initialization** | `PlantGrowth` requires every available recipe up front, drafts included, before checking `Draft`; one require failure can break the registry. | Cheap availability metadata and cached on-demand resolution (warm for nearby plots); validate all recipes before release; controlled fallback and diagnostics for a failed recipe. Lazy require does not remove the replicated modules from the client. |
| **Content ownership** | Economics, names, fallback colours, special seed sources and model mapping live in several places; 11 of 20 recipe modules use `PlantKit.recipe`, the rest older implementations. | One authoritative crop definition (display metadata, category, lifecycle, art link) with derived indexes. Do not force all unique geometry into a general template. |
| **Content verification** | Golden-master check is shared; geometry / integration scripts are copied per crop; registry construction silently overwrites duplicate ids / letters. | One catalogue validator (uniqueness, localization, economics, recipe interface, draft status, full / proxy budgets, deterministic backward seeks) plus parameterized geometry / lifecycle checks; crop-specific bounds as data / hooks. |
| **Lifecycle** | One `Grown` clock per square; Harvest removes the planting. Fruit slots are visual only. | Hundreds of annual crops fit. Trees, regrowing berries and independently ripe fruit need reusable lifecycle behaviours (separate structure and fruit state, server authority, persistence), not per-species branches in `GardenField`. |
| **Profile / feed traffic** | `fieldOf` re-cleans and reallocates stock / record tables; owner state sends whole maps after publishes; `PlotFeed` JSON-compares and broadcasts to all clients. | Not a hard blocker; cost grows with holdings and player count. Move full cleanup to load / migration; consider state revisions / deltas or interest filtering once measured. |
| **Economy / progression** | The EV model has its own fixed crop ladder and ID mapping; `config_match` iterates model crops and does not reject extra configured crops, so a new config entry can escape coverage. A 1.2× net-rate step per crop would make crop 100 about 7e7× and crop 500 about 3e39× the first. | Add coverage equality and authoritative model inputs; design catalogue breadth (families, seasons, alternatives) separately from the length of the main ladder. |

## Rendering risk is complexity, not species count
Recipes run from 54 Parts (Garlic) to 192 + 141 meshes (Sunflower); one expensive recipe can exceed the frame budget with a small
catalogue (`PlotView:Step` checks its deadline between pieces and posing between plants, so one plant's build is not preempted at 6 ms).
Adopt per-recipe and whole-scene budgets (Parts, proxy geometry, effects, construction, posing), benchmark mixed fields and simultaneous
transitions, optimise the measured bottleneck; a selective mesh approach may suit expensive forms. Desktop CPU samples exist for single
recipes only ([Golden Carrot](plants/GOLDEN_CARROT.md#field-integration-and-desktop-samples)). Recipe source averages ~11 kB per type
(~1.1 MB at 100, 5.5 MB at 500, all replicated). `StreamingEnabled` is off and would exempt client-created instances anyway.

## Suggested order
1. **Before dozens more crops:** replace the letter codec; catalogue validation and economy-model coverage; central metadata; bounded
   shop rows. A 500-entry fixture must round-trip arbitrary ids, highest codes, mixed squares, corrections and detail changes.
2. **Before 100 types:** reusable crop-check runner; measure registry init, cold join, shop open / update, serialized state, memory.
3. **Before new lifecycle families:** define annual and perennial contracts, saved-state transitions, harvest semantics.
4. **Before claiming 500 types:** 500-definition fixtures plus real complex mixed fields on the target phone and desktop at real server
   populations (12 players; 24 is a separate scenario), real controls, Czech layouts, second-client views; agree device targets first.
