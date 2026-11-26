# Testing in Studio

Procedures for playtests, the Studio MCP and live DataStores. The test tiers (what to validate for which change) are in AGENTS.md →
Testing. **Read this before any playtest, bot run or DataStore write.**

## Studio MCP habits
- A **minimized Studio window renders no 3D**: check `IsIconic` on the `RobloxStudioBeta` window and restore it with `ShowWindow(handle, 4)`
  from PowerShell before capturing.
- `screen_capture` **one call at a time**, ~1.5 s apart (parallel captures time out, then captures come back white until Studio restarts and
  the instance id changes). A capture with a camera position leaves the Edit camera `Scriptable`: set
  `workspace.CurrentCamera.CameraType = Enum.CameraType.Fixed` afterwards. `BillboardGui`s with `AlwaysOnTop` don't show in captures (check
  them by properties).
- Never leave a playtest running (`start_stop_play` false at the end; `Edit` calls fail in Play mode). Check `get_studio_state` for a
  playtest you did not start before stopping anything (ask the user). A character may not be loaded right after start (wait for
  `HumanoidRootPart`).
- Never `require` a client module that starts itself (GardenView, PetClient …), even indirectly through GardenSummary, from the MCP `Client`
  context: it runs a second copy (a second Workspace.GardenView with every plot drawn twice). Read their drawn instances or GUIs instead.
- `require` in the **Edit** context caches a ModuleScript across calls (may return the old version after a disk change): check `.Source`, or
  test in a playtest.
- Don't `require` PlayerProfile from the MCP command context during a playtest (a second copy that also saves).
- Console: not `get_console_output` (it returns the whole log). Use `execute_luau` (`Server` / `Client` during a playtest, `Edit` otherwise):
  `game:GetService("LogService"):GetLogHistory()`, keep entries matching a pattern (`"%[Telemetry%]"`, `"error"`, your own prefix) or after
  the test's start, last ~30, each cut to ~200 chars.

## Bots and input
- A `MoveTo` bot cannot walk on a kit mover (use `Humanoid:Move`); a jump-reach bot holds forward with `Humanoid:Move` every frame through
  the landing; teleporting into a coin or trigger is flaky (walk onto it).
- A ProximityPrompt shows (and its key works) only on screen: after teleporting the character, set the camera behind it before pressing the
  prompt's key.
- A stage finish can be driven by moving the character through the gate's `TimerStart` and then the finish portal.
- Scroll a list row into view before clicking it (an off-screen row's click lands on what lies under it).
- `user_mouse_input` x / y are GUI-inset coordinates (viewport y − `GuiService:GetGuiInset().Y`); its `instance_path` cannot aim at a
  BillboardGui button (reads it at 0, 0 and clicks the top-left HUD: the Home button teleports).

## Fresh-profile tests
Set the ServerStorage attribute `TestProfileKey` (a string) before the playtest: joining players load / save under that key (a new player
when missing; boards skip them). Clear the attribute and remove the key's record afterwards.

## Live DataStore snapshot / restore
Studio playtests with API access read / write the **live** DataStores.
- Right before **every** fixture write, copy the profile as it is now (`PlayerProfiles` `user_<id>`, plus its `MostStars` value) into
  `TestSnapshots` under a new key (`profile_<id>_<milestone>_<n>`); never restore an older snapshot (the user plays between tests). Restore
  after the playtest has stopped and remove the test's entries from `GlobalLeaderboardsStore`.
- If Edit-mode DataStore calls fail ("Access forbidden"), write from the playtest `Server` context after PlayerProfile's shutdown save:
  `game:BindToClose(function() task.wait(9); store:SetAsync(key, value) end)` (value built beforehand), stop the playtest, wait ~15 s before
  the next one, and check the write there before the profile is saved again. Don't kick the player (it ends the playtest and its dialog
  blocks the MCP).
- `GetAsync` returns two values: assign to a local before passing to `SetAsync` (else "Unable to cast Instance to Array").
- Accounts: `Lekzdrh` (9892673032, the developer in Studio), `AhojRupert` (769364524, another admin).

## Multi-client
The user starts Test → **Server and Clients** (F7), then **Add Clients**. `list_roblox_studios` shows one instance per client plus the server;
`get_studio_state` tells them apart. Test users have UserIds −1, −2… and create `PlayerProfiles` records `user_-1`, `user_-2`: remove them
afterwards from a later one-player playtest's `Server` context (a removal in the F7 server's `BindToClose` was overwritten by the test
players' leave saves). Studio does not filter text (`TextService`): filter results need a live test.
