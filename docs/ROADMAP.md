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
| M0 | Foundations | ✔ | 3/4 — multi-client check pending | – |
| M1 | Medals & rewards | – | – | – |
| M2 | Talents shop | – | – | – |
| M3 | Stage unlocks | – | – | – |
| M4 | Challenge coins | – | – | – |
| M5 | Leaderboards | – | – | – |
| M6 | Balancing pass | – | – | – |
| M7 | Monetization | deferred | | |

Order rationale: M0 unblocks everything. M1 creates Coin income, M2 spends it. M3 needs medals and Coins.
M4 adds a Coin source. M5 is mostly independent (can move earlier). M6 needs the full loop.

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
  Test writes to live DataStores were restored afterwards. Multi-client check not run yet (needs Test → Clients and Servers).

### M1 — Medals & rewards
- **Outputs:** tier evaluation at the finish portal; one-time payouts per GDD §5; results popup; medal shown on hub portal.
- **Acceptance checks:** first Silver finish pays Bronze + Silver exactly once; repeating Silver pays 0;
  later Gold pays only Gold; medal persists after rejoin.

### M2 — Talents shop
- **Outputs:** skills panel lists talents, levels, costs; purchase RemoteEvent; server applies WalkSpeed / jump height /
  double-jump flag on every spawn. Admin toggles stay as debug-only.
- **Acceptance checks:** purchase with insufficient Coins is rejected server-side (Coins unchanged);
  bought level applies after respawn and after rejoin; firing the remote with a forged cost/level has no effect.

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
- **Acceptance checks:** every board renders 10 rows from the DataStore (or fewer with real data, never blank errors);
  a new personal best appears within one refresh interval.

### M6 — Balancing pass
- **Outputs:** measured `T_base` per stage; finish-time telemetry; tuned numbers in GDD + stage config.
- **Acceptance checks:** every stage has a measured `T_base`; GDD §6 economy constraint table still all ✔.

### M7 — Monetization
Deferred; scoped after M6 (GDD §8).
