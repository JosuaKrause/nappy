# The south-edge doors drawn as door fronts, superseded by plain indents

`apartment_threshold.svg` and `open_threshold.svg` drew a locked apartment recess as a dark
opening under a chained frame and an open passage recess as a grey door slab with panel lines
between two door-post strips — both read as a door seen from the front, on the escape scene's
hallway south edge. The player rejected this in PLAYTEST-60 (see
`docs/playtests/PLAYTEST-60.md`, "The doors on the hallway's south edge"):

> the downwards leading doors in the hallways are fronwards facing doors now. the placement is
> good but they should be small indents in the wall -- nothing more -- where closed doors should
> be the indent + a brown bar closing the indent (this is indicating the closed door).

The placement was correct — both recesses keep their tile positions and columns on the hallway's
south edge — but the drawing itself was the defect: a frame, a chain and a panelled slab all read
as an object rather than a shallow notch in the wall. Superseded by the current
`assets/interior/apartment_threshold.svg` and `open_threshold.svg`, which draw only a recess with
its side returns and, for the locked version, a brown bar across its mouth as the sole sign of
closure.

This file is preserved for historical reference only. It is not design guidance, a style
reference, or an implementation target for new art; no import sidecar belongs in this ignored
archive.
