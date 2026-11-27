# Pawvest — pet-garden expansion design (E1–E11, drops D1–D10)

**Status.** Built and open to every player: the crop field, crops, size roll, crop mastery, upgrades and tier-1 tools, the market cart and
rotating seed stall, field pets with aptitudes and Tending, obby seeds, crows and Pest-control guards, the request board, the Harvest Hall and
plot likes (rules in **GDD §7.6–7.9**; numbers in `CropConfig` / `PetConfig`, pinned by `tools/economy.py`; state in the ROADMAP status
table). This document keeps the **design not built yet** plus the rules every drop must follow (§1.1, §13); each section says what of it is built.

**Name: Pawvest.** Store subtitle "Pets · Garden · Obby", tagline "Grow. Guard. Run.". Availability on Roblox and the trademark are still
to be checked. Avoid leading with "Grow" / "Garden" (the market leader "Grow a Garden" has pets with abilities). Numbers below are
placeholders until the economy model takes them ([ECONOMY.md](ECONOMY.md)); milestones become ROADMAP entries when they start.

## 1. Vision and pillars
**Pitch:** *grow things, put your pets on guard, run obbies for rare seeds.*

The obby is finite content; **systems** (crops growing, critters at the fence, the forecast, weekly events) give a reason to come back, pets
differ in *what they can do*, not in how big their number is, and the obby and mini-games supply the garden with what it cannot make.

| Pillar | Meaning |
|---|---|
| Pets are characters | Aptitudes, quirks and bond; rarity gives breadth, time gives height (§4); the only pure number stays the +50 % Coin multiplier cap |
| One pet, one place | A pet is in one place at a time (a field square or with you); allocation is the game |
| The garden is a place | It grows while you are away, is attacked while you are away, and visibly evolves |
| The obby is the expedition | A skilful run brings back things the garden cannot make |
| Earned, not rolled | Rare results (variants, rare crops, pets' best forms) come from what the player did; never from a slot machine |
| Coins buy verbs and looks | Coins unlock tools, abilities and a visible estate, never just a bigger number |
| Robux buys comfort | Time, capacity reached sooner, convenience and cosmetics; never luck, never a random item, never weather (§13) |

**GDD pillars:** farming is the main income (targets in ECONOMY.md), and the best crops are reachable only through the obby. Fair
leaderboards are unchanged: pets, tools and anything bought never touch movement or stage times. GDD §9 follows §13: no Coin packs, no Robux eggs.

### 1.1 Not another Grow a Garden
Pawvest shares a proven genre loop (plant, wait, harvest, sell, upgrade) with the market leader. Sharing *only* the loop is the danger: next to
a much bigger game we lose on every shared axis, a "ripoff" reputation sticks, and the leader's excitement comes from gambling that Pawvest
rules out. Rules, **checked for every drop before it ships**:
- **Lead with what is ours.** The first ten minutes, the store page and the thumbnail show the obby, pets on guard and critters at the fence;
  planting and selling are the frame, not the hook.
- **Avoid the leader's signature mechanics:** no seed shop restocking every few minutes (a daily market cart and a stall rotating every few
  hours instead), no random weather mutations (variants are earned, §5.3), no buying weather for a server (§13), no gear named like theirs
  (sprinklers, trowels; §6).
- **Our weather serves the defence:** it drives the forecast of critter visits (§7, §9.1), not a mutation lottery. (HYBRIDS.md: hybrids are
  bred, not a weather lottery; the term is still open.)
- **Size is social:** the size roll feeds the Harvest Hall and a weekly Harvest Fair (§9.3), not only a number.

## 2. Decided
| Topic | Decision |
|---|---|
| Core | Farm-sim garden + guardian defence. Collector is a by-product (field guide over trait and harvest data, strays later) |
| Expeditions | Pets are **not** sent away (they would duplicate the farm's timers); the obby is the expedition |
| Pet identity | Aptitudes with levels + quirks (§4); breeding is out for now but the trait set must stay breeding-ready |
| Raids | Offline only, resolved by the server, reported in a ledger. No active shoo mode, no PvP |
| Garden loop | No chores (no watering, no manual weeding); ripe crops wait and never rot |
| Unifying rule | One pet, one place: pets stand on field squares (no pens, no posts), reach by aptitude level (§3) |
| Long goals | Island restoration bundles, estate tiers + cottage, pet mastery, garden score — all four (§12) |
| Decoration | Free placement **outside only**, per-tier limit, validated on the server; the cottage is fixed |
| Online vs offline | Crop growth runs 2 online / 1 offline, capped at 24 h per absence (GDD §7.9); never pure AFK (Roblox no longer pays for uptime) |
| Seed shop | Mastery-gated catalogue, a rotating stall and a daily market cart (built); rare seeds are never sold |
| Harvest rolls | Every harvest rolls a **size** (built). **Variants** are **earned**: fertilisers from rare crops and pet aptitudes / quirks give the chance, weather only adds a bonus (§5.3) |
| Farm stages | Obby stages themed on the farm; each owns one unique rare crop (§8.2) |
| Mini-game gates | Mini-games may gate content only by **completion**, never by time or skill ceiling (§8.3) |
| Live ops | A drop every **1–2 weeks**; systemic content (forecast, market cart, weekly challenge, fair) before authored seasons (§9, §14) |
| Monetization | No paid random items, luck and weather are never sold; Robux buys comfort (§13) |

## 3. One pet, one place
*Built for Tending and Pest control (GDD §7.9): squares, slots, reach by aptitude level, the strongest pet of a job counts on overlaps, a pet
with both jobs does both, "with you" = the 3 equipped slots (Scouting, Coin multiplier).*

Not built / open:
- **Fertilising and Weeding** on the field arrive with their drops (D4, D1). Open: whether a pet with several field aptitudes does all of them
  (as Tending + Pest control do) or picks one job when placed.
- **Placement is the end-of-session decision:** guards to the side the forecast names (§7), tenders to the long crops; the middle covers more
  than a corner.
- **Moving field pets from far away** (from the Pets panel during an obby session; today garden actions need the own plot): open, §16.

## 4. Pet aptitudes, quirks and bond
*Built (GDD §7.9, `PetConfig`): the aptitude ids (Cuteness, Tending, Fertilising, Pest control with a speciality, Weeding, Scouting,
Crafting), levels 1–10 with diminishing effect, counts and caps by rarity, rolled once from the uid with the kind leaning the draw, XP per
weighted field hour. Cuteness carries the Coin bonus; the pet level is the highest trait level (size and look follow it); new pets roll only
working traits (Fertilising / Weeding / Crafting rejoin the hatch pool when built). Only Tending, Pest control and Scouting do something yet.*

**Rule: rarity gives breadth and a higher cap, time gives height.** A maxed Uncommon (level 7) equals an Epic at level 7; the rarer pet is more
flexible, not stronger at a job. New aptitudes get new ids (stored ids never change).

| Aptitude | Effect still to build |
|---|---|
| **Fertilising** | Faster growth and a better size roll on the squares in reach; from level 7 a small Golden chance rising with the level (§5.3) |
| **Pest control** | Specialities against moles, slugs, raccoons (only crows exist today; §7) |
| **Weeding** | Keeps weeds off (§7) |
| **Crafting** | Runs station queues faster (§5.6) |

- **Tonics (provisional):** every aptitude level from 7 up also needs a tonic brewed from a rare crop (Apothecary, §5.6), tying the best pets to
  the obby.
- **Quirks** are qualitative and carry a cost; target about 30, rolled from the uid (`Pets[uid].Quirks`). Examples (effect / cost): Light
  sleeper (guards at night / weak by day), Digger (finds a seed when idle / scatters the square), Glutton (food gives extra XP / nibbles crops),
  Lucky (small variant chance, no fertiliser needed, §5.3 / lower base yield), Greedy (extra yield / some crops lost), Brave (holds the line
  alone / ignores forecasts), Friendly (bond grows fast / distracted from work).
- **Looks follow the work:** size and tier effects follow the pet's highest aptitude (built); still to build: accessories pick by that
  aptitude (a veteran guard gets the scarf, a tender the straw hat).
- **Bond:** favourite food, mood and affection. Mood gives only bonuses, never penalties (no guilt-driven check-ins).
- Personal spending: dyes, outfits and a den furnished to the pet's preferences (a fox wants a burrow).

## 5. Crop economy
*Built (GDD §7.9, ECONOMY.md): the field loop (one crop per square, ripe crops wait, Tending replants during absences), one crop ladder with
tiers that set Coins per hour (`CropConfig`), crop mastery, the market cart and seed stall, the size roll with records, selling with pet
bonuses, crops as pet food.* **Not built:** fruit trees (§5.4).

Harvests are items with four uses: sell, process at a station (about 1.5–2× the raw value), turn in on a request or in a restoration bundle,
replant. **Grow times match real-life gaps** (a quick crop for a short session, 1 h for lunch, the longest for the night): "what do I plant
before I leave, and who guards it?" is the end-of-session decision.

### 5.1 Plant growth art
Crops grow continuously as recognizable individuals in the stud-block style; stable variation and visible harvest size distinguish
plantings, and silhouettes and ripeness must read at phone size. Annual harvest clears the plant; future perennials keep their seeded
structure and regrow fruit at persistent attachment points (rigid supports separate from growing organs). Authoring commands, recipe
contracts and the five-snapshot review (0/20/50/75/100 %) live in [PLANT_GROWTH.md](PLANT_GROWTH.md); status in ROADMAP.

### 5.2 Seed catalogue and market cart (not built parts)
- **Species unlocks from the obby:** first finishes / first Golds and challenge-coin milestones unlock catalogue species (§8.1), on top of mastery.
- The cart may also offer a fertiliser ingredient or a decor piece; its offers are never sold or re-rolled for Robux (§13).
- **Weekly visitor** (E8): a travelling merchant with an exotic or seasonal species for the week.

### 5.3 Earned variants
Variants roll on the server per planting (like the size roll: re-joining cannot reroll) and are worth several times the crop (provisional
×2–5) and an entry in the field guide (§11). A crop can only become a variant if something the player did gives it a chance:

| Variant | Source of the chance | Bonus | Value (provisional) |
|---|---|---|---|
| Frosted | Frost fertiliser on the square (brewed from the ice world's rare crop) | higher during Frost weather | ×2 |
| Golden | Gold-leaf fertiliser (from a farm-stage crop) or a Fertilising pet of level 7+ covering the square | – | ×5 |
| Starlit | Night fertiliser (from a world-3 rare crop) | only ripens Starlit during an Aurora | ×3 |
| any | Lucky quirk pet on the square (small chance, no fertiliser needed) | – | as the variant |

- **Fertilisers** are crafted at the Compost station (§5.6) from rare crops plus common ones and applied to one square for its next crop: a
  sink for rare crops and a reason to run the stage that supplies the ingredient.
- Size and variant stack; the expected value with tools, fertilisers and pets maxed goes through the economy model (E0) before D4. A variant
  or record item is stored apart from the plain per-crop counts and summed sizes the barn keeps today.
- Giants can enter the Harvest Fair (§9.3) or stay as a yard trophy (E7) instead of being sold.

### 5.4 Fruit trees (perennials; ROADMAP → TR)
A tree is a perennial on the crop field: planted from a sapling, it is never cleared by a harvest and bears fruit for good. *Decided (the
user, 2026-11-27):* trees are the first update after 1.0; a tree takes **one square** (1×1; big 2×2 trees come with the Orchard landmark
or hybrids); **digging one up loses it** (two-tap confirm, as for a crop); saplings come from the **seed stall** (Coins, mastery-gated,
at most 3 per kind, each next one dearer) **and the obby** (a rare tree per world, never sold, like the rare crops); the first update
ships **two kinds: one stall tree and one rare obby tree**.

Proposed rules (confirm in TR0):
- **Lifecycle:** sapling → first growth → one fruit at a time up to a cap (4–6); ripe fruit waits and never rots; at the cap the tree stops
  bearing. Growth as for crops (online ×2, offline ×1, 24 h cap; Growth upgrade and Cloches apply).
- **Picking:** a Basket tap on a bearing tree picks every ripe fruit that fits in the barn; each fruit rolls its own size (Hall records,
  ribbons and requests work unchanged). A Tending pet picks during absences (nothing to replant); crows eat at most one fruit, never the
  tree; a rare tree is never raided.
- **Mastery:** each picked fruit of a stall tree counts one plant toward that tree's ★ and points; Speed shortens the time between fruits.
  Rare trees give no mastery (as rare crops).
- **On the field:** a bearing tree's ring shows its fruit ("🍎 3/4") instead of the pie; trees stay out of the shared ring height (the
  tallest plant), or one tree lifts every ring. Fruit regrows at the recipe's fixed fruit slots (PLANT_GROWTH → Identify fruit).

### 5.5 Guardrails
Checked by `tools/economy.py check` after every rebalance (targets: ECONOMY.md): rare crops pay the most and only the obby gives them; seeds,
squares, tools, fertilisers, stations, barn, decor and bundles absorb a fixed share of the faucet; comfort purchases (§13) speed progress up
by a bounded factor and never change online income.

### 5.6 Requests and stations
- **Request board:** built (GDD §7.9: three tracked crop requests a day, a bonus on completion, a rare seed or a free egg as the drop). Not
  built: "a Big pumpkin" / "a Frosted carrot" requests, the timed-run requests (with Sunshine, EV2c), a quest book.
- **Stations** (queues with timers; Crafting pets run them faster): Compost (fertilisers, the first station, with the variants, D4), Mill
  (grain → flour), Kitchen (crops → pet food, a cheaper route to levels than shop food; raw crops can already be fed), Workshop
  (decor, plot upgrades), Apothecary (tonics, mastery items).

## 6. Garden tools
A Coin tree gated by crop mastery, never touching the obby, never sold for Robux (§13). Names are our own (§1.1). Data: `Garden.Tools[id] = level`.
*Built (GDD §7.9): Seed sorter (size), Cloches (online growth), Pruning shears (a second crop), plus the Growth and Barn upgrades.*

| Tool | Raises | Axis | Ships |
|---|---|---|---|
| Seed chest | seed stock and storage (Tending pets replant longer; may fold into the Barn upgrade) | Comfort | D1 |
| Wheelbarrow | harvest every ripe square with one prompt | Comfort | D2 |
| Scarecrow | raid defence on a few squares (§7), weaker than a Pest-control pet, takes no field pet slot | Defence | D1 |
| Clearing tools (parked) | locked squares lie under rubble or weeds; clearing a kind needs a tool level or a bought tool, on top of the square's price | Reach | later |

**No tool raises variant chance:** variants come from fertilisers and pets (§5.3).

## 7. Critters and raids
The defence loop is Pawvest's strongest hook (§1.1). Critters raid the garden while the player is away; never other players.
*Built (GDD §7.9): crows on a fixed UTC block schedule, the forecast line in the barn panel, Pest-control guards with the crow speciality,
deterministic resolution on join, at most 1 crop lost per absence, rare crops safe, losses in the join notice.*

Still to build (drop D1 unless noted):
- **Weather drives critters** (§9.1): rain brings slugs and moles, a dry spell brings crows, frost keeps most away, a clear night brings raccoons.
- **Forecast board** with the coming weather and visitors together ("rain tonight: slugs likely; crows at dawn").
- **Counters** (composition matters, not strength); a speciality works double against its critter: moles (growing crops) → mole
  speciality; slugs (many small bites on leaves) → wide reach, several guards; raccoons (stored goods, at night) → raccoon speciality (how a
  guard covers the barn: open); a weekly locust swarm (everything) → wide coverage.
- **Weeds** (provisional): grow while the owner is away on squares no Weeding pet covers, slow growth and lower the size roll; the harvest
  clears them. Never a chore: no manual weeding.
- **Raids from a side** the forecast names (provisional, "crows from the north tonight"): guards on that side cover the squares hit first.
- **Losses stay soft:** some crops or Coins, never pets, never a variant or a trophy. The join notice grows into the **ledger** of the absence:
  raids, harvests and their rolls, finished station queues, strays at the gate (the E5 ledger on join is built for the garden basics).
- Open: loss caps per raid for the full set and what a perfect defence earns (§16).

## 8. Obby, farm stages and mini-games
### 8.1 Obby links
*Built (E2, GDD §7.9): the seed pouch, a rare-seed meter per stage (no drop chance), one rare crop per world, Scouting from equipped pets
(meter speed and a pouch seed, capped at +50 %). Decided, after 1.0 (EV2c / ECONOMY.md → EV): repeat runs pay Sunshine instead of Coins;
Scouting XP = seconds of a running stage timer.*

Not built:
- **Species unlocks:** first finish / first Gold of a stage and challenge-coin milestones unlock catalogue species (§5.2).
- **Rare crops as ingredients** for fertilisers and variants (§5.3), landmarks (§12), tonics, unique products (a night-watch tonic, a critter
  repellent) and trophies. Rare items come only from the obby.
- Pets never touch times, movement or medals; only what a finish pays.

### 8.2 Farm stages
Obby stages themed on the farm (greenhouse, scarecrow field, orchard canopy, barn loft…), built from the existing kit (STAGES.md §2). Each farm
stage **owns one unique rare crop**: the first finish unlocks the species and gives a few seeds, the first Gold more, its meter more after that;
its seeds are never sold, so every farm stage is also a garden update; the crop is the ingredient of a specific fertiliser, landmark, tonic or
request (the first farm stage supplies the Gold-leaf fertiliser). Open: **bonus stages** outside the unlock chain (STAGES.md §5.3; reachable
from the garden island; recommended) or numbered world stages. Times and medals follow GDD §4.

### 8.3 Mini-games as gates
Mini-games (puzzle rooms like the Laser Lab prototype `Workspace.KeyArena`, garden-side games) may unlock content under one rule: **a gate tests
completion, never speed or skill ceiling**, so a garden-first player cannot get stuck. A gate shows a hint, is retryable without cost, and stays
replayable afterwards for a small daily reward. Uses: a restoration bundle input (§12; old mill: Coins + wheat + a Crafting pet + clear the
Gear Puzzle), a one-time unlock (a puzzle room opens a seed tier or a station), a repeatable source (fishing at the Pond after its
restoration, a harvest rush; short, counts as online time). Each mini-game is 1–3 minutes (GDD pillar 1) and passes the mobile check (ROADMAP → MU).

## 9. Weather and live events
### 9.1 Weather
- A schedule **derived from the UTC clock**, the same on every server, shown on the forecast board ahead of time (§7). Provisional: a change
  every few hours, so a forecast covers the player's absence; rare kinds (Aurora) rotate through the day so every time zone gets them.
- **What weather does:** decides the coming critters (§7), gives small growth bonuses to present players (Rain: faster growth while online),
  and raises the chance of a variant **that a fertiliser already made possible** (Frost, Aurora; §5.3). Weather alone never makes a variant.
- Art: a sky / lighting preset and particles per kind; no new models. **Weather is never sold** (§13).

### 9.2 Weekly obby challenge
- One existing stage per week with a kit **modifier** (low gravity and wind from `KitZones`, no checkpoints, a ghost of last week's #1), by a
  fixed rotation.
- A **weekly Top-10** reset every Monday 00:00 UTC (new `GlobalLeaderboardsStore` keys per week), so new players can top a board.
- Rewards: a finish gives a rare seed; the weekly Top-10 gets a cosmetic yard trophy. Same talent and pet rules (fair leaderboards).

### 9.3 Harvest Fair
- *First form, built:* the **Harvest Hall** (GDD §7.9): the week's biggest crop of every kind, global, on pedestals at the hub.
- The fair: a weekly prize-vegetable contest at the hub, one crop per player per category (rotating: pumpkin, melon, a farm-stage crop…).
- Ranked by size factor (every tier can compete); the top entries get a ribbon trophy, every entrant Mastery XP or a similar reward; the
  entered crop is kept. A small store per week, like the weekly challenge board.
- Size gets a social stage without a gamble: the roll is free, the Seed sorter and the choice of entry are the skill.

### 9.4 Seasons
4–6 weeks each: a theme, 3–4 seasonal crops, one seasonal pet kind (adopted, not hatched from a paid egg), a decor set, a seasonal farm stage or
challenge and critter; a **season pass** with a free and a premium track (§13), fed by season XP. Starts only after the forecast, market cart,
weekly challenge and fair run without attention.

### 9.5 Streak calendar
A 7-day loop of small rewards (days 1–6 Sunshine 10–30 min, **day 7 an Epic-or-better pet**: Epic 95 %, Legendary 5 %; numbers in ECONOMY.md →
EV, after 1.0); a missed day **pauses** the streak instead of resetting it (no guilt).

## 10. Social
*Built (GDD §7.9): the Harvest Hall (§9.3) and likes on plots (once per plot per day). The rest of this section is D6.*
*Later: gifts / buying something for a friend, a pet auction (needs trading's session locking).*

- **Friend bonus:** a small bonus on harvest sales while a friend is on the same server (provisional +10 %, outside the pet multiplier cap).
- **Visits and likes:** the plot ring is walkable; a like feeds the other plot's garden score.
- **Help a neighbour:** one optional tap on another plot gives both a small growth boost (once per plot per day). Later: lend a guard pet to a
  friend's field for one night.
- **Gifts:** seeds and common crops to a friend, capped per day (no pets, no variants; alt accounts must not become a faucet).
- **Invites:** the Roblox invite prompt with a reward when an invited friend joins (check Creator Rewards' current terms for new / lapsed players).
- Trading stays open (§16).

## 11. Collector layer
A **field guide** over trait and harvest data: kinds, aptitudes, coats, quirks, crops × variants, size records, fair ribbons, critters (the
pet catalog reuses `SeenKinds`, GDD §7). **Wandering strays** arrive at the gate for a limited time with their traits visible: adopt on sight
instead of rolling blind; the main non-random route to pets (whether eggs stay is open, §16). Breeding is deferred (hybrid plants:
HYBRIDS.md); keep the trait set breeding-ready (inherit a main aptitude, mutate a quirk).

## 12. Long-term goals: what money and rare seeds are for
Until the landmarks / estate are designed, the economy model keeps a reserved sink ladder (×1.15 steps) so the late game never runs dry; rebirth
is not planned for launch (a soft "Replant" only if the queue empties, ECONOMY.md → Decisions).

**Island restoration (the spine).** Overgrown landmarks on the garden island, restored by **bundles** of five kinds of input: Coins, common
crops, one rare crop, a pet-skill requirement (e.g. a Weeding pet of level 4+), and for some an obby achievement or a mini-game (§8.3). Money is
one input of five, so every play style feeds the goal. First sketch (finite; fix the first 6–8 before E6; landmark → what it unlocks, bundle
sketch): Kitchen (Kitchen station; Coins, tier-1 crops, a Big crop) · Old mill (Mill; Coins, wheat, a Crafting pet, the Gear Puzzle) ·
Greenhouse (growing in any season; tier-2 crops, a world-1 rare crop) · Pond (water crops, fishing; a Fertilising pet) · Orchard (big 2×2
trees; saplings, a world-2 rare crop) · Watchtower (longer forecast, +1 field pet slot; a Pest-control pet of level 4+, Gold on a world-2
stage) · Training grounds (aptitude XP +25 % provisional; a pet with 2 aptitudes at level 3+) · Nursery (choose between hatched strays; 5
pets in the field guide) · Observatory (whole-day forecast, seasonal events; rare crops of three worlds, a Starlit crop).

**Estate tiers:** Patch → Homestead → Estate → Grand Garden, each a visible overhaul others see on the plot ring. A **cottage** with fixed rooms
whose shelves fill by themselves (medals, field-guide book, pet portraits, ribbons, giant-crop trophies). **Outdoor decor** placed freely
within a per-tier limit; the server validates bounds, collisions and count; store a compact position + rotation per item.

**Pet mastery** (§4) makes rare seeds gate the best form of a favourite pet. **Garden score** on the plot sign (collection %, restorations,
masteries, likes), visible to visitors, **never ranked** (bought cosmetics would make a ranking pay-to-win).

**Horizons:** session (harvest, request, hatch, set the guards) · day (ledger, forecast, market cart, daily seed, streak) · week (weekly
challenge, fair, next bundle, an aptitude level, the next farm stage) · month+ (season, estate tier, field guide, whole island restored).

## 13. Monetization: sell comfort
GDD §9 follows these rules:
1. **No paid random items.** No eggs for Robux; Coins, seeds, crops and the market cart's offers are never sold or re-rolled for Robux; no Coin packs.
2. **Luck is never sold.** Size and variant chances come only from Coin-bought tools, crafted fertilisers, pets and weather.
3. **Weather is never sold**, for one player or for a server.
4. **Everything that changes the economy is earnable through play and capped** (GDD §9): Robux only reaches it sooner.
5. **The obby stays clean** (fair leaderboards): nothing bought affects a time; a skip gives no time, no medal, no payout and no challenge coin.
6. **Offers appear at a pain point, never on join**, and nothing in the first session: a full field, a long crop still growing, "growth paused
   after 24 h" in the ledger (information, not guilt).

| Motive | Product | Kind |
|---|---|---|
| Idle comfort | **Night shift**: offline rate and cap above the free 1 / 24 h; numbers need a new economy review; never changes online income | game pass |
| Impatience | Instant grow (one square, price by remaining time, daily cap); finish an incubator | developer product |
| Capacity | +1 field pet slot, +1 incubator, the next field squares before their gate (never beyond the earnable maximum) | game pass / product |
| Status | Pet dyes and outfits, decor packs, plot themes, fair-stand decorations, trails, a VIP tag | game pass / product |
| Generosity | A cosmetic gift to a friend (decor, a pet outfit) | developer product |
| Completion | Season pass premium track (§9.4) | product per season |
| Second thoughts | Reset of a crop's upgrade points (after 1.0): moves points, never adds any; also a special event item (rule 4) | developer product |
| First purchase | Starter pack, one time: a decor set, +1 field pet slot, 3 days of Night shift | developer product |
| Obby | Skip a stage / a checkpoint (rule 5) | developer product |

- Prices are placeholders (Robux price points at M7 / D2). 1.0 launches without the comfort shop; D2 is the first drop.
- The economy model gets a **Spender archetype** (Night shift, capacity early, a daily instant grow): paying speeds progress up by a bounded
  factor (provisional ≤ 1.5× per day) and never changes online income.
- Telemetry (TELEMETRY.md) gets purchase and offer events: where an offer was shown, whether it converted.

## 14. MVP and drop plan
**1.0** = the MVP loop (buy seeds, plant, put one pet on the field to tend and one to guard, run an obby for a rare seed, come back to a ledger
of harvests and chased-off crows, upgrade a tool) + a long engagement loop (crop mastery, rotating stall, requests) + basic social competition
(Harvest Hall, plot likes) + player feedback. All of it is built; the state and the release gates live in ROADMAP → Next. After it, **a drop
every 1–2 weeks**; obby drops alternate with garden drops; a drop too big for two weeks (World 4, estate) is split.

**Not in 1.0:** the full critter set, weeds and the forecast board, variants and fertilisers, the comfort shop, Sunshine (EV2c), obby time
calibration (M6b), tonics and the other stations, landmarks, estate / decor / cottage, strays, seasons, trading, World 4.

**Gates before going public** (ROADMAP → Road to 1.0): the first live test (M6a), the Czech text review, the mobile check (MU), the store
thumbnails (TH1 + THU), the Max Players 8 test. A **soft launch** (friends, then unlisted) first; the garden funnel telemetry decides whether
the loop works.

**Drops after 1.0** (order provisional; each about 1–2 weeks; D1–D10 is about 3–5 months)

| Drop | Content | Build stages |
|---|---|---|
| TR "Fruit trees" | Perennial fruit trees on one square: a stall tree and a rare obby tree (§5.4) | E1 |
| D1 "The Critters" | Moles, slugs, raccoons, weeds and Weeding, Pest-control specialities, the forecast board with weather, Scarecrow, Seed chest, full ledger | E4, E9 (weather), E1 |
| D2 "Comfort" | Comfort shop: Night shift, instant grow, starter pack, first cosmetics; Wheelbarrow | M7 |
| D3 "Weekly" | Weekly obby challenge, first farm stage and its crop, Harvest Fair (grows from the Harvest Hall), streak calendar | E10, E2 |
| D4 "Variants" | Compost station, Frost and Gold-leaf fertilisers, Frosted / Golden variants, Fertilising and Crafting working, Lucky quirk, field-guide records | E9, E5 |
| D5 "The Kitchen" | First landmark (Kitchen), first mini-game gate (puzzle room) | E6, E5 |
| D6 "Neighbours" | Friend bonus, help a neighbour, gifts, invites | E11 |
| D7 "Pet depth" | Pet mastery: quirks shown, field guide in full, tonics for aptitude levels 7+, other stations | E3, E5 |
| D8 "World 4" | Obby World 4 (S9–S10), second farm stage, night fertiliser and Starlit, more landmarks (split) | S, E2, E6, E9 |
| D9 "The Estate" | Estate tiers, outdoor decor, cottage, garden score (split) | E7 |
| D10 "Season 1" | First season and pass, strays, weekly visitor at the market cart | E10, E8 |

## 15. Build stages (progressive reveal; each stage ships alone)
E0 economy model (per drop; partial) · E1 field, crops, market cart, tools, field pets (built for 1.0) · E2 obby seed links (built), species
unlocks, farm stages (D3 / D8) · E3 quirks, field guide, aptitude UI (D7) · E4 critters, weeds, forecast board, Scarecrow (crows built; D1) ·
E5 request board and join ledger (built), stations, tonics (D4 / D5 / D7) · E6 restoration bundles, mini-game gates (D5 / D8) · E7 estate, decor,
cottage, garden score (D9) · E8 strays, weekly visitor (D10) · E9 weather, fertilisers, variants (D1 / D4 / D7 / D8) · E10 weekly challenge,
Harvest Fair, streak, seasons (D3 / D10) · E11 social (D6) · M7 comfort shop (D2).

## 16. Risks and open questions
**Open decisions for the user**
1. **Coin eggs:** keep the Coin incubators (no Robux eggs, decided) or remove eggs and make strays the only pet source? Instant grow sells time
   that becomes Coins: check the current Roblox paid-random-items rules before D2.
2. **Farm stages:** bonus stages outside the unlock chain (recommended) or numbered world stages (§8.2).
3. **Trading:** the strongest retention driver in pet games, but dupes, scams and moderation; plan for it or rule it out.
4. **Numbers:** variant chances and fertiliser recipes, Night shift values, weather cadence, friend bonus; all go through the economy model.
5. **Field pets from far away:** place / move field pets from the Pets panel anywhere (recommended; the "who guards tonight" choice often comes
   during an obby session), planting and harvesting stay on the plot.
6. **Aptitudes:** whether levels 7+ need tonics; several field jobs at once (§3).

**Plot architecture (built).** Clients draw nearby plots from server data, so player capacity is not tied to prebuilt scene plots
(`GardenPlotFeed`, [PROTOCOL](PROTOCOL.md)). Capacity targets 24 players at the planning stage; increasing it requires a fresh field budget
test. Real-phone performance and a 12-client join remain open.
- **Offline visits (designed, not built):** show a lightweight saved garden, up to five minutes old, including when its owner is on
  another server. [Storage proposal](PROTOCOL.md#planned-offline-garden-visits).

**Risks**
- **Genre overlap with Grow a Garden** (§1.1): check every drop against it; without gambling the excitement comes from skill (obby), defence
  outcomes (the ledger) and earned rarities.
- **Onboarding:** the first ten minutes show one loop (buy seeds, plant, put a guard on the field, run a stage, come back to a ledger); field
  pets, aptitudes and tools are revealed gradually.
- **Content volume and the 1–2 week pace:** every crop, variant, quirk, critter and landmark needs English and Czech and Studio-only art.
- **Luck inflation:** size × variant × tools × fertilisers × pets × weather multiply; the expected value must stay inside the targets (§5.5).
- **Forecast fairness:** an unannounced raid feels unfair; the weather schedule must give every time zone its rare kinds.
- **Profile size and save cost** (items, variants, records, fertilisers, quirks, decor, fair entries): compact encodings, watch the DataStore key limit.
- **Free outdoor decor:** placement exploits, per-item save size, collisions with paths and neighbouring plots, mobile controls.
- **Mini-game gates** must stay passable for every player; **gifts and alt accounts:** daily caps, no variant or pet gifts, a friend bonus
  must not reward a parked second account.
