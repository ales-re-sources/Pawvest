# Oby sandbox — Game Design Document

Status: **draft**. All numbers are placeholders until `T_base` is measured in the M6 balancing pass
(see [ROADMAP.md](ROADMAP.md)). This document says *what* the game is; the roadmap says *how and when* it is built.

## 1. Pillars
1. **Short, readable stages** — each stage is a 1–3 minute run with a clear finish.
2. **Mastery beats grind** — currency comes from beating times and finding hard coins, not from repetition.
3. **Fair leaderboards** — nothing that affects a leaderboard time can be bought with Robux (provisional, see §8).

## 2. Core loop
```
run a stage → medal by time → Coins (one-time per medal tier)
     ↑                                   ↓
faster runs / harder stages  ←  talents + stage unlocks
```
Secondary loop: talents (e.g. double jump) open new routes → challenge coins on already-cleared stages.

## 3. Stages

| Order | Stage | Internal key | Checkpoints | Difficulty | Theme / obstacles | Unlock |
|---|---|---|---|---|---|---|
| 0 | Tutorial | `"Stage 4"` ¹ | 23–24 | ★ | basics: jumps, first kill part | always open |
| 1 | Stage 1 | `"Stage 1"` | 1–9 | ★★ | laser strips, spinners, lava floor, choice stage, jump pads | always open |
| 2 | Stage 2 | `"Stage 2"` | 10–14 | ★★★ | kill-part corridors, bounce bricks | Silver on Stage 1 **or** 150 Coins |
| 3 | Stage 3 | `"Stage 3"` | 20–22 | ★★★★ | dense kill-part layouts | Silver on Stage 2 **or** 300 Coins |

¹ Existing DataStore key; keep it (or migrate) so recorded times are not lost.

**Unlocks.** Every stage after Stage 1 opens either by **meeting the bar** (required medal on the previous stage)
or by a **one-time Coin price**. Prices are set so that buying an unlock costs roughly a full talent level or two —
skipping is possible but slows talent progress. Unlocks are permanent.

**Hub portals** show: stage name, locked/unlocked, requirement + price when locked, best medal earned,
and challenge coins found `x/y`.

## 4. Time tiers
Each stage has `T_base` = time of a clean, no-talent run by the developer. Default thresholds (tunable per stage):

| Medal | Stars | Threshold | Intent |
|---|---|---|---|
| Bronze | ★ | ≤ 1.6 × T_base | finishable by any new player, no talents |
| Silver | ★★ | ≤ 1.1 × T_base | clean run; early talents help |
| Gold | ★★★ | ≤ 0.8 × T_base | requires the talents listed in §6 and a good route |

| Stage | T_base (s) | Bronze | Silver | Gold |
|---|---|---|---|---|
| Tutorial | TBD | | | |
| Stage 1 | TBD | | | |
| Stage 2 | TBD | | | |
| Stage 3 | TBD | | | |

Timer precision: tenths of a second (server-measured). A run starts at `TimerStart`, ends at the finish portal,
and is cancelled by leaving through `TeleportToSpawn`.

## 5. Rewards

### Medal payouts (one-time per tier, per player)
Base payout Bronze 20 / Silver 40 / Gold 80, × stage factor. Reaching a higher tier directly also pays the lower
tiers not yet earned (a first-try Silver pays Bronze + Silver).

| Stage | Factor | Bronze | Silver | Gold | Stage total |
|---|---|---|---|---|---|
| Tutorial | 0.5 | 10 | 20 | 40 | 70 |
| Stage 1 | 1.0 | 20 | 40 | 80 | 140 |
| Stage 2 | 1.5 | 30 | 60 | 120 | 210 |
| Stage 3 | 2.0 | 40 | 80 | 160 | 280 |
| **All** | | | | | **700** |

### Challenge coins
Placed off the main path, behind risky jumps, or reachable only with talents. Each coin is collected
**once per player**, saved, and hidden only for that player. Values: easy 2 / risky 5 / talent-gated 10.

| Stage | Coin budget (Coins) | Example mix |
|---|---|---|
| Tutorial | 10 | 1×5, 1×5 |
| Stage 1 | 30 | 3×2, 2×5, 1×10 + … |
| Stage 2 | 40 | |
| Stage 3 | 50 | |
| **All** | **130** | |

**Total earnable: 700 (medals) + 130 (coins) = 830 Coins.**

## 6. Talents
Bought in the skills panel (top-left). Permanent, server-owned, applied on every spawn.
The current admin toggles (run speed 16↔64, 5 air jumps) remain debug tools only.

| Talent | Levels | Effect per level | Cost per level | Total |
|---|---|---|---|---|
| Run Speed | 5 | +6 % WalkSpeed (16 → 20.8 at max) | 20 / 40 / 60 / 90 / 130 | 340 |
| Double Jump | 1 | one extra jump in the air | 150 | 150 |
| Jump Height | 3 | +8 % jump height | 30 / 60 / 100 | 190 |
| **Full tree** | | | | **680** |

### Economy constraints (must hold after every rebalance)
Gold on each stage is designed around a talent set; that set must be affordable from what is earnable *before*
that Gold (all medals on earlier stages + Bronze/Silver on this stage + challenge coins up to this stage).

| Gold on | Designed talent set | Cost | Earnable before | OK |
|---|---|---|---|---|
| Stage 1 | Run Speed 2 | 60 | 70 + 60 + 40 = 170 | ✔ |
| Stage 2 | Run Speed 3 + Double Jump | 270 | 70 + 140 + 90 + 80 = 380 | ✔ |
| Stage 3 | Run Speed 5 + Double Jump + Jump Height 2 | 580 | 70 + 140 + 210 + 120 + 130 = 670 | ✔ |
| Full tree | everything | 680 | 830 total | ✔ |

Notes:
- Bought stage unlocks are a sink outside this budget: a player who buys both unlocks (450) is ~450 Coins behind
  and must earn it back via medals — intended cost of skipping.
- Gold at 0.8 × T_base with only Run Speed 2 (+12 %) on Stage 1 needs a near-perfect route — verify in M6.

## 7. Leaderboards
- **Per stage:** Top-10 fastest times (exists for Stage 1 and 2; add Stage 3 and Tutorial).
- **Hub:** global "most stars" Top-10 (max 12★ with four stages).
- Open question: show the talents used next to a time, or keep a separate "no-talent" board?

## 8. Monetization (deferred)
Not designed yet; decide after M6. Candidates: cosmetics (trails, skins, portal effects), convenience passes
(2× Coins, skip stage), Coin packs. Rule for any candidate: everything purchasable must also be earnable through play
and capped, so money only speeds progress up. Leaderboard fairness (§1.3) is re-evaluated at that point.

## 9. Balancing & telemetry
- **Measuring `T_base`:** developer runs each stage clean, no talents, 3 attempts, take the median.
- **Telemetry:** log every finish (stage, time, talent levels) to a DataStore / AnalyticsService funnel.
- **Re-tune when:** Gold rate < 10 % among players with the designed talent set, or > 60 % of finishers stop at Bronze,
  or a stage's unlock is bought more often than earned.
