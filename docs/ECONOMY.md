# Pawvest economy model — targets, decisions, how to run

Two models live in `tools/` (Python stdlib):
- **`economy_ev.py` (EV, the engagement-first economy, 2026-11-07):** the proposed numbers (`CAND`) and the checks they must pass (G1–G9,
  B, B2, C). The game does not run these numbers yet: EV2a–e apply them (ROADMAP → EV).
- **`economy.py` (E0):** reads every Coin number from the Luau configs, pins it (`tools/economy_pins.json`) and checks the game **as built**
  (parity targets, below). Its `check` also runs the EV checks; its parity / lead block goes when EV2a moves the configs onto the proposal,
  and the pins then hold the EV values.

History: the E0 run-by-run log is in `git show 87b1d3c:docs/ECONOMY.md`, the E0 version of this doc in `git show a128d26:docs/ECONOMY.md`.

## How to run

```
python tools/economy.py check                 # pins + E0 checks of the built game + the 12 EV checks, exit 1 on a failure (~1 min)
python tools/economy.py proposal              # EV: the old -> new table (crops, trees, sinks, talents, eggs, obby, archetypes) + EV checks
python tools/economy.py evcheck               # EV checks only (also: python tools/economy_ev.py evcheck)
python tools/economy.py hour1                 # EV: a fresh player's first hour (G7 numbers)
python tools/economy.py pin                   # accept the reviewed config values as the new pins
python tools/economy.py sim | report | pets | tools   # E0 tables of the built game
```

Run `check` after changing any price, rate or reward in a config; `pin` only after the user has reviewed the values. To try an EV number,
edit `CAND` in `economy_ev.py` (or pass overrides to a scratch probe that copies `CAND` and calls `build(c)`).

## EV — why and the pillars (the user, 2026-11-07)
The E0 targets kept field income near obby income (parity). That produced a 5-minute Potato worth 4 Coins, then a 6 h jump to Corn, talents
bought before World 2 ends without farming, and repeat runs paying tens of Coins next to a farm paying 100 k+. New direction: **engagement,
not income equality.** Farming is the core; the obby and coming mini-games are the distraction while things grow and the only source of rare
drops. Something is always growing, hatching or nearly affordable ("one more thing").

1. **A timer for every gap:** one ladder of grow / hatch times from 10 s to 24 h, each step ≤ ×3, so every session and absence has a crop.
2. **Online is busy, offline is a hook:** something to collect every few minutes online; a long crop / egg ripens near the return (offline
   rate 0.5, 24 h cap stay).
3. **The next goal is close, never already bought:** time-to-afford stays in a band; the player never holds enough to buy everything.
4. **Each new crop is worth unlocking:** net Coins per square-hour rises ×1.2 per step; the per-harvest number fits the prices of its time.
5. **The obby is the expedition:** one-time medal / first-clear Coins stay as starter capital; repeat runs pay **Sunshine**, rare seeds and
   pet XP, never Coins.
6. **Talents need the farm:** Coins + a crop bundle; the required levels also take a rare crop of the world before.
7. **Inflation is accepted** (genre norm): every sink is priced on the square ladder; numbers stay integers < 2^53.
8. **No regret (for M7):** after launch prices never go down; nothing sold is later handed out free in bulk; a capacity product never exceeds
   the earnable maximum. Free play is scarce enough that a comfort purchase is worth 1.2–1.5× (G8), never more.

## EV checks (`evcheck`; all 13 pass on `CAND` as of 2026-11-07; EV0 compares the configs, talent bundles included since EV2b)
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
| G7 first hour | first harvest ≤ 30 s, ≥ 6 crops in hour 1, longest wait for something new (level, crop, first harvest of a kind, purchase, hatch) ≤ 10 min, first square ≤ 15 min, first hatch ≤ 5 min |
| G8 Spender | headroom on Dash 2, Squares 20 / 28 / 36, Growth 4, Sorter 3: median 1.2–1.5×, max ≤ 1.6× |
| G9 scarcity | Casual: the expected Legendary count reaches 0.5 not before day 14; top crop day 14–28 (talent-first), ≥ 14 (pets-first); last tool ≥ day 14 |
| B | Tending pets earn more (guards and crows off in both runs) |
| B2 | one field slot as a guard instead of a tender earns at least as much (Casual) |
| C | sinks ≥ 60 % of the faucet by day 30, ≥ 78 % by day 60 |

## EV — the rules as simulated
- **Player:** sessions per archetype, the obby block in the middle of each session with garden checks every 5–10 min; between sessions the
  field grows at the offline rate (Spender: 1.0 for 48 h). In garden time the player reacts to every ripe batch, fruit and egg. Crop choice:
  best net Coins per wall-clock second until the next chance to harvest; bundle and request crops planted only when they ripen in time.
- **Shop:** one queue sorted by price × policy bias (talent-first: talents ×0.5, pets ×1.5; pets-first: pets ×0.6); unbuyable items are
  skipped, saving goes to a blocking required talent first; seed reserve kept; eggs and food from 8 / 2 % of income (pets-first 25 / 8 %).
- **Renown:** level L needs 0.4 × L³ points; a harvest gives 4 × minutes^0.5 points; crops unlock on a gate ladder (R0 … R68).
- **Squares:** 36, price 290 × 1.33^(j−5) up to square 16, then × 1.93 (1.33 × 1.45); every other sink is anchored on a square's price × a factor, so it
  arrives when that square does. Reserved sinks (landmarks, estate, decor; not designed): 70 steps × 1.15 from square 12's price.
- **Trees (model-only):** a sapling, first growth 2–24 h, then a fruit every 5–60 min up to a cap of 4–6 held, forever.
- **Eggs:** the pet is rolled at purchase; the hatch time is set by its rarity (Common 2 m, Uncommon 10 m, Rare 1 h, Epic 4 h, Legendary
  12 h). The player buys the dearest egg the egg fund covers. Two placeholder eggs (FutureEgg1 / 2) above Golden keep Legendaries scarce while
  income grows ~1000×.
- **Obby:** first clears and medals pay their one-time Coins; repeat medal finishes pay Sunshine (16 / 24 / 32 s per Bronze / Silver /
  Gold, × 0.8^n per stage and day, floor 6 s) into a store of up to 3 h; spending it is a **time skip**: the whole store at once, each growing
  square, tree and incubator advances by the full amount (not split; a square that needs less ripens and the rest is lost for it); rare-seed meter, daily
  seed and pouch (free seeds) stay.
- **Scouting:** XP = seconds of a running stage timer while equipped (level 2 after 45 min, × 2 per level); bonus min(0.5, 0.5 × strength)
  on Sunshine, meter and pouch.
- **Requests:** 3 a day, per-day RNG (UTC day + user); crops of the unlocked set (grow ≤ 4 h), sized to 30 % of a day's income, paying 1.75×
  the sale; on half of the days slot 3 is a timed run; one in three also drops Sunshine, a rare seed or an egg. **Streak:** Sunshine 10–30
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
| Eggs | Basic 500 / 5 m, Golden 4 000 / 1 h, rolled at hatch | Basic 120, Golden 4 000 (weights U500 R370 E127 L3; FutureEgg1 L 4 ‰ since Sunshine also speeds incubators), rolled at purchase, hatch by rarity |
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

## Open decisions for the user
1. The EV bands (table above) and the proposal itself: approved; EV2a (numbers) and EV2b (talent bundles) are built (2026-11-07); EV2e
   (eggs at purchase), EV2c (Sunshine), EV2d (Scouting) are scoped when each starts. EV2b retired E0's check 3 (the no-grind required set,
   garden off): talents need the farm by design, G4 replaces it.
2. Whether the placeholder eggs become real egg kinds (needed for Legendary scarcity past week 3).
3. The real landmark / estate sinks (E6 / E7) that replace the reserved ladder.

## E0 — checks of the game as built (until EV2a)
| Check | Rule |
|---|---|
| 1 drift | every config number equals its pin |
| 2 reproduction | the GDD figures (medal totals, talent tree, a day of Gold runs) |
| 3 required set | each required talent set ≤ 65 % of the Coins earned up to its stage, garden off |
| 4 P / L | field ≤ 1.0× obby Coins over days 1–3 (Garden main 1.8×); ≥ 3× by day 7, ≥ 10× by day 30 (Casual, Garden main); Obby main ≥ 1× by day 14 |
| 5 B, 6 C, O | Tending beats no Tending; sinks ≥ 60 % / 78 % by day 30 / 60; online income per hour ≥ 2× offline |
| 12, 13 | size roll mean 1 ± 0.005; crop XP ≤ sale × Berry's XP per Coin |

Still-valid E0 decisions: online beats offline (2026-10-24; offline 0.5, 24 h cap since 2026-11-04); the field for everyone (FA, 2026-11-06);
P4 pet traits (Cuteness bonus, saturating at 1.49; pinned 2026-11-05); crows from Renown 3, rare crops safe (2026-11-04).
