## SVG-to-PNG style-transfer experiment — 2026-09-10

PLAYTEST-51 replaces the full illustrated overhaul with an experiment: style-transfer the existing SVGs into registered PNG replacements, retaining the illustrated opt-in. The player explicitly asks to archive the old outcomes and remove its code. The old layered-animation, comparison-offset and supersampling repair queue below is superseded by that request, not silently dropped. Adopting SVG-first authoring followed by style transfer as the standard pipeline remains conditional on the experiment working.

The previous asset tree, including source PNGs, manifests, generation records and import sidecars, is preserved at `docs/evidence/archive/rejected-graphics/illustrated-2026-09-10/`. It is historical evidence, not a style reference. Its original runtime and review scenes remain retrievable from commit `660647a`, which precedes this experiment.

### Superseded text from docs/TODO.md

### Illustrated actor registration and assembly

**This is Codex's parallel track, worked beside the gameplay queue rather than ahead of it.**
*(2026-09-09: "illustrated actors is currently a sidearm for codex to work on".)* The SVG drawings
are the game's graphics until the illustrated presentation passes its visual gates, so a drawing
item in the gameplay queue is drawn as SVG.

The repair follows [ILLUSTRATED-GAMEPLAY-FIXES.md](../ILLUSTRATED-GAMEPLAY-FIXES.md),
PLAYTEST-32's connected-body and legacy comparison requirements, and the M84 record in
DECISIONS.md. Keep the illustrated renderer opt-in. The supplied urban/mother illustrations
define style; `docs/reference/` supplies real-world structure and posture.

- [ ] Finish the modular source-art gate with eight complete views, clean alpha and isolated
      anatomy. The manifests identify same-facing arm/profile-leg reuse, shared diagonal walker
      edge pixels and the mustard SW facing ambiguity. Replace those source limitations while
      preserving interchangeable parts; flattened cards do not satisfy layered animation.
      Preserve PLAYTEST-44's selected transparent v3 pram. See DECISIONS.md under Illustrated
      registration audit and Limb attachment repair for the source findings and implemented fit.
- [ ] Review the registered actors at gameplay scale before expanding variants. Inspect all eight
      facings and smooth walk, run, stop, turn and reset, including the corrected resting knees.
      The static contact review in DECISIONS.md predates the resting-knee correction. Headless
      attachment and displacement checks do not establish motion quality or visual acceptance.
      Keep the legacy drawings at their fixed horizontal comparison offset.
- [ ] Resolve [PLAYTEST-45](../playtests/PLAYTEST-45.md)'s directional posture and pram-quality findings within
      the connected-body repair: mustard and red legs slant during east/west travel and spread
      outward during north/south travel. Review knee bend, ground stride, projected lift and
      source rest axes independently; matching endpoints alone is insufficient. Fit per-facing
      mother-to-handle spacing to natural arm reach, preserving the selected v3 pram and logical
      collision. Trace the pixelated pram to the actual visible binding, source alpha, complete
      assembly scale and inherited filtering before choosing a repair. Confirm the illustrated
      player loads in the actual test checkout after imports. Use the repeatable procedure in
      the illustrated-png skill; see DECISIONS.md under Texture integration process.
- [ ] Resolve [PLAYTEST-42](../playtests/PLAYTEST-42.md)'s additional anatomy and pram compositing defects.
      Inspect the preserved timed PNG sequence: each leg must read as one hip–knee–ankle chain,
      without a painted bend plus a second solver bend. The baby must sit within the seat and
      its facing-specific occlusion, not appear pasted over the stroller. Reconcile these with
      PLAYTEST-45's existing natural-reach and directional-gait repair; keep both reports intact.
- [ ] Implement and review [PLAYTEST-42](../playtests/PLAYTEST-42.md)'s higher-resolution rendering of the
      **current view**, preserving visible world extent, actor size, HUD size and physical window.
      Render more pixels and downsample them; do not zoom out or merely enlarge logical coordinates.
      Compare actual render-target dimensions and the same scene framing, input mapping, resize
      behavior and screenshot/burst capture. Inspect filtering and retained detail without declaring
      anatomy or animation fixed by resolution. The wider-view interpretation is rejected; its
      history is in DECISIONS.md under Animation anatomy and camera experiment. The debug
      `--illustrated-render-scale 2` experiment is in the tree and unverified; its open checks are
      in HANDOFF.md. Preserve legacy presentation and the illustrated opt-in while it is reviewed.
- [ ] Review whole-actor sorting in live overlaps and integrate roof reveal, then a representative
      illustrated live street.
      Preserve current joystick/tap choice and the event and crowd silhouette halos, including
      their attributed contribution and easing. Connect crowd halos to the animated PNG assembly;
      the current callback traces the offset legacy comparison. Extend vehicles, authored events,
      environment and screens only
      after their prerequisite visual gates.

### Superseded text from docs/HANDOFF.md

**The illustrated presentation remains opt-in and awaits visual acceptance.** The game draws
its legacy SVG graphics unless `--illustrated` (locally) or `?illustrated=1` (on the web) opts in.
The compositor consumes applied displacement without changing gameplay. The full graphics
overhaul is not ready for release.

The concept capture is [illustrated-street-review.png](../evidence/archive/session-captures/2026-09-06/illustrated-street-review.png).
The street study is completely off and must be redone from scratch: it has no coherence or sense,
and it uses reference imagery that does not fit the game's art style. It is not an approved visual
direction or a basis for extending the asset family.

[Illustrated gameplay repair instructions](../ILLUSTRATED-GAMEPLAY-FIXES.md) specify the asset,
attachment, gait and sorting contracts. The open work is in TODO.md under Illustrated actor
registration and assembly; the source audit and repair reasoning are in DECISIONS.md under
Illustrated registration audit and Limb attachment repair.

The actor manifests use measured per-facing crops and crop-local joints. The shared segment
transform maps painted endpoints to solved joints, including the lifted ankle and sole. The gait
retains unfinished steps across stops, bounds stride against leg reach and fits neutral knees to
the configured rest geometry. Review complete assembled bodies against the legacy drawings at
the fixed 96-world-pixel offset.

The mother uses a textured torso core and separate shoulder-to-hand arm registrations. The pram
manifest consumes PLAYTEST-44's selected `pram-layered-v3-draft-transparent.png`, with independent
chassis, seat, canopy and baby registration. The approved PNG remains unchanged; its extraction
record is `assets/illustrated/modular/pram-alpha-extraction-2026-09-08.md`.

Source limitations remain explicit: some profile arms and walker legs reuse one same-facing
drawing, and diagonal walker crops share painted edge pixels. Distinct isolated parts and authored
facing refinements remain an art gate. The stationary `scenes/dev/illustrated_actor_review.tscn`
and sampled `scenes/dev/illustrated_motion_review.tscn` expose assembly at gameplay scale; their
commands and limitations are in the repair brief. Live overlaps, roof reveal and a coherent
illustrated street still need their own review.

Crowd halo selection and meter attribution include walkers and cars. In illustrated mode the
halo still traces the offset legacy comparison drawing; tracing the animated PNG assembly remains
an open integration gate. Preserve the contribution-based hue, transparency and easing when
connecting the illustrated silhouette.

The visual and attachment suites pass in the illustrated mode, and the visual suite also checks
the legacy binding without the flag. The dated contact review and its build provenance are in
DECISIONS.md; that image predates the tested resting-knee correction. Visual acceptance of the
current pose and smooth motion remains open.

[PLAYTEST-45](../playtests/PLAYTEST-45.md) specifies the next actor defects: slanted east/west legs,
outward north/south leg movement, excessive mother-to-pram spacing and pixelated pram rendering.
[PLAYTEST-42](../playtests/PLAYTEST-42.md) supplies a preserved timed PNG burst and MP4, with additional
double-bend leg anatomy and baby-over-seat compositing findings. Its resolution experiment requires
more rendered pixels for the **same view**, actor size, HUD and window. Zooming out was an incorrect
interpretation; it does not meet the request. Supersampling and anatomy need independent checks.

**The same-view render-scale experiment is in the tree and is not visually verified.** Debug
`--illustrated-render-scale 2`, which acts only together with `--illustrated`, enlarges only
renderer state and adds a topmost screen-texture pass averaging each 2×2 sample block; the camera
and engine-facing logical coordinates stay unchanged by design. Without both flags nothing in it
runs. The repair brief gives the command.

Before relying on it, fix the output attachment to preserve KEEP letterboxing, verify buffer size
using image readback rather than the viewport wrapper's reported size, handle engine resets even
when dimensions repeat, and restore the original attachment on reload. The deferred post-draw
diagnostic needs a headless-safe lifetime. Then capture the same framing and compare
normalized world/HUD anchors, real window dimensions, pointer mapping, resize, portrait, reload
and bursts. Confirm the final shader includes every overlay. The baseline capture and exact
engine-source findings are indexed in DECISIONS.md under Same-view supersampling handoff.

The illustrated-png skill's [texture integration procedure](../../.claude/skills/illustrated-png/references/texture-integration.md)
covers source preservation, measured registration, natural reach, filtering and separate motion
and visual gates. Prepare the player's actual checkout with `./tools/check.sh` and an explicit
illustrated boot; a populated global class cache does not guarantee imported textures exist, and
`tools/run.sh` checks the sidecars against `.godot/imported/` and runs the import pass itself
when one is missing, so a pulled checkout boots rather than failing on the first preload.
Preserve `.import` sidecars. The missing-player diagnosis and capture provenance are in
DECISIONS.md under Texture integration process; the screenshot does not establish appearance
after the local import repair.

### Superseded text from docs/VISUALS.md

# Graphics redesign

This is the implementation brief for the opt-in illustrated overhaul in
[PLAYTEST-30.md](../playtests/PLAYTEST-30.md), covering the whole game. SVG graphics are the main presentation
for now and are maintained against the existing SVG style. This brief describes the illustrated
target, not a claim that its renderer or artwork is implemented. Animation, depth, material and
composition are designed together. Luna agents implement bounded pieces; the orchestrating session
owns design and review.

## Visual target

A detailed illustrated urban city, following the user's references in
`evidence/graphics-reference-urban-01.jpeg` and `graphics-reference-urban-02.jpeg`: fine ink
contours, painted brick and plaster, substantial apartment facades, readable shopfronts, clothing
folds, identifiable faces and detailed vehicles. The cardinal-layout draft in
`evidence/graphics-reference-cardinal.jpeg` is the floor for the available cardinal perspective;
it does not lower the art target. `evidence/reference-isometric-street-2026-09-06.jpeg` is an
additional approved urban gameplay reference. `evidence/reference-buttons-2026-09-06.jpeg` is an
approved button/icon reference; its depicted controls are not automatically requested features.

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

The illustrated overhaul uses PNG assets with layered character animation; its new artwork is PNG.
The main SVG presentation remains independently maintained. The 3D studies
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

### Superseded text from docs/LUNA_HANDOFF.md

# Luna graphics handoff

## Read first

Read `CLAUDE.md`, `docs/HANDOFF.md`, `docs/TODO.md`'s Visual overhaul section, then
`docs/playtests/PLAYTEST-30.md` and `docs/VISUALS.md`. The playtest preserves the player's full words;
the visuals document states the current target. Read the relevant skills before editing.
The orchestration and committing rules still apply. Implementation uses Luna.

The actor registration work is on `main` behind the illustrated opt-in; its open gates are in
`TODO.md` under Illustrated actor registration and assembly. Read `ILLUSTRATED-GAMEPLAY-FIXES.md`
and `PLAYTEST-43.md` for the attachment and legacy-scale repair gate. A prototype, source sheet or
code scaffold is not a completed overhaul. Do not release the presentation, or make it the default,
until the entire requested presentation is implemented and reviewed.

## Current decisions

- **No diagonal grid for now.** The player briefly chose it, then explicitly tabled it again.
  Keep the current cardinal presentation and controls. Match the illustrated diagonal references'
  art style, not their projection. M79 contains the investigation and additional review notes.
- **New artwork is PNG, not SVG or pictures drawn in code.** Existing SVG assets remain until
  replaced. Their separately requested small polish PR is not the full overhaul.
- **Illustrated apartment city, not detached houses or primitive low-poly people.** Detailed ink
  contours, painted materials, substantial facades, shops, clothing folds and recognizable people
  are the target. The 3D prototype was not accepted as final art.
- **Eight directions:** N, NE, E, SE, S, SW, W, NW. Prepare unused directions too. Explicitly record
  genuine symmetry; never silently substitute an unrelated or mirrored view.
- **Modular characters:** interchangeable head/hair, torso/clothing, arms/hands, legs and shoes,
  shared pivots and registration, per-direction layer order. Start with a few variations, not a
  giant catalogue. Keep authored events visually distinct from the generic crowd.
- **Mother:** high brown bun, green coat, patterned scarf, jeans and dark practical shoes, as in
  the dedicated reference. Detailed dark pram and warmly bundled baby. Portrait HUD is not requested.
- **Grounded walking:** stance feet stay fixed on the ground while the body travels; swing feet
  lift and land, with knees solved from joints. A bob or speed-controlled sine wave is insufficient.
  Actual displacement drives travel, including collision, stops, acceleration and turns.
- **Camera-specific cheats are permitted:** shorten hidden north-side building depth, exaggerate
  facades or split a foreground front. Geometry need only read correctly in gameplay; logical
  collision and streets do not change with the drawing.
- **Occlusion:** stable local dotted/stippled reveal or a foreground cutaway, not glassy roofs.
  Preserve the player/pram, approaching threats and useful street information. Do not introduce
  warning flicker or hide the visible evidence of a real wall.
- **Everything remains in scope:** title, controls, pause, summaries, endings, HUD/touch; all
  environmental, crowd and event art; animations; late-game litter, wear and flying paper; actual
  excitement-source attribution; improved objective guidance. No new action-bar verbs or minimap.

## References and source art

All paths are relative to the repository root and are committed assets, not Downloads dependencies.

| File | Use |
| --- | --- |
| `docs/evidence/graphics-reference-urban-01.jpeg` | Main illustrated urban style reference |
| `docs/evidence/graphics-reference-urban-02.jpeg` | Additional street, vehicle, shop and crowd detail |
| `docs/evidence/graphics-reference-cardinal.jpeg` | Floor for the available cardinal perspective; not the illustrated style or detail target |
| `docs/evidence/graphics-reference-mother.jpeg` | Mother, clothing, face, pram and baby reference |
| `assets/illustrated/source/mother-turnaround-v1.png` | Generated eight-view source draft; **not runtime-ready** |
| `assets/illustrated/source/README.md` | Exact built-in generation prompt, inspection and remaining defects |
| `assets/illustrated/modular/` | Measured mother parts and the selected transparent v3 pram, registered by the opt-in compositor |

The original mother draft is materially closer in style, but has a **baked checkerboard and no
alpha**. Its observed order is **S, SE, E, NE / N, NW, W, SW**, not the requested N-first ordering.
It is a source draft, not visual authority. `mother-parts-v3.png` supplies independently packed
parts with measured per-facing crops, anatomical axes and sole contacts. A textured torso core
excludes the sleeves so separate arms can meet the pram handles. Some views explicitly reuse a
single same-facing arm drawing; newly authored isolated anatomy remains an art requirement.
PLAYTEST-44 selects `pram-layered-v3-draft-transparent.png`; its manifest registers eight views
of chassis, seat, canopy and baby against one pram frame. The mother and pram map source columns
independently. Both families are bound to the opt-in live player. The player explicitly offers to
perform style transfer on usable draft sheets if generation does not achieve the target.

Use the imagegen skill for generation/editing. Built-in mode does not require an API key. Do not
silently switch to a paid CLI workflow or use SVG/code primitives as substitute artwork. Preserve
prompts and rejected alternatives in the same overhaul history. Verify actual alpha values; an
image of a checkerboard is not transparency.

## Implementation checkpoint

The playable game uses the existing renderer by default. `--illustrated` or a web
`?illustrated=1` query opts into the initial illustrated character runtime for review; neither
argument changes simulation. A missing argument remains legacy, so this is not an approval or a
release switch.
The 3D street and actor experiments are preserved in ancestry, indexed in `docs/DECISIONS.md`
under Illustrated assets and experiment preservation, and are not in the tree. Do not revive their
design by mistake.

The modular sprite components also have opt-in live gameplay bindings:

- `src/visuals/directional_parts.gd` validates eight-direction regions, pivots and source axes,
  then maps painted segment endpoints to actor-local joints without scaling length twice.
- `src/visuals/planted_gait.gd` uses world-pixel stance/swing state, lifted ankles and solved knees.
  Zero displacement freezes an unfinished step; renewed travel resumes it within bounded reach.
- `src/visuals/modular_person.gd` consumes actual applied displacement without changing a logical
  body, collision or gameplay RNG.
- `assets/illustrated/modular/` supplies mother and pram source bundles, including articulated
  lower-body parts. The focused visual and attachment suites exercise registration, transformed
  joints and displacement sequences; passing those checks does not establish visual acceptance.
- Under the illustrated opt-in, `Stroller` owns a zero-offset live `ModularPerson` child. It
  receives only displacement that survived collision and shove resolution, then resets the gait
  with every logical player reset. The legacy mother/pram SVG drawing remains the default, with
  shadows, baby cues and alert cues in both presentations.
- Under the illustrated opt-in, walkers bind to `ModularWalker`; cars retain their existing
  presentation. Walker scale includes both the painted upper body and the separately drawn legs.
  Profile legs explicitly reuse one same-facing source set, and diagonal crops share edge pixels.

The standalone `scenes/dev/illustrated_street_review.tscn` consumes the layered PNG assets under
`assets/illustrated/street/`: ground, continuous apartment frontage, roof depth and props. Its
camera-specific shortened north depth and stable dotted roof reveal are a player-review gate, not a
live renderer or a substitute for movement review. `GENERATION_RECORD.md` retains the built-in
generation prompts; facade, roof and props have verified alpha, while the ground plate is opaque.
The street study is rejected and needs rebuilding from the authoritative urban images. It is
not an approved direction or a basis for extending the asset family; see `HANDOFF.md` and the
M84 record in `DECISIONS.md`.

Review rendered coordinates as well as solver targets. Test planted soles in world space after
the source-to-actor transform. Validate zero displacement, collision, reverse/turn, teleports/resets,
direction-boundary hysteresis and switching compatible parts. No animation code may move a logical
body, alter collision or advance gameplay RNG.

Current main's control work must be preserved: title buttons and input-mode selection, device/input
resolution, forced debug overrides, summary/pause behavior and portrait transforms. The archived
screen experiment predates some of this and must not simply replace current title scripts.

## Next work order

1. Review registered actors against the legacy SVGs in all eight directions, then review movement
   and live overlap. The calibration scene keeps the original drawing at a fixed horizontal
   comparison offset. Resolve the documented source-part limitations before expanding variants;
   follow `ILLUSTRATED-GAMEPLAY-FIXES.md`.
2. After the actor gate, rebuild a representative live illustrated street and expand by family. Every
   catalogue look needs its own identity and state-appropriate animation; a generic placeholder
   must be recorded as unfinished, never quietly substituted.
3. Add seeded deterioration, truthful contribution cues and objective guidance. The baby already
   receives event/crowd contributions: consume those facts instead of inventing nearest-source
   attribution or copying meter arithmetic. Silent barriers remain silent.
4. Rebuild all screens while preserving the current main behavior, then verify busy scenes,
   portrait/touch, pauses/transitions and the browser. Keep the full TODO scope visible throughout.

The separate SVG polish is an independent small PR. Review its existing asset-only diff and finish
its visual/CI gate; do not expand it into the PNG overhaul or change gameplay to accommodate it.

## Git and verification

Commit and push frequently, **especially before changing direction**. Rejected ideas belong in
the overhaul branch's history, not dangling feature branches. An ancestry-only merge preserves
an experiment without adopting its files; `git show <commit>:<path>` retrieves it using the archive
index. Do not force-delete an unmerged branch. Active isolated worktrees are temporary and are
removed after their work is preserved. Inspect `git status`, `git worktree list` and remote PRs
before assuming anything about checkout state.

Use `./tools/check.sh`, `./tools/lint.sh` and focused test filters. Full-suite verification belongs
to PR CI. Read the actual result; a partial suite or headless boot proves neither visual quality
nor successful complete gameplay. No completed-test claim applies to an untested scaffold.

Godot windowed runs affect the player's screen and can stall on focus loss. Headless first;
use a small number of purposeful captures with an **external timeout**. A prior macOS launch
aborted before the game started; subsequent bounded escalated captures exited normally. Do not
blindly repeat sandboxed window launches. `tools/shot.sh` accepts seed/day/walk/touch flags and
`RESOLUTION`; choose the complete capture case before opening the window.

`tools/serve-web.sh` exports debug and serves the local web build without deployment. Browser
performance and real-touch behavior still need verification. Keep capability overrides usable.
After import/export, inspect `git status` and `git diff project.godot`; editor rewrites can remove
settings/comments or alter documentation whitespace. Keep source references and import sidecars
committed; never commit `.godot/`.

Before stopping, update this handoff, the main handoff and the open queue; archive history in
DECISIONS, run lint, commit and push. Tell the player what remains incomplete rather than presenting
a source-art draft as a finished game overhaul.

### Superseded text from docs/ILLUSTRATED-GAMEPLAY-FIXES.md

# Illustrated gameplay repair instructions

This brief addresses [the gameplay capture](../evidence/archive/session-captures/2026-09-06/illustrated-gameplay-review.png).
The capture is dated evidence, not an approved art reference. These are implementation
instructions from inspection of that frame, its source sheets and the current compositors;
they are not a claim that repairs are implemented or visually accepted.

[PLAYTEST-45](../playtests/PLAYTEST-45.md) adds directional leg posture, natural mother-to-handle reach,
pram image quality and actual-checkout loading to this repair. Follow the illustrated-png
skill's [texture integration procedure](../../.claude/skills/illustrated-png/references/texture-integration.md)
for repeatable source, import, registration and acceptance steps.

Read `CLAUDE.md`, `HANDOFF.md`, `PLAYTEST-30.md`, `VISUALS.md` and the M84 record in
`DECISIONS.md` first. The handoff identifies the illustrated presentation and street study as
rejected; descriptions elsewhere of an approved street gate do not authorize reusing that study.
Use the supplied mother and urban reference images named in `VISUALS.md` for art direction.
Keep the cardinal camera, logical bodies, movement, collision, crowd density and gameplay RNG.

## Implementation contracts

Runtime registration must describe actual painted parts: per-facing crops, crop-local joints,
rest axes, scale and draw order. A declared grid or a passing parser does not establish connected
anatomy. Compare the rendered output with the source artwork and the ground contacts; the dated
frame's diagnosis is evidence rather than a description of every later implementation.

PLAYTEST-32 requires the original drawing beside each illustrated object at a fixed horizontal
offset. The compositors expose a 96-world-pixel comparison offset. Use the legacy yeller as the
pedestrian scale comparison and judge complete assembled bodies, not transparent sheet bounds.

The real-world inputs under `docs/reference/` supply stroller posture, continuous shopfronts,
recessed entrances, awnings, fire escapes, flat roofs, parapets, skylights, ducts and equipment
clusters. Translate their structure into the supplied illustrations' style. Keep references out
of runtime assets. Inspect the stroller video for movement before making claims about its turns.

Preserve the current joystick/tap choice and button behavior. Event and crowd artwork must preserve
the excitement halo that traces the actively contributing entity's silhouette: a layered PNG
replacement needs the outline of the animated assembly, not an invisible legacy body. Keep the
source selection across events, walkers and cars. Hue and transparency both follow each source's
attributed meter contribution over the last five seconds, with their separate curves and easing.

## What the frame establishes

| Visible issue | Repair priority |
| --- | --- |
| Detached trouser segments and tiny shoes surround pedestrians across the frame. | Reconstruct one complete registered pedestrian before expanding variants. |
| At the centre, the mother's head/clothing overlap near ground level while legs float above; the pram reads as separate horizontal slices. | Rebuild attachment transforms and the pram asset registration. |
| Pale rectangular speckling surrounds the central pram. | Inspect source transparency and crop contamination before attributing it to an occlusion effect. |
| Detailed cutout people sit in a flat, sparsely detailed street with large plain building surfaces and simpler vehicles/props. | Integrate a coherent illustrated environment after the actor assembly gate. |
| A large developer readout covers the right street; tutorial text dominates the lower centre. | Separate diagnostic evidence from a clean gameplay composition review. |

A still cannot establish foot sliding, frame-rate stability, correct recycling, or how limbs
behave while turning. Those need movement evidence. Nor does this frame prove a traffic,
collision or density defect: do not change those systems to hide a drawing problem.

## 1. Make the sheets and their manifests agree

Start in `assets/illustrated/modular/`, `assets/illustrated/walkers/` and
`src/visuals/directional_parts.gd`, which maps sheet regions and pivots to sprites.

- Inspect every direction crop at source resolution and assembled gameplay size. Measure actual
  artwork bounds and attachment points; an equal grid and a declared direction order are not
  evidence that a generated image follows them.
- PLAYTEST-44 selects `pram-layered-v3-draft-transparent.png`. Its eight views contain chassis,
  seat, canopy and baby layers packed at different vertical intervals. Register each against
  measured wheel, hinge and seat contacts; equal-height row cuts are not valid for this sheet.
- Map actual facings explicitly to N, NE, E, SE, S, SW, W, NW, with N meaning screen-up.
  The mother's source begins with its front view; the selected pram begins with its rear view.
  Their column mappings are independent. Check matching mother and pram facings together.
- The mother's painted parts are independently packed into rows. The torso already includes
  arms, and the shoe area contains additional shoe drawings. Extract exactly the part named by
  each registration; remove duplicate anatomy from newly authored modular layers. A whole row
  cell must not contribute unrelated shoes or a second pair of arms.
- Walker source silhouettes cross nominal column boundaries, and profile views provide only
  one complete leg set. Use measured per-part regions and explicit left/right ownership.
  Record any same-facing source reuse explicitly; a neighboring fragment or mirrored direction
  cannot stand in for a missing part. Distinct inner/outer profile artwork remains an authoring
  requirement where the single supplied profile cannot express it.
- Use one authoritative machine-readable manifest for runtime registration and asset inspection.
  Include crop, crop-local attachment points, rest-axis endpoints, scale, actual facing and
  per-direction order. Validate texture bounds, required parts and missing directions loudly.
  Stop construction cleanly after failed validation: callers must not ignore a failed
  registration and dereference a null sprite. A missing file, duplicate source direction or
  missing direction mapping must not silently select another view. Introduce strict endpoint
  requirements together with valid replacement registrations, so the schema change and its
  consumers agree in the same implementation item.

PLAYTEST-44 accepts the selected pram's extracted transparency. Preserve that PNG while repairing
registration. Its extraction record is `assets/illustrated/modular/pram-alpha-extraction-2026-09-08.md`.
For any replacement art, inspect alpha values in intended empty areas and composite over contrasting
backgrounds: an alpha channel alone does not establish a clean edge. Do not erase every pale pixel;
highlights belong to the drawing. Follow the image-generation skill for replacement raster art.

Acceptance: every isolated crop contains only its named part; every direction can be assembled
into a complete static person/pram with no foreign fragments, checker rectangles or duplicate limbs.

## 2. Rebuild attachment transforms from a common ground anchor

`src/visuals/modular_person.gd` must assemble upper-body parts against measured anatomical targets
and pram layers against one chassis frame. Independently packed source rows have their own local
coordinates; their pivots are not interchangeable positions on the actor.

- Define a per-direction rest skeleton relative to the owner's ground anchor: pelvis, neck,
  shoulders, hips, knees and ankles, plus hand and pram-handle contacts. Derive body placement
  from that skeleton. A neck pivot goes to the neck target, not to the actor origin.
- For a cropped part, transform a texture point as
  `target_joint + rotation * scale * (texture_point - crop_local_pivot)`.
  Keep texture pixels, actor-local drawing coordinates and world ground coordinates explicit.
  Apply the source-to-game scale once. The parent already supplies owner translation.
- Assemble rigid pram layers against one shared chassis coordinate system. Preserve their
  designed offsets from axle/ground baseline; do not collapse canopy, basket and wheels onto
  their separate pivots at a common position.
- Author per-facing pram placement that visibly
  joins the mother's hands to the handle. The combined visual stays registered to the existing
  logical owner. Changing its collision shape is outside this repair.
- Keep the handle within natural arm reach. Hand contact alone does not establish correct
  posture: compare shoulder-to-wrist length and elbow shape to the source, and bring the pram
  into reach rather than stretching the arm to an arbitrary offset.
- Calibrate mother, pram and walkers together at gameplay scale. Their torso heights, limb
  lengths and wheel sizes must agree before animation is enabled. The current independent art
  scales and gait lengths are inputs to review, not proportions to preserve blindly.

Acceptance: the idle pose works in all eight directions. Feet and wheels meet the ground,
head meets neck, legs meet hips, hands meet handle, and switching facing does not teleport the
assembly away from its owner. Prove this before tuning a walk cycle.

## 3. Make rendered limbs follow the solved gait

Each painted limb has its own rest axis. `ModularPerson` and `ModularWalker` must map that axis
onto the solved joint segment, preserving transverse width while fitting its longitudinal extent.
Target distances are already world pixels: multiplying the longitudinal ratio by the source-to-world
scale a second time shortens the rendered segment and detaches its distal joint.

- Measure proximal and distal attachment points for each limb crop. Compute rotation from its
  authored rest axis to the desired joint segment. Match the rendered segment length to the
  solved length with suitable authored proportions and controlled longitudinal scaling.
- Make the upper leg end at the rendered knee and the lower leg end at the rendered ankle.
  Apply swing-foot height to the ankle used by the leg as well as the shoe; lifting only the
  shoe separates it from the shin.
- Keep `PlantedGait`'s world-ground stance constraint, but verify the rendered sole after all
  sprite transforms. A correct invisible foot target does not prove that the shoe lands there.
- Drive travel from applied displacement, including collision and shoves. Verify idle, walk,
  run, abrupt stop, reverse, turn, blocked movement and reset/recycle. Zero applied travel must
  not keep advancing a walking cycle. Maintain direction hysteresis without mismatching parts.
- Review east/west leg slant and north/south outward spreading explicitly for mustard and red
  walkers. Separate the ground stride from screen-space knee bend and swing lift; per-facing
  natural posture is a gate beyond connected endpoints. Cover every direction in movement
  evidence because the sampled review scene concentrates on south and north.

Acceptance: a planted rendered sole remains fixed against paving during stance; swing feet
lift and land connected to their legs; stopping and turning leave a complete connected actor.

## 4. Order whole actors and their parts correctly

Internal part order depends on facing. Keep that order within one actor assembly; positive child
z offsets can otherwise sort one person's shoes over another person's torso. Being a child is not
itself proof that the parts sort as one actor in the city.

- Author near/far leg and arm order for each facing. Put the pram in front of or behind the
  relevant body parts according to the view, with hands visibly meeting the handle.
- Inspect the actual actor/city sorting hierarchy. Keep internal part ordering confined to
  the actor's visual assembly so one person's shoes cannot sort through another's torso merely
  because all shoes share a higher z value. Sort world overlap using ground depth.
- Verify crossings between two people, player and car, and actor and foreground roof in both
  directions. Preserve stable local dotted occlusion and readable existing danger/baby cues.
  Do not use transparency to disguise a disconnected assembly.

Acceptance: each person reads as one body at overlaps, the pram occludes coherently, and roofs
do not hide the player or approaching threats. Review consecutive frames as well as stills.

## 5. Resolve the presentation mismatch and review composition

The live illustrated switch binds characters; it does not make the standalone illustrated
street the live city. Do not report the environment fixed because its separate scene renders.

- After actor assembly passes, build a representative live apartment frontage, pavement and
  crossing from the supplied urban references. Use consistent painted materials, line weight
  and apparent scale with the actors. Keep passable ground and crossings legible.
- Give the large plain building areas credible roof structure and multi-storey frontage,
  entrances and appropriate street detail. Use camera-specific depth compression and reviewed
  occlusion to retain visibility. Do not add visual doorways that imply nonexistent routes.
- Replace vehicles and authored props/events by their own reviewed families. Keep incomplete
  families explicit; generic pedestrians cannot substitute for event identities. Expand modular
  crowd variation only after the small initial set shares reliable joints and proportions.
- Produce a clean gameplay view without the diagnostic readout alongside targeted diagnostics.
  Review HUD/tutorial hierarchy against the current control behavior, including portrait/touch.
  Do not remove useful diagnostics or change the tutorial solely because this debug frame shows
  them. Do not inherit obsolete title choices from the graphics handoff.

## Verification and handoff

`scenes/dev/illustrated_actor_review.tscn` displays static mother/pram and both walker variants
in all eight directions at logical scale, with ground baselines and the legacy drawing at the
fixed comparison offset. It instantiates compositors only, so it does not move gameplay actors.
Run it with Godot's normal scene argument; the existing screenshot flags work:

```sh
godot --path . res://scenes/dev/illustrated_actor_review.tscn --resolution 1280x720 \
  -- --screenshot /private/tmp/illustrated-actor-review.png --after 1
```

Use an external timeout for a windowed capture. This is a static registration diagnostic;
it cannot establish motion quality, live-world sorting or visual acceptance. Light actor-row
backdrops expose the dark frame and limb contours. Dated captures and their exact build limits,
including the [contact review](../evidence/archive/session-captures/2026-09-08/illustrated-limbs-contact-review.png),
are indexed in DECISIONS.md under Limb attachment repair.

`scenes/dev/illustrated_motion_review.tscn` samples the compositors through applied-displacement
sequences: idle, initial stride, each foot in mid-swing, sustained walk, run, blocked stop,
reverse and reset. Most samples face south for comparison; the reverse faces north. Foot ticks
show the solver's ground targets so the rendered shoe can be compared with its intended contact.
The virtual owner position accumulates travel while each display cell stays fixed. Run this
scene with the same bounded screenshot command, substituting its scene path and output name.
It checks sampled assembly poses; it does not establish smooth motion or live city sorting.

Run `./tools/test.sh visuals limb_attachments mother_attachments --illustrated` for the focused
registration, rendered-endpoint and displacement checks. Exercise the legacy path with
`./tools/test.sh visuals`. The live-owner test checks that the opt-in child is absent in legacy
mode. A zero-failure assertion summary does not excuse a script error.

PLAYTEST-42 requires higher raster resolution for the current view: preserve the physical window,
visible world extent, actor size, HUD and input mapping, and downsample additional rendered pixels.
A wider camera view does not satisfy the request. For the same-view raster experiment, use
`--illustrated --illustrated-render-scale 2` at the same `1280x720` window size. The scene keeps
its existing 2× camera framing, so the visible world, actor size, HUD layout and input coordinates
remain the baseline while the root target draws at `2560x1440` and resolves each 2×2 block before
it reaches the `1280x720` window. The command is debug-only and does nothing to legacy presentation.
Compare the printed logical, target and output dimensions before reviewing a capture; the saved
root-viewport PNG is resolved render output, not a pristine high-resolution source. The experiment
is not visually verified; its open checks are in TODO.md and HANDOFF.md. Resolution does not
establish a fix for anatomy, gait, compositing or source-art noise.

Implement in bounded sequential pieces: sheet/manifest repair, static assembly, gait and sorting,
then environment integration. Use isolated implementation worktrees under the orchestration
rules; the orchestrator owns queue changes and visual acceptance. Load the path-matched skills,
especially illustrated-PNG, Godot and verification; load city/crowd/cues rules if those areas change.

Run `./tools/check.sh`, `./tools/lint.sh` and the affected focused suites. Extend the existing
visual tests to check rendered attachment continuity, sole placement and clean reset behavior,
not just sprite existence, region count or the solver's own coordinates. Compare equivalent
legacy/illustrated scenarios to ensure the presentation changes no simulation state.

Use a bounded contact/movement review covering all facings and at most one or two purposeful
windowed captures at the end. Include the capture's visible seed, 3224974826, when reproducing
the busy street; the screenshot alone does not supply the exact original route or build state.
Save new evidence under its dated session-capture directory. Inspect native gameplay size,
overlap, clean alpha and motion. If a display is unavailable, report the visual gate unverified.

Keep the illustrated presentation review-only until the player accepts the repaired result.
Report each repaired defect, the checks and images supporting it, and any remaining family or
motion gap. Passing headless checks cannot override visible disconnection in the rendered game.

### Superseded text from .claude/skills/illustrated-png/SKILL.md

---
name: illustrated-png
description: Add or revise illustrated PNG textures and their reproducible integration workflow. Use before changing assets/illustrated or src/visuals, or preparing an illustrated checkout for testing.
---

# Illustrated PNG pipeline

The graphics overhaul uses real PNG assets and compositors. A presentation component reads the
existing simulation; it never becomes a second simulation.

For texture authoring, registration or a test handoff, read
[the integration procedure](../references/texture-integration.md). It carries the ordered checks,
coordinate conventions and failure diagnosis; use the existing commands before inventing another
tool. Historical incidents and measurements belong in `docs/DECISIONS.md`, not in this skill.

## Reference authority

Inspect these images before generating or accepting illustrated art:

1. `docs/evidence/graphics-reference-mother.jpeg` defines the mother and pram: high brown bun,
   green coat, patterned scarf, jeans and practical dark shoes.
2. `docs/evidence/graphics-reference-urban-01.jpeg` and
   `docs/evidence/graphics-reference-urban-02.jpeg` define illustrated urban linework, material,
   apartment frontage, storefront density, street furniture, vehicle and pedestrian detail.
3. `docs/evidence/graphics-reference-cardinal.jpeg` is the floor for the available cardinal
   perspective. It does not lower the illustration or material target.

Do not derive style from archived experiments or an unapproved generated concept. Read
`docs/playtests/PLAYTEST-30.md`, `docs/VISUALS.md` and `docs/LUNA_HANDOFF.md` for the current accepted scope
before proposing a new family.

## Asset workflow

- Read the `imagegen` skill and use the built-in generator for new raster art. Inspect local
  reference images with `view_image` before generation so they are available as reference input.
- State the input images' roles in the prompt. Generate a new versioned sibling; never overwrite a
  reviewed source asset without an explicit request.
- A generated PNG must have real alpha where it is layered. Check it with `sips -g hasAlpha`; an
  image of a checkerboard is not transparency. A ground plate may deliberately be opaque.
- Keep a generation record beside the assets: exact prompt, reference inputs, output role, alpha
  result, and any rejected alternative worth avoiding. Keep a manifest beside directional or
  modular sheets.
- Preserve source PNGs and their `.import` sidecars together. Sidecars hold import configuration
  and resource identity; they are repository files even though Godot generates them. A capture
  under `docs/` has none: `docs/.gdignore` keeps Godot out of the whole folder, since nothing loads
  a `res://docs/` path. The ignored `.godot/` directory holds the rebuildable imported cache.
- Record exact extraction commands and tool versions for derived PNGs. Preserve the approved
  source, write a versioned output and inspect retained detail as well as transparent gaps.
- Directional sheets are ordered `N, NE, E, SE, S, SW, W, NW`. Record genuine symmetry explicitly;
  never silently mirror a view. Manifests state regions, pivots, layer order and variant contract.

## Runtime contract

The visual child receives only displacement its logical owner actually applied. It may solve
planted feet, choose an authored direction and update texture regions, but never changes the
owner's position, collision, traffic/crowd rules or gameplay RNG. Reset it wherever the owner is
teleported, recycled or reset.

Do not use a generic crowd look for an authored event, or a generic pedestrian for a car. An
unfinished family remains visibly unfinished until it has its own assets and binding.

Endpoint equality is only a connectivity check. Review natural rest posture, per-facing stride,
foreshortening and arm reach separately. Never stretch a painted arm to legitimize a pram placed
beyond its natural reach. Calibrate complete assemblies, including all pram layers, at gameplay
scale. Check inherited filtering and source alpha before blaming a pixelated result on resolution.

## Preparing the test checkout

After switching or integrating an asset branch, run `./tools/check.sh` in the exact folder the
player will use. A different worktree's successful import does not populate this one's `.godot/`.
`tools/run.sh` detects missing global classes and `.import` sidecars whose imported copy is
absent, and repairs both by running the import pass; `shot.sh` and the headless boot commands
below do not, so a populated class cache alone does not establish that the checkout can draw.

Then boot with `--illustrated` explicitly, using the bounded headless command in the procedure.
Read the first resource/parse error, not just repeated `new()` or nil errors downstream. A normal
legacy boot does not exercise the illustrated binding. Preserve sidecars after the import pass
and inspect the working tree before handing the folder over.

## Review gate

Run `./tools/check.sh` and the focused affected suites; the full suite is CI's job. Inspect
`project.godot` after imports. A visual change also needs one purposeful bounded capture when the
environment permits. Check real gameplay scale, y-sorting, occlusion/cue legibility,
and contact between feet/wheels and ground. If capture aborts or is unavailable, report that visual
validation as unverified rather than claiming it passed.

Do not extend a reviewed asset family to other gameplay families until the player has seen and
accepted the gate that applies to it.

### Superseded text from .claude/skills/illustrated-png/references/texture-integration.md

# Texture integration procedure

Use this procedure for a new illustrated family or a revision to an existing one. The contracts
and commands describe the current pipeline; the dated evidence is in `docs/DECISIONS.md` under
Texture integration process. Keep the accepted style, source-art gate and gameplay simulation
separate from runtime registration.

## 1. Preserve and identify the inputs

Read the selected family's generation record and manifest before making another asset. Inspect
the approved source at native resolution. A runtime screenshot or generated diagnostic does not
become an approved style reference because it is useful for spotting a defect.

Record the exact prompt, reference roles, generator/tool identity when available, output file,
dimensions, actual direction map and any post-processing command. Generation is not guaranteed
to reproduce identical pixels: preserve the actual output as the reproducible input to later
steps. For extraction, preserve inputs and versioned outputs; do not overwrite reviewed artwork.
Run Python tooling through `uv run python` and the repository lockfile.

For layered assets, check both alpha-channel presence and alpha values in intended empty regions.
Composite over light, dark and colored backgrounds and inspect enclosed wheel/handle gaps. A
checkerboard can be painted into an RGBA file. The existing checkerboard extractor is documented
in `assets/illustrated/modular/pram-alpha-extraction-2026-09-08.md`; its hard-alpha heuristic can
leave jagged coverage and does not reconstruct antialiasing. Do not erase pale fabric or highlights
to clean a background. Follow the image-generation skill for new or edited raster artwork unless
the player explicitly requests another method.

## 2. Measure the artwork, then register it

Use the family's machine-readable manifest as the source of runtime crop/joint data. For each
part and facing, record its actual source region, crop-local pivot, proximal/distal points, rest
axis, ownership, draw order and scale. A generated sheet's apparent grid is not a measurement:
parts can cross columns, rows can be packed independently, a torso can already contain arms,
and one profile can contain only one leg set. Missing anatomy remains an explicit source gap.

The runtime order is N, NE, E, SE, S, SW, W, NW, with N screen-up. Check the body, pram and every
part against this convention independently. The mother and selected pram sheets start with
different views. Do not equate their column indices or silently mirror a missing facing.

Keep these spaces distinct:

| Space | Meaning and conversion |
| --- | --- |
| Sheet pixels | Absolute location in the PNG. Subtract the crop origin to obtain crop-local points. |
| Crop-local pixels | Joint measurements before sprite offset, scale or rotation. |
| Actor-local pixels | Assembled body relative to the logical ground anchor; apply source scale once. |
| World ground | Owner position plus ground-relative offsets; applied displacement drives gait here. |
| Screen projection | Art elevation and foreshortening applied for drawing; a knee bend or swing lift is not ground travel. |

`DirectionalParts.SpriteManifest.apply_segment()` maps authored endpoints to target joints with
an affine basis.
Its longitudinal ratio is target length divided by source-axis length; transverse width uses
the art scale. Applying the art scale again along the length detaches endpoints. Rotate from the
measured painted axis, not an assumed vertical crop. Verify the final transformed painted joints,
not only solver coordinates: compare `sprite.transform * (crop_local_point + sprite.offset)`
with its actor-local target, and inspect whether the measured point actually lies on the painted
joint. An endpoint chosen in transparent padding can pass the transform check. Enable region
filter clipping so neighboring atlas art cannot bleed.

## 3. Assemble a natural idle pose before animating

Use `scenes/dev/illustrated_actor_review.tscn` for all facings at gameplay scale with ground
baselines and the required legacy comparison offset. Compare complete opaque body bounds, not
transparent cells or one component. The complete pram includes chassis, seat, canopy and baby;
sizing only the chassis makes the finished object too large. Keep rigid layer contacts in one
chassis frame, using the measured seat and hinge contacts rather than collapsing all pivots.

Check hips, knees, ankles and soles as a chain. A connected knee can still bend inward, cross the
other leg or sit in a permanent crouch. Inspect the painted anatomy: a crop labeled "upper leg"
can already contain
a knee and shin. Fitting that entire silhouette above a solver knee creates a second visible
bend despite exact endpoint connectivity. Identify the anatomical joint in the pixels before
choosing the crop and axis; each assembled leg must contain one knee.
Ground stride direction and the screen-space knee bend
need separate review: E/W travel must not tilt the entire leg pair diagonally as a substitute
for a walking pose, and N/S travel must not send the feet sideways into a spreading stance.
These are visual acceptance criteria, not instructions to force every projection into one pose.

Place the pram handle within the mother's natural reach, then fit the arms. Inspect shoulder,
elbow and wrist posture and compare arm length to the source. Exact hand-to-handle contact can
pass while the whole arm is stretched unnaturally. For each facing, record shoulder-to-grip
target distance and the authored arm-axis length at the chosen art scale before fitting; review
their ratio with the pose rather than treating arbitrary longitudinal stretch as a solution.
The illustrated compositor reads the legacy
`Stroller.PRAM_DISTANCE`, which also participates in other player presentation behavior; audit
its callers before changing it. Prefer measured per-facing illustrated placement when the
required change is only to illustrated posture. Keep gameplay collision and movement unchanged.

## 4. Check texture quality and motion independently

Trace the visible sprite to its bound source before diagnosing pixelation. The legacy comparison
is deliberately still visible beside the illustrated actor; a missing illustrated child can
leave only that comparison on screen. Check the opt-in flag, registration validity and earliest
resource error to distinguish legacy mode, invalid registration and a missing texture import.
Inspect source detail, extraction edge coverage, crop
size, complete assembly scale, inherited CanvasItem filtering and viewport/camera scaling.
`project.godot` sets `textures/canvas_textures/default_texture_filter=0` and actor parts do not
override filtering. Inspect the effective inherited filter in the assembled actor and the
project setting after import before attributing an artifact to a filter mode. A crisp atlas crop
does not prove good downsampling at gameplay size. Evaluate filtering on the illustrated family
before changing a project-wide setting that affects legacy sprites and UI. Linear filtering
alone cannot restore alpha coverage discarded during extraction.

Distinguish the physical window, logical viewport, visible world extent and raster target when
testing higher resolution. More rendered pixels for the current view must preserve framing,
actor size, HUD and pointer mapping. Reducing camera zoom shows more world and does not meet
that requirement. Verify the actual final downsampling filter; a larger render target followed
by nearest-pixel selection is not an average of the additional samples. An enlarged PNG alone
does not prove increased detail. Record whether captures contain raw samples or resolved output.

Drive motion from displacement the owner actually applied. Exercise idle, walk, run, abrupt stop,
blocked movement, reverse, turns and reset/recycle in all facings. Check stance soles against the
paving after every transform, and lift the shin's ankle together with its shoe during swing.
Keep unfinished steps coherent through zero travel. A frozen intermediate pose can be connected
and still look unnatural; record it as a pose issue rather than passing it as an idle review.

`scenes/dev/illustrated_motion_review.tscn` provides sampled displacement poses, mostly south with
a north-facing reversal. It does not cover smooth motion or all directions. Add the missing
directional evidence to the relevant repair before claiming those cases reviewed. Check live
overlaps separately: children with positive z offsets can interleave between actors despite
sharing a parent. Internal facing order must coexist with whole-actor ground-depth sorting.

Use B to capture a gameplay sequence when a still cannot communicate the defect. The
session-captures skill describes the numbered frames, timing metadata and sibling MP4 conversion.
Keep the sequence with its video and compare actual frame timestamps before diagnosing gait speed.

## 5. Prepare and verify the actual checkout

Keep PNGs and `.import` sidecars under version control, including sidecars for evidence images.
Do not remove them during worktree cleanup merely because they are generated. `.godot/` is the
ignored per-checkout cache, and imported textures in it are not transferred by a branch switch.
Preserve existing sidecar settings; inspect new ones after import rather than deleting them.

Run from the folder that will be handed to the player:

```sh
./tools/check.sh
./tools/test.sh visuals limb_attachments mother_attachments --illustrated
./tools/test.sh visuals
./tools/lint.sh
git diff --check
git status --short
```

Use the installed Godot binary for an explicit bounded illustrated gameplay boot:

```sh
GODOT_BIN="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
"$GODOT_BIN" --headless --path . --quit-after 120 -- --illustrated --walk south
```

Inspect the complete output, including the first error. A missing `.ctex` can cause a texture
preload to fail, then a dependent GDScript to fail compilation, then repeated nonexistent `new()`
and nil-method errors. Fix the failed import/load before altering constructors or adding nil
guards to mask it. A zero process exit or passing assertion count does not excuse script errors;
focused validation suites contain deliberate invalid-input probes, which must be distinguished
from unexpected failures. `check.sh` boots legacy mode, so keep the explicit illustrated boot.

Read `verify` before testing or capturing. Use at most one or two purposeful bounded windowed
captures for visual evidence; headless output establishes loading and geometry, not appearance.
Inspect gameplay scale and light/dark contrast. Preserve a player's whole run folder in
`docs/evidence/`; preserve new diagnostics under the dated session-capture archive. Record the
build, flags, dirty changes and what each image actually covers in `DECISIONS.md`. A capture
from before a correction is evidence of the defect, not proof of the correction.

Report separate outcomes for source approval, registration tests, smooth motion, live sorting
and player acceptance. Keep any unverified or visibly failing gate open. Do not expand a family
or ask the player to rediscover known defects just because the endpoint assertions pass.
