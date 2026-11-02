# Pawvest economy model (E0) — parameters, decisions, how to re-run

**Status: PROVISIONAL (2026-10-24, E0 in progress).** Every number for the crop field, Renown, expansion tiers, upgrades, reserved sinks, the online /
offline rates and the archetype behaviour is a model assumption until the user confirms it and E1 copies it into `CropConfig`. Numbers that already
exist in the game are read from the Luau configs (drift-pinned). Scope and acceptance checks: [ROADMAP.md](ROADMAP.md) → E0. Design: [EXPANSION.md](EXPANSION.md) §2, §5, §12.

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
edited there (a changed config makes `check` fail until `pin`). The crop field's numbers that live in `src/ReplicatedStorage/CropConfig.luau` (crops, squares,
expansions, Renown, barn, online / offline rates) are read from it and pinned (`crop_field_*`); Radish / Carrot / Trophy pumpkin and the rare crops stay model-only.

## The rules as simulated

- **Online beats offline (user rule 2026-10-24).** Offline income must exist, online income (even passive) must be much higher, as a reason to keep Roblox open.
  Two parameters, not constants: `online_rate = 1.0` and `offline_rate = 0.33` (online roughly 3x; **the user gave no number, open decision 5**). They apply
  to everything passive: crop growth, Gardener replanting and the old pen production (`--garden pens|both`). Offline time is capped after each session:
  `offline_cap_h = 12` for the field (provisional, open decision 5), 8 h for pens (GardenConfig). Roblox does not pay for uptime any more (Engagement-Based
  Payouts ended 2025-07-24; Creator Rewards pays per Active Spender), so this is a retention / monetization design choice: **the model pays nothing for pure AFK**,
  growth only counts as "online" during the archetype's session hours, and the 24-hour rule is checked for the online case only.
- **One field of squares.** The player plants any unlocked crop on any square. Squares: 4 free at the start, 8 expansion tiers up to 12
  (Coins and Renown); the field is capped at 12 squares (decision 1).
- **Visits.** A visit is a session start. At a visit: harvest what is ripe (one harvest per square, then the square is empty), sell it (pet multiplier at
  sale time, like `CoinRewards.Grant`), buy seeds (a real cost), replant. Ripe crops wait and never rot. A crop grows `online_rate` hours per online hour
  and `offline_rate` hours per offline hour (capped), so a long crop may span several visits; the player plants the crop with the best net per square and wall-clock hour.
- *Superseded 2026-10-30 (EXPANSION §3–§4), model not updated yet:* pets stand on field squares with a reach that grows with the aptitude level
  (own square, then 5, then 3 × 3), a few field pet slots instead of 6 posts, Tending as an aptitude with levels 1–10; stage finishes drop a seed
  pouch and fill a rare-seed meter (Scouting). The E0 re-run must model reach, Tending strength, slots and the seed pouch (ROADMAP → E0 inputs).
- **Gardener.** A Green-thumb pet (35 % of hatched pets) on a Field post replants and re-harvests `squares` squares (1; no coverage upgrade, see below)
  by itself from the seed stock, up to the barn capacity (40 + 20 per barn level), at the same online / offline rates. Posts are the existing pens (same prices).
- **Renown** = derived level from harvests (points per harvest 1 / 3 / 6 / 12 by tier, level L needs 3 x L^1.6 points); gates tier-2 crops (8), tier-3 (25)
  and the expansion tiers. The request board and stations are placeholders (`requests_per_day = 0`).
- **Rare crops** come only from the obby: 1 seed for the first Gold of a stage, 1 daily seed for the first run of a day. Half of a rare harvest is sold.
- **Garden modes.** `field` (default): pens become Field posts, no Coins-per-hour production. `pens`: today's game. `both`: grandfather.
- **Purchases.** Field items are merged into each policy's buying order by price (x 1.5 for talent-first, x 0.7 for pets-first); the reserved sink ladder is bought last.

## Guardrails (hard `check` items; numbering as in ROADMAP → E0)

| Check | Definition in the model | Result (6 seeds x 2 policies) |
|---|---|---|
| 4 A, 24-hour rule | The field's **online ceiling** on every day (Gardener squares cycle 24 h at `online_rate`, the others get the best plan of a player present for every gap; sales x multiplier minus seeds) divided by the player's **first obby hour of a fresh day at the same progress** (also x multiplier). <= 1.0x every day, every archetype x policy. Offline can only be lower | Obby main 0.95x worst, Casual 0.95x (**1.04x on day 16 since S8.2**: Dash split into Dash 5 000 + Long Dash 3 000; accepted by the user 2026-10-26, the check stays red as a reminder), Garden main 0.87x, Binge 0.27x |
| 4 A target | The best-developed archetype at day 60 lies in 0.8-1.0x | 0.95x (Casual / Obby main) |
| 5 B | The same field without any Gardener has a lower 24 h potential and a lower realised net per day | Net per day with / without: Obby main 6 580 / 6 155, Casual 4 713 / 4 115, Garden main 4 293 / 3 914, Binge 324 / 267 (**thin margin**, finding 5) |
| 6 C | Sinks / cumulative faucet >= 60 % by day 30 and >= 80 % by day 60 (**open decision 1**: `FIELD["sink_share"]`) | 93-97 % / 93-97 % incl. the reserved ladder (finding 4) |
| 6 garden share | Obby main: garden (field + pens) <= 50 % of income. Others only reported | Obby main 25 %, Casual 32 %, Garden main 73 %, Binge 7 % |
| O online / offline | Garden income per online hour >= 1 / `offline_rate` x per offline hour, and offline income exists | 3.3x Obby main, 3.5x Casual, 3.2x Garden main, 59x Binge |

**Update 2026-10-30:** World 3's tBase was cut to the developer's runs (55 / 50 / 45 / 95 / 55, GDD §4), which shortens the modelled obby hour; A is now 0.81x worst for Obby main, 0.92x Casual, 0.84x Garden main, 0.29x Binge, and the day-60 target sits at 0.80x (Casual), the bottom of the band. The 0.95x figures in this file are from before; re-tune the ladder scale in the repricing step if the band should be met with margin.

Archetypes: Obby main (2 h obby, visits 7:00 / 12:30 / 18:00, 3.5 h online a day), Casual (45 min, 8:00 / 19:00, 1 h), Garden main (15 min, 7 / 12 / 17 / 21, 2 h), Binge (one 6 h day a week, 0.9 h a day).

## Online vs offline: what it does to each archetype

| Archetype | Field net / day | Share of garden income earned online | Per hour online / offline | Realised net / first obby hour (ceiling 0.95x) |
|---|---|---|---|---|
| Obby main | 6 600 | 36 % | 782 / 244 = 3.3x | 0.43x |
| Casual | 4 700 | 13 % | 743 / 213 = 3.5x | 0.31x |
| Garden main | 4 300 | 22 % | 571 / 183 = 3.2x | 0.30x |
| Binge | 320 | 70 % | 318 / 6 = 59x | 0.02x |

With `offline_rate = 1` (no rule) the same field pays about 13 900 / 13 900 / 12 700 / 440 a day: the rule costs the three active archetypes about half to two thirds of their field
income, and Binge most of it. Findings:
- The per-hour ratio holds by construction (>= 1 / `offline_rate`), but the **share** of income earned online stays low (13-36 %) because online hours are few (1-3.5 of 24).
  At `offline_rate` 0.1 the online share becomes 67 % (Obby main), 32 % (Casual), 48 % (Garden main), 94 % (Binge) but the field pays only about 3 500 / 1 800 / 1 800 / 230 a day; a 4 h cap gives Obby main 51 %.
  A 45-minute player cannot get a majority online at any sensible rate.
- **Binge is nearly cut off** (field 320 a day, garden 7 % of income): one session a week plus a 12 h offline cap leaves ~10 growth hours a week. The cap helps only a little now: 24 h gives
  Binge about 400 a day (48 h: no further gain, the 12-square field is too small to use it); Obby main / Casual / Garden main do not change above 12 h (their gaps are shorter).
- **Garden main is the other one to watch:** 0.30x of the first obby hour at 2 h online, and it does not finish the field within 60 days (tier 6 of 8 on day 52).
- Pens (`--garden pens`): the weighted pen hours drop from 21.5 to 9.4 a day for Obby main and 22.5 to 8.8 for Garden main (Casual 17.0 to 6.3, Binge 2.0 to 1.2).
- Sensitivity of the field net per day (Obby main / Casual / Garden main / Binge, 4 seeds): `offline_rate` 0.2 -> 4 800 / 3 000 / 2 600 / 320; 0.5 -> 7 500 / 7 100 / 6 300 / 320 (A worst reaches 1.00x);
  cap 8 h -> 5 400 / 3 300 / 4 100 / 340; cap 24 h -> as 12 h except Binge 400.

## Recommended parameters (provisional)

**Field: 12 squares at ladder scale 0.3** (decided 2026-10-25, open decision 4: fewer squares, larger numbers). The ladder of EXPANSION §5 times 0.3: net Coins per square-hour 6 / 13.5 / 27 / 45 (rare)
instead of 20 / 45 / 90 / 150. Seed = 25 % of the sale. **The plot rework needs to draw 12 squares.**

| Crop (MVP, 7) | Tier | Grow | Sale | Seed | Net | Unlock |
|---|---|---|---|---|---|---|
| Potato | 1 | 3 h | 24 | 6 | 18 | start |
| Corn | 2 | 6 h | 108 | 27 | 81 | Renown 8 |
| Pumpkin | 2 | 8 h | 144 | 36 | 108 | Renown 8 |
| Giant melon | 3 | 12 h | 432 | 108 | 324 | Renown 25 |
| Rare W1 / W2 / W3 | rare | 6 / 8 / 10 h | 360 / 480 / 600 | 90 / 120 / 150 | 270 / 360 / 450 | obby seeds only |

Optional (`--crops full`): Radish 20 min, Carrot 1 h (tier 1), Trophy pumpkin 2 x 2 (tier 3). They change income by less than 1 %.

| Expansion tier | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|
| Squares (start 4) | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
| Price | 600 | 1 500 | 3 500 | 7 500 | 14 000 | 24 000 | 40 000 | 65 000 |
| Renown | 1 | 2 | 4 | 7 | 10 | 14 | 19 | 25 |

Upgrades: growth -5 % grow time per level (3 000 / 8 000 / 20 000 / 45 000), barn +20 capacity (1 500 / 4 000 / 10 000 / 25 000 / 60 000). **There is no Gardener coverage upgrade any more:** on 12 squares
one more square per Gardener (6 posts) would cover the whole field and put A at 1.06x. Total field sinks: squares 156 100 + upgrades 176 500 + seeds 30 000-60 000.
Reserved sink ladder (landmark Coins parts, estate, decor, stations; not designed): 20 steps from 8 000 x 1.3^k, bought last.

Time to buy (median day, Obby main / Casual / Garden main / Binge, talent-first): field tier 1 on day 2 / 2 / 1 / 8; tier 4 on 4 / 9 / 21 / 15; tier 8 on 26 / 55 / - / -.

## Decisions taken and findings

1. **Field size and scale (decided 2026-10-25).** The ladder as written (20 / 45 / 90 / 150) allows only 4-7 squares under the 24-hour rule at the last stage
   (first obby hour 10 188, 15 078 with the multiplier). Squares x ladder scale is what the rule limits: 12 squares all manual would allow scale 0.48, 24 squares 0.24, 150 squares 0.04. The chosen
   12 squares at 0.3 leave half of the squares Gardener-covered (a covered square is worth more than a manual one), which is why the scale is below 0.48 (`report` section 8).
2. **The online ceiling is a property of the field, not of the player.** Obby main and Casual (long gaps, long crops) sit at 0.95x, Garden main 0.76x at day 60, Binge 0.26x (its Renown stays below the tier-3 gate, so it never plants melons);
   about half of the ceiling is the Gardener part. It is sensitive to the ladder scale, squares per Gardener, the growth upgrade and the tier-3 gate (table below), and is
   independent of `online_rate` / `offline_rate`; those only move the realised income.
3. **Catalogue: six is enough, seven is recommended.** The smallest set (Potato, Pumpkin, Giant melon + one rare per world) passes every check; adding Corn (the 6 h slot) lifts the
   income of the active archetypes by about 10 %. Carrot and Radish are never the best crop and the 2 x 2 Trophy pumpkin changes nothing: leave them out of the MVP.
4. **Sink share needs the reserved ladder.** Existing sinks plus the field absorb 36 % (Obby main) and 68 % (Casual) of the cumulative faucet by day 60. To reach 80 % an
   Obby-main player needs about **0.76 M Coins** of further sinks (landmarks, estate, decor, stations), Casual 0.10 M.
5. **Gardener edge with 12 squares: still thin.** Realised net with / without Gardeners: Obby main +7 %, Casual +15 %, Garden main +10 %, Binge +21 % (24 squares: +9 / +16 / +8 / +212 %); the 24 h
   potential gap is larger (14 200 vs 12 600). A manual field already spans visits with long crops, so the Gardener only saves the idle time between ripening and the next visit. B still holds, but it flips with
   two parameters in the sensitivity run (expansion prices -20 %, rare sale share 1.0). The Gardener needs a bigger edge by design (for example an exclusive crop tier, or replanting during a visit), not by more coverage (that breaks A).
6. **Pen migration.** `--garden both` (grandfathered pens that pay and work as posts) breaks the 24-hour rule (worst day 2.3-2.6x) and today's `pens` already break it at full
   progress; the model supports **replacing the Coins-per-hour production** when the posts arrive (open decision 3 only decides about a one-time payout).
7. **Rare supply** from the obby: 8.9 seeds a week (Obby main), 7.0 (Casual), 3.3 (Binge), 2.3 (Garden main). Check 8 (landmark need) is still to do.
8. **Early game is deliberately small.** The field pays little in the first week and the obby stays the opening; A stays under 0.5x in the first week for the active archetypes.
9. **All built talents are affordable after World 2 (checked and kept 2026-10-27).** A replay from a reset profile (Gold on Tutorial + Stages 1-9, no admin Coins)
   earned 27 275 one-time (medals 22 750, finishes 1 625, challenge coins 2 900) plus about 4 700 from repeat runs, the pet bonus and pens, and bought every built
   talent (25 300), slot 2 and pens 2-3 with 1 163 left. That matches the model: the built tree is only 25 300 of the planned 47 300 (44 300 and a built
   tree of 22 300 since Double Jump became a world reward, K1 2026-11-01; Wall Jump 10 000 and Glide
   12 000 come in S9). Prices stay as they are until those two are built; revisit then. A ~11 000 gap in an earlier playthrough was the admin "+Coins" button
   (10 000), so check for it before suspecting a leak.

**Sensitivity of A (one-off, worst archetype on any day; not yet a `check` item):** ladder scale +20 % -> 1.14x (FAIL), -20 % -> 0.77x; squares per Gardener 1 -> 2 -> 1.06x (FAIL);
growth step 5 -> 7 % -> 1.01x (FAIL); tier-3 gate 25 -> 12 or 15 -> 1.28x (FAIL: the gate keeps the early field below the first obby hour); seed share 25 -> 30 % -> 0.98x; Renown k 3 -> 2.4 -> 0.99x;
expansion prices +-20 %, barn capacity, Green-thumb share and the rare sale share do not move A. Flag scale, Gardener coverage, growth speed and the tier-3 gate for telemetry in M6a.

## Open decisions for the user

1. **Sink share:** keep 60 % by day 30 / 80 % by day 60 (needs about 0.8 M Coins of landmark / estate / decor sinks for an Obby-main player), or lower it.
2. **Time-to-afford bands for repricing** (E0b): the field timeline above is available to propose them against; not started.
3. **Live players / pen migration:** replace the Coins-per-hour pens (the model's recommendation), with or without a one-time payout.
4. ~~Field size and scale~~ **Decided 2026-10-25:** 12 squares at ladder scale about 0.3.
5. **Online / offline numbers:** `offline_rate` 0.33 and a field offline cap of 12 h are placeholders (the user gave no number). At 0.33 the active archetypes lose half of their field income and earn only 13-36 % of it online;
   Binge is almost cut off. Choose the rate (0.2 = stronger reason to stay, 0.5 = gentler, A reaches 1.00x) and the cap (24 h helps only Binge, a little).

## Inputs ready for E1 (copy into `CropConfig` after the decisions above)

Crop table, expansion tiers and upgrade prices above; Renown formula k = 3, p = 1.6 and weights 1 / 3 / 6 / 12; Gardener 1 square per Green-thumb pet; barn 40 (+20);
rare seeds 1 per first Gold and 1 daily; passive rates `online_rate` 1.0 / `offline_rate` 0.33 and the offline cap (server `os.time()` as for pens; growth online needs a present player, never pure AFK).
Telemetry: the model's assumptions about visit schedules and learning speed are the biggest unknowns (M6a).
