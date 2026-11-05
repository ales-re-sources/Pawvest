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
| P2 | Pet garden: plots, pens, incubators, food | ✔ | ✔ | – |
| P3a, P3b | Pet page, pet names | ✔ | ✔ | – |
| H1, H2 | Hub island, stud checkpoints | ✔ | ✔ | – |
| S1–S7 | Stage framework, Quick Respawn, obstacle kit, World 1, worlds hub, World 2, Triple Jump + Dash | ✔ | ✔ | – |
| S8 | World 3 (Stages 11–15) — awaits the user's sign-off | ✔ | S8.1 ✔; S8.2–S8.3 bot-checked, run by the user | – |
| T1a, T1b | Telemetry | ✔ | ✔ | – |
| L1–L3 | Localization (English + Czech) | ✔ | ✔ | – |
| G1 | Player guidance hints — awaits the user's check in play | ✔ | ✔ | – |
| K1 | First-hour fixes (kid playtest 2026-11-01): Stage 5, G1 fallback, Double Jump world reward done; hatch panel proposed | partial | partial | – |
| E0 | Economy model: baseline, simulation, field and every E1–E4 re-run done; repricing and the remaining checks open | partial | – | – |
| E1.0 | Client-drawn plots spike: **GO** | ✔ | ✔ | – |
| E1a–E1d | Crop field behind field access: client-drawn plots, field, field pets, crops as pet food, size roll, upgrades, tools, market cart, farming-first numbers, 36 squares | ✔ | ✔ | – |
| E2 | Obby seeds: rare crops, rare-seed meters, seed pouch, Scouting | ✔ | ✔ | – |
| E4-thin | Crows and Pest-control guards (E4a server, E4b client) | ✔ | ✔ | – |
| OG | Offline crop growth 0.5 / 24 h | ✔ | pending | – |
| E5 | Garden MVP rest: request board, ledger on join, onboarding, garden telemetry | – | – | – |
| M6a | Soft launch + World 1 balancing — World 1 balanced by feel (2026-10-30); live test open | – | – | – |
| MU | Mobile UX check | – | – | – |
| S9, S10 | Wall Jump + Glide, World 4 (drop D8) | – | – | – |
| M6b, S11, M7, trading | Final balancing, bonus stages, monetization (drop D2), trading | – | – | – |

## Next
**Order (2026-10-30, updated 2026-11-05).** The obby (15 stages) goes out first as a soft launch; the garden MVP (EXPANSION §14) is built behind
field access and ships after it. World 4 waits until after the MVP.

1. **Close World 3:** the user's sign-off of Stages 11–15 with the new medal times. Stage 10's times stay (decided 2026-10-30: the fast
   test-account times there need every talent, the Long Dash included).
2. **M6a soft launch** (friends, then unlisted) with 15 stages and today's pets and garden: real finish times, T1a / T1b on the Creator
   Dashboard and a **retention baseline of the obby alone**, to measure later what the garden adds. Includes the live-test checks below.
3. **Offline growth (OG) validation:** a 24 h-back `SettledAt` must give `Grown` = 43 200 for a pumpkin (ripe at 28 800). The same test
   explains the user's pumpkin that still had 5 h 47 min left after 24 h away (at most about 4 h was expected under the old 0.33 / 12 h rules).
4. **E5 + rest of the garden MVP** (scope when it starts; EXPANSION §14): request board, the ledger on join (the join notice grows into it),
   onboarding for the first ten minutes, garden telemetry. Then **E1 ships**: `GardenConfig.FieldAccess = "all"` converts every live player's
   pens on join, Max Players goes to 24 (a place setting), and the open items "When E1 ships" below are checked.
   Gates before going public: M6a, the balancing pass, the Czech review of the new texts, MU, and the comfort shop (D2) or a decision to
   launch without it.
5. **E0 in parallel:** repricing and the remaining checks (section below).
6. **MU** before anything goes public.
7. **Drops D1–D10** after the MVP (EXPANSION §14), one every 1–2 weeks: Critters, Comfort shop (M7), Weekly, Variants, Kitchen (the first
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
- **When E1 ships (FieldAccess "all"):** the paths for a player without field access were checked in code only (`locked`, no field drawn, no
  Feed card); the live pen conversion; 24 plots with fields at once (the budget was checked with synthetic plots only); a second client
  watching a square purchase.
- **The user's checks:** World 3 sign-off (S8); G1 hints in play.
- **Localization:** Czech overflow screenshots of the panels (the font is BuilderSansBold, so re-check widths in Czech and the
  pseudo-language), the Stage 9 exit-door label.
- **Not built:** the pet page's "hatched on … from a Basic egg" line (`Born` / `Egg`).
- **Housekeeping (Studio):** delete `ReplicatedStorage.StageTimerStopped` (unused).

## Done
What was built and why, newest first. Details: the design docs and git history.

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
