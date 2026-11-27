# Remotes, DataStores and player attributes

Reference tables for the client-server protocol and the stored profile. AGENTS.md keeps the rules. Update this file in the same commit as
any change to a remote, a profile field or a mirrored attribute. Grep it for the remote, key or attribute you touch; don't read it whole.

## RemoteEvents
In `ReplicatedStorage`; `StageTimerUpdate`, `StageTimerStopped` and `ResetPlayerTimer` exist only in Studio (not in files), every other
one is created at runtime by its service (`Remotes.Add` / `Remotes.Folder`). Garden remotes share one 0.2 s per-player rate limit.

| Remote | Direction | Purpose |
|---|---|---|
| `StageTimerUpdate` | server → client | `(elapsed ≥ 0, stageKey)` run active; `(-1, final, result)` finished; `(-1)` cancelled |
| `StageTimerStopped` | — | unused (was the stop ack); can be deleted in Studio |
| `ResetPlayerTimer` | client → server | admin panel "Reset Score": full reset of the caller's own progress; server checks `AdminConfig` |
| `AdminAddCoins` | client → server, no arguments | admin panel "+Coins" (`AdminCoinsServer`): server checks `AdminConfig`, credits `AdminConfig.AddCoinsAmount` |
| `CoinUpdateEvent` | server → client | `CoinSystem`: the Coin display |
| `CheckpointReached` | server → client `(part, first)` | `CheckpointTouchHandler`: the respawn point moved to that checkpoint (the stage's `TimerStart` counts as the first) → `CheckpointClient` lights that pad for that player only; `first` (first reach in the run) also plays the sound |
| `CheckpointsReset` | server → client, no arguments | `CheckpointTouchHandler`: a new run started → every pad turns back |
| `ExploreWarning` | server → client `(stageKey)` | `CheckpointTouchHandler`: the player reached a checkpoint without a run (entered past the gate) → `StageExploreWarning` says this run is not timed |
| `StageArrival` | server → client `(stageKey)` | `PlayerTimerHandler`: the player entered a gate without a talent the stage needs → `StageArrivalWarning` popup (entry is never blocked); also feeds the `ArrivalWithoutTalent` telemetry event |
| `GoHome` | client → server, no arguments | Gateway button (second, top left); `HomeService`, 0.5 s cooldown; returns to the stage's plaza or onward to Central Island + cancels the timer |
| `GoGarden` | client → server, no arguments | the Home icon (first, top left; not fired without a `GardenPlot` attribute); `HomeService`, own 0.5 s cooldown; teleports in front of the caller's plot (`GardenPlots.PlotOf`) facing it + cancels the timer |
| `LanguageRemotes.Set` | client → server `(code)`: `""` = automatic, else a `Locale.Supported` code | `LanguageService`; stored in the profile, mirrored to the attributes `LanguageSetting` / `Language` |
| `LanguageRemotes.SystemLocale` | client → server `(localeId)`, once per join | the device's `SystemLocaleId` (the server cannot read it); validated, kept in attribute `SystemLocale`; used by `Locale.Resolve` |
| `TelemetryRemotes.Report` | client → server `("platform", kind)` / `("kill", part)` / `("fall")` | `Telemetry`; telemetry only, never trusted for gameplay; kill / fall rate-limited to 1 per s, the part must lie in a stage folder |
| `TalentRemotes.Buy` / `.Result` / `.Granted` | client → server `(talentId, expectedLevel)` / server → client `(talentId, ok, level or reason)` / server → client `(talentId, level)` | `TalentService`; price and crop bundle are never sent (a level takes `TalentConfig.crops[n]` from `Garden.Items` with the Coins; too few → `crops`); a world-reward level (`rewards`: Double Jump level 1 with World 2) is refused (`reward`) and granted when the world opens, announced on `Granted` |
| `UnlockRemotes.Buy` / `.Result` / `.Locked` | client → server `(stageKey)` / server → client `(stageKey, ok, reason?)` / server → client `(stageKey)` | `StageUnlocks`; price from `StageConfig.unlockPrice`; `Locked` is created but unused (gate prompts replaced the popup) |
| `PetRemotes.Equip` / `.Unequip` / `.BuySlot` / `.SellPet` / `.RequestState` | client → server `(uid)` / `(uid)` / `(expectedSlot)` / `(uid)` / none | `PetService`; `RequestState` re-sends `PetsChanged` (a client still loading misses the join publish); uids are strings; prices and sell values server-side. Eggs hatch only in the garden |
| `PetRemotes.PetsChanged` / `.Result` | server → client `({ pets, equipped, slots, freeEggs, seenKinds, multiplier, field = { [uid] = square } })` / `(action, ok, detail or reason)` | state after load and every change; per-request answer (sale value, reject reason); a pet's `Name` in `pets` is the filtered name only |
| `PetRemotes.Rename` | client → server `(uid, text)` | `PetConfig.CleanName` (1-20 letters / digits / spaces, `""` removes), 10 s cooldown, first name free then `PetConfig.RenamePrice`; filtered with `TextService` (owner, `PublicChat`) before storing; `Result` `("Rename", ok, { uid, name?, price } or reason)` |
| `GardenRemotes.RequestState` | client → server, no arguments | `GardenService`; re-sends `State`. Plot actions are derived from the caller (`GardenService.Usable`: within `MAX_DISTANCE` = 25 studs of the own plot and its field, `GardenConfig.FootprintDistance`); no remote carries a time |
| `GardenRemotes.StartEgg` / `.Hatch` / `.BuyIncubator` / `.Feed` | client → server `(incubator, eggId)` / `(incubator)` / `(expectedIncubator)` / `(uid, foodId)` | `GardenIncubators` / `GardenFood`; prices from `PetConfig.Eggs` / `GardenConfig.IncubatorPrices` / `GardenConfig.FoodPrice` (by trait level and rarity); StartEgg rejects `eggLocked` while the egg's `opensWith` crop is not in `Garden.Unlocked`; hatch time checked against server `os.time()`. `Result`: Hatch `{ incubator, egg, uid, kind, rarity, equipped, traits }`; Feed `{ uid, food, price, xp, level, trained = { { id, levels, level } } }`, rejects `maxed` / `coins` |
| `GardenRemotes.CancelEgg` | client → server `(incubator, id)` | `GardenIncubators`: discards the egg without refund; checks own-plot proximity and the exact stored `Id` (GUID), so a stale request cannot discard a replacement; waiting free eggs start; UI: trash button + `ConfirmTap` |
| `GardenRemotes.State` / `.Result` | server → client `(state)` / `(action, ok, detail or reason)` | `State` = `{ incubators = { count, eggs = { ["n"] = { id, egg, startedAt, readyAt } } }, field? }`, `field` below. `Result` is every action's answer (per-remote notes) |
| `GardenRemotes.Plant` / `.Harvest` / `.BuySeeds` / `.Sell` / `.BuySquare` | client → server `(square, cropId)` / `(square)` / `(cropId, count)` / `(cropId, count)` / `(square, expectedOpen)` | `GardenField`; prices and times from `CropConfig`; growth settled from server `os.time()` first. Plant / Harvest / BuySquare need the own plot, Sell works anywhere, BuySeeds within `GardenConfig.SeedStallDistance` (20 studs) of `Workspace.Garden.SeedStall` (else `far`). Plant has no unlock check (held seeds can be planted). Harvest answer `{ square, crop, count?, mastery? = { crop, n, level }, levelUp?, unlocked?, size, best?, extra? }` (size: `CropConfig.SizeFactor`; `extra` = the Shears' second crop; a fruit tree picks all its fruit, `count` of them, each with its own size roll; `size` / `best` = the biggest; a bare tree → `notripe`). Sell pays `CropConfig.SaleValue` of the sold share of the summed size. BuySeeds rejects `obby` (rare crop or rare tree), `locked`, `stock` (rotating crop not in this block), `soldOut` (past `CropConfig.Stall.Count`), `maxed` (a tree's saplings held + planted past `tree.Max`; sapling prices `CropConfig.SaplingPrice` by the number owned). BuySquare: price `CropConfig.NextExpansion`, answer `{ square, open, price }`, rejects `square` / `open` / `stale` / `coins` / `maxed` |
| `GardenRemotes.Uproot` | client → server `(square)` | `GardenField`: digs up the caller's growing crop on `square` (own plot); the seed is lost, no harvest / mastery; rejects `empty` / `ripe` (a fruit tree goes in any state, its fruit lost); Result `("Uproot", true, { square, crop })`. The square card's red trash brick fires it after a `ConfirmTap` |
| `GardenRemotes.PlacePet` / `.LiftPet` / `.BuyPetSlot` | client → server `(square, uid)` / `(uid)` / `(expectedSlots)` | `GardenField`; PlacePet also moves a placed pet; the pet needs Tending or Pest control (both = both jobs); one pet per square, at most `Garden.FieldPetSlots`; prices `CropConfig.PetSlotPrices`; PlacePet / LiftPet need the own plot, BuyPetSlot works anywhere |
| `GardenRemotes.BuyUpgrade` | client → server `(id, expectedLevel)` | `GardenField`; `CropConfig.Upgrades` (Growth, Barn); `expectedLevel` ≠ current → `stale`, top → `maxed`; anywhere; `("BuyUpgrade", ok, { id, level, price } or reason)` |
| `GardenRemotes.BuyTool` | client → server `(id, expectedLevel)` | `GardenField`; `CropConfig.Tools` (Sorter, Cloches, Shears; `Garden.Tools`); rejects `maxed` / `stale` / `coins`; anywhere; `("BuyTool", ok, { id, level, price } or reason)`. Sorter multiplies every harvest's size factor, Cloches the growth while the owner is online, Shears give a second crop with their chance (rolled per planting number) |
| `GardenRemotes.BuyCart` | client → server `(slot, cropId, count)` | `GardenField`, the daily market cart: offers from `CropConfig.CartOffers(UTC day, Garden.Unlocked)` (bargains on unlocked crops, a taste of the next locked crop from the Garlic unlock); counts in `Garden.Cart`, reset daily; within `SeedStallDistance` of the stall (else `far`); rejects `stale` / `soldout` / `barn` / `coins`; `("BuyCart", ok, { crop, count, price, taste? } or reason)` |
| `GardenRemotes.CropPoint` | client → server `(cropId, line)` | `GardenField`; anywhere; `line` = `Value` / `Size` / `Speed` (`CropConfig.PointLines`); adds 1 to `Garden.Crops[cropId].Pts[line]`; rejects `crop` (rare) / `maxed` (`Points.PerLine` = 3) / `points` (level − spent < 1); `("CropPoint", ok, { crop, line, points } or reason)` |
| `GardenRemotes.Quest` | client → server `(cropId, count)` | `GardenField`, the milestone quest of Corn / Pumpkin / Sweet potato (`CropConfig` `quest`); anywhere; moves `min(count, still needed)` of `cropId` from `Garden.Items` into `Garden.Quest.Got`; rejects `none` / `crop` (not wanted or already given) / `crops` (fewer held); the last piece adds the crop to `Garden.Unlocked` and `CropConfig.Mastery.QuestSeeds` seeds (past the barn limit); `("Quest", ok, { target, crop, count, got, unlocked?, seeds? } or reason)` |
| `GardenRemotes.FeedCrop` | client → server `(uid, cropId, count)` | `GardenField`, crops as pet food; no plot distance; any owned pet; XP per crop `GardenConfig.CropFeedXp`, care XP up to the food limit (`PetConfig.GainCareXp`), count clamped to what the pet can still use (`GardenConfig.XpToMax`), average size leaves `ItemSize`; rejects `items` / `maxed` / `small` (a crop is worth < 1 XP to this pet), a bad uid / crop / count gets no answer; `("FeedCrop", ok, { uid, crop, used, xp, level, trained = { { id, levels, level } } } or reason)` |
| `GardenRemotes.Result` `("Request", true, { crop, need, coins, drop? = { seed = rare crop id } or { egg = egg id } })` | server → client | `GardenRequests`: a tracked request finished (from the harvest that finished it, before its own answer; also from a Tending pet's harvest in the join settle); never refused |
| `GardenRemotes.Like` / `.Liked` | client → server `(slot)` / server → client `(likerName)` | `GardenLikes`; the owner is whoever borrows `slot`; refuses `loading`, `free`, `self`, `far` (> 60 studs), `liked` (once per owner per UTC day per liker); success `("Like", true, { name })`; 2 s rate; the owner gets `Liked` and the plot state's `likes` goes up |
| `GardenRemotes.Plot` / `.RequestPlots` | server → client `(userId, { slot, name, incCount, eggs = { "EggId:readyAt:startedAt" or "" × 3 }, field? = { crops, plants?, pets = { "Kind:Level:uid:square:tending:guard" } }, likes, ribbons })` or `(userId, nil)` on leave / client → server, none | `GardenPlotFeed`; sent to everyone after every publish whose plot changed; `RequestPlots` (1 s cooldown) re-sends all; clients draw the plots from it (`GardenView`). `field.crops` = `CropConfig.MaxSquares` two-character squares (`#0` locked, `.0` empty, crop letter + stage 1-3, a fruit tree 1-2 young, 2 bare, 3 with fruit (`CropConfig.Stage`); shape `CropConfig.RowWidths`); pet levels are Tending / Pest-control levels, 0 without |
| `FeedbackRemotes.Rate` | client → server `(stageKey, rating)` | `FeedbackService`; `rating` 1 / -1 from a rating sign (`RatingSigns`) or the results popup; world stages only; the character within `FeedbackConfig.RateDistance` (20 studs) of the stage's sign (tag `RatingSign`), or the stage finished within `PopupSeconds` (120 s, `StageResults.FinishedWithin`); 1 s rate; same value again changes nothing; refuses `loading`, `stage`, `value`, `far`, `wait`; success `("rate", true, rating)` on `FeedbackRemotes.Result` |
| `FeedbackRemotes.Send` | client → server `(category, text)` | `FeedbackService`; `category` ∈ `FeedbackConfig.Categories` (bug / idea / other); trimmed UTF-8 text 1–`MaxLength` (300); `PerDay` (3) per UTC day; 5 s rate; filtered (`PublicChat`) before storing; refuses `loading`, `category`, `empty`, `long`, `daily`, `wait`, `filter`, `failed`; success `("send", true, messages left today)` on `FeedbackRemotes.Result` |
| `HarvestHall.Toast` | server → client `(name, cropId, factor)` | `HarvestHall` (folder `ReplicatedStorage.HarvestHall`); to every client when a harvest takes a week's #1 and is Big or Giant (`CropConfig.SizeLabel`), at most one per `HallConfig.ToastGap` |
| `OnboardRemotes.Seen` | client → server `(stepId)` | `OnboardService`; only the client-only steps (`quests`: the Goals panel opened) are accepted, anything else is ignored; no answer (the player attribute `Onboard` changes) |

**`GardenRemotes.State.field`** (private, owner only; the rested mastery pool is never sent):
- `open` (sorted open squares), `squares = { ["n"] = { crop, grown, readyAt, size, fruit?, young?, nextAt? } }` (a fruit tree: `fruit` hanging, `young` before its first growth; `readyAt` = the next fruit, 0 while it has fruit; `nextAt` = server time of the next fruit if the owner stays online, for a grown tree below its cap), `seeds`, `items`, `slots`, `slotPrice`, `upgrades = { Growth?, Barn? }`, `barn` (capacity), `tools = { Sorter?, Cloches?, Shears? }`.
- `pets = { ["square"] = { uid, kind, level, job, apt, xp, next, reach } }`, and the Pest-control pets' `guard = { level, xp, next, reach, chance, spec }`.
- `mastery = { crops = { [cropId] = plants grown }, points = { [cropId] = { [line] = 1-3 } }, unlocked = { [cropId] = true }, quest? = { crop, got = { [cropId] = n } } }`.
- `cart = { nextAt, offers = { { slot, crop, count, left, price, base, discount?, taste? } } }`.
- `stall = { block, endsAt, left = { [cropId] = seeds left } }`: the restock block `CropConfig.StallBlock(os.time())` and its end; `left` lists the player's rotating crops (0 = not in this block or sold out; a crop not listed is always in stock).
- `requests = { open, endsAt (next UTC midnight), slots = { { crop, need, have, done, bonus (Coins it pays now, pet bonus included) } } }`.
- `sizes = { [cropId] = summed size }`, `best = { [cropId] = factor }`, `earned = { [cropId] = Coins }`, `ribbons = { [cropId] = weeks won }` (the crop page's stats).
- `crows = { from, to, active }`: the next crow block within a day (server times); `active` = `CropConfig.Crows.FromCrop` unlocked.
- `notice = { converted? = { pens, slots, refund, returned }, tended? = { [cropId] = n }, crows? = { ate = { [cropId] = n }, chased = { [uid] = n } }, away?, ripe?, eggs?, requests?, biggest? = { crop, factor }, ribbons? = { [cropId] = n }, ribbonsReady? }`: the absence ledger, only after an absence of 30 min or more (`away` seconds, ripe squares, ready incubator eggs, request slots filled since the last settle, the pets' biggest harvest, the join's Harvest Hall ribbons; `ribbonsReady` false while that check runs), plus this session's conversion of an old profile and the pets' harvests while away.

## DataStores

| Store | Key | Value |
|---|---|---|
| `PlayerProfiles` | `user_<UserId>` | the profile, table below. In Studio the ServerStorage attribute `TestProfileKey` (a string) loads and saves the profiles of players joining while it is set under that key instead (a missing record starts as a new player, no legacy import; `PlayerProfile.IsTest`; the star board and the stage Top-10s leave such a player out) |
| `PlayerCoins` | `UserId` | legacy integer coins, read once for migration |
| `PlayerScoresStore` | `player_<UserId>` | legacy `{ {StageName, Elapsed}, … }`, read once for migration |
| `GlobalLeaderboardsStore` | `leaderboard_<StageName>` | Top-10 `{ {PlayerName, Elapsed, UserId?}, … }` (UserId missing on entries from before the avatar boards) |
| ordered `MostStars` | `<UserId>` | total stars (sum of the profile's medals, `StageConfig.TotalStars`); no entry = 0; hub board (`StarBoard`) |
| ordered `"a"` | — | legacy time-played board (script removed; old data only; not in code) |
| `HarvestHall` | `week_<n>` (n = `HallConfig.Week`: weeks since Monday 1970-01-05 UTC), `alltime` | `{ crops = { [cropId] = { { u = UserId, n = name, f = size factor, t = os.time() of the harvest }, … } } }`: per crop at most 3, one per player, bigger first, earlier on a tie (`HallConfig.Merge`); written only with `UpdateAsync` (merge), at most once per key per 60–90 s per server; read every 120 s. Studio tests use `test_week_<n>` / `test_alltime` (ServerStorage attributes `HallTest`, `HallWeekShift` moves the week, `HallWrites` counts writes); remove them after a test |
| `StageRatings` | `counts` | `{ [stageKey] = { up, down, upUnfinished, downUnfinished } }`: thumbs by players who had finished the stage when they voted (`up` / `down`) and by the others (`…Unfinished`); a vote stays in the pair it was counted in until it changes; written only with `UpdateAsync` adding each server's queued deltas (a change moves one vote), at most once per 60–75 s per server and in `BindToClose`. Studio writes `studio_counts`; remove it after a test |
| `PlayerFeedback` | `<os.time()>_<UserId>` | one feedback message `{ u = UserId, t = os.time(), cat = bug / idea / other, area = Telemetry.AreaOf (stage key of a run going on, "garden", "hub" or the score panel's world / stage), text (filtered), lang (the player's game language), ver = PlaceVersion }`; never shown in the game, read by us (MCP `ListKeysAsync` / Open Cloud; a new key can take a while to show in a listing). Studio writes `studio_…` keys; remove them after a test |

### Profile (`PlayerProfiles`)
`Version = 7`. Missing fields take their defaults on load (`newProfile()`); fields marked "no `Version` step" were added that way.

| Field | Content |
|---|---|
| `Version` | 7. Migrations run once on load (below) |
| `Coins` | stored Coins (×10 scale since `Version` 3) |
| `BestTimes[stageKey]` | seconds, floored to tenths |
| `Medals[stageKey]` | highest medal 0-3 |
| `UnlockedStages[stageKey]` | `true` when the unlock was bought |
| `CollectedCoins[coinId]` | `true` per collected challenge coin |
| `Talents[talentId]` | level |
| `RunsToday` | `{ Day = UTC day, [stageKey] = medal finishes }`, drives the diminishing repeat reward (`StageConfig.RunReward`) |
| `Pets[uid]` | `{ Kind, Apt = { [aptitudeId] = { L, XP } }, Spec, Name (raw), Renamed }`; Cuteness XP in points, work traits in weighted field seconds, XP may be fractional (obby XP × 0.04 and time with you). `Level` / `XP` exist only on pets from before the traits rework: frozen, read only by the `Version` 4 migration |
| `EquippedPets`, `PetSlots`, `NextPetUid` | equipped uids in equip order (at most `PetSlots`), equip slots owned, next uid (never reused) |
| `FreeEggs[eggId]`, `LaunchEgg` | free eggs waiting to be opened; the launch free egg was granted |
| `SeenKinds[kind]` | `true` for every kind ever owned (egg odds portraits); `PetService` rebuilds it on join from itself + `Pets` (no `Version` step) |
| `Garden` | table below |
| `LastQuit` | `{ Stage, Segment, At }` telemetry, cleared on join |
| `Language` | `""` = automatic, `"en"`, `"cs"` |
| `StageRatings[stageKey]` | `{ R = 1 / -1, F = the stage was finished when rated }` (missing = not rated; other shapes are dropped on join) |
| `FeedbackToday` | `{ Day = UTC day, Count }` |
| `Onboard` | bit mask of `OnboardConfig.Funnel` steps done (bit k − 1 = step k); set on the first join after it existed: all bits when `Garden.Crops` or `Garden.BestSize` has an entry, else 0 (no `Version` step) |
| `OnboardLog`, `OnboardDay` | `GardenStart` funnel steps logged, in order; UTC day of that first join (a later day sets `return`) |

`Garden`:

| Field | Content |
|---|---|
| `Incubators["1".."3"]`, `IncubatorCount` | `{ Id (GUID), Egg, Kind, StartedAt, ReadyAt }` (server `os.time()`), incubators owned. `Kind` is rolled once at paid purchase / free placement; legacy entries get Kind / Id once on join, deadlines unchanged |
| `Field` | `{ Open = { ["n"] = true }, Squares["n"] = { Crop, Grown, N (planting number), Tried, Crow (this planting met crows once) }; a fruit tree's square (TR) = `{ Crop, Grown (≤ tree.First), N, Fruit (≤ tree.Cap), Next (seconds into the next fruit), Picks, Tried / Crow (= Picks when that pick's Tending / crow roll was made) }`, Upgrades = { Growth, Barn }, SettledAt, Plantings }`; fields from before `Open` held `Count` and are moved onto the grid on load |
| `Seeds[cropId]`, `Items[cropId]` | seeds / harvested crops held (barn limit) |
| `ItemSize[cropId]`, `BestSize[cropId]` | summed size factors of the stored crops (missing = 1 each); best size ever |
| `Earned[cropId]` | Coins the crop paid in sales and request bonuses (crop page; missing = 0, no `Version` step) |
| `Crops[cropId]` | `{ N, Pts? }`: plants grown (mastery ★ at `CropConfig.LevelsOf(crop)`, by grow time, never below the points spent); `Pts = { Value?, Size?, Speed? = 1-3 }` points per upgrade line (`Points.PerLine`), their sum at most the level; missing = none, load keeps whole numbers 0-3 (`CropConfig.PointsIn`), no `Version` step |
| `Unlocked[cropId]` | `true`: common crops whose seeds the stall sells |
| `Quest` | `{ Crop, Got[cropId] = n }`, the open milestone quest (absent when the next crop opens by count) |
| `Rested` | silent rested mastery pool in units of the harvested crop's `step`: `+RestPerDay` per day away past the first, cap `RestCap`; while > 0 a plant counts double |
| `FieldPets[uid]`, `FieldPetSlots` | `{ Square, Job = "Tending" or "PestControl" }` (PestControl = a pet without Tending); slots owned |
| `Converted` | the one-time conversion of a pre-field profile ran (below) |
| `Tools` | `{ Sorter, Cloches, Shears }` levels |
| `Cart` | `{ Day = UTC day, Bought = { [cropId, + "*" for the taste] = n } }` |
| `Stall` | `{ Block = restock block, Bought = { [cropId] = n } }`: rotating-crop seeds bought in that block, reset when it changes (no `Version` step) |
| `Requests` | `{ Day = UTC day last filled, Slots = { { Crop, Need, Have, At = os.time() filled, Done? } } }`, at most 3; load drops slots with a locked or unknown crop and clamps `Have` |
| `Income` | `{ Day = UTC day, Today, Prev }`: Coins from crop sales and request bonuses, sizes new requests (no `Version` step) |
| `Meters[stageKey]`, `RareDay`, `LastCrop` | rare-seed meter points per stage; UTC day of the last daily rare seed; the common crop planted last (seed pouch) |
| `MeterSeeds["world"]` | rare seeds the world's stage meters gave; every `tree.MeterEvery`-th is that world's rare tree sapling (`CropConfig.RareTreeOf`) while fewer than `tree.Max` are owned |
| `WeekBest`, `RibbonPending`, `Ribbons`, `Likes`, `Liked` | Harvest Hall / likes, below (no `Version` step) |
| `Renown` | unused; read once by the `Version` 7 migration |
| `Pens`, `PenCount`, `LastSeen`, `Carry` | pre-field pen data, cleared on join |

**Migrations** (on load; each runs once, then the record is stamped):
- `< 3`: `Coins × 10` (also legacy `PlayerCoins`). Never multiply stored Coins by hand.
- `< 4`: every pet from before the traits rework gets Cuteness once at `1 + ceil((Level − 1) × 9 / 19)` (clamped to its cap) (`PetConfig.MigrateLegacyPet`).
- `< 5`: `Garden.Renown` raised to the points of the level it had under the old curve (`CropConfig.Legacy`).
- `< 6`: every trait of every pet moves from the 10-level scale to 1..20 (`PetConfig.RescaleAptitudes`; same XP).
- `< 7`: crop mastery replaces Renown: `Garden.Unlocked` filled from the old Renown gates ≤ the stored Renown level plus every crop in `Seeds` / `Items` / `BestSize`; plant counts start at 0.
- A profile from before the field (pens, no `Garden.Converted`) converts once on join: its pens become field pet slots (`CropConfig.PetSlotsFromPens`), penned pets rest, no refund; the Tending roll is deterministic per planting (`Squares[n].N`), a failed one marks it `Tried`.

Stored ids are never renamed: stage keys, challenge coin ids, aptitude ids, upgrade / tool ids, crop ids, field square numbers.

## Coins, mirrored attributes, runtime state
Gameplay Coins (medals, repeat rewards, pickups) go through `CoinRewards.Grant`; purchases, deductions and pet sales call
`PlayerProfile.AddCoins` directly. The Coin multiplier is `PetService.Multiplier` (1 + equipped pets' Cuteness bonus, capped at +50 %;
a pet without Cuteness adds 0).

Player attributes (server-set unless noted):

| Attribute | Content |
|---|---|
| `Medal_<stage folder>` (0–3), `Unlocked_<stage folder>` (bool) | mirror `PlayerProfile.Medals` and `StageUnlocks` (bar met or `UnlockedStages[key]` bought; the bar is derived from medals, never stored) |
| `Talent_<talentId>` | the talent's level (`TalentService`, also on profile reset) |
| `StageRatings` | JSON `{ [stageKey] = 1 \| -1 }` mirror of the profile's ratings (`FeedbackService` on join / reset / change): `RatingSigns` lights the chosen thumb |
| `Onboard` | the profile's `Onboard` mask (`OnboardService`): the `Onboarding` client module derives the current path step (`OnboardConfig.Current`) from it |
| `HudStage` | the stage key while the player is on a stage (`PlayerTimerHandler.UpdateScorePanel` on arrival, cleared on the hub, a world island or the garden): the score panel shows only then, the tracker line (`GoalsClient`) otherwise |
| `EquippedPets` | `"Kind:Level:uid,…"` (Level = pet level = the highest shown trait level; empty when none; `PetConfig.DecodeEquipped` also reads the old `Kind:Level` form); `PetFollow` renders them on every client |
| `PetNames` | JSON `{ [uid] = filtered name }` of the named equipped and field pets, `""` when none (`PetConfig.DecodeNames`): carries names to every client (`PetFollow`, `GardenView` / `PlotView`); `EquippedPets` and the plot feed hold no names. The raw name is filtered again on every join |
| `GardenPlot` | slot of the borrowed plot (`GardenConfig.PlotCFrame(slot)`; absent when none) |
| `CollectedCoins` | sorted challenge coin ids, comma-separated, `""` when none: `ChallengeCoinsClient` hides those coins for that player only (the server never hides a coin) |
| `LanguageSetting`, `Language`, `SystemLocale` | the stored choice (`""` = automatic), the resolved code clients render in, the device locale the client reported |
| `ArenaKeys`, `ArenaOpened` | `ArenaConfig.Encode` lists of the Key Vault keys held / gates opened (`ArenaServer`; reset when a new run starts or the player leaves); `ArenaClient` shows each player their own state |
| `HallWeekBest` | JSON `{ [cropId] = factor }`: the player's biggest of each crop this week |
| `LikedToday`, `LikedDay` | `IdSet` of owner UserIds the player liked that UTC day, and that day |

`ReplicatedStorage.HarvestHall` attribute `Board` = JSON `{ week, endsAt, crops = { [cropId] = { { u, n, f, t }, … } }, best = { [cropId] = { u, n, f, t } } }` (the week's board and the all-time #1s, this server's queued entries on top).

Pets and the field:
- A pet is either equipped or on a field square: `PetService` rejects Equip / SellPet of a field pet; `GardenField.PlacePet` validates, removes the equipped assignment and places it without yielding.
- Aptitudes (`PetConfig.Aptitudes`) are rolled once from `userId/uid` (at hatch, or by the `Version` 4 migration) and never rerolled; ids never renamed. `Cuteness` carries the Coin bonus (`PetConfig.PetBonus`). Tending works on the field; Scouting while equipped (medal finishes give it XP; `PetConfig.ScoutBonus` raises rare-seed meter points and, at +50 %, the seed pouch).
- The plots exist only on the clients: `GardenView` draws them into the client folder `Workspace.GardenView` (`Slot_NN` > `base`, `inc1..3`, `field`, `sq1..78`) from `GardenRemotes.Plot`; the server adds no instance to Workspace.
- Plot state `field.plants[squareString]` = `{ n (planting number), startAt (effective start at the current online rate), readyAt (first whole server second when ripe), size (harvest mass factor incl. the Sorter; missing = 1), fruit?, young? }` (fruit trees, as in `State.field.squares`); private `field.squares` also carries `size`. Both times are 0 once settled ripe. Clients clamp progress between the anchors with server time and derive appearance from the owner id and `n`; Plant / Harvest still settle on the server. Visible countdowns convert `readyAt − now` with `CropConfig.CountdownRate(field.tools)` (×2, up to ×2.4 with Cloches); readiness and art use the original anchors. Field-job XP uses `WorkSeconds` (online ×1 / offline ×0.5, capped 24 h).
- Plant art Parts carry client-local `PlantRole` (`Support`, `Structure`, `Fruit`) and `FruitSlot`: visual only, never server state.
- Incubator eggs: `PetConfig.HatchSeconds[rarity]` sets the wait; stored with server `os.time()` and checked at `Hatch` (to test without waiting, move `StartedAt` / `ReadyAt` back in the stored profile: snapshot and restore it). Private State exposes egg id and the timer anchors; kind and rarity stay server-only until Hatch. The public plot carries `EggId:readyAt:startedAt` (no kind or id); the third anchor drives a display-only 30 s scan; old two-field strings still parse; ready wins over scanning for instant eggs.
Harvest Hall / likes (profile `Garden`, missing = empty): `WeekBest = { Week, [cropId] = factor }` (the player's biggest of each crop this week; a new week starts it over and puts the old week into `RibbonPending` when it held any), `RibbonPending = { week, … }` (finished weeks to read for ribbons, at most 8), `Ribbons = { [cropId] = n }` (weeks won as #1), `Likes` (received in all), `Liked = { Day, [ownerUserId] = true }`. The plot state carries `likes` and `ribbons` (total) for the sign.

Checkpoint respawn state is kept in `ServerStorage.CheckpointData.<UserId>` (ObjectValue, runtime only).

## Planned offline garden visits

**Designed, not implemented** (no `GardenSnapshots` in code). `GardenSnapshots`, key `garden_<UserId>`, is separate from the
live profile and its write gap. Write on leave and at most once per five minutes while the garden changes. Proposed payload:
a compact JSON object with name, field pets, eggs as `Egg:readyAt`, and four characters per square (crop, minutes to readiness in
two base-64 characters, size/variant), targeting under 1 KB. One visit uses one `GetAsync`; an owner on another server uses the same
snapshot, at most five minutes old, without MessagingService. Reconcile this proposed encoding with the current crop/fruit state
before implementation; it is not a shipped schema.
