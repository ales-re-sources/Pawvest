# Hybrid look prototype (HX0), as built

Studio reviewer only: nothing is saved, sent or in the field. The design it serves: [HYBRIDS.md](HYBRIDS.md). Function-level detail is in
the code comments; this page holds what the code does not say: the overall shape, what each gene means and what is weak.

## Files
| File | Role |
|---|---|
| `src/ReplicatedStorage/PlantGenome.luau` | the gene table (`GENES`), `new`, `random`, `cross`, `Mutagens`, `pack` / `unpack`, `footprint`, `Presets` |
| `src/ReplicatedStorage/GenePlant.luau` | `recipe(genome)`: an ordinary `PlantKit.recipe` drawn from a genome; `row`, `cross`, `presets` build review recipes |
| `src/StarterPlayer/StarterPlayerScripts/PlantGrowthReview.luau` | `OpenCross`, `OpenPresets`, the 2×2 block layout (commands: [PLANT_GROWTH.md](PLANT_GROWTH.md) → Hybrid look prototype) |
| `docs/art/plant-review/hx0/` | 18 stills: presets beside real crops, crosses, growth rows, mutagens, new plant types and 2×2 |

`GenePlant` is `Draft` and its module name matches no crop id, so `PlantGrowth` and the field never load it.

## Try it
Start a playtest and run in the **Client** command bar. Each call opens the reviewer on a disposable plot; its buttons (Six seeds / Five
poses / One plant, Seed, Size, Rings, scrubber, Play) work as for a catalogue crop. After a code change restart the playtest.

```luau
local R = require(game.Players.LocalPlayer.PlayerScripts.PlantGrowthReview)

R.OpenPresets({ "Palm", "AppleTree", "Cactus", "Toadstool", "Wheat", "Sunflower" })   -- up to six presets side by side
R.OpenCross("Tomato", "Blueberry")            -- Six seeds: parent A | four children | parent B
R.OpenCross("AppleTree", "Tomato")            -- big × small: children come out on a 2×2 block or on one square
R.OpenCross("Pumpkin", "Corn", 10, nil, 2)    -- 5th argument: another set of four children (default 1)
R.OpenCross("Tomato", "Pepper", 10, { "Violet" })          -- mutagens: "Violet", "Giant", or both
```

- `OpenCross(parentA, parentB, seconds?, mutagens?, crossSeed?)`, `OpenPresets(ids, seconds?)`; `seconds` = one growth playback (default 10).
- A parent is a preset id or a genome table, so a child can be bred on:
  ```luau
  local G = require(game.ReplicatedStorage.PlantGenome)
  local child = G.cross(G.new(G.Presets.Tomato), G.new(G.Presets.Blueberry), Random.new(7))
  R.OpenCross(child, "Pumpkin")
  R.OpenCross(G.new({ stems = 3, height = 4, leafShape = "feather", fruitShape = "pod", ripeHue = 0.6 }), "Corn")
  ```
  `G.new` fills every gene not given with its default; `G.random(Random.new(n))` gives a random plant.
- In **Six seeds**, seed 1 is parent A, 2-5 the children, 6 parent B; **Seed** picks one of them for the other modes.

## Plants (27 presets, `PlantGenome.Presets`)
| | Ids |
|---|---|
| Catalogue crops (19) | `Potato`, `Lettuce`, `Onion`, `Garlic`, `Tomato`, `Cucumber`, `Corn`, `Pepper`, `Broccoli`, `Pumpkin`, `Eggplant`, `Blueberry`, `SweetPotato`, `GiantMelon`, `Sunflower`, `Pineapple`, `GoldenCarrot`, `FrostGrape`, `GlowMushroom` |
| New types, one square (6) | `Cactus`, `Toadstool`, `Tulip`, `Bean`, `Wheat`, `Strawberry` |
| New types, 2×2 block (2) | `Palm`, `AppleTree` |

Presets are hand-fitted: they resemble their crops, they do not reproduce the authored art. Any two cross. Mutagens
(`PlantGenome.Mutagens`, act on the child after the cross: set a gene, scale it, or hold a minimum): `Violet` (ripe colour), `Giant` (fruit
size ×1.6, count ×0.5).

## Genome (49 genes, one byte each when packed)
A genome is a table `gene id → number`. Kinds: `num`, `int`, `hue` (wraps), `pick` (index of an option). Ranges and defaults: the `GENES`
table in `PlantGenome.luau`. There is no plant "type" gene: a rosette, a bush, a vine and a tree are points in one continuous space, which is
why any two plants cross. Hues are 0-1 around the colour circle (0 red, 0.15 yellow, 0.3 green, 0.6 blue, 0.78 violet).

| Group | Genes | What they control |
|---|---|---|
| Architecture (13) | `stems`, `height`, `spread`, `arch`, `lean`, `branches`, `branchAngle`, `branchAt`, `wood`, `stemWidth`, `support`, `climb`, `bulk` | number and height of stems, upright ↔ sprawling, curvature, branches and where they start (high = tree crown), stake / trellis and training along it, overall scale (`bulk` ≥ 1.5 → 2×2 block) |
| Stem look (4) | `stemHue`, `stemSat`, `stemTone`, `stemStyle` | colour; smooth / ribbed / spiny / segmented |
| Leaves (11) | `leafShape`, `leafLen`, `leafWidth`, `leafCount`, `leafFrom`, `basal`, `droop`, `leafHue`, `leafSat`, `leafTone`, `leafVary` | blade / round / lobed / strap / feather / mass (canopy clumps); size; leaves per stem and where they start (high = bare trunk); ground rosette (`basal` ×10 leaves); colour |
| Fruit (15) | `fruitShape`, `fruitSize`, `fruitAspect`, `fruitCurve`, `fruitCount`, `fruitAt`, `fruitHang`, `unripeHue`, `ripeHue`, `ripeSat`, `ripeVal`, `pattern`, `patternHue`, `patternSat`, `extra` | ball / tapered / cluster / head / pod / cap / bloom; size and proportions; count (capped by size); position from buried (-0.3) to stem tip (1); colours unripe → ripe; stripes / spots (ball, tapered, cap); crown / glow / frost / husk / tuft |
| Timing (3) | `bloomAt`, `flowerHue`, `ripenSpread` | when flowers open, their colour, how staggered the fruit ripens |
| Stats (3) | `growHours`, `value`, `kg` | carried, unused. `growHours` and `kg` are to be removed (HYBRIDS §5) |

- **Cross:** every gene draws two random numbers whatever its kind, so changing one gene never shifts the others. Numbers blend at a random
  point between the parents (`log` genes in log space) plus a drift of ±6% of the range; hues blend along the shorter arc (±0.03); picks
  come from one parent.
- The gene table is free to change until a genome is stored; then append-only, read by id.

## Generator pipeline (`GenePlant.recipe`)
1. **Fruit body:** the fruit's pieces from shape, aspect, pattern and extra (in fruit-size units).
2. **Layout:** organ counts clamped to the Part budget (140 on a square, 400 on a block). Leaves give way first, fruit and stems last. Fruit
   count is also capped by size (`floor(5 / size²)`, `floor(24 / size²)` on a block). The Part count is fixed per genome, never per planting
   seed.
3. **Shape (per planting seed):** stems as 3-point polylines, branches at golden-angle directions, leaves along stems and branches plus a
   ground rosette, fruit spread over stems then branches around `fruitAt`. The seed only adds small variation, as in authored recipes.
4. **Geometry (per growth 0-1):** seed leaves → stems extend → branches follow → leaves are born in order and unfold → flowers open and
   drop → fruit swells and ripens. Same emit order at every growth, so seeking back and forth is exact.
5. **Bounds:** every Part stays inside the footprint radius (2.4 studs on a square, 5.2 on a block); leaves shrink by an exact corner test,
   fruit is pulled towards the axis and rests on the soil.
6. Mid-detail proxies come from the same geometry through `PlantKit`'s `BuildProxy`.

Measured (desktop, 347 genomes): at most 140 Parts (square) / 398 (block), ground radius at most 2.38 / 5.13, build 3.9 ms, pose 1.2 ms.

## Known weaknesses
- 12 of the 19 crop presets were never compared side by side with their real crops; Tulip and Bean were not captured.
- Blooms face straight up (a sunflower head is edge-on to the camera); melon stripes are faint; glow turns the mushroom cap bright orange;
  `climb` only pulls the stem top to the rail.
- Five poses on 2×2 blocks: the front row hides the back row.
- No phone check, no real plot (`PlotView`) check, no low-detail tier.
- Missing for the mechanic: measuring functions (yield, mass, losses), a second fruit group, fruit count 0, perennial states.

## What carries over to production
Kept: the genome-as-data design, the cross, the pipeline and its bound / budget guarantees. To redo: the gene table (second fruit group,
stats genes), preset tuning, the reviewer wiring (synthetic crops `GeneCross` / `GenePresets`).
