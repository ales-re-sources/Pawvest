# Pawvest — store thumbnails (TH)

*Planned 2026-11-13 from the user's brief, revised the same day after a review of the nine variants (§5: phone-size rework, the
logo carries the name, a giant-harvest shot, two build passes); nothing built. Milestone outline: ROADMAP → TH. When a piece ships,
its as-built note (sets, camera, light) stays here and ROADMAP gets a short Done entry.*

## 1. Goal
A store page that makes the right players click and then stay (qualified play-through, §2), that shows what only Pawvest has
(EXPANSION §1.1), and that lets Roblox pick the winner by data instead of us guessing. We build **three clearly different
themes with three variants each** (9 thumbnails, §4) plus a logo and an icon, in two passes (§8), and test them in rounds (§6).

## 2. How Roblox tests thumbnails
- **Where:** Creator Dashboard → the experience → **Thumbnails**, tabs *Home Page* and *Experience Detail Page*. Upload any
  number; mark **2–5 as active**. With one active thumbnail everybody sees that one.
- **Thumbnail personalization:** a multi-armed bandit, not a fixed A/B split. Each active thumbnail first goes to random players;
  then the one with the better **qualified play-through rate** per player group gets most impressions, the others keep a little.
  Different groups can end up with different winners. Roblox reports +8.5 % qualified play-through on average.
- **Staff advice:** keep up to five active; make them differ in gameplay, characters, environment or the **player motivation**
  each one targets (look-alikes teach nothing); test new ones with every major update and show the new content; wait **at least
  7 days** before changing the set; keep one visual theme across thumbnails and icon; no clickbait.
- **Not testable:** the icon (512×512) and the title. A known workaround is an icon-style image among the thumbnails.
- **Format:** 16:9, 1920×1080. Content must be what the game really shows (moderation rejects misleading images).
- Sources: [Thumbnails (Creator Hub docs)](https://create.roblox.com/docs/production/publishing/thumbnails),
  [Thumbnail personalization announcement](https://devforum.roblox.com/t/live-now-personalize-your-thumbnails-to-attract-more-users/3257233),
  [5 tips from Roblox staff](https://devforum.roblox.com/t/5-tips-from-roblox-staff-to-get-the-most-out-of-thumbnail-personalization/3471689),
  [Get your thumbnails ready](https://devforum.roblox.com/t/get-your-thumbnails-ready-for-thumbnail-personalization/3226599).
  Re-check the dashboard UI when TH starts (the docs may lag).

## 3. Rules for every frame
- **Lead with what is ours** (EXPANSION §1.1): the obby, pets as characters on guard, critters at the fence. Planting and
  harvesting are the frame, not the hook. The one harvest-led shot (C2) keeps a pet in the frame (the user, 2026-11-13).
- **Real content only:** every piece in a frame exists in the game as players see it (stage parts, pets with their real looks,
  crops at a real growth stage and a real size). Composition, light and camera are free.
- **Phone first:** the home tile is thumb-sized. **One subject, one face toward the camera, one idea**; at most two pets; strong
  silhouette, saturated stud colours. Every draft passes the **tile test** (§8) before it is finished.
- **One motivation per thumbnail** (§2): each variant names the player it is for (§5).
- **Wordless except the logo.** No taglines, no numbers, **no stage count**: players abroad do not read English and Roblox
  prints the title under the tile anyway.
- **The logo carries the name** (§4 Logo): a **PAWVEST** wordmark with a pawprint worked into it (paw + harvest), made once,
  placed in the same corner of every thumbnail; the icon uses the pawprint mark alone. The stud sign in C1 is the only in-scene
  name.
- **One look across the set** (§2): the same avatar with its face visible, the same logo corner, the same palette.

## 4. Themes and variants
Variants inside a theme differ in subject, camera or place, not only in colour. Pets are at a level their kind reaches: the
rarity caps every trait, so the pet level too (`PetConfig.AptitudeCap`: Cat / Dog 12, Bunny / Fox 14, Owl / Panda 16, Dragon 18,
Phoenix 20; look tier 4 and its halo only on a Phoenix); uids are picked for the best accessory roll (no crown on a thumbnail pet).

### A — Action: "Run it, grow it" (for obby players)
The player in motion with one pet; saturated, fast, tilted camera.
| # | Subject | Camera / light | Pieces |
|---|---|---|---|
| A1 | One jump over World 3 lava (Rising Tide) with a Dragon trailing; the garden as **one glowing island** behind (no split frame) | low, from the side of the jump; lava glow in front, golden island behind | Stage 15 section, posed rig, Dragon, garden backdrop |
| A2 | Laser Lab **side-on** (the stage's own 2D view): the player mid-leap between neon beams, a pet trailing; neon on dark looks like nothing else on the page | side view, player large; the lab at night (by day it is a light sand-blue room: §9 A2), neon beams | Stage 14 section, rig, pet |
| A3 | The player landing on a stud checkpoint, **facing the camera**, with the Phoenix; a challenge coin beside them (taking one has no burst: it vanishes); the course behind them | high, ahead of the pad, looking back along the course; bright day | checkpoint, challenge coin, course section, rig, Phoenix |

### B — Characters: "Pets on guard" (for pet lovers and defence players)
Calm and cosy, eye contact with the pet; the defence angle no other garden game has.
| # | Subject | Camera / light | Pieces |
|---|---|---|---|
| B1 | One big guard pet on its square, its reach ring glowing over ripe crops, one big Pumpkin beside it. **With D1:** two or three crows landing on the fence | at fence height, pet in the foreground; late afternoon | plot, field squares, reach ring, pet, Pumpkin (crows later) |
| B2 | Stare-down: one guard pet (Fox with its scarf) face to face with a single crow on the fence, ripe crops soft behind. **Needs D1** | macro-close, shallow depth (DepthOfField); warm | Fox, crow, fence, crops |
| B3 | Wide plot at sunset: hatchery with a glowing egg on the left, barn on the right, pets resting among ripe Giant Melons and Sunflowers. **Experience Detail Page only** (no focal point at tile size) | high three-quarter view; sunset | plot (U5 layout), egg, pets, ripe crops |

**Crows (decided 2026-11-13):** crows are E4-thin today, a forecast and a settle roll with no bird in the world, so a crow in a
frame would break "real content only". B2 and B1's crows launch with drop D1 (Critters), which is also the update that
refreshes the thumbnails (§2).

**B1 parked until D1 (the user, 2026-11-14).** Crow-free, the guard idea rests on the yellow reach tint, which only a player who
has placed a field pet understands; a viewer sees a lit patch. The whole theme B waits for visible pests (D1); the crow-free
set stays buildable (§9 B1).

### C — Harvest: "Paw + Harvest" (for farming players and collectors)
The payoff: pets and what they grow. The most readable theme at phone size.
| # | Subject | Camera / light | Pieces |
|---|---|---|---|
| C1 | A pet pulling a glowing Golden Carrot out of the soil, **pet and carrot filling most of the frame**; the stud-built PAWVEST sign small behind | frontal, close; clean sky | pet, Golden Carrot (pulled pose), soil, sign |
| C2 | **Giant harvest:** a Giant Melon as big as the player, a pet sitting on top, the player beside it cheering | very low and close, so the melon towers; bright day | Giant Melon at the largest real size, pet, rig |
| C3 | Collection: three or four pets growing in size from a Cat to a glowing Phoenix, a crop beside each (pets do not hold crops in the game) | frontal, Phoenix dominant; bright day | 3–4 pets, crops |

**C2's size is real:** the melon is built at the upper bound of `CropConfig.SizeBounds()` (the drawn size grows with the cube
root, `PlantKit.dimension`); the camera does the rest. Never scale a crop past that bound.

**Icon (512×512):** the C1 pet (Bunny 4 at Lv 19, no crown or halo) with its Golden Carrot, a logo in a corner; built from
C1's set, cropped square (as built: §9 C1 square). The icon is not testable (§2); C1 doubles as the "icon-style" thumbnail.

### Logo (replaces the old C2 thumbnail)
The first plan had a thumbnail that was only a sign: PAWVEST with a letter turned into a pawprint, pawprint stamps along the
field rows, a basket of crops. Typography with no character does not earn a tap, and the idea is a logo, so it is one now.
- **Idea (the user, 2026-11-13, replacing "a paw worked into a letter"):** the word **HARVEST** with **HAR** crossed out and
  **PAW** written over it, tilted like a correction, in the pet colour (orange); VEST stays harvest gold, the struck HAR is a
  dimmed gold. The edit shows the wordplay without a sentence.
- **Chosen cross-out (the user, 2026-11-13): torn claw cuts.** Three claw marks tear through HAR so the background shows through,
  as if a pet clawed it out. Each mark is a sickle (sharp at both ends, thickest past the middle, slightly curved, ragged edges),
  steep at **74°** (the user's pick from 62 / 68 / 74 / 80°), staggered (the middle one longest and lowest),
  with a thin rim. Dropped on the way: a pawprint stamp over HAR (lost its shape when small), a plain strike bar, a scribble,
  a pawprint trail, a swipe ending in a paw, straight claw lines; and the first sketches (a pawprint in the A or the V, a
  stacked PAW / VEST badge).
- **Dark frames:** the cuts show the background, so on a dark frame a dark rim disappears (seen in the sketches). The rim must
  contrast with what lies under the logo: dark brown on light frames, cream on dark ones. **Check the cuts on every final image**
  (the user, 2026-11-13); where the frame behind the logo is busy, a backing plate behind the wordmark may be needed.
- **Style:** the user likes the chunky rounded font of the sketches (Lilita One, Google Fonts, OFL licence: free for commercial
  use) with a thick dark-brown outline, readable on a light and on a dark frame. Open: whether C1's in-scene sign uses the same
  lettering (as stud bricks or a decal) or is left out.
- **Deliverables:** the wordmark; the **pawprint mark** alone (for the icon and small sizes); both as transparent PNG, with a
  light-outline and a dark-outline version (the dark one with cream rims on the claw cuts).
- **How:** the final is drawn as vector art in that font (the sketches' SVG paths are the start) and exported as PNG (built:
  §9 Logo).
- **Tile-size risk:** the struck HAR and the smaller PAW are the finest parts of the logo; at a thumbnail corner PAW + VEST must
  read as one word, and the struck HAR may blur into a smudge (acceptable if PAWVEST still reads).
- **Where it goes:** the same corner of every thumbnail, the mark on the icon, C1's sign. Later candidates (not TH): the hub
  sign, the loading screen.
- **Checks:** the wordmark reads at tile size in a thumbnail corner; the mark reads at icon size in the Roblox home grid.
- **Dropped from the old C2:** the pawprint stamps along the rows (nothing in the game leaves them); the crop basket stays
  available as a prop.

## 5. Review of the variants (2026-11-13, judgment, not data)
| # | Who it pulls in | At tile size | Expectation |
|---|---|---|---|
| B2 | pet lovers | one face, one enemy, a conflict | the strongest idea; waits for D1 |
| A3 | obby players | one subject facing the camera, the course behind | strong |
| C1 | farming and pet players | pet + glowing carrot | strong; also the icon's source |
| C2 | farming players (the biggest audience in the genre) | one huge crop, one pet | strong; watch the "another garden game" read (§3) |
| C3 | collectors | reads with 3–4 pets (eight were specks) | medium |
| A1 | obby and farming players | reads once the split is gone | medium |
| B1 | pet and defence players | reads with one pet; the reach tint is not understood without pests | parked until D1 |
| A2 | obby players | high contrast, face in profile | medium, the most distinctive look |
| B3 | cosy and farming players | no focal point | Detail Page only |

What the review changed: A1 lost its split and second pet; A2 was an over-the-shoulder shot toward a portal showing the garden
(no face, and portals do not show that); A3's hub portals became a course with a hazard; B1 went from four pets, a flock, the
player and a pumpkin to one pet; the "H as a pawprint" sign (old C2) became the logo and its slot went to the giant harvest;
C3 went from eight pets to three or four.

## 6. Test plan
- **Home Page tab** takes the single-subject thumbnails; **Experience Detail Page tab** takes the story shots: B3 plus wide views
  made from the same sets (the full field, the hub), in the order obby → pets → garden.
- **Round 1 (≥ 7 days):** pass 1's two, A3 and C1 (theme B waits for D1, §4 B). It answers the biggest question first: which
  theme, i.e. which player, the game attracts.
- **Round 2 (≥ 7 days):** add pass 2's variants up to five active, the winning theme's first; drop a clear loser.
- **With D1:** B2 and B1 with crows replace the weakest active ones.
- **Keep** the top 2–3 active between updates; test new ones against them with every big update.
- **Read:** the Thumbnails page's per-thumbnail impressions and qualified play-through; compare with T1a / T1b retention
  (TELEMETRY.md) so a thumbnail that clicks but disappoints is caught. A dip in play-through right after a home-page surge is
  normal (§2).
- Testing needs real traffic: it starts with the public launch (or a soft launch with enough impressions to mean something).

## 7. Build approach
- **Studio-only photo sets:** `ServerStorage.PhotoSet.<A|B|C><n>` (A1…C3, Icon). No scripts, so Argon never syncs them (a rig's `Animate` LocalScript once did: `Rig.build` deletes scripts)
  (`$keepUnknowns` keeps them). A set is moved into Workspace only while shooting and back right after, so nothing shows in play.
  Pieces are cloned per set (variants never share instances). Built and edited through MCP `execute_luau` in Edit.
- **Pets:** clone `ReplicatedStorage.PetModels[kind]`, dress it with `PetLook.Apply(model, kind, level, uid)` (a pure function of
  kind / level / uid), pose by CFrame (and `PetLook.UpdateFx` once for tier effects). Search uids for the wanted accessories with
  `PetLook.AccessoriesOf(kind, level, PetLook.Seed(uid))`.
- **Crops:** `<CropId>Plant.new(parent, soilCFrame, seed, sizeFactor)` from the recipe modules (`PlantKit.recipe`), then
  `:SetGrowth(1)` for ripe (or a stage for C1's pulled carrot); the set keeps the Parts (no update loop). Pick the seed per crop
  for the best silhouette; size factors stay inside `CropConfig.SizeBounds()`.
- **Scene reuse:** the real garden plot (U5 layout) and its reach ring, stage parts in place (shoot A in the stage itself, add
  only rig and pet), `ServerStorage.DecorKit` decor with the placement rules (AGENTS.md Gotchas), the stud sign from StudStyle
  bricks.
- **Player:** one posed R15 rig for the whole set, built from free Roblox catalog items (the user, 2026-11-14: a purpose-made
  avatar, not an account's), face visible and expressive; `tools/photoset_rig.luau` (§9).
- **Logo:** per §4 Logo (vector master rendered to PNG, §9); composited onto the finals.
- **Light:** a per-set Lighting preset (time of day, Atmosphere, ColorCorrection, Bloom, DepthOfField for B2) applied by script;
  **snapshot Lighting and its children before and restore after** every session.
- **Capture:** drafts by MCP `screen_capture` with a camera CFrame, one at a time (AGENTS.md → Studio MCP habits; set
  `CameraType = Fixed` afterwards; restore a minimised window). Finals at 1920×1080 from a maximised Studio viewport with the UI
  hidden; the user, or Claude after sizing the window. Finals are stored under `docs/art/thumbnails/` (JPG).

## 8. Milestones (each scoped with acceptance checks when it starts)
Two passes: two thumbnails first (A3, C1; theme B waits for D1), the others only after they have been seen at tile size and by a kid.
| # | Content |
|---|---|
| TH0 | Shared pieces: the posed rig, pets at max level with chosen uids, the ripe crop set, the logo (three sketches, the user picks; wordmark + pawprint mark) and the stud sign in the same lettering, the Lighting snapshot / preset helper |
| TH1 | Pass 1: A3, C1 and the icon (B1 parked until D1, §4 B). Each draft passes the **tile test** (shrunk to tile size in a grid of real competitor thumbnails) and the **kid test** (which one would the playtester tap, and what does he think the game is) before finals |
| THU | Upload; round 1 active (the user on the dashboard) |
| TH2 | Pass 2, shaped by TH1's lessons: A1, A2, C2, C3; B3 and the wide views for the Detail Page |
| THR | Round 2 after ≥ 7 days; keep the top 2–3; as-built notes here |
| THD | With drop D1 (Critters): B2 and B1 with crows (or other visible pests) |

## 9. As built
**Tools** (run through MCP `execute_luau` in Edit; header comments say how):
- `tools/photoset_lighting.luau`: `snapshot` / `apply` (per-set presets: `C1`, `A3`, `B1`, `C2`, `A1`, `A2`) / `restore` / `status`. The snapshot lives in
  `ServerStorage.PhotoSet.LightingSnapshot` and refuses to be overwritten, so a forgotten restore never loses the real look.
- `tools/photoset_c1.luau`: builds `Workspace.PhotoSet_C1`, returns the camera for `screen_capture`; `stash` / `shoot` move it to and
  from `ServerStorage.PhotoSet.C1`. For iterating, its source sits in the StringValue `ServerStorage.PhotoSet.Builder_C1` and runs
  through `loadstring` with a parameter table (re-store the file after editing it). While a set is in Workspace the Studio GUI is
  hidden (`ShowDevelopmentGui`).
- `tools/photoset_b1.luau`: the same for `Workspace.PhotoSet_B1` (`ServerStorage.PhotoSet.B1`, iterating copy `Builder_B1`).
  Refuses a pet level above its kind's cap. Set-space +X is camera-left.
- `tools/photoset_rig.luau`: the player rig, a library the set builders load from `ServerStorage.PhotoSet.Builder_Rig`:
  `build` (the chosen look) and `pose` (named poses `stand` / `cheer` / `leap` / `dash`, `mirror` flips one; forward kinematics down the joint chain, feet
  set on a given floor).
- `tools/photoset_a3.luau`: A3 in the stage itself (`ServerStorage.PhotoSet.A3`, iterating copy `Builder_A3`): nothing in the
  stage is moved; the reached pad is drawn on copies over it.
- `tools/photoset_c2.luau`: C2 on the sun-side plot (`ServerStorage.PhotoSet.C2`, iterating copy `Builder_C2`, preset `C2`); loads
  the rig like A3. Refuses a pet level above its kind's cap and a melon past `CropConfig.SizeBounds()`.
- `tools/photoset_c3.luau`: C3 on the same sun-side plot (`ServerStorage.PhotoSet.C3`, iterating copy `Builder_C3`, preset `C2`
  shared). A `LINEUP` table of pet + crop pairs; refuses a level above the cap, a crop past the size bound and draft crop art.
- `tools/photoset_a2.luau`: A2 in Stage 14 itself (`ServerStorage.PhotoSet.A2`, iterating copy `Builder_A2`, preset `A2`): draws
  every hazard as ObstacleKit would `T` seconds into a run (beams by `KitMath.Window`, sweepers turned on copies), hiding the
  originals only through `LocalTransparencyModifier` (not saved; `stash` resets it); `COLORS` shows colour-switch groups as
  pressed (other-colour plates ghosted, the group's wire lit). `POSE` takes a name or a pose table, `MIRROR` flips it.
- `tools/photoset_a1.luau`: A1 in Stage 15 itself (`ServerStorage.PhotoSet.A1`, iterating copy `Builder_A1`, preset `A1`): an
  untagged copy of the tide (with its `Crust`) at `LAVA_Y`, and the garden island copy (`GARDEN_*`: PlotView plots, cut at the
  sea, moved along the camera's sight lines, its own sea disc); `HIDE` hides scene folders while shooting as A2 does.
  Building the copy takes about a second (17 000 parts).
- `tools/thumb_art.ps1` (PowerShell, Windows: headless Edge + System.Drawing): `render` (logo PNGs from `docs/art/logo/logo.html`),
  `grab` (a full-resolution 16:9 frame from Studio's viewport), `compose` (a logo onto a frame), `tiles` (320 / 200 / 150 px sheet).

**Logo (2026-11-13).** `docs/art/logo/logo.html` is the master (SVG drawn by script in Lilita One; the font file and its OFL licence
sit next to it): HARVEST with HAR dimmed gold, VEST gold, PAW orange tilted 10°, outline dark brown; three seeded sickle cuts at 74°
are real holes through HAR with a 4-unit rim that also traces them past the letters (the tips scratch the frame). `render` writes
`pawvest-logo-light.png` (dark-brown rims), `pawvest-logo-dark.png` (cream rims) and `pawvest-mark.png` (pawprint), transparent
and trimmed, ~3000 px wide.
- On C1 it sits top-left at 30 % of the frame width over the sky; at 40 % it covered the cat's face. The dark rims keep the cuts
  readable over sky and leaves; the dark version's cream rims read on the soil (tried bottom-left, not used).
- Tile test (320 / 200 / 150 px): PAW and VEST read at all three; the struck HAR becomes a smudge at 150 px (accepted in §4).

**C1 (draft G, 2026-11-13; the builder's defaults rebuild it).** Pet: **Bunny uid 4** (Scarf + Wings), also the icon's pet. **No
crown on a thumbnail pet** (the user, 2026-11-13, on draft F's Cat 33: the crown and the cat's leaning pose did not flatter it).
Crown-free max-level uids: Bunny / Cat / Fox 4 (Scarf + Wings), Panda 2 (Scarf + Wings), Dog 2 (FlameTail + Wings). The Bunny
won the drafts: tall enough that the carrot clears its body, and a bunny with a carrot reads at once; every Lv 20 Bunny has the
same lime trim (uids only change the coat). Panda 2 and Dog 2 are shorter: with the Bunny's pose the carrot hid behind their
bodies (they would need their own pose). Facing the camera, the mouth-held fronds always crossed the face; a three-quarter turn
works. The set stands on **slot 1's real plot** (`PLOT_SLOT = 1`, drawn by `PlotView` at full detail, labels removed): the pet in
square 32 (left empty), ripe crops around it from `CROPS` (no pineapples, whose gold competed with the carrot; no giant melon in
front), the barn and weathervane behind; the user's call over draft D's bare island edge, whose background was too empty and whose
square design did not suit (the squares themselves are hidden by the crops). **Eggplants turned 90°** (`TURN`): the eggplant is
flat and showed its edge to this camera (the user: revisit its design). Morning light (preset C1, ClockTime 9.2: the sun in the
east behind a camera looking west). The bunny leans back 14°, turned 70° toward the carrot, which hangs from its mouth by the
stalks (grip 1.8 studs up), tilted 50° and spun 250° so the root comes out ahead with its tapered tip showing and the fronds stay
below the eyes. Carrot: `GoldenCarrotPlant` at growth 1, size factor 1.6 (the upper bound is 3.03). Camera FOV 48, low on the
field's east side, backed off ×1.4 (`DOLLY`), aimed 0.7 studs higher (`LIFT`) and 1.2 studs to the pet's left (`SHIFT`) so the
halo clears the logo; build sets that camera.
- **Draft H (2026-11-14): Lv 19, no halo.** Every Lv 20 pet wears the tier-4 neon halo, which the user found as wrong for the
  thumbnail as the crown. Lv 19 is the last tier-3 level: no halo, one accessory (Bunny 4: Wings; Panda 2: Scarf), scale 1.57
  instead of 1.6, orbiting motes stay. The builder now defaults to Lv 19. **The user picked the Bunny (2026-11-14):**
  `c1-bunny-h(-logo).jpg` is C1 (the builder's defaults); the dropped candidate was `c1-panda-h(-logo).jpg` (Panda 2: `PET_YAW` 20, `DOLLY` 1.15, `CARROT_TILT` -55,
  `GRIP` 2.6). The Panda's model faces about 50° off the Bunny's, and its square head took 11–33 % of the stalks over the face
  at the Bunny's grip; a higher grip cleared it (measured by rays from the camera to a grid over eyes, nose and mouth). At
  150 px the Panda's face reads more strongly (black and white, blue scarf); the Bunny's carrot reads better as a carrot (its
  tapered tip shows).
- Drafts: `docs/art/thumbnails/drafts/` (`c1-bunny-h*` last; `c1-bunny-g*`, `c1-panda-h*`, `c1-cat-*` earlier).
- **Release candidate (2026-11-14, the user's call; final after the grid tile test and the kid test, §8 TH1).** Re-captured with
  the round-the-stem eggplant (CG16e, merged the same day), which needs no turn (`TURN` now defaults to none). Files in
  `docs/art/thumbnails/`: `c1.jpg` (1920×1080 with the logo, the upload) and `c1-clean.jpg` (no logo), scaled from the
  1968×1107 grab; the square, which the store also takes (512×512): `c1-square.jpg` (wordmark at 44 % width top-left; at 50 %
  it touched an ear), `c1-square-mark.jpg` (the pawprint mark instead), `c1-square-clean.jpg` (1360×1360 master, no logo).
  At 100–150 px the wordmark's PAW VEST still reads; the mark is cleaner but says less. **The user keeps both** square
  variants (2026-11-14). Square camera: the 16:9 camera's line
  of sight to the centre of the pet + carrot box, FOV 30 (less perspective than 48: up close the carrot loomed and fronds
  crossed an eye), about 20 studs back (cam {-1071.73, 19.20, -842.56} look {-1088.23, 19.36, -830.92}); grabbed with
  `-Rect "726,323,1968,1360" -Aspect 1:1`, the viewport minus its bottom 160 px, where Studio draws the view-cube gizmo.
- The pull is posed, not a game action (pets never harvest; `PlayHarvest` is a gold-fleck burst): the user chose it on 2026-11-13.
- Tile test (150 px): the face and the gold carrot read; the carrot reads as a carrot only with its tapered tip out.
- **Capture in Edit.** Particles (ripe glint, pet aura) do not render in Edit captures; a Play capture (HUD hidden, camera bound
  with `BindToRenderStep`, character parked) shows them, but at this distance they add almost nothing and stud textures render
  worse there.
- **Full-resolution frames:** `screen_capture` returns a downscaled image, so finals come from `thumb_art.ps1 grab` right after
  `build` / `shoot` (they leave the set's camera on, `Scriptable`); PrintWindow captures Studio without bringing it to the front. On this machine (3840×2160 at 150 %) the 1312×1013 viewport is 1968×1520 physical pixels at `-Rect "726,323,1968,1520"`
  (maximised Studio, current panel layout; re-read it after moving panels), and its middle 16:9 band is 1968×1107, enough for
  1920×1080.
- **Stale grabs:** Studio's Edit camera can fall back to `Fixed` and an earlier view between `build` and the grab, and the grab
  then shows that view (A1's drafts M / N were draft L's camera). A builder's `setCamera` sets `Camera.Focus` to the look-at
  as well (photoset_a1: since then the camera holds); before a final, read `CameraType` / `LookVector` back right before the grab.
- Still in the frame: the plot's small "Central Island" portal sign at the left edge (hide it in the set if it distracts).
- **Level exception (2026-11-14):** a Bunny reaches Lv 14 at most (Uncommon cap), so C1's Lv 19 Bunny is above what a player
  can own. **The user keeps C1 as it is** (C1 is done); later sets stay within the cap (§4).

**B1 (draft N, 2026-11-14, parked until D1: §4 B; the builder's defaults rebuild it).** Pet: **Owl uid 2 at Lv 16**, the Owl's real maximum (Rare cap;
tier 3: no halo, a blue scarf, orbiting motes); the Owl leans to Pest control and is the raccoon guard, so it is the guard pet
that needs no explaining. The set stands on the plot whose field faces the sun (`PLOT_SLOT = "sun"`: slot 8 at preset B1),
with the Owl on the outer row's square 32: its reach (Lv 16: 3 × 3) is clipped to six squares (23-25, 31-33) and tinted by
`PlotView:ShowReach`, the game's own reach tint, and outlined in the Owl's rarity blue by `PlotView:ShowBorders` (U3b;
a thin line along the front edge). Beside it in square 31 a ripe **Pumpkin at the size bound** (factor 3.03), as
tall as the Owl. No other pumpkin in `CROPS`, and **no Sunflower**: its art is still a draft, so the plot draws it as a
yellow block (drafts G-I had two behind the Owl). Late-afternoon light (preset B1, ClockTime 17.4, the sun behind the camera);
a warmer `ColorShift_Top` turned the brown Owl as orange as the Pumpkin. The Owl model faces the camera at `PET_YAW` 0 (turned
30° toward the Pumpkin). Camera FOV 50, low on the field's outer side; the Pumpkin left, the Owl right of centre, sky top-left
for the logo (30 % width).
- Drafts `docs/art/thumbnails/drafts/b1-owl-{g,h,i}(-logo).jpg`: G closer (the 16:9 band cut the Owl's tufts, logo over corn
  and barn), H further back (Owl small), I between; N is I without the Sunflower blocks and with the outline.
- Tried and dropped (`b1-owl-{j,k,l,m}-logo.jpg`): a camera at Owl height (J: the reach squares seen edge-on, the outline
  lost); the Owl in the middle of its full 3 × 3 reach (square 24) seen from above (K-M: the zone never fits the frame, so it
  still reads as a lit floor; the Owl small, the background busier, and a crop in front of it covered its face).
  DepthOfField does not show in Edit grabs (stronger far blur changed nothing).
- Tile test (320 / 200 / 150 px, by Claude): the Owl's face, scarf and the Pumpkin read at 150 px; the outline is too thin to
  see there, and the yellow reach squares read as a lit patch, not yet as "guarding"; the barn and corn behind are busier than
  C1's frame. The guard story stays thin until D1's crows (§4 B).

**Player rig (TH0, 2026-11-14).** Look C of three, the user's pick: Lavender Updo (Roblox, free; asset 451220849), skin
204/142/105, orange torso, navy legs, no clothing items; the other looks were classic Roblox colours with Pal Hair and a denim
jacket with Brown Charmer Hair (`docs/art/thumbnails/drafts/a3-rig-looks.jpg`). Edit-mode facts the library handles: the
default head is a **dynamic head** (classic face decals are ignored), so the grin is set on its `FaceControls` (lip corners,
jaw, cheeks, brows); the joints are `AnimationConstraint`s, so the parts are anchored and placed by forward kinematics; some
accessories come unwelded (the updo's handle sat 29 studs off), so every accessory is seated on its matching body attachment.
Catalog ids are checked with `MarketplaceService:GetProductInfo` before use (Creator Store search does not cover the catalog).
`Rig.LOOKS` names the looks: `updo` (the above, `Rig.LOOK`) and `classic` (Roblox's default avatar, added for C2 draft I).

**A3 (draft J, 2026-11-14; the builder's defaults rebuild it).** **Stage 1 (Island Hop), checkpoint 105**, the camera ahead
of the pad and above the next pillars, looking back along the course: the chain of stud pillars, the yellow mover and coins on
pillars cross the sea behind the player, which reads as an obby. Draft D (Stage 3, checkpoint 11, a low camera between red /
orange kill corridors) read as "it can be anything" and its lava smoke as unexplained (the user); from higher up Stage 3's
background is the hub, Stage 2 is a flat walkway with thin spinners, Stage 6's checkpoint a white block. The player stands
camera-left at the pillar's front edge (in the pad's middle the light column washed her pale), pose `cheer` (arms in a V, one
knee up from the landing step). The **Phoenix at Lv 19** (uid 1: FlameTail) hovers camera-left beside her, facing the camera
(its own glow, PointLight 2.5 range 10, bleached her when it hovered at her hand). The coin is the stage's own `Stage1_4` on
the pillar camera-right (a copy beside her hand left the real one in view too: two coins). Logo top right (`-Corner TR`, in
the sky; top left covered the Phoenix). Camera FOV 60; preset A3 (late morning, Brightness 2.2, exposure -0.15: brighter
washed the rig; contrast 0.18 and saturation 0.32 so the white pillars part at tile size).
- Drafts `docs/art/thumbnails/drafts/`: `a3-{a,b,c,d}-logo.jpg` (+ `a3-d.jpg` clean) on Stage 3: A floated and stood in the
  light column, B fixed the feet and the coin, C moved the Phoenix off, D turned it to the camera. On Island Hop: `a3-h.jpg`
  (first framing), `a3-i-logo.jpg` (logo over the Phoenix), `a3-j-logo.jpg` + `a3-j-tiles.png` (+ `a3-j.jpg` clean).
- Tile test of J (320 / 200 / 150 px, by Claude): the player, the Phoenix, the coin and the logo read at 150 px, the pillar
  path over blue water reads as a course at 320 / 200; the reached pad's light column is a pale cyan band through the
  middle, and her orange top looks amber in the pad's green light (both real).
- **Release candidate (2026-11-14, the user's call; final after the grid tile test and the kid test, §8 TH1).** Draft J
  re-grabbed from the stashed set. Files in `docs/art/thumbnails/`: `a3.jpg` (1920×1080, wordmark top right, the upload) and
  `a3-clean.jpg` (no logo); the 512×512 squares as for C1: `a3-square.jpg` (wordmark at 44 % width top left, clear of the
  Phoenix's crest), `a3-square-mark.jpg` (pawprint mark at 20 %), `a3-square-clean.jpg` (1360×1360 master, no logo). Square
  camera: along J's line of sight, aimed between the player and the course (pad space {2.6, 4.4, -6.8}), FOV 32, about 29
  studs back (pad space {1.2, 8.2, -36}: cam {-774.88, 87.70, 271.79} look {-745.77, 83.90, 274.46}); a camera aimed at the
  player + Phoenix box put the side pillars, not the course, behind them. The coin `Stage1_4` falls outside the square; coins
  on the far pillars still show. Grabbed with `-Rect "726,323,1968,1360" -Aspect 1:1`.

**C2 (draft H, 2026-11-14, started in TH2 ahead of the TH1 grid and kid tests; the builder's defaults rebuild it).** A ripe
**Giant Melon at the size bound** (factor 3.03, seed 1, turned -47° so its striped side and stem face the camera) on the
sun-side plot's outer square 32 (preset C2: ClockTime 11, the sun behind the camera), the **Cat uid 2 at Lv 12** (its real
maximum, Scarf) standing on its crown, the player cheering a row back (square 31 + 5 studs; squares 23, 31, 32 empty).
- **The size problem:** at the bound the melon is only 2.9 studs tall (`GiantMelonPlant` caps the radius at 1.55: "a heavy
  melon gets longer, not taller"), a tier-2/3 pet is 4 studs (the Panda at Lv 16 too; Lv 1 would still be ~3), the player
  6.4. Seen from eye height (draft E) the melon is knee-high and the frame reads "cat on a green block". Draft H fixes the
  scale by forced perspective: the camera half a stud above the soil, ~9 studs out, FOV 62, the player a row back, so the
  melon stands as tall as she does; closer (draft F, 5.6 studs, FOV 72) it became a wall of stud blocks.
- Drafts `docs/art/thumbnails/drafts/`: `c2-cat-e.jpg` (eye-level, beside), `c2-cat-h.jpg`, `c2-cat-h-logo.jpg` (wordmark
  top left at 30 %), `c2-cat-h-tiles.png`. Draft A (the Panda, the melon's blossom end to the camera) was not kept.
- Tile test of H (320 / 200 / 150 px, by Claude): the Cat's face, the player and the logo read at 150 px; the melon reads as
  a big green block (its stripes merge), so "giant watermelon" depends on the light ground spot and the stem. The pet is still
  bigger than the melon, the opposite of the brief's "melon as big as the player".
- **Draft I (2026-11-14, the user):** the Cat at **Lv 11** (3.9 studs instead of 4.0: the scale grows only 3 % per level,
  so a lower level does not fix the size problem; still tier 2 with its Scarf), and a second look for the player:
  **`classic`, Roblox's default avatar** (Rig.LOOKS: Pal Hair 63690008, Blue and Black Motorcycle Shirt 144076358,
  Dark Green Jeans 144076760, all free Roblox items; light stone grey skin), chosen with `LOOK_NAME`. Drafts
  `c2-cat11-i-{classic,updo}(-logo).jpg` + `-tiles.png`. At 150 px the classic avatar's white face and black jacket read as
  "a Roblox player" at once but darker against the red barn; the updo's orange top is the stronger colour patch.
- **Draft J (2026-11-14, the user): the Cat at Lv 6** (look tier 1: 3.4 studs, no Scarf), now a little shorter than the
  melon is long, so the melon reads bigger. Moved 0.5 studs toward the camera (`PET_SHIFT`): at the crown's centre a leaf
  lobe of the arch crossed its mouth (found by segment-box tests from the camera: plant parts have CanQuery off, so
  raycasts miss them). Both looks: `c2-cat6-j-{classic,updo}(-logo).jpg` + `-tiles.png`; the builder's defaults rebuild J
  (`LOOK_NAME` picks the look).
- **Release candidate (2026-11-14, the user's call: draft J with the default avatar; final after the grid tile test and the
  kid test, §8 TH1).** The builder's defaults (`LOOK_NAME` "classic"). Files in `docs/art/thumbnails/`: `c2.jpg` (1920×1080,
  wordmark top left at 30 %, the upload) and `c2-clean.jpg`; the 512×512 squares as for C1: `c2-square.jpg` (wordmark at
  **40 %** top left: at 44 % the T of VEST touched the Cat's ear), `c2-square-mark.jpg` (pawprint mark at 20 %),
  `c2-square-clean.jpg` (1360×1360 master). Square camera: the 16:9 camera position nudged (set space {-0.2, 0.55, -10.2}
  look {1.2, 3.0, 0}, FOV 48: narrower from the same low spot keeps the forced perspective; cam {-1147.83, 17.05, -958.29}
  look {-1151.72, 19.50, -948.76}), grabbed with `-Rect "726,323,1968,1360" -Aspect 1:1`.

**C3 (draft F, 2026-11-14, TH2 started early; the builder's defaults rebuild it).** Four pets, one per rarity step
(Dragon left out: four read at tile size), camera-left to camera-right on the sun-side plot's outer squares 31-34, each with
a ripe crop whose seed price and size factor grow with it: **Cat 2 Lv 6** (no accessory) + Tomato ×1.0, **Fox 4 Lv 12**
(Wings) + Blueberry ×1.4, **Panda 2 Lv 16** (Scarf) + Pumpkin ×2.0, **Phoenix 1 Lv 19** (FlameTail, hovering 1.7 studs)
+ Glow Mushroom ×2.6. Preset C2's light (shared), camera FOV 40 low and tilted up (set space {0.6, 1.2, -24} look
{0.4, 4.4, 0}), so the foreground grass drops out and the top left stays sky for the logo.
- **Heights barely grow with level** (Cat Lv 6 3.4, Fox 4.3, Panda 4.0, Phoenix 4.8 studs; the scale is ×1.0 at Lv 1 to
  ×1.6 at Lv 20), widths do (1.9 / 2.8 / 4.3 / 6.5). In a straight row (draft E) they looked one size; a **diagonal**,
  each pet a step nearer the camera (z -2.4 / -3.6 / -5.0 / -7.4), makes the ladder read and the Phoenix dominant.
- **Orbiting motes** (tier 3) are placed by `UpdateFx`'s time: the builder picks the moment when every mote stands most to
  the side as seen from the camera (at time 0 one sat on the Panda's nose).
- Drafts `docs/art/thumbnails/drafts/`: `c3-a.jpg` (first, a straight row seen from eye height: a third of the frame grass),
  `c3-e(-logo).jpg` + `-tiles.png` (the diagonal, wider), `c3-f(-logo).jpg` + `c3-f-tiles.png` (closer).
- Tile test of F (320 / 200 / 150 px, by Claude): all four faces read at 150 px (in E the Cat and Fox were specks); the
  Phoenix's glow does not show in Edit grabs, so "glowing" rests on its gold; the Glow Mushroom is half behind the Phoenix
  (its teal rings show, the caps at the right edge); the barn behind the Cat and Fox is busy.
- **Release candidate (2026-11-14, the user's call: draft F; final after the grid tile test and the kid test, §8 TH1).** The
  builder's defaults. Files in `docs/art/thumbnails/`: `c3.jpg` (1920×1080, wordmark top left at 30 %, the upload) and
  `c3-clean.jpg`; the 512×512 squares: `c3-square.jpg` (wordmark at **60 %**: a row of four leaves the square's top half
  sky, which the bigger wordmark fills), `c3-square-mark.jpg` (pawprint mark at 20 %), `c3-square-clean.jpg` (1360×1360
  master). Square camera: further back and lower along F's line of sight (set space {0.6, 0.2, -30.5} look {0.4, 6.0, 0},
  FOV 40: the grazing angle keeps the foreground grass thin; cam {-1139.37, 16.70, -976.85} look {-1154.80, 22.50,
  -950.53}), grabbed with `-Rect "726,323,1968,1360" -Aspect 1:1`. From further back (z -33, camera 1.4 up) a Phoenix mote
  crossed the Panda's cheek: the mote timing only clears each pet's own face.

**A2 (TH2, 2026-11-14; the builder's defaults rebuild draft L, the release candidate below).** Draft H: **Stage 14 (Laser Lab)**, square on to the lane like the
game's own side camera (26 studs out instead of 45), at run time **T 0.78 s**: Sweeper1's east arm 35° below level and coming
down, Beam3 and Beam4 (the two just passed) on, Beam1 and Beam2 off; the player (look `updo`, pose `leap`, yaw -112, the head
turned to the camera) mid-leap with her leading foot just over the arm's tip, the **Dog uid 4 at Lv 12** (its cap; Wings)
flying behind her. Lab space: origin on the floor under Sweeper1's hub, +X along the course (screen right), +Z to the camera.
- **The lab is not dark.** As built it is a sand-blue panel and white floors (STAGES.md §7.12), so by day the beams read as red
  sticks on a light wall. Preset **A2** is night (ClockTime 21) with a raised ambient (darker hid rig and pet) and a narrow
  key spot on the player from the set (a wide one lit a pale disc on the panel). The navy panel then carries the neon.
- **Every hazard is at one real moment:** the beams take `KitMath.Window` at T, the sweepers `Speed * T + Phase` (both are
  RunSeeded), so the frame is a moment a run really shows; the beams' blink means the two outer beams are never on together.
- **Pet:** the Dragon at Lv 18 (draft A) is purple and vanished against the night panel; the Dog is warm brown, unused by the
  other sets, and its Wings let it fly behind.
- **Logo** (dark version, cream rims) top left at 30 % over the grid's dark ceiling; aiming the camera a little higher kept
  Beam4's top from running under HAR (draft G).
- Drafts `docs/art/thumbnails/drafts/`: `a2-e(-logo).jpg` + `-tiles.png` (30 studs out: floor, both lit beams, rig and pet
  small), `a2-f-logo.jpg` (22 out: big faces, no floor, one beam), `a2-g-logo.jpg` (26 out, Beam4 under the logo),
  `a2-h(-logo).jpg` + `a2-h-tiles.png`.
- Tile test of H (320 / 200 / 150 px, by Claude): the player's face, the orange top, the Dog and the red arm read at 150 px;
  only Beam4 is in frame (Beam3 is just out); the neon is flat red because Bloom does not render in Edit grabs (a Play
  capture would show the glow); the lower right is empty panel.
- **Other parts of Stage 14 (2026-11-14, scouted at preset A2):** `a2-scout-1..5.jpg`. The finale's 34-stud jump over the
  red laser floor is the most dramatic but needs a high camera (side-on the floor leaves the frame; from above the lane's open
  front and the sea show); the beam grid corridor frames the player large under a dark ceiling; the teal key reads but is
  calm; the Vault overview and the colour shaft are too busy or need explaining at tile size (the green key is 1.8 studs).
- **Draft L, the Vault switch (the user's idea):** the jump from `Switch_Lane1` (blue, on `Block_Float2`) up and left toward
  `Block_Float1` and `PlatformA`, group `Vault1` shown pressed: the wire lit neon green from the button up and across the
  top, `Bar_Lane1` a ghost; the floor spike row bottom left, `PlatformA`'s spiked end top left, the Dog following from the
  button; now the builder's defaults. H rebuilds with `{ ORIGIN = Vector3.new(-594, 78, -585), COLORS = {}, MIRROR = false,
  RIG_AT = Vector3.new(-9.5, 0, 0), GROUND = 8.2, RIG_YAW = -112, PET_AT = Vector3.new(-15.5, 9.4, 0.5), PET_YAW = -130,
  KEY_AT = Vector3.new(-6, 13, 16), CAMERA = Vector3.new(-12.5, 9.2, 26), LOOK = Vector3.new(-12.5, 8.7, 0) }`. Files `a2-l(-logo).jpg` + `a2-l-tiles.png`;
  `a2-k-logo.jpg` was closer (33 out), but the 16:9 band cut the spikes and the logo (top right) sat on the wire. Tile test
  (by Claude): reads as a 2D platformer level (blocks, the lit wire, the button, spikes) with the player and the Dog; the
  player is smaller than in H and the only neon is the green wire, so it is calmer than H's red arm; the logo top left
  overlaps the wire and the platform's corner but stays readable.
- **Release candidate (2026-11-14, the user's call: draft L; final after the grid tile test and the kid test, §8 TH1).** The
  builder's defaults. Files in `docs/art/thumbnails/`: `a2.jpg` (1920×1080, dark wordmark top left at 30 %, the upload) and
  `a2-clean.jpg`; the 512×512 squares: `a2-square.jpg` (wordmark at 44 % top left, across the lit wire), `a2-square-mark.jpg`
  (pawprint mark at 20 %), `a2-square-clean.jpg` (1330×1330 master). Square camera: L's side-on line of sight, closer and
  narrower, on the player, the Dog and the button (lab space {-6, 6.7, 33.8} look {-6, 6.7, 0}, FOV 40; cam {-332.40, 92.85,
  -618.80} look {-332.40, 92.85, -585.00}); the floor spikes fall outside it, the spike on the switch block stays. Grabbed with
  `-Rect "726,323,1968,1330" -Aspect 1:1`: at height 1360 the view gizmo's green "Y" showed at the bottom edge.

**A1 (draft N, 2026-11-15, TH2; the builder's defaults rebuild it).** **Stage 15 (Rising Tide), Dash Run's 34-stud Long Dash gap
D1 -> D2**, the tide risen to 137.5 (5 under D1's top: about 14 s behind a clean run from 1303), the player (look `updo`, pose
`dash` mirrored, yaw 122) near the end of the dash, 2 studs above **D2's stud top, which fills the lower left with Stage 15's
gold coin on it** (the user: without the landing "a happy player jumping into lava"), the **Dragon uid 1 at Lv 18** (its cap;
FlameTail) trailing at draft K's distance (the user's pick) and fully in frame, the garden island beyond the lava. Camera
20 studs out on the course's east side, 8.5 above the pillar-top level, looking west-north-west along the line jump ->
garden and down onto D2 (look-at {-3.5, 5.7, 0} from the player), FOV 42, rolled -7°; Stage 14 hidden while shooting (`HIDE`: its lab panels stood as grey slabs
behind the Dragon; `LocalTransparencyModifier`, reset by `stash`); preset **A1** (ClockTime 7: a low warm sun to camera-right lights her face and
the island; thin haze so the island stays clear, a warm decay so the horizon reads gold). Logo top left at 30 % over the sky.
- **The real view does not work** (drafts `a1-a`..`c`): the Laser Lab's back wall (Stage 14 BeamHall, z -581, y 62-136) lies
  on the line from Stage 15 to the garden's centre and covers half the island from anywhere in Stage 15; from the Shore the
  line runs through Stages 13 / 14. Edit draws no plots (PlotView runs on clients), so the island was a bare green disc. And
  the island shows above the lava's far edge only while the camera stands well above the lava (a low camera loses it).
- **The garden copy (the user, 2026-11-15):** Workspace.Garden cloned (scripts, labels and prompts removed), the 12 ring-1
  plots drawn by PlotView at `mid` detail with ripe crops (corn, pumpkin, pineapple, giant melon, sweet potato, a golden
  carrot now and then; no Sunflower: draft art), cut at the sea (y 0), then scaled by k and moved to camera + k x (island -
  camera), k = 420 / distance: from the camera it is the real island, now in front of the Laser Lab. Drawn 1.8x bigger
  (`GARDEN_SIZE`, about its centre at the waterline). Its waterline is a plane far above the real sea, so without water the
  island floated: a sea disc (DebugBaseplate's material and colour, radius 2000) sits at the copy's waterline.
- **The lava (the user: flat orange was not appealing):** the real tide got a `CrackedLava` crust (STAGES §7.13), which KitTide
  moves and hides with the slab; CrackedLava alone was dark rock (a dark floor can read as walkable), over the Neon at 0.15 it
  reads as red-hot crust with glowing cracks.
- Drafts `docs/art/thumbnails/drafts/`: `a1-a`..`c` (the real view: flat lava, island half hidden), `a1-h(-logo)` + `-tiles`
  (first composition with the copy: the Laser Lab corner and Studio's view gizmo at the edges), `a1-i` (closer: heads cut),
  `a1-j(-logo)` + `-tiles` (the defaults), `a1-k(-logo)` + `-tiles` (`PET_AT {7.5, 6.6, -6}`, `PET_YAW 135`: the Dragon
  covers more of the Laser Lab corner but stands on the island instead of flying behind her), `a1-l(-logo)` + `-tiles`
  (reframed onto D2: the landing shows; the Dragon cut by the right edge, Laser Lab panels behind it), `a1-m` (Dragon moved
  in), `a1-n(-logo)` + `-tiles` (Stage 14 hidden: the defaults). M and N were grabbed with L's camera still on (look-at
  -3.5, not the -2.8 they were built with: stale grabs, §9 tools), so the defaults use -3.5; the release candidate matches N.
- Tile test of N (320 / 200 / 150 px, by Claude): the player, the Dragon, the island, the coin and the wordmark read at 150 px;
  D2's sand top reads as the floor she lands on; the lava is a red band between it and the island.
- **Release candidate (2026-11-15, the user's call: draft N; final after the grid tile test and the kid test, §8 TH1).** The
  builder's defaults. Files in `docs/art/thumbnails/`: `a1.jpg` (1920×1080, light wordmark top left at 30 %, the upload) and
  `a1-clean.jpg`; the 512×512 squares: `a1-square.jpg` (wordmark at 44 % top left, over the sky), `a1-square-mark.jpg`
  (pawprint mark at 20 %), `a1-square-clean.jpg` (1360×1360 master). Square camera: N's camera, wider and turned right so the
  coin, the player, the Dragon and the island fit (`FOV = 50, LOOK = R + {-0.6, 5.2, 0}`; cam {-132.38, 152.00, -245.59} look
  {-150.35, 148.70, -254.38}); D2's corner fills the lower left. Grabbed with `-Rect "726,323,2237,1360" -Aspect 1:1`.
- Grabs: Studio's viewport is now 2237 x 1520 physical pixels at 726, 323 (re-read after the panel layout changed);
  `-Rect "726,323,2237,1360"` keeps the view gizmo out of the 16:9 band.
