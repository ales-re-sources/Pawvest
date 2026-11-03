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
- **Field pets** (E0 re-run 2026-11-02, replaces the Gardener on a post): a Tending pet stands on a square and works its reach, counted on the
  4-column grid: levels 1-3 its own square, 4-6 plus the 4 next to it, 7-10 the 3 x 3 block; one pet per square; the same job does not stack.
  **Tending strength** s (20 / 35 / 48 / 59 / 68 / 76 / 83 / 89 / 95 / 100 % by level) is the chance the pet harvests and replants a ripe crop
  at once; otherwise the crop waits for the visit. So a tended square pays the visits' harvests plus s x what continuous cycling adds (s = 0 is
  a manual square, s = 100 % the old continuous Gardener); seeds come from the seed stock, crops go to the barn (40). Crops grow at the same
  online / offline rates whoever plants them. Tending is rolled at hatch (20 / 22 / 40 / 50 / 60 % by rarity, aptitudes at birth / 5),
  levels rise with weighted field time (online + capped offline x 0.33) up to the rarity cap (6-10). Field pet slots replace the pens.
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
| Potato | 1 | 5 min | 2 | 1 | 1 | start (was 3 h / 24 / 6 until 2026-11-02: the user wants a quick first harvest; at 24 / 6 a 5-minute Potato failed six A / O checks, at 2 / 1 everything but the known 5 B passes) |
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

## Field-pet re-run (2026-11-02, gates E1b; `python tools/economy.py pets`)

**Approved by the user 2026-11-02** as the E1b inputs (the two edge findings below stay open):

1. **Field pet slots: 3** (1 free + 2 bought at **2 500 / 9 000** Coins). Simulation (60 days): 1 slot -> A worst 0.88x, 2 -> 0.93x, 3 -> 0.93x,
   **4 -> 1.09x (breaks the 24-hour rule)**. Two pets at level 7+ already cover all 12 squares; the third slot matters while pets are at levels
   4-6 (reach 5: two cover 8, three 10 squares). Statically, a fully developed field (12 squares tended at 100 %) is 0.86x of the first obby
   hour for every archetype, against 0.58x with no pet (Obby main).
2. **Tending at level 10 = continuous cycling** (`tend_max` 1.0): A stays inside the rule with 3 slots; 80 % changes A by 0.03 only.
3. **Aptitude XP:** level L -> L + 1 takes 10 x 1.56^(L-1) weighted field hours (10 / 16 / 24 / 38 / 59 / 92 / 144 / 225 / 351). With the pet on the
   field every day: a Common reaches its cap (L6) in 14 days (Obby main) to 17 (Casual), level 10 takes 93-113 days; Binge (one session a week)
   needs 103 days for L6.
4. **Live pens -> slots:** 1 pen = 1 slot, 2-3 pens = 2 slots, 4-6 pens = 3 slots; the rest is refunded: 3 pens -> 1 000, 5 pens -> 6 000,
   6 pens -> 21 000 Coins (pens up to 6 cost 32 500). Live pets: Tending rolled once from the uid with the hatch chances, starting aptitude level
   ceil(pet level / 4) (level 20 -> 5), at most the rarity cap.
5. **Seed pouch (E2 input):** 0.1 common seeds per medal finish (about 4 per obby hour, 8 at Scouting L10) and a rare-seed meter of 100 finishes
   per rare seed, on top of the daily first-run rare seed: 12.9 / 9.3 / 7.8 / 3.3 rare seeds a week (Obby main / Casual / Garden main / Binge;
   today 8.8 / 7.4 / 2.9 / 3.3), 18.9 for Obby main at Scouting L10.

**Findings.**
- Realised field net per day at day 60 (6 seeds, with / without Tending pets): Obby main 6 333 / 6 171 (+3 %, it visits often), Casual
  5 376 / 4 406 (+22 %), Garden main 4 982 / 4 139 (+20 %); the 24 h potential of Obby main 15 411 vs 12 666. The tender's value is the long
  gaps. Guardrail B passes for 6 of 8 archetype x policy cells.
- **B fails for Binge (equal, not more):** one session a week leaves about 10 growth hours (6 online + 12 h cap x 0.33), so one cycle fits
  either way and a tender cannot add a second one. Options: accept (B as `>=` for archetypes whose week fits one cycle), or let Tending work
  during the session's online hours too (the model counts visits only at session starts, which undervalues a 6-hour session).
- **O sits on its limit for Garden main (3.023x vs 3.03x):** a fully tended field is all passive income, and passive income runs at exactly
  1 / offline_rate more per hour online, so the ratio converges to the rule's own bound; the 0.2 % gap is the online / offline attribution of growth
  in progress. Options: accept equality within 1 % in the check, or keep online play clearly ahead (e.g. Tending only while the owner is away).

## Garden tools re-run (2026-11-02, gates E1c3; `python tools/economy.py tools`)

**Superseded by the direction change below (2026-11-02):** these sizes assume the 24-hour rule (A), which the user wants replaced. The model now has the three tier-1 tools (EXPANSION §6) as field sinks with levels, prices and Renown gates.
- **Seed sorter:** expected size factor × (1 + effect).
- **Cloches:** online growth × (1 + effect), nothing offline.
- **Pruning shears:** chance of a second item, sale × (1 + effect), with no extra Renown or seed.

Two A figures are reported. "Bought" is A with the purchases as simulated. "Maxed" is A with every tool level the player's Renown allows, on every day, Coins aside (EXPANSION §5.5).

| Candidate | A worst (bought / maxed) | Field net per day, Obby main / Garden main |
|---|---|---|
| No tools (today) | 0.94x / 0.94x | 6 333 / 4 943 |
| EXPANSION sizes (sorter +5/10/15 %, Cloches +7/14/20 %, shears 5/10/15 %) | **1.43x / 1.57x** | 10 004 / 5 363 |
| The same × 0.2 / × 0.25 / × 0.33 | 0.97x / 0.99x · 1.00x / 1.01x · 1.04x / 1.04x | about 7 300-7 600 / 4 400-4 550 |
| EXPANSION sizes, crop ladder cut 0.3 → 0.21 / 0.19 | 1.00x / 1.07x · 0.91x / 0.97x | 6 964 / 3 504 · 6 341 / 3 126 |
| **Proposal:** sorter spread only, Cloches +3/5/7 %, shears 2/3/5 % | 0.99x / 1.00x | 6 889 / 4 617 |

**Findings.**
- **Only about +8-10 % of field income fits.** Today's field already uses 0.87x (Obby main) to 0.94x (Garden main) of the first obby hour, and A is an online ceiling that every income tool raises directly.
- **Gains are uneven.** The net gain is larger than the effect, because seeds are not multiplied and faster online growth makes some crops ripen before a visit instead of after it.
- **The EXPANSION sizes need the base crops cut by about a third.** That is ladder 0.19, and Garden main's field would fall from 4 943 to 3 126 a day.
- **A Seed sorter that only widens the roll costs no income.** It keeps the mean at 1 and the Big / Giant factor thresholds at 1.20 / 1.55, so it fits beside the other two. Sigma per level and what it gives:

  | Sigma | Big | Giant | Factor at 1 in 1 000 | Cap (z ±4) |
  |---|---|---|---|---|
  | 0.25 (today) | 20 % | 3.0 % | 2.10 | 2.63 |
  | 0.30 | 22 % | 5.4 % | 2.42 | 3.17 |
  | 0.35 | 24 % | 7.7 % | 2.77 | 3.81 |
  | 0.40 | 26 % | 9.8 % | 3.18 | 4.57 |

  It is the collector's tool: records now, the Harvest Fair later.
- **Tools compete with expansions for Garden main's Coins** (4 943 → 4 617 a day with the proposal). It still finishes the top tool levels late or not at all within 60 days.
- **Purchase timing.** Obby main buys every tool's top level by day 17-33 and Casual by day 28-38. Prices are a first proposal in the band of the Growth upgrade: sorter 5 000 / 15 000 / 40 000 (Renown 10 / 18 / 28), Cloches 4 000 / 12 000 / 30 000 (6 / 14 / 24), shears 6 000 / 18 000 / 45 000 (12 / 20 / 30).

## Direction change: farming is the main game (user, 2026-11-02; numbers open)
The user's words: on day one (one day, less or more, to discuss) farming income is limited to about the obby's; on the following days it should
surpass the obby by far. The obby is complementary at the beginning (more mini-games later), farming is the main game.
This replaces the 24-hour rule (A: the field's 24 h online ceiling at most the first obby hour, every day) and the Obby-main garden share cap (at most 50 %).
The model today does the opposite. Realised field net per day / obby Coins per day (talent-first, mean of 6 seeds):

| Day | Obby main | Casual | Garden main |
|---|---|---|---|
| 1 | 0 / 12 904 | 0 / 6 034 | 8 / 846 |
| 7 | 1 954 / 10 352 | 1 116 / 6 713 | 749 / 3 305 |
| 14 | 5 543 / 26 441 | 1 529 / 8 766 | 908 / 0 |
| 30 | 6 173 / 26 807 | 4 819 / 13 850 | 2 351 / 9 157 |

**Decided by the user 2026-11-02:**
- **Measure:** realised field net per day (sales − seeds) against obby Coins per day (medals, repeat runs, first finishes).
- **Parity (days 1-3):** the field earns at most 1.0x the obby's Coins over the first three days together (a cap only). It is a total, not a cap
  per day (decided after the lever search): the obby's first-clear payouts are too lumpy for a per-day cap.
- **Lead:** at least **3x by day 7** and **10x by day 30**, for Casual and Garden main. Obby main (2 h of obby a day by choice) only needs field ≥ obby by
  day 14; Binge is reported only.
- Unchanged: online ≥ 3x offline per hour (O), sink share (C), required talents per stage.

`economy.py check` now has the checks `4 P` (parity) and `4 L` (lead). The old A and the garden share are only reported.

**First sweeps (2026-11-02, 6 seeds, worst policy).** Each cell is parity (worst of days 1-3) / lead at day 7 / lead at day 30.

| Setting | Obby main | Casual | Garden main |
|---|---|---|---|
| Today (ladder 0.3) | 0.07 / 0.10 / 0.22 | 0.22 / 0.13 / 0.29 | 0.18 / 0.33 / 0.56 |
| Crop prices × 3 (ladder 0.9) | 0.21 / 0.29 / 0.69 | 0.65 / 0.41 / 0.93 | 0.53 / 1.01 / 3.66 |
| **Crop prices × 4.5 (ladder 1.35): parity binds** | 0.31 / 0.41 / 1.00 | **0.98** / 0.62 / 1.53 | 0.79 / 1.66 / 6.62 |
| × 4.5 + EXPANSION-size tools | 0.31 / 0.49 / 1.44 | 0.98 / 0.63 / 2.35 | 0.79 / 1.66 / 7.22 |
| × 4.5 + tools + obby repeat runs × 0.2 | 0.39 / 0.69 / 6.68 | 0.98 / 0.69 / 8.18 | 0.79 / 1.66 / 6.57 |

Findings:
- **Prices can rise about 4.5x before parity binds** (Casual on day 2). That alone gives Garden main 6.6x at day 30, but leaves Casual at 1.5x.
- **The day-7 lead is a ramp problem, not a price problem.** Parity caps day 2-3 at about 1.0x, so the field must triple relative to the obby within four days. Today's early field is flat: 4-6 Potato squares, Corn behind Renown 8, expansions that cost Coins.
  Casual's obby Coins in week 1 are first-clear medals, so cutting repeat-run rewards does not move day 7 (0.62 → 0.69).
- **The day-30 lead runs out of field.** Garden main has only 8 of 12 squares at day 30, and a 12-square cap leaves little room to grow after it.
  Cutting repeat runs helps Casual and Obby main at day 30, because their obby income by then is mostly repeats.
- The levers left are structural:
  - an early field ramp (cheaper or Renown-free first expansions, a mid crop early, faster first tiers);
  - a larger field or more growth axes (squares beyond 12, tools at full size, more crop tiers);
  - smaller obby Coin payouts once the first clears are done (obby rewards shift to seeds, talents and mini-games).

### Lever search (2026-11-02): a candidate that meets the targets (waiting for the user)
A grid over the three levers (sweep scripts in the session scratchpad; the overrides are model-only) found **candidate F1**.

| Lever | Today | F1 |
|---|---|---|
| Crop prices | ladder 0.3 | **× 9.7 (ladder 2.9):** Potato 6 / 2, Corn 1 044 / 261, Pumpkin 1 392 / 348, Giant melon 4 176 / 1 044 (sale / seed); rare crops the same factor |
| Crop gates | Corn and Pumpkin Renown 8, Giant melon 25 | Corn and Pumpkin **Renown 1**, Giant melon **Renown 5** |
| Field size | 12 squares, expansions 600 → 65 000 | **36 squares:** expansions from 1 400, about × 1.23 per square up to about 970 000 (5.1 M in all); squares 5-6 need no Renown, then Renown rises to 60 |
| Tools | none | EXPANSION §6 sizes (Seed sorter +5 / 10 / 15 %, Cloches +7 / 14 / 20 % online, shears 5 / 10 / 15 %) |
| Other field sinks | upgrades, pet slots as in CropConfig | the same × 9.7 |
| Obby Coins | as built | **repeat runs × 0.5** (first clears unchanged) |

Results (6 seeds, worst policy):

| Archetype | Parity, days 1-3 total | Lead day 7 / 14 / 30 | Field net per day, days 54-60 | Obby per day | Garden share |
|---|---|---|---|---|---|
| Obby main | 0.71x | 2.0 / 6.9 / 14.1 (target ≥ 1 by day 14) | 270 800 | 13 500 | 96 % |
| Casual | 0.84x | **2.96** / 7.4 / 14.6 | 189 600 | 7 000 | 97 % |
| Garden main | **1.02x** | 8.6 / 25.8 / 41.5 | 247 900 | 3 300 | 99 % |

O (online ≥ 3x offline per hour) holds at 3.66-4.15x, and C at 93-95 %. With the other sinks scaled the result barely moves: Casual 2.95x at day 7 and 10.2x at day 30, Garden main parity 1.02x.

**What F1 needs decided:**
1. ~~Parity as the total of days 1-3, not each day.~~ **Decided 2026-11-02: the 3-day total.** The obby's first-clear payouts are lumpy: Casual clears one stage on day 2, and Garden main has obby days with 0 Coins.
   Capped per day, the field is limited by the obby's weakest day, and no lever set meets the day-7 lead. With F1 the field earns 1.3-2.1x the obby on its single best day of the three.
2. **The targets sit on the edge.** Casual's day-7 lead (3x) and Garden main's parity trade against each other: ladder 2.85 → 2.91x / 1.00x, ladder 3.0 → 3.06x / 1.05x.
3. **Coins inflate about 40x.** A developed field pays about 200 000 a day (today about 6 000). Talents (44 300 in all), eggs, incubators and stage unlocks become trivial, and every archetype buys every talent.
   Either the obby-side prices scale too, or farming pays in its own currency.
   **Parked idea (user, 2026-11-02):** separate the two incomes. Skills / talents are bought with **stars**, and a cleared obby run rewards
   seeds (or similar) instead of Coins. Not decided: how it would work with the other mini-games planned later.
4. **Sinks:** 1.5-3 M Coins per player by day 60 must go into the still-undesigned reserved ladder (estate, landmarks, decor, stations).
5. **36 squares:** the plot draws 12 today (`GardenView` / `PlotView`, the ring layout). Bigger plots, or a field that grows in another direction (a second field, terraces).
6. **Live game:** the field is admin-only, so its prices can change freely. The repeat-run cut reaches every live obby player.

### F1 decisions (user, 2026-11-03)
- **Inflation accepted.** At 2 Coins a Potato is a bad use of a player's time. Crop prices and the field's own sinks (upgrades, tools, pet slots)
  rise × 9.7, as in F1.
- **The obby supplements.** It fills the money a player is missing and stops being the only income, so it pays less as the player progresses.
  F1 modelled this as repeat runs × 0.5. **Repeat runs stay as they are for now (user, 2026-11-03).** A second or later run of a stage pays tens of
  Coins, which feels right next to a first clear's 1 000+.
  Why they mattered in the model: a Gold repeat pays 50 × the stage's reward factor × 2 × 0.8^(finishes today), so the first runs of a late stage (factor 4-5.25)
  pay 400-525, and ten runs of it pay 1 800-2 300 a day. Once every stage is cleared, the model's Casual spends its 45 obby minutes on those
  and earns about 14 100 a day at day 30 (Obby main about 26 900 in 2 h).
  With repeats kept (F1 otherwise unchanged, 6 columns), Casual's lead is 5.3x at day 30 and reaches 10x only around day 60. Obby main is 5.5x at day 30 (target ≥ 1x by day 14),
  Garden main 28.9x. Casual's 2.8x at day 7 is the same with or without the cut (its week-1 obby Coins are first clears).
- **36 squares, all drawn.** The player unlocks **any** square they choose. The price rises with the number of squares already unlocked (F1's ladder by
  count: about 1 400 → 973 000), not with the position. Tending reach counted on a 6-column grid changes no target (re-run 2026-11-03).
- **Late field lever, candidate F2 (2026-11-03, after "find a field lever"; approved by the user 2026-11-03 as E1d's numbers).** With repeat runs kept, Casual stalled on the squares' Renown gates.
  At day 30 it held 123 000 Coins, 19 squares and Renown 54, and the next square needed 56 (F1's gates reach 60 by square 21).
  F2 changes F1 in three places:
  - **Gentler square gates.** Renown by squares open: 5 → 6: 0; 7: 5, 8: 6, 9: 7, 10: 8, 11: 10, then +1 per square up to 35 for the 36th.
  - **Two more field pet slots**, five in all: 0 / 23 300 / 84 000 / 280 000 / 746 700.
  - **Crop prices × 9.3** (ladder 2.8) instead of × 9.7: Potato 6 / 2, Corn 1 008 / 252, Pumpkin 1 344 / 336, Giant melon 4 032 / 1 008. This brings
    Garden main's parity back under 1.0.

  Results (6 seeds, worst policy, 6 columns, tools at EXPANSION sizes):

  | Archetype | Parity, days 1-3 | Lead day 7 / 14 / 30 | Field net per day / obby per day, days 54-60 | Squares, day 30 / 60 |
  |---|---|---|---|---|
  | Obby main | 0.52x | 3.1 / 6.8 / 11.8 | 251 500 / 26 900 | 31 / 35 |
  | Casual | 0.76x | **3.04** / 7.7 / 12.2 | 182 400 / 7 500 | 29 / 33 |
  | Garden main | **0.99x** | 8.8 / 30.5 / 30.7 | 209 000 / 2 800 | 28 / 33 |

  O (online ≥ 3x offline per hour) holds at 3.65x and C at 94 %. The reserved sinks needed by day 60 drop to 259 000 (Obby main), because the squares
  (4.8 M in all) absorb most of the income. The two thin edges remain: Casual's day 7 (3.04x) and Garden main's parity (0.99x) trade against each other via the
  crop prices. Field-pet slot 4 / 5 and the gentler gates are what lift day 14-30. Neither alone was enough: slots 4-5 alone 8.9x, gates alone 8.5x.
- **Later (parked):** locked squares lie under rubble or weeds. Clearing them needs a tool upgrade or a bought tool (EXPANSION §6).

## Market cart run (2026-11-03, gates E1c4; approved)
The model buys the cart on active days: the bargains where it buys those seeds anyway, and the taste (planted ahead of its gate) whenever the Coins allow.
6 seeds, worst policy, on F2 with the tools:

| Candidate | Garden main parity | Casual lead day 7 / 14 / 30 |
|---|---|---|
| No cart | 0.99x | 3.03 / 7.7 / 12.6 |
| 10 @ −30 % and 5 @ −50 % | 0.99x | 3.05 / 7.8 / 12.4 |
| ... + taste 2 seeds from level 0 (Corn first) | **1.79x** | 3.24 / 7.9 / 13.3 |
| ... + taste 2, only crops gated 2+ (melon) | **2.32x** | 3.36 / 8.1 / 13.9 |
| ... + taste 1-2 from Renown level 2 | **1.14-1.29x** | 3.05 / 7.8 / 12.4 |
| **... + taste 2 from Renown level 3 (approved)** | 0.99x | 3.05 / 7.8 / 12.4 |
| ... + taste 2 from level 2-3 at 2x the price | 0.99x | **2.86** / 7.9 / 13.4 |

The bargains are worth little (seeds are a quarter of the sale price). A taste is strong: one Giant melon sells for about as much as a day of early obby
play, so before Renown 3 it breaks parity. From level 3 on it is safe at the catalogue price.

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
