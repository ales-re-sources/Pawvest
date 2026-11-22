# Pawvest economy model — targets, decisions, how to run

Two models live in `tools/` (Python stdlib):
- **`economy_ev.py` (EV, the engagement-first economy, 2026-11-07):** the proposed numbers (`CAND`) and the checks they must pass (G1–G12,
  R, B, B2, C, U). `CAND["mode"]` is `"stars"` (EV3: crop levels replace Renown, in the game since EV3b1) or `"renown"` (the game before EV3b; the
  old column of the EV3 tables).
- **`economy.py` (E0):** reads every Coin number from the Luau configs, pins it (`tools/economy_pins.json`) and checks the game **as built**
  (parity targets, below). Its `check` also runs the EV checks; its parity / lead block goes when EV2a moves the configs onto the proposal,
  and the pins then hold the EV values.

History: the E0 run-by-run log is in `git show 87b1d3c:docs/ECONOMY.md`, the E0 version of this doc in `git show a128d26:docs/ECONOMY.md`.

## How to run

```
python tools/economy.py check                 # pins + E0 checks of the built game + the EV checks, exit 1 on a failure (~1 min)
python tools/economy.py proposal              # EV: the old -> new table (crops, trees, sinks, talents, eggs, obby, archetypes) + EV checks
python tools/economy.py evcheck               # EV checks only (also: python tools/economy_ev.py evcheck)
python tools/economy.py hour1                 # EV: a fresh player's first hour (G7 numbers)
python tools/economy.py pin                   # accept the reviewed config values as the new pins
python tools/economy.py sim | report | pets | tools   # E0 tables of the built game
```

Run `check` after changing any price, rate or reward in a config; `pin` only after the user has reviewed the values. To try an EV number,
edit `CAND` in `economy_ev.py` (or pass overrides to a scratch probe that copies `CAND` and calls `build(c)`).

## Crop timing update (OG2 and OG2b, 2026-11-20)

All 19 crop base durations are doubled (Potato 20 s, Sunflower 36 h, Pineapple 48 h; FL then reshaped the ladder, longest crop 14 h). Rates stay online 2 / offline 1, so the
actual online and offline crop pace returns to pre-OG2. Visible durations / countdowns use the away-time baseline and tick faster
while playing (Cloches extra). The offline cap stays 24 h; long crops need multiple absences or online time. The shared timing
hint states the pause and seed rows say "Growth time" rather than promise completion in one uninterrupted absence.

Field-job XP keeps separate pinned rates 1 / 0.5. Request MaxGrow doubles from 4 to 8 growth hours to retain Onion … Eggplant.
The model doubles ladder / rare / future-tree growth durations, halves `v1` and doubles its request cutoff; all generated sale,
seed and purchase prices stay unchanged. Model-only paid offline rate 2 represents the old rate 1 in the new growth-second units,
with its existing 48 h cap. No profile migration or saved `Grown` rewrite; existing plantings retain earned growth seconds.

`economy.py check`: since FL (2026-11-21) EV 17/19 on default seed 1 (G8, G11; core 15/15 once pinned). Since EG (2026-11-21), before FL: EV 16/19: G11 (old crops levelled) fails as before OG2, G5 and
B2 flip on the RNG path (Findings (EG)). The 10/18 result
was the intermediate faster-growth configuration; its controlled diagnosis is in `git show 573310e:docs/ECONOMY.md`.

## EV — why and the pillars (the user, 2026-11-07)
The E0 targets kept field income near obby income (parity). That produced a 5-minute Potato worth 4 Coins, then a 6 h jump to Corn, talents
bought before World 2 ends without farming, and repeat runs paying tens of Coins next to a farm paying 100 k+. New direction: **engagement,
not income equality.** Farming is the core; the obby and coming mini-games are the distraction while things grow and the only source of rare
drops. Something is always growing, hatching or nearly affordable ("one more thing").

1. **A timer for every gap:** one ladder of grow / hatch times from 10 s to 24 h, each step ≤ ×3, so every session and absence has a crop.
2. **Online is busy, offline is a hook:** something to collect every few minutes online; a long crop / egg ripens near the return (offline
   rate 1, online 2, 24 h cap since OG2, 2026-11-20; displayed times are the away-time baseline).
3. **The next goal is close, never already bought:** time-to-afford stays in a band; the player never holds enough to buy everything.
4. **Each new crop is worth unlocking:** net Coins per square-hour rises ×1.2 per step; the per-harvest number fits the prices of its time.
5. **The obby is the expedition:** one-time medal / first-clear Coins stay as starter capital; repeat runs pay **Sunshine**, rare seeds and
   pet XP, never Coins.
6. **Talents need the farm:** Coins + a crop bundle; the required levels also take a rare crop of the world before.
7. **Inflation is accepted** (genre norm): every sink is priced on the square ladder; numbers stay integers < 2^53.
8. **No regret (for M7):** after launch prices never go down; nothing sold is later handed out free in bulk; a capacity product never exceeds
   the earnable maximum. Free play is scarce enough that a comfort purchase is worth 1.2–1.5× (G8), never more.

## EV checks (`evcheck`; on the EV3 revision `CAND` (2026-11-17, smaller Double Jump 2 / Dash bundles) 12–15 of 18 pass on seeds 1–4 before EV3b; since EV3b1 (2026-11-17) EV0 passes and seed 1 passes 15 / 18 (R, B, G11 the known near-misses). EV0 compares the configs with `CAND`: crops (grow time, sale, seed, `step`, `quest`), `Mastery` (EV3c also its `Points` against `pt_value` / `pt_size` / `pt_speed` / `pt_cap`), `Stall` (ST, against `st_every` / `stall_staples` / `st_p` / `st_pity` / `st_n`), the crows / cart-taste crop, the Tutorial / World 1 `firstClear`, sinks in Coins only, talent bundles)
Bands are provisional, for the user to confirm with the proposal. Archetypes: Obby main (7:00 / 12:30 / 18:00, 2 h obby), Casual (8:00 / 19:00,
45 min obby), Garden main (7 / 12 / 17 / 21, 15 min obby), Binge (one 6 h day a week), Spender (Casual's schedule, paid comforts).

| Check | Rule |
|---|---|
| G1 ready cadence | online minutes per collectable event (ripe batch, fruit, hatch, drop, request) ≤ 4 on day 1, p90 ≤ 8 later |
| G2 return hook | ≥ 90 % of session ends (day 2+) have a crop or egg ripening near the coming return |
| G3 next goal | at session end the next goal (cheapest of the shop's first 3) is 0.3–2 sessions of income away (median; the lower bound only for daily players), ≤ 3 days max, days 1–30 |
| G4 talents | obby-only Coins through World 2 ≤ 40 % of the World 1–2 tree; Double Jump 2 / Dash 2 bought within 1 day (Obby / Garden main) or 2 days (Casual) of reaching Stage 11 / 13 |
| G5 horizon | Garden main's last purchase not before day 45, Casual's not before day 90 (or items left) |
| G6 expedition | obby Coins ≤ 25 % of income after day 3; Sunshine ≤ 40 min of growth per obby hour (30 until the user raised it, 2026-11-07) |
| G7 first hour | first harvest ≤ 30 s, ≥ 6 crops in hour 1, longest wait for something new (level, crop, first harvest of a kind, purchase, hatch, a finished request) ≤ 10 min, first square ≤ 15 min, first hatch ≤ 5 min |
| G8 Spender | headroom on Dash 2, Squares 20 / 28 / 36, Growth 4, Sorter 3: median 1.2–1.5×, max ≤ 1.6× |
| G9 scarcity | Casual: the expected Legendary count reaches 0.5 not before day 14; top crop day 10–28 (talent-first), ≥ 10 (pets-first; both were 14 until the user's FL decision, 2026-11-21); last tool ≥ day 14 |
| EG (2026-11-21) | each egg with an opening crop costs ≥ 2 h of every archetype's income in the 24 h after that crop opens, if it buys one (target: 2–4 h of the median) |
| B | Tending pets earn more (guards and crows off in both runs) |
| B2 | one field slot as a guard instead of a tender earns at least as much (Casual) |
| C | sinks ≥ 60 % of the faucet by day 30, ≥ 78 % by day 60 |
| G10 (EV3a) | a Tutorial / World 1 first clear (finish + medals + the seed pack at seed price) ≤ 3 min of the Casual farm's online income when Casual clears it |
| G11 (EV3a, revised 2026-11-17) | days 3–30: ≥ 15 % of the crop levels earned are on crops ≥ 3 steps below the newest unlocked one (every archetype; the old harvest share passed the Renown model too and is printed for reference) |
| G12 (EV3a) | the first crop at its top level not before day 7 (Garden main); Casual has ≥ 25 % of all levels (16 × 3) still to earn on day 60 |
| U (EV3a) | a maxed crop earns net per square-hour what a fresh crop 2–3 steps up the old × 1.2 ladder earns (× 1.44–1.73) |
| FD (2026-11-21) | Casual's day-7 Legendary (the streak pet, forced Legendary with Cuteness, always equipped) reaches Cuteness 10 within 2 days (the model's fixed 2 % food share saves a Legendary's bootstrap over a day or so) and 20 in 75–110 days (~90 for a daily player, the user 2026-11-21; the signed design had ≥ 14; the probe runs 130 days); a fed crop's XP ≤ its sale × the weakest food's XP per Coin at every level and rarity (E1a3); food prices to the limit (info) |

## EV — the rules as simulated
- **Player:** sessions per archetype, the obby block in the middle of each session with garden checks every 5–10 min; between sessions the
  field grows at the offline rate (Spender: 2.0 for 48 h in OG2b growth-second units). In garden time the player reacts to every ripe batch, fruit and egg. Crop choice:
  best net Coins per wall-clock second until the next chance to harvest; bundle and request crops planted only when they ripen in time.
- **Shop:** one queue sorted by price × policy bias (talent-first: talents ×0.5, pets ×1.5; pets-first: pets ×0.6); unbuyable items are
  skipped, saving goes to a blocking required talent first; seed reserve kept; eggs and food from 8 / 2 % of income (pets-first 25 / 8 %).
- **Renown (`mode: "renown"`, the game as built):** level L needs 0.4 × L³ points; a harvest gives 4 × minutes^0.5 points; crops unlock on a
  gate ladder (R0 … R68); squares and other sinks have gates.
- **EV3 revision (2026-11-17, the defaults in `CAND`; the 2026-11-14 draft below stays reachable with `--set`):** crops in **price tiers**
  (`tier_of`: Potato–Onion, Garlic–Cucumber, Corn–Broccoli, Pumpkin–Blueberry, Sweet potato–Giant melon, Sunflower–Pineapple; a tier
  shares one net Coins per square-hour, 2 500 × 1.727^tier). **Mastery = plants grown** of that crop (`mastery: "count"`): levels at 25 / 75 /
  200 plants for every crop (`m_levels`); 3 levels, each a point, one point per line (Value +11 %, Size +11 %, Speed −11 %), so a
  level-3 crop is fully upgraded (× 1.47). The next crop opens at 12 × 1.05^k plants of the previous one (12 Potato … 25 Sunflower, the
  draft's star-1 counts), apart from the levels; Corn, Pumpkin and **Sweet
  potato** by a quest handed in **piece by piece** (`quest_partial`; the policy keeps what the next talent bundle needs). **Rested:** each
  full day away past the first adds 0.5 "unlock counts" of plants that count double (cap 3). **Requests** are tracked (below).
- **Crop levels (`mode: "stars"`, EV3a draft 2026-11-14):** XP = grow minutes of each harvest of that crop. Star 1 needs 12 × 1.05^k square-harvests of crop k
  (k = 0 Potato … 15 Pineapple); star L > 1 needs star 1 + 40 × minutes^0.7 × (L − 1)^1.5 XP in all; 15 stars, each a point (Value +2 % sale,
  Size +2 % size factor, Speed −2.5 % grow time; 5 per line; Value first, then Speed, Size). The next crop opens at the previous one's star 1;
  Corn, Pumpkin and Giant melon by a quest taken from the barn (`unlock: "chain"`; `"total"` opens crops at a crop-XP total over all crops,
  rare crops included, 0.8 × gate³ on the as-built gate ladder; `"hybrid"` chains up to Cucumber, then the total; `"price"` has no unlock:
  every crop is in the stall, the seed price paces it, a crop counts as opened at its first harvest, quests off; with `price_quests` the
  quests gate groups instead: Corn, Pumpkin and Giant melon each open their group up to the next one; `"stall"`: no unlock, a stall restocks
  every 10 min, Potato–Garlic always, crop k above with chance 0.7 × 0.7^(k−4) and 1..4 × 0.85^(k−4) seeds, bought into a seed bag;
  its trees are `stall_trees`).
  Trees count for G2 (a tree full of fruit at the return is a timer). **Unlock bar policy:** the player plants just enough squares of the newest crop
  to fill its star 1 while it earns ≥ 0.5 × the best crop's rate, before bundles and requests; quest crops are planted at once. Sinks on Coins
  alone; crows from the Garlic unlock; rare crops give no XP.
- **Squares:** 78 since FX (2026-11-22), price 290 × 1.33^(j−5) up to square 20, × 1.93 (1.33 × 1.45) for squares 21–28, then × 1.33 again
  up to 40 M at square 36 and a flat 40 M for squares 37–78 (FXP, 2026-11-22; × 1.93 up to 750 M before). Every other sink is anchored on the
  EV2a ladder (× 1.93 on to square 36: `sq`, not the squares' own `sq_own`) × a factor, so it arrives when that ladder's square would. Reserved sinks (landmarks, estate, decor; not designed): 70 steps × 1.15 from square 12's price.
- **Trees (model-only):** a sapling, first growth 2–24 h, then a fruit every 5–60 min up to a cap of 4–6 held, forever.
- **Eggs:** the pet is rolled at purchase; the hatch time is set by its rarity (Common / Uncommon 5 m, Rare 1 h, Epic / Legendary
  4 h). The player buys the dearest open egg the egg fund covers. Above Pearl (`Basic`) and Topaz (`Golden`) the Ruby and Diamond eggs
  (EG, were the placeholders FutureEgg1 / 2) keep Legendaries scarce while income grows ~1000×; each opens with a crop (`egg_opens`:
  Pumpkin, Giant melon) and costs at least 2 h of every buying archetype's income in the 24 h after it opens (check EG).
- **Pet care (FD, `fd`):** Cuteness on the 20-level scale. The food fund feeds each equipped pet, best bonus first, one food at a time,
  priced × 2.65^(b − 1) by the base level of the trait it trains and × `food_rarity` (Legendary 10), up to half the rarity cap (`food_limit`); Cuteness first, then work
  traits. Past the food limit Cuteness grows to the cap from obby care XP × `obby_above` (0.04) and time with you (`with_you_xp` 0.75
  per online minute, every equipped pet). Work traits take care XP only up to the food limit. The model equips by current bonus; only
  the FD check's probe pet is always equipped.
- **Obby:** first clears and medals pay their one-time Coins; repeat medal finishes pay Sunshine (16 / 24 / 32 s per Bronze / Silver /
  Gold, × 0.8^n per stage and day, floor 6 s) into a store of up to 3 h; spending it is a **time skip**: the whole store at once, each growing
  square, tree and incubator advances by the full amount (not split; a square that needs less ripens and the rest is lost for it); rare-seed meter, daily
  seed and pouch (free seeds) stay.
- **Scouting:** XP = seconds of a running stage timer while equipped (level 2 after 45 min, × 2 per level); bonus min(0.5, 0.5 × strength)
  on Sunshine, meter and pouch.
- **Requests (tracked, `req_auto`, 2026-11-17):** 3 slots, per-day RNG (UTC day + user); "grow 6 Tomatoes" counts harvests of that crop
  (nothing handed in, the crops are sold as usual) and pays a bonus of 0.6 × the sale of the count; an unfinished request stays, only
  finished slots refill on the next UTC day; the board opens on the first visit with two eligible crops (day 0 included). Crops of the
  unlocked set (grow ≤ 4 h), sized to 30 % of a day's income; on half of the days slot 3 is a timed run; one in three also drops
  Sunshine, a rare seed or an egg. (Until 2026-11-17: handed in from the barn, 1.75 × the sale, a new board every day.) **1.0 (E5, the
  user, 2026-11-19):** no timed run and no Sunshine until EV2c: three crop requests, the drop a rare seed or a free egg (Pearl, Topaz once Pumpkin is open, EG; half
  and half); a day's income = crop sales + request bonuses of the previous UTC day or today, whichever is more, at least 2 000. **Streak:** Sunshine 10–30
  min on days 1–6, day 7 a pet (Epic 95 %, Legendary 5 %); a missed day pauses it.
- **Crows and guards:** in a crow block a ripe crop may be eaten, up to one per 12 unguarded squares per absence; guarded squares are safe; a
  guard covers 18 / 30 / 42 squares by level band. **Tending** (growth mode): a tended square grows 50 % × strength faster.

## EV — the proposal (summary; the full old → new table: `economy.py proposal`)
Every Coin price is a "nice" number (the user, 2026-11-07; `economy_ev.nice`): below 10 exact, a mantissa of 10–30 in whole steps, 30–95
in steps of 5 (120, 2 900, 35 000, 750 M). The checks run on the rounded prices; rounding moved the first square from 300 to 290 to keep G3.
| Item | Old (built) | Proposed |
|---|---|---|
| Crops | Potato 5 m, Corn 6 h, Pumpkin 8 h, Giant melon 12 h | 16 annuals on 10 s … 24 h: **Potato 10 s** (sale 9), FP1 30 s, FP2 1 m, FP3 3 m, FP4 8 m, FP5 15 m, **Corn 30 m** (5 000), FP6 1 h, FP7 2 h, **Pumpkin 3 h** (50 000), FP8 4 h, FP9 6 h, FP10 8 h, **Giant melon 12 h** (450 000), FP11 18 h, FP12 24 h; seed = 25 % of the sale |
| Rare crops | 6 / 8 / 10 h, sale 3 360 / 4 480 / 5 600 | same times; sale 50 000 / 150 000 / 300 000, Renown points 22 / 44 / 76, set by hand (2026-11-08). The first version, 2.5× a common crop of that time (350 000 / 600 000 / 900 000), ignored when a player gets the crop: the first Golden carrot paid 3.7× the World 1-2 talent tree on day 1, 58-79 % of that day's income and 7 Renown levels. Check R (`economy_ev.py`) now limits it: at most 70 % of a day's income on days 0-3, no sale in the first 5 days above 5× everything earned before it, one World 1 rare at most 3 Renown levels; G6 counts rare sales as obby income. Double Jump 2 takes 1 Frost grape (was 2) so that G4 holds at the lower prices |
| Renown | 3 × L^1.6 | 0.4 × L³, gates R0 … R68 |
| Squares | 1 400 → 907 400 (4.8 M in all) | 290 → 750 M (1.6 B in all) |
| Talents | 22 300 in all, Coins only | 3.4 M in all + crop bundles: Run Speed L1: 800; Double Jump L2: 16 000 + 20 FP5 + 2 Frost grapes; Dash L2: 29 000 + 20 FP6 + 1 Glow mushroom; Wall Jump L1: 700 000 + 20 FP9 + 3 Glow mushrooms; Glide L1: 2.6 M + 25 FP9 + 4 Glow mushrooms |
| Upgrades / tools | Growth 28 000 …, Barn 14 000 …, Sorter / Cloches / Shears 37 300–420 000 | Growth 3 000 → 22 M, Barn 1 200 → 15 M, Sorter 10 000 → 45 M, Cloches 4 000 → 6 M, Shears 18 000 → 160 M |
| Slots | field pet 23 300 …, equip 2 000 / 5 000, incubators 5 000 / 12 000 | field pet 2 400 → 11 M, equip 700 / 4 000, incubators 500 / 2 800 |
| Eggs | Pearl 120, Topaz 4 000, rolled at purchase; rarity hatch timers (EV2e, 2026-11-17); EG (2026-11-21): Ruby 450 000 (opens with Pumpkin), Diamond 3 000 000 (with Giant melon) | Pearl 120, Topaz 4 000 (weights U500 R370 E127 L3), Ruby (R600 E396 L4), Diamond (R400 E580 L20), rolled at purchase, hatch by rarity |
| Obby repeat runs | 50 × factor × medal × 0.8^n Coins | 0 Coins; Sunshine 16 / 24 / 32 s × 0.8^n (Casual: ~31 min of skip per obby hour, ~24 min a day) |
| Scouting | 15 min XP per medal finish (frozen: ~40 finishes for level 2) | XP = timer seconds; level 2 after 45 min of runs |

Day-60 outcome (talent-first): Casual 27 M Coins a day, R117, 33 squares, first Legendary not rolled by day 60 (expected 0.5 by day 14.8);
Obby main 36 M, R150; Garden main 29 M, R138; Spender 51 M. Obby Coins are 0 % of income after day 3.

## Findings (EV1, 2026-11-07)
- **Tending replant is nearly worthless on a dense ladder** (a ripe crop waits only minutes for the next visit): the proposal turns Tending into
  growth speed (+50 % × strength on tended squares).
- **Guards did not pay:** with a lower chance per crop, a big field's many ripe crops still fed the crow. Guards now make their squares safe and
  crows scale with the field (one crop per 12 unguarded squares per absence); a guard-first slot is now ≥ a tender (B2 1.01×).
- **Faster growth feeds crows:** with Tending, crops ripen earlier in a long absence and wait for the crow; Obby main earns no more with Tending
  unless a guard is out (B runs without crows for this reason).
- **Late-game sinks must be dense:** income flattens once the top crop and the squares' ×1.45 slope arrive; the reserved landmark / estate
  ladder (×1.15 steps) fills the gaps until E6 / E7 design real ones.
- **Legendary scarcity needs an egg ladder:** with fixed egg prices, Legendaries come in days once income grows ×1000; two placeholder eggs above
  Golden (price anchored on squares 18 / 26) keep the expected first one at about two weeks for Casual.
- **The Spender** needs offline 1.0 / 48 h and about 3 instant grows a day to reach 1.2–1.5× headroom.
- **G7** was at the edge (10–12 min gaps in the first hour, the greedy player locks every square into 30 m Corn at minute 14); every hatch and
  the first harvest of each crop kind now count as "something new" (longest gap 6 min).
- **Rebirth:** no archetype's queue runs dry within 60 days (G5: Garden main 6 items left at day 60, Casual buying until day 84), so no rebirth
  for launch. If the queue empties later, a soft "Replant" (reset squares, Coins and Renown; keep pets, talents, obby progress, looks; reward a
  permanent verb or a small capped bonus) fits better than a Coin multiplier.

## Findings (the user's review, 2026-11-14)
- **The 4× markup is not the slope:** sale = 4 × seed is the margin of one crop; tiers do not compound. Net Coins per square-hour rise ×1.2
  per crop (Potato 2 520 → Pineapple 37 500, ×15). The per-harvest numbers (9 → 1.2 M) are steep because grow times span 10 s → 24 h.
  Lowering the margin scales all income down equally and flattens nothing; flattening means a shorter time span, slower value steps or a
  slower square ladder.
- **Raising starter crop prices 5× = dividing obby Coins by 5** (every early sink would have to rise with it). The early problem is the
  obby's one-time Coins (Tutorial up to 750 in a 30 s run ≈ 7 min of the 4-square Potato farm), handled in EV3.
- **Old crops die at once:** the best crop is the longest that ripens before the next visit (ripe crops wait), so Potato is beaten ~20 s in
  (Lettuce unlocks at 0.3 min) and only the 2–3 crops near the top are planted. Renown points do the opposite (per hour: Potato ~720,
  Garlic 140, Corn 44), rewarding spam-clicks. EV3 replaces Renown with per-crop levels (XP = growing time of that crop) whose points
  upgrade that crop, so growing an old crop has a purpose.
- **Sink gates never bind:** with the Renown gate removed from squares (and from every sink but talents) all EV checks pass and every
  square's purchase day is unchanged (Casual #20 / #26 / #30 on days 3.3 / 10.3 / 21.3, day-60 income the same): the price ladder paces
  them. EV3 drops the gates (the user, 2026-11-14).
- **Day 5:** the user bought "almost everything" in ~5 days; the model agrees by count (Garden main 55 / 85 items, Obby main 60, Casual
  47) but those are 0.02–0.18 % of the total Coin price; the rest (550 k → 750 M) is a day or more each. The model's longer horizon leans on
  parts not built (trees, requests, Sunshine, placeholder eggs, reserved sinks); in the game a 24 h crop and logging off is the best play.

## EV3 — design draft (2026-11-14, rewritten the same day after the user's review; signed off with its revision 2026-11-17; build parts: ROADMAP → EV3)
**Why (the user, 2026-11-14).** Two 12-year-old players did not know what Renown is; a concept that needs explaining is out. Renown also
rewards spam-clicking Potatoes, old crops have no use once a newer one opens, the late game is a list of "+1 square for 4 M", and early
obby first clears outpay the farm they should feed (findings above).

**Direction (the user: not a quest per crop; upgradeable crops).**
- **Crop levels (★):** every crop has its own level, earned by growing that crop. It replaces Renown and sits on the crop itself
  ("Garlic ★2"), where a kid already looks.
- **Unlocks mostly happen by playing:** the next crop opens when the previous one reaches ★1 (the seed stall shows the bar). Nothing is
  used up.
- **Quests only at milestones:** Corn, Pumpkin, Giant melon (the original crops; the model may move them): "bring 20 Cucumbers + 30 Garlic"
  (taken at once, EV2b's `TakeCrops`). They keep obby Coins from buying the farm and feel like events, not chores.
- **Crop upgrades:** each crop level gives a point to invest in that crop's lines **Value** (sells for more), **Size** (grows bigger:
  look, size records, the sale through the size factor), **Speed** (grows faster). Points come only from growing that crop, so upgrading
  Potato means planting Potatoes: old crops become a choice, and 16 crops × 3 lines is a long goal that needs no bigger Coin numbers.

**Rules for the first cut (the model tunes the numbers):**
1. **Crop XP = growing time of that crop** (each harvest adds its grow minutes), not harvests: a harvest count would bring the spam-click
   back. Level thresholds per crop are set so a level takes about the same play time on the squares the player has then; ★1 is small for
   the first crops (G7: something new every ≤ 10 min). The player sees a bar, not minutes.
2. **Caps:** a fully upgraded crop matches a fresh crop 2–3 steps above it, never the top one (point sizes: findings below). Every line can
   be maxed in the end (completion, not a forced build); the choice is the order.
3. **Global upgrades stay** (Growth, Barn, Sorter, Cloches, Shears) and stack with crop upgrades: the global ones are the Coin sinks, crop
   upgrades the time sink.
4. **Squares, upgrades, tools, field pet slots:** Coins only, no gate (the user, 2026-11-14); the ×1.33 / ×1.93 price ladder paces them.
5. **Other Renown uses:** the market cart's taste and crows (both from Renown 3) start with the Garlic unlock.
6. **Obby one-time Coins:** first finish + medal Coins of the Tutorial and World 1 resized; part of a first clear paid as a seed pack of an
   unlocked crop (seeds of a locked crop would skip its unlock). Repeat-run Coins stay until EV2c.

**Revision (the user, 2026-11-17; replaces rules 1–2 and the quest form above; model defaults since then):**
- **Mastery = plants grown of that crop** ("Potato 32 / 75"), shown as the crop's ★. A long, expensive crop needs more time per level.
  Rule 1's spam worry does not apply: the count is per crop, so quick Potatoes level only Potato.
- **Three levels per crop** (like the stage medals), never infinite. Each level gives one upgrade point, a step a player notices
  (+11 %). EV3c shipped one point per line; then (the user, 2026-11-17) **any line, up to 3 in one**, no free reset (stacking, below).
  The same counts for every crop: **25 / 75 / 200 plants** (the user, 2026-11-17; since FL quick crops need more, Findings (FL)). The next crop opens at a smaller, rising count of
  the previous one (12 Potatoes … 25 Sunflowers), apart from the levels.
- **Price tiers:** the 16 crops form 6 tiers of 2–3 with one net Coins per square-hour each; inside a tier the crops differ in grow time
  (and look), so a rotating stall (ST) can offer any of them fairly. Tier 1 Potato–Onion, 2 Garlic–Cucumber, 3 Corn–Broccoli, 4 Pumpkin–
  Blueberry, 5 Sweet potato–Giant melon, 6 Sunflower–Pineapple. The milestone quests sit at tier starts: Corn, Pumpkin and **Sweet
  potato** (moved from Giant melon).
- **Quests:** no accept step and no expiry; crops are handed in piece by piece and the progress is kept; the reward is the unlock plus a
  seed pack of the new crop (the pack is not in the model yet).
- **Rested mastery:** after more than a day away, plants count double for a while (the weekly player's catch-up).
- **Not changed:** quests only at milestones, the cap (a maxed crop ≈ a fresh crop 2–3 old steps up), global upgrades stay, sinks on
  Coins alone, the obby payouts (rule 6).

**Stacking (the user, 2026-11-17; model `pt_cap` 3, `pt_total` 3, game `Points.PerLine` 3).** The three points go into any line, up to 3
in one. A maxed crop: 3 Speed × 1.49 net per square-hour (2.2 steps), 3 Price or 3 Size × 1.44 (2.0), one each × 1.47; check U now takes
the best and the worst way to spend them (both 2–3 steps). Model policy `pt_order` "auto": Speed for crops that grow in a session (≤ 1 h,
`pt_fast`), Price for overnight crops. `evcheck` passes on seeds 1–4 (of 18): one per line 15 / 13 / 16 / 13; auto 13 / 13 / 14 / 13;
all Price 14 / 12 / 15 / 14; all Speed 12 / 14 / 16 / 14; Speed only up to 15 min 16 / 13 / 15 / 15. Mostly noise; one structural effect:
Speed on a short crop speeds that crop's own plants, so its mastery and the next unlocks come sooner: **G9** fails on all four seeds with
auto (Casual's top crop on day 13.3–13.8, floor 14; before 14.3–16.3) and **G12** on single seeds (Garlic maxed on day 3.9 instead of
Sunflower around day 24). Accepted as near-misses with the rule (ST remodels the unlocks next); if it shows in play, the lever is a smaller
Speed point or the top crops' `step`.

## Findings (EV3a, 2026-11-14; `economy.py proposal` prints the old → new tables)
- **The draft's upgrade sizes broke its own cap:** +10 % Value, +10 % Size, −6 % Speed per point make a maxed crop ×3.7 per square-hour
  (~7 steps; the draft's "≈ 4 900 for Potato" left out Size). At 3 steps (+3 / +3 / −3 %) the extra income bought the shop out early (G5,
  C, G8, B2 failed); the candidate +2 / +2 / −2.5 % is ×1.46 (2.1 steps).
- **The unlock chain needs a player who chases the bar:** a maxed crop beats a fresh one 2–3 steps up, so a pure rate player never grows the
  newest crop and nothing opens (Giant melon opened on day 20 and was never planted). The model plants just enough squares of the newest crop
  to fill its star 1 (the stall shows that bar in EV3b). Planted after bundles and requests it got no squares; it goes first.
- **Stars pile up on the overnight crop:** XP is growing time, and the crop grown overnight gets most of it: Pineapple is the first crop
  maxed (Garden main day 31), old short crops rarely pass star 3; 40–60 of 240 stars by day 60.
- **Quests sized like the draft took days:** 15 Broccoli + 15 Pepper (≈ 615 000 Coins of sales) took Casual ~2.5 days. Quests are now about
  one partial field (Corn 6 Cucumber + 10 Garlic, Pumpkin 5 Pepper + 8 Corn, Giant melon 4 Sweet potato + 5 Blueberry). A timing rule for
  quest crops stalled Giant melon (a 6 h Blueberry fits no Casual session or absence), so they are planted at once.
- **Pace old → new:** the first hour keeps 6 crops but its longest wait is 10.0 min (limit 10; Renown 7.0). The mid game is slower:
  Casual Pumpkin day 1.8 → 4.8, Sweet potato 4.8 → 8.8, top crop 18.3 → 14.8; the weekly Binge player loses most (Sweet potato 7.7 → 28.4,
  no Pineapple within 60 days).
- **Obby payouts:** under Renown the as-built first clears were ≤ 2.2 min of farm income (spam-clicks grew the farm fast); under crop levels
  the as-built Tutorial is 3.6 min of Casual's farm. Candidate: Tutorial 250 + 4 seeds (up to Garlic), Stage 1–5 600 / 800 / 1 000 / 1 250 /
  1 500 + 4 seeds (up to Tomato); at most 2.7 min (Binge). The pack is capped by crop: "the newest crop" paid a late clear ~44 000 in seeds.
- **G11 does not measure EV3:** the Renown model passes it (24–90 %) because short crops fill sessions anyway. A sharper check: stars earned
  on crops ≥ 3 steps below the newest, or square-hours instead of harvests.
- **Margins are thin** (seeds 1–4): Binge's day-1 cadence 3.8–4.2 min (G1 ≤ 4), Casual's top crop day 13.3–15.8 (G9 ≥ 14), Casual's hook
  92–93 % (G2 ≥ 90; Renown 99–100 %). All 18 pass on seed 1 only. Slower stars for late crops (star 1 × 1.08–1.10 per crop) move the top crop
  to day 15–22 but drop the hook to 88–91 %: Casual needs a 3–6 h crop by day ~3 for its overnight absence, which one star-1 ratio cannot
  give together with a top crop after day 14.
- **Chain or total growing time (2026-11-14):** the slower mid game is not the chain's doing. A fixed Renown (points = grow minutes, no
  spam advantage, no sink gates) gives Casual Pumpkin on day 2.8 (spam Renown 1.8), Sweet potato 7.8, Pineapple 25.3. A first probe showed it
  as fast as the spam Renown, but only because the model-only trees still earned their old points. The rest of the delay comes with the
  quests, smaller payouts and crop points (Pumpkin ~3.3–4.8 in every rule). What the rules change are the edge margins (seeds 1–4, Casual
  unless named): overnight hook chain 92–93 %, total 94–97 % (0.5 × gate³), hybrid 94–95 %; Binge's day-1 cadence chain 3.8–4.2 min, total
  3.4–3.8, hybrid 3.2–3.8; top crop chain day 13.3–15.8, total 15.3–19.8, hybrid 21.8–23.8. On seed 1 chain passes 18 / 18 (its numbers
  were tuned on it); total 14 / 18 and hybrid 16 / 18 fail R, G8 (and B, B2 for total), not tuned yet.
- **Price as the only gate (2026-11-15):** every crop open from the start fails 5 of 18 on seed 1 (G1, G3, G4, G7, G9). The first hour
  loses its news (5 crops by minute 23, then 33 min with nothing new: G7); frequent players skip the middle and buy the top: Garden main
  Pineapple day 5.9–7.3 (chain ~14), Obby main day 5.3 after Sweet potato on day 2.3; Casual skips Giant melon and leaves Sunflower to
  day 60. Binge's day-1 cadence 3.6–4.5 min. With the quests as garden levels (`price_quests`) 11 / 18 (also R, G8, B): the first hour
  waits 54 min for news and Pumpkin comes later than in the chain. Price paces Coins, not attention: a cheap gate (seed price ∝ income)
  is passed on the day the income arrives, so the order of crops and the news stream need an unlock of some kind.
- **ST — the rotating stall on the EV3 chain (2026-11-17; `CAND` `st_*`, the candidate since then):** the chain decides which crops
  exist for the player; the stall restocks on a UTC schedule (the same draw on every server, counts per player). Always in stock: the
  staples, the newest unlocked crop, the next talent's bundle crops and the open quest's crops. Every other unlocked crop shows with chance
  `st_p`, and at least every `st_pity` restocks (staggered by crop), with `st_n` seeds per restock. `evcheck` passes (of 18, seeds 1–4):
  the chain alone 13 / 13 / 13 / 13; the candidate (1 h, staples Potato–Onion, 0.5, pity 3, 12 seeds) 16 / 16 / 16 / 17, fails only the
  known R, B2, G8, G11. Grid (sums of 72): 1 h 61–65, 2 h 56–64, 3 h 59–63; staples Potato–Onion beat Potato–Garlic by 1–6; 12 / 24 / 40
  seeds 63–65 / 64 / 61 (stock size hardly matters: a player buys what one field needs). What it changes: progress is slower (Casual's top
  crop day 17.8–19.3 instead of 13.3, Garden main's Sorter 3 day ~35 instead of 29), which fixes G9 and mostly G12 (Garlic no longer the
  first crop maxed: it rotates). **The newest crop must always be in stock:** without it the first hour loses its news (G7 failed on every
  seed), and G2 / G12 fail. The model player keeps Coins for the unlock bar before buying stall seeds (spending everything on the bag left
  Casual's Pumpkin bar unfunded for 50 days: a hint for the UI, the bar's crop is always buyable).
- **Rotating stall and trees (2026-11-15):** `unlock: "stall"` with its six tree kinds in place of the four (first growth 0.5 / 2 / 6 / 12 / 24 / 24 h, a fruit every 5 / 30 / 90 / 180 / 360 / 360 min, 4 held, valued as
  crop 6 / 8 / 10 / 12 / 14 / 16, saplings anchored to squares 6 / 10 / 14 / 18 / 22 / 26) passes 15 / 18 on seed 1. What it fixes: the
  first hour has news every ≤ 5.2 min (restocks and first purchases; price-only 33 min); every square of the field is not the top crop
  any more (supply limits it); trees carry the overnight hook (Casual 93–99 % on seeds 1–4; the stall alone 23–50 %: the bag seldom holds
  a crop that fits the night). Fails: G4 (talent bundles of non-staple crops wait on stock: Casual Double Jump 2 28 days after Stage 11;
  halving the bundles fixes Obby main, not Casual), G9 (top crop is luck: Casual day 8.8–27.3 over seeds 1–4; needs a pity rule), G7
  (first square 15.4 min, the stall buys first). Side effects: income is supply-limited, about 1/3–1/2 of the chain's from day 7 (the
  sink ladder was priced on the chain); most harvests are staples (G11 ~99 % for Casual and Garden main); saplings sell out early
  (Tree4 by day 2–4), so trees are not yet the long saving goals. Not tuned: these are the first numbers.
- **Model fix (both modes):** rare crops are kept for the next level of every talent (Quick Respawn 2 led the queue and the Frost grapes
  Double Jump 2 needs were sold); the Renown model still passes its 14 checks.

## Findings (EV3 revision, 2026-11-17; seeds 1–4; `economy.py proposal` prints the crop table)
- **Pass rate (levels 25 / 75 / 200):** 14 / 14 / 13 / 12 of 18 on seeds 1–4, against the draft's 16 / 11 / 12 / 13. EV0 fails by
  design (the tier prices are not in the configs until EV3b), so 12–14 of the 17 others pass. **G4 fails on every seed:** Obby main buys
  Triple Jump 1.2 d after Stage 11 (limit 1), Casual 2–3 d (limit 2); fewer early upgrade points mean slower income. To tune with the
  bundle sizes. (With the first cut, levels at 12–25 × 1 / 4 / 25: 13 / 15 / 15 / 13.) G7 and G9, which failed since EV2e, pass on every seed but one (G9 seed 3:
  top crop day 13.8). Near-misses left: G4 (seed 1 Casual Triple Jump 3.0 d after Stage 11, limit 2; other seeds 1.0 d against a
  1-day limit), R (Casual / Spender rare share 71–78 % on days 0–3, limit 70), G8 (Spender median below 1.2 on seeds 1, 4), B2 (a guard
  0.99× a tender on seed 1), G11 (Obby main 0 % of 8 levels on seeds 1, 4: too few levels in days 3–30 to measure).
- **The first hour needs the request board:** with three levels per crop, levels are rare news; after the 6th crop (minute 32) nothing
  happened for 27 min (G7 failed). The board opening on day 0 as soon as two crops qualify, and a finished request counting as news, give
  a longest wait of 6.0 min and Corn's quest done at minute 58.
- **Unlock pace stays near the draft's:** level-1 counts are the draft's star-1 counts (means of seeds 1–4, draft → revision: Casual
  Corn 1.9 → 1.8, Pumpkin 4.3 → 4.7, Sweet potato 8.3 → 7.8, Pineapple 14.1 → 15.1; Garden main Pineapple 9.5 → 9.7).
- **Partial quests took a bundle's crops:** handing in every kept Cucumber delayed Triple Jump by up to 5 days (G4); the policy now keeps
  what the next talent bundle needs. The game's quest UI should let the player choose what to hand in.
- **Level counts (2026-11-17):** one count does two jobs badly: at 50 / 100 / 200 with level 1 opening the next crop, the first hour
  had 5 crops (G7) and the top crop came on day ~23 with Casual's overnight hook at 84–88 % (G2); quick crops max at once (Garlic on day
  1.9). Split: the next crop opens at the old rising count (12–25 plants), the levels use flat counts. A flat unlock count (15 for every
  crop) brought the top crop on day 11–12 (G9) and emptied Garden main's shop (G5): the unlock count must rise with the crop.
  Levels by day 7 / 30 / 60 (Casual, means of seeds 1–4): first cut 13 / 20 / 22; 50 / 100 / 200: 5 / 10 / 14 (the weekly player 1 level
  in week 1, Pumpkin day 4.0 → 7.5); **25 / 75 / 200: 8 / 16 / 18** (weekly player 4 by day 7, 22 by day 60). With 25 / 75 / 200 the
  first crop is maxed on day 23–25 (Garden main, Sunflower) and Casual has 17–19 of 48 levels on day 60; 200 Potatoes is quick, 200
  Pineapples a long goal.
- **Tiers flatten tier 1 and lift the tier starts:** Lettuce sells 28 (was 35), Onion 55 (80), Tomato 750 (900), Cucumber 1 400
  (2 100), Pepper 10 000 (12 000), Broccoli 20 000 (29 000), Eggplant 70 000 (85 000), Blueberry 100 000 (150 000), Giant melon
  350 000 (450 000), Sunflower 900 000 (750 000); Potato, Garlic, Corn, Pumpkin, Sweet potato and Pineapple keep their prices.
- **Rested mastery helps only the weekly player:** at 0.5 "level 1s" per extra day (cap 3) Binge's Sweet potato comes on day 14.5 (no
  rest 21.5, draft 26.7) and Pineapple on day 42.5 (none in 60 days before); daily players are unchanged; 1.0 per day (cap 5) adds
  nothing more.
- **Tracked requests** (bonus 0.6 × the sale, crops kept) leave every other check where it was; the bonus size is a first guess.
- **G4 probe (2026-11-17, the user: "fewer plants, easier to obtain"):** two separate bottlenecks. Fewer crops (20 → 12) helped Casual,
  and lower Coin prices (factor 1.5 → 1.0) helped Obby main; removing the rare crop barely helped. No variant passes on all four seeds:
  the miss moves between seeds (1.0–1.4 d against Obby main's 1-day limit). **New candidate (in `CAND`):** Double Jump 2 10 000 + 12
  Cucumber + 1 Frost grape (was 16 000 + 20), Dash 1 8 000 + 12 Corn (12 000 + 20), Dash 2 19 000 + 12 Pepper + 1 Glow mushroom
  (29 000 + 20). G4 passes on seeds 1, 3, 4 (seed 2: Obby main Double Jump 2 1.4 d after Stage 11); Casual buys Dash 1 / Double Jump 2 /
  Dash 2 on day 2.8 / 5.8 / 7.8 (was 6.8 / 7.8 / 10.8, seed 1); obby-only Coins to World 2 = 37 % of the tree (limit 40). Passes 14 / 12 /
  15 / 12 on seeds 1–4 (was 14 / 14 / 13 / 12). B (Tending pays) now fails on seeds 1, 3, 4 with one archetype at 0.94–0.97×: a
  two-run comparison that flips with purchase timing (it flipped in most probe variants), so read as noise. G8 on seed 2: Spender's
  Dash 2 headroom 1.08× (cheaper Dash 2).
- **1.0 requests (E5a, 2026-11-19; `req_run_share` 0, `req_drop_sun` False):** EV passes per seed 1–4, old → new: 16 / 16 / 16 / 17 →
  16 / 13 / 17 / 17. Seed 1: G8 now passes, G2 fails on Casual (54 %; 91–95 % on seeds 2–4, so read as that seed's noise). Seed 2 loses
  three near-misses: G1 (Binge day 1 4.6 min, limit 4), G4 (Obby main Double Jump 2 2.0 d after Stage 11, was 0.5; the timed run's
  Sunshine had sped this archetype up) and G5 (Casual last purchase day 84, was 91). Accepted for 1.0 with the other near-misses;
  revisit with EV2c, which brings the timed run back.
- **Rested mastery works (2026-11-17 re-run):** the weekly player (Binge) gets Sweet potato on day 14.7–21.4 with it, 21.4–28.4 without, and
  Pineapple on day 42.5–49.5, never within 60 days without. The earlier "14.5" was seed 3's number. Daily players are unchanged.

EV2e (2026-11-17): the game now stores a pet kind at purchase / free placement, uses the approved rarity timers and
uses shared time tiers to hide exact rarity and keeps the chosen pet server-only until hatch. Cancellation uses a small trash button
with shared ConfirmTap (orange OK? → second tap; discard without refund). First free pet remains instant. Old eggs keep their deadlines.
`economy.py` reads and pins the rarity timer table; its per-egg `hatch_s` is the weighted mean (Basic 1 057.8 s, Golden 3 354 s),
used for report comparison, not a fixed gameplay timer. `economy_ev.py` checks the table against the proposal. The shared-tier
forecast passes 16/18: G7's longest first-hour news gap is 15.9 m (target ≤ 10); G9's Casual talent-first top crop is day 13.3
(target ≥ 14). Legendary expected-count timing stays in band. These targets need review at balancing; timers are the user's
accepted values and check thresholds are unchanged. The forecast's timed common/uncommon starter is still an approximation
of the game's instant first pet.

## Findings (EG, 2026-11-21; seeds 1–4, Ruby / Diamond swept 300 000–500 000 / 1.5–3.5 M)
- **Ruby 450 000:** the lowest nice price that keeps Obby main ≥ 2 h on every seed (400 000: 1.9 h on seed 1; nice() has no step
  between them). Obby main earns ~5× a Casual's hour the day Pumpkin opens, so the 2 h floor puts the median at 4.3–6 h, above the
  2–4 h target; the floor wins. Binge opens Pumpkin on day 0.6 with little income (Ruby = 70–84 h) and still buys 10–14.
- **Diamond 3 000 000:** Casual's Legendary odds reach 50 % on day 15.8–20.3 (G9 ≥ 14); 2 000 000 gave day 14.3 on seed 4 and
  Obby main 2.4 h. Median 6–10 h of the opening day (Casual 12–19 h: Giant melon opens on a short-session day).
- **Noise:** with these prices seed 1 also fails G5 (Casual's last purchase day 82 < 90) and B2 (guard 0.87×); both flip on the
  RNG path, not the price (over seeds 1–8 G5 fails 3× for Ruby 400 000 and 450 000 alike; B2 ranges 0.87–1.06× for both). The
  committed model already failed G5 on seed 2 and B2 on seed 3.

## Findings (FL, flatter ladder, 2026-11-21; seeds 1–8; built as FL, `CAND` = the configs since; the probe script with variants A–P is in git history only)
The user's question: fewer "inflating" steps (~1.5× per crop instead of the felt 4×), and no 36–48 h crops. As built, a crop's sale
rises 2.2× per crop on average, of which 1.83× is grow time; Coins per square-hour are flat inside a tier and jump ×1.73 at each of 5
tier steps (15× in all). So the per-plant step only falls if grow time stops rising with the unlock. The probe keeps the ids, unlock
order, quests and sinks, and makes grow time a choice inside a tier (short / medium / long). **Built: variant O.**
**As built (`python tools/economy_ev.py --seed N`):** 17 / 17 / 17 / 16 / 16 / 17 / 17 / 16 of 19 on seeds 1–8; G8 fails on every
seed, G11 on several, G1, G3, G4 or R on single seeds; G2 95–100 %; Casual's top crop day 10.3–12.3. Numbers below are the probe's.

| Tier (× net / sq-h) | Crops (away-time; changed in bold) |
|---|---|
| 0 (1) / 1 (1.73) / 2 (2.98), as built | Potato 20 s, Lettuce 1 m, Onion 2 m / Garlic 6 m, Tomato 16 m, Cucumber 30 m / **Corn 15 m**, Pepper 2 h, **Broccoli 8 h** |
| 3 (× 1.5 = 4.47) | **Pumpkin 12 h, Eggplant 5 h, Blueberry 20 m** |
| 4 (6.7) | **Sweet potato 6 h, Giant melon 14 h** |
| 5 (10.1, was 15.4) | **Sunflower 10 h, Pineapple 30 m** |

- **O passes 15 / 15 / 15 / 15 / 14 / 15 / 15 / 14 of the 18 checks besides EV0 on seeds 1–8** (as built: 15 / 16 / 17 / 17 / 13 / 15 / 17 /
  11); with G9 from day 10: 16 / 16 / 16 / 16 / 15 / 16 / 16 / 15. Fewer swings between seeds; G8 fails on every seed, G9 failed before its bound moved (below). Income per day (seed 1, day 7 / 14 / 30 / 60): Casual 2.2 / 29 /
  41 / 53 M → 3.5 / 14 / 18 / 20 M, Garden main 7.5 / 40 / 51 / 52 M → 12 / 16 / 21 / 23 M. With every sink unchanged G3, G5, C, G7,
  G12 hold: the shop lasts longer, the next goal stays near.
- **G11 (old crops levelled)** passes on 3 of 8 seeds (fails on all 8 as built; misses are Obby main / Casual at 12–15 %, limit 15).
- **Needed alongside:**
  - tiers 0–2 keep their rates and durations (a lower step from tier 1, × 1.5–1.6, broke G7, G4 and G10);
  - rare sales × 0.5 (at × 0.7–0.8 Casual's day 0–3 rare share is 63–82 %, check R);
  - mastery levels 2–3 need × 3 plants for crops ≤ 10 min and × 1.5 up to 1 h (without it Onion was maxed on day 2.7, G12); built
    as `Mastery.LevelsBy` 25 / 225 / 600 and 25 / 110 / 300 (model `m_bands`); a level never drops below the points spent;
  - Double Jump 2 at 10 Cucumber + 1 Frost grape and 8 500 Coins, factor 0.8 (was 12 + 1 and 10 000; G4 at 1.0–2.5 d without it);
  - **the stall always stocks the best unlocked crop of ≥ 6 h** (an overnight staple; `Stall.LongSeconds`, model `st_long`). G2 (Casual 50–87 %) was the stall, not the
    ladder: with one long crop per tier, an hour whose restock had none left nothing for the night. With it Casual is 96–99 %;
  - long crops spread so every schedule has one: Eggplant 5 h and Sweet potato 6 h for players who return every ~5 h.
- **Model rule (`chase_stuck_days`): a stuck player chases the bar.** The `chase` floor (plant the newest crop only while it earns ≥ 0.5 × the
  best) left a 5 h Eggplant unplanted for 55 days by Casual (two visits a day: 2–6 h crops fit neither a session nor the night). In
  the model, a crop open for more than a day is planted for its bar whatever it earns. The game must make that choice obvious (the bar
  on the seed, the Coins per hour shown): an unlock that hinges on a crop that does not fit the player's day is the ladder's one trap.
- **G9's top crop:** Casual opens Pineapple on day 10.3–12.3 (as built ~15); 1.5× the unlock counts from Sweet potato on (variant P)
  moved it by under a day, so the schedule, not the count, sets it. *Decided (the user, 2026-11-21): keep day 10–12*; G9's top-crop
  bound is now day 10 (was 14).
- **G8 fails on every seed:** paid offline speed is worth 1.0–1.2× (target 1.2–1.5): crops ≤ 16 h already fit one free absence. The
  comfort product (D2) needs another form (e.g. a replant while away), not double speed.
- **UI:** the sale per harvest no longer rises with the unlock (Pineapple 8 500 after Pumpkin 90 000): the seed stall shows each
  common crop's net Coins per hour of one square (`field.seed.rate`), or a new crop looks worse.
- Tried and dropped: × 1.5 from tier 1 (A, C–E), a short-crop premium (B: short × 1.15, long × 0.9), Cucumber 1–3 h (F–I: slower Corn
  quest, G4), Eggplant 2 h / Sweet potato 3 h (L: dead time for Casual).

## Findings (FXP, square prices on the flatter income, 2026-11-22; built, `CAND` `sq_k3` = the configs since)
*Why (the user):* FL cut late income by half or more (Casual day 30 / 60: 41 / 53 M → 18 / 20 M a day) but kept every sink, so the squares'
× 1.93 top (square 32: 110 M … 36: 750 M) ran away from income: on 120 days Casual bought square 32 on day 53 and never 36; the 42 FX squares at
750 M each were out of reach. *Probe* (scratch script, squares only, every other sink unchanged; 120 days, seed 1): squares 5–28 as built, then
× q3 per square to 36, flat from 37.

| q3 (36 = late price) | Casual #36 / #78 | Garden main #36 / #78 | Obby main #36 / #78 | Casual income d30 / d90 |
|---|---|---|---|---|
| as built (750 M) | – / – (#32 day 53) | – / – (#32 day 45) | 110 / – | 18 / 21 M |
| × 1.2 (17 M) | 27 / 51 | 23 / 45 | 19 / 37 | 24 / 67 M |
| **× 1.33 (40 M), built** | **41 / 96** | **35 / 85** | **28 / 63** | **21 / 55 M** |
| × 1.5 (100 M) | 83 / – (43 open on day 120) | 70 / – (49) | 54 / – (67) | 20 / 26 M |

- **Built: × 1.33 (40 M).** Squares 29–36: 5.5 / 7 / 9.5 / 13 / 17 / 22 / 29 / 40 M (were 7.5 M … 750 M); the doubled field is a ~3-month goal
  for Casual, ~2 for Obby main, and a late square costs ~1–2 days of the late income. All 32 + 42 squares: 1.83 B (was 33 B).
- **Checks (seed 1):** as before FXP: 20 / 22, the same two known misses (G8 Spender headroom, G11 old crops levelled); G5 Casual's last
  purchase day 99 (4 left at day 100), C 92–97 %. Seeds 2 / 3 / 4: 18 / 18 / 20 of 22 (were 16 / 18 / 21: seed 2 now passes B2 and G11,
  seed 4 misses G11 by a hair, Casual 14 %); every seed's Spender now buys square 36 (days 39–42).
- **Open:** the other late sinks keep the EV2a ladder (Growth 4 22 M, Sorter 3 45 M, Shears 3 160 M; anchored on squares 26–29); Sorter 3 is
  no longer bought within 60 days in the Spender run (G8).

## Findings (FD model pass, 2026-11-21; seeds 1–4; in the configs since the FD build, 2026-11-21)
*Build:* `PetConfig` `FoodLimitShare` / `ObbyAboveLimit` / `WithYouXp`, `GardenConfig` `FoodGrowth` / `FoodRarity` (prices `FoodPrice`,
the same `nice()` rounding, half to even; fed crops `CropFeedXp`, floored to whole XP); EV0 compares them with `CAND` (`economy.py` loads
them as `P["fd"]`). The game floors a fed crop's XP; the model keeps the fraction (the E1a3 bound holds either way).
**Decided (the user, 2026-11-21), in three steps:** "Obby time is hard working. Staying with me is not." → time with you stays, 10×
slower than designed (0.75 XP per online minute) → the target: a pet levels quickly to ~10, where it contributes (food does that), and
the max is not easy, ~90 days for a player who comes every day (Casual, our archetypes). In `CAND`: `with_you_xp` 0.75, `obby_above`
0.04 (past the food limit a Gold run gives ~2 XP; an obby minute ~2.1 XP with the time, an idle minute 0.75). Casual gets ~107 XP a day
past the limit (62 obby, 45 time). Days from Cuteness 10 to the max at that pace (linear, for scale): Common (12) ~23, Uncommon (14)
~34, Rare (16) ~49, Epic (18) ~66, Legendary (20) 88.5 (simulated). Simulated Legendary (seeds 1–4, all equal): Casual 88.5 days,
Obby main 29.5, Garden main 85.2 (more online time, little obby); Binge's pet arrives on day 42 and does not reach 20 in the 130-day
probe. Cuteness 10 within 0.5–1.5 days for Casual (the ×10 Legendary price, below), at once for the others. Check 6's band: 75–110
days. Seeds 1–4 (with the rarity factor) fail G8 everywhere plus near-misses of the committed model's kinds: G11 (1, 2, 3), G4 (2, 3),
G1 (2: Binge 4.2 min, bound 4), G9 (2: Casual's top crop day 9.8, bound 10), B2 (2: 1.000×), B (3: Casual 0.976×);
`economy.py check` E0 15 / 15, drift 0, exit 1 from G8 and G11 as before. The analysis that led there:
- **Obby care XP dominates.** In the game as built, repeat Gold runs give every equipped pet ~50 care XP (20 medal + up to 30 move) per
  ~1.5 min run: Casual's pets get ~1 500 XP a day from 45 min of obby, Obby main ~3 950. The design's 7.5 XP per online minute is 450
  a day for Casual. As designed (obby XP unchanged above the limit), Casual's day-7 Legendary goes from Cuteness 10 to 20 in 6.5–7.5 days,
  Obby main in 1.5, a Binge player within one 6 h day. Check 6 (≥ 14 days) fails even with no time with you at all (9.5 days).
- **Options swept** (days from the pet's arrival to Cuteness 20, seeds 1–3; Lv 10 is reached on the first day by food in all of them):

  | Option | Casual | Obby main | Garden main | Binge |
  |---|---|---|---|---|
  | as designed (7.5 / min, obby × 1) | 6.5–7.5 | 1.5 | 10 | 0.2 |
  | **decided: 0.75 / min, obby × 0.04** (seeds 1–4) | 88.5 | 29.5 | 85.2 | – |
  | 0.75 / min, obby × 0.03 / × 0.05 | 103.5 / 77.5 | 34 / 26.5 | 89 / 81 | – / 77 |
  | 0.5 / min, obby × 0.05 (more weight on the obby) | 88.5 | 31 | 108 | – |
  | 0.75 / min, obby × 1 | 8.5–9 | 2.2 | 25.6 | 0.2 |
  | no time with you, obby × 1 | 8.5–9.5 | 2.5 | 29.6 | 0.2 |
  | A: 7.5 / min, obby × 0.1 past the limit | 16–16.5 | 4.5 | 10.2 | 14.1 |
  | A′: 7.5 / min, obby × 0.15 | 14.5–15 | 4.5 | 10.2 | 14.1 |
  | B: no time with you, obby × 0.4–0.5 | 15–18.5 | 4.5–5.5 | 45–53 | 7–14 |
  | C: 10–11 / min, no obby XP past the limit | 14–15.5 | 4–4.5 | 7–7.6 | 14.1 |

  With whole obby XP no time-with-you rate gets near 90 days: ~1 500 obby XP a day alone gives Casual 9.5 days. The 90-day target
  needs obby XP scaled to a few % past the limit; time with you then matters (Garden main's 120 min online keep it close to Casual).
- **Food prices to the limit** (the cheapest mix, each food priced at the level the pet has when it eats it; `food_cost`): one Feast
  (1 500) takes a Common, Uncommon or Rare from Cuteness 1 to its limit (its extra XP flows on to work traits); Epic 7 370 (to 9),
  Legendary 200 100 with its ×10 (to 10: a Feast at level 1, then Cakes and Berries; 20 010 at ×1, Feasts alone 29 500). Today (flat
  prices) Cuteness 1 → 10 costs 2 700 and 1 → 20 16 750. A work trait to its limit: Common 5 870, Legendary 1 183 000 (×10; was
  ~13 000). The sim's feeding buys the best XP per Coin (Feasts), a little above the cheapest.
- **Rarity factor** (the user, 2026-11-21: "scale by rarity"; `food_rarity`, fitted to each rarity's first pet, seeds 1–2; the share
  is the bootstrap's cost ÷ the 24 h of income before the pet arrives, Casual / Obby main / Garden main). Pets of a rarity arrive by the
  hundreds late (Ruby / Diamond eggs, Rares and Epics at a median day ~30, ~20 M a day), when no price matters; the first one counts.
  Common / Uncommon arrive on day 0.3 (1 500: ~1 %), Rare on day 0.5–1.3 (1 500: 12 % / 1 % / 1 %), Epic on day 1.3–1.8 (7 370:
  17 % / 5 % / 2 %): Casual is poorest in its first two days, so ×1 there. A Legendary arrives on day 3–41 (day-7 streak pet, the egg
  odds ~day 20; 1–3 in 60 days): at ×1 20 010 is 0.06–1 %, at **×10** 200 100 is 7 % / 1 % / 11 %. Tried: ×2 per rarity (Epic 56 800:
  133 % of Casual's day 1.8), 1 / 1.5 / 2 / 3 / 20 (Epic 51 %), 1 / 1 / 1.5 / 2 / 10 (Epic 34 %). Fed crops follow the Berry's price for
  that pet, so a Legendary cannot eat Potatoes at all and Corn only below Lv 11. With ×10 the sim's 2 % food share needs up to 1.5
  days for the day-7 Legendary's bootstrap (6–9 % of Casual's day; a player pays it at once): check 6 allows 2 days.
- **Fed crops (E1a3 at every level):** "÷ 2.65^(b − 1)" breaks E1a3 by up to 3 % where nice() rounds the Berry's price up (Lettuce at
  Lv 13: 1.034×). Rule in the model: a crop gives its level-1 XP × the weakest food's XP per Coin at the pet's level ÷ the same at level 1,
  so feeding never beats selling and buying, at any level. Refused (< 1 XP) from: Potato Lv 5, Lettuce 8, Onion 9, Garlic 13, Tomato 15,
  Cucumber and Corn 16, Blueberry 17.
- **A fresh Legendary is weaker than grown Epics:** at its food limit (Cuteness 10, +22.6 %) it is below an Epic at 18 (+25.2 %), which the
  activity rules reach for a daily player. A player who equips by the bonus shown never takes it along to grow it. The model equips by
  current bonus (only the probe is forced). *Decided (the user, 2026-11-21):* the game does not show a pet's potential (its cap): a
  hidden mechanic, players find out by growing pets.
- **Other checks:** no new kind of failure (decided rule: above). The committed model fails G8 on every seed plus G11 (seeds 1, 4),
  B2 (2), G3 (3) and G4 (4); G11 is FL's known near-miss (passes on 3 of 8 seeds).
- **Model changes:** Cuteness is simulated on the 20-level scale (it was whole base levels); care XP left over at a limit flows on to the
  next trait (`PetConfig.GainCareXp`); food feeds Cuteness before work traits; the FD rules switch off with `--set fd=False` (the game
  before FD).

## Open decisions for the user
1. The EV bands (table above) and the proposal itself: approved; EV2a (numbers) and EV2b (talent bundles) are built (2026-11-07); EV2e
   (eggs at purchase + rarity timers + no-refund cancellation) is implemented (2026-11-17); EV2c (Sunshine), EV2d (Scouting)
   are scoped when each starts. EV2b retired E0's check 3 (the no-grind required set,
   garden off): talents need the farm by design, G4 replaces it.
2. Whether the placeholder eggs become real egg kinds (needed for Legendary scarcity past week 3).
3. The real landmark / estate sinks (E6 / E7) that replace the reserved ladder.
4. **EV3** ("EV3 — design draft" and its revision above, build parts in ROADMAP → EV3): *direction decided (the user, 2026-11-17):*
   mastery by plants grown, three levels with one point per line, price tiers, quests piece by piece without expiry, rested mastery,
   tracked requests (E5); crop XP = time, 15 stars and the old G11 are out. **Rested mastery is silent** (the user, 2026-11-17): no
   text, bar or icon tells the player; their plants simply count double after a long absence. G4: make the bundles easier (the user,
   2026-11-17); the candidate is in `CAND` (Findings → G4 probe). **Signed off (the user, 2026-11-17):** the tier table and its prices (Findings →
   EV3 revision), the unlock counts (12–24 plants of the previous crop; level counts 25 / 75 / 200 decided 2026-11-17), the new Double
   Jump 2 / Dash bundles, the point size (+11 % per line), the Sweet potato quest (5 Blueberry + 4 Eggplant), the rested rate (0.5 per
   extra day, cap 3), the obby payouts (rule 6, unchanged), and the near-misses listed in the findings (accept, or tune in the ST model,
   which re-runs the chain): the near-misses are accepted for now, to revisit in the ST model.
5. **A flatter curve** (shorter grow-time span, value steps ~1.5–2× per crop, a slower square ladder): probe in the model after EV3a,
   before M7 (after it prices never go down). *Probed 2026-11-21* (Findings (FL), candidate O): tiers drive the rate, grow time is a choice
   inside a tier, longest crop 14 h, an overnight staple in the stall; works with sinks unchanged. Top crop day 10–12 accepted (the user,
   2026-11-21; G9 from day 10). Open: G8 (paid offline speed). Built as FL (2026-11-21).
6. **Going public with a ~5-day horizon:** *resolved (the user, 2026-11-17):* the horizon is not a gate. 1.0 is gated by crop mastery
   (EV3), the rotating stall (ST), the online loop (requests, E5), the Harvest Hall (SH) and player feedback (FB); ROADMAP → Next.
   The comfort shop (D2) and Sunshine (EV2c) come after 1.0.
7. **Endgame:** drops (Weekly, Variants, Kitchen), landmark / estate sinks, a soft Replant if the queue empties, harvest boards; nothing
   needed now.
8. **Rotating stall (ST, decided in principle 2026-11-17):** restock cadence (1–3 h, UTC, the same on every server), stock per crop, the
   always-stocked set (staples, talent-bundle and quest crops), the pity rule for the newest crop. *Modelled 2026-11-17* (Findings → "ST");
   the candidate (hourly, staples Potato–Onion, half of the other crops per restock and each at least every 3rd, 12 seeds, the newest
   crop always) waits for the user's sign-off.

9. **FD (model pass 2026-11-21, Findings (FD)):** *decided (the user, 2026-11-21):* Cuteness to ~10 quick (food), the max in ~90 days for
   Casual: past the food limit obby care XP × 0.04 and time with you 0.75 XP per online minute (10× slower than designed); check 6's
   band 75–110 days; a pet's potential (its cap) is not shown to players; a fed crop's XP follows the Berry's
   price ratio (its level-1 XP × the Berry's level-1 price ÷ its price for that pet), not ÷ 2.65^(b − 1); food prices scale by
   rarity (Common–Epic × 1, Legendary × 10).

## E0 — checks of the game as built (until EV2a)
| Check | Rule |
|---|---|
| 1 drift | every config number equals its pin |
| 2 reproduction | the GDD figures (medal totals, talent tree, a day of Gold runs) |
| 3 required set | each required talent set ≤ 65 % of the Coins earned up to its stage, garden off |
| 4 P / L | field ≤ 1.0× obby Coins over days 1–3 (Garden main 1.8×); ≥ 3× by day 7, ≥ 10× by day 30 (Casual, Garden main); Obby main ≥ 1× by day 14 |
| 5 B, 6 C, O | Tending beats no Tending; sinks ≥ 60 % / 78 % by day 30 / 60; online income per hour ≥ 2× offline |
| 12, 13 | size roll mean 1 ± 0.005; crop XP ≤ sale × Berry's XP per Coin |

Still-valid E0 decisions: online beats offline (2026-10-24; offline 1 / online 2 since OG2, 2026-11-20, 24 h cap); the field for everyone (FA, 2026-11-06);
P4 pet traits (Cuteness bonus, saturating at 1.49; pinned 2026-11-05); crows from Renown 3, rare crops safe (2026-11-04).
