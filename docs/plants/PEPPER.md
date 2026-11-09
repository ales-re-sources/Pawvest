# Pepper growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../ROADMAP.md)

## Selected design

Ales's corrected reference (2026-11-09) is a **slender, pointed red chilli**, replacing the original lobed bell-pepper fruit.
Keep the stored crop ID `Pepper`, its current localized name and three stable fruit slots. The crop icon is now 🌶️.
The earlier bell-fruit study is historical; it is not the target for new work.

The free-standing upright forked bush has no pole. Two unequal upper arms and a shorter side shoot carry pointed oval leaves,
with gaps around the hanging fruit. At standard mass, the baseline is about **3.38 studs** tall, below the 5.46-stud reference
avatar. Keep every growth pose inside the shared **2.4-stud ground radius** and use Pawvest's colored stud-block style.

## Distinct chilli fruit

- A narrow body hangs from a small green calyx and bent stalk. There are no square shoulders, longitudinal lobes or blunt bell tips.
- The body follows a connected six-section curve, narrowing toward a real wedge-shaped point. Baseline shoulder thickness is
  about **0.34 studs**; vertical reach is about **1.55 studs**, with a sideways hook near the tip.
- Two peppers curve one way and the third curves the other; seeds vary bend, slenderness and length. New random draws are appended
  after the existing bush parameters so the corrected fruit does not reroll the planting's foliage identity.
- All three finish red. Green → orange → red, increasing length and a filling upper body communicate ripeness.

## Growth and harvest

[0%](../art/pepper/growth-0.jpg) · [20%](../art/pepper/growth-20.jpg) · [50%](../art/pepper/growth-50.jpg) ·
[75%](../art/pepper/growth-75.jpg) · [100%](../art/pepper/growth-100.jpg)

| Growth | Review pose |
|---|---|
| 0% | Tiny planted sprout with two folded leaves; unplanted soil stays bare. |
| 20% | Short upright stem with two pointed leaves opening at different heights. |
| 50% | Unequal arms extend, leaves unfold in tiers and small white flowers open at the three fruit attachments. |
| 75% | Nearly full bush, with slender green peppers lengthening and curving beneath their calyxes. |
| 100% | Three filled red chillies hang with distinct pointed hooks; fruit-bearing arms have settled slightly. |

Stems extend from their current parents and leaves unfold at attached bases. Five-petal white blossoms contract and turn green
into the calyx as fruit sets at the same attachment. The fruit lengthens, develops its curve and fills toward its upper end.
Growth is continuous and reversible; attached stalks, leaves and fruit follow the branch's small settling motion.

Seeded variation changes height, arm balance, lean, leaf angles and fruit proportions/timing. Seed 1 is the authored baseline;
the plant can rotate through a full circle. Actual harvested mass, including Sorter, scales fruit dimensions by its cube root.
Foliage vigor and spread are constrained; large fruit can raise the bush to preserve soil clearance.
Production duration remains **one hour** and harvest clears the whole square.

## Recipe and fruit identity

[`PepperPlant.luau`](../../src/ReplicatedStorage/PepperPlant.luau) uses `PlantKit` and is registered in `PlantGrowth`.
The full plant reuses **84 Parts**: seven stems, 35 leaf plates and three 14-Part fruit/blossom groups.
A 36-square field uses **3,024 plant Parts** before soil, pets or UI. Direct-built mid proxies use **5 / 31 / 31 Parts**
for young/growing/ripe plants, preserving the curved pointed fruit. Low detail hides crop art.

`PlantKit` accepts an optional `WedgePart` class for pointed tips; existing callers still create ordinary Parts.
Nominal ring height is **4.4 studs**, scaled by harvested mass's cube root. The shared one-hour scheduler samples every
**7.5 seconds**, skips completed leaf groups and stops posing ripe plants. Crop art does not intercept selection rays.

Each `fruitSlots[1..3]` entry has a stable ID, mature world-space attachment CFrame and 14 grouped Parts: two stalk pieces,
centre/calyx, five petals/sepals, five body sections and one pointed wedge. `PlantRole` distinguishes structure, foliage and fruit;
`FruitSlot` identifies the group. Visual slots do not define reward quantity or implement perennial collection.

Studio checks (2026-11-09): six seeds × harvest factors **0.3566 / 1 / 3.0298** × 101 ages fit within **2.04 studs** ground radius.
Ripe height is **2.91–4.73 studs**, with at least **0.34 studs** fruit clearance. Attachment and backward-seek checks pass.
PlotView uses 252 full-detail Parts or 67 mid-proxy Parts for three test crops, retains plant/soil/pet on time corrections,
restores detail and clears harvested art. Other existing recipes still build, pose and destroy through the shared Part factory.
The chilli icon renders in the ripe ring; the ring, selection outline and field pet were checked together at field distance.

Revised art review, full-field/24-plot performance, real-phone and second-client checks remain open.
