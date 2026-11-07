# Pawvest — Roadmap

Build order and status; "What next?" is answered from here. Design lives in [GDD.md](GDD.md) (the game as built), [STAGES.md](STAGES.md)
(stages), [EXPANSION.md](EXPANSION.md) (the pet-garden direction) and [ECONOMY.md](ECONOMY.md) (numbers). Finished milestones keep only what was
done and why; their scopes, acceptance checks and validation logs are in git history (last full version: `git show 87b1d3c:docs/ROADMAP.md`).

## Workflow
1. **Design check:** the milestone still matches the design docs; fix the docs first if not.
2. **Scope:** before coding, the milestone states inputs, outputs, boundary and **hard** acceptance checks (phrased so an empty or broken
   result fails: "second Gold finish pays 0", not "pays Coins").
3. **Implement:** code in `src/` (Argon); Studio-only changes (parts, GUI, RemoteEvents) are listed in the milestone, since git does not hold them.
4. **Studio validation:** an MCP playtest runs every check, through the real UI at least once (firing remotes alone once missed a broken
   button); no new console errors; live DataStores snapshotted and restored (AGENTS.md → Testing).
5. **Status + commit:** update the table, commit code and docs together; when a milestone is done, shrink it to a short entry in "Done".

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
| P4 | Pet traits: Cuteness carries the Coin bonus, per-trait levels 1–10, look from the highest trait | ✔ | partial | – |
| H1, H2 | Hub island, stud checkpoints | ✔ | ✔ | – |
| S1–S7 | Stage framework, Quick Respawn, obstacle kit, World 1, worlds hub, World 2, Triple Jump + Dash | ✔ | ✔ | – |
| S8 | World 3 (Stages 11–15) — awaits the user's sign-off | ✔ | S8.1 ✔; S8.2–S8.3 bot-checked, run by the user | – |
| T1a, T1b | Telemetry | ✔ | ✔ | – |
| L1–L3 | Localization (English + Czech) | ✔ | ✔ | – |
| G1 | Player guidance hints — awaits the user's check in play | ✔ | ✔ | – |
| K1 | First-hour fixes (kid playtest 2026-11-01): Stage 5, G1 fallback, Double Jump world reward done; hatch panel proposed | partial | partial | – |
| E0 | Economy model: baseline, simulation, field and every E1–E4 re-run done; repricing and the remaining checks open | partial | – | – |
| E1.0 | Client-drawn plots spike: **GO** | ✔ | ✔ | – |
| E1a–E1d | Crop field (every player's since FA): client-drawn plots, field, field pets, crops as pet food, size roll, upgrades, tools, market cart, farming-first numbers, 36 squares | ✔ | ✔ | – |
| E2 | Obby seeds: rare crops, rare-seed meters, seed pouch, Scouting | ✔ | ✔ | – |
| E4-thin | Crows and Pest-control guards (E4a server, E4b client) | ✔ | ✔ | – |
| OG | Offline crop growth 0.5 / 24 h | ✔ | pending | – |
| E5 | Garden MVP rest: request board, ledger on join, onboarding, garden telemetry | – | – | – |
| M6a | Soft launch + World 1 balancing — World 1 balanced by feel (2026-10-30); live test open | – | – | – |
| MU | Mobile UX check | – | – | – |
| U1 | Pets panel rows with trait chips, filters, pet page Sell under More, food stand rows | ✔ | partial (multi-client look open) | – |
| FA | The field for everyone, pens removed | ✔ | ✔ | – |
| U2 | Garden icon with a badge (ripe crops + ready eggs), summary bubble over the own plot sign | ✔ | ✔ | – |
| U3 | Field: rings, tap-select, square card, hand bar (Seeds / Basket / Pets / Look), reach borders, square prompts removed | ✔ | partial (phone touch, multi-client open) | – |
| U4–U5 | Garden and pet UI redesign, rest ([UI_GARDEN_PETS.md](UI_GARDEN_PETS.md)) — design decided 2026-11-05 | – | – | – |
| S9, S10 | Wall Jump + Glide, World 4 (drop D8) | – | – | – |
| M6b, S11, M7, trading | Final balancing, bonus stages, monetization (drop D2), trading | – | – | – |

## Next
**Order (2026-10-30, updated 2026-11-06).** The soft launch takes the obby (15 stages) and the garden as built: since FA (2026-11-06) every
player has the crop field, so the rest of the garden MVP (EXPANSION §14) is built in the open game. World 4 waits until after the MVP.

1. **Close World 3:** the user's sign-off of Stages 11–15 with the new medal times. Stage 10's times stay (decided 2026-10-30: the fast
   test-account times there need every talent, the Long Dash included).
2. **M6a soft launch** (friends, then unlisted) with 15 stages, pets and the garden with the crop field: real finish times, T1a / T1b on the
   Creator Dashboard and a first retention baseline. The planned obby-only baseline is dropped (the garden is in from the start since FA);
   what later drops add is measured against this one. Includes the live-test checks below.
3. **Offline growth (OG) validation:** a 24 h-back `SettledAt` must give `Grown` = 43 200 for a pumpkin (ripe at 28 800). The same test
   explains the user's pumpkin that still had 5 h 47 min left after 24 h away (at most about 4 h was expected under the old 0.33 / 12 h rules).
4. **E5 + rest of the garden MVP** (scope when it starts; EXPANSION §14): request board, the ledger on join (the join notice grows into it),
   onboarding for the first ten minutes, garden telemetry. Before going public Max Players goes to 24 (a place setting) and the open item
   "Before Max Players 24" below is checked.
   Gates before going public: M6a, the balancing pass, the Czech review of the new texts, MU, and the comfort shop (D2) or a decision to
   launch without it.
5. **E0 in parallel:** repricing and the remaining checks (section below).
6. **MU** before anything goes public.
7. **U1–U5 garden and pet UI** (design decided 2026-11-05, [UI_GARDEN_PETS.md](UI_GARDEN_PETS.md) §11–12; scope each when it starts):
   **U1** built and Studio-checked (2026-11-06) except the multi-client look check (F7, the user); **U2** built and Studio-checked (2026-11-06); **U3** (rings, tap-select, square card, hand bar, reach borders) built and Studio-checked
   (2026-11-07) except the phone touch check and multi-client; **U4–U5** (Skills Garden tab,
   barn, seed stall, plot layout) before E5's onboarding, which teaches the new controls.
8. **Drops D1–D10** after the MVP (EXPANSION §14), one every 1–2 weeks: Critters, Comfort shop (M7), Weekly, Variants, Kitchen (the first
   restoration landmark), Neighbours, Mastery, World 4 (S9 / S10), the Estate, Season 1. Restoration bundles (E6, D5) and estate tiers / decor /
   cottage (E7, D9) are the long-term Coin sinks; E0 holds a placeholder for their size until they are designed.

Key talents as **world rewards**: done for Double Jump (K1, GDD §6). Open: Triple Jump / Dash for World 3. The lost Coin sinks are made up in
the balancing pass (STAGES §6, GDD §6).

### K1 — First-hour fixes, open part (kid playtest 2026-11-01)
A 9-year-old on a phone, fresh progress, got stuck after about 20 minutes. Target: a new player who does not pay always has a next step for
the first hour; World 1 and the garden are tuned for 8–10 year olds on a phone. Seen: signs and banners are not read (the GDD §11 rule
"without reading anything" holds), too much text at hatching, Coins spent elsewhere so World 2 stopped him. Done: see "Done" → K1.
- **Hatching text (proposed):** the empty incubator lists every egg with a line of percentages. Instead: two egg cards (picture, price, time),
  odds behind a small "?", the hatch result as a pet reveal (portrait, name in the rarity colour, one line).
- **World 2's star bar** stays at 10 of 15 until the wider test (the user, 2026-11-01); a checkpoint inside Stage 5's tightrope: not now
  (telemetry first).
- **Measure it in M6a:** T1a fails per segment on Stage 5, quits per stage, session length of new players.

### P4 — Pet traits (decided 2026-11-05, implemented; Studio checks partial)
**Goal.** The Coin bonus becomes a trait, **Cuteness**, that only some pets roll at hatch; the single pet level (1–20) goes away: every trait
(aptitude) has its own level 1–10 (rarity cap 6–10), and the pet's level, size and look follow its highest working trait. Goes before U1, so
U1's trait chips include Cuteness.

**Decisions (the user).** Effect = Coin multiplier only (cap +50 %; "discounts" is flavour). Cuteness levels from today's pet XP sources
(obby XP, food, crop feeding); Tending / Pest control from field hours, Scouting from medal finishes, as built. Look: today's 20-level look
downscaled to 10 (size 1.0 → 1.6 at Lv 10, tiers at 3 / 5 / 8 / 10, Neon accents at 10), same level = same look on every pet. Counts by
rarity as today (1 / 1+10 % / 2 / 2+50 % / 3). Cuteness by a chance per rarity, no guarantee. Hatches roll only working traits (Cuteness,
Tending, Pest control, Scouting); stored Fertilising / Weeding / Crafting stay, hidden, not counted. A pet without Cuteness (or with it at its
cap) gets food and obby XP on its lowest working trait below level 5, as field time; nothing to train → food refused, obby XP lost. Every pet
from before P4 gets Cuteness once (at `1 + ceil((Level − 1) × 9 / 19)`, clamped to its cap; with `CuteStep` 19 ‰ no bonus drops), on top of
its traits.

**Inputs / outputs.** `PetConfig` (new id `Cuteness`, `PetLevel`, `GainCareXp`, `MaxLevel` 10, `Tiers`, `CuteChance`, `CuteStep`,
`CuteXpToNext`, `CareLevelCap`, `CareSecondsPerXp`), `GardenConfig` (pen rate by `PetLevel`, `LevelRate` so Lv 10 = ×1.76), profile
`Version = 4` migration in `PlayerProfile` (`Level` / `XP` stay stored, frozen), `PetService`, `GardenFood`, `GardenField` (FeedCrop, feeds),
`GardenPlotFeed`, `PetLook`, the pet UI (Pets panel minimal, pet page trait cards for everyone, food stand, hatch reveal), `economy.py`
(model + tuning + pin), docs. No Studio-only changes expected.

**Acceptance checks.**
1. 1 000 seeded hatches per rarity: only hatch-pool traits, count by rarity and ≤ 3, Tending and Cuteness shares within ±4 points of the
   shares `economy.py` computes from `TendingChance` / `CuteChance` (Cuteness is rolled after Tending, while a slot is left); forced Tending
   only for an owner with field access.
2. The multiplier counts only cute equipped pets: one non-cute equipped pet → multiplier exactly 1; the +50 % cap holds.
3. A medal finish: an equipped cute pet's Cuteness XP rises by the run's XP; an equipped non-cute pet's lowest working trait gains
   XP × `CareSecondsPerXp` seconds; a pet with Cuteness at cap and every work trait ≥ 5 gains nothing.
4. Food stand and crop feeding through the real UI follow rule 3; a pet with nothing to train is refused with its text and no Coins taken.
5. Migration on a copy of a live profile: every old pet has Cuteness at the mapped level, its bonus ≥ the old one (side by side), other
   traits unchanged, `Level` / `XP` unchanged; a second load changes nothing.
6. Look: Lv 10 = today's Lv 20 (scale 1.6, halo, 2 accessories, Neon accents), Lv 5 = today's Lv 10 (2 stars, 1 accessory); the level-up
   moment plays when the highest trait rises (follower and pen).
7. Pets panel, pet page, food stand and hatch reveal in English and Czech without cut-off text; the pseudo-language finds no literal.
8. `economy.py check` passes after the reviewed `pin`; pen output at Lv 10 equals today's at Lv 20.

**Studio (2026-11-05):** 1–6 passed (6 by the look numbers and a level-up moment on a follower; pens are gone for field-access players, so
the pen moment was not seen); 7 in Czech through the real UI (pets panel, pet page, food stand, hatch reveal: 48 of 50 px with three traits).
8 passed after the user accepted Obby main's 79 % sink share by day 60 (bar 80 → 78 %) and the `pin`. Open: a multi-client look
check (run with U1's check 9). The pseudo-language pass was done in U1 (check 8); the no-field pet page check was dropped with the no-field
concept (2026-11-06).

### U1 — Pets panel, pet page, food stand rows (design: [UI_GARDEN_PETS.md](UI_GARDEN_PETS.md) §9, §9.1; scope 2026-11-06)
**Goal.** A kid on a phone reads a pet's traits from icons and fills instead of text, equips without accidental taps, and does not sell by
mistake. Client UI only: no remote, profile or config change.

**Build.**
- **Shared row** (new ModuleScript `PetRow.luau` beside PetPortrait, used by the Pets panel and the food stand): portrait with a **level
  badge** (`PetConfig.PetLevel`) and a **status corner icon** (✓ with you, 🌾 on the field, none when resting); name in the rarity
  colour; one **trait chip** per working trait (`PetConfig.Shown`, list order): icon + level in the trait's colour (💗 Cuteness, 🌱 Tending,
  🛡 Pest control, 🔭 Scouting) with a thin progress fill along its bottom edge (the same share as the pet page's bar for that trait; full at
  the cap); a ▲ on the chip `PetConfig.CareTarget` names; "✔ Trained" instead when nothing can train. Mouse hover / touch hold on a chip
  shows the exact numbers (as the pet page: XP, field hours, medal finishes, "max").
- **Pets panel:** row = shared row + **Equip / Unequip** brick + **Details ›** brick (opens the pet page); the rest of the row does nothing; the
  "i" badge, the Sell brick, the rarity / bonus / XP text lines and the tag go. Summary line: "Coin bonus +12 % · 2 cute pets with you".
  **Filter chips** over the list: All (n/50) · With me · On the field · Best for ▾ (💗 Coins, 🌱 Tending, 🛡 Pest control, 🔭 Scouting: only pets
  with that trait, highest level first). The filter holds
  through state changes and reopening (per session). Width 340 → 460, capped to viewport width − 2 × 16 (the icons are a row above the
  panel, no column to keep free), divided by the PanelFit scale; compact layout on short screens as today. "Go to my garden" stays.
  Info line / slot hints say "Equip" instead of "click a pet".
- **Pet page:** Equip / Unequip stays at the top of the actions; **Sell** moves to the bottom under a small "More" heading: a small grey
  brick, first tap arms it (orange, "Sure? +N"), a second tap within 3 s sells. The trait card food trains now gets the ▲ (and the trait's
  colour on its title); a pet with nothing to train shows "✔ Trained" in the growth card.
- **Food stand:** the shared row; the chip the food will train is **highlighted** (outline) instead of the text line; order: pets with you,
  then the rest that can still grow, then "Trained" / "Max level" pets greyed at the bottom; food buttons, tooltips and the two-tap touch
  feed unchanged. The panel gets a UIScale so it fits a phone screen (today 540 × 480 fixed).
- **Every player has the field** (the user, 2026-11-06: only two players, both admins; the old no-field / pen concept is dropped): U1's
  files lose their `HasFieldAccess` branches (pet page "for later" cards, greyed chips, pen tags). Switching `FieldAccess` to everyone and
  removing pens elsewhere is its own task, not U1.
- Texts through `Locale` / `strings.csv` (English + Czech, `cs_status` new); keys no longer used are removed.

**Acceptance checks** (Studio, through the real UI; live profile snapshotted before any fixture, restored after).
1. Rows: for an equipped, a field and a resting pet the badge shows `PetLevel`, the corner icon is right, one chip per working trait with
   the right level; each chip's fill matches the pet page's bar for that trait (±2 %); ▲ sits on the `CareTarget` chip only; a pet with
   nothing to train shows "✔ Trained" and no ▲; hover (mouse) and hold (touch) show the exact numbers.
2. Equip brick equips / unequips (the slot fills / frees, the row's mark changes); for a field or pen pet it refuses with the reason; Details
   opens the pet page; a click on the row's name, chips or blank space changes nothing; no "i" badge and no Sell on any row.
3. Pet page: Sell is the last item, grey; the first tap turns it orange "Sure? +N", it lapses after 3 s; the second tap sells (Coins +
   sell value, the page closes, the row is gone); for an equipped / field pet it refuses with the reason. The ▲ card = the row's ▲ chip.
4. Summary: the bonus equals the server multiplier, the count equals the equipped pets with Cuteness; equipping a non-cute pet changes
   neither.
5. Filters on a profile with ≥ 6 pets: each chip lists exactly the matching pets (With me = equipped, On the field = on a square, Best for
   X = pets with X, highest X first); the choice survives an equip and a close / reopen.
6. Size: 460 px wide at 1920 × 1080; on 844 × 390 and 667 × 375 viewports the Pets panel, the pet page and the food stand stay fully on
   screen with ≥ 16 px side margins, at least two list rows show, every tap target (Equip, Details, filters, Sell, food buttons) is
   ≥ 44 px at scale 1 and ≥ 36 px on screen when scaled.
7. Food stand: rows as in check 1 with the food's chip highlighted; order with-you → can grow → trained (greyed, no food buttons); a feed
   through the real UI moves the highlighted chip's fill / level; P4's tooltips still show the outcome.
8. Texts: English and Czech without cut-off text (`TextFits`, brick `Glyph` labels) in the Pets panel, pet page, food stand and hatch
   reveal; the pseudo-language finds no literal there (P4's open check). `loc.py build` / `check` (0 errors) / `lint` (within baseline).
9. With the user's multi-client test (F7, P4's open look check): each client sees the other's equipped pets with their level look (size,
   tier). P4's "pet page without field access" check is dropped with the no-field concept.

**Studio (2026-11-06, live profile Lekzdrh, snapshot `profile_9892673032_U1_1`, restored and checked):** 1–8 passed. 1: 11 rows (badge,
corner icon, chip levels, fills ±2 %, ▲ only on CareTarget), "✔ Trained" via a display-only PetsChanged fixture, mouse hover; touch hold
untestable with the MCP (mouse only). 2: Equip / Unequip through the bricks, field pet and full slots refused, name / chips / portrait do
nothing. 3: Sell grey → orange "Sure? +100" → lapsed after 3 s; two taps sold a pet (+100 Coins, page closed, row gone). 4: a non-cute pet
equipped (fixture) left the summary unchanged. 5: each filter exact, held through an equip and close / reopen. 6: 460 wide at 1472 × 1005;
on 845 × 390 and 667 × 375 all three panels on screen, ≥ 2 rows, every target ≥ 36 px on screen (pet page and food buttons raised to it
during the check); the panel's left edge stays on the icons' line (x 10) like the other panels, right margin ≥ 16. 7: via the real
prompt; Cake feed moved the outlined Cuteness chip 0 → 0.17. 8: Czech and English all fit (food status line made two lines); pseudo finds
no literal (only the user's pet name), only pseudo-inflated texts overflow. Open: 9 (the user's multi-client test).

### FA — The field for everyone, pens removed (the user, 2026-11-06; scope 2026-11-06)
**Goal.** The game is not public and both players are admins, so the crop field goes to everyone and the old no-field / pen concept goes:
one garden (incubator strip + field + field pets), no second code path. Runs after U1 is committed (U1 drops the no-field branches of
`PetsPanel`, `PetDetail`, `FoodShopClient` itself; this task does not touch those three files and shares `strings.csv` with it).

**Build.**
- **Access:** `GardenConfig.FieldAccess` and `HasFieldAccess` are removed with every branch on them (`GardenField` "locked" rejects and
  `ObbyFinish`'s gate, `GardenPlotFeed`'s field-less state, `PetService.AddPet`'s Tending rule now always applies, `FieldClient`'s gate).
- **Pens, server:** `GardenService` keeps only the shared garden plumbing (hooks, rate limit, `Usable`, `State`, `RequestState`); the
  `Place` / `Remove` / `BuyPen` / `Payout` remotes, pen production, the online payout loop and the welcome-back payout go. `GardenConfig`
  loses `MaxPens`, `PenPrices`, `BaseRates`, `MaxLevelRate`, `OfflineCapSeconds`, `PayoutSeconds`, `MinAwaySeconds`, `Units`,
  `RatePerHour`, `Settle`, `IsPenned`; `PetsChanged.penned` and every "penned" reject go (`PetService`, `GardenField`, `GardenFood`);
  `GardenPlotFeed` drops `pens`, `penCount`, `converted`.
- **Live profiles:** the E1b conversion in `GardenField` stays as the one-time migration on join for a profile without `Garden.Converted`
  (penned pets back to the inventory, `CropConfig.PetSlotsFromPens` slots, the pen prices beyond the slots' value refunded, the "converted"
  line in the field notice). Its pen prices move to `CropConfig.LegacyPenPrices` (read only there). Pen production since the last payout is
  not paid any more (≤ 8 h of pen Coins, and only for a profile not converted yet). After the migration every profile's `Garden.Pens`,
  `PenCount`, `Carry`, `LastSeen` are cleared; a new profile starts without them.
- **Pens, client:** `GardenClient` (pen panel, welcome-back card, payout toast), `PetPenFx`, `PetPenLevelUp` are deleted on disk;
  `GardenView` loses `OnPen` / `OnPenLevelUp` / `PenPets` and the synthetic plots' pens; `PlotView` loses the pen pieces and labels and draws
  every plot (a free one too) as the incubator strip; `PetClient` drops `penned`. No Studio-only pen parts exist (plots are client-drawn).
- **Tools / texts:** `tools/economy.py` drops the pen rates (`--garden pens|both`, the pen table, check 2's pen figures) and reads
  `CropConfig.LegacyPenPrices` for the conversion; field-mode results stay as pinned. Pen texts (`garden.*` pen panel, payout, pen signs and
  prompts, `pets.tag.pen`, `pets.reject.penned`, `food.where.pen`, the field "locked" reject) leave `strings.csv` once nothing uses them.
- Max Players stays 12 (24 and the 24-plot check wait for going public).

**Acceptance checks** (Studio; live profiles snapshotted before any fixture, restored after).
1. Code: `grep -E "HasFieldAccess|FieldAccess|IsPenned|PenPrices|MaxPens|penned|OnPen"` over `src/` finds nothing (except
   `LegacyPenPrices` in CropConfig and the conversion); the three deleted scripts are gone in Studio too, no duplicate or empty scripts.
2. A playtest boots without errors or warnings from garden / pet scripts (server and client); `GardenRemotes` holds no `Place`, `Remove`,
   `BuyPen`, `Payout`.
3. Both live profiles (Lekzdrh, AhojRupert) are `Converted` before the change; after a join the Lekzdrh profile has no `Pens` / `PenCount` /
   `Carry` / `LastSeen` and the same Coins, pets, field, field pets, incubators and eggs as the snapshot (apart from the field's own growth).
4. Migration fixture (own profile, snapshotted): `Converted` = nil, two pets in `Pens`, `PenCount` 3 → after the join both pets rest in
   the inventory (Pets panel), `FieldPetSlots` = max(2, before), Coins unchanged (pens 1–3 cost 3 500, under slot 2's 23 300: no
   refund), the field notice shows the converted line once; a second join converts nothing.
5. Plots: the own plot, another occupied plot and a free plot all draw as the incubator strip with the field behind (free: "Free plot", grey
   incubators, no pads); the synthetic-plots budget run (`GardenViewPlots`) draws without errors.
6. Through the real UI: plant and harvest a square, place and lift a field pet, feed a crop to a pet, open an incubator, feed a resting pet
   at the food stand, equip and sell a resting pet.
7. A medal finish on a stage with a rare crop still gives its seeds; a hatch with no Tending pet owned gives Tending.
8. `loc.py build` / `check` (0 errors) / `lint` (within baseline), the removed keys gone; `economy.py check` passes after a `pin` that only
   drops the pen keys (`pen_rates`, `pen_level_rate`, `offline_cap_h`); every other check result equals the run before FA.

**Studio (2026-11-06, before U1):** 1, 2, 3, 4, 5 passed (both live profiles were safe: Lekzdrh converted, AhojRupert 0 penned pets);
6 field part passed through the real UI (harvest, plant, move and lift a field pet, incubator panel); `economy.py check`: only the drift
check differs (the three pen keys). **After U1 (2026-11-06):** 1 and 2 again (no errors on server or client, no pen remotes or scripts);
8 passed (`loc.py check` 0 errors, lint 0; `economy.py check` 48 / 48 after the pin); 6's rest through the real UI (Feed on a resting
pet's page, a Berry at the food stand, Unequip / Equip, Sell with two taps); the profile restored from `profile_9892673032_FA_3` and
checked equal. 7 is code-only (the same path admins always took).

### U2 — Garden button with badge, summary bubble over the own sign (design: [UI_GARDEN_PETS.md](UI_GARDEN_PETS.md) §3 Far, §8; scope approved by the user 2026-11-06)
**Goal.** A kid anywhere in the game sees that something waits in the garden and gets there with one tap; at the garden they see what
waits without opening a panel. Client only: no remote, profile or config change (`GoGarden` as today).

**Build.**
- **🌱 Garden button** (`GardenButton`) in the top-left icon row after Pets: Home, Skills, Pets, Garden, Settings, Admin. Made in
  `ButtonHandler` as a clone of the Skills button like the Pets fallback (no Studio change), a wood brick (the garden's colour: Garden panel, plot signs; green is the Pets icon), the 🌱 glyph only.
  A tap fires `GoGarden` (HomeService, as today); without a plot yet (`GardenPlot` attribute missing) a toast "Your garden plot is not ready
  yet" and nothing is fired. The Pets panel loses its `Garden` button (wide layout and the compact 🌱 brick at the end of the filter row);
  keys `pets.garden` / `pets.gardenNotReady` go, the toast gets a `garden.*` key.
- **Badge** on the Garden button: a red pill with the number of ripe crops + ready eggs (none at 0), a pulse when the number rises.
  `Hints.SetBadge(target, count)` beside `SetDot` (re-attached after a respawn like the dots). G1's egg dots go: `PetsGarden` (button gone)
  and the egg dot on the Pets icon (the badge says it now; the Pets icon keeps no garden signal). The toast and the "Ready!" marker over the
  incubator stay.
- **Counting** (new ModuleScript `GardenSummary.luau`, used by the badge and the bubble): from the owner's field state (`GardenRemotes.State`
  `field.squares`: crop, grown, readyAt), which `GardenView` now also keeps (`GardenView.OwnField()`), and the own plot's eggs
  (`GardenView.OwnState()`). A square is ripe when `grown ≥ growSeconds` or `readyAt ≤ GetServerTimeNow()` (the server settles before a
  harvest, so it can be picked); next = the smallest `readyAt` still ahead; an egg is ready when its `readyAt ≤ now`.
- **Summary bubble** over the own plot's name sign (client-drawn, only the own plot, independent of GardenView's detail level): one pill
  `🧺 4 ripe · ⏱ 2:14 · 🥚 Ready!` with only the parts that apply (ripe > 0; something growing → time to the next ripe crop; an egg ready);
  nothing planted (no crop on any square) → `🌱 Plant seeds` (with `· 🥚 Ready!` if an egg is ready). Updated once a second from
  `GetServerTimeNow`. Shown while the character is within 120 studs (horizontal) of the sign **or anywhere on the garden's central plaza**
  (inside plot ring 1); a constant on-screen size (pixels, not studs), `AlwaysOnTop` (changed while building: without it the food
  stand and the follower pets' labels hid it from the plaza; captures do not show it, so it is checked by its properties). Texts through `Locale` (plural for the ripe count), re-rendered on `Locale.Changed`.
- Not in U2: the Near tier's rings, other players' bubbles, the crow forecast in the bubble (U4), G1 markers pointing at the own plot.

**Acceptance checks** (Studio, through the real UI; live profile snapshotted before anything that changes it, restored after).
1. Code: `grep -E "PetsGarden|gardenButton|pets\.garden"` over `src/` and `localization/` finds nothing; the Pets panel (wide and compact)
   has no gap where the button was; no Studio-only change needed.
2. Button: in the row after Pets, same size / look as the others, back after a respawn. A click on the real button from the hub puts the
   character ≤ 10 studs from its plot's `GoGarden` arrival point (floor space (8, 0, −30)); with `GardenPlot` cleared on the client it shows
   the toast and `GoGarden` is not fired.
3. Badge against the real state: the number equals the server's count for the live profile (squares with `Grown ≥ growSeconds` after a
   settle + incubators with `ReadyAt ≤ now`); display-only fixtures (a `State` / `Plot` message fired to the client) for 2 ripe + 1 ready egg
   → "3", 0 → no badge, 12 ripe + 3 eggs → "15"; a harvest through the field prompt lowers it by 1 within 2 s; the Pets icon shows no egg dot.
4. Bubble: over the own sign only (no other plot has one); fixtures: ripe + growing + ready egg → all three parts; only growing → only the
   time, equal to the Garden panel's time of the soonest square (± 1 s) and ticking each second; nothing planted → "🌱 Plant seeds"; nothing
   planted + ready egg → both. Shown at 110 studs from the sign, hidden at 130 studs off the plaza, shown at the plaza's centre and its far
   edge, hidden in the hub; readable in a capture from the plaza.
5. Phone: at 667 × 375 and 844 × 390 the six icons fit without overlapping the score panel or the coin counter; the Garden button is ≥ 44 px
   at scale 1 and ≥ 36 px on screen; the badge does not cover the neighbouring icon.
6. Texts: English, Czech and the pseudo-language: bubble and toast with `TextFits`, no literal; `loc.py build` / `check` (0 errors) / `lint`
   (within baseline).
7. A playtest boot without errors or warnings on server and client.

**Studio (2026-11-06, live profile Lekzdrh; snapshots `profile_9892673032_U2_1` (unused) and `_U2_2`, restored after the harvest and
checked equal):** 1–7 passed. 1: grep clean; Pets panel wide layout without a gap (compact reviewed in code). 2: the real icon from the
hub → 0.0 studs from the arrival point; `GardenPlot` cleared → toast, no teleport. 3: live 9 ripe + 0 eggs = badge 9 (later 3 + 1 = 4);
fixtures 3 / none / 15 / 1; a harvest at square 16 → 4 → 3 within 0.3 s (the prompt triggered with `InputHoldBegin/End`: the MCP's E key
and a click on the prompt UI did not reach it, and at square 2 the E prompt shown was incubator 1's — the overlap U3 removes). 4: every
part combination, ticking, = the Garden panel's time; shown at 110 studs and on the plaza's far (178) and side edges, hidden at 125 /
130 off the plaza and in the hub; seen in a capture with `AlwaysOnTop` off. 5: by geometry (icons end at x 360; at 667 px the score
panel starts at 405, the coins at 504; the badge stays 4 px clear of the next icon). 6: cs / en / qps, bounds = size (`TextFits`
misreads AutomaticSize labels); no literal; loc check 0 errors, lint 0. 7: no warnings or errors (both boots).

### U3 — Field interaction: rings, tap-select, square card, hand bar, pet reach (design: [UI_GARDEN_PETS.md](UI_GARDEN_PETS.md) §3 Near, §4, §5, §10; scope 2026-11-07, approved by the user with the split, U3a first; U3a and U3b built and Studio-checked 2026-11-07)
**Goal.** On the own field a kid sees what grows and what is ripe without opening anything, and acts on exactly the square under their
finger: no prompts competing at a 5.5-stud pitch. **No remote, profile or config change:** the client keeps firing `Plant(square, crop)`,
`Harvest(square)`, `BuySquare(square, openCount)`, `PlacePet(square, uid)`, `LiftPet(uid)`; `GardenField` keeps every check (own plot from
the caller, 45-stud distance, open / occupied / ripe / seeds / Renown / Coins, the 0.2 s rate limit).

**Split** (approved; each ships alone; U3a first because removing the prompts needs the card to replace all of them):
- **U3a — see and select:** rings, tap-select + outline, square card with every context button (it alone replaces the prompts), the
  prompts removed, locked squares' look, the pet label with job icons.
- **U3b — the hand:** hand bar (Seeds / Basket / Pets / Look), lifting a pet with its reach following the pointer, the pet reach borders in
  rarity colours, the next-step hint on the bar, the pet page buttons (if they fit).

**Build (U3a).**
- **Code layout:** a new LocalScript `FieldHand.client.luau` owns the tap, the selection outline, the card (and in U3b the hand bar and its
  pickers); a new LocalScript `FieldRings.client.luau` draws the rings. `GardenView` gains `SquareCFrame(square)` (centre of an own
  square, world) and `SquareAt(position)` (world point → own square number or nil, by the plot's grid, locked squares included).
  `FieldClient` keeps the HUD Field button, the Garden panel (U4 removes it), the toasts and the notices; it loses `GardenView.OnSquare`,
  the seed / pet pickers (they move to `FieldHand`), the test hooks `OpenPicker` / `OpenPetPicker` and the 3 s reach tint after a place.
  `PlotView` loses `prompt` use on squares (`PetPrompt`, plant / harvest, `buildLock`'s buy) and `onSquare`; incubators keep their prompts.
- **Rings** (own plot only, ≤ 36 BillboardGuis, one per planted square, built once per square and only re-filled each second from
  `GetServerTimeNow`): shown while the character is within 30 studs (horizontal) of the nearest field square, else hidden. A circular track,
  a pie that fills with `grown / growSeconds` → `readyAt`, the crop icon in the middle. Ripe (`readyAt ≤ now` or `grown ≥ growSeconds`, as
  GardenSummary): full green ring, a ✓ badge and a small bounce (a tween of the GUI, not of the billboard). The 4 **growing** squares nearest
  the character also show the time left under the ring (`2:14`). Not `AlwaysOnTop` (crops / pets may hide them; captures must show them).
  Size in studs so neighbouring rings do not cover each other from the default camera.
- **Tap / click** (`TouchTapInWorld` on touch; `MouseButton1` press + release within 0.3 s and 8 px on a mouse, ignoring
  `gameProcessed`): ray from the camera through the point, include-filtered to the own plot's view, else the plot floor's plane → `SquareAt`.
  Only while the character is within 40 studs (horizontal) of the own plot centre (the server allows 45). A tap on a square selects it
  (white outline: four thin strips just above the soil, no shared face), a tap on the same square again or off the field closes the card.
- **Square card** (ScreenGui `FieldHandGui`, `ZIndexBehavior = Sibling`, slides up from the bottom, above the Field button, width
  min(400, screen − 2 × 110) so it never reaches the thumbstick or the jump button on touch): crop icon + name (or "Empty soil" / "Locked
  square"), a progress bar with the time left inside (ripe: full, "Ripe!"), the growth boosts that apply (Growth upgrade %, Cloches %),
  chips for the field pets whose reach covers this square (portrait + 🌱 / 🛡 icon and level; a tap opens that pet's page through a new
  `PetsGui` attribute `OpenPet` = uid) with one line per pet ("Mochi harvests ripe crops here while you are away: 48 %" from
  `PetConfig.Strength`, "Rex chases crows here: 70 %" from the guard chance), and the context buttons (≥ 44 px):
  - empty: **Plant** (seed picker: seeds held with count and grow time, ≥ 44 px rows; no seeds → hint + "Seed shop" opening the Garden
    panel's seeds as today) and **Place pet** (pet picker as today's, Tending / Pest-control pets with job levels and reach count);
  - growing: **Place pet** / **Move pet** (the pet picker); ripe: **Harvest** (+ the pet button);
  - a square with a pet: **Move pet** (pet picker for this square) and **Take back** (`LiftPet`);
  - locked: price + Renown of the next square (the server opens the tapped square), **Buy square**: green when affordable, two taps over
    1 000 Coins ("Tap again", orange, 3 s, §10's confirm pattern), grey with the reason (Renown / Coins) when not.
  The card re-renders on every `State`, on `PetClient.Changed` and `Locale.Changed`; closes when the character walks > 40 studs from the plot.
- **Locked squares** (every plot, full / mid detail): overgrown, i.e. two or three grass tufts on the grass plate (anchored, CanCollide /
  CanTouch / CanQuery off), no price in the world; the price shows only in the card.
- **Field pet label** (every plot): the pet's given name (only if named) and the job icons `🌱4 🛡2`; no level, no tier stars, no kind
  name. Pets without a name show only the icons.

**Build (U3b).**
- **Hand bar** (in `FieldGui`'s neighbour `FieldHandGui`, visible only while the tap range applies): four 52 px bricks `🌱` `🧺` `🐾` `✋`,
  the active one raised and outlined; a 2 × 2 block right-aligned above the jump button on touch (`UserInputService.TouchEnabled` and
  no keyboard), a row bottom-right on a mouse. Look is the default and is restored on leaving the range.
  - **Seeds:** a tap on 🌱 opens the seed picker; the chosen seed shows on the button with its count; every tap on an empty open square
    plants it (taps spaced ≥ 0.25 s on the client, so the 0.2 s server limit never drops one); out of seeds → back to the picker; a tap on
    a non-empty square selects it as in Look.
  - **Basket:** every tap on a ripe square fires one `Harvest`; a pop `+1 🌽` rises from the square for 1 s. Other squares: select. **No
    harvest-all, no drag-to-harvest** (the paid Wheelbarrow, D2).
  - **Pets:** a tap on a square with a pet lifts it into the hand (client only; the pet stays placed on the server until dropped); its reach
    is tinted yellow on the square under the mouse (mouse) or on the last tapped square (touch); a tap on a free open square drops it there
    (mouse: one click; touch: the first tap previews the reach, a second tap on the same square drops = `PlacePet`); a tap on 🐾 again or
    on the pet's own square cancels. A tap on a free square with nothing in hand opens the pet picker for it.
  - **Look:** a tap selects + card (U3a).
- **Reach borders** (own plot, Near tier): every placed pet's reach as a soft border (thin strips along the outer edges of its region,
  collinear edges merged, rarity colour, `Transparency` 0.3) where the region = the squares this pet counts for under the server's rule
  (strongest Tending per square; strongest guard per square; ties to the lower uid). At most one border strip per square edge per pet.
- **Next-step hint:** nothing planted and seeds held → the 🌱 button pulses; something ripe → 🧺 pulses (G1 style, stops on use).
- **Pet page:** "Place on field" (a resting pet with Tending or Pest control while the hand bar is shown: closes the Pets panel, Pets mode
  with this pet in hand) only if it fits the pet page's More menu cleanly; "Show on field" is not built (recorded as left over).

**Acceptance checks** (Studio, through the real UI where it says so; the live profile snapshotted right before anything that changes it,
restored after; display-only fixtures = a `State` / `Plot` message fired to the own client from the server context).
1. **Code:** `grep -E "PetPrompt|onSquare|OnSquare|buildLock|field\.prompt\.|OpenPicker|OpenPetPicker"` over `src/` finds nothing; the
   own plot's view holds no `ProximityPrompt` except the 3 incubators'; removed keys are gone from `strings.csv`.
2. **Rings:** live field → one ring per planted square and none on empty / locked ones; fixture 36 planted (mixed ripe / growing) →
   36 rings, the ripe ones full with ✓, exactly 4 time labels, on the 4 growing squares nearest the character, each equal to the card's time
   (± 1 s) and ticking; rings hidden at 32 studs from the nearest square and shown at 28; no ring over another plot.
3. **Performance:** with the 36-ring fixture the per-second ring update takes < 1 ms (os.clock around it, 10 samples) and builds no new
   instances after the first second (`Instances` count stable for 10 s).
4. **Tap and card (real clicks in the viewport):** a click on square A selects A (outline on A only), a click on its neighbour B moves the
   outline, a click on B again closes the card; a click on another player's plot or beyond 40 studs selects nothing. Every card state
   checked: empty, growing, ripe, with pet, locked (affordable / too few Coins / Renown short): title, bar, boosts, chips, buttons.
5. **Every card button through the real UI** (live profile, snapshotted): Plant (picker → crop) plants that square; Harvest harvests it
   (Garden badge −1); Place pet places the picked pet; Move pet moves it; Take back lifts it; Buy square with two taps opens the tapped
   square and takes the price once; a pet chip opens the right pet page.
6. **Server rejection** (remotes fired from the client context): `Plant` / `Harvest` / `BuySquare` / `PlacePet` with square 0, 37, −1,
   1.5, a string, a locked or occupied square → rejected (the matching reason or ignored), profile unchanged; the same from 60 studs away →
   `far`; a square id used while standing on a neighbouring plot acts only on the caller's own field.
7. **Hand modes (U3b, real clicks):** Seeds: pick Corn, three quick taps on three empty squares → three plantings, count −3, none dropped;
   tap on a growing square selects it. Basket: tap a ripe square → one harvest + pop; tap a growing one → card, no harvest. Pets: lift a
   placed pet, its reach follows the mouse, drop on another square → moved there (server state); cancel restores; free square with nothing
   in hand → pet picker. Look: back to the card. Leaving the range resets to Look and hides the bar.
8. **Borders and labels:** two placed pets with overlapping reach → each border in its rarity colour around the squares it counts for
   (equal to the server rule computed in the Server context); every plot's field pet label shows only name + job icons (no "Lv").
9. **Phone** (Studio device emulator, 667 × 375 and 844 × 390, touch): hand bar buttons ≥ 44 px on screen, the bar does not overlap the
   jump button, the thumbstick, the Field button or the card; the card's buttons ≥ 44 px; a tap in the world selects (TouchTapInWorld);
   record whether squares are easy to hit from the default camera (the field camera button is built later only if not).
10. **Texts:** English, Czech and the pseudo-language: card, pickers, hand bar, pop with `TextFits` (or bounds = size) in Czech, no
   literal (no `[!!` missing in qps); `loc.py build` / `check` (0 errors) / `lint` (within baseline).
11. **Multi-client** (only if the user starts F7 with 2 clients): neighbouring plots each show rings only over their own field; a tap on
   the neighbour's field selects nothing.
12. A playtest boot without errors or warnings on server and client.

**Changed while building U3a.** "Move pet" arms a move: the next tap on a free open square places the pet there (U3b's Pets mode replaces
it); the card's "Take back" replaces the old picker's Lift row. Rings sit 1.3 studs above the soil and 3 studs toward the camera
(`StudsOffset` Z; at 4 studs up they read as one row further back), disc 2.3 studs. Locked squares carry three tufts on every plot
(signature `lock|<own>`), `CanQuery` only on the own plot (as the row plates, soil and crops: the tap ray hits only the own field).
`FieldHand` / `FieldRings` read `GardenView.OwnField()` at start (the first `State` may arrive before they connect). Test hooks: `FieldHandGui`
attribute `Select` (square), `FieldRings` attributes `Rings` / `UpdateMs`. Removed keys: `field.prompt.*`, `field.petPicker.lift*`,
`pets.tending`.

**Studio results U3a (2026-11-07; live profile snapshotted as `profile_9892673032_U3a_1`, restored and checked equal after).**
1 ✔ (grep clean, only incubator prompts, no duplicate scripts after the Argon sync). 2 ✔ live 9 rings; fixture 36 rings, 7 ripe with ✓,
exactly 4 time labels on the 4 nearest growing squares, ring time = card time ± 1 s; shown at 28 / 29.5 studs, hidden at 30.5 / 32.
3 ✔ update 0.13–0.15 ms, instances stable at 756 for 10 s. 4 ✔ real clicks: select, neighbour moves the outline, same square closes,
60 studs away / neighbour plot select nothing; empty, growing, ripe, with pet and locked cards checked. 5 ✔ every button through the real
UI: Harvest, Plant → Potato, Move (next tap), Take back, Place pet → picker, the pet row opens its page, Buy with two taps (9 136 → 5 136,
charged once). 6 ✔ squares 0 / 37 / −1 / locked → `square`, 1.5 and "2" ignored, occupied / empty / notripe / open as expected, 60 studs →
`far`. 7 / 8 U3b. 9 open: geometry only (the 400 px card at 667 wide spans x 133–533, clear of the jump button and thumbstick; buttons
48 px); `TouchTapInWorld` and how easy squares are to hit on a phone are untested (no touch emulation through the MCP): the user or MU.
10 ✔ en / cs / qps fit, no literals; `loc.py check` 0 errors, lint within baseline. 11 not run (F7). 12 ✔ no game errors.

**Changed while building U3b.** The card's Move pet takes the pet in hand (Pets mode) instead of waiting for a tap; its Cancel button and
`field.card.cancel` are gone. Every field remote (the card's too) goes through one queue ≥ 0.25 s apart; plantings / harvests still on their
way count against the seeds and are not sent twice (3 s). "Place on field" sits under More next to Sell and also shows for a pet already on
the field (it moves it); "Show on field" is not built. The pop rises over the square (no barn to fly to before U4). Borders are flat
(SmoothPlastic), not Neon: Common grey glowed white like the select outline; strips extend at inner corners. The hint line is a fixed
300 × 40 box (AutomaticSize left a wrapped hint one line high). Pulse rule: a mode's pulse stops for the session once the mode was chosen.
Added after the first U3b commit (the user, 2026-11-07: would a player know to tap a square?): corner brackets on the square the character
stands on and Look's hint "Tap a square to see it" until the first tap on a square in the session; a hover outline for the mouse and the
other tap signals (rings, pulses) are left for a later talk. A full thin outline was tried first and looked like a Common pet's border.
Then (the user): the brackets follow the square under the mouse with a pointing-hand cursor (the stand-on square when the mouse is off
the field, always on touch), and the hint sits 12 px above the bar; checked by the user in Studio.
Studio: the brackets follow the character (on square 9: centred on it), give way to the select outline on the selected square; a real
click on square 3 opened its card and hid the hint; the hint fits in Czech; no errors (no profile write in this check).

**Studio results U3b (2026-11-07; live profile snapshotted as `profile_9892673032_U3b_1`, restored after and checked equal; MostStars 48
unchanged).** 7 ✔ real clicks: Basket, two quick taps on ripe squares 1 and 10 → both harvested (badge cleared, toast); Seeds → picker
→ Corn, quick taps on 1, 10 and growing 3 → two plantings (Corn 3 → 1, none dropped) and 3's card; Pets: tap the pet on 4 → in hand (outline,
hint), the reach tint followed the mouse to 9, a click on 9 moved it there (server state 3@9, its border moved); picked again, 🐾 cancelled;
free square 2 with nothing in hand → pet picker; Look → card; the card's pet row → pet page → "Dát na pole" → panel closed, pet in hand,
dropped back on 4 (3@4); 70 studs away → bar hidden, HandShown false, back → Look. Pop: a Harvest result fixture showed "+1 🌽" over the
square, removed after 1 s. Basket pulsed while 1 and 10 were ripe. 8 ✔ live borders around 4 (Uncommon green) and 1 (Common grey, lane 1);
fixture of 4 pets with overlapping reach and a tie: the regions match GardenField's strongest-per-job values on every square, the tie went
to the lower uid, borders side by side in lanes, inner corners closed (captures U3b_10 / U3b_12). 9 open: the touch layout (2 × 2 above the
jump button, card kept clear of it) is by geometry only; the two-tap drop on touch is untested. 10 ✔ every hint fits the box in en and cs
(≤ 2 lines); "Dát na pole" fits its brick; `loc.py check` 0 errors, lint within baseline. 11 not run (F7). 12 ✔ no game errors on server
or client.

### E0 — Economy model
**Goal.** One reproducible model of the Coin economy (`tools/economy.py`, Python stdlib; how to run it: ECONOMY.md) that fixes the numbers the
garden needs, proves GDD §6 and the EXPANSION §5 guardrails with crops, and re-prices every Coin sink. No game code in E0; approved prices are
applied in **E0b** (GDD first, then the configs, then `loc.py` if a price is in a text, then a Studio check of the shops; nobody is refunded or
charged again).

**Done:** loader + pins for every config number, the GDD figures reproduced, a 60-day simulation of four archetypes × two purchase policies,
the crop field and the re-runs that gated E1b (field pets), E1c (tools, cart), E1d (farming first), E2 (obby seeds), E4-thin (crows) and the
offline-growth change; `check` 52 / 52. What it showed: pet levels saturate within days (one reason for the aptitudes), the existing sinks run
out within weeks, and sinks absorb only part of the faucet by day 60 until the landmark / estate sinks exist.

**Still to do:** repricing (a table old → new price with time-to-afford per archetype, for the user's approval), the no-dead-end, rare-supply
and sensitivity checks, later the EXPANSION pieces (fertilisers, variants, the Spender archetype). Food prices were not scaled with F2, so pet
levels are cheap against field income (for the balancing pass).

**Acceptance checks** (`python tools/economy.py check`; the numbers are the ones ECONOMY.md uses): 1 drift 0 against the pins; 2 the GDD
figures reproduced; 3 GDD §6 required-set shares ≤ 65 % with garden income off; 5 guardrail B (Tending pets earn strictly more); 6 guardrail
C (sink share); 7 no dead end (the next required talent affordable without garden income); 8 rare crops cover the first landmark within 14
days for Casual and are zero without obby runs; 10 repricing inside each archetype's band (beyond ×2 / ÷2 flagged); 11 sensitivity ±20 % (a
parameter that flips a guardrail is flagged for M6a telemetry); 12 size-roll mean and shares; 13 crop XP ≤ sale × Berry's XP per Coin; plus
the farming-first parity / lead checks, which replaced guardrail A (the 24-hour rule) on 2026-11-02.

**Open decisions:** the sink share (proposal 60 % by day 30, 80 % by day 60); the time-to-afford bands; the size of the placeholder sinks.

### MU — Mobile UX check (scope when it starts)
Pawvest is **mobile-first** (decided 2026-10-24). A checklist on a real phone and the Studio device emulator, before anything goes public and
before M7: touch layout of every panel and popup at phone sizes, tap targets, safe areas, Czech text length, touch controls for the kit and
talents (the Dash button was never tried on a phone), performance on a mid-range phone (pets, a full garden; no phone number yet), the first
minutes, the T1a platform split. The phone layouts of the field panel, the pet page and the cart were not checked in Studio.

### Later milestones (scope when they start)
- **M6b — Final balancing:** measured `T_base` per stage from telemetry, tuned numbers in GDD and the configs; GDD §6 table still all ✔. Known
  items: the repeat-reward floor (a Tutorial loop pays ~1 400 Coins / h), pet bonus values, slot prices, the Basic egg's 5-minute hatch, food
  prices against field income.
- **S9 / S10 — Wall Jump + Glide, World 4** (STAGES §8), drop D8; re-check World 4's star bar (World 3's tighter Silver / Gold make 10 of 15
  stars harder).
- **S11 — Bonus stages** (STAGES §5.3); the farm stages (EXPANSION §8.2) may use this slot.
- **Trading:** first profile session locking (`UpdateAsync` with a `{ JobId, Time }` lock); then an atomic two-sided swap with confirmation,
  immediate saves and a trade log (GDD §7.7). Open whether to do it at all (EXPANSION §16).
- **M7 — Monetization:** comfort only (no paid random items, luck and weather never sold; EXPANSION §13), drop D2.

## Open items from finished work
- **For the live test (M6a):** several real players at once (others' plots, pets, coins; checkpoint pads only for their own player); two servers
  at once (boards and `MostStars`); gate prompts on a locked stage; a real 1-hour Golden egg and the inventory cap with free eggs waiting; every
  telemetry event type on the Creator Dashboard (only then T1 is live-validated); a pet name the filter changes shows as `####` (Studio does
  not filter text).
- **Before Max Players 24 (going public):** 24 plots with fields at once (the budget was checked with synthetic plots only); a second client
  watching a square purchase. (The no-field paths and the live pen conversion went with FA.)
- **The user's checks:** World 3 sign-off (S8); G1 hints in play.
- **Localization:** Czech overflow screenshots of the panels (the font is BuilderSansBold, so re-check widths in Czech and the
  pseudo-language), the Stage 9 exit-door label.
- **Not built:** the pet page's "hatched on … from a Basic egg" line (`Born` / `Egg`).
- **Housekeeping (Studio):** delete `ReplicatedStorage.StageTimerStopped` (unused).

## Done
What was built and why, newest first. Details: the design docs and git history.

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
under six segments replaying World 3). The user ran all five with Gold; medal times were set from those runs (Bronze 2.5 × tBase for every stage).

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
- **UI sounds:** the Creator Store creator SodaBreadle has many short free UI sounds (`UI - Level Up` is already `ReplicatedStorage.PetLevelUpSound`);
  use them for hover / click / panel open / buy result through a shared client module with one Studio-only `Sound` per cue, so the code works
  when a sound is missing. Find them via the creator's page (a keyword search does not list them); check licence and length.
- **Blink music:** a real track with its BPM instead of the metronome (S4).
