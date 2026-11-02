# Pawvest — Roadmap

Build order and status; "What next?" is answered from here. Design lives in [GDD.md](GDD.md) (the game as built), [STAGES.md](STAGES.md)
(stages), [EXPANSION.md](EXPANSION.md) (the pet-garden direction) and [ECONOMY.md](ECONOMY.md) (numbers). Finished milestones keep only what was
done and why; their scopes, acceptance checks and validation logs are in git history (last full version: `git show aae049d:docs/ROADMAP.md`).

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
| P2 | Pet garden: plots, pens, incubators, food | ✔ | ✔ | – |
| H1, H2 | Hub island, stud checkpoints | ✔ | ✔ | – |
| S1–S7 | Stage framework, Quick Respawn, obstacle kit, World 1, worlds hub, World 2, Triple Jump + Dash | ✔ | ✔ | – |
| S8 | World 3 (Stages 11–15) — awaits the user's sign-off | ✔ | S8.1 ✔; S8.2–S8.3 bot-checked, run by the user | – |
| T1a, T1b | Telemetry | ✔ | ✔ | – |
| L1–L3 | Localization (English + Czech) | ✔ | ✔ | – |
| G1 | Player guidance hints — awaits the user's check in play | ✔ | ✔ | – |
| K1 | First-hour fixes from the kid playtest (2026-11-01) — Double Jump world reward done; Stage 5, G1 fallback, hatch panel proposed | partial | partial | – |
| E1.0 | Client-drawn plots spike: **GO** | ✔ | ✔ | – |
| E0 | Economy model — partial (baseline, simulation, field, field-pet re-run approved); repricing and the rest open | partial | – | – |
| M6a | Soft launch + World 1 balancing — World 1 balanced by feel (2026-10-30); live test open | – | – | – |
| MU | Mobile UX check | – | – | – |
| E1a1 | Plots drawn by the client, new ring layout (garden moved) | ✔ | ✔ | – |
| E1a2 | Crop field behind admin access (CropConfig, GardenField, Garden panel) | ✔ | ✔ | – |
| E1b1 | Field pets, server: aptitudes, Tending, field pet slots, pen conversion (behind field access) | ✔ | ✔ | – |
| E1b2 | Field pets, client: pets on squares, place / move prompt, Pets section, conversion popup | – | – | – |
| E1a3–E5 | Garden MVP (see "Next") | – | – | – |
| S9, S10 | Wall Jump + Glide, World 4 (drop D8) | – | – | – |
| M6b, S11, P3, M7 | Final balancing, bonus stages, trading, monetization (drop D2) | – | – | – |

## Next
**Order (2026-10-30).** The obby (15 stages) is nearly finished and goes out first as a soft launch; the garden MVP follows on the E1.0
architecture and the pet design decided 2026-10-30 (EXPANSION §3–§4, §8.1). World 4 waits until after the MVP.

1. **Close World 3:** the user's sign-off of Stages 11–15 with the new medal times. Stage 10's times stay as they are (decided 2026-10-30:
   the fast test-account times there need every talent, the Long Dash included, so they say nothing about a World 2 player).
2. **M6a soft launch** (friends, then unlisted) with 15 stages and today's pets and garden: real finish times, the T1a / T1b telemetry on the
   Creator Dashboard, and a **retention baseline of the obby alone**, to measure later what the garden adds. Includes the live-test checks below.
3. **E0 in parallel:** the re-run for field pets (it gates E1b), then repricing and the remaining checks (section below).
4. **MU** before anything goes public.
5. **Garden MVP** (EXPANSION §14), milestones of 1–2 weeks, each with its scope when it starts:

   | # | Content | Needs |
   |---|---|---|
   | **E1a** | Plots for real: `PlotView` draws the garden by default, the ring layout for 8-stud gaps (radius 112 / 185, the island grows), the mid pet detail, `GardenRemotes.Plot` replaces the spike feed (EXPANSION §16 migration list). The field: 4 → 12 squares, first crops, seed catalogue and seed stock, selling, light Renown, square prompts and a Garden panel | E1.0 |
   | **E1b** | Field pets: pets placed on squares with reach by level, aptitudes rolled at hatch (live pets once from their uid), Tending auto-replant, pens converted to field pet slots and the Coins-per-hour production removed; garden servers of 24 | E0 field-pet re-run |
   | **E1c** | Size roll, tools tier 1 (Seed sorter, Cloches, Pruning shears), field upgrades (growth, barn), the daily market cart | E1a |
   | **E2** | Seed pouch for medal finishes, rare-seed meter per stage, rare crops of Worlds 1–3 | E1a |
   | **E4-thin** | Crows, Pest-control pets on the field, the forecast line | E1b |
   | **E5 + rest** | Request board, the ledger on join, onboarding for the first ten minutes, garden telemetry | E1b |

   Gates before going public: M6a, the balancing pass, the Czech review of the new texts, MU, and the comfort shop (D2) or a decision to launch without it.
6. **Drops D1–D10** after the MVP (EXPANSION §14), one every 1–2 weeks: Critters, Comfort shop (M7), Weekly, Variants, Kitchen (the first
   restoration landmark), Neighbours, Mastery, World 4 (S9 / S10), the Estate, Season 1. **Spending** grows there: restoration bundles (E6, D5)
   and estate tiers / decor / cottage (E7, D9) are the long-term Coin sinks; E0 holds a placeholder for their size until they are designed.

Key talents as **world rewards** (idea 2026-10-30): **decided for Double Jump on 2026-11-01** (K1: granted when World 2 opens, GDD §6).
Open: Triple Jump / Dash for World 3. The lost Coin sinks are made up in the balancing pass (STAGES §6, GDD §6).

### K1 — First-hour fixes (kid playtest 2026-11-01; proposed, awaiting the user's decisions)
A 9-year-old on a phone, fresh progress on the `Lekzdrh` profile, got stuck after about 20 minutes. Target: a new player who does not pay
always has a next step for the first hour; World 1 and the garden are tuned for 8-10 year olds on a phone.
- **Seen:** the red HUD dot was understood (G1 dot ✔). Signs and banners were not read until an adult pointed at one (the GDD §11 rule
  "without reading anything" holds). Too much text at hatching. He kept retrying Stage 5 and almost quit. He spent Coins on other things
  and never bought Double Jump, so World 2 stopped him and he did not know why.
- **Stage 5 is a wall:** 12-stud gaps at the limit of a single jump, 0.1-stud wires (on a touch stick), about 30 s of replay per death,
  while GDD says World 1 needs no talent. G1 makes it worse: the next-stage marker keeps pointing at the latest open stage without a medal,
  i.e. at Stage 5. And World 2's bar (10 of 15 stars) without Stage 5 means 10 of the 12 stars of Stages 1-4.
  *Done 2026-11-01:* the tightrope wires are 2-stud beams, the nubs as wide (STAGES §1, Stage 5); the G1 stuck fallback (GDD §11:
  3 failed runs or 12 deaths, fall resets included → the lowest-medal stage of the same world, never another world; playtest: after 3 given-up Stage 5
  runs the marker read "Stage 1: Silver"; after the review fixes, faked run events: 3 medal finishes did not count, 2 medal-less finishes + 1 run switch and 12 Quick Respawn fall resets each gave "Stage 1: Bronze"); section 1 rebuilt so it is clearable without talents (the user found it was not): five
  10.5 gaps with a 1-stud climbable lip on every landing plate (STAGES §1, Stage 5), checked by bot without talents. World 2's star bar stays at 10 until the wider test (user, 2026-11-01). A checkpoint
  inside the tightrope: not now (telemetry first). Stage 4 is clearable without talents (user's hand run, 2026-11-01): unchanged.
- **Double Jump can be missed:** World 2 needs it, but nothing makes the player save for it. **Decided 2026-11-01:** a world reward,
  granted by the server when World 2 opens (star bar or bought), with a "new skill" popup; never sold, the Skills row says it comes
  with World 2 (GDD §6). Open: the same for Triple Jump / Dash and World 3. *Implemented and Studio-validated 2026-11-01* (`TalentConfig`
  `rewards`, `StageUnlocks.Changed`, `TalentService` grant + `Granted` remote, `TalentGrantPopup`, Skills row 🔒 + "Free when World 2
  opens", no Skills dot for it, telemetry `TalentGranted`): on the `Lekzdrh` profile a forged Buy was refused (`reward`, no Coins
  taken); buying World 2 (2 500) granted level 1 and showed the popup (Czech texts fit), the row moved on to Triple Jump 5 000; a
  profile with World 2 open and no Double Jump got it on joining; profile restored. Economy model: pins updated (Double Jump 0);
  check 5 B (Gardeners beat no Gardeners) now fails narrowly for Obby main / talent-first (6 068 vs 6 145 net/day): for the E0
  field-pet re-run.
- **The kid's profile shows the real wall:** 5 of the 10 World 1 stars World 2 needs (Bronze on Stages 1, 3, 4, Silver on 2, nothing on
  5) and 503 Coins against World 2's 2 500. The world reward alone would not have got him in; Stage 5 and the star bar come next.
- **Hatching text:** the empty incubator lists every egg with a line of percentages. *Proposed:* two egg cards (picture, price,
  time), odds behind a small "?", the hatch result as a pet reveal (portrait, name in the rarity colour, one line).
- **Measure it:** in M6a, T1a fails per segment on Stage 5, quits per stage and session length of new players.

### E1a — Plots for real + the field (scope 2026-10-30, decisions taken)
**Goal.** The garden is drawn by the client for everyone, on the new ring layout, with today's gameplay unchanged (**E1a1**, published on its
own); then the first crop loop on a 4 → 12-square field, open only to admins until E1 ships (**E1a2**). Nothing in E1a breaks the live game, so
obby fixes keep shipping during the M6a baseline window. Field pets, the end of pen production and Max Players 24 are E1b.

**Design check (2026-10-30).** Matches EXPANSION §3, §5.1–§5.2, §16 and the ECONOMY numbers, with two changes (accepted 2026-10-30): light **Renown** moves
from E1c into E1a2 (without it only Potato is plantable and the expansion tiers have no gate; it is a derived level, no new system), and the
**controls** proposal of EXPANSION §3 is settled as below (square prompts + one Garden panel). Upgrades (growth, barn), the size roll, tools and
the market cart stay in E1c; rare crops and seed pouches in E2.

**E1a1 — Plots drawn by the client (no gameplay change; ~1 week).** EXPANSION §16 migration list items 1–5 and 7, in this order:
1. `PlotView` draws every plot by default from a real `GardenRemotes.Plot` broadcast (`(userId, state)` / `(userId, nil)`; pens as
   `Kind:Level:uid`, pen count, eggs as `Egg:readyAt`, owner name); the owner's `State` message stays for the panels. The client runner replaces
   `PlotViewSpike.client` (distance detail, build budget, own plot first).
2. Server: `GardenService.renderPlot` / `makePenPet`, the `GardenIncubators` renderer and `GardenPlots`' model writes go; `GardenPlots` keeps
   the assigner and the `GardenPlot` attribute. `PlotCount` → `PlotSlots` (Max Players stays 12).
3. Client: `GardenClient` / `IncubatorClient` prompts and countdowns come from `PlotView` (no scan of `Workspace.Garden.Plots`, no `OpenPen`
   hook); `PetPenFx` / `PetPenLevelUp` follow the drawn pens; `HintSources`' ready-egg marker targets the drawn incubator.
4. **Mid pet detail:** a pet beyond about 60 studs is one block.
5. **Layout:** `PlotRings` → radius 112 / 185; `HintSources`' Garden rectangle follows; `tools/plot_formula_test.luau` re-pointed at the
   new layout. *Design check 2026-11-02:* growing the island in place would overlap the hub (its hedge is 207 studs from today's garden
   centre), and ring 2's fields (E1a2, behind the plots) reach radius 224. So the **whole garden moves 87 studs away from the hub** along the
   bridge axis (`PlotCentre` −1222.517, 16.25, −834.035; the bridge stays as it is and still lands in the gate), the hedge + barrier ring sits
   at radius 230 (island 235), and **ring 2 is turned by 5°** (`offset`) so the bridge path (75°, 8 studs wide) runs between plots on both
   rings (4.5 studs of clearance to ring 1's inner corners). Decor moves between the rings (radius 150, between ring 1's fields).
   Free slots of ring 1 are drawn as empty "Free plot" plots (as today); ring 2 is drawn only where someone owns a slot.
   Prompt texts of pens and incubators become strings (`garden.prompt.*`; the Studio prompts were literals).
6. Remove `PlotViewSpike.*` and `PlotViewRemotes`; stash `Workspace.Garden.Plots` in `ServerStorage` until E1a1 is Studio-validated, then delete.

*Studio-only:* the island, hedge, barrier, decor and bridge changes; the plots stash and deletion.

*Implemented 2026-11-02* (`GardenPlotFeed`, `GardenView`, `PlotView`; `GardenService` / `GardenIncubators` / `GardenPlots` draw nothing;
`PlotViewSpike.*` removed). Studio, solo playtests on `Lekzdrh` (profile snapshotted and restored): checks 1, 3, 4, 5 and 6 and the one-client
half of check 2 pass. 1: `Workspace.Garden` holds 595 descendants on the server, as in Edit (no `Plots`, no server-drawn instance). 2: through the
real prompt (E) and buttons: Place the Cat in pen 1 (the drawn pen shows its model and "10 Coins/h" label), Remove, Place again; Basic egg
started at incubator 1 (countdown 298 s vs `ReadyAt − now` 297.1 s), `ReadyAt` moved back → the ready-egg marker targets
`Workspace.GardenView.Slot_01.inc1.Base`, Hatch through the panel empties the incubator and removes the marker. 3: `LastSeen` 1 h back → join payout 10 Coins = `Settle(10 000, carry 230 000, 3 609 s)`. 4: `plot_formula_test` 0 of 240 island rays miss, gaps
8.99 / 13.33 (with field) / 17.91, bridge path 0.49 from slot 3's corner; `GoGarden` lands 10 studs in front of the own plot facing it (dot 0.97); a
`MoveTo` walk from the hub's bridge path over the bridge ends on the plaza. 5: 30 synthetic plots with 12-square fields: 1 183 instances at the
centre, 1 771 at most elsewhere (limit 5 000); a full plot at 90 studs 63 (limit 80), at 30 studs 345. No new console errors.
Second client (2026-11-02, Server and Clients, test users −1 / −2, both non-admins): through Player1's pen panel, Remove and Place of
pen 1 showed on Player2's client 0.012 s / 0.006 s (server time) after Player1's `Result`, the Bunny with its "20 Coins/h" label; no errors on
server or clients. The Studio backups (`ServerStorage.E1a1_PlotsStash`, `E1a1_GardenBackup`) are deleted. **Open:** the place must be saved /
published with the new scene.

**E1a2 — The field (behind access; ~1–2 weeks).**
- **Access:** `GardenConfig.FieldAccess = "admins"` (admins + Studio test users; `"all"` when E1 ships). Every field remote checks it on the
  server; for anyone else no `Field` data is written and the broadcast carries no field (sent per viewer: a player without access sees no
  field on any plot), so live profiles stay untouched. A code constant, not a Workspace attribute: switched in git and live by publishing;
  no testers mode (the user, 2026-10-30); removed once E1 ships.
- **`CropConfig`** (ReplicatedStorage) from ECONOMY.md → "Inputs ready for E1": Potato (start), Corn, Pumpkin (Renown 8), Giant melon (Renown 25)
  with grow time, sale and seed price; expansion tiers 5–12 (price + Renown); Renown points 1 / 3 / 6 / 12 per harvest by tier, level L at
  3 × L^1.6 points; barn 40 seeds (fixed until E1c); `online_rate` 1.0, `offline_rate` 0.33, field offline cap 12 h (placeholders, ECONOMY open
  decision 5). `tools/economy.py` reads it and `check` pins it.
- **Profile:** `Garden.Field = { Count, Squares["1".."12"] = { Crop, Grown }, SettledAt }` (`Grown` = growth seconds earned, `SettledAt` = server
  `os.time()`), `Garden.Seeds[crop]` (a new field starts with 4 Potato), `Garden.Items[crop]`, `Garden.Renown` (points; the level is derived). Growth: online time × `online_rate`,
  offline time (since `SettledAt`, capped) × `offline_rate`, settled on join, leave, before every field action and every 60 s. Ripe crops wait.
- **Server** `GardenField` (a sibling module on GardenService's hooks, like `GardenIncubators`): remotes `Plant(square, crop)`, `Harvest(square)`,
  `BuySeeds(crop, count)`, `Sell(crop, count)`, `BuySquare(expectedCount)`; answers on `GardenRemotes.Result`; prices and times never come from
  the client; the caller must stand at their own plot (`Usable`). Sales go through `CoinRewards.Grant` (pet multiplier at sale time).
- **Client:** `PlotView` draws the real field behind the plot (crop and growth stage 0–3, stand-in stud blocks, no art pass); a prompt per
  owned square, shown within about 6 studs: Plant (seed picker over the stock) or Harvest; a **Garden panel** (button on the own plot): squares
  with crop and time left (`readyAt` sent as "ripe at, if you stay online"), seed catalogue with Renown locks, items and Sell, the next square
  with price and Renown, the Renown level. New texts through `strings.csv`.

*Implemented 2026-11-02* (`CropConfig`, `GardenField`, `FieldClient`; `GardenPlotFeed` adds `field` per viewer, `PlotView` / `GardenView` draw it
with square prompts and `OnSquare`; `tools/economy.py` reads `CropConfig`, pins `crop_field_*`). Studio, solo playtests on `Lekzdrh` (profile
snapshotted and restored, stored profile edited between playtests): checks 7–14 and 16 and the one-client half of 15 pass. 7: with `Lekzdrh`
taken out of `AdminConfig` in Studio only, `Plant` → `locked`, no `FieldGui`, no field drawn, the saved profile has no `Field` / `Seeds` /
`Items` / `Renown`. 8: new field `Count` 4, `Seeds.Potato` 4, nothing planted; Plant with 0 seeds / on square 5 / on an occupied square / Corn at
Renown 0 → `seeds` / `square` / `occupied` / `renown`, nothing changed. 9: the real prompt (E) opened the picker, Potato planted on square 1
(`Seeds.Potato` 3, `Grown` 0, 61 after a minute online); at `Grown` 10 740 Harvest → `notripe`, a minute later the prompt said Harvest and E
harvested it (`Items.Potato` +1, square empty, Renown 2 → 3, level 1, level-up toast). 10: `SettledAt` 3 h back → `Grown` 3 569 on join (3 564 +
≈ 15 s between the write and the join at 0.33); 24 h back → 14 256 (capped). 11: Sell all 3 Potatoes, no pet equipped: Coins 3 → 75 (+72);
Sell 5 with 0 owned → `items`. 12: three +10 clicks −60 each (4 231 → 4 051), the fourth → `barn` (33 + 10 > 40); +1 with 3 Coins → `coins`.
13: Buy at Renown 0 → `renown`; at level 1 with 599 Coins → `coins`; with 10 075 → `Count` 5, Coins −600, a fifth soil drawn; `BuySquare(4)`
afterwards → `stale`; at 12 squares → `maxed`. 14: Renown 3 / 84 / 518 points for L 1 / 8 / 25, monotonic to 2 000. 15: 30 synthetic plots with
12-square fields 1 716 instances at most (limit 5 000); a full plot message 310 bytes. 16: `economy.py check` drift 0 (42 / 43, the known 5 B
fail); `loc.py check` 0 errors, `lint` 0; Czech at a 374 px panel (phone portrait): 53 visible texts, every one fits (StudStyle glyphs measured).
No console errors or warnings on server or client.
Second client (2026-11-02, Server and Clients, test users −1 / −2, both with field access in Studio): Player1 planted a Potato on its square 1
through the real prompt and picker; Player2, 22 studs in front of plot 1, received the plot (`crops` `a1.0.0.0`) 0.001 s and drew the crop 0.017 s
(server time) after Player1's `Result`; no errors or warnings on server or clients.

**Acceptance checks.** E1a1:
1. `Workspace.Garden.Plots` is gone and a join adds **0** instances under server `Workspace`; a non-admin client draws its own plot with one pet
   model per penned pet whose `Uid` / `Kind` / `Level` match the profile.
2. Through the real UI on a drawn plot: place a pet in a pen and remove it (profile `Pens` changes; a second client's drawing follows within 2 s);
   start a Basic egg (the countdown equals `ReadyAt − server now` ± 1 s) and hatch it after moving `ReadyAt` back; the ready-egg marker sits on
   the drawn incubator.
3. Pen production unchanged: `LastSeen` moved back 1 h → the join payout equals `GardenConfig.Settle` for 3 600 s exactly.
4. Layout: every pair of neighbouring plots ≥ 8 studs apart on both rings; rays down from all four corners of every floor hit the island;
   `GoGarden` lands in front of the caller's plot facing it; a player walks from the hub over the bridge into the garden.
5. Budget: 30 plots in range (synthetic) ≤ 5 000 client instances; a full plot beyond 60 studs ≤ 80 instances.
6. `grep` finds no `PlotViewSpike`, `PlotViewRemotes` or `Garden.Plots` reference; no new console errors.

E1a2:
7. A non-admin's `Plant` is rejected (`locked`) and their saved profile has **no** `Field` key; their client draws no field on any plot.
8. A new admin profile has `Field.Count = 4`, `Seeds.Potato = 4` and nothing planted; planting on square 5 or an occupied square, with 0 seeds of that crop, or
   Corn below Renown 8 is rejected and changes nothing.
9. Plant a Potato through the square prompt: `Seeds.Potato` −1, square 1 holds `Potato` with `Grown = 0`; harvest at `Grown = 10 800 − 60`
   is rejected (`not ripe`), 60 s online later it succeeds: `Items.Potato` +1, the square is empty, `Renown` +1.
10. Offline: `SettledAt` moved back 3 h → `Grown` = 3 564 ± 5 on join (not ripe); moved back 24 h → `Grown` = 14 256 ± 5 (cap × 0.33; ripe).
11. Sell 3 Potatoes with no pet equipped: Coins +72 exactly; selling more than owned is rejected and Coins do not change.
12. Buy 10 Potato seeds: Coins −60, `Seeds.Potato` +10; buying past 40 seeds or without the Coins is rejected and changes nothing.
13. `BuySquare(4)` at Renown level 1 with 600 Coins: `Field.Count = 5`, Coins −600; at Renown 0, with 599 Coins, a stale `expectedCount` or at
    12 squares it is rejected.
14. Renown level from points matches 3 × L^1.6 at L = 1, 8 and 25 (unit check in the Edit context).
15. A second client sees the admin's crops at the right stage within 2 s; the plot message stays ≤ 1 KB with 12 squares; 30 synthetic plots
    with 12-square fields ≤ 5 000 client instances.
16. `python tools/economy.py check` reads `CropConfig` with drift 0; `loc.py check` 0 errors; the Garden panel's texts fit in Czech at phone size.

**Decisions (the user, 2026-10-30).** (1) Light Renown is in E1a2. (2) Seeds, selling and squares are bought from the Garden panel at the own
plot (fewer walks on mobile), no seed stand on the plaza. (3) A new field starts with 4 free Potato seeds, so the first plant needs no shop.
(4) `offline_rate` 0.33 / 12 h cap stay placeholders until ECONOMY open decision 5 is taken.
**Tuning (the user, 2026-11-02, after validation).** Potato grows in **5 minutes** (was 3 h) so the first harvest comes in the first session; its
price drops to sale 2 / seed 1 to keep the field inside guardrail A (at 24 / 6 the 5-minute Potato failed the 24-hour rule for every archetype,
the day-60 band and the online / offline ratio). Checks 9-12 above were run with the old Potato (3 h, 24 / 6); the code paths are unchanged.
Side effect the model does not cover (it replants only on visits): a player who stays at a 4-square field earns about 48 Renown points an hour,
so Renown 8 (Corn, Pumpkin) takes under 2 hours of field time instead of days.

### E1b — Field pets (design check 2026-11-02, decisions taken)
**Goal.** Pets stop working in pens and work the field instead: a pet stands on a square, a **Tending** pet harvests and replants the squares in
its reach while the owner is away, and its Tending level rises with field time. Pens convert into field pet slots once, with a refund. Like E1a2 it
is **behind `GardenConfig.HasFieldAccess`**: players without access keep their pens and the Coins-per-hour production unchanged (EXPANSION §3:
pen income is removed only when crops ship), so E1b can be published without touching live players. Inputs: ECONOMY → "Field-pet re-run"
(approved 2026-11-02).

**Design check.** Matches EXPANSION §3 (field pets, reach, one job per pet, data `Garden.FieldPets`), §4 (aptitudes rolled from the uid, levels
1–10, rarity caps, XP from field time) and §16 item 4 (full aptitude data stored from the first hatch, only the working ones shown). Only
**Tending** does something in E1b. Fertilising, Pest control (E4-thin), Weeding, Scouting (E2 seed pouch) and Crafting are rolled and stored but
not shown. Quirks and bond stay out (D7). Field pets can be placed only at the own plot (the "move from far away" question of §16 stays open).

**E1b1 — Data, aptitudes, conversion, Tending (server; ~1 week).**
1. **Aptitudes.** `PetConfig.Aptitudes` holds the ids `Tending`, `Fertilising`, `PestControl`, `Weeding`, `Scouting` and `Crafting` (never renamed).
   `PetConfig.RollAptitudes(uid, kind)` rolls them deterministically from the uid (as PetLook's looks):
   - the count follows the rarity (1 / 1 or 2 / 2 / 2–3 / 3);
   - Tending's chance per rarity is the model's 0.2 / 0.22 / 0.4 / 0.5 / 0.6, independent of the kind (so the model holds);
   - the kind leans the draw of the other aptitudes (cat, dog, owl → Pest control; bunny, dragon → Fertilising; fox, phoenix → Scouting;
     panda → Weeding);
   - a pet with Pest control also gets a `Spec` (crows, moles, slugs, raccoons).

   They are stored as `Pets[uid].Apt = { [id] = { L, XP } }` and `Pets[uid].Spec` at hatch (`PetService.AddPet`). A pet without `Apt` gets them once
   on load, at level ceil(pet level / 4) and at most the rarity cap. Stored aptitudes are never rerolled.
2. **Field pets.** The data is `Garden.FieldPets[uid] = { Square, Job }` (Job = `"Tending"` in E1b) and `Garden.FieldPetSlots` (1 free, +1 at 2 500,
   +1 at 9 000; `CropConfig.FieldPetSlotPrices`). The server checks:
   - the caller is at the own plot (within 45 studs);
   - the square is owned and holds no other pet;
   - the slot count allows another pet;
   - the pet has the job's aptitude and is not equipped.

   `PetService` rejects Equip / SellPet of a field pet (`"field"`), as it does for penned pets today (`GardenConfig.IsPenned` → `IsPlaced`: pen or field).
3. **Reach.** On the 4-column grid (`CropConfig.Reach(square, level, count)`):
   - levels 1–3: the pet's own square;
   - levels 4–6: that square plus its 4 neighbours;
   - levels 7–10: the 3 × 3 block.

   The same job does not stack: a square is tended by the strongest Tending pet that reaches it.
4. **Tending in `GardenField.settle`.** For each tended square whose crop ripens during the settled span:
   - The pet harvests it when a roll is below its strength for the level (20 / 35 / 48 / 59 / 68 / 76 / 83 / 89 / 95 / 100 %) and the barn has room (crops in `Items` below `BarnCapacity`). The crop goes into `Items` and gives Renown as a hand harvest does.
   - It then replants the same crop from `Seeds`, carrying over the leftover growth.
   - A failed roll or a full barn leaves the crop ripe. With no seed of that crop the square stays empty after the harvest.
   - The roll is deterministic per owner and planting (a new counter `Squares[n].N` from `Field.Plantings`); a failed roll marks the planting `Tried`, so a re-join never rerolls it.
   - Tending works **only while the owner is away** (the join settle), as the model assumes (decision 2).
5. **Aptitude XP.** A placed pet earns XP in its job's aptitude per weighted field hour, as growth does (online 1.0, offline 0.33, capped at 12 h).
   Level L → L + 1 needs 10 × 1.56^(L−1) hours, up to the rarity cap. XP is settled with the field.
6. **Conversion.** It runs once, for a player with field access, on join (flag `Garden.Converted`):
   1. pays the pending pen production (`settle` as today);
   2. returns penned pets to the inventory;
   3. sets `FieldPetSlots` by the pens bought (1 → 1, 2–3 → 2, 4–6 → 3);
   4. refunds the pens beyond that (`PlayerProfile.AddCoins`: 3 pens → 1 000, 5 → 6 000, 6 → 21 000).

   After that `Pens` / `PenCount` / `Carry` stay empty and pen production is 0. The Place / Remove / BuyPen remotes reject a converted player (`"field"`).
7. **Remotes** (in `GardenRemotes`): `PlacePet(square, uid)` (also moves a placed pet), `LiftPet(uid)` and `BuyPetSlot(expectedSlots)`, answered on
   `Result`. Message changes:
   - `State.field` gains `pets = { [square] = { uid, job, level, xp, next } }` and `slots`;
   - the plot message's `field` gains `pets = "Kind:Level:uid:square:reach" × n`;
   - `PetsChanged` gains `field = { [uid] = square }` (pets already carry `Apt`).
8. **Docs and checks:** AGENTS.md (remotes, profile), LAYOUT.md, and `economy.py check` with drift 0 for the new prices.

**E1b2 — Client (~1 week).**
1. **`PlotView`:** a converted plot draws no pens. Pets stand on their squares (full detail: the PetLook model; mid detail: a block). On the own
   plot, the squares in reach of the pet being placed or moved are tinted.
2. **Square prompt "Place pet" / "Move pet"** next to Plant / Harvest. It opens a pet picker listing pets that have Tending and are not equipped,
   with name, Tending level, reach, and "on square n" for placed ones. A placed pet also gets "Lift".
3. **Garden panel:** a **Pets** section shows who works where, the Tending level with an XP bar and slots used / total, and buys the next slot.
   The pen panel (`GardenClient`) hides for converted players.
4. **Pets panel:** pets that have Tending show a Tending line. A field pet shows "On the field" instead of the Equip button.
5. **Conversion popup:** a one-time "Your pens became field pet slots (+N Coins)". Strings go in the CSV (en + cs).

*Studio-only:* nothing (the field and pets are drawn by the client).

**E1b1 implemented and Studio-validated (2026-11-02)**, by remotes from a playtest client and fixtures in the developer's live profile (snapshot
`TestSnapshots` `profile_9892673032_e1b`, restored afterwards):
- Check 1: 100 uids rolled twice give the same sets; the forced Tending roll gives Tending; live pets got their aptitudes on join at
  ceil(level / 4) (Lv 4 → 1, Lv 8 → 2) and kept them on re-join. Check 2: Tending share 0.201 / 0.214 / 0.397 / 0.499 / 0.599 over 10 000 uids
  per kind; counts 1 / 1 (9.9 % two) / 2 / 2–3 (50.7 % three) / 3; Owl's Pest control always against raccoons; a Dog's lean gives Pest control 34 %.
- Check 3 (6 pens, 1 penned pet): 3 slots, +21 000 Coins (4 111 → 25 121 with the last 10 Coins of pen income), the pet back in the inventory,
  Place / BuyPen answer `field`; a re-join converts nothing.
- Check 4 (server): rejected a pet without Tending (`aptitude`), an equipped pet, square 9 of 4, over the slots, an occupied square, a stale slot
  purchase, a 4th slot (`maxed`), a far player; a forged call gets no answer; Equip / SellPet of a field pet answer `field`; move, lift and slot
  purchase (9 000) work.
- Check 5: two absences (3 h on 4 squares, 1 h on 12 squares) gave exactly the field an independent replay of the rolls predicts, square by
  square (planting numbers, leftover growth, seeds, Renown); the barn stopped the pets at 40 crops; a re-join did not reroll the Tried plantings.
- Check 6 (server part): reach 1 / 5 / 9 squares at levels 1 / 4 / 7 and the strongest pet on an overlap match the replay. Check 7: XP 10 h /
  15.6 h for levels 2 / 3, the Common cap stops at 6 (a PetConfig test); field time adds XP (3 569 s after the 3 h absence + online seconds).
- Decision 3: with no Tending pet owned, a hatched Basic egg gave a Bunny with Tending.
- Not covered by a playtest: a player without field access (code path: GardenField returns before converting; PetService rolls aptitudes for
  everyone, data only). Checks 6 (drawing), 8 and 9 come with E1b2.

**Acceptance checks (E1b).**
1. A new pet gets `Apt` (and `Spec` with Pest control) at hatch, and reloading keeps it. The same uid always rolls the same set (100 uids rolled twice).
2. Roll statistics over 10 000 synthetic uids per rarity match the targets: Tending share 0.2 / 0.22 / 0.4 / 0.5 / 0.6 (± 0.02), aptitude counts as in §4.
3. A live profile with 6 pens and 3 penned pets converts once: pending production paid, pets back in the inventory, 3 slots, +21 000 Coins.
   A second join changes nothing. A player without access keeps pens and production unchanged.
4. Place, move and lift work through the real UI. The server rejects:
   - an equipped pet or a pet without Tending;
   - an occupied or unbought square;
   - a 4th pet over the slots;
   - a far player;
   - forged arguments.

   Equip / sell of a field pet is rejected too.
5. Tending works offline (stored times moved back, with snapshot / restore). Crops that ripen during an absence are harvested and replanted by
   the roll, seeds are used, the barn limit is respected and Renown is counted. Re-joining does not reroll a failed planting, and the same profile
   settled twice from the same snapshot gives the same field.
6. Reach is 1 / 5 / 9 squares at levels 3 / 4 / 7, tested at a corner and the middle of the grid, and the drawn reach matches the server's.
7. Aptitude XP and level-ups come at the expected hours and stop at the rarity cap.
8. With two clients, the other player sees the pets on the plot. 24 full plots with fields and pets stay inside the E1a1 budget (`GardenViewFake`).
9. `economy.py check` shows drift 0, `loc.py check` 0 errors and lint stays within the baseline. The new texts fit in Czech at phone size.

**Decisions (the user, 2026-11-02: all six as recommended).** Recorded below with the options that were weighed. Decision 3 is implemented as
"a hatch while the owner has no Tending pet gets Tending" (covers the first garden hatch, and live players without a tender); decision 6 as
`EDGE_TOL` = 1 % in `economy.py check` (B and O).
1. **Gating:** E1b stays behind field access, and conversion runs only for players with access. Live players keep pens until E1 ships, when
   `FieldAccess = "all"` converts everyone on join. *Recommended.*
2. **When Tending works:** either only during absences, as modelled (online play stays ahead, but Binge gets no extra cycle: finding B), or also
   while the owner is online but away from the field (in the obby). The second helps Binge and long sessions but needs an `economy.py` re-run first,
   and the O finding moves too. *Recommended: absences only for E1b, revisit with telemetry.*
3. **A Tending pet for a new player:** a Common has Tending only 20 % of the time, so most players hatch no Tending pet for a while and the free
   slot sits idle. Proposal: the first pet hatched in the garden always has Tending (as its first aptitude). *Recommended.*
4. **Penned pets on conversion:** either back to the inventory (the player places them), or placed on the field automatically (fewer surprises,
   but on an arbitrary square). *Recommended: inventory, plus the popup.*
5. **Max Players 24:** this is a place setting changed at publish. Field pets stay admin-only, so 24 can wait until E1 ships; E1b checks the
   24-plot budget with the fake plots. *Recommended: keep 12 until E1 ships.*
6. **The two E0 edge findings** (B equal for Binge, O at its bound for Garden main): either accept them as equality within 1 % in `check`, or
   follow decision 2's alternative. *Recommended: accept for now.*

### E0 — Economy model
**Goal.** One reproducible model of the Coin economy (`tools/economy.py`, Python stdlib) that fixes the numbers E1 needs, proves GDD §6 and the
EXPANSION §5 guardrails with crops added, and re-prices every Coin sink. No game code in E0; approved prices are applied in **E0b** (GDD first,
then the configs, then `loc.py` if a price is in a text, then a Studio check of the shops; nobody is refunded or charged again).

**Done (2026-10-24 / 25, numbers in ECONOMY.md).** The loader reads every existing number from the Luau configs and pins it (`check` fails on drift);
the GDD figures are reproduced; a 60-day day-by-day simulation of four archetypes (Obby main, Casual, Garden main, Binge) × two purchase policies;
the crop field with guardrails A–C and the online / offline rule. What it showed and what was decided from it:
- Today's pens already break the 24-hour rule and the existing sinks run out within 1–4 weeks, so the field must take its ceiling from squares,
  seed cost and stock, and the garden needs new sinks.
- Pet levels saturate within days (Lv 20 in 7–14 days): XP is no lasting progression axis, which is one reason for the aptitudes (EXPANSION §4).
- **Field: 12 squares at ladder scale 0.3** (decided 2026-10-25): the original ladder fits only 4–7 squares under the 24-hour rule.
- The Tending (Gardener) edge is thin, and squares per Gardener is the most sensitive lever (2 squares put the worst day at 1.06x).
- Sinks absorb only 36–68 % of the faucet by day 60: the 80 % target needs the landmark / estate sinks (placeholder ladder).

**Inputs.** Existing (read from the configs): medals and first-finish payouts, repeat reward, challenge coins, talents, unlocks, pets, eggs, slots,
pens, incubators, food. New: the crop ladder, the field (squares, expansion tiers, upgrades), **field pets** (decided 2026-10-30, EXPANSION §3–§4:
field pet slots, reach by aptitude level, Tending strength, the aptitude XP curve; replaces "1 square per Gardener, 6 posts"), the **stage seed
pouch and rare-seed meter** with Scouting (§8.1), seed stock, Renown gates, stations, request board, the first landmark bundle.

**Still to do.**
- **Field-pet re-run** (before E1b): *modelled 2026-11-02* (`economy.py pets`, ECONOMY.md → "Field-pet re-run"): 3 field pet slots (1 free +
  2 500 / 9 000), Tending strength = replant-at-once chance (L10 = continuous), aptitude steps 10 x 1.56^(L-1) weighted hours, pens -> slots with a
  refund (6 pens -> 3 slots + 21 000), seed pouch 0.1 seeds per finish + a 100-finish rare-seed meter. **Approved by the user 2026-11-02**
  (E1b inputs). Open: the two edge results (B equal for Binge, O at its bound for Garden main); `check` 41 / 43.
- Repricing (a proposal table old → new price with time-to-afford per archetype, for the user's approval), dead end, rare supply, sensitivity;
  later the EXPANSION pieces (harvest rolls, fertilisers, tools, the Spender archetype).

**Acceptance checks** (`python tools/economy.py check`; numbering used by ECONOMY.md; 1–6 pass)
1. Drift: every config parameter equals the model's value.
2. Reproduction of the GDD figures (medal totals, talent tree, a day of Gold runs, pen rates).
3. GDD §6 required-set table: every share ≤ 65 % with garden income off; the table with it on is printed beside it.
4. Guardrail A, the **24-hour rule**: a fully developed, fully automated field over 24 h ≤ 1.0 × the player's first obby hour of a fresh day at
   the same progress, for every archetype on every day (target 0.8–1.0 ×).
5. Guardrail B: a field with no Tending pet pays strictly less per day than one with them.
6. Guardrail C: sinks absorb the decided share of the faucet over days 1–60.
7. No dead end: every archetype affords the next required talent before the stage that needs it, without garden income.
8. Rare crops: the weekly obby supply covers the first landmark within 14 days for Casual and is zero without obby runs.
10. Repricing: every proposed price lands each archetype's first affordable day inside its band; a change beyond ×2 / ÷2 is flagged for the user.
11. Sensitivity: ±20 % on each new parameter; any parameter that flips a guardrail is flagged for telemetry in M6a.

**Open decisions:** the sink share (proposal 60 % by day 30, 80 % by day 60); the time-to-afford bands; the size of the placeholder sinks (~0.8 M
Coins for Obby main); `offline_rate` (0.33 placeholder) and the field offline cap (12 h placeholder); the pen migration (likely only test accounts
have pen income).

### MU — Mobile UX check (scope when it starts)
Pawvest stays on Roblox and is treated as **mobile-first** (most Roblox playtime is on phones; decided 2026-10-24). A checklist on a real phone and
the Studio device emulator, before anything goes public and before M7: touch layout of every panel and popup at phone sizes, tap targets, safe
areas, Czech text length, touch controls for the kit and talents (the Dash button was never tried on a phone), performance on a mid-range phone
(pets, a full garden; E1.0 has no phone number yet), the first minutes, the T1a platform split.

### Later milestones (scope when they start)
- **M6b — Final balancing:** measured `T_base` per stage from telemetry, tuned numbers in GDD and the configs; GDD §6 table still all ✔. Known
  items: the repeat-reward floor (a Tutorial loop pays ~1 400 Coins / h), pet bonus values, slot prices, the Basic egg's 5-minute hatch.
- **S9 / S10 — Wall Jump + Glide, World 4** (STAGES §8), drop D8; re-check World 4's star bar (World 3's tighter Silver / Gold make 10 of 15 stars harder).
- **S11 — Bonus stages** (STAGES §5.3); the farm stages (EXPANSION §8.2) may use this slot.
- **P3 — Trading:** first profile session locking (`UpdateAsync` with a `{ JobId, Time }` lock); then an atomic two-sided swap with confirmation,
  immediate saves and a trade log. Open whether to do it at all (EXPANSION §16).
- **M7 — Monetization:** comfort only (no paid random items, luck and weather never sold; EXPANSION §13), drop D2.

## Open items from finished work
- **For the live test (M6a):** several real players at once (others' plots, pets, coins; checkpoint pads only for their own player); two servers
  at once (boards and `MostStars`); gate prompts on a locked stage; a real 1-hour Golden egg and the inventory cap with free eggs waiting; every
  telemetry event type visible on the Creator Dashboard (only then T1 is live-validated).
- **The user's checks:** World 3 sign-off (S8); G1 hints in play.
- **Localization:** the FredokaOne font with Czech carons, Czech overflow screenshots of the panels, the Stage 9 exit-door label.
- **E1.0 leftovers** (go to E1a / MU): a real-phone measurement, a 12-client join.
- **Housekeeping (Studio):** delete `ReplicatedStorage.StageTimerStopped` (unused). (`ServerStorage.Stage9_OldBigMaze` was deleted on 2026-11-01.)

## Done
What was built and why, newest first. Details: the design docs and git history.

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
