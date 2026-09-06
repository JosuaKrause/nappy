# Graphics redesign

This is the implementation brief for [PLAYTEST-26.md](PLAYTEST-26.md), covering the whole game.
It describes the target, not a claim that the renderer or artwork is implemented. The existing
SVG silhouettes are not the visual target. Animation, depth, material and composition are designed
together. Luna agents implement bounded pieces; the orchestrating session owns design and review.

## Visual target

A small, inhabited city with the tactile quality of an architectural miniature. Plaster has broad
painted variation, stone has edges and occasional wear, roofs have actual planes and eaves, and
trees have asymmetric volumes. Shapes have restrained bevels and lighting, rather than universal
black outlines. People have articulated bodies and identifiable poses. The mother and pram remain
legible through their silhouette, movement and contrasting rust/navy colors.

The camera stays high enough to read both pavements, crossings, entrances and alley mouths.
Buildings feel tall without taking the street out of view. Angled light carries ordinary paving
into alley mouths before the shaded passage begins. Surface noise diminishes at gameplay scale;
the most important contrast belongs to moving bodies and passable ground.

Districts have architecture, not merely a hue: residential stoops and balconies, shopfronts and
awnings, industrial loading doors and roof vents, civic steps and stone bays. Small lots receive
intentionally shallow buildings, not walls missing their roofs. Home has an entrance attached to
its actual building. The tunnel has a visible road receding under a modeled portal.

## Medium and architecture

The first experiment is a native orthographic 3D street with articulated actors. Godot can provide
the prototype's meshes, lighting and animation without Blender. Blender is the preferred authoring
tool if the experiment establishes that a modeled asset pipeline is worthwhile; report its absence
before installation. Models ship as glTF/GLB so playing or exporting does not require Blender.

The logical city remains the source of tiles, routes, collision, events and costs. A presentation
adapter reads those facts; it must not create a second simulation. A standalone scene establishes
the look, then a projection adapter proves alignment before replacing the live renderer. World
display, touch picking and screen cues use one coordinate mapping, including camera smoothing,
look-ahead and portrait presentation.

Use the web-compatible Compatibility renderer: a shadowed sun, simple materials and shared meshes.
Draw the visible neighborhood and batch static repetition. Paused gameplay pauses world animation;
the title has an explicit independent animation clock. Cosmetic randomness never advances gameplay
RNG. Native 3D must earn its runtime cost in the browser as well as on desktop.

| Content | Working format |
| --- | --- |
| Articulated people, pram, vehicles, roof forms | Meshes and animation; exported GLB for authored models |
| Plaster, stone, roof wear and ground variation | Small PNG atlases with broad tonal shapes |
| Papers, smoke, leaves and small distant details | Mesh particles or PNG flipbooks, selected by cost |
| Typography, simple interface symbols and masks | Font resources, vector or procedural drawing |
| Painted title/ending accents | PNG where painted texture adds value |

If native 3D cannot meet the mobile/browser budget, render the same models to directional PNG
animation atlases. This is a measured alternative, not a return to static SVG placeholders.
A concept image establishes style; only a rendered scene establishes feasibility and motion quality.

### Projection adapter contract

Keep the live `Camera2D` as the source of the logical ground transform, including its smoothing,
limits and look-ahead. Present the 3D world through a fixed-design-size `SubViewport` on a layer
behind the interface; rotate that layer through `ScreenOrientation` alongside the other furniture.
The logical world continues processing even when its old drawing is hidden.

For a camera pitch of 65 degrees and one model unit per 32 logical pixels, map a logical point
`(x, y)` to `(x / 32, 0, y / (32 * sin(65 degrees)))`. Apply the same mapping to the camera's
ground target. With `Camera3D.KEEP_HEIGHT`, orthographic size is the design viewport height divided
by logical zoom and tile size: 11.25 units for 720 design pixels at zoom 2. A size of 20 describes
the width at that scale, not the height. Read the actual camera transform instead of assuming the
player position is its center. Unrotate the canvas transform into design space before comparing
it with the 3D viewport.

Prove agreement between logical-to-screen, screen-to-logical and `Camera3D.unproject_position`
for ground points at the center, corners and building edges, through camera motion and both
orientations. Tap picking keeps the same ground destination. Elevation affects only the drawing;
warning anchors can use model height, but warning conditions still use logical positions.

The adapter owns presentation streaming and mesh lifetime, never movement, event clocks or costs.
Batch repetitive static geometry by material and visible chunk; do not instantiate the whole city
as individual tile nodes. A debug override may select either renderer while integration is
incomplete, but an incomplete replacement is not the ordinary playable default.

The [concept reference](evidence/graphics-redesign-concept.png) is generated art, not a capture of
the game. It establishes material, depth and early/late contrast; its density and camera framing
are not gameplay specifications. The generation prompt is kept beside it.

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
