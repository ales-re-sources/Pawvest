# Pawvest economy model (E0) — parameters, decisions, how to re-run

**Status: PROVISIONAL (2026-10-24, E0 in progress).** Every number for the crop field, Renown, expansion tiers, upgrades, reserved sinks and
the archetype behaviour is a model assumption until the user confirms it and E1 copies it into `CropConfig`. Numbers that already exist in
the game are read from the Luau configs (drift-pinned). Scope and acceptance checks: [ROADMAP.md](ROADMAP.md) → E0. Design: [EXPANSION.md](EXPANSION.md) §5, §9.

## How to re-run

```
python tools/economy.py check                 # 39 checks incl. guardrails A-C, about 2 s, exit 1 on a failure
python tools/economy.py sim                   # 60-day simulation per archetype x policy, field tables, guardrail lines
python tools/economy.py report                # baseline tables + sections 7-8 (crops, tiers, scale vs field size)
python tools/economy.py field                 # catalogue size and ladder-scale sweep
python tools/economy.py sim --garden both     # grandfathered pens (they pay AND work as posts); --garden pens = today's game
python tools/economy.py check --crops min     # smallest catalogue; --crops full adds Radish, Carrot, 2x2 Trophy pumpkin
python tools/economy.py sim --scale 0.2       # try another ladder scale (all crop prices follow)
```

To change a new number edit the `FIELD` / `CROP_DEFS` / `CATALOGUES` block in `tools/economy.py` and re-run `check`; existing game values are never
edited there (a changed config makes `check` fail until `pin`).

## The field model as simulated

- **One field of squares.** The player plants any unlocked crop on any square. Squares: 6 free at the start, 9 expansion tiers up to 24
  (bought with Coins, gated by Renown). The 150-square ceiling is a model parameter only (see decision 1: it is not needed).
- **Visits.** A visit is a session start of the archetype. At a visit: harvest what is ripe (one harvest per square, the square is then empty),
  sell it (pet multiplier at sale time, like `CoinRewards.Grant`), buy seeds (a real cost), replant. Ripe crops wait and never rot. The player picks the
  crop with the best net per square that is ripe by the next visit.
- **Gardener.** A Green-thumb pet (35 % of hatched pets) on a Field post replants and re-harvests `squares` squares (1, +1 with the coverage
  upgrade) by itself while the player is away, from the seed stock, up to the barn capacity (40 + 20 per barn level). Posts are the existing pens
  (same prices). Crops it plants grow continuously between visits (progress carries over).
- **Renown** = derived level from harvests (points per harvest 1 / 3 / 6 / 12 by tier, level L needs 3 x L^1.6 points); gates tier-2 crops (8), tier-3 (25)
  and the expansion tiers. The request board and stations are placeholders (`requests_per_day = 0`).
- **Rare crops** come only from the obby: 1 seed for the first Gold of a stage (rare of that world), 1 daily seed for the first run of a day. Half of a
  rare harvest is sold, the rest is kept (landmark placeholder).
- **Garden modes.** `field` (default): pens become Field posts, no Coins-per-hour production. `pens`: today's game. `both`: grandfather, pens pay
  Coins per hour AND work as posts.
- **Purchases.** Field items are merged into each policy's buying order by price (field price x 1.5 for talent-first, x 0.7 for pets-first); the
  reserved sink ladder is bought last. Required talents still come first.

## Guardrails (hard `check` items; numbering as in ROADMAP → E0)

| Check | Definition in the model | Result (6 seeds x 2 policies) |
|---|---|---|
| 4 A, 24-hour rule | The field's 24 h potential on every day (Gardener squares cycle 24 h, the others give one harvest per visit, every square always replanted with the best unlocked crop; sales x multiplier, minus seeds) divided by the player's **first obby hour of a fresh day at the same progress** (also x multiplier). Must be <= 1.0x on every day for every archetype and policy | Obby main 0.85x worst, Casual 0.95x, Garden main 0.86x, Binge 0.55x |
| 4 A target | The best-developed archetype at day 60 lies in 0.8-1.0x | 0.95x (Casual), both policies |
| 5 B | The same field without any Gardener has a lower 24 h potential **and** a lower realised net per day (a manual field harvests at most once per square per visit) | Net per day with / without Gardeners: Obby main 12 597 / 9 454, Casual 14 098 / 12 578, Garden main 8 507 / 2 173, Binge 4 421 / 120 |
| 6 C | Sinks / cumulative faucet >= 60 % by day 30 and >= 80 % by day 60 (**open decision 1**: thresholds are `FIELD["sink_share"]`) | 94-98 % / 95-98 % (incl. the reserved ladder, see decision 4) |
| 6 garden share | Obby main: garden (field + pens) income <= 50 % of income. Others only reported | Obby main 39 %, Casual 58 %, Garden main 84 %, Binge 51 % |

Archetypes: Obby main (2 h obby, visits 7:00 / 12:30 / 18:00), Casual (45 min, 8:00 / 19:00), Garden main (15 min, 7 / 12 / 17 / 21), Binge (one 6 h day a week).

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
coverage +1 square per Gardener (12 000). Total field sinks: squares 179 300 + upgrades 188 500 + seeds ~130 000 (Obby main, 60 days).
Reserved sink ladder (landmark Coins parts, estate, decor, stations; not designed): 20 steps from 8 000 x 1.3^k, bought last.

Time to buy (median day, Obby main / Casual / Garden main / Binge, talent-first): field tier 1 on day 1 / 1 / 1 / 8; tier 5 on 9 / 17 / 41 / 36; tier 9
on 23 / 42 / - / -. Garden main never completes the field in 60 days.

## Decisions taken and findings

1. **The ladder as written does not fit a big field.** With 20 / 45 / 90 / 150 per square-hour the 24-hour rule allows 4-7 squares at the last stage
   (first obby hour 10 188, 15 078 with the multiplier). The 150-square ceiling would need a ladder scale of about 0.04 (a potato selling for 3
   Coins). The tuned pair is scale 0.15 and a field of 6 -> 24 squares; **the plot rework needs to draw 24 squares (30 with margin), not 150.** The trade-off
   is linear: squares x ladder scale is what the rule limits (`report` section 8).
2. **Visit-bound players are the binding case.** Ripe crops wait, so a player with long gaps between visits harvests the 12 h melon every visit:
   Casual (gaps 11 h / 13 h) reaches 0.95x with a field that leaves Garden main (gaps 4-5 h) at 0.70x. The Gardener part is more than half of the
   potential (0.53x of 0.84-0.95x). The rule is sensitive to the ladder scale, the coverage per Gardener and the growth upgrade (table below).
3. **Catalogue: six is enough, seven is recommended.** The smallest set (Potato, Pumpkin, Giant melon + one rare per world) passes every check;
   adding Corn (the 6 h slot, with the growth upgrade it fits Obby main's 5.5 h gaps) lifts Obby main's field income by 10 %. Carrot and Radish are never the best
   crop for any archetype (nobody revisits within 3 h) and the 2 x 2 Trophy pumpkin changes nothing: leave them out of the MVP.
4. **Sink share needs the reserved ladder.** Existing sinks plus the field absorb only 35 % (Obby main) and 53 % (Casual) of the cumulative faucet by day 60 (the field itself
   about 0.5 M Coins). To reach the proposed 80 % a 2-hour player needs about **0.97 M Coins** and a 45-minute player 0.36 M of further sinks (landmark Coins parts,
   estate, decor, stations): E6 / E7 content has to supply them, or the threshold is lowered. The check passes with the placeholder ladder and prints both values.
5. **Pen migration.** `--garden both` (grandfathered pens that pay and work as posts) breaks the 24-hour rule (worst day 2.2-2.7x) and puts Obby main's garden share at
   53 %; today's `pens` already break it at full progress (baseline finding). The model therefore supports **replacing the Coins-per-hour production** when the posts arrive
   (open decision 3 only decides whether live players get a one-time payout instead).
6. **Rare supply** from the obby: 8.9 seeds a week (Obby main), 6.9 (Casual), 3.3 (Binge), 2.3 (Garden main). Check 8 (landmark need) is still to do.
7. **Early game is deliberately small.** The field pays 1-9 % of income in the first week (Obby main day 7: 1 600 of 18 000) and reaches a third (Obby main) to a half
   (Casual) of income by day 14, so the obby stays the opening and the 24-hour rule is not strained early (A stays under 0.5x in the first week for the three active archetypes).

**Sensitivity (one-off, Casual / worst archetype A on any day, 6 seeds; not yet a `check` item):** ladder scale +20 % -> 1.14x (FAIL), -20 % -> 0.76x (below the
band); squares per Gardener 1 -> 2 -> 1.09x (FAIL); growth step 5 -> 7 % -> 1.01x (FAIL); seed share 25 -> 30 % -> 0.98x; expansion prices +-20 %, Renown
gates, Renown k, barn capacity, Green-thumb share and the rare sale share do not move A. Flag scale, Gardener coverage and growth speed for telemetry in M6a.

## Open decisions for the user

1. **Sink share:** keep 60 % by day 30 / 80 % by day 60 (needs about 1 M Coins of landmark / estate / decor sinks for an Obby-main player), or lower it.
2. **Time-to-afford bands for repricing** (E0b): the model now has the field timeline above to propose them against; not started.
3. **Live players / pen migration:** replace the Coins-per-hour pens (the model's recommendation) with or without a one-time payout; depends on how many live pen incomes exist.
4. **Field size and scale:** accept 24 squares at ladder scale 0.15 (potato 12 / melon 216 Coins), or a smaller field with larger numbers (12 squares at about scale 0.3)?
5. **Casual is a garden-majority player (58 %)** because 45 minutes of obby are worth less than a developed field at the 24-hour rule's 0.95x; ROADMAP Q5 wants a majority only for Garden main.
   Accept, or lower the field to about 0.75x (below the 0.8-1.0 target band).

## Inputs ready for E1 (copy into `CropConfig` after the decisions above)

Crop table, expansion tiers and upgrade prices above; Renown formula k = 3, p = 1.6 and weights 1 / 3 / 6 / 12; Gardener 1 (+1) squares per Green-thumb pet; barn 40 (+20);
rare seeds 1 per first Gold and 1 daily. Telemetry: the model's assumptions about visit schedules and learning speed are the biggest unknowns (M6a).
