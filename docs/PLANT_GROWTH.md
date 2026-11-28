# Plant growth art

Shared authoring workflow, Studio player and recipe contracts. [EXPANSION §5.1](EXPANSION.md#51-plant-growth-art) holds the direction;
[ROADMAP](ROADMAP.md) the order and next steps; the table below each crop's status. Read only the relevant crop page for its anatomy,
silhouette, growth poses and geometry budget.

## Crops and status
Every registered crop passed the Studio geometry checks (six seeds × three masses × 101 ages, radius, seeks, proxies) and the production
`PlotView` lifecycle. **Open** lists what is left: *perf* = full-field / 8-plot CPU (Parts per
full field of 36 in brackets); *phone* = a real phone; *2nd* = a second client. Live validation is open for all.

| Crop | Design | Parts | Status | Open |
|---|---|---|---|---|
| Tomato | [Classic staked tomato](plants/TOMATO.md) | 71 | approved (tall staked classic); variants (two floors, cherry spiral) after GA | perf (2 556), phone, 2nd |
| Potato | [Upright compound foliage](plants/POTATO.md) | 65 | approved, desktop CPU done | phone, 2nd |
| Frost Grape | [Tall vineyard trellis](plants/FROST_GRAPE.md) | 115 | frost flecks on ripe bunches, harvest burst | perf (4 140 + particles), phone, 2nd |
| Corn | [Tall two-ear stalk](plants/CORN.md) | 99 | complete | – |
| Lettuce | [Crisp head](plants/LETTUCE.md) | 70 | approved | phone, 2nd |
| Pepper | [Upright red chilli-pepper bush](plants/PEPPER.md) | 84 | approved (slender pointed chillies) | perf, phone, 2nd |
| Glow Mushroom | [Glowing chestnut bolete pair](plants/GLOW_MUSHROOM.md) | 60 | approved | perf, phone, 2nd |
| Golden Carrot | [Buried pointed root and tall feathery crown](plants/GOLDEN_CARROT.md) | 72 | approved; owner-harvest burst; desktop CPU done | phone, 2nd |
| Onion | [Half-buried brown bulb, tall quills and flower umbel](plants/ONION.md) | 59 | approved | perf, phone, 2nd |
| Cucumber | [Ladder-trellis vine with hanging dark cucumbers](plants/CUCUMBER.md) | 79 | approved | perf, phone, 2nd |
| Garlic | [Half-buried ivory head, flat leaves and curled scape](plants/GARLIC.md) | 54 | approved; desktop CPU done (1 944) | phone, 2nd |
| Broccoli | [Lobed blue-green foliage and a domed floret crown](plants/BROCCOLI.md) | 108 | approved (longer leaves) | perf, phone, 2nd |
| Pumpkin | [Arching vine, broad leaves, big ribbed orange fruit](plants/PUMPKIN.md) | 96 | approved | perf (3 456), phone, 2nd |
| Eggplant | [Tall open plant with three long hanging purple fruit](plants/EGGPLANT.md) | 113 | approved (cross fork round the stem) | perf (4 068), phone, 2nd |
| Blueberry | [Round highbush with ten berry bunches over the whole bush](plants/BLUEBERRY.md) | 134 | approved | perf (4 824), phone, 2nd |
| Sweet potato | [Trained fan with broad heart leaves and reddish root shoulders](plants/SWEET_POTATO.md) | 169 | approved | perf (6 084), phone, 2nd |
| Giant melon | [Arching vine, lobed leaves, big striped green melon](plants/GIANT_MELON.md) | 97 | approved | perf (3 492), phone, 2nd |
| Sunflower | [A1 spiral foliage + H2 layered head](plants/SUNFLOWER.md) | 192 (+141 meshes) | approved; desktop CPU and phone done | 2nd |
| Pineapple | [Tall stalk lifting a diamond-eyed fruit over a leaf rosette](plants/PINEAPPLE.md) | 155 | approved | perf (5 580), phone, 2nd |
| Apple, Golden apple | [Round-crown fruit tree on a 2 × 2 block; picks keep the tree](plants/APPLE_TREE.md) | 54 | approved (TR2; 2 × 2 TR4) | perf, phone |

## Phone and performance test

**Admin → 🧪 Field test** (`AdminFieldTest`, admins only, works in a published game) fills the own plot and every free plot of the ring
(8) with 78 ripe plants of one crop with growth art. Each tap moves on: off → Sunflower (heaviest, 192 Parts + 141 meshes) → Garlic
(lightest, 54 Parts) → off. A second button cycles the full-detail distance (`GardenViewFullDistance`): auto (the game's: 60 on phones,
230 on desktops with a step-down) → 60 → 120 → 170 → 230 studs; it also applies to the real plots. A readout shows frames in the last
second, the 95th-percentile and slowest frame of the last 5 s, the objects GardenView draws and the distance in use. Drawing only: no
remotes, no saved data.

Phone check: publish, join on the phone with an admin account, stand on the own plot, compare Sunflower with Garlic (and off) at the same
spot: standing still, turning the camera across the field, walking in from the hub (the full-detail build hitch shows as the slowest
frame). Reference: Studio desktop, Sunflower 61 FPS, slowest 19-24 ms, ~46 k objects; Garlic 60 FPS, ~12 k objects. Published desktop
client with all 12 ring-1 fields in full detail at 230 studs: Sunflower 88 FPS (~11 ms, 157 k objects), Garlic 140 FPS; hence the desktop
default of 230 with the step-down. Test it on the published client with Roblox's Maximum Frame Rate above 60 and no driver cap (AMD Radeon
Chill held it at 60). Phones keep 60 (passed).

## Studio growth player

In a Studio playtest, admins open **Admin → 🌱 Plant growth** (**🌱 Růst rostlin**): the reviewer with its crop list expanded. Its preview
draws its own plot above the garden (works with all eight plots occupied); Close returns to the Admin panel and restores camera / HUD.
Studio-only; no remotes, no saved data. The **Client command bar** works too:

```luau
require(game.Players.LocalPlayer.PlayerScripts.PlantGrowthReview).Open()                  -- first crop with a recipe, picker open
require(game.Players.LocalPlayer.PlayerScripts.PlantGrowthReview).Open("GoldenCarrot", 10) -- crop id, optional playback seconds
```

The seconds argument controls review playback only (not real crop timing). The **plant-name button** opens a scrolling picker built from
the crop catalogue and recipe modules when the reviewer opens, so new recipes join without another list. It also lists recipes with
`Draft = true`, which the field does not use: appearing here is not proof of field integration. Choosing a crop keeps growth, seed,
size factor, rings, view mode and playback, replaces the review plants / rings, refreshes the comparison neighbour and reframes the
camera. Close the reviewer before calling `Open(...)` again.

**One plant** = growth scrubber; **Five poses** = 0/20/50/75/100%; **Six seeds** = internal variation check. **Seed**, **Size**, **Rings**
change the comparison; **Play/Pause** runs the continuous preview.

[Plant picker](art/plant-review/crop-picker.jpg)

**Hybrid look prototype (HX0):** `PlantGrowthReview.OpenCross("Tomato", "Blueberry")` reviews one cross of two generated plants
(`GenePlant`, parents = `PlantGenome.Presets` ids or genomes; optional seconds, mutagen list `{ "Violet" }`, cross seed). **Six seeds**
shows parent A, four children and parent B; **Seed** picks one for the other modes. `OpenPresets({ "Palm", "AppleTree", "Cactus" })`
shows up to six presets side by side. When any plant of the row is big (`bulk` ≥ 1.5), the whole field opens and the six spots become
2×2 blocks. See [HYBRID_PROTOTYPE.md](HYBRID_PROTOTYPE.md).

## Review deliverable

Art review = **five snapshots only, at 0%, 20%, 50%, 75% and 100%** (user decision). Same seed, harvested-size factor, field square and
camera for all five; they are poses of one continuously growing plant, not five models. No 20-frame sequence, GIF or video unless
requested; extra seed rows, size galleries and camera views only when requested (seed / size checks stay internal). Historical GIF
links in old notes are not requirements.

Use the normal gameplay distance and a composition readable at phone size, with the crop on its real soil and surroundings. Check the
field pet, selection and progress ring together without a separate gallery. A resized desktop screenshot checks composition, not phone
performance. Studio review controls stay English.

## Decide the plant before animating it

**Review gates (user decision):** first present **three static mature variants** and wait for Ales's choice. Build growth
only for the selected variant, then present the five growth stills for art approval. Field integration and performance work
follow that approval as separate milestones. Combine these steps only when Ales explicitly requests it. Keep the variant
study small: enough geometry and scale context to choose the silhouette, without implementing three growth recipes.
A recipe module is in the field as soon as it exists, so the growth build starts with `Draft = true` (reviewer only); field
integration ends by removing it.

- Use the supplied references to choose the stem habit, leaf shape, fruit position and support needs. Potato needed upright,
  layered foliage; a flat rosette lost its identity. Preserve the cues that distinguish the crop at gameplay distance.
- Agree the mature silhouette from the three static variants first. Define height
  relative to the actual avatar on the same ground plane; a close-up alone hides scale mistakes. Frost Grape's living canopy,
  not just its posts, must exceed the player.
- State what harvest removes: the whole annual plant, or fruit from a persistent plant. Real-world biology does not automatically
  change existing gameplay. Frost Grape still uses the existing square-clearing harvest contract.
- Keep the current 5.5-stud square and its clearances. Existing recipes target a maximum 2.4-stud ground radius throughout growth,
  including rotated poses and supported size extremes. Record any deliberate exception before implementation.
- Choose intentional readability shortcuts. Potato's brown tuber shoulders show the harvest underground; its green berries are
  decoration. Grapes hang below the leaves. Shape, size and placement should communicate ripeness alongside color.

## Build one deterministic plant

Use a crop recipe through the shared `PlantGrowth` system, not a crop-specific scheduler or review UI. Build on
[`PlantKit`](../src/ReplicatedStorage/PlantKit.luau): its timing, seed and size helpers and its `Rig` (cached Part writes) belong
there, not copied into a recipe (`seeded`, `tendency`, `dimension`, `phase`, `axis`).

**Write a new recipe for `PlantKit.recipe`** (Broccoli, Garlic, Onion, Cucumber, Golden Carrot, Blueberry and Sweet Potato do;
the newest two are the best templates). One `geometry(s, g, emit, proxy)` describes the plant and `recipe` supplies `new` /
`SetGrowth` / `Destroy` / `BuildProxy`; its header lists the spec. Rigid stakes, trellis or fan go in `supports` (placed once,
full size, never posed); fruit slots, effects and extra proxy pieces go in the hooks. `geometry` emits the same Parts in the same
order at every growth; with `proxy = true` it skips what the proxy leaves out (no invisible placeholders). Older recipes with a
hand-written proxy take its stage growth from `PlantKit.proxyGrowth(stage, mid)` and rods from `PlantKit.proxyRod`.

Keep a recipe's `vary` draws in their order: a new draw goes last, otherwise every existing planting changes shape. Build a
bounded set of Parts once and pose them continuously. Leaves unfold at their bases; children follow the current parent as it
extends.
Growth should extend successive stems and organs with overlapping timings rather than uniformly inflate the entire model. A 43→44→43% seek
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

The shared [PlantGrowth registry](../src/ReplicatedStorage/PlantGrowth.luau) dispatches every crop of `CropConfig.Crops` whose
`<CropId>Plant` ModuleScript exists in ReplicatedStorage and is not marked `Draft = true`: a new recipe module is in the field
as soon as it exists, so stage unfinished art with `Draft`. Each art recipe builds
local anchored, non-colliding geometry and exposes:

| Entry | Contract |
|---|---|
| `new(parent, soilCFrame, seed, sizeFactor?)` | Build once; return an instance with `model`. |
| `plant:SetGrowth(0..1)` / `Destroy()` | Pose reversibly / dispose of the instance. |
| `BuildProxy(parent, soilCFrame, stage, seed?, sizeFactor?)` | Production mid-detail silhouette; required before field integration. |
| `PlayHarvest(parent, soilCFrame, sizeFactor?)` | Optional local feedback after a successful owner harvest; transient instances must clean themselves up. |
| `RingHeight` | Nominal ring offset; mass-scaled unless `FixedRingHeight` is true. |
| `FixedOrientation`, `FixedRingHeight`, `ReviewHeight` | Optional row-alignment, ring and Studio-framing rules. |
| `Draft` | Optional: `true` keeps the recipe out of the field (reviewer only). |
| `plant.fruitSlots` | Explicit fruit IDs, attachments and Part groups where authored; see below. |

The public plot feed supplies planting identity, harvested-size factor and server-time anchors; its schema belongs in
[PROTOCOL](PROTOCOL.md). Ordinary time updates preserve existing plant, soil and pet instances. Mid proxies retain the selected
silhouette and harvest cues; low detail removes crop art. Do not construct a full plant just to derive its cheaper proxy.

`FieldHand` dispatches optional harvest feedback through `PlantGrowth.PlayHarvest` from the existing successful Harvest-result
pop. Keep it independent of `Destroy`: a distance change, redraw or state correction must not play a harvest effect. Recipes
without this optional entry retain their ordinary pop.

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

Each crop keeps its Studio scripts in `tools/` (start from the newest crop's copy; no remotes or profile writes):
`<crop>_ripe_studies.luau` (Edit: the three static mature variants), `<crop>_growth_checks.luau` (seeds × harvested masses: Part
count, footprint, height, backward seeks) and `<crop>_integration_checks.luau` (Client: production `PlotView` with disposable
public-feed fixtures). A code change that must not change the look (PlantKit, a shared helper, a recipe refactor) is proven
with [`plant_golden_master.luau`](../tools/plant_golden_master.luau): run it in Edit before and after, the lines must be equal;
it needs no new stills.

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
