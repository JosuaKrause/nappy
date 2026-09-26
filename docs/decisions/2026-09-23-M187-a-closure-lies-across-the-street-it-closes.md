## M187 — A closure lies across the street it closes · built 2026-09-23

*(Found by the street-obstructions redraw, PR 301, and queued with the player's agreement; the
pictures' style is accepted, [PLAYTEST-124](../playtests/PLAYTEST-124.md), statement 7.)* Each
closure cause was one picture drawn lying left to right, so on an east-west street the fallen
tree, the crashed cars, the rubble and the roadworks trench lay along the road instead of across
it. Each now has a `_vertical` picture under `art/closures/`, drawn again in the game's own
projection rather than rotated, and `ClosureMarker.cause_picture()` picks by the barrier's axis,
which `City` hands the marker from `RoadClosure.barrier_runs_across()`. A vertical picture covers
the same length of road as its across one and casts a band shadow down the street.

The roadworks end posts stood 13px in from each end of an end-on run and covered most of its
64px column: the end-cap code in `EventInstance._draw_spread` inset each post by half its extent
along the run, which end-on is the post's 26px height. It is now inset by its own 6px width, so
the post stands at the barrier's end on both axes; the roadblock's caps share that code and are
corrected with it. And end-on, the far post is drawn before the board and the near one after
([PLAYTEST-124](../playtests/PLAYTEST-124.md), statement 21: "the top construction pole is drawn
above the barried when it should be behind"): a spread is one node, so draw order is its depth.
Giving each cap its own depth-sorted node was rejected, since the event is one node for its
collision, field and halo and one straight run needs nothing more.

**Open to overturn, chosen by the agent:** the east-west tree falls toward the camera, as
`events/fallen_tree_vertical` does; the crashed cars are slewed a few degrees so both show, the
blue one far; each vertical cause spans its across picture's length of road rather than the
street's width, so the tree and the rubble reach onto both sidewalks as the across ones do. The
east-west rubble is the weakest picture, since a ridge seen end-on reads tall. **Left alone:** the
roadworks segments' band sits about 11px above what it blocks; moving it would change the stripe
phasing the segment art is built on.
