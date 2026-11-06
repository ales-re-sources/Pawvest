# Pawvest economy model (E0) — targets, decisions, how to run

`tools/economy.py` is one reproducible model of the Coin economy (Python stdlib). It reads every Coin number from the Luau configs and pins it
(`tools/economy_pins.json`: a changed config fails `check` until `pin`), adds the planned content no config holds yet (`PLANNED`, model
assumptions) and simulates 60 days of four player archetypes. Scope and open work: [ROADMAP.md](ROADMAP.md) → E0. The field as built: GDD §7.9.
Compacted 2026-11-05; the run-by-run history (candidate tables, sweeps, superseded rules) is in `git show 87b1d3c:docs/ECONOMY.md`.

## How to run

```
python tools/economy.py check                 # every pin + acceptance check (52), about 3 s, exit 1 on a failure
python tools/economy.py pin                   # accept the reviewed config values as the new pins
python tools/economy.py sim                   # 60-day simulation per archetype x policy, field tables, guardrail lines
python tools/economy.py report                # baseline tables (medals, talents, crops, tiers)
python tools/economy.py pets                  # field-pet run (slots, reach, Tending, aptitude pacing, pen conversion, seed pouch)
python tools/economy.py tools                 # garden tools run
python tools/economy.py check --offline-rate 0.5 --offline-cap 24     # try other passive rules
```

Run `check` after changing any price, rate or reward in a config, and `pin` only after the user has reviewed the new values. To try a number that
is not in a config yet, edit the `FIELD` / `CROP_DEFS` / `PLANNED` blocks in `tools/economy.py`. Optional crops (`--crops full`: Radish, Carrot,
a 2 x 2 Trophy pumpkin) stay model-only: they change income by less than 1 %.

## Targets the model checks (`check`)
Since the user's direction change (2026-11-02) **farming is the main game** and the obby supplements it. Measure: realised field net per day
(sales − seeds) against obby Coins per day (medals, repeat runs, first finishes).

| Check | Rule |
|---|---|
| 1 drift | every config number equals its pin |
| 2 reproduction | the GDD figures (medal totals, talent tree, a day of Gold runs) |
| 3 required set | GDD §6: each required talent set ≤ 65 % of the Coins earned up to its stage, garden income off |
| 4 P parity | the field earns ≤ 1.0x the obby's Coins over days 1-3 together (a total: first-clear payouts are too lumpy for a daily cap); Garden main ≤ 1.8x since the offline change |
| 4 L lead | field ≥ 3x the obby by day 7 and ≥ 10x by day 30 for Casual and Garden main; Obby main ≥ 1x by day 14; Binge reported only |
| 5 B | a field with Tending pets earns more than the same field without them (Binge within 3 %) |
| 6 C | sinks ≥ 60 % of the cumulative faucet by day 30 and ≥ 78 % by day 60 (with the reserved sink ladder, open decision 1) |
| O | garden income per online hour ≥ 1 / `offline_rate` × per offline hour, and offline income exists |
| 12 | size roll: mean factor 1 ± 0.005 with the cap, Big / Giant shares |
| 13 | crop XP ≤ sale × Berry's XP per Coin (feeding never beats selling and buying food) |

Not yet built (ROADMAP → E0): 7 no dead end, 8 rare supply vs the first landmark, 10 repricing bands, 11 sensitivity ±20 %. The old 24-hour rule
(A) and the Obby-main garden share cap (≤ 50 %) are only reported since 2026-11-02.

## The rules as simulated
- **Archetypes:** Obby main (2 h of obby, visits 7:00 / 12:30 / 18:00, 3.5 h online a day), Casual (45 min, 8:00 / 19:00, 1 h), Garden main
  (15 min, 7 / 12 / 17 / 21, 2 h), Binge (one 6 h day a week, 0.9 h a day); two purchase policies (talent-first, pets-first), 6 seeds each.
- **Online beats offline** (user rule 2026-10-24): every passive gain (crop growth, Tending, aptitude XP) runs at `online_rate` 1.0 while the
  player is in a session and `offline_rate` 0.5 while away, capped at 24 h per absence. Roblox no longer pays for
  uptime, so the model pays nothing for pure AFK: online growth counts only during session hours.
- **Visits:** at a session start the player harvests what is ripe, sells, buys seeds and replants the crop with the best net per square and
  wall-clock hour; ripe crops wait. Field items are bought in price order (× 1.5 for talent-first, × 0.7 for pets-first), the reserved sink ladder
  (landmarks, estate, decor, stations; 20 steps from 8 000 × 1.3^k, not designed) last.
- **Field:** the configs' crops, 36 squares opened in order of price, Renown gates, upgrades, tools, the market cart (bargains when buying those
  seeds anyway, the taste on active days), field pet slots. Tending reach is counted on the same centred grid as the game.
- **Field pets:** Tending strength = the chance a ripe crop is harvested and replanted at once (else it waits for the visit), only during
  absences; Tending rolled at hatch by rarity; aptitude levels from weighted field time up to the rarity cap.
- **Obby seeds:** the daily rare seed is the best world reached; first-Gold seeds from World 2; per-stage meters (300); the pouch gives seeds of
  the crop the player buys anyway; rare harvests are sold in full.
- **Crows:** the game's crow-block schedule; a ripe crop on a square during an absence overlapping a crow block is eaten with the chance, at most
  1 per absence, from Renown 3, rare crops safe. The model has no guards (the worst case).

## Decisions (dated; the numbers live in the configs)
- **2026-11-06 FA, the field for everyone:** the P2 pens and their production are gone (`GardenConfig` pen rates, offline cap, level
  rate); the model keeps only `CropConfig.LegacyPenPrices` for the one-time conversion. `pin` dropped `offline_cap_h`, `pen_level_rate`
  and `pen_rates` (the user accepted it); no other value changed.
- **2026-11-05 P4 pet traits** (reviewed and pinned): the Coin bonus is the **Cuteness** trait, levels 1-10; bonus = rarity
  base + `CuteStep` 19 ‰ per level above 1 (no migrated pet loses bonus), XP `100 × L^1.5` (11 100 to level 10, about today's ramp);
  `CuteChance` 0.35 / 0.4 / 0.5 / 0.6 / 0.7 by rarity after Tending gives Cuteness on 28 / 32 / 50 / 70 / 82 % of hatches (Tending shares
  unchanged); care XP trains work traits up to level 5 at 36 s per XP. The equipped
  multiplier saturates at 1.49 (was 1.47). Check C (Obby main's sink share by day 60) drops to 79 % (bar 80 %): the field earns about 5 %
  more; the user accepted it, the day-60 bar is now 78 %.
- **2026-10-24 Online beats offline** (above). **2026-11-04:** `offline_rate` 0.33 → 0.5 and the field cap 12 → 24 h (a day away grew only about
  4 h and the field felt unplayable); Garden main's parity relaxed to 1.8x (1.67x measured) and Binge's B to 3 % (1.7 % measured) with it.
- **2026-11-02 Field pets (E1b inputs):** Tending at level 10 = continuous cycling; aptitude level L → L + 1 in 10 × 1.56^(L−1) weighted field
  hours (a Common reaches its cap in about two weeks, level 10 takes 3-4 months); live pets roll aptitudes once from the uid at ceil(level / 4).
- **2026-11-02 Farming first** (the targets above). **2026-11-03 F1 / F2 decisions:**
  - Inflation accepted: crop prices and the field's own sinks rise (F2: × 9.3, ladder scale 2.8); a developed field pays about 200 000 a day.
  - Repeat obby runs stay as they are (the user: tens of Coins next to a first clear's 1 000+ feels right), so Casual's day-30 lead reaches 10x
    only with F2's gentler square gates and the 4th / 5th field pet slot.
  - 36 squares, any square opened by choice, the price by the number already open (1 400 → 907 400, 4.8 M in all).
  - Tools at the planned effect sizes (GDD §7.9), prices × 9.33, squares 7-11 one Renown level lower (Casual's day-7 lead was 2.93x).
  - Pens convert into field pet slots without a refund (slots are worth more than any pen set cost).
- **2026-11-03 Market cart:** bargains 10 @ −30 % and 5 @ −50 % (worth little: seeds are a quarter of the sale); the taste of 2 seeds from Renown 3
  at the catalogue price (earlier, one Giant melon is worth a day of early obby play and breaks parity).
- **2026-11-04 Obby seeds:** meter 300; no first-Gold seed for World 1 (a new player clears it in the first days and its seeds broke parity:
  1.33x Casual, 1.56x Garden main); rare harvests sold in full.
- **2026-11-04 Crows:** a quarter of the 6 h blocks, chance 0.3, cap 1 per absence, from Renown 3, rare crops safe (a rare crop is worth 13-22
  common ones; eating it would feel like theft of an obby reward). A cap above 1 hurt new players most (Casual's day-7 lead 2.4). Unguarded losses:
  1.6-2.1 % of field income from day 30, 3.8-9 % in week 1 (Binge 10.9 %).
- **2026-10-27 Talents** all affordable after World 2 without garden income (a replay from a reset profile bought every built talent with 1 163
  left); prices stay until Wall Jump / Glide are built. An unexplained ~11 000 Coins gap was the admin "+Coins" button: check for it first.

## Findings that still matter
- **Coins inflate about 40x** under F2: talents (44 300 in all), eggs, incubators, unlocks and food become cheap next to field income, and every
  archetype buys every talent. **Parked idea (the user, 2026-11-02):** buy talents with **stars** and let obby runs reward seeds instead of Coins;
  not decided (how it fits the later mini-games). Food was not scaled with F2 (for M6b).
- **Sinks:** under F2 the squares absorb most of the income; the reserved ladder still needs about 0.26 M Coins by day 60 for Obby main. Its real
  size comes with the landmarks / estate design (E6 / E7).
- **Tending's edge is thin for Binge:** one session a week leaves about one crop cycle either way, so a tender adds little; B holds within 3 %.
  Tending also only works during absences; whether it should work while the owner plays the obby is a telemetry question (E1b decision 2).
- **The early field is deliberately small** (parity); the day-7 lead is a ramp problem (early gates, first squares), not a price problem.
- **Biggest unknowns** are the visit schedules and learning speed of real players: M6a telemetry.

## Open decisions for the user
1. **Sink share:** keep 60 % by day 30 / 78 % by day 60 (80 % until P4) or lower it; it sizes the landmark / estate / decor sinks.
2. **Time-to-afford bands** for the repricing (E0b); not started.
3. **Placeholder sinks:** their size until E6 / E7 are designed.
4. **Stars for talents** (the parked idea above).
