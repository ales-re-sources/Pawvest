# Pawvest economy model — targets, decisions, how to run

Two models live in `tools/` (Python stdlib):
- **`economy_ev.py` (EV, the engagement-first economy):** the numbers (`CAND`) and the checks they must pass (G1–G12, R, B, B2, C, U, EG, FD).
  `CAND["mode"]` is `"stars"` (the game's crop mastery) or `"renown"` (the pre-mastery game, kept for comparison).
- **`economy.py` (E0):** reads every Coin number from the Luau configs, pins it (`tools/economy_pins.json`), runs checks 1 (pin drift), 2 (GDD
  reproduction), 12 (size roll: mean factor 1 ± 0.005, Big ~20 %, Giant ~3 %), 13 (crop XP ≤ sale × the weakest food's XP per Coin, E1a3) and
  the EV checks. E0's field simulation (`sim`, `field`, `pets`, `tools`) and no-grind talent check are retired (G4 replaces the latter).

## How to run
```
python tools/economy.py check      # pins + checks 1, 2, 12, 13 + the EV checks; exit 1 on a failure (~1 min)
python tools/economy.py proposal   # EV: the old -> new tables (crops, trees, sinks, talents, eggs, obby, archetypes) + the EV checks
python tools/economy.py evcheck    # EV checks only (same as python tools/economy_ev.py evcheck)
python tools/economy.py hour1      # EV: a fresh player's first hour (G7 numbers)
python tools/economy.py drift      # config numbers that differ from the pins (exit 1 if any)
python tools/economy.py pin        # accept the reviewed config values as the new pins
python tools/economy.py report     # E0 tables of the built game
python tools/economy_ev.py evcheck|proposal|hour1 [--days N] [--seed N] [--set key=literal]   # --set probes a CAND override (unknown key: exit 2)
```
`economy.py` forwards only `--days` to the EV model; `--seed` (default 1) and `--set` need `economy_ev.py` itself. `--seeds` / `--crops` /
`--scale` are E0 leftovers.

Run `check` after changing any price, rate or reward in a config; `pin` only after the user has reviewed the values. EV0 (inside the EV
checks) fails when the configs differ from `CAND`: crops (grow time, sale, seed, `step`, `quest`), `Mastery` incl. `Points`, `Stall`, the crows /
cart-taste crop, the Tutorial / World 1 `firstClear`, sinks (Coins only), talent bundles, the FD food numbers. To try a number, edit `CAND`
(or `--set`), then move the configs to match and `pin`.

**Last full run (TR5, seed 1): 20 / 22 pass; misses G8 (known) and G1 (Binge p90 8.2 min vs 8)** (so `check` exits 1). Seeds 2–4 pass 18–19 (G11 is the other
known miss); the misses that move between seeds (B, B2, FD, R by Spender at 70 %, G1 by Binge's first day at 4–4.6 min or its later p90 at 8.2, G2 by Garden main
at 87 %) are RNG-path noise, not a price.

## Crop timing update (OG2 and OG2b)
All crop base durations were doubled (FL then reshaped the ladder; the longest crop is 14 h). Rates stay online 2 / offline 1, so the actual
online / offline pace is as before. Displayed times and countdowns use the away-time baseline and tick faster while playing (Cloches extra).
The offline cap is 24 h; long crops need several absences or online time; seed rows say "Growth time", never "done in one absence". Field-job
XP keeps its own pinned rates 1 / 0.5. Request `MaxGrow` is 8 growth hours. The model doubles ladder / rare / tree growth durations; prices
are unchanged; model-only paid offline rate 2 (48 h cap) stands for the old rate 1. No profile migration: plantings keep their earned growth seconds.

## EV — why and the pillars
The E0 targets kept field income near obby income: a 5-minute Potato worth 4 Coins, talents bought without farming, repeat runs paying tens
of Coins next to a farm paying 100 k+. Direction: **engagement, not income equality.** Farming is the core; the obby and mini-games are the
distraction while things grow and the only source of rare drops. Something is always growing, hatching or nearly affordable.

1. **A timer for every gap:** one ladder of grow / hatch times from seconds to ~a day, so every session and absence has a crop.
2. **Online is busy, offline is a hook:** something to collect every few minutes online; a long crop / egg ripens near the return.
3. **The next goal is close, never already bought:** time-to-afford stays in a band.
4. **Each new crop is worth unlocking:** net Coins per square-hour rises per price tier (below).
5. **The obby is the expedition:** one-time medal / first-clear Coins stay as starter capital; repeat runs pay **Sunshine**, rare seeds and
   pet XP, never Coins.
6. **Talents need the farm:** Coins + a crop bundle; the required levels also take a rare crop of the world before.
7. **Inflation is accepted** (genre norm): every sink is priced on the square ladder; numbers stay integers < 2^53.
8. **No regret (for M7):** after launch prices never go down; nothing sold is later handed out free in bulk; a capacity product never exceeds
   the earnable maximum. Free play is scarce enough that a comfort purchase is worth 1.2–1.5× (G8), never more.

## EV checks
Bands are provisional until the user confirms them. Archetypes (`economy_ev.ARCHETYPES`): Obby main (7:00 / 12:30 / 18:00, 2 h obby),
Casual (8:00 / 19:00, 45 min obby), Garden main (7 / 12 / 17 / 21, 15 min obby), Binge (one 6 h day a week), Spender (Casual's schedule,
paid comforts). Policies: talent-first, pets-first.

| Check | Rule |
|---|---|
| G1 ready cadence | online minutes per collectable event (ripe batch, fruit, hatch, drop, request) ≤ 4 on day 1, p90 ≤ 8 later |
| G2 return hook | ≥ 90 % of session ends (day 2+) have a crop or egg ripening near the coming return |
| G3 next goal | at session end the next goal (cheapest of the shop's first 3) is 0.3–2 sessions of income away (median; lower bound for daily players only), ≤ 3 days max, days 1–30 |
| G4 talents | obby-only Coins through World 2 ≤ 40 % of the World 1–2 tree; Double Jump 2 / Dash 2 bought within 1 day (Obby / Garden main) or 2 days (Casual) of reaching Stage 11 / 13 |
| G5 horizon | Garden main's last purchase not before day 45, Casual's not before day 90 (or items left) |
| G6 expedition | obby Coins ≤ 25 % of income after day 3; Sunshine ≤ 40 min of growth per obby hour |
| G7 first hour | first harvest ≤ 30 s, ≥ 6 crops in hour 1, longest wait for something new (level, crop, first harvest of a kind, purchase, hatch, a finished request) ≤ 10 min, first square ≤ 15 min, first hatch ≤ 5 min |
| G8 Spender | headroom on Dash 2, Squares 20 / 28 / 36, Growth 4, Sorter 3: median 1.2–1.5×, max ≤ 1.6× |
| G9 scarcity | Casual: the expected Legendary count reaches 0.5 not before day 14; top crop day 10–28 (talent-first), ≥ 10 (pets-first); last tool ≥ day 14 |
| EG | each egg with an opening crop costs ≥ 2 h of every archetype's income in the 24 h after that crop opens, if it buys one (target: 2–4 h of the median) |
| R | rare crops stay a treat: a sale ≤ 70 % of a day's income on days 0–3 and, in the first 5 days, ≤ 5× everything earned before it; a World 1 rare gives at most 3 (Renown-model) levels |
| B | Tending pets earn more (guards and crows off in both runs) |
| B2 | one field slot as a guard instead of a tender earns at least as much (Casual) |
| C | sinks ≥ 60 % of the faucet by day 30, ≥ 78 % by day 60 |
| G10 | a Tutorial / World 1 first clear (finish + medals + the seed pack at seed price) ≤ 3 min of the Casual farm's online income |
| G11 | days 3–30: ≥ 15 % of the crop levels earned are on crops ≥ 3 steps below the newest unlocked one (every archetype) |
| G12 | the first crop at its top level not before day 7 (Garden main); Casual has ≥ 25 % of all levels still to earn on day 60 |
| U | a maxed crop earns net per square-hour what a fresh crop 2–3 steps up the ladder earns (best and worst way to spend the points) |
| FD | Casual's day-7 Legendary (streak pet, always equipped) reaches Cuteness 10 within 2 days and 20 in 75–110 days (~90 for a daily player); a fed crop's XP ≤ its sale × the weakest food's XP per Coin at every level and rarity (E1a3) |

## EV — the rules as simulated
- **Player:** sessions per archetype, the obby block in the middle of each session with garden checks every 5–10 min; between sessions the
  field grows at the offline rate (Spender: 2.0 for 48 h). The player reacts to every ripe batch, fruit and egg and picks the crop with the best
  net Coins per wall-clock second until the next chance to harvest (bundle and request crops only when they ripen in time). **Unlock-bar
  policy:** plant just enough squares of the newest crop to fill its unlock count while it earns ≥ 0.5 × the best crop's rate (`chase`), before
  bundles and requests; quest crops at once; a crop open for more than a day is planted for its bar whatever it earns (`chase_stuck_days`).
  The game must make that choice obvious (the bar on the seed, Coins per hour shown): an unlock that hinges on a crop that does not fit the
  player's day is the ladder's one trap.
- **Shop:** one queue sorted by price × policy bias (talent-first: talents ×0.5, pets ×1.5; pets-first: pets ×0.6); unbuyable items are
  skipped, saving goes to a blocking required talent first; a seed reserve, the unlock bar's Coins and the rare crops for the next talent
  level are kept; eggs and food from 8 / 2 % of income (pets-first 25 / 8 %).
- **Crops and mastery:** 6 **price tiers** (below), a tier shares one net Coins per square-hour. **Mastery = plants grown of that crop**,
  3 levels, one point each (Value +11 % sale, Size +11 % size factor, Speed −11 % grow time), any line up to 3 in one (`Points.PerLine`), no
  reset; a maxed crop earns × 1.44–1.49 net per square-hour (2–2.2 ladder steps; model `pt_order` "auto": Speed on crops ≤ 1 h, Price on
  overnight ones). Level counts `Mastery.Levels` 25 / 75 / 200 plants; quick crops need more (`LevelsBy`: grow ≤ 600 s 25 / 225 / 600, ≤ 3 600 s
  25 / 110 / 300); a level never drops below the points spent. The next common crop opens at `step` plants of the previous one (12 Potato … 25
  Pineapple); Corn, Pumpkin and Sweet potato by a **quest** handed in piece by piece, no expiry (the policy keeps what the next talent bundle
  needs). **Rested mastery** (silent, never shown): each full day away past the first adds 0.5 of an unlock count of plants that count double
  (cap 3); it helps only the weekly player. Crows and the market cart's taste start with the Garlic unlock; rare crops give no mastery.
- **Rotating seed stall (ST; `CropConfig.Stall`, model `st_*`):** hourly restocks on a UTC schedule (the same draw on every server, counts per
  player). Always in stock: the first 3 crops, the newest unlocked crop, the best unlocked crop of ≥ 6 h (an overnight staple), the next talent
  bundle's crops and the open quest's crops. Every other unlocked crop shows with chance 0.5, at least every 3rd restock, 12 seeds per player.
  A stall tree's sapling rotates rarer and alone (TR5, model `tree_st`): chance 0.1, at least every 24th restock (in stock ~14 % of hours,
  ~3 a day), 1 sapling per player.
- **Fruit trees (TR; CAND `trees`, `tree_unlock`, `obby_trees`, `tree_squares`):** a tree takes `tree_squares` (4: a 2 × 2 block, TR4)
  squares for good; fruit = the ladder crop's net per square-hour × 4 × the fruit time, no seed. **Stall tree (Apple):** saplings 9 000 each (TR5:
  no cap, the player's choice; the model buys 1), sold from the Cucumber unlock in the ST rotation, first growth 2 h, a fruit every 5 min, 8 held, 720 a fruit (Cucumber's 2 159 / sq-h).
  **Rare tree (Golden apple):** every 3rd World 1 meter seed is a sapling while fewer than 3 are held + planted; first growth 8 h, a fruit
  every 45 min, 8 held, 16 777 a fruit (Blueberry's 5 592 / sq-h). Saplings are planted while 4+ (bought) / 8+ (obby) crop squares stay
  besides the trees' blocks; the model never digs a tree up; the player picks once half the cap hangs.
- **Squares:** 78 (FX). Price 290 × 1.33^(j−5) up to square 20, × 1.93 for squares 21–28, × 1.33 up to 40 M at square 36 (FXP), flat 40 M for
  37–78 (`CropConfig.Expansions`). Every other sink is anchored on the EV2a ladder (× 1.93 on to square 36: `sq`, not the squares' own `sq_own`)
  × a factor, so it arrives when that ladder's square would. Reserved sinks (landmarks, estate, decor; not designed): 70 steps × 1.15 from
  square 12's price.
- **Eggs:** the pet is rolled at purchase; its rarity sets the hatch time (Common / Uncommon 5 m, Rare 1 h, Epic / Legendary 4 h; `economy.py`
  pins the table). The player buys the dearest open egg the egg fund covers. Ruby and Diamond (above Pearl `Basic` and Topaz `Golden`) keep
  Legendaries scarce while income grows ~1000×; each opens with a crop (`egg_opens`: Pumpkin, Giant melon), check EG.
- **Pet care (FD, `fd`):** Cuteness on the 20-level scale. The food fund feeds each equipped pet, best bonus first: priced × 2.65^(b − 1) by the
  base level of the trait it trains and × `food_rarity` (Legendary 10), up to half the rarity cap (`food_limit`); Cuteness first, then work
  traits. Past the food limit Cuteness grows to the cap from obby care XP × `obby_above` (0.04) and time with you (`with_you_xp` 0.75 per online
  minute, every equipped pet); work traits take care XP only up to the limit, leftovers flow on to the next trait (`PetConfig.GainCareXp`).
  The model equips by current bonus; only the FD check's probe pet is always equipped. `--set fd=False` switches FD off.
- **Obby:** first clears and medals pay their one-time Coins; repeat medal finishes pay Sunshine (16 / 24 / 32 s per Bronze / Silver / Gold,
  × 0.8^n per stage and day, floor 6 s) into a store of up to 3 h; spending it is a **time skip**: the whole store at once, every growing
  square, tree and incubator advances by the full amount (not split; what a square does not need is lost for it); the rare-seed meter, daily
  seed and pouch stay. Casual gets ~31 min of skip per obby hour.
- **Scouting:** XP = seconds of a running stage timer while equipped (level 2 after 45 min, × 2 per level); bonus min(0.5, 0.5 × strength)
  on Sunshine, meter and pouch.
- **Requests** (tracked, `req_auto`; `CropConfig.Requests`): 3 slots, per-day RNG (UTC day + user); "grow N Tomatoes" counts harvests of that
  crop (crops are sold as usual) and pays a bonus of 0.6 × the sale of the count; an unfinished request stays, finished slots refill on the next
  UTC day; the board opens on the first visit with two eligible crops (day 0 included). Eligible: unlocked common crops from the 3rd on with
  grow ≤ 8 growth hours; N is 30 % of a day's income (sales + request bonuses of the previous UTC day or today, whichever is more, at least
  2 000). A finished request drops (1 in 3) a rare seed or a free egg, half and half (Pearl; Topaz once Pumpkin is open). No timed run and no
  Sunshine drop until EV2c. **Streak:** Sunshine 10–30 min on days 1–6, day 7 a pet (Epic 95 %, Legendary 5 %); a missed day pauses it.
- **Crows and guards:** in a crow block a ripe crop may be eaten, up to one per 12 unguarded squares per absence; guarded squares are safe; a
  guard covers 18 / 30 / 42 squares by level band. **Tending** (growth mode): a tended square grows 50 % × strength faster.

## EV — the proposal (current numbers; `economy.py proposal` prints the old → new tables)
Every Coin price is a "nice" number (`economy_ev.nice`): below 10 exact, a mantissa of 10–30 in whole steps, 30–95 in steps of 5 (120, 2 900,
35 000, 750 M); the checks run on the rounded prices. The numbers themselves are in the configs; this is what explains them.

**Price tiers** (FL: net Coins per square-hour × the tier's factor; grow time is a choice inside a tier; away-time durations):

| Tier (× net / sq-h) | Crops |
|---|---|
| 0 (1) | Potato 20 s, Lettuce 1 m, Onion 2 m |
| 1 (1.73) | Garlic 6 m, Tomato 16 m, Cucumber 30 m |
| 2 (2.98) | Corn 15 m (quest), Pepper 2 h, Broccoli 8 h |
| 3 (4.47) | Pumpkin 12 h (quest), Eggplant 5 h, Blueberry 20 m |
| 4 (6.7) | Sweet potato 6 h (quest), Giant melon 14 h |
| 5 (10.1) | Sunflower 10 h, Pineapple 30 m |

Quests: Corn 6 Cucumber + 10 Garlic, Pumpkin 5 Pepper + 8 Corn, Sweet potato 5 Blueberry + 4 Eggplant (about one partial field each).

| Item | Now |
|---|---|
| Crops | 16 annuals on the tiers above, seed = 25 % of the sale, sale 9 (Potato) … 170 000 (Sunflower); `CropConfig.Crops` |
| Rare crops | one per world, obby only: Golden carrot 25 000, Frost grape 75 000, Glow mushroom 150 000 (hand-set, check R; Double Jump 2 takes 1 Frost grape) |
| Squares | 290 → 40 M (square 36), flat 40 M to 78 |
| Talents | ~3.4 M in all + crop bundles (`TalentConfig`; bundles kept small for G4) |
| Upgrades / tools / slots | `CropConfig.Upgrades` / `Tools` / `PetSlotPrices` (Growth 3 000 → 22 M, Barn 1 200 → 15 M, Sorter 10 000 → 45 M, Cloches 4 000 → 6 M, Shears 18 000 → 160 M, field pet 2 400 → 11 M); equip slots 700 / 4 000 (`PetConfig.SlotPrices`), incubators 500 / 2 800 (`GardenConfig.IncubatorPrices`) |
| Eggs | Pearl 120, Topaz 4 000, Ruby 450 000 (opens with Pumpkin), Diamond 3 000 000 (with Giant melon), rolled at purchase (`PetConfig.Eggs`) |
| Obby | repeat runs 0 Coins, Sunshine 16 / 24 / 32 s × 0.8^n; first clears: Tutorial 250 + 4 seeds (up to Garlic), Stages 1–5 600 / 800 / 1 000 / 1 250 / 1 500 + 4 seeds (up to Tomato). The seed pack is of an unlocked crop (a locked crop's seeds would skip its unlock), capped by crop |

**Upgrades.** Growth (−5 % of every grow time per level) and Barn (+20 capacity per level) stack with crop upgrades: the global ones are the
Coin sinks, crop upgrades the time sink. Ids are stored: never rename.
**Garden tools at F2.** Sorter (size factor), Cloches (online growth only), Shears (second crop chance): three levels each, Coins only.
**Field-pet re-run.** Field pet slots 2 400 / 14 000 / 220 000 / 11 M (slot 1 free); a profile from before the field converts once on join
(`PetSlotsFromPens`; extra pen Coins refunded in `GardenField`).
**Obby seeds run.** Rare seeds come only from the obby (`CropConfig.ObbySeeds`): a 300-point meter (Bronze / Silver / Gold 1 / 2 / 3), a daily
seed, a first-Gold bonus and the seed pouch; Scouting adds up to +50 %.

## Decisions
One or two lines per balancing pass: what was decided, why, and the numbers that are in the configs now. Seeds, sweeps and candidate tables
are history (`economy.py proposal` reproduces old → new tables).

**EV1 — engagement-first model.**
- Tending is growth speed (+50 % × strength on tended squares; a replant is worth nothing on a dense ladder). Guards make their squares safe
  and crows scale with the field; faster growth feeds crows, so B runs without crows.
- Late-game sinks must be dense: a reserved landmark / estate ladder (× 1.15) fills the gap until E6 / E7. Legendary scarcity needs an egg
  ladder (Ruby / Diamond, EG). The Spender needs offline 1.0 / 48 h and ~3 instant grows a day for 1.2–1.5× headroom.
- G7 passes only if every hatch and the first harvest of each crop kind count as "something new".
- **Rebirth:** none for launch (no queue runs dry within 60 days). If it empties later, a soft "Replant" (reset squares and Coins; keep pets,
  talents, obby progress, looks; reward a permanent verb or a small capped bonus) beats a Coin multiplier.

**User review of the EV proposal.**
- Sale = 4 × seed is one crop's margin, not the slope: net Coins per square-hour rise per tier. Flattening means a shorter time span, slower
  value steps or a slower square ladder (FL / FXP). Raising starter prices 5× = dividing obby Coins by 5; the early problem was the obby's
  one-time Coins (Tutorial ≈ 7 min of the Potato farm), resized in EV3.
- Old crops died at once and Renown rewarded spam-clicking Potatoes; kids did not know what Renown is: **Renown is out, per-crop mastery
  replaced it** (EV3). Sink gates never bound: **squares, upgrades, tools and field pet slots have no gate, Coins only** (user decision).

**EV3 — design (crop mastery; the draft and its revision).**
- Direction (user decision): not a quest per crop; each crop has its own level and upgrade points, shown on the crop ("Garlic ★2"). The next
  crop opens at a count of the previous one (the seed stall shows the bar); quests only at tier starts, no expiry, a seed pack as reward.
- Mastery counts plants, not crop XP (draft: XP = grow minutes, 15 stars): XP piled up on the overnight crop and quick crops never passed
  star 3. Level counts (25 / 75 / 200) and unlock counts (12 … 25, rising) stay separate: one count for both gave 5 crops in the first hour;
  a flat unlock count (15) brought the top crop on day 11–12 and emptied Garden main's shop.
- Point size +11 % per line: the draft's +10 / +10 / −6 % made a maxed crop ×3.7 per square-hour (~7 steps); the cap is "a maxed crop ≈ a
  fresh crop 2–3 old steps up, never the top one". Stacking (any line, up to 3; user decision) lets Speed on a short crop speed its own
  mastery: G9 (Casual's top crop day ~13.5) and G12 are accepted near-misses; the lever if it shows in play: a smaller Speed point or the top
  crops' `step`.
- The unlock chain needs a player who chases the bar (a maxed crop beats a fresh one 2–3 steps up). Quests are ~one partial field, planted
  at once. Not "price only" (every crop open from the start fails 5 of 18: price paces Coins, not attention) and not a total-XP gate.
- The first hour needs the request board (levels are rare news): it opens on day 0 once two crops qualify and a finished request counts as news.
- G4 (user: "fewer plants, easier to obtain"): smaller talent bundles (`TalentConfig`); obby-only Coins to World 2 = 37 % of the tree; a
  partial quest must not take a bundle's crops (it delayed Triple Jump by 5 days). Obby payouts (rule 6): first clears above, ≤ 2.7 min of
  farm income. G11 measures levels on crops ≥ 3 steps below the newest (the Renown model passed the old harvest-share form).
- Signed off (user): the tier table and prices, unlock counts, bundles, point size, the Sweet potato quest, rested rate; near-misses (R, G8,
  B2, G11 on single seeds) accepted for now.

**ST — rotating stall (user: decided in principle; numbers above).** The chain decides which crops exist, the stall which seeds are on sale:
`evcheck` 16–17 / 18 against the chain alone 13 (fails only R, B2, G8, G11); progress is slower (Casual's top crop day ~18 instead of 13), which
fixes G9 and mostly G12. **The newest crop must always be in stock** (else G7, G2, G12 fail). Rejected: a stall with no unlock chain (income
1/3–1/2 of the chain, bundle crops waiting on stock, a luck-set top crop). Trees carry the overnight hook.

**EG — Ruby 450 000, Diamond 3 000 000.** Ruby is the lowest nice price keeping Obby main ≥ 2 h of income on every seed (400 000: 1.9 h);
Diamond puts Casual's Legendary odds at 50 % on day 16–20 (G9 ≥ 14; 2 M gave day 14.3 and Obby main 2.4 h). G5 / B2 flip on the RNG path,
not the price.

**FL — flatter ladder.** The user's question: fewer inflating steps (~1.5× per crop, not 4×) and no 36–48 h crops. Built: the tier table above
(grow time a choice inside a tier, longest crop 14 h; tiers 0–2 unchanged because a lower step there broke G7, G4 and G10). Alongside: rare
sales × 0.5 (check R); more plants for levels 2–3 of quick crops (`LevelsBy`; Onion was maxed on day 2.7); **the stall always stocks the best
crop of ≥ 6 h** (G2 was the stall, not the ladder: 50–87 % → 96–99 %); Eggplant 5 h and Sweet potato 6 h so every schedule has a long crop.
Top crop on day 10–12 accepted (user; G9 from day 10). Income per day (seed 1): Casual 3.5 / 14 M on day 7 / 14, Garden main 12 / 16 M.
**G8 fails on every seed:** crops ≤ 16 h already fit one free absence, so paid offline speed is worth 1.0–1.2×; the comfort product (D2) needs
another form (a replant while away), not double speed. **UI rule:** the sale per harvest no longer rises with the unlock (Pineapple 8 500
after Pumpkin 90 000), so the seed stall shows each crop's net Coins per hour of one square (`field.seed.rate`).

**FXP — square prices on the flatter income.** FL halved late income but kept the squares' × 1.93 top (square 36 = 750 M; the 42 FX squares were
out of reach). Built: × 1.33 from the 29th square, 40 M at square 36, flat after: the doubled field is a ~3-month goal for Casual (square 36 on
day ~41, all 78 on day ~96), ~2 for Obby main (× 1.2 too cheap, × 1.5 left 43+ squares open on day 120). Casual's income ≈ 21 M a day on
day 30, 55 M on day 90. The other late sinks keep the EV2a ladder (Open decisions 3).

**FD — pet care.** User decisions: "Obby time is hard working. Staying with me is not."; a pet levels quickly to ~10 (food), the max takes
~90 days for a daily player. Built: time with you 0.75 XP per online minute (10× slower than designed), obby care XP × 0.04 past the food limit
(with whole obby XP Casual's Legendary maxed in 7–9 days; no time rate alone fixes that). Simulated Legendary 20: Casual 88.5 days, Obby main
29.5, Garden main 85, Binge not within 130. Food prices × 2.65^(b − 1) by the trait's base level and **× rarity** (user: "scale by rarity";
Legendary × 10, the rest × 1: a Legendary arrives day 3–41 and its bootstrap is 1–11 % of a day's income; the others arrive early, when Casual
is poorest). A fed crop's XP = its level-1 XP × the weakest food's XP per Coin at the pet's level ÷ the same at level 1 (÷ 2.65^(b − 1) broke
E1a3 by up to 3 %); a crop is refused (< 1 XP) from Potato Lv 5 … Blueberry Lv 17. The game does not show a pet's potential (its cap)
(user decision). A fresh Legendary at its food limit (+22.6 %) is weaker than an Epic at 18 (+25.2 %); accepted.

**EV2e — eggs at purchase.** The kind is rolled and stored at purchase, the rarity sets the hatch time (Common / Uncommon 5 m, Rare 1 h, Epic /
Legendary 4 h) and shared time tiers hide the exact rarity; cancelling an egg refunds nothing (ConfirmTap, orange then second tap); old eggs
keep their deadlines; the first free pet stays instant. The shared-tier forecast flags G7 (first-hour news gap) and G9 as approximations of
the instant first pet.

**TR4 — 2 × 2 trees** (the user, 2026-11-28: a tree takes 4 squares; the Apple is the cheapest tree, in the first third of the ladder).
Three Apple trees at Cucumber's tier hold 12 squares at a tier-1 rate for good: day-60 income −35 to −55 % and G2 / G4 / G9 / G11 fail;
two still cost ~30 % and fail G2 / G4 / G11. One Apple tree costs 10–25 % of the day-60 income (seeds 1–3, against no stall tree) and
passes what the 1 × 1 run passed except the RNG-path checks (G8, B, FD, G11 on one seed); without a stall tree G1 fails (p90 5.8 min).
A player can dig the tree up once better crops pay more (not modelled).

**TR5 — rare, single, uncapped saplings** (the user, 2026-11-28: saplings much rarer in the stall, one at a time, an expensive first
sapling is fine, no cap on trees). A sapling in ~14 % of hourly restocks, 1 per player, 9 000 each (Square 17's price; 2 800 in TR4).
The price and the rarity move the purchase from day 1.3–2.8 to 2.3–28 and cost nothing measurable (the checks flip on G1 / G2 / G11 at
the noise level across seeds 1–3, whatever the price from 2 800 to 21 000). The cap is the risk: the fruit stays at Cucumber's rate while
crops climb to 12 583 / sq-h, so every further Apple tree kept costs ~20 % of the day-60 income (2 trees −21 %, 4 trees −54 %, Casual);
the rarity and the price keep the count low, digging up frees the block. The user accepts that (2026-11-28): the Apple is the first,
expensive and possibly inefficient tree, 9 000 is about right, and later tree kinds carry the long-term gain.

**TR0 — fruit trees** (the rules above; EXPANSION §5.4). Until TR0 the model ran four placeholder trees (12 saplings) the game never had.
Without any tree (the game as built) the model fails G1 later in the game (p90 6–12 min between collects online) and G2 wobbles: the trees
carry the online cadence. The two TR trees bring the p90 back to 4–7 min and G2 to 87–99 %. A 10 h rare tree (a fruit every 2 h, 5 held)
failed G2 for Garden main on 2 of 4 seeds; 6 h passes. A 2 h stall tree (was 4 h) bears within an hour of play.

**OG2 / OG2b — crop timing** (section above). **E0 decisions still valid:** online beats offline; the field for everyone (FA); pet Cuteness
bonus saturates at 1.49 (pinned); crows start with the Garlic unlock, rare crops are safe.

## Constraints that must hold after every rebalance
- `python tools/economy.py check` runs; the only failures are the known G8 / G11 (and single-seed RNG near-misses). Pin only after review.
- No regret: prices never go down after launch; nothing sold is later handed out free in bulk; sinks are priced on the square ladder; every
  Coin number is a `nice()` integer < 2^53; stored Coins are never multiplied by hand (`Version = 3` already scaled them ×10).
- Repeat obby runs pay no Coins; first-clear Coins stay at starter size (G10); the obby is the only source of rare seeds.
- A fed crop's pet XP ≤ its sale × the weakest food's XP per Coin (E1a3, check 13); the size roll's mean factor stays 1 (check 12).
- Crop ids, tool / upgrade ids, field square numbers, egg ids and pet kinds are stored: never renamed or reused.
- New crops or eggs: price tier, unlock `step` / quest, stall behaviour, egg opening crop (EG) and talent bundles move together with `CAND`.

## Open decisions for the user
1. **G8 / the comfort shop (D2):** paid offline speed is worth 1.0–1.2× (target 1.2–1.5×) on the flatter ladder; needs another form of comfort
   product (a replant while away). Sunshine (EV2c) and Scouting (EV2d) are scoped when each starts.
2. **Real landmark / estate sinks (E6 / E7)** that replace the reserved × 1.15 ladder.
3. **Late sinks on the old ladder:** Growth 4, Sorter 3, Shears 3 keep the EV2a anchors; re-anchor if G8 or the Spender's late purchases need it.
4. **Endgame** (nothing needed now): drops (Weekly, Variants, Kitchen), a soft Replant if the queue empties, harvest boards.
5. **EV bands** stay provisional until the user confirms them; the single-seed near-misses (R, B, B2, G1, G3, G4, G5, G9) are accepted.
