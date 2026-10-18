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
| M4 | Challenge coins | ✔ | ✔ | – |
| M4.1 | Challenge coins, Stage 2 / 3 | ✔ | ✔ | – |
| M5 | Leaderboards | ✔ | ✔ | – |
| P2a1 | Garden island, portals, plot assignment | ✔ | ✔ | – |
| P2a2 | Garden pens, production, offline income | ✔ | ✔ | – |
| P2b1 | Garden incubators, Golden egg | ✔ | ✔ | – |
| P2b2 | Garden feeding | ✔ | ✔ | – |
| P2b3 | Eggs only in the garden (hub stand removed) | ✔ | ✔ | – |
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
- **Inputs:** GDD §5 "Challenge coins" (once per player, saved, hidden only for that player; easy 20 / risky 50 /
  talent-gated 100; budget Tutorial 100, Stage 1 300, Stage 2 400, Stage 3 500), `CoinRewards.Grant`,
  `PetService.AddXP(PetConfig.CoinXp)`, `PlayerProfile.CollectedCoins` (in the profile since M0, still empty),
  the legacy `workspace.CoinsFolder.Coin` pickup in `CoinSystem`, `HubPortalMedals`.
- **Outputs:**
  - `ReplicatedStorage.ChallengeCoinConfig`: tier values, the coin list (`id`, `stage` key, `tier`), `ById`,
    `Found(stage, collected) → x, y`, attribute / tag names, `Encode` / `Decode` of the collected-id string.
  - `ServerScriptService.ChallengeCoins.server.luau`: pickup of every part tagged `ChallengeCoin`; mirrors the collected
    ids to the player attribute `CollectedCoins` (sorted, comma-separated).
  - `StarterPlayerScripts/ChallengeCoinsClient.client.luau`: hides collected coins for the local player only, spins
    the visible ones.
  - Hub portal face: a `💰 found x/y` line per stage with coins.
  - `CoinSystem` keeps leaderstats and the coin counter; its legacy pickup code is removed.
- **Boundary:** first batch only (user decision): Tutorial and Stage 1 coins (10 coins, 400 Coins); Stage 2 / 3 coins
  (900 Coins) are a later pass (done in M4.1), so until then the GDD §6 "earnable before" column is 900 lower for Stage 3 / full tree.
  No popup (the coin counter shows the payout); a pickup sound was added later (follow-up below).
- **Design notes (design check 2026-10-18, user decisions):**
  - **Per player** (confirmed with the user: "disappear once collected" means for the collecting player): the server
    never hides a coin; each client hides the coins in its own `CollectedCoins` attribute (Transparency 1, CanTouch /
    CanQuery off, effects disabled, all local), so other players keep seeing it. A local `CanTouch = false` also stops
    that client's touches from reaching the server.
  - **Legacy coin converted:** its gold mesh (SurfaceAppearance + Highlight) is the look of every challenge coin; the
    part itself moves off the main path and becomes `Stage1_1`. `workspace.CoinsFolder` and `COIN_VALUE` are removed;
    the old server-wide hiding was never saved, so no profile migration.
  - **Ids** are `<stage folder>_<n>` (`Tutorial_1`, `Stage1_3`), stored as `CollectedCoins[id] = true`; never rename or
    reuse one. The part carries the id as attribute `CoinId` and the CollectionService tag `ChallengeCoin`; its value
    comes from the config tier, never from the part. A tagged part with an unknown id, an id whose config stage differs
    from the stage folder it is in, or a duplicate id is ignored with a warning. Stored ids no longer in the config stay
    stored but count for nothing.
  - **Pickup validation** (server `Touched`): a player character with a live Humanoid; profile loaded; id not yet in
    `CollectedCoins`; the character's root within `MAX_REACH` (15 studs) of the server-side coin (rejects touches of a
    coin moved or enlarged on the client). The check-and-mark has no yield, so queued touches of several body parts pay
    once. Then `CoinRewards.Grant(value, "challenge")` (pet multiplier), `PetService.AddXP(CoinXp)`, attribute refresh.
    Saved by the regular autosave / leave / shutdown (Coins and the id are in the same record, so they persist together).
  - `ProfileReset` (admin Reset Score) republishes the empty attribute, so all coins reappear for that admin.
  - **Talent-gated = Double Jump.** Measured in the playtest (JumpPower 50 / 55.7 with Jump Height 3, avatar 5.4 studs
    without accessories): a single Jump Height 3 jump lifts the body ~9 studs, so its top reaches ~15.2 above the floor
    (25.2 at checkpoint 5, standing on the checkpoint plate); a ground jump plus an air jump near the apex reaches ~22.5
    (32.5). The 100 coin sits 18.15 above the checkpoint 5 floor (bottom edge at 26.98): ~1.8 studs out of reach of the best
    plain jump, ~5.5 studs inside a Double Jump. Accessories never collect (their handle's parent is not the character).
    The first placement (15.8 above the floor, from the 6.4-stud textbook jump height) was reachable with Jump Height 3 and
    was raised. Risky coins sit beside the path over the void / lava at roughly chest-to-head height of a jump, so the
    player has to jump out and steer back.
  - Hub portal face: `💰 found x/y` under the stars when the stage is open; while locked the lock lines take that place and
    the coin line moves below them. Hidden for a stage without coins (Stage 2 / 3 until the next pass).
- **Studio-only changes (place file, not in git):**
  - `Workspace.CoinsFolder` deleted (its coin moved, see `Stage1_1`).
  - `Workspace.Tutorial.ChallengeCoins` and `Workspace.Stage1.ChallengeCoins` (Folders), each holding `Coin_<n>` MeshParts
    (clones of the legacy coin: anchored, CanCollide off, CanTouch on, attribute `CoinId`, tag `ChallengeCoin`):

    | Id | Tier | Position | Spot |
    |---|---|---|---|
    | `Tutorial_1` | risky 50 | (−441.0, 80.6, 44.7) | over the void beside the gap between Beam_01 and Beam_02 |
    | `Tutorial_2` | risky 50 | (−456.3, 80.6, −33.5) | over the void beyond the outer edge of Zigzag_04 |
    | `Stage1_1` | easy 20 | (−19.8, 11.6, −3.4) | landing pad, behind the Top-10 board (the legacy coin) |
    | `Stage1_2` | easy 20 | (−5.5, 11.7, −207.6) | JumpPadsStage, far left end of the first pad |
    | `Stage1_3` | easy 20 | (−7.0, 16.1, −167.9) | HarderJumpPadsStage, far left end of Part_4 |
    | `Stage1_4` | easy 20 | (−7.0, 11.8, −114.0) | SpinnerStage_1, exit corner outside the bars' sweep |
    | `Stage1_5` | easy 20 | (7.0, 12.6, −427.0) | RedDivider_1, right corner |
    | `Stage1_6` | risky 50 | (10.8, 13.2, −46.8) | over the void beside the LaserStripStage, between two lasers |
    | `Stage1_7` | risky 50 | (4.5, 16.4, −277.2) | over the lava, off the jump from Union_5 to Union_2 |
    | `Stage1_8` | talent 100 | (0.0, 28.2, −246.0) | 18.15 above checkpoint 5 (Double Jump) |
- **Acceptance checks:**
  - a coin collected by player A stays visible (and collectable) for player B (multi-client, Server and Clients);
  - it pays exactly once: base × pet multiplier and +1 pet XP on the first touch; walking through it again, touching it
    after re-enabling it locally on A's client, or touching a copy enlarged on the client while A stands far from the
    server-side coin pays 0 and changes nothing;
  - it does not reappear for A after rejoin (`CollectedCoins` stored, attribute restored, coin hidden on join);
  - each hub portal's `x/y` equals the number of the stage's config ids in `CollectedCoins` / the stage's coin count
    (Tutorial `0/2` → `1/2`, Stage 1 `n/8`; no line on Stage 2 / 3);
  - admin Reset Score empties `CollectedCoins` and shows every coin again;
  - the talent coin is not touched by a plain jump from the checkpoint 5 pad and is collected with Double Jump.
- **Validation log (2026-10-18, API access on, uid 9892673032; live profile: Run Speed 5, Double Jump, Jump Height 3,
  equipped Cat L3 → multiplier 1.03, 469 Coins, no coins collected):** join → server attribute `CollectedCoins = ""`, all
  10 tagged coins visible / CanTouch on the client, portal lines `💰 found 0/2` (Tutorial), `0/8` (Stage 1), none on
  Stage 2 / 3. Walking into `Stage1_1` behind the board: Coins 469 → **490** (20 × 1.03), attribute `Stage1_1`, coin
  Transparency 1 / CanTouch / CanQuery / Highlight off on the client only, portal `1/8`. Walking back through it: 0.
  **Forged:** coin re-enabled locally (Transparency 0, CanTouch on) and walked through → 12 client-side touches, Coins
  490, no `PetsChanged`; `Stage1_5` enlarged on the client to 80 studs while standing 31.6 studs away → 56 client-side
  touches, Coins 490, attribute unchanged. Then walking into `Stage1_5` normally → 511, Cat XP 50 → **51** (+1 per coin).
  Talent coin at the first height (25.9) was collected by a plain Jump Height 3 jump (body top 25.0) → raised to 28.2
  (see design notes). `Tutorial_1` (character dropped through it from the beam side, then fell and respawned) → +52
  (50 × 1.03 rounded), portal `1/2`. Stored after leaving: `CollectedCoins = {Stage1_1, Stage1_5, Stage1_8, Tutorial_1}`,
  Coins 666, Cat L4/1; `Stage1_8` then removed from the stored record for the retest. **Rejoin:** attribute
  `Stage1_1,Stage1_5,Tutorial_1`, exactly those three coins hidden from the start, portals `1/2` and `2/8`. Raised talent
  coin: `Talent_DoubleJump` attribute set to 0 on the server, single jumps, a double tap and a held Space from the
  checkpoint plate → best top 25.85 incl. hair (coin bottom 26.98), not collected; attribute back to 1, jump + air jump →
  top 33.1, collected, +104 (the Cat had levelled to L4, × 1.04), portal `3/8`. Admin Reset Score → attribute `""`, all
  coins visible again, portals `0/2` / `0/8`; Stage 1 now locked: lock lines at 0.72 / 0.82, coin line moved to 0.91, all
  `TextFits`. **Multi-client** (Server and Clients, Player1 = −1, Player2 = −2, no pets): Player1 walked into `Stage1_1` →
  +20, hidden on Player1's client only; on Player2's client the coin stayed visible (Transparency 0, CanTouch, Highlight
  on), server coin unchanged; Player2 then walked into it → +20 for Player2, Player1 still 20. Consoles: only Roblox's
  UIBlox "FoundationProvider" warnings, the usual DataStore queue notice when a new test profile is created, and errors
  from the test harness's own Heartbeat listener after a respawn. Not covered: a screenshot of the portal face (captures
  timed out; texts and layout checked through properties), the remaining coins walked one by one (positions checked in
  the Edit-mode captures, pickups share one code path), touch devices. Live profile and all four boards restored exactly
  to the pre-test snapshot (`m4-snapshot.json`; the Reset Score had also removed the admin's board entries). The
  test profiles `user_-1` / `user_-2` were stored with `CollectedCoins = {Stage1_1}` and 20 Coins each, then deleted.

### M4.1 — Challenge coins, Stage 2 / 3 (follow-up)
- **Inputs:** GDD §5 budgets Stage 2 400 / Stage 3 500, the M4 code (generic: config entries + Studio parts only), the
  M4 jump measurements (plain Jump Height 3 jump lifts the body ~9–10 studs, Double Jump ~16; talent coin 18.15 above
  its floor).
- **Outputs:** 19 ids in `ChallengeCoinConfig` (`Stage2_1`–`Stage2_9`, `Stage3_1`–`Stage3_10`); Studio parts; hub
  portals `found x/9` and `x/10`. No code change.
- **Design notes (user decisions 2026-10-18):** mix Stage 2 5×20 + 2×50 + 2×100, Stage 3 5×20 + 2×50 + 3×100.
  **Highlight dropped from all 29 coins** (Roblox renders at most 31 Highlights at once); coins keep the gold
  SurfaceAppearance and the spin. `ChallengeCoinsClient` toggles effects generically, so nothing else changes.
  Talent coins sit 18.15 above a flat floor and at least ~15 studs (horizontally) from any higher ground a plain jump
  could start from. Easy coins sit 1.7 above their floor.
- **Studio-only changes (place file, not in git):** Highlight removed from the 10 M4 coins (and the template);
  `Workspace.Stage2.ChallengeCoins` and `Workspace.Stage3.ChallengeCoins` (Folders) with `Coin_<n>` clones of
  `Stage1.ChallengeCoins.Coin_1` (attribute `CoinId`, tag `ChallengeCoin`):

  | Id | Tier | Position | Spot |
  |---|---|---|---|
  | `Stage2_1` | easy 20 | (−343.3, 79.7, 206.1) | landing pad, behind the Top-10 board |
  | `Stage2_2` | easy 20 | (−337.0, 109.3, 122.5) | checkpoint 11 plate, west corner (top of the level 10 tower) |
  | `Stage2_3` | easy 20 | (−333.5, 108.8, 88.0) | level 11 maze, dead-end pocket west of the path |
  | `Stage2_4` | easy 20 | (−347.5, 130.6, −112.0) | far west edge of the 45° ramp, near its top |
  | `Stage2_5` | easy 20 | (−324.0, 131.4, −276.5) | checkpoint 14 plate, east corner |
  | `Stage2_6` | risky 50 | (−325.3, 104.5, 139.0) | over the void east of the level 10 tower (jump from the 99 to the 108 plate) |
  | `Stage2_7` | risky 50 | (−326.2, 128.5, −284.3) | over the void east of the small plate `Part_01` before the finish |
  | `Stage2_8` | talent 100 | (−334.5, 125.2, 78.9) | 18.15 above the maze floor before checkpoint 12 |
  | `Stage2_9` | talent 100 | (−327.0, 153.25, −219.0) | 18.15 above the flat ribbon plate `Part_09` |
  | `Stage3_1` | easy 20 | (−395.5, 79.7, 206.3) | landing pad, behind the Top-10 board |
  | `Stage3_2` | easy 20 | (−381.8, 80.9, 161.0) | level.1 first plate, far corner |
  | `Stage3_3` | easy 20 | (−381.5, 96.9, 65.8) | top of the middle level.2 block, west corner |
  | `Stage3_4` | easy 20 | (−382.0, 84.9, 41.0) | checkpoint 21 plate, west corner |
  | `Stage3_5` | easy 20 | (−382.0, 84.6, −58.0) | checkpoint 22 plate, west corner |
  | `Stage3_6` | risky 50 | (−393.3, 87.25, −10.5) | over the void 4.5 west of the tightrope `Part_17` |
  | `Stage3_7` | risky 50 | (−356.3, 87.25, −24.5) | over the void 4.5 east of the tightrope `Part_19` |
  | `Stage3_8` | talent 100 | (−375.0, 98.35, 144.4) | 18.15 above level.1 plate 2 |
  | `Stage3_9` | talent 100 | (−374.9, 100.9, 20.0) | 18.15 above the straight tightrope `Part_12` |
  | `Stage3_10` | talent 100 | (−360.8, 100.9, −14.2) | 18.15 above the tightrope corner `Part_04` / `Part_19` |
- **Acceptance checks:** portals show `0/9` (Stage 2) and `0/10` (Stage 3) on a fresh profile and count up on pickup;
  every talent coin is missed by a plain Jump Height 3 jump (single, double tap, held Space with `Talent_DoubleJump` = 0)
  from the floor below it and collected with Double Jump; no Highlight left on any tagged coin; no new console errors.
- **Validation log (2026-10-18, API access on, uid 9892673032; live profile: Run Speed 5, Double Jump, Jump Height 3,
  equipped Cat L3, 469 Coins, no coins collected):** 29 tagged coins, 0 Highlights. Join → portals `💰 found 0/2`,
  `0/8`, `0/9`, `0/10`. Talent coins, plain jumps (server attribute `Talent_DoubleJump` = 0; best body top incl. hair vs
  coin bottom): `Stage2_8` 122.44 / 124.00, `Stage2_9` 150.42 / 152.05, `Stage3_8` 95.47 / 97.15, `Stage3_9` 97.90 /
  99.70, `Stage3_10` 98.01 / 99.70 — none collected. A running plain jump from the high edge of the rolled plate `Part_06`
  towards `Stage2_9` (the nearest higher ground) also missed. With the attribute back to 1, jump + air jump from the same
  spot collected each one (tops 129.5 / 158.6 / 103.6 / 103.6 / 106.1; +103 each, +104 after the Cat reached L4), and
  the character landed back on the tightrope. Portals then `2/9` and `3/10`. Walking up the ramp into `Stage2_4` → +21.
  The first `Stage3_3` spot (floor of the 2.7-stud slot between two blocks) was too narrow for a character (stuck after
  1 stud) → moved onto the middle block's top; second playtest: walking into it → +21. Stored after leaving:
  `CollectedCoins` = the collected ids, Coins 1007 (first test), then restored. Consoles: only Roblox's UIBlox
  "FoundationProvider" warnings. Not covered: the easy / risky coins other than `Stage2_4` / `Stage3_3` were not walked
  (positions raycast onto their floors; same code path as M4); a visual capture (Studio viewport captures came back
  blank after the playtest); multi-client (unchanged code). Live profile restored exactly (deep-equal) to the pre-test
  snapshot (`m4b-snapshot.json`) after each playtest; the four boards were never changed; no test profiles created.

### M4.2 — Challenge coin pickup sound (follow-up, user request 2026-10-18)
- **Outputs:** `ChallengeCoinsClient` plays a sound when the local player's `CollectedCoins` attribute gains an id after
  its first publish (so never on join, never for a reset that removes ids); one local clone of the template under
  `SoundService`, `:Play()` restarted per pickup, heard only by the collecting player.
- **Studio-only changes:** `ReplicatedStorage.ChallengeCoinSound` (Sound, free Creator Store asset 93529351909119
  "retro coin pickup sound effect powerup" by Greengem353, credits LilMati on freesound; 0.48 s, Volume 0.6). Without it
  the pickup is silent (no error). To swap the sound, change its `SoundId` in Studio.
- **Validation log (2026-10-18, solo playtest, live profile with `Tutorial_1`, `Tutorial_2` already collected):** template
  loaded on the client (`IsLoaded`); after join with two collected ids no clone existed (nothing played); walking into
  `Stage1_1` → clone created under `SoundService`, `IsPlaying` true; walking into `Stage1_5` → `Played` fired again, still one
  clone. Consoles: UIBlox warnings only. Not covered: how it sounds (listen in Studio). Live profile restored exactly to
  the pre-test snapshot (`m4-sound-snapshot.json`).

### M5 — Leaderboards
- **Outputs:** Top-10 board on every stage (add Stage 3, Tutorial); hub "most stars" board.
- **Scope of the hub board (design check 2026-10-18, matches GDD §8):** global "most stars" Top-10 on the hub; max
  3 × number of stages (12 with four stages).
  - **Inputs:** `PlayerProfile.Medals`; stage count from `StageConfig` (`TotalStars`, `MaxStars`).
  - **Design notes:** `ServerScriptService.StarBoard` keeps an OrderedDataStore `MostStars` (key = UserId, value = total stars;
    no entry = 0 stars). The profile is the source of truth, the store is only a ranking. Writes happen only when the
    total changes: `StageResults` calls `StarBoard.Sync` after a new medal, the profile reset (`PlayerProfile.ProfileReset`)
    removes the entry, and on join the stored value is read once and corrected if it differs from the profile (this also
    back-fills existing players). A failed profile load (`PlayerProfile.CanSave` false) never writes. Reads: one
    `GetSortedAsync` per minute per server (rate-limited to one per 10 s), names via `GetNameFromUserIdAsync` (cached,
    pcall, fallback "Player <id>"). A write by this server is layered over the read for 2 minutes and redraws the board at
    once through `StarBoard.Changed`; other servers show it at the next refresh. The hub score panel uses the same
    `StageConfig.TotalStars`.
  - **Studio-only changes:** `Workspace/StartLocation/StarsLeaderboard` (clone of a stage `Top10Leaderboard` model without
    scripts, placed north-west of the hub spawn, facing it). Its script is `StartLocation/StarsBoard.server.luau`, beside the
    model, because Argon does not turn a Studio-only model into a synced container.
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
  a new personal best appears within one refresh interval. Hub board: renders up to 10 rows from `MostStars`
  (empty rows `...`, never blank errors); a player's first new medal moves their total on the board within one refresh
  interval (at once on the same server); the totals equal the profile medals (`StageConfig.TotalStars`); the admin reset
  removes the admin's entry (0 stars).
- **Validation log (2026-10-18, solo playtests, API access on, uid 9892673032, live profile with 4 × Gold = 12★):** 11 test entries (ids 1–11, 1–11★) seeded in `MostStars`. On join the missing entry was back-filled: store 12, board row 1 "12 / 12", then rows 11 … 3★ (10 rows, the 11th and 12th entries cut; unresolvable names show "Player <id>"). Admin Reset Score: entry removed (store nil), board redrew within the 4 s check, and the forced re-read refilled row 10 (a second playtest). First new medal after the reset: Stage 1 Gold → store 3, board "3 / 12" at rank 10 at once; Stage 2 Gold → store 6, rank 6 (ties sorted by name); `Medal_<folder>` attributes and `StageConfig.TotalStars` agree with the stored values. An entry written to the store from "another server" (id 2 → 12★) showed on the board 9 s later (poll). Consoles: only the usual UIBlox warnings and the DataStore queue notice. Not covered: a screenshot of the board (viewport captures came back blank), two real servers, touch devices. Live profile, the four stage boards and `MostStars` (was empty; test keys removed) restored exactly to the pre-test snapshot (`m5-snapshot.json`). **The place must be saved** (Ctrl+S): the board model is Studio-only.
- **Avatars on the boards (2026-10-18, user request):** every board row shows the player's head shot in the existing
  `Photos.Photo1..10` ImageLabels. `ServerScriptService.AvatarThumbs` fetches it on the server (`GetUserThumbnailAsync`, HeadShot
  100×100), caches it in memory for 30 min and keeps the placeholder image when the lookup fails or the thumbnail is not ready;
  nothing is stored in a DataStore (the image id changes with the avatar). Stage Top-10 entries now also store `UserId`
  (`{ PlayerName, Elapsed, UserId }`); entries written before that resolve the UserId by name (`GetUserIdFromNameAsync`, cached)
  and gain `UserId` on that player's next record. Empty rows hide their photo. The four stage board scripts stay byte-identical.
  Validated in a playtest: hub board rows 1–10 got `rbxthumb://type=AvatarHeadShot&id=…` for existing accounts and kept the
  placeholder for deleted ones; legacy Stage 2 entries (no UserId) resolved by name; a new finish stored `UserId` in the board
  entry and showed the avatar at once; empty rows hidden. Data restored to the M5 snapshot. Not covered: a visual check
  (viewport captures were blank).


### P2a — Pet garden: plots, pens, offline income
Scoped 2026-10-18 (GDD §7.6, numbers settled with the user), split in two so the island can be validated before the economy.
Decided 2026-10-17: island in the same place, 12 plots, 12-player servers. Settled 2026-10-18: production 10 / 20 / 40 / 70 / 120
Coins/h per rarity at Lv 1, +4 % per level; 6 pens at 0 / 1 000 / 2 500 / 5 000 / 9 000 / 15 000; plots 40 × 40 studs; penned
pets are shown as models (reused `ReplicatedStorage.PetModels`) with a label.

#### P2a1 — Garden island, portals, plot assignment
- **Inputs:** hub portals (Studio-only models), `HomeService`, `PlayerTimerHandler.ResetTimer`.
- **Outputs:**
  - `ReplicatedStorage.GardenConfig`: plot count / size, `NewAssigner(count)` (pure plot assigner: `Claim(key)` → lowest free
    index or nil, `Release(key)`, `IndexOf(key)`), plot attribute names.
  - `ServerScriptService.GardenPlots` (module, required by `Garden.server.luau`): every player borrows the lowest free plot on
    join (also while still on the hub) and releases it on leave; player attribute `GardenPlot` = plot index (absent when none);
    plot model attributes `OwnerUserId` / `OwnerName`; the plot sign reads the owner's name, or "Free plot".
  - `ServerScriptService.Garden.server.luau` (boot script: starts `GardenPlots`, later `GardenService`): hub portal `TeleportToGarden` → `Garden.Arrival`; garden `ReturnPortal` → hub
    spawn, cancels a running timer (like `HomeService`); touch debounce per player, no script inside any Studio part.
- **Studio-only changes:** `Workspace.Garden` (island at x −1200, z −750, y 16; plaza; invisible barrier ring so nobody can fall
  off, because a death respawns at the last stage checkpoint; `Arrival`; `ReturnPortal`; `Plots/Plot_01..12` on a ring of
  radius ~90, each a Model with `Floor` 40 × 40, border, `Sign` with SurfaceGui text, facing the plaza); hub
  `StartLocation.TeleportToGarden` (a stripped clone of a hub portal: no script; label "Pet garden"); **Max Players = 12**
  in Game Settings (user, Game Settings → Places).
- **Acceptance checks:**
  1. the assigner hands out indices 1–12 to 12 distinct keys exactly once each, the 13th key gets `nil`; releasing key 5 and
     claiming a new key returns 5; claiming twice for one key returns the same index; releasing an unknown key changes nothing;
  2. real server with ≥ 2 clients: each player has a different `GardenPlot`, `OwnerName` on the plot and the sign text equal
     the player's name, all other plots read "Free plot"; after one client leaves its plot reads "Free plot" and the next
     joiner gets that index;
  3. hub portal → the character stands on the plaza (within 10 studs of `Arrival`); the return portal and the Home button →
     hub spawn (within 20 studs of `SpawnLocation`); a stage timer started before is cancelled by the return portal;
  4. all 12 plots exist, are 40 × 40 and are visible to every client (no per-player hiding); the barrier encloses the island
     (a raycast from the plaza centre outwards hits a barrier part in 8 directions);
  5. consoles clean (no new warnings besides the known UIBlox / DataStore notices).

- **Validation log (2026-10-18, solo playtest + Server and Clients with 3–4 test clients):** (1) assigner unit tests in Edit mode:
  12 keys → 1..12 once each, 13th nil, same key → same index, release 5 → new key gets 5, lowest free first, unknown release
  no-op — all pass. (2) Solo (uid 9892673032): `GardenPlot` = 1, `OwnerName`/sign "Lekzdrh", plots 2–12 "Free plot". Multi-client:
  Player1/2/3 got plots 1/2/3 with matching attributes and signs; Player1's client saw all 12 signs; after Player2 was kicked plot 2
  read "Free plot" on the server and on Player1's client; the next joiner (Player4) got plot 2. (3) Hub portal → 3.4 studs from
  `Arrival`; return portal and the Home button → 3.6 studs from the hub `SpawnLocation`; a running Stage 1 timer (5.4 s) was
  cancelled by the return portal (label hidden, stayed at 11.3 s). (4) 12 plots, floors 40 × 40, no floor overlaps
  (`GetPartBoundsInBox`); raycasts from the plaza in 8 directions hit `Barrier_n` at 142.7 studs (hedges below them). (5) Consoles:
  only the usual UIBlox warnings and the DataStore queue notice. Not covered: 12 real players at once (the assigner is unit-tested to 12),
  a visual check (viewport captures are blank). **Max Players** (Creator Hub "Maximum Visitors Count") was set to 12 by the user on 2026-10-18 (Studio had reported 60 before; the Hub said 50). Studio-only:
  `Workspace.Garden`, `StartLocation.TeleportToGarden` — **save the place (Ctrl+S)**. Test profiles `user_-1`..`user_-4` created by
  the clients are removed in the P2a2 cleanup.

#### P2a2 — Garden pens, production, offline income
- **Inputs:** P2a1, `PetService`, `CoinRewards`, `PlayerProfile`.
- **Outputs:**
  - `GardenConfig`: rates per rarity, `LevelRate` (+40 ‰ per level), `PenPrices`, `OfflineCapSeconds` = 28 800, `PayoutSeconds` = 300;
    pure helpers `Units(pet)` (rate × (1000 + 40 × (level − 1)), integer), `Settle(pets, carry, seconds)` →
    `(whole base Coins, new carry)` using integer math (Coins = floor((carry + Σunits × seconds) / 3 600 000)).
  - profile field `Garden = { Pens = { ["1"] = uid, … }, PenCount = 1, LastSeen = os.time() | nil, Carry = 0 }` (additive, filled
    by `reconcile`; `PROFILE_VERSION` stays 3). `GardenConfig.IsPenned(profile, uid)`.
  - `ServerScriptService.GardenService` (module, required by `Garden.server.luau`) with `GardenRemotes`: `Place(penIndex, uid)`, `Remove(penIndex)`, `BuyPen(expectedPen)`, `RequestState()`
    (client → server); `State(state)`, `Result(action, ok, detail)`, `Away(info)` (server → client). Settles before every
    change, on join (elapsed since `LastSeen`, capped at 8 h) and every 5 minutes online; pays with `CoinRewards.Grant(player, base, "garden")`;
    `LastSeen` is only ever set from the server's `os.time()`; no remote carries a time.
  - `PetService`: `Equip` rejects a penned pet (`"penned"`), `SellPet` rejects it, `Place` rejects an equipped pet (`"equipped"`);
    the Pets panel marks penned pets ("In pen") and disables Equip / Sell for them; `PetsChanged.penned` lists the uids.
  - Garden rendering by the server from the profile: per plot six pens (locked / empty / occupied), pet models cloned from
    `PetModels` with a label (`Kind Lv N · X/h`, rarity colour; Epic / Legendary glow as `PetFollow`), updated on every change.
  - Client: `GardenClient.client.luau` — pen prompts enabled only on the player's own plot, pen panel (buy / place from the
    unequipped, unpenned pets / remove), "while you were away" popup after the join payout, a small "+N Coins" toast on a payout.
- **Studio-only changes:** six pen pads per plot (`Pen_1..6` with a `Spot` part for the model, a `Prompt` ProximityPrompt and a
  sign), `Away`/panel GUI is built in code (no Studio GUI).
- **Acceptance checks:**
  1. a pet cannot be equipped and penned at once: `Place` of an equipped uid → rejected, `Equip` of a penned uid → rejected,
     `SellPet` of a penned uid → rejected, state unchanged each time; remove then equip works;
  2. production is exact: `Settle` over any split of 2 h (one call, 120 × 1 min, 24 × 5 min, uneven pieces) gives the same Coins
     and the same carry; the value equals floor(rate × (1 + 0.04 × (level − 1)) × hours) for a pen set with each rarity;
  3. offline payout on join equals `Settle(elapsed)` for the real elapsed time (checked against the popup's reported seconds and
     base Coins; paid = rounded base × the pet multiplier); a profile with `LastSeen` 20 h ago pays exactly the 8 h cap
     (reported seconds = 28 800) and the popup says "capped"; a profile with `LastSeen = nil` or in the future pays 0;
  4. production accrues only while a pet is penned: place a pet, wait, remove, wait → no payout for the empty time (settle
     before every change); buying a pen does not pay for the past;
  5. the client clock has no effect: no remote takes or returns a time (grep), `LastSeen` is written only from `os.time()` on the server;
  6. plot contents identical after rejoin: pens, models, labels and the sign match the profile before and after leaving
     and rejoining (also compared by plot attributes), and the pen count / prices follow `GardenConfig.PenPrices` exactly once;
  7. only the owner can use their plot: a `Place` / `Remove` / `BuyPen` from a player on another plot or with a bad index,
     uid or type changes nothing (the server derives the plot from the caller);
  8. consoles clean; live profile, Coins and boards restored exactly from the snapshot.
- **Implementation notes:** `Place` / `Remove` / `BuyPen` require the caller to stand within 45 studs of their plot (reject `"far"`);
  the plot is derived from the caller, so no request can name another plot. A hand-edited profile is cleaned on join (missing
  or duplicate pets, pens beyond `PenCount`, `PenCount` clamped to 1..6, bad `Carry` / `LastSeen`); a pet that is both equipped and
  penned stays penned and is dropped from the equipped list. Join payouts reach the client through `Payout` (shown once per
  `id`, re-sent on `RequestState`). `GardenClient` also opens a pen when the `OpenPen` attribute of its ScreenGui is set (test hook).
- **Validation log (2026-10-18, uid 9892673032, live profile snapshot `p2a-snapshot.json`; Server and Clients with test users):**
  (1) exclusivity — `Place` of an equipped uid → `equipped`, of a penned uid → `penned`; `Equip` / `SellPet` of a penned uid →
  `penned`; locked pen → `locked`, occupied → `occupied`; unknown uid and wrong argument types change nothing; remove then equip
  works (after taking a pet out of its pen it equips; an equipped pet cannot be penned; unequipping then penning works). (2) production — Edit-mode unit tests of `GardenConfig`: each rarity at Lv 1 yields
  exactly 10 / 20 / 40 / 70 / 120 Coins in 1 h; Phoenix Lv 20 = 211 Coins + 0.2 carry; a mixed 6-pen set (392 Coins/h) gives 784
  in 2 h as one call, 120 × 1 min, 24 × 5 min and an uneven split, same carry each time; 20 h capped = the 8 h production (3 136).
  Live: Phoenix Lv 1 (120 Coins/h) penned for 97 s of server time after 95 s of an empty pen paid exactly 3 Coins (carry-exact
  expectation 3.70–3.83; the empty 95 s paid nothing); the online tick fired at the first 30 s check after 300 s (+10 for
  ~305 s). (3) offline — LastSeen 20 h ago with Fox + Bunny + Dog: popup "8 h 0 min … capped", base 400, paid 412 (× 1.03 from the
  equipped Cat Lv 3), Coins 469 → 881; LastSeen 2 h ago with a Phoenix Lv 1: base 240, paid 247 (469 → 716); a 62 min absence of
  two test pets: base 31, paid 32; a future `LastSeen` paid 0 with no popup. (4) pens — buying: 4th pen costs exactly 5 000 once
  (881 + 10 000 admin Coins → 5 882 incl. 1 Coin of production), repeat → `stale`, too little Coins → `coins`; placing into an empty
  pen paid nothing for the past, removing paid the production up to then. (5) no remote takes a time; `LastSeen` is only set
  from the server's `os.time()` (grep). (6) rejoin — pens, pad colours, info text, model names, labels and positions were
  identical after leaving and rejoining (Bunny + Phoenix), and a garbage profile (missing pet, duplicate pet, out-of-range pens,
  `PenCount` 99, string `LastSeen`, negative `Carry`) loaded with only valid pens, no errors. (7) ownership — with two clients each
  client had only its own 6 prompts enabled (72 exist), saw the other plot's sign and pet models; a `Remove` from the hub → `far`
  and unchanged; forged uids of another player's pets were ignored. (8) UI — pen panel states (empty pen with 26 free pets,
  locked pen with price, pen behind a locked one, occupied pen with Take-out button), Pets panel "In pen 2", pet models stand on the
  pad (bottom 16.80 = pad top), Epic/Legendary glow present. Consoles clean (UIBlox warnings only). Not covered: the prompt key press
  itself (opened through the `OpenPen` hook), a real second server, a 12-player garden, visual screenshots. Cleanup: the live
  profile equals `p2a-snapshot.json` again (compared field by field) and `user_-1`..`user_-4` are removed. **Save the place (Ctrl+S)**: the pens are Studio-only.
- **Bug fix (2026-10-18, user report):** the pen panel's "Take out" button threw `attempt to index function with 'FireServer'`:
  `remotes.Remove` is the built-in `Instance:Remove()`, not the RemoteEvent. `GardenClient` now looks every garden remote up by
  name once (`WaitForChild`). My own tests had fired the remotes by name and never clicked that button, so the gap was in the
  validation, not in the server. Rule: never index a remote named like an `Instance` member (`Remove`, `Clone`, `Destroy`, `Parent`)
  with a dot; always `:WaitForChild("Name")`. Re-tested by the user with the real button click: works.

### P2b — Pet garden: incubators, feeding
Scoped 2026-10-18 (GDD §7.2, §7.4, §7.6), numbers settled with the user: Golden egg 4 000 Coins, hatch time 1 h; 3 incubators
per plot at 0 / 5 000 / 12 000; foods Berry 50 → 25 XP, Cake 400 → 250 XP, Feast 1 500 → 1 000 XP; the Golden egg is bought
at an empty incubator in the player's own plot, food at a food stand on the plaza; a ready egg is hatched by hand (Hatch
button), not automatically. Split in two so each part is testable on its own; both extend P2a2's `GardenService`.

Shared design notes:
- `GardenService` gains small hooks for sibling modules: `Remote(name)` (a RemoteEvent in `GardenRemotes`), `Allow`,
  `Reject`, `Succeed`, `Usable(player, action)` (loaded, owns a plot, within 45 studs of it), `SettleAndNotify`,
  `PublishState`, `AddStateField(name, fn(profile))` (extra fields of `GardenRemotes.State`) and
  `AddRenderer(fn(index, plot, profile?))` (extra drawing of a plot). The sibling modules are required by `Garden.server.luau`.
- Every time is the server's `os.time()`; no remote takes a time. Clients count down from `ReadyAt` with
  `workspace:GetServerTimeNow()` (synced to the server, not the client's own clock) for display only; the server decides.
- Purchases deduct with `PlayerProfile.AddCoins(-price)` (never `CoinRewards`) and save at once (`PlayerProfile.Save`).
- Remotes are looked up by name on the client (`:WaitForChild("Name")`), never with a dot (P2a2 lesson).

#### P2b1 — Incubators, Golden egg
- **Inputs:** P2a2 (`GardenService`, `GardenPlots`, plots), `PetService`, `PetConfig.Eggs.Golden` (price 4 000, weights).
- **Outputs:**
  - `PetConfig.Eggs.Golden.hatchSeconds = 3600`.
  - `GardenConfig`: `MaxIncubators = 3`, `IncubatorPrices = { 0, 5000, 12000 }`, `IncubatorNamePrefix = "Incubator_"`, pure
    helpers `EggReady(entry, now)` and `IncubatingCount(garden)`.
  - profile field `Garden.IncubatorCount = 1`, `Garden.Incubators = { ["1".."3"] = { Egg = "Golden", StartedAt, ReadyAt } }`
    (both server `os.time()`; additive, `PROFILE_VERSION` stays 3; an old `Garden` table without them is filled on join).
  - `PetService.AddPet(player, kind)` → `uid, equipped` (the shared "new pet" step of `BuyEgg`: next uid, auto-equip into a free
    slot, inventory cap); `PetService.PetCount(profile)`.
  - `ServerScriptService.GardenIncubators` (module) with remotes in `GardenRemotes`: `StartEgg(incubator)`, `Hatch(incubator)`,
    `BuyIncubator(expectedIncubator)` (client → server); answers through `GardenRemotes.Result`. `StartEgg` rejects `locked`,
    `occupied`, `full` (pets + incubating eggs ≥ 50), `coins`; `Hatch` rejects `empty`, `notready` (server `os.time()` < `ReadyAt`),
    `full` (pets ≥ 50; the egg stays); `BuyIncubator` rejects `maxed`, `stale`, `coins`; all reject `far` / `noplot` / `loading`.
    The pet is rolled at `Hatch` (`PetConfig.Roll("Golden")`). `GardenRemotes.State.incubators = { count, eggs = { ["n"] =
    { egg, readyAt } } }`.
  - Drawing per plot: `Incubator_1..3` models get attributes `State` (`free` / `locked` / `empty` / `egg`), `Egg`, `ReadyAt`;
    the egg part is shown only while an egg incubates; the `Info` billboard reads "🔒 Incubator n" / "Incubator n · empty" /
    the egg's countdown (drawn by every client from `ReadyAt`, "Ready!" once due).
  - Client `IncubatorClient.client.luau`: incubator prompts enabled only on the own plot; incubator panel (unlock / start a Golden
    egg with the odds and the hatch time / countdown / Hatch with the pet reveal); countdown texts on every plot; test hook:
    ScreenGui attribute `OpenIncubator`.
- **Studio-only changes:** per plot `Incubator_1..3` (Model: `Base` part with a `Prompt` ProximityPrompt and an `Info`
  BillboardGui, an `Egg` ball part) in the front half of each plot between the sign and the pens (36 models in total).
- **Acceptance checks:**
  1. an egg cannot be hatched before its time: `Hatch` right after `StartEgg` → `notready`, pet count and incubator unchanged;
     with `ReadyAt` moved to 5 s ahead (store edit between sessions) `Hatch` is `notready` before and succeeds after it;
  2. offline hatching: an egg started, the session ended, its `StartedAt` / `ReadyAt` moved one hour into the past in the store →
     after rejoin the incubator shows "Ready!" and `Hatch` adds exactly one Uncommon-or-better pet (never Common), clears the
     incubator, and a second `Hatch` → `empty`;
  3. Coins: `StartEgg` costs exactly 4 000 once (a repeated or double `StartEgg` → `occupied`, no second charge); too few Coins →
     `coins`, nothing changes; `BuyIncubator` charges 5 000 then 12 000 exactly once each, repeat → `stale`, past 3 → `maxed`;
     locked incubator → `locked`;
  4. inventory cap: at 49 pets + 1 incubating egg `StartEgg` → `full`; at 50 pets a ready egg's `Hatch` → `full` and the egg stays;
  5. forged calls change nothing: wrong types, indices 0 / 4 / 1.5, a call from the hub (`far`) and a call naming another
     player's incubator (the plot is derived from the caller) leave both profiles unchanged;
  6. the client clock has no effect: no remote takes a time (grep), `StartedAt` / `ReadyAt` are written only from server
     `os.time()`;
  7. rejoin: incubator states, egg models and `ReadyAt` attributes are identical before and after leaving and rejoining;
     a hand-edited profile (unknown egg id, string `ReadyAt`, entries beyond `IncubatorCount`, `IncubatorCount` 99) loads with
     only the valid eggs, no errors;
  8. consoles clean; live profile restored exactly from the snapshot.
- **Validation log (2026-10-18, uid 9892673032, live profile snapshot `p2b-snapshot.json`, four solo playtests with store edits
  between them):** Edit-mode unit tests of `GardenConfig` / `PetConfig`: `EggReady` false 1 s before and true at `ReadyAt`, false for a
  string or missing entry; `IncubatingCount`; prices 0 / 5 000 / 12 000; Golden 4 000 / 3 600 s, no Common weight, 5 000 rolls gave no
  Common — all pass. (1) `Hatch` right after `StartEgg` → `notready`; with `ReadyAt` set ~60 s ahead in the store: `Hatch` 1.9 s before →
  `notready`, 1.2 s after → hatched a Bunny (Uncommon). (2) egg 1 moved an hour back in the store between sessions → after rejoin the
  label read "Golden egg · ✨ Ready!", the panel "Ready to hatch!"; the real Hatch button click added exactly one pet (uid 27 Bunny,
  Uncommon; pets 26 → 27; a later hatch gave a Dragon, Epic), cleared the incubator (egg hidden, "Incubator 1 · empty"); a second
  `Hatch` → `empty`. (3) `StartEgg` −4 000 exactly once (the real Start click on incubator 2 after the real E key on its prompt also
  −4 000), repeat → `occupied`; `BuyIncubator` 2 = −5 000, 3 = −12 000 (Coins 50 008 → 21 008 after three eggs and two incubators, matching
  the store), a double click within the cooldown charged once, repeat → `stale`, 4 → `maxed`; incubator 2 before buying → `locked`.
  (4) 49 pets + 1 ready egg: `StartEgg` → `full` (×2, Coins unchanged), the hatch made 50, `StartEgg` → `full`; at 50 pets a ready egg's
  `Hatch` → `full` and the egg stayed (`State` egg, still in `State.incubators`). (5) `StartEgg("1")` / `1.5` → ignored, `0` / `4` → `locked`;
  from the hub → `far` for all three remotes (the panel closed itself); standing on plot 2 → `far`, plot 2's incubators unchanged and
  their prompts disabled on this client. (6) no garden remote takes a time (grep of the handlers and `FireServer` calls); `StartedAt` /
  `ReadyAt` are only written from server `os.time()` (one place). (7) rejoin: egg 3's `ReadyAt` 1792343843 was identical in the
  attribute before leaving, in the store and in the attribute after rejoining; a hand-edited profile (`IncubatorCount` 99, unknown egg
  `Bogus`, string `ReadyAt`, keys `4` and `x`) loaded as count 3 with only the valid egg, no errors. UI: panel states locked (price),
  empty (odds in rarity colours, "hatches in 1 hour"), counting ("Hatches in 59:47", button "Hatching..."), ready, the hatch reveal
  ("You got a Bunny (Uncommon)! It is in your Pets panel."); the countdown above the egg comes from `GetServerTimeNow`. (8) consoles: only
  the usual UIBlox warnings and the DataStore queue notice. Cleanup: the live profile equals `p2b-snapshot.json` again (deep compare),
  no `user_-1` / `user_-2`. Not covered: a real one-hour wait (times were moved in the store), several clients at once, visual screenshots
  (viewport captures are blank). Studio-only: 36 `Incubator_n` models — **save the place (Ctrl+S)**.

#### P2b2 — Feeding
- **Inputs:** P2b1, `PetConfig.GainXp`, `GardenService` settle (penned pets).
- **Outputs:**
  - `GardenConfig.Foods = { { id = "Berry", price = 50, xp = 25 }, { id = "Cake", price = 400, xp = 250 },
    { id = "Feast", price = 1500, xp = 1000 } }`, `FoodById`, `FoodStandDistance = 20`; pure helper `XpToMax(pet)`.
  - `ServerScriptService.GardenFood` (module) with remote `GardenRemotes.Feed(uid, foodId)`: caller within 20 studs of
    `Workspace.Garden.FoodStand`'s PrimaryPart (else `far`), any owned pet (equipped, penned or resting), level 20 → `maxed`,
    too few Coins → `coins`; a penned pet's production is settled first; Coins − price, the pet alone gets the XP through
    `PetConfig.GainXp`; publishes the pet state (levels feed the bonus and the `EquippedPets` labels) and redraws the plot
    (pen label and rate) when the pet is penned. Result detail `{ uid, food, xp, level, levels }`.
  - Client `FoodShopClient.client.luau`: prompt on the food stand opens the food panel (three foods with price and XP, a pet
    list with level, XP bar and "needs N XP to Lv 20", feed buttons; maxed pets marked and disabled); test hook: ScreenGui
    attribute `Open`.
- **Studio-only changes:** `Workspace.Garden.FoodStand` (Model on the plaza: counter, sign "🍓 PET FOOD", a `Prompt` on the
  PrimaryPart `Counter`).
- **Acceptance checks:**
  1. feeding deducts Coins exactly once and adds exactly the configured XP: a Berry to a Lv 1 pet with 0 XP → Coins − 50, XP
     25 → Lv 2 with 15 XP (10 needed for Lv 2); a Feast to a Lv 1 pet → the exact level / remainder from `XpToNext`; equipped,
     penned and resting pets all work; other pets' XP unchanged;
  2. a level-20 pet → `maxed`, Coins unchanged; too few Coins → `coins`, nothing changes;
  3. forged / repeated calls: unknown food id, another player's pet uid, wrong types, from the hub (`far`) change nothing;
     two quick calls within the cooldown charge once;
  4. a penned pet fed: production up to the feeding is paid at the old level (settled first), the pen label and the garden rate
     show the new level;
  5. a fed equipped pet updates the Coin multiplier and its `EquippedPets` label;
  6. consoles clean; live profile restored exactly from the snapshot.
- **Validation log (2026-10-18, same snapshot, fourth playtest: 2 000 Coins, 50 pets incl. a Dog Lv 20 and a Phoenix Lv 1 in pen 1):**
  Edit-mode: `XpToMax` Lv 1 = 6 714, Lv 20 = 0; Berry on Lv 1 → Lv 2 / 15 XP, Feast on Lv 1 → Lv 9 / 160 XP, Feast on Lv 19 / 800 → Lv 20 / 0.
  (1) the real E key opened the food panel (50 rows, "XP 10/28 · 6,694 XP to Lv 20 · equipped", maxed Dog "Max level", greyed buttons);
  a real click on the equipped Fox's Berry: Coins 2 000 → 1 950, Fox Lv 2 / 10 → Lv 3 / 7, no other pet changed; Berry on a resting Dog Lv 1 →
  Lv 2 / 15 (−50); Feast on the penned Phoenix → Lv 9 / 160 (−1 500). (2) Feast on the Lv 20 Dog → `maxed`, Coins unchanged; Feast with 352
  Coins → `coins`, nothing changed. (3) unknown food `Candy`, unknown uid, wrong types and no arguments → ignored, nothing changed; two
  Berries within the cooldown → one result, −50 once; from the plot (~100 studs away) → `far`. (4) feeding the penned Phoenix first settled
  66 s at the old rate (base 2 = floor(66 × 120 / 3 600), carry 0.2), the pen label then read "Phoenix Lv 9 · 158.4 Coins/h" and the State
  rate 158.4; the next settle (taking it out 70 s later) paid 3 = floor((0.2 + 70 × 158.4 / 3 600)) — the old rate would have paid 2.
  (5) the Fox's Berry raised the multiplier 1.045 → 1.05 and `EquippedPets` "Fox:2" → "Fox:3". All XP and Coins were in the store after
  the session (Coins 355 = 2 000 − 50 − 50 − 1 500 − 50 + 2 + 3). (6) consoles: UIBlox warnings, the DataStore queue notice and one error
  from my own test script only. Cleanup as in P2b1. Not covered: several clients at once, visual screenshots. Studio-only:
  `Workspace.Garden.FoodStand` — **save the place (Ctrl+S)**.

#### P2b3 — Eggs only in the garden
User request 2026-10-18: the hub egg stand is obsolete; every egg hatches in a garden incubator. Decisions (user): Basic eggs
go through the incubators too; free eggs (launch egg, first Gold) start in an incubator by themselves. Basic hatch time
**5 minutes** (my pick, `PetConfig.Eggs.Basic.hatchSeconds = 300`; easy to tune in M6).
- **Outputs:**
  - `PetConfig`: `stand` removed, every egg has `hatchSeconds`; `EggOrder = { "Basic", "Golden" }` (panel order).
  - `PetService`: `BuyEgg` remote and handler removed; `FreeEggsChanged` signal (fired by `GrantFreeEgg` and the launch egg).
  - `GardenService.AddSetupHook(fn)`: called after the join setup and after an admin reset.
  - `GardenIncubators`: `StartEgg(incubator, eggId)` (any egg with `hatchSeconds`; malformed ids ignored); `startFreeEggs` puts
    waiting `FreeEggs` into the lowest empty incubators while the inventory cap allows — from the setup hook, on
    `FreeEggsChanged`, after a hatch and after an incubator is bought. A free egg is a normal incubator entry (no flag).
  - `IncubatorClient`: an empty incubator lists both eggs (time + odds) with one button each ("Basic egg: 500",
    "Golden egg: 4,000"); "🎁 N free eggs will start in the next empty incubator" while some wait.
  - Pets panel "🎁 N free eggs waiting for an empty incubator"; results popup "🎁 Free Basic egg → your incubator" on a
    first Gold; garden / food texts no longer mention the stand. `EggStand.client.luau` deleted.
- **Follow-up (user request): eggs look different.** The incubator egg ball was always gold. `PetConfig.Eggs[id].look`
  (`color`, `material`, `glow`) is applied by the `GardenIncubators` renderer: Basic = plain cream, no glow; Golden = shiny
  gold with a gold glow. Checked on the server in a playtest (Basic `236,228,208` / light off, Golden `255,200,40` / light
  on, empty incubator hidden and dark); not checked visually (3D captures come out blank). No Studio changes.
- **Studio-only changes:** `Workspace.StartLocation.EggStand` model deleted — **save the place (Ctrl+S)**.
- **Acceptance checks:** no egg can be bought on the hub (no stand, no `BuyEgg` remote); a free egg starts in an empty
  incubator at once and waits while all are busy; a hatch lets a waiting free egg start; paid Basic / Golden eggs cost
  exactly their price; forged `StartEgg` requests change nothing; rejoin identical, no second launch egg.
- **Validation log (2026-10-18, solo playtests, API access on, uid 9892673032, snapshot `p2b3-snapshot.json`):**
  Playtest 1 (preset: 20 000 Coins, `LaunchEgg = false`, `FreeEggs = {Basic = 3}`, 3 incubators with a ready Golden egg
  in 2, Tutorial at Silver): join → incubators 1 and 3 Basic (ready in 300 s), `FreeEggs = {Basic = 2}`;
  `PetRemotes.BuyEgg` absent, hub `EggStand` absent. Tutorial Gold (0.6 s) → `freeEgg = "Basic"`, all busy → 3 waiting;
  Pets panel "🎁 3 free eggs waiting for an empty incubator". Incubator 2 panel: Golden odds, "Ready to hatch!"; a real
  click on Hatch → Epic Dragon (uid 28), and a waiting free egg started in incubator 2 at once (2 waiting). Stored after
  leaving: as seen by the client (20 432 Coins, 3 Basic eggs, `FreeEggs = {Basic = 2}`). Playtest 2 (preset: no free
  eggs, incubator 1 empty, a ready Basic egg in 3): empty panel lists "Basic egg · 5 min" (60 / 25 / 11 / 3.5 / 0.5 %) and
  "Golden egg · 1 hour" (45 / 35 / 15 / 5 %) = `PetConfig` weights; `StartEgg(1)`, `(1, "Nope")`, `(1, 5)`, `(1, {…})`,
  `("1", "Basic")` → no reply, nothing changed; real click "Basic egg: 500" → exactly −500, Basic in 1; Hatch in 3 →
  reveal "You got a Dog (Common)!"; real click "Golden egg: 4,000" → exactly −4 000, Golden in 3 (ready in 3 600 s).
  Admin Reset Score → fresh profile, the re-granted launch egg started in incubator 1 by itself (setup hook).
  Playtest 3 (rejoin): same incubator egg and `ReadyAt`, no pets, no free eggs, no second launch egg. Consoles: UIBlox
  warnings and two "DataStore request was added to queue" notices (several saves on the key within seconds: egg starts,
  hatch, reset). Found + fixed: the popup's free-egg line was too wide (386 of 296 px), shortened after the playtest (measured 247 px). Not covered: inventory
  cap with waiting free eggs, several clients at once, visual screenshots. Live profile, all four boards and MostStars
  (12) restored exactly.

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
