# Pawvest — Game Design Document

Status: **draft**. Numbers are provisional until `T_base` is measured in the M6 balancing pass (see [ROADMAP.md](ROADMAP.md)).
This document says *what* the game is as built and why; the roadmap says how and when it is built. Exact numbers live in the configs
(`src/ReplicatedStorage/*Config.luau`); [ECONOMY.md](ECONOMY.md) holds why they are what they are.

**Coin scale:** every Coin amount (rewards, prices, sell values) is 10× the first draft, so small percentage bonuses show up in single
payouts. Balances stored before the change were multiplied by 10 once (profile `Version = 3`); never scale stored Coins by hand.

## 1. Pillars
1. **Short, readable stages**: each stage is a 1–3 minute run with a clear finish.
2. **Mastery pays most**: within the obby, medals and fast times pay the most Coins; repeating a stage still pays, but less with every
   run. The crop field (§7.9) is the main income (everyone has it).
3. **Fair leaderboards**: nothing that affects a leaderboard time can be bought with Robux. Pets never change movement or stage times;
   talents do, but are earned with Coins and crops only (§9).
4. **One hall, many games**: the central island hosts several minigames (obby, pet garden, more later). They share one currency (Coins)
   and one pet collection, so progress in any game helps in the others.

## 2. Core loop
```
run a stage → medal by time → Coins (one-time per medal tier + diminishing repeat reward)
     ↑                                   ↓
faster runs / harder stages  ←  talents + stage unlocks

Coins (from any minigame) → eggs, pet slots → pets → Coin bonus + pet levels → more Coins
```
Secondary loops: talents (e.g. double jump) open new routes → challenge coins on already-cleared stages; pets level up while you play;
the pet garden (§7.6) raises pets, and the crop field (§7.9) produces Coins over time, also offline.

## 3. Stages

The game has the **Tutorial plus 15 stages in 3 worlds of 5**; a 4th world (stages 16–20) is planned (design and reasons:
[STAGES.md](STAGES.md)). The display number is the position in the game (`order` / `displayName` in `StageConfig`); the internal **key
and folder equal the position** (`Stage1` … `Stage15`, `Tutorial`) and **never change** (they are DataStore keys; only a stage's
`order`, `displayName`, bar and price may). Checkpoints take blocks of 100 numbers per stage. Shown names are positions ("Stage 1" …):
the signs, boards, popups and panels read them; the working titles below are not shown.

| # | World | Working title | Internal key | Required talents | Unlock |
|---|---|---|---|---|---|
| T | – (hub) | Tutorial | `Tutorial` | – | always open |
| 1 | 1 | Island Hop | `Stage1` | – | Bronze on Tutorial **or** 200 |
| 2 | 1 | the variety stage | `Stage2` | – | Bronze on 1 **or** 1 000 |
| 3 | 1 | bounce corridors | `Stage3` | – | Bronze on 2 **or** 1 500 |
| 4 | 1 | Blink ★ rhythm | `Stage4` | – | Bronze on 3 **or** 2 000 |
| 5 | 1 | the precision finale | `Stage5` | – | Bronze on 4 **or** 2 000 |
| 6 | 2 | Double Up | `Stage6` | Double Jump | World gate ¹ **or** 2 500 |
| 7 | 2 | Seesaw | `Stage7` | Double Jump | Bronze on 6 **or** 3 000 |
| 8 | 2 | Turntable | `Stage8` | Double Jump | Bronze on 7 **or** 3 000 |
| 9 | 2 | Labyrinth ★ iso maze | `Stage9` | Double Jump | Bronze on 8 **or** 3 500 |
| 10 | 2 | Clocktower, finale | `Stage10` | Double Jump | Bronze on 9 **or** 4 000 |
| 11 | 3 | Triple Peaks | `Stage11` | Triple Jump | World gate ¹ **or** 4 000 |
| 12 | 3 | Ice Rink | `Stage12` | Triple Jump | Bronze on 11 **or** 4 500 |
| 13 | 3 | Dash Bridge | `Stage13` | Triple Jump, Long Dash | Bronze on 12 **or** 5 000 |
| 14 | 3 | Laser Lab ★ side-scroller | `Stage14` | Triple Jump, Long Dash | Bronze on 13 **or** 5 500 |
| 15 | 3 | Rising Tide, finale | `Stage15` | Triple Jump, Long Dash | Bronze on 14 **or** 5 500 |
| 16–20 | 4 | planned (STAGES §8): Wall Climb, Glide Canyon ★, Moon Base, Clockwork, Summit | – | + Wall Jump, + Glide | World gate ¹ **or** 6 000, then 6 500 / 6 500 / 7 000 / 7 500 |

¹ **World opener** (stages 6, 11, 16): **10 of the 15 stars of the previous world** (10 = Silver on every stage of the world,
provisional) **or** the price (a second unlock rule type, "stars in a world", next to "medal on the previous stage").

The Tutorial belongs to no world: it stays a hub stage, its stars count in the total and on the hub board but not toward a world, so a
world is exactly 5 stages = 15 stars and the opener rule "10 of 15" stays exact.

★ = the world's special stage (plays differently from a normal obby, STAGES §5). **Bonus stages** (planned, STAGES §5.3) would come on
top: not numbered, outside the unlock chain (no bar, no price; each opens with its world), reward factor 1.0, medals, Top-10 board and
challenge coins like any stage; their stars count toward the total (+3 each).

Prices follow `price(n) ≈ medal total of stage n−1, rounded to 500`; buying every unlock costs 47 200 for the 15 built stages (80 700 for
all 20 planned), so skipping stays possible and expensive. Stage 1 is set to 200 on purpose: a new player cannot earn Coins without a
Tutorial medal (the Tutorial pays at most its 120 challenge-coin Coins without one), so the price is a shortcut for later purchases, not a
path for new players.

**Required talents** are shown, never enforced: the gate face lists "Needs: …", arriving without a required talent shows a warning with a
button to the Skills panel, and entry stays open. The course geometry is the real gate.

**Checkpoints** are square stud plates (16 × 12) across the course with a small green tile in the middle. Only the player's current
checkpoint (the respawn point) glows, and only for that player (a column of light rises from it; the previous one turns back). The first
reach in a run plays a sound; walking back to an earlier checkpoint moves the respawn point there silently. Passing the stage's start
gate counts as reaching its first checkpoint; a new run turns the lit pad back. Death respawns are placed on the stored plate facing
along the course after Roblox has placed the character at its default spawn.

**Unlocks.** Every stage after the Tutorial opens either by **meeting the bar** (required medal on the previous stage) or by a **one-time
Coin price**. Unlocks are permanent. Each stage can be bought on its own (Stage 3 does not require Stage 2 to be open). Times or medals
recorded on a locked stage do not open it, and admins follow the same rules. The first stage's bar is deliberately low (Bronze, ≈ 48 s on
the Tutorial): a new player has 0 Coins, so the Tutorial is the real way in and must always stay completable.

**Hub portals** show: stage name, locked / unlocked, requirement + price when locked, best medal earned, and challenge coins found `x/y`.
Locked portals are walls (`PortalBarriers`).

**Mastered stage.** A stage is *mastered* for a player when the top medal (Gold) is earned **and** every challenge coin of the stage is
found (a stage without coins needs only Gold). It tells the player "you are done here"; the only goals left are the own record and the
Top 10. Purely a display, no reward, local to the player (read from `Medal_<stage>` and `CollectedCoins`):
- each finished goal gets a green tick on the gate's door face (after the stars, after the coin line);
- once both are done a gold check badge bobs above the start gate, visible across the courtyard; the gate, its sign and the "Stage N"
  title stay as authored. The Tutorial gets it above its start gate (`LandingPad.StartGate`, no door: its tick face hangs on a local
  invisible anchor) and above its hub portal.

The hub world gates follow the same rule for the whole world: a green tick after the stars line when every star of the world is earned,
after the coins line when every coin of its stages is found, and the gold check above the gate once the world is mastered (all its
stages; a world with stages not built yet or marked `soon` shows nothing).
Open: showing the personal best time on the mastered door (needs a replicated best-time attribute).

## 4. Time tiers
Each stage has `T_base` = time of a clean run by the developer **with exactly the talents the stage requires** (none on the Tutorial and
stages 1–5). `tBase` lives in `StageConfig`; a stage may point `tiers` at its own table. Default thresholds:

| Medal | Stars | Threshold | Intent |
|---|---|---|---|
| Bronze | ★ | ≤ 2.5 × T_base | finishable by any player who owns the required talents (none in World 1), with a few deaths; Bronze unlocks the next stage, so a first run with deaths must pass |
| Silver | ★★ | ≤ 1.1 × T_base | clean run; early talents help |
| Gold | ★★★ | ≤ 0.8 × T_base | requires the talents of the stage's designed set (§6) and a good route |

Example: Tutorial `T_base` 30 s → Bronze ≤ 75 s, Silver ≤ 33 s, Gold ≤ 24 s. Run Speed and Jump Height never become requirements; they
stay the way to faster medals and shortcuts.

`T_base` is provisional (ranges: STAGES §4). World 3's values come from the developer's best runs with every talent (Gold ≈ 1.25 × that
best), so its Silver and Gold are much tighter than its Bronze; Stage 15 has its own `tiers` (Gold ≤ 46 s, +2 s for the stamper gate).
Worlds 1–2 keep rough values until M6 (M6a World 1, M6b the rest). Every run stays within pillar 1 (1–3 minutes).

Timer precision: tenths of a second (server-measured, floored by `TimeFormat.Tenths`). A run starts at `TimerStart`, ends at the finish
portal, and is cancelled by leaving through `TeleportToSpawn`.

Medal rules:
- A finish slower than the Bronze threshold earns no medal and no medal or repeat Coins (the time still counts as a personal best); the
  first finish of a stage still pays the first-finish payout (§5) and every finish pays pet XP (§7.4).
- A player's medal on a stage is the highest tier ever reached; it is never revoked, also not when thresholds are retuned.
- After every finish a results popup shows: time, personal best (or "New record!"), the medal of this run, Coins paid (medal payout,
  first-finish payout and repeat reward), and the threshold of the next medal not yet earned.

Limits are visible before and during a run:
- **Score panel** (on arriving at a stage): all three limits, e.g. `★ 1:52  ★★ 1:17  ★★★ 0:56`; tiers already earned are gold. It shows
  only on a stage; elsewhere the tracker line takes its place (§7.9; the hub's total stars left the HUD, the world gates still show their
  star bar).
- **Stage timer** (while running): next to the time, the best medal still reachable and its limit (`00:41.3  ★★★ 0:56`); when a limit
  passes it drops to the next tier, after Bronze to "no medal".
- **Hub portals**: earned stars are drawn on the portal face itself (part of the gate, not camera-facing).

## 5. Rewards
*Decided, not built (EV; numbers in [ECONOMY.md](ECONOMY.md) → EV, applied in EV2c):* repeat medal finishes pay **Sunshine** (16 / 24 /
32 s per Bronze / Silver / Gold into a store, spent as one time skip for every growing square, tree and incubator, × 0.8^n per stage and
day, stored up to 3 h), rare seeds and pet XP instead of Coins; one-time medal / first-clear Coins stay.

All Coins earned by playing (medal payouts, repeat rewards, challenge coins, crop sales, future minigames) are paid through one server
function (`CoinRewards.Grant`) and multiplied by the player's pet bonus (§7.3). Purchases are not.

### Medal payouts (one-time per tier, per player)
Base payout Bronze 200 / Silver 400 / Gold 800, × stage factor. Reaching a higher tier directly also pays the lower tiers not yet earned
(a first-try Silver pays Bronze + Silver).

**Stage factor** by display number `n`: `factor = 0.5 + 0.25 × n` (`rewardFactor` in `StageConfig`); the Tutorial stays at 0.5. Bonus
stages use 1.0. Stage total = 1 400 × factor (Stage 2: factor 1.0 → 200 / 400 / 800 = 1 400; Stage 15: 4.25 → 5 950). Planned 21 stages
in all: 83 790 Coins, but the six Tutorial / World 1 stages pay 5 040 by `firstClear` (below), not their factor totals.

### First-finish payout (one-time per stage, per player)
The first finish of a stage pays **100 × stage factor** (Tutorial 50), medal or not (a slow first finish should not go unrewarded), on top
of any medal payout of that run. "First" means the profile has no best time for the stage yet.

**First clears of the Tutorial and World 1.** These six stages carry `firstClear`: the first finish and its medals together pay 250
(Tutorial) / 600 / 800 / 1 000 / 1 250 / 1 500 Coins (Stage 1–5; `StageConfig.OneTimeFactor` spreads it over the finish and medal
payouts, so a later medal still pays its share), plus 4 seeds of the newest unlocked common crop up to Garlic (Tutorial) or Tomato
(World 1). Repeat rewards keep `rewardFactor`.

### Repeat reward (every medal finish, diminishing)
```
run reward = max(10, round(50 × stage factor × medal multiplier × 0.8^n))
```
The medal multiplier is that **run's** medal (Bronze ×1, Silver ×1.5, Gold ×2); `n` is the number of earlier medal finishes of that stage
by the player **today** (UTC day, resets at midnight UTC). A finish without a medal pays 0 and does **not** count towards `n` (a slow run
never lowers the next medal run's reward). Paid on top of any medal payout, also on the first finish. Example, Stage 2 (factor 1.0):
first run 50 / 75 / 100 (Bronze / Silver / Gold), the first 10 Gold runs of a day sum to 446. After 8–14 runs a stage pays the 10-Coin
floor until the next day, so faster medals pay more, grinding runs out quickly, and switching stages beats repeating one (pillar 2).

### Challenge coins
Placed off the main path, behind risky jumps, or reachable only with talents. Each coin is collected **once per player**, saved
(`CollectedCoins`) and hidden only for that player. Values: easy 20 / risky 50 / talent-gated 100, **flat on every stage** (no scaling
with the stage factor). From World 1 on, a talent coin needs a talent the stage does **not** require (one from a later world), so
finished stages are worth revisiting after each new talent.

Built: 122 coins, 4 840 Coins in all. Tutorial 3 coins (2×50, 1×20; 120); Stages 1 / 2: 4×20, 2×50, 1×100 (280); Stage 3: 4×20, 2×50,
2×100 (380); Stage 4 and every World 2–3 stage: 5×20, 2×50, 1×100 (300); Stage 5: 4×20, 2×50, 3×100 (480). Talent-gated coins of World
1 need Double Jump (placed out of reach of a Jump Height 3 jump). Ids are `<stage folder>_<n>` and never reused (retired ids are listed in
`ChallengeCoinConfig`).

**One-time total of the Tutorial and Stages 1–5:** 5 040 (medals) + 1 840 (coins) = 6 880 Coins, plus repeat rewards, the crop field and
the pet bonus, which have no fixed cap.

## 6. Talents
Each bought level costs **Coins + a crop bundle** from the barn (`Garden.Items`): from level 2 common crops of the player's tier, and the
levels a stage requires also a rare crop of the world before. The server takes the Coins and the crops together or not at all
(`TalentService`, `GardenField.TakeCrops`; the average size leaves, as in a sale). The Skills panel's buy button shows the whole price
(💰 Coins over the crops as icons with have / need, what is short highlighted; a refused tap names what is missing, §7.10) and is green only when
everything is there. The built tree costs 73 400 Coins plus crops, so talents need the farm.

Bought in the skills panel (top-left), except **world rewards**: a level a world requires that the server grants when that world opens
(Double Jump with World 2). Permanent, server-owned (`Talent_<id>`), applied on every spawn. The admin toggles (run speed 16↔64, 5 air
jumps) are debug tools only. The admin panel's **Reset Score** is a debug full reset of the admin's **own** progress (Coins, times,
medals, unlocks, coins found, talents, own Top-10 entries), confirmed by a second click; the server ignores it from non-admins.

| Talent | Levels | Effect per level | Cost per level (Coins + crops) | Coins total |
|---|---|---|---|---|
| Run Speed | 5 | +6 % WalkSpeed (16 → 20.8 at max) | 800; 1 400 + 12 Garlic; 2 600 + 12 Cucumber; 4 500 + 15 Corn; 8 000 + 15 Pepper | 17 300 |
| Double Jump | 1 | one extra jump in the air | free: world reward, granted when World 2 opens | 0 |
| Jump Height | 3 | +8 % jump height | 1 100; 1 900 + 12 Cucumber; 6 500 + 15 Pepper | 9 500 |

Double Jump is a **world reward**: the server grants level 1 when World 2 opens for the player (the star bar met or the world bought for
Coins), with a "new skill" popup; it is never sold (`TalentConfig` `rewards = { [1] = 2 }`, cost 0). *Why:* it is World 2's only hard
gate, and a young player spent the Coins on other things, reached World 2 without it and gave up without knowing why. It still opens the
talent coins of World 1 and the World 1 Gold routes, now as a revisit once World 2 is open. Triple Jump (`DoubleJump` level 2) is
still bought; the talents World 3 requires (Triple Jump, Long Dash) stay bought (user decision): from World 3 on the farm feeds the obby.

**Other talents** (ids never renamed; all client-driven, level server-owned; Run Speed and Jump Height stay soft, never required; only
hard gates can be *required* by a stage):

| Talent | Id | Effect | Levels | Cost (Coins + crops) | Coins total | First required at |
|---|---|---|---|---|---|---|
| Quick Respawn | `QuickRespawn` | utility, **never required**: level 1 respawns after 1 s instead of 3 s, level 2 instantly and adds a fall reset to the checkpoint; the timer keeps running | 2 | 1 100 + 12 Tomato / 10 000 + 15 Broccoli | 11 100 | – |
| Triple Jump | `DoubleJump` level 2 | 2 air jumps (reach about 19 studs) | +1 | 8 500 + 10 Cucumber + 1 Frost grape | 8 500 | stage 11 |
| Dash | `Dash` | in the air, a short horizontal burst (about 10 studs in 0.2 s), once per air time; key + mobile button | 1 | 8 000 + 12 Corn | 8 000 | – |
| Long Dash | `Dash` level 2 | the burst lasts 0.32 s: about 16 studs (STAGES §1.0, §7.12) | +1 | 19 000 + 12 Pepper + 1 Glow mushroom | 19 000 | stage 13 |
| Wall Jump (planned) | `WallJump` | against a wall in the air, jump kicks up and away; does not refill air jumps | 1 | 700 000 + 20 Blueberry + 3 Glow mushrooms | 700 000 | stage 16 |
| Glide (planned) | `Glide` | hold jump while falling: fall speed capped at about 8 studs/s | 1 | 2 600 000 + 25 Blueberry + 4 Glow mushrooms | 2 600 000 | stage 17 |

Full planned tree: 3 373 400 Coins plus the crops. Talents compete with squares, upgrades, pets and incubators (§7.9) for the same Coins.

### Economy constraints (must hold after every rebalance)
Talents need the farm, so the old no-grind rule (required set affordable from the stages' medals alone) is gone. Its replacement is
ECONOMY.md's check **G4** (`economy.py check`): obby-only Coins through World 2 cover at most 40 % of the World 1–2 tree, and every
required level is affordable within 1 day (Obby main, Garden main) or 2 days (Casual) of reaching the stage that needs it, garden on.
World 3 gives no talent as a reward (Triple Jump / Long Dash stay bought; user decision).

### Coins per hour (open income, provisional)
Obby, first hour of a day (Gold runs): ~2 230 (the first 10 Gold runs of each of four stages, then the 10-Coin floor); later the same
day ~500 (10 Coins per run at ~70 s; a ~25 s Tutorial loop pays ~1 400 / h, open, see M6). Crop field (§7.9): the main income from day
1–3 on (`economy.py check`: field ≈ obby over days 1–3, 3× by day 7, 10× by day 30). Pet bonus × 1.0–1.5 on all of it.

Sinks: talents (73 400 built, 3.4 M planned, plus crops), stage unlocks (47 200 built, 80 700 planned), eggs (§7.2), pet slots (4 700),
incubators (3 300), the crop field (§7.9) and feeding (§7.6). Bought stage unlocks sit outside the talent budget (the intended cost of
skipping); eggs and slots compete with talents for the same Coins. Open: Gold at 0.8 × T_base with only Run Speed 2 on Stage 1 needs a
near-perfect route; verify in M6.

## 7. Pets
Pets follow the player, are born with **traits** (aptitudes, §7.9) and level them up; a pet with **Cuteness** multiplies Coin income.
They never affect movement, jumping or stage times.

### 7.1 Rarities and kinds
| Rarity | Cuteness base bonus | Sell value | Traits at birth | Trait cap | Example kinds (prov.) |
|---|---|---|---|---|---|
| Common | +2 % | 100 | 1 | 6 | Cat, Dog |
| Uncommon | +4 % | 200 | 1 (10 %: 2) | 7 | Bunny, Fox |
| Rare | +7 % | 500 | 2 | 8 | Owl, Panda |
| Epic | +10 % | 1 500 | 2 (50 %: 3) | 9 | Dragon |
| Legendary | +15 % | 5 000 | 3 | 10 | Phoenix |

Every pet is an individual (own traits with their levels), identified by a unique id per player. Inventory holds up to **50** pets. A pet
can be **sold** back for its sell value (irreversible).

**Traits.** Rolled once at hatch from the pet's id, never rerolled, from the working traits only: **Cuteness** (the Coin bonus),
Tending, Pest control, Scouting (§7.9). Tending comes first (`TendingChance`; always for an owner who has no Tending pet yet), then
Cuteness by `CuteChance` while a slot is left, the rest from Pest control / Scouting (the kind leans the draw); slots the pool cannot fill
take Cuteness, then Tending. Share of hatches with Cuteness: Common 28 %, Uncommon 32 %, Rare 50 %, Epic 70 %, Legendary 82 %.
Fertilising, Weeding and Crafting stay stored on pets that have them (hidden, not counted) and rejoin the pool when built.

### 7.2 Eggs
The pet (kind and rarity) is **rolled at purchase**; its rarity sets the hatch time (Common / Uncommon 5 m, Rare 1 h, Epic / Legendary
4 h); traits still roll at hatch. Existing eggs from before this rule got a fixed pet once on join and kept their deadlines.

**Egg ladder.** Every egg is a **gem** (one scheme: rare gems, "smart and unique pets"), its shell in the gem's colour; no shell colour
matches a rarity colour, so a shell never reads as a promised rarity. The stored ids `Basic` / `Golden` stay (Pearl / Topaz). The two dear
eggs **open with a crop** (`PetConfig.Eggs[id].opensWith`, `PetConfig.EggOpen`): until that crop is open the card shows 🔒 + the crop's
icon and "Opens with …", and the server refuses the purchase. Later eggs take the next gems (Emerald / Sapphire / Amethyst only in a
non-rarity shade, or Opal, Onyx); kind-pool eggs wait until there are more than 8 kinds.

Every egg hatches in an **incubator** of the player's garden plot (§7.6) in real time, also while the player is offline. There is no egg
stand on the central island. The odds are always shown before buying: the "?" panel lists each rarity's chance and, under it, the kinds
that rarity can hatch as small portraits; a kind the player has never owned is a dark silhouette (`SeenKinds`, filled from the pets owned
on join and by every new pet).

| Egg (id) | Price | Opens | Shell | Common | Uncommon | Rare | Epic | Legendary |
|---|---|---|---|---|---|---|---|---|
| Pearl egg (`Basic`) | 120 | from the start | pearly cream | 60 % | 26.2 % | 11 % | 2.7 % | 0.1 % |
| Topaz egg (`Golden`) | 4 000 | from the start | gold-yellow, glow | – | 50 % | 37 % | 12.7 % | 0.3 % |
| Ruby egg (`Ruby`) | 450 000 | with Pumpkin | deep red, glow | – | – | 60 % | 39.6 % | 0.4 % |
| Diamond egg (`Diamond`) | 3 000 000 | with Giant melon | ice-white, glow + sparkles | – | – | 40 % | 58 % | 2 % |

Free eggs:
- one Pearl egg on the first join after pets launched (also for existing players, and again after an admin reset); a free egg that starts
  while the player has never hatched a pet (and nothing incubates) is **ready to hatch at once**, so a new player gets the first pet
  right away;
- one Pearl egg for the **first Gold on each stage**, the Tutorial included (`StageResults`; 16 over the built game, plus the launch egg);
- a request drop's egg (§7.9): Pearl, a Topaz egg once Pumpkin is open (`CropConfig.DropEggFor`).

A free egg starts by itself (no Coins) in the lowest empty incubator as soon as one is empty: on join, when the egg is earned, after a
hatch or cancellation and after an incubator is bought. While every incubator is busy (or the inventory cap is reached) it waits in the
profile; the Pets panel and the incubator panel show how many wait. Its pet is chosen when it enters a nest.

The nest row shows the egg with **Scanning…** for its first 30 s, then the remaining time; the pet kind and rarity stay server-only until
**Hatch**. Shared time tiers keep the exact rarity uncertain. A small square **trash** button (the shared ConfirmTap pattern, §7.10)
discards a growing egg without returning Coins or a free egg; a waiting free egg can immediately occupy the freed nest.

### 7.3 Slots and Coin bonus
Up to 3 pets can be **equipped** (follow the player, count for the bonus). A newly hatched pet is equipped automatically when a slot is
free. Slot prices: 1 free, 2 700, 3 4 000.

```
pet bonus  = base bonus (rarity) + 1.9 % × (Cuteness level − 1)     (0 without Cuteness)
multiplier = 1 + min(50 %, sum of the bonuses of equipped pets)
paid       = round(base Coins × multiplier)
```
A Cuteness-10 Legendary gives +32.1 %, a capped Common (6) +11.5 %; two strong cute pets hit the +50 % cap. Equipping a pet without
Cuteness raises nothing, so the slots are a choice between income and Scouting.

### 7.4 Levels and XP
**Pet level** = the highest level of its working traits, 1–**20** (max level and max look, §7.5; `PetConfig.BaseLevel`: every curve is the
old 10-level one with its steps split, level 1 stays 1 and old level L is level 2L, so XP totals, caps ×2 = 12 / 14 / 16 / 18 / 20,
strengths, reach (levels 8 and 14) and the bonus at every even level are unchanged); traits cap by rarity (§7.1). Food, fed crops, obby XP
and time with you are **care XP**: they train **Cuteness** first, otherwise the pet's lowest working trait, a work trait as 36 s of field
time per XP; XP nothing can use is lost.

**Food bootstraps, activity maxes:** food and fed crops train every trait only up to the **food limit**, half the rarity cap (Common 6,
Uncommon 7, Rare 8, Epic 9, Legendary 10); a pet whose traits are all there is refused food ("grows with you now"). Past it only activity
counts: Cuteness grows on to the cap from obby XP (counted **× 0.04** once Cuteness is at its food limit: a Gold run ~2 XP) and from
**time with you** (each equipped pet 0.75 XP per online minute; Roblox's 20-minute idle kick bounds AFK time); work traits take care XP
only up to the food limit and grow on from their jobs: Tending / Pest control from field hours, Scouting from medal finishes (§7.9). A
daily player takes a fresh Legendary to Cuteness 10 within two days and to 20 in ~90 (ECONOMY → Decisions (FD)). Cuteness XP from level L
to L+1: `round(100 × L^1.5)` (L1→2: 100, L5→6: 1 118, L9→10: 2 700). Every **equipped** pet receives the full XP of each event:

| Source | XP |
|---|---|
| Finish with Bronze / Silver / Gold (the run's medal) | 5 / 10 / 20 |
| Finish without a medal | 2 |
| Challenge coin collected | +1 |
| Movement while a stage timer runs | 1 XP per 20 studs, max 30 per run |
| Feeding in the pet garden (§7.6) | per food item, up to the food limit |
| Time with you | 0.75 per online minute |

Movement is measured on the server (horizontal distance of the character); jumps faster than walking speed allows (teleports, respawns)
do not count, and nothing is earned outside a running timer, so AFK walking earns nothing. Movement XP is paid at the finish, together
with the medal XP; a cancelled run (back to the hub) earns none. Levels are permanent.

**Migrations (profile versions, still run on join):** `Version = 6` (20 levels): every trait of every pet became level 1 → 1, L → 2L,
keeping its XP (`PetConfig.RescaleAptitudes`; the XP already earned towards the next old level can be worth one or two levels). A
Legendary Lv 10 → Lv 20; the Coin bonus is the same at every even level and in between it rises by half a step (about 0.95 %).
`Version = 4` (traits): a pet from before got Cuteness at `1 + ceil((old level − 1) × 9 / 19)`, clamped to its cap; no pet's bonus
dropped. Its old `Level` / `XP` stay stored, unused.

### 7.5 Display
Equipped pets float behind their owner and are visible to all players, with rarity colour and level on a small label. **Parking:** while
a player stands on the field of their own garden plot, their followers wait in a row at the field entrance (the path's end, facing the
field) so they never hang between the camera and the squares, and glide back when the owner walks out (hysteresis: park from 1 stud
inside the field's front edge, return 3 studs before it). Display only, per client, for every player's own plot; numbers are the `PARK_*`
constants in `PetFollow`.

**Pets panel** (top-left **🐶 Pets** button): a summary line naming where the Coin bonus comes from ("Coin bonus +12 % · 2 cute pets with
you"), filter chips (All n/50 · With me · On the field · Best for ▼ Coins / Tending / Pest control / Scouting: the pets with that trait,
highest first; kept for the session), the pet list and the three equip slots. A row (`PetRow`, shared with the food stand): portrait with
a **level badge** and a status corner icon (✓ with you, 🌾 on the field), the name in the rarity colour, one **trait chip** per working
trait (icon + level in the trait's colour, a thin fill = progress to the next level, the same share as the pet page's bar; hover / hold
shows the exact numbers), a ▲ on the chip food and runs train now or "✔ Trained" when nothing can train, then an **Equip / Unequip**
brick and a **Details ›** brick. A tap on the rest of the row does nothing; selling is only on the pet page. 460 px wide, capped to the
screen and scaled down on short screens, where the tap targets grow to stay ≥ 36 px (44 at full size).

**Art.** Simple, cute blocky models built from parts, one per kind, in one style, in `ReplicatedStorage.PetModels` (real art can replace
them without code changes); rarity shows as label colour and a glow (Epic, Legendary). How a pet's look is derived (nothing about it is
stored) and how models are authored: [PET_GROWTH.md](PET_GROWTH.md). The design rules:
- **Growth:** size follows level, 1.0× at Lv 1 to 1.6× at Lv 20, for followers and field pets alike. The follower formation widens with
  the pets so they never overlap; while the owner's stage timer runs their pets drop 4 studs further back and turn ghostly so the course
  stays visible; pets close to the camera fade out.
- **Level-up moment:** spin, flash, sparks, a ring and a floating "Level N!" (about 2 s) for everyone nearby; the label shows one ★ per
  look tier (Lv 5 / 10 / 15 / 20, `PetConfig.Tiers`).
- **Tier effects** (rarity colour, cumulative): Lv 5 sparkle trail, Lv 10 soft aura, Lv 15 orbiting motes, Lv 20 hexagonal halo; accent
  parts drift toward the rarity colour with the level and turn Neon at Lv 20. Off beyond 60 studs from the camera.
- **Individuality:** every pet id gets its own colour variation and about half a material texture that spreads with the level (at most
  45 % of the parts at Lv 20); from Lv 10 one accessory, at Lv 20 two, chosen from the pet id and kind (no wings on winged pets, no horns
  on horned pets, no crown together with horns).

### 7.6 Pet garden
*Plots, incubators and feeding; every plot also has the crop field and field pets (§7.9).*

A free area reached on foot from the central island, where pets are raised and crops grow. Aimed at players who prefer collecting and
caring over obby runs.
- **Where.** A separate island in the same place (not a separate place), joined to the central island by a short wooden bridge (~33
  studs; no portals). Both islands share one look (part-built grass islands on a rock base, cobblestone plazas, hedge rings, blocky trees
  and flowers) and stand in one sea that is also the world's kill floor.
- **Layout.** A central plaza (food stand, seed stall) surrounded by a ring of **8 plots** 45° apart (radius 112; the bridge path runs
  through the middle of one gap), on an island 390 studs across with its hedge ring at radius 190. A plot is about 40 × 40 studs: a
  40 × 21.5 front strip, the field behind it (§7.9). The strip holds, as seen from the plaza: the **hatchery** on the left (the 3
  incubators as open hatch pods in a triangle under one tall stud pavilion roof on four posts), the **barn** on the right (a red stud
  barn with a stepped gable, white X-brace doors swung open towards the plaza, a hayloft window and a weathervane with a pet; it shows no
  stock, the barn panel lists it), a gravel **path** between them from the sign to the field, so the field shows from the plaza, and the
  **owner name sign** (stud look, raised on two posts so players walk under it; the owner's name, or "Free plot", no plot number; under
  it the likes and ribbons in words, §7.9) on the lawn in front of the strip. Servers hold **8 players** (one plot per slot). Each client
  draws the plots from the server's data. Free-to-move incubators / barn are not planned before the Estate drop (decor placement,
  EXPANSION D9 / E7); the fixed layout keeps the slots that drop can use.
- **Getting there and seeing what waits.** The leftmost **🏠 Home** icon (red brick) puts the player on the grass in front of their plot
  from anywhere (a running timer is cancelled; a toast says so while no plot is assigned yet). Every join starts the player at this same
  spot, facing their own field (later deaths keep the checkpoint / respawn behaviour). A red **badge** on Home counts what waits: ripe
  crops + eggs ready to hatch (none at 0; a pulse when the number rises). Over the own plot's name sign a **summary bubble** (own plot,
  owner only) reads e.g. `🧺 4 ripe · ⏱ 2:14 · 🥚 Ready!` with only the parts that apply: ripe crops, the time to the next ripe crop while
  something grows, an egg ready; nothing planted → `🌱 Plant seeds`; the crow forecast joins it near crow time (§7.9). It ticks every
  second (server time), keeps one size on screen, draws over everything and shows within 120 studs of the sign or anywhere on the
  central plaza. A crop counts as ripe once its time is up (the server settles the field before a harvest).
- **Personal plot.** A player borrows a free plot while online: it is assigned on join, built from the profile, and released on leave. The
  plot's contents are saved in the profile and restored on any server. Growth and hatching run on server time, so they do not need the
  plot to exist while the player is offline. Everyone can walk through the garden and look at all plots and pets; only the owner can use
  their own plot (no stealing, no shared fields).
- **Incubators.** Every egg hatches here, in real time, and keeps hatching offline. Each plot has **up to 3 incubators**, unlocked in
  order for 0 / 500 / 2 800 Coins (3 300 in total). Only owned incubators appear in the world, at every detail level; a bought pod
  appears as soon as the purchase succeeds. An egg is bought for an empty incubator of the player's own plot (prices and the crops that
  open the dear eggs: §7.2); its kind is rolled and stored at purchase, and its rarity sets the wait. A ready egg waits until the owner
  taps **Hatch**; the stored pet is granted and equipped automatically when a slot is free (§7.3). An egg can only be started while the
  pets plus the eggs already incubating stay below the inventory cap (50), and a ready egg does not hatch into a full inventory (it
  waits).
  - **Look.** Every egg is a portal-style cross-lapped brick shell of nine tapered courses in the gem's colour (`EggLook`, shared with the
    3D shop previews; Topaz, Ruby and Diamond carry a light, Diamond sparkles). A pod is an **open arch body**: steel stud-brick side
    walls with cream caps step up to a steel headboard (rear heater on it, facing the egg), a striped cream / steel arch bridges the
    walls over the egg's back half and carries the two-sided number plate, the control module stands on the base ledge outside the right
    wall; every part rests on the one below it, the front stays open, footprint 6 × 6. Pods and egg face the central path towards the
    barn (plot-local −X). Detail levels full / mid / low use 59 / 13 / 8 body Parts and 27 / 9 / 5 egg bricks.
  - **Phases.** Empty pods are unlit. The first **30 s** of the hatch duration scan: a cyan eight-sided contour ring hugs the egg while it
    rises and falls (4 s), a bright head with a fading trail circles it (3 s a lap), and **Scanning…** shows above it; no countdown yet.
    Then an amber nest outline / soft light pulse with the hatch countdown; at full detail the heater flickers like embers and lights the
    egg like a heat lamp, amber sparks drift up and two pink brick hearts float up in turn. Ready eggs keep green indicators with the
    heater off. Mid detail has a static phase strip, low stays simple. `StartedAt` / `ReadyAt` keep phases aligned across reconnects;
    instant-ready eggs skip scanning.
  - **Labels.** Empty / locked labels and egg countdowns show only on the own plot while the character is near its nests (enter at 28
    horizontal studs from the nearest nest, exit beyond 30; fading out from 24 to 30), draw on top of the world (AlwaysOnTop) and show
    only status above the plate. Other players see the egg models without text and cannot use them.
  - **Hatchery panel.** Opened from the **🥚 Hatchery** farm HUD button beside Barn within 45 horizontal studs of the own plot (its badge
    counts ready eggs), or by clicking / tapping any owned pod from either side (generous target, whole-pod hover outline; GUI and range
    checks block world clicks; no E prompt, other players' pods have no click target). Opening never hatches an egg, closes the other
    panels, and walking 32 studs away closes it. Group boxes separate **Your nests** from **Eggs to buy**. The three incubator rows
    carry little text and keep one size in every state (picture, title, one line): a growing egg has the field card's progress bar
    ("42% · 2 h 40 min"; empty with **Scanning…** at first, as the time would give the rarity away) and a trash button; a ready one a
    **Hatch** brick; an empty one a dim "Empty" bar; the next incubator to buy an Unlock brick with its price (two taps over 1 000
    Coins), a later one a dim bar with its price. **Egg cards** are always shown: each egg (in its colour, name, possible hatch-time
    range, a price brick or the crop that opens it; Golden takes two taps) and a **?** brick with its odds (a rarity / percentage table
    and only the offline-hatching / no-refund tip; hidden roll mechanics stay out of the player-facing text); a card starts the egg in the
    first empty incubator. With none empty the price bricks turn grey and the group is headed **No free incubator**. Successes show in
    the rows; only a refusal (and waiting free eggs) gets a status line.
  - **Hatch reveal** (`HatchReveal`, about 4 s, a click / tap skips to the summary): the egg wobbles and hops, harder each time (Epic /
    Legendary once more), the last wobble glowing in the rarity colour; a flash, the shell's upper bricks fly off; the pet's portrait pops
    in with rays in the rarity colour, the rarity stamps in, confetti from Rare up. The **summary** shows the portrait, the kind in the
    rarity colour, the rarity with the egg's chance of it ("Epic · Topaz egg: 12.7 % chance"), where it went (with you / the Pets panel),
    the pet count (n / 50), one row per trait it was born with (level / rarity cap and what it does; shown one by one, a cute pet is a
    lucky roll), a line on how traits grow, and **View pet** / **Great!**.
- **Feeding.** Food bought for Coins gives a pet XP: an alternative to leveling by playing the obby, and a Coin sink. Food is sold at the
  **food stand** in the middle of the plaza (a four-sided stud kiosk with a big strawberry on top) and fed at once to one chosen pet
  (equipped, on the field or resting); there is no food inventory. Only the fed pet gains the XP, as care XP (§7.4: Cuteness first, up to
  the food limit). A pet at its food limit cannot be fed (no Coins taken; the row shows "🏃 Grows with you now" or "Max level"); XP it
  cannot use is lost, which the food button's tooltip says. The panel shows the Pets panel's row with the chip the food will train
  outlined; pets with you first, then those food can still train, those at the limit greyed at the bottom; it scales down to fit a phone.

  **"Bigger pets eat more":** the XP stays; the price below is for a level-1 trait of a Common-Epic pet and is × 2.65^(b − 1), b = the base
  level (`PetConfig.BaseLevel`) of the trait the food trains, and × 10 for a Legendary, nice-rounded (`GardenConfig.FoodPrice`), read at
  feeding; the buttons show the price for that pet. A Feast for a Cuteness-8 Epic costs 28 000, for a Cuteness-8 Legendary 280 000. Food
  to the limit (cheapest mix): Common-Rare 1 500, Epic 7 370, Legendary 200 100; a Legendary work trait 1 183 000.

  | Food | Price (level 1) | XP | Coins per XP |
  |---|---|---|---|
  | Berry | 50 | 25 | 2.0 |
  | Cake | 400 | 250 | 1.6 |
  | Feast | 1 500 | 1 000 | 1.5 |

### 7.7 Trading
Players on the same server can trade pets and Coins (after 1.0). Both players confirm the final offer; the server swaps everything at
once, saves both profiles immediately and logs the trade. Pets in an open trade are locked, and a short cooldown applies after each
trade. Trading requires profile session locking (a profile is open on at most one server), otherwise items could be duplicated across
servers.

### 7.8 Pet page and names
- **Pet page.** A row's **Details ›** brick opens the pet's page: a turning portrait, name, rarity, tier stars and where the pet is; one
  card per working trait (`PetConfig.Shown`), titled in the trait's colour and icon, the one food trains now outlined with a ▲ like the
  row's chip: Cuteness (level / cap, Coin bonus, XP), Tending, Scouting, Pest control (level / rarity cap, effect, field hours to the
  next level, reach, the food limit); the Feed card below them (crops, §7.9; its first line says what food trains now and up to which
  level, or that the pet grows with you now); Equip / Unequip; Rename; at the bottom under "More" "Place on field" (§7.9) and a small
  grey **Sell** brick (two-tap confirm: first tap orange "Sure? +N", second within 3 s sells). Built for 8–10 year olds on a phone:
  bars, stars and icons over text.
- **Names.** 1–20 letters, digits and spaces; clearing is free, the first name is free and every later one costs 250 Coins
  (`PetConfig.RenamePrice`); 10 s cooldown. Filtering is a Roblox rule: the server filters with `TextService` (owner, `PublicChat`),
  stores the raw text, filters again on every join, and only the filtered text leaves the server; a failed filter shows the kind name.
  Names show to everyone ("Mochi Lv 6") through the `PetNames` attribute and are never localized.

### 7.9 Crop field
Every player has the crop field. Exact numbers live in `CropConfig` / `PetConfig` / `GardenConfig` and are pinned by `tools/economy.py`;
why they are what they are: [ECONOMY.md](ECONOMY.md); what comes next: [EXPANSION.md](EXPANSION.md). *Decided, not built (after 1.0,
ROADMAP → EV2c / EV2d / EV2f):* Sunshine for repeat finishes (§5), Scouting XP from timer seconds, and field-pet changes (Tending as
growth speed, guards that make their squares safe from crows, crows scaling with the field). The rules below are the current ones.

**Crop art.** Every crop grows continuously, with stable variation tied to each planting and visible harvest-size differences; ripeness
is readable from shape and colour. Nearby and mid-distance art keeps the crop's identity, distant art is hidden. Full art reaches 60
studs on phones and tablets and 230 on desktops (every other plot from the own plot), stepping down to 170 / 120 / 60 on a desktop whose
frames are slow; a Graphics Quality set low by hand gets 60. A crop clears at harvest (Frost Grape, a tall vineyard trellis, sheds a
frost burst; its perennial regrowth is future work). Art authoring and per-crop status: [PLANT_GROWTH.md](PLANT_GROWTH.md); designs:
`docs/plants/`.

- **Goal.** Farming is the main game: over days 1–3 the field earns about what the obby earns, then 3× by day 7 and 10× by day 30
  (Casual, Garden main), checked by `economy.py check`.
- **Field.** Behind each plot: **78 squares** in rows 6-6-8-8-8-8-8-8-6-6-6, centred on an 8-column grid, numbered row by row from the
  plot (the numbers are stored: never reorder the rows). A new field opens the 2 × 2 block at the front centre (squares 3, 4, 9, 10) with
  4 free Potato seeds. Any locked square (overgrown: grass tufts, no price in the world) can be bought from its square card; the price
  depends on how many are open (Coins only): a ladder up to the 36th square (40 M; ×1.33 a square after the 28th), then a flat 40 M up to
  the 78th, whichever square is picked.

#### Where the field's panels are
There is no Garden panel; each piece sits where it is used.
- **Barn** (own plot): the barn building's "Open barn" prompt and the bottom-centre HUD brick "🧺 Barn" (within 45 studs of the own plot,
  and anywhere outside a run while crops are held; a corner badge counts the crops held: green, red when the barn is full) open the barn
  panel (480 px): a ticking crow forecast line, **Seeds** with the barn's fill ("Seeds · 18 / 40", red when full) and one line per seed
  with its grow time (Growth upgrade included), **Harvest** with one row per crop: the ★ brick (crop page), count and record, and the sell
  bricks **1 / 10 / All** with what that sale pays under each ("💰 69", pet bonus and Value point included). No feeding here: it is on
  the pet's page. The server accepts Sell from anywhere (`usableField(..., true)`), the field actions only near the own plot.
- **Seed stall** (`Workspace.Garden.SeedStall`, Studio-only, on the plaza beside the food stand): its counter prompt "Buy seeds" (E, 10
  studs) opens the stall panel (480 × 520). *Seeds tab:* the market cart's offers ("New offers in" countdown; one buy takes all that is
  left at the offer price) and the seed catalogue: "Growth: 16 s · Sells 💰 9", **+1 / +10 bricks with their price under the label**, and
  under the grow time "≈ 12 800 an hour per square" ((sale with Value points − seed) per grow hour on this field, Growth and Speed
  included: how the player compares crops whose price per harvest does not follow the order); no mastery line (the ★ brick opens the crop
  page). The next locked crop shows the previous crop's count toward it ("🔒 🥔 8 / 12") or, for a quest crop, one row per quest crop
  with brought / needed / held and a **Bring** button; later locked crops collapse into one grey line of icons; rare crops say from which
  world's medals. *Sell tab:* per crop **1 / 10 / All** with the Coins it pays (sizes pro rata, pet bonus included). A board above the
  counter lists the day's cart offers. BuySeeds / BuyCart are accepted within 20 studs of the counter only; the panel closes beyond that.
- **Rotating stock** (`CropConfig.Stall`; ECONOMY.md → Decisions "ST"). The stall restocks every UTC hour, the same on every server.
  Always in stock: Potato, Lettuce, Onion, the newest unlocked crop (the one whose bar opens the next), the newest unlocked crop of at
  least 6 h (`Stall.LongSeconds`: every night has a long crop) and every crop a talent's next level or the open quest asks for. Every
  other unlocked crop rotates: in stock about 2 hours of 3 (a draw from the hour and the crop, at least every 3rd hour), then 12 seeds
  per player for that hour; out of stock or sold out the row stays with a grey "Back soon". The panel counts down to the next restock and
  changes without a rejoin; a player in the garden gets a toast if a crop of theirs rotated in. Seeds already bought keep. *Why:*
  planting was too linear; a stall that does not offer everything makes the player plant what is there, gives online news, and slows the
  mid game (the model's Casual top crop ~day 18 instead of 13). The market cart stays apart (daily bargains, the taste).
- **Skills panel, Garden tab** (the Obby tab holds the talents): the Growth / Barn upgrades and the tools, buyable anywhere (Coins only).
  **Pets panel:** the field pet slot line (pets on the field / slots) with "+1 slot" (buyable anywhere).
- The crow forecast also shows in the summary bubble ("🐦 0:45" within an hour of crows, "🐦 now!" while they are on); the join notice
  stays a toast (after 30+ min away: the ledger, below). Spend confirmation and panel focus: §7.10.

#### Seeing and acting on the field
- **Rings (Near tier).** Within 30 studs of the own field every planted square shows a ring (own plot only): a dark disc whose pie fills
  as the crop grows, the crop icon inside; a ripe crop gets a full green pie, a ✓ badge, a small bounce and a bigger disc, while growing
  rings are smaller and dimmer; the 4 growing squares nearest the player also print the time left. All rings sit at one height straight
  up (the tallest planted crop's ring height), drawn 3 studs toward the camera so the crop does not hide them. *Why:* rings at their own
  crop heights, offset along the camera's up, slid over other rows on a steep view; one height keeps them a grid over the field.
  Other plots show only their crops and pets. A field pet's label is its given name (if any) over its job icons `🌱4 🛡2`, never its
  level.
- **Empty soil.** An open square without a crop has pale dry soil (every plot), so empty squares read apart from planted ones at any
  angle without an extra marker.
- **Tap a square.** No prompts on the field (the incubators keep theirs). A tap / click on a square of the own field (within 20 studs of
  the plot and its field, `GardenConfig.FootprintDistance`; the server allows 25) outlines it in white and slides the **square card** up
  from the bottom (header "Field square", close button above the scrolling content; the scrollbar appears only when the content exceeds
  the safe area). The **Crop** group box: an empty square shows only **Plant**; a growing crop its icon and name, a bar "42% · 3 h 40
  min" (share, never 100 % before ripe; away-time left), a red trash brick that digs it up (two-tap confirm, seed lost) and "Grows
  faster while you play"; a ripe crop only **Harvest**. The **Pets** group box: the resident pet is one row (portrait, name, job icons, ›
  opening its page in the Pets panel) with a grey X brick that takes it off the field; with no resident only **Place pet**. Under it two
  permanent indicators on every open square, "🌱 Tending 68%" and "🛡 Pest control 84%" (the strongest of each reaching the soil from
  any pet, dimmed at 0 %). No Move button: the destination square's picker moves a pet. The selected square again, a tap off-field or
  walking away closes the card; on touch it clears the controls. The client sends only square / crop / pet ids; the server validates
  everything.
- **Pet picker** ("Choose a pet for this spot"; 600 px wide, one bordered inset per row holding portrait, description and action; the
  whole picker scrolls under the fixed header). Top line: "Field pets" with one box of pips per field pet slot (🌾 on wood = taken; wood
  outline = owned and free; faint grey 🔒 = still to buy) and the "+1 slot" brick (two taps; gone at the last slot); the Pets panel's slot
  line is the same helper (`GardenUi.FieldSlots`). Rows: rarity by colour only; where the pet is now in brackets ("(with you)",
  "(elsewhere on the field)"); one job line "🌱 Tending Lv 7 (works one square) · 🛡 …"; a compact **Place pet** brick, followers
  included. Order: placeable first, then rarest, then Tending, Pest control. Capacity blocks first: a pet that cannot be placed has a
  dimmed row and a grey "🔒 Place pet" whose tap pulses the slot box and the "+1 slot" brick (no message). Field pets reuse their slot;
  the server validates, then unequips and assigns together. No square numbers in any picker, location or placement toast.
- **Hand bar.** While the tap range applies, four bricks: 🌱 Seeds, 🧺 Basket, 🐾 Pets, ✋ Look (default); a row at the bottom right with
  a mouse, a 2 × 2 block above the jump button on touch. Keys 1–4 act as a click on the brick in that order (ignored while typing or
  with a panel open). The active one is raised and framed; a line above says what a tap does. White
  corner brackets mark the own square under the mouse (the cursor turns into a pointing hand), else the square the character stands on
  (always so on touch), never the selected one (brackets, not an outline, so they never look like a reach border). *Seeds:* a seed is
  selected at once (the last picked while any is left, else the first held; when it runs out, the next at once), outlined in the
  card, which picks another; every tap on an empty open square plants it. *Basket:* every tap on a ripe square harvests that one (never all:
  harvest-all is a planned paid Wheelbarrow, D2). *Pets:* a tap on a placed pet takes it in hand (its reach tinted; on touch a first tap
  on a free square shows the reach, a second drops); an occupied destination keeps the held pet; a free square with nothing in hand opens
  the picker; the pet's own square or 🐾 again cancels. Any other tap selects as in Look. Every field action is queued and sent at most
  every 0.25 s (the server drops actions under 0.2 s apart), so quick taps are never lost. Every harvest pops "+1 🌽" (plus Big! /
  Giant!) over its square. Next-step hint: Seeds pulses while nothing is planted and seeds are held, Basket while something is ripe,
  each until used once in the session.
- **Placing and moving a pet** uses the real field and reach preview, with a compact Cancel strip by the hand bar; no field-grid dialog.
  The pet page's "Place on field" (for a pet with Tending or Pest control, followers included) checks capacity before closing the Pets
  panel and taking the pet in hand. Cancel / Escape keeps the original assignment; a submitted placement waits for the server answer (a
  refusal preserves the selection); following stops only after a successful placement.
- **Reach borders.** Every placed pet's region is outlined by thin strips in its rarity colour (not glowing: Common grey must not look
  like the white select outline): the squares it counts for, i.e. per square the strongest Tending pet and the strongest guard (ties to
  the lower uid). Regions that share an edge draw side by side (three lanes inset 0.45 / 0.8 / 1.15 studs).

#### Crops, growth and selling
- **Crops.** Potato (20 s away / 10 s online, so the first harvest comes in the first session), Corn, Pumpkin and Giant melon from the
  seed stall behind mastery unlocks; three rare crops, one per world (Golden carrot 25 000, Frost grape 75 000, Glow mushroom 150 000
  Coins), only from the obby (below), never sold as seeds, never eaten by crows. Growth runs on server time: online ×2, offline ×1 for
  at most 24 h per absence, settled on join, on leave, every 60 s and before every action; ripe crops wait. Listed durations and
  countdowns show away-time seconds, shortened by Growth and crop Speed; the countdown ticks ×2 faster while playing, additionally
  multiplied by Cloches (×2.4 at the top). Growth pauses after 24 h away. User decision: the exact online rate is not shown (the square
  card only says "Grows faster while you play"; Cloches states its own bonus), and the cap is not explained (every crop ripens within
  one 24 h absence, so it only limits replanting by Tending pets). The actual online `readyAt` drives art, ripe badges and Harvest. The
  barn holds 40 seeds and 40 stored crops (+20 per Barn level). Seeds held can always be planted; the stall sells only unlocked crops.
- **Fruit trees** (TR; rules EXPANSION §5.4): a sapling is a seed of the tree and is named as the tree everywhere it is meant (stall,
  barn, seed picker, hand bar, results popup, toasts: "Apple tree" / "Jabloň"); the fruit keeps the crop name. Stall row: grow-up time,
  time per fruit and sale, "You have 1 of 3", one +1 brick at the next sapling's price, a grey "Max 3" at the limit (the rare tree:
  "Medals in World 1"). Square card: a young tree has the growth bar to its first fruit, the trash and "Once grown, it bears fruit for
  good"; a grown tree, bare or bearing, has the same parts: "🍎 2 / 4 · next in 12 min" ("full" at the cap) beside the trash, then Pick
  all (grey while bare). A pick pops "+3 🍎" and toasts "+3 Apple · biggest 0.7 kg". Rings: a bearing tree the ripe ring with "3/4";
  tree rings sit at the tree's own height and stay out of the shared ring height.
- **Seed picker** (a square's Plant, or the card in Seeds mode): one row per held seed with the crop and ★, the stall's grow time and
  sale line, and the count on the right; in Seeds mode only the selected row is green, with a ✓. Six rows before it scrolls.
- **Price ladder.** Six price tiers set net Coins per square-hour (tiers 0–2 × 1.727 a step, then × 1.5; the top tier × 10.1 of Potato's);
  grow time is a choice inside a tier (away-time): Potato 20 s, Lettuce 1 m, Onion 2 m | Garlic 6 m, Tomato 16 m, Cucumber 30 m | Corn
  15 m, Pepper 2 h, Broccoli 8 h | Pumpkin 12 h, Eggplant 5 h, Blueberry 20 m | Sweet potato 6 h, Giant melon 14 h | Sunflower 10 h,
  Pineapple 30 m (ECONOMY.md → Decisions (FL)). A later crop can therefore sell for less per harvest than an earlier one (Pineapple 8 500
  after Pumpkin 90 000). A `Grown` already stored stays; the next join credits its pending absence at the current rate.
- **Selling and feeding.** A crop is sold from anywhere (Barn button, stall Sell tab; a young field gets a toast and a pulsing button):
  sale × its size, through `CoinRewards.Grant`; a sale over 1 000 Coins takes two taps. Or it is fed to any pet (from its page) for its
  crop XP (half the sale) × the Berry's level-1 price ÷ the Berry's price for that pet (`GardenConfig.CropFeedXp`: Corn gives a
  Cuteness-1 Common 600, a Cuteness-8 Epic 31, a Cuteness-8 Legendary 3), up to the food limit, so feeding is never better than selling
  and buying food at any level or rarity; a crop worth < 1 XP to that pet is refused and left out of its Feed card.
- **Size roll.** Every planting rolls a size factor (lognormal, mean exactly 1, 0.36–2.64), fixed by owner and planting number so a
  re-join cannot reroll it; Big = top 20 %, Giant = top 3 %, a record per crop, weight shown as kg × factor. The barn keeps a count and
  the summed size per crop; selling k of n pays the average size.
- **Crop mastery** (`CropConfig.Mastery`, why in ECONOMY.md → EV3). Every harvest of a common crop (by hand or a Tending pet; not the
  Shears' extra, not a rare crop) counts one plant of it (`Garden.Crops[id].N`); ★1 / ★2 / ★3 at 25 / 75 / 200 plants, shown as "Mastery
  ★" on the stall, barn and square card, with a toast at each star. Quick crops need more for ★2 / ★3 (`Mastery.LevelsBy` by base grow
  time): ≤ 10 min (Potato, Lettuce, Onion, Garlic) 25 / 225 / 600, ≤ 1 h (Tomato, Cucumber, Corn, Blueberry, Pineapple) 25 / 110 / 300. A
  level never drops: it is at least the points spent on the crop (`MasteryLevel(crop, n, pts)`). The common crops open in list order:
  the next crop at the previous one's `step` plants (12 for Lettuce … 25), except Corn, Pumpkin and Sweet potato, which open by a
  **milestone quest** (crops handed in piece by piece with Bring, from anywhere, no expiry; the last piece gives 4 seeds of the new crop,
  past the barn limit). Seeds are bought only for unlocked crops; seeds held (cart taste, obby) can always be planted and count toward
  that crop's ★, not its unlock. **Rested mastery** is silent (user decision: never shown or announced): each day away past the first
  adds 0.5 (cap 3) to a pool in units of the harvested crop's `step`; while it lasts a plant counts double. Squares, upgrades and tools
  cost Coins only. Profiles from before mastery migrated once (`Version = 7`): unlocked = the crops their old Renown level had opened plus
  every crop held or grown.
- **Crop upgrades** (`CropConfig.Mastery.Points`, model `economy_ev` `pt_*`). Every ★ of a common crop gives one point, spent on any of
  the crop's three lines, up to 3 in one (`Points.PerLine`; user decision: a ★3 crop can be all Speed). n points in a line: **Price**
  (sale × (1 + 0.11 n), at sale time, also for crops already in the barn), **Size** (every later harvest's size factor × (1 + 0.11 n),
  also a growing crop's look; the plant art stops at the old maximum, `SizeBounds(true)`, sale and records keep the full factor; the Big
  / Giant label comes from the roll with the Sorter but without the Size points, else nearly every harvest would be Big) and **Speed**
  (grow time × (1 − 0.11 n): the crop's growth rate × 1 / (1 − 0.11 n) from the moment the point is spent, growing crops included). A
  maxed crop earns × 1.44 (3 Price or 3 Size) to × 1.49 (3 Speed) per square-hour, one point each × 1.47: 2.0–2.2 steps of the price
  ladder. Prices on the stall rows, the barn's Sell and grow times follow the points. The star toast adds "A point to spend: tap ★ in the
  barn". **No reset** (decided, not built): later a paid comfort (D2) or an event item; by EXPANSION §13 rule 4 a paid reset needs that
  earnable path too; a reset only moves points, never adds any.
  - **Crop page** (a ★ brick on the stall's and the barn's crop rows, "★+" on green while a point is free; the Goals panel's *Upgrades*
    section lists such crops). Titled with the crop and the player's rank in it, one per star count: Rookie / Apprentice / Expert / Master
    ("🥒 Cucumber Expert"; Czech "Okurka · Odborník"). A star track: the crop's icon and the three ★ evenly spaced on one bar, each star
    one point (gold = earned, a green "+1" while its point is unspent, faint = still to grow), the segment toward the next star is the
    progress bar ("30 / 225") with each star's plant count under it; one fixed line: "1 point to spend: pick an upgrade", "Fully
    upgraded!" or, with no point free, "Each ★ gives 1 point. A spent point stays.". Three cards (icon tile, name, the effect as numbers
    with the new value in green: "Sells for 9 → 10", "Average 0.28 → 0.31 kg", "Grows in 0:16 → 0:15 away", a column of square pips
    aligned across the cards) carry a green Upgrade brick (two taps) only while a point is free; a full line shows ✓, else the slot stays
    empty. Every state keeps the same parts and sizes, so spending a point moves nothing under the pointer. Four stat tiles close it (the
    crop's history, not the barn's stock): grown, biggest harvest, Coins earned (sales and request bonuses, `Garden.Earned`, counted only
    from 2026-11-24) and crop-of-the-week wins (`Garden.Ribbons`).
- **Upgrades and tools.** Growth (4 levels, −5 % grow time each) and Barn (5 levels, +20 each). Tools: Seed sorter (sizes × 1.05 / 1.10 /
  1.15), Cloches (online growth +7 / 14 / 20 %), Pruning shears (5 / 10 / 15 % chance of a second crop of the same size, rolled per
  planting).
- **Market cart.** Offers per UTC day, the same on every server, counts per player: 10 seeds of an unlocked crop at −30 %, 5 of another at
  −50 %, and from the Garlic unlock a taste of 2 seeds of the next locked crop at the catalogue price.

#### Goals: tracker line, Goals panel, requests
- **Tracker line.** Outside a stage a wooden line under the coin plate (in the old score panel's place; on a stage the run view stays:
  stage name, record or "First try!", medal limits) shows the next crop's goal with a bar: "🥔 8 / 12 → 🥬 Lettuce", or for a quest crop
  its least-done piece (brought / needed); hidden once every crop is open. It pulses when the goal moves on. A tap opens the **Goals
  panel** (player-facing "Quests" / "Úkoly": "Cíl" is the finish portal): *Next crop* with how it opens and the count bar, or the quest's
  pieces with Bring buttons that work anywhere (the server takes from the barn); *Today's requests*; *Upgrades* (only while a crop has a
  free point, a row per crop with a button to its crop page). It replaces a separate request board; hints stay where they are used (the
  stall's locked-crop bar, the skills panel's bundles). The panel is meant to grow into a quest book after 1.0 (talent and world
  unlocks, mastery collection, streak; a drop adds a section, not a panel). Open: the world star count left the HUD (the world gates
  still show their star bar): check in play that nobody misses it.
- **Line 2** shows the day's request nearest to done ("🍅 4 / 6 → 💰" and a bar), under line 1 or in its place, unless the player ticked
  another one with the eye button (👁, while 2+ are open; client-only, kept for the session, dropped when the UTC day's board changes; a
  done request falls back to the nearest). *Today's requests* lists the three: "Grow 6 × 🍅 Tomato", the reward in Coins (pet bonus
  included) and a bar; a done one shows "Done! ✔" and the time to the next UTC day; before they open: "Requests open when you unlock 🧄
  Garlic".
- **Requests** (rules in `CropConfig.Requests`, server `GardenRequests`). Three tracked requests, "grow 6 Tomatoes": every crop of that
  kind that goes into the barn counts (by hand, a Tending pet, the Shears' extra); nothing is handed in. Crops: unlocked common crops
  from Onion on that need ≤ 8 h baseline growth (≤ 4 h online; Onion … Eggplant); the board opens when two qualify (the Garlic unlock) and
  picks different crops (seeded by player, UTC day and slot). Size: 0.3 × a day's income (crop sales + request bonuses of the previous
  UTC day or today, the higher, at least 2 000) ÷ the crop's sale with the pet bonus, 3 to half the barn. A finished request pays 0.6 ×
  the count's sale (+ pet bonus) at once with a toast, and one in three also drops a rare seed of the highest world with a finished
  stage or a free egg (half and half; Pearl, Topaz once Pumpkin is open, §7.2). An unfinished request stays; finished slots refill on the
  next UTC day. No timed run and no Sunshine yet (EV2c).

#### Field pets, obby seeds, crows
- **Field pets.** Every pet has aptitudes (§7.1: Cuteness, Tending, Pest control, Scouting; stored but not yet rolled: Fertilising,
  Weeding, Crafting; levels 1–20 up to its rarity's cap), rolled once from its uid (the count by rarity, the kind leans the draw) and
  never rerolled; a hatch while the owner has no Tending pet gets Tending. Food and obby XP also train the work traits up to the food
  limit (§7.4). A pet with Tending or Pest control can stand on a square (one per square, not equipped; 1 free field pet slot + 4 bought).
  Reach by the job's level: its square (1–3), plus its 4 neighbours (4–6), the 3 × 3 block (7–10); on overlaps the strongest pet of a job
  counts. **Tending** works only during absences: a crop that ripens in reach is harvested with the pet's strength (20 % at level 1 to
  100 % at 10) while the barn has room, then replanted from the seeds held (rolled once per planting). Placed pets gain aptitude XP on a
  separate work clock: online ×1, offline ×0.5 (24 h cap), unaffected by crop rates, Growth, crop Speed or Cloches; aptitude XP per
  weighted work hour (level L → L + 1 takes 10 × 1.56^(L−1) h). A profile from before the field converted once on join
  (`Garden.Converted`): the old pens became field pet slots (1 pen = 1, 2–3 = 2, 4–6 = 3; pen prices beyond the slots' value refunded),
  penned pets went back to the inventory.
- **Field pet idle (PL1, client only).** A placed pet within 90 studs of the camera breathes and, every few seconds (sooner at
  higher look tiers), looks around, hops, sits up, shuffles along its square's edges to sniff towards the crop and back, or naps
  under a floating 💤 (at most once per 90 s) with its eyes shut; near the camera it blinks (PL2). It never leaves its square, and
  its label stays still. Not in step between clients.
- **Obby seeds (world stages only).** The first Gold on a World 2 or 3 stage gives 1 rare seed of that world; the day's first medal
  finish gives 1 (once per UTC day); a rare-seed meter per stage (Bronze 1 / Silver 2 / Gold 3 points, doubled for the day's first finish
  there; 300 points = a seed). The **seed pouch**: the day's first medal finish on each stage gives 1 / 2 / 3 seeds of the common crop
  planted last, up to the barn. **Scouting** (equipped pets): 15 min of aptitude XP per medal finish; the scouts' bonus (up to +50 %)
  multiplies the meter points and at +50 % adds 1 pouch seed. The results popup lists every seed and the meter.
- **Crows.** From the Garlic unlock. The UTC day has four 6-hour blocks, a quarter of them crow blocks on a fixed schedule, shown as a
  forecast in the barn panel (and the summary bubble within an hour). On the join settle, after Tending, every ripe common crop whose
  ripe time overlaps a crow block is rolled once (30 %); a lost roll eats it unless the strongest guard reaching the square wins its
  chance (50 % + half the Pest-control strength, doubled for the crow speciality). At most 1 crop is eaten per absence; crops ripe while
  the owner plays are safe. A pet with Tending and Pest control does both jobs.

#### Join notice, Harvest Hall, likes
- **Join notice.** What the pets harvested (and the shears' extras), what the crows ate and who chased them off. After an absence of 30
  min or more it is the **"While you were away" ledger**: a centred panel, once per session, with the time away ("7 h 20 min", "2 d 3 h")
  and the lines that apply, in order: 🧺 the pets' harvests (3 crops, then "+ n more") and the biggest of them ("a giant 🍅 Tomato, 2.4
  kg"), 🐦 crows ate / a guard chased them off, 🌱 ripe crops waiting, 🥚 eggs ready, 🏆 "Crop of the week" ribbons won at this join, 📜 new
  requests. With nothing to say it does not open. It waits for the end of a stage run, closes with its button or a tap outside, and is
  information only. Under 30 min a toast stays; the old-pen conversion is always a toast.
- **Harvest Hall** (rules in `HallConfig`). On the west half of the hub plaza: a pedestal per crop (the ladder in order, the rare crops
  last) and the all-time record board beside the star board. Every crop that goes into a barn (by hand, a Tending pet, the Shears' extra)
  counts: the **week's biggest** of each crop (top 3, Monday 00:00 UTC to Monday) and the **all-time** top 3, shared by every server. A
  pedestal shows the week's #1 in its grown art at its size (a crop without art: its icon) with a label: avatar, name, kg, #2 and #3 and
  the viewer's own best when it is not on the list; an empty pedestal has the plaque "Grow the biggest!". A harvest that takes a week's
  #1 and is Big or Giant pops a toast for everyone on the server (at most one a minute). A week's #1 earns a **ribbon**
  (`Garden.Ribbons[crop]`; players see it as "crop of the week") once that week is over, shown on the plot sign as "🏆 3× crop of the
  week"; no Coins. Size comes only from the roll, the Seed sorter and the Size line (EXPANSION §13: nothing sold touches size).
- **Plot likes.** Another player's plot sign has a "Like ❤" prompt: once per plot per UTC day per player, never the own plot. The owner
  (always on the same server: plots exist only for present players) gets a toast "{name} likes your garden ❤", and the count shows on
  the sign ("12❤", centred, with a gap before the ribbons); `Garden.Likes` is the total (the garden score uses it later, D9).

### 7.10 Garden and pet UI rules
*Principles behind the garden / pet UI (§7.5–7.9); new UI follows them.*
- **See before you open.** Everything a player checks often (time left, what is ripe, which pet works where) shows in the world; panels
  are for decisions (buy, sell, choose). Distance tiers: Far (≤ 120 studs and from the plaza) the summary bubble, Near (≤ 30 studs) the
  rings and reach borders, Focus the selected square and its card.
- **One thing under your finger.** A square is picked by tapping / clicking it, never by standing next to it; no overlapping prompts.
- **One place per kind of thing:** crops held → barn, seeds bought → seed stall, permanent upgrades → Skills, a pet → its pet page.
- **Kid on a phone:** icons, bars and rings over numbers; numbers on hold / hover / second tap; tap targets ≥ 44 px (36 px on compact
  rows); every new piece is checked on a phone, Czech widths included.
- **Comfort planned for sale stays for sale:** no harvest-all (Wheelbarrow, D2), no instant grow.
- **Feedback where it happened:** a pop over the thing (the harvest pop over the square), not only a toast. Locked squares look different
  from empty soil (grass tufts vs pale dry soil; the price only in the square card).
- **Stable layout:** a click never makes panel content jump: the same parts and sizes in every state (crop page, square card).
- **Refused buy in a row** (Skills panel, both tabs): what is short is already highlighted on the brick; a tap on it is answered on the
  client at once (no request): the brick shakes (`UiKit.Shake`) and a red plate over the row's name and effect says what is missing for
  2.5 s ("Needs: 💰 1 200 more, Cucumber 5/20", `UiKit.Notice`). A refusal from the server shows the same way on that row, never as a
  toast.
- **Two-tap confirm** (`ConfirmTap`): every spend over 1 000 Coins (`THRESHOLD`) and every Sell takes two taps: the first turns the
  button orange ("Tap again" / "OK?") for 3 s (`SECONDS`), a second tap in that time fires; waiting, or closing the panel, disarms it.
  Spends at or under the threshold fire on the first tap; a spend the player cannot pay fires at once so the server's "not enough Coins"
  answer shows. The armed state is kept by key, so a panel that rebuilds its rows between the two taps keeps it. The food buttons keep
  their own confirm; hold prompts only in the world.
- **Panel focus** (`PanelFocus`): opening the Pets, Skills, Barn, Seed stall or Food panel closes the one open before; Pets, Skills and
  Barn close when the player walks 32 studs from where they were opened (`WALK_AWAY`), the two stalls beyond 20 studs from their counter.
- **Input:** garden dialog surfaces consume blank-area input (`InputSink.All`, `Active` false on passive containers); field tap / hover
  uses the shared UI hit-test across dialogs; panels refit to the live safe area and reflow on resize.
- **Open (only if a phone check or later play asks for it):** a field-camera button that tilts the camera down over the own field; "Show
  on field" on the pet page (marker + camera hint to its square); moving field pets from far away (EXPANSION §3); other players' summary
  bubbles (biggest crop); a public barn display (a shelf of record crops in grown art); more feedback pops (crop flying to the barn,
  Coins to the counter, XP to the pet). Touch taps on squares (`TouchTapInWorld`, the two-tap drop) were checked on desktop only.

## 8. Leaderboards
- **Per stage:** a Top-10 fastest-times board in every stage's courtyard (the Tutorial included).
- **Hub:** global "most stars" Top-10 (3★ per stage: 48★ with the Tutorial and the 15 built stages, 63★ with all 20 planned, +3 per bonus
  stage); each world island gets a world board with the stars in that world. The leaderstats column is "Stars". The board stands on the
  grass behind the Harvest Hall, beside the all-time record board (§7.9).
- **Harvest Hall:** the week's biggest crop of every kind and the all-time records (§7.9).
- Open question: show the talents used next to a time, or keep a separate "no-talent" board? Possible later: "rarest pets" / "highest
  pet level" board.

## 9. Monetization (comfort only)
The product list and offer rules are in [EXPANSION.md](EXPANSION.md) §13; the shop ships as M7 (drop D2).
- **No paid random items.** Eggs are never sold for Robux, and neither is anything that buys an egg: Coins, seeds, crops and the seed
  shop's stock are never sold for Robux (no Coin packs). Eggs stay Coins-only (whether eggs stay at all is open, EXPANSION §16); the egg
  UI keeps showing the odds.
- **Luck and weather are never sold.** Egg odds, harvest size and variant chances come only from play: Coin-bought tools, crafted
  fertilisers, pets and the weather schedule.
- **Robux buys comfort:** time (longer offline cap, instant grow, faster incubators), capacity reached sooner (pet slot, post,
  incubator), cosmetics (trails, skins, portal effects, pet accessories, decor), skip stage. No 2× Coins pass: it is neither earnable
  nor capped.
- Rule: everything purchasable that changes the economy must also be earnable through play and capped, so money only speeds progress up.
- Leaderboard fairness (§1, pillar 3): nothing bought affects a stage time; a skipped stage gives no time, no medal and no payout.

## 10. Balancing & telemetry
- **Measuring `T_base`:** developer runs each stage clean, no talents beyond the stage's requirement, 3 attempts, take the median.
- **Telemetry:** every finish (stage, time, talent levels, pet multiplier) and every egg purchase (egg, rarity); events and how to read
  them: [TELEMETRY.md](TELEMETRY.md).
- **Re-tune when:** Gold rate < 10 % among players with the designed talent set, or > 60 % of finishers stop at Bronze, or a stage's
  unlock is bought more often than earned, or garden income exceeds the obby first-hour income (pillar 2).
- **Player feedback** (only for us, never shown to players; shared numbers in `FeedbackConfig`).
  - *Stage rating:* a post sign in every world stage's courtyard, beside the gate and Top-10 leaderboard without covering either: "Did
    you like Stage 3?" with two thumb plates 👍 / 👎 (ProximityPrompts drawn as a small key badge under each thumb; a click / tap on the
    badge votes too). Anyone near the sign may rate, finished or not; one rating per stage and player, changeable any time, the own
    choice lit, no score shown. The per-stage counts (`StageRatings` DataStore) keep finishers and non-finishers apart; telemetry
    `StageRating` carries how far the player got (medal / finished / furthest checkpoint this session / none), so ratings by players who
    never tried can be left out. Input for M6b. The Tutorial has no sign.
  - *Rating on the results popup:* after a world-stage finish the results popup asks "Did you like it?" with 👍 / 👎 too: the same vote
    as the sign (either one changes it, both show it), taken from anywhere for `PopupSeconds` (120 s) after that finish.
  - *Feedback box:* Settings → "✉ Send feedback" opens a panel: category Bug / Idea / Other (one must be picked), a box of at most 300
    characters with a counter, "Don't write your name, address or any contacts.", Send. 3 messages a player per UTC day. The text is
    filtered by Roblox before it is stored (`PlayerFeedback`, with category, area, language and place version); a failed filter call
    stores nothing. We read the store through the MCP / Open Cloud; no admin list in the game.
  - Plot likes (§7.9) double as a signal of which gardens interest people.

## 11. Player guidance (hints)
**HUD navigation.** The desktop uses the top-left row: Home (own farm, with the ripe-crop / ready-egg badge), Gateway, Skills, Pets,
Settings, plus Admin for admins. Buttons, dialog title strips and HUD plates share one look: smooth top edges, rounded corners, dark
outlines, the brick lift / press animation, a faint tiled stud texture in dialog headers. Gateway (blue brick, 🌀) returns from a world
stage to its gateway plaza, then from the plaza (or anywhere else) to Central Island; both travel buttons cancel a running timer. On a
touch screen whose safe short edge is at most 600 px, the 50 px buttons form a two-column block (110 × 170 px including the admin row);
on landscape screens at least 600 px wide, panels align with the block's top and open to its right (x = 130); on narrower or portrait
screens a panel replaces the block, and its close button restores navigation. Panels fit the safe area, their lists scroll, layout
updates when the screen rotates, badges stay attached to their buttons. Skills, Settings and Admin start closed on joining; within a
session the open / closed choice survives respawns.

**Compact dialog chrome.** Titles and square X / back controls, Barn's HUD button and skill purchase buttons target 40 px on screen
after UIScale; Skills / Seed stall tabs and pet filters 36 px; these use a shallower 3 px brick lip. Other action buttons keep their
heights.

A player who finishes a stage, earns Coins or waits for an egg should always see what they can do next without reading anything. One
client-side system draws every such hint (`Hints`, `HintSources`), so the game speaks one visual language. Hints are local to the player
and display only: they read state the client already has (attributes, leaderstats, incubator models) and never ask the server for
anything.

**Onboarding.** A new player is walked through the first ten minutes by the same signals, never by text boxes or locked controls: 1 hatch
the starter egg (the Hatchery button pulses) → 2 plant the 4 start Potatoes (Seeds pulses) → 3 harvest (Basket) → 4 sell (Barn button)
→ 5 buy seeds (an orange marker "Buy seeds" over the seed stall) → 6 put the pet on the field (Pets) → 7 open the Goals panel (its line
pulses) → 8 finish a stage (the next-stage marker). The server keeps the finished steps (`Onboard`, a bit mask; `OnboardConfig`) from
the actions themselves; the hint is always the lowest unfinished step, a step done off the path is kept and skipped. Every join already
starts at the own plot, so there is no "go to the garden" step. Players who had harvested before onboarding existed start as done. The
`GardenStart` funnel (TELEMETRY) logs the steps plus the first finished request and the first return on a later day.

**Three kinds of signal, each with one job:**

| Signal | Answers | Look |
|---|---|---|
| World marker | *Where do I go?* | a chunky orange down arrow with a white outline and a label (the stage's name, "Ready!"), bobbing above the target; drawn on the screen at a constant size, so a sign or a wall never hides it. It points at the target at the player's height (a gate's doorway, never the point above its sign): while that spot is in view the arrow stays above it pointing down; otherwise it sits on the screen edge nearest the target and turns to point at it (a target behind the player goes to the nearer side edge, at mid-height). The edge area keeps clear of the top-left icons, the score panel and the bottom 30 % (touch controls). Orange and the arrow are used for nothing else (green and ticks mean "done") |
| HUD dot | *Which button?* | a red dot on the top-right corner of a top-left icon (and of a button inside a panel); one pulse when it appears, then still |
| HUD badge | *How much waits there?* | a red pill with a number on the top-right corner of a top-left icon (Home: ripe crops + ready eggs); none at 0, one pulse when the number rises |
| Toast | *Something happened elsewhere* | one line at the bottom of the screen for a few seconds, once per event |

**Rules (they keep the hints from becoming noise):**
- Flag only what pays off now: something to claim, or something the player can afford. Never "you could, if…".
- A shop dot clears once seen: it lights when an offer *becomes* affordable that was not affordable the last time the panel was open, and
  opening the panel clears it (the seen list lasts for the session). A reward waiting to be claimed (a ready egg) keeps its dot and
  marker until it is claimed.
- No blinking: a dot pulses once when it appears, a marker only bobs.
- Quiet during a run: markers hide, toasts wait until the run ends; dots stay.
- At most one world marker per area (a world courtyard, the hub, the garden).

**Hints:**
- **Next stage:** the latest stage in game order that is open for the player and has no medal yet, so players are pushed forwards (a
  player with World 2 open is sent to Stage 6, not back to an unfinished Stage 5); when the latest open stage already has a medal (e.g. a
  world bar not met yet) the latest open one still without a medal is used. When every open stage has a medal and a world opener's star
  bar shuts the next stage (e.g. Bronze on all of World 1 = 5 of the 10 stars World 2 needs), the marker goes to the open stage of the
  world the bar counts with the lowest medal (ties: the earliest, usually the easier one), labelled with the medal to reach ("Stage 3:
  Silver"). None when every open stage has a medal and no star bar shuts anything (Gold chasing has the mastered badge, §3). Its marker
  (labelled with the stage's name) stands above the stage's start gate while the player is in that stage's courtyard (the Tutorial: near
  its landing pad), above the hub entrance (the world's hub gate, the Tutorial's hub portal) while the player is in the hub or the
  garden (in the garden a ready egg's marker wins), and above the portal back to the hub while the player is in another courtyard or the
  Tutorial. It hides within 25 studs of its target, so the player who lands in front of a gate after a finish without a medal is not
  pointed at the gate behind them.
- **Stuck fallback** (a young player kept retrying Stage 5 because the marker kept sending him there): after 3 runs of the next stage
  that ended without a medal (given up or too slow; runs under 10 s do not count, walking out through a gate starts and ends a ghost
  run; a run of another stage started without ending this one also counts) or 12 deaths during its runs (Quick Respawn fall resets
  count as deaths), in this session, the marker moves to the open stage of the **same world** with the lowest medal (ties: the
  earliest), labelled with the medal to reach ("Stage 1: Silver"): the stars that can still open the next world. It never points into
  another world, so a player with World 2 open is still sent there. No other stage to improve: the marker stays.
- **Skills:** a dot on the Skills icon when a talent level became affordable that the player has not seen affordable with the panel open
  (the panel's green Buy brick already marks the row).
- **Ready egg:** counted in Home's badge (with the ripe crops, §7.6); a marker ("Ready!") above that incubator while the player is in the
  garden; a toast "Your egg is ready!" once per egg (also on joining with an egg already ready).

**Later, if playtests ask for it:** an affordable gate unlock (the gate prompt covers it up close), a short ground trail from the Arrival
to the next gate after a finish, a "Next: <stage>" line in the results popup.
