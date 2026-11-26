# Glow Mushroom growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../PLANT_GROWTH.md#crops-and-status)

## Selected design

**Glowing chestnut bolete pair.** The epic crop must be a bolete (the user's porcini photo), not a gilled mushroom. Rejected: the gilled
trio, tall lanterns and a giant single cap ([first studies](../art/glow-mushroom/ripe-studies.jpg)); bolete chestnut trio and indigo trio
([wide](../art/glow-mushroom/bolete-studies.jpg) · [trios](../art/glow-mushroom/bolete-closeup-trios.jpg) ·
[pair](../art/glow-mushroom/bolete-closeup-pair.jpg); left to right chestnut trio, indigo trio, chestnut pair).

Rare World 3 crop (stored id `GlowMushroom`, teal `g` in `PlotView.CROP_COLORS`); annual: harvest clears the whole square. A big bolete
(about **4.3 studs** at standard mass, avatar 5.46), a smaller one beside it and two small buttons, inside the 2.4-stud radius at every
age, seed and size.

Bolete cues: a fat **barrel stem**, widest in the lower third, pale grey-cream; a thick convex **chestnut cushion cap** with a thin pale
rim line; a pale **pore layer** (not gills) under the cap, wider than the stem. No spots on the cap.

**Ripeness cue:** the pore layer is ordinary pale plastic while growing and switches to bright **Neon** teal in the last fifth of growth
(82-98%). Material only, no light instances (a 36-square field adds no light cost); no other Part uses Neon.

## Growth

[0%](../art/glow-mushroom/growth-0.jpg) · [20%](../art/glow-mushroom/growth-20.jpg) · [50%](../art/glow-mushroom/growth-50.jpg) ·
[75%](../art/glow-mushroom/growth-75.jpg) · [100%](../art/glow-mushroom/growth-100.jpg)

| Growth | Pose |
|---|---|
| 0% | Two squat pale buns on short stubs and a smaller button. Unplanted square stays bare. |
| 20% | Stems start to swell and lengthen; caps are pale rounded buttons beginning to widen. |
| 50% | Pale barrel stems and chestnut convex caps, cap darkening; pore layer shows as a pale band under each rim. |
| 75% | Big cap spread, nearly flat on its tall stem, the small one beside and below it; pores still pale, no glow. |
| 100% | Full chestnut cushions at two heights; pore layers and buttons glow bright teal. |

Boletes grow as a **button**, not a stalk that opens an umbrella: the cap is there from the start and widens, rises and flattens while the
stem swells and lengthens. The big one finishes last. Caps darken from pale tan to chestnut; the pore layer thickens as the cap spreads.
Continuous and reversible (43→44→43% restores the pose, pore material included).

Seeds vary the height ratio (six tendencies, bigger / smaller pair), stem positions and lean, cap radii, tilt, yaw and small timing
delays; full-circle rotation. New random draws go **last**. The small cap stays clear of the big cap's underside (tilt allowance; at least
0.08 studs).

Harvest mass (cube root `ds`): **light** harvests scale the whole plant evenly (down to 0.71); **heavy** ones grow **taller and thicker**
(height and cap thickness up to ×1.3, stems up to ×1.15) but **never wider** than the square; tallest cap top capped at 4.8 studs.

## Recipe and fruit identity

[`GlowMushroomPlant.luau`](../../src/ReplicatedStorage/GlowMushroomPlant.luau), `PlantKit`: **60 Parts**: two boletes of 25 (barrel stem 10,
pores 2, rim 2, cap 11) and two 5-Part buttons; 36-square field 2 160. Mid proxies **4 / 8 / 12 Parts** (one stem block, one or two cap
blocks and the pore layer per bolete; buttons only when ripe); low detail hides crop art. Ring **5.0 studs** (cube-root scaled),
`ReviewHeight` 4.8. `fruitSlots[1..2]`: stable id, mature world-space stem-top attachment and all 25 Parts of that bolete (`PlantRole`
`Fruit`, `FruitSlot` = slot); the buttons are `Structure` (the mycelium bed a future perennial would keep). Visual slots do not define
reward quantity or collection. Max radius 2.33, ripe height 2.76-4.85 (4.33 seed 1 standard). Open: performance, real phone, second client.
