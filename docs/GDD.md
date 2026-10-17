# Oby sandbox — Game Design Document

Status: **draft**. All numbers are placeholders until `T_base` is measured in the M6 balancing pass
(see [ROADMAP.md](ROADMAP.md)). This document says *what* the game is; the roadmap says *how and when* it is built.

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

| Order | Stage | Internal key | Checkpoints | Difficulty | Theme / obstacles | Unlock |
|---|---|---|---|---|---|---|
| 0 | Tutorial | `"Stage 4"` ¹ | 23–24 | ★ | basics: jumps, first kill part | always open |
| 1 | Stage 1 | `"Stage 1"` | 1–9 | ★★ | laser strips, spinners, lava floor, choice stage, jump pads | Bronze on Tutorial **or** 50 Coins |
| 2 | Stage 2 | `"Stage 2"` | 10–14 | ★★★ | kill-part corridors, bounce bricks | Silver on Stage 1 **or** 150 Coins |
| 3 | Stage 3 | `"Stage 3"` | 20–22 | ★★★★ | dense kill-part layouts | Silver on Stage 2 **or** 300 Coins |

¹ Existing DataStore key; keep it (or migrate) so recorded times are not lost.

**Unlocks.** Every stage after the Tutorial opens either by **meeting the bar** (required medal on the previous stage)
or by a **one-time Coin price**. Prices are set so that buying an unlock costs roughly a full talent level or two —
skipping is possible but slows talent progress. Unlocks are permanent. Each stage can be bought on its own (Stage 3
does not require Stage 2 to be open). Times or medals already recorded on a locked stage do not open it (no grandfathering
of pre-M3 progress), and admins follow the same rules. Stage 1's bar is deliberately low (Bronze, ≈ 48 s on the Tutorial)
and its price is a small convenience: a new player has 0 Coins, so the Tutorial is the real way in, and the Tutorial
must always stay completable.

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
| Tutorial | 30 (prov.) | ≤ 48 s | ≤ 33 s | ≤ 24 s |
| Stage 1 | 70 (prov.) | ≤ 112 s | ≤ 77 s | ≤ 56 s |
| Stage 2 | 100 (prov.) | ≤ 160 s | ≤ 110 s | ≤ 80 s |
| Stage 3 | 120 (prov.) | ≤ 192 s | ≤ 132 s | ≤ 96 s |

Provisional `T_base` values (set in M1 so tiers can be evaluated) are rough guesses — Stage 1 is consistent with
the existing board (best 50 s → Gold, 104 s → Bronze). They are replaced by measured values in M6.

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
Base payout Bronze 20 / Silver 40 / Gold 80, × stage factor. Reaching a higher tier directly also pays the lower
tiers not yet earned (a first-try Silver pays Bronze + Silver).

| Stage | Factor | Bronze | Silver | Gold | Stage total |
|---|---|---|---|---|---|
| Tutorial | 0.5 | 10 | 20 | 40 | 70 |
| Stage 1 | 1.0 | 20 | 40 | 80 | 140 |
| Stage 2 | 1.5 | 30 | 60 | 120 | 210 |
| Stage 3 | 2.0 | 40 | 80 | 160 | 280 |
| **All** | | | | | **700** |

### Repeat reward (every finish, diminishing)
Every finish with a medal also pays

```
run reward = max(1, round(5 × stage factor × medal multiplier × 0.8^n))
```

where the medal multiplier is that **run's** medal (Bronze ×1, Silver ×1.5, Gold ×2) and `n` is the number of earlier
finishes of that stage by the player **today** (UTC day; resets at midnight UTC). A finish without a medal pays 0.
It is paid on top of any medal payout, also on the first finish.

| Stage | First run Bronze | Silver | Gold | Gold, sum of the first 10 runs of a day |
|---|---|---|---|---|
| Tutorial | 3 | 4 | 5 | 23 |
| Stage 1 | 5 | 8 | 10 | 44 |
| Stage 2 | 8 | 11 | 15 | 68 |
| Stage 3 | 10 | 15 | 20 | 89 |

After ~10 runs a stage pays 1 Coin per run until the next day. Faster medals pay more, grinding runs out quickly,
and switching stages is better than repeating one (pillar 2). All values provisional.

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

**One-time total: 700 (medals) + 130 (coins) = 830 Coins**, plus repeat rewards, garden production and the pet bonus,
which have no fixed cap.

## 6. Talents
Bought in the skills panel (top-left). Permanent, server-owned, applied on every spawn.
The current admin toggles (run speed 16↔64, 5 air jumps) remain debug tools only. The admin panel's **Reset Score**
is a debug full reset of the admin's **own** progress (Coins, times, medals, unlocks, coins found, talents, own Top-10
entries), confirmed by a second click; it never affects other players and the server ignores it from non-admins.

| Talent | Levels | Effect per level | Cost per level | Total |
|---|---|---|---|---|
| Run Speed | 5 | +6 % WalkSpeed (16 → 20.8 at max) | 20 / 40 / 60 / 90 / 130 | 340 |
| Double Jump | 1 | one extra jump in the air | 150 | 150 |
| Jump Height | 3 | +8 % jump height | 30 / 60 / 100 | 190 |
| **Full tree** | | | | **680** |

### Economy constraints (must hold after every rebalance)
The economy is open (repeat rewards, garden, pet bonus), so "earnable" is no longer a cap. The constraint is about
the **no-grind path**: a player who only plays each stage until its medals are earned, with no pets.
Gold on each stage is designed around a talent set; that set must be affordable from one-time income earned *before*
that Gold (all medals on earlier stages + Bronze/Silver on this stage + challenge coins up to this stage).
Repeat rewards and pets only add to this, so the table is a lower bound.

| Gold on | Designed talent set | Cost | Earnable before | OK |
|---|---|---|---|---|
| Stage 1 | Run Speed 2 | 60 | 70 + 60 + 40 = 170 | ✔ |
| Stage 2 | Run Speed 3 + Double Jump | 270 | 70 + 140 + 90 + 80 = 380 | ✔ |
| Stage 3 | Run Speed 5 + Double Jump + Jump Height 2 | 580 | 70 + 140 + 210 + 120 + 130 = 670 | ✔ |
| Full tree | everything | 680 | 830 total | ✔ |

### Coins per hour (open income, provisional)
| Source | Estimate | Notes |
|---|---|---|
| Obby, first hour of a day (Gold runs, all stages) | ~225 | first 10 Gold runs of each of the four stages (~40 runs), then the 1-Coin floor |
| Obby, later the same day | ~50 | 1 Coin per run at ~70 s per run |
| Pet garden (§7.6) | target 30–100 | depends on pets in pens; offline production capped at 8 h |
| Pet bonus | × 1.0–1.5 | on all of the above |

Sinks: talents (680), stage unlocks (500), eggs (§7.2), pet slots (700), garden upgrades and feeding (§7.6).

Notes:
- Bought stage unlocks are a sink outside the talent budget: a player who buys all three unlocks (500) is ~500 Coins behind
  and must earn it back — intended cost of skipping.
- Eggs and slots compete with talents for the same Coins; a player can choose pets first and talents later.
- Gold at 0.8 × T_base with only Run Speed 2 (+12 %) on Stage 1 needs a near-perfect route — verify in M6.

## 7. Pets
Pets follow the player, multiply Coin income and level up. They never affect movement, jumping or stage times.

### 7.1 Rarities and kinds
| Rarity | Base bonus | Sell value | Example kinds (prov.) |
|---|---|---|---|
| Common | +2 % | 10 | Cat, Dog |
| Uncommon | +4 % | 20 | Bunny, Fox |
| Rare | +7 % | 50 | Owl, Panda |
| Epic | +10 % | 150 | Dragon |
| Legendary | +15 % | 500 | Phoenix |

Every pet is an individual (own level and XP), identified by a unique id per player. Inventory holds up to **50** pets.
A pet can be **sold** back for its sell value (irreversible).

### 7.2 Eggs
Eggs are opened at an **egg stand** on the central island and hatch instantly with a random pet.
The odds are always shown before buying.

| Egg | Price | Common | Uncommon | Rare | Epic | Legendary | Where |
|---|---|---|---|---|---|---|---|
| Basic egg | 50 | 60 % | 25 % | 11 % | 3.5 % | 0.5 % | egg stand (hub), instant |
| Golden egg | 400 | – | 45 % | 35 % | 15 % | 5 % | pet garden incubator, hatches in real time (§7.6) |

Free eggs:
- one Basic egg on the first join after pets launch (also for existing players),
- one Basic egg for the **first Gold on each stage** (4 in total).

Free eggs wait in the profile until claimed at the egg stand.

### 7.3 Slots and Coin bonus
Up to 3 pets can be **equipped** (follow the player, count for the bonus).

| Slot | Price |
|---|---|
| 1 | free |
| 2 | 200 |
| 3 | 500 |

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
Levels are permanent. A pet at level 20 stops gaining XP.

### 7.5 Display
Equipped pets float behind their owner and are visible to all players, with rarity colour and level on a small label.
The pets panel (top-left **🐾 Pets** button) lists the inventory, equipped pets, slots, total bonus and XP bars.

**Art (first version):** simple, cute blocky models built from parts, one per kind, in one consistent style; rarity
shows as label colour and a glow (Epic, Legendary). Models live in `ReplicatedStorage.PetModels`, so real art can
replace them later without code changes.

### 7.6 Pet garden (minigame, P2)
A free area reached by a portal from the central island, where pets are raised. Aimed at players who prefer
collecting and caring over obby runs.
- **Where.** A separate island in the same place (not a separate place): a garden portal on the central island and a
  return portal on the garden.
- **Layout.** A central plaza (food shop; later a twin of the egg stand) surrounded by a ring of **12 plots**, about
  40 × 40 studs each, with an owner name sign, pens and incubators. Servers hold **12 players** (one plot per slot).
- **Personal plot.** A player borrows a free plot while online: it is assigned on join, built from the profile, and
  released on leave. The plot's contents are saved in the profile and restored on any server. Production runs on server
  time, so it does not need the plot to exist while the player is offline.
- **Other players.** Everyone can walk through the garden and look at all plots and pets; only the owner can use their
  own plot (no stealing, no shared pens).
- **Pens.** A pet is either equipped or placed in a pen, never both. Pets in pens produce Coins over time by rarity
  and level (rates in M6; target in §6). Pens unlock for Coins.
- **Incubators.** Garden eggs (Golden egg and better) hatch in real time (minutes to hours) and keep hatching offline.
  More incubators unlock for Coins.
- **Feeding.** Food bought for Coins gives a pet XP: an alternative to leveling by playing the obby, and a Coin sink.
- **Offline income.** On join, production since the last visit is paid, capped at 8 hours, and shown in a
  "while you were away" popup.

### 7.7 Trading (P3)
Players on the same server can trade pets and Coins. Both players confirm the final offer; the server swaps
everything at once, saves both profiles immediately and logs the trade. Pets in an open trade are locked, and a short
cooldown applies after each trade. Trading requires profile session locking (a profile is open on at most one server),
otherwise items could be duplicated across servers.

## 8. Leaderboards
- **Per stage:** Top-10 fastest times (exists for Stage 1 and 2; add Stage 3 and Tutorial).
- **Hub:** global "most stars" Top-10 (max 12★ with four stages).
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
