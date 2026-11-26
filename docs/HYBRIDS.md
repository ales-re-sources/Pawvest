# Hybrid plants (breeding)

Post-1.0 design. **Nothing here is built as a game mechanic.** Only the look prototype exists (HX0, Studio reviewer: `PlantGenome`,
`GenePlant`, [PLANT_GROWTH.md](PLANT_GROWTH.md) → Hybrid look prototype). Each point is **Decided**, **Proposed** (not agreed) or **Open**.
The milestone that settles the rest is HX1 in [ROADMAP.md](ROADMAP.md).

## 1. Concept
A player crosses two plants and gets a new one that is a random mix of both: shape, leaves, fruit, colours, size and value. Crafted
mutagens ("violet mutagen") bias a trait. A bad or odd result is part of the game. No LLM: the plant is drawn from a genome by one
generator, with real growth animation.

**Decided**
- Look: fully parametric generator; an authored organ library only as fallback if the look proves too plain (HX0 verdict: go).
- Stats: a hybrid has its own stats. Value per kg is inherited; kg and grow time are measured from the plant (§5).
- A hybrid is unique to its breeder but visitors see it.
- Big plants (trees, palms) take a 2×2 block of squares; the field grows anyway.
- Also decided (numbers and rules still open in their sections): grow time from plant mass and derived price (§5), two harvests and
  fruitless results (§3), perennials (§7), the player judges looks (§4), strains as the unit of breeding (§6).

## 2. What exists (HX0; as built: [HYBRID_PROTOTYPE.md](HYBRID_PROTOTYPE.md))
- **Genome:** 49 genes (architecture, stem look, leaves, fruit, timing, stats), packs to 49 bytes. Presets for the 19 catalogue crops and
  8 new types (Palm, AppleTree, Cactus, Toadstool, Tulip, Bean, Wheat, Strawberry).
- **Cross:** per gene a random point between the parents plus drift (±6% of the gene's range); option genes come from one parent; hues
  blend along the hue circle. Mutagens act after the cross (demo: Violet, Giant).
- **Footprint:** from the blended `bulk` gene (≥ 1.5 → 2×2), so a tree × tomato cross can come out big or small.
- The gene table is free to change until the first genome is stored; after that it is append-only.

## 3. Body and harvest
Every plant has one **harvest organ**, whatever its fruit genes build; everything else is the body. The generator keeps the two apart, so
the game can measure them separately.

| Plant | Body | Harvest |
|---|---|---|
| Apple tree | trunk, branches, canopy | apples |
| Sunflower, tulip | stem, leaves | the bloom |
| Cactus | the spiny stem | the bloom or fruit on top |
| Lettuce, broccoli | leaves | the head |
| Potato, carrot | tops | buried roots |

**Decided: a hybrid can have two harvests or none.** Neither is possible in the HX0 genome yet:
- *Two harvests on one plant* (apples above, potatoes below): a genome has one fruit group; a second (~15 genes) must be added before the
  first genome is stored. **Open:** when a cross gets it (proposed: only when the parents' harvests sit in different places, e.g. buried
  and on the stem), and how the two are harvested and sold.
- *A fruitless plant* (the "hollow tree"): fruit count has a minimum of 1. **Open:** the sterility rule (proposed: the chance grows with
  the distance between the parents' genomes).

## 4. Measuring the result
The game does not judge genes; it measures the plant the generator built, once per strain:
- **Yield:** fruit count after all clamps × fruit volume (the basis for kg).
- **Footprint and height:** one square or a 2×2 block.
- **Losses:** how much the layout had to cut (fruit that did not fit, leaves shrunk to stay in the square): a fair "weak plant" signal.

Beauty cannot be measured. **Decided:** the player judges looks, the game judges yield.

Selection today: a child lies between its parents, so big × standard usually gives something smaller than the big parent and only a few
percent beat it; pushing a trait means big × big. **Ceiling:** each gene has a range (fruit size ends at 2.6 studs) and fruit count is capped
by fruit size and footprint (`floor(5 / size²)` on a square, `floor(24 / size²)` on a block), so size and count trade off without extra rules.

## 5. Price and grow time
**Decided:**
- Price is derived, not a free gene: `harvest kg (measured, §4) × value per kg (inherited)`. A fruitless tree earns nothing and a lucky
  hybrid earns more, with no special cases.
- Grow time is derived from plant mass (a bigger plant takes longer; a 2×2 plant pays for four squares). Why: with a freely inherited
  grow time players would breed high yield with a short grow time and Coins per square-hour would have no ceiling. The `growHours` and
  `kg` genes go away; `value` stays as value per kg.

**Open:** the mass → grow time formula, the range and drift of value per kg (it compounds over generations: cap or rising cost), and the
fit with the EV3 crop levels, all through `tools/economy_ev.py`.

## 6. Strains, seeds and the breeding flow
**Decided:** the unit is the **strain** (one genome), not the single fruit.
- Harvest goes to the barn and sells as today (the profile stores counts and summed sizes per crop; single fruits by weight would mean
  storing every fruit).
- A cross takes two strains the player owns plus a cost in harvested fruit of each (a Coin / produce sink).
- The breeding UI is a strain list, sortable by kg, value and Coins per hour.
- Selection pressure comes from a limited number of strain slots: the player chooses which children to keep.

**Open:** number of slots, cost of a cross, whether a catalogue crop counts as a strain from the start, what happens to planted squares
of a discarded strain, mutagen sources and recipes.

## 7. Other open design work
- **Perennials (decided: yes):** a tree is not removed by Harvest; the body stays and fruit regrows. Needs a lifecycle with separate body
  and fruit state ([PLANT_CATALOGUE_SCALE.md](PLANT_CATALOGUE_SCALE.md) → Lifecycle). Open: which gene makes a plant perennial
  (proposed: `wood`), regrow time, whether a perennial ever dies or is only dug up.
- **2×2 on the field:** planting, pet reach, the square card and rings on a block; the field size increase.
- **Storage and feed:** strain ids and genomes in the profile; genomes in the public plot feed (the one-letter crop codec must go first,
  PLANT_CATALOGUE_SCALE.md).
- **Names, icons, field guide** for player-made plants (names are user data: text filter).
- **Wording:** EXPANSION §1.1 says "no random weather mutations"; hybrids are bred, not a weather lottery. Decide the term (hybrid / strain
  vs mutation) and adjust that line.
- **Hidden (recessive) genes:** proposed to stay with the simple blend for now.

## 8. Prerequisites (proposed, none scoped)
What must exist before breeding can be built. The first six are also worth building for the catalogue crops alone.

| Item | What is missing today | Why hybrids need it |
|---|---|---|
| **Perennial lifecycle** | One `Grown` clock per square; Harvest removes the planting. No body / fruit split, no regrowth, no dig-up. | Trees and bushes keep their body. Prove it on catalogue crops first (Blueberry, Frost Grape, a first tree). |
| **Bigger field and 2×2 blocks** | 78 squares, one planting per square; storage, planting, rings, square card, pet reach and PlotView all assume one square. | Big plants. A 400-Part plant also needs its own place in GardenView's detail budget. |
| **Plot-feed codec** | One letter per crop in the public feed (PLANT_CATALOGUE_SCALE.md). | Visitors must receive a strain's genome, not a catalogue letter. |
| **EV3 signed off and built** | Crop levels are a draft; the model has a fixed crop ladder. | Derived price and grow time must be modelled against the final economy; a strain's crop levels and unlock position depend on EV3. |
| **Phone performance of plant art** | Phone and second-client checks are open for most crops. | Generated plants add 140 / 400-Part recipes nobody hand-tuned. |
| **Catalogue UI at scale** | Seed stall, barn and seed picker render every row; no search or sort. | Strain lists grow per player. |

**Hybrid-specific**
- **A crop definition that is not in `CropConfig`.** Field, barn, stall, `PlantGrowth` and `Locale.CropName` resolve a crop through
  `CropConfig.ById`, and unknown ids are dropped from saves. A strain needs a per-player definition built from its genome, known to the
  server and to every client that sees the plot: the largest architectural change.
- **Strain storage:** strain ids, genomes, slots, stock and records keyed by strain; rules for a discarded strain.
- **Generator to production:** measuring functions (yield, mass, losses), the second fruit group and sterility, mid / low proxies checked
  on real plots, a fixed gene table before the first save.
- **Catalogue crop → genome:** a hand-built crop and its preset do not look the same, so Tomato × Tomato would visibly change the plant.
  Open: accept it (presets are "wild" breeding stock) or tune presets until the step is small.
- **Icons** for strains (catalogue crops have an authored icon): a rendered thumbnail or a generated swatch.
- **Names:** player-typed strain names need the text filter (live test only; Studio does not filter) and a fallback name.

**Order (proposed):** perennials → field growth and 2×2 → plot-feed codec with dynamic crop definitions → strain storage and server cross
→ breeding UI, names, icons. EV3 and the HX1 numbers run beside the first two.
