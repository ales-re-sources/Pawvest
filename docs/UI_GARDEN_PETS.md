# Pawvest — garden and pet UI redesign (U1–U5)

*Proposed 2026-11-05 from the user's notes, all open decisions settled the same day (§12); U1, U2 and U3 (a + b) built. Built UI as it is today: GDD §7.5–7.9, LAYOUT.md
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
| Far | ≤ 120 studs (and from the plaza) | the **summary bubble** over the name sign: **built in U2** (GDD §7.6) |
| Near | ≤ 30 studs | rings over the planted squares: **built in U3a** (GDD §7.9) |
| Focus | the selected square (§4) | white outline + the square card: **built in U3a** |

- Other players' plots show only the sign and the 3D crops (no rings). Their summary bubble could show Renown and the biggest crop instead
  (social, optional).

## 4. Field: acting on a square
**Decided (the user, 2026-11-05): tap a square + a square card + hand modes** (a light version of Stardew-style tools; no Roblox `Tool` objects).
Tap-select, the square card and the removal of the square prompts are **built in U3a**, the hand bar (Seeds / Basket / Pets / Look) in
**U3b** (both 2026-11-07), as built in GDD §7.9; the design text is in `git show 68b9c3b:docs/UI_GARDEN_PETS.md`. The harvest pop rises
over the square (it does not fly to the barn: the barn building comes with U5). So that a player knows squares are tappable (the user,
2026-11-07): corner brackets on the square under the mouse (pointing-hand cursor) or else the one the character stands on, and Look's
hint until the first tap, are built; whether rings / pulses need more is to be discussed. Left open:
- Later, only if the phone check shows players missing squares: a **field camera** button that tilts the camera down over the own field
  (easier to tap the right square on a phone). U3a / U3b were checked on a desktop only (no touch emulation through the MCP): the touch
  taps (TouchTapInWorld, the two-tap drop) and how easy squares are to hit on a phone are open (MU or the user).

*Rejected:* prompts with `Exclusivity = OneGlobally` and the card on trigger (fixes density only, not the repeated planting).

## 5. Pets on the field
- The job-icon label and the card's line per pet are **built in U3a**; the reach borders in rarity colours and the pet page's "Place on
  field" **in U3b** (GDD §7.9). Left open: **"Show on field"** on the pet page (marker + camera hint to its square); moving field pets from
  far away (EXPANSION §3).

## 6. Splitting the Garden panel
**Built in U4 (2026-11-07)**: the Garden panel is gone. Upgrades / tools / Renown are in the Skills panel's Garden tab (buyable anywhere),
field pet slots are a line in the Pets panel, the barn is a panel behind the bottom-centre "🧺 Barn" HUD button at the own plot (seeds, crops
with size / record, Feed / Sell, crow forecast), and seeds and the market cart are bought at the seed stall on the plaza (its board shows the
cart); the crow forecast is also in the summary bubble when crows are near. As built: GDD §7.9; the table of where each piece went is in
`git show c06d477:docs/UI_GARDEN_PETS.md`. Left for U5: the barn as a building on the plot (shelves / crates that fill visibly; the panel
opens from it as well as from the HUD button).

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
**Built in U2 (2026-11-06)**: the 🌱 Garden icon with its badge (ripe crops + ready eggs) and the summary bubble, as built in GDD §7.6 and
§11; the design text is in `git show e2f7a06:docs/UI_GARDEN_PETS.md`. Left open: G1's markers could point at the own plot when something
is ready (the badge covers it for now); other players' bubbles (Renown, biggest crop) stay optional (§3).

## 9. Pets panel and pet page
**Built in U1 (2026-11-06)**: as built in GDD §7.5 (rows, filters, summary) and §7.8 (pet page); the design history is in
`git show a514b94:docs/UI_GARDEN_PETS.md`. "Place on field" is built (U3b); "Show on field" is left open (§5).

### 9.1 Food stand (plaza)
**Built in U1**: the Pets panel's row with the trained chip outlined, pets with you first, trained ones greyed at the bottom (GDD §7.6).
The seed stall stands beside it as its own stall (**built in U4**, GDD §7.9); the food counters stay reachable and readable.

## 10. Other improvements
- **Feedback for every action:** a pop where it happened (crop to the barn, Coins to the counter, XP to the pet), not only a toast. The
  harvest pop over the square is built (U3b); the rest is open.
- **One confirm pattern** for every spend over ~1 000 Coins and for Sell: two taps, the button turning orange ("Tap again"): **built in U4**
  (`ConfirmTap`; the food buttons keep their own); hold prompts only in the world.
- **Next-step hint in the garden:** an empty field pulses Seeds, a ripe one the Basket: **built in U3b** (E5's onboarding builds on it).
- **Locked squares** look different from empty soil (grass tufts; the price only in the square card): **built in U3a**.
- **Panel focus:** opening one panel closes the others (Pets, Skills, Barn, Seed stall, Food); panels close when walking away (32 studs; the
  stalls at their own 20): **built in U4** (`PanelFocus`).
- **Phone check** of every new piece is part of its milestone (MU's checklist), Czech widths included.

## 11. Milestones (each ships alone; scope with acceptance checks when it starts)
| Id | Content | Depends on |
|---|---|---|
| U1 | Pets panel, pet page and the food stand panel (§9, §9.1): **built 2026-11-06** | P4 |
| U2 | Garden HUD button + badge, summary bubble over the own sign (§3 Far, §8): **built 2026-11-06** | – |
| U3a | Field: rings, tap-select, square card, prompts removed, locked look, pet job-icon labels (§3 Near, §4, §5): **built 2026-11-07** | every player |
| U3b | Hand bar (Seeds / Basket / Pets / Look), pet reach borders, next-step hint on the bar, pet page "Place on field" (§4, §5, §10): **built 2026-11-07** | U3a |
| U4 | Panel split: Skills → Garden tab, Barn panel, Seed stall; Garden panel removed (§6, §10): **built 2026-11-07** | U3b |
| U5 | Plot layout: hatchery left, barn right, path; K1 egg cards (§7) | U4 (barn) |

Order proposed: U1 before M6a; U2–U5 before E5's onboarding (it teaches the new controls).

## 12. Decisions (the user, 2026-11-05)
1. ~~Square interaction~~ — decided 2026-11-05: tap + square card + hand bar (§4).
2. ~~Pets list row~~ — decided 2026-11-05: an Equip brick + a Details brick; a tap on the rest of the row does nothing (§9).
3. ~~Barn~~ — decided 2026-11-05: on the own plot (§6, §7).
4. ~~Field camera button~~ — decided 2026-11-05: not in U3; built only if U3's phone check shows players missing squares (§4).
5. ~~Seeds~~ — decided 2026-11-05: a seed stall on the plaza, with the market cart offers on its board (§6), beside the food stand
   (§9.1).
