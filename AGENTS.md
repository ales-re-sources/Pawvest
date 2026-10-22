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
- Do not "clean up" folders like `src/Workspace/World1/Stage5/Part_01/` — that folder *is* the kill part that owns the script.
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
    StageConfig.luau                  stage list (key, folder, world, requires, hub portal, T_base, tiers, unlock, reward factor) + Worlds (name, gate model, island folder, spawn part; Worlds 3-4 carry `soon = true`, `stageCount` and an informational `unlock` / `unlockPrice` until their stages exist (S5; World 2 lost the flag with S6.1); the Tutorial is world 0 = hub) with PortalFolder / LocationKey / ReturnSpawn + medal, run-reward, world-stars and unlock-bar math
    KitMath.luau                      obstacle kit timing maths (pure): Cycle, Window (beam on / warning / off), Plate, Lift, Piston, Flip, Sine, Swing, Gust, TimeBase (server time or run time); every client derives the same phase from workspace:GetServerTimeNow()
    TimeFormat.luau                   tenths rounding, "mm:ss.t" and short "m:ss" formatting
    MedalText.luau                    rich text for stars, medal limits and the timer's medal target
    PortalFaceStyle.luau              text style of the status lines on hub portal / gate faces (black with a white outline; the portal's name label stays white with a dark outline): Apply(label); used by HubPortalMedals (portals) and HubGateFaces; a new hub portal gets the same look by using it (door faces keep their own closed / open colours)
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
    StarBoard.luau                    "most stars" rankings: OrderedDataStore MostStars (UserId → total stars, the hub board) and one `WorldStars_<n>` per built world (stars earned in that world, S5; `StarBoard.World(n)`, an empty stand-in for a `soon` world); Sync(player) writes every board only when its total changes (new medal, admin reset, join back-fill), Refresh / Top / Changed feed a board
    StageResults.luau                 finish → personal best, medal, one-time payout + daily repeat reward, free egg on first Gold, pet XP (medal + movement); Medal_<folder> attributes
    RunDistance.luau                  server-measured horizontal studs during a run (Start / Stop from PlayerTimerHandler); steps faster than WalkSpeed allows (teleports, respawns) are dropped
    StageUnlocks.luau                 stage gate: bar (previous stage's medal) or bought unlock; IsUnlocked / IsWorldOpen (a world gate is open when any of its stages is; a `soon` world is open for admins only); UnlockRemotes, Unlocked_<folder> attributes
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
    KitConveyors.server.luau          conveyors (S4.1): anchored parts tagged KitConveyor carry whatever stands on them along the part's front at attribute `Speed` studs/s (negative = backwards; the server sets AssemblyLinearVelocity once, per part and on attribute change)
  StarterPlayer/StarterPlayerScripts/
    StageMusic.client.luau            music of a rhythm stage (S4.2): a Studio-only Sound `Music` in the stage folder (attributes BPM, Metronome, BaseVolume) plays while that stage's run is active, driven by the run time (StageTimerUpdate): a tick on every beat (Metronome) or a looped track at TimePosition = run time mod length; silenced by the player attribute MusicMuted
    MusicSettings.client.luau         "Music: On / Off" row in the Settings panel (sets MusicMuted for the session; the row is added to every re-created ScreenGui)
    StageTimerClientUpdater.client.luau  StageTimer label: counts locally between start/stop from StageTimerUpdate
    TalentDoubleJump.client.luau      Double Jump talent: extra air jumps from the Talent_DoubleJump attribute
    StageResultsPopup.client.luau     results popup after a finish incl. pet XP line (GUI built in code)
    GateDoors.client.luau             door gates of the world stages (S4.0): door solid while locked, ghost when unlocked (local only); the unlock prompt comes from GatePrompts
    HubGateFaces.client.luau          world gate faces in the hub (S4.0): stars earned x / max and challenge coins found x/y of the world on its gate's Portal face; the requirement + price instead while the gate is shut; a `soon` world reads "Coming soon" + its future requirement
    HubGateLocks.client.luau          shut world gates (S4.x): while none of a world's stages is open, a local barrier fills the hub gate (the unlock prompt comes from GatePrompts); a `soon` world's gate stays shut for non-admins; the GateWorld<n> server script also refuses the teleport
    HubPortalMedals.client.luau       own best-medal stars, challenge coins "found x/y" + lock requirement/price on each stage's face (StageConfig.FaceTarget: the Door of its start gate, the hub portal for the Tutorial) (local SurfaceGuis; layout kept inside the arch's opening)
    CameraFacing.client.luau          (skips while a StageCamera mode is active) camera turns to the character's facing after a teleport (> 30 studs in a frame at > 500 studs/s) and on the first spawn; the targets set the facing: `SpawnLocation` looks at the Tutorial / Stage 1 portals, `TeleportDestination` along the course
    CheckpointClient.client.luau      checkpoints for the local player (H2): CheckpointReached(part, first) lights that pad (Core 3 → 7 Neon, PointLight, Beam rises; 1 s) and turns the previous one back, so only the current checkpoint glows; `first` also plays workspace.Handlers.CheckpointTouchHandler.Sound (SoundService copy); CheckpointsReset turns the lit pad back; values in the LOOK table
    ObstacleKit.client.luau           obstacle kit (S3.1 / S3.2a): client-driven parts from CollectionService tags + attributes, no server animation: KitMover (Kind Slide / Lift / Spin / Piston / Swing / Flip (S6.2: flipper plate, not solid while it turns); carries the character standing on it, jump-off air carry, optional Kill / Push), KitBeam (blinking kill beam), KitPlate (disappearing plate), KitTilt (kit-local tilt plate with slide-off), KitCrumble (kit-local crumbling plate), KitSwitch + KitColorPlate (kit-local colour groups), attribute RunSeeded (run time instead of server time); client kill = the local Humanoid.Health = 0; attribute reference in the script header, test stations in the Studio-only `Workspace.KitLab`
    KitZones.client.luau              kit zones (S3.3a): parts tagged KitZone, Kind Wind (Push, gusts; since S6.1 a local ParticleEmitter `WindParticles` of streaks flows along Push, its rate following the gust, attribute `Particles = false` turns it off) / LowGravity (GravityScale) / Updraft (Lift, Accel); act on the local character while inside; test stations in `Workspace.KitLab` row 4
    KitMaze.client.luau               shifting maze walls (S6.2): parts tagged KitMazeWall with Pattern ("1" up / "0" sunk per layout step), Period, Phase, Telegraph (a wall about to rise glows as a floor line, one about to sink flashes), RunSeeded; a rising wall pushes the character out; layouts are generated and checked when a maze is built (Labyrinth, docs/STAGES.md §7.9)
    KitGhosts.client.luau             ghost zones (S3.3b): parts tagged KitGhostZone (attribute Transparency, default 0.65); other players' characters inside one are drawn translucent (LocalTransparencyModifier) where each player sees their own kit-local state
    StageCamera.client.luau           camera modes Iso / Side / Down / Front (S3.2b): zones = parts tagged CameraZone with attribute Mode (+ Yaw / Pitch / Distance / Fov / Lead / Height / Priority overrides) or a stage folder attribute CameraMode while that stage's timer runs; Scriptable camera, blends in / out, snaps behind the character on death / teleport; player attributes CameraMode / CameraZone; test zones in the Studio-only `Workspace.KitLab` row 3
    BounceBricks.client.luau          bounce bricks (tag BounceBrick, attribute LaunchSpeed set by each brick's script): on touch sets the local character's velocity along the brick's LookVector to exactly LaunchSpeed (deterministic; the client owns its character)
    ChallengeCoinsClient.client.luau  hides the local player's collected challenge coins (local Transparency/CanTouch), spins the others, plays the pickup sound
    PortalBarriers.client.luau        invisible local wall in each locked hub portal (removed when Unlocked_<folder> turns true)
    QuickRespawnClient.client.luau    Quick Respawn level 2: fall reset (falling character below its checkpoint plate by the stage's attribute FallResetDepth, default 30, never below the sea + 5 studs, plate within 300 studs → back on the plate; 0 = off) + short fade; mirrors CheckpointReached / CheckpointsReset
    GatePrompts.client.luau           unlocking a shut gate (the unlock popup is gone): a local ProximityPrompt ("Unlock · 500 Coins" / "Needs 500 Coins", hold E) on every shut stage door and on a shut world gate in the hub (it buys the world's first stage); Triggered fires UnlockRemotes.Buy, a short toast reports the Result ("World 1 unlocked!", "Not enough Coins"); the prompt disappears when the gate is open. The requirement is on the gate face
    StageExploreWarning.client.luau   banner "Exploring Stage N without a timer" (ExploreWarning remote from CheckpointTouchHandler): shown for 9 s when a checkpoint of a stage is reached while no timer runs for it, i.e. the player got in around the gate; hidden when a timed run starts
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
      CheckpointTouchHandler.luau     checkpoint touch → respawn point, fires CheckpointReached(part, first) to that player whenever the respawn point changes (`first` = first reach in the run → sound); a TimerStart touch counts as the stage's lowest-numbered checkpoint; NewRun from TimerStart fires CheckpointsReset; fires ExploreWarning(stageKey) on a checkpoint touch without a running timer for that stage (on every touch, not only when the respawn point changes; again after 120 s, cleared by NewRun); dead characters ignored; a respawn is placed on the stored plate facing its LookVector (the course direction)
      PlayerTimerHandler.luau         stage timers (os.clock), personal bests (profile), global Top-10, score panel
    StartLocation/                    hub (central island, part-built since H1, centre (-1126, 16, -475), r 80): SpawnLocation on the plaza + TeleportToTutorial and GateWorld1 (S4.0: Script + 1.25x arch + Portal; teleports to the World 1 island) and GateWorld2..4 (S5: clones of it, `soon` worlds: shut for non-admins) on a circle of radius about 44 round the plaza centre at 90 / 60 / 30 / 0 degrees for Worlds 1 / 2 / 3 / 4 (Tutorial at 142), facing it (the stage portals moved to Workspace.World1) (each: Script, `Portal` = touch trigger + face with the stage-name SurfaceGui, Studio-only `Arch` Model of stud-stone blocks cloned from `ServerStorage.DecorKit.StudPortal`, H1.1) + StarsLeaderboard (Studio-only board model in the wooden stud style, no scripts; StarsBoard.server.luau beside it draws into Model.ScoreBlock.SurfaceGui: DataLabel, Names.NameN, Score.ScoreN, Photos.PhotoN); Studio-only Island folder (Island, IslandRock, Plaza, PlazaRing, Hedge + invisible Barrier ring with an opening toward the garden, BridgePath, GardenSign, Decor). Scripts find the hub by name, never by coordinates
    World1/                           World 1 courtyard (S4.0, Studio-only, rectangle x -430..-320, z 187..357, y 77; see "Courtyard layout" below): `Plaza`, `Rock` underside, low `Wall` (6 high, 3 thick) with the gate openings, `Spawn` pad (hub gate lands here, facing north), `ReturnGate` (Script + Portal + Arch in the south wall: back to the hub), no closed gates any more (`SoonGate1` / `SoonGate3` were replaced by the gates of Island Hop in S4.1 and Blink in S4.2), Decor, the five stage folders `Stage1` … `Stage5` (since 2026-10-22 key = folder = position; see "Stage anatomy"), `StarsLeaderboard` (clone of the hub board, S5) + `WorldStarsBoard.server.luau` (draws `StarBoard.World(n)`; identical copy in every world folder; the board stands right of the return gate, facing into the courtyard), `WorldSign` (S5, Studio-only: "World N" on two posts in front of the Spawn pad). The stages lie physically behind the gates
    World2/                           World 2 courtyard (S5, Studio-only): `Workspace.World1` cloned 263 studs south (z 450..620) and rotated 180 degrees about its centre (entrance + `ReturnGate` on the north side, the finale gate will be on the south side, courses run away from World 1); same children as World1 (Plaza, Rock, Wall, Spawn, ReturnGate, Decor, StarsLeaderboard, WorldSign, WorldStarsBoard); Stage6 / Stage7 (S6.1) stand in the east wall gates, Stage8 / Stage9 (S6.2) stand in the west gates, stage 10 follows with S6.3 (its opening carries the closed `SoonGate10` door, Studio-only), two bonus-portal slots stay free beside the return gate (S11)
    World1/Stage1 … Stage5 (the stage folders of World 1; the Tutorial's folder stays `Workspace/Tutorial`). Names = positions since 2026-10-22 (they were IslandHop / Stage1 / Blink / Stage2 / Stage3 before): Stage1 (Island Hop, west near gate): Studio-only `Pillars` (stud-textured columns from the sea), `Conveyors` (tag KitConveyor), `Movers` (one run-seeded Mover_Slide), `ChallengeCoins`, checkpoints `101`-`105`; Stage2 (the variety stage, west far gate), checkpoints `1`-`9`; Stage3 (Blink, east near gate): `Pillars`, `Plates` (kit plates), `Beams`, `Pistons`, `ChallengeCoins`, the `Music` Sound, checkpoints `201`-`206`; Stage4 (bounce corridors, east far gate), checkpoints `10`-`14`; Stage5 (the precision finale, north gate), checkpoints `20`-`22` (+ `level.2/26`)
    World2/Stage6, Stage7 (S6.1, Studio-only content): Stage6 (Double Up, east near gate z 505) `Pillars`, `Movers` (a lift, two run-seeded sliders), `ChallengeCoins`, checkpoints `401`-`406`; Stage7 (Seesaw, east far gate z 565) `Pillars`, `Plates` (kit tilt / crumble plates), `Zones` (wind), `ChallengeCoins`, checkpoints `501`-`506`; script files copied from Blink's (docs/STAGES.md §7.9)
    World2/Stage8 (S6.2, Studio-only content): Turntable, west near gate z 505, course west: `Pillars` (columns, pads, axles), `Movers` (turntables, sweeper bars, flippers, flat windmills, crumbling plates; all run-seeded), `ChallengeCoins`, checkpoints `601`-`606`; gate / board / `Arrival` / finish / checkpoints are Stage 6's rotated 180 degrees about (-375, 505), script files copied from Stage6's
    World2/Stage9 (S6.2, Studio-only content): Labyrinth, west far gate z 565, course west: `Pillars`, `Maze.Small` / `Maze.Big` (floor, static `Wall_` / shifting `Shift_` (KitMazeWall) / `Hedge_` / `Outer_` walls, invisible `_Ceiling`), `Zones` (Iso CameraZone + KitGhostZone per maze), `ChallengeCoins`, checkpoints `701`-`704`; gate etc. are Stage 7's rotated 180 degrees about (-375, 565)
    <Stage>/ChallengeCoins            Studio-only Folder (every stage): Coin_<n> MeshParts tagged ChallengeCoin with attribute CoinId (ids listed in `ChallengeCoinConfig`)
    DebugBaseplate/                   kill brick under the map = the sea (H1: centre (-350, -8, -100), top y 0, covers every stage, the hub and the garden; sea blue Glacier + Texture)
    LaneDividers (Studio-only Folder)  semi-transparent glass panes (S4 tuning) at z 263.5 between the lanes of Island Hop / Stage 2 (West, x -1040..-432, y 2..170) and Blink / Stage 4 (East, x -318..215), each with a WallTop pane over the courtyard wall (y 84..170) so the wall top cannot be walked from one lane to the other; `World2West` (+ `World2West_WallTop`, S6.2) at z 523.5 between Stage 8 and Stage 9 (x -1000..-431.5); collidable, no touch; a divider must also separate any future lanes that lie within a Double Jump + Run Speed reach (about 21 studs)
    Sea (Studio-only Folder)          Tile_1..8: cosmetic sea around DebugBaseplate out to the horizon (no scripts, CanCollide / CanTouch / CanQuery off)
    GardenBridge (Studio-only Folder) wooden bridge hub <-> garden at 75° from the garden centre: Deck, Rails, Supports, invisible Barrier walls (top y 16 like both islands)
    Garden/                           Studio-only pet garden island at x -1200, z -750: Island, Plaza, Hedge + invisible Barrier ring (opening at 75° for the bridge: *_GateL / *_GateR), BridgePath, HubSign, Decor, Plots/Plot_01..12 (Floor 40x40, Edge_*, Sign with SurfaceGui "Gui" > "Label", Pen_1..6 with Pad + Prompt + Info billboard, Incubator_1..3 with Base (PrimaryPart) + Prompt + Info billboard (Adornee = Egg, label above the egg), Nest, Egg ball + PointLight), FoodStand (Model on the plaza, PrimaryPart Counter with Prompt); GardenService adds PenPets folders
```

### Stage anatomy
**World stages** (`Workspace.World1.Stage1` … `Stage5`; since S4.0 the `LandingPad` object is gone) follow this pattern:

| Child | Script behaviour |
|---|---|
| `Gate` (Model) | the door gate in the courtyard wall: Studio-only pillars, beams, `Sign` (`Sign.Gui.Title`), `Door`, plus the scripted children below; the course starts directly behind it (no teleport into a stage) |
| `Gate/TimerStart` | starts the timer unless one already runs on this stage (refused unless `StageUnlocks.IsUnlocked`, shows the stage on the score panel) + acts as checkpoint; an invisible 21 x 16 x 4 trigger exactly in the doorway between the pillars (floor to 16 studs; it used to be 48 x 30 x 4 and started runs for players walking beside the gate or on the wall top; the Tutorial's `LandingPad/TimerStart` and the `StageKit.Gate` template have the same size); touching it counts as reaching the stage's first checkpoint (`CheckpointTouchHandler`, H2), so the respawn point is that plate |
| `Gate/Door` | Studio-only wooden door between the pillars; `GateDoors.client` makes it solid while the stage is locked for the local player (`GatePrompts` puts the unlock prompt on it), a faint ghost once unlocked; `HubPortalMedals` draws stars / coins / lock lines on its Back face (white text closed, black open) |
| `Gate/GateExit` | invisible trigger just outside the door on the courtyard side; walking back out cancels the running timer (panel -> world) |
| `Gate/GateSign` | script: writes the `StageConfig` display name on `Gate.Sign.Gui.Title` |
| `Top10Leaderboard` | Model standing in the courtyard in the outer wall segment beside the gate (user-placed: about 14-29 studs from the gate centre along the wall), parallel to the wall, facing into the courtyard, about 6 studs off it: SurfaceGui board from `LoadGlobalLeaderboard(stage.key)`; its Studio-only `Model` is a clone of `StartLocation.StarsLeaderboard.Model` (wooden frame, same `ScoreBlock.SurfaceGui` names) |
| `Arrival` | Studio-only Part on the courtyard in front of the gate, facing it: where finish and Home land (`StageConfig.ReturnSpawn`) |
| `<number>/C` | checkpoint (`1`-`9` Stage2, `10`-`14` Stage4, `20`-`22` Stage5, `23`-`25` Tutorial, `101`-`105` Stage1, `201`-`206` Stage3, `401`-`406` Stage6, `501`-`506` Stage7, `601`-`606` Stage8, `701`-`704` Stage9: the numbers stayed when the stages were renamed; a new stage takes the next free block of 100): `C` is the whole 16 x 1 x 12 cream stud plate (touch trigger + Script, respawn point); Studio-only `Core` / `Beam` animated per player by `CheckpointClient`. The plate's upstream edge touches the previous obstacle |
| `TeleportBackToStageStart/Portal` | finish line: `StopTimer` -> save best time; sibling script teleports to the stage's `Arrival`. Looks like the hub portals (S4 restyle, 2026-10-22): a 7.1 x 10 x 1.5 blue translucent portal labelled "Finish" inside a stud-stone `Arch` model (a clone of `World1.ReturnGate.Arch`, 15 wide); the old black frame parts and the cyan portal are gone from all six stages (Tutorial too). A new stage clones the finish model of an existing stage (visuals) and copies its script folders. **Orientation:** the portal's label is on its Back face, so the portal's `LookVector` must point along the direction the player arrives (last checkpoint -> portal), i.e. the Back face looks at the approaching player; after cloning or rotating a course check `portal.CFrame.LookVector:Dot(approach) > 0` (the Tutorial, Stage4 and Stage5 portals had to be turned by 180° on 2026-10-22) |
| obstacle models | kill parts, spinners (kit), lava, bounce bricks, choice stage |

**The Tutorial** (hub stage, world 0) keeps its old-style `LandingPad` (floor, decor, `StartGate`, `TimerStart`, `TeleportToSpawn` portal back to the hub, `TeleportDestination` = arrival from the hub portal and after a finish, `GateSign`, `Top10Leaderboard`) until it is redone.

**Courtyard layout** (World 1, `Workspace.World1`): a rectangle x -430..-320 (110 wide), z 187..357 (170 long) at y 77. The entrance (return portal to the hub, hub gate lands on `Spawn`) is in the south short wall; the far (north) short wall holds the gate of the finale (Stage 3, course runs north); two gates on each long side, near (z 302) and far (z 242): west wall = slots 1 and 2 (`Stage1` Island Hop, `Stage2`; courses run west), east wall = slots 3 and 4 (`Stage3` Blink, `Stage4`; courses run east). A course is placed by rotating / translating its whole stage folder (`CFrame` of every part) about its gate.

**Kit obstacles:** `ServerStorage.StageKit.Obstacles` (Studio-only, S3.3b) holds one preconfigured template per kit component (movers, hazards, plates, switches, zones, camera zones, ghost zone, run-seeded samples; `Hazard_PendulumRig` is a model with its frame): clone, `PivotTo` the spot, adjust attributes (listed in the header of `ObstacleKit.client.luau` / `KitZones` / `StageCamera`). The tags and attributes come with the clone.

**Adding a world stage:** clone the Studio-only templates `ServerStorage.StageKit.Gate` (door gate with its scripts), `StageKit.Top10Leaderboard` and `StageKit.Arrival` into the new stage folder, `PivotTo` / rotate them as a group onto a free gate position of the courtyard wall (the templates are laid out for a course running north from the gate line at z 187; the first checkpoint plate sits 7 studs behind the gate line), then add the `StageConfig` entry. Checkpoints: clone `ServerStorage.StageKit.Checkpoint` (plate + `Core` + `Beam` + the C Script; pivot = centre of the plate's top), rename it to the next free number and put its upstream edge against the previous obstacle, its front (LookVector, -Z) pointing along the course (the respawn faces that way). Scripts resolve the stage from the folder, so nothing else needs editing;
**Argon does not write the script files of instances created through the Studio MCP** (clones, `execute_luau`; changes to a synced script's `Source` made that way do not reach the disk either). For a new stage, copy the script directories from an existing stage on disk (`Gate`, `Top10Leaderboard`, `TeleportBackToStageStart`, one `<number>` per checkpoint; a plain directory is a Folder, the `init.meta.json` files hold the class), keep the old Studio folder, let Argon create the bare scripted instances from the copied files, then move the Studio-only children and the scripted parts' properties from the old folder into them (match by name; **children with duplicate names, like the three `Step` parts of a ChoiceStage, must be moved without matching** — a name match overwrites the first one), check that the descendant counts agree, and only then delete the old directories on disk (S4.1, S4.2 and the 2026-10-22 renaming did this). The templates' scripts are copies: when a stage script changes, change the template's copy too.

Stage scripts never hard-code a stage: they call `StageConfig.ForInstance(script)` (stage = the Workspace folder they
live in) or `StageConfig.ByHubPortal[...]`, so all copies of TimerStart, finish portal, TeleportToSpawn, hub portal and
Top10Leaderboard are byte-identical. Stage keys (`"Stage1"`…`"Stage5"`, `"Tutorial"`; equal to the stage's `folder` and position) are DataStore keys
and must never change. Hub label is `StageConfig.HubName` (`"Central Island"`).

## Reusable script variants (copy-pasted, not modules)

Most of the 119 scripts are identical copies. Edit them consistently (grep by content or md5):

| Count | Variant | Example |
|---|---|---|
| 31 | checkpoint → `CheckpointTouchHandler.OnTouched` | `Workspace/World1/Stage2/1/C/Script.server.luau` |
| 16 | kill on touch (`Humanoid.Health = 0`) | `Workspace/World1/Stage5/Part_01/Script.server.luau` |
| 8 | kill player on touch (debounced by `hit`) | `Workspace/World1/Stage2/LaserStripStage/Part_01/…` |
| 0 | ~~spinner~~: since S3.3c the Stage 2 spinners (`Workspace/World1/Stage2/SpinnerStage_1` / `_2`) are kit parts: attributes `Kind = Spin`, `Speed = 60` (the old 2° per `wait()`), `Kill` on the two sweeper bars, `Carry = false` on the two spinning plates, tag `KitMover`, no scripts (the folders only hold `init.meta.json`; the hub pillars `Part_4/5`, `_2: Part_2/6` no longer rotate, their rotation was invisible) | – |
| 7 | `TimerStart` (5 world stages, the Tutorial, the kit template) | `Workspace/Stage*/Gate/TimerStart/…`, `Workspace/Tutorial/LandingPad/TimerStart/…` |
| 1 | `TeleportToSpawn` (Tutorial only since S4.0) | `Workspace/Tutorial/LandingPad/TeleportToSpawn/…` |
| 6 | `GateExit` (5 stages + the kit template) | `Workspace/Stage*/Gate/GateExit/…` |
| 6+6 | finish portal / teleport back to stage start (Stage1 teleport copy differs slightly) | `Workspace/Stage*/TeleportBackToStageStart/…` |
| 1 | hub portal `TeleportToTutorial` (the stage portals are gone since S4.0: the stages open through door gates) | `Workspace/StartLocation/TeleportToTutorial/…` |
| 4 | world gate `GateWorld1`..`4` (find their world by the model name; refuse while the island folder is missing) | `Workspace/StartLocation/GateWorld*/Script.server.luau` |
| 2 | `WorldStarsBoard` (world found by the folder name) | `Workspace/World*/WorldStarsBoard.server.luau` |
| 4 | Top10Leaderboard | `Workspace/World1/Stage2/Top10Leaderboard/Script…` |
| 6 | `GateSign` | `Workspace/Stage*/Gate/GateSign.server.luau` |
| 3 | ChoiceStage random safe `Step` | `Workspace/World1/Stage2/ChoiceStage_*/Script…` |
| 3 | bounce brick: declares `LAUNCH_SPEED` (attribute `LaunchSpeed` + tag `BounceBrick`; the launch is done by `BounceBricks.client`) — all 300 since the user's tuning (2026-10-21); `Bounce Brick_1`–`_3` are siblings | `Workspace/World1/Stage4/12/Level 12/Bounce Brick_*` |

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
| `UnlockRemotes.Buy` / `.Result` / `.Locked` | client → server `(stageKey)` / server → client `(stageKey, ok, reason?)` / server → client `(stageKey)` | created at runtime by `StageUnlocks`; price from `StageConfig.unlockPrice`; `Locked` is unused since the unlock popup was replaced by gate prompts (S4 tuning) |
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
- `Workspace.World1.Stage4` carries the Studio-only attribute `FallResetDepth = 70` (QuickRespawnClient's default is 30): the bounce bricks of Level 12 lie 46-61 studs below the plates, a smaller depth resets the player before they reach them. Set the attribute on a stage folder whenever a course has a catch or bounce surface far below its plates.
- Studio playtests with API access read/write the **live** DataStores — snapshot and restore anything a test changes.
- `CheckpointTouchHandler`'s `Sound`/`Orig` children exist only in Studio (`CheckpointClient` clones `Sound` on the client).
- Checkpoint `Core` / `Beam` are authored in the "not reached" look; `CheckpointClient` reads that look once per pad and tweens to and
  from it, so restyle them in Studio in that state.
- Argon does not turn an existing plain Studio instance into a synced folder when a script file is added under it
  (it made a second empty `HomePanel`). Renaming such a folder on disk replaces the Studio instance with a bare Frame (styled
  children lost, rebuilt by hand). After adding/renaming script containers, check Studio for duplicates / lost children.
- **Moving a script container on disk recreates its Studio instance, drops its Studio-only children and also deletes a copy of the scripted part that was stashed elsewhere in Studio** (Argon tracks the instance, not the path): stash only Studio-only parts (they survive) and note the scripted parts' properties first.
- **Moving a script container on disk recreates its Studio instance and drops its Studio-only children** (S4.0: `git mv` of
  `TeleportToStage1..3` into `World1/` deleted their `Arch` / `Portal`; rebuilt from the Tutorial portal). Reparent in Studio,
  keep a copy of the Studio-only children, and rebuild after the disk move.
- `Workspace/World1/Stage5/level.2` is a Model literally named `level.2` (dot in the name). Its checkpoint `level.2/26` (the plate between the four jump plates of `level.1` and the wrap-around floor, 11 studs from the last plate) was renamed from `21` on disk in S1.1; Argon recreated it as a default part at the origin and the 23-stud gap made Stage 5 impossible until it was rebuilt on 2026-10-22 (plate 16 x 1 x 12 at z 80.1, the Core / Beam copied from `Stage5/21`). Never rename a checkpoint folder on disk without redoing its Studio parts.
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
- The Tutorial keeps its old-style `LandingPad` (floor, `StartGate`, `TimerStart`, return portal); the world stages have no landing pad since S4.0.
- **ChoiceStage duplicates when moving scene parts:** the three `Step` parts of a ChoiceStage share one name; code that matches children by name (the "graft" of Studio-only parts into freshly synced script containers) overwrites the first one with the second. Move such children without matching.
- Legacy APIs are common (`wait`, `spawn`, `:connect`, `findFirstChild`); prefer `task.*` and
  `Players:GetPlayerFromCharacter` in new code, but don't mass-rewrite without asking.

## Testing
No automated tests. Verify in Studio: playtest (MCP `start_stop_play`), read `get_console_output`,
and check DataStore behaviour only with Studio API access enabled.
MCP `screen_capture` with a camera position leaves the Edit camera on `Scriptable`: when done, set it back with
`workspace.CurrentCamera.CameraType = Enum.CameraType.Fixed` (Edit) so the user can move the viewport again.

Multi-client: the user starts Test → Start Test Session → **Server and Clients** (F7), then Test → **Add Clients**.
Studio MCP habits that cost time: `screen_capture` sometimes times out and the viewport then stays white until Studio is restarted (the data is still right: check geometry with `execute_luau`); do not leave a playtest running (`start_stop_play` false at the end of every test, `Edit` calls fail in Play mode); a `MoveTo` bot cannot walk on a kit mover (use `Humanoid:Move`); teleporting a character into a coin or trigger is flaky (walk onto it); a character may not be loaded right after `start_stop_play` (wait for `HumanoidRootPart`). Snapshot and restore recipe for the live DataStores: copy `PlayerProfiles` `user_<id>` into `TestSnapshots` (`profile_<id>`, plus the `MostStars` value) before a test, write it back after the playtest has stopped (the profile is saved again on shutdown), and remove the test's entries from `GlobalLeaderboardsStore`. Accounts: `Lekzdrh` (9892673032, the developer in Studio) and `AhojRupert` (769364524, another admin account).
`list_roblox_studios` then shows one extra instance per client and one for the server (unnamed);
`get_studio_state` tells them apart by the focused DataModel. Test users have UserIds −1, −2… and create
`PlayerProfiles` records `user_-1`, `user_-2` — remove them afterwards.
