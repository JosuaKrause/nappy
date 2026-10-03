# Scene composition and action evidence

Ten requested stills, their capture manifests (`*-capture.json`), and their complete headless
action manifests (`*.json`) are retained here. Generic logs, incidental screenshots and
duplicate takes are omitted. The manifests identify the recipe hash, construction context,
engine, physics rate, initial state and observations; capture manifests identify the exact
frozen tick and actors. A capture ends at its selected moment, so its `playback_complete` is
false; the separate headless manifest proves that the complete scripted action passes.

| Stills | Source revision | What the still establishes |
|---|---|---|
| `power-station-hall`, `power-station-yard` | `8941448c` | Real adjoining dead-end walls: the hall covers the facade, the fenced yard keeps it. |
| `trailer-choice` | `1f0823ed` | A uniformly populated alternate street after the mother's wrong-way approach and backtrack; selected restaurant guests are one block east. |
| `trailer-birds` | `1f0823ed` | The father and existing pigeon flock on an industrial side-street block, with ordinary roads throughout the frame. |
| `trailer-dog` | `1f0823ed` | Charging dog beside a skylight roof, moving pedestrians on every pictured street, and the foreground tree moved across the road. |
| `trailer-gatehouse` | `052fb4c1` | The father approaching horizontally toward the existing vertical gate. |
| `trailer-title` | `d7a56707` | The father walking inside the park, with the adjacent road visible. |
| `trailer-trucks` | `9768f6de` | Three army trucks beside the south-facing mother, varied posters, and the existing vertical roadblock at the left street mouth. |
| `trailer-chase` | `052fb4c1` | A visible carrying stride beside a pursuing guard. |
| `trailer-city` | `052fb4c1` | The complete active city after zooming out from the mother's doorstep. |

Sources are reachable through PR #457. Godot 4.7.2 stable, macOS Apple M2, Compatibility OpenGL,
1280×720, 30 Hz physics. Reproduce at the listed source with
`tools/scene-recipes.sh --recipe scene-recipes/NAME.json --screenshots --output /tmp/new-scene`.
The command uses `--player-view`, `--no-save`, scripted playback and the saved `capture_at`.
Fetch `refs/pull/457/head` when a source revision is absent locally. No video is made.

Scenes 3–5 each use 400 production walkers in their moving field, twice the ordinary act-1
count, and the ordinary 34 cars. Initial walkers are sampled evenly along eligible sidewalk
lanes with varied seeded walking directions; recycling gives pedestrian corridors equal weight.
An overcapacity request is rejected. Movement, body clearance, turns,
collisions and traffic use production behavior. Ordinary gameplay keeps its own population
and street hierarchy. Each pictured street is measured separately at the frozen capture tick:

| Scene | Horizontal street walkers (moving) | Left vertical street walkers (moving) | Right vertical street walkers (moving) | Left/right picture halves |
|---|---|---|---|---|
| Choice | h4: 17 (16) | v4 main road: 10 (10) | v5 side street: 13 (13) | 15 / 25 |
| Birds | h3: 15 (15) | v5 side street: 11 (11) | v6 side street: 10 (10) | 17 / 19 |
| Dog | h5: 13 (13) | v3 side street: 7 (7) | v4 main road: 14 (14) | 14 / 20 |

The bird block is explicitly industrial and one block east of the first bird preview; its
two existing building footprints and shallow roof make a different side-street composition.
The dog scene moves the actual street tree, its pit and its planning footprint from tile
[50,74] to [50,71], the opposite curb of the same street. The title walks south on park ground
from [1296,1712], with the road visible at the right. No new graphics or gameplay objects are used.

The truck capture uses the runtime and west-mouth recipe committed in `9768f6de`; that edit
was uncommitted during capture. Its recipe hash and full action are retained in the manifests.
All revised captures use ordinary vulnerability and no invincibility flag.

The revised scenes use production crowd simulation and only explicitly selected events and structures.
The normal event scheduler and seal selection do not add unrequested objects.
The truck formation is the actual day-13 happening; its spacing is not a trio of lookalikes.
The gate is a real region checkpoint. The choice scene's leaf blower is a composition choice;
the requested action is the turnaround and other route. The manifests check all three phases.

At capture tick 42 the chase records speed 168, carrying, contact gait frame 2 and an active
pursuing guard; the same-tick observations match. The production carrying animation uses the
same three pictures for walking and running, with faster cadence at running speed. This still
shows the clearest existing contact pose, not newly drawn running art. Stills establish
composition; action observations and displacement checks establish movement.

The wide city capture reports 2,048 visible walkers and 344 visible cars. The population
test checks moving walkers and cars in every quadrant. This recipe explicitly
populates the whole view at the ordinary field's area density; ordinary game density is
unchanged. Its population test checks actual displacement in every quadrant. Close-scene
`capture_activity` counts instead cover actors whose ground positions are in that picture;
visual review checks occlusion separately.
