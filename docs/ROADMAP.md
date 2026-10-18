# Oby sandbox — Roadmap

Design lives in [GDD.md](GDD.md); this file is the build order and status. "What next?" is answered from here.

## Workflow

1. **Design check** — confirm the milestone still matches the GDD; fix the GDD first if not.
2. **Scope** — before coding, the milestone section states inputs, outputs, boundary and acceptance checks.
3. **Implement** — code in `src/` (synced by Argon); Studio-only changes (parts, GUI, RemoteEvents) via Studio or MCP,
   listed in the milestone so they are not forgotten (they are not in git).
4. **Studio validation** — MCP playtest runs every acceptance check; console has no new errors.
5. **Status update + commit** — update the status table below, commit code + docs together.

Rules:
- One milestone at a time, in order, unless the order rationale below allows otherwise.
- Acceptance checks are **hard**: phrased so an empty or broken result fails ("second Gold finish pays 0",
  not "pays Coins").
- A design change discovered during implementation: GDD → ROADMAP → code, in that order.

### Status levels (tracked separately, never merged)
| Level | Meaning |
|---|---|
| **Implemented** | code in `src/`, synced to Studio, committed |
| **Studio-validated** | every acceptance check passed in an MCP playtest; no new console errors |
| **Live-validated** | published; checked on a real server with real DataStores |

## Status

| # | Milestone | Implemented | Studio-validated | Live-validated |
|---|---|---|---|---|
| D | Design docs (GDD + roadmap) | ✔ | n/a | n/a |
| M0 | Foundations | ✔ | ✔ | – |
| M1 | Medals & rewards | ✔ | ✔ | – |
| M1.1 | Medal limits visibility | ✔ | ✔ | – |
| M2 | Talents shop | ✔ | ✔ | – |
| R1 | Repeat rewards + shared payout | ✔ | ✔ | – |
| P1a | Pet data + economy | ✔ | ✔ | – |
| R2 | Coin scale ×10 | ✔ | ✔ | – |
| P1b | Egg stand + Pets panel | ✔ | ✔ | – |
| P1c | Pet models + following | ✔ | ✔ | – |
| P1d | Pet XP + levels | ✔ | ✔ | – |
| M3 | Stage unlocks | ✔ | ✔ | – |
| M4 | Challenge coins | – | – | – |
| M5 | Leaderboards | – | – | – |
| P2a | Pet garden: plots, pens, offline income | – | – | – |
| P2b | Pet garden: incubators, feeding | – | – | – |
| P3 | Trading | – | – | – |
| M6 | Balancing pass | – | – | – |
| M7 | Monetization | deferred | | |

Order rationale: M0 unblocks everything. M1 creates Coin income, M2 spends it. R1 opens the economy (repeat rewards)
and adds the single payout point that pets multiply; P1a needs it, and P1b–P1d need P1a (any order among them). M3 needs medals and Coins. M4 adds a Coin source.
M5 is mostly independent (can move earlier). P-milestones may move ahead of M3–M5 if pets take priority, but keep
their own order: P2a needs P1a–P1c (P1d recommended), P2b needs P2a, P3 needs P1 and profile session locking. M6 needs the full loop including the garden.

## Milestones

### M0 — Foundations
- **Inputs:** current `PlayerTimerHandler`, `CheckpointTouchHandler`, `CoinSystem`, DataStores `PlayerCoins`, `PlayerScoresStore`.
- **Outputs:**
  - Stage config ModuleScript: key, display name, order, `T_base`, tier multipliers, unlock rule, unlock price, reward factor.
    Replaces hard-coded `"Stage N"` strings in `TimerStart`, `TeleportToStageN`, `Top10Leaderboard` scripts.
  - Timer on `os.clock()`; client label shows `mm:ss.t`.
  - Per-player profile DataStore (Coins, medals per stage, unlocked stages, collected coin ids, talent levels),
    migrating existing `PlayerCoins` and `PlayerScoresStore` data on first load.
  - Per-player debounces replacing the script-global `lastHitPart` / `h` in timer, portal and checkpoint scripts.
- **Boundary:** no new gameplay (no medals, talents, unlocks yet).
- **Design notes:**
  - `ReplicatedStorage.StageConfig` / `TimeFormat` (shared), `ServerScriptService.PlayerProfile` (server-only).
    Stage scripts resolve their stage from the stage folder they live in, so per-stage copies are identical.
  - Profile store `PlayerProfiles`, key `user_<UserId>`. A failed load blocks saving for that session (never
    overwrite stored data with defaults); missing record → migrate legacy stores (they stay untouched, read-only).
  - Timer protocol on `StageTimerUpdate`: `(elapsed ≥ 0)` = running, client counts locally per frame;
    `(-1, final)` = finished; `(-1)` = cancelled. `StageTimerStopped` ack is retired (remote unused).
  - `h` in kill scripts is keyed by the touching part (already per player) → out of scope.
- **Studio-only changes:** none required (`StageTimerStopped` may be deleted later).
- **Acceptance checks:**
  - Timer label shows tenths and advances (not stuck at `00:00.0`).
  - Profile written on leave and identical after rejoin (Studio API access on).
  - A player with existing `PlayerCoins` / `PlayerScoresStore` data sees the same Coins and best times after migration.
  - Two test players (Studio multi-client) touching the same `TimerStart` both get a running timer.
- **Validation log (2026-10-17, solo playtest, API access on):** label advanced `00:00.1 → 00:01.7`; finish sent
  final `17.9`, panel updated, label faded; death mid-run kept the timer; `TeleportToSpawn` cancelled it.
  Migration: legacy 108 Coins / Stage 1 104 s / Stage 2 163 s → identical profile. Profile on leave
  (118 Coins, Stage 1 17.9) identical after rejoin. Found + fixed: one coin paid +10 (queued body-part touches).
  Test writes to live DataStores were restored afterwards.
  Multi-client (Test → Start Test Session → Server and Clients, + Add Clients): Player1 started at `00:01.8`,
  Player2 then touched the same `TimerStart` and counted `00:00.5 → 00:02.9`; Player1 kept counting
  (`00:19.7` ≈ 1.8 + 17.9 s) and received no extra timer events. Server console clean.
  Test profiles `user_-1` / `user_-2` removed afterwards.

### M1 — Medals & rewards
- **Inputs:** `StageConfig` (tBase, tiers, rewardFactor), `PlayerProfile.Medals`, finish in `PlayerTimerHandler.StopTimer`.
- **Outputs:** tier evaluation at the finish portal; one-time payouts per GDD §5; results popup; medal shown on hub portal.
- **Boundary:** no talents, unlocks or locked-portal UI (M2/M3); portal shows the medal only.
- **Design notes:**
  - Provisional `T_base` in `StageConfig` (GDD §4); medal logic in `StageConfig` (pure: evaluate, payout) +
    `ServerScriptService.StageResults` (best time, medal, Coins, save after a payout).
  - Finish message becomes `StageTimerUpdate(-1, final, result)`; `result` = stage, time, best, newBest,
    medal of the run, best medal, Coins paid, next threshold. Results popup is a code-built LocalScript GUI.
  - Medals replicate as player attributes `Medal_<stage folder>` (0–3); hub portal stars are a client-side
    BillboardGui per portal (each player sees their own).
- **Studio-only changes:** none.
- **Acceptance checks:** first Silver finish pays Bronze + Silver exactly once; repeating Silver pays 0;
  later Gold pays only Gold; medal persists after rejoin.
- **Validation log (2026-10-17, solo playtest, Tutorial T_base 30 / factor 0.5):** 26.0 s → Silver, +30 (109 → 139),
  popup "New record! ★★☆ Silver medal +30 Coins, Next: Gold under 00:24.0"; 26.9 s → Silver, +0, popup without Coins
  line; 7.9 s → Gold, +40 only, "All medals earned!". Stage 1 in 5.0 s → Gold directly, +140 (all tiers).
  Rejoin: `Medal_Tutorial = 3`, `Medal_Stage1 = 3`, 319 Coins, hub portal Stage 1 ★★★, others ☆☆☆.
  Server + client consoles clean. Live DataStores restored to the pre-test snapshot.
  Follow-up (user report): Stage 1 stars sat above the portal frame, hidden behind the top-right coin HUD from
  spawn; moved onto the portal face below the label, sized in studs, unearned stars lighter. Screenshot from spawn:
  all three portals show their stars.

### M1.1 — Medal limits visibility (follow-up, user feedback)
- **Outputs:** score panel limits row (hub: total stars); timer shows best reachable medal + limit; portal stars
  as a SurfaceGui on the gate face; score panel survives respawn (was reset to "Central Island").
- **Boundary:** display only — no change to medal evaluation or payouts.
- **Design notes:** timer start message becomes `StageTimerUpdate(elapsed, stageKey)`; the client derives limits
  from `StageConfig` and medals from `Medal_*` attributes. Short time format `m:ss` (`m:ss.t` if not whole).
  Score panel refreshed server-side whenever the `ScreenGui` is re-created in `PlayerGui` (respawn).
- **Studio-only changes:** `StarterGui.ScreenGui.ScorePanel` height 120 → 150, new TextLabel `StageMedals`
  (RichText, TextScaled) below `StageRecord`.
- **Acceptance checks:**
  - Arriving at Stage 1 with no medal shows `★ 1:52  ★★ 1:17  ★★★ 0:56`; after earning Silver, ★ and ★★ are gold.
  - Timer target reads ★★★ 0:56 at start, ★★ 1:17 after 56 s, ★ 1:52 after 77 s, "no medal" after 112 s.
  - Dying mid-stage keeps stage name, record and limits on the score panel.
  - Portal stars stay fixed on the gate face when viewed from the side.
- **Validation log (2026-10-17, solo playtest):** hub panel "Stars earned: 0 / 12"; Stage 1 panel
  `★ 1:52   ★★ 1:17   ★★★ 0:56`; timer target `00:55.1 ★★★ 0:56 → 00:56.7 ★★ 1:17`, `01:16.1 ★★ 1:17 → 01:17.7 ★ 1:52`,
  `01:51.2 ★ 1:52 → 01:52.7 no medal`; death at 20 s kept the panel (Stage 1, record, limits) and the run.
  Silver in 61.9 s: panel ★ and ★★ gold, ★★★ white; hub "Stars earned: 2 / 12"; popup +60.
  Portal stars are SurfaceGuis on the portal's label face (Back), adornee = portal; side-view screenshot not possible
  (3D viewport rendered blank in captures) — a SurfaceGui cannot face the camera, so the check holds by construction.
  Consoles clean; live DataStores restored to the pre-test snapshot.

### M2 — Talents shop
- **Done early (admin tooling, 2026-10-17):** `ReplicatedStorage.AdminConfig` is the single admin list (client UI and
  server); `ResetPlayerTimer` is checked server-side and is now a full self-reset (fresh profile, medal attributes,
  own Top-10 entries removed, 5 s cooldown); the button needs a confirming second click.
  Validated (solo, admin): one click → "Click again to confirm", nothing reset, reverts after 3 s; two clicks →
  Coins 0, all `Medal_*` 0, portal stars dim, panel "0 / 12", stored profile fresh, own entries gone from both boards
  (other entries kept); console clean; live data restored. Non-admin (multi-client, Player1 uid −1, Admin button
  hidden): `ResetPlayerTimer:FireServer()` from the client left 70 Coins and Tutorial Gold unchanged (also in the
  profile saved on leave); server logged "ignored request from non-admin Player1 (-1)". Test profiles and the
  Tutorial board entry removed afterwards.
- **Outputs:** skills panel lists talents, levels, costs; purchase RemoteEvent; server applies WalkSpeed / jump height /
  double-jump flag on every spawn. Admin toggles stay as debug-only.
- **Design notes:**
  - `ReplicatedStorage.TalentConfig` (shared, pure): talents, per-level costs and effect helpers (GDD §6 numbers).
    `ServerScriptService.TalentService` owns purchases; remotes are created by code in `ReplicatedStorage.TalentRemotes`
    (`Buy` client → server, `Result` server → client).
  - `Buy(talentId, expectedLevel)`: the price is never sent. The server charges `costs[current + 1]` and only accepts
    `expectedLevel == current + 1` (a stale panel, double click or forged level is rejected as "stale"), 0.25 s cooldown
    per player, non-string / unknown ids ignored silently. Success → `AddCoins(-cost)`, `Talents[id]`, save at once.
  - Levels are mirrored to `Talent_<id>` player attributes; the server applies WalkSpeed (base × 1 + 0.06·L) and jump
    (JumpPower × √(1 + 0.08·L), height ∝ power²) on every spawn and immediately after a purchase, always from the
    humanoid's values at spawn (idempotent). `PlayerProfile.ProfileReset` re-publishes talents after the admin reset.
  - Double Jump is client-driven (Roblox jumping is client-side): `TalentDoubleJump.client.luau` allows
    `AirJumps(level)` extra jumps from the attribute. The admin DoubleJump / RunSpeed toggles are untouched.
  - The panel is the existing "Your skills" `HomePanel` (🏠 button): `HomePanel/SkillsPanel.client.luau` builds the rows
    in code (level, next effect, Buy button, red hint on rejection).
  - Also fixed: `ButtonHandler` "click outside closes the panel" tested the AdminPanel's bounds (so any click on a
    panel's background closed it); it now uses the open panel and the GUI inset.
- **Studio-only changes:** `StarterGui.ScreenGui.HomePanel`: mock-up `RunSpeed` row deleted (rows are generated);
  panel height is set by the script. `HomePanel` is now a synced folder (`init.meta.json`) because it holds the script.
  Argon did not map the existing instance and created a second, empty `HomePanel` Frame from disk; the styled children
  were moved into it and the old one deleted — no duplicates remain. No other GUI/part changes.
- **Acceptance checks:** purchase with insufficient Coins is rejected server-side (Coins unchanged);
  bought level applies after respawn and after rejoin; firing the remote with a forged cost/level has no effect.
- **Validation log (2026-10-17, solo playtest, API access on, uid 9892673032 with 320 Coins):**
  forged requests (levels 5 / 99 / −1 / 0 / 2 / NaN / ∞ for Run Speed, 2 for Double Jump, 4 for Jump Height; unknown id,
  numeric / table / nil id, string level) changed nothing (Coins 320, all levels 0; valid-looking ones answered "stale").
  `Buy("RunSpeed", 1, 0, -1000, 0)` (forged cost args) charged exactly 20 (→ 300). Double-fired level 2 → one purchase
  (→ 260). Run Speed 3 (→ 200), Double Jump (→ 50); Run Speed 4 with 50 Coins rejected ("coins", still 50 / level 3);
  Jump Height 1 (→ 20), Jump Height 2 with 20 Coins rejected. Humanoid: WalkSpeed 16 → 18.88 (= 16 × 1.18),
  JumpPower 50 → 51.96 (= 50 × √1.08), identical after a respawn. Stored profile after leaving: Talents
  `{RunSpeed 3, DoubleJump 1, JumpHeight 1}`, Coins 20; after rejoin the same attributes, WalkSpeed and JumpPower, panel
  shows `Run Speed 3/5 · Buy 90`, `Double Jump 1/1 · MAX`, `Jump Height 1/3 · Buy 60`. Real mouse click on "Buy 60" with
  20 Coins → "Not enough Coins" hint, nothing bought. Double jump: three space presses in the air-time sequence produced
  the ground jump plus exactly one air jump. Admin Reset Score: talents 0, WalkSpeed 16, JumpPower 50, panel back to
  `Buy 20` / `Buy 150`. Consoles: only Roblox's own UIBlox "FoundationProvider" warnings. Not covered: a successful
  purchase through the panel button (no spare Coins; the server path is identical to the remote) and a multi-client run.
  Live DataStores restored: profile back to the 320-Coin snapshot; the reset had removed the admin's own Top-10 entries,
  which were re-added (Stage 1 104 s, Stage 2 58.5 s).
  Follow-up (user report, 2026-10-17): (1) the admin Run Speed toggle's "off" restored a hard-coded 16, discarding the
  talent speed — it now restores 16 × the talent factor and keeps the 64 boost if a purchase re-applies the server
  speed; (2) the skills panel is visible from the start but was not tracked as the open panel, so Settings / Admin
  opened behind it — it now counts as open and is closed first. Verified (Run Speed level 4): Settings click → Home
  hidden; Admin click → Settings/Home hidden; Home click → Admin hidden; toggle ON → client WalkSpeed 64, OFF → 19.84.
  The profile had real progress from the user's own play (Run Speed 2, Jump Height 2, Stage 1 Bronze); the two test
  purchases were reverted exactly (Run Speed 2, 191 Coins).

### R1 — Repeat rewards + shared payout
- **Inputs:** `StageResults.RecordFinish`, `CoinSystem` pickup, `PlayerProfile.AddCoins`, GDD §5 repeat reward.
- **Outputs:**
  - `ServerScriptService.CoinRewards`: `Grant(player, baseCoins, source) → paid`. The only place where gameplay pays
    Coins: applies the multiplier (1 until P1), rounds, calls `PlayerProfile.AddCoins`. Future minigames call only this.
    `PlayerProfile.AddCoins` stays for purchases and deductions (no multiplier).
  - `StageConfig.RunReward(stage, medal, finishesToday)` (pure).
  - Profile field `RunsToday = { Day = <UTC day number>, [stageKey] = count }`, reset when the day changes.
  - `RecordFinish` pays medal payout + run reward through `CoinRewards.Grant`; result gets `runCoins`;
    results popup shows the repeat reward on its own line.
  - Coin pickup in `CoinSystem` goes through `CoinRewards.Grant`.
- **Boundary:** no pets, multiplier is a constant 1.
- **Design notes:**
  - `Grant` returns the Coins paid, 0 for a non-positive base (no `CoinsChanged`), nil while the profile is not loaded
    (the pickup coin then stays). `source` (`"medal"`, `"run"`, `"coin"`) is unused until stats/pets need it.
  - Medal payout and run reward are two `Grant` calls (each multiplied and rounded on its own); the result's `coins` is
    the medal payout as paid, `runCoins` the run reward, `runsToday` this stage's finish count today incl. this one.
  - Every finish counts towards `n` (GDD: "earlier finishes"), including finishes without a medal.
  - UTC day = `floor(os.time() / 86400)`; `RunsToday` is replaced by `{ Day = today }` on the first finish of a new day.
    Run counts are saved by the autosave / on leave; a new medal still saves at once (after both grants).
  - `RunReward` rounds once (half up, with a 1e-9 guard against float error in `0.8^n`), so values match the GDD §5 table.
- **Studio-only changes:** none.
- **Acceptance checks:** the same stage finished 3× with Silver in one day pays run rewards exactly
  `max(1, round(R × 0.8^n))` for n = 0, 1, 2 (R = unrounded first-run reward; Tutorial Silver: 4, 3, 2), with the medal
  payout only on the first; a finish without a medal pays 0; a run reward never drops below 1; setting `RunsToday.Day`
  to yesterday resets the count (next run pays `r`); counts persist after rejoin the same day.
  (Design check: the earlier wording `round(0.8 r)`, `round(0.64 r)` rounds twice and disagrees with the GDD formula for
  the Tutorial: round(0.64 × 4) = 3, the formula gives round(3.75 × 0.64) = 2.)
- **Validation log (2026-10-17, solo playtest, API access on, uid 9892673032, Tutorial medal removed from the stored
  profile beforehand):** `RunReward` for all stages × medals × n = 0…9 matches the GDD §5 table (first runs, Gold sums
  23 / 44 / 68 / 89); no medal → 0; n = 50 → 1. Playtest 1: Silver 26.5 s → +34 (medal 30 + run 4), popup
  "+30 Coins" and "Run reward +4 (run 1 today)"; Silver 26.x s → +3; Silver 26.4 s → +2, medal line hidden, "Run reward +2
  (run 3 today)"; coin pickup → +1 (coin hidden); 50.4 s (no medal) → +0, run line hidden. Stored after leaving:
  `RunsToday = { Day = 20743, ["Stage 4"] = 4 }`, Coins 51. Playtest 2 (rejoin): Silver → +2 (run 5 today, n = 4).
  Playtest 3 (count set to 30): Silver → +1. Playtest 4 (`Day` set to 20742, count 31): Silver → +4, "run 1 today";
  stored `RunsToday = { Day = 20743, ["Stage 4"] = 1 }`. Talent purchases still call `AddCoins` (unchanged).
  Consoles: only Roblox's own UIBlox "FoundationProvider" warnings. Live profile restored to the pre-test snapshot
  (11 Coins, Tutorial Gold, no `RunsToday`; `reconcile` adds it on the next load); boards unchanged (no new bests).

### R2 — Coin scale ×10 (user decision 2026-10-17, after the economy review)
- **Inputs:** economy review: per-payout rounding swallows small pet bonuses (+2–4 % of a 1–10 Coin payout pays nothing
  extra); user decision: inflate every Coin amount by 10, no fraction carry; floor, pet values and slot prices stay for M6.
- **Outputs:**
  - Every Coin amount × 10 (GDD updated): medal base payouts 200 / 400 / 800; run reward
    `max(10, round(50 × factor × medal mult × 0.8^n))` (`StageConfig.RunRewardBase = 50`, new `RunRewardFloor = 10`);
    unlock prices 500 / 1 500 / 3 000; talent costs 200 / 400 / 600 / 900 / 1 300, 1 500, 300 / 600 / 1 000; Basic egg 500,
    Golden 4 000; slots 0 / 2 000 / 5 000; sell values 100 / 200 / 500 / 1 500 / 5 000; legacy pickup coin 10.
  - Profile `Version = 3`: a stored record below version 3 gets `Coins × 10` once on load; a record migrated from the
    legacy `PlayerCoins` store gets 10 × the legacy coins.
- **Boundary:** percentages, odds, times, the +50 % cap and the 0.8 decay are unchanged; no fraction carry; the floor
  (Tutorial loop ~1 400 / h) and pet value are left for M6. Pets, medals and boards need no migration.
- **Design notes:** the client UI reads every price from the configs (skills panel, unlock popup, portal lock lines,
  results popup), so no GUI script changes. The migration runs in `PlayerProfile.load` before `reconcile` stamps the
  version, so it happens exactly once per record; a failed load never saves, so it cannot double-apply.
- **Studio-only changes:** none expected (coin counter checked for 5-digit values).
- **Acceptance checks:**
  - every Coin amount in `StageConfig`, `TalentConfig`, `PetConfig` is exactly 10 × its previous value (scripted compare);
  - `RunReward` for all stages × medals × n = 0…9 matches the GDD §5 table (Gold sums 227 / 446 / 668 / 893), never < 10;
  - a stored version-2 record with N Coins loads with 10 N and `Version = 3`, and after rejoin still has 10 N (not 100 N);
    a version-1 record is scaled too and still gets the launch egg;
  - a missing profile migrated from `PlayerCoins` gets exactly 10 × the legacy coins;
  - purchases charge the new prices exactly: Run Speed 1 = 200, Basic egg = 500, slot 2 = 2 000, Stage 2 unlock = 1 500;
  - a Tutorial Gold over a Silver pays medal 400 + run 50; with a +10 % pet 440 + 55;
  - the UI shows the new prices (skills panel `Buy 200`, unlock popup `Unlock for 1500 Coins`) and the coin counter shows a
    5-digit balance unclipped.
- **Validation log (2026-10-17, solo playtests, API access on, uid 9892673032; the user's own running playtest was stopped
  first, with their OK):** Edit mode: all 28 Coin amounts in `StageConfig` / `TalentConfig` / `PetConfig` are exactly
  10 × the old values (Stage 1 unlock 50 → 500 from the M3 follow-up included); `RunReward` first runs 25 / 38 / 50,
  50 / 75 / 100, 75 / 113 / 150, 100 / 150 / 200 and Gold sums 227 / 446 / 668 / 893; minimum over n = 0…60 is 10; no medal 0.
  Playtest 1 (stored version-2 record, 1 Coin): counter 10, portal lock lines `or 500 / 1500 / 3000 Coins`, skills panel
  `Buy 200` / `Buy 1500` / `Buy 300`; stored `Version = 3`, Coins 10. Playtest 2 (rejoin): 10 (not 100).
  Playtest 3 (preset version-1 record: 1 200 Coins, Tutorial and Stage 1 Silver, a Dragon, no pet fields): counter `12000`
  unclipped, launch egg waiting; Stage 3 portal popup `Unlock for 3000 Coins` / `You have 12000 Coins` (screenshot);
  Run Speed 1 −200, launch egg 0, Basic egg −500, Stage 3 unlock −3 000, slot 2 −2 000, a Cat sold +100; with the Dragon
  (×1.1) Stage 1 Gold paid medal 880 + run 110 (+ free Basic egg); without a pet Tutorial Gold paid 400 + 50 (+ egg).
  Stored: Coins 7 840, `Version = 3`. Playtest 4 (profile record removed, legacy `PlayerCoins` = 108): Coins 1 080,
  best times 104 / 163 s from `PlayerScoresStore`. Consoles: only Roblox's UIBlox warnings and one "DataStore request was
  added to queue" on the migration join (migration save and launch-egg save on the same key at once — harmless, every new
  player triggers it). Live DataStores restored to the pre-test snapshot (version-2 profile, 1 Coin, launch egg waiting;
  boards unchanged, Stage 3 key absent); the next real join scales it to 10 Coins.

### P1 — Pets (split into P1a–P1d, design check 2026-10-17)
P1a comes first; P1b, P1c and P1d each need only P1a and can follow in any order. Pets never touch WalkSpeed / JumpPower.

### P1a — Pet data + economy
- **Inputs:** `CoinRewards` (R1), `StageResults` (first Gold), `PlayerProfile`, GDD §7.1–7.3.
- **Outputs:**
  - `ReplicatedStorage.PetConfig`: kinds, rarities, eggs + weights, slot prices, sell values, level curve; pure
    `Roll(egg, rng)`, `PetBonus(pet)`, `Multiplier(pets)`, `XpToNext(level)`.
  - Profile `Version = 2` with `Pets = { [uid] = { Kind, Level, XP } }`, `EquippedPets = { uid… }`, `PetSlots = 1`,
    `NextPetUid = 1`, `FreeEggs = { [eggId] = count }` (existing `reconcile` fills old records; the launch free egg is
    granted once via a flag).
  - `ServerScriptService.PetService` + remotes created by code in `ReplicatedStorage.PetRemotes` (`BuyEgg` — also opens
    a free egg when one is waiting —, `Equip`, `Unequip`, `BuySlot`, `SellPet`; server → client `PetsChanged`).
    The server validates every argument, takes prices from `PetConfig`, rolls itself, deducts with `AddCoins`, and saves
    after purchases and sales.
  - `CoinRewards.Grant` uses `PetService.Multiplier(player)`.
  - First Gold on a stage grants a free Basic egg.
  - Player attribute `EquippedPets` (`"kind:level,…"`) for rendering (P1c).
- **Boundary:** no GUI, models or XP; tested by firing the remotes from the client in `execute_luau`.
- **Design notes (design check 2026-10-17):**
  - Pet uids are **strings** (`tostring(NextPetUid)`): `Pets` is a dictionary keyed by uid, so a DataStore never sees a
    sparse numeric array. Remotes take the uid as a string only (anything else is ignored). The rarity is derived from
    the kind (`PetConfig.Kinds`), never stored.
  - Bonuses are kept in **permille** (Common 20 … Legendary 150, +5 per level above 1) so sums are exact;
    `Multiplier(pets) = 1 + min(500, Σ) / 1000`. `CoinRewards.Grant` rounds half up with the same 1e-9 float guard as
    `RunReward` (e.g. 30 × 1.15 is 34.4999… in floating point but pays 35).
  - Egg weights are integers per 1000 (Basic 600 / 250 / 110 / 35 / 5); `Roll(eggId, rng)` picks the rarity by weight,
    then a kind of that rarity uniformly. The Golden egg is in `PetConfig` for P2b but not sold at the stand
    (`stand = false`): `BuyEgg("Golden")` is ignored like an unknown id.
  - Remotes (`ReplicatedStorage.PetRemotes`): `BuyEgg(eggId)`, `Equip(uid)`, `Unequip(uid)`, `BuySlot(expectedSlot)`,
    `SellPet(uid)`; server → client `PetsChanged(state)` (`{ pets, equipped, slots, freeEggs, multiplier }`, sent after load
    and after every change) and `Result(action, ok, detailOrReason)` so P1b can show a hatch reveal or why a request failed.
    Malformed requests (wrong types, unknown egg / uid) are ignored silently; well-formed but refused ones answer a reason
    (`"coins"`, `"full"`, `"slots"`, `"equipped"`, `"stale"`, `"maxed"`, `"loading"`). One 0.2 s cooldown per player covers all
    pet remotes.
  - `BuySlot(expectedSlot)` follows the talent pattern: accepted only when `expectedSlot == PetSlots + 1` (a double click
    cannot buy slots 2 and 3 at once); the price comes from `PetConfig.SlotPrices`.
  - `BuyEgg` opens a waiting free egg of that kind first (no charge). Inventory cap 50 (`"full"`, also for free eggs, which
    then stay waiting). A sale pays the sell value through `AddCoins` (not multiplied, not a gameplay reward).
  - Purchases, egg opening and sales save at once; equip / unequip are saved by the autosave and on leave.
  - The launch egg: profile flag `LaunchEgg` (false in new and reconciled records) — `PetService` adds one Basic free egg
    and sets it on join, so new and existing players get exactly one. The admin reset returns a fresh profile, so the
    launch egg is granted again after it (consistent with a fresh player).
  - First Gold: `StageResults` calls `PetService.GrantFreeEgg(player, "Basic")` when a finish raises the medal to Gold;
    medals are never revoked, so this happens once per stage. The result carries `freeEgg = "Basic"` for a later popup line.
  - `reconcile` also sets `Version = 2` on old records.
- **Studio-only changes:** none.
- **Acceptance checks:**
  - buying an egg with too few Coins is rejected server-side: Coins and pet count unchanged;
  - remote calls with a forged price, a foreign or non-existent uid, an unknown egg id or a 4th equip with 3 slots
    change nothing;
  - 10 000 `PetConfig.Roll` calls in `execute_luau` match the Basic egg weights within ±1.5 percentage points;
  - with one +10 % pet equipped a 40-Coin payout pays exactly 44; with no pet exactly 40; the total never exceeds +50 %;
  - selling a pet removes it and pays exactly its sell value; an equipped pet cannot be sold;
  - the first Gold on a stage adds exactly one free Basic egg, a second Gold on that stage adds none; the launch free
    egg is granted once (not again after rejoin);
  - after rejoin: identical pets, levels, XP, slots, equipped set and free eggs.
- **Validation log (2026-10-17, solo playtests, API access on, uid 9892673032):** `PetConfig` in Edit mode: 10 000 Basic
  rolls → Common 58.99 / Uncommon 25.71 / Rare 11.11 / Epic 3.66 / Legendary 0.53 % (max deviation 1.01 pp), every kind
  matched its rarity; Golden rolls, an unknown egg returns nil; `XpToNext` 10 / 112 / 316 / 828 for L1 / 5 / 10 / 19, nil at
  20, 6 714 XP from 1 to 20; Epic L1 = 100 ‰, Legendary L20 = 245 ‰, three L20 Legendaries → ×1.5.
  Playtest A (stored v1 profile, 1 Coin): join → `FreeEggs = {Basic = 1}`; `BuyEgg("Basic")` → free Cat, uid "1", Coins 1;
  again → `coins`, and with forged price args → `coins` (Coins 1, 1 pet); `BuyEgg` Golden / "Nope" / 1 / table / nil → no
  reply, nothing changed; `BuySlot(2)` → `coins`, `BuySlot(3)` → `stale`, `BuySlot("2")` ignored; `Equip("999")` and
  `Equip(1)` ignored; `Equip("1")` → attribute `Cat:1`, again → `equipped`; `SellPet("1")` while equipped → `equipped`;
  after `Unequip` → +10 exactly (1 → 11), pet gone, second sale ignored. Stored: `Version = 2`, `LaunchEgg = true`,
  `NextPetUid = 2`. Playtest B (rejoin): no launch egg again (`freeEggs` empty, 11 Coins).
  Playtest C (stored preset: 1000 Coins, Dragon L1, Cat, 3 × Phoenix L20, Dog L3 / 5 XP, uids 1–5 + 7, `NextPetUid = 8`,
  Tutorial Silver, Stage 1 Bronze): `BuySlot(3)` → `stale`; `BuySlot(2, 0, -999)` → exactly −200; `BuySlot(2)` again →
  `stale`; `BuySlot(3)` → −300; `BuySlot(4)` → `maxed`; `BuyEgg("Basic", 0, -1000)` → exactly −50 (Fox, uid "8"); `Equip("6")`
  ignored. Dragon equipped (×1.1): Tutorial Gold 2.1 s → medal payout 40 paid **44**, run reward 5 paid 6, `freeEgg = "Basic"`,
  `FreeEggs = {Basic = 1}`. No pet: Stage 1 Silver 62 s → medal 40 paid **40**, run reward 8. Three Phoenix L20 (uncapped
  +73.5 %): multiplier 1.5, 4th `Equip("1")` → `slots` (equipped unchanged), `SellPet("3")` (equipped) → `equipped`,
  `SellPet("2")` (Cat) → +10 exactly; Tutorial Gold again → medal 0, run reward 4 paid 6 (uncapped would be 7), no second
  free egg. Stored after leaving = state before (Coins 364, 6 pets, slots 3, equipped `3, 4, 5`, `FreeEggs = {Basic = 1}`,
  `NextPetUid = 9`); playtest D (rejoin): identical `PetsChanged` state, attribute `Phoenix:20,Phoenix:20,Phoenix:20`, 364
  Coins. Then `BuyEgg("Basic")` opened the waiting free egg for 0 Coins (Dog, uid "9"); admin Reset Score → 0 Coins, no pets,
  slots 1, attribute empty, `FreeEggs = {Basic = 1}` (fresh launch egg). Consoles: only Roblox's own UIBlox
  "FoundationProvider" warnings and one "DataStore request was added to queue" (egg save and reset save on the same key
  within a second). Not covered: inventory cap 50, multi-client. Live DataStores restored to the pre-test snapshot
  (profile v1 with 1 Coin, boards Stage 1 / 2 unchanged, Stage 4 empty, Stage 3 key absent); the next real join grants the
  launch egg.

### P1b — Egg stand + Pets panel
- **Inputs:** P1a remotes and `PetsChanged`, `PetConfig`, GDD §7.2, §7.5.
- **Outputs:** `EggStand.client.luau` (ProximityPrompt → odds from `PetConfig` + price + confirm → hatch reveal;
  "open free egg" when one is waiting); `PetsPanel.client.luau` (code-built: inventory, equip / unequip, buy slot,
  sell with confirmation, total bonus); **🐶 Pets** button in the top-left icons (🐾 renders as a dark glyph on the dark
  button, so the button uses 🐶).
- **Studio-only changes:** `EggStand` model on the hub (`StartLocation`: Base / Step / Pedestal cylinders, `Egg` ball with
  PointLight and the ProximityPrompt `Prompt` (E, hold 0, range 14), spots, sign) built via MCP at (−1047, 11.8, −452);
  nothing else (the 🐶 button is cloned from the Skills button in code by `ButtonHandler`).
- **Acceptance checks:** the odds shown equal `PetConfig` exactly; buying through the stand with enough Coins deducts
  exactly the price and the new pet appears in the open panel without reopening it; with too few Coins nothing is
  deducted and the stand says why; selling needs a second confirmation and pays exactly the sell value; a free egg is
  opened for 0 Coins.
- **Design notes (2026-10-18):**
  - One small server addition: `PetRemotes.RequestState` (no arguments, 0.2 s pet cooldown) only re-sends `PetsChanged`.
    The server publishes the state once on join, which a client still loading (slow connection) would miss; the new
    `PetClient` module requests it as soon as it listens. Nothing price-bearing was added.
  - `PetClient.luau` (ModuleScript in StarterPlayerScripts) holds the shared client state (PetsChanged, leaderstats Coins,
    sorted inventory); `EggStand` and `PetsPanel` only render it. The Pets panel is its own persistent ScreenGui
    `PetsGui` (ResetOnSpawn off) with a `SetOpen` BindableEvent and an `Open` attribute; `ButtonHandler` (re-created
    per respawn) clones the Skills button for 🐶 and keeps the panels exclusive (opening Pets closes the open slide-in
    panel and vice versa). No outside-click closing for Pets (✕ or the 🐶 button), so the egg stand stays usable.
  - Egg popup: odds rows are generated from `PetConfig.Eggs.Basic.weights` (`%g` of weight / total × 100) with the kinds of
    each rarity; the price line switches to "free egg waiting: 0 Coins" while `freeEggs.Basic > 0`; the button sends only
    `BuyEgg("Basic")`. The egg wobbles ≥ 0.9 s, then the result (kind in rarity colour, bonus, Epic / Legendary glow) is
    shown; refusals are shown with the real numbers ("you need 500, you have 100"; full inventory). It closes itself
    when the player walks 8 studs beyond the prompt range.
  - Sell: first click turns the button into "Sure? +value" for 3 s, the second click sends `SellPet`; an equipped pet's
    Sell shows "Unequip it before selling" without a request (the server refuses it too).

- **Validation log (2026-10-18, solo playtest, API access on, uid 9892673032, stored v3 preset: 2 600 Coins, Dragon + Cat,
  Dragon equipped, 1 slot, 1 free Basic egg; GUI driven with `user_mouse_input` instance paths, the stand with E):**
  🐶 button at x = 250 (admin) opens the panel (Coin bonus +10 %, Equipped 1/1, Pets 2/50, "1 free egg waiting");
  E near the stand opens the popup. Odds labels vs `PetConfig.Eggs.Basic.weights`: 60 / 25 / 11 / 3.5 / 0.5 % — all equal
  (checked in code: `%g` of weight / 10 matches each label). Free egg → Cat, Coins stayed **2 600**, the Cat appeared in the
  open panel without reopening (Pets 3/50) and the button switched to "Open egg: 500 Coins". Paid egg → Coins **2 100**
  (exactly −500), new Cat (uid 4) in the panel at once. Buy slot (panel) → 100 Coins (−2 000), "Slot 2 unlocked", Equipped
  1/2. Egg with 100 Coins → popup "Not enough Coins: you need 500, you have 100", Coins and pets unchanged. Sell: first
  click → "Sure? +100", Coins unchanged; second click → Coins **200** (+100 exactly), pet gone, "Sold for 100 Coins". Equipped
  Dragon's Sell → "Unequip it before selling" (no request). Equip Cat → attribute `Dragon:1,Cat:1`, bonus +12 %. Skills
  button closes Pets and opens Skills. Walking away from the stand closes the popup. Stored after leaving: Coins 200,
  3 pets, slots 2, equipped `2, 1`, `NextPetUid = 5`. Consoles: only Roblox's UIBlox "FoundationProvider" warnings (one
  `execute_luau` typo of mine). Not covered: slow-client `RequestState` race (code path exercised on every join only),
  multi-client, inventory cap, touch / mobile layout; the 🐾 → 🐶 and ✕ → X cosmetic edits came after the playtest.
  Live profile restored exactly to the pre-test snapshot (v2, 1 Coin, free egg + launch flag; `p1b-snapshot.json`).

### P1c — Pet models + following
- **Inputs:** `EquippedPets` attribute (P1a), GDD §7.5 (art: blocky placeholders).
- **Outputs:** `ReplicatedStorage.PetModels` — one blocky part-built model per kind (Cat, Dog, Bunny, Fox, Owl, Panda,
  Dragon, Phoenix): PrimaryPart, Anchored, CanCollide / CanTouch / CanQuery off; `PetFollow.client.luau` renders every
  player's equipped pets behind their owner (local lerp, no server physics) with a rarity-coloured label "Kind Lv N";
  glow for Epic and Legendary.
- **Studio-only changes:** `ReplicatedStorage.PetModels` (Folder, built via MCP): Models `Cat`, `Dog`, `Bunny`, `Fox`, `Owl`,
  `Panda`, `Dragon`, `Phoenix` (15–23 SmoothPlastic parts each, Phoenix crest / wing tips / tail in Neon). Shared chibi
  style: invisible 1-stud `Root` = PrimaryPart at the model origin, front = −Z, body 1.3 × 1.0 × 1.5, head 1.5 × 1.3 × 1.3,
  black eyes with a white shine, 1.5–2.4 studs wide, 2.5–3.5 tall. All parts Anchored, Massless, CanCollide / CanTouch /
  CanQuery off. **Save the place (Ctrl+S) — the models exist only in the place file.**
- **Acceptance checks:** equipping shows the pet within 1 s and unequipping removes it; three equipped pets do not overlap;
  a second client (multi-client) sees the first player's pets following; pets never trigger touch parts (kill parts,
  coins, portals); the owner's WalkSpeed and jump are unchanged with pets equipped.
- **Design notes (2026-10-18):** design check against GDD §7.5 passed unchanged.
  - `PetFollow.client.luau` (StarterPlayerScripts) tracks every player (PlayerAdded / PlayerRemoving + existing players)
    and their `EquippedPets` attribute; an attribute change rebuilds the list, reusing models whose `Kind:Level` stays.
    Entries with an unknown kind or a malformed level are skipped; levels are clamped (`PetConfig.ClampLevel`); at most 3.
  - Pets are clones in a client-local folder `workspace.PetFollowers` (never on the server). The flags are enforced again
    on clone, so a replacement model cannot affect gameplay.
  - Formation: one smoothed anchor per owner (yaw-only CFrame at HumanoidRootPart − 0.5 Y, `Lerp` with 1 − e^(−8·dt),
    jumps when > 40 studs away: teleports, respawns); pets sit at fixed offsets on it (1: right-behind; 2: ±1.8; 3: ±3.2
    and centre 1 stud further back) plus a small per-pet bob. A rigid formation cannot overlap during turns (lerping each
    pet separately would pull side pets together on a 180° turn).
  - No character / HumanoidRootPart (respawning, streamed out) → pets unparented, the anchor jumps on the next spawn.
  - Label: BillboardGui "Kind Lv N" in `PetConfig` rarity colour, 0.5 stud above the model top, MaxDistance 80. Glow:
    PointLight + a small ParticleEmitter in the rarity colour on Epic and Legendary (brighter for Legendary).

- **Validation log (2026-10-18, API access on).** Solo playtest, live profile preset (Dragon, Phoenix, Cat, Owl, 3 slots):
  Equip Dragon → model after **0.07 s**, 2 / 0 / 3.5 studs right-behind the root, label "Dragon Lv 1" in Epic purple, PointLight.
  Three equipped → slots −3.2 / 0 / +3.2 (centre 1 stud further back); smallest gap between parts of different pets
  0.18 studs at rest and **0.17** during 180° / 90° walking turns (bounding-sphere test, so the true gap is larger).
  Unequip each → removed after **0.05 s**. Touch parts, walking with `Humanoid:MoveTo` so the Dragon (left slot) passes
  through the target while the owner stays 3.2 studs beside it, each with a positive control (owner walks through):
  coin — Dragon parts inside the coin for 63 frames, coin still visible, Coins 0; control: collected, +13 (10 × 1.27).
  Kill part (laser strip `Stage1.LaserStripStage.Part_01` moved onto the Stage 1 pad for that playtest only) — Dragon
  inside for 25 frames, health 100 on client and server; control: owner died, respawned, pets back in their slots.
  Hub Tutorial portal — Dragon inside for 62 frames, no teleport (890 studs from the destination); control: owner
  teleported (2.9 studs), pets snapped along. (A first attempt that held the character in place with CFrame writes never
  fires Touched, not even for the owner, so it proves nothing and was replaced by the walking test.) Movement: WalkSpeed
  16 / JumpPower 50 / JumpHeight 7.2 with 0 and 3 pets; measured walking speed 16.00 vs 15.95–16.00; real Space jumps
  7.27 studs ×3 with 3 pets and ×3 with none. Every kind renders (local attribute override `Cat:1,Dog:2,Bunny:3`,
  `Fox:4,Owl:20,Panda:7`, `Dragon:5,Phoenix:99`): labels and rarity colours correct, Lv 99 shown as 20, glow only on
  Dragon and Phoenix; `Zebra:1,Cat:x,Dog:2,,Owl:3,Fox:1` → Dog, Owl, Fox.
  Multi-client (Server + 2 clients, user_-1 seeded with Dragon, Phoenix, Bunny equipped): Player2 saw
  `Player1_Dragon / _Phoenix / _Bunny`, 3 pets every frame during Player1's 49-stud square walk (max 8.2 studs from the
  owner, back to −3.2 / 0 / +3.2 at rest, correct labels); Player1's unequip / equip reached Player2's view **0.03 s** after
  the request; after Player1 left (kick) Player2 showed no pets. Consoles: only Roblox's UIBlox "FoundationProvider"
  warnings (server log empty). Live profile restored exactly to the pre-test snapshot (v3, 0 Coins, free egg + launch flag;
  `p1c-snapshot.json`); `user_-1` / `user_-2` (stale v1 records from an earlier session, `user_-1` reused as the seed)
  deleted. Not covered: StreamingEnabled far-away owners, many players at once (performance), screenshots (3D view
  captures come out blank, so looks were not checked visually — only structurally).
- **Follow-up (2026-10-18, user request): auto-equip on hatch.** GDD §7.3: a newly hatched pet is equipped automatically
  when a slot is free. `PetService` BuyEgg (paid and free eggs) appends the new uid to `EquippedPets` if
  `#EquippedPets < PetSlots` and adds `equipped` to the `Result` detail; the egg stand says "Equipped: it follows you now"
  or "All slots full: swap it in via the Pets panel (🐶 button)". The pet appears behind the player at once, during the
  ≥ 0.9 s egg wobble (before the reveal). Studio-only changes: none.
  Validated (solo playtest, real stand clicks; preset 2 000 Coins, 2 slots, Dog equipped, 1 free egg): free egg → Fox,
  Coins 2 000, `EquippedPets` `Dog:1,Fox:1`, Fox following, "Equipped" message; paid egg with both slots full → Cat,
  Coins 1 500, attribute unchanged, "All slots full" message (fits its line); after unequipping the Dog a paid egg → Dog
  equipped (`Fox:1,Dog:1`), Coins 1 000. Stored after leaving: 4 pets, `EquippedPets = { "2", "4" }`. Console: UIBlox
  warnings only. Live profile restored exactly to the pre-test snapshot (`p1c-autoequip-snapshot.json`).

### P1d — Pet XP + levels
- **Inputs:** `PetService` (P1a), `StageResults`, `CoinSystem`, `PlayerTimerHandler` (running timer), GDD §7.4.
- **Outputs:** `PetService.AddXP(player, amount)` — full XP to every equipped pet, level-ups, `EquippedPets` refreshed;
  called by `StageResults` (the run's medal: 5 / 10 / 20), `CoinSystem` (+1 per coin) and a server-side movement counter
  (only while a stage timer runs, 1 XP per 20 studs, max 30 per run, teleports and respawns ignored).
- **Studio-only changes:** none.
- **Acceptance checks:** a Silver finish gives each equipped pet exactly 10 XP + movement XP ≤ 30; walking with no running
  timer gives 0 XP; a teleport adds no movement XP; a pet crossing `XpToNext` levels up and keeps the remainder; a level-20
  pet gains nothing; XP and levels identical after rejoin.
- **Design notes (design check 2026-10-18):** GDD §7.4 matches the scope; one clarification added there (movement XP is paid
  at the finish).
  - `PetConfig`: `MedalXp = { 5, 10, 20 }`, `CoinXp = 1`, `StudsPerXp = 20`, `MaxMoveXp = 30`; pure `MoveXp(studs)` and
    `GainXp(pet, amount)` (levels up while XP ≥ `XpToNext`, keeps the remainder; at level 20 XP stays 0 and nothing is gained;
    a remainder past level 20 is dropped).
  - `PetService.AddXP(player, amount)` gives every equipped pet the full amount and publishes once (`EquippedPets`
    attribute, `PetsChanged`), so the Coin bonus, follower labels and the Pets panel update live. Returns how many pets
    gained. Not saved at once: XP is small and frequent, so the autosave / leave / shutdown saves cover it.
  - `ServerScriptService.RunDistance` (new module): `Start(player)` / `Stop(player) → studs`, called by `PlayerTimerHandler`
    (start, cancel, finish; a restart on another stage starts from 0). One loop samples each running player's root part
    every 0.25 s; a horizontal step longer than `WalkSpeed × dt × 1.5 + 1` stud (teleports, respawns, flings, bounce
    pads) is dropped entirely; a dead or missing character breaks the segment. The server's WalkSpeed includes the Run
    Speed talent; the admin client-side 64 speed toggle is not replicated, so its steps are dropped too.
  - **Paid at the finish, not continuously:** one XP event per run (one publish, no XP for a cancelled run, a single
    number on the results popup). `StageResults.RecordFinish(player, stageKey, elapsed, studs)` adds medal XP of the run's
    medal (not only a new one) + `MoveXp`; the result carries `petXp`, `moveXp`, `petsLeveled`. A finish without a medal
    still pays movement XP.
  - `CoinSystem`: +1 XP after a successful coin pickup (after the Coin payout, so its multiplier uses the old levels).
  - Client: the Pets panel detail line reads "Rarity · +bonus % · xp/next XP" ("max level" at 20); the sell value moved
    onto the Sell button ("Sell 200", confirm "Sure? +200") because the longer line was truncated. Results popup line
    "Pets +N XP (M from moving)", shown when a pet gained XP.
- **Validation log (2026-10-18, solo playtests, API access on, uid 9892673032, preset from the live profile: 3 slots,
  equipped Dog L1/0, Fox L4/75, Cat L20/0, Run Speed 5 → WalkSpeed 20.8):** Edit mode: `GainXp` L1/0 +10 → L2/0, L4/75
  +10 → L5/5, L1/0 +100 → L4/10, L20 +50 → nil (unchanged), L19/820 +50 → L20/0, +100 000 → L20/0, missing XP treated as 0;
  `MoveXp` 0/19/20/599/600/5000 → 0/0/1/29/30/30. Playtest A: walked 114 studs in the hub with no timer → no `PetsChanged`,
  attribute unchanged (0 XP). Tutorial Gold by teleports → petXp 20, moveXp 0: Dog L1/0 → **L2/10**, Fox L4/75 → **L5/15**
  (crossed `XpToNext` 80, remainder kept), Cat L20/0 unchanged, `petsLeveled` 2, attribute `Dog:2,Fox:5,Cat:20`. Teleport run
  (timer confirmed running, then 8 teleports of 30–40 studs, the character ended up respawned at the pad, finish by
  teleport): 23.4 s Gold, **moveXp 0**, Dog → L3/2. A run cancelled by the pad's TeleportToSpawn portal paid nothing.
  **Silver** 26.9 s walking a rectangle on the pad (client-measured 529.8 studs ≈ 26 XP): petXp **35 = 10 + 25** (server
  counted ≥ 500 studs, slightly under the client, never over), Dog L3/2 → L3/37, Fox L5/35 → L5/70. Bronze 40.4 s, 804
  studs walked: petXp 35 = 5 + **30 (cap)**, Dog → L4/20. Coin pickup: Coins +12 (10 × 1.19) and **+1 XP** (Dog L4/21,
  Fox L5/106). Stored after leaving: Dog L4/21, Fox L5/106, Cat L20/0, equipped `5, 4, 8`. Playtest B (rejoin): identical
  `PetsChanged` state, attribute `Dog:4,Fox:5,Cat:20`, multiplier 1.21 (= 35 + 60 + 115 ‰, was 1.19). With the Pets panel
  open, a Tutorial Gold → Fox row "Lv 6 · +6.5 % · 14/147 XP" and follower label "Fox Lv 6" without reopening; popup line
  "Pets +20 XP (0 from moving)". Detail texts fit (worst case "Legendary · +24% · 827/828 XP" measured 157 of 200 px).
  Consoles: only Roblox's UIBlox "FoundationProvider" warnings. Not covered: multi-client, bounce bricks / spinners during
  a run (dropped or counted as their speed allows), touch layout. Live profile and all four boards restored exactly to the
  pre-test snapshot (`p1d-snapshot.json`); no `user_-1` / `user_-2` records.

### M3 — Stage unlocks
- **Inputs:** `StageConfig.unlock` / `unlockPrice` (GDD §3: Stage 2 = Silver on Stage 1 or 150 Coins, Stage 3 = Silver on
  Stage 2 or 300 Coins), `PlayerProfile.Medals` / `UnlockedStages` / `AddCoins`, hub portal scripts, `Medal_<folder>` attributes.
- **Outputs:**
  - `StageConfig.MedalIndex`, pure `StageConfig.MeetsUnlockBar(stage, medals)`, `StageConfig.UnlockedAttribute(stage)`.
  - `ServerScriptService.StageUnlocks` (module): `IsUnlocked(player, stage)`, `ShowLocked(player, stage)`; mirrors every
    stage's state to `Unlocked_<folder>` player attributes; owns the remotes in `ReplicatedStorage.UnlockRemotes`
    (created by code): `Buy` client → server `(stageKey)`, `Result` server → client `(stageKey, ok, reason?)`,
    `Locked` server → client `(stageKey)` when a locked portal is touched.
  - Hub portal scripts (4 identical copies) teleport only when `IsUnlocked`; otherwise they open the unlock popup.
  - Hub portal face (`HubPortalMedals.client.luau`): lock line "🔒 ★★ Silver on Stage 1 / or 150 Coins" while locked.
  - `StageUnlockPopup.client.luau` (code-built GUI): requirement, price, Coins, "Unlock for N Coins" button, Close.
  - `PortalBarriers.client.luau`: locked portals are walls (user request, see the follow-up below).
  - ~~Tutorial portal on the hub~~ — done in the M5 Tutorial pass 2 (`TeleportToTutorial`).
- **Boundary:** no challenge-coin `x/y` on portals (M4); stages stay physically reachable by other means (checkpoint respawn
  inside a stage during the same session, walking) — only the hub portal is gated.
- **Design notes (design check 2026-10-17, user decisions):**
  - Open = no unlock rule, **or** the bar (required medal on the previous stage, derived from `Medals` every time, never
    stored — medals only go down through the admin reset, which also clears purchases), **or** `UnlockedStages[key] == true`
    (bought). Unlocks are permanent.
  - **No grandfathering:** times or medals already recorded on the locked stage itself do not open it (the admin profile has
    Stage 2 Gold but only Stage 1 Bronze → Stage 2 locked, Stage 3 open via Stage 2 Gold).
  - **Admins follow the same rules** (no bypass), so locks can be tested solo.
  - **No ordering:** every stage can be bought on its own (Stage 3 without Stage 2 open).
  - `Buy(stageKey)`: the price is never sent; server takes `unlockPrice` from `StageConfig`. Non-string / unknown / ruleless
    keys ignored silently; 0.25 s cooldown per player; already open (bought or bar met) → `"owned"`, no charge; too few Coins
    → `"coins"`. Success → `AddCoins(-price)` (purchases bypass `CoinRewards`), `UnlockedStages[key] = true`, attributes, save
    at once. A repeated request finds the stage open → charged exactly once.
  - Attributes are re-published on join, on `ProfileReset` and whenever the prerequisite stage's `Medal_<folder>` changes.
  - A locked touch uses the portal's 2 s per-player cooldown, so standing in the portal does not spam the popup.
- **Studio-only changes:** none (remotes and GUIs are created by code; portal parts unchanged).
- **Acceptance checks:**
  - a locked portal does not teleport (character stays at the hub, score panel still "Central Island") and opens the popup;
  - meeting the bar unlocks without charging: earning Silver on Stage 1 flips `Unlocked_Stage2` to true, Coins unchanged,
    the portal teleports; a `Buy` for that stage then answers `"owned"` with Coins unchanged;
  - buying deducts the price exactly once: with ≥ 150 Coins, `Buy("Stage 2")` fired twice (and with forged extra price args)
    charges exactly 150; with < price Coins it is rejected (`"coins"`, Coins and lock unchanged);
  - forged requests (unknown key, number, table, nil, `"Stage 1"`) change nothing;
  - a bought unlock persists after rejoin (`UnlockedStages[key] = true` stored, attribute true, portal teleports).
- **Validation log (2026-10-17, solo playtest, API access on, uid 9892673032; stored profile was fresh with 1 Coin, preset
  to 400 Coins):** join → `Unlocked_Stage1/Tutorial = true`, `Unlocked_Stage2/3 = false`. Stage 2 portal: character stayed
  at the hub (1006 studs from the Stage 2 destination), panel "Central Island", popup "Stage 2 is locked / Earn ★★ Silver
  on Stage 1 / or unlock it now: / Unlock for 150 Coins / You have 400 Coins"; real click on Close hid it. Forged `Buy`
  (123, table, `"Stage 1"`, `"Stage 4"`, `"nope"`, `true`, nil, `(nil, "Stage 2")`) → no reply, 400 Coins, both locked.
  Stage 3 portal → popup; real click on "Unlock for 300 Coins" → 100 Coins, `Unlocked_Stage3 = true`, popup "Stage 3
  unlocked! / Step into the portal to enter"; `Buy("Stage 3", 0, -1000)` and `Buy("Stage 3")` → `owned`, still 100;
  `Buy("Stage 2")` with 100 Coins → `coins`, still locked. Stage 3 portal then teleported (2.8 studs from the destination,
  panel "Stage 3"). Bar: Stage 1 run in 1.6 s → Gold, Coins 100 → 250 (= payout 140 + run reward 10, nothing charged),
  `Unlocked_Stage2 = true`, portal lock lines hidden; `Buy("Stage 2")` → `owned`, 250; Stage 2 portal teleported.
  Stored after leaving: `UnlockedStages = {"Stage 3": true}`, Coins 250, Stage 1 Gold. Rejoin (Stage 1 medal removed from
  the stored profile so only the purchase can open anything): Stage 3 open and teleports; Stage 2 locked again, portal face
  lock lines `🔒 ★★ Silver on Stage 1` / `or 150 Coins` visible (Stage 3's hidden, none on Stage 1 / Tutorial), touch → no
  teleport + popup. Admin Reset Score → Coins 0, `Unlocked_Stage3 = false`, Stage 3 lock lines shown again.
  Consoles: only Roblox's own UIBlox "FoundationProvider" warnings (plus one error from the test harness's own listener).
  Not covered: multi-client; a portal-face screenshot (3D viewport renders blank in captures, lock lines checked via
  `Visible`/`Text`). Live DataStores restored to the pre-test snapshot (profile 1 Coin, boards unchanged, Stage 3 board key
  absent).
- **Follow-up (2026-10-17, user request): locked portals are walls.** A locked portal used to be a non-colliding opening
  that only refused the teleport. `PortalBarriers.client.luau` now creates, per locked stage, an invisible local part
  (portal width × height, 0.5 deep, centred in the 1.5-deep portal) that collides only for the local player and is removed
  when `Unlocked_<folder>` turns true (treated as locked until the server publishes it). It is thinner than the portal on
  purpose: a player pressed against the wall still overlaps the portal volume, so the touch fires and the unlock popup
  opens. Client-side only; the server check in the portal script stays the authority. Studio-only changes: none.
  Validated (solo playtest, 400 Coins): barriers exist for Stage 2 and 3 only; a character walking into the locked Stage 2
  portal stopped 0.74 studs from its centre, the popup opened, no teleport (1006 studs from the destination); the open
  Stage 1 portal still teleported; after buying Stage 2 its barrier was removed (Stage 3's stayed) and walking into the
  portal teleported (2.9 studs from the destination). Console clean (UIBlox warnings only). Live profile restored to the
  1-Coin snapshot. Not covered: a player standing inside the portal at the moment it becomes locked (admin reset).
- **Follow-up (2026-10-17, user request): Stage 1 is unlockable too.** Design check: GDD said "always open"; the user
  chose **Bronze on Tutorial or 50 Coins**, no grandfathering (existing Stage 1 progress does not open it). Reasons kept in
  mind: a new player has 0 Coins, so the Tutorial is the real way in and must stay completable (Bronze ≈ 48 s, validated
  bot run 17.5 s); the Tutorial income (70 Coins) already sits in the GDD §6 economy table, the 50-Coin price is an optional
  sink (all three unlocks now 500, GDD §6 updated). Change: `StageConfig` Stage 1 `unlock = { stage = "Stage 4", medal =
  "Bronze" }`, `unlockPrice = 50`; GDD §3 table and text. No other code changed (portal gate, popup, face lock lines and
  `PortalBarriers` are all driven by `StageConfig`). Studio-only changes: none.
  Validated (solo playtest, 400 Coins): `Unlocked_Tutorial = true`, `Unlocked_Stage1 = false`; barrier only on Stage 1,
  2, 3; Stage 1 face lock lines `🔒 ★ Bronze on Tutorial` / `or 50 Coins`; walking into the portal stopped 0.87 studs from
  its centre (1150 studs from the destination), popup "Stage 1 is locked / Earn ★ Bronze on Tutorial / Unlock for 50
  Coins"; the Tutorial portal still teleported. Real click on the button → 350 Coins, `Unlocked_Stage1 = true`, barrier
  gone; `Buy("Stage 1", 0, -100)` and `Buy("Stage 1")` → `owned` (350), `Buy("Stage 4")` / `Buy(12)` ignored; walking in
  teleported (2.0 studs). After an admin reset (Coins 0, Stage 1 locked again, barrier back) a Tutorial Gold finish paid
  75 (medal 70 + run 5, nothing charged), flipped `Unlocked_Stage1` to true and removed the barrier; `Buy("Stage 1")` →
  `owned` (75 → 75); walking in teleported. Console: UIBlox warnings plus one DataStore queue notice from the reset's
  burst of saves. Live profile (v2, migrated by the P1a session; free eggs 1, 1 Coin) and boards restored exactly to
  the snapshot taken before the test.

### M4 — Challenge coins
- **Outputs:** stable coin id attribute; server-validated pickup; per-player visibility; `found x/y` on portals;
  first challenge coins placed in Studio per GDD §5 budget.
- **Acceptance checks:** coin collected by player A stays visible for player B; does not reappear for A after rejoin;
  `x/y` matches collected ids; a coin cannot pay twice.

### M5 — Leaderboards
- **Outputs:** Top-10 board on every stage (add Stage 3, Tutorial); hub "most stars" board.
- **Done early (2026-10-17, user request):** Stage 3's landing pad lacked the `Top10Leaderboard` that Stage 1/2 have. The Stage 2
  board model was cloned into `Stage3/LandingPad` at the same relative spot (pad offset −52.2, 0, +0.2); its script is
  byte-identical (stage resolved via `StageConfig.ForInstance`), the disabled legacy `TopTimeScript` was left out. All other
  Stage 2 / Stage 3 pad parts already matched (sizes, colours, portal, timer start, destination). Studio-only: the board
  model. Validated: empty board shows `...` rows; a Stage 3 record (test name, 99.9 s) appeared on the board after the
  poll (`01:39.9`); the test entry was removed again.
- **Tutorial pass (2026-10-17, user request):** Tutorial is unfinished (no hub portal, not in the milestone plan), but its pad now matches
  Stage 2/3 (Top-10 board added the same way; key `Stage 4`). The finish gate was ~170 studs past checkpoint 24 with nothing
  to stand on: added a `Workspace/Tutorial/Course` folder of 14 plain parts (no scripts): 4 wide jump platforms (5-stud gaps),
  3 narrow beams (3 wide, 4-stud gaps), a rest pad with new checkpoint `25`, a 5-platform zigzag and two steps up (+2 each)
  to a landing in front of the gate (portal bottom y 82.45, last step top 82.1). Checkpoint 25 = copy of 24 (script file under
  `Tutorial/25/C`). Studio-only: board model, `Course` parts, checkpoint 25 parts. Validated with a scripted no-talent bot
  (WalkSpeed 16, JumpPower 50, jumps at edges): pad → gate in 17.5 s without a fall, the portal finished the run. Test finish
  (Bronze, +10 Coins, Tutorial best 42 s + board entry) was reverted in the live DataStores. Consoles clean.
  Follow-up (user report): cloned boards still read "Stage 2 - top 10!". The Top10Leaderboard script now sets the
  `DataLabel` title from `StageConfig` (`<displayName> - top 10!`), identical in all four scripts; verified on all four boards.
- **Tutorial pass 2 (2026-10-17, user report):** Studio was reopened from a saved place that lacked the unsaved
  `Tutorial/Course` parts (Studio-only objects are lost unless the place is saved: Ctrl+S after scene changes). Course rebuilt
  with the same 14 parts. Added the hub portal `StartLocation/TeleportToTutorial` (clone of the Stage 2 portal, 18 studs right
  of Stage 1, label "Tutorial access", script file = copy of the other hub portals) and set `StageConfig` Tutorial
  `hubPortal = "TeleportToTutorial"` (M3's "Tutorial portal on the hub" is thereby done; the unlock rule is still open to
  everyone). Validated: touching the hub portal lands on the Tutorial `TeleportDestination`, score panel "Tutorial / First try!";
  a no-talent bot ran pad → last step in 17.5 s without a fall, `leaderstats.Stage` = `25`. The bot's last jump also touched the
  finish gate (Gold 16.1 s, +70 Coins, board entry); reverted in the live DataStores (profile back to 191 Coins, no `Stage 4`).
- **Top-left buttons (2026-10-17, user request):** the 🏠 button no longer opens the skills panel. Now: 🏠 **Home** = new, sends the
  player to the hub (`GoHome` remote, `HomeService`: cooldown 3 s, same effect as a stage `TeleportToSpawn` portal: timer cancelled,
  score panel "Central Island"); ⚡ **Skills** opens the panel (`HomePanel` → `SkillsPanel`, script `TalentRows.client.luau`).
  Order Home, Skills, Settings, Admin. Studio-only: renamed/new buttons, panel renamed (its styled children were rebuilt from
  `SettingsPanel` after Argon replaced the renamed instance). Validated with real clicks: Home from the Tutorial pad → hub spawn,
  panel "Central Island"; Settings hides the open Skills panel; Skills reopens it with the three talent rows.
- **Done early (fix, 2026-10-17, user report):** a new record showed on the board only after a server restart (the board
  polled every 60 s). `PlayerTimerHandler.LeaderboardChanged` now fires after a Top-10 write and boards redraw at once
  (Stage 2 board updated 0.7 s after the finish); empty rows are cleared; the 60 s poll stays for other servers.
- **Acceptance checks:** every board renders 10 rows from the DataStore (or fewer with real data, never blank errors);
  a new personal best appears within one refresh interval.

### P2a — Pet garden: plots, pens, offline income
Scoped in detail after P1 (GDD §7.6). Decided 2026-10-17: island in the same place, 12 plots, 12-player servers.
- **Outputs (draft):** garden island with a central plaza + garden portal on the hub and a return portal; a ring of
  12 plots (~40 × 40 studs, owner sign), each borrowed on join and released on leave, built from a Studio template by
  code; everyone can see all plots, only the owner can use theirs; pens (unlock for Coins) hold pets that are not equipped; production paid through
  `CoinRewards.Grant`; offline production on join capped at 8 h with a "while you were away" popup;
  profile `Garden = { Pens, LastSeen }`.
- **Studio-only changes (draft):** garden island, plaza, plot template and portals (built via MCP from parts);
  **Max Players = 12** in Game Settings (user).
- **Acceptance checks (draft):** a pet cannot be equipped and penned at once; with 12 players every player gets their
  own plot and a leaving player's plot is free for the next one; production after N minutes matches the
  configured rate exactly; offline payout for 20 h equals the 8 h cap; changing the system clock on the client has no effect
  (server `os.time()` only); plot contents identical after rejoin on another server.

### P2b — Pet garden: incubators, feeding
- **Outputs (draft):** incubators (unlock for Coins) hatch Golden eggs in real time, also offline; food bought for Coins
  gives XP.
- **Acceptance checks (draft):** an egg cannot be collected before its hatch time; an egg started before leaving is
  ready after rejoin once the time passed; feeding deducts Coins exactly once and adds exactly the configured XP.

### P3 — Trading
- **Prerequisite:** profile session locking in `PlayerProfile` (`UpdateAsync` with a `{ JobId, Time }` lock instead of
  `SetAsync`; a profile locked by another live server is not loaded until released or stale).
- **Outputs (draft):** trade request → both players add pets/Coins → both confirm the final offer → server swaps
  atomically, saves both profiles immediately, writes a trade log; pets in an open trade are locked; cooldown.
- **Acceptance checks (draft):** changing the offer after a confirmation resets both confirmations; a player leaving
  mid-trade cancels it with no item moved; the same pet cannot end up in both inventories (also across a server
  crash right after the trade); a profile open on server A cannot be loaded for writing on server B.

### M6 — Balancing pass
- **Outputs:** measured `T_base` per stage; finish-time telemetry; tuned numbers in GDD + stage config.
- **Acceptance checks:** every stage has a measured `T_base`; GDD §6 economy constraint table still all ✔.

### M7 — Monetization
Deferred; scoped after M6 (GDD §8).
