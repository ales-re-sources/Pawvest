# Pawvest — pet-garden expansion design (E1–E11, drops D1–D10)

**Status (2026-11-05).** The direction was decided 2026-10-24 / 25 and reworked 2026-10-30 (pets on field squares, aptitudes, seed pouch and
rare-seed meter) and 2026-11-02 (farming is the main game). **Built and open to every player since FA** (2026-11-06; the P2 pens are gone): the
field, crops, size roll, Renown, upgrades and tier-1 tools, the market cart, field pets with aptitudes and Tending, obby seeds, crows and
Pest-control guards. The as-built rules are in **GDD §7.9** and the numbers in `CropConfig` / `PetConfig` (pinned by `tools/economy.py`). This
document keeps the **design not built yet** plus the rules every drop must follow (§1.1, §13); each section says what of it is built.
Compacted 2026-11-05; the full brainstorm text (superseded variants, the E1 migration list, the plot spike numbers) is in
`git show 87b1d3c:docs/EXPANSION.md`.

**Name: Pawvest** (decided 2026-10-24). Store subtitle "Pets · Garden · Obby", tagline "Grow. Guard. Run.". Availability on Roblox and the
trademark are still to be checked. Avoid leading with "Grow" / "Garden" (the market leader "Grow a Garden" has pets with abilities). Numbers
below are placeholders until the economy model takes them ([ECONOMY.md](ECONOMY.md)); milestones become ROADMAP entries when they start.

## 1. Vision and pillars
**Pitch:** *grow things, put your pets on guard, run obbies for rare seeds.*

The obby is finite content (players finish stages faster than they can be built); **systems** (crops growing, critters at the fence, the
forecast, weekly events) give a reason to come back, pets differ in *what they can do*, not in how big their number is, and the obby and
mini-games supply the garden with what it cannot make.

| Pillar | Meaning |
|---|---|
| Pets are characters | Aptitudes, quirks and bond; rarity gives breadth, time gives height (§4); the only pure number stays the +50 % Coin multiplier cap |
| One pet, one place | A pet is in one place at a time (a field square or with you); allocation is the game |
| The garden is a place | It grows while you are away, is attacked while you are away, and visibly evolves |
| The obby is the expedition | A skilful run brings back things the garden cannot make |
| Earned, not rolled | Rare results (variants, rare crops, pets' best forms) come from what the player did: obby runs, crafting, pet aptitudes; never from a slot machine |
| Coins buy verbs and looks | Coins unlock tools, abilities and a visible estate, never just a bigger number |
| Robux buys comfort | Time, capacity reached sooner, convenience and cosmetics; never luck, never a random item, never weather (§13) |

**GDD pillars:** since 2026-11-02 farming is the main income (the field earns about the obby's Coins over days 1–3, then far more; targets in
ECONOMY.md), and the best crops are reachable only through the obby. Pillar 3 (fair leaderboards) is unchanged: pets, tools and anything bought
never touch movement or stage times. GDD §9 follows §13: no Coin packs, no Robux eggs.

### 1.1 Not another Grow a Garden
Pawvest shares a proven genre loop (plant, wait, harvest, sell, upgrade) with the market leader. Sharing *only* the loop is the danger: next to
a much bigger game we lose on every shared axis, a "ripoff" reputation sticks, and the leader's excitement comes from gambling that Pawvest
rules out. Rules (reviewed 2026-10-25), **checked for every drop before it ships**:
- **Lead with what is ours.** The first ten minutes, the store page and the thumbnail show the obby, pets on guard and critters at the fence;
  planting and selling are the frame, not the hook.
- **Avoid the leader's signature mechanics:** no seed shop restocking every few minutes (a daily market cart instead), no random weather
  mutations (variants are earned, §5.3), no buying weather for a server (§13), no gear named like theirs (sprinklers, trowels; §6).
- **Our weather serves the defence:** it drives the forecast of critter visits (§7, §9.1), not a mutation lottery.
- **Size is social:** the size roll feeds a weekly Harvest Fair (§9.3), not only a number.

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
| Pet identity | Aptitudes with levels + quirks (§4); breeding is out for now but the trait set must stay breeding-ready |
| Raids | Offline only, resolved by the server, reported in a ledger. No active shoo mode, no PvP |
| Garden loop | No chores (no watering, no manual weeding); ripe crops wait and never rot |
| Unifying rule | One pet, one place: pets stand on field squares (no pens, no posts), reach by aptitude level (§3) |
| Long goals | Island restoration bundles, estate tiers + cottage, pet mastery, garden score — all four (§12) |
| Decoration | Free placement **outside only**, per-tier limit, validated on the server; the cottage is fixed |
| Field | One field of squares planted freely; **36 squares**, any square opened by choice at a price by the number open (2026-11-03, F2; built) |
| Garden vs obby | **Farming first** (2026-11-02): the 24-hour rule of 2026-10-24 is only reported now; the targets are in ECONOMY.md |
| Online vs offline | Offline income exists, online is higher: every passive gain runs at 1.0 online and **0.5 offline, capped at 24 h** per absence (2026-11-04). Never pure AFK (Roblox no longer pays for uptime) |
| Prices | E0 re-prices every sink; applied after the user's approval (E0b) |
| Seed shop | A fixed **catalogue** gated by Renown (and obby unlocks, §8.1) plus a daily **market cart** (same on every server, per-player counts; built); a weekly visitor later. Rare seeds are never sold |
| Harvest rolls | Every harvest rolls a **size** (built). **Variants** are **earned**: fertilisers from rare crops and pet aptitudes / quirks give the chance, weather only adds a bonus (§5.3) |
| Garden tools | A Coin tree gated by Renown beside the obby skills; **no tool raises variant chance** (§6) |
| Critters first | A thin critter loop is in the MVP (crows: built); the full set is the first drop (§7, §14) |
| Farm stages | Obby stages themed on the farm; each owns one unique rare crop (§8.2) |
| Mini-game gates | Mini-games may gate content only by **completion**, never by time or skill ceiling (§8.3) |
| Monetization | No paid random items, luck and weather are never sold; Robux buys comfort (§13) |
| Live ops | A drop every **1–2 weeks**; systemic content (forecast, market cart, weekly challenge, fair) before authored seasons (§9, §14) |
| Field pets | A pet on a square works the squares in its reach; 1 free + 4 bought field pet slots; a pre-field profile's pens converted into slots without a refund (built; pens removed in FA) |
| Aptitudes | Born with jobs, each with its own level 1–10 raised by doing it; rarity gives more aptitudes and a higher cap (6–10); the same level does the same on every pet (built: data, Tending, Pest control, Scouting) |
| Stage seed rewards | Seed pouch + per-stage rare-seed meter (no drop chance); Scouting adds packets and meter speed, capped; pets never touch times (built) |

## 3. One pet, one place
*Built for Tending and Pest control (GDD §7.9): squares, slots, reach 1 / 5 / 9 squares at levels 1–3 / 4–6 / 7–10, the strongest pet of a job
counts on overlaps, a pet with both jobs does both, "with you" = the 3 equipped slots (Scouting, Coin multiplier).*

Not built / open:
- **Fertilising and Weeding** on the field arrive with their drops (D4, D1). Open: whether a pet with several field aptitudes does all of them
  (as Tending + Pest control do since 2026-11-04) or picks one job when placed.
- **Placement highlight:** placing a pet shows the squares it would cover.
- **Placement is the end-of-session decision:** guards to the side the forecast names (§7), tenders to the long crops; the middle covers more
  than a corner.
- **Moving field pets from far away** (from the Pets panel during an obby session; today garden actions need the own plot): open, §16.

## 4. Pet aptitudes, quirks and bond
*Built (GDD §7.9, `PetConfig`): the six aptitude ids (Tending, Fertilising, Pest control with a speciality, Weeding, Scouting, Crafting),
levels 1–10 with diminishing effect (20 % at 1 to 100 % at 10), counts and caps by rarity, rolled once from the uid with the kind leaning the
draw, XP per weighted field hour. Only Tending, Pest control and Scouting do something yet; Fertilising arrives with D4, Weeding with D1,
Crafting with the stations. P4 (2026-11-05) added **Cuteness** (the Coin bonus as a trait, rolled by rarity chance), rolls new pets only from
the working traits (Fertilising / Weeding / Crafting rejoin the hatch pool when built), and made the pet level the highest trait level (1–10,
size and look follow it); food and obby XP train Cuteness, else work traits up to level 5 (GDD §7.4).*

**Rule: rarity gives breadth and a higher cap, time gives height.** A maxed Uncommon (level 7) equals an Epic at level 7; the rarer pet is more
flexible, not stronger at a job. New aptitudes get new ids (stored ids never change).

| Aptitude | Effect still to build |
|---|---|
| **Fertilising** | Faster growth and a better size roll on the squares in reach; from level 7 a small Golden chance rising with the level (§5.3) |
| **Pest control** | Specialities against moles, slugs, raccoons (only crows exist today; §7) |
| **Weeding** | Keeps weeds off (§7) |
| **Crafting** | Runs station queues faster (§5.6) |

- **Tonics (provisional):** every aptitude level from 7 up also needs a tonic brewed from a rare crop (Apothecary, §5.6), tying the best pets to
  the obby. (P4 settled the old question of a pet level next to the aptitudes: there is none, the pet level is the best aptitude.)
- **Quirks** are qualitative and carry a cost; target about 30, rolled from the uid (`Pets[uid].Quirks`). Examples:

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

- **Looks follow the work:** size and tier effects follow the pet's highest aptitude (built, P4); still to build: the accessories pick by
  that aptitude (a veteran guard gets the scarf, a tender the straw hat).
- **Bond** (`Pets[uid].Bond`): favourite food, mood and affection. Mood gives only bonuses, never penalties (no guilt-driven check-ins).
- Personal spending: dyes, outfits and a den furnished to the pet's preferences (a fox wants a burrow). Names are built (P3b).

## 5. Crop economy
*Decided, not built (EV, the user, 2026-11-07; numbers in [ECONOMY.md](ECONOMY.md) → EV, applied in EV2a–e):* one crop ladder from 10 s to 24 h (16 annual crops, the 4 built ones re-timed, "Future plant 1…12"
named later) and perennial fruit trees (a sapling, first growth 2–24 h, then a fruit every 5–60 min up to a cap of 4–6, forever).

*Built (GDD §7.9): the field loop (one crop per square, ripe crops wait, Tending replants during absences), the catalogue gated by Renown, the
daily market cart, the size roll with records, Renown as a derived level, selling through `CoinRewards.Grant`, crops as pet food. The value
ladder and prices are in `CropConfig` (ECONOMY.md).*

Harvests are items with four uses: sell, process at a station (about 1.5–2× the raw value), turn in on the request board or in a restoration
bundle, replant. **Grow times match real-life gaps** (a quick crop for a short session, 1 h for lunch, 8–12 h for the night): "what do I plant
before I leave, and who guards it?" is the end-of-session decision.

### 5.1 Tomato growth art pilot

One annual Tomato grows continuously from bare soil to a ripe bush. Each stem extends from its base, a shorter arm branches from it,
and a leaf opens from its attachment. Vary lean, spread and spacing per planting. The fruit stays attached as its branch dips. Use colored
Plastic blocks with the garden's `Studs` and `StudsSmall` materials. The five poses below are review stops on the same plant.

| Growth | Pose |
|---|---|
| 0% | A green tip breaks the soil after planting. An empty square stays bare. |
| 20% | A short leaning stem carries two broad leaves unfolding at different angles. |
| 50% | Two or three unequal arms open, with clear gaps between them and smaller leaves near their tips. |
| 75% | Small green tomatoes swell beneath the outer branches, which begin to dip. |
| 100% | Two or three full red tomatoes hang below the leaves. Fruit size and branch angle also signal ripeness in grayscale. |

**Art review.** First compare three ripe block studies in the field: A, squat and spreading; B, upright and open; C, leaning under fruit.
Review at gameplay distance and phone size, with a neighbor crop, field pet and ring for scale. The developer chooses a silhouette or asks
for another study. Next, review the chosen bush in a display-only Studio prototype: a scrubber, short loop, five poses and six planting
seeds. Scrub both ways at 43–44% to check attachments. Check crop identity and ripeness with rings hidden, then check UI legibility with
them visible. The developer signs off on the stills and loop before field integration.

The [ripe studies](art/tomato/ripe-studies.jpg) were captured from a client-only display plot built by the production plot renderer.
The [field view](art/tomato/field.jpg) includes a Potato ring and a Cat; the [720 × 405 view](art/tomato/phone.jpg) is a resized
Studio capture. Reproduce the three studies with [the Studio client command](../tools/tomato_ripe_studies.luau) during a playtest.

**Field integration after sign-off.** Build the structure once per planting identity and share compact identity and time anchors in the
public plot feed. The owner and nearby visitors see the same plant at the same age. Check rejoin, offline growth, replant and distance
changes. Compare frame times against the current renderer on the same route with a full 36-square field and 24 synthetic plots, then test
a real phone against a proposed 30 FPS target. If necessary, group distant leaves into plates and shorten the full-detail radius.

Tomato keeps its eight-minute crop time and clears the square at harvest. A future perennial Apple keeps its seeded trunk and branches
through harvest; only fruit regrows at persistent attachment points. Particles and lights can follow the silhouette review.

### 5.2 Seed catalogue and market cart (not built parts)
- **Species unlocks from the obby:** first finishes / first Golds and challenge-coin milestones unlock catalogue species (§8.1), on top of Renown.
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
- Size and variant stack; the expected value with tools, fertilisers and pets maxed goes through E0 before D4. A variant or record item is
  stored apart from the plain per-crop counts and summed sizes the barn keeps today.
- Giants can enter the weekly Harvest Fair (§9.3) or stay as a yard trophy (E7) instead of being sold.

### 5.5 Guardrails
Checked by `tools/economy.py check` after every rebalance (targets: ECONOMY.md): rare crops pay the most and only the obby gives them; seeds,
squares, tools, fertilisers, stations, barn, decor and bundles absorb a fixed share of the faucet (no inflation beyond the accepted F2 scale);
comfort purchases (§13) speed progress up by a bounded factor and never change online income.

### 5.6 Requests and stations
- **Request board** (E5, MVP): three requests a day ("6 carrots + 2 flour"; sometimes "a Big pumpkin" or "a Frosted carrot"), paying Coins, a
  rare item and Renown.
  *Decided (EV, 2026-11-07):* semi-random per UTC day + user (crops of the unlocked set, never the same crop twice a day, sized to ~30 % of a
  day's income, 1.75× the sale; on some days a **timed run** — a cleared obby stage under a time limit between the best time and Bronze,
  later mini-games); one in three also drops Sunshine, a rare seed or an egg.
- **Stations** (queues with timers; Crafting pets run them faster): Compost (fertilisers, the first station, with the variants, D4), Mill
  (grain → flour), Kitchen (crops → pet food, a cheaper route to levels than Berry / Cake / Feast; raw crops can already be fed), Workshop
  (decor, plot upgrades), Apothecary (tonics, mastery items).

## 6. Garden tools
A Coin tree gated by Renown, never touching the obby, never sold for Robux (§13). Names are our own (§1.1). Data: `Garden.Tools[id] = level`.
*Built (GDD §7.9): Seed sorter (size), Cloches (online growth), Pruning shears (a second crop), plus the Growth and Barn upgrades.*

| Tool | Raises | Axis | Ships |
|---|---|---|---|
| Seed chest | seed stock and storage (Tending pets replant longer; may fold into the Barn upgrade) | Comfort | D1 |
| Wheelbarrow | harvest every ripe square with one prompt | Comfort | D2 |
| Scarecrow | raid defence on a few squares (§7), weaker than a Pest-control pet, takes no field pet slot | Defence | D1 |
| Clearing tools (parked, user 2026-11-03) | locked squares lie under rubble or weeds; clearing a kind needs a tool level or a bought tool, on top of the square's price | Reach | later |

**No tool raises variant chance:** variants come from fertilisers and pets (§5.3).

## 7. Critters and raids
The defence loop is Pawvest's strongest hook (§1.1). Critters raid the garden while the player is away; never other players.
*Built (E4-thin, GDD §7.9): crows on a fixed UTC block schedule, the forecast line in the barn panel (U4; before it the Garden panel), Pest-control guards with the crow
speciality, deterministic resolution on join, at most 1 crop lost per absence, rare crops safe, losses in the join notice.*

Still to build (drop D1 unless noted):
- **Weather drives critters** (§9.1): rain brings slugs and moles, a dry spell brings crows, frost keeps most away, a clear night brings raccoons.
- **Forecast board** with the coming weather and visitors together ("rain tonight: slugs likely; crows at dawn").
- **Counters** (composition matters, not strength); a speciality works double against its critter:

| Critter | Targets | Counter |
|---|---|---|
| Moles | growing crops (roots) | Pest control, mole speciality |
| Slugs | leaves, many small bites | wide reach, several guards |
| Raccoons | stored goods, at night | Pest control, raccoon speciality (how a guard covers the barn: open) |
| Locust swarm (weekly) | everything | wide coverage |

- **Weeds** (provisional): grow while the owner is away on squares no Weeding pet covers, slow growth and lower the size roll; the harvest
  clears them. Never a chore: no manual weeding.
- **Raids from a side** the forecast names (provisional, "crows from the north tonight"): guards on that side cover the squares hit first.
- **Losses stay soft:** some crops or Coins, never pets, never a variant or a trophy. The join notice grows into the **ledger** of the absence
  (E5): raids, harvests and their rolls, finished station queues, strays at the gate.
- Open: loss caps per raid for the full set and what a perfect defence earns (§16).

## 8. Obby, farm stages and mini-games
### 8.1 Obby links
*Decided, not built (EV, the user, 2026-11-07; numbers in [ECONOMY.md](ECONOMY.md) → EV, applied in EV2a–e):* repeat runs pay Sunshine instead of Coins; Scouting XP = seconds of a running stage timer.

*Built (E2, GDD §7.9): the seed pouch, a rare-seed meter per stage (no drop chance), one rare crop per world (first Gold of a World 2 / 3
stage, the day's first finish, the meter), Scouting from equipped pets (meter speed and a pouch seed, capped at +50 %).*

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
replayable afterwards for a small daily reward.

| Use | Example |
|---|---|
| Restoration bundle input (§12) | Old mill: Coins + wheat + a Crafting pet + clear the Gear Puzzle |
| One-time unlock | A puzzle room opens a seed tier or a station |
| Repeatable source | Fishing at the Pond (after its restoration), a harvest rush; short, counts as online time |

Each mini-game is 1–3 minutes (GDD pillar 1) and passes the mobile check (ROADMAP → MU).

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
- Rewards: a finish gives a rare seed; the weekly Top-10 gets a cosmetic yard trophy. Same talent and pet rules (pillar 3).

### 9.3 Harvest Fair
- A weekly prize-vegetable fair at the hub: one crop per player per category (rotating: pumpkin, melon, a farm-stage crop…).
- Ranked by size factor (every tier can compete); the top entries get a ribbon trophy, every entrant Renown; the entered crop is kept.
- Size gets a social stage without a gamble: the roll is free, the Seed sorter and the choice of entry are the skill.

### 9.4 Seasons
- 4–6 weeks each: a theme, 3–4 seasonal crops, one seasonal pet kind (adopted, not hatched from a paid egg), a decor set, a seasonal farm stage or
  challenge, a seasonal critter.
- A **season pass** with a free and a premium track (§13), fed by season XP from everything.
- Starts only after the forecast, the market cart, the weekly challenge and the fair run without attention.

### 9.5 Streak calendar
*Decided, not built (EV, the user, 2026-11-07; numbers in [ECONOMY.md](ECONOMY.md) → EV, applied in EV2a–e):* days 1–6 Sunshine (10–30 min), **day 7 an Epic-or-better pet** (Epic 95 %, Legendary 5 %).

A 7-day loop of small rewards; a missed day **pauses** the streak instead of resetting it (no guilt).

## 10. Social
*Later (the user, 2026-11-07): gifts / buying something for a friend, a pet auction (needs trading's session locking).*

- **Friend bonus:** a small bonus on harvest sales while a friend is on the same server (provisional +10 %, outside the pet multiplier cap; E0).
- **Visits and likes:** the plot ring is walkable; a like feeds the other plot's garden score (once per plot per day).
- **Help a neighbour:** one optional tap on another plot gives both a small growth boost (once per plot per day). Later: lend a guard pet to a
  friend's field for one night.
- **Gifts:** seeds and common crops to a friend, capped per day (no pets, no variants; alt accounts must not become a faucet).
- **Invites:** the Roblox invite prompt with a reward when an invited friend joins (check Creator Rewards' current terms for new / lapsed players).
- Trading stays open (§16).

## 11. Collector layer
A **field guide** over trait and harvest data: kinds, aptitudes, coats, quirks, crops × variants, size records, fair ribbons, critters.
**Wandering strays** arrive at the gate for a limited time with their traits visible: adopt on sight instead of rolling blind; the main
non-random route to pets (whether eggs stay is open, §16). Breeding is deferred; keep the trait set breeding-ready (inherit a main aptitude,
mutate a quirk).

## 12. Long-term goals: what money and rare seeds are for
*Decided, not built (EV, the user, 2026-11-07; numbers in [ECONOMY.md](ECONOMY.md) → EV, applied in EV2a–e):* until the landmarks / estate are designed, the model keeps a reserved sink ladder (×1.15 steps) so
the late game never runs dry; rebirth is not planned for launch (a soft "Replant" only if the queue empties, ECONOMY.md → Findings).

**Island restoration (the spine).** Overgrown landmarks on the garden island, restored by **bundles** of five kinds of input: Coins, common
crops, one rare crop, a pet-skill requirement (e.g. a Weeding pet of level 4+), and for some an obby achievement or a mini-game (§8.3). Money is
one input of five, so every play style feeds the goal. First sketch (finite; fix the first 6–8 before E6):

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

**Estate tiers:** Patch → Homestead → Estate → Grand Garden, each a visible overhaul others see on the plot ring. A **cottage** with fixed rooms
whose shelves fill by themselves (medals, field-guide book, pet portraits, ribbons, giant-crop trophies). **Outdoor decor** placed freely
within a per-tier limit; the server validates bounds, collisions and count; store a compact position + rotation per item.

**Pet mastery** (§4) makes rare seeds gate the best form of a favourite pet. **Garden score** on the plot sign (collection %, restorations,
masteries, likes), visible to visitors, **never ranked** (bought cosmetics would make a ranking pay-to-win).

**Horizons:** session (harvest, request, hatch, set the guards) · day (ledger, forecast, market cart, daily seed, streak) · week (weekly
challenge, fair, next bundle, an aptitude level, the next farm stage) · month+ (season, estate tier, field guide, whole island restored).

## 13. Monetization: sell comfort
Decided 2026-10-25 (GDD §9 follows it):
1. **No paid random items.** No eggs for Robux; Coins, seeds, crops and the market cart's offers are never sold or re-rolled for Robux; no Coin packs.
2. **Luck is never sold.** Size and variant chances come only from Coin-bought tools, crafted fertilisers, pets and weather.
3. **Weather is never sold**, for one player or for a server.
4. **Everything that changes the economy is earnable through play and capped** (GDD §9): Robux only reaches it sooner.
5. **The obby stays clean** (pillar 3): nothing bought affects a time; a skip gives no time, no medal, no payout and no challenge coin.
6. **Offers appear at a pain point, never on join**, and nothing in the first session: a full field, a long crop still growing, "growth paused
   after 24 h" in the ledger (information, not guilt).

| Motive | Product | Kind |
|---|---|---|
| Idle comfort | **Night shift**: offline rate and cap above the free 0.5 / 24 h (say 0.75 / 36 h; through E0); never changes online income | game pass |
| Impatience | Instant grow (one square, price by remaining time, daily cap); finish an incubator | developer product |
| Capacity | +1 field pet slot, +1 incubator, the next field squares before their Renown / Coin gate (never beyond the earnable maximum) | game pass / product |
| Status | Pet dyes and outfits, decor packs, plot themes, fair-stand decorations, trails, a VIP tag | game pass / product |
| Generosity | A cosmetic gift to a friend (decor, a pet outfit) | developer product |
| Completion | Season pass premium track (§9.4) | product per season |
| First purchase | Starter pack, one time: a decor set, +1 field pet slot, 3 days of Night shift | developer product |
| Obby | Skip a stage / a checkpoint (rule 5) | developer product |

- Prices are placeholders (Robux price points at M7 / D2).
- E0 gets a **Spender archetype** (Night shift, capacity early, a daily instant grow): paying speeds progress up by a bounded factor
  (provisional ≤ 1.5× per day) and never changes online income.
- Telemetry (TELEMETRY.md) gets purchase and offer events: where an offer was shown, whether it converted.

## 14. MVP and drop plan
The MVP is the smallest build that shows the whole loop (buy seeds, plant, put one pet on the field to tend and one to guard, run an obby for a
rare seed, come back to a ledger of harvests and chased-off crows, upgrade a tool) and is worth opening to the public. After it, **a drop every
1–2 weeks**; obby drops alternate with garden drops; a drop too big for two weeks (World 4, estate) is split.

| MVP piece | State |
|---|---|
| Obby Worlds 1–3, pets, incubators, food, talents, telemetry, English / Czech | built (holding World 3 back as a first content drop is an option) |
| E1 field and crops, catalogue, market cart, size roll, Renown, field pets with Tending, tier-1 tools | built, every player (FA) |
| E4-thin crows, Pest-control guards, the forecast line | built, every player (FA) |
| E2 seed pouch, rare-seed meters, rare crops per world, Scouting | built |
| Aptitude data for every pet, only working aptitudes shown | built |
| E5 request board, ledger on join (the join notice grows into it), onboarding for the first ten minutes, garden funnel telemetry | **to build** (ROADMAP → Next) |

**Not in the MVP:** the full critter set, weeds and the forecast board, variants and fertilisers, the comfort shop, tonics and the other
stations, landmarks, estate / decor / cottage, strays, seasons, trading, World 4.

**Gates before going public:** the first live test (M6a) and the balancing pass, the Czech text review, the mobile check (MU), the comfort shop
(D2) or a decision to launch without it. A **soft launch** (friends, then unlisted) first; the garden funnel telemetry decides whether the loop works.

**Drops after the MVP** (order provisional; each about 1–2 weeks; D1–D10 is about 3–5 months)

| Drop | Content | Build stages | Why here |
|---|---|---|---|
| D1 "The Critters" | Moles, slugs, raccoons, weeds and Weeding, Pest-control specialities, the forecast board with weather, Scarecrow, Seed chest, full ledger | E4, E9 (weather), E1 | The hook that is ours (§1.1), right away |
| D2 "Comfort" | Comfort shop: Night shift, instant grow, starter pack, first cosmetics; Wheelbarrow | M7 | Monetization once the loop is proven |
| D3 "Weekly" | Weekly obby challenge, first farm stage and its crop, Harvest Fair, streak calendar | E10, E2 | Obby drop; renewable obby content; size gets its stage |
| D4 "Variants" | Compost station, Frost and Gold-leaf fertilisers, Frosted / Golden variants, Fertilising and Crafting working, Lucky quirk, field-guide records | E9, E5 | Earned variants tie the obby to the garden |
| D5 "The Kitchen" | First landmark (Kitchen), first mini-game gate (puzzle room) | E6, E5 | The first long goal |
| D6 "Neighbours" | Friend bonus, likes, help a neighbour, gifts, invites | E11 | Growth through friends |
| D7 "Mastery" | Quirks shown, field guide in full, tonics for aptitude levels 7+, other stations | E3, E5 | Pets get depth |
| D8 "World 4" | Obby World 4 (S9–S10), second farm stage, night fertiliser and Starlit, more landmarks (split) | S, E2, E6, E9 | Obby players and goal-chasers |
| D9 "The Estate" | Estate tiers, outdoor decor, cottage, garden score (split) | E7 | Visible personalization |
| D10 "Season 1" | First season and pass, strays, weekly visitor at the market cart | E10, E8 | Calendar-driven return |

## 15. Build stages (progressive reveal; each stage ships alone)
| Stage | Content | Ships in | State |
|---|---|---|---|
| E0 | Economy model (`tools/economy.py`); later harvest variants, fertilisers, the Spender archetype | before the MVP, per drop | partial |
| E1 | Field, crops, catalogue + market cart, size roll, Renown, tools, field pets, Tending | MVP / D1 / D2 | MVP part built |
| E2 | Obby seed links, species unlocks, farm stages and their crops | MVP / D3 / D8 | MVP part built |
| E3 | Quirks, field guide, aptitude UI in full | D7 | aptitude data built |
| E4 | Critters, weeds, forecast board, ledger, Scarecrow | MVP / D1 | crows built |
| E5 | Request board (MVP), stations (Compost first), tonics | MVP / D4 / D5 / D7 | – |
| E6 | Restoration bundles and landmark abilities, mini-game gates | D5 / D8 | – |
| E7 | Estate tiers, outdoor decor, cottage shelves, garden score | D9 | – |
| E8 | Strays, weekly visitor | D10 | – |
| E9 | Weather schedule (with the forecast), fertilisers and earned variants | D1 / D4 / D7 / D8 | – |
| E10 | Weekly obby challenge, Harvest Fair, streak calendar, seasons and the pass | D3 / D10 | – |
| E11 | Social | D6 | – |
| M7 | Comfort shop (§13) | D2 | – |

## 16. Risks and open questions
**Open decisions for the user**
1. **Coin eggs:** keep the Coin incubators (no Robux eggs, decided) or remove eggs and make strays the only pet source? Instant grow sells time
   that becomes Coins: check the current Roblox paid-random-items rules before D2.
2. **Farm stages:** bonus stages outside the unlock chain (recommended) or numbered world stages (§8.2).
3. **Trading:** the strongest retention driver in pet games, but dupes, scams and moderation; plan for it or rule it out.
4. **Numbers:** variant chances and fertiliser recipes, Night shift values, weather cadence, friend bonus; all go through E0.
5. **Field pets from far away:** place / move field pets from the Pets panel anywhere (recommended; the "who guards tonight" choice often comes
   during an obby session), planting and harvesting stay on the plot.
6. **Aptitudes:** whether levels 7+ need tonics; several field jobs at once (§3). (The pet level question was settled by P4: pet level = best aptitude.)

**Plot architecture (decided 2026-10-30, built in E1a).** The server keeps only data; each client draws the plots it needs from one
`GardenRemotes.Plot` message per plot (full / mid / low detail by distance, `GardenView`); plot positions come from `GardenConfig.PlotCFrame`
(30 slots on two rings), so the player cap is not tied to built plots. Garden servers start at **24** players for the soft launch (the instance
budget had about 4 % headroom at 30; raise to 30 after a fresh budget test with the 36-square field). Still open: a real-phone measurement and
a 12-client join.
- **Offline visit (designed, not built):** a store `GardenSnapshots`, key `garden_<UserId>`, written on leave and at most once per 5 min while
  the garden changes (its own key, outside the profile's write gap); one compact JSON object (name, field pets, eggs as `Egg:readyAt`, the
  field as one string of 4 characters per square: crop, minutes until ready in two base-64 characters, size / variant), under 1 KB. A visit
  costs one `GetAsync`; an owner online on another server is shown from the same snapshot (at most 5 min old); no MessagingService.

**Risks**
- **Genre overlap with Grow a Garden** (§1.1): check every drop against it; the store page and the first ten minutes lead with the obby, pets on
  guard and critters. Without gambling the excitement comes from skill (obby), defence outcomes (the ledger) and earned rarities; the garden
  funnel telemetry shows whether it does.
- **Onboarding.** The first ten minutes show one loop: buy seeds, plant, put a guard on the field, run a stage, come back to a ledger; field
  pets, aptitudes and tools are revealed gradually.
- **Content volume and the 1–2 week pace:** every crop, variant, quirk, critter and landmark needs English and Czech and Studio-only art;
  systemic content keeps weeks without a drop alive, seasons wait until it does.
- **Luck inflation:** size × variant × tools × fertilisers × pets × weather multiply; the expected value must stay inside the targets (E0, §5.5).
- **Forecast fairness:** a raid the forecast did not announce feels unfair; the weather schedule must give every time zone its rare kinds.
- **Profile size and save cost** (items, variants, records, fertilisers, quirks, decor, fair entries): keep compact encodings, watch the
  DataStore limit per key.
- **Free outdoor decor:** placement exploits, per-item save size, collisions with paths and neighbouring plots, mobile controls.
- **Mini-game gates** must stay passable for every player (completion only, mobile check).
- **Gifts and alt accounts:** daily caps, no variant or pet gifts; the friend bonus must not reward a second account parked on the server.
- **Harvest Fair storage:** one entry per player per week and a weekly ranking: a small store per week, like the weekly challenge board.
- **Raids:** loss caps and the reward for perfect defence for the full critter set.
