# Oby sandbox — Game Design Document

Status: **draft**. All numbers are placeholders until `T_base` is measured in the M6 balancing pass
(see [ROADMAP.md](ROADMAP.md)). This document says *what* the game is; the roadmap says *how and when* it is built.

**Coin scale (2026-10-17, R2):** every Coin amount (rewards, prices, sell values) is 10× the first draft, so small
percentage bonuses show up in single payouts and numbers feel like a Roblox pet game. Balances stored before the change
were multiplied by 10 once. Percentages, odds and times are unchanged.

## 1. Pillars
1. **Short, readable stages** — each stage is a 1–3 minute run with a clear finish.
2. **Mastery pays most** — medals and fast times pay the most Coins. Repeating a stage still pays, but less with every
   run; slow or idle sources (pet garden) are a steady trickle, never the fastest route.
3. **Fair leaderboards** — nothing that affects a leaderboard time can be bought with Robux. Pets never change
   movement or stage times; talents do, but are earned with Coins only (provisional, see §9).
4. **One hall, many games** — the central island hosts several minigames (obby first, pet garden next, more later).
   They share one currency (Coins) and one pet collection, so progress in any game helps in the others.

## 2. Core loop
```
run a stage → medal by time → Coins (one-time per medal tier + diminishing repeat reward)
     ↑                                   ↓
faster runs / harder stages  ←  talents + stage unlocks

Coins (from any minigame) → eggs, pet slots → pets → Coin bonus + pet levels → more Coins
```
Secondary loops: talents (e.g. double jump) open new routes → challenge coins on already-cleared stages;
pets level up while you play; the pet garden (§7.6) raises pets and produces Coins over time, also offline.

## 3. Stages

The game grows to **20 numbered stages in 4 worlds of 5** plus the Tutorial (plan and design reasons:
[STAGES.md](STAGES.md); decided 2026-10-21). Only the Tutorial and today's three stages exist; every other row is
**planned** (P) and gets its scope when its milestone starts. The display number is the position in the game
(`order` / `displayName` in `StageConfig`); the internal **key and folder never change** (new stages get a semantic key
equal to their folder, e.g. `IslandHop`; checkpoint blocks of 100 per new stage, STAGES §7.4).

| # | World | Stage | Internal key | Built | Required talents | Unlock |
|---|---|---|---|---|---|---|
| T | – (hub) | Tutorial | `"Stage 4"` ¹ | yes | – | always open |
| 1 | 1 | Stage 1 (Island Hop) | `IslandHop` | P (S4.1) | – | Bronze on Tutorial **or** 500 |
| 2 | 1 | Stage 2 (today's first stage) | `"Stage 1"` | yes | – | Bronze on Stage 1 **or** 1 000 |
| 3 | 1 | Stage 3 (Blink ★ rhythm) | `Blink` | P (S4.2) | – | Bronze on Stage 2 **or** 1 500 |
| 4 | 1 | Stage 4 (today's second stage) | `"Stage 2"` | yes | – | Bronze on Stage 3 **or** 2 000 |
| 5 | 1 | Stage 5 (today's third stage), finale | `"Stage 3"` | yes | – | Bronze on Stage 4 **or** 2 000 |
| 6 | 2 | Double Up | `DoubleUp` | P (S6) | Double Jump | World gate ² **or** 2 500 |
| 7 | 2 | Seesaw | `Seesaw` | P (S6) | Double Jump | Bronze on 6 **or** 3 000 |
| 8 | 2 | Turntable | `Turntable` | P (S6) | Double Jump | Bronze on 7 **or** 3 000 |
| 9 | 2 | Labyrinth ★ iso maze | `Labyrinth` | P (S6) | Double Jump | Bronze on 8 **or** 3 500 |
| 10 | 2 | Clocktower, finale | `Clocktower` | P (S6) | Double Jump | Bronze on 9 **or** 4 000 |
| 11 | 3 | Triple Peaks | `TriplePeaks` | P (S8) | Triple Jump | World gate ² **or** 4 000 |
| 12 | 3 | Ice Rink | `IceRink` | P (S8) | Triple Jump | Bronze on 11 **or** 4 500 |
| 13 | 3 | Dash Bridge | `DashBridge` | P (S8) | Triple Jump, Dash | Bronze on 12 **or** 5 000 |
| 14 | 3 | Laser Lab ★ side-scroller | `LaserLab` | P (S8) | Triple Jump, Dash | Bronze on 13 **or** 5 500 |
| 15 | 3 | Rising Tide, finale | `RisingTide` | P (S8) | Triple Jump, Dash | Bronze on 14 **or** 5 500 |
| 16 | 4 | Wall Climb | `WallClimb` | P (S10) | + Wall Jump | World gate ² **or** 6 000 |
| 17 | 4 | Glide Canyon ★ dropper | `GlideCanyon` | P (S10) | + Glide | Bronze on 16 **or** 6 500 |
| 18 | 4 | Moon Base | `MoonBase` | P (S10) | all so far | Bronze on 17 **or** 6 500 |
| 19 | 4 | Clockwork | `Clockwork` | P (S10) | all so far | Bronze on 18 **or** 7 000 |
| 20 | 4 | Summit, finale | `Summit` | P (S10) | all talents | Bronze on 19 **or** 7 500 |

¹ Existing DataStore key; keep it so recorded times are not lost. Today's keys never change either; only their `order`,
`displayName`, bar and price do (S1.1 / S4). Folder and key names above for planned stages are proposals, fixed at creation.
² **World opener** (stages 6, 11, 16): **10 of the 15 stars of the previous world** (decided 2026-10-21; 10 = Silver on
every stage of the world, provisional) **or** the price. This needs a new unlock rule type (stars in a world) next to
the medal-on-previous-stage rule, built in S1.1. The previous rule (Silver on the finale) is not used.

**Shown names are positions** (decided 2026-10-21): the signs, boards, popups and panels read "Stage 1" … "Stage 5" for World 1 (`StageConfig.displayName`; the internal key never changes); names like Island Hop / Blink are working titles of the new stages and may become subtitles later.

The Tutorial belongs to no world (decided 2026-10-21): it stays a hub stage, its stars count in the total and on the hub
board but not toward a world, so World 1 is exactly 5 stages = 15 stars and the opener rule "10 of 15" stays exact.

★ = the world's special stage (plays differently from a normal obby, STAGES §5). **Bonus stages** (S11, STAGES §5.3) come
on top: not numbered, outside the unlock chain (no bar, no price; each opens with its world), reward factor 1.0, medals,
Top-10 board and challenge coins like any stage; their stars count toward the total (+3 each).

Prices follow `price(n) ≈ medal total of stage n−1, rounded to 500` (stage 1: 500); buying every unlock costs 81 000
(skipping stays possible and expensive). Today's bars and prices change with the re-order (Stage 1: Bronze on Island Hop /
1 000; Stage 2: Bronze on Blink / 2 000; Stage 3: Bronze on Stage 2 / 2 000), applied in S4 together with the new
stages so players never see a gap in the numbering; nothing is live yet, so no grandfather rule is needed if this lands
**before the first live test**.

**Required talents** are shown, never enforced: the hub portal and the unlock popup list "Needs: …", arriving without a
required talent shows a warning with a button to the Skills panel, and entry stays open. The course geometry is the real gate.

**Checkpoints** (H2) are square stud plates (16 × 12) across the course with a small green tile in the middle. Only the
player's current checkpoint (the respawn point) glows, and only for that player: its tile grows into a larger glowing
square with a column of light rising from it (about 1 s) and the previous one turns back. The first reach in a run also
plays a sound; walking back to an earlier checkpoint moves the respawn point there silently. Passing the stage's start
gate counts as reaching its first checkpoint; a new run turns the lit pad back.

**Unlocks.** Every stage after the Tutorial opens either by **meeting the bar** (required medal on the previous stage)
or by a **one-time Coin price**. Prices are set so that buying an unlock costs roughly a full talent level or two —
skipping is possible but slows talent progress. Unlocks are permanent. Each stage can be bought on its own (Stage 3
does not require Stage 2 to be open). Times or medals already recorded on a locked stage do not open it (no grandfathering
of pre-M3 progress), and admins follow the same rules. The first stage's bar is deliberately low (Bronze, ≈ 48 s on the Tutorial)
and its price is a small convenience: a new player has 0 Coins, so the Tutorial is the real way in, and the Tutorial
must always stay completable.

**Hub portals** show: stage name, locked/unlocked, requirement + price when locked, best medal earned,
and challenge coins found `x/y`.

## 4. Time tiers
Each stage has `T_base` = time of a clean run by the developer **with exactly the talents the stage requires** (none on
the Tutorial and stages 1–5). Default thresholds (tunable per stage):

| Medal | Stars | Threshold | Intent |
|---|---|---|---|
| Bronze | ★ | ≤ 1.6 × T_base | finishable by any player who owns the required talents (none on World 1) |
| Silver | ★★ | ≤ 1.1 × T_base | clean run; early talents help |
| Gold | ★★★ | ≤ 0.8 × T_base | requires the talents of the stage's designed set (§6) and a good route |

Run Speed and Jump Height never become requirements; they stay the way to faster medals and shortcuts.

`T_base` is provisional; ranges are STAGES §4's, the thresholds below use the midpoint (planned stages: P).

| Stage | T_base (s) | Bronze | Silver | Gold |
|---|---|---|---|---|
| Tutorial | 30 | ≤ 48 s | ≤ 33 s | ≤ 24 s |
| 1 Island Hop (P) | 45–60 → 52 | ≤ 83 s | ≤ 57 s | ≤ 42 s |
| 2 Stage 1 | 70 | ≤ 112 s | ≤ 77 s | ≤ 56 s |
| 3 Blink (P) | 70–90 → 80 | ≤ 128 s | ≤ 88 s | ≤ 64 s |
| 4 Stage 2 | 100 | ≤ 160 s | ≤ 110 s | ≤ 80 s |
| 5 Stage 3 | 120 | ≤ 192 s | ≤ 132 s | ≤ 96 s |
| 6–10 (P) | 80–100, 90–110, 90–120, 90–120, 120–150 | 1.6 × | 1.1 × | 0.8 × |
| 11–15 (P) | 100–120, 110–130, 110–130, 120–150, 130–160 | 1.6 × | 1.1 × | 0.8 × |
| 16–20 (P) | 110–130, 90–130, 120–150, 130–170, 160–200 | 1.6 × | 1.1 × | 0.8 × |

Every run stays within pillar 1 (1–3 minutes). Provisional `T_base` values (set in M1 so tiers can be evaluated) are
rough guesses — Stage 1 is consistent with the existing board (best 50 s → Gold, 104 s → Bronze). They are replaced by
measured values in M6 (M6a for World 1, M6b for the rest).

Timer precision: tenths of a second (server-measured). A run starts at `TimerStart`, ends at the finish portal,
and is cancelled by leaving through `TeleportToSpawn`.

Medal rules:
- A finish slower than the Bronze threshold earns no medal and no Coins (the time still counts as a personal best).
- A player's medal on a stage is the highest tier ever reached; it is never revoked, also not when thresholds are retuned.
- Best times recorded before medals existed (pre-M1) do not grant medals retroactively; the next finish does.
- After every finish a results popup shows: time, personal best (or "New record!"), the medal of this run,
  Coins paid (medal payout and repeat reward), and the threshold of the next medal not yet earned.

Limits are visible before and during a run:
- **Score panel** (on arriving at a stage): all three limits, e.g. `★ 1:52  ★★ 1:17  ★★★ 0:56`; tiers already
  earned are gold. On the hub it shows the total stars earned.
- **Stage timer** (while running): next to the time, the best medal still reachable and its limit
  (`00:41.3  ★★★ 0:56`); when a limit passes it drops to the next tier, after Bronze to "no medal".
- **Hub portals**: earned stars are drawn on the portal face itself (part of the gate, not camera-facing).

## 5. Rewards
All Coins earned by playing (medal payouts, repeat rewards, challenge coins, garden production, future minigames)
are paid through one server function and multiplied by the player's pet bonus (§7.3). Purchases are not.

### Medal payouts (one-time per tier, per player)
Base payout Bronze 200 / Silver 400 / Gold 800, × stage factor. Reaching a higher tier directly also pays the lower
tiers not yet earned (a first-try Silver pays Bronze + Silver).

**Stage factor** by display number `n`: `factor = 0.5 + 0.25 × n` (decided 2026-10-21); the Tutorial stays at 0.5. Today's
stages move along the curve: Stage 1 (n = 2) 1.0, Stage 2 (n = 4) 1.5, **Stage 3 (n = 5) 1.75 instead of 2.0**
(Coins already paid are unaffected). Bonus stages use 1.0. Stage total = 1 400 × factor.

| Stage | Factor | Bronze | Silver | Gold | Stage total |
|---|---|---|---|---|---|
| Tutorial | 0.5 | 100 | 200 | 400 | 700 |
| 1 Island Hop (P) | 0.75 | 150 | 300 | 600 | 1 050 |
| 2 Stage 1 | 1.0 | 200 | 400 | 800 | 1 400 |
| 3 Blink (P) | 1.25 | 250 | 500 | 1 000 | 1 750 |
| 4 Stage 2 | 1.5 | 300 | 600 | 1 200 | 2 100 |
| 5 Stage 3 | 1.75 | 350 | 700 | 1 400 | 2 450 |
| 6–10 (P) | 2.0 … 3.0 | | | | 2 800 / 3 150 / 3 500 / 3 850 / 4 200 |
| 11–15 (P) | 3.25 … 4.25 | | | | 4 550 / 4 900 / 5 250 / 5 600 / 5 950 |
| 16–20 (P) | 4.5 … 5.5 | | | | 6 300 / 6 650 / 7 000 / 7 350 / 7 700 |
| **All 21** | | | | | **88 200** (World 1 with the Tutorial: 9 450; today's four stages 6 700, was 7 000) |

### Repeat reward (every finish, diminishing)
Every finish with a medal also pays

```
run reward = max(10, round(50 × stage factor × medal multiplier × 0.8^n))
```

where the medal multiplier is that **run's** medal (Bronze ×1, Silver ×1.5, Gold ×2) and `n` is the number of earlier
finishes of that stage by the player **today** (UTC day; resets at midnight UTC). A finish without a medal pays 0.
It is paid on top of any medal payout, also on the first finish.

| Stage | First run Bronze | Silver | Gold | Gold, sum of the first 10 runs of a day |
|---|---|---|---|---|
| Tutorial | 25 | 38 | 50 | 227 |
| Stage 1 | 50 | 75 | 100 | 446 |
| Stage 2 | 75 | 113 | 150 | 668 |
| Stage 3 (factor 1.75) | 88 | 131 | 175 | 781 |

New stages follow the same formula with their factor. After 8–14 runs (Gold: Tutorial from run 8, Stage 3 from run 14, later stages later) a stage pays the floor of 10 Coins per run until the
next day. Faster medals pay more, grinding runs out quickly,
and switching stages is better than repeating one (pillar 2). All values provisional.

### Challenge coins
Placed off the main path, behind risky jumps, or reachable only with talents. Each coin is collected
**once per player**, saved, and hidden only for that player. Values: easy 20 / risky 50 / talent-gated 100, **flat on
every stage** (decided 2026-10-21: no scaling with the stage factor). Planned stages carry about 8 coins each (5 easy,
2 risky, 1–3 talent), roughly 160 in total. From World 1 on, a talent coin needs a talent the stage does **not** require
(one from a later world), so finished stages are worth revisiting after each new talent.

| Stage | Coin budget (Coins) | Placed mix |
|---|---|---|
| Tutorial | 120 | 2×50, 1×20 (behind the score board) |
| Stage 1 | 280 | 4×20, 2×50, 1×100 |
| Stage 2 | 380 | 4×20, 2×50, 2×100 |
| Stage 3 | 480 | 4×20, 2×50, 3×100 |
| **All** | **1 260** | 27 coins |

Talent-gated coins need Double Jump (placed out of reach of a Jump Height 3 jump). All four stages have their coins
(M4 first batch: Tutorial + Stage 1; M4.1: Stage 2 + Stage 3).

**One-time total of today's four stages: 6 700 (medals) + 1 260 (coins) = 7 960 Coins** (all 21 planned stages:
88 200 medals + roughly 8 000 coins at about 400 per stage), plus repeat rewards, garden production and the pet bonus,
which have no fixed cap.

## 6. Talents
Bought in the skills panel (top-left). Permanent, server-owned, applied on every spawn.
The current admin toggles (run speed 16↔64, 5 air jumps) remain debug tools only. The admin panel's **Reset Score**
is a debug full reset of the admin's **own** progress (Coins, times, medals, unlocks, coins found, talents, own Top-10
entries), confirmed by a second click; it never affects other players and the server ignores it from non-admins.

| Talent | Levels | Effect per level | Cost per level | Total |
|---|---|---|---|---|
| Run Speed | 5 | +6 % WalkSpeed (16 → 20.8 at max) | 200 / 400 / 600 / 900 / 1 300 | 3 400 |
| Double Jump | 1 | one extra jump in the air | 1 500 | 1 500 |
| Jump Height | 3 | +8 % jump height | 300 / 600 / 1 000 | 1 900 |
| **Today's tree** | | | | **6 800** |

**Planned talents** (P; STAGES §6.2; ids never renamed; all client-driven, level server-owned as `Talent_<id>`; Run Speed
and Jump Height stay soft, never required). Only talents that are hard gates can be *required* by a stage.

| Talent | Id | Effect | Levels | Cost (prov.) | Total | First required at |
|---|---|---|---|---|---|---|
| Quick Respawn (P, S2) | `QuickRespawn` | utility, **never required**: level 1 respawns after 1 s instead of 3 s, level 2 instantly and adds a fall reset to the checkpoint; the timer keeps running | 2 | 1 000 / 3 000 | 4 000 | – |
| Triple Jump (P, S7) | `DoubleJump` level 2 | 2 air jumps (reach about 19 studs) | +1 level | 5 000 | (DJ total 6 500) | stage 11 |
| Dash (P, S7) | `Dash` | in the air, a short horizontal burst (about 10 studs in 0.2 s), once per air time; key + mobile button | 1 | 8 000 | 8 000 | stage 13 |
| Wall Jump (P, S9) | `WallJump` | against a wall in the air, jump kicks up and away; does not refill air jumps | 1 | 10 000 | 10 000 | stage 16 |
| Glide (P, S9) | `Glide` | hold jump while falling: fall speed capped at about 8 studs/s | 1 | 12 000 | 12 000 | stage 17 |

**Full planned tree: 45 800** (Run Speed 3 400 + Jump Height 1 900 + Double Jump 1 500 + Triple Jump 5 000 + Quick Respawn
4 000 + Dash 8 000 + Wall Jump 10 000 + Glide 12 000). Talents compete with pets, pens and incubators (about 56 500
together) for the same Coins.

### Economy constraints (must hold after every rebalance)
The economy is open (repeat rewards, garden, pet bonus), so "earnable" is no longer a cap. The constraint is about
the **no-grind path**: a player who only plays each stage until its medals are earned, with no pets.
Gold on each stage is designed around a talent set; that set must be affordable from one-time income earned *before*
that Gold (all medals on earlier stages + Bronze/Silver on this stage; challenge coins come on top).
Repeat rewards and pets only add to this, so the tables are lower bounds.

**World 1 Gold sets** (medal Coins only, new factors):

| Gold on | Designed talent set | Cost | Earnable before | OK |
|---|---|---|---|---|
| 2 Stage 1 | Run Speed 2 | 600 | 700 + 1 050 + 600 = 2 350 | ✔ |
| 4 Stage 2 | Run Speed 3 + Double Jump | 2 700 | 700 + 1 050 + 1 400 + 1 750 + 900 = 5 800 | ✔ |
| 5 Stage 3 | Run Speed 5 + Double Jump + Jump Height 2 | 5 800 | 7 000 + 1 050 = 8 050 | ✔ |

**Required talents** (a player must be able to afford the required set before the stage that first needs it, from the
medals of all stages before it):

| First required at | Required set | Cost | One-time medals before | Share | OK |
|---|---|---|---|---|---|
| 6 | Double Jump | 1 500 | 9 450 | 16 % | ✔ |
| 11 | + Triple Jump | 6 500 | 26 950 | 24 % | ✔ |
| 13 | + Dash | 14 500 | 36 400 | 40 % | ✔ |
| 16 | + Wall Jump | 24 500 | 53 200 | 46 % | ✔ |
| 17 | + Glide | 36 500 | 59 500 | 61 % | ✔ |

Share ≤ 65 % keeps talents a real investment without blocking the no-grind path. Run Speed and Jump Height could get more
levels later if Gold on Worlds 3–4 needs them (M6b).

### Coins per hour (open income, provisional)
| Source | Estimate | Notes |
|---|---|---|
| Obby, first hour of a day (Gold runs, all stages) | ~2 230 | first 10 Gold runs of each of the four stages (~40 runs), then the 10-Coin floor |
| Obby, later the same day | ~500 | 10 Coins per run at ~70 s per run (a ~25 s Tutorial loop pays ~1 400 / h; open, see M6) |
| Pet garden (§7.6) | target 200–1 000 | 6 mixed pets at Lv 5 ≈ 200 / h, a strong set ≈ 630 / h (≈ 940 with the pet bonus); offline production capped at 8 h (a strong set: ≈ 5 000 per 8 h) |
| Pet bonus | × 1.0–1.5 | on all of the above |

Sinks: talents (6 800 today, 45 800 planned), stage unlocks (5 000 today, 81 000 planned), eggs (§7.2), pet slots (7 000), garden pens (32 500), incubators (17 000)
and feeding (§7.6).

Notes:
- Bought stage unlocks are a sink outside the talent budget: a player who buys all three unlocks (5 000) is ~5 000 Coins behind
  and must earn it back — intended cost of skipping.
- Eggs and slots compete with talents for the same Coins; a player can choose pets first and talents later.
- Gold at 0.8 × T_base with only Run Speed 2 (+12 %) on Stage 1 needs a near-perfect route — verify in M6.

## 7. Pets
Pets follow the player, multiply Coin income and level up. They never affect movement, jumping or stage times.

### 7.1 Rarities and kinds
| Rarity | Base bonus | Sell value | Example kinds (prov.) |
|---|---|---|---|
| Common | +2 % | 100 | Cat, Dog |
| Uncommon | +4 % | 200 | Bunny, Fox |
| Rare | +7 % | 500 | Owl, Panda |
| Epic | +10 % | 1 500 | Dragon |
| Legendary | +15 % | 5 000 | Phoenix |

Every pet is an individual (own level and XP), identified by a unique id per player. Inventory holds up to **50** pets.
A pet can be **sold** back for its sell value (irreversible).

### 7.2 Eggs
Every egg hatches in an **incubator** of the player's garden plot (§7.6) in real time, also while the player is offline.
There is no egg stand on the central island (removed 2026-10-18). The odds are always shown before buying.

| Egg | Price | Common | Uncommon | Rare | Epic | Legendary | Where |
|---|---|---|---|---|---|---|---|
| Basic egg | 500 | 60 % | 25 % | 11 % | 3.5 % | 0.5 % | garden incubator, hatches in 5 minutes |
| Golden egg | 4 000 | – | 45 % | 35 % | 15 % | 5 % | garden incubator, hatches in 1 hour |

Free eggs:
- one Basic egg on the first join after pets launch (also for existing players),
- one Basic egg for the **first Gold on each stage** (4 in total).

A free egg starts by itself (no Coins) in the lowest empty incubator as soon as one is empty: on join, when the egg is
earned, after a hatch and after an incubator is bought. While every incubator is busy (or the inventory cap is reached) it
waits in the profile; the Pets panel and the incubator panel show how many wait.

### 7.3 Slots and Coin bonus
Up to 3 pets can be **equipped** (follow the player, count for the bonus). A newly hatched pet is equipped
automatically when a slot is free.

| Slot | Price |
|---|---|
| 1 | free |
| 2 | 2 000 |
| 3 | 5 000 |

```
pet bonus  = base bonus (rarity) + 0.5 % × (level − 1)
multiplier = 1 + min(50 %, sum of the bonuses of equipped pets)
paid       = round(base Coins × multiplier)
```
A level-20 Legendary gives +24.5 %; three strong pets hit the +50 % cap.

### 7.4 Levels and XP
Max level **20**. XP to go from level L to L+1: `round(10 × L^1.5)` (L1→2: 10, L5→6: 112, L10→11: 316,
L19→20: 828; ~6 700 XP from 1 to 20). Every **equipped** pet receives the full XP of each event:

| Source | XP |
|---|---|
| Finish with Bronze / Silver / Gold (the run's medal) | 5 / 10 / 20 |
| Finish without a medal | 0 |
| Challenge coin collected | +1 |
| Movement while a stage timer runs | 1 XP per 20 studs, max 30 per run |
| Feeding in the pet garden (§7.6) | per food item |

Movement is measured on the server (horizontal distance of the character); jumps faster than walking speed allows
(teleports, respawns) do not count, and nothing is earned outside a running timer, so AFK walking earns nothing.
Movement XP is paid at the finish, together with the medal XP; a run that is cancelled (back to the hub) earns none.
Levels are permanent. A pet at level 20 stops gaining XP.

### 7.5 Display
Equipped pets float behind their owner and are visible to all players, with rarity colour and level on a small label.
The pets panel (top-left **🐶 Pets** button) lists the inventory, equipped pets, slots, total bonus and XP bars.

**Art (first version):** simple, cute blocky models built from parts, one per kind, in one consistent style; rarity
shows as label colour and a glow (Epic, Legendary). Models live in `ReplicatedStorage.PetModels`, so real art can
replace them later without code changes.

**Growth (P1e1):** a pet's size follows its level, 1.0× at Lv 1 up to 1.6× at Lv 20 (linear), for followers and garden
pens alike. The follower formation widens with the pets so they never overlap, and while the owner's stage timer runs
their pets drop 4 studs further back and turn ghostly so the course stays visible; pets close to the camera fade out.
**Level-up moment (P1e2):** when a pet gains a level it spins faster and faster and rises, a bright flash covers the change from
the old look to the new one, then a burst of sparks, an expanding ring and a floating "Level N!" play and the pet drops back
(about 2 seconds), for everyone nearby (followers and, after feeding, garden pens); the label shows one ★ per look tier
(Lv 5 / 10 / 15 / 20).
**Tier effects (P1e3):** in the rarity colour, cumulative: Lv 5 sparkle trail, Lv 10 soft aura and rising sparks, Lv 15 three
orbiting motes, Lv 20 a hexagonal halo and a stronger aura; accent parts of the model (stripes, tail tip, belly...) drift toward the
rarity colour with the level and turn Neon at Lv 20; the float animation gets livelier with the tier. Effects switch off beyond
60 studs from the camera.
**Individuality (P1e4):** every pet id gets its own small colour variation (hue, saturation and brightness of the body, a pastel
tint for white / grey parts), so two Cats of the same level differ; 60 % of the Bunnies get a grey to near-black coat instead of white. About half of the pets also have a material "texture" (Fabric,
Marble, Granite, Slate, Pebble or Ice) that spreads over more body parts as the level rises (at most 45 % of the parts at Lv 20)
and never goes away. Accent parts, glow and tier effects use the pet's own shade of its rarity colour (a slightly different green for every Uncommon pet); the label keeps the exact rarity colour. 
**Accessories (P1f):** from Lv 10 a pet wears one small accessory, at Lv 20 two (crown, scarf, small wings, horns, flame tail; the Lv 20 halo is the tier
effect, not an accessory). Which pieces comes from the pet id and the kind (no wings on pets that have wings, no horns on pets that have horns or tufts, no crown on Bunny / Fox / Phoenix,
no flame tail on Owl / Panda, no crown together with horns); the Lv 10 piece stays and the second one is added at Lv 20. Details: [PET_GROWTH.md](PET_GROWTH.md).

### 7.6 Pet garden (minigame, P2)
A free area reached on foot from the central island, where pets are raised. Aimed at players who prefer
collecting and caring over obby runs.
- **Where.** A separate island in the same place (not a separate place), joined to the central island by a wooden
  bridge (no portals since H1). Both islands share one look (part-built grass islands on a rock base, cobblestone
  plazas, hedge rings, blocky trees and flowers) and stand in one sea that is also the world's kill floor.
- **Layout.** A central plaza (food shop) surrounded by a ring of **12 plots**, about
  40 × 40 studs each, with an owner name sign, pens and incubators. Servers hold **12 players** (one plot per slot).
- **Personal plot.** A player borrows a free plot while online: it is assigned on join, built from the profile, and
  released on leave. The plot's contents are saved in the profile and restored on any server. Production runs on server
  time, so it does not need the plot to exist while the player is offline.
- **Other players.** Everyone can walk through the garden and look at all plots and pets; only the owner can use their
  own plot (no stealing, no shared pens).
- **Pens.** A pet is either equipped or placed in a pen, never both. Pets in pens produce Coins over time by rarity
  and level. Pens unlock for Coins, in order. A penned pet gains no XP and does not count for the pet bonus (only
  equipped pets do); it cannot be sold while penned.

  | Rarity | Common | Uncommon | Rare | Epic | Legendary |
  |---|---|---|---|---|---|
  | Coins / hour at Lv 1 | 10 | 20 | 40 | 70 | 120 |

  Production per pet = rate × (1 + 0.04 × (level − 1)) per hour (Lv 20 = ×1.76). Pens: 6, prices
  0 / 1 000 / 2 500 / 5 000 / 9 000 / 15 000 (pen 1 free; 32 500 in total). Example sets (before the pet bonus):
  3 pens of Common/Common/Uncommon Lv 1 = 40 / h; 6 mixed pets (2 Common, 2 Uncommon, Rare, Epic) at Lv 5 ≈ 197 / h;
  2 Legendary + 2 Epic + 2 Rare at Lv 10 ≈ 626 / h (≈ 939 / h with the +50 % pet bonus); the theoretical maximum
  (6 Legendary Lv 20) is ≈ 1 267 / h.
- **Payout.** Production is paid through `CoinRewards.Grant` (the pet bonus applies) on server time only: every
  5 minutes while the owner is online, whenever the pens change (placing, removing, buying a pen settles first, so a
  pen never earns for time it was empty) and on join. Fractions of a Coin carry over, so the total over any split of
  time equals the exact production. The bonus is rounded per payout, which is why payouts are batched.
- **Incubators.** Every egg hatches here, in real time, and keeps hatching offline. Each plot has
  **3 incubators**, unlocked in order for 0 / 5 000 / 12 000 Coins (incubator 1 free; 17 000 in total). An egg is
  bought at an empty incubator of the player's own plot (Basic 500 Coins, ready **5 minutes** later; Golden 4 000 Coins,
  ready **1 hour** later, server time); free eggs start there by themselves (§7.2). A ready
  egg waits until the owner taps **Hatch** (with a reveal); the pet is rolled then and equipped automatically
  when a slot is free (§7.3). An egg can only be started while the pets plus the eggs already incubating stay below the
  inventory cap (50), and a ready egg does not hatch into a full inventory (it waits). Other players see the eggs and their
  countdown but cannot use them.
- **Feeding.** Food bought for Coins gives a pet XP: an alternative to leveling by playing the obby, and a Coin sink.
  Food is sold at the **food stand** on the plaza and fed at once to one chosen pet (equipped, penned or resting in the
  inventory); there is no food inventory. Only the fed pet gains the XP. A level-20 pet cannot be fed (no Coins taken);
  XP beyond level 20 is lost, so the panel shows how much a pet still needs. Feeding a penned pet settles its production
  first, so the new level only counts from then on.

  | Food | Price | XP | Coins per XP |
  |---|---|---|---|
  | Berry | 50 | 25 | 2.0 |
  | Cake | 400 | 250 | 1.6 |
  | Feast | 1 500 | 1 000 | 1.5 |

  Level 1 → 20 (~6 700 XP) costs about 10 000 Coins in Feasts.
- **Offline income.** On join, production since the last visit is paid, capped at 8 hours, and shown in a
  "while you were away" popup.

### 7.7 Trading (P3)
Players on the same server can trade pets and Coins. Both players confirm the final offer; the server swaps
everything at once, saves both profiles immediately and logs the trade. Pets in an open trade are locked, and a short
cooldown applies after each trade. Trading requires profile session locking (a profile is open on at most one server),
otherwise items could be duplicated across servers.

## 8. Leaderboards
- **Per stage:** Top-10 fastest times (exists for Stage 1 and 2; add Stage 3 and Tutorial).
- **Hub:** global "most stars" Top-10 (max 12★ with four stages; 63★ with the Tutorial and all 20 stages, +3 per bonus stage;
  each world island gets a world board with the stars in that world). The leaderstats column "Stage" (checkpoint number)
  is replaced by "Stars" in S1.2.
- Open question: show the talents used next to a time, or keep a separate "no-talent" board?
- Possible later: "rarest pets" / "highest pet level" board.

## 9. Monetization (deferred)
Not designed yet; decide after M6. Candidates: cosmetics (trails, skins, portal effects, pet accessories), convenience
passes (2× Coins, extra pet slot, faster incubators, skip stage), Coin packs. Rule for any candidate: everything
purchasable must also be earnable through play and capped, so money only speeds progress up.
Eggs are Coins-only for now. Selling random items (eggs) for Robux, or for anything bought with Robux, requires
disclosing the odds under Roblox rules — the egg UI already shows them. Leaderboard fairness (§1.3) is re-evaluated
at that point.

## 10. Balancing & telemetry
- **Measuring `T_base`:** developer runs each stage clean, no talents, 3 attempts, take the median.
- **Telemetry:** log every finish (stage, time, talent levels, pet multiplier) and every egg purchase (egg, rarity)
  to a DataStore / AnalyticsService funnel.
- **Re-tune when:** Gold rate < 10 % among players with the designed talent set, or > 60 % of finishers stop at Bronze,
  or a stage's unlock is bought more often than earned, or garden income exceeds the obby first-hour income (pillar 2).
