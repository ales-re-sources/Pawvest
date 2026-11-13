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
Variants inside a theme differ in subject, camera or place, not only in colour. Pets are at max level (Lv 10: two accessories,
PetLook tier effects); uids are picked for the best accessory roll (no crown on Bunny / Fox / Phoenix).

### A — Action: "Run it, grow it" (for obby players)
The player in motion with one pet; saturated, fast, tilted camera.
| # | Subject | Camera / light | Pieces |
|---|---|---|---|
| A1 | One jump over World 3 lava (Rising Tide) with a Dragon trailing; the garden as **one glowing island** behind (no split frame) | low, from the side of the jump; lava glow in front, golden island behind | Stage 15 section, posed rig, Dragon, garden backdrop |
| A2 | Laser Lab **side-on** (the stage's own 2D view): the player mid-leap between neon beams, a pet trailing; neon on dark looks like nothing else on the page | side view, player large; dark lab, neon beams | Stage 14 section, rig, pet |
| A3 | The player landing on a stud checkpoint, **facing the camera**, with the Phoenix; a challenge coin bursting; the course with a visible hazard receding behind | very low, wide lens; bright day | checkpoint, challenge coin, course section, rig, Phoenix |

### B — Characters: "Pets on guard" (for pet lovers and defence players)
Calm and cosy, eye contact with the pet; the defence angle no other garden game has.
| # | Subject | Camera / light | Pieces |
|---|---|---|---|
| B1 | One big guard pet on its square, its reach ring glowing over ripe crops, one big Pumpkin beside it. **With D1:** two or three crows landing on the fence | at fence height, pet in the foreground; late afternoon | plot, field squares, reach ring, pet, Pumpkin (crows later) |
| B2 | Stare-down: one guard pet (Fox, Lv 10 scarf) face to face with a single crow on the fence, ripe crops soft behind. **Needs D1** | macro-close, shallow depth (DepthOfField); warm | Fox, crow, fence, crops |
| B3 | Wide plot at sunset: hatchery with a glowing egg on the left, barn on the right, pets resting among ripe Giant Melons and Sunflowers. **Experience Detail Page only** (no focal point at tile size) | high three-quarter view; sunset | plot (U5 layout), egg, pets, ripe crops |

**Crows (decided 2026-11-13):** crows are E4-thin today, a forecast and a settle roll with no bird in the world, so a crow in a
frame would break "real content only". B1 ships crow-free first; B2 and B1's crows launch with drop D1 (Critters), which is also
the update that refreshes the thumbnails (§2).

### C — Harvest: "Paw + Harvest" (for farming players and collectors)
The payoff: pets and what they grow. The most readable theme at phone size.
| # | Subject | Camera / light | Pieces |
|---|---|---|---|
| C1 | A pet pulling a glowing Golden Carrot out of the soil, **pet and carrot filling most of the frame**; the stud-built PAWVEST sign small behind | frontal, close; clean sky | pet, Golden Carrot (pulled pose), soil, sign |
| C2 | **Giant harvest:** a Giant Melon as big as the player, a pet sitting on top, the player beside it cheering | very low and close, so the melon towers; bright day | Giant Melon at the largest real size, pet, rig |
| C3 | Collection: three or four pets growing in size from a Cat to a glowing Phoenix, a crop beside each (pets do not hold crops in the game) | frontal, Phoenix dominant; bright day | 3–4 pets, crops |

**C2's size is real:** the melon is built at the upper bound of `CropConfig.SizeBounds()` (the drawn size grows with the cube
root, `PlantKit.dimension`); the camera does the rest. Never scale a crop past that bound.

**Icon (512×512):** one Lv 10 pet face (Cat with crown, or Dog) peeking over a Golden Carrot, the pawprint mark in a corner, no
words; built from C1's set, cropped square. The icon is not testable (§2); C1 doubles as the "icon-style" thumbnail.

### Logo (replaces the old C2 thumbnail)
The first plan had a thumbnail that was only a sign: PAWVEST with a letter turned into a pawprint, pawprint stamps along the
field rows, a basket of crops. Typography with no character does not earn a tap, and the idea is a logo, so it is one now.
- **Idea:** a **PAWVEST** wordmark that shows the wordplay without a sentence: **PAW** and **VEST** in two colours (paw = a pet
  colour, vest = harvest gold / leaf green) and a pawprint worked into a letter (the counter of the A, or the print pressed into
  the V). No "PAW + HARVEST" line: it is unreadable at tile size and English only.
- **Style:** stud-brick letters like the in-game signs (StudStyle), thick outline, readable on a light and on a dark frame.
- **Deliverables:** the wordmark; the **pawprint mark** alone (for the icon and small sizes); both as transparent PNG, with a
  light-outline and a dark-outline version.
- **How:** three sketches in TH0 (which letter carries the paw, the two colours), the user picks one. The letters can be built
  from stud bricks in Studio and captured, so the logo and C1's stud sign are the same lettering; the final is cleaned up in an
  image editor.
- **Where it goes:** the same corner of every thumbnail, the mark on the icon, C1's sign. Later candidates (not TH): the hub
  sign, the loading screen.
- **Checks:** the wordmark reads at tile size in a thumbnail corner; the mark reads at icon size in the Roblox home grid.
- **Dropped from the old C2:** the pawprint stamps along the rows (nothing in the game leaves them); the crop basket stays
  available as a prop.

## 5. Review of the variants (2026-11-13, judgment, not data)
| # | Who it pulls in | At tile size | Expectation |
|---|---|---|---|
| B2 | pet lovers | one face, one enemy, a conflict | the strongest idea; waits for D1 |
| A3 | obby players | one subject facing the camera, hazard behind | strong |
| C1 | farming and pet players | pet + glowing carrot | strong; also the icon's source |
| C2 | farming players (the biggest audience in the genre) | one huge crop, one pet | strong; watch the "another garden game" read (§3) |
| C3 | collectors | reads with 3–4 pets (eight were specks) | medium |
| A1 | obby and farming players | reads once the split is gone | medium |
| B1 | pet and defence players | reads with one pet; the story is thin until crows | medium, better with D1 |
| A2 | obby players | high contrast, face in profile | medium, the most distinctive look |
| B3 | cosy and farming players | no focal point | Detail Page only |

What the review changed: A1 lost its split and second pet; A2 was an over-the-shoulder shot toward a portal showing the garden
(no face, and portals do not show that); A3's hub portals became a course with a hazard; B1 went from four pets, a flock, the
player and a pumpkin to one pet; the "H as a pawprint" sign (old C2) became the logo and its slot went to the giant harvest;
C3 went from eight pets to three or four.

## 6. Test plan
- **Home Page tab** takes the single-subject thumbnails; **Experience Detail Page tab** takes the story shots: B3 plus wide views
  made from the same sets (the full field, the hub), in the order obby → pets → garden.
- **Round 1 (≥ 7 days):** pass 1's three, one per theme (A3, B1 crow-free, C1). It answers the biggest question first: which
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
- **Player:** one posed R15 rig for the whole set (`Players:CreateHumanoidModelFromUserId`), face visible and expressive, joints
  posed by `Motor6D` transforms.
- **Logo:** per §4 Logo (stud letters captured in Studio, finished in an image editor); composited onto the finals.
- **Light:** a per-set Lighting preset (time of day, Atmosphere, ColorCorrection, Bloom, DepthOfField for B2) applied by script;
  **snapshot Lighting and its children before and restore after** every session.
- **Capture:** drafts by MCP `screen_capture` with a camera CFrame, one at a time (AGENTS.md → Studio MCP habits; set
  `CameraType = Fixed` afterwards; restore a minimised window). Finals at 1920×1080 from a maximised Studio viewport with the UI
  hidden; the user, or Claude after sizing the window. Finals are stored under `docs/art/thumbnails/` (JPG).

## 8. Milestones (each scoped with acceptance checks when it starts)
Two passes: three thumbnails first, the other six only after they have been seen at tile size and by a kid.
| # | Content |
|---|---|
| TH0 | Shared pieces: the posed rig, pets at Lv 10 with chosen uids, the ripe crop set, the logo (three sketches, the user picks; wordmark + pawprint mark) and the stud sign in the same lettering, the Lighting snapshot / preset helper |
| TH1 | Pass 1: A3, B1 (crow-free), C1 and the icon. Each draft passes the **tile test** (shrunk to tile size in a grid of real competitor thumbnails) and the **kid test** (which one would the playtester tap, and what does he think the game is) before finals |
| THU | Upload; round 1 active (the user on the dashboard) |
| TH2 | Pass 2, shaped by TH1's lessons: A1, A2, C2, C3; B3 and the wide views for the Detail Page |
| THR | Round 2 after ≥ 7 days; keep the top 2–3; as-built notes here |
| THD | With drop D1 (Critters): B2 and crows in B1 |
