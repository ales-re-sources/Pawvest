# Pawvest — pet-garden simulator expansion design (E1–E8)

Status: **draft, direction decided 2026-10-24** (brainstorm with the user, nothing built yet).
**Name: Pawvest** (decided 2026-10-24; "Oby sandbox" was the working title; the Studio place, the project and the repository folder are renamed). Store subtitle "Pets · Garden · Obby", tagline "Grow. Guard. Run.". Availability on Roblox
and trademark are still to be checked. Avoid leading with "Grow" / "Garden" (the market leader "Grow a Garden" has pets with abilities). All numbers are
placeholders until an economy model exists (see §10). This document says *what* the next big expansion is; milestones
become ROADMAP entries when they start. It builds on GDD §7 (pets, garden) and does not change the obby.

## 1. Vision and pillars
**Pitch:** *grow things, put your pets on guard, run obbies for rare seeds.*

Today the garden is a vending machine (GDD §7.6: a pet in a pen pays Coins per hour, incubators, a food stand) and a pet is
mechanically a number (rarity bonus + level). The goal is a pet and garden game in which pets stay unique (they differ in
*what they can do*, not in how big their number is), the obby and puzzles supply the garden, and the garden is the reason to
come back.

| Pillar | Meaning |
|---|---|
| Pets are characters | Traits, quirks and careers; the only pure number stays the +50 % Coin multiplier cap |
| One pet, one post | A pet is in one place at a time; allocation is the game |
| The garden is a place | It grows while you are away, is attacked while you are away, and visibly evolves |
| The obby is the expedition | A skilful run brings back things the garden cannot make |
| Money buys verbs and looks | Coins unlock new abilities and a visible estate, never just a bigger number |

**Change to GDD pillar 2:** "slow or idle sources are a steady trickle, never the fastest route" becomes: the garden is the
main *passive* source and a developed garden out-earns a lazy obby day, but it never beats an active obby hour at the same
progress, and the best crops are only reachable through the obby. Pillar 3 (fair leaderboards) is unchanged: pets never
touch movement or stage times.

## 2. Decided
| Topic | Decision |
|---|---|
| Core | Farm-sim garden + guardian defence. Collector is a by-product (field guide over trait data, strays later) |
| Expeditions | Pets are **not** sent away (they would duplicate the farm's timers); the obby is the expedition |
| Pet identity | Traits + careers; breeding is out for now but the trait set must stay breeding-ready |
| Raids | Offline only, resolved by the server, reported in a ledger. No active shoo mode, no PvP |
| Garden loop | No chores (no watering); ripe crops wait |
| Unifying rule | One pet, one post. Existing pens become posts |
| Long goals | Island restoration bundles, estate tiers + cottage, pet mastery, garden score — all four |
| Decoration | Free placement **outside only**, per-tier limit, validated on the server; the cottage is fixed |

## 3. One pet, one post
| Post | What the pet does | Notes |
|---|---|---|
| **Field** | Works the beds (Gardener auto-replant, §5) | Replaces the Coins-per-hour pen |
| **Perimeter** | Guards a side of the garden (§6) | Arrives with E4 |
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
- **Quirks** are qualitative and carry a cost. Target about 30; examples:

| Quirk | Effect | Cost |
|---|---|---|
| Light sleeper | Guards at night | Weak by day |
| Digger | Finds a seed when idle | Scatters the bed it works |
| Glutton | Food gives extra XP | Nibbles crops |
| Hoarder | Stores overflow harvest | Slower to react to raids |
| Skittish | Spots threats early | Flees a fight |
| Lucky | Sometimes a rare drop | Lower base yield |
| Greedy | Extra yield | Some crops lost |
| Sleepy | Works well at night only | Idle by day |
| Brave | Holds the line alone | Ignores forecasts |
| Friendly | Bond grows fast | Distracted from work |

- **Careers.** Three XP tracks: **Explorer** (obby runs, with you), **Gardener** (field work), **Guardian** (perimeter). A pet's
  history decides how it evolves and which aptitude steps it can take. The existing visuals carry meaning: the P1f accessories
  and P1e3 tier effects reflect the career (a long-serving guard gets the scarf, a gardener the straw hat).
- **Mastery.** novice → skilled needs career XP; skilled → **master** needs a rare tonic brewed from a rare crop (§7, §9).
- **Bond.** Favourite food, mood and affection. Mood gives only bonuses, never penalties (no guilt-driven check-ins).
- Personal spending: dyes, outfits, names, and a den furnished to the pet's preferences (a fox wants a burrow).
- Data: `Pets[uid]` grows `Aptitude`, `Quirks`, `CareerXP = { Explorer, Gardener, Guardian }`, `Bond`, `Post`; PetLook already
  derives individuality from the uid, the same seeding gives the traits at hatch.

## 5. Crop economy
Coins stay the one currency. Harvests are **items** (`Garden.Items[crop] = n`, a small table in the profile) with four uses:
sell (through `CoinRewards.Grant`, so the pet bonus applies at sale time), process at a station (about 1.5–2× the raw value), turn in
on the request board or in a restoration bundle, replant as seed stock.

**Bed loop (no chores).**
- A bed holds one crop. A ripe crop waits and never rots; raids are the risk (§6).
- A bed gives **one harvest per visit**, then stays empty. A **Gardener pet on the Field post auto-replants** from the seed stock
  while the player is away, so the bed keeps cycling for as long as there are seeds. The pet matters through a capability, not a percentage.
- The cap is structural, so the 8 h offline rule is not needed for crops: beds, seed stock and the number of Gardener posts limit the output.
- Quirks bend the loop (Lucky, Greedy, Sleepy, Digger above).

**Value ladder (provisional)**

| Tier | Gate | Example crops (grow time) | Net Coins per bed-hour |
|---|---|---|---|
| 1 | start | Radish 20 min, Carrot 1 h, Potato 3 h | about 20 |
| 2 | Renown 5 | Corn 6 h, Pumpkin 8 h | about 45 |
| 3 | Renown 12 | Giant melon 12 h | about 90 |
| Rare | obby unlock | one signature crop per world | about 150 |

"Net" is after the seed cost (20–30 % of the sale price). A casual player with 4 beds (about 14 effective bed-hours a day) nets
roughly 1 100 Coins a day, about half of one good obby hour (GDD §6: ~2 230 in the first hour, ~500 / h later).

**Guardrails** (to hold after every rebalance, like GDD §6):
- Early garden income per day stays below the obby's first-hour income.
- Rare crops pay the most and only the obby unlocks them.
- Seeds, beds, stations, barn size, decor and bundles absorb a fixed share of the faucet (no inflation).
- A developed garden is the main passive income but never beats an active obby hour at the same progress.

**Renown** is a derived garden level (harvests, requests, restorations); it gates beds, stations and seed tiers and is never spent.
**Request board:** three requests a day ("6 carrots + 2 flour"), paying Coins, a rare item and Renown.
**Stations** (queues with timers; Craft pets run them): Mill (grain → flour), Kitchen (crops → pet food, a cheaper route to levels than
Berry / Cake / Feast), Compost (leftovers → fertiliser that speeds growth), Workshop (decor, plot upgrades), Apothecary (tonics, mastery items).

## 6. Critters and raids
Critters raid the garden while the player is away; not other players.
- **Forecast board** shows the coming visitors, like weather ("mole tracks at the east fence, crows at dawn"). It is the reason to
  look before leaving: the player assigns guards with the forecast in front of them.
- **Counters** (composition matters, not strength):

| Critter | Targets | Counter |
|---|---|---|
| Crows | ripe crops | Keen eyes |
| Moles | growing crops (roots) | Dig |
| Slugs | leaves, many small bites | many hands |
| Raccoons | stored goods, at night | night watch |
| Locust swarm (weekly) | everything | wide coverage |

- **Resolution** is deterministic on join: each bed is a timeline of events, critter visits and rare drops are seeded by
  `(UserId, day, index)`, so reloading or rejoining cannot reroll them. Test with the incubators' clock trick (move stored times back).
- **Losses are soft:** some crops or Coins, never pets. The GDD's "welcome back" popup grows into a **ledger** of the absence:
  raids ("Rex chased off 3 crows. Slugs ate 2 carrots."), harvest, finished station queues, strays at the gate.
- Unresolved: loss caps per raid and how much a perfect defence earns (§10).

## 7. Obby and puzzle links
- **Species unlocks (seed catalogue).** First finish / first Gold of a stage and challenge-coin milestones unlock crop species; each world has
  a signature crop (for example an ice melon from the ice-rink world). A daily first-run gives one rare seed.
- **Rare items come only from the obby.** Rare crops are ingredients for landmarks (§9), tonics (pet mastery), unique products
  (frost fertiliser against a critter type, a night-watch tonic) and trophies (a giant pumpkin on display in the yard).
- Puzzle rooms (the Laser Lab prototype `Workspace.KeyArena`) are the same kind of source and give one-time items.
- Pets never touch times or movement; an Explorer pet may only reveal secret coins.

## 8. Collector layer
A **field guide** over trait data (kinds, aptitudes, coats, quirks, plants, critters). **Wandering strays** arrive at the gate for a
limited time with their traits visible: adopt on sight instead of rolling blind (eggs stay as a blind route). Breeding is deferred; keep
the trait set breeding-ready (inherit a main aptitude, mutate a quirk).

## 9. Long-term goals: what money and rare seeds are for
Money is not the goal; it is one input into goals the player can see.

**Island restoration (the spine).** The garden island has overgrown landmarks, restored by **bundles** of five kinds of input: Coins,
common crops, one rare crop, a pet-skill requirement (for example a skilled Digger), and for some an obby achievement. Money is one
input out of five, so every play style feeds the goal. First sketch (finite, authorable, shipped one at a time):

| Landmark | Unlocks | Bundle sketch |
|---|---|---|
| Old mill | Mill station | Coins, wheat, a Craft pet |
| Greenhouse | growing in any season | Coins, tier-2 crops, a rare crop of world 1 |
| Pond | water crops, later fishing | Coins, a Green thumb pet |
| Orchard | perennial trees | Coins, saplings (tier 3), a rare crop of world 2 |
| Watchtower | longer forecast, +1 Perimeter post | Coins, a skilled Keen-eyes pet, Gold on a world-2 stage |
| Training grounds | career steps to skilled | Coins, a pet with 2 careers started |
| Nursery | choose between hatched strays | Coins, rare crop, 5 pets in the field guide |
| Observatory | seasonal event access | Coins, rare crops of three worlds |

**Estate tiers:** Patch → Homestead → Estate → Grand Garden, each a visible overhaul that other players see when they walk the plot
ring. A **cottage** with fixed rooms whose shelves fill by themselves (medals, field-guide book, pet portraits). **Outdoor decor** is
placed freely within a per-tier limit; the server validates bounds, collisions and count; store a compact position + rotation per item.

**Pet mastery** (§4) makes rare seeds gate the best form of a favourite pet. **Garden score** on the plot sign sums collection %,
restorations and masteries, visible to visitors.

**Horizons:** session (harvest, request, hatch) · week (next bundle, a pet rank-up, the next world's seed) · month+ (estate tier,
field guide complete, whole island restored).

## 10. MVP and content updates
The MVP is the smallest build that shows the whole loop (plant, post a pet, run an obby for a rare seed, come back to a ledger) and is
worth opening to the public. Every later piece ships as an announceable update; obby drops alternate with garden drops.

**Already built (comes with the MVP):** obby World 1 and World 2 (World 3 is built too; holding it back as a first content drop is an option),
pets, incubators, food, talents, telemetry, English / Czech localization.

**New in the MVP**
1. **E1** beds and crops: about six crops in tiers 1–2, seed shop, selling, light Renown, pens renamed posts, Gardener auto-replant for Green-thumb pets only.
2. **E2** obby links: at least two rare crops (one from World 1, one from World 2) and the daily first-run seed.
3. **Traits rolled at hatch, only the working ones shown.** The full trait data (aptitude, quirks, career XP) is stored from the first hatch, the
   UI shows only what already does something, so no live pet needs a retroactive roll later.
4. **First landmark + request board.** The first restoration (the Kitchen, which takes over the food stand's role) is the goal beyond Coins; three daily requests.
5. **Basic ledger on join** (harvest ready, eggs ready); raids plug into it later.
6. **Onboarding** for the first ten minutes and telemetry for the garden funnel (extends TELEMETRY.md).

**Not in the MVP:** critters and raids, mastery tonics and the other stations, estate tiers / decor / cottage, strays, seasons, trading (P3), obby World 4.

**Gates before going public** (existing roadmap items): the first live test (M6a) and the balancing pass, the Czech text review, the mobile layout
check, a monetization decision (M7; it may be deferred but must respect the fairness pillar). A **soft launch** (friends, then unlisted) comes first; the garden
funnel telemetry decides whether the loop works.

**Updates after launch**

| Update | Content | Why here |
|---|---|---|
| U1 "The Critters" | E4: forecast board, raids, Perimeter post, full ledger | The defence fantasy, the strongest hook |
| U2 "Mastery" | E3 in full (traits shown, careers, field guide), E5 stations, mastery tonics | Pets get depth |
| U3 "World 4" + restoration | Obby World 4 (S9–S10), more landmarks (E6) | Obby players and goal-chasers |
| U4 "The Estate" | E7: estate tiers, outdoor decor, cottage, garden score | Visible personalization |
| U5 "Seasons and Strays" | E8: seasonal crops, strays, weekly visitor | Calendar-driven return |

## 11. Build stages (progressive reveal; each stage ships alone)
| Stage | Content | Ships in |
|---|---|---|
| E0 | Economy model (spreadsheet or script) against GDD §6; fixes the ladder, seed prices, sink share | before the MVP |
| E1 | Beds, crops, stock, sell, seed shop, Renown; pens renamed posts (Field only); minimal Green-thumb Gardener | MVP |
| E2 | Obby seed links (species unlocks, daily seed) so the obby matters from day one | MVP |
| E3 | Traits, quirks, careers, field guide (data and hatch roll in the MVP, full UI in U2) | MVP / U2 |
| E4 | Critters, forecast board, offline raids, ledger, Perimeter post | U1 |
| E5 | Stations, request board (the board and the Kitchen are in the MVP), mastery tonics | MVP / U2 |
| E6 | Island restoration bundles and landmark abilities (first landmark in the MVP) | MVP / U3 |
| E7 | Estate tiers, outdoor decor, cottage shelves, garden score | U4 |
| E8 | Strays, weekly visitor, seasons | U5 |

## 12. Risks and open questions
- **Onboarding.** The first ten minutes must show one loop: plant, post a pet, come back to a ledger. Posts and traits are revealed gradually.
- **Content volume.** Critters, aptitudes, quirks, crops, landmarks: English and Czech (loc workflow), Studio-only art and models.
- **Profile size and save cost** (items, traits, decor); keep compact encodings, check the DataStore limit per key.
- **12 plots per server.** The simulation runs on server data; visuals are a view of it.
- **Live players.** What happens to existing pets (traits rolled retroactively from the uid?), pens, eggs and offline income at migration.
- **Free outdoor decor.** Placement exploits, per-item save size, collision with paths and neighbouring plots, mobile controls.
- **Bundles must stay finite.** Fix the first 6–8 landmarks and their contents before E6.
- **Raids.** Loss caps and the reward for perfect defence; the fairness of a loss the player could not see coming (the forecast must be reliable).
