# Glow Mushroom growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../ROADMAP.md)

## Selected design

Ales chose a **glowing chestnut bolete pair** (CG9, 2026-11-09), after a first trio of gilled mushrooms: his porcini photo showed that
the epic crop should be a bolete, and he picked option 3 of three bolete studies (chestnut trio, indigo trio, chestnut pair).
Rejected: the gilled trio, tall lanterns and a giant single cap ([first studies](../art/glow-mushroom/ripe-studies.jpg)), and the
bolete trio variants ([wide](../art/glow-mushroom/bolete-studies.jpg) · [trios](../art/glow-mushroom/bolete-closeup-trios.jpg) ·
[pair](../art/glow-mushroom/bolete-closeup-pair.jpg); left to right chestnut trio, indigo trio, chestnut pair).

The rare World 3 crop (stored ID `GlowMushroom`, 10 h, teal `g` in `PlotView.CROP_COLORS`). It is an annual: harvest clears the
whole square. A big bolete (about **4.3 studs** tall at standard mass, below the 5.46-stud avatar), a smaller one beside it, and two
small buttons. The group stays inside the shared **2.4-stud ground radius** at every age, seed and size.

Bolete cues: a fat **barrel stem**, widest in the lower third, pale grey-cream; a thick convex **chestnut cushion cap** with a thin
pale rim line; a pale **pore layer** (not gills) under the cap, wider than the stem. No spots on the cap.

**Ripeness cue:** the pore layer is ordinary pale plastic while growing and switches to a bright **Neon** teal glow in the last fifth
of growth (82–98 %). No light instances: the glow is the material only, so a 36-square field adds no light cost.

## Growth and harvest

Ales approved the five stills on 2026-11-09.

[0%](../art/glow-mushroom/growth-0.jpg) · [20%](../art/glow-mushroom/growth-20.jpg) · [50%](../art/glow-mushroom/growth-50.jpg) ·
[75%](../art/glow-mushroom/growth-75.jpg) · [100%](../art/glow-mushroom/growth-100.jpg)

| Growth | Review pose |
|---|---|
| 0% | Two squat pale buns on short stubs and a smaller button. An unplanted square stays bare. |
| 20% | The stems start to swell and lengthen; the caps are pale, rounded buttons that begin to widen. |
| 50% | Pale barrel stems and chestnut convex caps, the cap darkening; the pore layer shows as a pale band under each rim. |
| 75% | Big cap spread and nearly flat on its tall stem, the small one beside and below it; pores still pale, no glow. |
| 100% | Full chestnut cushions at two heights; the pore layers and buttons glow bright teal. |

Boletes grow as a **button**, not as a stalk that opens an umbrella: the cap is there from the start and widens, rises and flattens
(its layers go from a rounded to a flatter profile) while the stem swells and lengthens, wider as it grows. The big one finishes
last. Caps darken from pale tan to chestnut as they open. The pore layer thickens as the cap spreads. Growth is continuous and
reversible; a 43→44→43% seek restores the identical pose.

Seeded variation changes the height ratio (six tendencies: bigger / smaller pair), stem positions and lean, cap radii, tilt and
yaw, and the growth timings (small delays). Seed 1 is the authored baseline; the plant can rotate through a full circle. New random
draws go **last**. The small cap stays clear of the big cap's underside, with a tilt allowance.

Harvest mass (cube root `ds`): **light** harvests scale the whole plant evenly (down to 0.71 at the smallest); **heavy** harvests
grow **taller and thicker** (height and cap thickness up to ×1.3, stems up to ×1.15) but **never wider** than the square; the
tallest cap top is capped at 4.8 studs. Production duration remains **ten hours**; harvest clears the whole square.

## Recipe and fruit identity

[`GlowMushroomPlant.luau`](../../src/ReplicatedStorage/GlowMushroomPlant.luau) uses `PlantKit` and is registered in `PlantGrowth`.
The full plant reuses **60 Parts**: two boletes of 25 (barrel stem 10, pores 2, rim 2, cap 11) and two 5-Part buttons. A 36-square
field uses **2,160 plant Parts** before soil, pets or UI. Direct-built mid proxies use **4 / 8 / 12 Parts** for young / growing /
ripe plants (one stem block, one or two cap blocks and the pore layer per bolete; the buttons only when ripe); low detail hides crop
art. Nominal ring height is **5.0 studs**, scaled by harvested mass's cube root; `ReviewHeight` is 4.8.

The pore parts are `Plastic` (stud variant) until the glow starts and `Neon` after; the recipe switches them, no other Part uses Neon.
`fruitSlots[1..2]` hold a stable ID, the mature world-space stem-top attachment and all 25 Parts of that bolete (`PlantRole` `Fruit`,
`FruitSlot` = the slot). The two buttons are `Structure` (the mycelium bed a future perennial would keep). Visual slots do not
define reward quantity or implement collection.

Studio checks (2026-11-09): six seeds × harvest factors **0.3566 / 1 / 3.0298** × 101 ages fit within **2.33 studs** ground radius,
and the ripe pose is always the widest. Ripe height is **2.76–4.85 studs** (4.33 at seed 1, standard size). The small cap clears
the big cap's pore layer by at least 0.08 studs. The 43→44→43 seek restores the same pose, and the pore material, in every case.
Through the real `PlotView` path three plants build 180 Parts at full detail, 24 as mid proxies and none at low detail. A playtest
boot logged no errors or warnings. Real-phone, full-field / 24-plot performance and second-client checks remain open.
