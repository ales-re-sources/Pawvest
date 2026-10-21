# Oby sandbox — agent guide

Roblox obby (obstacle course): a central hub island with portals to timed stages, checkpoints,
per-stage Top-10 leaderboards, collectible coins and a small admin panel.

- Place: **"Oby sandbox"**, placeId `83181838162651` (pinned in `Oby.project.json` → `placeIds`).
- Code is synced to this repo with **Argon** (Rojo-compatible); the **scene lives only in the place file**.
- Language: Luau, legacy run context (`.server.luau` = Script, `.client.luau` = LocalScript, `.luau` = ModuleScript).

## Project docs & workflow
- [docs/GDD.md](docs/GDD.md) — game design: loop, stages, time tiers, rewards, talents, economy numbers.
- [docs/ROADMAP.md](docs/ROADMAP.md) — milestones, acceptance checks, status. Answer "what next?" from here.
- [docs/PET_GROWTH.md](docs/PET_GROWTH.md) — design and plan for the pet growth visuals (P1e1–P1f).
- [docs/STYLE_PREVIEW.md](docs/STYLE_PREVIEW.md) — parked voxel / pixel-art style previews (Studio-only `ServerStorage.StylePreview`), decision pending.
- [docs/STAGES.md](docs/STAGES.md) — stage expansion to ≈ 20 stages: obstacle component catalogue, combination patterns, difficulty curve, special / bonus stages, talent gating, worlds / hub layout, proposed S milestones.

Work milestone by milestone per ROADMAP (design check → implement → Studio validation → status update → commit);
update the status levels (Implemented / Studio-validated / Live-validated) only after validation.

## How code gets here (read before editing)

Argon runs in **Only Code Mode**: `src/` contains every script **plus the instances that contain scripts**
(as folders with `init.meta.json` holding only `className`; no properties). Parts, GUI layout,
RemoteEvents, Sounds, lighting etc. exist **only in Studio**.

Consequences:
- Do not "clean up" folders like `src/Workspace/Stage3/Part_01/` — that folder *is* the kill part that owns the script.
- Changing a part's size/color/position, GUI layout, or adding a RemoteEvent must be done in Studio
  (manually or via the Roblox Studio MCP), not in files.
- Never run `argon build` to produce the real place — it would contain only scripts and default parts.
- Safety nets that must stay on: `$keepUnknowns: true` on every service in `Oby.project.json` and
  the plugin's **Keep Unknowns** setting. Without them a Server-priority sync deletes the scene.
- Sibling names must be unique (Argon drops duplicates on syncback). New parts that get a script
  need unique names (`Part_11`, `KillPart_3`, …). Exception: ChoiceStage `Step` parts — see Gotchas.
- `sourcemap.json` and `*.rbxl` are git-ignored.

Roblox Studio MCP is available for inspecting/editing the live place (`search_game_tree`,
`execute_luau`, `script_read`, `screen_capture`, playtests). Studio must be in **Edit** mode for
`datamodel_type: "Edit"`.

## Layout

```
src/
  ReplicatedStorage/
    StageConfig.luau                  stage list (key, folder, world, requires, hub portal, T_base, tiers, unlock, reward factor) + Worlds (name, gate model, island folder, spawn part; the Tutorial is world 0 = hub) with PortalFolder / LocationKey / ReturnSpawn + medal, run-reward, world-stars and unlock-bar math
    KitMath.luau                      obstacle kit timing maths (pure): Cycle, Window (beam on / warning / off), Plate, Lift, Piston, Sine, Swing, Gust, TimeBase (server time or run time); every client derives the same phase from workspace:GetServerTimeNow()
    TimeFormat.luau                   tenths rounding, "mm:ss.t" and short "m:ss" formatting
    MedalText.luau                    rich text for stars, medal limits and the timer's medal target
    AdminConfig.luau                  admin UserIds + IsAdmin (client UI gating and server checks)
    ChallengeCoinConfig.luau          challenge coins: tier values (20 / 50 / 100), coin list (id, stage, tier), Found x/y, Encode/Decode of the CollectedCoins attribute
    TalentConfig.luau                 talents (Run Speed, Double Jump, Jump Height, Quick Respawn): costs, optional per-level effect text, effect helpers (RespawnDelay, HasFallReset), Talent_<id> attribute names
    PetConfig.luau                    pet kinds, rarities (bonus ‰, sell value), eggs + weights, slot prices, level curve, XP sources; Roll, PetBonus, Multiplier, XpToNext, GainXp, MoveXp; MaxScale, Tiers, ScaleOf, TierOf, Encode/DecodeEquipped (EquippedPets attribute)
    PetLook.luau                      pet look as a pure function of (kind, level, uid): Scale (1.0 → 1.6 by level), Tier, Seed(uid) (individuality: hue / saturation / value shift of the body parts, grey parts tinted (Bunny: 60 % get a grey ... near-black coat), optional material texture on more parts with level, accessory pick seed; deterministic, uid nil = none), FxColor (per-pet effect colour: rarity colour shifted by the seed; model attribute FxColor), TexturedCount, Apply (flags, seed jitter, accent tint, scale, label, Epic/Legendary glow, accessories, tier effects trail / aura+updraft / orbiting motes / halo in rarity colour; used by PetFollow and the garden pens), AccessoryCount / AccessoriesOf / AccessoryAllowed (P1f accessory kit: crown, scarf, wings, horns, flame tail built in code from Head / Body / Tail*; 1 piece at Lv 10, 2 at Lv 20 picked by the seed with kind skip rules; model attribute Accessories, Folder Accessories in the model), AccentBlend, Bob, CollectFx / UpdateFx (per-frame mote orbit + distance LOD, 60 studs), LabelText ("Cat Lv 12 ★★"), LevelUp (client-only staged level-up moment: spin + rise, flash, old/new look cross-fade, burst, ring, floating text; returns a moment whose Pose(base) the owner of the pose calls every frame; optional Studio-only ReplicatedStorage.PetLevelUpSound), Slots (formation from scaled sizes)
    PetModels (Studio-only Folder)    one part-built Model per PetConfig kind; invisible PrimaryPart "Root" (front = −Z), all parts Anchored, CanCollide/CanTouch/CanQuery off; accent parts carry the attribute Accent = true (tinted by level, P1e3)
    ChallengeCoinSound (Studio-only)  Sound played on a challenge coin pickup (cloned locally by ChallengeCoinsClient)
    GardenConfig.luau                 pet garden: plot count / size, NewAssigner (pure plot assigner), pen prices, production rates (BaseRates, LevelRate), integer Units / Settle maths, IsPenned; incubator prices, EggReady, IncubatingCount (P2b1); Foods, FoodById, XpToMax (P2b2)
  ServerScriptService/
    PlayerProfile.luau                per-player profile DataStore (load/migrate/save), AddCoins, CoinsChanged
    CoinRewards.luau                  Grant(player, base, source): the only gameplay Coin payout (pet multiplier, rounding)
    PetService.luau                   pets: eggs (paid / free; a hatched pet takes a free slot), equip slots, sell; PetRemotes, EquippedPets attribute, Multiplier, GrantFreeEgg, AddXP (equipped pets, level-ups), AddPet / PetCount (shared with the incubators)
    AvatarThumbs.luau                 leaderboard avatars: Show(PhotoN ImageLabel, userId or name) fetches the head shot (GetUserThumbnailAsync, in-memory cache 30 min; legacy entries without UserId resolved by name)
    StarBoard.luau                    hub "most stars" ranking: OrderedDataStore MostStars (UserId → total stars); Sync(player) writes only when the total changes (new medal, admin reset, join back-fill), Refresh / Top / Changed feed the hub board
    StageResults.luau                 finish → personal best, medal, one-time payout + daily repeat reward, free egg on first Gold, pet XP (medal + movement); Medal_<folder> attributes
    RunDistance.luau                  server-measured horizontal studs during a run (Start / Stop from PlayerTimerHandler); steps faster than WalkSpeed allows (teleports, respawns) are dropped
    StageUnlocks.luau                 hub portal gate: bar (previous stage's medal) or bought unlock; UnlockRemotes, Unlocked_<folder> attributes
    HomeService.server.luau           GoHome remote: Home button → from a stage of a world to that world's island spawn, from anywhere else to the hub spawn; cancels the running timer
    Garden.server.luau                garden boot: requires GardenPlots + GardenService + GardenIncubators + GardenFood (no portals since H1: the garden is reached over Workspace.GardenBridge)
    GardenPlots.luau                  borrows one of 12 plots per player on join / releases on leave: player attribute GardenPlot, plot attributes OwnerUserId / OwnerName, sign text; PlotChanged
    GardenService.luau                pens + production: profile Garden, GardenRemotes (Place / Remove / BuyPen / RequestState; State / Result / Payout), settle on join (8 h cap) / every 5 min / before every pen change, draws pens + pet models into the plots; hooks for sibling modules (Remote, Allow, Reject, Succeed, Usable, SettleAndNotify, PublishAll, AddStateField, AddRenderer)
    GardenIncubators.luau             incubators (P2b1, P2b3): the only place eggs hatch; StartEgg(incubator, eggId) / Hatch / BuyIncubator remotes, Basic / Golden eggs hatch at server os.time() ReadyAt (also offline), roll at Hatch, inventory cap counts incubating eggs; starts waiting FreeEggs in empty incubators; draws Incubator_n attributes State / Egg / ReadyAt
    GardenFood.luau                   food stand (P2b2): Feed(uid, foodId) remote near Garden.FoodStand, price + XP from GardenConfig.Foods, only the fed pet levels, Lv 20 rejected, penned pets settled first
    RespawnService.server.luau        the only place that loads characters: sets Players.CharacterAutoLoads = false, join spawn + every respawn via LoadCharacter after a delay from Talent_QuickRespawn (Players.RespawnTime / 1 s / 0)
    TalentService.server.luau         talent purchases (Buy remote, server-priced), levels → profile + Talent_<id> attributes, WalkSpeed/jump on spawn
    CoinSystem.server.luau            leaderstats (Stars = StageConfig.TotalStars from the Medal_<folder> attributes, Coins) mirrored from profile, CoinUpdateEvent
    ChallengeCoins.server.luau        challenge coin pickup (tag ChallengeCoin, attribute CoinId): validated touch → CollectedCoins, CoinRewards.Grant, +1 pet XP, CollectedCoins attribute
    ResetPlayerTimerServer.server.luau  ResetPlayerTimer remote → admin-only full reset of the caller's own progress
    AdminCoinsServer.server.luau      AdminAddCoins remote → admin-only +AdminConfig.AddCoinsAmount Coins for the caller (debug; created at runtime)
  StarterPlayer/StarterPlayerScripts/
    StageTimerClientUpdater.client.luau  StageTimer label: counts locally between start/stop from StageTimerUpdate
    TalentDoubleJump.client.luau      Double Jump talent: extra air jumps from the Talent_DoubleJump attribute
    StageResultsPopup.client.luau     results popup after a finish incl. pet XP line (GUI built in code)
    GateDoors.client.luau             door gates of the world stages (S4.0): door solid + unlock popup while locked, ghost when unlocked (local only); OpenUnlockPopup player attribute asks StageUnlockPopup
    HubGateFaces.client.luau          world gate faces in the hub (S4.0): stars earned x / max and challenge coins found x/y of the world on its gate's Portal face
    HubPortalMedals.client.luau       own best-medal stars, challenge coins "found x/y" + lock requirement/price on each stage's face (StageConfig.FaceTarget: the Door of its start gate, the hub portal for the Tutorial) (local SurfaceGuis; layout kept inside the arch's opening)
    CameraFacing.client.luau          (skips while a StageCamera mode is active) camera turns to the character's facing after a teleport (> 30 studs in a frame at > 500 studs/s) and on the first spawn; the targets set the facing: `SpawnLocation` looks at the Tutorial / Stage 1 portals, `TeleportDestination` along the course
    CheckpointClient.client.luau      checkpoints for the local player (H2): CheckpointReached(part, first) lights that pad (Core 3 → 7 Neon, PointLight, Beam rises; 1 s) and turns the previous one back, so only the current checkpoint glows; `first` also plays workspace.Handlers.CheckpointTouchHandler.Sound (SoundService copy); CheckpointsReset turns the lit pad back; values in the LOOK table
    ObstacleKit.client.luau           obstacle kit (S3.1 / S3.2a): client-driven parts from CollectionService tags + attributes, no server animation: KitMover (Kind Slide / Lift / Spin / Piston / Swing; carries the character standing on it, jump-off air carry, optional Kill / Push), KitBeam (blinking kill beam), KitPlate (disappearing plate), KitTilt (kit-local tilt plate with slide-off), KitCrumble (kit-local crumbling plate), KitSwitch + KitColorPlate (kit-local colour groups), attribute RunSeeded (run time instead of server time); client kill = the local Humanoid.Health = 0; attribute reference in the script header, test stations in the Studio-only `Workspace.KitLab`
    KitZones.client.luau              kit zones (S3.3a): parts tagged KitZone, Kind Wind (Push, gusts) / LowGravity (GravityScale) / Updraft (Lift, Accel); act on the local character while inside; test stations in `Workspace.KitLab` row 4
    KitGhosts.client.luau             ghost zones (S3.3b): parts tagged KitGhostZone (attribute Transparency, default 0.65); other players' characters inside one are drawn translucent (LocalTransparencyModifier) where each player sees their own kit-local state
    StageCamera.client.luau           camera modes Iso / Side / Down / Front (S3.2b): zones = parts tagged CameraZone with attribute Mode (+ Yaw / Pitch / Distance / Fov / Lead / Height / Priority overrides) or a stage folder attribute CameraMode while that stage's timer runs; Scriptable camera, blends in / out, snaps behind the character on death / teleport; player attributes CameraMode / CameraZone; test zones in the Studio-only `Workspace.KitLab` row 3
    BounceBricks.client.luau          bounce bricks (tag BounceBrick, attribute LaunchSpeed set by each brick's script): on touch sets the local character's velocity along the brick's LookVector to exactly LaunchSpeed (deterministic; the client owns its character)
    ChallengeCoinsClient.client.luau  hides the local player's collected challenge coins (local Transparency/CanTouch), spins the others, plays the pickup sound
    PortalBarriers.client.luau        invisible local wall in each locked hub portal (removed when Unlocked_<folder> turns true)
    QuickRespawnClient.client.luau    Quick Respawn level 2: fall reset (falling character below its checkpoint plate by the stage's attribute FallResetDepth, default 30, never below the sea + 5 studs, plate within 300 studs → back on the plate; 0 = off) + short fade; mirrors CheckpointReached / CheckpointsReset
    StageUnlockPopup.client.luau      unlock popup after touching a locked hub portal (requirement, "Needs:" talents, price, unlock button; GUI built in code)
    StageArrivalWarning.client.luau   popup on arriving at a stage without a required talent (StageArrival remote from PlayerTimerHandler), button sets the ScreenGui attribute OpenSkills (ButtonHandler opens the Skills panel); entry never blocked
    PetClient.luau                    ModuleScript: client mirror of PetRemotes.PetsChanged + Coins (Inventory, Changed / Result signals); asks RequestState on load
    PetsPanel.client.luau             Pets panel (own ScreenGui "PetsGui": inventory with level + XP, equip, buy slot, sell with 2nd click, total bonus); opened by the 🐶 button
    PetFollow.client.luau             renders every player's equipped pets (EquippedPets attribute "Kind:Level:uid,…") via PetLook: local folder workspace.PetFollowers, one smoothed anchor per owner, camera fade, run mode (pets further back + ghostly while the owner's stage timer runs), level-up detection per uid (PetLook.LevelUp on the pet whose level rose, old model kept as the ghost), per-frame PetLook.UpdateFx (motes, LOD, emitters off while faded), tier-based bob
    PetPenLevelUp.client.luau         same level-up moment for garden pens (no cross-fade): watches the pen attributes Uid / Level (feeding a penned pet)
    PetPenFx.client.luau              garden pens: orbit animation of the motes + distance LOD for the tier effects the server built (PetLook.UpdateFx; model attribute FxCount)
    GardenClient.client.luau          garden: pen prompts (own plot only), pen panel (unlock / place / remove), "while you were away" popup, payout toast; GUI built in code; test hook: ScreenGui attribute OpenPen
    IncubatorClient.client.luau       incubator prompts (own plot only), incubator panel (unlock / start a Basic or Golden egg / free eggs waiting / countdown / Hatch + reveal), countdown labels on every plot from ReadyAt + GetServerTimeNow; test hook: IncubatorGui attribute OpenIncubator
    FoodShopClient.client.luau        food stand panel (every pet with level, XP, XP to Lv 20; one feed button per food); test hook: FoodShopGui attribute Open
  StarterGui/
    CoinGui/CoinDisplayScript.client.luau        top-right coin counter
    ScreenGui/TopLeftIcons/ButtonHandler.client.luau  icons Home (🏠 go to hub) / Skills (⚡) / Pets (🐶, cloned in code) / Settings / Admin, positioned in code in this order; slide-in panels (AdminConfig)
    ScreenGui/SkillsPanel/TalentRows.client.luau  "Your skills" panel (⚡ button): talent rows built in code
    ScreenGui/AdminPanel/...                      RunSpeed (16↔64), DoubleJump (up to 5 air jumps), ScoreReset, AdminAddCoins.client.luau (+Coins button, built in code)
  Workspace/
    Handlers/                         ModuleScripts shared by all stage scripts (required via workspace.Handlers.*)
      CheckpointTouchHandler.luau     checkpoint touch → respawn point, fires CheckpointReached(part, first) to that player whenever the respawn point changes (`first` = first reach in the run → sound); a TimerStart touch counts as the stage's lowest-numbered checkpoint; NewRun from TimerStart fires CheckpointsReset; dead characters ignored; a respawn is placed on the stored plate facing its LookVector (the course direction)
      PlayerTimerHandler.luau         stage timers (os.clock), personal bests (profile), global Top-10, score panel
    StartLocation/                    hub (central island, part-built since H1, centre (-1126, 16, -475), r 80): SpawnLocation on the plaza + TeleportToTutorial and GateWorld1 (S4.0: Script + 1.25x arch + Portal; teleports to the World 1 island) in an arc facing it (the stage portals moved to Workspace.World1) (each: Script, `Portal` = touch trigger + face with the stage-name SurfaceGui, Studio-only `Arch` Model of stud-stone blocks cloned from `ServerStorage.DecorKit.StudPortal`, H1.1) + StarsLeaderboard (Studio-only board model in the wooden stud style, no scripts; StarsBoard.server.luau beside it draws into Model.ScoreBlock.SurfaceGui: DataLabel, Names.NameN, Score.ScoreN, Photos.PhotoN); Studio-only Island folder (Island, IslandRock, Plaza, PlazaRing, Hedge + invisible Barrier ring with an opening toward the garden, BridgePath, GardenSign, Decor). Scripts find the hub by name, never by coordinates
    World1/                           World 1 courtyard (S4.0, Studio-only): the pads of Island Hop (slot 1, x -159, not built yet), Stage 1 (-213), Blink (-267, not built yet), Stage 2 (-321), Stage 3 (-375) stand side by side at y 77 (pad centre z 206, every course runs north) joined by `Plaza` (x -420..-114, z 185..305, top y 78) with a `Rock` underside, a low `Wall` (6 high) around it and between the gates, `Spawn` pad (hub gate lands here, facing north), `ReturnGate` (Script + Portal + Arch in the south wall: back to the hub), `SoonGate1` / `SoonGate3` (closed "Coming soon" copies of a StartGate for the two future stages), Decor. The stages lie physically behind the gates
    Stage1/ Stage2/ Stage3/ Tutorial/ stages (see below)
    <Stage>/ChallengeCoins            Studio-only Folder (every stage): Coin_<n> MeshParts tagged ChallengeCoin with attribute CoinId (ids listed in `ChallengeCoinConfig`)
    DebugBaseplate/                   kill brick under the map = the sea (H1: centre (-350, -8, -100), top y 0, covers every stage, the hub and the garden; sea blue Glacier + Texture)
    Sea (Studio-only Folder)          Tile_1..8: cosmetic sea around DebugBaseplate out to the horizon (no scripts, CanCollide / CanTouch / CanQuery off)
    GardenBridge (Studio-only Folder) wooden bridge hub <-> garden at 75° from the garden centre: Deck, Rails, Supports, invisible Barrier walls (top y 16 like both islands)
    Garden/                           Studio-only pet garden island at x -1200, z -750: Island, Plaza, Hedge + invisible Barrier ring (opening at 75° for the bridge: *_GateL / *_GateR), BridgePath, HubSign, Decor, Plots/Plot_01..12 (Floor 40x40, Edge_*, Sign with SurfaceGui "Gui" > "Label", Pen_1..6 with Pad + Prompt + Info billboard, Incubator_1..3 with Base (PrimaryPart) + Prompt + Info billboard (Adornee = Egg, label above the egg), Nest, Egg ball + PointLight), FoodStand (Model on the plaza, PrimaryPart Counter with Prompt); GardenService adds PenPets folders
```

### Stage anatomy
Every stage folder follows the same pattern:

| Child | Script behaviour |
|---|---|
| `LandingPad/TeleportDestination` | arrival point after a finish or Home (invisible, on the plaza in front of the stage's gate, facing it); for the Tutorial also the arrival from the hub portal |
| `LandingPad/TimerStart` | starts the timer unless one already runs on this stage (refused unless `StageUnlocks.IsUnlocked`, shows the stage on the score panel) + acts as checkpoint; an invisible 48 × 30 × 4 trigger across the whole pad edge; touching it counts as reaching the stage's first checkpoint (`CheckpointTouchHandler`, H2), so the respawn point is that plate |
| `LandingPad/TeleportToSpawn/Portal` | **Tutorial only** (the world stages have none since S4.0): back to hub; cancels timer, score panel → hub (Studio-only `Arch` Model beside it) |
| `LandingPad/StartGate/Door` | world stages (S4.0): Studio-only wooden door between the gate's pillars; `GateDoors.client` makes it solid + opens the unlock popup while the stage is locked for the local player, a faint ghost once unlocked; `HubPortalMedals` draws stars / coins / lock lines on its Back face |
| `LandingPad/GateExit` | world stages (S4.0): invisible trigger just outside the door; walking back out cancels the running timer (panel → world) |
| `LandingPad/Decor` | Studio-only Model (H1.2): cobblestone inlay, hedges, kit trees / bushes / flowers; `LandingPadTop` / `LandingPadBottom` are the grass pad and its rock |
| `LandingPad/StartGate` | Studio-only Model (H1.2): two 17-stud stud-stone pillars, wooden beams and the sign (`Sign.Gui.Title` / `Start`) over `TimerStart` |
| `LandingPad/GateSign` | script: writes the `StageConfig` display name on `StartGate.Sign.Gui.Title` |
| `LandingPad/Top10Leaderboard` | SurfaceGui board from `LoadGlobalLeaderboard(stage.key)` (Stage1, Stage2, Stage3, Tutorial); its Studio-only `Model` is a clone of `StartLocation.StarsLeaderboard.Model` (wooden frame, same `ScoreBlock.SurfaceGui` names) |
| `<number>/C` | checkpoint (`1`–`9` Stage1, `10`–`14` Stage2, `20`–`22` Stage3, `23`–`25` Tutorial): `C` is the whole 16 × 1 × 12 cream stud plate (touch trigger + Script, respawn point); Studio-only `Core` (3 × 3 green stud tile set into the plate, `PointLight` off) and `Beam` (Neon cylinder 18 high, invisible) are animated per player by `CheckpointClient` (H2). The plate's upstream edge touches the previous obstacle |
| `TeleportBackToStageStart/Portal` | finish line: `StopTimer` → save best time; sibling script teleports to stage start |
| obstacle models | kill parts, spinners, lava, bounce bricks, choice stage |

**Kit obstacles:** `ServerStorage.StageKit.Obstacles` (Studio-only, S3.3b) holds one preconfigured template per kit component (movers, hazards, plates, switches, zones, camera zones, ghost zone, run-seeded samples; `Hazard_PendulumRig` is a model with its frame): clone, `PivotTo` the spot, adjust attributes (listed in the header of `ObstacleKit.client.luau` / `KitZones` / `StageCamera`). The tags and attributes come with the clone.

**Adding a stage:** clone `ServerStorage.StageKit.LandingPad` (Studio-only template: floor, decor, start gate with door, gate-exit trigger, Top-10 board and the scripts, all stage-neutral) into the new stage folder as `LandingPad`,
`PivotTo` the pad centre (the template's pivot is the centre of the pad's top; the first checkpoint platform of the course must be centred on it, its edge 21 studs north: the gate, trigger, arrival point and return portal all sit on the pad's centre line), add the `StageConfig` entry and the hub portal. Checkpoints: clone `ServerStorage.StageKit.Checkpoint` (plate + `Core` + `Beam` + the C Script; pivot = centre of the plate's top), rename it to the next free number and put its upstream edge against the previous obstacle, its front (LookVector, −Z) pointing along the course (the respawn faces that way). Scripts resolve the stage from the folder, so nothing else needs editing;
Argon writes the clone's script files on its own. The template's scripts are copies: when a stage script changes, change the template's copy too.

Stage scripts never hard-code a stage: they call `StageConfig.ForInstance(script)` (stage = the Workspace folder they
live in) or `StageConfig.ByHubPortal[...]`, so all copies of TimerStart, finish portal, TeleportToSpawn, hub portal and
Top10Leaderboard are byte-identical. Stage keys (`"Stage 1"`…`"Stage 3"`, Tutorial `"Stage 4"`) are DataStore keys
and must never change. Hub label is `StageConfig.HubName` (`"Central Island"`).

## Reusable script variants (copy-pasted, not modules)

Most of the 93 scripts are identical copies. Edit them consistently (grep by content or md5):

| Count | Variant | Example |
|---|---|---|
| 20 | checkpoint → `CheckpointTouchHandler.OnTouched` | `Workspace/Stage1/1/C/Script.server.luau` |
| 16 | kill on touch (`Humanoid.Health = 0`) | `Workspace/Stage3/Part_01/Script.server.luau` |
| 8 | kill player on touch (debounced by `hit`) | `Workspace/Stage1/LaserStripStage/Part_01/…` |
| 0 | ~~spinner~~: since S3.3c the Stage 1 spinners (`Workspace/Stage1/SpinnerStage_1` / `_2`) are kit parts: attributes `Kind = Spin`, `Speed = 60` (the old 2° per `wait()`), `Kill` on the two sweeper bars, `Carry = false` on the two spinning plates, tag `KitMover`, no scripts (the folders only hold `init.meta.json`; the hub pillars `Part_4/5`, `_2: Part_2/6` no longer rotate, their rotation was invisible) | – |
| 4 | `TimerStart` | `Workspace/Stage*/LandingPad/TimerStart/…` |
| 1 | `TeleportToSpawn` (Tutorial only since S4.0) | `Workspace/Tutorial/LandingPad/TeleportToSpawn/…` |
| 4 | `GateExit` (3 stages + the kit template) | `Workspace/Stage*/LandingPad/GateExit/…` |
| 4+4 | finish portal / teleport back to stage start (Stage1 teleport copy differs slightly) | `Workspace/Stage*/TeleportBackToStageStart/…` |
| 1 | hub portal `TeleportToTutorial` (the stage portals are gone since S4.0: the stages open through door gates) | `Workspace/StartLocation/TeleportToTutorial/…` |
| 2 | Top10Leaderboard | `Workspace/Stage1/LandingPad/Top10Leaderboard/Script…` |
| 4 | `GateSign` | `Workspace/Stage*/LandingPad/GateSign.server.luau` |
| 3 | ChoiceStage random safe `Step` | `Workspace/Stage1/ChoiceStage_*/Script…` |
| 3 | bounce brick: declares `LAUNCH_SPEED` (attribute `LaunchSpeed` + tag `BounceBrick`; the launch is done by `BounceBricks.client`) — all 300 since the user's tuning (2026-10-21); `Bounce Brick_1`–`_3` are siblings | `Workspace/Stage2/12/Level 12/Bounce Brick_*` |

## Networking & persistence

RemoteEvents (in `ReplicatedStorage`; first three exist only in Studio, not in files):

| Remote | Direction | Purpose |
|---|---|---|
| `StageTimerUpdate` | server → client | `(elapsed ≥ 0, stageKey)` run active; `(-1, final, result)` finished; `(-1)` cancelled |
| `StageTimerStopped` | — | unused since M0 (was the stop ack); can be deleted in Studio |
| `ResetPlayerTimer` | client → server | admin panel "Reset Score": full reset of the caller's own progress; server checks `AdminConfig` |
| `AdminAddCoins` | client → server, no arguments | admin panel "+Coins": server checks `AdminConfig`, credits `AdminConfig.AddCoinsAmount` to the caller; created at runtime by `AdminCoinsServer` |
| `CoinUpdateEvent` | server → client | created at runtime by `CoinSystem` |
| `CheckpointReached` | server → client `(part, first)` | created at runtime by `CheckpointTouchHandler`; the player's respawn point moved to that checkpoint (the stage's `TimerStart` counts as its first checkpoint) → `CheckpointClient` lights that pad and turns the previous one back, for that player only; `first` (first reach in the run) also plays the sound |
| `CheckpointsReset` | server → client, no arguments | created at runtime by `CheckpointTouchHandler`; a new run started (`NewRun`) → `CheckpointClient` turns every pad back |
| `GoHome` | client → server, no arguments | Home button; created at runtime by `HomeService`, 3 s cooldown, server teleports + cancels the timer |
| `TalentRemotes.Buy` / `.Result` | client → server `(talentId, expectedLevel)` / server → client `(talentId, ok, level or reason)` | created at runtime by `TalentService`; the price is never sent |
| `UnlockRemotes.Buy` / `.Result` / `.Locked` | client → server `(stageKey)` / server → client `(stageKey, ok, reason?)` / server → client `(stageKey)` | created at runtime by `StageUnlocks`; price from `StageConfig.unlockPrice`; `Locked` opens the unlock popup |
| `PetRemotes.Equip` / `.Unequip` / `.BuySlot` / `.SellPet` / `.RequestState` | client → server `(uid)` / `(uid)` / `(expectedSlot)` / `(uid)` / no arguments | created at runtime by `PetService`; `RequestState` only re-sends `PetsChanged` (a client that was still loading misses the join publish); uids are strings; prices and sell values are server-side. No egg remote here: eggs hatch only in the garden (`GardenRemotes.StartEgg`) |
| `PetRemotes.PetsChanged` / `.Result` | server → client `({ pets, equipped, slots, freeEggs, multiplier })` / `(action, ok, detail or reason)` | state after load and every change; per-request answer (hatch result, sale value, reject reason) |
| `GardenRemotes.Place` / `.Remove` / `.BuyPen` / `.RequestState` | client → server `(penIndex, uid)` / `(penIndex)` / `(expectedPen)` / no arguments | created at runtime by `GardenService`; the plot is derived from the caller (must stand within 45 studs of it); prices from `GardenConfig.PenPrices`; no remote carries a time |
| `GardenRemotes.StartEgg` / `.Hatch` / `.BuyIncubator` / `.Feed` | client → server `(incubator, eggId)` / `(incubator)` / `(expectedIncubator)` / `(uid, foodId)` | created at runtime by `GardenIncubators` / `GardenFood`; prices from `PetConfig.Eggs` / `GardenConfig.IncubatorPrices` / `GardenConfig.Foods`; hatch time checked against server `os.time()`; answers on `GardenRemotes.Result` |
| `GardenRemotes.State` / `.Result` / `.Payout` | server → client `({ pens, penCount, rate, incubators = { count, eggs = { ["n"] = { egg, readyAt } } } })` / `(action, ok, detail or reason)` / `({ id, seconds, base, paid, capped, away })` | `away = true` is the join payout (popup, re-sent on `RequestState`, shown once per `id`), otherwise a toast |

DataStores:

| Store | Key | Value |
|---|---|---|
| `PlayerProfiles` | `user_<UserId>` | `{ Version = 3, Coins, BestTimes[stageKey], Medals, UnlockedStages, CollectedCoins, Talents, RunsToday, Pets[uid] = { Kind, Level, XP }, EquippedPets, PetSlots, NextPetUid, FreeEggs[eggId], LaunchEgg, Garden = { Pens["1".."6"] = uid, PenCount, LastSeen = server os.time, Carry, Incubators["1".."3"] = { Egg, StartedAt, ReadyAt }, IncubatorCount } }` |
| `PlayerCoins` | `UserId` | legacy integer coins — read once for migration |
| `PlayerScoresStore` | `player_<UserId>` | legacy `{ {StageName, Elapsed}, … }` — read once for migration |
| `GlobalLeaderboardsStore` | `leaderboard_<StageName>` | Top-10 `{ {PlayerName, Elapsed, UserId?}, … }` (UserId missing on entries from before the avatar boards) |
| ordered `MostStars` | `<UserId>` | total stars (sum of the profile's medals, `StageConfig.TotalStars`); no entry = 0; hub board |
| ordered `"a"` | — | legacy time-played board; `TopTimeScript` is **Disabled** |

Gameplay Coins (medals, repeat rewards, pickups, future sources) go through `CoinRewards.Grant`; purchases and
deductions (and pet sales) call `PlayerProfile.AddCoins` directly. The multiplier is `PetService.Multiplier`
(1 + equipped pets' bonus, capped at +50 %). All Coin amounts were scaled ×10 in R2: records below `Version = 3` (and legacy
`PlayerCoins`) get `Coins × 10` once on load — never multiply stored Coins by hand. `RunsToday = { Day = <UTC day>, [stageKey] = finishes }` drives
the diminishing repeat reward (`StageConfig.RunReward`).

Player attributes `Medal_<stage folder>` (0–3) mirror `PlayerProfile.Medals` for client displays; `Unlocked_<stage folder>`
(bool) mirror `StageUnlocks` (bar met or `UnlockedStages[key]` bought; the bar is derived from medals, never stored).
`EquippedPets` (`"Kind:Level:uid,…"`, empty when none; `PetConfig.DecodeEquipped` also reads the old `Kind:Level` form) mirrors the equipped pets; `PetFollow` renders them on every client.
`Garden.LastSeen` is the server time up to which pen production was paid (never from a client); production since then is capped at 8 h.
A pet is either equipped or penned: `PetService` rejects Equip / SellPet of a penned pet, `GardenService` rejects Place of an equipped one.
Player attribute `GardenPlot` = index of the borrowed plot; pen models carry attributes `State` / `Uid` / `Kind` / `Level` (tests, client);
incubator models carry `State` (`free` / `locked` / `empty` / `egg`) / `Egg` / `ReadyAt` (server time; clients only display the countdown).
Incubator eggs are stored with server `os.time()` only and checked at `Hatch`; to test hatching without waiting, move `StartedAt` / `ReadyAt`
back in the stored profile between playtests (snapshot and restore it).
`CollectedCoins` (sorted ids, comma-separated, `""` when none) mirrors `PlayerProfile.CollectedCoins[id] = true`;
`ChallengeCoinsClient` hides those coins for that player only (the server never hides a coin).

Checkpoint respawn state is kept in `ServerStorage.CheckpointData.<UserId>` (ObjectValue, runtime only).

## Gotchas
- **ChoiceStage** scripts pick a random child and require `p.Name == "Step"`; the three `Step` parts
  per ChoiceStage must keep that exact (duplicate) name. They are not synced (no code inside).
- `PlayerProfile` is saved on leave, every 60 s and in `BindToClose`; a failed load blocks saving for that session.
  Don't `require` it from the MCP command context during a playtest: that creates a second copy that also saves.
- Only **one** Argon plugin may be enabled in Studio (the CLI installs `%LOCALAPPDATA%\Roblox\Plugins\Argon.rbxm`;
  a Creator Store copy must stay disabled). Two plugins each create every new file → duplicate scripts.
- Two-way sync is on: deleting/renaming a synced script **in Studio deletes/renames the file**. Do such changes on disk.
  Clean up Studio-side duplicates only while Argon is disconnected.
- Initial sync priority is **Client** (Studio overwrites files on connect): commit before connecting and check
  `git status` right after; files edited while disconnected are overwritten by Studio's copy.
- Studio playtests with API access read/write the **live** DataStores — snapshot and restore anything a test changes.
- `CheckpointTouchHandler`'s `Sound`/`Orig` children exist only in Studio (`CheckpointClient` clones `Sound` on the client).
- Checkpoint `Core` / `Beam` are authored in the "not reached" look; `CheckpointClient` reads that look once per pad and tweens to and
  from it, so restyle them in Studio in that state.
- Argon does not turn an existing plain Studio instance into a synced folder when a script file is added under it
  (it made a second empty `HomePanel`). Renaming such a folder on disk replaces the Studio instance with a bare Frame (styled
  children lost, rebuilt by hand). After adding/renaming script containers, check Studio for duplicates / lost children.
- **Moving a script container on disk recreates its Studio instance and drops its Studio-only children** (S4.0: `git mv` of
  `TeleportToStage1..3` into `World1/` deleted their `Arch` / `Portal`; rebuilt from the Tutorial portal). Reparent in Studio,
  keep a copy of the Studio-only children, and rebuild after the disk move.
- `Workspace/Stage3/level.2` is a Model literally named `level.2` (dot in the name).
- Decorations (H1) are clones from the Studio-only library `ServerStorage.DecorKit` (the "Stud pack V1" models: Tree1,
  Tree2, Flowers, Grass1/2, Rock, Bush, Wall, Shop, Leaderboard frame used for signs, StudPortal = template of the hub portal arches). Their stud textures are
  MaterialVariants in `MaterialService.StudPack` (`Studs`, `Inlets`, `Universal`…), looked up by name: keep that folder.
  Placed decor is Anchored with CanTouch / CanQuery off (flowers / grass also CanCollide off).
- Debounces in timer, portal and checkpoint code are per player. Kill scripts keep a script-global `h` keyed by the
  touching part (effectively per player).
- Timer uses `os.clock()`; times are floored to tenths (`TimeFormat.Tenths`) before storing.
- Challenge coins pay once per player and are hidden only on that player's client. Coin ids (`<stage folder>_<n>`) are
  stored in profiles: never rename or reuse one; a new coin needs a new id in `ChallengeCoinConfig` **and** the Studio
  part (tag + `CoinId`) inside its stage folder. Coins have no Highlight (removed in M4.1: Roblox renders at most 31 at once and 29 coins would use nearly all).
- Admins are listed once in `ReplicatedStorage.AdminConfig`; every admin remote must check `AdminConfig.IsAdmin`
  on the server (the client check only hides the panel). The RunSpeed/DoubleJump toggles are client-side debug tools.
- Tutorial is unfinished but has a hub portal (`TeleportToTutorial`). Stage2, Stage3 and Tutorial landing pads are geometrically identical (offsets from Stage2: Stage3 x −52.2, z +0.2; Tutorial x −121.6);
  Stage1's pad sits at hub height with its board at a different offset.
- Legacy APIs are common (`wait`, `spawn`, `:connect`, `findFirstChild`); prefer `task.*` and
  `Players:GetPlayerFromCharacter` in new code, but don't mass-rewrite without asking.

## Testing
No automated tests. Verify in Studio: playtest (MCP `start_stop_play`), read `get_console_output`,
and check DataStore behaviour only with Studio API access enabled.
MCP `screen_capture` with a camera position leaves the Edit camera on `Scriptable`: when done, set it back with
`workspace.CurrentCamera.CameraType = Enum.CameraType.Fixed` (Edit) so the user can move the viewport again.

Multi-client: the user starts Test → Start Test Session → **Server and Clients** (F7), then Test → **Add Clients**.
`list_roblox_studios` then shows one extra instance per client and one for the server (unnamed);
`get_studio_state` tells them apart by the focused DataModel. Test users have UserIds −1, −2… and create
`PlayerProfiles` records `user_-1`, `user_-2` — remove them afterwards.
