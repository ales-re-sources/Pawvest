# Pawvest — pet-garden simulator expansion design (E1–E11)

Status: **draft, direction decided 2026-10-24, extended 2026-10-25** (seed catalogue and market cart, size roll and earned variants, garden
tools, farm stages, mini-game gates, weather and live events, social, comfort-only monetization, drop plan), then **reworked the same day to
reduce the overlap with Grow a Garden** (§1.1: critters right behind the MVP, earned variants instead of weather mutations, a market cart instead
of timed restocks, own tool names, no paid weather). Brainstorms with the user, nothing built yet.
**Name: Pawvest** (decided 2026-10-24; "Oby sandbox" was the working title; the Studio place, the project and the repository folder are renamed). Store subtitle "Pets · Garden · Obby", tagline "Grow. Guard. Run.". Availability on Roblox
and trademark are still to be checked. Avoid leading with "Grow" / "Garden" (the market leader "Grow a Garden" has pets with abilities). All numbers are
placeholders until the economy model confirms them ([ECONOMY.md](ECONOMY.md), ROADMAP → E0). This document says *what* the next big expansion is; milestones
become ROADMAP entries when they start. It builds on GDD §7 (pets, garden) and does not change the obby.

## 1. Vision and pillars
**Pitch:** *grow things, put your pets on guard, run obbies for rare seeds.*

Today the garden is a vending machine (GDD §7.6: a pet in a pen pays Coins per hour, incubators, a food stand) and a pet is
mechanically a number (rarity bonus + level). The obby is finite content: about an hour today, two with balancing, and players finish
stages faster than they can be built. The goal is a pet and garden game in which **systems** (crops growing, critters at the fence, the
forecast, weekly events) give a reason to come back, pets stay unique (they differ in *what they can do*, not in how big their number is), and the
obby and mini-games supply the garden with what it cannot make.

| Pillar | Meaning |
|---|---|
| Pets are characters | Traits, quirks and careers; the only pure number stays the +50 % Coin multiplier cap |
| One pet, one post | A pet is in one place at a time; allocation is the game |
| The garden is a place | It grows while you are away, is attacked while you are away, and visibly evolves |
| The obby is the expedition | A skilful run brings back things the garden cannot make |
| Earned, not rolled | Rare results (variants, rare crops, pets' best forms) come from what the player did: obby runs, crafting, pet careers; never from a slot machine |
| Coins buy verbs and looks | Coins unlock tools, abilities and a visible estate, never just a bigger number |
| Robux buys comfort | Time, capacity reached sooner, convenience and cosmetics; never luck, never a random item, never weather (§13) |

**Change to GDD pillar 2:** "slow or idle sources are a steady trickle, never the fastest route" becomes: the garden is the
main *passive* source and a developed garden out-earns a lazy obby day, but it never beats an active obby hour at the same
progress, and the best crops are only reachable through the obby. Pillar 3 (fair leaderboards) is unchanged: pets, tools and
anything bought never touch movement or stage times. **GDD §9** follows §13: no Coin packs, no Robux eggs.

### 1.1 Not another Grow a Garden
Pawvest shares a proven genre loop (plant, wait, harvest, sell, upgrade) with the market leader. Sharing the loop is normal on Roblox; sharing
*only* the loop is the danger: next to a much bigger game we lose on every axis we share, a "ripoff" reputation sticks, and Grow a Garden's
excitement comes from gambling (eggs, paid restocks, rare pet rolls) that Pawvest rules out. Rules (reviewed 2026-10-25):
- **Lead with what is ours.** The first ten minutes, the store page and the thumbnail show the obby, pets on guard and critters at the fence;
  planting and selling are the frame, not the hook. The critters come right behind the MVP, with a thin version inside it (§14).
- **Avoid the leader's signature mechanics:** no seed shop restocking every few minutes (a daily **market cart** instead, §5.2), no random
  weather mutations (variants are **earned**, §5.3), no buying weather for a server (§13), no gear named like theirs (sprinklers, trowels, §6).
- **Our weather serves the defence:** it drives the forecast of critter visits (§7, §9.1), not a mutation lottery.
- **Size is social:** the size roll feeds a weekly Harvest Fair (§9.3), not only a number.
- Every drop is checked against this list before it ships (§16).

| Ours, nowhere else in the genre | Shared with the genre, kept as the frame |
|---|---|
| The obby as the expedition (skill earns rare seeds), farm stages | Plant, wait, harvest, sell |
| Pets as characters with posts, careers and quirks | Crop tiers and a seed catalogue |
| Critter defence with a forecast | Crop size |
| Earned variants (crafted fertilisers, pet careers) | Growth upgrades |
| Island restoration bundles, no gambling at all | Visiting other plots |

## 2. Decided
| Topic | Decision |
|---|---|
| Core | Farm-sim garden + guardian defence. Collector is a by-product (field guide over trait and harvest data, strays later) |
| Expeditions | Pets are **not** sent away (they would duplicate the farm's timers); the obby is the expedition |
| Pet identity | Traits + careers; breeding is out for now but the trait set must stay breeding-ready |
| Raids | Offline only, resolved by the server, reported in a ledger. No active shoo mode, no PvP |
| Garden loop | No chores (no watering); ripe crops wait |
| Unifying rule | One pet, one post. Existing pens become posts |
| Long goals | Island restoration bundles, estate tiers + cottage, pet mastery, garden score — all four |
| Decoration | Free placement **outside only**, per-tier limit, validated on the server; the cottage is fixed |
| Field (2026-10-24) | One field of squares the player plants freely, instead of fixed beds; capacity grows by field expansion tiers; **decided 2026-10-25 (E0): 12 squares at ladder scale ~0.3** (the 24-hour rule limits squares × scale), so a plot draws at most 12 squares |
| Garden vs obby (2026-10-24) | **24-hour rule:** one active obby hour (mini-games count) ≈ 24 hours of fully automated planting at the same progress; checked by the E0 model (ROADMAP → E0) |
| Online vs offline (2026-10-24) | Offline income must exist, but **online income, even passive, is much higher**, to give players a reason to keep Roblox open. A parameter pair `online_rate` 1.0 / `offline_rate` (provisional 0.33, about 3x; the number is an open decision) applies to everything passive: crop growth, Gardener replanting, pen production; offline time is capped (pens 8 h, field its own cap, provisional 12 h). The 24-hour rule is checked for the online case (offline can only be lower). Not a Roblox payout (Engagement-Based Payouts ended 2025-07-24; Creator Rewards pays per Active Spender) and never pure AFK: income depends on the player being present |
| Prices (2026-10-24) | E0 also re-prices all sinks (talents, unlocks, slots, eggs, incubators, posts, food, field expansion and upgrades, tools); applied in E0b after approval |
| Differentiation (2026-10-25) | §1.1: lead with obby, pets on guard and critters; avoid the leader's signature mechanics (timed restocks, weather mutations, paid weather, its gear names) |
| Seed shop (2026-10-25) | A fixed **catalogue** gated by Renown and obby unlocks, plus a **market cart** with daily offers (same on every server, per-player quantities) and later a weekly visitor. Rare seeds are never sold (§5.2) |
| Harvest rolls (2026-10-25) | Every harvest rolls a **size** (weight). **Variants** (Frosted, Golden, Starlit…) are **earned**: crafted fertilisers made from rare crops and pet traits / careers give the chance, weather only adds a bonus; rolled on the server, deterministic per planting (§5.3) |
| Garden tools (2026-10-25) | A second upgrade tree beside the obby skills, bought with Coins and gated by Renown: size, growth, yield, comfort, defence; **no tool raises variant chance** (that comes from fertilisers and pets) (§6) |
| Critters first (2026-10-25) | A thin critter loop (crows, one Perimeter post, the forecast line) is in the MVP; the full critters are the first drop (§7, §14) |
| Farm stages (2026-10-25) | Obby stages themed on the farm; each owns one unique rare crop whose seeds come only from that stage (§8.2) |
| Mini-game gates (2026-10-25) | Mini-games may gate content, but only by **completion**, never by time or skill ceiling (§8.3) |
| Monetization (2026-10-25) | **No paid random items** (no eggs for Robux, Coins / seeds / crops / cart stock are never sold for Robux, no Coin packs), **luck is never sold**, **weather is never sold**. Robux buys comfort (§13) |
| Live ops (2026-10-25) | A drop every **1–2 weeks** (the user can ship at that pace). Systemic content (forecast, market cart, weekly challenge, fair) before authored seasons (§9, §14) |

## 3. One pet, one post
| Post | What the pet does | Notes |
|---|---|---|
| **Field** | Works the squares (Gardener auto-replant, §5) | Replaces the Coins-per-hour pen |
| **Perimeter** | Guards a side of the garden (§7) | One post in the MVP (thin critters), more with E4 |
| **With you** | Follows you in the obby (today's 3 equipped slots) | Earns Explorer XP; may reveal secret coins, never affects times |
| *(unposted)* | Rests; keeps its bond | |

- The rule generalises today's "equipped XOR penned": `PetService` / `GardenService` already reject the conflicting
  actions; they grow a third state.
- **Migration.** Pen prices (0 / 1 000 / 2 500 / 5 000 / 9 000 / 15 000, GardenConfig) keep their value as post slots. The
  Coins-per-hour production is removed only after crops ship (E1), so live players keep their offline income until then.

## 4. Pet traits and careers
- **Aptitudes** (one main, optionally one minor): Dig, Green thumb, Keen eyes, Brave, Swift, Craft. Three steps, not a decimal
  stat: novice, skilled, master. The pet's *kind* leans (dog → Brave, fox → Keen eyes, owl → night watch); the roll adds variance,
  so two foxes can differ. Rarity decides the number of trait slots and how unusual the quirks are, not raw power.
- **Green thumb does what gadgets do elsewhere:** a Green-thumb pet on the Field post speeds growth on the squares it works (by aptitude
  step), and a **master** Green thumb gives those squares a Golden chance (§5.3). Growth and variants are a reason to raise a pet, not to buy a tool.
- **Quirks** are qualitative and carry a cost. Target about 30; examples:

| Quirk | Effect | Cost |
|---|---|---|
| Light sleeper | Guards at night | Weak by day |
| Digger | Finds a seed when idle | Scatters the square it works |
| Glutton | Food gives extra XP | Nibbles crops |
| Hoarder | Stores overflow harvest | Slower to react to raids |
| Skittish | Spots threats early | Flees a fight |
| Lucky | Small variant chance on the squares it works, even without fertiliser (§5.3) | Lower base yield |
| Greedy | Extra yield | Some crops lost |
| Sleepy | Works well at night only | Idle by day |
| Brave | Holds the line alone | Ignores forecasts |
| Friendly | Bond grows fast | Distracted from work |

- **Careers.** Three XP tracks: **Explorer** (obby runs, with you), **Gardener** (field work), **Guardian** (perimeter). A pet's
  history decides how it evolves and which aptitude steps it can take. The existing visuals carry meaning: the P1f accessories
  and P1e3 tier effects reflect the career (a long-serving guard gets the scarf, a gardener the straw hat).
- **Mastery.** novice → skilled needs career XP; skilled → **master** needs a rare tonic brewed from a rare crop (§8, §12).
- **Bond.** Favourite food, mood and affection. Mood gives only bonuses, never penalties (no guilt-driven check-ins).
- Personal spending: dyes, outfits, names, and a den furnished to the pet's preferences (a fox wants a burrow).
- Data: `Pets[uid]` grows `Aptitude`, `Quirks`, `CareerXP = { Explorer, Gardener, Guardian }`, `Bond`, `Post`; PetLook already
  derives individuality from the uid, the same seeding gives the traits at hatch.

## 5. Crop economy
Coins stay the one currency. The profit loop: **buy seeds → plant → harvest → sell → buy better seeds and tools** (§6), with pets on the
field and the fence deciding how well it runs. Harvests are **items** (`Garden.Items[crop] = n`, a small table in the profile; a variant or
record-size item is kept apart, §5.3) with four uses: sell (through `CoinRewards.Grant`, so the pet bonus applies at sale time), process at
a station (about 1.5–2× the raw value), turn in on the request board or in a restoration bundle, replant as seed stock.

### 5.1 Field loop (no chores)
- A square holds one crop. A ripe crop waits and never rots; raids are the risk (§7).
- A square gives **one harvest per visit**, then stays empty. A **Gardener pet on the Field post auto-replants** from the seed stock
  while the player is away, so the square keeps cycling for as long as there are seeds. The pet matters through a capability, not a percentage.
- Output is limited by squares, seed stock, Gardener posts and the online / offline rates (§2).
- **Grow times match real-life gaps** (a quick crop for a short session, 1 h for lunch, 8–12 h for the night), so "what do I plant before I
  leave, and who guards it?" is the decision at the end of every session.
- Quirks bend the loop (Lucky, Greedy, Sleepy, Digger above).

### 5.2 Seed catalogue and market cart
- **Catalogue:** every unlocked species of tiers 1–3 can be bought at a fixed price, any time; Renown and obby first finishes unlock species (§8.1).
  There is no timed restock and no shared stock to race for.
- **Market cart:** a cart at the plot ring with **daily offers** (from the UTC day, the same on every server): 3–5 items such as discounted seeds,
  a species the player has not unlocked yet (a taste before the unlock), a fertiliser ingredient, a decor piece. Quantities are **per player**,
  so nobody misses out to a faster neighbour. A reason to look in once a day, not every five minutes.
- **Weekly visitor** (E8): a travelling merchant with an exotic or seasonal species for the week.
- The cart's offers are never sold or re-rolled for Robux (a paid re-roll would be a paid random draw, §13).
- **Rare seeds are never sold:** world signature crops and farm-stage crops come only from the obby (§8).
- Seed cost is 20–30 % of the sale price (the ladder below is net of it).

### 5.3 Harvest rolls: size and earned variants
Every harvest rolls on the server, with a seed derived from `(UserId, square, plantedAt)`, so reloading or rejoining cannot reroll it
(the same approach as the raid timeline, §7). The Gardener's offline harvests roll too and appear in the ledger.

- **Size (weight).** A continuous roll with a long tail: "Pumpkin, 41.2 kg". Sale value scales with the size factor; its expected value
  is 1.0 with no tools, so the ladder holds. Labels: normal, Big, **Giant** (top few %). The field guide keeps the **personal best per crop**,
  giants can enter the weekly **Harvest Fair** (§9.3) or stay as a yard trophy (E7) instead of being sold.
- **Variants are earned, not rolled from the sky.** A variant is worth several times the normal crop (provisional ×2–5) and is an entry in
  the field guide (§11). A crop can only become a variant if something the player did gives it a chance:

| Variant | Source of the chance | Bonus | Value (provisional) |
|---|---|---|---|
| Frosted | Frost fertiliser on the square (brewed from the ice world's rare crop) | higher during Frost weather | ×2 |
| Golden | Gold-leaf fertiliser (from a farm-stage crop) or a master Green-thumb pet working the square | – | ×5 |
| Starlit | Night fertiliser (from a world-3 rare crop) | only ripens Starlit during an Aurora | ×3 |
| any | Lucky quirk pet on the square (small chance, no fertiliser needed) | – | as the variant |

- **Fertilisers** are crafted at the Compost station (§5.6) from rare crops plus common ones and applied to one square for its next crop:
  a new sink for rare crops, and a reason to run the obby stage that supplies the ingredient.
- Size and variant stack. The expected value of size × variant, with tools, fertilisers and pets maxed, is part of the ladder in the E0 model:
  it must not break the 24-hour rule.

### 5.4 Value ladder (provisional)

| Tier | Gate | Example crops (grow time) | Net Coins per square-hour |
|---|---|---|---|
| 1 | start | Radish 20 min, Carrot 1 h, Potato 3 h | about 20 |
| 2 | Renown 5 | Corn 6 h, Pumpkin 8 h | about 45 |
| 3 | Renown 12 | Giant melon 12 h | about 90 |
| Rare | obby only | one signature crop per world, one per farm stage | about 150 |

*E0 re-scaled this ladder (2026-10-25, [ECONOMY.md](ECONOMY.md)): × 0.3, i.e. about 6 / 13.5 / 27 / 45 net per square-hour, Renown gates 8 / 25, a field of 12 squares; the old casual estimate is superseded by the E0 model.*

### 5.5 Guardrails
To hold after every rebalance, like GDD §6 (checked by `tools/economy.py check`, ECONOMY.md):
- Early garden income per day stays below the obby's first-hour income.
- Rare crops pay the most and only the obby unlocks them.
- Seeds, squares, tools, fertilisers, stations, barn size, decor and bundles absorb a fixed share of the faucet (no inflation).
- A developed garden is the main passive income but never beats an active obby hour at the same progress, with tools maxed and harvest rolls at their expected value.
- Comfort purchases (§13) speed progress up by a bounded factor and never change the online ceiling of the 24-hour rule.

### 5.6 Renown, requests, stations
**Renown** is a derived garden level (harvests, requests, restorations, fair entries); it gates seed tiers, squares, tools and stations and is never spent.
**Request board:** three requests a day ("6 carrots + 2 flour"; sometimes "a Big pumpkin" or "a Frosted carrot"), paying Coins, a rare item and Renown.
**Stations** (queues with timers; Craft pets run them): Compost (fertilisers for growth and variants, §5.3; the first station, with the variants),
Mill (grain → flour), Kitchen (crops → pet food, a cheaper route to levels than Berry / Cake / Feast), Workshop (decor, plot upgrades),
Apothecary (tonics, mastery items).

## 6. Garden tools
A second upgrade tree beside the obby skills (`TalentService` pattern: levels, a price per level, a panel like the Skills panel), bought
with **Coins only** and gated by Renown. Tools are the garden's main progression sink (ECONOMY open decision 1 needs one) and never touch
the obby. Names are our own (no sprinklers or trowels, §1.1); effects are bounded; numbers are placeholders for E0.

| Tool | Raises | Axis | Ships |
|---|---|---|---|
| Seed sorter | the size roll (picks the best seeds: expected value up to about +15 %, a longer tail) | Size | MVP |
| Cloches | growth speed **while the owner is online** (up to about +20 %; nothing offline) | Speed | MVP |
| Pruning shears | chance of a second item per harvest | Yield | MVP |
| Seed chest | seed stock and storage capacity (Gardener auto-replant runs longer) | Comfort | D1 |
| Wheelbarrow | harvest every ripe square with one prompt | Comfort | D2 |
| Scarecrow | raid defence on one side (§7), weaker than a posted pet | Defence | D1 |

- **No tool raises variant chance:** variants come from fertilisers and pets (§5.3). Growth beyond the Cloches comes from Green-thumb pets (§4).
- Data: `Garden.Tools[id] = level` in the profile.
- No tool and no tool level is ever sold for Robux (§13).
- E0 models the tool tree (prices, levels, the maxed case against the 24-hour rule).

## 7. Critters and raids
The defence loop is Pawvest's strongest hook (§1.1). Critters raid the garden while the player is away; not other players.
- **Forecast board** shows the coming weather and visitors together ("rain tonight: slugs likely; crows at dawn"). It is the reason to
  look before leaving: the player assigns guards with the forecast in front of them.
- **Weather drives critters** (§9.1): rain brings slugs and moles, a dry spell brings crows, frost keeps most critters away, a clear night
  brings raccoons.
- **Counters** (composition matters, not strength):

| Critter | Targets | Counter |
|---|---|---|
| Crows | ripe crops | Keen eyes |
| Moles | growing crops (roots) | Dig |
| Slugs | leaves, many small bites | many hands |
| Raccoons | stored goods, at night | night watch |
| Locust swarm (weekly) | everything | wide coverage |

- **MVP (thin):** crows only, one Perimeter post, the forecast as one line on the board and in the ledger. Enough to show "pets on guard"
  in the first sessions; the full set, the board and more posts are drop D1.
- **Resolution** is deterministic on join: each square is a timeline of events, critter visits and rare drops are seeded by
  `(UserId, day, index)`, so reloading or rejoining cannot reroll them. Test with the incubators' clock trick (move stored times back).
- **Losses are soft:** some crops or Coins, never pets, never a variant or a trophy. The GDD's "welcome back" popup grows into a **ledger** of
  the absence: raids ("Rex chased off 3 crows. Slugs ate 2 carrots."), harvests and their rolls, finished station queues, strays at the gate.
- The Scarecrow tool (§6) is a Coin-bought counter for one side, weaker than a posted pet.
- Unresolved: loss caps per raid and how much a perfect defence earns (§16).

## 8. Obby, farm stages and mini-games
### 8.1 Obby links
- **Species unlocks (seed catalogue).** First finish / first Gold of a stage and challenge-coin milestones unlock crop species in the
  catalogue (§5.2).
- **World signature crops.** Each world has one rare crop (for example an ice melon from the ice-rink world); its seeds come from the
  first Gold of that world's stages and the **daily first-run seed** (the first finish of a day gives one rare seed).
- **Rare items come only from the obby.** Rare crops are ingredients for fertilisers and their variants (§5.3), landmarks (§12), tonics
  (pet mastery), unique products (a night-watch tonic, a critter repellent) and trophies.
- Pets never touch times or movement; an Explorer pet may only reveal secret coins.

### 8.2 Farm stages
Obby stages themed on the farm (greenhouse, scarecrow field, orchard canopy, barn loft…), built from the existing kit (STAGES.md §2).
Each farm stage **owns one unique rare crop**:
- the first finish unlocks the species and gives a few seeds; the first Gold gives more; the daily first run of that stage gives one;
- its seeds are never sold, so every new farm stage is also a garden update (obby drops and garden drops feed each other);
- the crop is the ingredient of a specific fertiliser, landmark, tonic or request (the first farm stage supplies the Gold-leaf fertiliser),
  so each farm stage has a visible purpose in the garden.

Open: farm stages as **bonus stages** outside the unlock chain (STAGES.md §5.3; reachable from the garden island, so garden-first players
find them; recommended) or as numbered stages in the worlds. Times and medals follow GDD §4 like any stage.

### 8.3 Mini-games as gates
Mini-games (puzzle rooms like the Laser Lab prototype `Workspace.KeyArena`, garden-side games) may unlock content, under one rule:
**a gate tests completion, never speed or skill ceiling**, so a garden-first player cannot get stuck. A gate shows a hint, is retryable
without cost, and stays replayable afterwards for a small daily reward.

| Use | Example |
|---|---|
| Restoration bundle input (§12) | Old mill: Coins + wheat + a Craft pet + clear the Gear Puzzle |
| One-time unlock | A puzzle room opens a seed tier or a station |
| Repeatable source | Fishing at the Pond (after its restoration), a harvest rush; short, counts as active time in the 24-hour rule |

Each mini-game is 1–3 minutes (GDD pillar 1) and passes the mobile check (ROADMAP → MU).

## 9. Weather and live events
### 9.1 Weather
- A schedule **derived from the UTC clock**, the same on every server, shown on the forecast board ahead of time (§7). Provisional: a
  weather change every few hours, so a forecast covers the player's absence; rare kinds (Aurora) rotate through the day so every time zone gets them.
- **What weather does:** it decides the coming critters (§7), gives small growth bonuses to present players (Rain: faster growth while the
  owner is online), and raises the chance of a variant **that a fertiliser already made possible** (Frost for Frosted, Aurora for Starlit, §5.3).
  Weather alone never turns a crop into a variant.
- Art: a sky / lighting preset and particles per kind; no new models.
- **Weather is never sold** (§13).

### 9.2 Weekly obby challenge
- One existing stage per week with a **modifier** from the kit (low gravity and wind from `KitZones`, no checkpoints, a ghost of last week's #1),
  chosen by a fixed rotation.
- A **weekly Top-10** that resets every Monday 00:00 UTC (new `GlobalLeaderboardsStore` keys per week), so new players can top a board.
- Rewards: a finish gives a rare seed; the weekly Top-10 gets a cosmetic trophy for the yard. Pillar 3 holds: same talent and pet rules.
- It turns the finished stages into a renewable resource and gives obby players a weekly reason to return.

### 9.3 Harvest Fair
- A weekly prize-vegetable fair at the hub: each player may enter one crop per category (the category rotates: pumpkin, melon, a farm-stage crop…).
- Ranking by size factor (so every crop tier can compete); results at the end of the week, the top entries get a ribbon trophy for the yard,
  every entrant gets Renown. The entered crop is kept (shown at the fair stand), not lost.
- Size has a social stage without a gamble: the roll is free, the Seed sorter and the choice of what to enter are the skill.
- Tools and pets are earned with Coins and play only, so the fair is not pay-to-win (§13 rule 2).

### 9.4 Seasons
- 4–6 weeks each: a theme, 3–4 seasonal crops, one seasonal pet kind (adopted, not hatched from a paid egg), a decor set, a seasonal farm
  stage or challenge, a seasonal critter.
- A **season pass** with a free and a premium track (§13), fed by season XP from everything (harvests, runs, requests, defence, mini-games).
- Starts only after the forecast, the market cart, the weekly challenge and the fair run without attention (the weeks between drops stay alive).

### 9.5 Streak calendar
A 7-day loop of small rewards; a missed day **pauses** the streak instead of resetting it (no guilt, like pet mood).

## 10. Social
- **Friend bonus:** a small bonus on harvest sales while a friend is on the same server (provisional +10 %, outside the pet multiplier cap; in E0).
- **Visits and likes:** the plot ring is walkable; a like on another plot feeds its garden score (once per plot per day).
- **Help a neighbour:** one optional tap on another player's plot gives both a small growth boost (once per plot per day; not a chore).
  Later: lend a guard pet to a friend's fence for one night (fits "one pet, one post").
- **Gifts:** seeds and common crops to a friend, capped per day (no pets, no variants; alt accounts must not become a faucet).
- **Invites:** the Roblox invite prompt with a reward when an invited friend joins. Creator Rewards also pays for bringing new and lapsed
  players (to be verified against the current terms), so return mechanics are a revenue line in themselves.
- Trading (P3) stays open (§16).

## 11. Collector layer
A **field guide** over trait and harvest data: kinds, aptitudes, coats, quirks, crops × variants, size records, fair ribbons, critters. **Wandering strays**
arrive at the gate for a limited time with their traits visible: adopt on sight instead of rolling blind; they are the main non-random
route to pets (whether eggs stay is open, §16). Breeding is deferred; keep the trait set breeding-ready (inherit a main aptitude, mutate a quirk).

## 12. Long-term goals: what money and rare seeds are for
Money is not the goal; it is one input into goals the player can see.

**Island restoration (the spine).** The garden island has overgrown landmarks, restored by **bundles** of five kinds of input: Coins,
common crops, one rare crop, a pet-skill requirement (for example a skilled Digger), and for some an obby achievement or a mini-game
completion (§8.3). Money is one input out of five, so every play style feeds the goal. First sketch (finite, authorable, shipped one at a time):

| Landmark | Unlocks | Bundle sketch |
|---|---|---|
| Kitchen | Kitchen station (takes over the food stand's role) | Coins, tier-1 crops, a Big crop |
| Old mill | Mill station | Coins, wheat, a Craft pet, the Gear Puzzle |
| Greenhouse | growing in any season | Coins, tier-2 crops, a rare crop of world 1 |
| Pond | water crops, fishing mini-game | Coins, a Green thumb pet |
| Orchard | perennial trees | Coins, saplings (tier 3), a rare crop of world 2 |
| Watchtower | longer forecast, +1 Perimeter post | Coins, a skilled Keen-eyes pet, Gold on a world-2 stage |
| Training grounds | career steps to skilled | Coins, a pet with 2 careers started |
| Nursery | choose between hatched strays | Coins, rare crop, 5 pets in the field guide |
| Observatory | forecast for the whole day, seasonal event access | Coins, rare crops of three worlds, a Starlit crop |

**Estate tiers:** Patch → Homestead → Estate → Grand Garden, each a visible overhaul that other players see when they walk the plot
ring. A **cottage** with fixed rooms whose shelves fill by themselves (medals, field-guide book, pet portraits, fair ribbons, giant-crop trophies). **Outdoor decor** is
placed freely within a per-tier limit; the server validates bounds, collisions and count; store a compact position + rotation per item.

**Pet mastery** (§4) makes rare seeds gate the best form of a favourite pet. **Garden score** on the plot sign sums collection %,
restorations, masteries and likes, visible to visitors; it is **not ranked** on a board (bought cosmetics would make a ranking pay-to-win).

**Horizons:** session (harvest and its rolls, request, hatch, set the guards) · day (ledger, forecast, market cart, daily seed, streak) · week (weekly
challenge, Harvest Fair, next bundle, a pet rank-up, the next farm stage) · month+ (season, estate tier, field guide complete, whole island restored).

## 13. Monetization: sell comfort
Decided 2026-10-25 (GDD §9 follows it):
1. **No paid random items.** No eggs for Robux; Coins, seeds, crops and the market cart's offers are never sold or re-rolled for Robux (so Coin
   eggs never become paid random items through bought Coins); no Coin packs.
2. **Luck is never sold.** Size and variant chances come only from Coin-bought tools, crafted fertilisers, pets and weather.
3. **Weather is never sold**, for one player or for a server.
4. **Everything that changes the economy is earnable through play and capped** (GDD §9): Robux only reaches it sooner.
5. **The obby stays clean** (pillar 3): nothing bought affects a time; a skip gives no time, no medal, no payout and no challenge coin.
6. **Offers appear at a pain point, never on join**, and nothing in the first session: a full field, a long crop still growing, the ledger's
   "growth paused after 12 h" (shown as information, not guilt).

| Motive | Product | Kind |
|---|---|---|
| Idle comfort | **Night shift**: offline rate 0.33 → 0.5 and offline cap 12 → 24 h (provisional); never changes online income | game pass |
| Impatience | Instant grow (one square, price by remaining time, daily cap); finish an incubator | developer product |
| Capacity | +1 post, +1 incubator, the next field squares reached before their Renown / Coin gate (never beyond the earnable maximum) | game pass / product |
| Status | Pet dyes and outfits, decor packs, plot themes, fair-stand decorations, trails, a VIP tag | game pass / product |
| Generosity | A cosmetic gift to a friend (decor, a pet outfit) | developer product |
| Completion | Season pass premium track (§9.4) | product per season |
| First purchase | Starter pack, one time: a decor set, +1 post, 3 days of Night shift | developer product |
| Obby | Skip a stage / a checkpoint (rule 5) | developer product |

- Prices are placeholders (Robux price points are set at M7 / D2).
- E0 gets a **Spender archetype** (Night shift, capacity early, a daily instant grow) to check that paying speeds progress up by a bounded
  factor (provisional ≤ 1.5× per day) and that the 24-hour rule's online ceiling is unchanged.
- Telemetry (TELEMETRY.md) gets purchase and offer events: where an offer was shown, whether it converted.

## 14. MVP and drop plan
The MVP is the smallest build that shows the whole loop (buy seeds, plant, post a pet on the field and one on the fence, run an obby for a rare
seed, come back to a ledger of harvests and chased-off crows, upgrade a tool) and is worth opening to the public. After it, **a drop every
1–2 weeks**; obby drops alternate with garden drops; a drop that is too big for two weeks (World 4, estate) is split.

**Already built (comes with the MVP):** obby World 1 and World 2 (World 3 is built too; holding it back as a first content drop is an option),
pets, incubators, food, talents, telemetry, English / Czech localization.

**New in the MVP**
1. **E1** field and crops: about six crops in tiers 1–2, the seed catalogue and the daily market cart, selling, the size roll, light Renown,
   pens renamed posts, Gardener auto-replant for Green-thumb pets only; tools tier 1 (Seed sorter, Cloches, Pruning shears).
2. **E4 (thin)** critters: crows, one Perimeter post, the forecast line, crows in the ledger (§7).
3. **E2** obby links: at least two rare crops (one from World 1, one from World 2) and the daily first-run seed.
4. **Traits rolled at hatch, only the working ones shown.** The full trait data (aptitude, quirks, career XP) is stored from the first hatch, the
   UI shows only what already does something (Keen eyes against crows, Green thumb on the field), so no live pet needs a retroactive roll later.
5. **Request board** (three daily requests) as the first goal beyond Coins and tools.
6. **Basic ledger on join** (harvests and their sizes, crows, eggs ready).
7. **Onboarding** for the first ten minutes (plant, post a guard, run a stage, come back) and telemetry for the garden funnel (extends TELEMETRY.md).

**Not in the MVP:** the full critter set and the forecast board, variants and fertilisers, the comfort shop, mastery tonics and the other
stations, landmarks, estate tiers / decor / cottage, strays, seasons, trading (P3), obby World 4.

**Gates before going public** (existing roadmap items): the first live test (M6a) and the balancing pass, the Czech text review, the mobile layout
check (MU), the comfort shop (D2) or a decision to launch without it. A **soft launch** (friends, then unlisted) comes first; the garden
funnel telemetry decides whether the loop works.

**Drops after the MVP** (order provisional; each about 1–2 weeks)

| Drop | Content | Build stages | Why here |
|---|---|---|---|
| D1 "The Critters" | Moles, slugs, raccoons, the forecast board with weather, more Perimeter posts, Scarecrow, Seed chest, full ledger | E4, E9 (weather), E1 | The hook that is ours (§1.1), right away |
| D2 "Comfort" | Comfort shop: Night shift, instant grow, starter pack, first cosmetics; Wheelbarrow | M7 | Monetization once the loop is proven |
| D3 "Weekly" | Weekly obby challenge, first farm stage and its crop, Harvest Fair, streak calendar | E10, E2 | Obby drop; renewable obby content; size gets its stage |
| D4 "Variants" | Compost station, Frost and Gold-leaf fertilisers, Frosted / Golden variants, Lucky quirk shown, field-guide records | E9, E5 | Earned variants tie the obby to the garden |
| D5 "The Kitchen" | First landmark (Kitchen), first mini-game gate (puzzle room) | E6, E5 | The first long goal |
| D6 "Neighbours" | Friend bonus, likes, help a neighbour, gifts, invites | E11 | Growth through friends |
| D7 "Mastery" | Traits shown, careers, field guide in full, mastery tonics, master Green thumb (Golden), other stations | E3, E5 | Pets get depth |
| D8 "World 4" | Obby World 4 (S9–S10), second farm stage, night fertiliser and Starlit, more landmarks (split) | S, E2, E6, E9 | Obby players and goal-chasers |
| D9 "The Estate" | Estate tiers, outdoor decor, cottage, garden score (split) | E7 | Visible personalization |
| D10 "Season 1" | First season and pass, strays, weekly visitor at the market cart | E10, E8 | Calendar-driven return |

At the stated pace D1–D10 is about 3–5 months after the MVP.

## 15. Build stages (progressive reveal; each stage ships alone)
| Stage | Content | Ships in |
|---|---|---|
| E0 | Economy model (`tools/economy.py`) against GDD §6; fixes the ladder, seed prices, sink share; later adds harvest rolls, fertilisers, tools, the Spender archetype | before the MVP, extended per drop |
| E1.0 | Spike: client-drawn plots, GO / NO-GO on the plot architecture (§16; ROADMAP → E1.0) | before E1 |
| E1 | Field of squares, crops, stock, sell, seed catalogue + daily market cart, size roll, Renown, tools; pens renamed posts (Field only); minimal Green-thumb Gardener | MVP / D1 / D2 |
| E2 | Obby seed links (species unlocks, daily seed, world signature crops), farm stages and their crops | MVP / D3 / D8 |
| E3 | Traits, quirks, careers, field guide (data and hatch roll in the MVP, full UI in D7) | MVP / D7 |
| E4 | Critters, forecast board, offline raids, ledger, Perimeter posts, Scarecrow (thin version in the MVP) | MVP / D1 |
| E5 | Request board (MVP), stations (Compost first), mastery tonics | MVP / D4 / D5 / D7 |
| E6 | Island restoration bundles and landmark abilities, mini-game gates | D5 / D8 |
| E7 | Estate tiers, outdoor decor, cottage shelves, garden score | D9 |
| E8 | Strays, weekly visitor | D10 |
| E9 | Weather schedule (D1, with the forecast), fertilisers and earned variants (D4, D7, D8) | D1 / D4 / D7 / D8 |
| E10 | Weekly obby challenge, Harvest Fair, streak calendar, seasons and the season pass | D3 / D10 |
| E11 | Social: friend bonus, likes, help a neighbour, gifts, invites | D6 |
| M7 | Comfort shop (§13) | D2 |

## 16. Risks and open questions
**Open decisions for the user**
1. **Coin eggs:** keep the Coin incubators (no Robux eggs, decided) or remove eggs entirely and make strays the only pet source? With rule 1 of §13
   Coin eggs are not paid random items, but instant grow sells time that becomes Coins: check the current Roblox paid-random-items rules before D2.
2. **Farm stages:** bonus stages outside the unlock chain (recommended) or numbered world stages (§8.2).
3. **Trading (P3):** the strongest retention driver in pet games, but dupes, scams and moderation; plan for it or rule it out.
4. **Numbers:** size distribution, variant chances and fertiliser recipes, tool levels, Night shift values, weather cadence, friend bonus; all go through E0.

**Risks**
- **Genre overlap with Grow a Garden.** Reviewed 2026-10-25 (§1.1). Check every drop against §1.1 before it ships; the store page and the first ten
  minutes must lead with the obby, pets on guard and critters. Without gambling the excitement has to come from skill (obby), defence outcomes
  (the ledger) and earned rarities; telemetry on the garden funnel shows whether it does.
- **MVP scope.** The thin critters add work to the MVP; keep them to one critter, one post and a text forecast.
- **Onboarding.** The first ten minutes must show one loop: buy seeds, plant, post a guard, run a stage, come back to a ledger. Posts, tools and traits are revealed gradually.
- **Content volume and the 1–2 week pace.** Crops, variants, fertilisers, quirks, critters, landmarks, farm stages: English and Czech (loc workflow), Studio-only art.
  Systemic content (forecast, market cart, weekly challenge, fair) keeps weeks without a drop alive; seasons wait until it does.
- **Luck inflation.** Size × variant × tools × fertilisers × pets × weather multiply; the expected value must stay inside the ladder (E0, §5.5).
- **Weather and forecast fairness.** A raid the forecast did not announce feels unfair: the forecast must be reliable, and the weather schedule
  must give every time zone its rare kinds.
- **Profile size and save cost** (items, variants, size records, fertilisers, tools, traits, decor, fair entries); keep compact encodings, check the DataStore limit per key.
- **Plot architecture (open, raised 2026-10-24).** Today `GardenService` draws pens and pet models as server instances into 12 plots built in
  Studio, and a server holds 12 players. Direction under discussion: the server keeps only data (profile, timestamps, validation) and **each
  client draws the plots it needs from that data**: its own, plus others' within view distance, at lower detail. Plot positions then come from a formula
  (row / column by slot), so the player cap is no longer tied to built plots and the field size is not bounded by a 40 × 40 stud plot. Visits: a live visit
  to an owner on the same server needs only the owner's data; a visit to an offline owner or another server needs a compact snapshot read (to design).
  Alternative: a large walkable city with teleports to key places; that is a layout choice on top of the same drawing model, not a different
  architecture. Decided 2026-10-24: run the spike E1.0 (ROADMAP) before E1: draw one plot from data on the client, measure instance count and cost at the maximum field
  with 24-30 plots in range, check ProximityPrompts / pet followers, and the server-side checks that today use the plot's position.
- **Live players.** What happens to existing pets (traits rolled retroactively from the uid?), pens, eggs and offline income at migration.
- **Free outdoor decor.** Placement exploits, per-item save size, collision with paths and neighbouring plots, mobile controls.
- **Bundles must stay finite.** Fix the first 6–8 landmarks and their contents before E6.
- **Mini-game gates** must stay passable for every player (completion only, mobile check); a gate that blocks garden-first players breaks §8.3.
- **Gifts and alt accounts.** Daily caps, no variant or pet gifts; the friend bonus must not reward a second account parked on the server.
- **Harvest Fair storage.** One entry per player per week and a weekly ranking: a small store per week, like the weekly challenge board.
- **Raids.** Loss caps and the reward for perfect defence; the fairness of a loss the player could not see coming (the forecast must be reliable).
