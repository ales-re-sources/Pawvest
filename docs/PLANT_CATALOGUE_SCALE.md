# Crop catalogue scaling assessment

Analysis, 2026-11-16; code at `4095d3f`. Recommendations below are proposals, not an approved milestone or implementation.

## Verdict and scope

The existing simulation and client-drawn plot architecture are a sound base for 100–500 crop types. The game is not ready to
reach that size simply by appending recipes. The first necessary changes are the public crop encoding, catalogue UI and a
shared content-validation workflow. Recipe loading, lifecycle diversity and economy modelling also need deliberate treatment.

This assumes the field remains bounded at 36 squares per player. Catalogue size, concurrent planted instances, plant geometry
complexity and player count are separate scaling dimensions. Increasing all four would require a broader performance review.
This assessment does not certify 100 or 500 types on a phone.

## Evidence checked

- Inspected the catalogue, plant registry and kit, field service, profile storage, public plot feed, plot renderer and scheduler,
  seed stall, barn, seed picker, localization and economy tools.
- Read-only Studio inspection confirmed the intended place `73033440513091`, in Edit mode, with 19 recipe ModuleScripts and
  208,740 bytes / 4,606 newline characters of recipe source. The disk recipe byte total matches. There are 19 catalogue entries;
  Sunflower is a draft, so 18 recipes are production-enabled. Ten recipe files use the shared `Kit.recipe` factory.
- Current crop letters are unique and one byte wide. A pure parser example demonstrated that a two-byte identifier changes
  `aa1a2` into cells `aa` and `1a`, rather than two crop/stage pairs.
- A Python serialization calculation used synthetic `Crop0000`-style IDs, four stock/record maps and 36 planted-square records:
  100 types = 7,371 JSON bytes; 500 types = 30,171 bytes. These are illustrative crop-section sizes, not measured player profiles
  or Roblox remote payload sizes. All four maps deliberately contained every type; present stock capacity makes some of those
  combinations unattainable through normal play.
- No gameplay code, scene content or saved profiles were changed. No playtest, phone benchmark or 500-type load test was run.

## What already scales well

**Server simulation follows planted squares.** [GardenField](../src/ServerScriptService/GardenField.luau) resolves crops through
`CropConfig.ById`, settles stored growth at actions/join/leave and on a 60-second interval, and derives readiness from time.
It does not start a timer or simulation loop for every catalogue type. Twelve full fields contain at most 432 plantings; 24
contain 864, whether the catalogue offers 19 or 500 types. Offline tending can also perform bounded harvest/replant work;
its cost depends on available stock, capacity and crop duration.

**Persistence is compact and uses stable IDs.** A planting stores crop ID, accumulated growth and planting identity, not its
geometry. Seeds, harvested counts, summed sizes and best records are maps. Additional definitions do not preallocate 500
plants in every save. Keep shipped IDs permanently resolvable: `fieldOf` / `cleanStock` currently discard unknown IDs, including
plantings and records. Retiring a crop must retain a definition or use an explicit conversion, rather than deleting its entry.

**Rendering already has the right separation.** [GardenView](../src/StarterPlayer/StarterPlayerScripts/GardenView.luau) selects
full/mid/low/none detail at 60/120/300 studs, with hysteresis and a shared nominal 6 ms build/pose budget. The own plot gets
priority. [PlotView](../src/StarterPlayer/StarterPlayerScripts/PlotView.luau) preserves plant identity, spreads updates between
squares and stops posing ripe plants. Mid detail uses direct-built proxies; low detail removes crop art.

**A shared recipe contract exists.** [PlantKit](../src/ReplicatedStorage/PlantKit.luau) provides deterministic variation, cached
Part writes, geometry construction and proxies. [PlantGrowth](../src/ReplicatedStorage/PlantGrowth.luau) discovers recipes by
crop ID. Localization already resolves crop-name keys by ID. These are useful foundations to extend.

## Constraints and changes

| Area | Current behaviour | Implication and proposed change |
|---|---|---|
| Public plot format | `GardenField.PlotField` sends two bytes per square: one crop letter and one stage. GardenView and PlotView slice fixed byte offsets. | A hard limit below 500 unique crop codes; multibyte Unicode or `aa` breaks decoding. Replace with an explicit schema using crop IDs, or stable numeric codes with an appropriate codec. Keep stored crop IDs unchanged. |
| Catalogue UI | SeedStall clears and recreates every crop row on render, including locked crops. State and pet/coin changes trigger renders while open. Both buy and sell sections render even when one is hidden. | At 500 unlocked common crops, the buy list alone creates 1,000 purchase buttons plus labels/layout/stud decoration. Add search, useful grouping and sorting; paginate or recycle visible rows; update stock/prices in place. Barn and seed picker already filter to owned stock, but need the same navigation approach as holdings expand. |
| Recipe initialization | PlantGrowth immediately requires every available recipe, including drafts before checking `Draft`. One require failure can prevent registry initialization. | Use cheap availability metadata and cached on-demand recipe resolution, warming recipes needed for nearby plots. Validate all recipes before release and contain a failed visual recipe with a controlled fallback and diagnostics. Lazy require reduces initialization work, not replication of modules in ReplicatedStorage. |
| Content ownership | Economics, crop names, fallback colors, special seed sources and model mapping live in several places. Ten recipes use the shared factory; nine have older implementations. | Keep one authoritative crop definition with display metadata, source/category and lifecycle references, linked to art. Generate or derive secondary indexes and tool inputs. Do not rewrite all unique geometry into an overly general template. |
| Content verification | Golden-master checking is shared; many geometry/integration scripts are copied per crop. Registry construction silently overwrites duplicate IDs/codes. | Add one catalogue validator and reusable parameterized geometry/lifecycle checks; keep crop-specific bounds and exceptional checks as data/hooks. Check uniqueness, localization, valid economics, recipe interfaces, draft status, full/proxy budgets and deterministic backward seeks. |
| Lifecycle diversity | One `Grown` clock; Harvest removes `Field.Squares[square]`. Visual fruit slots do not implement persistent gameplay. | Hundreds of annual crops fit this model. Trees, regrowing berries and independently ripe fruit need reusable lifecycle behaviours with separate structure and fruit state, server authority and persistence. Add those behaviours when required, without per-species branches in GardenField. |
| Profile/publication work | `fieldOf` repeatedly cleans and reallocates stock/record tables. Owner state sends complete maps after publishes. PlotFeed JSON-compares state and broadcasts changes to all clients. | Not a 500-definition hard blocker, but work grows with actual holdings/records, and public broadcasts grow with player count. Measure normalization and payload costs; move full cleanup to load/migration and use targeted validation if warranted. Consider state revisions/deltas or interest filtering when measured traffic requires them. |
| Economy/content progression | Current catalogue is a 16-common-crop ladder plus three world rares. The EV model has its own fixed ladder, gates and ID mapping. `config_match` iterates model crops, without rejecting extra configured crops. | A new config entry can escape model coverage. Add coverage equality and authoritative model inputs. Choose how families, seasons and alternatives share progression; extending the same vertical ladder to hundreds of steps is not a sustainable content plan. |

The codec change concerns runtime messages, not a required profile migration. Update all consumers, reviewer/fixture builders
and [PROTOCOL](PROTOCOL.md) together. A simple explicit per-square table is a reasonable first design for only 36 squares;
measure it before deciding a binary format is necessary. Numeric codes, if chosen, must be assigned permanently, never inferred
from catalogue order.

## Rendering risk is complexity, not species count

Current production recipes range from 54 Parts (Garlic) to 169 (Sweet Potato): a homogeneous 36-square field would contain
1,944–6,084 plant Parts, before soil, pets, UI, meshes or effects. The 192-Part Sunflower (registered in CG20c, 2026-11-18,
after this review) raises the top to 6,912 Parts plus 5,076 sphere meshes. A new, complex recipe
can exceed the frame budget even with a small catalogue. `PlotView:Step` checks its deadline between pieces, and posing checks
between plants; construction or posing of one expensive plant is not preempted at 6 ms.

The existing [Golden Carrot desktop sample](plants/GOLDEN_CARROT.md#field-integration-and-desktop-samples) exercised 24 distance-tiered
plots (3 full, 4 mid, 17 low). It is evidence for that recipe, route and desktop, not all recipes or phones. Many crop performance,
phone and second-client checks remain open in [ROADMAP](ROADMAP.md).

Adopt per-recipe and whole-scene budgets for Parts, proxy geometry, effects, construction and posing; benchmark mixed fields
and simultaneous transitions as well as homogeneous fields. Optimize the measured bottleneck. Current small stud Parts may
remain suitable for some crops; a selective mesh/hybrid approach should be evaluated for expensive forms, rather than mandated
for every crop.

Measured recipe source averages about 11 kB/type. Straight-line projections are 1.10 MB for 100 and 5.49 MB for 500 at today's
average, approximately 24,242 / 121,211 source lines. These are source-maintenance estimates, not compressed downloads, compiled
memory or load-time predictions. On-demand execution does not make all those replicated modules disappear from the client.
Roblox documents [ModuleScript execution/caching](https://create.roblox.com/docs/reference/engine/classes/ModuleScript) and
[ReplicatedStorage](https://create.roblox.com/docs/reference/engine/classes/ReplicatedStorage) separately.

The place currently has StreamingEnabled off. Enabling it alone is not a replacement for GardenView's own detail management:
Roblox's [streaming documentation](https://create.roblox.com/docs/workspace/streaming) exempts client-created instances from
streaming out unless they are parented under a server-created instance.

## Suggested order and acceptance evidence

1. **Before expanding into dozens more crops:** replace the letter codec; add catalogue validation and model coverage checking;
   centralize secondary metadata; make the shop browse a bounded page/window of rows. A 500-entry fixture must round-trip
   arbitrary IDs, highest codes, mixed occupied/empty/locked squares, corrections and detail changes without touching live saves.
2. **Before committing to 100 types:** add a reusable crop-check runner; profile registry initialization and use cached on-demand
   recipe resolution if its cost is material. Measure cold join,
   first plot appearance, shop open/update, serialized owner/public state, cleanup and memory against today's catalogue using
   identical visible plants. Separately exercise the most expensive real recipes, effects and frequent-growth cases.
3. **Before introducing new lifecycle families:** define annual and perennial contracts, saved-state transitions and harvest
   semantics. Existing deterministic art and fruit-slot work should support this, but do not already implement it.
4. **Before claiming 500-type readiness:** run 500-definition fixtures plus real complex mixed fields on the target phone and
   desktop, at actual and intended server populations (the current config describes 12 players; 24 is a separate expansion
   scenario). Exercise UI search/sort and buy/plant/harvest/sell/feed through real controls, Czech layouts, second-client views,
   distance transitions and cleanup. Agree device-specific frame/load/memory targets before measuring; record p95 and spikes,
   not just averages.

For economy design, the current 1.2x net-rate increase per common-crop step illustrates why definitions cannot all be successive
upgrades: extending that rule would make the last crop's rate about 69 million times the first at 100 steps, and 3.25e39 times
at 500. Those are mathematical extrapolations, not proposed prices. Catalogue breadth should be designed separately from the
length of the main progression ladder. The pending EV3 proposal remains unimplemented and should not be treated as current
runtime architecture.
