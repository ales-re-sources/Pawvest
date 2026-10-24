# Pawvest economy model (E0) — parameters, decisions, how to re-run

**Status: PROVISIONAL (2026-10-24, E0 in progress).** Every number for the crop field, Renown, expansion tiers, upgrades, reserved sinks, the online /
offline rates and the archetype behaviour is a model assumption until the user confirms it and E1 copies it into `CropConfig`. Numbers that already
exist in the game are read from the Luau configs (drift-pinned). Scope and acceptance checks: [ROADMAP.md](ROADMAP.md) → E0. Design: [EXPANSION.md](EXPANSION.md) §2, §5, §9.

## How to re-run

```
python tools/economy.py check                 # 43 checks incl. guardrails A-C and the online / offline rule, about 3 s, exit 1 on a failure
python tools/economy.py sim                   # 60-day simulation per archetype x policy, field tables, online vs offline lines, guardrail lines
python tools/economy.py report                # baseline tables + sections 7-8 (crops, tiers, scale vs field size)
python tools/economy.py field                 # catalogue size and ladder-scale sweep
python tools/economy.py sim --garden both     # grandfathered pens (they pay AND work as posts); --garden pens = today's game
python tools/economy.py check --crops min     # smallest catalogue; --crops full adds Radish, Carrot, 2x2 Trophy pumpkin
python tools/economy.py sim --scale 0.2       # try another ladder scale (all crop prices follow)
python tools/economy.py check --offline-rate 0.5 --offline-cap 24     # try other online / offline rules (offline-rate 1 = no difference)
```

To change a new number edit the `FIELD` / `CROP_DEFS` / `CATALOGUES` block in `tools/economy.py` and re-run `check`; existing game values are never
edited there (a changed config makes `check` fail until `pin`).

## The rules as simulated

- **Online beats offline (user rule 2026-10-24).** Offline income must exist, online income (even passive) must be much higher, as a reason to keep Roblox open.
  Two parameters, not constants: `online_rate = 1.0` and `offline_rate = 0.33` (online roughly 3x; **the user gave no number, open decision 5**). They apply
  to everything passive: crop growth, Gardener replanting and the old pen production (`--garden pens|both`). Offline time is capped after each session:
  `offline_cap_h = 12` for the field (provisional, open decision 5), 8 h for pens (GardenConfig). Roblox does not pay for uptime any more (Engagement-Based
  Payouts ended 2025-07-24; Creator Rewards pays per Active Spender), so this is a retention / monetization design choice: **the model pays nothing for pure AFK**,
  growth only counts as "online" during the archetype's session hours, and the 24-hour rule is checked for the online case only.
- **One field of squares.** The player plants any unlocked crop on any square. Squares: 6 free at the start, 9 expansion tiers up to 24
  (Coins and Renown). The 150-square ceiling is a model parameter only (decision 1).
- **Visits.** A visit is a session start. At a visit: harvest what is ripe (one harvest per square, then the square is empty), sell it (pet multiplier at
  sale time, like `CoinRewards.Grant`), buy seeds (a real cost), replant. Ripe crops wait and never rot. A crop grows `online_rate` hours per online hour
  and `offline_rate` hours per offline hour (capped), so a long crop may span several visits; the player plants the crop with the best net per square and wall-clock hour.
- **Gardener.** A Green-thumb pet (35 % of hatched pets) on a Field post replants and re-harvests `squares` squares (1, +1 with the coverage upgrade)
  by itself from the seed stock, up to the barn capacity (40 + 20 per barn level), at the same online / offline rates. Posts are the existing pens (same prices).
- **Renown** = derived level from harvests (points per harvest 1 / 3 / 6 / 12 by tier, level L needs 3 x L^1.6 points); gates tier-2 crops (8), tier-3 (25)
  and the expansion tiers. The request board and stations are placeholders (`requests_per_day = 0`).
- **Rare crops** come only from the obby: 1 seed for the first Gold of a stage, 1 daily seed for the first run of a day. Half of a rare harvest is sold.
- **Garden modes.** `field` (default): pens become Field posts, no Coins-per-hour production. `pens`: today's game. `both`: grandfather.
- **Purchases.** Field items are merged into each policy's buying order by price (x 1.5 for talent-first, x 0.7 for pets-first); the reserved sink ladder is bought last.

## Guardrails (hard `check` items; numbering as in ROADMAP → E0)

| Check | Definition in the model | Result (6 seeds x 2 policies) |
|---|---|---|
| 4 A, 24-hour rule | The field's **online ceiling** on every day (Gardener squares cycle 24 h at `online_rate`, the others get the best plan of a player present for every gap; sales x multiplier minus seeds) divided by the player's **first obby hour of a fresh day at the same progress** (also x multiplier). <= 1.0x every day, every archetype x policy. Offline can only be lower | Obby main 0.95x worst, Casual 0.95x, Garden main 0.80x, Binge 0.52x |
| 4 A target | The best-developed archetype at day 60 lies in 0.8-1.0x | 0.95x (Obby main) |
| 5 B | The same field without any Gardener has a lower 24 h potential and a lower realised net per day | Net per day with / without: Obby main 6 787 / 6 252, Casual 4 539 / 3 912, Garden main 3 847 / 3 553, Binge 374 / 120 (**thin margin**, see finding 5) |
| 6 C | Sinks / cumulative faucet >= 60 % by day 30 and >= 80 % by day 60 (**open decision 1**: `FIELD["sink_share"]`) | 94-97 % / 95-97 % incl. the reserved ladder (decision 4) |
| 6 garden share | Obby main: garden (field + pens) <= 50 % of income. Others only reported | Obby main 25 %, Casual 31 %, Garden main 72 %, Binge 8 % |
| O online / offline | Garden income per online hour >= 1 / `offline_rate` x per offline hour, and offline income exists | 3.2x Obby main, 3.5x Casual, 3.1x Garden main, 54x Binge |

Archetypes: Obby main (2 h obby, visits 7:00 / 12:30 / 18:00, 3.5 h online a day), Casual (45 min, 8:00 / 19:00, 1 h), Garden main (15 min, 7 / 12 / 17 / 21, 2 h), Binge (one 6 h day a week, 0.9 h a day).

## Online vs offline: what it does to each archetype

| Archetype | Field net / day | Share of garden income earned online | Per hour online / offline | Realised net / first obby hour (ceiling 0.95x) |
|---|---|---|---|---|
| Obby main | 6 700 | 35 % | 810 / 253 = 3.2x | 0.44x |
| Casual | 4 500 | 13 % | 727 / 206 = 3.5x | 0.30x |
| Garden main | 3 700 | 22 % | 520 / 165 = 3.1x | 0.27x |
| Binge | 370 | 67 % | 333 / 6 = 54x | 0.03x |

With `offline_rate = 1` (no rule) the same field pays 13 700 / 14 200 / 12 800 / 500 a day: the rule costs the three active archetypes about half to two thirds of their field
income, and Binge almost all of it. Findings:
- The per-hour ratio holds by construction (>= 1 / `offline_rate`), but the **share** of income earned online stays low (13-35 %) because online hours are few (1-3.5 h of 24).
  At `offline_rate` 0.1 the online share becomes 68 % (Obby main), 31 % (Casual), 49 % (Garden main), 88 % (Binge) but the field pays only 3 300 / 2 000 / 1 400 / 230 a day; a 4 h cap gives Obby main 50 %.
  A 45-minute player cannot get a majority online at any sensible rate.
- **Binge is nearly cut off** (field 370 a day, garden 8 % of income): one session a week plus a 12 h offline cap leaves ~10 growth hours a week. The cap is the lever: 24 h lifts Binge to
  600 a day, 48 h to 970 (ratio still 15x); Obby main / Casual / Garden main do not change above 12 h (their gaps are shorter).
- **Garden main is the other one to watch:** 0.27x of the first obby hour at 2 h online, and it never completes the field in 60 days.
- Pens (`--garden pens`): the weighted pen hours drop from 21.5 to 9.4 a day for Obby main and 22.5 to 8.8 for Garden main (Casual 17.0 to 6.3, Binge 2.0 to 1.2).
- Sensitivity of the field net per day (Obby main / Casual / Garden main / Binge): `offline_rate` 0.2 -> 4 100 / 3 100 / 2 400 / 370; 0.5 -> 7 600 / 7 000 / 5 600 / 270; cap 8 h -> 5 300 / 3 500 / 3 600 / 370; cap 24 h -> as 12 h except Binge 600.

## Recommended parameters (provisional)

**Ladder scale 0.15** of the EXPANSION §5 numbers: net Coins per square-hour 3.0 / 6.7 / 13.5 / 22.5 (rare) instead of 20 / 45 / 90 / 150. Seed = 25 % of the sale.

| Crop (MVP, 7) | Tier | Grow | Sale | Seed | Net | Unlock |
|---|---|---|---|---|---|---|
| Potato | 1 | 3 h | 12 | 3 | 9 | start |
| Corn | 2 | 6 h | 54 | 14 | 40 | Renown 8 |
| Pumpkin | 2 | 8 h | 72 | 18 | 54 | Renown 8 |
| Giant melon | 3 | 12 h | 216 | 54 | 162 | Renown 25 |
| Rare W1 / W2 / W3 | rare | 6 / 8 / 10 h | 180 / 240 / 300 | 45 / 60 / 75 | 135 / 180 / 225 | obby seeds only |

Optional (`--crops full`): Radish 20 min, Carrot 1 h (tier 1), Trophy pumpkin 2 x 2 (tier 3). They change income by less than 1 %.

| Expansion tier | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
|---|---|---|---|---|---|---|---|---|---|
| Squares | 8 | 10 | 12 | 14 | 16 | 18 | 20 | 22 | 24 |
| Price | 800 | 2 000 | 4 000 | 7 500 | 12 000 | 18 000 | 28 000 | 42 000 | 65 000 |
| Renown | 1 | 3 | 5 | 8 | 11 | 14 | 17 | 20 | 24 |

Upgrades: growth -5 % grow time per level (3 000 / 8 000 / 20 000 / 45 000), barn +20 capacity (1 500 / 4 000 / 10 000 / 25 000 / 60 000), Gardener
coverage +1 square per Gardener (12 000). Total field sinks: squares 179 300 + upgrades 188 500 + seeds 30 000-60 000. Reserved sink ladder (landmark Coins
parts, estate, decor, stations; not designed): 20 steps from 8 000 x 1.3^k, bought last.

Time to buy (median day, Obby main / Casual / Garden main / Binge, talent-first): field tier 1 on day 2 / 1 / 1 / 8; tier 5 on 10 / 21 / 44 / 36; tier 9 on 26 / 58 / - / -.

## Decisions taken and findings

1. **The ladder as written does not fit a big field.** With 20 / 45 / 90 / 150 per square-hour the 24-hour rule allows 4-7 squares at the last stage
   (first obby hour 10 188, 15 078 with the multiplier). The 150-square ceiling would need a ladder scale of about 0.04 (a potato selling for 3 Coins). The tuned
   pair is scale 0.15 and 6 -> 24 squares; **the plot rework needs to draw 24 squares (30 with margin), not 150.** Squares x ladder scale is what the rule limits (`report` section 8).
2. **The online ceiling is a property of the field, not of the player.** Obby main and Casual (long gaps, long crops) sit at 0.95x of the ceiling, Garden main at 0.70x, Binge 0.52x;
   about half of the ceiling is the Gardener part. It is sensitive to the ladder scale, squares per Gardener, the growth upgrade and the tier-3 gate (table below). The ceiling is
   independent of `online_rate` / `offline_rate`; those only move the realised income.
3. **Catalogue: six is enough, seven is recommended.** The smallest set (Potato, Pumpkin, Giant melon + one rare per world) passes every check; adding Corn (the 6 h slot) lifts the
   income of the active archetypes by about 10 %. Carrot and Radish are never the best crop and the 2 x 2 Trophy pumpkin changes nothing: leave them out of the MVP.
4. **Sink share needs the reserved ladder.** Existing sinks plus the field absorb 38 % (Obby main) and 70 % (Casual) of the cumulative faucet by day 60. To reach 80 % an
   Obby-main player needs about **0.72 M Coins** of further sinks (landmarks, estate, decor, stations), Casual 0.08 M; the online / offline rule shrank the field income, so this need fell from 0.97 M.
5. **Gardener advantage is thin under the rule.** With the rule a manual field already spans visits with long crops, so the Gardener adds only +8 % (Obby main), +16 % (Casual),
   +8 % (Garden main) of realised net (it was +12 % to +3 600 % before). B still holds, but the margin is small and flips with several parameters in the sensitivity run
   (scale +20 %, coverage 2, seed share, expansion prices, tier-3 gate): the Gardener needs a bigger edge (more squares per Gardener would break A; a faster offline rate for Gardeners only would not).
6. **Pen migration.** `--garden both` (grandfathered pens that pay and work as posts) breaks the 24-hour rule (worst day 2.2-2.7x with unweighted pens) and today's `pens` already break it at full
   progress; the model supports **replacing the Coins-per-hour production** when the posts arrive (open decision 3 only decides about a one-time payout).
7. **Rare supply** from the obby: 8.9 seeds a week (Obby main), 7.0 (Casual), 3.3 (Binge), 2.3 (Garden main). Check 8 (landmark need) is still to do.
8. **Early game is deliberately small.** The field pays little in the first week and the obby stays the opening; A stays under 0.5x in the first week for the active archetypes.

**Sensitivity of A (one-off, worst archetype on any day; not yet a `check` item):** ladder scale +20 % -> 1.14x (FAIL), -20 % -> 0.77x; squares per Gardener 1 -> 2 -> 1.01x;
growth step 5 -> 7 % -> 1.01x; tier-3 gate 25 -> 12 or 15 -> 1.05x (FAIL: the gate keeps the early field below the first obby hour); seed share 25 -> 30 % -> 0.98x; expansion prices +-20 %,
Renown k, barn capacity, Green-thumb share and the rare sale share do not move A. Flag scale, Gardener coverage, growth speed and the tier-3 gate for telemetry in M6a.

## Open decisions for the user

1. **Sink share:** keep 60 % by day 30 / 80 % by day 60 (needs about 0.7 M Coins of landmark / estate / decor sinks for an Obby-main player), or lower it.
2. **Time-to-afford bands for repricing** (E0b): the field timeline above is available to propose them against; not started.
3. **Live players / pen migration:** replace the Coins-per-hour pens (the model's recommendation), with or without a one-time payout.
4. **Field size and scale:** accept 24 squares at ladder scale 0.15 (potato 12 / melon 216 Coins), or fewer squares with larger numbers (12 squares at about scale 0.3)?
5. **Online / offline numbers (new):** `offline_rate` 0.33 and a field offline cap of 12 h are placeholders. At 0.33 the active archetypes lose half of their field income and earn only 13-35 % of it online;
   Binge is almost cut off. Choose the rate (0.2 = stronger reason to stay, 0.5 = gentler) and the cap (24-48 h helps only Binge).
6. **Casual** is no longer a garden-majority player (31 %); only Garden main is (72 %), as ROADMAP Q5 wants. Nothing to decide unless the rule changes.

## Inputs ready for E1 (copy into `CropConfig` after the decisions above)

Crop table, expansion tiers and upgrade prices above; Renown formula k = 3, p = 1.6 and weights 1 / 3 / 6 / 12; Gardener 1 (+1) squares per Green-thumb pet; barn 40 (+20);
rare seeds 1 per first Gold and 1 daily; passive rates `online_rate` 1.0 / `offline_rate` 0.33 and the offline cap (server `os.time()` as for pens; growth online needs a present player, never pure AFK).
Telemetry: the model's assumptions about visit schedules and learning speed are the biggest unknowns (M6a).
