# Pawvest — store thumbnails (TH)

*Status: release candidates A1, A2, A3, C1, C2, C3 and the logo are built (§9); B1 is built but parked until D1; nothing uploaded yet.
Open: the stud sign decision, the grid tile test and the kid test (§8). Milestone row: ROADMAP → TH.*

## 1. Goal
A store page that makes the right players click and then stay (qualified play-through, §2), that shows what only Pawvest has
(EXPANSION §1.1), and that lets Roblox pick the winner by data instead of us guessing. **Three clearly different themes with
three variants each** (9 thumbnails, §4) plus a logo and an icon, in two passes (§8), tested in rounds (§6).

## 2. How Roblox tests thumbnails
- **Where:** Creator Dashboard → the experience → **Thumbnails**, tabs *Home Page* and *Experience Detail Page*. Upload any
  number; mark **2–5 as active** (with one active, everybody sees it).
- **Thumbnail personalization:** a multi-armed bandit, not a fixed A/B split. Each active thumbnail first goes to random players;
  then the one with the better **qualified play-through rate** per player group gets most impressions. Different groups can end
  up with different winners.
- **Staff advice:** up to five active; make them differ in gameplay, characters, environment or the **player motivation**
  each targets (look-alikes teach nothing); test new ones with every major update; wait **at least 7 days** before changing the
  set; one visual theme across thumbnails and icon; no clickbait.
- **Not testable:** the icon (512×512) and the title. Workaround: an icon-style image among the thumbnails.
- **Format:** 16:9, 1920×1080. Content must be what the game really shows (moderation rejects misleading images).
- Sources: [Thumbnails (Creator Hub docs)](https://create.roblox.com/docs/production/publishing/thumbnails); re-check the dashboard UI when uploading.

## 3. Rules for every frame
- **Lead with what is ours** (EXPANSION §1.1): the obby, pets as characters on guard, critters at the fence. Planting and
  harvesting are the frame, not the hook. The one harvest-led shot (C2) keeps a pet in the frame (user decision).
- **Real content only:** every piece exists in the game as players see it (stage parts, pets with their real looks, crops at a
  real growth stage and a real size). Composition, light and camera are free.
- **Phone first:** the home tile is thumb-sized. **One subject, one face toward the camera, one idea**; at most two pets; strong
  silhouette, saturated stud colours. Every draft passes the **tile test** (§8) before it is finished.
- **One motivation per thumbnail** (§2): each variant names the player it is for (§5).
- **Wordless except the logo.** No taglines, no numbers, **no stage count**: players abroad do not read English and Roblox
  prints the title under the tile anyway.
- **The logo carries the name** (§4 Logo): placed in the same corner of every thumbnail; the icon uses the pawprint mark alone.
  The stud sign in C1 is the only in-scene name.
- **One look across the set:** the same avatar with its face visible, the same logo corner, the same palette.

## 4. Themes and variants
Variants inside a theme differ in subject, camera or place, not only in colour. Pets are at a level their kind reaches: the
rarity caps every trait, so the pet level too (`PetConfig.AptitudeCap`: Cat / Dog 12, Bunny / Fox 14, Owl / Panda 16, Dragon 18,
Phoenix 20; look tier 4 and its halo only on a Phoenix); uids are picked for the best accessory roll (no crown on a thumbnail pet).

### A — Action: "Run it, grow it" (for obby players)
The player in motion with one pet; saturated, fast, tilted camera.
| # | Subject | Camera / light | Pieces |
|---|---|---|---|
| A1 | One jump over World 3 lava (Rising Tide) with a Dragon trailing; the garden as **one glowing island** behind (no split frame) | low, from the side of the jump; lava glow in front, golden island behind | Stage 15 section, posed rig, Dragon, garden backdrop |
| A2 | Laser Lab **side-on** (the stage's own 2D view): the player mid-leap, a pet trailing; neon on dark looks like nothing else on the page | side view, player large; the lab at night (by day it is a light sand-blue room), neon | Stage 14 section, rig, pet |
| A3 | The player landing on a stud checkpoint, **facing the camera**, with the Phoenix; a challenge coin beside them (taking one has no burst: it vanishes); the course behind them | high, ahead of the pad, looking back along the course; bright day | checkpoint, challenge coin, course section, rig, Phoenix |

### B — Characters: "Pets on guard" (for pet lovers and defence players)
Calm and cosy, eye contact with the pet; the defence angle no other garden game has.
| # | Subject | Camera / light | Pieces |
|---|---|---|---|
| B1 | One big guard pet on its square, its reach ring glowing over ripe crops, one big Pumpkin beside it. **With D1:** two or three crows landing on the fence | at fence height, pet in the foreground; late afternoon | plot, field squares, reach ring, pet, Pumpkin (crows later) |
| B2 | Stare-down: one guard pet (Fox with its scarf) face to face with a single crow on the fence, ripe crops soft behind. **Needs D1** | macro-close, shallow depth (DepthOfField); warm | Fox, crow, fence, crops |
| B3 | Wide plot at sunset: hatchery with a glowing egg on the left, barn on the right, pets resting among ripe Giant Melons and Sunflowers. **Experience Detail Page only** (no focal point at tile size) | high three-quarter view; sunset | plot, egg, pets, ripe crops |

**Crows:** crows are a forecast and a settle roll with no bird in the world yet, so a crow in a frame would break "real content
only". B2 and B1's crows launch with drop D1 (Critters), which also refreshes the thumbnails (§2).
**B1 is parked until D1 (user decision).** Crow-free, the guard idea rests on the yellow reach tint, which only a player who has
placed a field pet understands; a viewer sees a lit patch. The whole theme B waits for visible pests; the crow-free B1 stays
buildable (§9).

### C — Harvest: "Paw + Harvest" (for farming players and collectors)
The payoff: pets and what they grow. The most readable theme at phone size.
| # | Subject | Camera / light | Pieces |
|---|---|---|---|
| C1 | A pet pulling a glowing Golden Carrot out of the soil, **pet and carrot filling most of the frame**; the stud-built PAWVEST sign small behind | frontal, close; clean sky | pet, Golden Carrot (pulled pose), soil, sign |
| C2 | **Giant harvest:** a Giant Melon as big as the player, a pet sitting on top, the player beside it cheering | very low and close, so the melon towers; bright day | Giant Melon at the largest real size, pet, rig |
| C3 | Collection: three or four pets growing in size from a Cat to a glowing Phoenix, a crop beside each (pets do not hold crops in the game) | frontal, Phoenix dominant; bright day | 3–4 pets, crops |

**C2's size is real:** the melon is built at the upper bound of `CropConfig.SizeBounds()` (the drawn size grows with the cube
root, `PlantKit.dimension`); the camera does the rest. Never scale a crop past that bound.

**Icon (512×512):** the C1 pet (Bunny uid 4) with its Golden Carrot, a logo in a corner; C1 cropped square (§9). The icon is not
testable (§2); C1 doubles as the "icon-style" thumbnail.

### Logo
- **Idea (user decision):** the word **HARVEST** with **HAR** crossed out and **PAW** written over it, tilted like a correction,
  in the pet colour (orange); VEST stays harvest gold, the struck HAR is a dimmed gold. The edit shows the wordplay without a sentence.
- **Cross-out (user decision): torn claw cuts.** Three claw marks tear through HAR so the background shows through, as if a pet
  clawed it out. Each mark is a sickle (sharp at both ends, thickest past the middle, slightly curved, ragged edges), steep at
  **74°**, staggered (the middle one longest and lowest), with a thin rim. Not a pawprint stamp over HAR (loses its shape when small).
- **Dark frames:** the cuts show the background, so the rim must contrast with what lies under the logo: dark brown on light frames, cream
  on dark ones. **Check the cuts on every final image**; a busy frame may need a backing plate behind the wordmark.
- **Style:** chunky rounded font (Lilita One, OFL: free for commercial use), thick dark-brown outline. Open: whether C1's in-scene sign uses
  the same lettering (stud bricks or a decal) or is left out.
- **Deliverables:** the wordmark and the **pawprint mark** alone (icon, small sizes), transparent PNG, light-outline and
  dark-outline versions (built: §9 Logo).
- **Tile-size risk:** at a thumbnail corner PAW + VEST must read as one word; the struck HAR may blur into a smudge (acceptable).
- **Where:** the same corner of every thumbnail, the mark on the icon, C1's sign. Later candidates (not TH): hub sign, loading screen.

## 5. Review of the variants (judgment, not data)
Who each pulls in and the expectation: B2 pet lovers, the strongest idea, waits for D1 · A3 obby players, strong (one subject facing the
camera, the course behind) · C1 farming and pet players, strong, also the icon's source · C2 farming players (the biggest audience in the
genre), strong, watch the "another garden game" read (§3) · C3 collectors, medium (reads with 3–4 pets; eight were specks) · A1 obby and
farming players, medium · A2 obby players, medium, the most distinctive look (high contrast, face in profile) · B1 pet and defence players,
parked until D1 (the reach tint is not understood without pests) · B3 cosy and farming players, Detail Page only (no focal point).

## 6. Test plan
- **Home Page tab** takes the single-subject thumbnails; **Experience Detail Page tab** takes the story shots: B3 plus wide views
  made from the same sets (the full field, the hub), in the order obby → pets → garden.
- **Round 1 (≥ 7 days):** A3 and C1 (theme B waits for D1). It answers the biggest question first: which theme, i.e. which
  player, the game attracts.
- **Round 2 (≥ 7 days):** add pass 2's variants up to five active, the winning theme's first; drop a clear loser.
- **With D1:** B2 and B1 with crows replace the weakest active ones.
- **Keep** the top 2–3 active between updates; test new ones against them with every big update.
- **Read:** the Thumbnails page's per-thumbnail impressions and qualified play-through; compare with T1a / T1b retention
  (TELEMETRY.md) so a thumbnail that clicks but disappoints is caught. A dip in play-through right after a home-page surge is normal.
- Testing needs real traffic: it starts with the public launch (or a soft launch with enough impressions to mean something).

## 7. Build approach
- **Studio-only photo sets:** `ServerStorage.PhotoSet.<A|B|C><n>` (A1…C3, Icon). No scripts, so Argon never syncs them (a rig's
  `Animate` LocalScript once did: `Rig.build` deletes scripts; `$keepUnknowns` keeps the rest). A set is moved into Workspace only
  while shooting and back right after, so nothing shows in play. Pieces are cloned per set (variants never share instances).
  Built and edited through MCP `execute_luau` in Edit.
- **Pets:** clone `ReplicatedStorage.PetModels[kind]`, dress it with `PetLook.Apply(model, kind, level, uid)` (a pure function of
  kind / level / uid), pose by CFrame (and `PetLook.UpdateFx` once for tier effects). Search uids for the wanted accessories with
  `PetLook.AccessoriesOf(kind, level, PetLook.Seed(uid))`.
- **Crops:** `<CropId>Plant.new(parent, soilCFrame, seed, sizeFactor)` from the recipe modules (`PlantKit.recipe`), then
  `:SetGrowth(1)` for ripe (or a stage for C1's pulled carrot); the set keeps the Parts (no update loop). Pick the seed per crop
  for the best silhouette; size factors stay inside `CropConfig.SizeBounds()`. Plant parts have CanQuery off: use segment-box
  tests, not raycasts, to check what covers a face.
- **Scene reuse:** the real garden plot and its reach ring (`PlotView`, drawn at full detail, labels removed), stage parts in
  place (shoot in the stage itself, add only rig and pet), `ServerStorage.DecorKit` decor with the placement rules (AGENTS.md
  Gotchas), the stud sign from StudStyle bricks. Edit draws no plots on its own (PlotView runs on clients): the builders call it.
- **Player:** one posed R15 rig for the whole set, built from free Roblox catalog items (user decision: a purpose-made avatar,
  not an account's), face visible and expressive; `tools/photoset_rig.luau`.
- **Logo:** vector master rendered to PNG, composited onto the finals (§9).
- **Light:** a per-set Lighting preset (time of day, Atmosphere, ColorCorrection, Bloom, DepthOfField) applied by script;
  **snapshot Lighting and its children before and restore after** every session. Particles, Bloom and DepthOfField do not render
  in Edit captures (a Play capture shows particles and Bloom; stud textures render worse there).
- **Capture:** drafts by MCP `screen_capture` with a camera CFrame, one at a time (AGENTS.md → Studio MCP habits; set
  `CameraType = Fixed` afterwards; restore a minimised window). Finals at 1920×1080 from a maximised Studio viewport with the UI
  hidden (`thumb_art.ps1 grab`, §9). Finals are stored under `docs/art/thumbnails/` (JPG), drafts under `drafts/`.

## 8. Milestones
Two passes: two thumbnails first (A3, C1; theme B waits for D1), the others only after they have been seen at tile size and by a kid.
| # | Content | State |
|---|---|---|
| TH0 | Shared pieces: the posed rig, pets with chosen uids, the ripe crop set, the logo and the stud sign in the same lettering, the Lighting snapshot / preset helper | rig, logo, lighting helper done; stud sign open |
| TH1 | Pass 1: A3, C1 and the icon. Each draft passes the **tile test** (shrunk to tile size in a grid of real competitor thumbnails) and the **kid test** (which one would the playtester tap, and what does he think the game is) before finals | release candidates; grid tile test and kid test open |
| THU | Upload; round 1 active (the user on the dashboard) | – |
| TH2 | Pass 2, shaped by TH1's lessons: A1, A2, C2, C3; B3 and the wide views for the Detail Page | A1, A2, C2, C3 release candidates; B3 and wide views not built |
| THR | Round 2 after ≥ 7 days; keep the top 2–3 | – |
| THD | With drop D1 (Critters): B2 and B1 with crows (or other visible pests) | – |

## 9. As built
Each set builder's defaults rebuild its release candidate; the header comment of every tool says how to run it.

**Tools** (`tools/`, run through MCP `execute_luau` in Edit):
- `photoset_lighting.luau`: `snapshot` / `apply` (per-set presets `C1`, `A3`, `B1`, `C2`, `A1`, `A2`) / `restore` / `status`. The
  snapshot lives in `ServerStorage.PhotoSet.LightingSnapshot` and refuses to be overwritten, so a forgotten restore never loses the real look.
- `photoset_rig.luau`: the player rig, a library the set builders load from `ServerStorage.PhotoSet.Builder_Rig`: `build` and `pose`
  (named poses `stand` / `cheer` / `leap` / `dash`, `mirror` flips one; forward kinematics, feet set on a given floor).
- `photoset_<a1|a2|a3|b1|c1|c2|c3>.luau`: builds `Workspace.PhotoSet_<X>` and returns the camera for `screen_capture`; `stash` /
  `shoot` move it to and from `ServerStorage.PhotoSet.<X>`. For iterating, the source sits in the StringValue
  `ServerStorage.PhotoSet.Builder_<X>` and runs through `loadstring` with a parameter table (re-store the file after editing).
  While a set is in Workspace the Studio GUI is hidden (`ShowDevelopmentGui`). Builders refuse a pet level above its kind's cap
  and a crop past `SizeBounds()`. Set-space +X is camera-left in B1. A2 / A1 hide scene folders while shooting (`HIDE`,
  `LocalTransparencyModifier`, reset by `stash`).
- `thumb_art.ps1` (PowerShell, Windows: headless Edge + System.Drawing): `render` (logo PNGs from `docs/art/logo/logo.html`),
  `grab` (a full-resolution 16:9 frame from Studio's viewport; `-Rect "x,y,w,h" -Aspect 1:1` for squares), `compose` (a logo onto
  a frame, `-Corner`), `tiles` (320 / 200 / 150 px sheet).

**Capturing finals.** `screen_capture` returns a downscaled image, so finals come from `thumb_art.ps1 grab` right after
`build` / `shoot` (they leave the set's camera on, `Scriptable`); PrintWindow captures Studio without bringing it to the front.
The viewport rect depends on screen scale and panel layout (maximised Studio, 3840×2160 at 150 %: 2237×1520 px at 726, 323; the
16:9 band keeps the view-cube gizmo out; squares `-Rect "726,323,<w>,1360"` with the 1:1 aspect: at height 1360 or more the
gizmo's "Y" can show at the bottom edge). Re-read the rect after moving panels. **Stale grabs:** Studio's Edit camera can fall
back to `Fixed` and an earlier view between `build` and the grab; builders' `setCamera` also sets `Camera.Focus`, and before a
final read `CameraType` / `LookVector` back right before the grab.

**Files** in `docs/art/thumbnails/`, per variant X: `x.jpg` (1920×1080 with the logo: the upload), `x-clean.jpg` (no logo),
`x-square.jpg` (512×512 store square, wordmark), `x-square-mark.jpg` (pawprint mark at 20 %), `x-square-clean.jpg` (≈1360×1360
master, no logo). All six variants and the icon (C1's square) follow this. Finals are scaled from the ~1968×1107 grab.

**Logo.** `docs/art/logo/logo.html` is the master (SVG drawn by script in Lilita One; the font file and its OFL licence sit next to
it): HARVEST with HAR dimmed gold, VEST gold, PAW orange tilted 10°, outline dark brown; three seeded sickle cuts at 74° are real
holes through HAR with a 4-unit rim that also traces them past the letters. `render` writes `pawvest-logo-light.png` (dark-brown
rims), `pawvest-logo-dark.png` (cream rims) and `pawvest-mark.png` (pawprint), transparent and trimmed, ~3000 px wide. Wordmark size
30 % of the frame width (40 % covered C1's pet face); the 512 squares use 40–60 % depending on free sky. Tile test: PAW and VEST read
at 150 px, the struck HAR becomes a smudge (accepted).

**Player rig.** Look `updo` (`Rig.LOOK`): Lavender Updo (asset 451220849), skin 204/142/105, orange torso, navy legs, no clothing;
look `classic` (Roblox's default avatar: Pal Hair 63690008, shirt 144076358, jeans 144076760, light stone grey skin) added for C2.
Edit-mode facts the library handles: the default head is a **dynamic head** (classic face decals are ignored), so the grin is set
on its `FaceControls`; the joints are `AnimationConstraint`s, so parts are anchored and placed by forward kinematics; some
accessories come unwelded, so each is seated on its matching body attachment. Check catalog ids with
`MarketplaceService:GetProductInfo` (Creator Store search does not cover the catalog).

**C1 (icon source).** **Bunny uid 4 at Lv 19** (Scarf + Wings; Lv 19 is the last tier-3 level: no halo, which every Lv 20 pet wears; a
Bunny's real cap is Lv 14, so C1 is above what a player can own: **user decision, keep it**; later sets stay within the cap). Crown-free
max-level uids: Bunny / Cat / Fox 4, Panda 2, Dog 2. The Bunny beat the Panda (its carrot clears the body and reads as a carrot). Stands on
**slot 1's real plot** (`PLOT_SLOT = 1`) in square 32 (left empty), ripe crops around from `CROPS` (no pineapples: gold competes with the
carrot), barn behind; morning light (preset C1, ClockTime 9.2). The bunny leans back 14°, turned 70° toward the carrot, which hangs from its
mouth (grip 1.8 up), tilted 50° and spun 250° so the tapered root shows and the fronds stay below the eyes: `GoldenCarrotPlant` growth 1,
size factor 1.6. Camera FOV 48, low on the field's east side (`DOLLY`, `LIFT`, `SHIFT`; build sets it). The pull is posed, not a game action.
The plot's small "Central Island" portal sign stays at the left edge (hide it in the set if it distracts). Logo top left. Square: camera on
the 16:9 line of sight to the pet + carrot box, FOV 30, ~20 studs back (cam {-1071.73, 19.20, -842.56} look {-1088.23, 19.36, -830.92});
wordmark 44 %.

**A3.** **Stage 1 (Island Hop), checkpoint 105**, camera ahead of the pad and above the next pillars, looking back along the course (the
pillar chain, yellow mover and coins read as an obby; Stage 3's low-camera version read as "it can be anything"). The player stands
camera-left at the pillar's front edge, pose `cheer`; the **Phoenix Lv 19 uid 1** (FlameTail) hovers camera-left facing the camera (its
PointLight bleaches the player if it hovers at her hand). The coin is the stage's own `Stage1_4` on the camera-right pillar (a copy would
leave the real one in view too). Logo top right (`-Corner TR`). Camera FOV 60; preset A3 (late morning, Brightness 2.2, exposure -0.15,
contrast 0.18, saturation 0.32 so the white pillars part). Nothing in the stage is moved; the reached pad is drawn on copies. Square: same
line of sight, FOV 32, ~29 studs back (cam {-774.88, 87.70, 271.79} look {-745.77, 83.90, 274.46}); wordmark 44 %.

**C2.** A ripe **Giant Melon at the size bound** (factor 3.03, seed 1, turned -47°) on the sun-side plot's outer square 32 (preset C2:
ClockTime 11), **Cat uid 2 at Lv 6** (no Scarf, 3.4 studs) standing on it, the player (look `classic`, `LOOK_NAME`) cheering a row back. **The
size problem:** the melon is only 2.9 studs tall at the bound (`GiantMelonPlant` caps the radius at 1.55), a pet is 3.4–4, the player 6.4, and
pet scale grows only 3 % per level, so a lower level barely helps. The fix is forced perspective: the camera half a stud above the soil, ~9
studs out, FOV 62, the player a row back (closer it becomes a wall of stud blocks). The pet is shifted 0.5 studs toward the camera
(`PET_SHIFT`) so a leaf lobe does not cross its mouth. The melon reads as a green block at 150 px: "giant watermelon" depends on the light
ground spot and the stem. Square: cam {-1147.83, 17.05, -958.29} look {-1151.72, 19.50, -948.76}, FOV 48; wordmark 40 %.

**C3.** Four pets, one per rarity step (Dragon left out), on the sun-side plot's outer squares 31-34, each with a ripe crop: **Cat 2
Lv 6** + Tomato ×1.0, **Fox 4 Lv 12** (Wings) + Blueberry ×1.4, **Panda 2 Lv 16** (Scarf) + Pumpkin ×2.0, **Phoenix 1 Lv 19**
(FlameTail, hovering 1.7) + Glow Mushroom ×2.6; `LINEUP` table; refuses draft crop art. Preset C2 (shared). Heights barely grow with
level (3.4 to 4.8 studs), widths do: in a straight row they look one size, so the pets sit on a **diagonal**, each a step nearer the
camera (z -2.4 / -3.6 / -5.0 / -7.4). Camera FOV 40, low and tilted up (set space {0.6, 1.2, -24} look {0.4, 4.4, 0}), top left stays
sky for the logo. Tier-3 orbiting motes are placed by `UpdateFx`'s time: the builder picks the moment every mote is most to the side
(it only clears each pet's own face; from further back one crossed the Panda's cheek). Square: further back and lower (set space
{0.6, 0.2, -30.5} look {0.4, 6.0, 0}, FOV 40; cam {-1139.37, 16.70, -976.85} look {-1154.80, 22.50, -950.53}); wordmark 60 %.

**A2.** **Stage 14 (Laser Lab)**, the Vault switch jump: from `Switch_Lane1` (blue, on `Block_Float2`) up and left toward `Block_Float1`
and `PlatformA`, group `Vault1` shown pressed (the wire lit neon green, `Bar_Lane1` a ghost), floor spikes bottom left, the **Dog uid 4 at Lv
12** (Wings; warm brown, unused by other sets; the Dragon vanished against the night panel) following; player look `updo`, pose `leap`, yaw
-112. Lab space: origin on the floor under Sweeper1's hub, +X along the course, +Z to the camera; side-on camera 26 studs out (the builder's
defaults hold origin, rig, pet, key light and camera). **The lab is not dark** (sand-blue panel, white floors, STAGES §7.12): preset **A2** is
night (ClockTime 21) with a raised ambient and a narrow key spot on the player (a wide one lit a pale disc). Hazards are drawn at one real
moment `T` of a run (beams by `KitMath.Window`, sweepers `Speed * T + Phase`), originals hidden through `LocalTransparencyModifier`; `COLORS`
shows colour-switch groups as pressed; `POSE` takes a name or a table. Dark logo (cream rims) top left. Square: closer and narrower on the
player, Dog and button (lab space {-6, 6.7, 33.8} look {-6, 6.7, 0}, FOV 40; cam {-332.40, 92.85, -618.80} look {-332.40, 92.85, -585.00}),
grabbed at height 1330; wordmark 44 %. Scouted and dropped: the finale's 34-stud jump (needs a high camera, shows the open front and sea),
the beam grid corridor (calm), the Vault overview and colour shaft (too busy at tile size).

**A1.** **Stage 15 (Rising Tide), Dash Run's 34-stud Long Dash gap D1 -> D2**, the tide risen to 137.5, player (look `updo`, pose `dash`
mirrored, yaw 122) near the end of the dash, 2 studs above **D2's stud top with Stage 15's gold coin on it** (without the landing it reads as
"a happy player jumping into lava"), the **Dragon uid 1 at Lv 18** (FlameTail) trailing and fully in frame, the garden island beyond the lava.
Camera 20 studs out on the course's east side, 8.5 above the pillar-top level, FOV 42, rolled -7°, look-at {-3.5, 5.7, 0} from the player;
Stage 14 hidden while shooting (`HIDE`: its lab panels stood as grey slabs); preset **A1** (ClockTime 7, low warm sun, thin haze). Logo top
left. **The real view does not work:** the Laser Lab's back wall (Stage 14 BeamHall, z -581, y 62-136) covers half the island from anywhere in
Stage 15. So **the garden is a copy** (`GARDEN_*`): Workspace.Garden cloned (scripts, labels, prompts removed), the 12 ring-1 plots drawn by
PlotView at `mid` detail with ripe crops, cut at the sea (y 0), scaled by k = 420 / distance and moved along the camera's sight lines, drawn
1.8x bigger (`GARDEN_SIZE`), with its own sea disc (DebugBaseplate material and colour, radius 2000) at the copy's waterline. The lava is the
real tide with a `CrackedLava` crust (STAGES §7.13; moved and hidden by KitTide with the slab; over the Neon at 0.15 it reads red-hot).
Building the copy takes about a second (17 000 parts). Square: N's camera, wider and turned right (`FOV = 50, LOOK = R + {-0.6, 5.2, 0}`;
cam {-132.38, 152.00, -245.59} look {-150.35, 148.70, -254.38}), `-Rect "726,323,2237,1360"`; wordmark 44 %.

**B1 (parked, draft N).** **Owl uid 2 at Lv 16** (its real maximum; tier 3: no halo, blue scarf; it leans to Pest control, so it needs
no explaining) on the sun-facing plot (`PLOT_SLOT = "sun"`, slot 8, preset B1: ClockTime 17.4, warmer `ColorShift_Top`), outer-row square 32:
its 3 × 3 reach clipped to six squares (23-25, 31-33), tinted by `PlotView:ShowReach` and outlined in the Owl's rarity blue by
`PlotView:ShowBorders`; a ripe **Pumpkin at the size bound** in square 31. The Owl faces the camera (`PET_YAW` 0, turned 30° toward the
Pumpkin). Camera FOV 50, low on the field's outer side, sky top left for the logo. Sunflower is registered now, so it could be added.
Tile test: the Owl's face, scarf and Pumpkin read at 150 px, but the reach squares read as a lit patch, not "guarding": the story stays thin
until D1's crows. A camera at Owl height (reach squares edge-on) and a view from above (the zone never fits) were dropped.
