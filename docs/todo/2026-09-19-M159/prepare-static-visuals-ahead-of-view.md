**Prototype nearby scenery preparation and distant visual eviction.**

The player asks to prepare scenery shortly before it enters view, initially around home, and to
unload it at greater distance. They hypothesize that much of the prepared map is never seen and
question cross-day ground reuse because appearance changes. They ask:
"can we do them lazily instead whenever the player gets into x tiles from them (when the image is still off-screen)?"
Their full words are in
[sunny-lynx, measure the work in a crowded scene](../../playtests/2026-09-26-sunny-lynx.md) and
[gentle-swan, investigate lazy scenery preparation and unloading](../../playtests/2026-09-30-gentle-swan.md).

The [investigation record](../../decisions/2026-09-19-M159-3.md) and
[measured report](../../evidence/m159-lazy-scenery-2026-09-30/README.md) establish a native headless
preparation opportunity and its limits. What remains is a bounded prototype and acceptance
checks. The actual generated-route envelopes establish the expected-workload baseline, with
individual options and the whole offered network reported separately. They do not measure human
trajectories, and detached-layer allocation is not browser heap, GPU allocation or
operating-system reclamation. The player says
"let's focus on the one thing first": this item stays about nearby scenery and unloading; the
measured route-planning cost does not open another optimization task.

For expected coverage use the actual daily generated route choices with closures applied. The
player explains that alternatives are blocked or heavily discouraged, and a determined player
going off-path is likely to lose. The simplified nearest/farthest BFS samples are not that
baseline. Keep deliberate off-path travel as a stress case. Record modeled offered-route
coverage accurately without claiming observed human trajectories.

Boot uses the same nearby-only policy: "the boot paint should only be for the block around home"
and "lazily create distant ones as the player comes near". A literal home block does not fill the
measured initial viewport. The player clarifies: "block around the home means plus margin otherwise you might get gaps".
Cover the home-centered initial viewport plus an off-screen margin. The exact margin remains
unchosen; do not prepare the whole
city or accept visible holes in its place.

The player confirms: "I do like the larger unloading be a requirement." The unloading radius
must exceed the loading radius so walking
back and forth across the load boundary does not repeatedly create and destroy scenery. Between
the two boundaries, preserve residency: loaded scenery stays loaded and absent scenery stays
absent until it enters the load boundary. Choose the distances from measured preparation cost
and camera movement; their ordering is required, while exact values remain unchosen.

**Proposed, not yet a chosen implementation:** make map-specific ground cells resident in freeable
chunks and prepare inside the view plus an off-screen margin under a measured work budget.
Apply the player's wider unloading boundary to those chunks. Clearing a single growing TileMapLayer does not demonstrate
memory release. Cross-day composition reuse is not a prerequisite. Keep shared baked pages and
runtime ground composition at permitted loading moments; cell eviction does not eliminate the
shared sheet. Preserve Playtest 108's runtime composition choice and M147, every picture loaded
before it is needed: no first-visible-frame disk reads or shader compilation.

Keep city data, collision, routes, event placement and off-screen gameplay ready independently.
Buildings retain their persistent identity and collision; separate visual preparation before
evicting artwork. Reconstruct stable seeded appearance without changing gameplay RNG order or
resampling art on approach. Static surfaces stay still, with animation in separate overlays.
Existing shadow culling is not a new streaming benefit.

Reconstruct current visuals for day/condition changes, posters, blackout, closures, emptied tree
pits, home seals, litter, live ground/block changes and restart. Revisiting an area changed while
unloaded must not revive stale scenery. Eligibility uses full visual bounds, including roof
overhang, shadows, trees and station stacks, rather than origins.

Choose chunk size, work budget and entry/retention margins from measured worst-case preparation,
viewport size, maximum approach speed and camera look-ahead. Prepare initial view, fast reversals
and camera relocation without blank scenery, pop-in or first-visible-frame work bursts. The
investigation's illustrative margin is not a shipping value.

Compare startup/day-start latency, complete-frame median/tails/max, memory and preparation work
on identical actual routes. Include fast approach, leaving/returning across the retention
boundary, repeated reversals across the load boundary while staying inside the unload boundary,
overnight changes outside residency and camera jumps. Verify the reversal case causes no repeated
preparation/eviction. Use rendered evidence for seams
and pop-in; distinguish native CPU findings from phone/browser/GPU confirmation. Accept only a
measured benefit without stale/missing scenery or walking hitches.
