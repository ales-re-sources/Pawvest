# Incubator redesign — options for review

2026-11-16: **Cross-lapped oval** implemented and Studio-validated for world nests and hatchery shop previews through the shared EggLook recipe. Full / mid / low detail use 27 / 9 / 5 bricks, with the portal's stud map at the smaller pet-model tile scale (StudsSmall). Other design choices below remain open. As-built design: GDD §7.6.

## Observed baseline before the redesign

- `PlotView`: world eggs are 2.8-stud smooth balls; `IncubatorClient.eggPicture` draws a smooth oval separately in the shop.
- Hatchery roof underside is 8 studs over the plot origin, covering the three nests in a triangle. Its single prompt is inside the shelter, 3 studs behind the front post line, with a 10-stud activation range.
- Empty / locked nest billboards have a 60-stud camera range; occupied nest billboards allow 90. Full plot detail is itself distance limited.
- Field rings also allow a 90-stud camera range, but enable only while the character is within 30 horizontal studs of a field square. Incubators lack that character-proximity gate.
- The live Hatchery panel and its scrolling content are Active. The panel is a Frame, not a button. The cursor symptom is reported by the user; the exact cursor owner still needs real-pointer diagnosis before implementation. Preserve `UiKit.BlocksWorld` coverage while fixing it.
- The existing user-started Studio playtest was inspected read-only and left running. Existing unrelated working-tree changes were left untouched.

## Eggs — apply the chosen model to world eggs and shop previews

| Concept | Treatment | Tradeoff |
|---|---|---|
| Studded shell | Keep an egg silhouette, add a few raised stud pads on the upper shell; consistent Plastic / StudPack appearance. Golden uses the same form in gold. | Smallest change, but the shell remains rounded. Avoid stretching a flat stud texture across a sphere. |
| Stepped shell — recommended | Five broad brick tiers taper into an egg silhouette, with studs on exposed ledges and a small studded crown. | Strong Roblox identity with a readable egg shape; more angular. |
| Brick-built shell | Assemble a chunky egg from interlocking small bricks, with staggered seams and exposed studs. | Most toy-like; highest part count and visual density. |

Use a shared egg renderer / recipe so shop and world cannot drift. Keep the two shipped egg identities, prices, odds and timers. Basic stays pale; Golden stays gold. Preserve restrained Golden illumination. Full / mid / low detail need appropriate simplification.

## Shelter — keep the existing plot footprint and three nests

| Concept | Treatment | Tradeoff |
|---|---|---|
| Tall pavilion | Raise the underside from 8 to a proposed 12 studs; thin the eaves and move the prompt to the front approach. | Smallest architectural change; a solid roof still hides eggs at high camera angles. |
| Rear canopy | Roof covers only the rear portion; leave the front nests exposed. Rear posts only, prompt at the exposed front. | Keeps a shelter identity, but a rear view can still obscure the back nest. |
| Open nest court — recommended | Remove the roof and tall corner posts. Three stud-brick nest plinths, a low rear rail and a small side sign identify the hatchery. Front prompt is unobstructed. | Best egg visibility from orbiting cameras; less building-like. |

The visual previews are schematic concepts, not Studio screenshots. Proposed dimensions are starting points, not validated values. Keep the central path, barn access and follower clearance. Keep the one hatchery-opening interaction; eggs remain display objects.

## Dialog / pointer — one required behavior, three optional layouts

All variants: arrow over title, explanatory text, egg art, status, separators and blank space; hand only over enabled action controls. Passive areas still consume / block input so clicks cannot plant, harvest, select a field square or activate a prompt behind the panel. Do not fix this by indiscriminately turning Active off. Scrolling continues to work; disabled controls do not advertise an action.

| Concept | Treatment | Tradeoff |
|---|---|---|
| Quiet rows — recommended | Preserve the existing Your nests / Eggs to buy groups and row arrangement; constrain affordances to actual buttons. | Minimal learning and implementation cost. |
| Action column | Align nest actions in one clearly separated right column; passive status text on the left. Shop actions remain separate. | Stronger scanability; needs responsive stacking on phones. |
| Selected nest | Three explicitly raised nest-selector controls, one selected nest detail below, separate egg shop. | Compact focus, but adds selection and needs a defined purchase target instead of silently changing first-empty behavior. |

The preview buttons are local illustrations, not purchases or remote calls. Selected nest would be a larger interaction change and should be scoped separately if chosen.

## World labels — distance is measured from the character to the nearest nest, horizontally

| Concept | Treatment | Tradeoff |
|---|---|---|
| Nearby labels | Keep the current text, own plot only; fully visible through 24 studs, fade to hidden at 30. Near entry 28 / exit 30 prevents boundary flicker. | Lowest change, but all three labels still compete at close range. |
| Field-style focus — recommended | Own plot only, same 30-stud character-proximity rule as field overlays (entry 28 / exit 30). Empty nests have no floating words; growing eggs show a compact timer / progress ring; ready eggs show a compact ready marker. Names, empty and locked explanations live in the dialog. | Clean world view; details require opening the hatchery. |
| Physical plaques | Put number / empty / lock on small nest-front plates instead of floating text; countdown and hatch details in the dialog. Plates naturally shrink with distance and are hidden outside near range / full detail. | Most integrated into the scenery; more angle-dependent and Czech text needs careful sizing. |

The existing own-egg Ready hint / toast and Home badge remain governed by their hint rules; they are not the empty-label problem. Avoid adding competing ready markers. Other players' nests show the egg model without verbose status text.

## Proposed package

Initial recommendation: Stepped shell + Open nest court + Quiet rows + Field-style focus. The confirmed round-two egg choice, Cross-lapped oval, supersedes Stepped shell; the other recommendations remain unconfirmed.

## Egg review, round two — portal brick construction

The user requested three further egg options based on the portal's layered stud bricks. Live read-only inspection of `ServerStorage.DecorKit.StudPortal` confirms thin Plastic parts with `MaterialVariant = "Studs"`, overlapping courses and alternating orientations. The portal has deliberate small irregularities; its outline is built by the blocks themselves.

The second-round concepts use studded faces throughout, narrow course heights and a complete three-dimensional brick volume. The earlier decorative-stud and broad-tier previews remain historical alternatives.

| Concept | Construction | Tradeoff |
|---|---|---|
| Cross-lapped oval — selected | Nine thin courses; a broad lower body narrows into a small crown. Alternating cross-shaped courses create stepped corners in both horizontal axes. | Closest balance of the portal's layered construction and a familiar egg silhouette. |
| Staggered brick egg | Eight chunkier courses of three bricks, alternating orientation, staggered joints and slightly offset edges. | Strongest handmade portal character; more irregular and squat. |
| Tall tapered egg | Eleven thin layers, alternating long axes, with a progressively narrower upper half. | Clearest tall egg silhouette; its upper profile is more pointed. |

These are geometric concept studies, with Basic / Golden using the same construction and different shell colours. Front, three-quarter and side views show the volume. The reference view uses measured live portal brick geometry, omitting the neon portal face and thin overlay pieces. The user confirmed Cross-lapped oval after this review. Use the same egg model in nests and shop previews. Shelter, cursor and world-label choices remain undecided.

## Acceptance checks when a design is selected

- Same egg design and identity in nests and egg cards; a clear egg silhouette at default gameplay zoom; studs visible at near distance without excessive part count.
- Eggs and front prompt visible from the plaza approach and normal orbit / high camera positions; no obstructing roof, post or new collision; barn, path and followers still clear.
- Real mouse pass across panel title, blank space, labels, cards and each enabled / disabled control. Only actionable controls advertise clicking. Click passive areas while a field square is behind the panel: no world action. Verify mouse wheel and phone scroll.
- Walk towards / away from the own hatchery and inspect another plot. Empty labels cannot be read across the garden; chosen near-distance rules hold without flicker. Zoom the camera out while the character remains near: camera range remains a secondary cap, not the proximity rule.
- Open, buy / confirm, odds, unlock, hatch / reveal and close through their real UI paths if changed. Purchases / hatching require a fresh live-profile snapshot immediately before each fixture write and restoration under AGENTS.md; design preview needs none.
- Czech wrapping / TextFits and required localization checks for any changed shipped text. One playtest boot with bounded server / client warning and error inspection. Update GDD / LAYOUT / ROADMAP only for implemented and validated work.
