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
| E1.0 | Client-drawn plots spike: **GO** | ✔ | ✔ | – |
| E0 | Economy model — partial (baseline, simulation, field); field-pet re-run, repricing and the rest open | partial | – | – |
| M6a | Soft launch + World 1 balancing — World 1 balanced by feel (2026-10-30); live test open | – | – | – |
| MU | Mobile UX check | – | – | – |
| E1a–E5 | Garden MVP (see "Next") | – | – | – |
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
   | **E1a** | Plots for real: `PlotView` draws the garden by default, the ring layout for 8-stud gaps (radius 112 / 185, the island grows), the mid pet detail, `GardenRemotes.Plot` replaces the spike feed (EXPANSION §16 migration list). The field: 4 → 12 squares, first crops, seed catalogue and seed stock, selling, square prompts and a Garden panel | E1.0 |
   | **E1b** | Field pets: pets placed on squares with reach by level, aptitudes rolled at hatch (live pets once from their uid), Tending auto-replant, pens converted to field pet slots and the Coins-per-hour production removed; garden servers of 24 | E0 field-pet re-run |
   | **E1c** | Size roll, tools tier 1 (Seed sorter, Cloches, Pruning shears), Renown, the daily market cart | E1a |
   | **E2** | Seed pouch for medal finishes, rare-seed meter per stage, rare crops of Worlds 1–3 | E1a |
   | **E4-thin** | Crows, Pest-control pets on the field, the forecast line | E1b |
   | **E5 + rest** | Request board, the ledger on join, onboarding for the first ten minutes, garden telemetry | E1b |

   Gates before going public: M6a, the balancing pass, the Czech review of the new texts, MU, and the comfort shop (D2) or a decision to launch without it.
6. **Drops D1–D10** after the MVP (EXPANSION §14), one every 1–2 weeks: Critters, Comfort shop (M7), Weekly, Variants, Kitchen (the first
   restoration landmark), Neighbours, Mastery, World 4 (S9 / S10), the Estate, Season 1. **Spending** grows there: restoration bundles (E6, D5)
   and estate tiers / decor / cottage (E7, D9) are the long-term Coin sinks; E0 holds a placeholder for their size until they are designed.

Pending idea (2026-10-30, not decided): key talents as **world rewards** (Double Jump for finishing World 1, Dash for World 2), Coins buy the
levels and the other talents; it removes two Coin sinks, so talent prices rise in the balancing pass (STAGES §6, GDD §6).

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
- **Field-pet re-run** (before E1b): with reach up to 3 × 3 one Tending pet covers 9 of 12 squares; the value of tended squares, not their count,
  must fit the 24-hour rule. Output: slots, reach and strength numbers, the pen-slot conversion, the seed income per obby hour and rare seeds per
  week at maximum Scouting.
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
- **Housekeeping (Studio):** delete `ReplicatedStorage.StageTimerStopped` (unused) and `ServerStorage.Stage9_OldBigMaze`.

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
