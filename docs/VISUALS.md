# Graphics redesign

This is the implementation brief for [PLAYTEST-27.md](PLAYTEST-27.md), covering the whole game.
It describes the target, not a claim that the renderer or artwork is implemented. The existing
SVG silhouettes are not the visual target. Animation, depth, material and composition are designed
together. Luna agents implement bounded pieces; the orchestrating session owns design and review.

## Visual target

A detailed illustrated urban city, following the user's references in
`evidence/graphics-reference-urban-01.jpeg` and `graphics-reference-urban-02.jpeg`: fine ink
contours, painted brick and plaster, substantial apartment facades, readable shopfronts, clothing
folds, identifiable faces and detailed vehicles. The cardinal-layout draft in
`evidence/graphics-reference-cardinal.jpeg` is useful for composition but does not lower the art
target. The reference action buttons, minimap and portrait HUD are not requested features.

`evidence/graphics-reference-urban-01.jpeg` and `evidence/graphics-reference-urban-02.jpeg` are
the authoritative illustrated urban references. `evidence/graphics-reference-mother.jpeg` is the
authoritative mother/pram reference; its green coat, patterned scarf, high bun, jeans and practical
shoes take precedence over generated drafts.

**Keep the current non-diagonal presentation.** Match the diagonal references' illustration,
detail and inhabited-city character without rotating the grid. M79's diagonal investigation is
tabled, not an implementation task. The logical street layout, controls and route rules stay intact.

The mother follows `evidence/graphics-reference-mother.jpeg`: brown hair in a high bun, green
coat, patterned scarf, jeans and practical dark shoes. Give her an expressive, drawn face and a
detailed dark stroller with a warm bundled baby, not a rectangle and circle standing in for a
person. Portrait UI remains outside this task.

The camera stays high enough to read both pavements, crossings, entrances and alley mouths.
Buildings feel tall without taking the street out of view. Angled light carries ordinary paving
into alley mouths before the shaded passage begins. Surface noise diminishes at gameplay scale;
the most important contrast belongs to moving bodies and passable ground.

Districts have architecture, not merely a hue: residential stoops and balconies, shopfronts and
awnings, industrial loading doors and roof vents, civic steps and stone bays. Small lots receive
intentionally shallow buildings, not walls missing their roofs. Home has an entrance attached to
its actual building. The tunnel has a visible road receding under a modeled portal.

**This is an apartment city, not a suburb of detached houses.** Residential streetfronts are
continuous multi-storey apartment buildings: repeated window bays, shared entrances, balconies,
ground-floor shops where appropriate, and internal courts. Roofs finish an urban block rather
than giving each large lot a single family-house silhouette. Compress apparent height where
needed to keep streets readable; do not change the logical footprint or replace apartments with
bungalows to solve occlusion. Review the revised apartment street with the player before expanding
the architecture library. The current detached-house study is not an approved building target.

## Medium and architecture

Use illustrated PNG assets with layered character animation. No new SVG artwork. The 3D studies
are retained as experiments, not the art target or a required runtime dependency. A 3D authoring
rig remains an option only where it makes creating the drawings easier. Asset quality is judged
from the fixed gameplay camera, not in a modeling tool: shorten a building's hidden north depth,
warp its apparent height, or separate its front to keep the adjacent street legible.

The logical city remains the source of tiles, routes, collision, events and costs. A presentation
adapter reads those facts; it must not create a second simulation. A standalone scene establishes
the look, then a projection adapter proves alignment before replacing the live renderer. World
display, touch picking and screen cues use one coordinate mapping, including camera smoothing,
look-ahead and portrait presentation.

Use the web-compatible Compatibility renderer with shared atlas textures.
Draw the visible neighborhood and batch static repetition. Paused gameplay pauses world animation;
the title has an explicit independent animation clock. Cosmetic randomness never advances gameplay
RNG. The illustrated renderer must meet the mobile/browser budget as well as the desktop budget.

| Content | Working format |
| --- | --- |
| People, pram, vehicles, buildings and props | PNG sheets with explicit pivots, bounds and direction metadata |
| Plaster, stone, roof wear and ground variation | Small PNG atlases with broad tonal shapes |
| Papers, smoke, leaves and small distant details | PNG flipbooks or animated PNG cutouts |
| Typography, simple interface symbols and masks | Fonts, PNG symbols, engine layout and shaders |
| Painted title/ending accents | PNG where painted texture adds value |

Prepare draft sheets for player-applied style transfer if generated art does not meet the target.
That fallback keeps dimensions, alpha, part registration, anchors and frame layout unchanged.
Only a rendered scene establishes feasibility and motion quality.

### Projection adapter contract

Keep the live `Camera2D` and its canvas transform, smoothing, limits, look-ahead and portrait
composition. New sprite parts share one logical ground anchor; their drawn heights do not move
that anchor. Tap picking, danger cues and home guidance use the same existing transform. Test
direction/frame changes for anchor stability rather than adjusting collision to accommodate art.
The experimental orthographic mapping remains preserved in branch history; it is not live wiring.

### Directional and modular sheet contract

Author eight real views in a consistent clockwise order: N, NE, E, SE, S, SW, W, NW. A direction
not used by today's animation still gets a slot and artwork, not a mirrored placeholder. Static
rotationally symmetric assets may explicitly share equivalent views; record that equivalence
rather than silently borrowing a different facing. Ground textures do not acquire a false facing.

Separate head, hair, torso/clothing, arms/hands, legs and shoes into interchangeable registered
parts. Keep pram body, canopy, baby and wheels separately animatable. Start with a few compatible
pedestrian variants, not a large combinatorial catalogue. Shared attachment points, scale, cell
size and direction-dependent layer order make combinations fit. A variant changes art, never
physics, warnings or route costs. Keep authored-event silhouettes distinct from generic crowds.

Each sheet has explicit pixel rectangles, logical anchor, attachment pivots, direction order and
layer order in a manifest. Style transfer can replace the PNG without changing that manifest.
Review an assembled character as well as individual parts: independently attractive parts can
still leave seams, mismatched lighting or disconnected hands when composed.

## Animation contract

| Family | Required motion and state |
| --- | --- |
| Mother | Distance-driven walk/run, planted feet, turn, idle weight shift, hands on pram |
| Pram and baby | Rolling wheels, suspension response, breathing/sleep, stirring/fuss |
| Pedestrians | Gait variation, standing gestures, turns, bodily response to contact |
| Vehicles | Wheel rotation, steering, coherent turning body, restrained suspension |
| Dogs/cats/birds | Idle attention, gait/chase, peck, wingbeat, takeoff/landing |
| Authored people | Instrument, conversation, work, waiting or pursuit matched to the row |
| Events | Anticipation, active action and completion tied to actual event state |
| Environment | Canopy/awning motion, paper, restrained smoke/fire and water movement |

Speed controls stride distance and wheel travel. A stopped body does not walk in place. Turning
must not snap between unrelated still images. Event animation reads the event clock, so anticipation
never promises time the actual encounter does not allow. Animation does not move the logical body,
retune an encounter or hide a warning. A reduced-motion setting quiets decoration while retaining
meaningful state changes.

Foot contact is a constraint, not a sine wave. During stance, a foot remains planted on a logical
ground point while the body travels over it; during swing it lifts and lands at the next reachable
point. Solve knees from hip and ankle positions. Acceleration, stopping, reversing and collision
must not slide a planted foot or continue a treadmill gait. Test actual world-space foot drift
and review several consecutive rendered frames. Wheel rotation likewise follows actual travel.

## Roof depth and occlusion

Roofs may project roughly half a tile into the screen space above their footprints, as suggested
by the player. This replaces the visual restriction that every roof must fit its lot; collision
remains the building's real ground footprint.

Prefer a local stippled echo of an occluded actor, clipped to the part hidden by a roof. Keep the
roof opaque rather than fading the building to glass. Use a stable ordered pixel pattern with
fully covered and fully uncovered pixels. Control its scale in design pixels and anchor it
consistently to avoid crawling noise. Visible parts of the actor stay fully drawn.

Mother, pram and approaching threats remain readable behind roofs; critical warning symbols sit
above the occluder. Review movement along every building edge, two overlapping roofs and an event
approaching behind one. A still cannot prove the transition works.

## A city that deteriorates

Change the same identifiable street over the run. Early days have intact paving, cared-for
shopfronts and sparse everyday litter. Later days accumulate refuse near bins and kerbs, torn
posters, paper, shuttered windows, grime and damaged surfaces. Final days show boarded shops,
charred surfaces and fragments consistent with each district's actual condition.

Persistent dress is seeded by lot/tile and accumulates where the narrative calls for it. Flying
papers follow a common wind with local tumbles. Cracks cluster at believable wear locations,
including armoured-vehicle routes when known. Do not imply a particular truck caused damage unless
its passage was recorded. Cosmetic dress changes no route, crowd density, cost or collision.

Cracks and litter remain low profile and quieter than obstacles. Large rubble that looks
impassable must be an actual event or closure. Trees, facade condition and light follow the
existing story instead of inventing a second calendar.

## What is raising excitement

Read attribution from the same contributions that feed the baby, not distance to the nearest
entity. A silent van cannot be blamed for a sound coming from somewhere else.

While the meter rises, the strongest relevant visible contributors briefly animate small warm
hatch strokes at the emitting part: instrument, mouth or machine. Synchronize that with a modest
accent in the excitement meter. Contribution controls emphasis; a short hold/hysteresis avoids
flickering between nearly equal sources. These explain a present cost and differ from danger cues.

Contact gets a brief bodily response. Running and alley dread need their own small meter context,
since neither has an external culprit. Diffuse crowd and citywide noise appear as ambient context
instead of arbitrarily blaming a pedestrian. Preserve the full contributing set internally even
when only a few sources are emphasized. Recovery reducing the total is not a source disappearing.

No range rings or beams to every entity. Test several contributors, sleeping sensitivity, running,
alley cost, pause and offscreen sources. Consume the event system's current contributions rather
than copying its arithmetic; silent obstacles must remain silent in the presentation too.

## Objective guidance

Prefer a compact objective tab with a destination symbol and an offscreen bearing. It answers
where the current destination lies without drawing a route through the city. Visible destinations
carry a matching physical motif: home entrance light, recognizable park gate, or resistance mark.
The objective tab can repeat the instruction without unexpectedly stopping movement.

Protesters need not act as universal compass needles. Chalk on every ordinary path would add a
navigation system and risk turning route choice into following arrows. Use chalk for authored
discovery and identification rather than mandatory breadcrumb collecting.

Keep the first resistance contact unannounced until encountered, but visible from an ordinary
route near an alley mouth. After discovery, allow explicit bearings and the current instruction.
This preserves discovery while challenging the old restriction on useful destination guidance.
Park guidance must preserve a choice of destinations instead of silently choosing an optimal park.

## Every screen

The title is a composed animated home street, distinct wordmark and clear control-mode choices,
preserving the existing title-selection behavior. No developer readout or wall of instructions.
The city supplies imagery; typography and spacing provide hierarchy. Pause freezes that place.
Day summaries and endings use the street's condition and the baby's state, with distinct next steps.

The playing HUD positions clock, meters, baby state and objective without large pavement-covering
panels. Sleep and excitement differ by shape/icon as well as color. Touch targets are generous;
objective cues avoid stick/run regions. Review title, pause, success, failure, ending, touch and
desktop views, including transitions, actual portrait rotation and reduced motion.

## Delivery gates

1. Render an early/late street with real articulated motion and roof occlusion at gameplay scale.
2. Prove screen picking, warning projection and camera alignment on desktop and portrait touch.
3. Replace every visual family and screen. A missing authored event is explicit unfinished work,
   not a generic model quietly standing in for it.
4. Profile a busy neighborhood on the web-compatible renderer; verify pause, streaming, transitions
   and cosmetic determinism.
5. Integrate current main and related control/field changes, review bounded captures, run appropriate
   local checks and let PR merge-result CI gate the complete build.

A demonstration street, concept board, unanimated models or a restyled title is not a finished
overhaul. The rejected initial SVG polish is preserved separately and does not define this design.

## Engine references

Godot's [Camera3D reference](https://docs.godotengine.org/en/stable/classes/class_camera3d.html)
documents orthographic projection and world/screen mapping. Its
[material guide](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html)
describes alpha hash and scissor; the proposed actor reveal requires a local occlusion mask,
not merely enabling transparency on a roof. The
[renderer guide](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
describes the Compatibility renderer used for web targets.
