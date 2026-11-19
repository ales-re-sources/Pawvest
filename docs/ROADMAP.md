# Pawvest — Roadmap

Build order and status; "What next?" is answered from here. Design lives in [GDD.md](GDD.md) (the game as built), [STAGES.md](STAGES.md)
(stages), [EXPANSION.md](EXPANSION.md) (the pet-garden direction), [ECONOMY.md](ECONOMY.md) (numbers), [UI_GARDEN_PETS.md](UI_GARDEN_PETS.md)
(garden / pet UI), [PLANT_GROWTH.md](PLANT_GROWTH.md) (crop art and **per-crop status**), [HYBRIDS.md](HYBRIDS.md) (breeding) and
[THUMBNAILS.md](THUMBNAILS.md) (store art). Finished milestones keep only what was done and why; their scopes, acceptance checks and
validation logs are in git history: `git show 87b1d3c:docs/ROADMAP.md` (up to S8, E1), `git show 44431fe:docs/ROADMAP.md` (P4, U1–U5, FA,
EV2a / EV2b, E0 and the per-crop CG notes).

## Workflow
1. **Design check:** the milestone still matches the design docs; fix the docs first if not.
2. **Scope:** before coding, the milestone states inputs, outputs, boundary and **hard** acceptance checks (phrased so an empty or broken
   result fails: "second Gold finish pays 0", not "pays Coins").
3. **Implement:** code in `src/` (Argon); Studio-only changes (parts, GUI, RemoteEvents) are listed in the milestone, since git does not hold them.
4. **Studio validation:** an MCP playtest runs every check, through the real UI at least once (firing remotes alone once missed a broken
   button); no new console errors; live DataStores snapshotted and restored (AGENTS.md → Testing).
5. **Status + commit:** update the table, commit code and docs together; when a milestone is done, shrink it to a short entry in "Done"
   (as-built design to GDD / STAGES / the topic doc, open checks to "Open items").

A design change found while building goes docs → ROADMAP → code, in that order. One milestone at a time unless the order below says otherwise.

| Status level | Meaning |
|---|---|
| **Implemented** | code in `src/`, synced to Studio, committed |
| **Studio-validated** | every acceptance check passed in an MCP playtest |
| **Live-validated** | published and checked on a real server with real DataStores (nothing is yet) |

## Status

| # | Milestone | Impl. | Studio | Live |
|---|---|---|---|---|
| M0–M5, R | Foundations, medals, talents, economy, unlocks, challenge coins, boards | ✔ | ✔ | – |
| P1, P1e, P1g | Pets, growth visuals, stud restyle | ✔ | ✔ | – |
| P2 | Pet garden: plots, incubators, food (the pens were removed in FA) | ✔ | ✔ | – |
| P3a, P3b | Pet page, pet names | ✔ | ✔ | – |
| P4 | Pet traits: Cuteness carries the Coin bonus, per-trait levels, look from the highest trait | ✔ | ✔ (multi-client look open) | – |
| H1, H2 | Hub island, stud checkpoints | ✔ | ✔ | – |
| S1–S8 | Stage framework, Quick Respawn, obstacle kit, Worlds 1–3 (15 stages), worlds hub, Triple Jump + Dash | ✔ | ✔ | – |
| T1a, T1b | Telemetry | ✔ | ✔ | – |
| L1–L3 | Localization (English + Czech) | ✔ | ✔ | – |
| G1 | Player guidance hints (awaits the user's check in play) | ✔ | ✔ | – |
| K1 | First-hour fixes (kid playtest 2026-11-01): Stage 5, G1 fallback, Double Jump world reward, hatch panel done; the rest is measured in M6a | partial | partial | – |
| E0 | Economy model (its repricing replaced by EV) | ✔ | – | – |
| EV | Engagement-first economy: EV1 model, EV2a numbers, EV2b talent bundles | EV1–EV2b, EV2e ✔; EV2c, EV2d, EV2f after 1.0 | EV2a, EV2b ✔ | – |
| EV3 | Crop mastery: crop levels replace Renown, milestone quests, crop upgrades, first-hour obby payouts (1.0) | ✔ (EV3a signed off; EV3b1, EV3b2, EV3c Studio-validated 2026-11-17) | – | – |
| E1.0, E1a–E1d | Client-drawn plots; crop field (every player's since FA), field pets, crops as pet food, size roll, upgrades, tools, market cart, 36 squares | ✔ | ✔ | – |
| E2, E4-thin | Obby seeds (rare crops, meters, pouch, Scouting); crows and Pest-control guards | ✔ | ✔ | – |
| OG | Offline crop growth 0.5 / 24 h | ✔ | pending | – |
| FA | The field for everyone, pens removed | ✔ | ✔ | – |
| U1–U5 | Garden / pet UI: pets panel rows, garden badge + bubble, field rings / square card / hand bar, panel split (Skills Garden tab, Barn, seed stall), plot layout + hatchery panel | ✔ | ✔ (physical touch and multi-client open) | – |
| MU1 | Responsive HUD navigation and panels | ✔ | ✔ (phone emulation) | – |
| CG1–CG21 | Plant growth art, 19 crops ([status per crop](PLANT_GROWTH.md#crops-and-status)) | all 19 in the field (Sunflower registered in CG20c, 2026-11-18) | geometry + PlotView checks pass; stills of Tomato, Pepper, Pumpkin await review; performance, real phone and second client open for most | – |
| HX0 | Hybrid plants: look prototype (Studio reviewer only) | ✔ | ✔ (look approved 2026-11-16) | – |
| HX1 | Hybrid plants: breeding mechanic design ([HYBRIDS.md](HYBRIDS.md)) | main rules decided 2026-11-16; numbers and rules open | – | – |
| TH | Store thumbnails ([THUMBNAILS.md](THUMBNAILS.md) §8–9) | logo; release candidates A1, A2, A3, C1, C2, C3; B1 parked until D1 | stud sign decision, grid tile test, kid test open | – |
| ST | Rotating seed stall: slow UTC rotation, stock by mastery (1.0) | ✔ Studio-validated 2026-11-18 | – | – |
| SH | Harvest Hall (weekly biggest crop per kind) and plot likes (1.0) | ✔ | ✔ 2026-11-18 | – |
| FB | Player feedback: stage rating, feedback box (1.0) | ✔ | ✔ 2026-11-18 | filter check open |
| FB2 | Stage rating on a signboard in each stage's courtyard instead of the popup (1.0) | ✔ | ✔ 2026-11-18 | – |
| FB3 | The popup's 👍 / 👎 row back, alongside the signs (1.0) | ✔ | ✔ 2026-11-19 | – |
| E5 | Garden MVP rest: request board, ledger on join, onboarding, garden telemetry (1.0) | – | – | – |
| M6a | Soft launch + World 1 balancing (balanced by feel 2026-10-30; live test open) | – | – | – |
| MU | Mobile UX check | – | – | – |
| S9, S10 | Wall Jump + Glide, World 4 (drop D8) | – | – | – |
| M6b, S11, M7, trading | Final balancing, bonus stages, monetization (drop D2), trading (after 1.0) | – | – | – |

## Next
**1.0 (decided 2026-11-17, the user).** 1.0 = a long engagement loop + basic social competition; then the game goes public.
- **Long loop:** crop mastery (EV3), a slowly rotating seed stall (ST), the request board and the ledger (E5).
- **Social:** the Harvest Hall (weekly biggest crop of every kind) and likes on plots (SH).
- **Player feedback** to us: stage ratings and a feedback box (FB).
- **Not in 1.0:** obby time calibration (M6b; the obby stays as built), the comfort shop (D2: 1.0 ships without monetization),
  Sunshine (EV2c), World 4, hybrids (HX1 build).

**Start here:** E5 (scope it). (FB + FB2 Studio-validated 2026-11-18, FB3 2026-11-19, the live filter check open; SH Studio-validated 2026-11-18, likes in a two-client test; ST Studio-validated 2026-11-18; EV3 done 2026-11-17; open: the square card and the barn's crop rows in Czech, the Goals line on a real phone). Alongside: OG validation and the M6a friends test (step 0).
*Update this line whenever a milestone finishes.*

**Road to 1.0** (in order; one milestone at a time unless marked "alongside"):
0. **Alongside, now.** **OG validation:** a 24 h-back `SettledAt` must give `Grown` = 43 200 for a pumpkin (ripe at 28 800); the same
   test explains the user's pumpkin that still had 5 h 47 min left after 24 h away. **M6a soft launch** (friends, then unlisted) on the
   current build: real finish times, T1a / T1b on the Creator Dashboard, a first retention baseline and the live checks under "Open items"
   tagged [1.0]. Unlisted needs no TH.
1. **EV3 — crop mastery** (section below; player-facing name "Mastery ★"): sign-off → EV3b (levels, unlocks, Renown out) → EV3c (crop
   upgrade points). *State:* done: EV3a numbers signed off 2026-11-17 (mastery by plants grown, 3 levels, price tiers, smaller Double
   Jump 2 / Dash bundles); EV3b and EV3c built and Studio-validated 2026-11-17.
2. **ST — rotating seed stall:** done (Studio-validated 2026-11-18; Done).
3. **SH — Harvest Hall and plot likes:** done (Studio-validated 2026-11-18; Done).
4. **FB — player feedback:** done (Studio-validated 2026-11-18; Done).
5. **E5 — the online loop** (scope when it starts; EXPANSION §14): request board (rules: ECONOMY.md → EV "Requests": tracked "grow 6 Tomatoes",
   no hand-in and no accept step, an unfinished request stays, the board opens on day 0; decided 2026-11-17; shown as the Goals panel's
   *Today's requests* and the second tracker line, no board stand: UI_GARDEN_PETS §13), the ledger on join
   (the join notice grows into it), onboarding for the first ten minutes (teaches the U1–U5 controls, mastery, the stall, the Hall),
   garden funnel telemetry.
6. **Release gates, then public:** MU (section below; adds the Hall and a full field on a real phone), TH1 + THU, the Czech review of
   every new text, the M6a live checks, "Before Max Players 24" under "Open items", then Max Players → 24 (a place setting).

**After 1.0** (a drop every 1–2 weeks, EXPANSION §14; order provisional): D2 Comfort shop (M7) together with EV2c Sunshine, then M6b
obby time calibration, D1 Critters, D3 Weekly, D4 Variants, D5 Kitchen, D6 Neighbours, D7 Pet depth, D8 World 4 (S9 / S10), D9 Estate,
D10 Season 1; EV2d, EV2f and the HX1 build when they fit. **Accepted risk until EV2c:** the Tutorial repeat loop pays ~1 400 Coins / h
(watch it in M6a telemetry).

**Alongside, any time:** plant growth art (open crops and checks: [PLANT_GROWTH.md](PLANT_GROWTH.md#crops-and-status); review = five
snapshots, no animation capture), HX1 (design only), TH.

### K1 — First-hour fixes, open part (kid playtest 2026-11-01)
A 9-year-old on a phone, fresh progress, got stuck after about 20 minutes. Target: a new player who does not pay always has a next step for
the first hour; World 1 and the garden are tuned for 8–10 year olds on a phone. Seen: signs and banners are not read (the GDD §11 rule
"without reading anything" holds), too much text at hatching (fixed by U5b's egg cards and reveal), Coins spent elsewhere so World 2 stopped
him. Done: see "Done" → K1.
- **World 2's star bar** stays at 10 of 15 until the wider test (the user, 2026-11-01); a checkpoint inside Stage 5's tightrope: not now
  (telemetry first).
- **Key talents as world rewards:** done for Double Jump (GDD §6). *Decided (the user, 2026-11-17):* World 3 gives no talent; Triple Jump,
  Dash and Long Dash stay bought (with crops), so from World 3 on the farm feeds the obby. Open (the user): whether Double Jump stops being
  World 2's reward (it was the fix for the kid who quit at World 2, K1).
- **Measure it in M6a:** T1a fails per segment on Stage 5, quits per stage, session length of new players; whether the faster first pet
  level-ups (20 levels since 2026-11-12) feel right.

### EV — Engagement-first economy, open parts
Rules and targets: [ECONOMY.md](ECONOMY.md) → EV. **Decided (the user, 2026-11-07):** talents cost Coins + a crop bundle (built, EV2b); a
crop ladder from ~10 s to 24 h (built, EV2a); repeat obby runs pay **drops** (Sunshine, rare seeds) instead of Coins; eggs are **rolled at
purchase** and the rarity sets the hatch time; a semi-random request board (crops and sometimes a timed run); a 7-day streak with an Epic+
pet on day 7; perennials; free play scarce enough that comfort products are worth buying (headroom 1.2–1.5×). Rebirth is evaluated by the
model, not decided. Long term (recorded only): gifts / buying for a friend, a pet auction, quests.

Still to build after 1.0, each scoped when it starts: **EV2c** Sunshine (repeat-run Coins → 0), **EV2d** Scouting XP (today 15 min of XP per medal
finish against 10 h for level 2), **EV2f** field pets (Tending as growth speed, guards make their squares
safe, crows scale with the field: a mechanics change the model assumes). Trees, requests and the streak come with E5 / the drops.

### EV3 — Crop mastery replaces Renown; milestone quests; crop upgrades; first-hour obby payouts (revised 2026-11-17; EV3a signed off)
Why, direction and rules: [ECONOMY.md](ECONOMY.md) → "EV3 — design draft" and its revision (2026-11-17); findings and what was signed off:
ECONOMY.md → Findings (EV3a, EV3 revision) and open decision 4. *Revision (the user, 2026-11-17):* mastery = plants grown of that crop,
3 levels at 25 / 75 / 200 plants for every crop (one upgrade point each, one per line: a ★3 crop is fully upgraded); the next crop opens
at 12–25 plants of the previous one; 16 crops in 6 price tiers, the third quest on Sweet potato,
quests handed in piece by piece without expiry, rested mastery after a day away (silent: never shown to the player).

**EV3a — model (no game code).** Built 2026-11-14, revised 2026-11-17: `economy_ev.py` `CAND` carries the revision (`tier_of`,
`mastery: "count"`, `m_levels`, `quest_partial`, `req_auto`, `rest_per_day`, smaller Double Jump 2 / Dash bundles for G4; the draft via
`--set`, seeds via `--seed`); `evcheck` 12–15 / 18 on seeds 1–4 (EV0 fails until EV3b; G4 passes on 3 of 4); `economy.py proposal`
prints the EV3 tables. **Signed off (the user, 2026-11-17):** tier prices, unlock counts, talent bundles, point size, quests, the
silent rested rate, obby payouts; the near-misses are accepted for now (ECONOMY.md → open decision 4).

**EV3b — levels, unlocks, Renown out (scoped 2026-11-17).** Fixes the first hour. Two parts, each shippable: **EV3b1** the mechanic
(data, server, configs, migration, the existing panels) and **EV3b2** the tracker line and the Goals panel (UI_GARDEN_PETS §13). Numbers:
`economy_ev.CAND` (signed off 2026-11-17); `economy.py proposal` prints them.
*Live profiles (read 2026-11-17, one playtest):* 4 records. Lekzdrh Renown level 29 (Potato … Blueberry by gate; Sweet potato grown from a
cart taste), AhojRupert level 5 (Potato … Cucumber), test records `user_-1` / `user_-2` (to remove). No per-crop history exists
(`Field.Plantings` is one field total), so plant counts start at 0.

**EV3b1 — the mechanic**
1. **Config.** `CropConfig.Crops`: the tier prices (`sale` / `seed`: Lettuce 28 / 7, Onion 55 / 14, Tomato 750 / 190, Cucumber 1 400 /
   350, Pepper 10 000 / 2 500, Broccoli 20 000 / 5 000, Eggplant 70 000 / 18 000, Blueberry 100 000 / 25 000, Giant melon 350 000 /
   90 000, Sunflower 900 000 / 220 000; the rest unchanged); `renown` and `points` go; new `step` = plants of this crop that open the next
   one (12, 13, 13, 14, 15, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25 in list order; also the rested unit); `quest` on Corn
   `{ Cucumber = 6, Garlic = 10 }`, Pumpkin `{ Pepper = 5, Corn = 8 }`, Sweet potato `{ Blueberry = 5, Eggplant = 4 }` (a quest crop
   opens by its quest, not by the previous crop's `step`). The unlock order is the list order of the common crops; rare crops have no
   mastery. `CropConfig.Mastery = { Levels = { 25, 75, 200 }, RestPerDay = 0.5, RestCap = 3, QuestSeeds = 4 }` with helpers
   (`MasteryLevel(n)`, `NextLocked(unlocked)`, `UnlockNeed(crop)`). `renown` goes from `Expansions`, `Upgrades`, `Tools` (prices stay);
   `RenownK` / `RenownP` / `PointsFor` / `RenownLevel` move into a `CropConfig.Legacy` block used only by the migration. `Crows.FromLevel`
   → `FromCrop = "Garlic"`, `Cart.taste.fromLevel` → `fromCrop = "Garlic"`; `CartOffers(day, unlocked)` (bargains on unlocked crops, the
   taste = the next locked crop). `TalentConfig`: Double Jump 2 10 000 + 12 Cucumber + 1 Frost grape, Dash 1 8 000 + 12 Corn, Dash 2
   19 000 + 12 Pepper + 1 Glow mushroom. `StageConfig`: Tutorial and Stage 1–5 get `firstClear = { coins, seeds = 4, upTo }` (250 /
   600 / 800 / 1 000 / 1 250 / 1 500 Coins for the first finish + its medals together; `upTo` Garlic for the Tutorial, Tomato for World 1);
   `rewardFactor` and repeat runs unchanged (EV2c).
2. **Server (GardenField, StageResults).** Profile: `Garden.Crops[cropId] = { N }` (plants grown; a table so EV3c adds `Pts`),
   `Garden.Unlocked = { [cropId] = true }`, `Garden.Quest = { Crop, Got = { [cropId] = n } }` (the open milestone), `Garden.Rested`
   (number, in `step`s). A harvest (by hand or a Tending pet; not the Shears' extra crop, not a rare crop) adds 1 to `N`, +1 more while
   `Rested` lasts (`Rested -= 1 / step`); reaching the previous crop's `step` unlocks the next crop; a quest crop opens `Garden.Quest`
   instead. Harvest answer `{ …, mastery = { crop, n, level }, levelUp?, unlocked? }`. New remote `GardenRemotes.Quest(cropId, count)`
   (hand in `count` of `cropId` toward the open quest, accepted anywhere; takes at most what the quest still needs; rejects `none` /
   `crop` / `crops`, nothing taken); the last piece unlocks the crop and gives `QuestSeeds` seeds of it (past the barn limit, as rare
   seeds). On join, before settling: an absence over a day adds `(away − 1 day) / day × RestPerDay` to `Rested` (cap `RestCap`; from
   `Field.SettledAt`). **Rested is silent**: never in the state, a toast or a text. `BuySeeds` checks `Unlocked` (reject `locked`);
   `BuySquare` / `BuyUpgrade` / `BuyTool` lose the `renown` check; crows and the cart taste from the Garlic unlock. First clears: Coins
   per `firstClear`, and `GardenField.ObbyFinish` (first finish) adds 4 seeds of the newest unlocked common crop up to `upTo`. Telemetry:
   `crop_unlock` (crop, how: count / quest / migration) and `crop_level` (crop, level).
3. **Migration** (`PlayerProfile` `Version = 7`). `Unlocked` = every common crop whose old gate ≤ the profile's Renown level (EV2a curve),
   plus every crop the profile holds or has grown (`Seeds`, `Items`, `BestSize`); a quest whose crop is already unlocked is done; `Crops`
   = {}; `Rested` = 0; `Renown` stays, unused. Lekzdrh → Potato … Blueberry + Sweet potato (next: Giant melon at 22 Sweet potatoes);
   AhojRupert → Potato … Cucumber (next: the Corn quest).
4. **Client.** Seed stall: a ★ on each unlocked row; the next locked crop shows "🥔 8 / 12" or its quest pieces `{crop} {have}/{need}` with
   a **Bring** button per crop (the player chooses what to hand in); further locked crops grey without a number. Square card and barn row:
   the crop's ★; the square card's price line without Renown. Toasts: "Garlic ★2", "Lettuce unlocked!", a quest piece. Skills panel Garden
   tab: the Renown header goes, rows show only the price. Barn's young-field sell hint: until Corn is unlocked (was Renown 5). Crow line:
   "crows come after Garlic". (FieldHand, FieldClient, BarnClient, GardenSkills, SeedStallClient, GardenUi.)
5. **Tools.** `economy.py`'s config reader and EV0 read the new fields (crops with `step` / `quest`, sinks without gates, `firstClear`,
   talents); `evcheck` EV0 passes; `pin`.
6. **Docs and text.** GDD §7.9 (Renown → mastery), PROTOCOL (remote, profile v7, Harvest answer), TELEMETRY (two events), ECONOMY
   (EV0 note), strings: the 15 `renown` / gate keys reworded or removed, new ones with Czech.
- **Acceptance (EV3b1):**
  - `economy.py check` exit 0 with EV0 PASS (after `pin`, drift 0); `loc.py build` / `check` (0 errors) / `lint` (within the baseline);
    `grep -ri renown src/` only in `PlayerProfile`'s migration and `CropConfig.Legacy`; no `renown` key in `strings.csv`.
  - One playtest boot without errors or warnings (server and client).
  - Studio, on a fresh fixture profile (snapshot first, restored after): Lettuce opens at the 12th Potato (toast), Potato ★1 at the 25th;
    a locked crop's seeds refused (`locked`); the Corn quest handed in through the real seed stall in two visits with a rejoin between
    (progress kept), one refusal for missing crops (barn unchanged), the last piece opens Corn and gives 4 Corn seeds; a square, a Growth
    level and a Cloches level bought on Coins alone; the Tutorial's first finish pays 250 Coins with its medals and 4 seeds of the
    newest crop up to Garlic.
  - Rested: a fixture with `SettledAt` 3 days back → `Rested` = 1.0 after the join; the next 12 Potato harvests add 2 each, then 1; no
    text about it anywhere.
  - Migration: Lekzdrh's live profile (snapshot first) migrates on join to the set above, Seeds / Items / Coins unchanged; AhojRupert's
    path reviewed in code (same rule; no fixture).
  - Triple Jump in the skills panel costs 10 000 + 12 Cucumber + 1 Frost grape.
  - Pseudo-language and Czech pass: no "Renown" on screen; Czech fits on the stall row with Bring buttons and on the square card.
  - The test records `user_-1` / `user_-2` removed.

**EV3b2 — tracker line and Goals panel:** done 2026-11-17 (Done; the scope: `git show 5778797:docs/ROADMAP.md`).
- **Open (the user):** the quest's seed pack (4 seeds of the new crop, a first guess like the first clears' packs); the cart taste of a
  locked crop stays until ST decides the cart (tasted plants count toward that crop's ★ but do not unlock it).

**EV3c — crop upgrades:** done 2026-11-17 (Done; the scope: `git show d7a25a3:docs/ROADMAP.md`). Decided with it: points stack, up to 3 in
one line (changed the same day); no free reset (later a paid comfort in D2 or an event item: EXPANSION §13); no collection total (with a
"farm book" review of crops / barn / quests: proposed 2026-11-17, timing open).

**Not in EV3:** repeat-run Coins → Sunshine (EV2c); requests and trees (the online loop, E5); a flatter price curve (ECONOMY.md → open
decision 5).

### ST — Rotating seed stall
Done 2026-11-18 (Done; the scope: `git show df15e8f:docs/ROADMAP.md`). Decided with it: the numbers (hourly, staples Potato–Onion,
chance 0.5, pity 3, 12 seeds, the newest crop always; the user, 2026-11-18); the market cart stays apart; the restock note is a garden
toast, not a HudPopup.

### SH — Harvest Hall and plot likes
Done 2026-11-18 (Done; the scope, design check and validation log: `git show 2367d6f:docs/ROADMAP.md`; as built: GDD §7.9). Decided with
it: two plain DataStore keys with `UpdateAsync` merges instead of ordered stores; all-time top 3 per crop; the toast only for a new weekly
#1 that is Big or Giant (one per server per 60 s); a ribbon for each week's #1; the Hall on the hub plaza's west half; a like gives the
owner a live toast (no join-notice line); the own record shelf left SH (Open items → Not built).

### FB — Player feedback
Done 2026-11-18 (Done; the scope, acceptance checks and validation log: `git show 3d247a8:docs/ROADMAP.md`; as built: GDD §10). Decided
with it: one feedback panel from a Settings row; per-stage counts as one `UpdateAsync`-merged key; `studio_` keys in Studio; no admin
list (we read the stores through the MCP / Open Cloud).

### FB2 — Rating signboard
Done 2026-11-18 (Done; the scope, acceptance checks and validation log: `git show 0b9c8bd:docs/ROADMAP.md`; as built: GDD §10, LAYOUT →
Stage anatomy `RatingSign`). Decided with it (the user): a post sign in view on landing, no score shown to players, no sign for the
Tutorial; anyone may rate, the progress sent along filters out who never tried.

### FB3 — Rating on the results popup too
Done 2026-11-19 (Done; the scope, acceptance checks and validation log: `git show 02e767e:docs/ROADMAP.md`; as built: GDD §10).

### HX1 — Hybrid plants: the breeding mechanic (design only; added 2026-11-16; the build comes after 1.0)
Settle the game mechanic before any game code. Notes, decisions and open points: [HYBRIDS.md](HYBRIDS.md); the HX0 prototype: "Done".
**Decided (Ales, 2026-11-16):** price = measured kg × inherited value per kg; grow time from plant mass; strains (not single
fruits) are the unit of breeding; a hybrid can have two harvests or none; perennials; big plants take a 2×2 block. Still to settle:
1. Numbers: mass → grow time, value-per-kg range and its cap over generations, cost of a cross, strain slots (§5, §6);
   checked in `economy_ev.py`.
2. Rules for the second harvest and for sterility (§3).
3. Perennial lifecycle and 2×2 field rules (§7): how a cross gets its footprint, planting / pet reach / square card on a block, the
   economy of four squares.
4. The term (hybrid / strain vs mutation) and the EXPANSION §1.1 line.

**Prerequisites (HYBRIDS §8, proposed, none scoped):** perennial lifecycle on catalogue crops; bigger field and 2×2 blocks;
plot-feed codec; EV3 signed off and built; phone performance of plant art; catalogue UI at scale. Hybrid-specific: crop
definitions outside `CropConfig`, strain storage, the generator to production, strain icons and names.

Done when HYBRIDS.md has no "Open" point that blocks a build scope, and the prerequisites and the build are cut into
scoped milestones.

### TH — Store thumbnails ([THUMBNAILS.md](THUMBNAILS.md))
Three themes (Action, Pets on guard, Harvest) × three variants, a logo and an icon, built as Studio-only photo sets and tested in rounds with
Roblox thumbnail personalization. TH0 shared pieces → TH1 A3 + C1 + icon (grid tile test and kid test; theme B waits for D1) → THU upload,
round 1 → TH2 the other six → THR round 2; THD crow shots with D1. TH1 and THU before going public. What exists (release candidates, drafts,
photo-set scripts): THUMBNAILS.md §9.

### MU — Mobile UX check (scope when it starts)
Pawvest is **mobile-first** (decided 2026-10-24). A checklist on a real phone and the Studio device emulator, before anything goes public and
before M7 (a 1.0 gate; add the Harvest Hall, the rotating stall and the feedback box to the list): touch layout of every panel and popup at phone sizes, tap targets, safe areas, Czech text length, touch controls for the kit and
talents (the Dash button was never tried on a phone), performance on a mid-range phone (pets, a full garden, the plant art; no phone number
yet), the first minutes, the T1a platform split. Collected from finished work: the field's tap-select and two-tap pet drop on touch (U3),
whether squares are easy to hit from the default camera (decides the field camera button, UI_GARDEN_PETS §12.4), the hatchery, pet picker
and dialogs on a physical phone.

### Later milestones (scope when they start)
- **M6b — Final balancing:** measured `T_base` per stage from telemetry, tuned numbers in GDD and the configs; GDD §6 table still all ✔. Known
  items: the repeat-reward floor (a Tutorial loop pays ~1 400 Coins / h, until EV2c), pet bonus values, slot prices, rarity-based hatch
  time, food prices against field income. Shared hatch tiers flag EV forecast G7 / G9 (ECONOMY → EV2e); review at balancing.
- **S9 / S10 — Wall Jump + Glide, World 4** (STAGES §8), drop D8; re-check World 4's star bar (World 3's tighter Silver / Gold make 10 of 15
  stars harder).
- **S11 — Bonus stages** (STAGES §5.3); the farm stages (EXPANSION §8.2) may use this slot.
- **Trading:** first profile session locking (`UpdateAsync` with a `{ JobId, Time }` lock); then an atomic two-sided swap with confirmation,
  immediate saves and a trade log (GDD §7.7). Open whether to do it at all (EXPANSION §16).
- **M7 — Monetization:** comfort only (no paid random items, luck and weather never sold; EXPANSION §13), drop D2.

## Open items from finished work
Tagged **[1.0]** (needed before 1.0 goes public) or **[later]**.
- **[1.0] For the live test (M6a):** several real players at once (others' plots, pets, coins; checkpoint pads only for their own player); two servers
  at once (boards, `MostStars` and, once built, the Harvest Hall); gate prompts on a locked stage; a real 1-hour Golden egg and the inventory cap with free eggs waiting; every
  telemetry event type on the Creator Dashboard (only then T1 is live-validated); a pet name the filter changes shows as `####` (Studio does
  not filter text); the checkpoint respawn fix (2026-11-14) and garden arrival on the published game.
- **[1.0] Before Max Players 24 (going public):** 24 plots with fields at once (the budget was checked with synthetic plots only; the plant art
  adds up to 6 084 Parts per full field); a second client watching a square purchase.
- **[1.0] The user's checks:** G1 hints in play; a multi-client test (F7): each client sees the other's pets with their level look (P4 / U1), rings
  only over the own field and no selection on a neighbour's (U3); the stills of Tomato (CG1e), Pepper and Pumpkin.
- **[1.0] Checked in code only** (check in the M6a playtests): the crow part of the summary bubble (`🐦 now` / `🐦 0:45`, U4); the first-harvest toast and the young-field pulse
  (playtest fixes 2026-11-08); the pet page's Feed card with held crops and its Czech width (20 levels, 2026-11-12).
- **[1.0] Localization:** Czech overflow screenshots of the panels (the font is BuilderSansBold, so re-check widths in Czech and the
  pseudo-language), the Stage 9 exit-door label, the food stand's prompt ("Buy food" is a Studio literal: set its texts from
  `FoodShopClient` as `SeedStallClient` does); the pseudo-language pass on SH's texts (Hall plaque, label, record board, toast, like
  prompt, sign line).
- **[1.0] FB live check:** a feedback message with a name or a phone number is stored filtered (`PlayerFeedback`; Studio does not
  filter text); `StageRating` / `Feedback` on the Creator Dashboard.
- **[1.0] Not built:** the own shelf of record crops in their grown art (moved out of SH 2026-11-18: phone performance; revisit after MU).
- **[later] Not built:** the pet page's "hatched on … from a Basic egg" line (`Born` / `Egg`); "Show on field" on the pet page (U3b); a
  "barn full" cue in the world.
- **[1.0] Housekeeping (Studio):** delete `ReplicatedStorage.StageTimerStopped` (unused).

## Done
What was built and why, newest first. Details: the design docs and git history.

**FB3 — rating on the popup too** (2026-11-19; Studio-validated through the real popup button, profile snapshot restored). *Why:*
the user wants finishers asked right away; the signs stay for the rest. *What:* GDD §10; the popup's 👍 / 👎 row back on world
stages, showing the sign's vote (attribute `StageRatings`); `Rate` also within `FeedbackConfig.PopupSeconds` (120 s) of a finish
(`StageResults.FinishedWithin`).

**FB2 — rating signboard** (2026-11-18; Studio-validated through the real prompts, profile snapshot restored). *Why:* the popup
row was gone after 7 s and reached only finishers. *What:* GDD §10 (Stage rating); a `RatingSign` in each world stage's courtyard
(template `ServerStorage.StageKit.RatingSign`, tag `RatingSign`), `RatingSigns.client`, `Rate` checks the sign distance instead of a
finish, profile `StageRatings[key] = { R, F }`, attribute `StageRatings`, counts `up` / `down` / `upUnfinished` / `downUnfinished`,
`Telemetry.StageProgress` in `StageRating` CF02; the popup row removed.

**FB — player feedback** (2026-11-18; Studio-validated through the real UI with Lekzdrh's profile snapshot, restored). *Why:* we need to
hear the players; kids rarely write reviews. *What:* GDD §10 (Player feedback); `FeedbackConfig`, `FeedbackService` (`FeedbackRemotes`
`Rate` / `Send` / `Result`; DataStores `StageRatings` key `counts`, `PlayerFeedback` keys `<time>_<UserId>`), profile `StageRatings` /
`FeedbackToday`, the popup's 👍 / 👎 row, `FeedbackClient` (Settings row + panel), `Telemetry.AreaOf`, telemetry `StageRating` /
`Feedback`.

**SH — Harvest Hall and plot likes** (2026-11-18; Studio-validated on test keys with Lekzdrh's profile snapshot, restored, and in a
two-client F7 test). *Why:* players should feel competition, not play alone. *What:* GDD §7.9 (Harvest Hall, plot likes); `HallConfig`,
`HarvestHall` service (DataStore `HarvestHall`, keys `week_<n>` / `alltime`), `HallClient`, `GardenLikes` (`Like` / `Liked`), profile
`Garden.WeekBest` / `Ribbons` / `Likes` / `Liked`, plot state `likes` / `ribbons`, telemetry `HallEntry` / `PlotLike`; scene
`Workspace.StartLocation.HarvestHall` (19 pedestals, record board; the star board moved beside it).

**ST — rotating seed stall** (2026-11-18; Studio-validated on Lekzdrh's live profile and a fixture, restored). *Why:* planting was too
linear; a stall that does not offer everything makes the player plant what is there, gives online news and slows the mid game (model:
16 / 16 / 16 / 17 of 18 on seeds 1–4, the chain alone 13; ECONOMY.md → Findings "ST"). *What:* GDD §7.9 (rotating stock);
`CropConfig.Stall` / `StallStock` / `StallAlways` / `StallRotating`, profile `Garden.Stall`, state `stall`, BuySeeds `stock` / `soldOut`
(PROTOCOL); the stall rows ("N left this hour", "Back soon", "New seeds in"), the restock toast; `economy.py` reads `Stall`, EV0 compares
it with `st_*`. Checked: server and client draw the same stock for the block; over 200 hours every crop is out at most 2 hours in a row
(in stock 67 %); through the stall's buttons Tomato +1, +10 → "1 left" and +10 became +1 → bought out, "Back soon"; `soldOut` and `stock`
take nothing (Coins and seeds unchanged); Potato and the newest crop (Sweet potato) buy without a count; on a fixture (Sweet potato's quest
open, Jump Height 1, last hour's counts) Cucumber (the talent's next level) 22, Eggplant and Blueberry (the quest) 13 each, Pepper reset
to 12 and bought out; the real restock at 19:00 UTC (block 498619) arrived without a rejoin: the countdown restarted at 59:23, Garlic came back with 12 and the sold-out Pepper reset to 12; the restock toast (blocks sent to the client by hand) shows at the stall, not at the hub and not when nothing rotated in (the first cut tested the area by the character's ancestry, which never is Workspace.Garden: now the distance from the garden centre); Czech and the pseudo-language fit (no literals); no errors. Not checked: two live servers side by side
(the draw is a pure function of the block, checked in two contexts).

**EV3c stacking — any line, up to 3** (2026-11-17; the user's change after EV3c). *Why:* the player chooses a build (all Speed on a quick
crop, all Price on an overnight one) instead of only an order. *What:* `Mastery.Points.PerLine` 3, `Pts[line]` = 0–3, additive
multipliers, Big / Giant labels from the roll without Size points, the crop page's dots and "now → one more point", `CropPoint` telemetry
value = the line's points; model `pt_cap` 3 / `pt_total` 3 / policy "auto", U takes the best and the worst allocation, EV0 compares
`PerLine` (ECONOMY.md → Stacking: G9 / G12 near-misses accepted). Checked on a fixture of Lekzdrh's profile (restored): three Price
points on a ★3 Cucumber through the page's + → ●●○ "Sells for 1 708 → 1 862", then ●●● ✓ 1 862, the other lines without +, "Fully
upgraded!", toast with the dots; a 4th Price `maxed`, Size `points`; Potato Speed 1 → 2, a 3rd `points`; the Czech page (dots, grey +);
labels: 1.25 with 3 Size points none, 1.66 Big, 2.10 Giant; junk points clean to 0–3; no errors. Not checked: a real harvest toast with
Size points (code and the label function only).

**EV3c — crop upgrades** (2026-11-17; Studio-validated on a fixture of Lekzdrh's profile, restored). *Why:* the endgame layer of crop
mastery: every ★ gives a point for the crop's Price, Size or Speed line, so old crops stay worth growing (ECONOMY.md → EV3). *What:* GDD
§7.9 (crop upgrades); `GardenRemotes.CropPoint`, profile `Crops[id].Pts`, state `mastery.points` (PROTOCOL); the crop page
(`CropPageClient`) from ★ bricks on the stall and barn rows and the Goals panel's *Upgrades*; telemetry `CropPoint`; the plant look capped
at the old size maximum; `economy.py` pins the point sizes, EV0 compares them. Checked (Czech): Value through the barn's page → Sell
10 185 → 11 305 and a real sale paid it; Speed through the stall's page while a Cucumber grew → its rate × 1 / 0.89 and an earlier
`readyAt`; Size through the Goals panel → the next Potato's factor = roll × Sorter × 1.11 (state and harvest alike); a third + refused
(`points`, Coins unchanged), a repeated line `maxed`, a rare crop `crop`; points kept over a rejoin; *Upgrades* gone after the last
point; the X returns to the panel the page came from. Not checked: the level-up toast's point line (in code); the barn's crop rows are
narrow with the ★ brick (the Czech text column wraps to 5 lines: readable, to look at on a phone).

**EV3b2 — tracker line and Goals panel** (2026-11-17; Studio-validated on fixtures of Lekzdrh's profile, restored). *Why:* the next
unlock and the milestone quests need a "what next" outside the seed stall, and the brown score panel had nothing to say off a stage
(UI_GARDEN_PETS §13). *What:* GDD §7.9 (tracker line, Goals panel); the score panel only on a stage (`HudStage`, PROTOCOL); the hub /
world star count and three `hud.score.*` keys gone; the quest rows shared (`GardenUi.QuestRows`). Checked: the line followed Lettuce
harvests (0 → 2 / 13) and moved on after the Lettuce and Corn unlocks, the Corn quest handed in through the panel 96 studs from the stall,
the run view unchanged on Stage 1, Czech fits at a 496 × 319 viewport. Not checked: the touch HUD on a real phone (the desktop HUD's
icon row covers the line in a very small window, as it did the score panel).

**Hatch reveal** (2026-11-17; Studio-validated with Hatch answers sent to the client, no real hatch). *Why:* the reveal was a static
page and its trait chips explained nothing. *What:* `HatchReveal` (GDD §7 hatchery): egg wobble with a rarity-colour hint, burst, pet pop
with rays / rarity stamp / confetti from Rare, sounds; then a summary (egg's chance of the rarity, where it went, pet count, one row per
trait with level / cap and what it does) and View pet / Great!. The Hatch answer carries `egg`. Fixed on the way: the pet page opened
through `PetsGui.OpenPet` from a closed panel drew its trait cards too short.

**Seed stall button height fix** (2026-11-17; UI Studio-validated). Restored the missing `TapHeight()` binding so cart, seed-buy and
crop-sell bricks keep their 44 px touch targets after panel scaling. Transaction completion not revalidated (MCP snapshot access refused).

**HX0 — Hybrid plants: look prototype** (2026-11-16; as built: [HYBRID_PROTOTYPE.md](HYBRID_PROTOTYPE.md); design: [HYBRIDS.md](HYBRIDS.md)). *Why:* the user's breeding idea (cross two plants into
one that mixes both, crafted mutagens bias a trait, unique to its breeder, visible to visitors) needs generated plants that look good before
any mechanic. *What:* `PlantGenome` (genome v2: 49 genes, cross, mutagens, 49-byte pack, presets for the 19 crops and 8 new plant types),
`GenePlant` (a `Draft` `PlantKit.recipe` from a genome), the reviewer's `OpenCross` / `OpenPresets`; nothing is saved, sent or in the field.
Studio checks: 347 genomes, 122 of them 2×2 (≤ 140 / 400 Parts, 2.38 / 5.13 radius), seeks, proxies; stills in
[art/plant-review/hx0](art/plant-review/hx0). *Decided (Ales):* go, fully parametric (no organ library for now); trees and other big plants
take a 2×2 block, its footprint from the blended `bulk` gene. Next: HX1.

**EV2e — Egg timing and cancellation** (2026-11-17; GDD §7.2, §7.6). Implemented and desktop Studio-validated: pet fixed at
purchase / free placement, shared rarity timers (Common / Uncommon 5 m, Rare 1 h, Epic / Legendary 4 h); pet hidden until hatch,
Square trash uses ConfirmTap (orange OK? → second tap, discard without refund); aligned odds rows and short egg info tips. Existing eggs keep their deadlines; first free pet stays instant. Physical touch and
live validation remain open.

**Incubator arch body** (2026-11-17; GDD §7.6). Desktop Studio-validated: the rear heater and side tiers no longer float;
side walls step up to a headboard and a cream / steel arch over the egg's back half carries the plate (user picked C Arch of
three options). Full / mid / low body Parts 59 / 13 / 8; scan ring and hearts clear the body; physical touch / live open.

**Incubator scan and warmth** (2026-11-17; GDD §7.2, §7.6). Desktop Studio-validated: first 30 s of the existing timer
scan with a cyan contour ring (rises / falls on the egg, circling head and trail) and Scanning… label; then a soft pulsing amber nest glow / countdown with ember heater / heat lamp, rising sparks and brick hearts; ready stays green. Offline /
rejoin uses stored anchors; instant-ready eggs skip scanning. Full / mid / low body Parts 44 / 8 / 3; physical touch / live open.

**Incubator number plates / foundation** (2026-11-17; GDD §7.6). Desktop Studio-validated: two-sided rear plates carry numbers
at full / mid detail; floating labels show status only. Foundation edge beams use the pavilion's Plastic / Inlets.

**Owned incubators only** (2026-11-17; GDD §7.6). Desktop Studio-validated: unpurchased pods are absent at all details;
unclaimed plots have none. Unlock remains in the hatchery panel; successful purchases add their pod immediately.

**Hatchery access** (2026-11-17; GDD §7.6). Desktop Studio-validated: Hatchery HUD beside Barn with a ready-egg badge;
click/tap any owned pod from either side, including empty pods, with whole-pod hover. Hatchery E prompt removed.
Passive GUI and range guards tested; physical phone touch remains open.

**Hatchery redesign** (2026-11-16; GDD §7.6). Cross-lapped stud egg shells and 3D egg cards, stud-textured foundations, a tall pavilion with
a front prompt, a passive dialog cursor with world-input guards, owner-only nest labels fading at 24–30 studs. Studio-validated; physical
phone touch open. Open hatch pod body selected and Studio-validated: stepped cheeks, rear heater, front / side controls; amber while growing, green when ready; 17 / 6 / 3 body Parts. Pods and eggs turned towards the central path (Studio-checked 2026-11-17). [Archived redesign notes](INCUBATOR_REDESIGN.md).

**Garden UI follow-ups** (2026-11-14 / 15; [UI_GARDEN_PETS.md §5.1](UI_GARDEN_PETS.md#51-soil-card-and-pet-placement--decided-2026-11-14),
GDD §11). Soil card and pet placement clarity, group boxes in the card, Barn and Hatchery, Take off field; blank card / hand UI blocks field
selection and hover (click-through fix); garden panel input guards; live safe-area refit. Studio-validated on desktop and the Czech phone
layout; physical touch open.

**Compact skill purchases** (2026-11-16; GDD §11). Obby / Garden skill buttons target 40 px with shallow lips; symmetric Obby row padding
fixes their vertical centring. Studio-validated: all ten button centres, desktop / landscape phone scaling, English/Czech including two-line
Coin/crop prices, real MAX and first-tap confirm controls, clean client/server logs. No profile fixtures or changed Czech texts.

**Compact dialog chrome** (2026-11-16; GDD §11). On-screen 40 px titles and square X/back controls, 36 px Skills / Seed stall tabs and pet
filters, 40 px Barn HUD button, shallower brick lips and reclaimed content space. Studio-validated: desktop + landscape phone emulator,
real tabs/filters/open/close/back, English/Czech foreground TextFits and two square-stud rows, clean game logs. Original pet loadout
restored after a misdirected test click. Physical phone remains open; no changed Czech texts.

**Pet picker compact rows** (2026-11-16; GDD §7.9). Wider picker, bordered whole-pet rows and right-side Place pet buttons; narrow layouts stack
the action and use one scrolling body. Studio-validated: real open/back/place, English/Czech TextFits, emulated phone swipe and desktop reflow,
clean server/client logs. Placement profile snapshot restored and verified. Physical phone remains open; no changed Czech texts.

**Textured dialog headers** (2026-11-16; GDD §11). Shared dialog title strips reuse the world stud texture as a faint flat pattern;
titles draw above it and keep following localization / layout. The texture fits two complete square-stud rows at any header height
(50 / 80 px and UIScale checked; 2026-11-16). Studio-validated: Pets, Settings and the field square in English/Czech,
foreground TextFits, smooth borders and no square-card scrollbar regression, clean server/client logs. No changed Czech texts.

**Field square dialog** (2026-11-16; GDD §7.9). Fixed the subpixel height mismatch that showed a scrollbar on short content;
added the shared colored header with a fixed close button and renamed the title from "This spot" to "Field square" (Czech: "Políčko").
Studio-validated: empty and growing squares without residents, Czech TextFits, real seed/pet picker and close buttons, locked square,
real scrolling with overflowing display content and a fixed header, clean server/client logs.

**Smooth UI borders** (2026-11-16; GDD §11). Removed top-edge studs from shared buttons, dialog title strips and HUD plates.
Studio-validated: fresh boot, Settings / Pets / Barn visual review, 108 styled buttons with no top-edge stud frames, clean server/client logs.

**HUD panels closed on join** (2026-11-16; GDD §11). Skills, Settings and Admin now start closed independently of authored visibility;
the session's panel choice still survives respawns. Studio-only: `StarterGui.ScreenGui.SkillsPanel.Visible = false` prevents a startup flash.
Studio-validated: fresh boot closed, real Skills open/close, respawns with Skills open and closed, Settings → Admin switching, clean server/client logs.
Plant growth remains intentionally Studio-only (PLANT_GROWTH.md). Publishing and live confirmation remain open; no changed Czech texts.

**Checkpoint respawn timing fix** (2026-11-14; GDD §3, STAGES §6.2.1). Removed the early `CharacterAdded` placement race:
`RespawnService` restores the checkpoint after `LoadCharacter` returns. Studio-validated: garden join, real touches and
deaths at all nine Stage 2 pads, Stage 1 regression, walking onto a Stage 2 laser and retaining the timer, clean server /
client logs and localization checks. No profile fixtures or changed Czech texts. The reported published-game failure
did not reproduce before the fix; publishing and live confirmation remain open.

**Garden arrival on every join** (2026-11-13; GDD §7.6). New and returning players start in front of their own field,
facing it, at the same destination as Home (shared GardenPlots.ArrivalCFrame). Later deaths keep their checkpoint / respawn
behavior. Studio-validated: two joins, matching Home arrival, camera facing, Stage1 checkpoint death / respawn, clean logs and
localization checks; no profile fixture or changed Czech texts. Live validation open. Scope / acceptance / validation:
`git show 9a0a4ac:docs/ROADMAP.md`.

**Home farm and Gateway navigation** (2026-11-13; GDD §7.6, §11). The leftmost house goes to the own farm and carries
its ripe-crop / ready-egg badge. The adjacent blue brick with a 🌀 emoji keeps the old Home return
(stage plaza → Central Island); the separate Garden button is gone. Studio-validated: desktop clicks, both timer cancellations,
8-item badge matching the plot feed, respawn, iPhone 13 landscape layout, clean logs and localization checks. Real-phone touch
remains with MU (MCP clicks did not activate under touch emulation); no new Czech texts or profile fixtures. Scope / acceptance /
validation record: `git show 39afdc8:docs/ROADMAP.md`. Follow-up: the custom outlined portal is replaced by the chosen 🌀 emoji in the standard circular
socket, matching the other navigation glyphs. Fresh Studio boot, screenshot, Gateway click and clean client / server
logs checked; localization checks pass, with no new or changed Czech texts.

**MU1 responsive HUD navigation** (2026-11-13; GDD §11). Desktop row; phones get a two-column block, landscape panels beside it
and portrait panels replacing it until closed. Skills / Pets reflow on rotation, close targets stay 44 px, the pet trait menu
scrolls within the panel and the Barn shortcut hides behind panel focus. Studio-validated with native UI clicks, iPhone 7 / 13
emulation in both orientations, Czech fit, respawn and clean logs. No new Czech strings or profile fixtures. Real-phone feel
remains with MU. Scope / acceptance / validation record: `git show bf22ffc:docs/ROADMAP.md`.

**Pet page without the growth card, 20 pet levels** (2026-11-12; GDD §7.4, §7.8). The pet page lost its top Growth card (level bar, "trained" line, next look): the trait cards come first, the Feed card below them (it carries the "what trains now" line). Pet and trait levels run 1..20 instead of 1..10: the curves stay written on the 10-level scale and `PetConfig` splits every step (`BaseLevel`, `ToLevel`; level 1 stays 1, L → 2L), so XP totals, caps, strengths, reach and the Coin bonus at even levels are unchanged and `economy.py check` stays valid (it reads `BaseMaxLevel`). Profile `Version = 6` rescales every pet once (`RescaleAptitudes`). Studio-validated on the developer's profile (Dragon Cuteness 9 → 18, Owl 8 → 16; snapshot `profile_9892673032_petlevels20_1`, the migrated profile was kept). Open: the Feed card with held crops and a Czech-width check of the page were not looked at; look tiers at Lv 5 / 10 / 15 / 20; the first level-up now comes after a third of the old XP (Cuteness 33 XP, Tending 3.3 field hours), so the early game feels faster: check it in the next retention look.

**Barn stock display removed** (2026-11-12; GDD §7.9, [UI_GARDEN_PETS.md](UI_GARDEN_PETS.md) §6). The barn building keeps its walls,
roof, empty shelves and "Open barn" prompt; the U5a seed sacks and crop crates are gone (`PlotView:SetBarn`, GardenView's `barnFill`).
They repeated the barn panel less exactly, only the owner saw them, and the colour-topped crates clashed with the crop growth art.
Open: a "barn full" cue in the world, and a public shelf of record crops in their grown art (Estate / decor drop).

**Admin plant review shortcut** (2026-11-10; [guide](PLANT_GROWTH.md#studio-growth-player)). Studio admins can open the reviewer
and expanded crop picker from Admin → Plant growth. Named `Open(cropId, seconds)` stays direct; hidden HUD clicks preserve
the Admin panel for return on Close. Real UI open/select/close/reopen and Czech/pseudo Glyph fit pass; no saved-state writes.

**Plant reviewer crop picker** (2026-11-10; [guide](PLANT_GROWTH.md#studio-growth-player)). The shared Studio review UI now
switches between catalogue crops with plant recipes, including unregistered art, while preserving review settings and playback.
`Open(cropId, seconds)` remains compatible; `Open()` supplies a default. Real clicks checked nine recipes, all view modes,
scroll/dismissal, cleanup and HUD/camera restoration; Czech names fit and refresh. No saved-state or production UI changes.

**CG1–CG21 — Plant growth art** (2026-11-08 → 11-14; [PLANT_GROWTH.md](PLANT_GROWTH.md), `docs/plants/`). Shared recipe dispatch and
timing (CG2), seeded individuality and harvested size (CG4), and per-crop growth art designed with Ales from references (static studies →
a choice → five stills → recipe → field registration). All 19 crops grow in the field (Sunflower registered last, CG20c 2026-11-18). Decisions,
budgets and open checks per crop: PLANT_GROWTH.md → Crops and status. Tomato became the tall staked classic (CG1e, 2026-11-09; variants
after GA); fruit-only perennial gameplay is separate future work (HX1).

**CG6 — Corn growth art** (2026-11-09; [design](plants/CORN.md)). Tall two-ear Corn now grows continuously in the field, with seeded
variation, visible harvest mass and cheaper distant art. Studio lifecycle/detail and desktop CPU checks pass. Ales confirmed both
real-phone and second-client validation on 2026-11-09; CG6a–d are complete.

**Playtest fixes 2026-11-08** (ECONOMY.md, GDD §6, §7.9, STAGES §2). *Why:* a tester's first Golden carrot paid 350 000; the second Stage 2 lava looked like the lethal one; Blink was harder than the stage after it; the skill's crop price was unreadable and detached from its button; nobody found where to sell crops. *What:* rare crops 50 000 / 150 000 / 300 000 with fewer Renown points, model check R, Double Jump 2 takes 1 Frost grape; `Lava block` retiled as hot coals; bounce corridors are Stage 3 and Blink Stage 4 (folders, coin ids, boards cleared); the buy button shows 💰 and the crops with have/need; selling from anywhere, Barn button outside runs, the seed stall's Sell tab, a first-harvest toast. Studio-validated (controls through the real UI, boot clean); the toast and the pulse (young fields only) were reviewed in code, not seen.

**EV2b — Talent bundles** (2026-11-08; GDD §6). Each bought talent level costs Coins **and** crops from the barn, taken together on the
server (`GardenField.TakeCrops`, all or nothing, reject `crops`); bought levels stay, world rewards stay free; the Skills panel shows
`{crop} have/need`. Retired E0's no-grind check 3 (EV's G4 replaces it). Studio-validated (the user tested the purchases).

**EV2a — Engagement numbers** (2026-11-07 / 08; GDD §7.9, ECONOMY.md → EV). The configs moved onto `economy_ev.CAND`: a 10 s → 24 h crop
ladder (the 4 crops re-timed, 12 new crops), Renown per harvest 4 × √minutes with a one-time level keep, "nice" prices for squares,
upgrades, tools, slots, eggs and incubators, client-predicted ripeness for short crops, `Locale.Compact` for big numbers. Studio-validated
2026-11-08 (boot, Renown migration, a 10 s Potato, a square and the Barn bought, seed stall and Skills panel in Czech).

**U5 — Plot layout and hatchery panel** (2026-11-07; UI_GARDEN_PETS §6–7, GDD §7.6). *Why:* the three incubators across the front strip hid
the field, and hatching showed too much text for kids (K1). *What:* hatchery left, barn right, a path to the field (client-drawn, no protocol
change); one hatchery prompt and panel with nest rows, egg cards (odds behind "?") and a pet reveal with the trait chips one by one. The
barn's sacks and crates went again 2026-11-12. Studio-validated.

**U4 — Garden panel split** (2026-11-07; UI_GARDEN_PETS §6, §10). *Why:* one panel held everything, most of it far from where it is used.
*What:* upgrades and tools in a Skills → Garden tab and the field pet slot line in the Pets panel (both bought anywhere); a seed stall on the
plaza with the cart's offers on its board (seeds bought only there; Studio-only `Workspace.Garden.SeedStall`); a Barn panel (Sell, Feed)
behind the bottom-centre 🧺 button (the user chose the HUD button over an early barn building); the crow forecast in the barn and the
bubble; `ConfirmTap` (two taps over 1 000 Coins) and `PanelFocus` (one panel at a time, closes on walking away). The Garden panel is gone.
Studio-validated.

**U3 — Field interaction** (2026-11-07; UI_GARDEN_PETS §3–5, GDD §7.9). *Why:* square prompts at a 5.5-stud pitch competed, and a kid could
not see what grew. *What:* progress rings over planted squares; tap-select with a square card holding every action (the square prompts
went); overgrown locked squares; field pet labels with job icons; the hand bar (Seeds / Basket / Pets / Look) for repeated taps, lifting a
pet with its reach following the pointer, reach borders in rarity colours, next-step pulses, corner brackets on the square under the
pointer. No harvest-all or drag-to-harvest (the paid Wheelbarrow, D2). No remote change; field remotes go through one 0.25 s queue.
Studio-validated on desktop.

**EV1 — Engagement-first model** (2026-11-07; ECONOMY.md → EV). *Why:* E0's income-parity targets left a 5 min → 6 h gap in the crop
ladder, a 4-Coin Potato, talents bought before World 2 ends, repeat runs worth tens of Coins next to a 100 k+/day field and Scouting
effectively frozen. *What:* `tools/economy_ev.py` (event-by-event simulation, the old → new proposal table, checks G1–G9, B, B2, C), approved
by the user and pinned. Decisions: "Next" → EV.

**U2 — Garden badge and summary bubble** (2026-11-06; UI_GARDEN_PETS §3, §8). A badge with ripe crops + ready eggs (on the Garden button,
since 2026-11-13 the Home farm button) and a bubble over the own plot's sign (ripe count, time to the next ripe crop, ready egg, "🌱 Plant
seeds"). Studio-validated.

**FA — The field for everyone, pens removed** (2026-11-06; GDD §7.9). *Why:* the game was not public and both players were admins, so the
no-field / pen path was a second code path for nobody. *What:* `FieldAccess` and every pen remote, rate, panel and script removed; a
profile from before converts once on join (penned pets to the inventory, field pet slots from pens, pen fields cleared; pen production since
the last payout is not paid). Max Players stays 12 until going public. Studio-validated on both live profiles and a migration fixture.

**U1 — Pets panel, pet page, food stand rows** (2026-11-06; UI_GARDEN_PETS §9, GDD §7.8). *Why:* a kid on a phone reads icons and fills, not
text, and must not sell by mistake. *What:* a shared pet row (level badge, status corner, one trait chip per working trait with a fill, ▲ on
the trait food trains, "✔ Trained"), only Equip + Details bricks, filter chips (All, With me, On the field, Best for …), Sell under More with
two taps, the food stand on the same rows. Studio-validated.

**P4 — Pet traits** (2026-11-05; GDD §7.4, §7.8). *Why:* the Coin bonus becomes one trait among others, so pets differ. *Decided (the
user):* the Coin bonus is the **Cuteness** trait (multiplier only, cap +50 %), rolled by a chance per rarity, no guarantee; every working
trait (Cuteness, Tending, Pest control, Scouting) has its own level and the pet's level, size and look follow its highest one; Cuteness
levels from obby XP, food and crop feeding, the others from field hours / medal finishes; a pet without Cuteness (or at its cap) trains its
lowest working trait below level 5, nothing to train → food refused; stored Fertilising / Weeding / Crafting stay, hidden. Every pet from
before got Cuteness once (profile `Version = 4`), so no bonus dropped. Levels doubled to 20 on 2026-11-12. Studio-validated.

**Stud food stand and plot signs** (2026-11-05; GDD §7.6, LAYOUT Garden). *Why:* the stand and the plot signs were the last plain-wood
pieces in the garden; the stand read from one side only, and the low plot sign blocked the way and the view into a plot. *What:* the food
stand rebuilt as a four-sided stud kiosk at the plaza centre (sign on every side, strawberry on top; `Counter` + prompt kept); the plot
sign (`PlotView:buildSign`) in the hub sign's stud palette, 1.5x taller, its board 7.5 studs over the ground. Studio-validated: a
character walked under the sign, the prompt opened the food panel with E, the stand's coplanar audit shows only hidden faces.

**Stud conveyors** (2026-11-05; STAGES §2.5). *Why:* Stage 1's two conveyors were smooth slate columns that hid their direction. *What:*
charcoal stud belts with rollers and amber chevrons on their own stud pillars (Stage 1), Stage 10's `Conveyor_9` restyled the same way,
template `Conveyor_Belt`; in play the chevrons slide along the belt at its speed (`KitConveyorsClient`). Studio-validated: coplanar audit
clean, a playtest carried the character at 5.9 / 5.8 studs/s along the chevrons, chevrons moved at the belt speeds (6 / 12) and turned on a
sign flip.

**E4-thin — Crows and Pest-control guards** (2026-11-04; GDD §7.9). *Why:* a light risk that makes the forecast and guard pets matter
without punishing play (only during absences, at most one crop). *What:* UTC crow blocks with a forecast line, the raid in the join settle
after Tending, guards with a chase chance and specialities, both jobs per pet, the Pest-control card and the crow notice. Numbers: ECONOMY
"Crow run".

**E0 — Economy model** (to 2026-11-07; ECONOMY.md). `tools/economy.py` (Python stdlib): pins for every config number, the GDD figures
reproduced, a 60-day simulation of four archetypes × two purchase policies, and the re-runs that gated E1b–E1d, E2, E4-thin and offline
growth. It showed pet levels saturating within days (one reason for the aptitudes) and the sinks running out within weeks. Its repricing
and open checks (sink share, bands, sensitivity) were replaced by EV.

**E2 — Obby seeds** (2026-11-04; GDD §7.9). *Why:* medal finishes feed the field, so the obby and the garden pull together. *What:* three rare
crops (one per world, only from the obby), rare seeds for the first World 2 / 3 Gold, the daily seed and per-stage meters, the seed pouch,
Scouting on equipped pets, lines on the results popup. Golds from before E2 give nothing (the user). Numbers: ECONOMY "Obby seeds run".

**E1d — Farming first, 36-square field** (2026-11-03). *Why:* the user made farming the main game (parity with the obby on days 1–3, 3x by
day 7, 10x by day 30). *What:* the F2 numbers (crop prices × 9.3, square / upgrade / slot prices, five field pet slots; pens convert without a
refund); the field as 36 squares in rows 6-6-8-8-8 behind an incubator strip, any square opened by a hold prompt, old 12-square fields moved
onto the grid on load (`CropConfig.FromOldSquare`). Rejected: three rectangular garden islands (a scene job of its own that would spread 12
players over 18–24 plots; may come back with the estate).

**E1c — Size roll, field upgrades, tools, market cart** (2026-11-02 / 03; GDD §7.9). *What:* a lognormal size roll per planting with Big /
Giant and records; Growth and Barn upgrades; Seed sorter, Cloches and Pruning shears with Renown-gated levels; the daily market cart with a
taste of the next locked crop (so Plant lost its Renown gate). Found on the way: `Locale.Number` had swapped the bytes of the Czech thousands
separator since L1 (fixed).

**E1a3 — Crops as pet food** (2026-11-04). Held crops fed from the pet page; XP = half the sale, so feeding is never better than selling and
buying food (the Kitchen, D5, stays the better route).

**P3a / P3b — Pet page and pet names** (2026-11-02; GDD §7.8). *Why:* aptitudes made pets differ in ways the list cannot show, and a named pet
is a kept pet. *What:* the "i" badge → `PetDetail` page; names filtered with `TextService`, first free then 250 Coins, shown to everyone
through `PetNames`.

**E1b — Field pets** (2026-11-02; GDD §7.9). *Why:* pets work the field instead of pens, and aptitudes are a lasting progression axis (pet
levels saturate within days). *What:* aptitudes rolled from the uid, Tending pets that harvest and replant during absences, reach by level,
field pet slots, the one-time pen conversion. Decisions (the user): behind field access, so live players keep pens until E1 ships; Tending
only during absences (revisit with telemetry); a hatch while owning no Tending pet gets Tending; penned pets go back to the inventory; Max
Players stays 12 until E1 ships.

**E1a — Client-drawn plots and the crop field** (2026-10-30 / 11-02). *What:* E1a1: every plot drawn by the clients from `GardenRemotes.Plot`
(the server holds no plot instance), the garden moved 87 studs away from the hub onto two rings (radius 112 / 185, ring 2 turned 5° so the
bridge path runs between plots); E1a2: the field behind `GardenConfig.FieldAccess = "admins"` (a code constant switched by publishing, no
testers mode), `CropConfig`, light Renown, seeds and selling from the Garden panel at the own plot (no seed stand), 4 free Potato seeds.

**K1 (part) — First-hour fixes** (2026-11-01). Stage 5's tightrope wires became 2-stud beams and its section 1 is clearable without talents
(1-stud lips on the landing plates); the G1 stuck fallback (3 failed runs or 12 deaths → the lowest-medal stage of the same world); Double
Jump became a world reward granted when World 2 opens (never sold; `TalentGrantPopup`). Open part: "Next" → K1.

**E1.0 — Client-drawn plots spike, GO** (2026-10-30). *Why:* the 12 server-built plots tie the player cap to built scenery, and the crop field would
multiply the server's instances. *What:* a client `PlotView` prototype behind a Studio flag draws a plot from one data message; plot positions
come from a formula (`GardenConfig.PlotCFrame`), which the server's distance check and `GoGarden` already use. *Measured:* 30 plots in range cost at
most 4 802 client instances (budget 5 000; pets are 78 %), no build frame over 7.6 ms, about +6 MB, no server instance or DataStore request; the
formula matches the Studio plots and is equal on server and client (check 2), but today's inner ring is only 2.8 studs apart. *Decided:* the server
keeps only data; up to 30 players (start at 24), a compact ring neighbourhood with teleports, a mid pet detail first, an offline-visit snapshot
designed (EXPANSION §16).

**G1 — Player guidance hints** (2026-10-27; GDD §11). *Why:* after a stage players did not know where to go, and affordable skills and ready eggs
went unnoticed. *What:* an orange arrow with the next stage's name (the latest open stage without a medal, or the stage whose medal would open
the next world), on the screen edge when off screen and hidden during a run; a dot on Skills when a level becomes affordable; dots, a marker and
a toast for a ready egg. Display only, no server change.

**S8 — World 3** (2026-10-24 / 28; STAGES §7.11–7.13). *Why:* the third world for the Triple Jump and Dash talents. *What:* Triple Peaks (Triple
ledges, crushers), Ice Rink (kit ice, wind, a pressure door), Dash Bridge (Long Dash = Dash level 2, rolling balls), Laser Lab (the Key Arena
prototype rebuilt as stacked vault lanes and a tower after the user's sketches, checked by `tools/vault_reach.py`), Rising Tide (a lava tide
under six segments replaying World 3). The user ran all five with Gold; medal times were set from those runs (Bronze 2.5 × tBase for every stage). **Signed off 2026-11-07** after a sign-off playtest: Stages 11–14 unchanged; Stage 15 got studded pillars and chimney shell, a 14-high `TideDoor`, a capped 1305 beam (`BeamHeight` attribute in `CheckpointClient`), plain-transparent `GlassN` (Glass hides transparent beams), a ceiling stamper gate with a three-stage telescope on `Slab3_N`, a studded hazard-stripe Sweeper, and Gold 46 s (own `tiers`); STAGES §7.13.

**S7 — Triple Jump + Dash, World 3 courtyard** (2026-10-24). *Why:* World 3 needs new movement. *What:* Double Jump level 2 = Triple Jump, Dash
(Q / gamepad / touch button), reach table with the real talents, the World 3 courtyard east of the hub.

**S6 — World 2** (2026-10-22 / 23; STAGES §7.9). *Why:* the second world, built on Double Jump. *What:* Double Up, Seesaw, Turntable, Labyrinth (a
maze with guards and shifting walls) and Clocktower (tick-driven spinners, buttons and doors). Declared done by the user 2026-10-30.

**S5 — Worlds hub** (2026-10-22). *Why:* stages grouped into worlds behind star bars. *What:* hub gates for Worlds 1–4 (a "soon" world is shut for
all but admins), the World 2 courtyard, per-world stars boards.

**S4 — World 1 complete** (2026-10-21 / 22). *Why:* finish the first world before the first live test, so the new unlock chain needs no grandfather
rule. *What:* the courtyard with a hub gate and the `Gate` / `Top10Leaderboard` / `Arrival` templates, Island Hop and Blink (the rhythm stage),
prompts on shut gates instead of the unlock popup, all courses restyled in the stud look; stage keys, folders and coin ids renamed to the stage
position (`Stage1`…`Stage5`) and the records migrated.

**S3 — Obstacle kit + jump lab** (2026-10-21; STAGES §2.4). *Why:* stages built from tagged parts instead of per-part scripts, and smooth movers
for the player who rides them. *What:* a client-driven kit (movers, tilt plates, beams, crumbling and colour plates, switches; zones for wind, low
gravity and updrafts; ghosts; a stage camera) after a measured spike, a jump lab and a reach table per talent set. Lesson kept in STAGES: other
clients see a rider about 0.2 s late, so movers stay slow.

**S2 — Quick Respawn talent.** *Why:* faster retries on hard stages. *What:* respawn after 1 s, then instantly with a client-side fall reset; one
server script does all respawns.

**S1 — Stage framework** (2026-10-21). *Why:* a world-based unlock chain for about 20 stages. *What:* `world` / `requires` in `StageConfig`, reward
factors by position, unlock by 10 of the previous world's 15 stars or a price, "Needs: <talent>" lines that warn but never block, Stars in the
leaderstats.

**L1–L3 — Localization** (2026-10-23 / 24; LOCALIZATION.md). *Why:* reach Czech players first and keep every later text translatable. *What:*
English + Czech chosen from the locale with a Settings override; `Locale.T` / `SetKey`; one CSV with context compiled by `tools/loc.py`, a lint
against literal texts and a pseudo-language; every panel, server text and Studio label converted. The user reviewed the Czech texts.

**T1a / T1b — Telemetry** (2026-10-23; TELEMETRY.md). *Why:* M6a needs real data, and data accumulates only once it is live. *What:* one
AnalyticsService user: a run funnel per stage, fails per segment and cause, run ends, quits and returns, sessions (locale, platform), the talent
loadout per run and every purchase.

**H2 — Stud checkpoints.** *Why:* clearer checkpoints that show progress. *What:* a stud plate whose tile and light column glow only for the
player who reached it; respawns face along the course; a `StageKit.Checkpoint` template.

**Art style: stud, final** (2026-11-05, the user). The voxel / pixel-art previews of 2026-10-20 were dropped (doc and screenshots:
`git show 87b1d3c:docs/STYLE_PREVIEW.md`).

**H1 — Hub island redesign.** *Why:* one look for hub and garden. *What:* the hub as a stud-style island joined to the garden by a bridge, one sea
as the kill floor, stud portals, decor from `ServerStorage.DecorKit`, the camera turned along the course after a teleport.

**P2 — Pet garden.** *Why:* a place to raise pets for players who prefer collecting to obby runs. *What:* a garden island with 12 borrowed plots;
6 pens whose pets produce Coins, also offline (8 h cap, server time only); 3 incubators, the only place eggs hatch; a food stand for pet XP.
To be replaced by the field and field pets in E1.

**P1 / P1e / P1g — Pets.** *Why:* collection and a reason to replay. *What:* 8 kinds in 5 rarities with a Coin bonus capped at +50 %, 3 follower
slots, XP from runs, levels 1–20; looks derived from kind, level and uid (size, tier effects, colours, accessories); all kinds restyled in studs
and checked by the user 2026-10-30.

**M5 — Leaderboards + hub navigation.** Top-10 boards with avatars per stage, the hub "most stars" board, the Tutorial, top-left buttons (Home,
Skills, Pets, Settings, Admin). *Why:* competition and a way home.

**M4 — Challenge coins.** Coins hidden in the courses, paid once per player and hidden only for that player. *Why:* exploration and a reason to
revisit. Ids are stored in profiles and never renamed.

**M3 — Stage unlocks.** A stage opens by the previous stage's medal or a purchase. *Why:* a progression path that skill or Coins can open.

**R — Economy.** `CoinRewards.Grant` is the only gameplay payout (pet multiplier, rounding); a daily repeat reward that decays per finish; all
amounts ×10 (profile `Version = 3` migrates once). *Why:* one place for payouts and repeat play that cannot be farmed.

**M2 — Talents shop + admin tools.** Run Speed, Double Jump, Jump Height, server-priced; `AdminConfig` with server-checked admin actions.
*Why:* a Coin sink that changes how a player moves; safe testing tools.

**M1 — Medals & rewards.** Bronze / Silver / Gold by time with one-time payouts and a results popup. *Why:* a goal beyond finishing.

**M0 — Foundations.** `StageConfig` so all stage scripts are identical copies, the run timer, the `PlayerProfiles` DataStore (a failed load never
saves) migrating the legacy stores. *Why:* one data model and one copy of every stage script.

## Ideas (unscheduled)
- **More UI sounds:** click, tab, field hover and toast notify are in (`UiSounds`, AmbientSorcery `ui-simple-*`). Same creator also has
  `-menu-open` / `-menu-close`, `-inventory-open` / `-close`, `-positive-confirmation`, `-negative-error`, `-reward-collect`, `-equip` /
  `-unequip` (search `ui-simple`, Audio, Creator Store): candidates for panel open / close, buy result, error toasts, pet equip.
- **Blink music:** a real track with its BPM instead of the metronome (S4).
