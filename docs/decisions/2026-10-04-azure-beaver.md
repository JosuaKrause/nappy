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
whole package nor export/template scratch is kept. This verification does not publish a new
release; the live v0.25.5 package remains the old one until a later release.

CI on `f35292439b7e1eb308e23576b0c02838b31cef08` passes, including both browser jobs and the
full game checks. Final integration with the trailer's recording/camera changes and a usable
motion capture remain required by the queue; the failed covered-window movie is not recast as
a pass.
