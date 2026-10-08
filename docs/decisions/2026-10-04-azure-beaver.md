# azure-beaver — The task scenes are a handcrafted stretch with a rigged marble bag · 2026-10-05

Filed from [polite-dolphin](../playtests/2026-10-04-polite-dolphin.md) (inbox #555): "it should be 1)
only one stretch of a city with nothing (no ground!) off the path at all. and pedestrians etc and
deterioation and events should spawn like in a real game -- but authored", then "the whole point of
those scenes is that they are not seeded but handcrafted -- you can use a seed to create it. but then
everything should be placed manually. the events should still spawn using the same rules but the
marble bag should be rigged", the width "The streets she walks", and "right now it's just empty" /
"that's not a good test".

## Explicit layouts and ordinary rules

The nine task scenes and station-door corner are stretches. Their recipes explicitly list the
visible tile runs, fronting buildings, street trees, props, litter, cracks, posters and starting
walkers and cars. Nothing outside that stretch draws ground, buildings, shadows, tree pits or
decals. A collision boundary holds the player, pursuers and crowd against the void.

Each recipe also stores the off-camera spatial context that ordinary rules need: tile rows,
block arcs and layouts, districts and region boundaries, home and station, lots and trees.
Runtime loads those lists directly, then applies the visible stretch's authored placements as
the authority. It does not run city generation or compare against a generated witness. The
ordinary task, route and event planners read the resulting explicit map. Authored ground
survives daily repainting and the finale, and authored trees supply their pits and clearance.

`tools/scene-draft.sh` can create a first draft from a seed and route; generation belongs to
that authoring step. The saved scenes derive from route-based drafts and subsequent edits,
with the spatial context serialized for independent loading. This is not a claim that every
placement originated manually or that redrafting gives a byte-identical file. Redrafting
deliberately writes a fresh draft; hand edits to a saved recipe control its runtime layout.

The initial implementation regenerated a context city and refused a saved scene that differed
tile for tile, lot for lot or tree for tree. That witness preserved a seed dependency and did
not satisfy the original request. On 2026-10-08,
[mossy-marmot](../playtests/2026-10-08-mossy-marmot.md), inbox #618, records the explicit choice
"Finish fully handcrafted layouts now (Recommended)". The independent loader implements that
choice inside this PR; retaining the witness and handcrafting later is rejected.

## Activity, boundaries and authored choices

Events use a rigged route bag through the ordinary director. The bag specifies its marbles,
pre-bag, owed count and first due time; ordinary event placement, spacing, pursuit and danger
still apply. Enabling that director also keeps its owed places on the route and later-day return
patrols. The `appeared` observation requires an event to have reached the visible play area;
an instance existing behind the camera does not satisfy it.

Starting walkers and cars are explicit. A body recycles only after leaving the whole camera,
and its accepted replacement, including its final queue position, must also be outside the
view on authored ground. A visible stretch end produces a turn, or a car waits or turns off
before it. No hidden full-map street supplies a visible spawn. Regression coverage observes
actual accepted entries and visible turns across all ten stretches rather than accepting a
run with no recycle activity as proof.

Small authoring choices remain open to the player's correction:

- The stretch includes complete traversed street segments, both sidewalks and their junctions,
  nearby off-street tiles, entered alleys, task corners and the neighbor's route home. The
  day-12 park is the patch around the path and swing. Fronting lots include diagonal neighbors.
- Every stretch lists walkers and cracks. Days 6–11 also list cars. Day 6 has neither litter
  nor posters; day 9 and the station corner have no posters. The other stretches list both.
- The cat precedes the ordinary bag and is first due at 3 seconds, except day 9 at 6 seconds
  and the station corner at 0.5 seconds. All ten saved playbacks satisfy the visible-event
  observation. The earlier claim that the cats in days 6–8 never enter view is not the result
  of the completed implementation.
- Task placement uses the scene's own streets. Distances in the assertions include the
  difference between the mark and the point where she reads it: 540–644px for the nearby
  placed targets and 540–676px for day 9 and day 12. The neighbor retains its own 400px rule.
- The fire-truck scene is full-city, and the station hall and yard are bounded constructions.
  Trailer recipes keep their own declared extents; they are not all classified as full-city.
- Day 9 and the station corner have no sufficiently distant authored start for the sent
  robber, so the ordinary placement search finds no site. No gameplay immunity is added.

The day-7 playback ends at tick 292, when its task completes. The retained earlier trial
continues one tick farther and is caught by the sent guard under the ordinary warning rules.
The endpoint is not evidence that waiting beside the van is safe. The fire-truck route instead
manages noise by retreating north after seeing the fire, then returning partway to watch. It
shows the engine moving at tick 114, visible at 294 and parked at its exact kerb at 414, with
ordinary danger and the original scene duration intact. Its waiting-route crying loss and
the intermediate timing counterexamples are retained with the passing result.

## Evidence and verification

[Authored-scene evidence](../evidence/azure-beaver-authored-scenes-2026-10-08/README.md)
retains the twenty start/later stills, recipe hashes, observation manifests, contrary results
and capture provenance. The stills use clean source `deb809f1f5ec342521139868eb336908192f99d8`,
Godot 4.7.2 and run seed 11. They establish visible layout and contents, not smooth movement
or absence of pop-in. The first covered-window movie repeats stale frames; its selected
decoded frames, hashes and settings are retained as a failed capture, not motion proof.

Main's task-arrow change is reconciled at `3ae27750`: the task-6 and task-13 recipes retain
their explicit layouts while checking that the target is arrowed at tick 60. The scene table
keeps its corrected measured distances. A further interaction required the arrow ground mask
to block the authored void: the optimized field reads raw saved tiles, which otherwise include
hidden streets. A five-by-five U-shaped authored street provides the counterexample. The raw
context chooses the target across a four-tile hidden shortcut; the actual walk chooses the
closer target along the visible U. The corrected mask produces that walkable choice without
changing ordinary generated fields. The two affected playbacks and focused resistance/stretch
checks pass on the integrated source.

Focused city, crowd, scene and ground checks pass, including explicit edits after changed
drafting inputs, dawn/finale persistence, invalid-data rejection, visible-event assertions
and actual crowd recycling. Capture and action wrappers reject engine errors even when Godot
exits with status zero. Linux CI at `9f82d43ad55ad55e4eec464d33917dfa83b59af8` passes after the
capture fixture isolates atlas availability while exercising the real wrappers. Human free
play remains the question in [the scene review](../review/2026-10-04-azure-beaver.md).

## Development recipes stay local

[Pebbly-hare](../playtests/2026-10-08-pebbly-hare.md), inbox #622, asks whether the scene
recipes have a Godot ignore file and whether they ship in production. The audit of published
v0.25.5 finds 22 development recipe JSON files in its package. The assistant proposes excluding
these development inputs while preserving local scene tooling; no gameplay or release change
is requested by this packaging correction.

The recipe directory now has `.gdignore` and an explicit export exclusion. The fatal PCK audit
rejects recipe paths, with a packed-fixture regression that would fail if they returned. Local
tools still load the plain JSON from the source checkout. A real release-style Web export at
`85f0ee3e5814c0bff7f7a561265f24048ce7ef9a` contains 336 files and zero development recipes;
the previously published package has 352 files and 22 recipes. The compact listings, exact
commands and both package hashes are retained in the authored-scene evidence folder. Neither
whole package nor export/template scratch is kept. These audits did not publish a release;
the v0.25.5 measurement describes the published package inspected at that time.

CI on `f35292439b7e1eb308e23576b0c02838b31cef08` passes, including both browser jobs and the
full game checks. That checkpoint did not include final integration with the trailer's
recording/camera changes or a usable motion capture. The failed covered-window movie remains
a failed counterexample.

## Derived geometry and camera observations · 2026-10-08

The independent source review finds two gaps that the initial editable-layout checks miss.
An authored building's height and variant are applied after roof joins and shared courtyard
tint have already been derived. In the concrete day-7 pair, raising lot `[90,56,2,6]` from
two to four stories leaves its touching front lot `[90,62,2,8]` with roof-extension rows
`[2,2]`. Commit `a262356a` applies authored district, variant and height while constructing
the building, before those dependent relationships. The live regression now requires the
front extension to reach the actual four-story rear wall, and the original probe reports
`[4,4]`. Ordinary generated-building construction keeps its existing order and inputs.

The event's visible-drawing observation also uses a fixed 640×360 world rectangle rather
than the current camera. With a 1280×720 viewport at zoom 4, a 32-pixel actor centered
250 pixels right of the camera passes despite being entirely beyond the real 160-pixel
half-width. Commit `07c2221f` inverse-transforms all four live viewport corners through the
canvas transform before applying the existing rendered-body and joystick-corner overlap
test. The original probe then reports both `appeared=false` and `in_picture=false`.
Regressions cover the default view, that zoomed-in counterexample and zoom 0.5, where the
same offset is visible. The actual transform also supplies the view orientation.

At source `07c2221f5514671e32d90655ee53350cbe79e527`, the focused scene suite passes 42 checks,
the all-stretch crowd suite passes 147, and ordinary ground-floor/visible-view suites pass
31,869, each with zero failures and a clean exit. Import/boot, lint and diff checks pass.
These bounded repairs do not establish trailer integration or moving capture. The independent
delta review below checks their source and remaining geometry behavior.

The delta review confirms the height repair and camera behavior, including a portrait
transform, but finds the courtyard-tint repair incomplete. In the day-14 recipe, editing
visible lot `[118,34,13,4]` to variant `123456789` leaves its tint at `3792558343`, selected
from hidden, unlisted context lot `[118,48,22,8]`. Applying authored values before sharing
is insufficient when the sharing pass still chooses its source outside the visible authored
members. This counterexample requires the further construction correction below.

Source `6669a4c67e2a0436f599a364355559247030ea6f` makes a partial authored courtyard use
its first shown, authored member in canonical building-rectangle order as the shared-tint
source. Hidden context members cannot select the visible color. In the concrete day-14
case, both visible members now receive tint `123456789`, while each keeps its own authored
variant for its other details. Ordinary generated cities keep their complete courtyard's
first-piece choice. Selecting the first authored member preserves the one-tint courtyard
rule; this small authoring convention is documented in CITY and remains open to correction.
The real-City regression requires both visible members and checks their actual tint and
individual variants. The focused scene suite passes 46 checks and the ordinary ground-floor
suite passes 31,807, with zero failures; import/boot, lint and diff checks pass. No native
capture or whole-game local suite accompanies this bounded repair. Trailer integration and
motion evidence are separate from those checks.

## Trailer integration and covered-window motion · 2026-10-08

Merge `751b61c5389dc8af0ae404ee87d36ddf2bbea1c1` combines the authored scenes with main
`af405524a0ab998b7962ce1c70a889e32e28cf63`, including the trailer camera and task arrows.
The two textual conflicts retain both the fixed/settled camera and asleep/awake/near-player
observations from main, and the authored scene's moving-crowd and rendered-body observations.
Distance validation and crowd-only key validation remain separate, so a near-player
observation cannot silently accept a walkers or cars field.

Authored stretches and recipe exteriors both have unlimited camera bounds. The scenery
lookup rejects authored void before applying any exterior or outside-map landscape. Ordinary
player cameras start synchronized and clear their limits, while authored interiors retain
their bounds. Stretch crowd entry checks the complete view and the final queued position;
a visible end produces a turn or wait. Ordinary traffic retains its hidden tunnel and bridge
entry depths. The two saved day-6 and day-13 recipes pass their exact arrow assertions.

The first native covered-window recording after integration still fails: its 584 frames
contain only five rendered states, including one 457-frame, 7.62-second repeat. Deferring
the recording-only forced draw misses the movie writer's capture boundary. Source
`4e8ec04e3dfaff91347ae576d9efb0e9f8f0baa5` calls the draw synchronously only when recording
and the window cannot draw. Visible recordings and non-recording play use the ordinary path.

The repeat at that clean source renders all 584 frames at 60 FPS over 9.73 seconds, with
every adjacent whole-frame hash different. Its twelve observations pass with no violation;
the route event first appears at physics tick 181, and visible moving activity changes from
three walkers and no car to five walkers and one car. The decoded early, middle and late
frames show the player, camera and crowd moving as the task is offered and completed.
The [evidence folder](../evidence/azure-beaver-authored-scenes-2026-10-08/README.md) retains
the selected frames, complete hashes, settings, manifest, engine log and failed counterexample.
This is motion proof for one covered-window day-7 playback, not every scene or every possible
crowd entry. The ordinary free-play questions remain in the scene review.

The combined focused Godot run passes 102,141 checks with no failures across the scene,
crowd, ground, camera, recording, main and resistance suites. After the synchronous-draw
correction, the focused recording suite passes 207 checks. Import/boot, lint, the 334 CLI-help
checks, both saved recipe assertions and whitespace checks pass. The full game suite remains
CI's gate. The completed construction and integration item leaves the queue; the human
free-play review is retained.
