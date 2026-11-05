# Pawvest — garden and pet UI redesign (U1–U5)

*Proposed 2026-11-05 from the user's notes, all open decisions settled the same day (§12); nothing built. Built UI as it is today: GDD §7.5–7.9, LAYOUT.md
(PetsPanel, PetDetail, PlotView, FieldClient, IncubatorClient). When a piece ships, its as-built design moves to GDD and this file shrinks.*

## 1. Problems
| # | Problem (user, 2026-11-05) | Where it comes from in today's build |
|---|---|---|
| 1 | The plot's state needs the big Garden panel; the square only offers two prompts | `PlotView:buildSquare` draws a crop block in 3 stages, no time; `FieldClient`'s Garden panel holds everything else |
| 2 | Squares are close together | 5.5-stud pitch, 2 prompts per square (plant / harvest + pet, range 6): neighbours' prompts compete, the nearest wins |
| 3 | Pet placement and its effect are not visible | reach shows only while placing (`ShowReach`); the pet label carries the job levels as text |
| 4 | Garden upgrades and tools are buried in the Garden panel | `BuyUpgrade` / `BuyTool` need the own plot (`usableField`) |
| 5 | "Go to my garden" hides in the Pets panel | `PetsPanel` `gardenButton` → `GoGarden` |
| 6 | No place that shows the crops held | barn = a section of the Garden panel |
| 7 | Incubators take the front of the plot | `INCUBATOR_SPOTS` across the 40 × 16 strip in front of the field |
| 8 | Pets list: XP as numbers, aptitudes as small grey text, Sell too prominent, "i" badge unclear, panel narrow | `PetsPanel` rows: `pet.xp` text, `pets.tending` suffix, Sell brick on every row, `WIDTH = 340` |

## 2. Principles
- **See before you open.** Everything a player checks often (time left, what is ripe, which pet works where) shows in the world; panels are for
  decisions (buy, sell, choose).
- **One thing under your finger.** The player picks a square by tapping / clicking it, never by standing next to it. No overlapping prompts.
- **One place per kind of thing:** crops held → barn, seeds bought → seed stall, permanent upgrades → Skills, a pet → its pet page.
- **Kid on a phone** (K1, GDD §11): icons, bars and rings over numbers; numbers on hold / hover / second tap; tap targets ≥ 44 px.
- Comfort that is planned for sale stays for sale: no harvest-all (Wheelbarrow, D2), no instant grow.

## 3. Field: see without opening anything (distance tiers, own plot)
| Tier | Distance from the own plot | Shows |
|---|---|---|
| Far | ≤ 120 studs (and from the plaza) | a **summary bubble** over the name sign: `🧺 4 ripe · ⏱ 2:14 · 🥚 Ready!` (only the parts that apply; nothing growing → `🌱 Plant seeds`) |
| Near | ≤ 30 studs | a **ring over every planted square**: a pie that fills as the crop grows, crop icon inside; ripe = full ring that bounces with a ✓; the 4 squares nearest the player also print the time (`2:14`) |
| Focus | the selected square (§4) | white outline + the square card |

- Other players' plots show only the sign and the 3D crops (no rings): less clutter, cheaper. Their summary bubble could show Renown and the
  biggest crop instead (social, optional).
- Cost: at most 36 ring billboards, own plot only, updated once a second from `GetServerTimeNow` (the incubator countdowns already do this).
- Rings work without reading and for colour-blind players (shape + icon, not only colour).

## 4. Field: acting on a square
**Decided (the user, 2026-11-05): tap a square + a square card + hand modes** (a light version of Stardew-style tools; no Roblox `Tool` objects).
- Tap / click a square of the own field (raycast, within 40 studs of the plot; the server keeps its distance check) → it gets an outline and a
  **square card** slides up at the bottom: crop name and icon, a progress bar with the time left (exact time in the bar), growth boosts
  (Growth upgrade, Cloches), **which pets reach it** (portrait chips with their job icon, tap → pet page), and context buttons: Plant / Harvest
  / Place pet / Move pet / Buy square (with price and Renown).
- **Hand bar** (only while in the own field, above the jump button on phones): `🌱 Seeds` · `🧺 Basket` · `🐾 Pets` · `✋ Look`.
  - Seeds: pick a seed once (the picker shows count held), then every tap on an empty square plants it; the bar shows the seed and the count.
  - Basket: every tap on a ripe square harvests it (one per tap; harvest-all stays the Wheelbarrow, D2). A pop `+1 Corn · Big!` flies to the
    barn.
  - Pets: tap a pet → it lifts, its reach follows the finger as a yellow tint, tap a square to drop it; tap a free square first → a pet
    picker (Tending / Pest-control pets, with job levels).
  - Look (default): tap = select + square card.
- The square prompts go away (`PetPrompt`, plant / harvest, locked-square buy); incubators keep theirs (3, well apart) until §7.
- Later, only if U3's phone check shows players missing squares: a **field camera** button that tilts the camera down over the own field (easier to tap the right square on a phone).

*Rejected:* prompts with `Exclusivity = OneGlobally` and the card on trigger (fixes density only, not the repeated planting).

## 5. Pets on the field
- A placed pet's reach stays visible in the Near tier as a **soft border in the pet's rarity colour** around its squares (several pets: the
  strongest per job, as the rules count it).
- The pet's label shows job icons, not text: `🌱4 🛡2` (Tending 4, Pest control 2), and on the field **never the pet level**: with P4 the
  level (and size) can come from Cuteness, so a big pet may be a weak tender.
- The square card says what the pet does there in one line: "Mochi harvests 60 % of ripe crops here while you are away", "Rex chases crows:
  70 %"; the chip opens the pet page.
- The pet page gets **"Show on field"** (marker + camera hint to its square) and, in the garden, **"Place on field"** (opens Pets mode with this
  pet in hand). Moving field pets from far away stays open (EXPANSION §3).

## 6. Splitting the Garden panel
| Today in the Garden panel | Goes to |
|---|---|
| squares, countdowns, seeds to plant | the field itself (§3, §4) |
| barn: seeds held, crops held, Sell | **Barn** building on the own plot (§7): shelves / crates that fill visibly; panel with seeds, crops (size, record), Sell / Feed |
| seed shop, market cart | **Seed stall** on the plaza beside the food stand (§9.1; one shop for everyone; cart offers shown on its board) |
| Growth / Barn upgrades, tools | **Skills panel, tab "Garden"** (tab "Obby" = today's talents); buyable anywhere (server: drop the plot check for `BuyUpgrade` / `BuyTool`, they are pure Coin + Renown buys) |
| field pet slots, field pets | Pets panel (slots as a line under the equip slots) and the hand bar's Pets mode |
| Renown, crow forecast | Skills → Garden tab header (Renown bar) and the summary bubble / barn board (forecast) |
| join notice | stays (grows into the E5 ledger) |

## 7. Plot layout
Today the front strip holds the sign and three incubators across. Proposed: **hatchery** (3 nests under one small roof) on the left of the
strip, **barn** on the right, the sign raised over a **path** in the middle into the field. The field becomes the first thing seen from the
plaza.
- Free-to-move incubators / barn: not now. Moving objects needs a placement system, saved positions and collision with the field; it belongs
  to the Estate drop (decor placement, D9, E7). The fixed layout keeps the slots that drop can use later.
- The hatchery panel gets K1's proposed egg cards (picture, price, time; odds behind "?"; reveal on hatch). P4's reveal lists the rolled
  traits as text; U5 shows them as chips one by one (a cute pet is a lucky roll: worth its own moment).
- Studio check: plots stand 9 studs apart; the barn and hatchery stay inside the plot's 40-stud width.

## 8. Getting there
- A **🌱 Garden** button in the top-left icon row (after Pets): teleports to the own plot (`GoGarden`, as today); removed from the Pets panel.
- Its **badge** counts what waits: ripe crops + ready eggs (G1's `PetsGarden` dot moves here).
- In the hub, a signpost at the bridge already points to the garden; G1's markers can point at the own plot when something is ready.

## 9. Pets panel and pet page
*Builds on P4 (pet traits, built 2026-11-05, GDD §7.3–7.4): no single pet XP any more; every trait has its own level 1–10, the pet's level =
its highest working trait, food and obby XP go to Cuteness (or, without it / at its cap, the lowest working trait below 5). P4 already
built: a trait card per working trait on the pet page (for every player; work traits are "for later" without the field), the row's text
line "Cuteness XP 23 / 147", no bonus line for a pet without Cuteness, the food stand per trait (§9.1), the traits in the hatch reveal.*

**Row** (left → right): portrait with a **level badge** (`6` = the pet level) and status corner icon (✓ with you, 🌾 on the field, 🏠 pen) ·
name in the rarity colour · **trait chips**, one per working trait: icon + level in the trait's colour (💗 Cuteness, 🌱 Tending, 🛡 Pest
control, 🔭 Scouting) with a thin **progress fill** along the chip's bottom edge (XP / time to the next level on hover / hold, as on the pet
page; work-trait chips greyed for players without the field, as the pet page's "for later") · **Equip toggle** brick · **Details ›** brick.
- No separate XP bar: with P4 the pet level only moves when its highest trait does, so one bar would sit still while food raises another trait.
- The chip that food and obby XP train now gets a small ▲ marker; a pet with nothing left to train shows P4's "✔ Trained" tag instead (food refused).
- The summary line names where the Coin bonus comes from: "Coin bonus +12 % · 2 cute pets with you"; a non-cute pet in a slot adds nothing
  (Scouting may still be why it is there).
- Tapping the row no longer equips (kids toggled pets by accident while scrolling); Equip is its own brick (decided 2026-11-05).
- **Sell leaves the row**: only on the pet page, at the bottom, a small grey brick with the two-tap confirm.
- **Width** 340 → 460, capped to the screen (viewport width − 2 × 16 − the icon column), and still scaled by `PanelFit` on short screens.
- **Filter chips** over the list: All · With me · On the field · Best for… (Coins = Cuteness / Tending / Pest control / Scouting); 50 pets do
  not fit one scroll.
- Pet page: Sell moves down under "More"; adds "Show on field" / "Place on field" (§5); P4's trait cards stay, the trained one marked as in
  the row.

### 9.1 Food stand (plaza)
The kiosk itself stays (four-sided, readable from every plot, built 2026-11-05). **Built in P4:** each row names the trait food trains now
and its XP, the food tooltip previews the result ("Owl Lv 6 · Cuteness → Lv 8", XP wasted), a pet with nothing to train shows "✔ Trained"
instead of the food buttons. **Left for U1:**
- The same row as the Pets panel (portrait, level badge, trait chips with fills); the **chip the food will train is highlighted** instead of
  the text line.
- Order: pets with you first, then the rest that can still grow; "Trained" pets at the bottom, greyed.
- The seed stall (§6) stands beside the food stand (decided 2026-11-05) as its own stall, not part of the kiosk; Studio check: the food
  stand's counters stay reachable and readable from the plots on that side.

## 10. Other improvements
- **Feedback for every action:** a pop where it happened (crop to the barn, Coins to the counter, XP to the pet), not only a toast.
- **One confirm pattern** for every spend over ~1 000 Coins and for Sell: two taps with the button turning orange ("Tap again"), as the food
  buttons do; hold prompts only in the world.
- **Next-step hint in the garden** (G1 / E5 onboarding builds on §4, so §4 comes first): an empty field points at Seeds, a ripe one at the Basket.
- **Locked squares** look different from empty soil (overgrown + a small price tag only when selected), no prompt per locked square.
- **Panel focus:** opening one panel closes the others (Pets, Skills, Barn, Seed stall, Food); panels close when walking away (32 studs, today
  only the Garden panel).
- **Phone check** of every new piece is part of its milestone (MU's checklist), Czech widths included.

## 11. Milestones (each ships alone; scope with acceptance checks when it starts)
| Id | Content | Depends on |
|---|---|---|
| U1 | Pets panel, pet page and the food stand panel (§9, §9.1) | P4 (built; its open pseudo-language / multi-client checks can run with U1's, same files) |
| U2 | Garden HUD button + badge, summary bubble over the own sign (§3 Far, §8) | – |
| U3 | Field interaction: rings, tap-select, square card, hand bar, pet reach borders, prompts removed (§3 Near, §4, §5) | field access |
| U4 | Panel split: Skills → Garden tab, Barn panel, Seed stall; Garden panel removed (§6) | U3 |
| U5 | Plot layout: hatchery left, barn right, path; K1 egg cards (§7) | U4 (barn) |

Order proposed: U1 before M6a; U2–U5 before E5's onboarding (it teaches the new controls) and before E1 ships.

## 12. Decisions (the user, 2026-11-05)
1. ~~Square interaction~~ — decided 2026-11-05: tap + square card + hand bar (§4).
2. ~~Pets list row~~ — decided 2026-11-05: an Equip brick + a Details brick; a tap on the rest of the row does nothing (§9).
3. ~~Barn~~ — decided 2026-11-05: on the own plot (§6, §7).
4. ~~Field camera button~~ — decided 2026-11-05: not in U3; built only if U3's phone check shows players missing squares (§4).
5. ~~Seeds~~ — decided 2026-11-05: a seed stall on the plaza, with the market cart offers on its board (§6), beside the food stand
   (§9.1).
