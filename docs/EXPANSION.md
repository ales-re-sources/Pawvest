# Pawvest — pet-garden simulator expansion design (E1–E11)

Status: **draft, direction decided 2026-10-24, extended 2026-10-25** (seed catalogue and market cart, size roll and earned variants, garden
tools, farm stages, mini-game gates, weather and live events, social, comfort-only monetization, drop plan), then **reworked the same day to
reduce the overlap with Grow a Garden** (§1.1: critters right behind the MVP, earned variants instead of weather mutations, a market cart instead
of timed restocks, own tool names, no paid weather). **Pets and the field reworked 2026-10-30** (§3, §4, §8.1: pets stand on field squares
instead of posts, aptitudes with levels, a seed pouch and a rare-seed meter for stage finishes). Brainstorms with the user, nothing built yet
(the E1.0 plot spike is done, ROADMAP → E1.0).
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
| Pets are characters | Aptitudes, quirks and bond; rarity gives breadth, time gives height (§4); the only pure number stays the +50 % Coin multiplier cap |
| One pet, one place | A pet is in one place at a time (a field square or with you); allocation is the game |
| The garden is a place | It grows while you are away, is attacked while you are away, and visibly evolves |
| The obby is the expedition | A skilful run brings back things the garden cannot make |
| Earned, not rolled | Rare results (variants, rare crops, pets' best forms) come from what the player did: obby runs, crafting, pet aptitudes; never from a slot machine |
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
| Pets as characters with aptitudes, a place on the field and quirks | Crop tiers and a seed catalogue |
| Critter defence with a forecast | Crop size |
| Earned variants (crafted fertilisers, pet aptitudes) | Growth upgrades |
| Island restoration bundles, no gambling at all | Visiting other plots |

## 2. Decided
| Topic | Decision |
|---|---|
| Core | Farm-sim garden + guardian defence. Collector is a by-product (field guide over trait and harvest data, strays later) |
| Expeditions | Pets are **not** sent away (they would duplicate the farm's timers); the obby is the expedition |
| Pet identity | Aptitudes with levels + quirks (§4; careers dropped 2026-10-30); breeding is out for now but the trait set must stay breeding-ready |
| Raids | Offline only, resolved by the server, reported in a ledger. No active shoo mode, no PvP |
| Garden loop | No chores (no watering); ripe crops wait |
| Unifying rule | One pet, one place. **2026-10-30:** pets stand on field squares (no pens, no posts, no Perimeter post), reach by aptitude level (§3) |
| Long goals | Island restoration bundles, estate tiers + cottage, pet mastery, garden score — all four |
| Decoration | Free placement **outside only**, per-tier limit, validated on the server; the cottage is fixed |
| Field (2026-10-24) | One field of squares the player plants freely, instead of fixed beds; capacity grows by field expansion tiers; **decided 2026-10-25 (E0): 12 squares at ladder scale ~0.3** (the 24-hour rule limits squares × scale), so a plot draws at most 12 squares |
| Garden vs obby (2026-10-24) | **24-hour rule:** one active obby hour (mini-games count) ≈ 24 hours of fully automated planting at the same progress; checked by the E0 model (ROADMAP → E0) |
| Online vs offline (2026-10-24) | Offline income must exist, but **online income, even passive, is much higher**, to give players a reason to keep Roblox open. A parameter pair `online_rate` 1.0 / `offline_rate` (provisional 0.33, about 3x; the number is an open decision) applies to everything passive: crop growth, Gardener replanting, pen production; offline time is capped (pens 8 h, field its own cap, provisional 12 h). The 24-hour rule is checked for the online case (offline can only be lower). Not a Roblox payout (Engagement-Based Payouts ended 2025-07-24; Creator Rewards pays per Active Spender) and never pure AFK: income depends on the player being present |
| Prices (2026-10-24) | E0 also re-prices all sinks (talents, unlocks, slots, eggs, incubators, field pet slots, food, field expansion and upgrades, tools); applied in E0b after approval |
| Differentiation (2026-10-25) | §1.1: lead with obby, pets on guard and critters; avoid the leader's signature mechanics (timed restocks, weather mutations, paid weather, its gear names) |
| Seed shop (2026-10-25) | A fixed **catalogue** gated by Renown and obby unlocks, plus a **market cart** with daily offers (same on every server, per-player quantities) and later a weekly visitor. Rare seeds are never sold (§5.2) |
| Harvest rolls (2026-10-25) | Every harvest rolls a **size** (weight). **Variants** (Frosted, Golden, Starlit…) are **earned**: crafted fertilisers made from rare crops and pet aptitudes / quirks give the chance, weather only adds a bonus; rolled on the server, deterministic per planting (§5.3) |
| Garden tools (2026-10-25) | A second upgrade tree beside the obby skills, bought with Coins and gated by Renown: size, growth, yield, comfort, defence; **no tool raises variant chance** (that comes from fertilisers and pets) (§6) |
| Critters first (2026-10-25) | A thin critter loop (crows, Pest-control pets on the field, the forecast line) is in the MVP; the full critters are the first drop (§7, §14) |
| Farm stages (2026-10-25) | Obby stages themed on the farm; each owns one unique rare crop whose seeds come only from that stage (§8.2) |
| Mini-game gates (2026-10-25) | Mini-games may gate content, but only by **completion**, never by time or skill ceiling (§8.3) |
| Monetization (2026-10-25) | **No paid random items** (no eggs for Robux, Coins / seeds / crops / cart stock are never sold for Robux, no Coin packs), **luck is never sold**, **weather is never sold**. Robux buys comfort (§13) |
| Live ops (2026-10-25) | A drop every **1–2 weeks** (the user can ship at that pace). Systemic content (forecast, market cart, weekly challenge, fair) before authored seasons (§9, §14) |
| Field pets (2026-10-30) | A pet is placed on a field square and works the squares in its reach (own square, then the 4 next to it, then 3 × 3, by level); a few field pet slots; one active job per pet; the 6 pens and the Perimeter post are dropped (§3) |
| Aptitudes (2026-10-30) | Born with jobs (Tending, Fertilising, Pest control with a speciality, Weeding, Scouting, Crafting), each with its own level 1–10 raised by doing it; rarity gives more aptitudes and a higher cap (6–10), the same level does the same on every pet; a maxed Uncommon equals an Epic at level 7 (§4) |
| Stage seed rewards (2026-10-30) | A medal finish drops a seed pouch (more for better medals, less for repeats); rare seeds come from a per-stage **rare-seed meter**, not a drop chance; Scouting pets add packets and fill the meter faster, capped; pets never touch times (§8.1) |

## 3. One pet, one place
*Decided 2026-10-30 (replaces "one pet, one post": the six pens no longer become Field posts and the Perimeter post is dropped).* A pet is in
exactly one place at a time; allocation is the game.

| Place | What the pet does |
|---|---|
| **A square of the field** | Stands on that square and does its **active job** (§4: Tending, Fertilising, Pest control or Weeding) on every square in its reach |
| **With you** | Today's 3 equipped slots: follows you in the obby; Scouting improves what a stage finish pays (§8.1); the Coin multiplier stays (equipped pets only) |
| *(nowhere)* | Rests in the inventory; keeps its bond |

- **No post buildings.** The plot shows the field with its pets standing on it; the 6 pens go.
- **Field pet slots** limit how many pets work the field at once: 1 free, a few bought (provisional 3–4 in total; E0). One pet per square.
- **Reach** is counted in squares, not studs, and grows with the active aptitude's level (§4): levels 1–3 the pet's own square, 4–6 that square
  and the 4 next to it, 7–10 the 3 × 3 block around it. Placing a pet highlights the squares it would cover.
- **Overlap:** different jobs on one square all apply; the same job does not stack (the strongest pet's effect counts).
- **One active job per pet**, chosen when it is placed. A pet with several aptitudes changes job by being placed again: extra aptitudes give
  flexibility (Tending today, Pest control when the forecast says crows), never several jobs at once.
- **Placement is the end-of-session decision:** guards go to the side the forecast names (§7), tenders to the long crops, the middle covers more
  than a corner.
- **Controls (settled 2026-10-30 in the E1a design check, ROADMAP → E1a):** a prompt at each square plants (seed picker over the seed stock), harvests (shows the
  size roll) and places or moves a pet; each prompt shows only within a few studs of its square (12 prompts side by side, mobile). A Garden panel
  at the own plot gives the overview (crop and time left per square, who works where) and holds the seed catalogue, selling and the next square
  (no seed stand on the plaza). Whether field pets can also be moved from far away is open (§16).
- **Data and validation.** `Garden.FieldPets[uid] = { Square, Job }`; the server checks the caller's own plot, an owned square, one pet per square,
  the slot count, that the pet has the aptitude and is not equipped. This generalises today's "equipped XOR penned" (`PetService` /
  `GardenService` already reject the conflicting actions).
- **Migration of live players.** Pen purchases (up to 6, 32 500 Coins in total) convert into field pet slots; how many slots and how much Coin is
  refunded for the rest is decided in E0 / E1b. The Coins-per-hour production is removed only after crops ship (E1), so live players keep their
  offline income until then.

## 4. Pet aptitudes, quirks and bond
*Decided 2026-10-30 (replaces the six traits Dig, Green thumb, Keen eyes, Brave, Swift, Craft with three novice / skilled / master steps, and the
three career XP tracks).* Aptitudes are the jobs a pet is born with; each has its own level that rises by doing that job.
**Rule: rarity gives breadth and a higher cap, time gives height.** The same aptitude level does exactly the same on every pet, whatever its rarity.

| Aptitude | Where | Effect on the squares in reach / on the run |
|---|---|---|
| **Tending** | field | Replants from the seed stock and harvests while the owner is away (the former "Gardener", §5.1) |
| **Fertilising** | field | Faster growth and a better size roll; from level 7 a small Golden chance that rises with the level (§5.3) |
| **Pest control** | field | Guards against critters (§7). A **speciality** rolled at birth (crows, moles, slugs, raccoons) works double against that critter |
| **Weeding** | field | Keeps weeds off (§7) |
| **Scouting** | with you | More seeds and a faster rare-seed meter from stage finishes (§8.1) |
| **Crafting** | stations | Runs station queues faster (§5.6); arrives with the stations |

- **The kind leans the roll** (dog → Pest control, bunny → Fertilising, owl → Pest control with a raccoon speciality, fox → Scouting…); the roll
  adds variance, so two foxes can differ. More aptitudes may be added later (each new one is a new id; stored ids never change).
- **Levels 1–10, diminishing returns** (effect in % of the maximum; placeholder until E0):

  | Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
  |---|---|---|---|---|---|---|---|---|---|---|
  | Effect | 20 | 35 | 48 | 59 | 68 | 76 | 83 | 89 | 95 | 100 |

  Reach steps at levels 4 and 7 (§3).
- **XP comes from doing the job:** time on the field (online at the full rate, offline at the offline rate, §2) or medal finishes with the pet
  equipped (Scouting). The steps grow: a specialist's cap takes weeks, the top levels months (E0 sets the curve). Provisional: every level from 7 up
  also needs a **tonic** brewed from a rare crop (Apothecary, §5.6), which ties the best pets to the obby.
- **Food** (Berry / Cake / Feast) keeps raising the pet level (1–20, size and the Coin multiplier's level part are unchanged); it does not raise
  aptitude levels. Open: an aptitude may not exceed half the pet level, so feeding and obby runs still matter for field pets (§16).
- **Rarity: breadth, not height** (placeholder):

  | Rarity | Common | Uncommon | Rare | Epic | Legendary |
  |---|---|---|---|---|---|
  | Aptitudes at birth | 1 | 1 (small chance of 2) | 2 | 2–3 | 3 |
  | Level cap | 6 | 7 | 8 | 9 | 10 |

  A **maxed Uncommon (level 7, 83 %) equals an Epic at level 7**; the Epic gains only 6 % at level 8 and 12 % at 9, for much more time. A rarer
  pet is more flexible (more jobs), not stronger at a job at the same level. Field pet slots are few, so a maxed specialist keeps its place.
  The +50 % Coin multiplier (rarity bonus of equipped pets) is unchanged and stays the only pure rarity number.
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

- **Looks follow the work:** the P1f accessories and P1e3 tier effects reflect the pet's highest aptitude (a veteran guard gets the scarf, a
  tender the straw hat).
- **Bond.** Favourite food, mood and affection. Mood gives only bonuses, never penalties (no guilt-driven check-ins).
- Personal spending: dyes, outfits, names, and a den furnished to the pet's preferences (a fox wants a burrow).
- **Data:** `Pets[uid]` grows `Apt = { [aptitudeId] = { L, XP } }` (1–3 entries), `Spec` (the Pest-control speciality), `Quirks`, `Bond`. Rolled
  at hatch from the uid (PetLook already derives the looks from it), so a reload never rerolls. Live pets get theirs rolled once from their uid at
  migration; their starting aptitude level comes from today's pet level (provisional, E0).

## 5. Crop economy
Coins stay the one currency. The profit loop: **buy seeds → plant → harvest → sell → buy better seeds and tools** (§6), with pets on the
field and the fence deciding how well it runs. Harvests are **items** (`Garden.Items[crop] = n`, a small table in the profile; a variant or
record-size item is kept apart, §5.3) with four uses: sell (through `CoinRewards.Grant`, so the pet bonus applies at sale time), process at
a station (about 1.5–2× the raw value), turn in on the request board or in a restoration bundle, replant as seed stock.

### 5.1 Field loop (no chores)
- A square holds one crop. A ripe crop waits and never rots; raids are the risk (§7).
- A square gives **one harvest per visit**, then stays empty. A **Tending pet on the field auto-replants** the squares in its reach from the seed stock
  while the player is away, so the square keeps cycling for as long as there are seeds. The pet matters through a capability, not a percentage.
- Output is limited by squares, seed stock, field pet slots, Tending reach and the online / offline rates (§2).
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
(the same approach as the raid timeline, §7). Tending pets' offline harvests roll too and appear in the ledger.

- **Size (weight).** A continuous roll with a long tail: "Pumpkin, 41.2 kg". Sale value scales with the size factor; its expected value
  is 1.0 with no tools, so the ladder holds. Labels: normal, Big, **Giant** (top few %). The field guide keeps the **personal best per crop**,
  giants can enter the weekly **Harvest Fair** (§9.3) or stay as a yard trophy (E7) instead of being sold.
- **Variants are earned, not rolled from the sky.** A variant is worth several times the normal crop (provisional ×2–5) and is an entry in
  the field guide (§11). A crop can only become a variant if something the player did gives it a chance:

| Variant | Source of the chance | Bonus | Value (provisional) |
|---|---|---|---|
| Frosted | Frost fertiliser on the square (brewed from the ice world's rare crop) | higher during Frost weather | ×2 |
| Golden | Gold-leaf fertiliser (from a farm-stage crop) or a Fertilising pet of level 7+ covering the square | – | ×5 |
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
**Stations** (queues with timers; Crafting pets run them faster): Compost (fertilisers for growth and variants, §5.3; the first station, with the variants),
Mill (grain → flour), Kitchen (crops → pet food, a cheaper route to levels than Berry / Cake / Feast; a raw crop can be fed since E1a3, worth only what its Coins would buy), Workshop (decor, plot upgrades),
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
| Seed chest | seed stock and storage capacity (Tending pets replant longer) | Comfort | D1 |
| Wheelbarrow | harvest every ripe square with one prompt | Comfort | D2 |
| Scarecrow | raid defence on a few squares (§7), like a low-level Pest-control pet; takes no field pet slot | Defence | D1 |

- **No tool raises variant chance:** variants come from fertilisers and pets (§5.3). Growth beyond the Cloches comes from Fertilising pets (§4).
- Data: `Garden.Tools[id] = level` in the profile.
- No tool and no tool level is ever sold for Robux (§13).
- E0 models the tool tree (prices, levels, the maxed case against the 24-hour rule).

## 7. Critters and raids
The defence loop is Pawvest's strongest hook (§1.1). Critters raid the garden while the player is away; not other players.
- **Forecast board** shows the coming weather and visitors together ("rain tonight: slugs likely; crows at dawn"). It is the reason to
  look before leaving: the player assigns guards with the forecast in front of them.
- **Weather drives critters** (§9.1): rain brings slugs and moles, a dry spell brings crows, frost keeps most critters away, a clear night
  brings raccoons.
- **Counters** (composition matters, not strength): Pest-control pets cover squares (§3); a speciality works double against its critter (§4).

| Critter | Targets | Counter |
|---|---|---|
| Crows | ripe crops | Pest control, crow speciality |
| Moles | growing crops (roots) | Pest control, mole speciality |
| Slugs | leaves, many small bites | wide reach, several guards |
| Raccoons | stored goods, at night | Pest control, raccoon speciality (how a guard covers the barn: open, D1) |
| Locust swarm (weekly) | everything | wide coverage |

- **Weeds** (D1, provisional): grow while the owner is away on squares no Weeding pet covers, slow growth and lower the size roll; the harvest
  clears them. Never a chore: there is no manual weeding.
- **Raids come from a side** the forecast names (provisional, "crows from the north tonight"): guards on that side cover the squares hit first.

- **MVP (thin):** crows only, Pest-control pets on the field (every Pest-control pet works against crows, the crow speciality double), the
  forecast as one line on the board and in the ledger. Enough to show "pets on guard"
  in the first sessions; the full set, the specialities that matter, weeds and the board are drop D1.
- **Resolution** is deterministic on join: each square is a timeline of events, critter visits and rare drops are seeded by
  `(UserId, day, index)`, so reloading or rejoining cannot reroll them. Test with the incubators' clock trick (move stored times back).
- **Losses are soft:** some crops or Coins, never pets, never a variant or a trophy. The GDD's "welcome back" popup grows into a **ledger** of
  the absence: raids ("Rex chased off 3 crows. Slugs ate 2 carrots."), harvests and their rolls, finished station queues, strays at the gate.
- The Scarecrow tool (§6) is a Coin-bought counter for a few squares, weaker than a Pest-control pet.
- Unresolved: loss caps per raid and how much a perfect defence earns (§16).

## 8. Obby, farm stages and mini-games
### 8.1 Obby links
- **Species unlocks (seed catalogue).** First finish / first Gold of a stage and challenge-coin milestones unlock crop species in the
  catalogue (§5.2).
- **Seed pouch (decided 2026-10-30).** Every medal finish drops a pouch of seeds of that stage's world: more packets for a better medal
  (provisional Bronze 1, Silver 2, Gold 3), fewer for repeats on the same day (like the Coin repeat reward, `RunsToday`), more for the first finish
  of the day on a stage. Seed income per obby hour must not run a full field on its own (the catalogue stays a Coin sink; E0).
- **Rare-seed meter (decided 2026-10-30, replaces the daily rare seed).** Each stage has a meter; every medal finish fills it (Gold the most, the
  daily first finish double), a full meter gives the stage's or world's rare seed. No drop chance: the player always sees how close the next
  rare seed is ("earned, not rolled"). E0 fixes the rare seeds per week at maximum Scouting.
- **World signature crops.** Each world has one rare crop (for example an ice melon from the ice-rink world); its seeds come from the
  first Gold of that world's stages and the rare-seed meters of its stages.
- **Rare items come only from the obby.** Rare crops are ingredients for fertilisers and their variants (§5.3), landmarks (§12), tonics
  (pet mastery), unique products (a night-watch tonic, a critter repellent) and trophies.
- **Scouting** (§4, the With-you aptitude): an equipped scout adds packets to the pouch (provisional +1 at level 10) and fills the meter faster
  (up to +50 %); the equipped pets' Scouting adds up to a cap (provisional +50 % in total, like the Coin multiplier). A real choice for the 3
  slots: a high Coin bonus or a scout. It is a meter speed, never a drop chance, so no pet becomes a luck lever (§13).
- Pets never touch times, movement or medals; only what a finish pays.

### 8.2 Farm stages
Obby stages themed on the farm (greenhouse, scarecrow field, orchard canopy, barn loft…), built from the existing kit (STAGES.md §2).
Each farm stage **owns one unique rare crop**:
- the first finish unlocks the species and gives a few seeds; the first Gold gives more; the stage's rare-seed meter gives more after that;
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
| Restoration bundle input (§12) | Old mill: Coins + wheat + a Crafting pet + clear the Gear Puzzle |
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
  Later: lend a guard pet to a friend's field for one night (fits "one pet, one place").
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
common crops, one rare crop, a pet-skill requirement (for example a Weeding pet of level 4+), and for some an obby achievement or a mini-game
completion (§8.3). Money is one input out of five, so every play style feeds the goal. First sketch (finite, authorable, shipped one at a time):

| Landmark | Unlocks | Bundle sketch |
|---|---|---|
| Kitchen | Kitchen station (takes over the food stand's role) | Coins, tier-1 crops, a Big crop |
| Old mill | Mill station | Coins, wheat, a Crafting pet, the Gear Puzzle |
| Greenhouse | growing in any season | Coins, tier-2 crops, a rare crop of world 1 |
| Pond | water crops, fishing mini-game | Coins, a Fertilising pet |
| Orchard | perennial trees | Coins, saplings (tier 3), a rare crop of world 2 |
| Watchtower | longer forecast, +1 field pet slot | Coins, a Pest-control pet of level 4+, Gold on a world-2 stage |
| Training grounds | faster aptitude XP (provisional +25 %) | Coins, a pet with 2 aptitudes at level 3+ |
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
| Capacity | +1 field pet slot, +1 incubator, the next field squares reached before their Renown / Coin gate (never beyond the earnable maximum) | game pass / product |
| Status | Pet dyes and outfits, decor packs, plot themes, fair-stand decorations, trails, a VIP tag | game pass / product |
| Generosity | A cosmetic gift to a friend (decor, a pet outfit) | developer product |
| Completion | Season pass premium track (§9.4) | product per season |
| First purchase | Starter pack, one time: a decor set, +1 field pet slot, 3 days of Night shift | developer product |
| Obby | Skip a stage / a checkpoint (rule 5) | developer product |

- Prices are placeholders (Robux price points are set at M7 / D2).
- E0 gets a **Spender archetype** (Night shift, capacity early, a daily instant grow) to check that paying speeds progress up by a bounded
  factor (provisional ≤ 1.5× per day) and that the 24-hour rule's online ceiling is unchanged.
- Telemetry (TELEMETRY.md) gets purchase and offer events: where an offer was shown, whether it converted.

## 14. MVP and drop plan
The MVP is the smallest build that shows the whole loop (buy seeds, plant, put one pet on the field to tend and one to guard, run an obby for a rare
seed, come back to a ledger of harvests and chased-off crows, upgrade a tool) and is worth opening to the public. After it, **a drop every
1–2 weeks**; obby drops alternate with garden drops; a drop that is too big for two weeks (World 4, estate) is split.

**Already built (comes with the MVP):** obby World 1 and World 2 (World 3 is built too; holding it back as a first content drop is an option),
pets, incubators, food, talents, telemetry, English / Czech localization.

**New in the MVP**
1. **E1** field and crops: about six crops in tiers 1–2, the seed catalogue and the daily market cart, selling, the size roll, light Renown,
   pens replaced by field pets (pets on squares, reach by level, §3), Tending auto-replant; tools tier 1 (Seed sorter, Cloches, Pruning shears).
2. **E4 (thin)** critters: crows, Pest-control pets on the field, the forecast line, crows in the ledger (§7).
3. **E2** obby links: the seed pouch and the rare-seed meter (§8.1), at least two rare crops (one from World 1, one from World 2).
4. **Aptitudes rolled at hatch, only the working ones shown.** The full data (aptitudes with levels, speciality, quirks) is stored from the first
   hatch (live pets rolled once from their uid), the UI shows only what already does something (Tending and Pest control in the MVP; Weeding with
   D1, Scouting with D3, Fertilising and Crafting with D4).
5. **Request board** (three daily requests) as the first goal beyond Coins and tools.
6. **Basic ledger on join** (harvests and their sizes, crows, eggs ready).
7. **Onboarding** for the first ten minutes (plant, put a guard on the field, run a stage, come back) and telemetry for the garden funnel (extends TELEMETRY.md).

**Not in the MVP:** the full critter set, weeds and the forecast board, variants and fertilisers, the comfort shop, mastery tonics and the other
stations, landmarks, estate tiers / decor / cottage, strays, seasons, trading (P3), obby World 4.

**Gates before going public** (existing roadmap items): the first live test (M6a) and the balancing pass, the Czech text review, the mobile layout
check (MU), the comfort shop (D2) or a decision to launch without it. A **soft launch** (friends, then unlisted) comes first; the garden
funnel telemetry decides whether the loop works.

**Drops after the MVP** (order provisional; each about 1–2 weeks)

| Drop | Content | Build stages | Why here |
|---|---|---|---|
| D1 "The Critters" | Moles, slugs, raccoons, weeds and Weeding, Pest-control specialities, the forecast board with weather, Scarecrow, Seed chest, full ledger | E4, E9 (weather), E1 | The hook that is ours (§1.1), right away |
| D2 "Comfort" | Comfort shop: Night shift, instant grow, starter pack, first cosmetics; Wheelbarrow | M7 | Monetization once the loop is proven |
| D3 "Weekly" | Weekly obby challenge, first farm stage and its crop, Harvest Fair, streak calendar, Scouting shown | E10, E2 | Obby drop; renewable obby content; size gets its stage |
| D4 "Variants" | Compost station, Frost and Gold-leaf fertilisers, Frosted / Golden variants, Fertilising and Crafting shown, Lucky quirk shown, field-guide records | E9, E5 | Earned variants tie the obby to the garden |
| D5 "The Kitchen" | First landmark (Kitchen), first mini-game gate (puzzle room) | E6, E5 | The first long goal |
| D6 "Neighbours" | Friend bonus, likes, help a neighbour, gifts, invites | E11 | Growth through friends |
| D7 "Mastery" | Quirks shown, field guide in full, tonics for aptitude levels 7+, other stations | E3, E5 | Pets get depth |
| D8 "World 4" | Obby World 4 (S9–S10), second farm stage, night fertiliser and Starlit, more landmarks (split) | S, E2, E6, E9 | Obby players and goal-chasers |
| D9 "The Estate" | Estate tiers, outdoor decor, cottage, garden score (split) | E7 | Visible personalization |
| D10 "Season 1" | First season and pass, strays, weekly visitor at the market cart | E10, E8 | Calendar-driven return |

At the stated pace D1–D10 is about 3–5 months after the MVP.

## 15. Build stages (progressive reveal; each stage ships alone)
| Stage | Content | Ships in |
|---|---|---|
| E0 | Economy model (`tools/economy.py`) against GDD §6; fixes the ladder, seed prices, sink share; later adds harvest rolls, fertilisers, tools, the Spender archetype | before the MVP, extended per drop |
| E1.0 | Spike: client-drawn plots, GO / NO-GO on the plot architecture (§16; ROADMAP → E1.0) | before E1 |
| E1 | Field of squares, crops, stock, sell, seed catalogue + daily market cart, size roll, Renown, tools; pens replaced by field pets (§3); Tending | MVP / D1 / D2 |
| E2 | Obby seed links (species unlocks, daily seed, world signature crops), farm stages and their crops | MVP / D3 / D8 |
| E3 | Aptitudes (levels, reach, specialities), quirks, field guide (data and hatch roll in the MVP, full UI in D7) | MVP / D7 |
| E4 | Critters, weeds, forecast board, offline raids, ledger, Pest control, Scarecrow (thin version in the MVP) | MVP / D1 |
| E5 | Request board (MVP), stations (Compost first), aptitude tonics | MVP / D4 / D5 / D7 |
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
5. **Field pets (2026-10-30):** the number of field pet slots and how pen purchases convert; whether field pets can be moved from far away (today the
   server allows garden actions only within 45 studs of the plot, and the "who guards tonight" choice often comes during an obby session;
   recommended: placing and moving from the Pets panel anywhere, planting and harvesting on the plot).
6. **Aptitudes:** whether an aptitude may not exceed half the pet level; whether levels 7+ need tonics; the XP curve; live pets' starting levels.

**Risks**
- **Genre overlap with Grow a Garden.** Reviewed 2026-10-25 (§1.1). Check every drop against §1.1 before it ships; the store page and the first ten
  minutes must lead with the obby, pets on guard and critters. Without gambling the excitement has to come from skill (obby), defence outcomes
  (the ledger) and earned rarities; telemetry on the garden funnel shows whether it does.
- **MVP scope.** The thin critters add work to the MVP; keep them to one critter, Pest control without specialities that matter, and a text forecast.
- **Onboarding.** The first ten minutes must show one loop: buy seeds, plant, put a guard on the field, run a stage, come back to a ledger. Field pets, aptitudes and tools are revealed gradually.
- **Content volume and the 1–2 week pace.** Crops, variants, fertilisers, quirks, critters, landmarks, farm stages: English and Czech (loc workflow), Studio-only art.
  Systemic content (forecast, market cart, weekly challenge, fair) keeps weeks without a drop alive; seasons wait until it does.
- **Luck inflation.** Size × variant × tools × fertilisers × pets × weather multiply; the expected value must stay inside the ladder (E0, §5.5).
- **Weather and forecast fairness.** A raid the forecast did not announce feels unfair: the forecast must be reliable, and the weather schedule
  must give every time zone its rare kinds.
- **Profile size and save cost** (items, variants, size records, fertilisers, tools, traits, decor, fair entries); keep compact encodings, check the DataStore limit per key.
- **Plot architecture (raised 2026-10-24; decided 2026-10-30 by the E1.0 spike: GO, numbers in ROADMAP → E1.0).** Today `GardenService` draws pens
  and pet models as server instances into 12 plots built in Studio, and a server holds 12 players. **Decision: the server keeps only data** (profile,
  timestamps, validation) and **each client draws the plots it needs** from one data message per plot: its own, plus others' within view distance at
  lower detail (full ≤ 120 studs, low ≤ 300, nothing beyond; builds spread over frames within a 6 ms budget). Plot positions come from a formula
  (`GardenConfig.PlotCFrame(slot)`: rings round the garden centre), so the player cap is no longer tied to built plots and the field is not bounded
  by a 40 × 40 stud plot. Measured: 30 plots in range cost at most 4 802 client instances with today's 12-square field (the worst spot is the garden
  centre, where all 12 inner plots are at full detail), no build frame over 7.6 ms, about +6 MB; the server gains no instance and no DataStore request;
  the server's distance check and `GoGarden` already use the formula.
  - **Player cap:** the drawing allows **30** (the formula has 30 slots and the 12-square field fits the instance budget). Start the garden servers at
    **24** in E1b: the 5 000 budget has only about 4 % headroom at 30 and E1 adds tools and crops (field pets replace the 6 pens: fewer pet models per plot); raise it to 30 once the mid detail below is in.
  - **Mid detail first:** pet models are 78 % of the instances (40-94 each). E1a adds a third detail: pets as one block beyond about 60 studs (a full plot
    drops from about 370 to about 70 instances), which also makes fields larger than 12 squares affordable (the 150-square stress field reached 7 779).
  - **Layout: compact neighbourhood + teleports, no walkable city.** Rings round the garden plaza, reached over the bridge and by `GoGarden`; the
    instance cost depends on how many plots are within 120 studs, and a city only adds walking. Today's ring 1 has **2.77 studs** between neighbouring
    plots (fails the 8-stud rule): E1 moves ring 1 to radius 112 and ring 2 to 185 (gaps 8.99 / 31.8 / 17.9 studs, 13.3 with the field). *Built in
    E1a1 (2026-11-02):* the island grows from radius 145 to 235 and, so as not to overlap the hub, the whole garden moved 87 studs away from it along
    the bridge axis (the bridge is unchanged); ring 2 is turned by 5° so the path from the bridge runs between plots; the hedge ring sits at 230.
  - **E1 migration list.** (1) Scene: grow the island and move the plaza ring for the new radii; delete `Workspace.Garden.Plots` (12 Studio plots)
    once `PlotView` draws by default; `PlotCount` → `PlotSlots`, Max Players 24. (2) `GardenPlots` keeps the slot assigner and the `GardenPlot`
    attribute, drops the plot-model writes (sign text and owner attributes come from the message). (3) Pens: `GardenService.renderPlot` / `makePenPet` go;
    the spike's feed becomes a real `GardenRemotes.Plot` broadcast (pens as `Kind:Level:uid`, pen count, eggs as `Egg:readyAt`, owner name, field); the
    owner's own `State` message stays for the panels. `PetPenFx` / `PetPenLevelUp` follow the client's pen models. (4) Incubators: the
    `GardenIncubators` renderer goes; `IncubatorClient` reads countdowns and prompts from `PlotView`. (5) Prompts: `PlotView` own-plot prompts call
    the pen / incubator panels directly (no `OpenPen` hook); `HintSources`' ready-egg marker targets the drawn incubator; `GardenClient` / `IncubatorClient`
    stop scanning `Workspace.Garden.Plots`. (6) Field (E1a): crop data in the profile and in the message, the mid detail, then re-run the budget test.
    (7) Remove the spike flag and `PlotViewSpike.*` once the real feed exists; keep `tools/plot_formula_test.luau` (re-point its Studio comparison at the
    new layout). Done already in E1.0: `GardenService.Usable` and `GoGarden` use `PlotCFrame`.
  - **Offline visit (designed, not built):** a separate store `GardenSnapshots`, key `garden_<UserId>`, written on leave and at most once per 5 min while
    the garden changes (in the profile save loop, its own key, so the 6 s rule per key does not slow the profile). Encoding: one JSON object
    `{ v, name, pens = { "Kind:Level:uid" × 6 }, eggs = { "Egg:readyAt" × 3 }, field = one string, 4 characters per square (crop, two base-64
    characters of minutes until ready, size / variant) }`: about 0.3 KB at 12 squares, 0.9 KB at 150 (limit 4 MB). A visit costs 1 `GetAsync` (read budget
    60 + 10 × players per minute: 360 at 30 players, so even one visit per player per minute is 8 %) and nothing else; writes stay under 6 per minute at
    30 players. An owner online on another server is shown from the same snapshot (at most 5 min old); no MessagingService.
  - Still open: a real-phone measurement (the Studio device emulator was not used; it does not slow the CPU anyway) and a 12-client join.
- **Live players.** Existing pets get their aptitudes rolled once from the uid (§4); pens convert to field pet slots (§3); what happens to the
  offline pen income and eggs at migration is E0 / E1b.
- **Field-pet reach vs the 24-hour rule.** E0 found the Gardener's coverage the most sensitive lever (2 squares per Gardener already put the worst
  day at 1.06x, ECONOMY.md); with reach up to 3 × 3 one Tending pet covers 9 of 12 squares. E0 must model reach, Tending strength and the slot
  count together; the value of tended squares, not their count, has to stay inside the rule. The bigger Tending edge also answers ECONOMY
  finding 5 (the Gardener's edge was too thin).
- **Free outdoor decor.** Placement exploits, per-item save size, collision with paths and neighbouring plots, mobile controls.
- **Bundles must stay finite.** Fix the first 6–8 landmarks and their contents before E6.
- **Mini-game gates** must stay passable for every player (completion only, mobile check); a gate that blocks garden-first players breaks §8.3.
- **Gifts and alt accounts.** Daily caps, no variant or pet gifts; the friend bonus must not reward a second account parked on the server.
- **Harvest Fair storage.** One entry per player per week and a weekly ranking: a small store per week, like the weekly challenge board.
- **Raids.** Loss caps and the reward for perfect defence; the fairness of a loss the player could not see coming (the forecast must be reliable).
