# Pepper growth art

[Shared authoring and Studio player](../PLANT_GROWTH.md) · [Status](../PLANT_GROWTH.md#crops-and-status)

## Selected design

A **slender, pointed red chilli** (Ales's corrected reference; replaces the original lobed bell-pepper fruit, which is not the target for
new work). Keep stored id `Pepper`, its localized name and three stable fruit slots; the crop icon is 🌶️.

Free-standing upright forked bush, no pole: two unequal upper arms and a shorter side shoot carry pointed oval leaves, with gaps around
the hanging fruit. Baseline about **3.38 studs** tall (avatar 5.46); every pose inside the 2.4-stud radius; coloured stud-block style.

**Chilli fruit:** a narrow body hangs from a small green calyx and bent stalk; no square shoulders, longitudinal lobes or blunt bell tips.
The body follows a connected six-section curve narrowing to a real wedge-shaped point (shoulder ~0.34 studs, vertical reach ~1.55, a
sideways hook near the tip). Two peppers curve one way, the third the other; seeds vary bend, slenderness, length. New random draws are
appended after the existing bush parameters so the fruit does not reroll a planting's foliage identity. All three finish red:
green → orange → red, increasing length and a filling upper body communicate ripeness.

## Growth

[0%](../art/pepper/growth-0.jpg) · [20%](../art/pepper/growth-20.jpg) · [50%](../art/pepper/growth-50.jpg) ·
[75%](../art/pepper/growth-75.jpg) · [100%](../art/pepper/growth-100.jpg)

| Growth | Pose |
|---|---|
| 0% | Tiny planted sprout with two folded leaves; unplanted soil stays bare. |
| 20% | Short upright stem, two pointed leaves opening at different heights. |
| 50% | Unequal arms extend, leaves unfold in tiers, small white flowers open at the three fruit attachments. |
| 75% | Nearly full bush; slender green peppers lengthen and curve beneath their calyxes. |
| 100% | Three filled red chillies hang with distinct pointed hooks; fruit-bearing arms settled slightly. |

Stems extend from their current parents, leaves unfold at attached bases. Five-petal white blossoms contract and turn green into the
calyx as fruit sets at the same attachment; the fruit lengthens, curves and fills toward its upper end. Continuous and reversible.
Seeds vary height, arm balance, lean, leaf angles, fruit proportions / timing; full-circle rotation. Harvested mass (Sorter included)
scales fruit by its cube root; foliage vigor and spread constrained; large fruit can raise the bush to keep soil clearance. Annual:
harvest clears the square.

## Recipe and fruit identity

[`PepperPlant.luau`](../../src/ReplicatedStorage/PepperPlant.luau), `PlantKit`: **84 Parts** (seven stems, 35 leaf plates, three 14-Part
fruit/blossom groups); 36-square field 3 024. Mid proxies **5 / 31 / 31 Parts** keep the curved pointed fruit; low detail hides crop art.
`PlantKit` accepts an optional `WedgePart` class for pointed tips. Nominal ring **4.4 studs**, mass-scaled (cube root). Crop art does not
intercept selection rays. Each `fruitSlots[1..3]`: stable id, mature world-space attachment CFrame, 14 Parts (two stalk pieces,
centre/calyx, five petals/sepals, five body sections, one pointed wedge); `PlantRole` / `FruitSlot` attributes. Visual slots do not
define reward quantity or perennial collection. Max radius 2.04 over seeds / masses (0.3566 / 1 / 3.0298), ripe height 2.91-4.73, fruit
clearance at least 0.34. Open: revised art review (stills), performance, real phone, second client.
