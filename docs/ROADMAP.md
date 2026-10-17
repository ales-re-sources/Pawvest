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
| R1 | Repeat rewards + shared payout | – | – | – |
| P1 | Pets core | – | – | – |
| M3 | Stage unlocks | – | – | – |
| M4 | Challenge coins | – | – | – |
| M5 | Leaderboards | – | – | – |
| P2a | Pet garden: plots, pens, offline income | – | – | – |
| P2b | Pet garden: incubators, feeding | – | – | – |
| P3 | Trading | – | – | – |
| M6 | Balancing pass | – | – | – |
| M7 | Monetization | deferred | | |

Order rationale: M0 unblocks everything. M1 creates Coin income, M2 spends it. R1 opens the economy (repeat rewards)
and adds the single payout point that pets multiply; P1 needs it. M3 needs medals and Coins. M4 adds a Coin source.
M5 is mostly independent (can move earlier). P-milestones may move ahead of M3–M5 if pets take priority, but keep
their own order: P2a/P2b need P1, P3 needs P1 and profile session locking. M6 needs the full loop including the garden.

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
- **Studio-only changes:** none.
- **Acceptance checks:** the same stage finished 3× with Silver in one day pays run rewards exactly `r`, `round(0.8 r)`,
  `round(0.64 r)` (medal payout only on the first); a finish without a medal pays 0; a run reward never drops below 1;
  setting `RunsToday.Day` to yesterday resets the count (next run pays `r`); counts persist after rejoin the same day.

### P1 — Pets core
- **Inputs:** `CoinRewards` (R1), `StageResults`, `CoinSystem`, `PlayerTimerHandler` (running timer), GDD §7.1–7.5.
- **Outputs:**
  - `ReplicatedStorage.PetConfig`: kinds, rarities, eggs + weights, slot prices, sell values, level curve; pure
    `Roll(egg, rng)`, `PetBonus(pet)`, `Multiplier(pets)`, `XpToNext(level)`.
  - Profile `Version = 2` with `Pets = { [uid] = { Kind, Level, XP } }`, `EquippedPets = { uid… }`, `PetSlots = 1`,
    `NextPetUid = 1`, `FreeEggs = { [eggId] = count }` (existing `reconcile` fills old records; the launch free egg is
    granted once via a flag).
  - `ServerScriptService.PetService` + `PetRemotes.server.luau`: remotes created by code in `ReplicatedStorage.PetRemotes`
    (`BuyEgg`, `Equip`, `Unequip`, `BuySlot`, `SellPet`; server → client `PetsChanged`). Server validates every argument,
    takes prices from `PetConfig`, rolls itself, saves after purchases and sales.
  - `CoinRewards.Grant` uses `PetService.Multiplier(player)`.
  - `PetService.AddXP(player, amount)`: full XP to every equipped pet, level-ups. Called by `StageResults` (run medal),
    `CoinSystem` (coin) and a server-side movement counter (only while a stage timer runs, capped per run, teleports ignored).
  - First Gold on a stage grants a free Basic egg.
  - Player attribute `EquippedPets` (`"kind:level,…"`) for rendering.
  - Client: `PetFollow.client.luau` (all players' pets follow, local lerp), `PetsPanel.client.luau` (code-built GUI:
    inventory, equip, slots, sell, bonus, XP bars; "Pets" button in `ButtonHandler`), `EggStand.client.luau`
    (ProximityPrompt → odds + confirm → hatch result).
- **Boundary:** no garden, no trading, no Robux. Pets never touch WalkSpeed / JumpPower.
- **Studio-only changes:** `EggStand` model on the hub (`StartLocation`) with a ProximityPrompt; `ReplicatedStorage.PetModels`
  with one model per kind (PrimaryPart, Anchored, CanCollide off, CanTouch off).
- **Acceptance checks:**
  - buying an egg with too few Coins is rejected server-side: Coins and pet count unchanged;
  - remote calls with a forged price, a foreign or non-existent uid, an unknown egg id or a 4th equip with 3 slots
    change nothing;
  - 10 000 `PetConfig.Roll` calls in `execute_luau` match the Basic egg weights within ±1.5 percentage points;
  - with one +10 % pet equipped a 40-Coin payout pays exactly 44; with no pet exactly 40; the total never exceeds +50 %;
  - a Silver finish gives each equipped pet exactly 10 XP + movement XP ≤ 30; walking with no running timer gives 0 XP;
    a pet crossing `XpToNext` levels up and keeps the remainder;
  - selling a pet removes it and pays exactly its sell value; an equipped pet cannot be sold;
  - after rejoin: identical pets, levels, XP, slots and equipped set; launch free egg is not granted twice;
  - a second client (multi-client) sees the first player's pets following; server and client consoles clean.

### M3 — Stage unlocks
- **Outputs:** portal checks bar *or* paid unlock; locked-portal UI (requirement + price); buy-unlock remote;
  Tutorial portal on the hub.
- **Acceptance checks:** locked portal does not teleport; meeting the bar unlocks without charging;
  buying deducts the price exactly once; unlock persists after rejoin.

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
- **Done early (fix, 2026-10-17, user report):** a new record showed on the board only after a server restart (the board
  polled every 60 s). `PlayerTimerHandler.LeaderboardChanged` now fires after a Top-10 write and boards redraw at once
  (Stage 2 board updated 0.7 s after the finish); empty rows are cleared; the 60 s poll stays for other servers.
- **Acceptance checks:** every board renders 10 rows from the DataStore (or fewer with real data, never blank errors);
  a new personal best appears within one refresh interval.

### P2a — Pet garden: plots, pens, offline income
Scoped in detail after P1 (GDD §7.6).
- **Outputs (draft):** garden area + portal from the hub; one plot per server slot, assigned on join, built from a
  Studio template by code; pens (unlock for Coins) hold pets that are not equipped; production paid through
  `CoinRewards.Grant`; offline production on join capped at 8 h with a "while you were away" popup;
  profile `Garden = { Pens, LastSeen }`.
- **Acceptance checks (draft):** a pet cannot be equipped and penned at once; production after N minutes matches the
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
