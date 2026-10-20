# Style preview: voxel and pixel art vs stud (pending review)

Status: **parked for a later review** (2026-10-20). No style was chosen; the stud style (H1 / H1.1 / H1.2) stays live.
The decision is open: keep stud, or roll out one of the variants below to the rest of the world.

## Where the previews are

- Studio-only folder **`ServerStorage.StylePreview`** (no scripts, so Argon does not sync it). It exists only in the place
  file: it is kept after the place is saved (Ctrl+S / publish).
- To review: drag the folder into `Workspace` (it is positioned for that: a grass platform 220 × 110 in open sea at
  (-750, 16, -950), between the garden and Stage 1, fronts facing +Z), look around, then drag it back to `ServerStorage`
  before publishing, so players never see it.
- Layout: gate row at z -975, portal row at z -925; columns x -830 stud reference, -790 Voxel A, -750 Voxel B,
  -710 Pixel A, -670 Pixel B. Every model has a floating label (`Anchor.PreviewLabel`).
- Everything is Anchored with CanTouch / CanQuery off. Delete the folder when the decision is made.

## The test pieces

- **Start gate** (H1.2 `LandingPad.StartGate`): two pillars, beam and the sign with the stage name over `TimerStart`.
  Every variant keeps the 22-stud opening and has nothing at ground level except the pillars.
- **Hub portal** (H1.1 `StartLocation.TeleportToStageN`): arch + `Portal` face 7.1 × 10 × 1.5, translucent blue.
  Every portal preview carries a mock of everything the face can show at once (stage name, stars, both lock lines,
  "found 2/9", see `HubPortalMedals.client.luau`) to check the room inside the opening.

## Variants

| Variant | Technique | Gate parts | Portal parts | Notes |
|---|---|---|---|---|
| Stud (current) | clones of the live gate / portal | 23 | 36 | reference |
| **Voxel A**, classic | 2-stud cubes, SmoothPlastic, per-block colour jitter instead of textures; cobblestone pillars (moss at the base), oak log beam, plank sign, torches (Neon + PointLight); stone-brick portal frame with glowstone corners | 115 | 23 | reads as Minecraft; pillars a bit muddy in shadow |
| **Voxel B**, chunky toy | 4-stud cubes, bright palette; cream pillars on terracotta, red beam, leaf blocks, white board sign; purple portal frame with glass crystals | 30 | 14 | cheapest 3D option, friendly, close to the pet models; near plain shapes at this block size |
| **Pixel A**, pixel slab | front-facing sprite of 1-stud pixels, 1 stud deep, one part per horizontal colour run; ~10-colour palette, dark outlines | 127 | 89 | sprite look from the front, has shadows and collision; thin from the side |
| **Pixel B**, sprite board | one transparent board, the sprite drawn as SurfaceGui Frames on both faces (`LightInfluence` 0); portal face dithered | 1 | 1 | cheapest, most "real" pixel art; no shadow, no collision, fades at a distance; text over the dithered face is busy |

All text in the voxel and pixel variants uses the built-in pixel font
`Font.new("rbxasset://fonts/families/PressStart2P.json")`. No textures or assets were uploaded.

Screenshots (taken 2026-10-20): [overview](style-preview/00-overview.jpg); gates
[stud](style-preview/01-gate-stud.jpg), [Voxel A](style-preview/02-gate-voxelA.jpg),
[Voxel B](style-preview/03-gate-voxelB.jpg), [Pixel A](style-preview/04-gate-pixelA.jpg),
[Pixel B](style-preview/05-gate-pixelB.jpg); portals [stud](style-preview/06-portal-stud.jpg),
[Voxel A](style-preview/07-portal-voxelA.jpg), [Voxel B](style-preview/08-portal-voxelB.jpg),
[Pixel A](style-preview/09-portal-pixelA.jpg), [Pixel B](style-preview/10-portal-pixelB.jpg).

## Findings

- The portal face has room for all lines in every variant.
- Press Start 2P is very wide: long lines (the lock line "Silver on Stage 1") shrink a lot with `TextScaled`. Using it on
  the real portals needs shorter lines or two lines in `HubPortalMedals.client.luau`.
- SurfaceGui text disappears at overview distance in Studio captures; judge readability from a player's distance.
- Sprite boards (Pixel B) need invisible collision parts for pillars and look pasted on without a shadow.

## Rollout notes (if a style is picked)

- **Voxel** (A or B): islands as stepped block layers (grass / dirt / stone) with same-colour runs merged into larger
  parts and jitter only at the edges (a whole island block by block would be thousands of parts); trees, hedges,
  flowers, signs and board frames from a code-built `VoxelKit` in `ServerStorage` (built once via the Studio MCP),
  replacing `DecorKit`. The 4 gates + 4 portals at Voxel A density are about 1 000 static anchored parts, fine for 12 players.
  The block-built pets already fit.
- **Pixel art**: suits front-facing props, signs, boards and the UI; hard to apply to ground and islands without pixel
  textures (would need image uploads) and clashes with 3D characters and pets seen from the side.
- Recommendation made at the preview: **Voxel A for the world, pixel art as an accent on signs, boards and UI.**
  A picked style becomes a ROADMAP milestone (design check → kit → hub → pads → garden → Studio validation).
