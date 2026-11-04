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
| E1b2 | Field pets, client: pets on squares, place / move prompt, Pets section, conversion popup | ✔ | ✔ | – |
| P3a | Pet detail panel (Pets list "i" badge → `PetDetail`) | ✔ | ✔ | – |
| P3b | Pet names (filtered, shown to everyone; first free, renames 250) | ✔ | ✔ | – |
| E1a3 | Crops as pet food (pet detail page; XP = half the sale value) | ✔ | ✔ | – |
| E1c1 | Field upgrades (growth, barn) | ✔ | ✔ | – |
| E1c2 | Size roll (lognormal, Big / Giant, best per crop, sizes in the barn) | ✔ | ✔ | – |
| E1d1 | Farming-first numbers (F2: crop prices × 9.3, new square / upgrade prices, five field pet slots) | ✔ | ✔ | – |
| E1d2 | 36-square field (rows 6-6-8-8-8 behind an incubator strip), squares chosen freely, price by the number open | ✔ | ✔ | – |
| E1c3 | Garden tools tier 1 (Seed sorter, Cloches, Pruning shears; Renown-gated levels) | ✔ | ✔ | – |
| E1c4 | Daily market cart (two seed bargains, a taste of the next locked crop from Renown 3) | ✔ | ✔ | – |
| E2–E5 | Garden MVP (see "Next") | – | – | – |
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
   | **E1a3** | Crops as pet food: feed held crops to a pet from its detail page (scope below) | E1a2, P3a |
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

### P3 — Pet detail panel and pet names (proposed 2026-11-02, decisions taken the same day)
*Why:* aptitudes (E1b) made pets differ in ways the Pets list cannot show: which jobs a pet has, how far each can grow, what to do next.
A pet the player has named is a pet they keep. *Audience:* K1's 8-10 year olds on a phone, so the panel uses bars, stars and icons and as little
text as possible.

**P3a — Detail panel (client; PetsChanged already carries `Apt` / `Spec`).** Opened by an info button on a Pets list row (decided: a tap on the
row still equips / unequips); one screen, scrolls on a phone:
1. **Header:** a large slowly turning portrait (PetLook in a ViewportFrame), the name (kind name until named), rarity in its colour, tier stars,
   where the pet is (with you / square n / pen / resting).
2. **Growth:** pet level n / 20 with the XP bar; how it grows (walking with you, food from the garden food shop); the next look (★ at Lv 5 / 10 / 15 /
   20, `PetConfig.TierOf`); the Coin bonus, which counts only while the pet is with you.
3. **Aptitudes:** one card per rolled aptitude that works today (decided: only the ids in `PetConfig.Shown`, now Tending; the others appear when
   their system ships, E2 / E4-thin): icon, level / the rarity's cap (`AptitudeCap`), the effect bar (`Strength`), XP to the next level
   in hours of field time (offline at a third), reach (1 / 5 / 9 squares, the next step at level 4 / 7) and the speciality for Pest control.
   At the cap: "Max for a Rare" (rarity gives breadth, not height, EXPANSION §4).
4. **Actions:** Equip / Unequip, Sell (with the confirm step), Rename (P3b).

**P3b — Names (server).**
- `PetRemotes.Rename(uid, text)`: 1-20 characters after trimming, letters / digits / spaces only (no rich text, no line breaks), one rename per
  10 s; an empty text removes the name (free).
- **Price (decided):** the first name is free, every later one costs 250 Coins (`PetConfig.RenamePrice`, server-side, `PlayerProfile.AddCoins`;
  `Pets[uid].Renamed = true` after the first, so clearing a name does not make the next one free); pinned in `economy.py`.
- **Filtering is a Roblox rule, not a choice:** the server filters with `TextService:FilterStringAsync` (owner's user id, `PublicChat` context)
  and shows `GetNonChatStringForBroadcastAsync`. The raw text is stored as `Pets[uid].Name` and filtered again on every join (filters change);
  clients only ever receive the filtered text. A failed filter call shows no name (the kind name), never the raw one.
- **Shown to others (decided)** through a player attribute `PetNames` (JSON `{ [uid] = filtered }` for the equipped and field pets), read by `PetFollow`
  and `PlotView`; the plot feed and `EquippedPets` keep their formats (a name can hold no `:` / `,` there).
- **Display:** "Mochi" as the title, "Cat Lv 6" under it (list, detail, field picker, food shop); labels over pets "Mochi · Lv 6". A name is
  user data: never localized, `AutoLocalize = false` (already the rule for code-built GUIs).
- New pets also store `Born` (server `os.time`) and `Egg` for a "hatched on … from a Basic egg" line; older pets show nothing there.

**Acceptance checks (P3).**
1. Every pet in the list opens its panel; the numbers match `PetConfig` (level, XP, aptitude levels / caps, reach, bonus); a Legendary with three
   aptitudes and a Common with one both fit on a 374 px phone panel in Czech.
2. Equip / Unequip / Sell from the panel behave as from the list (field / pen rejections included).
3. Rename: a forged uid, 21 characters, a newline, `<b>` and two renames within 10 s are refused; a name that the filter changes shows as `####`
   on both clients; a re-join keeps the name; the other client sees it over a following pet and a field pet. The first name costs nothing, the
   second 250 Coins, a rename with 249 Coins is refused (`coins`), clearing is free.
4. `loc.py check` 0 errors, lint within the baseline.

**P3a implemented and Studio-validated (2026-11-02)**, by clicks in a playtest on a fixture in the developer's live profile (Phoenix Lv 12 with
Tending 7, Cat Lv 6 with Tending 4 on square 1, Dog Lv 20 with Tending 6; restored afterwards to the state before the test, snapshot
`TestSnapshots` `profile_9892673032_p3a`):
- The "i" badge on a row's portrait opens the page without equipping; a tap on the row still equips / unequips; Back returns to the list, the
  page's X closes the panel. Numbers match `PetConfig`: Phoenix "Level 12 / 20", 40 / 416 XP, next look ★★★ at 15, +20.5 %; Tending 7 / 10,
  effect 83 %, 5.6 / 144.1 h, 9 squares; Cat on the field "Works square 1", Tending 4 / 6, 5 squares and no next step (7 is above its cap);
  Dog "Top level!", "Every look unlocked", "Max for its rarity (Common)"; a pet without Tending shows the no-job line.
- Actions: Equip with the only slot taken → `slots`; Sell of the equipped Cat → "Unequip it before selling"; Unequip / Equip from the page;
  Equip of the field pet → `field`; Sell takes a second tap within 3 s, the page closes and the list says "Sold for 100 Coins".
- Czech: the 21 texts of the Phoenix page and every list row fit (the panel is 340 px wide at every screen size, scaled by PanelFit).
- Found and fixed: the page drew empty (a ScreenGui made in code has Global ZIndex, its children sat under the page: they are lifted now);
  🪙 has no glyph (now 💰). No console errors. Once, in a fast scripted click sequence, the Cat ended up equipped and the same sequence
  did not repeat it; nothing in the code equips except the Equip button and a row tap.

**P3b implemented and Studio-validated (2026-11-02)**, in playtests on a fixture in the developer's live profile (restored afterwards, snapshot
`TestSnapshots` `profile_9892673032_p3b`) and with two clients (`user_-1` a copy of that profile, removed afterwards). Differences from the plan:
the title and the labels read "Mochi Lv 6" (`pet.nameLevel.named`; the kind stays on the page's second line); `PetNames` also lists penned
pets (pens show labels too); the "hatched on … from a Basic egg" line (`Born` / `Egg`) is not built (left for later).
- Server (remote calls): a forged uid gets no answer; 21 characters, a newline, `<b>` → `name`; "  Mochi  " → "Mochi", free; a second rename
  within 10 s → `cooldown`; the same name → `same`; the next name cost 250 (499 → 249), one more with 249 Coins → `coins`; clearing is free.
- UI (clicks): the button reads "Save · free" / "Save · 250" / "Remove" / greyed "Save" for the box's text and the note gives the price; the
  result line shows for 4 s; 249 Coins → "Not enough Coins" without a request. The name shows on the page title, the list row, the slot caption,
  the follower ("Blaze Lv 12 ★★"), the field pet ("Tiger Lv 6 ★ / Tending 4") and its prompt; a re-join keeps it. Czech: the row fits
  ("Uložit · zdarma" is the longest).
- Two clients: Player2 saw Player1's field pet "Tiger" and follower "Phoenix"; renames on Player1 ("Blaze", "Stripes") reached both of
  Player2's labels at once.
- **Live-only:** Studio does not filter text ("Fox 5551234567" came back unchanged), so the `####` part of check 3 waits for a live test.
- Found and fixed: Argon left Studio's copy of `PetDetail` without its last edit (the name box / button handlers) although it was connected;
  the block was pasted into Studio's copy (byte-identical to the file). If an edit does not show in Studio, reconnect the plugin.

### E1a3 — Crops as pet food (scope 2026-11-02, the user's idea; defaults accepted)
A harvested crop can be **sold or fed to a pet** for XP. Design check: EXPANSION plans the Kitchen (D5) as "crops → pet food, a cheaper route to
levels than Berry / Cake / Feast"; feeding a raw crop is therefore **no cheaper than selling it and buying food**, so the Kitchen stays the better
route later. Only for `GardenConfig.HasFieldAccess` (nobody else holds crops).
- **Numbers:** `CropConfig` gets `xp` per crop = half its sale value (at least 1): Potato 1, Corn 54, Pumpkin 72, Giant melon 216. Berry, the
  weakest food, gives 0.5 XP per Coin, so a crop is worth what its Coins would buy. `economy.py` pins the values and checks
  `xp <= sale × Berry.xp / Berry.price` for every crop (a new crop or a sale-price change then has to pass the guardrail).
- **Server (`GardenField`, it owns `Items` and settles the field):** `GardenRemotes.FeedCrop(uid, cropId, count)`, count an integer 1..held.
  Settle the field first (Tending harvests count); clamp the count to `ceil(GardenConfig.XpToMax(pet) / xp)` (the last crop may go past level 20, the XP
  over it is lost; the crops after it stay in the barn); `Items[crop] -= used` and `ItemSize[crop] -= used × ItemSize / held` (the average
  size leaves, as in a sale, E1c2); `PetConfig.GainXp`; a penned pet's production is settled at the old level first (as `GardenFood`
  does); publish pets and garden; answer on `GardenRemotes.Result` `("FeedCrop", ok, { uid, crop, used, xp, level, levels } or reason)`.
  Rejects: no field access `locked`, crop not held `items`, a level-20 pet `maxed` (nothing used), bad uid / crop / count → no answer.
  Any owned pet can be fed (equipped, penned, resting or on the field, the same rule as food); a field pet's reach follows its new level.
  Renown is earned at harvest, so feeding takes none away. No position check: the page works anywhere (the food stand's distance rule exists
  because food is bought there).
- **Client (`PetDetail`):** a "Feed" card under Growth, shown with field access while the player holds crops: one row per held crop (icon, count,
  "+54 XP"), buttons **Feed** (one) and **All** (as many as the pet can take; the label says how many). The Growth card's bar moves with the answer;
  level-up shows the usual level-up moment on a following pet. Strings: `petDetail.feed.*` (title, per-crop XP, buttons, done line, rejects).
- **Known effect, accepted:** Tending pets harvest crops that can level pets, Tending pets included: a slow loop at these rates.

**Acceptance checks (E1a3).**
1. One Corn fed to a Lv 4 pet: `Items.Corn` −1, XP +54, Coins and Renown unchanged; the Growth card and the list show the new XP.
2. "All" on a pet 100 XP below level 20 with 5 Corn: 2 Corn used (108 XP), the pet is level 20, 3 Corn stay; a level-20 pet → `maxed`,
   nothing used.
3. Refused: crop not held → `items`; count 0, 1.5, −1 or more than held → no change; a forged uid → no answer; a player without field
   access → `locked` and no card.
4. A penned pet fed to a new level: production up to the feeding is paid at the old level. A field pet fed past a reach step: its card and the
   field show the new reach.
5. `economy.py check` passes with the new pins; `loc.py check` 0 errors, lint within the baseline; the card fits a 340 px panel in Czech.
6. All of it once through the real UI (clicks), no console errors; live profile snapshotted right before and restored after.

**Design check (2026-11-04), corrections from the milestones built since the scope:**
- Players with field access have no pens (E1b converts them on join), so check 4's penned pet cannot occur. The settle before feeding stays in the code as a guard.
- A field pet's reach follows its Tending level, not its pet level: feeding moves the level on its field label, not its reach.
- With E1d1's prices the XP is Potato 3, Corn 504, Pumpkin 672, Giant melon 2 016. Level 1 → 20 takes 6 714 XP (14 Corn).
  That is what the same Coins buy as Berries; food prices were not scaled with F2, so pet levels are cheap against field income either way (for the balancing pass).

**Implemented (2026-11-04).**
- `CropConfig` `xp` per crop.
- `GardenField`: remote `FeedCrop`; `usableField(…, anywhere)` skips the plot distance.
- `PetDetail` Feed card: one row per held crop with "+N XP each", Feed and All · n (hidden when n is 1), and a result line that stays for 4 s, also after the pet reaches level 20.
- Strings: 8 rows `petDetail.feed.*`.
- `economy.py`: pin `crop_field_xp` and check 13 (1 ≤ XP ≤ sale × Berry's XP per Coin); `check` passes 52 / 52.

**Studio-validated (2026-11-04).** By clicks in playtests on a fixture in the developer's live profile: 8 Corn of summed size 9.6, Cat #1 at Lv 18 1 000 XP below the top, Cat #2 at Lv 20.
Snapshot `TestSnapshots` `profile_9892673032_e1a3`, restored afterwards through `BindToClose` writes.
1. One Corn to the equipped Owl, Lv 4 66 XP: Lv 8 46 / 226 XP. The follower played the level-up moment, and the card read "🌽 × 1 snězeno: +504 XP · Postup! Lv 8".
   Corn 7, the summed size 8.4 (the average 1.2 left); Coins 3 402 and Renown 32 unchanged.
2. Cat #1 showed "Vše · 2" and went to Lv 20 with 2 Corn; 5 stayed. Rejected with `maxed`, nothing used: Cat #1 and Cat #2 at Lv 20.
3. Pumpkin not held and 6 of 5 → `items`. Counts 0, 1.5 and −1, a forged uid and an unknown crop got no answer.
4. The field pet Fox #3 on square 4, Lv 2: Lv 7 107 / 185 with Tending still 2. The plot feed sent `Fox:7:3:4:2` and the field label read "sklízečka Lv 7 ★ / Péče 2".
5. Feeding survived a re-join. 10 Potatoes ("Vše · 10", Corn's All hidden at 1) took Cat #2 from Lv 19 to 20; the card kept only "🥔 × 10 snězeno: +30 XP · Postup! Lv 20" and left after 4 s.
   The Czech card fits the 340 px panel. No warnings or errors on the server or the client.

Found and fixed: the result line disappeared with the card when the pet reached level 20.
Found in the test harness, not a bug: clicking a list row that is scrolled out of view lands on the slot bar under the list (it unequipped the Owl).
That is probably the stray equip seen once in P3a. Scroll a row into view before clicking it.
Not covered: a player without field access (`locked`; the card is not built without `HasFieldAccess`), checked in the code only; phone layout.

### E1d — Farming-first rebalance (scope draft 2026-11-03; numbers: ECONOMY.md → "Direction change", F1)
**Goal.** Farming becomes the main game: over days 1-3 the field earns at most what the obby earns, then 3x by day 7 and 10x by day 30 (Casual,
Garden main). The field is admin-only (`GardenConfig.FieldAccess`), so its numbers can change freely. The obby change reaches live players.
Proposed split into two steps, each validated and committed on its own:

**E1d1 — Numbers.**
- **`CropConfig`, candidate F2 (ECONOMY.md), × 9.3:**
  - Crops (sale / seed): Potato 6 / 2, Corn 1 008 / 252, Pumpkin 1 344 / 336, Giant melon 4 032 / 1 008.
  - Gates: Corn and Pumpkin Renown 1, Giant melon 5.
  - Field sinks: upgrades (Growth 28 000 / 74 700 / 186 700 / 420 000, Barn 14 000 / 37 300 / 93 300 / 233 300 / 560 000).
  - **Five** field pet slots: 0 / 23 300 / 84 000 / 280 000 / 746 700.
  - Squares by the number open: the price rises about × 1.23 per square, from 1 400 (5th) to 907 400 (36th); Renown 0 / 0 for the 5th / 6th, then
    5, 6, 7, 8, 10 and +1 per square up to 35. Exact roundings come from the model.
- **E1a3 crop XP** stays half the sale (Corn 504). The guardrail still holds: XP ≤ sale × Berry's XP per Coin.
- **Obby:** repeat runs stay as they are (user, 2026-11-03). Talents stay Coins until the parked stars idea is decided.
- **`economy.py`** reads the new configs. `check` then passes the P / L checks, and `pin` accepts the numbers. A migration is not needed:
  stored Coins stay as they are.

**Implemented (2026-11-03).** `CropConfig` carries F2's numbers. The Expansions list keeps 8 entries (squares 5-12, F2's first 8) until E1d2.
`economy.py` now runs at ladder scale 2.8 and was pinned. The fixes found on the way:
- Tending pets fall back to a crop whose seeds the player can afford.
- The shop keeps one replant of every square in reserve. Without it, a field pet slot could take the last Coins, and the tended squares stayed empty
  at Giant melon seed prices, which failed B for Garden main.

`check` 50 / 51: only Casual's day-30 lead fails (4.6x on 12 squares without tools), as expected until E1d2 and E1c3. Pens convert into slots with
no refund any more: slots are now worth more than any pen set cost (6 pens 32 500, their 3 slots 107 300).

**Acceptance checks (E1d1).**
1. Panel with field access, Renown ≥ 1: Corn and Pumpkin seeds buyable (252 / 336), Giant melon locked below Renown 5 and buyable from it (1 008);
   the next square on a 4-square field costs 1 400 with no Renown; Growth 1 costs 28 000, Barn 1 14 000; the next field pet slot shows its new price.
2. Remotes charge exactly those prices: BuySeeds, BuySquare, BuyUpgrade, BuyPetSlot up to slot 5 (280 000 / 746 700). A 6th slot has no price.
3. Selling pays the new sale × size: two Pumpkins of summed size 2.0 pay 2 688 before the pet bonus.
4. No console errors. The live profile is snapshotted right before and restored after.

**Studio-validated (2026-11-03).** Fixture: 1 200 000 Coins, 4 squares (square 1 ripe Corn), Renown 37 points (level 4), 3 field pet slots,
no equipped or placed pets, two Pumpkins of summed size 2.0. All four checks passed:
- The panel in Czech showed every price in check 1. Giant melon showed "Pověst 5".
- The remotes charged exactly: BuySeeds Corn 252, BuySquare 1 400, Growth 1 28 000, Barn 1 14 000, slot 4 280 000, slot 5 746 700; a 6th slot → `maxed`.
- Giant melon seeds → `renown` until the Corn harvest reached level 5, then 1 008.
- The sale paid 2 688. Coins went 1 200 000 → 131 328 as computed.
- No warnings or errors on the server or the client.

Studio Edit mode was refused DataStore access ("Access forbidden") even with API access on, while the playtest server had it. The snapshot, fixture
and restore therefore ran in the playtest server: kick the player (the leave write runs, then PlayerProfile forgets them and shutdown saves nobody),
wait 3 s, write the store, stop. The restore was read back in a fresh playtest.
Noticed: the next-square line says "Renown 0" when a square has no gate (squares 5 and 6); E1d2 rebuilds that section and should leave it out.

**E1d2 — The 36-square field.**
**Layout decided by the user (2026-11-03, option 1 of 2).** The square size stays (5.5 studs) and the ring layout stays.
A converted plot's floor shrinks to a 40 x 16 strip holding the sign side and the 3 incubators, and the field starts right behind it.
The field's rows are 6, 6, 8, 8, 8 squares (36), each row centred on an 8-column grid: 27.5 deep and 44 wide at the back.
The whole plot reaches about as far as the old 4 x 3 field did: ring 1's field ends at radius 137 (ring 2 starts at 165), ring 2's at 210 (hedge 230).
About 7 rows fit before ring 2 or the hedge, so more rows can come later without scene work.
The rejected option 2: three rectangular garden islands off StartLocation. It was rejected because it is a scene job of its own, it would redo E1a1's island, and it
would spread 12 players over 18-24 plots. It may come back with the social / estate milestones.
- **Shape:** `CropConfig.RowWidths = { 6, 6, 8, 8, 8 }`, `GridColumns = 8`, `MaxSquares = 36`.
  Squares are numbered row by row from the plot. The numbers are stored, so the rows are never reordered.
  `Cell` / `SquareAt` give the grid position.
- **Opening squares:** every square is drawn. The player opens any locked one through its hold-to-buy prompt (0.5 s).
  The price and Renown gate come from the number already open: `Expansions[open - StartSquares + 1]`, 32 entries from 1 400 to 907 400, 4.81 M in all;
  Renown 0, 0, 5, 6, 7, 8, 10, then +1 per square up to 35.
  The panel's Bigger field section shows the next price, the missing Renown, and how to buy. The "Renown 0" line is gone.
- **Data:** `Field.Open = { ["n"] = true }` replaces `Field.Count`. A new field opens `StartOpen = { 3, 4, 9, 10 }`, the 2 x 2 block at the front centre.
  A field from before E1d2 (Count = its first squares of 4 x 3) moves onto rows 1-3, grid columns 3-6 (`CropConfig.FromOldSquare`), with its
  `Squares` and the field pets' `Square`. This happens once, on load; `Count` is then dropped.
- **Remote:** `BuySquare(square, expectedOpen)` answers `{ square, open, price }`. It rejects `square` (no such square), `open` (already open),
  `stale`, `renown`, `coins` and `maxed`. Plant and PlacePet need an open square.
- **Reach and feed:**
  - `CropConfig.Reach(square, shape, open)` counts on the grid and keeps only open squares. Tending and the panel use it.
  - The plot feed's `field` is `{ crops, pets }`: 36 two-character squares, `#0` = locked. `cols` / `rows` are gone (the shape is shared config).
  - The panel's square list follows the open set.
- **Drawing (PlotView):**
  - Every row is a plate of overgrown grass, under the soil without a shared face. Open squares are soil on it.
  - On the own plot, locked squares carry the buy prompt (an invisible holder part).
  - Low detail draws the row plates only.
- **Model:** `economy.py` reads `RowWidths` / `GridColumns`, and `cover()` counts reach on the same centred grid (squares opened row by row from the plot).
  The model was re-pinned. `check` passes 50 / 51: Casual's lead (2.93x day 7, 9.93x day 30) waits for E1c3. F2's run with the tools gave 3.04x / 12.2x.

**Implemented (2026-11-03).** Files:
- `CropConfig`, `GardenField`, `PlotView`, `GardenView` (synthetic fields of up to 36 open squares) and `FieldClient`.
- Strings: 12 rows added (`field.prompt.buySquare`, `field.prompt.price*`, `field.prompt.priceRenown*`, `field.expand.next*`, `field.expand.hint`,
  `field.reason.open`), 4 removed (`field.expand.info*`, `field.expand.buy`).
- `economy.py` and its pins.

**Acceptance checks (E1d2).**
1. Migration on the real (old-format) profile: Count 5 with Potatoes on 1-5 and a Tending pet on 3 → open 2, 3, 4, 5, 8, crops there, pet on 4.
2. A new field opens 3, 4, 9, 10 with 4 Potato seeds. The own plot draws 5 row plates, 4 soil squares and 32 buy prompts. The feed holds 36 squares.
3. Buying through the real prompt (hold): any square, 1 400 then 1 700. Then the rejections: Renown 5 for the 7th square (`renown`), a stale
   count (`stale`), an open square (`open`), square 37 (`square`). Plant on a locked square → `square`; on a bought one it works.
4. Reach on the grid: square 9 with the 3 x 3 reach covers 2, 3, 4, 8, 9, 10, 15, 16, 17; with only 3, 4, 9, 10 open → 3, 4, 9, 10.
   Old squares 1-12 map to 2-5, 8-11, 15-18.
5. The panel in Czech: the square list shows the open squares; Bigger field shows the next price, the missing Renown in red, and the hint.
6. Budget: 30 synthetic plots with 36 open squares and pets ≤ 5 000 client instances. No console errors; the live profile is snapshotted right before and restored after.

**Studio-validated (2026-11-03).** All six checks passed:
1. Migration: open `[2,3,4,5,8]`, Potatoes on those squares, the Fox on square 4. The feed was `#0a3a3a3a3#0#0a3#0…`.
2. New field: open `[3,4,9,10]`, Potato 4. Drawn: 5 rows, 4 soils, 32 locks. The prompt read "Koupit políčko / 1400 mincí", hold 0.5.
3. The prompts on squares 36 and 1 bought them for 1 400 and 1 700 (Coins 1 200 000 → 1 196 900), and 30 locks were left. All four rejections and
   both plants answered as expected.
4. Reach as listed, and also 7 / plus → 1, 7, 8, 14 and 36 / 3 x 3 → 27, 28, 35, 36.
5. Panel: squares 1, 3, 4, 9, 10, 36 ("36 Brambora 4:41"); "Další políčko: 2100 mincí", "Potřebuješ Pověst 5", the hint.
6. Budget: 1 931 instances standing at the plaza and 2 131 next to slot 7. A full-detail plot is 711; a mid-detail plot with a full field is 137
   (E1a1's 80 was for plots without a field).
   E1b's 12-square run peaked at 1 322. No warnings or errors on the server or the client.

The screenshot shows the strip, the stepped field outline and the crops. The overgrown plates are close to the island's grass (a stand-in colour, art pass later).
Snapshot, fixture and restore ran in the playtest server (kick first, AGENTS.md → Testing). The restore wrote the old-format profile back: the user's
next join migrates it as in check 1.
Not covered: a second client watching the purchase, phone layout, a player without field access.
- **Later (parked):** rubble / weeds on locked squares, cleared with tools (EXPANSION §6).

**F2 approved by the user (2026-11-03).** F2's model also has the tools at EXPANSION sizes (built in E1c3).

**E1c3 — Garden tools tier 1.** Numbers approved by the user (2026-11-03, "approve with gate tweak"): the EXPANSION §6 effect sizes, prices × 9.33 like
F2, and squares 7-11 one Renown level lower (4, 5, 6, 7, 9 instead of 5, 6, 7, 8, 10). With the tools at F2's numbers alone, Casual's day-7 lead was
2.93x; the reach of the open squares was not the cause (opening them compactly changed nothing by day 7), the gates were.
| Tool | Effect per level | Prices | Renown |
|---|---|---|---|
| 🔍 Seed sorter | size factor × 1.05 / 1.10 / 1.15 | 46 700 / 140 000 / 373 300 | 10 / 18 / 28 |
| 🔔 Cloches | online growth × 1.07 / 1.14 / 1.20 (nothing offline) | 37 300 / 112 000 / 280 000 | 6 / 14 / 24 |
| ✂️ Pruning shears | 5 / 10 / 15 % chance of a second crop of the same size | 56 000 / 168 000 / 420 000 | 12 / 20 / 30 |
- **Data:** `Garden.Tools = { Sorter, Cloches, Shears }` (levels; ids stored, never renamed), cleaned on load.
- **Server (`GardenField`):** `BuyTool(id, expectedLevel)` → `maxed` / `stale` / `renown` / `coins`, else `{ id, level, price }`.
  - Sorter: every harvest (owner and Tending) stores `SizeFactor × (1 + effect)`; `SizeBounds` widens with the top level.
  - Cloches: the online settle's crop growth × (1 + effect), and the State countdown uses the same speed; the absence settle and the pets' aptitude XP do not change.
  - Shears: a roll from the owner and the planting number (its own seed, like Tending's), so a re-join never rerolls. The second crop adds to Items /
    ItemSize, gives no Renown or seed. A Tending pet takes it only while the barn has room; the join notice counts it.
  - The harvest answer carries `extra = true`; State `field.tools`.
- **Client (`FieldClient`):** a Tools section under the upgrades: level, effect now → next in %, the Renown needed in red, price / Max; the BuyTool
  toast reuses the upgrade toast; the harvest toast adds "The shears got you a second one!".
- **Model:** `economy.py` reads `CropConfig.Tools` (pinned as `crop_field_tools`). `check` passes 51 / 51: Casual 3.03x / 7.7x / 12.6x on days
  7 / 14 / 30, Garden main's parity 0.99x, Obby main 3.22x by day 7.

**Implemented (2026-11-03).** `CropConfig`, `GardenField`, `FieldClient`, the `Locale.Number` fix; strings: 11 rows (`field.section.tools`, `field.tool.*`, `field.toast.shears`),
5 contexts widened to tools; `economy.py` and its pins.

**Acceptance checks (E1c3).**
1. Purchases at Renown level 12 with 50 000 Coins: Cloches 1 (37 300) works; Sorter 1 → `coins`, then after +Coins it works; Cloches 2 → `renown`
   (14); Shears at level 3 → `maxed`; a stale level → `stale`.
2. Sorter: the harvest answer's size = `SizeFactor(user, N) × 1.05`.
3. Shears (level 3): planting 101 (roll < 0.15) gives 2 crops and `extra`, planting 100 gives 1.
4. Tending + Shears in the join settle: the Fox on square 30 harvests planting 183 → 2 Potatoes, the notice says 2.
5. Cloches: a fresh Potato's countdown (300 s) is 300 s before the purchase and 281 s after it.
6. The panel in Czech: the Tools rows, the red Renown line, the toasts; no console errors; the live profile snapshotted before and restored after.

**Studio-validated (2026-11-03).** All six checks passed. Fixture: Coins 50 000, Renown 160 points (level 12), Shears 3, open 3, 4, 9, 10, 30.
1. Cloches 1 bought for 37 300. Sorter 1 → `coins`, Cloches 2 → `renown`, Shears → `maxed`, Cloches at level 0 → `stale`; an unknown id is ignored.
   After 4 × +Coins the Sorter cost 46 700 (Coins 16 000 left, as the HUD showed).
2. With the Sorter, planting 201's harvest answered size 0.8201 = `SizeFactor(201)` 0.7811 × 1.05.
3. Planting 101: `extra = true`, Items 3 → 5; planting 100: no extra, 5 → 6. Both without the Sorter at the time, sizes equal to `SizeFactor`.
4. The join settle: the Fox harvested planting 183 → Potato 2, ItemSize 1.5017 (2 × 0.7508), notice `tended = { Potato = 2 }`, replanted from Seeds (7 → 6).
5. A fresh Potato's countdown: 299 s before Cloches 1, 279 s after ((300 − 1) / 1.07).
6. The Czech panel: "Nářadí", "Třídička semínek · 1 / 3", "Plodiny o 5 % větší → o 10 %", "Potřebuješ Pověst 18", "Skleněné poklopy",
   "Zahradnické nůžky · 3 / 3", "Max"; every button glyph fits. No warnings or errors on the server or the client.
   **Found and fixed:** `Locale.Number` wrote the Czech thousands separator (no-break space, 2 bytes) with its bytes swapped, because it groups the
   reversed string. Every Czech number from 10 000 up had shown "��" since L1, and six-digit numbers also had a stray leading separator. It now
   writes "112 000", "1 234 567" and "1500"; English is unchanged. The tools' "%" now sits behind a no-break space.
Snapshot, fixture and restore ran through `BindToClose` writes (AGENTS.md → Testing; the kick recipe ends the playtest now). The restore wrote the old-format
profile back (Count 5): the user's next join migrates it as in E1d2.
Not covered: a phone layout, a Tending pet's second crop against a full barn, a second client.

### E1c — Size roll, tools, field upgrades, market cart (scope 2026-11-02, the user's decisions)
Split into four steps, each validated and committed on its own (decided 2026-11-02):
- **E1c1 Field upgrades** (growth, barn): numbers from ECONOMY, already in the model. Scope below.
- **E1c2 Size roll** (EXPANSION §5.3, without variants): scope below.
- **E1c3 Tools tier 1** (Seed sorter, Cloches, Pruning shears, EXPANSION §6). **Decided:** `economy.py` first models the tools and the size roll
  (the sensitivity run already fails A at +20 % income), then effect sizes and prices go to the user for approval, as the field-pet re-run did.
  **Built 2026-11-03 (above).** It was on hold from 2026-11-02: the user made farming the main game. The 24-hour rule is replaced by parity over days 1-3 and a lead of 3x by day 7 and 10x by day 30.
  The field's economy is being re-tuned first (ECONOMY.md → "Direction change", candidate F1: crop prices × 9.7, 36 squares, early gates); under it the
  tools fit at their EXPANSION sizes.
- **E1c4 Market cart** (EXPANSION §5.2). **Decided:** seeds only for now (fertilisers and decor do not exist): 3-4 daily offers from the UTC day
  (same on every server, per-player quantities), discounted seeds of unlocked crops plus a few seeds of one locked crop as a taste. **Built 2026-11-03 (below).**

**E1c4 — Market cart.** Numbers approved by the user (2026-11-03, after the model run, ECONOMY.md → "Market cart run"). The cart is a section of the
Garden panel (a physical cart can come with the art pass).
- **Offers (`CropConfig.Cart`, `CartOffers(day, level)`):** the day is the UTC day (`CartDay(os.time())`, new offers at 00:00 UTC).
  - Bargain 1: 10 seeds of an unlocked crop at −30 %; bargain 2: 5 seeds of another unlocked crop at −50 % (only with 2+ crops unlocked). The crops
    come from a shuffle seeded by the day, so every player with the same unlocked crops sees the same offers on every server.
  - Taste: 2 seeds of the next locked crop (lowest Renown gate) at the catalogue price, from Renown level 3 (today: Giant melon at levels 3-4).
    Earlier tastes (from level 0-2) put Garden main's parity at 1.14-2.3x; a 2x price put Casual's day-7 lead at 2.86x.
- **Data:** `Garden.Cart = { Day, Bought = { [crop id, + "*" for the taste] = n } }`, cleaned on load, reset when the day changes.
- **Server:** `BuyCart(slot, crop, count)` checks, in order:
  - `stale`: the offer is no longer that crop, or `count` is more than what is left;
  - `soldout`;
  - `barn`: the seed stock limit, as in BuySeeds;
  - `coins`.

  It answers `{ crop, count, price, taste? }`. State `field.cart = { nextAt, offers }`.
  **Plant lost its Renown gate:** seeds the player holds can always be planted (the taste); BuySeeds keeps the gate.
- **Client:** a Market cart section under Seeds with:
  - the countdown to the new offers;
  - one row per offer: crop · left / count, then the discount and the price per seed, or the taste line;
  - a button that buys what is left ("Sold out" once bought).

  At 00:00 UTC the panel asks for a new State. The seed picker lists every crop the player has seeds of.
- **Model:** `economy.py` buys the taste on active days and uses the bargains when it buys those seeds anyway (pinned as `crop_field_cart`).
  `check` passes 51 / 51 (Casual 3.05x / 7.8x / 12.4x, Garden main's parity 0.99x).

**Implemented (2026-11-03).** Files:
- `CropConfig`, `GardenField`, `FieldClient`.
- Strings: 8 rows (`field.section.cart`, `field.cart.*`, `field.reason.soldOut`).
- `economy.py` and its pins.

**Acceptance checks (E1c4).**
1. Offers: the same call twice gives the same offers, and the next day gives other ones.
   - Level 0: only a Potato bargain.
   - Level 3: two bargains and the Giant melon taste.
   - Level 5: melon as a bargain (706 a seed).
2. A cart from the day before (Pumpkin 10 and the taste bought) shows every offer full today; `nextAt` = the next 00:00 UTC.
3. Purchases at level 3 with 3 000 Coins and 28 Potato seeds:
   - the wrong crop → `stale`, and 11 of 10 → `stale`;
   - Pumpkin 10 for 2 350, then again → `soldout`;
   - Potato 5 → `barn` (38 + 5 > 40);
   - the taste → `coins`; after +Coins it works (2 016).
4. The taste's Giant melon can be planted at Renown 3; BuySeeds of Giant melon is still refused (`renown`); the picker lists it.
5. The panel in Czech; no console errors; the live profile snapshotted before and restored after.

**Studio-validated (2026-11-03).** All five checks passed.
- Day 20760 at level 3: Pumpkin 10 @ 235 (base 336), Potato 5 @ 1 (base 2), Giant melon 2 @ 1008 (taste). The next day: Corn, Potato, Giant melon.
  The countdown read 2:13 to 00:00 UTC.
- The panel read "Tržní vozík", "Nové nabídky za 2:11:27", "Dýně · 0 / 10", "Sleva 30 % · 235 za semínko místo 336", "Obří meloun · 0 / 2",
  "Ochutnávka před Pověstí 5 · 1008 za semínko" and "Vyprodáno"; every text fits.
- No warnings or errors on the server or the client.

Snapshot, fixture and restore ran through `BindToClose` writes. Not covered: the panel's re-request at 00:00 UTC (the server's day change was tested
with a stored day), a second client, phone layout.
**Found and fixed (older than E1c4):** with the Garden panel open, the seed picker opened under the panel's stud buttons (their glyphs, ZIndex 2,
drew over the picker's rows). `FieldGui` now uses `ZIndexBehavior = Sibling`; checked in Studio with both open.

**E1c2 — Size roll.** Design check: EXPANSION §5.3 (a continuous roll with a long tail, sale value × size, expected value 1.0 without
tools so the ladder holds, labels normal / Big / Giant, a personal best per crop, the roll fixed per planting so a re-join cannot reroll it,
Tending pets' harvests roll too). Variants, the Harvest Fair and the ledger stay out.
- **The roll (`CropConfig.SizeFactor(userId, planting)`):** lognormal, `exp(σ·z − σ²/2)` with `σ = 0.25` (mean exactly 1), `z` from
  Box-Muller on `Random.new(seed)` with a seed from the owner and the square's planting number `N` (not the Tending roll's seed), `z` capped at
  ±4 (factor 0.36–2.64). **Big** from z ≥ 0.84 (top 20 %, factor ≥ 1.20), **Giant** from z ≥ 1.88 (top 3 %, factor ≥ 1.55). The owner's
  harvest and a Tending pet's harvest of the same planting roll the same.
- **Weight shown:** `CropConfig.Crops[].kg` = the weight at factor 1 (Potato 0.25, Corn 0.5, Pumpkin 6, Giant melon 15), shown as kg × factor
  to 0.1 kg ("Pumpkin, 7.4 kg").
- **Barn (decided):** per crop a count and the summed factor, `Garden.Items[crop]` + `Garden.ItemSize[crop]`; selling k of n pays
  `round(sale × k × ItemSize / n)` (then the pet bonus, `CoinRewards.Grant`) and removes `k × ItemSize / n`. Crops stored before E1c2 count as
  factor 1 (no ItemSize → ItemSize = count). `Garden.BestSize[crop]` = the highest factor harvested. Stored ids: never rename them.
- **Server (`GardenField`):** Harvest rolls and answers `{ ..., size = factor, best = true? }`; the absence settle rolls each pet harvest into
  ItemSize / BestSize (the join notice keeps its counts). State `field` gains `sizes = ItemSize` and `best = BestSize`.
- **Client (`FieldClient`):** harvest toast "+1 Pumpkin · 7.4 kg" + "Big one!" / "Giant!" + "New record!" (+ "Renown 4!" on a level-up); a
  Harvest row shows the count, the best weight ("Record 8.1 kg") and the sale value of the stored sizes on its button.
  `CropConfig.SaleValue(crop, sizeSum)` is the one rounding rule.
- **Economy:** `economy.py` pins σ and the two thresholds and checks the factor's expected value (1 ± 0.005, numerically, with the cap) and the
  Big / Giant shares, so a change to the roll cannot raise income unseen. E1a3's crop XP stays per crop, not per size.

**Acceptance checks (E1c2).**
1. 10 000 rolls of `SizeFactor` in Studio: mean 1 ± 0.01, Big 20 ± 1.5 %, Giant 3 ± 0.5 %, all within 0.36–2.64; the same (user, planting)
   always gives the same factor.
2. A harvested Pumpkin: Items +1, ItemSize + the factor `SizeFactor` gives for its planting, the toast shows 6 × factor kg and the label its
   threshold gives; BestSize changes (and "New record!" shows) only when the factor beats the old best.
3. Selling: three Pumpkins with ItemSize 3.42 pay `round(144 × 3.42)` = 492 before the pet bonus, and ItemSize goes; one of three (remote)
   pays `round(144 × 1.14)` = 164 and leaves 2.28. Crops from before E1c2 (Items 6 Potato, no ItemSize) sell for 12.
4. A Tending pet's harvests while away add their factors to ItemSize; a re-join does not reroll a planting.
5. `economy.py check` passes with the size pins and the expected-value check; `loc.py` check 0 errors, lint within the baseline; the toast and
   the Harvest rows fit in Czech; all of it once through the real UI, no console errors, the live profile snapshotted and restored.

**E1c2 implemented and Studio-validated (2026-11-02)**, in playtests on fixtures in the developer's live profile (snapshot `TestSnapshots`
`profile_9892673032_e1c2`, restored afterwards):
- 10 000 rolls: mean 1.001, Big 20.25 %, Giant 2.96 %, range 0.379–2.635; the same (user, planting) gave the same factor every time.
- Three ripe Giant melons (plantings 200 / 204 / 224, best before 1.5) harvested through the panel: factors 1.161 / 1.623 / 1.332, ItemSize
  4.1154 (their sum); toasts "+1 Obří meloun · 17,4 kg / Pověst 3!", "… 24,3 kg / Obří kus! Nový rekord! / Pověst 4!", "… 20,0 kg / Pořádný
  kus!"; only the Giant moved BestSize. Crops from before E1c2 (6 Potatoes, no ItemSize) were read as size 6.
- Pumpkins with ItemSize 3.42: one sold by remote paid 164 and left 2.28, the other two through the panel paid 328 (492 in all); the 6 old
  Potatoes paid 12; sold-out crops lost their ItemSize. Rows in Czech: "Prodat vše · 328", "Rekord 24,3 kg · 1778"; everything fits.
- Tending 1 (strength 0.2), 4 h away, a ripe Potato on the pet's square: planting 300's Tending roll missed → left for the owner, nothing
  stored. Plantings chosen to hit: the pet harvested 303 and the replants 416 / 417, 418 missed and waits; ItemSize 3.1386 = the three rolls'
  sum, BestSize 1.334 = the largest, seeds 4 → 1, notice `tended = { Potato = 3 }`. A re-join changed no size, record or square.
- `economy.py check` 45 / 45 (check 12: size mean and shares); no console errors on client or server.

**E1c1 — Field upgrades.** Inputs: ECONOMY → upgrades (no Renown gate in the model).
- **Numbers (`CropConfig.Upgrades`, pinned):** Growth 4 levels, 3 000 / 8 000 / 20 000 / 45 000, each level -5 % grow time; Barn 5 levels,
  1 500 / 4 000 / 10 000 / 25 000 / 60 000, each +20 capacity (40 → 140). Upgrade ids are stored: never rename one.
- **Growth** works on earned growth: growth seconds are multiplied by `1 / (1 - 0.05 × level)` (the model's grow time x (1 - step x level)),
  online, offline and for Tending pets; stored `Grown` and `growSeconds` stay as they are; a purchase settles the field first, so the faster
  rate counts from then on. `readyAt` and the shown grow times follow the level.
- **Barn** capacity = 40 + 20 × level, for both limits it sets today: the seed stock (BuySeeds) and the crops a Tending pet may store.
- **Server (`GardenField`):** `GardenRemotes.BuyUpgrade(id, expectedLevel)`; field access only (`locked`); unknown id → no answer;
  `expectedLevel` not the current level → `stale` (out-of-date panel, nothing bought); max level → `maxed`; too few Coins → `coins`.
  Profile `Garden.Field.Upgrades = { Growth = n, Barn = n }`. `GardenRemotes.State` `field` gains `upgrades = { Growth, Barn }` and `barn` (capacity).
- **Client (`FieldClient`):** an "Upgrades" section after Expand: per upgrade its level "2 / 4", what it does now and what the next level gives
  ("Crops grow 10 % faster → 15 %", "Barn 60 → 80"), and a Buy button with the price (greyed without the Coins; "Max" at the top). The barn line
  and the seed buttons use the new capacity; seed and picker grow times show the shortened time.

**Acceptance checks (E1c1).**
1. Growth level 1 bought with 3 000 Coins: Coins -3 000, level 1; a fresh Potato (300 s) ripens after 285 s online (300 × 0.95), not 300; a
   square half grown before the purchase needs 142.5 s more instead of 150.
2. Growth to level 4: the prices charged are 3 000 / 8 000 / 20 000 / 45 000; the fifth → `maxed`, no Coins taken. Barn the same with its
   five prices; level 5 holds 140 seeds (buying the 141st → `barn`) and a Tending pet harvests until 140 crops are stored, not 40.
3. Refused: a stale `expectedLevel` → `stale`; 2 999 Coins for Growth 1 → `coins`; a player without field access → `locked`; an unknown id → no
   answer. A re-join keeps both levels.
4. Offline: an absence of 1 h at Growth 4 gives 0.33 × 3 600 / 0.8 = 1 485 growth seconds (cap still 12 h of absence).
5. The panel through clicks: levels, effects, prices, the Max state, the barn line and seed buttons at the new capacity; Czech fits.
6. `economy.py check` passes with the upgrade prices read from `CropConfig` and pinned; `loc.py` check 0 errors, lint within the baseline.

**E1c1 implemented and Studio-validated (2026-11-02)**, in playtests on fixtures in the developer's live profile (snapshot `TestSnapshots`
`profile_9892673032_e1c1`, restored afterwards):
- Offline: Growth 4 / Barn 5 and `SettledAt` one hour back gave a Giant melon 1 486 growth seconds on join (0.33 × ~3 602 s / 0.8) and a
  countdown of 33 371 s ((43 200 − 1 486) / 1.25). A Tending pet (Tending 6, reach over squares 1–3) stored one crop, 139 → 140, replanted it
  (seeds 7 → 6) and left the other two ripe; at the old limit of 40 it would have stored none. 134 seeds bought to 140, one more → `barn`.
- Panel at the top levels (Czech): "Max" on grey buttons, "Doba růstu −20 %", "Pojme 140 semínek i plodin", barn line 140 / 140, grow times
  Giant melon 9 h 36 min and Potato 4 min; English "Grow times −20 %" / "Holds 140 seeds and crops".
- Buying from zero through the panel: 2 999 Coins → `coins` ("Nemáš dost mincí"), nothing charged; then Growth 1 for 3 000 (12 999 → 9 999),
  toast "Růst: úroveň 1!", row "1 / 4 · −5 % → −10 %". A Potato with 99 growth seconds left now needed 93.9 s (99 × 0.95; check 1's 150 → 142.5
  is the same formula); a fresh Potato is ready in 285 s.
- By remote: Growth 2–4 charged 8 000 / 20 000 / 45 000, Barn 1–5 1 500 / 4 000 / 10 000 / 25 000 / 60 000, the next try of each → `maxed` with
  nothing charged; a stale level → `stale`; an unknown id or a level of 1.5 → no answer. A re-join kept Growth 4 / Barn 5. No console errors.
- Not run: `locked` for a player without field access (every account in Studio has access; it is the first check of the shared `usableField`,
  validated with E1a2).

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

**E1b2 implemented and Studio-validated (2026-11-02)**, through the real UI (clicks, the F key) of a playtest client on a
converted fixture in the developer's live profile (same snapshot, restored afterwards):
- Plot: a converted plot draws no pens (so the pen panel, opened only from pen prompts, cannot open) and the pet on its square with the label
  "Cat Lv 6 ★ / Tending 4"; every square has the prompt "Place pet" / "Move / lift" on F; pressing F at square 7 opened "Pet for square 7".
- Picker at square 6: Phoenix "Tending 7 · works 6 squares", Cat Lv 6 "… · now on square 1", Cat Lv 2 "works 1 square"; hovering a row tints its
  reach (the Phoenix's squares 1-3 and 5-7, as `CropConfig.Reach` gives on 8 squares); a click placed it (toast, pet drawn, tint gone after 3 s).
- Field panel Pets section: one row per pet (square, Tending, reach, "Tending XP: 0.7 / 38.0 h"), Lift (pet back, "Field pets 1 / 2"), Buy of
  slot 3 (9 000 Coins, "Field pets 1 / 3", "All field pet slots bought."). Pets panel: the field pet's tag "Square 1", " · Tending n" on every pet with
  Tending. Conversion and absence toast: "Pens are gone … 2 field pet slots. / 1,000 Coins refunded … / Your penned pet is back … / While you were
  away, your pets harvested 6× Potato."
- Czech: 52 visible texts in the field panel and 9 in the picker, every one fits (stud-brick glyphs measured). Phone portrait gives the same
  result: the panel's texts wrap and grow, its buttons have fixed widths, and the picker is capped at 340 px.
- Budget: 30 synthetic plots with 12-square fields and pets (`GardenViewFake = 30`, `GardenViewField = 12`), the character walked past every plot:
  1 322 client instances at most (limit 5 000). No console errors or warnings.
- Two clients (Server and Clients, test users −1 / −2): Player1 hatched its launch egg (a Cat with Tending, as decision 3 promises), unequipped it
  and placed it on square 1; Player2, 20 studs in front of that plot, drew it with "Cat Lv 1 / Tending 1", no pens and no prompts on the other
  plot; Player1's Lift removed it on Player2's screen. No errors on the server or either client.
- Not covered by a playtest: a player without field access.

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
- **Localization:** Czech overflow screenshots of the panels (the font is now BuilderSansBold, so re-check widths in Czech and the pseudo-language), the Stage 9 exit-door label.
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
