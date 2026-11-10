# Pawvest — Game Design Document

Status: **draft**. All numbers are placeholders until `T_base` is measured in the M6 balancing pass
(see [ROADMAP.md](ROADMAP.md)). This document says *what* the game is; the roadmap says *how and when* it is built.

**Coin scale (2026-10-17, R2):** every Coin amount (rewards, prices, sell values) is 10× the first draft, so small
percentage bonuses show up in single payouts and numbers feel like a Roblox pet game. Balances stored before the change
were multiplied by 10 once. Percentages, odds and times are unchanged.

## 1. Pillars
1. **Short, readable stages** — each stage is a 1–3 minute run with a clear finish.
2. **Mastery pays most** — medals and fast times pay the most Coins. Repeating a stage still pays, but less with every
   run. *Changed 2026-11-02 (farming first, §7.9):* within the obby mastery pays most, but the crop field is the main income
   (everyone has it since FA, 2026-11-06; the P2 pens are gone).
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
(`order` / `displayName` in `StageConfig`); the internal **key and folder equal the position** since 2026-10-22 (`Stage1` … `Stage5`, `Tutorial`;
they were `IslandHop`, `"Stage 1"`, `Blink`, `"Stage 2"`, `"Stage 3"`, `"Stage 4"` before; STAGES §7.4); checkpoint blocks of 100 per new stage.

| # | World | Stage | Internal key | Built | Required talents | Unlock |
|---|---|---|---|---|---|---|
| T | – (hub) | Tutorial | `Tutorial` ¹ | yes | – | always open |
| 1 | 1 | Stage 1 (Island Hop) | `Stage1` | yes (S4.1) | – | Bronze on Tutorial **or** 200 |
| 2 | 1 | Stage 2 (the variety stage) | `Stage2` | yes | – | Bronze on Stage 1 **or** 1 000 (switched in S4.1) |
| 3 | 1 | Stage 3 (bounce corridors; swapped with Blink 2026-11-08, the easier course first) | `Stage3` | yes | – | Bronze on Stage 2 **or** 1 500 |
| 4 | 1 | Stage 4 (Blink ★ rhythm) | `Stage4` | yes (S4.2) | – | Bronze on Stage 3 **or** 2 000 |
| 5 | 1 | Stage 5 (the precision finale) | `Stage5` | yes | – | Bronze on Stage 4 **or** 2 000 |
| 6 | 2 | Double Up | `DoubleUp` | P (S6) | Double Jump | World gate ² **or** 2 500 |
| 7 | 2 | Seesaw | `Seesaw` | P (S6) | Double Jump | Bronze on 6 **or** 3 000 |
| 8 | 2 | Turntable | `Turntable` | P (S6) | Double Jump | Bronze on 7 **or** 3 000 |
| 9 | 2 | Labyrinth ★ iso maze | `Labyrinth` | P (S6) | Double Jump | Bronze on 8 **or** 3 500 |
| 10 | 2 | Clocktower, finale | `Clocktower` | P (S6) | Double Jump | Bronze on 9 **or** 4 000 |
| 11 | 3 | Triple Peaks | `Stage11` | yes (S8.1) | Triple Jump | World gate ² **or** 4 000 |
| 12 | 3 | Ice Rink | `Stage12` | yes (S8.1) | Triple Jump | Bronze on 11 **or** 4 500 |
| 13 | 3 | Dash Bridge | `Stage13` | yes (S8.2) | Triple Jump, Long Dash | Bronze on 12 **or** 5 000 |
| 14 | 3 | Laser Lab ★ side-scroller | `Stage14` | yes (S8.2b) | Triple Jump, Long Dash | Bronze on 13 **or** 5 500 |
| 15 | 3 | Rising Tide, finale | `RisingTide` | P (S8) | Triple Jump, Dash | Bronze on 14 **or** 5 500 |
| 16 | 4 | Wall Climb | `WallClimb` | P (S10) | + Wall Jump | World gate ² **or** 6 000 |
| 17 | 4 | Glide Canyon ★ dropper | `GlideCanyon` | P (S10) | + Glide | Bronze on 16 **or** 6 500 |
| 18 | 4 | Moon Base | `MoonBase` | P (S10) | all so far | Bronze on 17 **or** 6 500 |
| 19 | 4 | Clockwork | `Clockwork` | P (S10) | all so far | Bronze on 18 **or** 7 000 |
| 20 | 4 | Summit, finale | `Summit` | P (S10) | all talents | Bronze on 19 **or** 7 500 |

¹ DataStore key. Keys were renamed to the stage positions on 2026-10-22 (nothing was live; the stored profiles and boards of the developers' accounts were migrated). From now on a key never changes; only a stage's `order`,
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

Prices follow `price(n) ≈ medal total of stage n−1, rounded to 500` (stage 1 is set to 200, decided 2026-10-22: a new player cannot earn Coins without a Tutorial medal, the Tutorial pays at most its 120 challenge-coin Coins without one, so the price is a shortcut for later purchases, not a path for new players); buying every unlock costs 80 700
(skipping stays possible and expensive). Today's bars and prices change with the re-order (Stage 1: Bronze on Island Hop /
1 000; Stage 2: Bronze on Blink / 2 000; Stage 3: Bronze on Stage 2 / 2 000), applied in S4 together with the new
stages so players never see a gap in the numbering; nothing is live yet, so no grandfather rule is needed if this lands
**before the first live test**.

**Required talents** are shown, never enforced: the gate face lists "Needs: …" (the unlock popup of M3 was replaced by a prompt on the gate), arriving without a
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

**Mastered stage.** A stage is *mastered* for a player when the top medal (Gold) is earned **and** every challenge coin of
the stage is found (a stage without coins needs only Gold). It tells the player "you are done here"; the only goals left
are beating your own record and the Top 10. Purely a display, no reward. Local to the player (read from `Medal_<stage>` and
`CollectedCoins`):
- each finished goal gets a green tick on the gate's door face (after the stars, after the coin line);
- once both are done a gold check badge bobs above the start gate, visible across the courtyard; the gate, its sign and the
  "Stage N" title stay as authored. The Tutorial gets it above its start gate (`LandingPad.StartGate`, which has no door: its
  tick face hangs on a local invisible anchor) and above its hub portal.
The hub world gates follow the same rule for the whole world: a green tick after the stars line when every star of the
world is earned and after the coins line when every coin of its stages is found, and the gold check above the gate once the
world is mastered (all its stages; a world with stages not built yet or marked `soon` shows nothing).
Open: showing the personal best time on the mastered door (needs a replicated best-time attribute).

## 4. Time tiers
Each stage has `T_base` = time of a clean run by the developer **with exactly the talents the stage requires** (none on
the Tutorial and stages 1–5). Default thresholds (tunable per stage):

| Medal | Stars | Threshold | Intent |
|---|---|---|---|
| Bronze | ★ | ≤ 2.5 × T_base (1.6 × until 2026-10-30) | finishable by any player who owns the required talents (none on World 1), with a few deaths; Bronze unlocks the next stage |
| Silver | ★★ | ≤ 1.1 × T_base | clean run; early talents help |
| Gold | ★★★ | ≤ 0.8 × T_base | requires the talents of the stage's designed set (§6) and a good route |

Run Speed and Jump Height never become requirements; they stay the way to faster medals and shortcuts.

2026-10-30: Bronze moved from 1.6 × to 2.5 × T_base for every stage (it unlocks the next stage, so a first run with deaths must pass).
World 3's T_base values come from the developer's best runs with every talent (Gold ≈ 1.25 × that best), so its Silver and Gold are
much tighter than before while its Bronze stays close to the old limits. Worlds 1–2 keep their T_base for now (balancing later, M6).

`T_base` is provisional; ranges are STAGES §4's, the thresholds below use the midpoint (planned stages: P).

| Stage | T_base (s) | Bronze | Silver | Gold |
|---|---|---|---|---|
| Tutorial | 30 | ≤ 75 s | ≤ 33 s | ≤ 24 s |
| 1 Island Hop | 52 (provisional, built S4.1) | ≤ 130 s | ≤ 57 s | ≤ 42 s |
| 2 Stage 1 | 70 | ≤ 175 s | ≤ 77 s | ≤ 56 s |
| 3 Bounce corridors | 100 | ≤ 250 s | ≤ 110 s | ≤ 80 s |
| 4 Blink | 60 (provisional, built S4.2; a perfect run is about 40 s) | ≤ 150 s | ≤ 66 s | ≤ 48 s |
| 5 Stage 3 | 120 | ≤ 300 s | ≤ 132 s | ≤ 96 s |
| 6–10 | 90, 80, 75, 100, 75 (set after the user's runs, StageConfig) | 2.5 × | 1.1 × | 0.8 × |
| 11 Triple Peaks | 55 (2026-10-30, from the developer's best 35.4 s) | ≤ 137.5 s | ≤ 60.5 s | ≤ 44 s |
| 12 Ice Rink | 50 (best 31.7 s) | ≤ 125 s | ≤ 55 s | ≤ 40 s |
| 13 Dash Bridge | 45 (best 27.9 s) | ≤ 112.5 s | ≤ 49.5 s | ≤ 36 s |
| 14 Laser Lab | 95 (best 60.4 s) | ≤ 237.5 s | ≤ 104.5 s | ≤ 76 s |
| 15 Rising Tide | 55 (best 34.8 s) | ≤ 137.5 s | ≤ 60.5 s | ≤ 46 s (+2 s on 2026-11-07, the stamper gate; own `tiers`) |
| 16–20 (P) | 110–130, 90–130, 120–150, 130–170, 160–200 | 2.5 × | 1.1 × | 0.8 × |

Every run stays within pillar 1 (1–3 minutes). Provisional `T_base` values (set in M1 so tiers can be evaluated) are
rough guesses — Stage 1 is consistent with the existing board (best 50 s → Gold, 104 s → Bronze). They are replaced by
measured values in M6 (M6a for World 1, M6b for the rest).

Timer precision: tenths of a second (server-measured). A run starts at `TimerStart`, ends at the finish portal,
and is cancelled by leaving through `TeleportToSpawn`.

Medal rules:
- A finish slower than the Bronze threshold earns no medal and no medal or repeat Coins (the time still counts as a
  personal best); the first finish of a stage still pays the first-finish payout (§5) and every finish pays pet XP (§7.4).
- A player's medal on a stage is the highest tier ever reached; it is never revoked, also not when thresholds are retuned.
- Best times recorded before medals existed (pre-M1) do not grant medals retroactively; the next finish does.
- After every finish a results popup shows: time, personal best (or "New record!"), the medal of this run,
  Coins paid (medal payout, first-finish payout and repeat reward), and the threshold of the next medal not yet earned.

Limits are visible before and during a run:
- **Score panel** (on arriving at a stage): all three limits, e.g. `★ 1:52  ★★ 1:17  ★★★ 0:56`; tiers already
  earned are gold. On the hub it shows the total stars earned.
- **Stage timer** (while running): next to the time, the best medal still reachable and its limit
  (`00:41.3  ★★★ 0:56`); when a limit passes it drops to the next tier, after Bronze to "no medal".
- **Hub portals**: earned stars are drawn on the portal face itself (part of the gate, not camera-facing).

## 5. Rewards
*Decided, not built (EV, the user, 2026-11-07; numbers in [ECONOMY.md](ECONOMY.md) → EV, applied in EV2a–e):* repeat medal finishes pay **Sunshine** (16 / 24 / 32 s per Bronze / Silver / Gold into a store, spent as one time skip for every growing square, tree and incubator, × 0.8^n per stage
and day, stored up to 3 h), rare seeds and pet XP instead of Coins; one-time medal / first-clear Coins stay.

All Coins earned by playing (medal payouts, repeat rewards, challenge coins, crop sales, future minigames)
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
| 1 Island Hop | 0.75 | 150 | 300 | 600 | 1 050 |
| 2 Stage 1 | 1.0 | 200 | 400 | 800 | 1 400 |
| 3 Bounce corridors | 1.25 | 250 | 500 | 1 000 | 1 750 |
| 4 Blink | 1.5 | 300 | 600 | 1 200 | 2 100 |
| 5 Stage 3 | 1.75 | 350 | 700 | 1 400 | 2 450 |
| 6–10 (P) | 2.0 … 3.0 | | | | 2 800 / 3 150 / 3 500 / 3 850 / 4 200 |
| 11–15 (P) | 3.25 … 4.25 | | | | 4 550 / 4 900 / 5 250 / 5 600 / 5 950 |
| 16–20 (P) | 4.5 … 5.5 | | | | 6 300 / 6 650 / 7 000 / 7 350 / 7 700 |
| **All 21** | | | | | **88 200** (World 1 with the Tutorial, all six built stages: 9 450) |

### First-finish payout (one-time per stage, per player)
The first finish of a stage pays **100 × stage factor** (Tutorial 50, factor 3.0 → 300), medal or not (decided
2026-10-23: a slow first finish should not go unrewarded). It is paid on top of any medal payout of that run. "First"
means the profile has no best time for the stage yet, so players who finished a stage before this rule get nothing
retroactively. All 21 planned stages: 6 300 Coins in total.

### Repeat reward (every medal finish, diminishing)
Every finish with a medal also pays

```
run reward = max(10, round(50 × stage factor × medal multiplier × 0.8^n))
```

where the medal multiplier is that **run's** medal (Bronze ×1, Silver ×1.5, Gold ×2) and `n` is the number of earlier
medal finishes of that stage by the player **today** (UTC day; resets at midnight UTC). A finish without a medal pays 0
and does **not** count towards `n` (decided 2026-10-23: a slow run never lowers the next medal run's reward).
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
| Stage 1 (Island Hop, S4.1) | 280 | 4×20, 2×50, 1×100 |
| Stage 2 | 280 | 4×20, 2×50, 1×100 |
| Stage 3 | 380 | 4×20, 2×50, 2×100 |
| Stage 4 (Blink, S4.2) | 300 | 5×20, 2×50, 1×100 |
| Stage 5 | 480 | 4×20, 2×50, 3×100 |
| **All** | **1 840** | 42 coins |

Talent-gated coins need Double Jump (placed out of reach of a Jump Height 3 jump). All six built stages have their coins
(M4 first batch: Tutorial + Stage 1; M4.1: Stage 2 + Stage 3; S4.1: Island Hop; S4.2: Blink).

**One-time total of the six built stages (Tutorial and Stages 1-5): 9 450 (medals) + 1 840 (coins) = 11 290 Coins** (all 21 planned stages:
88 200 medals + roughly 8 000 coins at about 400 per stage), plus repeat rewards, the crop field and the pet bonus,
which have no fixed cap.

## 6. Talents
Since **EV2b** (2026-11-07; numbers in [ECONOMY.md](ECONOMY.md) → EV) each bought level costs **Coins + a crop bundle** from the barn
(`Garden.Items`): from level 2 common crops of the player's tier, and the levels a stage requires also a rare crop of the world before. The
server takes the Coins and the crops together or not at all (`TalentService`, `GardenField.TakeCrops`; the average size leaves, as in a
sale); the Skills panel's buy button shows the whole price (💰 Coins over the crops as icons with have/need, what is short highlighted; a refused tap names the crops, playtest 2026-11-08), and the buy brick is
green only when everything is there. The built tree costs 94 900 Coins plus crops (5 300 Coins only before), so talents need the farm.
Levels bought before EV2b stay; nothing was refunded or charged again.

Bought in the skills panel (top-left), except **world rewards**: a level a world requires that the server grants when that world
opens (Double Jump with World 2, K1). Permanent, server-owned, applied on every spawn.
The current admin toggles (run speed 16↔64, 5 air jumps) remain debug tools only. The admin panel's **Reset Score**
is a debug full reset of the admin's **own** progress (Coins, times, medals, unlocks, coins found, talents, own Top-10
entries), confirmed by a second click; it never affects other players and the server ignores it from non-admins.

| Talent | Levels | Effect per level | Cost per level (Coins + crops) | Coins total |
|---|---|---|---|---|
| Run Speed | 5 | +6 % WalkSpeed (16 → 20.8 at max) | 800; 1 400 + 12 Garlic; 2 600 + 12 Cucumber; 4 500 + 15 Corn; 8 000 + 15 Pepper | 17 300 |
| Double Jump | 1 | one extra jump in the air | free: granted when World 2 opens | 0 |
| Jump Height | 3 | +8 % jump height | 1 100; 1 900 + 12 Cucumber; 6 500 + 15 Pepper | 9 500 |

Double Jump is a **world reward** (decided 2026-11-01 after the kid playtest, ROADMAP K1): the server grants level 1 when
World 2 opens for the player (the star bar met or the world bought for Coins), with a "new skill" popup; it is never sold
(`TalentConfig` `rewards = { [1] = 2 }`, cost 0). *Why:* it is World 2's only hard gate, and a young player spent the Coins
on other things, reached World 2 without it and gave up without knowing why. Until then it cost 3 000 (1 500 until
2026-10-23). It still opens the talent coins of World 1 (8 × 100) and the World 1 Gold sets below, now as a revisit once
World 2 is open. Triple Jump (level 2) is still bought. Open: whether the talents World 3 requires (Triple Jump, Dash) become
World 3 rewards too; the lost Coin sink is made up in the balancing pass (M6b).

**Planned talents** (P; STAGES §6.2; ids never renamed; all client-driven, level server-owned as `Talent_<id>`; Run Speed
and Jump Height stay soft, never required). Only talents that are hard gates can be *required* by a stage.

| Talent | Id | Effect | Levels | Cost (prov.) | Total | First required at |
|---|---|---|---|---|---|---|
| Quick Respawn (S2) | `QuickRespawn` | utility, **never required**: level 1 respawns after 1 s instead of 3 s, level 2 instantly and adds a fall reset to the checkpoint; the timer keeps running | 2 | 1 100 + 12 Tomato / 10 000 + 15 Broccoli | 11 100 | – |
| Triple Jump (S7, built 2026-10-24) | `DoubleJump` level 2 | 2 air jumps (reach about 19 studs) | +1 level | 16 000 + 20 Cucumber + 2 Frost grapes (5 000 Coins until EV2b) | 16 000 | stage 11 |
| Dash (S7, built 2026-10-24) | `Dash` | in the air, a short horizontal burst (about 10 studs in 0.2 s), once per air time; key + mobile button | 1 | 12 000 + 20 Corn (5 000 until EV2b) | 12 000 | – |
| Long Dash (S8.2, 2026-10-26) | `Dash` level 2 | the burst lasts 0.32 s: about 16 studs (STAGES §1.0, §7.12) | +1 level | 29 000 + 20 Pepper + 1 Glow mushroom (3 000 until EV2b) | 29 000 | stage 13 |
| Wall Jump (P, S9) | `WallJump` | against a wall in the air, jump kicks up and away; does not refill air jumps | 1 | 700 000 + 20 Blueberry + 3 Glow mushrooms | 700 000 | stage 16 |
| Glide (P, S9) | `Glide` | hold jump while falling: fall speed capped at about 8 studs/s | 1 | 2 600 000 + 25 Blueberry + 4 Glow mushrooms | 2 600 000 | stage 17 |

**Full planned tree: 3 394 900 Coins** plus the crops (44 300 Coins only until EV2b). Talents compete with squares, upgrades, pets and
incubators (§7.9) for the same Coins.

### Economy constraints (must hold after every rebalance)
Since EV2b the old **no-grind rule** (the required set affordable from the medals of the stages before it, ≤ 65 %, garden off) no longer
holds by design: talents need the farm. Its replacement is EV's check **G4** (ECONOMY.md → EV; `economy.py check`): obby-only Coins
through World 2 cover at most 40 % of the World 1–2 tree, and every required level is affordable within 1 day (Obby main, Garden main)
or 2 days (Casual) of reaching the stage that needs it, garden on. The old tables (World 1 Gold sets, required sets vs medals):
`git show a128d26:docs/GDD.md`. Open (K1): whether Triple Jump / Long Dash become World 3 rewards, as Double Jump did for World 2.

### Coins per hour (open income, provisional)
| Source | Estimate | Notes |
|---|---|---|
| Obby, first hour of a day (Gold runs, all stages) | ~2 230 | first 10 Gold runs of each of the four stages (~40 runs), then the 10-Coin floor |
| Obby, later the same day | ~500 | 10 Coins per run at ~70 s per run (a ~25 s Tutorial loop pays ~1 400 / h; open, see M6) |
| Crop field (§7.9) | see ECONOMY.md | the main income from day 1-3 on (`economy.py check`: field ≈ obby over days 1-3, 3x by day 7, 10x by day 30) |
| Pet bonus | × 1.0–1.5 | on all of the above |

Sinks: talents (94 900 today, 3.4 M planned, plus crops; EV2b), stage unlocks (6 700 today, 80 700 planned), eggs (§7.2), pet slots (4 700), incubators (3 300; EV2a), the crop field (§7.9)
and feeding (§7.6).

Notes:
- Bought stage unlocks are a sink outside the talent budget: a player who buys all three unlocks (5 000) is ~5 000 Coins behind
  and must earn it back — intended cost of skipping.
- Eggs and slots compete with talents for the same Coins; a player can choose pets first and talents later.
- Gold at 0.8 × T_base with only Run Speed 2 (+12 %) on Stage 1 needs a near-perfect route — verify in M6.

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

Every pet is an individual (own traits with their levels), identified by a unique id per player. Inventory holds up to **50** pets.
A pet can be **sold** back for its sell value (irreversible).

**Traits (P4, 2026-11-05).** Rolled once at hatch from the pet's id, never rerolled, from the working traits only: **Cuteness** (the Coin
bonus), Tending, Pest control, Scouting (§7.9). Tending comes first (`TendingChance`; always for an owner who has no Tending pet yet), then Cuteness by `CuteChance` while a slot is left, the rest from Pest control / Scouting (the kind leans the draw); slots
the pool cannot fill take Cuteness, then Tending. Share of hatches with Cuteness: Common 28 %, Uncommon 32 %, Rare 50 %, Epic 70 %,
Legendary 82 %. Fertilising, Weeding and Crafting stay stored on pets that have them (hidden, not counted) and rejoin the pool when built.
Every pet from before P4 got Cuteness once, on top of its traits (profile `Version = 4`, below §7.4).

### 7.2 Eggs
*Decided, not built (EV, the user, 2026-11-07; numbers in [ECONOMY.md](ECONOMY.md) → EV, applied in EV2a–e):* the pet (kind and rarity) is **rolled at purchase**; its rarity sets the hatch time
(Common 2 m, Uncommon 10 m, Rare 1 h, Epic 4 h, Legendary 12 h); aptitudes still roll at hatch. Basic 120, Golden 4 000.

Every egg hatches in an **incubator** of the player's garden plot (§7.6) in real time, also while the player is offline.
There is no egg stand on the central island (removed 2026-10-18). The odds are always shown before buying.

| Egg | Price | Common | Uncommon | Rare | Epic | Legendary | Where |
|---|---|---|---|---|---|---|---|
| Basic egg | 120 | 60 % | 26.2 % | 11 % | 2.7 % | 0.1 % | garden incubator, hatches in 5 minutes |
| Golden egg | 4 000 | – | 50 % | 37 % | 12.7 % | 0.3 % | garden incubator, hatches in 1 hour |

Free eggs:
- one Basic egg on the first join after pets launch (also for existing players, and again after an admin reset); a free
  egg that starts while the player has never hatched a pet (and nothing incubates) is **ready to hatch at once** (no
  5-minute wait), so a new player gets the first pet right away,
- one Basic egg for the **first Gold on each stage**, the Tutorial included (`StageResults`: any stage's first Gold; 21 over the planned
  game, plus the launch egg; corrected 2026-10-24, the text said 4).

A free egg starts by itself (no Coins) in the lowest empty incubator as soon as one is empty: on join, when the egg is
earned, after a hatch and after an incubator is bought. While every incubator is busy (or the inventory cap is reached) it
waits in the profile; the Pets panel and the incubator panel show how many wait.

### 7.3 Slots and Coin bonus
Up to 3 pets can be **equipped** (follow the player, count for the bonus). A newly hatched pet is equipped
automatically when a slot is free.

| Slot | Price |
|---|---|
| 1 | free |
| 2 | 700 |
| 3 | 4 000 |

```
pet bonus  = base bonus (rarity) + 1.9 % × (Cuteness level − 1)     (0 without Cuteness)
multiplier = 1 + min(50 %, sum of the bonuses of equipped pets)
paid       = round(base Coins × multiplier)
```
A Cuteness-10 Legendary gives +32.1 %, a capped Common (6) +11.5 %; two strong cute pets hit the +50 % cap. Equipping a pet without
Cuteness raises nothing, so the slots are a choice between income and Scouting.

### 7.4 Levels and XP
**Pet level (P4)** = the highest level of its working traits, 1–**10** (max level and max look, §7.5); traits cap by rarity (§7.1). Food and
obby XP are **care XP**: they train **Cuteness** while it is below its cap, otherwise the pet's lowest working trait below **level 5**, as
36 s of field time per XP (so Coins never buy the top work levels); with nothing left to train the XP is lost and food is refused.
Tending / Pest control also level from field hours, Scouting from medal finishes (§7.9). Cuteness XP from level L to L+1:
`round(100 × L^1.5)` (L1→2: 100, L5→6: 1 118, L9→10: 2 700; 11 100 XP from 1 to 10). Every **equipped** pet receives the full XP of
each event:

| Source | XP |
|---|---|
| Finish with Bronze / Silver / Gold (the run's medal) | 5 / 10 / 20 |
| Finish without a medal | 2 |
| Challenge coin collected | +1 |
| Movement while a stage timer runs | 1 XP per 20 studs, max 30 per run |
| Feeding in the pet garden (§7.6) | per food item |

Movement is measured on the server (horizontal distance of the character); jumps faster than walking speed allows
(teleports, respawns) do not count, and nothing is earned outside a running timer, so AFK walking earns nothing.
Movement XP is paid at the finish, together with the medal XP; a run that is cancelled (back to the hub) earns none.
Levels are permanent.

**Migration (P4, profile `Version = 4`):** a pet from before P4 got Cuteness at `1 + ceil((old level − 1) × 9 / 19)`, clamped to its cap
(old Lv 20 → 10, Lv 10 → 6, Lv 2 → 2); no pet's bonus dropped. Its old `Level` / `XP` stay stored, unused.

### 7.5 Display
Equipped pets float behind their owner and are visible to all players, with rarity colour and level on a small label.
**Parking (2026-11-10):** while a player stands on the field of their own garden plot, their followers wait in a row at the field
entrance (the path's end, facing the field) so they never hang between the camera and the squares, and glide back when the owner
walks out (hysteresis: park from 1 stud inside the field's front edge, return 3 studs before it). Display only, per client, for every
player's own plot; the numbers are the `PARK_*` constants in `PetFollow`.
The pets panel (top-left **🐶 Pets** button, U1): a summary line naming where the Coin bonus comes from ("Coin bonus +12 % · 2 cute
pets with you"), filter chips (All n/50 · With me · On the field · Best for ▼ Coins / Tending / Pest control / Scouting: the pets with that
trait, highest first; kept for the session), the pet list and the three equip slots. A row: portrait with a **level badge** (the pet
level) and a status corner icon (✓ with you, 🌾 on the field), the name in the rarity colour, one **trait chip** per working trait (icon +
level in the trait's colour, a thin fill = progress to the next level, the same share as the pet page's bar; hover / hold shows the exact
numbers), a ▲ on the chip food and runs train now or "✔ Trained" when nothing can train, then an **Equip / Unequip** brick and a
**Details ›** brick. A tap on the rest of the row does nothing; selling is only on the pet page. 460 px wide, capped to the screen and
scaled down on short screens, where the tap targets grow to stay ≥ 36 px (44 at full size). Shared row: `PetRow` (food stand too).

**Art (first version):** simple, cute blocky models built from parts, one per kind, in one consistent style; rarity
shows as label colour and a glow (Epic, Legendary). Models live in `ReplicatedStorage.PetModels`, so real art can
replace them later without code changes.

*P4 downscaled the look from 20 levels to 10: read Lv 5 / 10 / 15 / 20 below as Lv 3 / 5 / 8 / 10 (`PetConfig.Tiers`), size 1.6× at Lv 10.*
**Growth (P1e1):** a pet's size follows its level, 1.0× at Lv 1 up to 1.6× at Lv 20 (linear), for followers and field
pets alike. The follower formation widens with the pets so they never overlap, and while the owner's stage timer runs
their pets drop 4 studs further back and turn ghostly so the course stays visible; pets close to the camera fade out.
**Level-up moment (P1e2):** when a pet gains a level it spins faster and faster and rises, a bright flash covers the change from
the old look to the new one, then a burst of sparks, an expanding ring and a floating "Level N!" play and the pet drops back
(about 2 seconds), for everyone nearby (followers); the label shows one ★ per look tier
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
*Plots, incubators and feeding; every plot also has the crop field and field pets (§7.9). The P2 pens (Coins per hour from penned
pets) were removed in FA (2026-11-06): a profile from before the field converts once on join (§7.9).*

A free area reached on foot from the central island, where pets are raised. Aimed at players who prefer
collecting and caring over obby runs.
- **Where.** A separate island in the same place (not a separate place), joined to the central island by a wooden
  bridge (no portals since H1). Both islands share one look (part-built grass islands on a rock base, cobblestone
  plazas, hedge rings, blocky trees and flowers) and stand in one sea that is also the world's kill floor.
- **Layout.** A central plaza (food shop) surrounded by a ring of **12 plots** (a second ring of 18 is ready for bigger servers), about
  40 × 40 studs each, with an owner name sign (stud look, raised on two posts so players walk under it and see the plot past it) over a
  40 × 16 front strip, the field behind it. The strip (U5a) holds, as seen from the plaza, the **hatchery** on the left (the 3 incubators
  as nests in a triangle under one stud roof on four posts), the **barn** on the right (a red plank shed open towards the plaza: shelves of
  seed sacks, crates of crops) and a gravel **path** between them from the sign to the field, so the field shows from the plaza. Servers hold **12 players** (one plot per slot). Each player's
  client draws the plots from the server's data (E1a1); free plots of the inner ring show "Free plot".
- **Getting there and seeing what waits (U2).** A **🌱 Garden** icon in the top-left row (after Pets, a wood brick) puts the player
  on the grass in front of their plot from anywhere (as the Home button does; a running timer is cancelled); without a plot yet
  (just joined) a toast says so. A red **badge** on it counts what waits: ripe crops + eggs ready to hatch (none at 0; a pulse
  when the number rises). Over the own plot's name sign a **summary bubble** (only on the own plot, only for its owner) reads
  e.g. `🧺 4 ripe · ⏱ 2:14 · 🥚 Ready!` with only the parts that apply: ripe crops, the time to the next ripe crop while
  something grows, an egg ready; nothing planted → `🌱 Plant seeds`. It ticks every second (server time), keeps one size on
  screen and draws over everything (the food stand and the pets' labels would hide it from the plaza); it shows within 120
  studs of the sign or anywhere on the central plaza. A crop counts as ripe once its time is up (the server settles the
  field before a harvest).
- **Personal plot.** A player borrows a free plot while online: it is assigned on join, built from the profile, and
  released on leave. The plot's contents are saved in the profile and restored on any server. Growth and hatching run on
  server time, so they do not need the plot to exist while the player is offline.
- **Other players.** Everyone can walk through the garden and look at all plots and pets; only the owner can use their
  own plot (no stealing, no shared fields).
- **Incubators.** Every egg hatches here, in real time, and keeps hatching offline. Each plot has
  **3 incubators**, unlocked in order for 0 / 500 / 2 800 Coins (incubator 1 free; 3 300 in total; EV2a). An egg is
  bought for an empty incubator of the player's own plot (Basic 120 Coins, ready **5 minutes** later; Golden 4 000 Coins,
  ready **1 hour** later, server time); free eggs start there by themselves (§7.2). A ready
  egg waits until the owner taps **Hatch**; the pet is rolled then and equipped automatically
  when a slot is free (§7.3).
  - **Hatchery panel (U5b).** The three incubators stand as nests under the hatchery's roof (§7.6 Layout) with one "Open hatchery"
    prompt. The panel lists each incubator: its egg and a live countdown, **Hatch** when ready, the next one's Unlock brick with its
    price (two taps over 1 000 Coins), "unlock incubator n first" for the later one. While an owned incubator is empty, **egg cards**
    show each egg (drawn in its colour, name, hatch time, a price brick; Golden takes two taps) and a **?** brick that shows its odds;
    a card starts the egg in the first empty incubator. Hatching shows a **reveal** in the panel: the pet's portrait, its kind in the
    rarity colour and the rarity, where it went (with you / the Pets panel), then the traits it was born with as chips, one every
    0.4 s. Opening it closes the other panels; walking 32 studs away closes it. An egg can only be started while the pets plus the eggs already incubating stay below the
  inventory cap (50), and a ready egg does not hatch into a full inventory (it waits). Other players see the eggs and their
  countdown but cannot use them.
- **Feeding.** Food bought for Coins gives a pet XP: an alternative to leveling by playing the obby, and a Coin sink.
  Food is sold at the **food stand** in the middle of the plaza (a four-sided stud kiosk, readable from every plot, a big strawberry on top) and fed at once to one chosen pet (equipped, on the field or resting in the
  inventory); there is no food inventory. Only the fed pet gains the XP, as care XP (§7.4: Cuteness first). A pet with nothing left
  to train cannot be fed (no Coins taken; the row shows "Trained" or "Max level"); XP it cannot use is lost, which the food button's
  tooltip says. The panel (U1) shows the Pets panel's row with the chip the food will train outlined; pets with you first, then those
  that can still grow, the trained ones greyed at the bottom; it is scaled down to fit a phone screen.

  | Food | Price | XP | Coins per XP |
  |---|---|---|---|
  | Berry | 50 | 25 | 2.0 |
  | Cake | 400 | 250 | 1.6 |
  | Feast | 1 500 | 1 000 | 1.5 |

  Cuteness 1 → 10 (11 100 XP) costs about 17 000 Coins in Feasts.

### 7.7 Trading (P3)
Players on the same server can trade pets and Coins. Both players confirm the final offer; the server swaps
everything at once, saves both profiles immediately and logs the trade. Pets in an open trade are locked, and a short
cooldown applies after each trade. Trading requires profile session locking (a profile is open on at most one server),
otherwise items could be duplicated across servers.

### 7.8 Pet page and names (P3)
- **Pet page.** A row's **Details ›** brick opens the pet's page: a turning portrait, name, rarity, tier stars and where the pet is;
  growth (P4: level = best trait, what food and runs train now or "✔ Trained", next look); one card per working trait
  (`PetConfig.Shown`), titled in the trait's colour and icon, the one food trains now outlined with a ▲ like the row's chip: Cuteness
  (level / cap, Coin bonus, XP), Tending, Scouting, Pest control (level / rarity cap, effect, field hours to the next level, reach, the
  care cap); the Feed card (crops, §7.9); Equip / Unequip; Rename; at the bottom under "More" a small grey **Sell** brick (first tap:
  orange "Sure? +N", a second tap within 3 s sells). Built for 8-10 year olds on a phone: bars, stars and icons over text.
- **Names.** 1-20 letters, digits and spaces; clearing is free, the first name is free and every later one costs 250 Coins
  (`PetConfig.RenamePrice`); 10 s cooldown. Filtering is a Roblox rule: the server filters with `TextService` (owner, `PublicChat`), stores
  the raw text, filters again on every join, and only the filtered text leaves the server; a failed filter shows the kind name. Names show to
  everyone ("Mochi Lv 6") through the `PetNames` attribute and are never localized.

### 7.9 Crop field (E1-E4)

**Crop growth art (CG1–CG13).** Tomato, Potato, Corn, Lettuce, Onion, Garlic, Cucumber, Pepper, Glow Mushroom and Golden Carrot
grow continuously with stable variation tied to each planting and visible
harvest-size differences. Fruit and foliage develop from attached stems; ripeness is readable from shape and color. Nearby and
mid-distance art preserve crop identity while distant art is hidden. These crops still clear at harvest. Frost Grape's tall trellis
design is approved as a display prototype; its field integration and future perennial regrowth are separate work.
[Plant art and individual crop designs](PLANT_GROWTH.md) · [Current status](ROADMAP.md).

Garlic uses a half-exposed ivory head, alternating flat blue-green leaves and a curled scape with a pointed closed spathe.
The exposed head is an approved readability shortcut (Ales, 2026-11-10). Growth takes three minutes; harvest clears the whole
plant. Its 54-Part recipe and 9/14/26-Part mid proxies are registered and Studio-checked; phone and second-client checks remain open.
*Decided, not built (EV, the user, 2026-11-07; numbers in [ECONOMY.md](ECONOMY.md) → EV, applied in EV2a–e):* the parity goal below is replaced by engagement: the four crops move onto one ladder
of 10 s … 24 h (Potato 10 s, Corn 30 m, Pumpkin 3 h, Giant melon 12 h; 12 more crops later), Renown 0.4 × L³, every sink priced on the
square ladder (290 → 750 M), Tending as growth speed, guards make their squares safe from crows, Scouting XP from timer seconds.

*Built and Studio-validated 2026-10-30 – 11-04; every player has it since FA (2026-11-06; until then admins only); tap-and-card controls since U3a, the hand bar since U3b, the Garden panel split up since U4 (all 2026-11-07). Exact numbers live in `CropConfig` / `PetConfig` and are pinned by
`tools/economy.py`; why they are what they are: [ECONOMY.md](ECONOMY.md); what comes next: [EXPANSION.md](EXPANSION.md).*

- **Goal (2026-11-02, the user).** Farming is the main game: over days 1-3 the field earns about what the obby earns, then 3x by day 7 and
  10x by day 30 (Casual, Garden main), checked by `economy.py check`.
- **Field.** Behind each plot (a 40 x 16 strip in front holds the sign, the hatchery, the barn and the path): 36 squares in rows 6-6-8-8-8 centred on an
  8-column grid, numbered row by row from the plot (the numbers are stored: never reorder the rows). A new field opens the 2 x 2 block at the
  front centre (squares 3, 4, 9, 10) with 4 free Potato seeds. Any locked square (overgrown: grass tufts, no price in the world) can be
  bought from its square card; its price and Renown gate depend on how many are open (1 400 for the 5th up to 907 400 for the 36th).
- **Where the field's panels are (U4, 2026-11-07).** There is no Garden panel; each piece sits where it is used:
  - **Barn** (own plot): the barn building on the front strip (U5a) shows the stock: 8 seed sacks on two shelves, as many as the seeds'
    share of the barn's capacity (rounded up; none at 0), and a crate per crop kind held, topped in the crop's colour (drawn on the own
    plot only, at full detail; other plots show an empty barn). Its "Open barn" prompt and the bottom-centre HUD brick "🧺 Barn" (shown
    within 45 studs of the own plot) both open the barn panel: the crow
    forecast line (ticking), the seeds held with their grow time (Growth upgrade included) and the barn's fill ("18 / 40 seeds"), the crops
    held with count, average size and record, **Feed** (a page of the player's pets that can still learn from food, equipped first; a tap
    opens that pet's page at its harvest-feeding section) and **Sell** (all of that crop, always two taps; since 2026-11-08 the button
    shows the count and what the sale pays with the pet bonus, "Sell 2 · 3 787"). Sell is accepted at the own plot only.
  - **Seed stall** (`Workspace.Garden.SeedStall`, Studio-only, on the plaza beside the food stand, facing it): a green-and-white striped
    market stall with sacks and crates; its counter prompt "Buy seeds" (E, 10 studs) opens the stall panel: the market cart's offers (one
    buy takes all that is left at the offer price) and the seed catalogue (+1 / +10 per crop; Renown-locked rows say from which level, the
    rare crops from which world's medals) with the barn's fill. The board above the counter (both faces) lists the day's cart offers
    ("−30 % · 💰 1", "sold out") and the time to new ones. BuySeeds / BuyCart are accepted within 20 studs of the counter only; the panel
    closes beyond that.
  - **Skills panel, Garden tab** (the Obby tab holds the talents): Renown level and bar, the Growth / Barn upgrades and the tools, buyable
    anywhere (pure Coin + Renown buys).
  - **Pets panel:** the field pet slot line (pets on the field / slots) with "+1 slot" (buyable anywhere).
  - The crow forecast also shows in the summary bubble over the own sign ("🐦 0:45" within an hour of crows, "🐦 now!" while they are on).
    The join notice stays a toast.
  - **Confirm and focus (all panels).** A spend over 1 000 Coins and every Sell take two taps: the first turns the button orange ("Tap
    again") for 3 s. Opening the Pets, Skills, Barn, Seed stall or Food panel closes the one open before; Pets, Skills and Barn close when
    the player walks 32 studs from where they were opened, the two stalls beyond 20 studs from their counter.
- **Seeing the field (U3a, 2026-11-07).** Within 30 studs of the own field every planted square shows a ring (own plot only, ≤ 36): a dark
  disc whose pie fills as the crop grows, the crop icon inside; a ripe crop gets a full green pie, a ✓ badge and a small bounce; the 4 growing
  squares nearest the player also print the time left. The rings sit at crop height, drawn 3 studs toward the camera so the crop does not
  hide them (higher rings looked a row further back from the default camera). Other plots show only their crops and pets. A field pet's
  label is its given name (if any) over its job icons `🌱4 🛡2` (Tending, Pest control), never its level (with P4 the level can come
  from Cuteness).
- **Acting on a square (U3a).** No prompts on the field (the incubators keep theirs). A tap / click on a square of the own field (within 40
  studs of the plot centre; the server allows 45) outlines it in white and slides the **square card** up from the bottom: crop icon and
  name, a progress bar with the time left ("Ripe!" when ripe), the growth boosts that apply (Growth upgrade, Cloches), a row per field pet
  whose reach covers the square (portrait, job icons, what it does there: "harvests ripe crops here while you are away: 35 %", "chases
  crows away here: 70 %"; a tap opens its pet page) and context buttons: Plant (seed picker: seeds held, count, grow time; none → a note
  pointing to the seed stall), Harvest, Place pet (pet picker: Tending / Pest-control pets with job levels and squares reached; hovering a row tints
  its reach), Move pet (takes it in hand, Pets mode below), Take back, Buy square (price and Renown; grey with the reason when
  not possible; over 1 000 Coins a second tap within 3 s confirms). The selected square again, a tap off the field or walking away closes it.
  The card is at most 400 px wide and on a touch screen keeps 110 px free on each side (thumbstick, jump button). The client sends only the
  square number (and a crop id or pet uid); `GardenField` checks everything as before.
- **Hand bar (U3b, 2026-11-07).** While the tap range applies, four bricks: 🌱 Seeds, 🧺 Basket, 🐾 Pets, ✋ Look (default); a row at the
  bottom right with a mouse, a 2 x 2 block above the jump button on a touch screen without a keyboard (the card then keeps clear of it). The
  active one is raised and framed; a line above the bar says what a tap does (in Look: "Tap a square to see it" until the first tap on a
  square in the session). White corner brackets mark the own square under the mouse (the cursor turns into a pointing hand), else the
  square the character stands on (always so on touch), never the selected one: squares are things to tap; brackets, not a full outline,
  so they never look like a reach border. Seeds: the card picks a seed (count, grow time), then every tap
  on an empty open square plants it; the brick shows the seed and the count left; with none left a tap reopens the picker. Basket: every tap
  on a ripe square harvests that one (never all: harvest-all is the paid Wheelbarrow, D2). Pets: a tap on a placed pet takes it in hand
  (outline on its square, its reach tinted under the mouse, or on the last tapped square on touch); a tap on a free open square puts it there
  (one click; on touch the first tap shows the reach, a second tap on the same square drops); the pet's own square or 🐾 again cancels; a
  free square with nothing in hand opens the pet picker. Any other tap selects as in Look. Leaving the range hides the bar and resets Look.
  Every field action is queued and sent at most every 0.25 s (the server drops actions under 0.2 s apart), so quick taps are never lost.
  Every harvest pops "+1 🌽" (plus Big! / Giant!) over its square for a second. Next step: Seeds pulses while nothing is planted and seeds
  are held, Basket while something is ripe, each until that mode was used once in the session. The pet page has "Place on field" (under
  More, while the bar shows, for a pet with Tending or Pest control that is not equipped; also moves a field pet): it closes the Pets panel
  and puts the pet in hand.
- **Reach borders (U3b).** In the Near tier every placed pet's region is outlined by thin strips in its rarity colour (not glowing: Common
  grey must not look like the white select outline): the squares it counts for under the field's rules, i.e. per square the strongest Tending
  pet and the strongest guard (ties to the lower uid). Regions that share an edge draw side by side (three lanes inset 0.45 / 0.8 / 1.15
  studs); strips meet at outer and inner corners.
- **Crops.** Potato (5 min, so the first harvest comes in the first session), Corn, Pumpkin and Giant melon from the seed stall behind Renown
  gates; three rare crops, one per world (Golden carrot 50 000, Frost grape 150 000, Glow mushroom 300 000 Coins; priced for the days a world is reached, ECONOMY.md), only from the obby (below), never sold as seeds, never
  eaten by crows. Growth runs on server time only: online x 1.0, offline x 0.5 for at most 24 h per absence, settled on join, on leave, every
  60 s and before every action; ripe crops wait. The barn holds 40 seeds and 40 stored crops (+20 per Barn level). Seeds held can always be
  planted; the stall keeps the Renown gate.
- **Selling and feeding.** A crop is sold from anywhere (playtest 2026-11-08: the Barn button shows outside runs while crops are held, the seed stall has a Sell tab; a young field gets a toast and a pulsing button) (sale x its size, through `CoinRewards.Grant`) or fed to any pet (from its page or the barn's Feed) for XP = half the
  sale, so feeding is never better than selling and buying food (the Kitchen, D5, stays the better route later).
- **Size roll.** Every planting rolls a size factor (lognormal, mean exactly 1, 0.36-2.64), fixed by owner and planting number so a re-join
  cannot reroll it; Big = top 20 %, Giant = top 3 %, a record per crop, weight shown as kg x factor. The barn keeps a count and the summed size
  per crop; selling k of n pays the average size.
- **Renown.** Points per harvest by tier (1 / 3 / 6 / 12 for rare crops), level L at 3 x L^1.6 points; gates seeds in the shop, squares and
  tool levels.
- **Upgrades and tools.** Growth (4 levels, -5 % grow time each) and Barn (5 levels, +20 each). Tools with Renown-gated levels: Seed sorter
  (sizes x 1.05 / 1.10 / 1.15), Cloches (online growth +7 / 14 / 20 %), Pruning shears (5 / 10 / 15 % chance of a second crop of the same size,
  rolled per planting).
- **Market cart.** Offers per UTC day, the same on every server, counts per player: 10 seeds of an unlocked crop at -30 %, 5 of another at -50 %,
  and from Renown 3 a taste of 2 seeds of the next locked crop at the catalogue price.
- **Field pets.** Every pet has aptitudes (traits, §7.1: Cuteness, Tending, Pest control, Scouting; stored but not yet rolled: Fertilising,
  Weeding, Crafting; levels 1-10 up to its rarity's cap), rolled once from its uid (the count by rarity, the kind leans the draw) and never
  rerolled; a hatch while the owner has no Tending pet gets Tending. Food and obby XP also train the work traits up to level 5 (§7.4). A pet with Tending or Pest control can stand on a square (one per square, not equipped; 1 free field pet slot + 4 bought). Reach
  by the job's level: its square (1-3), plus its 4 neighbours (4-6), the 3 x 3 block (7-10); on overlaps the strongest pet of a job counts.
  **Tending** works only during absences: a crop that ripens in reach is harvested with the pet's strength (20 % at level 1 to 100 % at 10)
  while the barn has room, then replanted from the seeds held (rolled once per planting). Placed pets gain aptitude XP per weighted field hour
  (level L -> L + 1 takes 10 x 1.56^(L-1) h). A profile from before the field converts once on join (`Garden.Converted`): the P2 pens become
  field pet slots (1 pen = 1, 2-3 = 2, 4-6 = 3; pen prices beyond the slots' value refunded), penned pets go back to the inventory.
- **Obby seeds (E2, world stages only).** The first Gold on a World 2 or 3 stage gives 1 rare seed of that world; the day's first medal finish
  gives 1 (once per UTC day); a rare-seed meter per stage (Bronze 1 / Silver 2 / Gold 3 points, doubled for the day's first finish there; 300
  points = a seed). The **seed pouch**: the day's first medal finish on each stage gives 1 / 2 / 3 seeds of the common crop planted last, up to
  the barn. **Scouting** (equipped pets): 15 min of aptitude XP per medal finish; the scouts' bonus (up to +50 %) multiplies the meter points
  and at +50 % adds 1 pouch seed. The results popup lists every seed and the meter.
- **Crows (E4-thin).** From Renown 3. The UTC day has four 6-hour blocks, a quarter of them crow blocks on a fixed schedule, shown as a
  forecast in the barn panel (and the summary bubble within an hour). On the join settle, after Tending, every ripe common crop whose ripe time overlaps a crow block is rolled once
  (30 %); a lost roll eats it unless the strongest guard reaching the square wins its chance (50 % + half the Pest-control strength, doubled
  for the crow speciality). At most 1 crop is eaten per absence; crops ripe while the owner plays are safe. A pet with Tending and Pest control
  does both jobs.
- **Join notice.** What the pets harvested (and the shears' extras), what the crows ate and who chased them off, an old profile's pen conversion.

## 8. Leaderboards
- **Per stage:** Top-10 fastest times (exists for Stage 1 and 2; add Stage 3 and Tutorial).
- **Hub:** global "most stars" Top-10 (max 12★ with four stages; 63★ with the Tutorial and all 20 stages, +3 per bonus stage;
  each world island gets a world board with the stars in that world). The leaderstats column "Stage" (checkpoint number)
  is replaced by "Stars" in S1.2.
- Open question: show the talents used next to a time, or keep a separate "no-talent" board?
- Possible later: "rarest pets" / "highest pet level" board.

## 9. Monetization (comfort only)
Decided 2026-10-25. The product list and offer rules are in [EXPANSION.md](EXPANSION.md) §13; the shop ships as M7 (drop D2).
- **No paid random items.** Eggs are never sold for Robux, and neither is anything that buys an egg: Coins, seeds, crops and
  the seed shop's stock are never sold for Robux (no Coin packs). Eggs stay Coins-only (whether eggs stay at all is open,
  EXPANSION §16); the egg UI keeps showing the odds.
- **Luck and weather are never sold.** Egg odds, harvest size and variant chances come only from play: Coin-bought tools,
  crafted fertilisers, pets and the weather schedule.
- **Robux buys comfort:** time (longer offline cap, instant grow, faster incubators), capacity reached sooner (pet slot,
  post, incubator), cosmetics (trails, skins, portal effects, pet accessories, decor), skip stage. No 2× Coins pass: it is
  neither earnable nor capped.
- Rule: everything purchasable that changes the economy must also be earnable through play and capped, so money only
  speeds progress up.
- Leaderboard fairness (§1, pillar 3): nothing bought affects a stage time; a skipped stage gives no time, no medal and no payout.

## 10. Balancing & telemetry
- **Measuring `T_base`:** developer runs each stage clean, no talents, 3 attempts, take the median.
- **Telemetry:** log every finish (stage, time, talent levels, pet multiplier) and every egg purchase (egg, rarity)
  to a DataStore / AnalyticsService funnel.
- **Re-tune when:** Gold rate < 10 % among players with the designed talent set, or > 60 % of finishers stop at Bronze,
  or a stage's unlock is bought more often than earned, or garden income exceeds the obby first-hour income (pillar 2).

## 11. Player guidance (hints)
Decided 2026-10-27. A player who finishes a stage, earns Coins or waits for an egg should always see what they can do next
without reading anything. One client-side system (milestone G1) draws every such hint, so the game speaks one visual
language. Hints are local to the player and display only: they read state the client already has (attributes, leaderstats,
incubator models) and never ask the server for anything.

**Three kinds of signal, each with one job:**

| Signal | Answers | Look |
|---|---|---|
| World marker | *Where do I go?* | a chunky orange down arrow with a white outline and a label (the stage's name, "Ready!"), bobbing above the target; drawn on the screen (not in the 3D world) at a constant size, so a sign or a wall never hides it. It always points at the target at the player's height (a gate's doorway, never the point above its sign): while that spot is in view left to right, the arrow stays above it pointing down, kept under the top of the screen when the player stands close and the point above the sign is out of view. Otherwise it sits on the screen edge nearest the target and turns to point at it, the label level on the side towards the screen centre; a target behind the player goes to the left or right edge of the shorter turn, at mid-height. The edge area keeps clear of the top-left icons, the score panel and the bottom 30 % (touch joystick and jump button). Orange and the arrow are used for nothing else (green and ticks mean "done") |
| HUD dot | *Which button?* | a red dot on the top-right corner of a top-left icon (and of a button inside a panel); one pulse when it appears, then still |
| HUD badge | *How much waits there?* | a red pill with a number on the top-right corner of a top-left icon (the Garden icon: ripe crops + ready eggs, U2); none at 0, one pulse when the number rises |
| Toast | *Something happened elsewhere* | one line at the bottom of the screen for a few seconds, once per event |

**Rules (they keep the hints from becoming noise):**
- Flag only what pays off now: something to claim, or something the player can afford. Never "you could, if…".
- A shop dot clears once seen: it lights when an offer *becomes* affordable that was not affordable the last time the panel was
  open, and opening the panel clears it (the seen list lasts for the session). A reward waiting to be claimed (a ready egg)
  keeps its dot and marker until it is claimed.
- No blinking: a dot pulses once when it appears, a marker only bobs.
- Quiet during a run: markers hide, toasts wait until the run ends; dots stay.
- At most one world marker per area (a world courtyard, the hub, the garden).

**Hints (phase 1):**
- **Next stage:** the latest stage in game order that is open for the player and has no medal yet, so players are pushed
  forwards (a player with World 2 open is sent to Stage 6, not back to an unfinished Stage 5); when the latest open stage
  already has a medal (e.g. a world bar not met yet) the latest open one still without a medal is used. When every open stage
  has a medal and a world opener's star bar shuts the next stage (e.g. Bronze on all of World 1 = 5 of the 10 stars World 2
  needs), the marker goes to the open stage of the world the bar counts with the lowest medal (ties: the earliest, usually the
  easier one), labelled with the medal to reach ("Stage 3: Silver"). None when every open stage has a medal and no star bar
  shuts anything (Gold chasing has the mastered badge, §3). Its marker (labelled with the stage's name) stands above
  the stage's start gate while the player is in that stage's courtyard (the Tutorial: near its landing pad), above the hub
  entrance (the world's hub gate, the Tutorial's hub portal) while the player is in the hub or the garden (in the garden a
  ready egg's marker wins), and above the portal back to the hub while the player is in another courtyard or the Tutorial. It hides within 25 studs of its target, so the player who lands
  in front of a gate after a finish without a medal is not pointed at the gate behind them.
- **Stuck fallback** (K1, 2026-11-01, after a young player kept retrying Stage 5 because the marker kept sending him there):
  after 3 runs of the next stage that ended without a medal (given up or too slow; runs under 10 s do not count, walking out
  through a gate starts and ends a ghost run; a run of another stage started without ending this one also counts) or 12 deaths
  during its runs (Quick Respawn fall resets count as deaths), in this session, the marker moves to the open stage
  of the **same world** with the lowest medal (ties: the earliest), labelled with the medal to reach ("Stage 1: Silver"): the
  stars that can still open the next world. It never points into another world, so a player with World 2 open is still sent
  there (the next stage is then a World 2 stage). No other stage to improve: the marker stays.
- **Skills:** a dot on the Skills icon when a talent level became affordable that the player has not seen affordable with the
  panel open (the panel's green Buy brick already marks the row).
- **Ready egg:** counted in the Garden icon's badge (with the ripe crops, §7.6; U2 replaced the dots on the Pets icon and its
  old "Go to my garden" button); a marker ("Ready!") above that incubator while the player is in the garden; a toast "Your egg
  is ready!" once per egg (also on joining with an egg already ready).

**Later, if playtests ask for it:** an affordable gate unlock (the gate prompt covers it up
close), a short ground trail from the Arrival to the next gate after a finish, a "Next: <stage>" line in the results popup.
