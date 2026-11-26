# Pawvest — Roadmap

Status and order; "What next?" is answered from here. Design lives in [GDD.md](GDD.md) (the game as built), [STAGES.md](STAGES.md),
[EXPANSION.md](EXPANSION.md) (pet-garden direction, drops), [ECONOMY.md](ECONOMY.md) (numbers),
[PLANT_GROWTH.md](PLANT_GROWTH.md) (crop art, **per-crop status**), [HYBRIDS.md](HYBRIDS.md), [THUMBNAILS.md](THUMBNAILS.md). Old scopes and
validation logs are in git only: `git show 87b1d3c:docs/ROADMAP.md` (up to S8, E1), `git show 44431fe:docs/ROADMAP.md` (P4, U1–U5, FA, EV2, E0, CG).

## Workflow
Per AGENTS.md (design check → scope with hard acceptance checks → implement → Studio validation → status + commit). A design change found
while building goes docs → ROADMAP → code. Finished milestones shrink to one line in "Done"; as-built design goes to GDD / STAGES.
Status levels: **Implemented** (code in `src/`, committed), **Studio-validated** (every check passed in an MCP playtest), **Live-validated**
(checked on a published server with real DataStores; nothing is yet).

## Status

| # | Milestone | Impl. | Studio | Live |
|---|---|---|---|---|
| M0–M5, R | Foundations, medals, talents, economy, unlocks, challenge coins, boards | ✔ | ✔ | – |
| H1, H2, S1–S8 | Hub, stud checkpoints, stage framework, Quick Respawn, obstacle kit, Worlds 1–3 (15 stages), Triple Jump + Dash | ✔ | ✔ | – |
| P1–P4 | Pets, growth looks, pet page and names, traits (multi-client look open) | ✔ | ✔ | – |
| P2, E1.0–E1d, FA, FX | Pet garden, client-drawn plots, crop field (every player's), field pets, 8 plots × 78 squares | ✔ | ✔ | – |
| E2, E4-thin | Obby seeds, crows and Pest-control guards | ✔ | ✔ | – |
| T1a, T1b, L1–L3 | Telemetry; localization (English + Czech) | ✔ | ✔ | – |
| G1 | Player guidance hints (awaits the user's check in play) | ✔ | ✔ | – |
| U1–U5, MU1 | Garden / pet UI, responsive HUD (physical touch and multi-client open) | ✔ | ✔ | – |
| EV | Engagement-first economy: EV1 model, EV2a numbers, EV2b talent bundles, EV2e egg timing; EV2c, EV2d, EV2f after 1.0 | ✔ | ✔ | – |
| EV3 | Crop mastery (crop levels replace Renown, quests, crop upgrades, first-hour payouts) | ✔ | ✔ | – |
| OG, OG2, OG2b | Crop timing: offline ×1, online ×2, 24 h cap | ✔ | ✔ | – |
| ST, SH | Rotating seed stall; Harvest Hall and plot likes | ✔ | ✔ | – |
| FB, FB2, FB3 | Stage rating (signboards + popup), feedback box | ✔ | ✔ | filter check open |
| E5 | Request board, ledger on join, onboarding, garden telemetry | ✔ | ✔ | – |
| EG, FL, FD | Egg ladder (gems), flatter crop ladder, food trains a pet to half its max | ✔ | ✔ | – |
| CG1–CG21 | Plant growth art, 19 crops, all in the field ([per crop](PLANT_GROWTH.md#crops-and-status)) | ✔ | geometry + PlotView pass; stills of Tomato, Pepper, Pumpkin await review; phone performance and second client open | – |
| CP | Crop page redesign | ✔ | ✔ | – |
| HX0 | Hybrid plants: look prototype (Studio reviewer only) | ✔ | ✔ | – |
| HX1 | Hybrid breeding mechanic ([HYBRIDS.md](HYBRIDS.md)): main rules decided, numbers open | design only | – | – |
| K1 | First-hour fixes (kid playtest 2026-11-01): Stage 5, G1 fallback, Double Jump world reward, hatch panel done; the rest is measured in M6a | partial | partial | – |
| TH | Store thumbnails ([THUMBNAILS.md](THUMBNAILS.md) §8–9): logo, release candidates A1–A3, C1–C3; stud sign decision, grid tile test, kid test open | partial | – | – |
| M6a | Soft launch + World 1 balancing (balanced by feel 2026-10-30; live test open) | – | – | – |
| MU | Mobile UX check | – | – | – |
| S9, S10, M6b, S11, M7, trading | Wall Jump + Glide, World 4, final balancing, bonus stages, monetization, trading (after 1.0) | – | – | – |

## Next
**1.0 = a long engagement loop + basic social competition; then the game goes public** (decided 2026-11-17, the user). All of it is built
(EV3, ST, E5, SH, FB, EG, FL, FD). **Not in 1.0:** obby time calibration (M6b; the obby stays as built), the comfort shop (D2: 1.0 ships
without monetization), Sunshine (EV2c), World 4, the HX1 build.

**Start here:** the release gates below, MU first; alongside, the M6a friends test.
*Update this line whenever a milestone finishes.*

**Road to 1.0** (in order):
0. **Alongside, now: M6a soft launch** (friends, then unlisted; unlisted needs no TH) on the current build: real finish times, T1a / T1b on
   the Creator Dashboard, a first retention baseline, the live checks tagged [1.0] under "Open items".
1. **Release gates, then public:** MU (adds the Hall and a full field on a real phone), TH1 + THU, the Czech review of every new text, the M6a
   live checks, "Before Max Players 8" under "Open items", then Max Players → 8 (a place setting).

**After 1.0** (a drop every 1–2 weeks, EXPANSION §14; order provisional): D2 Comfort shop (M7) with EV2c Sunshine, then M6b obby time
calibration, D1 Critters, D3 Weekly, D4 Variants, D5 Kitchen, D6 Neighbours, D7 Pet depth, D8 World 4 (S9 / S10), D9 Estate, D10 Season 1;
EV2d, EV2f and the HX1 build when they fit. **Accepted risk until EV2c:** the Tutorial repeat loop pays ~1 400 Coins / h (watch it in M6a
telemetry).

**Alongside, any time:** plant growth art (open crops and checks: PLANT_GROWTH; review = five snapshots, no animation capture), HX1 (design
only), TH.

### K1 — First-hour fixes, open part (kid playtest 2026-11-01)
Target: a new player who does not pay always has a next step for the first hour; World 1 and the garden are tuned for 8–10 year olds on a
phone. Signs and banners are not read (GDD §11: "without reading anything").
- **World 2's star bar** stays at 10 of 15 until the wider test (user decision); a checkpoint inside Stage 5's tightrope: not now (telemetry first).
- **Key talents as world rewards:** Double Jump is World 2's reward (GDD §6). *Decided (the user, 2026-11-17):* World 3 gives no talent; Triple
  Jump, Dash and Long Dash stay bought (with crops), so from World 3 on the farm feeds the obby. Open (the user): whether Double Jump stops
  being World 2's reward.
- **Measure in M6a:** T1a fails per segment on Stage 5, quits per stage, session length of new players; whether the 20-level pet level-ups feel right.

### EV — Engagement-first economy, open parts
Rules and targets: ECONOMY.md → EV. Decided (the user, 2026-11-07): repeat obby runs pay **drops** (Sunshine, rare seeds) instead of Coins;
a 7-day streak with an Epic+ pet on day 7; perennials; free play scarce enough that comfort products are worth buying (headroom 1.2–1.5×);
Rebirth is evaluated by the model, not decided. Long term (recorded only): gifts, a pet auction, quests.
After 1.0, each scoped when it starts: **EV2c** Sunshine (repeat-run Coins → 0), **EV2d** Scouting XP (15 min of XP per medal finish against
10 h for level 2), **EV2f** field pets (Tending as growth speed, guards make their squares safe, crows scale with the field: a mechanics
change the model assumes). Open (the user, EV3): the quest's seed pack (4 seeds of the new crop, a first guess); the cart taste of a locked
crop stays (tasted plants count toward its ★ but do not unlock it); a "farm book" review of crops / barn / quests (timing open); no free
point reset (a paid comfort in D2 or an event item, EXPANSION §13).

### HX1 — Hybrid plants: the breeding mechanic (design only; the build comes after 1.0)
Notes, decisions and open points: HYBRIDS.md. **Decided (Ales, 2026-11-16):** price = measured kg × inherited value per kg; grow time from
plant mass; strains (not single fruits) are the unit of breeding; a hybrid can have two harvests or none; perennials; big plants take a 2×2
block. To settle: (1) numbers (mass → grow time, value-per-kg range and cap, cross cost, strain slots; check in `economy_ev.py`);
(2) rules for the second harvest and sterility; (3) perennial lifecycle and 2×2 field rules; (4) the term (hybrid / strain vs mutation) and
the EXPANSION §1.1 line. Prerequisites (HYBRIDS §8, none scoped): perennials on catalogue crops, bigger field and 2×2 blocks, plot-feed
codec, phone performance of plant art, catalogue UI at scale, crop definitions outside `CropConfig`, strain storage. Done when HYBRIDS.md
has no "Open" point that blocks a build scope and the build is cut into scoped milestones.

### TH — Store thumbnails ([THUMBNAILS.md](THUMBNAILS.md))
Three themes (Action, Pets on guard, Harvest) × three variants, a logo and an icon, built as Studio-only photo sets and tested in rounds with
Roblox thumbnail personalization. TH0 shared pieces → TH1 A3 + C1 + icon (grid tile test and kid test; theme B waits for D1) → THU upload,
round 1 → TH2 the other six → THR round 2; THD crow shots with D1. TH1 and THU before going public. State: THUMBNAILS.md §9.

### MU — Mobile UX check (scope when it starts)
Pawvest is **mobile-first** (decided 2026-10-24). A checklist on a real phone and the Studio device emulator, a 1.0 gate (before M7): touch
layout of every panel and popup at phone sizes, tap targets, safe areas, Czech text length, touch controls for the kit and talents (the Dash
button was never tried on a phone), performance on a mid-range phone (pets, a full garden, plant art; no number yet), the first minutes, the
T1a platform split; add the Hall, the rotating stall and the feedback box. Collected: the field's tap-select and two-tap pet drop on touch
(U3), whether squares are easy to hit from the default camera (decides the field camera button, GDD §7.10), hatchery pods, pet
picker and dialogs on a physical phone, the Goals line, the barn's crop rows in Czech (the ★ brick wraps the text column to 5 lines).

### Later milestones (scope when they start)
- **M6b — Final balancing:** measured `T_base` per stage from telemetry, tuned numbers in GDD and the configs; GDD §6 table still all ✔.
  Known items: the repeat-reward floor (until EV2c), pet bonus values, slot prices, rarity-based hatch time. Shared hatch tiers flag EV
  forecast G7 / G9 (ECONOMY → EV2e); review at balancing.
- **S9 / S10 — Wall Jump + Glide, World 4** (STAGES §8), drop D8; re-check World 4's star bar (World 3's tighter Silver / Gold make 10 of 15
  stars harder).
- **S11 — Bonus stages** (STAGES §5.3); the farm stages (EXPANSION §8.2) may use this slot.
- **Trading:** first profile session locking (`UpdateAsync` with a `{ JobId, Time }` lock), then an atomic two-sided swap with confirmation,
  immediate saves and a trade log (GDD §7.7). Open whether to do it at all (EXPANSION §16).
- **M7 — Monetization:** comfort only (no paid random items, luck and weather never sold; EXPANSION §13), drop D2.

## Open items from finished work
Tagged **[1.0]** (needed before going public) or **[later]**.
- **[1.0] For the live test (M6a):** several real players at once (others' plots, pets, coins; checkpoint pads only for their own player); two
  servers at once (boards, `MostStars`, the Harvest Hall, the stall draw); gate prompts on a locked stage; a real 1-hour Golden egg and the
  inventory cap with free eggs waiting; every telemetry event type on the Creator Dashboard (only then T1 is live-validated); a pet name the
  filter changes shows as `####` (Studio does not filter text); the checkpoint respawn fix, garden arrival and the OG2 / OG2b crop timers on
  the published game.
- **[1.0] Before Max Players 8 (FX):** Max Players → 8 in Game Settings (a place setting) and publish the reshaped island; 8 plots with full
  78-square fields at once (the budget was checked with synthetic plots only; plant art adds up to ~13 200 Parts per full field); a second
  client watching a square purchase; the Field test's step distances (PLANT_GROWTH) re-measured on the 8-plot ring.
- **[1.0] The user's checks:** G1 hints in play; a multi-client test (F7): each client sees the other's pets with their level look (P4 / U1),
  rings only over the own field and no selection on a neighbour's (U3); plot likes with two clients; the stills of Tomato (CG1e), Pepper, Pumpkin.
- **[1.0] Checked in code only** (check in the M6a playtests): the crow part of the summary bubble (`🐦 now` / `🐦 0:45`, U4); the first-harvest
  toast and the young-field pulse; the pet page's Feed card with held crops and its Czech width; E5's `request` funnel step, the ledger
  waiting for a run to end and its ribbons line, a Tending pet's join-settle harvests counting for a request; the level-up toast's point
  line (EV3c); look tiers at Lv 5 / 10 / 15 / 20.
- **[1.0] Localization:** Czech overflow screenshots of the panels (font BuilderSansBold: re-check widths in Czech and the pseudo-language),
  the Stage 9 exit-door label, the food stand's prompt ("Buy food" is a Studio literal: set its texts from `FoodShopClient` as
  `SeedStallClient` does), the pseudo-language pass on SH's texts.
- **[1.0] FB live check:** a feedback message with a name or a phone number is stored filtered (`PlayerFeedback`); `StageRating` / `Feedback`
  on the Creator Dashboard.
- **[1.0] E5 leftovers (not built):** one-time markers for the mastery ★, the stall rotation and the Hall.
- **[1.0] Not built:** the own shelf of record crops in their grown art (left SH: phone performance; revisit after MU). **FD:** the results
  popup's "Pets +N XP" shows the run's XP, not the × 0.04 a pet past its food limit gets.
- **[later] Not built:** the pet page's "hatched on … from a Basic egg" line (`Born` / `Egg`); "Show on field" on the pet page (U3b); a
  "barn full" cue in the world.
- **[1.0] Housekeeping (Studio):** delete `ReplicatedStorage.StageTimerStopped` (no script in `src/` uses it).

## Done
One line per milestone, newest first; the as-built design is in the doc named after "As built".

**CP — Crop page redesign** (2026-11-24): star track, icon-tile cards, stat tiles (new `Garden.Earned`, counted from now on). As built: GDD §7.9.

**FX / FXP — 8-player garden, double field** (2026-11-22): ring of 8 plots (radius 112), island 390 studs, 78 squares (37–78 a flat 40 M); `GardenConfig.StripFront`, `SignZ`. As built: GDD §7.6 / §7.9, ECONOMY → FXP.

**FD — food bootstraps, activity maxes** (2026-11-21): food trains only to half the rarity cap, past it Cuteness grows from obby XP × 0.04 and time with you. As built: GDD §7.4 / §7.9, ECONOMY → FD.

**FL — flatter crop ladder** (2026-11-21): a price tier sets Coins per square-hour, grow time a choice inside it, longest crop 14 h. As built: GDD §7.9, ECONOMY.

**EG — egg ladder** (2026-11-21): gem eggs Pearl, Topaz, Ruby (Pumpkin), Diamond (Giant melon), `eggLocked`, `SeenKinds` silhouettes. As built: GDD §7, ECONOMY → EG.

**OG / OG2 / OG2b — crop timers** (2026-11-20): offline ×1, online ×2, 24 h cap; base durations doubled to keep the pre-OG2 pace. As built: GDD §7.9, ECONOMY → Crop timing update.

**E5 — the online loop** (2026-11-20): three daily crop requests, "While you were away" ledger, first-ten-minutes onboarding, `GardenStart` funnel. As built: GDD §7.9 / §11, TELEMETRY.

**FB / FB2 / FB3 — player feedback** (2026-11-18 / 19): stage rating on courtyard `RatingSign`s and the popup row, feedback box; counts merged with `UpdateAsync`, no admin list (stores read via MCP / Open Cloud), no sign in the Tutorial. As built: GDD §10, LAYOUT.

**SH — Harvest Hall and plot likes** (2026-11-18): weekly and all-time top 3 per crop on two DataStore keys (`UpdateAsync` merge), ribbons, likes. As built: GDD §7.9.

**ST — rotating seed stall** (2026-11-18): hourly UTC restock, staples and newest crop always in stock, the market cart stays apart. As built: GDD §7.9, ECONOMY → ST.

**EV3 — crop mastery** (2026-11-14 → 17; replaces Renown): ★ at 25 / 75 / 200 plants, quests, rested mastery, first-clear payouts (`Version = 7`), tracker line and Goals panel, crop upgrade points (up to 3 per line). As built: GDD §7.9, ECONOMY → EV3.

**Hatch reveal, EV2e, hatchery and incubator polish** (2026-11-16 → 17): reveal with trait chips; pet fixed at purchase, shared rarity timers, cancel without refund; owned pods only, tap any pod. As built: GDD §7.2 / §7.6.

**HX0 — hybrid plants: look prototype** (2026-11-16): `PlantGenome`, `GenePlant`, reviewer; nothing saved. *Decided (Ales):* fully parametric, big plants take 2×2. As built: HYBRID_PROTOTYPE.md.

**Dialog / HUD polish, MU1** (2026-11-12 → 17): compact dialogs (44 px targets), textured headers, panels closed on join, responsive phone HUD. As built: GDD §7.9 / §11.

**Respawn fix, garden arrival, Home farm button** (2026-11-13 / 14): checkpoint restored after `LoadCharacter`; every join arrives at the own field (`GardenPlots.ArrivalCFrame`). As built: GDD §3 / §7.6.

**Pet levels 1..20** (2026-11-12): curves unchanged, profile `Version = 6` rescales pets once. As built: GDD §7.4 / §7.8.

**Barn stock display removed** (2026-11-12): no sacks / crates on the barn. As built: GDD §7.9.

**Plant reviewer, CG1–CG21 plant growth art** (2026-11-08 → 18): shared recipe dispatch, per-crop art designed with Ales, all 19 crops in the field. As built: PLANT_GROWTH → Crops and status.

**Playtest fixes** (2026-11-08): rare crops 50 000 / 150 000 / 300 000, Blink is Stage 4, selling from anywhere. As built: GDD §6 / §7.9.

**EV2a / EV2b / EV1 — engagement economy** (2026-11-07 / 08): `economy_ev.py` model, 10 s → 24 h crop ladder, talent bundles (Coins + crops, reject `crops`). As built: GDD §6 / §7.9, ECONOMY → EV.

**U1–U5 — garden and pet UI** (2026-11-06 / 07): pet rows, badge and bubble, field rings / square card / hand bar, panel split, plot layout, hatchery panel. As built: GDD §7.5–7.10.

**FA — the field for everyone** (2026-11-06): pens removed; a profile from before converts once on join. As built: GDD §7.9.

**P4 — pet traits** (2026-11-05): *Decided (user):* Cuteness is the Coin bonus (cap +50 %); every trait has its own level; look follows the highest (`Version = 4`). As built: GDD §7.4 / §7.8.

**Stud food stand, plot signs, stud conveyors** (2026-11-05): stud kiosk, hub-palette plot sign, `KitConveyorsClient`. Stud art style is final (user). As built: GDD §7.6, STAGES §2.5.

**E4-thin — crows and Pest-control guards** (2026-11-04): UTC crow blocks, a raid in the join settle (at most one crop), guards chase. As built: GDD §7.9, ECONOMY "Crow run".

**E2 — obby seeds** (2026-11-04): three rare crops, rare seeds for first World 2 / 3 Gold (earlier Golds give nothing, user), meters, pouch, Scouting. As built: GDD §7.9.

**E1a–E1d — crop field, field pets, size roll, tools, cart** (2026-10-30 → 11-04): plots drawn by clients from `GardenRemotes.Plot` (positions from `GardenConfig.PlotCFrame`), Tending pets work during absences, crops as pet food, lognormal size roll. *Decided (user):* farming is the main game. Rejected: separate garden islands (may return with the estate). As built: GDD §7.6 / §7.9.

**P3a / P3b — pet page and names** (2026-11-02): `PetDetail`; names filtered with `TextService`, `PetNames`. As built: GDD §7.8.

**K1 (part)** (2026-11-01): Stage 5 tightrope clearable without talents, G1 stuck fallback, Double Jump as World 2 reward. Open: "Next" → K1.

**G1 — guidance hints** (2026-10-27): arrow to the next stage, dots on Skills / ready eggs; display only. As built: GDD §11.

**S1–S8 — stages and worlds** (2026-10-21 → 28): framework (unlock by 10 of 15 stars or a price), Quick Respawn, obstacle kit (other clients see a rider ~0.2 s late: movers stay slow), Worlds 1–3 (World 3 signed off 2026-11-07), worlds hub, Triple Jump + Dash. As built: STAGES.

**L1–L3, T1a / T1b — localization, telemetry** (2026-10-23 / 24): English + Czech, `tools/loc.py`; one AnalyticsService user. As built: LOCALIZATION.md, TELEMETRY.md.

**E0 — economy model** (to 2026-11-07): `tools/economy.py` pins and simulation; repricing replaced by EV. As built: ECONOMY.md.

**H1, H2, P1, P2 — hub, checkpoints, pets, garden** (2026-10): stud hub joined to the garden by a bridge, per-player checkpoint glow, 8 pet kinds in 5 rarities (bonus cap +50 %). As built: GDD §3 / §7.

**M0–M5, R — foundations** (2026-10): `StageConfig` stubs, `PlayerProfiles`, medals, talents, `CoinRewards.Grant`, unlocks, challenge coins (ids never renamed), boards, Tutorial; `Version = 3` scaled Coins ×10. As built: GDD.

## Ideas (unscheduled)
- **Kind-pool eggs** (the user, 2026-11-20): an egg that hatches only a set of ~5 kinds, dearer eggs with rarer kinds. Needs many more
  than today's 8 kinds (2 / 2 / 2 / 1 / 1 by rarity) and fits with the pet catalog / field guide (EXPANSION §11, D7).
- **More UI sounds:** click, tab, field hover and toast notify are in (`UiSounds`, AmbientSorcery `ui-simple-*`). Same creator also has
  `-menu-open` / `-menu-close`, `-inventory-open` / `-close`, `-positive-confirmation`, `-negative-error`, `-reward-collect`, `-equip` /
  `-unequip` (search `ui-simple`, Audio, Creator Store): candidates for panel open / close, buy result, error toasts, pet equip.
- **Blink music:** a real track with its BPM instead of the metronome (S4).
