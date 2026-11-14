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
| A2 | Laser Lab **side-on** (the stage's own 2D view): the player mid-leap between neon beams, a pet trailing; neon on dark looks like nothing else on the page | side view, player large; dark lab, neon beams | Stage 14 section, rig, pet |
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
- **Studio-only photo sets:** `ServerStorage.PhotoSet.<A|B|C><n>` (A1…C3, Icon). No scripts, so Argon never syncs them
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
- `tools/photoset_lighting.luau`: `snapshot` / `apply` (per-set presets, `C1` so far) / `restore` / `status`. The snapshot lives in
  `ServerStorage.PhotoSet.LightingSnapshot` and refuses to be overwritten, so a forgotten restore never loses the real look.
- `tools/photoset_c1.luau`: builds `Workspace.PhotoSet_C1`, returns the camera for `screen_capture`; `stash` / `shoot` move it to and
  from `ServerStorage.PhotoSet.C1`. For iterating, its source sits in the StringValue `ServerStorage.PhotoSet.Builder_C1` and runs
  through `loadstring` with a parameter table (re-store the file after editing it). While a set is in Workspace the Studio GUI is
  hidden (`ShowDevelopmentGui`).
- `tools/photoset_b1.luau`: the same for `Workspace.PhotoSet_B1` (`ServerStorage.PhotoSet.B1`, iterating copy `Builder_B1`).
  Refuses a pet level above its kind's cap. Set-space +X is camera-left.
- `tools/photoset_rig.luau`: the player rig, a library the set builders load from `ServerStorage.PhotoSet.Builder_Rig`:
  `build` (the chosen look) and `pose` (named poses, forward kinematics down the joint chain, feet set on a given floor).
- `tools/photoset_a3.luau`: A3 in the stage itself (`ServerStorage.PhotoSet.A3`, iterating copy `Builder_A3`): nothing in the
  stage is moved; the reached pad is drawn on copies over it.
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
