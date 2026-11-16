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
| EV | Engagement-first economy: EV1 model, EV2a numbers, EV2b talent bundles | EV1–EV2b ✔; EV2c–f open | EV2a, EV2b ✔ | – |
| EV3 | Crop levels replace Renown, milestone quests, crop upgrades, first-hour obby payouts | EV3a model built; awaits sign-off | – | – |
| E1.0, E1a–E1d | Client-drawn plots; crop field (every player's since FA), field pets, crops as pet food, size roll, upgrades, tools, market cart, 36 squares | ✔ | ✔ | – |
| E2, E4-thin | Obby seeds (rare crops, meters, pouch, Scouting); crows and Pest-control guards | ✔ | ✔ | – |
| OG | Offline crop growth 0.5 / 24 h | ✔ | pending | – |
| FA | The field for everyone, pens removed | ✔ | ✔ | – |
| U1–U5 | Garden / pet UI: pets panel rows, garden badge + bubble, field rings / square card / hand bar, panel split (Skills Garden tab, Barn, seed stall), plot layout + hatchery panel | ✔ | ✔ (physical touch and multi-client open) | – |
| MU1 | Responsive HUD navigation and panels | ✔ | ✔ (phone emulation) | – |
| CG1–CG21 | Plant growth art, 19 crops ([status per crop](PLANT_GROWTH.md#crops-and-status)) | 18 in the field; Sunflower a draft (CG20c next) | geometry + PlotView checks pass; stills of Tomato, Pepper, Pumpkin await review; performance, real phone and second client open for most | – |
| HX0 | Hybrid plants: look prototype (Studio reviewer only) | ✔ | ✔ (look approved 2026-11-16) | – |
| HX1 | Hybrid plants: breeding mechanic design ([HYBRIDS.md](HYBRIDS.md)) | main rules decided 2026-11-16; numbers and rules open | – | – |
| TH | Store thumbnails ([THUMBNAILS.md](THUMBNAILS.md) §8–9) | logo; release candidates A1, A2, A3, C1, C2, C3; B1 parked until D1 | stud sign decision, grid tile test, kid test open | – |
| E5 | Garden MVP rest: request board, ledger on join, onboarding, garden telemetry | – | – | – |
| M6a | Soft launch + World 1 balancing (balanced by feel 2026-10-30; live test open) | – | – | – |
| MU | Mobile UX check | – | – | – |
| S9, S10 | Wall Jump + Glide, World 4 (drop D8) | – | – | – |
| M6b, S11, M7, trading | Final balancing, bonus stages, monetization (drop D2), trading | – | – | – |

## Next
**Order (2026-10-30, updated 2026-11-06 and 2026-11-14).** The soft launch takes the obby (15 stages) and the garden as built: since FA
(2026-11-06) every player has the crop field, so the rest of the garden MVP (EXPANSION §14) is built in the open game. World 4 waits until
after the MVP.

1. **M6a soft launch** (friends, then unlisted) with 15 stages, pets and the garden: real finish times, T1a / T1b on the Creator Dashboard
   and a first retention baseline (the obby-only baseline is dropped: the garden is in from the start). Includes the live-test checks under
   "Open items". The store page needs **TH** before going public; an unlisted soft launch can start without it.
2. **Offline growth (OG) validation:** a 24 h-back `SettledAt` must give `Grown` = 43 200 for a pumpkin (ripe at 28 800). The same test
   explains the user's pumpkin that still had 5 h 47 min left after 24 h away (at most about 4 h was expected under the old 0.33 / 12 h rules).
3. **EV3** sign-off, then EV3b (fixes the first hour) and EV3c; EV2c–f each scoped when it starts (section below).
4. **E5 + rest of the garden MVP** (scope when it starts; EXPANSION §14): request board, the ledger on join (the join notice grows into it),
   onboarding for the first ten minutes (it teaches the U1–U5 controls), garden telemetry. Before going public Max Players goes to 24 (a
   place setting) and "Before Max Players 24" under "Open items" is checked.
   **Gates before going public:** M6a, the balancing pass, the Czech review of the new texts, MU, TH1 + THU, EV3 (no Renown in the first
   hour), an online loop from day 2 (requests, E5), and the comfort shop (D2) or a decision to launch without it. Whether the content horizon
   (~5 days for a heavy player) is a gate too: ECONOMY.md → open decision 6.
5. **MU** before anything goes public.
6. **Drops D1–D10** after the MVP (EXPANSION §14), one every 1–2 weeks: Critters, Comfort shop (M7), Weekly, Variants, Kitchen (the first
   restoration landmark), Neighbours, Mastery, World 4 (S9 / S10), the Estate, Season 1. Restoration bundles (E6, D5) and estate tiers / decor /
   cottage (E7, D9) are the long-term Coin sinks; the model holds a placeholder for their size until they are designed.

**Alongside:** plant growth art (open crops and checks: [PLANT_GROWTH.md](PLANT_GROWTH.md#crops-and-status); review = five snapshots, no
animation capture), HX1 (design only), TH.

### K1 — First-hour fixes, open part (kid playtest 2026-11-01)
A 9-year-old on a phone, fresh progress, got stuck after about 20 minutes. Target: a new player who does not pay always has a next step for
the first hour; World 1 and the garden are tuned for 8–10 year olds on a phone. Seen: signs and banners are not read (the GDD §11 rule
"without reading anything" holds), too much text at hatching (fixed by U5b's egg cards and reveal), Coins spent elsewhere so World 2 stopped
him. Done: see "Done" → K1.
- **World 2's star bar** stays at 10 of 15 until the wider test (the user, 2026-11-01); a checkpoint inside Stage 5's tightrope: not now
  (telemetry first).
- **Key talents as world rewards:** done for Double Jump (GDD §6). Open: Triple Jump / Long Dash for World 3 — since EV2b Triple Jump
  (World 3's hard gate) needs farm crops, so a kid who ignores the garden is blocked. The lost Coin sinks are made up in the balancing pass.
- **Measure it in M6a:** T1a fails per segment on Stage 5, quits per stage, session length of new players; whether the faster first pet
  level-ups (20 levels since 2026-11-12) feel right.

### EV — Engagement-first economy, open parts
Rules and targets: [ECONOMY.md](ECONOMY.md) → EV. **Decided (the user, 2026-11-07):** talents cost Coins + a crop bundle (built, EV2b); a
crop ladder from ~10 s to 24 h (built, EV2a); repeat obby runs pay **drops** (Sunshine, rare seeds) instead of Coins; eggs are **rolled at
purchase** and the rarity sets the hatch time; a semi-random request board (crops and sometimes a timed run); a 7-day streak with an Epic+
pet on day 7; perennials; free play scarce enough that comfort products are worth buying (headroom 1.2–1.5×). Rebirth is evaluated by the
model, not decided. Long term (recorded only): gifts / buying for a friend, a pet auction, quests.

Still to build, each scoped when it starts: **EV2c** Sunshine (repeat-run Coins → 0), **EV2d** Scouting XP (today 15 min of XP per medal
finish against 10 h for level 2), **EV2e** eggs rolled at purchase, **EV2f** field pets (Tending as growth speed, guards make their squares
safe, crows scale with the field: a mechanics change the model assumes). Trees, requests and the streak come with E5 / the drops.

### EV3 — Crop levels replace Renown; milestone quests; crop upgrades; first-hour obby payouts (draft 2026-11-14; awaits sign-off)
Why, direction and rules: [ECONOMY.md](ECONOMY.md) → "EV3 — design draft"; findings and what to sign off: ECONOMY.md → Findings (EV3a) and
open decision 4.

**EV3a — model (no game code).** Built 2026-11-14: `economy_ev.py` with `CAND["mode"] = "stars"` (`"renown"` = as built) simulates crop XP,
levels, unlocks, milestone quests and point spending; `evcheck` 18 / 18 (G10–G12 and U added); `economy.py proposal` prints the EV3 tables.
Acceptance: the user signs off the thresholds, caps, quests and bands.

**EV3b — levels, unlocks, Renown out (scope after EV3a's review).** Fixes the first hour.
1. **Config:** `CropConfig` crops get level thresholds and, for milestones, `quest = { [cropId] = n }`; the `renown` gates of `Expansions`,
   `Upgrades`, `Tools` go (prices stay); `RenownK` / `RenownP` / `points` go; `StageConfig` payouts + seed packs.
2. **Server:** `Garden.Crops[cropId] = { XP }` and `Garden.Unlocked` (IdSet; stored ids never reused); harvest adds XP and unlocks the
   next crop at ★1 (answer `{ …, cropLevel, levelUp, unlocked? }`); `GardenRemotes.Quest(cropId)` at the seed stall takes a milestone bundle
   (all or nothing, reject `crops`); `BuySeeds` checks `Unlocked`; `BuySquare` / `BuyUpgrade` / `BuyTool` lose the `renown` check and reject.
3. **Migration** (`Version = 7`): `Unlocked` = every crop whose old gate ≤ the profile's Renown level (no player loses a crop); crop XP
   starts at 0 (or from `Plantings` if the live profiles show it fair); `Renown` stays as a field, unused. Read the live profiles first.
4. **Client:** seed stall: a locked crop shows the previous crop's ★ bar or the quest `{crop} {have}/{need}` with a Bring button; the
   crop's ★ on the seed row, square card and barn row; a level-up toast "Garlic ★2"; the Renown bar / level go (FieldHand, FieldClient,
   BarnClient, GardenSkills, SeedStallClient); sink tiles show only the price.
5. **Docs and text:** GDD §7.9, PROTOCOL, ECONOMY.md, strings (the `renown` keys removed, new ones with Czech).
- **Acceptance (draft):** `economy.py check` exit 0 (drift 0 after `pin`); `loc.py build / check / lint`; a boot without errors or
  warnings; in Studio (snapshot first) on a fresh test profile Lettuce opens when Potato reaches ★1, the Corn quest done through the real
  seed stall, one refusal for missing crops (nothing taken), a square and an upgrade bought on Coins alone; a migrated live profile keeps every
  crop it could buy; the word Renown nowhere on screen in English or Czech (pseudo-language pass, `strings.csv` grep); the Tutorial's
  first clear pays the new amount and the seed pack; Czech fits on the stall and the square card.

**EV3c — crop upgrades (scope after EV3b; can ship as a drop).** The endgame layer.
1. **Server:** `Garden.Crops[cropId].Pts = { Value, Size, Speed }`; `GardenRemotes.CropPoint(cropId, line)` (free points = level − spent;
   reject `points` / `maxed`); sale, size roll and grow time read the crop's points (grow time settled server-side as now).
2. **Client:** a crop page (from the seed stall row and the barn row): ★ level and bar, the three lines with their dots and the next
   effect, a + per line; the square card's ready time uses the crop's speed.
3. **Docs and text** as EV3b.
- **Acceptance (draft):** model and loc checks as EV3b; in Studio a point spent in each line through the real crop page, its effect
  seen (sale price, size factor, ready time); a refusal without free points.
- **Open:** whether points can be moved later (a reset); whether the crop page shows a collection total (all crops' ★, a garden score).

**Not in EV3:** repeat-run Coins → Sunshine (EV2c); requests and trees (the online loop, E5); a flatter price curve (ECONOMY.md → open
decision 5).

### HX1 — Hybrid plants: the breeding mechanic (design only; added 2026-11-16, not yet placed in the order above)
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
before M7: touch layout of every panel and popup at phone sizes, tap targets, safe areas, Czech text length, touch controls for the kit and
talents (the Dash button was never tried on a phone), performance on a mid-range phone (pets, a full garden, the plant art; no phone number
yet), the first minutes, the T1a platform split. Collected from finished work: the field's tap-select and two-tap pet drop on touch (U3),
whether squares are easy to hit from the default camera (decides the field camera button, UI_GARDEN_PETS §12.4), the hatchery, pet picker
and dialogs on a physical phone.

### Later milestones (scope when they start)
- **M6b — Final balancing:** measured `T_base` per stage from telemetry, tuned numbers in GDD and the configs; GDD §6 table still all ✔. Known
  items: the repeat-reward floor (a Tutorial loop pays ~1 400 Coins / h, until EV2c), pet bonus values, slot prices, the Basic egg's hatch
  time, food prices against field income.
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
  not filter text); the checkpoint respawn fix (2026-11-14) and garden arrival on the published game.
- **Before Max Players 24 (going public):** 24 plots with fields at once (the budget was checked with synthetic plots only; the plant art
  adds up to 6 084 Parts per full field); a second client watching a square purchase.
- **The user's checks:** G1 hints in play; a multi-client test (F7): each client sees the other's pets with their level look (P4 / U1), rings
  only over the own field and no selection on a neighbour's (U3); the stills of Tomato (CG1e), Pepper and Pumpkin.
- **Checked in code only:** the crow part of the summary bubble (`🐦 now` / `🐦 0:45`, U4); the first-harvest toast and the young-field pulse
  (playtest fixes 2026-11-08); the pet page's Feed card with held crops and its Czech width (20 levels, 2026-11-12).
- **Localization:** Czech overflow screenshots of the panels (the font is BuilderSansBold, so re-check widths in Czech and the
  pseudo-language), the Stage 9 exit-door label, the food stand's prompt ("Buy food" is a Studio literal: set its texts from
  `FoodShopClient` as `SeedStallClient` does).
- **Not built:** the pet page's "hatched on … from a Basic egg" line (`Born` / `Egg`); "Show on field" on the pet page (U3b); a "barn full"
  cue in the world and a public shelf of record crops in their grown art (Estate / decor drop).
- **Housekeeping (Studio):** delete `ReplicatedStorage.StageTimerStopped` (unused).

## Done
What was built and why, newest first. Details: the design docs and git history.

**HX0 — Hybrid plants: look prototype** (2026-11-16; as built: [HYBRID_PROTOTYPE.md](HYBRID_PROTOTYPE.md); design: [HYBRIDS.md](HYBRIDS.md)). *Why:* the user's breeding idea (cross two plants into
one that mixes both, crafted mutagens bias a trait, unique to its breeder, visible to visitors) needs generated plants that look good before
any mechanic. *What:* `PlantGenome` (genome v2: 49 genes, cross, mutagens, 49-byte pack, presets for the 19 crops and 8 new plant types),
`GenePlant` (a `Draft` `PlantKit.recipe` from a genome), the reviewer's `OpenCross` / `OpenPresets`; nothing is saved, sent or in the field.
Studio checks: 347 genomes, 122 of them 2×2 (≤ 140 / 400 Parts, 2.38 / 5.13 radius), seeks, proxies; stills in
[art/plant-review/hx0](art/plant-review/hx0). *Decided (Ales):* go, fully parametric (no organ library for now); trees and other big plants
take a 2×2 block, its footprint from the blended `bulk` gene. Next: HX1.

**Hatchery redesign** (2026-11-16; GDD §7.6). Cross-lapped stud egg shells and 3D egg cards, stud-textured foundations, a tall pavilion with
a front prompt, a passive dialog cursor with world-input guards, owner-only nest labels fading at 24–30 studs. Studio-validated; physical
phone touch open. Incubator body concepts: [INCUBATOR_REDESIGN.md](INCUBATOR_REDESIGN.md#incubator-body-follow-up).

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
a choice → five stills → recipe → field registration). 18 of 19 crops grow in the field; Sunflower is a draft (CG20c next). Decisions,
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
